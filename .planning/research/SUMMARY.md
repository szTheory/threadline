# v1.14 Research Synthesis — "Drop-in Production Adopter Slice"

**Project:** Threadline (mature Elixir audit library, post-v1.13, Hex `threadline 0.2.0`)
**Milestone scope:** SIGRA / PERF / INCIDENT / RELEASE / ADOPT — additive only
**Synthesized:** 2026-04-26
**Overall confidence:** HIGH (HIGH on stack/architecture/pitfalls; LOW on SIGRA's six spec-deferred design questions, by design)

This synthesis is the single document the requirements step and roadmapper read.
Detail lives in the four sibling research files (`STACK.md`, `FEATURES.md`,
`ARCHITECTURE.md`, `PITFALLS.md`) and the locked
`sigra-integration-context.md`. This summary names the decisions that are
locked, the items the spec/discuss/plan steps must still resolve, and the
phase order recommended for the roadmapper.

---

## Top findings (all four streams)

1. **v1.14 is additive, not architectural.** No changes to capture / semantics
   / exploration / retention / export / correlation / time-travel public
   surface are required. One new module (`Threadline.Integrations.Sigra`) +
   one new namespace; everything else is guides, scripts, harness, packaging.
2. **Zero new runtime deps for the library.** SIGRA stays an *optional, host-side*
   dep via `Code.ensure_loaded?/1` guard. PERF deps are `only: :dev`. ExDoc bumps
   from `~> 0.34` to `~> 0.40`. The published Hex tarball's runtime closure is
   unchanged.
3. **`Threadline.Integrations.Sigra` ships in-tree (Tier 2), not as docs-only
   (Tier 1) and not as a separate Hex package (Tier 3).** Tier 1 under-delivers
   on "drop-in"; Tier 3 is premature at ~80–150 LOC. Locked behind a runtime
   `Code.ensure_loaded?(Sigra.Session)` guard.
4. **The SIGRA spec phase has six unresolved design questions** (impersonation,
   org scope, `session.id` → `correlation_id`, telemetry-vs-Plug-only, API-token
   actor mapping, `:anonymous` fallback). These MUST be answered in a SPEC
   artifact before SIGRA-01 can plan; the adapter must NOT pre-answer them.
5. **`ActorRef` stays at 6 closed types.** Impersonation must NOT add a 7th
   type — it is a relationship between actors, not a new actor kind. A 7th
   type would force a JSONB migration of `audit_actions` rows. Locked rule.
6. **PERF harness lives in a top-level `bench/` dir owned by a NEW
   `mix verify.bench` alias and is NOT in `mix ci.all`.** Bench numbers are
   maintainer artifacts (5–30+ min on sized data), not PR gates. The OSS DNA
   "honest default tests" rule + sized-DB requirements both point this way.
7. **Each new guide ships with a doc-contract test.** v1.13's lesson (DOC-01/02/03
   + Phase 43 retroactive verification) is locked: `incident-playbook.md`,
   `performance.md`, `getting-started-saas.md`, and `integrations/sigra.md` each
   need a paired `*_doc_contract_test.exs` landing in the same phase.
8. **Verification artifacts are first-class milestone outputs.** Every v1.14
   phase delivers `NN-VERIFICATION.md` alongside its `NN-SUMMARY.md` — this
   is now a Plan-checker / reviewer gate, not a retroactive cleanup task.
9. **Three-way allowlist drift is the highest-impact RELEASE risk.** `mix.exs`
   `:files`, ExDoc `extras`, and `guides/*.md` on disk must agree; a
   `release_artifact_contract_test.exs` ties them together because four new
   guides land in v1.14.
10. **Extend the existing example app; do not fork a `threadline_phoenix_sigra/`.**
    The Phase 23 `audit_actor.ex` stub was always intended to be replaced; the
    Sigra-aware (guarded) version IS the canonical replacement.
11. **RELEASE is strictly last.** It packages SIGRA + PERF + INCIDENT + ADOPT.
    Bumping `@version` before the others land breaks CHANGELOG narrative,
    `groups_for_modules` (no `Threadline.Integrations.Sigra` to surface),
    and the published baseline numbers in CHANGELOG quotes.

---

## Stack additions

