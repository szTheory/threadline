# Roadmap: Threadline

## Milestones

- 🚧 **v1.43 Supply Chain, CI Economy and Repo Hygiene** - Phases 214-222 (in progress, opened 2026-09-26)
- [x] **v1.42 Capture Correctness for Real Table Shapes** - Phases 208-213 (shipped 2026-09-26, released as 0.11.0). Archive: `.planning/milestones/v1.42-ROADMAP.md`
- [x] **v1.41 Green, Clean, and Honest** - Phases 198-207 (shipped 2026-09-24). Archive: `.planning/milestones/v1.41-ROADMAP.md`
- [x] **v1.40 Automated Operator-UI Critique & Forward-Only Iteration Harness** - Phases 194-197 (shipped 2026-08-27). Archive: `.planning/milestones/v1.40-ROADMAP.md`
- [x] **v1.39 Quality Baseline, Schema Confidence, and CI Efficiency** - Phases 189-193 (shipped 2026-07-03). Archive: `.planning/milestones/v1.39-ROADMAP.md`
- [x] **v1.38 Operator UI Page-by-Page IA & Design-System Polish** - Phases 181-188 (shipped 2026-06-30). Archive: `.planning/milestones/v1.38-ROADMAP.md`
- [x] **v1.37 Operator Surface Design-System Stress Test & Component System** - Phases 171-180 (shipped 2026-06-20). Archive: `.planning/milestones/v1.37-ROADMAP.md`
- [x] **v1.36 Operator Surface Light Mode** - Phases 166-170 (shipped 2026-06-14). Archive: `.planning/milestones/v1.36-ROADMAP.md`
- [x] **v1.35 Unified Logo & Brand Book v2** - Phases 159-165 (shipped 2026-06-12). Archive: `.planning/milestones/v1.35-ROADMAP.md`
- [x] **v1.34 Local Docker Admin UI DX** - Phases 154-158 (shipped 2026-06-07). Archive: `.planning/milestones/v1.34-ROADMAP.md`

## 🚧 v1.43 Supply Chain, CI Economy and Repo Hygiene (In Progress)

**Milestone Goal:** Close the open dependency advisories behind a CI audit gate, make every CI job earn its runner minutes and read clearly, and keep the public repo free of machine-local paths. Measure first, cut the lowest-risk waste first, and ship as a patch.

**Granularity:** coarse config, but nine phases. The product layers are untouched; each boundary is an ordering constraint on the CI topology, not a feature split. Every gate's fix must land before the gate (advisories before the audit gate, scrub before the path guard). Deletions must precede caching so only the final job set is cached. Renames must follow every roster change so names and contract tests churn once. The classifier's value depends on post-wins data, so it goes last. Merging adjacent phases would either put a gate in front of its own fix or cache/rename a job set that is about to change.

**Evidence:** `.planning/research/SUMMARY.md` (Implications for Roadmap, resolved disagreements) and `.planning/REQUIREMENTS.md`. Where they conflict, REQUIREMENTS.md wins (no runtime-cycle gate; `@tag :tmp_dir` scoped as hygiene; weekly flake cadence).

### Dependency spine

```
                 ┌─→ 215 Supply chain gate ──┐
214 Baseline ────┼─→ 216 Platform currency ──┼─→ 218 Remove CI waste ─→ 219 _build cache ─→ 220 Newest lane ─→ 221 Names/order ─→ 222 SEED-006 (conditional)
                 └─→ 217 Repo hygiene ───────┘        (ECON-07 re-measure)                  (spike-gated)
```

- **215, 216 and 217 are mutually independent.** Any order works after 214. If the runner's Node 20 forced-upgrade shim is withdrawn, pull 216 ahead of 215.
- **216 fixes the cache-key shape** (resolved OTP/Elixir) that 218's flake cache key, 219's `_build` keys and 220's lane all reuse.
- **217's tmp_dir work precedes 218's flake re-scope**, so the flake lane measures a cleaner suite.
- **222 adds one new job** (`verify-change-scope`) after 221. It is born with its final descriptive name, so 221's "rename once" still holds.

