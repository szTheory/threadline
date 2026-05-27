---
phase: 105
slug: help-desk-domain-expansion-in-reference-app
status: approved
shadcn_initialized: false
preset: none
created: 2026-05-27
reviewed_at: 2026-05-27
---

# Phase 105 — UI Design Contract

> Visual and interaction contract for Phase 105. This phase ships help-desk domain, capture, and semantics in `examples/threadline_phoenix/` only (`lib/` read-only). There are **no new screens, routes, or LiveViews** in scope. The contract locks how help-desk audit data must read on the **existing** mounted `/audit` operator surface (Phase 98 baseline) and what product UI is explicitly deferred.

---

## Phase UI Boundary

| In scope (Phase 105) | Out of scope (deferred) |
|----------------------|-------------------------|
| Ecto schemas, migrations, contexts, triggers, capture config, integration tests | Help-desk product landing, ticket inbox, agent console (`Phase 109` RUN-01) |
| `organization_id` on `audit_transactions.meta` for org-scoped operator queries | Sigra signup/login/logout templates (`Phase 106`) |
| Semantic actions (`:ticket_replied_and_closed`, etc.) visible via existing timeline/transaction UI | `mix demo.seed` / seeded walkthrough entities (`Phase 107`) |
| `ticket_replies.internal_note_body` masked at capture for operator redaction walkthrough | WALKTHROUGH.md narrative UI (`Phase 108`) |
| Coverage rows for new audited tables on `/audit/coverage` | Any `lib/threadline/operator_surface/*` edits |

**UI hint rationale:** Operators and maintainers will exercise new help-desk writes through the same `/audit` surfaces already mounted in the reference app. Phase 105 must not introduce ad-hoc styling or copy in the example app that diverges from the shipped operator surface.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none — inherit Phase 98 / `Threadline.OperatorSurface.Style` (`98-UI-SPEC.md`, `lib/threadline/operator_surface/style.ex`) |
| Preset | not applicable |
| Component library | Phoenix.Component + Phoenix.LiveView (existing operator surface only) |
| Icon library | none (unchanged) |
| Font | `system-ui, -apple-system, sans-serif` |

**Rule:** Phase 105 MUST NOT add parallel CSS, Tailwind, or component libraries under `examples/threadline_phoenix/` for audit exploration. Any future help-desk product chrome is a later-phase concern and must not fork operator tokens.

---

## Spacing Scale

Declared values (must be multiples of 4) — **unchanged from Phase 98**; executor does not alter operator spacing in this phase:

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, inline padding, monospace chips |
| sm | 8px | Compact row gaps, table cell inset, badge spacing |
| md | 16px | Default page padding, card padding, section spacing, empty states |
| lg | 24px | Gap between transaction header and change list |
| xl | 32px | Gap between filter block and results viewport |
| 2xl | 48px | Major error/unsupported breathing room only |
| 3xl | 64px | Do not introduce inside `/audit` for Phase 105 |

Exceptions: sticky header `36px`; history link rows ≥ `44px` touch height; pill badges `12px` radius — per Phase 98.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 14px | 400 | 1.5 |
| Label | 12px | 400 | 1.4 |
| Heading | 18px | 600 | 1.2 |
| Display | 18px | 600 | 1.2 |

Use only weights `400` and `600`. Table names, PK fragments, and action atoms stay monospace where the operator surface already uses monospace chips.

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `#FFFFFF` | Page background, sticky header, change list body |
| Secondary (30%) | `#F3F4F6` | Empty states, metadata chips, grouped headers |
| Accent (10%) | `#3B82F6` | `History` links, active filter state, timeline deep links |
| Destructive | `#EF4444` | Load failures and invalid filter state only |

Accent reserved for: `History` row links, active timeline filter affordances, and deep links to related transactions — same as Phase 98. Do not add help-desk-specific accent colors in the example app.

---

## Help-Desk Domain Vocabulary (Operator-Facing)

These names are **locked** for Phase 105 so timeline, transaction, coverage, and policy viewers stay consistent with capture and walkthrough scripts.

### Audited tables (physical names — shown verbatim in UI)

| Table | Operator label | Notes |
|-------|----------------|-------|
| `organizations` | `organizations` | Org root entity |
| `org_memberships` | `org_memberships` | Join table; expect lower row volume |
| `agents` | `agents` | Support/agent actors |
| `tickets` | `tickets` | Primary incident subject |
| `ticket_replies` | `ticket_replies` | Replies + internal notes column |

