# R1 — Phase 219 deps-only `_build` cache: KEY SHAPE + ARTIFACT CORRECTNESS

Researcher dimension: key shape and artifact correctness. The repo was only read; nothing in it was edited.
Mix source was read from the local installs of Elixir 1.17.3 (the current lane) and 1.20.2 (the Phase 220 lane), and from a v1.15.8 tag clone (the min lane) at /tmp/r1src/elixir115.
Paths below are `lib/mix/lib/mix/...` in those trees.
Every mechanism cited was checked in all three versions unless noted.

Labels: **[VERIFIED]** = read in Mix source, repo files or cited upstream PRs. **[INFERENCE]** = reasoned, not proven by a run.

---

## TL;DR recommendations

| Q | Recommendation |
|---|---|
| 1 Config | Keep config in the key. Mix does NOT reliably see config changes for Hex deps, so the key is the only guard. Root: `hashFiles('config/**/*.exs')`. Example: `hashFiles('examples/threadline_phoenix/config/**/*.exs')`. Include `runtime.exs` for simplicity. Lock: exact `hashFiles('mix.lock')` / `hashFiles('examples/threadline_phoenix/mix.lock')`, NEVER `**/mix.lock`. Do not add `mix.exs`; `build-vN` is the escape hatch. |
| 2 Profile | Key = `<runner>-otp-<otp>-elixir-<ex>-build-v1-<project>-<MIX_ENV>-<profile>-<lock>-<config>`, with project ∈ {`root`,`example`} and profile ∈ {`full`}. `no-optional` is a reserved name that must never appear (contract). A literal manual `build-v1` segment: YES. |
| 3 Deletions | Root: `rm -rf _build/$MIX_ENV/lib/threadline` is sufficient, because `consolidated/`, `.mix/` manifests, `compile.elixir_scm` and `compile.app_cache` all live inside it (non-umbrella). Example app: remove BOTH `_build/test/lib/threadline_phoenix` AND `_build/test/lib/threadline`. The path dep is compiled code under test, and the example lock does not change when it changes. Do the rm BEFORE the save, not only before the compile. |
| 4 Other inputs | `.tool-versions`: leave it out (redundant with the resolved outputs, and its nodejs line would cause spurious misses). No THREADLINE_*/DB_* env var reaches dep compilation. Guard with a contract rule against compiler env (`ERL_COMPILER_OPTIONS`, `ELIXIR_ERL_OPTIONS`, `CC`/`CFLAGS`, `MIX_*` other than MIX_ENV). The lazy_html NIF is covered by runner+OTP. Hex/rebar3 versions are not correctness inputs. |
| 5 deps vs _build | Keep the `deps` cache's `restore-keys`. No lockstep is needed, because Mix reconciles a near-miss `deps/` against an exact-lock `_build`. Restore `_build` unconditionally, BEFORE `mix deps.get`. Run `mix deps.compile` only on a `_build` miss. |
| 6 Prior art | Ash is the closest match (exact-ish key with `config/**/*.exs` + manual `build-3` version segment). Phoenix, Ecto, Oban and LiveView all use `deps+_build` together with `restore-keys`, which is the footgun CargoSense/setup-elixir-project#13 fixed after a real outage. Swatinem/rust-cache confirms the "deps only, workspace crates cleaned" shape. |

---

## Q1. Does Mix recompile deps when config changes? Which files?

### What Mix actually does [VERIFIED]

1. **Tracked config files.** `Mix.Tasks.Loadconfig.load_compile/1` registers `config/config.exs` and every file it `import_config`s through `Mix.ProjectStack.loaded_config(apps, files)`. That is `config/test.exs` under MIX_ENV=test; the root's dev env imports nothing. `load_runtime/1` registers `runtime.exs` with an **empty** file list (`loaded_config(..., [])`), so `runtime.exs` is **not** a compile-staleness input (`tasks/loadconfig.ex` ~L55-70, same in 1.20.2).
   Each project's `config_files` list also starts with its own `_build/ENV/lib/<app>/.mix/compile.lock` (`project_stack.ex` L260-271). `mix will_recompile` touches that file after any dep compile or lock write (`deps.compile.ex` L112, `dep/lock.ex` L46).
