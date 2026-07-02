# Phase 193: Quality Closeout and Next-Step Decision - Context

**Gathered:** 2026-07-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 193 closes milestone **v1.39** (Quality Baseline, Schema Confidence, and CI Efficiency)
with **evidence and a decision** — it does not ship, archive, or write product code.

It delivers the four CLOSE-01 clauses:
1. Requirements traceability + verification evidence, current.
2. Before/after CI data where possible; explicit no-measure rationale where not.
3. Ranked remaining software-quality risks, each with owner + follow-up (no vague "polish later" bucket).
4. A clear v1.40 next-milestone recommendation (CI/CD depth · external adopter proof · observability · hold).

**Anchor:** this is a *closeout-evidence-and-decision* phase. Milestone archive/tag and any
public ship action are explicitly OUT of this phase (see D-01).
</domain>

<decisions>
## Implementation Decisions

### Closeout scope & ship/archive boundary (high-impact — user-confirmed)
- **D-01:** Phase 193 produces **evidence/decision artifacts ONLY.** It writes: a requirements
  traceability rollup, a verification + CI evidence index, a ranked residual-risk register, and a
  v1.40 next-step recommendation. Exact filenames are a planning detail (e.g. `193-TRACEABILITY.md`,
  `193-EVIDENCE-INDEX.md`, `193-RISK-REGISTER.md`, `193-NEXT-STEP.md`, plus the standard
  `193-VERIFICATION.md` / `193-SUMMARY.md`).
- **D-02:** Phase 193 does **NOT**: archive the milestone, collapse `ROADMAP.md`, delete
  `REQUIREMENTS.md`, evolve `PROJECT.md`, cut/push any git tag, bump version, or publish to Hex.
  Those belong to a separate local `/gsd-complete-milestone` run. No fix demands a version bump, so
  publish stays out of scope per REQUIREMENTS.md.
- **D-03:** Phase 193 does **NOT** produce `v1.39-MILESTONE-AUDIT.md` itself — that is
  `/gsd-audit-milestone`'s artifact. Recommended post-193 sequence: **193 (evidence/decision) →
  `/gsd-audit-milestone` → `/gsd-complete-milestone`** (local archive + local tag; tags stay local
  per the milestone-tags-stay-local convention — origin is public `szTheory/threadline` and local
  `main` is ~395 commits ahead, all `.planning/`).
- **D-04:** The **192 ship-gated checklist** (Task 192-04-03: D-17 throwaway min-lane resolution
  run + D-19 branch-protection reconfig) is **tracked as an open residual, NOT executed.** It is
  inherently external — it requires the `ci.yml` verify-test matrix to reach public `origin/main`,
  a push the local-only convention forbids and that has not happened. 193 restates and tracks it;
  it cannot close it.

### v1.40 next-step recommendation (high-impact — user-confirmed)
- **D-05:** Phase 193 recommends **HOLD / thin-polish** as the v1.40 direction — the project's own
  `default_no_signal_path`. Three independent gates converge: done-band (~92–95% vs
  `done_band_threshold: 90`), no sustained real external-adopter signal, and Phase 189's quality
  audit already adjudicated the candidates (every must-fix closed inside v1.39; everything left is
  score-2–4 "good enough / future seed"). `no_auto_new_milestone` holds — 193 recommends, it does
  not open v1.40.
- **D-06:** Thin-polish content (if pursued) = close the ship-gated 192-04-03 when it can legitimately
  go public, plus Nyquist/charter/frontmatter backlog cleanup. Nothing here needs a version bump.
- **D-07:** The recommendation ships with **armed flip-triggers**, each mapped to a Future
  Requirement: **named external host/integrator** → external-pilot (EXT-PILOT-01, highest-leverage,
  simultaneously arms observability); **measured sustained CI bottleneck the Phase-192 changes did
  not resolve** → CI/CD depth; **real operator production-debugging gap / audit re-scores
  debuggability score-1** → observability (OBS-01 — note: Phase 189 did NOT flag debuggability, so
  do not auto-promote without fresh evidence); visual regression escaping a release → UI-REG-01;
  socket-drop spec failure / field report → RECONNECT-01.

### CI before/after data method (safe-to-default)
- **D-08:** Before/after CI evidence is an **in-repo static `ci.yml` diff** against `192-BASELINE.md`
  — cache jobs (0→N), `mix deps.get` invocations (8→fewer), `concurrency` (0→1), pinned images
  (`pgbouncer:latest`→pinned), single-lane→`verify-test` min/current matrix.
- **D-09:** Runtime timing (wall-clock), billed minutes, and cache-hit rate are recorded as
  **explicit no-measure** rows with rationale: the new matrix/cache config has never run on public
  GitHub because it is ship-gated (D-04). This IS the honest "no-measure reason" CLOSE-01 anticipates —
  reuse the DNA Nyquist-debt row style (owner / date / superseding-evidence pointer / reopen trigger)
  already used in `192-BASELINE.md`.

### Risk-register sourcing & ranking (safe-to-default)
- **D-10:** Method = **hybrid, manual-synthesis-dominant.** Run `/gsd-audit-milestone` ONCE (it
  supplies the cross-phase integration check, E2E re-verification, and traceability refresh CLOSE-01
  needs regardless, in the proven `v1.38-MILESTONE-AUDIT.md` format), then **hand-rank** the register
  on top of it. **Skip `/gsd-audit-uat`** — v1.39 introduced no `*-UAT.md` files; it would only
  re-surface the already-deferred v1.36 rows.
- **D-11:** Register seed = Phase 189's `189-QUALITY-AUDIT.md` ranked ledger (which already names 193
  as its consumer and already carries **Owner + Trigger-to-reopen** per row), refreshed by verifying
  rows 1–3 as CLOSED (by phases 190/191/192) and folding in new post-189 items.
