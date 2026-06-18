---
phase: 177-component-groups-meta-components
reviewed: 2026-06-18T00:00:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - DESIGN-SYSTEM.md
  - brandbook/tokens.css
  - brandbook/tokens.json
  - lib/threadline/operator_surface/stress_fixtures.ex
  - lib/threadline/operator_surface/style.ex
  - lib/threadline/operator_surface/ui.ex
  - test/threadline/brandbook_token_parity_test.exs
  - test/threadline/operator_surface/live/row_history_live_test.exs
  - test/threadline/operator_surface/stress_fixtures_test.exs
  - test/threadline/operator_surface/stress_router_test.exs
  - test/threadline/operator_surface/style_contract_test.exs
  - test/threadline/operator_surface/ui_stress_test.exs
  - test/threadline/operator_surface/ui_test.exs
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 177: Code Review Report

**Reviewed:** 2026-06-18
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Reviewed the Phase 177 meta-component work: five new internal Phoenix function
components (`stack`, `cluster`, `toolbar`, `detail_header`, `data_panel`), the
breadcrumb-trail truncation extension, the overlay/offline motion CSS, semantic
`--tl-gap-*` token parity across `style.ex`/`tokens.css`/`tokens.json`, and the
expanded stress-fixture group registry.

The phase invariants hold well. I verified: zero new runtime deps; no
`String.to_atom`/`to_existing_atom` on user input; no inline `on*=` handlers (all
JS via `Phoenix.LiveView.JS`); no Tailwind/animation-lib markers; no raw hex,
`min-width` literals, or ungoverned `\d+ms` in the *new* CSS (token discipline is
clean per the StyleContract source-governance assertions); and brand-token gap
parity is present in all three sources. Capture/semantics layers are untouched.

No blockers. The findings below are correctness/robustness defects in the new
meta-components plus a real z-index layering regression in the new toast CSS.

## Warnings

### WR-01: New `.tl-toast` uses `--tl-z-subview` (50) instead of the dedicated `--tl-z-toast` (60) — toasts render behind the sticky topbar/skip-link and any modal/drawer at the same layer

**File:** `lib/threadline/operator_surface/style.ex:3369-3373`
**Issue:** The token catalog defines a dedicated stacking layer `--tl-z-toast: 60`
(line 147) precisely so notifications sit above every other surface. The new
`.tl-toast` rule instead stacks at `z-index: var(--tl-z-subview)` (50), the SAME
layer as `.tl-modal-container`/`.tl-drawer-container` (line 3317). The sticky
topbar and skip-link already paint at `--tl-z-toast` (60, lines 383/441), so a
fixed bottom-right toast will be occluded by the topbar where they overlap, and a
toast raised while a modal/drawer is open has undefined paint order (equal
z-index, later-in-DOM wins). This defeats the purpose of the toast layer token.
**Fix:**
```css
.tl-toast {
  position: fixed;
  right: var(--tl-space-4);
  bottom: var(--tl-space-4);
  z-index: var(--tl-z-toast); /* was: var(--tl-z-subview) */
  ...
}
```

### WR-02: `data_panel` with `state={:permission}`/`:unavailable` and no `reason` silently collapses to a generic error, defeating the component's load-bearing contract

**File:** `lib/threadline/operator_surface/ui.ex:790-821` (dispatch) and `635-685` (`data_state/1`)
**Issue:** `data_panel/1` declares `attr(:reason, :atom, default: nil)`. In the
`:permission`/`:unavailable` branch it calls `<.data_state reason={@reason} .../>`.
`data_state/1` only special-cases known atoms (`:unauthorized`, `:source_down`,
`:redacted`, `:pruned`, …); any other value — including `nil` — falls through to
the catch-all clause that renders the generic "Could not load this timeline"
`error_state`. So a caller that sets `state={:permission}` but forgets `reason`
gets a generic error, silently erasing the permission-vs-unavailable-vs-no-data
forensic distinction the component's own docstring promises to "NEVER convert to a
generic empty" (D-176-16). The failure is invisible — it renders successfully with
the wrong message. The component should fail loudly or constrain `reason`.
**Fix:** Make the dependency explicit so a missing/invalid reason cannot pass
silently, e.g. validate at render time:
```elixir
def data_panel(%{state: s, reason: nil} = assigns) when s in [:permission, :unavailable] do
  raise ArgumentError,
        "data_panel state=#{inspect(s)} requires a typed :reason " <>
          "(e.g. :unauthorized, :source_down, :redacted, :pruned)"
end

def data_panel(assigns) do
  # existing body
end
```
(Or document `reason` as required-when-state-is-permission/unavailable and add a
test asserting the distinct heading actually renders, not just `role="alert"`.)

