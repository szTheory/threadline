# Architecture Research

**Domain:** CI topology for an Elixir Hex library (Threadline v1.43: Supply Chain, CI Economy and Repo Hygiene)
**Researched:** 2026-09-26
**Confidence:** HIGH for integration points and contract-test impact. All are read from the tree, with file:line cited. Durations are measured from run `36258719902` (latest green push-to-main CI) plus the run history. MEDIUM for the dynamic `allowed-skips` mechanism. It rests on GitHub expression evaluation plus the alls-green README, and has not been exercised in this repo. MEDIUM for the Hex advisory feature version and the newest-toolchain versions (web sources).

This file is about the **CI topology**. It covers where each new check lives, the job graph, the contracts that pin it, and the order in which to change it. The product's three-layer architecture is unchanged by v1.43.

---

## Standard Architecture

### System Overview (current, measured)

```
.github/workflows/
┌──────────────────────────────────────────────────────────────────────────┐
│ ci.yml  (push main, pull_request main, workflow_dispatch; NO paths:)     │
│                                                                          │
│  no-BEAM      verify-release-shape            8s                         │
│  BEAM/no-DB   verify-format 22s  verify-compile-no-optional 47s          │
│               verify-credo 80s   verify-dialyzer 83s (PLT cache)         │
│               verify-docs 77s    verify-hex-package 15s                  │
│  DB           verify-test[min] 434s   verify-test[current] 600s          │
│               verify-pgbouncer-topology 116s  verify-hex-evaluator 64s   │
│               verify-mechanical 87s   verify-bump-rehearsal 164s         │
│  browser      verify-example-browser 651s  <-- critical path             │
│               verify-capture 529s                                        │
│                         │ (all 14 fan in, if: always())                   │
│                         ▼                                                │
│               ci-required "CI required" (alls-green, pinned SHA)         │
│               = the ONLY required status check (ruleset main-protection)  │
└──────────────────────────────────────────────────────────────────────────┘
┌──────────────────────┐ ┌───────────────────────┐ ┌──────────────────────┐
│ browser-full.yml     │ │ flake-detection.yml   │ │ release.yml          │
│ push main + 05:00    │ │ 07:00 nightly         │ │ release-please ->    │
│ ALL Playwright       │ │ 51 full-suite runs    │ │ pin sync -> dispatch │
│ projects, ~14-18 min │ │ 117-136 min when green│ │ CI -> gate-ci-green  │
│ not required         │ │ not required          │ │ -> publish (env gate)│
└──────────────────────┘ └───────────────────────┘ └──────────────────────┘
```

The critical path is the browser job. Its 610 s Playwright step compiles the example app cold. `verify-test (current)` is close behind at 600 s: 310 s of tests plus a 203 s `verify.example` step.

### Target System Overview (end of v1.43)

```
ci.yml  (unchanged triggers; still NO trigger-level paths:)

 [P-last] verify-change-scope  "Classify changed files"  (required, no if:)
             │ outputs.allowed_skips (empty on push/dispatch/unknown)
             │ needs: only from skip-eligible jobs
 ─────────────────────────────────────────────────────────────────────
 Tier 0 no-BEAM, seconds   verify-repo-hygiene (NEW)  verify-release-shape
 Tier 1 BEAM, no DB        verify-format  verify-deps-audit (NEW)
                           verify-compile-no-optional  verify-credo
                           verify-hex-package  verify-docs  verify-dialyzer
 Tier 2 DB                 verify-test[min|current|latest (NEW lane)]
                           verify-pgbouncer-topology  verify-hex-evaluator
                           verify-bump-rehearsal
 Tier 3 browser            verify-example-browser  verify-capture
 REMOVED                   verify-mechanical (dominated, see below)
                                   │
                                   ▼
            ci-required  alls-green  allowed-skips: ${{ classifier output }}

deps-health.yml (NEW, weekly + dispatch, not required):
  mix hex.audit + mix hex.outdated -> bin/upsert-ci-issue (label ci-deps)
browser-full.yml: push -> only the 4 projects ci.yml does not run;
                  schedule/dispatch -> full set
flake-detection.yml: bounded repeat count sized to a measured budget
release.yml: bootstrap-release-pr-ci dispatches only when no PAT fan-out
```

