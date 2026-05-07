# Threadline v1.18 — Adoption and Policy Hardening

**Milestone:** v1.18 — Adoption and Policy Hardening
**Opened:** 2026-05-06
**Phase numbering:** continues from 63 → starts at Phase 64

## Goal

Tighten what v1.17 shipped so production teams can roll the operator surface out cleanly. Round out the surface with a raw timeline browse + filter form (full API parity), exports UI parity (download current view), drift-aware policy viewers (coverage + redaction), and lifecycle ergonomics. Read-only throughout; zero new platform infrastructure; Mix-task parity for every UI viewer.

## Scope summary

- **Raw timeline browse + filter form** — full `Threadline.Query.timeline/2` filter parity (date range, table, actor_ref kind+id, correlation_id), URL-as-state via `live_patch`, reuses the existing `validate_timeline_filters!/1` allowlist.
- **Exports UI parity** — "Download CSV / JSON" of the currently-filtered view from inside the LiveView; sync `iodata` for small windows, chunked stream via `Plug.Conn.send_chunked/2` + `Threadline.Export.stream_changes/2` for large; pre-flight `count_matching/2` preview.
- **Coverage dashboard** — wraps `Threadline.Health.trigger_coverage/1` with poll interval + `:schema` option; parity Mix task `mix threadline.health.coverage`.
- **Drift-aware redaction admin** — config-vs-deployed reconciliation comparing `config :threadline, :trigger_capture` against `pg_proc.prosrc`-derived deployed redaction, with a "config matches deployed" badge per table; never displays sample values; parity Mix task `mix threadline.policy.show`.
- **Lifecycle ergonomics** — quickstart revisit so the first-hour onboarding mounts the surface end-to-end; upgrade-path docs for the optional-Phoenix-deps posture; repo-wide `mix format` drift cleanup so `mix ci.all` is honest again.

## v1.18 Requirements

### Raw timeline browse + filter form (BROWSE)

- [ ] **BROWSE-01** — Ship a raw paged timeline browse LiveView under the existing `threadline_operator_surface` macro, gated by `Code.ensure_loaded?(Phoenix.LiveView)` (capture-only adopters compile cleanly), requires no new dependencies; threads `:authorize_fn`-returned scope into investigation queries per the v1.17 auth contract.
- [ ] **BROWSE-02** — Filter form ships full `Threadline.Query.timeline/2` parity — `from`, `to`, `table`, `actor_ref` (kind + id), `correlation_id` — using the existing `validate_timeline_filters!/1` allowlist so UI / API / `Threadline.Export` / `mix threadline.export` share one filter literal.
- [ ] **BROWSE-03** — Filter state is URL-as-state via `live_patch`; the URL alone reproduces results (paste-into-Slack share); browser back/forward navigates filter history; first mount defaults to a "last 24h" window with no other filters; native `<input type="datetime-local">` and a `<select>` for actor kind (no custom widgets).
- [ ] **BROWSE-04** — Doc-contract test locks the LiveView route literal, the form input ARIA labels, and the filter key list (parity with `Threadline.Query.timeline/2` allowlist) so any future divergence between UI and API filter keys fails CI.

### Exports UI parity (EXPO)

- [ ] **EXPO-03** — "Download CSV" and "Download JSON" affordances on the raw timeline browse LiveView; LiveView event redirects (HTTP 303) to a Phoenix controller endpoint under the operator surface that re-validates the filter params using `validate_timeline_filters!/1` and authorizes via the same `:authorize_fn` contract as the LiveView mount.
- [x] **EXPO-04** — Controller streams large windows via `Plug.Conn.send_chunked/2` + `Threadline.Export.stream_changes/2`; sends iodata synchronously for windows below a configurable threshold (default 5,000 rows); pre-flight `Threadline.Export.count_matching/2` renders match count and truncation banner *before* click. Filenames are UTC-ISO (`threadline-changes-2026-05-06T12-00Z.csv`), `Content-Disposition: attachment; filename*=UTF-8''…` per RFC 5987, RFC 4180 CSV with `Content-Type: text/csv; charset=utf-8` and no BOM, JSON wrapped + NDJSON variants matching `mix threadline.export` flags.
- [ ] **EXPO-05** — Doc-contract test locks download button labels, filename format, content-type literals, and Mix-task flag parity (`mix threadline.export` and the operator surface produce identical files for identical filters); a focused integration test asserts the chunked-stream path completes for a window above the iodata threshold.

