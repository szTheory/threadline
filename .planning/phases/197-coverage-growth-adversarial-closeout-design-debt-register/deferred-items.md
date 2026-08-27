# Phase 197 — Deferred Items

Out-of-scope discoveries logged during execution (not fixed inline per scope
boundary — each is registered in 197-DESIGN-DEBT-REGISTER.md).

## 197-05 (2026-08-27)

- **`test/threadline/operator_surface/copy_contract_test.exs:249` red** — expects
  the "Selected schema readiness" eyebrow that the landed 197-02 coverage edit
  (842bd737) removed. Caused by 197-02's changes, not this plan's; the 197-02
  commit gates (coverage_live_test 21/0, verify.mechanical, verify.critic_trust)
  did not include the copy-contract suite. Fix = flip the expectation to the
  post-edit copy (assert-to-refute pattern, same as coverage_live_test). Registered
  as debt rank 2.
- **Inherited 3-module doc-contract baseline confirmed unchanged** — fresh full
  `mix test` (2026-08-27): exactly V123Charter / FormlessPages / Phase06Nyquist
  red, no new members. Registered as debt rank 8 (tracked since 195-10).
- **`(undefined_table)` search_path signature count = 0** in the fresh full run —
  the historical ~81 local failures did not reproduce (confirmed
  `ALTER DATABASE ... SET search_path` fix in effect). Register row 12 closed-in-
  environment with a CI reopen-trigger.
