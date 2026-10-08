---
phase: 237-upgrade-guide-and-1-0-0
verified: 2026-10-08T00:53:59Z
status: passed
score: 21/21 must-haves verified
covered_files: [".github/workflows/ci.yml", ".github/workflows/release.yml", ".planning/MILESTONE-ARC.md", ".planning/phases/237-upgrade-guide-and-1-0-0/237-01-PLAN.md", ".planning/phases/237-upgrade-guide-and-1-0-0/237-01-SUMMARY.md", ".planning/phases/237-upgrade-guide-and-1-0-0/237-02-PLAN.md", ".planning/phases/237-upgrade-guide-and-1-0-0/237-02-SUMMARY.md", ".planning/phases/237-upgrade-guide-and-1-0-0/237-03-PLAN.md", ".planning/phases/237-upgrade-guide-and-1-0-0/237-03-SUMMARY.md", ".planning/phases/237-upgrade-guide-and-1-0-0/237-04-PLAN.md", ".planning/phases/237-upgrade-guide-and-1-0-0/237-04-SUMMARY.md", ".planning/phases/237-upgrade-guide-and-1-0-0/237-05-PLAN.md", ".planning/phases/237-upgrade-guide-and-1-0-0/237-05-SUMMARY.md", ".planning/phases/237-upgrade-guide-and-1-0-0/237-REVIEW.md", ".planning/phases/237-upgrade-guide-and-1-0-0/237-SECURITY.md", ".planning/phases/237-upgrade-guide-and-1-0-0/237-VALIDATION.md", "CHANGELOG.md", "bin/verify-bump-rehearsal", "guides/upgrade-path.md", "guides/upgrading-to-1.0.md", "mix.exs", "release-please-config.json", "test/partition_weights.txt", "test/threadline/changelog_contract_test.exs", "test/threadline/ci_topology_contract_test.exs", "test/threadline/guide_graph_contract_test.exs", "test/threadline/upgrading_to_1_0_doc_contract_test.exs"]
covered_digest: "v3:sha256:8bbe64c27d3f822848e44bbdde0d1b30f98a2ba71746502d0d940b9f63e30d8f"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 5
  total: 5
  not_honored: []
---

# Phase 237: Upgrade Guide and 1.0.0 Verification Report

**Phase Goal:** A 0.11 or 0.12 adopter can follow one guide through every breaking change to 1.0. The 1.0.0 CHANGELOG is complete, and hex.pm serves threadline 1.0.0, cut by release-please from one `feat!:` squash.
**Verified:** 2026-10-08T00:53:59Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Roadmap success criterion | Status | Evidence |
|---|---|---|---|
| 1 | The guide gives 0.11/0.12 adopters the seven required 1.0 migration steps, follows the existing guide pattern, states trigger requirements, and has a tested/weighted change-map contract. | ✓ VERIFIED | [Guide](../../../guides/upgrading-to-1.0.md), conditional 0.11.x preflight, ordered steps, graph/extras registration, and explicit partition weight are present. The 50 focused contract tests and ExDoc build passed per VALIDATION.md. |
| 2 | The human-owned 1.0.0 changelog covers every breaking change and deprecation in the milestone and records the exact history cross-check. | ✓ VERIFIED | [CHANGELOG.md](../../../CHANGELOG.md) has 12 1.0 breaking entries and eight deprecations. The recorded `v1.44` (`4ae4557…`) through source tip `6227ad9…` audit found 11 matching commits / 12 consequences and maps each to a guide ID; three 0.12 prerequisites stay separate. |
| 3 | Release Please configuration and candidate rehearsal select 1.0.0, not 0.13.0, and the landing squash carries the required footer. | ✓ VERIFIED | `release-please-config.json` sets `bump-minor-pre-major` to JSON `false`; candidate mode validates `feat!`, exactly one `Release-As: 1.0.0` trailer, and the resulting 1.0.0 target. The candidate rehearsal passed. GitHub reports the landed `feat!: land Threadline 1.0 API contract` squash with one exact footer. |
| 4 | The granted squash lands with green required CI including min PostgreSQL 15/latest pins, and the separately granted release publishes 1.0.0 to Hex. | ✓ VERIFIED | PR #78 and PR #79 grants and exact SHAs are recorded. Post-release CI [37706469417](https://github.com/szTheory/threadline/actions/runs/37706469417) passed all jobs, including min/latest and `CI required`. The `v1.0.0` tag and successful protected release workflow target `f815e589c954a8e3983bc6f73b21c9e3304d6aa4`; the Hex API serves 1.0.0 with docs and matching checksum. |

