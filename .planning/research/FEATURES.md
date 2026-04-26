# Feature Research — Threadline v1.14 "Drop-in Production Adopter Slice"

**Domain:** Subsequent-milestone feature additions on a shipped Elixir/Phoenix audit library (Hex `threadline` 0.2.0, post-v1.13).
**Researched:** 2026-04-25
**Confidence:** HIGH (5/5 categories grounded in shipped public API, OSS DNA, Sigra exploration note, ecosystem patterns)

This research is scoped to **what NEW capability v1.14 should ship** in five categories: SIGRA, PERF, INCIDENT, RELEASE, ADOPT. Already-shipped capability (capture, semantics, exploration, redaction, retention, export, correlation, `as_of`, `change_diff`, transaction-scoped change listing, runnable Phoenix example, audit-indexing cookbook, production checklist, adoption-pilot-backlog with STG rubric, doc-contract tests) is treated as **input**, not as research surface.

The downstream consumer is the requirements step, which will turn this into REQ-IDs.

---

## How to read this document

Each of the five categories has the same shape:

1. **What it is** — one sentence framing.
2. **Table-stakes features** — what an Elixir-OSS library of this maturity is expected to ship in this category.
3. **Differentiators** — what raises Threadline above "expected" in this category.
4. **Anti-features** — what looks reasonable but should NOT be built in v1.14.
5. **Dependencies on shipped Threadline capability** — which existing modules / APIs / files are required.
6. **Complexity** — small / medium / large per feature.

A consolidated dependency map and MVP shape live at the end.

---

## Category 1 — SIGRA: Sigra integration adapter

**What it is:** Map Sigra-authenticated request state into Threadline's `ActorRef` and `AuditContext` without making Threadline auth-aware or making Sigra Threadline-aware. Closes SEED-001.

**Important framing the spec phase owns, not this research:** the locked architectural framing and the **six open design questions** (impersonation representation, organization scope, `session.id` → `correlation_id` passthrough, telemetry-vs-Plug-only, API-token actor mapping, `:anonymous` fallback policy) live in `.planning/research/sigra-integration-context.md`. This features doc enumerates the **shape** v1.14 should ship; it does **not** resolve those six questions — that is a `/gsd-spec-phase sigra-integration-adapter` job.

### Table-stakes (Elixir-OSS auth-integration shape)

These are the five things every mature Elixir/Phoenix ecosystem auth-integration adapter ships. Threadline's `:actor_fn` callback was deliberately designed for exactly this shape (`lib/threadline/plug.ex:16-18`).

| Feature | Why expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Plug-callback shape** — adapter exposes a function with the existing `(Plug.Conn.t() -> ActorRef.t() \| nil)` signature, suitable for `plug Threadline.Plug, actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1` | Matches the canonical Phoenix auth-adapter pattern (Pow, `phx.gen.auth`, Guardian) and avoids inventing a new contract | SMALL | Pure mapping function; no new core surface in Threadline. |
| **No hard dep on `sigra`** — adapter compiles and loads even when Sigra is not in the host's deps; integration-module body guarded by `Code.ensure_loaded?(Sigra)` (or equivalent compile-time gate) | Threadline must remain auth-agnostic per `prompts/threadline-elixir-oss-dna.md:49` and per Sigra's own `001-defer-sigra-lockspire-glue-package.md` | SMALL | If absent, `actor_ref_from_conn/1` returns `nil` and the host falls through to whatever other `actor_fn` it wires. |
| **Doc + example pair** — one prose section in `guides/` (or in module `@moduledoc`) showing the recipe, plus the matching update to `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` so the example app's static-stub actor is replaced with a Sigra-shaped one | Tier 1 of the three-tier menu in `sigra-integration-context.md`; "every adopter copies the same code" is the symptom this prevents | SMALL | The Phase 23 stub explicitly comments that production replaces it with a real `current_scope` extraction — the Sigra adapter is the canonical replacement. |
| **Doc-contract test** locking the integration recipe literals (module name, function arity, `current_scope` field references) so Sigra API drift fails CI rather than silently misleading adopters | Threadline's OSS DNA explicitly treats public-doc literals as a contract (Phases 41–43 of v1.13 were the canonical example) | SMALL | Pattern is identical to the existing `Threadline.ReadmeDocContractTest` and example-README tests. |
| **Adapter returns `nil` when source library or scope is absent** — `current_scope` not assigned, `Sigra` module not loaded, or session not present → graceful `nil`, never a crash | Optional-dep ergonomics; Threadline already handles `nil` from `:actor_fn` without persisting an actor row | SMALL | Equivalent to `audit_actor.ex` returning `nil` on unauthenticated requests today. |

### Differentiators

| Feature | Value proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **In-tree `Threadline.Integrations.Sigra` module** (Tier 2 of the menu, not Tier 1) — a single canonical mapping shipped, versioned, and tested with Threadline rather than living only as docs | Adopters write **one line** (`actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1`) instead of N lines of glue; one place fixes drift for everyone | MEDIUM | Establishes the `Threadline.Integrations.*` namespace, which implies a parity expectation for Pow / `phx.gen.auth` later. The spec phase decides whether v1.14 ships Tier 1 (docs only) or Tier 2 (in-tree module). |
| **Worked impersonation example** in the integration guide — show how `scope.impersonating_from` shows up in the audit trail end-to-end (request → `audit_transactions.actor_ref` → timeline read) regardless of which design question 1 resolution is picked | Sigra's impersonation surface is the single hardest auth-shape Threadline must absorb; a worked example is what turns the integration from "compiles" to "trustworthy for real ops" | MEDIUM | Leans on shipped `Threadline.Query.timeline/2` + `Threadline.actor_history/2` to show audit visibility without new core surface. |

### Anti-features

