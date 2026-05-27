# Phase 113: Adopter Truth & Doc Sync - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 113-adopter-truth-doc-sync
**Areas discussed:** Evidence mount authorization, Evidence CLI naming, Adoption-pilot version sync, WALK-03-02 prose + contracts, Planning/archive doc scope

---

## Evidence mount authorization

| Option | Description | Selected |
|--------|-------------|----------|
| Admin-only dedicated callback | `my_evidence_authorize_fn` mirrors export gate | ✓ |
| Reuse `my_export_authorize_fn` | Zero duplication, coupled policies | |
| Grant support via `{:ok, scope}` | Misleading — no evidence query scoping | |
| Omit callback (status quo) | Fail-closed for everyone including admin | |

**User's choice:** Admin-only dedicated callback (research synthesis; user requested one-shot coherent recommendations)
**Notes:** Aligns with TRUTH-01, WALK-04, CloudTrail/GitHub tiered audit access patterns. Support uses CLI fallback per operator-surface.md.

---

## Evidence CLI naming

| Option | Description | Selected |
|--------|-------------|----------|
| Doc-footnote + archive sync + doc-contract | Canonical `threadline.evidence.show` only | ✓ |
| Root `verify.evidence` alias | Blurs CI gates vs viewers | |
| Example-only alias | Wrong layer for adopters | |
| Archives-only cleanup without tests | Drift returns | |

**User's choice:** Doc-footnote + contracts; no alias
**Notes:** Phase 108 precedent; `verify.*` reserved for CI in mix.exs. Task moduledoc: viewer not gate.

---

## Adoption-pilot version sync

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal (distribution table only) | TRUTH-02 literal only | |
| Medium (table + orientation sentence) | SSOT + upgrade-path pointer | ✓ |
| Full ExampleCloud matrix refresh | Scope creep vs Phase 112 | |

**User's choice:** Medium refresh
**Notes:** Fictional ExampleCloud job N/A row deferred. New `adoption_pilot_doc_contract_test.exs`.

---

## WALK-03-02 prose + contracts

| Option | Description | Selected |
|--------|-------------|----------|
| Operator question fix only | WR-110-001 minimum | |
| + walkthrough literals + count==12 | Fiction consistency locked | ✓ |
| Deep UI/org-scoping tests | Out of scope | |

**User's choice:** Operator question + literals + shallow+ notch demo_contract
**Notes:** Tickets-only expected outcome; no ticket_replies in seed.

---

## Planning / archive doc scope

| Option | Description | Selected |
|--------|-------------|----------|
| Active surface only | guides + example + tests | ✓ (core) |
| + PROJECT/MILESTONES living index | Canonical CLI in index | ✓ |
| Full milestones sweep | Rejected — archive integrity | |

**User's choice:** Active + living index + v1.23 errata blocks
**Notes:** v1.22-phases immutable; errata not silent checkbox rewrites.

---

## Claude's Discretion

Listed in CONTEXT.md — doc wording polish, footnote retention, Hex publish status row, optional evidence LiveView test.

## Deferred Ideas

See CONTEXT.md `<deferred>` — support-scoped evidence, verify.evidence alias, ExampleCloud matrix, archive sweep.
