# Phase 95: Evidence Model Lock And Scope Guard - Research

**Researched:** 2026-05-25
**Domain:** append-only evidence primitives, governance-schema fit, and boundary-lock posture
**Confidence:** HIGH

## Summary

Phase 95 should establish one boring, durable evidence primitive before any API,
CLI, or mounted-surface expansion. The current repo already contains the owned
facts that make this viable:

- governance tables for retention runs, export jobs, and saved views
- machine-readable policy/coverage posture surfaces
- a strongly defended host-owned auth/scope boundary on `/audit`

What is missing is the unified evidence record that snapshots those facts
consistently and says, in code and docs, which subjects Threadline will not
pretend to own.

**Primary recommendation:** add a new append-only governance table and schema
for evidence records, pair it with an explicit supported-subject inventory plus
boundary validator, and lock the negative claims with tests and narrow doc
contract updates. Do not add public APIs or mounted views in this phase.

## Architectural Responsibility Map

| Concern | Primary tier | Secondary tier | Rationale |
|--------|---------------|----------------|-----------|
| Durable evidence row contract | `Threadline.Governance.EvidenceRecord` | `Threadline.Governance.Migration` | Stable persistence contract belongs beside the other governance schemas. |
| Supported subject inventory | `Threadline.Evidence.Subject` | tests/docs | The subject list is a product boundary, not incidental runtime behavior. |
| Append-only semantics | changeset + persistence tests | migration indexes/constraints | The phase must prevent update-in-place posture drift from becoming the default shape. |
| Host-owned boundary lock | validator + doc-contract tests | guides | Unsupported subjects need explicit, testable denial. |
| API/CLI/UI exposure | later phases | N/A | Phase 95 should not overreach into later milestone surfaces. |

## Current Tree Findings

### Verified strengths

- `lib/threadline/governance/migration.ex` and `Mix.Tasks.Threadline.Install`
  already provide a clear adoption path for new governance tables.
- `Retention.purge/1` writes durable retention-run records today, which proves
  the repo is comfortable persisting governance facts distinct from audit rows.
- `Threadline.Policy.RedactionPresenter` and `Threadline.Health.Policy` show
  two useful patterns for the evidence plane:
  machine-readable posture output and strict bounded validation.
- The host-owned auth/tenancy boundary is repeated across the milestone arc,
  docs, and prior planning artifacts; Phase 95 can lock evidence scope without
  reopening that argument.

### Verified gaps

- There is no single evidence row contract that can represent redaction,
  coverage, retention, export, and support-lane posture consistently.
- Existing governance rows are purpose-specific and mutable enough that they
  should not double as the evidence ledger.
- No current module explicitly denies host-owned or compliance-platform
  subjects such as role models, tenant semantics, approvals, legal hold, or
  vendor report packs.
- Current docs explain what Threadline is not, but they do not yet bind that
  non-goal language to the new evidence-plane contract.

## Recommended Runtime Shape

### Pattern 1: Add one new governance table instead of overloading old ones

The cleanest contract is a dedicated `threadline_evidence_records` table plus
`Threadline.Governance.EvidenceRecord`. Reusing `threadline_export_jobs` or
`threadline_retention_runs` as the evidence ledger would mix operational state
with evidence snapshots and make future API/CLI parity harder to reason about.

Recommended fields:

- `id` UUID
- `subject` text
- `subject_ref` JSONB
- `summary_status` text
- `recorded_at` timestamptz
- `actor_ref` JSONB nullable
- `provenance` JSONB
- `detail` JSONB
- `schema_version` integer
- `inserted_at` timestamptz

Avoid `updated_at` semantics that imply evidence rows are meant to mutate into a
new truth. New posture should produce new rows.

### Pattern 2: Make the subject inventory explicit and closed

Phase 95 should define the allowed subject families directly. The repo-fit list
is narrow and already evidenced by owned modules/tests:

- `redaction_policy`
- `trigger_coverage`
- `retention_run`
- `retention_policy`
- `export_delivery`
- `support_scope_posture`

The exact names can vary, but the set should stay narrow and Threadline-owned.
The validator should explicitly reject categories such as:

- `rbac_policy`
- `tenant_membership`
- `approval_workflow`
- `legal_hold`
- `vendor_report_pack`

### Pattern 3: Keep boundary meaning host-owned even when evidence mentions support posture

Support-lane evidence is valid only when it speaks about Threadline's own seam
behavior, such as:

- whether scoped reads were the active contract
- whether export denial remained separate
- what mounted surfaces are proven or unsupported

It must not capture business roles, customer tenancy semantics, or approval
state as if those were library-owned truths.

### Pattern 4: Lock negative claims in code and docs now

Relying on milestone memory is too weak. The phase should update at least one
canonical product-boundary doc and corresponding contract test so later phases
cannot drift into "compliance platform" language accidentally.

### Pattern 5: Defer public API and surface parity intentionally

The milestone ordering in `ROADMAP.md` is correct:

1. Phase 95 locks the record contract and non-goal boundary.
2. Phase 96 builds persistence/create-read flows on that contract.
3. Phase 97 shapes machine-readable proof output.
4. Phase 98 mounts read-only `/audit` views.
5. Phase 99 locks public claims and final verification.

## Common Pitfalls

### Pitfall 1: Reusing mutable operational rows as the evidence ledger

That blurs "current runtime state" with "historical evidence snapshot" and
makes append-only semantics easy to violate.

### Pitfall 2: Letting the subject list become an escape hatch

If the record contract accepts arbitrary host-policy subjects, Phase 95 silently
turns Threadline into a platform-expansion lane and breaks `EVID-03`.

### Pitfall 3: Using `updated_at` or upsert-first flows as the default posture

Evidence records should accumulate snapshots. New posture means a new insert.

### Pitfall 4: Over-documenting end-user evidence flows in this phase

Public API, Mix-task UX, and mounted navigation are later-phase concerns. Phase
95 should not leak future surface details into its core-model work.

### Pitfall 5: Talking about "support evidence" as though Threadline owns auth

The supported claim is about Threadline's seams and mounted proof posture, not
about who a customer considers an admin or support actor.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Targeted ExUnit schema, migration-install, boundary-validator, and doc-contract tests |
| Quick run | `mix test test/threadline/governance/evidence_record_test.exs test/threadline/evidence/subject_test.exs test/threadline/how_threadline_works_doc_contract_test.exs --max-failures 1` |
| Phase gate | `mix test test/threadline/governance/evidence_record_test.exs test/threadline/evidence/subject_test.exs test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs --max-failures 1` |

### Requirement Map

| Req ID | Truth to prove | Expected evidence |
|--------|----------------|-------------------|
| EVID-01 | Threadline has a durable append-only evidence record for owned governance facts. | migration + schema tests |
| EVID-02 | The record captures subject, timestamp, actor/provenance, summary status, and machine-readable detail. | changeset + contract tests |
| EVID-03 | Unsupported host-owned/compliance-platform subjects are rejected and docs repeat the non-goal boundary honestly. | validator tests + doc-contract tests |

## Sources

### Primary

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/research/v1.22-policy-evidence-plane.md`
- `.planning/research/v1.21-option-3-policy-compliance-shape.md`
- `lib/mix/tasks/threadline.install.ex`
- `lib/threadline/governance/migration.ex`
- `lib/threadline/governance/export_job.ex`
- `lib/threadline/governance/retention_run.ex`
- `lib/threadline/governance/saved_view.ex`
- `lib/threadline/retention.ex`
- `lib/threadline/policy/redaction_presenter.ex`
- `lib/threadline/health/policy.ex`
- `guides/how-threadline-works.md`
- `guides/integration-contracts.md`
- `guides/operator-surface.md`
- `test/threadline/retention_test.exs`
- `test/threadline/health/policy_test.exs`
- `test/threadline/how_threadline_works_doc_contract_test.exs`
- `test/threadline/integration_contracts_doc_contract_test.exs`
- `test/threadline/operator_surface/policy_show_mix_test.exs`
- `test/threadline/operator_surface/live/policy_redaction_live_test.exs`

## RESEARCH COMPLETE
