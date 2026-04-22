# Threadline — Elixir OSS “DNA” synthesis

**Purpose:** Encode recurring engineering habits from **scrypath**, **accrue**, **lattice_stripe**, and **sigra** so Threadline (audit platform for Phoenix/Ecto/PostgreSQL) starts with the same quality bar. This is maintainer intent, not a legal spec.

**Threadline architectural spine:** treat **capture**, **semantics**, and **exploration/operations** as separate layers (see `prompts/audit-lib-domain-model-reference.md`). OSS “DNA” below mostly hardens **how** we ship and verify, not **what** goes in each layer.

---

## 1. Verify and CI

- **Verification is a product surface.** Prefer named entrypoints (`mix verify.*`, `mix ci.*` aliases) that contributors and CI cite verbatim—avoid folklore commands that exist only in chat or a single doc paragraph.
- **Default `mix test` honesty:** Avoid silently excluding heavy suites from the default path unless `test/test_helper.exs` and maintainer docs change together (Sigra phase **50** explicitly guards this). Prefer timeouts, deterministic env, pinned tooling, and **layered** CI jobs over hidden skips.
- **Nested / fixture apps:** When an installer or golden host lives under `test/fixtures/`, give it a **single flat Mix alias** (documented next to env vars) and **separate cache keys** from the root app—reuse of root `_build`/`deps` caches for nested trees is a footgun (Sigra **50** installer golden pattern).
- **Stable CI job identifiers:** Keep **job `id:`** immutable for `act`, scripts, and grep-based contracts; evolve human-readable `name:` and prose together (Accrue phase **36** patterns).
- **Path filters + main:** Expensive nested jobs still run on **`main`** (and optionally schedule) even when PRs are path-filtered—signal without pretending the default root suite covers everything.
- **Nyquist / validation debt:** When validation is deferred, record **owner, date, pointer** to superseding evidence, and **trigger to reopen**—never merge-theater `nyquist_compliant: true` (Sigra **50** hybrid policy).

---

## 2. Docs and contracts

- **Single contributor entrypoint** for “where do I pin this doc anchor?”—failures should name REQ, script section, or contract file when possible (Accrue **36-PATTERNS**).
- **Three-source traceability:** `REQUIREMENTS.md` checkboxes, `NN-VERIFICATION.md`, and `requirements-completed` in completed `NN-SUMMARY.md` stay aligned; prefer **links** from `.planning/` into runnable docs over duplicating long command tables (Accrue **36**).
- **Doc contract tests** (`docs_contract_test` or equivalent): lock README ↔ guides ↔ example README ordering and filesystem anchors so marketing drift does not break adopters (Scrypath history: golden path, integration smoke, contributor matrices).
- **Dual-contract awareness:** When both root README and host/example README participate in verification scripts, treat updates as **one logical change set** (Accrue **36**).

---

## 3. Releases and Hex

- **Version SSOT:** `mix.exs` / workspace packages + Release Please (or chosen automation) stay numerically aligned; post-publish gates (`release_parity`, workspace clean) belong in the same mental model as tests (Scrypath milestone narrative).
- **CHANGELOG and narrative coherence:** Ship notes, Hex metadata, and README agree on version story for the same tag—avoid “docs say A, Hex says B.”
- **Release gates are not optional ad-hoc scripts**—they should be discoverable from `CONTRIBUTING.md` and runnable locally where feasible.

---

## 4. Examples and host apps

- **Canonical host** under `examples/` (Accrue: `accrue_host`) is the adoption proof: seeded flows, CI-equivalent verify, browser checks where justified, README as the front door.
- **Golden path guide** separate from README quick start: README points to one authoritative longer guide (Scrypath-style).
- **Integration smoke** on PR + `main` that matches documented “Integration smoke” steps—reduces “works on my laptop” for Phoenix wiring.

---

## 5. Security and audit-adjacent patterns

- **Actionable errors:** Structured `{:error, reason}` with stable modules / reasons and links to “what next” docs (Scrypath operator polish arc).
- **Pitfalls ledger:** Domain-specific “what goes wrong and why” (LatticeStripe `PITFALLS.md` style) is valuable for **audit capture** too—e.g. trigger ordering, migration edge cases, redaction leaks.
- **Actor and session semantics:** Sigra’s auth research in `prompts/prior-art/from-sigra/` informs **who is the actor**, request-bound context, and multi-tenant boundaries—Threadline semantics layer should integrate with host auth without becoming an auth library.
- **Tamper-evidence and corpus discipline:** Accrue’s audit ledger and “audit corpus” integration phases are the reference for **traceability matrices** and verifier ownership when multiple scripts enforce one requirement.

---

## 6. GSD and milestone hygiene

- **Milestone close:** When audit is green, finish with **git tag**, **`milestones/v*-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`**, and planning markers in one pass so `MILESTONES.md` does not lag (Scrypath `RETROSPECTIVE.md` lesson).
- **Tech-debt audits:** If milestone audit is `tech_debt`, you may still ship—but **attach** the audit under `milestones/` so hygiene gaps stay discoverable without blocking archive.
- **Automation gaps:** When SDK milestone automation fails, keep **manual archive steps** explicit and repeatable rather than pretending tooling works (recurring note across Scrypath retrospectives).

---

## 7. Borrow checklist for Threadline v0 (actionable)

| Practice | Threadline application |
|----------|-------------------------|
| Flat `mix ci.*` / `mix verify.*` alias for nested example | If `examples/threadline_host` (or similar) exists early, one cited command for CI + locals |
| Doc contract anchors | README ↔ `guides/` ↔ example agree on install and “first audit event” path |
| Immutable CI job ids | Any script or `act` doc that greps workflow YAML keeps working |
| REQ + verification + summary alignment | Even before Hex, track requirements in GSD with traceable verify artifacts |
| Pitfalls doc | First chapter: migrations + triggers + Ecto sandbox interaction gotchas |
| Action semantics API | Plug / `conn.assigns` / Oban metadata conventions documented like a public contract |

---

## 8. Non-goals for this DNA document

- Does not prescribe Carbonite vs custom triggers (that belongs in roadmap research).
- Does not import Stripe, Meilisearch, or Sigra product scope—only **process and patterns**.

---

## 9. Prior-art file map

| Location | Contents |
|----------|----------|
| `prompts/prior-art/oss-deep-research/` | Deduped Elixir / Ecto / Phoenix / Plug / OSS CI deep research (canonical bytes from scrypath; see `SOURCE-CANONICAL.md`) |
| `prompts/prior-art/from-scrypath/` | Search-library research + Scrypath brand book (operator / product narrative reference) |
| `prompts/prior-art/from-sigra/` | Auth-domain research (actor, Phoenix integration, naming discipline) |
| `prompts/prior-art/accrue-planning-notes.md` | Pointers into Accrue `.planning/` (no prompts tree there) |