| Anti-feature | Why requested | Why problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| **Tier 3 — separate `threadline_sigra` Hex package** (now) | Cleanest separation; matches the OSS-DNA "borrow checklist" instinct of treating integration adapters as their own published artifacts | Premature for v1.14: Tier 1 docs likely serve 95% of adopters and a separate package adds repo, CI, and version-compatibility-matrix overhead before adoption signal exists | Keep Tier 3 in the SEED-001 follow-up window — promote only if the integration grows beyond ~150 LOC, develops its own test surface, or needs an independent release cadence. |
| **Hard `sigra` dep in `threadline.mix.exs`** | Simpler conditional code; one less guard to reason about | Violates the locked architectural framing — Threadline must coexist with hosts using Pow, `phx.gen.auth`, custom auth, or no auth | Optional dep + `Code.ensure_loaded?` guard, exactly as the seed and exploration note specify. |
| **Auth-event mirroring** — Threadline subscribing to `[:sigra, :audit, :log]` to record auth-only events into `audit_actions` automatically | "Free" auth audit story | Conflates two audit concerns: Sigra owns auth-event audit; Threadline owns row-mutation + intent audit. They can coexist; merging them turns Threadline back into an auth library | Document that the two coexist; defer telemetry subscription to design question 4 in the spec phase. |
| **Threadline core surface changes for `active_organization_id` / impersonation** in v1.14 | Sigra exposes both fields and they feel like first-class actor state | Open design questions 1 and 2 may resolve to "encode in `:id`", "extend `AuditContext`", or "out of scope today" — pre-committing a schema change forecloses those options | Keep all six open questions truly open until the spec phase runs; the integration adapter is shippable as Tier 1 docs without resolving them. |
| **Cross-codebase changes to Sigra** | Could simplify the integration | Sigra has explicitly decided (`/Users/jon/projects/sigra/.planning/decisions/001-defer-sigra-lockspire-glue-package.md`) not to depend on third-party libs; reopening would relitigate a closed Sigra decision | All adapter code lives on the Threadline side, full stop. |

### Dependencies on shipped Threadline capability

