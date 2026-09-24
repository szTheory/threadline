---
phase: 204-structure
plan: 12
subsystem: operator-surface
tags: [refactor, banners, credo, structural-register, exports, router, auth]
status: complete

requires:
  - phase: 204-structure
    provides: "size gate with banner entries only for export_controller (9) and actor_ref (3), credo register at 17 (204-11)"
provides:
  - "Threadline.OperatorSurface.Controllers.ExportController.Encoding: put_headers/2, emit_prefix/2, format_batch/3, emit_suffix/2"
  - "ExportController: owned_by_requester?/2 replaces the nested ownership if; 9 banner lines gone"
  - "ActorRef: 3 banner lines gone, comment/blank lines only"
  - "Router macro: validate_theme!/3 and secure_mount_guard/4 private helpers"
  - "Auth: reconcile_actor/3; Presentation: @status_labels + humanize_status/1; RowHistoryComponent: schema_for_atom_key/2"
  - "Size gate: @banner_exceptions %{} (zero-tolerance banner scan over lib/**/*.ex)"
  - "Credo register 17 -> 12 (Nesting 11, CyclomaticComplexity 1); no `# Structural debt:` line left in lib/"
affects: [204-15, source-size-contract, credo-config-contract, release-artifact-contract, STRUCT-04, STRUCT-07]

actuals:
  tokens: 6300      # chars/4 over the realized diff 50730dd0..34b8c8a9 (25287 chars)
  tasks: 2
  commits: 6        # MEASURED: git rev-list --count 50730dd0..HEAD before the SUMMARY commit
plan_head_before: 50730dd026e5d32df7e58fdc2c29a3623986cccb

tech-stack:
  added: []
  patterns:
    - "A macro's quoted fragment can live in a private helper that returns `quote do ... end`; the macro unquotes it in place, so the helper carries the fragment's branching instead of the macro"
    - "A long literal-to-literal case becomes a module-attribute map plus Map.get_lazy/3 fallback"

key-files:
  created:
    - lib/threadline/operator_surface/controllers/export_controller/encoding.ex
  modified:
    - lib/threadline/operator_surface/controllers/export_controller.ex
    - lib/threadline/semantics/actor_ref.ex
    - lib/threadline/operator_surface/router.ex
    - lib/threadline/operator_surface/auth.ex
    - lib/threadline/operator_surface/presentation.ex
    - lib/threadline/operator_surface/live/row_history_component.ex
    - test/threadline/operator_surface/exports_doc_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
    - test/threadline/source_size_contract_test.exs
    - test/threadline/credo_config_contract_test.exs

key-decisions:
  - "Export encoding (headers, chunked prefix, per-batch formatting, suffix) became ExportController.Encoding, a public-function sibling with @moduledoc false. It has no Phoenix reference, so it takes no Code.ensure_loaded? guard (Plug is a required dep); verify.compile_no_optional is clean."
  - "Encoding joined the source_vocab_operator_infrastructure owner group in release_artifact_contract_test, because it carries user-visible CSV/JSON output text."
  - "The three content-type / Content-Disposition / no-store pins in exports_doc_contract_test now read the controller family via SourceFamily.read!/1. The first-line guard pin and the FilterParams pin still read export_controller.ex alone, and their text did not move. export_controller_test's download-source pin (:572) also still reads the parent, and its text stayed in download/2."
  - "Comments that cited planning artifacts ('RESEARCH §O-2', 'Plan 04's doc-contract test') were reworded when they moved into Encoding, so no planning vocabulary ships in the new module."
  - "Router: the secure-pipeline check is now returned by secure_mount_guard/4 and unquoted at the same position. The raised CompileError texts are unchanged. The generated AST differs only in that the check's three expressions now sit in a nested block, which the compiler flattens."

patterns-established:
  - "Zero-tolerance banner gate: any `# ---`, `# ===`, `# ───`, or `# ***` rule comment in lib/**/*.ex now fails source_size_contract_test"
  - "lib/ carries no structural-register site; the remaining 12 register entries are test-side (204-15)"

