---
phase: 202-release-0-10-0
plan: 09
subsystem: testing
tags: [release, doc-contract, elixir, mix-task, version-truth]

requires:
  - phase: 202-06
    provides: "`release.pins.ex` reads `@version` through `Mix.Project.config()[:version]`, a Dialyzer-resolvable API — the precondition for building shared derivation on top of it"
  - phase: 202-02
    provides: "`mix release.pins` as the designated sole writer of every documented install pin"
provides:
  - "The release-artifact contract derives README's expected install pin from `mix release.pins` instead of asserting a hardcoded `~> 0.9.0`"
  - "`Mix.Tasks.Release.Pins.target_pin_version/0` as the single `major.minor.0` derivation, with one owner and two readers"
  - "A rehearsed proof that bumping `@version` to the next minor and running the sole writer leaves this contract green with zero edits to it"
affects: [202-05, release, version-truth, born-red]

actuals:
  tokens: 1030
  tasks: 1
  commits: 1
plan_head_before: 1b99225bda08afb64a2b317e71ed7587960de439

tech-stack:
  added: []
  patterns:
    - "A documentation contract asks the designated writer what the value should be rather than restating the rule"

key-files:
  created: []
  modified:
    - test/threadline/release_artifact_contract_test.exs
    - lib/mix/tasks/release.pins.ex

key-decisions:
  - "Expose `target_pin_version/0` on the pins task rather than extract a shared module — `release.pins.ex:40-46` rules out extraction for a release-time-only concern, and the plan's own alternative (`the test must call into the pins task's public surface`) is what that reasoning permits"
  - "The failure message reports README's actual pin via a plain `{:threadline,` line filter, not a third copy of `@pin_regex` — the task/contract regex pair is deliberately a PAIR and a third copy would weaken its self-policing property"
  - "Three of the four version literals in the file are left alone as legitimately fixed (two vocabulary-matcher fixtures, one historical release tag CONTRIBUTING itself labels `illustrative`)"

patterns-established:
  - "One rule, one owner, two readers: where a duplicated rule cannot be self-policed by a contract, expose the owner's derivation instead of restating it"

requirements-completed: []

coverage:
  - id: D1
    description: "The README install-pin assertion derives its expected value from `mix release.pins`, so running the designated sole writer can never turn this contract red"
    requirement: "RELEASE-02"
    verification:
      - kind: integration
        ref: "test/threadline/release_artifact_contract_test.exs#README carries only the release-scoped installer and routing literals"
        status: pass
      - kind: other
        ref: "bump rehearsal: scratch branch, @version -> 0.10.0, `mix release.pins`, `mix test test/threadline/release_artifact_contract_test.exs` -> 19 tests, 0 failures, contract file untouched"
        status: pass
    human_judgment: false
  - id: D2
    description: "The assertion still fails when README's pin is genuinely wrong, with a message naming expected and actual"
    requirement: "RELEASE-02"
    verification:
      - kind: other
        ref: "negative control: README pin corrupted to `~> 0.8.0` -> 1 failure naming `expected: {:threadline, \"~> 0.9.0\"}` / `actual: {:threadline, \"~> 0.8.0\"}`; README md5 identical before and after"
        status: pass
    human_judgment: false
  - id: D3
    description: "Sibling doc contracts and the release verification steps do not regress"
    verification:
      - kind: integration
        ref: "mix test version_truth_doc_contract_test.exs upgrade_path_doc_contract_test.exs changelog_contract_test.exs -> 24 tests, 0 failures"
        status: pass
      - kind: other
        ref: "verify.release steps run individually: bin/verify-release-shape; mix test release_artifact+ci_topology (36/0); MIX_ENV=dev mix docs --warnings-as-errors; mix hex.build"
        status: pass
    human_judgment: false

duration: 22min
completed: 2026-09-22
status: complete
---

# Phase 202 Plan 09: Derive the README Install Pin Summary

**The release-artifact contract now asks `mix release.pins` what README's install pin should say instead of hardcoding `~> 0.9.0`, closing born-red cause BR-5 — proven by a next-minor bump rehearsal that leaves the contract green with zero edits to it.**

## Performance

- **Duration:** 22 min
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments

