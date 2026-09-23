# Phase 204: Structure - Research

**Researched:** 2026-09-23
**Domain:** Behavior-preserving refactor of an Elixir/Phoenix LiveView library (CSS byte-lock, module extraction, ExUnit source-scan gates, Mix alias topology)
**Confidence:** HIGH (every load-bearing number re-measured against HEAD `6aa08ba3` in this session; the CSS pivot was prototyped end-to-end)

## Summary

CONTEXT.md (26 locked decisions) is accurate on almost every measured fact. I re-derived its numbers against the live tree, and they hold: the rendered CSS is 212,633 bytes with sha256 `b10d6a2c…`, there are 42 structural-register sites, 21 files in the `verify.doc_contract` alias against 33 real doc-contract files, the 8 style-segment cut points, and the Endpoint/Router inventory. I also **prototyped the style pivot**. Moving the stylesheet bytes into a file and rendering `~H"{@fonts_html}{@stylesheet}"` with `Phoenix.HTML.raw` produces output byte-identical to today's. Dropping `raw` breaks equality, because `>` and `"` get escaped.

The research found **seven things CONTEXT did not account for**. Any one of them would turn a "pure refactor" commit red or unsafe:
1. **Hex leak.** `exclude_patterns` are per-file anchored regexes (`mechanical_checker\.ex$`, `stress_live\.ex$`). A `mechanical_checker/…` or `stress_live/…` sibling module would ship in the Hex package unless the pattern and `release_artifact_contract_test.exs` `@maintainer_only_paths/@maintainer_only_prefixes` are widened in the same commit.
2. **Source-text pins across the suite.** At least 15 test files `File.read!` the exact files being split and assert on literal code: `defp preload_visible_context(...)` in timeline_live.ex, `def shell(assigns)` and a `def pager` regex in ui.ex, the gamma-2.4 line and all constants in mechanical_checker.ex, the `<form id="timeline-filters"…</form>` block, the download anchors, and more. Moving that code breaks these pins unless the test is repointed in the same commit.
3. **`query.ex` filter pipeline is pinned by an adopter-facing guide.** `guides/code-walkthrough.md` quotes `defp filter_by_correlation` "in `Threadline.Query`", and its contract test forbids guides naming hidden modules. The section under the only `query.ex` banner (:840) therefore **must stay in query.ex**; the other private helpers move out instead.
4. **`ui.ex` family split has ~770 call sites, not "8 LiveViews + stress_live".** They break down as lib 247, `examples/threadline_phoenix/storybook/*.story.exs` 327, and test 198.
5. **A 138-line function CONTEXT missed.** `Threadline.Governance.Migration.migration_content/0` is a single generated-migration heredoc with no golden test.
6. **`timeline_live.ex` cannot get under 800 by moving only the helper section.** 1399 minus ~515 is still about 885, so it needs a second sibling (the filter components). Those components carry doc-contract-pinned markup.
7. **Three test Endpoint variants, not two.** `gating_test.exs` `ExportsDisabledEndpoint` has **no `Plug.Parsers` at all**, so the shared Endpoint template needs a "no parsers" option.

**Primary recommendation:** Keep D-26's order. Add three cross-cutting mechanisms before the extractions:
- a **source-family reader** in `test/support`, so pins read "file + its extracted siblings";
- **widened `exclude_patterns`** plus a release-artifact assertion that the `.css` segments ship;
- a **banner guard** for STRUCT-04, which currently has no enforcement in CONTEXT.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
- Removing the leftover `/* End Find cluster primitives */` CSS comment — needs a deliberate hash re-baseline.
- Widening the bump rehearsal from doc-contract files to all ~78 `*contract_test.exs`.
- Router macro supporting multiple mounts / configurable `live_session` name (would enable one shared test router).
- `boundary` library / compile-time layer enforcement.
- Credo opt-in checks (`Readability.Specs`, `ABCSize`) → TYPES-01.
- Re-verifying Phases 199–203 (verification digests stale because later phases touched covered files) → at milestone audit after 204, not now.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STRUCT-01 | Emitted CSS locked by committed content hash gated in `ci.all` | Baseline re-measured (212,633 B / `b10d6a2c…`); fonts-off render = style-owned suffix exactly (119,508 B / `c7baf51e…`) — §Pattern 1, §Code Examples |
| STRUCT-02 | style module split into ordered segments, hash unchanged every commit | Pivot prototyped byte-identical; 8 cuts re-verified at depth 0; `raw` omission proven to break equality; 5 source readers + 1 source-scan inventory to repoint — §Pattern 2, Pitfalls 1–4 |
| STRUCT-03 | No lib file > ~800 lines / function > ~120, or named exception | AST measurement of every lib function (table below); `migration_content/0` (138) newly found; timeline_live needs 2 siblings; export_status_live at 796 — §Size Inventory |
| STRUCT-04 | Separator comments no longer stand in for boundaries in `lib/` | 42 banner lines = **33 distinct banners** (5 timeline, 3 start, 2 coverage are two-line rule pairs); no enforcement exists in CONTEXT → add banner guard — §Banner Inventory |
| STRUCT-05 | Shared endpoint/router case templates | 31 Endpoint modules in 18 files normalize to 3 real variants (default / export `[:urlencoded,:json]` / gating **no Parsers**); titles & cookie keys unasserted — §Test Template Inventory |
| STRUCT-06 | No duplicate/drift-prone steps in `ci.all` | Every `verify.doc_contract` reference enumerated (code, CI, tests, docs); 12 drifted files listed — §ci.all Inventory |
| STRUCT-07 | Structural register → 0 | 42 sites / 33 files (30 lib in 26 files, 12 test in 7 files) listed; credo test's empty-register breakage points identified — §Register Inventory |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Three-layer architecture (capture / semantics / exploration). This phase touches only exploration-layer (operator surface) internals plus `Threadline.Query` private helpers. It must not move responsibility across layers.
- Domain language (AuditTransaction, AuditChange, AuditAction, AuditContext, ActorRef, Correlation) stays unchanged in any renamed or extracted module.
- Use named entrypoints (`mix verify.*` / `mix ci.*`), not ad-hoc commands, in CI and docs.
- **Honest default tests.** Never silently exclude suites from `mix test`. The new gates must live in plain `*_test.exs` picked up by bare `mix test`.
- **Stable CI job IDs.** Never change a job `id:` (D-22 deletes a *step* only).
- **Doc contract tests.** README, guides, and example README stay aligned via assertions. Every doc edit in D-25 has a pinning test that must move in the same commit.
- Trigger-backed capture boundary: untouched.
- GSD: `state.begin-phase` uses flags (`--phase 204 --name "Structure" --plans N`) with gsd-core v1.14.0. Hand-check STATE.md/ROADMAP.md afterwards.
- Memory gotchas: never `git add .planning/`; never run Playwright directly (use `mix verify.example_browser`); Dialyzer red in `ci.all` means a PLT cache miss (a PLT exists at `.dialyzer/dialyxir_erlang-27.3_elixir-1.17.3_deps-dev.plt`); the browser lane at 82 passed / 8 failed is the healthy baseline.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CSS emission (`Style.css/1`) | Frontend Server (LiveView SSR component) | Build (compile-time file read) | CSS bytes are assembled at compile time from `.css` resources and emitted inline by a function component |
| CSS byte lock | Test gate (ExUnit, `verify.test`) | — | Pure assertion over rendered output; never writes fixtures |
| Size/banner/structure gates | Test gate (ExUnit source scan) | — | Repo convention: invariants as `*_contract_test.exs`, no new tooling/aliases |
| Component/LiveView extraction | Frontend Server (LiveView modules) | — | Internal `@moduledoc false` modules; no public API change |
| `Threadline.Query` helper extraction | API/Backend (query composition) | — | Private helpers only; public functions and the walkthrough-pinned filter pipeline stay |
| Test Endpoint/Router templates | Test support (`test/support`, compiled only in `:test`) | — | `elixirc_paths(:test) = ["lib", "test/support"]` (mix.exs:82) |
| ci.all topology | Build/CI (Mix aliases + GitHub Actions) | Docs | Alias list + workflow steps + prose that cites them |
| Hex package contents | Build/Release (`package/0`) | Test gate (`release_artifact_contract_test`) | Proven against the unpacked tarball, not the config |

