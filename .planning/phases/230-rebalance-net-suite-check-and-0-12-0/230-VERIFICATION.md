---
phase: 230-rebalance-net-suite-check-and-0-12-0
verified: 2026-10-03T00:00:00Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-01-PLAN.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-01-SUMMARY.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-02-PLAN.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-02-SUMMARY.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-03-PLAN.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-03-SUMMARY.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-04-PLAN.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-04-SUMMARY.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-CONTEXT.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-DISCUSSION-LOG.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-EVIDENCE.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-PATTERNS.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-RESEARCH.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-REVIEW-DISPOSITION.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-REVIEW.md"
  - ".planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-VALIDATION.md"
  - "CHANGELOG.md"
  - "CONTRIBUTING.md"
  - "guides/upgrade-path.md"
  - "lib/threadline/health.ex"
  - "lib/threadline/health/coverage_schemas.ex"
  - "lib/threadline/operator_surface/live/coverage_live.ex"
  - "lib/threadline/operator_surface/live/evidence_live.ex"
  - "lib/threadline/operator_surface/live/transaction_live.ex"
  - "lib/threadline/operator_surface/stress_fixtures.ex"
  - "lib/threadline/operator_surface/ui/page.ex"
  - "test/partition_weights.txt"
  - "test/threadline/brandbook_token_parity_test.exs"
  - "test/threadline/operator_surface/coverage_doc_contract_test.exs"
  - "test/threadline/operator_surface/policy_show_doc_contract_test.exs"
  - "test/threadline/operator_surface_doc_contract_test.exs"
  - "test/threadline/support_playbook_doc_contract_test.exs"
covered_digest: "v2:sha256:6611fdbe3c336364c7eb1c137578289c2751a591cbffc900c8fe3b71fd828008"
behavior_unverified: 0
overrides_applied: 0
coincidental_reliance_items: []
---

# Phase 230: Rebalance, Net-Suite Check and 0.12.0 Verification Report

**Phase Goal:** The maintainer ships a milestone whose suite is more honest and no slower than where it started, released as 0.12.0 on hex.pm
**Verified:** 2026-10-03
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (mapped to ROADMAP Success Criteria)

