# Phase251 implementation research

Source-only research at accepted post250 `af4ec7afe606b193eb634d64b5451d9d1a1639b2`; no fresh tests/browser/DB result is claimed. Three independent current-source memos and prior accepted research resolve the existing jobs without a new API/dependency or major user decision.

## Recommendation and source drift

Use two coherent vertical groups: navigation/history (ADM15/18/19) and selected-schema inspection (ADM20/21/22). Phase250 already fixed valid Timeline/transaction/history return context, raw filter preservation, explicit unfiltered marker, path-table identity and drawer copy/title placement; its current brand/font/theme foundation is shared. Do not repeat the old defect or Acme journey as proof of remaining cases.

1. Expose malformed nonemptyas_of instead of choosing latest. Preserve missing/blank defaults and valid deletion/horizon semantics at both history entry routes and the component.
2. Prevent unsupported-only direct UI input or malformed saved filters becoming an unfiltered query. Keep FilterParams.parse/1's explicit unknown-key-dropping contract for shared callers and atom safety; validate at existing UI/saved-view boundaries before canonicalizing. Preserve deliberate from= intent. Existing invalid retained context still recovers safely to bare Timeline, with a visible explanation rather than a false promise of preserved filters.
3. Prove existing Home, saved-view, direct/reload/back and nonhuman/absent actor semantics through actual owning paths, without a new lookup or composite-key navigation.
4. Keep Coverage selected-schema facts/current shared badge consistent; zero or expected-only rows never imply global capture completeness. Preserve stale/changed-schema failure/auth/disabled/read boundaries and safe remediation.
5. Align zero-policy Redaction copy, configured/deployed/current-definition source/time and Left out versus Redacted meanings. Preserve missing-trigger drift/unreadable/unavailable differences and normalize unexpected error details safely.
6. Label Evidence snapshot recording time and display only a bounded recorded-provenance summary. Caller-overridable metadata is not authenticated origin; arbitrary maps/detail/actor IDs stay hidden.

## Independent evidence and tradeoffs

- [Navigation drift](../../../research/2026-11-12-phase251/navigation.md) — existing route/parser/component/proof owners and valid actor semantics.
- [Inspection drift](../../../research/2026-11-12-phase251/inspection.md) — three page/state/read/privacy boundaries, exact existing gaps and stable IDs.
- [Adversarial synthesis](../../../research/2026-11-12-phase251/adversarial.md) — unfiltered-query and malformed saved-view/context risks, scope coherence and proof groups.

These memos include pros/cons, concrete source/negative-test owners, compatibility/security/SRE/DX/accessibility lenses and252/253 dependencies. Current code/source resolved the questions; installed Phoenix LiveView is1.1.33. Older prefetch links to newer LiveView docs do not authorize new APIs.

## Verification and implementation guidance

Use existing LiveView/HEEx/private helpers and typed UI composition. Stable249 inventory IDs survive source-anchor migration; couple the generic source checklist/route inventory, semantic locator tests and structure receipts to any actual changed owner before narrow plan acceptance. Keep independent discovery and malformed/duplicate/ownership negative controls unchanged.

Map each deliverable to the smallest existing meaningful ExUnit/live/DB/browser boundary. New visible/state behavior needs a matched before/after route/scenario capture, current runtime source before startup, served asset identity, actual fixture/clock/browser/theme/viewport and exact nonzero first-attempt title set. Reuse250 evidence only where source-compatible. Static Storybook rendering does not establish live/auth/DB behavior. Use only controlled clipboard doubles where needed; no native clipboard permissions, foreground activation, new runner/dependency/cache/concurrency or broad cross-product proof by default.

Preserve original250 materialization/capsules and shared-computer custody. Prepare a dedicated test/example partition before checks, capture actual versions/locks/process exits and use managed background sessions. No whole-root repeat is renewed. Plan useful Nyquist coverage and authored threat ownership, formal code review and six-pillar UI outputs at the first review dispatch; use bounded delta confirmation after actual fixes, not a later format-only handoff. Phase253 retains its comprehensive inclusive/zoom/error-pixel/docs/package/release acceptance, and REL-01 retains its live external trigger.

## Boundaries not to infer

No authenticated provenance, all-schema UI, new public API/routes/query names/schema/config, actor lookup/composite keys, backend capture change, login/white-label, React/Fablebook, package/version/hosted action or risk/publication authority. Existing font/theme/schema callbacks and host scope remain authoritative. Routine private reversible choices use the coherent context; there is no open user decision.

## Validation Architecture

Extend existing ExUnit/live owners for navigation (query/filter_params; operator_surface/live/timeline_live, start_live, actor_live; operator_surface/transaction_live; existing history owners), and inspection (operator_surface/live/coverage_live, policy_redaction_live, evidence_live). Use `mix verify.test` with explicit existing paths and isolated Phase 251 test partitions; preserve shared FilterParams compatibility with negative controls. Existing Node inventory contracts and Playwright route-state/earned-flow/coverage owners supply the coupled structural and real-route boundaries. Before first execution, resolve exact history paths and selected browser title sets from tracked files; no invented command paths. Compile with warnings as errors and run the named formatter on changed files.

Use scoped task checks after source changes, the selected combined regression after each coherent group, and matched before/after evidence only for changed scenarios. No whole-root repeat is authorized. Source/rendered/live/browser/catalog results remain separate. The execution plans fill the per-task commands and threat references into the validation map before execution; no test or runtime result is claimed by this strategy.
