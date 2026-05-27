# Phase 97: Mix-Task And Machine-Readable Proof - Research

**Researched:** 2026-05-26
**Domain:** Mix-task viewer parity, wrapped machine-readable proof contracts, and truthful unsupported-claim semantics for the evidence plane
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Canonical Mix-task shape

- **D-01:** Ship one canonical evidence viewer under the `threadline.evidence`
  Mix-task namespace.
- **D-02:** Prefer a narrow viewer command such as
  `mix threadline.evidence.show`; do not widen into `threadline.proof` or
  compliance-pack naming.
- **D-03:** The task must stay a thin wrapper over `Threadline.Evidence` read
  helpers; no task-local SQL, reducers, or parallel query model.
- **D-04:** The task is a viewer/exporter, not a CI gate, and successful proof
  inspection should exit `0`.

### Subject coverage and workflow

- **D-05:** Phase 97 must expose the full closed six-subject evidence set:
  `redaction_policy`, `trigger_coverage`, `retention_run`,
  `retention_policy`, `export_delivery`, and `support_scope_posture`.
- **D-06:** Do not ship a narrower starter subset.
- **D-07:** Default workflow should be overview-first.
- **D-08:** Drill-down should happen through bounded filters, not extra tasks:
  `--subject`, explicit subject-ref input, `--latest` / `--history`, `--from`,
  `--to`, and `--limit`.
- **D-09:** `latest` remains a projection over append-only history, not a new
  mutable state contract.

### Machine-readable JSON contract

- **D-10:** `--json` must emit one canonical wrapped proof document.
- **D-11:** The wrapper should be versioned and jq-friendly with top-level keys
  `format_version`, `generated_at`, `proof_type`, `subject`, `mode`,
  `filters`, `summary`, `claim_assessment`, and `records`.
- **D-12:** `records` should stay close to the stable evidence row shape
  already implied by `Threadline.Evidence` and
  `Threadline.Governance.EvidenceRecord`.
- **D-13:** JSON keys must stay stable and additive: snake_case keys,
  machine-stable enums, ISO-8601 UTC timestamps, arrays instead of
  shape-switching maps, and string-keyed nested maps.
- **D-14:** Human output, machine JSON, and future mounted UI serialization are
  separate surfaces.
- **D-15:** NDJSON may arrive later as an additive mode, but not as the
  primary Phase 97 contract.

### Proof-language boundary

- **D-16:** Successful proof outputs must classify claims as `proven`,
  `inferred_posture`, or `unsupported`.
- **D-17:** Error outcomes stay separate: `invalid_request` and
  `runtime_failure`.
- **D-18:** `proven` is only for Threadline-owned evidence or deterministic
  derivations over that evidence.
- **D-19:** `inferred_posture` may summarize owned facts or posture snapshots,
  but cannot overclaim host-owned behavior.
- **D-20:** `unsupported` means Threadline does not claim authority here, not
  false and not operational failure.
- **D-21:** Unsupported claims must be explicit in the payload.
- **D-22:** Negative evidence Threadline does own is still `proven`.

### Boundary discipline and DX

- **D-23:** Keep proof semantics in the payload, not in marketing-style command
  names.
- **D-24:** Do not infer provenance, actor meaning, auth meaning, or claim
  semantics from ambient runtime context.
- **D-25:** Mix-task ergonomics should follow existing Threadline viewer
  patterns: human-readable default, explicit `--json`, bounded flags, and no
  hidden shape-switching.
- **D-26:** Prefer discoverable `@shortdoc`, `@moduledoc`, and current repo
  bootstrap behavior for viewer commands.

### Recommendation-first closure

- **D-27:** Research already converged on one architecture: one canonical
  viewer task, full subject parity, wrapped versioned JSON, and layered
  proof-language semantics.

### Deferred Ideas (OUT OF SCOPE)

- A separate CI-gate task such as `threadline.evidence.verify`
- Mounted `/audit` evidence UI work (Phase 98)
- Compliance-pack generation, host-policy verification, or broad attestation
  products
- NDJSON proof output as the primary contract
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-02 | Mix-task parity exists for the milestone's evidence subjects, including stable machine-readable output for CI, procurement, or audit handoff. [VERIFIED: .planning/REQUIREMENTS.md] | One namespaced viewer task can reuse `Threadline.Evidence` latest/history helpers for all six subjects and emit one wrapped JSON document modeled after the existing export contract. [VERIFIED: .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md, lib/threadline/evidence.ex, lib/mix/tasks/threadline.policy.show.ex, lib/mix/tasks/threadline.export.ex] |
| PROOF-03 | Evidence outputs clearly distinguish proven facts, inferred posture, and unsupported claims. [VERIFIED: .planning/REQUIREMENTS.md] | A dedicated proof-serialization layer should derive explicit `claim_assessment` fields from evidence subject + detail/status semantics and keep unsupported claims as valid payloads instead of failures. [VERIFIED: .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md, lib/threadline/evidence/subject.ex, guides/integration-contracts.md, guides/how-threadline-works.md] |
</phase_requirements>

