# Stack Research: v1.43 Supply Chain, CI Economy and Repo Hygiene

**Domain:** CI, supply-chain and repo-hygiene tooling for an Elixir Hex library (`threadline` 0.11.0)
**Researched:** 2026-09-26
**Confidence:** HIGH for versions, advisory facts and CI behaviour. These were checked against primary sources: hex.pm API, OSV API, `gh api` release and tag data, the Hex and Elixir source at tagged versions, local `mix` runs, and logs from the last green CI run. MEDIUM for the policy recommendations, which are my inference and are marked as such.

**Scope note:** This file covers tooling only. The product itself is validated and was not re-researched. No repo files were modified, except that `mix hex.audit`, `mix hex.outdated`, `mix xref` and `mix deps.unlock --check-unused` were run read-only.

**Confidence labels in this file:**
- **[VERIFIED]** means checked against a primary source or command output.
- **[WEB]** means a single web source that was not cross-checked.
- **[INFERENCE]** means my reasoning from the verified facts.

---

## 0. Findings that change the milestone scope

Read these first. Several of them correct the baseline in PROJECT.md.

1. **There are now two advisories in the root lock, not one.** [VERIFIED, `mix hex.audit` exits 1]
   - `lazy_html 0.1.12`: EEF-CVE-2026-92106 / GHSA-8rqp-v692-v82q, LOW. It is fixed in **0.1.13**, per OSV `fixed: 0.1.13`. 0.1.13 was released 2026-09-25 and requires `elixir: ~> 1.15`, so the min lane is fine.
   - `mint 1.10.0`: **EEF-CVE-2026-82672** / GHSA-rj5m-69wp-cxq9, MEDIUM, an HTTP/1 response-smuggling issue. It is fixed in **1.10.1**, released 2026-09-19 with `elixir: ~> 1.15`. mint arrives transitively through `req -> finch -> mint`, where `req` is an optional runtime dep.
   - Adopters resolve their own lock, so both fixes are lock-only (`mix deps.update lazy_html mint`). Neither needs a `mix.exs` change.
   - **Inference:** a CHANGELOG line for mint is still worthwhile, because `req` is an optional runtime integration.
2. **`bench/mix.lock` has 8 advisories, 3 of them HIGH.** [VERIFIED]
   - The affected versions are postgrex 0.22.0 (×3, one HIGH), plug 1.19.1 (×4, two HIGH) and decimal 2.3.0.
   - `bench/` is not audited by anything in CI.
   - The audit gate has to cover all three tracked lockfiles: `mix.lock`, `examples/threadline_phoenix/mix.lock` (clean today) and `bench/mix.lock`.
3. **CI does not run the OTP it claims to.** [VERIFIED from run logs, 2026-09-26]
   - Every non-matrix job pins `otp-version: "27.0"`. With setup-beam's default `version-type: loose`, that resolves to **OTP-27.0.1**, a July 2024 build. This applies to the Dialyzer "current toolchain" job, Credo, format, browser, capture and others.
   - The `current` test lane pins `"27"` and gets **OTP-27.3.4.18**.
   - Local `.tool-versions` says `27.3.4.15`, and that file is **untracked** (`?? .tool-versions`).
   - So the result is three different OTPs, and the Dialyzer PLT key (`otp27.0`) is honest only about the stale one.
   - `test/threadline/ci_topology_contract_test.exs:396` *asserts* `otp-version: "27.0"`, which pins the drift in place.
4. **Node 20 actions are past GitHub's removal date.** [VERIFIED]
   - GitHub set Node 20 removal for **2026-09-23**. The pinned `actions/cache@v4`, `actions/upload-artifact@v4` and `googleapis/release-please-action@v4` all declare `using: node20`.
   - They currently run because the runner forces them onto Node 24, which produces deprecation noise in logs. This is a latent break, not a hypothetical one.
   - `test/threadline/ci_workflow_parity_contract_test.exs:255` asserts `actions/cache@v4`.
