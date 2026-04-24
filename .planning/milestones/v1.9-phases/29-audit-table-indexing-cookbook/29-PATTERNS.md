# Phase 29 — Pattern map

Analog files and conventions for executors.

| Role | New / touched | Closest analog | Notes |
|------|---------------|----------------|-------|
| Long-form guide + ExDoc | `guides/audit-indexing.md` | `guides/domain-reference.md`, `guides/production-checklist.md` | Same `guides/` root; Reference group via `mix.exs` extras |
| Doc contract (medium) | `test/threadline/audit_indexing_doc_contract_test.exs` | `test/threadline/support_playbook_doc_contract_test.exs` | `File.cwd!()` + `Path.join` + `String.contains?/2`; fewer literals than LOOP-04 |
| Docs index | `mix.exs` `docs/0` → `extras:` | Existing `guides/*.md` entries | Insert `"guides/audit-indexing.md"` in alphabetical order with other guides |
| Thin pointer | `guides/domain-reference.md` | Phase 28 support-playbook pointer blocks | Short subsection; link only — no full DDL duplicate |
| Operator navigation | `guides/production-checklist.md` | LOOP-04 cross-links to domain-reference | Add concrete path to `audit-indexing.md` + optional heading anchor |

**Code excerpts (join semantics — must match prose):**

```elixir
# Inner join when correlation filter active (timeline_query pipeline)
join(query, :inner, [ac, at], aa in AuditAction,
  on: at.action_id == aa.id and aa.correlation_id == ^cid
)
```

```elixir
# Export without correlation_id — LEFT JOIN actions
|> join(:left, [ac, at], aa in AuditAction, on: at.action_id == aa.id)
```

**Shipped index names (verbatim for “Installed defaults” section):**

- `audit_transactions_txid_idx`
- `audit_changes_transaction_id_idx`, `audit_changes_table_name_idx`, `audit_changes_captured_at_idx`
- `audit_actions_actor_ref_idx`, `audit_actions_inserted_at_idx`, `audit_actions_name_idx`

## PATTERN MAPPING COMPLETE
