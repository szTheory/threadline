# Feature Research

**Domain:** CI/CD economy, supply chain and repo hygiene for a public Elixir Hex library (Threadline 0.11.0). Milestone v1.43 "Supply Chain, CI Economy and Repo Hygiene".
**Researched:** 2026-09-26
**Confidence:** HIGH for every measured number (each cites a GitHub Actions run ID or a file:line). MEDIUM for projected savings (arithmetic on measured numbers, labelled **[inference]**). LOW only where stated.

**Method.** `gh run list` over the 30 days 2026-08-27 → 2026-09-26 (280 runs), `gh run view --json jobs` for per-job and per-step durations, full job logs for the Flake Detection, CI and Browser runs cited, `mix hex.audit` / `mix hex.outdated` run locally against every tracked lockfile, `mix xref graph --format cycles`, and `git grep` over tracked files. Nothing in the repo was changed except this file.

---

## 0. Corrections to the pre-milestone baseline

Read these first. Four statements in PROJECT.md or the milestone guide are stale or wrong.

| Baseline statement | Measured today | Evidence |
|---|---|---|
| Flake Detection: "12 cancelled, 2 green (117–136 min)" | The timeout was already raised from 120 to 180 min (flake-detection.yml:41, comment cites run 35967937335). The two latest nightlies are green: **98.0 min** (36106137910) and **137.0 min** (36225676728). The fast-failure streak is longer than stated: it runs from **08-18 → 09-12** (at least 26 nightlies, e.g. 32110527200 … 34679766829), not 08-28 → 09-12. | `gh run list --workflow flake-detection.yml` |
| Only advisory: lazy_html 0.1.12 (test-only) | **Two advisories in root `mix.lock`**: lazy_html 0.1.12 (EEF-CVE-2026-92106, LOW, fixed in 0.1.13, published 2026-09-25) **and mint 1.10.0** (EEF-CVE-2026-82672 / GHSA-rj5m-69wp-cxq9, MEDIUM, response smuggling, fixed in 1.10.1, published 2026-09-19). mint is a runtime transitive dep via the optional `:req` (mix.exs:99; mix.lock:26). The tracked **`bench/mix.lock` has 8 advisories**: plug 1.19.1 ×4 (two HIGH), postgrex 0.22.0 ×3 (one HIGH), decimal 2.3.0 ×1. `examples/threadline_phoenix/mix.lock` is clean. | `mix hex.audit` exit 1 in root and in `bench/`; osv.dev entries |
| Guide §9a: "`mix xref graph --format cycles` is clean" | **5 runtime cycles of length 2** (e.g. `capture/audit_transaction.ex` ↔ `capture/audit_change.ex`, `investigation.ex` ↔ `threadline.ex`). **Compile-connected cycles: 0**, and that is **already gated** in CI: `mix verify.xref_cycles` (mix.exs, `--label compile-connected --fail-above 0`) runs in both test lanes (ci.yml:351-352). | local `mix xref graph --format cycles` |
| "xref cycles guard" is a v1.43 target | It shipped already (see above). What is left is only a decision about runtime cycles, and gating those is an anti-feature (§ Anti-Features). | ci.yml:351-352 |

---

## 1. Baseline table (cite this)

### 1a. CI workflow (`ci.yml`), per job

Samples: push-to-main 36258719902, 36257162368, 36256231845; PR 36255483521, 36258071425, 36256339043; release-PR dispatch 36256344029. All green. Durations are job start → end in seconds (step detail from 36258719902).

| Job (`name:`) | id | Duration (s), 7 samples | Where the time goes (36258719902) |
|---|---|---|---|
| Example app browser E2E (Playwright) | verify-example-browser | 453–651 (typ. ~635) | 103 s setup (example-app deps.get + compile, both uncached) + 8.4 min Playwright, 344 tests, **`workers: 1`** (playwright.config.ts:142) |
| Run test suite (current) | verify-test | 593–646 | compile 47 s, `mix test` 310 s (2,207 tests; 17.4 s async / 291.4 s sync), `verify.example` 203 s (109 s of example tests + example-app deps/compile) |
| Tier A capture lane (byte-stable evidence) | verify-capture | 439–541 | `verify.capture` 439 s (2 × 2.9 min Playwright captures + setup), then **`verify.mechanical` again: 50 s** (ci.yml:683-684) |
| Run test suite (min) | verify-test | 359–444 | compile 52 s, `mix test` 346 s |
| Bump rehearsal (next minor) | verify-bump-rehearsal | 149–171 | 128 s rehearsal (throwaway clone, cold deps by design, ci.yml:901-907) |
| PgBouncer transaction topology | verify-pgbouncer-topology | 98–125 | apt-get postgresql-client 13 s; compile 52 s |
| Mechanical checker (committed scorecards) | verify-mechanical | 84–93 | 50 s: runs `test/threadline/operator_surface/mechanical_checker_test.exs` |
| Dialyzer (current toolchain) | verify-dialyzer | 75–124 | compile 59 s; PLT hit → analysis ~8 s |
| Build ExDoc (dev) | verify-docs | 65–80 | `mix docs` 63 s (no `--warnings-as-errors`) |
| Run Credo (strict) | verify-credo | 55–80 | |
| Hex evaluator smoke (threadline from hex.pm) | verify-hex-evaluator | 64–75 | |
| Compile without optional deps | verify-compile-no-optional | 44–65 | |
| Check formatting | verify-format | 15–22 | |
| Hex package tarball | verify-hex-package | 15–17 | |
| Release metadata (version / changelog) | verify-release-shape | 5–8 | |
| CI required | ci-required | 2–5 | starts at +612 to +655 s |