## Summary

Phase 96 already landed the public append-only evidence API in
`Threadline.Evidence`, including generic history reads plus explicit latest
projections for each subject family. Phase 97 should build on that truth
surface rather than inventing a second query model inside a Mix task.
[VERIFIED: lib/threadline/evidence.ex, .planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md]

The strongest local viewer pattern is consistent across
`threadline.health.coverage`, `threadline.policy.show`, `threadline.incident`,
and `threadline.export`: load app config, start the configured repo, keep the
task thin, render human output by default, and expose one explicit machine
format behind `--json`. `threadline.export` is the closest precedent for the
wrapped, versioned JSON envelope because it already locks `format_version` and
`generated_at` as stable top-level machine fields.
[VERIFIED: lib/mix/tasks/threadline.health.coverage.ex, lib/mix/tasks/threadline.policy.show.ex, lib/mix/tasks/threadline.incident.ex, lib/mix/tasks/threadline.export.ex, test/threadline/export_test.exs]

**Primary recommendation:** introduce one new thin task
`Mix.Tasks.Threadline.Evidence.Show` plus one library module dedicated to
proof-oriented projection and serialization. The library module should accept a
bounded filter set, reuse `Threadline.Evidence.list_latest_subject_refs/3`,
`list_subject_ref_history/4`, and `list_history/2`, then build one wrapped
proof document with explicit `claim_assessment` semantics. That keeps task
bootstrap, filtering, and rendering separate from semantic proof shaping while
preserving the append-only source of truth.
[VERIFIED: .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md, lib/threadline/evidence.ex, lib/mix/tasks/threadline.export.ex]

## Project Constraints (from CLAUDE.md)

- Keep capture, semantics, and exploration/operations responsibilities
  separate; Phase 97 belongs in the exploration/operations layer and must not
  reopen host auth or compliance-platform scope. [VERIFIED: CLAUDE.md]
- Prefer named verification entrypoints such as `mix verify.test` and
  `mix ci.all` over ad-hoc verification commands in final plan guidance.
  [VERIFIED: CLAUDE.md, mix.exs]