2. **Hex (fetchable) deps do NOT inherit parent config files.** `Mix.Dep.in_dependency` sets `inherit_parent_config_files: not scm.fetchable?()` (1.15.8 `dep.ex` L267, 1.17.3 L260). 1.20.2 makes it explicit: `[deps_lock: ...]` for fetchable deps, `[inherit_parent_config_files: true]` only for path deps (L262-272).
   So the mtime path in `Mix.Compilers.Elixir.compile/7` (`config_mtime > old_config_mtime`, L78-80) never fires in a Hex dep because of a root config edit.
3. **The only config-driven dep recompilation is value-based:** `Mix.Dep.Loader.compile_env_status/2` (1.17.3 `dep/loader.ex` L440-446). It reads the `compile_env` list the dep recorded in its `.app` and, if `Config.Provider.valid_compile_env?/1` fails against the current app env, sets the dep status to `:compile`. `deps.loadpaths` then recompiles it.
   This covers `Application.compile_env/3`. It does NOT cover a dep that reads `Application.get_env` or `System.get_env` in a module body at compile time: Mix has no record of that read.
4. **Consequence:** Mix cannot detect config that a dep reads at compile time without `compile_env`, so including a config hash in the key is the correct conservative guard, not redundancy. For a dep that does use `compile_env`, a key miss plus Mix's own value check make it doubly safe.

### Which files

- Root: only `config/config.exs` + `config/test.exs` exist, and there is no `runtime.exs`. **`hashFiles('config/**/*.exs')`**.
- Example app: `config.exs`, `dev.exs`, `prod.exs`, `test.exs`, `runtime.exs`. Strictly, only `config.exs` + `test.exs` feed a MIX_ENV=test compile. **Recommend `hashFiles('examples/threadline_phoenix/config/**/*.exs')` anyway** [INFERENCE on DX]:
  - config changed in 2 of 479 main commits over 90 days (root 2, example 2), so over-invalidation costs almost nothing;
  - one glob that means "all config" is what a contributor expects;
  - a precise `{config,test}.exs` list silently goes stale if someone adds an `import_config`.
- The root key must NOT include example config, and vice versa: Mix never loads a dependency's `config/` [VERIFIED by the loadconfig flow: only the top-level project's `config_path` is read].
- **Lock glob: exact paths, never `**/mix.lock`.** Tracked locks: `mix.lock`, `bench/mix.lock`, `examples/threadline_phoenix/mix.lock`, `test/fixtures/deps_audit/vulnerable_lock/mix.lock`. There is also an untracked, runtime-generated `priv/ci/hex_evaluator/mix.lock` (gitignored), and `**` would also walk `deps/`.
  Phoenix, Ecto, Oban and LiveView use `**/mix.lock`. Here that would add spurious invalidation from fixtures and bench, and could make the key depend on what is on disk before the restore.
- **`mix.exs`: do NOT add it.** It changed in 22 of 479 main commits (version bumps and aliases). A dep-tuple option that changes compilation without changing the lock (`compile:`, `system_env:`, `manager:`, `app:`) does not exist in the root or example `deps()` today [VERIFIED]; they use only `only/runtime/optional`.
  `only:` changes are self-healing: a newly included dep is simply missing and gets compiled. Record in the CACHE KEY CONTRACT comment: "adding a compile-affecting dep option → bump `build-vN`". Optional: a contract test that asserts dep tuples use only an allowed option set.

## Q2. Profile segment

What differs per cached job [VERIFIED from ci.yml / mix.exs / run-e2e.sh]:

| Job | Project | MIX_ENV | Dep closure |
|---|---|---|---|
| verify-test min | root | test | full (optional included) |
| verify-test current | root, and example via `verify.example` | test / test | full |
| verify-pgbouncer-topology | root | test | full. Same artifact as verify-test current, so it may share the key (correct, since the inputs are identical). |
| verify-dialyzer | root | dev (+ test for the slice step) | full. Two `_build/<env>` dirs means two entries. |
| verify-example-browser / verify-capture | example (run-e2e.sh exports MIX_ENV=test) | test | example full |
| verify-compile-no-optional | root | dev, `--no-optional-deps` | NO CACHE (locked) |
| verify-hex-evaluator | fixture with an untracked, regenerated lock | test | not cacheable by lock, so leave it cache-free |

