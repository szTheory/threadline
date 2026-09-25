# Phase 204: Structure - Context

**Gathered:** 2026-09-23
**Status:** Ready for planning
**Mode:** Advisor (research-then-recommend). Five parallel research passes (CSS lock, style split, render/size/register, test templates, ci.all dedup); maintainer accepted the full recommendation set ("1").

<domain>
## Phase Boundary

Make the largest files legible without changing a byte of output. Lock the emitted CSS behind a committed content hash (STRUCT-01), split `style.ex` into ordered legible segments with the hash unchanged at every commit (STRUCT-02), bring `lib/` under ~800 lines/file and ~120 lines/function or name the exception (STRUCT-03), replace separator comments with real boundaries (STRUCT-04), adopt shared endpoint/router test templates (STRUCT-05), remove duplicate/drift-prone steps from `ci.all` (STRUCT-06), and drain the Credo structural register to 0 (STRUCT-07).

Out of scope: any design/IA/visual change; any public API change (`Threadline.*` public modules keep their functions); capture/query/auth semantic change; new Credo opt-in checks (TYPES-01); `boundary` library adoption; router-macro changes to allow multiple mounts; regenerating Playwright baselines or Tier A scorecards.

</domain>

<decisions>
## Implementation Decisions

### Carried forward (Phase 203 — still binding)
- **D-00:** Commit type `refactor` for pure restructuring (never `fix`/`feat` — release-please would publish it); one `lib/` file per commit where practical; `git mv` for every move; new modules get a deliberate `@moduledoc false` (Credo `ModuleDoc` has `ignore_names` cleared); AliasUsage stays at upstream defaults (new call sites must alias); no planning vocabulary (`Phase \d+`, `STRUCT-0x`) in packaged source (`release_artifact_contract_test.exs` `:phase_prose`); `--warnings-as-errors`, `--no-optional-deps` compile and Elixir 1.15 min lane stay green; Dialyzer stays at 0 with empty ignore file; gates never read `.planning/` (DECOUPLE-01); never `git add .planning/` wholesale.
- **D-00b:** "Zero output change" evidence after every refactor commit touching rendered code: CSS byte lock (D-01) + `rendered_output_contract_test` + component contract tests green, and `mix verify.example_browser` at exactly the **8 known pre-existing failures** (a 9th failure or changed hash = real regression; never regenerate baselines). Never run Playwright directly.

### CSS byte lock (STRUCT-01)
- **D-01:** Golden file + sha256 pins in ONE ExUnit contract test: `test/threadline/operator_surface/style_byte_lock_test.exs` (`async: true`, guarded `if Code.ensure_loaded?(Phoenix.LiveView)`).
  - Rendered form: `Style.css(%{__changed__: nil}) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary()` (research proved byte-identical to `render_component(&Style.css/1, [])`).
  - Assert (a) golden file bytes == the style-owned portion of the output (everything after the fonts `<style>@font-face…</style>` prefix, i.e. from `<style>\n  .threadline-ui {` through `</style>`); (b) `sha256(golden file) == @golden_sha256`; (c) `sha256(full rendered output incl. fonts) == @rendered_sha256`. Also assert `Application.get_env(:threadline, :operator_surface_embed_fonts, true) == true` so the lock can't be computed against the fonts-off variant.
  - Golden file: `test/fixtures/style/operator_surface.css` + a one-paragraph `test/fixtures/style/README.md` (bump procedure). **NOT** under `test/fixtures/operator_surface/` — that directory has a full-corpus `manifest.sha256` contract (`operator_surface_fixture_contract_test.exs:50-66`).
  - Research measured baseline (current tree, LV 1.2.11 / phoenix_html 4.3.0 / Elixir 1.17.3): full output **212,633 bytes**, sha256 `b10d6a2c9a7d8abc99642f332cea9611ea7dab8f8a4ea8b212fac582ecaea5b1`. Planner/executor must RE-MEASURE at execution time and commit the measured value, not this one.
  - Failure message: byte sizes, 1-based first differing line with expected/actual `inspect`ed, byte offset, new sha, and the regeneration one-liner. Never let ExUnit print the two ~100 KB binaries. Test never writes fixtures.
  - Bump procedure (intentional CSS change only — **none allowed in this phase**): regenerate golden via `MIX_ENV=test mix run --no-start -e …`, paste both hashes, commit together with a why.
  - Gating: lives in `verify.test`, which is in `ci.all` on both lanes. **No new alias** (STRUCT-06).
  - Lands FIRST, before any refactor. — **Reversibility:** reversible.

