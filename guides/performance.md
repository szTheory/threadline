# Performance

<!-- PERF-01 -->
<!-- PERF-02 -->
<!-- PERF-03 -->

Threadline is built with performance in mind. Because audit logging happens via Postgres triggers in the same transaction as your primary mutations, understanding the performance impact is critical.

## Workload Presets

We run our benchmarking suite against three standard workload presets to provide realistic expectations:

* **`cold_single_table`**: A bare database with a single table, no existing data, to measure raw trigger overhead.
* **`warm_loaded`**: A seeded audit dataset used to measure query latency once the timeline tables are already populated.
* **`concurrent_purge`**: The harness reserve for measuring write/query behavior while retention deletes run in parallel.

```yaml BENCHMARK-ENV
postgres: 14.17 (Homebrew)
otp: 28.4.1
elixir: 1.19.5
hardware: Apple M2, 16GB RAM
preset: cold_single_table
changed_from: true
```

## Throughput Baselines

The following numbers represent operations per second (IPS) and average time per operation under the `cold_single_table` preset.

| Operation | IPS | Average Time |
|-----------|-----|--------------|
| Insert | 5.14 K | 194.69 &micro;s |
| Update | 4.40 K | 227.14 &micro;s |
| Delete | 10.85 K | 92.19 &micro;s |

## Warm-loaded query baselines

The same harness also captures query-time numbers after the audit tables are seeded:

```yaml BENCHMARK-ENV
postgres: 14.17 (Homebrew)
otp: 28.4.1
elixir: 1.19.5
hardware: Apple M2, 16GB RAM
preset: warm_loaded
changed_from: true
```

| Query | IPS | Average Time |
|-------|-----|--------------|
| `timeline_by_table` | 148.16 | 6.75 ms |
| `timeline_unfiltered` | 1.26 | 794.48 ms |

## Impact on Primary Transactions

Because Threadline audit triggers execute synchronously within your application's database transactions, they add a small latency overhead to every mutated row.

**PgBouncer and Transaction Mode:** Threadline is fully compatible with PgBouncer operating in transaction mode. Because correlation variables (like user ID and request ID) are passed via `SET LOCAL` at the start of your transaction block, they remain bound to the connection exactly for the duration of that specific transaction and do not leak to other requests sharing the same pool.

That wording is backed by the `verify-pgbouncer-topology` CI job and the topology contract tests that keep pooler behavior in the default verification story.

## Capture-time cost knobs

You can tune the performance impact of Threadline using several configuration options:

* **Redaction:** Redacting fields takes slightly more CPU time inside the trigger.
* **Changed From:** Enabling `changed_from` tracking requires comparing the `OLD` and `NEW` records, adding marginal overhead to `UPDATE` operations.
* **Filtering:** Using `when` conditions on triggers allows you to skip auditing entirely for noisy updates.

The side-by-side update benchmark from `redaction_and_changed_from_bench.exs` is the published reference point for those knobs:

| Scenario | IPS | Average Time | Comparison note |
|----------|-----|--------------|-----------------|
| `update_baseline` | 1.30 K | 766.88 &micro;s | 2.71x slower than the fastest run |
| `update_changed_from` | 2.50 K | 399.64 &micro;s | 1.41x slower than the fastest run |
| `update_redacted` | 3.53 K | 283.13 &micro;s | fastest run in this sample |
| `update_both` | 2.85 K | 351.39 &micro;s | 1.24x slower than the fastest run |

`concurrent_purge` remains part of the reproducible harness, but its published numbers should be refreshed from a clean rerun after the helper path fix so new artifacts land in the tracked `bench/baselines` directory again.
