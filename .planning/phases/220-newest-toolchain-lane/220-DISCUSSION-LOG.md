# Phase 220: Newest-Toolchain Lane - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-28
**Phase:** 220-newest-toolchain-lane
**Areas discussed:** Pins, Lane shape and payload, Pre-spike remediation, Spike vehicle, Green definition and not-yet policy, Contract tests, Docs, Spend (HIGH-IMPACT)

**Method:** research-then-recommend. Three parallel researchers covered toolchain availability, lane shape and contracts, and spike mechanics. The toolchain researcher also ran a local compile on Elixir 1.20.2 / OTP 29.0.5 against a scratch copy outside the repo. One roll-up recommendation set was then presented with a single confirm question, plus a separate HIGH-IMPACT spend question.

---

## Recommended set (items 1–7)

| Option | Description | Selected |
|--------|-------------|----------|
| Accept all | Lock items 1–7 as written | ✓ |
| Adjust specific picks | Change named items only | |
| Reject and discuss | Go area by area | |

**User's choice:** Accept all.

Alternatives weighed inside the set, all recommended against:
- PG pin: major-only `18`, or a digest pin, instead of `18.6`.
- Spike vehicle: a standalone spike workflow (can't be dispatched because it is not on main), a new `workflow_dispatch` input on `ci.yml`, or pushing to PR #60.
- Payload: running the example app, `verify.threadline` or Dialyzer on latest.
- Pins: floating (Oban/Req style) instead of exact (Phoenix/Ecto style).
- Pin contract: literal pins instead of shape-and-ordering checks.
- Beta-image check: a denylist instead of an allowlist.

## Spend (HIGH-IMPACT)

| Option | Description | Selected |
|--------|-------------|----------|
| Every run, trim in 222 | Lane votes on every PR, push and dispatch; about +6 billed runner-min/run; trimmed by 222 | ✓ |
| Main + dispatch only | Skip on PRs; needs `allowed-skips`; a PR can merge red on the new toolchain | |
| Record 'not yet' on cost | Record the lane as not yet because of spend, even if green | |

**User's choice:** Every run, trim in 222.

## Claude's Discretion

- The `ledger_splice.ex` restructure, and how the D-08 fixes are split into commits.
- The local pre-spike versions (install 1.20.4 / 29.1.1, or run the installed 1.20.2 / 29.0.5 and say so).
- Whether to extend remeasure tooling to measure latest's actual cost.

## Deferred Ideas

- `mix test --warnings-as-errors` across all lanes.
- A deps-health pin-drift job.
- Running the example app, `verify.threadline` or Dialyzer on latest.
- Cost trim: Phase 222.
- Retiring the historical required-check list in CONTRIBUTING: Phase 221.
- Reviewed, not folded: todo `2026-09-28-ci-suite-sync-bound-parallelism.md`.