### style.ex split (STRUCT-02)
- **D-02:** Nine ordered **`.css` files** in `lib/threadline/operator_surface/style/`, read at compile time. `style.ex` keeps an explicit ordered `@segments` list (no `Path.wildcard`), `@external_resource` for **every** segment, builds `@stylesheet "<style>" <> … <> "</style>"` at compile time, and renders it via `Phoenix.HTML.raw` alongside the existing `fonts_html` assign (pattern at `style.ex:~4502-4506`). Whole module stays inside `if Code.ensure_loaded?(Phoenix.LiveView)`. Hex `files:` already covers `lib` (mix.exs:~440) — confirm the `.css` files land in the tarball. — **Reversibility:** reversible.
- **D-03:** Segment map (source lines of current `style.ex`; every cut verified at brace depth 0 and preceded by a blank line — re-verify at execution):

  | File | Source lines | ~Lines | Content |
  |---|---|---|---|
  | `01_tokens.css` | 19–334 | 316 | `.threadline-ui` tokens, breakpoint tokens, light/system themes, `prefers-color-scheme`, light-surface overrides |
  | `02_base_shell.css` | 335–690 | 356 | reset, checkbox, skip link, sr-only, code/pre, topbar, shell nav, theme picker |
  | `03_page_home.css` | 691–1115 | 425 | phone-proof base, container/page, Operator Home, page header, nav, schema picker, orientation, segmented/tabs |
  | `04_controls.css` | 1116–1722 | 607 | toolbar, timeline command, filters, controls, disclosure, saved views, drawer, buttons, icons, links |
  | `05_feedback.css` | 1723–2141 | 419 | chips, alerts, empty states, stress, status, pager, summary grid |
  | `06_layout_primitives.css` | 2142–2795 | 654 | card, stack/cluster, data panel, detail header, metric card, change list, metadata row, transaction, table, job list, refs, target row |
  | `07_find_detail.css` | 2796–3301 | 506 | Find cluster, job/params, section, evidence, policy drift |
  | `08_overlays_motion.css` | 3302–3986 | 685 | subview, keyframes, transitions, `.hidden`, modal/drawer/popover/toast, reconnect, motion C1–C4, copy, kv, journey rail, coverage verdict, record list |
  | `09_responsive.css` | 3987–4497 | 511 | responsive tables, C5, ≤480px, tablet ≥768px, desktop ≥1280px, `prefers-reduced-motion` |

- **D-04:** Commit sequence, every commit green on D-01: (1) **pivot** — move the entire stylesheet into one `style/stylesheet.css` taken from the **rendered bytes** between `<style>` and `</style>` (not source lines), switch `css/1` to the raw compile-time render; this commit settles the join newlines empirically. (2) Peel segments **tail-first** (09, 08, … 02), one per commit, appending to `@segments` in order; the remainder is renamed `01_tokens.css`. Add a test asserting the `@segments` order (it IS the cascade).
- **D-05:** Pins that must move with the split (all currently read `style.ex` as text): add a shared reader (`test/support` helper or public-but-`@doc false` `Style.stylesheet/0`) and repoint `test/threadline/brandbook_token_parity_test.exs:22,34`, `test/threadline/operator_surface/style_contract_test.exs:5` (47 uses), `component_contract_test.exs:21,281,321`, `stress_router_test.exs:136,525`. Widen `rendered_output_contract_test.exs:187,422` planning-vocabulary scan to include `lib/threadline/operator_surface/style/*.css` (else CSS comments silently leave the scan). Update indent-sensitive literals in `style_contract_test.exs:973,1014,1020,1356` (source 8/10-space → rendered 2/4-space). Refresh comment-only line citations in e2e specs (`operator-stress.spec.ts:294,498`, `operator-phase-178-uat.spec.ts:53,150,172,230`, `operator-screenshot-regression.spec.ts:122`, `operator-component-contracts.spec.ts:252,348`) and `DESIGN-SYSTEM.md:176` wording. Re-measure all line numbers at execution.
- **D-06:** The leftover `/* End Find cluster primitives */` comment (~:3032) moves verbatim into `07`; removing it would change the hash → deferred.

