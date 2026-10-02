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

## SUITE-06 net suite time

### Gate (D-06)

**PASS** iff all three of the following hold on one fresh `ci.yml` run on the
final pre-landing tree:

1. All three lanes (`min`, `current`, `latest`) report `Build cache: hit`
   (from `ci-job-timing.py <run> --cache-state`).
2. The summed per-lane `Run tests` step seconds is **≤ 930.6** (SUITE-01's
   846 s + 10%).
3. Each lane's `Run tests` seconds is **≤** its own SUITE-01 figure: min ≤
   288, current ≤ 291, latest ≤ 267.

A value exactly equal to a ceiling (930.6, or a lane's own SUITE-01 figure)
**passes** — these are `≤` comparisons, not `<`.

**INVALID, not PASS/FAIL:** a lane with no `Run tests` step, no partition
report, or a `Build cache: miss` makes the comparison **INVALID**. An
INVALID result blocks landing exactly like a FAIL (D-10) — it is never
silently treated as a pass. A phase that published no CI run at all is
disclosed in the milestone table as local-only, never back-filled or
interpolated.

This formula is fixed here, before plan 04 takes the one fresh measurement
it judges.

### Method proof

**Reproducing SUITE-01 (run 36730596489, the pinned baseline):**

```
## run 36730596489

| Lane | Job seconds | Proxy (min) | Run tests seconds | Build cache |
|---|---|---|---|---|
| min | 340 | 6 | 288 | hit |
| current | 476 | 8 | 291 | hit |
| latest | 321 | 6 | 267 | hit |
| **total** | | **20** | |

Computed from `gh api repos/szTheory/threadline/actions/runs/36730596489/jobs --paginate`, run 36730596489.
```

`python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py 36730596489 --cache-state` reproduces the SUITE-01 lane figures exactly: 288 / 291 / 267 (sum 846), all three lanes `Build cache: hit`. The comparator is proven against the figure it must judge future runs against.

**228's after-run (37018812221), same tool, single-run mode:**

```
## run 37018812221

| Lane | Job seconds | Proxy (min) | Run tests seconds | Build cache |
|---|---|---|---|---|
| min | 234 | 4 | 182 | hit |
| current | 335 | 6 | 142 | hit |
| latest | 220 | 4 | 173 | hit |
| **total** | | **14** | |

Computed from `gh api repos/szTheory/threadline/actions/runs/37018812221/jobs --paginate`, run 37018812221.
```

`ci-job-timing.py --compare` needs two or more after runs. This phase cites
one existing after-run (228's) purely to prove the partition-extraction
method, not to gate on it — following 227's INSUFFICIENT fallback: single-run
mode on one run id reads the same per-lane figures `--compare` would, so this
method-proof uses one single-run invocation rather than a two-run compare.

**Partition report per lane, run 37018812221** (read-only `gh api
repos/szTheory/threadline/actions/jobs/<job-id>/logs --allow-escape-sequences`,
ANSI-stripped, lines between `ci-test-partitions: partition report` and the
`| total |` row):

`min` (job 110876289440):

| Partition | Exit | Seconds | Counts |
|---|---|---|---|
| 1 | 0 | 118 | 677 tests, 0 failures |
| 2 | 0 | 135 | 620 tests, 0 failures |
| 3 | 0 | 168 | 640 tests, 0 failures |
| 4 | 0 | 180 | 765 tests, 0 failures |
| total | - | 181 | - |

Per-partition Seconds sum (min lane): 118 + 135 + 168 + 180 = **601 s**

`current` (job 110876289478):

| Partition | Exit | Seconds | Counts |
|---|---|---|---|
| 1 | 0 | 112 | 677 tests, 0 failures |
| 2 | 0 | 110 | 620 tests, 0 failures |
| 3 | 0 | 125 | 640 tests, 0 failures |
| 4 | 0 | 141 | 765 tests, 0 failures |
| total | - | 142 | - |

Per-partition Seconds sum (current lane): 112 + 110 + 125 + 141 = **488 s**

`latest` (job 110876289375):

| Partition | Exit | Seconds | Counts |
|---|---|---|---|
| 1 | 0 | 103 | 675 tests, 0 failures |
| 2 | 0 | 122 | 620 tests, 0 failures |
| 3 | 0 | 159 | 639 tests, 0 failures |
| 4 | 0 | 171 | 765 tests, 0 failures |
| total | - | 172 | - |

Per-partition Seconds sum (latest lane): 103 + 122 + 159 + 171 = **555 s**

**Total serial-equivalent work across all three lanes, run 37018812221:**
601 + 488 + 555 = **1644 s**.

Each lane's per-partition-Seconds sum (601 / 488 / 555) closely tracks that
lane's step-level `Run tests` seconds (182 / 142 / 173) but is not identical
— the per-partition Seconds figure includes each partition's own Mix boot
time, so it slightly overstates pure ExUnit run time. ExUnit's own "Finished
in" line is only printed to the partition log on a failed partition (the
runner suppresses it on a clean partition to keep output small), so the
Seconds column — already exposed by `bin/ci-test-partitions`' own `report()`
step-summary table — is the serial-equivalent figure this evidence uses, per
the Don't Hand-Roll decision (D-06): no echo was added to the runner.

**No runner change:** `git diff 4a04e4f38ea5d36f313e1b1e7ffdfbdd4fc799dc -- bin/` is empty (BASE sha recorded by plan 01's `## SUITE-04 rebalance` section above) — this plan reads `bin/ci-test-partitions`' existing output only.

### Milestone suite-time table (D-09)

Every numeric cell below is copied verbatim from the cited phase's own
published evidence (never recomputed or interpolated). "Local before/after"
is each phase's own local `mix test` median (or, where a phase recorded
only a 2-run swing check rather than a 3-run median, both figures with that
noted). "CI before/after" is the `Run tests` step-seconds sum across the
three lanes (min + current + latest), taken from each phase's own cited run
via `ci-job-timing.py --cache-state`; the proxy-minute figure is the printed
total proxy column. "Serial-equivalent work Δ" is the per-phase change in
the sum of all 12 (3 lanes x 4 partitions) per-partition `Seconds` figures
(or, for 224/225's starting point, the unpartitioned per-lane step seconds,
which is the same quantity before partitioning existed).

| Phase | Local before (median s) | Local after (median s) | CI before (step sum s / proxy min) | CI after (step sum s / proxy min) | Δ CI % | Serial-equivalent work Δ | Run ID(s) | Source doc |
|---|---|---|---|---|---|---|---|---|
| 224 | 231.0s / 243.2s (2-run swing check, not a 3-run median) | 282.5s / 187.7s (2-run swing check, not a 3-run median) | local-only (no CI run this phase) | local-only (no CI run this phase) | n/a | not exposed (no partitioned CI run this phase; pre-partition SUITE-01 serial total 846s, run 36730596489, is the starting reference 225's Δ below is measured against) | 36730596489 (cited, pre-224 baseline) | `224-EVIDENCE.md` "Suite wall clock (SUITE-06)" |
| 225 | 137.0s | 136.5s (phase head, post SUITE-02 gate) | 846 / 20 | 483 / 14 | -42.9% | 36730596489->36808706517: 846s -> 1588s (+742s). Attributable to the partitioning mechanism's own per-partition Mix-boot/compile overhead (4 partitions x 3 lanes each re-boot/compile), not test growth — suite size (~2588 tests) is essentially unchanged from SUITE-01. This is the one-time architectural cost of switching to in-job partitioned testing (D-01..D-12). | 36730596489 (before), 36808706517 (after, cache hit) | `225-EVIDENCE.md` "SUITE-06 before and after" |
| 226 | 226.5s | 144.9s | 430 / 12 | 456 / 14 | +6.1% | 1588s -> 1508s (-80s). Despite pure-property-test growth this phase added (~2588 -> 2649 tests), the serial-equivalent total decreased in this run, most likely from partition-weight rebalancing and ordinary run-to-run variance on shared GitHub-hosted runners, not from any reduction in test content. Property-test growth was a deliberate milestone goal (see test-count column); stated plainly, not re-baselined and not called noise. | 36820084560 (before), 36887218675 (after) | `226-EVIDENCE.md` "SC-5 wall clock before and after" |
| 227 | 133.1s | 128.9s | 524 / 14 | 491 / 14 | -6.3% | 1508s -> 1643s (+135s). Attributable to the three new DB-backed property tests this phase added (~2649 -> 2672 tests). | 36903609149 (before), 36929234558 (after) | `227-EVIDENCE.md` "SC-5 wall clock before and after" |
| 228 | 213.7s | 219.0s | 491 / 14 | 497 / 14 | +1.2% | 1643s -> 1644s (+1s). Attributable to the telemetry tests this phase added (~2672 -> 2702 tests); negligible serial-equivalent cost for this phase's added coverage. | 36929234558 (before), 37018812221 (after) | `228-EVIDENCE.md` "SC-5 wall clock before and after" |
| 229 | 186.2s | 171.9s | local-only (no CI run this phase) | local-only (no CI run this phase) | n/a | not exposed (no partitioned CI run this phase; local-only) | — | `229-adopter-api-and-health-additions/evidence/SC5-wallclock.md` |
| 230 | 137.44s (BASE, SUITE-04 rebalance before) | 151.59s (REBAL_AFTER) | pending: plan 04 fresh pre-landing run | pending: plan 04 fresh pre-landing run | pending | pending: plan 04 fresh pre-landing run (34 fewer tests from the SUITE-04 rebalance cuts should trend this down; attribution: 230 rebalance cuts) | — | `230-EVIDENCE.md` "SUITE-04 rebalance" / "Wall clock before and after" (this phase, plan 01) |
| SUITE-06 verdict | — | — | pending: plan 04 fresh pre-landing run | pending: plan 04 fresh pre-landing run | pending | — | — | `230-EVIDENCE.md` (plan 04 fills this row) |

### Serial-equivalent work (D-07)

`bin/ci-test-partitions` runs its partitions **concurrently inside** each
lane job, so a lane's `Run tests` step wall-clock time (the D-06 gate
figure) does not reflect how much total test work ran — it reflects only
the slowest partition in that lane. This section discloses the actual
summed work, honestly, with per-phase attribution, and is never used to
gate the release (D-06 remains wall clock only).

Method: for each partitioned after-run cited above, `gh api
repos/szTheory/threadline/actions/jobs/<job-id>/logs --allow-escape-sequences`
per lane job (read-only), ANSI-stripped, summing the `Seconds` column of
`bin/ci-test-partitions`' own `report()` table (already exposed in every
green run's step summary and log — no echo was added to the runner, per
the Don't Hand-Roll decision D-06).

| Transition | Total serial-equivalent (sum of all lanes' partition Seconds) | Δ | Attribution |
|---|---|---|---|
| SUITE-01 (pre-partition, serial) -> Phase 225 (run 36808706517) | 846s -> 1588s | +742s | Partitioning's own per-partition Mix-boot/compile overhead (D-01..D-12), not test growth |
| Phase 225 -> Phase 226 (run 36887218675) | 1588s -> 1508s | -80s | Pure property-test growth (226) landed, but partition-weight rebalancing and shared-runner variance dominated this particular run; not re-baselined, not called noise |
| Phase 226 -> Phase 227 (run 36929234558) | 1508s -> 1643s | +135s | DB-backed property tests (227) |
| Phase 227 -> Phase 228 (run 37018812221) | 1643s -> 1644s | +1s | Telemetry tests (228); negligible |
| Phase 228 -> Phase 230 | 1644s -> pending | pending | Plan 04's fresh pre-landing run; expected to trend down from the SUITE-04 rebalance's 34-test cut (230), offset by whatever 229's adopter-API/health tests added (229 published no CI run, so 229's own serial-equivalent contribution is not exposed — see its row above) |

Per-lane partition-Seconds sums behind each total above:

- 225 (run 36808706517): min 583s (111+125+168+179), current 491s (102+101+141+147), latest 514s (99+119+142+154)
- 226 (run 36887218675): min 477s (96+109+130+142), current 488s (106+112+128+142), latest 543s (103+120+152+168)
- 227 (run 36929234558): min 575s (110+127+163+175), current 469s (106+108+123+132), latest 599s (120+135+164+180)
- 228 (run 37018812221): min 601s (118+135+168+180), current 488s (112+110+125+141), latest 555s (103+122+159+171) — matches the Task 1 Method proof section above

No new timing script was written; all figures above come from `ci-job-timing.py --cache-state` and `bin/ci-test-partitions`' existing partition-report table (D-06 Don't Hand-Roll).

