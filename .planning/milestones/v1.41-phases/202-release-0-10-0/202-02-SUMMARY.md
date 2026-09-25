---
phase: 202-release-0-10-0
plan: 02
subsystem: infra
tags: [hex, release, mix-task, doc-contract, packaging, release-please]

requires:
  - phase: 202-release-0-10-0
    provides: "Plan 01's flipped storage-schema default and rehearsal registry; the install pin literal in guides/getting-started-saas.md was deliberately left untouched there for this plan to own"
provides:
  - "`mix release.pins` — derives every documented install pin from `mix.exs` `@version`, with a write-free `--check` gate mode"
  - "A fourth family in the version-truth doc contract: no install-pin line may also carry a release-please version marker"
  - "`package[:exclude_patterns]` in `mix.exs` keeping 11 maintainer-only files (4,706 lines) out of the published tarball"
  - "Archive refutations measured against the UNPACKED tarball, including a pre-emptive guard on the bot-owned generated changelog"
  - "A CONTRIBUTING.md ownership table classifying every remaining version-bearing line as illustrative or current-version claim"
affects: [202-03 changelog and upgrade guide, 202-04 release.yml wiring, 202-05 post-publish verification]

actuals:
  tokens: 5404
  tasks: 4
  commits: 4
  plan_head_before: 8bcbe008d9614aa0dbde9073017c6fafa29aa101

tech-stack:
  added: []
  patterns:
    - "Deliberate duplication over a shared module for a release-time-only derivation: the task and the contract carry character-identical glob and regex expressions, and the contract goes red the moment they disagree"
    - "Non-vacuity assertion before refutation: a refutation test first asserts its own scan found something, so a broken glob cannot make the guard pass silently"
    - "Existence + absence pairing: each enumerated maintainer-only path must exist in the repository AND be absent from the archive, so a rename cannot masquerade as an exclusion"

key-files:
  created:
    - lib/mix/tasks/release.pins.ex
  modified:
    - test/threadline/version_truth_doc_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
    - mix.exs
    - CONTRIBUTING.md

key-decisions:
  - "The pin derivation is duplicated into `mix release.pins` rather than extracted into a shared module — a shared module would be new production surface for a release-time-only concern"
  - "`mix release.pins` reads `@version` at runtime rather than freezing it into a module attribute, so a bump can never be shadowed by a stale compiled artifact"
  - "The task carries `@moduledoc false`, not a rendered moduledoc: the public-surface contract requires every visible module to be grouped, and a maintainer-only task is not adopter surface"
  - "`files:` was left as a pattern allowlist and narrowed with `exclude_patterns:` rather than converted into a file-granular enumeration of `lib/`"
  - "The stress and mechanical harness files were dropped as archive source-vocabulary owners because they are no longer packaged; the exclusion refutations replace them"

patterns-established:
  - "Ownership tables over remembered convention: every version-bearing line has a named owner recorded in CONTRIBUTING.md, and the pin/marker separation that was a code comment is now a failing-capable test"
  - "Guard the future file: the generated-changelog refutation is committed before the file it guards exists"

requirements-completed: [RELEASE-02]