- Preserve the product boundary: Threadline is not a SIEM, not an auth
  library, not a tenancy DSL, and not a generic compliance platform.
  [VERIFIED: CLAUDE.md, .planning/MILESTONE-ARC.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CLI task bootstrap and argv parsing | API / Backend | — | The Mix task should own help text, option parsing, repo startup, and shell rendering only. [VERIFIED: lib/mix/tasks/threadline.policy.show.ex, lib/mix/tasks/threadline.health.coverage.ex] |
| Evidence proof projection | API / Backend | Database / Storage | Proof shaping belongs in a reusable library module that reads through `Threadline.Evidence`, not in shell-printing code. [VERIFIED: lib/threadline/evidence.ex, lib/mix/tasks/threadline.export.ex] |
| Claim verdict classification | API / Backend | Docs / Contract | `proven`, `inferred_posture`, and `unsupported` are product semantics that need explicit code and tests, not prose-only interpretation. [VERIFIED: .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md, .planning/REQUIREMENTS.md] |
| Wrapped machine-readable JSON | API / Backend | Docs / Contract | The export module already proves Threadline’s wrapped JSON style; Phase 97 should reuse that contract shape with evidence-specific fields. [VERIFIED: lib/threadline/export.ex, test/threadline/export_test.exs] |
| Future mounted parity | Docs / Contract | API / Backend | Phase 98 should be able to reuse the same proof vocabulary and JSON semantics without redefining them. [VERIFIED: .planning/ROADMAP.md, .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Mix task runtime and proof serializer implementation. | Existing task surfaces and project verification are already built around it. [VERIFIED: mix.exs, CLAUDE.md] |
| Ecto | 3.13.5 | Access to append-only evidence rows through the existing public API. | Phase 97 should reuse `Threadline.Evidence`, not bypass it. [VERIFIED: lib/threadline/evidence.ex, mix.lock] |
| Jason | current lockfile version | JSON encoding for the wrapped proof document. | Existing export and task code already use it for stable machine output. [VERIFIED: lib/threadline/export.ex, lib/mix/tasks/threadline.incident.ex, mix.lock] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit | bundled | Task and serializer verification. | Use for wrapped JSON shape, verdict semantics, and CLI output/exit behavior. [VERIFIED: test/mix/tasks/threadline.export_test.exs, test/threadline/export_test.exs] |
| Phoenix / LiveView | optional | Not required for Phase 97 runtime. | Keep Phase 97 Phoenix-optional so mounted parity can consume the same library later. [VERIFIED: .planning/ROADMAP.md, mix.exs] |

## Architecture Patterns

### Pattern 1: Thin Mix task over a reusable library projection

**What:** Keep `Mix.Tasks.Threadline.Evidence.Show` responsible only for argv,
repo startup, and rendering, while a library module builds the proof document
and overview/history projections.
[VERIFIED: lib/mix/tasks/threadline.policy.show.ex, lib/mix/tasks/threadline.export.ex]

**When to use:** Use for every human and JSON output path in Phase 97 so the
future mounted surface can reuse the same proof semantics.
[VERIFIED: .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md]

**Recommended structure:**

```text
lib/
├── mix/tasks/threadline.evidence.show.ex
├── threadline/evidence.ex
└── threadline/evidence/proof.ex
```

`Threadline.Evidence.Proof` is a recommendation, not a locked module name, but
Phase 97 needs a reusable library seam equivalent to how `Threadline.Export`
keeps document shaping out of its Mix task.
[ASSUMED]

### Pattern 2: Overview-first default with bounded drill-down filters

**What:** Default to latest-per-subject overview across the full six-subject
inventory, then allow narrowing by `--subject`, explicit subject-ref JSON,
`--history`, `--from`, `--to`, and `--limit`.
[VERIFIED: .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md, lib/threadline/evidence.ex]

**Why this fits the repo:** Existing tasks prefer small bounded option
vocabularies with explicit validation rather than free-form query DSLs.
[VERIFIED: lib/mix/tasks/threadline.export.ex, lib/mix/tasks/threadline.health.coverage.ex, lib/threadline/evidence.ex]

### Pattern 3: Wrapped JSON with additive top-level fields

**What:** Emit a stable top-level object containing version and provenance
fields (`format_version`, `generated_at`) plus evidence-specific proof fields
(`proof_type`, `subject`, `mode`, `filters`, `summary`, `claim_assessment`,
`records`).
[VERIFIED: .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md, lib/threadline/export.ex]

**Why this fits the repo:** Export JSON already uses wrapped documents for
machine-readable downstream consumption and reserves NDJSON for additive
streaming, which matches the locked Phase 97 decision set.
[VERIFIED: lib/threadline/export.ex, test/threadline/export_test.exs, guides/domain-reference.md]

### Pattern 4: Separate semantic proof verdicts from operational errors

**What:** Model `proven`, `inferred_posture`, and `unsupported` inside payload
data, while treating invalid flags or runtime failures as separate errors.
[VERIFIED: .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md]

**Why this matters:** `unsupported` is a truthful, machine-readable answer, not
an exception path; collapsing it into runtime failure would violate `PROOF-03`.
[VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md]

## Pitfalls

1. **Task-local query drift.** If the Mix task directly queries
   `threadline_evidence_records`, Phase 97 creates a second truth surface and
   breaks the locked “thin wrapper” rule. Reuse `Threadline.Evidence`.
   [VERIFIED: .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md, lib/threadline/evidence.ex]
2. **Per-subject task sprawl.** Multiple subject-specific tasks would fight the
   overview-first requirement and create contract fragmentation.
   [VERIFIED: .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md]
3. **Shape-switching JSON.** Returning a bare array for one mode and an object
   for another would contradict the existing wrapped JSON precedent and make
   downstream `jq` usage brittle. [VERIFIED: lib/threadline/export.ex, guides/domain-reference.md]
4. **Overclaiming unsupported territory.** Host-owned auth, tenancy, or
   external policy guarantees must surface as `unsupported` or
   `inferred_posture`, not `proven`. [VERIFIED: guides/integration-contracts.md, guides/how-threadline-works.md, .planning/MILESTONE-ARC.md]
5. **Conflating viewer and gate semantics.** The task should exit `0` on valid
   proof inspection even when the result contains weak or unsupported claims;
   a future verifier task can turn those semantics into gates. [VERIFIED: .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md, lib/mix/tasks/threadline.health.coverage.ex]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Mix task tests + Ecto/PostgreSQL integration tests. [VERIFIED: test/mix/tasks/threadline.export_test.exs, test/threadline/export_test.exs, test/test_helper.exs] |
| Config file | `mix.exs`, `config/test.exs`, `test/test_helper.exs`. [VERIFIED: mix.exs, config/test.exs, test/test_helper.exs] |
| Quick run command | `mix test test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs --max-failures 1` once the new files exist. [ASSUMED] |
| Full suite command | `mix verify.test`, then `mix ci.all` at phase gate. [VERIFIED: CLAUDE.md, mix.exs] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROOF-02 | One canonical Mix task reads the full supported subject set and emits stable wrapped JSON for overview and bounded drill-down modes. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md] | mix task + integration | `mix test test/mix/tasks/threadline.evidence_show_test.exs --max-failures 1` | ❌ Wave 0 |
| PROOF-02 | Proof JSON keeps stable top-level keys and additive record shape. [VERIFIED: .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md, lib/threadline/export.ex] | unit + integration | `mix test test/threadline/evidence/proof_test.exs --max-failures 1` | ❌ Wave 0 |
| PROOF-03 | Claim assessment explicitly distinguishes `proven`, `inferred_posture`, and `unsupported` without treating unsupported claims as runtime failure. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md] | unit + integration | `mix test test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs --max-failures 1` | ❌ Wave 0 |