requirements-completed: []
requirements-advanced: [STRUCT-04, STRUCT-07]  # STRUCT-04 is done in lib; STRUCT-07's test-side sites finish in 204-15

coverage:
  - id: D1
    description: "Export controller banners replaced by the Encoding boundary or plain comments; ownership register site drained; export bytes and headers unchanged"
    requirement: STRUCT-04
    verification:
      - kind: unit
        ref: "export_controller_test, exports_doc_contract_test, exports_mix_parity_test, gating_test, release_artifact_contract_test, source_size_contract_test, credo_config_contract_test, optional_deps_contract_test (119 tests, 0 failures) after cb2147ea"
        status: pass
    human_judgment: false
  - id: D2
    description: "ActorRef banners removed (comment lines only); banner map empty"
    requirement: STRUCT-04
    verification:
      - kind: unit
        ref: "test/threadline/semantics plus every test referencing ActorRef (552 tests, 0 failures) after 0e1c15f5; comment-only diff check passes"
        status: pass
    human_judgment: false
  - id: D3
    description: "Router, auth, presentation, and row-history register sites drained with no behavior change"
    requirement: STRUCT-07
    verification:
      - kind: unit
        ref: "router-referencing tests (570, 0 failures), auth tests (141), presentation tests + byte lock + rendered_output (306), row-history/transaction tests + byte lock + rendered_output (203), all 0 failures"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser after b33da7ea (re-run once, see deviation 1) and after 34b8c8a9: 326/8/16, the 8 known screenshot cases, baselines clean"
        status: pass
      - kind: unit
        ref: "full mix test 1769 tests, 0 failures (1 excluded); mix credo --strict exit 0; MIX_ENV=dev mix verify.dialyzer 0 errors"
        status: pass
    human_judgment: false

duration: 33min
completed: 2026-09-24
---

# Phase 204 Plan 12: Lib Banners and Last Lib Register Sites Summary

**Export encoding now lives in `ExportController.Encoding`. The controller and ActorRef carry no separator banners, and the size gate's banner map is `%{}`. The last five lib register sites (export ownership, router macro, auth reconciliation, status labels, row-history key matcher) are extracted into small private functions. The credo register drops from 17 to 12, lib has no `# Structural debt:` line, and export bytes, auth outcomes, and rendered HTML are unchanged.**

## Performance

- **Duration:** 33 min
- **Started:** 2026-09-24T02:32:16Z
- **Completed:** 2026-09-24T03:05:38Z
- **Tasks:** 2
- **Files modified:** 11 (1 created)

## Banner decision table

