# Phase 204: Structure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-23
**Phase:** 204-structure
**Areas discussed:** CSS byte lock, style.ex split, render extraction / size limits / register, shared test templates, ci.all dedup
**Mode:** Advisor, text mode. Five parallel gsd-advisor-researcher passes (calibration `minimal_decisive`), synthesized into one coherent set; maintainer replied "1" (accept whole set).

---

## CSS byte lock (STRUCT-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Golden `.css` + sha256 pins in one contract test | Diffable failure, literal committed hash, in verify.test | ✓ |
| sha256 module attribute only | Smallest; opaque mismatch, bisect by hand | |

**User's choice:** Accepted recommendation.

## style.ex split (STRUCT-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Ordered `.css` files read at compile time | Real CSS, no escaping/dedent hazard, no new modules | ✓ |
| Nine `@moduledoc false` segment modules with `~S` heredocs | Stays `.ex`; dedent/escaping risk, no CSS tooling | |

**User's choice:** Accepted recommendation (9 segments, pivot then tail-first peels).

## Render extraction, size limits, separators, register (STRUCT-03/04/07)

| Option | Description | Selected |
|--------|-------------|----------|
| Extract in place + family split + AST size gate + drain register to 0 | Honest end state, one exception (stress_fixtures) | ✓ |
| Extract listed monsters only, `.heex` templates, re-register remainder | Fewer commits; games the limit, carries debt | |

**User's choice:** Accepted recommendation.

## Shared test templates (STRUCT-05)

| Option | Description | Selected |
|--------|-------------|----------|
| One shared Endpoint + Router (LiveDashboard style) | Not viable: router macro mounts once per router | |
| `use`-macro templates generating per-file modules + OperatorSurfaceCase | Removes boilerplate, keeps per-file mount visible | ✓ |

**User's choice:** Accepted recommendation (16 files migrate, 3 documented exceptions).

## ci.all dedup (STRUCT-06)

| Option | Description | Selected |
|--------|-------------|----------|
| Delete `verify.doc_contract`; rehearsal derives by filename; drop critic_trust/mechanical from ci.all; alias-introspection guard | No second registry anywhere | ✓ |
| Keep `verify.doc_contract` via `@moduletag :doc_contract` | Tag is itself a drift-prone second definition | |

**User's choice:** Accepted recommendation.

## Claude's Discretion

- Module/segment names, ui.ex family membership, test helper name, guard-test placement, per-site flattening technique.

## Deferred Ideas

- End-Find-cluster CSS comment removal; widening bump rehearsal; multi-mount router macro; `boundary`; opt-in Credo checks (TYPES-01); re-verifying 199–203 at milestone audit.
