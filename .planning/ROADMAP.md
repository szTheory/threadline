# Roadmap: Threadline

## Milestones

- ✅ **v1.12 — Temporal Truth & Safety** — Phases 38-40 (shipped 2026-04-25) — [requirements](milestones/v1.12-REQUIREMENTS.md) · [archive](milestones/v1.12-ROADMAP.md)
- ✅ **v1.13 — Docs Contract Repair** — Phases 41-43 (shipped 2026-04-26) — [requirements](REQUIREMENTS.md) · [archive](milestones/v1.13-ROADMAP.md)
- 🚧 **v1.14 — Drop-in Production Adopter Slice** — Phases 44-48 (in planning, opened 2026-04-26) — [requirements](REQUIREMENTS.md)

## Milestone v1.14 — Drop-in Production Adopter Slice

**Goal:** Make Threadline genuinely drop-in for a SaaS team running Phoenix + Sigra (or any custom auth) by closing the actor-mapping mile, proving operational behavior under realistic load with published numbers, packaging it as `threadline 0.3.0` with a clean upgrade narrative, and shipping a copy-pasteable production incident playbook.

**Approach:** Five additive categories — SIGRA → PERF → INCIDENT → ADOPT → RELEASE — landed sequentially as Phases 44–48. Library runtime deps unchanged. No new public capture/semantics surface. RELEASE strictly last.

**Phase 44 prerequisite (blocking):** Phase 44 (`sigra-integration-adapter`) requires `/gsd-spec-phase sigra-integration-adapter` to produce a `SPEC.md` answering SEED-001 Q1–Q6 (impersonation representation, organization scope, `session.id` → `correlation_id` passthrough, telemetry-vs-Plug-only, API-token actor mapping, `:anonymous` fallback) **before** the phase can enter plan. The adapter must NOT pre-answer these questions.

### Phases (summary)

- [ ] **Phase 44: sigra-integration-adapter** — Ship `Threadline.Integrations.Sigra` in-tree, wire the example app to Sigra, publish the integration guide + doc-contract test (SIGRA-01/02/03).
- [ ] **Phase 45: bench-harness-published-baselines** — Ship the reproducible `bench/` harness, `mix verify.bench` alias, and `guides/performance.md` with published baseline numbers across three workload presets (PERF-01/02/03).
- [ ] **Phase 46: incident-playbook-replay-script** — Ship `guides/incident-playbook.md` with five canonical incidents and a guarded incident-replay script in the example app (INCIDENT-01/02).
- [ ] **Phase 47: saas-adopter-onramp** — Ship `guides/getting-started-saas.md` 30-minute SaaS quickstart and one fully-walked maintainer column on the STG matrix (ADOPT-01/02).
- [ ] **Phase 48: threadline-0.3.0-release** — Bump to `threadline 0.3.0`, refresh CHANGELOG / ExDoc extras / module groups (`Threadline.Integrations.Sigra` surfaced), tag `v0.3.0`, ship `mix verify.release` pre-flight (REL-01/02/03).

### Phase Details

#### Phase 44: sigra-integration-adapter
**Goal**: An integrator running Phoenix + Sigra can wire Threadline once and have audit_actions populated with the right ActorRef across user, admin, service-account, and anonymous request shapes — without `:sigra` becoming a Threadline runtime dep.
**Depends on**: — (first v1.14 phase; **blocking prerequisite: `/gsd-spec-phase sigra-integration-adapter` SPEC.md must answer SEED-001 Q1–Q6 before plan**)
**Requirements**: SIGRA-01, SIGRA-02, SIGRA-03
**Success Criteria** (what must be TRUE):
  1. An integrator can wire `actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1` into their Phoenix `:api` pipeline and observe `audit_actions` rows whose `ActorRef` type matches a `:user`, `:admin`, `:service_account`, or `:anonymous` request shape (per the SPEC's locked decisions for Q1, Q5, Q6).
  2. The same integrator can remove `:sigra` from their host application's deps and Threadline still loads, compiles, and serves requests — `Threadline.Integrations.Sigra.actor_ref_from_conn/1` returns `nil` (or the SPEC's chosen fallback) instead of raising, because `Code.ensure_loaded?(Sigra.Session)` is the only gate.
  3. A reader of `guides/integrations/sigra.md` can copy the install snippet, the Plug callback line, and the six SPEC-answered behaviors verbatim and the wiring works end-to-end against the shipped `examples/threadline_phoenix/` reference app.
  4. A maintainer running `mix test` against the Threadline library suite (without `:sigra` installed) sees the three-conn-shape baseline (no `:current_scope`, `current_scope: nil`, `current_scope: %{user: nil}`) all pass deterministically against the test doubles.
  5. A reviewer running the doc-contract test for `guides/integrations/sigra.md` sees CI fail if the install/wire-up literals or the documented six-question outcomes drift from the guide.
