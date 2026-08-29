# Phase 198: Green Bringup - Context

**Gathered:** 2026-08-27
**Status:** Ready for planning

<domain>
## Phase Boundary

`origin/main` carries every local commit and its CI concludes green well inside a usable feedback loop; the red-test baseline that nobody re-derived is retired with each former failure fixed on its merits; branch protection requires exactly the checks CI emits; and the measurement sweep that sizes Phases 201 and 203 is on disk before either is planned.

Covers GREEN-01 .. GREEN-12. This is a **bringup and gating** phase — no product behavior changes, no operator-UI design/IA/layout/visual change, no capture/query/auth semantic change.

</domain>

<ground_truth>
## Ground Truth Corrections (verified during discussion — these SUPERSEDE the roadmap)

Four parallel research agents read the actual workflow files, `playwright.config.ts`, `mix.exs`, the test suite, and live GitHub state. Three of the roadmap's stated premises for Phase 198 are **wrong**. Planning must use the corrected version.

| Roadmap / prior belief | Verified reality | Evidence |
|---|---|---|
| PR #26 is blocked by a phantom required-check name that CI cannot emit | PR #26 is blocked by a **genuinely RED required check**. All six required contexts reported; `Run test suite` **failed**. | `gh pr checks 26`; live protection contexts: `Check formatting`, `Run Credo (strict)`, `Run test suite`, `Build ExDoc (dev)`, `Hex package tarball`, `Release metadata (version / changelog)` |
| The `min` lane "has never executed on origin" (a required-checks picker problem) | The matrix commit `cce7f409` and `8fe32c6b` were **never pushed**. `origin/main` is `67998e0b` and runs a materially older `ci.yml`. Nearly every "CI is red" symptom traces to origin being old. | `git log origin/main`; local `main` = `412123ca` |
| ~81 local `mix test` failures are a PostgreSQL `search_path` env issue, fixed by `ALTER DATABASE … SET search_path` | **Stale local test database** predating `priv/repo/migrations/20260607000000_threadline_storage_schema_default.exs`, which moved audit tables from `public` to `threadline`. CI provisions a fresh `threadline_test` container with **no** `ALTER DATABASE` step and is green. | `.github/workflows/ci.yml:99-162`; the only `ALTER DATABASE … SET search_path` in the repo is `ci.yml:374-375`, scoped to `threadline_phoenix_test` for the example app's unqualified demo-seed queries |
| The red baseline is a large body of deterministic failures | On a fresh DB the suite has **one** deterministic failure: `test/threadline/v1_23_charter_doc_contract_test.exs:18` asserts `.planning/PROJECT.md` says `v1.38`; it says `v1.41`. | Agent executed the suite |

### Two live, undetonated hazards discovered

1. **The GREEN-08 failure mode is armed, not historical.** `.github/workflows/ci.yml:106` sets a static `name: Run test suite` over a base matrix axis `lane: [min, current]` (`ci.yml:109-121`), and `ci.yml:100-106` asserts GitHub will emit `Run test suite (min)` / `Run test suite (current)`. **If that comment is correct, the moment local `main` is pushed the required context `Run test suite` becomes permanently unsatisfiable** — precisely the deadlock GREEN-08 exists to prevent. The append behaviour is **unverified** and has never been observed on origin. The aggregate-gate decision (D-06) makes this moot for protection purposes, but it must still be observed and recorded.

2. **Pushing 587 commits fires the parked paid critic lane.** `.github/workflows/ui-critic.yml:14-21` triggers on `push: branches: [main]` with a `lib/threadline/operator/**` path filter, which 587 commits will match. `ui-critic.yml:48` binds `secrets.ANTHROPIC_API_KEY`; `:22-32` exposes the `score` boolean; `:103-113` branches into the paid runner. **GREEN-09 must land BEFORE the push (D-15), not as cleanup after it.**

### Additional verified facts for planning

- **Zero `timeout-minutes` exist in any of the five workflows** (grep across `.github/workflows/`). The concurrency block at `ci.yml:22-24` never cancels `push: main`, so an unbounded hang bills up to 6h.
- **`playwright.config.ts:16-18`** defines three *unscoped* Chromium projects (`chromium`, `desktop-chromium`, `mobile-chromium`) with no `testMatch`. Each runs all 126 `test(` blocks across 27 specs → **~382 serialized test invocations** in one job, at `workers: 1` (`:126`), `timeout: 120_000` (`:122`), `retries: 1` on CI (`:125`). This is both the 1h33m systemic-break cost and the reason the job is slow when green.
- **`chromium` is redundant with `desktop-chromium`** — same `devices["Desktop Chrome"]`, differing only 1280×720 vs 1280×900. ~33% of browser work for zero added coverage.
- **Cache keys collide across lanes.** `ci.yml:42` keys on `${{ runner.os }}`, which is `Linux` for **both** ubuntu-22.04 and ubuntu-24.04, and carries no OTP/Elixir. The `min` and `current` lanes currently share one cache entry.
- **Four jobs run today but are required by nothing:** `Compile without optional deps`, `Hex evaluator smoke`, `PgBouncer transaction topology`, `Example app browser E2E`.
- **`hex-publish.yml` wins the publish race by construction.** It self-describes as "Legacy fallback" (`:1-3`), fires on any `v*.*.*` tag push (`:7-10`), and runs `mix hex.publish --yes` (`:52-61`) with no CI gate. release-please tags using `RELEASE_PLEASE_TOKEN` (`release.yml:96`), a PAT — and PAT-created tags **do** trigger workflows — so it publishes within a minute while `release.yml` sits in its 30-minute `gate-ci-green` poll (`release.yml:221-234`).
- **The paid billing code is not in `lib/`.** No `ANTHROPIC` reference exists anywhere under `lib/`. The actual API client is `examples/threadline_phoenix/e2e/critic/client.ts` + `critic-before-pole.sh:34`, neither of which enters the Hex tarball (`mix.exs:323-324`).
- **`lib/mix/tasks/critic.measure.ex` and `critic.synth.ex` DO ship** in the tarball and on HexDocs today. They make no API calls, so they are not a billing path — this is Phase 200's `@moduledoc false` work, **not** 198's.
- **Hex trusted publishing / OIDC is announced but NOT GA** as of 2026 (Hex 2.4 shipped OAuth device flow + CLI 2FA as the intermediate step). `HEX_API_KEY` stays for now.
- **Live protection settings:** `strict: true`, `enforce_admins: false`, `required_linear_history: false`, `required_conversation_resolution: false`, `rulesets: []`.
- **`.planning/` disclosure surface:** 2159 tracked files, 49 containing dollar figures (LLM spend down to `$0.015`), plus vendor/model names and internal quality assessments. A HEAD grep is already clean of `sk-ant-`, `ghp_`, `github_pat_`, `AKIA`, and PEM private-key patterns; `.gitignore:26-28,79` covers `.env`.
- **Local git state:** 2 worktrees (`/Users/jon/projects/threadline`, `/Users/jon/projects/threadline-phase166` at `dd5b48be`); 3 branches (`main` ahead 587, `gsd/phase-166-unfreeze-token-lane-mechanism` at `dd5b48be`, `backup/pre-release-cleanup-2026-05-08` at `50374eb7`). `dd5b48be` is verified NOT an ancestor of `main`: 24 files, +719/−56.
- **`.planning/milestone.lock`** is a stale untracked artifact from a dead session (pid 62757, `"phase": "null"`) dirtying `git status`. Deferred to Phase 199 / DECOUPLE-05.

