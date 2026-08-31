---
phase: 198-green-bringup
plan: 21
subsystem: testing
tags: [ci, ci-required, merge-gate, branch-protection, contract-test, needs-list, D-42]

requires:
  - phase: 198-20
    provides: "Maintainer's recorded verbatim dispositions for verify-capture, verify-example-browser, and mix verify.example (D-39/D-40/D-41), plus the standing needs:/ruleset/CONTRIBUTING.md interlock finding (D-42)"
provides:
  - "Confirmation that ci-required's needs: list is already in its decided (all-keep) state — no ci.yml, rulesets/main.json, or playwright.config.ts edit required"
  - "A CONTRIBUTING.md ## CI Coverage roster subheading naming every current needs: job id"
  - "Two executable contract tests in ci_topology_contract_test.exs: a needs:-vs-documented-roster drift guard (both directions, non-vacuity, allowed-skips/allowed-failures laundering guard) and a ruleset-singleton/emitted-name exact-match guard"
affects: [198-VERIFICATION, green-07, green-08, ci-required, 198-22]

actuals:
  tokens: 2174
  tasks: 2
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Derive-from-source contract test pairs (workflow YAML <-> documented roster; ruleset JSON <-> job name:), following the existing ci_topology_contract_test.exs read-and-assert idiom rather than a new harness"
    - "Mutate-observe-revert-observe teeth proof for guard tests that assert an already-true invariant, in place of literal pre-implementation RED, since the guards are not testing not-yet-built behavior"

key-files:
  created: []
  modified:
    - CONTRIBUTING.md
    - test/threadline/ci_topology_contract_test.exs

key-decisions:
  - "Task 1 made zero file edits. All three 198-20 dispositions (D-39, D-40, D-41) are 'keep in needs:', so ci-required's needs: list, .github/rulesets/main.json, playwright.config.ts, and CONTRIBUTING.md's existing required/non-required markings were already correct — verified against source, not assumed. An empty Task 1 diff is the plan's own documented correct outcome for an all-keep decision, not a shortfall."
  - "Task 2's roster test derives ci-required's needs: list by isolating the block after the literal marker \"\\n  ci-required:\\n\" (ci-required is the final job in ci.yml's jobs: map) rather than parsing YAML with a library, matching the file's existing regex-based idiom and mix.exs's lack of a yaml dependency."
  - "The singleton test decodes .github/rulesets/main.json with Jason (already a project dependency) rather than adding a new one."
  - "Chose to represent CONTRIBUTING.md's new roster as a bullet list under a dedicated \"### `ci-required` needs: roster\" subheading (backtick-quoted job ids, one per line) so the roster test can extract it with a simple line regex without disturbing the existing project-list table the doc-contract test already parses."

requirements-completed: []

coverage:
  - id: D1
    description: "ci-required's needs: list is confirmed in exactly its 198-20-decided (all-keep) state; ci.yml, rulesets/main.json, and playwright.config.ts are untouched"
    requirement: "GREEN-07"
    verification:
      - kind: unit
        ref: "git diff --quiet .github/rulesets/main.json && git diff --quiet examples/threadline_phoenix/e2e/playwright.config.ts; python3 needs-count check == 12 >= 10; grep -c 'ci-required:' == 1; grep -c 'name: CI required' == 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Roster contract test derives ci-required's needs: from ci.yml, compares against a new CONTRIBUTING.md roster subheading, fails distinctly on each drift direction, on non-vacuity (<10 entries), and on undocumented allowed-skips/allowed-failures; observed red (three separate mutations) then green"
    requirement: "GREEN-07"
    verification:
      - kind: unit
        ref: "mix test test/threadline/ci_topology_contract_test.exs:255 (roster test) — 0 failures after mutation-and-revert"
        status: pass
    human_judgment: false
  - id: D3
    description: "Singleton contract test asserts .github/rulesets/main.json names exactly one required status check context, byte-exact-equal to the literal \"CI required\", matching ci-required's emitted name:; observed red (two separate mutations) then green"
    requirement: "GREEN-08"
    verification:
      - kind: unit
        ref: "mix test test/threadline/ci_topology_contract_test.exs:295 — 0 failures after mutation-and-revert"
        status: pass
    human_judgment: false
  - id: D4
    description: "No regression: full mix test suite, mix format --check-formatted, and mix credo --strict all clean after the plan's changes"
    verification:
      - kind: unit
        ref: "mix test — 1422 tests, 0 failures (1 excluded); mix format --check-formatted — clean; mix credo --strict — 2726 mods/funs, found no issues"
        status: pass
    human_judgment: false

duration: ~55min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 21: `CI required` self-guarding merge gate Summary

**Confirmed all three 198-20 lane dispositions are already applied (zero `ci.yml`/ruleset diff), then added two derive-from-source contract tests — a `needs:`-vs-documented-roster drift guard and a ruleset-singleton/emitted-name exact-match guard — each observed red against a deliberate mutation of its source of truth before being observed green.**

## Performance

