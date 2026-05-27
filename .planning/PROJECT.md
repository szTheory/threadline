# Threadline

## What This Is

Threadline is an open-source audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL. It combines trigger-backed row-change capture, first-class application action semantics (actor, intent, request/job context), and operator-grade exploration tools. It is built for teams who need audit trails that are hard to bypass, SQL-queryable without blobs, and genuinely useful for support and ops — not just compliance.

## Core Value

Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## Latest Milestone Shipped: v1.24 Audited Write Path & Adopter Truth

**Goal (achieved):** Package the manual audited-transaction recipe into a first-class library helper, adopt it in the reference app and getting-started guide, and repair reference/doc truth for 0.5.x evaluators — without compliance-platform expansion.

**Shipped:**
- `Threadline.Audit.transaction/3` — actor GUC + domain callback + optional `record_action/2` + `action_id` linkage in one call; PostgreSQL integration tests and doc contracts
- Example app primary write paths (`Blog`, `HelpDesk`, Oban touch) and `guides/getting-started-saas.md` adopt the helper; correlation/audit tests unchanged
- Adopter truth: `evidence_authorize_fn` on sigra-reference mount; adoption-pilot at **0.5.0** / `~> 0.5`; canonical `mix threadline.evidence.show` locked in doc contracts; WALK-03-02 prose fix (WR-110-001)

**Next milestone goals:** _(superseded by v1.25 — see Current Milestone below)_

## Shipped capabilities (cumulative)
- Mountable in-tree LiveView operator surface (`Threadline.OperatorSurface.Router`) with `phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub` declared `optional: true`; `Code.ensure_loaded?(Phoenix.LiveView)` gating keeps capture-only adopters Plug-only at install time.
- Shared `/audit` support-lane proof covers the mounted set the repo verifies today: timeline, actor, transaction, support-scoped row history / as-of, and export denial posture through host-owned seams; `mix threadline.incident <transaction_id>` ships transaction parity for no-LiveView operators.
- Mount-time auth contract: host-mount default + optional `:authorize_fn`, fail-closed at compile time unless the scope has `pipe_through`, `:authorize_fn` is supplied, or `:adopter_acknowledges_unauthenticated: true` is explicit; telemetry event `[:threadline, :operator_surface, :authorize]` with `:granted | :denied | :error`; `:authorize_fn` returned scopes are threaded into investigation queries.
- Raw timeline browse at `/audit` ships with full `Threadline.Query.timeline/2` filter parity, URL-as-state via `live_patch`, shared filter validation, and locked filter-vocabulary doc contracts.
- Operators can download the current timeline view as CSV / wrapped JSON / NDJSON with pre-flight match counts, RFC 5987 filenames, sync-or-chunked delivery based on row count, and byte-parity coverage against `mix threadline.export`.
- Read-only policy viewers ship for trigger coverage and redaction drift: `/audit/coverage`, `/audit/policy/redaction`, `mix threadline.health.coverage`, and `mix threadline.policy.show`.
- **(v1.22)** Append-only evidence records via `Threadline.Evidence` — six bounded subjects with stable provenance metadata and machine-readable detail payloads; no host business-policy meaning encoded.
- **(v1.22)** Three-tier proof vocabulary in `Threadline.Evidence.Proof` distinguishing proven facts, inferred posture, and unsupported claims — shared across library, Mix-task, and LiveView surfaces.
- **(v1.22)** Phoenix-optional library API plus Mix-task parity — **canonical:** `mix threadline.evidence.show` with stable JSON contract for CI / procurement / audit handoff.
- **(v1.22)** Mounted `/audit/evidence` LiveView with overview-first drill-down, URL-driven navigation, host-owned auth gate, and truthful mounted fallbacks — no new operator UI family, no Threadline-owned RBAC.
- Doc-contract test locks the macro signature, route literals, auth section, and v1.22 evidence-plane claim (`mix verify.doc_contract`); CHANGELOG, `guides/operator-surface.md`, `guides/how-threadline-works.md`, `guides/upgrade-path.md`, `guides/domain-reference.md`, README, production checklist, and the example app are aligned end-to-end.

## Current Milestone: v1.25 Adopter-Ready Release & First-Hour Truth

**Goal:** Make the shipped v1.22–v1.24 stack truthfully adoptable from Hex and remove first-hour doc/example friction — without compliance expansion or a second synthetic walkthrough.

**Target features:**
- **REL** — Cut **threadline 0.6.0** (changelog, ExDoc includes `Threadline.Audit`, `mix verify.release` green) ✓ Phase 114
- **NARR** — Sync `guides/how-threadline-works.md` to `Audit.transaction/3` as blessed write path ✓ Phase 115
- **EXAMPLE** — Fix example README first-hour friction (API auth staging, setup vs `demo.seed`, generator/migration confusion) ✓ Phase 116
- **DOC** — Evidence-plane doc authority (thin hub or fix PROJECT references); semver-not-milestone in adopter prose
- **PILOT-PREP (optional)** — Refresh adoption-pilot test counts; external evaluator one-pager

**Assessment source:** `.planning/threads/2026-05-27-milestone-next-step-v1.25-assessment.md`.

**Current planning focus:** Phase 117 (evidence-plane doc authority) — example first-hour fixes complete.

> **Evidence CLI errata:** `mix verify.evidence` was planned for early milestones but never shipped; runnable viewer is `mix threadline.evidence.show` only.

## Prior milestone shipped: v1.23 Realistic-Demo Walkthrough

**Goal (achieved):** Synthetic first-adopter walkthrough — realistic help-desk reference app, Sigra auth, demo seeds, maintainer runbook, observe-only dry-run, and triage of filed findings.

**Shipped:**
- Five-table help-desk domain in `examples/threadline_phoenix/` with capture, semantics, and operator-surface integration
- Sigra signup/login/session lane; `/audit` via `:operator_browser` + host authorize callbacks
- `mix demo.seed` / `mix demo.reset` with manifest-driven deterministic fiction and hero audit incidents
- `WALKTHROUGH.md` (§0–§5), findings template + classification protocol, Phase 109 dry-run, Phase 110 triage (0001–0003 fixed, RUN-01/02/03 pass on validation re-walk)
- Zero `lib/threadline/**` commits for inventory fixes; `mix ci.all` green at closeout

**Next milestone goals:** _(superseded by v1.24 — see Current Milestone above)_

## Prior latest milestone: v1.22 Policy / Evidence Plane

**Goal (achieved):** Persist durable, append-only evidence records for Threadline-owned governance facts; expose them consistently through Phoenix-optional library APIs, Mix tasks, and a host-gated `/audit/evidence` LiveView; lock the narrow contract in docs and tests — without widening into a compliance platform, auth model, or tenancy model.

