---
phase: 178-per-page-flow-stress-pass-all-11-pages
plan: 02
subsystem: operator-surface
tags: [operator-surface, seed-005, shared-shell, reconnect-banner, data-tl-mutating, integration]
requires:
  - "lib/threadline/operator_surface/ui.ex (reconnect_banner/1, surface_header/page_header composition, Pitfall-6 mutating-link contract)"
  - "lib/threadline/operator_surface/style.ex:3405-3424 (reconnect/offline CSS keyed off .threadline-ui.phx-loading/.phx-error — read-only, not edited)"
  - "test/threadline/operator_surface/component_contract_test.exs (Wave-0 reconnect-banner-mounted-once RED contract)"
provides:
  - "UI.shell/1 — the single @doc false shared shell/chrome component for all 11 operator LiveViews (D-10)"
  - "reconnect_banner/1 mounted exactly once, above #tl-main inside .threadline-ui (D-10/D-11) — Wave-0 reconnect-mount contract now GREEN"
  - "data-tl-mutating wired on the D-12 control set (prune_now submit, save-view submit, delete-view button) + the download links (with aria-disabled/tabindex per Pitfall-6)"
affects:
  - "all 11 operator LiveViews (render-tree refactor — route chrome through UI.shell)"
  - "lib/threadline/operator_surface/style.ex (NOT edited — CSS already correct)"
tech-stack:
  added: []
  patterns:
    - "Single shared @doc false chrome component (kills 11-way wrapper drift, D-10)"
    - ":if={@base_path} gate on surface_header preserves the conditional-header pages byte-for-byte"
    - "data-tl-mutating as a disconnect-time affordance marker (CSS dims via .phx-loading/.phx-error), never enforcement"
key-files:
  created: []
  modified:
    - "lib/threadline/operator_surface/ui.ex"
    - "lib/threadline/operator_surface/live/start_live.ex"
    - "lib/threadline/operator_surface/live/timeline_live.ex"
    - "lib/threadline/operator_surface/live/transaction_live.ex"
    - "lib/threadline/operator_surface/live/row_history_live.ex"
    - "lib/threadline/operator_surface/live/actor_live.ex"
    - "lib/threadline/operator_surface/live/coverage_live.ex"
    - "lib/threadline/operator_surface/live/evidence_live.ex"
    - "lib/threadline/operator_surface/live/policy_redaction_live.ex"
    - "lib/threadline/operator_surface/live/retention_history_live.ex"
    - "lib/threadline/operator_surface/live/export_status_live.ex"
    - "lib/threadline/operator_surface/live/stress_live.ex"
decisions:
  - "Shell name = UI.shell/1; slots/attrs: theme, header_theme (defaults to theme), current, coverage, base_path (nilable), error, *_enabled, scoped, script, main_class, main_rest (:global incl data-testid), inner_block"
  - "base_path made nilable + surface_header gated on :if={@base_path} so evidence/policy_redaction/retention_history/export_status keep their original conditional-header behavior byte-for-byte"
  - "Added :header_theme so stress_live keeps its selected_theme root + host-theme nav divergence; defaults to :theme so the other 10 pages are unaffected"
  - "stress_live routed too (the contract test enforces all 11) via fully-qualified Threadline.OperatorSurface.UI.shell — no new alias added, matching its existing fully-qualified style"
  - "Download links carry static aria-disabled/tabindex per the explicit D-12 must_have + Pitfall-6 contract example (ui.ex:1071)"
metrics:
  duration: "~30 min (continuation: Task 1 pre-committed; this run finished Task 2 + Task 3)"
  completed: "2026-06-18"
  tasks: 3
  files_changed: 12
status: complete
---

# Phase 178 Plan 02: Shared shell + reconnect-banner mount + data-tl-mutating wiring (SEED-005) Summary

Landed SEED-005 structurally: extracted the 11-way-duplicated `<div class="threadline-ui">…surface_header…<main id="tl-main">` chrome wrapper into one internal `@doc false` `UI.shell/1` component, routed all 11 operator LiveViews through it, mounted `reconnect_banner/1` exactly once (above `#tl-main`, inside `.threadline-ui`), and wired `data-tl-mutating` onto the genuine state-changers — turning the Wave-0 reconnect-banner-mounted-once RED contract GREEN while leaving the server-side prune enforcement byte-for-byte untouched.

## What was built

