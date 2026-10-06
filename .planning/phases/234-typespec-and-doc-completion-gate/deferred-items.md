# Deferred Items — Phase 234 Plan 15

## Plan 20: CI closeout gate remains open

- **Evidence:** On 2026-10-06, `mix ci.all` ran with writable Git metadata and isolated Hex/npm caches. All lanes passed except `verify.example_browser`: Playwright reported 313 passed, 26 skipped, 4 flaky, and 1 failed. The sole failure was `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts:323`; its “Show Drawer” click timed out twice because the open modal intercepted the click.
- **Scope:** This E2E failure is in an unrelated example browser test and outside Plan 20's declared source scope. It was not changed.
- **Disposition:** Plan 20 does not close SPEC-02. Keep its checkbox and traceability row Pending until the canonical CI gate passes. D-46 fresh review and report integrity passed; focused tests, strict Dialyzer, and warning-free dev docs passed. `mix ci.all` exited 1, so no successful Plan 20 summary is justified.

## Resolved: required full verification

- **Initial sandbox run:** `mix ci.all` reached the test/browser lanes but exited non-zero because sandbox permissions blocked a temporary linked worktree under `.git/worktrees`, writes to Hex/npm caches, and Playwright's browser cache lock. The earlier dependency advisory findings were resolved by Plan 19's source-guarded, accountable acknowledgements; the dependency graph and lockfiles remain unchanged.
- **Resolution:** The canonical `mix ci.all` command was rerun with the required filesystem/cache access and exited zero on 2026-10-06. It passed 3,006 root tests, 130 example tests, strict Dialyzer (0 errors), the live Dialyzer slice (17 tests, 0 failures), npm audit (0 vulnerabilities), and the desktop/mobile Playwright lane (318 passed, 26 intentionally skipped). The standalone advisory contracts passed 19/19 and `mix verify.deps_audit` passed across all three lockfiles.
- **Disposition:** No dependency or lockfile changes were needed. Plan 15 reconciled T-234-26 from the fresh CI and evidence gates, set security to verified with zero open high threats, marked SPEC-02 Complete, and set validation to Nyquist-compliant. The low-severity T-234-08 and T-234-13 items remain explicitly open below the blocking threshold.

## Resolved: Plan 22 canonical CI environment flakiness

- **Initial evidence:** On 2026-10-06, an initial `mix ci.all` run passed the root tests, example tests, and Dialyzer lanes but failed in the browser lane amid host Git configuration and resource noise. The first browser attempt reported an accessibility dropdown interaction failure, while retries showed the case was flaky; a focused rerun also hit an OS `enfile` resource error.
- **Resolution:** The canonical `mix ci.all` command was rerun against the final corrected source with `GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null` and browser-cache access. It passed 3,016 root tests (0 failures, 3 excluded), 130 example tests (0 failures), strict Dialyzer (0 errors), live Dialyzer (17 tests, 0 failures), npm audit (0 vulnerabilities), and Playwright (318 passed, 26 skipped). The accessibility case passed in this final run. The root Git clone contract also passed 9/9 with the same Git-config isolation. An unprivileged rerun stopped at the browser lane because it could not create Playwright's cache lock; the cache-enabled canonical rerun passed.
- **Disposition:** The earlier failures were environment flakiness, not a remaining Plan 22 source defect. The canonical CI, strict Dialyzer, warning-free docs build, and fresh independent D-46 PASS with report-integrity validation are green. SPEC-02 remains Pending until phase re-verification, and Phase 234 remains In Progress.
