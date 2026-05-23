# Phase 80: Governance Verification & Milestone Surface Repair - Research

**Researched:** 2026-05-23 [VERIFIED: system date]
**Domain:** Milestone closeout governance, current-tree verification, and planning-surface reconciliation [VERIFIED: codebase grep]
**Confidence:** HIGH [VERIFIED: codebase grep]

<user_constraints>
## User Constraints (from CONTEXT.md)

Source: copied verbatim from `.planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md`. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]

### Locked Decisions

### Evidence posture

- **D-01: Phase 80 is a current-tree truth-repair phase.** Re-verify Phase 75 and repair Phase 79 against the code and docs that exist today. Do not treat prior summaries as authoritative merely because they were written earlier.
- **D-02: Historical artifacts remain as history, not as the active truth surface.** Older summaries, discussions, and validation notes may stay in place, but if they overstate current status, the active milestone surfaces must correct them explicitly.
- **D-03: “Missing artifact” and “requirement satisfied” are different questions.** Creating a missing verification file or summary is not, by itself, proof that the underlying requirement is closed.
- **D-04: Module existence is insufficient proof.** For Threadline, a capability is only “satisfied” when the adopter-facing path is proven, not when a behaviour, adapter module, or isolated unit test merely exists.

### Truth taxonomy

- **D-05: Use an explicit status taxonomy in Phase 80 planning and verification.**
  - `implemented` = code/modules/tests for the isolated surface exist
  - `integrated` = startup/runtime/controller/LiveView path is wired in a realistic host flow
  - `satisfied` = the adopter-facing requirement or success criterion is actually proven
- **D-06: Downgrades are allowed and expected when the current tree demands them.** If prior summaries or verification artifacts over-claimed closure, Phase 80 should correct the claim instead of preserving false continuity.
- **D-07: Phase 80 should prefer “verified on the repaired final tree” language.** Follow the Phase 74 precedent of observable truths on the current tree rather than reconstructing a fictional historically perfect chain.

### Phase 75 repair stance

- **D-08: Re-verify INFRA-01 and INFRA-02 on today’s code, docs, and install path.** This includes governance migrations, schemas, behaviour contracts, storage defaults, and install-task behavior as currently shipped.
- **D-09: Audit Phase 75 for claim drift before writing its verification artifact.** In particular, verify the actual `Threadline.Storage` contract shape, local storage defaults, governance migration output, and any summary wording that implies more polish or stability than the current tree proves.
- **D-10: Do not preserve outdated implementation descriptions for convenience.** If the old research/summary says `priv/exports` but the tree uses `priv/threadline_exports`, or if the behaviour contract evolved, the new evidence must describe the shipped reality.

### Phase 79 repair stance

- **D-11: Restore the missing `79-02` evidence trail, but do not let that restoration silently preserve overstated requirement closure.**
- **D-12: Reframe Phase 79 as adapter-surface implementation, not full adopter-flow closure.** Optional Oban and S3 adapter modules landed, but adopter-facing runtime proof remains open where the current host flow still surprises users.
- **D-13: ADAPT-01 should not remain fully satisfied unless startup/runtime proof exists.** `init/1` safeguards and isolated enqueue tests are useful, but they are not equivalent to proven supervised startup and enqueue behavior in the actual exported path.
- **D-14: ADAPT-02 should not remain fully satisfied while the operator-surface download path assumes local storage.** A storage adapter that correctly returns `{:error, :not_local}` for `path/1` does not make the operator download flow complete.
- **D-15: Phase 80 should explicitly separate “adapter module shipped” from “operator flow works end to end.”** The latter belongs to Phase 84 by the current roadmap shape.

### Milestone surface hierarchy

