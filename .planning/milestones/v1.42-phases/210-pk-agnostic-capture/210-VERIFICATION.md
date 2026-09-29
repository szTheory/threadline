---
phase: 210-pk-agnostic-capture
verified: 2026-09-25T22:20:00Z
status: passed
score: 5/5 must-haves verified (roadmap SC1-SC5); CONF-01 capture/config half verified, read half explicitly deferred to Phase 211 per ROADMAP/REQUIREMENTS
covered_files:
  - ".planning/REQUIREMENTS.md"
  - ".planning/phases/210-pk-agnostic-capture/210-01-PLAN.md"
  - ".planning/phases/210-pk-agnostic-capture/210-01-SUMMARY.md"
  - ".planning/phases/210-pk-agnostic-capture/210-02-PLAN.md"
  - ".planning/phases/210-pk-agnostic-capture/210-02-SUMMARY.md"
  - ".planning/phases/210-pk-agnostic-capture/210-03-PLAN.md"
  - ".planning/phases/210-pk-agnostic-capture/210-03-SUMMARY.md"
  - ".planning/phases/210-pk-agnostic-capture/210-04-PLAN.md"
  - ".planning/phases/210-pk-agnostic-capture/210-04-SUMMARY.md"
  - ".planning/phases/210-pk-agnostic-capture/210-05-PLAN.md"
  - ".planning/phases/210-pk-agnostic-capture/210-05-SUMMARY.md"
  - ".planning/phases/210-pk-agnostic-capture/210-CONTEXT.md"
  - ".planning/phases/210-pk-agnostic-capture/210-RESEARCH.md"
  - ".planning/phases/210-pk-agnostic-capture/210-REVIEW.md"
  - "CHANGELOG.md"
  - "bench/README.md"
  - "bench/baselines/pk_capture_bench.md"
  - "bench/fixtures/threadline_capture_changes_v0_10_2.sql"
  - "bench/pk_capture_bench.exs"
  - "guides/configuration-and-commands.md"
  - "lib/mix/tasks/threadline.gen.triggers.ex"
  - "lib/threadline/capture/naming.ex"
  - "lib/threadline/capture/primary_key_sql.ex"
  - "lib/threadline/capture/trigger_capture_config.ex"
  - "lib/threadline/capture/trigger_sql.ex"
  - "lib/threadline/storage_schema.ex"
  - "mix.exs"
  - "test/mix/tasks/threadline/gen_triggers_test.exs"
  - "test/support/legacy_trigger_sql.ex"
  - "test/threadline/capture/collision_free_emission_test.exs"
  - "test/threadline/capture/legacy_trigger_pk_fallback_test.exs"
  - "test/threadline/capture/trigger_body_invariants_test.exs"
  - "test/threadline/capture/trigger_capture_config_test.exs"
  - "test/threadline/capture/trigger_migrate_time_errors_test.exs"
  - "test/threadline/capture/trigger_pk_override_test.exs"
  - "test/threadline/capture/trigger_pk_shapes_test.exs"
  - "test/threadline/capture/trigger_sql_storage_schema_test.exs"
  - "test/threadline/mix/trigger_migration_property_test.exs"
  - "test/threadline/mix/trigger_migration_test.exs"
covered_digest: "v1:sha256:cfe89f28b6da6f44e239ec54654687a2415f1201f79eb512e21518c34132cf79"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 210: PK-Agnostic Capture Verification Report

