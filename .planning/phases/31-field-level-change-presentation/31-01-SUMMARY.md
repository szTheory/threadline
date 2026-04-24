---
phase: 31-field-level-change-presentation
plan: 31-01
subsystem: exploration
tags: [json, audit_change, export]
provides:
  - Threadline.ChangeDiff.from_audit_change/2 primary wire map
  - format: :export_compat branch mirroring Export.change_map/1 base keys
affects: [XPLO-01]
requirements-completed: [XPLO-01]
tech-stack:
  added: []
  patterns: [capability module alongside Query/Export]
key-files:
  created:
    - lib/threadline/change_diff.ex
  modified: []
key-decisions: []
duration: 25min
completed: 2026-04-24
---

# Plan 31-01 summary

Implemented **`Threadline.ChangeDiff`** with deterministic string-key primary output (`schema_version`, `before_values`, sorted `field_changes`, row identifiers, ISO `captured_at`) and **`:export_compat`** flat maps matching export id coercion and defaults.

## Task commits

Single implementation pass (tasks 31-01-01 + 31-01-02 combined in repository history for this run).

## Self-check

PASSED — `mix compile --warnings-as-errors`
