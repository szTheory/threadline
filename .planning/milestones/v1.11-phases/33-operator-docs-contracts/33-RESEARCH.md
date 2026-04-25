# Phase 33 — Research: Operator docs & contracts (XPLO-03)

**Question:** What do we need to know to plan **routing docs + contract tests** well?

## Summary

- **Edit surface:** `guides/domain-reference.md` — insert **`## Exploration API routing (v1.10+)`** immediately **before** `## Support incident queries` (line ~175). The Support block already carries **LOOP-04-SUPPORT-INCIDENT-QUERIES** and the five `### N.` playbooks; the new section is a **skimmable API→intent** layer that links down with one explicit sentence to `#support-incident-queries`.
- **Cross-link:** `guides/production-checklist.md` already links `domain-reference.md#support-incident-queries` in **Support incident queries**; add one bullet or sentence pointing to **`#exploration-api-routing-v110`** (GitHub-style slug for the new heading — verify in plan acceptance).
- **Contracts:** Mirror **`Threadline.SupportPlaybookDocContractTest`** and **`Threadline.AuditIndexingDocContractTest`**: `File.cwd!()` + `Path.join`, read markdown, `assert String.contains?/2` on heading string, marker token, and table substrings (`audit_changes_for_transaction`, `change_diff` or `ChangeDiff`).
- **Public API names** (must match docs — from `lib/threadline.ex`): `history/3`, `timeline/2`, `actor_history/2`, `export_csv/2`, `export_json/2`, `audit_changes_for_transaction/2`, `change_diff/2` → **`Threadline.ChangeDiff`** via delegate.

## Pitfalls

- **Anchor drift:** If the `##` title changes, contract tests and `production-checklist.md` fragment must change together.
- **Duplicating LOOP-04:** Routing table must **not** replace the `| 1 |`…`| 5 |` table; it summarizes **which module/function** first, with SQL detail deferred to Support incident queries.

## Out of scope (locked)

- LiveView, Hex bump, new capture semantics, unified `:transaction_id` on `timeline/2` (Phase 32 deferral).

## Validation Architecture

Phase 33 is **documentation + ExUnit doc contracts** only. Validation is **deterministic string checks** in `test/threadline/exploration_routing_doc_contract_test.exs` plus **`mix test`** on that file (and optionally full `mix test test/threadline/` doc contract group). No database or schema push. After each doc edit task, run **`mix test test/threadline/exploration_routing_doc_contract_test.exs`** when the test file exists; until it exists, rely on **`mix compile --warnings-as-errors`** for accidental code edits (should be none).

---

## RESEARCH COMPLETE
