# Project Research Summary

**Project:** Threadline (Hex `threadline` 0.11.0). Milestone v1.43 Supply Chain, CI Economy and Repo Hygiene
**Domain:** CI economy, supply-chain gating and repo hygiene for a public, single-maintainer Elixir Hex library
**Researched:** 2026-09-26
**Confidence:** HIGH for measured facts (run IDs, file:line, command output). MEDIUM for projected savings and the untested dynamic `allowed-skips` mechanism.

## Executive Summary

v1.43 does not change the product. It is about the machinery around the product. The four research files agree on the shape of the work. A small, well-tooled Elixir library should gate advisories with the built-in `mix hex.audit` rather than a third-party auditor or Dependabot churn. It should prove each failure class once, in the cheapest lane that can prove it. It should keep one required aggregate check (`CI required`), which may only skip a job when a required, unskippable classifier ordered the skip. It should keep the public tree free of machine-local paths with a tracked-files `git grep` guard. The measured baseline shows where the money goes. Flake Detection alone costs about 3,000–4,100 runner-min/month and has produced zero `flaky` findings in its lifetime. Release-PR double dispatch adds about 600/month. Browser-full re-runs about 14 of its 16 Playwright minutes per push on the same SHA that CI already proved. Fixing these cheap, high-evidence items should take the forward rate from about 5,500–6,500 runner-min/month to about 1,900–2,300 **[inference]**.

Re-measuring on 2026-09-26 turned up baseline facts that shift scope. Two advisories are open in the root lock, not one: mint 1.10.0 is MEDIUM and runtime-transitive via the optional `req`, and lazy_html 0.1.12 is LOW. `bench/mix.lock` carries **8 advisories, 3 of them HIGH**, and nothing audits it. CI does not run the OTP it claims to run: the `"27.0"` pin loosely resolves to **OTP 27.0.1** (July 2024), the current test lane gets 27.3.4.18, and the local `.tool-versions` is **untracked**. `actions/cache@v4`, `upload-artifact@v4` and `release-please-action@v4` are Node 20 actions, now past GitHub's 2026-09-23 removal date. They run only because the runner forces them onto Node 24. `ubuntu-22.04` (the min lane) entered deprecation on 2026-09-17 and is unsupported from 2027-04-17. The release-PR double dispatch is confirmed on 9 SHA pairs, and 7 of those pairs were double-red.

The main risk is that a gate is born vacuous, born red, or laundered green. Each new gate needs a fix that lands before it, so it starts green, and a negative test proving it can fail: the audit gate on an old Hex, and the path guard matching its own fixtures. Removing a duplicate proof needs a written "failure class X is still caught by job Y on trigger Z" line. Any `allowed-skips` entry must come from the classifier's dynamic output and nothing else. The secondary risk is scope drift into anti-features: gating runtime xref cycles, Dependabot version PRs, Playwright sharding, SQL Sandbox, or history rewriting. The research rejects all of these.

## Key Findings

### Recommended Stack

Everything is built in or already on the runner. No new Hex dependencies are needed. Details are in [STACK.md](STACK.md).

**Core technologies:**
- **`mix hex.audit` (Hex >= 2.5.1, asserted in-job):** the advisory gate. It uses the EEF CNA/OSV feed and exits 1 on advisories or retirements, and `hex: [ignore_advisories: [...]]` is the reviewed escape hatch. `mix_audit` is rejected: its database misses both current advisories and its last release was 2025-06.
- **`mix deps.unlock --check-unused` + `mix deps.get --check-locked`:** cheap, deterministic lock-integrity checks, both available on the 1.15 floor.
- **`erlef/setup-beam` v1.24.1 with `version-file: .tool-versions`, `version-type: strict`** for non-matrix jobs. This needs `.tool-versions` committed. Cache keys use the *resolved* `otp-version` output, not the requested literal.
- **Node 24 action majors:** `actions/cache@v5` (split `restore`/`save` for the deps-only `_build`), `actions/upload-artifact@v7`, `release-please-action@v5`. Bump release-please in its own commit and rehearse it through the release runbook.
- **`git grep -I` guard script (`bin/`):** the local-path/PII guard. It scans tracked text files only and runs in about 0.15 s. Gitleaks and trufflehog are rejected because they duplicate the secret scanning and push protection already enabled, and history mode would flag the deliberately unrewritten past.
- **ExUnit `@tag :tmp_dir`:** available since 1.11, so it is safe on the min lane. It creates `<project>/tmp/<module>/<test>-<hash>`, which is inside the worktree and gitignored. It is wiped at test *start* and left behind afterwards.
- **Newest lane pins (spike first):** Elixir 1.20.4 / OTP 29.1 / `postgres:18` / ubuntu-24.04. Use PG 18, not `19beta4`. FEATURES.md said "OTP 28". STACK.md's verified pins supersede it.