coverage:
  - id: D1
    description: "A minor-version bump produces every install pin in README.md and guides/**/*.md by running `mix release.pins` — no maintainer opens a doc file to change a pin by hand."
    requirement: "RELEASE-02"
    verification:
      - kind: other
        ref: "simulated minor bump (@version 0.10.0): mix release.pins rewrote exactly 6 pin sites; git status --porcelain listed exactly those 6 files"
        status: pass
      - kind: unit
        ref: "test/threadline/version_truth_doc_contract_test.exs#every threadline install pin across README + guides equals the derived ~> 0.9.0"
        status: pass
    human_judgment: false
  - id: D2
    description: "`mix release.pins` is a provable no-op at a patch bump, leaves pin-free doc files byte-identical, and is idempotent across consecutive runs."
    requirement: "RELEASE-02"
    verification:
      - kind: other
        ref: "simulated patch bump (@version 0.9.1): task reported 0 rewrites, git diff --exit-code exited 0"
        status: pass
      - kind: other
        ref: "20 files scanned, 6 modified under the minor bump — the other 14 left byte-identical per git status"
        status: pass
      - kind: other
        ref: "md5 of README.md + guides/*.md identical across two consecutive runs"
        status: pass
    human_judgment: false
  - id: D3
    description: "No line carrying a threadline `~>` install pin also carries a release-please version marker, enforced by a test rather than a code comment."
    requirement: "RELEASE-02"
    verification:
      - kind: unit
        ref: "test/threadline/version_truth_doc_contract_test.exs#no install pin line is also owned by a release-please version marker"
        status: pass
      - kind: other
        ref: "negative control — marker appended to README.md:68 reproduced the failure naming README.md:68; probe reverted"
        status: pass
    human_judgment: false
  - id: D4
    description: "The built Hex archive contains no critic Mix tasks, no critic-trust modules, no operator-surface stress or mechanical harness, and no release-pins task."
    verification:
      - kind: integration
        ref: "test/threadline/release_artifact_contract_test.exs#built Hex archive excludes maintainer-only tooling"
        status: pass
      - kind: integration
        ref: "test/threadline/release_artifact_contract_test.exs#the bot-owned generated changelog is never adopter surface"
        status: pass
      - kind: other
        ref: "mix hex.build --unpack — 132 entries, zero matching critic|stress|mechanical|release.pins, lib/threadline.ex and mix.exs present"
        status: pass
      - kind: other
        ref: "negative control — removing exclude_patterns: made the archive test fail naming lib/mix/tasks/critic.measure.ex; key restored"
        status: pass
      - kind: other
        ref: "mix compile --warnings-as-errors clean — no runtime module depends on an excluded path"
        status: pass
    human_judgment: false
  - id: D5
    description: "Every remaining version-bearing line outside the pin regex is classified in writing as illustrative or as a current-version claim with a named owner."
    verification: []
    human_judgment: true
    rationale: "Backstop-marked in the plan: no test can prove a prose sentence is illustrative. The table in CONTRIBUTING.md is a recorded judgement and a maintainer should confirm the dispositions, particularly the one line moved into the human-owned bucket (guides/upgrade-path.md opening era narrative)."
  - id: D6
    description: "The one-way narrowing of the published tarball was confirmed before any packaging change."
    verification: []
    human_judgment: true
    rationale: "Task 3 was a checkpoint:decision carrying no `gate` attribute, so it defaulted to gate=\"blocking\" and auto-selected under mode: yolo + workflow.auto_advance: true. No fresh live human confirmation was obtained — see 'Checkpoint handling' below. A maintainer should confirm the exclusion set before publish, because a shipped file cannot be withdrawn from a published version."

duration: 12min
completed: 2026-09-22
status: complete
---

# Phase 202 Plan 02: Automated install pins and a tarball free of maintainer tooling Summary

**`mix release.pins` derives all six documented install pins from `mix.exs` `@version` (no-op at a patch bump, idempotent, write-free `--check` gate), release automation is now test-forbidden from ever owning a pin line, and 11 maintainer-only files totalling 4,706 lines are excluded from the published archive — proven against the unpacked tarball, not the config that produced it.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-09-22T14:01:42Z
- **Completed:** 2026-09-22T14:13:40Z
- **Tasks:** 4 (one was a decision checkpoint and produced no commit)
- **Files modified:** 5 (1 created, 4 modified)

## Accomplishments

- **The born-red pin problem is closed by construction.** Under a simulated `0.10.0` `@version`, Family A of the version-truth contract failed on all six pins; one `mix release.pins` run turned it green and touched nothing else. Under a simulated `0.9.1` it reported zero rewrites — a patch release stays genuinely zero-edit because the `major.minor.0` floor is patch-invariant.
- **The "release-please must never own a pin line" rule left the comment and became a test.** It fails with a message that explains the mechanism (full-version write on a marked line; leading-digit replacement inside the compound requirement string) and names `mix release.pins` as the owner.
- **The published tarball stopped carrying maintainer instruments.** The two `@shortdoc`-bearing critic tasks would otherwise have appeared in every adopter's `mix help` under a namespace that is not this library's. The archive is now 132 entries with zero matches for the excluded prefixes.
- **The remaining version literals are classified rather than assumed.** Eight hits outside the six pins and two marker lines are each assigned an owner and a disposition in `CONTRIBUTING.md`.

