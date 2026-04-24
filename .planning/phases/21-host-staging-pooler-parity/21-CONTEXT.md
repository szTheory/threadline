# Phase 21: Host staging & pooler parity - Context

**Gathered:** 2026-04-23  
**Status:** Ready for planning

<domain>

## Phase Boundary

Deliver **STG-01**–**STG-03** (see `.planning/REQUIREMENTS.md`): integrator-owned **topology narrative**, **HTTP + async job** audited-path evidence with **OK / Issue / N/A** and reproducible pointers, and **backlog** rows (`guides/adoption-pilot-backlog.md` or host-linked copy per intro) that stay honest about **CI vs host**. No new capture semantics, no claiming external environments the library does not control, no in-repo Phoenix sample app in this phase (remains deferred per `REQUIREMENTS.md` / `PROJECT.md`).

**Gathering mode:** User selected **all** gray areas; decisions below synthesize parallel research (OSS doc patterns, Elixir/Hex norms, pooler/Ecto operator docs, checklist semantics) into one coherent maintainer plan.

</domain>

<decisions>

## Implementation Decisions

### 1. Evidence shape and canonical home (STG-02 / STG-03)

- **D-01 (Hybrid B + C):** Keep **versioned in-repo rubric** only in canonical markdown: definitions of OK / Issue / N/A / Not run, what counts as evidence, redaction rules, and **empty or example-only** template rows where useful. Put **host-specific outcomes and payloads** (topology detail beyond the index, log excerpts, internal URLs) in **integrator-controlled** artifacts (app repo `docs/…`, wiki, or private doc) and **link** from `guides/adoption-pilot-backlog.md` intro and/or per-row “Evidence link” cells—per `REQUIREMENTS.md` allowance for a linked host-maintained copy.
- **D-02:** Reject **A-alone** (single file that becomes the dumping ground for every host’s secrets and attestation): high footgun risk (git history, version skew, maintainer-as-notary). Reject relying on **C-alone** without in-repo rubric: discoverability and criterion drift.
- **D-03:** In-repo rows may hold **short stable summaries** (e.g. status + “see [evidence doc] §STG”) when the full narrative lives off-repo; never require pasting connection strings or raw tokens into `main`.

### 2. Maintainer vs integrator workflow

- **D-04:** **Maintainer** owns **structure**: templates, section headings, CONTRIBUTING (or guide) subsection “Submitting host STG evidence,” and neutral wording that does not attest to third-party infra.
- **D-05:** **Integrator** owns **attested content** for anything that reads as “we ran this in our environment”: prefer **fork + PR** so git authorship, review thread, and CLA/DCO match normal Elixir OSS (same family of norms as Kubernetes SIG docs / collector contrib: provenance via PR, not proxy commits).
- **D-06:** **Discourage** maintainer-only paste of a third-party’s full narrative as the **sole** canonical record (weak provenance, redaction/CLA blur). **Discourage** issue-only dumps as the **only** durable artifact (link rot, weak diff review); issues may **coordinate** before a doc PR.
- **D-07:** Maintainer may still **merge** integrator PRs that only touch guide tables/links after normal review—no requirement to “verify their staging,” only to enforce modesty of claims, redaction, and link hygiene.

### 3. OK / Issue / N/A semantics

- **D-08:** Treat **Not run** as applicable but not yet exercised; **never** use Not run and N/A interchangeably.
- **D-09:** **N/A** is allowed only with a **one-line objective justification** tied to a written scope rule (e.g. “no background job executor in this deployment; async audit deferred to future profile”). Vague N/A is unacceptable (“not relevant”).
- **D-10:** **OK** requires a **reproducible pointer**: Mix/CI command, test path, PR to the integrator’s public repo, doc path, or scripted steps—not “we tested it” with no anchor. Prefer noting **`threadline` semver** and app commit where practical (aligns with `.planning/research/PITFALLS.md`).
- **D-11:** **Issue** for known gaps, flakiness, or “must fix before we claim OK,” with owner or next step when tracked in-repo.
- **D-12:** Explicitly **label CI-class proof vs host-class proof** where a reader could confuse `verify-pgbouncer-topology` / `mix verify.threadline` with the host’s HTTP/Oban paths—reuse and sharpen existing **CI-PGBOUNCER-TOPOLOGY-CONTRACT** language rather than inventing a second metaphor.

### 4. Topology narrative structure (STG-01)

- **D-13:** Use a **fixed ordered field list** per environment (staging / prod-like), not freeform prose alone. Minimum fields: **chain** (`app → [pooler] → postgres` or `app → postgres`), **pooler product** (or none), **pool mode** (e.g. transaction / session / vendor equivalent—never “PgBouncer” without mode), **Postgres role** if material, **Ecto** `pool_size` / `pool_count` if non-default, **`prepare:`** policy if material to pooler story, explicit note that **Sandbox is test-only**, **matches prod: yes | no | partial** as an enum—not buried in a sentence.
- **D-14:** Immediately after the fixed block, require the **one-paragraph rationale** already implied by STG-01—especially to explain **partial** honestly (CI vs host class; see `PITFALLS.md` §1).
- **D-15:** Keep `guides/adoption-pilot-backlog.md` **Connection topology** as a **narrow index table** (short cells + optional link column). Longform and optional Mermaid live in the **host-linked** doc; Mermaid is illustrative, not the source of truth for mode.

