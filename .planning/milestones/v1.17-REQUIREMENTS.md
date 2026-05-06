# Requirements: Threadline

**Defined:** 2026-05-06
**Milestone:** v1.17 — Operator Surface Foundation
**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Milestone goal:** Ship a host-usable operator surface — a mountable LiveView surface inside `threadline` (with Phoenix/LiveView as optional deps) that turns the v1.16 investigation contracts into one-click answers for the documented support questions, while preserving the v1.15 host-owns-auth boundary.

## v1.17 Requirements

### SURF — Mountable in-tree surface and dependency posture

- [ ] **SURF-01**: `Threadline.OperatorSurface.Router` exposes a `threadline_operator_surface "/path", opts` macro that hosts can `import` and call inside an existing `Phoenix.Router` scope's `pipe_through` to mount the operator surface in one line.
- [x] **SURF-02**: `phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub` are declared `optional: true` in `threadline`'s `mix.exs`, so capture-only adopters install `threadline` with no Phoenix or LiveView code compiled. *(Validated in Phase 57 plan 01, 2026-05-06.)*
- [x] **SURF-03**: All modules under `lib/threadline/operator_surface/` are gated via `Code.ensure_loaded?(Phoenix.LiveView)` (or the equivalent compile-time guard) so `threadline` compiles cleanly when LiveView is absent and adds zero observable overhead to the capture path. *(Validated in Phase 57 plan 01, 2026-05-06 — `Threadline.OperatorSurface` namespace module ships with file-scope wrap; `mix verify.compile_no_optional` exits 0 with zero warnings and the BEAM file is absent in the no-optional-deps build.)*
- [ ] **SURF-04**: `examples/threadline_phoenix` mounts the operator surface end-to-end behind a `phx.gen.auth`-style admin pipeline, demonstrating the canonical adopter wiring with both `:actor_fn` and `:authorize_fn` populated.

### UI — Operator screens

- [ ] **UI-01**: Incident drill-down LiveView at `/audit/transactions/:id` renders `Threadline.incident_bundle/2` — actor and request-context header, ordered changes with `Threadline.change_diff/2` per row, URL-addressable for log/ticket deep-links, and an explicit not-found state.
- [x] **UI-02**: Actor window LiveView at `/audit/actors/:kind/:id` renders `Threadline.actor_history/2` — time-window picker, paged transaction list, each row deep-links into UI-01, and an explicit empty state.
- [ ] **UI-03** *(should-have, slice 1 if cheap)*: Row history sub-view at `/audit/rows/:table/:pk` renders `Threadline.history/3` plus `Threadline.as_of/4` — reachable only from change rows in UI-01 (no orphan deep links), with an as-of timestamp picker that drives the `as_of/4` snapshot panel.

### CLI — Mix-task parity (no-LiveView operator path)

- [ ] **CLI-01**: `mix threadline.incident <transaction_id>` renders `Threadline.incident_bundle/2` to console with a human-readable layout; supports `--json` for pipeable output.

### AUTH — Mount-time auth contract

