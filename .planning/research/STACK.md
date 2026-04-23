# Stack Research

**Domain:** Elixir/Phoenix/Ecto audit platform (Hex library)
**Researched:** 2026-04-22
**Confidence:** HIGH for core runtime stack; MEDIUM for capture substrate (pending Phase 1 research gate)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir | ≥ 1.15 (target 1.17+) | Primary language | Project constraint; 1.17 is current stable with improved type system; 1.15 minimum aligns with Phoenix LTS |
| OTP | ≥ 26 | BEAM runtime | Project constraint; OTP 26 introduced stable process labels and improved Logger; OTP 27 adds native JSON module |
| PostgreSQL | ≥ 14 | Database; trigger host | Project constraint; PG 14 provides JSONB performance gains, logical replication improvements, and `pg_stat_io`; triggers are first-class and stable since PG 9 |
| Ecto | ~> 3.10 | DB abstraction, migration DSL, query API | Standard Phoenix/Ecto stack; `Ecto.Multi` is essential for atomic audit transaction wrapping; `Ecto.Repo` callbacks are how context propagation hooks in |
| Ecto SQL | ~> 3.10 | PostgreSQL SQL adapter | Companion to Ecto for raw SQL, migrations, and `explain`; ships with Ecto as of 3.x |
| Postgrex | ~> 0.17 | PostgreSQL wire protocol driver | Required by Ecto SQL for Postgres; handles JSONB natively as `map()` — no custom codec needed for audit data |

### Capture Substrate (Pending Phase 1 Research Gate)

This is the single most important open technology decision. Two viable paths exist:

**Path A — Build on Carbonite (leading candidate)**

| Library | Version | Purpose | Why Recommended |
|---------|---------|---------|-----------------|
| Carbonite | ~> 0.16 | Trigger-backed row capture | Best-maintained trigger library in Elixir ecosystem; covers INSERT/UPDATE/DELETE; ties changes to transaction records; supports `Ecto.Multi`, excluded/filtered columns, composite PKs, multiple audit schemas via `carbonite_prefix`, migration helpers, query helpers, and outbox abstraction. v0.16.x is current. |

