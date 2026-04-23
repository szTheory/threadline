# Phase 4: Documentation & Release - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 4 delivers a **Hex-releasable** `threadline` package and documentation that satisfy **DOC-01, DOC-02, DOC-03, DOC-05** and the roadmap success criteria: ≤15-minute README path to working capture, PgBouncer + safe GUC propagation called out, a domain reference defining the six named concepts, and complete public `@moduledoc` / `@doc` on the public API.

**Release automation boundary:** Phase work is **complete when the tree is verified releasable** (`mix ci.all`, `mix docs`, `mix hex.build` clean, metadata and files list correct). **`mix hex.publish` remains a deliberate human step** (Hex credentials, final eyeball on tarball/docs warnings). This matches high-trust Elixir OSS practice (Oban, Req, Ecto family): registry immutability favors a human at the publish boundary.

**Out of scope for this phase:** Running `mix hex.publish` in CI without human review; wiki-only docs; doc contract tests (**TOOL-03**, v2).

</domain>

<decisions>
## Implementation Decisions

### Release boundary, versioning, and package metadata

- **D-01 (publish boundary):** Treat **“Hex-ready”** as the phase exit: docs build, package builds, checklist satisfied. **Do not** automate `mix hex.publish` in this phase; the maintainer runs publish locally (or from a guarded manual workflow) after review.
- **D-02 (first Hex version):** Ship **first public Hex version as `0.1.0`** (plain semver), **not** `0.1.0-dev` as the default consumer target. Prereleases (`-rc.N`) are reserved for **opt-in** testers because `~>` constraints **exclude** prereleases unless pinned explicitly — poor default DX for an audit library that wants `{:threadline, "~> 0.1"}` to “just work.” During active development on `main`, **`mix.exs` may use `0.1.0-dev` or `0.2.0-dev`**, but **before** the first publish, bump to **`0.1.0`** (or cut **`0.1.0-rc.1`** deliberately if a public beta is intended).
- **D-03 (CHANGELOG):** Add **`CHANGELOG.md` before first publish** with at least an **“Initial release”** / `[0.1.0]` section (optionally `[Unreleased]` stub above). Cost is tiny; signal for integrators matches Ruby/npm infra library norms.
- **D-04 (LICENSE):** **`package/0` already declares `licenses: ["MIT"]` and lists `LICENSE` in `files`.** Create a **standard MIT `LICENSE`** file in the repo root if missing — required for trust and Hex metadata consistency.
- **D-05 (`:files` and missing paths):** Prefer **Hex-idiomatic globs** (e.g. `README*`, `LICENSE*`, `CHANGELOG*`) **or** ensure **every** explicitly listed path exists before `mix hex.build`. Today `README.md`, `LICENSE`, and `CHANGELOG.md` are referenced but absent — **fix in Phase 4** so `hex.build` never fails for missing paths.
- **D-06 (`docs :source_ref`):** Avoid **404 “View Source”** links on HexDocs. **Rule:** `source_ref` must point at a **ref that exists** on GitHub when docs are published. **Until `v0.1.0` (or chosen release tag) exists**, use **`source_ref: "main"`** (or the default branch name). **When tagging releases**, set `source_ref` to the **tag** (e.g. `"v0.1.0"`) for published versions so permalinks match the artifact. The pattern `source_ref: "v#{@version}"` is **unsafe** while `@version` is `"0.1.0-dev"` and no matching tag exists — **do not** ship docs to Hex with dangling refs.

### README vs HexDocs (landing and duplication)

- **D-07 (`main:` landing):** **Keep `main: "Threadline"`** (top-level module as HexDocs home). This matches **Ecto, Oban, NimblePool**-style libraries: API + orientation live beside module reference. **Do not** switch to `main: "readme"` unless README is intentionally the **only** curated overview **and** is listed in **`extras`** with discipline to keep GitHub-only noise out.
- **D-08 (README role):** **GitHub README** = short **front door**: value prop, requirements (Elixir/OTP/PostgreSQL), **install dep snippet**, **three-step** install path (install task → migrate → gen triggers), **one** minimal happy-path snippet (Plug + one write), **PgBouncer note** (short paragraph + link to `Threadline.Plug` and domain reference for GUC detail — avoids drift vs duplicated long SQL). **Prominent link:** “**Full documentation on HexDocs**” as canonical depth.
- **D-09 (anti-drift):** **Canonical home for long examples** = **`@doc` / `@moduledoc` (prefer doctest-backed where practical)** + **`guides/`**. README repeats **at most** install + minimal snippet; deeper examples **link** to HexDocs guides or module docs. **DOC-01** “under 15 minutes” = **total path** (README + linked first guide + copy-paste blocks), not README length alone.
- **D-10 (README file):** **Create `README.md`** — required for GitHub, Hex package files, and DOC-01; align examples with **`MyApp.Repo` / `users`** already used in query `@doc` examples for least surprise.