### Cross-cutting invariants (hold in every phase)

- **Same-commit roster rule.** Any add, remove or rename of a `verify-*` job changes `ci.yml`, CONTRIBUTING's job table and roster, `ci-required` `needs:` and the topology contract test in the same commit. Job `id:`s are immutable; `CI required` stays byte-exact.
- **No laundering.** No trigger-level `paths:` on `ci.yml`, no static `allowed-skips`, no `continue-on-error` on a voting job.
- **Every new gate is born green and proven red.** Each gate lands after its fix and ships with a negative test that makes it fail.
- **Every removal is justified.** Each deleted proof carries a written "failure class X is still caught by job Y on trigger Z" line.
- **Zero human verification.** Every success criterion names the test, alias, or recorded run ID that proves it. `mix ci.all` stays green at each phase close. The maintainer handles only push, merge, `production-hex` approval, and repo-setting toggles (Dependabot alerts).
- **Never `git add .planning/` wholesale.** Stage explicit file lists only.
- **Ships as a patch.** At least one releasable `fix(deps):` commit (Phase 215) carries the CHANGELOG line. No planning vocabulary in releasable commit subjects or CHANGELOG.

## Phases

- [x] **Phase 214: Baseline Measurement** - A cited, re-measured CI cost and duration baseline, and PROJECT.md corrected to match it (completed 2026-09-26)
- [x] **Phase 215: Supply Chain Gate** - All three lockfiles audit clean, and CI fails any PR that introduces an advisory (completed 2026-09-26)
- [x] **Phase 216: CI Platform Currency** - CI runs the exact committed toolchain on Node 24 actions and supported runners (completed 2026-09-27)
- [x] **Phase 217: Repo Hygiene** - No tracked machine-local paths, a CI guard that keeps it that way, scoped tmp_dir hygiene, and the xref disposition recorded (completed 2026-09-27)
- [x] **Phase 218: CI Economy: Remove Waste** - Flake, release, Browser-full, live-Dialyzer and mechanical duplicates cut, each with a named dominating proof, and savings measured (completed 2026-09-27)
- [ ] **Phase 219: Deps-Only Build Cache** - Test jobs restore exact-keyed deps-only `_build` and example-app caches, with the saving measured
- [ ] **Phase 220: Newest-Toolchain Lane** - Spike-gated voting lane on Elixir 1.20 / OTP 29 / PG 18, or recorded "not yet"
- [ ] **Phase 221: CI Names and Order** - A red check's name says what failed, and YAML runs fastest-to-red first
- [ ] **Phase 222: SEED-006 Change-Aware Lanes (conditional)** - Decided from measured data: a fail-closed classifier, or "measured, not worth it"

## Phase Details

### Phase 214: Baseline Measurement

**Goal**: The maintainer and every later phase can cite a re-measured, run-ID-backed CI baseline, and PROJECT.md's baseline matches measured fact
**Depends on**: Nothing (first phase)
**Requirements**: BASE-01, BASE-02
**Success Criteria** (what must be TRUE):

  1. A baseline evidence doc exists in the phase directory with per-job p50/p95 over ≥10 PR and ≥10 push runs, runner-minutes per PR / push-to-main / release cycle, the critical path, Flake Detection and Browser-full cost, `mix test --slowest 25`, the isolated `:live_dialyzer` cost, and the inert-path share of merged PRs.
  2. Every number in the doc cites a GitHub run ID or a reproducible command; an automated check (script or grep over the doc) finds no uncited figure.
  3. PROJECT.md `## Current Milestone` baseline states the corrected flake streak dates and 180-min timeout, the two root advisories plus 3 HIGH in bench, the tracked-path count including `prompts/prior-art/`, "tmp_dir hygiene" wording, and the no-runtime-cycle-gate xref disposition.
  4. PROJECT.md Out of Scope still permits an added, spike-gated newest lane and records the pin-honesty justification for the OTP fix (amended at milestone open, 2026-09-26; re-check, do not re-edit).