</ground_truth>

<decisions>
## Implementation Decisions

### Green Definition & the Red Baseline (GREEN-04, GREEN-05)

- **D-01:** "Green" means **fresh clone + `mix test` locally is byte-identical to CI**, both reachable via `mix ci.all`. `mix test` is the contributor contract. The ~81 local failures are NOT in the baseline — they are a stale-DB artifact of the maintainer's machine, not a fresh-clone defect.
- **D-02:** Do **NOT** set a repo-level `search_path` (`parameters: [search_path: …]` in `config/test.exs`) and do **NOT** use `Repo.default_options(prefix:)`. Both enshrine search_path reliance the library explicitly forbids, and `default_options(prefix:)` would relocate `schema_migrations` into `threadline`. `test/threadline/storage_schema_prefix_contract_test.exs:31` actively **refutes** `@schema_prefix "threadline"` and would catch this. — **Reversibility:** costly — reversing means unwinding a runtime prefix decision that D-190-12/D-190-16 already settled and that a contract test guards.
- **D-03:** Instead, add a **stale-schema tripwire** in `test/test_helper.exs` (after the `Ecto.Migrator.run/3` at `:13`) that queries `information_schema.tables` for `audit_transactions`/`audit_changes`/`audit_actions` still in `public`, and raises **once, loudly**, naming the cause ("this test database predates the storage-schema migration") and the fix. Scope it to `Threadline.Test.Repo`'s own database only, never in `lib/` — a host application may legitimately have `public.audit_*`. Guard against false-positives from the legitimate `audit` schema created by `test/support/storage_schema_case.ex`.
- **D-04:** Add `mix test.reset` (`ecto.drop --quiet -r Threadline.Test.Repo` then `test`) and `mix test.setup` aliases to `mix.exs`. `test/test_helper.exs:13` already calls `storage_up/1`, so `test.reset` needs only the drop. Rationale: Threadline's default is effectively `--keepdb` with no staleness check; Django's default is recreate and `--keepdb` is opt-in. Restore the safe default without the runtime cost.
- **D-05:** **Triage taxonomy is binding, with an anti-laundering guard.** Every former failure gets a row in a `198-TRIAGE.md` artifact: `test | category | disposition | evidence`.
  - *Real bug* → fix `lib/`, keep assertion. Evidence: a failing→passing commit touching `lib/`.
  - *Rotting assertion* → rewrite as derive-from-SSOT. Evidence: the new assertion must be demonstrated **failing** against a deliberately drifted SSOT (prove it has teeth).
  - *Environmental* → fix the **setup path** (tripwire/alias), never the test. Evidence: CI job AND fresh clone both green.
  - *Genuinely obsolete* → `git rm`, naming the superseding guard, or explicitly admitting coverage was dropped.
  - **Hard cap: `tag+exclude` count must be ZERO in Phase 198**, asserted mechanically — a test that greps `test/**/*_test.exs` for `@tag :skip` / `@moduletag :skip` and asserts `ExUnit.configuration()[:exclude] == [pgbouncer_topology: true]`.
- **D-06 (version literals):** `test/threadline/v1_23_charter_doc_contract_test.exs` is classified **obsolete → `git rm`**, not version-bumped and not loosened to a `~r/v1\.\d+/` regex that asserts nothing. It is a Phase-104 planning-doc readability proxy over `.planning/`, which v1.41 is explicitly decoupling from. The triage artifact must record it honestly, with no successor guard — an honest admission of dropped coverage beats a silent bump. Where a version check is still wanted, copy the **derive-from-SSOT** idiom already proven at `test/threadline/version_truth_doc_contract_test.exs:24-45`.
- **D-07 (GREEN-05 formless guard):** Replace the `@formless_pages` allowlist (`formless_pages_test.exs:47-54`) with a **self-declaring `@ui_form_policy` module attribute** (`Module.register_attribute(persist: true)`, valued `:formless` or `{:has_forms, "reason"}`) over an **exhaustive directory scan** of `lib/threadline/operator_surface/live/*.ex`. Pattern name: *self-describing fixture / co-located contract with a derived roster*. It beats the allowlist on three axes: (a) the fix lands in the changed file — GREEN-05 verbatim; (b) a newly added page **cannot be silently unguarded**, which today's non-exhaustive list permits; (c) reverse drift (a page losing its form but keeping a stale exemption) is caught too. The scan MUST assert the glob is non-empty (copy `version_truth_doc_contract_test.exs:59`) so it cannot pass vacuously. `surface_header.ex` stays excluded naturally — it is not in `live/`.

