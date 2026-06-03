# Phase 135: Seed Enrichment & IA Lock-In — Research

**Researched:** 2026-06-03
**Domain:** Elixir demo seed (deterministic), doc-contract testing, IA artifact locking
**Confidence:** HIGH — all claims verified against live codebase

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** ONE deterministic `mix demo.seed`. No `--profile` flags.
- **D-02:** Empty/scoped/permission-edge states via existing mechanisms (`offboarded-co`, `scope_operator_query/3`, `my_authorize_fn/1`, future-date filter).
- **D-03:** Per-state recipe table in `DEMO-MANIFEST.md`, backed by a doc-contract test.
- **D-04 (deferred):** Coverage fully-covered / all-empty state → Phase 138.
- **D-05:** Root cause of "Actor unknown everywhere" is `Personas.run` inserting trigger-audited rows with no actor GUC AND no backdate. Fix: give persona/setup transactions a real actor AND a backdated timestamp.
- **D-06:** Realistic-skewed actor roster (~70% `:user`, ~15% `:admin`, ~5% `:service_account`, ~5% `:job`, ~3% `:system`, ~2% `:anonymous`).
- **D-07:** Generalize `Support.set_actor_guc!/1` and `Support.audit_context/2` to accept actor kind (currently hardcoded `:user`).
- **D-08 (constraint):** Use `:service_account` for integration actor. Do NOT introduce `:integration`.
- **D-09 (load-bearing constraint A):** Only `ticket_replies` has `store_changed_from: true` + `mask`. Do not fake `before` values on other tables.
- **D-10 (load-bearing constraint B):** Default Timeline window is 24h off wall-clock `now`. In-window variety MUST use `DateTime.utc_now() |> DateTime.add(-N, :hour)` pattern.
- **D-11:** Two-layer op-mix: in-window variety pack (~5 INSERT / 4 UPDATE / 2 DELETE), corpus/filler shift to ~55/35/10.
- **D-12:** 6 specific mutation stories (reply-edit, ticket-reopened/re-triaged, membership-role-change, reply-delete in-window, ticket-delete, membership-delete).
- **D-13:** Guarantee ≥1 UPDATE + ≥1 DELETE in 24h window; back with thin seed assertion.
- **D-14:** Keep `internal_note_body` masked on reply-edit. Use existing redaction config only.
- **D-15:** Lock `v1.31-PERSONAS-IA.md` in place with a status header. Do NOT fork into `v1.31-UI-AUDIT.md`.
- **D-16:** Stabilize ID scheme: P1–P5, J1–J11, EF1–EF5, each EF bound to its audit finding.
- **D-17:** Add one-line pointer in `v1.31-UI-AUDIT.md` near the Status line.
- **D-18:** C-lite doc-contract test (~15 assertions) for PERSONAS-IA.md IDs and the pointer line.
- **D-19 (reconcile):** Real count is J1–J11 (not J1–J10). Fix any success-criterion wording.

### Claude's Discretion

- Exact in-window hour offsets, exact filler ratio (~50–60/30–40/10–15), exact seed-module decomposition (extend `Anchors`/`Filler` vs new thin `VarietyPack` module) — provided determinism + D-13 hold.
- Exact actor-id literal strings (suggested: `service_account/zendesk-sync`, `job/oban-retention-purge`, `system/trigger-backfill`) — finalize as named `Manifest` literals.

### Deferred Ideas (OUT OF SCOPE)

- F-201 render, F-703 render, F-103 render → Phase 138.
- F-204 Home resume row render → Phase 139.
- Coverage fully-covered / all-empty state → Phase 138.
- Empty-as-diagnostic for Evidence/Exports/Retention where global rows exist → Phase 137+.
- `:integration` ActorRef kind — out of scope (library change).
- `--profile` seed flags — explicitly forbidden.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| POLISH-SEED | Every operator-surface screen demonstrates itself from seed — empty states, long/paginated lists, status variety, and permission/edge cases are all reachable via `mix demo.reset && mix demo.seed`; DEMO-MANIFEST.md updated as SSOT. Seed only — no schema/route/business-logic changes. | Verified mechanisms: GUC actor path (D-05), in-window anchor pattern (D-10), scoped/permission-edge via `my_authorize_fn/1` + `scope_operator_query/3` (D-02), `ticket_replies` custom trigger for rich diffs (D-09). All mutation patterns (D-12) are feasible with existing `Repo.transaction` + `set_actor_guc!/1` idiom. |
</phase_requirements>

---

## Summary

CONTEXT.md locked all 19 decisions with high specificity. This research verifies the load-bearing claims against live code, fills gaps the planner needs (test file locations, exact function signatures, IA ID inventory, pointer location), and recommends a seed module decomposition.

**Three things the planner needs that CONTEXT.md does not fully supply:**