| # | Truth (ROADMAP SC) | Status | Evidence |
|---|---|---|---|
| 1 | SC1: keep/cut rubric recorded and applied to all six guard-test files (incl. the four not previously audited); prose-to-literal tests cut, live-derived/mutation-controlled tests kept; no CI-topology or CONTRIBUTING contract test cut | ✓ VERIFIED | `stg_doc_contract_test.exs` and `operator_surface/theme_doc_contract_test.exs` deleted and absent from the tree (`git grep` for their names returns 0 hits outside `.planning/`); `operator_surface_doc_contract_test.exs` 15→6 tests (`grep -c '^  test "'` = 6), `coverage_doc_contract_test.exs` 0 `File.read!("guides/` hits remain, `policy_show_doc_contract_test.exs` 0 `@domain_reference_path` hits remain; `storage_schema_migration_contract_test.exs`/`storage_schema_prefix_contract_test.exs` untouched (plan 01 diff-quiet check); CONTRIBUTING.md carries `### Writing a doc-contract or guard test` (confirmed at line 261 in current tree); v1.43 mutation-control cross-check performed and recorded (230-EVIDENCE.md) |
| 2 | SC2: `ci-required` roster unchanged; rebalance reports wall clock before/after | ✓ VERIFIED | `git diff fc47af60 origin/main -- .github/workflows/ci.yml` is empty (confirmed live against the landed tree) — 13-job roster byte-identical; 230-EVIDENCE.md `### Wall clock before and after` records 3 before runs (median 137.44s) and 3 after runs (median 151.59s) |
| 3 | SC3: milestone suite-time table cites every phase's before/after figure; net suite time does not regress against SUITE-01, locally and in CI, with run IDs | ✓ VERIFIED (see note below) | `### Milestone suite-time table (D-09)` cites phases 224-230 each with a source doc and (where published) a CI run id; `SUITE-06 verdict` row: CI step-sum 846s (SUITE-01) → 507s (run 37082623361, landing PR's own CI run) = -40.1%, confirmed PASS under the D-06 formula fixed in 230-02 before measurement. **Local figure note:** the local `mix test` median rose 137.44s → 151.59s (+14.15s, +10.3%) — a literal regression, not a non-regression. This is disclosed, not hidden, in 230-EVIDENCE.md, and is explicitly addressed by a decision locked in 230-CONTEXT.md *before* any measurement was taken: D-06 names CI step-sum wall clock as "the gate" (committers' actual wait time, and SUITE-01/02's own comparator), and D-08 names local figures "context, not the comparator," citing this machine's documented ≈52-56s noise floor (224-EVIDENCE.md) as an order of magnitude larger than the observed +14.15s delta. Read plainly, ROADMAP SC3's "locally and in CI" is satisfied as "both figures reported, with CI run IDs" rather than "non-regression required in both domains" — a reading the phase's own locked pre-measurement decisions make explicit, not a post-hoc rationalization invented to explain away an inconvenient number. No evidence of papering over: the +14.15s increase is stated in the table and in two prose paragraphs, with the actual delta, not just the caveat. |
| 4 | SC4: milestone lands on main as one squash with a clean conventional `feat:` title; release-please ships 0.12.0; hex.pm serves it; `latest` lane pins re-checked against builds.hex.pm/Docker Hub, result cited | ✓ VERIFIED | Live-checked: `origin/main` head is `0d6f36f1` (`chore(release): sync distribution docs for 0.12.0 (#75)`, merged); `origin/main~2` = `67090195` = `feat!: add export and retention telemetry, a history limit, and strict coverage checks (#73)`, body carries exactly 3 `BREAKING CHANGE:` footers (confirmed via `git log -1 --format=%B 67090195`); `gh release view v0.12.0` returns tag `v0.12.0` (published 2026-10-03T00:57:10Z); `curl https://hex.pm/api/packages/threadline/releases/0.12.0` returns `"version":"0.12.0"`, inserted 2026-10-03T01:08:48Z; release run 37084163662 jobs all `success` (Release Please, Select release ref, Verify CI green, Publish to Hex.pm, Smoke test, Post-publish distribution sync); PRs #73/#74/#75 all `MERGED` with their recorded merge commits exactly matching `git log` on `origin/main`; pin re-check table in 230-EVIDENCE.md cites builds.hex.pm and Docker Hub URLs with verdict "current" for Elixir 1.20.4, OTP 29.1.1, PostgreSQL 18.6 |
| 5 | SC5: `mix ci.all` and `bin/verify-repo-hygiene` green at close; no phase/plan ID in `lib/`, guides or the 0.12.0 CHANGELOG | ✓ VERIFIED | Plan 03 ran `mix ci.all` to completion (318 passed, 0 failed, 26 skipped, Dialyzer 0 errors) and `bin/verify-repo-hygiene` (4472 files clean) on the pre-landing tree, both recorded with exit codes in 230-EVIDENCE.md `### Gate results`; re-ran `bin/verify-repo-hygiene` live against the current tree — `4476 tracked text file(s) clean; 8 allowlist entries used, 0 inert`; live ID-sweep re-run against the current tree: `grep -rnE '...' lib guides` = 36 hits, all of which are the same reviewed date-literal exclusions recorded in evidence (0 phase/plan/decision/requirement-ID tokens); the 0.12.0 CHANGELOG block scan returns 0 ID hits |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `test/threadline/stg_doc_contract_test.exs` | deleted | ✓ VERIFIED | absent from tree, 0 remaining references |
| `test/threadline/operator_surface/theme_doc_contract_test.exs` | deleted | ✓ VERIFIED | absent from tree, 0 remaining references |
| `test/threadline/operator_surface_doc_contract_test.exs` | trimmed to 6 tests | ✓ VERIFIED | `grep -c '^  test "'` = 6 |
| `test/threadline/operator_surface/coverage_doc_contract_test.exs` | trimmed, guide-prose removed | ✓ VERIFIED | 0 `File.read!("guides/` hits |
| `test/threadline/operator_surface/policy_show_doc_contract_test.exs` | trimmed, 1 test cut | ✓ VERIFIED | 0 `@domain_reference_path` hits |
| `CONTRIBUTING.md` | carries keep/cut rubric | ✓ VERIFIED | `### Writing a doc-contract or guard test` present |
| `CHANGELOG.md` | dated `## [0.12.0]` entry | ✓ VERIFIED | `## [0.12.0] - 2026-10-02` present, above `## [0.11.2]` |
| `guides/upgrade-path.md` | `0.11.x → 0.12.x` coverage | ✓ VERIFIED | 3 occurrences (table row + bullet + narrative reference) |
| `.planning/.../230-EVIDENCE.md` | SUITE-04/SUITE-06/REL-01 sections | ✓ VERIFIED | all required `##`/`###` headings present (`## SUITE-04 rebalance`, `## SUITE-06 net suite time`, `## Pre-land gate`, `## Release (REL-01)`) |
| `main @ squash commit` (67090195) | one `feat!:` commit, 3 `BREAKING CHANGE:` footers | ✓ VERIFIED | live `git log` confirms |
| `v0.12.0` (tag + release + Hex package) | live | ✓ VERIFIED | `gh release view`, `curl hex.pm` both confirm |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `test/partition_weights.txt` | deleted test files | weight-line removal | ✓ WIRED | 2 lines removed, 0 dangling entries (plan 01 verify) |
| ci-required roster (BASE) | ci-required roster (landed) | `git diff fc47af60 origin/main -- .github/workflows/ci.yml` | ✓ WIRED | empty diff, confirmed live |
| squash commit footers | release-please generated notes | conventional-commit parsing | ✓ WIRED | release PR #74's CHANGELOG-GENERATED.md 0.12.0 section lists all 3 breaking changes (collapsed into one generated bullet — a presentation difference, recorded as a deviation, not a content loss) |
| landing PR #73 CI run | SUITE-06 verdict row | `ci-job-timing.py --cache-state` + D-06 formula | ✓ WIRED | run 37082623361, all lanes cache-hit, Σ 507s ≤ 930.6s, verdict PASS |
| release PR merge | production-hex → hex.pm | release.yml push trigger | ✓ WIRED | run 37084163662, publish-hex/smoke/distribution-sync all success, hex.pm serves 0.12.0 |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| SUITE-04 | 230-01 | Guard-test rubric recorded and applied | ✓ SATISFIED | REQUIREMENTS.md marks Complete; verified above (truth 1) |
| SUITE-06 | 230-02, 230-04 | Net suite time does not regress milestone-wide | ✓ SATISFIED (CI gate; local caveat noted) | REQUIREMENTS.md marks Complete; verified above (truth 3) |
| REL-01 | 230-03, 230-04 | Milestone lands as squash, 0.12.0 ships via release-please, pins re-checked | ✓ SATISFIED | REQUIREMENTS.md marks Complete; verified above (truth 4) |

