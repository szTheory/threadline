# Pitfalls Research — v1.14 "Drop-in Production Adopter Slice"

**Domain:** Adding 5 capability categories (SIGRA / PERF / INCIDENT / RELEASE / ADOPT) to a mature, production-track Elixir audit library (Threadline 0.2.0).
**Researched:** 2026-04-25
**Confidence:** HIGH

This document is **integration-specific**. Generic Elixir / generic OSS pitfalls (typespec drift, README typos, etc.) are out of scope — they are caught by the existing `mix ci.all` chain. Pitfalls below are mistakes that are **specific to layering these five capabilities on top of Threadline's existing architecture and constraints** (Path B custom triggers, six-type closed `ActorRef`, transaction-local GUC, doc-contract test discipline, integrator-owned STG evidence, no `threadline_web`).

Each pitfall has: **Description / Why it happens / Warning sign / Prevention / Owning phase**. Prevention strategies are actionable — a test to add, a CI rule, or a code-review gate the plan-checker can enforce.

---

## SIGRA pitfalls (closes SEED-001)

These derive from the locked architectural framing in `.planning/research/sigra-integration-context.md`: **Sigra unaware of Threadline; Threadline auth-agnostic; six open design questions deferred to the spec phase, not pre-committed in the adapter.**

### SIGRA-P1: Compile-time dependency leakage from Threadline core into Sigra

**What goes wrong:**
The adapter is implemented as `Threadline.Integrations.Sigra` but `Threadline` core (`lib/threadline/plug.ex`, `lib/threadline/semantics/actor_ref.ex`) gains `alias Sigra.Session` or `import Sigra.Scope` calls. Threadline now hard-depends on `sigra` to compile. Hosts using Pow, `phx.gen.auth`, or no auth get a forced transitive dep and a coupled release cadence.

**Why it happens:**
Convenience: it's easier to write `%Sigra.Session{} = sigra_session` than to introduce a struct-shape duck-typing layer. Adapter author forgets that `Threadline.Integrations.Sigra` is **inside** the `threadline` package — it ships in the same Hex tarball.

**Warning sign:**
- `grep -rn "Sigra" lib/threadline/` returns hits **outside** `lib/threadline/integrations/sigra.ex`.
- `mix.exs` `deps` gains a `{:sigra, ...}` entry (even as `optional: true`).
- `mix deps.tree` for an adopter not using Sigra shows `sigra` pulled in transitively.

**Prevention:**
1. Add a CI grep gate: `! grep -rn "Sigra\." lib/threadline/ | grep -v 'lib/threadline/integrations/sigra'` (any hit fails).
2. The integration module **must** use `Code.ensure_loaded?(Sigra.Session)` at call time and pattern-match on a plain map (`%{__struct__: Sigra.Session, id: id, ...}`) — never `alias` or `require` Sigra modules at compile time.
3. `mix.exs` does **not** add `sigra` to `deps` — neither as required nor optional. Sigra is a runtime expectation of the **host**, not Threadline.
4. Add a doc-contract test that compiles `Threadline.Integrations.Sigra` in a fresh project **without** `sigra` in deps and asserts it returns `{:error, :sigra_not_loaded}` (or equivalent) instead of raising `UndefinedFunctionError`.

**Owning phase:** SIGRA (adapter implementation phase)

---

### SIGRA-P2: Adapter pre-answers the six open design questions

**What goes wrong:**
The adapter ships with hard-coded answers to questions the spec phase was supposed to deliberate (impersonation representation, org scope, session-id → correlation_id, telemetry vs Plug, API-token actor mapping, anonymous fallback). One example: adapter encodes impersonation as `"admin:42:as:user:99"` in `ActorRef.id` because the implementer thought it was "obviously right." Audit consumers now have a JSONB shape contract that was never debated.

**Why it happens:**
Six open questions feel like blockers; the implementer picks pragmatic defaults to "unblock the ship." This is the exact failure mode the seed `SEED-001` warned against: "the three-tier choice is real and shouldn't be foreclosed."

**Warning sign:**
- Adapter PR lacks an explicit reference to a completed `/gsd-spec-phase sigra-integration-adapter` artifact.
- ActorRef `:id` strings contain colons, JSON, or composite encoding without a documented schema.
- `AuditContext` extras gain new keys (`:org_id`, `:impersonator_id`) without a corresponding decision record.
- Adapter tests assert on a specific impersonation encoding without a doc reference explaining why.

**Prevention:**
1. Plan-checker rule: SIGRA phase plan **must** cite a spec/discuss artifact (`.planning/phases/NN-sigra/SPEC.md` or equivalent) that explicitly answers each of the six questions with rationale. Plans that link only to `sigra-integration-context.md` (the context note) without a decision record fail the gate.
2. For each of the six questions, the SPEC artifact must state: **answer**, **rejected alternatives**, **revisit trigger**.
3. If a question is intentionally deferred (e.g. org scope ruled out of scope for v1.14), the deferral is recorded as a **decision**, not omitted.

**Owning phase:** SIGRA (and a preceding spec/discuss phase before plan)

---

### SIGRA-P3: 7th `ActorRef` type added for impersonation

**What goes wrong:**
A `:impersonator` (or `:impersonated_user`) type is added to `ActorRef`'s closed list of six types (`:user, :admin, :service_account, :job, :system, :anonymous`). Existing pattern-match call sites — including JSONB serialization in `ActorRef.to_map/1`, capture-side trigger output, and any consumer doing `case actor_ref.type do :user -> ...; :admin -> ...; _ -> ...` — silently lose coverage. Doc contract for ActorRef shape breaks. Migrating archival `audit_actions` rows is non-trivial (the type lives in JSONB, not a schema column).

**Why it happens:**
"Impersonation is a kind of actor, so it deserves its own type" — a category mistake. Impersonation is a **relationship between two actors**, not a third actor type. The ActorRef closed-set is a deliberate design constraint (see `lib/threadline/semantics/actor_ref.ex:24` and the architectural framing).

**Warning sign:**
- Diff to `lib/threadline/semantics/actor_ref.ex` adds an atom to the `@types` list or to the type spec.
- A migration appears that mutates JSONB `actor_ref` blobs.
- Tests assert `type == :impersonator` anywhere.

**Prevention:**
1. Code-review rule: any change to `@types` in `actor_ref.ex` requires an explicit milestone-level decision and updates `Threadline` `groups_for_modules` Schemas section + JSONB shape doc contract.
2. SPEC phase must adopt one of: **(A)** `:admin` actor with impersonation target in `AuditContext` extras (`audit_actions.context_extra`), **(B)** `:user` actor with impersonator in extras, or **(C)** composite encoding **with explicit JSONB shape doc contract** — but **not** a 7th type.
3. Add a test that asserts `length(ActorRef.types()) == 6` and lock it in `actor_ref_test.exs` so the closed-set invariant fails CI on extension.

**Owning phase:** SIGRA (gated by SPEC decision on Q1 / Q2)

---

### SIGRA-P4: `current_scope == nil` raises instead of returning gracefully

**What goes wrong:**
Adapter is `def actor_ref_from_conn(conn), do: build(conn.assigns.current_scope)` and `build(nil)` is undefined or matches a struct pattern. An unauthenticated request (login page, public endpoint, health check that hits an audited path) crashes the Plug pipeline with `FunctionClauseError`. Worse: the failure happens inside `Threadline.Plug` so the host sees a 500 from an audit library, not from auth — terrible debugging story.