### Branch-Protection Contract Shape (GREEN-08)

- **D-08:** Adopt a **single aggregate gate** — job id `ci-required`, `name: CI required` — as the **only** required status check on `main`. This dissolves the `ci.yml:100-106` matrix-naming hazard entirely (the aggregate's name has no matrix axis, so it cannot rot) and absorbs Phases 199/203/204 adding dialyzer, credo, and CSS-hash lanes with **zero protection edits**. It honors the `CLAUDE.md` stable-`id:` convention by moving durable identity from twelve names to one. — **Reversibility:** costly — reverting to enumeration means re-deriving and re-entering every emitted check name in protection, and re-arming the matrix-rename deadlock.
- **D-09:** Implement it with **`re-actors/alls-green@release/v1`** under **`if: always()`** — **never** the hand-rolled `contains(needs.*.result, 'failure')` idiom. Rationale: a job that `needs:` a failed job is marked *skipped*, and **GitHub scores a skipped required check as PASSING**. `if: always()` defeats skipped-on-dependency-failure; `jobs: ${{ toJSON(needs) }}` inspects every result value (`success|failure|cancelled|skipped`) rather than the two strings `contains()` tests; a never-scheduled job appears as `skipped` and therefore fails unless explicitly allow-listed. `fail-fast: false` (`ci.yml:108`) ensures a `min` failure still reports.
- **D-10:** **Never filter at `on: pull_request: paths:`.** A workflow filtered out at the `on:` level never reports, and the PR hangs forever on "Expected — Waiting for status to be reported." Keep `ci.yml:9-10` unfiltered; add a `changes` job and gate at the **job** level, with `|| github.ref == 'refs/heads/main'` to preserve the CLAUDE.md "path filters + main" convention.
- **D-11:** The `min` lane never becomes an individually required check. Under the aggregate it is already covered by `needs: verify-test`, which spans both matrix legs. Push the matrix first, **observe** the emitted names, and record what GitHub actually did with the static-`name:`-over-matrix question (currently unverified) — that observation IS GREEN-08's "verified after the matrix has reported once."
- **D-12:** **Verification is a committed script, not a runbook.** Add `bin/verify-branch-protection` (sibling to the existing `bin/verify-release-shape`, `ci.yml:573`), wired as a CI job on `main`. It must do **both** halves: (a) diff live protection contexts against the expected singleton `CI required` and fail on any difference; (b) assert via `gh api repos/:owner/:repo/commits/main/check-runs` that the name **has actually been emitted on a real run** — this second half is the executable form of "after the matrix has reported once." A runbook is an assertion; a script is proof.
- **D-13:** **Migrate to a repository ruleset**, exported and committed as `.github/rulesets/main.json`. Settings: `required_status_checks: ["CI required"]` with `strict_required_status_checks_policy: false`; `non_fast_forward`; `deletion`; `required_linear_history`; `pull_request` with `required_approving_review_count: 0` and `required_review_thread_resolution: true`; `enforcement: active` with a bypass actor scoped to the **release-please app only**. **No** signed commits (breaks bot PRs, deters contributors). **No** merge queue (overkill at solo throughput). Note `gh ruleset` CLI is read-only; write via `gh api`.
- **D-14:** **Turn `strict` OFF** (currently `true`). "Require branches to be up to date" forces rebase churn against a 20-minute CI and deadlocks release-please PRs. Simultaneously turn **`enforce_admins` ON** (currently `false`, which makes protection theater). This is the trade that pays back the security lens for accepting the aggregate: one legible gate, genuinely enforced.

### CI Cost Surgery (GREEN-06, GREEN-07)

- **D-15:** The ≤20-min lever is **project fan-out and `workers: 1`, not sharding and not caching.** Apply in this order: (1) **delete the redundant `chromium` project** at `playwright.config.ts:16`; (2) add `maxFailures: process.env.CI ? 5 : 0` and per-job `timeout-minutes`; (3) split the browser job (see D-17); (4) recompose cache keys (D-19); (5) shard **only if** (1)+(3) still miss the budget. Sharding is last because it pays a `mix compile --force` + `demo.reset` + `demo.seed` preamble **per runner** (`e2e/run-e2e.sh`) — a large fixed cost.
- **D-16:** **Every job in all five workflows gets `timeout-minutes`.** Budget: `verify-*` fast jobs 10; `verify-test` (both lanes) 20; reduced `verify-example-browser` 18 (with a 14-minute step-level bound on the Playwright run); full browser lane 50; `verify-capture` 35; `verify-pgbouncer-topology` 20; `verify-hex-evaluator` 15. Bound = generous multiple of observed p95, sized to catch a hang without flaking a slow runner.
- **D-17:** **Split the browser lane.** The PR lane keeps the **existing job id AND name byte-identical** (`verify-example-browser` / `Example app browser E2E (Playwright)`) but runs only `desktop-chromium` + `mobile-chromium`, and **stays inside `CI required`** — it votes. A **new** id `verify-example-browser-full` runs the whole project set on `push: main` + nightly `schedule`, and is **not** required. — **Reversibility:** reversible.
- **D-18:** **Fail fast without losing diagnosis.** `--max-failures=5` (not `-x`) aborts the run while leaving `trace: "retain-on-failure"` (`playwright.config.ts:140`) traces for the failures that did occur; upload them plus `/tmp/threadline_phoenix_e2e.log` on `if: failure()`. `e2e/run-e2e.sh` already implements the correct boot preflight (120×1s poll on `/users/log_in`, then `tail -80` of the log) — **extend that final `curl` to also hit `/audit`**, so a broken operator mount aborts before 382 tests each burn 120s. Failing fast and *diagnosing* fast are different requirements; GREEN-06 needs both.
- **D-19:** **Recompose cache keys now so Phase 199's PLT slots in unchanged.** Key `deps` and `_build` on `matrix.runner` + `matrix.otp` + `matrix.elixir` + `hashFiles('mix.lock')` — **never `runner.os`**, which is `Linux` for both 22.04 and 24.04. `_build` gets **no `restore-keys`** (a partial restore across a changed lock is the stale-beam footgun); PLT restore-keys **are** correct, since PLTs update incrementally. Always `rm -rf _build/$MIX_ENV/lib/threadline` before compiling. The Phase 199 PLT key must include `mix.exs` (that is where `plt_add_apps` for the 9 optional deps lives) and `otp` (PLTs are not portable across OTP).
- **D-20:** **No `on: paths:` workflow-level filters** (reinforces D-10). Only five workflows and a library-shaped repo — filters buy little and risk `main` divergence.
- **D-21:** **Both `min` and `current` lanes stay PR-blocking from day one**, but the `min` lane is **rehearsed** via `workflow_dispatch` on the staging branch before the PR opens. Rejected: `continue-on-error: true` — a non-blocking gate that is never promoted is permanent decay. `min` is the floor promise to Elixir 1.15 adopters; trimming it is the exact "quiet downgrade" the OSS DNA forbids.
- **D-22:** **Never raise `workers` for the four capture projects** (`tier-a-capture*`, `storybook-capture`, `graded-capture`, `refute-capture`). Byte-stable evidence (`ci.yml:390-399`) is a hard constraint. Leave `workers: 1`.
- **D-23 (honesty mechanism for what moves to nightly):** GREEN-06 plus the OSS DNA's "honest default tests" rule require this to be visible, not silent: (a) the new full lane gets a stable id in its own workflow; (b) a **CI Coverage table in `CONTRIBUTING.md`** stating verbatim which Playwright projects run on PRs vs main vs nightly; (c) a **doc contract test** asserting that table's project list equals the actual `--project` flags in the workflow — reusing the repo's existing `verify.doc_contract` idiom (`mix.exs:88-90`); (d) nightly failure opens/updates a GitHub issue via `gh issue create` in an `if: failure()` step, since `schedule` runs email nobody.

### Irreversibility Guards (GREEN-09, GREEN-10, GREEN-11, GREEN-12)

- **D-24 (GREEN-09):** **Delete `.github/workflows/ui-critic.yml` outright.** Do NOT keep a stripped skeleton — a workflow with the input removed IS the "defaulted off" state GREEN-09 explicitly rejects, and it invites a one-line resurrection. Deleting the trigger satisfies "the billing code path is absent" because the actual API client (`examples/threadline_phoenix/e2e/critic/client.ts`, `critic-before-pole.sh:34`) becomes unreachable from CI and never enters the tarball. `mix verify.ui_critique` (`mix.exs:111,247-267`) is already maintainer-local, requires a key in the operator's own shell, and is excluded from `ci.all` — leave it. — **Reversibility:** reversible — restore is `git checkout archive/critic-lane-v1.40 -- .github/workflows/ui-critic.yml`, which keeps CRITIC-02 ("resume iff spend/value is reconsidered") cheap.
- **D-25:** Guard resurrection with **assertions in the existing `test/threadline/ci_topology_contract_test.exs`** (already wired into `verify.release`, `mix.exs:158`): zero workflows reference `ANTHROPIC_API_KEY`, and exactly one workflow contains `mix hex.publish`. A test, not a comment — the Threadline-idiomatic guard.
- **D-26 (GREEN-10):** **`release.yml` survives; `hex-publish.yml` is deleted.** `release.yml` already has all three gates: `gate-ci-green` (`:221-234`), a hard `needs:` dependency (`:276-281`), `bin/verify-release-shape` + `mix hex.build` (`:319-323`), an already-published idempotency skip (`:326-333`), and post-publish verification (`:362`). Keep every one. — **Reversibility:** one-way in effect — `mix hex.publish` is irreversible (hex.pm offers roughly a one-hour revert window, then it is a support request), so the gates protecting it must never be weakened. Losing the tag-triggered fallback is acceptable; recovery is `workflow_dispatch` (`release.yml:13-27`).
- **D-27:** Keep `HEX_API_KEY` — **Hex trusted publishing / OIDC is not GA**. Mitigate with a GitHub **Environment** (`production-hex`) carrying a **required-reviewer rule on the `publish-hex` job**, so the irreversible step needs a human click; scope the key to publish-only. Migrate to OIDC the day Hex ships it. Build the pipeline so the auth step is one swappable block.
- **D-28 (credential audit):** Scan **full history, not HEAD** — 587 commits is exactly the window where a `.env` gets committed and reverted. Run `gitleaks` with `--log-opts="--all --full-history"`, a `--no-git` pass for the untracked working tree, `trufflehog` in **verified** mode (it calls the provider to test liveness), and a `git log --all --diff-filter=A` sweep for ever-added-then-removed `.env`/`.pem`/`id_rsa`/`credentials`/`.netrc` files. Enable **GitHub secret scanning + push protection BEFORE** the push as a third net. Commit the reports to `.planning/audits/`.
- **D-29 (the decision rule for "a secret was found" — binding, stated in advance so it is never litigated under pressure):**
  - **Class A — rotatable credential we control** (API key, PAT, DB password, our own private key) → **rotate immediately, BEFORE the push**; remove from HEAD if present; log in the register; **push proceeds**. History rewrite is NOT triggered — rotation makes the artifact inert, and force-rewriting a 587-commit public-bound repo costs more than it buys.
  - **Class B — cannot be made inert** (a third party's credential, customer/user PII, NDA'd vendor terms, someone else's personal data) → **ABORT the push. Escalate.** This is the **only** class that may override the "no git history rewrite" constraint, and only with a written finding naming the affected party; the rewrite-or-abandon call is made *with* them, never unilaterally.
  - **Class C — false positive, example value, expired, or already public** → record in the register with the reason; push proceeds.
  - **Invariants:** rotation happens *before* `git push`, never after. **Push protection blocking a push is a Class A/B signal — clicking "allow secret" is forbidden.** No class is decided verbally; every finding gets a register row.
- **D-30 (`.planning/` disclosure posture — USER DECISION):** **Publish as-is.** No content sweep. An audit library that shows its own record — including LLM spend figures and honest self-assessments that contradict its own docs — is on-brand and defensible; the record is an asset, not a liability. The credential scan (D-28) still runs and still gates the push, but **only Class A/B credential findings** block it. Content disclosure is explicitly NOT a gate. — **Reversibility:** one-way — 587 commits of internal planning history become permanently public and mirrorable; the no-history-rewrite constraint means nothing here can be un-published.
- **D-31 (GREEN-12 branch triage):** Archive-tag convention is `archive/<original-branch-name>`, **annotated**, with a message carrying: SHA, base, ancestry verification, diffstat, archive date + requirement, the merge-or-archive **recommendation**, rationale, restore command, and a register pointer. Create a tracked **`.planning/ARCHIVE-REGISTER.md`** — one row per archived ref (`ref | SHA | date | reason | recommendation | restore command`) — as the findable-in-five-years artifact. Apply to both `gsd/phase-166-unfreeze-token-lane-mechanism` (`dd5b48be`) and `backup/pre-release-cleanup-2026-05-08` (`50374eb7`); a branch named "backup" is an archive tag wearing the wrong hat.
- **D-32 (USER DECISION):** **Push archive tags to origin.** The "milestone tags stay local" rule existed solely because pushing would publish `.planning/` history — **that rationale is void the moment `.planning/` goes public on `main` in this very phase**. Local-only archive tags mean a laptop loss silently destroys the only copy of real unmerged work, which is exactly what GREEN-12 forbids. Whether *milestone* tags stay local is a separate question, deferred.
- **D-33 (USER DECISION):** The phase-166 merge-or-archive call is made **in-phase, after the diff artifact exists** — no mid-phase stop. Decision rule: **archive by default**; cherry-pick only if the diff carries unique unshipped value. Weigh (a) does it duplicate work already on `main`, and (b) does it touch files v1.41 is about to rewrite (it is operator-surface routing + style contract, and Phases 201/204 rewrite exactly those). The diff, summary, and recommendation must exist and be committed **before** anything is removed.
- **D-34 (ordering — irreversible steps are gated):**
  1. **Branch/worktree triage.** Gate: `dd5b48be` diff + summary + recommendation committed; archive tags created and verified (`git cat-file -p`) **before** any `git branch -D` / `git worktree remove`. Abort: any tag fails to resolve → stop, delete nothing.
  2. **Delete `ui-critic.yml`.** Must precede the push (see hazard 2 above). Gate: `grep -rl ANTHROPIC .github/` returns empty.
  3. **Delete `hex-publish.yml` + add the topology assertions.** Gate: `mix verify.release` green; `grep -rl "hex.publish" .github/workflows/` → exactly `release.yml`. **Abort: if `release.yml` cannot be shown green end-to-end, keep both and stop** — a broken single path is worse than a racy dual path.
  4. **Credential audit.** Gate: report committed, every finding classified per D-29, all Class A rotated **before** step 5. Abort: any Class B → do not push; escalate.
  5. **Enable secret scanning + push protection, then `git push` (+ archive tags).** Irreversible. Gate: steps 1–4 green.
- **D-35 (GREEN-11):** Flake Detection must (a) distinguish "suite is broken" from "suite is flaky" **by name** — a suite that fails on run 1 is broken, not flaky, and must be reported as such; (b) carry `timeout-minutes`; (c) surface failures to a **deduplicated** tracking issue (create-or-update, never a new issue per run), since `schedule` runs notify nobody.

### Measurement Sweep (GREEN-01, GREEN-02, GREEN-03)

- **D-36:** Plan 01 stays **read-only and first** — it sizes Phases 201 and 203 and must land before either is planned. Preserving run `28214113903` is a ~4-week window against a 90-day purge, not a nice-to-have. **Note:** that run predates the local matrix work, so its logs describe the *older* `ci.yml` on `origin/main` — record that caveat with the artifact so a future reader does not mistake it for the current pipeline.
- **D-37:** The Credo histogram is produced from a full-default config held **outside** the repo via `--config-file` (which *replaces* rather than merges), so `.credo.exs` is **never modified** in this phase. Deliver a per-check histogram **and** a per-file concentration table.
- **D-38:** The `verify.mechanical` sensitivity probe (GREEN-03) must answer **from evidence, not inference**, whether the checker is sensitive to rendered text content and width or only to tokens, contrast, and element geometry — and must do so **without touching any scorecard**. This answer sizes Phase 201 Tier 2.

### `CI required` Aggregate — Lane Dispositions (Round 3, MAINTAINER DECISION, 2026-08-28)

- **D-39 (`verify-capture` disposition):** **Keep `verify-capture` (`name: Tier A capture lane (byte-stable evidence)`) in `ci-required`'s `needs:`.** Maintainer's own words, recorded verbatim by the plan 198-20 executor: "A1 — Keep in `needs:`." This responds to CI run `33197493051`, on which `Tier A capture lane` was 1 of 3 red `needs:` dependencies behind `CI required`'s `failure` conclusion, and to 198-16's diagnosis (a document-wide `scrollHeight` read couples `scroll_cost` to the stress-lab catalog size; every remedy requires Tier-A `page.*` regeneration, which the maintainer had already re-ratified as forbidden this session). Under this choice, `CI required` keeps guaranteeing exactly what it always has for this lane — every merged PR proves byte-stable Tier A evidence proven fresh on that PR — and gives up nothing: no coverage shrinks, `.github/rulesets/main.json` needs no edit (it already names only the single context `CI required`), and no `CONTRIBUTING.md` row becomes false. **GREEN-07 remains uncloseable through this lane** for as long as the milestone-level regeneration prohibition stands — not an unfixed defect in the ordinary sense, but a structural constraint outside Phase 198's authority. — **Reversibility:** reversible — nothing is removed, narrowed, or weakened by this choice; switching to a `needs:`-removal later costs only a subsequent edit plus the D-23 honesty-mechanism work that removal would require.
- **D-40 (`verify-example-browser` disposition):** **Keep `verify-example-browser` (`name: Example app browser E2E (Playwright)`) in `ci-required`'s `needs:`, and fix the 28 masked failures in a dedicated successor round.** Maintainer's own words, recorded verbatim: "B1 — Fix the 28 masked failures in a dedicated successor round." This responds to CI run `33197493051`, on which `Example app browser E2E` was 1 of 3 red `needs:` dependencies, and to 198-17's diagnosis: its 5 originally-diagnosed failures are fixed and confirmed held on that measured run, but running the plan's own full local verify command surfaced 28 further pre-existing failures across 14 unrelated spec files, previously masked by `playwright.config.ts:141`'s `maxFailures: 5` ceiling (`deferred-items.md` Plan 198-17 entry, `WINDOWS.md` #8). Under this choice, `CI required` keeps guaranteeing exactly what it always has — a green PR proves the example app's interactive Chromium flows pass — and gives up nothing: D-17's explicit "stays inside `CI required` and votes" commitment is honored unchanged, not restated. **GREEN-07 remains uncloseable through this lane** until the successor round lands and is confirmed on a real measured CI run, in the same disciplined, no-weakening, red-then-green manner 198-17 used. **This is a genuine, evidence-backed deferral, not a definitional closure — GREEN-07 is NOT marked Complete by this decision.** The 28-failure fix is out of plan 198-20's and plan 198-21's scope: diagnosing and fixing 28 unrelated failures across 14 files exceeds a single executor's context budget and requires its own dedicated planning round; 198-21 must not attempt it. — **Reversibility:** reversible — nothing is removed, narrowed, or weakened; the lane's guarantee is unchanged today and strengthens once the successor round lands.
- **D-41 (`mix verify.example` / appendix Lane C disposition):** **Leave `mix verify.example` running inside the `verify-test` job (`current` lane, emitting `name: Run test suite (current)`), and fix the 8 demo-seed failures in a dedicated successor round.** Maintainer's own words, recorded verbatim: "C1 — Fix the 8 demo-seed failures in a dedicated successor round." This responds to a fact measured by the orchestrator on 2026-08-28, distinct from CI run `33197493051` (that run predates plan 198-19's fix): plan 198-19 landed the `ALTER DATABASE ... SET search_path` statement `ci.yml:235-240` was missing, and `mix verify.example` now produces zero `undefined_table` occurrences on the merged main tree at commit `0c8304ae` — **GREEN-04's originally-named cause is genuinely fixed and measured closed.** But `mix verify.example` still exits 1 with 8 failures / 109 tests (14 hits in `demo_contract_test.exs`, 5 in `walkthrough_happy_path_test.exs`, 3 in `walkthrough_evidence_test.exs` — pre-existing demo-seed content mismatches deferred since Phase 177, per `deferred-items.md` Plan 198-12 entry), and `.github/workflows/ci.yml:251` runs `mix verify.example` with `if: matrix.lane == 'current'` inside the very `verify-test` job that emits the required check `Run test suite (current)`. **Consequence, stated plainly: `Run test suite (current)` is expected to conclude FAILURE on plan 198-22's measured CI run for this reason, even though the originally-named search_path cause is closed — the check is red for a newly-identified, different reason, and that distinction must not be conflated.** Under this choice, `CI required` keeps guaranteeing exactly what it always has for this check — a green PR proves both the root-repo test suite and the example app's demo-seed/walkthrough content are consistent — and gives up nothing. **GREEN-04 remains uncloseable** until the successor round fixes the 8 failures and a real CI run confirms it; **GREEN-04 is NOT marked Complete by this decision.** This fix is out of plan 198-20's and plan 198-21's scope, exactly as the Lane B fix is: 198-21 must not attempt it. — **Reversibility:** reversible — nothing is removed, narrowed, or weakened; the check's guarantee is unchanged today and strengthens once the successor round lands.
- **D-42 (standing interlock, applies to any future `needs:` change):** Any future change to `ci-required`'s `needs:` list — removing or adding a lane — must be reconciled **in the same diff** against `.github/rulesets/main.json` and the `## CI Coverage` table in `CONTRIBUTING.md` (with its derive-from-source contract test), because `.github/rulesets/main.json` names only the single aggregate context `CI required` and therefore cannot itself detect a narrowing of what that aggregate asserts — a `needs:`-only edit is invisible at the protection layer by construction. This is recorded as a standing constraint from `.planning/audits/198-ci-required-aggregate-decision.md`'s Task 1 analysis, independent of and not resolved by the specific D-39/D-40/D-41 choices above (none of which change `needs:` today). — **Reversibility:** not applicable — this is a process constraint on future changes, not a state that is itself reversed or not.

### Claude's Discretion

- Exact `timeout-minutes` values within the D-16 budget, once p95s are observable.
- Whether the shard fallback (D-15 step 5) is needed, judged against the measured post-surgery wall clock.
- The precise wording of the stale-DB tripwire message and the `@ui_form_policy` failure messages, subject to D-03/D-07's stated requirements.
- `198-TRIAGE.md` table formatting, provided the four columns and the zero-exclusions assertion from D-05 are present.
- Number of plans (roadmap estimates 5: measurement sweep · red-baseline retirement · CI cost surgery · staging-PR bringup · triage).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone & phase authority
- `.planning/ROADMAP.md` §"Phase 198: Green Bringup" — goal, success criteria, carried notes, dependency spine, cross-cutting invariants
- `.planning/REQUIREMENTS.md` §"Green Bringup" — GREEN-01..GREEN-12 verbatim; §"Out of Scope"; §"Traceability" (explains why GREEN-02/03 and GREEN-09/10 live in 198)
- `.planning/PROJECT.md` — project state and milestone framing
- `.planning/STATE.md` — session/progress state

### Engineering standards (binding on every decision above)
- `prompts/threadline-elixir-oss-dna.md` — named `mix verify.*` / `mix ci.*` entrypoints, honest default tests, stable CI job `id:`s, path-filters-plus-main, doc contract tests
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — §329 "do not use one gigantic matrix as required status"; §167 "keep branch protection tied to a smaller required matrix"
- `prompts/prior-art/oss-deep-research/elixir-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/ecto-best-practices-deep-research.md`
- `CLAUDE.md` — three-layer architecture, domain language, verification entrypoints, CI conventions, `gsd-sdk` positional-args gotcha

### Files this phase modifies or reads (verified to exist)
- `.github/workflows/ci.yml` — `:9-10` triggers, `:22-24` concurrency, `:35-36` setup-beam pins, `:42` cache key, `:99-162` verify-test + matrix, `:100-106` the matrix-name assertion, `:108` fail-fast, `:220-278` browser job, `:265` Playwright cache key, `:287` mechanical, `:316` Tier-A capture, `:374-375` example-app `ALTER DATABASE`, `:390-399` byte-stable evidence, `:573` verify-release-shape
- `.github/workflows/release.yml` — `:13-27` workflow_dispatch + dry_run, `:96` RELEASE_PLEASE_TOKEN, `:104` prs_created gate, `:112` dispatch, `:221-234` gate-ci-green, `:276-281` needs, `:308` version↔tag, `:319-323` verify-release-shape + hex.build, `:326-333` idempotency, `:362` post-publish verify
- `.github/workflows/hex-publish.yml` — `:1-3` "Legacy fallback", `:7-10` tag trigger, `:17` job name, `:52-61` ungated publish → **DELETE**
- `.github/workflows/ui-critic.yml` — `:14-21` push trigger, `:22-32` score input, `:48` ANTHROPIC_API_KEY, `:103-113` paid runner → **DELETE**
- `.github/workflows/flake-detection.yml` — `:20` job name
- `examples/threadline_phoenix/e2e/playwright.config.ts` — `:16-18` the three unscoped projects, `:122` timeout, `:123` snapshotPathTemplate, `:125` retries, `:126` workers, `:140` trace
- `examples/threadline_phoenix/e2e/run-e2e.sh` — boot preflight, browser install fallback
- `mix.exs` — `:88-90` verify.doc_contract, `:111` verify.ui_critique, `:158` verify.release, `:247-267` ui_critique impl, `:323-324` `package.files`
- `test/test_helper.exs` — `:13` storage_up, `:39` topology guard (tripwire insertion point)
- `test/support/storage_schema_case.ex` — `prepare_dual_storage!/1`
- `test/threadline/storage_schema_prefix_contract_test.exs` — `:31` refutes `@schema_prefix`
- `test/threadline/version_truth_doc_contract_test.exs` — `:24-45` derive-from-SSOT idiom, `:59` non-empty glob assertion
- `test/threadline/v1_23_charter_doc_contract_test.exs` — `:18` the single deterministic failure → **`git rm`**
- `test/threadline/ci_topology_contract_test.exs` — home for the D-25 assertions
- `test/**/formless_pages_test.exs` — `:47-54` the non-exhaustive allowlist → replace per D-07
- `bin/verify-release-shape` — sibling pattern for `bin/verify-branch-protection`
- `priv/repo/migrations/20260607000000_threadline_storage_schema_default.exs` — the migration the stale local DB predates
- `lib/mix/tasks/critic.measure.ex`, `lib/mix/tasks/critic.synth.ex` — ship today; `@moduledoc false` is **Phase 200's** job, not 198's

### External references consulted
- `re-actors/alls-green` — `if: always()` is mandatory; skipped required checks score as pass
- GitHub community discussions #26733 (require-all-without-enumerating), #60792 (conditional jobs + matrix deadlock), #26822
- Playwright docs — `--shard`, `blob` reporter + `merge-reports`, `--max-failures`, file-level shard granularity without `fullyParallel`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`test/threadline/ci_topology_contract_test.exs`** — already wired into `verify.release` (`mix.exs:158`). The D-25 resurrection guards (one publish path, zero ANTHROPIC refs) belong here; no new harness needed.
- **`test/threadline/version_truth_doc_contract_test.exs:24-45`** — the proven derive-from-SSOT idiom. Every D-06 shape-assertion rewrite copies this, including the `:59` non-empty-glob assertion that prevents vacuous passes.
- **`bin/verify-release-shape`** (`ci.yml:573`) — the established "committed script as a gate" pattern. `bin/verify-branch-protection` (D-12) is its sibling.
- **`mix verify.doc_contract`** (`mix.exs:88-90`) — the doc-contract idiom that makes D-23's CI Coverage table self-guarding. (Note: Phase 204 plans to *delete* this alias as redundant — D-23's test should be a plain `*_contract_test.exs` picked up by `mix test`, not a new `verify.*` step, so it survives that deletion.)
- **`e2e/run-e2e.sh`** — already implements the correct systemic-break preflight (120×1s poll, `tail -80` on failure). D-18 extends rather than replaces it.
- **`test/support/storage_schema_case.ex`** — `prepare_dual_storage!/1` is why the suite is fresh-DB green; it is the Go-style hermeticity the tripwire protects.
- **`release.yml`'s five pre-publish gates** — already correct and complete. GREEN-10 is a deletion, not a construction.

