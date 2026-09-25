# Phase 200: Public Surface - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-11
**Phase:** 200-Public Surface
**Areas discussed:** Public configuration contract, Canonical documentation homes, HexDocs organization, Contributor and security intake

---

## Public Configuration Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Document the current surface as-is | Lowest runtime churn, but freezes ambiguous or accidental configuration and extension details as permanent API. | |
| Curated explicit contract with exhaustive allowlists | Classifies every key/task/alias, publishes real extension points, keeps internals private, and enforces the result mechanically without redesigning runtime APIs. | ✓ |
| Façade-only docs plus namespaced config redesign | Produces a smaller long-term surface, but breaks existing keys and expands a cleanup phase into architectural API work. | |

**User's choice:** Discuss all areas, research them with subagents, and make the best cohesive recommendation so the user does not have to choose each detail.
**Notes:** Selected the curated contract with one scope correction to the research proposal: no new `put_file/2` callback or broad config redesign. `:storage_adapter` becomes explicit; the optional-`path/1` contradiction may receive a narrow behavior-preserving repair; polling keys become advanced documented configuration.

---

## Canonical Documentation Homes

| Option | Description | Selected |
|--------|-------------|----------|
| README-led HexDocs hub; task guides canonical | Uses the existing four intent lanes on GitHub and HexDocs while keeping each executable procedure in one versioned guide. | ✓ |
| `Threadline` module as HexDocs home | Familiar API-first landing, but creates a second navigation authority or duplicates the README routing model. | |
| Standalone documentation site | Maximum IA flexibility, but adds hosting, version synchronization, search fragmentation, and theme/accessibility maintenance far beyond this phase. | |

**User's choice:** Delegated to the researched recommendation.
**Notes:** Getting Started owns install/first hour, Operator Surface owns mount/authorization/overview, and Local Docker DX owns Docker lifecycle. Controlled summaries and deep links are allowed; competing command/config sequences are not.

---

## HexDocs Organization

| Option | Description | Selected |
|--------|-------------|----------|
| Group every currently visible module | Minimal visibility judgment, but presents runtime plumbing and maintainer tooling as supported public surface. | |
| Curate visibility and exhaustively group supported modules | Hides proven internals, retains adopter call paths/return types/extensions, and groups every visible page under a user-oriented taxonomy with set-equality tests. | ✓ |
| Façade-only documentation | Small index and maximum internal freedom, but hides valuable structs/extensions and creates an unnecessary pre-release compatibility reset. | |

**User's choice:** Delegated to the researched recommendation.
**Notes:** Fixed groups are Core API, Data Types, Configuration & Extension Points, Integrations, Operator Surface, and Mix Tasks. DESIGN-SYSTEM and the example README become version-pinned external resources in existing intent lanes rather than tarball contents. Native ExDoc theming and the current brandbook remain authoritative; no docs skin project.

---

## Contributor and Security Intake

| Option | Description | Selected |
|--------|-------------|----------|
| Lean GitHub-native structured intake | Three short issue forms, a short PR template, private vulnerability reporting, and a GitHub-scoped conduct policy; proportional to current project scale. | ✓ |
| Markdown templates with blank issues | Stable and flexible, but yields less consistent reports, more triage work, and a larger accidental-public-security-report surface. | |
| Discussions-first support | Separates questions from defects, but creates an unmonitored second queue before a responder community exists. | |
| External email/forum intake | Can be private, but no verified monitored Threadline inbox or forum exists; inventing one would be worse than a GitHub-native route. | |

**User's choice:** Delegated to the researched recommendation.
**Notes:** Use minimal accessible YAML forms with free-text versions, problem-first feature requests, and sensitive-data warnings. Use GitHub private vulnerability reporting for security, never a public issue. Use Contributor Covenant 3.0 with GitHub scope and GitHub Report Abuse for private conduct reports; do not invent a conduct email or overload Security Advisories.

---

## Research Basis

- Official ExDoc guidance: module hiding, external extras, module/extra grouping, versioned source links, and native generated-doc behavior.
- Official Elixir guidance: small explicit library APIs, behaviors for extension points, and caution around application environment as global state.
- Official Hex guidance: deliberate package file lists, versioned documentation, and pre-1.0 compatibility implications.
- Official GitHub guidance: community-health files, issue forms/templates, pull-request templates, private vulnerability reporting, and code-of-conduct placement.
- Elixir ecosystem comparisons: Ecto, Elixir, Phoenix, Oban, Ash, Swoosh, and Sentry Elixir.
- Cross-ecosystem lessons: Diátaxis-style separation of learning/tasks/reference, successful SDK security intake, and the recurring costs of duplicated quick starts and unmonitored support channels.
- Project-local authority: applicable `prompts/` research, Phase 198/199 context, current code/contracts, and the newer `brandbook/brand-book.md` rather than stale prompt-era brand material.

## the agent's Discretion

- The user delegated all detailed choices and asked the agent/subagents to produce one coherent recommendation.
- Exact prose, module order, guide successor links, test-file split, and external-extra mechanism remain implementation discretion inside the locked decisions.

## Deferred Ideas

- Namespaced config or new storage callback API — future API-design phase.
- Standalone docs site/custom skin — only when project scale justifies it.
- Discussions/support forum/private conduct inbox — only with a real monitored owner.
- Runtime rendered-output and structural work — Phases 201 and 203-204.