### Sampling Rate

- After every serializer/verdict change: run
  `mix test test/threadline/evidence/proof_test.exs --max-failures 1`.
- After every CLI/task change: run
  `mix test test/mix/tasks/threadline.evidence_show_test.exs --max-failures 1`.
- Per wave merge: run `mix verify.test`.
- Phase gate: run `mix ci.all`.

### Wave 0 Gaps

- [ ] `test/threadline/evidence/proof_test.exs` — proof envelope shape,
  overview/history projection semantics, and explicit verdict classification.
- [ ] `test/mix/tasks/threadline.evidence_show_test.exs` — argv parsing, human
  output, JSON output, and viewer exit semantics.
- [ ] Deterministic fixtures covering all six supported evidence subjects so
  overview mode proves full subject-set parity.
- [ ] Unsupported-claim fixture proving the payload stays valid JSON and the
  task still exits `0`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V4 Access Control | no | Host authorization stays out of scope; unsupported host-owned claims must remain explicit instead of implied. [VERIFIED: guides/integration-contracts.md, .planning/MILESTONE-ARC.md] |
| V5 Input Validation | yes | Validate subject filters, explicit subject-ref JSON, time bounds, and limit values at the CLI/library edge. [VERIFIED: lib/threadline/evidence.ex, lib/mix/tasks/threadline.export.ex] |
| V9 API / Serialization | yes | Keep JSON keys stable, additive, and machine-readable. [VERIFIED: .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md, lib/threadline/export.ex] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Overclaiming host-owned proof | Spoofing / Repudiation | Encode claim verdicts explicitly and reserve `unsupported` for non-authoritative surfaces. [VERIFIED: .planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md, guides/integration-contracts.md] |
| Shape drift in machine output | Tampering | Lock top-level JSON keys and enums with dedicated serializer tests. [VERIFIED: lib/threadline/export.ex, test/threadline/export_test.exs] |
| Unbounded history reads through CLI | Denial of service | Keep `--limit` bounded and pass validated filters through the existing evidence API. [VERIFIED: lib/threadline/evidence.ex, lib/mix/tasks/threadline.export.ex] |

## Sources

### Primary (HIGH confidence)

- `CLAUDE.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/STATE.md`
- `.planning/MILESTONE-ARC.md`
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-CONTEXT.md`
- `.planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md`
- `.planning/phases/96-evidence-persistence-and-public-api/96-RESEARCH.md`
- `.planning/phases/97-mix-task-and-machine-readable-proof/97-CONTEXT.md`
- `lib/threadline/evidence.ex`
- `lib/threadline/evidence/subject.ex`
- `lib/threadline/governance/evidence_record.ex`
- `lib/mix/tasks/threadline.health.coverage.ex`
- `lib/mix/tasks/threadline.policy.show.ex`
- `lib/mix/tasks/threadline.incident.ex`
- `lib/mix/tasks/threadline.export.ex`
- `test/threadline/evidence_test.exs`
- `test/threadline/export_test.exs`
- `test/mix/tasks/threadline.export_test.exs`
- `guides/domain-reference.md`
- `guides/operator-surface.md`
- `guides/integration-contracts.md`
- `guides/how-threadline-works.md`

### Secondary (MEDIUM confidence)

- None.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Stack and task patterns: HIGH - verified from checked-in Mix tasks, tests,
  and current evidence-plane modules.
- Architecture: HIGH - the recommendation is directly constrained by locked
  Phase 97 context and existing Phase 96 APIs.
- Pitfalls: HIGH - the main failure modes are explicit in the locked context
  and reinforced by repo-local wrapped JSON and viewer-task precedents.

**Research date:** 2026-05-26
**Valid until:** 2026-06-25
