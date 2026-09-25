---
phase: 207-gen-triggers-rerun-name-collision-storage-schema-default-doc
plan: 03
subsystem: docs
tags: [guides, changelog, storage_schema, gen.triggers, doc-contract, postgres]

requires:
  - phase: 207-02
    provides: "numbered rerun migrations, per-table rollback comment, ## Rerunning moduledoc phrases"
provides:
  - "Every guide states the public storage_schema default; guard over guides/**/*.md + README.md"
  - "Drift guides describe rerun + rollback; doc contract ties guides, moduledoc and generated down comment"
  - "CHANGELOG Unreleased entry for the rerun fix and guide corrections"
  - "End-to-end proof on real PostgreSQL that three consecutive generated migrations apply and converge"
affects: [release 0.10.2, phase verification]

actuals:
  tokens: 4600
  tasks: 3
  commits: 2
plan_head_before: 50dcb9fdc54b865fe944f3eda8bd49fad2682d41

tech-stack:
  added: []
  patterns:
    - "Doc default-claim guard: scope lines by regex, capture claimed values, compare to the code default, positive-control matcher test plus non-vacuity floor"
    - "Regex sources (not compiled regexes) in module attributes, compiled in the helper"
    - "Shared-phrase doc contract: one attribute list pins guides, moduledoc (Code.fetch_docs) and generated output"

key-files:
  created: []
  modified:
    - test/threadline/storage_schema_test.exs
    - test/mix/tasks/threadline/gen_triggers_test.exs
    - guides/audit-indexing.md
    - guides/production-checklist.md
    - guides/how-threadline-works.md
    - guides/domain-reference.md
    - CHANGELOG.md

key-decisions:
  - "Guard regexes stored as source strings and compiled at call time, so the test module still compiles on OTP releases that reject compiled regexes in module attributes"
  - "Rerun doc contract collects every missing phrase and asserts once, so a failure names every guide at fault instead of the first"
  - "CHANGELOG names the four corrected guides by path; the hidden SQL module is not named"

patterns-established:
  - "Default-claim guard: new guides are covered automatically via Path.wildcard(\"guides/**/*.md\") ++ [\"README.md\"]"

requirements-completed: [W1, W2]

coverage:
  - id: D1
    description: "All four wrong-default guide sentences now say storage_schema defaults to public, with a dedicated schema as an opt-in chosen before install"
    requirement: "W2"
    verification:
      - kind: unit
        ref: "test/threadline/storage_schema_test.exs#every documented storage_schema default matches the code default"
        status: pass
    human_judgment: false
  - id: D2
    description: "Default-claim guard: proven RED on the four sites, positive-control matcher test, non-vacuity floor of 3 correct claims"
    requirement: "W2"
    verification:
      - kind: unit
        ref: "test/threadline/storage_schema_test.exs#the default-claim matcher flags every known offender"
        status: pass
      - kind: other
        ref: "/Users/jon/.claude/jobs/77cf1bdd/tmp/207-03-t1-red.txt (RED run)"
        status: pass
    human_judgment: false
  - id: D3
    description: "production-checklist and domain-reference describe rerun + rollback truthfully, pinned to the moduledoc and the generated down comment"
    requirement: "W1"
    verification:
      - kind: integration
        ref: "test/mix/tasks/threadline/gen_triggers_test.exs#describe rerun documentation (2 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "CHANGELOG Unreleased entry: prose paragraph, Required action, three Fixed bullets quoting both errors, releases 0.1.0 through 0.10.1"
    requirement: "W1"
    verification:
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs; test/threadline/release_artifact_contract_test.exs; MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
    human_judgment: true
    rationale: "Whether the release note reads clearly to an upgrader is a judgment call; tests prove only shape, vocabulary and that docs build"
  - id: D5
    description: "Three consecutive generated posts migrations (default, --store-changed-from, default) apply on real PostgreSQL and converge to one trigger on the global function with no leftover per-table function"
    requirement: "W1"
    verification:
      - kind: e2e
        ref: "psql -v ON_ERROR_STOP=1 against throwaway DB threadline_probe_207 (dropped afterwards)"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-09-24
status: complete
---

# Phase 207 Plan 03: storage_schema default docs, rerun docs and phase gate Summary

**Four guides now state the real `storage_schema` default, `public`, and a test scans every guide and the README so a wrong default claim fails CI. The drift guides now describe what a rerun migration does and what rolling it back does, using the same wording as the generated migration. The CHANGELOG has a 0.10.2 entry for the fix. Three consecutive generated trigger migrations were applied on real PostgreSQL and left exactly one trigger.**