**Shipped:**
- Append-only evidence schema and `Threadline.Evidence` public context — six bounded subjects with stable provenance metadata, machine-readable detail payloads, and explicit non-goal language for host business policy.
- Three-tier proof vocabulary (`Threadline.Evidence.Proof`) distinguishing proven facts, inferred posture, and unsupported claims — same verdict language across library, Mix-task, and mounted LiveView surfaces.
- Phoenix-optional library API plus Mix-task parity — **canonical:** `mix threadline.evidence.show` with a stable JSON contract for CI, procurement, and audit handoff.
- Mounted `/audit/evidence` LiveView with overview-first drill-down, URL-driven navigation, host-owned auth gate, and truthful mounted fallbacks — no new operator UI family, no Threadline-owned RBAC.
- Public docs and contract tests lock the narrow evidence-plane claim and the explicit non-goals (no legal hold, no immutable-storage guarantee, no generic compliance pack, no Threadline-owned RBAC/tenancy DSL).
- Phase 99 named rerun bundle (`mix verify.doc_contract` + 5-file evidence-plane seam bundle + `mix verify.example`) locks the contract on the current tree; reran green at closeout (122 tests, 0 failures).
- Verification backfill chain (Phases 100/101/102) closed Phase 95/96/98 verification gaps with current-tree proof and finalized Nyquist validation artifacts.
- Authority surface reconciliation and milestone re-audit (Phase 103) flipped the v1.22 audit to `status: passed` with 12/12 requirements satisfied, `closeout_readiness: green`.

**Next milestone goals:**
- Apply real-adopter pressure on the evidence-plane contract before adding scope. v1.23 framing should start from feedback on the shipped narrow surface, not from speculative compliance-pack design.
- Re-evaluate DEFER-01 (compliance report packs), DEFER-02 (legal hold / approval flows), and DEFER-03 (immutable archive guarantees) only when concrete adopter pressure exists; do not preemptively expand the proof vocabulary.
- Preserve the host-owned auth/tenancy boundary that has held through v1.15 → v1.22.

**Post-close judgment (2026-05-27):**
- Shipping the narrow evidence-plane contract first (rather than a generic compliance pack) was the right move — the rerun bundle is now the authoritative source for the procurement / audit-of-audit claim, and future milestones can build on it instead of re-litigating it.
- The verification backfill pattern (Phases 100/101/102) is now repeatable shape for closing audit gaps without widening scope; capture this as a reusable closeout play.
- D-02 (archive vs. closeout-gate separation) and D-16 (`.planning/`-only boundary on closeout-gate phases) held cleanly through Phase 103 — bake into the standard closeout playbook.

## Prior milestone shipped: v1.21 Scoped Support / Operator Proof (Phases 85-94, 2026-05-25)

**Goal (achieved):** Turn the existing host-owned `scope_query_fn` seam into a truthful, first-party support-safe lane on the shipped `/audit` surface without widening Threadline into an auth, tenancy, or compliance platform.

**Shipped:**
- Narrowed the support-lane claim to the exact current-tree proof set: timeline, actor, transaction, support-scoped row history / as-of, and export denial posture through host-owned seams.
- Coverage and policy surfaces now stay explicit as admin/global or unsupported for support-scoped sessions, with denial and fallback UX aligned across LiveView, HTTP, docs, and tests.
- One canonical `/audit` mount recipe and the example Phoenix app prove admin + support personas honestly on the same host-owned route tree.
- Phases 90-94 backfilled the missing verification chain, refreshed the authority surfaces, and closed all 12 v1.21 requirements on rerun-backed current-tree evidence.

**Archives:** `.planning/milestones/v1.21-REQUIREMENTS.md`, `.planning/milestones/v1.21-ROADMAP.md`, `.planning/milestones/v1.21-MILESTONE-AUDIT.md`.

## Prior milestone shipped: v1.20 Scale and Governance Depth

**Goal (achieved):** Move Threadline from "capturing and reading" into governed lifecycle management: safe retention pruning, actor-owned saved views, background exports, and enterprise adapter seams, all while preserving the zero-intrusion default posture.

**Shipped:**
- Governance migrations plus `Threadline.Storage` and `Threadline.ExportQueue` behaviour seams for retention/export state and backend abstraction.
- Batched retention pruning with run tracking and a Retention History LiveView surface.
- Actor-owned saved views on the default operator mount path with session-first ownership semantics.
- Built-in background export runtime supervision, truthful lifecycle transitions, expiry cleanup, and actor-scoped status visibility.
- Backend-aware export delivery plus configured-path Oban/S3 integration proof and repaired public guidance.
- Repaired current-tree verification and Nyquist closeout artifacts for Phases 75-79 and 84 so the milestone evidence matches the shipped tree.

## Prior milestone shipped: v1.17 — Operator Surface Foundation (Phases 57-63, 2026-05-06)

**Goal (achieved):** Ship a host-usable operator surface — a mountable LiveView surface inside `threadline` (with Phoenix/LiveView as optional deps) that turns the v1.16 investigation contracts into one-click answers for the documented support questions, while preserving the v1.15 host-owns-auth boundary.

**Shipped:**
- **Phase 57** — SURF-02 / SURF-03: `phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub` declared `optional: true`; `Threadline.OperatorSurface` namespace module with file-scope `Code.ensure_loaded?(Phoenix.LiveView)` gating; `mix verify.compile_no_optional` alias + dedicated stable-id GitHub Actions job lock the regression-protection contract.
- **Phase 58** — SURF-01 / AUTH-01–05 / TELEM-01: `threadline_operator_surface` mount macro with optional `:actor_fn` / `:authorize_fn`; fails closed at compile time without a secure pipeline or explicit acknowledgement flag; `:adopter_acknowledges_unauthenticated: true` raises in test and emits a loud `Logger.warning` in prod; telemetry event `[:threadline, :operator_surface, :authorize]` with `:granted | :denied | :error`; `:authorize_fn`-returned scopes threaded into investigation queries.
- **Phases 59-61** — UI-01 / UI-02 / UI-03: incident drill-down LiveView at `/audit/transactions/:id` rendering `Threadline.incident_bundle/2`; actor window LiveView at `/audit/actors/:kind/:id` rendering `Threadline.actor_history/2` (with `ActorHistoryPage` keyset paging); row history sub-view at `/audit/rows/:table/:pk` rendering `Threadline.history/3` + `Threadline.as_of/4`, reachable from drill-down change rows.
- **Phase 62** — CLI-01 / SURF-04: `mix threadline.incident <transaction_id>` (with `--json`); `examples/threadline_phoenix` mounts the operator surface end-to-end behind a `phx.gen.auth`-style admin pipeline.
- **Phase 63** — DOC-01–04: `operator_surface_doc_contract_test.exs` locks macro signature, route literals, and auth section; `guides/operator-surface.md` covers mount, auth, screens, and the CLI task; README, production checklist, and example app README cross-link the new guide; CHANGELOG entry highlights the optional dependency posture and macro.

**Archives:** `.planning/milestones/v1.17-REQUIREMENTS.md`, `.planning/milestones/v1.17-ROADMAP.md`, `.planning/milestones/v1.17-MILESTONE-AUDIT.md`.

## Prior milestone shipped: v1.15 — Host Integration Completion (Phases 49-52, 2026-05-05)

**Goal (achieved):** Finish the remaining Phoenix host-integration gap so adopters get native request-context wiring, direct Sigra callback composition, and an authenticated incident drill-down baseline without inventing their own glue for the first serious host rollout.

