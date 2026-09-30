# R3 — Phase 219 research: which jobs get which cache, example-app cache design, measurement method

Scope: read-only research. Sources: `.github/workflows/ci.yml` (full), `flake-detection.yml`, `browser-full.yml`, `mix.exs`, `examples/threadline_phoenix/{mix.exs,mix.lock,config/*,e2e/run-e2e.sh}`, 214-BASELINE.md, 218-REMEASURE.md and the committed 218 raw job JSON (`.planning/phases/218-ci-economy-remove-waste/raw/ci/runs/*.json`), plus read-only `gh run view --job <id> --log` of run 36364354586 (post-218, success, head 37e36cb2) for dep-vs-app compile split. Local Elixir source (1.17.3) checked for path-dep behaviour.

## 0. Key facts that drive everything

1. **Deps dominate every compile step.** Log timestamps of run 36364354586 (`==> <dep>` lines up to `==> threadline`):

| Job (run 36364354586) | MIX_ENV | Step | Deps compile | Own app compile | Step total |
|---|---|---|---|---|---|
| Run test suite (current) | test | Compile (warnings as errors) | ~41 s (01:01:50.6 → 01:02:31.4) | ~5 s | 46 s |
| Run test suite (current) | test | Verify Threadline Phoenix example | ~81 s (61.5 s before `==> threadline`, 19.3 s after: heroicons…sigra; `idna` alone 18 s) + ~3.5 s example `deps.get` fetch (example `deps/` is not cached today) | threadline ~5 s + threadline_phoenix ~4.3 s | 203 s (p50) |
| Run test suite (min) | test | Compile (warnings as errors) | ~42.5 s (01:01:56.0 → 01:02:38.5) | ~6 s | 48 s |
| Example app browser E2E | test (example) | Run example Playwright suite | ~80 s (02:06.5 → 03:07.8, 03:12.8 → 03:31.6) | ~10 s | 594 s (p50) |
| Tier A capture lane | test (example) | Regenerate Tier A capture | ~77 s (01:58.9 → 02:59.8, 03:04.7 → 03:20.3) | ~9 s | 450 s (p50) |
| PgBouncer topology | test | Bootstrap test DB | ~40 s (02:40.5 → 03:20.3) | ~6 s | 48 s (p50) |
| Dialyzer | dev | Compile full optional build | ~34 s | ~3 s | 53 s (p50) |
| Dialyzer | test | Live Dialyzer slice proof | ~27 s (test-env deps) | ~10 s incl. test | 54 s (p50) |
| Credo | dev | Run Credo | ~48.5 s (01:01:30.3 → 01:02:18.8) | n/a (credo ~9 s) | 59 s (p50) |
| Compile without optional deps | dev | Compile without optional deps | ~38 s | ~2 s | 35 s p50 — **locked cache-free** |

Per-step p50s are over the 8-run 218 `post` set (computed from committed raw job JSON; e.g. current `Compile` p50 47 s run 36359171595, min 40 s run 36359132030, `Verify Threadline Phoenix example` 203 s run 36364354586, browser Playwright step 594 s run 36362405054, capture regenerate 450 s run 36361003789, pgbouncer bootstrap 48 s run 36364354586, credo 59 s run 36362405054). The deps/app split is from one run's logs (n=1) — **[inference]** for the p50 split, but the dep list is deterministic so the share should be stable.

2. **Mix path-dep semantics (Elixir 1.17 `deps.loadpaths.ex:118-124`, `dep.ex:260`)**: the example declares `{:threadline, path: "../.."}`. Path deps are always handed to the compiler when "ok" (incremental), and they get `inherit_parent_config_files: true`, i.e. threadline is compiled **inside the example's `_build/test/lib/threadline` with the example's config**. So the example `_build` contains two project-owned apps: `threadline` and `threadline_phoenix`. Both must be removed after restore.

3. **Consolidated protocols live per-app** in Elixir ≥1.17 (`_build/test/lib/<app>/consolidated`; local `_build/test` contains only `lib/`). Removing `lib/threadline` (root) / `lib/threadline_phoenix` (example) also removes the stale consolidation. No separate `consolidated/` rm needed on the current toolchain; **flag for sibling (a)**: Elixir 1.15.8 (min lane) — verify where consolidation lands (older Mix wrote `_build/$ENV/lib/<app>/consolidated` too since 1.11-ish, but confirm in the min-lane log before relying on it; cheapest robust choice is caching `_build/$MIX_ENV/lib` only).