## Performance

- **Duration:** about 7 min
- **Started:** 2026-09-24T21:16:52Z
- **Completed:** 2026-09-24T21:23:38Z
- **Tasks:** 3 (2 committed, 1 verification-only)
- **Files modified:** 7

## Accomplishments
- The wrong-default sentences at `audit-indexing.md:7`, `production-checklist.md:14`, `how-threadline-works.md:94` and `domain-reference.md:311` are corrected to match the voice of `getting-started-saas.md` and `configuration-and-commands.md`. The "historical footprint" wording is gone.
- The widened guard in `storage_schema_test.exs` checks every default claim on a storage-schema line in `guides/**/*.md` and `README.md` against `StorageSchema.get([])`. It was proven RED against the four sites before they were fixed, a positive-control test covers each bad sentence and the opt-in examples, and a floor of 3 correct claims stops it passing vacuously.
- `production-checklist.md` (rerun checklist item) and `domain-reference.md` (a new paragraph after the three status bullets, which are kept verbatim) now say four things:
  - a rerun writes a numbered migration that replaces the trigger in place
  - a rollback keeps capture on and does not restore the earlier capture policy
  - a rolled-back rerun that removed redaction keeps capturing unredacted, and the drift view and `mix threadline.policy.show` flag it
  - how to stop capture on a table
- A `describe "rerun documentation"` in `gen_triggers_test.exs` pins those phrases in both guides, the gen.triggers moduledoc (read through `Code.fetch_docs`) and a generated rerun `down` comment, all from one attribute list.
- The CHANGELOG Unreleased block gains a second prose paragraph, a Required action paragraph and three Fixed bullets. It still has exactly one set of `###` headings, and Breaking changes is still None.

## Task Commits

1. **Task 1 (tracer): default-claim guard + four guide corrections**: `96f703c6` (docs)
2. **Task 2: rerun doc contract, drift guides, CHANGELOG**: `a69b0cc1` (docs)
3. **Task 3: phase gate**: verification only, no commit

Each task wrote its test first and saved the RED run. RED and GREEN went into one commit per task, using the plan's docs subjects.

## RED proof

**Task 1** (`/Users/jon/.claude/jobs/77cf1bdd/tmp/207-03-t1-red.txt`): `11 tests, 1 failure`. The real-tree test failed with:
`these docs claim a storage_schema default other than "public", ...: guides/audit-indexing.md:7 -> threadline, guides/domain-reference.md:311 -> threadline, guides/how-threadline-works.md:94 -> threadline, guides/production-checklist.md:14 -> threadline, guides/production-checklist.md:14 -> threadline`.
The matcher positive-control test passed, as designed. After the guide edits: 11 tests, 0 failures.

**Task 2** (`/Users/jon/.claude/jobs/77cf1bdd/tmp/207-03-t2-red.txt`): `15 tests, 1 failure`. The guides test failed with:
`guides/production-checklist.md lacks "replaces the trigger in place"; ... lacks "does not restore the earlier capture policy"; ... lacks "unredacted"; guides/domain-reference.md lacks` the same three phrases.
The moduledoc part passed, which confirms plan 02's phrases. The generated-down test passed. After the guide edits: 15 tests, 0 failures.

## End-to-end probe

The script `/Users/jon/.claude/jobs/77cf1bdd/tmp/207-probe.exs` was run with `MIX_ENV=test mix run --no-start`. The SQL was applied with `psql -v ON_ERROR_STOP=1` to the throwaway database `threadline_probe_207`, which was dropped afterwards (`pg_database` count is 0).

```
generated: 20260924212018_threadline_triggers_posts.exs
generated: 20260924212019_threadline_triggers_posts_2.exs
generated: 20260924212020_threadline_triggers_posts_3.exs
statements: 8
CREATE TABLE
CREATE FUNCTION
CREATE TRIGGER
psql:.../207-e2e.sql:73: NOTICE:  function public.threadline_capture_changes_posts() does not exist, skipping
DROP FUNCTION
CREATE FUNCTION
CREATE TRIGGER
CREATE TRIGGER
DROP FUNCTION
1
threadline_capture_changes
0
DROP DATABASE
probe_rc=0
```
The probe ran to completion. The query results are 1 trigger, the global function, and 0 leftover per-table functions. The third migration's `DROP FUNCTION` removed the per-table function that the second migration installed. It printed no NOTICE, so the drop was real and not a no-op.

## Gate results

