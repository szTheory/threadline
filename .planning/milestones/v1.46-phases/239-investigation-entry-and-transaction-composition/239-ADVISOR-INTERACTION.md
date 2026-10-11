# Phase 239 shared interaction research

Source authority: `the retained current-main worktree`. Read-only research; no repository files changed.

## Recommendation

Use the existing shared CSS token catalog and Phoenix UI primitives as the owner for common hierarchy, control states, focus visibility, overlay stacking, theme preference/effective appearance, and requested-versus-rendered result truth. Keep route-specific rules only for genuinely different content composition. Prove the contract across home, Timeline, and transaction inspection in the same journey. Avoid introducing a client state system or dependency: Threadline already has session-backed Light/Dark/System selection, CSS system preference handling, shared controls/overlays, and LiveView URL patching.

This aligns with the approved Phase 239 goal and existing product constraints: preserve the Threadline identity, canonical AuditAction/AuditTransaction/AuditChange/AuditContext/ActorRef distinctions, exact authorized evidence, and host-owned authorization, tenant scope, and redaction. No new public API, auth, backend, or library/framework scope is called for. Phoenix `handle_params` is the existing URL/query boundary and is invoked after mount and each live patch.

| Option | Pros | Cons | Complexity | Recommendation |
|---|---|---|---|---|
| Shared tokens and existing Phoenix UI primitives, with narrow route rules | One owner for common hierarchy, states, focus and theme; reuses session preference and CSS system media query; no dependency | Shared edits affect several journeys; duplicate theme blocks/circular aliases and CSS cascade can obscure actual computed styles | Shared CSS/UI modules plus route/browser checks — Risk: cascade and LiveView patch regressions | Rec for Phase 239's shared contract across home, Timeline, and transactions |
| Route-local styles and state markup | Limits changes to a unique page composition; useful for true exceptions | Repeats common behavior; can drift on focus, labels, theme and long values; less regression coverage across routes | Route modules and CSS — Risk: behavior divergence during navigation | Rec only for a finding demonstrably unique to one route |
| Client-managed theme and interaction state | Can coordinate transient visual state in the browser | Duplicates server preference and LiveView state; adds lifecycle/hydration risks; System already follows OS preference in CSS | Script, shell and persistence — Risk: server/client disagreement and needless runtime coupling | Rec only if a required behavior cannot be represented by current CSS/LiveView contracts |

## Evidence and ownership boundary

- Phase 238's `238-BASELINE-FINDINGS.md` and `238-UI-REVIEW.md` accept the 375 CSS px long-filter overflow as a rendered finding: 232-character correlation value, document `scrollWidth` 1924, date fields/Apply/chip clipped. This is a whole-document overflow, not an intentionally contained evidence scroller. Keep every control visible, constrain intrinsic grid/flex/input widths, let long active chips wrap, and retain complete-value access/copy.
- Phase 238 confirms `--tl-color-paper` and `--tl-color-ink` self-reference in dark and light/System theme declarations and resolve empty. This is latent token debt, not a reproduced contrast failure. Repair the source and assert computed values/effective colors per chosen preference and OS media mode; source-string assertions alone do not prove visual values.
- Theme choice already uses a theme POST controller, session value, mirrored cookie, `Auth` assignment, root `data-tl-theme`, explicit light/dark CSS and `prefers-color-scheme` for System. Keep *selected preference* (System) distinct from *effective appearance* (light or dark).
- Timeline `handle_params/3` sets raw filter params, validates and calls synchronous `load_filtered_page/2`; that function awaits parallel count/page tasks and resets the stream when complete. The accepted delayed test holds a query with no nonempty previous rows. It does not establish that a prior nonempty result is labeled as the new requested scope. Add a seeded nonempty scope, hold a second query, and verify requested scope vs last completed result remain clear until the matching response lands. If query concurrency is later introduced, bind rendered results to request identity so out-of-order completions cannot relabel scope.
- Existing modal/drawer helpers set focus on open and use `JS.pop_focus()` on close. Source markup does not prove actual tab containment, focus return across patch/rerender, or overlapping toast/menu/drawer behavior. CSS z-order has toast at 60 above subview at 50; the toast primitive uses `role="alert"` for all severities and click-away/Escape dismissal. Exercise actual open/close overlap and focus sequences. If status/alert roles change, verify LiveView lifecycle behavior, not just literal markup.
- **Lifecycle guard:** role/status updates that are introduced or changed must be exercised after real LiveView patches and state replacements. A literal HEEx assertion does not prove that a status region is mounted, updated, announced, or still correct after navigation/patch. Check no duplicate/stale announcements and ensure routine info/success feedback does not become assertive interruption without a reason.
- Scope: Phase 239 owns the *shared overlap/focus contract* in home → Timeline → transaction journey: visible focus, predictable Escape/dismissal and focus return, and defined precedence when shared transient UI overlaps. It can establish shared contracts and prove one representative overlap. Phase 240 owns the distinct row-history/drawer investigation journey and its narrow drawer-header composition/reachability fixes (Phase 238 visual candidate V1). Do not absorb full drawer journey repair into Phase 239.
- Actual browser-chrome 200% zoom remains unverified in Phase 238. The feasible proof is a headed real browser at 200% browser zoom with captured zoom/viewport state and checks that controls/content remain usable. `page.setViewportSize`, device pixel ratio changes, and device emulation are not browser zoom. W3C's Reflow explanation uses 400% / 320 CSS px as its WCAG 1.4.10 benchmark; the project separately requires actual 200% zoom, so satisfy the project requirement without claiming a WCAG 400% pass from a 200% sample.

