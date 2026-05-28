# Phase 119: phx.gen.auth Integration Guide & Lane — Research

**Researched:** 2026-05-27
**Status:** Complete

## Summary

Phase 119 is a **documentation-only** vertical slice: ship `guides/integrations/phx-gen-auth.md` as the majority-Phoenix auth cookbook and add **`phx-gen-auth-reference`** lane vocabulary to `guides/upgrade-path.md` **without** a compatibility matrix row (Phase 120) and **without** a `Threadline.Integrations.PhxGenAuth` module. Proof model = maintained guide prose now; root integration tests land in Phase 120.

## Key Findings

### 1. Structural template: `sigra.md` with deliberate omissions

| Section (sigra) | phx guide (119) |
|-----------------|-----------------|
| `## Install` (optional Hex dep) | **Omit** — host runs `mix phx.gen.auth` |
| `## Plug callback wire-up` | **Keep** — host `MyApp.AuditActor` module |
| `## Surface and export auth` | **Abbreviate** — admin `authorize_fn` only |
| `## Behaviors locked by SPEC` | **Rename** → `## Reference semantics` (numbered, not adapter-locked) |
| `## correlation_id formats` (Sigra prefixes) | **Omit** — optional correlation paragraph only |
| `## Soft-dep contract` | **Omit** |

Target length: **~70–90 lines** (CONTEXT D-08). HTML marker: `<!-- PHX-GEN-AUTH-03-INTEGRATION-GUIDE -->` (D-10).

### 2. Assign contract: `current_scope` capture, `current_user` operator bridge

- **Capture:** `actor_fn` reads `conn.assigns[:current_scope]` with map-safe `%{user: %{id: id}}` pattern (matches `Threadline.Integrations.Sigra` `Map.get(conn.assigns, :current_scope)` but host-owned).
- **Operator:** `authorize_fn` may use `assigns[:current_user]` after host bridge plug (pattern: `OperatorUser.assign_from_scope/2` in example app — Sigra-specific org logic is **not** copied; guide shows minimal `role == "admin"` or `is_admin`).
- **Plug order (hard requirement):** `fetch_session` → `fetch_current_scope` (generated) → `Threadline.Plug` on audited pipelines (D-06).
- **Legacy:** One short Phoenix 1.7 `current_user`-only fallback inside host `actor_fn` template (D-07).

### 3. Upgrade-path edits (prose only)

Add to `guides/upgrade-path.md`:

- **Who this guide is for** — fourth bullet for phx.gen.auth hosts
- **How to tell which lane you are on** — new `phx-gen-auth-reference` paragraph (parallel to `sigra-reference`)
- **Support vocabulary** — bullet under “That distinction matters” for `phx-gen-auth-reference` as `reference`, narrower than `phoenix-surface`, **not Sigra-compatible**
- **Release checklist** — item to read phx guide when on that lane

**Do not** add matrix row or cite `phx_gen_auth_integration_test.exs` (D-14, D-15, D-16). Wording: “Maintained composition path: `guides/integrations/phx-gen-auth.md`”; forthcoming root tests in Phase 120.

### 4. No new public API or doc-contract tests in 119

- CONTEXT defers doc-contract locks to Phase 121 (ADOPT-AUTH-03).
- No `lib/threadline/**` changes unless zero-behavior doc helper (not needed).
- Verification for 119 = `mix format --check-formatted` on touched markdown + manual grep checklist in plan acceptance criteria.

### 5. Operator surface depth

- Copy-paste `threadline_operator_surface/2` with admin-only `authorize_fn` (D-11).
- Defer export/evidence/coverage/policy callbacks — link `guides/operator-surface.md` (D-12).
- One footgun paragraph: LiveView `on_mount` ≠ export HTTP auth (D-13).

### 6. Correlation defaults

- Default `context_overrides_fn` → `%{}` or omit (D-18).
- Headers win; overrides additive only (D-19, Phase 49 semantics).
- Optional non-normative patterns: W3C trace id, BFF header, `Audit.transaction/3` business ids — **no** `phx-session:` format table (D-20, D-21).

## Validation Architecture

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Phase 120); Phase 119 manual/grep only |
| **Config file** | N/A for 119 |
| **Quick run command** | `mix format --check-formatted guides/integrations/phx-gen-auth.md guides/upgrade-path.md` |
| **Full suite command** | `mix verify.format` (119 scope) |
| **Estimated runtime** | ~5 seconds |

**Sampling:** After each plan task commit → format check on modified guides. After wave 2 → grep acceptance criteria from plans.

**Wave 0:** Not required — no new test files in 119.

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| ROADMAP says “matrix” but CONTEXT forbids row in 119 | Plans follow CONTEXT D-14/D-16; matrix deferred to 120 |
| Guide duplicates sigra doc-contract surface | Omit Install/Soft-dep/formats; smaller marker set in 121 |
| Implies Threadline runs `phx.gen.auth` | AUTH-GUIDE-03 non-goals section mandatory |
| Implies root CI already proves lane | D-15 wording; no test file citations |

## Canonical Code Snippets (for planner)

**Host AuditActor (illustrative):**

```elixir
defmodule MyApp.AuditActor do
  alias Threadline.Semantics.ActorRef

  def actor_ref_from_conn(conn) do
    case conn.assigns[:current_scope] do
      %{user: %{id: id}} -> ActorRef.new(:user, to_string(id))
      _ -> nil
    end
  end

  def audit_context_overrides_from_conn(_conn), do: %{}
end
```

**Router pipeline:**

```elixir
pipeline :browser do
  plug :accepts, ["html"]
  plug :fetch_session
  plug :fetch_current_scope
  plug Threadline.Plug,
    actor_fn: &MyApp.AuditActor.actor_ref_from_conn/1,
    context_overrides_fn: &MyApp.AuditActor.audit_context_overrides_from_conn/1
end
```

**Operator mount (admin gate):**

```elixir
threadline_operator_surface "/audit",
  authorize_fn: fn %{assigns: %{current_user: %{role: "admin"}}}, _opts -> :ok end,
  authorize_fn: fn _, _opts -> {:error, :unauthorized} end
```

(Planner should fix duplicate `authorize_fn` key — use single function with `case`.)

## RESEARCH COMPLETE