**Critical version facts:** `--repeat-until-failure` needs Elixir >= 1.17 (current/latest lanes only). Elixir 1.20 needs OTP >= 27. Elixir 1.15 is out of upstream support and PG 14 reaches EOL on 2026-11-12. Both are **v1.45 floor decisions**, flagged here and not acted on.

### Expected Features

Details are in [FEATURES.md](FEATURES.md), which also holds the measured per-job baseline table.

**Must have (table stakes):**
- **T1** Remediate advisories in every tracked lockfile, root and bench. The fix is lock-only (`mix deps.update lazy_html mint`, and refresh `bench/`), with no `mix.exs` change.
- **T2** A `mix hex.audit` gate over root, `examples/threadline_phoenix` and `bench`, plus a weekly scheduled audit on `main` that feeds one tracking issue.
- **T3** Right-size Flake Detection (see "Researcher disagreements, resolved"). This is the largest saving, at about 2,900–4,000 runner-min/month.
- **T4** Kill the release-PR double dispatch (about 600 runner-min/month, plus duplicate red checks).
- **T5** Browser-full on push runs only the projects CI does not run. Nightly skips an already-green SHA.
- **T6** Remove the uncached `:live_dialyzer` test (540 s timeout) from default `mix test`. It runs once, inside the PLT-cached `verify-dialyzer` job.
- **T7** Drop the dominated mechanical-check copies: the `verify-mechanical` job and `verify-capture`'s trailing step.
- **T8** Forward scrub of about 295–298 tracked `.planning/` files, then a local-path guard in CI.
- **T9** Honest job names. For example, "Hex evaluator smoke (threadline from hex.pm)" is false on PRs.
- **T10** Tracking issues close themselves on green. #36 and #28 are open while their lanes are green.
- **New from the baseline:** move to Node 24 actions, commit `.tool-versions`, run the exact OTP, and move the min lane to ubuntu-24.04. These are latent breaks, not optional polish.

**Should have (differentiators):**
- **X1** A deps-only `_build` cache plus an example-app cache. It saves about 1–1.5 min off *both* critical-path jobs, which are tied at about 10.5 min.
- **X2** A newest-toolchain lane, gated on a spike.
- **X6** `mix test --slowest 25` as before/after proof.
- **X8** `@tag :tmp_dir` migration, scoped as hygiene rather than a flake fix. There is no recorded temp-dir flake.
- **X7** SEED-006 change-aware lanes, last and conditional.

**Defer (v1.44+):**
- **X3** SHA-pinning all 51 mutable `uses:`.
- **X5** Splitting `verify.example` out of test-current. It only pays once the browser job also shrinks.
- **X10** Idle polling in the release `gate-ci-green` step (about 11 min per release, but touches the release path).
- A composite setup action.
- Removing `verify-docs` in favour of the rehearsal's `--warnings-as-errors` docs build. It is optional; decide it in the economy phase using the "still caught by" rule.
- The v1.42 debt that is already deferred to v1.44.

