# Phase252 implementation research

Status: source research complete; runtime proof pending. Base bc640b63. Three independent clusters and one adversarial synthesis, including a bounded worker-target follow-up, produced one coherent recommendation. No new tests/apps/DB/browser were run during this research.

## Recommendation

Preserve and prove Export; implement the authorized transient Retention dry run with same-worker target coordination and server-side confirmation gating; add Operations stories sharing production rendering and the existing static fixture/inventory boundary. The locked decisions are in252-CONTEXT.md. No unresolved architect choice remains under ADM23–25.

## Evidence and alternatives

- [Exports](../../../research/2026-11-13-phase252/exports.md): shipped scoped immediate versus unscoped queue split; scope persistence would expand the public/security/persistence contract and is rejected here.
- [Retention](../../../research/2026-11-13-phase252/retention.md): existing dry-run path and missing UI preview; durable lineage/migration rejected. Existing event authorization, audit and run persistence remain authoritative.
- [Catalog](../../../research/2026-11-13-phase252/catalog.md): Operations category uses existing Storybook page API and production components; exact markup sharing is narrow, not a general page engine. PhoenixStorybook is1.2.0, Threadline is1.1.0.
- [Adversarial synthesis and target seam](../../../research/2026-11-13-phase252/adversarial.md): counts are sequential/full-schema and ignore batch limits; seeders write and must not run in stories; mount and worker targets can differ. Prefer an explicit narrow internal snapshot/guarded same-PID call in the existing undocumented worker over debug-state introspection. Supported public APIs remain unchanged.

## Implementation guidance

Keep every operation's options server-owned. Authorize before preview and again before confirmation, reject target/schema/restart mismatches before counts/audit/run, recheck target after counting, and never reroute a guarded request to a replacement PID. A valid zero preview is not an unavailable read. Preview failure clears/refuses confirmation; a forged direct prune event cannot bypass server-held successful preview. Do not infer atomicity, returned cutoff or guaranteed totals from dry_run. Preserve actual persisted statuses/count fields and their limitations.

Use existing named test entrypoints and owners in the peer memos; add focused recurring negative contracts only for new failure classes. Static story helpers materialize assigns without Repo/files/seed calls and reference the existing semantic identities; actual route tests own permissions/queries/downloads/mutations. Keep source/inventory/browser declarations coupled within each implementation slice and retain malformed/duplicate/wrong-owner controls. One representative ordinary flow plus named boundary cases beats a new cross-product runner.

## Pitfalls and acceptance

The demo test config disables retention by default; positive mounted preview proof needs a separately recorded owned-runtime fixture using existing startup options and a bounded schedule, while preserving matching before/after conditions and original paired data. Pruner startup can update abandoned runs; bind operational rows after ready as well as audit rows. Never use the shared5432 PostgreSQL or silently renew the full-root repeat stop. Existing script/source/app startup guards, unique logs/artifacts and correct PLAYWRIGHT_JSON_OUTPUT_FILE must carry forward. Independent final code/security/six-pillar UI/goal review is required; prepare automated judgment disposition and final sampling records before the last fingerprint.