- **D-16: `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, the milestone audit, and phase verification/validation artifacts are the authoritative status surfaces for v1.20.**
- **D-17: `PROJECT.md` is a narrative surface and must not contradict the authoritative status layer.** Phase 80 should repair its stale “current milestone” and “current state” sections, but should not turn it into a second per-phase bookkeeping ledger.
- **D-18: Scope the planning-surface repair narrowly.** In scope: Phase 75 verification/validation closure, Phase 79 evidence/bookkeeping repair, authoritative milestone-file reconciliation, and the directly stale `PROJECT.md` current-state narrative. Out of scope: sweeping rewrites of historical milestone prose, README churn, or generic planning beautification.

### Recommendation-first downstream posture

- **D-19: Preserve the project’s existing recommendation-heavy discuss/planning posture.** Downstream agents should default to research-first synthesis and cohesive recommendations rather than broad user arbitration.
- **D-20: Only escalate discussion when a decision is genuinely high impact.** The escalation categories are the ones already encoded in `.planning/config.json`: `semver`, `security_model`, `breaking_public_api`, and `scope_cut`.
- **D-21: The durable home for this preference is `.planning/config.json`, not a new methodology artifact.** Phase 80 should carry the preference forward in context so planners and executors understand it is intentional, but should not broaden Phase 80 into workflow redesign.

### the agent's Discretion

- Exact wording for “implemented” vs “integrated” vs “satisfied” in verification prose, as long as the taxonomy above stays intact.
- Whether Phase 79 is described as `partial`, `pending closure`, or equivalent, as long as the wording makes clear that adapter modules exist but adopter-facing proof remains open.
- Exact command lists and proof structure for regenerated verification/validation artifacts, as long as they follow the current-tree / observable-truth model and avoid evidence theater.
- Whether `PROJECT.md` repair is performed directly in Phase 80 or called out as part of milestone-surface reconciliation tasks, as long as its stale current-milestone narrative is fixed before Phase 80 is considered closed.

### Deferred Ideas (OUT OF SCOPE)

- Retention runtime supervision and end-to-end retention closure — Phase 81
- Saved-view actor handoff/runtime repair — Phase 82
- Built-in async export runtime and cleanup closure — Phase 83
- Export delivery and adapter-backed integration closure — Phase 84
- Any broad GSD workflow redesign beyond preserving the already-configured recommendation-first posture
- Sweeping historical narrative cleanup outside the narrow current-state contradictions named above
</user_constraints>

<phase_requirements>
## Phase Requirements

Source: `.planning/REQUIREMENTS.md`. [CITED: .planning/REQUIREMENTS.md]

| ID | Description | Research Support |
|----|-------------|------------------|
| INFRA-01 | Introduce Ecto schemas and migrations for `threadline_export_jobs`, `threadline_retention_runs`, and `threadline_saved_views`. [CITED: .planning/REQUIREMENTS.md] | Re-verify `mix threadline.install`, `Threadline.Governance.Migration`, and the three governance schemas against the current tree; create Phase 75 verification/validation artifacts that prove install-path and schema truth on the repaired final tree. [VERIFIED: codebase grep] |
| INFRA-02 | Define `Threadline.Storage` and `Threadline.ExportQueue` behaviours to formalize pluggable backend components for storage and background task orchestration. [CITED: .planning/REQUIREMENTS.md] | Re-verify the actual behaviour contracts, built-in adapters, and current defaults; correct any stale descriptions in Phase 75 evidence and avoid implying Phase 79 adapter integration equals requirement satisfaction. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 80 should be planned as a repository-governance repair loop, not as runtime implementation work. The authoritative surfaces already say that v1.20 is open, Phase 80 owns INFRA-01 and INFRA-02 closeout, and Phases 81-84 own the remaining runtime gaps. `ROADMAP.md` defines Phase 80 as evidence and planning-surface reconciliation, `REQUIREMENTS.md` remaps INFRA-01 and INFRA-02 to Phase 80 with `Pending` status, and `STATE.md` now reports milestone `v1.20` as `in_progress` at Phase 80. [CITED: .planning/ROADMAP.md] [CITED: .planning/REQUIREMENTS.md] [CITED: .planning/STATE.md]

The main technical research result is that the current tree does support a narrow closeout for Phase 75, but only if the evidence is rewritten to match shipped reality exactly. `mix threadline.install` generates a governance migration file, `Threadline.Governance.Migration` creates the three governance tables, `Threadline.Storage` and `Threadline.ExportQueue` are present as behaviours, and `Threadline.Storage.Local` defaults to `priv/threadline_exports`; those facts differ in material ways from older Phase 75 prose that still describes a smaller behaviour surface and an older storage path. [VERIFIED: codebase grep] [CITED: lib/mix/tasks/threadline.install.ex] [CITED: lib/threadline/governance/migration.ex] [CITED: lib/threadline/storage.ex] [CITED: lib/threadline/export_queue.ex] [CITED: lib/threadline/storage/local.ex] [CITED: .planning/phases/75-governance-infrastructure-and-state/75-RESEARCH.md]

The main planning risk is false closure by artifact repair alone. Phase 79 still lacks `79-02-SUMMARY.md`, `79-VALIDATION.md` is not in the newer Nyquist frontmatter shape, and the current runtime code still proves the audit’s boundary: Oban and S3 modules exist, but startup and operator download integration remain open and belong to later phases. The planner should therefore structure Phase 80 around two outcomes only: truthful Phase 75 closure and milestone-surface consistency, with explicit downgrades or caveats where the current tree does not justify stronger claims. [CITED: .planning/phases/79-scale-adapters/79-VERIFICATION.md] [CITED: .planning/phases/79-scale-adapters/79-VALIDATION.md] [CITED: .planning/v1.20-MILESTONE-AUDIT.md] [VERIFIED: codebase grep]

**Primary recommendation:** Reuse the Phase 74 “verified on the repaired final tree” pattern to regenerate Phase 75 closeout evidence, restore the missing Phase 79 summary trail, and then reconcile `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `PROJECT.md`, and the v1.20 audit in that authority order. [CITED: .planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VERIFICATION.md] [CITED: .planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VALIDATION.md] [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Re-verify INFRA-01 on the current tree | Repository / Verification Artifacts [VERIFIED: codebase grep] | API / Backend [VERIFIED: codebase grep] | Proof is emitted as planning artifacts, but the truth source is backend code in the install task, migration module, and governance schemas. [CITED: lib/mix/tasks/threadline.install.ex] [CITED: lib/threadline/governance/migration.ex] |
| Re-verify INFRA-02 on the current tree | Repository / Verification Artifacts [VERIFIED: codebase grep] | API / Backend [VERIFIED: codebase grep] | The planner must prove behaviour contracts from shipped modules, then record that proof in Phase 75 verification/validation artifacts. [CITED: lib/threadline/storage.ex] [CITED: lib/threadline/export_queue.ex] |
| Repair Phase 79 evidence drift | Repository / Planning Artifacts [VERIFIED: codebase grep] | API / Backend [VERIFIED: codebase grep] | The missing `79-02` summary and overstated closure claims are planning-surface problems, but they must be corrected by reading adapter and controller code on the current tree. [CITED: .planning/phases/79-scale-adapters] [CITED: lib/threadline/export_queue/oban.ex] [CITED: lib/threadline/storage/s3.ex] [CITED: lib/threadline/operator_surface/controllers/export_controller.ex] |
| Reconcile milestone surfaces | Repository / Planning Artifacts [VERIFIED: codebase grep] | Narrative Docs [VERIFIED: codebase grep] | `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, and the milestone audit are the authoritative layer; `PROJECT.md` is downstream narrative that must be aligned last. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] [CITED: .planning/PROJECT.md] |

## Project Constraints (from CLAUDE.md)

- Use Threadline’s three-layer architecture vocabulary consistently: capture, semantics, and exploration/operations. [CITED: CLAUDE.md]
- Prefer the canonical verification entrypoints `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all` over ad hoc commands in docs and evidence. [CITED: CLAUDE.md]
- Keep milestone evidence honest: docs and verification artifacts are part of the shipped product surface, not optional paperwork. [CITED: CLAUDE.md]
- Do not recommend approaches that assume a hard Oban or Phoenix dependency; optional dependency posture is part of the project design constraints. [CITED: CLAUDE.md]
- When using `gsd-sdk query state.begin-phase`, use positional arguments because flag-style invocation can corrupt `.planning/STATE.md`. [CITED: CLAUDE.md]

## Standard Stack

Phase 80 should add no new dependencies. It should use the repo’s existing planning and verification stack only. [VERIFIED: codebase grep]

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 [VERIFIED: command `elixir --version`] | Executes Mix tasks, ExUnit suites, and doc-contract checks. [VERIFIED: codebase grep] | Already installed and is the project runtime/tooling baseline. [VERIFIED: codebase grep] |
| Mix | 1.19.5 [VERIFIED: command `mix --version`] | Runs the verification aliases and targeted tests that Phase 80 evidence should cite. [CITED: mix.exs] | The repo already exposes named entrypoints the project asks contributors to use verbatim. [CITED: CLAUDE.md] [CITED: mix.exs] |
| ExUnit | bundled with Elixir 1.19.5 [VERIFIED: command `elixir --version`] | Provides targeted adapter, export, router, and doc-contract tests for current-tree proof. [VERIFIED: codebase grep] | Existing tests already cover the code surfaces Phase 80 must reference instead of inventing new harnesses. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| GSD planning artifacts | repo-local [VERIFIED: codebase grep] | Hold authoritative milestone truth in `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, audits, and phase artifacts. [VERIFIED: codebase grep] | Use for every status claim, especially before touching `PROJECT.md`. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] |
| ripgrep | available in environment [VERIFIED: command `rg --files test`] | Fast artifact and source auditing. [VERIFIED: codebase grep] | Use to prove file presence, missing trails, and command literals in verification docs. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Phase 74-style current-tree verification [CITED: .planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VERIFICATION.md] | Ad hoc retrospective reconstruction from older summaries [ASSUMED] | Reconstructing intent from stale summaries risks preserving false claims; the current-tree pattern is already established in-repo and matches the locked decisions. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] |
| Named Mix aliases in evidence [CITED: CLAUDE.md] | Raw one-off shell commands [ASSUMED] | Ad hoc commands are harder to compare across closeout artifacts and contradict the project’s stated CI/documentation convention. [CITED: CLAUDE.md] |

