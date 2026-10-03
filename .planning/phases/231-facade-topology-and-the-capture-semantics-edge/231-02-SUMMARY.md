---
phase: 231-facade-topology-and-the-capture-semantics-edge
plan: 02
subsystem: docs
tags: [exdoc, docs-gate, api-surface, facade]

requires:
  - phase: 231-01
    provides: "Threadline.Query.hydrate_actions/3 and the reshaped incident_bundle/2 body this plan's code-walkthrough excerpt now mirrors"
provides:
  - "Threadline.Query and Threadline.Investigation hidden (@moduledoc false), ungrouped from mix.exs Core API"
  - "Threadline.Query.timeline_query/1 named as the one documented Ecto-composition escape hatch, via mix.exs skip_code_autolink_to"
  - "Every rendered lib doc and five guides rewritten onto the Threadline facade; MIX_ENV=dev mix docs --warnings-as-errors green with both modules hidden"
affects: ["232 (retiring other internal helper names)", "233 (lookup return shapes)", "234 (typespec/doc gate)"]

actuals:
  tokens: 10058
  tasks: 3
  commits: 5
  plan_head_before: 95bfc77d55848431d15193d25ae8e5de5162125f
  plan_head_after: fb079fc6075bccab43979cd063b026e885134612

tech-stack:
  added: []
  patterns:
    - "ExDoc skip_code_autolink_to as the documented mechanism for naming a function in a @moduledoc false module without an autolink warning"
    - "skip_undefined_reference_warnings_on scoped to exactly one extra (CHANGELOG.md) to preserve released history without widening the live docs gate"

key-files:
  created: []
  modified:
    - lib/threadline/query.ex
    - lib/threadline/investigation.ex
    - lib/threadline.ex
    - lib/threadline/export.ex
    - lib/threadline/audit.ex
    - lib/threadline/retention.ex
    - mix.exs
    - test/threadline/public_surface_contract_test.exs
    - guides/how-threadline-works.md
    - guides/code-walkthrough.md
    - guides/audit-indexing.md
    - guides/production-checklist.md
    - guides/domain-reference.md

key-decisions:
  - "SC1's 'links' wording is satisfied by naming (D-01): ExDoc 0.40.1 cannot render a link into a hidden module, so the Threadline moduledoc names Threadline.Query.timeline_query/1 as inline code, backed by skip_code_autolink_to"
  - "No Threadline.timeline_query/1 facade delegate was added (D-04) — the escape hatch stays a Threadline.Query function, reached directly by name"
  - "Two pre-existing decision-id comments in lib/threadline/query.ex (231-01's D-08/D-10) were reworded to drop the bare D-\\d{2,} token — Rule 3 blocking fix, since they failed this task's own <verify> command (release_artifact_contract_test.exs), not a pre-existing issue left for later"

requirements-completed: [API-04]

coverage:
  - id: D1
    description: "Threadline.Query and Threadline.Investigation are @moduledoc false, ungrouped from mix.exs groups_for_modules, and pinned as hidden in public_surface_contract_test.exs; their six child struct modules stay visible and grouped under Data Types"
    requirement: "API-04"
    verification:
      - kind: unit
        ref: "test/threadline/public_surface_contract_test.exs#the public façade is grouped and mandatory critic modules are hidden"
        status: pass
      - kind: unit
        ref: "test/threadline/public_surface_contract_test.exs#child struct modules of the newly-hidden modules stay visible"
        status: pass
    human_judgment: false
  - id: D2
    description: "The Threadline moduledoc names Threadline.Query.timeline_query/1 as the one escape hatch in inline code; Threadline does not export timeline_query/1; mix.exs docs() skip lists are pinned to exactly skip_code_autolink_to: [\"Threadline.Query.timeline_query/1\"] and skip_undefined_reference_warnings_on: [\"CHANGELOG.md\"]"
    requirement: "API-04"
    verification:
      - kind: unit
        ref: "test/threadline/public_surface_contract_test.exs#the Threadline moduledoc names Threadline.Query.timeline_query/1 as the one escape hatch"
        status: pass
      - kind: unit
        ref: "test/threadline/public_surface_contract_test.exs#the docs skip lists are pinned to exactly their documented entries"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every other Threadline.Query.* / Threadline.Investigation.* reference in lib/threadline.ex, export.ex, audit.ex, and retention.ex is rewritten to a facade reference or self-contained prose; the only backticked hidden-module reference left in lib/threadline.ex is the named escape hatch"
    requirement: "API-04"
    verification:
      - kind: automated_ui
        ref: "bash -c 'MIX_ENV=dev mix docs -f html' grep check for lib/ warning lines"
        status: pass
      - kind: other
        ref: "grep -oE 'Threadline\\.(Query|Investigation)\\.[a-z_]+[!?]?/[0-9]' lib/threadline.ex | sort -u -> exactly Threadline.Query.timeline_query/1"
        status: pass
    human_judgment: false
  - id: D4
    description: "guides/how-threadline-works.md, code-walkthrough.md, audit-indexing.md, production-checklist.md and domain-reference.md call only Threadline.* facade functions (or the named escape hatch) in place of every hidden-module reference; the code-walkthrough section 13 excerpt matches the shipped incident_bundle/2 body; audit-indexing points export at Threadline.export_csv/2 / Threadline.export_json/2"
    requirement: "API-04"
    verification:
      - kind: other
        ref: "grep -rhoE 'Threadline\\.(Query|Investigation)\\.[a-z_]+[!?]?/[0-9]' guides | sort -u -> empty"
        status: pass
      - kind: integration
        ref: "test/threadline/code_walkthrough_doc_contract_test.exs, audit_indexing_doc_contract_test.exs, how_threadline_works_doc_contract_test.exs, production_checklist_doc_contract_test.exs, guide_graph_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D5
    description: "The strict docs gate (MIX_ENV=dev mix docs --warnings-as-errors) is green with both modules hidden; released CHANGELOG.md history is not rewritten"
    requirement: "API-04"
    verification:
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors"
        status: pass
    human_judgment: false

