---
phase: 228-telemetry
plan: 01
subsystem: telemetry
tags: [telemetry, operator-surface, health, plug, liveview]

requires: []
provides:
  - "Threadline.Telemetry.__events__/0 (@doc false) registry of all eight existing events"
  - "Threadline.Telemetry.emit_operator_surface_authorize/3, emit_export_authorize_error/0, emit_actor_ref_mismatch/0"
  - "exception-taking Threadline.Telemetry.emit_health_checked_error/1"
  - "test/threadline/telemetry_registry_contract_test.exs (runtime allowlist + static scan, extended by plans 02/03/05)"
affects: [228-02, 228-03, 228-05]

actuals:
  tokens: 6100
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Single-owner telemetry emission: every :telemetry.execute/span call lives in lib/threadline/telemetry.ex; call sites invoke @doc false helpers"
    - "Registry-driven runtime allowlist: attach to every __events__/0 name, drive a real operation per event, assert observed keys equal registered keys"

key-files:
  created:
    - test/threadline/telemetry_registry_contract_test.exs
  modified:
    - lib/threadline/telemetry.ex
    - lib/threadline/operator_surface/auth.ex
    - lib/threadline/operator_surface/theme_auth_plug.ex
    - lib/threadline/operator_surface/export_auth_plug.ex
    - lib/threadline/operator_surface/coverage/on_mount.ex
    - lib/threadline/operator_surface/live/coverage_live.ex
    - test/threadline/operator_surface/theme_auth_plug_test.exs
    - test/threadline/operator_surface/export_auth_plug_test.exs
    - test/threadline/operator_surface/exports_doc_contract_test.exs
    - test/threadline/operator_surface/auth_test.exs
    - test/threadline/telemetry_test.exs
    - CHANGELOG.md

key-decisions:
  - "D-17 implemented as maintainer-decided one-way break: actor_ref/session_actor_ref/scope_actor_ref removed from operator-surface events; health error metadata is now %{exception: module}"
  - "The authorize helper is the one helper that takes %Plug.Conn{} | nil plus the scope, deriving path from conn.request_path and scope_keys from Map.keys/1 — every other helper takes only integers/booleans/atoms/exception structs (D-03 reconciled with D-17)"

patterns-established:
  - "@doc false __events__/0 exposes the registry internally; no public events/0 (D-01, deferred to v1.45)"

requirements-completed: [TELE-03]

coverage:
  - id: D1
    description: "Threadline.Telemetry holds a registry of all eight existing events, exposed only through @doc false __events__/0"
    requirement: TELE-03
    verification:
      - kind: unit
        ref: "test/threadline/telemetry_registry_contract_test.exs#every registry event fires with exactly its registered keys"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every :telemetry.execute/:telemetry.span call in lib/ lives in lib/threadline/telemetry.ex; call sites use @doc false helpers"
    requirement: TELE-03
    verification:
      - kind: unit
        ref: "test/threadline/telemetry_registry_contract_test.exs#:telemetry.execute/:telemetry.span appear only in lib/threadline/telemetry.ex"
        status: pass
    human_judgment: false
  - id: D3
    description: "operator-surface authorize/export_authorize/actor_ref_mismatch events and the health error event carry no identity or free-text (D-17 strip)"
    requirement: TELE-03
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/auth_test.exs"
        status: pass
      - kind: unit
        ref: "test/threadline/telemetry_test.exs#emit_health_checked_error/1 emits exception-module metadata"
        status: pass
    human_judgment: false
  - id: D4
    description: "CHANGELOG Breaking changes documents the two identity/message removals in adopter language"
    verification:
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs"
        status: pass
    human_judgment: false

duration: ~1h
completed: 2026-10-02
status: complete
---

# Phase 228 Plan 01: Telemetry Registry and Identity Strip Summary

**Single-owner `Threadline.Telemetry` event registry seeded with all eight existing events, operator-surface and health-error emitters stripped of actor identity and free-text message, proven by a runtime allowlist and a static `:telemetry.execute`/`:telemetry.span` scan.**

## Performance

- **Duration:** ~1h
- **Completed:** 2026-10-02
- **Tasks:** 3/3 completed
- **Files modified:** 12 (1 created, 11 modified)

## Accomplishments

