# Requirements — Threadline v1.14: Drop-in Production Adopter Slice

**Milestone goal:** Make Threadline genuinely drop-in for a SaaS team running Phoenix + Sigra (or any custom auth) by closing the actor-mapping mile, proving operational behavior under realistic load with published numbers, packaging it as `threadline 0.3.0` with a clean upgrade narrative, and shipping a copy-pasteable production incident playbook.

**Approach:** Five additive categories — SIGRA, PERF, INCIDENT, ADOPT, RELEASE — landed sequentially as Phases 44–48. Library runtime deps unchanged. No new public capture/semantics surface. RELEASE strictly last.

**Decision sources:** `.planning/research/SUMMARY.md`, `.planning/research/sigra-integration-context.md`, `.planning/seeds/SEED-001-sigra-integration-adapter.md` (promoted), `.planning/PROJECT.md`.

---

## v1.14 Requirements

### SIGRA — Sigra integration adapter (closes SEED-001)

- [ ] **SIGRA-01** — `Threadline.Integrations.Sigra` adapter module ships in-tree at `lib/threadline/integrations/sigra.ex` with public surface `actor_ref_from_conn/1`, `audit_context_overrides_from_conn/1`, and `actor_fn/0` factory. Runtime `Code.ensure_loaded?(Sigra.Session)` guard returns `nil` when Sigra is absent. Library `mix.exs` does NOT add `:sigra` (not even `optional: true`). `test/support/sigra_test_doubles.ex` defines minimal `Sigra.Session`/`Sigra.Scope` shims only when real modules are absent. Three-conn-shape test baseline (no `:current_scope`, `current_scope: nil`, `current_scope: %{user: nil}`) returns deterministic results without raising. **Prerequisite: `/gsd-spec-phase sigra-integration-adapter` answers SEED-001 Q1–Q6 in a `SPEC.md` artifact before this requirement enters plan.**
- [ ] **SIGRA-02** — `examples/threadline_phoenix/` is wired to Sigra: the Phase 23 `audit_actor.ex` stub is replaced with a Sigra-aware (guarded) extraction; `examples/threadline_phoenix/mix.exs` adds `{:sigra, "~> 0.2", optional: true}`; the example router/endpoint wires `Threadline.Plug` with `actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1`. Existing example test suite (HTTP + Oban audited paths, correlation path, incident JSON path) continues to pass.
- [ ] **SIGRA-03** — `guides/integrations/sigra.md` ExDoc extra documents the wiring contract end-to-end (install snippet, Plug callback, six SPEC decisions surfaced as documented behaviors, fallback semantics) with a paired `test/threadline/integrations/sigra_doc_contract_test.exs` locking the install/wire-up literals and the documented six-question outcomes.

### PERF — Reproducible benchmark harness & published baselines

- [ ] **PERF-01** — `bench/` top-level directory ships with `audit_capture_bench.exs`, `timeline_query_bench.exs`, `scripts/seed_audit_changes.exs`, `scripts/teardown.exs`, and a `bench/README.md` documenting how to run. Three workload presets minimum: `cold_single_table`, `warm_loaded` (with `audit-indexing.md` index set), `concurrent_purge`. Random seed pinned (`:rand.seed(:exsss, {1, 2, 3})`); `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` plans captured into `bench/baselines/`. New `mix verify.bench` alias is documented and discoverable via `mix help` but is NEVER added to `mix ci.all` (CI topology contract test asserts). `bench/results/*.json` is gitignored.
- [ ] **PERF-02** — `guides/performance.md` ships as an ExDoc extra with published baseline numbers grouped by preset, each paired with a `BENCHMARK-ENV` block (PG version, Elixir/OTP, hardware class, schema preset, `changed_from` flag, exact `mix run …` command). Cross-links to `guides/audit-indexing.md` and `guides/production-checklist.md`. PgBouncer transaction-mode confirmation paragraph cites the `verify-pgbouncer-topology` CI job. Paired `test/threadline/performance_doc_contract_test.exs` locks structure and required headings — NOT numeric values (which drift legitimately when re-baselined).
- [ ] **PERF-03** — `guides/performance.md` includes a "Capture-time cost knobs" section with side-by-side baseline numbers for: (a) capture with vs without `RedactionPolicy` exclude/mask, and (b) capture with vs without `--store-changed-from` triggers. Numbers come from a `redaction_and_changed_from_bench.exs` scenario set (or extension of `audit_capture_bench.exs`) and are produced by the same `mix verify.bench` flow as PERF-01. Doc-contract test asserts the section exists.

### INCIDENT — Production incident playbook & replay script