### Established Patterns
- **Named `mix verify.*` / `mix ci.*` entrypoints** are the only things CI and docs may cite verbatim. Any new gate gets an alias, not an ad-hoc command.
- **Stable CI job `id:`s, free `name:`s** — but note the sharp edge: GitHub matches required checks on **name**, not id. D-17's "keep both byte-identical" exists for this reason.
- **Ratchet-down-only ceilings** (the MODE-B floors idiom) — the pattern Phase 199's dialyzer ignore ceiling will reuse; D-19's cache-key work must not need redoing then.
- **Register rows with owner + reopen-trigger** (the 193 R-D / 197 design-debt pattern) — the honest way to carry deferred debt.
- **Contract tests over comments** — the repo consistently enforces conventions with executable assertions. D-25 follows it.

### Integration Points
- The aggregate gate (D-08) `needs:` every current `verify-*` job and must be extended by Phases 199 (dialyzer), 203 (real credo), and 204 (CSS hash). Its `needs:` list becomes the durable job-id contract — extend the `ci.yml:1-2` header comment to name `ci-required`.
- D-19's cache keys are the slot Phase 199's PLT cache drops into (`otp` + `mix.exs` in the key).
- The `198-TRIAGE.md`, `.planning/audits/`, and `.planning/ARCHIVE-REGISTER.md` artifacts are new tracked planning outputs — note that Phase 199 (DECOUPLE-01) requires `mix ci.all` to pass with `.planning/` renamed away, so **no gate may read any of them**.