**Anti-features (do not build):**
- A runtime xref-cycle gate.
- Dependabot `mix` version-update PRs.
- Trigger-level `paths:` on `ci.yml`.
- Retries as a flake cure.
- Playwright `workers > 1` or sharding.
- Dropping the min lane. It caught 2 unique failures in 30 days.
- Making Browser-full required.
- A git history rewrite.
- SQL Sandbox.
- `postgres:19beta*` in a required lane.

### Architecture Approach

The product's three layers are untouched. v1.43 changes the CI topology, and [ARCHITECTURE.md](ARCHITECTURE.md) maps each change to file:line and to the contract tests it disturbs. The governing rule is **same-commit roster change**. Any add, remove or rename of a `verify-*` job id changes four things in one commit: the `ci.yml` header comment, the job key, CONTRIBUTING's job table, and `ci-required` `needs:` plus its CONTRIBUTING roster. New job ids must start with `verify-`, or the parity scan cannot see them. Logic belongs in table-tested `bin/` scripts, following the `bin/classify-flake-run` precedent, not in YAML. "Fastest failure first" means YAML and step order, never a `needs:` preflight chain, which would add about 1–1.5 min to every green run.

**Major components:**
1. **`ci-required` (alls-green, pinned SHA):** the only required check. Its roster changes here, and it gets a dynamic `allowed-skips` only in the final phase. Its name `CI required` is byte-pinned and must never be renamed.
2. **`verify-deps-audit` (new, Tier 1):** runs `hex.audit` over all three lockfiles, asserts the Hex version, and is backed by a negative fixture test.
3. **`verify-repo-hygiene` (new, Tier 0, no BEAM):** runs the `bin/` local-path guard. A `mix verify.*` alias wraps it for `ci.all`.
4. **`deps-health.yml` (new, weekly, not required):** runs `hex.audit` and `hex.outdated` and upserts a `ci-deps` issue. Its label stays distinct from `ci-flake` and `ci-browser-full`.
5. **Modified lanes:**
   - `flake-detection.yml`: bounded and weekly, with a contract-compliant cache key.
   - `browser-full.yml`: on push, runs the set difference against CI's projects.
   - `release.yml` `bootstrap-release-pr-ci`: guarded on PAT presence.
   - the `verify-test` matrix: gains `lane: latest`.
6. **`verify-change-scope` + `bin/classify-ci-lanes` (last phase, conditional):** a fail-closed classifier. On push and dispatch it emits an empty `allowed_skips`.

### Critical Pitfalls

1. **Audit gate: vacuous, or red on an unchanged commit.**
   - Assert Hex >= 2.5.1. An older Hex audits retirements only, or ignores the ignore list.
   - Add a negative test that runs the gate against a fixture lock with a known-advisory version.
   - Require every `ignore_advisories` entry to carry a reason, a reachability claim and a review-by date, enforced by a test. Hex only *warns* on stale entries.
   - Pair the PR gate with the weekly `main` audit, so a new advisory surfaces as an issue before it blocks PRs.
2. **Skip laundering through `alls-green`.**
   - No static `allowed-skips` and no `continue-on-error` on voting jobs.
   - The classifier is required and unskippable. Each `if:` skips only on an exact `'false'`, so an empty output means the job runs.
   - `push` and `workflow_dispatch` always run the full matrix.
   - Markdown is tested code in this repo (doc-contract tests), so "docs-only" is not inert. Classify from an allowlist of provably inert paths; anything unknown gets the full matrix.
3. **Deleting a "duplicate" that catches a distinct failure class.**
   - Write a "still caught by" line for every removal.
   - For Browser-full, use a computed set difference plus a contract test that the PR lane's projects together with Browser-full's equal the Playwright config's project set. A hand-maintained list would let a new project run nowhere.
   - Record a conscious decision about dropping the min lane's OTP 26 Dialyzer run.
4. **`_build` cache serving wrong artifacts.**
   - Use exact keys that include MIX_ENV, a profile segment, the resolved OTP/Elixir and the lock hash. No `restore-keys`.
   - Run `rm -rf _build/$MIX_ENV/lib/threadline` before compiling.
   - Keep `verify-compile-no-optional` cache-free, or it can false-green.
   - Never add caches to the `release.yml` publish path (cache-poisoning route).