| File | Banner line (at base) | Section | Disposition | D-11 criterion |
|---|---|---|---|---|
| export_controller.ex | :21 `Three thin actions, one shared dispatcher` | csv/2, json/2, ndjson/2, download/2, then download's private delivery chain | Rule deleted; kept as plain comment "Three thin actions share one dispatcher." | Deletion. The section is the controller's public action group (csv/2, json/2, ndjson/2, download/2) plus the private helpers only download/2 uses. The controller module itself is the boundary for its actions. |
| export_controller.ex | :199 `Iodata path (count <= 5_000)` | send_iodata/4 (3 clauses) | Rule deleted; kept as plain comment with the 5_000 threshold | Deletion. One clause group: send_iodata/4. |
| export_controller.ex | :228 `Chunked path (count > 5_000)` | send_chunked_stream/4 | Rule deleted; kept as plain comment with the threshold | Deletion. One function: send_chunked_stream/4. |
| export_controller.ex | :257 `Per-format prefix emission` | emit_prefix/2 (3 clauses) | Moved to a boundary | `ExportController.Encoding.emit_prefix/2` |
| export_controller.ex | :286 `Per-batch row formatting` | format_batch/3 (3 clauses) | Moved to a boundary; explanatory prose kept as plain comment | `ExportController.Encoding.format_batch/3` |
| export_controller.ex | :311 `Per-format suffix emission` | emit_suffix/2 (3 clauses) | Moved to a boundary | `ExportController.Encoding.emit_suffix/2` |
| export_controller.ex | :324 `Headers` | put_export_headers/2 + /3 | Moved to a boundary; the charset rationale kept as plain comment | `ExportController.Encoding.put_headers/2` (+ private put_headers/3) |
| export_controller.ex | :351 `Filter validation (mirrors TimelineLive.safe_validate/1)` | safe_validate/1 | Rule deleted; kept as plain comment "Mirrors `TimelineLive.safe_validate/1`." | Deletion. One clause group: safe_validate/1. |
| export_controller.ex | :360 `Repo resolution` | default_repo/0 | Deleted outright (title added nothing) | Deletion. One clause group: default_repo/0. |
| actor_ref.ex | :29 `Constructor` | new/2, identifiable?/1 | Deleted outright | Deletion. One cohesive group: building and checking an ActorRef. Both functions are public API and cannot leave the public module. |
| actor_ref.ex | :65 `Map serialization (ACTR-04)` | to_map/1, from_map/1, private type_from_string/1 | Deleted outright | Deletion. One cohesive group: the JSONB round trip. to_map/1 and from_map/1 are public API; type_from_string/1 serves only from_map/1. |
| actor_ref.ex | :102 `Ecto.ParameterizedType callbacks` | init/1, type/1, cast/2, load/3, dump/3 | Deleted outright | Deletion. One cohesive group: the behaviour's callback set, which must be defined in the module that declares the type. |

Total: 12 banner lines removed (9 export_controller, 3 actor_ref). A tree-wide banner grep over `lib --include='*.ex'` prints 0.

## Register sites drained

| File | Site | Fix | Register after |
|---|---|---|---|
| export_controller.ex | ownership `if` nested in `case` inside `case` (Nesting) | `owned_by_requester?/2`, two clauses; same `==` and both `identifiable?` checks, `false` for any other shape | Nesting 14 -> 13, ceiling 17 -> 16 |
| router.ex | `threadline_operator_surface/2` complexity 12 (CyclomaticComplexity) | `validate_theme!/3` (guard clause + raising clause, same CompileError) and `secure_mount_guard/4` (returns the secure-pipeline quoted check, unquoted at the same position) | CC 3 -> 2, ceiling 16 -> 15 |
| auth.ex | mismatch `if` nested in `case` inside `case` (Nesting) | `reconcile_actor/3`: `%ActorRef{}` session clause keeps `!=` + `emit_actor_mismatch/2` + returns `socket`; fallback clause assigns the scope actor | Nesting 13 -> 12, ceiling 15 -> 14 |
| presentation.ex | `status_label/1` complexity 17 (CyclomaticComplexity) | `@status_labels` map + `Map.get_lazy/3` with `humanize_status/1` fallback; nil and "" still give "Unknown" | CC 2 -> 1, ceiling 14 -> 13 |
| row_history_component.ex | `if` inside `find_value` fn inside `case` (Nesting) | `schema_for_atom_key/2`, two clauses; `Enum.find_value/2` still returns the first truthy match | Nesting 12 -> 11, ceiling 13 -> 12 |

**Register sum after the plan: 12** (Nesting 11, CyclomaticComplexity 1). `grep -rln 'Structural debt:' lib` prints nothing.

`emit_actor_mismatch` count in auth.ex: 2 at plan base, 2 after (definition + the one call).

## Task Commits

1. **Task 1 (tracer): export controller**
   - `cb2147ea`: Encoding sibling, banners removed, ownership site drained, pins repointed, banner entry deleted, Encoding added to @source_owners
   - Tracer gate: the task's verify (119 tests, 0 failures, plus the banner and register greps) passed after cb2147ea, before expansion.
