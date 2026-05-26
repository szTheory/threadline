# Phase 98: Mounted Evidence Views On `/audit` - Research

**Researched:** 2026-05-26
**Domain:** mounted LiveView evidence presentation, `/audit` route fit, proof parity, and host-owned capability gating
**Confidence:** HIGH

## Summary

Phase 97 already shipped the core no-Phoenix evidence proof path:
`Threadline.Evidence`, `Threadline.Evidence.Proof`, and
`mix threadline.evidence.show`. Phase 98 should therefore stay narrow. It does
not need a new evidence query model, a new proof vocabulary, or a new operator
surface family. It needs one truthful mounted read-only page at
`/audit/evidence` that:

- answers “what can Threadline prove right now?” using the existing latest
  overview semantics
- allows bounded subject/history drill-down on the same route family
- reuses the existing `/audit` URL-as-state and unsupported-view patterns
- stays behind explicit host-owned authorization instead of inheriting broad
  timeline visibility

**Primary recommendation:** add one `EvidenceLive` page under the existing
router, back it with the current `Threadline.Evidence` and
`Threadline.Evidence.Proof` helpers, and wire a dedicated evidence capability
gate that fails closed to an explicit unsupported state with CLI fallback.

## Architectural Responsibility Map

| Concern | Primary tier | Secondary tier | Rationale |
|--------|---------------|----------------|-----------|
| Mounted route and capability option | `Threadline.OperatorSurface.Router` | `Threadline.OperatorSurface.Auth` | `/audit` siblings and capability booleans already live here. |
| Mounted state + URL handling | `Threadline.OperatorSurface.Live.EvidenceLive` | `Threadline.OperatorSurface.Components.SurfaceHeader` | Existing LiveViews own `handle_params/3`, `base_path`, and mounted navigation. |
| Read-side evidence data | `Threadline.Evidence` | `Threadline.Evidence.Proof` | Phase 98 must consume existing overview/latest/history helpers rather than inventing task-local or LV-local queries. |
| Unsupported fallback copy | `Threadline.OperatorSurface.Unsupported` | `UnsupportedView` component | Current coverage/policy surfaces centralize truthful fallback copy here. |
| Mounted/API/CLI parity lock | shared presenter/proof mapping tests | Mix task + LiveView tests | Phase 98 must prove the mounted page preserves Phase 97 verdict language and boundary semantics. |

## Current Tree Findings

### Verified strengths

- `lib/threadline/evidence.ex` already exposes the exact mounted read model
  Phase 98 needs: `list_overview/2`, `list_latest_subject_refs/3`,
  `get_latest_subject_ref/3`, and `list_subject_ref_history/4`.
- `lib/threadline/evidence/proof.ex` already wraps evidence reads in the
  milestone’s canonical proof vocabulary: `proven`, `inferred_posture`, and
  `unsupported`.
- `lib/threadline/operator_surface/router.ex` already uses the “one canonical
  sibling page inside `/audit`” mount pattern for coverage, exports, and policy
  surfaces.
- `lib/threadline/operator_surface/auth.ex` already computes fail-closed
  capability booleans (`threadline_coverage_enabled`,
  `threadline_policy_enabled`) from host-owned callbacks.
- `CoverageLive`, `PolicyRedactionLive`, and `RetentionHistoryLive` already
  prove the two UI postures Phase 98 needs: read-only grouped status views and
  explicit unsupported-state fallbacks.

### Verified gaps

- No `/audit/evidence` route exists today.
- No operator-surface capability or callback exists for evidence views.
- No mounted presenter/view-model exists for turning proof rows into overview
  groups, latest summaries, and history drill-downs.
- `SurfaceHeader` has no evidence badge/link today, so the new view would be an
  orphan unless navigation is extended.
- There is no mounted parity test proving the LiveView preserves the same proof
  facts and boundary wording as the CLI/API paths.

## Recommended Runtime Shape

### Pattern 1: One canonical mounted landing page

Add one route at `/audit/evidence` inside the existing `threadline_operator_surface/2`
scope. Do not spread evidence state across coverage, retention, redaction, or
export pages. Those pages can deep-link into evidence later, but `/audit/evidence`
should remain the canonical entry for the proof question.

Recommended URL shape:

- `/audit/evidence` -> overview across the fixed subject inventory
- `/audit/evidence?subject=retention_run` -> latest rows for one subject family
- `/audit/evidence?subject=retention_run&subject_ref_json=...&mode=history` ->
  append-only history for one subject reference

This matches the repo’s route-driven state pattern from `TimelineLive` and keeps
state shareable without page-local reducer logic.

### Pattern 2: Overview-first default, history as explicit drill-down