**Phase Goal:** A table's audit rows record its real primary key, whatever the key's name, type or column count, without adding per-row cost or breaking existing installs.
**Verified:** 2026-09-25T22:20:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth (ROADMAP SC) | Status | Evidence |
|---|------|------|----------|
| SC1 | Writes to tables keyed by non-`id` integer/uuid/text columns, and composite-PK tables (incl. INCLUDE columns), store every key column in `table_pk` with no configuration | ✓ VERIFIED | `mix test test/threadline/capture/trigger_pk_shapes_test.exs` → 13 tests, 0 failures (re-run by verifier). `PrimaryKeySQL.create_trigger_block/3` resolves keys from `pg_index`, excludes INCLUDE columns via first-`indnkeyatts` rule (`lib/threadline/capture/primary_key_sql.ex`). |
| SC2 | Migrating triggers for a PK-less table with no override fails at migrate time, before any host write, naming the table and `primary_key:`; a PK column in `mask`/`exclude` is refused before any capture, naming the column | ✓ VERIFIED | `mix test test/threadline/capture/trigger_migrate_time_errors_test.exs` re-run by verifier → included in the 303-test capture/mix/policy run, 0 failures. Refusal text confirmed in `primary_key_sql.ex` (`RAISE EXCEPTION`, `config/config.exs` HINT, redaction-overlap check). |
| SC3 | An adopter can declare `primary_key: [...]` for a PK-less table; empty lists/invalid names/duplicates/redaction overlap rejected; migration requires a qualifying unique index; override-on-PK-table refused; captured rows carry declared columns | ✓ VERIFIED | `mix test test/threadline/capture/trigger_capture_config_test.exs test/threadline/capture/trigger_pk_override_test.exs` re-run by verifier → included in the 303-test run, 0 failures. `TriggerCaptureConfig.validate_primary_key!/3` and `PrimaryKeySQL` override branch confirmed present and wired from `gen.triggers`. |
| SC4 | A trigger installed by 0.10.x SQL (no arguments) keeps capturing exactly as before; unresolvable key stores `{}` instead of failing the host transaction | ✓ VERIFIED | `mix test test/threadline/capture/legacy_trigger_pk_fallback_test.exs` re-run by verifier → 11 tests, 0 failures. Frozen 0.10.2 fixture (`test/support/legacy_trigger_sql.ex`) compared pairwise against the new global body. |
| SC5 | Per-row trigger overhead is within noise of the 0.10.x baseline, recorded as before/after numbers in the phase verification, and the trigger body contains no catalog lookup | ✓ VERIFIED | Benchmark numbers copied below from `bench/baselines/pk_capture_bench.md` (not re-run, per instruction — executor-run in 210-05). Static no-catalog-lookup guard `test/threadline/capture/trigger_body_invariants_test.exs` re-run by verifier → 65 tests (combined with legacy fallback), 0 failures; the regex scans every generated function body for `pg_*`, `information_schema`, `TG_RELID`, `regclass`, `EXECUTE`. |

**Score:** 5/5 ROADMAP success criteria verified.

### CONF-01 (Requirement, Split Across Phases 210/211)

| Requirement | Status | Evidence |
|---|------|------|
| CONF-01 — capture/config half (this phase) | ✓ VERIFIED | Override declared in `config/config.exs`, validated (`trigger_capture_config_test.exs`), enforced at migrate time against a qualifying unique index with per-index mismatch reasons (`trigger_pk_override_test.exs`), and `TriggerCaptureConfig.load/1` exposes `primary_key:` for the read side to consume (per D-18, confirmed in `210-04-SUMMARY.md`). |
| CONF-01 — read-side half | **Deferred to Phase 211** | ROADMAP and REQUIREMENTS.md explicitly hold CONF-01 as "Pending (read side proven in Phase 211)". This is not a gap in Phase 210 — it is the documented phase boundary (see `210-CONTEXT.md` Phase Boundary section and `210-05-SUMMARY.md` "Next Phase Readiness"). |