## Task Commits

1. **Task 1: `mix release.pins`** — `f50c4eaa` (feat)
2. **Task 2: pin/marker separation test + ownership classification** — `43c64458` (test)
3. **Task 3: decision checkpoint** — no commit (see "Checkpoint handling")
4. **Task 4 (correction to Task 1's artifact): `@moduledoc false` on the pin rewriter** — `feef183f` (fix)
5. **Task 4: `exclude_patterns` + archive refutations** — `1addff8a` (feat)

`actuals.commits: 4` is measured with `git rev-list --count 8bcbe008..HEAD` **immediately before the SUMMARY commit**. A later re-measure from the same base will read higher by exactly the SUMMARY commit plus the STATE/ROADMAP metadata commit that follows it; that offset is the instrument's, not a discrepancy in the count.

## Files Created/Modified

- `lib/mix/tasks/release.pins.ex` (new, 131 lines) — `Mix.Tasks.Release.Pins`. No `@shortdoc`, `@moduledoc false`. `--check` parsed with `OptionParser`, raising via `Mix.raise/1`. Rewrites only the captured version segment inside a matched pin via `Regex.replace/3` with a callback; writes with `File.write!/2`.
- `test/threadline/version_truth_doc_contract_test.exs` — pin regex hoisted to `@pin_regex` (shared by Family A and the new family, so the two can no longer drift); new Family B-inverse test; moduledoc updated from three families to four.
- `test/threadline/release_artifact_contract_test.exs` — `@maintainer_only_paths` (11 enumerated paths) and `@maintainer_only_prefixes` (2 pattern sweeps); two new archive tests; `source_vocab_operator_stress` owner group removed and `mechanical_checker.ex` dropped from `source_vocab_operator_infrastructure`.
- `mix.exs` — `package/0` gains `exclude_patterns:` with seven regexes.
- `CONTRIBUTING.md` — new `### Version-bearing lines and who owns them` subsection under Hex publish (maintainers): the ownership table, a minor-bump release checklist item, and the enforced-invariants paragraph.

## Observed outputs recorded verbatim

**Simulated minor bump (`@version` temporarily `0.10.0`), `mix release.pins`:**

```
release.pins: mix.exs @version is 0.10.0, derived install pin is `~> 0.10.0`
  README.md: `~> 0.9.0` -> `~> 0.10.0`
  guides/adoption-evidence-playbook.md: `~> 0.9.0` -> `~> 0.10.0`
  guides/adoption-pilot-backlog.md: `~> 0.9.0` -> `~> 0.10.0`
  guides/evaluating-threadline.md: `~> 0.9.0` -> `~> 0.10.0`
  guides/getting-started-saas.md: `~> 0.9.0` -> `~> 0.10.0`
  guides/operator-surface.md: `~> 0.9.0` -> `~> 0.10.0`
release.pins: scanned 20 file(s); 6 pin site(s) differ from the derived pin
release.pins: rewrote 6 file(s).
```

`git status --porcelain -- README.md guides` after that run listed exactly those six files, so the other 14 scanned files — the pin-free case — were left byte-identical. `git diff -- guides/adoption-pilot-backlog.md` showed a single changed line, the `App depends on {:threadline, "~> …"}` row; the marker-bearing SSOT sentence (line 7) and the Hex attestation row (line 13) were untouched. The three externally-owned lines were confirmed outside the pin regex **by inspection of the diff**, not assumed.

**Simulated patch bump (`@version` temporarily `0.9.1`):**

```
release.pins: mix.exs @version is 0.9.1, derived install pin is `~> 0.9.0`
release.pins: scanned 20 file(s); 0 pin site(s) differ from the derived pin
release.pins: no changes — every install pin already reads the
release.pins: derived `~> 0.9.0`.
```

`git diff --exit-code` exited 0 afterwards. `--check` under the same version also exited 0.

**`--check` under the simulated minor bump** exited **1** with `** (Mix) mix release.pins --check: 6 install pin(s) do not match the derived ~> 0.10.0` and `git diff --exit-code` still exited 0 afterwards — it wrote nothing.

**Idempotence:** a second consecutive run reported `0 pin site(s) differ`, and `md5` over `README.md` + `guides/*.md` was identical across two runs.

**Task 2 negative control** (marker appended to the README pin line, then reverted):

```
README.md:68 carries BOTH an install pin and an x-release-please-version marker, so release
automation would own a pin line. That cannot work: the generic updater writes the FULL version
onto a marked line, emitting `~> x.y.1` on a patch release while this contract derives
`~> x.y.0`; and the component updater replaces the first bare integer on the line, which inside
`{:threadline, "~> 0.9.0"}` is the leading `0` of the requirement string, producing a nonsense
major. Install pins are owned by `mix release.pins` and by nothing else — remove the marker, and
never register a pin-bearing file under `extra-files` in release-please-config.json.

    {:threadline, "~> 0.9.0"} <!-- x-release-please-version -->
```

**Task 4 negative control** (`exclude_patterns:` temporarily removed, then restored):

```
lib/mix/tasks/critic.measure.ex is maintainer-only tooling and was published in the Hex archive.
Two of the critic tasks carry a `@shortdoc`, so shipping them puts maintainer instruments in
every adopter's `mix help` under a namespace that is not this library's — and nothing in a
published version can be withdrawn from it. Add the path to `exclude_patterns` in mix.exs
`package/0`.
```

`@version` and all doc files were restored to their committed state before each commit; `git diff --exit-code -- mix.exs README.md guides` exited 0 at every restore point.

## Exclusion enumeration (measured, not quoted)

Taken from `git ls-files 'lib/**'`, filtered for the critic tasks, the critic-trust directory, and the operator-surface stress/mechanical files, plus the new pins task. This list — not the "roughly five thousand lines" figure in CONTEXT.md nor the "roughly three and a half thousand" in RESEARCH.md — is what the contract is written against:

| Path | Lines |
|---|---:|
| `lib/mix/tasks/critic.measure.ex` | 463 |
| `lib/mix/tasks/critic.synth.ex` | 192 |
| `lib/threadline/critic_trust/krippendorff_alpha.ex` | 177 |
| `lib/threadline/critic_trust/ledger_splice.ex` | 121 |
| `lib/threadline/critic_trust/measure.ex` | 171 |
| `lib/threadline/critic_trust/rank_metrics.ex` | 70 |
| `lib/threadline/operator_surface/live/stress_live.ex` | 1394 |
| `lib/threadline/operator_surface/mechanical_checker.ex` | 952 |
| `lib/threadline/operator_surface/stress_fixtures.ex` | 980 |
| `lib/threadline/operator_surface/stress_router.ex` | 53 |
| `lib/mix/tasks/release.pins.ex` | 133 |
| **Total** | **4706** |

(The `release.pins.ex` count is its pre-`@moduledoc false` length, which is what was measured and presented at the decision point; it is 131 lines as committed.)

`@shortdoc`-bearing members of that set: `critic.measure.ex` and `critic.synth.ex` — the two that would have surfaced in an adopter's `mix help`, which is the whole rationale.

**No module outside the maintainer harness references any excluded module.** Verified with `grep -rlE 'StressRouter|StressFixtures|StressLive|MechanicalChecker|CriticTrust|Mix\.Tasks\.Critic' lib/` filtered to files outside the harness — empty. `mix compile --warnings-as-errors` is clean, and the unpacked archive keeps `lib/threadline.ex` and `mix.exs`.

**Unpacked archive after the change:** 132 entries; `grep -E 'critic|stress|mechanical|release.pins'` over the entry list returned nothing.

## Version-bearing line classification (Task 2)

Eight hits for the current version string across `README.md`, `guides/**`, and `CONTRIBUTING.md` outside the six pins and two marker lines. Full table with owners is in `CONTRIBUTING.md`; the dispositions are:

- **current-version claim, automation-owned:** the Hex attestation row (`bin/post-publish-distribution-sync`).
- **current-version claim, human-owned (the one hit that had no owner):** `guides/upgrade-path.md:5`, the opening era narrative whose minor range ends at the latest released minor. It was given an owner rather than silently absorbed: a release-checklist item in `CONTRIBUTING.md` requires extending it with that minor's upgrade row, and Family C of the version-truth contract already fails the build until the new minor's coverage exists, so the step cannot be skipped unnoticed. It is human-owned because writing an upgrade row is *authoring content* — what changed and what an adopter must do — not a mechanical version substitution.
- **illustrative (stay correct after a bump):** `guides/upgrade-path.md` lines 68, 90, 91, 107 and `CONTRIBUTING.md` line 618 — backport-policy examples and append-only historical era rows.

The subsection states explicitly that RELEASE-02 means no line requires a HAND edit, and that an illustrative example is not such a line.

## Decisions Made

- **Runtime `@version` read, not a module attribute.** `mix release.pins` calls `Threadline.MixProject.project()[:version]` inside the run so a bumped `mix.exs` can never be shadowed by a stale `.beam`.
- **The pin regex was hoisted into `@pin_regex` in the contract test.** The plan required reusing the module's existing regex rather than redefining it; it lived as a local variable inside Family A, so hoisting was the only way to genuinely share it. The literal is character-identical to the one in `mix release.pins`.
- **`files:` was not restructured.** It keeps its pattern allowlist; only a trailing comma was added as the syntactic consequence of appending a sibling key. The allowlist's contents are unchanged — stated precisely because the plan's acceptance criterion said "no edit to the `files:` line", and a comma is an edit to that line even though it is not an edit to the allowlist.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] The pin rewriter's rendered `@moduledoc` broke the public-surface contract**

