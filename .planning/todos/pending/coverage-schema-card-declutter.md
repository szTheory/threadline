---
created: 2026-06-13T00:00:00Z
updated: 2026-06-20T12:25:36Z
title: Coverage audit-readiness IA, schema affordance, and duplicate remediation copy
area: operator-surface
origin: User demo feedback after Phase 179/180 operator-surface review; replaces the old card-declutter framing completed by Phase 176 DATA-05.
files:
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/coverage/on_mount.ex
  - lib/threadline/operator_surface/coverage/snapshot.ex
  - lib/threadline/health.ex
  - lib/mix/tasks/threadline.health.coverage.ex
  - lib/mix/tasks/threadline.verify_coverage.ex
  - lib/threadline/operator_surface/style.ex
  - test/threadline/operator_surface/live/coverage_live_test.exs
  - test/threadline/operator_surface/coverage_doc_contract_test.exs
  - test/threadline/operator_surface/coverage_mix_test.exs
  - examples/threadline_phoenix/e2e/tests/operator-features.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts
  - guides/operator-surface.md
---

## Problem

The previous "Coverage - schema: public" card-declutter todo is no longer the real issue. Phase 176
already flattened the old `tl-coverage-command` nesting, but `/audit/coverage` still feels accidental
in the current demo:

- Schema selection exists only as `?schema=NAME`, so the UI says `Coverage - schema: public` without
  an obvious way to switch schemas or understand whether coverage is schema-scoped.
- The same readiness signal is repeated in multiple places: the trust rail chip, the metric card,
  the remediation panel, table rows, and footer summary all restate "need capture".
- The page-level `Open timeline` action competes with the Coverage job even though Timeline should
  already be available through the shell navigation.
- Non-public coverage links can be misleading because row-level `View activity` links currently risk
  carrying only `table` instead of the selected `table_schema`.
- CoverageLive has page/header split-brain risks: the shared header coverage poll is public-only,
  while the page can render another schema; page refresh/polling and error messages need to remain
  scoped to the selected page schema.

The operator job is: "Before I rely on timeline/evidence answers, tell me which app tables in this
schema have capture triggers, which are intentionally excluded, and exactly what to fix next."

## Solution

Redesign Coverage around one readiness verdict and one schema scope:

- Keep `/audit/coverage` and `/audit/coverage?schema=public` as the default public-schema URL state.
- Add a visible `Schema` control on the page. Use URL params as the canonical state so links remain
  shareable. When more than one eligible schema exists, make the available schemas discoverable.
- Add a pure, Phoenix-free helper such as `Threadline.Health.CoverageSchemas` for boundary concerns:
  conservative lowercase schema validation, parameterized `pg_namespace` existence checks, and
  available-schema discovery. Keep `Threadline.Health.trigger_coverage/1` as the low-level trusted
  catalog function.
- Do not overload `schema=all`; `all` can be a valid PostgreSQL schema. Defer all-schema aggregation
  unless it is designed as a distinct scope with schema-qualified rows and a non-conflicting param.
- Change the H1 to `Audit coverage`; show `Schema: public` and checked-at metadata as page meta/control
  rather than in the title.
- Remove the top-level `Open timeline` button. Keep only contextual row actions such as `View activity`,
  and include `table_schema` for non-public schemas.
- Collapse duplicated readiness copy into one primary summary plus compact counts and table actions.
  The remediation copy should explain the next action once, not repeat the same count again.
- Render page-specific coverage errors from the selected schema result, not only the shared header
  `threadline_coverage_error`.

## Acceptance Criteria

- `/audit/coverage` shows `Audit coverage`, the selected schema, checked-at metadata, and one primary
  readiness verdict.
- A user can switch to a valid schema through visible UI; invalid schema input remains rejected by the
  existing lowercase/namespace safety contract.
- No top-level `Open timeline` CTA renders on Coverage.
- The "need capture" count is not simultaneously repeated as trust rail, metric card, remediation chip,
  footer, and row label. Rows still carry their own status.
- `View activity` links include `table_schema` whenever the selected schema is not `public`.
- Manual refresh and any page-specific poll preserve and update the selected schema state.
- Docs explain that the header badge remains public-schema scoped unless a later all-schema header
  feature is explicitly designed.