- **Duration:** ~55 min (Task 1 read/verify ~15 min; Task 2 test authoring + four mutation-teeth-proofs + format/credo/full-suite verification ~40 min)
- **Started:** 2026-08-28 (session continuation)
- **Completed:** 2026-08-28
- **Tasks:** 2 of 2 completed (Task 1 tracer, Task 2 auto/tdd)
- **Files modified:** 2

## Accomplishments

- **Task 1 (tracer):** Read the 198-20 recorded dispositions (D-39 `verify-capture` keep, D-40 `verify-example-browser` keep-and-defer, D-41 `mix verify.example` keep-and-defer) and verified against source that all three are already the state on disk: `ci-required`'s `needs:` carries all 12 pre-existing entries in order (`verify-format, verify-credo, verify-compile-no-optional, verify-test, verify-hex-evaluator, verify-example-browser, verify-mechanical, verify-capture, verify-pgbouncer-topology, verify-docs, verify-hex-package, verify-release-shape`), `.github/rulesets/main.json` is untouched, `examples/threadline_phoenix/e2e/playwright.config.ts` is untouched, and `CONTRIBUTING.md`'s `## CI Coverage` table already marks the required/non-required rows correctly with no reduction to disclose. **No file was edited for Task 1** — its own acceptance criterion anticipated exactly this outcome for an all-"keep" decision set. Verified `mix test test/threadline/ci_coverage_doc_contract_test.exs` (2 tests, 0 failures) still passes unchanged.
- **Task 2 (auto, tdd):** Added a `### \`ci-required\` needs: roster` subheading to `CONTRIBUTING.md`'s `## CI Coverage` section, listing all 12 current `needs:` job ids as backtick-quoted bullets, plus a sentence on the documented convention for citing a future `allowed-skips`/`allowed-failures` decision.
- Added two tests to `test/threadline/ci_topology_contract_test.exs`:
  1. **Roster test** (`"ci-required's needs: roster matches CONTRIBUTING.md in both drift directions and stays non-vacuous"`) — derives `needs:` from `ci.yml`, compares as sets against the new CONTRIBUTING.md roster, asserts non-vacuity (>=10 entries), and asserts `allowed-skips`/`allowed-failures` stay absent from the alls-green step unless the roster section documents a decision citation for them.
  2. **Singleton test** (`"the ruleset's sole required status check is byte-exact with ci-required's emitted name"`) — decodes `.github/rulesets/main.json` via `Jason`, asserts exactly one `required_status_checks` context, asserts it is byte-exact-equal (`===`) to the literal `"CI required"`, and asserts it matches `ci-required`'s emitted `name:` in `ci.yml`.
- Proved both tests have teeth via four separate mutate-observe-revert-observe cycles (all reverted; `git diff --quiet .github/` confirmed clean after each and at the end):
  1. Deleted `- verify-docs` from `ci.yml`'s `needs:` list -> roster test failed naming `["verify-docs"]` as the silent-narrowing case.
  2. Deleted the corresponding `- \`verify-docs\`` bullet from CONTRIBUTING.md's roster -> roster test failed naming `["verify-docs"]` as the docs-omit case (distinct message from #1).
  3. Truncated `ci.yml`'s `needs:` to 3 entries -> roster test failed on the non-vacuity assertion (`"only 3 entries"`), independent of roster matching.
  4. Appended a second `{"context": "Extra check"}` to `.github/rulesets/main.json` -> singleton test failed on the `length(contexts) == 1` assertion.
  5. Renamed `ci-required`'s `name:` to `"CI Required Renamed"` -> singleton test failed on the `job_name === context` assertion.
- Ran `mix format` on the new test file (one auto-fix needed for a multi-line `flunk/1` call), then confirmed `mix format --check-formatted` clean repo-wide and `mix credo --strict` reports no new issues (2726 mods/funs, 0 issues).
- Ran the full suite: **1422 tests, 0 failures (1 excluded)** — up from the phase's 1420-test/0-failure baseline by exactly the 2 new tests, confirming no regression.

## Task Commits

Task 1 produced no file change and therefore no commit — the plan's own acceptance criteria anticipate an empty diff when every disposition is "keep" (all three were). Task 1's verification was still fully executed (see Accomplishments and Deviations below).

1. **Task 2: Make the merge gate self-guarding** — `8f306a39` (test)

**Plan metadata:** committed alongside this SUMMARY.

## Files Created/Modified

- `CONTRIBUTING.md` — added `### \`ci-required\` needs: roster` subheading under `## CI Coverage`, listing all 12 current `needs:` job ids and the allowed-skips/allowed-failures decision-citation convention.
- `test/threadline/ci_topology_contract_test.exs` — added the roster drift-guard test and the ruleset-singleton exact-match test, plus their shared helper functions (`ci_required_block/0`, `ci_required_needs/0`, `strip_comment_lines/1`, `documented_needs_section/0`, `documented_needs_roster/0`).

## Decisions Made