- **Literal inventory, honestly classified.** Every version-shaped literal in `test/threadline/release_artifact_contract_test.exs` was inventoried, not just the failing line. **4 literals total: 1 must-be-derived (fixed), 3 legitimately fixed (left alone).**

  | Line (pre-fix) | Literal | Classification | Why |
  |---|---|---|---|
  | 229 | `{"CHANGELOG.md", "Milestone v1.41"}` | **legitimately fixed** | Positive-control fixture fed to the planning-vocabulary matcher. It is an internal milestone literal the matcher must flag; it is a synthetic in-memory string, never read from a file. Deriving it would destroy the positive control. |
  | 239 | `"README.md" => "Threadline 0.9 audit data"` | **legitimately fixed** | Negative-control fixture proving `~r/\bv1\.(?:3[4-9]\|4[01])\b/` does **not** fire on a Threadline product version. Also synthetic — never read from README — so no bump can make it stale. Deriving it would stop testing the boundary it exists to test. |
  | 345 | `{:threadline, "~> 0.9.0"}` | **must be derived** | The install pin. `mix release.pins` is the designated sole writer of this exact value; a hand-maintained second copy goes red the moment the writer does its job. **Fixed.** |
  | 357 | `assert String.contains?(doc, "v0.6.0")` | **legitimately fixed** | A historical bootstrap release tag. `CONTRIBUTING.md:668` classifies it in its own table as *"human prose, historical record \| illustrative"*, and `:674` documents the one-shot `v0.6.0` bootstrap. It is a record of what happened, not a claim about the current version. |

- **The derivation is shared, not duplicated.** `Mix.Tasks.Release.Pins.target_pin_version/0` is now public (`@doc false`) and is the single `major.minor.0` derivation. The test calls it; the task's own `run/1` calls it. The test reimplements nothing.

- **Mechanism chosen, and the comment it honors.** `release.pins.ex:40-46` says, of the glob and the pin regex:

  > "The glob and the regex below are deliberately duplicated from `test/threadline/version_truth_doc_contract_test.exs` rather than extracted into a shared module. **A shared module would be new production surface for a release-time-only concern**, and the duplication is self-policing: the contract test goes red the moment this task and the contract disagree about which lines count. Do not 'fix' this by extracting it — keep the two expressions character-identical instead."

  Extraction is therefore off the table. The plan's stated alternative — *"the test must call into the pins task's public surface, or the derivation must be exposed deliberately"* — is exactly what that reasoning permits: **expose the existing derivation on the owner**. One rule, one owner, two readers, and no new module. The choice is recorded in a comment at the function itself.

  **Why exposure rather than character-identical duplication here:** the `:40-46` argument rests on duplication being *self-policing* — the contract test goes red when the two copies disagree. That property does not exist for the pin **value**. Two independent `major.minor.0` derivations agree on every input, forever; nothing would ever go red to reveal a drift, because there is no drift to reveal — only a second maintenance site. Duplication that cannot police itself is not the pattern `:40-46` is defending.

  The pin **regex** was deliberately left duplicated: the failure message reports README's actual pin with a plain `String.contains?(&1, "{:threadline,")` line filter, so no third copy of `@pin_regex` enters the tree.

- **Negative control — the contract still has teeth.** README's pin was corrupted to a wrong-but-plausible `~> 0.8.0` (md5 `d8aaf2e0…` → `a45bc5e4…`) and the contract failed:

  ```
  1) test README carries only the release-scoped installer and routing literals (Threadline.ReleaseArtifactContractTest)
     test/threadline/release_artifact_contract_test.exs:342
     README.md does not carry the install pin derived from mix.exs @version.
       expected: {:threadline, "~> 0.9.0"}
       actual:   {:threadline, "~> 0.8.0"}
     `mix release.pins` owns every documented pin — run it rather than editing the pin by hand.
     code: assert String.contains?(readme, expected_pin),
  ```

  README was restored from a byte copy and re-verified: md5 `d8aaf2e07fff79c3b0e0becd98a6ebb3` **before and after, identical**.

- **Bump rehearsal — the thing this plan exists to survive.** On scratch branch `scratch-202-09-bump-rehearsal`: `@version` set to `0.10.0`, `mix release.pins` run (rewrote 6 pin sites across README + 5 guides, `README.md: ~> 0.9.0 -> ~> 0.10.0`), then `mix test test/threadline/release_artifact_contract_test.exs` → **19 tests, 0 failures**, with `git diff --name-only` confirming the contract file was **not** edited. The pre-fix literal would have gone red here by construction. Scratch branch deleted; nothing carried forward.

## Task Commits

1. **Task 1: Derive the expected install pin instead of hardcoding it** — `07f46ed9` (fix)

## Files Created/Modified

- `test/threadline/release_artifact_contract_test.exs` — the README assertion derives `expected_pin` from `Mix.Tasks.Release.Pins.target_pin_version/0`; new `readme_install_pins/1` helper builds a failure message naming expected and actual without a third pin-regex copy.
- `lib/mix/tasks/release.pins.ex` — `target_pin_version/0` promoted from `defp` to `def` + `@doc false`, with a comment recording why exposure (not extraction, not duplication) is the right seam.

## Decisions Made

See `key-decisions` in the frontmatter. The load-bearing one is the mechanism: **expose the owner's derivation**, because `release.pins.ex:40-46` forbids a shared module and because value duplication — unlike the regex duplication that comment defends — has no self-policing property to justify it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `lib/mix/tasks/release.pins.ex` modified (plan declared only the test file)**

