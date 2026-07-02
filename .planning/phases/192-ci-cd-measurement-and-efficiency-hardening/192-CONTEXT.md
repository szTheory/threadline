# Phase 192: CI/CD Measurement and Efficiency Hardening - Context

**Gathered:** 2026-07-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Baseline the current CI/CD pipeline from evidence, then make **low-risk, reversible** improvements to feedback speed, determinism, and maintainer DX **without weakening any gate**. Covers requirements CI-01 (baseline), CI-02 (cache/setup efficiency), CI-03 (alignment/hygiene), CI-04 (compatibility policy + minimal lanes).

**Sequencing within the phase (locked):** measure the baseline **first** (read-only, off run history — no observer effect), **then** land the efficiency/alignment/compat edits. Phase 193 (CLOSE-01) captures the after-data and diffs it against this phase's baseline artifact.

**Not in scope:** clever CI matrix/sharding beyond the one justified min lane; caching `_build`; adding Dialyzer to CI; bumping the current Elixir anchor off 1.17.3; any nightly/cron PG-spread (deferred until PR timing is measured); new product/UI surface.
</domain>

<decisions>
## Implementation Decisions

These four areas were researched in depth (4 advisor researchers) and then **adversarially verified** (technical red-team + project-DNA/vision check). Amendments from verification are folded in and marked ⚠️.

### CI-01 — Baseline evidence & artifact
- **D-01:** Produce a durable, **read-only** artifact `.planning/phases/192-.../192-BASELINE.md` mirroring the Phase 189 quality-audit shape (YAML frontmatter: `phase/artifact/scope/requirements/status/source_precedence` + one ranked table). Lands in-repo so Phase 193 does a pure in-repo before/after diff.
- **D-02:** Depth = **static analysis of `ci.yml`** (job fan-out, `needs:` serialization, cache absence, `mix deps.get`×N) **+ p50/p95 aggregated from the last ~15 green `ci.yml` runs**, filtered to one event type, via `gh api repos/szTheory/threadline/actions/runs/{id}/jobs` (job + step `started_at`/`completed_at`). ~96 runs of history are available (contra any "no historical DB" assumption).
- **D-03:** Table columns: `job | p50 | p95 | on critical path? | repeated setup cost (deps.get + setup-beam) | cache state | flaky/rerun (run_attempt>1 count) | evidence source`.
- **D-04:** Explicit honest **"unavailable" rows**: billed-minute cost = unavailable (public-repo billing API returns 0); cache-hit rate = N/A (no `actions/cache` configured today). ⚠️ Each unavailable/deferred row carries the DNA Nyquist-debt metadata shape — **owner, date, pointer to superseding evidence, trigger to reopen** (`threadline-elixir-oss-dna.md:16`), not a bare "unavailable".
- **D-05:** No workflow edits during the baselining step (avoid observer effect). Headline finding already visible and pre-justifies CI-02: all 10 jobs run in parallel (zero `needs:`), zero caching, browser lane ≈ 98% of the ~5m52s critical path, `mix deps.get` runs cold ×8–10.

### CI-02 — Caching (add exactly three; decline two)
- **D-06:** Add `actions/cache@v4` for **`deps/`** on every job (incl. `flake-detection.yml`), keyed `${{ runner.os }}-mix-deps-${{ hashFiles('mix.lock') }}` with a `restore-keys` prefix. Verified safe: `deps/` holds **source only** (compiled artifacts live in `_build`, which we do NOT cache); both matrix lanes fetch byte-identical source from the same pinned `mix.lock`, so **no cross-lane poisoning** and `restore-keys` is safe (`deps.get` reconciles after partial restore). `erlef/setup-beam@v1` has **no** built-in dep cache, so explicit `actions/cache` is required.
- **D-07:** Add **Playwright browser cache** `~/.cache/ms-playwright` on the `verify-example-browser` lane, keyed on `hashFiles('examples/threadline_phoenix/e2e/package-lock.json')` (that lock pins `@playwright/test`, which determines browser version).
- **D-08:** Add **npm download cache** via the existing `setup-node@v5` step. ⚠️ **MUST set** `cache-dependency-path: examples/threadline_phoenix/e2e/package-lock.json` — there is **no root `package-lock.json`**, so `cache: npm` without this path **fails the job** with "Dependencies lock file is not found". `run-e2e.sh` runs `npm ci` from `e2e/`, so setup-node and the install must agree on that path. (`npm ci` wipes `node_modules`, so cache the npm download dir, not `node_modules`.)
- **D-09:** ⚠️ **Cache-key scoping (DNA `threadline-elixir-oss-dna.md:13` — "separate cache keys from the root app; reusing root deps/_build for nested trees is a footgun"):** the Playwright/npm caches are keyed to the **example-host subtree** (`e2e/package-lock.json`), never folded into the root `mix.lock` key. Root `deps/` key stays on root `mix.lock` only.
- **D-10:** **Decline `_build` caching** — restoring stale/incompatible `_build` can mask `--warnings-as-errors` and cause cross-`MIX_ENV` bleed (the exact CI-02 footgun). Not caching `_build` is the strongest guarantee the gate keeps its teeth.
- **D-11:** **Decline Dialyzer PLT caching** — ⚠️ corrected rationale: it is **moot, a no-op**, because there is **no `mix dialyzer` CI job** (`dialyzer:` is configured in `mix.exs` but never invoked in CI). Documented for completeness; not a warnings-integrity argument.
- **D-12:** Guarantee: `mix deps.get` / `npm ci` / `playwright install` all still **run** — caches change **speed only, never what runs** — so local `mix ci.all` reproduces CI byte-identically. Each cache is an independently removable block (reversible).

