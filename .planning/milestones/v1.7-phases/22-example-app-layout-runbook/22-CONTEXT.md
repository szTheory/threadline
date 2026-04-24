# Phase 22: Example app layout & runbook - Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **REF-01** and **REF-02**: a **non-published** Phoenix application under `examples/` that depends on **`threadline` via `:path`**, with a contributor runbook (Postgres, migrate, run, tests) **without** Hex publish; migrations reflect **`mix threadline.install`** (or equivalent checked-in migrations) and **`mix threadline.gen.triggers`** for **at least one** audited domain table; README documents the same **`MIX_ENV`** caveats as the root README for trigger regeneration.

**Explicitly later phases:** HTTP audited path (**REF-03**, Phase 23), Oban + `record_action/2` + adoption links (**REF-04**–**REF-06**, Phase 24). This context only locks layout, bootstrap, first-table choice, CI harness shape, and config minimalism so those phases plug in cleanly.

</domain>

<decisions>
## Implementation Decisions

### Naming, path, and OTP identity
- **D-01:** Canonical directory **`examples/threadline_phoenix/`** — matches **REF-01** wording in `.planning/milestones/v1.7-REQUIREMENTS.md`, signals Phoenix (the integration surface for v1.7), and avoids colliding with the **`:threadline`** OTP application at repo root.
- **D-02:** Example Mix project **`app: :threadline_phoenix`** with module namespace **`ThreadlinePhoenix`** (e.g. `ThreadlinePhoenix.Application`, `ThreadlinePhoenixWeb.Endpoint`). Do not name the example app `:threadline`.
- **D-03:** **`threadline_host`** remains a valid *documentation* term for “SaaS-shaped integrator app” but the **on-disk primary** example stays **`threadline_phoenix`** unless REQUIREMENTS and root README are deliberately renamed in the same change set (avoid glossary drift).

### Phoenix baseline (generator contract)
- **D-04:** Create the example with **`mix phx.new`** using an **API-lean, asset-free** flag set — **not** a hand-rolled minimal app and **not** the default browser/LiveView/asset kitchen sink. Rationale: integrators recognize standard Phoenix layout (Endpoint, Router, Ecto, supervision) while avoiding Node/esbuild/LiveView noise unrelated to audit capture; upgrades remain “regenerate throwaway with same flags, diff, port Threadline bits.”
- **D-05:** Document the **exact** `phx.new` invocation (app name, module, flags, Phoenix version) in the **example README** and a one-line pointer from **`examples/README.md`** so regeneration after Phoenix bumps is reproducible. Illustrative shape (adjust only if Phoenix task docs require changes): `--database postgres --adapter bandit --no-html --no-assets --no-mailer --no-dashboard --no-gettext` (keep **Ecto**; do **not** use `--no-ecto`).
- **D-06:** Revisit a fuller browser stack **only** if an in-repo operator UI becomes a product requirement; v1.7 reference work stays API-first.

### First audited domain table
- **D-07:** First (and initially only) **`mix threadline.gen.triggers`** target table: **`posts`**. Aligns with README examples (`users,posts,comments`) while scoping Phase 22 to a **single** boring domain table.
- **D-08:** Defer auditing **`users`** until HTTP/auth demos need it; never seed credential-like columns in the reference app. Use **neutral, synthetic** titles/slugs in seeds (avoid realistic PII and avoid gendered human fixtures unless identity is the lesson).
- **D-09:** Keep associations minimal for Phase 22 — avoid multi-table capture noise before **AuditTransaction** / **AuditChange** mental model is established. Copy in README should not conflate **ActorRef** with “the row being audited.”

### Contributor bootstrap and Postgres
- **D-10:** Primary onboarding is **Elixir-native**: define **`mix setup`** in the example as **`deps.get` → `compile` → `ecto.setup`** (or equivalent ordered aliases). **`mix setup` does not start Postgres** — it assumes a reachable server; state that explicitly to avoid silent “green setup, red server” confusion.
- **D-11:** **Do not** introduce **Makefile** or **`bin/setup`** as the primary path (Windows and shell portability tax). Optional **`bin/setup`** only if later paired with documented Windows/Git-Bash expectations — default remains Mix + README.
- **D-12:** **Docker Compose** stays an **optional appendix**, anchored at **repo root** `docker-compose.yml` and **`CONTRIBUTING.md`**: bless **`DB_HOST` / `DB_PORT`** (e.g. **`DB_PORT=5433`** when using the repo’s default Compose publish) and repeat the **three-line contract** in the example README: (1) where path dep points, (2) **from which directory** to run Compose vs `mix`, (3) **`mix ecto.migrate` / `mix phx.server` / tests** with env vars.
- **D-13:** If Compose uses **`depends_on`**, document or script **health wait** (`pg_isready`) so first `mix ecto.create` does not race the DB.

### CI and verification (Phases 22–24)
- **D-14:** Keep **one independent Mix project** under `examples/threadline_phoenix/` (**no umbrella** at root; matches `.planning/PROJECT.md` non-goals).
- **D-15:** Add root alias **`mix verify.example`** that runs, under **`MIX_ENV=test`**, from repo root: `cd examples/threadline_phoenix && mix deps.get && mix compile --warnings-as-errors && mix test` (extend with `ecto.create` / migrate if tests require a prepared DB — mirror what `CONTRIBUTING` documents for the library gate). Use a **dedicated test database name** for the example (e.g. **`threadline_phoenix_test`**) to avoid clashing with **`threadline_test`** used by the library harness.
- **D-16:** Fold **`verify.example`** into **`mix ci.all`** once the example exists so **`main` cannot rot** the reference app (honest default tests / OSS DNA). Extend **`test/threadline/*contract*.exs`** (or add a sibling contract test) if job lists or alias chains must stay machine-verified. **CI implementation detail:** prefer **reusing the existing Postgres service** in the **`verify-test`** job (create second DB in a prelude) over a third long-lived service **unless** job time limits force a follow-up optimization.
- **D-17:** If PR **path filters** are introduced later for cost, **never** skip **`verify.example`** on **`push` to `main`**; stable workflow **`id:`** fields stay immutable per project conventions.