**Installation:** None. Phase 80 should not introduce packages or toolchain changes. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Current tree code + existing phase artifacts
        |
        v
Phase 80 evidence audit
  - Phase 75 install/migration/schema/behaviour proof
  - Phase 79 summary/verification/validation drift check
        |
        v
Truth classification
  implemented -> integrated -> satisfied
        |
        +--> If proof is sufficient:
        |      regenerate/repair verification + validation artifacts
        |
        +--> If proof is insufficient:
               downgrade claim, point to owning later phase
        |
        v
Authoritative surface reconciliation
  ROADMAP.md -> REQUIREMENTS.md -> STATE.md -> milestone audit
        |
        v
Narrative alignment
  PROJECT.md current-state repair
```

This diagram reflects the repository-only data flow for Phase 80; there is no runtime service path to implement in this phase. [VERIFIED: codebase grep]

### Recommended Project Structure

```text
.planning/
├── ROADMAP.md                    # Authoritative phase goals/status surface
├── REQUIREMENTS.md               # Requirement-to-phase traceability surface
├── STATE.md                      # Active milestone sequencing/progress surface
├── PROJECT.md                    # Narrative current-state surface
├── v1.20-MILESTONE-AUDIT.md      # Audit baseline to reconcile against
└── phases/
    ├── 74-.../                   # Current-tree verification precedent
    ├── 75-.../                   # Phase 75 evidence to close
    ├── 79-.../                   # Phase 79 evidence to repair
    └── 80-.../                   # This phase's research/plan/summary artifacts