### CI-04 — Compatibility policy & minimal lanes (highest-risk area)
- **D-13:** **Declared support contract** (make explicit in README + a `mix.exs` comment): Elixir **1.15 floor / 1.17.3 current**; OTP **26 min / 27 current**; PostgreSQL **14 min / 16 current**. (13 reached EOL Nov 2025; 14 is the oldest non-EOL major.)
- **D-14:** **Honor the floor — add a min lane, do NOT raise `~> 1.15`.** Raising silently breaks existing 1.15 adopters (least-surprise / upgrade-trust — reinforced by product strategy: "Upgrades and schema drift hurt trust"). Adding a lane converts an untested claim into a proven one.
- **D-15:** **Exactly one matrix addition** — `verify-test` gets 2 `strategy.matrix.include` lanes: min `elixir 1.15 / otp 26 / postgres:14` + current `elixir 1.17.3 / otp 27 / postgres:16`. The min-Elixir lane doubles as the min-PG lane → two PG majors across the trigger-heavy suite at **zero extra lanes**. Every other job stays single current lane.
- **D-16:** ⚠️ **Shared-`mix.lock` false-promise guard.** The min lane resolves the *committed* lock, so it tests "1.15 with current deps," not "1.15-era deps," with **zero margin** — the next `mix deps.update` pulling a dep that floors at 1.16 (e.g. Oban's "3 most recent Elixir versions" policy) turns the min lane red for a reason unrelated to Threadline. **Chosen mitigation (option c):** scope the contract to "**1.15 compiles + tests green with current deps**" AND add a guard test asserting **no locked dep floors above 1.15**, so the promise fails **loudly at the lock**, not mid-CI. (Rejected: fresh-resolve-per-lane nondeterminism; a maintained `mix.lock.min`.)
- **D-17:** ⚠️ **Runner pin for the min lane** — pin the min lane to `ubuntu-22.04` (guaranteed OTP-26 precompiled builds) while the current lane stays `ubuntu-24.04`. **Verify with a throwaway matrix run** that `elixir 1.15 / otp 26` actually resolves on the chosen runner before committing the contract.
- **D-18:** ⚠️ **Scope the min lane's body** to `mix compile --warnings-as-errors` + `mix test` only — **not** the full current-lane payload (nested example app, `hex_evaluator`, `verify.threadline`, doc contracts) — to shrink the false-red surface from 1.15↔1.17 deprecation differences.
- **D-19:** ⚠️ **CRITICAL COHERENCE — branch-protection check rename.** Adding `strategy.matrix` to `verify-test` makes GitHub post checks named **`Run test suite (min)` / `Run test suite (current)`** (matrix context is always appended; a stable `name:` cannot suppress it). The currently-required check **"Run test suite (verify-test)"** (`CONTRIBUTING.md:179`) will then **never post → PRs block forever**. Branch protection MUST be reconfigured to the two new check names **as part of this change**, and the contract test must assert the *new* names. `gate-ci-green` reads workflow-run conclusion (not per-job checks), so it is unaffected.
- **D-20:** The existing `--no-optional-deps --warnings-as-errors` compile lane (`verify-compile-no-optional` job) **stays** — it is the check proving Threadline compiles for adopters who haven't pulled Phoenix/LiveView (Phoenix stays optional). Confirm it is preserved through the matrix work; do not fold it into the version matrix.
- **D-21:** **Defer** any nightly/cron PG-spread (14/15/16/17) or extra Elixir versions until PR lane timing is measured (measurement-first). Every added lane must carry a one-sentence justification.

### CI-03 — Alignment & hygiene (five fixes; all repair *live* problems)
- **D-22:** **Pin** `edoburu/pgbouncer:latest` (`ci.yml:225`) → `edoburu/pgbouncer:v1.25.2-p0` (real pullable tag; behavior-neutral vs today's `latest` which is already 1.25.2; guards future drift). No change to `POOL_MODE=transaction` / `scram-sha-256`. Tag-pin, not digest — symmetric with the untouched `postgres:16` policy. `:latest` at line 225 is the only one in `ci.yml`, so a "no `:latest` in workflows" assertion is clean after.
- **D-23:** **Add CI concurrency** to `ci.yml`: `group: ${{ github.workflow }}-${{ github.ref }}`, `cancel-in-progress: ${{ github.event_name == 'pull_request' }}`. Verified clean: cancels superseded **PR** runs only; the release-PR bootstrap dispatch (`workflow_dispatch`, `ref = release-please--branches--main`) and push-to-main runs each land in their own group and are **never** cancelled — so `gate-ci-green` (which keys on `head_sha`) is unaffected.
- **D-24:** ⚠️ **Release concurrency — REVISED from the first-pass recommendation.** Collapsing `release.yml` to a workflow-level `group: release-${{ github.ref }}` is a **regression**: it serializes ALL release-workflow runs on `main`, so a fast `release-please` bookkeeping run (the only job that runs on an ordinary merge) queues behind a prior run's up-to-30-min `gate-ci-green`+publish. **Chosen fix:** scope `concurrency` to the **publish job level** (`group: release-publish-${{ github.ref }}`, `cancel-in-progress: false`) so frequent bookkeeping stays independent while publishes never overlap. Publish-race safety is already covered by `publish-hex` idempotency skip + `gate-ci-green`. (The current `release-${{ event_name }}-${{ run_id }}` group is an effective no-op — `run_id` makes every run unique.)
- **D-25:** **Repair CONTRIBUTING drift** — its "Stable job keys" table lists **8** jobs; `ci.yml` defines **10**. Add `verify-hex-evaluator` and `verify-example-browser` so the documented required-checks list matches all 10 `jobs:` keys and the `ci.yml` header contract comment (lines 1–2, already correct).
- **D-26:** **Extend `test/threadline/phase06_nyquist_ci_contract_test.exs`** (async, static-parse; verified additive — won't break existing presence/ordering assertions) with: job-key parity across `ci.yml` ↔ header comment ↔ CONTRIBUTING table; **no `:latest`** in any workflow; `release.yml` publish concurrency group present and free of `run_id`; `ci.yml` PR-scoped concurrency block present; **the new matrix check names** (`Run test suite (min)`/`(current)`) match the documented required checks (ties into D-19).
- **D-27:** ⚠️ **Land as one logical change set** (DNA `:25`): the CONTRIBUTING fix, the workflow edits, the branch-protection reconfig, and the new/extended contract tests must ship together, or a test is "born red" (consistent with the repo's known release-please born-red lesson).

### Claude's Discretion
- Exact `jq`/script for run-history aggregation (throwaway, lives in `.planning`, not CI).
- Exact wording/table layout of `192-BASELINE.md` within the Phase-189 frontmatter convention.
- Precise `restore-keys` prefixes and `actions/cache` step placement per job.
- Whether the min-lane guard test (D-16) is a new file or an extension of the contract test.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Live pipeline (the thing being baselined + edited)
- `.github/workflows/ci.yml` — 10 parallel jobs; job-id contract comment (lines 1–2); `edoburu/pgbouncer:latest` at line 225; `verify-test` is the matrix target; no concurrency block today.
- `.github/workflows/release.yml` — release-please + `gate-ci-green` (polls up to 60×30s) + `publish-hex` (idempotent skip guard); concurrency group at line 40 embeds `run_id` (no-op); dispatches `ci.yml` on the release PR (~line 112).
- `.github/workflows/flake-detection.yml` — same cold-`deps.get` pattern; apply the `deps/` cache here too.
- `.github/workflows/hex-publish.yml` — untouched; no caches; verify no interference.
- `examples/threadline_phoenix/e2e/run-e2e.sh` — `npm ci` + `npx playwright install chromium` (~lines 105–111); cwd is `e2e/`.

### Local entrypoints & contract tests (must stay aligned + testable)
- `mix.exs` — `ci.all` alias + all `verify.*` aliases; `elixir: "~> 1.15"` (line 28); `dialyzer:` config (~line 38, never run in CI). Local `mix ci.all` is the canonical reproducibility anchor (CLAUDE.md).
- `test/threadline/phase06_nyquist_ci_contract_test.exs` — existing job-key/`ci.all`-ordering assertions; the extension point for D-26.
- `CONTRIBUTING.md` — "Stable job keys" table (drifted 8→10, ~lines 118–129) + required-status-checks doc (~line 179).

### Prior artifact template
- `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md` — frontmatter + ranked-table shape that `192-BASELINE.md` mirrors.

### Project DNA / strategy (grounds the "why")
- `prompts/threadline-elixir-oss-dna.md` — §named `verify.*`/`ci.*` entrypoints; §"Stable CI job identifiers" (`:14`); §"separate cache keys from nested trees" (`:13`); §"expensive jobs still run on `main`" path-filter invariant (`:15`); §deferred-validation ledger (`:16`); §doc-contract tests (`:24–25`); §release parity gates (`:31–33`).
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — §"Upgrades and schema drift hurt trust" (`:110`, `:156`) → grounds honor-the-floor.
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — min+current matrix shape (`:156–160`), smaller required matrix for branch protection (`:167`), PR concurrency cancel (`:193`), SHA/tag pinning (`:197`), optional-deps compile lane (`:55`, `:107`).
- `.planning/ROADMAP.md` §Phase 192 · `.planning/REQUIREMENTS.md` (CI-01…CI-04).

### Ecosystem exemplars (matrix/concurrency/caching patterns cited)
- Oban, ecto_sql, Broadway, Carbonite CI workflows (min+current `include:`; DB-breadth confined to the DB job).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Phase-189 audit artifact** — proven frontmatter+table template to clone for `192-BASELINE.md`.
- **`phase06_nyquist_ci_contract_test.exs`** — established static-parse contract-test pattern; extend rather than invent (async, no network).
- **`ci.yml` header job-id contract comment** — already correct (all 10 jobs); the authoritative source the CONTRIBUTING table must be reconciled to.
- **Existing `verify-compile-no-optional` job** — the optional-deps guard; preserve as-is.

### Established Patterns
- **Named entrypoints:** all steps run through `mix verify.*` / `mix ci.*`; caching must not change *what* those run, only speed.
- **Doc-contract tests** lock docs↔workflow↔`mix.exs` alignment; new alignment fixes must land with matching assertions.
- **Path-filters + `main`:** expensive jobs still run on `main` even when PRs are path-filtered — any new lane must preserve this so it actually exercises on the default branch.
- **Single pinned version lane** today (1.17.3/OTP27/PG16) — the matrix is the *only* deviation introduced.

### Integration Points
- `verify-test` job ← the min/current matrix (renames branch-protection checks — D-19).
- Every job ← `deps/` cache; `verify-example-browser` ← Playwright + npm caches.
- `release.yml` publish job ← publish-level concurrency (D-24); must not starve `release-please` bookkeeping.
- Branch-protection required-checks config ← must be reconfigured with D-19/D-25/D-26.
</code_context>

<specifics>
## Specific Ideas

- Baseline must be **honest-first**: record what's genuinely unavailable (billed minutes, cache-hit rate) with reopen-triggers rather than fabricating numbers — mirrors Phase 189's screenshot/host-staging honesty boundaries.
- "Measure before optimize" is a hard ordering, not a preference: the baseline captures the **cache-absent, deps×N, browser-lane-dominated** state so Phase 193 has a real before/after anchor.
- Every change must be **independently reversible** and **gate-preserving** — no hidden skips, no warning masking, no harder local reproduction.
</specifics>

<deferred>
## Deferred Ideas

- **Nightly/cron PostgreSQL spread (14/15/16/17)** and additional Elixir versions — revisit only if measurement shows PR headroom or a trigger regression appears (own future consideration; not this phase).
- **Bump current Elixir anchor to 1.18/1.19** — keep 1.17.3 this phase; note in CHANGELOG that the floor advances to 1.16 (the security-patched window) at the next release that can carry a floor bump. Not done here (avoids adopter surprise + scope creep).
- **Digest-pinning service images / GitHub Actions to full SHA** — DNA endorses it (`:197`); deferred as broader supply-chain hardening, asymmetric with the current tag-pin policy.
- **`_build` caching via tightly-keyed per-env entries** — only revisit if measurement proves a job is compile-bound; even then, per-env keyed with no restore-keys.

None of the above are blockers; all preserved for a future CI-depth milestone (a candidate v1.40 direction per Phase 193's decision).
</deferred>

---

*Phase: 192-CI/CD Measurement and Efficiency Hardening*
*Context gathered: 2026-07-02*
