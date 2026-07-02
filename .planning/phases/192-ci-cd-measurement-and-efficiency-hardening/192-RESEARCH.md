# Phase 192: CI/CD Measurement and Efficiency Hardening - Research

**Researched:** 2026-07-02
**Domain:** GitHub Actions CI/CD (Elixir/OTP/Postgres matrix, caching, concurrency, branch protection), static-parse contract testing
**Confidence:** HIGH — every claim below is ground-truthed against the live files, `gh api` against `szTheory/threadline`, or a cited GitHub/vendor source. Discrepancies vs. CONTEXT.md are called out explicitly.

## Summary

CONTEXT.md's 27 locked decisions are, with two precision caveats, **accurate against the live tree**. This research does not re-litigate them; it (1) confirms the exact file anchors the plans will edit, (2) nails down the three risky mechanics the plans depend on (matrix check-run naming, `actions/cache` scoping, `setup-node` cache path), and (3) specifies the Validation Architecture so the planner can split auto-verifiable from human-gated work.

Two findings materially sharpen the plan and must not be glossed:
1. **"On every job" (D-06) is really 8 of 10 jobs.** `verify-hex-evaluator` runs no *root* `mix deps.get` (it resolves a nested hex project) and `verify-release-shape` has no `setup-beam`/`deps.get` at all — neither gains anything from a root `deps/` cache.
2. **CONTRIBUTING has TWO distinct lists**, not one. The "Stable job keys" table (8 rows, `CONTRIBUTING.md:120-129`) is what D-25 fixes 8→10. The "Branch protection" **required-checks** list (7 rows, `CONTRIBUTING.md:177-183`, with `Run test suite (verify-test)` at line 179) is what D-19 renames. These are different lists with different membership and purpose; D-25's phrase "documented required-checks list matches all 10 jobs" conflates them — the *required-checks* list is intentionally a **subset** and stays one.

**Primary recommendation:** Plan two waves. Wave A = read-only baseline (`192-BASELINE.md`) with zero workflow edits (D-05 observer-effect ordering). Wave B = one coherent change set (ci.yml matrix + concurrency + pgbouncer pin, flake-detection deps cache, CONTRIBUTING both-lists fix, phase06 contract-test extensions, min-lane dep-floor guard) landing together, with branch-protection reconfiguration coordinated against the PR that first posts the new matrix check names (D-19/D-27).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Run-history measurement | CI provider (GitHub Actions API) | Local `gh`/`jq` script in `.planning` | Data lives in GitHub's runs/jobs API; script is throwaway, never in CI (D-02, Claude's discretion) |
| Dependency/browser caching | CI runner (`actions/cache`) | — | Caches are runner-local artifacts keyed off in-repo lockfiles; never change *what* runs (D-06/07/08/12) |
| Compatibility gating | CI matrix on `verify-test` | Branch protection (GitHub settings) | Matrix produces the checks; branch protection decides which are required (D-15/D-19) |
| Doc/workflow alignment | In-repo docs + `phase06` contract test | — | Static-parse test locks ci.yml ↔ header ↔ CONTRIBUTING ↔ mix.exs (D-25/D-26) |
| Release publish serialization | `release.yml` publish job concurrency | `publish-hex` idempotency + `gate-ci-green` | Job-level concurrency keeps bookkeeping independent; idempotency is the real race guard (D-24) |

## Ground-Truth Confirmation of Canonical Refs

Legend: ✅ confirmed as CONTEXT.md states · ⚠️ confirmed with a precision caveat the planner must honor · ❌ discrepancy.