**Shipped:**
- **Phase 49** — PLUG-01/02: native `Threadline.Plug` context overrides hook, additive-only precedence rules, deterministic invalid-shape failures, and aligned docs/tests.
- **Phase 50** — SIGRA-04/05: direct `Threadline.Integrations.Sigra` callback wiring through `Threadline.Plug`, example-app router adoption, and drift guards for the canonical callback pair.
- **Phase 51** — INCIDENT-03/04: authenticated incident drill-down baseline in the Phoenix example app plus incident docs that keep tenancy and richer authorization host-owned.
- **Phase 52** — ADOPT-03: getting-started, Sigra, README, domain-reference, incident-playbook, and adoption-backlog alignment with cross-doc contract coverage.

**Archives:** `.planning/milestones/v1.15-REQUIREMENTS.md`, `.planning/milestones/v1.15-ROADMAP.md`, `.planning/milestones/v1.15-MILESTONE-AUDIT.md`, `.planning/milestones/v1.15-phases/`.

## Prior milestone shipped: v1.14 — Drop-in Production Adopter Slice (Phases 44-48, 2026-05-05)
**Goal (achieved):** Make Threadline genuinely drop-in for a SaaS team running Phoenix + Sigra by closing the actor-mapping mile, publishing realistic operational evidence, shipping the incident playbook/replay path, and packaging the result as `threadline 0.3.0`.

**Shipped:**
- **Phase 44** — SIGRA-01/02/03: `Threadline.Integrations.Sigra`, example-app Sigra wiring, and `guides/integrations/sigra.md` with doc-contract coverage.
- **Phase 45** — PERF-01/02/03: reproducible `bench/` harness, tracked baseline artifacts, `mix verify.bench`, and `guides/performance.md`.
- **Phase 46** — INCIDENT-01/02: `guides/incident-playbook.md`, guarded incident replay script, and smoke/doc-contract coverage.
- **Phase 47** — ADOPT-01/02: SaaS quickstart, fixture-backed snippet extraction, and a maintainer-walked STG example with disclaimer/evidence guards.
- **Phase 48** — REL-01/02/03: `0.3.0` packaging surface, release artifact contract, ExDoc regrouping, and `mix verify.release`.

**Archives:** `.planning/milestones/v1.14-REQUIREMENTS.md`, `.planning/milestones/v1.14-ROADMAP.md`, `.planning/milestones/v1.14-MILESTONE-AUDIT.md`, `.planning/milestones/v1.14-phases/`.

## Prior milestone shipped: v1.13 — Docs Contract Repair (Phases 41–43, 2026-04-26)

**Goal (achieved):** Repair README contract drift on the root project and the Phoenix example so the published docs match the shipped public API surface, and restore the verification artifacts the milestone audit was missing.

**Shipped:**
- **Phase 41** — DOC-01: Root `README.md` aligned with the shipped public API surface; doc-contract test locks the literals.
- **Phase 42** — DOC-02: `examples/threadline_phoenix/README.md` and `examples/README.md` aligned with the runnable Phoenix reference app; doc-contract test extended to cover example install/runbook + historical reconstruction literals.
- **Phase 43** — DOC-03: `41-VERIFICATION.md`, `42-VERIFICATION.md`, and reconciled `v1.13-MILESTONE-AUDIT.md` close the audit evidence gap so DOC-01–03 are counted as verified.

**Archives:** `.planning/milestones/v1.13-REQUIREMENTS.md`, `.planning/milestones/v1.13-ROADMAP.md`, `.planning/milestones/v1.13-MILESTONE-AUDIT.md`, `.planning/milestones/v1.13-phases/`.

## Prior milestone shipped: v1.12 — Temporal Truth & Safety (Phases 38–40, 2026-04-25)

**Goal (achieved):** Provide a stable foundation for point-in-time row reconstruction with map-first reads, opt-in struct reification, and copy-pasteable operator docs.

**Shipped:**
- **Phase 38** — ASOF-01/02/05: snapshot-first `Threadline.as_of/4` with delete and genesis-gap handling.
- **Phase 39** — ASOF-03/04: opt-in struct reification with loose historical loading.
- **Phase 40** — ASOF-06: Time Travel operator docs and Phoenix example walkthrough.

**Archive:** `.planning/milestones/v1.12-REQUIREMENTS.md`, `.planning/milestones/v1.12-ROADMAP.md`.

## Last milestone shipped: v1.11 — Composable incident surface (Phase 37, 2026-04-24)

**Goal (achieved):** Close the integrator **composition** gap with a **two-step HTTP JSON** pattern in the reference Phoenix app: **`POST /api/posts`** returns **`audit_transaction_id`**, then **`GET /api/audit_transactions/:id/changes`** returns ordered changes plus **`change_diff`** maps.

**Shipped:**
- **Phase 37** — COMP-01/02/03: Example incident JSON path in `examples/threadline_phoenix`, `AuditTransactionController`, and `COMP-EXAMPLE-INCIDENT-JSON` doc contract.

## Last milestone shipped: v1.10 — Support-grade exploration primitives (Phases 31–36, 2026-04-24)

**Goal (achieved in-repo):** Turn shipped **capture + semantics + timeline/export** into faster **incident answers** with **small, explicit library APIs** — without new capture semantics or a UI framework.

**Shipped:**

- **Phase 31** — XPLO-01: **`Threadline.ChangeDiff`** + **`Threadline.change_diff/2`** — JSON-serializable field-level projection; documented INSERT/UPDATE/DELETE and `changed_from` absence.
- **Phase 32** — XPLO-02: **`Threadline.Query.audit_changes_for_transaction/2`** + **`Threadline.audit_changes_for_transaction/2`** — stable ordering for one transaction id.
- **Phase 33** — XPLO-03: **`## Exploration API routing (v1.10+)`** in **`guides/domain-reference.md`**, production-checklist cross-link, **`Threadline.ExplorationRoutingDocContractTest`**.

**Non-goals (unchanged):** LiveView operator UI; published **`threadline_web`**; new capture / redaction / retention **semantics**; maintainer-attested third-party STG URLs; **Hex** semver bump unless a **separate** release milestone says so.

**Distribution:** **`v0.2.0`** / **`threadline` 0.2.0** on Hex unchanged unless a release decision is made.

## Last milestone shipped: v1.9 — Production confidence at volume (Phases 28–30, 2026-04-24)

**Goal (achieved in-repo):** Credible **ops-at-volume** narrative for telemetry + **`Threadline.Health`**, a durable **audit indexing** cookbook, and **retention-at-scale** guidance grounded in shipped APIs — **docs-first**.

**Shipped:**

- **Phase 28** — OPS-01, OPS-02: per-event telemetry narrative + **`## Trigger coverage (operational)`** in **`guides/domain-reference.md`**; production checklist cross-links.
- **Phase 29** — IDX-01, IDX-02: **`guides/audit-indexing.md`**, ExDoc extra, doc contract **`test/threadline/audit_indexing_doc_contract_test.exs`**.
- **Phase 30** — SCALE-01, SCALE-02: **`guides/production-checklist.md`** volume / purge cadence H3 + export & support hooks; **`guides/domain-reference.md`** **`## Operating at scale (v1.9+)`** hub; **`README.md`** Maintainer-band discovery paragraph.

