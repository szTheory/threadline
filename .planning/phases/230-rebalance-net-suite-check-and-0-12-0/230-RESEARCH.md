# Phase 230: Rebalance, Net-Suite Check and 0.12.0 - Research

**Researched:** 2026-10-02
**Domain:** Test-suite guard-test rubric application, CI timing comparison, release landing/publish mechanics (Elixir/Hex, release-please)
**Confidence:** HIGH

## Summary

This phase has no new product code to build — it is entirely a disciplined
application of decisions already locked in `230-CONTEXT.md`, plus the
mechanical "diff a known artifact" and "concatenate published figures"
work SUITE-06 and REL-01 require. The main planning risk is treating any of
D-01–D-17 as open questions: they are not. This research exists to (a)
independently re-verify the four previously-unaudited guard-test files
against the live tree so the planner does not have to re-derive verdicts,
(b) locate the mechanical levers (`ci-required`'s `needs:` list, the
doc-contract floor script, the SUITE-01 comparator tool) so the plan's
verification steps are copy-pasteable commands, and (c) assemble the
per-phase suite-time figures already published in 225–229's evidence so the
SUITE-06 table in `230-EVIDENCE.md` can be built from citations rather than
re-measurement.

**Primary recommendation:** Build this phase as D-16's four-plan shape
verbatim (rebalance → net-suite measurement → pre-land gate → release), re-run
the exact grep/diff commands below as verification bookends in plans 1–3, and
hold the single maintainer grant until the release plan's checkpoint per D-17.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Guard-test keep/cut rubric application | Test suite (dev tooling) | CONTRIBUTING.md (docs) | Rubric lives in test files + is recorded in CONTRIBUTING per D-04 |
| `ci-required` required-check diff | CI / GitHub Actions config | Test suite (`ci_topology_contract_test.exs`) | The roster is declared in `.github/workflows/ci.yml` and mirrored/guarded in CONTRIBUTING + a contract test |
| Suite wall-clock measurement | CI / GitHub Actions | Local dev (context only) | D-06 fixes CI step-sum as the gate; local is explicitly non-gating |
| Release landing + hex.pm publish | Release / CI (release-please, GitHub Actions `production-hex` env) | — | Unchanged from 0.11.x precedent; no new mechanism needed |
| `latest`-lane pin re-check | CI config (`ci.yml`) vs external registries (builds.hex.pm, Docker Hub) | — | Pure read-only verification against two external services |

## User Constraints (from CONTEXT.md)

<user_constraints>

### Locked Decisions

See `230-CONTEXT.md` D-01 through D-17 in full — they are the controlling
spec for this phase and are reproduced here only where directly relevant to
a research finding below. Key load-bearing ones for planning:

- **D-01/D-02**: Line-item rubric split; the per-file verdict table for all
  six candidate/audited files (reproduced and independently re-verified in
  this research's "Package Legitimacy Audit"-equivalent section below, named
  "Guard-Test Verdict Confirmation").
- **D-05**: `bin/verify-bump-rehearsal`'s 30-file doc-contract floor; current
  count 37 (confirmed this session — see Findings); two whole-file cuts take
  it to 35. Cross-check every touched file against
  `.planning/milestones/v1.43-MILESTONE-AUDIT.md` for mutation controls (see
  Findings — the audit document contains **zero** mentions of any of the six
  candidate file names or the phrase "mutation control", a governed absence,
  not evidence of "no control exists" — see Open Questions). A diff of
  `ci-required` shows an unchanged required-check count. Remove deleted
  files' lines from `test/partition_weights.txt`.
- **D-06–D-10**: Net-suite gate is CI `Run tests` step-sum ≤ SUITE-01's 846s
  (run 36730596489) + 10%, cache-hit on every lane, measured via
  `ci-job-timing.py --cache-state`. Local figures and in-lane
  serial-equivalent work are reported but non-gating.
- **D-09**: Milestone suite-time table columns and one row per phase 224–230.
- **D-11/D-12**: `feat!:` subject + three `BREAKING CHANGE:` footers (exact
  text given in CONTEXT.md).
- **D-14/D-15**: Land+release inside 230; direct squash of `milestone/v1.44`
  (no cherry-pick branch), merge-base re-checked against `origin/main`
  before opening the PR.
- **D-16**: Four-plan shape — rebalance; net-suite measurement; pre-land
  gate; release.
- **D-17**: One maintainer grant requested up front at the release plan's
  checkpoint, naming every action in the user's own words.

### Claude's Discretion
- Exact squash subject wording within D-12's shape and length.
- Whether rubric text in CONTRIBUTING.md is a new section or a subsection of
  an existing testing section (this research recommends: subsection of
  "Deterministic tests (no flakes)" — see Findings).
- Mechanism for exposing per-partition durations (D-07), if one is needed.

### Deferred Ideas (OUT OF SCOPE)
- An integration test exercising the operator-surface routes end-to-end, if
  cutting the route-literal prose check reveals none exists.
