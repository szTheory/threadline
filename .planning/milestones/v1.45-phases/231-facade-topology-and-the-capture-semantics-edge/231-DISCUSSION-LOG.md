# Phase 231: Facade Topology and the Capture/Semantics Edge - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md. This log preserves the alternatives considered.

**Date:** 2026-10-03
**Phase:** 231-facade-topology-and-the-capture-semantics-edge
**Areas discussed:** Escape-hatch linkability, `.action` struct shape and hydrate helper, Guide rewrite reach and contract test, Public `preload: :action`
**Mode:** advisor (minimal_decisive). Four parallel researchers ran before the first question; the result was one roll-up confirm plus one HIGH-IMPACT question.

---

## Escape-hatch linkability

| Option | Description | Selected |
|--------|-------------|----------|
| Plain-text mention + `skip_code_autolink_to` | Name `Threadline.Query.timeline_query/1` as inline code; ExDoc cannot link to hidden targets; clean `--warnings-as-errors` build | ✓ |
| Facade delegate `Threadline.timeline_query/1` | Real link, but deviates from the requirement and adds surface | |

**User's choice:** Accepted the recommendation (roll-up).
**Notes:** Verified in the installed ExDoc 0.40.1 source.

## `.action` struct shape and hydrate helper

| Option | Description | Selected |
|--------|-------------|----------|
| Virtual `:any` field, default nil + internal batched helper | Only shape that passes `__schema__(:associations)`; honors storage prefix | ✓ |
| Keep association behind runtime indirection | Fails SC3 outright | |

**User's choice:** Accepted the recommendation (roll-up).

## Guide rewrite reach and contract test

| Option | Description | Selected |
|--------|-------------|----------|
| New dedicated facade-only contract test; rewrite all 5 guides + example script; `export_changes_query/1` → export facade prose | Separate concern from the ownership-tag contract | ✓ |
| Extend `public_surface_contract_test.exs` | Conflates two contracts | |

**User's choice:** Accepted the recommendation (roll-up).

## Public `preload: :action` (HIGH-IMPACT)

| Option | Description | Selected |
|--------|-------------|----------|
| Keep it working, warn | Pull `:action` out, hydrate it, one deprecation warning; nested keys raise; removal in 2.0 | ✓ |
| Raise a clear ArgumentError | Researcher's pick; hard break on upgrade | |

**User's choice:** Keep it working, warn.
**Notes:** Orchestrator overrode the researcher to match Phase 232's "working call + one warning" promise; the user confirmed.

## Claude's Discretion

- Helper placement (inside `query.ex` or a hidden submodule), the warning mechanism and wording, and the rewritten prose.

## Deferred Ideas

- Remove the preload compatibility path in 2.0; a composable export-query facade wrapper; full alias resolution in the scanner.
