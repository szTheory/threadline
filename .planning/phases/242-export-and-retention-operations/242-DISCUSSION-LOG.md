# Phase 242: Export and retention operations - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `242-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-10-10  
**Phase:** 242-export-and-retention-operations  
**Areas discussed:** Export lifecycle and download journey; confirmed retention prune journey; LiveView disconnect/reconnect and duplicate-mutation behavior.

## Export lifecycle and download journey

| Option | Description | Selected |
|--------|-------------|----------|
| Transient LiveView state or push-only events | Simple, but remount/reconnect can lose the only lifecycle result. | |
| Persisted actor-owned job with reconnect reconciliation | Reuses the existing job row and access boundary; keeps pending/running/failure/completion durable. | ✓ |
| New event/notification infrastructure | Faster visible updates, but adds architecture/dependency surface without improving authority. | |

**User's choice:** `[--auto]` The maintainer authorized auto-following recommendations; selected persisted job state and existing protected download delivery.
**Notes:** Rebuild a local Timeline path from supported validated filters, including the unfiltered case. Do not deduplicate deliberate new exports. Test actual file delivery and missing/expired outcomes; metadata alone is insufficient.

## Confirmed retention prune journey

| Option | Description | Selected |
|--------|-------------|----------|
| Improve confirmation copy and keep current asynchronous gap | Low effort, but an accepted cast can disappear before a run becomes visible and exceptions may not be recorded. | |
| LiveView-only pending state | Closes the click race in one socket but is lost on remount/reconnect. | |
| Persist acceptance and terminal result on one existing run record | Small internal runner handoff correction; reconnect can observe accepted work and partial/failed outcome. | ✓ |

**User's choice:** `[--auto]` The maintainer authorized auto-following recommendations; selected the same persisted run record, active-only coalescing, and existing advisory locking.
**Notes:** No migration is needed because run status is unconstrained text and existing outcome fields can be reused. Explain the global configured storage-schema scope, strict cutoff, and conditional empty-transaction deletion. Preserve server authorization, exact confirmation, and audit-before-trigger. Never expose raw exception details or claim historical settings not stored by the run.

## LiveView disconnect/reconnect and duplicate-mutation behavior

| Option | Description | Selected |
|--------|-------------|----------|
| CSS pointer blocking and visual feedback only | Leaves keyboard activation available and does not protect unmarked mutations. | |
| Keep page readable; natively disable only mutations and refresh authoritative state | Preserves useful read-only information while making unavailable controls unavailable to pointer and keyboard. | ✓ |
| Make the whole page inert | Suppresses useful read-only evidence and harms discoverability/accessibility. | |

**User's choice:** `[--auto]` The maintainer authorized auto-following recommendations; selected the focused native mutation gate and persisted-state reconciliation.
**Notes:** Announce reconnect status without moving focus. Resume mutations only after a fresh server state. Prevent offline activation and in-flight double submits; do not promise exactly-once behavior or replay an uncertain request.

## Cross-cluster adversarial check

Three targeted reviews examined export, retention, and interaction from product, architecture, security, operations, accessibility, and dependency-minimization perspectives; a follow-up checked cross-cluster consistency. Exports remain repeatable requests, while retention requests coalesce only while work is active. Both recover from persisted state and neither blindly replays a mutation. No major maintainer decision remains.

## the agent's Discretion

- Choose concise status copy, state grouping, and existing components/styles within `242-CONTEXT.md`.
- Keep the retention refactor internal and preserve existing public return/error behavior.
- Use focused ExUnit and mounted-browser checks; document any limits in live reconnect proof.

## Deferred Ideas

- Exactly-once/idempotency contracts, persisted historical policy snapshots, preview counts, notification infrastructure, new dependencies/routes/public APIs, and tenant-scoped retention.