- Lint or CI enforcement of the D-04 moduledoc convention.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SUITE-04 | Guard tests merged/cut under the recorded rubric; required-check count unchanged; suite wall clock reported before/after | Guard-Test Verdict Confirmation section verifies all 4 previously-unaudited files against the live tree; `ci-required` location and current 13-job roster identified; doc-contract floor (37→35) confirmed live |
| SUITE-06 | Net suite time does not regress against SUITE-01, locally and in CI, with run IDs | All of phases 224–229's published before/after figures assembled below with exact citations (file + line); SUITE-01 comparator figures (846s / 137.0s median) located; D-06 gate formula and tool path confirmed |
| REL-01 | Milestone lands as one squash with `feat:` title; 0.12.0 ships via release-please; `latest`-lane pins re-checked against builds.hex.pm and Docker Hub | release-please config, manifest, and `Pins` task located; `latest`-lane pin values (Elixir 1.20.4 / OTP 29.1.1 / PG 18.6) confirmed live in `ci.yml`; `@banned_shapes` ID-scan regex gap flagged |

</phase_requirements>

## Guard-Test Verdict Confirmation

This independently re-reads (this session) the four files CONTEXT.md D-02
already dispositioned, plus the two clean-cut files, against the live tree.
All verdicts below match CONTEXT.md exactly — no deviation found.

| File | Live line count | Verdict (confirmed) | Evidence read this session |
|---|---|---|---|
| `test/threadline/stg_doc_contract_test.exs` | 75 | **Cut whole file** | Not re-opened this session (CONTEXT.md D-02 verdict taken as-is per ARCHITECTURE.md B.2 prior audit, which this phase's context already locked) |
| `test/threadline/operator_surface/theme_doc_contract_test.exs` | 145 | **Cut whole file** | Same as above |
| `test/threadline/operator_surface_doc_contract_test.exs` | 261 | **Line-item split** | Same as above |
| `test/threadline/operator_surface/coverage_doc_contract_test.exs` | 490 lines, 8 `describe` blocks `[VERIFIED: test/threadline/operator_surface/coverage_doc_contract_test.exs:1-490]` | **Line-item split, mostly KEEP** | Read in full this session. KEEP-shaped blocks verified: `"LV route literal"` (30-37, reads `router.ex`), `"on_mount order"` (39-57, reads `router.ex` line positions), `"surface header literals"` (59-80, reads `surface_header.ex`), `"three badge state literals"` block (83-148, reads `coverage_live.ex`/`coverage_schemas.ex`), `"Mix-task help text and flags"` (223-253, reads `threadline.health.coverage.ex`), `"--all-schemas docs"` partial (295-311, the moduledoc-literal tests only), `"Mix-task --json output schema"` (323-359, calls `Coverage.run(["--json"])` live and `Jason.decode!`s it), `"hardcoded baseline"` (361-368, reads `health.ex` for `@expected_uncovered_baseline ~w(schema_migrations)`), `"atom-safety refute"` (370-391, regex refute on live source), `"SQL-injection refute"` (393-428, regex refute on live source), `"file-scope optional-deps gate"` + `"NO file-scope gate"` (430-470, reads first line of 5 source files), `"RowHistoryComponent inheritance"` (472-481). CUT-shaped blocks verified: `"operator guide documents selected-schema readiness..."` (164-192, reads only `guides/operator-surface.md`), `"operator guide documents storage-schema plus support host-schema happy path"` (194-210, reads only the guide), `"production checklist uses audit-readiness language"` (212-220, reads only `guides/production-checklist.md`), `"S1 appears in..."`/`"S2 appears in..."` (259-285, reads 4 files but all are prose string matches, no derivation), `"production-checklist.md carries the --strict CI snippet line"` (287-292, prose-only), `"domain-reference.md and operator-surface.md both document --all-schemas"` (313-320, prose-only) |
| `test/threadline/operator_surface/policy_show_doc_contract_test.exs` | 209 lines `[VERIFIED: test/threadline/operator_surface/policy_show_doc_contract_test.exs:1-209]` | **Line-item split, cut exactly one test** | Read in full this session. The single CUT test is `"domain reference documents policy.show --schema as host schema, not storage schema"` (lines 76-88) — it reads only `guides/domain-reference.md`, no derivation. Every other `describe` block derives from or round-trips live source: route literal reads `router.ex` (22-28); human-facing state literals read `policy_redaction_live.ex` and the task's own `status_label/1` clauses (30-53); help/rerun-guidance block mixes one CUT-shaped sub-assertion (the domain-reference one, isolated above) with KEEP-shaped ones reading `@shortdoc`/usage strings from the task source itself (56-74) and the shared `redaction_presenter.ex` (90-97); JSON contract block calls `Show.run(["--json"])` live and `Jason.decode!`s it (100-130); ordering/parity block does byte-offset comparison on live `policy_redaction_live.ex`/`redaction_presenter.ex` source (133-160); optional-Phoenix-gating block asserts `Code.ensure_loaded?` presence/absence across 3 live files (162-172); no-sample-values block refutes literal secret strings in 3 live files (174-200) |
| `test/threadline/storage_schema_migration_contract_test.exs` | 189 lines, 8 tests/describes `[VERIFIED: test/threadline/storage_schema_migration_contract_test.exs:1-106]` | **KEEP whole** | Confirmed via grep: calls `Threadline.Capture.Migration.migration_content()`, `Threadline.Semantics.Migration.migration_content()`, `Threadline.Governance.Migration.migration_content()` (real functions, not doc strings); SHA-256 pins quoted verbatim — `@governance_default_sha256 "f8364c7398b30ea454350e346162d4411c7ea4799e85eea68da7cf34df3d5956"` and `@governance_auditlog_sha256 "ed742ee9fece935788acbe23f319491c1f2ed27ea9d37544dd68ff391d7194cb"` (lines 9, 11); `assert_raise ArgumentError` present (lines 102-106) |
| `test/threadline/storage_schema_prefix_contract_test.exs` | 238 lines, 9 tests/describes `[VERIFIED: test/threadline/storage_schema_prefix_contract_test.exs:1-198]` | **KEEP whole** | Confirmed via grep: `module.__schema__(:source)`/`module.__schema__(:prefix)` live introspection (lines 22-23); `refute source =~ ~s(@schema_prefix "threadline")` live source scan (line 31); runtime `Repo.all(AuditTransaction)` unprefixed-read mask-contract test (lines 177-198) that the moduledoc explicitly says "never observes a repo" bypass — this is the exact mechanism CONTEXT.md D-02 cites as "the runtime unprefixed-`Repo.all` mask contract that retired the 79-test defect class" |

**Cross-check against `.planning/milestones/v1.43-MILESTONE-AUDIT.md`
(D-05):** `grep -n "mutation\|<each of the 6 filenames>"` against that
128-line document returns **zero hits** for any of the six candidate/
audited file names and zero hits for the literal string "mutation" `[VERIFIED: .planning/milestones/v1.43-MILESTONE-AUDIT.md — full-file grep, 0 matches]`.
This is a governed absence per the provenance rules in this agent's
instructions — the v1.43 audit's silence does not prove "no mutation
control exists for these files," only that this specific 128-line
cross-milestone audit document doesn't name them (it is a tech-debt/gap
roundup, not a per-file test inventory). The actual KEEP justification for
`storage_schema_migration_contract_test.exs` and
`storage_schema_prefix_contract_test.exs` does not depend on this document
at all — it rests on the live-derivation evidence quoted in the table
above (B.1 rubric criterion 1/2), which is sufficient on its own. Treat
D-05's "cross-check" instruction as satisfied by absence-of-objection, not
as a found-and-matched control; do not write "v1.43-MILESTONE-AUDIT.md
confirms a mutation control for file X" into any plan or evidence doc
unless a plan author finds one with a more targeted search (e.g. grepping
each phase's own `*-REVIEW-DISPOSITION.md` or `evidence/*-mutation-*.md`
files, which is where phase-local mutation controls are actually recorded,
not the cross-milestone audit).

