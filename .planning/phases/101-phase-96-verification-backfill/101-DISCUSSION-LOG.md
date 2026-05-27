# Phase 101: Phase 96 Verification Backfill - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 101-phase-96-verification-backfill
**Areas discussed:** Truth-band granularity, Rerun bundle scope, Phoenix-optional / no-ambient-state proof method, Subject-helper inventory enforcement, `mix verify.test` alias-drift, PROOF-01 closure row layout, "Not closed here" section content

---

## Truth-band granularity

| Option | Description | Selected |
|--------|-------------|----------|
| 3 bands (Phase 100 parallel) | Write contract / Read contract / Defaults+Phoenix-optional fused. Strict structural parity with Phase 100. Risk: fuses provenance defaults and Phoenix-optional install into one band. | |
| 4 bands (recommended) | Write contract / Read contract / Defaults+provenance / Phoenix-optional + no-ambient-state. Phase 96 has more contract surface than Phase 95; splitting these makes each PASS/FAIL block point at one decision. | ✓ |
| 5 bands (one per major decision cluster) | Write / Read / Defaults+provenance / Phoenix-optional / No-ambient-state. Risk: 'Phoenix-optional' and 'no-ambient-state' are tightly entangled; splitting fragments proof. | |

**User's choice:** 4 bands
**Notes:** Sets the artifact structure for `96-VERIFICATION.md` per D-03 in CONTEXT.md. Phase 100's 3-band shape is the structural template; Phase 101 expands to 4 bands without changing the band shape itself.

---

## Rerun bundle scope

