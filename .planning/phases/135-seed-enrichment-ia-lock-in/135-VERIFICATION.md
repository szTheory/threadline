---
phase: 135-seed-enrichment-ia-lock-in
verified: 2026-06-04T00:00:00Z
status: passed
score: 4/4
overrides_applied: 0
human_verification: []
automated_uat:
  - test: "In-window Timeline op variety and non-human actor labels"
    expected: "Default /audit/timeline renders UPDATE and DELETE rows plus service_account/zendesk-sync, job/oban-retention-purge, system/trigger-backfill, and anonymous/unknown actor rendering."
    evidence: "`examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts`; verified by `mix verify.example_browser` (`145 passed`, `5 skipped`)."
  - test: "Reply-edit transaction diff with masked internal_note_body"
    expected: "The ticket_replies UPDATE transaction renders body before/after values and [REDACTED] for internal_note_body, without raw internal note text."
    evidence: "`examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts`; verified by `mix verify.example_browser` (`145 passed`, `5 skipped`)."
  - test: "Offboarded support scoped empty Timeline"
    expected: "support@offboarded-co.example.com renders a scoped empty Timeline without crashing."
    evidence: "`examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts`; verified by `mix verify.example_browser` (`145 passed`, `5 skipped`)."
  - test: "Support user denied admin-only Coverage"
    expected: "support@acme.example.com cannot render the Coverage dashboard and receives the unsupported/denied support-lane state without a crash."
    evidence: "`examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts`; verified by `mix verify.example_browser` (`145 passed`, `5 skipped`)."
---

# Phase 135: Seed Enrichment & IA Lock-In Verification Report

**Phase Goal:** Enrich the demo seed so every operator-surface screen demonstrates itself (empty / long-list / status-variety / edge cases all reachable with NO code changes), update DEMO-MANIFEST.md as SSOT, and lock the persona/JTBD IA decisions into the audit doc. SEED ONLY — no schema, route, or business-logic changes.
**Verified:** 2026-06-04T00:00:00Z
**Status:** passed
**Re-verification:** Yes - previous verification was `human_needed`; render/permission-edge checks are now automated by Playwright.

## Goal Achievement