4. **No asset binaries.** No esbuild/tailwind in the example (`grep esbuild|tailwind` over mix.exs/config: none). Native bits in the example `_build`: `argon2_elixir` (C via elixir_make, ~1.1 s) and `mdex_native` (rustler_precompiled **downloads** a NIF at compile time — caching removes a network fetch as well as time). The runner label + OTP in the key cover NIF ABI/arch.

5. **Env-driven config is not in any file hash.** `THREADLINE_E2E` (example `config/test.exs:80`, `runtime.exs:26`) and `THREADLINE_PGBOUNCER_TOPOLOGY` (root `config/test.exs:3`) change `:threadline` config between jobs that would share a key. This is safe **only because** it configures `:threadline`/`:threadline_phoenix`, which are always removed. Third-party deps read no such env. Flag for sibling (a)/(c): the "config in key" segment is defence in depth; the rm is the real guarantee.

6. **Cache scoping decides what "warm" means.** PR runs save to `refs/pull/N/merge` and can read main; `workflow_dispatch` on a branch saves to `refs/heads/<branch>` — a *different* scope from the PR merge ref. All jobs of one run start together, so the first run in any scope is cold for every job; warm starts at the second run in that scope (if saving is allowed there) or after main holds the entry.

## 1. Per-job decision

| Job | MIX_ENV | Compiles | Deps-compile saving (warm) | Recommend |
|---|---|---|---|---|
| verify-test (current) | test | root deps + example deps | ~41 s root + ~81 s example + ~3.5 s example fetch ≈ −115 s net of restores (573 → ~460 s) | **YES: root test key (current toolchain) + example key** |
| verify-test (min) | test | root deps (1.15.8/OTP 26) | ~42 s ≈ −39 s net (318 → ~280 s) | **YES: root test key (min toolchain, its own key from beam outputs)** |
| verify-example-browser | test (example via run-e2e.sh) | example deps only (root `deps.get` runs but root is never compiled) | ~80 s ≈ −76 s net (643 → ~567 s) — **the critical-path job** | **YES: example key** |
| verify-capture | test (example) | example deps only | ~77 s ≈ −73 s net (499 → ~426 s) | **YES: example key** |
| verify-pgbouncer-topology | test | root deps | ~40 s ≈ −38 s net (114 → ~76 s) | **YES, restore-only of the current-lane root test key** (same runner/OTP/Elixir/MIX_ENV/lock/config → zero new keys). It is a test job. |
| verify-credo | dev | root deps (dev) | ~48 s (74 → ~28 s) | **NO in 219** (not a test job, off critical path). Follow-up candidate: one `dev` key shared with dialyzer, ≈ −1 billed min. |
| verify-dialyzer | dev + test | root deps twice (dev compile, then test-env compile in the live slice step) | ~34 s dev + ~27 s test | **NO in 219.** Two envs in one job, PLT interplay, would need a dev key + a restore of the test key. ≈ −1 billed min if ever done. |
| verify-compile-no-optional | dev | root deps without optional | ~38 s | **NO (locked)**. Contract must also forbid it restoring any shared dev key. |
| verify-hex-evaluator | test (fixture) | `priv/ci/hex_evaluator` against a rehearsal tarball | ~? (31 s step total) | **NO**: its `mix.lock` is untracked/gitignored and `:threadline` is re-resolved every run (mix.exs:437-446) — there is no stable exact key, and its purpose is an honest cold adopter compile. |
| verify-bump-rehearsal | dev | throwaway clone | n/a | **NO** (already documented: clone never reads `deps/`/`_build`). |
| verify-format | — | nothing compiled (job p50 17 s) | 0 | **NO** |
| verify-deps-audit / repo-hygiene / release-shape / ci-required | — | nothing | 0 | **NO** |
| flake-detection.yml | test | root deps once, then 13 suite runs (45.7 min) | ~41 s ≈ 1.5 % | **NO in 219** (weekly, off-PR; adds a file to the parity contract for ~1.5 %). Possible restore-only follow-up. |
| browser-full.yml | test (example) | example deps | ~77 s of 6.4 min per push run (~26 runner-min/month at 20 pushes) | **NO in 219**; restore-only follow-up candidate (reads the ci.yml example key from main). |
| release.yml publish | — | — | — | **NO (locked)** |