| Option | Description | Selected |
|--------|-------------|----------|
| Narrow focused bundle (Phase 100 parallel) | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1`. Mirrors Phase 100 narrowing. Risk: contradicts current `96-VALIDATION.md` which names `mix verify.test`. | ✓ |
| Honor 96-VALIDATION.md (`mix verify.test`) | Cite `mix verify.test` as the authority band. Risk: broader surface for unrelated failures (e.g., the alias-drift tech debt). | |
| Both — focused as primary, verify.test as supporting | Cite focused bundle as authoritative; cite `mix verify.test` as supporting. Two PASS blocks per relevant band. | |

**User's choice:** Narrow focused bundle
**Notes:** This forces a literal-truth repair to `96-VALIDATION.md`'s authority band per D-06. The repair is in scope under Phase 101's smallest-literal-truth-repair posture.

---

## Phoenix-optional / no-ambient-state proof method

| Option | Description | Selected |
|--------|-------------|----------|
| Structural grep + arity citation (recommended) | Two literal proofs: tightened `rg` negative-assertion against `lib/threadline/evidence.ex` + cite explicit `repo:` opt requirement. No new test required. | ✓ |
| Cite existing test isolation only | Cite that `test/threadline/evidence_test.exs` exercises Evidence without Plug/Phoenix. Risk: indirect proof — test passing doesn't prove absence of ambient lookups. | |
| Add a small dedicated test | Add a test that poisons `Process.put` and `Logger.metadata` and asserts Evidence ignores them. Strongest behavioral proof. Risk: adds new code to a verification-backfill phase. | |
| Structural grep + behavioral test (both) | Combine (a) and (c). Most thorough but exceeds verification-backfill scope. | |

**User's choice:** Structural grep + arity citation
**Notes:** During the sanity check, the naive grep pattern matched the moduledoc string at `lib/threadline/evidence.ex:5`. CONTEXT.md D-09 records the tightened pattern that only matches actual module references and runtime calls: `'^\s*(import|alias|require|use)\s+(Plug|Phoenix)\.|Process\.(put|get)\(|Logger\.metadata\(|:ets\.'`. The naive pattern is explicitly forbidden from the artifact.

---

## Subject-helper inventory enforcement

| Option | Description | Selected |
|--------|-------------|----------|
| Assert exact function names (recommended) | Cite the six specific `record_*` helpers by name + `rg -n 'def record_'` closed-set proof. Strongest boundary proof. | ✓ |
| Assert closed-set property only | Cite that the public writer set matches `Threadline.Evidence.Subject` supported subjects, without naming each function. Lower-maintenance but weaker boundary. | |
| Exact names + list_latest_* shape parity | (a) plus matching `list_latest_*` and `get_latest_*` helper-shape assertions. Pulls one Read-contract decision into the Write-contract band — overlaps with the 4-band split. | |

**User's choice:** Assert exact function names
**Notes:** The list-vs-singular shape discipline (D-10/D-11/D-12 from Phase 96 CONTEXT) lives in the Read-contract band, not the Write-contract band, to keep the 4-band split clean (CONTEXT.md D-13).

---

## `mix verify.test` alias-drift tech debt

| Option | Description | Selected |
|--------|-------------|----------|
| Disclaim in band authority statement (recommended) | The band-3/4 authority statement names the focused bundle as the Phase 96 contract proof; a one-line note records Phase 99 ownership and commit `b636c17` as the most recent fix. No new repair triggered. | ✓ |
| Run `mix verify.test` in 101-01 preflight as repo-health context only | Surface its actual status in preflight; PASS gets noted, FAIL gets noted as carry-forward tech debt without triggering a repair. | |
| Treat alias drift as in-scope literal-truth repair if still broken | If `mix verify.test` still fails for an alias reason, 101 makes the minimal repair. Risk: pulls Phase 99 ownership into Phase 101's boundary. | |

**User's choice:** Disclaim in band authority statement
**Notes:** Quick git-log check found commit `b636c17` ("fix(99-02): update ci.all topology contract to expanded doc_contract alias") at HEAD, suggesting the alias-drift may already be resolved. Phase 101 still disclaims rather than re-fixing — Phase 99 is the owner.

---

## PROOF-01 requirement-closure row layout

| Option | Description | Selected |
|--------|-------------|----------|
| One row (Phase 100 parallel, recommended) | Single `PROOF-01 \| ✓ SATISFIED \| <one prose sentence>`. Matches Phase 100's convention and aligns with `.planning/REQUIREMENTS.md` Traceability single-row entry. | ✓ |
| Three sub-rows (one per sub-claim) | Three rows for create / read / Phoenix-optional. More granular but creates a Phase-96-specific table shape that doesn't match Phase 100 or REQUIREMENTS.md. | |

**User's choice:** One row
**Notes:** Detail lives in the 4 numbered bands; the closure table is a summary. Reduces friction for Phase 103 reconciliation.

---

## "Not closed here" section content

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 100 boilerplate only (recommended) | Same three bullets as Phase 100: REQUIREMENTS.md / ROADMAP.md / STATE.md intentionally unreconciled — Phase 103 work. Plus one closing line. | ✓ |
| Boilerplate + Phoenix-optional behavioral test exclusion | Add a fourth bullet noting the behavioral test was intentionally not added. Documents the trade-off. | |
| Boilerplate + Phase 97/98 dependency note | Add a bullet noting Phase 97 and 98 consumers depend on this contract; their verification artifacts already passed. Forward-references for Phase 103. | |
| Both (b) and (c) | Most explicit but lengthens the section. Risk: catchall for things already closed elsewhere. | |

**User's choice:** Phase 100 boilerplate only
**Notes:** The chosen proof method (structural grep + arity citation) is the proof, not a deferral, so it does not belong in "Not closed here" (CONTEXT.md D-10).

---

## Claude's Discretion

- Exact prose wording inside each band's bullet list (PASS/FAIL block and cited command must remain explicit).
- Exact ordering of the four bands (Write before Read; Phoenix-optional positioned as holistic boundary).
- Exact `## Commands Actually Used` formatting in `96-VALIDATION.md`.
- Whether to break the structural grep into one or two `rg` invocations.

## Deferred Ideas

- Behavioral test poisoning `Process.put` / `Logger.metadata` (chosen proof method makes this unnecessary; not deferred to a future phase, just not added).
- Repairing `mix verify.test` alias-drift (Phase 99 owns; commit `b636c17` is the latest fix).
- Updating `.planning/REQUIREMENTS.md` PROOF-01 row from `Pending` to `Complete` (Phase 103).
- Updating `.planning/ROADMAP.md` Phase 101 plan checkboxes (Phase 103 / milestone closeout).
- Updating `.planning/STATE.md` to reflect Phase 101 closure (Phase 103).
- Root-level `Threadline.*` delegates for `Threadline.Evidence` helpers (already deferred in Phase 96, still deferred).
- Phase 102 (SURF backfill) and Phase 103 (authority-surface reconciliation) — separate phases.
