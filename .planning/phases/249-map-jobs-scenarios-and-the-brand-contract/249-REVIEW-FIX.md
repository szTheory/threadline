---
phase: 249
fixed_at: 2026-11-12T06:34:03Z
review_path: .planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-REVIEW.md
iteration: 2
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 249: Code Review Fix Report

**Fixed at:** 2026-11-12T06:34:03Z
**Source review:** `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-REVIEW.md`
**Iteration:** 2

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### WR-01: Scenario class changes bypass class-specific validation

**Disposition:** fixed; focused automated proof and independent confirmation complete
**Files modified:** `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts`
**Source commit:** `0ff17d6ed9519083f66aa1e0fc027bf2ecfac577`

**Applied fix:** Pinned the expected `ordinary`, `boundary`, or `stress` class for all eleven required scenario IDs. Missing and unknown scenario IDs remain invalid. Added the requested negative control that changes `scenario.state-empty` to `boundary`, removes its `ordinaryBaseline`, and asserts that the class mismatch fails.

**Proof:** The focused Node contract command passed 30/30 tests after this change. The negative control runs in the named-scenarios contract test.

### WR-02: Reference identity checks miss blank and duplicate brand-role IDs

**Disposition:** fixed; focused automated proof and independent confirmation complete
**Files modified:** `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts`
**Source commit:** `970419ba80745aeda4eb499e5967c584538464f9`

**Applied fix:** Added one reusable per-list guard requiring string IDs that are not blank and are unique within that reference list. Applied it to scenario source, fixture, and proof references, brand-role source and proof references, and the other object reference lists checked by this contract. Each list builds its own identity set, so shared baseline and authority IDs across separate lists remain valid. Added missing Acme fixture ID, missing and duplicate named-scenario fixture ID, and blank and duplicate brand-role source and proof ID controls. Existing Unicode, repeated-label, and identity assertions remain in place.

**Proof:** The focused Node contract command passed 30/30 tests after this change, including all added identity mutations.

### WR-03: Focused contract test reads active requirements that milestone completion removes

**Prior review title:** Focused contract test reads planning files that normal cleanup moves; the current title reflects the remaining active-requirements lifecycle finding.
**Disposition:** fixed; lifecycle automated proof and independent confirmation complete
**Files modified:** `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts`, `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json`
**Source commit:** `b7e6c6f46e18f34a0a4114e77420832c27c1b1de`

**Applied fix:** Added explicit selection for this known v1.48 requirements source: the versioned archive is preferred whenever present, the active requirements file is used before closeout, and missing both fails during module initialization. The inventory reference is rebound to the actual selected path and uses stable ADM-06 requirement wording; it no longer cites the transient Pending/Complete traceability cell. The unresolved, non-authoritative ADM-06 flag and later owners remain unchanged.

**Proof:** The focused Node command passed 32/32 tests with the current active v1.48 source, and again in each private lifecycle fixture: (1) archived v1.48 requirements with active requirements and `.planning/phases` absent; (2) the v1.48 archive alongside an unrelated later active requirements file, confirming archive precedence; and (3) active requirements with the ADM-06 traceability cell changed from Pending to Complete. A missing-both-sources control exited 1 with the explicit expected-source error. Fixtures were private copies and removed after each run; the real planning files were not moved or changed. The earlier phase-only fixture claim at `4f0b523e` is superseded by these lifecycle proofs.

## Verification and Limits

Verification ran in the existing authorized orchestrator checkout `.claude/worktrees/v148-admin-orchestrator` on `agent-v148-admin`; no separate fixer worktree was created. The final focused command was `./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts support/operator-route-evidence.test.ts` from `examples/threadline_phoenix/e2e` and passed 32/32 tests at source revision `b7e6c6f4`. The three private success fixtures each passed the same 32 tests. The source map selects the archive over any active file, rewrites the known ADM-06 reference to that actual selected source before validation, and preserves missing-source failure visibility.

No project-aware TypeScript typecheck was available: the nearest `package.json` has no `typecheck` script and no `tsconfig*.json` was present. These checks cover local Node contract behavior and source ownership only. They do not establish browser, database, full-suite, hosted CI, visual, accessibility, or release acceptance.

**Operational retries:** The first normal-hook commit could not create the linked worktree index lock; the same file-scoped commit succeeded with authorized sandbox elevation and normal hooks. One WR-02 commit preflight compared a short hash with a full hash and stopped before staging; the corrected short-hash check committed successfully. An initial phase-path scan matched the test's own assertion literal and was changed to check path segments. The first private fixture launch pointed at the wrong `node_modules` location and failed with `ENOENT`; using the prepared E2E-local runner passed all 32 tests. In this continuation, the normal commit again hit the linked index lock and the elevated normal-hook commit succeeded. The first missing-source assertion inspected stderr only; Node's TAP reporter emitted the expected module-load failure on stdout, so the control was corrected to inspect both streams and then passed.

---

_Fixed: 2026-11-12T06:34:03Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_

## Verification policy clarification

The fixer template initially labeled each applied fix as requiring human verification. The project explicitly requires zero routine human verification: focused automated controls and the parent-assigned independent re-review are the applicable proof. Those template labels were corrected before report acceptance; no maintainer action or human attestation is requested or fabricated.

## Current independent confirmation

WR01 and WR02 are independently confirmed fixed at `4f0b523e`. WR03's version-specific lifecycle correction is committed at `b7e6c6f4`; the active, archived, archive-priority, Pending-to-Complete, and missing-source cases now have focused automated proof. The earlier phase-only fixture claim at `4f0b523e` is superseded. Independent confirmation is clean at b7e6c6f4: all three original findings are confirmed fixed. No human verification is requested.