All four success criteria pass automated checks. The prior render/permission-edge confirmations are now covered by focused Playwright E2E assertions in `operator-phase-135-uat.spec.ts`; no human verification remains.

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | After `mix demo.reset && mix demo.seed`, every operator-surface screen can be driven to empty / long-paginated / status-variety / permission-edge states without code changes; recipe table documents the login/path/filter for each state | VERIFIED | `DEMO-MANIFEST.md` contains a `## State recipes` table covering all required states (empty, dense, scoped, permission-edge, future-date filter, op variety, actor variety). D-13 contract test asserts ≥1 INSERT + ≥1 UPDATE + ≥1 DELETE in the default 24h window; D-05 contract test asserts setup rows are actor-attributed and backdated outside 24h window. Orchestrator confirmed `mix demo.reset && mix demo.seed` exits 0 (CR-01 double-seed regression guard passes). Note: per-screen RENDER fixes are deferred to phases 136–143 per phase design; this truth is about DATA + recipes. |
| 2 | `DEMO-MANIFEST.md` is updated and matches the enriched seed as the single source of truth | VERIFIED | File contains `## State recipes` section, `## Named actor literals` section, all three named actor literals (`zendesk-sync`, `oban-retention-purge`, `trigger-backfill`), the anonymous actor cluster, Phase 138 deferral note for Coverage fully-covered/all-empty state, future-date filter `?from=2030-01-01`, and the one-command story (`mix demo.reset && mix demo.seed`). `demo_manifest_contract_test.exs` pins all literals in CI. |
| 3 | No demo-app schema, route, or business-logic changes (seed-only diff) | VERIFIED | `git diff --name-only 39c85b6..HEAD` produces exactly 28 files, all under `.planning/`, `examples/threadline_phoenix/lib/threadline_phoenix/demo/`, `examples/threadline_phoenix/DEMO-MANIFEST.md`, `examples/threadline_phoenix/test/`, or `test/`. Zero schema/migration/router/LiveView/business-logic paths. |
| 4 | Locked persona/JTBD IA decisions (P1–P5, J1–J11, EF1–EF5, Find/Verify/Prove) recorded in `v1.31-PERSONAS-IA.md` and referenced by one-line pointer from `v1.31-UI-AUDIT.md` | VERIFIED | `v1.31-PERSONAS-IA.md` contains: `Locked by Phase 135` status header; P1–P5 (personas); J1–J11 (all 11 JTBDs including J11); `## Earned Flows (EF1–EF5)` table with all five IDs bound to finding/JTBD/persona; `Find / Verify / Prove` triad (twice). `v1.31-UI-AUDIT.md` line 4 contains: `**IA:** Personas P1–P5, jobs J1–J11, earned flows EF1–EF5 are locked in .planning/milestones/v1.31-PERSONAS-IA.md.` `ia_lock_doc_contract_test.exs` asserts all IDs + pointer; orchestrator confirmed 757 tests, 0 failures. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex` | Actor-kind-generalized GUC + audit_context helpers (D-07) | VERIFIED | `set_actor_guc!(actor_id, kind \\ :user)` with kind guard for 5 non-anonymous kinds; `set_anonymous_actor_guc!/0` for :anonymous; `audit_context/2` reads `kind = Keyword.get(opts, :kind, :user)`. No :integration kind. Existing callers (anchors.ex, personas.ex) use the :user default — no arity break. |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex` | D-05 fix: persona/setup rows get :admin actor + backdated timestamp | VERIFIED | `seed_memberships/1` uses `Enum.reduce` pattern; calls `Support.set_actor_guc!(admin_id, :admin)` inside each `Repo.transaction`; `setup_ts = DateTime.add(Manifest.epoch(), -21, :day)` (21 days before epoch = outside 24h window); no `DateTime.utc_now` in setup rows. |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/temporal.ex` | Setup/upsert noise is backdated out of the default 24h window | VERIFIED | `Temporal.run/1` applies explicit story timestamps and then backdates untracked null-actor transactions to `Manifest.epoch() - 21 days`; `demo_contract_test.exs` asserts zero null-actor audit rows in the default 24h window. |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex` | Named actor literals + accessor (D-06) | VERIFIED | `@actor_zendesk_sync "zendesk-sync"`, `@actor_oban_retention_purge "oban-retention-purge"`, `@actor_trigger_backfill "trigger-backfill"` as module attributes; `def actor_id(:zendesk_sync)`, `def actor_id(:oban_retention_purge)`, `def actor_id(:trigger_backfill)` accessors present. |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex` | seed_variety_pack/1 — in-window 5/4/2 op + multi-kind actor cluster (D-10/11/12) | VERIFIED | `seed_variety_pack/1` defined and called last in `run/1` (line 24). 9 private functions implement: reply-edit (INSERT+UPDATE with zendesk-sync service_account), ticket reopen+reassign (UPDATE with oban-retention-purge job), membership role change (UPDATE with trigger-backfill system, epoch-backdated per D-05), reply hard-delete (DELETE, anonymous actor), ticket delete (DELETE, trigger-backfill system), zendesk sync INSERT, stale sweep UPDATE, backfill UPDATE, anon submission INSERT. All in-window via `DateTime.utc_now() |> DateTime.add(-N, :hour)` + `Support.put_timestamp`. |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/filler.ex` | DELETE branch shifting corpus op-mix toward 55/35/10 (D-11) | VERIFIED | `status_roll = rem(number, 10)` deterministic; `status_roll == 0` → `Repo.delete!(ticket)` (~10%); `1..3` → closed UPDATE (~30–35%); else → in_progress UPDATE (~55–60%). Stays epoch-relative via `Support.random_days_ago_timestamp()` — no `DateTime.utc_now`. |
| `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/exports.ex` | SavedView seed rows for admin (F-204 data) | VERIFIED | `seed_saved_views/2` private function inserts 2 rows: `"Recent deletes"` (`%{"op" => "delete"}` filters) and `"Closed this week"` (`%{"table" => "tickets", "status" => "closed"}` filters), both keyed to the admin `actor_ref`. Deterministic UUIDv5 IDs. `Repo.insert_all(SavedView, ...)` with on_conflict. |
| `.planning/milestones/v1.31-PERSONAS-IA.md` | Locked IA artifact with status header + EF1–EF5 (D-15/D-16/D-19) | VERIFIED | Status header with "Locked by Phase 135"; `## Earned Flows (EF1–EF5)` table; J1–J11 (J11 = P5 JTBD present); P1–P5 intact; `Find / Verify / Prove` triad present. |
| `.planning/milestones/v1.31-UI-AUDIT.md` | One-line pointer to the locked IA (D-17) | VERIFIED | Line 4: `**IA:** Personas P1–P5, jobs J1–J11, earned flows EF1–EF5 are locked in .planning/milestones/v1.31-PERSONAS-IA.md. Cite IDs from there; do not duplicate here.` No IA fork (no second persona block). |
| `test/threadline/ia_lock_doc_contract_test.exs` | C-lite doc-contract test (~15 assertions) for IA IDs + pointer (D-18) | VERIFIED | `Threadline.IaLockDocContractTest` with `async: true`; asserts P1–P5 (loop), J1–J11 (loop), EF1–EF5 (loop), Find/Verify/Prove triad (OR match), v1.31-PERSONAS-IA.md reference in UI-AUDIT, P1–P5 mention in pointer, EF1–EF5 mention in pointer. Orchestrator confirmed 757 library tests pass including this file. |
| `examples/threadline_phoenix/DEMO-MANIFEST.md` | Per-state recipe table + named actor literals section (D-03/D-06) | VERIFIED | `## State recipes` section with 20 rows covering Timeline (7 states), Transactions (2), Actor (3), Row History (2), Coverage (3 inc. DEFERRED), Evidence (2), Exports (2), Redaction (1), Retention (1), Home (2). `## Named actor literals` section with all four kinds. |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_contract_test.exs` | Doc-contract test for the recipe table + actor literals (D-03) | VERIFIED | `ThreadlinePhoenix.DemoManifestContractTest` with `async: true`; `describe "recipe table"` (5 tests) and `describe "named actor literals"` (3 tests); pins `## State recipes`, screen names, login literals, future-date filter, Coverage Phase 138 deferral, all three non-human actor literals, anonymous kind. Orchestrator confirmed 20 demo contract tests, 0 failures. |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` | D-13 in-window variety + D-05 actor-attribution assertions | VERIFIED | `describe "D-05 persona setup actor attribution"` (2 tests): ≥1 org_memberships AuditChange with non-null actor_ref; 0 org_memberships in default 24h window. `describe "D-13 in-window variety guarantee"` (1 test): asserts ≥1 each for "insert", "update", "delete" in 24h window. Double-seed regression guard (CR-01). Orchestrator confirmed 20 tests, 0 failures. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `personas.ex seed_memberships/1` | `Support.set_actor_guc!/2` with `:admin` kind | `Repo.transaction` wrapper per org | WIRED | `grep "Support.set_actor_guc!(admin_id, :admin)" personas.ex` returns 2 — one for admin's own membership, one for persona members |
| `personas.ex seed_memberships/1` | `Support.put_timestamp` with epoch-21d | `setup_ts = DateTime.add(Manifest.epoch(), -21, :day)` | WIRED | Both `Enum.reduce` loops in `seed_memberships/1` call `Support.put_timestamp(acc/inner_acc, tx_id, setup_ts)` |
| `anchors.ex seed_variety_pack` | `Support.set_actor_guc!/2` and `set_anonymous_actor_guc!/0` | non-human actor clusters via `Manifest.actor_id/1` | WIRED | `grep "Manifest.actor_id" anchors.ex` returns 7 (zendesk_sync, oban_retention_purge, trigger_backfill used across variety stories); `set_anonymous_actor_guc!` used in reply-delete and anon-submission stories |
| `demo_contract_test.exs D-13 block` | `AuditChange.op + transaction.occurred_at` | join query over 24h window | WIRED | `occurred_at >= ^window_start` present in D-13 test; query tests all three op values |
| `demo_manifest_contract_test.exs` | `examples/threadline_phoenix/DEMO-MANIFEST.md` | `Path.expand("../../DEMO-MANIFEST.md", __DIR__)` + `File.read!` | WIRED | Path resolves correctly from test directory; asserts literals that exist in the DEMO-MANIFEST.md file |
| `ia_lock_doc_contract_test.exs` | `v1.31-PERSONAS-IA.md` and `v1.31-UI-AUDIT.md` | `Path.expand("../../.planning/milestones/...")` | WIRED | Both path expansions present in test file; EF1–EF5 exist in the target file, so all assertions pass |

