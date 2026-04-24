# Phase 22 — Research: Example app layout & runbook

**Purpose:** Answer “What do I need to know to PLAN this phase well?” for implementing **REF-01** and **REF-02** (see `.planning/REQUIREMENTS.md`). Locked decisions **D-01–D-19** live in `.planning/phases/22-example-app-layout-runbook/22-CONTEXT.md`.

---

## 1. Executive summary (what to build)

Phase 22 delivers a **single canonical Mix project** at **`examples/threadline_phoenix/`** (`app: :threadline_phoenix`, namespace **`ThreadlinePhoenix`**) that:

- Depends on **`threadline` via `:path`** pointing at the **repo root** (not Hex), satisfying **REF-01**.
- Uses a **standard `mix phx.new` layout** (API-lean, no HTML/assets/mailer/dashboard/gettext per **D-04–D-06**) so upgrades stay “regenerate with same flags, diff, port Threadline bits.”
- Ships a minimal **`posts`** domain table (**D-07**), **`mix threadline.install`**-generated (or equivalent **checked-in**) migrations, and **`mix threadline.gen.triggers --tables posts`** (**REF-02**), without live **`config :threadline, :trigger_capture`** in the example (**D-18**).
- Documents **Postgres-first bootstrap** (`mix setup` = deps → compile → `ecto.setup`), **no Makefile / `bin/setup` as primary** (**D-10–D-11**), optional **root `docker-compose.yml` + `DB_HOST` / `DB_PORT`** appendix aligned with **`CONTRIBUTING.md`** (**D-12–D-13**).
- Adds root **`mix verify.example`** and folds it into **`mix ci.all`** so **`main` cannot rot** the example (**D-15–D-16**, **`prompts/threadline-elixir-oss-dna.md`** §1 / §4).

Update **`examples/README.md`** (currently states there is no in-tree Phoenix sample; see `examples/README.md` lines 1–3) to index **`threadline_phoenix/`** and point at the **exact documented `phx.new` invocation** in the example README (**D-05**).

---

## 2. Technical approach

### 2.1 `mix phx.new` flags and versioning

**Target shape (from 22-CONTEXT D-05):** API-first Phoenix with Ecto, Bandit, no front-end kitchen sink:

```bash
mix phx.new threadline_phoenix --module ThreadlinePhoenix \
  --database postgres --adapter bandit \
  --no-html --no-assets --no-mailer --no-dashboard --no-gettext
```

**Planning must verify** against the **installed Phoenix** on CI (Elixir **1.17.3** / OTP **27.0** per `.github/workflows/ci.yml`): HexDocs **`Mix.Tasks.Phx.New`** for the Phoenix version you add to **`examples/threadline_phoenix/mix.exs`** — flag names drift across minors (**D-05**, **Claude’s discretion** in context).

**Placement:** Generate **inside** `examples/threadline_phoenix/` (or generate elsewhere and move) so the repo path matches **REF-01** / **D-01**. Do **not** create an umbrella at repo root (**D-14**, `.planning/PROJECT.md` non-goals referenced in context).

### 2.2 Path dependency to parent `threadline`

In **`examples/threadline_phoenix/mix.exs`**, depend on the library with a **relative path to repo root**:

```elixir
{:threadline, path: "../.."}
```

(Adjust only if the example directory depth differs; canonical path is **`examples/threadline_phoenix/`** → **`../..`** reaches root.)

**OTP naming:** Example app **`:threadline_phoenix`**, not **`:threadline`** (**D-02**), to avoid clashing with the package app at root.

### 2.3 `posts` schema and migrations

- Add a boring **`posts`** table migration (title/slug or similar) with **neutral synthetic seeds** (**D-08–D-09**): no credential-like columns, minimal associations.
- Run **`mix threadline.install`** from **`examples/threadline_phoenix/`** so migrations land under that app’s **`priv/.../migrations/`**. The task resolves the path via **`Mix.Project.config()` → `:ecto_repos` → repo `priv`** (see `lib/mix/tasks/threadline.install.ex` `migrations_path/0`).
- **`mix threadline.install`** emits **two** migration files when absent (`*_threadline_audit_schema.exs`, `*_threadline_semantics_schema.exs`) and instructs **`mix ecto.migrate`** — it does **not** run migrate for you (`lib/mix/tasks/threadline.install.ex` `@moduledoc`).
- Then **`mix threadline.gen.triggers --tables posts`** and **`mix ecto.migrate`** again as in root **`README.md`** (lines 36–40).

### 2.4 `MIX_ENV` parity for trigger regeneration

