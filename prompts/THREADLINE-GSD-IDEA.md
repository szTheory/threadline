# Threadline — GSD new-project idea document

Use with: `/gsd-new-project --auto @prompts/THREADLINE-GSD-IDEA.md` from the **threadline** repo root.

## One-line pitch

**Threadline** is an open-source **audit platform** for Elixir teams using **Phoenix, Ecto, and PostgreSQL**—combining trustworthy **row-change capture**, rich **action semantics** (who / why / in what context), and **operator-grade** exploration and health signals.

## Problem

Teams need audit trails that are **hard to bypass**, **SQL-friendly**, and **useful for support and ops**—not only compliance checkboxes. Row-level history without **request and actor context** is incomplete; context without **durable capture** is untrustworthy.

## Product principles (table stakes)

- **Correct by default:** harder to miss capture than to enable it.
- **Context-rich:** actions, jobs, and requests link to changes.
- **Composable:** idiomatic Plug, Phoenix, Ecto, Oban, and LiveView ergonomics.
- **Operationally legible:** degraded capture, retention, and redaction are visible and actionable.
- **SQL-native:** operators can query and export without opaque blobs.

## Non-goals (initial milestones)

- Not a SIEM, not full event sourcing, not a replacement for pgAudit, not a data warehouse product (see domain reference).

## Technical direction (high level)

- **Capture layer:** trigger-backed or equivalent **canonical** change log for row mutations (evaluate Carbonite and alternatives during early research phases).
- **Semantics layer:** first-class **application events** binding actor, intent, correlation ids, and affected resources.
- **Exploration / ops layer:** timelines, diffs, filters, exports, health and coverage checks—can mature after the library proves capture + semantics.

## OSS / engineering constraints

Ship with the same discipline as sibling libraries:

- Named **`mix verify.*` / `mix ci.*`** entrypoints, honest default tests, stable CI job ids.
- **Doc contract** tests once public docs exist; **golden path** guide + example host when the API stabilizes.
- **Release automation** and Hex alignment when publishing.

Full synthesis: **`prompts/threadline-elixir-oss-dna.md`**.

## Prior research (read in full during GSD research step)

1. **`prompts/audit-lib-domain-model-reference.md`** — domain model, API/UI/ops considerations, layered architecture.
2. **`prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md`** — ecosystem and strategy.
3. **`prompts/Threadline Brand Book.txt`** — naming, voice, visual intent.
4. **`prompts/prior-art/`** — deduped Elixir/Phoenix/OSS CI research + Scrypath/Sigra supplements + Accrue planning pointers.

## Suggested first milestone (for roadmap seeding)

**Milestone v0.1 — “Trustworthy spine”**

- Hex package **`threadline`** (name TBD if conflict; default to `threadline`), Elixir ≥ same baseline as active Phoenix LTS in sibling repos.
- **Design contracts:** documented data model for capture vs semantics; migration story sketched.
- **Minimal capture path:** proof-level integration with PostgreSQL + Ecto (exact mechanism chosen in phase 1 research).
- **Semantics hook:** one blessed way to attach **actor + correlation** from Plug/Phoenix (even if minimal).
- **CI:** GitHub Actions running format, credo (if adopted), and tests; no merge theater.
- **Docs stub:** README vision + link to domain reference; CONTRIBUTING skeleton.

Subsequent milestones might add example host, LiveView operator UI, retention/redaction, and export—but **do not** commit to all of that in v0.1.

## Open decisions for `/gsd-discuss-phase` / planning

- Umbrella vs single package vs optional `threadline_web` companion (defer until API sketch exists).
- Minimum supported **Phoenix / Ecto / PG** versions.
- Whether v0.1 ships **read APIs only** or also a minimal operator surface.

## GSD bootstrap commands (pick one)

- **In Cursor / Claude Code (slash workflow):** run from repo root with a clean session:
  ```text
  /gsd-new-project --auto @prompts/THREADLINE-GSD-IDEA.md
  ```
  Then: `/gsd-plan-phase 1` (add `--text` in non-Claude CLIs if menus are unavailable).

- **Terminal — one-shot init (creates `.planning/` end-to-end):** requires `git` in the repo root first.
  ```bash
  cd /path/to/threadline
  git init   # if not already a repo
  gsd-sdk init @prompts/THREADLINE-GSD-IDEA.md
  ```

- **Optional — plan Phase 1 without the slash command:**
  ```bash
  gsd-sdk run "/gsd-plan-phase 1 --text --skip-verify --skip-research"
  ```
  Always **re-verify** roadmap claims with `mix test` (PostgreSQL test DB) and maintainer review of `gate-01-01.md` before treating Phase 1 as complete.

---

**Instruction to GSD (auto mode):** Treat this file as authoritative for **vision, constraints, non-goals, and first-milestone intent**. Pull detailed requirements from the linked domain reference and DNA doc. Run **research** to validate capture options and ecosystem overlap before locking `REQUIREMENTS.md`.
