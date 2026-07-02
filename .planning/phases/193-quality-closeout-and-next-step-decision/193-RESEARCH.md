# Phase 193: Quality Closeout and Next-Step Decision - Research

**Researched:** 2026-07-02
**Domain:** Milestone closeout — evidence assembly, requirements traceability, ranked residual-risk synthesis, next-milestone decision (planning/docs artifacts only, no product code)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Closeout scope & ship/archive boundary**
- **D-01:** Phase 193 produces **evidence/decision artifacts ONLY** — a requirements traceability rollup, a verification + CI evidence index, a ranked residual-risk register, and a v1.40 next-step recommendation. Exact filenames are a planning detail (e.g. `193-TRACEABILITY.md`, `193-EVIDENCE-INDEX.md`, `193-RISK-REGISTER.md`, `193-NEXT-STEP.md`, plus standard `193-VERIFICATION.md` / `193-SUMMARY.md`).
- **D-02:** Phase 193 does **NOT**: archive the milestone, collapse `ROADMAP.md`, delete `REQUIREMENTS.md`, evolve `PROJECT.md`, cut/push any git tag, bump version, or publish to Hex. Those belong to a separate local `/gsd-complete-milestone` run. No fix demands a version bump, so publish stays out of scope.
- **D-03:** Phase 193 does **NOT** produce `v1.39-MILESTONE-AUDIT.md` itself — that is `/gsd-audit-milestone`'s artifact. Recommended post-193 sequence: **193 (evidence/decision) → `/gsd-audit-milestone` → `/gsd-complete-milestone`** (local archive + local tag; tags stay local — origin is public `szTheory/threadline`, local `main` is ~395 commits ahead, all `.planning/`).
- **D-04:** The **192 ship-gated checklist** (Task 192-04-03: D-17 throwaway min-lane resolution run + D-19 branch-protection reconfig) is **tracked as an open residual, NOT executed.** It is inherently external — it requires the `ci.yml` verify-test matrix to reach public `origin/main`, a push the local-only convention forbids and that has not happened. 193 restates and tracks it; it cannot close it.

**v1.40 next-step recommendation**
- **D-05:** Phase 193 recommends **HOLD / thin-polish** as the v1.40 direction — the project's own `default_no_signal_path`. Three independent gates converge: done-band (~92–95% vs `done_band_threshold: 90`), no sustained real external-adopter signal, and Phase 189's quality audit already adjudicated the candidates (every must-fix closed inside v1.39; everything left is score-2–4 "good enough / future seed"). `no_auto_new_milestone` holds — 193 recommends, it does not open v1.40.
- **D-06:** Thin-polish content (if pursued) = close the ship-gated 192-04-03 when it can legitimately go public, plus Nyquist/charter/frontmatter backlog cleanup. Nothing here needs a version bump.
- **D-07:** The recommendation ships with **armed flip-triggers**, each mapped to a Future Requirement: **named external host/integrator** → external-pilot (EXT-PILOT-01, highest-leverage, simultaneously arms observability); **measured sustained CI bottleneck the Phase-192 changes did not resolve** → CI/CD depth; **real operator production-debugging gap / audit re-scores debuggability score-1** → observability (OBS-01 — note: Phase 189 did NOT flag debuggability, so do not auto-promote without fresh evidence); visual regression escaping a release → UI-REG-01; socket-drop spec failure / field report → RECONNECT-01.

**CI before/after data method**
- **D-08:** Before/after CI evidence is an **in-repo static `ci.yml` diff** against `192-BASELINE.md` — cache jobs (0→N), `mix deps.get` invocations (8→fewer effective cost), `concurrency` (0→1), pinned images (`pgbouncer:latest`→pinned), single-lane→`verify-test` min/current matrix.
- **D-09:** Runtime timing (wall-clock), billed minutes, and cache-hit rate are recorded as **explicit no-measure** rows with rationale: the new matrix/cache config has never run on public GitHub because it is ship-gated (D-04). This IS the honest "no-measure reason" CLOSE-01 anticipates — reuse the DNA Nyquist-debt row style (owner / date / superseding-evidence pointer / reopen trigger) already used in `192-BASELINE.md`.