**Per-run totals.** Sum of job durations: **46.0–50.2 runner-min** per CI run (billed with per-job rounding: 56–60). Wall clock: PR median **10.4 min** (n=60), push median **10.8 min** (n=21) over 30 days.

**Critical path.** All 14 jobs start within 36 s of each other (no `needs:` except the aggregate). The critical path is a near tie between **browser E2E (~10.6–10.9 min)** and **test suite current (~9.9–10.8 min)**, with Tier A capture (~8.7–9.0 min) close behind. Cutting wall time therefore needs *both* the browser job and the test-current job shortened; shortening only one moves the critical path by less than a minute. **[inference from the tie]**

**Dialyzer PLT.** Cold PLT build 148.49 s (34731370786), near-miss restore ~30 s (36254623336, 36256344029), analysis 5.7–9.5 s.

### 1b. Other workflows

| Workflow | Trigger | Measured | Evidence |
|---|---|---|---|
| Browser (full project set) | push to main | median 18.1 min, max 24.4 (n=20). Playwright 350 tests, **324 passed / 26 skipped, 16.1 min** | 36258719891 |
| Browser (full project set) | nightly 05:00 | 11.4–19.9 min when green (09-13 → 09-26); fast-failed 08-28 → 09-12 (median of 30 = 2.2 min) | 36220250465, 36097873196; issue #28 |
| Flake Detection | nightly 07:00 | first iteration 288 s, then ~165 s per repeat (flake-detection.yml:35-37); 1,698 tests/iteration in 35967937335 | see §2 |
| Release | push to main | 0.2–3 min when nothing to release; **~11 min of `gate-ci-green` polling** on a publishing push (643 s in 36257162356, 638 s in 35797666620) | |
| Branch Protection / Community Health / Environment Protection | schedule + workflow_run | ~0.2 min each | |

### 1c. Runner-minutes per unit of work

| Unit | Runner-min | Composition |
|---|---|---|
| One PR CI run | **~48** | 14 jobs + aggregate (§1a) |
| One push to main (no release) | **~69** | CI ~50 + Browser-full ~18 + Release 0.2 + 3 × workflow_run 0.6 |
| One landed PR (PR run + squash-merge push) | **~117** | |
| One release cycle (extra, on top of the landed PR) | **~200+** | release-please branch: 1 cancelled partial CI (e.g. 36256249852, 1.8 min wall) + **2 full CI runs on the same SHA** (~98) + pin sync 81 s + publish-push CI+Browser (~69) + gate poll ~11 + publish 80 s + smoke 61 s + distribution-sync PR CI (~46) **[inference: summed from 36256231909, 36256339043, 36256344029, 36257162356, 36258071425]** |

### 1d. 30-day totals (2026-08-27 → 2026-09-26, wall minutes from `gh run list`)

| Workflow / event | Runs | Wall-min | Runner-min (est.) |
|---|---|---|---|
| CI pull_request | 60 | 533 | ~2,450 **[inference: ×4.6 jobs-per-wall ratio from §1a]** |
| CI push | 21 | 222 | ~1,020 **[inference]** |
| CI workflow_dispatch (all release-PR bootstrap or manual) | 13 | 131 | ~600 **[inference]** |
| Flake Detection | 31 | **1,740** | 1,740 (single job) |
| Browser-full push | 20 | 343 | 343 |
| Browser-full schedule | 30 | 248 | 248 |
| Release push | 20 | 122 | ~122 |
| Hygiene workflows | 85 | ~17 | ~17 |

At the steady state now that Flake Detection completes (98–137 min per night), it costs **~3,000–4,100 runner-min/month** on its own. **[inference: 30 × measured range]** That would make it the single largest line item, bigger than all PR CI.

---

