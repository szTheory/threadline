# Phase 23: HTTP audited path - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in `23-CONTEXT.md`.

**Date:** 2026-04-24  
**Phase:** 23 — HTTP audited path  
**Areas discussed:** Proof strategy, HTTP actor, API surface, GUC/transaction layering (via parallel research + synthesis)

---

## User intent

User selected **all** gray areas and requested **parallel subagent research** (ecosystem, cross-language, DX, footguns) followed by a **single coherent recommendation set** aligned with Threadline vision—no further back-and-forth.

---

## 1. Proof strategy (test vs README vs both)

| Option | Description | Selected |
|--------|-------------|----------|
| Integration test via real Endpoint/Router | ConnCase HTTP through `Threadline.Plug`; assert `audit_changes` + transaction linkage | ✓ |
| README curl/httpie only | Human-friendly; weak CI honesty unless scripted | |
| Both | Test canonical; optional minimal README pointing at test | ✓ (optional README) |

**User's choice:** Research-synthesized — **primary = automated integration test** on `mix verify.example` path; **optional short README** with curl, test as source of truth.

**Notes:** Matches Rails `test/dummy` + CI patterns; avoids README drift; REF-03 satisfied by test branch; aligns with Phase 22 honest gates.

---

## 2. HTTP actor

| Option | Description | Selected |
|--------|-------------|----------|
| Synthetic `actor_fn` → stable `ActorRef` | No users table, no fake secrets | ✓ |
| Minimal API key / Bearer | Familiar but credential-like / security theater | |
| Nil actor + correlation only | Valid but weak for “who” teaching | |
| Full session auth | Out of scope noise for reference | |

**User's choice:** **Synthetic stable `ActorRef`** + document production replacement; show correlation/request headers in tests/README optionally.

---

## 3. API surface

| Option | Description | Selected |
|--------|-------------|----------|
| `POST /api/posts` only | Tracer bullet; REF-03 HTTP path | ✓ |
| Add `PATCH` | Second surface; CRUD creep before Phase 24 | |
| Context-only / no HTTP | Fails REF-03 intent | |

**User's choice:** **`POST /api/posts` only**; skinny controller + context.

---

## 4. GUC + transaction layering

| Option | Description | Selected |
|--------|-------------|----------|
| Context module owns `Repo.transaction` + `set_config` + writes | Phoenix-idiomatic; one boundary | ✓ |
| Controller-local | Duplication; bad for future LiveView/jobs | |
| Plug/Endpoint `set_config` | Wrong layer; PgBouncer footgun | |

**User's choice:** **Context** + optional small **private helper** for GUC prelude; controller delegates.

---

## Claude's Discretion

- Exact module naming; optional `Ecto.Multi`; whether to add README curl at all.

## Deferred ideas

- PATCH CRUD, real auth example, Hex-wide audit-transaction helper — see `23-CONTEXT.md` `<deferred>`.
