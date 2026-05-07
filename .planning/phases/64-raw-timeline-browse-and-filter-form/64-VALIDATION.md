---
phase: 64
slug: raw-timeline-browse-and-filter-form
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
reconstructed_from: [64-01-SUMMARY.md, 64-02-SUMMARY.md, 64-03-SUMMARY.md, 64-VERIFICATION.md, 64-HUMAN-UAT.md]
---

# Phase 64 — Validation Strategy

> Per-phase validation contract reconstructed from completed-phase artifacts.
> All four BROWSE requirements (01–04) and all three originally-human UAT items have automated coverage. `mix ci.all` is the canonical CI gate (323–325 tests, 0 failures at verification time).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + `Phoenix.LiveViewTest` for integration; pure `File.read!/1 + String.contains?/2` for doc-contract |
| **Config file** | `test/test_helper.exs` (ExUnit.start, repo bring-up, `pgbouncer_topology` excluded by default) |
| **Quick run command** | `mix test test/threadline/operator_surface/live/timeline_live_test.exs` (LV integration only) |
| **Full suite command** | `mix ci.all` (verify.format → credo → compile --warnings-as-errors → verify.compile_no_optional → verify.test → verify.threadline → verify.example → verify.doc_contract) |
| **Phase-scoped suite** | `mix test test/threadline/operator_surface/` (43 tests, 0 failures) |
| **LV-absent invariant** | `mix verify.compile_no_optional` (file-scope `Code.ensure_loaded?(Phoenix.LiveView)` gate verified at runtime) |
| **Estimated runtime** | full `mix ci.all` ~30–60s on a warm cache |

---

## Sampling Rate

- **After every task commit:** `mix test test/threadline/operator_surface/` (~5s)
- **After every plan wave:** `mix verify.test` + `mix verify.compile_no_optional`
- **Before `/gsd-verify-work`:** `mix ci.all` must be green
- **Max feedback latency:** ~10s for phase-scoped suite, ~60s for full CI

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 64-01-01 | 01 | 1 | BROWSE-01, BROWSE-02, BROWSE-03 | — | TimelineLive file-scope gated; `:authorize_fn` scope threaded via `scope_aware_opts/1`; `String.to_existing_atom/1` for actor kinds (atom-table-leak prevention) | integration + doc-contract | `mix test test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` | ✅ | ✅ green |
| 64-01-02 | 01 | 1 | BROWSE-04 (route literal) | — | Router exposes `live("/", TimelineLive, :index)` inside `live_session :threadline` (auth pipeline preserved) | doc-contract | `mix test test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` | ✅ | ✅ green |
| 64-01-03 | 01 | 1 | (CSS namespace — D-03/D-05) | — | CSS rules namespaced under `.threadline-ui …`; no Tailwind, no `@apply`, no top-level selectors | source-grep / no automated test | covered by Plan 01 verify block grep gates (commit gate, not runtime test) | ✅ | ✅ green (commit-gated) |
| 64-01-04 | 01 | 1 | (D-02 back-link) | — | `← Timeline` literal present in TransactionLive `transaction-header` and ActorLive `actor-header` + `:not_found` branch | doc-contract | `mix test test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` | ✅ | ✅ green |
| 64-02-01 | 02 | 1 | BROWSE-01, BROWSE-02, BROWSE-03 | — | Runtime LV behaviors (URL state, default 24h, anonymous collapse, correlation_id length, datetime UTC norm, viewport binding, scope-thread, no `phx-change`, allowlist drop, history hygiene) | LiveViewTest integration | `mix test test/threadline/operator_surface/live/timeline_live_test.exs` | ✅ | ✅ green (14 tests) |
| 64-03-01 | 03 | 2 | BROWSE-04 | — | Source-level pin: route literal, six ARIA labels, MapSet parity vs `@allowed_timeline_filter_keys`, file-scope gate, native widgets, `phx-change` prohibition, `← Timeline` back-link presence on siblings | doc-contract | `mix test test/threadline/operator_surface/timeline_browse_doc_contract_test.exs` | ✅ | ✅ green (10 tests) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Test Case Index — `timeline_live_test.exs` (14 cases)