- [ ] **INCIDENT-01** — `guides/incident-playbook.md` ships as an ExDoc extra with five canonical incidents, each using the locked structure: **Scenario / Diagnosis (API) / Diagnosis (raw SQL) / Expected output / Recovery**. Five incidents: (1) "Who changed this row at time T?" (history); (2) "What did service-account X do today?" (actor window); (3) "Did this Oban job actually mutate the DB?" (correlation bundle via `audit_changes_for_transaction/2` + `change_diff/2`); (4) "What did this row look like at time T?" (`as_of/4`); (5) "Single-transaction drilldown: every change in this audit_transaction." Every SQL recipe names columns explicitly (no `SELECT *`); recipes joining live application tables include a `<!-- LIVE-JOIN-WARNING -->` callout. Dedicated "Reading `change_diff`" subsection enumerates INSERT/UPDATE/DELETE shape and the `changed_from` opt-in matrix. Cross-links from `guides/production-checklist.md` and `guides/domain-reference.md`. Paired `test/threadline/incident_playbook_doc_contract_test.exs` asserts five `## N. Incident:` headings, four required subsections each, no `SELECT *`, the live-join callout, and the `change_diff` subsection.
- [ ] **INCIDENT-02** — `examples/threadline_phoenix/priv/scripts/incident_replay.exs` is Mix-runnable (`mix run priv/scripts/incident_replay.exs --incident=<slug>`) and exercises three of the five playbook recipes end-to-end against a seeded DB. Hard guards refuse to run unless `Mix.env() in [:dev, :test]` AND `THREADLINE_REPLAY_DISPOSABLE_DB=1` AND target DB name matches a disposable pattern; default behavior is `--dry-run`; mutation requires explicit `--execute`. Smoke test in `examples/threadline_phoenix/test/` shells out via `Mix.shell().cmd/2` and asserts JSON shape of the script's output.

### ADOPT — SaaS adopter onramp

- [ ] **ADOPT-01** — `guides/getting-started-saas.md` ships as an ExDoc extra with eight steps: (1) prerequisites (Phoenix 1.7+, Ecto schema, `:api` pipeline; pointer to phoenixframework.org for newcomers); (2) install (`{:threadline, "~> 0.3"}`); (3) `mix threadline.install`; (4) `mix threadline.gen.triggers <table>` (mandatory literal — most common skip); (5) `Threadline.Plug` wire-up with `:actor_fn`; (6) first audited write + verify with `Threadline.Health.trigger_coverage/1`; (7) first `Threadline.timeline/2` read; (8) first `Threadline.change_diff/2` and `Threadline.as_of/4`. Code blocks pulled from `examples/threadline_phoenix/` source via a fixture module so the guide cannot drift from the example. Closing pointer block links to `production-checklist.md`, `incident-playbook.md`, `performance.md`, `integrations/sigra.md`, `brownfield-continuity.md`, `adoption-pilot-backlog.md`. Paired `test/threadline/getting_started_saas_doc_contract_test.exs` locks the eight section headings, the literal `mix threadline.gen.triggers` command, and the `{:covered, _}` health-check assertion literal.
- [ ] **ADOPT-02** — `guides/adoption-pilot-backlog.md` STG-AUDITED-PATH-RUBRIC matrix gets ONE fully-walked maintainer column using fictional/generic placeholders ("ExampleCloud", "GenericPooler") with an explicit `<!-- ADOPT-EXAMPLE-DISCLAIMER -->` banner clarifying the column is maintainer-walked CI evidence — NOT third-party endorsement. Evidence-pointer cells link only to in-repo CI artifacts (e.g. `verify-pgbouncer-topology`), never to third-party staging URLs. `test/threadline/stg_doc_contract_test.exs` is extended to assert the disclaimer banner is present, the column has at least one OK row with an in-repo evidence pointer, and no real third-party product names appear in the column.

### RELEASE — `threadline 0.3.0` packaging

- [ ] **REL-01** — Release artifacts: `mix.exs` `@version` `"0.2.0"` → `"0.3.0"`; `CHANGELOG.md` `## [0.3.0] — YYYY-MM-DD` section with all four standard subsections (`### Added`/`### Changed`/`### Deprecated`/`### Breaking` — empty allowed, missing not) AND a mandatory `### Upgrade from 0.2.x` subsection covering deps changes, config changes, migration steps (none expected), and the Sigra adapter wiring one-liner; CHANGELOG `### Added` quotes the published PERF baseline numbers; `README.md` install snippet `~> 0.2` → `~> 0.3` with `readme_doc_contract_test.exs` updated in the same commit; `v0.3.0` git tag matches `@version`.
- [ ] **REL-02** — Release surfaces: ExDoc `extras` includes the four NEW guides (`integrations/sigra.md`, `performance.md`, `incident-playbook.md`, `getting-started-saas.md`); ExDoc `groups_for_extras` adds `Integrations: ~r{^guides/integrations/}` BEFORE `Reference: ~r{^guides/}` (regex-match order matters); ExDoc `groups_for_modules` adds a NEW plural `Integrations:` group surfacing `Threadline.Integrations.Sigra` (the existing singular `Integration:` group for Plug/Job/Health/Continuity stays unchanged); CONTRIBUTING.md gains a maintainer publish runbook with the literal "wait for green CI on `main` before tagging" (doc-contract-asserted); a NEW `test/threadline/release_artifact_contract_test.exs` ties the three-way allowlist together: `mix.exs :files` glob ↔ ExDoc `extras` list ↔ `guides/*.md` files on disk must agree, and any drift fails CI.
- [ ] **REL-03** — `mix verify.release` pre-flight alias runs `mix hex.build` + `mix docs` (and any other Hex-publish-adjacent checks) so packaging drift is caught locally before tagging. Documented in CONTRIBUTING.md alongside the publish runbook. Discoverable via `mix help`. Not added to `mix ci.all` (it requires a clean working tree and produces release artifacts).

