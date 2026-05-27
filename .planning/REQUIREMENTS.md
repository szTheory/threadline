# Requirements: Threadline v1.23 — Realistic-Demo Walkthrough

**Defined:** 2026-05-27
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Milestone goal:** Make the maintainer the synthetic first adopter — upgrade `examples/threadline_phoenix/` into a realistic help-desk SaaS with Sigra-backed auth and believable seed data, then walk install → onboarding → daily use → incident response → evidence review end-to-end, surface gaps, and route them via an explicit fix-vs-defer rule.

**Framing override:** v1.22's closeout language said "real-adopter feedback first, not speculative widening." v1.23 deliberately overrides that rule in absence of any real adopter. The override is recorded as a Phase 104 Key Decision so it does not get re-litigated next milestone-arc reread.

---

## v1 Requirements

### Charter (Phase 104) — Override decision and non-goals

- [x] **CHARTER-01**: PROJECT.md Key Decisions table gains a row for "v1.23 deliberately overrides v1.22's 'real-adopter-first' closeout guidance" with rationale, override trigger ("no real adopter exists, alternative is shipping nothing"), and re-engagement trigger ("first real adopter signal — issue, pilot host, or procurement conversation — pauses synthetic walkthroughs and resumes the v1.22 rule").
- [x] **CHARTER-02**: `MILESTONE-ARC.md` gains a v1.23 row in the arc-order table with theme "Realistic-Demo Walkthrough," why-now framing, what-this-unlocks, and explicit non-goals; strategic thesis paragraph updated to note the override.
- [x] **CHARTER-03**: v1.23 non-goals locked in PROJECT.md: no new evidence subjects beyond the six shipped in v1.22; no Threadline-owned RBAC / tenancy DSLs; no `lib/` auth code; no domain-model code in `lib/`; no rebrand from "example app" to "demo product"; no extension of the Sigra integration unless real signup/login surfaces a contract gap (handled via sub-phase 106b).

### Help-Desk Domain Expansion (Phase 105) — Reference-app domain

- [x] **DEMO-01**: Add Ecto schemas and migrations for `organizations`, `org_memberships`, `agents`, `tickets`, and `ticket_replies` (with an `internal_note_body` column) in `examples/threadline_phoenix/lib/threadline_phoenix/help_desk/` (or equivalent context layout); associations modeled correctly (org ↔ memberships ↔ agents; org ↔ tickets ↔ replies).
- [x] **DEMO-02**: Context modules write through Threadline correctly: transaction-local actor GUC set before writes, `Threadline.record_action/2` called inside the same DB transaction for multi-table actions (e.g. `:ticket_replied_and_closed` hits `tickets` + `ticket_replies` in one tx), patterned after `Blog.create_post/2`.
- [x] **DEMO-03**: `mix threadline.gen.triggers` generates triggers for every audited help-desk table; `mix threadline.verify_coverage` (or `mix verify.threadline` coverage check) passes green; example-app CI integration test asserts row-level audit on at least one multi-table write.
- [x] **DEMO-04**: `config :threadline, :trigger_capture` in `examples/threadline_phoenix/config/runtime.exs` (or appropriate env file) masks/excludes `ticket_replies.internal_note_body` so redaction posture has a real surface to exercise in Phase 108's walkthrough.

### Sigra Auth Lane (Phase 106) — Real auth integration in the reference app

- [x] **AUTH-01**: Sigra added as a dependency in `examples/threadline_phoenix/mix.exs` with config in the example app's config files; install/migration steps integrate with `mix ecto.setup` cleanly.
- [x] **AUTH-02**: Signup, login, and logout routes wired in the example app's router using Sigra-provided generators or hand-rolled equivalent; templates rendered; session persists across requests.
- [x] **AUTH-03**: Authenticated session shape exposes `is_admin: boolean()`, `role: :support | :agent`, and `organization_id` on `current_user` / `current_scope` — matching what `my_authorize_fn` and `scope_operator_query` in `router.ex` already expect — so the existing `/audit` mount continues to work without router changes beyond auth-pipeline wiring.
- [x] **AUTH-04**: All pre-existing example-app tests still pass (`posts_audit_path_test`, `posts_correlation_path_test`, `posts_incident_json_path_test`, `operator_surface_test`, `post_touch_worker_test`); new help-desk audit tests run against real Sigra session, not faked `conn |> assign(:current_user, …)`.

### Realistic Seed Data + Demo Mix Tasks (Phase 107)