### Domain reference (`guides/domain-reference.md`)

- **D-11 (location):** Add **`guides/domain-reference.md`** and register it in **`docs/0` → `extras`**, grouped (e.g. **“Reference”** or **“Concepts”** via `groups_for_extras`). **Single consolidated file** for v0.1 — split into additional guides only when a topic exceeds ~1–2 screens (defer fragmentation until needed). **Do not** put primary vocabulary in ADR tone or wiki-only — ADRs are for **why** decisions; this guide is for **what each term means**.
- **D-12 (structure):** Order: short intro → **ubiquitous language table** (term → one sentence → tier: **persisted row / field on row / concept only**) → **one ASCII diagram** (` ```text ` fenced, spaces not tabs, avoid Unicode box-drawing) for AuditAction ↔ AuditTransaction ↔ AuditChange, with a **one-sentence prose invariant** under it (accessibility + search) → per-entity sections (**what it is / when created / what it is not / fields or pointers**) → short glossary.
- **D-13 (Correlation):** Open the **Correlation** subsection with an explicit **“not a database table”** statement: correlation is a **cross-cutting identifier** (`correlation_id`, headers, job args), same spirit as **trace context** in distributed systems docs — avoid implying a `correlations` schema or a `Threadline.Correlation` module unless one truly exists.
- **D-14 (README ↔ domain doc links):** README links to **relative path on GitHub** for browsing source and to **HexDocs** URL pattern for published docs (`hexdocs.pm/threadline/...`) so both audiences are served without maintaining two different bodies of text.

### ExDoc surface, `@moduledoc`, and module groups

- **D-15 (`@moduledoc false`):** Use on **true internals**: migration/SQL string emitters (`Threadline.Capture.Migration`, `Threadline.Semantics.Migration`, `Threadline.Capture.TriggerSQL`), and any codegen helpers **not** meant as semver-stable API. **Sidebar grouping does not hide modules** — only `@moduledoc false` removes them from the manual.
- **D-16 (schema modules):** Add **rich, operator-oriented `@moduledoc`** to **`Threadline.Capture.AuditTransaction`** and **`Threadline.Capture.AuditChange`**: role in capture, relationship to triggers/txid, **field semantics** (what operators query in SQL), links to install/gen-triggers and domain reference — **not** a raw duplicate of every `field` line. Aligns with how **`Oban.Job`** documents operational data.
- **D-17 (`@doc false`):** Keep **`@doc false`** on **internal `changeset/2`** and similar Ecto plumbing **not** intended as caller API (consistent with `AuditAction`). **Do not** hide functions that are semver-stable extension points.
- **D-18 (Plug):** **`Threadline.Plug`**: **`@moduledoc` carries usage**; **`@impl Plug`** callbacks need **no** separate `@doc` unless plug-specific options need documentation beyond `Plug` behaviour docs.
- **D-19 (`groups_for_modules`):** Configure **Core API** (`Threadline`, `Threadline.Semantics.ActorRef`, `Threadline.Semantics.AuditContext`), **Integration** (`Threadline.Plug`, `Threadline.Job`, `Threadline.Health`, `Threadline.Telemetry`), **Schemas** (`Threadline.Semantics.AuditAction`, `Threadline.Capture.AuditTransaction`, `Threadline.Capture.AuditChange`), **Mix tasks** (`Mix.Tasks.Threadline.Install`, `Mix.Tasks.Threadline.Gen.Triggers`). Keep **top-level narrative** strong in **`Threadline`’s `@moduledoc`** (per D-07). **Do not** set **`api_reference: false`** — operators benefit from **schema-first API reference** alongside guides (unlike Oban’s narrative-first choice, which is a poor fit for SQL-savvy audit users).
- **D-20 (`extras`):** Include **`guides/domain-reference.md`** and **`CONTRIBUTING.md`** in `extras`; optionally **`CHANGELOG.md`** as an extra for HexDocs sidebar parity with common Elixir libs.

### Plan split (unchanged engineering order)

- **D-21:** **04-01** — README + `guides/domain-reference.md` + PgBouncer/DOC-03 alignment + link hygiene. **04-02** — `@moduledoc`/`@doc` audit (DOC-05), ExDoc config (`extras`, `groups_for_modules`, `groups_for_extras`, `source_ref` policy), `mix.exs` package files/version, add missing **`LICENSE`** / **`CHANGELOG.md`** / **`README.md`**, verify **`mix hex.build`** and **`mix docs`**.

### Claude's Discretion

Exact ExDoc sidebar labels, whether `CHANGELOG.md` is both root file and extra only vs duplicated title in groups, minor wording in README badges, and doctest depth per function — **planner/executor** within the constraints above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product and requirements

- `.planning/ROADMAP.md` — Phase 4 goal, success criteria, requirements IDs.
- `.planning/REQUIREMENTS.md` — **DOC-01** through **DOC-05** (acceptance text).
- `.planning/PROJECT.md` — vision, OSS quality bar, PgBouncer / capture constraints.

### Capture and semantics decisions (docs must not contradict)

- `.planning/phases/01-capture-foundation/gate-01-01.md` — Path B, PgBouncer-safe capture rationale.
- `.planning/phases/01-capture-foundation/01-CONTEXT.md` — install/gen-triggers patterns, schema evolution notes.
- `.planning/phases/02-semantics-layer/02-CONTEXT.md` — GUC bridge (CTX-03), `ActorRef` JSON shape, public API patterns.
- `.planning/phases/03-query-observability/03-CONTEXT.md` — query API shapes, `repo:` requirement, example naming.

### Repository conventions

- `CLAUDE.md` — architecture vocabulary for module grouping and prose.
- `mix.exs` — current `package/0`, `docs/0`, `@version`, dependencies (source of truth for release metadata work).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- `lib/threadline/plug.ex` — **canonical** PgBouncer + `set_config(..., true)` narrative; README should **link** here rather than duplicating full SQL.
- `lib/threadline/job.ex`, `lib/threadline/query.ex`, `lib/threadline/telemetry.ex`, `lib/threadline/health.ex` — established **@moduledoc** patterns and **MyApp.Repo** examples to mirror in README.
- `lib/threadline/capture/audit_transaction.ex`, `lib/threadline/capture/audit_change.ex` — **missing `@moduledoc`** today; primary DOC-05 gap for schema modules.

### Established patterns

- **`repo:` explicit** on public APIs — README and guides must **not** imply implicit repo from config.
- **`@doc false` on changesets** — already used on schemas; keep consistent for internal Ecto surface.

### Integration points

- `mix.exs` — `docs/0` already includes `ex_doc`; extend with `extras`, groups, and **safe `source_ref`** policy per **D-06**.
- `package/0` — lists files that **must exist** before publish (**D-04, D-05**).

</code_context>

<specifics>
## Specific Ideas

- **Subagent research synthesis (2026-04-22):** Cross-checked Elixir/Hex idioms (semver, prerelease resolution, `source_ref` footguns), README vs HexDocs patterns (Ecto, Phoenix, Oban, NimblePool), domain-doc placement (Ecto guides, Ash domains, Commanded vocabulary), and ExDoc hiding vs grouping (`@moduledoc false` vs sidebar-only “internal” groups). Recommendations above are chosen for **coherence**: thin README + strong `Threadline` landing + guides + schema-first API reference + human-gated publish + non-prerelease first release.

</specifics>

<deferred>
## Deferred Ideas

- **TOOL-03** (README/doc contract tests, doctest CI for markdown blocks) — v2; optional note in CONTRIBUTING as future contribution.
- **Automated `mix hex.publish` on tag** — defer until project maturity and key management story exist.
- **CHANGELOG beyond initial stub** — grow with releases post-0.1.0.

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches for phase 04.

</deferred>

---

*Phase: 04-documentation-release*
*Context gathered: 2026-04-22*