duration: 55min
completed: 2026-10-03
status: complete
---

# Phase 231 Plan 02: Facade Topology and the Capture/Semantics Edge Summary

**Hid `Threadline.Query` and `Threadline.Investigation` behind `@moduledoc false`, named `Threadline.Query.timeline_query/1` as the one documented Ecto-composition escape hatch via ExDoc's `skip_code_autolink_to`, and rewrote every rendered lib doc and five guides onto the `Threadline` facade so `mix docs --warnings-as-errors` stays green.**

## Performance

- **Duration:** 55 min
- **Started:** 2026-10-03T15:10:00Z
- **Completed:** 2026-10-03T16:05:00Z
- **Tasks:** 3 completed
- **Files modified:** 13 (1 test file, 6 lib files, 1 mix.exs, 5 guides)

## Accomplishments

- `Threadline.Query` and `Threadline.Investigation` are now `@moduledoc false` and removed from `mix.exs`'s `groups_for_modules` "Core API" list (their six child struct modules — `TimelinePage`, `ActorHistoryPage`, `IncidentBundle`, `IncidentChange`, `LinkedChange`, `LinkedTransaction` — stay visible and grouped under "Data Types").
- `mix.exs` `docs()` gained `skip_code_autolink_to: ["Threadline.Query.timeline_query/1"]` and `skip_undefined_reference_warnings_on: ["CHANGELOG.md"]`, both pinned to their exact single-entry values by new tests in `public_surface_contract_test.exs`.
- The `Threadline` moduledoc gained "Reading audit data" and "Composing your own Ecto query" sections, naming `Threadline.Query.timeline_query/1` in inline code as the one supported escape hatch — no `Threadline.timeline_query/1` delegate was added.
- Every other `Threadline.Query.*` / `Threadline.Investigation.*` doc reference in `lib/threadline.ex`, `lib/threadline/export.ex`, `lib/threadline/audit.ex`, and `lib/threadline/retention.ex` was rewritten to a facade reference (`Threadline.timeline/2`) or self-contained prose (inline ordering, strict `:correlation_id` semantics, the deprecated `transaction: :action` preload note).
- All five named guides (`how-threadline-works.md`, `code-walkthrough.md`, `audit-indexing.md`, `production-checklist.md`, `domain-reference.md`) were rewritten onto the facade; `code-walkthrough.md`'s section 13 excerpt now matches the post-231-01 `incident_bundle/2` body (preload `[:transaction]`, then `Query.hydrate_actions/3` on the header and the changes).
- `MIX_ENV=dev mix docs --warnings-as-errors` exits 0 with both modules hidden.

## Task Commits

Each task was committed atomically; Task 1 followed TDD (RED test, GREEN implementation):

1. **Task 1: Tracer — hide Query/Investigation, name the escape hatch, pin it in the public-surface contract**
   - `21cac1a7` `test(231-02): add failing coverage for hidden Query/Investigation escape hatch`
   - `5dee2abc` `feat(231-02): hide Query/Investigation, name timeline_query/1 as the escape hatch`
   - `4d7a5aaa` `fix(231-02): reword pre-existing decision-id comments blocking the tracer gate`
2. **Task 2: Make every lib doc self-contained on the facade (D-03)**
   - `0b65d750` `docs(231-02): make every lib doc self-contained on the facade`
3. **Task 3: Rewrite the five guides onto the facade and close the docs gate**
   - `fb079fc6` `docs(231-02): rewrite the five guides onto the facade, close the docs gate`

**Plan metadata:** (this commit)

_Note: Task 1 had no separate REFACTOR commit — the GREEN implementation was already the minimal, final shape, apart from the one Rule-3 blocking fix below._

## Files Created/Modified