- [x] **SEED-01**: `mix demo.seed` task added under `examples/threadline_phoenix/lib/mix/tasks/`, deliberately separate from `priv/repo/seeds.exs` so adopters don't conflate the demo seed with their own seed scaffolding.
- [x] **SEED-02**: Seeds deterministic via fixed `:rand.seed`; idempotent (re-running produces the same state); volume target ~3 organizations × 5 agents × 50 tickets, with ticket activity spanning roughly 14 days (created/updated timestamps backdated, audit history showing realistic activity gaps).
- [x] **SEED-03**: Seed dataset drives every Phase 108 walkthrough scenario — i.e. the specific tickets, agents, and timing referenced in the walkthrough doc are findable in the seeded data; the answers exist before the walkthrough runs.
- [x] **SEED-04**: `mix demo.reset` task returns the database to a clean post-migrate state (drops + re-runs migrations + re-runs `demo.seed`); documented as the canonical way to recover.
- [x] **SEED-05**: A "deleted by someone" record is planted in the seed dataset (e.g. an agent deleted a ticket reply in org Acme last Tuesday) so the Phase 108 support-incident scenario ("who deleted X?") has a real on-disk answer.

### Walkthrough Script + Finding Protocol (Phase 108)

- [ ] **WALK-01**: `examples/threadline_phoenix/WALKTHROUGH.md` install/onboarding section: clone, dep install, db setup, demo seed, Sigra signup/login, first ticket-reply created through the UI; expected outputs and verification steps documented.
- [ ] **WALK-02**: Daily-use section: agent replies to and closes a ticket; admin views recent activity for their org via the operator surface; support agent triages an inbound ticket — each flow with expected screens and audit-table outcomes.
- [ ] **WALK-03**: Incident section — three concrete user-uttered scenarios with documented answer procedures using only the shipped operator surface:
  1. "Support: who closed ticket #4521 in org Acme last Tuesday, and what did they say in internal-notes before doing it?" (scoped timeline + correlation + actor window + row history)
  2. "Admin: agent X is leaving — what did they touch in their last 24h?" (actor history with cross-org admin scope)
  3. "Admin/compliance: prove org Y's data was retention-purged when they offboarded." (evidence-plane drill-down)
- [x] **WALK-04**: Evidence section — three exercises against shipped subjects only (retention purge run, redaction policy snapshot, trigger coverage snapshot), executed via `mix verify.evidence` / `mix threadline.evidence.show` and the `/audit/evidence` LiveView; expected `Threadline.Evidence` records documented.
- [ ] **FINDINGS-01**: `.planning/v1.23/findings/TEMPLATE.md` and `.planning/v1.23/findings/README.md` define the finding file format and the (a/b/c/d) classification rule (breakage / DX papercut / doc gap / design gap) — including the fix-vs-defer routing: (a) always fixed in Phase 110, (b) fixed if ≤1 plan in scope, (c) always fixed, (d) deferred to v1.24 seeds with rationale.

### Maintainer Walkthrough Dry-Run (Phase 109)

- [ ] **RUN-01**: Clean-clone install completes following only WALKTHROUGH.md (no out-of-band shell commands, no IEx fixes); `mix phx.server` boots and `http://localhost:4000` shows a working help-desk landing.
- [ ] **RUN-02**: All three Phase-108 operator scenarios resolved using only shipped operator-surface flows — no raw SQL, no IEx hacks, no `Repo.all/2` from a console — and the resolution procedure matches what WALKTHROUGH.md documents.
- [ ] **RUN-03**: All three Phase-108 evidence exercises produce the documented `Threadline.Evidence` records via the shipped Mix tasks and `/audit/evidence` LiveView.
- [ ] **FINDINGS-02**: Every gap, papercut, surprise, and confusion observed during the run is captured as a numbered file under `.planning/v1.23/findings/NNNN-slug.md` with classification (a/b/c/d) assigned at capture time, with the originating walkthrough step cited; no findings deferred to be "classified later."

### Triage + Narrow Fixes (Phase 110)

- [ ] **FIX-01**: Every (a) breakage finding is fixed in Phase 110 with a commit referencing the finding ID; `lib/` is touchable only for (a) findings citing concrete walkthrough evidence (e.g. a wrong answer, a crash, a security regression).
- [ ] **FIX-02**: Every (b) DX papercut finding is fixed in Phase 110 if the fix is ≤ 1 narrow plan in scope; over-budget papercuts are explicitly deferred with a `.planning/v1.24-seeds/SEED-NNN.md` and the finding marked `deferred_to:`.
- [ ] **FIX-03**: Every (c) doc gap finding is fixed in `guides/` or example-app README, with `mix verify.doc_contract` updated to lock the literals if doc contracts are touched.
- [ ] **DEFER-01**: Every (d) design gap finding lands as `.planning/v1.24-seeds/SEED-NNN.md` with a one-paragraph rationale, the originating finding ID, and a "when this seed should surface" trigger; finding file marked `deferred_to:` and Phase-110 SUMMARY.md lists deferred seeds.