</code_context>

<specifics>
## Specific Ideas

- **"A test, not a comment."** Every guard in this phase is executable: the publish-path singleton, the zero-ANTHROPIC assertion, the zero-skips assertion, the branch-protection diff, the CI-coverage doc contract. This phase's output is gates, and a gate that is prose is not a gate — the same critique this milestone levels at the vacuous `.credo.exs`.
- **The meta-standard.** Threadline is an audit library. Its own record-keeping should model the honesty it sells: the archive register, the triage artifact with its zero-exclusions cap, the honest admission when coverage is dropped (D-06), and the published `.planning/` history (D-30) are all instances of the product thesis applied to the repo.
- **Anti-laundering is the point of D-05.** A triage taxonomy launders if "environmental" and "obsolete" are unfalsifiable. Both are bound: environmental must fix the *setup path*, obsolete must name a successor guard or explicitly admit lost coverage, and the exclusion count is mechanically asserted to be zero.
- **Prove new assertions have teeth.** Any rewritten shape assertion must be demonstrated **failing** against a deliberately drifted SSOT before commit. A shape assertion so loose it asserts nothing is worse than the rotting literal it replaced.
- **Failing fast ≠ diagnosing fast.** `--max-failures=5` (not `-x`) plus retained traces, because the maintainer must still learn *why* it broke.

