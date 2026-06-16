# Phase 173: Primitive components (extract + audit each in isolation) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-15
**Phase:** 173-Primitive components (extract + audit each in isolation)
**Areas discussed:** Component Module Structure, Component API Design (Attrs & Slots), Overlay Management

---

## Component Module Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Single module for primitives | (`Threadline.OperatorSurface.UI` or `CoreComponents`) keeping all primitives cohesive | ✓ |
| Many modules | File per component (e.g., `Threadline.OperatorSurface.Components.Button`) | |

**User's choice:** Single module for primitives
**Notes:** Auto-selected (recommended default). Avoids file explosion for simple pure functions, matching Phoenix's `core_components.ex` idiom.

---

## Component API Design (Attrs & Slots)

| Option | Description | Selected |
|--------|-------------|----------|
| Strict validation | Use explicit `@doc` and typed `attr`, failing at compile-time for typos | ✓ |
| Loose validation | Flexible props passing | |

**User's choice:** Strict validation
**Notes:** Auto-selected (recommended default). Ensures robust internal use.

---

## Overlay Management

| Option | Description | Selected |
|--------|-------------|----------|
| Phoenix.LiveView.JS commands | JS commands for simple toggles without custom JS hooks | ✓ |
| Custom JS Hooks | Dedicated alpine/JS logic for overlays | |

**User's choice:** Phoenix.LiveView.JS commands
**Notes:** Auto-selected (recommended default). Keeps the UI JS-light and fail-closed.

---

## Claude's Discretion

None.

## Deferred Ideas

None.
