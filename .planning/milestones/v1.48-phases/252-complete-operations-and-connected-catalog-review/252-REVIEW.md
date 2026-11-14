---
phase: 252-complete-operations-and-connected-catalog-review
reviewed: 2026-11-13T13:17:12Z
depth: deep
reviewed_revision: 74fe8df2b2520868d464eca93054492fc93a2cad
previous_reviewed_revision: e79f7837e6e9817e739933c85d9579f436f42446
runtime_revision: 74fe8df2b2520868d464eca93054492fc93a2cad
previous_runtime_revision: 7cca0a1830949c31fec4a90d2719ef1f0fcb4056
baseline_revision: b1888177648ef468c6d2bfc1cc1645f860fd2e4b
files_reviewed: 20
files_reviewed_list:
  - examples/threadline_phoenix/e2e/support/operator-journey-inventory.json
  - examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts
  - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts
  - examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex
  - examples/threadline_phoenix/storybook/index.exs
  - examples/threadline_phoenix/storybook/operations/exports.story.exs
  - examples/threadline_phoenix/storybook/operations/index.exs
  - examples/threadline_phoenix/storybook/operations/retention.story.exs
  - examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs
  - lib/threadline/operator_surface/live/export_status_live/components.ex
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/retention_history_live/components.ex
  - lib/threadline/operator_surface/style/02_base_shell.css
  - lib/threadline/retention/pruner.ex
  - test/fixtures/operator_surface/route-inventory.json
  - test/fixtures/operator_surface/source-surface-checklist.json
  - test/threadline/operator_surface/live/retention_history_live_test.exs
  - test/threadline/retention/pruner_test.exs
  - test/threadline/retention_test.exs
delta_files_reviewed_list:
  - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
  - examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex
  - examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/retention_history_live/components.ex
  - lib/threadline/operator_surface/style/02_base_shell.css
  - test/threadline/operator_surface/live/retention_history_live_test.exs
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
  necessity: 0
status: clean
---

# Phase 252: Code Review Report

**Reviewed:** 2026-11-13T13:17:12Z
**Depth:** deep, with bounded delta confirmation
**Files Reviewed:** 20 unique source/test files
**Status:** clean for source review

## Summary

The initial review at `e79f7837e6e9817e739933c85d9579f436f42446` identified two source findings. This bounded review examined the seven-file delta at `74fe8df2b2520868d464eca93054492fc93a2cad`; every delta-manifest hash matches. Both initial findings are resolved in the current source: active counts are excluded from finished-run aggregates and rendered as progress, failed checkpoint counts are qualified as incomplete, nil outcomes remain unrecorded, and the partial Storybook summary now derives completion from the scenario's actual runs. No current source findings remain.

Parent-supplied receipts report 128 root tests and 13 example tests passing; the retained pre-fix reds reproduced the count and partial-story defects. I inspected those receipts and source, but did not run tests, builds, or browsers. The after-capture receipt records source HEAD `74fe8df`; its completion is not a pixel judgment. The exact touch/focus hit-test and refreshed pixel review remain pending, so this source verdict does not close the UI gate. `Pruner.trigger/0` and Export's live default renderer behavior remain compatible.

## Source-side UI criteria and limits

- **U1 Export:** the default job-history renderer and live DOM IDs remain unchanged; the optional ID is scoped to static stories. Export routes, jobs, and actions remain shared with the production renderer.
- **U2 Retention preview:** pending, unavailable, successful-zero, cleanup-disabled, and server-held confirmation states remain separate. Authorization surrounds the asynchronous read, and a changed mounted/worker target is refused. The loading announcement now matches the specified “Previewing retention estimates…” copy.
- **U3 Retention history:** queued runs show “Not started,” running counts are qualified as “recorded so far,” active rows are excluded from the finished-run aggregate, and failed checkpoints are explicitly qualified. Nil and completed zero remain distinct. The partial static scenario now reports “No completed run yet.”
- **U4 catalog:** Operations remains discoverable from the existing PhoenixStorybook index; deterministic static fixtures share read-only renderers, avoid Repo/seed/file-write/mutation calls, and disclaim what static composition proves.

