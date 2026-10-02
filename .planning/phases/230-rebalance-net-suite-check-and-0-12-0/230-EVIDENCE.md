# Phase 230 Evidence — Rebalance, Net-Suite Check and 0.12.0

Scope: this document records the SUITE-04 guard-test rebalance (whole-file cuts,
line-item trims, the recorded rubric) and the rebalance's own local wall clock
before and after. Net-suite (SUITE-06) and release (REL-01) evidence are
appended by later plans in this phase.

## SUITE-04 rebalance

BASE: 4a04e4f38ea5d36f313e1b1e7ffdfbdd4fc799dc

### Before — three sequential `mix test` runs at BASE

| Run | real (s) | ExUnit summary |
|---|---|---|
| 1 | 137.44 | Finished in 136.8 seconds (13.8s async, 123.0s sync) — 32 properties, 2768 tests, 0 failures, 3 excluded |
| 2 | 138.38 | Finished in 137.7 seconds (14.1s async, 123.6s sync) — 32 properties, 2768 tests, 0 failures, 3 excluded |
| 3 | 134.07 | Finished in 133.5 seconds (12.7s async, 120.8s sync) — 32 properties, 2768 tests, 0 failures, 3 excluded |

Median real: 137.44s. Median Finished-in: 136.8s. All three runs: 0 failures.

local, noisy: this machine's own documented load-noise floor (phase 224's
evidence doc recorded head-vs-base swings of about 52 and 56 seconds in
opposite directions from unrelated concurrent processes on the same machine)
is an order of magnitude larger than any delta this rebalance is expected to
produce, so the local figure above is read as context, not as a precise
per-test measurement.

### Whole-file cuts (D-02)

| File | Test count | Verdict |
|---|---|---|
| `test/threadline/stg_doc_contract_test.exs` | 6 | Cut whole file — all 6 tests are CONTRIBUTING/guide prose cross-references |
| `test/threadline/operator_surface/theme_doc_contract_test.exs` | 11 | Cut whole file — moduledoc self-declares pure `File.read!` + `String.contains?` against guide prose |

Neither file's assertions were relocated anywhere (D-01).

### Weight-line removal

`test/partition_weights.txt` lost exactly 2 lines (the entries for the two
deleted files above) and gained 0 lines. The three trimmed files' (Task 2)
weight lines are left untouched — a stale weight only costs partition balance.

### Doc-contract floor (D-05)

`find test \( -name '*doc_contract_test.exs' -o -name '*readme_contract_test.exs' \) | wc -l`: 37 before this plan's cuts -> 35 after, against the `bin/verify-bump-rehearsal` floor of 30. The floor itself (`bin/verify-bump-rehearsal`) was not touched.

### Line-item ledger

**`test/threadline/operator_surface_doc_contract_test.exs`** (15 tests before -> 6 after)