- **Found during:** Task 4 (full `mix test test/threadline/` run)
- **Issue:** The plan instructed a `@moduledoc` stating the task is maintainer-only. A visible moduledoc makes the module part of the documented public surface, and `public_surface_contract_test.exs` failed twice: *"every visible compiled module belongs to exactly one of six groups"* (the task belonged to none), and *"all local, external, and module-doc subjects have one exact owner"* (`Mix.Tasks.Release.Pins contains unknown public references: modules: [Threadline.VersionTruthDocContractTest]` — a module doc may not cite a test module).
- **Fix:** Converted to `@moduledoc false`, matching the convention the critic tasks and stress harness already use, and preserved the entire rationale verbatim as module comments. The plan's *intent* — a written record of why the task is maintainer-only, why no `@shortdoc`, why the floor stops at the minor, why release automation cannot own a pin line — is fully retained; only its visibility changed, which is exactly consistent with keeping maintainer tooling off adopter surface.
- **Files modified:** `lib/mix/tasks/release.pins.ex`
- **Verification:** `mix test test/threadline/public_surface_contract_test.exs` — 36 tests, 0 failures.
- **Committed in:** `feef183f`

**2. [Rule 3 - Blocking] Two archive source-vocabulary owner groups asserted the presence of files the exclusion removes**

