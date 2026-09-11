# Phase 199 Deferred Items

## 199-01: Pre-existing repository-wide formatter drift

- **Status:** open
- **Discovered during:** Plan 199-01 Task 2 verification
- **Evidence:** `mix verify.format` reports formatting drift in `test/threadline/e2e_preflight_contract_test.exs`, `test/threadline/phase198_automation_policy_test.exs`, `test/threadline/phase198_nyquist_contract_test.exs`, and `test/threadline/main_ci_observer_contract_test.exs`.
- **Scope:** None of the four files was modified by Plan 199-01. The plan-owned checker and test files pass `mix format --check-formatted` directly.
- **Disposition:** Deferred to the owner of the Phase 198 contract-test formatting drift; Plan 199-01 does not rewrite unrelated files.
