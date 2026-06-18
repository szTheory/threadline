---
phase: 176-data-display-operator-patterns
plan: 03
subsystem: operator-surface
tags: [consumer-migration, ref, kv, data-state, copy-footgun, double-truncation, forensic, security, wave-3]

# Dependency graph
requires:
  - "176-01: Presentation.ref/2 → %{visible, title, full}; value_token/1 truncation at 56; per-kind truncate_for; icons funnel/history/lock/eye_off/cloud_off/archive; RefCopyContract test helper"
  - "176-02: UI.ref/1 (data-tl-copy=full), UI.kv/1, UI.empty_state variants (never/no_data/permission/unavailable), UI.error_state/1, UI.data_state/1"
provides:
  - "Transaction copy footgun closed: transaction id + correlation id + diff before/after cells all bind data-tl-copy={full} via UI.ref/1 (never .title/.visible/.text) — copy==full!=visible asserted"
  - "transaction metadata as UI.kv; diff cells truncate (value_token max 56) + expose a gated per-cell copy bound to the full value; timestamps wrapped in semantic <time datetime=exact_time> UTC (D-22)"
  - "actor/timeline/evidence/export migrated to UI.ref/1 (copy=full) + UI.kv/1; tl-param-list retired on export per-job + context filter blocks"
  - "Per-page data-state taxonomy: empty (never/history) vs no_data (funnel) distinct on actor + timeline; evidence no_data; export never; invalid-actor-ref → error_state"
  - "Presentation.kinds/0 + kind_from_string/1 — interns the per-kind atoms so UI.ref resolves a kind STRING safely (replaces a String.to_existing_atom that raised for :correlation/:arn/:actor/:email)"
  - ".tl-secondary-ref CSS double-truncation removed (text-overflow:ellipsis gone, overflow-wrap:anywhere kept); style_contract_test locks the deletion (refute ellipsis + assert wrap)"
affects:
  - "176-04/05 (coverage flatten + retention/redaction T3): the remaining Wave-0 RED scaffolds (card-nesting + T3 prune + retention ref-copy) stay RED for those owning plans; this plan did not touch coverage/retention/redaction LiveViews"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Copyable id/ref everywhere flows through UI.ref/1 — data-tl-copy binds the FULL value on both <code> and the gated copy button; the visible face is per-kind middle-truncation (D-02 forensic boundary)"
    - "UI.ref nested inside an <a> is invalid HTML (button-in-anchor); the link became a sibling 'Timeline'/'Actor' affordance with the copyable ref rendered separately"
    - "ok-empty is branched by the page author into empty_state variant=never (first-run, history icon) vs no_data (narrowing filter active, funnel icon) — AsyncResult cannot make that call (D-17); distinctness is icon SHAPE, never color"
    - "diff_full/1 recovers the complete diff value for the gated copy: value_token keeps the full value in :title when it truncates; sentinel placeholders (omitted/absent/null) have no copyable value"
    - "kind atoms are interned at compile time via @ref_kinds in Presentation; UI.ref maps the kind string against that list instead of String.to_existing_atom (which raises for never-yet-referenced atoms)"
    - "CSS deletion paired with its contract assertion in the SAME task: refute text-overflow:ellipsis AND assert overflow-wrap:anywhere on .tl-secondary-ref so re-introduction fails CI"

key-files:
  created:
    - .planning/phases/176-data-display-operator-patterns/176-03-SUMMARY.md
  modified:
    - lib/threadline/operator_surface/live/transaction_live.ex
    - lib/threadline/operator_surface/live/actor_live.ex
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/live/evidence_live.ex
    - lib/threadline/operator_surface/live/export_status_live.ex
    - lib/threadline/operator_surface/presentation.ex
    - lib/threadline/operator_surface/ui.ex
    - lib/threadline/operator_surface/style.ex
    - test/threadline/operator_surface/transaction_live_test.exs
    - test/threadline/operator_surface/live/export_status_live_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
    - .planning/phases/176-data-display-operator-patterns/deferred-items.md

key-decisions:
  - "[176-03]: UI.ref cannot be nested inside an <a> (a copy <button> inside an anchor is invalid interactive nesting). For correlation/actor links the copyable ref renders standalone and the deep-link became a sibling 'Timeline'/'Actor' affordance — preserves copy=full AND the navigation target without invalid HTML."
  - "[176-03]: Rule 1 bug fix in UI.ref — String.to_existing_atom(kind) raised ArgumentError for :correlation/:arn/:actor/:email (their atoms are not literals anywhere in truncate_for, so they may not exist at runtime). Added Presentation.kinds/0 + kind_from_string/1 to intern the kinds at compile time and resolve the string safely. Surfaced the instant timeline adopted kind=\"correlation\"."
  - "[176-03]: timeline ok-empty variant is chosen by whether a NARROWING filter (table/table_schema/actor_kind/actor_id/correlation_id) is active — first-run (time-window only) renders variant=never (history), filtered renders variant=no_data (funnel). The locked F-401/F-402 copy is preserved as the empty_state body/title, so those tests stay green while the variant class + icon shape become distinct."
  - "[176-03]: the coverage card-nesting (D-12) + retention T3 prune + retention ref-copy Wave-0 RED scaffolds are OUT OF SCOPE — this plan's invariants forbid touching coverage/retention/redaction LiveViews (those are plans 04/05). They remain RED for their owning plans; logged to deferred-items."
  - "[176-03]: style.ex was touched in Task 1 (additive .tl-diff__cell, composing existing tokens, no new --tl-* token) and Task 3 (the .tl-secondary-ref ellipsis deletion + its paired contract assertion). The deletion-pairs-with-test invariant applies only to the Task-3 deletion and is honored in the same commit."