### Coverage dashboard (COV)

- [ ] **COV-01** — Coverage dashboard LiveView at a route under the operator surface (e.g. `/audit/coverage`) renders `Threadline.Health.trigger_coverage/1` with separate covered / uncovered table lists, expected-uncovered marked (e.g. `schema_migrations`), uncovered counts surfaced in the surface header.
- [ ] **COV-02** — `Threadline.Health.trigger_coverage/1` accepts an optional `:schema` argument (defaults to `"public"` for backward compatibility) so Ecto-prefix and non-`public` schema adopters get correct results; LiveView refreshes on a configurable poll interval (default 30s); telemetry signal `:health_checked` is hookable for refresh.
- [ ] **COV-03** — Parity Mix task `mix threadline.health.coverage` prints the same covered / uncovered data (table format + `--json` flag) for capture-only adopters who never mount the surface; doc-contract test locks the LiveView route literal and the Mix-task help text + output schema.

### Drift-aware redaction admin (REDN)

- [ ] **REDN-03** — Read-only redaction admin LiveView at a route under the operator surface (e.g. `/audit/policy/redaction`) renders the configured `config :threadline, :trigger_capture` (re-validated via existing `Threadline.Capture.RedactionPolicy.validate!/1`); displays per-table column-level exclude / mask sets with column names only — sample values are never rendered.
- [ ] **REDN-04** — Drift detection — for each audited table, the viewer compares the configured redaction set to the deployed redaction extracted from `pg_proc.prosrc` (parsed conservatively; on parse failure show a "could not introspect — rerun gen.triggers" warning rather than silently passing); each table displays a "config matches deployed" / "drift detected" badge with a "rerun `mix threadline.gen.triggers`" hint when mismatched.
- [ ] **REDN-05** — Parity Mix task `mix threadline.policy.show` prints the same drift-aware config-vs-deployed view (table format + `--json` flag); doc-contract test locks the LiveView route literal, the Mix-task output literals, the per-table badge state names, and asserts that no sample values appear in either surface.

### Lifecycle ergonomics (ADOPT)

- [ ] **ADOPT-05** — First-hour onboarding revisit — `guides/getting-started-saas.md`, the root `README.md` quickstart, and `examples/threadline_phoenix/README.md` updated so the documented first-hour path actually mounts the operator surface end-to-end behind a `phx.gen.auth`-style admin pipeline (matching the v1.17 Phase 62 example wiring); doc-contract test extended to assert the new mount snippet appears verbatim in each surface.
- [ ] **ADOPT-06** — Upgrade-path docs for the optional Phoenix/LiveView/HTML/PubSub deps posture: a new section (in `guides/operator-surface.md` or a new `guides/upgrade-path.md`) covering the version-compat matrix, what changes between Threadline minors when Phoenix/LiveView majors shift, how adopters detect "capture-only vs surface-mounted" status, and the deprecation/removal policy for surface-only changes; doc-contract test locks the matrix table headers and the policy literals.
- [ ] **ADOPT-07** — Repo-wide `mix format` drift cleanup — every untouched file outside the v1.16 / v1.17 closeout sets formatted; `mix verify.format` and `mix ci.all` are green on `main` with no exceptions; GitHub Actions stable job IDs unchanged; the v1.16 / v1.17 STATE.md "format drift in untouched files" blocker is closed in this milestone.

