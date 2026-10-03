# Phase 230: Rebalance, Net-Suite Check and 0.12.0 - Context

**Gathered:** 2026-10-02
**Status:** Ready for planning

<domain>
## Phase Boundary

The last phase of v1.44. It delivers three things, in this order:

1. **Rebalance (SUITE-04).** Apply the locked B.1 keep/cut rubric to the
   guard/contract tests, including the four files not yet audited. Cut the
   assertions that only compare prose to a hand-typed literal. Record the rubric
   so future guard tests are judged against it.
2. **Net-suite check (SUITE-06).** Build the milestone suite-time table from
   every phase's published before/after figures plus one fresh CI run. Show that
   net suite time does not regress against SUITE-01, locally and in CI, with
   run IDs.
3. **Land and release (REL-01).** One squash to main, release-please ships
   0.12.0, hex.pm serves it, and the `latest` lane pins are re-checked against
   builds.hex.pm and Docker Hub.

The phase closes with `mix ci.all` and `bin/verify-repo-hygiene` green, and no
phase or plan ID in `lib/`, guides or the 0.12.0 CHANGELOG. Milestone
audit and close (`/gsd-audit-milestone`, `/gsd-complete-milestone`) run
**after** this phase, not inside it.

</domain>

<decisions>
## Implementation Decisions

### Guard-test disposition (SUITE-04)

- **D-01: Policy is a line-item split by rubric.** Keep every assertion that
  derives from a live source (code, generated output, a real Mix task run,
  `git ls-files`) or asserts a structural or security invariant. Remove only
  the prose-to-prose and prose-to-hand-typed-literal assertions. A file is cut
  whole only when **all** of its assertions are condemned. Do **not** relocate
  cut assertions into another file. "Merge" would just move the same
  anti-pattern, so a cut assertion is deleted, not folded.
- **D-02: Per-file verdicts** (planner re-confirms line ranges against the
  live files before editing):

  | File | Verdict |
  |---|---|
  | `test/threadline/stg_doc_contract_test.exs` | **Cut whole file.** All 6 tests are CONTRIBUTING/guide prose cross-references. Do not merge into `adoption_pilot_doc_contract_test.exs`, whose moduledoc owns a different (Pins-derived) contract. |
  | `test/threadline/operator_surface/theme_doc_contract_test.exs` | **Cut whole file.** Its moduledoc self-declares pure `File.read!` + `String.contains?` against guide prose. |
  | `test/threadline/operator_surface_doc_contract_test.exs` | **Line-item split.** Keep the `Pins.target_pin_version()`-derived upgrade-path assertion (trim its prose siblings). Cut the bare README/guide literal tests: route literals, "owns procedures / routes exhaustive configuration", "leads with production mount" ordering, and the other prose-only callback/Storybook/mounted-parity checks. Exception: keep any assertion that pins an **auth / fail-closed / export-auth security boundary** sentence. Losing that silently is a security-docs regression, which is rubric KEEP #2 in spirit. Record each kept exception with a one-line reason. |
  | `test/threadline/operator_surface/coverage_doc_contract_test.exs` | **Line-item split, mostly KEEP.** Keep: router/on_mount ordering, `*.ex` source literals, the real `--json` run + `Jason.decode!` schema checks, the `@expected_uncovered_baseline` guard, the atom-leak and SQL-injection refutes, and the `Code.ensure_loaded?(Phoenix.LiveView)` gate checks. Cut the doc-to-doc blocks: the selected-schema readiness guide prose, the storage-schema happy-path guide prose, the checklist audit-readiness language, the S1/S2 same-sentence-in-4-guides identity checks, and the `--all-schemas` in-two-guides check. |
  | `test/threadline/operator_surface/policy_show_doc_contract_test.exs` | **Line-item split, cut one test.** Cut only the "domain reference documents policy.show --schema as host schema" test, which reads only `guides/domain-reference.md`. Keep the cross-file label/order parity between the LiveView, the Mix task and the presenter, the runtime `Show.run(["--json"])` test, and the no-secret-leak refutes. |
  | `test/threadline/storage_schema_migration_contract_test.exs` | **KEEP whole.** It calls the real `migration_content()` functions, with SHA-256 pins on generated SQL, `ArgumentError` raises and parse checks. |
  | `test/threadline/storage_schema_prefix_contract_test.exs` | **KEEP whole.** It has `__schema__` introspection, a live source scan against `@schema_prefix "threadline"` reintroduction, and the runtime unprefixed-`Repo.all` mask contract that retired the 79-test defect class. |