</specifics>

<deferred>
## Deferred Ideas

- **`.planning/milestone.lock`** — stale untracked artifact from a dead session (pid 62757, `"phase": "null"`) dirtying `git status`. Belongs to **Phase 199 / DECOUPLE-05** ("a fresh clone plus `mix deps.get` leaves `git status` clean"). Either ignore it or have the SDK clean it up.
- **`@moduledoc false` on `lib/mix/tasks/critic.measure.ex` and `critic.synth.ex`** — they ship in the tarball and appear on HexDocs today. Adopter-visible noise, but **not** a billing path (no `ANTHROPIC` reference exists under `lib/`). Already scoped to **Phase 200 / SURFACE-03**.
- **Example-app `ALTER DATABASE … SET search_path` at `ci.yml:374-375`** — a real wart, caused by `demo.seed` issuing unqualified queries. Fixing it means changing seeded page content, which would force Tier-A `page.*` scorecard regeneration — **forbidden this milestone**. Carry as a **register row** with owner and reopen-trigger (the 193 R-D pattern); revisit when the recapture constraint lifts.
- **Two duplicated `~> 0.9.0` literals** at `getting_started_saas_doc_contract_test.exs:33` and `operator_surface_doc_contract_test.exs:58` — redundant with `version_truth_doc_contract_test.exs`'s `@expected_pin_version` and will go red at 0.10.0. Folding them into the derived guard is clean but deletes two named tests. Natural home: **Phase 202 / RELEASE-02** (version-literal wiring).
- **Does "milestone tags stay local" survive Phase 198?** Its stated rationale (pushing would publish `.planning/` history) is void once `.planning/` is public on `origin/main`. D-32 settles *archive* tags (pushed); the milestone-tag convention needs retiring or restating — **milestone-close decision, not 198**.
- **Hex trusted publishing / OIDC migration** — not GA in 2026. D-27 keeps `HEX_API_KEY` behind an Environment reviewer gate and structures the auth step as one swappable block. Revisit when Hex ships it.
- **`stress_live.ex` classification** — it sits in `lib/threadline/operator_surface/live/` and will be swept into D-07's derived roster. If it is a dev harness rather than a shipped page it should declare `{:has_forms, "stress harness"}` or move out of `live/`. Resolve inside D-07's implementation; note if it turns out to want a real relocation (that would be Phase 204 structure work).
- **Snapshot-baseline check before deleting the `chromium` project (D-15).** `playwright.config.ts:123` includes `{projectName}` in `snapshotPathTemplate`, so deleting the project orphans any `-chromium` baselines. Verify no test depends on its 1280×720 viewport before removing — an execution-time preflight, not a separate phase.

</deferred>

---

*Phase: 198-Green Bringup*
*Context gathered: 2026-08-27*