## Future Requirements (deferred from v1.18)

- **Saved views** in the operator surface (named filter combos with owner / visibility / sharing) — deferred to v1.19+; bookmarks + URL state cover the persistence story for free at this stage. Adding it would drag a tiny new auth model into a lib that has stayed auth-agnostic since v1.15.
- **Queued / Oban-based exports + status page + scheduled exports** — deferred to v1.20+ unless real adopters report row-cap pain on real incidents. Adding Oban as a hard dep walks back the v1.17 optional-deps win, and storage adapters / file-expiry semantics are platform creep.
- **Retention admin viewer with last-purge stats** — deferred to v1.19. "Last purge" requires net-new `audit_retention_runs` capture machinery (writes from `Threadline.Retention.purge/1`), which broadens the milestone rather than hardens it; revisit when the capture surface is decided.
- **Email-when-ready / link-expiry exports** — deferred indefinitely; not on the v1.20 candidate list.
- **Multi-repo coverage** — deferred to v1.19+; v1.18 ships single-repo only.
- **Companion `threadline_web` extraction** — still v1.19+ candidate, with documented promotion path; revisit when the in-tree surface has live adopters.

## Out of Scope (explicit exclusions for v1.18)

- **Runtime edits to redaction, retention, or coverage policy from any viewer** — the read-only ceiling holds. An audit lib that lets you mutate redaction from a web UI is itself a compliance vector; users edit `config/runtime.exs` and rerun `mix threadline.gen.triggers`.
- **"Purge now" buttons on retention** — destructive operations stay on the Mix-task path (`mix threadline.retention.purge`) where host auth elevation is the operator's concern.
- **New auth adapters** — host stays in charge per the v1.15 boundary; adapters and `threadline_sigra`-style integrations are v1.19+ scope.
- **CDC / WAL / new storage backend** — out of scope across the entire arc per `MILESTONE-ARC.md`.
- **SIEM-grade reporting / compliance depth** — out of scope; v1.20+ at earliest, informed by real adopter pain.
- **Hard Phoenix / LiveView dependency in `threadline` core** — the v1.17 optional-deps posture is preserved; v1.18 viewers and Mix tasks all work in capture-only adopter compiles.

## REQ-ID conventions

- `BROWSE` (new in v1.18) — Raw timeline browse + filter form
- `EXPO` — Continues v1.3's export-library numbering (EXPO-01 / EXPO-02 shipped in v1.3 covered the lib + Mix task; EXPO-03..05 cover the operator-surface UI variant)
- `COV` (new in v1.18) — Coverage dashboard
- `REDN` — Continues v1.3's redaction-policy numbering (REDN-01 / REDN-02 shipped in v1.3 covered capture-time exclude/mask; REDN-03..05 cover the drift-aware admin viewer)
- `ADOPT` — Continues the v1.5 / v1.14 adopter-onboarding numbering (ADOPT-01..04 shipped earlier; ADOPT-05..07 cover this milestone's lifecycle ergonomics)

## Traceability

| REQ-ID    | Phase | Status |
|-----------|-------|--------|
| BROWSE-01 | 64    | mapped |
| BROWSE-02 | 64    | mapped |
| BROWSE-03 | 64    | mapped |
| BROWSE-04 | 64    | mapped |
| EXPO-03   | 65    | mapped |
| EXPO-04   | 65    | complete (Plan 65-01) |
| EXPO-05   | 65    | mapped |
| COV-01    | 66    | mapped |
| COV-02    | 66    | mapped |
| COV-03    | 66    | mapped |
| REDN-03   | 67    | mapped |
| REDN-04   | 67    | mapped |
| REDN-05   | 67    | mapped |
| ADOPT-05  | 68    | mapped |
| ADOPT-06  | 68    | mapped |
| ADOPT-07  | 68    | mapped |

---
*REQ count: 16 across 5 categories. All 16 mapped to phases 64-68.*
