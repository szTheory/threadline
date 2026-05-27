---
phase: 110-triage-narrow-fixes
reviewed: 2026-05-27T20:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/page_html.ex
  - examples/threadline_phoenix/WALKTHROUGH.md
  - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs
  - test/threadline/example_phoenix_readme_contract_test.exs
findings:
  critical: 0
  warning: 1
  info: 3
  total: 4
status: issues
---

# Phase 110: Code Review Report

**Reviewed:** 2026-05-27  
**Depth:** standard  
**Files Reviewed:** 5 (from plans 110-01–110-02 `key-files`; `.planning/` artifacts excluded per D-03)  
**Status:** issues (1 warning, 3 informational)

## Summary

Phase 110 closes findings 0001–0003 with focused, in-scope fixes: a nil-safe landing template for logged-out visitors, WALK-03-02/03 doc alignment for WR-001/WR-002, IN-001 §0 voice cleanup, and contract-test locks. Changes stay in `examples/` and root doc-contract tests — no `lib/threadline/**` commits, matching the phase scope guard.

The landing BadMapError fix and CLI/window doc fixes are correct and address the 108-REVIEW warnings that blocked Phase 109 re-walk. One remaining WALK-03-02 prose inconsistency and thin contract coverage are worth a narrow follow-up but do not block milestone archive.

## Findings

### WR-110-001: WALK-03-02 operator question still says “last 24 hours”

**Severity:** warning  
**File:** `examples/threadline_phoenix/WALKTHROUGH.md` (WALK-03-02)

Plan 110-02 aligned step 2–3 filters to `demo_last_tuesday` (`2026-05-20T14:30:00Z`) through `demo_epoch` (`2026-05-27T12:00:00Z`), closing 108-REVIEW WR-001. The **operator question** on line 451 still reads:

> what did they touch in the **last 24 hours** before offboard?

That contradicts the corrected step literals and reintroduces the wall-clock-relative framing Phase 110 removed elsewhere (§3, §4 intro). A maintainer skimming only the question may apply a 24h window and falsely classify seeded activity as `(a) breakage` even though steps and Appendix A are now aligned.

**Recommendation:** Restate the operator question to match fiction — e.g. “what did they touch from **`demo_last_tuesday`** through **`demo_epoch`**?” — and optionally lock the phrase in `walkthrough_doc_contract_test.exs`.

### IN-110-001: Leaving-agent contract test is minimal

**Severity:** info  
**File:** `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs`

The new `"SEED-03 leaving agent window"` describe closes 108-REVIEW IN-004 and uses the same `actor_ref @> map` pattern as `Threadline.actor_history/2`. It only asserts `count >= 1` in the time window — it does not verify help-desk table involvement (`tickets`, `ticket_replies`) or org scoping described in WALK-03-02 expected outcomes.

**Recommendation:** Extend the test with a join on `audit_changes` filtering `table_name in ["tickets", "ticket_replies"]` and Acme org meta, or assert `count >= @leaving_agent_tx_count` (12) to match `anchors.ex`.

### IN-110-002: `walkthrough_doc_contract_test` still omits WALK-03-02 window literals

**Severity:** info  
**File:** `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs`

Phase 110 added `--subject retention_run` and `subject-ref-json` locks (WR-002). The RUN-01 literal list still omits WALK-03-02 anchors added in 110-02: `demo_last_tuesday`, `33123cc4-da21-5674-b030-e168cee90521`, or `leaving agent window` prose. Partial follow-up to 108-REVIEW IN-002.

**Recommendation:** Add window and agent2 UUID literals when fixing WR-110-001.

### IN-110-003: Agent2 UUID remains hardcoded outside Manifest

**Severity:** info  
**Files:** `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs`, `examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex`

The contract test inlines `33123cc4-da21-5674-b030-e168cee90521` (correct per Appendix A / UUID v5). `:agent2` is still absent from `Manifest.user_id/1` (108-REVIEW IN-003 deferral). Future manifest edits risk test/doc drift.

**Recommendation:** Add `:agent2` to manifest accessors in a small follow-up; have the contract test call `Manifest.user_id(:agent2)` once available.

## Positive observations

- **Finding 0001 fix (`page_html.ex`):** Nil-safe guards (`is_nil(@current_scope) or is_nil(@current_scope.user)` and `@current_scope && @current_scope.user`) correctly prevent BadMapError on logged-out GET `/` without touching `lib/threadline/**`. Matches host-owned Sigra wiring in the reference app.
- **WR-002 fix:** WALK-03-03 optional CLI now matches §5 flag style; invalid positional form removed from WALKTHROUGH.
- **WR-001 fix (steps):** WALK-03-02 filter prose and operator-surface table use `demo_last_tuesday` through `demo_epoch`; stale `2026-05-26T12:00:00Z` `from` anchor gone.
- **IN-001 fix:** §0 no longer references internal GSD labels (`Plan 05`, `Task 2`).
- **README contract (`example_phoenix_readme_contract_test.exs`):** Assertion aligned to 108-05 “runnable proof artifact behind both paths” — unblocks `mix ci.all` without scope creep.
- **Scope discipline:** Phase 110 changes remain in `examples/` and doc-contract tests; re-walk log attests empty `lib/threadline/` commit range.

## Verification

```bash
cd examples/threadline_phoenix && mix test \
  test/threadline_phoenix/demo_contract_test.exs \
  test/threadline_phoenix/walkthrough_doc_contract_test.exs

cd /path/to/threadline && mix test test/threadline/example_phoenix_readme_contract_test.exs
```

Phase attestation (110-02/03): **9 + 1 + 6 tests, 0 failures**; `mix ci.all` exit 0. Reviewer re-ran README and walkthrough doc contract tests successfully; full example demo contract suite should be re-run in CI or a clean clone before archive if local Postgres state is stale.

## Recommendation

Fix **WR-110-001** (operator question prose) in a narrow doc pass — low effort, prevents WALK-03-02 confusion on future dry-runs. Informational items can ride with v1.23 archive or a 110.x doc-only follow-up. No critical or security blockers; landing fix and WR-001/002 step corrections are shippable.

---

_Reviewed: 2026-05-27_  
_Reviewer: Cursor (gsd-code-reviewer)_  
_Depth: standard_