## 2. Flake Detection: why it failed fast, then got cancelled

**Phase A. Fast failures (08-18 → 09-12, 2.5–4.0 min each).** The scheduled run tests the default branch HEAD, which sat on `a97f527e` (and `67998e0b` before it) for weeks. That commit's suite was **deterministically broken**: run 34679766829 reports `1381 tests, 81 failures`, all `relation "threadline_saved_views" does not exist` / `relation "audit_changes" does not exist` (the unprefixed-storage-schema defect the maintainer memory records as fixed 08-30, and pushed to origin on 09-13). CI on push already showed that red, so the nightly **duplicated a failure class CI owns** and added no signal. No tracking issue was filed for any of these runs: issue #36 was first created 2026-09-13. The workflow's own comment (flake-detection.yml:83-91) describes an errexit defect that skipped classification. That this defect caused the missing issues is **[inference]**.

**Phase B. Cancellations (09-13 → 09-24, 120.3–120.5 min each).** The suite grew to 1,698 tests (~165 s per repeat). `--repeat-until-failure 50` means 51 runs, about 145 min, against a 120-min timeout, so the job was killed while still green (45 `Running ExUnit with seed` headers in 35967937335). On cancellation the repeat step never writes `exit_code`, so `bin/classify-flake-run` gets an empty EXIT_CODE and reports `unknown`. The issue body then claims "No `Running ExUnit with seed:` header was found", which is **false** (45 headers). That produced **11 misleading comments on issue #36** (09-14 → 09-24).

**Phase C. Green (09-25, 09-26)** after the timeout went to 180. Issue #36 is **still open** because `bin/upsert-ci-issue` has no close path (no `close` in the script). The same is true of Browser-full issue #28, open since 08-28 with 16 comments and green since 09-13.

**Signal delivered, lifetime:** 0 `flaky` classifications. 0 Playwright retries/flaky in the sampled browser runs. The only real finding (broken main) duplicated CI.

**Right-sized design (recommended):**
1. **Weekly, not nightly** (e.g. Sunday), plus `workflow_dispatch`. Skip if HEAD equals the SHA of the last green flake run.
2. **Bounded repeats:** `--repeat-until-failure 10`, about 288 + 10 × 165 s ≈ 32 min. Set the timeout to 2× that from measurement, not a guess.
3. **Pre-check:** if the latest `ci.yml` push run on this SHA is red, exit early with classification `broken-upstream` (no suite run). A broken main is CI's finding, not the flake lane's.
4. **Cancellation-aware classification:** a timeout is `inconclusive (timed out after N green iterations)`, never `unknown` with a false "no header" claim. Close the tracking issue on `pass`.
5. **Optional PR-side cheap probe [differentiator]:** repeat only *changed* test files N times on PRs (`mix test <changed files> --repeat-until-failure 20`). This catches new flakes at their source for seconds of runner time.

**Expected saving:** ~3,000–4,100 → ~140 runner-min/month (4.3 × ~32 min). That is **~95% of the lane**. **[inference]**

---

## 3. Duplicate-proof inventory (same failure class, proven more than once)

