# Phase 26 — Technical research: Support playbooks & doc contracts

**Question:** What do we need to know to plan LOOP-02 / LOOP-04 well?

## Summary

- **LOOP-02** is documentation-only in two existing ExDoc extras: `guides/domain-reference.md` (canonical depth) and `guides/production-checklist.md` (compact table + links). No LiveView, no new capture APIs.
- **Operator doc patterns** in-repo: `Threadline.StgDocContractTest` and `Threadline.CiTopologyContractTest` use `read_rel!/1`, `async: true`, and `String.contains?/2` on stable headings plus optional marker tokens (`STG-*`, `CI-*`). LOOP-04 should add a **third** focused module per **26-CONTEXT D-3** (not README tests).
- **API surface** for “API / Mix” column: `Threadline.Query.timeline/2`, `validate_timeline_filters!/1`, `export_changes_query/1`; `Threadline.Export` (`to_csv_iodata/2`, `to_json_document/2`, `stream_changes/2`, `count_matching/2`); `mix threadline.export` and other `mix threadline.*` tasks already referenced in `domain-reference.md` (retention, verify_coverage, continuity).
- **Correlation semantics (Phase 25):** When documenting Q3, prose must state **strict** semantics: `:correlation_id` filter only returns changes whose transaction **inner-joins** to an `AuditAction` with that correlation — orphan capture rows without `action_id` / matching action **do not** appear. Cite `lib/threadline/query.ex` moduledoc and **25-CONTEXT.md**.
- **SQL style:** Hybrid golden `SELECT` + “Replace before run” placeholder block (`your_schema` convention locked in implementation). Bounded queries (`LIMIT`, `:from`/`:to`), read-only/replica expectation once per section.

## Risks / pitfalls

- Duplicating long SQL in **both** guides violates D-1; checklist must use **pointers** to `domain-reference.md` anchors.
- Brittle tests if we assert entire markdown tables; prefer **heading lines**, optional **marker token** `LOOP-04-SUPPORT-INCIDENT-QUERIES`, and a **lightweight** invariant that the at-a-glance table lists all five questions (e.g. rows numbered 1–5 or contains all five `### N.` prefixes in domain-reference).

## References (read during execution)

- `.planning/phases/26-support-playbooks-doc-contracts/26-CONTEXT.md`
- `.planning/REQUIREMENTS.md` (evidence-driving questions 1–5, LOOP-02, LOOP-04)
- `.planning/phases/25-correlation-aware-timeline-export/25-CONTEXT.md`
- `guides/domain-reference.md`, `guides/production-checklist.md`
- `test/threadline/stg_doc_contract_test.exs`, `test/threadline/ci_topology_contract_test.exs`
- `lib/threadline/query.ex`, `lib/threadline/export.ex`, `lib/mix/tasks/threadline.export.ex`

## Validation Architecture

This phase validates through **ExUnit** doc-contract tests plus full **`mix test`** / **`mix ci.all`**.

| Dimension | How we sample |
|-----------|----------------|
| Doc anchors | New `test/threadline/support_playbook_doc_contract_test.exs` asserts headings + marker after each substantive edit to guides. |
| Regression | `mix test test/threadline/support_playbook_doc_contract_test.exs` after guide tasks; `mix test` before phase close. |
| Operator accuracy | Manual spot-read of correlation subsection against `Threadline.Query` moduledoc (not automated). |

**Nyquist note:** Guide changes without running the new test file risk silent anchor rot — **wave 2** must land tests in the same phase, not deferred.

---

## RESEARCH COMPLETE