5. **The `ubuntu-22.04` image entered deprecation on 2026-09-17.** [VERIFIED, actions/runner-images#14254]
   - Brownouts run 2027-03-23 through 04-13, and the image is unsupported from **2027-04-17**.
   - The min lane (`ubuntu-22.04`) should move to `ubuntu-24.04`. setup-beam supports OTP 24.3–29 on 24.04.
6. **The xref-cycles gate already exists.** [VERIFIED]
   - `verify.xref_cycles` (`--label compile-connected --fail-above 0`) is in `ci.all` and in both test lanes, and it is clean.
   - `mix xref graph --format cycles` with **no label** finds **5 runtime cycles**, all of length 2:
     - `audit_transaction <-> audit_change`
     - `audit_transaction <-> semantics/audit_action`
     - `investigation <-> threadline`
     - `mechanical_checker <-> mechanical_checker/contrast`
     - `critic_trust/repository_boundary <-> mix/tasks/critic.measure`
   - `capture/audit_transaction <-> semantics/audit_action` crosses the Capture/Semantics layer boundary. **Inference:** this is most likely an Ecto association back-reference, but it needs a look under the "layers stay one-directional" rule (guide §9a).
7. **Secret scanning and push protection are already enabled** on the repo (`security_and_analysis`). [VERIFIED] Dependabot security updates are disabled, `/vulnerability-alerts` returns 404 (alerts off), and there is no `.github/dependabot.yml`.
8. **The local-path baseline has grown to 298 files, all under `.planning/`.** [VERIFIED, `git grep`, 0.15 s]
   - Distinct prefixes: the maintainer home directory (978 hits), the GitHub runner home `home/runner/` (350 hits, which is CI log excerpts and not PII) and one `home/timeline/` false positive.
   - 5 files contain macOS temp paths (`/private/var`, `/var/folders`, `/private/tmp`).

---

## Recommended Stack

### Core tooling (adopt)

| Tool | Version | Purpose | Why recommended |
|---|---|---|---|
| **`mix hex.audit`** (built into Hex) | Hex **>= 2.5.0**. CI installs **2.5.1** today [VERIFIED from log `hex-2.5.1`] | The CI audit gate. It reports retired packages **and security advisories**, and exits 1 on either. | Advisory reporting landed in Hex 2.5.0 (hexpm/hex#1150, released 2026-06-28). Its source is the EEF CNA / OSV feed: the lazy_html advisory was flagged the day it was published. `ignore_advisories` / `ignore_retirements` (Hex 2.5.1) gives a reviewed escape hatch in `mix.exs :hex` that fails nothing and warns when an entry goes stale. It needs zero new dependencies. |
| **`mix deps.unlock --check-unused`** | Elixir >= 1.15 (flag present in 1.15.8) [VERIFIED] | Fails if `mix.lock` carries entries no dep needs | Cheap and deterministic, and it currently passes (exit 0). It stops a lockfile from keeping a dropped, vulnerable dep that the audit would still flag. |
| **`mix deps.get --check-locked`** | Elixir >= 1.15 (present in 1.15.8, absent in 1.14) [VERIFIED] | Fails if `mix.exs` and `mix.lock` disagree | This turns "someone edited a requirement but not the lock" into a named, fast failure. It can replace the plain `mix deps.get` in the audit job. |
| **`erlef/setup-beam`** | **v1.24.1** (2026-06-28), `@v1`, node24 [VERIFIED] | BEAM toolchain in every job | Use `version-file: .tool-versions` with `version-type: strict` for every non-matrix job. The parser ignores the `nodejs` line and understands the `-otp-27` suffix [VERIFIED in `src/setup-beam.js`]. This needs `.tool-versions` to be **committed**. |
| **`actions/cache`** | **v5** (v5.1.0) or v6 (v6.1.0). Use split `actions/cache/restore` + `actions/cache/save` [VERIFIED node24] | deps, deps-only `_build`, PLT, Playwright | v4 is node20 and past removal. v5 is the smallest step (a runtime bump only). v6 only migrates internals to ESM. **Pick v5** unless another reason to take v6 appears. |
| **`actions/upload-artifact`** | **v7** (v7.0.1). v6 is the first major that *defaults* to node24 [VERIFIED] | flake log, Playwright traces | v5 still ran node20 by default. v7 adds an opt-in `archive: false` and is otherwise compatible. |
| **`googleapis/release-please-action`** | **v5** (v5.0.0) [VERIFIED] | Release PRs | The only breaking change in v5.0.0 is node24 (plus release-please 17.3 -> 17.6). Treat it as its own commit, and rehearse it through the release runbook because the release lane is fragile. |
| **Composite action** `.github/actions/setup-elixir/action.yml` | n/a (GitHub `using: composite`) | Dedupe the checkout-to-`deps.get` setup across about 14 jobs | This is a step-level dedupe that **keeps job IDs and check names unchanged**. See "What NOT to use" for why a reusable workflow is the wrong tool here. |
| **`git grep`-based guard script** `bin/check-local-paths` + `mix verify.no_local_paths` | git (runner-provided) | PII / absolute-local-path guard | It scans only **tracked** files, so it never sees deps/, _build/ or node_modules. It runs in about 0.15 s across the whole repo, needs no install, runs identically locally and in CI, and can be unit-tested like `bin/classify-flake-run`. |

### Supporting additions

| Item | Version | Purpose | When to use |
|---|---|---|---|
| Hex `cooldown` config | Hex >= 2.5.0 [VERIFIED feature, from changelog] | Holds freshly published versions back for N days during resolution | Supply-chain hygiene against compromised releases. **Inference:** set `7d` for this repo's own resolution. It does not affect adopters. It bypasses cooldown for locked versions that carry advisories, so security fixes are never held back [VERIFIED, changelog]. *Verify where it is configured* (`mix.exs :hex` block vs `mix hex.config` vs `HEX_COOLDOWN`) before relying on it [MEDIUM]. |
| `mix hex.outdated --within-requirements` | Hex 2.5.1 | Freshness signal. Exits 1 only if an in-range update exists [VERIFIED from help text] | The dependency-freshness policy (§Freshness). Today it would flag ex_doc, lazy_html, oban, phoenix and phoenix_live_view. `yaml_elixir` shows "Update not possible", which is correct because of the deliberate `~> 2.11.0` floor pin. |
| ExUnit `@tag :tmp_dir` | Elixir >= 1.11, so the 1.15 min lane is fine [VERIFIED] | Replace ad-hoc `System.tmp_dir!()` + `unique_integer` dirs (40 test files use `System.tmp_dir`, and only 1 uses `:tmp_dir`) | Semantics are covered in §5. |
| `mix test --repeat-until-failure N --max-failures 1` | Elixir >= **1.17** [VERIFIED, help text] | Flake lane budget | Only on the current or latest toolchain. The 1.15 min lane cannot run it. |
| Dependabot **alerts** (a repo toggle, not a bot) | n/a | Async alerts for the **GitHub Actions** and **npm** (`examples/threadline_phoenix/e2e/package-lock.json`) ecosystems | This is a maintainer action (settings -> Code security). It is free on public repos and adds no PRs. |
| `.github/dependabot.yml`, `github-actions` ecosystem only, `interval: monthly`, a single `groups:` entry | Dependabot v2 config | Keeps action SHAs and majors fresh with one PR per month | **Inference:** this is the only Dependabot *version-update* config worth adding. It fixes the class of rot behind finding 4. Do **not** add `package-ecosystem: mix` (churn). |

### Toolchain versions for the "newest" lane (as of 2026-09-26)

| Component | Newest stable | Status | Source |
|---|---|---|---|
| Elixir | **1.20.4** (2026-08-28) | 1.20 gets bug and security fixes. 1.16–1.19 get security fixes only. **1.15 is out of support** | [VERIFIED: gh releases, elixir.hexdocs.pm compatibility page] |
| Erlang/OTP | **29.1.1** (2026-09-22). Also 28.5.0.7 and **27.3.4.18** | Elixir 1.20 supports OTP **27–29**. Elixir 1.17 supports 25–27 | [VERIFIED] |
| PostgreSQL | **18.6** (`postgres:18`) | PG 19 is at **beta 4** (2026-09-24), with GA planned for October 2026. **PG 14 reaches EOL 2026-11-12**, the floor this repo's min lane proves | [VERIFIED: postgresql.org versioning and roadmap, Docker Hub tags up to `19beta4`] |
| Playwright | 1.63.0 (lock has 1.60.0) | No change is needed for this milestone | [VERIFIED] |
| Hex | 2.5.1 (2.5.2-dev adds SARIF) | | [VERIFIED] |
| dialyxir / credo / ex_doc | 1.4.8 / 1.7.19 / 0.40.4 | | [VERIFIED hex.pm] |

**Recommended newest lane:** add `latest` to the `verify-test` matrix with Elixir `1.20.4`, OTP `29.1`, `postgres:18` and `ubuntu-24.04`. It yields the check name `Run test suite (latest)`.

- Use `postgres:18`, **not** `19beta4`. A beta image in a required lane means red builds from upstream churn. Revisit when PG 19 is GA and the next `postgres:19` tag exists.
- **[INFERENCE, needs a spike]** Elixir 1.20's whole-body type inference will very likely emit new warnings. Under `compile --warnings-as-errors` those break the lane on day one. Measure it locally before deciding whether the lane blocks the build.
- Keep the `current` lane pinned to the committed `.tool-versions`. It is the adopter-default proof, and the Dialyzer and PLT job must match it.

---

## 1. Supply chain: `mix hex.audit` vs `mix_audit` vs GitHub tooling

| Criterion | `mix hex.audit` (Hex 2.5.1) | `mix_audit` (`mix deps.audit`) | GitHub dependency-review-action |
|---|---|---|---|
| Advisory source | EEF CNA / OSV via hex.pm | `mirego/elixir-security-advisories`, synced from GHSA | GitHub Advisory DB, which needs dependency-graph data |
| Has lazy_html advisory today | **Yes** (published 09-25, flagged) | **No**: `packages/lazy_html` is 404 in its DB [VERIFIED] | Only if Mix deps are submitted |
| Has mint 2026 advisory | **Yes** | **No**: only the three older mint GHSAs are present [VERIFIED] | Same as above |
| Retired packages | Yes | No | No |
| Maintenance | Core Hex, active (commits 2026-09-22) | Last release **2.1.5 on 2025-06-09** [VERIFIED] | Active (v5.0.0, node24) |
| New dependency | None | A Hex dev dep | Plus `erlef/mix-dependency-submission` (v1.3.4) with **`contents: write`** |
| Ignore mechanism | `hex: [ignore_advisories: [...]]`, which warns when stale | A YAML ignore file | Config |

**Recommendation: `mix hex.audit` only.** Gate it on every PR in a dedicated fast job, and also run it on a **weekly schedule on `main`**. The scheduled run catches advisories published against an unchanged lock, which PR gating cannot see.
- Scheduled output goes to one tracking issue, reusing the flake lane's issue-upsert pattern.
- Guard the Hex version inside the job: assert `mix hex.info` reports >= 2.5.0. An older Hex silently audits **retirements only**, which gives a false green.

**Integration:**
- `mix.exs` aliases:
  - `"verify.deps_audit": ["deps.unlock --check-unused", "hex.audit"]`
  - root, example app and bench, via `cmd --cd examples/threadline_phoenix mix hex.audit` and `cmd --cd bench mix hex.audit`, or a small `bin/` loop.
- Add it to `ci.all` near the front: it is fast and fails early. **Caveat:** `hex.audit` calls `deps.loadpaths --no-compile` first [VERIFIED in the source], so deps must be *fetched* (not compiled), and it needs network access to hex.pm.
- Add it to `preferred_envs` only if needed. It works in any env.
- CI job `id: verify-deps-audit`, `name: "Audit dependencies (Hex advisories)"`. Add it to the `ci-required` aggregate `needs` and to the CONTRIBUTING job list in the same commit (guide §9).

**Freshness policy (not Dependabot churn).** [INFERENCE, built on verified tool behaviour]
- Hex `cooldown: "7d"` for this repo's resolution.
- A monthly scheduled job runs `mix hex.outdated --within-requirements` across the three lockfiles. It reports into one tracking issue and **does not fail CI**, because freshness is advisory and security is a gate.
- Batched updates happen once per release train: one `mix deps.update --all` commit, gated by the full suite and `hex.audit`.
- Keep the deliberate floor pins (`yaml_elixir ~> 2.11.0`) documented as exceptions.

## 2. CI economy stack

**Deps-only `_build` cache.** [INFERENCE on the design, with verified constraints from the existing ci.yml contract comment, D-19]
- Key: `<runner>-otp<exact>-elixir<exact>-<MIX_ENV>-<variant>-build-${{ hashFiles('mix.lock') }}-${{ hashFiles('config/**/*.exs') }}`. **No `restore-keys`**, which matches the rule already written into ci.yml.
- `variant` separates `full` from `no-optional`: `compile --no-optional-deps` builds a different dep set.
- Config is in the key because Mix recompiles a dep when its app config changes. That is inference, and being conservative here costs little.
- Build the deps-only artifact with a split cache:
  1. `actions/cache/restore`
  2. `mix deps.get`
  3. `mix deps.compile`
  4. `actions/cache/save` (only on a miss, `if: steps.x.outputs.cache-hit != 'true'`)
  5. then `rm -rf _build/$MIX_ENV/lib/threadline` and `mix compile --warnings-as-errors`
- Saving before the project compiles is what makes the cache "deps-only". The project's own beams are never cached, so a stale Threadline beam can never be served.
- Use **exact** OTP versions in keys, which follows from finding 3. With `version-file` and strict mode, read the version from `steps.beam.outputs.otp-version`.

**Dialyzer PLT:** the current design is already correct (`restore-keys` allowed, `mix.exs` in the key, save on miss).
- Change the key's OTP segment to the exact resolved `otp-version` output.
- **Move the `@tag :live_dialyzer` test** (`test/threadline/dialyzer_slice_contract_test.exs`, 540 s timeout, no PLT cache in the test lanes) out of both test lanes: `ExUnit.configure(exclude: [live_dialyzer: true])`, then `mix test --only live_dialyzer` inside `verify-dialyzer`, which owns the PLT cache.
- Per CLAUDE.md "honest default tests", `test/test_helper.exs`, CONTRIBUTING and the topology contract must change together.

**Playwright:** keep caching `~/.cache/ms-playwright` (Chromium only, no `--with-deps`, which is correct on ubuntu-24.04).
- Change the key from `hashFiles(package-lock.json)` to the resolved `@playwright/test` version, currently 1.60.0, read with `jq` from the lockfile in a prior step. Unrelated npm changes then stop busting the browser cache.
- Drop `restore-keys`. A restored old revision is dead weight, because Playwright downloads the exact revision anyway.

**Composite action vs reusable workflow:** use a **composite action** (see "What NOT to use").
- Keep failing-prone steps (`mix compile`, `mix test`, `mix credo`) **outside** it, as named job steps. A failure inside a composite shows under the composite's single step name, which hurts CI DX (guide §9).

**Flake budget:**
- Measured cost: 288 s cold plus about 165 s per repeat, so 50 repeats is about 145 min [VERIFIED from workflow comments].
- **[INFERENCE]** Run it weekly, not nightly, with `mix test --repeat-until-failure 15 --max-failures 1` and `timeout-minutes: 60`. That is about 45 min per week, or roughly 200 runner-min per month, versus about 3,600 today.
- Exclude `:live_dialyzer` and any shell-out-to-example-app tests from the repeat set, since they are deterministic and expensive.
- The 16 *fast* failures (08-28 to 09-12) are "broken", not "flaky". The lane must go green on repeat 1 before any budget is meaningful.

## 3. Repo hygiene stack

**PII / local-path guard: a `git grep` script. Not gitleaks, not trufflehog.**
- `bin/check-local-paths`: `git grep -nIE -e '<pattern>' -- . ':!<allowlisted paths>'`. It exits 1 with `file:line` output.
- Patterns: macOS user homes, Linux user homes, Windows `C:\Users\`, and macOS temp roots (`/private/var/folders`, `/var/folders`, `/private/tmp`).
- **Explicitly allow** the GitHub runner home (`home/runner/`, 350 hits of CI log excerpts, not PII) and known false positives such as the `home/timeline/` route fragment.
- Match on a path segment *after* the home root, so documentation of the pattern itself (for example `/Users/<name>/`) does not self-match.
- Add a contract test that feeds fixtures through the script: a positive, a runner-path allow and a placeholder allow.
- Alias `verify.no_local_paths`. It goes in `ci.all` and in the cheapest existing job, or its own 1-minute job. It runs **after** the forward scrub lands, so it starts green.
- Why not **gitleaks** (v8.30.1, gitleaks-action v3.0.0 node24): its value is the secret ruleset, and GitHub **secret scanning plus push protection are already enabled** [VERIFIED]. A custom local-path rule in `.gitleaks.toml` just re-implements one regex. It adds a binary download, and the default `git` mode scans **history**, which would flag the pre-scrub commits that this milestone deliberately does not rewrite.
- Why not **trufflehog** (v3.97.9): it is built for *verified* live credentials, calls out to providers, and duplicates secret scanning. Wrong tool for path and PII detection.
- Also recommend (maintainer toggle) `secret_scanning_non_provider_patterns`, currently disabled. It covers generic high-entropy strings at zero CI cost. [WEB/INFERENCE; check the plan eligibility for a user-owned public repo]

**xref cycles:**
- Keep `verify.xref_cycles` (compile-connected, `--fail-above 0`) as is.
- **[INFERENCE]** Add a ratchet for *all* cycles: `mix xref graph --format cycles --fail-above 5` as `verify.xref_cycles_all`. The count can only fall, and the layer-crossing capture/semantics pair gets a named decision.
- Put it in `ci.all` and the current lane only. It is the same compile, so there is no extra cost.

## 4. ExUnit `@tag :tmp_dir` semantics [VERIFIED from the source at v1.15.8 and v1.17.3, and the v1.20.4 docs]

- The path is `Path.expand(Path.join(["tmp", escape(inspect(module)), "#{escape(test_name)}-#{short_hash}", extra]))`.
- The path is **relative to the current working directory when the test starts**, so it lands in `<project>/tmp/...`, which is already covered by `.gitignore` `tmp/`.
- It is unique per module and test (a short hash guards collisions), so it is **async-safe**.
- `File.rm_rf!` runs **before** `mkdir_p!`, so each run starts empty. It is **not** deleted after the test, and it is left for debugging.
- The escape set is `space ~ # % & * { } \ : < > ? / + | "`, each replaced with `-`.
- Available since 1.11. The implementation is identical in 1.15.8 and 1.17.3, so the min lane is safe.
- Use `@tag tmp_dir: "sub"` for a subpath. Also available: `@moduletag :tmp_dir` and `@describetag`.
- **Footguns for this repo:**
  - 43 test references to `File.cd` or `File.cwd` exist. A test that `cd`s before the tag is evaluated moves the root.
  - Tests that **walk the working tree** (planning-independence, doc-contract and clean-checkout tests) or run the new local-path guard over untracked files will now see `tmp/`. The guard must use `git grep` on tracked files, and the tree-walkers must exclude `tmp/`.
  - `tmp_dir` paths are absolute and contain the home directory. Never write them into committed fixtures, snapshots or evidence. That is the PII rule again.

---

## Installation / integration sketch

```bash
# Lock-only remediation (root). No mix.exs change needed.
mix deps.update lazy_html mint
(cd bench && mix deps.update --all)          # 8 advisories, 3 HIGH
mix hex.audit && (cd examples/threadline_phoenix && mix hex.audit) && (cd bench && mix hex.audit)

# Commit .tool-versions (currently untracked), bumped to the latest 27 patch:
#   erlang 27.3.4.18 / elixir 1.17.3-otp-27 / nodejs 22.14.0
```

```elixir
# mix.exs aliases (additions)
"verify.deps_audit": ["deps.unlock --check-unused", "hex.audit",
                      "cmd --cd examples/threadline_phoenix mix hex.audit",
                      "cmd --cd bench mix hex.audit"],
"verify.no_local_paths": ["cmd bin/check-local-paths"],
"verify.xref_cycles_all": ["xref graph --format cycles --fail-above 5"],
# mix.exs project/0 (only if an unfixable advisory ever appears; each entry needs a comment):
# hex: [ignore_advisories: []]
```

```yaml
# .github/actions/setup-elixir/action.yml (composite). Setup only; no failing work inside.
# steps: erlef/setup-beam@v1 (version-file: .tool-versions, version-type: strict, id: beam)
#        actions/cache@v5 deps (restore-keys ok)
#        actions/cache/restore@v5 _build deps-only (exact key, no restore-keys)
#        mix deps.get --check-locked ; mix deps.compile ; actions/cache/save@v5 on miss
```

## Alternatives Considered

| Recommended | Alternative | When to use the alternative |
|---|---|---|
| `mix hex.audit` | `mix_audit` 2.1.5 | Never here. Its DB lags the EEF CNA feed (verified missing both current advisories), and its last release was in 2025. |
| `mix hex.audit` weekly on `main` | `erlef/mix-dependency-submission` v1.3.4 + Dependabot alerts for Hex + `dependency-review-action` v5 | Only if the maintainer wants GitHub-UI alerts for Hex. It costs a `contents: write` workflow, and native Hex dependency-graph support is not shipped (dependabot-core#15020 closed unmerged 2026-09-22, and Hex is absent from GitHub's supported-ecosystems table). |
| Composite action | Reusable workflow (`workflow_call`) | For whole-job reuse *across repos*. Not here: see "What NOT to use". |
| `git grep` path guard | gitleaks 8.30.1 with custom rules | If the repo ever loses GitHub secret scanning, or needs pre-commit secret rules offline. |
| `postgres:18` newest lane | `postgres:19beta4` | A non-required, `continue-on-error` canary only. Revisit after PG 19 GA in October 2026. |
| Split restore/save cache | `actions/cache` single step | Fine for `deps/`. Not for deps-only `_build`, which must save *before* the project compiles. |
| Weekly bounded flake lane | Nightly with 50 repeats | Only after a real intermittent flake is being hunted, and as a temporary `workflow_dispatch` with an input count. |

## What NOT to Use

| Avoid | Why | Use instead |
|---|---|---|
| `mix_audit` / `mix deps.audit` | Stale release and a lagging advisory DB. It does not see lazy_html or mint today [VERIFIED]. | `mix hex.audit` (Hex >= 2.5.0) |
| Hex older than 2.5.0 in the audit job | `hex.audit` then checks **retirements only**, which gives a false green | Assert the Hex version in the job |
| `mix hex.audit --format sarif` | Only in 2.5.2-**dev** and requires OTP 27+ [VERIFIED changelog] | Plain text output. Revisit when 2.5.2 ships. |
| Dependabot `package-ecosystem: mix` version updates | PR churn, which the guide explicitly rejects. Floor pins (`yaml_elixir ~> 2.11.0`) would generate perpetual PRs to be closed. | Monthly `hex.outdated` report plus a batched release-train update |
| `actions/dependency-review-action` for Hex | No Hex dependency graph without a write-scoped submission workflow, and it duplicates `hex.audit` | `hex.audit` |
| Reusable workflows for setup dedupe | Called-workflow jobs render as `caller / callee` check names. That breaks the single required aggregate, the stable-name contract and `ci_topology_contract_test`. They also cannot share `services:` shapes easily. | Composite action, with job IDs and names unchanged |
| `_build` cache with `restore-keys` or including `_build/*/lib/threadline` | Stale compiled artifacts are the D-19 footgun already documented in ci.yml | Exact-key, deps-only `_build` cache plus `rm -rf _build/$MIX_ENV/lib/threadline` |
| `otp-version: "27.0"` (loose) | Resolves to OTP 27.0.1 from 2024 [VERIFIED] | `version-file: .tool-versions` with `version-type: strict` |
| `actions/cache@v4`, `upload-artifact@v4`, `release-please-action@v4` | node20, past the 2026-09-23 removal | v5 / v7 / v5 |
| `ubuntu-22.04` min lane | Deprecated 2026-09-17, removed 2027-04-17 | `ubuntu-24.04`. The key already includes the runner label, so there is no cache collision. |
| gitleaks / trufflehog for the path guard | Duplicates the enabled secret scanning. History mode flags the unrewritten past. Adds a binary and a network dependency. | `bin/check-local-paths` (git grep, tracked files only) |
| `git filter-repo` / BFG history rewrite | Explicitly out of scope ("no history rewrite") | A forward scrub plus a guard |
| `postgres:19beta*` in a required lane | Upstream beta churn turns into red builds | `postgres:18` |
| `--repeat-until-failure` in the min lane | Needs Elixir 1.17+ | Current or latest lane only |

## Version Compatibility

| Package A | Compatible with | Notes |
|---|---|---|
| lazy_html 0.1.13 | Elixir ~> 1.15 | Keeps the min lane. It ships precompiled NIFs via cc_precompiler. **Verify in CI** that the OTP 26 / ubuntu-24.04 artifact exists after moving off 22.04 [MEDIUM]. |
| mint 1.10.1 | Elixir ~> 1.15, finch ~> 0.21 range (`mint ~> 1.8`) | A lock-only bump |
| Elixir 1.20.4 | OTP 27–29 | 1.20 cannot run on OTP 26. The latest lane pairs it with OTP 29. |
| Elixir 1.17.3 | OTP 25–27 | Current lane. Bump OTP to 27.3.4.18. |
| Elixir 1.15.x | OTP 24–26 | **Out of upstream support.** The floor decision belongs to v1.45 (1.0 API contract), not this milestone. |
| PostgreSQL 14 | EOL 2026-11-12 | The min-lane floor goes EOL during the ladder. This is a v1.45 scope decision to flag, not an action for v1.43. |
| setup-beam v1.24.1 + `.tool-versions` | strict mode required | It errors if both `version-file` and `otp-version` / `elixir-version` are given. Matrix jobs keep explicit inputs. |
| `ci_topology_contract_test.exs:396`, `ci_workflow_parity_contract_test.exs:255` | Pin `"27.0"` and `actions/cache@v4` | These must change in the **same commit** as the workflow edits, or `mix verify.test` goes red. |

## Sources

- hex.pm API: `/api/packages/{lazy_html,mint,mix_audit,plug,postgrex,dialyxir,credo,ex_doc,stream_data}` and release metadata for lazy_html 0.1.13 and mint 1.10.1 [VERIFIED]
- OSV API: `EEF-CVE-2026-92106` (fixed 0.1.13) and `EEF-CVE-2026-82672` (fixed 1.10.1) [VERIFIED]
- Hex CHANGELOG and `lib/mix/tasks/hex.audit.ex` at v2.5.1; commit history of the audit task (#1150 advisories, #1198 ignores, #1203 SARIF) [VERIFIED]
- `mirego/elixir-security-advisories` contents via `gh api` (lazy_html missing, mint 2026 GHSA missing); `mirego/mix_audit` tags [VERIFIED]
- `gh api` releases for erlef/setup-beam, actions/cache, actions/checkout, actions/setup-node, actions/upload-artifact, actions/dependency-review-action, gitleaks, gitleaks-action, trufflehog, elixir-lang/elixir, erlang/otp, microsoft/playwright, release-please-action, alls-green; `action.yml` `runs.using` per pinned ref [VERIFIED]
- erlef/setup-beam README and `src/setup-beam.js` at v1.24.1 (`.tool-versions` parser) [VERIFIED]
- Elixir source `lib/ex_unit/lib/ex_unit/runner.ex` at v1.15.8 and v1.17.3 (`create_tmp_dir!`); ExUnit.Case docs v1.20.4; `mix help test`, `mix help deps.unlock`, `mix help deps.get`; `deps.get.ex` at v1.14.5 and v1.15.8 [VERIFIED]
- [Elixir compatibility and deprecations](https://hexdocs.pm/elixir/compatibility-and-deprecations.html) [VERIFIED]
- [PostgreSQL versioning policy](https://www.postgresql.org/support/versioning/), [PostgreSQL roadmap](https://www.postgresql.org/developer/roadmap/), Docker Hub `library/postgres` tags [VERIFIED]
- [Deprecation of Node 20 on GitHub Actions runners](https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/) (removal 2026-09-23) [VERIFIED]
- [actions/runner-images#14254](https://github.com/actions/runner-images/issues/14254) (ubuntu-22.04 deprecation) [VERIFIED]
- [GitHub dependency graph supported ecosystems](https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/dependency-graph-supported-package-ecosystems) (no Hex); [dependabot-core#15020](https://github.com/dependabot/dependabot-core/pull/15020) (closed unmerged); [erlef/mix-dependency-submission](https://github.com/erlef/mix-dependency-submission) [VERIFIED]
- Local runs on 2026-09-26: `mix hex.audit` (root, example, bench), `mix hex.outdated`, `mix deps.unlock --check-unused`, `mix xref graph --format cycles` (with and without label), `git grep` path census; `gh run view` logs of the latest green CI run; `gh api repos/szTheory/threadline` security settings [VERIFIED]
