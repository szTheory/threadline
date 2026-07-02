---
phase: 191-release-version-and-docs-trust-repair
verified: 2026-07-02T00:00:00Z
status: passed
score: 16/16 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 191: Release Version & Docs Trust Repair Verification Report

**Phase Goal:** Remove public-version drift and sharpen the adoption path so a stranger can trust the README, Hex line, evaluator docs, and upgrade story without maintainer context.
**Verified:** 2026-07-02
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

The phase goal decomposes into the four ROADMAP success criteria (the roadmap contract) plus the twelve plan-frontmatter must-have truths (three per-plan lanes). Every one is observably true in the codebase and locked by a passing, non-vacuous drift guard. A stranger opening the repo sees a single `0.9.0` truth on every public surface, a per-minor upgrade story that answers "must I act?", a four-verb routing table, and drift-guard tests that will fail if any of it re-drifts.

### Observable Truths — ROADMAP Success Criteria (contract)

| # | Truth (SC) | Status | Evidence |
| --- | --- | --- | --- |
| SC1 | README/guides/evaluator docs/backlog/package metadata/install snippets agree on `0.9.0` or explicitly justify older examples | ✓ VERIFIED | All 7 install pins read `{:threadline, "~> 0.9.0"}` (README.md:67, getting-started-saas.md:26, operator-surface.md:30, evaluating-threadline.md:38, adoption-evidence-playbook.md:15, adoption-pilot-backlog.md:14, priv/ci/hex_evaluator/mix.exs:27); `@version "0.9.0"` in mix.exs:4; zero stale `~> 0.6/0.5/0.3` live pins; historical `0.6.0 packages Evidence…after 0.5.0` line explicitly preserved as history (evaluating-threadline.md:13) |
| SC2 | Upgrade guidance covers 0.6.x→0.9.x adopter effects: storage-schema default, operator surface/theming, release lanes, migration expectations | ✓ VERIFIED | upgrade-path.md: four-theme orientation table (lines 89-92) with exact ADOPT-02 keywords; per-minor spine (lines 98-100); per-bump detail bullets (105-107); storage-schema freeze-at-generation callout distinct from host `table_schema` (111-115); division-of-labor note (81); backport policy (68) |
| SC3 | README/ExDoc routing gives evaluators/first-hour adopters/operators/maintainers a short next-step path | ✓ VERIFIED | README `## Start here` three-column intent table (lines 25-30) with Evaluate/Adopt/Operate/Contribute → canonical landing + next hop; collapsed `<details>` all-guides index grouped by the four verbs (193-232); mix.exs `groups_for_extras` (286-295) exposes the four verb lanes + Overview + Integrations; no standalone start-here/where-to-go-next guide |
| SC4 | Doc-contract tests fail on future install/version/upgrade drift | ✓ VERIFIED | version_truth_doc_contract_test (Families A install-pin, B marker+extra-files, C current-minor coverage) derives all from `@version`, globs README+guides, guards vacuous scan; persona_routing_doc_contract_test locks routing; upgrade_path_doc_contract_test extended (theme axis + per-minor + nothing-required + refutes). Both new tests registered in `verify.doc_contract`, which runs under `ci.all` |

### Observable Truths — Plan Must-Haves

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 (P01) | Adopter on 0.6/0.7/0.8.x learns per-minor whether action is required | ✓ VERIFIED | Per-minor spine + bullets (upgrade-path.md 98-107), each with explicit "nothing required" |
| 2 (P01) | Each of four ADOPT-02 themes has an orientation entry naming landing + adopter action | ✓ VERIFIED | Theme table upgrade-path.md 89-92, exact keyword phrasing |
| 3 (P01) | Storage-schema freeze-at-generation expectation stated, distinct from host table_schema | ✓ VERIFIED | upgrade-path.md 111-115 |
| 4 (P01) | Backport-policy sentence in both upgrade-path.md and CONTRIBUTING.md | ✓ VERIFIED | upgrade-path.md:68, CONTRIBUTING.md:187-189 (identical commitment) |
| 5 (P02) | README `## Start here` three-column intent table, four verb rows to canonical landings | ✓ VERIFIED | README 25-30 |
| 6 (P02) | Flat `## Documentation` dump replaced by collapsed `<details>` all-guides index; every guide link survives | ✓ VERIFIED | README 193-232; all prior guide links present + relocated lane-matrix/Phoenix-auth literals (34) |
| 7 (P02) | mix.exs groups_for_extras exposes four verb lanes + Overview + Integrations, each extra in one lane | ✓ VERIFIED | mix.exs 286-295; release_artifact groups-key equality test passes (no ungrouped extra); `mix docs` clean per baseline |
| 8 (P02) | No standalone start-here/where-to-go-next guide exists | ✓ VERIFIED | `ls` confirms neither file exists; persona_routing refute passes |
| 9 (P03) | Every install snippet reads `~> 0.9.0` (three-segment, bound to @version); no scoped guard asserts stale `~> 0.6` | ✓ VERIFIED | grep of all pins (SC1); guard tests refute stale pins and pass |
| 10 (P03) | evaluating-threadline.md current claim reads 0.9.0 + marker; historical 0.6.0 line survives verbatim | ✓ VERIFIED | evaluating-threadline.md:11 (`0.9.0` + `x-release-please-version`), line 13 historical intact |
| 11 (P03) | priv/ci/hex_evaluator installs `~> 0.9.0` with regenerated lock | ✓ VERIFIED | mix.exs:27 pin; mix.lock:13 resolves `threadline 0.9.0` from hexpm |
| 12 (P03) | version_truth test derives pin+version from @version, globs README+guides, runs under ci.all, fails on drift | ✓ VERIFIED | test source reviewed (Families A/B/C, no hardcoded literal, empty-scan guard); registered in verify.doc_contract → ci.all |

