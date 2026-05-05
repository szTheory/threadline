# Roadmap: Threadline

## Current Milestone

- **v1.15 — Host Integration Completion** — Phases 49-52 (planned 2026-05-05) — [requirements](REQUIREMENTS.md)

## Overview

This milestone closes the remaining host-integration gap between Threadline's
credible operator/documentation surface and the smaller pieces Phoenix adopters
still have to invent themselves. It formalizes native `Threadline.Plug`
context overrides, direct Sigra host wiring, an authenticated incident
drill-down pattern in the example app, and the doc-contract updates that keep
that story stable.

## Phases

### Phase 49: Native Plug Context Overrides

**Goal**: Make additive request-context wiring a first-class `Threadline.Plug` capability instead of an example-only plug composition pattern.
**Depends on**: Phase 48
**Requirements**: PLUG-01, PLUG-02
**Plans**: 2/2 plans complete

Plans:
- [x] `49-01-PLAN.md` — Tighten `Threadline.Plug` override authority, precedence, and tests around the in-flight implementation.
- [x] `49-02-PLAN.md` — Align Sigra/quickstart docs and doc-contract tests with the narrowed override contract.

**Success criteria:**
1. `Threadline.Plug` accepts a native `:context_overrides_fn` callback and merges only allowed fields into the assigned `AuditContext`.
2. Invalid override shapes fail deterministically with targeted tests rather than being silently ignored.
3. Existing `actor_fn` behavior remains intact for hosts that do not use the new hook.

### Phase 50: Direct Sigra Host Wiring

**Goal**: Make the shipped Sigra integration the canonical direct host-wiring path through `Threadline.Plug`.
**Depends on**: Phase 49
**Requirements**: SIGRA-04, SIGRA-05
**Plans**: 2/2 plans complete

Plans:
- [x] `50-01-PLAN.md` — Converge the direct wiring contract in code and request-path tests.
- [x] `50-02-PLAN.md` — Align the canonical Sigra docs and drift guards.

**Success criteria:**
1. `Threadline.Integrations.Sigra` composes directly with `Threadline.Plug` via actor and context-override callbacks while keeping the library soft-dependency contract intact.
2. The Phoenix example app uses the direct callback pattern and no longer needs an example-only Sigra pre-plug for correlation wiring.
3. Sigra-focused tests cover the native hook integration path and protect the direct-wiring contract against drift.

### Phase 51: Authenticated Incident Drill-down

**Goal**: Turn the incident JSON drill-down path into a host-safe reference pattern by adding a clear authentication boundary and documenting what remains host-owned.
**Depends on**: Phase 50
**Requirements**: INCIDENT-03, INCIDENT-04
**Plans**: 2/2 plans complete

Plans:
- [x] `51-01-PLAN.md` — Converge the incident drill-down runtime path on one explicit authenticated baseline in the Phoenix example app.
- [x] `51-02-PLAN.md` — Align the incident-facing docs around the shipped authenticated baseline and add narrow drift guards.

**Success criteria:**
1. The example incident drill-down endpoint rejects anonymous requests and serves the existing response shape only to authenticated actors.
2. Example-app tests cover both the authorized success path and the anonymous rejection path.
3. Incident-facing docs explain the shipped auth baseline while explicitly keeping tenancy and richer authorization policy in host scope.

### Phase 52: Docs and Contract Alignment

**Goal**: Align adopter-facing guides and doc-contract tests around the native host-wiring pattern and the secured incident reference path.
**Depends on**: Phase 51
**Requirements**: ADOPT-03
**Plans**: 2/2 plans complete

Plans:
- [x] `52-01-PLAN.md` — Converge the adopter-facing guides and example README on one canonical host-wiring and incident-boundary story.
- [x] `52-02-PLAN.md` — Tighten the existing doc-contract suites so the final host-integration wording cannot drift silently across docs.

**Success criteria:**
1. Getting-started, Sigra integration, incident, domain-reference, and example README docs all describe the same native host-wiring pattern.
2. Contract tests lock the new public/docs literals so the host-integration story cannot drift silently.
3. The adoption backlog reflects the authenticated incident baseline accurately without claiming host-owned tenancy proof.

## Milestones

- ✅ **v1.14 — Drop-in Production Adopter Slice** — Phases 44-48 (shipped 2026-05-05) — [archive](milestones/v1.14-ROADMAP.md)
- ✅ **v1.13 — Docs Contract Repair** — Phases 41-43 (shipped 2026-04-26) — [archive](milestones/v1.13-ROADMAP.md)
- ✅ **v1.12 — Temporal Truth & Safety** — Phases 38-40 (shipped 2026-04-25) — [archive](milestones/v1.12-ROADMAP.md)

---

_For detailed scope, see `.planning/REQUIREMENTS.md`._