- **Task 1 confirmed rather than applied — no edit was made.** Read `198-CONTEXT.md`'s D-39/D-40/D-41 and `.github/workflows/ci.yml`, `.github/rulesets/main.json`, and `CONTRIBUTING.md` directly, and found every disposition already reflected on disk (all three lanes stay in `needs:`; no coverage reduction to disclose; `git diff --quiet` on the ruleset and Playwright config both exit 0 without any edit). Per the plan's own acceptance criterion — "`git diff --name-only` for this task ... is empty if every disposition was 'keep'" — this is the correct outcome, not a shortfall.
- **Recorded the reasons GREEN-07 and GREEN-04 stay open**, per the recorded-dispositions instructions:
  - `verify-capture` remains blocking because every remedy for the `scrollHeight`-coupled `scroll_cost` diagnosis (198-16) requires Tier-A `page.*` regeneration, which the maintainer had already re-ratified as forbidden this milestone (D-39).
  - `verify-example-browser` remains blocking because its 28 masked Playwright failures (across `operator-find-mobile.spec.ts`, `operator-phase-135/173/175/177-uat.spec.ts`, `operator-screenshot-regression.spec.ts`, `operator-screenshots.spec.ts`, `register.spec.ts`) exceed a single executor's context budget and require a dedicated successor round (D-40). **Recorded here, per the plan's own instruction, as a written recommendation to the orchestrator: plan a dedicated round scoped to those 28 failures across those named spec files, in the same red-then-green, no-weakening manner 198-17 used — 198-21 must not and did not attempt it.**
  - `mix verify.example` (inside `verify-test`'s `current` lane) remains a source of `Run test suite (current)` failure because 8 demo-seed content mismatches (14 hits in `demo_contract_test.exs`, 5 in `walkthrough_happy_path_test.exs`, 3 in `walkthrough_evidence_test.exs`) persist even though the originally-named `search_path` cause is genuinely fixed by 198-19 (D-41). **Recorded here, per the plan's own instruction, as a written recommendation to the orchestrator: plan a dedicated round scoped to those 8 failures across those three files — 198-21 must not and did not attempt it.**
- **Chose regex-based parsing over a YAML/JSON library dependency addition** for the `needs:` derive (matching the file's existing idiom; `mix.exs` has no YAML dependency), and used the already-present `Jason` dependency for the ruleset JSON decode.
- **Combined all roster sub-assertions (equality-both-directions, non-vacuity, allowed-skips/allowed-failures) into one test function**, matching the plan's action text describing "the first" test as a single unit performing multiple checks, and proved each sub-assertion's teeth with its own targeted mutation rather than splitting into separate `test` blocks.

## Deviations from Plan

None — plan executed exactly as written. Task 1's zero-file-diff outcome is the plan's own documented expected result for an all-"keep" decision set, not a deviation. Task 2's two new tests, the CONTRIBUTING.md roster subheading, and the four mutation-teeth-proofs all match the plan's `<action>` and `<acceptance_criteria>` verbatim.

## Issues Encountered

- One `mix format` fix needed on the new test file (a multi-line `flunk/1` call needed reformatting to satisfy the formatter) — applied via `mix format`, no logic change, confirmed by `mix format --check-formatted` clean afterward.
- Working with BSD `sed` (macOS) for scripted mutations required switching from inline `sed -i` range-address deletes to small Python scripts for two of the four mutations, since BSD `sed`'s `-i` and brace-address syntax differ from GNU `sed`. No impact on the mutation content or the observed red/green results.

## User Setup Required

None — no external service configuration required. This plan only modified `CONTRIBUTING.md` and a test file.

## Next Phase Readiness

- **GREEN-07 remains Pending**, unchanged from 198-20's assessment: `verify-capture` and `verify-example-browser` both stay in `ci-required`'s `needs:`, both for reasons outside this plan's authority to resolve (Tier-A regeneration prohibition; 28-failure successor round respectively).
- **GREEN-04 remains Pending**, unchanged from 198-20's assessment: `Run test suite (current)` is still expected to conclude FAILURE on plan 198-22's next measured CI run, for the 8 demo-seed content mismatches, distinct from the already-fixed `search_path` cause.
- **GREEN-08 is non-regressed and now executable, not merely asserted in prose.** The singleton contract test (`test/threadline/ci_topology_contract_test.exs:295`) now proves locally, on every `mix test` run, that `.github/rulesets/main.json` names exactly one required context and that it byte-exact-matches `ci-required`'s emitted `name:` — the exact-match hazard D-08 was adopted to dissolve is now a red test if it ever regresses, rather than something only a live-CI observation could catch.
- **Two dedicated successor planning rounds are required before plan 198-21's scope is exhausted**, exactly as 198-20 named them: (1) the 28 masked Playwright failures across the named spec files; (2) the 8 demo-seed content mismatches across the three named test files. Neither was attempted here, per explicit instruction.
- **A future silent narrowing of `ci-required`'s `needs:` list is now a red test, not an invisible YAML edit** — the roster contract test (`test/threadline/ci_topology_contract_test.exs:255`) fails the moment a `needs:` entry is removed without a matching `CONTRIBUTING.md` roster edit, in either direction, and fails on a degenerate (<10-entry) derive too.
- No blockers for plan 198-22 (the next real measured CI run). Both `Run test suite (current)` and the two kept-required lanes are expected to still report `failure` on that run, per this plan's honest carry-forward of 198-20's recorded consequences — this plan changes nothing about that expectation.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*