- **`lib/threadline/plug.ex`** — `:actor_fn` callback (the integration's only mounting point).
- **`lib/threadline/semantics/actor_ref.ex`** — six closed types (`:user, :admin, :service_account, :job, :system, :anonymous`); JSONB serialization via `to_map/1`.
- **`lib/threadline/semantics/audit_context.ex`** — fields `actor_ref`, `request_id`, `correlation_id`, `remote_ip`.
- **`examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex`** — Phase-23 static stub the Sigra wiring replaces.
- **Doc-contract test pattern** (`test/threadline/readme_doc_contract_test.exs`, example README equivalent) — lock the literals.
- **No new core schema or API** is required for Tier 1; Tier 2 only adds an in-tree module.

### Complexity summary

- Tier 1 (docs + example wiring + doc contract): **SMALL**.
- Tier 1 + Tier 2 (Tier 1 plus in-tree `Threadline.Integrations.Sigra`): **MEDIUM**.
- Tier 3 (separate Hex package): **LARGE** — explicitly anti-feature for v1.14.

---

## Category 2 — PERF: Reproducible benchmark harness + `guides/performance.md`

**What it is:** A `bench/` directory using the Elixir-standard Benchee pattern, with documented seed, fixed PostgreSQL major version, and a published-numbers guide (`guides/performance.md`) so adopters know capture and exploration cost before they commit Threadline to a hot path.

### Table-stakes (benchmark-harness shape every mature Elixir lib ships)

The reference precedent is `ecto_sql/bench/` and `ecto_sqlite3/bench/`, both of which use Benchee with a `bench/` top-level directory, scripts split between micro (no DB roundtrip) and macro (real DB roundtrip) benchmarks, a README explaining how to run, and reproducibility guidance (warm-up, cached statements, fixed connection reuse).

| Feature | Why expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **`bench/` directory at repo root** with `.exs` scripts runnable by `mix run bench/<name>.exs` | Canonical Elixir-ecosystem pattern; matches `ecto_sql/bench`. Adopters and contributors expect this layout | SMALL | Add to `mix.exs` `:elixirc_paths` if needed; otherwise no project-shape changes. |
| **Benchee as the harness** with explicit `time:`, `warmup:`, `memory_time:` knobs and `parallel: 1` for steady-state numbers | Benchee is the de facto standard; rolling a custom harness is a smell | SMALL | Add `{:benchee, "~> 1.0", only: :dev}` to `mix.exs`. |
| **Reproducible seed** — every script seeds `:rand` with a fixed value and inserts a fixed-size fixture set before the measured block | Without this, benchmark numbers vary 10x between runs and adopters cannot reproduce or trend them | SMALL | Use `:rand.seed(:exsss, {1, 2, 3})` (or equivalent) at top of each script; document in the bench README. |
| **Fixed PostgreSQL major version** documented for the published baselines (PG14 minimum from `PROJECT.md` constraints; pick one major for the published table — likely PG16 to match active LTS) | Trigger and JSONB performance varies materially across PG majors; numbers without a version are misleading | SMALL | Document version in `guides/performance.md` and the `bench/README.md`. PG version is already pinned in `docker-compose.yml` and CI. |
| **`bench/README.md`** explaining how to run (`mix run bench/<name>.exs`), what the harness measures, what the host parameters were, and how to publish a new baseline | Without it, only the maintainer can reproduce — defeats the point | SMALL | Mirror the structure of `ecto_sqlite3/bench/README.md`. |
| **`guides/performance.md`** with **published numbers** for at least four scenarios — capture overhead per audited write (insert, update, delete), `Threadline.Query.timeline/2` p50/p95 at three table sizes, `Threadline.Export.stream_changes/2` rows-per-second, `Threadline.Retention.purge/1` rows-per-second per `batch_size` | "Numbers, or it didn't happen" is the bar set by Ecto, Oban, and Broadway docs | MEDIUM | Numbers are **maintainer-host** numbers, clearly labeled as such, with no SLA implication. |
| **ExDoc extra entry** for `guides/performance.md` so it shows up under HexDocs alongside `domain-reference.md`, `audit-indexing.md`, `production-checklist.md` | All other Threadline guides are extras; this one must be too or it drops off the discoverability map | SMALL | Add to `mix.exs` `:docs.extras`. |
| **Doc-contract test** locking at least the file's existence, headings, and the four scenario labels | Same OSS-DNA habit applied to v1.13 README work | SMALL | Mirrors `audit_indexing_doc_contract_test.exs`. |

### Differentiators

| Feature | Value proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Index-set recommendations per workload** in `guides/performance.md`, cross-linked from `audit-indexing.md` — show the published numbers for default vs recommended indexes per workload (timeline-heavy, export-heavy, correlation-heavy, retention-heavy) | The `audit-indexing.md` cookbook (v1.9) ships the **shape** of the recommendations but no measured numbers; v1.14 closes that loop | MEDIUM | Reuses the `bench/` harness; produces 2–3 extra rows in the benchmark table. |
| **PgBouncer transaction-mode confirmation** — re-run the capture-overhead micro-benchmark once direct, once via the existing `verify-pgbouncer-topology` PgBouncer container, publish both numbers | The library's biggest correctness story (transaction-local GUC, PgBouncer-safe) deserves a public **performance** number, not just a correctness check | MEDIUM | The CI topology already runs PgBouncer (`edoburu/pgbouncer`, `POOL_MODE=transaction`); the bench harness can reuse it. |
| **Cost-of-redaction note** — measured incremental cost of `:trigger_capture, mask: …` and `--store-changed-from` (sparse `changed_from`) per audited write | These are the two redaction/before-values switches operators worry about; "is this expensive?" is a recurring adoption question | MEDIUM | Two extra benchmark scenarios; numbers go in `guides/performance.md` with explicit "when this is worth it" prose. |
| **`mix verify.bench` (or `mix bench`) entrypoint** that wraps the canonical run command, matching the OSS-DNA "named entrypoints over folklore commands" rule | Contributors and CI cite one verbatim command instead of folklore | SMALL | Optional; only worth it if `bench/` will be run regularly enough that `mix run bench/<file>.exs` becomes friction. |

### Anti-features

| Anti-feature | Why requested | Why problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| **Load-test runner shipped as a library feature** (k6, wrk, Tsung wrappers, etc.) | "It would be nice to test under sustained traffic" | Threadline has no business owning a load-test runner — that is the host's job; supporting one would expand the maintenance surface indefinitely | Document host-load-test patterns in `guides/performance.md` if adoption signal demands; do not ship code. |
| **Published SLAs / "Threadline can do N writes/sec"** | Marketing-friendly | Threadline does not control the host's hardware, network, PG tuning, or workload mix; SLA-shaped numbers create false expectations | Publish **maintainer-host baselines** with the host parameters (CPU, RAM, PG version, PgBouncer mode) printed inline, framed as reference points adopters reproduce against their own infra. |
| **Continuous performance regression gate in CI** | Catches regressions automatically | Benchmark CI is famously noisy on shared runners; the Elixir-OSS norm is to run benches manually pre-release | Run benches on release branches, document the maintainer-publish runbook, add to CI only after numbers are stable enough to gate without flakiness. |
| **Synthetic huge-row JSON benchmark** (10MB `data_after`) | Looks impressive in tables | Realistic audited rows are small; an outlier benchmark distorts published numbers | Stick to realistic row sizes; if a "large-payload" warning is needed, add it to PITFALLS, not to the benchmark headline. |
| **TPS-style throughput claims without latency** | Single number, easy to publish | TPS without p50/p95 latency hides the latency story operators actually care about for hot-path inserts | Always publish percentiles alongside throughput. |

### Dependencies on shipped Threadline capability

- **Capture path** (`Threadline.Capture.TriggerSQL`, `mix threadline.gen.triggers`) — measured target.
- **`Threadline.Query.timeline/2`** + `Threadline.history/3` — measured target.
- **`Threadline.Export.stream_changes/2`**, `to_csv_iodata/2`, `to_json_document/2` — measured target.
- **`Threadline.Retention.purge/1`** — measured target.
- **`Threadline.audit_changes_for_transaction/2`**, `Threadline.change_diff/2` — measured target (incident-replay path).
- **`Threadline.as_of/4`** — measured target (point-in-time read latency).
- **PgBouncer topology** (`docker-compose.yml`, `verify-pgbouncer-topology` CI job) — reused for the pooler-mode comparison.
- **`audit-indexing.md`** — cross-linked target for index-set recommendations.

### Complexity summary

- Bench harness scaffolding + 1 capture-overhead script: **SMALL**.
- Full table-stakes set (4 scenarios published + redaction/changed_from + PgBouncer comparison + guide + ExDoc extra + doc contract): **MEDIUM**.
- Maintainer-publish runbook + `mix verify.bench` entrypoint: **SMALL**.

---

## Category 3 — INCIDENT: Production incident playbook + replayable example

**What it is:** A single guide (`guides/incident-playbook.md`) that turns the five canonical "support questions" into copy-paste recipes (API call + raw SQL + expected output), plus a runnable incident-replay script in the example app that proves the recipes round-trip.

### Table-stakes (canonical "support questions" Elixir SaaS teams ask of an audit log)

These five questions are not invented for v1.14 — they are already the validated shape of `## Support incident queries` in `guides/domain-reference.md` (LOOP-04, v1.8). v1.14's job is to turn that **catalog** into a **playbook** with full recipes and a runnable proof.

The five canonical questions, each maps to existing public API:

1. **Who** changed this row? (`Threadline.history/3` + `Threadline.actor_history/2`)
2. **What** did one actor do across tables in a window? (`Threadline.actor_history/2`, `Threadline.Query.timeline/2` + `:actor_ref`)
3. **When** did this state exist? (`Threadline.as_of/4` for one row at one instant; `Threadline.Query.timeline/2` for a window)
4. **Why** did this happen? (`Threadline.record_action/2` + `audit_actions` join via `action_id`; correlation bundle via `:correlation_id`)
5. **From where** did the request come? (`AuditContext` fields — request_id, correlation_id, remote_ip — surfaced through `audit_changes` / `audit_transactions` joins)

| Feature | Why expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **`guides/incident-playbook.md`** with one section per question, each section structured as **(a) symptom, (b) primary API call with literal arguments, (c) raw SQL with placeholder names called out, (d) expected output shape, (e) escalation pointer** | This is the shape every production-grade lib's playbook takes (Oban's exception cookbook, Broadway's troubleshooting, ecto_sql's "common mistakes") | MEDIUM | The full SQL already exists in `domain-reference.md` — the incident-playbook restructures it into a symptom-first triage shape rather than a vocabulary-first reference. |
| **Each recipe shape: API call → SQL → expected output** | Operators on call need to paste-and-run; the existing `domain-reference.md` is structured as a vocabulary, which is harder under pressure | MEDIUM | One block per question, all five must hit the same shape so muscle memory carries from question to question. |
| **ExDoc extra entry** for `guides/incident-playbook.md` | Same discoverability rule as every other guide | SMALL | Add to `mix.exs` `:docs.extras`; place in the "Operating" group. |
| **Doc-contract test** locking the five question titles, the API symbol literals, the SQL placeholder names (`your_schema`, `your_table`, etc.), and the cross-link anchors | Same OSS-DNA habit; v1.13 was the canonical demonstration that public-doc literals are public API | SMALL | Mirror `support_playbook_doc_contract_test.exs`. |
| **Cross-links from `production-checklist.md`** to the new playbook so the "Support incident queries" section in the checklist points to the playbook for the recipe and back to `domain-reference.md` for the vocabulary | The three docs (`domain-reference.md`, `production-checklist.md`, `incident-playbook.md`) must form one consistent web; orphan playbooks rot fast | SMALL | One paragraph + one link in §6 / "Support incident queries" of `production-checklist.md`. |

