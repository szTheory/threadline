---
phase: 98-mounted-evidence-views-on-audit
verified: 2026-05-27T00:00:00Z
status: passed
score: 3/3 requirement bands verified
overrides_applied: 0
---

# Phase 98: Mounted Evidence Views On `/audit` Verification Report

**Phase Goal:** Re-prove the current-tree mounted `/audit/evidence` surface with explicit verification evidence instead of inherited summary claims.
**Verified:** 2026-05-27T00:00:00Z
**Status:** passed
**Re-verification:** Yes - gap closure for missing phase verification

## Current-tree preflight

**Result:** PASS

- The Phase 98 implementation files, tests, and summaries are present on disk, but `98-VERIFICATION.md` was missing before this run.
- This verification treats the current working tree as the authority and closes that missing artifact gap directly.
- Milestone authority surfaces remain intentionally unreconciled here; `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` stay Phase 103 work.

## 1. Read-only /audit/evidence mount inside the existing operator family

**Requirement:** `SURF-01`  
**Result:** PASS

- `lib/threadline/operator_surface/router.ex:100` mounts `live("/evidence", EvidenceLive, :index)` inside the `live_session :threadline` block (lines 89-109) as a sibling alongside `live("/", TimelineLive, :index)` at line 99 — no new UI family introduced.
- `lib/threadline/operator_surface/live/evidence_live.ex` defines only `mount/3` (line 12), `handle_params/3` (line 21), and `render/1` (line 49) with no `handle_event/3` defined — URL-driven navigation per the Phase 98 thin-LiveView contract.
- `test/threadline/operator_surface/live/evidence_live_test.exs` is the LiveView-scope behavioral authority for the mount, navigation, and URL-driven assertions for SURF-01.

### Evidence

```bash
rg -n 'live("/evidence"' lib/threadline/operator_surface/router.ex
```

Result: PASS (exactly one match at line 100, inside the live_session :threadline block opened at line 89)

### Evidence

```bash
rg -n '^\s*def handle_event' lib/threadline/operator_surface/live/evidence_live.ex
```

Result: PASS (exit code 1 — zero matches; negative assertion proving no mutation handlers are defined)

### Evidence

```bash
mix test test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1
```

Result: PASS (`5 tests, 0 failures`)

## 2. Mounted parity through Threadline.Evidence.Proof and locked copy literals

**Requirement:** `SURF-02`  
**Result:** PASS

- `lib/threadline/operator_surface/live/evidence_live.ex:8` carries `alias Threadline.Evidence.Proof` and `evidence_live.ex:253` calls `Proof.present_record(record)` inside `defp build_row/1` — the same presenter `lib/threadline/evidence/proof.ex` exposes for the Mix-task `render_human/1` and `to_json_iodata/2` paths, confirming surface-to-API parity via the shared presenter.
- The canonical verdict-vocabulary source is `lib/threadline/evidence/proof.ex:10`: `@semantic_statuses ~w(proven inferred_posture unsupported)`. The dynamic render site at `evidence_live.ex:116-118` consumes this vocabulary via `{row.verdict_status}` — both are cited because the render site is NOT the literal-defining site (per RESEARCH.md §2.2 dual-grep nuance; Risk 6 warns against citing only the render site, which returns zero matches for static grep).
- The five locked Phase 98 copy literals from `98-UI-SPEC.md` (Copywriting Contract) are each verified by a structural grep against source AND a behavioral assertion in the LiveView test suite: `What can Threadline prove right now?` at `evidence_live.ex:67` asserted by `evidence_live_test.exs:115` (refute, denied-state) and `:150` (assert, overview); `View history` at `evidence_live.ex:142` asserted at `evidence_live_test.exs:152`; `No evidence records yet` at `evidence_live.ex:89` asserted at `evidence_live_test.exs:213`; `Evidence view unavailable.` at `unsupported.ex:25` rendered via `evidence_live.ex:154` and asserted at `evidence_live_test.exs:113`; verdict triple (`proven`, `inferred_posture`, `unsupported`) asserted at `evidence_live_test.exs:153-155`.

### Evidence

```bash
rg -n 'alias Threadline\.Evidence\.Proof|Proof\.present_record' lib/threadline/operator_surface/live/evidence_live.ex
```