**Non-goals (unchanged):** LiveView operator UI; `threadline_web`; new capture/redaction semantics; Hex semver bump unless a separate release decision is made.

## Last milestone shipped: v1.8 — Close the support loop (Phases 25–27, 2026-04-24)

**Goal (achieved in-repo):** Faster **time-to-answer** in production support via shared **timeline + export** vocabulary, **correlation-aware** filtering, **copy-paste operator docs**, and an **example app** slice that proves the correlation path in CI.

**Shipped:**

- **Phase 25** — LOOP-01: `:correlation_id` on timeline/export with strict `audit_actions` join; validation + integration tests.
- **Phase 26** — LOOP-02, LOOP-04: Support incident queries in guides; doc contract anchors.
- **Phase 27** — LOOP-03: Example **`POST /api/posts`** records **`record_action`** in the audited transaction, links **`audit_transactions.action_id`**, **`ThreadlinePhoenixWeb.PostsCorrelationPathTest`**, README correlation + **`export_json`** / **`jq`**.

**Archives:** `.planning/milestones/v1.8-REQUIREMENTS.md`, `.planning/milestones/v1.8-ROADMAP.md`. **Non-goals (unchanged):** LiveView operator UI; `threadline_web` / umbrella; new capture semantics; maintainer-attested third-party STG URLs.

## Last milestone shipped: v1.7 — Reference integration for SaaS (Phases 22–24, 2026-04-24)

**Goal (achieved in-repo):** Give teams a **runnable, minimal Phoenix integration** under **`examples/threadline_phoenix/`** that demonstrates capture and semantics on **HTTP and Oban job paths**, with **`record_action/2`** and cross-links to **`guides/production-checklist.md`** and **`guides/adoption-pilot-backlog.md`** (STG rubric) — integrator-owned host evidence unchanged from v1.6.

**Shipped:**

- **Phase 22** — Path-dep example app, install + `gen.triggers` for `posts`, **`mix verify.example`** in **`mix ci.all`**, README runbook.
- **Phase 23** — **`Threadline.Plug`** on `:api` pipeline; **`Blog.create_post/2`** with transaction-local GUC; ConnCase audit path test.
- **Phase 24** — Oban **`PostTouchWorker`**, **`Blog.touch_post_for_job/2`** with **`Threadline.Job`** + **`record_action(:post_title_refreshed_from_queue, …)`**; README **Semantics in jobs** + adoption doc links.

**Archives:** `.planning/milestones/v1.7-REQUIREMENTS.md`, `.planning/milestones/v1.7-ROADMAP.md`.

**Non-goals (unchanged):** LiveView operator UI; new capture/redaction semantics; Hex semver bump unless a separate release decision is made; published `threadline_web` — example stays under **`examples/`**.

## Prior milestone shipped: v1.6 — Host staging / pooler parity (Phase 21, 2026-04-24)

**Goal (achieved in-repo):** Close the gap between **library CI** and **honest host documentation** using integrator-owned templates and evidence pointers — not maintainer attestation of third-party staging.

**Shipped (maintainer affordances):**

- **STG-01** — Fixed-field topology scaffold (`STG-HOST-TOPOLOGY-TEMPLATE`) in **`guides/adoption-pilot-backlog.md`** plus **partial** rationale guidance.
- **STG-02** — Audited HTTP/job path rubric (`STG-AUDITED-PATH-RUBRIC`) with **OK / Issue / N/A / Not run** and **Evidence / pointer** column.
- **STG-03** — Rubric rules (no OK without pointer; **N/A** vs **Not run**; CI vs host labeling); **CONTRIBUTING** `## Host STG evidence (integrators)`; production-checklist intro cross-link; doc contracts in **`test/threadline/ci_topology_contract_test.exs`** and **`test/threadline/stg_doc_contract_test.exs`**.

**Non-goals (unchanged):** New capture semantics, exploration API expansion, LiveView UI, or claiming external pilot environments the library does not control — see **Out of Scope** below and **Future** in **`.planning/milestones/v1.6-REQUIREMENTS.md`** (archived v1.6 scope).

## Shipped milestones

**v1.0** through **v1.13** are complete (**v1.13** shipped 2026-04-26, Phases 41–43). Prior milestones live under **`.planning/milestones/`**. **Living roadmap:** **`.planning/ROADMAP.md`**.

## Requirements

### Validated