### Differentiators

| Feature | Value proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Runnable incident-replay script in `examples/threadline_phoenix/`** — a `priv/repo/incident_replay.exs` (or a `Mix.Task` if cleaner) that (1) seeds the example DB with a synthetic incident scenario via the audited HTTP path, (2) walks through all five questions against that data printing the actual results, and (3) is exercised by a CI test so it cannot drift | Turning a playbook from "trust me, this works" into "the CI just ran it" is the credibility differential | MEDIUM | Reuses the existing `POST /api/posts` audited path, the `record_action` + correlation linkage, the `change_diff` map, and `as_of/4`; the script is composition over already-shipped APIs, not new core surface. |
| **The script doubles as the example-app walk** — adopters clone the example, run the script, watch all five questions answer themselves against real captured rows | Best Elixir-OSS examples don't just exist; they tell a story end-to-end (Phoenix's bumblebee demos, LiveBook tutorials) | MEDIUM | One `Mix.Task` (e.g. `mix incident.replay`) inside the example app, documented in `examples/threadline_phoenix/README.md`. |
| **Doc-contract test on the example incident-replay script** — assert it runs to completion, asserts on the printed result for each of the five questions | Locks "this script works" into CI rather than relying on a screenshot in a README | SMALL | Adds one test under `examples/threadline_phoenix/test/`. |

### Anti-features

| Anti-feature | Why requested | Why problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| **Web UI / log-search interface / SIEM-shaped dashboard** | "Operators want to click around" | Explicitly out of scope per `PROJECT.md` ("Not a SIEM, not event sourcing, not a pgAudit replacement, not a data warehouse product"); "no LiveView UI in v0.1" is a key decision (`PROJECT.md`) | Keep the playbook copy-pasteable. The exploration UI is post-v0.x and a separate library decision. |
| **Auto-generated incident reports from telemetry** | "We could ship daily incident summaries" | Reporting is a host concern; Threadline emits telemetry and provides query primitives, the host wires reports | Document telemetry attach patterns in `domain-reference.md` (already shipped); link from the playbook. |
| **Severity scoring / priority ranking inside the playbook** | "Tell us which incident is most serious" | Severity is host-policy specific (PII, SOC2 scope, regulatory regime) — Threadline cannot rank for you | Stay descriptive: each question has a recipe; severity is the operator's call. |
| **Playbook recipes that require new public API** | "Could we add a helper for question N?" | Bloats the public surface mid-milestone; the five questions are already each answerable with existing public API | The playbook is composition over shipped API; if a recipe demands new code, that's a different milestone or a separate phase. |

### Dependencies on shipped Threadline capability

- **`Threadline.history/3`**, **`Threadline.actor_history/2`** — Q1, Q2.
- **`Threadline.Query.timeline/2`** with `:actor_ref`, `:correlation_id`, `:from`, `:to` — Q2, Q3, Q4.
- **`Threadline.as_of/4`** — Q3 single-row reconstruction.
- **`Threadline.record_action/2`** + `audit_actions` schema + `audit_transactions.action_id` linkage — Q4 "why".
- **`Threadline.audit_changes_for_transaction/2`**, **`Threadline.change_diff/2`** — Q4 / Q5 detail.
- **`AuditContext`** fields (request_id, correlation_id, remote_ip) — Q5 "from where".
- **`Threadline.Export` / `mix threadline.export`** — recipe (d) "save to disk for review".
- **Existing example-app HTTP audited path** (`POST /api/posts`) and Oban-job audited path (`PostTouchWorker`) — replay-script seed source.
- **Existing example-app incident JSON path** (`GET /api/audit_transactions/:id/changes`) — composition reference.
- **`guides/domain-reference.md` `## Support incident queries`** — source of the SQL templates the playbook restructures.

### Complexity summary

- `guides/incident-playbook.md` + ExDoc extra + doc-contract test + cross-links: **MEDIUM**.
- Example-app incident-replay script + CI test: **MEDIUM**.
- Both together (the v1.14 INCIDENT scope as briefed): **MEDIUM** total.

---

## Category 4 — RELEASE: `threadline 0.3.0` packaging

**What it is:** Ship `threadline 0.3.0` on Hex with an explicit 0.2.x → 0.3.0 upgrade narrative, ExDoc/module-group refresh, and the OSS-DNA-mandated release artifacts. v1.14's shipped capability (SIGRA, PERF, INCIDENT, ADOPT) is what's *being* released; this category is the **packaging** that turns those features into a Hex tarball adopters can `mix deps.update`.

