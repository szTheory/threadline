# Phase 125: Authority-Surface Reconciliation — Research

**Researched:** 2026-05-28  
**Phase:** 125 — Authority-Surface Reconciliation  
**Confidence:** HIGH

## Objective

Reconcile planning authority surfaces with shipped v1.27 delivery evidence (Phases 122–124) and restore `mix verify.doc_contract` green. No adopter-facing guide or `lib/` changes.

## Root Cause (audit-confirmed)

| Surface | Drift | Evidence |
|---------|-------|----------|
| `v1_23_charter_doc_contract_test.exs` | Asserts `## Current Milestone:` | PROJECT.md uses `## Latest Milestone Shipped:` since v1.27 closeout edit |
| `.planning/STATE.md` | `status: executing`, Last shipped v1.26, Phase 124 not started | Contradicts 122–124 VERIFICATION.md `passed` |
| `.planning/MILESTONE-ARC.md` | v1.27 **active**, thesis cites Hex **0.5.0** lag | hex.pm latest **0.6.0** (Phase 122) |
| `.planning/ROADMAP.md` | Last shipped v1.26; Phase 125 unchecked | Expected until this phase executes |

Fresh run: `mix verify.doc_contract` — **97 tests, 1 failure** (`PROJECT.md locks v1.27 milestone framing`).

## Decision: Align Contract to Shipped Heading (not revert PROJECT.md)

ROADMAP success criterion #1 names the **`## Latest Milestone Shipped:`** pattern. Reverting PROJECT.md to `## Current Milestone:` would fight the v1.21+ house style used at `/gsd-complete-milestone` boundaries (see Phase 103 D-02: “Latest Milestone Shipped” owned by complete-milestone; here v1.27 delivery is already archived in PROJECT.md body).

**Action:** Update `test/threadline/v1_23_charter_doc_contract_test.exs` literals to match current PROJECT.md and post-reconciliation MILESTONE-ARC.md.

## Authority-Surface Edit Map

### D-125-01 — Charter doc contract (`test/threadline/v1_23_charter_doc_contract_test.exs`)

| Test | Current assertion | Target assertion |
|------|-------------------|------------------|
| PROJECT.md | `## Current Milestone: v1.27 Distribution & First-Hour Finish` | `## Latest Milestone Shipped: v1.27 Distribution & First-Hour Finish` |
| MILESTONE-ARC active line | `**Active milestone:** **v1.27 Distribution & First-Hour Finish**` | `**Active milestone:** **v1.28 External Pilot** (queued — signal-gated)` |
| MILESTONE-ARC arc row | `\| v1.27 \| **active** \|` | `\| v1.27 \| **shipped** \|` |
| MILESTONE-ARC thesis | `Hex.pm still lists **0.5.0**` | `Hex.pm lists **0.6.0**` (or equivalent honest 0.6.0 thesis — no 0.5.0 lag claim) |

Retain existing anchors: `Threadline.Audit.transaction`, `phx-gen-auth-reference`, `AUTH-PROOF-01`, `phx.gen.auth reach wedge`, `see PROJECT.md Key Decisions`, `first sustained external signal`.

### D-125-02 — `.planning/STATE.md`

| Field | Current | Target |
|-------|---------|--------|
| `status` | `executing` | `gap_closure` |
| `completed_phases` | 3 | 4 (includes 124; 125 in progress until plan completes) |
| `Last Milestone Shipped` | v1.26 | **v1.27 — Distribution & First-Hour Finish (2026-05-28)** |
| `Phase` / `Plan` | 124 / Not started | **125** / Ready to execute (or 126 next after 125) |
| `Session Continuity` | plan 124 | **Phase 125 planned; next `/gsd-execute-phase 125`** |
| `Hex distribution` | 0.6.0 noted | Keep; ensure consistent with arc |

Footnote: Full milestone archive (`/gsd-complete-milestone v1.27`) waits until Phases 126–127; STATE “shipped posture” means **delivery requirements satisfied**, gap phases labeled explicitly.

### D-125-03 — `.planning/MILESTONE-ARC.md`

Mirror D-125-01 MILESTONE-ARC targets:

- **Active milestone:** v1.28 queued (signal-gated) — not v1.27 in progress
- **Strategic thesis:** v1.27 distribution + first-hour gaps **closed**; Hex **0.6.0** on registry
- **Arc order:** v1.27 → **shipped**; v1.28 → **queued** (unchanged semantics)
- **Option record row 11:** v1.27 → **Shipped** (not Active)

### D-125-04 — `.planning/ROADMAP.md` (Current Planning State + Progress)

- `**Last shipped:**` → **v1.27 — Distribution & First-Hour Finish (2026-05-28)**
- `**Status:**` → Phases 122–124 shipped; gap closure 125–127 (125 planned)
- `**Next step:**` → `/gsd-execute-phase 125` (until execution), then 126
- Progress table Phase 125: update at execution time (planning only flips checkbox in execute)

**Out of scope (Phase 126/127):** Nyquist VALIDATION sign-off; example `:schemas` wiring.

## Precedent: Phase 103 (v1.22)

Phase 103 **deferred** MILESTONE-ARC + “Latest Milestone Shipped” to `/gsd-complete-milestone v1.22`. Phase 125 is the **inverse**: v1.27 delivery content already in PROJECT.md; this phase **does** update MILESTONE-ARC and charter contract because the audit found post-ship drift, not pre-ship deferral.

## Validation Architecture

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Quick run** | `mix verify.doc_contract` |
| **Full suite** | `mix ci.all` |
| **Phase-specific** | `mix test test/threadline/v1_23_charter_doc_contract_test.exs` |

**Per-plan verification:**

| Plan | Automated gate |
|------|----------------|
| 125-01 | `mix test test/threadline/v1_23_charter_doc_contract_test.exs` → 2 tests, 0 failures; `mix verify.doc_contract` → 97 tests, 0 failures |
| 125-02 | `rg` invariants on STATE/MILESTONE-ARC/ROADMAP; `mix ci.all` green |

**Manual:** None — charter proxies replace human UAT on planning-doc readability.

## Risks

| Risk | Mitigation |
|------|------------|
| Over-claiming v1.28 active | Use “queued (signal-gated)” wording; ROADMAP non-goals unchanged |
| Premature `/gsd-complete-milestone` | ROADMAP + STATE explicitly note 126–127 before archive |
| Scope creep into 127 `:schemas` | `files_modified` limited to `.planning/` + charter test |

## Files Touched (expected)

- `test/threadline/v1_23_charter_doc_contract_test.exs`
- `.planning/STATE.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/ROADMAP.md` (Current Planning State band only — not Phase Details bodies)

## RESEARCH COMPLETE
