# Phase 174: Form components - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-16
**Phase:** 174-Form components
**Areas discussed:** Form API contract, Rich interactive controls, Field layout composition

---

## Form API contract

| Option | Description | Selected |
|--------|-------------|----------|
| Form API contract | Use `Phoenix.HTML.FormField` structs vs passing explicit name/value/errors? (Note: `phoenix_html` is an optional dependency) | ✓ |
| Rich interactive controls | Native `<select>`/`<input type="date">` for zero-JS vs custom rich elements (requires LiveView JS hooks/commands) | |
| Field layout composition | Monolithic `<Field>` wrapper handling label+error+input vs explicit composition of distinct primitives? | |

**User's choice:** All options selected, requested deep one-shot research.
**Notes:** Decided against `phoenix_html` struct dependency to maintain the zero-dependency goal and support pure Plug adopters. Favored explicit `name`/`value`/`errors`.

---

## Rich interactive controls

| Option | Description | Selected |
|--------|-------------|----------|
| Form API contract | Use `Phoenix.HTML.FormField` structs vs passing explicit name/value/errors? (Note: `phoenix_html` is an optional dependency) | |
| Rich interactive controls | Native `<select>`/`<input type="date">` for zero-JS vs custom rich elements (requires LiveView JS hooks/commands) | ✓ |
| Field layout composition | Monolithic `<Field>` wrapper handling label+error+input vs explicit composition of distinct primitives? | |

**User's choice:** All options selected, requested deep one-shot research.
**Notes:** Recommended native HTML5 elements without custom JS hooks, leaning into Elixir/Phoenix idiomatic zero-JS approach where possible, ensuring 100% WCAG compliance.

---

## Field layout composition

| Option | Description | Selected |
|--------|-------------|----------|
| Form API contract | Use `Phoenix.HTML.FormField` structs vs passing explicit name/value/errors? (Note: `phoenix_html` is an optional dependency) | |
| Rich interactive controls | Native `<select>`/`<input type="date">` for zero-JS vs custom rich elements (requires LiveView JS hooks/commands) | |
| Field layout composition | Monolithic `<Field>` wrapper handling label+error+input vs explicit composition of distinct primitives? | ✓ |

**User's choice:** All options selected, requested deep one-shot research.
**Notes:** Recommended a monolithic `<.field>` component to reduce template duplication and ensure programmatically linked labels and errors, maximizing developer DX.

---

## Claude's Discretion

The user deferred to deep research-backed architectural recommendations for all areas, prioritizing great developer DX, UI/UX, and ecosystem idioms without interactive Q&A.

## Deferred Ideas

None
