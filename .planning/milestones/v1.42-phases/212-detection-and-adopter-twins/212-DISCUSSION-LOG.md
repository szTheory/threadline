# Phase 212: Detection and Adopter Twins - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-26
**Phase:** 212-detection-and-adopter-twins
**Areas discussed:** Findings API shape, Detection semantics per code, Mix task gate and output, PgBouncer and non-owner safety, Adopter twin shapes

Mode: advisor (USER-PROFILE.md present, `minimal_decisive` tier). Five `gsd-advisor-researcher` agents ran in parallel, one per area. The maintainer's standing instruction was "auto follow your recommendations", so every area took the researched recommendation, except for the two orchestrator overrides noted below.

---

## Findings API shape

| Option | Description | Selected |
|--------|-------------|----------|
| Plain maps | `%{code:, severity:, ...}` | |
| `%Threadline.Health.Finding{}` struct | `@enforce_keys`, dialyzer-checkable, matches the ActorRef/AuditContext precedent | ✓ |
| `:schema` defaults to `"public"` | mirrors `trigger_coverage/1` | |
| `:schema` defaults to all non-system schemas | the only way to see the two-schema twin and cross-schema sharing | ✓ |
| Identify triggers by name prefix only | today's coverage behaviour | |
| Identify by name prefix ∪ function (`tgfoid` → `proname`) | catches renamed or copied triggers; required for the shared-function check | ✓ |
| Leave `trigger_coverage/1` counting disabled triggers | no behaviour change | |
| Exclude disabled (`'D'`/`'R'`) from covered | HLTH-05 requires it; this is a breaking-change CHANGELOG entry | ✓ |

**Choice:** struct; all-schemas default; union identification; coverage excludes disabled; sort by `{schema, table, code}`; new `[:threadline, :health, :findings_checked]` telemetry event.
**Notes:** The researcher was split on identification. Area 2 preferred name-only for duplicate detection. The union was chosen because it covers both and closes the renamed-trigger gap.

## Detection semantics per code

| Option | Description | Selected |
|--------|-------------|----------|
| New code for a legacy no-arg trigger on a non-`id` key | `:legacy_trigger_pk_mismatch` | |
| Reuse `:pk_drift`, treating a no-arg trigger as the implicit `{"id"}` key | one set-equality rule | ✓ |
| Separate codes per drift cause | dropped PK / renamed column / removed override | |
| One `:pk_drift` with `details.reason` | 210 D-16's single rule | ✓ |
| Disabled means `'D'` only | literal HLTH-05 wording | |
| Disabled means `'D'` or `'R'` | a replica-only trigger silently skips app writes | ✓ |

**Choice:** as selected. Only `:error` and `:warning` exist. A table can produce several findings. The bare global `threadline_capture_changes` is excluded from the shared-function check. Each message carries its exact fix command.

## Mix task gate and output

| Option | Description | Selected |
|--------|-------------|----------|
| Gate only on expected tables | keeps the positive-list contract | ✓ |
| Gate on any error finding | breaks the positive-list contract | |
| Additive `findings` JSON key plus a FINDINGS text section | non-breaking | ✓ |
| Reshape the JSON | breaks adopters' jq scripts | |
| Add `--strict` now | already a ROADMAP backlog item | |

**Choice:** gate on expected tables, and print un-gated error findings under a "not gated" heading (orchestrator refinement); the additive JSON key; keep `--schema`; no `--strict`.

## PgBouncer and non-owner safety

| Option | Description | Selected |
|--------|-------------|----------|
| Parse `pg_get_triggerdef` text for the arguments | researcher recommendation | |
| Split the `tgargs` bytea on NUL in Elixir | the format PostgreSQL documents; no text parsing | ✓ (orchestrator override) |
| Independent parameterized catalog queries, with no session state | today's `health.ex` pattern | ✓ |
| Per-test `CREATE ROLE` plus `SET LOCAL ROLE`; the PgBouncer case in the topology lane | no existing precedent, so this phase originates it | ✓ |
| Rescue a config `ArgumentError` into an `:invalid_config` finding | researcher suggestion | (deferred) |
| Let a malformed config raise | consistent with gen.triggers and reads | ✓ (orchestrator override) |

## Adopter twin shapes

| Option | Description | Selected |
|--------|-------------|----------|
| Fit the shapes into the help-desk domain | reads like a real app | |
| A labelled `shape_*` fixture set | honest home for the 60-byte and two-schema shapes | ✓ |
| Commit the generated migrations and pin them with a drift contract test | matches the existing committed trigger migrations | ✓ |
| Generate the migrations at CI time | no reviewable diffs | |
| Evaluator reuses the example app's migrations | couples two separate projects | |
| Evaluator-local fixtures | keeps the evaluator independent of the example app | ✓ |
| Second schema: the Threadline storage schema | unsafe | |
| Second schema: a host-owned `shapes` schema | clean | ✓ |

**Choice:** as selected. Round trips live primarily in the example app, with a mirror in the evaluator. The fixtures stay out of seeds and out of operator query paths, and the browser lane must be unchanged.

## Claude's Discretion

- Module split, message wording, fixture names, the non-`id` key type, test layout.

## Deferred Ideas

- `--strict` warnings-fail mode (ROADMAP backlog)
- `--all-schemas` for the Mix tasks
- An `:invalid_config` finding code
- Findings in the operator UI (parked until 1.0.0)
