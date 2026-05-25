# Phase 91: Phase 86 Verification Backfill - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the missing verification chain for Phase 86 on the current tree. This phase proves the scoped read-path story for support-scoped sessions, especially query-level enforcement and mounted `/audit` behavior around row history / as-of and coverage gating.

This is a verification-backfill phase, not a new feature phase. It may add or tighten proof, refresh artifacts, and correct authoritative wording if the verified current-tree truth is narrower than earlier implementation intent. It does not widen the support lane, invent a new auth model, or reopen the original Phase 86 product decisions.

</domain>

<decisions>
## Implementation Decisions

### Verification proof bar
- **D-01: Phase 91 must use a three-layer proof bar.** Do not treat query-level assertions alone as sufficient closure.
- **D-02: Query-level proof is mandatory.** Verification must explicitly cover `Threadline.history/3`, `Threadline.as_of/4`, `Threadline.row_history/4`, and `Threadline.row_history_page/4` with support-style scoping applied.
- **D-03: Mounted LiveView proof is mandatory.** Verification must show that the scoped row-history path is actually wired through the shipped `/audit` transaction flow, not merely available as a lower-level API.
- **D-04: Example-host and public-proof surfaces should only be included where the repo already claims support-lane truth.** Do not over-promote the example app or docs into proof for support-scoped row history / as-of unless the current tree truly proves that path.

### Truth-first fallback
- **D-05: Use asymmetric truth handling.** If verification exposes only a small, local, same-pass proof gap, a narrow repair is allowed only when it can be fully verified immediately on the current tree.
- **D-06: Prefer narrowing over stretching the claim.** If row history / as-of still lacks proof at the same seriousness level as timeline, actor, and transaction support-lane behavior, keep that path `unclaimed` for support sessions.
- **D-07: Artifact creation is not closure by itself.** The phase only closes when the written verification artifact matches the actual current-tree proof, not the older implementation intent from Phase 86.