Carbonite rough edges that Threadline fills:
- TRUNCATE is not captured (document, do not block v0.1)
- Metadata propagation is still app responsibility (Threadline's semantics layer owns this)
- Empty transactions can happen (expose in health checks)
- Outbox has ordering caveats (document clearly)

**Path B — Custom trigger infrastructure**

- Write migrations directly using Ecto migrations + raw PostgreSQL DDL
- No external capture dependency
- Full control, but Carbonite has already solved the hard parts (composite PKs, schema isolation, change table design)
- Only choose this path if Phase 1 research reveals Carbonite has a hard incompatibility

**Recommendation:** Default to Carbonite; confirm in Phase 1 research gate before locking architecture.

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Plug | ~> 1.14 | Request context propagation | Optional runtime dependency; provides `conn.assigns` integration for actor/request binding; any Phoenix app already has this |
| Phoenix | ~> 1.7 | Router and LiveView integration | Optional `dev` / `test` dep for integration testing only; Threadline is not a Phoenix app — do not make it a hard runtime dep |
| Oban | ~> 2.17 | Background job context integration | Optional integration; Threadline should detect Oban metadata at runtime if available, not hard-depend on it; Oban provides `Oban.Worker.init/1` and job args for correlation propagation |
| Jason | ~> 1.4 | JSONB encoding/decoding | Preferred JSON library across Phoenix ecosystem; Postgrex can use it for JSONB column codec; prefer over Poison which is deprecated |
| Telemetry | ~> 1.2 | Metrics, spans, observability hooks | Already included transitively via Phoenix/Ecto; Threadline should emit `:telemetry.execute/3` events for captures, actions, health checks — let adopters route to whatever backend they use |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| ExDoc | Generate Hex docs | Standard for Hex-published libraries; use `@moduledoc` / `@doc` / `@spec` throughout public API; configure `:extras` for guides |
| Credo | Static analysis / style | Use `--strict` flag per project DNA; config in `.credo.exs`; cite `mix verify.credo` in CI |
| ExCoveralls | Test coverage reporting | Optional but useful for tracking coverage gaps in capture and semantics layers; configure via `coveralls.json` |
| mix_test_watch | Test runner (dev only) | Quality-of-life for local development; do not include in CI |
| Postgrex (test) | Integration test database | Use a real PostgreSQL instance in CI — never mock the database for trigger/capture tests. Trigger behavior is DB-level; mocks will not catch DDL issues. |
| GitHub Actions | CI pipeline | Project standard; use `ubuntu-latest` + `services: postgres` pattern; pin action versions with SHA |

---

## Installation

```elixir
# mix.exs — runtime dependencies
defp deps do
  [
    {:ecto_sql, "~> 3.10"},
    {:postgrex, "~> 0.17"},
    {:jason, "~> 1.4"},
    {:telemetry, "~> 1.2"},

    # Capture substrate — pending Phase 1 research gate
    {:carbonite, "~> 0.16"},

    # Optional integrations — should be declared as optional: true
    {:plug, "~> 1.14", optional: true},

    # Dev/test
    {:ex_doc, "~> 0.34", only: :dev, runtime: false},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:excoveralls, "~> 0.18", only: :test}
  ]
end
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Carbonite (trigger-backed) | ExAudit (hook-based) | Never for Threadline — ExAudit uses ETS/PID-scoped context (ages poorly in async) and Erlang binary patch storage (opaque, fails SQL-native requirement) |
| Carbonite (trigger-backed) | PaperTrail for Elixir (explicit calls) | Never as primary capture — PaperTrail misses direct Repo/SQL writes; use it as inspiration for action-level ergonomics only |
| Carbonite (trigger-backed) | WAL/CDC (Debezium, Bemi) | Only if the project explicitly expands to polyglot/multi-DB scenarios in v1+ — WAL requires logical replication setup, PgBouncer hazards, and cloud caveats; incompatible with Threadline's "batteries-included" promise at v0.x |
| Jason | Poison | Never — Poison is deprecated ecosystem-wide; Jason is the standard |
| Real PostgreSQL in CI | Mocked Ecto sandbox | Never for trigger/capture tests — triggers execute at the DB level; Ecto sandbox can be used for semantics layer unit tests, but must not replace integration coverage of trigger behavior |
| Telemetry events | Custom callback system | Never — Telemetry is OTP-native and universal; adopters already know how to route it; custom callbacks create integration surface area |
| Plug optional dep | Hard Phoenix dep | Never — Threadline is a library, not a Phoenix app; making Phoenix a hard dep excludes non-Phoenix adopters |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| ETS / process dictionary for audit context | Context is lost across async boundaries (task, job, remote call); ExAudit proved this ages poorly | Explicit context threading or `Ecto.Multi` metadata attachment |
| Connection-local PostgreSQL variables (`SET LOCAL`) for metadata propagation without transaction guard | Misbehaves with PgBouncer in session/statement pool modes if transaction is skipped; Logidze documented this footgun | Trigger metadata via transaction-level variables inside a DB transaction; document PgBouncer requirements |
| YAML or Erlang binary term storage for audit data | YAML caused years of upgrade pain in Ruby Audited; Erlang binary terms require Elixir to decode; both fail SQL-native requirement | JSONB for flexible metadata; typed columns for queryable dimensions (actor_id, action, occurred_at) |
| Logical replication / WAL streaming as primary capture | Adds PgBouncer hazards, logical replication setup, cloud provider caveats; Neon documented wal_level change cannot be reverted | PostgreSQL triggers via Carbonite |
| Umbrella app structure at v0.1 | Premature split before API surface is known; adds compilation complexity and consumer confusion | Single `threadline` package; revisit after v0.1 validates API shape |
| pgAudit dependency | Statement-level DB auditing is a different product category; different buyers, different infrastructure | Trigger-backed application-level capture; document pgAudit as complementary, not competing |
| Association tracking in v0.1 | Ruby PaperTrail's association tracking bloated the core and was eventually extracted to a separate gem | Keep v0.1 to direct row mutations; add association patterns in v0.2+ |

---

## Stack Patterns by Variant

**If the host app uses PgBouncer in transaction pooling mode:**
- Trigger metadata propagation works correctly because it uses transaction-scoped state
- Verify: session pooling or connection-scoped `SET` calls must be inside a DB transaction
- Document: Threadline's capture layer must never rely on session-level `SET` outside a transaction

**If the host app uses Oban for background jobs:**
- Bind `AuditContext` via Oban worker `init/1` callback or metadata args
- Propagate `correlation_id` from parent request to job args at enqueue time
- Do not auto-detect via process inspection — make it explicit in the job module

**If the host app uses Phoenix LiveView:**
- LiveView does not use traditional `Plug.Conn`; actor binding must hook into socket assigns, not conn assigns
- Defer LiveView integration to v0.2+ after the Plug/HTTP path is stable

**If the host app uses multi-tenancy (Ecto prefix):**
- Carbonite supports `carbonite_prefix` for schema isolation
- Audit tables can live in a dedicated `audit` schema or be co-located with app tables per prefix
- Defer full multi-tenant pattern to after basic single-tenant capture is validated

**If the host app has strict write performance requirements:**
- PostgreSQL triggers add ~1-2ms overhead per write; document this honestly
- Filtered/excluded columns reduce trigger payload for high-throughput tables
- For high-volume tables, consider partition strategies early; document guidance in ops layer

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| Elixir 1.15 | OTP 24-26 | Minimum version; prefer 1.17+ for better type system primitives |
| Elixir 1.17 | OTP 26-27 | Current stable; OTP 27 adds native `JSON` module (useful for audit data encoding) |
| Ecto 3.10+ | Postgrex 0.17+ | Required for composite primary key support in `Ecto.Schema` |
| Carbonite 0.16.x | Ecto 3.x, PostgreSQL 14+ | Verify specific PostgreSQL version floor in Phase 1 |
| Phoenix 1.7.x | Ecto 3.x, Plug 1.14+ | Phoenix is an optional integration dep only; LTS baseline |
| Postgrex 0.17+ | Elixir 1.14+, OTP 24+ | JSONB maps natively without custom codec in 0.17+ |

---

## What the Stack Does NOT Own

These are integration points, not stack choices:

- **Authentication**: Threadline integrates with host auth (reads actor from `conn.assigns`, Oban args, etc.) but is not an auth library. Do not import Sigra or any auth library as a runtime dep.
- **Job queuing**: Oban is the most common queue in the Phoenix ecosystem; integration should be opt-in and detection-based.
- **LiveView**: Deferred to v0.2+; not in initial stack.
- **Admin UI**: Deferred; if added, it would be a separate `threadline_web` package or optional component.

---

## Sources

- Project `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — ecosystem analysis, Carbonite evaluation, prior art lessons (HIGH confidence — primary source)
- Project `prompts/audit-lib-domain-model-reference.md` — domain model, entity definitions, bounded contexts (HIGH confidence — primary source)
- Project `.planning/PROJECT.md` — constraints, decisions, out-of-scope boundaries (HIGH confidence — primary source)
- Project `prompts/threadline-elixir-oss-dna.md` — engineering quality bar, CI/testing patterns (HIGH confidence — primary source)
- Project `prompts/prior-art/oss-deep-research/elixir-best-practices-deep-research.md` — Elixir API design patterns (HIGH confidence — deep research artifact)
- Hex.pm Carbonite package — current version 0.16.x confirmed in ecosystem analysis doc (MEDIUM confidence — version may have advanced; verify in Phase 1)
- Elixir/Ecto ecosystem knowledge — Postgrex JSONB support, Phoenix LTS baseline, Oban prevalence (HIGH confidence — stable ecosystem facts)

---

## Open Questions for Phase 1 Research Gate

1. **Carbonite current version**: Confirm exact version and any breaking changes since 0.16.x
2. **Carbonite PostgreSQL floor**: Does Carbonite support PG 14+ cleanly, or does it require 15+?
3. **Carbonite trigger metadata mechanism**: Does it use `SET LOCAL` or a dedicated transaction row? This determines PgBouncer compatibility posture.
4. **Carbonite maintenance status**: Is the library actively maintained? Are there open PRs for known gaps (TRUNCATE, metadata propagation ergonomics)?
5. **Postgrex 0.18.x changes**: Any breaking changes relevant to JSONB handling?
6. **Elixir 1.18 release**: Has it shipped by April 2026? Any type system features relevant to Threadline's public API design?

---

*Stack research for: Threadline — Elixir audit platform for Phoenix/Ecto/PostgreSQL*
*Researched: 2026-04-22*
