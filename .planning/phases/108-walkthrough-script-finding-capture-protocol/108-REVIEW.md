---
phase: 108-walkthrough-script-finding-capture-protocol
reviewed: 2026-05-27T18:30:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex
  - examples/threadline_phoenix/DEMO-MANIFEST.md
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex
  - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
  - examples/threadline_phoenix/WALKTHROUGH.md
  - examples/threadline_phoenix/DEMO_USERS.md
  - examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs
  - examples/threadline_phoenix/README.md
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues
---

# Phase 108: Code Review Report

**Reviewed:** 2026-05-27  
**Depth:** standard  
**Files Reviewed:** 8 (from plans 01–05 `key-files`; `.planning/` artifacts excluded per D-03)  
**Status:** issues (2 warnings, 4 informational)

## Summary

Phase 108 delivers the intended walkthrough runbook, findings capture protocol, redaction-policy evidence seed, and doc contract tests. Elixir changes follow existing manifest/RetentionTail patterns; contract tests pass (8 tests, 0 failures).

Two warnings block a faithful Phase 109 dry-run on **WALK-03-02** and **WALK-03-03**: the leaving-agent time window in prose does not match seeded timestamps, and one optional CLI example uses invalid `mix threadline.evidence.show` flags. Fix these before Phase 109 or expect `(a) breakage` findings on the first dry-run pass.

## Findings

### WR-001: WALK-03-02 time window does not match seeded agent2 activity

**Severity:** warning  
**Files:** `examples/threadline_phoenix/WALKTHROUGH.md`, `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex`

WALK-03-02 instructs a **24-hour window ending at `demo_epoch`** (`from` = `2026-05-26T12:00:00Z`, `to` = `2026-05-27T12:00:00Z`). Seeded leaving-agent transactions are stamped at **`demo_last_tuesday` + 1..12 minutes** (`2026-05-20T14:31:00Z` … `2026-05-20T14:42:00Z`) in `seed_leaving_agent_window/1`.

Following the documented filter exactly yields **empty** actor history — contradicting the expected outcome (“non-empty for the 24h window”). Phase 109 would classify this as **(a) breakage**.

**Recommendation:** Align prose with seed fiction — e.g. anchor the window to `demo_last_tuesday` through `demo_epoch`, or restate the operator question as “last Tuesday” with the same `2026-05-20T14:30:00Z` footnote used elsewhere. Add a contract test or `demo_contract_test` describe that asserts agent2 transaction counts in the documented window.

### WR-002: WALK-03-03 optional CLI uses invalid flag syntax

**Severity:** warning  
**File:** `examples/threadline_phoenix/WALKTHROUGH.md` (WALK-03-03 step 5)

Documented command:

```bash
mix threadline.evidence.show retention_run --subject-ref walk-retention-offboarded-co
```

`Mix.Tasks.Threadline.Evidence.Show` rejects positional args:

```
threadline.evidence.show: unexpected argument(s): retention_run, walk-retention-offboarded-co
```

§5 (WALK-04-01) already shows the correct form:

```bash
mix threadline.evidence.show --subject retention_run \
  --subject-ref-json '{"run_id":"walk-retention-offboarded-co"}'
```

**Recommendation:** Replace WALK-03-03 step 5 with the §5 flag style (or drop the optional CLI line and point to WALK-04-01).

### IN-001: Stale planning artifacts in published §0 table

**Severity:** info  
**File:** `examples/threadline_phoenix/WALKTHROUGH.md`

§0 “Sections in this runbook” still lists **“Task 2”** for §1–§3 and references **“Plan 05”** / **“see §5 in Plan 05”** (lines 39, 46–48, 143). These are internal GSD labels, not maintainer-facing status.

**Recommendation:** Replace with “Complete” or remove the Status column before Phase 109.

### IN-002: `walkthrough_doc_contract_test` locks only six literals

**Severity:** info  
**File:** `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs`

RUN-01 contract omits walk-critical strings added in later plans: `walk-acme-4521-close`, `walk-demo-redaction-policy`, `WALK-04-01`, `agent2@acme.example.com`, `33123cc4-da21-5674-b030-e168cee90521`. Drift between WALKTHROUGH, DEMO-MANIFEST, and Appendix A would not fail CI.

**Recommendation:** Extend the contract list incrementally (or one test per WALK section) when fixing WR-001/WR-002.

### IN-003: `agent2` persona absent from manifest accessors and DEMO-MANIFEST Users table

**Severity:** info  
**Files:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex`, `examples/threadline_phoenix/DEMO-MANIFEST.md`

`agent2@acme.example.com` is seeded (`personas.ex`), listed in `DEMO_USERS.md` and WALKTHROUGH Appendix A, but not in `@user_emails` / `Manifest.user_id/1` or DEMO-MANIFEST Users table. UUID is inlined correctly (`33123cc4-da21-5674-b030-e168cee90521` matches UUID v5) — documented deferral in 108-04 — but future manifest edits risk Appendix A drift.

**Recommendation:** Add `:agent2` to manifest + DEMO-MANIFEST in Phase 110 or a small 108.x fix.

### IN-004: No automated proof for leaving-agent window fiction

**Severity:** info  
**Files:** `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs`, `anchors.ex`

Hero incidents #4521, #4518, org Y retention, and redaction policy have contract tests; **agent2 leaving-agent window** has none. WR-001 would have been caught by a test asserting non-zero agent2 audit rows in the walkthrough’s documented time range.

**Recommendation:** Add `describe "SEED-03 leaving agent window"` (or WALK-03-02) after WR-001 window fix.

## Positive observations

- **Redaction evidence (108-01):** `@evidence_redaction_policy_ref`, `RetentionTail.record_evidence!/2`, and `demo_contract_test` WALK-04 describe close the four evidence families for WALK-04.
- **Security:** WALK-03-01 expected outcome avoids the seed constant substring; threat-model grep discipline preserved.
- **Four-incident separation:** #4521 close and #4518 delete remain distinct heroes with separate actors and filters.
- **Findings protocol (108-02):** `TEMPLATE.md` and README decision tree match D-108-05; observe-only discipline is clear.
- **RUN-01 routing:** README maintainer pointer to `WALKTHROUGH.md` vs integrator guide is correct.
- **RetentionTail:** Evidence recording follows the same pattern as retention_run/policy/trigger_coverage; `Application.put_env` for retention is scoped to demo seed path (acceptable for reference app).

## Verification

```bash
cd examples/threadline_phoenix && mix test \
  test/threadline_phoenix/demo_contract_test.exs \
  test/threadline_phoenix/walkthrough_doc_contract_test.exs
```

Result: **8 tests, 0 failures**

CLI syntax check (WALK-03-03 documented form):

```bash
mix threadline.evidence.show retention_run --subject-ref walk-retention-offboarded-co
# Mix error: unexpected argument(s)
```

## Recommendation

Fix **WR-001** and **WR-002** before Phase 109 observe-only dry-run; otherwise WALK-03-02 and WALK-03-03 optional CLI will produce false `(a)` findings. Informational items can ride with Phase 110 triage or a narrow 108.x doc pass.

---

_Reviewed: 2026-05-27_  
_Reviewer: Cursor (gsd-code-reviewer)_  
_Depth: standard_