### Plan Must-Haves

| Plan | Must-have truth | Status | Evidence |
|---|---|---|---|
| 237-01 | 0.11.x adopters complete the conditional three-change 0.12 preflight, 0.12.x adopters skip it, and both follow exactly seven 1.0 steps. | ✓ VERIFIED | Guide sections and seven ordered headings; focused guide contract asserts the preflight and count. |
| 237-01 | Twelve 1.0 breaking entries and eight deprecations each map once to an actionable ID; three 0.12 entries are separate. | ✓ VERIFIED | Exact ID extraction and scope/duplicate/missing/extra assertions pass; 1.0 and 0.12 IDs appear in their own changelog sections. |
| 237-01 | The guide states 1.0 changes need no trigger regeneration and directs only adopters missing the earlier 0.11 migration to that procedure. | ✓ VERIFIED | Wording is in the guide; test asserts no trigger regeneration and conditional preflight scope. |
| 237-01 | The guide is registered in ExDoc and Adopt, and its contract has a partition weight. | ✓ VERIFIED | `mix.exs`, guide graph test, and `test/partition_weights.txt` verify each registration. |
| 237-02 | Strict candidate rehearsal requires committed `feat!`, one exact 1.0.0 footer and config false, then derives the target from that footer. | ✓ VERIFIED | Script implements these checks before clone creation; parser/config tests cover acceptance and rejection. |
| 237-02 | Candidate simulation reaches 1.0.0, rejects 0.13.0, and preserves artifact checks and source-tree identity. | ✓ VERIFIED | Candidate-bound rehearsal passed at `81041db…`; VALIDATION.md records 1.0.0 target, artifact checksum, 34-file identity, and clean source tree. |
| 237-02 | Ordinary non-candidate PR CI keeps its generic rehearsal through the stable job ID. | ✓ VERIFIED | Generic mode is default; topology contract preserves the `verify-bump-rehearsal` CI job and checks it is required. |
| 237-02 | Rehearsal reports identify local artifact scope and candidate SHA without claiming live Release Please. | ✓ VERIFIED | Script report labels the local run, records `SOURCE_SHA`, and explicitly disclaims a live Release Please invocation. |
| 237-03 | Exact v1.44-to-source-tip audit records both SHAs and reconciles every matching breaking footer with human 1.0 notes. | ✓ VERIFIED | The exact-range audit records 11 commits and 12 consequences, mapped to the dated changelog and guide. |
| 237-03 | Isolated candidate uses current main as parent, a conventional breaking subject, one 1.0.0 footer, and a passing strict rehearsal. | ✓ VERIFIED | GitHub API confirms landed squash SHA `371ce3a…` has parent `0d6f36f…`, the exact `feat!` subject, and one footer; candidate-bound rehearsal passed before merge. |
| 237-03 | Candidate-bound rehearsal precedes full CI; PG15/latest pins are checked and local success is not represented as a remote grant/action. | ✓ VERIFIED | VALIDATION.md records the ordering, local suite, and pin values; release/push/merge/publication evidence is separately labeled. |
| 237-04 | Candidate push follows a fresh explicit grant bound to its SHA. | ✓ VERIFIED | Recorded grant is tied to candidate `81041db…`; PR #78 used that head. |
| 237-04 | Milestone merge follows a separate grant and green exact-head required CI including PG15/latest. | ✓ VERIFIED | Recorded conditional merge grant followed PR #78 CI success on the exact candidate SHA; its required lanes passed before merge. |
| 237-04 | Landed main commit is one conventional `feat!` squash with one footer; live Release Please is separate from local rehearsal. | ✓ VERIFIED | GitHub commit API confirms exact subject/footer and parent; Release Please run/PR and local rehearsal have distinct records. |
| 237-05 | Generated 1.0.0 Release PR merged after its own grant and green required CI, then live release/tag identify 1.0.0. | ✓ VERIFIED | PR #79's exact-head CI passed; PR API records merge to `f815e58…`; tag and release point to the same SHA. |
| 237-05 | Protected production-Hex publish followed another grant and Hex serves threadline 1.0.0. | ✓ VERIFIED | Release workflow publish job succeeded following the recorded separate grant; public Hex release API lists 1.0.0 with docs. |
| 237-05 | Verification distinguishes local rehearsal, live Release Please, live required CI, protected publication, and public package evidence. | ✓ VERIFIED | Separate sections, SHAs, run links, job links, and registry records appear in VALIDATION.md and this report. |