These are source-intent observations across the 30 U1–U4 criteria, not a visual score or proof that every state meets its pixel contract. The three descriptorless prohibition intents remain unresolved and flagged: ADM-23 must not imply an unscoped background export is tenant-scoped or acceptance is persisted completion; ADM-24 must not imply sequential estimates are atomic, guaranteed removals, or recorded outcomes; ADM-25 must not present static stories as proof of permissions, query results, downloads, persistence, or reconnect safety. No enforcement descriptor, engine pass, or human approval is inferred. Native clipboard, full-root, foreground, and hosted acceptance remain unproven.

## Bounded delta scope

All seven source/test paths below match the supplied delta manifest at `74fe8df2b2520868d464eca93054492fc93a2cad`:

| File | SHA-256 |
|---|---|
| `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | `51f18146637e358202db4c1363e3353317664e22dfbb701d159d75063b3a87d1` |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex` | `c57a97f028dd1b799320776d030999e58265f84c28b1747660a91c1d5ab935a2` |
| `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs` | `53d942c165457e37de3b5b23fc07022865c6db59db733598171c211c91891c5b` |
| `lib/threadline/operator_surface/live/retention_history_live.ex` | `5f3b53c28c1a7e276899aa73b99b9b51763d469060a49ae4ea8fe01703569d84` |
| `lib/threadline/operator_surface/live/retention_history_live/components.ex` | `cf3e4a006ac2b5945c821b3717c20952f8652367a0e013df8da258624ae4e1db` |
| `lib/threadline/operator_surface/style/02_base_shell.css` | `3035c059e8f6f4d1f2d2f56032c4926b836d39b25dfd86a7d267b544ae92b523` |
| `test/threadline/operator_surface/live/retention_history_live_test.exs` | `31c1a8bcd541a7d0914e976cd5adb943ad64becc84176b9b14e2656a7e01efd8` |

The delta also adjusts the Retention page to use the existing stack-gap primitive and lowers sticky header/navigation layers from toast level to the existing header token (30), below the modal/subview token (50). The source-level loading status is the specified copy. The supplied `modal-layer-red-01` receipt records the earlier failed painted-heading hit-test before the CSS change; no passing hit-test is claimed here.

## Narrative Findings (AI reviewer)

No open source findings at `74fe8df2b2520868d464eca93054492fc93a2cad`.

## Initial Findings History — resolved in the bounded delta

### Initial CR-01 (BLOCKER): Progress or unknown deletion counts were presented as final outcomes — RESOLVED

The initial issue was in the shared history renderer and aggregate: queued/running placeholder or checkpoint counts appeared as final deleted totals, and a nil failed count fell back to zero. The delta now aggregates only completed/failed records, labels active rows as not started or recorded-so-far, qualifies failed counts as last checkpoints that may be incomplete, and preserves nil as unrecorded. The root LiveView regression covers nil and zero separately and tests failed counts 0, 1, and 7 plus active-row exclusion. `outcome-review-red-01` preserved two meaningful pre-fix failures; `review-delta-root-01` reports the corrected root owner and contracts passing 128 tests.

### Initial WR-01 (WARNING): Partial Retention story claimed a completed run that was absent — RESOLVED

The initial `:partial` fixture contained only a pending run but borrowed the ordinary fixture's completion timestamp. The delta now finds a completed run within that scenario and reports “No completed run yet” when none exists; the Storybook contract asserts both the summary value and rendered copy. `partial-story-review-red-02` reproduced the date leak before the correction; `outcome-story-green-01` reports 13 example tests passing. An earlier selector that ran a different Export test is not counted as causal evidence for this finding.

---

_Reviewed: 2026-11-13T13:17:12Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep; bounded delta from `e79f7837`_
