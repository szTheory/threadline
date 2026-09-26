# Threadline Benchmarking Harness

This `bench/` directory contains an independent Mix project designed exclusively for performance benchmarking.

## Purpose

By keeping benchmarks in a separate sibling application, we guarantee that benchmarking dependencies (`benchee`, `benchee_html`, etc.) do not leak into the root `threadline` library dependencies. This structure enforces a strict boundary while still allowing us to measure the root project via a local path dependency.

## Workload Presets

The harness supports three primary workload presets designed to test different aspects of Threadline's performance:

* **`cold_single_table`**: Benchmarks performance against a single table without pre-existing cache or loaded state.
* **`warm_loaded`**: Benchmarks performance with a fully warmed state and loaded relationships.
* **`concurrent_purge`**: Simulates heavy concurrent retention purges alongside regular data ingestion.

These presets are seeded via `scripts/seed_audit_changes.exs` and cleaned up with `scripts/teardown.exs`.

## `pk_capture_bench.exs`: capture overhead of primary-key resolution

Measures the per-row overhead the primary-key-agnostic capture trigger body
adds over the frozen 0.10.2 body (`fixtures/threadline_capture_changes_v0_10_2.sql`).
Installs both bodies, plus a sensitivity-control body whose key extraction
reads `pg_index` per row, as three differently named functions in the same
database. Each variant runs on its own freshly created table: `INSERT ...
SELECT generate_series`, then `UPDATE` every row, then `DELETE` every row,
timed in-server with `clock_timestamp()` via a single `EXECUTE` per
statement, alternating variant order across reps so machine drift does not
favor one side. A two-column composite-key table is also timed on the
current body only, reported against the current body's single-key median.

It is in-server (not a client round-trip benchmark like
`audit_capture_bench.exs`) because the thing under test is PL/pgSQL
execution cost inside the trigger, and client round trips would dwarf a
10% difference in that. The pass bar is that the current body's per-row
median is at most 1.10x the 0.10.2 median on insert, update and delete; a
sensitivity control (the `pg_index`-per-row variant) must come out at
least 1.25x, proving the bench can detect a regression of the size the
bar guards, or the run fails even if the real body passes.

`BENCH_PK_ROWS` (default 50000) and `BENCH_PK_REPS` (default 5) control
row count and rep count. Results are printed and written to
`baselines/pk_capture_bench.md` with commit SHA, PostgreSQL server
version, Elixir/OTP versions and a machine description.

This benchmark is **not a CI gate** — shared CI runners are too noisy for
a 10% bar. It runs as part of `mix verify.bench`, a maintainer command, not
part of `mix ci.all`.