Result: PASS (exactly two matches: line 8 alias, line 253 Proof.present_record call site)

### Evidence

```bash
rg -n '@semantic_statuses' lib/threadline/evidence/proof.ex
```

Result: PASS (exactly one match at line 10 — `@semantic_statuses ~w(proven inferred_posture unsupported)`; canonical verdict-vocabulary source per RESEARCH.md §2.2)

### Evidence

```bash
mix test test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1
```

Result: PASS (`5 tests, 0 failures`)

## 3. Host-owned evidence_authorize_fn gate with no Threadline RBAC

**Requirement:** `SURF-03`  
**Result:** PASS

- `lib/threadline/operator_surface/auth.ex:253-254` defines `defp assign_evidence_enabled(socket, opts) do` with `evidence_authorize_fn = Keyword.get(opts, :evidence_authorize_fn, fn _ -> false end)` — the fail-closed default that denies access when the host omits the option entirely.
- `evidence_authorize_fn` is a host-supplied function value of shape `(%{assigns: map()} -> boolean | :ok | {:ok, scope} | _)` dispatched at `auth.ex:269` (`evidence_authorize_fn.(mirror)`) where `mirror = %{assigns: socket.assigns}` at `auth.ex:267` — a host-supplied callback only, NOT a Threadline-owned module dispatch, behaviour implementation, or protocol consumer.
- Zero matches for `Threadline.RBAC|Threadline.Permissions|Threadline.Policy.RBAC` under `lib/threadline/operator_surface/` (negative assertion confirming no Threadline-owned RBAC modules), paired with the positive-control grep above so a path typo would fail loudly (per D-07).
- 6 unit tests in `describe "assign_evidence_enabled"` at `test/threadline/operator_surface/auth_test.exs:337-394` (SURF-03 capability-boolean fan-out at unit scope), plus the denied-state HTML assertion at `test/threadline/operator_surface/live/evidence_live_test.exs:106-116` (Test 1 at line 106 owns the SURF-03 denied-state HTML rendering — `assert html =~ "Evidence view unavailable."` at line 113).

### Evidence

```bash
rg -n 'Threadline\.RBAC|Threadline\.Permissions|Threadline\.Policy\.RBAC' lib/threadline/operator_surface/
```

Result: PASS (exit code 1 — zero matches; negative assertion that no Threadline-owned RBAC modules are referenced under the operator surface)

### Evidence

```bash
rg -n 'evidence_authorize_fn' lib/threadline/operator_surface/auth.ex
```

Result: PASS (5 matches at lines 254, 259, 265, 266, 269; line 254 is the canonical `Keyword.get(opts, :evidence_authorize_fn, fn _ -> false end)` fail-closed default; positive-control paired with the negative grep above per D-07)

### Evidence

```bash
mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1
```

Result: PASS (`34 tests, 0 failures`)

### Authority statement

The authoritative Phase 98 rerun bundle is:

1. `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1`
2. `rg -n 'live("/evidence"' lib/threadline/operator_surface/router.ex` (Band 1)
3. `rg -n '^\s*def handle_event' lib/threadline/operator_surface/live/evidence_live.ex` (Band 1)
4. `rg -n 'alias Threadline\.Evidence\.Proof|Proof\.present_record' lib/threadline/operator_surface/live/evidence_live.ex` (Band 2)
5. `rg -n 'Threadline\.RBAC|Threadline\.Permissions|Threadline\.Policy\.RBAC' lib/threadline/operator_surface/` (Band 3 negative)
6. `rg -n 'evidence_authorize_fn' lib/threadline/operator_surface/auth.ex` (Band 3 positive control)

`mix verify.test` is intentionally not the authority for Phase 98. The Phase 98-02 summary (`98-02-SUMMARY.md:70-74`) records a pre-existing alias-drift failure in `Threadline.CiTopologyContractTest` that is outside Phase 98 ownership; Phase 99 owns the named-alias topology, and commit `b636c17` ("fix(99-02): update ci.all topology contract to expanded doc_contract alias") is the most recent fix on that surface. Phase 102 disclaims rather than reopens that scope.
