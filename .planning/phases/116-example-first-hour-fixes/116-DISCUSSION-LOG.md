# Phase 116: Example First-Hour Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 116-Example First-Hour Fixes
**Areas discussed:** API auth staging, clean clone vs demo paths, task ownership matrix, doc-contract strategy (all four — user requested full research synthesis)

---

## API auth staging for `POST /api/posts`

| Option | Description | Selected |
|--------|-------------|----------|
| A — Prerequisite callout + tests-only skip | Docs only; bare curl fails honestly | |
| B — Session plugs on `:api` + browser cookie curl | `fetch_session` + `fetch_current_scope` before `Threadline.Plug`; curl with `_threadline_phoenix_key` | ✓ |
| C — Dev Bearer demo token | `Authorization: Bearer` shim in dev | |
| D — IEx-only primary path | Demote HTTP curl | |

**User's choice:** Auto-selected via research synthesis (user: "discuss all… perfect recommendations").

**Notes:** Subagent + prompts review. Bare curl returns 500 `missing actor` today. WALKTHROUGH already uses cookie pattern on browser routes. Rejected Bearer (implies Threadline ships API auth). Sync `getting-started-saas.md` §6.

---

## Clean clone vs walkthrough fiction

| Option | Description | Selected |
|--------|-------------|----------|
| A — Goal decision table + shared base + tracks | Choose your path table; Base install; Track A/B | ✓ |
| B — Fully parallel H2 tracks | Duplicate install lists | |
| C — Linear install with inline forks | Easy to miss fork at step 7 | |
| D — Quick start + reference only | Oversimplifies generator story | |

**User's choice:** A (+ task reference table from research).

**Notes:** Keep `## Demo walkthrough data` for existing doc contract. Neutral `seeds.exs` vs `demo.seed` terminology.

---

## Task responsibility matrix

| Option | Description | Selected |
|--------|-------------|----------|
| A — Table only | | partial |
| B — Three owners prose only | | partial |
| C — Numbered runbook inline only | | partial |
| D — Dual runbooks + appendix table | Clean clone vs greenfield + `## Mix task ownership` | ✓ |

**User's choice:** D.

**Notes:** Ecosystem: Carbonite/Oban generate → Ecto migrate → app seed. Footguns: `install`≠`create`, `ecto.reset`≠`demo.reset`, `MIX_ENV` on `gen.triggers`.

---

## Doc-contract locks (EXAMPLE-04)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Headings only | Too weak | |
| B — Auth + setup literals | Split across two contract files | ✓ |
| C — Full table row locks | Row labels, not headers alone | ✓ |
| D — Full WALKTHROUGH cross-file parity | Maintainer file separate | |

**User's choice:** B + selective C in `readme_doc_contract_test.exs`; B in `example_phoenix_readme_contract_test.exs`.

**Notes:** Do not snapshot full curl blocks or passwords.

---

## Claude's Discretion

- Exact subsection titles and prose within D-116 structures.
- Optional POST status code alignment.
- Shared literal with WALKTHROUGH only if exact phrase match.

## Deferred Ideas

- Dev Bearer token for headless automation
- Full CSRF cookie-jar login in README
- Changing `ecto.setup` alias to exclude `seeds.exs` without separate product decision
