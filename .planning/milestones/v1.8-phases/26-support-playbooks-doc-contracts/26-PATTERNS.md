# Phase 26 — Pattern map

Analog code and doc patterns for executors.

## Doc contract tests

| New / target | Analog | Excerpt pattern |
|--------------|--------|------------------|
| `test/threadline/support_playbook_doc_contract_test.exs` | `test/threadline/stg_doc_contract_test.exs` | `@repo_root File.cwd!()`, `read_rel!(["guides", ...])`, `String.contains?/2`, `async: true` |
| Marker + heading asserts | `test/threadline/ci_topology_contract_test.exs` | Multiple `assert String.contains?(doc, "TOKEN")` |

## Guide style

| Target | Analog | Notes |
|--------|--------|-------|
| Checklist → domain deep link | `production-checklist.md` → `domain-reference.md#telemetry-operator-reference` | Reuse relative `domain-reference.md#...` links |
| Long operator prose | `guides/domain-reference.md` § Retention, Export | Fenced SQL + prose tables, not SQL inside pipe tables |

## API citations

| Topic | Source of truth file |
|-------|---------------------|
| Timeline filters / correlation | `lib/threadline/query.ex` `@moduledoc` |
| Export | `lib/threadline/export.ex`, `domain-reference.md` § Export |
| Mix export task | `lib/mix/tasks/threadline.export.ex` |

---

## PATTERN MAPPING COMPLETE