- [x] **Capture layer (Phase 1)** — Custom `Threadline.Capture` trigger SQL, `mix threadline.install` / `mix threadline.gen.triggers`, integration tests on PostgreSQL, GitHub Actions CI, CONTRIBUTING. Validated in Phase 1: Capture Foundation (2026-04-23).
- [x] **Semantics layer (Phase 2)** — `ActorRef`, `audit_actions` / nullable `audit_transactions.actor_ref`, `record_action/2`, `Threadline.Plug`, `Threadline.Job`, transaction-local GUC bridge for trigger-populated `actor_ref`. Validated in Phase 2: Semantics Layer (2026-04-23).
- [x] **Query + observability (Phase 3)** — `Threadline.Query`, delegators on `Threadline`, health coverage checks, telemetry hooks. Validated in Phase 3: Query & Observability (2026-04-23).
- [x] **Documentation + Hex readiness (Phase 4)** — root `README.md`, `guides/domain-reference.md`, `LICENSE`, `CHANGELOG.md`, ExDoc configuration, capture schema `@moduledoc`, `mix docs` / `mix hex.build` / `mix ci.all` green. Validated in Phase 4: Documentation & Release (2026-04-23).
- [x] **Canonical GitHub hosting (Phase 5)** — `origin` → `github.com/szTheory/threadline`, `@source_url` / package links / README CI badge aligned; `main` tracks `origin/main`; CI workflow monitors `main` only. Validated in Phase 5: Repository & remote (2026-04-22).
- [x] **CI signal on GitHub (Phases 6 & 8)** — `ci.yml` jobs green on `main` with maintainer-recorded proof (`06-VERIFICATION.md`); README / CONTRIBUTING document Actions. Validated in Phase 8: Publish main & verify CI (2026-04-23).
- [x] **Hex package `threadline` 0.1.0** — semver, dated changelog, `v0.1.0` on `origin`, publish to Hex. Validated in Phase 7–8 (2026-04-23).
- [x] **Before-values capture (Phase 9)** — nullable `audit_changes.changed_from`, opt-in per-table trigger SQL via `mix threadline.gen.triggers --store-changed-from`, `AuditChange.changed_from` and `Threadline.history/3` loading. Validated in Phase 9: Before-values capture (2026-04-23).
- [x] **Verify coverage & doc contracts (Phase 10)** — `mix threadline.verify_coverage`, `Threadline.Verify.CoveragePolicy`, CI `verify.threadline` / `verify.doc_contract`, README doc contract fixtures, CONTRIBUTING parity. Validated in Phase 10: Verify coverage & doc contracts (2026-04-23).
- [x] **Backfill / continuity (Phase 11)** — `Threadline.Continuity`, `mix threadline.continuity`, brownfield integration test, `guides/brownfield-continuity.md`, README and HexDocs discovery. Validated in Phase 11: Backfill / continuity (2026-04-23).
- [x] **Redaction at capture (Phase 12)** — `config :threadline, :trigger_capture`, `RedactionPolicy`, `TriggerSQL` exclude/mask, tests and operator docs. Validated in Phase 12 (2026-04-23).
- [x] **Retention + batched purge (Phase 13)** — `Threadline.Retention.Policy`, `Threadline.Retention.purge/1`, `mix threadline.retention.purge`, integration tests on PostgreSQL. Validated in Phase 13 (2026-04-23).
- [x] **Export (Phase 14)** — `Threadline.Export`, strict timeline filter validation, `mix threadline.export`, README + domain guide + ExDoc. Validated in Phase 14 (2026-04-23).
- [x] **Onboarding & README (Phase 15)** — `~> 0.2`, quickstart export, doc index links. Validated in Phase 15 (2026-04-23).
- [x] **Production checklist (Phase 16)** — `guides/production-checklist.md`. Validated in Phase 16 (2026-04-23).
- [x] **Timeline/export DX (Phase 17)** — `Threadline.Query.timeline_repo!/2`, validation order, tests. Validated in Phase 17 (2026-04-23).
- [x] **Release 0.2.0 packaging (Phase 18)** — `mix.exs` 0.2.0, CHANGELOG, ExDoc extras + retention in module groups. Validated in Phase 18 (2026-04-23).
- [x] **Adoption operator docs (Phase 19)** — `guides/adoption-pilot-backlog.md`, README + ExDoc extras, domain-reference telemetry operator table, production-checklist cross-links (ADOP-01, ADOP-02, TELEM-01, TELEM-02). Validated in Phase 19 (2026-04-23).
- [x] **ADOP-03 (Phase 20)** — Pilot backlog filled with **OK** / **N/A** + evidence; **AP-ENV.1** triaged to **STG-01**. Validated in Phase 20: First external pilot (maintainer CI evidence pass, 2026-04-23).
- [x] **STG-01 — STG-03 (Phase 21)** — In-repo topology template, audited-path rubric, CONTRIBUTING integrator workflow, production-checklist pointer, doc contract tests. Validated in Phase 21: Host staging & pooler parity (2026-04-24). Integrators still fill matrices with host-specific evidence via fork + PR.
- [x] **REF-01 / REF-02 (Phase 22)** — Canonical `examples/threadline_phoenix/` path-dep app, install + `gen.triggers` for `posts`, dedicated `threadline_phoenix_test`, `mix verify.example` in `ci.all`, CI + doc contracts. Validated in Phase 22: Example app layout & runbook (2026-04-24).
- [x] **REF-03 (Phase 23)** — `Threadline.Plug` on example `:api` pipeline; `Blog.create_post/2` with transaction-local GUC; ConnCase `posts_audit_path_test.exs` proves `audit_changes` + `AuditTransaction.actor_ref`. Validated in Phase 23: HTTP audited path (2026-04-24).
- [x] **REF-04 / REF-05 / REF-06 (Phase 24)** — Oban `PostTouchWorker` + `Blog.touch_post_for_job/2` with `Threadline.Job` and `record_action(:post_title_refreshed_from_queue, …)`; example README **Semantics in jobs** + links to **`guides/production-checklist.md`** and **`guides/adoption-pilot-backlog.md`**. Validated in Phase 24: Job path, actions, adoption pointers (2026-04-24).
- [x] **LOOP-01 (Phase 25)** — Optional **`:correlation_id`** on **`Threadline.Query.timeline/2`**, **`timeline_query/1`**, **`export_changes_query/1`**, and **`Threadline.Export`**; strict `AuditAction` join when set; JSON **`action`** object and opt-in CSV **`include_action_metadata`**; integration tests + CHANGELOG. Validated in Phase 25: Correlation-aware timeline & export (2026-04-24).
- [x] **LOOP-02 / LOOP-04 (Phase 26)** — **`guides/domain-reference.md`** + **`guides/production-checklist.md`** **Support incident queries** (five questions, API vs SQL); marker **`LOOP-04-SUPPORT-INCIDENT-QUERIES`**; **`test/threadline/support_playbook_doc_contract_test.exs`**. Validated in Phase 26: Support playbooks & doc contracts (2026-04-24).
- [x] **LOOP-03 (Phase 27)** — **`examples/threadline_phoenix/`** correlation path: **`x-correlation-id`**, **`record_action/2`**, **`ThreadlinePhoenixWeb.PostsCorrelationPathTest`**, README **`timeline`** / **`export_json`** with **`:correlation_id`**. Validated in Phase 27: Example app correlation path (2026-04-24).
- [x] **OPS-01 / OPS-02 (Phase 28)** — **`guides/domain-reference.md`** per-event telemetry narrative + **`## Trigger coverage (operational)`**; **`guides/production-checklist.md`** §1/§6 cross-links; README pointer to **`guides/domain-reference.md#trigger-coverage-operational`**. Validated in Phase 28: Telemetry & health operators' narrative (2026-04-24).
- [x] **IDX-01 / IDX-02 (Phase 29)** — **`guides/audit-indexing.md`** (installed defaults, access patterns vs **`Threadline.Query`** / **`Threadline.Export`** / **`Threadline.Retention`**, tradeoffs, optional DDL framed non-mandatory); ExDoc extra; cross-links from **`guides/domain-reference.md`** and **`guides/production-checklist.md`**; **`test/threadline/audit_indexing_doc_contract_test.exs`**. Validated in Phase 29: Audit table indexing cookbook (2026-04-24).
- [x] **SCALE-01 / SCALE-02 (Phase 30)** — **`guides/production-checklist.md`** volume / purge cadence H3 tied to **`Threadline.Retention.Policy`**, **`Threadline.Retention.purge/1`**, **`mix threadline.retention.purge`**; export §5 + support intro hooks; **`guides/domain-reference.md`** **`## Operating at scale (v1.9+)`** discovery hub; **`README.md`** Maintainer-band pointer. Validated in Phase 30: Retention at scale & discovery (2026-04-24).
- [x] **XPLO-01 (Phase 31)** — **`Threadline.ChangeDiff.from_audit_change/2`** (primary + `:export_compat`), ExDoc matrix for INSERT/UPDATE/DELETE and `before_values` / `prior_state`, **`test/threadline/change_diff_test.exs`**, **`Threadline.change_diff/2`**. Validated in Phase 31: Field-level change presentation (2026-04-24).
- [x] **XPLO-02 (Phase 32)** — **`Threadline.Query.audit_changes_for_transaction/2`**, **`Threadline.audit_changes_for_transaction/2`**, stable order via **`timeline_order/1`**, UUID validation + **`[]`** empty semantics, **`test/threadline/query_test.exs`**. Validated in Phase 32: Transaction-scoped change listing (2026-04-24).
- [x] **XPLO-03 (Phase 33)** — **`guides/domain-reference.md`** **Exploration API routing (v1.10+)**, production-checklist cross-link, **`Threadline.ExplorationRoutingDocContractTest`**. Validated in Phase 33: Operator docs & contracts (2026-04-24).
- [x] **COMP-01 / COMP-02 / COMP-03 (Phase 37)** — Example **`POST /api/posts`** returns **`audit_transaction_id`**; **`GET /api/audit_transactions/:id/changes`** lists changes with **`Threadline.change_diff/2`** maps; **`COMP-EXAMPLE-INCIDENT-JSON`** in **`guides/domain-reference.md`**; **`ThreadlinePhoenixWeb.PostsIncidentJsonPathTest`**. Validated in Phase 37: Example incident JSON path (2026-04-24).
- [x] **ASOF-01 / ASOF-02 / ASOF-05 (Phase 38)** — Map-first reconstruction, deleted-record handling, and genesis-gap errors. Validated in v1.12: Core As-of Reconstruction.
- [x] **ASOF-03 / ASOF-04 (Phase 39)** — Opt-in struct reification and loose casting. Validated in v1.12: Reification & Schema Safety.
- [x] **ASOF-06 (Phase 40)** — Time Travel docs and example walkthrough. Validated in v1.12: Temporal Operator Guides.
- [x] **DOC-01 (Phase 41)** — Root `README.md` aligned with the shipped public API surface; locked by `test/threadline/readme_doc_contract_test.exs`. Validated in v1.13: Docs Contract Repair (2026-04-26).
- [x] **DOC-02 (Phase 42)** — `examples/threadline_phoenix/README.md` and `examples/README.md` aligned with the runnable Phoenix reference app; doc-contract test extended to assert the example surface. Validated in v1.13: Docs Contract Repair (2026-04-26).
- [x] **DOC-03 (Phases 41–42, audit closed in Phase 43)** — Doc-contract tests cover the README and example README literals; `41-VERIFICATION.md`, `42-VERIFICATION.md`, and `v1.13-MILESTONE-AUDIT.md` close the audit evidence gap. Validated in v1.13: Docs Contract Repair (2026-04-26).
- [x] **Investigation table stakes (Phases 53–56)** — `Threadline.timeline_page/2`, public investigation helpers, `Threadline.incident_bundle/2`, focused request-path coverage, and one canonical investigation docs story. Validated in v1.16: Investigation Table Stakes (2026-05-06).
- [x] **Operator Surface Foundation (Phases 57–63)** — Mountable in-tree LiveView with optional Phoenix/LiveView/HTML/PubSub deps, two must-have screens + row history sub-view, fail-closed mount-time auth contract with optional `:authorize_fn` and authorize telemetry, `mix threadline.incident` CLI parity, doc-contract test locking macro signature + route literals + auth section. Validated in v1.17 (2026-05-06).
- [x] **Policy / Evidence Plane (Phases 95–103)** — `Threadline.Evidence` append-only records with stable provenance and machine-readable detail; Phoenix-optional library APIs and Mix-task parity (**canonical:** `mix threadline.evidence.show`); `/audit/evidence` LiveView with host-owned auth gate; three-tier proof vocabulary (`Threadline.Evidence.Proof`); doc contracts lock the narrow claim and explicit non-goals (no legal hold, no immutable storage, no generic compliance pack, no Threadline-owned RBAC/tenancy DSL). Validated in v1.22: EVID-01/02/03, PROOF-01/02/03, SURF-01/02/03, DOC-01/02/03 (2026-05-27).
- [x] **DEMO (Phase 105)** — Help-desk domain in `examples/threadline_phoenix/`: five `binary_id` tables, `HelpDesk.ticket_replied_and_closed/6`, masked `internal_note_body` capture, triggers + `verify_coverage` green, DataCase audit proofs. Validated in Phase 105 (2026-05-27).
- [x] **CHARTER (Phase 104)** — v1.23 override Key Decision and non-goals locked in PROJECT.md and MILESTONE-ARC.md. Validated in v1.23 (2026-05-27).
- [x] **AUTH (Phase 106)** — Sigra signup/login/session in reference app; help-desk-aware `current_user`; `/audit` via `:operator_browser`. Validated in v1.23 (2026-05-27).
- [x] **SEED (Phase 107)** — `mix demo.seed` / `mix demo.reset` with deterministic three-org fiction and hero incidents. Validated in v1.23 (2026-05-27).
- [x] **WALK (Phase 108)** — `WALKTHROUGH.md` runbook and findings protocol. Validated in v1.23 (2026-05-27).
- [x] **RUN (Phase 109)** — Observe-only dry-run; findings captured for Phase 110. Validated in v1.23 (2026-05-27).
- [x] **FIX (Phase 110)** — Findings 0001–0003 fixed; zero v1.24 deferrals; validation re-walk pass. Validated in v1.23 (2026-05-27).
- [x] **AUDIT-TXN-01 / AUDIT-TXN-02 / AUDIT-TXN-03 / AUDIT-TXN-04 (Phase 111)** — `Threadline.Audit.transaction/3` with PostgreSQL integration tests and doc contracts. Validated in v1.24 (2026-05-27).
- [x] **ADOPT-HELPER-01 / ADOPT-HELPER-02 / ADOPT-HELPER-03 (Phase 112)** — Reference app + getting-started adopt helper; correlation-ready integration proof. Validated in v1.24 (2026-05-27).
- [x] **TRUTH-01 / TRUTH-02 / TRUTH-03 / TRUTH-04 / TRUTH-05 (Phase 113)** — `evidence_authorize_fn`, adoption-pilot 0.5.x, evidence CLI naming, WR-110-001 prose, verify gates green. Validated in v1.24 (2026-05-27).
- [x] **REL-01** through **REL-04 (Phase 114)** — 0.6.0 semver, CHANGELOG, ExDoc Evidence group, verify.release, install-snippet SSOT `~> 0.6`. Validated in v1.25 (2026-05-27).
- [x] **NARR-01** through **NARR-03 (Phase 115)** — `guides/how-threadline-works.md`, README, and getting-started aligned on `Audit.transaction/3` as blessed write path; doc-contract tests lock narrative literals and cross-doc discovery order. Validated in v1.25 (2026-05-27).
- [x] **EXAMPLE-01** through **EXAMPLE-04 (Phase 116)** — Example `:api` session plugs before `Threadline.Plug`; README Choose your path / Base install / Track A–B runbook; Mix task reference and ownership tables; doc-contract locks for auth staging and first-hour literals. Validated in v1.25 (2026-05-27).

