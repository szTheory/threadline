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
