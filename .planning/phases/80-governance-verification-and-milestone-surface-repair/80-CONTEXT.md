# Phase 80: Governance Verification & Milestone Surface Repair - Context

**Gathered:** 2026-05-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Repair the milestone evidence and planning surfaces for v1.20 so they truthfully describe the current tree before closeout resumes. This phase is a truth-repair and bookkeeping-repair phase, not a runtime feature phase. It may re-verify prior work, recreate missing evidence trails, and downgrade overstated claims. It does not close the retention, saved-view, async-export, or S3/Oban runtime gaps themselves; those remain owned by Phases 81-84.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<specifics>
## Specific Ideas

- The strongest maintainer posture for this phase is: “If a user installed Threadline from this tree today, what could they truthfully rely on?”
- The strongest ecosystem lesson here is to avoid adapter theater:
  - Oban-style features are not really “done” until startup/supervision and the real enqueue path are proven.
  - S3-style storage is not really “done” if the library still assumes local-file download mechanics.
  - Audit and docs surfaces should behave like public API contracts, not internal memory aids.
- The repo already contains the desired GSD preference shift in `.planning/config.json`:
  - `discuss_default_research_synthesis`
  - `discuss_use_subagent_research`
  - `discuss_default_cohesive_recommendations`
  - `discuss_interactive_menus_high_impact_only`
  - `discuss_trust_cohesive_research_unless_high_impact`
  Phase 80 should preserve that stance rather than inventing a new workflow layer.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contract and milestone audit
- `.planning/ROADMAP.md` — Phase 80 goal, success criteria, and Phase 81-84 ownership boundaries
- `.planning/REQUIREMENTS.md` — v1.20 requirement mapping and current traceability surface
- `.planning/STATE.md` — active milestone state and current sequencing
- `.planning/v1.20-MILESTONE-AUDIT.md` — the concrete gaps this phase is repairing
- `.planning/PROJECT.md` — stale current-milestone narrative that must be reconciled

### Prior closeout precedent
- `.planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VERIFICATION.md` — precedent for current-tree observable-truth verification
- `.planning/phases/74-nyquist-closeout-and-requirement-tracking-repair/74-VALIDATION.md` — precedent for Nyquist-compliant closeout repair

### Phase 75 evidence surface
- `.planning/phases/75-governance-infrastructure-and-state/75-DISCUSSION.md`
- `.planning/phases/75-governance-infrastructure-and-state/75-RESEARCH.md`
- `.planning/phases/75-governance-infrastructure-and-state/75-01-SUMMARY.md`
- `lib/mix/tasks/threadline.install.ex`
- `lib/threadline/governance/migration.ex`
- `lib/threadline/governance/export_job.ex`
- `lib/threadline/governance/retention_run.ex`
- `lib/threadline/governance/saved_view.ex`
- `lib/threadline/storage.ex`
- `lib/threadline/storage/local.ex`
- `lib/threadline/export_queue.ex`

### Phase 79 evidence surface
- `.planning/phases/79-scale-adapters/79-01-PLAN.md`
- `.planning/phases/79-scale-adapters/79-02-PLAN.md`
- `.planning/phases/79-scale-adapters/79-03-PLAN.md`
- `.planning/phases/79-scale-adapters/79-01-SUMMARY.md`
- `.planning/phases/79-scale-adapters/79-03-SUMMARY.md`
- `.planning/phases/79-scale-adapters/79-VERIFICATION.md`
- `.planning/phases/79-scale-adapters/79-VALIDATION.md`
- `lib/threadline/export_queue/oban.ex`
- `lib/threadline/export_queue/task_adapter.ex`
- `lib/threadline/storage/s3.ex`
- `lib/threadline/export/orchestrator.ex`
- `lib/threadline/operator_surface/controllers/export_controller.ex`
- `lib/threadline/operator_surface/live/timeline_live.ex`

### Saved-view / export / retention drift named by the audit
- `.planning/phases/77-saved-views-ergonomics/77-01-SUMMARY.md`
- `.planning/phases/77-saved-views-ergonomics/77-02-SUMMARY.md`
- `.planning/phases/78-async-exports-ui/78-VALIDATION.md`
- `.planning/phases/76-batched-retention-and-ui/76-VALIDATION.md`
- `lib/threadline/operator_surface/session_plug.ex`
- `lib/threadline/operator_surface/auth.ex`
- `lib/threadline/operator_surface/router.ex`
- `lib/threadline/export/cleanup_task.ex`

### Project philosophy and planning posture
- `.planning/config.json`
- `CLAUDE.md`
- `GEMINI.md`
- `prompts/THREADLINE-GSD-IDEA.md`
- `prompts/threadline-elixir-oss-dna.md`
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md`
- `prompts/prior-art/accrue-planning-notes.md`
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/phoenix-best-practices-deep-research.md`
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 74 already provides the right verification/validation shape for a repair-style phase that must verify the final tree rather than replay historical intent.
- The current audit is specific enough to drive truth-repair tasks directly; it names both artifact gaps and runtime mismatch points.
- `.planning/config.json` already encodes the desired “research first, recommend first, interrupt only on high-impact decisions” workflow stance.

### Established Patterns
- Threadline’s project DNA treats verification, docs, and planning surfaces as part of the product surface, not secondary paperwork.
- The repo consistently values optional dependencies with strong DX, but the audit shows that optional adapters still need honest startup and runtime proof before being treated as adopter-ready.
- LiveView and controller paths are intentionally separate in the operator surface, which makes transport-boundary truth especially important for exports and session handoff.

### Integration Points
- Phase 80 planning should connect prior-phase artifacts, active milestone files, and concrete runtime code paths into one reconciled status story.
- Phase 79 bookkeeping must connect to the Phase 84 runtime-repair plan boundary rather than pretending the integration already landed.
- Phase 75 verification must connect install-task output, governance schemas, and behaviour contracts into one explicit proof chain.

</code_context>

<deferred>
## Deferred Ideas

- Retention runtime supervision and end-to-end retention closure — Phase 81
- Saved-view actor handoff/runtime repair — Phase 82
- Built-in async export runtime and cleanup closure — Phase 83
- Export delivery and adapter-backed integration closure — Phase 84
- Any broad GSD workflow redesign beyond preserving the already-configured recommendation-first posture
- Sweeping historical narrative cleanup outside the narrow current-state contradictions named above

</deferred>

---

*Phase: 80-governance-verification-and-milestone-surface-repair*
*Context gathered: 2026-05-23*