### Active

- [ ] **DOC-01** through **DOC-03** — Evidence-plane doc authority + semver prose (Phase 117)
- [ ] **PILOT-01** / **PILOT-02** — Optional pilot-prep (Phase 118)

### Out of Scope

- **SIEM / security information and event management** — different product category, different buyers, different infrastructure
- **Full event sourcing / CQRS** — Threadline captures audit facts; it does not drive application state reconstruction
- **pgAudit replacement** — statement-level DB auditing is a separate concern; Threadline is application-level
- **Data warehouse / CDC pipeline** — WAL/logical replication adds operational surface area (PgBouncer hazards, cloud caveats, cannot be reverted) that is not worth the tradeoff for v0.x
- **Hard LiveView / Phoenix dependency in `threadline` core** — out of scope. The v1.17 operator surface is gated on `phoenix_live_view` as an optional dep so capture-only adopters retain a Plug-only install footprint.
- **Multi-tenant / prefix-scoped capture beyond Ecto prefix support** — defer until basic capture is validated
- **Forced `threadline_web` extraction before version-pressure exists** — out of scope for v1.19. The milestone should define objective extraction triggers first; a package split only makes sense once real adopters create version-matrix or release-cadence pressure.
- **Automated Hex publish from CI** — tag-triggered workflow exists; interactive `mix hex.publish` remains the documented maintainer path for early releases
- **Elixir/OTP version bumps in CI** — unless required for runner or dependency breakage

