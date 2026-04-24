# Phase 32: Transaction-scoped change listing - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`32-CONTEXT.md`**.

**Date:** 2026-04-24  
**Phase:** 32 — Transaction-scoped change listing  
**Areas discussed:** API arity/repo · Ordering · Empty/malformed id · Preload · Naming  
**Mode:** User selected **all** gray areas; **five parallel subagent research passes** + maintainer **cohesive synthesis** (one-shot recommendations).

---

## API arity and repo placement

| Option | Description | Selected |
|--------|-------------|----------|
| A | Positional `Query.fun(repo, transaction_id)` | |
| B | Domain-first `Query.fun(transaction_id, opts)` + `Keyword.fetch!(opts, :repo)` | ✓ |
| C | Timeline-style `[transaction_id: tid]` filters + `timeline_repo!/2` | |

**User's choice:** **B** (cohesive synthesis; aligns with `history/3`, `actor_history/2`; avoids overloading timeline filter grammar in Phase 32).

**Notes:** Roadmap wording “repo and transaction_id” satisfied as explicit **`:repo`** + **domain id first**.

---

## Stable ordering within one transaction

| Option | Description | Selected |
|--------|-------------|----------|
| A | `captured_at` DESC, `id` DESC (match `timeline/2`) | ✓ |
| B | Ascending “replay” order | |
| C | `id` ASC only | |
| D | Document stability as composite `(captured_at, id)` only | ✓ (paired with A) |

**User's choice:** **A + D** — default order matches **`timeline_order`**; moduledoc states honest composite stability; **reject C** (UUID not monotonic with capture narrative).

---

## Malformed id vs empty result

| Option | Description | Selected |
|--------|-------------|----------|
| A | Always `[]` | |
| B | `ArgumentError` if malformed UUID; `[]` if query matches no rows | ✓ |
| C | Tuple API `{:ok, []}` / `:not_found` | |
| D | Document `Repo.get(AuditTransaction)` for 404 vs 200+[] | ✓ (integrator pattern, not library tuple) |

**User's choice:** **B** + document **D** for HTTP-style semantics at the app layer.

---

## Preload `:transaction`

| Option | Description | Selected |
|--------|-------------|----------|
| A | Plain `%AuditChange{}` only | ✓ (default) |
| B | Default preload `:transaction` | |
| C | Opt-in `preload: [:transaction]` | ✓ |
| D | Separate merged-select / map API | Deferred (export pipeline) |

**User's choice:** **A default, C opt-in** — matches **`timeline/2`** narrow select; no default preload surprise.

---

## Public function name

| Option | Description | Selected |
|--------|-------------|----------|
| `changes_for_transaction` | Generic | |
| `audit_changes_for_transaction` | Explicit capture vocabulary | ✓ |
| `list_changes_for_transaction` | `list_` prefix | |
| `transaction_changes` | Underspecified “changes” | |
| `by_transaction_id` | Filter-shaped, weak discoverability | |

**User's choice:** **`audit_changes_for_transaction/2`** on **`Threadline.Query`** and **`Threadline`**.

---

## Claude's Discretion

- **`ArgumentError` message** wording for invalid UUID.
- Strictness of **unknown `opts`** keys for the new function.

## Deferred Ideas

- Timeline filter unification for `:transaction_id`.
- Explicit ascending/replay ordering API.
- Flat export-style projection for single txn.
