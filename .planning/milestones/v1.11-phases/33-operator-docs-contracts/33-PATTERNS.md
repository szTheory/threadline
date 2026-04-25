# Phase 33 — Pattern map

Analogs for executor agents (read before editing).

| Planned touch | Role | Closest analog | Notes |
|---------------|------|----------------|-------|
| `guides/domain-reference.md` | Long-form operator guide | Existing **Support incident queries** section + **Export** section | Same voice: tables + contract marker + “Replace before run” where SQL appears only in Support block |
| `guides/production-checklist.md` | Checklist cross-links | Lines 61–76: `domain-reference.md#…` links | Add one more fragment link; keep checklist tone |
| `test/threadline/exploration_routing_doc_contract_test.exs` | Doc contract | `test/threadline/support_playbook_doc_contract_test.exs` | `read_rel!/1`, async case, string assertions on repo-relative paths |

**Excerpts (support playbook test):**

```elixir
defp read_rel!(segments) when is_list(segments) do
  @repo_root |> Path.join(Path.join(segments)) |> File.read!()
end
```

Use the same `@repo_root File.cwd!()` pattern so CI resolves guides from project root.