### `.github/workflows/ci.yml` — 10 jobs, no `needs:`, no concurrency
- ✅ Header job-id contract comment lists all 10 keys `[VERIFIED: ci.yml:1-2]`.
- ✅ 10 jobs, all parallel (zero `needs:`), single pinned lane `elixir 1.17.3 / otp 27.0`, no `concurrency:` block `[VERIFIED: ci.yml]`.
- ✅ `edoburu/pgbouncer:latest` at **line 225**, the only `:latest` in the file `[VERIFIED: ci.yml:225]`. `POOL_MODE=transaction` (229), `AUTH_TYPE=scram-sha-256` (228) — untouched by D-22.
- ✅ `verify-test` is the matrix target; `runs-on: ubuntu-24.04` (73), `postgres:16` service hardcoded (79).
- ⚠️ **`verify-test` runs SIX steps, not two.** `mix deps.get` (100) → `mix compile --warnings-as-errors` (103) → `verify.test` (106) → `verify.threadline` (109) → createdb (114) → `verify.example` (118) → `verify.doc_contract` (121). D-18 scopes the **min lane** to compile + test only. Mechanic: the four extra steps (`verify.threadline`, createdb, `verify.example`, `verify.doc_contract`) must be gated `if: matrix.lane == 'current'` (or equivalent), and the service image / runner must become matrix-driven: `image: postgres:${{ matrix.pg }}`, `runs-on: ${{ matrix.runner }}`. GitHub Actions permits `matrix` context in both `services.*.image` and `runs-on` `[CITED: docs.github.com/actions matrix contexts]`.
- ⚠️ **Which jobs actually gain a root `deps/` cache (D-06):** jobs that run a *root* `mix deps.get` — `verify-format` (32), `verify-credo` (49), `verify-compile-no-optional` (66), `verify-test` (100), `verify-example-browser` (193, "Install root dependencies"), `verify-pgbouncer-topology` (257, inside a `run` block), `verify-docs` (284), `verify-hex-package` (301). **`verify-hex-evaluator` has NO root `deps.get`** (144-158: `setup-beam` → createdb → `verify.hex_evaluator`, whose deps resolve inside `priv/ci/hex_evaluator`) — a root `deps/` cache is moot for it. **`verify-release-shape` has no `setup-beam` and no `deps.get`** (345-352) — nothing to cache. So "every job" = **8 jobs**, not 10.

### `.github/workflows/release.yml`
- ✅ Workflow-level `concurrency` at **line 40**: `group: release-${{ github.event_name }}-${{ github.run_id }}` — `run_id` makes every run unique → effective no-op, exactly as D-24 states `[VERIFIED: release.yml:39-41]`.
- ✅ `gate-ci-green` polls `maxAttempts=60`, `waitMs=30000` (60×30s) and keys on **workflow-run conclusion** (`run.conclusion === 'success'`, line 263), **not** per-job checks — so the D-19 matrix rename does not affect it `[VERIFIED: release.yml:233,234,263]`.
- ✅ `publish-hex` idempotency skip guard: `mix hex.info threadline <ver> | grep Released` → `skip=true` (321-328) `[VERIFIED: release.yml:321-328]`.
- ✅ Release-PR CI dispatch `gh workflow run ci.yml --ref release-please--branches--main` at **line 112** (job `bootstrap-release-pr-ci`, 100-112) `[VERIFIED: release.yml:112]`.
- D-24 target: add a **publish-job-level** `concurrency: { group: release-publish-${{ github.ref }}, cancel-in-progress: false }` on the `publish-hex` job (276), leaving the workflow-level group to keep `release-please` bookkeeping independent. Note the existing no-op workflow group can be left or removed; D-26 will assert publish-level group present + free of `run_id`.

### `.github/workflows/flake-detection.yml`
- ✅ Single job `verify-flake`, cold `mix deps.get` at **line 48** `[VERIFIED: flake-detection.yml:48]`. In scope for the `deps/` cache (D-06 "incl. flake-detection.yml").

### `.github/workflows/hex-publish.yml`
- ✅ Legacy tag-only fallback; `mix deps.get` at line 30 but **out of D-06 scope** (rare tag path, not PR-perf-critical). CONTEXT.md lists it "untouched; verify no interference" — confirmed: it shares no cache keys with ci.yml and is not edited.