**Task 1 — shared shell + banner mount (commit `087c33d`, pre-committed by a prior run; extended this run):**
- `UI.shell/1` `@doc false` chrome component in `ui.ex`: `<div class="threadline-ui">` root → `Style.css` → optional `Script.js` (`:script`) → `surface_header` → `reconnect_banner/1` (mounted ONCE) → `<main id="tl-main">` wrapping `inner_block`.
- This run hardened the shell so it could carry all 11 pages losslessly:
  - `base_path` made nilable; `surface_header` gated on `:if={@base_path}` to preserve the four conditional-header pages.
  - Added `:header_theme` (defaults to `:theme`) for the stress lab's root-vs-nav theme divergence.
  - Reworded the shell/banner doc comments so they no longer contain the literal forbidden strings (`reconnect_banner` extra reference, `.phx-disconnected`, `body.phx-`) that the Tier A contract scans for.

**Task 2 — route all 11 LiveViews (commit `a38d1b3`):**
- Replaced the inline wrapper in `start`, `timeline`, `transaction`, `row_history`, `actor`, `coverage`, `evidence`, `policy_redaction`, `retention_history`, `export_status`, `stress` LiveViews with a `UI.shell` call.
- Per-page `<main>` class preserved via `:main_class` (e.g. `tl-page tl-home`, `tl-page tl-container`, `tl-page tl-stress`); page-specific `<main>` attrs (`data-earned-flow`/`data-persona`/`data-jtbd`, `data-testid="stress-lab"`) ride `:main_rest`.
- Pure render-tree refactor: no `handle_event`, `mount`, or assign logic changed.

**Task 3 — data-tl-mutating wiring (commit `fb4b742`):**
- `data-tl-mutating` on the prune_now submit (`retention_history_live.ex`), the save-view submit and the delete-view button (`timeline_live.ex`) — genuine DB mutations.
- `data-tl-mutating` PLUS `aria-disabled="true" tabindex="-1"` on the timeline CSV/JSON/NDJSON download links and the export download link (`export_status_live.ex`) — links can't take HTML `disabled` (Pitfall-6).
- No-op export "queue" stubs (`request_background_export`, `queue_timeline_export_context`) and read-only `policy_redaction_live.ex` left unwired (D-12).

## Shell component contract

- **Name:** `UI.shell/1` (`Threadline.OperatorSurface.UI.shell`), `@doc false` — no public/host-facing API (v1.31 freeze).
- **Attrs:** `theme`, `header_theme` (defaults to `theme`), `current`, `coverage` (default `%{uncovered_count: 0}`), `base_path` (nilable), `error`, `coverage_enabled`/`policy_enabled`/`evidence_enabled`/`exports_enabled`, `scoped`, `script`, `main_class` (default `"tl-page"`), `main_rest` (`:global`, incl `data-testid`).
- **Slot:** `inner_block` (required) → the former `#tl-main` body.

## data-tl-mutating control set (exactly D-12)

| Control | File | Attribute(s) |
|---------|------|--------------|
| prune_now submit | retention_history_live.ex | `data-tl-mutating` |
| save-view submit | timeline_live.ex | `data-tl-mutating` |
| delete-view button | timeline_live.ex | `data-tl-mutating` |
| CSV download link | timeline_live.ex | `data-tl-mutating` + `aria-disabled="true"` + `tabindex="-1"` |
| JSON download link | timeline_live.ex | `data-tl-mutating` + `aria-disabled="true"` + `tabindex="-1"` |
| NDJSON download link | timeline_live.ex | `data-tl-mutating` + `aria-disabled="true"` + `tabindex="-1"` |
| export download link | export_status_live.ex | `data-tl-mutating` + `aria-disabled="true"` + `tabindex="-1"` |
| ~~request_background_export~~ (no-op stub) | timeline_live.ex | none (skipped, D-12) |
| ~~queue_timeline_export_context~~ (no-op stub) | export_status_live.ex | none (skipped, D-12) |
| ~~policy_redaction controls~~ (read-only) | policy_redaction_live.ex | none (D-12) |

Counts confirmed: retention=1, timeline=5, export_status=1, policy_redaction=0.

## Security — prune handler diff is empty

`retention_history_live.ex handle_event("prune_now", …)` (the `secure_compare` + authz re-check + scope fail-closed + audit path) is **byte-for-byte unchanged**. `git diff HEAD` over the server-handler region returns no `secure_compare`/`handle_event`/`authz`/`scope`/`canonical` line changes; the only edit to the file is the single `data-tl-mutating` attribute on the submit button. `data-tl-mutating` is a disconnect-time affordance (CSS `pointer-events:none`/`opacity:.55` under `.phx-loading`/`.phx-error`), never the enforcement gate.

## RED → GREEN deltas

| Assertion | Before (Wave-0) | After this plan |
|-----------|-----------------|-----------------|
| reconnect-banner-mounted-once shared shell (SEED-005, D-10/D-11) | RED (0 banners, no shell) | **GREEN** |
| no `<body>`/`.phx-disconnected` anchor (D-11) | GREEN-confirming | GREEN (held) |
| every page routes through `UI.shell`, no per-page `.threadline-ui`/`#tl-main` | RED (only transaction mid-edit) | **GREEN** (all 11) |