5. **Scrub and guard mishandled.**
   - Stage only the `git grep -l -I` file list. Never run `git add .planning/`, because about 1,066 untracked critic files live there.
   - Change the path prefix only. Do not rewrite receipts.
   - Scrub before the guard lands, and never allowlist the 295 files.
   - Keep real usernames out of the guard and its fixtures (build fixtures at runtime), and make the guard fail on unused allowlist entries.
   - The scrub protects the tip of `main` only while milestones land by squash PR and tags stay local.
   - Dispatch prompts must forbid executors from editing the allowlist to get the guard green.

## Researcher disagreements, resolved

| Topic | Positions | Resolution |
|---|---|---|
| **Runtime xref cycles (5, length 2)** | STACK: ratchet `--fail-above 5`. PITFALLS: named-cycle allowlist. FEATURES: anti-feature. PROJECT.md target text: "runtime-cycle ratchet (named allowlist)" | **No runtime-cycle gate.** The existing `verify.xref_cycles` (compile-connected, `--fail-above 0`, in `ci.all` and both test lanes) is the gate. Correct MILESTONE-GUIDE §9a so it names the `compile-connected` label. Record `Capture.AuditTransaction` ↔ `Semantics.AuditAction` (an Ecto association back-reference that crosses the capture→semantics direction) as an **architecture observation for a later milestone**, not as v1.43 work. **Amend the PROJECT.md target-features line** so requirements do not inherit the ratchet. |
| **Flake cadence** | STACK: weekly, 15 repeats, 60 min. FEATURES: weekly, 10 repeats, about 32 min. ARCHITECTURE: nightly, 10 repeats. PITFALLS: tagged subset plus a step timeout | **Weekly** (plus `workflow_dispatch`) with **10–15 repeats**, sized from measured per-iteration time. Add a **step-level timeout shorter than the job timeout**, so the classify, upload and issue steps always run. **Skip** when HEAD equals the last green flake SHA, and exit `broken-upstream` when CI on that SHA is red. On timeout, classify **inconclusive / budget-exhausted-clean**, never `unknown` with the false "no header" claim. The tracking issue **closes itself on pass**. `:live_dialyzer` leaves the repeat set through the T6 default exclusion. Fix the `runner.os`-only cache key, and widen the anti-regression grep to all workflows. |
| **Newest-toolchain lane** | All: pin exactly and never `continue-on-error`. FEATURES and PITFALLS: tension with PROJECT.md | **Spike first.** Run one dispatch run of Elixir 1.20.4 / OTP 29.1 / PG 18 under `--warnings-as-errors`. Land it only green, as a third `verify-test` entry (test job only). **Scope conflict flagged:** PROJECT.md Out of Scope says "Elixir/OTP version bumps in CI — unless required for runner or dependency breakage". An *added* lane arguably isn't a bump, but the maintainer should amend that line explicitly. The line also touches the OTP pin fix (27.0.1 → 27.3.4.18 via `.tool-versions`). That fix is justified under the "runner breakage" exception by the ubuntu-22.04 deprecation and the Node 20 removal, but record that justification. |
| **Audit gate Hex floor** | STACK: >= 2.5.0. PITFALLS: >= 2.5.1 | **Assert >= 2.5.1.** `ignore_advisories` only exists from 2.5.1, and a gate that cannot parse its own allowlist must fail. |
| **Scheduled audit cadence** | STACK and ARCHITECTURE: weekly. PITFALLS: nightly | **Weekly**, in `deps-health.yml`, together with the monthly-or-weekly `hex.outdated` report. The PR gate carries the blocking role. |
| **Bench HIGH count** | FEATURES T1 says "2 HIGH + more"; its own detail and STACK both give 3 | **3 HIGH** (plug ×2, postgrex ×1) out of 8 advisories. |
| **Composite setup action** | STACK: adopt. ARCHITECTURE: defer, because contract tests assert literal cache keys in job blocks | **Defer.** Reopen only if the `_build`-cache phase rewrites the parity assertions anyway. |
| **Dependabot `github-actions` updates** | STACK: a monthly grouped config. FEATURES: churn, bump by hand | **No version-update config in v1.43.** The milestone says "not dependabot churn", and each PR needs a maintainer merge. Put action-major currency in the freshness policy, reviewed at milestone open. Turning on Dependabot **alerts** is a maintainer toggle to hand off. |
| **Release double-dispatch fix** | ARCHITECTURE: `HAS_PAT` guard. FEATURES: a `pushed_with_pat` output. PITFALLS: PAT absence *or* no run for the head SHA | **Deterministic guard on PAT presence or the sync output.** Do **not** query "does a PR run exist", which races GitHub's event latency. Keep the job, its `needs:` and its `if: always()`, and extend `release_control_plane_contract_test.exs`. |
| **`verify-mechanical`** | ARCHITECTURE: remove. FEATURES: fold, or keep as a named fast signal. PITFALLS: committed vs regenerated inputs differ | **Remove the job and the capture lane's trailing step, and keep the alias.** After the byte-stable assertion, the regenerated evidence equals the committed evidence. `verify.test` runs the file in both lanes, and in 30 days the job never failed alone. Write the "still caught by" line. |
| **`@tag :tmp_dir` scope** | FEATURES: migrate about 40 files mechanically. PITFALLS: migrate only named-flaky or async-colliding tests | **Scoped migration:** the 7 files that leak into `/tmp` (no `on_exit`) plus async-colliding tests. **Leave** tests that shell out to `git`/`mix` in the temp dir, and "outside the repo" tests. Make tree-walking tests exclude `tmp/`. Frame this as hygiene, because no temp-dir flake is recorded. **Amend the PROJECT.md wording** ("temp-dir flakes"). |