# Metrics
metrics:
  duration: ~75m
  tasks: 3
  files_created: 1
  files_modified: 12
  completed: 2026-06-18
---

# Phase 176 Plan 03: Display-page consumer migration (ref/kv + data-state) Summary

Migrated the read-only/display operator pages onto the Plan-02 components — closing the confirmed `transaction_live` copy footgun (every copy site now binds the EXACT full value via `UI.ref/1`), routing KV metadata and diff before/after cells through truncation + a gated copy affordance, landing the per-page data-state taxonomy (empty vs no_data vs error distinct by icon shape), and killing the `.tl-secondary-ref` CSS double-truncation with a paired contract assertion that locks the deletion.

## What was built

### Task 1 — Transaction copy footgun + ref/kv + diff cells (TDD: `e1650c8`)
- Replaced the inline `data-tl-copy={transaction_ref.title}` (L120/121) and correlation `data-tl-copy={correlation_ref.title}` (L145) wirings with `<UI.ref kind="uuid"/"correlation">` — the component binds `data-tl-copy={full}` on BOTH the `<code>` and the gated button, eliminating the D-02 footgun.
- Converted the `tl-param-list` metadata block to `<UI.kv>` (`<dl class="tl-kv">`); the correlation `<dd>` renders a `UI.ref` plus a sibling Timeline deep-link.
- Routed the diff before/after cells through the now-truncating `value_token/1` (max 56) and added a per-cell gated copy button bound to the full value (`diff_full/1`), with field-specific aria-labels ("Copy {field} before value").
- Wrapped change timestamps in `<time datetime={exact_time}>` UTC-explicit (D-22, `change_datetime/1`).
- Extended `transaction_live_test.exs`: copy==full!=visible for a long id (RefCopyContract), diff-cell copy bound to full, kv metadata replaces tl-param-list.

### Task 2 — actor/timeline/evidence/export migration + data-state (`32b0977`)
- **actor:** detail header as `UI.kv` (Kind/Id, id via `UI.ref kind="actor"`); per-row transaction copy → `UI.ref kind="uuid"` (copy=full, keeps `data-tl-copy={tx.id}`); never→`empty_state variant="never"` (history), window-empty→`variant="no_data"` (funnel); invalid-ref→`error_state`.
- **timeline:** correlation copy → `UI.ref kind="correlation"`; ok-empty branched into `never` (first-run) vs `no_data` (narrowing filter active) by `timeline_filters_active?/1`, distinct icon shape; removed the now-unused `correlation_ref/1`.
- **evidence:** `subject_ref` → `UI.ref` (copy=full); empty groups → `empty_state variant="no_data"`.
- **export_status:** all three `tl-param-list` blocks (per-job + timeline-context + evidence-context) → `UI.kv` with `UI.ref` values; actor ref → `UI.ref kind="actor"` (+ sibling Actor link); no-jobs → `empty_state variant="never"`.
- **Rule 1 fix:** `UI.ref` used `String.to_existing_atom(kind)` which raised for `:correlation`/`:arn`/`:actor`/`:email` (atoms not interned). Added `Presentation.kinds/0` + `kind_from_string/1` and switched `UI.ref` to the safe resolver.
- Updated `export_status_live_test.exs` for the kv/ref filter structure (key in `<dt>`, full value in `UI.ref` title/data-tl-copy).

### Task 3 — Remove CSS double-truncation + paired contract lock (`a798147`)
- Removed `text-overflow: ellipsis` from `.tl-secondary-ref` (D-05); `overflow-wrap: anywhere` stays so the server-truncated tail wraps and is always reachable on mobile.
- Updated `style_contract_test.exs` IN THE SAME COMMIT: `refute` the ellipsis rule on `.tl-secondary-ref` and `assert` `overflow-wrap: anywhere`, so re-introduction fails CI. No new `--tl-*` token; brand-token parity stays green.

## Verification

