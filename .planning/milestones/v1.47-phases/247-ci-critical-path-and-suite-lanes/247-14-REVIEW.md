# Phase 247-14 Independent Review

## Scope

Reviewed `bin/ci-test-partitions`, the three `test/partition_weights*.txt` files, and `test/threadline/ci_topology_contract_test.exs` against commits `0848c2f1..HEAD` and the working-tree diff. Read the phase plan and D-10/D-11/D-12 context. No source files were modified and no suites were run concurrently with the parent agent.

## Findings

No open findings.

## Resolved During Follow-up

### WR-01: Routing self-test did not prove lane-specific weights reached assignment — RESOLVED

The follow-up diff gives current and latest distinct sentinel weights, compares each route's `assignment.tsv` against an assignment generated from its expected weights file, and mutates the sandbox runner to use `WEIGHTS_REL` while keeping the latest label. The latest assignment comparison requires that mutation to diverge. This closes the previously reported routing coverage gap. I reviewed this change statically and did not run suites, per request.

## Review Notes

- The production path currently passes `selected_weights` to `assign_files`, and the selector rejects unknown lanes before compilation.
- The strict ingestion logic checks the exact lane inventory, three distinct numeric run directories with partitions 1–4, duplicate/missing/stale observations, output-path allowlisting, and same-directory atomic replacement. Zero-ms rows remain accepted and generated medians are floored at 1 as specified.
- No additional source-level correctness or security finding was confirmed in the scoped changes. Full and scoped real-suite execution remained pending with the parent agent at follow-up review time.