## Standard Stack

No new dependencies. Everything is already locked in `mix.lock`.

### Core (in use, verified)
| Library | Version | Purpose | Why relevant |
|---------|---------|---------|--------------|
| phoenix_live_view | 1.2.11 | `~H`, function components, `attr` | Component functions **must** return `%Rendered{}` [VERIFIED: deps/phoenix_live_view/lib/phoenix_live_view/tag_engine.ex:141-150 — `expected #{inspect(func)} to return a %Phoenix.LiveView.Rendered{} struct` / `Ensure your render function uses ~H to define its template.`]. `css/1` must keep a `~H` |
| phoenix | 1.8.13 | test Endpoint/Router | shared templates |
| credo | 1.7.18 | structural register | Defaults: `Nesting` `param_defaults: [max_nesting: 2]` [VERIFIED: deps/credo/lib/credo/check/refactor/nesting.ex:4]; `CyclomaticComplexity` `param_defaults: [max_complexity: 9]` [VERIFIED: …/cyclomatic_complexity.ex:4]; `LongQuoteBlocks` `param_defaults: [max_line_count: 150, ignore_comments: false]` [VERIFIED: …/long_quote_blocks.ex:5]. `ABCSize` is in the disabled list [VERIFIED: deps/credo/.credo.exs:192] |
| dialyxir | 1.4.8 | Dialyzer gate | PLT cached in `.dialyzer/` (mix.exs:53-54) |
| lazy_html | 0.1.12 | LiveViewTest HTML | unchanged |

**Package Legitimacy Audit:** Not applicable. The phase installs no external packages. The `research-plan` web/doc seam was not needed because every question was answerable from the repo, `deps/` source, and empirical probes.

## Architecture Patterns

### System Architecture Diagram (CSS path, before → after)

```
compile time                                    render time (every page)
─────────────                                   ────────────────────────
priv/fonts/*.woff2 ──@external_resource──▶ Fonts.@face_css ─┐
                                                           │  Fonts.face_css()
style/01_tokens.css ─┐                                     │  (""  if embed_fonts=false)
style/02_…css       ─┤ @external_resource each             ▼
   …                 ├─ ordered @segments ──▶ @stylesheet ─▶ Style.css/1  (~H "{@fonts_html}{@stylesheet}")
style/09_…css       ─┘ (explicit list, no wildcard)          │    both assigns wrapped in Phoenix.HTML.raw
                                                             ▼
                                   UI shell (ui.ex:1165) / storybook wrapper.ex:15 ─▶ HTML
                                                             │
                             style_byte_lock_test ◀──────────┘ sha256(full)==pin, suffix==golden file
```

### Pattern 1: CSS byte lock (STRUCT-01)
- The style-owned golden equals **the output with `operator_surface_embed_fonts: false`**, byte for byte [VERIFIED: probe this session — `String.ends_with?(full, fonts_off) == true`; fonts-off = 119,508 bytes, sha256 `c7baf51ecd9b4465675ea12a67218974157616ea8e8937e71aa166ca8154ab4b`; full = 212,633 bytes, sha256 `b10d6a2c9a7d8abc99642f332cea9611ea7dab8f8a4ea8b212fac582ecaea5b1`].
- Compute the suffix **by prefix stripping, not by toggling app env**. The test is `async: true`, and `put_env` would race other async tests. Use `prefix = "<style>" <> Fonts.face_css() <> "</style>"`, assert `String.starts_with?(full, prefix)`, then `binary_part` the rest. The probe used exactly this.
- `css/1` takes **no theme argument**. The "theme matrix" is CSS-internal (`[data-tl-theme="light"|"system"]`, `prefers-color-scheme`) [VERIFIED: style.ex:9-18 `def css(assigns)` / `{@fonts_html}<style>`]. The only render-time variable is `operator_surface_embed_fonts` [VERIFIED: fonts.ex `face_css/0` reads `Application.get_env(:threadline, :operator_surface_embed_fonts, true)`]. Fonts are compile-time `Base.encode64` of 5 fixed files, so they are deterministic. **The hash is stable, so the "STOP if unstable" branch does not trigger.**