## Exact repository source and test references

All paths below are relative to `the retained current-main worktree`.

Planning and accepted evidence:
- `AGENTS.md` — repository/domain language, layer boundaries, research fanout and zero-human-verification conventions.
- `PRODUCT.md` — user priorities, direct/reload/browser-navigation expectations, exact values, scope/redaction boundaries, canonical terms.
- `.planning/ROADMAP.md:78-91` — Phase 239 goal, requirements, five success criteria; `.planning/REQUIREMENTS.md:17-43` — UIS/UIA statements and owners.
- `.planning/PROJECT.md:35-39` — approved identity/scope; source authority.
- `.planning/research/SUMMARY.md` and `.planning/UI-MILESTONE-PREFLIGHT.md` — reuse research and Scrypath/Accrue/Mailglass lessons; do not restart generic research.
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-HANDOFF.md` — authority/preservation, accepted source/evidence, limitations, phase ownership.
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-BASELINE-FINDINGS.md` — ranked rendered findings and evidence IDs.
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-UI-REVIEW.md` — bounded UI observations and explicit browser/keyboard limits.
- `prompts/audit-lib-domain-model-reference.md`, `prompts/threadline-elixir-oss-dna.md`, `prompts/Threadline Brand Book.txt` — domain boundaries, OSS/Phoenix quality bar, existing typography/identity.

Product source:
- `lib/threadline/operator_surface/style/01_tokens.css:1-75,189-260` — spacing/type/color tokens, invalid paper/ink aliases, light and System lanes.
- `lib/threadline/operator_surface/style/04_controls.css:108-157` — filter form/grid/field intrinsic width rules.
- `lib/threadline/operator_surface/style/09_responsive.css:115-151` — narrow Timeline command/filter rules.
- `lib/threadline/operator_surface/live/timeline_live/filters.ex:26-109,132-150,215-285` — primary filters, advanced drawer, active filter summary/actions.
- `lib/threadline/operator_surface/live/timeline_live.ex:83-178,226-233,349-426` — params/validation/query/reset, Apply URL patch, rendered result/empty-state behavior.
- `lib/threadline/operator_surface/auth.ex:84-92,238-240` — session preference normalization and assignment.
- `lib/threadline/operator_surface/controllers/theme_controller.ex:9-13` — session/cookie preference update.
- `lib/threadline/operator_surface/router.ex:41,89-106` — documented theme configuration and scoped POST endpoint.
- `lib/threadline/operator_surface/ui/page.ex` — shared page hierarchy and status pager.
- `lib/threadline/operator_surface/ui/overlay.ex:60-165,176-195,222-247` — modal/drawer show/hide focus behavior, toast role/dismissal, reconnect status.

Existing test/proof seams:
- `test/threadline/operator_surface/style_contract_test.exs:7-124,1190-1272` — theme lanes, selectors/focus, token/focus contracts; computed visual assertions need browser counterpart.
- `test/threadline/operator_surface/live/start_live_test.exs:597-638` — System/default theme, posted preference persistence and safe redirects.
- `test/threadline/operator_surface/live/timeline_live_test.exs` — Timeline semantics, empty state and URL/query contracts; includes an Escape markup assertion at line 929 and scoped-access cases. These ExUnit assertions do not replace browser interaction proof.
- `test/threadline/operator_surface/ui_test.exs:245-355` — modal/drawer/toast/menu helper markup; insufficient alone for lifecycle/overlap acceptance.
- `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts:94-124` — accepted delayed Timeline query and long-value case; begins without a prior nonempty result and resizes viewport, not browser zoom.
- `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts` — journey navigation/filter/keyboard acceptance seams.
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts:302-474,768-1001` — focus/navigation/theme/menu and overlay keyboard scenarios.
- `examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts:114-132` — real retention dialog Escape/outside dismissal seam.
- `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts:582` — mobile shell dismissal seam.

Sibling-design guidance consulted for planning only: `installed skill: impeccable/reference/operate.md` (earned familiarity, semantic states, structural responsive behavior, no needless dependencies/modals) and `installed skill: emil-design-eng/SKILL.md` (frequent keyboard actions immediate, motion purposeful and short, support reduced motion). No Impeccable initialization was run.

## Primary documentation sources

- W3C WCAG 2.1 Understanding SC 1.4.10 Reflow: https://www.w3.org/WAI/WCAG21/Understanding/reflow
- W3C WCAG 2.2 Understanding SC 4.1.3 Status Messages: https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html
- W3C WAI-ARIA APG Dialog (Modal) Pattern: https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/
- W3C WAI-ARIA APG Menu Button Pattern: https://www.w3.org/WAI/ARIA/apg/patterns/menu-button/
- Phoenix LiveView `handle_params/3` and lifecycle: https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html
- Playwright Page API (`setViewportSize` is page resize): https://playwright.dev/docs/next/api/class-page
- Chrome DevTools Device Mode documents viewport/DPR simulation and limitations: https://developer.chrome.com/docs/devtools/device-mode

No major architect-level decision remains unresolved. The unverified browser-zoom method is a proof implementation detail, not a scope question. No actual 200% zoom pass is claimed.