Facts that shape the segment [VERIFIED]:
- Mix compiles every dep with `opts[:env] || :prod` regardless of MIX_ENV (`dep.ex` 1.20.2 L274), but writes it under `_build/$MIX_ENV`. MIX_ENV in the key is therefore about path scoping and the `only:` closure, and must stay.
- `--warnings-as-errors` and `--force` are NOT propagated to deps: `do_mix` runs `compile` with `["--from-mix-deps-compile", "--no-warnings-as-errors", "--no-code-path-pruning"]`, and `deps.loadpaths` calls `Deps.Compile.compile(compile)` with no options. So run-e2e.sh's `mix compile --force` and the `--warnings-as-errors` flags do not alter or invalidate cached dep artifacts, and neither needs a key segment.
- `--no-optional-deps` changes which deps are loaded and compiled (`deps.loadpaths.ex` L34-40) and the root compile cache_key (`compile.elixir.ex` `cache_key = {..., "--no-optional-deps" in args}`). This is why no-optional must never share an entry with full.

**Proposed key (root, test):**
```
${{ matrix.runner || 'ubuntu-24.04' }}-otp-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-build-v1-root-${{ env.MIX_ENV }}-full-${{ hashFiles('mix.lock') }}-${{ hashFiles('config/**/*.exs') }}
```
(Keep the runner as the literal `ubuntu-24.04` in non-matrix jobs, and as `${{ matrix.runner }}` in verify-test, per the existing contract.)

**Example:**
```
ubuntu-24.04-otp-<otp>-elixir-<ex>-build-v1-example-test-full-${{ hashFiles('examples/threadline_phoenix/mix.lock') }}-${{ hashFiles('examples/threadline_phoenix/config/**/*.exs') }}
```

- `build-v1` = manual poison-recovery and semantics-version segment. Precedent: Ash `...-build-3-...`. Bump it when the artifact's meaning changes (a dep-option change in mix.exs, a Mix/Elixir staleness bug, a suspected poisoned entry). A reviewable one-line commit beats `gh cache delete`, which cannot stop re-poisoning. Keep it a literal (greppable, visible in the Actions cache UI), with the contract test asserting that every `_build` key carries the same `build-vN`.
- Use `${{ env.MIX_ENV }}` rather than a literal where the job sets MIX_ENV at job level, so the key cannot drift from the env that actually compiled. The contract test should assert the key's env segment matches the job/step MIX_ENV and that `path:` is `_build/<same env>`.
- `profile` currently has one value, `full`. It is kept so the key reads as a sentence and so `no-optional` stays a reserved, contract-forbidden token rather than a silent future collision. If sibling (c) prefers fewer segments, fold it into the project segment (`root-full`, `example-full`), but do not drop the concept.
- The `-otp-`/`-elixir-` labels keep it readable, matching the existing deps key's `-elixir-` label.

## Q3. What else in `_build` can be stale after deleting only `lib/threadline`?

[VERIFIED] Where the root project's own state lives:
- `consolidated/` → `Mix.Project.consolidation_path/1` = `Path.join(app_path(config), "consolidated")` for non-umbrella projects, i.e. `_build/ENV/lib/threadline/consolidated` (1.15.8 `project.ex` L805-812, 1.17.3 L810-817, 1.20.2 L910-917). Confirmed on disk: `_build/test/lib/threadline/{consolidated,ebin,priv,.mix}`.
- Root manifests (`compile.elixir`, `compile.elixir_scm`, `compile.lock`, `compile.protocols`, `compile.app_cache`, `cached_dot_formatter`) live in `_build/test/lib/threadline/.mix/`. There is NO `_build/test/.mix` [VERIFIED on disk].
- So `rm -rf _build/$MIX_ENV/lib/threadline` removes all first-party state. Protocol consolidation is rebuilt from scratch, including dep impls, because its manifest and output are gone (`compile.protocols.ex` L52-64 recompiles when the manifest is missing or config_mtime is newer).
- Per-dep `compile.elixir_scm` records `{System.version(), otp_release}`. `otp_release` is the OTP MAJOR only (`dep.ex` `check_manifest`), so Mix will NOT notice an OTP patch bump. The key MUST carry the full resolved OTP, which is already planned. An Elixir version mismatch is detected (`:elixirlock` status → recompile).
- `mix deps.compile`'s `will_recompile` touches `_build/$MIX_ENV/lib/threadline/.mix/compile.lock`, so a stub `lib/threadline/.mix/` exists after `deps.compile`. **Put the rm after deps.compile and before the save**, which also makes it before the compile. That gives one rm step, a genuinely deps-only artifact, and one place for the contract test to pin.
- The dep `_build` dirs contain **relative symlinks into `deps/`** (`priv -> ../../../../deps/phoenix/priv`, rebar3 `src -> ../../../../deps/telemetry/src`; `Mix.Utils.symlink_or_copy` makes relative links). The artifact is location-independent but NOT self-contained: `deps/` must be present (restored or fetched) before the compile. It always is.
- **Example app (critical):** `{:threadline, path: "../.."}`. Its `_build/test/lib/threadline/` holds the compiled library (144 beams plus `priv -> ../../../../../../priv`).
  - Path deps are "local", so `deps.loadpaths` always passes them to compile (`partition/3`: `Mix.Dep.ok?(dep) and local?(dep)`), and they inherit the parent config files. Mix would usually recompile changed sources via mtime and digest.
  - But the example `mix.lock` does not record threadline at all [VERIFIED: no entry], so the key cannot see library changes. The locked "never serve a stale copy of the code under test" rule therefore requires removing it.
  - **Rule: rm both `_build/test/lib/threadline_phoenix` and `_build/test/lib/threadline`.** On a miss, use `mix deps.compile --skip-local-deps` (present since at least 1.15.8) so the path dep is never compiled into the save.