- **D-03: A cut prose lock gets no replacement.** Ordinary doc review on the
  PR that touches the guide catches a reworded sentence. Do not add a blanket
  `mix docs` scope or a new derived test as a substitute. If cutting the route
  literals exposes that no integration test exercises the operator routes,
  record that as a deferred gap. Do not build one here.
- **D-04: Record the rubric in CONTRIBUTING.md** as a short section, "Writing a
  doc-contract or guard test". It states KEEP criteria 1-3 and the CUT shape
  in plain prose. It adds one convention: every new `*_contract_test.exs`
  moduledoc names, in one sentence, which KEEP criterion it satisfies. No new
  tooling. If a CONTRIBUTING contract test pins section lists, update it in the
  same change, and never cut it.
- **D-05: Guardrails, checked in the same plan.**
  - `bin/verify-bump-rehearsal` has a hard floor of 30 doc-contract files
    (`*doc_contract_test.exs`/`*readme_contract_test.exs`). The current count
    is 37, and the two whole-file cuts take it to 35. Assert the count after
    the cuts, and do not lower the floor.
  - Cross-check every touched file against
    `.planning/milestones/v1.43-MILESTONE-AUDIT.md`. Any assertion carrying a
    v1.43 mutation control is kept.
  - A diff of `ci-required` shows an unchanged required-check count.
  - Remove the deleted files' lines from `test/partition_weights.txt` if
    present, so the partitioner does not carry dead weights.
  - Report the rebalance's own suite wall clock before and after.

### Net-suite comparison basis (SUITE-06)

- **D-06: The gate is CI test-step wall clock.** This is what contributors
  wait for, and what SUITE-01/SUITE-02 used as the comparator. Take one fresh
  `ci.yml` run on the final pre-landing tree where every lane reports
  `Build cache: hit`. A cache-state mismatch invalidates the comparison.
  Measure it with
  `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py <run> --cache-state`.
  **Pass:** the summed per-lane `Run tests` step seconds are ≤ SUITE-01's
  846 s (run 36730596489) + 10%, and the per-lane max is ≤ SUITE-01's per-lane
  figure.
- **D-07: Disclose serial-equivalent work honestly, but do not gate on it.**
  `bin/ci-test-partitions` runs partitions concurrently **inside** each lane
  job, so a step's wall clock hides added test work. The table must also
  report serial-equivalent test work against SUITE-01's serial figure, with
  per-phase attribution:
  - Prefer the sum of each partition's ExUnit `Finished in` time. If the
    partition logs on a green run don't expose it, the planner may add a
    one-line per-partition duration echo to the runner.
  - Use the local `mix test` serial median as a fallback or as context.

  Property-test growth from 226/227 was a deliberate milestone goal. If work
  grew, say so with numbers and attribution. Never re-baseline, never call it
  noise, and never fail the release over it.
- **D-08: Local figures are context, not the comparator.** Report the median of
  3 sequential local `mix test` runs at the final commit against SUITE-01's
  local 137.0 s median. Reuse the repo's standard noise-floor caveat (the
  ≈52-56 s documented local swing; see 224/227/228 evidence).
  `mix verify.test_partitioned`'s partition table is a balance sanity check
  only.
- **D-09: Milestone suite-time table shape.** Columns: `Phase | Local before
  (median s) | Local after (median s) | CI before (step sum s / proxy min) |
  CI after (step sum s / proxy min) | Δ CI % | Serial-equivalent work Δ | Run
  ID(s) | Source doc`. One row per phase 224-230, pulled from each phase's
  published evidence. Phases with local-only figures are marked as such, not
  back-filled. A final SUITE-06 row carries the D-06 verdict. The numbers and
  citations live in `230-EVIDENCE.md`, and the pass/fail statement in
  `230-VERIFICATION.md`.