**Plans**: 4 plans (1 gap closure)

Plans:
**Wave 1**

- [x] 214-01-PLAN.md — Tracer + CI API baseline: collector, citation checker, per-job p50/p95, critical path, runner-minutes, Flake Detection and Browser-full cost (wave 1)
- [x] 214-02-PLAN.md — BASE-02 facts re-measured, PROJECT.md baseline corrected + checker, Out of Scope re-check, local slowest-25 and live-Dialyzer captures (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 214-03-PLAN.md — Inert-path PR share, fold local/BASE-02 evidence into the doc, completeness checker and single verify-phase.sh gate (wave 2)

**Gap closure** *(from 214-VERIFICATION G2)*

- [x] 214-04-PLAN.md — Restate the PROJECT.md CI wall-time bullet from measured p50s (run IDs), add wall facts to facts.json and assert them in check-project-baseline.sh with a stale-wall negative fixture (wave 1)

**Research**: Not needed (measurement method already in `research/FEATURES.md`)

### Phase 215: Supply Chain Gate

**Goal**: No lockfile in the repo carries a known advisory, and CI stops any PR that would introduce one, without a Dependabot PR flood
**Depends on**: Phase 214 (independent of 216 and 217)
**Requirements**: SUP-01, SUP-02, SUP-03, SUP-04
**Success Criteria** (what must be TRUE):

  1. `mix hex.audit` exits 0 for the root, `examples/threadline_phoenix` and `bench` lockfiles, with no `mix.exs` constraint change (diff check), and both test lanes are green on the lazy_html NIF bump; a releasable `fix(deps):` commit carries a CHANGELOG line for the mint advisory.
  2. `mix verify.deps_audit` runs the unused-lock check plus `hex.audit` over all three lockfiles, asserts Hex ≥ 2.5.1, and runs in a new `verify-deps-audit` job added under the same-commit roster rule; a negative fixture test proves it exits non-zero on a known-vulnerable lock and on an old Hex.
  3. A test fails when any `hex: [ignore_advisories: ...]` entry lacks a reason, a reachability claim, or an unexpired review-by date.
  4. A weekly, non-required `deps-health.yml` runs `hex.audit` + `hex.outdated` and upserts a single `ci-deps` issue (label distinct from `ci-flake`/`ci-browser-full`), and CONTRIBUTING states the batched freshness policy with no Dependabot version-update PRs (doc-contract test).

**Plans**: 6 plans (4 executed + 2 gap closure) — all executed, re-verification pending
**Research**: Narrow, only if Hex `cooldown` is adopted (confirm where it is configured first)

Plans:
**Wave 1**

- [x] 215-01-PLAN.md — Lock-only advisory fixes: root mint/lazy_html (fix(deps) + CHANGELOG), bench package-group refresh; both test lanes green (wave 1) (completed 2026-09-26)
- [x] 215-03-PLAN.md — hex_audit_ignores/0 convention + contract test over all three projects' resolved hex config (wave 1) (completed 2026-09-26)

**Wave 2**

- [x] 215-02-PLAN.md — bin/verify-deps-audit + `mix verify.deps_audit` + required `verify-deps-audit` job, ci.all membership, vulnerable-lock/old-Hex self-test (wave 2) (completed 2026-09-26)

**Wave 3**

- [x] 215-04-PLAN.md — Weekly non-required deps-health.yml (single ci-deps issue), CONTRIBUTING freshness policy, doc-contract test (wave 3) (completed 2026-09-26)

**Gap closure (215-VERIFICATION: CR-01, WR-02)**

- [x] 215-05-PLAN.md — Required gate: refuse global `mix hex.config` advisory/retirement ignores, fetch with `deps.get --check-locked`, self-test cases for both, workflow contract rejects HEX_HOME/MIX_HOME/`hex.config ignore_`, corrected ignore-contract moduledoc (gap wave 1) (completed 2026-09-27)
- [x] 215-06-PLAN.md — Weekly lane: active Hex suppression and lock drift classify `unknown`, CONTRIBUTING sentence, non-promoted review findings tracked in deferred-items.md (gap wave 2) (completed 2026-09-27)

### Phase 216: CI Platform Currency

**Goal**: CI runs exactly the toolchain the repo commits to, on non-deprecated actions and runner images
**Depends on**: Phase 214 (independent of 215 and 217)
**Requirements**: PLAT-01, PLAT-02, PLAT-03
**Success Criteria** (what must be TRUE):

  1. `.tool-versions` is tracked; non-matrix jobs use setup-beam `version-file` with `version-type: strict`; a CI log shows the resolved OTP equals the committed pin (no 27.0.1 drift); every cache key interpolates the resolved OTP/Elixir outputs, and the topology and parity contract tests assert these pins.
  2. A grep-based contract test finds no Node 20 action in any workflow (`actions/cache@v5`, `upload-artifact@v7`, `release-please-action@v5`), and the release-please bump lands in its own commit with a recorded rehearsal through the release runbook.
  3. The min lane runs on a supported runner image (not `ubuntu-22.04`), and a green CI run ID shows lazy_html's OTP 26 NIF resolving there.

**Plans**: 8/8 plans complete (7 + 1 gap closure)

Plans:
**Wave 1**

- [x] 216-01-PLAN.md — Track .tool-versions; every non-matrix ci.yml job on setup-beam version-file strict with resolved-output cache keys; toolchain classifiers (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 216-02-PLAN.md — Strict verify-test matrix with exact floor pins and the min lane on ubuntu-24.04; runner-image and OS-family key guards (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 216-03-PLAN.md — Release jobs read the pin from the workflow commit (toolchain-first sparse checkout); browser-full, flake-detection, deps-health re-pinned; contract scans every workflow (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 216-04-PLAN.md — release-please-action v5 in its own commit + dry-run rehearsal; cache@v5 / upload-artifact@v7 (wave 4)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 216-05-PLAN.md — Fail-closed Node 24 allowlist test + Release Please upgrade runbook with its doc contract (wave 5)

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 216-06-PLAN.md — Negative-controlled evidence recipe, local gate, maintainer push gate, post-push CI evidence (OTP pin, min lane NIF, no Node 20) (wave 6, non-autonomous)

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 216-07-PLAN.md — Maintainer landing gate, first Release run on release-please-action v5 and main CI / Browser-full evidence (wave 7, non-autonomous)

**Gap closure** *(post-landing regression)*

- [x] 216-08-PLAN.md — Release-job toolchain pin checkout isolated in .toolchain-pin (git 2.55 sparse-checkout disable no-op broke run 36319430805); PR #57

**Research**: Partial: release-please-action v5 rehearsal path, and lazy_html OTP 26 NIF availability on ubuntu-24.04

### Phase 217: Repo Hygiene

**Goal**: The public tree carries no machine-local paths and CI keeps it that way; leaking temp-dir tests are cleaned up; the xref disposition is on record
**Depends on**: Phase 214 (independent of 215 and 216)
**Requirements**: HYG-01, HYG-02, HYG-03, HYG-04
**Success Criteria** (what must be TRUE):

  1. `git grep -I` over tracked files finds no absolute or home-relative machine-local path, including `prompts/prior-art/`; the scrub commit changes path prefixes only, stages exactly the `git grep -l -I` list, and does not rewrite history.
  2. A `bin/` guard, wrapped by a `verify.*` alias in `ci.all` and run by a new `verify-repo-hygiene` job (same-commit roster rule), scans tracked text files only, allowlists runner/cache paths, fails on an unused allowlist entry, and a negative test with runtime-built fixtures proves it goes red; no real username appears anywhere in the repo.
  3. The 7 leaking test files and any async-colliding tests use `@tag :tmp_dir`; tests that need an out-of-repo dir keep the system temp dir; tree-walking tests ignore `tmp/`; a full `mix test` leaves no new entries in the system temp dir.
  4. MILESTONE-GUIDE §9a names the `compile-connected` label, `verify.xref_cycles` stays unchanged, no runtime-cycle gate exists, and the `Capture.AuditTransaction`↔`Semantics.AuditAction` edge is logged as a v1.45 architecture observation.

**Plans**: 7/7 plans complete (5 + 2 gap closure)

Plans:
**Wave 1**

- [x] 217-01-PLAN.md — `bin/verify-repo-hygiene` tracked-text local-path guard, scoped allowlist with unused/inert tracking, `--self-test`, offline behavior test (HYG-02, unwired)
- [x] 217-02-PLAN.md — Leaking temp-dir tests on ExUnit `@tag :tmp_dir`; `bin/verify-temp-leaks` / `mix verify.temp_leaks` proves the suite leaves no system-temp entries (HYG-03)
- [x] 217-03-PLAN.md — Re-verify the xref disposition (compile-connected gate unchanged, no runtime gate) and trace the AuditTransaction<->AuditAction edge onto the §7 v1.45 rung (HYG-04)

**Wave 2** *(blocked on 217-01)*

- [x] 217-04-PLAN.md — Guard-driven prefix-only scrub: public prior-art commit plus a separate `.planning/`-only commit, exact-list staging (HYG-01)

**Wave 3** *(blocked on 217-04 and 217-02)*

- [x] 217-05-PLAN.md — Same-commit roster wiring: `mix verify.repo_hygiene` in `ci.all`, required `verify-repo-hygiene` job in `ci-required`, CONTRIBUTING, wiring contract test (HYG-02)

**Gap closure, Wave 1**

- [x] 217-06-PLAN.md — CR-01 family-6 single-segment false negative, red-then-green plus a sixth self-test case; WR-01 conditional label, WR-03 full-family allowlist safety net, IN-01 explicit git check (HYG-02)

**Gap closure, Wave 2** *(blocked on 217-06)*

- [x] 217-07-PLAN.md — Placeholder convention for describing path shapes in prose (CONTRIBUTING section, guard failure hint, doc contract test); WR-02 colon-safe parsing; all review dispositions recorded (HYG-01, HYG-02)

**Research**: Completed (`217-RESEARCH.md`, `217-PATTERNS.md`)

### Phase 218: CI Economy: Remove Waste

**Goal**: Every remaining CI minute buys a distinct signal, and the savings are measured against the baseline
**Depends on**: Phase 214 (baseline), Phase 216 (cache-key shape, Node 24 actions), Phase 217 (tmp_dir hygiene before the flake re-scope); lands after 215 so the roster shrinks once
**Requirements**: ECON-01, ECON-02, ECON-03, ECON-04, ECON-05, ECON-06, ECON-07
**Success Criteria** (what must be TRUE):

  1. Flake Detection runs weekly plus on dispatch with 10–15 repeats sized from measured iteration time, a step timeout shorter than the job timeout so classify/report always run, skips an unchanged green SHA, exits `broken-upstream` when CI on that SHA is red, reports a timeout as inconclusive (no false "no header"), and uses a contract-compliant cache key checked by an all-workflows anti-regression grep (`flake_classifier` and workflow contract tests).
  2. `bin/upsert-ci-issue` closes a tracking issue when its lane goes green (table test), #28 and #36 are resolved, and a release PR head SHA gets exactly one CI run because `bootstrap-release-pr-ci` dispatches on a deterministic PAT/sync-output guard (extended `release_control_plane_contract_test.exs`).
  3. Browser-full on push runs only the Playwright projects `ci.yml` does not, the nightly skips an already-green SHA, and a contract test proves CI's projects plus Browser-full's equal the full Playwright config project set.
  4. `:live_dialyzer` is excluded from default `mix test` and runs only in the PLT-cached `verify-dialyzer` job (test_helper, CONTRIBUTING and topology test changed together); `verify-mechanical` and the capture lane's trailing mechanical step are gone with the alias kept; each removal carries a written "still caught by job Y on trigger Z" line.
  5. A re-measurement doc records runner-minutes and critical-path deltas against the Phase 214 baseline, each figure citing run IDs.

**Plans**: 8/8 plans complete (serialized waves 1-8; main checkout, no Elixir tests in worktrees)

Plans:
**Wave 1**
- [x] 218-01-PLAN.md — ECON-03: release-PR CI dispatch guarded on PAT absence (D-06a), contract + mutation controls

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 218-02-PLAN.md — ECON-02: `bin/upsert-ci-issue --close` table-tested, deps-health close-on-clean, #28/#36 resolved or handed off (D-06)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 218-03-PLAN.md — ECON-05: fail-closed Dialyzer slice verifier, `:live_dialyzer` excluded by default and run only in verify-dialyzer, ci.all dedup contract exemption (D-08)

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 218-04-PLAN.md — ECON-06: drop capture mechanical step, dominance pins, one roster commit removing verify-mechanical/verify-docs/verify-hex-package (D-09, D-10)

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 218-05-PLAN.md — ECON-01: weekly bounded Flake Detection, `bin/ci-sha-gate`, inconclusive/broken-upstream (D-01..D-04)

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 218-06-PLAN.md — ECON-01/02: truthful flake issue text, close on pass, all-workflow OS-family guard (D-04..D-06)

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 218-07-PLAN.md — ECON-04: `bin/browser-full-projects` derived difference, partition contract, nightly green-SHA skip, close on green (D-07)

**Wave 8** *(blocked on Wave 7 completion)*
- [x] 218-08-PLAN.md — ECON-07: copied 214 tools, phase gate, maintainer push checkpoint, cited re-measurement vs BASE-01 (D-11)

**Research**: Not needed (each change has file:line and a named dominating proof)

### Phase 219: Deps-Only Build Cache

**Goal**: Test jobs stop recompiling dependencies on every run without ever serving a stale or wrong artifact
**Depends on**: Phase 216 (resolved-version key shape), Phase 218 (final cached job set)
**Requirements**: CACHE-01
**Success Criteria** (what must be TRUE):

  1. Test jobs restore a deps-only `_build` cache and a separate example-app cache via split restore/save, keyed exactly on runner, resolved OTP/Elixir, MIX_ENV, profile, lock and config, with no `restore-keys`.
  2. The project's own build (`_build/$MIX_ENV/lib/threadline`) is removed before compiling in every cached job.
  3. `verify-compile-no-optional` and the `release.yml` publish path contain no cache step, and the parity contract test asserts all of the above rules.
  4. A before/after measurement cites run IDs and records the per-job and critical-path delta against the Phase 214 baseline.

**Plans**: 3 plans

Plans:
**Wave 1**

- [x] 219-01-PLAN.md — Contract first: pure `build_cache_errors/2` with allowlists, key segments, step-order classifier and docs parity, proven by D-21 mutation controls on a synthetic fixture; D-17 security subset asserted live (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 219-02-PLAN.md — One commit: exact-keyed deps-only root and example caches in verify-test, pgbouncer (restore-only), example-browser and capture; no-optional deps cache removed; ci.yml comment + CONTRIBUTING `### Dependency build cache`; contract flipped live (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 219-03-PLAN.md — Copied measurement tools + `remeasure-219.py`, maintainer landing/dispatch checkpoint, cited `219-REMEASURE.md` against BASE-01 and 218 (wave 3, non-autonomous)

**Research**: Yes: config-in-key and profile-segment shape are inference; check eviction under the 10 GB cache budget

### Phase 220: Newest-Toolchain Lane

**Goal**: The suite is proven (or honestly not yet proven) on the newest stable Elixir, OTP and PostgreSQL before any adopter hits them
**Depends on**: Phase 216 (runner image, Node 24 actions), Phase 219 (cache-key shape); Phase 214's PROJECT.md Out of Scope amendment
**Requirements**: LANE-01
**Success Criteria** (what must be TRUE):

  1. A dispatch spike run, cited by run ID, executes the suite on exactly pinned Elixir 1.20.x / OTP 29.x / PostgreSQL 18 under `--warnings-as-errors`.
  2. If the spike is green, `lane: latest` is a voting entry in `verify-test` with roster and parity contract tests updated in the same commit; if not, a findings record states "not yet" with the specific failures.
  3. A contract test proves no voting lane uses `continue-on-error` and no lane uses a beta PostgreSQL image.

**Plans**: TBD
**Research**: Yes: the Elixir 1.20 warning surface under `--warnings-as-errors` is unknown until spiked

### Phase 221: CI Names and Order

**Goal**: A contributor can tell from a red check's name what failed, without opening logs
**Depends on**: Phase 220 (every roster add/remove/lane change is done)
**Requirements**: DX-01
**Success Criteria** (what must be TRUE):

  1. Every CI job `name:` states what it proves, including the Hex evaluator name that is currently false on PRs, rewritten in one pass with CONTRIBUTING quotes updated in the same commit (doc-contract test).
  2. Jobs in `ci.yml` are ordered by measured time-to-red with no `needs:` preflight chain added (topology contract test).
  3. Job `id:`s are unchanged and `CI required` is byte-exact (existing pins stay green).

**Plans**: TBD
**Research**: Not needed

### Phase 222: SEED-006 Change-Aware Lanes (conditional)

**Goal**: SEED-006 is settled by measured data: either inert PRs skip provably irrelevant lanes through a fail-closed classifier, or the seed is closed as "measured, not worth it"
**Depends on**: Phase 218 (ECON-07 re-measure), Phase 219 (cache delta), Phase 221 (names settled; the new job is born with its final name)
**Requirements**: SCOPE-01
**Success Criteria** (what must be TRUE):

  1. A decision record re-checks the Phase 214 inert-PR share against the post-218/219 numbers and states build or close, with cited run IDs.
  2. If built: `bin/classify-ci-lanes` is table-tested and fail-closed (any unknown path runs the full matrix), a `verify-change-scope` job joins the roster under the same-commit rule, and `allowed-skips` is dynamic and limited to skip-eligible jobs (never `verify-test` or the rehearsal).
  3. If built: on `push` and `workflow_dispatch` the skip list is always empty, and a `ci-required` step re-justifies every skip (contract tests including `release_control_plane_contract_test.exs`).
  4. If not built: SEED-006 is marked closed with the "measured, not worth it" rationale and the numbers behind it.

**Plans**: TBD
**Research**: Yes: dynamic `allowed-skips` through alls-green is unexercised in this repo; enumerate doc-contract test file reads

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 214. Baseline Measurement | 4/4 | Complete    | 2026-09-26 |
| 215. Supply Chain Gate | 6/6 | Complete    | 2026-09-26 |
| 216. CI Platform Currency | 8/8 | Complete    | 2026-09-27 |
| 217. Repo Hygiene | 7/7 | Complete    | 2026-09-27 |
| 218. CI Economy: Remove Waste | 8/8 | Complete    | 2026-09-27 |
| 219. Deps-Only Build Cache | 2/3 | In Progress | - |
| 220. Newest-Toolchain Lane | 0/TBD | Not started | - |
| 221. CI Names and Order | 0/TBD | Not started | - |
| 222. SEED-006 Change-Aware Lanes | 0/TBD | Not started | - |

## Prior Milestones

<details>
<summary>v1.42 Capture Correctness for Real Table Shapes (Phases 208-213) - SHIPPED 2026-09-26</summary>

- [x] Phase 208: Identifier Foundation (5/5 plans)
- [x] Phase 209: Collision-Free Emission (6/6 plans)
- [x] Phase 210: PK-Agnostic Capture (5/5 plans)
- [x] Phase 211: Read-Side Agreement (4/4 plans)
- [x] Phase 212: Detection and Adopter Twins (7/7 plans)
- [x] Phase 213: Upgrade Guide and 0.11.0 Release (3/3 plans) — completed 2026-09-26

Capture that is correct for every primary-key shape, schema and name length. Collision-free per-table functions fix the shared-function security issue, and history/as-of reads match exactly. Health findings detect broken capture. There is an upgrade guide with real-PG-proven backfill SQL. 28/28 requirements. Released as 0.11.0 (#52, #53, #54). Archive: `.planning/milestones/v1.42-ROADMAP.md`.

</details>

<details>
<summary>v1.41 Green, Clean, and Honest (Phases 198-207) - SHIPPED 2026-09-24</summary>

Repo hygiene and quality ratchet: real Credo/Dialyzer/xref gates, `mix test` 83 failures to 0 on CI, suite independent of `.planning/`, clean public surface, 0.10.0 and 0.10.1 on hex.pm, installer and `gen.triggers` rerun fixes (0.10.2 CHANGELOG entry, unreleased). 53/54 requirements; GREEN-07 accepted-pending (D-39). Archive: `.planning/milestones/v1.41-ROADMAP.md`.

</details>

<details>
<summary>v1.40 Automated Operator-UI Critique & Forward-Only Iteration Harness (Phases 194-197) - SHIPPED 2026-08-27</summary>

- [x] Phase 194: Deterministic Scorecard-Cube Ledger & Mechanical Capture Foundation (3/3 plans) — completed 2026-07-03
- [x] Phase 195: Validated Adversarial Critic Runner & Panel (9/9 plans) — completed 2026-08-26
- [x] Phase 196: Forward-Only Net-Positive Gate & First Proven Iteration (6/6 plans) — completed 2026-08-26
- [x] Phase 197: Coverage Growth, Adversarial Closeout & Design-Debt Register (3/5 plans; 03/04 waived on a ratified PROOF-02 shortfall) — completed 2026-08-27

28/29 requirements satisfied. The paid critic loop is PARKED on ratified spend/value grounds; residual design debt lives in `197-DESIGN-DEBT-REGISTER.md` with owner and reopen-trigger per row. Archive: `.planning/milestones/v1.40-ROADMAP.md`.

</details>

<details>
<summary>v1.39 Quality Baseline, Schema Confidence, and CI Efficiency (Phases 189-193) - SHIPPED 2026-07-03</summary>

Repo-evidence quality-risk ranking followed by high-confidence fixes to the three weakest surfaces: configurable PostgreSQL `storage_schema` behavior proven end-to-end, release/docs version truth reconciled to `0.9.0` behind a drift-guard test, and measured CI/CD efficiency work behind contract guards. 15/15 requirements. Archive: `.planning/milestones/v1.39-ROADMAP.md`.

</details>

<details>
<summary>v1.38 Operator UI Page-by-Page IA & Design-System Polish (Phases 181-188) - SHIPPED 2026-06-30</summary>

Baseline guard repair, PhoenixStorybook example/dev lane, shell/Home orientation, Timeline investigation flow, Coverage readiness, detail/governance/export surface polish, accessibility/motion/docs closeout, and Phase 188 audit-gap closure. Archive: `.planning/milestones/v1.38-ROADMAP.md`.

</details>

<details>
<summary>v1.37 Operator Surface Design-System Stress Test & Component System (Phases 171-180) - SHIPPED 2026-06-20</summary>

Internal component system, `/audit/__stress`, design-system ledger, shell/navigation/theme picker, page stress coverage, microcopy/IA normalization, WCAG/APG/motion guardrails, accessibility-tree evidence, and adversarial closeout. Archive: `.planning/milestones/v1.37-ROADMAP.md`.

</details>

<details>
<summary>v1.36 Operator Surface Light Mode (Phases 166-170) - SHIPPED 2026-06-14</summary>

`theme: :dark | :light | :system` host config and pure-CSS light/system lanes. Archive: `.planning/milestones/v1.36-ROADMAP.md`.

</details>