- **Found during:** Task 4 (writing the exclusion)
- **Issue:** `release_artifact_contract_test.exs`'s `@source_owners` map asserted `Map.keys(selected) == expected` for `source_vocab_operator_stress` (`stress_fixtures.ex`, `stress_live.ex`) and `source_vocab_operator_infrastructure` (`logo.ex`, `mechanical_checker.ex`). Excluding those files from the archive makes the assertion unsatisfiable, and the group also asserts `expected != []`, so emptying the stress group would fail too.
- **Fix:** Removed the `source_vocab_operator_stress` group entirely and dropped `mechanical_checker.ex` from `source_vocab_operator_infrastructure` (which keeps `logo.ex` and stays non-empty), with a comment recording why. **The contract was not weakened:** those owners existed to prove packaged source carries durable vocabulary, and the files are no longer packaged — their vocabulary can no longer reach an adopter. The new refutations assert their absence instead, which is a strictly stronger claim.
- **Files modified:** `test/threadline/release_artifact_contract_test.exs`
- **Verification:** `mix test test/threadline/release_artifact_contract_test.exs` — 19 tests, 0 failures (was 18: +2 new, −1 removed group).
- **Committed in:** `1addff8a`

---

**Total deviations:** 2 auto-fixed (2 blocking).
**Impact on plan:** Both were required to make the repository's own existing contracts pass alongside the plan's new ones. No scope creep — both are confined to files the plan already lists.

