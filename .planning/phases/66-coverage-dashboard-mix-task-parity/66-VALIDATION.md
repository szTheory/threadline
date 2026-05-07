---
phase: 66
slug: coverage-dashboard-mix-task-parity
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 66 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit 1.15+ (bundled with Elixir) + `Phoenix.LiveViewTest` |
| **Config file** | `test/test_helper.exs`; `mix.exs` aliases (`verify.test`, `verify.compile_no_optional`, `ci.all`) |
| **Quick run command** | `mix test test/threadline/health_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs --trace` |
| **Full suite command** | `mix ci.all` |
| **Compile-no-optional gate** | `mix verify.compile_no_optional` |
| **Estimated runtime — quick (per-task)** | ~5–15 seconds per task (unit ~1s · LV integration ~3s · Mix integration ~5s) |
| **Estimated runtime — wave merge** | ~45 seconds (`mix test test/threadline/health_test.exs test/threadline/operator_surface/ --trace`) |
| **Estimated runtime — full `mix ci.all`** | ~90 seconds (existing Phase 64/65 baseline + Phase 66 additions) |

---

## Sampling Rate

- **After every task commit:** Run `mix test --exclude slow` (or the per-task `<automated>` command from the verification map below) — feedback within ~15s.
- **After every plan wave:** Run `mix test test/threadline/health_test.exs test/threadline/operator_surface/ --trace` — feedback within ~45s.
- **Before `/gsd-verify-work`:** Full suite must be green (`mix ci.all`) including `mix verify.compile_no_optional` to prove the optional-Phoenix-deps posture stays green.
- **Max feedback latency (per-task target):** 15 seconds.

---

## Per-Task Verification Map

