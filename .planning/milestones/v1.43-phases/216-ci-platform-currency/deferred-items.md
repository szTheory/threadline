# Phase 216 deferred items

Out-of-scope discoveries recorded during phase 216. Nothing here is fixed in this phase.

## From plan 216-06

1. **Align setup-node with `.tool-versions` (OD-5).** `.tool-versions` pins `nodejs 22.14.0`, but the
   workflows install `node-version: "22"` (floating minor). `actions/setup-node` supports
   `node-version-file`, which would read the committed pin the same way the BEAM toolchain now does.
   Deferred: PLAT-01 is scoped to the OTP/Elixir pin, and the floating Node 22 has not caused drift.
2. **SHA-pin every third-party action.** Only the `alls-green` action is SHA-pinned today; every other
   `uses:` reference rides a moving major tag. SHA-pin all third-party actions (with a comment naming
   the tag) as a possible future supply-chain hardening step, ideally with an automated bump path.
3. **Note for the later CI-economy phase.** The `flake-detection` workflow's deps cache key already
   interpolates the resolved toolchain, so it is already contract-compliant. Separately, 216-03's
   all-workflow `cache_key_errors/3` classifier (fed every `.github/workflows/*.{yml,yaml}` file)
   already fails on any cache key led by the OS-family runner value. That phase therefore does not add
   the first guard: it only adds its dedicated all-workflows anti-regression grep, or cites this
   classifier as satisfying it.
  status: acknowledged

## From code review 216-REVIEW.md (recorded 2026-09-27 at phase close)

- **CR-01 (critical, pre-existing before 216, out of PLAT-01..03 scope; awaiting a maintainer decision):** In `.github/workflows/release.yml`, `smoke-published` has no job-level `permissions:`, so it inherits the workflow's `contents: write` / `pull-requests: write` / `issues: write`. Its target-ref checkout persists credentials by default, and the job then compiles hex.pm dependencies (`mix verify.hex_evaluator`). `publish-hex` has the same checkout shape with a read-only token. Proposed fix:
  - add `permissions: contents: read` to `smoke-published`;
  - add `persist-credentials: false` to both target-ref checkouts;
  - widen the release_control_plane credential contract, with a mutation control, to every release.yml job that runs `mix`.
- **WR-01:** CONTRIBUTING repeats the pin literals (27.3.4.15, 1.17.3, 22.14.0) with no contract binding them to `.tool-versions`.
- **WR-02:** The runbook contract (`ci_action_runtime_contract_test.exs:124-158`) is a substring check: `@v5` also matches `@v50`, a stale `Last rehearsal` line still passes, and only the first action ref is checked.
  status: acknowledged
