# Phase 199: Decouple - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-10
**Phase:** 199-decouple
**Areas discussed:** Fixture topology and ownership, Evidence-reader contract, Deletion and repository hygiene, Dialyzer bootstrap policy

---

## Fixture Topology and Ownership

| Option | Description | Selected |
|--------|-------------|----------|
| Domain-scoped mirror | Preserve dataset concepts under one `test/fixtures/operator_surface/` owner; distinguish committed and generated lifecycles with precise path policy. | ✓ |
| Purpose-first split | Rename into `baselines/`, `oracles/`, and `generated/` to make lifecycle visible, at the cost of broader path/schema churn. | |
| Test-colocated fixtures | Place evidence beside individual ExUnit/Playwright consumers, at the cost of duplicating a corpus shared across languages and gates. | |

**User's choice:** Research all options and select the best cohesive recommendation.
**Notes:** Specialist review selected the domain-scoped mirror because it honors the required `git mv`, preserves byte-stable joins and vocabulary, minimizes behavioral churn, and gives the corpus one obvious owner. Immutable evidence and generated critic output remain separate by policy.

---

## Evidence-Reader Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit injection plus thin edge adapters | Keep shipped/pure code repository-agnostic; resolve repository paths only in ExUnit, Mix-task, TypeScript, and CI adapters. | ✓ |
| Central repository resolver | Give all callers one default resolver, but risk shipping repository layout as an apparent runtime contract. | |
| Application or Mix configuration | Configure roots globally, introducing mutable ambient state and adopter-visible settings for files excluded from Hex. | |
| Environment/CLI roots | Make language-neutral overrides primary, sacrificing hermeticity and discoverability. | |

**User's choice:** Research all options and select the best cohesive recommendation.
**Notes:** Explicit library inputs align with Elixir library guidance and Threadline's optional-integration architecture. Deterministically anchored edge adapters preserve command ergonomics. Explicit CLI flags remain overrides, not ambient defaults. Missing required evidence becomes an actionable hard failure.

---

## Deletion and Repository Hygiene

| Option | Description | Selected |
|--------|-------------|----------|
| Surgical deletion and citation repair | Delete proven-dead artifacts, repair live citations in the same logical change, and rely on Git history for recovery. | ✓ |
| Planning archive | Move debris into a retained archive, preserving HEAD-visible bytes but creating ambiguous authority and maintenance burden. | |
| Tombstones/redirects | Retain old paths as redirects, useful only for externally stable identifiers rather than private scratch artifacts. | |
| Retain and annotate | Keep artifacts in place, conflicting with DECOUPLE-03/04 and leaving executable footguns. | |

**User's choice:** Research all options and select the best cohesive recommendation.
**Notes:** The chosen policy preserves historical truth through minimal addenda and recovery SHAs, not stale files. Shared ignores stay precise and producer-owned. A disposable fresh clone—not the maintainer's current working tree—is the authority for clean-checkout proof. Formatter coverage respects child project rules.

---

## Dialyzer Bootstrap Policy

| Option | Description | Selected |
|--------|-------------|----------|
| Fix every warning before enabling | Strongest clean slate but risks swallowing the phase or trespassing on Phase 203 architecture work. | |
| Specific strict ignores with tighten-only ceiling | Fix narrow real defects, justify irreducible residue one entry at a time, and block all new warnings immediately. | ✓ |
| Generated broad baseline | Fast bootstrap but easily regenerated, noisy, and capable of hiding unrelated defects. | |
| Advisory then blocking later | Low initial disruption but leaves the refactor phases unprotected and can remain advisory indefinitely. | |

**User's choice:** Research all options and select the best cohesive recommendation.
**Notes:** The strict-ignore ratchet best matches the roadmap and Threadline's existing MODE-B pattern. The gate retains unknown/unmatched/extra-return signal, includes all nine optional applications in the PLT, fails unused filters, runs on the current CI lane and local `ci.all`, and documents measured cold/cache-hit cost.

## the agent's Discretion

- Exact path-adapter and helper names.
- Exact failure-message prose and optional `--update-fixtures` flag.
- Exact PLT directory, cache implementation details, measured timeout, ignore-ceiling constant location, and plan count.
- Whether to add a short ownership/regeneration README inside the fixture root.

## Deferred Ideas

- Public-surface vocabulary and maintainer-only module visibility remain Phase 200 work.
- Broad architectural repairs surfaced by Dialyzer remain Phase 203 work after exact Phase 199 triage.
- No UI/design changes were considered because Phase 199 has no visual surface.