| # | Failure class | Proven by | Evidence | Verdict |
|---|---|---|---|---|
| D1 | Committed scorecards breach MODE-A/MODE-B | (a) `mix test` in **both** test lanes, (b) `verify-mechanical` job, (c) last step of `verify-capture` | mix.exs alias comment: "its test file already runs in `verify.test`"; ci.yml:683-684. In 30 days `verify-mechanical` failed 7 times, **always alongside a test-suite failure** (never a unique signal). | Delete the capture step (after the byte-stable assertion, regenerated evidence == committed evidence, so the check is identical). Fold or keep `verify-mechanical` only as a deliberate 90-s fast-signal job, and say so in its name. Saves 50 s on a near-critical job + ~87 runner-s/run. |
| D2 | desktop/mobile Chromium E2E regressions | CI `verify-example-browser` **and** Browser-full on the **same push SHA** | 344 vs 350 tests; 318 identical passes (36258719902 vs 36258719891) | Browser-full on push re-runs ~8.4 min of identical Playwright. |
| D3 | Tier A capture drift | CI `verify-capture` **and** Browser-full on the same push SHA | CONTRIBUTING.md:424-425; tier-a-capture 2.9 m + light 2.9 m in 36258719891 | ~5.8 min of identical Playwright per push. Browser-full has no byte-stability assertion, so its run is *weaker* than CI's. |
| D4 | Browser-full nightly re-testing an unchanged SHA | Every nightly 09-13 → 09-26 (14 runs) ran on a SHA that had already passed Browser-full on push (18fe87f5, 86852f98 ×9, 471ebf6e ×2, b37d7bd4 ×2) | run list §1b | 100% same-SHA repeats. Playwright browsers are cached by lockfile, so not even Chromium drifts. |
| D5 | Release PR CI | `pull_request` run (PAT-pushed pin commit) **and** `workflow_dispatch` run from `bootstrap-release-pr-ci` on the **same SHA** | Pairs: 0745a341 (36256339043 + 36256344029), 43cf7b45, 6ff12652, 2f5248b9, b4aa566e, 0d4c755b, ae7074a0, 560a470c, fc736ca1. `RELEASE_PLEASE_TOKEN` is configured (`gh secret list`), so the PAT push always fans out and the dispatch is redundant (release.yml:150-152, 171-188). 7 of the pairs were **double-red**. | ~49 runner-min per release-PR update, 13 dispatches in 30 days ≈ **~600 runner-min/month** and duplicate red checks. |
| D6 | Live Dialyzer warnings | `verify-dialyzer` job (cached PLT) **and** `test/threadline/dialyzer_slice_contract_test.exs:8-18` (`@tag :live_dialyzer`, 540 s timeout) shelling out to `MIX_ENV=dev mix dialyzer` (bin/verify-dialyzer-slice:274) in **both** test lanes | The tag is excluded nowhere (test_helper.exs excludes only `pgbouncer_topology`). The test lanes cache only `deps` (ci.yml:338-343), so they get a cold dev compile + cold PLT. Cold PLT alone = 148 s (34731370786). | Cost per lane is **not yet isolated**. The best bound is flake-detection.yml:35-37 (first iteration 288 s vs ~165 s warm repeats, ≤ ~2 min, which also includes other first-run effects) **[inference, MEDIUM]**. Measure with `mix test --slowest 20` before and after. |
| D7 | Tarball is buildable and contains `lib/` | `verify-hex-package` (hex.build + `lib/` grep), `verify-hex-evaluator` (builds this tree's tarball into a local rehearsal registry and **installs and runs** it, mix.exs:358-383), `verify-bump-rehearsal` (`mix hex.build` at next version, mix.exs:234-243) | | The evaluator is a strictly stronger proof than the `lib/` grep **[inference]**. `verify-hex-package` costs only 15 s, so this is a clarity win, not a minutes win. |
| D8 | ExDoc builds | `verify-docs` (`mix docs`, **no** `--warnings-as-errors`) and bump rehearsal (`mix docs --warnings-as-errors`, mix.exs:240) | ci_topology_contract_test.exs:98 pins that the `verify-docs:` id exists | The rehearsal is the stronger gate. `verify-docs` is ~77 s of weaker proof. Removing it needs the topology test and CONTRIBUTING changed in the same commit. |
| D9 | Suite broken on main | CI push run **and** nightly Flake Detection (Phase A, §2) **and** nightly Browser-full (fast-failed 08-28 → 09-12, issue #28) | | Handled by the §2 pre-check and D4 dedupe. |

**Not duplicates, keep:**
- The min lane caught **2 failures alone** (push 36084731591 on main, PR 36082981344), so it earns its minutes.
- Bump rehearsal owns the version-moved failure class (ci_topology_contract_test.exs:622-640).
- `verify.example` inside test-current is a different failure class.
- The PgBouncer lane is the only pooler proof.

---

## Feature Landscape

### Table Stakes (the milestone is incomplete without these)

| # | Feature | Why expected | Complexity | Measured saving / value | Notes |
|---|---|---|---|---|---|
| T1 | **Remediate advisories in every tracked lockfile** | Public library with a known MEDIUM (mint, runtime-transitive via optional `:req`) and LOW (lazy_html) advisory, plus 2 HIGH + more in `bench/mix.lock` | LOW | Clears 2 + 8 advisories | `mix deps.update lazy_html mint` (fixed: 0.1.13, 1.10.1). Refresh or regenerate `bench/mix.lock` (plug/postgrex/decimal). The example lock is clean today. |
| T2 | **`mix hex.audit` CI gate over all tracked lockfiles** | No audit gate exists (no `hex.audit`/`deps.audit` in `.github` or mix.exs). Dependabot alerts are **disabled** (API 404) | LOW | Blocks new advisories at PR time | `mix hex.audit` natively reports advisories, exits 1, and supports `hex: [ignore_advisories: [...]]` with "Ignored" reporting (verified via `mix help hex.audit`). No `mix_audit` needed. Run it in root, `examples/threadline_phoenix`, and `bench`. **Pitfall:** a newly published advisory turns unrelated PRs red. Pair the PR gate with a weekly scheduled audit that files or updates one issue, and require a justification comment next to every `ignore_advisories` entry (the same pattern as `.dialyzer_ignore.exs`). |
| T3 | **Right-size Flake Detection** (§2) | Largest single runner-minute line item. Zero `flaky` findings ever. 11 false-diagnosis comments | MEDIUM | ~3,000–4,100 → ~140 runner-min/month **[inference]** | Weekly + bounded repeats + skip-if-unchanged + a `broken-upstream` pre-check + timeout-aware classification + close-on-pass. Update `flake_classifier_contract_test.exs` together with it. |
| T4 | **Kill the release-PR double dispatch** (D5) | 2 identical full CI runs per release-PR update; double red checks | LOW | ~49 runner-min per release-PR update, ~600/month at the observed cadence | Dispatch only when the pin sync pushed **nothing** or pushed with GITHUB_TOKEN (no PAT). An output from `sync-release-pr-pins` (`pushed_with_pat=true`) gates `bootstrap-release-pr-ci`. Keep the `always()` so a failed sync still produces a red run. Covered by `release_ci_gate_contract_test.exs`. |
| T5 | **Browser-full stops re-running CI's projects** (D2, D3, D4) | ~14 of 16.1 Playwright minutes per push are identical to CI on the same SHA. Nightly runs are 100% same-SHA | LOW–MEDIUM | Push: ~18 → ~5 min (only storybook 9 s, graded 1.6 m, refute 6.5 s, route 6.4 s unique + ~2 min setup), ~260 runner-min/month. Nightly: skip when SHA already green on push, ~250–450/month | Change the `mix verify.example_browser` invocation to the 4 unique `--project` flags. Update the CONTRIBUTING "## CI Coverage" table and `ci_coverage_doc_contract_test.exs` in the same commit. Also consider weekly for these 4 critic-feeder capture lanes: the critic loop is parked and these specs carry 1–5 `expect(` each. |
| T6 | **Remove the uncached live-Dialyzer test from default `mix test`** (D6) | Duplicates the `verify-dialyzer` failure class. Cold PLT in 2 lanes per run | LOW | ≤ ~2 min × 2 lanes per CI run (~4 runner-min/run, ~375/month) **[inference, measure first]** | Either exclude `:live_dialyzer` in test_helper.exs and run the slice check inside `verify-dialyzer` (warm PLT), or give the test lanes the PLT cache. CLAUDE.md "honest default tests": test_helper.exs and docs must change together. |
| T7 | **Delete the mechanical-check duplicate** (D1) | Proven 3–4 times per run, never unique in 30 days | LOW | 50 s off verify-capture + ~87 runner-s/run if the job folds | Keep one fast signal and drop the rest. |
| T8 | **Local-path / PII guard in CI + forward scrub** | 295 tracked files contain `/Users/<user>/` (~890 occurrences), **all under `.planning/`**, 101 of them in `milestones/v1.41-phases`. Also 2 files **outside** `.planning` use home-relative `<home>/projects…` paths (`prompts/prior-art/SOURCE-CANONICAL.md`, `prompts/prior-art/accrue-planning-notes.md`). `/home/runner/` (350 hits) is CI-log noise and must be allow-listed | LOW–MEDIUM | Public-repo privacy (§13 of the guide) | The guard is a `git grep -nIP` (PCRE, because it needs the negative lookahead) over tracked files for `/Users/[^/]+/`, `/home/(?!runner/)[^/]+/`, `<home>/(projects|Documents|Desktop)`, `C:\\Users\\`, and email shapes, with a small explicit allowlist. Wire it as a fast job or a step in verify-format. Scrub forward only (no history rewrite) by replacing with repo-relative paths. The scrub touches 295 `.planning` files, so the maintainer memory's "never `git add .planning/`" rule means the scrub must stage an explicit file list. |
| T9 | **Honest, actionable job names (CI DX)** | "Hex evaluator smoke (threadline from hex.pm)" is **false** on PRs: it installs *this tree* from a local rehearsal registry (mix.exs:359-370). "Tier A capture lane (byte-stable evidence)" and "Mechanical checker (committed scorecards)" are internal jargon | LOW | Red check readable without logs (§9) | Rename via `name:` only (ids immutable). **Watch:** `ci-required`'s name is byte-pinned to the ruleset (ci_topology_contract_test.exs:669), and `verify-example-browser` name is deliberately byte-identical (ci.yml:495-497). |
| T10 | **Tracking issues close themselves on green** | #36 and #28 are open while their lanes are green (#28 green since 09-13) | LOW | Removes false-alarm noise | Add a `--close-on-pass` mode to `bin/upsert-ci-issue` and call it on the success path. The script has no close path today. |

### Differentiators (valuable, not required for the milestone to count)

| # | Feature | Value | Complexity | Expected saving | Notes |
|---|---|---|---|---|---|
| X1 | **Deps-only `_build` cache + example-app `deps`/`_build` cache** | Compile repeats in ~10 jobs (47–59 s each). The example app is compiled cold in 3 PR jobs (browser setup 103 s; `verify.example` ~90 s of its 203 s; capture) | MEDIUM | ~8–10 runner-min/run and ~1–1.5 min off **both** critical-path jobs **[inference, measure per job]** | Follow the CACHE KEY CONTRACT already written in ci.yml:65-93: runner + OTP + Elixir + lock hash, **no restore-keys**, `rm -rf _build/$MIX_ENV/lib/threadline` before compile. A separate key on `examples/threadline_phoenix/mix.lock`. |
| X2 | **Newest-toolchain lane** | Current lane pins Elixir 1.17.3 / OTP 27.0 / PG 16. Newest GA: **Elixir 1.20** (June 2026), **OTP 28**, **PostgreSQL 18** (PG 19 is at Beta 4, released 2026-09-24, GA expected ~Oct) | MEDIUM | Catches next-version breakage early; costs ~7–10 runner-min/run if it is a full third `verify-test` entry | Tension: PROJECT.md "Out of Scope: Elixir/OTP version bumps in CI" is contradicted by the milestone's own target, so it needs an explicit scope note. Run a one-shot dispatch spike first: `--warnings-as-errors` on 1.20's type checker may be red on day one. Recommend a third matrix entry for `verify-test` only, `test` job only (not Dialyzer, docs or browser). Also flag: **PostgreSQL 14 (the min lane) reaches EOL in November 2026**. Decide the floor policy now. **[PG14 EOL date: from the PostgreSQL versioning policy, not re-fetched; MEDIUM]** |
| X3 | **Pin third-party actions by SHA + move off Node 20 actions** | 51 of 52 `uses:` are mutable tags (only `re-actors/alls-green` is SHA-pinned). `actions/cache@v4` triggers the "Node.js 20 is deprecated … forced to run on Node.js 24" annotation in 12 jobs of 36258719902 | LOW | Supply-chain hardening. Removes annotation noise | A freshness policy (T-series) covers bumping. Dependabot `github-actions` updates would reintroduce churn (see anti-features), so do it on a quarterly cadence by hand or with a script. |
| X4 | **Dependency-freshness policy** (not churn) | `mix hex.outdated`: 7 updatable (oban 2.22.1→2.24.1, phoenix 1.8.13→1.8.15, phoenix_live_view 1.2.11→1.2.12, ex_doc, credo, lazy_html, yaml_elixir blocked) | LOW | Predictable upkeep | Policy: advisories patch immediately (T2). Everything else in one batched update per release train, recorded in the CHANGELOG. Optionally turn on **Dependabot alerts only** (the dependency graph supports Hex, and GHSA includes Erlang/Elixir advisories) without version-update PRs. |
| X5 | **Split `verify.example` out of the test-current job** | test-current is 590–646 s, of which `verify.example` is 203 s | LOW–MEDIUM | test-current → ~6.5 min. Only pays off once the browser job is also shortened (critical-path tie, §1a) | Adds one job (~1.5 min setup), so +runner-min, −latency. Do it only together with X1. |
| X6 | **`mix test --slowest 25` in the current lane** | §9 "audit the suite regularly". Isolates D6 and the 94%-sync suite cost (291 of 309 s sync) | LOW | Measurement, not savings | The output doubles as the before/after proof for T6 and X1. |
| X7 | **SEED-006 change-aware lanes behind a fail-closed classifier** | Doc-only or `.planning`-only PRs (e.g. every `release/sync-*` distribution PR, 36258071425, 46 runner-min) pay the full matrix | HIGH | Up to ~40 runner-min per docs-only PR **[inference]** | Last phase, only after T3–T7 and X1 are measured. Must be a required, unskippable classifier job + job-level `if:` + `|| github.ref == 'refs/heads/main'` + `allowed-skips` registered (ci.yml:21-27). `verify-bump-rehearsal` may never be skip-listed (ci_topology_contract_test.exs:622-640). |
| X8 | **`@tag :tmp_dir` migration** | 40 test files hand-roll `System.tmp_dir!()` + unique names. 7 lack `on_exit` cleanup (they leak into `/tmp`). Only 1 file uses `@tag :tmp_dir` (playwright_fail_fast_contract_test.exs). One fixed name exists (`export/cleanup_test.exs:74`, async false, so safe today) | LOW–MEDIUM | Hygiene and isolation. **No recorded temp-dir flake**: 0 flaky classifications across ~100 green repeat iterations (36106137910, 36225676728) | Treat as hygiene, not a flake fix. `tmp/` is already gitignored (.gitignore:45). Batch it mechanically and keep behavior identical. |
| X9 | **Fastest likely failure surfaced first** | Everything starts in parallel. Format fails in ~20 s but the check list is unordered | LOW | DX only | Do **not** gate expensive jobs behind cheap ones with `needs:` (it adds ~80 s to every green run). Instead order jobs in YAML and names so the cheap static checks read first, and keep the D1 fast mechanical signal if retained. |
| X10 | **Release `gate-ci-green` idle polling** | ~11 runner-min of sleeping per publish (643 s, 638 s) | MEDIUM | ~11 runner-min per release | Low value vs. release-path risk. Defer. |

### Anti-Features (tempting, but do not build)

| Feature | Why requested | Why problematic | Alternative |
|---|---|---|---|
| Dependabot **version-update** PRs for mix / actions | "Automate freshness" | PR churn on a single-maintainer repo. Each PR costs ~117 runner-min (§1c). The milestone explicitly says "not dependabot churn" | T2 audit gate + X4 batched policy + (optionally) Dependabot *alerts* only |
| Trigger-level `paths:` filters on ci.yml | Cheap docs PRs | Deadlocks the single required check (ci.yml:10-27) | X7 classifier with job-level `if:` |
| Gate **runtime** xref cycles (`--format cycles` with no label) | The guide's §9a wording | 5 legitimate length-2 runtime cycles (Ecto associations such as AuditTransaction ↔ AuditChange; mix.exs says "runtime association edges are allowed") | Keep the existing compile-connected gate. Fix the guide text |
| Flaky retries as a cure (ExUnit or more Playwright `retries`) | Green CI | Hides flakes. Playwright already has `retries: 1` on CI with 0 observed use | T3 PR-side changed-file repeat probe |
| Playwright `workers > 1` or sharding now | The browser job is on the critical path | Shared seeded DB state (the suite is 94% sync by design, "no SQL Sandbox"). Parallelism without isolation manufactures flakes. §5 of the guide: "no broad sharding … unless the baseline proves" | X1 caches first. Revisit sharding only if the browser job is still the sole critical path afterwards |
| Dropping the min lane | "Duplicate of current" | It caught 2 unique failures in 30 days (36084731591, 36082981344) | Keep |
| Making Browser-full required | "Coverage" | Its unique content is 4 critic-feeder capture lanes for a parked loop | T5 |
| Rewriting git history to purge local paths | "Clean repo" | Force-push on a public repo breaks clones, tags and PR references. The guide rules it out | T8 forward scrub + guard |
| Nightly anything on an unchanged SHA | "Catches drift" | 14/14 recent nightlies were same-SHA repeats with cached browsers | Skip-if-unchanged or weekly |
| Moving the test suite to SQL Sandbox to cut the 291 s sync time | Biggest test-lane cost | Architectural. Threadline's triggers need real committed transactions, and the no-sandbox decision is deliberate (maintainer memory) | Out of scope for v1.43 |

---

## Feature Dependencies

```
T1 advisory fix ──must precede──> T2 hex.audit gate (else the gate lands red)
X6 --slowest measurement ──informs──> T6 live-Dialyzer, X1 caches, X5 split
T6 (exclude :live_dialyzer) ──requires──> test_helper.exs + CONTRIBUTING change in same commit
T5 Browser-full de-dup ──requires──> CONTRIBUTING "## CI Coverage" + ci_coverage_doc_contract_test.exs
T7 / D8 removals ──require──> ci-required needs + CONTRIBUTING roster + ci_topology_contract_test.exs (same commit)
T3 Flake right-size ──requires──> flake_classifier_contract_test.exs update; T10 close-on-pass shares bin/upsert-ci-issue
T4 double dispatch ──requires──> release_ci_gate_contract_test.exs review
T8 guard ──requires──> T8 forward scrub first (else the guard lands red); explicit-file staging (.planning rule)
X1 caches ──enables──> X5 split (latency only pays once both critical-path jobs shrink)
X2 newest lane ──requires──> one-shot dispatch spike + a scope note vs PROJECT.md "no Elixir/OTP bumps"
X7 SEED-006 ──requires──> T3..T7 + X1 landed and re-measured (the baseline must be the post-cheap-wins one)
```

## Ranked candidate list (by measured saving × evidence strength ÷ risk)

| Rank | Candidate | Runner-min saved / month (est.) | Latency effect | Evidence | Risk |
|---|---|---|---|---|---|
| 1 | T3 Flake Detection right-size | **~2,900–4,000** | none (scheduled) | HIGH (31 runs, logs) | LOW |
| 2 | T1 + T2 advisories + audit gate | n/a (security) | +~20 s job | HIGH (hex.audit output) | LOW |
| 3 | T4 release-PR double dispatch | **~600** | removes duplicate red | HIGH (9 SHA pairs) | LOW–MED (release path) |
| 4 | T5 Browser-full de-dup (push + nightly) | **~500–700** | none on PR | HIGH (test counts, SHAs) | LOW |
| 5 | T6 live-Dialyzer out of test lanes | ~375 **[inference]** | up to ~2 min off test-current | MEDIUM (cost not isolated) | LOW |
| 6 | X1 `_build` + example caches | ~750–900 **[inference]** | ~1–1.5 min off both critical jobs | MEDIUM | MEDIUM (stale-artifact footgun; contract already written) |
| 7 | T7 + D8 duplicate proofs | ~215 + ~140 | 50 s off capture | HIGH | LOW |
| 8 | T8 path guard + scrub | n/a (privacy) | +few s | HIGH (git grep) | LOW |
| 9 | T9 + T10 names + issue auto-close | n/a (DX) | none | HIGH | LOW |
| 10 | X2 newest lane | −(~650) cost | none (parallel) | MEDIUM | MEDIUM (may be red on day one) |
| 11 | X3, X4, X6, X8, X9 | small | small | varied | LOW |
| 12 | X7 SEED-006 | up to ~40 per docs-only PR | large on docs PRs | LOW until re-measured | HIGH |

**Projected steady state [inference]:** the ~5,500–6,500 runner-min/month forward rate (with Flake at 3,000–4,100) drops to roughly **1,900–2,300**. Per-PR CI drops from ~48 to ~38–40 runner-min. PR wall clock drops from ~10.4 to ~9 min with X1, and toward ~7 min only if X5 and a browser-job reduction also land.

## MVP recommendation

1. **Measure first:** add `--slowest 25` (X6) and record the §1 baseline as the phase-1 artifact.
2. **Cheap, high-evidence wins:** T1 → T2, T3 (+T10), T4, T5, T6, T7.
3. **Hygiene:** T8 scrub → guard, T9 names.
4. **Cache and newest lane:** X1, then an X2 spike.
5. **Last:** X7 SEED-006, only if the post-wins baseline still shows docs-only PRs as a material cost.

Defer: X10 (release-path risk for ~11 min/release). Keep Playwright parallelism and SQL Sandbox out of v1.43.

## Sources

- GitHub Actions runs (HIGH, primary): 36258719902, 36257162368, 36256231845, 36255483521, 36258071425, 36256339043, 36256344029, 36256249852, 36258719891, 36220250465, 36257162356, 35797666620, 36256231909, 36225676728, 36106137910, 35967937335, 34679766829, 34731370786, 36254623336, 36084731591, 36082981344; issues #28 and #36.
- Repo files (HIGH): `.github/workflows/{ci,flake-detection,browser-full,release}.yml`, `mix.exs` aliases, `test/test_helper.exs`, `test/threadline/dialyzer_slice_contract_test.exs`, `bin/verify-dialyzer-slice`, `bin/classify-flake-run`, `bin/upsert-ci-issue`, `examples/threadline_phoenix/e2e/playwright.config.ts`, `CONTRIBUTING.md` (## CI Coverage, roster), `test/threadline/ci_topology_contract_test.exs`, `.planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md`.
- Local tool output (HIGH): `mix hex.audit` (root, bench, example), `mix hex.outdated`, `mix help hex.audit`, `mix xref graph --format cycles`, `git grep`.
- [osv.dev EEF-CVE-2026-82672 (mint)](https://osv.dev/vulnerability/EEF-CVE-2026-82672): fixed 1.10.1 (HIGH)
- [osv.dev EEF-CVE-2026-92106 (lazy_html)](https://osv.dev/vulnerability/EEF-CVE-2026-92106): fixed 0.1.13 (HIGH)
- [Elixir compatibility (v1.20.4 docs)](https://hexdocs.pm/elixir/compatibility-and-deprecations.html), [Elixir v1.19 release](https://elixir-lang.org/blog/2025/10/16/elixir-v1-19-0-released/) (MEDIUM, via search)
- [PostgreSQL 19 Beta 4 released](https://www.postgresql.org/about/news/postgresql-19-beta-4-released-3386/) (MEDIUM, via search)
- [GitHub Advisory Database includes Erlang/Elixir](https://github.blog/changelog/2022-06-27-github-advisory-database-now-includes-erlang-and-elixir-advisories/), [dependabot-core Hex dependency-graph PR #15020](https://github.com/dependabot/dependabot-core/pull/15020) (MEDIUM)

---
*Feature research for: v1.43 Supply Chain, CI Economy and Repo Hygiene*
*Researched: 2026-09-26*