REQUIREMENTS.md checkbox state confirmed: CAP-01..CAP-06 are `[x]` and "Complete"; CONF-01 is `[ ]` and "Pending (read side proven in Phase 211)" — consistent with the phase's documented scope split.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/threadline/capture/primary_key_sql.ex` | Shared row-key fragment + DO-block resolver/refusals | ✓ VERIFIED | 464 lines, exists, substantive (contains detected-key resolution, type allowlist, redaction check, override branch, per-index mismatch reasons), imported by `trigger_sql.ex` and `gen.triggers`. |
| `lib/threadline/capture/trigger_sql.ex` | Four function bodies read `TG_ARGV` instead of hardcoded `'id'` | ✓ VERIFIED | Confirmed via `trigger_body_invariants_test.exs` passing (regex-extracted bodies contain no catalog lookups) and `trigger_pk_shapes_test.exs` real-PG proof. |
| `lib/threadline/capture/trigger_capture_config.ex` | `primary_key:` normalization + `validate_primary_key!/3` | ✓ VERIFIED | `defp validate_primary_key!` present; unit-tested in `trigger_capture_config_test.exs` (33 tests total with override test, 0 failures). |
| `test/support/legacy_trigger_sql.ex` | Frozen 0.10.2 fixture, never calls current code | ✓ VERIFIED | `v0_10_2_install_function/2` present; grep for `TriggerSQL\|StorageSchema\.\|Naming\.` inside the file returns 0 per plan 02's acceptance criteria (design contract). |
| `bench/pk_capture_bench.exs`, `bench/baselines/pk_capture_bench.md` | In-server A/B benchmark + recorded numbers | ✓ VERIFIED | Both files exist; baseline file contains commit SHA, PG version, machine, medians table, PASS line (reproduced below). |
| `guides/configuration-and-commands.md`, `lib/mix/tasks/threadline.gen.triggers.ex` moduledoc, `CHANGELOG.md` | Adopter docs for discovery, override, refusals, `{}` semantics | ✓ VERIFIED | `primary_key:` documented in the guide's `trigger_capture` row; "## Primary keys" section present in the mix task moduledoc; CHANGELOG names `timestamptz`, the `{"id": null}` → `{}` change and its "only rows that never had a usable identity" qualifier. |

### Key Link Verification

| From | To | Via | Status |
|---|---|---|---|
| `lib/mix/tasks/threadline.gen.triggers.ex` | `lib/threadline/capture/primary_key_sql.ex` | `redacted_columns:`/`primary_key:` passed from `build_table_capture_spec/4` into `TriggerSQL.create_trigger/3` | ✓ WIRED — confirmed by grep (`redacted_columns` appears ≥1 in both files per plan 03/04 acceptance criteria, re-checked) and by `trigger_migrate_time_errors_test.exs`/`trigger_pk_override_test.exs` passing end-to-end through the actual `mix threadline.gen.triggers` + `Ecto.Migrator.up` path. |
| `lib/threadline/capture/primary_key_sql.ex` | `pg_type` (`typbasetype`) | Domain resolution before the type allowlist check | ✓ WIRED — `typbasetype` present in file; exercised by `pk_int_domain`/`pk_tstz_domain` tests in `trigger_migrate_time_errors_test.exs` (passing). |
| `test/threadline/capture/legacy_trigger_pk_fallback_test.exs` | `bench/fixtures/threadline_capture_changes_v0_10_2.sql` | `File.read!` compared with `LegacyTriggerSQL.v0_10_2_install_function/2` | ✓ WIRED — test re-run by verifier, included in the 11-test legacy-fallback pass. |

### Benchmark (SC5 — copied verbatim from `bench/baselines/pk_capture_bench.md`, not re-run per instruction)

- **Commit:** 128f5cb5b6cfc7f0e4ce9d743b7867774a19b5e8
- **PostgreSQL server_version:** 14.17 (Homebrew)
- **Elixir:** 1.17.3 / **OTP:** 27
- **Machine:** Darwin arm64 (Apple M5 Pro)
- **Rows:** 50000, **Reps:** 5

