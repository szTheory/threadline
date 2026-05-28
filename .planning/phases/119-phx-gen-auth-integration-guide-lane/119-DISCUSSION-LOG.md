# Phase 119: phx.gen.auth Integration Guide & Lane - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 119 — phx.gen.auth Integration Guide & Lane
**Areas discussed:** Adapter shape, Assign contract, Guide depth, Operator auth scope, Upgrade-path timing, Correlation strategy

**Mode:** User requested all six gray areas with subagent research + one-shot cohesive recommendations (no per-question interactive pass).

---

## 1. Adapter shape

| Option | Description | Selected |
|--------|-------------|----------|
| `Threadline.Integrations.PhxGenAuth` | Public module like Sigra; Phase 120 tests call it | |
| Guide-only inline snippets | Router lambdas only | |
| Host template module (`MyApp.AuditActor`) | Copy from guide; no new public API | ✓ |

**User's choice:** Host template module (guide-first, no `Integrations.PhxGenAuth`).

**Notes:** Sigra Tier-2 rationale applies to real optional deps only. phx.gen.auth is generated host code — observability libs (Sentry, OTel) use host hooks, not generator adapters. Avoids semver coupling to `role`/`is_admin` field drift.

---

## 2. Assign contract

| Option | Description | Selected |
|--------|-------------|----------|
| `current_scope` only | Phoenix 1.8+ canonical | ✓ (capture) |
| Dual-primary scope + `current_user` | Both equal in production | |
| `current_user` primary | Reject for 1.8+ | |
| Scope + optional legacy fallback | Scope-first; 1.7 note in guide | ✓ (compat) |

**User's choice:** `current_scope` → `user.id` for `actor_fn`; `authorize_fn` may use `current_user` after host bridge plug.

**Notes:** Matches `Integrations.Sigra` assign key; operator docs already use `current_user` for gates. Reference app `OperatorUser` is the bridge pattern to cite.

---

## 3. Guide depth

| Option | Description | Selected |
|--------|-------------|----------|
| Full sigra.md parity | Install, soft-dep, long contracts | |
| Minimal cookbook | Plug + authorize + non-goals only | |
| Medium parallel spine (~70–90 lines) | Same arc, link SSOT contracts | ✓ |

**User's choice:** Medium cookbook (Option C).

**Notes:** AUTH-GUIDE-02 requires authorize_fn in guide. Omit Install/soft-dep. "Reference semantics" replaces "Behaviors locked by SPEC."

---

## 4. Operator auth scope

| Option | Description | Selected |
|--------|-------------|----------|
| Admin-only `authorize_fn` | Defer other callbacks to operator-surface | ✓ |
| Full callback matrix | Like expanded getting-started mount | |
| Admin + `export_authorize_fn` example | | |

**User's choice:** Admin-only + export/LiveView footgun prose (no second callback snippet).

**Notes:** AUTH-GUIDE-02 + Phase 120 proof scope. RailsAdmin/Django pattern: mount + single gate in cookbook, matrix elsewhere.

---

## 5. Upgrade-path timing

| Option | Description | Selected |
|--------|-------------|----------|
| Full matrix row in 119 with "Phase 120" pointer | | |
| Defer all lane naming to 120 | | |
| Lane prose in 119; matrix row in 120 | | ✓ |

**User's choice:** Option C — narrative + vocabulary in 119; matrix + four-lane doc-contract when tests land in 120.

**Notes:** upgrade-path.md matrix claims "current in-repo proof only." Sigra shipped guide + example + matrix together; phx lane intentionally differs (no second example app).

---

## 6. Correlation strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Default `%{}` only | | ✓ (default) |
| Prescribe `phx-session:` formats | | |
| Host-defined + non-normative examples | | ✓ (optional patterns) |

**User's choice:** Default empty overrides; optional host patterns (traceparent → header, BFF header, `Audit.transaction/3`); no formats table.

**Notes:** Session-derived correlation collapses many requests. Sigra prefixes are lane-specific. django-auditlog / W3C trace context inform upstream header propagation, not Threadline-owned session IDs.

---

## Claude's Discretion

- Exact template module naming and doc-contract literal count (within D-08/D-10 bounds).
- Placement of cross-links inside `upgrade-path.md`.

## Deferred Ideas

- `Threadline.Integrations.PhxGenAuth`, Pow lane, `traceparent` parsing in core Plug, full operator matrix in phx guide, matrix row before tests, `phx-session:` correlation canon.
