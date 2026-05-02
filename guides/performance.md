# Performance

<!-- PERF-01 -->
<!-- PERF-02 -->
<!-- PERF-03 -->

Threadline is built with performance in mind. Because audit logging happens via Postgres triggers in the same transaction as your primary mutations, understanding the performance impact is critical.

## Workload Presets

We run our benchmarking suite against three standard workload presets to provide realistic expectations:

*   **`cold_single_table`**: A bare database with a single table, no existing data, to measure raw trigger overhead.
*   **`warm_loaded`**: A database pre-populated with realistic volumes of data, foreign keys, and indexes to measure the impact of updates on a busy table.
*   **`concurrent_purge`**: Measures throughput while Threadline's retention system is actively deleting old audit logs in the background.

```yaml BENCHMARK-ENV
postgres: 15.3
otp: 26.2
elixir: 1.16.1
hardware: Apple M2, 16GB RAM
preset: cold_single_table
changed_from: true
```

## Throughput Baselines

The following numbers represent operations per second (IPS) and average time per operation under the `cold_single_table` preset.

| Operation | IPS | Average Time |
|-----------|-----|--------------|
| Insert | {{insert_ips}} | {{insert_avg}} |
| Update | {{update_ips}} | {{update_avg}} |
| Delete | {{delete_ips}} | {{delete_avg}} |

## Impact on Primary Transactions

Because Threadline audit triggers execute synchronously within your application's database transactions, they add a small latency overhead to every mutated row.

**PgBouncer and Transaction Mode:** Threadline is fully compatible with PgBouncer operating in transaction mode. Because correlation variables (like user ID and request ID) are passed via `SET LOCAL` at the start of your transaction block, they remain bound to the connection exactly for the duration of that specific transaction and do not leak to other requests sharing the same pool.

## Capture-time cost knobs

You can tune the performance impact of Threadline using several configuration options:

*   **Redaction:** Redacting fields takes slightly more CPU time inside the trigger.
*   **Changed From:** Enabling `changed_from` tracking requires comparing the `OLD` and `NEW` records, adding marginal overhead to `UPDATE` operations.
*   **Filtering:** Using `when` conditions on triggers allows you to skip auditing entirely for noisy updates.