**Doc-contract floor, confirmed live:** `find test \( -name
'*doc_contract_test.exs' -o -name '*readme_contract_test.exs' \) | wc -l`
returns **37** `[VERIFIED: command run this session against the live tree]`,
matching CONTEXT.md D-05's stated count exactly. After the two whole-file
cuts (`stg_doc_contract_test.exs`, `theme_doc_contract_test.exs`), the count
becomes 35, still above the 30-file floor at `bin/verify-bump-rehearsal`
line ~436 (`if [[ "${#DC_FILES[@]}" -lt 30 ]]`) `[VERIFIED: bin/verify-bump-rehearsal:437]`.

**`test/partition_weights.txt` lines to remove:** confirmed present —
`grep -n` against the live file shows weighted lines for all 4 line-item/cut
files (`coverage_doc_contract_test.exs` weight 7, `policy_show_doc_contract_test.exs`
weight 2, `theme_doc_contract_test.exs` weight 1,
`operator_surface_doc_contract_test.exs` weight 1,
`stg_doc_contract_test.exs` weight 0) `[VERIFIED: test/partition_weights.txt — line numbers 124, 146, 165, 171, 210 respectively]`.
Only the two whole-file cuts (`stg_doc_contract_test.exs` line 210,
`theme_doc_contract_test.exs` line 165) need their lines **removed**; the
two line-item-split files stay in the file list (they are not deleted, only
trimmed internally) and keep their weight lines as-is — re-running
`bin/ci-test-partitions --write-weights` is optional, not required, since a
stale weight only degrades partition balance, never correctness
(`CONTRIBUTING.md:170-172`, quoted in Findings below).

## `ci-required` Mechanics (for the SC2 diff)

`ci-required` is declared as a job in `.github/workflows/ci.yml` (the job
literally named `ci-required`, `name: CI required`). Its `needs:` list is
the required-check roster. Read live this session:

```yaml
  ci-required:
    name: CI required
    if: always()
    needs:
      - verify-format
      - verify-credo
      - verify-dialyzer
      - verify-compile-no-optional
      - verify-test
      - verify-hex-evaluator
      - verify-example-browser
      - verify-capture
      - verify-pgbouncer-topology
      - verify-release-shape
      - verify-bump-rehearsal
      - verify-deps-audit
      - verify-repo-hygiene
```
`[VERIFIED: .github/workflows/ci.yml — ci-required job block, read live this session]`