### Data-Flow Trace (Level 4)

The phase produces seed data (not rendered components), so Level 4 data-flow traces apply to the test assertions rather than UI components.

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `demo_contract_test.exs D-13` | `count` of AuditChange ops in 24h window | `Repo.one!` query on `AuditChange` + `AuditTransaction` join | Yes — seed runs before assertions via `setup do ... Reset.run()` | FLOWING |
| `demo_contract_test.exs D-05` | org_memberships actor_ref attribution | `Repo.one!` query on `AuditChange` join `AuditTransaction` | Yes — seed inserts via audited `Repo.transaction` with GUC set | FLOWING |
| `exports.ex SavedView seed` | 2 rows in `threadline_saved_views` | `Repo.insert_all(SavedView, ...)` with `actor_ref` = admin ActorRef | Yes — deterministic UUIDv5 IDs, on_conflict idempotent | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `set_actor_guc!/2` definition with kind defaulting to :user | `grep -c "def set_actor_guc!(actor_id, kind" support.ex` | 1 | PASS |
| `set_anonymous_actor_guc!/0` present | `grep -c "def set_anonymous_actor_guc!" support.ex` | 1 | PASS |
| No `:integration` kind introduced | `grep -c ":integration" support.ex` | 0 | PASS |
| `actor_id/1` accessors for all three literals | `grep -c "def actor_id(" manifest.ex` | 3 | PASS |
| `seed_variety_pack` defined and called in run/1 | `grep -c "seed_variety_pack" anchors.ex` | 2 | PASS |
| Anonymous actor GUC used in variety pack | `grep -c "Support.set_anonymous_actor_guc!" anchors.ex` | 7 | PASS |
| Manifest.actor_id called 3+ times in variety pack | `grep -c "Manifest.actor_id" anchors.ex` | 7 | PASS |
| Filler DELETE branch present | `grep -c "Repo.delete!" filler.ex` | 1 | PASS |
| Filler deterministic roll | `grep -c "rem(number, 10)" filler.ex` | 2 | PASS |
| Filler stays epoch-relative (no utc_now) | `grep "DateTime.utc_now" filler.ex \| wc -l` | 0 | PASS |
| SavedView seeded | `grep -c "SavedView" exports.ex` | 3 | PASS |
| PERSONAS-IA lock header present | `grep -c "Locked by Phase 135" v1.31-PERSONAS-IA.md` | 1 | PASS |
| UI-AUDIT pointer present | `grep -c "v1.31-PERSONAS-IA.md" v1.31-UI-AUDIT.md` | 1 | PASS |
| `State recipes` section in DEMO-MANIFEST.md | `grep -c "State recipes" DEMO-MANIFEST.md` | 1 | PASS |
| Seed-only diff: no schema/route/LV files changed | `git diff --name-only 39c85b6..HEAD \| grep prohibited-paths` | (no output) | PASS |