Use `Threadline.Evidence.list_overview/2` or `Threadline.Evidence.Proof` as the
default landing read. This is already the strongest answer to the operator
question “what can Threadline prove right now?” and aligns the mounted view with
Phase 97 instead of creating a history-first analyst console.

History should remain available, but only after a subject or subject-ref
selection. The mounted page must label `latest` as a projection over append-only
history, not a mutable current state.

### Pattern 3: Thin LiveView over evidence APIs, not a second query model

The LiveView should call the existing evidence APIs and only own:

- parsing URL params
- choosing overview/latest/history mode
- grouping records for scanability
- rendering fallback/empty/error states

It should not query `Threadline.Governance.EvidenceRecord` directly, build its
own SQL, or duplicate proof classification heuristics locally.

### Pattern 4: Dedicated evidence capability gate, fail closed

Phase 98 should not inherit broad timeline access by accident. The evidence
surface is closer to coverage/policy than to the timeline, so it should follow
the explicit capability pattern:

- router option such as `:evidence_authorize_fn`
- auth assign such as `:threadline_evidence_enabled`
- LiveView checks that render unsupported state when denied

This keeps the boundary host-owned and testable without introducing
Threadline-owned RBAC or tenant semantics.

### Pattern 5: Shared parity seam for verdict labels and unsupported language

Mounted parity should not mean rendering the raw proof JSON document into the
page. It should mean one shared semantic seam for:

- verdict labels (`proven`, `inferred_posture`, `unsupported`)
- subject identity and recorded-at display
- unsupported-state wording and CLI fallback

The likely clean seam is a small shared presenter/view-model module that both
`EvidenceLive` and `Mix.Tasks.Threadline.Evidence.Show` can consume, with
`Threadline.Evidence.Proof` remaining the machine-contract layer.

## Common Pitfalls

### Pitfall 1: Query drift inside the LiveView

If `EvidenceLive` directly queries `threadline_evidence_records`, Phase 98
creates a second truth surface and breaks `SURF-02`.

### Pitfall 2: Silent denial by route omission

Hiding the route or badge when evidence access is denied weakens the host-owned
boundary claim. Coverage and policy already prove the better pattern: render an
explicit unsupported state with fallback guidance.

### Pitfall 3: Treating history as the default mounted experience

That would pull `/audit` toward an evidence-analysis console and away from the
locked overview-first operator question.

### Pitfall 4: Coupling evidence auth to broad timeline auth accidentally

Support-safe sessions can be allowed on the main timeline while still being
truthfully denied mounted evidence. The code should preserve that distinction.

### Pitfall 5: Raw proof-envelope dumping

Fields such as `format_version` and `proof_type` belong to the machine contract,
not primary UI chrome. The mounted page should translate, not mirror, the proof
document.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix LiveView tests + operator-surface auth tests |
| Quick run | `MIX_ENV=test mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` |
| Phase gate | `mix verify.test` |

### Requirement Map

| Req ID | Truth to prove | Expected evidence |
|--------|----------------|-------------------|
| SURF-01 | Evidence views live on existing `/audit` surface. | router + LiveView tests proving `/audit/evidence` mount |
| SURF-02 | Mounted view preserves the same facts and boundary language as API/CLI paths. | parity tests around verdict labels, subject coverage, unsupported fallback, and shared presenter/proof seam |
| SURF-03 | Host-owned authorization remains the gate. | auth/router tests + unsupported-state mounted tests |

## Sources

### Primary

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md`
- `.planning/phases/98-mounted-evidence-views-on-audit/98-UI-SPEC.md`
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-CONTEXT.md`
- `.planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md`
- `.planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md`
- `guides/operator-surface.md`
- `guides/domain-reference.md`
- `lib/threadline/evidence.ex`
- `lib/threadline/evidence/proof.ex`
- `lib/mix/tasks/threadline.evidence.show.ex`
- `lib/threadline/operator_surface/router.ex`
- `lib/threadline/operator_surface/auth.ex`
- `lib/threadline/operator_surface/unsupported.ex`
- `lib/threadline/operator_surface/components/unsupported_view.ex`
- `lib/threadline/operator_surface/components/surface_header.ex`
- `lib/threadline/operator_surface/live/coverage_live.ex`
- `lib/threadline/operator_surface/live/policy_redaction_live.ex`
- `lib/threadline/operator_surface/live/retention_history_live.ex`
- `lib/threadline/operator_surface/live/timeline_live.ex`
- `test/threadline/operator_surface/auth_test.exs`
- `test/threadline/operator_surface/live/coverage_live_test.exs`
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs`
- `test/threadline/operator_surface/live/retention_history_live_test.exs`
- `test/threadline/operator_surface/router_test.exs`

## RESEARCH COMPLETE