### `examples/threadline_phoenix/e2e/run-e2e.sh`
- ✅ `cd "$E2E_DIR"` then `npm ci` (when lockfile present) / `npm install` else, then `npx playwright install chromium` (105-111) `[VERIFIED: run-e2e.sh:105-111]`. cwd is `e2e/`.
- ✅ **`examples/threadline_phoenix/e2e/package-lock.json` exists** (2205 B) and pins `@playwright/test` (`package.json` declares `^1.52.0`; the lockfile pins the resolved version → correct cache key for the browser version, D-07). **No root `package-lock.json` anywhere** `[VERIFIED: filesystem find]` — this is the exact precondition that makes D-08's `cache-dependency-path` mandatory.

### `mix.exs`
- ✅ `elixir: "~> 1.15"` at **line 28** (D-14 says do NOT raise this) `[VERIFIED: mix.exs:28]`.
- ✅ `dialyzer: [plt_add_apps: [:mix]]` at **line 38** — configured, **never invoked in any workflow** (grep of all four workflows: no `mix dialyzer`). Confirms D-11's corrected rationale (PLT caching is a no-op, not a warnings argument) `[VERIFIED: mix.exs:38 + workflow grep]`.
- ✅ `"ci.all"` alias (98-110) ordering: format → credo → compile-strict → compile_no_optional → test → threadline → example → doc_contract → example_browser. `preferred_envs: ["ci.all": :test]` (11-13). Local `mix ci.all` is the reproducibility anchor (D-12).
- ⚠️ **`verify-compile-no-optional` is `mix compile --no-optional-deps --warnings-as-errors`** (alias line 93; job 54-69). D-20 says preserve it standalone — it is a *separate job*, not part of the version matrix; the matrix work must not fold it in.

### `test/threadline/phase06_nyquist_ci_contract_test.exs`
- ✅ Async (`async: true`, line 3), static-parse only (`File.read!`), no network — safe to extend (D-26) `[VERIFIED: test file:3]`.
- ✅ Existing assertions the extensions must not break: job-key presence for `verify-format/credo/test/pgbouncer-topology` (15-18); `push`/`pull_request` `branches: [main]` (20-28); `ci.all` **ordering** `verify.test < verify.threadline < verify.example < verify.doc_contract` (55-61); CONTRIBUTING contains the four job keys + Actions URL (91-100). **These do not currently assert `verify-hex-evaluator`/`verify-example-browser` presence** — so adding those two to the CONTRIBUTING table is purely additive.

### `CONTRIBUTING.md` — TWO lists (the highest-value nuance)
- ⚠️ **List 1 — "Stable job keys" table** (`CONTRIBUTING.md:120-129`): lists **8** jobs (`verify-format`, `verify-credo`, `verify-compile-no-optional`, `verify-test`, `verify-pgbouncer-topology`, `verify-docs`, `verify-hex-package`, `verify-release-shape`). Missing: **`verify-hex-evaluator`, `verify-example-browser`**. This is the list D-25 repairs 8→10 to match the header comment + all 10 `jobs:` keys `[VERIFIED: CONTRIBUTING.md:120-129]`.
- ⚠️ **List 2 — "Branch protection (maintainers)" required checks** (`CONTRIBUTING.md:173-185`): 7 checks, each shown as `<display name> (<job key>)`. Line **179** = `Run test suite (\`verify-test\`)` — the string D-19 must rewrite to the two matrix names. This list is a deliberate **subset** (it omits `verify-compile-no-optional`, `verify-hex-evaluator`, `verify-example-browser`) and **should remain a subset** — D-25 does not add rows here. Do not conflate List 1 and List 2 `[VERIFIED: CONTRIBUTING.md:173-185]`.
- Dev-env header (5-9) already states Elixir 1.15+/OTP 26+/PG 14+ — D-13's declared contract is **partly present**; D-13 asks to make it explicit in README + a `mix.exs` comment (README/mix.exs still need the min/current split spelled out).

