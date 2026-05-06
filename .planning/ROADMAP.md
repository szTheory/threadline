# Roadmap: Threadline

## Active Milestone

### v1.17 — Operator Surface Foundation

**Status:** Active (planning complete, execution pending)
**Phases:** 57-63 (continuing from v1.16's last phase, no `--reset-phase-numbers`)
**Granularity:** coarse (per `.planning/config.json`)
**Coverage:** 18/18 v1.17 requirements mapped (17 must-have + 1 should-have)

**Goal:** Ship a host-usable operator surface — a mountable LiveView surface inside `threadline` (with Phoenix/LiveView as optional deps) that turns the v1.16 investigation contracts into one-click answers for the documented support questions, while preserving the v1.15 host-owns-auth boundary.

#### Phases

- [x] **Phase 57: Optional Deps & Module Gating** — Declare Phoenix/LiveView as optional deps and gate the operator surface modules so capture-only adopters keep a Plug-only install footprint *(shipped 2026-05-06; plan 01 SUMMARY)*
- [ ] **Phase 58: Mount Macro & Auth Contract** — Ship the one-line mount macro, the host-mount-default + `:authorize_fn` auth contract, the compile-time fail-closed check, and the authorize telemetry event
- [ ] **Phase 59: Incident Drill-down Screen** — Render `Threadline.incident_bundle/2` as a URL-addressable LiveView with actor/context header, ordered diff rows, and explicit not-found state
- [ ] **Phase 60: Actor Window Screen** — Render `Threadline.actor_history/2` as a paged LiveView with time-window picker, deep-links into incident drill-down, and explicit empty state
- [ ] **Phase 61: Row History & As-of Sub-view** — Render `Threadline.history/3` plus `Threadline.as_of/4` as a sub-view reachable only from incident drill-down change rows, with a timestamp picker driving the as-of snapshot panel
- [ ] **Phase 62: Mix Task & Example-app Wiring** — Ship `mix threadline.incident <transaction_id>` (with `--json`) and wire the operator surface end-to-end in `examples/threadline_phoenix` behind a `phx.gen.auth`-style admin pipeline
- [ ] **Phase 63: Docs, Contracts & Changelog** — Lock the macro/route/auth literals with a doc-contract test, ship `guides/operator-surface.md`, surface it from the README and production checklist, and document the new optional deps in CHANGELOG for the next Hex release

#### Phase Details

##### Phase 57: Optional Deps & Module Gating

**Goal**: Make Phoenix/LiveView opt-in at install time so capture-only adopters never compile UI code.
**Depends on**: Phase 56 (v1.16 close)
**Requirements**: SURF-02, SURF-03
**Success Criteria** (what must be TRUE):
  1. `mix.exs` declares `phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub` with `optional: true` so an adopter who installs `threadline` without those deps gets zero UI code compiled into their release.
  2. Every module under `lib/threadline/operator_surface/` is gated behind a `Code.ensure_loaded?(Phoenix.LiveView)` (or compile-time-equivalent) guard so `mix compile --warnings-as-errors` succeeds with and without LiveView present.
  3. The capture path's runtime behavior is observably unchanged when LiveView is absent — no new modules loaded, no boot-time warnings, no telemetry events fired.
**Plans**: 1 plan

Plans:
- [x] 57-01-PLAN.md — Optional deps + gated namespace module + verify.compile_no_optional alias + GH Actions job + CONTRIBUTING.md row *(shipped 2026-05-06; SURF-02 + SURF-03 validated; five atomic commits 4281556/b8e7044/409d135/5d0aebf/719d7ac)*
**UI hint**: yes

##### Phase 58: Mount Macro & Auth Contract

**Goal**: Give hosts a one-line mount macro with the most conservative auth posture in the ecosystem (fail-closed by default, host-owned policy).
**Depends on**: Phase 57
**Requirements**: SURF-01, AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, TELEM-01
**Success Criteria** (what must be TRUE):
  1. A host can `import Threadline.OperatorSurface.Router` and call `threadline_operator_surface "/audit", opts` inside a `Phoenix.Router` scope's `pipe_through` to mount the surface in one line.
  2. The mount macro raises a clear adopter-targeted compile error unless one of: the scope has at least one `pipe_through`, `:authorize_fn` is supplied, or `:adopter_acknowledges_unauthenticated: true` is explicit; the awkward escape hatch raises in `:test`, emits one `Logger.warning` per boot in `:prod`, and warns in `:dev`.
  3. `:authorize_fn` accepts the documented `(Plug.Conn.t() | Phoenix.LiveView.Socket.t()) -> :ok | true | {:ok, scope :: map} | any()` shape with allowlist semantics — anything other than `:ok | true | {:ok, scope}` denies — and `{:ok, scope}` threads `scope` into the surface's investigation queries while non-scope returns inherit `conn.assigns` / `socket.assigns` (matching v1.15 incident-endpoint behavior).
  4. Every authorize check emits a `[:threadline, :operator_surface, :authorize]` telemetry event with `%{result: :granted | :denied | :error}` measurements and `%{path, actor_ref, scope_keys}` metadata, asserted by an integration test on both granted and denied paths.
**Plans**: 3 plans

Plans:
- [ ] 58-01-PLAN.md — Establish module skeletons, Mix configuration, and doc-contract gating test
- [ ] 58-02-PLAN.md — Implement compile-time AST checking and Router mount macro (TDD)
- [ ] 58-03-PLAN.md — Implement LiveView on_mount lifecycle hook and telemetry (TDD)
**UI hint**: yes

##### Phase 59: Incident Drill-down Screen

**Goal**: Turn `Threadline.incident_bundle/2` into a one-click answer for "what happened in this transaction" with a URL-addressable LiveView.
**Depends on**: Phase 58
**Requirements**: UI-01
**Success Criteria** (what must be TRUE):
  1. Visiting `/audit/transactions/:id` renders the incident bundle with an actor/request-context header and ordered changes laid out per row using `Threadline.change_diff/2`.
  2. The screen URL is a stable deep-link suitable for log/ticket references — pasting `/audit/transactions/<known_id>` from a fresh session lands directly on the bundle without prior navigation state.
  3. Visiting an unknown or malformed `:id` renders an explicit not-found state (no crash, no mis-attributed empty bundle) so operators can distinguish "no such transaction" from "transaction with zero changes."
**Plans**: TBD
**UI hint**: yes

##### Phase 60: Actor Window Screen

**Goal**: Turn `Threadline.actor_history/2` into a one-click answer for "what did this actor do recently" with deep-links into the incident drill-down.
**Depends on**: Phase 59
**Requirements**: UI-02
**Success Criteria** (what must be TRUE):
  1. Visiting `/audit/actors/:kind/:id` renders a paged transaction list for that actor with a time-window picker that drives the underlying `actor_history/2` call.
  2. Each transaction row in the list links to the corresponding `/audit/transactions/:id` drill-down so the operator can move from "who" to "what" without leaving the surface.
  3. Visiting an actor with no recorded activity in the chosen window renders an explicit empty state (no crash, no orphan loading spinner).
**Plans**: TBD
**UI hint**: yes

##### Phase 61: Row History & As-of Sub-view

**Goal**: Make per-row history and point-in-time reconstruction reachable from the drill-down without inviting orphan deep-links to it.
**Depends on**: Phase 59 (drill-down owns the only entry point)
**Requirements**: UI-03
**Success Criteria** (what must be TRUE):
  1. Clicking a change row inside a `/audit/transactions/:id` drill-down navigates to `/audit/rows/:table/:pk`, which renders `Threadline.history/3` for that row.
  2. The sub-view exposes an as-of timestamp picker that drives a `Threadline.as_of/4` snapshot panel alongside the history list, so operators can compare "history of this row" against "what this row looked like at time T."
  3. The route is reachable only from drill-down change rows — there is no top-level navigation entry, no actor-window link, and the routing literal is documented as the deep-link only path so the orphan-deep-link surface stays intentionally narrow.
**Plans**: TBD
**UI hint**: yes

##### Phase 62: Mix Task & Example-app Wiring

**Goal**: Ship the no-LiveView operator path and prove the canonical adopter wiring end-to-end in the Phoenix example.
**Depends on**: Phase 58 (mount macro), Phase 59-61 (screens to wire)
**Requirements**: CLI-01, SURF-04
**Success Criteria** (what must be TRUE):
  1. Running `mix threadline.incident <transaction_id>` from a host project renders the same `Threadline.incident_bundle/2` data as the LiveView drill-down, in a human-readable console layout, so SSH-only operators can answer the marquee question without mounting the surface.
  2. The same Mix task supports `--json` and emits a single pipeable JSON document on stdout, ready for `jq` or downstream tooling without hand-stripping log lines.
  3. `examples/threadline_phoenix` mounts the operator surface end-to-end behind a `phx.gen.auth`-style admin pipeline with both `:actor_fn` and `:authorize_fn` populated, and a request-path test proves an authenticated admin reaches `/audit/transactions/<seeded_id>` while an anonymous request is rejected by the host pipeline.
**Plans**: TBD
**UI hint**: yes

##### Phase 63: Docs, Contracts & Changelog

**Goal**: Make the new operator surface discoverable, contract-locked, and release-noted so future drift fails CI instead of shipping silently.
**Depends on**: Phase 62
**Requirements**: DOC-01, DOC-02, DOC-03, DOC-04
**Success Criteria** (what must be TRUE):
  1. A new doc-contract test asserts the `Threadline.OperatorSurface.Router` macro signature, the default route literals (`/audit/transactions/:id`, `/audit/actors/:kind/:id`, `/audit/rows/:table/:pk`), and the README's auth section verbatim — drifting any of these fails `mix verify.doc_contract`.
  2. A new `guides/operator-surface.md` exists and covers mount, the `:actor_fn` / `:authorize_fn` options, each shipped screen, the documented support questions each screen answers, and the `mix threadline.incident` companion task.
  3. The README has a top-level "Operator Surface" section pointing to the new guide; `guides/production-checklist.md` has an operator-surface row; `examples/threadline_phoenix/README.md` documents the wired example end-to-end.
  4. `CHANGELOG.md` has an entry for the next published Hex version (likely `0.4.0`) documenting the new `optional: true` Phoenix/LiveView deps, the `Threadline.OperatorSurface.Router` mount macro, and the `mix.exs` adjustment hosts need to wire the surface.
**Plans**: TBD

#### v1.17 Sequencing Rationale

The seven-phase shape was accepted as proposed in the planning prompt. Each placement has a load-bearing reason:

- **Phase 57 must come first** because every later phase mounts code under `lib/threadline/operator_surface/`; without optional-dep declarations and module gating, capture-only adopters would either pay UI compile cost or `mix compile` would fail.
- **Phase 58 must come before any screen phase (59-61)** because the mount macro and `:authorize_fn` contract define the request-shape every screen receives; building screens against a non-existent or non-fail-closed mount path would force rework once the auth contract lands.
- **Phases 59 → 60 → 61** are ordered by deep-link dependency: the actor window (60) deep-links into the drill-down (59), and the row history sub-view (61) is reachable *only* from drill-down change rows. Building 60 or 61 before 59 would mean shipping deep-links into a non-existent target.
- **Phase 62 (Mix task + example-app wiring)** is placed after 58-61 rather than early because (a) SURF-04 wires *all* shipped screens, so it depends on 59-61, and (b) bundling CLI-01 here keeps the "wire up the no-LiveView operator path" work in one delivery boundary alongside the example-app wiring that DOC-02 will then reference. CLI-01 is technically independent of the screens (it only reads `Threadline.incident_bundle/2` shipped in v1.16), but the docs phase needs both shipped before it can document them.
- **Phase 63 must come last** because DOC-01 locks route literals from 58-61, DOC-02 documents the screens from 59-61 and the Mix task from 62, DOC-03 references the wired example from 62, and DOC-04 documents the optional-dep change from 57 + the mount macro from 58.

## Milestones

- 🟢 **v1.17 — Operator Surface Foundation** — Phases 57-63 (active, opened 2026-05-06) — [requirements](REQUIREMENTS.md)
- ✅ **v1.16 — Investigation Table Stakes** — Phases 53-56 (shipped 2026-05-06) — [requirements](milestones/v1.16-REQUIREMENTS.md) · [archive](milestones/v1.16-ROADMAP.md)
- ✅ **v1.15 — Host Integration Completion** — Phases 49-52 (shipped 2026-05-05) — [requirements](milestones/v1.15-REQUIREMENTS.md) · [archive](milestones/v1.15-ROADMAP.md)
- ✅ **v1.14 — Drop-in Production Adopter Slice** — Phases 44-48 (shipped 2026-05-05) — [requirements](milestones/v1.14-REQUIREMENTS.md) · [archive](milestones/v1.14-ROADMAP.md)
- ✅ **v1.13 — Docs Contract Repair** — Phases 41-43 (shipped 2026-04-26) — [archive](milestones/v1.13-ROADMAP.md)
- ✅ **v1.12 — Temporal Truth & Safety** — Phases 38-40 (shipped 2026-04-25) — [archive](milestones/v1.12-ROADMAP.md)

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 57. Optional Deps & Module Gating | 1/1 | Complete | 2026-05-06 |
| 58. Mount Macro & Auth Contract | 0/3 | Planned | - |
| 59. Incident Drill-down Screen | 0/1 | Not started | - |
| 60. Actor Window Screen | 0/1 | Not started | - |
| 61. Row History & As-of Sub-view | 0/1 | Not started | - |
| 62. Mix Task & Example-app Wiring | 0/1 | Not started | - |
| 63. Docs, Contracts & Changelog | 0/1 | Not started | - |

See `.planning/MILESTONE-ARC.md` for the standing ranked recommendation order beyond v1.17.