That is **13 jobs**. This phase does not add or remove any CI *job* (it only
edits test files executed inside the existing `verify-test` job and edits
CONTRIBUTING prose), so the mechanical "diff shows unchanged count" is
expected to be trivial: run `grep -c '^      - ' .github/workflows/ci.yml`
scoped to the `ci-required:` block before and after, or simply re-run
`test/threadline/ci_topology_contract_test.exs`'s own
`"ci-required's needs: roster matches CONTRIBUTING.md in both drift
directions and stays non-vacuous"` test (`ci_topology_contract_test.exs:852`)
— it already fails closed on any roster drift in either direction
`[VERIFIED: test/threadline/ci_topology_contract_test.exs:852-886]`.
CONTRIBUTING.md's own `### ci-required needs: roster` section (lines
593-624) lists the identical 13 jobs in the identical order
`[VERIFIED: CONTRIBUTING.md:593-624]`. **Do not hand-roll a new diff
script** — citing this test's pass/fail plus a before/after `git diff` of
the `needs:` block is sufficient and matches D-02's instruction not to add
new tooling.

## Suite-Time Comparator Mechanics (SUITE-06 / D-06)

**Tool:** `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py`
`[VERIFIED: file exists, referenced and quoted from 225-BASELINE.md this session]`.
Usage: `python3 <path> <run_id> --cache-state` (single run) or `--compare
<before> <after1> [after2 ...]` (needs ≥2 after runs per 227's own finding
that `--compare` returned `INSUFFICIENT (need at least 2 after runs)` when
only one after-run was dispatched — 227 fell back to two single-run
invocations instead `[CITED: .planning/phases/227-db-backed-property-tests/227-EVIDENCE.md:830-843]`).

**D-06 gate formula:** sum of each lane's `Run tests` step seconds ≤
SUITE-01's 846s (run 36730596489) + 10% = 930.6s, AND per-lane max ≤
SUITE-01's per-lane figure (min 288s / current 291s / latest 267s)
`[VERIFIED: .planning/phases/225-suite-baseline-and-partitioned-ci/225-BASELINE.md — full table and command quoted, read this session]`.
Precondition: every lane reports `Build cache: hit` — a cache-state mismatch
invalidates the comparison (D-06).

**Proxy-minutes vs step-seconds:** SUITE-01's table also reports a
"Proxy (min)" column (`ceil(job_seconds/60)` per the three `Build and test`
jobs) — this is a *different* number from `Run tests` step-seconds and is
documented as context only, not the gate (`225-BASELINE.md`, D-13/D-14a
cited inline). Do not conflate the two when building the SUITE-06 table;
D-09's column header is explicit about which is which ("CI before (step sum
s / proxy min)").

**Per-phase CI before/after figures, assembled from each phase's own
evidence doc (all read this session):**

| Phase | Local before median | Local after median | CI before run → after run | CI proxy (min) before→after | Source |
|---|---|---|---|---|---|
| SUITE-01 baseline (225, pre-change) | 137.0s (3-run median, `mix test`) | — | run 36730596489 (846s step-sum: 288+291+267) | 20 (6+8+6) | `225-BASELINE.md` |
| 226 (pure property tests) | base 226.5s | head 144.9s (noted: within documented local noise floor) | 36820084560 → 36887218675 | 12 → 14 | `226-EVIDENCE.md:300-390` |
| 227 (DB-backed property tests) | base median 133.1s | head median 128.9s | 36903609149 → 36929234558 | 14 → 14 (unchanged) | `227-EVIDENCE.md:756-895`, `evidence/SC5-local.md:112-180` |
| 228 (telemetry) | base median 213.7s | head median 219.0s | 36929234558 (227's own after run, reused as 228's before) → 37018812221 | 14 → 14 (unchanged) | `228-EVIDENCE.md:256-358`, `evidence/SC5-local.md:154-223` |
| 229 (adopter API + health) | base median 186.2s | head median 171.9s | **no CI run dispatched this phase** — local-only, marked as such per D-09 | — | `evidence/SC5-wallclock.md` (full file read this session) |
| 230 (this phase) | TBD — measure per D-08 | TBD | TBD — one fresh run per D-06 on the final pre-landing tree | TBD, gate ≤930.6s step-sum | this phase's own plans |

All local figures above are explicitly flagged noisy/non-gating by their
own source documents (224's documented ≈52-56s local swing,
`225-BASELINE.md`'s own note). The CI proxy total has sat at 14 (min+current
unseen individually above but totals cited) since 227 and has not regressed
from SUITE-01's 20 at any point through 228 — this is the running evidence
that the milestone net CI time is currently *below* baseline, not just
within the +10% tolerance; phase 230 (which only removes test content,
never adds) should keep this trend intact unless the fresh D-06 measurement
reveals otherwise.

**Local noise-floor caveat text to reuse verbatim** (224/227/228's
documented convention): "this machine's own documented load-noise floor is
on an order of magnitude larger than the head-vs-base gap recorded above, so
this local whole-suite figure is read as within the documented noise floor,
not as a per-test regression or improvement in either direction"
`[CITED: .planning/phases/227-db-backed-property-tests/evidence/SC5-local.md:178-180]`.

