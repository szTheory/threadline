---
phase: 252-complete-operations-and-connected-catalog-review
plan: "02"
subsystem: ui
tags: [phoenix, storybook, operations, retention, exports]
requires:
  - phase: 252-01
    provides: "Safe transient preview and exact-target worker coordination"
provides:
  - "Reachable Operations Export/Retention catalog with pure deterministic projections"
  - "Shared actual production history/preview renderers and unique static composition IDs"
  - "Existing semantic resource/route links, current five-case mounted smoke and bound pixels"
affects: ["252-03", "252-04", "Phase253 inclusive integration"]
tech-stack:
  added: []
  patterns: ["Static projections never establish host capability or lifecycle proof", "Recorded unknown counts remain distinct from zero"]
key-files:
  created:
    - examples/threadline_phoenix/storybook/operations/index.exs
    - examples/threadline_phoenix/storybook/operations/exports.story.exs
    - examples/threadline_phoenix/storybook/operations/retention.story.exs
    - lib/threadline/operator_surface/live/retention_history_live/components.ex
  modified:
    - examples/threadline_phoenix/storybook/index.exs
    - examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex
    - examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs
    - lib/threadline/operator_surface/live/export_status_live/components.ex
    - lib/threadline/operator_surface/live/retention_history_live.ex
    - examples/threadline_phoenix/e2e/support/operator-journey-inventory.json
    - examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts
    - examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts
    - test/fixtures/operator_surface/source-surface-checklist.json
key-decisions:
  - "Optional internal Export renderer ID follows a real duplicate-ID counterexample; live defaults remain unchanged"
  - "Share read-only Retention markup; keep server mutation state out of static fixtures"
  - "Qualify recorded aggregate counts and disclose unknown omissions"
patterns-established:
  - "Current exact titles/results, raw no-write snapshots and fresh selected capsule identity"
requirements-completed: []
actuals:
  tokens: null
  executor_usage: null
  tasks: 3
status: complete
completed: 2026-11-13
coverage:
  - id: D-06-D-09
    description: "Actual production compositions, pure projections, connected inventory and bounded mounted proof"
    verification:
      - kind: integration
        ref: "13 example cases, affected live/dependency/source owners and33 Node cases"
        status: pass
      - kind: browser
        ref: "252-PAIR-EVIDENCE.md; five exact catalog cases retries0 and current14 images"
        status: pass
    human_judgment: false
---

# Plan02 — Connected Operations catalog

Operations Export and Retention are reachable in the existing dev/test PhoenixStorybook. Export uses production job_history with unchanged live IDs by default; static compositions have explicit unique IDs. Retention shares the actual read-only production history and preview presentation. Pure fixtures provide separated ordinary/edge projections, literal legacy statuses and no mutation target. Existing semantic route/job/source/proof references connect to the actual catalog; no registry, adapter, package or public surface was added.

[Evidence](252-PAIR-EVIDENCE.md) records source 794d0fa2a4b4872dc8b77182c84b24573292f66c, actual current app/DB/options, selected after-02 pixels, earlier failures and proof boundaries. The current five-case catalog browser report passes first attempt, retries0, no skip/flaky result; current14 images and two real preview no-write comparisons are sealed. Four default scenes have byte-checked unchanged assets/styles and matching original audit/operational values; clocks and housekeeping setup differences remain explicit. These are selected local results, not full canonical, host-permission, persistence, reconnect, zoom or human-UAT acceptance. Plan03 and independent Plan04 judgments remain pending.

## Task and corrective commits

- `cae83202` — Operations branch, actual Export renderer, pure fixtures and demonstrated duplicate-ID remedy.
- `17dfcb8b` — actual shared Retention renderers/story and live/static read-only regression proof.
- `b9e1afe3` — existing inventory/resource links, moved source anchors and actual mounted targets.
- `47ef32dd` — corrected acknowledgement uncertainty and direct-token confirmation authority ordering.
- `ea41c860` / `794d0fa2` — honest missing measurements and qualified recorded aggregates with zero/nonzero/unknown controls.

## Deviations and lessons

The demonstrated duplicate-ID defect required one extra existing Export component owner, permitted by the plan's defect-only condition; it is not an unrelated Export rewrite. No public API/config/schema or version change occurred. Actual static rendering, tag-aware assertions and current mapped declarations caught gaps source-only checks had not covered. Preserve the rejected timeout reproduction, source/setup mistakes and automatic-review rejection; do not convert failures into successful proof or renew any stopped window. The retained [retrospective](../../research/2026-11-12-autonomous-run-retrospective.md) remains in progress until actual autonomous closeout.

## Threat flags and limits

Independent security/UI/source/goal review is pending; no risk was accepted. The catalog-transparency prohibition remains flagged-unverified in the engine, assessed separately from actual composition behavior. Package1.1.0/PhoenixStorybook1.2.0 and the original native/full-root/foreground/hosted stops remain unchanged. Requirements are not marked wholly complete before the full phase verdict.

## Self-check

All task/corrective commits exist; current selected catalog/static/live evidence is bound and retained. This is Plan02 completion only. The parent continues Plan03 in the same GSD checkout; no user action is needed.


## Current contracted-width gap closure

Current final-source catalog5 passes, retries0/no skips/flakes; ordinary data unchanged and after04 remains selected. See the exact current receipt and preserved initial gap in [252-VALIDATION.md](252-VALIDATION.md). Same verifier owns final closure.
