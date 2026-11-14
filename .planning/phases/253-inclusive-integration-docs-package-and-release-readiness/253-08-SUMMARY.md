---
phase: 253-inclusive-integration-docs-package-and-release-readiness
plan: "08"
subsystem: docs
tags: [migration, authorization, retention, font-provenance]
requires:
  - phase: 252
    provides: "Accepted mount and Retention behavior"
provides: ["Current unreleased authorization/Retention migration guidance", "Preserved historical font provenance"]
affects: ["253-09", "253-10"]
tech-stack:
  added: []
  patterns: ["Separate current unreleased changes from historical release claims"]
key-files:
  created: []
  modified: [guides/upgrade-path.md, test/threadline/upgrade_path_doc_contract_test.exs, priv/fonts/README.md]
requirements-completed: [ADM-29, ADM-34]
requirements-partial: []
actuals:
  tokens: null
  tasks: 1
status: complete
completed: 2026-11-13
coverage:
  - id: migration-and-font-history
    description: "Current mount/Retention consequences, supported recovery and preserved historical font provenance"
    verification:
      - kind: unit
        ref: "upgrade_path_doc_contract_test.exs and operator_surface/style_contract_test.exs"
        status: pass
    human_judgment: false
---

# Plan08 — Current migration guidance and historical fonts

**Final contribution:** independent goal verification passes5/5 roadmap truths and9/9 requirements with current required CI green. This plan contribution is complete at the named evidence boundaries. Historical pending checkpoints below preserve original failures and provenance; [final verification](253-VERIFICATION.md) and [CI results](253-CI-RESULTS.md) control the current result. REL-01 remains separate and no release/merge authority is inferred.

The upgrade guide adds a clearly unreleased section rather than rewriting the historical1.1 release's nothing-required statement. It describes usable unary authorization, the exact intentional-public acknowledgement in every environment, pipeline-only refusal, Preview retention → Review and confirm → exact-name Prune now, cancel/repreview, global configured-worker-store scope, sequential estimates and persisted/checkpoint distinctions. Target/policy/restart refusal and host-owned alignment/restart recovery are explicit; Pruner.trigger/0 remains unchanged. Compatibility matrix, support floors, version, public APIs and existing headings remain.

The old priv/fonts README now marks its directory as superseded, unshipped history and points to approved brand assets/licenses and the actual current compile-time source. Its inventory/download provenance and original font/license bytes remain. Font opt-out/fallback and CSP guidance are retained. The assigned style-contract owner contained no obsolete documentation-authority reference, so it was inspected and executed without an unnecessary edit; current styling, font fallback, palette, negative and CSP controls remain.

Task commit:b4117b66. Formatting exited0, diff whitespace check exited0, and both selected existing owners executed72 tests with0 failures. Local receipts: threadline-253-docs-migration-format-01.json and threadline-253-docs-migration-01.json. The receipt hashes bind the actual changed Markdown and test source. No browser, archive, current ExDoc rendering, hosted CI, publication or observed adopter comprehension is claimed by this plan. Independent review and phase-wide acceptance remain for09–11. No new dependency, schema, version or public configuration was introduced.

## Task commits

| Task | Commit | Description |
| --- | --- | --- |
| 1 | b4117b66 | Current unreleased migration guidance and historical font provenance |

First-wave post hooks ran after all six local summaries existed. Schema drift reported no schema files/drift. Codebase drift explicitly skipped because no STRUCTURE.md exists. UI safety found the approved UI-SPEC and did not block, but its task-commit scope was degraded; this is workflow routing evidence, not UI behavior acceptance. The initial flag-style UI invocation incorrectly resolved --phase and exited69 unreadable; the corrected positional invocation and all actual outputs are preserved in threadline-253-wave1-post-gates-01.json.
