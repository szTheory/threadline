# Phase 220: Newest-Toolchain Lane - Context

**Gathered:** 2026-09-28
**Status:** Ready for planning
**Method:** research-then-recommend (3 parallel researchers). The maintainer accepted the whole recommended set, plus the HIGH-IMPACT spend pick "every run, trim in 222".

<domain>
## Phase Boundary

LANE-01. The phase proves the suite on the newest stable toolchain before any adopter hits it. The toolchain is Elixir 1.20.x / OTP 29.x / PostgreSQL 18, exactly pinned, under `--warnings-as-errors`.

There are two acceptable outcomes:
- **Green:** a voting `lane: latest` row in `verify-test`, with its roster, parity and doc changes in the same commit.
- **Not green:** a "not yet" findings record that names the specific failures.

Either way, a fail-closed contract test must prove two things:
- no voting lane uses `continue-on-error`;
- no lane uses a beta PostgreSQL image.

The lane is additive. `.tool-versions` (1.17.3 / 27.3.4.15, current lane) and the declared floor (1.15.8 / 26.2.5.21 / PG 14, min lane) stay unchanged, per PROJECT.md Out of Scope around line 667.

</domain>

<decisions>
## Implementation Decisions

### Pins
- **D-01: Exact pins:**
  - `elixir: "1.20.4"`, the newest stable, 2026-08-28. Elixir 1.20.0 went final on 2026-06-03.
  - `otp: "29.1.1"`, the newest, 2026-09-22.
  - `pg: "18.6"`, the newest minor, 2026-08-13. `18.5` was never released and has no Docker tag.
  - `runner: "ubuntu-24.04"`, with `version-type: strict`.
  - Sources: builds.hex.pm lists `v1.20.4-otp-29` and `OTP-29.1.1` for ubuntu-24.04, and Docker Hub carries `postgres:18.6`.
  - The planner/executor re-checks these sources at execution time. If a newer patch has shipped by then, pin the newest and record the change. Do not type guessed versions.
- **D-02: PG pinning uses the version tag `18.6`, not a digest.** The other rows use `14` and `16`. The contract allowlist accepts both styles (see D-16).
  - Tradeoff: `postgres:18.6` can be re-pushed when its Debian base is rebuilt. This is accepted, because a digest pin means manual churn.

### Lane shape
- **D-03: Add a third row on the base axis: `lane: [min, current, latest]`.**
  - The `include` row carries `elixir`/`otp`/`pg`/`runner` only. That way GitHub posts exactly "Run test suite (latest)" (construction A, `ci.yml:316-340`).
  - The row sets explicit `otp`/`elixir` pins and no `version-file`, like the min row.
  - Keep the `lane: latest` spacing. The existing `:latest` substring ban around contract test line 205 depends on the space after the colon.
- **D-04: No branch-protection or ruleset edit.**
  - `verify-test` is already in `ci-required.needs`, and alls-green scores the whole matrix. So the latest row votes automatically.
  - `bin/verify-branch-protection` expects exactly one required context, `CI required`. Do not add the new check name to `.github/rulesets/main.json`.
  - `fail-fast: false` already keeps latest from cancelling min or current.
- **D-05: Payload is min-like:** `mix compile --warnings-as-errors`, `mix verify.xref_cycles`, `mix verify.test`.
  - No example app, no `verify.threadline`, no Dialyzer on latest.
  - The existing `if: matrix.lane == 'current'` guards (around `ci.yml:429-488`) already scope those steps to current.
  - Test-file warnings stay non-fatal, for parity with the other lanes: `verify.test` is plain `mix test`. State this in the findings and docs; do not widen it here.
- **D-06: Latest caches, using Phase 219's key shape unchanged.**
  - The root `_build` and deps keys already carry `matrix.runner` plus the resolved OTP and Elixir versions, so latest gets its own non-colliding key.
  - No `build_cache_errors/2` rule changes are needed.
  - 219 D-11's "3 keys / 5 job-lanes" becomes **4 keys / 6 job-lanes**. Update the prose: contract test reason around line 441 ("both lanes"), CONTRIBUTING around line 753 ("root on both lanes" → "every lane"), and the `ci.yml` cache comment around lines 381-388.

### Spend (HIGH-IMPACT, maintainer-decided)
- **D-07: Latest runs and votes on every `ci.yml` run: PRs, pushes to main, and dispatch.** — **Reversibility:** reversible — it is one matrix row; Phase 222 trims it.
  - Expected cost is about +6 billed runner-minutes per run (warm p50 about 49 → about 55), about +40 s more on a cold miss. This exceeds 219's saving. Wall clock is unchanged, because the critical path is still Browser E2E at about 550 s.
  - Record the cost honestly in the phase record. Do **not** add a conditional `if:` now; it would also need `allowed-skips`.
  - Phase 222 (SEED-006 change-aware lanes) is where it gets trimmed.