```

### Pattern 1: Current-Tree Verification
**What:** Verify the repaired final tree exactly as it exists now, then state observable truths instead of historical intent. [CITED: .planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VERIFICATION.md]  
**When to use:** For Phase 75 closeout and for any milestone-surface claim that was reopened by the audit. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]  
**Example:**
```text
Observable Truths
1. Phase 75 has current-tree verification and validation artifacts.
2. INFRA-01 is proven by install-task + migration + schema evidence.
3. INFRA-02 is proven by behaviour + built-in adapter evidence.
```
Source: `.planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VERIFICATION.md`. [CITED: .planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VERIFICATION.md]

### Pattern 2: Authority-Order Reconciliation
**What:** Update status surfaces in descending authority order: `ROADMAP.md`, then `REQUIREMENTS.md`, then `STATE.md`, then the milestone audit, then `PROJECT.md`. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]  
**When to use:** Any time Phase 80 changes status language or requirement closure claims. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]  
**Example:**
```text
1. Fix phase plan counts / summary references in ROADMAP.md.
2. Ensure requirement status and phase ownership in REQUIREMENTS.md match.
3. Recompute milestone progress and next step in STATE.md.
4. Reword PROJECT.md current milestone/current state to mirror the authoritative layer.
```

### Pattern 3: Scope Fence by Audit Ownership
**What:** Record later runtime gaps as explicit boundaries, not stealth fixes. [CITED: .planning/ROADMAP.md] [CITED: .planning/v1.20-MILESTONE-AUDIT.md]  
**When to use:** Any time Phase 79 evidence touches Oban startup, S3 download flow, cleanup supervision, or saved-view actor handoff. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]  
**Example:**
```text
ADAPT-01: implemented at adapter surface, not yet satisfied end to end.
ADAPT-02: implemented at adapter surface, not yet satisfied for operator download flow.
```

### Anti-Patterns to Avoid

- **Historical-summary deference:** Do not repeat older Phase 75 prose when the current tree proves a different storage path or behaviour shape. [CITED: .planning/phases/75-governance-infrastructure-and-state/75-RESEARCH.md] [CITED: lib/threadline/storage.ex] [CITED: lib/threadline/storage/local.ex]
- **Artifact theater:** Creating `75-VERIFICATION.md`, `75-VALIDATION.md`, or `79-02-SUMMARY.md` is not itself proof of requirement closure. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]
- **Runtime gap smuggling:** Do not solve retention supervision, session handoff, cleanup lifecycle, or S3-backed download delivery in Phase 80; those are explicitly owned by Phases 81-84. [CITED: .planning/ROADMAP.md] [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]
- **Narrative-first repair:** Do not update `PROJECT.md` before the authoritative milestone files agree. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Verification document shape | A new closeout format for Phase 80 [ASSUMED] | Reuse the Phase 74 verification/validation pattern. [CITED: .planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VERIFICATION.md] [CITED: .planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VALIDATION.md] | The repo already has a successful precedent for current-tree repair phases. [CITED: .planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VERIFICATION.md] |
| Requirement truth model | Binary “done / not done” language [ASSUMED] | Use the locked `implemented` / `integrated` / `satisfied` taxonomy. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] | The audit gaps in 79 and the future ownership split across 81-84 require finer status language. [CITED: .planning/ROADMAP.md] |
| Milestone status source | `PROJECT.md` as a second ledger [ASSUMED] | Treat `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, audit, and phase artifacts as the authoritative layer. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] | The context explicitly defines that hierarchy. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] |
| Command surface | One-off verification commands only [ASSUMED] | Cite `mix verify.*` and `mix ci.all` aliases. [CITED: CLAUDE.md] [CITED: mix.exs] | The project explicitly standardizes on named entrypoints for CI and docs. [CITED: CLAUDE.md] |

