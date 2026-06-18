---
id: SEED-005
status: open
planted: 2026-06-18
planted_during: Phase 177 UAT shift-left automation
scope: Small
target_phase: 178
---

# Reconnect / offline banner — mount in the operator shell

**Domain:** Operator surface shell (`lib/threadline/operator_surface/`)
**Status:** Open implementation follow-up — surfaced while automating Phase 177 UAT #4.

## What's missing

`Threadline.OperatorSurface.UI.reconnect_banner/1` exists and its CSS contract is
correct and proven to compute (hidden by default; revealed under
`.threadline-ui.phx-loading` / `.phx-error`; sibling `[data-tl-mutating]` controls
dim to `opacity:.55; pointer-events:none`). **But the banner is never mounted** — not
in the shell, not in any live page, not in the `group.offline.current` stress story.
Likewise, no real mutating control currently carries `data-tl-mutating`.

So a live socket drop today produces **no on-page banner and no disabled controls** —
the behavior is implemented at the component+CSS level but not wired into the surface.

## Done-when

- `reconnect_banner/1` is rendered once at the shell level (above `#tl-main`, inside
  `.threadline-ui`) so it reveals on a dropped socket across every operator page.
- Real mutating controls carry `data-tl-mutating` (start with the retention prune
  button in `retention_history_live.ex`; audit other mutating buttons/links — links
  also need `aria-disabled="true" tabindex="-1"` per the Pitfall-6 note in `ui.ex`).
- A true socket-drop e2e replaces the current computed-CSS *probe*: in
  `examples/threadline_phoenix/e2e/tests/operator-phase-177-uat.spec.ts` UAT #4, drop
  the LiveView socket (or force `.phx-error`) and assert the *real* banner element
  becomes visible and the *real* mutating control disables — then remove the
  inject-markup probe.

## Why it's a seed, not a blocker

Phase 177's acceptance is the component + CSS contract, both verified
(`component_contract_test.exs`). Mounting is shell/flow-level behavior that belongs to
Phase 178 (per-page & flow stress pass), where shell offline behavior is exercised
across all 11 pages. Pull this into 178 planning. See
`.planning/threads/2026-06-18-shift-left-uat-173-175.md` and
`177-VERIFICATION.md` (follow_up).