"Tier" is **YAML order and job design**, not `needs:` chaining. All tiers still start in parallel. See Pattern 3 for why no preflight gate is added.

### Component Responsibilities

| Component | Owns | Implementation | New / Modified |
|---|---|---|---|
| `ci-required` (ci.yml:923-954) | The only branch-protection decision | `re-actors/alls-green` pinned at a SHA, `if: always()` | MODIFIED: roster edits; `allowed-skips` in the last phase only |
| `verify-deps-audit` | Known-vulnerable or retired locked deps | `mix verify.audit`, which runs `mix hex.audit` | NEW job + NEW alias |
| `verify-repo-hygiene` | No absolute local paths or PII in tracked files | `bin/verify-no-local-paths` (bash, `git ls-files -z`), no BEAM | NEW job + NEW bin + NEW alias `verify.hygiene` |
| `verify-test` matrix (ci.yml:278-377) | Suite on floor, current and newest toolchains | New `lane: latest` include | MODIFIED |
| `verify-mechanical` (ci.yml:529-569) | Scorecard gate | Dominated by `verify.test` in both lanes and by `verify-capture`'s last step | REMOVED (alias kept) |
| `verify-capture` (ci.yml:577-684) | Byte-stable Tier A regeneration | Drop the trailing `mix verify.mechanical` step (ci.yml:683-684) | MODIFIED |
| `browser-full.yml` (:99-104) | Projects PRs do not run | Event-conditional project args | MODIFIED |
| `flake-detection.yml` | Intermittency signal | Bounded repeats, contract-compliant cache key | MODIFIED |
| `release.yml` `bootstrap-release-pr-ci` (:171-188) | CI on the release PR when no PAT fan-out | Skip the dispatch when `RELEASE_PLEASE_TOKEN` is configured | MODIFIED |
| `_build` deps cache | Warm dependency compile | `actions/cache@v4`, exact key, no `restore-keys`, `rm -rf _build/$MIX_ENV/lib/threadline` | NEW cache blocks (ci.yml:77-84 already specifies the rules) |
| `deps-health.yml` | Freshness and new-advisory signal on an unchanged tree | Scheduled workflow, `bin/upsert-ci-issue` | NEW workflow |
| `bin/classify-ci-lanes` | Changed paths to skip-eligible lanes, fail-closed | Pure script, table-tested (pattern: `bin/classify-flake-run`) | NEW (last phase) |
| `verify-change-scope` | Run the classifier and expose the output | Job with no `if:`, member of `ci-required` | NEW (last phase) |

---

## Recommended Project Structure (files touched)

```
.github/workflows/
├── ci.yml                 # roster, new jobs, matrix lane, _build cache, names/order, classifier
├── browser-full.yml       # event-conditional project set
├── flake-detection.yml    # bounded repeats + cache key fix
├── release.yml            # no double dispatch
└── deps-health.yml        # NEW: weekly audit + outdated -> tracking issue
bin/
├── verify-no-local-paths  # NEW: tracked-file PII/path guard (no BEAM)
└── classify-ci-lanes      # NEW (last phase): fail-closed lane classifier
mix.exs                    # aliases: verify.audit, verify.hygiene; ci.all entries;
                           # verify.flake -> function alias; hex: [ignore_advisories: []]
test/test_helper.exs       # exclude :live_dialyzer by default (honest-default rule)
test/threadline/
├── ci_topology_contract_test.exs        # roster, aliases, allowed-skips carve-out
├── ci_workflow_parity_contract_test.exs # List 1 parity, matrix axis, _build rule
├── ci_coverage_doc_contract_test.exs    # browser-full project flags
├── release_control_plane_contract_test.exs  # allowed-skips + bootstrap wiring
├── flake_classifier_contract_test.exs   # unchanged invariants, re-verified
└── ci_lane_classifier_contract_test.exs # NEW: table + completeness tests
CONTRIBUTING.md            # roster (:458-489), job table (:495-510), CI Coverage (:412-456),
                           # Deterministic tests (:99-138), freshness policy
```