**Key insight:** Phase 80 is successful when it makes milestone truth easier to audit, not when it invents new paperwork. The cheapest path is to reuse the existing closeout machinery and apply it more honestly. [CITED: .planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VERIFICATION.md] [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Treating Phase 75’s old research as the shipped contract
**What goes wrong:** Evidence repeats stale details such as a smaller behaviour shape or the wrong local export directory. [CITED: .planning/phases/75-governance-infrastructure-and-state/75-RESEARCH.md] [CITED: lib/threadline/storage.ex] [CITED: lib/threadline/storage/local.ex]  
**Why it happens:** Phase 75 has research and summary artifacts but no verification or validation artifact, so old prose was never hardened against the final tree. [VERIFIED: codebase grep]  
**How to avoid:** Drive every Phase 75 claim from the current code paths first, then write the verification document. [VERIFIED: codebase grep]  
**Warning signs:** The artifact mentions `priv/exports`, omits `path/1`, or describes `put/2` as returning `:ok` instead of `{:ok, file_id}`. [CITED: .planning/phases/75-governance-infrastructure-and-state/75-RESEARCH.md] [CITED: lib/threadline/storage.ex] [CITED: lib/threadline/storage/local.ex]

### Pitfall 2: Marking Phase 79 satisfied because unit tests pass
**What goes wrong:** Oban and S3 modules are treated as fully closed even though current runtime integration is still broken. [CITED: .planning/v1.20-MILESTONE-AUDIT.md] [CITED: lib/threadline/export_queue/oban.ex] [CITED: lib/threadline/storage/s3.ex]  
**Why it happens:** The repo has adapter tests and a passed Phase 79 verification artifact, but the current controller/runtime code still assumes local-path download and a started built-in queue path. [CITED: .planning/phases/79-scale-adapters/79-VERIFICATION.md] [CITED: lib/threadline/operator_surface/controllers/export_controller.ex] [CITED: lib/threadline/export_queue/task_adapter.ex]  
**How to avoid:** Use the locked taxonomy and downgrade Phase 79 claims to adapter-surface implementation where end-to-end proof is missing. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]  
**Warning signs:** Evidence says “ADAPT-01 satisfied” without startup proof or says “ADAPT-02 satisfied” while download still routes through `path/1`. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] [CITED: lib/threadline/operator_surface/controllers/export_controller.ex] [CITED: lib/threadline/storage/s3.ex]

### Pitfall 3: Reconciling narrative before authority
**What goes wrong:** `PROJECT.md` gets updated first and then drifts again when `ROADMAP.md`, `REQUIREMENTS.md`, or `STATE.md` changes. [CITED: .planning/PROJECT.md] [CITED: .planning/ROADMAP.md] [CITED: .planning/REQUIREMENTS.md] [CITED: .planning/STATE.md]  
**Why it happens:** `PROJECT.md` reads like a “current truth” page even though the context explicitly demotes it to narrative. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]  
**How to avoid:** Reconcile authoritative milestone files first and patch `PROJECT.md` last. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]  
**Warning signs:** `PROJECT.md` still says the current milestone is v1.19 while `STATE.md` says the active milestone is v1.20. [CITED: .planning/PROJECT.md] [CITED: .planning/STATE.md]