### Pre-spike remediation (known failures)
- **D-08: Fix the 6 known compile warnings before the paid spike.**
  - A researcher found them with a local compile on Elixir 1.20.2 / OTP 29.0.5 against a scratch copy outside the repo.
  - All are dead code or cleanup, with no behaviour change:
    1. an unused `require Logger` in `lib/mix/tasks/threadline.incident.ex:38`;
    2. an unused `require Logger` in `test/support/migration_harness.ex:16`;
    3. bitstring `size(open)` wants a pin in `lib/threadline/critic_trust/ledger_splice.ex:85`. `size(^open)` does not compile on the 1.15.8 floor, so restructure it version-neutrally, e.g. with `binary_part/3`. No `Version.match?` branching.
    4. a never-matching `timeline_search_path/2` clause in `lib/threadline/operator_surface/live/export_status_live/components.ex:173`;
    5. a never-matching `maybe_put(_, _, nil)` clause in `lib/threadline/operator_surface/live/evidence_live.ex:438`;
    6. a condition that always succeeds, `@has_ever_acted and …`, in `lib/threadline/operator_surface/live/actor_live.ex:233`.
  - Each fix must stay green on the min lane, 1.15.8 / 26.2.5.21, which the same CI run proves.
- **D-09: A local pre-spike runs before any paid dispatch.**
  - Compile under `--warnings-as-errors` on the exact D-01 pins, and run the suite against a local `postgres:18.6` container.
  - Locally installed now: asdf `elixir 1.20.2-otp-29` and `erlang 29.0.5`, and Docker 29.5.2 with no PG18 image pulled yet.
  - Install 1.20.4 / 29.1.1 if feasible. Otherwise state which versions ran.
  - Mind the shared local PG (too_many_connections is environmental). Use a dedicated container port.

### Spike vehicle and landing
- **D-10: The spike is the real landing commit.**
  - Cut a throwaway branch `spike/220-latest` from `land/v1.43-217-218` HEAD.
  - One commit carries the latest row, the roster and parity contract updates (D-13/D-14), the D-15/D-16 contract tests and the D-17 docs. The D-08 fixes may be a separate preceding commit.
  - Push it, then run `gh workflow run ci.yml --ref spike/220-latest` and cite the run ID. This works because `ci.yml` is on the default branch with `workflow_dispatch`, and it has been dispatched against non-default refs before (e.g. 36457705448).
  - Rejected alternatives:
    - a standalone spike workflow, which can't be dispatched because it is not on main;
    - a new `workflow_dispatch` input on `ci.yml`, which adds permanent surface on the release-bootstrap path;
    - pushing straight to PR #60, which would put a possibly red required check on the landing PR.
  - If green, cherry-pick onto `land/v1.43-217-218` / PR #60.
  - **Push, each dispatch, and the cherry-pick push need an explicit maintainer grant naming the branch** (a `checkpoint:human-action` in the plan). Dispatch sequentially: the concurrency group allows one pending run per ref.
- **D-11: What green means, and where retries stop.**
  - Green: the latest row passes compile `--warnings-as-errors`, `verify.xref_cycles` and `verify.test` in the cited run, **and** min and current are green in that same run.
  - A red latest gets one flake re-dispatch. A failure that doesn't reproduce, in a test with flake history, is a flake. Read the recent Flake Detection classifications first (runs 36391367194, 36359135268).
  - Any compile or warning failure, or any failure that reproduces, counts against the toolchain.
  - At most one fix-and-re-spike cycle, so at most 2 spike dispatches plus 1 flake re-dispatch.
  - **Out of scope; record "not yet":**
    - any `mix.lock` change or dependency bump;
    - a dependency compile error on OTP 29 (dependency *warnings* do not fail the root app, e.g. yamerl and sweet_xml);
    - any fix needing version-conditional code or a behaviour change;
    - a second failed cycle.
- **D-12: Where "not yet" is recorded:**
  - `220-FINDINGS.md`: run IDs, the pinned versions, each failure verbatim (file:line, warning or error class), each tagged ours or dependency;
  - a one-line PROJECT.md Key Decisions row;
  - a seed for v1.44/v1.45 next to the floor-raise decision.
  - Re-triggers: the next Elixir 1.20.x or OTP 29.x patch, a dependency release that fixes the named failure, or else re-evaluate at milestone close.
  - LANE-01 is satisfied by either outcome.

