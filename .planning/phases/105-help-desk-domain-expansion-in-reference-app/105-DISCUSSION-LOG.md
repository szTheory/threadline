# Phase 105: Help-Desk Domain Expansion in Reference App - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the research-backed rationale.

**Date:** 2026-05-27
**Phase:** 105-help-desk-domain-expansion-in-reference-app
**Areas discussed:** All six (user requested full research synthesis, no manual Q&A)

---

## Org & ticket identity

| Option | Description | Selected |
|--------|-------------|----------|
| UUID in meta | Stable tenant key for scope + FK alignment | ✓ |
| Slug in meta | Human-readable but rename-orphans audit | |
| Dual meta keys | Extra sync burden | |
| Per-org ticket `number` + UUID PK | Walkthrough #4521 in capture diffs | ✓ |

**User's choice:** Research-backed recommendation (D-01) — no interactive pick.
**Notes:** Shopify/GitHub lesson: stable id for ACL, display number for support narrative.

---

## Semantic action catalog

| Option | Description | Selected |
|--------|-------------|----------|
| Only `:ticket_replied_and_closed` | Meets DEMO-02/UI-SPEC | ✓ |
| Large catalog now | Scope creep vs UI-SPEC | |
| Split reply/close actions | Breaks one-commit operator story | |

**User's choice:** D-02 — defer other atoms to 107/109.

---

## Redaction mode

| Option | Description | Selected |
|--------|-------------|----------|
| mask + store_changed_from | Column visible, value redacted | ✓ |
| exclude | Hides column from diffs | |

**User's choice:** D-03 — mask per UI-SPEC and ecosystem GDPR/HIPAA posture.

---

## Delete semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Hard DELETE + capture | `op = delete` on timeline | ✓ |
| Soft-delete primary | UPDATE not delete; confuses walkthrough | |

**User's choice:** D-04 — optional `:ticket_reply_deleted` deferred to 107.

---

## Test style

| Option | Description | Selected |
|--------|-------------|----------|
| DataCase + HelpDesk context | No routes in 105 | ✓ |
| sigra_conn help-desk tests | Violates AUTH-04 intent for 106 | |

**User's choice:** D-05 — ConnCase + real Sigra in 106.

---

## Agent ↔ user linkage

| Option | Description | Selected |
|--------|-------------|----------|
| agents.user_id required | Login = audit identity | ✓ |
| Standalone agents | Breaks 106/108 | |

**User's choice:** D-06 — roles on org_memberships, not agents table.

---

## Claude's Discretion

Context module naming, ticket status fields, number allocation in tests, whether minimal delete helper ships in 105 vs 107.

## Deferred Ideas

See CONTEXT.md `<deferred>` section.