---

## Future Requirements (deferred from v1.14)

- **SIGRA-stretch — worked impersonation walkthrough:** end-to-end example showing `audit_transactions.actor_ref` → timeline for an admin acting as a user, including how the SPEC's chosen impersonation representation surfaces in operator queries. Defer to v1.15 once SIGRA-01's SPEC has shipped and at least one external pilot has exercised it.
- **SIGRA-stretch — Sigra telemetry subscription:** subscribe to `[:sigra, :audit, :log]` for non-Plug audit events (Oban, manual `record_action` outside conn). Deferred — dedup design (telemetry vs Plug double-recording) isn't mature enough to ship in v1.14; revisit after Plug-only adapter lands and adopter feedback exists.
- **PERF-stretch — scheduled monthly bench workflow:** GitHub Actions cron to re-run `mix verify.bench` on a sized DB monthly and post results. Deferred — needs hosted-runner spec and a place to publish stale-detection signals.
- **PERF-stretch — SHA-pinned bench output with stale-detection:** commit bench output keyed by the SHA of capture-path source files; CI flags when output is older than the latest source change.
- **INCIDENT-stretch — Postgrex.Notifications live-tail mention:** one-paragraph cross-link in `incident-playbook.md` noting live-tail is available without new deps. Defer — would pull a non-shipped feature into the operator-facing doc; revisit if adopter ask materializes.
- **INCIDENT-stretch — telemetry-attach worked example:** end-to-end snippet wiring `:telemetry.attach/4` for `[:threadline, :*]` events in an operator console. Defer to a dedicated telemetry-guide phase.
- **ADOPT-stretch — "What to wire next" decision tree:** closing decision tree at end of `getting-started-saas.md` pointing readers to correlation/jobs/Sigra/incident-playbook based on their answers. Useful but not load-bearing for the first-hour experience.
- **ADOPT-stretch — standalone `guides/upgrading-to-0.3.md`:** separate upgrade walkthrough guide instead of (or in addition to) the CHANGELOG `### Upgrade from 0.2.x` subsection. Deferred — CHANGELOG subsection is sufficient at 0.x; revisit at 1.0.
- **DEPR — Phoenix 1.8 readiness check:** explicit smoke test or doc note pinning the Phoenix-version range Threadline supports as the ecosystem moves. Defer to a v1.15 dependency-hygiene phase.

---

## Out of Scope (explicit exclusions)

- **No changes to capture / semantics / exploration / retention / export / correlation / time-travel public surface.** v1.14 is additive only.
- **No 7th `ActorRef` type.** Impersonation is a relationship between actors, not a new actor kind. Adding a 7th type would force a JSONB migration of `audit_actions`.
- **No `{:sigra, ...}` in library `mix.exs`** (not even `optional: true`). Sigra is a host runtime expectation, never a library dep.
- **No second example app** (`examples/threadline_phoenix_sigra/`). Extend the existing example; do not fork.
- **No `mix verify.bench` in `mix ci.all`.** Benchmarks are maintainer artifacts on sized data, not PR gates.
- **No live-tail / streaming UI in incident playbook.** v1.14 ships docs + replay script; live-tail is a future capability.
- **No telemetry subscription in SIGRA adapter.** Plug-only for v1; defer subscription until dedup design is mature.
- **No real third-party product names in walked STG matrix column.** Generic placeholders + disclaimer banner only — maintainer-walked CI evidence, not third-party endorsement.
- **No automated Hex publish from CI.** Tag-triggered workflow exists; interactive `mix hex.publish` remains the documented maintainer path (carried forward from PROJECT.md).
- **No SIEM / pgAudit / event sourcing / CDC / LiveView UI / `threadline_web` companion / umbrella package.** Carried forward from PROJECT.md.

---

## Traceability

(Populated by roadmapper after roadmap is approved.)

| REQ | Phase | Status |
|---|---|---|
| SIGRA-01 | TBD | Pending |
| SIGRA-02 | TBD | Pending |
| SIGRA-03 | TBD | Pending |
| PERF-01 | TBD | Pending |
| PERF-02 | TBD | Pending |
| PERF-03 | TBD | Pending |
| INCIDENT-01 | TBD | Pending |
| INCIDENT-02 | TBD | Pending |
| ADOPT-01 | TBD | Pending |
| ADOPT-02 | TBD | Pending |
| REL-01 | TBD | Pending |
| REL-02 | TBD | Pending |
| REL-03 | TBD | Pending |

---

*Last updated: 2026-04-26 — v1.14 milestone opened; 13 requirements across 5 categories.*