| Operation | baseline (us/row) | current (us/row) | current/baseline | catalog (us/row) | catalog/baseline | composite (us/row) | composite/current |
|---|---|---|---|---|---|---|---|
| insert | 21.750 | 23.299 | 1.071 | 42.402 | 1.949 | 22.346 | 0.959 |
| update | 35.275 | 33.994 | 0.964 | 54.187 | 1.536 | 36.333 | 1.069 |
| delete | 20.601 | 21.134 | 1.026 | 39.840 | 1.934 | 22.766 | 1.077 |

PASS: current/baseline ≤ 1.10x and catalog/baseline ≥ 1.25x on every operation (D-07 pass bar). The catalog (sensitivity-control) variant coming in at 1.5–1.95x proves the benchmark can see a regression of the size the 1.10x bar guards against, satisfying the phase's non-negotiable prohibition ("MUST NOT report a performance pass from a benchmark that cannot see a regression"). 210-05-SUMMARY.md also records one prior full-row/full-rep run failing the delete bar at 1.125x, rerun once per the plan's explicit instruction (not loosened), and passing cleanly on the recorded rerun — this is an honest disclosure, not a red flag.

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|---|---|---|---|
| CAP-01 | 210-01 | ✓ SATISFIED | `trigger_pk_shapes_test.exs` (13 tests) |
| CAP-02 | 210-01 | ✓ SATISFIED | Composite/INCLUDE-column cases in same suite |
| CAP-03 | 210-03 | ✓ SATISFIED | `trigger_migrate_time_errors_test.exs` (no-PK refusal, subset of 303-test run) |
| CAP-04 | 210-02 | ✓ SATISFIED | `legacy_trigger_pk_fallback_test.exs` (11 tests) |
| CAP-05 | 210-03/04 | ✓ SATISFIED | Redaction-overlap refusal tests in `trigger_migrate_time_errors_test.exs` and `trigger_capture_config_test.exs` |
| CAP-06 | 210-01/05 | ✓ SATISFIED | Static invariant test (65 tests incl. legacy fallback) + recorded benchmark above |
| CONF-01 | 210-04/05 | ✓ SATISFIED (capture half); Phase 211 owns read half | Override validation/enforcement tests; loader exposure recorded in `210-04-SUMMARY.md` |

No orphaned requirements: cross-checking `.planning/REQUIREMENTS.md` lines 42-58 and 123-129 against the seven IDs declared across all five plans' frontmatter shows every ID mapped to exactly one plan, and REQUIREMENTS.md's own status table agrees (CAP-01..06 Complete, CONF-01 Pending-on-211).

### Anti-Patterns Found

None blocking. `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` grep across the phase's `lib/` and `bench/` files (`primary_key_sql.ex`, `trigger_sql.ex`, `trigger_capture_config.ex`, `naming.ex`, `storage_schema.ex`, `gen.triggers.ex`, `pk_capture_bench.exs`) returns nothing. Debt-marker gate: clear.

### Code Review Findings (210-REVIEW.md) — Disposition

0 critical, 4 warnings, 2 info. Judged against the five success criteria:

- **WR-01** (`redaction_check_sql/2`'s "first offending column" pick has no explicit `ORDER BY`): cosmetic — the migration still refuses correctly regardless of which offending column is named first; does not affect SC2's "message names the column" guarantee (a column is still named, just not guaranteed-first under a future planner change). Non-blocking.
- **WR-02** (HINT snippets don't escape embedded double quotes in column names): edge case affecting only tables with a PK column literally containing a `"` character; advisory text only, never executed as SQL, cannot cause an incorrect capture. Non-blocking.
- **WR-03** (`primary_key:` override identifier check is stricter than what a detected key tolerates, rejecting legally-quoted-but-irregular column names): this is a **known, deliberate** consequence of D-15 ("names over 63 bytes (reuse the NAME-01 identifier check)"), not an accidental gap — the context doc explicitly directs reusing the same identifier validator. It narrows the override surface but does not violate SC3, which only requires validation of empty lists/invalid names/duplicates/overlap, all of which are correctly enforced. Non-blocking, but genuinely undocumented as a limitation; worth a follow-up doc note, not a phase gap.
- **WR-04** (mix task's private `table_token/1` duplicates `Naming.table_token/1`): duplication risk for future drift, not a present-day correctness issue — both implementations agree today. Non-blocking.
- **IN-01, IN-02**: both acknowledged as harmless/cosmetic by the reviewer. Non-blocking.

None of the four warnings or two info notes falsifies any of the five ROADMAP success criteria or the CAP-*/CONF-01 must-haves; none is a data-loss, security, or correctness defect. Disposition: accepted as-is for this phase, consistent with the reviewer's own "none of these need to block a ship" judgment.

### Behavioral Spot-Checks / Re-Run Evidence (this verifier's own execution, not SUMMARY claims)

| Command | Result | Status |
|---|---|---|
| `mix test test/threadline/capture/trigger_pk_shapes_test.exs` | 13 tests, 0 failures | ✓ PASS |
| `mix test test/threadline/capture/trigger_body_invariants_test.exs test/threadline/capture/legacy_trigger_pk_fallback_test.exs` | 65 tests, 0 failures | ✓ PASS |
| `mix test test/threadline/capture/trigger_migrate_time_errors_test.exs test/threadline/capture/trigger_pk_override_test.exs test/threadline/capture/trigger_capture_config_test.exs` | 55 tests, 0 failures | ✓ PASS |
| `mix test test/threadline/capture/ test/threadline/mix/ test/mix/tasks/threadline/gen_triggers_test.exs test/threadline/policy/ test/threadline/source_size_contract_test.exs` | 9 properties, 303 tests, 0 failures | ✓ PASS |
| `mix test test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs test/threadline/public_surface_contract_test.exs` | 65 tests, 0 failures | ✓ PASS |
| `mix test test/threadline/capture/collision_free_emission_test.exs` (Phase 209 regression check) | 5 tests, 0 failures | ✓ PASS |
| `mix credo --strict` | 3743 mods/funs, no issues | ✓ PASS |
| `git status --porcelain` (no source/test modification, no accidental migration-file commits) | Only pre-existing unrelated `.planning/WINDOWS.md`, `.planning/config.json`, `.tool-versions` — no phase-210 files touched | ✓ CLEAN |

`mix ci.all` itself was not re-run in full by this verifier (long-running: dialyzer + full suite + browser lane); its constituent pieces most relevant to this phase (capture/mix/policy tests, doc contracts, credo) were re-run directly above and all pass. `mix dialyzer` and `mix verify.example_browser` were not independently re-run; 210-05-SUMMARY.md's claim of a clean `mix ci.all` (dialyzer clean, xref clean, verify.example 117/0, verify.example_browser 318 passed/26 skipped) is accepted as SUMMARY evidence for those two sub-steps only, consistent with the project's documented healthy browser-lane baseline (`screenshot-8-failures-pre-existing` note — note: 210-05 reports 26 skipped rather than a fixed 8-failure count, which is a `verify.example_browser` skip count, not the standalone Playwright failure count the memory note describes; these are different commands and not a discrepancy).

### Human Verification Required

None. All must-haves are automatable and were automated (config validation, real-PG migrate-time behavior, static SQL-body invariants, and a recorded in-server benchmark with a proven sensitivity control). No UI, real-time, or external-service behavior is in scope for this phase.

### Gaps Summary

No gaps. All five ROADMAP success criteria are verified against actual re-run tests (not SUMMARY narration), all seven requirement IDs (CAP-01..06, CONF-01) are accounted for with CONF-01's read-side half correctly and explicitly deferred to Phase 211 per the phase's own documented boundary, the benchmark numbers satisfy the CAP-06 pass bar with a demonstrated sensitivity control, and the four code-review warnings are judged non-blocking against the success criteria (one — WR-03 — is actually a deliberate design decision per D-15, not an oversight).

---

_Verified: 2026-09-25T22:20:00Z_
_Verifier: Claude (gsd-verifier)_