### Size limits, extraction, separators, structural register (STRUCT-03/04/07)
- **D-07:** Enforcement = new `test/threadline/source_size_contract_test.exs` (Credo 1.7.18 has no file/function-length check; `LongQuoteBlocks` is default-on, `ABCSize` opt-in). Scans `lib/**/*.ex` **and `lib/**/*.css`** (800-line file limit); function length via `Code.string_to_quoted!(src, token_metadata: true, columns: true)` → `end[:line] - line + 1` per `def/defp/defmacro` clause grouped by name/arity (120-line limit). `@file_exceptions` / `@function_exceptions` maps of path/MFA → `{exact_limit, reason}`; fails on a stale exception (now under limit) and on an exceeded one; self-test with a synthetic planted violation (mirror `credo_config_contract_test.exs:92-108`); non-empty scan set. Runs in `verify.test`. **Lands second**, with exceptions pinned at today's measured values so it starts green; each extraction commit lowers/removes its entry.
- **D-08:** Extraction pattern: carve oversized `render/1` bodies into **private `defp` function components in the same LiveView** (called `<.foo …/>`, with `attr` declarations — `timeline_live.ex` already does this at `timeline_command`/`timeline_filter_drawer`). Use a sibling `@moduledoc false` module only if the file would still exceed 800 lines (expected: `timeline_live` → `TimelineLive.Helpers` for the helper section ~:885–end; possibly `stress_live`). **`embed_templates`/`.heex` is banned** for this work — it games the `.ex` limit. No `defdelegate` facades (they drop `attr` compile-time validation).
- **D-09:** `ui.ex` (1686 lines, `@moduledoc false` → internal, not a public-API change) splits by component family into `UI.Actions` (button, icon_button, link), `UI.Display` (badge, alert, divider, spinner, avatar, card, stack, cluster, stat_tile, ref, kv, code_block), `UI.Page` (page_header, pager, toolbar, detail_header, shell, tabs, segmented_control), `UI.Data` (data_table, data_panel, data_state, empty/error/loading/stale states), `UI.Overlay` (modal, drawer, toast, tooltip, popover, dropdown, accordion, reconnect_banner, JS show/hide helpers), `UI.Form` (label, error, help, input, field, error_summary, field_group, radio, switch, combobox). Call sites (8 LiveViews + stress_live) update aliases. Exact family membership is planner discretion after reading the file.
- **D-10:** `mechanical_checker.ex` (948) splits along its 7 banner seams (~:120, :132, :432, :536, :661, :743, :804) into `MechanicalChecker.{Contrast, TokenConformance, RatchetMetrics, AccentHue, Parsing}` (names indicative), `run/1` stays in the parent. `query.ex` (895, public) moves **only private helpers** into an internal `@moduledoc false` module — no public function moves or signature changes.
- **D-11:** STRUCT-04: a separator banner is removed by making it a real module or function boundary; delete a banner outright only when its section is already one cohesive clause group (e.g. a `handle_event` block). Current inventory (re-measure): 42 banners — mechanical_checker 10, timeline_live 10, export_controller 9, start_live 6, actor_ref 3, coverage_live 3, query 1.
- **D-12:** Exceptions at phase end — exactly one: `lib/threadline/operator_surface/stress_fixtures.ex` (~980 lines) — reason "declarative fixture data tables; excluded from the Hex package (mix.exs exclude_patterns)". The `style.ex` exception exists only until D-04 completes. **Not** exceptions: `stress_live.ex` (541-line render splits one `defp` per story section), `mechanical_checker.ex`, `critic_trust/*` — they are compiled on the lib path and split cleanly.
- **D-13:** STRUCT-07: drain all **42** register sites (Nesting 26 + CyclomaticComplexity 16; ≤3 per file across ~34 files, lib + test) via early return, multi-clause pattern matching, `with`, or extracted private functions; remove each site's `# Structural debt:` line with its disable. End state in `credo_config_contract_test.exs`: `@register %{}`, `@ceiling 0`, `@historical_max 46` kept as history (adjust assertions so an empty register is valid). Fallback only per-site: a site whose fix would change rendered output is re-registered with exact count + a named successor beyond v1.41 — never bulk re-registration. — **Reversibility:** reversible.
- **D-14:** Re-measure function lengths with the AST gate (the discuss-time awk estimates — stress_live render 541, export_status_live render 255, timeline_filter_drawer 207, start_live render 195, retention_history_live render 190, transaction_live render 184, timeline_live render 166, actor_live render 150, coverage_live render 140, timeline_command 131, refute_density_fields 123, timeline_live handle_params 121 — are indicative only).