- **D-12:** Ranking dimension = the project-native **adoption / operations / maintainer-risk** lens
  (matches REQUIREMENTS.md Future-Requirements framing and QUAL-02's must-fix-vs-good-enough split),
  NOT generic severity×likelihood. A one-line severity note per row is allowed as secondary color.
  Every row keeps **Owner + concrete follow-up/reopen-trigger** — this structurally forbids a "polish
  later" bucket.

### Claude's Discretion
- Exact `193-*` artifact filenames and whether some are merged into one CLOSE-01 doc vs. split.
- Whether to run `/gsd-audit-uat` once as a cheap confirmation (near-zero expected value) or skip entirely.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` §"Phase 193" (~L138–149) — goal + four success criteria.
- `.planning/REQUIREMENTS.md` — CLOSE-01 (L41), Future Requirements (EXT-PILOT-01, OBS-01, UI-REG-01,
  RECONNECT-01, L45–61), Out of Scope table (version bump / Hex publish deferred), adoption/ops/
  maintainer-risk framing (L45).

### Risk-register seed & evidence (the register is ~80% pre-built)
- `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md` — **primary
  register seed**: the ranked ledger (rows ~98–148) + QUAL-03 residual table; explicitly names Phase
  193 as consumer.
- `.planning/phases/190-storage-schema-confidence-and-host-schema-truth/190-VERIFICATION.md` — residual
  **WR-01** (alt-schema fixture uses `CREATE TABLE … LIKE INCLUDING ALL`, FK constraints unproven).
- `.planning/phases/191-release-version-and-docs-trust-repair/deferred-items.md` +
  `191-VERIFICATION.md` — `v1_23_charter_doc_contract_test.exs` residual (PROJECT.md milestone literal drift).
- `.planning/phases/192-ci-cd-measurement-and-efficiency-hardening/192-BASELINE.md` — the **before**
  CI baseline for the D-08 static diff.
- `.planning/phases/192-.../192-SHIP-CHECKLIST.md` — the ship-gated D-17/D-19 residual (D-04).
- `.planning/phases/192-.../192-VERIFICATION.md` — ship-gated + ~81 local-env test-failure items.

### Closeout format & decision policy
- `.planning/milestones/v1.38-MILESTONE-AUDIT.md` — the residual-classification + audit format
  (`Verdict / Closeout Evidence / Requirements Cross-Reference / Integration / E2E / Residual Tech
  Debt / Boundary Check`) to mirror; product of `/gsd-audit-milestone`.
- `.planning/config.json` §`workflow.milestone_next_step` + `workflow.milestone_assessment` — encodes
  `default_no_signal_path: hold_or_thin_polish`, `done_band_threshold: 90`, `no_auto_new_milestone`.
- `.planning/STATE.md` — done-band scope (~92–95%), Deferred Items table, decision log
  ([v1.39-01/02/03], [192-*]).
- `.planning/threads/2026-05-28-milestone-next-step-post-v1.27.md` +
  `.planning/threads/2026-05-29-post-v1.29-posture.md` — the recurring signal-gated "no synthetic
  pilot" posture behind D-05.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Phase 189 ranked ledger** — already a ranked, owner-tagged, reopen-triggered risk table; 193's
  register is a verify-and-refresh of it, not a fresh discovery pass.
- **`192-BASELINE.md`** — self-described as the "before" half of 193's in-repo before/after CI diff;
  already records which metrics are honestly unavailable and why.
- **`v1.38-MILESTONE-AUDIT.md`** — reusable structure/format for the evidence + residual sections.

### Established Patterns
- Two-step milestone close: `/gsd-audit-milestone` (audit snapshot) → `/gsd-complete-milestone`
  (archive + local tag). 193 slots in *before* both and must not duplicate them.
- Honest-unavailable metric rows carry DNA Nyquist-debt metadata (owner / date / superseding-evidence
  pointer / reopen trigger) rather than fabricated numbers — reuse for D-09.
- Milestone tags stay local; never push `main` to public origin.

### Integration Points
- 193 consumes phase 189–192 artifacts (VERIFICATION / VALIDATION / BASELINE / SHIP-CHECKLIST /
  deferred-items) and the REQUIREMENTS.md traceability table; it emits standalone `193-*` docs and
  does not mutate milestone-level files.
</code_context>

<specifics>
## Specific Ideas

- The ~81 local `mix test` failures (undefined audit tables) are a **pre-existing env
  storage_schema/search_path issue, not a regression** — record as a maintainer-friction risk row,
  do NOT treat as a v1.39 quality regression (CI provisions the DB correctly).
- The `v1_23_charter_doc_contract_test.exs` failure is a PROJECT.md milestone-literal drift
  (v1.38→v1.39), owner = charter/SSOT truth owner.
</specifics>

<deferred>
## Deferred Ideas

- **Milestone archive + local tag** → separate `/gsd-complete-milestone` run after 193.
- **`v1.39-MILESTONE-AUDIT.md`** → `/gsd-audit-milestone` run after 193.
- **192 ship-gated D-17/D-19** → fires only when CI matrix reaches public `origin/main`; tracked, not executed.
- **v1.40 candidate directions** (external-pilot, CI depth, observability, UI-REG, reconnect) →
  parked behind the D-07 flip-triggers; not opened by 193.
- **Version bump / Hex publish** → out of scope; no fix demands it.

None of the above is lost — each is a tracked residual with an owner and a reopen trigger.
</deferred>

---

*Phase: 193-Quality Closeout and Next-Step Decision*
*Context gathered: 2026-07-02*
