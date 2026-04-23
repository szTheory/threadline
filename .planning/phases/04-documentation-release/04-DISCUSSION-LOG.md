# Phase 4: Documentation & Release - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `04-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-22
**Phase:** 04-documentation-release
**Mode:** `[--all]` gray areas + parallel **research subagents**; user requested one-shot cohesive recommendations (no interactive Q&A per area).
**Areas covered:** Release boundary & versioning; README vs HexDocs; Domain reference shape; ExDoc & `@moduledoc` surface

---

## Release boundary & versioning

| Option | Description | Selected |
|--------|-------------|----------|
| A — Human-gated publish | Phase ends at `mix hex.build` + `mix docs` + CI green; maintainer runs `mix hex.publish` | ✓ |
| B — CI auto-publish | Tag-driven `hex.publish --yes` | |
| C — Git-only until stable | No Hex until API frozen | |
| D — Prerelease as default | `0.1.0-dev` / `-rc` as primary install story | |

**Research notes:** Hex semver + prerelease resolution; `source_ref: "v#{@version}"` **404** risk when tag absent; SPDX licenses; `:files` must exist or use globs; Ruby/npm/changelog culture favors **CHANGELOG before first release**.

**User's intent (via orchestration):** Maximize **trust + least surprise**; first public version **`0.1.0`**; add **LICENSE** + **CHANGELOG**; fix **`source_ref`** policy.

---

## README vs HexDocs

| Option | Description | Selected |
|--------|-------------|----------|
| A — `main: "readme"` | README as HexDocs home | |
| B — `main: "Threadline"` | Module landing + guides | ✓ |
| C — `main: "overview"` guide | Phoenix-scale book (defer until many guides) | |

**Research notes:** Ecto/Oban/NimblePool favor **module `main`** or dedicated overview **guide**, not duplicating a fat README; **anti-drift**: long examples in guides / doctest-backed `@doc`, README stays thin.

---

## Domain reference

| Option | Description | Selected |
|--------|-------------|----------|
| A — Single `guides/domain-reference.md` | One ExDoc extra + GitHub browse | ✓ |
| B — Many small guides | Per-entity files | |
| C — ADR folder as primary vocab | Wrong genre for onboarding | |
| D — Wiki-only | Version drift | |

**Research notes:** **Persistence tier legend** for Correlation; ASCII in fenced **`text`** blocks; ADRs ≠ domain reference.

---

## ExDoc & module docs

| Option | Description | Selected |
|--------|-------------|----------|
| A — Rich schema `@moduledoc` + `@moduledoc false` internals | Operator-friendly HexDocs | ✓ |
| B — `api_reference: false` | Narrative-only (Oban-style) | |
| C — “Internals” group only | Still public; footgun | |

**Research notes:** **`groups_for_modules`** does not hide; **`@moduledoc false`** is the standard hide; Plug callbacks rely on **`@moduledoc`** + behaviour docs unless plug-specific detail needed.

---

## Claude's Discretion

Minor sidebar labels, badge set, exact doctest coverage per function — left to planner/executor within `04-CONTEXT.md`.

## Deferred ideas

See `<deferred>` in `04-CONTEXT.md` (TOOL-03, auto-publish, changelog growth).
