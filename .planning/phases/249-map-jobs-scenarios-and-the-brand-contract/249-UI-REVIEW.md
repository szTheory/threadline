# Phase 249 — UI Review

**Audited:** 2026-11-12  
**Baseline:** Approved `249-UI-SPEC.md` (reference-only mapping contract)  
**Screenshots:** Not captured; Phase 249 authority limits this to code/reference review, with no browser or app capture.  
**Interaction captures:** off (`workflow.ui_interaction_capture=false`)

Phase 249 changed the job, state, scenario, source/proof, and brand-reference maps plus demo seed chronology. It did not change runtime UI, brand assets, fonts, colors, or rendering. The scores below judge what this phase delivered against its reference-only contract; they do not measure the rendered product. Existing runtime quality remains unverified here. The runtime `lib/` and `priv/` paths are unchanged from the preimplementation baseline `0d689025`.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Existing wording is preserved and mapped; the known Redaction empty-state copy issue is explicitly deferred to Phases 251/253. |
| 2. Visuals | 2/4 | No rendered capture was authorized; the known drawer/title overlap remains unresolved and assigned to later acceptance. |
| 3. Color | 3/4 | All eight approved roles and asset consumers are mapped, but runtime color use and rendered contrast are not measured in this phase. |
| 4. Typography | 2/4 | Font sources are mapped only; dense typography and served-font proof remain open for Phases 250/253. |
| 5. Spacing | 2/4 | The spec preserves the existing scale without a rendered spacing check; the known overlap remains open. |
| 6. Experience Design | 3/4 | Route/action/state and access boundaries have source-grounded owners and passing mapping contracts, but no fresh live interaction result is claimed. |

**Overall: 15/24**

These are phase-contract scores. The low visual scores reflect missing rendered evidence and known carried issues, not a regression introduced by Phase 249.

---

## Top 3 Priority Fixes

1. **Resolve the drawer/title overlap** — It can obscure the inspection context; Phase 251 should inspect the current layout and adjust the shared drawer/header layout, with Phase 253 checking the whole flow at supported viewports. The carry entry is at `operator-journey-inventory.json:2077`.
2. **Address dense typography during role migration** — Dense data can slow scanning; Phase 250 should map the approved font roles and verify actual served fonts and rendered text density, with package-wide acceptance in Phase 253. See `operator-journey-inventory.json:2100`.
3. **Rewrite the Redaction empty-state guidance** — The current wording is a known gap; Phase 251 should provide a clear next step and Phase 253 should check it in context. See `operator-journey-inventory.json:2123`.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** The contract correctly avoids inventing new CTA or empty-state copy and maps current route/state owners (`249-UI-SPEC.md:71`, `249-UI-SPEC.md:83`). The Redaction empty-state wording remains a known unresolved issue, with no Phase 249 copy change or rendered proof; it is explicitly assigned to Phases 251/253 (`operator-journey-inventory.json:2123`, `operator-journey-inventory.json:2143`).
- The inventory keeps product language, domain meaning, and proof limitations separate. Its test owner establishes reference structure only, not an approved-brand copy review (`operator-journey-inventory.json:754`).

### Pillar 2: Visuals (2/4)

- **WARNING:** No screenshot or rendered inspection was authorized, so hierarchy, clipping, responsive layout, and icon treatment cannot be scored from visual evidence.
- The known drawer/title overlap is retained as historical feedback awaiting a reviewed current rendering; it has no current rendered proof reference (`operator-journey-inventory.json:2077`, `operator-journey-inventory.json:2097`). This is not a fresh reproduction.
- The UI spec accurately limits itself to the existing production components and reserves fresh rendered acceptance for later phases (`249-UI-SPEC.md:12`, `249-UI-SPEC.md:117`).

### Pillar 3: Color (3/4)

- **WARNING:** The map references the approved role IDs and asset sources without copying token values, hashes, or contrast ratios. It names consumers, proof gaps, and later owners (`249-UI-SPEC.md:60`, `249-UI-SPEC.md:117`, `operator-journey-inventory.json:754`).
- Runtime role-to-token mapping and rendered theme/contrast behavior remain unmeasured by contract and are assigned to Phase 250 and complete acceptance in Phase 253 (`249-UI-SPEC.md:67`, `operator-journey-inventory.json:1176`). This score does not assert that the current palette passes or fails contrast.

### Pillar 4: Typography (2/4)

- **WARNING:** The approved font files and consumers are mapped, but the phase makes no font-size, weight, line-height, or served-font claim (`249-UI-SPEC.md:49`, `249-UI-SPEC.md:127`).
- Dense typography remains an open carry item, and the inventory explicitly says served-font/rendered proof is future work (`operator-journey-inventory.json:2100`, `operator-journey-inventory.json:2120`).

### Pillar 5: Spacing (2/4)

- **WARNING:** The spec declares only “existing runtime scale” and adds no values. No current spacing classes or rendered viewport geometry were measured (`249-UI-SPEC.md:41`).
- The outstanding drawer/title overlap is the only concrete layout defect retained in this phase record; its current state is unverified and later-owned (`operator-journey-inventory.json:2077`). No Phase 249 spacing regression was found because runtime UI files did not change.

### Pillar 6: Experience Design (3/4)

- **WARNING:** The semantic inventory covers eleven LiveViews and five HTTP declarations, with route-specific actions, states, access facts, and proof owners. Its 30-test Node receipt and independent mapping review establish declaration/reference correctness, not mounted behavior (`249-01-SUMMARY.md`, `249-MAPPING-REVIEW.md`).
- The inventory distinguishes ordinary and stress selections, uses source-grounded state dispositions, and preserves degraded Timeline as a state rather than a route (`operator-journey-inventory.json:2171`, `operator-journey-inventory.json:2249`).
- No browser, accessibility, visual, hosted, or human-comprehension acceptance is claimed. Existing proof references are owners; focused receipts remain local and limited (`249-VALIDATION.md`, `249-MAPPING-REVIEW.md`).

---

## Files Audited

- `.planning/conventions/research-verification-and-efficiency.md`
- `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-01-PLAN.md` through `249-04-PLAN.md`
- `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-01-SUMMARY.md` through `249-04-SUMMARY.md`
- `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-UI-SPEC.md`
- `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-CONTEXT.md`
- `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-MAPPING-REVIEW.md`
- `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-VALIDATION.md`
- `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-WAVE3-RECEIPT.json`
- `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-FINAL-AFFECTED-RECEIPT.json`
- `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json`
- `brand/BRAND.md`
- `brand/brand.json`
- `brand/assets/README.md`

No tests were rerun: the final focused receipts and source-bound mapping review were reused because their reviewed source identity is unchanged. No screenshots were created, so the screenshot gitignore gate was not needed.