- Staleness via mtime after restore: checkout sets file mtimes to "now". Mix then falls back to size+digest comparison before recompiling (1.17.3 `compilers/elixir.ex` L403-414 `size != last_size or (last_mtime > mtime and (missing_beam_file? or digest_changed?))`). Result: not stale, not a spurious recompile, for Hex deps whose sources are unchanged.

## Q4. Other key inputs

- `.tool-versions`: redundant [VERIFIED by construction]. The key uses `steps.beam.outputs` with `version-type: strict`, so a changed pin changes the resolved outputs. Adding the file would also miss on a `nodejs` bump. Leave it out, consistent with the deps and PLT keys.
- Env vars (all `env:` blocks in ci.yml, grepped): `DB_HOST`, `DB_PORT`, `MIX_ENV`, `THREADLINE_TOPOLOGY_BOOTSTRAP`, `THREADLINE_PGBOUNCER_TOPOLOGY`, `PGPASSWORD`. Also `THREADLINE_E2E`/`THREADLINE_E2E_THEME` via run-e2e.sh.
  - They change config VALUES for `:threadline`/`:threadline_phoenix` (config/test.exs `System.get_env` branches), or are read at compile time only by first-party code (the example router's `THREADLINE_E2E_THEME`; `Application.compile_env(:threadline_phoenix, :dev_routes)`). All of that code is deleted before every compile.
  - No Hex dep reads them [INFERENCE: no dep has a reason to, and the root lib has zero `compile_env`, VERIFIED by grep].
  - Even if a dep's `compile_env` key depended on one, Mix's value check (Q1 point 3) recompiles it, which costs speed but is never wrong.
  - Env that CAN change dep BEAMs/NIFs: `ERL_COMPILER_OPTIONS`, `ELIXIR_ERL_OPTIONS`, `CC`/`CFLAGS`/`MAKE*`, elixir_make force-build vars (e.g. `*_BUILD=true`). None are set today. Contract rule: none of these may be set at job or step level in a cached job, or the key must grow a segment. rust-cache's default env-prefix hashing (`CARGO CC CFLAGS CXX CMAKE RUST`) is the precedent.
- NIF: lazy_html (test-only) is precompiled via elixir_make/cc_precompiler. The download cache lives in `~/.cache/elixir_make` (outside `_build`, NOT cached, and no need to cache it). The `.so` lands as a real file in `_build/test/lib/lazy_html/priv/liblazy_html.so` [VERIFIED on disk]. NIF ABI = OTP NIF version + target triple, covered by full OTP + runner label.
  Runner image patch updates keep glibc forward-compatible within ubuntu-24.04 [INFERENCE].
- rebar3 deps: `telemetry`, `yamerl` [VERIFIED mix.lock]. The rebar3 binary is Mix's `<home>/.mix/elixir/<v>/rebar3`, (re)installed by setup-beam, and its version can float without a key change. Output BEAMs are semantically equivalent across rebar3 patch versions [INFERENCE]. Not a key input; `build-vN` is the escape hatch.
- Hex version: affects fetch only, not compile. Not a key input.
- Optional deps: all cached jobs compile the full closure. The no-optional job stays cache-free (locked).

## Q5. deps/ (restore-keys) vs exact `_build`

[VERIFIED] Mix reconciles every combination:
- An exact `_build` hit implies byte-identical `mix.lock`, so every dep in `_build` was compiled from exactly the locked versions.
- A near-miss `deps/` means `mix deps.get` re-fetches the differing deps. `Mix.Dep.Fetcher.mark_as_fetched/1` deletes `_build/*/lib/<dep>/.mix/compile.fetch`. `Mix.Dep.Loader.recently_fetched?/1` then marks those deps `:compile`, and `deps.compile`'s `maybe_clean` rm's their build dir and recompiles.
- Separately, `Mix.Dep.check_lock/1` flags `deps/` vs lock mismatches (`:lockmismatch`/`:lockoutdated`).
- Worst case is some wasted recompilation, never a wrong artifact. The genuine failure mode (a hard `:nomatchvsn` "does not match the requirement" error from a stale `.app`; `loader.ex` `app_status`) needs a `_build` from a DIFFERENT lock. That can only come from `_build` `restore-keys`, which are banned. This is exactly the outage CargoSense/setup-elixir-project#13 describes.

Recommendations:
- Keep the deps cache's `restore-keys`; "lockstep" is not required (this corrects PITFALLS.md Pitfall 7 bullet 3 [VERIFIED]).
- Restore `_build` unconditionally (not gated on a deps hit), and **before `mix deps.get`**, so Mix's fetched-marker invalidation acts on the restored tree. Belt and braces: it is also correct in the other order, because the `_build` lock is exact.
- **Run `mix deps.compile` only when the `_build` restore missed** (`if: steps.<id>.outputs.cache-hit != 'true'`), then rm the first-party dirs, then save, then `mix compile`.
  - On a hit, `mix compile` → `deps.loadpaths` → `deps_check` compiles only deps whose status is not ok [VERIFIED `deps.loadpaths.ex` deps_check/partition].
  - An unconditional `mix deps.compile` re-runs `rebar3 bare compile` for telemetry/yamerl and enters every Mix dep's compiler every time [VERIFIED `deps.compile.ex` run/compile: "attempts to compile all dependencies"]. ElixirForum thread 45994 reported exactly this recompile-on-warm-cache symptom.
  - This is a policy choice for sibling (a); correctness holds either way.

## Q6. Prior art

- **Ash** (`ash-project/ash` test-subprojects.yml): `path: <proj>/_build`, key `<proj>-otp-<otp>-elixir-<ex>-build-3-${{ hashFiles('config/**/*.exs') }}-${{ hashFiles(.../mix.lock) }}`. It has config in the key and a manual `build-3` version segment, but still a `restore-keys` prefix (down to the config hash). That is the closest ecosystem precedent for our shape, minus the restore-keys.
- **Phoenix, Phoenix LiveView, Ecto, Oban** (ci.yml, fetched via `gh api` 2026-09-27): one cache for `deps` + `_build` together, `${{ runner.os }}` (the D-19 anti-pattern), `**/mix.lock`, WITH `restore-keys`. None removes first-party build output. This is the common pattern that the Threadline contract deliberately rejects.
- **CargoSense/setup-elixir-project#13** ("Stop falling back to a `_build` cache from a different mix.lock", benwilson512):
  - Real outage: after a `leto ~> 0.1 → ~> 0.3` bump, every PR failed with "the dependency does not match the requirement".
  - `actions/cache` saves only on success, so failed jobs never repaired the namespace, which left a permanent loop until caches were purged by hand.
  - Fix: drop `restore-keys` for `_build` only, and keep them for `deps/`, `~/.hex` and rebar3, "since `mix deps.get` safely reconciles them".
  - This matches our Q5 split exactly.
- **FRIKKern/barkpark #18013 / PR #19950**: the test-job `deps+_build` cache with a prefix restore silently restored stale first-party `.beam`s. The remedy was "cache dependency artifacts only" or a hard-fail tripwire. It validates both locked rules (no restore-keys + remove first-party).
- **erlef/setup-beam**: its README has no `_build` caching guidance and ships no cache feature. Its workflows don't cache `_build`.
- **Swatinem/rust-cache** (the closest cross-language analog):
  - What it gets right: it caches `<home>/.cargo` + `target/` for dependencies only, and "the workspace crates themselves are not cached since doing so is generally not effective". It prunes non-dependency and unused artifacts before saving. Its key includes the rustc version/host hash, compiler env vars (`CARGO CC CFLAGS CXX CMAKE RUST` prefixes), lockfile and manifest hashes, and toolchain/config files, plus a manual `prefix-key` (default `v0-rust`) for invalidation. That validates both the env-var guard and the `build-vN` segment.
  - What differs: rust-cache also hashes `Cargo.toml` manifests (our analog, mix.exs, is deliberately excluded; see Q1) and uses a partial restore. That is safe for Cargo because Cargo fingerprints every unit by content/flags. Mix's `.app` vsn check is not equivalent, so the partial restore does not transfer.
- **Gradle/Bazel remote cache poisoning** [INFERENCE, general knowledge]: poisoning happens when a writer of lower trust (PR builds) can populate entries read by higher-trust consumers, or when undeclared inputs (env, absolute paths, tool versions) leak into outputs. Mitigations: read-only for untrusted builds, full input declaration, versioned cache namespaces.
  Mapping: GitHub already scopes PR-branch caches away from `main` reads. Keep release.yml cache-free (locked). Declare env inputs (Q4 contract rule). `build-vN` = the namespace version.
- **Rails bootsnap** [INFERENCE]: it keys compile caches per file on mtime+size+Ruby version+`RUBY_PLATFORM` and is known to break across mtime-unreliable CI restores unless keyed on revision. Lesson: never let correctness depend on mtimes after a tarball restore. Mix's digest fallback (Q3) is why our design survives this.

## Coherence notes for siblings

- (a) save/restore: a single ordered sequence per project:
  restore `_build` → restore deps → `mix deps.get` → [miss] `mix deps.compile` (example: `--skip-local-deps`) → rm first-party dirs → [miss] save → `mix compile --warnings-as-errors`.
  verify-test current and verify-pgbouncer-topology produce the same key, so expect "cache already exists" on the second save, which is harmless.
- (b) coverage: verify-dialyzer needs two entries (dev, test). The example cache applies to verify-test current (verify.example), verify-example-browser and verify-capture. The example compile inside `mix verify.example` runs in a `bash -lc` sub-shell, so the rm/compile ordering must be done in workflow steps before that alias runs, or the alias must tolerate a pre-populated `_build` (it does, since Mix is incremental). verify-hex-evaluator stays uncached (its untracked, regenerated lock).
- (c) contract test should assert, for every `_build` restore/save pair:
  - no `restore-keys`;
  - key contains `build-v<N>` (identical across the file), the runner (literal or `matrix.runner`), `steps.beam.outputs.otp-version` and `elixir-version`, a MIX_ENV segment equal to the job's MIX_ENV, a profile token ≠ `no-optional`, exact `hashFiles('mix.lock')` (or the example path) and `hashFiles('<proj>config/**/*.exs')`;
  - no `**/mix.lock`, no `runner.os`;
  - an `rm -rf` of `lib/threadline` (plus `lib/threadline_phoenix` for the example) ordered after `deps.compile` and before both the save and `mix compile`;
  - verify-compile-no-optional and release.yml contain no `actions/cache`;
  - no `ERL_COMPILER_OPTIONS`/`ELIXIR_ERL_OPTIONS`/`CC`/`CFLAGS` in cached jobs.

## Sources
- Mix source, Elixir v1.15.8 / v1.17.3 / v1.20.2: `project.ex` (config_files, config_mtime, consolidation_path), `project_stack.ex`, `tasks/loadconfig.ex`, `dep.ex` (in_dependency, check_lock, check_manifest), `dep/loader.ex` (validate_app, recently_fetched?, compile_env_status), `dep/fetcher.ex` (mark_as_fetched), `dep/elixir_scm.ex`, `tasks/deps.compile.ex`, `tasks/deps.loadpaths.ex`, `tasks/compile.elixir.ex`, `compilers/elixir.ex`, `tasks/compile.protocols.ex`, `tasks/will_recompile.ex`, `utils.ex` (symlink_or_copy)
- [CargoSense/setup-elixir-project#13](https://github.com/CargoSense/setup-elixir-project/pull/13)
- [FRIKKern/barkpark#18013](https://github.com/FRIKKern/barkpark/issues/18013), [PR #19950](https://github.com/FRIKKern/barkpark/pull/19950)
- [ElixirForum: GitHub Action cache always recompiles dependencies](https://elixirforum.com/t/github-action-cache-elixir-always-recompiles-dependencies-elixir-1-13-3/45994)
- [Swatinem/rust-cache README](https://github.com/Swatinem/rust-cache)
- [actions/cache#469 (Elixir _build example)](https://github.com/actions/cache/pull/469)
- Workflows via `gh api`: phoenixframework/phoenix, phoenixframework/phoenix_live_view, elixir-ecto/ecto, oban-bg/oban, ash-project/ash (test-subprojects.yml)