### Contract tests (`test/threadline/ci_workflow_parity_contract_test.exs`)
- **D-13: Roster changes:**
  - the regex around line 244 becomes `[min, current, latest]`;
  - the row-count check around lines 1302-1309 becomes 3 rows with keys `["current","latest","min"]`;
  - the control around line 284, "a third matrix row", becomes "a fourth";
  - the doc assertion around lines 374-378 also requires "Run test suite (latest)".
- **D-14: New `latest_row_errors/2`, fed the `.tool-versions` text.** It checks the pins' **shape and ordering, not literal values**; min's literal pins encode a support promise, and latest's do not.
  - explicit `otp`/`elixir` and no `version-file`;
  - runner `ubuntu-24.04`;
  - OTP matches `^\d+\.\d+(\.\d+){0,2}$`, Elixir matches `^\d+\.\d+\.\d+$` (no `x`, `-rc`, `-otp`);
  - pg matches `^\d+(\.\d+)?$`;
  - OTP major, Elixir version and pg major are each strictly newer than the current row.
  - Mutation controls, each asserting its specific error fragment:
    - `version-file` added;
    - `otp: "29"`;
    - `elixir: "1.20.0-rc.1"`;
    - `pg: "16"`, which is not newer;
    - runner `22.04`.
- **D-15: Criterion 3a: no `continue-on-error` on a voting lane. Fail closed:**
  - assert `ci-required.needs` equals every `ci.yml` job key except `ci-required` itself, so every job votes;
  - reject `continue-on-error:` at job or step level in any comment-stripped job block, including `${{ matrix.* }}` forms;
  - reject `allowed-failures` in `ci-required`, an equivalent bypass.
  - There are zero occurrences today.
  - Controls: job-level in `verify-test`; step-level on "Run tests"; the matrix-expression form; `allowed-failures:` in `ci-required`; and a positive control where a comment mentioning the word stays green.
- **D-16: Criterion 3b: no beta PostgreSQL. Allowlist, not denylist:**
  - Scan every `postgres:<tag>` image across all `workflow_files()` plus `docker-compose.yml`.
  - Resolve `${{ matrix.pg }}` through the parsed `include` rows. An unresolvable expression is an error.
  - Each tag must match `^\d+(\.\d+)?$`, which fails closed on `19beta1`, `18rc1`, `devel`, `nightly` and `latest`.
  - Controls: `pg: "19beta1"` in the latest row, `postgres:18rc1` in `browser-full.yml`, `postgres:devel` in `release.yml`.

### Docs (same commit as the row)
- **D-17: Same-commit doc surfaces:**
  - `ci.yml`: the verify-test header comment, around lines 316-325 ("exactly … (min) and … (current)"), and the cache comment around lines 381-388;
  - CONTRIBUTING:
    - the required-check list around lines 877-878, adding "Run test suite (latest)";
    - the build-cache table around line 753;
    - the "min and current lanes" text around lines 659-660;
    - the toolchain section around lines 23-37, with a latest-lane note;
  - the `README.md:102` support statement: **tested on**, explicitly **not a new support floor**;
  - the `mix.exs` support-contract comment around lines 38-41.
- **D-18: Pin upkeep is process, not automation.** Add a MILESTONE-GUIDE checklist line: "re-pin latest to the newest Elixir/OTP patch and PG minor". Dependabot does not cover setup-beam versions.

### Claude's Discretion
- The exact `binary_part` restructure for `ledger_splice.ex`, and whether the D-08 fixes land as one commit or several.
- Whether the local pre-spike installs 1.20.4 / 29.1.1 or runs on the installed 1.20.2 / 29.0.5 and says so.
- Whether to extend `219-deps-only-build-cache/tools/remeasure-219.py` (it knows only min and current) to measure latest's actual cost from the spike runs. This is nice-to-have; the cost estimate in D-07 is an inference to be confirmed, not asserted.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contract
- `.planning/ROADMAP.md`, Phase 220: goal, 3 success criteria, and the research flag.
- `.planning/REQUIREMENTS.md`, LANE-01 (around line 99).
- `.planning/PROJECT.md`, around line 667: Out of Scope. Floor and current lane are not silently bumped; the additive newest lane is in scope after a spike.
- `.planning/MILESTONE-GUIDE.txt`, around line 199: "One lane on the newest PostgreSQL/Elixir".