Root **`README.md`** (lines 52–54) states that **`mix threadline.gen.triggers`** runs **`Mix.Task.run("app.config", [])`**, so **use the same `MIX_ENV`** when regenerating. The **example README** must **repeat this caveat** for **REF-02** (same intent as root README, not necessarily verbatim paste).

### 2.5 `mix setup` alias (example app)

Per **D-10**, define in the **example** `mix.exs` something equivalent to:

```elixir
setup: ["deps.get", "compile", "ecto.setup"]
```

Document explicitly: **`mix setup` does not start Postgres** — contributor must have a reachable server (mirrors the honesty of **`CONTRIBUTING.md`** setup narrative).

### 2.6 Test database: `threadline_phoenix_test`

**D-15** requires a **dedicated test DB** (e.g. **`threadline_phoenix_test`**) so example tests never collide with the library’s **`threadline_test`** (`config/test.exs` line 10).

**Pattern to copy:** Root **`test/test_helper.exs`** uses **`Ecto.Adapters.Postgres.storage_up/1`** then **`Ecto.Migrator.run(..., :up, all: true)`** for **`Threadline.Test.Repo`**. The example app should either:

- Use the same **storage_up + migrate** pattern in **`test/test_helper.exs`** against **`threadline_phoenix_test`**, or  
- Rely on explicit **`ecto.create`** in **`verify.example`** / CI prelude **plus** migrations — but then **document** the two modes (local vs CI) to avoid “green compile, red DB.”

**CI note:** `.github/workflows/ci.yml` **`verify-test`** service sets **`POSTGRES_DB: threadline_test`** only (lines 56–64). Creating **`threadline_phoenix_test`** requires a **`psql`/`createdb` step** (or `mix ecto.create` with `DATABASE_URL`) **before** `mix verify.example` — align with **D-16** (“create second DB in a prelude”).

---

## 3. CI integration

### 3.1 `verify.example` alias shape (root `mix.exs`)

**From D-15**, the root alias should run under **`MIX_ENV=test`** from **repo root**, conceptually:

```bash
cd examples/threadline_phoenix && mix deps.get && mix compile --warnings-as-errors && mix test
```

Extend with **`ecto.create`** / migrate when the example’s tests need a prepared DB (same discipline as **`CONTRIBUTING.md`** for the library gate: Postgres required, env for host/port).

**`mix.exs` today** (`mix.exs` lines 59–75): aliases include **`verify.format`**, **`verify.credo`**, **`verify.test`**, **`verify.threadline`**, **`verify.doc_contract`**, and **`ci.all`** — **`verify.example`** is the natural extension (**22-CONTEXT** code insights).

**`preferred_envs`:** Root `cli/0` already pins **`ci.all`** to **`:test`** (`mix.exs` lines 7–16). When adding **`verify.example`**, decide whether it must be invoked only inside **`ci.all`** (inherits `:test`) or needs its own **`preferred_envs`** entry if called standalone.

### 3.2 Folding into `mix ci.all`

**D-16:** Append **`verify.example`** to **`ci.all`** after the library is green — typical order: keep **format → credo → compile → library tests → threadline → doc_contract**, then **`verify.example`** (nested app deps/compile/test), **or** insert **`verify.example`** immediately after **`verify.test`** if you want failures closer to “integration surface.” Document the chosen order in the phase plan.

**OSS DNA:** `prompts/threadline-elixir-oss-dna.md` §1 and §4 — **one flat alias** contributors and CI cite verbatim; **separate cache keys** for nested `_build`/`deps` if GitHub Actions caches deps (avoid reusing root cache paths for the example tree).

### 3.3 `.github/workflows/ci.yml`

- **D-16–D-17:** Prefer **reusing the existing `postgres` service** in **`verify-test`** over a third service; add a step to **create `threadline_phoenix_test`** and run **`mix verify.example`** (or run the same shell as the alias).
- **Stable job `id:`** values must stay **`verify-format`**, **`verify-credo`**, **`verify-test`**, etc. (header comment in `ci.yml` lines 1–2; **`test/threadline/phase06_nyquist_ci_contract_test.exs`** greps these keys).
- **Postgres readiness:** The **`verify-test`** service already uses **`pg_isready`** health options (`ci.yml` lines 65–69). **D-13** still matters for **local Compose**: document **`pg_isready`** / “wait until healthy” so **`mix ecto.create` does not race** cold containers.

### 3.4 Doc contract tests

