# Phase 102: Phase 98 Verification Backfill - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 102-phase-98-verification-backfill
**Areas discussed:** Band structure & SURF mapping, Proof method per band, Rerun bundle authority, UI-SPEC handling

**Discussion mode:** User requested deep parallel-subagent research with one coherent recommendation set, rather than single-question turns. Four `gsd-advisor-researcher` agents were dispatched in parallel, each scoped to one area, each reading Phase 100/101 precedent, Phase 98's current-tree surface, Phase 84-VERIFICATION precedent for UI-SPEC handling, and project prompts/ docs. The user then locked the synthesized recommendation set as-is without further questions.

---

## Band structure & SURF mapping

| Option | Description | Selected |
|--------|-------------|----------|
| A — 3 bands, 1:1 with SURF | Band 1 = SURF-01 (`/audit/evidence` lives on existing operator family). Band 2 = SURF-02 (parity — shared presenter, verdict vocabulary). Band 3 = SURF-03 (host-owned `evidence_authorize_fn`, no RBAC). Cleanest mapping; mirrors Phase 100's 3-band shape. | ✓ |
| B — 4 bands, separate unsupported-state band | Bands 1–3 as above plus Band 4 = explicit unsupported-state / CLI fallback posture (cross-cuts SURF-02 + SURF-03). Mirrors Phase 96's 4-band shape. | |
| C — 4 bands, SURF-01 split | Splits SURF-01 into route-shape + read-only bands. | |

**User's choice:** Option A (via locked synthesized recommendation set)
**Notes:** Research agent identified that Phase 96's 4-band layout was a workaround for a single-requirement phase (`PROOF-01` covering four contract surfaces), not a template to copy when requirements are already plural. SURF-01/02/03 already factor cleanly, so the 1:1 mapping is the cleanest closure-table alignment with REQUIREMENTS.md three rows. Unsupported-state/fallback proof folds into SURF-02 (vocabulary includes `unsupported`) and SURF-03 (host gate denial path), not an orthogonal claim.

---

## Proof method per band

| Option | Description | Selected |
|--------|-------------|----------|
| A — Behavioral-only | Every band cites `mix test ... --max-failures 1`. No structural grep. | |
| B — Structural-only | Every band cites `rg -n` patterns + arity/function-name inventories. No test runs in artifact. | |
| C — Behavioral + structural per band (mixed, hierarchical) | Each band picks the strongest proof for its specific claim. Mirrors Phase 101 D-08/D-09/D-10 mixed posture but adapted for a LiveView surface. | ✓ |
| D — Behavioral-primary + structural fallbacks | Behavioral test is headline; structural grep is fallback only for negatives. | |

**User's choice:** Option C (via locked synthesized recommendation set)
**Notes:** Research agent confirmed SURF-01 and SURF-03 each contain irreducibly negative clauses ("no new UI family", "no Threadline RBAC") that grep proves cleanly but behavior cannot. Phase 98 has 34 passing tests across `auth_test.exs` and `evidence_live_test.exs`, so the behavioral half is essentially free. The mixed posture is the strongest available proof per band. Added negative-grep + positive-control-grep pairing so path typos fail loudly rather than silently passing.

---

## Rerun bundle authority

| Option | Description | Selected |
|--------|-------------|----------|
| A — Two-file focused bundle (auth_test + evidence_live_test) | Adopt the current `98-VALIDATION.md` Quick command verbatim. | ✓ |
| B — Widen with presenter/view-model parity tests | Add any presenter/view-model test files. | |
| C — Narrow to single focused command | One `mix test` invocation against just the LiveView test; auth_test cited as supplementary in Behavioral Spot-Checks. | |
| D — Multi-band, multi-command | Each band names its own focused test invocation. | |

**User's choice:** Option A (via locked synthesized recommendation set)
**Notes:** Research agent ran the candidate bundle on the current tree and confirmed PASS — 34 tests, 0 failures, 0.2s runtime. No presenter test file exists separately, so Option B has no widening candidate. The two-file coupling is intentional and contract-direct: `auth_test.exs` owns SURF-03 capability boolean fan-out, `evidence_live_test.exs` owns SURF-01 mount + SURF-02 parity. `mix verify.test` is disclaimed using Phase 101 D-07's pattern verbatim, citing commit `b636c17` (Phase 99-02 alias topology fix) as the most-recent known repair.

---

## UI-SPEC handling

| Option | Description | Selected |
|--------|-------------|----------|
| A — Out of scope | `98-VERIFICATION.md` doesn't cite UI-SPEC.md at all. | |
| B — Reference-only | Cite as canonical ref but not band authority. | |
| C — Band 2 authority for SURF-02 parity (locked literals only) | Make `98-UI-SPEC.md` a Band 2 authority, scoped strictly to mechanically-verifiable copy literals already present in `evidence_live.ex` + tests. Visual hierarchy / spacing / color remain Manual-Only. | ✓ |
| D — Separate UI-SPEC parity band | Add an extra band specifically asserting design contract match. | |

**User's choice:** Option C (via locked synthesized recommendation set)
**Notes:** Research agent identified Phase 84-VERIFICATION as the internal precedent — Band 2 there cites `84-UI-SPEC.md` alongside lib/test paths for locked copy literals. Five locked literals were identified as code-verifiable (landing title, verdict triple, View history CTA, empty-state heading, denied-state heading), each with both source location and test assertion already in place. Visual hierarchy / spacing tokens / typography / color palette are NOT code-anchorable from this surface and explicitly remain Manual-Only per `98-VALIDATION.md`. The "Not closed here" section names this boundary explicitly so a future reviewer doesn't try to grep visual claims.

---

## Claude's Discretion

- Exact prose wording inside each band's bullet list (PASS/FAIL block and cited test/grep command must remain explicit).
- Exact ordering of the three bands (must read as SURF-01 → SURF-02 → SURF-03).
- Whether to render the locked-literal table (D-12) verbatim inside Band 2 or inline each row as a separate Result bullet.
- Exact `## Commands Actually Used` numbering if 102-01's repair adds additional commands actually executed.

## Deferred Ideas

- Visual hierarchy, spacing tokens, typography sizing, color palette adherence from `98-UI-SPEC.md` — Manual-Only per `98-VALIDATION.md`.
- Exhaustive behavioral test poisoning every host capability boolean for `assign_evidence_enabled` — verification-backfill posture, no widening.
- Repairing the `mix verify.test` alias-drift — owned by Phase 99; disclaimed.
- Updating `.planning/REQUIREMENTS.md` SURF rows from `Pending` to `Complete` — Phase 103.
- Updating `.planning/ROADMAP.md` Phase 102 checkboxes to `[x]` — Phase 103.
- Updating `.planning/STATE.md` to reflect Phase 102 closure — Phase 103.
- Root-level `Threadline.*` delegates / new evidence helpers — already deferred by Phase 96.
- Phase 103 authority-surface reconciliation — next phase, not in this scope.
