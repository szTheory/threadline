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
| `page.actor.reserved` | reserved | 35 | 90 | page | `page.actor.reserved` | `page.actor.reserved` | 178 |
| `page.coverage.reserved` | reserved | 35 | 90 | page | `page.coverage.reserved` | `page.coverage.reserved` | 178 |
| `page.evidence.reserved` | reserved | 35 | 90 | page | `page.evidence.reserved` | `page.evidence.reserved` | 178 |
| `page.exports.reserved` | reserved | 35 | 90 | page | `page.exports.reserved` | `page.exports.reserved` | 178 |
| `page.home.happy` | baseline | 62 | 90 | page | `page.home.happy` | `page.home.happy` | 171 |
| `page.home.reserved` | reserved | 35 | 90 | page | `page.home.reserved` | `page.home.reserved` | 178 |
| `page.redaction.reserved` | reserved | 35 | 90 | page | `page.redaction.reserved` | `page.redaction.reserved` | 178 |
| `page.retention.reserved` | reserved | 35 | 90 | page | `page.retention.reserved` | `page.retention.reserved` | 178 |
| `page.row-history.reserved` | reserved | 35 | 90 | page | `page.row-history.reserved` | `page.row_history.reserved` | 178 |
| `page.shell.reserved` | reserved | 35 | 90 | page | `page.shell.reserved` | `page.shell.reserved` | 178 |
| `page.timeline.empty` | baseline | 62 | 90 | page | `page.timeline.empty` | `page.timeline.empty` | 171 |
| `page.timeline.reserved` | reserved | 35 | 90 | page | `page.timeline.reserved` | `page.timeline.reserved` | 178 |
| `page.transaction.reserved` | reserved | 35 | 90 | page | `page.transaction.reserved` | `page.transaction.reserved` | 178 |

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
