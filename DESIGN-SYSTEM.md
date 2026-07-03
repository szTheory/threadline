# Threadline Operator Surface Design System

This inventory is projected from `.planning/design-system-ledger.json`. Update the JSON ledger first, then keep this table projection fresh.

## Ratchet Rule

Scores may only stay level or increase unless an explicit reset with rationale is recorded in the ledger. Locked entries cannot be silently removed, and minimum scores are enforced by `mix test test/threadline/operator_surface/stress_ledger_test.exs`.

## Foundations

| ID | Status | Current Score | Target Score | Kind | Story ID | Fixture Key | Owner Phase |
|---|---:|---:|---:|---|---|---|---:|
| `foundation.color` | baseline | 62 | 90 | foundation | `foundation.color` | `foundation.color.tokens` | 171 |
| `foundation.density` | baseline | 62 | 90 | foundation | `foundation.density` | `foundation.density.scale` | 171 |
| `foundation.motion` | baseline | 62 | 90 | foundation | `foundation.motion` | `foundation.motion.tokens` | 171 |
| `foundation.radius` | baseline | 62 | 90 | foundation | `foundation.radius` | `foundation.radius.tokens` | 171 |
| `foundation.shadow` | baseline | 62 | 90 | foundation | `foundation.shadow` | `foundation.shadow.tokens` | 171 |
| `foundation.spacing` | baseline | 62 | 90 | foundation | `foundation.spacing` | `foundation.spacing.tokens` | 171 |
| `foundation.typography` | baseline | 62 | 90 | foundation | `foundation.typography` | `foundation.typography.tokens` | 171 |
| `foundation.z-index` | baseline | 62 | 90 | foundation | `foundation.z-index` | `foundation.z-index.tokens` | 171 |

## Primitives

| ID | Status | Current Score | Target Score | Kind | Story ID | Fixture Key | Owner Phase |
|---|---:|---:|---:|---|---|---|---:|
| `primitive.icon.reserved` | reserved | 35 | 90 | primitive | `primitive.icon.reserved` | `primitive.icon.reserved` | 171 |
| `primitive.logo.reserved` | reserved | 35 | 90 | primitive | `primitive.logo.reserved` | `primitive.logo.reserved` | 171 |
| `primitive.surface-header.current` | current | 72 | 90 | primitive | `primitive.surface-header.current` | `primitive.surface_header.current` | 171 |
| `primitive.unsupported-view.reserved` | reserved | 35 | 90 | primitive | `primitive.unsupported-view.reserved` | `primitive.unsupported-view.reserved` | 171 |
| `state.data-table.current` | current | 62 | 90 | state | `state.data-table.current` | `state.data_table.current` | 176 |
| `state.empty` | baseline | 62 | 90 | state | `state.empty` | `state.empty` | 171 |
| `state.kv.current` | current | 62 | 90 | state | `state.kv.current` | `state.kv.current` | 176 |
| `state.loading` | current | 62 | 90 | state | `state.loading` | `state.loading` | 176 |
| `state.many` | baseline | 62 | 90 | state | `state.many` | `state.many` | 171 |
| `state.mixed-severity` | baseline | 62 | 90 | state | `state.mixed-severity` | `state.mixed_severity` | 171 |
| `state.no-data` | current | 62 | 90 | state | `state.no-data` | `state.no_data` | 176 |
| `state.null-fields` | baseline | 62 | 90 | state | `state.null-fields` | `state.null_fields` | 171 |
| `state.one` | baseline | 62 | 90 | state | `state.one` | `state.one` | 171 |
| `state.pagination-boundary` | baseline | 62 | 90 | state | `state.pagination-boundary` | `state.pagination_boundary` | 171 |
| `state.permission` | current | 62 | 90 | state | `state.permission` | `state.permission` | 176 |
| `state.permission-denied` | baseline | 62 | 90 | state | `state.permission-denied` | `state.permission_denied` | 171 |
| `state.ref.current` | current | 62 | 90 | state | `state.ref.current` | `state.ref.current` | 176 |
| `state.stale` | current | 62 | 90 | state | `state.stale` | `state.stale` | 176 |
| `state.stale-reconnecting` | baseline | 62 | 90 | state | `state.stale-reconnecting` | `state.stale_reconnecting` | 171 |
| `state.timezone-boundary` | baseline | 62 | 90 | state | `state.timezone-boundary` | `state.timezone_boundary` | 171 |
| `state.unavailable-down` | current | 62 | 90 | state | `state.unavailable-down` | `state.unavailable_down` | 176 |
| `state.unavailable-pruned` | current | 62 | 90 | state | `state.unavailable-pruned` | `state.unavailable_pruned` | 176 |
| `state.unavailable-redacted` | current | 62 | 90 | state | `state.unavailable-redacted` | `state.unavailable_redacted` | 176 |

## Form Controls

| ID | Status | Current Score | Target Score | Kind | Story ID | Fixture Key | Owner Phase |
|---|---:|---:|---:|---|---|---|---:|
| `form-control.checkbox.current` | current | 35 | 90 | form_control | `form-control.checkbox.current` | `form.checkbox.current` | 174 |
| `form-control.date-range.current` | current | 35 | 90 | form_control | `form-control.date-range.current` | `form.date_range.reserved` | 174 |
| `form-control.input.current` | current | 35 | 90 | form_control | `form-control.input.current` | `form.input.current` | 174 |
| `form-control.radio.current` | current | 35 | 90 | form_control | `form-control.radio.current` | `form.radio.current` | 174 |
| `form-control.search.current` | current | 35 | 90 | form_control | `form-control.search.current` | `form.search.current` | 174 |
| `form-control.select.current` | current | 35 | 90 | form_control | `form-control.select.current` | `form.select.current` | 174 |
| `form-control.textarea.current` | current | 35 | 90 | form_control | `form-control.textarea.current` | `form.textarea.current` | 174 |

## Groups

