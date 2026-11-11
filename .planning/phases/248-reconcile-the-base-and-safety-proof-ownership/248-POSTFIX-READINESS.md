> Superseded readiness snapshot. Its repeat grant is consumed; current corrected evidence, stopped resources and the unapproved diagnostic proposal are in [248-PRESSURE-READINESS.md](248-PRESSURE-READINESS.md). This snapshot grants no new run.

> Historical readiness snapshot: its one-invocation grant was consumed by five clean runs and an iteration6 public-reference timeout. The corrected current candidate and remaining decision are recorded in [248-INVENTORY-READINESS.md](248-INVENTORY-READINESS.md); this older snapshot is not fresh authority or proof.

# Phase 248 postfix readiness

The approved full repeat failed after six clean runs: iteration 7 timed out in the formatter ownership contract. Its classifier is `flaky`; the one-invocation grant is consumed. Plan 248-04 and ADM-04 remain incomplete.

## Concrete corrections and automated proof

- Formatter test: computes each ordered owner set once per ownership check, preserving all representatives, exact controls, the original glob, async mode and timeout. Calculated wildcard expansions fell from 168 to 36. Focused check and the full root suite passed. [Fix](248-FORMATTER-FIX.md), [independent review](248-FORMATTER-REVIEW.md).
- Database capacity: one diagnosed canonical attempt failed example startup on shared PostgreSQL14 connection exhaustion. A task-owned supported-floor PostgreSQL15.17 instance used the same 100-connection limit and existing host/port controls. Its observed sampled peak was 77 clients. No shared service/session was changed. The private service is now stopped; data is retained for continuation. [Diagnosis](248-PG-CAPACITY.md).
- Actual isolated canonical result: exit 0 / capture 0 in 1,427 seconds; root 3,400 tests / 0 failures, example 132 / 0, Dialyzer 0 errors and live slice 17 / 0. Browser: 417 first-attempt passes,one retry-passed clipboard focus case and 56 configured skips. This remains a non-clean browser result on source `ab65c014`. [Exact receipt](248-ISOLATED-CANONICAL-RECEIPT.json).
- Clipboard test: one established LiveView-connected wait, no product/UI/assertion change. Current source `ac260b47` passed 6 first-attempt target cases and the affected file with 41 passes / 11 configured skips across 52 combined desktop/mobile instances, all retries disabled. Discovery: 9 / 0 and inventory: 15 checks passed. The old first-attempt failure/context remain preserved; its exact cause is unconfirmed because tracing was disabled. The new proof covers the connected state, not pre-connect handoff. [Proof](248-CLIPBOARD-PROOF.md), [independent review](248-CLIPBOARD-REVIEW.md).

## Remaining action

A passing current-source nine-run scale 5 repeat remains required. The prepared proposal retains 55 minutes plus 60-second termination grace and the unchanged classifier/iteration assertions. It needs NEW explicit user approval for exactly one invocation; no automatic further retry is authorized. Approval concerns this bounded local resource use, not human UAT or risk acceptance. Phase249 implementation and worktree removal remain held.

The package stays 1.1.0. No hosted CI, live issue closure, scheduled clean dependency-health receipt, full minimum/current/latest matrix, REL-01, push, merge or publication is claimed. Earlier local PostgreSQL 14 runs are below the declared database floor and remain diagnostic history. The isolated local Elixir 1.17.3 / OTP 27 / PostgreSQL 15 evidence covers those components only.