### WR-03: `.tl-data-panel__region` declares an opacity cross-fade transition that nothing triggers — the documented state cross-fade does not actually occur

**File:** `lib/threadline/operator_surface/style.ex:2152-2155`
**Issue:** The new region rule sets `transition: opacity var(--tl-motion-fast)
var(--tl-ease-standard)` and the comment (style.ex:2146-2151) claims the region
"cross-fades on a state swap (happy <-> loading <-> empty <-> error)". But
`data_panel/1` swaps states by re-rendering different child markup inside the
`cond` — it never toggles the element's `opacity` (no `opacity-0`/`opacity-100`
class flip, no keyframe, no per-state class on `.tl-data-panel__region`). A
`transition` only animates when a transitioned property's *value* changes; opacity
here is always the default `1`, so the swap is an instant snap, not a fade. The CSS
is inert/aspirational and the comment overstates behavior. Either wire the fade
(e.g. a `data-state`-keyed opacity or a JS.transition on swap) or drop the dead
declaration and the misleading comment.
**Fix:** Remove the inert rule, or implement the fade — e.g. key opacity off the
already-present `data-state` attribute and toggle via `Phoenix.LiveView.JS` on the
state change, matching the modal/drawer transition pattern used elsewhere in this
file.

## Info

### IN-01: `stat_tile`/`empty_state` accept a `signal` status/variant with no matching `.tl-card--metric[data-status="signal"]` stripe

**File:** `lib/threadline/operator_surface/ui.ex:371-374` (and `style.ex:2228-2242`)
**Issue:** `stat_tile`'s `status` attr allows `"signal"` and `ui_stress_test.exs`
exercises it, but `.tl-card--metric` only defines stripe rules for `danger`,
`warning`, `success`, `info` (style.ex:2228-2242). A `signal` tile emits
`data-status="signal"` with no visual treatment. This is a pre-existing gap (the
metric-card CSS is not in this phase's diff), noted for completeness — low impact
since the value is accepted and renders, just without a stripe.
**Fix:** Add a `signal` stripe rule (or remove `signal` from the accepted values if
unused for metrics).

### IN-02: `data_panel` ignores `as_of` for the `:no_data`/`:empty`/`:error` inner states

**File:** `lib/threadline/operator_surface/ui.ex:805-813`
**Issue:** The stale banner is correctly rendered above the region for every state
(`<.stale_banner :if={@as_of} .../>`), and `as_of` is threaded into
`data_state/1` for `:permission`/`:unavailable`. But the `:no_data` branch calls
`<.data_state reason={:no_data} />` without `as_of`, and `:empty`/`:error` render
hardcoded copy. This is consistent with the documented "stale banner sits above"
rule, so it is not a bug — but the `pruned`/retention sub-case timestamp is only
reachable via the `:permission`/`:unavailable` path, which may surprise a caller
expecting `as_of` to flow into a `:no_data` retention message. Documentation-level
note only.
**Fix:** None required; consider a doc note clarifying that `as_of` reaches the
inner message only for `:permission`/`:unavailable`.

### IN-03: `breadcrumb_trail/1` computes `last_index = length(crumbs) - 1` which is `-1` for an empty list

**File:** `lib/threadline/operator_surface/ui.ex:260-261`
**Issue:** `assign(assigns, :last_index, length(assigns.crumbs) - 1)` yields `-1`
for `crumbs == []`. It is currently safe because the only caller,
`page_header/1`, guards with `:if={@breadcrumbs != []}` (ui.ex:241), so the
component never receives an empty list. Flagged as latent: `breadcrumb_trail/1` is
private and the guard lives at the single call site, so a future second caller
could pass `[]` and silently render an empty `<nav>` (harmless, but the
`-1`-vs-index comparison is brittle).
**Fix:** Defensive guard inside the component, e.g. render nothing when
`@crumbs == []`, decoupling correctness from the caller's guard.

---

_Reviewed: 2026-06-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
