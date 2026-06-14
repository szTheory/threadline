# Phase 166: unfreeze-token-lane-mechanism - Context

**Gathered:** 2026-06-12
**Status:** Ready for planning
**Source:** Recovery from `$gsd-progress` crash plus v1.35 Phase 165 approved recommendation

<domain>
## Phase Boundary

Phase 166 opens v1.36 by making light/system theming mechanically real without retuning every component. It must deliver the host API, server-rendered theme attribute, CSS token lane, same-wave style contract amendment, and decision ledger update. Component-level visual retuning, screenshot lanes, adopter docs, and brandbook parity are later phases unless a source test in this phase needs a narrow supporting assertion.

</domain>

<decisions>
## Implementation Decisions

### D-01 Host Theme API
- `threadline_operator_surface/2` accepts `theme: :dark | :light | :system`.
- The default is `:dark` for zero behavior change.
- Invalid literal theme values raise at compile time and name the allowed triad.

### D-02 Server-Rendered Root Attribute
- The configured theme is assigned during `Threadline.OperatorSurface.Auth.on_mount/4` because router opts already flow there for every LiveView.
- Every operator LiveView root renders `data-tl-theme` with the normalized string value `"dark"`, `"light"`, or `"system"`.
- The implementation uses one shared helper/normalizer so ten roots do not diverge.

### D-03 CSS Mechanism
- Base `.threadline-ui` remains the canonical dark lane and retains `color-scheme: dark`.
- `.threadline-ui[data-tl-theme="light"]` declares the light token lane and `color-scheme: light`.
- `.threadline-ui[data-tl-theme="system"]` receives the same light declarations only inside scoped `@media (prefers-color-scheme: light)`.
- There is no JavaScript, localStorage, head script, or runtime toggle.

### D-04 Light Token Lane Values
- Use the v1.35 recommendation's value system: 19 base semantic light values from `brandbook/tokens.json`, plus designed light values for alpha tints, glass, shadows, focus, and status tokens.
- Add `--tl-color-accent-inset` to replace the one hardcoded shell-nav active inset rgba; declare it in both lanes.
- Keep operation tokens as aliases to status tokens.

### D-05 Source-First Contract Amendment
- Amend `lib/threadline/operator_surface/style.ex` and `test/threadline/operator_surface/style_contract_test.exs` in the same execution wave.
- Replace global dark-only refutes with theme-aware assertions.
- Keep the `theme-toggle` ban verbatim.
- Keep the Phase 144 dark frozen-token assertions intact.

### D-06 Decision Ledger
- Add `[165-01]` to `.planning/STATE.md` as the superseding decision over `[136-01]`.
- Do not edit the old `[136-01]` entry except through the new superseding entry.

### D-07 Worktree Safety
- The repo has unrelated uncommitted nav-overhaul/source changes across `lib/`, `examples/`, and `test/`.
- Execution must read current files and stage explicit paths only.
- Do not revert, checkout, or normalize unrelated source changes.

### the agent's Discretion
- Exact private helper names are discretionary if the public API and source tests prove the same behavior.
- Whether the focused root-attribute proof lives in a new test file or an existing LiveView test file is discretionary.

</decisions>

<canonical_refs>
## Canonical References

### Phase Scope
- `.planning/ROADMAP.md` - Phase 166 goal, requirements, scope notes, and success criteria.
- `.planning/REQUIREMENTS.md` - THEME-01..04 and TOKEN-01..03.
- `.planning/STATE.md` - current decision ledger and v1.36 continuity notes.

### Approved Strategy
- `.planning/milestones/v1.35-phases/165-light-mode-strategy/165-LIGHT-MODE-RECOMMENDATION.md` - approved mechanism and phase breakdown.
- `.planning/milestones/v1.35-phases/165-light-mode-strategy/165-RESEARCH-SURFACE.md` - exact file surface, token census, and refute sites.
- `.planning/milestones/v1.35-phases/165-light-mode-strategy/165-01-SUMMARY.md` - user-approved decision [165-01].

### Source Contracts
- `lib/threadline/operator_surface/router.ex` - `threadline_operator_surface/2` macro and option threading.
- `lib/threadline/operator_surface/auth.ex` - current on_mount assignment seam.
- `lib/threadline/operator_surface/style.ex` - source CSS contract and token block.
- `test/threadline/operator_surface/style_contract_test.exs` - source-first style contract.
- `test/threadline/operator_surface/router_test.exs` - macro compile-validation pattern.

</canonical_refs>

<specifics>
## Specific Ideas

- Root files with literal `<div class="threadline-ui">`: `start_live.ex`, `timeline_live.ex`, `evidence_live.ex`, `coverage_live.ex`, `export_status_live.ex`, `policy_redaction_live.ex`, `retention_history_live.ex`, `row_history_live.ex`, `transaction_live.ex`, `actor_live.ex`.
- The lone hardcoded color outside the token block is `style.ex` shell-nav active inset `rgba(127, 169, 255, 0.16)`.
- Existing seven dark-only enforcement points are in `style_contract_test.exs`: lines 8-14, 86-87, 121-122, 168-169, 196-197, and the Phase 144 anti-pattern list around 824-834.

</specifics>

<deferred>
## Deferred Ideas

- Runtime theme toggle UI and persistence.
- Screenshot `__light__` baseline lane.
- Example app `theme: :system` demonstration.
- Adopter-facing docs and doc-contract coverage.
- Full AA mirror and interaction-state accessibility audit.
- Brandbook `tokens.json` / `tokens.css` 45-token parity.

</deferred>

---

*Phase: 166-unfreeze-token-lane-mechanism*
*Context gathered: 2026-06-12 via crash recovery*