**Library runtime deps: NO CHANGES.** `ecto_sql ~> 3.10`, `postgrex ~> 0.17`,
`jason ~> 1.4`, `nimble_csv ~> 1.2`, `plug ~> 1.15`, `telemetry ~> 1.2` all
unchanged; existing constraints already accept current upstream versions.

**No `{:sigra, ...}` in library `mix.exs` — neither required nor optional.**
Sigra is a runtime expectation of the *host*, never of Threadline.

| Dep | Version | Scope | Rationale |
|---|---|---|---|
| `ex_doc` | `~> 0.40` (was `~> 0.34`) | `only: :dev, runtime: false` | RELEASE — Markdown formatter, faster docgen; non-breaking for current `docs/0` config |
| `benchee` | `~> 1.5` | `only: :dev, runtime: false` | PERF-01 — canonical Elixir benchmarking |
| `benchee_html` | `~> 1.0` | `only: :dev, runtime: false` | PERF-02 — interactive HTML reports for maintainer review |
| `benchee_markdown` | `~> 0.3` | `only: :dev, runtime: false` | PERF-02 — produces tables for embedding in `guides/performance.md` |
| `sigra` | `~> 0.2` | example app `mix.exs` only, `optional: true` | SIGRA — exercised end-to-end ONLY by the Phoenix example; library stays auth-agnostic |

**Belt-and-suspenders for "harness must not ship in Hex tarball":** (a) `mix.exs`
`:files` allowlist excludes `bench/` (preserve), (b) Benchee deps are `only: :dev`
so even if `bench/` leaked, transitive resolution would not pull them. Both must hold.

---

## Feature table-stakes (must-ship per category)

### SIGRA (closes SEED-001) — Tier 2 in-tree

- `Threadline.Integrations.Sigra` adapter module with `actor_ref_from_conn/1` + `audit_context_overrides_from_conn/1` + `actor_fn/0` factory.
- Runtime `Code.ensure_loaded?(Sigra.Session)` guard — no compile-time `alias Sigra.*` outside `lib/threadline/integrations/sigra.ex`.
- `test/support/sigra_test_doubles.ex` — minimal stubs defined ONLY when real Sigra modules absent, so the library suite stays hermetic.
- Three-conn-shape baseline: no `:current_scope`, `current_scope: nil`, `current_scope: %{user: nil}` — each returns deterministic `nil` (or `:anonymous` per Q6 SPEC), never raises.
- `guides/integrations/sigra.md` integration guide + paired doc-contract test.
- Example app's `audit_actor.ex` replaced with a Sigra-aware (guarded) extraction; `examples/threadline_phoenix/mix.exs` adds `{:sigra, "~> 0.2", optional: true}`; router wires `actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1`.