### Release Authorization Evidence

| Action | Recorded grant | Bound evidence |
|---|---|---|
| Candidate push | The recorded `yes i authorize/grant u` grant covered the initial candidate push. A later scoped authorization covered updating that branch to revised candidate `81041db…` and triggering fresh CI. | Phase 237-04 record identifies the branch and candidate SHA; PR #78 used the revised candidate. |
| Milestone squash | Conditional grant: “and if ci is green on that i authorize u to auto squash merge it then too...” | Applied to PR #78 only after its exact-head required CI passed; merged as `371ce3a…`. |
| Release PR merge | Separate `yes` after exact-head PR #79 preflight. | PR #79 head `5132b55…`, base `371ce3a…`, merge commit `f815e58…`; exact-head CI run 37705157832 passed. |
| Protected Hex publication | A separate `yes` after the release/tag/CI checks. | Release run 37706469316, tag `v1.0.0`, merge SHA `f815e58…`, protected `production-hex` publish job 113084855750 succeeded. |

**Score:** 21/21 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `guides/upgrading-to-1.0.md` | Complete 0.11/0.12 to 1.0 adopter procedure | ✓ VERIFIED | Substantive seven-step procedure, separately scoped 0.11-only preflight, actionable changes, and trigger guidance. |
| `guides/upgrade-path.md` | Route adopters to the 1.0 guide | ✓ VERIFIED | 0.12.x jump points to the detailed 1.0 guide. |
| `CHANGELOG.md` | Human-owned breaking/deprecation record | ✓ VERIFIED | Dated 1.0.0 section and scoped IDs; Unreleased staging heading retained. |
| `test/threadline/upgrading_to_1_0_doc_contract_test.exs` | Change-map and guide-shape contract | ✓ VERIFIED | Exact set/scope/uniqueness assertions, seven-step ordering, trigger rule, and registration checks. |
| `test/threadline/guide_graph_contract_test.exs` | Guide graph registration | ✓ VERIFIED | New guide is in the Adopt inventory and graph routing. |
| `test/partition_weights.txt` | Weighted contract test | ✓ VERIFIED | Explicit entry for the new contract. |
| `release-please-config.json` | 1.0 major-bump configuration | ✓ VERIFIED | `bump-minor-pre-major` is literal JSON `false`. |
| `bin/verify-bump-rehearsal` | Strict candidate artifact rehearsal | ✓ VERIFIED | Candidate metadata is validated before disposable-clone release simulation; normal generic mode remains available. |
| `test/threadline/ci_topology_contract_test.exs` | Candidate parser and CI topology controls | ✓ VERIFIED | Acceptance/rejection controls exercise the parser and preserve the stable CI job. |
| `test/threadline/changelog_contract_test.exs` | Release config and changelog ownership contract | ✓ VERIFIED | Pins config boolean and generated/human changelog ownership. |
| `.planning/phases/237-upgrade-guide-and-1-0-0/237-VERIFICATION.md` | Auditable range, candidate, and release evidence | ✓ VERIFIED | This report carries the milestone audit and release boundary evidence. |
| `.planning/MILESTONE-ARC.md` | Record shipped 1.0.0 and closeout state | ✓ VERIFIED | Records v1.45/1.0.0 shipped and accurately says closeout is pending PR #80. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `CHANGELOG.md` | `guides/upgrading-to-1.0.md` | Scoped hidden IDs and actionable steps | ✓ WIRED | Exact-set contract connects every source entry to guide content. |
| `guides/upgrade-path.md` | `guides/upgrading-to-1.0.md` | Adopter route | ✓ WIRED | Relative link resolves to the detailed guide. |
| `guides/upgrading-to-1.0.md` | `mix.exs` / Adopt graph | ExDoc and guide registration | ✓ WIRED | Guide appears in ExDoc extras and the Adopt graph contract. |
| `release-please-config.json` | `bin/verify-bump-rehearsal` | Candidate mode checks the config | ✓ WIRED | Script parses the JSON boolean and fails closed unless it is `false`. |
| `bin/verify-bump-rehearsal` | `mix.exs` | `mix verify.bump_rehearsal` and in-clone `verify.release` | ✓ WIRED | Mix aliases dispatch to the script; the disposable clone invokes the release gate. |
| Candidate commit / CI workflow | Release evidence | Exact SHA, PR, and green required checks | ✓ WIRED | PR #78's granted candidate and merge record, followed by successful CI on the exact release SHA, are recorded separately from local rehearsal. |
| Release workflow | GitHub release / Hex | Release tag, CI gate, protected publish, smoke, distribution sync | ✓ WIRED | Live workflow jobs completed on `f815e58…`; tag and public Hex metadata agree on 1.0.0. |