**Other baseline corrections for PROJECT.md:**
- The flake fast-failure streak began 08-18, not 08-28.
- The timeout is already 180 min, and the last two nightlies were green at 98 and 137 min.
- FEATURES found 2 files **outside** `.planning/` with home-relative paths (in `prompts/prior-art/`), which contradicts "none outside it". The guard's patterns must cover home-relative forms.
- The tracked-file count has moved from 295 to 298.

## Implications for Roadmap

The phases continue from 214. The order is: measure → security fix → latent platform breaks → hygiene → deletions → cache → new lane → renames once → classifier (conditional).

### Phase 214: Baseline measurement
**Rationale:** Guide §9 says "measure before you optimize". v1.41's finding was a baseline that was never re-measured.
**Delivers:** An evidence doc with:
- per-job p50/p95 over at least 10 push and at least 10 PR runs;
- runner-min per PR, per push and per release cycle;
- the critical path;
- Flake and Browser-full costs;
- `--slowest 25`;
- the isolated `:live_dialyzer` cost;
- **the PR diff-class distribution** (the share of merged PRs that touch only inert paths).

All numbers cite run IDs. This is a local one-shot, not a CI job.
**Addresses:** X6. It is the input to T3–T7, X1 and X7.
**Avoids:** Optimizing against a stale baseline. It must also fix the PROJECT.md baseline corrections.

### Phase 215: Supply chain gate
**Rationale:** The headline defect. The lock fix lands before the gate, so the gate is born green.
**Delivers:**
- Lock-only bumps: lazy_html 0.1.13, mint 1.10.1, and a `bench/mix.lock` refresh.
- A CHANGELOG line for mint.
- Aliases: `verify.deps_audit` (unused-lock check plus `hex.audit` over root, example and bench).
- A `verify-deps-audit` job added under the same-commit roster rule.
- A Hex >= 2.5.1 assertion and a negative fixture test.
- An `ignore_advisories` expiry test.
- `deps-health.yml` (weekly audit plus `hex.outdated`, with a `ci-deps` issue).
- The freshness policy in CONTRIBUTING.

