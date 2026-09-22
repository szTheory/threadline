# Contributing to Threadline

Thanks for helping improve Threadline. You can contribute without access to
maintainer credentials or the project's internal planning history.

## Communication

Choose the route that matches the change:

- Small bug fixes and documentation corrections may go directly to a pull
  request.
- Please discuss large behavior changes or public API changes in a
  [feature request](https://github.com/szTheory/threadline/issues/new/choose)
  before investing in an implementation.
- Use the same issue chooser for reproducible bugs and questions. Report
  suspected security vulnerabilities through the repository's
  [private security policy](https://github.com/szTheory/threadline/security/policy), never in a public issue.

## Setup

**Requirements:**

- Elixir 1.15+ (CI uses 1.17.3)
- OTP 26+ (CI uses OTP 27.0)
- PostgreSQL 14+ (PostgreSQL 16 recommended; matches CI and `docker-compose.yml`)
- Node.js 22 — only for the browser end-to-end lane, which is the last step of
  the full verification gate described under Running tests below. Everything
  else, including the whole library test suite, runs without it.

If you manage toolchains with a version manager such as asdf or mise, note that
this repository intentionally does **not** commit a `.tool-versions` file. It
supports a range of Elixir versions rather than a single one, and committing a
pin would turn "Elixir 1.15 and up works" into "install exactly the version this
file names" — which would break contributors on versions the project genuinely
supports and tests.

A fresh clone therefore inherits whatever versions you already have set. If your
version manager has none set at all, `mix` fails with something like `No version
is set for command mix`, which names your version manager rather than this
project and is an easy trail to lose. Set one yourself, globally or in a local
`.tool-versions` you leave uncommitted. To match the lane CI runs, use Elixir
1.17.3 with the matching OTP 27 build and Node.js 22.

1. Clone the repository.
2. Install dependencies: `mix deps.get`
3. Start a local PostgreSQL test database by following
   [Run the test database](guides/local-docker-dx.md#run-the-test-database).

The Docker guide owns lifecycle commands, port overrides, multi-checkout
isolation, and cleanup. The test helper creates `threadline_test` when it is
missing, so no manual `createdb` step is required.

## Running tests

```bash
mix test test/path.exs   # single file
mix verify.test          # full suite (needs PostgreSQL)
```

Integration tests use a **real** database and triggers; they are not excluded from `mix test`.

**Environment:** `DB_HOST` defaults to `localhost`; **`DB_PORT`** defaults to `5432` (see `config/test.exs`). Override if Postgres listens on another port (e.g. **`DB_PORT=5433`** with the default `docker-compose.yml` mapping).

## Run `mix ci.all`

Before submitting, run the repository's complete local gate:

```bash
mix ci.all
```

This repository alias runs formatting, Credo, strict compiles, tests, trigger
coverage, documentation contracts, and Dialyzer in the test environment. If
your local database uses a non-default port, set `DB_PORT` for the command as
described in the [local database guide](guides/local-docker-dx.md#run-the-test-database).

### Troubleshooting a missing audit table

If a repository or example-app command fails with
`(undefined_table) relation "audit_changes" does not exist`, the local database
schema does not match the checkout: the Threadline migrations have not run
against that database, or an older Compose volume is still in use. Follow the
[local database reset and stale-state troubleshooting](guides/local-docker-dx.md#troubleshooting)
for the canonical repair. Keep the lifecycle and cleanup commands in that guide
so its volume-deletion warning stays attached to the procedure.

## Pull requests

1. Fork the repository and create a branch from `main`.
2. Make the focused change and add or update tests when behavior changes.
3. Run the relevant focused tests, then `mix ci.all`.
4. Open a pull request against `main` and explain why the change is useful,
   what changed, and how you verified it. An issue is not required for a small
   fix.

The sections below are reference material for specialized tests and maintainer
work. They are not prerequisites for an ordinary contribution.

## Deterministic tests (no flakes)

Tests must be deterministic — a green run must mean the code is correct, not that
the dice landed well. Re-running a flaky test to get green hides real races and,
as we learned, can block a release.

**Test model.** This suite does **not** use Ecto's SQL Sandbox (audit triggers
and `SET LOCAL` GUCs operate at the DB level, outside sandbox awareness).
The repository's data-case helper is therefore `async: false` and cleans audit
tables in `setup` (FK order). Keep DB-touching tests on that helper.

**Rules of thumb:**

- **Never `Process.sleep` to wait for a condition.** Use
  `assert_eventually/2` (from the async test helpers, imported by the data case) —
  it polls against a real deadline, robust on slow CI without being racy.
- **Drain GenServers deterministically.** Use `drain_mailbox/1` (two
  `:sys.get_state` round-trips) instead of sleeping after a `cast`/`send`.
- **Advisory locks: hold them on a dedicated session.** Use
  `with_advisory_lock_held/3`, not the repo pool — a pooled lock-holder races
  with the code under test on pool allocation.
- **Stop singletons in `setup`.** For globally named Threadline workers, call
  `stop_named_process!/1` so a previous test can't leak work into the next.
- **Telemetry tests are `async: false`.** `:telemetry` handlers are
  process-global; an `async: true` module that attaches a handler will receive
  events emitted by *any* concurrently-running test for the same event name.
- **Don't assert on unordered query results positionally.** Add an explicit
  `order_by` when a test depends on row order.

**Reproduce / prove determinism.** Run a test (or the suite) repeatedly:

```bash
mix test test/path/to/flaky_test.exs --repeat-until-failure 200
mix test --seed 0 --repeat-until-failure 20   # pin a specific ordering
mix verify.flake                              # full suite, 50 repeats (fresh seed each)
```

`mix verify.flake` is also run nightly (and on demand) by the **Flake Detection**
workflow ([`.github/workflows/flake-detection.yml`](.github/workflows/flake-detection.yml));
it is intentionally kept out of `mix ci.all` so per-PR CI stays fast.

## Local-only critic (verify.ui_critique)

`mix verify.ui_critique` runs the adversarial critic runner against the
operator-surface scorecard cells. It calls an external AI API and is therefore
**local-only** — it requires an API key set in the environment (`ANTHROPIC_API_KEY`)
and is **excluded from `ci.all`** (same precedent as `verify.flake`).

```bash
ANTHROPIC_API_KEY="sk-ant-..." mix verify.ui_critique
```

When `ANTHROPIC_API_KEY` is absent or empty, `mix verify.ui_critique` exits 0
with a skip message. Contributors and CI without a key are completely unaffected.

The companion gate **`mix verify.critic_trust`** is pure-Elixir (no network, no
AI), runs in `ci.all` before `verify.mechanical`, and asserts that every validated
critic lens meets its statistical trust bar — **Spearman ρ ≥ 0.70** (rank
correlation of oracle severity vs critic score, the validated ranking signal);
with n ≥ 20. Krippendorff α, AUC, and raw agreement are recorded as reported-only
companions and never gate (the lenses rank well even where their absolute scale is
compressed). All lenses seed as `validated: false` until the trust run promotes
them; the gate passes vacuously on the empty skeleton.

> **Do not commit `ANTHROPIC_API_KEY` values anywhere.** The key is read from
> the environment only; `mix verify.ui_critique` never writes it to files.

## Maintainer: building and validating the golden oracle

This section is **maintainer-only** — it requires `ANTHROPIC_API_KEY` and human judgment.
Contributors do not need to run any of these steps; the `ci.all` gate (`verify.critic_trust`)
runs without an API key and passes vacuously until the maintainer has populated the golden set.

### Prerequisites

- `ANTHROPIC_API_KEY` available in the shell (never committed). Nothing auto-loads
  `.env`, so source it into the shell first — this makes the key reach both `npm` and `mix`:
  ```bash
  set -a; source .env; set +a    # .env holds: export ANTHROPIC_API_KEY='sk-ant-...'
  ```
- Postgres running for `mix ci.all` verification at the end
- All `npm` dependencies installed: `cd examples/threadline_phoenix/e2e && npm install`

### Step 1 — Build the oracle

The critic must be validated against an oracle before its scores may drive the ratchet.
There are two oracles; the **synthetic** one is the default (no human labeling).

#### Step 1a (recommended) — Synthetic twin oracle (labeling-free)

The synthetic oracle is a graded severity ladder of twins (lens × scenario × 4 rungs)
whose verdicts are known *by construction*, so the trust gate reaches n≥20/lens with **zero
labeling**. It proves the critic tracks known-severity flaws monotonically on held-out rungs
(a *calibration* claim), which is sufficient to drive the **forward-only** ratchet. It does
NOT claim taste-agreement on ambiguous UI — that's what Step 1b's human oracle is for.

```bash
mix critic.synth                                   # generate synthetic-set.json from the ladder
cd examples/threadline_phoenix/e2e
npm run capture:graded                             # shoot the graded rung cells (needs dev server)
npm run critic:score -- --synthetic                # score exactly the graded (cell, lens) pairs
cd ../../.. && mix critic.measure --source synthetic  # α + n + raw per lens; writes honest provenance
mix verify.critic_trust                            # gate re-asserts what was recorded
```

#### Step 1b (optional, stronger claim) — Human golden set (blind test-retest)

The `critic label` CLI guides you through the golden-set authoring lane. IDs are masked
behind ephemeral tokens so each round is genuinely blind. Use this when you want a
taste-agreement claim on real UI beyond the synthetic calibration claim.

The images come from two capture lanes (run once, before labeling): `npm run capture:storybook`
emits the real-UI Storybook `story.*` cells, and `npm run capture:refute` re-emits the refute-twin
pole cells clipped to the twin content (both need the dev server — see `e2e/run-e2e.sh`).

```bash
cd examples/threadline_phoenix/e2e

# Seed the labeling queue (clean Storybook story.* cells first, then the refute poles)
npm run critic:label -- --bootstrap

# Label round 1 — RECOMMENDED: the local web page (one always-current clean image at a time;
# opens http://127.0.0.1:4399; g/o/a/x + a few words of evidence; Ctrl+C stops, progress saved)
npm run critic:label -- --round r1 --web

# ...or the keystroke CLI in the terminal (g=good, o=borderline, a=bad, x=broken; evidence required)
npm run critic:label -- --round r1

# Commit r1 BEFORE running r2 (enforces a time gap for honest blind test-retest)
git add test/fixtures/operator_surface/golden/rounds/r1.json
git commit -m "chore: golden set round 1 labels"

# Label round 2 (reshuffled, re-tokenized — never sees r1 content; add --web for the page)
npm run critic:label -- --round r2

# Reconcile: keep r1==r2 agreements; you tiebreak disagreements
npm run critic:label -- --reconcile

# Check progress — target ≥20 per lens for validated status
npm run critic:label -- --status
```

Lenses under the 20-judgment bar stay `provisional` and cannot ratchet. That is acceptable
for this phase; add more cells with `--add <cell-id>` or run `--bootstrap --lens <lens>`.

**Key invariant:** `--reconcile` is the ONLY writer of `golden-set.json`. Never hand-edit it.
Held-out IDs (in `held_out_ids`) are refused at queue time — they are the independent
true-north set and must never be rubric-tuned.

### Step 2 — Prove the critic (refute battery)

The refute battery verifies that the critic can correctly identify sign/attribution on synthetic
extremes. This is separate from the golden-set agreement metric.

```bash
cd examples/threadline_phoenix/e2e
npm run critic:validate -- --dry-run    # preview the twins + cost first
npm run critic:validate                 # runs the battery (~$1–3: 6 gestalt twins; veto-ordering twin is $0)
```

All gates must pass: binary directional (correct rank), margin gate (delta > noise floor),
metamorphic invariance (verdict stable under reshuffling), and veto-ordering (off-token accent
trips the veto, no aesthetic score emitted). Failure bars the critic from any ledger bump.

### Step 3 — Score the golden cells and record critic_trust

```bash
cd examples/threadline_phoenix/e2e
# Score EXACTLY the labeled golden (cell, lens) pairs — cheap and correct for measurement.
npm run critic:score -- --golden --dry-run    # check cost before running
npm run critic:score -- --golden              # bills the API for the golden cells only

# Measure per-lens trust and write the critic_trust block (separate, reviewed step):
cd ../../.. && mix critic.measure
```

`npm run critic:score -- --golden` writes nondeterministic per-dimension scores under
`test/generated/operator_surface/critic-scores/`. All local capture and critic output
lives below the ignored `test/generated/operator_surface/` boundary; immutable inputs
remain under `test/fixtures/operator_surface/`.
The measurement alias then computes per-lens Krippendorff's α, raw agreement, and n against the
golden labels and writes the `critic_trust` block in `test/fixtures/operator_surface/design-system-ledger.json`.
It is local-only (not in `ci.all`) and never git-commits — you review the diff and commit.

A lens is set `validated: true` only if α ≥ 0.67 AND n ≥ 20 AND raw_agreement ≥ 80% at the
current rubric version + model ID. (`pairwise_acc` is recorded as `null` until the label CLI
persists pair margins — it never gates promotion.)

### Step 4 — Regenerate the reviewable CRITIQUE.md

```bash
# CRITIQUE.md auto-regenerates at the end of `critic:score`. To regenerate standalone:
cd examples/threadline_phoenix/e2e && node --import tsx critic/run.ts report
```

Verify `test/generated/operator_surface/reports/CRITIQUE.md` is fresh — it should show scored cells with Betterer flags
(▲ new for first scores, ▲/▽ gain/regression on subsequent runs).

### Step 5 — Confirm CI stays honest

```bash
mix ci.all
```

`mix verify.critic_trust` (part of `ci.all`) enforces whatever was recorded in
`critic_trust`. All other gates (`verify.mechanical`, `verify.test`, etc.) must stay green.
`mix verify.ui_critique` itself is excluded from `ci.all` — it is local-only.

### Step 6 — Commit as one reviewed commit

```bash
git add test/fixtures/operator_surface/golden/golden-set.json
git add test/fixtures/operator_surface/golden/rounds/r2.json
git add test/fixtures/operator_surface/design-system-ledger.json  # critic_trust block updated
git commit -m "chore: golden oracle scored and critic trust measured"
```

This commit should never be auto-generated — it represents the maintainer's reviewed judgment.

### Rubric maintenance

To check rubric integrity (hash, dimension count, pole references):

```bash
npm run critic:rubric -- lint
```

To bump a rubric version after editing it (recomputes sha8, prints invalidation blast radius):

```bash
npm run critic:rubric -- bump hierarchy --patch   # wording tweak
npm run critic:rubric -- bump density --minor     # new dimension added
npm run critic:rubric -- bump typography --major  # lens semantics redefined
```

After a bump, `critic_trust` for that lens is auto-invalidated (the rubric version no longer
matches the stored `golden_rubric_version`). Re-run the golden-set scoring to restore trust.

## Forward-only gate — run one iteration

**Maintainer-only.** This is the repeatable loop that turns the validated critic (above)
into a **forward-only net-positive gate**: a proposed change to a real `/audit` page is
accepted only if it moves the targeted **blocking** lens in the right direction with **no
regression** anywhere on the blocking panel, and only after the deterministic mechanical /
a11y floor still passes. Like the oracle steps above it is **local-only** (needs
`ANTHROPIC_API_KEY`) and **never runs in CI** — CI runs only the deterministic guards
(`verify.critic_trust`, `verify.mechanical`).

The loop operates on the real seeded `route.*` cells, never the `page.*`
stress-lab chrome and never the isolated `story.*` fixtures. Each `route.*` cell has a
committed `page.<x>.happy` twin in `mechanical_floors`; that twin is the deterministic floor
the gate gates on.

### Route ↔ page twin mapping

| route cell (live, gitignored) | route path | committed `page.*` twin (mechanical floor) |
|---|---|---|
| `route.timeline` | `/audit/timeline` | `page.timeline.happy` |
| `route.coverage` | `/audit/coverage` | `page.coverage.happy` |
| `route.retention` | `/audit/policy/retention` | `page.retention.happy` |
| `route.actor` | `/audit/actors/service_account/zendesk-sync` | `page.actor.happy` |
| `route.evidence` | `/audit/evidence` | `page.evidence.happy` |

### Steps (capture → score → gate → floor → ratify → commit)

```bash
cd examples/threadline_phoenix/e2e

# 1. Capture the live route lane (needs the seeded dev server — see e2e/run-e2e.sh).
#    Writes route.* PNG + scorecard JSON; these stay LOCAL (gitignored) by design.
npm run capture:pages

# 2. Score the four BLOCKING lenses on the candidate routes to pick the weakest
#    (page, lens) — this is the propose target. Records the "before" snapshot.
npm run critic:score -- --page route.coverage

# 3. Make the proposed change, re-capture (step 1), then run the accept/reject gate
#    on the targeted blocking lens. The gate is RELATIVE (ranking Δ vs IQR noise
#    floor), blast-radius-aware, and never uses an absolute score threshold.
npm run critic:gate -- --page route.coverage --lens brand_fidelity
```

```bash
# 4. The deterministic hard floor: the mechanical / a11y checker over the COMMITTED
#    page.<x>.happy twin (WCAG contrast + off-grid px hard-fail; ratchet floors).
cd ../../.. && mix verify.mechanical
```

```bash
# 5. Ratify + commit the evidence trail: append the human sign-off to
#    ratchet.signoffs in the append-only ledger, then commit the reviewed diff.
git add test/fixtures/operator_surface/design-system-ledger.json   # ratchet.signoffs + any twin bump
git commit -m "chore: forward-only gate — <page> <lens> advanced, zero regressions"
```

### Invariants (do not violate)

- **LLM stays local-only and out of CI** (196-D9). The gate's scoring/re-eval calls the
  external AI API; only the deterministic `verify.critic_trust` + `verify.mechanical` guards
  run in `ci.all`.
- **Only the four validated lenses block**: `brand_fidelity`, `density`, `typography`,
  `rhythm`. `hierarchy` and `color_contrast` are **advisory only** — reported under an
  advisory badge, **never** auto-block, and their findings must be **verified against ground
  truth** before anyone acts on them (they confidently hallucinate specifics).
- **The gate is relative, not absolute** — accept iff the targeted lens improves AND no
  blocking lens regresses below its floor AND the mechanical floor still passes; compare
  rank/Δ direction, never absolute thresholds.
- **`route.*` cells and critic reports stay uncommitted** under
  `test/generated/operator_surface/` (gitignored and regenerated per run). Only the
  reviewed ledger sign-off + any twin bump is committed.

## CI Coverage

Browser coverage is **split** across two workflows. Pull requests run a reduced
Playwright project set so per-PR feedback stays inside a usable loop; the full
set runs on `main` and nightly. **This is a real trade, not a free speedup** —
four projects that used to run on every pull request now run only after merge.
They are named below.

| Playwright project | Pull request | `main` | Nightly | Runs via |
|---|---|---|---|---|
| `desktop-chromium` | **yes** | yes | yes | `verify-example-browser` (PR, **required**) + `verify-example-browser-full` |
| `mobile-chromium` | **yes** | yes | yes | `verify-example-browser` (PR, **required**) + `verify-example-browser-full` |
| `tier-a-capture` | **yes** | yes | yes | `verify-capture` (PR, `mix verify.capture`) + `verify-example-browser-full` |
| `tier-a-capture-light` | **yes** | yes | yes | `verify-capture` (PR, `mix verify.capture`) + `verify-example-browser-full` |
| `storybook-capture` | no | yes | yes | `verify-example-browser-full` only |
| `graded-capture` | no | yes | yes | `verify-example-browser-full` only |
| `refute-capture` | no | yes | yes | `verify-example-browser-full` only |
| `route-capture` | no | yes | yes | `verify-example-browser-full` only |
| `desktop-chromium-light` | no | no | no | Registered only under `THREADLINE_E2E_THEME=system`; run locally via `mix verify.example_browser_light`. Not wired into any CI job. |

**The `main` and nightly columns are the same lane, not two lanes.** Job
`verify-example-browser-full` in
[`.github/workflows/browser-full.yml`](.github/workflows/browser-full.yml)
triggers on both push-to-`main` and a nightly `schedule`, plus manual dispatch.
The pull-request set and the full set **overlap** — `desktop-chromium` and
`mobile-chromium` run in both; the table is not a partition.

**What does not run on pull requests:**

- `storybook-capture`, `graded-capture`, `refute-capture`, and `route-capture` —
  moved to `main` + nightly only.
- The bare `chromium` project was **deleted outright**, not moved. It was
  `Desktop Chrome` at 1280×720 with no scoped `testMatch`, and both
  snapshot-bearing specs already excluded it by name, so it carried zero
  baselines and added zero coverage over `desktop-chromium`.

`verify-example-browser-full` is **not** a required check and does not block a
pull request. Because a `schedule:` run notifies nobody, a failure of that lane
opens (or comments on) a single deduplicated tracking issue labelled
`ci-browser-full` — distinct from Flake Detection's own dedup stream.

This table is not documentation-on-trust:
`test/threadline/ci_coverage_doc_contract_test.exs` derives the project list from
the actual `--project` flags in the workflows and fails if a project a workflow
really runs is missing from this table.

### `ci-required` needs: roster

This is what the single required check `CI required` actually proves: every
pull request merged to `main` proves each of the following jobs succeeded.
`test/threadline/ci_topology_contract_test.exs` derives this list from
`.github/workflows/ci.yml`'s `ci-required` job itself and fails in either
drift direction — a job the aggregate requires but this list omits, or a job
this list claims but the aggregate no longer requires (the silent-narrowing
case) — so a future edit to `needs:` cannot shrink this guarantee
without also failing a test.

- `verify-format`
- `verify-credo`
- `verify-dialyzer`
- `verify-compile-no-optional`
- `verify-test`
- `verify-hex-evaluator`
- `verify-example-browser`
- `verify-mechanical`
- `verify-capture`
- `verify-pgbouncer-topology`
- `verify-docs`
- `verify-hex-package`
- `verify-release-shape`
- `verify-bump-rehearsal`

No `allowed-skips` or `allowed-failures` entry is documented here today,
because `.github/workflows/ci.yml`'s `alls-green` step carries neither — every
job above runs unconditionally. If either is ever introduced, it must be
recorded here as `allowed-skips decision: D-NN` or `allowed-failures decision:
D-NN`, citing the decision that authorized it; the roster contract test fails
otherwise.

## CI parity and `act`

GitHub Actions workflow: `.github/workflows/ci.yml`. **Live runs (branch `main`):** https://github.com/szTheory/threadline/actions?query=branch%3Amain — Stable job keys (do not rename; used by docs, `act`, and branch protection):

| Job key | Purpose |
|---------|---------|
| `verify-format` | `mix verify.format` |
| `verify-credo` | `mix verify.credo` |
| `verify-dialyzer` | `mix verify.dialyzer`; strict full-build analysis on Elixir 1.17.3 / OTP 27.0 with the exact PLT cache lifecycle below |
| `verify-compile-no-optional` | `mix verify.compile_no_optional` (compile without optional deps; gates against missing Phoenix/LiveView) |
| `verify-test` | compile `--warnings-as-errors` + `mix verify.test` (Postgres service) |
| `verify-pgbouncer-topology` | Postgres + **PgBouncer (`POOL_MODE=transaction`)** — `priv/ci/topology_bootstrap.exs` on direct Postgres, then `mix verify.topology` + `mix verify.threadline` on the pooler port |
| `verify-hex-evaluator` | `mix verify.hex_evaluator` — threadline resolved from hex.pm in a nested project |
| `verify-example-browser` | `mix verify.example_browser` — operator-surface Playwright e2e on the example app |
| `verify-mechanical` | `mix verify.mechanical`; deterministic MODE-A / MODE-B gate over the committed `test/fixtures/operator_surface/scorecards/*.json` |
| `verify-capture` | `mix verify.capture`; regenerates the Tier A evidence from scratch against a migrated example DB and a real browser, and asserts byte-stable regeneration against the committed evidence |
| `verify-docs` | `MIX_ENV=dev` — `mix docs` (ExDoc + extras) |
| `verify-hex-package` | `mix hex.build` + assert tarball contains `lib/` |
| `verify-release-shape` | `bin/verify-release-shape` — `@version` / dated `CHANGELOG` for release versions |
| `verify-bump-rehearsal` | `mix verify.bump_rehearsal` — simulates the next-minor release commit in a throwaway clone and runs `mix verify.doc_contract` + `mix verify.release` against it, so a born-red release cause fails the pull request that introduces it rather than the publish gate |

### Dialyzer PLT cache and measurement contract

`mix verify.dialyzer` is part of `mix ci.all`, and the unconditional
`verify-dialyzer` job runs the same `mix dialyzer --no-check` analyzer command
on the exact current lane: Ubuntu 24.04, Elixir 1.17.3, and OTP 27.0. The
independent no-optional-dependencies compile lane never runs Dialyzer; analysis
always uses the full optional build and the strict warning/ignore configuration
from `mix.exs`.

The PLT cache lives at `.dialyzer` and is keyed by the runner image, exact OTP
and Elixir versions, and both `mix.lock` and `mix.exs` hashes. A restore prefix
may reuse only a PLT from the same runner/OTP/Elixir boundary. On a miss, CI
fetches dependencies and compiles outside the timers, measures `mix dialyzer
--plt`, saves the successfully built PLT, and only then measures `mix dialyzer
--no-check`. On an exact-key hit, CI skips PLT construction and reports no
synthetic PLT-build values.

The stable log fields are:

- `THREADLINE_DIALYZER_PLT_CACHE`: exactly `miss` or `hit`.
- `THREADLINE_DIALYZER_PLT_WALL_SECONDS`: numeric PLT-build wall time, miss only.
- `THREADLINE_DIALYZER_PLT_MAX_RSS_KB`: integer PLT-build peak RSS, miss only.
- `THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS`: numeric analysis wall time on every run.
- `THREADLINE_DIALYZER_ANALYSIS_MAX_RSS_KB`: integer analysis peak RSS on every run.

GNU `time -v` parsing fails closed if any required measurement is absent or
non-numeric. Durable cost claims require authenticated immutable run URLs, the
exact commit and dependency/config hashes, and separate cold and exact-key-hit
runs for that same commit; estimates and unlinked log excerpts are not valid
evidence.

#### Authenticated cold/hit evidence (2026-09-11)

Both jobs below are attempt 1 for commit
`a4f21e7e89ed4f958bc4ff0bb48c796225496bdd`. They ran on GitHub-hosted
`ubuntu-24.04` image version `20260907.300.1` (Ubuntu 24.04.5 LTS; runner
2.337.0), with the workflow pins resolving to Erlang/OTP 27.0.1 and Elixir
1.17.3 compiled for OTP 27. Their identical primary PLT cache key recorded
`hashFiles('mix.lock') = f8275246d287e483bdc4bea1cc53781d9076e21403d44c887c3adfedaabbb53a`
and
`hashFiles('mix.exs') = 1025d27a2bd55968da5682d1654a62eff358df117b8d8a52e6c8ed034c0b7861`.

| Evidence | Cold cache miss | Exact-key cache hit |
|---|---|---|
| Workflow run | [`34642915672`](https://github.com/szTheory/threadline/actions/runs/34642915672), event `push` | [`34643744220`](https://github.com/szTheory/threadline/actions/runs/34643744220), event `workflow_dispatch` |
| Dialyzer job | [`103406722917`](https://github.com/szTheory/threadline/actions/runs/34642915672/job/103406722917), success | [`103410179816`](https://github.com/szTheory/threadline/actions/runs/34643744220/job/103410179816), success |
| PLT cache proof | `THREADLINE_DIALYZER_PLT_CACHE=miss`; exact key not found, then saved before analysis | Exact primary key restored; `THREADLINE_DIALYZER_PLT_CACHE=hit`; PLT build step skipped |
| PLT build | `THREADLINE_DIALYZER_PLT_WALL_SECONDS=152.82`; `THREADLINE_DIALYZER_PLT_MAX_RSS_KB=2282540` | Not emitted, as required on a hit |
| Analysis | `THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS=9.82`; `THREADLINE_DIALYZER_ANALYSIS_MAX_RSS_KB=1023056` | `THREADLINE_DIALYZER_ANALYSIS_WALL_SECONDS=9.42`; `THREADLINE_DIALYZER_ANALYSIS_MAX_RSS_KB=1009288` |
| Whole job elapsed | 252 seconds (20:11:54Z–20:16:06Z) | 123 seconds (20:23:39Z–20:25:42Z) |

The `verify-dialyzer` timeout is derived from the measured cold whole-job
elapsed time, not just the analyzer subprocesses: `ceil(252 seconds × 2.0 / 60)
= 9 minutes`. The 2.0 factor gives 100% headroom for dependency, runner, and
PLT-build variance while keeping a bounded failure time. The exact-key hit
saved 143.4 seconds of analyzer work (`162.64 - 9.42`) and 129 seconds of
whole-job elapsed time (`252 - 123`) on this evidence pair.

Hex **publish** runs from **[`.github/workflows/release.yml`](.github/workflows/release.yml)** (canonical) using the **`HEX_API_KEY`** repository secret — see [Hex publish (maintainers)](#hex-publish-maintainers) below.

For running the test job locally with [nektos/act](https://github.com/nektos/act), see `scripts/ci/README.md`.

## PgBouncer topology CI parity

`docker-compose.yml` includes **`pgbouncer`** (transaction mode) behind the
`pgbouncer` Compose profile on host port **`6432`** by default
(`THREADLINE_PGBOUNCER_PORT`), alongside Postgres on **`5433`**
(`THREADLINE_DB_PORT`).

1. `docker compose --profile pgbouncer up -d` and wait until both services are healthy.
2. Bootstrap migrations + topology fixture on **direct** Postgres (DDL does not go through PgBouncer):

   ```bash
   MIX_ENV=test DB_HOST=localhost DB_PORT=5433 THREADLINE_TOPOLOGY_BOOTSTRAP=1 mix run priv/ci/topology_bootstrap.exs
   ```

3. Run topology tests + `verify.threadline` through the pooler:

   ```bash
   MIX_ENV=test DB_HOST=localhost DB_PORT=6432 THREADLINE_PGBOUNCER_TOPOLOGY=1 mix verify.topology
   MIX_ENV=test DB_HOST=localhost DB_PORT=6432 THREADLINE_PGBOUNCER_TOPOLOGY=1 mix verify.threadline
   ```

`mix verify.topology` **requires** `THREADLINE_PGBOUNCER_TOPOLOGY=1` so it cannot accidentally pass against direct Postgres only.

## Host STG evidence (integrators)

**Host staging / pooler parity** is **integrator-owned attestation**: detailed topology, logs, and runbooks live in **your** repo or docs under **your** control. Threadline maintainers do not operate your staging stack.

To contribute a **short in-repo index** (tables, links, **redact**ed excerpts) that helps other operators, use a **fork** and open a **pull request** against this repository. Maintainers merge for **modesty** of claims, **redaction**, and **link** hygiene only — not to vouch for third-party environments.

Fill the canonical scaffolds in the [adoption pilot backlog](guides/adoption-pilot-backlog.md): search for **`STG-HOST-TOPOLOGY-TEMPLATE`** (fixed-field topology narrative) and **`STG-AUDITED-PATH-RUBRIC`** (HTTP + job paths with OK / Issue / N/A / Not run and evidence pointers). Long-form evidence stays in integrator-controlled artifacts; the PR updates the **small, reviewable surface** in `main`.

## Branch protection (maintainers)

In GitHub repository settings, require these checks on `main` (names match the workflow `name:` fields or job summaries as shown in the PR UI):

- Check formatting (`verify-format`)
- Run Credo (strict) (`verify-credo`)
- Run test suite (min) (`verify-test` min lane)
- Run test suite (current) (`verify-test` current lane)
- PgBouncer transaction topology (`verify-pgbouncer-topology`)
- Build ExDoc (dev) (`verify-docs`)
- Hex package tarball (`verify-hex-package`)
- Release metadata (version / changelog) (`verify-release-shape`)

Exact labels depend on GitHub’s UI; map them to the job keys above.

## Backport policy (maintainers)

Security and critical fixes are backported as patch releases on the current minor (e.g. `0.9.1`), which any `~> 0.9.0`-style three-segment pin picks up automatically; crossing a minor stays a deliberate, changelog-reading act. This keeps an install-once audit adopter on a tight pin from being stranded on an unpatched line. This mirrors the backport policy stated for adopters in [`guides/upgrade-path.md`](guides/upgrade-path.md).

## Hex publish (maintainers)

**Canonical path:** [`.github/workflows/release.yml`](.github/workflows/release.yml) — Release Please on `main` (0.6.1+) or **`workflow_dispatch`** bootstrap/recovery (e.g. first **`v0.6.0`** cut).

The release workflow:

1. Resolves the release ref (Release Please tag or dispatch inputs).
2. Waits for green **`ci.yml`** on the release SHA (`gate-ci-green`).
3. Runs **`mix verify.release`**, then **`mix hex.publish --yes`** (idempotent if version already on Hex).
4. Polls Hex.pm until the version is indexed.
5. Opens a **distribution sync PR** (`bin/post-publish-distribution-sync`) that flips the adoption-pilot **Hex attestation row** ("latest is X on Hex") to OK with dated evidence — the one version statement that is only true *after* publish.

> The adoption-pilot **SSOT line** ("Distribution preflight below reflects the **X** tree") is bumped **automatically by Release Please** in the release commit (`release-please-config.json` → `extra-files`, via the `x-release-please-version` annotation on that line). There is **no manual doc prep** before a Release PR — it is green by construction. `test/threadline/adoption_pilot_doc_contract_test.exs` guards this wiring.

**Secrets:** **`HEX_API_KEY`** (required). **`RELEASE_PLEASE_TOKEN`** (optional fine-grained PAT — recommended for Release Please PRs and distribution sync PRs).

### The publish approval is a confirmation, not a review

The `publish-hex` job declares the **`production-hex`** environment, which carries a required-reviewer rule. The approval prompt sits after the green-CI gate and immediately before `mix hex.publish`, so it is the last thing between a commit and a permanent public artifact.

Every automated gate above it answers one question: **is this artifact well-formed?** — formatting, Credo, Dialyzer, the suite, the tarball shape, the evaluator install, the release metadata. The human answers a different question that no gate can: **is this the release I meant to make, and from this commit?**

Be honest about what it is not. This repository has a single maintainer, and the environment rule permits self-review, so the approval is a **confirmation step** — it is **not peer review and not a second pair of eyes**. Describing it as review would be the same category of claim as a gate that asserts a line of configuration and calls it behavior, which is exactly the failure this project keeps finding in its own tooling.

Two checks cover the gate, and they prove different things:

| Check | What it proves | What it does **not** prove |
|-------|----------------|-----------------------------|
| `test/threadline/release_control_plane_contract_test.exs` | `release.yml` still declares the environment on the publish job, and the publish command still sits behind it | Nothing about GitHub's side — deleting the reviewer leaves this green and the gate inert |
| `bin/verify-environment-protection` (workflow: `Environment Protection`) | The **live** environment still carries a required-reviewer rule with at least one reviewer, and the publish job is gated on that same environment name | Nothing about the artifact — it is a property of repository configuration, not of the commit under test |

The script fails closed: an unreadable response is never scored as a pass. Its only partial-pass path requires `ALLOW_UNVERIFIED_ENVIRONMENT_PROTECTION=1` and prints a warning naming what it could not inspect. That variable is deliberately not set in the workflow. The check runs **outside** the required status check, because a contributor cannot fix repository configuration and should not be blocked by it.

### Version-bearing lines and who owns them

Every line in `README.md`, `guides/**`, and this file that carries a Threadline version number has exactly one named owner. The goal is that **no version-bearing line requires a hand edit at release time** — not that no version literal exists. A sentence that uses a version as an *example* stays true after a bump and needs no owner; a sentence that asserts *what the current version is* must be produced by automation.

That distinction is the honest scope of the rule. An illustrative literal is not a maintenance burden, and pretending otherwise would push us toward deleting useful examples to satisfy a metric.

| Line | Owner | Disposition |
|------|-------|-------------|
| The six `{:threadline, "~> x.y.z"}` install pins (`README.md`; `guides/getting-started-saas.md`, `operator-surface.md`, `evaluating-threadline.md`, `adoption-evidence-playbook.md`, `adoption-pilot-backlog.md`) | mix release.pins | current-version claim |
| `guides/adoption-pilot-backlog.md` preflight SSOT sentence; `guides/evaluating-threadline.md` SSOT sentence (both carry `x-release-please-version`) | Release Please `extra-files` marker | current-version claim |
| `guides/adoption-pilot-backlog.md` Hex attestation row ("latest is **X** on Hex", tag **`vX`**) | `bin/post-publish-distribution-sync` | current-version claim |
| `guides/upgrade-path.md` opening era narrative (the minor range ending at the latest minor) | human prose, written with that release's upgrade row — see the release checklist item below | current-version claim |
| `guides/upgrade-path.md` backport-policy example (`0.9.1` / `~> 0.9.0`) | human prose | illustrative |
| `guides/upgrade-path.md` historical era rows and per-minor upgrade bullets (`[0.7.0]`…`[0.9.0]`, `0.8.x → 0.9.x`) | human prose, append-only history | illustrative |
| `CONTRIBUTING.md` backport-policy example (`0.9.1` / `~> 0.9.0`) | human prose | illustrative |
| `CONTRIBUTING.md` bootstrap references to **`v0.6.0`** | human prose, historical record | illustrative |

**Release checklist item (minor bumps only).** A minor release must add that minor's upgrade row to [`guides/upgrade-path.md`](guides/upgrade-path.md) and extend the opening era narrative to include it. This is authoring new *content* — what changed and what an adopter must do — not a mechanical version substitution, which is why it has a human owner rather than an automated one. `test/threadline/version_truth_doc_contract_test.exs` Family C fails the build until the new minor's coverage exists, so the step cannot be silently skipped.

**Enforced invariants.** `test/threadline/version_truth_doc_contract_test.exs` fails if an install pin drifts from the `major.minor.0` floor derived from `mix.exs` `@version` (Family A), if a marked SSOT line is unregistered or stale (Family B), or if a pin line ever *also* carries a Release Please marker (Family B-inverse). The last one exists because Release Please cannot correctly own a pin line: its generic updater writes the full version (wrong for a floor pinned at the minor) and its component updater replaces the leading digit inside the requirement string (producing a nonsense major). Never add a pin-bearing file to `extra-files` in `release-please-config.json`.

### Bootstrap `v0.6.0` (one-shot)

After Wave 1 distribution doc work is on **`main`** and CI is green:

1. Actions → **Release** → **Run workflow**
2. Inputs: `tag` = `v0.6.0`, `release_version` = `0.6.0`
3. Merge the automated **distribution sync** PR when `mix verify.doc_contract` passes on that PR

The workflow creates tag **`v0.6.0`** on green `main` HEAD if the tag does not exist yet.

### Ongoing releases (0.6.1+)

1. Merge conventional commits to **`main`** — Release Please opens/updates a Release PR (`release-please-config.json`, manifest `.release-please-manifest.json`). The Release PR bumps `mix.exs`, `CHANGELOG.md`, **and** the adoption-pilot SSOT line together, so it is green on the doc contract without any manual prep.
2. Merge the Release PR when CI is green — Release Please tags, then the same publish + distribution sync chain runs.

### Recovery / dry-run

**`workflow_dispatch`** inputs:

| Input | Purpose |
|-------|---------|
| `tag` | Existing or to-be-created `vX.Y.Z` |
| `release_version` | Must match `@version` in `mix.exs` at that ref |
| `dry_run` | `mix hex.publish --dry-run --yes` only |
| `skip_distribution_sync` | Publish without opening the doc sync PR |

**Local manual runbook (optional):** `mix hex.publish --dry-run` / `mix hex.publish` with `mix hex.user auth` instead of CI.

Post-publish distribution proof for adopters is recorded in the adoption-pilot
Distribution preflight row in `guides/adoption-pilot-backlog.md`.

### Recovery after a bad publish

Written down **before** a publish goes wrong, so it is a procedure rather than a decision made under pressure.

**The decision rule, first:** inside the revert window, **revert**. Outside it, **retire and patch**. Do not spend the window deciding which one to do.

**1. Inside the window — revert.** Hex allows a published release to be reverted for a short period after it is published, on the order of **an hour**. Within that window:

```bash
mix hex.publish --revert X.Y.Z
```

This is the only path that actually withdraws the release. Treat the window as short and act immediately; do not wait for a full diagnosis, because a diagnosis that takes two hours costs you this option.

**2. Outside the window — retire, then ship a patch the same day.** Retirement is the only remaining lever:

```bash
mix hex.retire threadline X.Y.Z invalid --message "Reason, and the version to use instead"
```

Be precise about what retirement does: it **warns**. Resolving the retired version prints a warning, and the package page marks it. Be equally precise about what it does **not** do:

- It does **not** remove the tarball — the release stays downloadable.
- It does **not** break existing lockfiles — a project with the bad version in `mix.lock` keeps resolving it.
- It does **not** move anyone already pinned — nobody is upgraded off the retired release by retiring it.

So retirement is a signal, not a fix. The **fix** is a **same-day patch release** that corrects the defect, paired with the retirement so the warning has somewhere to point. Ship it through the normal Release Please path; do not hand-publish around the gates.

**3. Removal beyond retirement is not available to you.** Deleting a published release after the revert window is a support request to the Hex team, granted at their discretion and not on your schedule. Plan as if it is unavailable, because in any timeframe that matters it is.

**4. Documentation is permanent regardless.** Published documentation for a version stays published even when that version is reverted, so the recovery path never fully restores the prior state. Anything embarrassing or wrong that reaches HexDocs is public from then on — which is the strongest argument for the confirmation step in front of the publish, above.

Recovery is deliberately **not automated**. There is no mix alias, script, or workflow for it, and adding one would create a fast path to an irreversible action. The commands above are run by a human who has read this section.

## Maintainer manual checklist (release)

Use when preparing or debugging a release (no secrets in logs):

1. Clean tree: `git status --porcelain` empty (local preflight only).
2. Run `mix verify.release`.
3. Run `DB_PORT=5433 mix ci.all` (or `mix ci.all`) with Postgres up.
4. Ensure **`main`** CI is green on the commit to release.
5. **Release workflow:** dispatch **`release.yml`** or merge Release Please PR — do not rely on manual `mix hex.info` copy-paste; the workflow polls Hex.pm and opens the distribution sync PR.
6. Merge the distribution sync PR after doc contracts pass.
