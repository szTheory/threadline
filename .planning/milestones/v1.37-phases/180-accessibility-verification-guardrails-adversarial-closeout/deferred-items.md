# Deferred Items

## 180-01: `mix precommit` demo seed failures

- **Found during:** Plan 180-01 final AGENTS.md verification
- **Command:** `mix precommit` from `examples/threadline_phoenix`
- **Status:** acknowledged
- **Acknowledged at:** v1.40 milestone close, 2026-08-27
- **Scope:** Out of scope for Plan 180-01
- **Evidence:** 95 tests ran, 7 failed in demo seed/walkthrough coverage:
  - `ThreadlinePhoenixWeb.WalkthroughEvidenceTest` missing #4521 close/redaction evidence transaction.
  - `ThreadlinePhoenixWeb.WalkthroughHappyPathTest` #4518 deleter hard-delete timestamp assertion failed.
  - `ThreadlinePhoenix.DemoContractTest` SEED-03/SEED-05/D-05 demo contract rows returned no matching audit transactions/changes.
- **Why deferred:** Plan 180-01 changed rendered accessibility browser coverage plus shared UI/stress/retention semantics only; it did not modify demo seed data, walkthrough tests, audit capture, or seed contract logic.
- **Plan-owned verification:** `mix compile --warnings-as-errors`, focused operator-surface ExUnit tests, and both required `operator-accessibility.spec.ts` browser lanes passed after the accessibility fixes.
