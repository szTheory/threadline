# Phase 192: CI/CD Measurement and Efficiency Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-02
**Phase:** 192-CI/CD Measurement and Efficiency Hardening
**Areas discussed:** Baseline evidence depth (CI-01), Caching aggressiveness (CI-02), Compat policy & lanes (CI-04), Alignment fixes (CI-03)

**Method:** User selected all four gray areas and directed a deep research-then-recommend pass. Four `gsd-advisor-researcher` agents researched pros/cons/tradeoffs, Elixir-ecosystem idioms, and lessons from comparable libs (Oban, Ecto/ecto_sql, Phoenix, Broadway, Carbonite). A second **adversarial verification round** (technical red-team + project-DNA/vision check against `prompts/`) stress-tested the synthesized set and produced amendments. Final decisions are in `192-CONTEXT.md`.

---

## CI-01 — Baseline evidence depth & artifact

| Option | Description | Selected |
|--------|-------------|----------|
| A. Static-only | Read `ci.yml`; derive fan-out, deps×N, cache absence, critical path by inspection | partial |
| B. Static + single-run snapshot | One green run via `gh api .../jobs` | |
| C. Static + multi-run p50/p95 | Aggregate last ~15 green runs; honest "unavailable" rows | ✓ |
| D. Instrument-first | Add caching/tooling then measure | ✗ (violates measurement-first non-goal) |

**User's choice:** Option C (verified CONFIRMED by red-team). Static analysis is the mandatory structural half, not a competitor.
**Notes:** ~96 runs of history available. Billed-minutes and cache-hit-rate are genuinely unavailable → recorded with Nyquist-debt metadata (owner/date/pointer/reopen-trigger). No workflow edits during baselining.

---

## CI-02 — Caching aggressiveness

| Option | Description | Selected |
|--------|-------------|----------|
| Cache `deps/` (all jobs) | Source-only, keyed on root `mix.lock` | ✓ |
| Cache Playwright browsers | Keyed on `e2e/package-lock.json` | ✓ |
| Cache npm download | Via `setup-node cache:npm` + explicit `cache-dependency-path` | ✓ |
| Cache `_build` | Recompile speed | ✗ (warnings-as-errors masking / cross-MIX_ENV bleed) |
| Cache Dialyzer PLT | Version-keyed PLT | ✗ (moot — no dialyzer CI job) |

**User's choice:** Add three, decline two.
**Notes (red-team amendments):** deps-key poisoning worry UNFOUNDED (`deps/` is source-only). **Footgun caught:** `setup-node cache:npm` fails without `cache-dependency-path: examples/threadline_phoenix/e2e/package-lock.json` (no root lockfile). PLT-decline rationale corrected from "warnings integrity" to "no-op, no dialyzer job." Example-host caches keyed to subtree, not root (DNA `:13`).

---

## CI-04 — Compatibility policy & CI matrix lanes

| Option | Description | Selected |
|--------|-------------|----------|
| A. Status quo (single lane) | Leaves `~> 1.15` untested | ✗ |
| B. Raise floor to 1.17 | Honest with one lane but narrows adopters | ✗ (adopter surprise) |
| C. Add min+current lane on verify-test only | min 1.15/OTP26/PG14 + current 1.17.3/OTP27/PG16 | ✓ |
| D. Full cross-product + nightly | All jobs × versions × PG | ✗ (non-goal: clever matrix before measurement) |

**User's choice:** Option C — honor the floor, add a min lane (verified CONFIRMED-WITH-AMENDMENT, highest-risk item).
**Notes (red-team amendments):** shared-`mix.lock` min lane is a zero-margin false promise → add guard test asserting no locked dep floors above 1.15 + scope contract to "1.15 compiles with current deps." Pin min lane to `ubuntu-22.04`; verify 1.15/OTP26 resolves before locking. Scope min-lane body to compile+test only. **CRITICAL:** matrix renames branch-protection checks (`Run test suite (min)`/`(current)`) → must reconfigure branch protection or PRs block forever. Preserve existing `--no-optional-deps` compile lane.

---

## CI-03 — Alignment & hygiene fixes

| Option | Description | Selected |
|--------|-------------|----------|
| Pin pgbouncer `v1.25.2-p0` | Tag-pin, symmetric with `postgres:16` | ✓ |
| CI concurrency (cancel PR only) | `cancel-in-progress` scoped to `pull_request` | ✓ |
| Release concurrency fix | Publish-JOB-level group (revised from workflow-level) | ✓ (revised) |
| Repair CONTRIBUTING drift | 8→10 job-key table | ✓ |
| Extend contract test | parity / no-latest / concurrency / check-name assertions | ✓ |

**User's choice:** All five (all repair live problems).
**Notes (red-team amendment):** first-pass proposed collapsing `release.yml` to a workflow-level group — **rejected as a regression** (serializes fast `release-please` bookkeeping behind 30-min publishes). Revised to **publish-job-level** concurrency. pgbouncer pin confirmed behavior-neutral. CI concurrency confirmed not to break the release-PR dispatch. Land all edits + branch-protection reconfig + tests as one change set (avoid born-red).

---

## Claude's Discretion

- Run-history aggregation script (throwaway, `.planning`-local).
- Exact `192-BASELINE.md` table layout within Phase-189 frontmatter convention.
- `restore-keys` prefixes and cache-step placement.
- Whether the min-lane dep-floor guard is a new test file or an extension of the contract test.

## Deferred Ideas

- Nightly/cron PostgreSQL spread (14/15/16/17) + extra Elixir versions — until PR timing measured.
- Bump current Elixir anchor to 1.18/1.19 — keep 1.17.3 this phase; CHANGELOG-note floor→1.16 at next floor-bump release.
- Digest-pinning service images / actions to full SHA — broader supply-chain hardening.
- Tightly-keyed per-env `_build` caching — only if a job proves compile-bound.