Hex `cooldown` is optional, and only after confirming where it is configured.
**Addresses:** T1, T2, X4.
**Avoids:** Pitfalls 1–3. There must be no `mix.exs` constraint change, and both test lanes must go green on the NIF bump.
**Release note:** A lock-only change is not a releasable commit type. Plan a `fix:`/`deps:` commit so the milestone "ships as a patch".

### Phase 216: CI platform currency
**Rationale:** Latent breaks that are already past or near their deadlines. The later cache keys depend on the resolved-OTP key shape.
**Delivers:**
- Commit `.tool-versions` (erlang 27.3.4.18 / elixir 1.17.3-otp-27).
- setup-beam `version-file` + `strict` on non-matrix jobs, and exact resolved OTP in PLT and cache keys.
- `actions/cache@v5` and `upload-artifact@v7`.
- `release-please-action@v5` as its own commit, rehearsed.
- The min lane moves to ubuntu-24.04, with a check that the lazy_html OTP 26 NIF artifact resolves.
- Flake-detection cache-key fix, and the anti-regression grep widened to all workflows.
- Contract tests `ci_topology_contract_test.exs:396` and `ci_workflow_parity_contract_test.exs:255` updated in the same commits.

**Addresses:** the new baseline facts.
**Avoids:** a floating OTP in keys (Pitfall 7). **Scope flag:** the PROJECT.md "no OTP bumps" line needs its runner-breakage justification recorded.

### Phase 217: Repo hygiene
**Rationale:** Independent of CI economy. Scrub before the guard. The tmp_dir work comes before the flake re-scope, so the flake lane measures a cleaner suite.
**Delivers:**
- A prefix-only forward scrub in its own commit, staging the explicit file list, and covering the 2 `prompts/prior-art/` files.
- A `bin/` guard with runtime-built fixtures, an unused-allowlist failure and a negative test, plus a `verify.*` alias in `ci.all` and a `verify-repo-hygiene` job.
- The MILESTONE-GUIDE §9a wording correction and the recorded cross-layer xref observation.
- The scoped `@tag :tmp_dir` migration.

**Addresses:** T8, X8, the xref disposition.
**Avoids:** Pitfalls 9, 10, 11 and 13.

