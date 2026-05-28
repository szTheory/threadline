---
status: clean
phase: 116-example-first-hour-fixes
reviewed: 2026-05-27
depth: standard
files_reviewed: 10
findings_critical: 0
findings_warning: 0
findings_info: 0
total: 0
---

# Phase 116 Code Review

Example first-hour fixes — session plugs on the `:api` pipeline, `sigra_conn/2` session-token staging, API auth curl documentation, and README runbook restructure (Choose your path / Base install / Track A–B / Mix task ownership).

## Scope Reviewed

**116-01 (API auth staging)**

- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — `:api` session plugs
- `examples/threadline_phoenix/test/support/conn_case.ex` — `sigra_conn/2` refactor
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_*_path_test.exs` — user-fixture auth staging
- `examples/threadline_phoenix/README.md` — Authenticate before subsection + cookie curl
- `guides/getting-started-saas.md` — §6 auth staging + curl
- `test/threadline/example_phoenix_readme_contract_test.exs` — API auth literal locks
- `test/threadline/getting_started_saas_doc_contract_test.exs` — §6 auth literal locks

**116-02 (README runbook clarity)**

- `examples/threadline_phoenix/README.md` — Choose your path, Base install, Track A/B, Mix task tables
- `test/threadline/readme_doc_contract_test.exs` — first-hour path and ownership literal locks

## Verification

```bash
cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/posts_audit_path_test.exs test/threadline_phoenix_web/posts_correlation_path_test.exs test/threadline_phoenix_web/posts_incident_json_path_test.exs
# 7 tests, 0 failures

mix test test/threadline/example_phoenix_readme_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs
# 27 tests, 0 failures

mix verify.example   # 53 tests, 0 failures
mix verify.doc_contract  # 63 tests, 0 failures
```

## Router Session Plug Ordering

`:api` pipeline order in `router.ex`:

1. `plug(:fetch_session)`
2. `plug(:fetch_current_scope)`
3. `plug(:accepts, ["json"])`
4. `Threadline.Plug` (Sigra `actor_fn` / `context_overrides_fn`)

This ordering is correct: session must load before `fetch_current_scope/2` reads `:user_token`; scope and `:sigra_session` private must populate before `Threadline.Integrations.Sigra.actor_ref_from_conn/1` runs inside `Threadline.Plug`. Session plugs sit **outside** the `router-pipeline-actor-fn` doc fence per plan decision — the fenced snippet still extracts cleanly for getting-started §5.

Browser `:browser` pipeline already runs the same session → scope sequence; `:api` now mirrors that auth path without duplicating CSRF/browser-only plugs.

## sigra_conn/2 Session Token Staging

`sigra_conn/2` correctly stages production-shaped auth:

- Creates a real user (fixture or passed `user`) and `Accounts.generate_user_session_token/1`
- Optionally persists `active_organization_id` via `UserSession` Ecto update (not `Sigra.Session` changeset — correct fix for undefined changeset)
- Uses `init_test_session/1` + `put_session(:user_token, token)` so dispatch runs `fetch_current_scope` and populates assigns from DB

Direct `:current_scope` / private `:sigra_session` assigns were removed — plugs no longer overwrite staged state with `nil`. Correlation fallback test correctly uses `Ecto.UUID.generate()` for org id when `Accounts.Organization` fixture is unavailable.

## Doc Contract Test Correctness

| Test file | Locks | Assessment |
|-----------|-------|------------|
| `example_phoenix_readme_contract_test.exs` | Auth subsection heading, `fetch_current_scope`, cookie key, `missing actor`, no credentials in first fence after heading | Correct; auth fence scoping avoids locking demo passwords |
| `getting_started_saas_doc_contract_test.exs` | §6 `Authenticate before`, `_threadline_phoenix_key`, bearer disclaimer, existing router/blog/mount fences | Correct; §6 curl `-b` flag aligned with example README |
| `readme_doc_contract_test.exs` | Choose your path, Base install, skip-generators callout, neutral vs walkthrough fiction, Mix task ownership | Correct EXAMPLE-02/03/04 remainder coverage |

`GettingStartedFixtures.extract!/2` for `router-pipeline-actor-fn` still matches router fence (session plugs excluded by design). Dual-contract pattern (literals without locking full curl fences) is appropriate.

## README Restructure Clarity

Runbook structure is coherent and non-contradictory:

- **Choose your path** table routes evaluators to Track A (first audited write, no `demo.seed`), Track B (WALKTHROUGH fiction), or getting-started for greenfield
- **Base install** centralizes committed-checkout skip-generators callout; generator commands remain in Regenerating skeleton only
- **Track A / Track B** forks are short and link back to Base install; Track A points to the auth subsection under Audited HTTP path
- **Demo walkthrough data** heading preserved (root doc contract); body compressed to Track B pointer
- **Mix task reference** + **Mix task ownership** tables disambiguate `ecto.setup` / `ecto.reset` vs `demo.seed` / `demo.reset` without duplicating full install tracks

Seed terminology (`priv/repo/seeds.exs` = neutral, `mix demo.seed` = walkthrough fiction) is reinforced consistently.

## Architecture Notes (Intentional, Not Defects)

- Getting-started §5 fenced router snippet omits session plugs; example README **Authenticate before** subsection is the runnable authority for `:api` session wiring on the reference app. Aligns with 116-01 decision to keep session plugs outside the doc fence.
- Reference `:api` routes accept browser session cookies without CSRF plugs — documented as host-owned production concern (`401`/`403` earlier, no bearer tokens in example).

## Findings

None — router plug ordering, test helper staging, doc contracts, and README restructure match phase intent. No security or correctness issues identified.
