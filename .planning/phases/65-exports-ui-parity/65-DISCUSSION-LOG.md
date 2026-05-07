# Phase 65: Exports UI Parity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-06
**Phase:** 65-exports-ui-parity
**Areas discussed:** Click mechanism, Match-count preview UX, Controller routing + auth wiring, JSON variant exposure
**Discussion mode:** Default — research-then-recommend (per saved memory). Three parallel general-purpose research subagents dispatched before the first user-facing question.

---

## Click Mechanism (D-15)

| Option | Description | Selected |
|--------|-------------|----------|
| Option 1 — `phx-click` event → `redirect(socket, external: …)` | LV event handler builds the export URL and redirects | |
| Option 2 — Plain `<.link href={…}>` anchor | Browser GET; `Content-Disposition: attachment` keeps operator on the LV | ✓ |
| Option 3 — Form double-submit (second submit on the filter form) | Same form, branched on a hidden value | |

**User's choice:** Option 2 — plain anchor.
**Rationale:** Phoenix LiveView PR #2611 specifically fixed `wantsNewTab()` so anchors with `download=` / `Content-Disposition: attachment` no longer tear down the LV socket. Datadog Audit Trail, Sentry Discover Export, GitHub Audit Log all use this pattern. Option 1 is the documented footgun (LV process tears down mid-export, scroll/cursor/filter state lost). Option 3 conflates URL state mutation with file delivery and breaks the Phase 64 URL contract.
**Notes:** `<.link>` is already imported in TimelineLive for the `[Clear all]` link — zero new import surface. The href is computed at render time from the LV's current filter assigns, which makes the "operates on currently-rendered filter set" requirement a trivial string-format operation.

---

## Match-Count Preview UX (D-16, D-17, D-18, D-23)

### Sub-dimension A — When is `count_matching/2` invoked?

| Option | Description | Selected |
|--------|-------------|----------|
| A1 — Always-on, computed concurrently with `timeline_page` on every Apply | Two parallel Repo calls; total latency = max(count, page) | ✓ |
| A2 — Lazy, computed on hover/focus of download button | Saves the query unless export is imminent | |
| A3 — Lazy, computed on first download click + confirmation step | Two-click commit flow | |
| A4 — Async via `Task.async` + `send(self(), :count)` | Timeline rows render first; count appears 100-300ms later | |

### Sub-dimension B — Where is the count shown?

| Option | Description | Selected |
|--------|-------------|----------|
| B1 — Inline in the toolbar near the download buttons | "3,142 matches • Download CSV" | |
| B2 — Above the timeline as a status line | "Showing 50 of 3,142 matches in this window" | ✓ |
| B3 — Pre-download confirmation banner on hover/click | Surfaces only on intent | |
| B4 — Always-visible badge in the surface header | Parity with Phase 66 coverage dashboard's planned header badge | |

### Sub-dimension C — Truncation banner shape

| Option | Description | Selected |
|--------|-------------|----------|
| C1 — Show only when count > 10k | Single warning ("Truncated to first 10,000 rows") | |
| C2 — Two bands — >5k informational, >10k warning | Distinct messages, distinct visual weight | ✓ |
| C3 — Show only the truncation warning, no chunked notice | Operator doesn't care about transport | |

**User's choice:** A1 + B2 + C2.
**Rationale:** The count IS the filter-correctness signal forensics operators need — hiding it behind hover/click reverses cause and effect. GitHub Audit Log, Datadog Logs Explorer, BigQuery preflight, and Oban Web all surface counts always on every filter change. B2 (above-timeline status line) makes the count a property of the result set, not export metadata — useful for both browsing and export. C2 honors that the 5k and 10k thresholds have different remedies (wait longer vs use Mix task); collapsing them deprives the operator of the info that changes their next action. D-23 captures the degraded-count fallback for huge unfiltered windows.
**Notes:** Run count + timeline_page in parallel (Task.async_stream or two parallel Repo calls) so total latency is `max`, not `sum`. Degrade to "10,000+ matches" via `EXISTS LIMIT 10001` cap rather than erroring the LV when `statement_timeout` would otherwise trip.

---

## Controller Routing + Auth Wiring (D-19, D-20, D-21)

### Sub-dimension A — How does the controller mount inside the macro?

| Option | Description | Selected |
|--------|-------------|----------|
| A1 — Same `threadline_operator_surface` macro emits both LV routes and a controller scope | One mount call, both wirings | ✓ |
| A2 — Companion `threadline_operator_surface_exports` macro | Explicit opt-in, two mount lines | |
| A3 — Separate scope inside the macro driven by `:pipe_through` | Effectively collapses to A1 | |

### Sub-dimension B — How is `:authorize_fn` reused for HTTP requests?