## Checkpoint handling

**Task 3 (`checkpoint:decision`, rated one-way) was auto-selected, not human-confirmed.**

The task carried no `gate` attribute, so it defaulted to `gate="blocking"`, and `.planning/config.json` has `mode: yolo` with `workflow.auto_advance: true`. Under the checkpoint protocol that means auto-select the first option, which was *"Proceed with the exclusion set as enumerated from the tree."*

The plan's own acceptance criteria were: *"The enumerated exclusion list, taken from `git ls-files`, is presented to the maintainer before any packaging change"* and *"The maintainer's confirmation and its timestamp are recorded in the SUMMARY."*

Stating this plainly: **the enumeration was produced and recorded at `2026-09-22T14:06:33Z`, before any edit to `mix.exs`** (the enumeration table above is that output), **but no live maintainer confirmation was obtained.** What exists instead is the prior recorded decision D-20 in `202-CONTEXT.md`, dated 2026-09-22, reached with the maintainer during `/gsd-discuss-phase` and rated one-way there. The timestamp above is the auto-selection's, not a human's.

This is the second one-way decision in this phase to auto-select (Plan 01's storage-schema flip was the first). Given a shipped file cannot be withdrawn from a published version, **a maintainer should confirm the exclusion set before publish.** If the planner intended this to stop even in auto-mode, the task needed `gate="blocking-human"`.

## Issues Encountered

- **`guides/evaluating-threadline.md:41` and `guides/adoption-evidence-playbook.md:15` now carry a stale claim** — both say `mix verify.hex_evaluator` depends on threadline *"from hex.pm — not a path dep"*. Plan 01 changed that: the default mode resolves from a local rehearsal registry built from this tree's own tarball. The install pin on those lines is correct and this plan rewrites it; the surrounding prose is not this plan's file and not a version-bearing line, so it was **not** edited here. Logged to `deferred-items.md` for Plan 03, which owns the documentation pass.
- **The intermittent `Threadline.OperatorSurface.CriticTrustTest`** noted in Plan 01 did not reproduce in either full-suite run during this plan (1669 tests, 0 failures on the final run). It remains open in `deferred-items.md`; two clean runs are not a refutation.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

**Ready for 202-03.** Concretely provided:

- Plan 03 can add the `0.9.x → 0.10.x` upgrade row knowing Family A will already be green at the bumped version once `mix release.pins` runs; the only remaining doc-contract families that go red on a simulated bump are B (release-please's own prose, bumped by the release commit) and C (the upgrade coverage Plan 03 writes).
- The generated-changelog refutation is already committed, so `CHANGELOG-GENERATED.md` can never become adopter surface — the guard exists before the file does.
- Plan 04 can wire `mix release.pins --check` into a release gate: it writes nothing and exits non-zero on drift.

**Concerns carried forward:**

1. The one-way tarball narrowing has no live maintainer confirmation (see "Checkpoint handling"). Re-confirm before publish.
2. `guides/evaluating-threadline.md:41` and `guides/adoption-evidence-playbook.md:15` carry a stale hex-evaluator claim for Plan 03.
3. The `CriticTrustTest` flake remains unresolved and unreproduced.

---
*Phase: 202-release-0-10-0*
*Completed: 2026-09-22*

## Self-Check: PASSED

- Created file verified present on disk: `lib/mix/tasks/release.pins.ex`.
- Commits verified in `git log`: `f50c4eaa`, `43c64458`, `feef183f`, `1addff8a`.
- Plan `<verification>` block re-run green at the committed tree: `mix verify.doc_contract` (134 tests, 0 failures — was 133 before this plan), `mix test test/threadline/version_truth_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs` (23 tests, 0 failures — was 21), `mix hex.build` succeeded and the unpacked archive omits every enumerated maintainer path while keeping `lib/threadline.ex` and `mix.exs`, `mix compile --warnings-as-errors` clean, `mix verify.format` and `mix verify.credo` clean, full `mix test test/threadline/` at 1669 tests / 0 failures.