| ID | Status | Current Score | Target Score | Kind | Story ID | Fixture Key | Owner Phase |
|---|---:|---:|---:|---|---|---|---:|
| `group.data-panel.current` | current | 62 | 90 | group | `group.data-panel.current` | `group.data_panel.current` | 177 |
| `group.detail-header.current` | current | 62 | 90 | group | `group.detail-header.current` | `group.detail_header.current` | 177 |
| `group.drawer-form.reference` | current | 62 | 90 | group | `group.drawer-form.reference` | `group.drawer_form.reference` | 177 |
| `group.empty-cta.current` | current | 62 | 90 | group | `group.empty-cta.current` | `group.empty_cta.current` | 177 |
| `group.modal-destructive.current` | current | 62 | 90 | group | `group.modal-destructive.current` | `group.modal_destructive.current` | 177 |
| `group.offline.current` | current | 62 | 90 | group | `group.offline.current` | `group.offline.current` | 177 |
| `group.page-header.current` | current | 62 | 90 | group | `group.page-header.current` | `group.page_header.current` | 177 |
| `group.permission-denied.current` | current | 62 | 90 | group | `group.permission-denied.current` | `group.permission_denied.current` | 177 |
| `group.stats-chart-table.current` | current | 62 | 90 | group | `group.stats-chart-table.current` | `group.stats_chart_table.current` | 177 |
| `group.tabs-subviews.reference` | current | 62 | 90 | group | `group.tabs-subviews.reference` | `group.tabs_subviews.reference` | 177 |
| `group.toast-update.current` | current | 62 | 90 | group | `group.toast-update.current` | `group.toast_update.current` | 177 |
| `group.toolbar.current` | current | 62 | 90 | group | `group.toolbar.current` | `group.toolbar.current` | 177 |

## Pages

| ID | Status | Current Score | Target Score | Kind | Story ID | Fixture Key | Owner Phase |
|---|---:|---:|---:|---|---|---|---:|
| `page.actor.advanced` | current | 62 | 90 | page | `page.actor.advanced` | `page.actor.advanced` | 178 |
| `page.actor.boundary` | current | 62 | 90 | page | `page.actor.boundary` | `page.actor.boundary` | 178 |
| `page.actor.empty` | current | 62 | 90 | page | `page.actor.empty` | `page.actor.empty` | 178 |
| `page.actor.error` | current | 62 | 90 | page | `page.actor.error` | `page.actor.error` | 178 |
| `page.actor.happy` | current | 62 | 90 | page | `page.actor.happy` | `page.actor.happy` | 178 |
| `page.actor.loading` | current | 62 | 90 | page | `page.actor.loading` | `page.actor.loading` | 178 |
| `page.actor.permission` | current | 62 | 90 | page | `page.actor.permission` | `page.actor.permission` | 178 |
| `page.coverage.advanced` | current | 62 | 90 | page | `page.coverage.advanced` | `page.coverage.advanced` | 178 |
| `page.coverage.boundary` | current | 62 | 90 | page | `page.coverage.boundary` | `page.coverage.boundary` | 178 |
| `page.coverage.empty` | current | 62 | 90 | page | `page.coverage.empty` | `page.coverage.empty` | 178 |
| `page.coverage.error` | current | 62 | 90 | page | `page.coverage.error` | `page.coverage.error` | 178 |
| `page.coverage.happy` | current | 62 | 90 | page | `page.coverage.happy` | `page.coverage.happy` | 178 |
| `page.coverage.loading` | current | 62 | 90 | page | `page.coverage.loading` | `page.coverage.loading` | 178 |
| `page.coverage.permission` | current | 62 | 90 | page | `page.coverage.permission` | `page.coverage.permission` | 178 |
| `page.evidence.advanced` | current | 62 | 90 | page | `page.evidence.advanced` | `page.evidence.advanced` | 178 |
| `page.evidence.boundary` | current | 62 | 90 | page | `page.evidence.boundary` | `page.evidence.boundary` | 178 |
| `page.evidence.empty` | current | 62 | 90 | page | `page.evidence.empty` | `page.evidence.empty` | 178 |
| `page.evidence.error` | current | 62 | 90 | page | `page.evidence.error` | `page.evidence.error` | 178 |
| `page.evidence.happy` | current | 62 | 90 | page | `page.evidence.happy` | `page.evidence.happy` | 178 |
| `page.evidence.loading` | current | 62 | 90 | page | `page.evidence.loading` | `page.evidence.loading` | 178 |
| `page.evidence.permission` | current | 62 | 90 | page | `page.evidence.permission` | `page.evidence.permission` | 178 |
| `page.exports.advanced` | current | 62 | 90 | page | `page.exports.advanced` | `page.exports.advanced` | 178 |
| `page.exports.boundary` | current | 62 | 90 | page | `page.exports.boundary` | `page.exports.boundary` | 178 |
| `page.exports.empty` | current | 62 | 90 | page | `page.exports.empty` | `page.exports.empty` | 178 |
| `page.exports.error` | current | 62 | 90 | page | `page.exports.error` | `page.exports.error` | 178 |
| `page.exports.happy` | current | 62 | 90 | page | `page.exports.happy` | `page.exports.happy` | 178 |
| `page.exports.loading` | current | 62 | 90 | page | `page.exports.loading` | `page.exports.loading` | 178 |
| `page.exports.permission` | current | 62 | 90 | page | `page.exports.permission` | `page.exports.permission` | 178 |
| `page.home.advanced` | current | 62 | 90 | page | `page.home.advanced` | `page.home.advanced` | 178 |
| `page.home.boundary` | current | 62 | 90 | page | `page.home.boundary` | `page.home.boundary` | 178 |
| `page.home.empty` | current | 62 | 90 | page | `page.home.empty` | `page.home.empty` | 178 |
| `page.home.error` | current | 62 | 90 | page | `page.home.error` | `page.home.error` | 178 |
| `page.home.happy` | baseline | 72 | 90 | page | `page.home.happy` | `page.home.happy` | 171 |
| `page.home.loading` | current | 62 | 90 | page | `page.home.loading` | `page.home.loading` | 178 |
| `page.home.permission` | current | 62 | 90 | page | `page.home.permission` | `page.home.permission` | 178 |
| `page.redaction.advanced` | current | 62 | 90 | page | `page.redaction.advanced` | `page.redaction.advanced` | 178 |
| `page.redaction.boundary` | current | 62 | 90 | page | `page.redaction.boundary` | `page.redaction.boundary` | 178 |
| `page.redaction.empty` | current | 62 | 90 | page | `page.redaction.empty` | `page.redaction.empty` | 178 |
| `page.redaction.error` | current | 62 | 90 | page | `page.redaction.error` | `page.redaction.error` | 178 |
| `page.redaction.happy` | current | 62 | 90 | page | `page.redaction.happy` | `page.redaction.happy` | 178 |
| `page.redaction.loading` | current | 62 | 90 | page | `page.redaction.loading` | `page.redaction.loading` | 178 |
| `page.redaction.permission` | current | 62 | 90 | page | `page.redaction.permission` | `page.redaction.permission` | 178 |
| `page.retention.advanced` | current | 62 | 90 | page | `page.retention.advanced` | `page.retention.advanced` | 178 |
| `page.retention.boundary` | current | 62 | 90 | page | `page.retention.boundary` | `page.retention.boundary` | 178 |
| `page.retention.empty` | current | 62 | 90 | page | `page.retention.empty` | `page.retention.empty` | 178 |
| `page.retention.error` | current | 62 | 90 | page | `page.retention.error` | `page.retention.error` | 178 |
| `page.retention.happy` | current | 62 | 90 | page | `page.retention.happy` | `page.retention.happy` | 178 |
| `page.retention.loading` | current | 62 | 90 | page | `page.retention.loading` | `page.retention.loading` | 178 |
| `page.retention.permission` | current | 62 | 90 | page | `page.retention.permission` | `page.retention.permission` | 178 |
| `page.row-history.advanced` | current | 62 | 90 | page | `page.row-history.advanced` | `page.row_history.advanced` | 178 |
| `page.row-history.boundary` | current | 62 | 90 | page | `page.row-history.boundary` | `page.row_history.boundary` | 178 |
| `page.row-history.empty` | current | 62 | 90 | page | `page.row-history.empty` | `page.row_history.empty` | 178 |
| `page.row-history.error` | current | 62 | 90 | page | `page.row-history.error` | `page.row_history.error` | 178 |
| `page.row-history.happy` | current | 62 | 90 | page | `page.row-history.happy` | `page.row_history.happy` | 178 |
| `page.row-history.loading` | current | 62 | 90 | page | `page.row-history.loading` | `page.row_history.loading` | 178 |
| `page.row-history.permission` | current | 62 | 90 | page | `page.row-history.permission` | `page.row_history.permission` | 178 |
| `page.shell.advanced` | current | 62 | 90 | page | `page.shell.advanced` | `page.shell.advanced` | 178 |
| `page.shell.boundary` | current | 62 | 90 | page | `page.shell.boundary` | `page.shell.boundary` | 178 |
| `page.shell.empty` | current | 62 | 90 | page | `page.shell.empty` | `page.shell.empty` | 178 |
| `page.shell.error` | current | 62 | 90 | page | `page.shell.error` | `page.shell.error` | 178 |
| `page.shell.happy` | current | 62 | 90 | page | `page.shell.happy` | `page.shell.happy` | 178 |
| `page.shell.loading` | current | 62 | 90 | page | `page.shell.loading` | `page.shell.loading` | 178 |
| `page.shell.permission` | current | 62 | 90 | page | `page.shell.permission` | `page.shell.permission` | 178 |
| `page.timeline.advanced` | current | 62 | 90 | page | `page.timeline.advanced` | `page.timeline.advanced` | 178 |
| `page.timeline.boundary` | current | 62 | 90 | page | `page.timeline.boundary` | `page.timeline.boundary` | 178 |
| `page.timeline.empty` | baseline | 72 | 90 | page | `page.timeline.empty` | `page.timeline.empty` | 171 |
| `page.timeline.error` | current | 62 | 90 | page | `page.timeline.error` | `page.timeline.error` | 178 |
| `page.timeline.happy` | current | 62 | 90 | page | `page.timeline.happy` | `page.timeline.happy` | 178 |
| `page.timeline.loading` | current | 62 | 90 | page | `page.timeline.loading` | `page.timeline.loading` | 178 |
| `page.timeline.permission` | current | 62 | 90 | page | `page.timeline.permission` | `page.timeline.permission` | 178 |
| `page.transaction.advanced` | current | 62 | 90 | page | `page.transaction.advanced` | `page.transaction.advanced` | 178 |
| `page.transaction.boundary` | current | 62 | 90 | page | `page.transaction.boundary` | `page.transaction.boundary` | 178 |
| `page.transaction.empty` | current | 62 | 90 | page | `page.transaction.empty` | `page.transaction.empty` | 178 |
| `page.transaction.error` | current | 62 | 90 | page | `page.transaction.error` | `page.transaction.error` | 178 |
| `page.transaction.happy` | current | 62 | 90 | page | `page.transaction.happy` | `page.transaction.happy` | 178 |
| `page.transaction.loading` | current | 62 | 90 | page | `page.transaction.loading` | `page.transaction.loading` | 178 |
| `page.transaction.permission` | current | 62 | 90 | page | `page.transaction.permission` | `page.transaction.permission` | 178 |

