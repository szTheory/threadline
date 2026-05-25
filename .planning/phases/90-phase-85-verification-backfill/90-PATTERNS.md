# Phase 90: Phase 85 Verification Backfill - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/85-support-lane-surface-audit/85-VERIFICATION.md` | verification artifact | transform | `.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md` | role-match |
| `.planning/phases/85-support-lane-surface-audit/85-VALIDATION.md` | validation artifact | transform | `.planning/phases/89-contract-lock-final-verification/89-VALIDATION.md` | role-match |
| `.planning/REQUIREMENTS.md` | planning authority | transform | `.planning/REQUIREMENTS.md` updates from Phase 74 / Phase 80 closeout | exact |
| `.planning/ROADMAP.md` | planning authority | transform | `.planning/ROADMAP.md` updates from Phase 74 / Phase 80 closeout | exact |
| `.planning/STATE.md` | planning authority | transform | `.planning/STATE.md` updates from Phase 74 / Phase 80 closeout | exact |
| `guides/upgrade-path.md` | guide | transform | `guides/upgrade-path.md` | exact |
| `guides/operator-surface.md` | guide | request-response | `guides/operator-surface.md` | exact |
| `guides/getting-started-saas.md` | guide | request-response | `guides/getting-started-saas.md` | exact |
| `guides/integration-contracts.md` | guide | request-response | `guides/integration-contracts.md` | exact |
| `examples/threadline_phoenix/README.md` | guide | request-response | `examples/threadline_phoenix/README.md` | exact |
| `test/threadline/operator_surface/auth_test.exs` | contract test | request-response | `test/threadline/operator_surface/auth_test.exs` | exact |
| `test/threadline/operator_surface/export_auth_plug_test.exs` | contract test | request-response | `test/threadline/operator_surface/export_auth_plug_test.exs` | exact |

## Pattern Assignments

### `.planning/phases/85-support-lane-surface-audit/85-VERIFICATION.md`

**Analog:** `.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md`

Use the same final-tree verification structure:

- frontmatter with `verified`, `status`, and score-style summary,
- one section per truth band,
- explicit commands-run list,
- plain-language gaps summary that names remaining follow-up without hiding it.

For Phase 85, the truth bands should be narrower:

1. public support-lane claim boundary,
2. shared callback contract across LiveView and HTTP export,
3. minimal additive controls and example-host proof.

### `.planning/phases/85-support-lane-surface-audit/85-VALIDATION.md`

**Analog:** `.planning/phases/89-contract-lock-final-verification/89-VALIDATION.md`

Use the modern Nyquist shape:

- frontmatter with `phase`, `slug`, `status`, `nyquist_compliant`, and timestamps,
- test infrastructure table,
- sampling-rate section,
- per-task verification map with explicit commands,
- commands-actually-used section after execution,
- validation sign-off that names whether the phase is finalized.

### `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`

**Analog:** `.planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-02-PLAN.md` and `.planning/phases/80-governance-verification-and-milestone-surface-repair/80-VALIDATION.md`

Follow the closeout-bookkeeping pattern:

- mark only the requirements actually closed by the phase,
- mark only the specific plan checklist items completed,
- update state counts and next-step messaging without claiming unrelated phase
  closure,
- keep the milestone surface internally consistent across all three files.

### `guides/upgrade-path.md`

**Analog:** `guides/upgrade-path.md`

Preserve the lane-taxonomy pattern:

- `supported`, `reference`, and `unclaimed` remain the operative vocabulary,
- root-lane proof and example-lane proof stay distinct,
- row-history/as-of claim language must stay literal and current-tree truthful.

### `guides/operator-surface.md`, `guides/getting-started-saas.md`, `guides/integration-contracts.md`, `examples/threadline_phoenix/README.md`

**Analog:** exact-file pattern plus Phase 89 contract-lock usage

Preserve these shared patterns:

- one host-owned `/audit` mount,
- `authorize_fn` as the primary seam,
- `scope_query_fn` for scoped reads,
- `export_authorize_fn` for explicit export override,
- no Threadline-owned role or tenancy DSL language.

### `test/threadline/operator_surface/auth_test.exs`

**Analog:** exact file

Key proof pattern:

- attach telemetry handlers in `setup`,
- verify granted / denied / error outcomes explicitly,
- prove support scopes remain opaque host-owned maps,
- keep the shared `%{assigns: assigns}` callback shape literal in the test body.

### `test/threadline/operator_surface/export_auth_plug_test.exs`

**Analog:** exact file

Key proof pattern:

- prove HTTP export uses `export_authorize_fn` when present,
- otherwise prove fallback to the synthetic `%{assigns: conn.assigns}` mirror,
- assert `403` denial and telemetry outcomes literally,
- keep the mirror non-`%Plug.Conn{}` assertion intact.

## Metadata

**Reference phases:** 74, 80, 89
**Primary proof surfaces:** Phase 85 context/summaries, Phase 89 verification, v1.21 milestone audit
