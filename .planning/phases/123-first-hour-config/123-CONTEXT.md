# Phase 123: First-Hour Config - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Adopters discover `config :threadline, ecto_repos: [MyApp.Repo]` on day one — before any Mix task or operator-surface fallback fails with an opaque repo resolution error. Covers CFG-01 (getting-started Base install), CFG-02 (doc-contract lock), CFG-03 (production-checklist cross-link). Does **not** scope §6 auth neutrality, ADOPT-AUTH strict literals, `:schemas` mount docs, or evidence host-write (Phase 124).

</domain>

<decisions>
## Implementation Decisions

### Getting-started placement (CFG-01)

- **D-01:** Add a dedicated subsection **`### Configure Threadline`** immediately after **§2 Add Threadline** (`mix deps.get`) and **before §3 Install the audit schema** — do **not** bury config at §7 or defer to first `resolve_repo!/0` failure.
- **D-02:** Rationale for placement: ROADMAP “discover on day one”; `mix threadline.install` (§3) uses **host** `config :my_app, ecto_repos` and succeeds without `:threadline` config — adopters must learn the **dual-key split** before §3–§6, not at §7.
- **D-03:** **Reject** Option C (just-before-§7): §8 fallback bullets, production-checklist §1 mix tasks, and operator-surface fallbacks all need `:threadline, :ecto_repos` before §7 in real adopter paths.

### Rationale depth (CFG-01 prose)

- **D-04:** **Option C pattern** — brief getting-started (2 sentences max) + ops depth in production-checklist; **reject** full §7–§9 task enumeration in getting-started (§8 already owns mix-task parity narrative; checklist owns exhaustive inventory).
- **D-05:** Getting-started must explicitly name **`config :threadline, :ecto_repos`** — not vague “your Repo” — because adopters already have `config :my_app, ecto_repos` and assume it suffices (example app sets **both**).
- **D-06:** Prose shape (locked intent, planner may polish wording):
  1. Threadline Mix tasks and operator-surface fallbacks resolve repo from **`config :threadline, :ecto_repos`**, not host `:ecto_repos` alone.
  2. `mix threadline.install` continues to use host `:ecto_repos` for migration path — the two keys serve different surfaces.
  3. One-line pointer to production-checklist for full mix-task inventory and multi-database notes.

### Config literal & multi-repo (CFG-01 snippet)

- **D-07:** Show strict literal **`config :threadline, ecto_repos: [MyApp.Repo]`** in a `config/config.exs` fence — matches CFG-01, example app, and mix-task error messages.
- **D-08:** Add **one footnote sentence**: put the repo that holds audit tables **first**; Threadline uses **first element only** (`List.first()` / `hd()`) — unlike Ecto mix tasks which iterate **all** repos in the list. **Reject** multi-repo example block in getting-started (Ecto/Oban pattern: happy path = one repo; advanced = ops doc).
- **D-09:** Footnote may reference operator-surface **`repo: MyApp.Repo`** on mount as explicit override (already canonical in `guides/operator-surface.md`); do not explain `Application.get_env` fallback chain in getting-started.

### Production checklist placement (CFG-03)

- **D-10:** Add standalone unnumbered section **`## Host repo wiring (prerequisite)`** immediately **after checklist intro**, **before `## 1. Capture and triggers`** — preserves §1–§7 section IDs and adoption-pilot anchor stability.
- **D-11:** Checklist entry = **checkbox + cross-link only** — no duplicate full install prose; canonical snippet and rationale live in getting-started (OSS DNA dual-contract: one SSOT, checklist verifies).
- **D-12:** Checklist bullet content: confirm `config :threadline, ecto_repos: [MyApp.Repo]`; required for all `mix threadline.*` tasks using `resolve_repo!/0` and operator-surface Mix fallbacks when LiveView denied/not mounted; link to getting-started §2 Configure block anchor.
- **D-13:** Checklist advanced note (same section): multi-database hosts — list **primary audit repo only**; do not mirror full host `:ecto_repos` unless first entry is the audit database; pass `repo:` on mount and programmatic APIs.
- **D-14:** Optional one-sentence backlink in **§5 Export and investigation** pointing to Host repo wiring prerequisite — **no second checkbox** in §5.

### Doc-contract strictness (CFG-02 + CFG-03 tests)

- **D-15:** **CFG-02** in `getting_started_saas_doc_contract_test.exs` — **Option B+**:
  - Exact literal: `config :threadline, ecto_repos: [MyApp.Repo]`
  - `:binary.match` ordering: literal index **<** `## 7. Check trigger coverage`
  - `:binary.match` ordering: literal index **<** `getting-started-sigra-reference-fence` (prevents optional-lane-only documentation)
  - **Preferred tighten:** literal index **<** `## 3. Install the audit schema` (matches “Base install path”)
  - At least one rationale fragment containing `Mix tasks` (or equivalent) and `ecto_repos`
- **D-16:** **CFG-03** in a **production-checklist-focused** contract test (extend `stg_doc_contract_test.exs` or add small dedicated test) — **not** folded into getting-started contract:
  - `guides/production-checklist.md` contains same literal or stable anchor text
  - Links back to getting-started (path + anchor)
  - **Reject** asserting production-checklist cross-link inside `getting_started_saas_doc_contract_test.exs` — blurs REQ ownership; footer link to checklist already exists and does not prevent today’s gap.

### Ecosystem alignment (locked rationale)