The generic key-link query reports false negatives for prose/evidence-record links because it searches for literal target references. The links above were checked directly in guide/test code and against live workflow/job records; this did not reveal an unwired path.

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Upgrade guide contract | Breaking/deprecation ID sets | Human-owned changelog and rendered guide files | Yes; reads both files and compares scoped sets | ✓ FLOWING |
| Candidate release rehearsal | Target version and source SHA | Committed HEAD subject/body plus parsed Release-As trailer | Yes; derives `1.0.0` and reports the exact source SHA | ✓ FLOWING |
| Release verification | Tag and package version/SHA | GitHub commit/tag/release APIs and Hex package APIs | Yes; live remote records agree on `f815e58…` and `1.0.0` | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Guide/change-map and graph contracts | Focused `mix verify.test` command in VALIDATION.md | 50 tests passed, 0 failures | ✓ PASS |
| Full local regression | `mix verify.test` (today's local run, sandbox-approved `.git` access and Hex/npm caches under `/private/tmp`) | 3,058 tests, 0 failures, 3 excluded | ✓ PASS |
| ExDoc generation | `MIX_ENV=dev mix docs --warnings-as-errors` | Passed without warnings | ✓ PASS |
| Candidate-bound release simulation | `THREADLINE_BUMP_REHEARSAL_MODE=candidate mix verify.bump_rehearsal` | Passed; target 1.0.0 and not 0.13.0; local artifact/tree checks passed | ✓ PASS |
| Release SHA CI | [Run 37706469417](https://github.com/szTheory/threadline/actions/runs/37706469417) | `CI required`, min PostgreSQL 15, latest, and all component jobs passed on `f815e58…` | ✓ PASS |
| Protected release workflow | [Run 37706469316](https://github.com/szTheory/threadline/actions/runs/37706469316) | Release, publish, smoke, and distribution-sync jobs succeeded | ✓ PASS |

The focused documentation, rehearsal, and release checks above are recorded in `237-VALIDATION.md`; the local regression result is today's run supplied with this verification request. No tests were added or rerun during this report update.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| DOCS-03 | 237-01 | One complete seven-step 1.0 guide, scoped preflight, trigger guidance, and changelog contract | ✓ SATISFIED | Guide, exact-ID tests, ExDoc/Adopt registration, graph test, and partition weight verified. |
| REL-01 | 237-02, 237-03 | Release Please proposes exactly 1.0.0 from explicit config and footer | ✓ SATISFIED | Strict parser/config verified; committed candidate rehearsal and landed squash footer recorded. |
| REL-02 | 237-01, 237-03 | Human 1.0 changelog covers all milestone breaks/deprecations and is cross-checked | ✓ SATISFIED | Exact `v1.44..6227ad9…` audit records 11 commits / 12 consequences and mapping. |
| REL-03 | 237-02 through 237-05 | Granted squash, green CI, release-please tag, separate protected publish, public Hex 1.0.0 | ✓ SATISFIED | PR #79, merge/tag SHA, successful exact-SHA CI and protected release jobs, and public Hex API all agree. |

All four Phase 237 requirements are mapped and satisfied, matching the current REQUIREMENTS.md traceability and completed roadmap. The milestone-wide closeout is recorded separately in the v1.45 milestone audit.

### Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---|---|---|
| `test/threadline/upgrading_to_1_0_doc_contract_test.exs` | DOCS-03, REL-02 | yes | 0 | no | Behavioral/value: exact scoped sets, uniqueness, ordering, and required wording | ✓ PASS |
| `test/threadline/guide_graph_contract_test.exs` | DOCS-03 | yes | 0 | no | Behavioral: graph route and link resolution | ✓ PASS |
| `test/threadline/changelog_contract_test.exs` | REL-01, REL-02 | yes | 0 | no | Value: JSON booleans, scope/ownership contracts | ✓ PASS |
| `test/threadline/ci_topology_contract_test.exs` | REL-01, REL-03 | yes | 0 | no | Behavioral/value: parser acceptance/rejection and CI wiring | ✓ PASS |

Disabled-test scan found no disabled tests linked to these requirements. Writer-pattern scan found no circular fixture generation in the linked contract files.

### Decision Coverage

All trackable CONTEXT.md decisions are honored by shipped artifacts: 5/5; none unhonored.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | No blocking debt markers or implementation stubs found in the phase's changed artifacts | — | — |

The medium residual security note T-237-02 in `237-SECURITY.md` says the contract does not pin the guide's explanation of exploration hydration versus capture persistence. The guide itself states the distinction and the unchanged `action_id`/foreign key; this is a non-blocking contract-strengthening note, not a failed roadmap or plan must-have.

## Human Verification Required

None. The user-facing documentation has executable contracts and a clean agent review; release and package state were checked through live GitHub and Hex records. No behavior-dependent or non-inferable truth remains without direct evidence.

## Gaps Summary

No Phase 237 goal conditions remain unmet. Phase success is verified: the adopter guide and complete changelog are present, the single `feat!` squash produced the `v1.0.0` release, and Hex serves the package with documentation.

Milestone closeout remains pending. `.planning/MILESTONE-GUIDE.txt` §11 requires release-please and distribution-sync PRs closed before archiving the whole milestone. PR #80 (`chore(release): sync distribution docs for 1.0.0`) is open and unmerged; its workflow-created CI/merge decision is outside this phase goal and has no separate merge grant. Keep it open until its own closeout conditions and authorization are handled. `.planning/MILESTONE-ARC.md` accurately records this pending closeout.

---

_Verified: 2026-10-08T00:53:59Z_
_Verifier: the agent (gsd-verifier)_