- [ ] **AUTH-01**: The mount macro accepts optional `:actor_fn` (passthrough to the existing `Threadline.Plug` shape) and optional `:authorize_fn` callbacks; both default to `nil`, and the docs explicitly note they are wiring slots, not policy.
- [ ] **AUTH-02**: The macro fails closed at compile time — it raises with a clear adopter-targeted error unless one of: (a) the scope it is mounted into has at least one `pipe_through`, (b) `:authorize_fn` is supplied, or (c) `:adopter_acknowledges_unauthenticated: true` is explicit.
- [ ] **AUTH-03**: `:adopter_acknowledges_unauthenticated: true` raises in `Mix.env() == :test`, emits exactly one `Logger.warning` per boot in `:prod`, and emits a `Logger.warning` in `:dev`. The flag's name is intentionally awkward to discourage casual use.
- [ ] **AUTH-04**: The `:authorize_fn` contract is documented and locked by a doc-contract test — `(Plug.Conn.t() | Phoenix.LiveView.Socket.t()) -> :ok | true | {:ok, scope :: map} | any()`, with allowlist semantics: anything other than `:ok | true | {:ok, scope}` is treated as a deny.
- [ ] **AUTH-05**: When `:authorize_fn` returns `{:ok, scope}`, the surface threads `scope` into investigation queries as a tenant/scope filter; when no scope is returned, the surface inherits whatever the host pipeline assigned to `conn.assigns` / `socket.assigns` (matching v1.15's incident-endpoint behavior). Threadline never invents a tenant model — it provides the slot.

### TELEM — Telemetry

- [ ] **TELEM-01**: Threadline emits a `[:threadline, :operator_surface, :authorize]` telemetry event on every authorize check with `%{result: :granted | :denied | :error}` measurements and `%{path, actor_ref, scope_keys}` metadata. The event is documented in `guides/domain-reference.md`'s telemetry section, and an integration test asserts it fires for granted and denied paths.

### DOC — Doc contracts and guides

- [x] **DOC-01**: A new doc-contract test locks the `Threadline.OperatorSurface.Router` macro signature, the default route literals (`/audit/transactions/:id`, `/audit/actors/:kind/:id`, plus `/audit/rows/:table/:pk` if UI-03 ships), and the README's auth section.
- [x] **DOC-02**: A new guide `guides/operator-surface.md` covers mount, the `:actor_fn` / `:authorize_fn` options, the screens, the documented support questions each screen answers, and the `mix threadline.incident` companion task.
- [x] **DOC-03**: README acquires a top-level "Operator Surface" section pointing to the new guide; `guides/production-checklist.md` gains an operator-surface row; `examples/threadline_phoenix/README.md` documents the wired example end-to-end.
- [x] **DOC-04**: `CHANGELOG.md` entry for the next published Hex version (likely `0.4.0`) documents the new optional Phoenix/LiveView deps, the `Threadline.OperatorSurface.Router` mount macro, and the required `mix.exs` adjustment for hosts that want the surface.

## Future Requirements (carried forward)

- **UI-FILTER-01**: Paged timeline browse with filter form (`:table`, `:from`, `:to`, `:correlation_id`, `:actor_ref`) — deferred to v1.18 because raw paging without filters is operator drudgery (CloudTrail Event History pre-filters lesson).
- **UI-EXPORT-01**: "Export this view" button on the operator screens that emits the same slice as `Threadline.Export` for review/parity — deferred to v1.18.
- **WEB-PKG-01**: Promotion of the in-tree operator surface into a separate `threadline_web` Hex companion package — deferred to v1.19+ when adoption + version-matrix pressure justifies the double-tagging burden. Migration path: rename `Threadline.OperatorSurface.Router` → `Threadline.Web.Router`, deprecation overlap, then extract.
- **POLICY-01**: Richer policy and governance guardrails once real adopter workflows expose the sharpest gaps — deferred until the v1.17 surface has live adopters.
- **INTEG-01**: Broaden the integration surface beyond Phoenix + Sigra after the investigation backbone and operator surface are easier to reuse across hosts.
- **ADOPT-05**: Compress first-hour adoption further once v1.17 ships — likely a v1.18 candidate after the operator workflow is real to teach.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Hard LiveView / Phoenix dependency in `threadline` core | Out of scope by design. The v1.17 surface is gated on `phoenix_live_view` as an `optional: true` dep so capture-only adopters keep a Plug-only install footprint; making LV a hard dep would betray that posture and the audit-platform "not a UI lib" stance. |
| Separate `threadline_web` companion Hex package | Deferred to v1.19+. Splitting at v0.3.0 with one maintainer doubles the release/version-matrix burden when the surface is still small. LiveDashboard, Oban Web, and Ash Admin all split *after* their core had hundreds of adopters. |
| Raw paged timeline browse (no filter form) | Without filters, operator timelines are drudgery — CloudTrail Event History lesson. Deferred to v1.18 along with the filter form work that makes it useful. |
| Saved views, redaction admin, retention admin, coverage dashboard | All belong on the operator surface eventually; v1.17 must stay scoped to a coherent two/three-screen first slice that proves the contract. |
| Generic tenancy or authorization policy framework | Threadline keeps host-owned tenancy and authorization (v1.15 boundary). The mount macro provides slots (`:actor_fn`, `:authorize_fn`); it does not own policy. |
| Free-text JSONB search across audit changes | Performance footgun (CloudTrail trap). Deferred indefinitely; investigation queries stick to indexed columns documented in `guides/audit-indexing.md`. |
| "Issue grouping" of similar audit changes | Sentry footgun mismatched with audit semantics — audit events are facts, not errors. One row = one fact. |
| Multi-tenant / prefix-scoped capture beyond Ecto prefix support | Unchanged from prior milestones — defer until basic capture is validated and a real adopter asks for it. |

## Traceability

Mapped by `gsd-roadmapper` on 2026-05-06.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SURF-01 | Phase 58 | Pending |
| SURF-02 | Phase 57 | Validated |
| SURF-03 | Phase 57 | Validated |
| SURF-04 | Phase 62 | Pending |
| UI-01 | Phase 59 | Pending |
| UI-02 | Phase 60 | Validated |
| UI-03 | Phase 61 | Pending |
| CLI-01 | Phase 62 | Pending |
| AUTH-01 | Phase 58 | Pending |
| AUTH-02 | Phase 58 | Pending |
| AUTH-03 | Phase 58 | Pending |
| AUTH-04 | Phase 58 | Pending |
| AUTH-05 | Phase 58 | Pending |
| TELEM-01 | Phase 58 | Pending |
| DOC-01 | Phase 63 | Validated |
| DOC-02 | Phase 63 | Validated |
| DOC-03 | Phase 63 | Validated |
| DOC-04 | Phase 63 | Validated |

**Coverage at roadmap close:**
- v1.17 requirements: 18 total (17 must-have + 1 should-have)
- Mapped to phases: 18/18 ✓
- Validated: 2/18 (SURF-02, SURF-03 in Phase 57)

## Notes

- Phase numbering continues from v1.16; v1.17 starts at **Phase 57** (no `--reset-phase-numbers`).
- Three parallel research agents grounded these requirements: surface-shape (cited LiveDashboard, Oban Web, Ash Admin, Kaffy, Backpex, Pow, Sentry-Elixir, Carbonite); workflow-scope (cited CloudTrail, Sentry, Datadog, GCP Cloud Audit Logs, Stripe, Okta, GitHub, temporal.io, PaperTrail viewer gems); auth-model (cited LiveDashboard, Oban Web, Sidekiq Web, GoodJob, Hangfire, Django Admin, Flask-Admin, Bull Board).
- The auth contract intentionally adopts Hangfire's fail-closed default + Oban Web's resolver shape — the most conservative posture in the ecosystem, on-brand for an audit-trail surface (highest-stakes leak target).
