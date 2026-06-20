# Phase 171: Audit baseline, stress-lab harness & idempotency ledger - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 171-Audit baseline, stress-lab harness & idempotency ledger
**Areas discussed:** Stress Route Boundary, Fixture Source Of Truth, Ledger Shape And Ratchet, Screenshot Baseline Policy

---

## Stress Route Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Add `/__stress` inside `threadline_operator_surface/2` behind `stress: true` | Canonical under every mount and close to mounted-tool idiom, but expands the adopter-facing API and risks public API creep. | |
| Example-app-only `/audit/__stress` route | Preserves public API cleanliness and uses the example harness, but can drift from library router behavior. | |
| Separate internal stress macro mounted only by example/test router | Keeps the production operator macro clean while preserving explicit Phoenix mounted-router shape and authenticated shell context. | yes |
| Standalone dev/test router or forwarded Plug | Strong isolation, but weaker LiveView/session realism and higher false-confidence risk. | |

**User's choice:** The user selected all areas and asked for subagent-backed one-shot recommendations so they did not have to choose manually.
**Notes:** Advisor recommendation: internal dev/test-only stress macro, mounted by the example app under the authenticated `/audit` scope at `/audit/__stress`; no `stress: true` option on the main public macro.

---

## Fixture Source Of Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Pure library-side fixture structs/assigns | Fast, deterministic, DB-independent, but can drift from real LiveView/query shapes. | |
| Example-app seeded DB data | Realistic and exercises routed workflows, but brittle/noisy for visual matrix and awkward for impossible edge states. | |
| Hybrid static story fixtures plus small seeded real-page fixtures | Static fixtures become design-system truth while seeded pages remain integration truth. | yes |
| Generated fixture matrix | Broad coverage but high bloat/noise risk if not curated. | |
| PhoenixStorybook-style internal variations | Good named-variation model without a dependency if implemented lightly, but premature as the only source before components exist. | |

**User's choice:** The user selected all areas and asked for cohesive recommendations.
**Notes:** Advisor recommendation: static library-side stress fixtures are canonical for `/audit/__stress`, ugly-data coverage, ledger IDs, and stress screenshots; example-app seeds remain a smaller real-page lane.

---

## Ledger Shape And Ratchet

| Option | Description | Selected |
|--------|-------------|----------|
| Markdown-only table in `DESIGN-SYSTEM.md` | Highly readable but brittle to parse and weak for no-regression semantics. | |
| JSON sidecar plus generated/readable `DESIGN-SYSTEM.md` projection | Strong schema, deterministic checks, good CI diagnostics, and matches existing JSON parity patterns. | yes |
| YAML sidecar plus markdown projection | Human-friendly but no parser exists and adding one violates the no-new-dep posture. | |
| Elixir module data source | Compile-time validation possible, but blurs app-source and design-ledger boundaries. | |
| ExUnit assertions over markdown-only sections | Lightweight, but still inherits markdown parsing fragility. | |

**User's choice:** The user selected all areas and asked for cohesive recommendations.
**Notes:** Advisor recommendation: JSON is the ratchet source of truth; `DESIGN-SYSTEM.md` v2 is the human-reviewed projection guarded by ExUnit freshness/schema/ratchet tests.

---

## Screenshot Baseline Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Broad full stress matrix in CI immediately | Maximum coverage but high flake, cost, and review-noise risk. | |
| Narrow critical screenshot set, expand per phase | Reviewable and aligned with fractal phases, but needs ledger enforcement to avoid permanent gaps. | yes |
| Semantic/computed CI smoke plus local-only broad screenshots | Deterministic and fast, but not sufficient alone for screenshot guard requirements. | |
| CI screenshots on pinned Linux/Playwright environment | Makes pixel failures actionable and avoids local platform noise. | yes |
| External visual service or Storybook-style baseline workflow | Mature UI review tooling, but conflicts with zero-dep/no-service/no-Storybook posture. | |

**User's choice:** The user selected all areas and asked for cohesive recommendations.
**Notes:** Advisor recommendation: combine a narrow high-signal CI screenshot allowlist with a pinned Playwright environment; keep full-matrix semantic/computed checks in CI and let the ledger ratchet more screenshots in later phases.

---

## the agent's Discretion

- User explicitly requested subagent-backed research across all areas and a cohesive recommendation set.
- Recommendations were locked without additional per-area prompts to honor the request for one-shot technical synthesis.

## Deferred Ideas

- Runtime dark/light/system theme picker implementation remains Phase 175.
- Coverage schema card declutter implementation remains Phase 176.
- Transaction page desktop centering implementation remains Phase 178.