No orphaned requirements: REQUIREMENTS.md's "Phase 230" rows (SUITE-04, SUITE-06, REL-01) all appear in at least one plan's `requirements:` frontmatter (230-01: SUITE-04; 230-02: SUITE-06; 230-03: REL-01; 230-04: REL-01, SUITE-06).

### Anti-Patterns Found

Scanned all `lib/` files touched by plan 03's SC5 sweep plus `CHANGELOG.md`, `guides/upgrade-path.md`, and `CONTRIBUTING.md` for `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` markers: **none found.**

Code review (230-REVIEW.md, standard depth, 15 files) found 0 critical, 0 warning, 1 info-level finding (IN-01: a stylistic inconsistency — `operator_surface_doc_contract_test.exs` keeps its KEEP-rationale comment outside `@moduledoc` instead of inside it, unlike its two trimmed siblings). Disposition (230-REVIEW-DISPOSITION.md): left open as an advisory style nit, test-only, no runtime effect, candidate for a later tidy-up. Not a blocker.

### Deviations Noted in Evidence (reviewed, not gaps)

1. **Release-please collapsed 3 `BREAKING CHANGE:` footers into 1 generated bullet** naming all three changes. CHANGELOG.md (hand-written) keeps them as 3 separate entries with `Fix:` lines. Judged a presentation difference, not missing content — confirmed by inspecting the squash commit body directly (3 footers present) and the generated notes (one bullet, all three named).
2. **CHANGELOG.md dated 2026-10-02; CHANGELOG-GENERATED.md dated 2026-10-03** — UTC rolled over minutes after the push. No contract test objected; release PR CI was green.
3. **Local suite wall clock increased** 137.44s → 151.59s after the SUITE-04 cuts (34 tests removed). Addressed in truth 3 above: disclosed honestly, attributed to documented machine noise floor, and the actual release gate (CI step-sum) decreased 40.1%.

None of these rise to a gap: each is disclosed with evidence, matches a pre-locked phase decision (D-06, D-08, D-12/D-13 shape), and was independently confirmed against live remote state in this verification, not just taken from SUMMARY.md narrative.

### Human Verification Required

None. All must-haves resolved to VERIFIED via direct codebase inspection and live read-only queries against GitHub and hex.pm (git log, gh release view, gh pr view, gh run view, curl hex.pm API).

### Gaps Summary

No gaps. All five ROADMAP success criteria for Phase 230 are verified against the current codebase and live remote state, not solely against SUMMARY.md claims. The one literal-reading discrepancy (SC3's local-figure wording vs. the observed local increase) is documented above with full reasoning rather than silently passed — it resolves to VERIFIED because the phase's own pre-measurement locked decisions (D-06/D-08) explicitly designate CI as the regression gate and local figures as disclosed context, and the increase was in fact disclosed, not concealed.

---

_Verified: 2026-10-03_
_Verifier: Claude (gsd-verifier)_
