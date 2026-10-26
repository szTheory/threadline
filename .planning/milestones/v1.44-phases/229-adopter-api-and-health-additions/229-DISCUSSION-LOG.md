# Phase 229: Adopter API and Health Additions - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-02
**Phase:** 229-adopter-api-and-health-additions
**Areas discussed:** history/3 :limit, --strict, --all-schemas, :unresolved_legacy_keys + HLTH-04

**Mode:** Four parallel gsd-advisor-researcher agents ran first (one per area). One recommendation set was presented, and a single roll-up confirm followed.

---

## history/3 :limit

| Option | Description | Selected |
|--------|-------------|----------|
| Private validator in Query, Evidence wording, nil accepted | Raises before DB access. Cap applied in history_query/3 after the order_bys | ✓ |
| Generalise Cursors.timeline_page_size!/1 | Shared validator, but it is a refactor v1.45 owns | |
| NimbleOptions | New runtime dependency, and it changes existing error types | |

## --strict

| Option | Description | Selected |
|--------|-------------|----------|
| A. :error findings only, exit({:shutdown,1}), stderr status line, pure JSON stdout | Matches HLTH-01 and verify_coverage parity | ✓ |
| B. Also fail on uncovered tables | Scope change. Would cause false-red CI on first run | |
| C. Split exit codes (1/2) | Would change existing Mix.raise codes. Breaks parity | |

## --all-schemas

| Option | Description | Selected |
|--------|-------------|----------|
| A. Task-only, batched catalog query, {"schemas":…, "summary":…} envelope, SCHEMA column | One jq filter works for both modes. No new public API | ✓ |
| B. Bare object keyed by schema, per-schema loop | Key collisions, hash ordering past 32 keys, 2N round trips, N telemetry events | |
| C. List of per-schema objects | Not "keyed by schema" | |
| D. Public trigger_coverage(schema: :all) | One-way API decision ahead of v1.45 | |

## :unresolved_legacy_keys

| Option | Description | Selected |
|--------|-------------|----------|
| (a) Fold into trigger_findings/1 | Breaks the zero-grant PgBouncer contract, changes telemetry semantics and cost | |
| (b) New public Health.legacy_key_findings/1, called only by health.coverage | Index-bound, capped, time-limited per-table probes. Counts only backfillable rows | ✓ |
| (c) Mix-task only | Not callable from a release | |

**User's choice:** "Accept all (Recommended)". The whole recommendation set was accepted, including public `legacy_key_findings/1` and raising on unknown switches.

## Claude's Discretion

- Status-line wording, table widths, module and file split.
- Whether a legacy probe timeout raises or returns a sentinel from the public function.
- An optional incident-playbook sentence about `limit:`.

## Deferred Ideas

- The coverage/findings exclusion mismatch (3 vs 7 Threadline tables, extension tables).
- v1.45: umbrella Health.findings/1, public multi-schema API, @spec for history opts, `:limit` on sibling reads, actor_history's unvalidated `:limit`.
- Split exit codes, `--fail-on-uncovered`, `--summary`.