---

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Compliance / Evidence Vocabulary Expansion (DEFER from v1.22, re-evaluated here)

- **COMPLIANCE-PACK** — opinionated bundles of evidence records (SOC2-flavored, HIPAA-flavored). Carried forward from v1.22 DEFER-01. Re-evaluate only if v1.23 walkthrough surfaces concrete adopter-style pressure (it will not, per the v1.23 framing rule).
- **LEGAL-HOLD** — selective freeze of records against retention purge. Carried forward from v1.22 DEFER-02. Same defer rule.
- **IMMUTABLE-ARCHIVE** — append-only storage guarantees beyond the current append-only schema posture. Carried forward from v1.22 DEFER-03. Same defer rule.

### Walkthrough-surfaced design gaps (TBD)

Whatever Phase 109 surfaces as (d) findings becomes the v2 list at milestone close — formalized as `.planning/v1.24-seeds/SEED-NNN.md` in Phase 110.

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| Adding any new `Threadline.Evidence` subject beyond the six shipped in v1.22 | v1.23 exercises existing subjects; new subjects would be speculative widening and contradict the v1.22 closeout posture even under the v1.23 override |
| Threadline-owned RBAC, tenancy DSL, or auth abstractions in `lib/` | Boundary held since v1.15; v1.23 explicitly does not pressure this — all auth/tenancy work lives in `examples/threadline_phoenix/` |
| Rebranding `examples/threadline_phoenix/` from "reference app" to "demo product" | Conflating the two invites scope creep ("demos need polish, references don't"); v1.23 enhances the reference app without repositioning the artifact |
| `lib/` changes outside Phase 110 S-tier fixes | Strict library-read-only boundary in Phases 104–109; Phase 110 only touches `lib/` for findings with concrete walkthrough evidence |
| Fixing every walkthrough finding in v1.23 | The fix-vs-defer rule deliberately defers design-gap findings to v1.24; v1.23 ships fixes proportionate to the override's narrow scope |
| Adopter-template marketing positioning of the example app | The example remains a maintainer-affordance proof vehicle; positioning the help-desk demo as a copy-paste SaaS template is out of scope |
| Multi-domain demos (project tracker, document repo, billing) | Help-desk chosen as the single domain for v1.23; other domains do not enter this milestone |
| Phx.gen.auth auth lane | Sigra chosen as the auth lane; not running both, even though phx.gen.auth might be more familiar to some adopters |
| Maintainer-attested external pilot environments | Unchanged from v1.5/v1.6 stance; v1.23 walkthrough is local and reproducible only |

---

## Traceability

Filled by `gsd-roadmapper` during Phase 0 of execution.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CHARTER-01 | Phase 104 | Complete |
| CHARTER-02 | Phase 104 | Complete |
| CHARTER-03 | Phase 104 | Complete |
| DEMO-01 | Phase 105 | Complete |
| DEMO-02 | Phase 105 | Complete |
| DEMO-03 | Phase 105 | Complete |
| DEMO-04 | Phase 105 | Complete |
| AUTH-01 | Phase 106 | Complete |
| AUTH-02 | Phase 106 | Complete |
| AUTH-03 | Phase 106 | Complete |
| AUTH-04 | Phase 106 | Complete |
| SEED-01 | Phase 107 | Complete |
| SEED-02 | Phase 107 | Complete |
| SEED-03 | Phase 107 | Complete |
| SEED-04 | Phase 107 | Complete |
| SEED-05 | Phase 107 | Complete |
| WALK-01 | Phase 108 | Pending |
| WALK-02 | Phase 108 | Pending |
| WALK-03 | Phase 108 | Pending |
| WALK-04 | Phase 108 | Complete |
| FINDINGS-01 | Phase 108 | Pending |
| RUN-01 | Phase 109 | Pending |
| RUN-02 | Phase 109 | Pending |
| RUN-03 | Phase 109 | Pending |
| FINDINGS-02 | Phase 109 | Pending |
| FIX-01 | Phase 110 | Pending |
| FIX-02 | Phase 110 | Pending |
| FIX-03 | Phase 110 | Pending |
| DEFER-01 | Phase 110 | Pending |

**Coverage:**

- v1 requirements: 29 total
- Mapped to phases: 29
- Unmapped: 0 ✓

---

*Requirements defined: 2026-05-27*
*Last updated: 2026-05-27 — initial v1.23 definition, sourced from approved plan at `/Users/jon/.claude/plans/no-actual-adopter-feedback-logical-flamingo.md`.*