- **Found during:** Task 1
- **Issue:** `target_pin_version/0` was `defp`. With extraction ruled out by `release.pins.ex:40-46` and reimplementation ruled out by the plan's own prohibitions, there was no reachable single derivation without exposing the existing one.
- **Fix:** `defp target_pin_version do` → `@doc false` + `def target_pin_version do`, plus an explanatory comment. No logic change; no behavior change to `mix release.pins`.
- **Files modified:** `lib/mix/tasks/release.pins.ex` (+14 lines, 13 of which are comment)
- **Verification:** `mix release.pins` still derives and rewrites correctly (proven live in the bump rehearsal); `mix credo --strict` → no issues; `mix format --check-formatted` clean; `MIX_ENV=dev mix docs --warnings-as-errors` clean (the function stays off the rendered surface via `@moduledoc false`); the task remains excluded from the archive via `exclude_patterns` in `mix.exs`, so this is not new adopter API.
- **Committed in:** `07f46ed9`
- **Anticipated by:** the dispatch brief, which named this a legitimate deviation if the mechanism required it.

---

**Total deviations:** 1 auto-fixed (1 blocking). **Impact:** the minimum edit that makes a single shared derivation reachable. No scope creep.

## Observations That Disagree With, or Extend, the Plan

1. **The plan's framing implied more defect sites than exist.** The dispatch brief warned that "fixing only the line that happens to fail would leave siblings waiting to bite." The honest inventory found **no siblings** — line 345 was the only must-be-derived literal; the other three are correctly literals. The warning was right to demand the inventory; the inventory's answer is 1, not N.

2. **A different born-red site surfaced during the rehearsal, outside this plan's scope.** With `@version` bumped to `0.10.0` by hand, `version_truth_doc_contract_test.exs:81` (Family B) fails:

   > `guides/adoption-pilot-backlog.md` has an `x-release-please-version` marked line that does not contain the current `@version 0.10.0`.

   **This is most likely a rehearsal artifact, not a defect.** Family B lines are owned by release-please's `extra-files` pass, which rewrites them *in the same release commit* that bumps `mix.exs` — a hand-edit of `mix.exs` alone deliberately desynchronizes the pair. It is recorded here because the rehearsal is the only place it is visible, and because a real release should confirm that `extra-files` does in fact cover `guides/adoption-pilot-backlog.md` (release-runbook memory notes this exact line as the historical born-red site). **Not fixed; not in scope for 202-09.**

3. **`mix verify.release` could not be run as a single alias**, as the dispatch brief predicted: `ensure_clean_tree!()` (`mix.exs:381`) halts on the pre-existing dirty `.planning/` files. Its four steps were run individually and all passed — `bin/verify-release-shape` (`Release shape OK for version 0.9.0`), `mix test release_artifact + ci_topology` (36 tests, 0 failures), `MIX_ENV=dev mix docs --warnings-as-errors`, `mix hex.build` (`Saved to threadline-0.9.0.tar`).

## Verification

| Check | Result |
|---|---|
| `mix test test/threadline/release_artifact_contract_test.exs` | 19 tests, **0 failures** |
| `mix test version_truth + upgrade_path + changelog contracts` | 24 tests, **0 failures** |
| `grep -n '~> 0\.9\.0' test/threadline/release_artifact_contract_test.exs` | **no matches** (exit 1) |
| `mix format --check-formatted` | clean |
| `mix credo --strict` | 3167 mods/funs, **no issues** |
| Negative control (README pin corrupted) | **fails** with expected/actual named |
| README md5 before / after negative control | `d8aaf2e07fff79c3b0e0becd98a6ebb3` / identical |
| Bump rehearsal at `@version 0.10.0` | 19 tests, **0 failures**, contract file untouched |
| Scratch branch after rehearsal | `git branch --list 'scratch*'` → **empty** |
| `git status --porcelain` before / after task | identical: ` M .planning/WINDOWS.md`, ` M .planning/config.json`, `?? .tool-versions` |
| Branch / HEAD after rehearsal | `fix/branch-protection-actions-capability` @ `07f46ed9` |

## Issues Encountered

None.

## User Setup Required

None.

## Next Phase Readiness

BR-5 is closed. All four gap-closure plans (202-06 through 202-09) are complete, so the red gates that halted **202-05** are cleared and 202-05's dress rehearsal / human-gated publish can resume.

**RELEASE-01 is deliberately NOT marked complete** — 0.10.0 is not published. RELEASE-02 is not marked complete here either: this plan removed one obstacle to it, but the criterion ("every version-bearing line managed by release automation") is settled by 202-05's real release, and observation 2 above is an open question against it.

## Self-Check: PASSED

- `test/threadline/release_artifact_contract_test.exs` — present on disk
- `lib/mix/tasks/release.pins.ex` — present on disk
- `.planning/phases/202-release-0-10-0/202-09-SUMMARY.md` — present on disk
- Commit `07f46ed9` — found in `git log --oneline --all`

---
*Phase: 202-release-0-10-0*
*Completed: 2026-09-22*