| Test | Verdict | Rubric criterion | Reason |
|---|---|---|---|
| README routes the operator surface mount macro to its canonical owner | CUT | CUT 1 (prose-to-literal) | README mount-macro routing is a plain string check with no derivation |
| README documents fail-closed posture and links guide | PARTIAL -> renamed "README states the fail-closed security posture" | KEEP 2 (security boundary) / CUT 1 | Kept the fail-closed sentence (auth/security exception); cut the guide-link assertion (prose cross-reference) |
| operator surface guide declares route literals | CUT | CUT 1 | Route literals are a hand-typed string check; `git grep` confirmed non-prose integration coverage already exists (see below) |
| operator surface guide details fail-closed security and auth options | KEEP whole | KEEP 2 (security boundary) | fail-closed + `:authorize_fn` + unauthenticated-acknowledgement opt-out are the auth boundary |
| operator surface guide locks the canonical admin and support recipes | PARTIAL -> renamed "operator surface guide's mount recipe keeps its auth and export-auth gates" | KEEP 2 / CUT 1 | Kept `pipe_through [:browser, :admin_auth]` and `export_authorize_fn` (the mount recipe's auth gate and export-auth callback); cut the support-variation, `organization_id`, refutes and schema-count lines (prose) |
| operator surface guide documents :schemas for row history reification (DOC-03) | CUT | CUT 1 | Prose-to-literal check on guide wording, no live derivation |
| operator surface guide links the canonical upgrade-path guide and stays scoped | PARTIAL -> renamed "operator surface guide's install pin is derived from mix release.pins" | KEEP 1 (live-derived) / CUT 1 | Kept the `Pins.target_pin_version()`-derived install-pin assertion; cut the two doc-link asserts, the stays-focused assert and the stale-pin refutes (duplicate of `version_truth_doc_contract_test.exs` Family A, CUT 3) |
| operator surface owns procedures and routes exhaustive configuration to one reference | CUT | CUT 1 | Prose ownership-claim check against guide text |
| operator surface leads with the production mount before advanced operation links | CUT | CUT 1 | Byte-offset ordering of hand-typed headings; no live derivation |
| operator surface guide locks callback shape and export fallback wording | PARTIAL -> renamed "operator surface guide states that LiveView auth does not cover HTTP routes" | KEEP 2 / CUT 1 | Kept "`live_session` and `on_mount` protect the LiveView pages only" and "plain-text `403`" (the auth-scope boundary); cut the callback-signature prose and fallback wording |
| operator surface guide documents asset embedding and CSP opt-outs | CUT | CUT 1 | Prose config-flag documentation check |
| operator surface guide locks the default actor handoff story | CUT | CUT 1 | Prose narrative check |
| operator surface guide keeps Storybook out of adopter install guidance | CUT | CUT 1 | Prose exclusion-claim check |
| operator surface guide documents direct export route authorization boundary | KEEP whole | KEEP 2 (security boundary) | Export-auth exception: "HTTP export auth remains authoritative" pins the direct-export auth boundary |
| operator surface guide locks mounted parity table and rejects overclaiming | CUT | CUT 1 | Prose parity-table check against guide text |

**Route-literal integration finding:** `git grep -n -e '/audit/transactions/' -e '/audit/actors/' -e '/audit/rows/' -- test ':!test/threadline/operator_surface_doc_contract_test.exs'` returns 50+ hits across `transaction_live_test.exs`, `actor_live_test.exs`, `row_history_live_test.exs`, `row_history_component_test.exs`, `skip_link_test.exs` and others, all exercising those routes via real `live(conn, ...)` mounts. **Finding: integration coverage EXISTS** — not a deferred gap (D-03 n/a here).

**`test/threadline/operator_surface/coverage_doc_contract_test.exs`** (39 tests before -> 32 after)

| Test | Verdict | Rubric criterion | Reason |
|---|---|---|---|
| router declares live("/coverage", ...) inside live_session :threadline | KEEP | KEEP 1 (live source) | Reads live router source |
| Auth runs before Coverage.OnMount in the on_mount: list | KEEP | KEEP 2 (structural order) | Derives index order from live router source |
| surface_header.ex contains the literal "All tables captured" | KEEP | KEEP 1 | Live `*.ex` source literal |
| surface_header.ex renders the audit coverage gap pluralization format | KEEP | KEEP 1 | Live `*.ex` source literal |
| coverage_live.ex renders "Covered" badge state | KEEP | KEEP 1 | Live `*.ex` source literal |
| coverage_live.ex renders "Needs capture" badge state | KEEP | KEEP 1 | Live `*.ex` source literal |
| coverage_live.ex renders "Expected gap" badge state | KEEP | KEEP 1 | Live `*.ex` source literal |
| coverage_live.ex page heading and schema picker literals | KEEP | KEEP 1 | Live `*.ex` source literal |
| coverage schema helper error copy (D-33a) | KEEP | KEEP 1 | Live `*.ex` source literal |
| coverage_live.ex shows Refresh affordance with phx-click=refresh | KEEP | KEEP 1 | Live `*.ex` source literal |
| coverage_live.ex locks Phase 185 verifier next-step copy and accent action classes | KEEP | KEEP 1 | Live `*.ex` source literal |
| coverage_live.ex owns one selected-schema verdict and native schema select | KEEP | KEEP 1 | Live `*.ex` source literal |
| operator guide documents selected-schema readiness, schema recovery, refresh, and row actions | CUT | CUT 1 | Guide-only prose cross-reference, no source derivation |
| operator guide documents storage-schema plus support host-schema happy path | CUT | CUT 1 | Guide-only prose list of literals |
| production checklist uses audit-readiness language instead of dashboard language | CUT | CUT 1 | Guide-only prose check |
| threadline.health.coverage.ex declares @shortdoc with the locked literal | KEEP | KEEP 1 | Live `*.ex` source literal |
| threadline.health.coverage.ex @moduledoc lists the three usage forms | KEEP | KEEP 1 | Live `*.ex` source literal |
| threadline.health.coverage.ex declares the OptionParser strict spec | KEEP | KEEP 1 | Live `*.ex` source literal |
| S1 appears in task moduledoc + 3 guides | CUT | CUT 2 (duplicate) | Prose-identity check across guides; duplicates ordinary doc review |
| S2 appears in task moduledoc + 3 guides | CUT | CUT 2 (duplicate) | Prose-identity check across guides |
| production-checklist.md carries the --strict CI snippet line | CUT | CUT 1 | Guide-only prose snippet check |
| moduledoc states the --all-schemas usage lines | KEEP | KEEP 1 | Live `*.ex` source literal |
| moduledoc states the mutual-exclusion sentence | KEEP | KEEP 1 | Live `*.ex` source literal |
| domain-reference.md and operator-surface.md both document --all-schemas | CUT | CUT 1 | Guide-only prose check, two guides |
| --json emits exactly the locked top-level keys (sorted) plus the additive findings key | KEEP | KEEP 1 (real run) | Real `Coverage.run(["--json"])` + `Jason.decode!` schema check |
| --json expected_uncovered entries have exactly ["source", "table"] keys | KEEP | KEEP 1 (real run) | Real `Coverage.run(["--json"])` round trip |
| Threadline.Health declares @expected_uncovered_baseline ~w(schema_migrations) and only that | KEEP | KEEP 2 (baseline guard) | Live source regression guard against silent baseline growth |
| coverage_live.ex source does NOT call String.to_atom | KEEP | KEEP 2 (security — atom-leak) | Atom-leak vector refute |
| threadline.health.coverage.ex source does NOT call String.to_atom | KEEP | KEEP 2 (security) | Atom-leak vector refute |
| threadline.verify_coverage.ex source does NOT call String.to_atom | KEEP | KEEP 2 (security) | Atom-leak vector refute |
| health.ex source does NOT contain interpolated nspname/schemaname | KEEP | KEEP 2 (security — SQLi) | SQL-injection vector refute |
| coverage_live.ex source does NOT contain interpolated nspname | KEEP | KEEP 2 (security) | SQL-injection vector refute |
| threadline.health.coverage.ex source does NOT contain interpolated nspname | KEEP | KEEP 2 (security) | SQL-injection vector refute |
| threadline.verify_coverage.ex source does NOT contain interpolated nspname | KEEP | KEEP 2 (security) | SQL-injection vector refute |
| coverage_live.ex first line is the file-scope gate | KEEP | KEEP 2 (structural) | Live-source optional-deps gate check |
| on_mount.ex first line is the file-scope gate | KEEP | KEEP 2 (structural) | Live-source optional-deps gate check |
| surface_header.ex first line is the file-scope gate | KEEP | KEEP 2 (structural) | Live-source optional-deps gate check |
| threadline.health.coverage.ex does NOT have a Phoenix.LiveView file-scope gate | KEEP | KEEP 2 (structural) | Live-source optional-deps gate check |
| health/policy.ex does NOT have a Phoenix.LiveView file-scope gate | KEEP | KEEP 2 (structural) | Live-source optional-deps gate check |
| row_history_component.ex does NOT contain its own surface_header invocation | KEEP | KEEP 2 (structural) | Live-source inheritance check |

The now-unused private `guide_section/2` helper (only used by the three cut guide-prose tests) was removed.

**`test/threadline/operator_surface/policy_show_doc_contract_test.exs`** (12 tests before -> 11 after)

| Test | Verdict | Rubric criterion | Reason |
|---|---|---|---|
| domain reference documents policy.show --schema as host schema, not storage schema | CUT | CUT 1 | Reads only `guides/domain-reference.md` — prose-to-literal, no source derivation |
| (all other 11 tests) | KEEP whole, unchanged | KEEP 1 / KEEP 2 | Live source literals, live `Show.run(["--json"])` round trip, cross-file label/order parity and no-secret-leak refutes — unchanged |

The now-unused `@domain_reference_path` attribute was removed with its sole test.

### v1.43 mutation-control cross-check

`grep -n -i -e mutation -e doc_contract .planning/milestones/v1.43-MILESTONE-AUDIT.md`: 1 hit (line 113, a targeted-run tally line mentioning `ci_coverage_doc_contract_test.exs` — a *different* file from `test/threadline/operator_surface/coverage_doc_contract_test.exs`; no mutation-control content on any assertion touched by this plan).

`grep -rl -e operator_surface_doc_contract -e coverage_doc_contract -e policy_show_doc_contract .planning/milestones/v1.43-phases/`: 30+ files hit, but every hit is either (a) an incidental substring match on `ci_coverage_doc_contract_test.exs` (a different, unrelated file) or (b) a generic PR-files-changed listing or cross-phase pattern-reference with no mutation-control language naming an assertion this plan cuts. No hit names a mutation control defending a cut assertion.

Governed-absence wording (per 230-RESEARCH.md): absence of a mutation-control mention in the v1.43 audit is not proof that no control exists; the KEEP verdicts above rest on live derivation (source reads, real task runs, structural/security invariants), not on the absence check alone.

### Wall clock before and after

REBAL_AFTER: 77cb5c861a186bfa7919950a08abd0e4705fbbb3 (Task 2's commit — the after figures below were measured at this tree state; the CONTRIBUTING.md rubric addition that follows touches no test file)

**Before** (three runs at BASE, repeated from the SUITE-04 rebalance section above):

| Run | real (s) | ExUnit summary |
|---|---|---|
| 1 | 137.44 | Finished in 136.8 seconds — 32 properties, 2768 tests, 0 failures, 3 excluded |
| 2 | 138.38 | Finished in 137.7 seconds — 32 properties, 2768 tests, 0 failures, 3 excluded |
| 3 | 134.07 | Finished in 133.5 seconds — 32 properties, 2768 tests, 0 failures, 3 excluded |

Median real: 137.44s. Median Finished-in: 136.8s.

**After** (three runs at REBAL_AFTER):

| Run | real (s) | ExUnit summary |
|---|---|---|
| 1 | 133.60 | Finished in 133.1 seconds — 32 properties, 2734 tests, 0 failures, 3 excluded |
| 2 | 151.59 | Finished in 151.0 seconds — 32 properties, 2734 tests, 0 failures, 3 excluded |
| 3 | 172.11 | Finished in 171.2 seconds — 32 properties, 2734 tests, 0 failures, 3 excluded |

Median real: 151.59s. Median Finished-in: 151.0s. All three runs: 0 failures.

**Test-count delta:** 2768 -> 2734 = 34 fewer tests, exactly matching the 34 deleted tests from this plan's cuts (17 from the two whole-file cuts in Task 1 — 6 + 11 — plus 17 from the three line-item trims in Task 2 — 9 + 7 + 1).

**Wall-clock delta:** median real went from 137.44s to 151.59s (+14.15s), despite removing 34 tests. This sits inside the repo's documented local-noise floor: phase 224's evidence doc recorded head-vs-base swings of about 52 and 56 seconds in opposite directions from unrelated concurrent processes on the same machine, an order of magnitude larger than this +14.15s delta. The after-run-3 figure (172.11s) in particular reflects that noise, not a real regression from removing tests. local, noisy: this local figure is read as context, not as the release gate — SUITE-06 (a later plan in this phase) uses CI step-sum wall clock as the actual comparator, per D-06/D-08.

### ci-required roster

13 jobs, unchanged before and after this plan's cuts:

```
verify-format, verify-credo, verify-dialyzer, verify-compile-no-optional,
verify-test, verify-hex-evaluator, verify-example-browser, verify-capture,
verify-pgbouncer-topology, verify-release-shape, verify-bump-rehearsal,
verify-deps-audit, verify-repo-hygiene
```

`diff /tmp/230-ci-required-before.txt /tmp/230-ci-required-after.txt`: empty. `git diff BASE -- .github/workflows/`: empty. `test/threadline/ci_topology_contract_test.exs`: green (part of the 278/0 run above).

### Rubric recorded

`CONTRIBUTING.md` gained `### Writing a doc-contract or guard test` as the last subsection of `## Deterministic tests (no flakes)`, immediately before `## Local-only critic (verify.ui_critique)`. It states the three KEEP criteria, the CUT shape, and the one-sentence-moduledoc convention, in plain prose with no new tooling. Committed in the plan-metadata commit that follows this evidence entry.