**Plans**: 3 plans
- [ ] 44-01-PLAN.md — adapter module (`Threadline.Integrations.Sigra`), test doubles, and adapter unit tests (SIGRA-01)
- [ ] 44-02-PLAN.md — example app rewiring: `:sigra` optional dep, `SigraContextPlug`, two-plug pipeline, posts_audit_path_test fix (SIGRA-02)
- [ ] 44-03-PLAN.md — `guides/integrations/sigra.md` ExDoc extra and paired doc-contract test locking 5 literal groups (SIGRA-03)
**Notes**: Six-question SPEC is non-negotiable prerequisite. No `{:sigra, ...}` in library `mix.exs` (not even `optional: true`). Adapter must NOT pre-answer Q1–Q6 — SPEC encodes the choices.

#### Phase 45: bench-harness-published-baselines
**Goal**: An operator evaluating Threadline for production can read published baseline numbers grounded in a reproducible harness, and a maintainer can re-run the harness locally to refresh numbers without dragging benchmarks into PR CI.
**Depends on**: Phase 44
**Requirements**: PERF-01, PERF-02, PERF-03
**Success Criteria** (what must be TRUE):
  1. A maintainer can run `mix verify.bench` from a clean checkout against a sized PostgreSQL instance and reproduce the three workload presets (`cold_single_table`, `warm_loaded`, `concurrent_purge`) with deterministic ordering thanks to the pinned `:rand.seed/2`.
  2. A reader of `guides/performance.md` sees published baseline numbers for each preset, each paired with a `BENCHMARK-ENV` block (PG version, Elixir/OTP, hardware class, schema preset, `changed_from` flag, exact `mix run …` command) plus side-by-side numbers for capture with vs without `RedactionPolicy` and with vs without `--store-changed-from`.
  3. A maintainer running `mix help` discovers `mix verify.bench`, but a contributor running `mix ci.all` on a PR observes that the bench step never executes — the CI topology contract test asserts no `bench` job runs by default.
  4. A reviewer running the performance doc-contract test sees CI fail when a required heading, the PgBouncer transaction-mode confirmation paragraph, or the "Capture-time cost knobs" section drifts; numeric values are NOT asserted because they re-baseline legitimately.
  5. A maintainer publishing the package observes `bench/results/*.json` is gitignored and `mix.exs` `:files` excludes `bench/`, so harness output and Benchee deps never leak into the Hex tarball.
**Plans**: TBD

#### Phase 46: incident-playbook-replay-script
**Goal**: A support engineer hit with a production incident can open one guide, pick a canonical scenario, and run either the SQL recipe or the Threadline API call to answer the question — and a maintainer can demo the same recipes end-to-end against a disposable DB.
**Depends on**: Phase 45
**Requirements**: INCIDENT-01, INCIDENT-02
**Success Criteria** (what must be TRUE):
  1. A support engineer reading `guides/incident-playbook.md` finds five canonical incidents — "who changed this row at time T?", "what did service-account X do today?", "did this Oban job actually mutate the DB?", "what did this row look like at time T?", and "single-transaction drilldown" — each with the locked Scenario / Diagnosis (API) / Diagnosis (raw SQL) / Expected output / Recovery structure and a "Reading `change_diff`" subsection that explains INSERT/UPDATE/DELETE shape and the `changed_from` opt-in matrix.
  2. The same engineer copy-pasting any SQL recipe never sees `SELECT *` and is warned by a `<!-- LIVE-JOIN-WARNING -->` callout whenever a recipe joins live application tables — both asserted by the doc-contract test.
  3. A maintainer in the example app's dev environment with `THREADLINE_REPLAY_DISPOSABLE_DB=1` set and a disposable DB name can run `mix run priv/scripts/incident_replay.exs --incident=<slug>` and reproduce three of the five playbook recipes against seeded data; running without the env var, in `:prod`, or against a non-disposable DB name aborts before any mutation.
  4. The same maintainer running `mix run priv/scripts/incident_replay.exs --incident=<slug>` with no flags observes a `--dry-run` execution by default; mutating runs require an explicit `--execute`.
  5. A reviewer running the example app's smoke test sees it shell out to the replay script and assert the JSON output shape, so script breakage fails CI rather than silently rotting.
**Plans**: TBD