- `lib/threadline/query.ex` — `@moduledoc false`; two pre-existing comments reworded (see Deviations)
- `lib/threadline/investigation.ex` — `@moduledoc false`
- `lib/threadline.ex` — new moduledoc sections naming the escape hatch; `timeline/2`, `audit_changes_for_transaction/2`, `export_csv/2`, `export_json/2` docs rewritten self-contained
- `lib/threadline/export.ex` — moduledoc, `count_matching/2`, `stream_export_rows/2` docs point at `Threadline.timeline/2` / describe the export projection in prose
- `lib/threadline/audit.ex`, `lib/threadline/retention.ex` — moduledocs point at `Threadline.timeline/2` / "the `Threadline` read functions"
- `mix.exs` — `docs()` drops `Threadline.Query`/`Threadline.Investigation` from "Core API"; adds both skip-list keys
- `test/threadline/public_surface_contract_test.exs` — `@hidden_modules` extended; three new tests (escape-hatch moduledoc, skip-list pin, child-struct visibility)
- `guides/how-threadline-works.md`, `guides/code-walkthrough.md`, `guides/audit-indexing.md`, `guides/production-checklist.md`, `guides/domain-reference.md` — every hidden-module reference rewritten onto the facade

## Decisions Made

- The SC1 "links" wording is satisfied by "names" (D-01 from `231-CONTEXT.md`): ExDoc 0.40.1 cannot render a link into a hidden module, so the moduledoc names `Threadline.Query.timeline_query/1` as inline code, backed by `skip_code_autolink_to`.
- No `Threadline.timeline_query/1` facade delegate was added (D-04): the escape hatch stays a direct `Threadline.Query` call.
- `audit-indexing.md`'s export module line points at `Threadline.export_csv/2` / `Threadline.export_json/2` with no second `skip_undefined_reference_warnings_on` entry and no new facade function, per the plan's explicit instruction.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reworded two pre-existing decision-id comments blocking Task 1's own `<verify>` command**
- **Found during:** Task 1, running `mix test test/threadline/public_surface_contract_test.exs test/threadline/release_artifact_contract_test.exs`
- **Issue:** Two comments added in 231-01's GREEN commits (`lib/threadline/query.ex`, the `hydrate_actions/3` doc and the `extract_action_preload/1` doc) matched `release_artifact_contract_test.exs`'s planning-vocabulary `decision_id: ~r/\bD-\d{2,}\b/` scan (`# D-08: ...`, `# D-10: ...`). Confirmed via `git stash` that these failures predate 231-02 entirely — they exist on top of 231-01's own last commit.
- **Fix:** Reworded both comments to the identical rationale text without the `D-\d{2,}` token (e.g. "Hidden, batched replacement for..." instead of "D-08: hidden, batched replacement for..."). No behavior change.
- **Files modified:** `lib/threadline/query.ex`
- **Verification:** `mix test test/threadline/public_surface_contract_test.exs test/threadline/release_artifact_contract_test.exs` went from 3 failures to 0 (60 tests, 0 failures); `mix verify.credo` stayed clean.
- **Committed in:** `4d7a5aaa`

---

**Total deviations:** 1 auto-fixed (1 blocking). **Impact on plan:** The fix was a comment-only reword with no behavior change, scoped to the exact file Task 1 already touches; it unblocked the task's own verify gate rather than expanding scope. Logged first to `deferred-items.md`, then resolved in the same commit sequence (see that file's history for the before/after record).

## Issues Encountered

None beyond the deviation above.

## Known Stubs

None — no stub patterns introduced. This plan only touches `@moduledoc`/`@doc` text, `mix.exs` docs configuration, a test file, and five guide markdown files; no new runtime code paths were added.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- API-04 is satisfied: `Threadline.Query` and `Threadline.Investigation` are hidden, `Threadline.Query.timeline_query/1` is the one named escape hatch, every rendered lib doc and the five named guides are self-contained on the `Threadline` facade, and `MIX_ENV=dev mix docs --warnings-as-errors` is green.
- `examples/threadline_phoenix/priv/scripts/incident_replay.exs` (the one remaining D-11 table row, `Threadline.Query.history(...)` → `Threadline.history(...)`) is explicitly out of scope for 231-02 per the plan's objective ("the example-app script row is Plan 03") — left for 231-03.
- Ready for 231-03.

## Self-Check: PASSED

- All key-files (created + modified) verified present on disk
- All 5 task commits + this SUMMARY commit verified present via `git log --oneline --all`
- Full plan `<verification>` block re-run clean: `public_surface_contract_test.exs` + `release_artifact_contract_test.exs` (60/0), `MIX_ENV=dev mix docs --warnings-as-errors` (exit 0), `*_doc_contract_test.exs` + `guide_graph_contract_test.exs` (180/0), `mix compile --warnings-as-errors` and `mix verify.credo` (clean)

---
*Phase: 231-facade-topology-and-the-capture-semantics-edge*
*Completed: 2026-10-03*