### Table-stakes (0.x → 0.3 packaging items every Elixir Hex package ships)

These are the canonical Hex-publish items, drawn from prior Threadline release milestones (Phase 4 for 0.1.0, Phase 18 for 0.2.0) and from the broader Elixir-Hex ecosystem norms (Ecto, Oban, Phoenix, Plug all follow this shape).

| Feature | Why expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **`mix.exs` `@version "0.3.0"` bump** | Hex SSOT for version | SMALL | Mirrors Phase 18. |
| **`CHANGELOG.md` `## 0.3.0 — YYYY-MM-DD`** section with the four new capability headings (SIGRA, PERF, INCIDENT, ADOPT) and a "what's locked / what's new" prose line per heading | Adopters read CHANGELOG before they `mix deps.update`; a missing or vague section is a smell | SMALL | Mirrors prior Threadline CHANGELOG entries; OSS-DNA narrative-coherence rule applies (mix.exs / CHANGELOG / README all agree). |
| **ExDoc `:extras` list refreshed** — add `guides/performance.md`, `guides/incident-playbook.md`, `guides/getting-started-saas.md` | Discoverability via HexDocs is the primary reading path; new guides not in `:extras` are invisible | SMALL | Touch `mix.exs`; ordering matters (table of contents). |
| **ExDoc `:groups_for_extras`** refreshed so new guides land under the right heading (e.g. "Operating", "Adopting", "Reference") | Without grouping, HexDocs sidebar becomes a flat alphabetical list and adopters lose the narrative | SMALL | Already in `mix.exs`; just adds three entries in the right groups. |
| **ExDoc `:groups_for_modules`** refreshed if the SIGRA Tier 2 decision adds `Threadline.Integrations.Sigra` (a new top-level namespace) | Same reason as `:groups_for_extras`; new namespace deserves its own group | SMALL | Conditional on Tier 2; SMALL no-op if Tier 1 only. |
| **README install snippet bump** to `{:threadline, "~> 0.3"}` | Adopter copy-paste path; doc-contract test locks the literal | SMALL | Matches existing `Threadline.ReadmeQuickstartFixtures` doc-contract pattern. |
| **`v0.3.0` git tag** matching `@version` in `mix.exs` | Hex publish workflow is tag-driven for many Elixir libs; tag also anchors the release in GitHub for changelog discovery | SMALL | Standard `git tag v0.3.0 && git push origin v0.3.0`. |
| **Maintainer-run `mix hex.publish`** with `mix hex.publish docs` afterward (or as part of the same flow) | Explicitly the documented maintainer path per `PROJECT.md` "Out of Scope" — automated CI publish is **not** in scope | SMALL | Phase 4 / Phase 18 used the same flow. |
| **Maintainer publish runbook** in `CONTRIBUTING.md` (or under `.planning/`) — exact command order, pre-flight checks (`mix ci.all`, `mix hex.build` dry-run), tag, publish, post-publish verification | OSS-DNA "named entrypoints over folklore" — no maintainer should be reconstructing the publish flow from chat history | SMALL | Updates an existing CONTRIBUTING block; new prose in the runbook section. |
| **`mix ci.all` green on `main`** before the publish | Standard Threadline release gate | SMALL | Already enforced by GitHub Actions. |

### Differentiators

| Feature | Value proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Runnable, integrator-tested 0.2.x → 0.3.0 upgrade walkthrough** — a short `guides/upgrading-to-0.3.md` (or a CHANGELOG sub-section) that walks through the upgrade end-to-end on a real host shape, with explicit migration / config / Plug-wiring deltas, and the example app exercised by CI on the upgrade path | Most Hex 0.x → 0.x bumps ship with "see CHANGELOG" and let adopters discover surprises; an explicit upgrade walkthrough is the OSS-DNA "narrative coherence" rule taken seriously | MEDIUM | The walkthrough should explicitly call out: SIGRA tier (does Tier 1 docs require any host-side change? — typically zero); PERF guide is additive; INCIDENT guide is additive; ADOPT quickstart is additive. The upgrade should be additive-only — no breaking changes. |
| **Doc-contract test on the upgrade walkthrough** — lock the version literals, the migration filename pattern, and the install-snippet diff | Same OSS-DNA habit applied to release narrative | SMALL | Mirrors v1.13 README work. |
| **Module-group refresh that surfaces new top-level namespaces explicitly** in HexDocs (e.g. "Integrations" group if Tier 2 ships) | Adopters scanning HexDocs see "yes, Sigra is a first-class integration here" without reading the changelog | SMALL | Pure ExDoc config. |

### Anti-features