| Case | Name | Requirement |
|---|---|---|
| 1 | default_window | BROWSE-03 + D-09 |
| 2 | filter_parity | BROWSE-02 |
| 3 | url_round_trip | BROWSE-03 |
| 4 | anonymous (actor_id strip) | BROWSE-02 + D-07 |
| 5 | correlation_id_too_long | BROWSE-02 + D-10 |
| 6 | datetime_normalization | F-2 + Pattern 3 |
| 7 | unknown_table_hint | D-08 |
| 8 | phx_change_prohibition | D-04 + F-6 |
| 9 | viewport_bottom_present | BROWSE-01 + D-11 |
| 10 | scope_thread (separate scoped endpoint module) | BROWSE-01 |
| 11 | url_paste_echoes_form_fields | BROWSE-03 / WARNING-1 |
| 12 | unknown_param_dropped | BROWSE-02 / WARNING-5 |
| 13 | apply_one_history_entry | BROWSE-03 / WARNING-5 |
| 14 | history_round_trip (back-button equivalent) | BROWSE-03 (HUMAN-UAT-3 shift-left) |

### Test Case Index — `timeline_browse_doc_contract_test.exs` (10 cases)

| Case | Assertion |
|---|---|
| 1 | Route literal `live("/", TimelineLive, :index)` in `router.ex` |
| 2 | All six ARIA labels (`from`, `to`, `table`, `actor kind`, `actor id`, `correlation id`) verbatim |
| 3 | Filter-key parity — MapSet equality between form `name="filter[…]"` keys (after `actor_kind`+`actor_id`→`actor_ref` collapse, minus `:repo`) and `@allowed_timeline_filter_keys` extracted from `query.ex:36` source |
| 4 | File-scope gate at line 1 of `timeline_live.ex` is the literal `if Code.ensure_loaded?(Phoenix.LiveView) do` |
| 5 | Native `<input type="datetime-local">` and `<select>` for actor_kind |
| 6 | `phx-change=` prohibition in LV source |
| 7 | `← Timeline` literal in `transaction_live.ex` |
| 8 | `← Timeline` literal in `actor_live.ex` |
| 9 | `← Timeline` occurrence count ≥ 2 in `actor_live.ex` (`:not_found` + `actor-header` dual-presence) |
| 10 | `replace: true` literal contract for default-window push_patch (HUMAN-UAT-1 shift-left) |

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* No new framework, no new fixtures, no test-helper changes. Both new test files (`timeline_live_test.exs`, `timeline_browse_doc_contract_test.exs`) reuse the existing `Threadline.Test.Repo` and the verbatim test-router/endpoint scaffold pattern from `actor_live_test.exs`.

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

The three originally-human UAT items (default 24h window in a real browser, URL paste hydration, browser back/forward navigation) were shifted left during the verification phase. See `64-HUMAN-UAT.md` and the "Human Verification Shifted Left" section of `64-VERIFICATION.md` for the full mapping. Net additions: 1 new LV integration test case (Case 14 `history_round_trip`) and 1 new doc-contract assertion (`replace: true` literal). Both run on every `mix ci.all` invocation.

---

## Known Anti-Patterns (Non-Blocking)

Recorded in `64-VERIFICATION.md`; left here for ledger continuity. Neither blocks Nyquist compliance because the canonical CI entrypoint (`mix ci.all` / `mix verify.test`) does not run with `--warnings-as-errors` on the test suite, and the second item is a cosmetic HTML-structure deviation.

| File | Severity | Detail |
|------|---------|--------|
| `test/threadline/operator_surface/live/timeline_live_test.exs:139,168` | ℹ️ Info | `seed_change!/1` and `seed_changes!/2` produce unused-default-arg warnings under `mix test --warnings-as-errors`; `mix ci.all` and `mix verify.test` are unaffected. |
| `lib/threadline/operator_surface/live/timeline_live.ex:236-239` | ⚠️ Warning | Empty-state `<div>` is a sibling after `</section>` rather than inside the stream container (deviation from Plan 01 BLOCKER-2 spec template). Behavioral requirement met; all tests pass. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or are covered by sibling test plans
- [x] Sampling continuity: every consecutive task pair has at least one automated test
- [x] Wave 0 covers all MISSING references (none — existing infrastructure is sufficient)
- [x] No watch-mode flags
- [x] Feedback latency < 60s for full CI (`mix ci.all`); < 10s for phase-scoped suite
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-07 (reconstructed from artifacts; `mix ci.all` green at 323–325 tests, 0 failures).