### Structure Rationale

- **Aliases stay the entrypoint.** Every new check is a `mix verify.*` alias that `ci.all` and CI both cite. The one exception is `verify-repo-hygiene`: it calls its `bin/` script directly so it runs in seconds without BEAM, as `verify-release-shape` already does (ci.yml:851-859). The alias wraps the same script for local use.
- **Logic lives in `bin/`, not in YAML.** This is the precedent from `bin/classify-flake-run`. YAML can only be grep-tested. A script can be tested on behaviour with a table. The classifier and the path guard must be scripts.
- **No composite action.** A local `.github/actions/setup-elixir` would remove the 14 copies of setup-beam plus cache. But the contract tests assert literal cache keys inside `ci.yml` job blocks (ci_topology_contract_test.exs:142, :405; ci_workflow_parity_contract_test.exs:252-270). Moving the text out would force a contract rewrite for no failure-class gain. Defer it.

---

## Architectural Patterns

### Pattern 1: Same-commit roster change (the existing contract, restated precisely)

**What:** Any add, remove or rename of a `verify-*` job id changes these in **one commit**:
1. the `ci.yml` header roster comment (ci.yml:1-2), read by `ci_header_comment_keys` (parity test :140-148);
2. the job key itself, read by `ci_job_keys` (parity test :126-137, regex `^  (verify-[a-z0-9-]+):`);
3. CONTRIBUTING's "Job key | Purpose" table (:495-510), read by `contributing_list1_keys` (:151-164);
4. `ci-required` `needs:` (ci.yml:926-940) and CONTRIBUTING's `### ci-required needs: roster` (:458-480), checked in both drift directions by ci_topology_contract_test.exs:558-600.

**Consequence for naming:** the parity scan only sees ids that start with `verify-`. Name the classifier job `verify-change-scope`, not `changes` or `classify`. The existing three-way parity then covers it without a new scan. An id outside that prefix is invisible to the guard, which is how silent drift starts.

### Pattern 2: A skip is decided only by a required, unskippable job

**What:** Only the classifier job decides skips. It has **no `if:`**, sits in `ci-required.needs`, and emits `allowed_skips`. `ci-required` passes that output straight to alls-green: `allowed-skips: ${{ needs.verify-change-scope.outputs.allowed_skips }}`. GitHub evaluates the expression before the action reads its comma-separated input.
**Why it is fail-closed:**
- If the classifier fails, every dependent job is skipped by the default `success()` rule. The output is also empty, so alls-green scores both the failure and the skips as red.
- A job that ran and **failed** is never laundered, because `allowed-skips` only forgives `skipped`.
- On `push` and `workflow_dispatch`, the script emits nothing. Main and the release SHA that `gate-ci-green` polls (release.yml:299-372) always get the full matrix.

**Belt and braces:** each skip-eligible job's `if:` also carries `|| github.event_name != 'pull_request'`. This follows the ci.yml:21-27 comment, which already names this as the sanctioned mechanism.
**Example:**
```yaml
verify-change-scope:
  name: Classify changed files (lane selection)
  outputs:
    allowed_skips: ${{ steps.classify.outputs.allowed_skips }}
    run_browser: ${{ steps.classify.outputs.run_browser }}
  steps:
    - uses: actions/checkout@v5
      with: { fetch-depth: 0 }
    - id: classify
      env:
        EVENT: ${{ github.event_name }}
        BASE: ${{ github.event.pull_request.base.sha }}
        HEAD: ${{ github.event.pull_request.head.sha }}
      run: bin/classify-ci-lanes --event "$EVENT" --base "$BASE" --head "$HEAD" >> "$GITHUB_OUTPUT"

verify-example-browser:
  needs: verify-change-scope
  if: needs.verify-change-scope.outputs.run_browser == 'true' || github.event_name != 'pull_request'
```

### Pattern 3: "Fastest likely failure first" means YAML order and step order, not a preflight gate

