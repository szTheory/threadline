# RESEARCH.md — Phase 4: Documentation & Release

**Phase:** 4 — Documentation & Release
**Generated:** 2026-04-22
**Status:** RESEARCH COMPLETE

---

## Summary

Phase 4 delivers: README, domain reference guide, @moduledoc gaps, ExDoc configuration, and Hex publish readiness. The codebase is already well-documented at the function level — two schema modules lack @moduledoc, and the ExDoc config is minimal. No source files exist (README.md, guides/, LICENSE). All public APIs have @doc with examples; content reuse is high.

---

## 1. Current Documentation State

### README.md
**Confidence: HIGH**

`README.md` does not exist. Must be created from scratch.

Required content (per CONTEXT.md D-02):
- Badges (CI, Hex version, HexDocs)
- "What is Threadline" — one paragraph
- Installation — 3 steps: add dep, `mix threadline.install`, `mix threadline.gen.triggers`
- Quick Start — Plug config + `record_action/2` call
- PgBouncer constraint note (3–5 sentences; link to `Threadline.Plug` @moduledoc for full example)
- Domain reference link
- Contributing link

Constraint: developer has working audit capture in ≤ 15 minutes.

### guides/domain-reference.md
**Confidence: HIGH**

`guides/` directory does not exist. Must be created.

Required structure (per CONTEXT.md D-06):
1. Intro — what Threadline captures and why entities are separate
2. Six entities: AuditTransaction, AuditChange, AuditAction, AuditContext, ActorRef, Correlation
3. ASCII layer diagram (capture → semantics → query)
4. Glossary (short term definitions)

Source material: `prompts/audit-lib-domain-model-reference.md` is the canonical domain model reference (1.6 MB). Distill from it; do not copy wholesale.

### LICENSE
**Confidence: HIGH**

Does not exist. Standard MIT license. Must be created before Hex publish.

---

## 2. @moduledoc / @doc Coverage Audit