#### Phase 47: saas-adopter-onramp
**Goal**: A SaaS team picking up Threadline for the first time can go from `mix.exs` install to first audited write, first timeline read, first `change_diff`, and first `as_of` in under thirty minutes by following one guide that cannot drift from the example app.
**Depends on**: Phase 46
**Requirements**: ADOPT-01, ADOPT-02
**Success Criteria** (what must be TRUE):
  1. A new adopter following `guides/getting-started-saas.md` from "prerequisites" through "first `as_of`" in eight steps can complete every step against the shipped `examples/threadline_phoenix/` reference app, including the `mix threadline.gen.triggers <table>` step (the most-skipped step is locked as a doc-contract literal).
  2. The same adopter running `Threadline.Health.trigger_coverage/1` after step 6 sees the literal `{:covered, _}` shape — asserted in the doc-contract — confirming the host's first audited table is wired correctly.
  3. The adopter following the guide's closing pointer block lands on `production-checklist.md`, `incident-playbook.md`, `performance.md`, `integrations/sigra.md`, `brownfield-continuity.md`, and `adoption-pilot-backlog.md` — every link points at a guide that already exists in the repo when the adopter reads it.
  4. A maintainer editing `examples/threadline_phoenix/` source observes that the quickstart's code blocks are pulled from the example through a fixture module, so editing the example without re-running the doc-contract test fails CI rather than silently desyncing the guide.
  5. A reader of `guides/adoption-pilot-backlog.md` sees one fully-walked column on the `STG-AUDITED-PATH-RUBRIC` matrix with fictional/generic placeholders ("ExampleCloud", "GenericPooler"), an explicit `<!-- ADOPT-EXAMPLE-DISCLAIMER -->` banner, and evidence-pointer cells linking only to in-repo CI artifacts — never to third-party staging URLs — and the extended `stg_doc_contract_test.exs` asserts the disclaimer, an OK row with an in-repo pointer, and the absence of real third-party product names.
**Plans**: TBD

#### Phase 48: threadline-0.3.0-release
**Goal**: A maintainer can publish `threadline 0.3.0` to Hex with a clean upgrade narrative, the four new guides surfaced in ExDoc, the `Threadline.Integrations.Sigra` module discoverable in a new plural `Integrations:` group, and a pre-flight alias that catches packaging drift before tagging.
**Depends on**: Phase 44, Phase 45, Phase 46, Phase 47
**Requirements**: REL-01, REL-02, REL-03
**Success Criteria** (what must be TRUE):
  1. A reader of the published `CHANGELOG.md` `## [0.3.0]` section sees all four standard subsections present (`### Added` / `### Changed` / `### Deprecated` / `### Breaking`, empty allowed) plus a mandatory `### Upgrade from 0.2.x` subsection covering deps changes, config changes, migration steps (none expected), and the Sigra adapter wiring one-liner; the `### Added` block quotes the PERF baseline numbers shipped in Phase 45.
  2. A reader landing on the published HexDocs sees the four new guides (`integrations/sigra.md`, `performance.md`, `incident-playbook.md`, `getting-started-saas.md`) discoverable via ExDoc `extras`, with `Integrations: ~r{^guides/integrations/}` matching ahead of the broader `Reference:` group, and `Threadline.Integrations.Sigra` surfaced in a new plural `Integrations:` `groups_for_modules` entry — distinct from the existing singular `Integration:` group for Plug/Job/Health/Continuity.
  3. An installer copy-pasting the README install snippet sees `~> 0.3` (not `~> 0.2`), and the `readme_doc_contract_test.exs` and the new `release_artifact_contract_test.exs` together fail CI if `mix.exs :files` glob, ExDoc `extras`, and `guides/*.md` on disk ever drift apart.
  4. A maintainer running `mix verify.release` from a clean working tree sees `mix hex.build` and `mix docs` (and Hex-publish-adjacent checks) execute as a pre-flight; `mix help` lists the alias; running `mix ci.all` confirms `verify.release` is NOT included (it requires a clean tree and produces release artifacts).
  5. A maintainer following CONTRIBUTING.md's publish runbook sees the literal "wait for green CI on `main` before tagging" (doc-contract-asserted), tags `v0.3.0` matching `mix.exs` `@version`, and observes the published Hex package whose runtime deps closure is unchanged from 0.2.0.
**Plans**: TBD

### Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 44. sigra-integration-adapter | 0/3 | Not started | — |
| 45. bench-harness-published-baselines | 0/1 | Not started | — |
| 46. incident-playbook-replay-script | 0/1 | Not started | — |
| 47. saas-adopter-onramp | 0/1 | Not started | — |
| 48. threadline-0.3.0-release | 0/1 | Not started | — |

## Next Milestone

- Phase 44 plans landed (3 plans, 3 waves). Run `/gsd-execute-phase 44` to begin Wave 1 (Plan 01: adapter module + test doubles + unit tests).