### CI and contracts
- `.github/workflows/ci.yml`: header job-id contract and `ci-required` extension point (lines 1-30), `verify-test` (around 314-500), and the `ci-required` aggregator with its `allowed-skips` note (around 1070-1100).
- `test/threadline/ci_workflow_parity_contract_test.exs`: roster tests around 238-302 and 1298-1360, `build_cache_errors/2` and its controls, `workflow_files()`, and the `:latest` ban around 205.
- `.github/rulesets/main.json` and `bin/verify-branch-protection`: `CI required` stays the single required context.
- `CONTRIBUTING.md`: toolchain around 23-37, lanes around 659-660, cache table around 753, required checks around 870-885.
- `README.md:102`: support statement.
- `mix.exs`: around 38-41 (support comment) and around 140 (`verify.test` alias).

### Prior phase decisions
- `.planning/phases/219-deps-only-build-cache/219-CONTEXT.md`: D-01..D-26 (key shape, D-11 coverage, D-14/D-15 save policy with no `continue-on-error`, D-20/D-21 contract style and mutation controls).
- `.planning/phases/219-deps-only-build-cache/219-REMEASURE.md`: per-lane costs (the min lane's warm p50 of 341 s is the latest-lane estimate).
- `.planning/phases/218-ci-economy-remove-waste/`: landing deviations and the land-branch cherry-pick precedent.

### External (verify at execution)
- https://builds.hex.pm/builds/elixir/builds.txt: Elixir 1.20.x builds (`v1.20.4-otp-29`).
- https://builds.hex.pm/builds/otp/ubuntu-24.04/builds.txt: OTP 29.x prebuilt for ubuntu-24.04.
- https://www.postgresql.org/docs/release/18.6/ and Docker Hub `postgres` tags.
- https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows: the `workflow_dispatch` rule behind D-10.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The `min_row_errors/2` and `current_row_errors/1` pattern in the parity contract is the template for `latest_row_errors/2`.
- The `{label, mutated}` + `refute mutated == yaml` mutation-control pattern, and `strip_comment_lines`, are used throughout the contract test.
- The Phase 219 key shape: resolved `steps.beam.outputs.otp-version` and `elixir-version` in every root and deps key.

### Established Patterns
- Construction A: only the base `lane` axis appends to the check name, and `include`-only keys do not.
- Each matrix row sets exactly one toolchain source: explicit pins, or `version-file`. setup-beam errors when both are set.
- Fail-closed allowlists over denylists, with each mutation control asserting its specific error fragment (219 D-21).
- Landing goes through cherry-picks onto `land/v1.43-217-218` / PR #60.

### Integration Points
- The `verify-test` matrix in `ci.yml`, the parity contract test, and the doc surfaces in D-17.
- The `lib/` files named in D-08.

</code_context>

<specifics>
## Specific Ideas

- Prior art: every surveyed lib runs a voting newest lane, and none use allow-failure. Phoenix pins exactly (1.20.4 / 29.0.5); Oban and Req float and go red when upstream ships a release; Ecto and Broadway are still on 1.19 / 28. Threadline follows the strict ones: voting plus exact pins.
- The OTP 28+ regex (PCRE2) risk for `@attr ~r/…/` module attributes did **not** materialise on 1.20.2 / 29.0.5 (e.g. `storage_schema.ex:23`, `coverage_schemas.ex:6`, `row_key.ex:337`).
- **Research flag for plan-phase:** PostgreSQL 18 reportedly runs AFTER triggers as the role active when the event was queued, rather than the role at commit.
  - A researcher reported this without verifying it.
  - The phase researcher must verify it against the PG 18 release notes, then check whether the capture trigger functions read `current_user` or `session_user`.
  - Also check whether any test schema uses generated columns: PG 18 makes virtual the default, and virtual columns are not stored, which could affect `to_jsonb(NEW)`.
- Not yet exercised on 1.20: test-file compile warnings (non-fatal by D-05, but likely present), runtime on PG 18, and the example app (out of payload by D-05).

</specifics>

<deferred>
## Deferred Ideas

- `mix test --warnings-as-errors` across all lanes, making test-file warnings fatal. This is a separate hardening decision that needs every lane to change together.
- A `deps-health.yml` job that compares builds.hex.pm's newest Elixir/OTP and Docker's newest PG minor against the latest-lane pins and opens an issue when they drift. D-18's process line covers this for now.
- Running the example app, `verify.threadline` or Dialyzer on the latest toolchain.
- Trimming latest's cost with change-aware lanes: Phase 222 (SEED-006).
- Retiring CONTRIBUTING's historical required-check list, since `CI required` is the only required context: Phase 221 (names/order).

### Reviewed Todos (not folded)
- `2026-09-28-ci-suite-sync-bound-parallelism.md` ("Cut CI wall clock by making the test suite less sync-bound"): about 91% of the suite runs synchronously. This is CI wall-clock and serial-core work, not the newest-toolchain lane. It belongs with 221/222 or the next milestone.

</deferred>

---

*Phase: 220-newest-toolchain-lane*