- `Threadline.Telemetry` now holds an `@events` module-attribute registry (name, measurement keys, metadata keys, when-emitted sentence) for all eight existing events, exposed only through `@doc false __events__/0` — no public `events/0` (D-01).
- Every `:telemetry.execute`/`:telemetry.span` call in `lib/` now lives in `lib/threadline/telemetry.ex`; `auth.ex`, `theme_auth_plug.ex` and `export_auth_plug.ex` call `@doc false` helpers instead (D-02), proven by a static scan.
- `[:threadline, :operator_surface, :authorize]`, `[..., :export_authorize]` and `[..., :actor_ref_mismatch]` no longer carry `actor_ref`, `session_actor_ref` or `scope_actor_ref`; `[:threadline, :health, :checked, :error]` carries `%{exception: module}` instead of `%{error: message}` (D-17, maintainer "Strip now" decision from 2026-10-01).
- A runtime allowlist test drives a real operation for each of the eight events and asserts observed measurement/metadata keys equal the registry entry exactly; a mutation control (adding an unlisted `:foo` key to `emit_actor_ref_mismatch/0`) was confirmed to turn it red, then reverted.
- CHANGELOG `### Breaking changes` gained two adopter-language bullets for the identity-field removal and the health-error metadata shape change.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — registry + one helper + three authorize emitters + runtime allowlist** - `0ca7f135` (feat)
2. **Task 2: Strip export_authorize, actor_ref_mismatch and the health error; widen allowlist; add static scan** - `d7fc2432` (feat)
3. **Task 3: Update tests for stripped shapes; CHANGELOG breaking-change entry** - `4a8446ac` (test)

## Files Created/Modified

- `lib/threadline/telemetry.ex` - `@events` registry, `__events__/0`, `emit_operator_surface_authorize/3`, `emit_export_authorize_error/0`, `emit_actor_ref_mismatch/0`, exception-taking `emit_health_checked_error/1`
- `lib/threadline/operator_surface/auth.ex` - `emit_telemetry/3`, `emit_actor_mismatch/2` and `emit_export_authorize_error/0` now delegate to `Threadline.Telemetry` helpers
- `lib/threadline/operator_surface/theme_auth_plug.ex`, `export_auth_plug.ex` - `emit_telemetry/3` delegates to `emit_operator_surface_authorize/3`
- `lib/threadline/operator_surface/coverage/on_mount.ex`, `live/coverage_live.ex` - pass the rescued exception `e` to `emit_health_checked_error/1`; UI assigns keep `Exception.message/1`
- `test/threadline/telemetry_registry_contract_test.exs` - new: runtime allowlist over all eight registry events + static scan (execute/span location, no `:query` event name, no Mix task references `Threadline.Telemetry`)
- `test/threadline/operator_surface/theme_auth_plug_test.exs`, `auth_test.exs`, `telemetry_test.exs`, `exports_doc_contract_test.exs` - updated to assert the stripped shapes
- `CHANGELOG.md` - two Breaking changes bullets

## Decisions Made

- D-17 (maintainer, 2026-10-01 "Strip now"): identity fields removed from operator-surface events; health error metadata is the exception module only. Implemented verbatim per the resolved-decisions note in the plan — no checkpoint:decision inserted.
- D-03 reconciled with D-17: the authorize helper is the single helper that accepts `%Plug.Conn{} | nil` plus the scope; every other helper (export-authorize-error, actor-ref-mismatch, health-error) takes only integers/booleans/atoms/exception structs.

## Deviations from Plan

None — plan executed as written. One acceptance-criteria grep in Task 3 (`grep -c "actor_ref: \"user:support\"}}" test/threadline/operator_surface/theme_auth_plug_test.exs`) returns 1 instead of 0, but the one remaining match is the test's own `authorize_fn` return value (`{:ok, %{actor_ref: "user:support"}}`), unrelated to the telemetry metadata assertion the criterion was written to catch — that metadata assertion itself was changed to `%{scope_keys: [:actor_ref]}` with an explicit `refute Map.has_key?(metadata, :actor_ref)`. No code change was warranted.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The registry, helper-only emission rule and runtime allowlist/static-scan contract are in place and extensible. Plans 02 (export events) and 03 (retention events) add their own registry entries and drivers to the same `drive_all!/0` and `@events` list; plan 05 (docs) derives its tables from `__events__/0`.

---
*Phase: 228-telemetry*
*Completed: 2026-10-02*

## Self-Check: PASSED