## Context

**Ecosystem gap:** Carbonite (v0.16.x) is the strongest trigger-backed capture substrate in the Elixir ecosystem but is a library, not a platform — it handles what changed but not who did it or why. PaperTrail and ExAudit fill the action-semantics gap but sacrifice correctness (miss direct Repo/SQL writes). No existing library combines both with operator tooling.

**Key prior-art lessons:**
- Logidze: metadata via connection-local variables misbehaves with PgBouncer if transactions are skipped — Threadline must document this and provide safe propagation patterns
- ExAudit: ETS/PID-scoped context ages poorly in async contexts; avoid process-local context stores
- Ruby Audited: YAML storage caused years of upgrade pain — JSONB with typed columns is the answer
- Ruby PaperTrail: association tracking complexity bloated the core — keep association tracking out of v0.1

**Engineering baseline:** The project follows the same OSS quality bar as sibling libraries (Scrypath, Sigra): `mix verify.*` / `mix ci.*` entrypoints, doc contract tests once public docs exist, stable GitHub Actions job IDs, release automation aligned to Hex publishing workflow.

**Capture mechanism (closed):** Path B — custom `Threadline.Capture.TriggerSQL` with transaction-row grouping (`txid_current()`), no `SET LOCAL` in the capture path. Formal decision: `.planning/milestones/v1.0-phases/01-capture-foundation/gate-01-01.md` (archived with v1.0).

## Constraints