**Risk-register sourcing & ranking**
- **D-10:** Method = **hybrid, manual-synthesis-dominant.** Run `/gsd-audit-milestone` ONCE (it supplies the cross-phase integration check, E2E re-verification, and traceability refresh CLOSE-01 needs regardless, in the proven `v1.38-MILESTONE-AUDIT.md` format), then **hand-rank** the register on top of it. **Skip `/gsd-audit-uat`** — v1.39 introduced no `*-UAT.md` files; it would only re-surface the already-deferred v1.36 rows.
- **D-11:** Register seed = Phase 189's `189-QUALITY-AUDIT.md` ranked ledger (which already names 193 as its consumer and already carries **Owner + Trigger-to-reopen** per row), refreshed by verifying rows 1–3 as CLOSED (by phases 190/191/192) and folding in new post-189 items.
- **D-12:** Ranking dimension = the project-native **adoption / operations / maintainer-risk** lens (matches REQUIREMENTS.md Future-Requirements framing and QUAL-02's must-fix-vs-good-enough split), NOT generic severity×likelihood. A one-line severity note per row is allowed as secondary color. Every row keeps **Owner + concrete follow-up/reopen-trigger** — this structurally forbids a "polish later" bucket.

### Claude's Discretion
- Exact `193-*` artifact filenames and whether some are merged into one CLOSE-01 doc vs. split.
- Whether to run `/gsd-audit-uat` once as a cheap confirmation (near-zero expected value) or skip entirely.

### Deferred Ideas (OUT OF SCOPE)
- **Milestone archive + local tag** → separate `/gsd-complete-milestone` run after 193.
- **`v1.39-MILESTONE-AUDIT.md`** → `/gsd-audit-milestone` run after 193.
- **192 ship-gated D-17/D-19** → fires only when CI matrix reaches public `origin/main`; tracked, not executed.
- **v1.40 candidate directions** (external-pilot, CI depth, observability, UI-REG, reconnect) → parked behind the D-07 flip-triggers; not opened by 193.
- **Version bump / Hex publish** → out of scope; no fix demands it.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CLOSE-01 | v1.39 closes with requirements traceability, verification evidence, before/after CI data or explicit no-measure rationale, ranked remaining risks, and a clear recommendation for v1.40 or hold. | All four clauses are pre-sourced: (1) traceability skeleton below maps 15/15 requirements to phase + proof artifact; (2) evidence index draws from five phase VERIFICATION artifacts already on disk; (3) before/after CI is a static `ci.yml`-vs-`192-BASELINE.md` diff with honest no-measure rows for runtime metrics; (4) risk register is a verify-and-refresh of the pre-ranked 189 ledger; (5) next-step is HOLD + armed flip-triggers backed by config policy. This phase writes NO product code — verification is presence/consistency/traceability assertion, not a test suite. |
</phase_requirements>

## Summary

Phase 193 is the closeout evidence-and-decision phase for milestone v1.39. It is **not** a
discovery phase and **not** an implementation phase: nearly every input already exists on disk.
The four CLOSE-01 clauses map to four (optionally merged) markdown artifacts, each of which is a
**synthesis of existing verified evidence** rather than new analysis. The single largest reusable
asset is `189-QUALITY-AUDIT.md`, a 12-row ranked ledger that already carries per-row Owner +
reopen-trigger and explicitly names Phase 193 as its consumer — so the risk register is ~80%
pre-built and the register task is a **verify-and-refresh**, not a fresh ranking.

The CI before/after evidence (D-08/D-09) is fully bounded by two facts already recorded in
`192-BASELINE.md` and `192-VERIFICATION.md`: the static structural deltas (cache blocks 0→9,
`concurrency` 0→1, `pgbouncer:latest`→`v1.25.2-p0`, single lane→min/current matrix) are all
in-repo diffable, while wall-clock / billed-minutes / cache-hit-rate are **honestly unavailable**
because the new config is ship-gated and has never run on public `origin/main`. That "never ran
publicly" fact is not a gap to hide — it is exactly the no-measure rationale CLOSE-01 anticipates,
and `192-BASELINE.md` already supplies the four-field Nyquist-debt row format to record it.

The next-step recommendation is HOLD / thin-polish, and three independent project gates converge on
it (done-band ~92–95% ≥ 90 threshold, no sustained external-adopter signal, and the 189 audit having
already adjudicated every remaining candidate as score-2–4). The config's `milestone_next_step` and
`milestone_assessment` policy (`default_no_signal_path: hold_or_thin_polish`, `done_band_threshold: 90`,
`no_auto_new_milestone: true`) structurally supports HOLD; the four candidate directions map cleanly
to the four Future Requirements as armed flip-triggers.

**Primary recommendation:** Plan 193 as a small set of synthesis tasks over existing artifacts —
(1) traceability rollup, (2) evidence index, (3) verify-and-refresh risk register, (4) HOLD
recommendation with armed triggers — plus a docs-appropriate `193-VERIFICATION.md` that asserts
presence + internal consistency + traceability completeness (no runnable feature to test). Do **not**
run `/gsd-audit-milestone` inline; leave it (and its `v1.39-MILESTONE-AUDIT.md` artifact) to the
post-193 skill sequence per D-03. See Open Question OQ-1 for the D-10↔D-03 wording tension and its
recommended resolution.

## Architectural Responsibility Map

For a closeout phase, "tier" = which artifact/actor OWNS each deliverable and boundary. This map
lets the planner sanity-check that 193 does not stray into ship/archive territory owned downstream.

| Capability | Primary Owner | Secondary / Downstream | Rationale |
|------------|---------------|------------------------|-----------|
| Requirements traceability rollup (CLOSE-01 clause 1) | Phase 193 artifact (`193-TRACEABILITY.md`) | `REQUIREMENTS.md` traceability table (source of truth, read-only) | 193 synthesizes; it must NOT edit/delete REQUIREMENTS.md (D-02). |
| Verification + CI evidence index (clause 2) | Phase 193 artifact (`193-EVIDENCE-INDEX.md`) | Phase 189–192 VERIFICATION/BASELINE artifacts (read-only inputs) | 193 indexes/points to existing evidence; it does not re-run phase verifications. |
| CI before/after diff (clause 2) | Phase 193 (static in-repo diff) | `192-BASELINE.md` (the "before"); `.github/workflows/ci.yml` (the "after") | Pure in-repo diff (D-08); runtime "after" is honest-unavailable (D-09). |
| Ranked residual-risk register (clause 3) | Phase 193 artifact (`193-RISK-REGISTER.md`) | `189-QUALITY-AUDIT.md` ledger (seed); phase 190/191/192 residuals (fold-ins) | Verify-and-refresh of a pre-ranked ledger; adoption/ops/maintainer lens (D-12). |
| v1.40 next-step recommendation (clause 4) | Phase 193 artifact (`193-NEXT-STEP.md`) | `config.json` policy + Future Requirements (constraints, read-only) | 193 recommends only; `no_auto_new_milestone` forbids opening v1.40 (D-05). |
| Milestone audit snapshot (`v1.39-MILESTONE-AUDIT.md`) | **`/gsd-audit-milestone` (post-193)** | — | Explicitly NOT 193's artifact (D-03). |
| Milestone archive + local tag + PROJECT.md evolution | **`/gsd-complete-milestone` (post-193)** | — | Explicitly out of 193 scope (D-02). |
| Ship-gated D-17/D-19 execution | **maintainer, when CI reaches public `origin/main`** | `192-SHIP-CHECKLIST.md` (durable instructions) | Inherently external; 193 tracks, cannot execute (D-04). |

## Standard Stack

**N/A — no libraries, packages, or runtime dependencies.** Phase 193 writes markdown planning
artifacts synthesized from existing repo files. There is nothing to `mix deps.get` / `npm install`.
The only tooling touched is the GSD skill layer (`/gsd-audit-milestone`, `/gsd-complete-milestone`)
which is invoked AFTER 193, not by it. Consequently the following template sections are intentionally
omitted as not-applicable: **Standard Stack tables, Package Legitimacy Audit, Installation, Version
verification.** [VERIFIED: repo inspection — CONTEXT D-01/D-02 scope this phase to docs artifacts]

## Evidence Source Inventory

The planner needs exact paths, structure, and current status of each input so tasks are
"verify/refresh/point-to," not "discover." All entries below were read this session.

### Primary risk-register seed — `189-QUALITY-AUDIT.md` [VERIFIED: repo file]

`.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md`. Structure:

- **Frontmatter:** `phase / artifact / audited / scope / requirements / status / source_precedence`.
- **Score Rubric** (0=unknown/broken … 4=strong/proven) + **Priority Taxonomy** (Blocker, Must fix before publish, Prove before claim, External-owned, Maintenance note, Backlog cleanup, Future seed, Good enough, N/A).
- **Ranked Evidence Ledger** — a **12-row** table with columns: `Rank | Quality dimension | Score | Confidence | Evidence refs | Practical consequence | Highest-leverage fix | Priority | Route bucket | Owner phase`. This already carries the Owner and (via the QUAL-03 table) reopen-trigger data D-11/D-12 need.
- **QUAL-03 Residuals** — a 7-row table with columns `Residual | Current evidence | Classification | Owner | Why it matters | Trigger to reopen` (the explicit Owner + reopen-trigger source).
- **Good Enough / N/A Appendix** and **v1.39 Narrowing** (route-by-route map).

**Rows 1–3 are the v1.39 must-fix rows and should verify as CLOSED by phases 190/191/192**
(one residual each remains — see Risk Register Synthesis). **Row 4 ("Closeout traceability and
residual ownership") IS this phase (193).** **Row 5 (known CI/example-app residuals) is 192-owned**
and already separated in `192-VERIFICATION.md`. **Rows 6–12** (screenshot-regression, host staging,
external pilot, Hex/dep notes, SEED-005, optional-Phoenix boundary, compliance/API/WAL/redaction
N/A) are future/external/good-enough/N-A and are **preserved as-is** — do not re-litigate.

### CI "before" baseline — `192-BASELINE.md` [VERIFIED: repo file]

`.planning/phases/192-.../192-BASELINE.md`. Self-describes as "the before half of 193's in-repo
before/after CI diff." Contains: a ranked per-job timing table (10 jobs, p50/p95, critical path =
`verify-test` at median / `verify-example-browser` at tail), a **Static-Analysis Findings** table
(the exact structural metrics for the D-08 diff), and a **Honest-Unavailable Metrics** ledger already
in the DNA Nyquist-debt four-field shape (owner / date / superseding-evidence pointer / reopen
trigger) covering billed-minutes and cache-hit-rate. It ends with a "Baseline → Phase 193 Diff
Anchor" section that literally pre-lists the deltas 193 should assert. **This is the reuse jackpot for
clauses 2 (CI half); mirror its Nyquist-debt row format verbatim for D-09.**

### Closeout FORMAT to mirror — `v1.38-MILESTONE-AUDIT.md` [VERIFIED: repo file]

`.planning/milestones/v1.38-MILESTONE-AUDIT.md`. Section skeleton to reuse for the evidence/residual
artifacts: **Verdict → Closeout Evidence (table) → Requirements Cross-Reference (table) → Integration
Check (table) → E2E Flow Results (table) → Residual Tech Debt (table with Area/Residual/Owner-Scope/
Impact/Next Action) → Boundary Check (bullets).** Frontmatter carries `scores:` and
`closed_findings:`/`residuals:` arrays. **Note:** this is the *product of* `/gsd-audit-milestone` —
193 mirrors its FORMAT for the hand-synthesized evidence sections but does NOT emit the
`v1.39-MILESTONE-AUDIT.md` file itself (D-03).

### Phase verification artifacts (read-only evidence inputs) [VERIFIED: repo files]

| Artifact | What it proves | Residual it introduces for the register |
|----------|----------------|------------------------------------------|
| `189-VERIFICATION.md` + `189-QUALITY-AUDIT.md` | QUAL-01/02/03 complete | (seed itself) |
| `190-VERIFICATION.md` | SCHEMA-01..04 complete; real dual-schema `audit` proof matrix (`storage_schema_integration_test.exs`) | **WR-01** (see below) |
| `191-VERIFICATION.md` + `deferred-items.md` | ADOPT-01..03 complete; single `0.9.0` truth + drift guards | **charter-test drift** (see below) |
| `192-VERIFICATION.md` + `192-BASELINE.md` + `192-SHIP-CHECKLIST.md` | CI-01..04 complete (16/16 must-haves) | **ship-gated D-17/D-19**; **~81 local env test failures** (out-of-scope observation) |

## Traceability Skeleton (CLOSE-01 clause 1)

Drop-in table for `193-TRACEABILITY.md`. All statuses from `REQUIREMENTS.md` traceability table
(15 total, 14 Complete, CLOSE-01 Pending) cross-checked against phase VERIFICATION artifacts.
[VERIFIED: REQUIREMENTS.md L78-99 + phase VERIFICATION files]

| Req | Phase | Status | Primary proof artifact | Verification evidence |
|-----|-------|--------|------------------------|-----------------------|
| QUAL-01 | 189 | Complete | `189-QUALITY-AUDIT.md` (ranked ledger) | `189-VERIFICATION.md` |
| QUAL-02 | 189 | Complete | `189-QUALITY-AUDIT.md` (must-fix vs good-enough split + Good Enough/N/A appendix) | `189-VERIFICATION.md` |
| QUAL-03 | 189 | Complete | `189-QUALITY-AUDIT.md` QUAL-03 Residuals table | `189-VERIFICATION.md` |
| SCHEMA-01 | 190 | Complete | `storage_schema_integration_test.exs` (custom `audit` matrix) | `190-VERIFICATION.md` |
| SCHEMA-02 | 190 | Complete | prefix-removal wiring + would-fail-if-`threadline` tests | `190-VERIFICATION.md` |
| SCHEMA-03 | 190 | Complete | generated-migration quoting contracts | `190-VERIFICATION.md` |
| SCHEMA-04 | 190 | Complete | host-schema redaction/coverage support + docs | `190-VERIFICATION.md` |
| ADOPT-01 | 191 | Complete | `version_truth_doc_contract_test.exs` (single `0.9.0` truth) | `191-VERIFICATION.md` |
| ADOPT-02 | 191 | Complete | `upgrade_path_doc_contract_test.exs` (0.6.x→0.9.x era) | `191-VERIFICATION.md` |
| ADOPT-03 | 191 | Complete | `persona_routing_doc_contract_test.exs` (four verb lanes) | `191-VERIFICATION.md` |
| CI-01 | 192 | Complete | `192-BASELINE.md` (read-only baseline) | `192-VERIFICATION.md` |
| CI-02 | 192 | Complete | ci.yml deps/Playwright/npm caches; `phase06_nyquist_ci_contract_test.exs` | `192-VERIFICATION.md` |
| CI-03 | 192 | Complete | pin + concurrency + CONTRIBUTING reconciliation | `192-VERIFICATION.md` |
| CI-04 | 192 | Complete | min/current matrix + `dep_floor_guard_test.exs` | `192-VERIFICATION.md` |
| CLOSE-01 | 193 | **Pending → closed by this phase** | `193-*` evidence/decision artifacts | `193-VERIFICATION.md` (this phase) |

**Coverage line for the artifact:** 15/15 requirements mapped; 14/15 Complete with proof; CLOSE-01
closed by 193 itself. Zero unmapped, zero orphaned.

## CI Before/After Diff (CLOSE-01 clause 2)

### Static structural deltas (in-repo diffable — D-08) [VERIFIED: 192-BASELINE.md + 192-VERIFICATION.md]

| Metric | Before (`192-BASELINE.md`) | After (current `ci.yml` / workflows) | Evidence for "after" |
|--------|----------------------------|--------------------------------------|----------------------|
| `actions/cache` blocks in `ci.yml` | 0 | 9 (8 `path: deps` + 1 Playwright) | `192-VERIFICATION.md` truth 3–4 |
| flake-detection.yml deps cache | 0 | 1 (before its `mix deps.get`) | truth 3 |
| `_build` cache (must stay 0) | 0 | 0 (contract-test refuted) | truth 5, prohibition |
| `mix deps.get` invocations | 8 cold | 8 (retained; now cache-warmed — speed only, D-12) | truth 6 |
| `concurrency:` blocks in `ci.yml` | 0 | 1 (PR-scoped, cancel only superseded PRs) | truth 8 |
| release.yml publish concurrency | 0 | 1 (`release-publish-${{ github.ref }}`, no `run_id`) | truth 9 |
| PgBouncer image tag | `edoburu/pgbouncer:latest` | `edoburu/pgbouncer:v1.25.2-p0` (0 `:latest` across all 4 workflows) | truth 7 |
| `verify-test` version lanes | single pinned `elixir 1.17.3 / OTP 27` | min/current matrix → `Run test suite (min)` + `(current)` | truth 11–12 |
| min-lane axis | — | `1.15 / otp26 / pg14 / ubuntu-22.04` (compile-strict + `mix test` only) | truth 12 |
| Elixir floor (`~> 1.15`, must be unchanged) | `~> 1.15` | `~> 1.15` (comment-only addition; floor honored by CI, not by raising req) | truth 13 |

### Honest-unavailable runtime rows (D-09 — reuse 192-BASELINE Nyquist-debt format)

These CANNOT be measured because the after-config has never run on public `origin/main` (ship-gated,
D-04). Record each with the four-field DNA shape, never a fabricated number. [VERIFIED: 192-BASELINE.md Honest-Unavailable ledger]

| Metric | Status | Owner | Superseding-evidence pointer | Reopen trigger |
|--------|--------|-------|------------------------------|----------------|
| Wall-clock critical path (after) | Unavailable — never ran publicly | maintainer (szTheory) | GH Actions run telemetry once ci.yml matrix lands on `origin/main` | The ship-gated push (D-04 / `192-SHIP-CHECKLIST.md`) executes |
| Cache-hit rate | N/A (no telemetry yet) | maintainer (szTheory) | `actions/cache` restore/save logs after Wave-2 caches run on GitHub | Same ship-gated push |
| Billed minutes | Unavailable (public repo returns empty `{"billable":{}}`) | maintainer (szTheory) | org-level Actions billing export | Repo becomes private, or org billing export available |

**Framing for the artifact:** the before/after is *structurally* complete and *runtime* honestly
deferred — this is the intended CLOSE-01 "before/after where possible; explicit no-measure reason
where not," not a shortfall.

## Risk Register Synthesis (CLOSE-01 clause 3)

### Method (D-10/D-11): verify-and-refresh, adoption/ops/maintainer lens (D-12)

1. Start from the 189 ledger (already ranked, owner-tagged, reopen-triggered).
2. **Verify rows 1–3 as CLOSED** by the phase VERIFICATION artifacts; each closed row leaves exactly
   one residual to carry forward (below).
3. **Preserve rows 6–12** (future/external/good-enough/N/A) unchanged.
4. **Fold in the four new post-189 residuals** (below).
5. Rank by adoption/ops/maintainer-risk (NOT severity×likelihood); one-line severity note allowed as
   secondary color; every row keeps Owner + concrete reopen-trigger — this structurally forbids a
   "polish later" bucket.

### Rows 1–3 close-out status [VERIFIED: phase VERIFICATION files]

| 189 row | v1.39 owner phase | Closed? | Carried residual |
|---------|-------------------|---------|------------------|
| 1 — configurable `storage_schema` confidence | 190 | CLOSED (10/10 plans; real dual-schema proof) | **WR-01** |
| 2 — release/version/docs authority surface | 191 | CLOSED (single `0.9.0` truth + drift guards) | **charter-test drift** |
| 3 — CI/CD measurement & gate-trust baseline | 192 | CLOSED in-repo (16/16 must-haves) | **ship-gated D-17/D-19** + **~81 local env failures** |

### New post-189 residuals to fold in [VERIFIED: repo files]

| # | Residual | Source | Owner | Adoption/Ops/Maintainer classification | Reopen trigger |
|---|----------|--------|-------|----------------------------------------|----------------|
| R-A | **Ship-gated D-17/D-19** — throwaway min-lane resolution run (elixir 1.15/otp26 on ubuntu-22.04) + branch-protection reconfig to `Run test suite (min)`/`(current)` | `192-SHIP-CHECKLIST.md`, `192-VERIFICATION.md` override | maintainer (szTheory) | Ops (release-gate correctness); inherently external | The deliberate clean push/release that lands the ci.yml matrix on public `origin/main` |
| R-B | **WR-01** — alternate-schema test fixture uses `CREATE TABLE … LIKE "threadline"."table" INCLUDING ALL` rather than applying generated migrations; schema-local FK constraints unproven | `190-VERIFICATION.md:93` (WARNING, non-blocking) | future schema-fixture hardening | Maintainer-confidence (test fidelity); runtime isolation already proven, generated-migration SQL separately contracted | A custom-schema FK regression appears, or a phase chooses to apply real migrations in the fixture |
| R-C | **`v1_23_charter_doc_contract_test.exs` drift** — asserts PROJECT.md v1.38 milestone literals; PROJECT.md correctly moved to v1.39, so the test fails | `191/deferred-items.md`, `191-VERIFICATION.md:101` | charter / SSOT-truth owner | Maintainer (doc-contract greenness); pre-existing, outside 191's file scope | Fix by refreshing the expected literal to the active milestone or binding it to an SSOT; reopen if `verify.doc_contract` must be fully green before archive |
| R-D | **~81 local `mix test` failures** — `(undefined_table) relation "audit_changes"/… does not exist` | `192-VERIFICATION.md` out-of-scope observation; MEMORY `local-test-db-storage-schema-failures` | maintainer env / Phase-190 territory | Maintainer-friction ONLY — **explicitly NOT a v1.39 quality regression** (identical count at pre-192 commit and HEAD; CI provisions the DB correctly) | A CI (not local) test failure with the same signature, i.e. the env issue reaches the provisioned pipeline |

**Critical framing (from CONTEXT `<specifics>`):** R-D must be recorded as maintainer-friction, NOT
a regression — the count is identical before and after Phase 192 and CI is green; presenting it as a
v1.39 quality defect would be dishonest in the opposite direction (over-claiming risk). R-C is a
milestone-literal drift, not a version-truth defect (ADOPT-01's `0.9.0` reconciliation is proven).

## Next-Step Recommendation (CLOSE-01 clause 4)

### HOLD / thin-polish, backed by three converging gates + config policy [VERIFIED: config.json + STATE.md + 189 ledger]

| Gate | Evidence | Supports HOLD? |
|------|----------|----------------|
| Done-band threshold | Scope completion ~92–95% (`STATE.md`) vs `done_band_threshold: 90` (`config.json`) | Yes — above threshold |
| External-adopter signal | No sustained real signal; `STATE.md` Deferred Items keeps external-pilot "Deferred until sustained real-adopter signal"; REQUIREMENTS Out-of-Scope forbids "external pilot without real signal" | Yes — no signal to flip |
| Candidate adjudication | 189 ledger already scored every remaining candidate 2–4 ("good enough / future seed"); every score-1 must-fix (rows 1–3) closed inside v1.39 | Yes — nothing left demands a milestone |

Config policy structurally supports the recommendation: `default_no_signal_path: hold_or_thin_polish`,
`no_auto_new_milestone: true` (193 recommends, does not open v1.40), `adopter_lens: true`
(ranking lens matches D-12). [VERIFIED: config.json `milestone_next_step` + `milestone_assessment`]

### Armed flip-triggers → Future Requirements (D-07) [VERIFIED: REQUIREMENTS.md L45-61]

| Trigger (observed signal) | Flips to | Future Req | Note |
|---------------------------|----------|------------|------|
| Named external host/integrator commits to a pilot | External adopter proof | **EXT-PILOT-01** | Highest-leverage; simultaneously arms observability |
| Measured **sustained** CI bottleneck the Phase-192 changes did NOT resolve | CI/CD depth | (CI depth, not a Future Req ID) | Requires post-ship measurement first (the ship-gated run) |
| Real operator production-debugging gap / audit re-scores debuggability score-1 | Observability | **OBS-01** | Phase 189 did NOT flag debuggability — do NOT auto-promote without fresh evidence |
| Visual regression escapes a release | UI regression confidence | **UI-REG-01** | 189 keeps screenshot-regression a "prove before claim" future seed |
| Socket-drop spec failure / operator field report | Reconnect UX | **RECONNECT-01** | 189 scored SEED-005 reconnect "good enough"; reopen only on real failure |

**Thin-polish content if pursued (D-06):** close ship-gated 192-04-03 when it can legitimately go
public, plus Nyquist/charter/frontmatter backlog cleanup (R-C is a natural candidate). Nothing here
needs a version bump.

## Verification Approach for a Docs/Evidence Phase (Research Q5)

There is no runnable feature, so `193-VERIFICATION.md` asserts **presence + internal consistency +
traceability completeness**, NOT a test suite. `nyquist_validation: true` in config, but the honest
mapping for a docs phase is document-integrity assertions, not ExUnit. Recommended checks:

| Check class | What it asserts | How |
|-------------|-----------------|-----|
| Presence | All four CLOSE-01 clause artifacts exist (whichever filenames/merge chosen) | file existence |
| Traceability completeness | 15/15 requirements appear in the rollup, each with a phase + proof pointer; 0 unmapped/orphaned | cross-check against `REQUIREMENTS.md` table |
| Internal consistency | Every risk-register row has Owner + concrete reopen-trigger (no bare "polish later"); every honest-unavailable CI row has the four Nyquist-debt fields | structural read of the artifacts |
| Evidence-pointer validity | Every cited proof artifact/path exists on disk | path existence for each reference |
| Boundary/scope | No product code, schema, UI, workflow, version, or tag changed; `v1.39-MILESTONE-AUDIT.md` NOT created by 193; ROADMAP/REQUIREMENTS/PROJECT unmutated | `git diff --stat` shows only `.planning/phases/193-*` files |
| Recommendation completeness | HOLD stated with all three gates + all five armed triggers mapped | structural read |

Optionally (Claude's discretion, D-10) a lightweight lint could assert the risk register carries no
row lacking an owner — but a manual structural review is sufficient; do NOT invent an ExUnit lane for
planning markdown. Mirror the existing `189-VALIDATION.md` / static-artifact-validation style already
used for `189-QUALITY-AUDIT.md` and `192-BASELINE.md`.

## Sequencing Boundary & the D-10↔D-03 Tension (Research Q6)

**Boundary:** `193 (evidence/decision) → /gsd-audit-milestone → /gsd-complete-milestone`.
`/gsd-audit-milestone` produces `v1.39-MILESTONE-AUDIT.md` (the cross-phase integration/E2E/traceability
snapshot in the `v1.38-MILESTONE-AUDIT.md` format); `/gsd-complete-milestone` does the local archive +
local tag (tags stay local — never push `main` to public origin). 193 slots strictly BEFORE both and
must not duplicate their artifacts (D-02/D-03). [VERIFIED: CONTEXT D-03 + MEMORY milestone-tags-stay-local]

**The tension (flag for planner/discuss — see OQ-1):** D-03 sequences `/gsd-audit-milestone` AFTER
193, while D-10 describes running `/gsd-audit-milestone` ONCE as the register-building *method* (as an
input 193 hand-ranks on top of). Both cannot be literally true if the audit is "after" 193 yet also
"input to" 193's register. The `additional_context` lean and D-03's higher-level sequencing both point
to the same resolution.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Ranked risk register | A fresh from-scratch severity×likelihood matrix | Verify-and-refresh the 189 ledger; adoption/ops/maintainer lens | 189 is already ranked, owner-tagged, reopen-triggered and names 193 as consumer (D-11/D-12) |
| CI before/after numbers | Synthetic/estimated wall-clock or cache-hit figures | Static structural diff + honest-unavailable Nyquist-debt rows | The after-config never ran publicly; fabricating numbers violates the DNA honesty rule (D-09) |
| Evidence/residual section layout | A new bespoke closeout format | Mirror `v1.38-MILESTONE-AUDIT.md` section skeleton | Proven format the downstream `/gsd-audit-milestone` also uses |
| Milestone audit snapshot | Writing `v1.39-MILESTONE-AUDIT.md` in 193 | Leave it to `/gsd-audit-milestone` (post-193) | D-03 — wrong owner; would duplicate + risk drift |
| Honest-unavailable metric rows | A plain "N/A" cell | The four-field owner/date/superseding-pointer/reopen-trigger row | Matches `192-BASELINE.md` and DNA Nyquist-debt shape |

**Key insight:** this phase's risk is *over-doing* it — re-analyzing already-proven evidence, or
straying into ship/archive/audit territory owned downstream. The highest-quality plan is the one that
synthesizes and points, and stops exactly at the D-01/D-02 boundary.

## Common Pitfalls

### Pitfall 1: Running `/gsd-audit-milestone` inside Phase 193
**What goes wrong:** produces `v1.39-MILESTONE-AUDIT.md`, which D-02/D-03 explicitly say 193 must NOT
create; duplicates the follow-on skill's artifact and risks drift between two audit files.
**How to avoid:** 193 mirrors the v1.38 audit FORMAT for its hand-synthesized evidence sections but
does not run the skill or emit the audit file. Resolve OQ-1 before planning the register task.
**Warning sign:** a task action that shells `/gsd-audit-milestone` or writes `v1.39-MILESTONE-AUDIT.md`.

### Pitfall 2: Presenting the ~81 local test failures as a v1.39 regression
**What goes wrong:** over-claims risk; contradicts `192-VERIFICATION.md` (identical count pre/post,
CI green) and MEMORY guidance; would falsely gate the closeout.
**How to avoid:** record R-D as maintainer-friction / env issue only, with the "identical count, CI
provisions DB correctly" evidence inline.
**Warning sign:** the register ranks R-D above the ship-gated or storage-schema residuals.

### Pitfall 3: Fabricating after-timing to make before/after look complete
**What goes wrong:** invents wall-clock/cache-hit numbers the ship-gate makes impossible to measure;
violates DNA honesty and the whole point of CLOSE-01's "explicit no-measure rationale."
**How to avoid:** use the D-09 honest-unavailable rows; frame runtime deferral as intended, not a gap.
**Warning sign:** any numeric "after" wall-clock or cache-hit-rate value in the CI diff.

### Pitfall 4: Editing milestone-level files (ROADMAP/REQUIREMENTS/PROJECT) or bumping version/tag
**What goes wrong:** crosses into `/gsd-complete-milestone` scope (D-02); could corrupt STATE via the
known `gsd-sdk state.*` handler bug, or leak planning history if a tag/push is attempted.
**How to avoid:** 193 emits only `193-*` files under its own phase dir; boundary check in verification
asserts `git diff --stat` touches nothing else.
**Warning sign:** a task modifying `REQUIREMENTS.md`, `PROJECT.md`, `ROADMAP.md`, `mix.exs`, or `git tag`.

### Pitfall 5: Re-litigating the good-enough / future / external rows (189 rows 6–12)
**What goes wrong:** manufactures scope (e.g., promoting OBS-01 observability though 189 never flagged
debuggability), contradicting D-05/D-07.
**How to avoid:** preserve rows 6–12 verbatim; observability/UI-REG/reconnect stay parked behind their
flip-triggers with the "no fresh evidence → no promotion" note.
**Warning sign:** the next-step artifact recommends anything other than HOLD without a named trigger firing.

## Runtime State Inventory

**N/A — not a rename/refactor/migration phase.** Phase 193 writes new `193-*` planning artifacts and
mutates no stored data, service config, OS-registered state, secrets, or build artifacts. No runtime
state carries any renamed string. (Verified by scope: CONTEXT D-01/D-02 constrain output to docs.)

## Environment Availability

**Largely N/A.** The phase synthesizes existing repo files; it has no external tool dependency for its
in-repo work. One optional note: if OQ-1 resolves toward any milestone-audit-style cross-phase re-check
that reads GitHub run history, the `gh` CLI would be involved — but the recommended plan (static in-repo
diff, D-08) needs no network and no `gh`. `git` is the only required tool and is present.

## Security Domain

**N/A — no code, no attack surface, no data handling.** `security_enforcement` is not set to a value
that applies here; this phase produces planning markdown only. No ASVS category applies. The one
security-adjacent invariant to honor is operational, not code: **do not push `main` to public
`origin`** (would leak ~395 commits of private `.planning/` history) and **keep milestone tags local** —
both are already out of scope per D-02 and reinforced in the boundary check.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The recommended resolution of the D-10↔D-03 tension is to NOT run `/gsd-audit-milestone` inline and leave the audit artifact to the post-193 skill | Sequencing Boundary / OQ-1 | If the user actually wants the audit run inline as register input, the register task's method changes (still low-risk: it only changes whether a skill is invoked vs. format mirrored). Flagged for discuss/planner confirmation. |
| A2 | Exact `193-*` filenames / whether clauses merge into one doc | throughout | None material — explicitly Claude's discretion (CONTEXT). Planner picks. |
| A3 | Scope completion is ~92–95% (from STATE.md assessment band) and remains above the 90 done-band at closeout | Next-Step | Low — even at the band's floor it clears 90; HOLD holds. |
| A4 | R-D (~81 local failures) count is still identical at current HEAD (not just at the 192 verification commit) | Risk Register R-D | Low — MEMORY + 192-VERIFICATION both confirm; a quick `mix test` count at plan time would re-verify if desired. |

**Note:** No `[ASSUMED]`-tagged package or compliance claims exist — this phase installs nothing and
sets no policy. All substantive claims are `[VERIFIED: repo file]` from this session's reads.

## Open Questions

1. **OQ-1 — D-10↔D-03 wording tension: run `/gsd-audit-milestone` inline or after 193?**
   - What we know: D-03 sequences the audit AFTER 193 and says 193 must NOT produce
     `v1.39-MILESTONE-AUDIT.md`; D-10 describes running it ONCE as the register method.
   - What's unclear: whether "run once" means literally invoke the skill during 193, or mirror its
     format while hand-synthesizing.
   - Recommendation: **do NOT run it inline.** 193 hand-synthesizes evidence sections in the v1.38
     audit FORMAT from the existing phase VERIFICATION artifacts (which already contain integration /
     E2E / traceability evidence), and the formal `/gsd-audit-milestone` run happens post-193 per D-03.
     Rationale: (a) running it inline would create the very artifact D-02/D-03 forbid 193 from creating;
     (b) D-03 is the higher-level sequencing decision; (c) the cross-phase evidence D-10 wants "regardless"
     already exists on disk and can be indexed without the skill. Confirm with the user in discuss/plan.

2. **OQ-2 — Merge vs. split the four CLOSE-01 artifacts?**
   - What we know: filenames/merge are Claude's discretion.
   - Recommendation: split into four focused files (`193-TRACEABILITY.md`, `193-EVIDENCE-INDEX.md`,
     `193-RISK-REGISTER.md`, `193-NEXT-STEP.md`) + standard `193-VERIFICATION.md` / `193-SUMMARY.md`;
     each maps 1:1 to a CLOSE-01 clause and to a verification presence-check. A single mega-doc is also
     valid but harder to verify clause-by-clause. Planner decides.

3. **OQ-3 — Run `/gsd-audit-uat` once as cheap confirmation, or skip (D-10 skip lean)?**
   - Recommendation: **skip** — v1.39 introduced no `*-UAT.md` files; it would only re-surface
     already-deferred v1.36 rows (near-zero expected value). Skip is the default; note it explicitly in
     the evidence index so the decision is visible.

## State of the Art

**N/A — no fast-moving technology.** Closeout methodology is project-native and stable; the reference
formats (`v1.38-MILESTONE-AUDIT.md`, `192-BASELINE.md` Nyquist-debt rows, 189 ranked ledger) are the
current-state-of-the-art within this repo and were all produced in the last two milestones.

## Project Constraints (from CLAUDE.md)

- Cite named `mix verify.*` / `mix ci.*` entrypoints verbatim in any evidence that references CI/tests
  (do not invent ad-hoc commands). Relevant here for the traceability/evidence artifacts:
  `mix verify.test`, `mix verify.doc_contract`, `mix ci.all`.
- Use domain language consistently (AuditTransaction / AuditChange / AuditAction / AuditContext /
  ActorRef / Correlation) if any evidence text touches the domain — mostly N/A for this closeout.
- Respect the three-layer architecture framing (capture / semantics / exploration-ops) when
  characterizing what a residual affects (e.g. WR-01 is a capture/storage-schema fixture-fidelity
  residual, not a semantics or exploration defect).
- **GSD gotcha:** when running `gsd-sdk query state.begin-phase`, use POSITIONAL args
  (`phase slug plan_count`) — flag-style invocations can corrupt `.planning/STATE.md`. Also note the
  MEMORY caveat that `state.advance-plan` / `update-progress` / `record-metric` miscompute STATE's
  bespoke progress block — hand-correct after calling.

## Sources

### Primary (HIGH confidence — read this session)
- `.planning/phases/193-.../193-CONTEXT.md` — locked decisions D-01..D-12
- `.planning/REQUIREMENTS.md` — CLOSE-01, Future Requirements, traceability table, Out-of-Scope
- `.planning/ROADMAP.md` §Phase 193 — goal + four success criteria
- `.planning/STATE.md` — done-band ~92–95%, Deferred Items, decision log
- `.planning/phases/189-.../189-QUALITY-AUDIT.md` — the ranked risk-register seed (12-row ledger + QUAL-03 residuals)
- `.planning/phases/190-.../190-VERIFICATION.md` — SCHEMA closeout + WR-01 residual
- `.planning/phases/191-.../191-VERIFICATION.md` + `deferred-items.md` — ADOPT closeout + charter-test drift
- `.planning/phases/192-.../192-BASELINE.md` — CI "before" baseline + honest-unavailable ledger
- `.planning/phases/192-.../192-VERIFICATION.md` — CI closeout (16/16) + ~81 local-env observation
- `.planning/phases/192-.../192-SHIP-CHECKLIST.md` — ship-gated D-17/D-19 residual
- `.planning/milestones/v1.38-MILESTONE-AUDIT.md` — closeout FORMAT to mirror
- `.planning/config.json` — `milestone_next_step` / `milestone_assessment` policy
- `CLAUDE.md` — verify.*/ci.* entrypoints, three-layer architecture, domain language, GSD gotcha

### Secondary (MEDIUM confidence)
- MEMORY: `local-test-db-storage-schema-failures`, `milestone-tags-stay-local`,
  `gsd-state-handlers-corrupt-progress` — corroborate R-D framing, tag-stays-local, and STATE caveats

### Tertiary (LOW confidence)
- None. No web sources needed; this is an in-repo synthesis phase.

## Metadata

**Confidence breakdown:**
- Traceability skeleton: HIGH — every row cross-checked against REQUIREMENTS.md + phase VERIFICATION files.
- CI before/after: HIGH — static deltas verified in `192-VERIFICATION.md` truths; honest-unavailable rows verbatim from `192-BASELINE.md`.
- Risk register: HIGH — seed + all four fold-in residuals read directly from source artifacts.
- Next-step recommendation: HIGH — three gates + config policy all verified in-repo.
- Sequencing/OQ-1: MEDIUM — the D-10↔D-03 wording tension needs a user confirmation, though the recommended resolution is well-supported.

**Research date:** 2026-07-02
**Valid until:** 2026-08-01 (stable; the only volatility is if new residuals land before 193 executes — re-scan phase artifacts if that happens)