**What:**
- Order jobs in YAML, which is also the order of the checks list, by expected time-to-red: hygiene, release-shape, format, audit, compile-no-optional, credo, hex-package, docs, dialyzer, test lanes, pgbouncer, evaluator, rehearsal, capture, browser.
- Inside a job, order steps cheap before costly. `verify-test` already does compile, then xref, then tests (ci.yml:348-355, pinned by ci_topology_contract_test.exs:204-230).

**Why not `needs: [verify-format, ...]` before the heavy jobs:** it adds roughly 1-1.5 min (runner pickup plus BEAM setup) to every **green** run to save minutes on red runs. Runner minutes are free on a public repo, and latency is the metric §9 protects. Parallel fan-out with honest names already tells a contributor where to look.

### Pattern 4: Move a unique assertion, then delete the dominated job

**What:** Before removing a job, confirm that another required job runs the same command on the same inputs. Keep the mix alias as a maintainer command.
**Applied:**
- `verify-mechanical` runs `test/threadline/operator_surface/mechanical_checker_test.exs`. That file already runs inside `verify.test` in **both** lanes (mix.exs:148-153 says so), and a third time at the end of `verify-capture`.
- The capture lane's trailing `mix verify.mechanical` (ci.yml:683-684) is also dominated. The byte-stable step before it asserts regenerated == committed, and `verify.test` already checks the committed JSON.

---

## Data Flow

### PR run (target, before SEED-006)

```
pull_request ─► ci.yml (all jobs in parallel)
                  └─► ci-required (alls-green over toJSON(needs)) ─► ruleset
merge (squash) ─► push main ─► ci.yml full ─► release.yml gate-ci-green polls it
                             └► browser-full.yml (4 non-PR projects only)
nightly ─► browser-full (full set) · flake-detection (bounded) · weekly deps-health
```

### Release PR flow (the double-dispatch fix)

Measured on the release branch (`gh run list --workflow ci.yml --branch release-please--branches--main`): every release head since 2026-09-22 got **two** CI runs on the same SHA, `pull_request` plus `workflow_dispatch`. Examples: `0745a341` at 16:41:13 and 16:41:17, and `43cf7b45` at 02:04:42 and 02:06:07.

The cause: `RELEASE_PLEASE_TOKEN` is configured (secret created 2026-05-28). The PAT pushes from release-please and from `sync-release-pr-pins` (release.yml:153-169) therefore already fan out a `pull_request` run. `bootstrap-release-pr-ci` (release.yml:171-188) then dispatches another run anyway.

**Fix:** keep the job, its `needs:` and its `if: always()` start. These are pinned by release_control_plane_contract_test.exs:122-160. Guard only the dispatch step: `HAS_PAT: ${{ secrets.RELEASE_PLEASE_TOKEN != '' }}`, and exit 0 with a notice when it is true. Do not make the dispatch "check whether a PR run exists". That is a race against GitHub's event latency. Extend the contract test to assert the guard.

### Key data flows

1. **Advisory signal.** Two paths:
   - PR path: `mix.lock` goes to `mix hex.audit` in `verify-deps-audit`, which reds `ci-required`.
   - Unchanged-tree path: weekly `deps-health.yml` upserts one `ci-deps` issue. Its label must stay distinct from `ci-flake` and `ci-browser-full`, the same dedup rule as browser-full.yml:118-120.
2. **Classifier signal.** The PR diff goes to `bin/classify-ci-lanes`, then to `allowed_skips` and the `run_*` outputs, then to job `if:` and the alls-green input.

---

## Integration Points (per target change)