Full `operator_surface` suite: **591 tests, 6 failures**, all 6 the documented cross-plan RED scaffolds owned by other plans (NOT this plan):
1. PAGE-01 page-story conversion → Plan 04
2. PAGE-02 #6 `.tl-timeline-fact` spacing token → Plan 04
3. PAGE-03 `.tl-home` twin centering → Plan 03
4. PAGE-02 #4 scrim click-outside dismiss → Plan 05 Task 2
5. PAGE-03 `.tl-container` centering → Plan 03
6. PAGE-02 #1 desktop scroll reconciliation → Plan 04

Wave-0 reported 7 failures; we are at 6 — exactly the reconnect-banner-mounted-once flip this plan owned.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Shell doc comment contained the literal forbidden anchor strings the Tier A contract scans for**
- **Found during:** Task 2 (running `component_contract_test.exs` against the committed Task 1 shell)
- **Issue:** The shell/banner doc comments in `ui.ex` (committed in `087c33d`) literally contained `reconnect_banner` (an extra reference, pushing the banner-mount count to 2), `.phx-disconnected`, and the example `<.reconnect_banner />` — tripping the "mounted EXACTLY once" count and the "no `.phx-disconnected` anchor" guard (which `String.contains?`-scans the ui.ex source).
- **Fix:** Reworded the doc comments to describe the same intent without the literal forbidden tokens (e.g. "the legacy pre-1.0 disconnected class", "the banner component below").
- **Files modified:** `lib/threadline/operator_surface/ui.ex`
- **Commit:** `a38d1b3`

**2. [Rule 3 — Blocking] Shell could not losslessly carry the four conditional-header pages or the stress lab**
- **Found during:** Task 2 (reading evidence/policy_redaction/retention_history/export_status — all gate `surface_header` behind `<%= if @base_path do %>`; stress_live diverges its root `data-tl-theme` (`selected_theme`) from its nav theme (`threadline_theme`)).
- **Fix:** Made `base_path` nilable + gated `surface_header` on `:if={@base_path}` (mirrors the original per-page conditional); added `:header_theme` (defaults to `:theme`) for stress. Both preserve byte-for-byte rendering for the pages that don't use them.
- **Files modified:** `lib/threadline/operator_surface/ui.ex`
- **Commit:** `a38d1b3`

### Notes / latitude exercised (within plan)
- **Static `aria-disabled="true" tabindex="-1"` on download links.** Followed the explicit D-12 `must_have` and the Pitfall-6 contract example (`ui.ex:1071`), which show the attributes set statically. Observed that this makes the download links permanently `aria-disabled` (not only during disconnect); kept the plan-prescribed static form rather than inventing a dynamic toggle, since the plan and the in-code contract are prescriptive and unambiguous here. The disconnect-time dimming is driven separately by the CSS keyed off `data-tl-mutating`.
- **stress_live routed (not left bespoke).** The plan allowed leaving stress bespoke "if its chrome differs materially," but the Tier A contract (`component_contract_test.exs:318-330`) enforces all 11 (including `stress_live.ex`) routing through `UI.shell`. Routed it via the fully-qualified `Threadline.OperatorSurface.UI.shell` (matching its existing fully-qualified component style — no new alias).

## Scratch-file note (not committed)

A prior interrupted run left untracked scratch files in the working tree (`.git-commit-task1.sh`, `.git-commit-task2.sh`, `.update_roadmap.rb`, `fix_theme.exs`, `.planning/v1.37-MILESTONE-AUDIT.md`). These were **not** part of this plan and were **not** staged or committed; they remain untracked debris for separate cleanup.

## Verification

- `mix compile --warnings-as-errors` — clean.
- `mix format --check-formatted` — clean.
- `mix credo --strict` — 2132 mods/funs, no issues.
- `mix test test/threadline/operator_surface/component_contract_test.exs` — reconnect-banner-mounted-once GREEN (only the #4-scrim cross-plan RED remains).
- `mix test test/threadline/operator_surface/` — 591 tests, 6 failures (all documented cross-plan RED scaffolds).
- `mix test test/threadline/brandbook_token_parity_test.exs` — 4 tests, 0 failures (zero new tokens).
- Capture & semantics layers: `git diff --name-only HEAD` shows all code changes confined to `operator_surface`.

## Self-Check: PASSED

- `lib/threadline/operator_surface/ui.ex` (UI.shell) — FOUND (`def shell(assigns)` present)
- All 11 LiveViews route through `UI.shell` — FOUND (grep: 2 references each, 0 inline `threadline-ui`/`tl-main`)
- Commit `087c33d` (Task 1) — FOUND
- Commit `a38d1b3` (Task 2) — FOUND
- Commit `fb4b742` (Task 3) — FOUND
</content>
</invoke>
