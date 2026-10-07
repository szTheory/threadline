# Supported PostgreSQL table shapes

<!-- TABLE-SHAPES-01 -->

## Will this table work before I install triggers?

Use this matrix before running `mix threadline.gen.triggers`. A supported shape
still has the conditions in its row.

| Table shape | Status | Required conditions | Operational caveat and evidence |
| --- | --- | --- | --- |
| One-column, composite, or non-`id` primary key | Supported | Every key column uses `smallint`, `integer`, `bigint`, `text`, `varchar`, `char`, `citext`, `uuid`, `date`, `timestamp without time zone`, an enum, or a domain over one of those types. | The key is resolved from the table's primary key and recorded by column name. Evidence: `lib/threadline/capture/primary_key_sql.ex`; `test/threadline/capture/trigger_pk_shapes_test.exs`; `test/threadline/capture/trigger_migrate_time_errors_test.exs`. |
| Table without a primary key | Supported with `primary_key:` | Set `primary_key: ["column", ...]` for that table. The declared columns must exactly equal the key columns of a valid, ready, immediate, unconditional, non-expression unique index; every indexed key column must be `NOT NULL`. | Subsets, supersets, `INCLUDE` columns, partial indexes, expression indexes, deferred indexes, and nullable key columns do not qualify. Evidence: `lib/threadline/capture/primary_key_sql.ex`; `test/threadline/capture/trigger_pk_override_test.exs`. |
| Schema-qualified table | Supported as `schema.table` | Use the schema-qualified name for a non-`public` schema in table configuration and `--tables`. | Resolution preserves the schema when the table is on `search_path`. Evidence: `lib/threadline/capture/naming.ex`; `test/threadline/capture/trigger_pk_shapes_test.exs`. |
| Long derived trigger, function, or migration names | Supported within PostgreSQL's identifier limit | PostgreSQL's default identifier limit is 63 **bytes**. The source schema and table names must themselves fit that limit. | Threadline keeps derived names within 63 bytes: trigger names retain the legacy cut, while long function and migration names use deterministic hashes. Evidence: `lib/threadline/capture/naming.ex`; `test/threadline/capture/naming_test.exs`; [PostgreSQL identifier rules](https://www.postgresql.org/docs/current/sql-syntax-lexical.html). |
| `char(n)` key | Supported | Use a supported fixed-width character key. | Keep the original blank padding when using a stored key for history after its table or key configuration changes; see [audit indexing](audit-indexing.md#table-primers) and `test/threadline/capture/trigger_migrate_time_errors_test.exs`. |
| Partitioned table | Supported | Install the generated trigger on the partitioned parent. | PostgreSQL clones its row trigger to partitions. Captured `table_name` records the physical leaf relation that received the row. Evidence: `lib/threadline/capture/trigger_sql.ex`; `test/threadline/capture/trigger_pk_shapes_test.exs`; [PostgreSQL trigger behavior](https://www.postgresql.org/docs/current/sql-createtrigger.html). |
| Unlogged table | Accepted with durability risk | No additional Threadline option is required. | PostgreSQL does not WAL-log unlogged source data and truncates it after a crash or unclean shutdown. The surviving audit trail may no longer match the source table's post-crash state. Evidence: the generated row trigger in `lib/threadline/capture/primary_key_sql.ex`; [PostgreSQL unlogged tables](https://www.postgresql.org/docs/current/sql-createtable.html#SQL-CREATETABLE-UNLOGGED). |
| View | Unsupported | Capture requires a row-level `AFTER INSERT OR UPDATE OR DELETE` trigger on a table. | Views do not provide this row-trigger installation surface. Evidence: `lib/threadline/capture/primary_key_sql.ex`; [PostgreSQL CREATE TRIGGER](https://www.postgresql.org/docs/current/sql-createtrigger.html). |

## Example: configure a table without a primary key

For a table whose only qualifying unique index covers non-null `post_id` and
`tag_id` columns, declare that exact key set:

```elixir
config :threadline, :trigger_capture,
  tables: %{"posts_tags" => [primary_key: ["post_id", "tag_id"]]}
```

The order in the option becomes the captured key order. See the
[upgrade path](upgrade-path.md) for release compatibility and
[the stability policy](stability.md) for the 1.x database contract.

## Next steps

- [Return to Getting Started](getting-started-saas.md).
- [Review the upgrade path](upgrade-path.md).
- [Read the stability policy](stability.md).
