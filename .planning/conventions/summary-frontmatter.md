# SUMMARY frontmatter convention

**SSOT for PLAN-01** — how completed plan summaries declare traceability metadata.

---

## Purpose

Threadline planning uses **three-source audit** traceability (see `prompts/threadline-elixir-oss-dna.md`):

1. **REQUIREMENTS.md** — milestone requirement checkboxes and traceability table
2. **`*-SUMMARY.md`** — `requirements-completed` in completed plan summaries
3. **`*-VERIFICATION.md`** — phase-level must-have table and automated command evidence

These three sources must agree for a requirement to be considered closed. The SUMMARY frontmatter field `requirements-completed` is the plan-level attestation; VERIFICATION is the phase-level proof; REQUIREMENTS is the milestone rollup.

---

## Field: `requirements-completed`

- **Canonical form:** hyphenated `requirements-completed` (YAML array of IDs).
- **Deprecated alias:** `requirements_completed` (underscore) — do not use in new SUMMARYs; PLAN-01 prose may note the alias for historical grep only.
- **Delivery phases:** array of milestone REQ IDs (`DIST-*`, `CFG-*`, `DOC-*`, `WALK-*`, `README-*`, `AUTH-*`, etc.).
- **Gap-closure phases:** array of **GAP IDs** (see below), never milestone REQ IDs.

Empty `requirements-completed: []` in a **delivery** feature phase may mean partial plan completion (e.g. Phase 107-style). In **gap-closure** phases, empty arrays were ambiguous before Phase 130; use `gap-closure: true` plus GAP IDs instead.

---

## Field: `gap-closure`

- **Type:** boolean
- **`gap-closure: true`** — post-shipment gap-closure work (Phases 125–127 style). Signals that empty delivery REQ IDs were intentional; closure is tracked via GAP IDs.
- **Omit or `false`** — normal delivery-phase summaries (Phases 122–124, 128–129, etc.).

---

## GAP ID namespace

Format: **`GAP-{phase}-{nn}`** (e.g. `GAP-125-01`).

| Property | Rule |
|----------|------|
| Scope | Post-shipment gap closure only |
| Not milestone REQs | GAP IDs must **not** appear in REQUIREMENTS.md v1 requirement checkboxes |
| Counting | Never increment "11/11 requirements satisfied" — GAP closure is orthogonal to adopter-facing REQ satisfaction |
| NYQ-01 | Phase **130** Nyquist finalize on 125 — **not** `GAP-126-*` |

### GAP ID map (v1.27 gap closure)

| Phase / Plan | GAP IDs | Closes |
|--------------|---------|--------|
| 125-01 | GAP-125-01, GAP-125-02, GAP-125-03 | Charter doc contract; STATE.md; MILESTONE-ARC.md |
| 125-02 | GAP-125-04 | ROADMAP closeout + green verify bundle |
| 126-01 | GAP-126-01 | 122-VALIDATION Nyquist sign-off |
| 126-02 | GAP-126-02 | 123-VALIDATION Nyquist sign-off |
| 126-03 | GAP-126-03 | 124-VALIDATION Nyquist sign-off |
| 127-01 | GAP-127-01, GAP-127-03 | Example `:schemas` mount; row-history reification proof |
| 127-02 | GAP-127-02 | getting-started §9 mount parity |

---

## Delivery vs gap-closure

| Work type | ID namespace | `gap-closure` | Example phases |
|-----------|--------------|---------------|----------------|
| Adopter-facing delivery | `DIST-*`, `CFG-*`, `DOC-*`, `WALK-*`, `README-*`, `AUTH-*` | omit / false | 122–124, 128–129 |
| Post-shipment gap closure | `GAP-{phase}-{nn}` | `true` | 125–127 |

---

## NYQ-01 (Phase 130)

**NYQ-01** is satisfied by archiving and finalizing `.planning/milestones/v1.27-phases/125-authority-surface-reconciliation/125-VALIDATION.md` with `nyquist_compliant: true` and a green Tier 1 bundle on the **current tree** (Phase 130 Plan 01). It is **not** represented by `GAP-126-*` IDs — those cover Nyquist sign-off for phases 122–124 only.

---

## Phase 127 and DOC-03

Phase 127 GAP IDs close **runnable demonstration** gaps (`:schemas` mount, row-history proof, getting-started §9 parity). They do **not** claim **DOC-03** — documentation for walkthrough/row-history was satisfied in Phase 124. Do not add `DOC-03` to any 127 `requirements-completed` list.

---

## Example frontmatter blocks

### Delivery phase (128-01 style)

```yaml
---
phase: 128-readme-phx-gen-auth-mount-parity
plan: 01
# ... subsystem, tags, requires, provides, affects, tech-stack, key-files, key-decisions ...

requirements-completed: [README-01, README-02, TRIG-01]

duration: 8min
completed: 2026-05-28
---
```

### Gap-closure phase (125-01 style)

```yaml
---
phase: 125-authority-surface-reconciliation
plan: "01"
# ... subsystem, tags, requires, provides, affects, tech-stack, key-files, key-decisions ...

gap-closure: true
requirements-completed: [GAP-125-01, GAP-125-02, GAP-125-03]

duration: 2min
completed: 2026-05-28
---
```

---

*Convention established: Phase 130 (PLAN-01). Archive: `.planning/milestones/v1.27-phases/`.*