| Anti-feature | Why requested | Why problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| **Forced breaking changes for 0.3.0** (rename a public function, drop deprecated arity, change `ActorRef` shape) | "0.x is the time to break" | v1.14 is an additive milestone — SIGRA, PERF, INCIDENT, ADOPT are all new capability or new docs; nothing in scope **forces** a break. Forcing one creates upgrade friction for no payoff | Keep 0.3.0 strictly additive; defer any breaking changes to a future milestone with a real motivation (e.g. resolving open design questions 1–6 might force `ActorRef` to change later — that's the milestone for the break, not v1.14). |
| **Auto-publish on tag from CI** | "One less manual step" | Explicitly out of scope per `PROJECT.md`: "**Automated Hex publish from CI** — tag-triggered workflow exists; interactive `mix hex.publish` remains the documented maintainer path for early releases" | Keep the maintainer-interactive flow; revisit auto-publish post-1.0. |
| **Skipping the CHANGELOG entry / writing it after publish** | "We can fill it in later" | CHANGELOG is the adopter's first read on `mix deps.update` — drift here erodes trust quickly; OSS-DNA explicitly calls out narrative-coherence between mix.exs / CHANGELOG / README | CHANGELOG entry is part of the same commit as the `@version` bump. |
| **Bumping minimum Elixir/OTP/PG just for 0.3.0** | "Cleaner deps story" | Out of scope per `PROJECT.md` ("Elixir/OTP version bumps in CI — unless required for runner or dependency breakage") | Keep the constraints from PROJECT.md unless something in v1.14 actively requires a bump. |
| **Hidden test exclusions** to make the new `bench/` or example-replay tree compile faster on Hex | "Hex-publish CI is slow" | OSS-DNA explicitly forbids: "Default `mix test` honesty: never silently exclude heavy suites without updating `test/test_helper.exs` and docs together" | If something needs excluding, change `test_helper.exs` and the maintainer release runbook in the same commit. |

### Dependencies on shipped Threadline capability

- **`mix.exs`** — version SSOT, `:docs.extras`, `:groups_for_extras`, `:groups_for_modules`.
- **`CHANGELOG.md`** — section pattern from prior 0.1.0 / 0.2.0 entries.
- **`README.md`** install snippet + doc-contract test (`test/threadline/readme_doc_contract_test.exs`) — locked literal must update with the version bump.
- **`mix ci.all`** alias chain — required green for publish.
- **`mix hex.build` / `mix hex.publish`** — Hex flow.
- **`v0.2.0` tag pattern** — same shape for `v0.3.0`.
- **All four other v1.14 categories** — RELEASE is the packaging *of* SIGRA + PERF + INCIDENT + ADOPT, so it is downstream of all of them.

### Complexity summary

- Standard packaging items (version bump, CHANGELOG, ExDoc refresh, README, tag, publish runbook): **SMALL**.
- Upgrade walkthrough + doc-contract test: **SMALL/MEDIUM** depending on whether Tier 2 SIGRA ships (which adds module-group refresh).
- Total: **SMALL** if Tier 1 SIGRA, **MEDIUM** if Tier 2 SIGRA.

---

## Category 5 — ADOPT: 30-minute SaaS quickstart + walked STG matrix

**What it is:** A `guides/getting-started-saas.md` that takes a fresh Phoenix-SaaS engineer from "I have a Phoenix app" to "I have audit capture, semantics, and the first three exploration calls working" in 30 minutes, plus a fully-walked example column on the existing STG-AUDITED-PATH-RUBRIC matrix in `guides/adoption-pilot-backlog.md` so adopters see exactly what "OK with reproducible pointer" looks like end-to-end.

### Table-stakes (the shape of a 30-minute Phoenix-SaaS quickstart)

The reference precedents are the Phoenix `mix phx.new` "Up and Running" guide, Oban's "Getting Started", LiveBook's tutorials, and Ash's "Get Started" — all share the same eight-step shape, scaled to whatever the library does.

| Feature | Why expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Prerequisites block** — Elixir/OTP/PG versions, an existing Phoenix app (the guide does NOT teach Phoenix), `psql` reachable | Anti-feature mitigation: stops adopters from reading two paragraphs and discovering they don't have PG | SMALL | One block at top; mirror `examples/threadline_phoenix/README.md` prerequisites. |
| **Install** — `{:threadline, "~> 0.3"}` + `mix deps.get` | First step of every Hex library guide | SMALL | Doc-contract-test target. |
| **`mix threadline.install`** — base schema migration, `mix ecto.migrate` | Second step; matches existing example-app shape | SMALL | One block. |
| **`mix threadline.gen.triggers --tables ...`** — first audited table list, `mix ecto.migrate` | Third step | SMALL | One block. |
| **Plug wire-up** — `plug Threadline.Plug, actor_fn: ...` on the host's `:api` (or `:browser`) pipeline, with a stub `actor_fn` and a pointer to the Sigra adapter section / Pow recipe / `phx.gen.auth` recipe | Fourth step; the canonical wiring point | SMALL | The stub is intentionally a static `:service_account` — same as the existing `audit_actor.ex`. The pointer to SIGRA closes the loop. |
| **First audited write** — show the pattern from `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex`: open transaction, set `threadline.actor_ref` GUC, do the audited write, optionally call `Threadline.record_action/2` in the same transaction | Fifth step; this is the moment audit data first lands | SMALL | Reference the existing example. |
| **First timeline read** — `Threadline.Query.timeline/2` with `:table` and `:from`/`:to` | Sixth step; first read after first write | SMALL | One snippet. |
| **First `change_diff`** — fetch one `AuditChange`, project it through `Threadline.change_diff/2` | Seventh step; "what actually changed" view | SMALL | One snippet. |
| **First `as_of`** — reconstruct the row at `DateTime.utc_now()`, show map result and `cast: true` | Eighth step; closes the temporal-truth story | SMALL | Reference the existing `historical-reconstruction-walkthrough` block in the example README. |
| **Closing pointer block** — links to `production-checklist.md`, `incident-playbook.md`, `performance.md`, the Sigra integration recipe | Tells the adopter where to go next without expanding the guide's surface | SMALL | One section at the bottom. |
| **ExDoc extra + group placement** — under "Adopting" group | Discoverability | SMALL | Touch `mix.exs`. |
| **Doc-contract test** locking step ordering, command literals, API symbol references | Same OSS-DNA habit | SMALL | Mirror v1.13 work. |

### Differentiators

| Feature | Value proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **"What to wire next" decision tree** at the end of the guide — a small flowchart-shaped section: "Need cross-request correlation? → wire `:correlation_id`, see `record_action` in the same transaction. Need job-path audit? → wire `Threadline.Job` in your Oban worker. Need to replay an incident? → see `incident-playbook.md` + the example replay script. Using Sigra? → see SIGRA integration. Using Pow / phx.gen.auth / custom auth? → write your own `actor_fn` (recipe link)." | Adopters land on one guide and immediately know which next-step to read; without the decision tree they get the install but lose the full surface | SMALL | Pure prose; no new code surface. |
| **One fully-walked example column on `guides/adoption-pilot-backlog.md`'s STG-AUDITED-PATH-RUBRIC** — pick the example app's `POST /api/posts` HTTP path and the `PostTouchWorker` Oban job path, fill them in with **OK** + reproducible pointers (test path + Mix command + CI link), explicitly labeled as a maintainer-walked column so adopters see the exact shape "OK with pointer" takes | The STG rubric (v1.6, Phase 21) shipped the rules but no maintainer-filled example column; v1.14 closes that loop | MEDIUM | The data already exists — the example app's CI tests prove the audited paths. The work is restructuring the rubric to add the example column without disturbing the existing rules. |
| **Doc-contract test on the walked STG column** — assert the pointers it claims (test paths, Mix commands, CI job names) all exist | Locks the example column against drift; same OSS-DNA habit | SMALL | Mirror existing STG doc-contract test. |
| **Cross-link from `getting-started-saas.md`** to the walked STG column so the adopter's natural next step ("how do I prove this in our staging?") lands on a maintainer-walked example | One narrative arc from "install" to "production-ready evidence" | SMALL | One paragraph + one link. |

### Anti-features

| Anti-feature | Why requested | Why problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| **Phoenix-from-scratch tutorial** inside `getting-started-saas.md` (`mix phx.new`, routing, Ecto basics) | "Make it self-contained" | Out of scope: the guide is for **existing** Phoenix-SaaS teams; teaching Phoenix bloats the guide and competes with the official Phoenix guides; OSS-DNA "single contributor entrypoint" rule | Hard prerequisite + link to Phoenix's "Up and Running" — Threadline's job is the audit layer, not the framework. |
| **Authentication tutorial** inside the quickstart | "Audit needs an actor; teach me auth" | Threadline is auth-agnostic by design (locked architectural framing); teaching auth picks a winner among Sigra / Pow / `phx.gen.auth` / custom | Stub `actor_fn` returning `:service_account` (matches existing example); pointer to SIGRA, Pow recipe, `phx.gen.auth` recipe. |
| **Multi-tenant / org-scope tutorial** inside the quickstart | "Most Phoenix SaaS apps are multi-tenant" | Threadline's org-scope story is one of the open SIGRA design questions (#2 in `sigra-integration-context.md`); answering here pre-commits a design | Mention multi-tenant as a "what to wire next" branch with a forward link; do not pretend it's solved. |
| **LiveView-based "see your audit log" demo** | "It would be nicer to see it" | "No LiveView UI in v0.x" is a key decision (`PROJECT.md`); building one inside the quickstart contradicts the milestone | Show the timeline / change_diff / as_of through `iex` snippets; UI is a separate library decision post-1.0. |
| **Promises about timing** ("you'll be done in 30 minutes") that aren't budgeted against the prerequisites | Marketing-friendly | If the adopter doesn't have PG running, the "30 minutes" is dishonest | Frame as "30 minutes once your prerequisites are in place"; print the prerequisite block prominently. |
| **A re-walked production checklist** inside the quickstart | "One-stop shop" | Duplicates `production-checklist.md` and creates two specs that drift; OSS-DNA "prefer links over duplicating long command tables" rule | Link to `production-checklist.md` from the closing pointer block; do not re-list its items. |

### Dependencies on shipped Threadline capability

- **`mix threadline.install`** — quickstart step 2.
- **`mix threadline.gen.triggers`** — quickstart step 3.
- **`Threadline.Plug`** + `:actor_fn` — quickstart step 4.
- **Existing example app's audit pattern** (`Blog.create_post/2`, transaction-local GUC, `record_action/2`) — quickstart step 5.
- **`Threadline.Query.timeline/2`** — quickstart step 6.
- **`Threadline.change_diff/2`** + `Threadline.audit_changes_for_transaction/2` — quickstart step 7.
- **`Threadline.as_of/4`** — quickstart step 8.
- **`Threadline.Job`** — referenced from "what to wire next".
- **`guides/adoption-pilot-backlog.md`** — STG-AUDITED-PATH-RUBRIC structure, walked column lands here.
- **Example-app CI tests** (`PostsAuditPathTest`, `PostsCorrelationPathTest`, `PostsIncidentJsonPathTest`, Oban worker test) — pointers in the walked STG column.
- **(Forward-link only)** SIGRA recipe and INCIDENT replay script — both shipped in v1.14, the quickstart points at them; no circular dependency because the quickstart is additive prose.

### Complexity summary

- `getting-started-saas.md` (table-stakes 8-step quickstart + ExDoc + doc contract): **MEDIUM**.
- "What to wire next" decision tree: **SMALL** addition.
- Walked STG matrix column + doc-contract test: **MEDIUM**.
- Total: **MEDIUM**.

---

## Cross-category dependency map

```
SIGRA ─── (independent core; references Threadline.Plug + ActorRef + AuditContext)
   │
   └─ referenced by ─────────► ADOPT (quickstart "what to wire next" decision tree)
                                  │
                                  └─ references ──► INCIDENT (replay script branch)
                                                    │
                                                    └─ depends on ── existing example-app paths
                                                                     + record_action + change_diff
                                                                     + as_of + timeline

PERF ── (independent; reuses existing capture / query / export / retention APIs +
         existing PgBouncer CI topology)
   │
   └─ referenced by ───────► ADOPT (closing pointer block)
                              ADOPT walked STG column (PgBouncer evidence pointer)

RELEASE ── (downstream of everything; packages SIGRA + PERF + INCIDENT + ADOPT)
   │
   └─ depends on ──► all four other categories landing first
                     mix.exs / CHANGELOG.md / README.md / ExDoc extras / v0.3.0 tag
```

**Phase-ordering implication for the requirements step / roadmap step:**

1. **SIGRA** and **PERF** can be researched, spec'd, and built in parallel — they are independent and each closes a different adoption gap.
2. **INCIDENT** depends on no other v1.14 capability for its core (it composes shipped APIs); the example-app replay-script CI test is independently mergeable but must coexist with whatever existing tests it touches.
3. **ADOPT** is most useful **last** in execution order because its "what to wire next" tree references SIGRA and INCIDENT outputs by name and link; if those land first, ADOPT's links are concrete rather than aspirational.
4. **RELEASE** is strictly last — its sole job is to package what the other four shipped.

A reasonable phase ordering for the roadmap step (not prescriptive):

`SIGRA + PERF` (parallel) → `INCIDENT` → `ADOPT` → `RELEASE`.

---

## Anti-features that span multiple categories

A few anti-feature themes recur across categories — calling them out once so the requirements step can encode them as cross-cutting "do not's":

1. **No new opinionated UI.** Out across SIGRA, INCIDENT, ADOPT (no LiveView, no SIEM, no dashboard). Aligned with `PROJECT.md` "no LiveView UI in v0.1".
2. **No forced breaking changes.** v1.14 is additive across SIGRA, PERF, INCIDENT, RELEASE, ADOPT. RELEASE is explicit — if a real motivation for a break appears, it is its own future milestone.
3. **No auto-published / auto-promoted release artifacts.** Maintainer-interactive `mix hex.publish` remains the documented path; CI runs benches and incident-replay scripts but does not push tags or publish.
4. **No promises (SLA, "30-min" without prereqs, "X writes/sec without context").** Across PERF and ADOPT — frame as maintainer-host baselines and prerequisite-conditional timing.
5. **No hidden test exclusions** (default `mix test` honesty rule). Across PERF (bench dir), INCIDENT (replay script CI), ADOPT (quickstart doc-contract test) — all live tests visible in `mix test` or behind a documented alias.
6. **No re-research of shipped capability.** Capture / semantics / exploration / redaction / retention / export / correlation / `as_of` / `change_diff` / transaction-scoped change listing / runnable example are inputs, not surface.

---

## Feature prioritization matrix (for the requirements step)

| Category | Feature | User value | Implementation cost | Priority |
|---------|---------|------------|---------------------|----------|
| SIGRA | Tier 1 docs + example-app wiring + doc contract | HIGH | LOW (SMALL) | P1 |
| SIGRA | Tier 2 in-tree `Threadline.Integrations.Sigra` module | HIGH | MEDIUM | P1 (spec phase decides Tier 1 vs 1+2) |
| SIGRA | Tier 3 separate Hex package | LOW (premature) | HIGH | P3 (anti-feature for v1.14) |
| PERF | `bench/` harness + Benchee + 4 published scenarios | HIGH | MEDIUM | P1 |
| PERF | `guides/performance.md` + ExDoc extra + doc contract | HIGH | MEDIUM | P1 |
| PERF | PgBouncer-mode comparison numbers | MEDIUM | MEDIUM | P2 |
| PERF | Redaction + `changed_from` cost numbers | MEDIUM | MEDIUM | P2 |
| PERF | Index-set recommendations per workload | HIGH | MEDIUM | P1 |
| PERF | `mix verify.bench` entrypoint | LOW | LOW | P3 |
| INCIDENT | `guides/incident-playbook.md` + ExDoc extra + doc contract + cross-links | HIGH | MEDIUM | P1 |
| INCIDENT | Example-app replay script + CI test | HIGH | MEDIUM | P1 |
| RELEASE | Standard 0.3.0 packaging (mix.exs / CHANGELOG / README / extras / tag / publish runbook) | HIGH | LOW (SMALL) | P1 |
| RELEASE | Upgrade walkthrough + doc-contract test | HIGH | LOW/MEDIUM | P1 |
| RELEASE | Module-group refresh (if Tier 2 SIGRA ships) | MEDIUM | LOW | P1 conditional |
| ADOPT | `guides/getting-started-saas.md` 8-step quickstart + ExDoc + doc contract | HIGH | MEDIUM | P1 |
| ADOPT | "What to wire next" decision tree | HIGH | LOW (SMALL) | P1 |
| ADOPT | Walked STG matrix column + doc-contract test | HIGH | MEDIUM | P1 |

**Priority key:** P1 = must ship in v1.14, P2 = should ship if scope holds, P3 = explicitly deferred.

---

## Sources

- `.planning/PROJECT.md` — current state, milestone scope, key decisions, out-of-scope list, constraints.
- `.planning/research/sigra-integration-context.md` — locked Sigra integration framing, three-tier menu, six open design questions.
- `.planning/seeds/SEED-001-sigra-integration-adapter.md` — seed conditions, complexity sizing, breadcrumbs.
- `prompts/threadline-elixir-oss-dna.md` — verification entrypoints, doc-contract habits, release narrative coherence, named entrypoints, default-`mix test` honesty.
- `guides/domain-reference.md` — vocabulary, telemetry catalog, support-incident-queries section (LOOP-04), exploration API routing, `as_of` hub.
- `guides/production-checklist.md` — operator checks, retention/purge cadence, support-incident pre-launch checklist.
- `guides/adoption-pilot-backlog.md` — STG-HOST-TOPOLOGY-TEMPLATE and STG-AUDITED-PATH-RUBRIC structure, CI evidence pass.
- `README.md` — public-API contract surface and install snippet.
- `examples/threadline_phoenix/README.md` — runnable Phoenix integration shape: install, gen.triggers, Plug wiring, audited HTTP + Oban paths, correlation, `as_of` walkthrough, incident JSON drill-down.
- Ecosystem references for benchmark-harness shape: [ecto_sql/bench](https://github.com/elixir-ecto/ecto_sql/tree/master/bench), [ecto_sqlite3 bench README](https://github.com/elixir-sqlite/ecto_sqlite3/blob/main/bench/README.md), [Benchee](https://github.com/bencheeorg/benchee), [Benchee guide on AppSignal](https://blog.appsignal.com/2022/09/06/benchmark-your-elixir-apps-performance-with-benchee.html).
- Ecosystem references for ExDoc extras / module groups: [ExDoc](https://hexdocs.pm/ex_doc/readme.html), [ExDoc CHANGELOG (groups_for_extras / groups_for_modules)](https://hexdocs.pm/ex_doc/changelog.html).

---

*Feature research for: Threadline v1.14 — Drop-in Production Adopter Slice (subsequent milestone, additive scope).*
*Researched: 2026-04-25*