### 5. Repo affordances (what ships in-repo this phase)

- **D-16:** **Primary lever:** extend existing **doc contract** coverage (`verify.doc_contract`, `test/threadline/readme_doc_contract_test.exs`, related fixtures)—anchors, cross-links, and fixture-backed checks on **public integration surfaces** only (no capture internals).
- **D-17:** **Do not** add a new Phoenix **example app** or expand **Docker** topology in v1.6: high maintenance and scope creep; remains aligned with `REQUIREMENTS.md` “Out of scope” and research SUMMARY.
- **D-18 (Claude’s discretion / optional):** A **thin** `mix threadline.*` task that only prints canonical doc paths and `mix verify.*` / CI job names is acceptable **if** it shares a single source of truth with guides (no second validation engine). If it risks duplicating policy strings, **skip** and rely on docs + doc contracts only.

### Cohesion note (cross-decision)

Evidence **B+C**, workflow **fork+PR**, topology **fixed fields + link**, and semantics **OK/N/A/Not run** are mutually reinforcing: the integrator PR updates **short in-repo index + links** while detailed proof stays **reviewable** and **redactable** in the integrator’s artifact; maintainers never imply they operated the host stack.

### Claude's Discretion

- Whether a thin STG index Mix task is worth the extra surface area (**D-18**).
- Exact doc contract assertions (which anchors) once plan-phase touches files.
- Wording polish in guides and CONTRIBUTING.

</decisions>

<canonical_refs>

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — STG-01–STG-03 acceptance text
- `.planning/ROADMAP.md` — Phase 21 goal, success criteria, notes on Hex 0.2.0
- `.planning/PROJECT.md` — v1.6 milestone intent, non-goals
- `.planning/milestones/v1.5-REQUIREMENTS.md` — archived STG-01 draft (linked from backlog)

### Research and pitfalls

- `.planning/research/SUMMARY.md` — v1.6 scope guardrails
- `.planning/research/PITFALLS.md` — CI vs host, POOL_MODE, evidence reproducibility

### Operator and adoption docs (implementation targets)

- `guides/adoption-pilot-backlog.md` — Connection topology table, checklist matrix, STG / CI boundary copy
- `guides/production-checklist.md` — Cross-walk for STG rows
- `CONTRIBUTING.md` — PgBouncer topology CI parity, how maintainers run verification

### CI and contracts

- `.github/workflows/ci.yml` — `verify-pgbouncer-topology`, job ordering
- `test/threadline/pgbouncer_topology_test.exs` — pooler path coverage
- `test/threadline/ci_topology_contract_test.exs` — doc/CI contract for topology job
- `test/threadline/readme_doc_contract_test.exs` — doc contract pattern to extend
- `test/support/readme_quickstart_fixtures.ex` — fixture patterns for doc contracts

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable assets

- **Doc contract suite:** `mix verify.doc_contract` → `readme_doc_contract_test.exs` + `ReadmeQuickstartFixtures` for compile-safe, API-honest documentation checks.
- **CI topology job:** `verify-pgbouncer-topology` + `priv/ci/topology_bootstrap.exs` (referenced in backlog)—the **library’s** transaction-pooler class proof.

### Established patterns

- **Honest labeling:** Backlog already distinguishes maintainer CI evidence from **STG-01** host remainder (`AP-ENV.1` row); Phase 21 extends that pattern rather than replacing it.
- **Mix task namespace:** Operational tasks live under `lib/mix/tasks/threadline.*.ex` with tests under `test/mix/tasks/`—any optional STG index task should follow that layout and stay trivial.

### Integration points

- **CONTRIBUTING** ↔ **adoption-pilot-backlog** ↔ **production-checklist**: single narrative for operators; Phase 21 edits should keep cross-links consistent for doc contracts.
- **STATE / roadmap:** `gsd-sdk query init.phase-op "21"` currently returns `phase_found: false` because Phase 21 lacks a checklist line in `ROADMAP.md`; planning or a small roadmap edit in a separate change can restore tool discovery.

</code_context>

<specifics>

## Specific Ideas

- Treat **SOC2 / SRE PRR / CNCF** analogues only as **discipline** (evidence links, documented omission, no scorecard gaming)—Threadline is not a compliance product, but the same **matrix hygiene** prevents “everything N/A.”
- **Ecto + PgBouncer least surprise:** topology docs must surface **pool mode** and app-side **Repo** settings (`prepare:`, pool counts)—operators debug “where did my session feature break?” not “did Threadline insert a row in CI?”

</specifics>

<deferred>

## Deferred Ideas

- **In-repo Phoenix sample app** — explicitly out of scope for v1.6 per `REQUIREMENTS.md` / `PROJECT.md`; would change how often integrator matrices need N/A for job/HTTP profiles.
- **Automated `mix threadline.stg` “validator”** that encodes policy beyond existing `verify.*` — risks false confidence and duplicate source of truth; not part of agreed Phase 21 unless reduced to a link index (**D-18** discretion only).

</deferred>

---

*Phase: 21-host-staging-pooler-parity*  
*Context gathered: 2026-04-23*
