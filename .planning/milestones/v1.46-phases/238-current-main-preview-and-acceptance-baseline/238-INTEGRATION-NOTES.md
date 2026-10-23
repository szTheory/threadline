# Phase 238 integration notes

## Wave 2

- Wave 1: strict compile and 32 properties / 3064 tests passed, seed 524535.
- First wave-2 run: two frozen-rendered-corpus contract failures caused by new generic route inventory. Fixed in `e36bd1f8`; 15 focused tests passed including an unknown-reference negative control. Existing 427 reference hashes and manifest remain unchanged.
- First rerun: one unchanged health test failed because the orchestrator chose an overly long `MIX_TEST_PARTITION`, exceeding a PostgreSQL role identifier limit. Use short root-suite partitions such as `tl238_<unique>`. Browser evidence retains its required `operator_` prefix.
- Second rerun, seed 549841: three unchanged `RowHistoryIndexExplainTest` assertions selected `audit_changes_table_name_idx` instead of `audit_changes_row_history_idx`. No query/index implementation or that test changed from immutable main. Isolated fresh-database rerun passed 3/3. This is observed suite-order/planner sensitivity, not a demonstrated UI regression; exact underlying cause remains unproven.
- Full confirmation with wave-1 seed 524535 passed: 32 properties, 3065 tests, 0 failures, 3 standard exclusions; 153.4s. Do not hide the failed random seed or claim the entire suite is flake-free. Carry the planner-test sensitivity to Phase 243 integrated verification for reproduction/triage; current baseline scope does not change query APIs/index behavior.

## Wave 3 and final review gate

- Initial combined run: four failures. One real integration omission (new test absent from partition_weights.txt) fixed in `2a1887e9`; three failures required writable caches and allowed temporary git-worktree access. No product test was excluded.
- Security review closed two reproduced tooling gaps; code review closed four reproduced findings, with original report and independent repair report retained. Disposition: zero open.
- Final repaired source under the repository's established Bash 5 environment: `mix verify.test --seed 524535` →32 properties, 3075 tests, 0 failures, 3 standard exclusions, 141.9 seconds. Log `/tmp/threadline-238-final-bash5-tests.log`. Earlier green 32/3075 run at `2a1887e9` is historical.
- Additional default macOS Bash 3 full run exposed 29 failures in unchanged `bin/verify-repo-hygiene` empty-array behavior. That script has no diff against immutable base. This is pre-existing tooling portability debt; the new browser runner itself now passes 23 Node contracts under both Bash 3and Bash 5. Keep Bash 5 for full repository verification; do not infer the entire repository supports Bash 3.
- Focused home browser selection passes 1/1 and explicitly labels partial evidence. Final full route batch 12 passes + 1 intentional legacy-writer skip; dark 11 and System/light 11 pass. Selected renamed-manifest positive and forged base/hash/missing output negatives pass in explicit live mode; preview-required 10/10 pass.
- Committed phase evidence paths now resolve relative to the retained worktree; absolute local process receipts remain untracked. Actual `bin/verify-repo-hygiene` is clean in the implementation worktree.
- First v1.46 phase: no prior completed current-milestone phases for the regression subgate. Archived/prior-milestone verification files in the source base do not make them current-milestone regressions. The full suite above covers existing behavior.
- No remote CI, PR, push, merge or publication performed. Product UI/source, public API, auth, scope and redaction semantics remain unchanged.