## Code Examples

Verified patterns from the current repo:

### Phase 75 install-path proof
```elixir
# Source: lib/mix/tasks/threadline.install.ex
governance_written =
  if existing_governance_migration?(path) do
    Mix.shell().info("Threadline governance schema migration already exists — skipping.")
    false
  else
    file = Path.join(path, "#{timestamp()}_threadline_governance_schema.exs")
    create_file(file, Threadline.Governance.Migration.migration_content())
    true
  end
```
[CITED: lib/mix/tasks/threadline.install.ex]

### Phase 75 behaviour truth
```elixir
# Source: lib/threadline/storage.ex
@callback init(keyword()) :: :ok | {:error, term()}
@callback put(path_or_content(), options()) :: {:ok, file_id()} | {:error, term()}
@callback path(file_id()) :: {:ok, String.t()} | {:error, term()}
@callback download_url(file_id(), options()) :: {:ok, String.t()} | {:error, term()}
```
[CITED: lib/threadline/storage.ex]

### Phase 79 boundary proof
```elixir
# Source: lib/threadline/operator_surface/controllers/export_controller.ex
case storage_adapter.path(job.file_path) do
  {:ok, absolute_path} -> Plug.Conn.send_file(conn, 200, absolute_path)
  {:error, _reason} -> send_resp(conn, 404, "File not found or not locally accessible")
end
```
[CITED: lib/threadline/operator_surface/controllers/export_controller.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Historical completion narratives stand unless contradicted later. [ASSUMED] | Current-tree verification on the repaired final tree is the repo precedent for closeout repair. [CITED: .planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VERIFICATION.md] | Proven by Phase 74 on 2026-05-08. [CITED: .planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VERIFICATION.md] | Phase 80 should verify observable truth instead of reconstructing idealized history. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] |
| “Module exists” implies requirement closure. [ASSUMED] | The locked taxonomy separates `implemented`, `integrated`, and `satisfied`. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] | Introduced in the Phase 80 context on 2026-05-23. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] | Phase 79 claims can be downgraded without deleting the evidence that modules shipped. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] |
| `PROJECT.md` can act as milestone truth. [ASSUMED] | Authoritative truth lives in roadmap, requirements, state, audit, and verification/validation artifacts; `PROJECT.md` is narrative only. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] | Explicit in the Phase 80 context on 2026-05-23. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] | Planning repairs must be applied in authority order to avoid reintroducing contradiction. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] |

**Deprecated/outdated:**

