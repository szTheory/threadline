# Phase 230: Rebalance, Net-Suite Check and 0.12.0 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-02
**Phase:** 230-rebalance-net-suite-check-and-0-12-0
**Mode:** advisor (research-then-recommend; maintainer asked for one coherent one-shot set)
**Areas discussed:** Cut vs merge disposition, Net-suite comparison basis, Release title + breaking signal, Close vs land ordering

---

## Cut vs merge disposition

| Option | Description | Selected |
|--------|-------------|----------|
| Line-item split by rubric | Keep derived/security assertions, delete prose-to-literal ones; whole-file cut only if 100% condemned | ✓ |
| Whole-file cut/merge only | Treat each file atomically | |
| Leave as-is | Defer | |

**Notes:** All 4 unaudited files classified. Two storage_schema files are KEEP whole; coverage/policy_show are mostly KEEP. Fold-into-another-file rejected because it relocates the anti-pattern. Orchestrator added the security-boundary-sentence exception in operator_surface_doc_contract_test.

## Net-suite comparison basis

| Option | Description | Selected |
|--------|-------------|----------|
| Partitioned CI step only vs SUITE-01 | Trivially passes | |
| CI step sum vs 846 s, ≤+10% | Existing tool, cache-hit precondition | ✓ (gate) |
| Local mix test median | Too noisy (documented 52-56 s swing) | context only |
| Local partition sum | No true SUITE-01 equivalent | sanity only |

**Notes:** The orchestrator verified that `bin/ci-test-partitions` runs partitions concurrently inside each lane job, so the lane-step sum still hides work growth. Serial-equivalent work is disclosed with attribution and is non-gating (D-07).

## Release title + breaking signal

| Option | Description | Selected |
|--------|-------------|----------|
| Plain `feat:` | No ⚠ section despite 3 breaks | |
| `feat!:` no footer | One breaking bullet only | |
| `feat!:` + 3 `BREAKING CHANGE:` footers | Matches 0.11.0 precedent, full signal | ✓ |

**Notes:** The researcher's subject listed the removals. The orchestrator changed it to lead with capabilities, since the footers carry the breaks. The researcher flagged that there's no upgrading-to-0.12 guide. Decision: CHANGELOG Fix lines suffice, because no backfill is needed (D-13).

## Close vs land ordering

| Option | Description | Selected |
|--------|-------------|----------|
| Close first, land after | Contradicts SC4 | |
| Land+release as 230's final plan, audit/close after | v1.43 phase-223 precedent | ✓ |
| Hybrid draft audit | Extra pass, no precedent | |

**Notes:** The researcher proposed a `land/v1.44-226-230` cherry-pick branch. The orchestrator verified the merge base is origin/main fc47af60 and that 224/225 content diffs empty, so it chose a direct squash of milestone/v1.44 (D-15).

## Claude's Discretion
- Squash subject wording, CONTRIBUTING placement, per-partition duration mechanism.

## Deferred Ideas
- Operator-route integration test if missing; lint for moduledoc KEEP-criterion convention.