**SIGRA Stretch:** worked impersonation example end-to-end through `audit_transactions.actor_ref` → timeline; telemetry subscription on `[:sigra, :audit, :log]` (deferred — dedup design isn't mature).

### PERF — `bench/` harness + `guides/performance.md`

- `bench/` top-level dir with `audit_capture_bench.exs`, `timeline_query_bench.exs`, `scripts/seed_audit_changes.exs`, `scripts/teardown.exs`, `bench/results/` (gitignored).
- `mix verify.bench` alias — separate from `ci.all`.
- Three workload presets: `cold_single_table`, `warm_loaded` (with `audit-indexing.md` index set), `concurrent_purge`. Lowest number is what `guides/performance.md` quotes as "expected production capture rate."
- Each published number paired with a `BENCHMARK-ENV` block (PG version, Elixir/OTP, hardware class, schema preset, `changed_from` flag, exact `mix run …` command).
- Random seed pinned (`:rand.seed(:exsss, {1, 2, 3})`).
- `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` plans captured into `bench/baselines/`.
- `guides/performance.md` + ExDoc extra + paired doc-contract test (locks structure, NOT numeric values).
- Cross-link to `guides/audit-indexing.md`.

**PERF Stretch:** PgBouncer-mode side-by-side numbers; redaction + `--store-changed-from` cost numbers; SHA-pinned bench output with stale-detection; scheduled monthly bench workflow.

### INCIDENT — `guides/incident-playbook.md` + replay script

- Five canonical incidents, each with locked structure: **Scenario / Diagnosis (API) / Diagnosis (raw SQL) / Expected output / Recovery**. (Maps to existing `## Support incident queries` in `domain-reference.md` plus `as_of` for incident #4.)
- Every SQL recipe names columns explicitly — NO `SELECT *` (regex-asserted in doc-contract test). Recipes joining live application tables get an explicit `<!-- LIVE-JOIN-WARNING -->` callout.
- Each recipe ships in TWO columns: SQL and `Threadline.change_diff/2` API call. Dedicated "Reading `change_diff`" subsection enumerates INSERT/UPDATE/DELETE shape + `changed_from` opt-in matrix.
- `examples/threadline_phoenix/priv/scripts/incident_replay.exs` — Mix-runnable script.
- Hard guards: refuses to run unless `Mix.env() in [:dev, :test]` AND `THREADLINE_REPLAY_DISPOSABLE_DB=1` AND target DB name matches disposable pattern. Default `--dry-run`; mutation requires explicit `--execute`.
- Smoke test in `examples/threadline_phoenix/test/`: runs the script, asserts JSON output shape.
- ExDoc extra + cross-links from `production-checklist.md` and `domain-reference.md`.
- Doc-contract test asserts five `## N. Incident:` headings and four required subsections each.

**INCIDENT Stretch:** worked telemetry-attach example; `Postgrex.Notifications` mention with one-paragraph live-tail sketch.

### RELEASE — `threadline 0.3.0` packaging

- `mix.exs` `@version` `"0.2.0"` → `"0.3.0"`.
- CHANGELOG `## [0.3.0] — YYYY-MM-DD` with all four standard sections (`Added`/`Changed`/`Deprecated`/`Breaking`) — empty allowed, missing not.
- **Mandatory `### Upgrade from 0.2.x` subsection** with deps changes, config changes, migration steps (none expected), Sigra adapter wiring one-liner.
- README install snippet `~> 0.2` → `~> 0.3` (locked by `readme_doc_contract_test.exs` — test must update in same commit).
- ExDoc `extras` includes the four NEW guides; ExDoc `groups_for_extras` adds `Integrations: ~r{^guides/integrations/}` BEFORE `Reference:` (regex-match-order matters); ExDoc `groups_for_modules` adds new **plural** `Integrations:` group surfacing `Threadline.Integrations.Sigra` (existing singular `Integration:` row stays — `Threadline.Plug`/`Threadline.Job`/etc.).
- `v0.3.0` git tag matching `@version`.
- Maintainer publish runbook in CONTRIBUTING with literal "wait for green CI on `main` before tagging" (doc-contract-asserted).
- `release_artifact_contract_test.exs` ties `:files` glob ↔ `extras` ↔ `guides/*.md` on disk.

**RELEASE Stretch:** `mix verify.release` alias running `hex.build` + `docs` pre-flight; Hex publish workflow guard checking `gh run list` SUCCESS at tag SHA before `mix hex.publish`.

### ADOPT — SaaS quickstart + walked STG column

- `guides/getting-started-saas.md` with eight steps: prerequisites → install → `mix threadline.install` → **`mix threadline.gen.triggers`** (mandatory literal — single most common skip) → Plug wiring → first audited write → first timeline read → first `change_diff` → first `as_of`.
- Verification step calls `Threadline.Health.trigger_coverage/1` and asserts `{:covered, _}` literal in doc-contract.
- Code blocks pulled from `examples/threadline_phoenix/` source via fixture module (same pattern as `Threadline.ReadmeQuickstartFixtures`) so guide cannot drift from example.
- Closing pointer block links to `production-checklist.md`, `incident-playbook.md`, `performance.md`, `integrations/sigra.md`, `brownfield-continuity.md`, `adoption-pilot-backlog.md`.
- Prerequisites block: "Phoenix 1.7+ app with at least one Ecto schema and an `:api` pipeline; if new to Phoenix, complete phoenixframework.org/getting_started first."
- ONE fully-walked maintainer column on `STG-AUDITED-PATH-RUBRIC` in `guides/adoption-pilot-backlog.md` using **fictional/generic labels** ("ExampleCloud", "GenericPooler") + explicit `<!-- ADOPT-EXAMPLE-DISCLAIMER -->` banner — NOT real third-party product names. Evidence pointer cells link to in-repo CI artifacts (e.g. `verify-pgbouncer-topology`), NOT third-party staging URLs.

**ADOPT Stretch:** "What to wire next" decision tree at end of quickstart; integrator-tested 0.2.x → 0.3.0 walkthrough as separate `guides/upgrading-to-0.3.md`.

---

## Architectural decisions locked

**Optional-deps guard pattern (SIGRA):**
```elixir
defp sigra_loaded?, do: Code.ensure_loaded?(Sigra.Session)

def actor_ref_from_conn(conn) do
  if sigra_loaded?(), do: do_extract(conn), else: nil
end
```
Runtime probe at call time. NOT compile-time. NOT `Application.ensure_all_started`.
Survives release pruning. Library `mix.exs` does NOT add `:sigra` (not even as `optional: true`).

**`mix verify.bench` separation from `mix ci.all`:** bench step is NEVER in
`ci.all`. Plan-checker rule for the PERF phase. CI topology contract test
extended to assert no `bench` job runs on PR by default.

**Doc-contract test for every new guide (locked rule):** `incident-playbook.md`,
`performance.md`, `getting-started-saas.md`, `integrations/sigra.md` each ship
with `test/threadline/<name>_doc_contract_test.exs` IN THE SAME PHASE — not as
a follow-up, not as a stretch. Plan-checker gate.

**ExDoc `groups_for_modules` plural `Integrations:` group:** existing singular
`Integration:` (Plug, Job, Health, Continuity, Telemetry — wiring contract)
stays. New plural `Integrations:` (auth-source adapters under
`Threadline.Integrations.*`, currently just Sigra) signals "this list grows."

**RELEASE-last constraint:** RELEASE phase blocks on SIGRA, PERF, INCIDENT,
ADOPT all merging to `main`. Version bump invalid until
`Threadline.Integrations.Sigra` exists and PERF baselines exist.

### NEW files (load-bearing)

| Path | Phase | Purpose |
|---|---|---|
| `lib/threadline/integrations/sigra.ex` | SIGRA | Adapter module, runtime guard |
| `test/threadline/integrations/sigra_test.exs` | SIGRA | Unit tests against test doubles |
| `test/support/sigra_test_doubles.ex` | SIGRA | `Sigra.Session`/`Scope` shims when real absent |
| `guides/integrations/sigra.md` + doc-contract test | SIGRA | Integration guide |
| `bench/audit_capture_bench.exs`, `timeline_query_bench.exs`, `scripts/*.exs`, `README.md` | PERF | Harness |
| `guides/performance.md` + doc-contract test | PERF | Published baselines |
| `guides/incident-playbook.md` + doc-contract test | INCIDENT | Five-incident playbook |
| `examples/threadline_phoenix/priv/scripts/incident_replay.exs` + smoke test | INCIDENT | Replay script |
| `guides/getting-started-saas.md` + doc-contract test | ADOPT | 30-min SaaS quickstart |
| `test/threadline/release_artifact_contract_test.exs` | RELEASE | Triple-allowlist guard |

### MODIFIED files

`mix.exs` (every phase: `extras`, `groups_for_extras`, `groups_for_modules`, `aliases`, `deps`, eventually `@version`); `README.md` + `readme_doc_contract_test.exs` (documentation list entries; install snippet `~> 0.2` → `~> 0.3`); `CHANGELOG.md` (RELEASE phase consolidates); `examples/threadline_phoenix/` (audit_actor, mix.exs, router, README, seeds); `guides/{production-checklist,domain-reference,audit-indexing,brownfield-continuity,adoption-pilot-backlog}.md` (cross-links + STG column); `CONTRIBUTING.md` (bench section + release runbook); `.gitignore` (`bench/results/*.json`); existing `stg_doc_contract_test.exs`, `ci_topology_contract_test.exs` (extend).

---

## Recommended phase build order (Phases 44–48)

**Sequence: SIGRA → PERF → INCIDENT → ADOPT → RELEASE.**

ARCHITECTURE.md and FEATURES.md disagreed on parallelism; both agreed RELEASE
is last and ADOPT references SIGRA + INCIDENT outputs. Recommendation: pick
the FEATURES.md ordering and run **sequentially** (no parallel phases).

**Rationale:**
1. ADOPT's quickstart and decision tree must reference *concrete*
   `Threadline.Integrations.Sigra` symbols and *concrete* `incident-playbook.md`
   recipes — not aspirational pointers. Landing it AFTER both removes
   doc-contract drift.
2. INCIDENT's replay script benefits from the Sigra-wired example app (more
   realistic actor mapping in recipes).
3. PERF and SIGRA touch disjoint files but the SIGRA spec phase is a
   serializing event regardless. Sequential ordering is friction-free.
4. Sequential ordering matches v1.13's clean phase progression and the
   "verification artifacts are first-class" rule from PROJECT.md.

| # | Phase | Requirements | Notes |
|---|---|---|---|
| 44 | Sigra integration adapter | SIGRA-01, 02, 03 | **Prerequisite: `/gsd-spec-phase sigra-integration-adapter`** answering Q1–Q6 |
| 45 | Benchmark harness & published baselines | PERF-01, 02 | `bench/` layout grounded in `ecto_sql/bench` precedent |
| 46 | Incident playbook & replay script | INCIDENT-01, 02 | Composes shipped APIs |
| 47 | SaaS adopter onramp | ADOPT-01, 02 | Lands AFTER SIGRA+INCIDENT so cross-links are concrete; STG column refresh |
| 48 | Threadline 0.3.0 release | REL-01, 02 | Packages all four; CHANGELOG quotes PERF numbers |

**Research flags:**
- **Phase 44 (SIGRA): NEEDS spec/discuss before plan.** Six open design questions in `sigra-integration-context.md`.
- **Phases 45–48: standard patterns; no `/gsd-research-phase` needed.**

---

## Watch out for (cross-cutting pitfalls)

### HIGH impact

- **SIGRA-P3 — 7th `ActorRef` type added.** Forces JSONB migration of `audit_actions`. Locked rule: test asserts `length(ActorRef.types()) == 6`. SPEC must encode impersonation in `:id` or `AuditContext` extras.
- **RELEASE-P4 — three-way allowlist drift** (`mix.exs :files` ↔ ExDoc `extras` ↔ `guides/*.md`). Four new guides land in v1.14; `release_artifact_contract_test.exs` ties them together.
- **SIGRA-P1 — compile-time Sigra leakage.** `alias Sigra.Session` outside `lib/threadline/integrations/sigra.ex` makes `:sigra` a hard dep. CI grep gate.
- **CROSS-P1 — verification artifact gap (Phase 43 lesson regression).** Every v1.14 phase delivers `NN-VERIFICATION.md` IN THE SAME PHASE as `NN-SUMMARY.md`.
- **PERF-P5 — bench inside `ci.all`.** Locked: `mix verify.bench` is a separate alias, NEVER in `ci.all`. CI topology contract test asserts.
- **INCIDENT-P3 — replay script mutates production-shaped data.** Hard guards: env check + `THREADLINE_REPLAY_DISPOSABLE_DB=1` + DB-name pattern allowlist + default `--dry-run`.

### MEDIUM impact

- **SIGRA-P2 — adapter pre-answers six open questions** without SPEC artifact. Plan-checker gate.
- **SIGRA-P5 — telemetry double-recording** if `[:sigra, :audit, :log]` subscription ships without dedup design. Defer to follow-up phase.
- **INCIDENT-P1 — SQL recipe leaks redacted columns.** No-`SELECT *` regex assertion + `LIVE-JOIN-WARNING` callout assertion in doc-contract.
- **RELEASE-P2 — missing `### Upgrade from 0.2.x` subsection.** Doc-contract asserts subsection presence.
- **ADOPT-P1 — quickstart skips `mix threadline.gen.triggers`** because authors forget the two-step split. Doc-contract asserts the literal command.
- **ADOPT-P3 — STG matrix column misread as third-party endorsement.** Generic placeholders + disclaimer banner + evidence pointers to in-repo CI.

### LOW impact

PERF-P1/P3/P4 reproducibility/realism/staleness; SIGRA-P4/P6 nil-conn / API-token; INCIDENT-P2/P4 change_diff confusion / recipe drift; ADOPT-P2/P4 quickstart drift / Phoenix prereqs; CROSS-P2 unstable CI job IDs; RELEASE-P1/P3/P5 undocumented changes / version-bump rebuild / tag-before-green-CI.

---

## Open questions for spec / discuss / plan

These carry through to the appropriate phase's spec/discuss/plan steps and are NOT resolved here.

### SIGRA-01 spec phase (the six locked questions)

1. **Impersonation representation** — `ActorRef{:admin, admin_id}` + impersonation target in `AuditContext` extras (Option A) vs `:user` + impersonator in extras (Option B) vs composite `:id` encoding (Option C). NOT a 7th type.
2. **Organization scope** — extend `AuditContext` (`:org_scope` field) vs encode in `:id` vs out-of-scope for v1.14.
3. **`session.id` → `correlation_id` passthrough** — populate `audit_context.correlation_id` from `session.id` when `x-correlation-id` header absent? (Most likely yes.)
4. **Telemetry-vs-Plug-only** — subscribe to `[:sigra, :audit, :log]`? Recommended default: **Plug-only for v1**.
5. **API-token actor mapping** — `:service_account` with `on_behalf_of_user_id` in extras (recommended) vs `:user`.
6. **`:anonymous` fallback** — return `nil` (no actor row) vs `ActorRef.new(:anonymous, nil)`.

### Cross-cutting (later phases)

7. **PERF benchmark hardware/PG version for published baselines** — exact rig spec for `guides/performance.md`. PERF-01 spec decides.
8. **Whether `benchee_html` and `benchee_markdown` both ship** or just one. PERF spec decides.
9. **`Postgrex.Notifications` mention in incident playbook** — one-paragraph cross-link, or omit. INCIDENT spec decides.
10. **Incident-replay script: `Mix.Task` vs `priv/scripts/*.exs`** — `Mix.Task` recommended for `mix help` discoverability. INCIDENT plan decides.
11. **Whether to ship `mix verify.release` pre-flight alias** in v1.14 or v1.15. RELEASE plan decides.

---

## Confidence assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Versions Hex-verified 2026-04-25 (Benchee 1.5.0, ExDoc 0.40.1, Sigra 0.2.5, Postgrex 0.22.0, Plug 1.19.1) |
| Features | HIGH | Five categories grounded in shipped public API + OSS DNA + locked Sigra context |
| Architecture | HIGH | All paths grounded in repo file-by-file; optional-deps guard is standard idiom |
| Pitfalls | HIGH | All 24 pitfalls grounded in Threadline-specific architecture + v1.13 burned lessons |
| SIGRA design questions resolution | LOW | Deliberately deferred to `/gsd-spec-phase sigra-integration-adapter` |
| Whether to extend example vs fork | MEDIUM | Strong recommendation (extend); reasonable to relitigate during SIGRA-01 spec |
| Exact 5 incidents in playbook | MEDIUM | Recommended five mapped to existing `domain-reference.md` LOOP-04 + `as_of` for #4 |

**Overall:** HIGH for milestone roadmap creation; spec-phase work scoped narrowly to SIGRA's six questions.

---

## Sources

- `.planning/research/STACK.md` — dep additions, version verification, what NOT to add
- `.planning/research/FEATURES.md` — table-stakes per category, anti-features, prioritization matrix
- `.planning/research/ARCHITECTURE.md` — file layout NEW/MODIFIED, integration with three layers, build order graph
- `.planning/research/PITFALLS.md` — 24 specific pitfalls with prevention, recovery costs
- `.planning/research/sigra-integration-context.md` — locked architectural framing, three-tier menu, six open design questions
- `.planning/PROJECT.md` — milestone scope, key decisions, out-of-scope, constraints
- `.planning/seeds/SEED-001-sigra-integration-adapter.md` — promoted seed; trigger met since 2026-04-25
- `prompts/threadline-elixir-oss-dna.md` — verification entrypoints, doc-contract habits, stable CI job IDs
- v1.13 milestone audit — Phase 43 retroactive verification artifact lesson (CROSS-P1)
- Hex.pm version verification (2026-04-25) — Benchee, ExDoc, Sigra, Postgrex, Plug
- Existing `mix.exs`, `guides/*.md`, `examples/threadline_phoenix/`

---

*Synthesis for: Threadline v1.14 — Drop-in Production Adopter Slice*
*Synthesized: 2026-04-26*
*Ready for: requirements step → roadmapper (Phases 44–48)*