### Local context (D-08)

`git diff --quiet 77cb5c861a186bfa7919950a08abd0e4705fbbb3 HEAD -- test lib config mix.exs mix.lock` holds at this plan's measurement point (exit 0, no diff) — nothing under `test/`, `lib/`, `config/`, `mix.exs` or `mix.lock` has changed since plan 01's REBAL_AFTER commit. Per D-08, this plan reuses plan 01's after-figure rather than re-measuring: **median 151.59s** (three sequential `mix test` runs at `77cb5c86`, see plan 01's `### Wall clock before and after` section above for the full per-run table).

Against SUITE-01's local baseline of **137.0s** (median of three `mix test` runs at the milestone base, `225-BASELINE.md`), this is a **+14.59s** delta. Per 230-01's own finding (restated here per the repo's standard noise-floor caveat): this machine's documented local-noise floor is approximately 52-56s (224-EVIDENCE.md recorded head-vs-base swings of that size from unrelated concurrent processes), an order of magnitude larger than this delta, so it is read as context, not as a regression. SUITE-06's real release comparator is the CI step-sum wall clock in the milestone table above, measured on dedicated single-tenant runners, not this local figure (D-06/D-08).

`mix verify.test_partitioned` (the same partitioned-CI code path CI runs, as a **balance sanity check only** — never a SUITE-06 comparator) at the current tree:

| Partition | Exit | Seconds | Counts |
|---|---|---|---|
| 1 | 0 | 49 | 712 tests, 0 failures |
| 2 | 0 | 61 | 743 tests, 0 failures |
| 3 | 0 | 56 | 599 tests, 0 failures |
| 4 | 0 | 47 | 680 tests, 0 failures |
| total | - | 62 | - |

The four partitions are balanced within 49-61s (a ~12s spread across 4 partitions), confirming `test/partition_weights.txt`'s weight removal in plan 01 (2 dead lines for the deleted files) did not introduce a skew.

## Pre-land gate

### Release readiness

Commit `73360d72` dates the 0.12.0 CHANGELOG entry and adds the 0.11.x -> 0.12.x upgrade-path coverage (D-16 step 3).

- `grep -n '^## ' CHANGELOG.md | head -3` shows, in order: `## Unreleased — highlights`, `## [0.12.0] - 2026-10-02`, `## [0.11.2] - 2026-09-29`.
- The three Breaking changes entries under `## [0.12.0]` each carry a `Fix:` sentence (D-13): the non-list `exclude:`/`mask:`/`except_columns:` entry ("Fix: wrap the column name in a list..."), the operator-surface actor-ref telemetry entry ("Fix: remove those keys from your handler's pattern matches..."), and the health-checked-error metadata entry ("Fix: match `%{exception: mod}`..."). `awk '/^## \[0\.12\.0\]/{f=1;next} /^## /{f=0} f' CHANGELOG.md | grep -c 'Fix:'` reports 3.
- `guides/upgrade-path.md` gained the `0.11.x → 0.12.x` table row (`### At a glance, per minor`) and the matching bullet (`### Upgrade by Threadline minor`), each restating only the CHANGELOG's three Fix lines, plus an extended opening-narrative sentence naming 0.11.0 and 0.12.0. `grep -c '0.11.x → 0.12.x' guides/upgrade-path.md` reports 2.
- No `guides/upgrading-to-0.12.md` was created (D-13): `test ! -e guides/upgrading-to-0.12.md` exits 0.
- `mix test test/threadline/changelog_contract_test.exs test/threadline/version_truth_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/guide_graph_contract_test.exs` — 55 tests, 0 failures.
- `bin/verify-release-shape` — `Release shape OK for version 0.11.2` (current @version; the rehearsal below proves the 0.12.0 shape separately).
- `mix verify.bump_rehearsal`, run against commit `73360d72` (after the CHANGELOG/upgrade-path commit landed — the rehearsal clones HEAD, so it must run post-commit to see real content), printed both "nothing synthesised" lines verbatim:
  - `CHANGELOG.md already carries a heading for 0.12.0 — nothing synthesised`
  - `upgrade-path.md already covers 0.11.x -> 0.12.x — nothing synthesised`
  The rehearsal's own gates (35 doc-contract test files: 277 tests/0 failures; changelog contract: 9 tests/0 failures; `mix verify.release`: `Release shape OK for version 0.12.0`, 42 tests/0 failures) all passed at the rehearsed 0.12.0 state, and the real working tree was confirmed byte-identical afterward (30 files checksummed, no scratch branch or worktree survived).

**Deviation note:** the plan's task-1 action lists "run verify commands, then commit" in that order; `mix verify.bump_rehearsal` clones `HEAD`, so running it before the content commit exists only sees the prior tree and (correctly) synthesises stand-ins. The content was committed first (`73360d72`, CHANGELOG.md + guides/upgrade-path.md only), then the rehearsal was re-run against that commit to get a real "nothing synthesised" proof — no code or test behavior changed, this is a verification-ordering fix (Rule 3).

### SC5 ID sweep

Command: `grep -rnE '\b([Pp]hase|[Pp]lan)[ _-]?[0-9]+|\bD-[0-9]{2,}\b|\b(T-)?[0-9]{2,3}-[0-9]{2}\b|\b(CAPT|PROP|TELE|QRY|HLTH|SUITE|REL|WR|IN|CR)-[0-9]{2}\b|\bv1\.4[2-4]\b' lib guides` plus the same pattern over `awk '/^## \[0\.12\.0\]/{f=1;next} /^## /{f=0} f' CHANGELOG.md`.

- **Hit count before:** 45 lines (checked out at `8e77e244`, the commit immediately before this task's edits) — 9 real ID tokens + 36 date literals (`~U[...]`, `"2026-...-..."`, bare `2026-MM-DD`/`2024-MM-DD` strings).
- **Hit count after:** 36 lines — the same 36 date literals, 0 ID tokens.
- **CHANGELOG 0.12.0 block:** 0 hits before and after (the block never carried an ID).

Scrubbed sites (file:line, token removed — each edit touched only the comment/`@doc` text, rewording minimally to keep the sentence readable):

| File:Line | Token removed |
|---|---|
| `lib/threadline/health.ex:177` | `(HLTH-02)` |
| `lib/threadline/health/coverage_schemas.ex:55` | `(HLTH-02)` |
| `lib/threadline/operator_surface/ui/page.ex:157` | `mitigates T-175-09` (phrase removed, "below the cap" clause kept) |
| `lib/threadline/operator_surface/stress_fixtures.ex:100` | `the 177-05 group precedent` (reworded to "no orphaned reserved id): each page subject...") |
| `lib/threadline/operator_surface/live/transaction_live.ex:404` | `(T-211-14)` |
| `lib/threadline/operator_surface/live/evidence_live.ex:77` | `196-06, ` (kept `signal-to-chrome`) |
| `lib/threadline/operator_surface/live/evidence_live.ex:121` | `196-05, ` (kept `signal-to-chrome`) |
| `lib/threadline/operator_surface/live/evidence_live.ex:145` | `196-06, ` (kept `signal-to-chrome`) |
| `lib/threadline/operator_surface/live/coverage_live.ex:317` | `197-02, ` (kept `signal-to-chrome` and the full `"Selected schema readiness"` phrase) |

`git show --stat 8e77e244..HEAD -- lib` (the task 2 commit, recorded below) touches exactly these 7 files, 12 insertions / 12 deletions — one comment line changed per hit (evidence_live.ex carries 3 of the 9 scrubbed lines, so 3 of its 6 changed lines).

Reviewed exclusions (not phase or plan IDs):

| Pattern | Example | Reason | Pinning test |
|---|---|---|---|
| Date/timestamp literals | `~U[2026-01-01 00:00:00Z]`, `"2026-07-01"`, bare `2024-03-15` in `guides/incident-playbook.md` | Not an ID — a calendar date in a doctest, stress fixture, or worked example | N/A (not a planning ID; out of SC5 scope) |
| `STG-01` | `guides/adoption-pilot-backlog.md:19`, `production-checklist.md:5` | Legacy pre-v1.44 requirement-shaped contract anchor | `test/threadline/pgbouncer_topology_test.exs:36` names `STG-01 CI` |
| `STG-02`, `STG-03` | `guides/adoption-pilot-backlog.md:31,41` | Legacy pre-v1.44 requirement-shaped anchor | `git grep -n 'STG-0[23]' -- test` returns nothing — **unpinned, candidate for later cleanup** |
| `PERF-01`/`PERF-02`/`PERF-03` | `guides/performance.md:3-5` (HTML comment markers) | Legacy pre-v1.44 anchor | `test/threadline/performance_doc_contract_test.exs:14-16` asserts each `<!-- PERF-0N -->` marker |
| `IDX-02` | `guides/audit-indexing.md:3` | Legacy pre-v1.44 anchor | `test/threadline/audit_indexing_doc_contract_test.exs:11,14` asserts the `IDX-02-AUDIT-INDEXING` marker |
| `XPLO-03-API-ROUTING` | `guides/domain-reference.md:288` | Legacy pre-v1.44 anchor | `test/threadline/exploration_routing_doc_contract_test.exs:15` asserts this exact string |
| `CAP-10` | `lib/threadline/health.ex:109`, `guides/domain-reference.md:253` | Legacy pre-v1.44 anchor | `git grep -n 'CAP-10' -- test` returns nothing — **unpinned, candidate for later cleanup** |
| `CTX-05` | `lib/threadline/job.ex:6` | Legacy pre-v1.44 anchor | `test/threadline/job_test.exs:61` names a `"CTX-05: no process state"` describe block |
| `(v1.17)`, `(v1.10+)` | `guides/operator-surface.md:238`, `guides/domain-reference.md:284` | Guide section headings naming the Threadline Hex minor the section shipped in, not a v1.4x milestone/phase/plan ID; `v1.4[2-4]` in the sweep regex does not match these | N/A (version-history heading, not a milestone ID) |

`@banned_shapes` in `test/threadline/release_artifact_contract_test.exs` is necessary but not sufficient (230-RESEARCH.md "@banned_shapes ID-scan gap"): it scans only the Hex tarball, not tracked `lib/`/`guides/` source, and its regex does not cover the `HLTH-`/`T-`-prefixed shapes scrubbed here or the `v1.42`-`v1.44` range. This sweep is the source-tree complement; `release_artifact_contract_test.exs` remains the packaged-tarball complement, and neither alone would have caught all 9 hits.