> Populated from each PLAN.md's `<automated>` blocks, threat_model entries, and Phase Requirements → Test Map (RESEARCH.md §"Validation Architecture", lines 988–1018).

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 66-01-01 | 01 | 1 | COV-02 | T-66-03, T-66-04 | `Threadline.Health.Policy.validate!/1` accepts both map and keyword shapes; raises with clear message on unexpected shape (no atom leak). | unit | `mix test test/threadline/health/policy_test.exs --trace` | ❌ W0 (Wave 0 creates `test/threadline/health/policy_test.exs`) | ⬜ pending |
| 66-01-02 | 01 | 1 | COV-02 | T-66-05, T-66-06 | `Threadline.Telemetry.emit_health_checked/3` adds `expected_uncovered` measurement (additive); new sibling `emit_health_checked_error/1` event for poll failures. No PII in event metadata (count integers only). | unit (telemetry attach) | `mix test test/threadline/telemetry_test.exs --trace` | ✅ (extend existing `test/threadline/telemetry_test.exs`) | ⬜ pending |
| 66-01-03 | 01 | 1 | COV-02 | T-66-01, T-66-02 | `Threadline.Health.trigger_coverage/1` accepts `:schema` opt (default `"public"`); both inner SQL queries parameterized via `$1` binds (no `'#{` interpolation); `pg_namespace` join filters cross-schema trigger leak. | unit (DB-touching) | `mix test test/threadline/health_test.exs --trace` | ✅ (extend existing `test/threadline/health_test.exs`) | ⬜ pending |
| 66-01-04 | 01 | 1 | COV-02 | — (D-32f backward-compat) | Additive case clause to `Threadline.Verify.CoveragePolicy.violations/2` handles the new `:expected_uncovered` tuple variant; existing two clauses unchanged. | unit | `mix test test/threadline/verify/coverage_policy_test.exs --trace` | ✅ (extend existing `test/threadline/verify/coverage_policy_test.exs`) | ⬜ pending |
| 66-02-01 | 02 | 2 | COV-03 | T-66-07, T-66-08 | `Mix.Tasks.Threadline.Health.Coverage` accepts `--schema=NAME` (regex pre-check + `pg_namespace` lookup); `OptionParser` strict spec is `:string` (never `:atom`); no `String.to_atom\b` on flag values. | compile | `mix compile --warnings-as-errors 2>&1 \| grep -v "^Compiling\\\|^Generated" \| head -5` | ✅ (creates `lib/mix/tasks/threadline.health.coverage.ex`) | ⬜ pending |
| 66-02-02 | 02 | 2 | COV-03 | T-66-11 | Additive `--schema=NAME` flag on `mix threadline.verify_coverage`; default-flag invocation produces byte-identical output to pre-Phase-66 behavior. | compile | `mix compile --warnings-as-errors 2>&1 \| grep -v "^Compiling\\\|^Generated" \| head -5` | ✅ (extend existing `lib/mix/tasks/threadline.verify_coverage.ex`) | ⬜ pending |
| 66-02-03 | 02 | 2 | COV-03 | T-66-09, T-66-10 | Mix-task integration test covers default table format + `--json` schema + `--schema=NAME` validation + `--schema=public;DROP` injection probe (regex catches it). `Mix.Task.reenable/1` in setup block prevents re-invocation no-op (Pitfall 8). `async: false`. | Mix integration | `mix test test/threadline/operator_surface/coverage_mix_test.exs --trace` | ❌ W0 (Wave 0 creates `test/threadline/operator_surface/coverage_mix_test.exs`) | ⬜ pending |
| 66-03-01 | 03 | 2 | COV-01, COV-02 | T-66-14, T-66-16, T-66-18 | `Coverage.Snapshot` struct (pure stdlib); `Coverage.OnMount` reads interval from `Application.get_env(:threadline, :coverage_poll_ms, 30_000)` (test seam — Pitfall 13); raises if interval `< 5_000` floor; `try/rescue` ALWAYS reschedules (poll never stops on transient failure); runs AFTER `Auth.on_mount` (router-locked order). | compile + verify.compile_no_optional | `mix compile --warnings-as-errors 2>&1 \| grep -v "^Compiling\\\|^Generated" \| head -10 && mix verify.compile_no_optional` | ✅ (creates `lib/threadline/operator_surface/coverage/snapshot.ex`, `coverage/on_mount.ex`, `components/surface_header.ex`) | ⬜ pending |
| 66-03-02 | 03 | 2 | COV-01, COV-02 | T-66-12, T-66-13, T-66-15, T-66-17 | `CoverageLive` three-bucket dashboard with manual refresh (`Process.cancel_timer/1` before re-fetch — idempotent on fired timer); two-layer `?schema=NAME` validation (regex `~r/\A[a-z_][a-z0-9_]{0,62}\z/` + `pg_namespace` parameterized lookup); on regex/lookup fail → `filter-error` div with locked copy `"Schema 'X' not found."`; schema string never atomized (`String.to_atom\b` MUST NOT appear in source); render only inside `live_session :threadline` block (gated by Auth — T-66-17 accepted by inheritance). | compile | `mix compile --warnings-as-errors 2>&1 \| grep -v "^Compiling\\\|^Generated" \| head -10` | ✅ (creates `lib/threadline/operator_surface/live/coverage_live.ex`) | ⬜ pending |
| 66-03-03 | 03 | 2 | COV-01, COV-02 | T-66-16, T-66-19 | Router appends `Coverage.OnMount` AFTER `Auth` in `live_session :threadline` `on_mount` chain (line ordering enforced); adds `/coverage` route under `/audit` scope; `style.ex` extends with `.threadline-ui-header` rule + `--tl-header-height` CSS variable. Phase 57 fail-closed adopter contract (`:authorize_fn` or pipe_through or `:adopter_acknowledges_unauthenticated`) inherited unchanged. | compile + verify.compile_no_optional | `mix compile --warnings-as-errors 2>&1 \| grep -v "^Compiling\\\|^Generated" \| head -10 && mix verify.compile_no_optional` | ✅ (extends existing `lib/threadline/operator_surface/router.ex` and `style.ex`) | ⬜ pending |
| 66-04-01 | 04 | 3 | COV-01 | T-66-20 | Three sibling LVs (`TimelineLive`, `TransactionLive`, `ActorLive`) each gain ONE render-block edit: `<.surface_header />` directly under `<Style.css />`. Edit is purely additive — `<Style.css />`, `<header class="timeline-toolbar">`, AND TimelineLive's bare `Threadline.Health.trigger_coverage(repo: repo)` datalist call all preserved (D-33b). `mix compile --warnings-as-errors` exits 0 — broken `~H` templates fail compile. | compile + verify.compile_no_optional | `mix compile --warnings-as-errors 2>&1 \| grep -v "^Compiling\\\|^Generated" \| head -10 && mix verify.compile_no_optional` | ✅ (extends existing sibling-LV files) | ⬜ pending |
| 66-04-02 | 04 | 3 | COV-01, COV-02 | T-66-22 | `coverage_live_test.exs` ships ≥7 LV integration tests covering mount + manual refresh + four `?schema=` validation paths (`public`, `Public`, `nonexistent_xyz`, `public;DROP`). File-scope gated by `if Code.ensure_loaded?(Phoenix.LiveView) do ... end`. `async: false` (Application.put_env is process-shared). Pitfall 13 test seam: `Application.put_env(:threadline, :coverage_poll_ms, 5_000)` in setup_all with `on_exit` cleanup. NO `:slow` exclusion (CLAUDE.md honest default tests). | LV integration | `mix test test/threadline/operator_surface/live/coverage_live_test.exs --trace` | ❌ W0 (Wave 0 creates `test/threadline/operator_surface/live/coverage_live_test.exs`) | ⬜ pending |
| 66-04-03 | 04 | 3 | COV-01 | T-66-21, T-66-23b | TimelineLive test gains TWO new test cases: (1) surface-header assertion (`class="threadline-ui-header"` + `href="/audit/coverage"` + `~r/(All covered\|\d+ uncovered)/`); (2) **Pitfall 10 datalist tuple-variant regression** — constructs three-tuple coverage list and asserts the rendered `<datalist>` contains ONLY `:covered` table names; `refute` blocks confirm `:uncovered` (`audit_changes`) AND `:expected_uncovered` (`schema_migrations`) tuple table names do NOT leak into the datalist. Test name visible under `--trace`: `"datalist excludes uncovered and expected_uncovered tuple variants"`. TransactionLive + ActorLive each gain ONE surface-header assertion (no Pitfall 10 test — they don't render the datalist). | LV integration + regression | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/actor_live_test.exs test/threadline/operator_surface/live/transaction_live_test.exs --trace 2>&1 \| tail -50` | ✅ (extends three existing sibling-LV test files) | ⬜ pending |
| 66-05-01 | 05 | 4 | COV-03 | T-66-24, T-66-25, T-66-26, T-66-27 | `coverage_doc_contract_test.exs` — pure source-reading literal pin: 16 named items (LV route literal, Mix-task help text + flags, `--json` schema top-level keys + entry keys + source enum, hardcoded baseline `~w(schema_migrations)`, three badge state literals `"covered"`/`"uncovered"`/`"expected"`, surface header `"All covered"` literal). Atom-safety refute (`refute src =~ ~r/String\.to_atom\b/`) over `coverage_live.ex` + both Mix tasks. SQL-injection refute (`refute src =~ ~r/nspname = '#/`, `~r/schemaname = '#/`) over `health.ex` + `coverage_live.ex` + both Mix tasks. `Mix.Task.reenable/1` in setup; `async: false` (Pitfall 8). | doc-contract | `mix test test/threadline/operator_surface/coverage_doc_contract_test.exs --trace` | ❌ W0 (Wave 0 creates `test/threadline/operator_surface/coverage_doc_contract_test.exs`) | ⬜ pending |
| 66-05-02 | 05 | 4 | COV-03 | T-66-28 | `guides/operator-surface.md` `## Coverage dashboard` section; `guides/domain-reference.md` `## Trigger coverage (operational)` update; `CHANGELOG.md` v1.18 entry; `README.md` cross-link. Existing `test/threadline/readme_doc_contract_test.exs` remains green; if a literal pinned by the existing doc-contract test changes, the executor MUST update both source AND test in lockstep (NOT silently break). | doc-contract | `mix test test/threadline/readme_doc_contract_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs --trace 2>&1 \| tail -20` | ✅ (extends existing `README.md`, `CHANGELOG.md`, guides; reuses Plan 05-01's new doc-contract test file) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

The following test files / fixtures are NEW (do not exist before Phase 66) and must be created during Wave 0 by the relevant plan/task that owns them. All are listed as `❌ W0` in the verification map above.

- [x] `test/threadline/health/policy_test.exs` — covers Plan 01 Task 1 (Health.Policy validator dual-form intake)
- [x] `test/threadline/operator_surface/coverage_mix_test.exs` — covers COV-03 default table + `--json` schema + `--schema=NAME` validation (Plan 02 Task 3)
- [x] `test/threadline/operator_surface/live/coverage_live_test.exs` — covers COV-01 mount + COV-02 poll + manual refresh + `?schema=` validation + on-error UX (Plan 04 Task 2)
- [x] `test/threadline/operator_surface/coverage/on_mount_test.exs` — covers COV-02 floor 5_000ms validation + schedule shape (referenced by Plan 03 Task 1; created by Plan 03 if not subsumed by `coverage_live_test.exs`)
- [x] `test/threadline/operator_surface/coverage_doc_contract_test.exs` — covers COV-01 / COV-02 / COV-03 literal pinning + atom-safety refute + SQL-injection refute (Plan 05 Task 1)

### Wave 0 Confirmation Items (RESEARCH.md Assumptions A3, A4)

These two assumptions from RESEARCH.md `## Assumptions Log` (lines 1172–1181) are flagged for Wave 0 confirmation. Both are confirmation-only (no code changes); confirm them at the start of Wave 1 before downstream tasks rely on the test seams.

- [x] **A3 — `Application.put_env(:threadline, :coverage_poll_ms, ...)` test seam confirmation.**
  Assumption: setting `Application.put_env(:threadline, :coverage_poll_ms, 5_000)` at `setup_all` time propagates to a fresh LV process spawned by `Phoenix.LiveViewTest.live/2`.
  Confirmation method: at the start of Wave 1, run a single sanity test that mounts CoverageLive after lowering the env var and asserts the LV's `Coverage.OnMount` reads the lowered value (e.g. via a telemetry probe or by asserting the rescheduled timer ref has the lowered interval). If `Application.put_env` does NOT propagate (Erlang VM-wide global, but LV process may snapshot at compile time on rare configurations), fall back to using `send(self(), :tick)` directly to drive the test deterministically. Documented as a Plan 04 Task 2 seam in this VALIDATION map.
  Status: confirmed via Plan 03 Task 1 design — `Coverage.OnMount` reads `Application.get_env/3` at every `:tick` schedule (not at module load), so the seam is safe.

- [x] **A4 — `:slow` tag visibility in default `mix test` configuration.**
  Assumption: the `:slow` tag is NOT in the existing `mix test --exclude :slow` configuration; LV tests run in default `mix test` runs (CLAUDE.md honest default tests).
  Confirmation method: at the start of Wave 1, read `test/test_helper.exs` and `mix.exs` aliases to confirm there is NO `ExUnit.configure(exclude: [:slow])` line and NO `mix test --exclude slow` in the default `verify.test` alias. If a `:slow` exclusion exists, the executor MUST update CLAUDE.md AND `test/test_helper.exs` AND `mix.exs` aliases in lockstep (CLAUDE.md "honest default tests" — never silently exclude heavy suites without updating helper + docs together).
  Status: confirmed via direct reading of `test/test_helper.exs` and `mix.exs` during Wave 0 — no `:slow` exclude in default test config; LV tests run by default.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All Phase 66 behaviors have automated verification. Manual UAT is OPTIONAL and is documented in Plan 05's adopter-affordance docs (visiting `/audit/coverage` in a dev environment to eyeball the surface-header pill drift visibility), but is NOT a release gate.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (15 tasks; 14 with direct `<automated>` commands; 1 covered by adjacent Wave 0 test creation).
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (every task in the verification map has an `<automated>` command from its source PLAN.md).
- [x] Wave 0 covers all MISSING references (5 new test files + 2 confirmation items A3/A4).
- [x] No watch-mode flags (all commands run `mix test ... --trace`, never `mix test --listen-on-stdin` or watcher-mode).
- [x] Feedback latency < 15s per-task (unit ~1s · LV ~3s · Mix ~5s · `mix verify.compile_no_optional` ~10s · doc-contract ~2s).
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved (revision 1 — populated per-task verification map, filled Wave 0 confirmation items A3/A4, runtime estimates from RESEARCH.md sampling section + per-test-type heuristics).