**Why it happens:**
Implementer tests against authenticated fixtures only. Sigra adapter author assumes "scope is always present in our app" and forgets the `actor_fn` contract is `(Plug.Conn.t() -> ActorRef.t() | nil)` — `nil` is **valid** and **expected**.

**Warning sign:**
- No test case in the adapter test file with `assigns: %{}` (no `current_scope` key).
- No test case for `current_scope: nil` explicitly.
- Adapter `def` uses struct pattern in head (`def actor_ref_from_conn(%Plug.Conn{assigns: %{current_scope: %Sigra.Scope{}}} = conn)`) without a fallback clause.

**Prevention:**
1. Adapter test file must include three baseline cases: `conn` with no `:current_scope` assign, `conn` with `current_scope: nil`, `conn` with `current_scope: %{user: nil}`. Each must return a deterministic value (per the SPEC's answer to Q6 — `nil` or `ActorRef.new(:anonymous, nil)`), never raise.
2. Adapter `actor_ref_from_conn/1` has an explicit `def actor_ref_from_conn(_conn), do: <fallback>` clause as its last function head.
3. `Threadline.Plug` integration test uses the adapter against a `Plug.Test.conn(:get, "/")` with empty assigns and asserts no crash.

**Owning phase:** SIGRA

---

### SIGRA-P5: Double-recording actions via `[:sigra, :audit, :log]` telemetry subscription

**What goes wrong:**
Adapter subscribes to Sigra's `[:sigra, :audit, :log]` telemetry event "to catch Oban-job-triggered re-auth" and calls `Threadline.record_action/2` from the handler. Every Sigra-audited login that goes through a Plug already gets captured by `Threadline.Plug` + the audited transaction; the telemetry subscription captures it **again**. `audit_actions` table doubles for any auth event. Worse: telemetry handlers run **outside** the host's `Repo.transaction`, so the second record has a different (or missing) `transaction_id` and breaks correlation.

**Why it happens:**
Q4 in the open questions ("telemetry vs Plug-only") gets answered "both" without thinking through deduplication. Sigra fires telemetry **after** its own DB commit; the Plug captures **during** the host transaction; without a guard, both fire for the same logical event.

**Warning sign:**
- `:telemetry.attach` calls in `Threadline.Integrations.Sigra` without a corresponding dedup mechanism (`:already_recorded` flag in conn assigns, idempotency key, etc.).
- Test that exercises a full Plug-pipeline auth event and asserts `audit_actions` count — count > 1 for one logical event.
- `[:sigra, :audit, :log]` handler calls `Threadline.record_action/2` without checking if the originating conn already passed through `Threadline.Plug`.

**Prevention:**
1. SPEC phase Q4 default: **Plug-only for v1**. Telemetry subscription is a **separate** future phase, not bundled into the v1.14 adapter.
2. If telemetry subscription ships, the handler must **only** fire for events that have **no** corresponding `Plug.Conn` (i.e., genuinely non-HTTP auth paths). Implementation: handler checks `:threadline_action_recorded` flag in metadata and skips if set; `Threadline.Plug` sets the flag.
3. Integration test: a single logged-in HTTP request to an audited endpoint produces **exactly one** row in `audit_actions` for the auth event.

**Owning phase:** SIGRA — but subscription itself should be **deferred** to a follow-up phase

---

### SIGRA-P6: API-token requests mapped to `:user` instead of `:service_account`

**What goes wrong:**
Adapter sees `Sigra.APIToken`-authenticated request, finds `current_scope.user` (the on-behalf-of user), and returns `ActorRef.new(:user, user.id)`. Audit consumers think a human did it. Compliance answers ("which actor performed this?") are wrong. Forensics conflates token-driven automation with interactive sessions.

**Why it happens:**
The token *belongs* to a user, so `:user` "looks right." But `ActorRef` types encode **how the action originated**, not **who owns the credential**: a CI bot using Alice's API token is acting as a service account on Alice's behalf, not as Alice.

**Warning sign:**
- Adapter has no branch on `conn.private[:sigra_session].type` or on the presence of `Sigra.APIToken`.
- Test fixtures for "API token request" assert `actor_ref.type == :user`.
- Open question Q5 in the SPEC is unanswered or answered "use `:user` because the token has a user owner."

**Prevention:**
1. SPEC phase Q5 default: **`:service_account` for token-authenticated requests**, with the token's owning-user-id encoded in `AuditContext` extras (e.g., `on_behalf_of_user_id`) for forensic linkage.
2. Adapter test: token-authenticated conn fixture (`conn.private[:sigra_session].type == :api_token` or equivalent Sigra-side marker) must produce `actor_ref.type == :service_account`.
3. Doc contract: `guides/integrations-sigra.md` states the mapping table explicitly: `standard session → :user`, `api_token → :service_account`, `impersonation → :admin (per Q1 decision)`.

**Owning phase:** SIGRA (gated by SPEC decision on Q5)

---

## PERF pitfalls (benchmark harness + published baselines)

These derive from Threadline's specific posture: Path B custom triggers, transaction-local GUC, and a Hex package whose `:files` list controls what ships.

### PERF-P1: Numbers that can't be reproduced (no seed, no PG version pin, no schema)

**What goes wrong:**
`guides/performance.md` publishes "Threadline captures 10k inserts/sec on Postgres 14" without specifying the schema (one audited table? ten? `changed_from` enabled? trigger redaction config?), the benchmark seed, the row width, the index set, or the hardware class. A reader runs the harness and gets 3k/sec; either Threadline is lying or their setup is wrong — neither explains which.

**Why it happens:**
Benchmark output is a single number that "feels" complete. The variability surface is hidden until someone tries to reproduce.

**Warning sign:**
- `guides/performance.md` has bare numbers without a "How this was measured" block.
- Benchmark code in `bench/` has hard-coded values for PG version, schema, batch size that aren't surfaced in the published table.
- No `BENCHMARK-ENV` doc-contract anchor.

**Prevention:**
1. Every published number in `guides/performance.md` must be paired with an inline metadata row: PG version, Elixir/OTP, hardware class (e.g. "GitHub Actions `ubuntu-latest` Apr 2026" or "MacBook Pro M2"), schema preset name, `changed_from` on/off, and the exact `mix run bench/...` command.
2. The harness emits a `bench/output/<timestamp>.json` with the env metadata and seed. The guide cites a specific output file (committed or linked).
3. Doc-contract test: `test/threadline/performance_doc_contract_test.exs` asserts the guide contains `BENCHMARK-ENV` block with required keys (PG version, OTP version, schema preset, changed_from flag).
4. Random data uses a fixed seed (`:rand.seed(:exsss, {1, 2, 3})`); the seed is documented.

**Owning phase:** PERF

---

### PERF-P2: Harness ships in the Hex tarball and bloats install / pulls bench-only deps

**What goes wrong:**
`bench/` is added to `mix.exs` `:files` list (or simply not excluded), and benchmark dependencies (`benchee`, optional `benchee_html`, `:eex_evaluator` test fixtures, etc.) leak into runtime via test-only dep declarations that aren't actually test-only. Adopters install `threadline 0.3.0` and find: (a) tarball ballooned, (b) `benchee` pulled into their runtime tree, (c) `bench/` Mix tasks shipped to production.

**Why it happens:**
`mix.exs` `:files` defaults to a permissive list; adding `bench/` for `mix deps.get` ergonomics inside the repo is one line. Excluding it is two lines and easy to forget.

**Warning sign:**
- `mix hex.build` output for `0.3.0` includes any path under `bench/`.
- `mix deps` (after `mix deps.get` in a fresh project depending on `threadline 0.3.0`) includes `benchee` (or other bench-only libs) without `only: :dev` discipline.
- `:files` in `mix.exs` doesn't have an explicit allowlist — or includes `~w(bench)`.

**Prevention:**
1. Keep `:files` as an **allowlist**, not denylist (current `mix.exs:106` already does this — preserve the pattern). Adding `bench` requires explicit decision; default is excluded.
2. Benchmark deps go in a **separate** `mix.exs` under `bench/` (a sibling Mix project, like `examples/threadline_phoenix/` is) — not in the root `mix.exs`.
3. RELEASE phase has a doc-contract test that runs `mix hex.build`, untars the result, and asserts `bench/`, `examples/`, `.planning/`, `prompts/`, and `priv/ci/` are absent from the tarball (allowlist match).

**Owning phase:** PERF (harness layout) + RELEASE (tarball gate)

---

### PERF-P3: Benchmarks measure unrealistic workload shapes

**What goes wrong:**
Harness benchmarks `INSERT` against a freshly truncated `audit_changes` table with no indexes, no retention policy active, and one audited table. Published number: "10k/sec." Production reality: 50 audited tables, 200M-row `audit_changes`, GIN index on `actor_ref`, retention purging concurrently — measured ~800/sec. Adopters miss capacity planning by 12×.

**Why it happens:**
Benchmark targets the **library code path**, not the **deployment workload**. Optimizing for a synthetic best case is easy; modeling realistic load requires intent.

**Warning sign:**
- Benchmark scripts only test single-table INSERT.
- No "warm cache" / "loaded table" variant in `bench/`.
- Performance guide doesn't differentiate "fresh DB" vs "loaded DB" numbers.
- No benchmark exercises `Threadline.Retention.purge/1` running concurrently with capture.

**Prevention:**
1. Harness ships **at minimum three** workload presets, each separately published in `guides/performance.md`:
   - `cold_single_table` — empty table, single audited entity (best case, useful as baseline).
   - `warm_loaded` — `audit_changes` pre-loaded with N rows (e.g. 10M) and the indexes from `guides/audit-indexing.md`.
   - `concurrent_purge` — capture running while `Threadline.Retention.purge/1` runs in another process.
2. Each preset has its own number in the published table; the **lowest** number is what the guide quotes as "expected production capture rate."
3. SPEC artifact for PERF phase explicitly enumerates which presets ship in v1.14 (vs deferred).

**Owning phase:** PERF

---

### PERF-P4: Stale committed benchmark output drifts and lies

**What goes wrong:**
`bench/output/2026-04-25.json` is committed and cited by the guide. Six months later, after `Threadline.Capture.TriggerSQL` is refactored and `audit_indexing.md` recommends a new index, the committed output is unchanged but the underlying behavior shifted. New adopters trust a stale number.

**Why it happens:**
"Just commit one good run" feels final. There's no automatic mechanism to detect that the run is stale relative to current code.

**Warning sign:**
- `bench/output/` directory contains files older than the most recent change to `lib/threadline/capture/`.
- No mention in the guide of when numbers were last reproduced.
- No CI job (even monthly / scheduled) re-runs benchmarks.

**Prevention:**
1. Each committed benchmark output file includes a `git rev-parse HEAD` commit SHA at capture time. Doc-contract test asserts the cited SHA is **either** HEAD **or** has no diff in `lib/threadline/capture/`, `priv/threadline/`, or the relevant trigger SQL paths since that SHA. If diffs exist, CI fails with "benchmark numbers stale — re-run `mix bench` and update."
2. Guide states the SHA explicitly: "Last measured at SHA `abc1234` on 2026-04-25."
3. Optional: scheduled GitHub Actions workflow runs benchmarks monthly on `main` and opens an issue when delta exceeds 10%.

**Owning phase:** PERF

---

### PERF-P5: Benchmarks run inside `mix ci.all` and slow every PR

**What goes wrong:**
PERF phase author adds `bench` step to the `ci.all` alias "for safety." Every PR now runs 30 seconds to 5 minutes of benchmarks, contributors get noisy variance, CI cost goes up, and people start using `--no-verify` to skip hooks.

**Why it happens:**
Putting things in `ci.all` is the easy way to "make sure it's exercised." The OSS DNA explicitly cautions against this: "Layered CI jobs over hidden skips" — benchmarks are a **separate layer**, not part of the default verify chain.

**Warning sign:**
- Diff to `mix.exs` `aliases` adds `"bench"` (or similar) to the `"ci.all": [...]` list.
- `mix ci.all` wall time on `main` increases by >20% after PERF phase merges.
- Contributors complain about CI duration on PR feedback.

**Prevention:**
1. PERF phase adds a **separate** `mix verify.bench` alias, not in `ci.all`. Run on `main` only via a path-filtered or scheduled GitHub Actions job (per OSS DNA: "Path filters + main: Expensive nested jobs still run on `main` ... when PRs are path-filtered").
2. Plan-checker rule: PERF phase plan must explicitly state the verify alias is **not** added to `ci.all`. Diff review confirms.
3. CI workflow doc contract: existing `test/threadline/ci_topology_contract_test.exs` extended (or new `bench_topology_contract_test.exs`) asserts the `bench` job has `id: verify-bench` and runs only on `main` or schedule, not on PRs by default.

**Owning phase:** PERF

---

## INCIDENT pitfalls (`guides/incident-playbook.md` + replay script)

These build on existing v1.10–v1.11 work (`Threadline.ChangeDiff`, `Threadline.audit_changes_for_transaction/2`, support-incident-queries doc).

### INCIDENT-P1: SQL recipe leaks redacted columns into copy-paste output

**What goes wrong:**
Playbook recipe for "what changed in transaction X" is `SELECT * FROM audit_changes WHERE transaction_id = $1`. `audit_changes.changed_from` and `change_diff` JSONB include columns that the trigger config has masked or excluded. The recipe is correct mechanically; it bypasses the **redaction policy** that the trigger SQL enforces — it shows the fields the redaction policy already redacted (because they're nulled / masked in the JSONB), but it makes it look like redaction is a UI-layer concern, encouraging a culture of "just go to SQL." Worse, if a recipe pre-dates redaction config or includes a JOIN to the live source table (`SELECT a.*, u.email FROM audit_changes a JOIN users u ON ...`), the SQL **does** leak un-redacted live data into incident tickets.

**Why it happens:**
SQL recipes feel "raw" and "honest"; authors use `SELECT *` because the audit table is the audit table. The subtle interaction with `:trigger_capture` mask/exclude config is invisible from the SQL writer's POV.

**Warning sign:**
- Recipes in `guides/incident-playbook.md` use `SELECT *` from `audit_changes` or join to live application tables (`users`, `posts`, etc.).
- No explicit "redaction reminder" callout in any recipe.
- Recipes don't reference `:trigger_capture` or `RedactionPolicy`.

**Prevention:**
1. Every SQL recipe in the playbook explicitly names columns: `SELECT id, table_name, op, captured_at, change_diff, changed_from FROM audit_changes ...` — never `SELECT *`. Doc-contract test asserts no `SELECT \*` (regex `\bSELECT\s+\*\b`) appears in `guides/incident-playbook.md`.
2. Recipes that reach into live application tables get a **callout box**: "This recipe joins to live tables; the redaction policy in `:trigger_capture` does **not** apply to live data. Confirm with security before sharing output." Doc-contract test asserts each "live join" recipe has the callout marker (e.g. `<!-- LIVE-JOIN-WARNING -->`).
3. Playbook intro section explicitly cross-links `:trigger_capture` config and reminds operators: "If a column is masked/excluded in audit, do not query it from live tables for the same incident without re-confirming policy."

**Owning phase:** INCIDENT

---

### INCIDENT-P2: Recipes don't show how to read `change_diff` correctly

**What goes wrong:**
Recipe shows `SELECT change_diff FROM audit_changes WHERE id = $1` and operator gets a JSONB blob: `{"op": "UPDATE", "changes": {"role": ["member", "admin"]}}`. Operator doesn't know:
- For INSERT, `change_diff` has no `before` values (per `Threadline.ChangeDiff` docs — `before_values` is absent).
- For DELETE, `change_diff` has no `after`.
- `op` is uppercase in the wire map but lowercase in the trigger; `change_diff` normalizes (Phase 34 decision); raw SQL on `audit_changes.change_diff` JSONB requires knowing which form is stored.
- `changed_from` is a **separate** column, populated only when `--store-changed-from` was passed at trigger generation.

The operator copy-pastes a recipe that "works" for UPDATE and silently produces empty `before` for INSERT, then incorrectly reports "we lost data."

**Why it happens:**
Recipes optimize for the example case (UPDATE on a single column) and don't enumerate the INSERT/DELETE/`changed_from`-off matrix. Existing `Threadline.ChangeDiff` doc explains it but recipes don't link into it.

**Warning sign:**
- No INSERT example in the playbook recipes.
- No DELETE example.
- No mention of `changed_from` opt-in.
- Recipes don't reference `Threadline.change_diff/2` (the API path) as the preferred approach.

**Prevention:**
1. Each canonical incident playbook recipe ships in **two columns**: SQL and `Threadline.change_diff/2` API call. Doc-contract test asserts both columns are present for each of the five incidents.
2. Playbook has a dedicated "Reading `change_diff`" subsection that enumerates INSERT / UPDATE / DELETE shape and the `changed_from` opt-in matrix. Cross-links to `Threadline.ChangeDiff` ExDoc.
3. Each SQL recipe includes a comment: `-- INSERT: before_values absent. DELETE: after_values absent. See guides/incident-playbook.md#reading-change-diff`.

**Owning phase:** INCIDENT

---

### INCIDENT-P3: Replay script mutates production-shaped data without sandbox

**What goes wrong:**
The example app's incident-replay script (`examples/threadline_phoenix/lib/.../incident_replay.ex` or a Mix task) is intended to "let operators reproduce a 5-incident scenario locally." Author writes it against the example app's normal Repo. An adopter copy-pastes it into their host app pointing at staging or prod, or runs it against the example app expecting it to be read-only — and it mutates `posts`, fires triggers, generates fresh `audit_changes` rows. Now the audit timeline has replay-generated noise mixed with real history.

**Why it happens:**
The replay script needs to **demonstrate** capture, so it has to write. The boundary between "demo in a fresh sandbox DB" and "run against my data" isn't enforced — only documented in a README the operator may not read.

**Warning sign:**
- Replay script doesn't check `Mix.env()` or a `:replay_allowed` config flag.
- Script doesn't drop+recreate (or use a dedicated test schema) before running.
- README for the script doesn't say "RUN ONLY AGAINST A DISPOSABLE DATABASE" in a callout.
- No `--dry-run` mode.

**Prevention:**
1. Replay script **refuses to run** unless `Mix.env() in [:dev, :test]` **and** `THREADLINE_REPLAY_DISPOSABLE_DB=1` is set, **and** the target DB name matches a known disposable pattern (`*_test`, `*_replay`, etc.). Hard-coded: refuses to run against `prod` env or any DB whose name contains `prod` or `staging`.
2. Script ships with `--dry-run` as the **default**; mutation requires explicit `--execute`.
3. `examples/threadline_phoenix/README.md` runbook section for the replay script includes the literal `disposable database only` requirement; doc-contract test (extending `examples/.../README.md` doc contract) asserts the literal.
4. Before mutation, the script prints the target DB name and `audit_changes` row count and asks for confirmation in interactive mode.

**Owning phase:** INCIDENT

---

### INCIDENT-P4: Recipes drift from shipped APIs and break silently

**What goes wrong:**
Playbook cites `Threadline.Query.timeline/2` with a filter key that gets renamed in 0.4.0 (`:correlation_id` → `:correlation`). The doc has no contract test, so the playbook keeps shipping the wrong literal. Adopters copy-paste, get `ArgumentError: unknown filter :correlation_id`, file an issue, and Threadline looks careless.

**Why it happens:**
v1.13 already burned this lesson with READMEs (DOC-01/02/03 retroactive doc-contract tests). Playbook is a new doc surface — without a doc-contract test it inherits the same drift risk.

**Warning sign:**
- `guides/incident-playbook.md` ships without a corresponding `test/threadline/incident_playbook_doc_contract_test.exs`.
- Playbook recipes use module/function names without anchored doc-contract literals.
- A future Threadline rename or signature change doesn't fail CI.

**Prevention:**
1. Phase deliverable explicitly lists `test/threadline/incident_playbook_doc_contract_test.exs` as a required artifact (not a "stretch goal"). Plan-checker gate: phase plan that doesn't include this file fails review.
2. Doc-contract test asserts each of the five recipes contains the **exact** literal API call as it appears in the relevant ExDoc (`Threadline.audit_changes_for_transaction/2`, `Threadline.change_diff/2`, `Threadline.timeline/2` with correct keys, etc.). Pattern: tests pull literals from `Threadline.ReadmeQuickstartFixtures` (or sibling fixture module) so renames cascade.
3. Each recipe is also exercised by an integration test in `examples/threadline_phoenix` that runs the recipe end-to-end against the example app.

**Owning phase:** INCIDENT (and the doc-contract pattern is reused by ADOPT — see ADOPT-P2)

---

## RELEASE pitfalls (threadline 0.3.0 packaging)

These build on the v1.4 / v1.7 / v1.13 lessons (Hex 0.1.0, 0.2.0, doc contract repair).

### RELEASE-P1: Undocumented breaking change in `as_of/4` cast behavior

**What goes wrong:**
v1.12 shipped `Threadline.as_of/4` with `cast: true` returning a struct with **loose** historical loading. v1.14 quietly tightens or relaxes the cast policy as part of unrelated polish; CHANGELOG says "minor as_of improvements." Adopters relying on loose-cast (or strict-cast) error semantics break on upgrade and the upgrade story is unclear.

**Why it happens:**
`as_of/4` is recent (v1.12) and its behavior boundary is subtle. Small refactors during 0.3.0 packaging touch it without recognizing the public contract.

**Warning sign:**
- Diff between `v0.2.0` and `v0.3.0` HEAD touches `lib/threadline/as_of.ex` (or wherever the loose-cast logic lives) without a corresponding CHANGELOG entry under `## [0.3.0]`.
- `Threadline.as_of/4` ExDoc changes between versions in any observable way (return shape, error tuple, cast policy) without a `Changed` entry in CHANGELOG.
- README quickstart `as_of/4` example output changes silently.

**Prevention:**
1. CHANGELOG `## [0.3.0]` has explicit `## Changed` and `## Breaking` sections. **Empty is allowed; missing is not.** RELEASE phase plan-checker rule: `0.3.0` entry must have all four standard sections (Added / Changed / Deprecated / Breaking) even if empty.
2. README + ExDoc doc-contract tests already lock the `as_of/4` example output (per v1.13 work); RELEASE phase verifies these still pass and any intentional change updates fixtures + CHANGELOG together.
3. RELEASE phase plan includes an "API surface diff" step: `mix xref graph` (or simpler: `mix docs` + grep public modules) compared between `v0.2.0` tag and HEAD. Any new/removed/renamed public function lands in CHANGELOG.

**Owning phase:** RELEASE

---

### RELEASE-P2: CHANGELOG missing 0.2.x → 0.3.0 upgrade narrative

**What goes wrong:**
CHANGELOG `## [0.3.0]` lists "Added: SIGRA integration. Added: incident playbook." Adopter on 0.2.0 reads it, runs `mix deps.update threadline`, and hits a config validation error because they didn't notice the SIGRA adapter expects `:actor_fn` to be a captured-MFA reference (or whatever the SPEC decision is). No upgrade steps; adopter has to reverse-engineer the diff.

**Why it happens:**
"What changed" is easy; "what an existing adopter must do" requires extra empathy. Bullet list of features ≠ upgrade guide.

**Warning sign:**
- `## [0.3.0]` has no `### Upgrade from 0.2.x` subsection.
- README "Upgrading" section (if it exists) is unchanged.
- No `guides/upgrading.md` exists or is not updated.

**Prevention:**
1. CHANGELOG `## [0.3.0]` **must** include `### Upgrade from 0.2.x` subsection enumerating: deps changes, config changes, migration steps (none expected, but state explicitly), Sigra adapter wiring (one-liner with link to integration guide), and known incompatibilities. Doc-contract test asserts the subsection exists.
2. RELEASE plan-checker rule: phase plan that doesn't list "0.2.x → 0.3.0 upgrade narrative" as a deliverable fails review.
3. Optional `guides/upgrading.md` (or a section in CHANGELOG) added to ExDoc `extras` list.

**Owning phase:** RELEASE

---

### RELEASE-P3: `mix.exs` version bump without re-running `mix hex.build` and `mix docs`

**What goes wrong:**
Author bumps `@version` in `mix.exs` to `0.3.0`, commits, tags `v0.3.0`, pushes. Tag-triggered Hex publish workflow fires. But `mix hex.build` was never run locally to verify the tarball; `mix docs` was never run to check ExDoc compiles with the new extras (the new `guides/integrations-sigra.md`, `guides/performance.md`, `guides/incident-playbook.md`, `guides/getting-started-saas.md`). Hex publish succeeds; HexDocs build fails silently or omits the new guides.

**Why it happens:**
The current `mix.exs` doesn't have `extras` for the four new guides yet. Bumping version without re-running build steps is a subtle skip — the existing CI runs `mix docs` for the existing extras, so it passes; but the new guides' literal paths in `extras` get forgotten.

**Warning sign:**
- Diff to `mix.exs` between v0.2.0 and v0.3.0 changes `@version` but **not** `defp docs/0` `extras` list — yet the milestone shipped four new guides.
- Local `mix hex.build` produces warnings about missing files in `:files`.
- HexDocs at https://hexdocs.pm/threadline/0.3.0 has 4 sidebar entries (the 0.2.0 set), not 8.

**Prevention:**
1. RELEASE phase has an explicit checklist item: "Update `defp docs/0` `extras` to include all new guides shipped in v1.14, in correct `groups_for_extras` group."
2. Pre-release smoke test (a Mix alias like `mix verify.release`): runs `mix hex.build`, `mix docs`, asserts the generated `doc/` index includes every file listed in `:files`'s `guides/` allowlist. Doc-contract test asserts `extras` count matches `guides/*.md` count (or an explicit allowlist).
3. RELEASE plan-checker rule: phase plan must list "Update `mix.exs` `extras`" as a separate deliverable from "Bump `@version`."

**Owning phase:** RELEASE

---

### RELEASE-P4: `:files` allowlist in `mix.exs` doesn't include new guides

**What goes wrong:**
v1.14 ships `guides/integrations-sigra.md`, `guides/performance.md`, `guides/incident-playbook.md`, `guides/getting-started-saas.md`. Current `mix.exs:106` has `files: ~w(lib guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md)` — **`guides` is in the list**, so the new guides ship. **But** if the team thinks "we've already added `guides`, we're fine" they may not realize that **only files referenced by `extras` appear in HexDocs**. New guides ship in the **tarball** but not in **HexDocs** unless `extras` is also updated. (See RELEASE-P3.)

A second variant: someone "tidies" `:files` to be more restrictive (`~w(lib guides/domain-reference.md ...)`) and now new guides silently don't ship.

**Why it happens:**
Two separate allowlists (`:files` for tarball, `extras` for HexDocs) and they don't cross-validate. Easy to update one and not the other.

**Warning sign:**
- `mix hex.build` succeeds, but `tar tf threadline-0.3.0.tar.gz | grep guides` doesn't include all four new files.
- HexDocs sidebar missing one or more new guides.
- `:files` line in `mix.exs` lists individual files instead of `guides` directory glob.

**Prevention:**
1. Keep `:files` as `~w(lib guides ...)` — directory-level allowlist, not per-file. Prevents drift on guide additions.
2. Add a CI test that ties `:files`, `extras`, and `guides/*.md` together: every file in `guides/` must appear in `extras`, every entry in `extras` must exist on disk, and `:files` glob must cover them all. Test: `test/threadline/release_artifact_contract_test.exs`.
3. RELEASE phase deliverable: this contract test exists and is in `mix ci.all`.

**Owning phase:** RELEASE (with PERF / INCIDENT / SIGRA / ADOPT each contributing one new guide that the test must cover)

---

### RELEASE-P5: `v0.3.0` tag pushed before tests pass

**What goes wrong:**
RELEASE phase author runs `git tag v0.3.0 && git push --tags` immediately after merging the version bump, expecting CI to "catch anything wrong." Tag-triggered publish workflow fires before the post-merge CI on `main` finishes. Hex 0.3.0 ships with a known regression that the next CI run would have caught.

**Why it happens:**
Tag push is local; CI is remote. The author intuits "tagging is just a label, the real check is CI" — backwards.

**Warning sign:**
- `git log` shows the tag commit and the merge commit at the same SHA without a green CI status check between them.
- Hex publish workflow doesn't check `mix ci.all` before publishing.
- CONTRIBUTING / RELEASE runbook doesn't say "wait for green CI on main before tagging."

**Prevention:**
1. RELEASE runbook (`CONTRIBUTING.md` "Releasing" section) states **explicitly**: "Wait for `main` CI to be green at the version-bump commit. Only then tag. Do not push the tag until CI is green at that exact SHA." Doc-contract test asserts the literal "wait for green CI" appears in the runbook.
2. Tag-triggered Hex publish workflow has a guard step: `gh run list --branch main --limit 1 --json conclusion --jq '.[0].conclusion == "success"'` before `mix hex.publish`. If not success, abort.
3. Optional: protected `v*` tag rule on GitHub requiring branch protection / status checks.

**Owning phase:** RELEASE

---

## ADOPT pitfalls (`guides/getting-started-saas.md` + maintainer-walked STG column)

These build on v1.7 / v1.8 / v1.9 (example app, support loop) and v1.6 (STG rubric).

### ADOPT-P1: Quickstart skips `gen.triggers`, leaves readers without audit rows

**What goes wrong:**
"30-minute Phoenix-SaaS quickstart" walks reader through `mix deps.get`, `mix threadline.install`, `Threadline.Plug` wiring, and a sample request. Reader makes a request, queries `audit_changes`, gets an empty result, files an issue: "audit doesn't work." Cause: the quickstart skipped `mix threadline.gen.triggers <table>` because the author thought "install does that" — it doesn't (gen.triggers is per-audited-table by design, see existing `examples/threadline_phoenix` runbook).

**Why it happens:**
Author writing the quickstart already has the model loaded; `gen.triggers` feels redundant when they look at their own working setup. The two-step (install schema vs generate per-table triggers) split is a deliberate Threadline design choice that the quickstart must explicitly walk through.

**Warning sign:**
- Quickstart guide doesn't contain the literal command `mix threadline.gen.triggers` (or `mix threadline.gen.triggers --store-changed-from` if `changed_from` is part of the SaaS recipe).
- Quickstart's "verify" step is "make a request" without "run `Threadline.Health.trigger_coverage/1`."
- No mention of `verify_coverage` config or `expected_tables`.

**Prevention:**
1. Quickstart guide has a **mandatory** "Generate triggers" step between install and first request, with the exact `mix threadline.gen.triggers <table>` command. Doc-contract test asserts the literal.
2. Quickstart's verification step calls `Threadline.Health.trigger_coverage/1` and shows the expected `{:covered, _}` tuple. Asserts the literal in doc-contract.
3. Quickstart includes a "Why two steps?" callout (one paragraph) explaining install = catalog + GUC bridge, gen.triggers = per-audited-table. Cross-link to `guides/domain-reference.md`.
4. The maintainer-walked STG column in `guides/adoption-pilot-backlog.md` (the second ADOPT deliverable) explicitly walks the same two-step in the audited-path rubric.

**Owning phase:** ADOPT

---

### ADOPT-P2: Quickstart diverges from example app and rots silently

**What goes wrong:**
Quickstart guide hand-writes `Posts` controller and `Blog.create_post/2` — but the actual `examples/threadline_phoenix/` app has its own (similar but not identical) implementation. Six months later, example app gets a refactor (e.g. `:correlation_id` propagation tightened in v1.8); guide doesn't. New adopter follows guide, hits subtle inconsistency with the live example app.

**Why it happens:**
Quickstart authors copy-paste the canonical pattern at the time of writing; the live example app evolves; nobody runs a "do the literals match?" check.

**Warning sign:**
- Code blocks in `guides/getting-started-saas.md` that aren't sourced from `examples/threadline_phoenix/`.
- Differences between guide's `actor_fn` example and `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` (the SIGRA-updated version per SIGRA-01–03).
- No doc-contract test linking the guide to the example app source.

**Prevention:**
1. Quickstart guide's code blocks are **either** (a) generated/extracted from `examples/threadline_phoenix/` source via a fixture module (preferred — same pattern as `Threadline.ReadmeQuickstartFixtures`), or (b) have a doc-contract test that asserts the guide's literals match the example app source character-for-character.
2. The guide's "Verify" section instructs the reader to clone `examples/threadline_phoenix/`, follow its README, and **then** apply the quickstart on their own app — minimizing divergent prose.
3. Doc-contract test: `test/threadline/getting_started_saas_doc_contract_test.exs` asserts (a) presence of literal commands (`mix threadline.install`, `mix threadline.gen.triggers`, `mix verify.example`-equivalent verify), (b) `actor_fn` example matches `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` post-SIGRA update.

**Owning phase:** ADOPT

---

### ADOPT-P3: Maintainer-walked STG matrix column misread as third-party endorsement

**What goes wrong:**
v1.6 STG-01 was deliberate about this: "no maintainer-attested third-party STG URLs" was a non-goal. ADOPT-02 ships **one fully-walked example column** in `guides/adoption-pilot-backlog.md` showing how to fill the STG-HOST-TOPOLOGY-TEMPLATE. A reader interprets the example column as "Threadline maintainers have certified $cloud_provider + $pooler at staging" — exactly the misread v1.6 worked to prevent.

**Why it happens:**
A filled-in example with concrete labels ("Render.com", "Supabase Pooler") looks like a third-party validation badge. The example is supposed to be a **shape** demo, not an endorsement.

**Warning sign:**
- The example column uses real third-party product names (Render, Supabase, Fly.io, etc.) without an explicit "this is a maintainer-walked illustration, not a certified topology" disclaimer.
- The example column's "Evidence link" cell points to a real third-party staging URL the maintainer doesn't control.
- README or external comms quotes the example column as "Threadline supports Render.com staging."

**Prevention:**
1. The maintainer-walked column uses **fictional / generic labels** (e.g. "ExampleCloud", "GenericPooler") **or** a labeled disclaimer banner above the matrix: `<!-- ADOPT-EXAMPLE-DISCLAIMER --> This row is a maintainer-walked illustration of the rubric. It is **not** an endorsement, certification, or evidence of compatibility with any third-party host. Adopters fill their own rows with their own evidence.`
2. Doc-contract test: `test/threadline/stg_doc_contract_test.exs` (already exists per v1.6) extended to assert the disclaimer literal appears immediately above the example column, and that the example column's product labels match an allowlist of generic placeholders.
3. The "Evidence link" in the example column points to an in-repo CI artifact (e.g. `.github/workflows/ci.yml#verify-pgbouncer-topology` — a *library* CI proof) **not** a third-party staging URL — reinforcing "library CI ≠ host pilot."
4. Plan-checker rule: ADOPT phase plan that proposes real third-party product names in the example column fails review.

**Owning phase:** ADOPT

---

### ADOPT-P4: Quickstart assumes Phoenix knowledge and skips the Phoenix wiring it claims

**What goes wrong:**
Title is "30-minute Phoenix-SaaS quickstart" but step 3 is "add `Threadline.Plug` to your `:api` pipeline" without showing **where** that pipeline lives, what `pipe_through :api` looks like, or how to confirm the Plug actually runs. Reader new to Phoenix gets stuck. Reader experienced in Phoenix wonders why the guide is called "Phoenix" if it assumes the wiring is obvious.

**Why it happens:**
Quickstart authors are deep in the Threadline domain and ambient about Phoenix; the line between "Threadline content" and "Phoenix scaffolding" gets fuzzy. Either the guide is for Phoenix beginners (and needs more scaffolding) or for Phoenix users (and should explicitly say so).

**Warning sign:**
- Guide title contains "Phoenix" but doesn't reference `mix phx.new` or `phx.gen.auth`-shaped projects as a baseline.
- Guide assumes a `router.ex` shape without showing the literal block.
- Guide doesn't link to Phoenix's own getting-started.

**Prevention:**
1. Guide opens with a **prerequisites** block: "This guide assumes you have a Phoenix 1.7+ app with at least one Ecto schema and an `:api` pipeline. If you're new to Phoenix, complete [phoenixframework.org/getting_started] first."
2. Each Threadline-specific step includes the **enclosing Phoenix context** verbatim — e.g., `lib/my_app_web/router.ex` shown with the actual `pipeline :api do` block, not just the one new line.
3. Guide ends with a "Did it work?" verification block that runs against the example app's known-good shape: `Threadline.audit_changes_for_transaction/2` returns at least one row after a sample request.
4. Doc-contract test asserts the prerequisites block literal and the verification block literal both appear.

**Owning phase:** ADOPT

---

## Cross-cutting pitfalls (affect more than one v1.14 phase)

### CROSS-P1: Verification artifact gap (Phase 43 lesson regression)

**What goes wrong:**
v1.13 Phase 43 was retroactive: it had to write `41-VERIFICATION.md` and `42-VERIFICATION.md` after the fact because earlier phases shipped without them. v1.14 phases (SIGRA / PERF / INCIDENT / RELEASE / ADOPT) repeat the mistake — they ship `SUMMARY.md` without paired `NN-VERIFICATION.md` artifacts, and the milestone close has to retroactively reconcile.

**Why it happens:**
Phase summary writing feels like the natural end; verification artifact is "extra." The OSS DNA explicitly calls this out (§1 Verify and CI: "Three-source traceability"), but it relies on phase authors remembering.

**Warning sign:**
- Phase merges with `NN-SUMMARY.md` but no `NN-VERIFICATION.md`.
- `requirements-completed` block in summary doesn't cite specific verify artifacts.

**Prevention:**
1. Plan-checker rule (already implied by v1.13 Phase 43 lesson, now made explicit): every v1.14 phase plan deliverable list **must** include `NN-VERIFICATION.md` as a separately-named artifact.
2. Code-reviewer rule: phase PR cannot merge without `NN-VERIFICATION.md` in `.planning/phases/NN-*/`.
3. Milestone audit script greps for `NN-VERIFICATION.md` for each completed phase before allowing milestone close.

**Owning phase:** All five (SIGRA, PERF, INCIDENT, RELEASE, ADOPT)

---

### CROSS-P2: Stale CI job IDs / new jobs in `ci.all` without job-id discipline

**What goes wrong:**
PERF adds a benchmark job; INCIDENT adds a replay-script job; ADOPT adds a quickstart-doc-contract job. Each phase author names the job whatever feels descriptive ("benchmarks", "incident-replay-test"). Future grep-based contracts and `act` invocations in `CONTRIBUTING.md` break because there's no naming convention.

**Why it happens:**
GitHub Actions job naming feels cosmetic. The OSS DNA disagrees: §1 "Stable CI job identifiers: Keep job `id:` immutable for `act`, scripts, and grep-based contracts."

**Warning sign:**
- New jobs added with names like `bench`, `replay`, `docs` (terse, generic) instead of stable IDs like `verify-bench`, `verify-incident-replay`, `verify-getting-started`.
- `test/threadline/ci_topology_contract_test.exs` not extended when new jobs land.

**Prevention:**
1. New CI job IDs follow the existing `verify-*` naming convention. Plan-checker rule: phase plans that add CI jobs must specify the `id:` literal.
2. `test/threadline/ci_topology_contract_test.exs` extended to assert each new job ID exists. Doc-contract test fails if a job's `id:` is later renamed.

**Owning phase:** PERF / INCIDENT / ADOPT (whichever introduces new CI jobs); RELEASE coordinates final state

---

## Technical debt patterns (v1.14 specific)

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Pre-answer SIGRA open question Q1 (impersonation) inline in adapter without SPEC | Unblocks SIGRA phase | JSONB shape contract foreclosed; future re-design requires migration of `audit_actions` rows | **Never** — SPEC phase is non-optional gate |
| Add `bench/` to root `mix.exs` deps for ergonomics | One `mix deps.get` covers everything | `benchee` leaks into Hex runtime tree on adopters | **Never** — bench/ must be a sibling Mix project |
| Skip benchmark workload presets, ship one number | Faster PERF phase | Adopters miscalibrate capacity; reputational risk on numbers being wrong | **Never** — at least `cold` + `warm_loaded` ship together |
| Real third-party labels in maintainer-walked STG column | Concrete, relatable example | Misread as endorsement; v1.6 non-goal violated | **Never** — generic placeholders + disclaimer required |
| Tag `v0.3.0` immediately after merge | Faster release | Possible Hex publish of broken code | **Never** — wait-for-green-CI is non-optional |
| Bundle telemetry-subscription adapter (Q4) into v1.14 SIGRA phase | One-shot complete integration | Double-recording risk; deduplication design isn't mature | Acceptable **only** if SPEC explicitly covers dedup with test coverage |

---

## Integration gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Sigra adapter — `current_scope` access | Pattern-match on `%Sigra.Scope{}` at compile time | Pattern-match on plain map shape; guard with `Code.ensure_loaded?/1` |
| Sigra adapter — session metadata | Pull `session.id` directly into `ActorRef.id` | `session.id` belongs in `AuditContext.correlation_id` (per Q3 SPEC decision); actor `id` is the user/admin/service-account stable id |
| PgBouncer + benchmarks | Benchmark on direct Postgres only, claim "PgBouncer-safe" | Benchmark also through `verify-pgbouncer-topology` chain; publish both numbers |
| Replay script vs example app DB | Replay script writes to the same DB the example app's `mix test` uses | Replay script targets a separate disposable DB name; test isolation enforced |
| Hex publish + new guides | Bump version, push tag, assume HexDocs picks up new guides | Update `mix.exs` `extras`, run local `mix docs`, verify sidebar before tag |

---

## Performance traps (v1.14 specific)

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Synthetic-best-case benchmark cited as production capacity | Capacity planning misses by >5× | Three-preset minimum; quote lowest in headline number | First production deploy with realistic data volume |
| Benchmarks inside `ci.all` | PR CI wall time grows; contributors skip hooks | Separate `verify.bench` alias; `main`-only or scheduled job | After a few PRs accumulate the new step |
| Stale committed bench output | Numbers slowly diverge from reality, undetected | Commit-SHA pin in output; doc-contract test fails on drift | Whenever capture path is refactored (could be any phase) |
| Telemetry double-recording from `[:sigra, :audit, :log]` | `audit_actions` row count = 2× expected | Plug-only adapter for v1; defer telemetry to next phase | Production with login traffic |

---

## Security mistakes (v1.14 specific)

| Mistake | Risk | Prevention |
|---------|------|------------|
| Incident playbook recipe joins audit table to live application table without redaction reminder | Live un-redacted PII pasted into incident tickets | Live-join recipes get explicit callout + doc-contract assertion |
| Replay script runnable against production DB | Production audit timeline polluted with replay rows; possible data mutation | Hard guards: env, DB-name pattern, `--execute` opt-in, default `--dry-run` |
| API-token requests mapped to `:user` actor | Forensic answers conflate human and automation actors | `:service_account` mapping per SPEC Q5; doc-contract assertion |
| Sigra session metadata (`ip`, `geo_*`) propagated into `AuditContext` extras without retention policy review | PII retained beyond retention policy intent; GDPR scope confusion | SPEC explicitly enumerates which Sigra fields cross into Threadline; default to **none** without explicit decision |

---

## "Looks Done But Isn't" Checklist

- [ ] **SIGRA adapter:** Often missing graceful `current_scope == nil` handling — verify three-conn-shape test (`P4`).
- [ ] **SIGRA adapter:** Often missing SPEC artifact answering all six open questions — verify `.planning/phases/NN-sigra/SPEC.md` exists and references each Q1–Q6 (`P2`).
- [ ] **PERF guide:** Often missing reproducibility metadata — verify `BENCHMARK-ENV` block per published number (`P1`).
- [ ] **PERF tarball:** Often includes `bench/` accidentally — verify `tar tf` output excludes `bench/` and `examples/` (`P2` + `RELEASE-P4`).
- [ ] **INCIDENT playbook:** Often missing INSERT/DELETE shape examples — verify each canonical incident has all three op variants (`P2`).
- [ ] **INCIDENT replay:** Often missing DB-name guard — verify script refuses to run against `prod`/`staging` patterns (`P3`).
- [ ] **RELEASE 0.3.0:** Often missing `Upgrade from 0.2.x` subsection — verify CHANGELOG `## [0.3.0]` has it (`P2`).
- [ ] **RELEASE 0.3.0:** Often missing new guides in `extras` — verify `mix docs` HexDocs sidebar count matches `guides/*.md` count (`P3`, `P4`).
- [ ] **RELEASE 0.3.0:** Often missing wait-for-green-CI in runbook — verify CONTRIBUTING `Releasing` section literal (`P5`).
- [ ] **ADOPT quickstart:** Often missing `mix threadline.gen.triggers` literal — verify doc-contract assertion (`P1`).
- [ ] **ADOPT STG column:** Often uses real third-party product names — verify generic placeholders + disclaimer (`P3`).
- [ ] **All phases:** Often missing `NN-VERIFICATION.md` — verify each completed phase artifact directory (`CROSS-P1`).

---

## Recovery strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| SIGRA adapter pre-answered Q1 wrong (impersonation encoding) | HIGH (JSONB migration of `audit_actions`) | Add second supported encoding; deprecate old in 0.4.0; document migration path |
| 7th `ActorRef` type added (P3) | HIGH | Revert; re-encode in `AuditContext`; no JSONB migration if only future writes affected, full migration if archival rows have the new type |
| Bench output committed but stale | LOW | Re-run on HEAD; commit new output with current SHA |
| Hex 0.3.0 published with regression (RELEASE-P5) | MEDIUM | Yank 0.3.0 (`mix hex.publish.docs`-equivalent yank), publish 0.3.1 with fix; CHANGELOG documents yank |
| Quickstart drifted from example app (ADOPT-P2) | LOW | Update guide literals; doc-contract test then locks them; one-time fix per drift |
| Incident replay polluted production audit table | HIGH | Forensic identification of replay-generated rows by `actor_ref` or `correlation_id` pattern; targeted purge via `Threadline.Retention.purge/1` with custom cutoff |

---

## Pitfall-to-phase mapping

| Pitfall | Owning phase | Verification |
|---------|--------------|--------------|
| SIGRA-P1 — Compile dep leakage | SIGRA | CI grep gate + tarball deps test |
| SIGRA-P2 — Pre-answered open questions | SIGRA (+ SPEC predecessor) | Plan-checker requires SPEC artifact citing Q1–Q6 |
| SIGRA-P3 — 7th ActorRef type | SIGRA | `length(ActorRef.types()) == 6` test |
| SIGRA-P4 — `current_scope == nil` raises | SIGRA | Three-conn-shape test in adapter test file |
| SIGRA-P5 — Telemetry double-recording | SIGRA (defer subscription) | Single-event integration test counts `audit_actions == 1` |
| SIGRA-P6 — API token → `:user` | SIGRA | Adapter test asserts token fixture → `:service_account` |
| PERF-P1 — Non-reproducible numbers | PERF | `BENCHMARK-ENV` doc-contract |
| PERF-P2 — Harness in tarball | PERF + RELEASE | `mix hex.build` tarball-content test |
| PERF-P3 — Unrealistic workload | PERF | At-least-three-presets requirement in plan |
| PERF-P4 — Stale committed output | PERF | SHA-pin doc-contract; CI fails on capture-path drift |
| PERF-P5 — `bench` in `ci.all` | PERF | `ci.all` alias diff review; CI topology contract |
| INCIDENT-P1 — SQL leaks redacted columns | INCIDENT | No-`SELECT *` doc-contract; live-join callout assertion |
| INCIDENT-P2 — `change_diff` shape confusion | INCIDENT | Each recipe has SQL + API + INSERT/UPDATE/DELETE coverage |
| INCIDENT-P3 — Replay mutates wrong DB | INCIDENT | Hard env + DB-name guards in script |
| INCIDENT-P4 — Recipes drift | INCIDENT | `incident_playbook_doc_contract_test.exs` |
| RELEASE-P1 — Undocumented `as_of/4` change | RELEASE | API surface diff step + CHANGELOG sections required |
| RELEASE-P2 — No upgrade narrative | RELEASE | `### Upgrade from 0.2.x` doc-contract |
| RELEASE-P3 — Version bump without rebuild | RELEASE | `mix verify.release` alias runs `hex.build` + `docs` |
| RELEASE-P4 — `:files` / `extras` drift | RELEASE | `release_artifact_contract_test.exs` |
| RELEASE-P5 — Tag before green CI | RELEASE | Runbook literal + Hex publish workflow guard |
| ADOPT-P1 — Quickstart skips `gen.triggers` | ADOPT | Doc-contract on literal command + Health verification |
| ADOPT-P2 — Quickstart drifts from example | ADOPT | Doc-contract pulls literals from example app source |
| ADOPT-P3 — STG column misread as endorsement | ADOPT | Generic placeholders + disclaimer assertion |
| ADOPT-P4 — Phoenix knowledge assumed | ADOPT | Prerequisites block + verification block doc-contract |
| CROSS-P1 — Missing `NN-VERIFICATION.md` | All five | Plan-checker + reviewer rule + milestone-audit grep |
| CROSS-P2 — Unstable CI job IDs | PERF / INCIDENT / ADOPT | `ci_topology_contract_test.exs` extended per new job |

---

## Sources

- `.planning/PROJECT.md` (Context: prior-art lessons; Constraints: Path B / PgBouncer)
- `.planning/research/sigra-integration-context.md` (locked architectural framing; six open questions)
- `.planning/seeds/SEED-001-sigra-integration-adapter.md` (locked framing reiterated)
- `prompts/threadline-elixir-oss-dna.md` §1 (verification entrypoints, stable CI job IDs, path filters + main), §2 (doc contracts), §3 (release gates), §4 (canonical host), §6 (milestone close + verification artifacts)
- `mix.exs:99-108` (current `:files` allowlist); `mix.exs:115-124` (current `extras` list)
- `guides/production-checklist.md` (existing checklist this milestone augments)
- `guides/adoption-pilot-backlog.md` (STG-01/02/03 rubric — context for ADOPT-02)
- v1.13 milestone audit (`v1.13-MILESTONE-AUDIT.md`) — Phase 43 retroactive verification artifact lesson (CROSS-P1)
- v1.6 STG-01 non-goal (no maintainer-attested third-party STG) — context for ADOPT-P3

---
*Pitfalls research for: Threadline v1.14 "Drop-in Production Adopter Slice"*
*Researched: 2026-04-25 — Confidence HIGH, grounded in shipped Threadline architecture and v1.14 milestone scope*
