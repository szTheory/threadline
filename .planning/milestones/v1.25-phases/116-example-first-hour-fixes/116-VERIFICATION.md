---
status: passed
phase: 116-example-first-hour-fixes
verified: 2026-05-27
score: 4/4
---

# Phase 116 Verification Report

**Phase goal:** A maintainer or evaluator can clone the example app and reach a first audited write without README traps (auth staging, demo.seed path, generator clarity).

## Requirements Verified

| ID | Requirement | Status | Evidence |
|----|-------------|--------|----------|
| EXAMPLE-01 | Example README documents API auth staging for `POST /api/posts` curl (session/cookie path) | ✓ | Router `:api` pipeline L115–127; README `### Authenticate before the audited API call` (L217–248); getting-started §6 (L117–137); `example_phoenix_readme_contract_test.exs` auth staging test |
| EXAMPLE-02 | Clean-clone setup distinguishes base install from `mix demo.seed` / `mix demo.reset` | ✓ | `## Choose your path` table (L25–31); `## Base install (all paths)` with skip-generators callout (L63–65); Track A explicit no `demo.seed` (L102–111); Track B pointer (L113–118); `readme_doc_contract_test.exs` first-hour path locks |
| EXAMPLE-03 | Generator/migration vs demo task responsibilities clear; no contradictory first-hour steps | ✓ | `## Mix task reference` (L137–147); `## Mix task ownership` appendix (L149–165); `skip on this checkout` for generators; old `## Installation (Threadline capture…)` removed |
| EXAMPLE-04 | `mix verify.example` green; doc-contract tests updated for README literals | ✓ | `mix verify.doc_contract` 63/0; `mix verify.example` 53/0; extended `readme_doc_contract_test.exs`, `example_phoenix_readme_contract_test.exs`, `getting_started_saas_doc_contract_test.exs` |

## Plan 01 Must-Haves (API auth staging)

| Truth / artifact | Status | Evidence |
|------------------|--------|----------|
| `:api` runs `fetch_session` + `fetch_current_scope` before `Threadline.Plug`, outside doc fence | ✓ | `router.ex` L115–127; fence markers unchanged |
| `sigra_conn/2` stages `:user_token` session (no direct `assign(:current_scope)`) | ✓ | `conn_case.ex` L50–69; posts_* tests 7/0 |
| README + getting-started §6 auth subsection with cookie curl and `missing actor` boundary | ✓ | README L217–248; `getting-started-saas.md` L117–137 |
| Doc-contract locks for auth staging literals | ✓ | `example_phoenix_readme_contract_test.exs` L116+; `getting_started_saas_doc_contract_test.exs` L65–67 |

## Plan 02 Must-Haves (first-hour runbook)

| Truth / artifact | Status | Evidence |
|------------------|--------|----------|
| `## Choose your path` before long install prose | ✓ | README L25–31 |
| Single `## Base install (all paths)`; Track A needs no `demo.seed` | ✓ | README L63–111 |
| `## Mix task reference` + `## Mix task ownership` tables | ✓ | README L137–165 |
| `## Demo walkthrough data` heading preserved; body compressed | ✓ | README L129–135 |
| Root doc-contract locks for skip-generators + neutral vs walkthrough fiction | ✓ | `readme_doc_contract_test.exs` L152–168 |

## Automated Checks

- `mix verify.doc_contract` — 63 tests, 0 failures
- `mix verify.example` — 53 tests, 0 failures
- `mix test test/threadline/readme_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs` — 24 tests, 0 failures
- `cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/posts_audit_path_test.exs test/threadline_phoenix_web/posts_correlation_path_test.exs test/threadline_phoenix_web/posts_incident_json_path_test.exs` — 7 tests, 0 failures

## Human Verification

Optional (non-blocking): manual Track A golden path — clean clone → `mix ecto.migrate` → `mix phx.server` → browser login at `/users/log_in` → cookie curl → `201` + `audit_transaction_id` without `mix demo.seed`. Automated tests and doc contracts cover the same contract; manual run is a nice-to-have evaluator smoke test only.

## Gaps

None — all four EXAMPLE requirements satisfied with current-tree evidence.
