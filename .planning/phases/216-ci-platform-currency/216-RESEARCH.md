# Phase 216: CI Platform Currency - Research

**Researched:** 2026-09-26
**Domain:** GitHub Actions toolchain pinning (erlef/setup-beam), JavaScript-action runtime currency (Node 20 → Node 24), runner-image currency, release-please upgrade rehearsal
**Confidence:** HIGH (every load-bearing claim was probed live this session: action manifests fetched at the exact refs, builds.hex.pm listings, a real CI log, a Docker NIF probe, and a release-please dry-run)

## Summary

CI today runs **three different Erlang/OTP builds in one workflow run**, and none of them is the one the maintainer's `.tool-versions` names. Every non-matrix job pins `otp-version: "27.0"`, which setup-beam's default loose matching resolves to `OTP-27.0.1`. The `verify-test` current lane pins `otp: "27"`, which resolves to the newest 27.x (`OTP-27.3.4.18` today). The min lane resolves `OTP-26.2.5.21` on `ubuntu-22.04`. The untracked `.tool-versions` says `erlang 27.3.4.15` [VERIFIED: CI run 36258719902 log, see Code Examples]. The fix is the documented setup-beam path: `version-file: .tool-versions` + `version-type: strict` (setup-beam refuses a version file unless strict is set, and errors if YAML version inputs are set too). Every cache key must then come from the step outputs (`steps.beam.outputs.otp-version` → `OTP-27.3.4.15`, `steps.beam.outputs.elixir-version` → `v1.17.3-otp-27`), not literals.

Node 20 was removed from GitHub-hosted runners on 2026-09-23. Actions that declare `node20` are currently being **force-run on Node 24** with a warning annotation. The live main run already carries `Node.js 20 is deprecated ... being forced to run on Node.js 24: actions/cache@v4` [VERIFIED: run 36258719902]. Probing every `uses:` ref's `action.yml` shows exactly three node20 actions in the tree: `actions/cache@v4` (plus its `restore`/`save` sub-actions), `actions/upload-artifact@v4`, and `googleapis/release-please-action@v4`. Everything else (`checkout@v5`, `setup-beam@v1`, `setup-node@v5`, `github-script@v8`) is already node24. `re-actors/alls-green@<sha>` is a composite action that only runs bash. release-please-action v5.0.0 differs from v4.4.1 **only** in `runs.using` (the `action.yml` diff is one line) and a bundled-library bump from 17.3.0 to 17.6.0. A dry-run of both library versions against the real repo config gave byte-identical output (apart from npm warnings).

The min lane can move to `ubuntu-24.04` with low risk. builds.hex.pm publishes 36 OTP 26 builds for ubuntu-24.04, up to `OTP-26.2.5.21`. lazy_html 0.1.13 ships only a `nif-2.16` x86_64-linux-gnu artifact, and elixir_make picks it for any VM with NIF ≥ 2.16. The artifact was built on Ubuntu 20.04 (GCC 9.4) and needs only `GLIBC_2.14` / `GLIBCXX_3.4.21`. A Docker probe on Ubuntu 24.04.5 (glibc 2.39) with OTP 26 (NIF 2.17) downloaded that artifact and ran a real LazyHTML query, with no `make` on PATH, so a source-compile fallback was impossible. The success criterion still asks for a green CI run ID, so that proof is a post-push maintainer-gated step.

**Primary recommendation:** Track `.tool-versions`, switch every non-matrix setup-beam step to `id: beam` + `version-file: .tool-versions` + `version-type: strict`. Give the `verify-test` matrix one strict step fed by matrix values (current row = `version-file`, min row = exact `26.2.5.21`/`1.15.8` on `ubuntu-24.04`). Rebuild every BEAM-dependent cache key from `steps.beam.outputs.*`. Bump the three node20 actions to `cache@v5`, `upload-artifact@v7` and `release-please-action@v5`, with the release-please bump in its own `ci:` commit plus a runbook dry-run rehearsal. Lock all of it with offline ExUnit contract tests in the existing idiom (a pure classifier plus mutation controls).

## User Constraints

No CONTEXT.md exists for this phase. The user chose to plan from research + requirements. Binding constraints come from REQUIREMENTS.md, ROADMAP.md, CLAUDE.md, and MILESTONE-GUIDE.txt (below).

<phase_requirements>
## Phase Requirements

| ID | Description (verbatim, REQUIREMENTS.md:43-49) | Research Support |
|----|-------------|------------------|
| PLAT-01 | "CI runs the Erlang/OTP it claims. `.tool-versions` is committed. Non-matrix jobs use setup-beam `version-file` in strict mode, and the `"27.0"` → 27.0.1 drift is gone. Every cache key uses the resolved OTP/Elixir versions. The contract tests assert the new pins." | setup-beam source + README (version-file requires strict, mutually exclusive with YAML inputs, outputs `OTP-x` / `vX-otp-N`). Full inventory of 20 setup-beam steps and every cache key (Pattern 1–3). Release.yml ref-switching pitfall (Pitfall 1). Exact test lines that go red (Pitfall 4). |
| PLAT-02 | "No workflow uses a Node 20 action. That means `actions/cache@v5`, `upload-artifact@v7`, and `release-please-action@v5`. The release-please bump lands in its own commit and is rehearsed through the release runbook." | Runtime of every `uses:` ref probed (table in Standard Stack). v4→v5 release-please diff = runtime only. Dry-run rehearsal command proven live (Code Examples). Allowlist classifier test design (Pattern 4). |
| PLAT-03 | "The min lane runs on a supported runner image (off the deprecated `ubuntu-22.04`), with lazy_html's OTP 26 NIF verified to resolve there." | ubuntu-22.04 deprecation dates. OTP 26 builds exist on ubuntu-24.04. lazy_html artifact list, glibc needs, and a Docker positive probe. Log-grep proof recipe for the post-push run (Validation Architecture). |
</phase_requirements>

## Project Constraints (from CLAUDE.md and MILESTONE-GUIDE.txt)

