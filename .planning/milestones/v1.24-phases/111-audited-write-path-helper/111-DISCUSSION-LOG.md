# Phase 111: Audited Write-Path Helper - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 111-Audited Write-Path Helper
**Areas discussed:** Return contract, Action recording policy, Missing actor_ref behavior, Callback API (all four — user requested full research + one-shot recommendations)

---

## Return contract — how callers get audit_transaction_id

| Option | Description | Selected |
|--------|-------------|----------|
| Third tuple `{:ok, val, meta}` | Separates domain from audit metadata | |
| **Merge into callback map** | `{:ok, %{post: p, audit_transaction_id: id}}` when callback returns map | ✓ |
| Fixed envelope `%{result:, audit:}` | Always namespaced; no key collision | |
| Result struct | Typed but ceremony-heavy | |
| Side channel (Process dict) | Implicit, untestable | |

**User's choice:** Auto-resolved via research synthesis (user requested one-shot coherent recommendations).
**Notes:** Two-tuple only (`{:ok, result}`) matches `Repo.transaction/1`. Map merge preserves Blog/HelpDesk/controller patterns. Non-map callback returns wrapped as `%{result:, audit_transaction_id:}`.

---

## Action recording policy — correlation-ready vs capture-only

| Option | Description | Selected |
|--------|-------------|----------|
| Action always required | Every write gets semantic action | |
| **`:action` opt triggers record+link; omit = capture-only** | Recommended path is explicit; correlation opt-in | ✓ |
| Default record+link with opt-out | Safe default but noisy for batch | |
| Separate `capture_transaction/2` function | Clear API split; two docs to learn | |

**User's choice:** Auto-resolved — Option B with `:capture_only: true` explicit alias.
**Notes:** Aligns with AUDIT-TXN-01 "optionally records" and SEED-001 linkage foot-gun. Does not collapse capture/semantics models. Phase 112 fixes `touch_post_for_job` orphaned-action pattern.

---

## Missing actor_ref behavior

| Option | Description | Selected |
|--------|-------------|----------|
| **Fail before transaction** | `{:error, :missing_actor}` like Blog today | ✓ |
| Fail inside transaction rollback | Wasted work | |
| Implicit anonymous on nil | NULL actor conflated with guest | |
| `allow_missing_actor: true` opt-in | Capture-only escape hatch | ✓ (secondary) |
| Actor required only when `:action` present | Split policy | ✓ (baked into validation) |

**User's choice:** Auto-resolved — fail fast default + documented escape hatch.
**Notes:** Explicit `ActorRef.new(:anonymous)` for unauthenticated SaaS writes. Nil ≠ anonymous. Matches CloudTrail typed-principal model and domain reference ActorRef taxonomy.

---

## Callback API — what host code receives inside the transaction

| Option | Description | Selected |
|--------|-------------|----------|
| **`fn -> result end`** (Repo in closure) | Helper owns GUC + action + link | ✓ |
| `fn repo, ctx -> ...` | Redundant second authority | |
| Macro DSL | Over-engineered; hard to doc-contract | |
| Ecto.Multi integration | Valid later; nested tx footgun now | |
| Pre-merged action opts in callback arity | Belongs in outer opts, not callback | |

**User's choice:** Auto-resolved — zero-arity callback; helper owns all audit ceremony.
**Notes:** Matches Phoenix context + Ecto explicit orchestration (OSS DNA, scrypath prior-art). `audit_context:` sugar for Plug paths. Forbidden: set_config, record_action, nested transaction inside callback.

---

## Claude's Discretion

- Internal module decomposition within `Threadline.Audit`
- Optional private Result struct for typing only
- Test file naming/organization

## Deferred Ideas

- Ecto.Multi first-class support — future if adopter demand
- Public Result struct return type — rejected for ceremony
- Example app adoption — Phase 112
- Static lint for forbidden callback ops — future