## Known Footguns

| ID | Status | Current Score | Target Score | Kind | Story ID | Fixture Key | Owner Phase |
|---|---:|---:|---:|---|---|---|---:|
| `footgun.coverage-schema-card-declutter` | reserved | 25 | 90 | footgun | `footgun.coverage-schema-card-declutter` | `footgun.coverage_schema.card_declutter` | 176 |
| `footgun.transaction-page-left-push-desktop` | reserved | 25 | 90 | footgun | `footgun.transaction-page-left-push-desktop` | `footgun.transaction_page.left_push_desktop` | 178 |

## Future Reserved Cases

| ID | Status | Current Score | Target Score | Kind | Story ID | Fixture Key | Owner Phase |
|---|---:|---:|---:|---|---|---|---:|
| `future.theme-picker-idiomatic-ui` | reserved | 20 | 90 | future_reserved | `future.theme-picker-idiomatic-ui` | `future.theme_picker.idiomatic_ui` | 175 |

## Semantic Token Mapping

Keep `brandbook/tokens.json` strict to primitive brand tokens. Map primitives to functional UI tokens in `style.ex`. This separation of concerns allows the brand to own the core primitive color palette, while the UI system defines semantics like `--tl-color-surface` and maps them appropriately.

## Motion Reductions

For `prefers-reduced-motion: reduce`, do not use universal 0ms. Zero out positional transitions but preserve opacity fades (`120ms ease`). This explicitly respects user accessibility preferences without jarring UI cuts.

## Scorecard Cube