| # | Change | Lives in | Alias | Files and lines | Contract tests affected | New/Mod |
|---|---|---|---|---|---|---|
| 1 | Baseline measurement | Local one-shot `gh run view --json jobs` over N runs. Record as evidence, not a CI job (§9: "one-shot probes run locally") | none | none | none | NEW evidence only |
| 2 | Fix advisories | `mix.lock` (lazy_html test-only; **mint 1.10.0 via req→finch, optional**) | none | mix.exs:104, mix.lock:21, :26 | dependency-floor guard (min lane must still resolve) | MOD |
| 3 | Audit gate | New job `verify-deps-audit` in `ci-required` | `verify.audit: ["hex.audit"]`, early in `ci.all` | ci.yml new job + :1-2 + :926-940; mix.exs:126-215; CONTRIBUTING :458-480, :495-510 | topology roster (:558), parity List 1 (:167), alias assertions (:48-62) | NEW |
| 4 | Freshness policy | `deps-health.yml` weekly: `hex.audit` + `hex.outdated` into one issue; policy text in CONTRIBUTING | reuses `verify.audit` | new workflow; `bin/upsert-ci-issue` | parity `:latest` image guard (:199-207) applies automatically | NEW |
| 5 | Flake Detection re-scope | flake-detection.yml:41, :70-75, :97 | `verify.flake` becomes a function alias (repeat count from env, default 50 locally) | mix.exs:177 | flake_classifier_contract_test.exs Tests 2-4 must stay green; the classifier is untouched | MOD |
| 6 | Remove duplicate proofs | Delete `verify-mechanical`; drop ci.yml:683-684; exclude `:live_dialyzer` in test_helper.exs:6-7 | keep `verify.mechanical` | ci.yml:529-569, :683-684, :936; test_helper.exs; CONTRIBUTING :99-138, roster, List 1 | topology roster, parity List 1, header parity | MOD/REMOVE |
| 7 | Release-PR double dispatch | release.yml:185-188 | none | release.yml | release_control_plane_contract_test.exs:122 (extend) | MOD |
| 8 | Browser-full de-dup | browser-full.yml:99-104. Event-conditional `--project=` for push; none for schedule/dispatch | `verify.example_browser` | browser-full.yml; CONTRIBUTING CI Coverage :412-456 | ci_coverage_doc_contract_test.exs:73 derives projects from `--project` flags; the table's `main` column semantics change | MOD |
| 9 | Deps-only `_build` cache | Every full-compile job: test lanes, dialyzer, credo, docs, compile-no-optional (separate key segment), browser/capture (plus the example app's own `_build`) | none | ci.yml:65-93 contract comment | **ci_workflow_parity_contract_test.exs:252-270 refutes `path: _build`. Rewrite it** to assert: exact key incl. MIX_ENV, no `restore-keys` on `_build` keys, and an `rm -rf _build/$MIX_ENV/lib/threadline` step before compile | NEW |
| 10 | Newest PG/Elixir lane | `verify-test` matrix gains `lane: latest` (exact pins: Elixir 1.20.x / OTP 29 / PG 18, ubuntu-24.04). Runs compile, xref and tests only; the `current`-only steps stay gated | none | ci.yml:286-300 | parity :233-241 asserts `lane: [min, current]`; :243-249 asserts List 2 names. Both change. The roster is unchanged, because `verify-test` is already a need | MOD |
| 11 | `@tag :tmp_dir` | Test files only (about 40 files call `System.tmp_dir`) | none | test/ | none. It raises the flake lane's signal-to-noise | MOD (tests) |
| 12 | PII/local-path guard | New job `verify-repo-hygiene` (no BEAM) in `ci-required` | `verify.hygiene` wraps `bin/verify-no-local-paths`; add to `ci.all` | new bin, ci.yml, mix.exs, CONTRIBUTING | roster, List 1, header parity. Also planning_dependency_contract_test.exs:126: do not hardcode a `.planning` path read in CI sources | NEW |
| 13 | Forward scrub | 295 tracked `.planning/` files: replace the home prefix only, no content edits | none | `.planning/**` | none | MOD |
| 14 | xref cycles gate | **Already shipped.** `verify.xref_cycles` (mix.exs:171-173) runs in both test lanes (ci.yml:351-352) and `ci.all`, pinned by ci_topology_contract_test.exs:204-230 | existing | none | none | EXISTS |
| 15 | CI DX names and order | `name:` fields and YAML order only; ids immutable | none | ci.yml; CONTRIBUTING quotes names | parity :243-249 (List 2 names). `CI required` must stay byte-exact (topology :669-708; `bin/observe-main-ci:88`) | MOD |
| 16 | SEED-006 classifier | `verify-change-scope` + `bin/classify-ci-lanes` + dynamic `allowed-skips` | none | ci.yml; new bin | **release_control_plane_contract_test.exs:90-120 refutes any `allowed-skips:` line**, and topology :585-600 requires an `allowed-skips decision:` entry in CONTRIBUTING. Amend both deliberately with a recorded decision | NEW |

### Findings that change scope (verified 2026-09-26)

1. **A second advisory is open.** `mix hex.audit` (Hex 2.5.1) reports **mint 1.10.0, EEF-CVE-2026-82672 (MEDIUM, GHSA-rj5m-69wp-cxq9)** as well as lazy_html. The milestone baseline lists only lazy_html. Mint arrives via the optional `req` dependency (`req ~> 0.7 → finch → mint ~> 1.8`), so adopters who use the S3/Req export path can resolve it. Fix both before the gate lands, or the gate is born red.
2. **The xref gate already exists, but the guide's claim is too broad.** `--label compile-connected` is clean. Plain `mix xref graph --format cycles` reports **5 runtime cycles**, including `capture/audit_transaction.ex ↔ semantics/audit_action.ex`, which crosses the capture and semantics layers. MILESTONE-GUIDE §9a says "`mix xref graph --format cycles` is clean", which holds only with the label. Scope decision: keep the compile-connected gate, which is Ecto association edges by design. Optionally add a ratchet that fails on any *new* runtime cycle. Correct the guide sentence either way.
3. **`verify-hex-evaluator`'s name is wrong.** It says "threadline from hex.pm", but the PR job runs rehearsal mode against a local registry built from the PR tree (mix.exs:358-398). Fix the name in the DX phase.
4. **Flake Detection's cache key breaks the cache-key contract.** `${{ runner.os }}-mix-deps-` (flake-detection.yml:74-75) is the exact shape ci.yml:65-75 bans. The anti-regression grep only scans ci.yml. Fix the key, and consider widening the grep to all workflows.
5. **The live-Dialyzer test is a duplicate proof.** `dialyzer_slice_contract_test.exs:8-12` (`@tag :live_dialyzer`, 540 s timeout) shells out to a cold Dialyzer in both test lanes. It also runs in every Flake Detection iteration. `verify-dialyzer` already enforces zero warnings on the same toolchain with a cached PLT. Exclude it by default in `test/test_helper.exs` and document it in CONTRIBUTING in the same commit (honest-default rule). Keep it runnable with `--include live_dialyzer`.

---

## Suggested Build Order (phases continue from 214)

Order: measurement first, then low-risk edits to existing lanes, then new required gates (each born green), then riskier cache and toolchain changes, then renames once the roster is stable, and the classifier last.

| Phase | Scope | Depends on | Risk | Why here |
|---|---|---|---|---|
| **214 Baseline** | Per-job p50/p95 over ≥10 push and ≥10 PR runs, runner-min per PR and per push, critical path, Flake and Browser-full costs, plus the **PR diff-class distribution** (share of merged PRs touching only docs/test/.planning). Local one-shot, recorded as evidence | none | none | §9 "measure before you optimize". The diff-class number decides whether 221 is worth building |
| **215 Supply chain** | Bump lazy_html and mint → `verify.audit` alias → `verify-deps-audit` job + roster/List 1/header in one commit → `deps-health.yml` → freshness policy text | 214 | Low | Headline defect. The gate lands green because the fix lands first. Adds one fast job, off the critical path |
| **216 Repo hygiene** | Forward scrub (a separate commit, prefix-only replacement) → `bin/verify-no-local-paths` + `verify.hygiene` + `verify-repo-hygiene` in `ci-required` → xref decision (ratchet or doc correction) → `@tag :tmp_dir` migration | 214 | Low | Independent of CI economy. Scrub before guard or the guard is born red. tmp_dir first improves the signal that 217's Flake re-scope measures |
| **217 CI economy: remove waste** | Release double dispatch · Browser-full push subset · drop `verify-mechanical` + capture's trailing mechanical step · exclude `:live_dialyzer` · Flake re-scope + cache key · docs/tarball overlap decision | 214 (numbers), 216 (tmp_dir) | Low-Med | Pure deletions and narrowing, each with a named dominating proof. Roster shrinks here, once |
| **218 Deps-only `_build` cache** | Cache blocks per (runner, OTP, Elixir, MIX_ENV, mix.lock, optional-deps flag), no restore-keys, rm own app before compile. Example app `_build` separately. Rewrite parity :252-270 | 217 | Med | Stale-artifact risk, so isolate it and measure before/after against 214. Do after 217 so the job set being cached is final |
| **219 Newest toolchain lane** | `lane: latest` in `verify-test`, exact pins, parity :233-249 + List 2 | 218 (key shape covers the new lane) | Med | Elixir 1.20's type inference can surface new warnings under `--warnings-as-errors`. Prove green on a branch before it votes. Never `continue-on-error` |
| **220 CI DX** | `name:` rewrites ("says what failed"), YAML reorder by time-to-red, CONTRIBUTING name quotes, stale evaluator name | 215-219 (roster final) | Low | Rename once, after every job add, remove and lane change, so names and docs churn one time |
| **221 SEED-006 classifier** | `bin/classify-ci-lanes` + `ci_lane_classifier_contract_test.exs` → `verify-change-scope` (roster) → `if:` on skip-eligible jobs → dynamic `allowed-skips` + amended release_control_plane :90 + CONTRIBUTING `allowed-skips decision:` | 214 diff-class data, 220 | High | Only one that weakens what a single PR proves. Build only if 214 shows a real share of skip-eligible PRs. Otherwise record "measured, not worth it" and close SEED-006 |

### Classifier design constraints (for phase 221)

- **Skip-eligible jobs only:** `verify-example-browser`, `verify-capture`, `verify-pgbouncer-topology`, and perhaps `verify-hex-evaluator`. **Never skip** `verify-test`, `verify-bump-rehearsal`, the Tier 0/1 jobs or the classifier. Doc-contract tests read README, guides, CONTRIBUTING and workflows inside `verify-test`, and the rehearsal runs every doc-contract file. A "docs-only" PR can still turn those red.
- **Full matrix whenever any of these change:** `lib/`, `priv/`, `config/`, `assets/`, `examples/`, `mix.exs`, `mix.lock`, `.github/`, `bin/`, `.tool-versions`, or **any path not on an explicit allow-list**. A workflow edit changes the jobs themselves, so the SEED's "CI-only change" example must run everything.
- **Also full matrix:** the event is not `pull_request`, `git diff` fails, or the base SHA is missing.
- **Mechanical tests:**
  - (a) a table of path sets mapped to expected outputs;
  - (b) a completeness test: every `git ls-files` path classifies to a known category or to "unknown → full";
  - (c) a test that every file a contract test reads maps to a category that runs `verify-test`;
  - (d) a test that `push` and `workflow_dispatch` always yield an empty `allowed_skips`.

---

## Scaling Considerations

| Concern | Now | After v1.43 | If the suite doubles |
|---|---|---|---|
| Concurrent-job cap (public repo) | 15 jobs per ci.yml run; PR + push + browser-full overlap | 16 jobs (+2 new, −1 removed, +1 matrix lane) | Consider the classifier, not sharding |
| Critical path | Browser 651 s, current test lane 600 s | Browser ~ −(example compile) with the `_build` cache; current lane unchanged | Move `verify.example` (203 s) out of `verify-test (current)` into its own parallel job (measure first) |
| Cache budget (10 GB per repo) | deps + PLT + Playwright | + `_build` per lane and env + example `_build` | Watch evictions. Exact keys only, no restore-keys fan-out |
| Flake Detection | ~3,600 runner-min/month | Bounded, e.g. 10 repeats ≈ 30 min nightly, about 900/month (confirm against 214) | Re-derive repeat count from measured per-iteration time |

---

## Anti-Patterns

### Anti-Pattern 1: Static `allowed-skips` or `continue-on-error` on a voting job
**What people do:** list a flaky or new lane in `allowed-skips`/`allowed-failures`, or mark its step `continue-on-error`, to land it early.
**Why it's wrong:** it launders a red job into a green `CI required`. release_control_plane_contract_test.exs:90-120 exists to catch exactly this.
**Do this instead:** land the lane green on a branch first (219). Only the classifier's dynamic output may populate `allowed-skips` (221).

### Anti-Pattern 2: Trigger-level `paths:` / `paths-ignore:` on ci.yml
**Why it's wrong:** the required check never reports and the PR waits forever (ci.yml:9-27). It also lets main diverge.
**Do this instead:** job-level `if:` driven by a required classifier.

### Anti-Pattern 3: `_build` cache with `restore-keys`, or without removing the app's own build
**Why it's wrong:** a partial restore across a changed `mix.lock` serves stale compiled deps. A restored `_build/*/lib/threadline` can mask the code under test.
**Do this instead:** follow the rules in ci.yml:77-84 and pin them in the rewritten parity test.

### Anti-Pattern 4: Floating toolchain tags for the newest lane
**Why it's wrong:** `postgres:latest` is already banned (parity :199-207). An unpinned "latest Elixir" turns red on an upstream release, with no change in the repo.
**Do this instead:** use exact versions and bump them on purpose.

### Anti-Pattern 5: A gate that passes on nothing
**Why it's wrong:**
- `mix hex.audit` only reports advisories on a Hex version that supports them. `ignore_advisories` is documented for Hex 2.5.1. An old Hex archive passes green while seeing nothing.
- The path guard's own pattern and its fixtures can match themselves.

**Do this instead:**
- Assert a Hex version floor in the audit job, or keep a fixture lock pinned to a known-vulnerable version that must fail.
- Build the path regex from parts, and run a table test with a seeded positive.

### Anti-Pattern 6: The forward scrub rewrites historical receipts
**Why it's wrong:** §8 says "do not rewrite historical receipts to look cleaner".
**Do this instead:** replace the home-directory prefix only (with `~` or a repo-relative path), mechanically. Keep every other byte. Commit it separately from the guard so the diff can be reviewed as prefix-only.

---

## Sources

- Repository (HIGH): `.github/workflows/{ci,browser-full,flake-detection,release}.yml`, `mix.exs`, `CONTRIBUTING.md`, `test/test_helper.exs`, `test/threadline/{ci_topology,ci_workflow_parity,ci_coverage_doc,release_control_plane,flake_classifier,dialyzer_slice}_contract_test.exs`, `bin/observe-main-ci`, `.planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md`, `.planning/MILESTONE-GUIDE.txt` §7, §8, §9, §9a, §13
- Measured (HIGH): CI run `36258719902` per-job and per-step durations; release-branch run list (duplicate `pull_request` + `workflow_dispatch` per SHA); `gh secret list` (RELEASE_PLEASE_TOKEN present); `mix hex.audit` output (Hex 2.5.1); `mix xref graph --format cycles` with and without `--label compile-connected`; `git ls-tree origin/main` (2190 `.planning/` files public)
- [re-actors/alls-green README](https://github.com/re-actors/alls-green): `allowed-skips` is a comma-separated input (MEDIUM for dynamic expression use)
- [mix hex.audit docs, Hex v2.5.1](https://hex.hexdocs.pm/Mix.Tasks.Hex.Audit.html): advisories, `ignore_advisories`, `HEX_IGNORE_ADVISORIES` (MEDIUM for which version introduced advisories)
- [Elixir v1.20.0 release](https://github.com/elixir-lang/elixir/releases/tag/v1.20.0) and [changelog v1.20.4](https://hexdocs.pm/elixir/changelog.html): OTP 27+ required, OTP 29 compatible, stronger type inference (MEDIUM)

---
*Architecture research for: CI topology, v1.43*
*Researched: 2026-09-26*