### Pattern 2: Pivot then peel (STRUCT-02), prototyped
Prototype result: `pivot identical: true`. The same stylesheet rendered **without** `raw` gives `false`, because the sheet contains `>` and `"` (no `&`) [VERIFIED: probe].
- Rendered sheet: 4481 lines; it starts `"<style>\n  .threadline-ui {\n   "` and ends `"…!important;\n    }\n  }\n</style>"`. It has 0 trailing-whitespace lines, 0 tabs, and 0 CRs [VERIFIED: grep on extracted sheet]. No `.gitattributes`, `.editorconfig`, or pre-commit hook exists. `.formatter.exs` inputs are `{config,lib,test}/**/*.{ex,exs}` only, so `mix format` never touches `.css`.
- Source line to rendered-sheet line: `rendered = source − 17`, and indentation shrinks by 6 spaces (heredoc dedent). The D-03 cut lines (source 335, 691, 1116, 1723, 2142, 2796, 3302, 3987) map to sheet lines 318, 674, 1099, 1706, 2125, 2779, 3285, 3970.
- All 8 cuts re-verified this session: each sits at brace depth 0 (comment-aware scan) and is preceded by a blank line. Final depth is 0.
- The trailing newline in `~H` heredocs is trimmed (the prototype's `~H"""\n{@fonts_html}{@stylesheet}\n"""` produced no extra `\n`).
- **Size gate interplay:** at the pivot commit, `style.ex` drops to ~40 lines and `style/stylesheet.css` (4481 lines) takes over the file exception. The `css/1` function exception (4492) disappears. The gate fails on stale exceptions, so **the pivot commit must edit the gate's exception map in the same commit**. Each peel then lowers the `.css` exception, and the last peel deletes it.

### Pattern 3: Source-family reader (new, recommended)
There are two problems. Pins in ~15 test files read one source path, and extraction moves the pinned text into sibling modules. Add one helper in `test/support` (e.g. `Threadline.Test.SourceFamily.read!(path)`) that returns the file plus every file under its sibling directory (`timeline_live.ex` + `timeline_live/*.ex`; `ui.ex` + `ui/*.ex`; `mechanical_checker.ex` + `mechanical_checker/*.ex`). Repoint pins to it **in the same commit as each extraction**. Keep single-file reads where the assertion is about that exact file:
- the line-1 `if Code.ensure_loaded?(Phoenix.LiveView) do` gate (timeline_browse_doc_contract_test.exs:106-110);
- `@ui_form_policy` declarations.

This is the generalisation of D-05's `StyleSource` for the style case. Name it per CONTEXT's discretion. Use an explicit sorted `Path.wildcard` **only for reading in tests**; the wildcard ban applies to `@segments` in lib.

### Pattern 4: In-module function components (D-08)
The precedent already exists (`timeline_live.ex:551 defp timeline_command`, `:682 defp timeline_filter_drawer`). `attr` declarations add lines, so a file close to the limit can cross it. `export_status_live.ex` is **796 lines** today.

### Anti-Patterns to Avoid
- **`Path.wildcard` for `@segments`.** The order is the cascade, and a wildcard makes it filesystem-order dependent. D-02 bans it.
- **`embed_templates` / `.heex`.** Banned by D-08. Enforce it: the size gate should assert no `lib/**/*.heex` and no `embed_templates` in lib (0 today [VERIFIED: grep]).
- **`defdelegate` facades to keep `UI.button` names.** Banned by D-08, because they drop `attr` compile-time validation.
- **Toggling `Application.put_env` in the async byte-lock test.** Use prefix stripping instead.
- **Editing story `doc/0` prose in the storybook** while updating `UI.*` call sites. The prose ("Covered primitives: UI.button, …") is rendered on the Storybook page and captured by the browser lane. Change code, not prose.

## Size Inventory (AST-measured this session)

Method: `Code.string_to_quoted(src, token_metadata: true, columns: true)`, measuring `end.line − line + 1` per def clause. The script is at `/tmp/p204/fnlen.exs`; re-run it at execution.

**Files > 800** [VERIFIED: `wc -l`]: style.ex 4509 · ui.ex 1686 · timeline_live.ex 1399 · stress_live.ex 1398 · stress_fixtures.ex 980 · mechanical_checker.ex 948 · query.ex 895. **Near the limit:** export_status_live.ex 796.

**Function clauses > 120:** style.ex `css/1` 4492 · stress_live `render/1` 540 · export_status_live `render/1` 254 · timeline_live `timeline_filter_drawer/1` 202 · start_live `render/1` 190 · retention_history_live `render/1` 186 · transaction_live `render/1` 183 · timeline_live `render/1` 165 · actor_live `render/1` 149 · **governance/migration.ex `migration_content/0` 138 (not in CONTEXT)** · coverage_live `render/1` 135 · timeline_live `timeline_command/1` 130.

**Just under 120 (watch for growth):** timeline_live `handle_params/3` 116, evidence_live `render/1` 114, policy_redaction_live `render/1` 111, router.ex `threadline_operator_surface/2` 110, export/orchestrator `run/2` 101. `refute_density_fields` is now under 100.

**Grouping rule to decide:** D-07 says "per clause grouped by name/arity". Measure **per clause** and report the max clause per name/arity. Summing clauses would falsely flag timeline_live `handle_event/3` (10 clauses, 159 total, max clause 56).

**Extraction math the planner needs:**
- **timeline_live.ex (1399).** Sections: mount :27, handle_params :87, handle_event :208, render :381 (render 165 + timeline_command 130 + filter_drawer 202), helpers :885–1399 (~515).
  - Moving helpers alone leaves ~885 lines, which is **still over 800**.
  - Also move the two filter components to a second sibling to reach ~550.
  - Keep `scope_aware_opts`/`preload_visible_context` (:889–920) in the LiveView. `timeline_live_test.exs:1351-1358` pins `defp preload_visible_context(%{entries: entries} = page, repo, opts)` in timeline_live.ex, and `defp` becomes `def` if moved.
  - The filter form, drawer, and download-link markup is pinned by `timeline_browse_doc_contract_test.exs` and `exports_doc_contract_test.exs`, so repoint those via the source-family reader.
- **query.ex (895, public module).** The walkthrough guide pins `filter_by_correlation` (:882-894) in `Threadline.Query` [VERIFIED: test/threadline/code_walkthrough_doc_contract_test.exs:21-23 `"lib/threadline/query.ex" => ["on: at.action_id == aa.id and aa.correlation_id == ^cid"]`; guides/code-walkthrough.md:301 "internal correlation filter in `Threadline.Query`"]. Guides may not name hidden modules (code_walkthrough_doc_contract_test.exs:75-86 refutes `Threadline.Query.Scope` etc.).
  - **Move the cursor/validation/scope-opts helpers instead**: actor_history cursor helpers ~:558-640, `*_scope_opts` ~:739-780, `validate_timeline_*`/`timeline_page_next_cursor` ~:797-840. That is well over the 95 lines needed.
  - Keep the `filter_by_*` group and delete the :840 banner (a cohesive defp group, as D-11 allows).
  - Also keep the three `repo.preload(… storage_opts([], opts))` lines pinned by `query_test.exs:615-620` (:109, :133, :668), and `@allowed_timeline_filter_keys` (:40), pinned by two doc-contract tests.
- **mechanical_checker.ex (948, excluded from Hex).** `mechanical_checker_test.exs:22-59` pins as **text** in mechanical_checker.ex: all 7 MODE-A/B constants, the 4 scale lists (`@spacing_scale_px [4, 8, …]`, etc.), and `:math.pow((srgb + 0.055) / 1.055, 2.4)`.
  - Keep constants and `linearize_channel` in the parent (or repoint the test).
  - Best cohesive cuts: scorecard loading/validation :132-431 (~300 lines) → `MechanicalChecker.Scorecards`; parsing helpers :804-948 → `MechanicalChecker.Parsing`. That gives about 500 lines in the parent without moving any pinned text.
  - Modify D-10's names accordingly (discretion).
- **ui.ex (1686).** 49 public components [VERIFIED: grep of `def` heads]. Each family module needs `use Phoenix.Component` + `import Phoenix.Component, except: [link: 1]` (ui.ex:4-5) where it defines `link`, plus the aliases it uses (`JS`, `Icon`, `Presentation`, `Script`).
  - `component_contract_test.exs` reads ui.ex source at :22/:362/:398/:414/:472-517/:545/:596: `def shell(assigns)`, plus the regex `~r/def pager\(assigns\) do.*?~H"""(.*?)"""/s` at :599. Repoint these.
- **stress_live.ex (1398, excluded from Hex).** Render is 540 lines. Carving per story section into `defp` components keeps text in-file. A sibling module is needed only if the file is still over 800 after carving (carving adds `attr` lines).
- **migration_content/0 (138).** This is one heredoc that generates the governance migration written by `mix threadline.install` (lib/mix/tasks/threadline.install.ex:57). No golden test covers its output. Choose one:
  - **(a)** Name it a function exception with the reason "single heredoc template of the generated migration file". This makes 2 exceptions, contradicting D-12's "exactly one", so it needs confirmation.
  - **(b)** Split it into `up`/`down` heredoc helpers **after** adding a sha256 pin of `migration_content()` output, the same pattern as the CSS lock.
  - Recommend (a).

## Banner Inventory (STRUCT-04)

Regex `^\s*#\s*(-{3,}|={3,}|─{3,}|\*{3,})` over `lib/` finds 42 lines [VERIFIED: grep this session]. Distinct banners:

| File | Lines | Distinct | Notes |
|---|---|---|---|
| mechanical_checker.ex | 26, 33, 37, 120, 132, 432, 536, 661, 743, 804 | 10 | 26/33/37 frame attribute groups; the constants must stay textually in this file |
| export_controller.ex | 21, 199, 228, 257, 286, 311, 324, 351, 360 | 9 | 366-line file; its source is pinned by export_controller_test.exs:572 and exports_doc_contract_test.exs:90-173 |
| timeline_live.ex | 27/29, 87/89, 208/210, 381/383, 885/887 | 5 | rule/title/rule triplets naming callbacks |
| start_live.ex | 21/36, 309/311, 411/414 | 3 | 21–36 frames a 14-line explanatory paragraph; keep the prose as a plain comment and drop the rules |
| actor_ref.ex | 29, 65, 102 | 3 | public module; clause groups are cohesive, so delete |
| coverage_live.ex | 20/22, 336 | 2 | |
| query.ex | 840 | 1 | cohesive `filter_by_*` group, so delete (see above) |
| **Total** | 42 lines | **33** | ROADMAP's "33 banner comments" is the distinct count; CONTEXT's "42 banners" is the line count |

**Gap:** CONTEXT defines no enforcement for STRUCT-04. Add a zero-tolerance banner scan (the same regex over `lib/**/*.ex`) to `source_size_contract_test.exs`, with a planted-violation self-test. Without it the requirement is unguarded and can regress.

## Structural Register Inventory (STRUCT-07)

42 disables in 33 files, each with a `# Structural debt:` line [VERIFIED: grep counts 42/42].
- **lib (30 sites, 26 files):** 2 sites each in query/filter_params, timeline_live, stress_live, critic_trust/krippendorff_alpha. 1 site each in retention/policy, query, policy/redaction_presenter, operator_surface/router, presentation, mechanical_checker, row_history_component, export_status_live, actor_live, export_controller, auth, export/orchestrator, export/cleanup_task, evidence, critic_trust/rank_metrics, critic_trust/measure, change_diff, audit, mix tasks threadline.verify_coverage, threadline.install, threadline.export, critic.measure.
- **test (12 sites, 7 files):** 3 in rendered_output_contract_test, 3 in operator_surface_fixture_contract_test, 2 in support/getting_started_fixtures, and 1 each in release_artifact_contract_test, card_nesting_regression_test, guide_graph_contract_test, dialyzer_ignore_contract_test.

**credo_config_contract_test.exs changes for the empty end state** [VERIFIED: file read, lines 35-41, 72-108, 184, 492-493]:
- `@register %{…}` becomes `%{}` and `@ceiling 42` becomes `0`.
- The test at :90-108 does `Map.fetch!(@register, Credo.Check.Refactor.Nesting)`. That **raises on an empty register**, so rewrite it against a local synthetic register (e.g. `%{Nesting => {2, "x"}, Complexity => {1, "x"}}`).
- The :84 `Enum.all?(…successor == @successor)` passes vacuously on an empty map. That is fine, but keep `@successor` used (lines 184, 492-493 still use it) to avoid an unused-attribute warning.
- The moduledoc's "Phase 204 (STRUCT-07) … ratchets toward 0" prose needs updating. It lives in test/, so the packaged-source vocabulary ban doesn't apply, but keep it truthful.

Sites inside the `critic_trust/*` and `critic.measure` files are in the **live Dialyzer slice** (`dialyzer_slice_contract_test.exs:12` runs cold Dialyzer on the critic-tooling slice and is not excluded by `test_helper.exs`). A refactor there that introduces a Dialyzer warning fails both the slice test and `verify.dialyzer`.

## Test Template Inventory (STRUCT-05)

31 `use Phoenix.Endpoint` modules in **18** files (17 to migrate plus `stress_router_test.exs`, an exception). 20 files `use Phoenix.Router` (the 18 plus `router_test.exs` and `support/stress_router_prod_compile.exs`) [VERIFIED: grep]. Per-file multiplicity: timeline 5, export_controller 4, start 3, actor/row_history/transaction 2 each, stress_router 2 endpoints / 5 routers, router_test 9 routers.

D-17 says "Migrate 16 files", but the list it gives has 17 entries. The correct count is **17**.

Normalizing endpoint bodies (module names, cookie key, and salt masked) leaves **three real variants** [VERIFIED: AST normalize + md5 this session]:
1. **Default** (26 modules): `Plug.Session` → `:fetch_session` → `Plug.Parsers parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library()` → `MethodOverride` → `Head` → Router.
2. **export_controller** (4 modules): `parsers: [:urlencoded, :json]`, `json_decoder: Jason`, and salts `String.duplicate("x"|"y"|"a"|"d", 8)`.
3. **gating `ExportsDisabledEndpoint`**: **no `Plug.Parsers`**. The shared Endpoint needs `parsers: false` (skip the plug) to stay behavior-identical. Adding Parsers is probably harmless, but it is a behavior change in a "no behavior change" phase.

Router deltas: `:put_test_actor` browser plug (timeline_live_test ActorRouter :95-117), per-file `scope`/mount paths/opts, and `import Ecto.Query` plus helper `def`s inside ScopedRouters (actor_live_test :43-73). Those helper functions (`auth/1`, `scope_operator_query/3`, `actor_fn/1`) are referenced as `&__MODULE__.fun/n`, so they must remain defined **in the router module** after `use Threadline.OperatorSurfaceTest.Router`.

Titles "Copy contract" / "Rendered output contract" / "Stress Router Test" and cookie keys (`_threadline_key`) are asserted nowhere [VERIFIED: grep returned no matches outside the `<head><title>` literals]. Collapsing them is safe.

`exports_mix_parity_test.exs:42-49` does `_ = start_supervised(@endpoint)` on `ExportControllerTest.Endpoint` and ignores `{:error, {:already_started,_}}`. That is a cross-file coupling D-17 already targets.

Compile constraints for `test/support/operator_surface_case.ex`:
- `verify.compile_no_optional` runs `compile --no-optional-deps` in `:test` (ci.all's preferred env), which compiles `test/support`. Phoenix/LV are `optional: true` (mix.exs:92-95), so **the whole file must sit inside `if Code.ensure_loaded?(Phoenix.LiveView) do`**.
- Every module needs `@moduledoc` (ModuleDoc `ignore_names: []`).
- `quote` blocks must stay under 150 lines (LongQuoteBlocks default).

## ci.all Inventory (STRUCT-06)

`verify.doc_contract` references [VERIFIED: grep, excluding CHANGELOG history]:
- **mix.exs:** :13 (preferred env), :129-131 (alias; 21 files), :197 (ci.all).
- **.github/workflows:** ci.yml:379-381 (step `Doc contract tests` in `verify-test`), ci.yml:869 and :876 (comments), release.yml:578.
- **bin/verify-bump-rehearsal:** :379 (gate), :419 (summary).
- **tests:**
  - ci_topology_contract_test.exs:60-79 (alias-content asserts), :95 and :109-110 (`:binary.match`, raises when missing), :218-220 (`- name: Doc contract tests` / `run: mix verify.doc_contract`);
  - ci_workflow_parity_contract_test.exs:38-61 (step list plus ordering message);
  - evaluating_threadline_doc_contract_test.exs:42;
  - adoption_pilot_doc_contract_test.exs:92;
  - ci_coverage_doc_contract_test.exs:21-23 (moduledoc prose only).
- **docs:** CONTRIBUTING.md:508, :682; guides/evaluating-threadline.md:38, :57, :58; guides/configuration-and-commands.md:116; guides/adoption-pilot-backlog.md:5, :133 ("nine steps"); prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md:394, :424 (ungated prompt file; update for truthfulness).
- **CONTRIBUTING's critic_trust/mechanical "in ci.all" prose:** :154-155, :169, :303, :345, :397.

The 12 doc-contract files missing from the alias [VERIFIED: `comm` of the find output against the alias]: audit_indexing, ci_coverage, incident_playbook, integrations/sigra, operator_surface/{coverage, exports, policy_show, theme, timeline_browse}, performance, stg, support_playbook. After D-23 these run in the bump rehearsal for the first time. The `find` must run **inside `$CLONE`** (the gates run with `cd "$CLONE"`, see bin/verify-bump-rehearsal:367). The script uses `set -euo pipefail` (:89). Avoid `mapfile` for macOS bash 3.2 portability; `/usr/bin/env bash` here is 5.2, but contributors may differ. Use a `while IFS= read -r` loop.

Guides ship in the Hex package (`files:` includes `guides`), so D-25 guide edits are adopter-visible docs. Use commit type `docs`, which is not releasable per the release runbook memory.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Function-length measurement | awk/regex line counting | `Code.string_to_quoted(…, token_metadata: true)` `meta[:end][:line]` | Handles heredocs, `~H` blocks, and multi-line heads; the awk estimates in D-14 were off by 1–5 lines |
| Detecting real credo disables | grep | existing `credo_config_contract_test` scanner (`Code.string_to_quoted_with_comments`) | Already mirrors Credo's regex; string literals are not suppressions |
| Alias expansion in the D-24 guard | regex over mix.exs | `Mix.Project.config()[:aliases]` at runtime | Regex over ci.all already needed `:binary.match` gymnastics |
| CSS golden diffing | printing both binaries | first-differing-line and byte-offset reporter | ~100 KB binaries flood ExUnit output |
| Hex contents check | asserting `package/0` config | existing `built_archive()` in release_artifact_contract_test | "a gate that asserts its own inputs proves nothing" (mix.exs comment) |

## Runtime State Inventory (refactor phase)

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None. No DB rows, ChromaDB, or other store keys on module names or file paths. The operator-surface fixture manifest (`test/fixtures/operator_surface/manifest.sha256`) hashes evidence JSON, not source; verified by reading the fixture contract :50-66 | none |
| Live service config | GitHub branch protection / required checks reference **job ids** (e.g. `verify-test`, `ci-required`), not step names. Deleting a step leaves ids intact | none (no job id change) |
| OS-registered state | None. No launchd/systemd/pm2 artifacts reference these files | none |
| Secrets/env vars | None renamed. `ANTHROPIC_API_KEY` is only for `verify.ui_critique`, which is untouched | none |
| Build artifacts | `_build/{dev,test}` hold compiled beams for the modules being split. `@external_resource` makes `.css` edits recompile `style.ex`. Deleted modules leave stale beams until recompilation, and `mix compile --force` in the verify commands handles that. The `.dialyzer/` PLT covers deps only; project modules are re-analyzed | run the D-00 `compile --force --warnings-as-errors` per commit |

## Common Pitfalls

### Pitfall 1: Missing `Phoenix.HTML.raw` on the stylesheet assign
**What goes wrong:** `>` and `"` get HTML-escaped. The hash changes while the CSS looks identical in a browser inspector. **Proven** this session (prototype `no-raw identical: false`).
**How to avoid:** Wrap with `Phoenix.HTML.raw/1`; the byte lock catches it.

### Pitfall 2: Stale compiled CSS behind a green lock
**What goes wrong:** Without `@external_resource` for **every** segment, editing a `.css` file doesn't recompile `style.ex`. Locally the lock stays green against stale beams, and it fails only on a clean CI build.
**How to avoid:** Emit one `@external_resource` per `@segments` entry (the fonts.ex pattern: `for … do @external_resource … end`). Add a test asserting that `Style.__info__(:attributes)` or the module's `@external_resource` set covers every file in `style/` (this also catches an orphan `.css` that is never read).

### Pitfall 3: `.css` files missing from the Hex tarball
**What goes wrong:** Adopters compile threadline from source in `deps/`. A missing `.css` means `File.read!` raises at **their** compile time.
**Evidence it works today:** `files:` lists the `priv/fonts` *directory*, and fonts.ex reads those files at compile time in published releases, so directory entries are packaged recursively [VERIFIED: mix.exs:440 `files: ~w(lib priv/fonts …)`, fonts.ex @external_resource loop].
**How to avoid:** Still add `assert "lib/threadline/operator_surface/style/01_tokens.css" in entries` (and every segment) to release_artifact_contract_test's `built_archive()` test.

### Pitfall 4: Hex leak of maintainer-only extractions
**What goes wrong:** `exclude_patterns` are exact-file anchored: `~r{^lib/threadline/operator_surface/mechanical_checker\.ex$}` and `~r{^lib/threadline/operator_surface/live/stress_live\.ex$}` [VERIFIED: mix.exs:462-468]. `MechanicalChecker.Scorecards` at `mechanical_checker/scorecards.ex`, or a `stress_live/` sibling, **would publish** to Hex.
**How to avoid:** In the same commit, widen the pattern to `~r{^lib/threadline/operator_surface/mechanical_checker(\.ex$|/)}` (same for stress_live). Add the new prefixes to `@maintainer_only_prefixes` and the files to `@maintainer_only_paths` (release_artifact_contract_test.exs:152-170).

### Pitfall 5: Source-text pins break on move
**Known pins on files being split** [VERIFIED: grep plus reads this session]:
- **timeline_live.ex:** timeline_live_test.exs:1351, timeline_browse_doc_contract_test.exs (7 reads), exports_doc_contract_test.exs:19/32/156.
- **start_live.ex:** start_live_test.exs:399/564.
- **coverage_live.ex:** coverage_live_test.exs:115, coverage_doc_contract_test.exs:22.
- **export_controller.ex:** export_controller_test.exs:572, exports_doc_contract_test.exs:90-173.
- **query.ex:** query_test.exs:616, code_walkthrough_doc_contract_test.exs:21, exports/timeline_browse doc contracts.
- **ui.ex:** component_contract_test.exs (8 reads), plus ui_form_policy_contract_test and others. Grep `"lib/threadline/operator_surface/ui.ex"` before the split.
- **mechanical_checker.ex:** mechanical_checker_test.exs:13-59.
- **style.ex:** brandbook_token_parity:22, style_contract_test:5 (48 reads), component_contract_test:21/281/321/578, stress_router_test:136/525, rendered_output_contract_test:187/422.
- **Path lists:** release_artifact_contract_test.exs `@source_owners` (:16-47) and `@maintainer_only_paths` (:152-164) enumerate LiveView paths. New sibling files that carry user-visible copy should join the right `@source_owners` group so the archive vocabulary scan keeps covering them.

**How to avoid:** Before every extraction commit, run `grep -rn "<old path>" test examples/threadline_phoenix/test`.

### Pitfall 6: ui.ex split blast radius
~770 `UI.*` references (lib 247 / storybook 327 / test 198) [VERIFIED: grep -o count]. The example app's 8 `:page` stories alias `Threadline.OperatorSurface.UI` and call `UI.button` etc.; the capture spec only mentions it in a comment. All stories are `:page` kind, so no auto-generated code snippet renders the module name [VERIFIED: 8× `use PhoenixStorybook.Story, :page`]. HEEx debug annotations are **off** everywhere [VERIFIED: no `debug_heex_annotations` in config/ or the example config], so moving components doesn't change HTML.
**How to avoid:**
- One commit per family.
- Update storybook call sites, not `doc/0` prose.
- Run `mix verify.example` plus the browser lane after each family.
- `storybook_stories_test.exs:261` asserts `source =~ "Threadline.OperatorSurface.UI"`. That still matches `Threadline.OperatorSurface.UI.Actions`, but verify it.

### Pitfall 7: Endpoint env ordering and async
`Application.put_env(:threadline, Endpoint, secret_key_base: …, live_view: [signing_salt: …], render_errors: …)` must precede `start_supervised!`. The existing files do this in `setup_all` (e.g. stress_router_test.exs:138-143). Unique per-file endpoint module names avoid cross-file `already_started` coupling.

### Pitfall 8: Empty file list makes `mix test` run everything
This applies to D-23 and to the D-24 alias guard. Assert `length(files) >= 30` before invoking. Today there are 33 [VERIFIED: find].

### Pitfall 9: `ci.all` ordering asserts raise on a missing step
Both CI contract tests use `:binary.match(ci_block, "\"verify.doc_contract\"")`, which **raises a MatchError** (not a readable assertion) when the step is gone. Edit mix.exs and both tests in one commit.

### Pitfall 10: `ci_coverage_doc_contract_test` and the bump rehearsal first run
The 12 restored files run at `$NEXT` for the first time. A version-pinned assertion among them would make `verify-bump-rehearsal` red. Run `mix verify.bump_rehearsal` locally (preferred env `:dev`; it shells `bin/verify-bump-rehearsal`) before pushing.

## Code Examples

### Byte-lock rendered form and suffix (probe-verified)
```elixir
# Source: probe run this session (MIX_ENV=test mix run --no-start /tmp/p204/pivot.exs)
full =
  Threadline.OperatorSurface.Style.css(%{__changed__: nil})
  |> Phoenix.HTML.Safe.to_iodata()
  |> IO.iodata_to_binary()

prefix = "<style>" <> Threadline.OperatorSurface.Fonts.face_css() <> "</style>"
true = String.starts_with?(full, prefix)
style_owned = binary_part(full, byte_size(prefix), byte_size(full) - byte_size(prefix))
# style_owned begins "<style>\n  .threadline-ui {" and ends "  }\n</style>"
```

### Pivot shape (prototype that produced `pivot identical: true`)
```elixir
# Prototype used a runtime File.read!; production reads at compile time per D-02.
@segments ~w(stylesheet.css)                       # later: 01_tokens.css … 09_responsive.css, explicit order
@style_dir Path.join(__DIR__, "style")
for seg <- @segments, do: @external_resource Path.join(@style_dir, seg)
@stylesheet Enum.map_join(@segments, &File.read!(Path.join(@style_dir, &1)))

def css(assigns) do
  assigns =
    assigns
    |> assign(:fonts_html, Phoenix.HTML.raw(font_face_style()))
    |> assign(:stylesheet, Phoenix.HTML.raw(@stylesheet))

  ~H"""
  {@fonts_html}{@stylesheet}
  """
end
```
Whether `<style>`/`</style>` live in the file or in the Elixir concatenation is settled by the pivot commit (D-04). The prototype put them inside the file's bytes.

### Per-clause function length (AST)
```elixir
{:ok, ast} = Code.string_to_quoted(src, token_metadata: true, columns: true, file: path)
Macro.prewalk(ast, [], fn
  {kind, meta, [head | _]} = node, acc when kind in [:def, :defp, :defmacro, :defmacrop] ->
    len = if meta[:end], do: meta[:end][:line] - meta[:line] + 1, else: 1
    {node, [{name_arity(head), meta[:line], len} | acc]}
  node, acc -> {node, acc}
end)
# name_arity must unwrap {:when, _, [{name, _, args} | _]} guards.
```

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| HEEx `<%= %>` interpolation | `{…}` curly interpolation (LV 1.0+); disabled inside `<style>`/`<script>` | Why the 4.5k-line CSS with `{` braces works inside `~H` today; the prototype confirms `{@stylesheet}` in body context |
| Hand-listed test-file aliases | derive by filename at run time plus a floor | D-23 |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Moving CSS from HEEx *statics* into a *dynamic* `{@stylesheet}` doesn't change LiveView wire behavior materially. A zero-attr `<Style.css />` call is not re-evaluated on later diffs, the same as the already-dynamic 93 KB `{@fonts_html}` today | Pattern 2 | Live diffs could resend ~119 KB. HTML bytes (the locked contract) are unaffected. Mitigation: it already happens for fonts, if at all |
| A2 | `mix test` inside the bump-rehearsal clone runs in `:test` (Mix doesn't export `MIX_ENV=dev` to the child shell from a `:dev` preferred-env alias). The current script already relies on this for `verify.doc_contract` | ci.all Inventory | Rehearsal errors ("running in dev"). Detected by the required local run |
| A3 | `migration_content/0` is best handled as a named exception (a second exception beyond D-12) | Size Inventory | Needs maintainer confirmation; the alternative is a split behind a new output pin |
| A4 | The gating endpoint's lack of `Plug.Parsers` is incidental, but preserving it with a `parsers: false` option is the safe default | Test Templates | None if preserved |

## Open Questions

1. **Second size exception (`migration_content/0`, 138 lines).**
   - Known: it is one heredoc, adopter-visible output, with no golden test.
   - Unclear: whether the maintainer accepts 2 exceptions.
   - Recommendation: exception with reason. If refused, pin the output sha256 first, then split into up/down helpers.
2. **timeline_live second sibling.** Moving helpers alone lands at ~885 lines. The recommendation is `TimelineLive.Helpers` (presentation helpers :920–end) plus a filter-components sibling (`timeline_command` and `timeline_filter_drawer`), with doc-contract pins repointed through the source-family reader. This goes beyond D-08's "only if still over 800" wording, but it is the case D-08 anticipates.
3. **STRUCT-04 enforcement.** CONTEXT has none. The recommendation is a banner scan in `source_size_contract_test.exs`, at planner discretion on placement.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang/Elixir | all | ✓ | 27.3.4.15 / 1.17.3-otp-27 (`.tool-versions`, untracked; commands use `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27`) | — |
| Postgres test DB | `mix test` | ✓ | `localhost:5433 - accepting connections` | — |
| Node + Playwright | `mix verify.example_browser` | ✓ | node v22.14.0; `e2e/node_modules/.bin/playwright` present | — |
| Dialyzer PLT | `verify.dialyzer` | ✓ | `.dialyzer/dialyxir_erlang-27.3_elixir-1.17.3_deps-dev.plt` | `mix dialyzer --plt` on a cache miss |
| python3 | none (research only) | ✓ | — | — |

No blocking gaps.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17.3), LiveViewTest (LV 1.2.11), Playwright via `mix verify.example_browser` |
| Config file | `test/test_helper.exs` (excludes only `pgbouncer_topology` off-pooler) |
| Quick run command | `DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test <files>` |
| Full suite command | `DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix ci.all` |
| Compile gate | `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix compile --force --warnings-as-errors` and `MIX_ENV=test mix verify.compile_no_optional` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STRUCT-01 | rendered CSS sha256 plus golden suffix equality | unit/contract | `mix test test/threadline/operator_surface/style_byte_lock_test.exs` | ❌ Wave 0 |
| STRUCT-02 | segment order = cascade; every segment is `@external_resource`; no orphan `.css`; hash unchanged | contract | `mix test test/threadline/operator_surface/style_byte_lock_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/brandbook_token_parity_test.exs test/threadline/operator_surface/component_contract_test.exs test/threadline/operator_surface/rendered_output_contract_test.exs` | partial (lock ❌) |
| STRUCT-02 | `.css` segments ship in the Hex tarball | contract | `mix test test/threadline/release_artifact_contract_test.exs` | ✅ (add assertion) |
| STRUCT-03 | file ≤800 / clause ≤120 or exact exception; stale exception fails; no `.heex`/`embed_templates` | contract | `mix test test/threadline/source_size_contract_test.exs` | ❌ Wave 0 |
| STRUCT-04 | zero banner-regex lines in `lib/**/*.ex` | contract | same file (banner describe) | ❌ Wave 0 |
| STRUCT-05 | Endpoint/Router only in support or allowlist | contract | `mix test test/threadline/test_structure_contract_test.exs` | ❌ Wave 0 |
| STRUCT-06 | no `verify.doc_contract`; only `verify.test` expands to `test` in ci.all; no multi-path test alias | contract | `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs` (+ dedup guard) | ✅ (edit) / ❌ guard |
| STRUCT-06 | rehearsal derives ≥30 doc-contract files | script | `mix verify.bump_rehearsal` | ✅ (edit) |
| STRUCT-07 | register empty, ceiling 0, Credo clean | contract + lint | `mix test test/threadline/credo_config_contract_test.exs && mix credo --strict` | ✅ (edit) |
| D-00b | zero rendered-output change | e2e | `mix verify.example_browser` → exactly 8 known failures | ✅ |

### Sampling Rate
- **Per task commit:** compile `--force --warnings-as-errors` + byte lock + size gate + the tests that pin the touched file (grep for its path) + `mix credo --strict <touched files>`.
- **Per plan/wave merge:** `mix verify.test` + `mix verify.dialyzer` (dev) + `mix verify.xref_cycles` + `mix verify.compile_no_optional`. After any rendered-code wave, also `mix verify.example` and `mix verify.example_browser` (expect exactly 8 failures).
- **Phase gate:** `MIX_ENV=test mix ci.all` green (browser at 8 known) plus `mix verify.bump_rehearsal` locally.

### Wave 0 Gaps
- [ ] `test/threadline/operator_surface/style_byte_lock_test.exs` + `test/fixtures/style/operator_surface.css` + `test/fixtures/style/README.md` (STRUCT-01)
- [ ] `test/threadline/source_size_contract_test.exs` with file, function, banner, and heex guards, seeded at measured values (STRUCT-03/04)
- [ ] `test/support` source-family reader (and/or `Style.stylesheet/0`) before the first extraction
- [ ] `test/support/operator_surface_case.ex` + `test/threadline/test_structure_contract_test.exs` (STRUCT-05)
- [ ] ci.all dedup guard (STRUCT-06)

## Security Domain

`security_enforcement` is absent from config, so it is treated as enabled. The phase adds no inputs, auth, or crypto. The relevant control is **build/supply-chain integrity (ASVS V14 Configuration / V10 Malicious Code)**.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | unchanged (`authorize_fn`, auth plugs untouched; register-site refactors in `auth.ex` must preserve semantics) |
| V4 Access Control | yes (preserve) | `ExportAuthPlug`/`ThemeAuthPlug`/`authorize_fn` behavior is covered by existing gating/export_controller tests; the template migration must keep each test's authorize/scope fns |
| V5 Input Validation | yes (preserve) | `safe_validate/1`, filter validation, and cursor validation move modules only; `query_test`/export tests stay green |
| V10/V14 Build integrity | yes | `exclude_patterns` + `release_artifact_contract_test` proving the unpacked tarball; `.css` presence assertion |

| Threat Pattern | STRIDE | Mitigation |
|---------|--------|---------------------|
| Maintainer-only tooling published via an unmatched new file path | Information disclosure | Widen anchored `exclude_patterns` to directory prefixes and extend `@maintainer_only_*` in the same commit |
| Missing packaged `.css` breaks adopters' builds | Denial of service | Archive-entry assertion for every segment |
| Refactor of a register site in `auth.ex`/`evidence.ex` silently changes a branch | Elevation/Tampering | One site per commit; existing auth/gating tests; no behavior-changing rewrites (D-13 fallback) |

## Sources

### Primary (HIGH confidence, read or executed this session)
- Repo at HEAD `6aa08ba3`: `lib/threadline/operator_surface/{style,fonts,ui,mechanical_checker,router}.ex`, `live/timeline_live.ex`, `query.ex`, `governance/migration.ex`, `mix.exs` (:7-30, :122-215, :431-470), `bin/verify-bump-rehearsal` (:89, :360-420), `.github/workflows/ci.yml` (:370-382, :860-882)
- Tests read: `credo_config_contract_test.exs` (:1-140), `release_artifact_contract_test.exs` (:1-200), `ci_topology_contract_test.exs` (:50-115, :210-225), `ci_workflow_parity_contract_test.exs` (:1-75), `code_walkthrough_doc_contract_test.exs` (:15-110), `mechanical_checker_test.exs` (:13-75), `dialyzer_ignore_contract_test.exs` (:1-40), `dialyzer_slice_contract_test.exs` (:1-60), `operator_surface_fixture_contract_test.exs` (:45-69), `actor_live_test.exs` (:1-90), plus the grep inventories cited inline
- `deps/phoenix_live_view/lib/phoenix_live_view/tag_engine.ex:138-157`; `deps/credo/.credo.exs`; credo check `param_defaults`
- Empirical probes: rendered hash and bytes, fonts-off suffix identity, pivot prototype (raw vs non-raw), brace-depth cut verification, AST function lengths, endpoint normalization

### Secondary / Tertiary
- None. No external web sources were needed.

## Metadata

**Confidence breakdown:**
- CSS lock/split: HIGH. Prototyped end-to-end with exact bytes.
- Size/banner/register inventories: HIGH. Measured with AST and grep this session.
- Extraction plans (timeline, query, mechanical_checker): HIGH on constraints (pins read); MEDIUM on exact line targets (re-measure at execution).
- Test templates: HIGH. AST-normalized comparison.
- LiveView wire-diff effect of static→dynamic CSS: LOW (A1), but it doesn't affect the locked HTML contract.

**Research date:** 2026-09-23
**Valid until:** until the next commit touching `lib/threadline/operator_surface/` or `mix.exs` aliases. Line numbers drift, so re-measure at execution (D-14).