## Risky Mechanics (verified)

### M1 — Matrix check-run naming (D-19 crux) `[VERIFIED: gh api + community docs]`
GitHub composes a matrix job's check-run/display name as `<name-or-jobid> (<matrix values, comma-joined>)`. Confirmed behavior:
- **No `name:`** → `verify-test (min)` style using the job id.
- **Static `name: "Run test suite"`** → GitHub **still appends** the matrix suffix → `Run test suite (<values>)`. A static name **cannot suppress** the suffix (D-19's claim is correct) `[CITED: github.com/orgs/community/discussions/9918]`.
- **`name:` with a matrix expression** → GitHub uses the interpolated string verbatim, no extra suffix.

**To produce exactly `Run test suite (min)` / `Run test suite (current)` — two reliable constructions:**
- **(A) base axis + include (recommended):** `strategy.matrix.lane: [min, current]` plus `include:` entries keyed by `lane` that carry `elixir/otp/pg/runner`. **Keys introduced only via `include` do NOT contribute to the auto-suffix** — only the base axis `lane` does — so a static `name: Run test suite` yields suffix `(min)` / `(current)`.
- **(B) explicit interpolation:** keep pure `include:` but set `name: Run test suite (${{ matrix.lane }})`.

**Anti-pattern (breaks D-19):** pure `strategy.matrix.include` with NO base axis and a static name → GitHub appends **all** the include values → `Run test suite (1.15, 26, 14, ubuntu-22.04)` — which will not match the two documented required checks and will block PRs forever. The planner MUST specify construction (A) or (B) explicitly, and the D-26 contract test asserts the resulting two names.

### M2 — `actions/cache@v4` for `deps/` with `restore-keys` (D-06) `[VERIFIED: cache semantics + repo state]`
Key `${{ runner.os }}-mix-deps-${{ hashFiles('mix.lock') }}` with a `restore-keys: ${{ runner.os }}-mix-deps-` prefix. Safe because: `deps/` holds **source only** (compiled beam lands in `_build`, NOT cached — D-10); both matrix lanes fetch byte-identical source from the same committed `mix.lock`; on a partial `restore-keys` hit `mix deps.get` reconciles to the lock. No cross-lane poisoning. `erlef/setup-beam@v1` ships **no** built-in dependency cache, so an explicit `actions/cache` step is required. `runner.os` in the key auto-separates the `ubuntu-22.04` (min) and `ubuntu-24.04` (current) lanes only if they differ by OS string — both report `Linux` for `runner.os`, so add the runner or elixir/otp to the key if lane isolation of the cache is desired (source is identical, so sharing is acceptable; scope only if you want per-lane hit metrics).

### M3 — `setup-node@v5` `cache: npm` requires `cache-dependency-path` (D-08) `[VERIFIED: filesystem + vendor issue]`
`setup-node` with `cache: npm` searches for a lockfile at the **repo root** by default; with none present it **fails the job** with `Error: Dependencies lock file is not found` `[CITED: dev.to/imomaliev TIL; actions/setup-node monorepo guidance]`. There is no root `package-lock.json` (only `examples/threadline_phoenix/e2e/package-lock.json`), so the `verify-example-browser` `setup-node` step (188-190) MUST set `cache-dependency-path: examples/threadline_phoenix/e2e/package-lock.json`. Since `npm ci` wipes `node_modules`, cache the npm **download** dir (setup-node's built-in npm cache does this), not `node_modules` (D-08). Keep this key scoped to the e2e subtree, never folded into the root `mix.lock` key (D-09).

### M4 — Playwright browser cache (D-07)
Cache `~/.cache/ms-playwright` on `verify-example-browser`, keyed on `hashFiles('examples/threadline_phoenix/e2e/package-lock.json')` (the lock pins `@playwright/test`, which determines the Chromium build). `npx playwright install chromium` still runs (D-12 — speed only), populating/refreshing the cache.

### M5 — Min-lane runtime resolution (D-17) — **manual/external verify**
Whether `elixir 1.15 / otp 26` resolves on `ubuntu-22.04` via `erlef/setup-beam@v1` cannot be proven statically; setup-beam consumes precompiled OTP/Elixir builds and availability is OS-version-specific. `ubuntu-22.04` is the runner with guaranteed OTP-26-era precompiled builds (24.04 dropped some older OTP prebuilds), which is why D-17 pins the min lane there. **This requires the throwaway matrix run D-17 already mandates** — treat as a human-gated preflight, not an in-repo assertion. `[ASSUMED — availability table not fetched this session; the plan already gates it behind a live run]`

## CI Concurrency (D-23)
Add to `ci.yml` top level: `concurrency: { group: ${{ github.workflow }}-${{ github.ref }}, cancel-in-progress: ${{ github.event_name == 'pull_request' }} }`. Cancels superseded **PR** runs only; the release-PR bootstrap dispatch is `workflow_dispatch` on `ref = release-please--branches--main` and push-to-main runs land in distinct groups → never cancelled → `gate-ci-green` (keys on `head_sha`) unaffected. Confirmed against the release.yml dispatch path.

## Baseline Feasibility (CI-01 / D-02, D-03, D-04) — measured this session

All numbers below are from live `gh api` against `szTheory/threadline`:
- **`ci.yml` run history depth:** `total_count = 96` `[VERIFIED: gh api workflows/ci.yml/runs]`. Contradicts any "no historical DB" assumption (CONTEXT.md is right).
- ⚠️ **Recent history is red-heavy.** Of the most recent 15 runs, only ~2 are `success` (successes cluster around 2026-06-07; the 2026-06-26 cluster is all `failure`). A naive "last 15 runs" sample would be almost all red. **The D-02 "last ~15 GREEN runs, one event type" filter must page deeper than the last 15 total runs** — the aggregation script should query `?status=success&event=push` (or `pull_request`) and page until it collects ~15 green runs. Flag for the baseline script (Claude's discretion, but note the depth requirement).
- **Per-job/step timing endpoint works:** `gh api repos/szTheory/threadline/actions/runs/{id}/jobs` returns `started_at`/`completed_at` per job `[VERIFIED]`. Spot-check of green run `27082048346`: browser lane `Example app browser E2E (Playwright)` ran ~344s; total run ~349s (**5m49s**); `Run test suite` 256s. **Confirms D-05's "browser lane ≈ 98% of ~5m52s critical path" and the parallel-fan-out picture.**
- ⚠️ **Jobs endpoint returns display `name`, not job key.** The aggregation must map name→key (e.g. `Run test suite` → `verify-test`, `Example app browser E2E (Playwright)` → `verify-example-browser`) when building the D-03 table.
- **Flaky/rerun signal is sparse:** every run in the recent window has `run_attempt=1` — few/no reruns to count. D-03's `run_attempt>1` column will likely read "0 reruns observed in sampled window"; record honestly (not a bug).
- **Billed minutes = unavailable (D-04 confirmed):** `gh api .../actions/workflows/ci.yml/timing` returns `{"billable":{}}` (empty) for this public repo `[VERIFIED]`.
- **Cache-hit rate = N/A (D-04 confirmed):** no `actions/cache` configured today, so no restore/save telemetry exists.

`192-BASELINE.md` should mirror `.planning/phases/189-.../189-QUALITY-AUDIT.md` frontmatter (`phase/artifact/audited/scope/requirements/status/source_precedence` + ranked table) `[VERIFIED: 189 template read]`. Each unavailable/deferred row carries the DNA Nyquist-debt shape — **owner, date, superseding-evidence pointer, reopen trigger** (D-04, `threadline-elixir-oss-dna.md:16`), not a bare "unavailable".

## Package / Action Legitimacy Audit

This phase installs **no new npm/hex/registry packages**. It uses only first-party GitHub Actions:
| Action | Status | Note |
|--------|--------|------|
| `actions/cache@v4` | OK — GitHub-official | New usage; the only added action. Current major is v4. |
| `actions/setup-node@v5` | OK — already in use | `verify-example-browser` (ci.yml:188); adds `cache`/`cache-dependency-path` inputs only. |
| `erlef/setup-beam@v1` | OK — already in use | Erlang Ecosystem Foundation; unchanged. |

No SLOP/SUS risk; no registry legitimacy gate needed. No `postinstall` surface (these are Actions, not npm deps).

## Validation Architecture

> Nyquist is enabled. Split of what's auto-verifiable vs. human-gated so the planner can populate Dimension-8 validation and mark external steps explicitly.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir), static-parse pattern in `test/threadline/phase06_nyquist_ci_contract_test.exs` (`async: true`, no network) |
| Quick run | `mix test test/threadline/phase06_nyquist_ci_contract_test.exs` |
| Full suite | `mix verify.test` / `MIX_ENV=test mix ci.all` |
| Phase gate | Full suite green before `/gsd-verify-work`; the extended contract test must be green in the same change set (D-27) |

### Auto-verifiable — extend `phase06_nyquist_ci_contract_test.exs` (D-26, additive static-parse)
| Assertion | Source of truth | Ties to |
|-----------|-----------------|---------|
| Job-key parity: 10 keys across `ci.yml` `jobs:` ↔ header comment (lines 1-2) ↔ CONTRIBUTING "Stable job keys" table | ci.yml + CONTRIBUTING List 1 | D-25 |
| No `:latest` in **any** of the four workflow files | `.github/workflows/*.yml` | D-22 |
| `ci.yml` has a PR-scoped `concurrency` block (`cancel-in-progress` gated on `pull_request`) | ci.yml | D-23 |
| `release.yml` publish job has a concurrency group present and **free of `run_id`** | release.yml publish-hex | D-24 |
| The two matrix check names (`Run test suite (min)` / `Run test suite (current)`) appear in ci.yml (via construction A/B) **and** in CONTRIBUTING List 2 line 179 | ci.yml + CONTRIBUTING List 2 | D-19 |
| `verify-compile-no-optional` job still present and standalone (not folded into matrix) | ci.yml | D-20 |

### Auto-verifiable — new guard test (D-16) — **highest implementation uncertainty**
Goal: fail **loudly at the lock**, not mid-CI, if a locked dep floors above Elixir 1.15. **Open problem:** `mix.lock` records versions + hashes, **not** per-dep Elixir requirements — a pure static parse of `mix.lock` cannot read `elixir:` floors. Viable resolutions for the planner to choose (Claude's discretion notes it may be new file or contract-test extension):
- **(a)** After `mix deps.get`, inspect each `deps/*/mix.exs` for its `elixir:` requirement and assert none exceeds `~> 1.15`. Requires deps fetched (not pure static) — runs as a test that shells/reads `deps/`.
- **(b)** Treat the **min CI lane itself** as the guard (it goes red if a dep floors >1.15). This does NOT satisfy D-16's "loudly at the lock" intent (failure surfaces mid-CI), so pair it with a comment/CHANGELOG note, or prefer (a).
- **(c)** Maintain nothing extra and accept the min lane as the only signal (weakest; D-16 explicitly wants the loud-at-lock guard). 
Recommend **(a)**. Flag this as the one decision the plan must resolve concretely; do not leave it as "add a guard test" without specifying the mechanism.

### Human-gated / external (cannot be asserted by an in-repo test)
| Step | Why manual | Ties to |
|------|-----------|---------|
| Branch-protection required-checks reconfiguration (drop `Run test suite (verify-test)`, add `Run test suite (min)` + `(current)`) | GitHub repo settings, not in-repo; the PR must first POST the new check names before a maintainer can select them | D-19, D-27 |
| Throwaway matrix run confirming `elixir 1.15 / otp 26` resolves on `ubuntu-22.04` | Runtime availability, not a static fact | D-17 |
| Run-history aggregation producing `192-BASELINE.md` numbers | One-time `gh`/`jq` script in `.planning`, not CI | D-02 |

### Honest "unavailable" boundaries (record, do not assert) — D-04
- Billed minutes: `{"billable":{}}` empty for public repo.
- Cache-hit rate: N/A pre-Wave-B (no cache today); becomes measurable in Phase 193 after Wave B.
- Rerun/flaky rate: recent sampled window shows `run_attempt=1` only → "0 reruns in sampled window," not a measurement failure.

### Requirement → verification map
| Req | Behavior | Verification | Automated? |
|-----|----------|--------------|-----------|
| CI-01 | Baseline artifact with critical path, setup cost, browser lane, cache state, flaky signal | `192-BASELINE.md` from `gh api` (measured feasible this session) | Manual script (D-02) |
| CI-02 | Cache/setup speedups that never change what runs, no `_build` cache, no warning-masking | `deps/` + Playwright + npm cache blocks; `mix ci.all` unchanged locally | Partial: contract test asserts blocks present; parity is by construction |
| CI-03 | pgbouncer pin, release concurrency, branch-protection docs, job names, `mix ci.*` aligned & testable | phase06 extensions (D-26) | ✅ auto (except branch-protection reconfig = manual) |
| CI-04 | Explicit min/current Elixir/OTP/PG policy; only justified lanes | Matrix names + dep-floor guard + README/mix.exs comment | ✅ auto (except D-17 throwaway run = manual) |

## Sequencing Constraints (planner MUST honor)

1. **Baseline is read-only and lands FIRST (D-05).** No workflow edits during CI-01 — the baseline must capture the cache-absent, deps×N, browser-dominated state so Phase 193 has a clean before/after. Two waves: Wave A (baseline) → Wave B (edits).
2. **Wave B ships as ONE coherent change set (D-27).** ci.yml (matrix + concurrency + pgbouncer pin) + flake-detection.yml (deps cache) + release.yml (publish concurrency) + CONTRIBUTING (both lists) + phase06 extensions + dep-floor guard land together. Splitting them "born-reds" a test (the new-matrix-name assertion is red until ci.yml has the matrix; the CONTRIBUTING parity assertion is red until the table is fixed).
3. **Branch-protection reconfig is a coordinated human step within Wave B (D-19).** Chicken-and-egg: the required check `Run test suite (verify-test)` will stop posting the moment the matrix lands, so PRs block forever unless branch protection is updated to the two new names. Safe order: the Wave-B PR runs and POSTS `Run test suite (min)` / `(current)`; a maintainer updates required checks to those names (removing the old one) just-in-time (or admin-merges), then merge. Document this explicitly as a maintainer checklist item — it is not automatable.

## Common Pitfalls

1. **Pure `matrix.include` with static name** → check names become `Run test suite (1.15, 26, ...)`, breaking branch protection. Use base-axis-`lane` + include, or `name:` interpolation (M1).
2. **`setup-node` `cache: npm` without `cache-dependency-path`** → hard job failure `Dependencies lock file is not found` (no root lockfile) (M3).
3. **Applying all six `verify-test` steps to the min lane** → false reds from 1.15↔1.17 deprecation deltas in `verify.example`/doc-contracts. Gate extras `if: matrix.lane == 'current'` (D-18).
4. **Caching `_build`** → masks `--warnings-as-errors`, cross-`MIX_ENV` bleed. Declined (D-10) — keep declined.
5. **Collapsing `release.yml` to a workflow-level concurrency group** → serializes `release-please` bookkeeping behind 30-min publishes (D-24 regression). Scope to publish job only.
6. **Editing List 2 (branch-protection required checks) to add all 10 jobs** → over-reach; it is intentionally a subset. Only rename the `verify-test` entry (D-19); the 8→10 fix is List 1 only (D-25).
7. **Sampling "last 15 runs" for the baseline** → mostly red in the current window; page to 15 *green* runs of one event type (Baseline section).

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gh` CLI (authed as `szTheory`) | D-02 run-history aggregation | ✓ | 2.95.0, keyring auth active | — |
| `gh api` runs/jobs endpoints | D-02/D-03 timing | ✓ | 96 runs, jobs timing confirmed | Mark rows unavailable per D-04 |
| `jq` | aggregation script | ✓ (used inline this session) | — | inline `--jq` |
| GitHub Actions billing API | D-04 billed minutes | ✗ (empty for public repo) | — | Record "unavailable" with reopen trigger |
| `ubuntu-22.04` runner w/ OTP 26 prebuild | D-17 min lane | ? unverified | — | Throwaway matrix run (human-gated) |

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| A1 | `elixir 1.15 / otp 26` resolves on `ubuntu-22.04` via setup-beam | M5 / D-17 | Min lane can't provision → pick a different runner or OTP patch; already gated behind D-17 throwaway run |
| A2 | `include`-only matrix keys do not contribute to the check-name suffix (only base axes do) | M1 | If wrong, construction (A) yields ugly names; construction (B) name-interpolation is the safe fallback and should be preferred if any doubt |

## Open Questions

1. **Dep-floor guard mechanism (D-16).** `mix.lock` cannot express Elixir floors statically. Recommend option (a): post-`deps.get` inspection of `deps/*/mix.exs`. The plan must specify this concretely, not defer it. (See Validation Architecture.)
2. **Baseline event-type filter (D-02).** Choose `push` or `pull_request` for the p50/p95 sample and page to ~15 green — recent window is red-heavy. Recommend `push` on `main` (most stable, and honors the path-filter+main invariant that main always runs the full set).
3. **deps/ cache key lane isolation.** `runner.os` is `Linux` for both lanes, so the base key does not separate min/current. Source is identical so sharing is safe; add `matrix.lane` to the key only if per-lane cache-hit metrics are wanted in Phase 193.

## Sources

### Primary (HIGH — ground-truthed this session)
- Live files: `.github/workflows/{ci,release,flake-detection,hex-publish}.yml`, `mix.exs`, `CONTRIBUTING.md`, `test/threadline/phase06_nyquist_ci_contract_test.exs`, `examples/threadline_phoenix/e2e/{run-e2e.sh,package.json,package-lock.json}`, `.planning/phases/189-.../189-QUALITY-AUDIT.md`.
- `gh api repos/szTheory/threadline/actions/...` — 96 ci.yml runs, per-job timing on run `27082048346`, empty billing.

### Secondary (MEDIUM — cited)
- Matrix job naming: github.com/orgs/community/discussions/9918.
- setup-node cache lockfile path: dev.to/imomaliev "TIL: Fix Dependencies lock file is not found"; actions/setup-node monorepo guidance.

### Tertiary (LOW)
- setup-beam OTP/Elixir prebuild availability per runner — not fetched; deferred to the D-17 throwaway run.

## Metadata

**Confidence breakdown:**
- File anchors / discrepancies: HIGH — read directly, line-cited.
- Baseline feasibility (D-02/03/04): HIGH — measured via gh api this session.
- Matrix naming (M1) / setup-node (M3): HIGH — behavior confirmed + cited; construction (A)/(B) both documented.
- Min-lane runtime resolution (M5/D-17): LOW — inherently a live-run check; already gated.

**Research date:** 2026-07-02
**Valid until:** 2026-08-01 (stable domain; re-check GitHub run history counts and any Actions runner-image OTP-prebuild changes before Wave A).