### Probe Execution

Step 7c skipped — no conventional `scripts/*/tests/probe-*.sh` files exist in this repository and the phase does not declare any probes. The equivalent role is played by the `mix verify.test` run confirmed by the orchestrator (757 tests, 0 failures).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| POLISH-SEED | Plans 135-01, 135-02, 135-03, 135-04 | Every operator-surface screen demonstrates itself from seed; DEMO-MANIFEST.md updated as SSOT; seed only | SATISFIED | All four plans claim POLISH-SEED and their must-haves are verified above. REQUIREMENTS.md marks POLISH-SEED for Phase 135 as Complete (checkbox ticked). |

### Anti-Patterns Found

No `TBD`, `FIXME`, or `XXX` debt markers found in any files modified by this phase.

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | No anti-patterns found |

### Scope Note: CR-02 Membership DELETE (D-12 Story 6)

The code review (135-REVIEW.md) identified that D-12 story 6 (a membership DELETE) was not implemented. The DEMO-MANIFEST.md was corrected to honestly describe the membership operation as a role-change UPDATE (backdated outside the 24h window). This is not a gap — the manifest is now accurate, and the D-13 in-window DELETE guarantee is satisfied by ticket_replies and ticket DELETEs (stories 4 and 5). The manifest documents this correctly in the recipe table notes.

### Automated UAT

The prior render/permission-edge checks are now covered by `examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts` and run through the existing `mix verify.example_browser` CI lane. The browser harness now runs `mix demo.reset && mix demo.seed` before Playwright so repeated local/CI runs start from the documented UAT state.

#### 1. In-window variety and non-human actors visible above fold in Timeline

**Automated:** The spec logs in as `admin@example.com`, opens `/audit/timeline`, and asserts visible UPDATE and DELETE rows plus service_account/zendesk-sync, job/oban-retention-purge, system/trigger-backfill, and anonymous/unknown actor rendering.

#### 2. Reply-edit rich diff with [REDACTED] internal_note_body

**Automated:** The spec opens the in-window `ticket_replies` UPDATE transaction, asserts `body` before/after values, asserts `internal_note_body` renders `[REDACTED]`, and asserts the raw internal note strings are absent.

#### 3. Empty scoped Timeline for offboarded-co support login

**Automated:** The spec logs in as `support@offboarded-co.example.com`, opens `/audit/timeline`, and asserts a scoped empty state with zero Timeline rows.

#### 4. Permission-edge: support login on admin-only Coverage screen

**Automated:** The spec logs in as `support@acme.example.com`, opens `/audit/coverage`, and asserts the support session receives the unsupported/denied state rather than the Coverage dashboard.

### Human Verification Required

None. The runtime/browser behaviors that previously required human confirmation are now covered by focused Playwright assertions and the example browser CI lane.

### Gaps Summary

No gaps found. All four success criteria are verified by automated checks, including the prior runtime/render behaviors. Status is `passed`; no human verification remains.

---

_Verified: 2026-06-04T00:00:00Z_
_Verifier: the agent (automated UAT closure)_