- `mix test transaction_live_test.exs actor/timeline/evidence/export_status_live_test.exs data_state_mapping_wave0_test.exs style_contract_test.exs brandbook_token_parity_test.exs ui_test.exs presentation_test.exs` → **213 tests, 0 failures**.
- Full `test/threadline/operator_surface/` → **543 tests, 6 failures** — ALL 6 are the documented cross-plan Wave-0 RED scaffolds owned by plans 04/05: 1 card-nesting (D-12, coverage flatten), 1 retention ref-copy, 4 T3 prune enforcement (retention_history_live). This plan does not touch coverage/retention/redaction LiveViews (phase invariant), so those stay RED for their owning plans. Matches the 176-02 baseline (541→543 with this plan's 2 new transaction tests; same 6 RED).
- `grep 'ref.title'` in transaction_live copy bindings → NONE (footgun gone); `UI.ref` present in transaction/actor/timeline/evidence/export_status.
- `mix format --check-formatted` clean on every file this plan touched.
- `mix compile --warnings-as-errors` clean.
- Capture & semantics layers untouched — only exploration-layer LiveViews, presentation.ex (additive helpers), ui.ex (one-line safe-resolver swap), style.ex, and tests edited.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] UI.ref raised for kinds whose atom was not interned**
- **Found during:** Task 2 (timeline adopting `kind="correlation"`).
- **Issue:** `UI.ref` resolved its `kind` string with `String.to_existing_atom/1`; `:correlation`/`:arn`/`:actor`/`:email` are not literal atoms anywhere in `truncate_for/2` (they fall to the default `_` clause or are matched dynamically), so the atom may not exist at runtime → `ArgumentError: not an already existing atom`. The transaction test passed only because `:uuid` happened to be interned.
- **Fix:** Added `Presentation.kinds/0` (literal `@ref_kinds` list, compile-time interned) + `Presentation.kind_from_string/1`; `UI.ref` now maps the kind string against that list. Invalid kinds resolve to `nil` (default truncation) instead of raising.
- **Files modified:** lib/threadline/operator_surface/presentation.ex, lib/threadline/operator_surface/ui.ex
- **Commit:** 32b0977

**2. [Rule 3 - Blocking] UI.ref cannot be nested inside an `<a>`**
- **Found during:** Task 1 (correlation) and Task 2 (export actor).
- **Issue:** The original markup wrapped the visible ref text in a deep-link `<a>`. `UI.ref` renders a copy `<button>`; a button inside an anchor is invalid interactive nesting.
- **Fix:** Rendered the copyable `UI.ref` standalone and demoted the deep-link to a sibling "Timeline"/"Actor" affordance. Copy=full and the navigation target are both preserved.
- **Files modified:** transaction_live.ex, export_status_live.ex
- **Commit:** e1650c8, 32b0977

**3. [Scope boundary] Updated two consumer tests for the new ref/kv structure**
- `export_status_live_test.exs` asserted the retired `tl-param` `title="key: value"` format; re-targeted to the kv `<dt>` + `UI.ref` full-value title/data-tl-copy. `transaction_live_test.exs` "renders verifiable secondary refs" assertion was updated from `secondary_ref(_, 30)` to `Presentation.ref(_, kind: :uuid)` to match `UI.ref`'s per-kind truncation. Both are behavior-preserving assertion updates in the same commit that changed the markup.

## Deferred Issues (out of scope)

- **Coverage card-nesting (D-12) + retention T3 prune (4) + retention ref-copy (1)** Wave-0 RED scaffolds stay RED — owned by plans 04/05; this plan's invariants forbid touching coverage/retention/redaction LiveViews. Logged to deferred-items.md.
- **`row_history_live_test.exs` + `ui_stress_test.exs` `mix format` drift** — pre-existing, not in this plan's `files_modified`; `mix verify.format` fails on them independent of this plan. Every file this plan edited is format-clean. Logged to deferred-items.md.

## Known Stubs

None. Every migration is real wiring (copyable full values, distinct named state components with preserved typed reasons). No placeholder data, "coming soon", or mock-only props introduced.

## Threat Flags

None new. This plan strengthens the three plan-assigned mitigations:
- **T-176-05** (transaction copy footgun): replaced `data-tl-copy={ref.title}` with `UI.ref` (copy=full) at the heading + correlation + diff cells; `transaction_live_test` asserts copy==full!=visible. Closed.
- **T-176-06** (`.tl-secondary-ref` CSS ellipsis): removed; `style_contract_test` refutes re-introduction. Closed.
- **T-176-07** (per-page typed-reason rendering): actor/timeline/evidence/export render distinct named state components (never/no_data/error) with distinct icon shape; the data_state taxonomy stays distinct per the component-level mapping test. (Per Open Q1, async dispatch was not introduced where pages load synchronously; the taxonomy distinctness is the satisfied requirement.)
No new network endpoints, auth paths, file access, or schema changes — exploration-layer display pages only.

## Self-Check: PASSED

All 12 modified files + the SUMMARY exist on disk; all three task commits (`e1650c8`, `32b0977`, `a798147`) are present in git history; `transaction_live.ex` contains `UI.ref` and no `ref.title` copy binding; `style.ex` `.tl-secondary-ref` has `overflow-wrap: anywhere` and no `text-overflow: ellipsis`.
