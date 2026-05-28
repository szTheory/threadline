---
status: passed
phase: 117-evidence-plane-doc-authority
verified: 2026-05-27
score: 3/3
---

# Phase 117 Verification Report

**Phase goal:** Evaluators find evidence-plane documentation without dead links; adopter prose speaks in Hex semver, not internal milestone labels.

## Requirements Verified

| ID | Requirement | Status | Evidence |
|----|-------------|--------|----------|
| DOC-01 | Evidence-plane documentation has a single authoritative entry point — split-guide map with no dead `guides/evidence-plane.md` references | ✓ | `.planning/PROJECT.md` L33 lists `how-threadline-works.md`, `upgrade-path.md`, `domain-reference.md`, `operator-surface.md`; `rg -F 'guides/evidence-plane.md' .planning/PROJECT.md` — no matches; README `## Evidence plane` (L26–40) links to split guides; `semver_adopter_doc_contract_test.exs` refutes phantom hub across adopter band |
| DOC-02 | Adopter-facing prose uses Hex semver vocabulary; internal milestone labels (`v1.2x`) removed from adopter paths | ✓ | `getting-started-saas.md` L87 `### Recommended path (0.6.0+)`; `upgrade-path.md` L5 evaluator sentence, L77 `0.5.x → 0.6.x` bullet; `how-threadline-works.md` L206–213 Evolution semver bullets; `rg 'v1\.2[0-9]' guides/getting-started-saas.md guides/upgrade-path.md` — no matches; `semver_adopter_doc_contract_test.exs` refutes `~r/v1\.2[0-9]/` in README + five adopter guides |
| DOC-03 | `mix verify.doc_contract` green after evidence-plane and semver prose changes | ✓ | `mix verify.doc_contract` — 71 tests, 0 failures; `exploration_routing_doc_contract_test.exs` and `semver_adopter_doc_contract_test.exs` wired in `mix.exs` L81 alias |

**Requirement ID coverage:** Plans 117-01 (DOC-01, DOC-02) and 117-02 (DOC-03) account for all three phase requirement IDs from REQUIREMENTS.md traceability table.

## Plan 01 Must-Haves (Doc authority prose)

| Truth / artifact | Status | Evidence |
|------------------|--------|----------|
| Maintainer PROJECT.md lists real split guides; no phantom hub | ✓ | `.planning/PROJECT.md` L33; `rg -F 'guides/evidence-plane.md' .planning/PROJECT.md` — empty |
| Adopter guides use Hex semver, not `v1.2x` milestone labels | ✓ | `getting-started-saas.md`, `upgrade-path.md` — no `v1.2x` matches |
| `upgrade-path.md` documents `0.5.x → 0.6.x` minor upgrade with Evidence + `Audit.transaction/3` | ✓ | `upgrade-path.md` L77; `rg -F '0.5.x → 0.6.x' guides/upgrade-path.md` — match |
| Incident JSON step 1 describes semantics via `Audit.transaction/3` with `:action` | ✓ | `domain-reference.md` L274; old `record_action/2`-only step 1 prose absent (`rg -n 'after \`Threadline.record_action/2\` links semantics'` — no match) |
| `guides/getting-started-saas.md` recommended-path heading | ✓ | L87 `### Recommended path (0.6.0+)` |

## Plan 02 Must-Haves (Doc-contract locks)

| Truth / artifact | Status | Evidence |
|------------------|--------|----------|
| `mix verify.doc_contract` includes `exploration_routing` and passes | ✓ | `mix.exs` L81; 71/0 green |
| Evolution section chronology: `0.5.0` before `0.6.0` with Evidence + `Audit.transaction/3` | ✓ | `how_threadline_works_doc_contract_test.exs` L90–106; `how-threadline-works.md` L206–213 |
| Adopter-band refute: no `v1.2x`, no phantom hub | ✓ | `semver_adopter_doc_contract_test.exs` L14–20 |
| Incident JSON contract scoped after `COMP-EXAMPLE-INCIDENT-JSON` | ✓ | `exploration_routing_doc_contract_test.exs` L41–48 |

## ROADMAP Success Criteria

| Criterion | Status | Evidence |
|-----------|--------|----------|
| No adopter-facing doc references a missing evidence-plane guide | ✓ | README map + split-guide links; hub refute test across adopter band |
| Adopter paths use Hex semver vocabulary consistently | ✓ | Prose sweep + semver refute contract |
| `mix verify.doc_contract` green | ✓ | 71 tests, 0 failures |

## Automated Checks (2026-05-27)

```text
rg 'v1\.2[0-9]' guides/getting-started-saas.md guides/upgrade-path.md
  → no matches (exit 1)

rg -F 'guides/evidence-plane.md' .planning/PROJECT.md
  → no matches (exit 1)

rg -F '0.5.x → 0.6.x' guides/upgrade-path.md
  → guides/upgrade-path.md:77 match

rg -F 'Threadline.Audit.transaction/3' guides/domain-reference.md
  → guides/domain-reference.md:274 match

mix verify.doc_contract
  → 71 tests, 0 failures (exit 0)
```

## Human Verification

Optional (non-blocking): spot-check `.planning/milestones/**` for stale `@guides/evidence-plane.md` references when those files are next touched — explicitly out of `verify.doc_contract` scope per 117-CONTEXT D-117-01c / D-117-04.

## Gaps

None — all three DOC requirements satisfied with current-tree evidence.