Per-persona × per-lens projection of the v2 scorecard cube (`scores` in the ledger), covering page-kind surfaces only. Lens columns follow the D-01 frozen order. Cells render `—` while unrated; the `Score` column is the entry `current_score` rollup. Regenerate this table from the ledger whenever a cube cell changes.

| Entry | Persona | hierarchy | density | rhythm | typography | color_contrast | brand_fidelity | Score |
|---|---|---|---|---|---|---|---|---:|
| `page.actor.advanced` | P1 | — | — | — | — | — | — | 62 |
| `page.actor.advanced` | P2 | — | — | — | — | — | — | 62 |
| `page.actor.advanced` | P3 | — | — | — | — | — | — | 62 |
| `page.actor.advanced` | P4 | — | — | — | — | — | — | 62 |
| `page.actor.advanced` | P5 | — | — | — | — | — | — | 62 |
| `page.actor.boundary` | P1 | — | — | — | — | — | — | 62 |
| `page.actor.boundary` | P2 | — | — | — | — | — | — | 62 |
| `page.actor.boundary` | P3 | — | — | — | — | — | — | 62 |
| `page.actor.boundary` | P4 | — | — | — | — | — | — | 62 |
| `page.actor.boundary` | P5 | — | — | — | — | — | — | 62 |
| `page.actor.empty` | P1 | — | — | — | — | — | — | 62 |
| `page.actor.empty` | P2 | — | — | — | — | — | — | 62 |
| `page.actor.empty` | P3 | — | — | — | — | — | — | 62 |
| `page.actor.empty` | P4 | — | — | — | — | — | — | 62 |
| `page.actor.empty` | P5 | — | — | — | — | — | — | 62 |
| `page.actor.error` | P1 | — | — | — | — | — | — | 62 |
| `page.actor.error` | P2 | — | — | — | — | — | — | 62 |
| `page.actor.error` | P3 | — | — | — | — | — | — | 62 |
| `page.actor.error` | P4 | — | — | — | — | — | — | 62 |
| `page.actor.error` | P5 | — | — | — | — | — | — | 62 |
| `page.actor.happy` | P1 | — | — | — | — | — | — | 62 |
| `page.actor.happy` | P2 | — | — | — | — | — | — | 62 |
| `page.actor.happy` | P3 | — | — | — | — | — | — | 62 |
| `page.actor.happy` | P4 | — | — | — | — | — | — | 62 |
| `page.actor.happy` | P5 | — | — | — | — | — | — | 62 |
| `page.actor.loading` | P1 | — | — | — | — | — | — | 62 |
| `page.actor.loading` | P2 | — | — | — | — | — | — | 62 |
| `page.actor.loading` | P3 | — | — | — | — | — | — | 62 |
| `page.actor.loading` | P4 | — | — | — | — | — | — | 62 |
| `page.actor.loading` | P5 | — | — | — | — | — | — | 62 |
| `page.actor.permission` | P1 | — | — | — | — | — | — | 62 |
| `page.actor.permission` | P2 | — | — | — | — | — | — | 62 |
| `page.actor.permission` | P3 | — | — | — | — | — | — | 62 |
| `page.actor.permission` | P4 | — | — | — | — | — | — | 62 |
| `page.actor.permission` | P5 | — | — | — | — | — | — | 62 |
| `page.coverage.advanced` | P1 | — | — | — | — | — | — | 62 |
| `page.coverage.advanced` | P2 | — | — | — | — | — | — | 62 |
| `page.coverage.advanced` | P3 | — | — | — | — | — | — | 62 |
| `page.coverage.advanced` | P4 | — | — | — | — | — | — | 62 |
| `page.coverage.advanced` | P5 | — | — | — | — | — | — | 62 |
| `page.coverage.boundary` | P1 | — | — | — | — | — | — | 62 |
| `page.coverage.boundary` | P2 | — | — | — | — | — | — | 62 |
| `page.coverage.boundary` | P3 | — | — | — | — | — | — | 62 |
| `page.coverage.boundary` | P4 | — | — | — | — | — | — | 62 |
| `page.coverage.boundary` | P5 | — | — | — | — | — | — | 62 |
| `page.coverage.empty` | P1 | — | — | — | — | — | — | 62 |
| `page.coverage.empty` | P2 | — | — | — | — | — | — | 62 |
| `page.coverage.empty` | P3 | — | — | — | — | — | — | 62 |
| `page.coverage.empty` | P4 | — | — | — | — | — | — | 62 |
| `page.coverage.empty` | P5 | — | — | — | — | — | — | 62 |
| `page.coverage.error` | P1 | — | — | — | — | — | — | 62 |
| `page.coverage.error` | P2 | — | — | — | — | — | — | 62 |
| `page.coverage.error` | P3 | — | — | — | — | — | — | 62 |
| `page.coverage.error` | P4 | — | — | — | — | — | — | 62 |
| `page.coverage.error` | P5 | — | — | — | — | — | — | 62 |
| `page.coverage.happy` | P1 | — | — | — | — | — | — | 62 |
| `page.coverage.happy` | P2 | — | — | — | — | — | — | 62 |
| `page.coverage.happy` | P3 | — | — | — | — | — | — | 62 |
| `page.coverage.happy` | P4 | — | — | — | — | — | — | 62 |
| `page.coverage.happy` | P5 | — | — | — | — | — | — | 62 |
| `page.coverage.loading` | P1 | — | — | — | — | — | — | 62 |
| `page.coverage.loading` | P2 | — | — | — | — | — | — | 62 |
| `page.coverage.loading` | P3 | — | — | — | — | — | — | 62 |
| `page.coverage.loading` | P4 | — | — | — | — | — | — | 62 |
| `page.coverage.loading` | P5 | — | — | — | — | — | — | 62 |
| `page.coverage.permission` | P1 | — | — | — | — | — | — | 62 |
| `page.coverage.permission` | P2 | — | — | — | — | — | — | 62 |
| `page.coverage.permission` | P3 | — | — | — | — | — | — | 62 |
| `page.coverage.permission` | P4 | — | — | — | — | — | — | 62 |
| `page.coverage.permission` | P5 | — | — | — | — | — | — | 62 |
| `page.evidence.advanced` | P1 | — | — | — | — | — | — | 62 |
| `page.evidence.advanced` | P2 | — | — | — | — | — | — | 62 |
| `page.evidence.advanced` | P3 | — | — | — | — | — | — | 62 |
| `page.evidence.advanced` | P4 | — | — | — | — | — | — | 62 |
| `page.evidence.advanced` | P5 | — | — | — | — | — | — | 62 |
| `page.evidence.boundary` | P1 | — | — | — | — | — | — | 62 |
| `page.evidence.boundary` | P2 | — | — | — | — | — | — | 62 |
| `page.evidence.boundary` | P3 | — | — | — | — | — | — | 62 |
| `page.evidence.boundary` | P4 | — | — | — | — | — | — | 62 |
| `page.evidence.boundary` | P5 | — | — | — | — | — | — | 62 |
| `page.evidence.empty` | P1 | — | — | — | — | — | — | 62 |
| `page.evidence.empty` | P2 | — | — | — | — | — | — | 62 |
| `page.evidence.empty` | P3 | — | — | — | — | — | — | 62 |
| `page.evidence.empty` | P4 | — | — | — | — | — | — | 62 |
| `page.evidence.empty` | P5 | — | — | — | — | — | — | 62 |
| `page.evidence.error` | P1 | — | — | — | — | — | — | 62 |
| `page.evidence.error` | P2 | — | — | — | — | — | — | 62 |
| `page.evidence.error` | P3 | — | — | — | — | — | — | 62 |
| `page.evidence.error` | P4 | — | — | — | — | — | — | 62 |
| `page.evidence.error` | P5 | — | — | — | — | — | — | 62 |
| `page.evidence.happy` | P1 | — | — | — | — | — | — | 62 |
| `page.evidence.happy` | P2 | — | — | — | — | — | — | 62 |
| `page.evidence.happy` | P3 | — | — | — | — | — | — | 62 |
| `page.evidence.happy` | P4 | — | — | — | — | — | — | 62 |
| `page.evidence.happy` | P5 | — | — | — | — | — | — | 62 |
| `page.evidence.loading` | P1 | — | — | — | — | — | — | 62 |
| `page.evidence.loading` | P2 | — | — | — | — | — | — | 62 |
| `page.evidence.loading` | P3 | — | — | — | — | — | — | 62 |
| `page.evidence.loading` | P4 | — | — | — | — | — | — | 62 |
| `page.evidence.loading` | P5 | — | — | — | — | — | — | 62 |
| `page.evidence.permission` | P1 | — | — | — | — | — | — | 62 |
| `page.evidence.permission` | P2 | — | — | — | — | — | — | 62 |
| `page.evidence.permission` | P3 | — | — | — | — | — | — | 62 |
| `page.evidence.permission` | P4 | — | — | — | — | — | — | 62 |
| `page.evidence.permission` | P5 | — | — | — | — | — | — | 62 |
| `page.exports.advanced` | P1 | — | — | — | — | — | — | 62 |
| `page.exports.advanced` | P2 | — | — | — | — | — | — | 62 |
| `page.exports.advanced` | P3 | — | — | — | — | — | — | 62 |
| `page.exports.advanced` | P4 | — | — | — | — | — | — | 62 |
| `page.exports.advanced` | P5 | — | — | — | — | — | — | 62 |
| `page.exports.boundary` | P1 | — | — | — | — | — | — | 62 |
| `page.exports.boundary` | P2 | — | — | — | — | — | — | 62 |
| `page.exports.boundary` | P3 | — | — | — | — | — | — | 62 |
| `page.exports.boundary` | P4 | — | — | — | — | — | — | 62 |
| `page.exports.boundary` | P5 | — | — | — | — | — | — | 62 |
| `page.exports.empty` | P1 | — | — | — | — | — | — | 62 |
| `page.exports.empty` | P2 | — | — | — | — | — | — | 62 |
| `page.exports.empty` | P3 | — | — | — | — | — | — | 62 |
| `page.exports.empty` | P4 | — | — | — | — | — | — | 62 |
| `page.exports.empty` | P5 | — | — | — | — | — | — | 62 |
| `page.exports.error` | P1 | — | — | — | — | — | — | 62 |
| `page.exports.error` | P2 | — | — | — | — | — | — | 62 |
| `page.exports.error` | P3 | — | — | — | — | — | — | 62 |
| `page.exports.error` | P4 | — | — | — | — | — | — | 62 |
| `page.exports.error` | P5 | — | — | — | — | — | — | 62 |
| `page.exports.happy` | P1 | — | — | — | — | — | — | 62 |
| `page.exports.happy` | P2 | — | — | — | — | — | — | 62 |
| `page.exports.happy` | P3 | — | — | — | — | — | — | 62 |
| `page.exports.happy` | P4 | — | — | — | — | — | — | 62 |
| `page.exports.happy` | P5 | — | — | — | — | — | — | 62 |
| `page.exports.loading` | P1 | — | — | — | — | — | — | 62 |
| `page.exports.loading` | P2 | — | — | — | — | — | — | 62 |
| `page.exports.loading` | P3 | — | — | — | — | — | — | 62 |
| `page.exports.loading` | P4 | — | — | — | — | — | — | 62 |
| `page.exports.loading` | P5 | — | — | — | — | — | — | 62 |
| `page.exports.permission` | P1 | — | — | — | — | — | — | 62 |
| `page.exports.permission` | P2 | — | — | — | — | — | — | 62 |
| `page.exports.permission` | P3 | — | — | — | — | — | — | 62 |
| `page.exports.permission` | P4 | — | — | — | — | — | — | 62 |
| `page.exports.permission` | P5 | — | — | — | — | — | — | 62 |
| `page.home.advanced` | P1 | — | — | — | — | — | — | 62 |
| `page.home.advanced` | P2 | — | — | — | — | — | — | 62 |
| `page.home.advanced` | P3 | — | — | — | — | — | — | 62 |
| `page.home.advanced` | P4 | — | — | — | — | — | — | 62 |
| `page.home.advanced` | P5 | — | — | — | — | — | — | 62 |
| `page.home.boundary` | P1 | — | — | — | — | — | — | 62 |
| `page.home.boundary` | P2 | — | — | — | — | — | — | 62 |
| `page.home.boundary` | P3 | — | — | — | — | — | — | 62 |
| `page.home.boundary` | P4 | — | — | — | — | — | — | 62 |
| `page.home.boundary` | P5 | — | — | — | — | — | — | 62 |
| `page.home.empty` | P1 | — | — | — | — | — | — | 62 |
| `page.home.empty` | P2 | — | — | — | — | — | — | 62 |
| `page.home.empty` | P3 | — | — | — | — | — | — | 62 |
| `page.home.empty` | P4 | — | — | — | — | — | — | 62 |
| `page.home.empty` | P5 | — | — | — | — | — | — | 62 |
| `page.home.error` | P1 | — | — | — | — | — | — | 62 |
| `page.home.error` | P2 | — | — | — | — | — | — | 62 |
| `page.home.error` | P3 | — | — | — | — | — | — | 62 |
| `page.home.error` | P4 | — | — | — | — | — | — | 62 |
| `page.home.error` | P5 | — | — | — | — | — | — | 62 |
| `page.home.happy` | P1 | — | — | — | — | — | — | 72 |
| `page.home.happy` | P2 | — | — | — | — | — | — | 72 |
| `page.home.happy` | P3 | — | — | — | — | — | — | 72 |
| `page.home.happy` | P4 | — | — | — | — | — | — | 72 |
| `page.home.happy` | P5 | — | — | — | — | — | — | 72 |
| `page.home.loading` | P1 | — | — | — | — | — | — | 62 |
| `page.home.loading` | P2 | — | — | — | — | — | — | 62 |
| `page.home.loading` | P3 | — | — | — | — | — | — | 62 |
| `page.home.loading` | P4 | — | — | — | — | — | — | 62 |
| `page.home.loading` | P5 | — | — | — | — | — | — | 62 |
| `page.home.permission` | P1 | — | — | — | — | — | — | 62 |
| `page.home.permission` | P2 | — | — | — | — | — | — | 62 |
| `page.home.permission` | P3 | — | — | — | — | — | — | 62 |
| `page.home.permission` | P4 | — | — | — | — | — | — | 62 |
| `page.home.permission` | P5 | — | — | — | — | — | — | 62 |
| `page.redaction.advanced` | P1 | — | — | — | — | — | — | 62 |
| `page.redaction.advanced` | P2 | — | — | — | — | — | — | 62 |
| `page.redaction.advanced` | P3 | — | — | — | — | — | — | 62 |
| `page.redaction.advanced` | P4 | — | — | — | — | — | — | 62 |
| `page.redaction.advanced` | P5 | — | — | — | — | — | — | 62 |
| `page.redaction.boundary` | P1 | — | — | — | — | — | — | 62 |
| `page.redaction.boundary` | P2 | — | — | — | — | — | — | 62 |
| `page.redaction.boundary` | P3 | — | — | — | — | — | — | 62 |
| `page.redaction.boundary` | P4 | — | — | — | — | — | — | 62 |
| `page.redaction.boundary` | P5 | — | — | — | — | — | — | 62 |
| `page.redaction.empty` | P1 | — | — | — | — | — | — | 62 |
| `page.redaction.empty` | P2 | — | — | — | — | — | — | 62 |
| `page.redaction.empty` | P3 | — | — | — | — | — | — | 62 |
| `page.redaction.empty` | P4 | — | — | — | — | — | — | 62 |
| `page.redaction.empty` | P5 | — | — | — | — | — | — | 62 |
| `page.redaction.error` | P1 | — | — | — | — | — | — | 62 |
| `page.redaction.error` | P2 | — | — | — | — | — | — | 62 |
| `page.redaction.error` | P3 | — | — | — | — | — | — | 62 |
| `page.redaction.error` | P4 | — | — | — | — | — | — | 62 |
| `page.redaction.error` | P5 | — | — | — | — | — | — | 62 |
| `page.redaction.happy` | P1 | — | — | — | — | — | — | 62 |
| `page.redaction.happy` | P2 | — | — | — | — | — | — | 62 |
| `page.redaction.happy` | P3 | — | — | — | — | — | — | 62 |
| `page.redaction.happy` | P4 | — | — | — | — | — | — | 62 |
| `page.redaction.happy` | P5 | — | — | — | — | — | — | 62 |
| `page.redaction.loading` | P1 | — | — | — | — | — | — | 62 |
| `page.redaction.loading` | P2 | — | — | — | — | — | — | 62 |
| `page.redaction.loading` | P3 | — | — | — | — | — | — | 62 |
| `page.redaction.loading` | P4 | — | — | — | — | — | — | 62 |
| `page.redaction.loading` | P5 | — | — | — | — | — | — | 62 |
| `page.redaction.permission` | P1 | — | — | — | — | — | — | 62 |
| `page.redaction.permission` | P2 | — | — | — | — | — | — | 62 |
| `page.redaction.permission` | P3 | — | — | — | — | — | — | 62 |
| `page.redaction.permission` | P4 | — | — | — | — | — | — | 62 |
| `page.redaction.permission` | P5 | — | — | — | — | — | — | 62 |
| `page.retention.advanced` | P1 | — | — | — | — | — | — | 62 |
| `page.retention.advanced` | P2 | — | — | — | — | — | — | 62 |
| `page.retention.advanced` | P3 | — | — | — | — | — | — | 62 |
| `page.retention.advanced` | P4 | — | — | — | — | — | — | 62 |
| `page.retention.advanced` | P5 | — | — | — | — | — | — | 62 |
| `page.retention.boundary` | P1 | — | — | — | — | — | — | 62 |
| `page.retention.boundary` | P2 | — | — | — | — | — | — | 62 |
| `page.retention.boundary` | P3 | — | — | — | — | — | — | 62 |
| `page.retention.boundary` | P4 | — | — | — | — | — | — | 62 |
| `page.retention.boundary` | P5 | — | — | — | — | — | — | 62 |
| `page.retention.empty` | P1 | — | — | — | — | — | — | 62 |
| `page.retention.empty` | P2 | — | — | — | — | — | — | 62 |
| `page.retention.empty` | P3 | — | — | — | — | — | — | 62 |
| `page.retention.empty` | P4 | — | — | — | — | — | — | 62 |
| `page.retention.empty` | P5 | — | — | — | — | — | — | 62 |
| `page.retention.error` | P1 | — | — | — | — | — | — | 62 |
| `page.retention.error` | P2 | — | — | — | — | — | — | 62 |
| `page.retention.error` | P3 | — | — | — | — | — | — | 62 |
| `page.retention.error` | P4 | — | — | — | — | — | — | 62 |
| `page.retention.error` | P5 | — | — | — | — | — | — | 62 |
| `page.retention.happy` | P1 | — | — | — | — | — | — | 62 |
| `page.retention.happy` | P2 | — | — | — | — | — | — | 62 |
| `page.retention.happy` | P3 | — | — | — | — | — | — | 62 |
| `page.retention.happy` | P4 | — | — | — | — | — | — | 62 |
| `page.retention.happy` | P5 | — | — | — | — | — | — | 62 |
| `page.retention.loading` | P1 | — | — | — | — | — | — | 62 |
| `page.retention.loading` | P2 | — | — | — | — | — | — | 62 |
| `page.retention.loading` | P3 | — | — | — | — | — | — | 62 |
| `page.retention.loading` | P4 | — | — | — | — | — | — | 62 |
| `page.retention.loading` | P5 | — | — | — | — | — | — | 62 |
| `page.retention.permission` | P1 | — | — | — | — | — | — | 62 |
| `page.retention.permission` | P2 | — | — | — | — | — | — | 62 |
| `page.retention.permission` | P3 | — | — | — | — | — | — | 62 |
| `page.retention.permission` | P4 | — | — | — | — | — | — | 62 |
| `page.retention.permission` | P5 | — | — | — | — | — | — | 62 |
| `page.row-history.advanced` | P1 | — | — | — | — | — | — | 62 |
| `page.row-history.advanced` | P2 | — | — | — | — | — | — | 62 |
| `page.row-history.advanced` | P3 | — | — | — | — | — | — | 62 |
| `page.row-history.advanced` | P4 | — | — | — | — | — | — | 62 |
| `page.row-history.advanced` | P5 | — | — | — | — | — | — | 62 |
| `page.row-history.boundary` | P1 | — | — | — | — | — | — | 62 |
| `page.row-history.boundary` | P2 | — | — | — | — | — | — | 62 |
| `page.row-history.boundary` | P3 | — | — | — | — | — | — | 62 |
| `page.row-history.boundary` | P4 | — | — | — | — | — | — | 62 |
| `page.row-history.boundary` | P5 | — | — | — | — | — | — | 62 |
| `page.row-history.empty` | P1 | — | — | — | — | — | — | 62 |
| `page.row-history.empty` | P2 | — | — | — | — | — | — | 62 |
| `page.row-history.empty` | P3 | — | — | — | — | — | — | 62 |
| `page.row-history.empty` | P4 | — | — | — | — | — | — | 62 |
| `page.row-history.empty` | P5 | — | — | — | — | — | — | 62 |
| `page.row-history.error` | P1 | — | — | — | — | — | — | 62 |
| `page.row-history.error` | P2 | — | — | — | — | — | — | 62 |
| `page.row-history.error` | P3 | — | — | — | — | — | — | 62 |
| `page.row-history.error` | P4 | — | — | — | — | — | — | 62 |
| `page.row-history.error` | P5 | — | — | — | — | — | — | 62 |
| `page.row-history.happy` | P1 | — | — | — | — | — | — | 62 |
| `page.row-history.happy` | P2 | — | — | — | — | — | — | 62 |
| `page.row-history.happy` | P3 | — | — | — | — | — | — | 62 |
| `page.row-history.happy` | P4 | — | — | — | — | — | — | 62 |
| `page.row-history.happy` | P5 | — | — | — | — | — | — | 62 |
| `page.row-history.loading` | P1 | — | — | — | — | — | — | 62 |
| `page.row-history.loading` | P2 | — | — | — | — | — | — | 62 |
| `page.row-history.loading` | P3 | — | — | — | — | — | — | 62 |
| `page.row-history.loading` | P4 | — | — | — | — | — | — | 62 |
| `page.row-history.loading` | P5 | — | — | — | — | — | — | 62 |
| `page.row-history.permission` | P1 | — | — | — | — | — | — | 62 |
| `page.row-history.permission` | P2 | — | — | — | — | — | — | 62 |
| `page.row-history.permission` | P3 | — | — | — | — | — | — | 62 |
| `page.row-history.permission` | P4 | — | — | — | — | — | — | 62 |
| `page.row-history.permission` | P5 | — | — | — | — | — | — | 62 |
| `page.shell.advanced` | P1 | — | — | — | — | — | — | 62 |
| `page.shell.advanced` | P2 | — | — | — | — | — | — | 62 |
| `page.shell.advanced` | P3 | — | — | — | — | — | — | 62 |
| `page.shell.advanced` | P4 | — | — | — | — | — | — | 62 |
| `page.shell.advanced` | P5 | — | — | — | — | — | — | 62 |
| `page.shell.boundary` | P1 | — | — | — | — | — | — | 62 |
| `page.shell.boundary` | P2 | — | — | — | — | — | — | 62 |
| `page.shell.boundary` | P3 | — | — | — | — | — | — | 62 |
| `page.shell.boundary` | P4 | — | — | — | — | — | — | 62 |
| `page.shell.boundary` | P5 | — | — | — | — | — | — | 62 |
| `page.shell.empty` | P1 | — | — | — | — | — | — | 62 |
| `page.shell.empty` | P2 | — | — | — | — | — | — | 62 |
| `page.shell.empty` | P3 | — | — | — | — | — | — | 62 |
| `page.shell.empty` | P4 | — | — | — | — | — | — | 62 |
| `page.shell.empty` | P5 | — | — | — | — | — | — | 62 |
| `page.shell.error` | P1 | — | — | — | — | — | — | 62 |
| `page.shell.error` | P2 | — | — | — | — | — | — | 62 |
| `page.shell.error` | P3 | — | — | — | — | — | — | 62 |
| `page.shell.error` | P4 | — | — | — | — | — | — | 62 |
| `page.shell.error` | P5 | — | — | — | — | — | — | 62 |
| `page.shell.happy` | P1 | — | — | — | — | — | — | 62 |
| `page.shell.happy` | P2 | — | — | — | — | — | — | 62 |
| `page.shell.happy` | P3 | — | — | — | — | — | — | 62 |
| `page.shell.happy` | P4 | — | — | — | — | — | — | 62 |
| `page.shell.happy` | P5 | — | — | — | — | — | — | 62 |
| `page.shell.loading` | P1 | — | — | — | — | — | — | 62 |
| `page.shell.loading` | P2 | — | — | — | — | — | — | 62 |
| `page.shell.loading` | P3 | — | — | — | — | — | — | 62 |
| `page.shell.loading` | P4 | — | — | — | — | — | — | 62 |
| `page.shell.loading` | P5 | — | — | — | — | — | — | 62 |
| `page.shell.permission` | P1 | — | — | — | — | — | — | 62 |
| `page.shell.permission` | P2 | — | — | — | — | — | — | 62 |
| `page.shell.permission` | P3 | — | — | — | — | — | — | 62 |
| `page.shell.permission` | P4 | — | — | — | — | — | — | 62 |
| `page.shell.permission` | P5 | — | — | — | — | — | — | 62 |
| `page.timeline.advanced` | P1 | — | — | — | — | — | — | 62 |
| `page.timeline.advanced` | P2 | — | — | — | — | — | — | 62 |
| `page.timeline.advanced` | P3 | — | — | — | — | — | — | 62 |
| `page.timeline.advanced` | P4 | — | — | — | — | — | — | 62 |
| `page.timeline.advanced` | P5 | — | — | — | — | — | — | 62 |
| `page.timeline.boundary` | P1 | — | — | — | — | — | — | 62 |
| `page.timeline.boundary` | P2 | — | — | — | — | — | — | 62 |
| `page.timeline.boundary` | P3 | — | — | — | — | — | — | 62 |
| `page.timeline.boundary` | P4 | — | — | — | — | — | — | 62 |
| `page.timeline.boundary` | P5 | — | — | — | — | — | — | 62 |
| `page.timeline.empty` | P1 | — | — | — | — | — | — | 72 |
| `page.timeline.empty` | P2 | — | — | — | — | — | — | 72 |
| `page.timeline.empty` | P3 | — | — | — | — | — | — | 72 |
| `page.timeline.empty` | P4 | — | — | — | — | — | — | 72 |
| `page.timeline.empty` | P5 | — | — | — | — | — | — | 72 |
| `page.timeline.error` | P1 | — | — | — | — | — | — | 62 |
| `page.timeline.error` | P2 | — | — | — | — | — | — | 62 |
| `page.timeline.error` | P3 | — | — | — | — | — | — | 62 |
| `page.timeline.error` | P4 | — | — | — | — | — | — | 62 |
| `page.timeline.error` | P5 | — | — | — | — | — | — | 62 |
| `page.timeline.happy` | P1 | — | — | — | — | — | — | 62 |
| `page.timeline.happy` | P2 | — | — | — | — | — | — | 62 |
| `page.timeline.happy` | P3 | — | — | — | — | — | — | 62 |
| `page.timeline.happy` | P4 | — | — | — | — | — | — | 62 |
| `page.timeline.happy` | P5 | — | — | — | — | — | — | 62 |
| `page.timeline.loading` | P1 | — | — | — | — | — | — | 62 |
| `page.timeline.loading` | P2 | — | — | — | — | — | — | 62 |
| `page.timeline.loading` | P3 | — | — | — | — | — | — | 62 |
| `page.timeline.loading` | P4 | — | — | — | — | — | — | 62 |
| `page.timeline.loading` | P5 | — | — | — | — | — | — | 62 |
| `page.timeline.permission` | P1 | — | — | — | — | — | — | 62 |
| `page.timeline.permission` | P2 | — | — | — | — | — | — | 62 |
| `page.timeline.permission` | P3 | — | — | — | — | — | — | 62 |
| `page.timeline.permission` | P4 | — | — | — | — | — | — | 62 |
| `page.timeline.permission` | P5 | — | — | — | — | — | — | 62 |
| `page.transaction.advanced` | P1 | — | — | — | — | — | — | 62 |
| `page.transaction.advanced` | P2 | — | — | — | — | — | — | 62 |
| `page.transaction.advanced` | P3 | — | — | — | — | — | — | 62 |
| `page.transaction.advanced` | P4 | — | — | — | — | — | — | 62 |
| `page.transaction.advanced` | P5 | — | — | — | — | — | — | 62 |
| `page.transaction.boundary` | P1 | — | — | — | — | — | — | 62 |
| `page.transaction.boundary` | P2 | — | — | — | — | — | — | 62 |
| `page.transaction.boundary` | P3 | — | — | — | — | — | — | 62 |
| `page.transaction.boundary` | P4 | — | — | — | — | — | — | 62 |
| `page.transaction.boundary` | P5 | — | — | — | — | — | — | 62 |
| `page.transaction.empty` | P1 | — | — | — | — | — | — | 62 |
| `page.transaction.empty` | P2 | — | — | — | — | — | — | 62 |
| `page.transaction.empty` | P3 | — | — | — | — | — | — | 62 |
| `page.transaction.empty` | P4 | — | — | — | — | — | — | 62 |
| `page.transaction.empty` | P5 | — | — | — | — | — | — | 62 |
| `page.transaction.error` | P1 | — | — | — | — | — | — | 62 |
| `page.transaction.error` | P2 | — | — | — | — | — | — | 62 |
| `page.transaction.error` | P3 | — | — | — | — | — | — | 62 |
| `page.transaction.error` | P4 | — | — | — | — | — | — | 62 |
| `page.transaction.error` | P5 | — | — | — | — | — | — | 62 |
| `page.transaction.happy` | P1 | — | — | — | — | — | — | 62 |
| `page.transaction.happy` | P2 | — | — | — | — | — | — | 62 |
| `page.transaction.happy` | P3 | — | — | — | — | — | — | 62 |
| `page.transaction.happy` | P4 | — | — | — | — | — | — | 62 |
| `page.transaction.happy` | P5 | — | — | — | — | — | — | 62 |
| `page.transaction.loading` | P1 | — | — | — | — | — | — | 62 |
| `page.transaction.loading` | P2 | — | — | — | — | — | — | 62 |
| `page.transaction.loading` | P3 | — | — | — | — | — | — | 62 |
| `page.transaction.loading` | P4 | — | — | — | — | — | — | 62 |
| `page.transaction.loading` | P5 | — | — | — | — | — | — | 62 |
| `page.transaction.permission` | P1 | — | — | — | — | — | — | 62 |
| `page.transaction.permission` | P2 | — | — | — | — | — | — | 62 |
| `page.transaction.permission` | P3 | — | — | — | — | — | — | 62 |
| `page.transaction.permission` | P4 | — | — | — | — | — | — | 62 |
| `page.transaction.permission` | P5 | — | — | — | — | — | — | 62 |