- **`mix verify.doc_contract`** runs **`test/threadline/readme_doc_contract_test.exs`** (`mix.exs` line 65).
- **`test/threadline/phase06_nyquist_ci_contract_test.exs`** asserts **`ci.all`** includes an ordered list of steps (**`verify.test`** before **`verify.threadline`** before **`verify.doc_contract`**, lines 32–56). **Adding `verify.example` requires updating this contract** (or a sibling test) so **`main` cannot silently drop** the example from the alias chain.
- **Dual-contract (DNA §2):** Consider assertions that **`examples/README.md`** links to **`examples/threadline_phoenix/`** and that the example README contains **`mix threadline.install`**, **`mix threadline.gen.triggers`**, **`MIX_ENV`**, and the **`phx.new`** block — keeps **REF-01 / REF-02** prose from drifting.

---

## 4. Risks / pitfalls

| Risk | Mitigation |
|------|------------|
| **Phoenix / `phx.new` flag drift** | Pin Phoenix version in example `mix.exs`; README command audited against **`Mix.Tasks.Phx.New`**; re-run contract grep after upgrades (**D-05**). |
| **`ecto.create` vs Postgres readiness** | CI: rely on service health + optional explicit `pg_isready` loop (see **`verify-pgbouncer-topology`** step “Wait for Postgres”, `ci.yml` lines 131–138). Local: **`docker compose ps`** / health (**`CONTRIBUTING.md`** lines 17–21, **D-13**). |
| **DB name collision** | Use **`threadline_phoenix_test`** only for the example; library stays on **`threadline_test`** (**D-15**, `config/test.exs`). |
| **Mix task cwd** | `mix threadline.install` / `gen.triggers` use **`Mix.Project`** of the **current app** — always document **running from `examples/threadline_phoenix/`** (**D-12** three-line contract). |
| **Nested `_build` / deps cache pollution** | DNA: separate CI cache paths for **`examples/threadline_phoenix/deps`** and **`_build`**. |
| **Path filters (future)** | **Never skip `verify.example` on `push` to `main`** (**D-17**). |
| **Implying redaction from config** | Omit **`:trigger_capture`** in example config (**D-18**); link to **`README.md`** / **`guides/domain-reference.md`** for redaction semantics. |

---

## Validation Architecture

### Test stack (ExUnit / Mix)

- **Library:** Full **`mix test`** on PostgreSQL with real triggers; **`test/test_helper.exs`** ensures DB exists and runs migrations (except PgBouncer topology mode).
- **Example:** Standard **Phoenix + Ecto** tests under **`examples/threadline_phoenix/test/`** — plan the **minimum** tests for Phase 22 (e.g. Repo connectivity, migration applied, optional smoke insert into **`posts`**). Heavy HTTP/Oban coverage belongs to **REF-03–REF-06** (Phases 23–24 per **`REQUIREMENTS.md`** traceability table).

### Commands: quick verify vs full `ci.all`

| Intent | Command (from repo root unless noted) |
|--------|----------------------------------------|
| Library quick test | `mix verify.test` (needs Postgres; **`CONTRIBUTING.md`** lines 41–44) |
| Library full local gate | `MIX_ENV=test mix ci.all` or `DB_PORT=5433 mix ci.all` (**`CONTRIBUTING.md`** lines 29–37) |
| After Phase 22 | Same, plus nested **`verify.example`** inside **`ci.all`** — reproduce with documented env for second DB |
| CI parity | **`.github/workflows/ci.yml`** job **`verify-test`** runs `mix compile --warnings-as-errors`, `mix verify.test`, `mix verify.threadline`, `mix verify.doc_contract` (lines 81–91); extend with **`mix verify.example`** prelude + command per plan |

### Sampling strategy (after tasks / waves)

- After any change to **`mix.exs` aliases**, **`ci.yml`**, or **`examples/`** tree: run **`MIX_ENV=test mix ci.all`** locally with Postgres (or at minimum **`mix verify.example`** + **`mix verify.doc_contract`**).
- Run **`mix test test/threadline/phase06_nyquist_ci_contract_test.exs`** whenever **`ci.all`** or **`ci.yml`** job keys change.
- When touching README / examples docs: run **`mix verify.doc_contract`** (and extend contract tests if new anchors are added).

### Mapping verification to **REF-01** and **REF-02**

| Requirement | What “done” looks like in verification |
|-------------|----------------------------------------|
| **REF-01** | Path **`examples/threadline_phoenix/`** exists; **`mix.exs`** has **`{:threadline, path: "…"}`** to repo root; README covers prerequisites, **`mix setup`**, server, tests; **`mix verify.example`** + **`ci.all`** + CI step prove it stays buildable. |
| **REF-02** | Migrations in-repo reflect **`mix threadline.install`** + **`mix threadline.gen.triggers --tables posts`** workflow; README documents **`MIX_ENV`** for regeneration (root **`README.md`** lines 52–54 as canonical technical source); doc contract tests can grep example README for **`MIX_ENV`** + task names. |

## RESEARCH COMPLETE