- Contract batch (16 paths): `205 tests, 0 failures`.
- Full suite, `mix verify.test`: `Finished in 133.1 seconds (7.6s async, 125.5s sync)` / `1839 tests, 0 failures, 1 excluded` (exit 0).
- `mix compile --force --warnings-as-errors`: passed.
- `mix verify.format`: passed.
- `MIX_ENV=test mix verify.credo`: no issues in 323 files.
- `MIX_ENV=dev mix verify.dialyzer`: 0 errors. The PLT was current, so no rebuild was needed.
- `mix verify.xref_cycles`: no cycles.
- `MIX_ENV=dev mix release.pins --check`: 0 differing pin sites.
- `MIX_ENV=dev mix docs --warnings-as-errors`: passed, with no warnings.
- Hygiene checks:
  - `git diff --stat 1a9fbd53~1..HEAD -- examples/ priv/` is empty.
  - This phase has exactly 7 commit subjects, all `fix(gen.triggers)` / `docs(guides)` / `docs(gen.triggers)`, and none contains an ID.
  - `git status` shows only the pre-existing `.planning/WINDOWS.md` and `.planning/config.json` changes and the pre-existing untracked files.

## Files Created/Modified
- `test/threadline/storage_schema_test.exs`: adds the default-claim attributes, the `default_claims/1` helper and two tests inside the `default storage schema (D-01)` describe. The existing tests are unchanged.
- `test/mix/tasks/threadline/gen_triggers_test.exs`: adds `@repo_root`, `@rerun_doc_phrases`, `@generated_down_phrases` and `describe "rerun documentation"`. The existing tests are unchanged.
- `guides/audit-indexing.md`, `guides/how-threadline-works.md`: default sentence corrected.
- `guides/production-checklist.md`: default corrected, and the rerun checklist item extended.
- `guides/domain-reference.md`: default corrected, and a rerun/rollback paragraph added before "This is a viewer, not a mutator."
- `CHANGELOG.md`: the Unreleased entry.

## Decisions Made
- The regex sources live in module attributes and are compiled inside the helper. The plan said "compile with Regex.compile!/2 at module level", but compiled regexes in module attributes stop compiling on newer OTP releases, and the behaviour is otherwise the same.
- The `default_claims/1` helper is at module level. The tests are inside the describe, as planned.
- The rerun guides test collects every missing phrase before asserting, so the RED run names both guides.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rerun doc test stopped at the first missing phrase**
- **Found during:** Task 2 RED
- **Issue:** One assertion per phrase inside a `for` loop failed on the first gap. The RED output named only production-checklist.md, but the acceptance criterion needs both guides named.
- **Fix:** The test now collects every `source lacks phrase` into a list and asserts that the list is empty.
- **Files modified:** test/mix/tasks/threadline/gen_triggers_test.exs
- **Verification:** The re-run RED named all six gaps across both guides. GREEN passed after the edits.
- **Committed in:** a69b0cc1

**2. [Rule 1 - Bug] The plan's CHANGELOG awk slice spans the whole file**
- **Found during:** Task 2 acceptance
- **Issue:** `awk '/^## Unreleased/{f=1} f&&/^## [0-9]/{exit} f'` never exits, because dated headings are `## [0.10.1]`, not `## 0...`. It therefore counted headings in every release: 2 Fixed, 3 Breaking, 3 Required.
- **Fix:** No file change was needed. I re-checked with a slice that stops at the next `## ` heading. Within `## Unreleased — highlights` there is exactly 1 of each heading, and the vocabulary grep is empty.
- **Committed in:** n/a (verification only)

---

**Total deviations:** 2 (1 test fix, 1 corrected acceptance check). **Impact:** no change in scope. The contract and the acceptance intent both hold.

## TDD Gate Compliance

There are no separate `test(207-03)` / `feat(207-03)` commits. The plan prescribes docs subjects per task (D-13 release-note hygiene), so RED and GREEN share one commit per task, as in plans 01 and 02. The RED evidence is the two saved files listed above. `workflow.tdd_mode` is not enabled.

## Issues Encountered
None.

## User Setup Required
None. No external service configuration is required.

## Next Phase Readiness
- Phase 207 is complete: 3 of 3 plans have summaries. It is ready for phase verification, and its commits ride into 0.10.2.
- The `README.md` and `guides/operator-surface.md` "rerun gen.triggers" mentions are unchanged by design, because they are true after the fix.

---
*Phase: 207-gen-triggers-rerun-name-collision-storage-schema-default-doc*
*Completed: 2026-09-24*

## Self-Check: PASSED