- **D-17:** Follow **Oban / ExAudit / Sentry** install pattern: deps → **configure library** → schema/tasks — not observability-lib “configure at first health check.”
- **D-18:** Follow **ExAudit lesson** (product strategy doc): day-one onboarding must feel effortless; **actionable errors** (`set :ecto_repos in config`) are good but **preventing** the error beats explaining it after §6 of a walkthrough.
- **D-19:** Follow **django-auditlog / Audit.NET** ops-layer pattern: first-hour doc teaches wiring; production checklist confirms wiring before domain-specific gates (`verify_coverage`, export, retention).
- **D-20:** Follow **Threadline OSS DNA** §2: doc contracts lock README ↔ guides ↔ example ordering; one verify artifact per REQ (CFG-02 vs CFG-03 split).

### Phase 122 dependency

- **D-21:** Execute against **Hex 0.6.0 live** (Phase 122 Tier 2 complete) — evaluators test published package; no code dependency but prefer honest evaluator path.

### Claude's Discretion

- Exact subsection title if `### Configure Threadline` reads awkward adjacent to §2 heading (keep between §2 and §3).
- Whether CFG-03 test extends `stg_doc_contract_test.exs` vs new `production_checklist_doc_contract_test.exs`.
- Exact anchor slug for getting-started link from checklist (`#configure-threadline` or similar).
- Minor prose polish within D-05/D-06 intent bounds.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` — Phase 123 goal, success criteria, CFG-01–03
- `.planning/REQUIREMENTS.md` — CFG-01, CFG-02, CFG-03 acceptance text
- `.planning/threads/2026-05-28-milestone-next-step-post-v1.26.md` — `ecto_repos` day-1 blocker evidence
- `.planning/phases/122-release-distribution-truth/122-CONTEXT.md` — D-14 Phase 123 prefers Hex 0.6.0 live

### OSS DNA & product strategy
- `prompts/threadline-elixir-oss-dna.md` — §2 doc contracts, §4 golden path / example host
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — ExAudit day-one DX, actionable errors, operator layer from day one
- `CLAUDE.md` — verification entrypoints (`mix verify.doc_contract`, `mix ci.all`)

### Runnable docs & contracts (edit targets)
- `guides/getting-started-saas.md` — CFG-01 primary edit
- `guides/production-checklist.md` — CFG-03 cross-link
- `test/threadline/getting_started_saas_doc_contract_test.exs` — CFG-02
- `test/threadline/stg_doc_contract_test.exs` — candidate for CFG-03 extension

### Code truth (repo resolution behavior)
- `examples/threadline_phoenix/config/config.exs` — both host and `:threadline, ecto_repos` set
- `lib/mix/tasks/threadline.install.ex` — uses host app `:ecto_repos` via `Mix.Project`
- `lib/mix/tasks/threadline.health.coverage.ex` — `resolve_repo!/0` pattern (representative)
- `lib/threadline/operator_surface/live/timeline_live.ex` — mount fallback to `:threadline, :ecto_repos`

### Ecosystem comparators (research only — do not copy verbatim)
- ExAudit `ecto_repos` config pattern — same key name as Threadline
- Oban installation docs — `repo:` in install chapter, not production-only
- Ecto getting-started — single-repo happy path; replicas in separate guide

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `examples/threadline_phoenix/config/config.exs:14` — canonical both-keys pattern for doc alignment
- `getting_started_saas_doc_contract_test.exs` — existing `:binary.match` ordering pattern (sigra fence scoping) to extend for CFG-02
- `exploration_routing_doc_contract_test.exs` / `stg_doc_contract_test.exs` — pattern for checklist cross-link assertions (CFG-03)

### Established Patterns
- Getting-started §1–§9 heading contract — do not renumber; insert subsection under §2 only
- Production-checklist domain sections §1–§7 — add unnumbered prerequisite band without renumbering
- Mix tasks share identical `resolve_repo!/0` error string across 9+ tasks

### Integration Points
- §7 `mix threadline.health.coverage` — first guided `resolve_repo!` consumer
- §8 mix fallback bullets — adopters may run before §7 if skimming
- §9 operator mount — `repo:` in mount block already; config is fallback when omitted
- Production-checklist §1 `verify_coverage` — fails without `:threadline, :ecto_repos` in CI paths

</code_context>

<specifics>
## Specific Ideas

- “Install worked, so I’m configured” is the #1 footgun — `mix threadline.install` proves nothing about `:threadline` config.
- Threadline’s first-only repo semantics **contradict** Ecto’s “all repos in list” intuition — footnote is mandatory, not optional polish.
- Dual-contract: getting-started owns snippet + brief why; checklist owns checkbox + task inventory + multi-DB note.
- Doc contract should fail if config appears only in Sigra optional fence (v1.26-class soft-gap pattern).

</specifics>

<deferred>
## Deferred Ideas

- Full multi-repo / dynamic-repo guide — future advanced doc if adopter signal (not v1.27)
- Auto-infer `:threadline, :ecto_repos` from host config at compile time — product/code change, out of Phase 123 scope
- Carbonite-style `-r MyApp.Repo` CLI flag instead of app env — architectural alternative, not this phase
- §6 auth neutrality, ADOPT-AUTH literals, `:schemas`, evidence host-write — Phase 124

</deferred>

---

*Phase: 123-first-hour-config*
*Context gathered: 2026-05-28*