### `config :threadline, :trigger_capture`
- **D-18:** Phase 22 example: **omit** `:trigger_capture` (implicit empty rules) — one linear story: install → migrate → `gen.triggers --tables posts` → run. Redaction teaching stays **documentation-linked** (`README.md`, `guides/domain-reference.md`, `guides/production-checklist.md`) not a second source of truth in `config/*.exs`.
- **D-19:** Any future optional redaction demo must pair **`mix threadline.gen.triggers --dry-run`** instructions with the **same `MIX_ENV` parity** callout as the root README (regeneration + migrate before relying on new SQL).

### Claude's Discretion

- Exact **`phx.new` flag spelling** if Phoenix minor releases rename options; keep README command audited against installed Phoenix.
- Optional **short “Advanced”** README subsection later (post–Phase 22) linking to redaction without adding live `:trigger_capture` until a requirement explicitly asks.
- Fine-tuning **when** `verify.example` joins `ci.all`** if the first green build proves materially slow — preference order: (1) optimize caches / second DB / test count, (2) then consider split alias, never silent omission from `main`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirements
- `.planning/milestones/v1.7-REQUIREMENTS.md` — **REF-01**, **REF-02** acceptance text; recommended `examples/threadline_phoenix/` path.
- `.planning/ROADMAP.md` — Phase 22 success criteria and v1.7 goal.
- `.planning/PROJECT.md` — v1.7 goals, non-goals (no umbrella, example-only integration).

### Runbooks and contributor flow
- `README.md` — `mix threadline.install`, `mix threadline.gen.triggers`, **`MIX_ENV`** caveat.
- `CONTRIBUTING.md` — `DB_HOST` / `DB_PORT`, Compose ports, **`MIX_ENV=test mix ci.all`**, PgBouncer topology jobs.
- `docker-compose.yml` — local Postgres (and pooler) topology for optional appendix.

### Operator and domain depth (links from example README, not duplicated behavior)
- `guides/production-checklist.md` — install + gen.triggers + `MIX_ENV` rows.
- `guides/domain-reference.md` — capture, redaction, retention, export semantics.
- `guides/adoption-pilot-backlog.md` — STG rubric (Phase 24 linking; mention only if README needs forward pointer).

### Engineering DNA
- `prompts/threadline-elixir-oss-dna.md` — named `mix verify.*` / `mix ci.*` entrypoints, honest default tests, CI job `id` stability, nested-app cache keys.

### Phoenix upstream (generator contract)
- HexDocs: `Mix.Tasks.Phx.New` for the **exact** supported Phoenix version — **must** match documented example generation command.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Root **`README.md`** — canonical install / `gen.triggers` / `MIX_ENV` wording to mirror or cross-link from the example README.
- **`docker-compose.yml`** + **`CONTRIBUTING.md`** — existing Postgres port story (`DB_PORT=5433` pattern); example docs should reference rather than fork.
- **`mix.exs`** aliases — today: `verify.format`, `verify.credo`, `verify.test`, `verify.threadline`, `verify.doc_contract`, `ci.all`; **`verify.example`** is the planned extension point.

### Established Patterns
- Library tests use **`MIX_ENV=test`** with **`config/test.exs`** database config — example should follow the same env discipline for `mix test` and trigger regeneration docs.
- Doc contract tests under **`test/threadline/`** — extend or add contracts when `ci.all` gains new steps.

### Integration Points
- **`examples/README.md`** — currently a placeholder; becomes the index pointing at **`threadline_phoenix/`**.
- **`.github/workflows/ci.yml`** — attach example verification to existing jobs/services per decisions **D-15**–**D-17**.

</code_context>

<specifics>
## Specific Ideas

- **`mix phx.new` command block** (flags as in **D-05**) is the regeneration contract — paste from Phoenix docs when implementing and keep in sync on upgrades.
- **Research synthesis (2026-04-23):** Parallel review covered Hex/OSS examples (e.g. `ex_audit` example dir pattern, Phoenix `installer/` CI, Hexpm’s second-tree integration), Rails `bin/setup` + dummy app, npm `examples/*`, and Go `_example` patterns — converged on **one canonical path-dep app**, **documented generator flags**, **Mix-first bootstrap**, **optional Compose**, and **CI that cannot silently ignore `examples/`**.

</specifics>

<deferred>
## Deferred Ideas

- **In-example redaction demo** (`:trigger_capture` with exclude/mask) — defer until a phase explicitly needs a live codegen policy demo; avoid teaching “config alone updates triggers.”
- **Rename to `threadline_host`** — only if REQUIREMENTS + root docs adopt “host” as the public folder name in one coordinated change.
- **Full LiveView + assets** in the reference app — only if product scope adds operator UI in-repo.
- **Umbrella / published `threadline_web`** — explicit non-goal for v1.7 per `PROJECT.md`.
- **Separate heavy CI job** vs folding into `verify-test` — optimize after first measured wall time; **D-16** prefers honest inclusion in `ci.all` first.

</deferred>

---

*Phase: 22-example-app-layout-runbook*  
*Context gathered: 2026-04-23*