**Score:** 16/16 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| guides/upgrade-path.md | 0.6.x→0.9.x era, 4 themes, per-minor, storage-schema, backport, division-of-labor | ✓ VERIFIED | All content present and locked by extended test |
| CONTRIBUTING.md | backport-policy sentence | ✓ VERIFIED | Dedicated `## Backport policy (maintainers)` subsection |
| README.md | Start here intent table + `<details>` index | ✓ VERIFIED | Both present; preservation literals survive |
| mix.exs groups_for_extras | four verb lanes | ✓ VERIFIED | Explicit per-lane regexes, Integrations before verb lanes |
| evaluating-threadline.md | SSOT 0.9.0 + marker | ✓ VERIFIED | Line 11 corrected + marked; historical line preserved |
| release-please-config.json | evaluating-threadline.md in extra-files | ✓ VERIFIED | Both marked files registered; no pin-bearing file |
| priv/ci/hex_evaluator/mix.exs + mix.lock | `~> 0.9.0` + regenerated lock | ✓ VERIFIED | Pin + lock resolve to threadline 0.9.0 |
| version_truth_doc_contract_test.exs | new, Families A/B/C | ✓ VERIFIED | Substantive, derives from @version, registered |
| persona_routing_doc_contract_test.exs | new, subset+landing+refute | ✓ VERIFIED | Substantive, registered |
| upgrade_path_doc_contract_test.exs | extended: theme+per-minor+refutes | ✓ VERIFIED | New assertions present, non-vacuous |
| release_artifact_contract_test.exs | groups-key equality updated + README pin | ✓ VERIFIED | `[:Overview,:Integrations,:Evaluate,:Adopt,:Operate,:Contribute]`; asserts `~> 0.9.0` |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| README verb labels | mix.exs groups_for_extras keys | shared four-verb vocabulary | ✓ WIRED | persona_routing asserts subset; release_artifact asserts exact order |
| both new tests | verify.doc_contract alias | mix.exs:82 space-joined string | ✓ WIRED | Both appended; alias in ci.all (mix.exs:106) |
| x-release-please-version markers | release-please extra-files | Family B identity check | ✓ WIRED | Both marked files (evaluating-threadline, adoption-pilot-backlog) registered |
| version_truth Family C | upgrade-path.md 0.8.x→0.9.x | derived-from-@version read | ✓ WIRED | Coverage present; test passes |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase-touched doc-contract guards all pass | `mix test` on 10 guard files | 82 tests, 0 failures | ✓ PASS |
| Drift guards are non-vacuous | source review of version_truth (empty-scan assertion) + upgrade_path (asserts real keywords) | genuine assertions, would fail on drift | ✓ PASS |
| hex_evaluator lock resolves 0.9.0 | grep mix.lock | `threadline 0.9.0` from hexpm | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| ADOPT-01 | 191-03 | Public install/version references agree on 0.9.0 or justify older | ✓ SATISFIED | SC1 + truths 9-12 |
| ADOPT-02 | 191-01 | Upgrade guidance covers 0.6.x→0.9.x era incl. migration expectations | ✓ SATISFIED | SC2 + truths 1-4 |
| ADOPT-03 | 191-02 | README/ExDoc routing without a giant new guide | ✓ SATISFIED | SC3 + truths 5-8 |

All three requirement IDs declared in PLAN frontmatter are accounted for and satisfied. REQUIREMENTS.md maps only ADOPT-01/02/03 to Phase 191 — no orphaned requirements.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| (none) | — | — | — | No TBD/FIXME/XXX, no aspirational tokens (`coming soon`/`forthcoming`) in phase docs; "mask placeholder" in operator-surface.md is a legitimate redaction feature term, not a stub |

### Known / Deferred (not a phase-191 gap)

`test/threadline/v1_23_charter_doc_contract_test.exs` fails (asserts PROJECT.md v1.38 milestone strings; PROJECT.md correctly moved to v1.39 when the current milestone opened 2026-07-01). This is a PRE-EXISTING failure confirmed failing before phase execution, outside the phase's declared file scope, and about milestone-charter truth — a distinct axis from ADOPT-01/02/03. It is logged in deferred-items.md across all three plans and does not affect any of the four success criteria. Not attributed to this phase; not a blocker to the phase goal.

### Human Verification Required

None. Every success criterion decomposes into objectively verifiable doc content, all confirmed by direct file inspection and 82 passing, non-vacuous drift guards. The "stranger can trust it" outcome is fully operationalized by the four criteria, each met.

### Gaps Summary

No gaps. All four ROADMAP success criteria and all twelve plan must-have truths are verified in the codebase and locked by passing drift-guard tests wired into `ci.all`. Install pins, SSOT claim, upgrade story, routing, and drift guards are all in place and mutually consistent. A stranger reading the README, Hex line, evaluator docs, and upgrade guide gets one coherent `0.9.0` truth with per-minor "must I act?" answers and a four-verb next-step path — with no maintainer context required.

---

_Verified: 2026-07-02_
_Verifier: Claude (gsd-verifier)_