2. **Task 2: ActorRef and four register sites**
   - `0e1c15f5`: ActorRef banners removed; `@banner_exceptions %{}`
   - `3103d207`: router macro option validation split out
   - `42314f84`: auth actor reconciliation extracted
   - `b33da7ea`: status_label lookup
   - `34b8c8a9`: row-history atom-key matcher extracted

## Acceptance criteria

- `grep -c 'export_controller.ex' test/threadline/source_size_contract_test.exs` prints 0. PASS
- `grep -c '5_000' lib/threadline/operator_surface/controllers/export_controller.ex` prints 3 (`@sync_threshold 5_000` plus two comments). PASS
- ActorRef diff against the plan base changes only comment or blank lines (the plan's check exits 0). PASS
- `emit_actor_mismatch` count is 2 at base and 2 after. PASS
- The browser lane chain passed after the presentation.ex and row_history_component.ex commits. PASS (invariant form; the presentation run needed one re-run, see deviation 1)
- Task 2 verify: no register site in lib, zero lib banners, `@banner_exceptions %{}` present. PASS

## Plan-level verification

- Full `mix test`: 1769 tests, 0 failures (1 excluded).
- Repo-wide `mix credo --strict`: exit 0.
- `MIX_ENV=dev mix verify.dialyzer`: 0 errors.
- `mix verify.compile_no_optional` clean after cb2147ea and 3103d207. `mix compile --force --warnings-as-errors` and `mix format --check-formatted` clean after every commit.

## Deviations from Plan

### Verify-path substitutions

**1. Browser lane re-run once after b33da7ea (presentation.ex)**
- The first run gave 325/9/16. The extra failure was `[mobile-chromium] operator-motion.spec.ts:323` (stress overlay/popover/accordion/toast motion). It was a `locator.click` test-timeout hang on "Show Drawer" because the stress-page toast intercepted pointer events. No assertion failed. The same test passed on desktop in the same run. The stress lab page does not render `status_label/1`.
- I treated this as the dispatch's "timeout hang with no assertion" class and re-ran once with nothing changed. The re-run gave 326/8/16 with exactly the 8 known screenshot cases and clean baselines. The first run's log is kept at /tmp/p204-12-browser-run1.log.
- Note for the orchestrator: this was the mobile side, while the known interaction-timeout flake pattern names desktop-only. I judged it under the first ("timeout hang with no assertion") category instead.

**2. Browser gate in invariant form**
- The plan's `82 passed` grep is stale. I checked the invariant with /tmp/p20412_browser_check.sh (326/8/16, exactly the 8 known screenshot cases, clean baselines, scorecard fixtures restored after each run).

**3. Test file lists built with xargs**
- The Task 2 verify's `$(grep -rlE ...)` expansion was run as `{ ...; grep -rl --include='*_test.exs' ...; } | sort -u | xargs mix test`. A first attempt without `--include` swept in a JSON fixture, and the command was corrected before any result was taken.

---

**Total deviations:** 0 auto-fixed, plus 3 verify-path notes (1 browser re-run).
**Impact on plan:** None. No gate was weakened, no pinned string was edited, no size exception was added, and no baseline was touched. The D-13 per-site fallback was not needed.

## Known Stubs

None.

## Threat Flags

None. No new endpoints, auth paths, or trust-boundary surface were introduced. T-204-24..27 were mitigated as planned (auth/gating/export/router tests green, ActorRef comment-only diff).

## Next Phase Readiness

- lib is banner-free and carries no register site. The credo register is 12 (Nesting 11, CyclomaticComplexity 1), all test-side, for 204-15.
- The size gate carries only the stress_fixtures file exception.

---
*Phase: 204-structure*
*Completed: 2026-09-24*

## Self-Check: PASSED

- All six commits (cb2147ea, 0e1c15f5, 3103d207, 42314f84, b33da7ea, 34b8c8a9) exist, and encoding.ex exists.