### Shared test case templates (STRUCT-05)
- **D-15:** A single shared router (LiveDashboard pattern) is **not viable**: `threadline_operator_surface/2` reserves `live_session :threadline` + `pipeline :threadline_exports` and must be mounted once per router (`lib/threadline/operator_surface/router.ex:101,136-142`); ~13 files mount at `/audit` with different opts, so sharing would move rendered hrefs.
- **D-16:** New `test/support/operator_surface_case.ex` (guarded `if Code.ensure_loaded?(Phoenix.LiveView)`, each module with `@moduledoc`, aliases inside `quote` for AliasUsage):
  - `Threadline.OperatorSurfaceTest.Layouts` — `root/1` (title "Test") + `render("500.html", _)`.
  - `Threadline.OperatorSurfaceTest.Router` — `__using__(opts)`: `use Phoenix.Router`, LiveView router import, `require Threadline.OperatorSurface.Router`, `pipeline :browser` with `accepts: opts[:accepts] || ["html"]`, fetch_session, fetch_live_flash, shared root layout, plus `opts[:browser_plugs]` (timeline's `:put_test_actor`). Each file writes its own `scope` + `threadline_operator_surface(...)` mount — that is the deliberate, documented per-file difference.
  - `Threadline.OperatorSurfaceTest.Endpoint` — `__using__(router:, parsers: …)`: the standard stack (Session, fetch_session, Parsers, MethodOverride, Head, Router); cookie `key` derived from `Macro.underscore(__MODULE__)`; constant signing salt; json decoder `Phoenix.json_library()`.
  - `Threadline.OperatorSurfaceCase` — plain `__using__(endpoint:)` (NOT an `ExUnit.CaseTemplate`, so each file keeps its own explicit `use Threadline.DataCase/ExUnit.Case, async: …`), imports ConnTest/LiveViewTest, sets `@endpoint`; helper `start_endpoint!(endpoint, extra_env \\ [])` that does `Application.put_env` (secret_key_base, live_view signing_salt, render_errors) **before** `start_supervised!`, with `on_exit` cleanup.
  - Each file keeps unique per-file module names (no redefinition warnings, no shared endpoint across files).
- **D-17:** Migrate 16 files: breadcrumb, card_nesting_regression, copy_contract, gating, rendered_output_contract, skip_link, transaction_live, live/{actor, coverage, evidence, export_status, policy_redaction, retention_history, row_history, start, timeline}_live tests, controllers/export_controller (4 endpoints, `parsers: [:urlencoded, :json]`, accepts csv/json). Also fix `exports_mix_parity_test.exs:42-49` borrowing `ExportControllerTest.Endpoint` (give it its own). Three `<title>` variants (rendered_output_contract, copy_contract, stress_router) collapse to one shared title — research found no fixture contains `<title>`; confirm with the golden/contract tests.
- **D-18:** Documented exceptions (allowlist with reason): `router_test.exs` (throwaway `Code.compile_quoted` routers are the subject under test), `stress_router_test.exs` (different macro `threadline_operator_surface_stress`, `live_session :threadline_stress`, compiles throwaway routers), `test/support/stress_router_prod_compile.exs` (runs under `MIX_ENV=prod mix run --no-start`, can't depend on test/support).
- **D-19:** Enforcement: new `test/threadline/test_structure_contract_test.exs` (async, source scan over `test/**/*.{ex,exs}`): `use Phoenix.Endpoint` only in `test/support/operator_surface_case.ex`; `use Phoenix.Router` only there or in `@allowlist %{path => reason}`; every allowlisted path exists and still matches (stale entries fail); non-empty scan set.

### ci.all de-duplication (STRUCT-06)
- **D-20:** **Delete `verify.doc_contract` outright** (preferred-env entry mix.exs:~13, alias :~129-131, `ci.all` entry :~197). Its hand-listed 21 files had already drifted from the 33 real doc-contract files — it is the "second, drift-prone definition". `verify.test` already runs all of them. Not an adopter-facing API (maintainer/evaluator prose only) → not semver-relevant. — **Reversibility:** reversible.
- **D-21:** Remove `verify.critic_trust` and `verify.mechanical` from `ci.all` (both re-run test files `verify.test` already ran); **keep both aliases** (ci.yml `verify-mechanical` fast job :~573 and capture job :~688 use `verify.mechanical`; `verify.critic_trust` is the focused maintainer command). Fail-fast is preserved: `verify.test` runs before the browser lane. `compile --warnings-as-errors` vs `verify.compile_no_optional` are different builds → both stay; `verify.threadline`, `verify.example`, dialyzer are distinct → stay.
- **D-22:** Delete the ci.yml "Doc contract tests" step (~:379-381) inside job `verify-test` — step only, **no job `id:` change**. Fix comments at ~:869/:876.
- **D-23:** `bin/verify-bump-rehearsal` (~:375-379, summary ~:419) derives its subset by filename at run time: `find test \( -name '*doc_contract_test.exs' -o -name '*readme_contract_test.exs' \) | sort`, **fails if fewer than 30 files found** (an empty list would make `mix test` run the full suite and pass vacuously), then `mix test "${DC_FILES[@]}"`. This restores the 12 files that had drifted out; they may be red at NEXT on first run — run `mix verify.bump_rehearsal` locally before pushing; a failure there is a real born-red defect, not noise.
- **D-24:** Enforcement: guard test (in `ci_topology_contract_test.exs` or new `ci_all_dedup_contract_test.exs`) reading `Mix.Project.config()[:aliases]` at runtime (not regex): (a) `:"verify.doc_contract"` absent; (b) recursively expanding string aliases, only `verify.test` in `ci.all` expands to a `test…` command (function-capture aliases opaque/allowed); (c) no alias anywhere is `test` with ≥2 explicit `.exs` paths; (d) `ci.all` non-empty and contains `verify.test`.
- **D-25:** Same-commit updates (re-measure lines): `test/threadline/ci_topology_contract_test.exs` (~:60-73, :80, :95, :107-108, :218-220 — ordering asserts use `:binary.match` which raises on a missing step), `ci_workflow_parity_contract_test.exs:~37-61`, `adoption_pilot_doc_contract_test.exs:~92`, `evaluating_threadline_doc_contract_test.exs:~42`; `.github/workflows/release.yml:~578` → "Merge after CI (`mix verify.test`) is green"; mix.exs comments at ~:146-157; CONTRIBUTING.md (~:154-155, :169, :303-304, :345, :397-398 → "in `mix verify.test` (and so in ci.all)"; :508; :682); `guides/configuration-and-commands.md:~116`; `guides/evaluating-threadline.md:~38,58`; `guides/adoption-pilot-backlog.md:~5,133` ("nine steps" → "eight"). CHANGELOG history lines stay. `ci_coverage_doc_contract_test.exs:21-23` already anticipates this deletion.

### Plan shape (planner may adjust count, not the ordering constraints)
- **D-26:** Recommended order: (1) CSS byte lock → (2) size gate at measured ceilings → (3) style.ex split (pivot + 8 peels) → (4) separator-banner files + mechanical_checker split → (5) ui.ex family split → (6) render carving across LiveViews + long non-render functions → (7) structural register drain lib then test, ceiling → 0 → (8) test case templates + structure contract → (9) ci.all dedup + guard + docs. Hard constraints: (1) and (2) precede every refactor; (3) before the size gate's style exception is removed; (7) may interleave with (4)–(6) when a register site sits in a file being split (one commit per file still).

### Claude's Discretion
- Exact segment-module/component-module names, exact `ui.ex` family membership, test helper name (`StyleSource` vs `Style.stylesheet/0`), guard-test file placement, whether individual Nesting/Complexity sites use `with` vs multi-clause vs extracted `defp`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & rules
- `.planning/ROADMAP.md` §"Phase 204: Structure" (~line 787) — goal, 5 success criteria
- `.planning/REQUIREMENTS.md` lines 84-90 — STRUCT-01..07
- `.planning/phases/203-real-gates/203-CONTEXT.md` — D-07/D-27/D-31 (register form, `# Structural debt:` prefix), D-28 (commit granularity/type), the 204 hard rule
- `.planning/phases/203-real-gates/203-08-SUMMARY.md`, `203-09-SUMMARY.md` — how the 42 structural sites were filed

### CSS / style
- `lib/threadline/operator_surface/style.ex` — the 4509-line `~H` block (single interpolation `{@fonts_html}` at :18)
- `lib/threadline/operator_surface/fonts.ex:33-66` — compile-time font embedding (`@external_resource` precedent)
- `test/threadline/operator_surface/style_contract_test.exs`, `brandbook_token_parity_test.exs`, `component_contract_test.exs`, `stress_router_test.exs`, `rendered_output_contract_test.exs` — source-text readers of style.ex
- `test/fixtures/operator_surface/manifest.sha256` + `test/threadline/operator_surface/operator_surface_fixture_contract_test.exs:50-66` — why the golden must not go there
- `DESIGN-SYSTEM.md:176`

### Gates & precedents
- `test/threadline/credo_config_contract_test.exs` — register/ceiling pattern (:36-41, self-test :92-108)
- `test/threadline/dialyzer_ignore_contract_test.exs:20` — `@sealed_output_sha256` pin precedent
- `test/threadline/release_artifact_contract_test.exs` — `:phase_prose` ban; packaged-path rules
- `test/threadline/ci_topology_contract_test.exs`, `ci_workflow_parity_contract_test.exs`, `ci_coverage_doc_contract_test.exs:21-23`
- `mix.exs` aliases (~:122-215), package `files`/`exclude_patterns` (~:431-460)
- `.github/workflows/ci.yml` (verify-test job ~:355-381, verify-mechanical ~:533-573, capture ~:688, bump rehearsal ~:865-880), `.github/workflows/release.yml:~578`
- `bin/verify-bump-rehearsal`
- `deps/credo/.credo.exs` — which Refactor checks are default (LongQuoteBlocks on, ABCSize off)

### Router / test templates
- `lib/threadline/operator_surface/router.ex:58-170` — mount-once constraint (:101, :136-142)
- `test/threadline/operator_surface/live/actor_live_test.exs` — representative hand-rolled Layouts/Router/ScopedRouter/Endpoint
- `test/threadline/operator_surface/controllers/export_controller_test.exs`, `live/timeline_live_test.exs:~99`, `exports_mix_parity_test.exs:42-49` — real per-file deltas

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `credo_config_contract_test.exs` / `dialyzer_ignore_contract_test.exs` — exact-count register + ceiling + self-test pattern for the size gate and the CSS pin.
- `fonts.ex` — compile-time `File.read!` + `@external_resource` pattern for the `.css` segments.
- `timeline_live.ex` `timeline_command/1`, `timeline_filter_drawer/1` — in-module function-component extraction precedent.
- `components/` dir (icon, logo, surface_header, unsupported_view) — per-family component module precedent for the ui.ex split.

### Established Patterns
- Invariants enforced by ExUnit source-scan/contract tests in `verify.test`, not new tooling or aliases.
- Measured (not estimated) numbers are re-derived at execution; discuss-time line numbers are indicative.
- `.planning/` is never read by gates and never staged wholesale.

### Integration Points
- `ci.all` alias and the CI `verify-*` jobs (job ids immutable).
- Operator layout calls `<Threadline.OperatorSurface.Style.css />` exactly once (`ui.ex:~1165`) — becomes a UI-family module call site after D-09.
- Playwright browser lane (`mix verify.example_browser`) — 8 known failures baseline.

</code_context>

<specifics>
## Specific Ideas

- "Zero output change" is proven, not asserted: byte lock + contract tests + browser lane at exactly 8 known failures after each commit.
- Moving markup to `.heex` or bulk re-registering register sites would satisfy the letter while dodging the intent — both explicitly rejected.
- Footguns captured by research: HEEx escaping if `Phoenix.HTML.raw` is missed (`>` / `"` / `&` escaped → hash changes while looking identical); heredoc dedent drift; newline at segment joins; missing `@external_resource` → stale compiled CSS behind a green lock; cascade order; endpoint `put_env` must precede `start_supervised!`; empty file list makes `mix test` run everything.

</specifics>

<deferred>
## Deferred Ideas

- Removing the leftover `/* End Find cluster primitives */` CSS comment — needs a deliberate hash re-baseline.
- Widening the bump rehearsal from doc-contract files to all ~78 `*contract_test.exs`.
- Router macro supporting multiple mounts / configurable `live_session` name (would enable one shared test router).
- `boundary` library / compile-time layer enforcement.
- Credo opt-in checks (`Readability.Specs`, `ABCSize`) → TYPES-01.
- Re-verifying Phases 199–203 (verification digests stale because later phases touched covered files) → at milestone audit after 204, not now.

</deferred>

---

*Phase: 204-structure*
*Context gathered: 2026-09-23*