### Authority updates when truth changes
- **D-08: If Phase 91 changes the current-tree truth, update every authoritative surface touched by that truth.** This includes the phase artifact plus `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and any public support-lane docs/examples whose wording would otherwise overclaim.
- **D-09: Keep authority updates requirement-scoped and exact.** Only `SCOPE-01` and `SCOPE-02` should move in this phase; do not imply broader v1.21 closeout.
- **D-10: Public wording must follow proof, not implementation aspiration.** If docs currently say support-scoped row history / as-of is `unclaimed`, that wording remains correct unless Phase 91 produces explicit current-tree proof strong enough to change it.

### Locked upstream product posture
- **D-11: Do not reopen the original Phase 86 behavioral decisions.** The locked product direction remains:
  row history / as-of should be scope-enforced when claimed, and coverage is a separate gated admin/global surface.
- **D-12: Keep the support lane host-owned.** Proof should reinforce `scope_query_fn` and `coverage_authorize_fn` as the canonical seams, not invent a Threadline-owned policy layer.

### the agent's Discretion
- Exact choice of proof commands and test subsets, as long as the three-layer verification bar is satisfied.
- Whether a same-pass repair is done in code, tests, docs, or phase artifacts, as long as it is narrowly bounded and fully re-verified immediately.
- Exact wording inside the verification artifact, as long as it states the current-tree truth plainly and distinguishes proven from unclaimed behavior.

</decisions>

<specifics>
## Specific Ideas

- The strongest recommended Phase 91 posture is:
  query proof plus mounted `/audit` proof, then truth-first narrowing if row-history / as-of still does not meet the same evidence bar as the rest of the claimed support lane.
- The most important current-tree caution is:
  public docs already say support-scoped row history / as-of remains `unclaimed`, so planning must not assume this phase is guaranteed to promote that path into the named claim.
- The cleanest closure pattern is:
  verify the existing Phase 86 implementation honestly, repair only if the gap is small and immediately provable, otherwise preserve the narrower claim and write that down explicitly.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and requirement contract
- `.planning/ROADMAP.md` — Phase 91 goal, plan slots, and current milestone wording around scoped read-path verification backfill.
- `.planning/REQUIREMENTS.md` — `SCOPE-01` and `SCOPE-02` are the direct requirement contract for this phase.
- `.planning/STATE.md` — current milestone routing, including Phase 90 complete and Phase 91 queued.
- `.planning/PROJECT.md` — current milestone thesis: one canonical `/audit` mount, host-owned auth/scope semantics, and truthful support-lane claims.

### Locked upstream context
- `.planning/phases/85-support-lane-surface-audit/85-CONTEXT.md` — support-lane claim lock and export/controls posture.
- `.planning/phases/88-denial-fallback-ux-closure/88-CONTEXT.md` — current support-lane UX truth model, including unsupported/direct-route posture and explicit `unclaimed` handling.
- `.planning/phases/89-contract-lock-final-verification/89-CONTEXT.md` — contract-lock verification philosophy, authority hierarchy, and truth-first drift handling.
- `.planning/phases/86-scoped-read-path-closure/86-DISCUSSION.md` — original Phase 86 decision record for row history/as-of scoping and coverage gating.
- `.planning/phases/86-scoped-read-path-closure/86-RESEARCH.md` — implementation shape for row-history scoping and coverage authorization.
- `.planning/phases/86-scoped-read-path-closure/86-VALIDATION.md` — original Nyquist expectations for query scoping, LiveView threading, and coverage gating.
- `.planning/phases/90-phase-85-verification-backfill/90-01-SUMMARY.md` and `.planning/phases/90-phase-85-verification-backfill/90-02-SUMMARY.md` — the established pattern for narrow current-tree verification backfill and authority-surface updates.

### Current public truth surfaces
- `guides/operator-surface.md` — current public wording says support-scoped row history / as-of remains `unclaimed` unless the host separately proves it.
- `guides/upgrade-path.md` — named support-lane matrix and the current `unclaimed` wording for row history / as-of.
- `guides/getting-started-saas.md` — first-hour adopter guidance that keeps support-lane row-history / as-of wording narrower than timeline, actor, and transaction proof.
- `examples/threadline_phoenix/README.md` — example-host reference wording around the shared `/audit` tree and narrower row-history / as-of claim.

### Current implementation seams
- `lib/threadline/query.ex` — row-history and as-of query scoping via `maybe_apply_scope/2` and `row_history_scope_opts/3`.
- `lib/threadline/investigation.ex` — public helper path into scoped row-history queries.
- `lib/threadline/operator_surface/live/transaction_live.ex` — mounted `/audit` transaction flow that threads `scope` and `scope_query_fn` into row history.
- `lib/threadline/operator_surface/live/row_history_component.ex` — row-history LiveComponent that delegates to `Threadline.history/3` and `Threadline.as_of/4`.
- `lib/threadline/operator_surface/auth.ex` — `coverage_authorize_fn` handling and `threadline_coverage_enabled` assignment.
- `lib/threadline/operator_surface/coverage/on_mount.ex` — coverage polling gate for unauthorized sessions.
- `lib/threadline/operator_surface/live/coverage_live.ex` — direct-route coverage denial behavior.

### Verification surfaces
- `test/threadline/query_test.exs` — direct query-level proof for `history/3` and `as_of/4`; likely expansion point for stronger scoped evidence.
- `test/threadline/investigation_test.exs` — direct proof for `row_history/4` and `row_history_page/4`.
- `test/threadline/operator_surface/transaction_live_test.exs` — mounted `/audit` transaction flow and scoped operator test seam.
- `test/threadline/operator_surface/row_history_component_test.exs` — current lightweight component coverage; may need strengthening if planning chooses component-level proof.
- `test/threadline/operator_surface/auth_test.exs` — default-deny and callback-shape proof for `coverage_authorize_fn`.
- `test/threadline/operator_surface/coverage/on_mount_test.exs` — proof that unauthorized coverage sessions do not start the polling path.
- `test/threadline/operator_surface/live/coverage_live_test.exs` — direct-route coverage denial behavior.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Query` already contains the scoping hook points for row history and as-of queries; verification should start by proving those exact seams rather than redesigning them.
- `TransactionLive` and `RowHistoryComponent` already thread scoped parameters through the mounted `/audit` path, so planning can focus on proving the end-to-end chain instead of adding a new wiring model.
- Coverage gating is already factored cleanly through `Auth.on_mount/4`, `Coverage.OnMount`, and `CoverageLive`.

### Established Patterns
- Verification backfills in this milestone close against current-tree truth, not broader earlier intent.
- Authority-surface updates happen only when proof changes the truthful claim.
- Threadline treats docs, tests, example proof, and verification artifacts as one contract chain, but keeps each concern in its own authority layer.

### Integration Points
- Strengthen or rerun query-level tests around scoped row-history/as-of behavior.
- Strengthen or rerun mounted `/audit` tests so the scoped row-history path is proven through the actual transaction UI flow.
- If truth changes, reconcile planning surfaces and public support-lane wording in the same narrow pass.

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 91-phase-86-verification-backfill*
*Context gathered: 2026-05-25*
