# Phase 12 — Pattern map

Analogs in codebase for redaction / capture work.

## Policy & codegen

| New / changed | Role | Closest analog | Excerpt / convention |
|---------------|------|----------------|----------------------|
| Per-table trigger SQL with options | Codegen | `Threadline.Capture.TriggerSQL.install_function_for_table/2` | Takes `store_changed_from`, `except_columns`; returns full `CREATE OR REPLACE FUNCTION` string |
| Mix migration file | Output | `Mix.Tasks.Threadline.Gen.Triggers.migration_content/3` | `execute #{inspect(sql)}` for each statement |
| CLI flags | UX | `--store-changed-from`, `--except-columns` | `OptionParser.parse` with `strict:` |

## Testing

| New tests | Analog file | Pattern |
|-----------|-------------|---------|
| Redaction integration | `test/threadline/capture/trigger_changed_from_test.exs` | `setup_all` creates table + installs SQL; `setup` truncates + drops trigger; `Repo.all(AuditChange)` assertions on `data_after`, `changed_from`, `changed_fields` |

## Config

| Surface | Analog | Location |
|---------|--------|----------|
| Library consumer config | `:verify_coverage` | Search `config :threadline` in host `config/*.exs` and `lib/` |

## SQL safety (Path B)

| Constraint | Where enforced today | Extend |
|------------|---------------------|--------|
| No session writes in trigger | `TriggerSQL` moduledoc + `current_setting(..., true)` read only | Keep invariant in any new shared core |

---

## PATTERN MAPPING COMPLETE