Do not introduce friendly aliases (e.g. "Ticket" title case) in capture payloads or tests unless the operator surface gains a host-owned label map in a **later** phase. Consistency with SQL and `mix threadline.*` output beats marketing labels here.

### Semantic actions (recorded via `Threadline.record_action/2`)

| Action atom | Intended meaning | Typical tables in one transaction |
|-------------|------------------|-----------------------------------|
| `:ticket_replied_and_closed` | Agent reply recorded and ticket closed | `ticket_replies`, `tickets` |
| (additional actions) | Planner may add only actions referenced by DEMO-02 tests and Phase 108 walkthrough seeds | Must follow `snake_case` atom convention |

Action names appear on linked `audit_actions` rows and existing timeline affordances — no new action-badge styling in Phase 105.

### Transaction metadata

Every help-desk context write that should participate in support read-only scoping MUST set `audit_transactions.meta` to `%{"organization_id" => org_id}` (string UUID or slug matching `scope_operator_query/3` in `router.ex`), patterned after `ThreadlinePhoenix.Blog.audit_transaction_meta/1`.

---

## Redaction & Policy Surfaces (DEMO-04)

**Capture config (example app):** `ticket_replies.internal_note_body` MUST be **masked** (preferred) or **excluded** under `config :threadline, :trigger_capture` in `examples/threadline_phoenix` config.

| Mode | Operator transaction diff expectation | Walkthrough expectation |
|------|--------------------------------------|-------------------------|
| **mask** (preferred) | Field `internal_note_body` present with after-value `"[REDACTED]"` (default placeholder) | Operators see redaction without losing column presence |
| **exclude** | Field absent from `field_changes` | Acceptable only if walkthrough step explicitly documents exclusion semantics |

**Policy viewer:** `/audit/policy/redaction` must list `ticket_replies` with `internal_note_body` under configured mask/exclude and show deployed trigger parity after `mix threadline.gen.triggers`. No sample note text in UI — column names only (existing policy viewer contract).

**Forbidden:** Persisting raw internal note bodies in `audit_changes` JSON for any walkthrough or test fixture.

---

## Copywriting Contract

Applies to **existing** `/audit` surfaces when displaying help-desk capture — not new CTAs.

| Element | Copy |
|---------|------|
| Primary CTA | View history — reuse existing `History` link on transaction change rows (no new primary CTA in Phase 105) |
| Empty state heading | No changes match these filters in the selected window. |
| Empty state body | (none — existing timeline copy is sufficient; do not add help-desk-specific empty body text in Phase 105) |
| Transaction bundle empty | No Changes Recorded |
| Coverage gap | No audited tables found for schema '{schema}'. Run mix threadline.gen.triggers to set up capture. — must include new help-desk tables once triggers are generated |
| Error state | Transaction unavailable. Confirm the audit transaction id and that capture ran for this database, then retry from the timeline. |
| Destructive confirmation | none — Phase 105 is read-only on operator surfaces |

**Multi-table transaction scan copy (implicit):** When `:ticket_replied_and_closed` links `tickets` + `ticket_replies` in one bundle, the transaction header remains `Transaction: {id}`; change rows list each table in capture order. Operators must be able to answer "what changed in one commit?" without custom Phase 105 headings.

**Brand voice:** Calm, precise, operational — per Threadline Brand Book. Avoid help-desk product marketing tone ("Supercharge your support") on audit surfaces.

---

## Visual Hierarchy

| Surface | Focal Point | Supporting Hierarchy |
|---------|-------------|----------------------|
| `/audit` timeline (help-desk filters) | Most recent matching change row (table + op + time) | Filters and table picker stay subordinate; `tickets` / `ticket_replies` rows scannable at same weight as `posts` |
| Transaction detail (multi-table) | Transaction id header, then **all** change rows in the bundle | A `:ticket_replied_and_closed` bundle must show **both** table sections with equal row treatment — do not collapse multi-table txs into a single synthetic summary |
| `ticket_replies` change row with mask | `internal_note_body` field line with redacted value | Field name visible; redacted placeholder visually distinct via existing `.field-after` / monospace — no custom "secret" iconography in Phase 105 |
| `/audit/coverage` | Audited table list including all five help-desk tables | Missing trigger for any help-desk table is a **blocking** setup failure for phase verification |
| `/audit/policy/redaction` | `ticket_replies` row in configured-vs-deployed grid | Drift on `internal_note_body` mask is a walkthrough stop-the-line item |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| none | none | not applicable — no new component registries |

---

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS

**Approval:** approved 2026-05-27
