# Roadmap: Threadline

## Active Milestone

### v1.18 — Adoption and Policy Hardening

**Status:** Active (planning complete, execution pending)
**Phases:** 64-68 (continuing from v1.17's last phase, no `--reset-phase-numbers`)
**Granularity:** coarse (per `.planning/config.json`)
**Coverage:** 16/16 v1.18 requirements mapped

**Goal:** Tighten what v1.17 shipped so production teams can roll the operator surface out cleanly. Round out the surface with a raw timeline browse + filter form (full `Threadline.Query.timeline/2` parity), exports UI parity (download current view), drift-aware policy viewers (coverage + redaction), and lifecycle ergonomics. Read-only throughout; zero new platform infrastructure; Mix-task parity for every UI viewer; the v1.17 optional-Phoenix-deps posture (`mix verify.compile_no_optional`) stays green across every phase.

#### Phases

- [x] **Phase 64: Raw Timeline Browse & Filter Form** — Ship the raw paged timeline browse LiveView with full `Threadline.Query.timeline/2` filter parity, URL-as-state via `live_patch`, and the doc-contract that locks the shared filter-key vocabulary (completed 2026-05-07)
- [ ] **Phase 65: Exports UI Parity** — Wire "Download CSV / JSON" of the currently-filtered view into the timeline browse, with sync iodata for small windows, chunked stream for large, pre-flight match-count preview, and Mix-task filename parity
- [ ] **Phase 66: Coverage Dashboard & Mix Task Parity** — Render `Threadline.Health.trigger_coverage/1` as a polled LiveView with optional `:schema` support, plus the parity `mix threadline.health.coverage` task for capture-only adopters
- [ ] **Phase 67: Drift-Aware Redaction Admin & Mix Task Parity** — Render the read-only config-vs-deployed redaction reconciliation viewer (column-only, never sample values) with `pg_proc.prosrc` introspection and the parity `mix threadline.policy.show` task
- [ ] **Phase 68: Lifecycle Ergonomics** — Revisit first-hour onboarding to mount the surface end-to-end, ship optional-Phoenix-deps upgrade-path docs, and clear the repo-wide `mix format` drift so `mix ci.all` is honest again

#### Phase Details

##### Phase 64: Raw Timeline Browse & Filter Form

**Goal**: Operators can browse and filter the raw audit timeline through a URL-addressable LiveView that shares one filter vocabulary with `Threadline.Query.timeline/2`, `Threadline.Export`, and `mix threadline.export`.
**Depends on**: Phase 63 (v1.17 close — operator surface, mount macro, auth contract)
**Requirements**: BROWSE-01, BROWSE-02, BROWSE-03, BROWSE-04
**Success Criteria** (what must be TRUE):
  1. Visiting the raw timeline browse route under the existing `threadline_operator_surface` macro renders a paged audit timeline; the v1.17 auth contract still applies (compile-time fail-closed, `:authorize_fn`-returned scope threaded into the underlying investigation queries) and the LiveView module compiles cleanly when `Phoenix.LiveView` is absent (`mix verify.compile_no_optional` stays green).
  2. The filter form accepts all five `Threadline.Query.timeline/2` keys — `from`, `to`, `table`, `actor_ref` (kind + id), `correlation_id` — using the same `validate_timeline_filters!/1` allowlist that gates the API and `mix threadline.export`, so no UI-only filter dialect can drift in.
  3. The current filter set is encoded in the URL via `live_patch` so pasting the URL into a fresh session reproduces the same results, browser back/forward navigates filter history, and first mount with no params defaults to a "last 24h" window with native `<input type="datetime-local">` and a `<select>` for actor kind (no custom widgets).
  4. A doc-contract test locks the LiveView route literal, the form input ARIA labels, and the filter key list (parity with `Threadline.Query.timeline/2`) so any future divergence between UI and API filter keys fails CI.
**Plans:** 3/3 plans complete
- [x] 64-01-PLAN.md — TimelineLive core: file-scope-gated LiveView (mount + handle_params + handle_event + render + scope_aware_opts/1), router edit (`live("/", TimelineLive, :index)`), CSS extension (toolbar/form/button-cluster), inline `← Timeline` back-links on TransactionLive + ActorLive headers (BROWSE-01 / BROWSE-02 / BROWSE-03)
- [x] 64-02-PLAN.md — LiveViewTest integration suite: mount + filter-apply + URL round-trip + datetime-tz norm + anonymous + correlation-id-too-long + scope-thread + phx-change-prohibition (BROWSE-01 / BROWSE-02 / BROWSE-03)
- [x] 64-03-PLAN.md — BROWSE-04 doc-contract test: pure source-reading test pinning route literal, ARIA labels, filter-key parity against `Threadline.Query.@allowed_timeline_filter_keys`, file-scope gate, native widgets, phx-change prohibition, and ← Timeline back-link presence on siblings (BROWSE-04)
**UI hint**: yes

##### Phase 65: Exports UI Parity

**Goal**: Operators can download the currently-filtered timeline view as CSV or JSON without leaving the surface, with the same filter vocabulary and the same file format Mix-task users get.
**Depends on**: Phase 64 (filter form + shared `validate_timeline_filters!/1` literal must already exist for the export controller to re-validate against)
**Requirements**: EXPO-03, EXPO-04, EXPO-05
**Success Criteria** (what must be TRUE):
  1. The raw timeline browse LiveView exposes "Download CSV" and "Download JSON" affordances; clicking either redirects (HTTP 303) to a Phoenix controller endpoint mounted under the operator surface that re-validates the filter params using `validate_timeline_filters!/1` and authorizes via the same `:authorize_fn` contract as the LiveView mount.
  2. Before the operator clicks download, a pre-flight `Threadline.Export.count_matching/2` renders the match count and a truncation banner; the controller streams windows above a configurable threshold (default 5,000 rows) via `Plug.Conn.send_chunked/2` + `Threadline.Export.stream_changes/2`, and sends iodata synchronously below the threshold.
  3. Downloaded files have UTC-ISO filenames (e.g. `threadline-changes-2026-05-06T12-00Z.csv`), `Content-Disposition: attachment; filename*=UTF-8''…` per RFC 5987, RFC 4180 CSV with `Content-Type: text/csv; charset=utf-8` and no BOM, and JSON wrapped + NDJSON variants matching `mix threadline.export` flags — identical filenames + bytes for identical filters.
  4. A doc-contract test locks the download button labels, filename format, and content-type literals; a focused integration test asserts the chunked-stream path completes for a window above the iodata threshold; a parity assertion proves the Mix task and the operator-surface controller produce identical files for identical filters.
**Plans:** 4 plans
- [ ] 65-01-PLAN.md — Library + helper foundation: additive `:cap` opt on `Threadline.Export.count_matching/2`, pure `Threadline.OperatorSurface.Exports.Filename` helper, pure `Threadline.OperatorSurface.Exports.FilterParams` shared parser (EXPO-04)
- [ ] 65-02-PLAN.md — HTTP surface: `Threadline.OperatorSurface.Controllers.ExportController` (3 actions, threshold dispatch, RFC 5987 dual-emit), `Threadline.OperatorSurface.ExportAuthPlug` (Conn-shaped twin of `Auth.on_mount/4` with `:export_authorize_fn` opt + synthetic `%{assigns: conn.assigns}` mirror), router macro grows sibling `scope <path>/exports` block (EXPO-03 + EXPO-04)
- [ ] 65-03-PLAN.md — LV surface: `TimelineLive` runs `count_matching` + `timeline_page` in parallel via `Task.async`, appends three `<.link href download>` anchors to `.button-cluster`, renders count status line + two-band truncation banner; CSS extension; `timeline_live_test.exs` extended with 4 cases (EXPO-03 + EXPO-04)
- [ ] 65-04-PLAN.md — EXPO-05 test trifecta: doc-contract test pinning all literals (button labels, route literals, content-type literals, filename helper output, file-scope gates, atom-safety refutations, `phx-change` refutation, chunked-stream pattern literals), chunked-stream integration test seeding 5,001 rows, Mix-task vs controller byte-equality parity test for all 3 formats (EXPO-05)
**UI hint**: yes

##### Phase 66: Coverage Dashboard & Mix Task Parity

**Goal**: Operators can see at a glance which audited tables are covered by triggers, including non-`public` schemas, with parity Mix-task access for capture-only adopters.
**Depends on**: Phase 63 (v1.17 close — surface mount + auth contract); does *not* depend on Phase 64/65 (no shared filter or export plumbing)
**Requirements**: COV-01, COV-02, COV-03
**Success Criteria** (what must be TRUE):
  1. A coverage dashboard LiveView under the operator surface (e.g. `/audit/coverage`) renders `Threadline.Health.trigger_coverage/1` with separate covered / uncovered table lists, expected-uncovered tables (e.g. `schema_migrations`) clearly marked, and an uncovered count surfaced in the surface header so an operator notices drift from any screen.
  2. `Threadline.Health.trigger_coverage/1` accepts an optional `:schema` argument (defaulting to `"public"` for backward compatibility) so Ecto-prefix and non-`public` schema adopters get correct results; the LiveView refreshes on a configurable poll interval (default 30s) and the existing `:health_checked` telemetry signal is hookable for refresh.
  3. A parity `mix threadline.health.coverage` task prints the same covered / uncovered data (table format + `--json`) so capture-only adopters who never mount the surface have identical access; a doc-contract test locks the LiveView route literal and the Mix-task help text + output schema.
**Plans**: TBD
**UI hint**: yes

##### Phase 67: Drift-Aware Redaction Admin & Mix Task Parity

**Goal**: Operators can confirm at a glance that the deployed per-table redaction matches `config :threadline, :trigger_capture` — the Logidze/Carbonite-class footgun (config edited without `gen.triggers` rerun) is now visible from both the surface and a Mix task, with a clear "rerun gen.triggers" hint when drift is detected.
**Depends on**: Phase 63 (v1.17 close — surface mount + auth contract); does *not* depend on Phases 64/65/66
**Requirements**: REDN-03, REDN-04, REDN-05
**Success Criteria** (what must be TRUE):
  1. A read-only redaction admin LiveView under the operator surface (e.g. `/audit/policy/redaction`) renders the configured `config :threadline, :trigger_capture` (re-validated through the existing `Threadline.Capture.RedactionPolicy.validate!/1`); each audited table shows column-level exclude / mask sets *by column name only* — sample values are never rendered in the UI or the Mix task output.
  2. For each audited table, the viewer compares the configured redaction set to the deployed redaction extracted from `pg_proc.prosrc`, parsed conservatively; on parse failure the table renders a "could not introspect — rerun `mix threadline.gen.triggers`" warning rather than silently passing; tables with matching sets show a "config matches deployed" badge, and tables with drift show a "drift detected" badge with a "rerun `mix threadline.gen.triggers`" hint.
  3. A parity `mix threadline.policy.show` task prints the same drift-aware config-vs-deployed view (table format + `--json`); a doc-contract test locks the LiveView route literal, the Mix-task output literals, the per-table badge state names, and asserts that no sample values appear in either surface.
**Plans**: TBD
**UI hint**: yes

##### Phase 68: Lifecycle Ergonomics

**Goal**: Close the v1.18 adoption-and-policy-hardening loop by making the documented first-hour path actually mount the now-shipped operator surface, by giving adopters a real upgrade-path doc for the optional Phoenix/LiveView/HTML/PubSub deps posture, and by clearing the repo-wide `mix format` drift that has blocked an honest `mix ci.all` since v1.16.
**Depends on**: Phases 64-67 (onboarding + upgrade-path docs must reflect the v1.18 surface as it actually shipped)
**Requirements**: ADOPT-05, ADOPT-06, ADOPT-07
**Success Criteria** (what must be TRUE):
  1. `guides/getting-started-saas.md`, the root `README.md` quickstart, and `examples/threadline_phoenix/README.md` document a first-hour path that actually mounts the operator surface end-to-end behind a `phx.gen.auth`-style admin pipeline (matching the v1.17 Phase 62 example wiring); the existing doc-contract test is extended to assert the new mount snippet appears verbatim in each surface.
  2. A new section in `guides/operator-surface.md` (or a new `guides/upgrade-path.md`) covers the version-compat matrix for the optional Phoenix/LiveView/HTML/PubSub deps, what changes between Threadline minors when those Phoenix majors shift, how adopters detect "capture-only vs surface-mounted" status at install time, and the deprecation/removal policy for surface-only changes; a doc-contract test locks the matrix table headers and the policy literals.
  3. Every untouched file outside the v1.16 / v1.17 closeout sets is formatted; `mix verify.format` and `mix ci.all` are green on `main` with no exceptions; GitHub Actions stable job IDs unchanged; the v1.16 / v1.17 STATE.md "format drift in untouched files" blocker is closed.
**Plans**: TBD

#### v1.18 Sequencing Rationale

The five-phase shape was accepted close to the planning prompt's suggested ordering. Each placement has a load-bearing reason:

- **Phase 64 must come first** because the filter form is the load-bearing artifact for the rest of the milestone — both the URL-as-state contract and the shared `validate_timeline_filters!/1` literal that Phase 65 re-validates against must exist before exports UI parity can be wired without inventing a parallel filter dialect.
- **Phase 65 must come immediately after Phase 64** because EXPO-04's controller endpoint re-validates the same filter params the LiveView mount accepts, and EXPO-05's parity assertion ("identical filters produce identical files") only makes sense once both halves of the filter contract are shipped on the same literal.
- **Phases 66 and 67 are intentionally not folded into one "policy admin" phase** even under coarse granularity, because COV-02 has a real lib-API change (the `:schema` argument on `Threadline.Health.trigger_coverage/1`) and REDN-04 has the heavyweight `pg_proc.prosrc` introspection logic; the two viewers are read-only siblings but their implementation surfaces and "what could go wrong" risks differ enough that one delivery boundary per viewer mirrors the v1.17 Phase 59/60/61 per-screen separation. They can run in either order or in parallel since neither depends on the other.
- **Phase 68 must come last** because ADOPT-05 (onboarding revisit) and ADOPT-06 (upgrade-path docs) document the surface as it actually shipped this milestone — running them before 64-67 would document a moving target. ADOPT-07 (repo-wide format drift cleanup) is the tidy closing slice that finally restores an honest `mix ci.all` so the next milestone can open without a known-blocker carry-forward.
- **The optional-Phoenix-deps posture stays green across every phase** — `mix verify.compile_no_optional` is part of `ci.all` and every UI phase (64, 65, 66, 67) must compile cleanly when `Phoenix.LiveView` is absent. This is a constraint on every phase, not a separate phase.

## Milestones

- 🟢 **v1.18 — Adoption and Policy Hardening** — Phases 64-68 (active, opened 2026-05-06) — [requirements](REQUIREMENTS.md)
- ✅ **v1.17 — Operator Surface Foundation** — Phases 57-63 (shipped 2026-05-06) — [requirements](milestones/v1.17-REQUIREMENTS.md) · [archive](milestones/v1.17-ROADMAP.md)
- ✅ **v1.16 — Investigation Table Stakes** — Phases 53-56 (shipped 2026-05-06) — [requirements](milestones/v1.16-REQUIREMENTS.md) · [archive](milestones/v1.16-ROADMAP.md)
- ✅ **v1.15 — Host Integration Completion** — Phases 49-52 (shipped 2026-05-05) — [requirements](milestones/v1.15-REQUIREMENTS.md) · [archive](milestones/v1.15-ROADMAP.md)
- ✅ **v1.14 — Drop-in Production Adopter Slice** — Phases 44-48 (shipped 2026-05-05) — [requirements](milestones/v1.14-REQUIREMENTS.md) · [archive](milestones/v1.14-ROADMAP.md)
- ✅ **v1.13 — Docs Contract Repair** — Phases 41-43 (shipped 2026-04-26) — [archive](milestones/v1.13-ROADMAP.md)
- ✅ **v1.12 — Temporal Truth & Safety** — Phases 38-40 (shipped 2026-04-25) — [archive](milestones/v1.12-ROADMAP.md)

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 64. Raw Timeline Browse & Filter Form | 3/3 | Complete   | 2026-05-07 |
| 65. Exports UI Parity | 0/4 | Planned     | - |
| 66. Coverage Dashboard & Mix Task Parity | 0/TBD | Not started | - |
| 67. Drift-Aware Redaction Admin & Mix Task Parity | 0/TBD | Not started | - |
| 68. Lifecycle Ergonomics | 0/TBD | Not started | - |

See `.planning/MILESTONE-ARC.md` for the standing ranked recommendation order beyond v1.18.