| Option | Description | Selected |
|--------|-------------|----------|
| B1 — Widen `:authorize_fn` to accept `socket \| conn`, dispatch on struct | Breaks v1.17 contract for pattern-matched adopter functions | |
| B2 — New `:export_authorize_fn` opt; default = thin Conn-shaped adapter wrapping the existing `:authorize_fn` | Additive; preserves v1.17 contract verbatim | ✓ |
| B3 — `Threadline.OperatorSurface.AuthPlug` calling existing `:authorize_fn.(conn)` | Hides B1's contract widening in a Plug | |
| B4 — Document `:authorize_fn` accepts socket-or-conn; dispatch on `assigns` | Same problem as B1, pushed to adopter | |
| B5 — Macro accepts `:plug` opt; adopters re-pipe their existing pipeline | Raises adoption floor | |

### Sub-dimension C — File-scope gating for the controller

| Option | Description | Selected |
|--------|-------------|----------|
| C1 — Gate on `Phoenix.LiveView` (parity with surface) | Couples two independent optional deps | |
| C2 — Gate on `Phoenix.Controller` (strictly correct) | Capture-only-plus-Controller adopter works | ✓ |
| C3 — Gate on BOTH | File compiles iff surface as a whole is wired | |

**User's choice:** A1 + B2 + C2.
**Rationale:** A1 keeps the v1.17 one-line mount contract intact — exports just appear under the same path with the same auth boundary. B2 keeps the `:authorize_fn.(socket)` contract frozen (LV-shaped, advertised in Phase 62) and ships a sensible default Conn-shaped adapter; B1/B3/B4 silently break adopters whose function pattern-matches on `%Phoenix.LiveView.Socket{}`. C2 is strictly correct — the controller depends only on `Phoenix.Controller`/`Plug`, not on LiveView, so gating per actual dep (rather than coupling) keeps `mix verify.compile_no_optional` honest.
**Notes:** Threadline already ships `Threadline.Plug` with `:actor_fn` / `:context_overrides_fn` Conn-shaped callbacks (separate from any LV equivalent). `:export_authorize_fn` follows that in-house precedent. Add `:exports` boolean opt (default `true`) so the rare LV-only adopter can disable. `live_session`-level `on_mount` does NOT apply to `get/3` routes — controller scope needs its own pipeline.

---

## JSON Variant Exposure (D-22)

| Option | Description | Selected |
|--------|-------------|----------|
| Option 1 — One `[Download JSON]` button (wrapped only) | Hides NDJSON entirely; deferred to Mix task | |
| Option 2 — `[Download JSON]` + `?json_format=ndjson` URL knob | NDJSON for power-users | |
| Option 3 — `[Download JSON]` + checkbox toggle in toolbar | Two affordances + one switch | |
| Option 4 — Three buttons: `[Download CSV] [Download JSON] [Download NDJSON]` | Visible parity with Mix task's three callable shapes | ✓ |

**User's choice:** Option 4 — three buttons.
**Rationale:** EXPO-04 explicitly requires NDJSON parity with the Mix task. The Mix task uses a flag (`--json-format ndjson`); the UI's analog of a flag is a separate visible affordance. Hiding NDJSON behind a URL param or a checkbox surprises operators who expect the Mix task and UI to expose the same shape. Three buttons is honest, even if it's one more than Phase 64's forward-looking sketch.
**Notes:** Cluster grows from `[Clear all] [Apply]` (Phase 64) → `[Clear all] [Apply] [Download CSV] [Download JSON] [Download NDJSON]`. Filenames: `.csv`, `.json`, `.ndjson`.

---

## Claude's Discretion

- Exact CSS class names and visual styling for the count status line, truncation banners, and download cluster — extend `.threadline-ui` namespace + CSS-variable convention. No Tailwind, no JS framework.
- Exact button label literals (must match doc-contract test literals — planner picks, test pins).
- Exact wording of chunked + truncation banner copy (terse, neutral tone, parity with existing TransactionLive empty-state copy).
- Exact location of the filename helper module (recommended: `Threadline.OperatorSurface.Exports.Filename`).
- Pre-flight match-count integration test seeding strategy for the chunked-path assertion.
- Exact strategy for the degraded-count fallback (D-23) — `EXISTS LIMIT 10001` cap, separate library helper, or Repo-level timeout retry.
- Whether `include_action_metadata` / `max_rows` / CSV column toggles are exposed as URL knobs — recommendation: NO at this phase.

---

## Deferred Ideas

- NDJSON-only progressive download (no count pre-flight) — out of v1.18 scope.
- CSV column toggles / `include_action_metadata` UI checkbox — Mix task doesn't expose it.
- `?max_rows=N` URL knob with sanity ceiling — out of Phase 65 scope.
- Saved exports / "schedule this export to email" — deferred to v1.20+; Oban dep barrier.
- Resume / partial-download recovery — out of scope; chunked stream is one-shot.
- Per-row "export this row" affordance — out of scope; Phase 65 is window-shaped.
- Async download with status page — out of scope; Oban dep barrier.
- Email-when-ready / signed-link-expiry exports — deferred indefinitely.
- Auto-name "save as" for Mix task sharing `Threadline.OperatorSurface.Exports.Filename` — possible but out of Phase 65 scope.
- Phase 66 forward-compat for surface-header count — Phase 66's coverage badge is independent of Phase 65's above-timeline count.