- **Stable CI job IDs**: job `id:` keys stay immutable. `name:` may evolve. Nothing in this phase renames a job. `Run test suite (min)` / `(current)` are composed from the `lane` axis, and the runner is not part of the check name, so changing the min runner does not touch branch protection. [VERIFIED: ci.yml:279-285 comment + parity test lines 232-241]
- **Named entrypoints**: cite `mix verify.*` / `mix ci.all`. Contract tests run under `mix test` (and so `mix verify.test`).
- **Honest default tests**: no silent exclusion. New contract tests are plain `async: true` ExUnit files.
- **Doc contract tests**: CONTRIBUTING prose changes in the same commit as the workflow/test changes it describes (CONTRIBUTING's job list and topology tests change together, per MILESTONE-GUIDE §9).
- **Zero human verification by default**: automate. Hand the maintainer only push/publish/merge. The CI-run-ID criteria (1 and 3) need a pushed branch, so they are maintainer-gated post-push steps.
- **No GSD vocabulary** (phase numbers, plan IDs, requirement IDs) in workflow comments, product code, shipped commit subjects, or CONTRIBUTING (MILESTONE-GUIDE §8).
- **Tests are never tautological** (MILESTONE-GUIDE §8). A string-presence assertion needs a failure class behind it. Use the repo's pure-function-plus-mutation-controls idiom (`dialyzer_topology_errors/3`).
- **"Do not rewrite historical receipts"** (MILESTONE-GUIDE §8): the CONTRIBUTING Dialyzer cold/hit evidence (run 34642915672, "resolving to Erlang/OTP 27.0.1") is a historical receipt. Keep it as dated history. Update only the present-tense "current lane" sentence.
- **One-shot probes run locally and are recorded as evidence** (MILESTONE-GUIDE §9). This covers the lazy_html Docker probe and the release-please dry-run.
- **Local gotchas (memory)**: never `git add .planning/` wholesale. `ci.all` red at Dialyzer usually means a PLT cache miss (`mix dialyzer --plt`). Worktrees have no `deps/`/`_build`, so Elixir suites cannot run in one. All plans here edit `.github/workflows/ci.yml`, so run them **sequentially without worktrees**.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Toolchain version truth | Repo file `.tool-versions` | setup-beam `version-file` | One SSOT read by asdf locally and setup-beam in CI. Drift becomes impossible, not merely detected. |
| Toolchain resolution | CI runner (setup-beam action) | builds.hex.pm | setup-beam resolves against builds.hex.pm listings per runner image. |
| Cache identity | Workflow YAML (`actions/cache` key) | setup-beam step outputs | Keys must reflect what was *installed*, not what was *requested*. |
| Action runtime currency | Workflow YAML `uses:` refs | ExUnit contract test | The grep test is the regression gate. The YAML is the fix. |
| Release automation upgrade | `release.yml` release-please job | CONTRIBUTING runbook | The runbook owns the rehearsal procedure. The workflow owns the pin. |
| Min-floor proof | `verify-test` matrix `min` row | lazy_html precompiled NIF | The runner image hosts the floor lane. The NIF is the known image-sensitive dependency. |

## Standard Stack

### Action inventory: every `uses:` in `.github/workflows/*.yml`

Counts from `grep -rhoE "uses: *[^ ]+" .github | sort | uniq -c`. Runtimes fetched from each ref's `action.yml` this session.

| Ref in tree | Count | `runs.using` at that ref | Target | Latest major available | Action |
|---|---|---|---|---|---|
| `actions/checkout@v5` | 27 | `node24` | keep `@v5` | v7.0.1 (2026-07-20) | none (node24 already) |
| `erlef/setup-beam@v1` | 20 | `node24` | keep `@v1` | v1.24.1 (2026-06-28) | add `id: beam`, `version-file`, `version-type` |
| `actions/cache@v4` | 16 | `'node20'` | **`@v5`** (`'node24'`) | v6.1.0 (2026-06-26) | bump |
| `actions/cache/restore@v4` | 1 | (sub-action, v4 = `node20`) | **`@v5`** (`'node24'`) | — | bump |
| `actions/cache/save@v4` | 1 | (sub-action, v4 = node20) | **`@v5`** (`'node24'`) | — | bump |
| `actions/setup-node@v5` | 3 | `'node24'` | keep `@v5` | v7.0.0 (2026-07-14) | none |
| `actions/upload-artifact@v4` | 3 | `'node20'` | **`@v7`** (`'node24'`) | v7.0.1 (2026-04-10) | bump |
| `actions/github-script@v8` | 1 | `node24` | keep `@v8` | v9.0.0 (2026-04-09) | none |
| `googleapis/release-please-action@v4` | 1 | `'node20'` | **`@v5`** (`'node24'`) | v5.0.0 (2026-04-22) | bump, own commit |
| `re-actors/alls-green@b5b5b37504aa4183270bd3d855c52a67f212be35` | 1 | `composite` (one `run:` step, `shell: bash`, no nested `uses:`) | keep SHA pin | — | none |

[VERIFIED: `curl raw.githubusercontent.com/<repo>/<ref>/action.yml` for each ref; `gh api repos/<repo>/releases` for latest majors; restore/save sub-actions fetched at `actions/cache/v5/{restore,save}/action.yml` = `using: 'node24'`, `v4/restore` = `using: 'node20'`]

**Why the requirement's majors and not the newest:** `cache@v6` (ESM migration, "Update packages") and `checkout@v7` / `setup-node@v7` / `github-script@v9` exist, but they are not needed to meet "no Node 20 action", and REQUIREMENTS.md names `cache@v5` and `upload-artifact@v7` explicitly. Taking extra majors is scope creep with its own risk. Recommend the named majors exactly. [CITED: github.com/actions/cache/releases/tag/v6.0.0]

**Breaking-change review for the bumps:**
- `cache@v5`: "runs on the Node.js 24 runtime and requires a minimum Actions Runner version of `2.327.1`". No input/output changes. GitHub-hosted runners are on 2.337.0 (per CONTRIBUTING evidence). [CITED: github.com/actions/cache/releases/tag/v5.0.0]
- `upload-artifact@v5` (node24 support, `@actions/artifact` v4), `@v6` (node24 default), `@v7` (ESM, new opt-in `archive: false` input for single-file direct uploads). The repo uses only `name`, multi-line `path` (including absolute `/tmp/threadline_phoenix_e2e.log`), `if-no-files-found: warn`, and `retention-days: 14`, all unchanged. [CITED: github.com/actions/upload-artifact/releases v5.0.0/v6.0.0/v7.0.0]
- `release-please-action@v5.0.0`: "⚠ BREAKING CHANGES: upgrade to node24" plus "bump release-please from 17.3.0 to 17.6.0". `diff` of `action.yml` v4.4.1 vs v5.0.0 is exactly `using: 'node20'` → `using: 'node24'`. Inputs (`token, release-type, path, target-branch, config-file, manifest-file, repo-url, github-api-url, github-graphql-url, fork, include-component-in-tag, proxy-server, skip-github-release, skip-github-pull-request, skip-labeling, changelog-host, versioning-strategy, release-as`) and outputs are unchanged. The repo's `with:` (`token`, `config-file`, `manifest-file`) and consumed outputs (`release_created`, `tag_name`, `version`, `sha`, `prs_created`) need no edits. [VERIFIED: diff /tmp/rp4.yml /tmp/rp5.yml; gh api release v5.0.0 body]

### Platform deadlines (why now)

| Event | Date | Source |
|---|---|---|
| Runners default to Node 24 | 2026-06-16 | [CITED: github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners] |
| Node 20 removed from runners | 2026-09-23 | same |
| ubuntu-22.04 deprecation begins | 2026-09-17 | [CITED: github.com/actions/runner-images/issues/14254] |
| ubuntu-22.04 fully unsupported | 2027-04-17 (brownouts on Mar 23/30, Apr 6/13) | same |
| Recommended targets | "`ubuntu-24.04`, `ubuntu-26.04`, or `ubuntu-latest`" | same |

Choose `ubuntu-24.04` for the min lane, not `ubuntu-26.04`. setup-beam's README compatibility table lists only 22.04 (OTP 24.2–29) and 24.04 (OTP 24.3–29), and every other job already runs 24.04. builds.hex.pm does have 33 OTP-26 builds for ubuntu-26.04, but that would be a new, unlisted combination. [VERIFIED: setup-beam README; curl builds.hex.pm/builds/otp/amd64/ubuntu-26.04/builds.txt]

### Toolchain availability on builds.hex.pm (amd64)

| Version | ubuntu-24.04 listing | Notes |
|---|---|---|
| `OTP-27.3.4.15` (the committed pin) | present, built 2026-07-27 | newer patches exist: `.16`, `.17`, `.18` (2026-09-22) |
| `OTP-27.0.1` (the current drift) | present | what `"27.0"` loose resolves to |
| `OTP-26.2.5.21` | present (36 OTP-26 builds total) | highest OTP 26. Also the min lane's current loose resolution. |
| Elixir `v1.17.3-otp-27` | present | matches `.tool-versions` `1.17.3-otp-27` |
| Elixir `v1.15.8-otp-26` | present | min lane's current loose resolution of `"1.15"` |

[VERIFIED: curl builds.hex.pm/builds/otp/amd64/ubuntu-24.04/builds.txt and builds.hex.pm/builds/elixir/builds.txt]

**Installation:** none. No package is added to any `mix.exs` or `package.json`. `npx -y release-please@17.3.0` / `@17.6.0` are one-shot rehearsal invocations only.

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| release-please (one-shot `npx`, rehearsal only, not installed) | npm | latest publish 2026-08-24 | 167,974/wk | github.com/googleapis/release-please | [OK] (`gsd-tools query package-legitimacy check`), `postinstall: null` | Approved for the rehearsal command |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none
GitHub Actions are not registry packages. Their provenance is the official `actions/*`, `erlef/*` and `googleapis/*` orgs, confirmed by fetching each `action.yml` at the exact ref.

## Architecture Patterns

### System Architecture Diagram

```
                .tool-versions (tracked)            builds.hex.pm/builds/otp/amd64/ubuntu-24.04/builds.txt
                erlang 27.3.4.15                                  │
                elixir 1.17.3-otp-27                              │
                       │                                          │
   push / PR ──▶ job ──┼─▶ checkout@v5 ──▶ setup-beam@v1 (id: beam, version-file, version-type: strict)
                       │                         │  exact match or ERROR (no silent drift)
                       │                         ▼
                       │          outputs: otp-version=OTP-27.3.4.15, elixir-version=v1.17.3-otp-27
                       │                         │
                       │                         ▼
                       │    cache@v5 key = <runner>-<otp-version>-elixir-<elixir-version>-mix-deps-<lock hash>
                       │                         │
                       │                         ▼
                       │               mix deps.get → compile → verify.*
                       │
  verify-test matrix ──┴─▶ min row: otp 26.2.5.21 / elixir 1.15.8 / ubuntu-24.04 (strict, explicit)
                          current row: version-file .tool-versions / ubuntu-24.04
                                    │
                                    ▼ deps.get fetches lazy_html 0.1.13 → elixir_make downloads
                                      lazy_html-nif-2.16-x86_64-linux-gnu-0.1.13.tar.gz (NIF 2.16 ≤ VM 2.17)

  release.yml jobs that check out ANOTHER ref (release-please branch / release tag):
     checkout@v5 (workflow SHA, sparse .tool-versions, no creds) → setup-beam version-file → checkout@v5 (target ref)

  ExUnit contract tests (offline, mix test):
     workflow YAML ──▶ pure classifier(s) ──▶ [] | [errors]  ◀── synthetic mutated YAML (must be non-empty)
```

### Recommended file touch map

```
.tool-versions                                   # git add (currently untracked); content unchanged
.github/workflows/ci.yml                         # 15 setup-beam steps, 14 cache keys, matrix rows, comments
.github/workflows/browser-full.yml               # setup-beam + deps key + cache@v5 + upload-artifact@v7
.github/workflows/flake-detection.yml            # setup-beam + deps key (drop runner.os) + cache@v5 + upload-artifact@v7
.github/workflows/deps-health.yml                # setup-beam (no cache)
.github/workflows/release.yml                    # 3 setup-beam steps (toolchain-first checkout) + release-please-action@v5
bin/verify-bump-rehearsal                        # lines 234-243: the "untracked .tool-versions" copy block/comment
CONTRIBUTING.md                                  # lines 22-42 (toolchain policy), 563, 579-583 (Dialyzer lane sentence), + runbook subsection
test/threadline/ci_topology_contract_test.exs    # dialyzer_topology_errors pins + mutation control (lines 142, 396-411)
test/threadline/ci_workflow_parity_contract_test.exs  # "dependency cache contract" (line 255) + new pin/key assertions
test/threadline/ci_action_runtime_contract_test.exs   # NEW: node20-free allowlist classifier
```

### Pattern 1: Non-matrix job, version-file strict, resolved-output cache key

**What:** Replace the literal pins and the literal key segments in every non-matrix job.
**When to use:** All 13 non-matrix setup-beam steps in ci.yml, plus browser-full, flake-detection, deps-health and the 3 release.yml jobs (release.yml uses Pattern 3).
```yaml
# Source: setup-beam README "Version file" + action.yml inputs/outputs (fetched at ref v1)
      - uses: actions/checkout@v5

      - id: beam
        uses: erlef/setup-beam@v1
        with:
          version-file: .tool-versions
          version-type: strict

      - name: Cache deps
        uses: actions/cache@v5
        with:
          path: deps
          key: ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-mix-deps-${{ hashFiles('mix.lock') }}
          restore-keys: ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-mix-deps-
```
Resolved key example: `ubuntu-24.04-OTP-27.3.4.15-elixir-v1.17.3-otp-27-mix-deps-<sha256>`.
- Output formats: `otp-version` = `OTP-27.3.4.15` and `elixir-version` = `v1.17.3-otp-27`. Evidence: the CI log prints `Installing Erlang/OTP OTP-27.0.1` / `Installing Elixir v1.17.3-otp-27`. setup-beam source calls `core.setOutput('otp-version', otpVersion)` with the same variable it logs in `startGroup(\`Installing Erlang/OTP ${otpVersion} ...\`)`, and the same holds for Elixir. [VERIFIED: setup-beam src/setup-beam.js lines ~62-83, ~90-104 at ref v1; run 36258719902 log]
- The hyphenated output in dot syntax (`steps.beam.outputs.otp-version`) is valid. The repo already uses `steps.dialyzer-plt-restore.outputs.cache-hit` (ci.yml:171). [VERIFIED: ci.yml:171]
- `.tool-versions` also contains `nodejs 22.14.0`. setup-beam ignores it: `const APPS = ['erlang', 'elixir', 'gleam', 'rebar']` and `parseToolVersionsFile` keeps only `APPS.includes(app)`. [VERIFIED: setup-beam src line 15, 820-831]
- The `-otp-27` suffix in `elixir 1.17.3-otp-27` is handled: `getElixirVersion` extracts `userSuppliedOtp` via `/-otp-(\d+)/`, strips it for strict matching of `1.17.3`, and downloads `v1.17.3-otp-27`. [VERIFIED: setup-beam src 221-297]
- Keep the literal runner label in the key (`ubuntu-24.04`) and never `runner.os`. The existing CACHE KEY CONTRACT comment and its anti-regression grep ban the OS-family value. [VERIFIED: ci.yml:65-93]

### Pattern 2: The verify-test matrix, one strict step fed by matrix values

**What:** Keep `lane: [min, current]` as the only base axis (check names unchanged). The current row reads `.tool-versions`. The min row pins its exact floor build. Both run on `ubuntu-24.04`.
```yaml
    strategy:
      fail-fast: false
      matrix:
        lane: [min, current]
        include:
          - lane: min
            elixir: "1.15.8"
            otp: "26.2.5.21"
            pg: "14"
            runner: "ubuntu-24.04"
          - lane: current
            version-file: ".tool-versions"
            pg: "16"
            runner: "ubuntu-24.04"
    runs-on: ${{ matrix.runner }}
    ...
      - id: beam
        uses: erlef/setup-beam@v1
        with:
          version-file: ${{ matrix.version-file }}
          otp-version: ${{ matrix.otp }}
          elixir-version: ${{ matrix.elixir }}
          version-type: strict

      - name: Cache deps
        uses: actions/cache@v5
        with:
          path: deps
          key: ${{ matrix.runner }}-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-mix-deps-${{ hashFiles('mix.lock') }}
          restore-keys: ${{ matrix.runner }}-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-mix-deps-
```
Why this is safe, from the setup-beam source. `getInput(name, required, alt, versions)` throws only when **both** a YAML input and a version-file value are non-empty (`if (input && alternativeValue)`). An empty `version-file` input skips parsing entirely (`if (versionFilePath)`). So the min row, with `version-file` empty, uses its explicit pins, and the current row, with `otp`/`elixir` empty, uses the file. [VERIFIED: setup-beam src 26-39, 801-818] The one assumption: a matrix key missing from a row renders as an empty string in `with:`. [ASSUMED, standard Actions null→'' coercion; confirm with `actionlint` locally and on the first CI run.]

Why exact min pins: `version-type` is one step input, so strict applies to both rows. Pinning `26.2.5.21` / `1.15.8` equals today's loose resolution on the min lane (CI log: `OTP-26.2.5.21 - built on amd64/ubuntu-22.04`, `Elixir v1.15.8-otp-26`). The only behavioral change is therefore the runner image, and future OTP-26 patch drift becomes an explicit edit. [VERIFIED: run 36258719902 job "Run test suite (min)"]

**Fallback if the matrix-expression approach misbehaves:** give the current row explicit `otp: "27.3.4.15"` / `elixir: "1.17.3"` and add a parity assertion that those equal the parsed `.tool-versions` values. This satisfies PLAT-01, which requires version-file only for *non-matrix* jobs.

### Pattern 3: Jobs that check out a different ref (release.yml)

**What:** `sync-release-pr-pins` checks out `release-please--branches--main`. `publish-hex` and `smoke-published` check out `needs.release-ref.outputs.checkout_ref`, which can be an older tag on `workflow_dispatch` recovery. After this phase, `.tool-versions` may not exist at those refs: a stale release-please branch based on pre-landing main (release-please does not rebase for non-releasable commits), or any tag ≤ v0.11.0. setup-beam would then fail with "The specified version file, .tool-versions, does not exist". [VERIFIED: setup-beam src 862-872; release.yml:131-139, 410-417, 557-564]
**Fix (keeps today's semantics, where the toolchain comes from the workflow's own commit):** read the toolchain from the workflow SHA before switching refs.
```yaml
      - name: Read the toolchain pin from this workflow's commit
        uses: actions/checkout@v5
        with:
          sparse-checkout: .tool-versions
          sparse-checkout-cone-mode: false
          persist-credentials: false

      - id: beam
        uses: erlef/setup-beam@v1
        with:
          version-file: .tool-versions
          version-type: strict

      - uses: actions/checkout@v5
        with:
          ref: ${{ needs.release-ref.outputs.checkout_ref }}   # (or release-please--branches--main)
          persist-credentials: false                          # keep the existing value where present
```
setup-beam installs into the runner tool cache and PATH, outside the workspace, so the second checkout's clean does not undo it. `persist-credentials: false` on the toolchain checkout matters: `sync-release-pr-pins` deliberately compiles dependencies with no persisted credential (release.yml:125-130 comment). [ASSUMED: checkout@v5 `sparse-checkout` + `sparse-checkout-cone-mode: false` fetches a single root file. This is the documented checkout input pair; verify with actionlint and the first release-path run, which is dry-run-able via `workflow_dispatch dry_run: true`, a maintainer action.]

### Pattern 4: The "no Node 20 action" contract test (allowlist, fail-closed)

**What:** A new `test/threadline/ci_action_runtime_contract_test.exs` in the repo idiom: glob workflows (both extensions, refuse an empty glob), a **pure** `node20_errors(yaml_by_path)` function returning a list of errors, a live assertion that the result is `[]`, and **mutation controls** that feed synthetic YAML into the same function and assert it goes non-empty.
**Why allowlist, not denylist:** a denylist (`cache@v4`, `upload-artifact@v4`, `release-please-action@v4`) passes vacuously when someone adds a *different* node20 action. The allowlist is a map of `{"owner/repo[/path]", "ref"} => runtime` verified at research time. Any unknown ref fails with "fetch its action.yml, confirm `runs.using` is node24 or composite/docker, then add it here". That catches the failure class that matters: new or re-pinned node20 actions.
```elixir
# Idiom source: test/threadline/ci_topology_contract_test.exs (workflow_paths/0, dialyzer_topology_errors/3 + mutation_controls)
@node24_or_non_js %{
  {"actions/checkout", "v5"} => :node24,
  {"erlef/setup-beam", "v1"} => :node24,
  {"actions/setup-node", "v5"} => :node24,
  {"actions/cache", "v5"} => :node24,
  {"actions/cache/restore", "v5"} => :node24,
  {"actions/cache/save", "v5"} => :node24,
  {"actions/upload-artifact", "v7"} => :node24,
  {"actions/github-script", "v8"} => :node24,
  {"googleapis/release-please-action", "v5"} => :node24,
  {"re-actors/alls-green", "b5b5b37504aa4183270bd3d855c52a67f212be35"} => :composite
}

# Scan non-comment lines only: ~r/^\s*(?:-\s+)?uses:\s*["']?([^@\s"']+)@([^\s"'#]+)/m
# Skip local "./..." and "docker://..." refs explicitly (none exist today).
# Mutation controls (each must yield a non-empty error list):
#   "uses: actions/cache@v4"                    (known node20)
#   "uses: googleapis/release-please-action@v4" (known node20)
#   "uses: some-org/new-action@v1"              (unknown => fail closed)
#   "  - uses: actions/upload-artifact@v4"      (list-item form)
# Non-vacuity: the live scan must find > 0 uses: refs, and every allowlist entry must be used somewhere
# (stale entries fail, mirroring the unused-allowlist rule HYG-02 adopts).
```
The test lives entirely offline. No network in `mix test`.

### Pattern 5: Parity/topology assertions for the pins

Add to `ci_workflow_parity_contract_test.exs`, or to a small pure helper used by both files:
1. Parse `.tool-versions`: `erlang`, `elixir` lines present. Assert the file is tracked with `git ls-files --error-unmatch .tool-versions`, which gives a real failure class (someone re-ignores or deletes it).
2. For every workflow, every `erlef/setup-beam` step block: it has `id: beam` and `version-type: strict`. Either (a) it has `version-file: .tool-versions` and no `otp-version:`/`elixir-version:` keys, or (b) it is the `verify-test` step whose inputs are the three `${{ matrix.* }}` expressions.
3. The `verify-test` matrix: the min row's runner is not `ubuntu-22.04` (assert `ubuntu-24.04`). The current row has `version-file: ".tool-versions"`. No workflow contains `ubuntu-22.04` in a `runs-on:` or `runner:` value.
4. Every `actions/cache*` step with `path: deps` or `path: .dialyzer`: its `key:` and `restore-keys:` contain both `steps.beam.outputs.otp-version` and `steps.beam.outputs.elixir-version`, and contain no `otp27`, `"27.0"` or `runner.os`. Playwright caches (`path: ~/.cache/ms-playwright`) are the only exempt path, named explicitly in the test. Browser binaries depend on the npm lockfile, not the BEAM.
5. Mutation controls: revert one key to `ubuntu-24.04-otp27.0-elixir1.17.3-mix-deps-` and set one setup-beam step back to `otp-version: "27.0"`. Each must produce errors.

### Anti-Patterns to Avoid
- **Adding a "verify resolved OTP equals .tool-versions" CI step:** with strict + version-file, setup-beam errors on any mismatch. The step would be tautological (MILESTONE-GUIDE §8). The log line `Installing Erlang/OTP OTP-27.3.4.15 - built on amd64/ubuntu-24.04` is the proof.
- **`hashFiles('.tool-versions')` in keys instead of resolved outputs:** it changes on a `nodejs` edit (false misses) and says nothing about what was actually installed. PLAT-01 says "resolved".
- **Denylist-only node20 grep:** vacuous for new actions (Pattern 4).
- **Bumping to cache@v6 / checkout@v7 "while we're here":** outside the requirement, with an ESM migration risk and no failure class.
- **Rewriting the Dialyzer evidence block in CONTRIBUTING:** it is a dated receipt of run 34642915672 at OTP 27.0.1. Keep it.
- **Moving the min lane to `ubuntu-latest`:** a mutable label reintroduces image drift, the very thing this phase removes.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Toolchain SSOT → CI | a script that parses `.tool-versions` and exports `OTP_VERSION` env | setup-beam `version-file` + `version-type: strict` | Built-in, errors on mismatch or double specification, and already handles the `-otp-N` suffix |
| Release-please rehearsal | a mock of the action or a fork repo | `npx -y release-please@<bundled version> release-pr --dry-run` against the real repo/config | Same library the action bundles (v5.0.0 → 17.6.0). Read-only, uses real GitHub data |
| NIF availability proof | reading lazy_html source to reason about loading | Docker probe on `hexpm/elixir:1.15.8-erlang-26.2.5.21-ubuntu-noble-*`, and the post-push CI log | Probes the real artifact selection and dlopen |
| Workflow syntax check | eyeballing YAML | `actionlint -shellcheck=` (1.7.12 installed; clean baseline today) | Catches expression and matrix-key typos before a push |

**Key insight:** every problem in this phase already has a first-party mechanism. The work is wiring plus fail-closed contract tests, not tooling.

## Common Pitfalls

### Pitfall 1: release.yml ref-switching jobs lose `.tool-versions`
**What goes wrong:** `publish-hex` / `smoke-published` (dispatch recovery of an old tag) or `sync-release-pr-pins` (a stale release-please branch) fail at setup-beam: "The specified version file, .tool-versions, does not exist".
**Why it happens:** version-file is read from the workspace, which holds the *target* ref, not the workflow's commit.
**How to avoid:** Pattern 3 (toolchain-first sparse checkout with `persist-credentials: false`).
**Warning signs:** a release-path job red at "Run erlef/setup-beam@v1" right after landing.

### Pitfall 2: The first run after landing is a cold cache everywhere, including the Dialyzer PLT
**What goes wrong:** every deps key and the PLT key change shape, so the first run misses. The PLT build takes ~153 s (CONTRIBUTING evidence).
**How to avoid:** expected, and within `timeout-minutes: 9` (derivation `ceil(252 * 2 / 60) = 9`). Do not "fix" it with broader `restore-keys`. Note it in the post-push evidence, since the first run's `THREADLINE_DIALYZER_PLT_CACHE=miss` is correct.

### Pitfall 3: "Its own commit" does not survive a squash landing
**What goes wrong:** v1.41 landed via squash PR #49 and v1.42 as "1 ID-free feat! squash commit" (STATE.md:813). The release-please bump's separate commit then exists only on the milestone branch.
**How to avoid:** keep it as its own `ci:` commit on the milestone branch (revertable, reviewable, and what the criterion inspects). Flag the landing shape to the maintainer (Open Question 2).

### Pitfall 4: Existing contract tests hard-code the old literals, so they go red mid-change
Exact lines that must change **in the same commit** as the workflow edit:
- `test/threadline/ci_workflow_parity_contract_test.exs:255-256`: `assert String.contains?(yaml, "actions/cache@v4"), "ci.yml must use actions/cache@v4 for the deps cache"`
- `test/threadline/ci_topology_contract_test.exs:396`: `{String.contains?(job, ~s(otp-version: "27.0")), "verify-dialyzer must pin OTP 27.0"},`
- `ci_topology_contract_test.exs:400`: `{String.contains?(job, "uses: actions/cache/restore@v4"),`
- `ci_topology_contract_test.exs:405`: `{String.contains?(job, "ubuntu-24.04-otp27.0-elixir1.17.3-dialyzer-plt-"),`
- `ci_topology_contract_test.exs:410`: `{String.contains?(job, "uses: actions/cache/save@v4"),`
- `ci_topology_contract_test.exs:142`: mutation control `"ubuntu-24.04-otp27.0-elixir1.17.3-dialyzer-plt-",` → `"ubuntu-24.04-dialyzer-plt-"`. Rewrite it so it strips the resolved-output segment instead.
[VERIFIED: Read/grep of both files this session. Baseline: 48 tests, 0 failures across the four CI/release contract files.]

### Pitfall 5: Silent source-compile fallback would mask a missing NIF
**What goes wrong:** if elixir_make cannot download the precompiled NIF, it prints "Attempting to compile lazy_html from source..." and GitHub runners have a C/C++ toolchain, so the lane can go green **without** the NIF having resolved. The Docker probe showed exactly this fallback path when CA certs were missing.
**How to avoid:** the PLAT-03 proof must grep the min-lane log for `Downloading precompiled NIF to /home/runner/.cache/elixir_make/lazy_html-nif-2.16-x86_64-linux-gnu-0.1.13.tar.gz` **and** the absence of `compile lazy_html from source`. A green check alone is not the proof.

### Pitfall 6: A misstatement in phase-215 notes: "NIF 2.16 is OTP 26"
OTP 26 runs NIF **2.17**. The probe printed `{~c"26", ~c"2.17"}`. It loads the 2.16 artifact because lazy_html declares `make_precompiler_nif_versions: [versions: ["2.16"]]` and elixir_make selects the highest listed version ≤ the VM's. Do not repeat the 215 phrasing in CONTRIBUTING or comments. [VERIFIED: Docker probe; lazy_html v0.1.13 mix.exs]

### Pitfall 7: CONTRIBUTING currently argues *against* committing `.tool-versions`
CONTRIBUTING.md:30-35 (verbatim): "this repository intentionally does **not** commit a `.tool-versions` file. It supports a range of Elixir versions rather than a single one, and committing a pin would turn "Elixir 1.15 and up works" into "install exactly the version this file names"". `bin/verify-bump-rehearsal:234-243` says "`.tool-versions` is deliberately untracked in this repository" and copies it into the clone. Both must change with the tracking commit. The new rationale: the file pins the *CI current lane*, while the support floor stays proven by the min lane. Contributors on another supported version override per shell, e.g. `ASDF_ERLANG_VERSION` / `ASDF_ELIXIR_VERSION` [ASSUMED: asdf 0.16 env override names; verify with `asdf help` or docs before writing them into CONTRIBUTING]. After tracking, `git clone` carries the file, so delete the copy block. No test references that block or the CONTRIBUTING paragraph (grep: none).

## Code Examples

### Evidence: today's drift (main CI run 36258719902, 2026-09-26)
```
Check formatting | ##[group]Installing Erlang/OTP OTP-27.0.1 - built on amd64/ubuntu-24.04
Run test suite (current) | ##[group]Installing Erlang/OTP OTP-27.3.4.18 - built on amd64/ubuntu-24.04
Run test suite (min)     | ##[group]Installing Erlang/OTP OTP-26.2.5.21 - built on amd64/ubuntu-22.04
Run test suite (min)     | ##[group]Installing Elixir v1.15.8-otp-26
Build ExDoc (dev) Complete job ##[warning]Node.js 20 is deprecated. The following actions target Node.js 20 but are being forced to run on Node.js 24: actions/cache@v4.
Run test suite (current) | Downloading precompiled NIF to /home/runner/.cache/elixir_make/lazy_html-nif-2.16-x86_64-linux-gnu-0.1.12.tar.gz
```
(origin/main still locks lazy_html 0.1.12. Phase 215's 0.1.13 bump is local and unpushed.) [VERIFIED: `gh run view 36258719902 --log`]

### In-repo values (verbatim)
- `.tool-versions:1-3` [VERIFIED: Read]: `nodejs 22.14.0` / `erlang 27.3.4.15` / `elixir 1.17.3-otp-27`
- `ci.yml:290-300` matrix rows [VERIFIED: Read]: `- lane: min` `elixir: "1.15"` `otp: "26"` `pg: "14"` `runner: "ubuntu-22.04"`; `- lane: current` `elixir: "1.17.3"` `otp: "27"` `pg: "16"` `runner: "ubuntu-24.04"`
- Non-matrix pin, e.g. `ci.yml:60-63` [VERIFIED: Read]: `- uses: erlef/setup-beam@v1` / `elixir-version: "1.17.3"` / `otp-version: "27.0"`
- Deps key, e.g. `ci.yml:98-99` [VERIFIED: Read]: `key: ubuntu-24.04-otp27.0-elixir1.17.3-mix-deps-${{ hashFiles('mix.lock') }}` / `restore-keys: ubuntu-24.04-otp27.0-elixir1.17.3-mix-deps-`
- PLT key `ci.yml:160-161` [VERIFIED: grep output of the Read file]: `key: ubuntu-24.04-otp27.0-elixir1.17.3-dialyzer-plt-${{ hashFiles('mix.lock') }}-${{ hashFiles('mix.exs') }}` / `restore-keys: ubuntu-24.04-otp27.0-elixir1.17.3-dialyzer-plt-`
- Flake key `flake-detection.yml:74-75` [VERIFIED: Read]: `key: ${{ runner.os }}-mix-deps-${{ hashFiles('mix.lock') }}` / `restore-keys: ${{ runner.os }}-mix-deps-`
- Release Please step `release.yml:92-99` [VERIFIED: Read]: `uses: googleapis/release-please-action@v4` with `token: ${{ secrets.RELEASE_PLEASE_TOKEN || secrets.GITHUB_TOKEN }}`, `config-file: release-please-config.json`, `manifest-file: .release-please-manifest.json`
- `.release-please-manifest.json` [VERIFIED: Read]: `{ ".": "0.11.0" }`

Full setup-beam step list (20): ci.yml lines 60, 114, 143, 260, 325 (matrix), 403, 447, 553, 601, 720, 769, 794, 897, 922; browser-full.yml:65; deps-health.yml:40; flake-detection.yml:65; release.yml:136, 414, 561. Jobs **without** a deps cache (keep it that way; the comments explain why): verify-hex-evaluator, verify-bump-rehearsal, verify-deps-audit, deps-health, and all release.yml jobs.

### Release-please v5 rehearsal (proven live this session, read-only)
```bash
# From repo root. Same library the action bundles: v4.4.1 → release-please 17.3.0, v5.0.0 → 17.6.0.
for v in 17.3.0 17.6.0; do
  npx -y release-please@$v release-pr \
    --repo-url=szTheory/threadline --token="$(gh auth token)" --target-branch=main \
    --config-file=release-please-config.json --manifest-file=.release-please-manifest.json \
    --dry-run 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -v '^npm warn' > /tmp/rp-$v.log
done
diff /tmp/rp-17.3.0.log /tmp/rp-17.6.0.log && echo IDENTICAL
```
Result on 2026-09-26 against origin/main `5e78b2f0`: identical output. The key lines: `Found release for path ., v0.11.0`, `No user facing commits found since 8312290d... - skipping`, `Would open 0 pull requests`. Limitation: the dry-run reads **origin's** `main`, so it rehearses config/manifest parsing and commit analysis on published history, not the unpushed milestone commits. The full rehearsal completes post-landing: the first `Release` run on the landing push executes `release-please-action@v5` for real. Phase 215's releasable `fix(deps):` commit means it should open or update a release PR, and `sync-release-pr-pins` then runs. Record that run ID, the absence of a Node 20 annotation, and the release PR diff (mix.exs `@version`, CHANGELOG-GENERATED.md, the two `x-release-please-version` extra-files lines).

**Runbook placement:** add a short "Upgrading the Release Please action" subsection under CONTRIBUTING "Hex publish (maintainers)" (around CONTRIBUTING.md:753-756 "Ongoing releases"). It should give the dry-run diff command above and the post-landing observation checklist. The rehearsal then goes "through the release runbook" and is repeatable for v6.

### lazy_html OTP 26 / ubuntu-24.04 probe (positive, recorded evidence)
```bash
docker run --rm --platform linux/amd64 -e ERL_FLAGS="+JMsingle true" \
  hexpm/elixir:1.15.8-erlang-26.2.5.21-ubuntu-noble-20260911 bash -c '
  apt-get update -qq && apt-get install -y -qq ca-certificates
  mix local.hex --force && mix local.rebar --force
  cd /tmp && mix new probe && cd probe
  sed -i "s/# {:dep_from_hexpm, \"~> 0.3.0\"}/{:lazy_html, \"0.1.13\"}/" mix.exs
  mix deps.get && mix compile
  mix run -e "IO.inspect({:erlang.system_info(:otp_release), :erlang.system_info(:nif_version)}); IO.inspect(LazyHTML.from_fragment(~s(<p class=x>hi</p>)) |> LazyHTML.query(~s(p.x)) |> LazyHTML.text(), label: :query)"'
```
Observed output (image: `Ubuntu 24.04.5 LTS`, `ldd (Ubuntu GLIBC 2.39-0ubuntu8.9) 2.39`, `x86_64`, `command -v make` → none):
```
Downloading precompiled NIF to /root/.cache/elixir_make/lazy_html-nif-2.16-x86_64-linux-gnu-0.1.13.tar.gz
Generated lazy_html app
{~c"26", ~c"2.17"}
query: "hi"
```
Notes: `+JMsingle true` works around BEAM-JIT segfaults under amd64 emulation on Apple Silicon, which is a probe artifact, not a CI concern. The artifact's own requirements: `GLIBC_2.14` max, `GLIBCXX_3.4.21`, `CXXABI_1.3.9`, built with `GCC: (Ubuntu 9.4.0-1ubuntu1~20.04.2) 9.4.0`. [VERIFIED: `strings` on the extracted `liblazy_html.so`] The 0.1.13 release publishes only `nif-2.16` artifacts (13 targets incl. `x86_64-linux-gnu`). [VERIFIED: `gh api repos/dashbitco/lazy_html/releases/tags/v0.1.13`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Loose `otp-version: "27.0"` literals | `version-file` + `version-type: strict` | setup-beam version-file support (v1.x) | Resolution is exact or the job errors |
| `node20` JS actions | `node24` majors (cache v5, upload-artifact v6+, release-please-action v5) | Node 24 default 2026-06-16, Node 20 removed 2026-09-23 | node20 actions are force-run on node24 with warnings today and may break outright |
| `ubuntu-22.04` | `ubuntu-24.04` | deprecation from 2026-09-17, unsupported 2027-04-17 | brownouts in 2027 would red the min lane |

**Deprecated/outdated in this repo:** `actions/cache@v4`, `actions/cache/{restore,save}@v4`, `actions/upload-artifact@v4`, `googleapis/release-please-action@v4`, `runs-on: ubuntu-22.04` (min lane), `runner.os` deps key in flake-detection.yml.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A matrix key absent from an `include` row renders as `''` in a step `with:` input | Pattern 2 | Low. Fallback: explicit current-row pins plus a parity assertion. actionlint and the first CI run expose it immediately. |
| A2 | `actions/checkout@v5` with `sparse-checkout: .tool-versions` + `sparse-checkout-cone-mode: false` materializes just that root file | Pattern 3 | Low. Alternative: full default checkout first (a few seconds more). The release path is dry-runnable by the maintainer via `workflow_dispatch dry_run: true`. |
| A3 | asdf 0.16 honours `ASDF_ERLANG_VERSION` / `ASDF_ELIXIR_VERSION` overrides | Pitfall 7 (CONTRIBUTING prose) | Doc accuracy only. Verify with `asdf` docs before writing. |
| A4 | Playwright browser caches may be exempt from "every cache key uses resolved OTP/Elixir" | Pattern 5 | Scope reading. If the verifier reads "every" literally, add the resolved segments to the Playwright keys too (cost: a browser re-download on each OTP bump). |
| A5 | GitHub keeps force-running node20 actions on node24 (rather than failing them) until this lands | Summary | If they start failing, this phase becomes urgent-blocking. It does not change the plan. |

## Open Questions (RESOLVED)

1. **Bump the pin to `27.3.4.18` while tracking it?** RESOLVED (OD-1): no bump; `.tool-versions` is tracked byte-identical and the min row pins today's floor build.
   - What we know: `.tool-versions` says `27.3.4.15` (installed locally via asdf). builds.hex.pm has `.16`–`.18` (latest 2026-09-22).
   - Recommendation: **no.** Track the file byte-identical (the criterion is "resolved equals committed pin"). A patch bump is a separate, deliberate one-line commit with its own local `asdf install`. It is a batched-freshness decision under the CONTRIBUTING dependency policy.
2. **Landing shape vs "own commit".** RESOLVED (OD-2): own `ci(release):` commit on the milestone branch; merge vs squash is the maintainer's call at the gate (plans 216-06 / 216-07). Recommendation: own `ci:` commit on the milestone branch. Tell the maintainer at the push gate that a squash landing folds it (Pitfall 3).
3. **flake-detection.yml deps key overlaps Phase 218** RESOLVED (OD-3): the key is rewritten in this phase (plan 216-03); Phase 218 only adds its all-workflows grep. (ECON criterion 1: "contract-compliant cache key checked by an all-workflows anti-regression grep"). Recommendation: this phase rewrites the key (PLAT-01 says *every* key, and the step is touched anyway for `cache@v5`). Phase 218 then only adds its all-workflows grep. Mention it in the plan so 218's planner does not redo it.
4. **Align Node too?** RESOLVED (OD-5): deferred; recorded in deferred-items.md by plan 216-06. `.tool-versions` has `nodejs 22.14.0` while the three setup-node steps use `node-version: "22"`. setup-node supports `node-version-file: .tool-versions` [CITED: actions/setup-node v5 README "Examples: package.json, .nvmrc, .node-version, .tool-versions"]. Recommendation: out of scope for PLAT-01 (OTP-specific). Record it as a deferred idea, not silent drift.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang/OTP (asdf) | local `mix test` | ✓ | 27.3.4.15 | — |
| Elixir | local `mix test` | ✓ | 1.17.3 (OTP 27) | — |
| PostgreSQL | contract tests boot `test_helper` | ✓ | localhost:5432 and :5433 accepting | — |
| actionlint | local workflow validation | ✓ | 1.7.12 (`actionlint -shellcheck=` clean baseline) | — |
| act | optional local job runs | ✓ | installed | not needed |
| gh CLI (authenticated as szTheory) | run-log evidence, release-please dry-run token | ✓ | — | — |
| npx / Node | release-please rehearsal | ✓ | npx 11.1.0, node v22.14.0 | — |
| Docker | lazy_html probe (already recorded) | ✓ | running | the post-push CI log is the required proof anyway |
| Pushed branch + CI run | criteria 1 and 3 run-ID proof, release-please live run | ✗ (maintainer grant) | — | **none**: maintainer-gated post-push step |

**Missing dependencies with no fallback:** a push grant (maintainer). The plan must isolate run-ID evidence into a final maintainer-gated/post-push verification step.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17.3), static workflow/doc contract tests |
| Config file | `test/test_helper.exs` (boots/migrates `threadline_test`) |
| Quick run command | `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs test/threadline/release_control_plane_contract_test.exs test/threadline/clean_checkout_contract_test.exs` (baseline ~11 s, 48 tests / 0 failures before the new file) |
| Full suite command | `mix ci.all` (Dialyzer red = PLT miss → `mix dialyzer --plt`) |
| Extra local gate | `actionlint -shellcheck=` (must stay clean) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLAT-01 | `.tool-versions` tracked and parseable (erlang + elixir) | contract | `git ls-files --error-unmatch .tool-versions && mix test test/threadline/ci_workflow_parity_contract_test.exs` | parity ✅ (new assertions ❌) |
| PLAT-01 | every non-matrix setup-beam step = `id: beam` + `version-file: .tool-versions` + strict, no YAML pins; mutation controls red | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs` | ✅ file / ❌ assertions |
| PLAT-01 | every deps/PLT cache key and restore-key uses `steps.beam.outputs.otp-version` + `elixir-version`; no `otp27.0`/`runner.os` | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs` | ✅ / ❌ assertions |
| PLAT-01 | Dialyzer topology contract updated (pins + PLT key + restore/save@v5) incl. mutation controls | contract | `mix test test/threadline/ci_topology_contract_test.exs` | ✅ (edit lines 142, 396-411) |
| PLAT-01 | CI log shows resolved OTP = pin | **post-push** | `gh run view <id> --log \| sed 's/\x1b\[[0-9;]*m//g' \| grep 'Installing Erlang/OTP' \| sort -u` → only `OTP-27.3.4.15` (non-min) and `OTP-26.2.5.21 ... amd64/ubuntu-24.04` (min) | n/a (maintainer push) |
| PLAT-02 | no node20 action in any workflow (allowlist, fail-closed, mutation controls, non-vacuous) | contract | `mix test test/threadline/ci_action_runtime_contract_test.exs` | ❌ Wave 0 (new file) |
| PLAT-02 | release-please bump is its own commit | git | `git log --format='%h %s' --name-only -1 <sha>` shows only `.github/workflows/release.yml` (+ test if the allowlist moves with it) with a `ci:` subject | n/a |
| PLAT-02 | rehearsal recorded | local probe | the dry-run diff command above → `IDENTICAL`, output pasted into SUMMARY | n/a |
| PLAT-02 | no Node 20 annotation on a real run | **post-push** | `gh run view <id> --log \| grep -c 'Node.js 20 is deprecated'` → `0` for CI, Browser-full and Release runs | n/a |
| PLAT-03 | min lane runner is `ubuntu-24.04`, no `ubuntu-22.04` anywhere | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs` and `! grep -rn 'ubuntu-22.04' .github/workflows/*.yml` (comments included, so update them) | ❌ assertion |
| PLAT-03 | lazy_html OTP 26 NIF resolves on 24.04 | local probe (done) + **post-push** | min-lane log: `grep 'Downloading precompiled NIF.*lazy_html-nif-2.16-x86_64-linux-gnu-0.1.13'` present AND `grep -c 'compile lazy_html from source'` = 0 AND `Image: ubuntu-24.04` in "Set up job" | n/a |

### Sampling Rate
- **Per task commit:** quick run command + `actionlint -shellcheck=`
- **Per wave merge:** `mix ci.all`
- **Phase gate:** full suite green locally. Then the maintainer-gated push produces the run ID(s) for the three post-push rows before `/gsd-verify-work` marks criteria 1–3.

### Wave 0 Gaps
- [ ] `test/threadline/ci_action_runtime_contract_test.exs`: covers PLAT-02 (write it red against the current tree first; it must list exactly the 3 node20 refs + 2 sub-actions)
- [ ] New assertion blocks in `ci_workflow_parity_contract_test.exs` for PLAT-01/PLAT-03
- Framework install: none

## Suggested Plan Decomposition (sequential, no worktrees; every plan edits ci.yml)

Mirrors the phase-215 shape: tracer-first task, one concern per commit, test and workflow change in the same commit, no test born red.

1. **Plan 01, PLAT-01 toolchain pin (wave 1)**
   - T1 tracer: `git add .tool-versions`. Rewrite CONTRIBUTING.md:22-42 toolchain policy + line 24 ("CI uses OTP 27.0"). Remove the copy block and comment in `bin/verify-bump-rehearsal:234-243`. Add the tracked-file assertion. Commit (`build:` or `chore:`, non-releasable).
   - T2: ci.yml's 13 non-matrix jobs → Pattern 1 (the deps keys and the PLT key). Update the topology Dialyzer contract (lines 142, 396, 405 and its mutation control) and CONTRIBUTING:563/579-583 present-tense lane sentence (keep the dated evidence block). Add the parity pin/key assertions with mutation controls. One commit.
   - T3: browser-full, flake-detection (drop `runner.os`), deps-health, and release.yml's 3 jobs via Pattern 3. Extend the assertions to all workflows. One commit.
2. **Plan 02, PLAT-03 min lane (wave 2, after 01)**: matrix per Pattern 2, runner `ubuntu-24.04`, rewrite the verify-test comments that name ubuntu-22.04 (ci.yml:279-285, 330-337; keep the D-19 bug history accurate but present-tense-correct), add a parity assertion. Record the Docker probe as evidence in the SUMMARY. One commit.
3. **Plan 03, PLAT-02 Node 24 (wave 3)**
   - T1: new runtime contract test (red on the current tree). Bump `cache@v4` → `@v5` (16 + restore/save) and `upload-artifact@v4` → `@v7` (3). Update the literals at parity:255-256 and topology:400/410. Test goes green. One `ci:` commit. The release-please ref stays out of the allowlist until T2, so T1 temporarily lists `googleapis/release-please-action@v4` under a dedicated "pending" entry. Alternatively order T2 first so no interim state exists. **Prefer T2 first** (release-please bump commit, then the test-and-bump commit), so the new test is born green without a pending entry.
   - T2: `release-please-action@v4` → `@v5` alone in its own `ci:` commit. Add the CONTRIBUTING runbook subsection (separate `docs:` commit, so the bump commit stays single-file). Run the dry-run rehearsal and paste the output into the SUMMARY.
4. **Plan 04, maintainer gate and post-push evidence (wave 4, non-autonomous)**: halt at push (no `git push`, `gh pr merge` or Hex action without the maintainer's own grant; relayed approvals do not count). After the push: collect the CI run ID and verify the three post-push rows. After landing: the Release run ID for release-please v5, plus the release PR shape.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes (CI tokens) | `persist-credentials: false` on the new toolchain checkout in release jobs. Release Please keeps `secrets.RELEASE_PLEASE_TOKEN \|\| secrets.GITHUB_TOKEN` unchanged. |
| V5 Input Validation | minimal | setup-beam strict mode rejects unlisted versions. The contract tests reject unknown actions. |
| V6 Cryptography | no | — |
| V10/V14 Malicious code / config (supply chain) | yes | Official-org actions only. The allowlist test forces a reviewed edit for any new action/ref. alls-green stays SHA-pinned. |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| New unreviewed third-party action slipped into a workflow | Tampering | Fail-closed allowlist in `ci_action_runtime_contract_test.exs` |
| Credential persisted into a job that compiles dependencies | Information disclosure | `persist-credentials: false` on every checkout in `sync-release-pr-pins` (existing comment release.yml:125-130) |
| Toolchain drift masking a vulnerable OTP patch | Tampering / repudiation | Exact strict pins. Patch bumps become explicit, reviewable commits. |

Out of scope: SHA-pinning every action (only alls-green is SHA-pinned today). Record it as a possible future hardening item, not this phase.

## Sources

### Primary (HIGH confidence)
- erlef/setup-beam `action.yml`, `README.md` and `src/setup-beam.js` at ref `v1` (`using: node24`; version-file/strict/outputs/getInput/parseToolVersionsFile/getElixirVersion)
- `action.yml` at exact refs for actions/checkout v5/v6, actions/cache v4/v5 (+ v5/v4 restore/save), actions/upload-artifact v4/v6/v7, actions/setup-node v5/v6, actions/github-script v8/v9, googleapis/release-please-action v4/v4.4.1/v5/v5.0.0, re-actors/alls-green @b5b5b375… and release/v1
- GitHub release notes via `gh api`: release-please-action v5.0.0, actions/cache v5.0.0/v6.0.0, upload-artifact v5.0.0/v6.0.0/v7.0.0
- builds.hex.pm listings: otp/amd64/ubuntu-24.04, ubuntu-22.04, ubuntu-26.04; elixir/builds.txt
- dashbitco/lazy_html v0.1.13: release assets, `mix.exs`, extracted `liblazy_html.so`
- CI run https://github.com/szTheory/threadline/actions/runs/36258719902 (log)
- Local probes: Docker `hexpm/elixir:1.15.8-erlang-26.2.5.21-ubuntu-noble-20260911`; `npx release-please@17.3.0/17.6.0 --dry-run`; `actionlint 1.7.12`; baseline `mix test` of 4 contract files
- In-repo files read this session: `.tool-versions`, ci.yml, release.yml, flake-detection.yml, browser-full.yml, deps-health.yml, release-please-config.json, .release-please-manifest.json, ci_topology_contract_test.exs, ci_workflow_parity_contract_test.exs, clean_checkout_contract_test.exs, CONTRIBUTING.md, bin/verify-bump-rehearsal

### Secondary (MEDIUM confidence)
- https://github.blog/changelog/2025-09-19-deprecation-of-node-20-on-github-actions-runners/ (Node 24 default 2026-06-16, Node 20 removal 2026-09-23)
- https://github.com/actions/runner-images/issues/14254 (ubuntu-22.04 deprecation from 2026-09-17, unsupported 2027-04-17)

### Tertiary (LOW confidence)
- None relied upon.

Note: the `gsd-tools research-plan` seam was not used. Every lookup was a direct fetch of a primary artifact (action manifests, registry listings, release APIs, CI logs), which ranks above any cached digest.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH. Every ref's runtime was fetched at the exact tag.
- Architecture: HIGH for Patterns 1, 4 and 5 (read from source), MEDIUM for Patterns 2 and 3 (one ASSUMED Actions behavior each, both with fallbacks).
- Pitfalls: HIGH. Each was observed (CI log, Docker probe, test file lines, setup-beam source).

**Research date:** 2026-09-26
**Valid until:** ~2026-10-26 (action majors and builds.hex.pm listings move monthly; re-check if a new setup-beam or cache major lands)