- **Tech stack**: Elixir ≥ 1.15 / OTP ≥ 26 / PostgreSQL ≥ 14 / Ecto 3.x — align with active Phoenix LTS baseline
- **SQL-native**: no Erlang binary or opaque blob storage; all audit data must be introspectable with plain SQL
- **Correct by default**: capture must not depend on developers remembering to call library functions on every write path
- **OSS quality bar**: named `mix verify.*` / `mix ci.*` entrypoints; honest `mix test` (no silent exclusions); stable GitHub Actions job IDs
- **Capture mechanism**: Path B (custom triggers) — see archived gate-01-01.md; PgBouncer transaction-mode safe
- **No WAL/CDC as primary backend**: logical replication adds operational surface area incompatible with Threadline's "batteries-included" promise at v0.x

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Trigger-backed capture (not application-hook-based) | Harder to bypass than PaperTrail-style opt-in; correctness is the core value | ✓ Validated (Phase 1) |
| Carbonite vs custom (Phase 1 gate) | Carbonite metadata path uses patterns incompatible with D-06; Threadline needs D-05 schema | ✓ Path B: custom `TriggerSQL` (see archived gate-01-01.md) |
| Separate capture vs. semantics models | Actions ≠ changes; transactions ≠ requests; collapsing them is how prior art created gaps | ✓ Good (design principle) |
| JSONB + typed columns, no binary formats | Avoids YAML/Erlang-term upgrade pain documented in Audited and ExAudit | ✓ Good (design principle) |
| Single package `threadline` to start | Avoid premature umbrella/companion split before API is known; revisit after v0.1 | ✓ **0.1.0** shipped on Hex (v1.1) |
| No LiveView UI in v0.1 | Exploration layer matures after capture + semantics prove out | ✓ Good |
| v1.7 reference app under `examples/` | Runnable SaaS-shaped integration without publishing a companion Hex package | ✓ Shipped (Phases 22–24, 2026-04-24) |
| `ChangeDiff` normalizes trigger `op` casing | Lowercase `op` from PostgreSQL trigger paths maps to uppercase INSERT/UPDATE/DELETE in the primary wire map | ✓ Shipped (Phase 34, v1.10) |
| `as_of/4` map-first reconstruction and cast-based reification | Point-in-time reads now support explicit deleted/genesis errors plus opt-in struct loading | ✓ Shipped (Phases 38–40, v1.12) |
| Treat README docs drift as a first-class milestone | README literals are public API; doc-contract tests must lock them so future drift fails CI instead of silently shipping | ✓ Shipped (Phases 41–43, v1.13) |
| Verification artifacts are first-class milestone output | Phase 43 retroactively wrote `*-VERIFICATION.md` to close an audit gap; future phases should land verification evidence alongside SUMMARY.md, not after | ✓ Shipped (Phase 43, v1.13) |
| Investigation workflows before UI breadth | The library already captures and correlates rich audit data, but adopters still need packaged answers to the first support questions before a UI or new adapter layer will feel durable | ✓ Shipped in v1.16 |
| Persist a standing milestone arc in `.planning/MILESTONE-ARC.md` | Future milestone starts should begin from a recorded strategic recommendation, not from memory or a fresh prompt | ✓ Shipped in v1.16 |
| v1.17 operator surface ships in-tree with optional Phoenix/LiveView deps, not as a separate `threadline_web` package | Splitting at v0.3.0 with one maintainer is premature: doubles the release/version-matrix burden when the surface is still small. LiveDashboard / Oban Web / Ash Admin all split *after* the core had hundreds of adopters; Sentry-Elixir keeps Phoenix integrations optional in-tree without a companion. Keeps capture-only adopters Plug-only via `optional: true` deps gated by `Code.ensure_loaded?(Phoenix.LiveView)`. | ✓ Shipped (Phases 57–63, v1.17) |
| Operator surface defaults to host-mounted with optional `:authorize_fn` callback and fails closed at compile time | Pure host-mount (LiveDashboard / Sidekiq Web pattern) leaks the surface when adopters forget the pipeline. Pure callback walks back from v1.15's "host owns auth, Threadline owns the wiring contract." Hangfire's fail-closed default + Oban Web's resolver shape gives the most conservative posture for an audit-trail surface, which is the highest-stakes leak target in the ecosystem. | ✓ Shipped (Phases 57–63, v1.17) |
| v1.18 ships the raw timeline browse with full `Threadline.Query.timeline/2` filter parity (no narrow starter, no saved views) | Narrow starter creates a UI/API filter divergence — operators learn two filter dialects, doc-contract tests have to track both, the CloudTrail/Kibana trajectory of "ship a subset, bolt on the rest later" is well-documented. Saved views drag a tiny new auth model (owner / visibility / sharing) into a lib that has stayed auth-agnostic since v1.15; URL-as-state via `live_patch` + browser bookmarks cover the persistence story for free, which is what GitHub audit log and Oban Web do at scale. Five filters is well below the threshold where saved views become necessary. | ✓ Shipped in v1.18 |
| v1.18 ships exports UI as "download current view" only (sync `iodata` for small windows, chunked stream for large), not queued/Oban-backed | Adding Oban as a hard dep walks back the v1.17 optional-deps win, and storage adapters / file expiry / status pages are platform creep that contradicts "lib not platform." Sidekiq Pro hit memory pain on in-process CSV before adding streaming; Backpex / Linear / GitHub-style sync downloads are the right ceiling at our stage. Queued-with-link-when-ready is what large products (CloudTrail, Sentry, GitHub audit-log) ship after sync hits a wall — Threadline hasn't hit that wall, so the design would be speculative. Revisit in v1.20 once real adopters report row-cap pain on real incidents. | ✓ Shipped in v1.18 |
| v1.18 ships read-only policy admin viewers (coverage dashboard + drift-aware redaction admin); retention admin deferred to v1.19 | Coverage has zero drift risk and the highest operational value (covers the most expensive Threadline failure mode — uncaptured tables) over already-shipped `Threadline.Health.trigger_coverage/1`. Drift-aware redaction admin reconciles `config :threadline, :trigger_capture` against `pg_proc.prosrc`-derived deployed redaction so a config edit without `gen.triggers` rerun cannot silently mislead operators (the Logidze/Carbonite-class footgun). Retention admin's "last purge" requires net-new `audit_retention_runs` capture machinery (`purge/1` writes), which broadens the milestone rather than hardens it; revisit when the capture surface is decided. Read-only ceiling preserves the v1.15 host-owns-auth boundary and avoids the "Purge now" / runtime-policy-edit compliance vector. | ✓ Shipped in v1.18 |
| v1.19 focuses on integration breadth and extraction readiness, not deeper operator product scope | The next leverage point is reducing host-specific glue and tightening proven compatibility claims. Saved views, retention admin capture machinery, queued exports, and mutable policy UI all add product surface or infrastructure without making adoption easier across hosts. `threadline_web` should remain a measured future decision unless real adopter pressure proves otherwise. | — Active (opened 2026-05-07) |
| v1.21 will productize the mount contract, not the auth model | The strongest remaining adoption gap was a truthful scoped support lane on `/audit`. The current tree now proves one host-owned path end to end, and Phase 94 closed the authority and audit surfaces around that proof without inventing RBAC or tenancy DSLs. | ✓ Ready for closeout (2026-05-25) |
| v1.22 will ship a narrow evidence plane, not a compliance platform | The next leverage point is durable proof for policy/governance posture. Append-only evidence records, API/CLI parity, and read-only `/audit` evidence views strengthen enterprise credibility without crossing the host-owned auth/tenancy boundary. | ✓ Shipped (Phases 95-103, v1.22, 2026-05-27) |
| Three-tier proof vocabulary (`proven`, `inferred`, `unsupported`) lives in `Threadline.Evidence.Proof` and is shared across library, Mix, and LiveView surfaces | Procurement and audit-of-audit asks require honest claim language, not just data. Splitting the verdict into proven facts vs. inferred posture vs. explicit unsupported claims kept the contract narrow while still being useful — and prevented the "everything is a proven compliance fact" drift other audit libraries fall into. | ✓ Shipped (Phase 97, v1.22, 2026-05-27) |
| Mounted `/audit/evidence` reuses the existing `/audit` surface and host-owned auth gate; no new operator UI family or Threadline-owned RBAC | Pure read-only views with overview-first drill-down and URL-driven navigation match the support-lane shape established in v1.21, so adopters get one consistent operator vocabulary. A new UI family would have reopened auth scope. | ✓ Shipped (Phase 98, v1.22, 2026-05-27) |
| Verification backfill phases (Phases 100/101/102) are the right pattern for closing audit gaps without widening milestone scope | When a milestone audit surfaces gaps in already-shipped phases, inserting narrow verification-only phases (`.planning/`-only, no doc/code/test edits, named rerun bundle as proof) closes the loop without re-litigating the underlying work. Phase 103 then reconciles the authority surfaces and reruns the audit on the reconciled tree. Reusable closeout play. | ✓ Validated (Phases 100-103, v1.22, 2026-05-27) |
| D-02 archive/closeout-gate separation and D-16 `.planning/`-only boundary held cleanly through Phase 103 | The archive step (`/gsd-complete-milestone`) owns MILESTONE-ARC, PROJECT "Last shipped", MILESTONES, RETROSPECTIVE, and `.planning/milestones/v*` archives. The closeout-gate phase is the proof step, not the archive step. Keeping these separated avoids the "audit closed itself" anti-pattern. | ✓ Validated (Phase 103, v1.22, 2026-05-27) |
| v1.23 deliberately overrides v1.22's "real-adopter feedback first" closeout rule and ships a synthetic-first-adopter walkthrough instead | No real adopter exists at v1.22 close, and the alternative is shipping nothing — a maintainer walking the reference app on a clean clone is the strongest available signal until external pressure arrives. Override scoped to v1.23 only and does not extend evidence subjects, Threadline-owned RBAC/tenancy DSLs, or `lib/` auth code. **Re-engages the v1.22 rule on first sustained real-adopter signal** (live-integration issue, maintainer-confirmed pilot host, or named procurement/security-review/evaluation conversation); drive-by interest routes to `.planning/v1.24-seeds/` rather than re-engaging the rule. | ✓ Shipped (v1.23, 2026-05-27) |
| v1.24 prioritizes audited write-path ergonomics over compliance expansion | Milestone-next-step assessment (~83% done for stated scope): capture+semantics+operator stack is strong; #1 remaining foot-gun is manual transaction recipe for actor GUC + `record_action` + `action_id`. No sustained adopter signal — proceed with helper + reference/doc truth, not DEFER-01/02/03 or another walkthrough. | ✓ Shipped (Phases 111-113, v1.24, 2026-05-27) |
| `Threadline.Audit.transaction/3` is the recommended audited write path | Single helper replaces copy-pasted GUC + `record_action` + `action_id` recipe; reference app and guides prove correlation-ready timelines without weakened tests. | ✓ Shipped (Phases 111-112, v1.24, 2026-05-27) |
| Adopter truth for 0.5.x evaluators lives in example mount + doc contracts | `evidence_authorize_fn`, adoption-pilot version SSOT, canonical evidence CLI, and walkthrough prose aligned to seed fiction — no new Evidence subjects. | ✓ Shipped (Phase 113, v1.24, 2026-05-27) |
| Post-v1.24 assessment prioritizes release truth + first-hour friction over compliance expansion | Repo-grounded done band ~88–92% for stated narrow scope; Hex 0.5.0 lags v1.22–v1.24 stack; largest remaining synthetic wedge is 0.6.0 + narrative doc sync + example README fixes — not DEFER trio without adopter signal. phx.gen.auth breadth queued as v1.26. | — Recommended (2026-05-27 assessment) |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (e.g. GSD `phase.complete` / roadmap update after `/gsd-execute-phase` when applicable):

1. Requirements invalidated? → Move to Out of Scope with reason  
2. Requirements validated? → Move to Validated with phase reference  
3. New requirements emerged? → Add to Active  
4. Decisions to log? → Add to Key Decisions  
5. "What This Is" still accurate? → Update if drifted  

**After each milestone** (via `/gsd-complete-milestone`):

1. Full review of all sections  
2. Core Value check — still the right priority?  
3. Audit Out of Scope — reasons still valid?  
4. Update Context with current state  

---
*Last updated: 2026-05-27 — Phase 116 complete (example first-hour fixes); Phase 117 next.*