- **D-10: If D-06 fails,** do not land. Diagnose (cache state, then real test
  content, then partition weights). Rebalance weights or trim before release,
  and re-measure. `THREADLINE_PROPERTY_SCALE` is Flake-Detection-only, so a CI
  regression is real content.

### Release title and breaking signal (REL-01)

- **D-11: Use `feat!:` with one `BREAKING CHANGE:` footer per break.** REL-01's
  "clean conventional `feat:` title" is satisfied in spirit: type `feat` with
  the `!` breaking marker, matching the 0.11.0 precedent `b0668e6d` (#52).
  - `bump-minor-pre-major: true` yields 0.12.0 either way, so only the signal
    differs.
  - A plain `feat:` would ship three real breaks with no `⚠ BREAKING CHANGES`
    on GitHub releases or in `CHANGELOG-GENERATED.md`.
  - A footer-less `feat!:` would surface only one of the three.

  — **Reversibility:** one-way — the squash commit message on main is
  permanent and release-please renders it into the published 0.12.0 release
  notes.
- **D-12: The subject leads with what adopters gain.** The breaks live in the
  footers, so the subject should not be a list of removals. Proposed:
  `feat!: add export and retention telemetry, a history limit, and strict coverage checks`
  (the planner may tighten it). The body skeleton is a one-paragraph user-facing
  summary followed by three `BREAKING CHANGE:` lines:
  1. Operator-surface authorize/export/actor_ref_mismatch telemetry no longer
     carries actor refs.
  2. The `[:threadline, :health, :checked, :error]` metadata is now
     `%{exception: module}`.
  3. A non-list `exclude:`/`mask:`/`except_columns:` raises `ArgumentError`.

  Close with "See CHANGELOG.md for upgrade steps." No phase, plan, decision or
  `WR-` IDs anywhere (SC5; `release_artifact_contract_test.exs`
  `@banned_shapes`).
- **D-13: No separate `guides/upgrading-to-0.12.md`.** Each hand-written
  `### Breaking changes` entry in `CHANGELOG.md` already carries a concrete
  "Fix:" line, and none needs a data backfill, unlike 0.11. Before landing,
  confirm each entry has a Fix line and that `changelog_contract_test.exs` is
  green.

### Close vs land ordering

- **D-14: Land and release inside phase 230. Audit and close after.**
  - SC4 makes the release evidence part of 230's own verification, so
    `/gsd-audit-milestone` and `/gsd-complete-milestone` run after phase 230
    and cite the live hex.pm page and the pin re-check. This follows the v1.43
    phase-223 precedent.
  - The milestone tag stays local.
- **D-15: Squash `milestone/v1.44` directly. No `land/*` cherry-pick branch.**
  - The branch's merge base is `origin/main` `fc47af60`. A three-dot diff shows
    224/225 content is already on main.
  - The PR diff is therefore exactly phases 226-230, plus the scrubbed
    `.planning/` tree, which is published on main by design.
  - Before opening the PR, re-check `git merge-base` == `origin/main`. If main
    has moved, rebase or merge main first.
  - Never `git add .planning/` wholesale.
- **D-16: Plan shape.**
  1. Rebalance plan(s) (D-01..D-05).
  2. Net-suite measurement and table (D-06..D-10).
  3. Pre-land gate: `mix ci.all`, `bin/verify-repo-hygiene`, an SC5 ID scan of
     `lib/`, `guides/` and CHANGELOG, a `whoami`/home-path grep of tracked
     `.planning/`, and D-13's check.
  4. One final **release plan**: PR, CI green, squash merge, release-please PR
     merge, `production-hex` approval, hex.pm smoke check, `latest`-lane pin
     re-check against builds.hex.pm and Docker Hub with the result cited, and
     the post-release "sync distribution docs" chore PR if release-please
     leaves one (#69 pattern).

  The release plan's verification rows are separate, so a stalled or failed
  release leaves the SC1-3 proof intact and only the SC4 rows pending.
- **D-17: One maintainer grant, requested up front at the release plan's
  checkpoint.**
  - A bare "go" is denied by the classifier. The grant must name every action
    in the user's own words: push `milestone/v1.44`, open its PR to main,
    squash-merge it once CI is green, merge the release-please PR for 0.12.0,
    approve the `production-hex` deployment, and open and merge the
    distribution-docs sync PR.
  - Never `--no-verify`.
  - This is the only human touch in the phase; everything else is automated.

### Claude's Discretion
- Exact squash subject wording within D-12's shape and length.
- Whether rubric text in CONTRIBUTING.md is a new section or a subsection of an
  existing testing section.
- Mechanism for exposing per-partition durations (D-07), if one is needed.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Rubric and cut list
- `.planning/research/ARCHITECTURE.md` §B.1–B.2: the LOCKED keep/cut rubric and the initial findings table
- `.planning/milestones/v1.43-MILESTONE-AUDIT.md`: cross-check for v1.43 mutation controls before cutting anything
- `bin/verify-bump-rehearsal` (lines ~430-440): 30-file doc-contract floor
- `CONTRIBUTING.md`: target for the recorded rubric, and contract-pinned sections
- `test/threadline/ci_topology_contract_test.exs`: never cut, and it constrains CONTRIBUTING edits

### Suite timing
- `.planning/phases/225-suite-baseline-and-partitioned-ci/225-BASELINE.md`: SUITE-01 figures (846 s step sum, run 36730596489, local 137.0 s median)
- `.planning/phases/225-suite-baseline-and-partitioned-ci/225-EVIDENCE.md`: partitioned after-runs
- `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py`: the comparator tool
- `.planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md`: local noise-floor caveat (D-18)
- `.planning/phases/226-pure-property-tests-and-run-budget/226-EVIDENCE.md`, `.planning/phases/227-db-backed-property-tests/evidence/SC5-local.md`, `.planning/phases/228-telemetry/evidence/SC5-local.md`, `.planning/phases/229-adopter-api-and-health-additions/evidence/SC5-wallclock.md`: per-phase before/after
- `bin/ci-test-partitions`, `test/partition_weights.txt`: partition runner and weights

### Release
- `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release.yml`
- `CHANGELOG.md` (hand-written top section, including `### Breaking changes`), `CHANGELOG-GENERATED.md`
- `test/threadline/changelog_contract_test.exs`, `test/threadline/release_artifact_contract_test.exs` (`@banned_shapes`)
- `.planning/milestones/v1.43-ROADMAP.md` (phase 223 publish/production-hex/smoke/distribution-sync plan): release-plan precedent
- `.planning/MILESTONE-GUIDE.txt`: quality/CI/release bar

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ci-job-timing.py --cache-state` / `--compare`: per-lane step seconds, billed-minutes proxy and cache-state check. Reuse it; do not write a new timer.
- `mix verify.test_partitioned` → `bin/ci-test-partitions`: the same script CI runs, so local and CI partition behavior match.
- `Mix.Tasks.Release.Pins`: the live pin source already used by KEEP tests.

### Established Patterns
- Every phase 224-229 reports CI as the comparator and local triples as noisy context. Keep that framing verbatim.
- Breaking releases use `feat!:` (0.11.0, #52). release-please renders the subject or footers under `⚠ BREAKING CHANGES`.
- Landings squash with a conventional title. Follow-up release-please and distribution-sync PRs are separate (#50/#51, #69).

### Integration Points
- Deleted test files must leave `test/partition_weights.txt` and any hand-listed aliases consistent. `ci_all_dedup_contract_test.exs` derives from the alias tree.
- `bin/verify-repo-hygiene` scans tracked `.planning/` prose. Phase-230 evidence must use placeholder path shapes, not home paths or the username.

</code_context>

<specifics>
## Specific Ideas

- The milestone's theme is "a more honest suite". The net-suite table must not let in-job partition parallelism hide added test work (D-07), even though the gate itself is wall clock.
- Release notes should match the severity of the hand-written Breaking changes section, not under-report it (D-11).

</specifics>

<deferred>
## Deferred Ideas

- An integration test exercising the operator-surface routes end-to-end, if cutting the route-literal prose check reveals none exists (future phase, not SUITE-04).
- Lint or CI enforcement of the D-04 moduledoc convention (names a KEEP criterion). Convention only for now.

</deferred>

---

*Phase: 230-rebalance-net-suite-check-and-0-12-0*
*Context gathered: 2026-10-02*