**Confidence: HIGH** (verified by reading all 16 lib/*.ex files)

### Missing @moduledoc — must add

| Module | Gap |
|--------|-----|
| `Threadline.Capture.AuditTransaction` | No @moduledoc at all |
| `Threadline.Capture.AuditChange` | No @moduledoc at all |

Both are Ecto schema modules. @moduledoc should explain: what the entity represents in the domain, its key fields, relationship to sibling entities, and when records are created.

### @moduledoc present — HIGH quality

All other public modules have @moduledoc. Quality verified as HIGH for:
- `Threadline` — root API with three-layer description
- `Threadline.Query` — query API with DB error handling notes
- `Threadline.Plug` — comprehensive: PgBouncer note, GUC bridge, usage pattern
- `Threadline.Job` — context propagation, enqueue pattern
- `Threadline.Health` — trigger coverage detection
- `Threadline.Telemetry` — all 3 events with measurement shapes
- `Threadline.Semantics.ActorRef` — actor types, constructors, serialization
- `Threadline.Semantics.AuditContext` — field documentation
- `Threadline.Capture.TriggerSQL` — PL/pgSQL, PgBouncer safety, GUC reading
- `Mix.Tasks.Threadline.Install` — generated migration files
- `Mix.Tasks.Threadline.Gen.Triggers` — usage, options, recursive-trigger guard

### @moduledoc MEDIUM quality — consider enriching

| Module | Current State | Recommendation |
|--------|--------------|----------------|
| `Threadline.Semantics.AuditAction` | Present but minimal | Add: name convention examples, category/verb examples |
| `Threadline.Semantics.Migration` | "DDL helpers for Phase 2" | Adequate as-is; internal helper |
| `Threadline.Capture.Migration` | "used by mix threadline.install" | Adequate as-is; internal helper |

### @doc on public functions — HIGH coverage

All public functions have @doc with examples using `MyApp.Repo` and `users` table:
- `Threadline.record_action/2` — options, returns, errors documented
- `Threadline.history/3`, `actor_history/2`, `timeline/2` — delegate to Query with @doc
- All three `Threadline.Query` functions — @doc with examples

Internal changesets are correctly marked `@doc false` (AuditTransaction, AuditChange, AuditAction).

Plug callbacks (`init/2`, `call/2`) are `@impl Plug` — no explicit @doc needed; behavior links handle this.

---

## 3. ExDoc Configuration

**Confidence: HIGH**

### Current state (mix.exs)

```elixir
defp docs do
  [
    main: "Threadline",
    source_ref: "v#{@version}",
    source_url: @source_url
  ]
end
```

Minimal — no extras, no module grouping, landing page is the root module not the README.

### Required changes

```elixir
defp docs do
  [
    main: "readme",
    source_ref: "v#{@version}",
    source_url: @source_url,
    extras: [
      "README.md",
      "guides/domain-reference.md",
      "CONTRIBUTING.md"
    ],
    groups_for_modules: [
      "Core API": [
        Threadline,
        Threadline.Semantics.ActorRef,
        Threadline.Semantics.AuditContext
      ],
      Integration: [
        Threadline.Plug,
        Threadline.Job,
        Threadline.Health,
        Threadline.Telemetry
      ],
      Schemas: [
        Threadline.Semantics.AuditAction,
        Threadline.Capture.AuditTransaction,
        Threadline.Capture.AuditChange
      ],
      "Mix Tasks": [
        Mix.Tasks.Threadline.Install,
        Mix.Tasks.Threadline.Gen.Triggers
      ]
    ]
  ]
end
```

ExDoc dep is already present: `{:ex_doc, "~> 0.34", only: :dev, runtime: false}`.

---

## 4. Hex Package Metadata

**Confidence: HIGH**

### Current state (mix.exs package/0)

```elixir
defp package do
  [
    licenses: ["MIT"],
    links: %{"GitHub" => @source_url},
    files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md)
  ]
end
```

### Issues

| Aspect | Issue |
|--------|-------|
| `README.md` in files list | File doesn't exist yet; will be created |
| `LICENSE` in files list | File doesn't exist yet; must be created |
| `CHANGELOG.md` in files list | File doesn't exist; deferred — remove from list or create stub |
| `guides/` not in files list | Must add `"guides"` to include domain-reference.md |
| Links | Only GitHub; `HexDocs` link added automatically by Hex after publish |

### Required change to files list

```elixir
files: ~w(lib guides .formatter.exs mix.exs README.md LICENSE CONTRIBUTING.md)
```

Note: CHANGELOG.md omitted until created. Can add back when it exists.

---

## 5. Standard Patterns & Pitfalls

**Confidence: HIGH** (from OSS Elixir ecosystem knowledge)

### ExDoc best practices

- `main: "readme"` makes README the landing page on HexDocs — standard for user-facing libraries
- `extras:` must include `"README.md"` explicitly (not just setting main)
- Module groups appear in sidebar; group names are strings or atoms — use strings for multi-word
- `@moduledoc false` hides internal modules from ExDoc sidebar — useful for Migration/TriggerSQL if desired, but these currently have public @moduledoc so leaving them public is defensible
- `mix docs` generates into `doc/` directory; add `doc/` to `.gitignore` if not already present

### README conventions for Hex libraries

- Badges: `[![Hex.pm](https://img.shields.io/hexpm/v/threadline.svg)](https://hex.pm/packages/threadline)` pattern
- Installation block always shows `{:threadline, "~> 0.1"}` (without `-dev` suffix)
- Quick start must be copy-pasteable — use placeholder values explicitly labeled
- PgBouncer note: mention transaction mode pooling; say Threadline uses `set_config(..., true)` which is transaction-scoped safe

### Hex publish readiness checklist

- [ ] README.md exists and is in files list
- [ ] LICENSE exists and is in files list
- [ ] Version is not `-dev` suffixed (or publish as pre-release)
- [ ] `mix hex.build` passes with no warnings
- [ ] `mix docs` generates without errors
- [ ] Description is ≤ 300 characters (current: "Audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL" — fine)

**Version note (D-14):** Phase 4 does not bump the version. `0.1.0-dev` will need to become `0.1.0` before actual `mix hex.publish`. That is a one-line change in mix.exs; the decision on when to do it is out of Phase 4 scope.

---

## 6. Content Reuse Map

**Confidence: HIGH**

These assets exist in the codebase and should be referenced/quoted, not rewritten:

| Asset | Location | Use In |
|-------|----------|--------|
| PgBouncer + GUC explanation | `Threadline.Plug` @moduledoc lines 2–50 | README brief note → links here |
| Oban context pattern | `Threadline.Job` @moduledoc | domain-reference.md can link |
| Telemetry event list | `Threadline.Telemetry` @moduledoc | domain-reference.md Correlation section |
| Query API examples | `Threadline.Query` @doc | README Quick Start (must match exactly) |
| 15-min install pattern | CONTRIBUTING.md | README Installation section |
| Actor type list | `Threadline.Semantics.ActorRef` @moduledoc | domain-reference.md ActorRef entity |
| Domain entity definitions | `prompts/audit-lib-domain-model-reference.md` | guides/domain-reference.md (distill) |

README examples MUST use `MyApp.Repo` and `users` table for consistency with existing @doc examples (D-03).

---

## 7. Plan Structure Recommendation

**Confidence: HIGH** (directly from CONTEXT.md D-01)

Split into two plans:

### 04-01: README + Domain Reference

Deliverables:
1. `README.md` — badges, what, install, quick start, PgBouncer note, links
2. `guides/domain-reference.md` — 6 entities, layer diagram, glossary
3. `LICENSE` — MIT

Success criteria:
- `mix docs` generates without errors and guide page renders
- README installation steps work (smoke test mentally or in sandbox)

### 04-02: @moduledoc + ExDoc + Hex Readiness

Deliverables:
1. `@moduledoc` for `AuditTransaction` and `AuditChange`
2. `mix.exs` docs() — extras, main, groups_for_modules
3. `mix.exs` package() — files list updated
4. `mix docs` clean output verified
5. `mix hex.build` passes (pre-publish validation)

Success criteria:
- All public modules have @moduledoc
- `mix docs` produces correct sidebar grouping
- `mix hex.build` exits 0 with no warnings
- DOC-01 through DOC-05 requirements all satisfied

---

## 8. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| README examples don't match actual API | LOW | HIGH | Copy from existing @doc examples verbatim |
| `mix hex.build` fails on missing files | MEDIUM | MEDIUM | Verify files list matches what exists on disk |
| ExDoc `groups_for_modules` module names wrong | LOW | LOW | Run `mix docs` and check output |
| Version `-dev` suffix blocks Hex publish | LOW | LOW | Noted in D-14; not Phase 4 scope |
| domain-reference.md too long / too short | MEDIUM | LOW | Target 500–900 words; entity definitions + diagram + glossary |

---

## 9. Open Questions

None blocking. All decisions captured in CONTEXT.md.

CONTEXT.md decisions D-01 through D-14 are all approved. No ambiguity remains for planning.