Minimal honest set = **3 keys** per lock/config state (root-test-min, root-test-current, example-test-current), used by **5 job-lanes** (test current, test min, browser, capture, pgbouncer). This captures ~95 % of the achievable critical-path win and ~75 % of the achievable runner-minute win; credo+dialyzer would add a 4th (dev) key for ≈ −2 billed min/run and zero critical-path change.

Budget: local compressed sizes (macOS, indicative) root `_build/test/lib` minus threadline ≈ 15 MB, example `_build/test/lib` minus the two apps ≈ 21 MB, example `deps/` ≈ 4 MB. ≈ 40–60 MB per lock state — negligible vs 10 GB even with per-PR-ref saves; the eviction risk is from Playwright/npm entries, not these. (Record actual sizes read-only via `gh cache list` in the remeasure.)

## 2. Example-app cache design

- **Dependency shape**: `{:threadline, path: "../.."}` (examples/threadline_phoenix/mix.exs:42). `examples/threadline_phoenix/mix.lock` is tracked and lists every resolved hex dep, including threadline's transitive deps. `_build/` is gitignored in the example.
- **Jobs that build it**: verify-test (current) via `mix verify.example` (`deps.get` + `compile --warnings-as-errors` + `mix test`, MIX_ENV=test); verify-example-browser and verify-capture via `run-e2e.sh` (`deps.get --only test`, `touch router.ex`, `mix compile --force`, MIX_ENV=test); browser-full.yml (same script). All four produce the identical `_build/test/lib/<dep>` set (same toolchain, same env, same lock; `--force` does not propagate to deps).
- **Recommended paths (one key)**: `examples/threadline_phoenix/deps` and `examples/threadline_phoenix/_build/test/lib`. Caching example `deps/` too saves the ~3.5 s hex fetch and removes a network dependency; it is keyed on the same lock so it is exact.
- **Removal set, after restore, before any example compile**: `examples/threadline_phoenix/_build/test/lib/threadline` and `examples/threadline_phoenix/_build/test/lib/threadline_phoenix`. For browser/capture this must run before `mix verify.example_browser`/`verify.capture`; in the current lane before `mix verify.example`. (Root removal: `_build/test/lib/threadline`.)
- **Key composition (recommendation; sibling (a) owns final shape)**: runner label literal + resolved OTP + resolved Elixir (from the job's `beam` step) + `MIX_ENV` (`test`) + profile segment `example` + `hashFiles('examples/threadline_phoenix/mix.lock')` + `hashFiles('examples/threadline_phoenix/mix.exs', 'examples/threadline_phoenix/config/**')`.
  - **Do not include root `mix.lock`**: the example resolves every dep from its own lock; root lock changes cannot alter example `_build` deps. Including it only causes needless cold misses (every root dep bump would cold both example consumers, including the critical-path job).
  - Root `config/` is never loaded by the example (path deps inherit the *parent's* config) — exclude.
  - If CI ever re-resolves the example lock (root mix.exs constraint change without re-locking the example), Mix itself detects the per-dep lock mismatch and recompiles that dep — correctness holds; only the saving degrades.
- **Saver**: three jobs restore the example key; let one save (sibling (b)). Prefer an off-critical-path saver (verify-capture or verify-test current), with the save placed right after its compile (PLT "save before analysis" precedent) so a later test failure does not discard a valid entry. Saved content includes the two project apps; the restore-side rm makes that harmless (optionally also rm before save to shrink the entry).

## 3. Measurement method (219-REMEASURE.md)

**Tools**: copy the 218 tools (collector, summarizer, citation checker) into `.planning/phases/219-*/tools/` (same D-11 pattern), extend the checker's phase exemption to 219, and add `remeasure-219.py` that imports `remeasure-218.py`'s arithmetic unchanged and adds sets `warm`, `cold`, plus `base` (214) and `post218` (218's 8 runs, read-only from the 218 manifest).

**Make hit/miss labelable from committed job JSON (no log dependence)**: mirror the PLT precedent — per cache, a `Report exact <x> build cache hit` step guarded `if: steps.<restore>.outputs.cache-hit == 'true'` that echoes `THREADLINE_BUILD_CACHE_<X>=hit`, and on miss the save step runs. Step conclusion (success vs skipped) in `raw/ci/runs/*.json` then labels every sample. Strongly recommended: split root `mix deps.compile` into its own step ahead of `Compile (warnings as errors)`, and add an explicit `Compile example dependencies` step (`cd examples/threadline_phoenix && mix deps.get && mix deps.compile`, MIX_ENV=test) in browser/capture/current before the suite. Then the saving shows directly in the `steps` mode (warm ≈ 1–2 s vs ~40/~80 s cold) without log scraping, and logs (90-day retention, never committed) are not needed as evidence.

**Required fields (consistent with 218-REMEASURE.md)**:
- §0 Method: code under measurement (branch, push instant, first run id), tools and their copy provenance, raw-data collection commands, citation rule, [inference] labelling for projections.
- §1 Samples: one row per run — run id, event, head, conclusion, cache scope (PR merge ref / branch / main), per-cache label (root-min, root-current, example) hit|miss, jobs not success.
- §2 Runner-minutes per ci.yml run: base (214, n=20) / post218 (n=8) / warm / cold — unrounded + billed p50/p95.
- §3 Wall clock and critical-path end offset (218 rule: latest successful voting job completion from first job start): base 623 s (run 36256339043), post218 643 s (run 36362405054), warm, cold; plus which job finishes last.
- §4 Per-job table for the five cached job-lanes: base p50 / post218 p50 / warm p50 / cold p50 / Δ vs base / Δ vs 218, citing run ids. Step table: deps-compile step p50 warm vs cold, restore-step p50, save-step p50 (= cold-miss penalty).
- §5 Correctness evidence: in a warm run the compile log shows zero `==> <dep>` lines and a fresh `Compiling N files (.ex)` / `Generated threadline app` (root and example); in a cold run the full dep list. Quote from `gh run view --job <id> --log` with run ids.
- §6 Budget: entry count and sizes per key from `gh cache list` (read-only), total vs 10 GB, any eviction observed.
- §7 Summary of deltas table (same shape as 218 §9).

**Sample counts**: 214 used ≥10 PR + ≥10 push (n=20 PR). 218 accepted n=8. For 219: cold n ≥ 2 (the first run in each scope is cold for free), warm n ≥ 8 to match 218 (≥10 to match 214 if the maintainer grants the dispatches — each run ≈ 44 runner-min, so 10 warm ≈ 7.3 runner-h: a spend decision to hand up). Step-level deps-compile deltas are tight (min lane compile 34–49 s range) and are honest at n=5; the critical-path delta rides the browser job's 488–612 s spread and needs n ≥ 8.

**Observing cold vs warm without mutating state**: never `gh cache delete`. The first PR run on the land branch is cold (main has no entry pre-merge); later PR pushes/re-runs on that PR are warm *if* the save policy allows PR-ref saves. Dispatch runs on the land branch are a separate scope: first dispatch cold, later dispatches warm. **If sibling (b) picks main-only saves, every pre-merge run is cold** — then 219 can only measure the cold penalty before merge, and warm samples require the post-merge push run (cold, saves) followed by later PR/push/dispatch runs on main; the record must say so and the warm figures become a post-landing addendum (like 218's push-unit inference).

## 4. Honest expectation

| Job | Post-218 p50 | Expected warm | Δ | Billed min |
|---|---|---|---|---|
| Browser E2E (critical path) | 643 s | ~567 s | ~−76 s | 11 → 10 |
| Test (current) | 573 s | ~460 s | ~−115 s | 10 → 8 |
| Capture | 499 s | ~426 s | ~−73 s | 9 → 8 |
| Test (min) | 318 s | ~280 s | ~−39 s | 6 → 5 |
| PgBouncer | 114 s | ~76 s | ~−38 s | 2 → 2 |
| **Per run** | 44.4 unrounded / 53 billed (218) | ≈ −5.7 unrounded / ≈ −5 billed | | |
| Critical path | 643 s | ~567 s (still the browser job; current lane falls to ~460 s) | **≈ −76 s (−12 %)** | |

All [inference] from one run's log split × 218 p50s; restore overhead assumed 2–4 s per cache. Cold-miss penalty ≈ +3–6 s per saving job (restore miss ~1 s + save of a 15–25 MB entry). ARCHITECTURE.md's "current lane unchanged" is wrong: `verify.example` recompiles ~81 s of example deps inside the current lane, so the current lane gains the most. Credo/dialyzer would add ≈ −1.7 unrounded / −2 billed min per run and nothing to the critical path — excluded for scope and key-count, recorded as a follow-up option. Side note (not 219 scope): browser/capture restore the root `deps` cache and run root `mix deps.get` although root deps are never compiled there.