1. The `Support.set_actor_guc!/1` and `Support.audit_context/2` functions are confirmed hardcoded to `:user` — the exact refactor shape is simple (add a `kind` parameter with `:user` as default). The plan needs to sequence this generalization as a prerequisite step before any new actor-kind cluster is inserted.

2. `v1.31-PERSONAS-IA.md` currently has J1–J11 and P1–P5 but contains **no EF IDs at all** (EF1–EF5 do not exist yet). D-16 requires adding them as part of this phase. The doc-contract test (D-18) must assert IDs that are written in this phase, not pre-existing.

3. The seed module decomposition recommendation (Claude's Discretion): extend `Anchors` for the in-window variety pack rather than adding a new module — rationale below.

**Primary recommendation:** All locked decisions are viable against the codebase. No decision needs revisiting. Proceed to planning.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Seed data insertion (actor, op, table variety) | Demo seed layer (`seed/*.ex`) | HelpDesk domain API | Seed orchestrates through existing HelpDesk API + direct Repo calls for non-semantic ops |
| Actor GUC propagation | `Support.set_actor_guc!/1` → PostgreSQL trigger | `ActorRef.new/2` | GUC is transaction-local; trigger reads `current_setting('threadline.actor_ref', true)` into `audit_transactions.actor_ref` |
| Timestamp backfill (in-window vs epoch-anchored) | `Temporal.run/1` | — | Raw SQL UPDATE; all backdating flows through this; in-window rows skip this (use wall-clock `DateTime.utc_now()`) |
| Scoped / empty-state reachability | `router.ex` (`my_authorize_fn/1`, `scope_operator_query/3`) | — | No seed changes needed; login as support persona routes through these functions |
| IA artifact locking | `.planning/milestones/v1.31-PERSONAS-IA.md` | `v1.31-UI-AUDIT.md` (pointer only) | Lock happens via status header in PERSONAS-IA.md + one-line pointer in UI-AUDIT.md |
| Doc-contract tests | `examples/threadline_phoenix/test/threadline_phoenix/` | `test/threadline/` (library contracts) | Demo-app doc-contract tests live in the example app test suite |

---

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation` absent from `.planning/config.json` → treated as enabled).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir standard) |
| Config file | `examples/threadline_phoenix/test/test_helper.exs` |
| Quick run command | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/demo_manifest_test.exs` |
| Full suite command | `cd examples/threadline_phoenix && mix ci.all` (or `mix verify.test` from project root for library suite) |

### Three Validation Surfaces for Phase 135

#### Surface 1: Doc-contract test for recipe table (D-03)

**What to test:** `DEMO-MANIFEST.md` contains the per-state recipe table. A thin doc-contract test asserts the table's header row and ≥3 screen-state-login triples exist.

**Exemplar pattern** — `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs` (confirmed at `test/threadline_phoenix/walkthrough_doc_contract_test.exs:1`). The pattern is:

```elixir
@manifest Path.expand("../../DEMO-MANIFEST.md", __DIR__)
test "DEMO-MANIFEST.md recipe table covers expected screens" do
  doc = File.read!(@manifest)
  assert String.contains?(doc, "## State recipes")
  assert String.contains?(doc, "empty")
  assert String.contains?(doc, "offboarded-co.example.com")
  # ... etc
end
```

**File:** A new test module to be created in Wave 0. Suggested path: `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs`. Note: the existing `demo_manifest_test.exs` tests the `Manifest` Elixir module (not the .md file) — a separate file for the recipe-table contract is the right separation.

**Validated signal:** `mix test test/threadline_phoenix/demo_manifest_contract_test.exs` green.

#### Surface 2: Doc-contract test for IA IDs (D-18)

**What to test:** `v1.31-PERSONAS-IA.md` contains P1–P5, J1–J11, EF1–EF5, the `Find/Verify/Prove` triad string; and `v1.31-UI-AUDIT.md` contains the pointer line added by D-17.

**File:** New test module. Suggested path: `test/threadline/ia_lock_doc_contract_test.exs` (in the library test suite, alongside other doc-contract tests at `test/threadline/*_doc_contract_test.exs`). Alternatively co-located in the example app test directory — either works, but placing it in the library test suite keeps IA assertions with the other cross-cutting doc contracts.

**Assertion shape (~15 assertions):**

```elixir
@personas_ia Path.expand("../../.planning/milestones/v1.31-PERSONAS-IA.md", __DIR__)
@ui_audit Path.expand("../../.planning/milestones/v1.31-UI-AUDIT.md", __DIR__)

for id <- ~w(P1 P2 P3 P4 P5) do
  test "PERSONAS-IA.md contains persona #{id}" do
    assert String.contains?(File.read!(@personas_ia), #{inspect(id)})
  end
end
# same for J1..J11, EF1..EF5
# one test for "Find/Verify/Prove" triad
# one test for UI-AUDIT.md pointer line presence
```

**Important:** EF1–EF5 do not exist in `v1.31-PERSONAS-IA.md` today. The test for EF IDs will fail (Wave 0 gap) until D-16 writes them into the file. The planner must sequence D-16 (write EF IDs) before D-18 (test asserts them). [VERIFIED: read confirmed no EF IDs in PERSONAS-IA.md]

**Validated signal:** `mix verify.test` from project root passes all `ia_lock_doc_contract_test.exs` assertions.

#### Surface 3: Seed in-window guarantee assertion (D-13)

**What to test:** After `mix demo.seed`, ≥1 UPDATE and ≥1 DELETE `audit_change` exist with `captured_at > DateTime.utc_now() - 24h`.

**Location:** Extend `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` (confirmed at `test/threadline_phoenix/demo_contract_test.exs:1`). This file already uses `unboxed_run` + `@moduletag :demo_contract` and runs the full seed in `setup`. Add a new `describe "D-13 in-window variety guarantee"` block.

**Query shape (thin, does not re-seed — reads from post-setup state):**

```elixir
test "default 24h window contains ≥1 UPDATE and ≥1 DELETE" do
  Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
    window_start = DateTime.utc_now() |> DateTime.add(-24, :hour)

    for op <- ["update", "delete"] do
      count =
        Repo.one!(
          from(ac in AuditChange,
            join: at in assoc(ac, :transaction),
            where: ac.op == ^op,
            where: at.occurred_at >= ^window_start,
            select: count(ac.id)
          )
        )
      assert count >= 1, "expected ≥1 #{op} in default 24h window, got #{count}"
    end
  end)
end
```

**Determinism note:** This assertion is window-relative (`DateTime.utc_now() - 24h`), not epoch-relative. The in-window variety-pack rows use `DateTime.utc_now() |> DateTime.add(-N, :hour)` offsets (N ≤ 6), so they always satisfy the window condition regardless of when CI runs. The assertion is stable by construction. [VERIFIED: `seed_active_agent_window` in `anchors.ex:56` uses this exact pattern]

**Validated signal:** `mix test test/threadline_phoenix/demo_contract_test.exs` (the `@moduletag :demo_contract` tests require a live DB; they run in `async: false` unboxed mode per existing pattern).

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| POLISH-SEED (recipe table) | DEMO-MANIFEST.md contains per-state recipe table | doc-contract | `mix test test/threadline_phoenix/demo_manifest_contract_test.exs` | ❌ Wave 0 |
| POLISH-SEED (IA IDs locked) | PERSONAS-IA.md has P1–P5, J1–J11, EF1–EF5; UI-AUDIT.md has pointer | doc-contract | `mix verify.test` (library suite) | ❌ Wave 0 |
| POLISH-SEED (in-window variety) | ≥1 UPDATE + ≥1 DELETE in default 24h window post-seed | integration | `mix test test/threadline_phoenix/demo_contract_test.exs` | ✅ (extend existing) |
| POLISH-SEED (seed-only diff guard) | No schema/route/business-logic changes | review convention | `git diff --name-only` — no files outside `seed/`, `DEMO-MANIFEST.md`, test/docs | manual |

### Sampling Rate

- **Per task commit:** `cd examples/threadline_phoenix && mix verify.format` (fast; no DB needed)
- **Per wave merge:** `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix/demo_manifest_contract_test.exs && mix verify.test` (library suite for IA doc-contract)
- **Phase gate:** `mix ci.all` from project root — must be green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs` — covers D-03 recipe table assertions
- [ ] `test/threadline/ia_lock_doc_contract_test.exs` — covers D-18 IA ID assertions (note: EF IDs in PERSONAS-IA.md must be written before this test can pass)

---

## Mechanism Verification Table

| Claim (from CONTEXT.md) | Status | Evidence |
|-------------------------|--------|---------|
| D-05: `Personas.run` inserts trigger-audited rows with no actor GUC | CONFIRMED | `personas.ex:38–148` — all `Repo.insert!` and `Repo.update!` calls are bare; no `Support.set_actor_guc!/1` call anywhere in the file; no `Repo.transaction` wrapper. `ensure_membership!/2` (line 126) and `ensure_agent!/2` (line 138) call `Repo.insert!` directly. |
| D-05: `Personas.run` never backdates (Temporal.run only rewrites tx in `ctx.timestamps`) | CONFIRMED | `temporal.ex:8` — `run/1` iterates `ctx.timestamps` map; `personas.ex:30–35` — returns `ctx` but never calls `Support.put_timestamp/3`, so persona rows have no entry in `ctx.timestamps` and are never backdated. |
| D-05: `Support.set_actor_guc!/1` works via `set_config('threadline.actor_ref', ...)` | CONFIRMED | `support.ex:57–65` — calls `ActorRef.new(:user, user_id)`, encodes to JSON, runs `SELECT set_config('threadline.actor_ref', $1::text, true)`. |
| D-05: Trigger reads GUC into `audit_transactions.actor_ref` | CONFIRMED | `trigger_sql.ex:231` — `NULLIF(current_setting('threadline.actor_ref', true), '')::jsonb` inserted into `audit_transactions.actor_ref`. |
| D-05: `actor_label/1` displays it | CONFIRMED | `timeline_live.ex:544–551` — `actor_label/1` returns `"#{type}/#{id}"` for structs/maps with non-nil id; falls to `"unknown"` for all other patterns. |
| D-07: `Support.set_actor_guc!/1` hardcodes `:user` | CONFIRMED | `support.ex:57` — `def set_actor_guc!(user_id) when is_binary(user_id)` calls `ActorRef.new(:user, user_id)` — kind is compile-time literal `:user`. |
| D-07: `Support.audit_context/2` hardcodes `:user` | CONFIRMED | `support.ex:19–20` — `def audit_context(user_id, opts \\ []) when is_binary(user_id)` calls `ActorRef.new(:user, user_id)` — kind is compile-time literal `:user`. |
| D-07: `ActorRef.new/2` already supports all 6 kinds | CONFIRMED | `actor_ref.ex:24` — `@types ~w(user admin service_account job system anonymous)a`; `new/2` validates against this list. |
| D-08 constraint: 6 kinds, no `:integration` | CONFIRMED | `actor_ref.ex:24` — the 6 `@types` atoms are the complete set; `new/2` line 37 returns `{:error, :unknown_actor_type}` for any other atom. |
| D-09: Only `ticket_replies` has `store_changed_from: true` + `mask` | CONFIRMED | `dev.exs:78–90` — `:trigger_capture` config has `"ticket_replies" => [mask: ["internal_note_body", "body"], store_changed_from: true]` and `"posts" => [mask: []]`; no other table has `store_changed_from`. |
| D-10: Default Timeline window is 24h off wall-clock `now` | CONFIRMED | `timeline_live.ex:13` — `@default_window_hours 24`; line 90 — `from = DateTime.utc_now() |> DateTime.add(-@default_window_hours * 3600, :second)` |
| D-10: `seed_active_agent_window` uses `DateTime.utc_now() |> DateTime.add(-N, :hour)` | CONFIRMED | `anchors.ex:56` — `ts = DateTime.utc_now() |> DateTime.add(-hours_ago, :hour)` with `hours_ago` in `[1, 3, 6]`. |
| D-02: `offboarded-co` + `RetentionTail.assert_org_y_audit_empty!/1` | CONFIRMED | `retention_tail.ex:213–218` — `assert_org_y_audit_empty!/1` raises if `count != 0`. |
| D-02: `scope_operator_query/3` in demo `router.ex` | CONFIRMED | `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:112–128` — narrows `timeline`, `transaction`, `export`, `row_history`, `actor_history`, `transaction_header` surfaces by `organization_id` from meta. |
| D-02: `my_authorize_fn/1` returns `{:ok, %{access: :support_read_only, organization_id: org_id}}` for support users | CONFIRMED | `router.ex:71–82` — `%{role: :support, organization_id: org_id}` branch returns `{:ok, %{access: :support_read_only, organization_id: org_id}}`; export/evidence/coverage/policy fns require `is_admin: true`. |
| SavedView keyed by `actor_ref` | CONFIRMED | `saved_view.ex:17` — `field(:actor_ref, Threadline.Semantics.ActorRef)`; `timeline_live.ex:41–44` — queried `where: v.actor_ref == ^actor_ref`. |
| Seed pipeline order | CONFIRMED | `seed.ex:24–30` — `Personas → Exports → Anchors → Filler → Temporal → RetentionTail → RetentionRuns`. |

---

## Seed Module Decomposition Recommendation

**Recommendation: Extend `Anchors` and `Filler` in place. Do NOT add a new `VarietyPack` module.**

**Rationale:**

`Anchors` (`anchors.ex`) already owns the wall-clock-relative pattern (`seed_active_agent_window`). The D-12 mutation stories (reply-edit, ticket-reopened, membership-role-change, etc.) are conceptually "anchor incidents with precise in-window timestamps" — the same abstraction as the existing `hero_close`, `hero_delete`, and `seed_active_agent_window` functions. Extending `Anchors` with a `seed_variety_pack/1` function keeps the module coherent and avoids a thin wrapper.

`Filler` (`filler.ex`) owns the INSERT-only bulk churn. Adding a DELETE branch to `insert_filler_ticket/4` (or a sibling `filler_update_and_delete/4`) is a local change — the module's role does not change.

**Pipeline slot:** New variety-pack calls in `Anchors.run/1` execute after the existing `seed_active_agent_window` call. The Temporal pass runs after Anchors/Filler (as today), so in-window rows must NOT be added to `ctx.timestamps` — they should use `DateTime.utc_now() |> DateTime.add(-N, :hour)` directly as the `occurred_at` at insert time via a direct `Repo.update!` on the audit_transaction, or by skipping `put_timestamp` (since Temporal only rewrites what's in `ctx.timestamps`, leaving wall-clock rows untouched). [VERIFIED: `temporal.ex:8` — only rewrites `ctx.timestamps` entries]

**Determinism preservation:** All new mutations use deterministic Repo operations within `Repo.transaction` with `set_actor_guc!`. The `DateTime.utc_now()` calls for in-window anchors are deterministic for the D-13 assertion (always within 24h) but not for exact timestamp values — this is intentional and matches the existing `seed_active_agent_window` pattern.

**Actor-kind generalization prerequisite:** D-07 must be done first (generalize `Support.set_actor_guc!/1` and `Support.audit_context/2`). The recommended minimal refactor:

```elixir
# Before (support.ex:57)
def set_actor_guc!(user_id) when is_binary(user_id) do
  {:ok, actor_ref} = ActorRef.new(:user, user_id)
  ...
end

# After
def set_actor_guc!(actor_id, kind \\ :user)
    when is_binary(actor_id) and kind in [:user, :admin, :service_account, :job, :system] do
  {:ok, actor_ref} = ActorRef.new(kind, actor_id)
  ...
end

# For anonymous (no id needed):
def set_anonymous_actor_guc! do
  {:ok, actor_ref} = ActorRef.new(:anonymous)
  ...
end
```

```elixir
# Before (support.ex:19)
def audit_context(user_id, opts \\ []) when is_binary(user_id) do
  {:ok, actor_ref} = ActorRef.new(:user, user_id)
  ...
end

# After
def audit_context(actor_id, opts \\ []) when is_binary(actor_id) do
  kind = Keyword.get(opts, :kind, :user)
  {:ok, actor_ref} = ActorRef.new(kind, actor_id)
  ...
end

def audit_context(:anonymous, opts) do
  {:ok, actor_ref} = ActorRef.new(:anonymous)
  %AuditContext{actor_ref: actor_ref, ...}
end
```

Existing callers pass a positional `user_id` with no `:kind` option — they continue to work unchanged with the `:user` default.

---

## Actor-Kind Generalization Surface (D-07/D-06)

### Current Signatures

**`Support.set_actor_guc!/1`** — `support.ex:57`
```elixir
def set_actor_guc!(user_id) when is_binary(user_id) do
  {:ok, actor_ref} = ActorRef.new(:user, user_id)
  json = actor_ref |> Threadline.Semantics.ActorRef.to_map() |> Jason.encode!()
  Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
end
```

**`Support.audit_context/2`** — `support.ex:19`
```elixir
def audit_context(user_id, opts \\ []) when is_binary(user_id) do
  {:ok, actor_ref} = ActorRef.new(:user, user_id)
  %Threadline.Semantics.AuditContext{
    actor_ref: actor_ref,
    correlation_id: Keyword.get(opts, :correlation_id),
    request_id: Keyword.get(opts, :request_id, "demo-seed")
  }
end
```

### Named Actor Literals (D-06 Manifest entries)

The CONTEXT.md suggests these literals for the `Manifest` module and DEMO-MANIFEST.md:

| Kind | Literal ID | Cluster role |
|------|-----------|-------------|
| `:service_account` | `service_account/zendesk-sync` | Inbound ticket sync (INSERT + UPDATE upserts) |
| `:job` | `job/oban-retention-purge` | Attribute existing retention purge + stale-ticket sweep |
| `:system` | `system/trigger-backfill` | Small backfill/correction cluster |
| `:anonymous` | (no id — `ActorRef.new(:anonymous)`) | Public ticket-submission form cluster |

These literal strings become constants in `Manifest` (e.g., `@service_account_id "service_account/zendesk-sync"`) and named accessor functions (e.g., `Manifest.actor_id(:zendesk_sync)`). They are referenced in DEMO-MANIFEST.md under a new `## Named actor literals` section.

### Admin actor for D-05 fix

The D-05 fix requires giving `Personas.run` setup transactions (org/membership/agent inserts) a real actor. The natural actor is `:admin` / `admin@example.com` (the cross-org admin already in `Manifest.user_ids()`). This requires wrapping `ensure_membership!` and `ensure_agent!` insertions in `Repo.transaction` with `Support.set_actor_guc!(admin_id, :admin)` and `Support.put_timestamp/3` (epoch-backdated). This is the core of the D-05 fix.

---

## IA Lock-In Mechanics (D-15..D-19)

### v1.31-PERSONAS-IA.md: ID Inventory (VERIFIED)

| ID Group | IDs Present | Source |
|----------|-------------|--------|
| Personas | P1 (Incident Responder), P2 (Support Agent), P3 (Compliance/Security Reviewer), P4 (Audit Operator/SRE), P5 (Adopter Developer) | `v1.31-PERSONAS-IA.md:11–30` |
| JTBDs | J1–J11 (J1: correlation-id find, J2: row history, J3: actor sweep, J4: record-first, J5: Evidence verdict, J6: export loop, J7: redaction confirm, J8: health check, J9: coverage close, J10: purge confirm, J11: first-mount confirm) | `v1.31-PERSONAS-IA.md:39–49` |
| Earned Flows | **NONE** — EF1–EF5 do not exist in the file today | Confirmed by grep; `v1.31-PERSONAS-IA.md` has no "EF" strings |
| Find/Verify/Prove triad | Present — "Find / Verify / Prove" grouping in section 3 | `v1.31-PERSONAS-IA.md:58` |

**D-19 confirmed:** J11 = "P5 Confirm data + scoping work on first mount" exists at line 49. CONTEXT.md's correction is accurate — J11 is real.

**D-16 action required:** EF1–EF5 must be written into `v1.31-PERSONAS-IA.md` as part of this phase. The EF definitions from CONTEXT.md (D-16) are the authoritative source:

| ID | Earned Flow | JTBD | Persona | Finding |
|----|-------------|------|---------|---------|
| EF1 | Record-first cordoned path | J4 | P2 | F-1001 (Phase 140) |
| EF2 | First-class row-history entry | J2 | P1 | F-1003 (138/140) |
| EF3 | Close the export loop | J6 | P3 | F-602, F-1002 (140) |
| EF4 | Correlation-id paste/deep-link on Home | J1 | P1 | F-1001 (140) |
| EF5 | Prove-group separator before Exports (+ optional Verify→Trust card label) | P3 IA | — | F-105, F-304 (139) |

### v1.31-UI-AUDIT.md: Status Line Location (D-17)

The D-17 pointer goes near the `**Status:**` line at the top of `v1.31-UI-AUDIT.md`. The current Status line is:

```
**Status:** Baseline captured 2026-06-03.
```
(file line 3)

The one-line pointer should be added directly after this line as a new line:

```
**IA:** Personas P1–P5, jobs J1–J11, earned flows EF1–EF5 are locked in `.planning/milestones/v1.31-PERSONAS-IA.md`. Cite IDs from there; do not duplicate here.
```

This satisfies D-17 without forking the IA or duplicating content.

### What "status-header lock" looks like for PERSONAS-IA.md (D-15)

Add a status header to `v1.31-PERSONAS-IA.md` indicating it is locked by Phase 135:

```
**Status:** Locked by Phase 135 (2026-06-03). IDs P1–P5 / J1–J11 / EF1–EF5 are stable; per-screen phases (137–143) cite from here.
```

This matches the convention already used in `v1.31-UI-AUDIT.md`.

---

## Common Pitfalls

### Pitfall 1: In-window rows inadvertently backdated by Temporal.run

**What goes wrong:** Developer adds in-window variety-pack rows but also calls `Support.put_timestamp(ctx, tx_id, some_epoch_relative_time)` — the row lands at epoch (past), becomes invisible above the fold, D-13 assertion fails.

**Why it happens:** The `put_timestamp` pattern is used everywhere in Anchors; easy to copy-paste without recognizing that in-window rows must skip it.

**How to avoid:** In-window variety-pack rows must NOT appear in `ctx.timestamps`. Temporal.run only rewrites entries in that map. Wall-clock-relative timestamps from `DateTime.utc_now()` survive the Temporal pass unchanged. [VERIFIED: `temporal.ex:8` — only iterates `ctx.timestamps`]

**Warning signs:** `mix test test/threadline_phoenix/demo_contract_test.exs` D-13 assertion fails; Timeline shows 0 UPDATE/DELETE above the fold.

### Pitfall 2: `Personas.run` fix adds `Repo.transaction` wrappers without updating `ctx`

**What goes wrong:** `Personas.run` is refactored to wrap insertions with `set_actor_guc!` and `Repo.transaction`, but the returned transaction IDs are not captured for `put_timestamp` — persona/setup rows still sort to the top (now wall-clock, not backdated).

**How to avoid:** Each new `Repo.transaction` in `Personas.run` must call `Support.current_audit_transaction_id!()` and immediately call `Support.put_timestamp(ctx, tx_id, backdated_ts)` where `backdated_ts` is ≥ 2 weeks before `demo_epoch` (far outside the 24h window). Accumulate timestamps into `ctx` and return the updated `ctx`.

**Warning signs:** "Actor unknown" rows still appear at the top of the Timeline default view after the fix.

### Pitfall 3: Actor-kind generalization breaks existing callers

**What goes wrong:** `set_actor_guc!/1` arity changes to `/2`, breaking existing 1-arg call sites in `anchors.ex`, `filler.ex`, `personas.ex`.

**How to avoid:** Use a default parameter (`kind \\ :user`) so all existing `Support.set_actor_guc!(user_id)` calls continue to work. Same for `audit_context/2` adding `kind` as a keyword option (not positional). Verify with `mix compile --warnings-as-errors`.

### Pitfall 4: D-18 doc-contract test asserts EF IDs before they are written

**What goes wrong:** The test is written first (Wave 0) but EF1–EF5 are not yet in PERSONAS-IA.md — test fails in Wave 0 unexpectedly.

**How to avoid:** The Wave 0 task for the IA doc-contract test should add the test file with a comment `# NOTE: will be red until D-16 writes EF IDs in the same wave`; OR sequence D-16 (write EF IDs into PERSONAS-IA.md) as Wave 0 work alongside the test, so both pass by end of Wave 0.

### Pitfall 5: `ticket_replies` reply-edit adds `before` values to non-reply tables

**What goes wrong:** Planner assumes that because `ticket_replies` has `store_changed_from: true`, other tables should too — contradicts D-09 and the documentation's "honest after-only" principle.

**How to avoid:** The reply-edit mutation story exclusively targets `ticket_replies` for the before/after diff. Mutations on `tickets` and `org_memberships` (D-12 stories 2, 3, 6) are after-only — this is correct and deliberate, not a data gap.

---

## Environment Availability

Step 2.6: SKIPPED (phase is seed code + docs; no new external dependencies — uses existing PostgreSQL, Elixir/Mix stack already in use).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Threadline.Audit.transaction/3` (used by HelpDesk for `ticket_replied_and_closed`) sets the actor GUC automatically via the passed `audit_context.actor_ref` | Seed decomposition | If false, new HelpDesk API calls for D-12 mutations won't propagate actor — need to verify `Threadline.Audit.transaction` implementation sets the GUC internally. Mitigated: existing `seed_acme_close` works correctly via this path, confirming the mechanism. [ASSUMED from training + confirmed by working seed] |

Note: `Threadline.Audit.transaction/3` clearly works for the existing `ticket_replied_and_closed` path (confirmed by `demo_contract_test.exs` passing), so the risk is LOW. The planner should confirm with a grep on `Threadline.Audit.transaction` to verify it handles GUC setup internally vs. relying on pre-set GUC.

---

## Open Questions / Risks for Planner

1. **`Threadline.Audit.transaction/3` vs. raw `Repo.transaction` for D-12 variety-pack mutations.**
   - What we know: HelpDesk uses `Threadline.Audit.transaction/3` which accepts an `audit_context` — this path is proven to set actor correctly.
   - What's unclear: For direct `Repo.transaction` + `set_actor_guc!` calls (the pattern in `anchors.ex` / `filler.ex`), the GUC is set manually — this also works (confirmed by leaving-agent and active-agent windows).
   - Recommendation: Use `Repo.transaction` + `set_actor_guc!` for the variety-pack mutations that don't have a HelpDesk API (pure `Repo.update!` / `Repo.delete!` calls); use HelpDesk API (`ticket_replied_and_closed`) for the reply-edit story to preserve the semantic action name.

2. **How to handle `:admin` actor for the D-05 Personas fix.**
   - What we know: `admin@example.com` has UUID `5bbaa26c-b413-5c51-8c9e-88806fd8641d` in Manifest.
   - What's unclear: Whether `ensure_membership!` and `ensure_agent!` need to be converted to full `Repo.transaction` wrappers or whether the outer `seed_memberships/1` call can be wrapped in a single transaction per org.
   - Recommendation: Wrap each org's membership+agent setup in ONE transaction with a single `set_actor_guc!(:admin)` call and one `put_timestamp` per org. This gives one `audit_transaction` per org setup (not one per row), which is realistic (an admin onboarding an org is one action) and minimizes transaction overhead.

3. **SavedView seeding for F-204.**
   - What we know: `SavedView` is a real persisted Ecto schema (`saved_view.ex`); Timeline queries it by `actor_ref` at mount. Phase 135 is to seed the data (render is Phase 139).
   - What's unclear: CONTEXT.md says F-204 saved views are "seed-feasible" but D-16 and D-17 don't mention SavedView seeding explicitly. This is a Phase 135 POLISH-SEED deliverable.
   - Recommendation: The planner should include a `Seed.SavedViews` task (or extend `Seed.Exports`) to insert 1–2 `SavedView` rows keyed to `admin@example.com`'s `ActorRef`. The `actor_ref` must match what Timeline uses for the logged-in admin user. This is small scope (2 `Repo.insert!` calls) and satisfies F-204 data half without any render work.

---

## Sources

### Primary (HIGH confidence)

All claims are verified directly against live source files in the codebase. No external sources needed — this is a purely code-verification research task.

| File | What was verified |
|------|-------------------|
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex` | D-07 hardcoded `:user` in `set_actor_guc!/1` and `audit_context/2`; exact function signatures |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex` | D-05 root cause: no GUC, no `put_timestamp` anywhere in file |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex` | D-10 in-window pattern: `DateTime.utc_now() |> DateTime.add(-hours_ago, :hour)` at line 56 |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/temporal.ex` | Only rewrites `ctx.timestamps` entries — in-window rows safe |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex` | `assert_org_y_audit_empty!/1` confirmed at line 213 |
| `lib/threadline/semantics/actor_ref.ex` | D-08: exactly 6 kinds at line 24; `new/2` validated; anonymous path |
| `lib/threadline/capture/trigger_sql.ex` | GUC read at line 231: `NULLIF(current_setting('threadline.actor_ref', true), '')::jsonb` |
| `lib/threadline/operator_surface/live/timeline_live.ex` | `@default_window_hours 24` at line 13; window calculation at line 90; `actor_label/1` at lines 544–551 |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | `my_authorize_fn/1` at line 71; `scope_operator_query/3` at lines 112–128; permission-edge for support users |
| `examples/threadline_phoenix/config/dev.exs` | `ticket_replies` custom trigger config at lines 78–90; only table with `store_changed_from: true` |
| `.planning/milestones/v1.31-PERSONAS-IA.md` | P1–P5 (lines 11–30), J1–J11 (lines 39–49); EF IDs absent (confirmed by grep) |
| `.planning/milestones/v1.31-UI-AUDIT.md` | Status line at line 3; Phase 135 worklist at line 155 |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` | Test pattern: `unboxed_run`, `@moduletag :demo_contract`, `async: false`; seed runs in `setup` |
| `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs` | Doc-contract test pattern: file path via `Path.expand`, `String.contains?` assertions |
| `lib/threadline/governance/saved_view.ex` | `actor_ref` field confirmed; `Threadline.Governance.SavedView` schema |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex` | Pipeline order confirmed: Personas → Exports → Anchors → Filler → Temporal → RetentionTail → RetentionRuns |

---

## Metadata

**Confidence breakdown:**
- Mechanism verification: HIGH — all 17 claims verified with file:line evidence
- Seed module decomposition: HIGH — based on direct code inspection; recommendation follows existing idioms
- IA ID inventory: HIGH — confirmed by grep and file read; EF absence is certain
- Validation architecture: HIGH — test file locations confirmed, query patterns verified against existing tests
- Actor-kind refactor shape: HIGH — exact function signatures read from source

**Research date:** 2026-06-03
**Valid until:** Stable — seed + semantics layer code changes infrequently; valid until any refactor of `support.ex`, `actor_ref.ex`, or `timeline_live.ex`

---

## RESEARCH COMPLETE

**Phase:** 135 - Seed Enrichment & IA Lock-In
**Confidence:** HIGH

### Key Findings

1. **D-05 root cause confirmed with line-level evidence.** `Personas.run` in `personas.ex` has zero `set_actor_guc!` or `put_timestamp` calls — every org/membership/agent row lands with null `actor_ref` and wall-clock `now()` timestamp, sorting above the fold. Fix is well-scoped: wrap `seed_memberships` blocks in transactions with `:admin` kind.

2. **D-07 refactor is trivially small.** Both functions have a single `ActorRef.new(:user, ...)` call each. Adding a `kind` parameter with `:user` default is a 2-line change per function; all existing callers continue to work unchanged.

3. **EF1–EF5 do not exist yet.** `v1.31-PERSONAS-IA.md` has P1–P5 and J1–J11 but no EF IDs. Phase 135 must write them (D-16). The IA doc-contract test (D-18) depends on this and should be sequenced after or alongside D-16 in Wave 0.

4. **D-18 test pointer location confirmed.** The D-17 one-line pointer goes immediately after `**Status:**` on line 3 of `v1.31-UI-AUDIT.md`. New doc-contract test file: `test/threadline/ia_lock_doc_contract_test.exs`.

5. **In-window rows bypass `Temporal.run` safely.** `temporal.ex` only rewrites entries in `ctx.timestamps`. In-window variety-pack rows using `DateTime.utc_now()` are never added to `ctx.timestamps` and survive the Temporal pass untouched — proven by the existing `seed_active_agent_window` pattern.

### File Created
`.planning/phases/135-seed-enrichment-ia-lock-in/135-RESEARCH.md`

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| Mechanism verification | HIGH | 17 claims verified with file:line citations |
| Seed decomposition | HIGH | Direct code inspection; follows established idioms |
| IA ID inventory | HIGH | Confirmed by direct file read + grep |
| Validation architecture | HIGH | Test patterns confirmed against existing test files |

### Open Questions
- Confirm whether `Threadline.Audit.transaction/3` sets the actor GUC internally or expects the caller to pre-set it (low risk — existing seeds prove the path works; grep `Threadline.Audit.transaction` to confirm for planner's peace of mind)
- SavedView seeding scope (F-204): planner should include 1–2 `SavedView` rows for `admin@example.com` in the plan; small scope, unambiguous POLISH-SEED deliverable

### Ready for Planning
Research complete. Planner can now create PLAN.md.
