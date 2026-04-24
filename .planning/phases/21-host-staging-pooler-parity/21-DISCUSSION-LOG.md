# Phase 21: Host staging & pooler parity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `21-CONTEXT.md` — this log preserves research synthesis.

**Date:** 2026-04-23  
**Phase:** 21 — Host staging & pooler parity  
**Mode:** User requested **all** gray areas with parallel subagent research; principal agent merged outputs into one coherent decision set (no interactive Q&A turns).

**Areas covered:** (1) Evidence shape & home, (2) Maintainer vs integrator workflow, (3) OK/Issue/N/A semantics, (4) Topology narrative structure, (5) Repo affordances.

---

## Research synthesis (by area)

### 1. Evidence shape and home

| Theme | Notes |
|-------|--------|
| Hex-library idioms | Versioned guides + integrator-owned runbooks; avoid canonical OSS file as sole home for every host’s sensitive narrative. |
| Footguns | Secrets in git history; version skew vs Threadline semver; conflating CI pooler class with host HTTP/Oban; orphaned external links; maintainer-as-notary. |
| **Locked choice** | Hybrid **B + C**: in-repo rubric + template; filled evidence host-controlled + linked (see CONTEXT D-01–D-03). |

### 2. Maintainer vs integrator workflow

| Theme | Notes |
|-------|--------|
| OSS provenance | Fork + PR preserves authorship and review; maintainer proxy-paste weakens CLA/redaction clarity. |
| **Locked choice** | Maintainer structure; integrator fork+PR for attested host content; issues for coordination only (CONTEXT D-04–D-07). |

### 3. OK / Issue / N/A

| Theme | Notes |
|-------|--------|
| Matrix hygiene | N/A = documented omission with rule reference; Not run ≠ N/A; OK needs reproducible pointer. |
| **Locked choice** | Explicit definitions + CI vs host labeling (CONTEXT D-08–D-12). Integration “profiles” reserved for a **future** example-app world—not required wording for Phase 21 deliverables. |

### 4. Topology structure (STG-01)

| Theme | Notes |
|-------|--------|
| Operator reality | Pool **mode** + Ecto `prepare:` / pool counts; avoid Sandbox-in-prod confusion. |
| **Locked choice** | Fixed field block + paragraph + narrow backlog index table (CONTEXT D-13–D-15). |

### 5. Repo affordances

| Theme | Notes |
|-------|--------|
| Idiomatic Elixir | Doc contracts + `mix` tasks for repeatable ops; avoid generators as ongoing truth; skip heavy example/docker in this milestone. |
| **Locked choice** | Doc contract extension primary; optional thin index Mix task at discretion (CONTEXT D-16–D-18). |

---

## Claude's Discretion

- Optional STG index Mix task (**D-18**).
- Exact doc contract assertions once implementation starts.

## Deferred Ideas

- Phoenix sample app; heavy STG “validator” task — see CONTEXT `<deferred>`.