- Phase 75’s old description of local storage as `priv/exports` is outdated; the current adapter writes under `priv/threadline_exports`. [CITED: .planning/phases/75-governance-infrastructure-and-state/75-RESEARCH.md] [CITED: lib/threadline/storage/local.ex]
- Phase 79’s binary “all requirements satisfied” framing is outdated for milestone truth because the current audit and current controller/runtime code still prove unresolved adopter-flow gaps. [CITED: .planning/phases/79-scale-adapters/79-VERIFICATION.md] [CITED: .planning/v1.20-MILESTONE-AUDIT.md] [CITED: lib/threadline/operator_surface/controllers/export_controller.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Reusing the Phase 74 document shape is preferable to introducing a new closeout format. [ASSUMED] | Standard Stack / Don’t Hand-Roll | Low. The planner could still execute Phase 80 with a different format, but it would lose in-repo precedent and comparability. |
| A2 | Raw one-off verification commands are materially worse than named Mix aliases for future milestone maintenance. [ASSUMED] | Standard Stack / Don’t Hand-Roll | Low. The project already prefers aliases, but a planner could still cite raw commands if absolutely needed. |
| A3 | Binary “done / not done” language would create avoidable ambiguity for Phase 79 closeout. [ASSUMED] | Don’t Hand-Roll / State of the Art | Medium. If the team rejects the taxonomy, Phase 80 could struggle to describe partial adapter closure honestly. |

## Open Questions

1. **Should `PROJECT.md` be repaired in the same execution slice as the authoritative milestone files or in a follow-up slice within Phase 80?**
What we know: The context makes `PROJECT.md` narrative-only and explicitly scopes its stale current-state repair into Phase 80. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]
What's unclear: Whether the planner wants that narrative repair bundled with the final authority-surface task or as a small final cleanup slice. [VERIFIED: codebase grep]
Recommendation: Keep it in Phase 80, but sequence it after `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, and the audit are reconciled. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks, ExUnit, doc verification [VERIFIED: codebase grep] | ✓ [VERIFIED: command `elixir --version`] | 1.19.5 [VERIFIED: command `elixir --version`] | — |
| Mix | Named verification entrypoints [CITED: mix.exs] | ✓ [VERIFIED: command `mix --version`] | 1.19.5 [VERIFIED: command `mix --version`] | — |
| ripgrep | Fast artifact/file audits [VERIFIED: codebase grep] | ✓ [VERIFIED: command `rg --files test`] | — [VERIFIED: command `rg --files test`] | `grep` if needed. [ASSUMED] |

**Missing dependencies with no fallback:** None. [VERIFIED: codebase grep]

**Missing dependencies with fallback:** None material to Phase 80 planning. [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5, plus planning-artifact checks and Mix alias gates. [VERIFIED: command `elixir --version`] [CITED: mix.exs] |
| Config file | `mix.exs`; `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `.planning/STATE.md`; `.planning/v1.20-MILESTONE-AUDIT.md`. [CITED: mix.exs] [VERIFIED: codebase grep] |
| Quick run command | `mix test test/threadline/export/orchestrator_test.exs test/threadline/export_queue/task_adapter_test.exs test/threadline/export_queue/oban_test.exs test/threadline/storage/local_test.exs test/threadline/storage/s3_test.exs --max-failures 1` [VERIFIED: codebase grep] |
| Full suite command | `mix ci.all` [CITED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INFRA-01 | Governance install path and schema surface are present and describable truthfully on the current tree. [VERIFIED: codebase grep] | artifact + targeted unit | `rg -n 'threadline_governance_schema|threadline_export_jobs|threadline_retention_runs|threadline_saved_views' lib/mix/tasks/threadline.install.ex lib/threadline/governance/migration.ex lib/threadline/governance/*.ex && mix test test/threadline/export/orchestrator_test.exs --max-failures 1` [VERIFIED: codebase grep] | ✅ [VERIFIED: codebase grep] |
| INFRA-02 | Storage and export queue behaviour contracts and built-in adapters match the repaired evidence. [VERIFIED: codebase grep] | targeted unit + artifact | `mix test test/threadline/export_queue/task_adapter_test.exs test/threadline/export_queue/oban_test.exs test/threadline/storage/local_test.exs test/threadline/storage/s3_test.exs --max-failures 1 && rg -n '@callback init|@callback enqueue|@callback download_url|threadline_exports' lib/threadline/storage.ex lib/threadline/export_queue.ex lib/threadline/storage/local.ex lib/threadline/export_queue/task_adapter.ex` [VERIFIED: codebase grep] | ✅ [VERIFIED: codebase grep] |

### Sampling Rate

- **Per task commit:** Run the targeted artifact grep plus the narrow ExUnit subset that matches the surface being documented. [VERIFIED: codebase grep]
- **Per wave merge:** Run `mix verify.compile_no_optional` if any docs or evidence cite optional-dependency posture, and run `mix ci.all` before final verification. [CITED: mix.exs] [CITED: CLAUDE.md]
- **Phase gate:** Full milestone-surface reconciliation plus `mix ci.all` green before `/gsd-verify-work`. [CITED: mix.exs] [ASSUMED]

### Wave 0 Gaps

- [ ] `75-VERIFICATION.md` — Phase 80 must create it because it does not exist yet. [VERIFIED: codebase grep]
- [ ] `75-VALIDATION.md` — Phase 80 must create it because it does not exist yet. [VERIFIED: codebase grep]
- [ ] `79-02-SUMMARY.md` — Phase 80 must restore it because it does not exist yet. [VERIFIED: codebase grep]
- [ ] `79-VALIDATION.md` frontmatter normalization — existing file lacks the newer Nyquist shape used by Phase 74. [CITED: .planning/phases/79-scale-adapters/79-VALIDATION.md] [CITED: .planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VALIDATION.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: codebase grep] | No new auth surface is added in Phase 80; later runtime auth fixes remain in Phase 82. [CITED: .planning/ROADMAP.md] |
| V3 Session Management | no [VERIFIED: codebase grep] | Session handoff is explicitly deferred to Phase 82. [CITED: .planning/ROADMAP.md] |
| V4 Access Control | no [VERIFIED: codebase grep] | Phase 80 should document status truth, not change runtime authorization behavior. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] |
| V5 Input Validation | yes [ASSUMED] | Validate every status claim against current-tree evidence and authoritative milestone sources before writing it. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] |
| V6 Cryptography | no [VERIFIED: codebase grep] | No cryptographic surface is introduced or modified in this phase. [VERIFIED: codebase grep] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Stale completion claims survive into active milestone files. [VERIFIED: codebase grep] | Tampering / Repudiation [ASSUMED] | Re-verify against current code, then repair authoritative surfaces in order. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] |
| Missing summary or validation trails are mistaken for proof of satisfaction. [VERIFIED: codebase grep] | Repudiation [ASSUMED] | Separate “artifact exists” from “requirement satisfied” in every Phase 80 report. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] |
| Narrative docs contradict authoritative status surfaces. [VERIFIED: codebase grep] | Tampering [ASSUMED] | Update `PROJECT.md` only after `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, and the audit agree. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `CLAUDE.md` - project constraints, verification entrypoints, architectural language. [CITED: CLAUDE.md]
- `.planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md` - locked decisions, scope boundaries, authority hierarchy. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md]
- `.planning/ROADMAP.md` - Phase 80 goal/success criteria and ownership boundaries for Phases 81-84. [CITED: .planning/ROADMAP.md]
- `.planning/REQUIREMENTS.md` - INFRA-01 and INFRA-02 wording and current traceability remap. [CITED: .planning/REQUIREMENTS.md]
- `.planning/STATE.md` - active milestone status, current phase, and next-step surface. [CITED: .planning/STATE.md]
- `.planning/v1.20-MILESTONE-AUDIT.md` - concrete gap statements and audit boundary for Phase 80. [CITED: .planning/v1.20-MILESTONE-AUDIT.md]
- `.planning/PROJECT.md` - stale narrative surface that must be aligned. [CITED: .planning/PROJECT.md]
- `.planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VERIFICATION.md` - current-tree verification precedent. [CITED: .planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VERIFICATION.md]
- `.planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VALIDATION.md` - Nyquist validation precedent. [CITED: .planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VALIDATION.md]
- `lib/mix/tasks/threadline.install.ex`, `lib/threadline/governance/*.ex`, `lib/threadline/storage*.ex`, `lib/threadline/export_queue*.ex`, `lib/threadline/export/orchestrator.ex`, `lib/threadline/operator_surface/controllers/export_controller.ex` - current-tree proof for Phase 75 and Phase 79 status. [CITED: lib/mix/tasks/threadline.install.ex] [CITED: lib/threadline/governance/migration.ex] [CITED: lib/threadline/governance/export_job.ex] [CITED: lib/threadline/governance/retention_run.ex] [CITED: lib/threadline/governance/saved_view.ex] [CITED: lib/threadline/storage.ex] [CITED: lib/threadline/storage/local.ex] [CITED: lib/threadline/storage/s3.ex] [CITED: lib/threadline/export_queue.ex] [CITED: lib/threadline/export_queue/task_adapter.ex] [CITED: lib/threadline/export_queue/oban.ex] [CITED: lib/threadline/export/orchestrator.ex] [CITED: lib/threadline/operator_surface/controllers/export_controller.ex]
- `mix --version`, `elixir --version`, `rg --files test`, `ls -la .planning/phases/75-governance-infrastructure-and-state`, `ls -la .planning/phases/79-scale-adapters` - environment/tooling/file-presence verification. [VERIFIED: command output]

### Secondary (MEDIUM confidence)
- None. This research stayed inside current-tree and repo-local evidence. [VERIFIED: codebase grep]

### Tertiary (LOW confidence)
- None beyond the assumptions explicitly logged above. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase uses only installed Elixir/Mix tooling and repo-local conventions verified in the current workspace. [VERIFIED: command output] [CITED: mix.exs]
- Architecture: HIGH - the scope, authority order, and later-phase boundaries are locked in the Phase 80 context and roadmap. [CITED: .planning/phases/80-governance-verification-and-milestone-surface-repair/80-CONTEXT.md] [CITED: .planning/ROADMAP.md]
- Pitfalls: HIGH - the pitfalls are directly evidenced by mismatches between current code, current planning artifacts, and the milestone audit. [CITED: .planning/v1.20-MILESTONE-AUDIT.md] [VERIFIED: codebase grep]

**Research date:** 2026-05-23 [VERIFIED: system date]
**Valid until:** 2026-06-22 for repo-local planning truth, assuming no new phase execution lands before planning. [ASSUMED]