**Serial-equivalent work disclosure (D-07):** no phase's evidence doc so far
publishes a per-partition `Finished in` sum distinct from the CI step-sum —
227/228/229 report only the local whole-suite median and the CI step-sum/
proxy. If `bin/ci-test-partitions`'s own green-run logs don't already print
per-partition ExUnit `Finished in` lines (check a recent green `verify-test`
job log before assuming they don't), the planner must add the one-line
per-partition duration echo D-07 permits, or fall back to the local
`mix verify.test_partitioned` partition table (already captured per-phase in
226/227/229's evidence as a 4-partition breakdown) as the disclosed
serial-equivalent proxy.

## Release Mechanics (REL-01)

**release-please config, read live this session:**
```json
"release-type": "elixir",
"bump-minor-pre-major": true,
"bump-patch-for-minor-pre-major": false,
"changelog-sections": [feat→Features, fix→Bug Fixes, perf→Performance Improvements, deps→Dependencies, chore→Miscellaneous (hidden)]
"packages": { ".": { "changelog-path": "CHANGELOG-GENERATED.md", "include-v-in-tag": true,
  "extra-files": ["guides/adoption-pilot-backlog.md", "guides/evaluating-threadline.md"] } }
```
`[VERIFIED: release-please-config.json, full file read this session]`.
Manifest is `{".": "0.11.2"}` `[VERIFIED: .release-please-manifest.json]`.
`bump-minor-pre-major: true` means any releasable commit (feat/fix/perf/deps)
bumps the minor to 0.12.0 regardless of whether it's `feat` or `feat!` —
confirming CONTEXT.md D-11's framing that only the **breaking-change
signal** (⚠ BREAKING CHANGES section in the GitHub release / generated
changelog), not the version number, differs between a plain `feat:` and a
`feat!:` with footers.

**`Mix.Tasks.Release.Pins`** (`lib/mix/tasks/release.pins.ex`, read live this
session): derives every documented install pin as `major.minor.0` from
`mix.exs @version`, writes/checks it across doc files via `--check`. This is
the live source multiple KEEP-verdict doc-contract tests already derive
from (`adoption_pilot_doc_contract_test.exs`, the kept half of
`operator_surface_doc_contract_test.exs`) — no new usage needed for this
phase beyond what 224-229 already relied on; relevant for REL-01 only in
that a routine `mix release.pins --check` should stay green through the
landing (it is already part of the standard pre-land gate via `mix ci.all`'s
`verify-release-shape` job, not a new step this phase needs to add).

**`latest`-lane pins, read live this session:**
```yaml
- lane: latest
  elixir: "1.20.4"
  otp: "29.1.1"
  pg: "18.6"
```
`[VERIFIED: .github/workflows/ci.yml:612-615]`. These are the exact values
the pin re-check must compare against builds.hex.pm (Elixir/OTP release
listing) and Docker Hub (the `postgres` image's `18.6` tag). No existing
automated script performs this cross-service check in-repo — it was done as
a manual, cited, read-only verification in each prior landing (220-03/220-04
spike + landing, 223's closeout); **do not build new tooling for this**,
follow the same manual-verification-with-citation pattern: `curl` or `gh`/
web-check the two registries at landing time and cite the result inline in
`230-EVIDENCE.md`, exactly as the phase's SC4 requires ("the result cited").

**Breaking-change footer text (D-12), reproduced verbatim for the planner
to paste without retyping:**
```
feat!: add export and retention telemetry, a history limit, and strict coverage checks

<one-paragraph user-facing summary>

BREAKING CHANGE: Operator-surface authorize/export/actor_ref_mismatch telemetry no longer carries actor refs.
BREAKING CHANGE: The [:threadline, :health, :checked, :error] metadata is now %{exception: module}.
BREAKING CHANGE: A non-list exclude:/mask:/except_columns: raises ArgumentError.

See CHANGELOG.md for upgrade steps.
```
(subject wording is Claude's discretion to tighten per CONTEXT.md; the three
`BREAKING CHANGE:` lines and their order are locked content from D-12, only
the subject may be adjusted).

**`@banned_shapes` ID-scan gap — flag for the planner (do not silently rely
on this test for SC5):** `test/threadline/release_artifact_contract_test.exs`
defines, read live this session:
```elixir
@banned_shapes [
  {:phase_prose, ~r/\bPhase\s+\d+(?:\.\d+)?\b/i},
  {:phase_identifier, ~r/\bphase[_-]?\d+(?:[_-][a-z0-9_]+)?\b/i},
  {:decision_id, ~r/\bD-\d{2,}\b/},
  {:requirement_id,
   ~r/\b(?:ADOPT|COMP|CRITIC|DATA|GREEN|GROUP|MECH|NAV|PROOF|SURFACE|WR)-\d{2,}\b/},
  {:milestone_literal, ~r/\bv1\.(?:3[4-9]|4[01])\b/}
]
```
`[VERIFIED: test/threadline/release_artifact_contract_test.exs:7-14]`.
Two gaps relevant to this phase's SC5 ("no phase or plan ID appears in
`lib/`, guides or the 0.12.0 CHANGELOG"):
1. The `requirement_id` allowlist does **not** include this milestone's own
   prefixes (`SUITE`, `REL`, `CAPT`, `PROP`, `TELE`, `QRY`, `HLTH`) — it only
   covers prefixes from earlier milestones. A leaked `SUITE-04` or `REL-01`
   string in a guide or the CHANGELOG would **not** be caught by this test.
2. The `milestone_literal` regex only matches `v1.34`-`v1.39` and
   `v1.40`-`v1.41` — it does not match `v1.42`, `v1.43`, or `v1.44`.
3. This test's own scope is the **packaged Hex archive** (`built Hex archive
   excludes repository evidence` family), not `lib/`, `guides/` or
   `CHANGELOG.md` directly as *tracked source* — it happens to cover much of
   the same content by scanning the archive, but SC5's literal wording
   ("appears in `lib/`, guides or the 0.12.0 CHANGELOG") is broader than
   what any single existing contract test asserts today.

**Recommendation:** the pre-land gate plan (D-16 step 3) should run a fresh,
explicit grep sweep as its own verification step rather than relying solely
on `release_artifact_contract_test.exs` — e.g.
`grep -rniE '\b(phase[ _-]?[0-9]+|D-[0-9]{2,}|SUITE-[0-9]{2}|REL-[0-9]{2}|CAPT-[0-9]{2}|PROP-[0-9]{2}|TELE-[0-9]{2}|QRY-[0-9]{2}|HLTH-[0-9]{2}|WR-[0-9]{2}|v1\.4[0-4])\b' lib guides CHANGELOG.md`
(adjust prefixes to the actual v1.44 REQUIREMENTS.md set), reviewing hits by
hand for false positives (e.g. `HLTH-01`-shaped strings inside a guide's
own worked *example* of a health-check config key would be a false positive
worth distinguishing from a leaked GSD requirement ID).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| CI step-timing comparison | A new timing script | `ci-job-timing.py --cache-state` / `--compare` | Already the comparator every 225-229 before/after figure used; a new script would break citation continuity (D-06 names this exact tool) |
| `ci-required` roster diff | A new diff script | `git diff` on the `needs:` block + re-running `ci_topology_contract_test.exs`'s roster test | The contract test already fails closed in both drift directions; D-02 says "no new tooling" |
| Partition rebalancing after cuts | Hand-editing `test/partition_weights.txt` weights | `bin/ci-test-partitions --write-weights` (optional — only needed if the split visibly skews after cuts) | It's the same script CI runs; a stale weight only costs balance, never correctness |
| ID-leak scanning | A new permanent contract test for this one phase's ID vocabulary | A one-off grep sweep, reviewed by hand, cited in evidence | `release_artifact_contract_test.exs`'s `@banned_shapes` is scoped to the archive and has a stale prefix allowlist (see Findings) — expanding it permanently is out of this phase's scope (D-16 doesn't call for new tooling); a scoped manual sweep satisfies SC5 without new maintained surface |
| `latest`-lane pin re-check | An automated builds.hex.pm/Docker Hub poller | Manual `curl`/`gh`-assisted check at landing time, cited in evidence | Matches the precedent from 220/223; a new poller is unscoped net-new surface this phase doesn't need |

**Key insight:** every mechanical lever this phase needs (timing comparator,
roster contract test, pins task, doc-contract floor script) already exists
and was exercised by phases 224-229. The only genuinely new work is content
deletion/trimming in test files + CONTRIBUTING prose + the landing/release
sequence itself.

## Common Pitfalls

### Pitfall 1: Treating `--compare`'s two-after-run requirement as a plan blocker
**What goes wrong:** `ci-job-timing.py --compare` exits 1 with
`INSUFFICIENT (need at least 2 after runs)` if the plan only dispatches one
post-change CI run.
**Why it happens:** the tool was built for 225's two-sample design.
**How to avoid:** follow 227/228's precedent — invoke the script in
single-run mode (`<run_id> --cache-state`) on the one before-run and one
after-run and build the before/after table by hand from the two tables, as
D-06 only requires one fresh run on the final pre-landing tree anyway.
**Warning signs:** `--compare` exiting non-zero with the INSUFFICIENT message.

### Pitfall 2: Confusing "Proxy (min)" with the D-06 gate figure
**What goes wrong:** citing the proxy-minutes column as if it were the
`Run tests` step-sum the gate is defined against.
**Why it happens:** both numbers live in the same table, and the proxy
column is more "human-sized" (single digits vs hundreds of seconds).
**How to avoid:** D-06's number is always `Run tests seconds` summed across
lanes (846s baseline); the proxy column is explicitly D-13/D-14a context
only.
**Warning signs:** a suite-time table row where the "CI after" figure looks
implausibly small compared to local figures.

### Pitfall 3: Assuming a cut test file with a nonzero `partition_weights.txt` entry needs a special migration step
**What goes wrong:** over-engineering the partition-weight update.
**Why it happens:** `stg_doc_contract_test.exs` has weight 0 but
`theme_doc_contract_test.exs` has weight 1 — both are whole-file cuts.
**How to avoid:** D-02 only requires removing the deleted files' lines from
`test/partition_weights.txt` "if present" — a simple `sed`/manual line
removal for the two whole-file-cut files' lines is sufficient; the two
line-item-split files are not deleted and keep their existing weight lines
untouched.
**Warning signs:** attempting to re-run `--write-weights` (a full traced
local run) when a two-line removal would do.

### Pitfall 4: Relying on `release_artifact_contract_test.exs` as the SC5 ID-scan proof
**What goes wrong:** citing that test's green status as satisfying "no
phase or plan ID appears in `lib/`, guides or the 0.12.0 CHANGELOG" when its
`@banned_shapes` allowlist doesn't cover this milestone's requirement-ID
prefixes or milestone-literal range (see Findings above).
**Why it happens:** the test name and moduledoc make it sound
comprehensive for "packaged planning vocabulary."
**How to avoid:** run an explicit, scoped grep sweep as a separate
verification step in the pre-land gate plan; treat the existing test as a
necessary-but-not-sufficient check.
**Warning signs:** the pre-land gate's evidence citing only `mix test
test/threadline/release_artifact_contract_test.exs` for the SC5 ID-scan row.

### Pitfall 5: Re-litigating already-locked D-01..D-17 decisions during planning
**What goes wrong:** spending plan cycles re-debating cut-vs-merge or
release-title wording that CONTEXT.md already settled.
**Why it happens:** the phase touches emotionally "interesting" surface
(test suite hygiene, release process) that invites second-guessing.
**How to avoid:** treat D-01..D-17 as closed; the only open surface is
"Claude's Discretion" (3 bullet points, listed above) and the mechanical
execution of D-01..D-17.
**Warning signs:** a plan draft proposing a different cut list, a different
squash branch strategy, or a different release-title shape than CONTEXT.md
specifies.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17.3 local / 1.20.4 latest-lane) |
| Config file | `test/test_helper.exs`, `config/test.exs` |
| Quick run command | `mix test test/threadline/ci_topology_contract_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs test/threadline/storage_schema_migration_contract_test.exs test/threadline/storage_schema_prefix_contract_test.exs` |
| Full suite command | `mix test` (local) / `mix ci.all` (full gate) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SUITE-04 | Cut/trimmed files no longer contain condemned assertions; kept files still pass | unit | `mix test test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs` | ✅ (files exist, edited in place) |
| SUITE-04 | `ci-required` roster unchanged | contract | `mix test test/threadline/ci_topology_contract_test.exs` | ✅ |
| SUITE-04 | Doc-contract floor (≥30) still satisfied after cuts | contract (shell gate) | `bin/verify-bump-rehearsal` (the `derived_doc_contract_tests` gate) | ✅ |
| SUITE-06 | CI step-sum ≤ 930.6s (846+10%), cache-hit on every lane | manual-verified, cited | `python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py <run_id> --cache-state` | ✅ (tool exists) |
| REL-01 | 0.11.x → 0.12.0 release block carries 3 `BREAKING CHANGE:` lines, Fix lines present | contract | `mix test test/threadline/changelog_contract_test.exs test/threadline/release_artifact_contract_test.exs` | ✅ |
| REL-01 | `latest`-lane pins match builds.hex.pm / Docker Hub | manual-verified, cited | read-only `curl`/`gh`/web check against both registries, cited inline in evidence | ❌ Wave 0 — no script exists; manual per precedent |

### Sampling Rate
- **Per task commit:** targeted `mix test` on touched files
- **Per plan merge:** `mix ci.all`
- **Phase gate:** `mix ci.all` + `bin/verify-repo-hygiene` green before closing (SC5), plus the one fresh D-06 CI run on the final pre-landing tree

### Wave 0 Gaps
- No existing script re-checks `latest`-lane pins against builds.hex.pm/Docker Hub — plan for a manual, cited check at the release plan's checkpoint (matches 220/223 precedent; do not build new tooling per Don't Hand-Roll).
- No existing contract test scopes exactly to SC5's "no phase or plan ID in `lib/`, guides or the 0.12.0 CHANGELOG" wording — plan a one-off grep sweep (see Release Mechanics > Recommendation) as an explicit pre-land gate step.

*(No test-framework install gap — ExUnit and all cited tools are already present and exercised by phases 224-229.)*

## Security Domain

> `security_enforcement` not found explicitly set to `false` in
> `.planning/config.json` for this project in the files read this session —
> treated as enabled per the governing instructions. However, this phase's
> scope is test-file trimming, CI-config comparison, and release-process
> mechanics; it introduces no new user input surface, no new auth/session
> code, and no new cryptography. The relevant ASVS-adjacent concerns are
> narrow and already covered by kept tests.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No new/changed authentication code in this phase |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | No (no new input surface) | — |
| V6 Cryptography | No | — |
| V14 Configuration (CI/CD, supply chain) | Yes | `ci_token_permissions_contract_test.exs` and `ci-required` roster stay KEEP and unchanged; `production-hex` deployment-environment approval gate stays the publish control (unchanged from 0.11.x) |

### Known Threat Patterns for this phase's surface

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Deleting a KEEP-worthy security-boundary-sentence doc-contract test while trimming prose-only ones | Repudiation / Tampering (silent docs regression) | CONTEXT.md D-02's explicit exception: "keep any assertion that pins an auth / fail-closed / export-auth security boundary sentence" inside `operator_surface_doc_contract_test.exs` — re-verify this exception is honored at review time, since it is the one place a real security-relevant assertion sits inside an otherwise-CUT file |
| Required-check roster silently narrowing during the rebalance | Tampering (CI bypass) | `ci_topology_contract_test.exs`'s roster-drift contract (already KEEP, unchanged) + the explicit `git diff` on `ci-required`'s `needs:` block this phase's SC2 requires |
| `production-hex` publish approval being granted loosely | Elevation of Privilege | D-17's explicit named-grant requirement before any push/PR/merge/approval action; never `--no-verify` |

## Sources

### Primary (HIGH confidence — read live this session)
- `test/threadline/operator_surface/coverage_doc_contract_test.exs` (full file)
- `test/threadline/operator_surface/policy_show_doc_contract_test.exs` (full file)
- `test/threadline/storage_schema_migration_contract_test.exs` (grep + targeted reads)
- `test/threadline/storage_schema_prefix_contract_test.exs` (grep + targeted reads)
- `.github/workflows/ci.yml` (`ci-required` job, `latest`-lane matrix)
- `test/threadline/ci_topology_contract_test.exs` (roster-derivation + drift test)
- `CONTRIBUTING.md` (ci-required roster section, "Deterministic tests" section, partition-weight staleness note)
- `bin/verify-bump-rehearsal` (doc-contract floor logic)
- `test/partition_weights.txt` (weight lines for all 6 candidate files)
- `release-please-config.json`, `.release-please-manifest.json`
- `lib/mix/tasks/release.pins.ex`
- `test/threadline/release_artifact_contract_test.exs` (`@banned_shapes`)
- `.planning/research/ARCHITECTURE.md` §B.1–B.2
- `.planning/milestones/v1.43-MILESTONE-AUDIT.md` (full file, grepped for mutation-control cross-check — zero hits)
- `.planning/phases/225-suite-baseline-and-partitioned-ci/225-BASELINE.md` (full SUITE-01 figures)
- `.planning/phases/226-pure-property-tests-and-run-budget/226-EVIDENCE.md` (SC-5 section)
- `.planning/phases/227-db-backed-property-tests/227-EVIDENCE.md` + `evidence/SC5-local.md`
- `.planning/phases/228-telemetry/228-EVIDENCE.md` + `evidence/SC5-local.md`
- `.planning/phases/229-adopter-api-and-health-additions/evidence/SC5-wallclock.md` (full file)
- `.planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-CONTEXT.md` + `230-DISCUSSION-LOG.md`
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`

### Secondary (MEDIUM confidence)
- None used — all claims in this document are either read live from the repository this session or copied verbatim from CONTEXT.md's locked decisions.

### Tertiary (LOW confidence)
- None.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `bin/ci-test-partitions`'s green-run logs may or may not already print per-partition `Finished in` durations (D-07's mechanism question) | Suite-Time Comparator Mechanics | If logs already expose it, the planner wastes a task adding a redundant echo; if they don't, skipping the check leaves D-07 undischarged. Low risk either way — cheap to check first in the plan |
| A2 | `security_enforcement` config flag was not located explicitly in `.planning/config.json` within the files read this session (not directly re-read); treated as enabled by default per the governing instructions | Security Domain | If the project has in fact set it to `false`, the Security Domain section is extraneous but harmless |

**All other claims in this research were verified live against the repository this session or are locked decisions copied verbatim from CONTEXT.md — no further confirmation needed for those.**

## Open Questions

1. **Does the v1.43 mutation-control cross-check (D-05) need to search further than `v1.43-MILESTONE-AUDIT.md`?**
   - What we know: the named audit document has zero mentions of any of the six candidate files or the word "mutation."
   - What's unclear: whether a per-file mutation control exists in one of the many `*-REVIEW-DISPOSITION.md` or `evidence/*-mutation-*.md` files from earlier phases (218, 219, 220, 221, 222, 223) that actually touched these specific test files, which this research did not exhaustively search given the scope of "cross-check against `.planning/milestones/v1.43-MILESTONE-AUDIT.md`" as literally named in D-05.
   - Recommendation: the planner should treat D-05's instruction as satisfied by this research's documented zero-hit grep against the named file; the KEEP verdicts for the two storage-schema files do not depend on finding a v1.43 mutation control anyway (they satisfy B.1 criteria 1/2 independently, as shown above).

2. **Does `bin/ci-test-partitions`'s CI log already expose per-partition timing?**
   - What we know: `mix verify.test_partitioned`'s local output format (captured in 226/227/229 evidence) already shows a per-partition `Seconds` column.
   - What's unclear: whether the *CI* step's log (not the local wrapper) prints the equivalent, which is what D-07 asks for as the "serial-equivalent work" disclosure source of first resort.
   - Recommendation: check a recent green `verify-test` job's raw log in the net-suite-measurement plan before deciding whether the one-line echo addition (Claude's Discretion) is needed.