### Phase 218: CI economy — remove waste
**Rationale:** Pure deletions and narrowing, each with a named dominating proof. The roster shrinks once, here.
**Delivers:**
- The flake re-scope from the resolution table.
- Tracking-issue close-on-pass (T10, also for #28).
- The release-PR dispatch guard.
- Browser-full push set difference plus the union contract test, and a nightly skip on an already-green SHA.
- Exclusion of `:live_dialyzer` by default and a run in `verify-dialyzer` (updating test_helper, CONTRIBUTING and the topology test together).
- Removal of `verify-mechanical` and the capture's trailing step.
- An optional D8 decision on `verify-docs`.
- Re-measurement against the 214 numbers.

**Addresses:** T3, T4, T5, T6, T7, T10.
**Avoids:** Pitfalls 6 and 8, and the release dispatch removed in the wrong direction.

### Phase 219: Deps-only `_build` cache
**Rationale:** Medium risk from stale artifacts, so isolate it. It comes after 218, when the cached job set is final, and after 216, when the key shape is final.
**Delivers:**
- Split restore/save caches.
- Exact keys: runner, resolved OTP/Elixir, MIX_ENV, profile, lock and config.
- `rm -rf` of the app's own build.
- A separate example-app cache.
- `verify-compile-no-optional` stays cache-free.
- The parity test at :252-270 rewritten to assert these rules.
- Before/after measured against 214.

**Addresses:** X1.
**Avoids:** Pitfall 7. Validate CI-only results after renaming away the stale local `public.threadline_capture_changes()`.

### Phase 220: Newest-toolchain lane (spike-gated)
**Rationale:** Elixir 1.20's type inference will likely emit new warnings under `--warnings-as-errors`. Prove the lane green before it votes. It reuses the 219 key shape.
**Delivers:** A dispatch spike and its findings. Then either a green, exact-pinned `lane: latest` in `verify-test` (with parity :233-249, List 2 and CONTRIBUTING updated), or a recorded "not yet" with the findings.
**Addresses:** X2.
**Avoids:** Pitfall 12. **Needs** the PROJECT.md Out of Scope amendment first.

### Phase 221: CI DX — names and order
**Rationale:** Rename once, after every add, remove and lane change, so names and docs churn one time.
**Delivers:**
- `name:` rewrites that say what failed, including the evaluator name. Job ids stay immutable, and `CI required` stays byte-exact.
- YAML ordered by time-to-red.
- CONTRIBUTING name quotes updated in the same commit.

**Addresses:** T9, X9.
**Avoids:** `needs:` chains, and rename drift across contract surfaces.

### Phase 222: SEED-006 change-aware lanes (LAST, CONDITIONAL)
**Rationale:** It is the only change that weakens what a single PR proves. **Build it only if the 214 diff-class data, re-checked after 218–219, shows a material share of skip-eligible PRs.** Otherwise record "measured, not worth it" and close SEED-006.
**Delivers (if built):**
- `bin/classify-ci-lanes`, driven by an inert allowlist, with anything unknown running the full matrix.
- `ci_lane_classifier_contract_test.exs`, covering the fixture table, completeness, contract-read files, and push/dispatch always yielding an empty `allowed_skips`.
- A `verify-change-scope` job in the roster.
- Fail-closed `if:` on skip-eligible jobs only (browser, capture, pgbouncer, perhaps the evaluator; never `verify-test` or the rehearsal).
- A dynamic `allowed-skips`, with deliberate amendments to `release_control_plane_contract_test.exs:90-120` and a CONTRIBUTING `allowed-skips decision:` entry.
- A step in `ci-required` that re-derives the justification for each skip.

**Addresses:** X7.
**Avoids:** Pitfalls 4 and 5. Never use `pull_request_target` or `workflow_run`.

### Phase Ordering Rationale

- Each gate's fix lands before the gate: advisories before the audit gate, and the scrub before the path guard.
- Platform currency (216) precedes the cache work (219), because keys must use the resolved OTP. It also precedes the new lane (220), which needs ubuntu-24.04 and Node 24 actions.
- Deletions (218) precede caching (219), so only the final job set is cached. Renames (221) come after every roster change, so docs and contract tests churn once.
- The classifier is last because its value depends on the post-wins baseline, and it carries the highest laundering risk.
- 215, 216 and 217 are mutually independent. If the Node 20 forced-upgrade shim is withdrawn, 216 can be pulled ahead of 215.

### Research Flags

Phases likely needing `--research-phase` during planning:
- **Phase 220 (newest lane):** the Elixir 1.20 warning surface under `--warnings-as-errors` is unknown until spiked, and it depends on the scope amendment.
- **Phase 222 (classifier):** dynamic `allowed-skips` through alls-green has not been exercised in this repo (MEDIUM). Enumerate the file reads of the doc-contract tests.
- **Phase 219 (`_build` cache):** config-in-key and profile segments are inference. Also check eviction under the 10 GB cache budget.
- **Phase 216 (platform), partial:** a release-please-action v5 rehearsal, and lazy_html NIF availability for OTP 26 on ubuntu-24.04.
- **Phase 215, narrow:** where Hex `cooldown` is configured, if it is adopted.

Phases with standard patterns (skip research):
- **Phase 214:** `gh run view` measurement that already has a method in FEATURES.md.
- **Phase 217:** the guard, scrub and tmp_dir semantics are fully specified.
- **Phase 218:** every change has file:line and a named dominating proof.
- **Phase 221:** name and order edits under known contracts.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Versions, advisories and action runtimes were checked against hex.pm, OSV, `gh api` and the source at tagged versions. Policy choices (cooldown, freshness cadence) are MEDIUM inference. |
| Features | HIGH / MEDIUM | Per-job durations, duplicates and flake regimes come from 280 runs with cited IDs (HIGH). Projected savings are arithmetic on those numbers (MEDIUM). The live-Dialyzer cost is not isolated. |
| Architecture | HIGH | Integration points and contract-test impacts were read from the tree at file:line. The dynamic `allowed-skips` expression is MEDIUM. |
| Pitfalls | HIGH | Mostly repo-observed. The Hex changelog version attribution is a LOW single source, but the local `mix help hex.audit` confirms the 2.5.1 behaviour. |

**Overall confidence:** HIGH

### Gaps to Address

- **`:live_dialyzer` cost per lane is not isolated:** measure it in 214 before claiming the approximately 375 runner-min/month saving.
- **PROJECT.md drift:**
  - the flake baseline numbers;
  - the xref "ratchet" target (remove it);
  - the tmp_dir "flakes" wording;
  - the claim of no paths outside `.planning/`;
  - the Out of Scope OTP line (amend, with its runner-breakage justification).

  Fix these at requirements time.
- **Releasability:** the milestone must ship as a patch, but lock and CI changes are not releasable commit types. Plan at least one `fix:`/`deps:` commit (the mint CHANGELOG line). Push, merge and `production-hex` approval stay with the maintainer.
- **Maintainer toggles to hand off:**
  - Dependabot alerts;
  - optionally `secret_scanning_non_provider_patterns` (plan eligibility unverified).
- **Floor decisions for v1.45, not v1.43:** Elixir 1.15 is out of support, and PG 14 reaches EOL on 2026-11-12.
- **Capture↔Semantics runtime edge:** recorded as an architecture observation. Whether it violates "layers stay one-directional" at runtime is a later-milestone question.
- **Hex `cooldown` config location:** unverified. Adopt it only after confirming.

## Sources

### Primary (HIGH confidence)
- GitHub Actions runs, 2026-08-27 → 2026-09-26 (280 runs), including 36258719902, 36258719891, 36256339043/36256344029 (double-dispatch pair), 35967937335 (45-header cancelled flake run), 34679766829 (broken-main flake failure), 36225676728 and 36106137910 (green flake runs), 36084731591 and 36082981344 (unique min-lane catches); issues #28 and #36.
- Local command output: `mix hex.audit` (root, example, bench; Hex 2.5.1), `mix hex.outdated`, `mix deps.unlock --check-unused`, `mix xref graph --format cycles` with and without `--label compile-connected`, and a `git grep` path census.
- Repo files: `.github/workflows/{ci,flake-detection,browser-full,release}.yml`, `mix.exs`, `test/test_helper.exs`, the contract tests (`ci_topology`, `ci_workflow_parity`, `ci_coverage_doc`, `release_control_plane`, `flake_classifier`, `dialyzer_slice`, `clean_checkout`), `bin/classify-flake-run`, `bin/upsert-ci-issue`, CONTRIBUTING.md, and SEED-006.
- OSV: EEF-CVE-2026-82672 (mint, fixed 1.10.1) and EEF-CVE-2026-92106 (lazy_html, fixed 0.1.13).
- Hex source at v2.5.1 (`hex.audit`), setup-beam v1.24.1 source (`.tool-versions` parser), and ExUnit `create_tmp_dir!` at v1.15.8 and v1.17.3.
- GitHub changelog on the Node 20 removal (2026-09-23), actions/runner-images#14254 (ubuntu-22.04), and the PostgreSQL versioning policy (PG 14 EOL).

### Secondary (MEDIUM confidence)
- The re-actors/alls-green README (dynamic `allowed-skips` expression use).
- The Elixir 1.20 release notes and changelog (type inference, OTP 27–29).
- PostgreSQL 19 Beta 4 news, and dependabot-core#15020 (Hex dependency graph not shipped).

### Tertiary (LOW confidence)
- The Hex CHANGELOG version attribution for advisory features (2.5.0 vs 2.5.1). The local help text confirms the 2.5.1 behaviour.
- Elixir Forum threads on `mix hex.audit` in CI.

---
*Research completed: 2026-09-26*
*Ready for roadmap: yes*
