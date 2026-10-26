---
phase: 246-debt-closeout-and-critic-retirement
artifact: 246-DEBT-REGISTER.md
milestone: v1.47
clause: DEBT-01 (every carried debt item has one recorded, evidenced disposition — closed, waived with a reason, or routed to a named milestone or seed — and no polish-later bucket)
generated: 2026-10-25
seed: .planning/research/QUALITY-ROADMAP-2026-10-24.md §Carried-debt register + 246-CONTEXT.md D-00a..D-00e, D-18, D-19, D-20 + .planning/WINDOWS.md (60 open rows)
verified_against: 37dc883d04a3ead7395f5e6d10f5798b9a84f100
closed: 64
waived: 44
routed: 23
total: 131
status: complete
---

# Phase 246 · v1.47 Carried-Debt Register

**DEBT-01.** This is the single register for every debt item v1.47 inherited. It uses the
197-DESIGN-DEBT-REGISTER.md / 193-RISK-REGISTER.md shape. Each row has one disposition:
`closed` (fixed, with evidence at HEAD or a commit), `waived` (with a reason), or `routed`
(to a named milestone, v1.48 to v1.51, or a seed). The close check
`tools/verify-phase.sh --close` reads this table.

All **131 items** are accounted for (none silently dropped):

- the 12 rows of the QUALITY-ROADMAP carried-debt table, expanded to one row per finding;
- the D-00a..D-00c corrections, which add 223 WR-01..05, the omitted 215/216 findings, the
  218 items, the 221 BASH_ENV advisory, ECON-03 and the 202 flake correction;
- two more 215 findings named in 215-06-SUMMARY.md (CR-01, WR-02), which the original
  register never listed;
- the 11 phase-217 round-1/round-2 review findings;
- the 198 review finding CR-05, which also has WINDOWS row W7 (the two rows cross-reference
  each other and are not merged);
- the 60 open WINDOWS rows, as `W<id>` anchors.

Evidence was re-checked at `37dc883d`. Commits named `(#NN)` are squash merges on main.
Hashes from phase branches that were squashed (for example 217-06's 09817a77) are not
ancestors of HEAD, so those rows cite the squash commit instead.

## Verdict

Most of the carried debt was already paid. 223 WR-01..05 landed in #70 (dd780e68). The
v1.45 review warnings landed in #81 (d56e807c). 245 closed the action-pinning and setup-node
items. Phase 246 fixed five 215/223 findings plus 216 IN-01 (246-05, all test-only), and its
critic removal (slices C1 to C5) made the critic and Dialyzer-slice rows obsolete.

What is still real is routed, never waived:

- **v1.48:** CR-05, the MIX_EXS/MIX_HOME runtime refusal, 216 IN-03 (token in argv),
  ECON-03, and the v1.48 small items (233 IN-01, 234 WR-02, 231 IN-01, the incident_replay
  session config).
- **v1.49:** 216 WR-01/WR-02, the clean_checkout tmp collision, and 215 IN-04.
- **v1.51:** 215 WR-09 with WR-10.
- **SEED-008:** the operator-UI items (DR-243-01, typography, the Redaction copy, and the
  8 screenshot baselines in W14 to W17 and W62).

One disposition departs from D-19's wording: 218 WR-03 is waived, not closed or routed by the
REL-02 test. See its row.

| id | item | source file | evidence | disposition | reason or route |
|---|---|---|---|---|---|
| `223-WR-01` | Vacuous positive control for an allowlisted job's checkout | .planning/milestones/v1.43-phases/223-close-v1-43-audit-debt/223-REVIEW-DISPOSITION.md | dd780e68 (#70); test/threadline/release_control_plane_contract_test.exs:455 | closed | fixed in #70: the positive control now renames the job and proves the allowlist does the exempting |
| `223-WR-02` | `mix_command_position?/1` gaps defeat the D-09 security check | .planning/milestones/v1.43-phases/223-close-v1-43-audit-debt/223-REVIEW-DISPOSITION.md | dd780e68 (#70); test/threadline/release_control_plane_contract_test.exs:395-400 | closed | fixed in #70: wrapper forms (timeout, sudo, nohup, nice, xargs, case arms) are pinned as mix positions |
| `223-WR-03` | `allowlisted-job-runs-no-mix` cannot see into externally invoked scripts | .planning/milestones/v1.43-phases/223-close-v1-43-audit-debt/223-REVIEW-DISPOSITION.md | dd780e68 (#70); .github/workflows/release.yml:787; bin/post-publish-distribution-sync:8 | closed | fixed in #70: the invariant is stated at both ends of the job-to-script boundary |
| `223-WR-04` | `literal_too_broad` guard coverage missed 3 of 9 roots | .planning/milestones/v1.43-phases/223-close-v1-43-audit-debt/223-REVIEW-DISPOSITION.md | dd780e68 (#70); test/threadline/repo_hygiene_guard_test.exs:97-98,499-500 | closed | fixed in #70: every documented root has a guard-test case |
| `223-WR-05` | `newline_status` capture ignores a `git ls-files` failure | .planning/milestones/v1.43-phases/223-close-v1-43-audit-debt/223-REVIEW-DISPOSITION.md | dd780e68 (#70); bin/verify-repo-hygiene:494-498 | closed | fixed in #70: a non-zero `git ls-files` status now dies with a named reason |
| `223-IN-01` | D-18/D-06 CONTRIBUTING wording has no contract test | .planning/milestones/v1.43-phases/223-close-v1-43-audit-debt/223-REVIEW-DISPOSITION.md | 6e439225 (246-05) | closed | fixed in 246-05: repo_hygiene_contract_test and changelog_contract_test pin both sentences, mutation-checked |
| `215-CR-01` | Weekly lane reported clean under an active Hex advisory suppression | .planning/milestones/v1.43-phases/215-supply-chain-gate/215-06-SUMMARY.md | bin/deps-health-report:160-202 | closed | fixed in 215-06: env-var and global hex.config ignores classify unknown before any per-dir call |
| `215-WR-01` | Any `hex.outdated` failure was classified outdated, so the lane stayed green | .planning/milestones/v1.43-phases/215-supply-chain-gate/deferred-items.md | bin/deps-health-report:45-46 | closed | superseded in 245: hex.outdated is no longer run (D-24), so a failed outdated check cannot read as informational |
| `215-WR-02` | Weekly lane fetched without `--check-locked`, so a drifted lock was audited | .planning/milestones/v1.43-phases/215-supply-chain-gate/215-06-SUMMARY.md | bin/deps-health-report:10-12,26 | closed | fixed in 215-06: every fetch runs `mix deps.get --check-locked` |
| `215-WR-03` | Weekly lane accepted a directory with no mix.lock | .planning/milestones/v1.43-phases/215-supply-chain-gate/deferred-items.md | bin/deps-health-report:10-12,26 | closed | fixed through WR-02: `--check-locked` fails when the lock would be created, so a missing lock classifies unknown |
| `215-WR-04` | Ruleset check refuted the workflow name, not the job's check-run name | .planning/milestones/v1.43-phases/215-supply-chain-gate/deferred-items.md | f29a40bf (246-05) | closed | fixed in 246-05: `required_context_hits/2` compares ruleset contexts with the job name, with a negative control |
| `215-WR-05` | `@lockfiles` was a restated literal, not derived from CANONICAL_DIRS | .planning/milestones/v1.43-phases/215-supply-chain-gate/deferred-items.md | 1df4c803 (246-05) | closed | fixed in 246-05: lockfiles derive from `canonical_dir_line!/1` |
| `215-WR-06` | Gate test did not assert exactly three canonical directories | .planning/milestones/v1.43-phases/215-supply-chain-gate/deferred-items.md | f9764172 (246-05) | closed | fixed in 246-05: exact path list, exact hex.info log, refute deps.unlock |
| `215-WR-07` | ci-deps issue title froze at the first classification and never closed | .planning/milestones/v1.43-phases/215-supply-chain-gate/deferred-items.md | bin/upsert-ci-issue:10; .github/workflows/deps-health.yml:134 | closed | fixed in 244/245: upsert retitles on a changed classification and a clean run closes the issue |
| `215-WR-08` | Weekly lane has no Hex version floor | .planning/milestones/v1.43-phases/215-supply-chain-gate/deferred-items.md | test/threadline/hex_pin_contract_test.exs | waived | superseded: CI installs an exact, contract-tested Hex 2.6.0 pin, so no older client can run the audit |
| `215-WR-09` | deps-health-report suppression mirror has no live proof against real Hex | .planning/milestones/v1.43-phases/215-supply-chain-gate/215-REVIEW.md | bin/deps-health-report:170 (no --self-test) | routed | v1.51 with 215-WR-10: the dedupe makes `bin/verify-deps-audit --self-test` prove both copies; a silent clean-under-suppression is security-relevant, so not waived |
| `215-WR-10` | Duplicated ~45-line `read_global_hex_ignore` | .planning/milestones/v1.43-phases/215-supply-chain-gate/215-REVIEW.md | bin/deps-health-report:170; bin/verify-deps-audit:335 | routed | v1.51 (lean tree, shared helpers), together with 215-WR-09 |
| `215-IN-01` | Step output interpolated directly into a `run:` script | .planning/milestones/v1.43-phases/215-supply-chain-gate/deferred-items.md | .github/workflows/deps-health.yml:85,144 | closed | fixed in 244/245: the classification reaches shell only through `env: CLASSIFICATION` |
| `215-IN-02` | `printf \| grep -q` under pipefail can report a spurious red | .planning/milestones/v1.43-phases/215-supply-chain-gate/deferred-items.md | bin/verify-deps-audit:167,195 | closed | fixed: the self-test greps here-strings, so no SIGPIPE can occur |
| `215-IN-03` | Tautological assertions in the report and doc tests | .planning/milestones/v1.43-phases/215-supply-chain-gate/deferred-items.md | 9ff63692 (246-05) | closed | fixed in 246-05: both vacuous assertions deleted; WR-04 is the real guard |
| `215-IN-04` | Report truncation can leave an unclosed code fence and drop the footer | .planning/milestones/v1.43-phases/215-supply-chain-gate/deferred-items.md | bin/deps-health-report:440-443 | routed | v1.49: the fix is a bin behaviour change, which is not D-17-cheap |
| `215-IN-05` | A wrapped Hex line starting with `[` could cause a false-positive refusal | .planning/milestones/v1.43-phases/215-supply-chain-gate/215-REVIEW.md | bin/deps-health-report:185 | waived | low value: the failure mode is a false refusal (fails closed), never a false clean |
| `215-IN-06` | Self-test case (d) drift is a constraint substitution, not an independent resolution | .planning/milestones/v1.43-phases/215-supply-chain-gate/215-REVIEW.md | bin/verify-deps-audit (self-test case d) | waived | low value: the case still proves the drift path fails; a second resolver adds network cost |
| `T-215-36` | MIX_EXS/MIX_HOME can redirect per-dir Mix calls at runtime | .planning/milestones/v1.43-phases/215-supply-chain-gate/deferred-items.md | bin/deps-health-report and bin/verify-deps-audit have no MIX_EXS or MIX_HOME refusal | routed | v1.48 (safe by default): security angle and a bin change, so D-17 forbids a waiver |
| `216-CR-01` | smoke-published persisted a write token, then compiled Hex code | .planning/milestones/v1.43-phases/216-ci-platform-currency/216-REVIEW.md | .github/workflows/release.yml:729-734; db8d5373 (#66) | closed | fixed: every release.yml checkout sets `persist-credentials: false`; 245 SC2 re-verified the workflow set |
| `216-WR-01` | CONTRIBUTING hard-codes the toolchain pins with no contract to .tool-versions | .planning/milestones/v1.43-phases/216-ci-platform-currency/216-REVIEW.md | CONTRIBUTING.md (pin literals) | routed | v1.49 (honest specs): needs a new contract test group |
| `216-WR-02` | Release Please runbook contract is a substring check | .planning/milestones/v1.43-phases/216-ci-platform-currency/216-REVIEW.md | test/threadline/ci_action_runtime_contract_test.exs (runbook block) | routed | v1.49 (honest specs): tighten with exact matches and a stale-rehearsal check |
| `216-IN-01` | Cache-key contract accepts any `ubuntu-24.04-` prefix regardless of `runs-on` | .planning/milestones/v1.43-phases/216-ci-platform-currency/216-REVIEW.md | 46efd9d4 (246-05) | closed | fixed in 246-05 within D-17: `runner_label_errors/3` plus a `runs-on: ubuntu-26.04` mutation control |
| `216-IN-02` | .tool-versions pins Node 22.14.0 but CI floated on "22" (same defect as 216-SETUP-NODE) | .planning/milestones/v1.43-phases/216-ci-platform-currency/216-REVIEW.md | 245-VERIFICATION.md SC2; .github/workflows/ci.yml:684,889,1052 | closed | fixed in 245 SC2: every setup-node reads `node-version-file: .tool-versions`; see 216-SETUP-NODE |
| `216-IN-03` | Runbook puts the GitHub token in argv and uses a GNU-only sed escape | .planning/milestones/v1.43-phases/216-ci-platform-currency/216-REVIEW.md | CONTRIBUTING.md:1205,1207 | routed | v1.48 (safe by default): credential angle and not test-only, so D-17 forbids a waiver |
| `216-IN-04` | The same toolchain-pin comment is copied three times | .planning/milestones/v1.43-phases/216-ci-platform-currency/216-REVIEW.md | .github/workflows/release.yml (3 copies of the setup-beam comment) | waived | comment drift only; the fix edits .github/workflows/, which is not D-17-cheap |
| `216-IN-05` | Node 24 allowlist verified floating major tags (same defect class as 216-SHA-PINNING) | .planning/milestones/v1.43-phases/216-ci-platform-currency/216-REVIEW.md | 245-VERIFICATION.md SC2; test/threadline/ci_action_pin_contract_test.exs | closed | fixed in 245 SC2: every `uses:` is a full SHA with a version comment; see 216-SHA-PINNING |
| `216-SHA-PINNING` | SHA-pin every third-party action | .planning/milestones/v1.43-phases/216-ci-platform-currency/deferred-items.md | 245-VERIFICATION.md SC2 (0 of 79 tag-only refs); test/threadline/ci_action_pin_contract_test.exs | closed | fixed in 245 SC2, with a PIN-FORM negative control |
| `216-SETUP-NODE` | Align setup-node with .tool-versions (OD-5) | .planning/milestones/v1.43-phases/216-ci-platform-currency/deferred-items.md | 245-VERIFICATION.md SC2; .github/workflows/browser-full.yml:103 | closed | fixed in 245 SC2; same defect as 216-IN-02 |
| `217-R1-CR-01` | Family-6 Claude-encoded project dir regex missed a real path shape | .planning/milestones/v1.43-phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md | 3c4ac9b1 (#60) | closed | fixed in 217-06 Task 1, landed in #60 |
| `217-R1-WR-01` | Summary line printed `(.planning/ absent)` unconditionally | .planning/milestones/v1.43-phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md | 3c4ac9b1 (#60) | closed | fixed in 217-06 Task 2, landed in #60 |
| `217-R1-WR-02` | Colon-containing filenames defeated `git grep` line parsing | .planning/milestones/v1.43-phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md | 3c4ac9b1 (#60) | closed | fixed in 217-07 Task 2, landed in #60 |
| `217-R1-WR-03` | Home-directory safety-net test checked 2 of 7 pattern families | .planning/milestones/v1.43-phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md | 3c4ac9b1 (#60) | closed | fixed in 217-06 Task 2, landed in #60 |
| `217-R1-IN-01` | Missing-git exit-2 case had no check and the wrong reason | .planning/milestones/v1.43-phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md | 3c4ac9b1 (#60) | closed | fixed in 217-06 Task 2, landed in #60 |
| `217-R2-WR-01` | `forbidden_home_literal?/1` passed ancestor-prefix literals | .planning/milestones/v1.43-phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md | db8d5373 (#66) | closed | fixed in 223-02 Task 3, landed in #66 |
| `217-R2-WR-02` | Widened family-6 regex flagged ordinary TitleCase kebab words | .planning/milestones/v1.43-phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md | db8d5373 (#66) | closed | fixed in 223-02 Task 2, landed in #66 |
| `217-R2-WR-03` | A newline in a tracked filename mis-scoped the hit | .planning/milestones/v1.43-phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md | db8d5373 (#66); bin/verify-repo-hygiene:494-498 | closed | fixed in 223-02 Task 3, landed in #66 |
| `217-R2-WR-04` | CONTRIBUTING claimed Linux-encoded project dirs were detected | .planning/milestones/v1.43-phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md | db8d5373 (#66) | closed | fixed in 223-02 Task 1, landed in #66 |
| `217-R2-IN-01` | Failure-hint contract test passed with the hint deleted | .planning/milestones/v1.43-phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md | db8d5373 (#66) | closed | fixed in 223-03 Task 1, landed in #66 |
| `217-R2-IN-02` | "No file or directory is exempt" contradicted the allowlist self-exclusion | .planning/milestones/v1.43-phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md | db8d5373 (#66); 6e439225 (246-05) | closed | fixed in 223-03 Task 2 (#66); the reworded sentence is now contract-pinned (223-IN-01) |
| `218-DIALYZER-SLICE-LINE` | Live Dialyzer slice line not quotable from the CI log | .planning/milestones/v1.43-phases/218-ci-economy-remove-waste/deferred-items.md | 4b2c3f89 (C1) | waived | obsolete with DEBT-02: the critic-tooling slice fixture it would quote was removed in C1 |
| `218-BROWSER-FULL-TIER-A` | Browser-full ran tier-a-capture as refute-capture's dependency | .planning/milestones/v1.43-phases/218-ci-economy-remove-waste/deferred-items.md | 9ea29dc4 (C3a); bin/browser-full-projects | closed | fixed via D-05: both capture projects left the Playwright config in C3a, and no project declares a CI dependency today |
| `218-WR-03` | `broken-upstream` refusal applies on manual dispatch too | .planning/milestones/v1.43-phases/218-ci-economy-remove-waste/deferred-items.md | bin/ci-sha-gate:32-36; test/threadline/ci_sha_gate_contract_test.exs:106-110 | waived | locked maintainer decision 218 D-04: the refusal is designed and contract-pinned, and unrelated to REL-02. Deviation from D-19, which framed this row with ECON-03/REL-02 |
| `221-BASH-ENV` | Lane-level BASH_ENV advisory from the 221 verification | .planning/milestones/v1.43-phases/221-ci-names-and-order/221-VERIFICATION.md | test/threadline/ci_workflow_parity_contract_test.exs:1856 (rule=gate-bash-env), :1793-1796 | closed | the rule bans a key-spelled BASH_ENV and the comment now states its scope, which was the 221 resolution |
| `ECON-03` | One CI run per release PR is still unconfirmed | .planning/milestones/v1.43-MILESTONE-AUDIT.md | .planning/phases/244-release-flow/244-REL02-EVIDENCE.md:3 (Status: pending) | routed | v1.48: confirmed by the first natural release cycle, the same trigger as the REL-02 observation |
| `202-CRITIC-TRUST-FLAKE` | critic_trust_test scratch-path collision (unique_integer restarts per VM) | .planning/milestones/v1.41-phases/202-release-0-10-0/202-05-SUMMARY.md | 4b2c3f89 (C1) | waived | obsolete with DEBT-02: critic_trust_test.exs was deleted in C1 |
| `231-WR-01` | Invalid actor references crashed instead of returning a validation error | .planning/milestones/v1.45-phases/231-facade-topology-and-the-capture-semantics-edge/231-REVIEW-DISPOSITION.md | d56e807c (#81); lib/threadline/audit.ex:216 | closed | fixed in #81; the stale disposition row is hand-fixed in this plan |
| `233-WR-01` | A malformed binary id short-circuited a missing `:repo` | .planning/milestones/v1.45-phases/233-lookup-return-shapes/233-REVIEW.md | d56e807c (#81); lib/threadline/query/transaction_lookup.ex:69 | closed | fixed in #81: `:repo` is fetched before the id is resolved; 233 has no disposition file to fix |
| `234-WR-01` | A present malformed serialized actor_ref was classified as missing | .planning/milestones/v1.45-phases/234-typespec-and-doc-completion-gate/234-REVIEW-DISPOSITION.md | d56e807c (#81); lib/threadline/job.ex:80 | closed | fixed in #81: a malformed map returns `:invalid_actor_ref_map` |
| `231-IN-01` | incident_replay.exs reads audit_transactions with raw SQL instead of a facade helper | .planning/milestones/v1.45-phases/231-facade-topology-and-the-capture-semantics-edge/231-REVIEW-DISPOSITION.md | examples/threadline_phoenix/priv/scripts/incident_replay.exs:141,167 | routed | v1.48 small items, with INCIDENT-REPLAY-SESSION |
| `233-IN-01` | `NotFoundError.message/1` matches a bare map, not the exception struct | .planning/milestones/v1.45-phases/233-lookup-return-shapes/233-REVIEW.md | lib/threadline/not_found_error.ex:31 | routed | v1.48 small items |
| `234-WR-02` | Capture-boundary test helper misses grouped aliases | .planning/milestones/v1.45-MILESTONE-AUDIT.md (in git at 22254954, line 125) | 22254954 | routed | v1.48 small items |
| `INCIDENT-REPLAY-SESSION` | incident_replay.exs uses a session-level `set_config` (third arg false) | .planning/research/QUALITY-ROADMAP-2026-10-24.md | examples/threadline_phoenix/priv/scripts/incident_replay.exs:92 | routed | v1.48 small items, with 231-IN-01 |
| `GEN-TRIGGERS-DOWN` | gen.triggers `down` orphaned the rerun per-table function | .planning/milestones/v1.42-MILESTONE-AUDIT.md | lib/mix/tasks/threadline.gen.triggers.ex:601-617 | closed | fixed: `down_body/2` drops rerun functions with a rollback comment |
| `GEN-BACKFILL-INVALID-CONFIG` | gen.backfill task and an `:invalid_config` finding | .planning/milestones/v1.42-MILESTONE-AUDIT.md | .planning/milestones/v1.44-phases/229-adopter-api-and-health-additions/229-CONTEXT.md:16 | waived | anti-feature: v1.44 rejected both as durable non-goals |
| `PARTITION-WEIGHTS` | Partition weights were missing the property test files | .planning/research/QUALITY-ROADMAP-2026-10-24.md | test/partition_weights.txt:28,33 (13 property rows) | closed | fixed; the close check's partition rule proves every row names an existing file |
| `BENCH-COMPILE` | Bench project compile was not gated | .planning/research/QUALITY-ROADMAP-2026-10-24.md | .github/workflows/ci.yml:224-225 (mix verify.bench_compile) | closed | fixed: CI compiles the bench project |
| `CLEAN-CHECKOUT-TMP` | clean_checkout temp-dir name can collide across VMs | .planning/milestones/v1.43-phases/218-ci-economy-remove-waste/deferred-items.md | test/threadline/clean_checkout_contract_test.exs:339 | routed | v1.49 (honest specs): move to `@tag :tmp_dir` |
| `VERIFY-TEMP-LEAKS` | `verify.temp_leaks` does not run continuously | .planning/research/QUALITY-ROADMAP-2026-10-24.md | mix.exs:198-199,315 | waived | opt-in by design: it wraps an explicit `mix test` run |
| `V142-GUIDE-IN-01` | pk_drift-on-refused-type explanation is dense trailing prose | .planning/milestones/v1.42-MILESTONE-AUDIT.md | .planning/milestones/v1.42-MILESTONE-AUDIT.md:21 | waived | historical prose review note; no reader-facing defect was reported |
| `V142-GUIDE-IN-02` | 3+ column composite-key backfill is described, not shown | .planning/milestones/v1.42-MILESTONE-AUDIT.md | .planning/milestones/v1.42-MILESTONE-AUDIT.md:22 | waived | historical prose review note; backfill stays an anti-feature (GEN-BACKFILL-INVALID-CONFIG) |
| `SEED-005` | Reconnect banner shell mount | .planning/seeds/SEED-005-reconnect-banner-shell-mount.md | lib/threadline/operator_surface/ui/page.ex:295; lib/threadline/operator_surface/script.ex:58,101 | closed | shipped; the seed moves to the SEED-006 closure schema in this plan |
| `DR-243-01` | History drawer title partly under the fixed header (medium) | .planning/milestones/v1.46-MILESTONE-AUDIT.md | .planning/milestones/v1.46-MILESTONE-AUDIT.md:121 | routed | SEED-008 (operator-UI carry; UI parked until 1.0.0) |
| `UI-TYPOGRAPHY` | Dense typography uses sizes outside the four-size contract | .planning/milestones/v1.46-MILESTONE-AUDIT.md | .planning/milestones/v1.46-MILESTONE-AUDIT.md:122 | routed | SEED-008 (operator-UI carry) |
| `UI-REDACTION-COPY` | Redaction empty-category copy reads awkwardly beside the zero-row heading | .planning/milestones/v1.46-MILESTONE-AUDIT.md | lib/threadline/operator_surface/live/policy_redaction_live.ex:450-454 | routed | SEED-008 (operator-UI carry) |
| `198-CR-05` | Ruleset snapshot never diffed against live bypass_actors (same defect as W7) | .planning/milestones/v1.41-phases/198-green-bringup/198-VERIFICATION.md | bin/verify-branch-protection has no bypass check; .github/rulesets/main.json:5 | routed | v1.48 (safe by default); WINDOWS row W7 carries the same defect |
| <a id="W1"></a>W1 | GREEN-11 two-dispatch flake-issue dedup was never run live | .github/workflows/flake-detection.yml | .github/workflows/flake-detection.yml:297,320; test/threadline/ci_issue_upsert_contract_test.exs | closed | Fixed: dedup moved to bin/upsert-ci-issue (218-02), which is contract-tested and runs on main |
| <a id="W3"></a>W3 | mix ci.all failed at verify.example (DemoContractTest) | .planning/milestones/v1.41-phases/198-green-bringup/deferred-items.md | 3d148435 (#26, 0.10.0) | closed | Fixed: ci.all and verify.example have been green on main since the v1.41 landing |
| <a id="W4"></a>W4 | GREEN-07 not verified; origin/main CI red | .planning/milestones/v1.41-phases/198-green-bringup/198-13-SUMMARY.md | 3d148435 (#26, 0.10.0) | closed | Fixed: main CI went green at the v1.41 landing and has released since |
| <a id="W5"></a>W5 | CR-03: contents read token could not tell a 403 from absent classic protection | .github/workflows/branch-protection.yml | bin/verify-branch-protection:111-163 | closed | Fixed: a 403 falls back to branch metadata, and an unverifiable answer is reported PARTIAL instead of OK |
| <a id="W6"></a>W6 | CR-04: empty check-run count was treated as a pass | bin/verify-branch-protection | bin/verify-branch-protection:94-103 | closed | Fixed: an empty or failed count is coerced to 0 and fails block b |
| <a id="W7"></a>W7 | CR-05: ruleset snapshot never diffed against live state (same defect as 198-CR-05) | .github/rulesets/main.json | bin/verify-branch-protection has no bypass_actors diff; .github/rulesets/main.json:5 | routed | Routed to v1.48 (safe by default), with 198-CR-05 |
| <a id="W8"></a>W8 | 28 browser failures hidden by maxFailures 5 | .planning/milestones/v1.41-phases/198-green-bringup/198-17-SUMMARY.md | .planning/milestones/v1.41-phases/201-rendered-output/201-VERIFICATION.md (lane at the 8 known screenshot failures) | closed | Fixed: phase 198 rounds 4 and 5 cleared them; only the 8 screenshot baselines remain (W62, SEED-008) |
| <a id="W9"></a>W9 | Mobile focus flake on #stress-dropdown-button | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts:1078 | waived | Not reproduced: the browser lane has run at exactly the 8 screenshot failures since phase 201, with this test passing on both projects |
| <a id="W10"></a>W10 | Exports Expired text not found (accessibility spec) | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts:796 | closed | Fixed: the assertion matches Export expired (settled by W20) |
| <a id="W11"></a>W11 | Exports dense Expired text not found (prove-mobile spec) | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts:65 | closed | Fixed: the assertion matches Export expired (settled by W21) |
| <a id="W12"></a>W12 | Root cause of W10: label changed to Export expired | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts:794-796 | closed | Fixed: regex re-anchored in plan 198-31 |
| <a id="W13"></a>W13 | Root cause of W11: same label change | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts:63-65 | closed | Fixed: regex re-anchored in plan 198-31 |
| <a id="W14"></a>W14 | Dense Timeline screenshot baseline diff | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts:108 | routed | Routed to SEED-008 (screenshot baselines wait for the UI work) |
| <a id="W15"></a>W15 | Row-history drawer screenshot baseline diff | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts:115 | routed | Routed to SEED-008 (screenshot baselines wait for the UI work) |
| <a id="W16"></a>W16 | Exports screenshot baseline diff | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts:136 | routed | Routed to SEED-008 (screenshot baselines wait for the UI work) |
| <a id="W17"></a>W17 | Retention screenshot baseline diff | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts:145 | routed | Routed to SEED-008 (screenshot baselines wait for the UI work) |
| <a id="W18"></a>W18 | demo_reset_test CI-only ExUnit timeout | examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs | examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs:22 | closed | Fixed: the cold prod compile runs in setup_all (settled by W22) |
| <a id="W19"></a>W19 | Row history heading not found on mobile (CI-only) | examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts | examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts:278-292 | closed | Fixed: exerciseMobileNav opt-out for the row-history route (settled by W23) |
| <a id="W20"></a>W20 | Settles W10/W12: regex fixed | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts | examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts:796 | closed | Fixed: the settling fix is present at HEAD |
| <a id="W21"></a>W21 | Settles W11/W13: regex fixed | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts:65 | closed | Fixed: the settling fix is present at HEAD |
| <a id="W22"></a>W22 | Settles W18: compile moved to setup_all | examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs | examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs:15-34 | closed | Fixed: the settling fix is present at HEAD |
| <a id="W23"></a>W23 | Settles W19: mobile-nav opt-out | examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts | examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts:278-292 | closed | Fixed: the settling fix is present at HEAD |
| <a id="W24"></a>W24 | state.advance-plan parsed the legacy position | .planning/STATE.md | .planning/milestones/v1.41-phases/198-green-bringup/198-VERIFICATION.md | waived | Obsolete process record: a GSD bookkeeping reconciliation for a closed phase; no code defect |
| <a id="W25"></a>W25 | state.advance-plan incremented stale prose position | .planning/STATE.md | .planning/milestones/v1.41-phases/198-green-bringup/198-VERIFICATION.md | waived | Obsolete process record: a GSD bookkeeping reconciliation for a closed phase; no code defect |
| <a id="W26"></a>W26 | Plan verify used an unsupported mix test -x flag | test/threadline/operator_surface/operator_surface_fixture_contract_test.exs | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: the plan command was corrected at execution time; no code defect |
| <a id="W27"></a>W27 | roadmap.update-plan-progress could not write the legacy 199 row | .planning/ROADMAP.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: roadmap bookkeeping for an archived phase |
| <a id="W28"></a>W28 | Plan 199-09 verify used an unsupported mix test -x flag | test/threadline/removed_artifact_contract_test.exs | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: the plan command was corrected at execution time; no code defect |
| <a id="W29"></a>W29 | Plan 199-09 roadmap progress reconciled by hand | .planning/ROADMAP.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: roadmap bookkeeping for an archived phase |
| <a id="W30"></a>W30 | Plan 199-10 replaced an unsupported mix test -x flag | test/threadline/clean_checkout_contract_test.exs | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: the plan command was corrected at execution time; no code defect |
| <a id="W31"></a>W31 | Bench entrypoints had formatter drift | bench/audit_capture_bench.exs | `mix format --check-formatted` clean at HEAD (246-05) | closed | Fixed: formatted in plan 199-10 and covered by the child-aware format gate since |
| <a id="W32"></a>W32 | Plan 199-10 roadmap progress reconciled by hand | .planning/ROADMAP.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: roadmap bookkeeping for an archived phase |
| <a id="W33"></a>W33 | Eight 199 summary-backed plans reconciled by hand | .planning/ROADMAP.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: roadmap bookkeeping for an archived phase |
| <a id="W34"></a>W34 | Pair-label token wiring unimplemented in critic/label.ts | examples/threadline_phoenix/e2e/critic/label.ts | cbb804a6 (C2) | waived | Obsolete with DEBT-02: critic/label.ts was deleted in C2 |
| <a id="W35"></a>W35 | Plan 199-05 roadmap progress reconciled by hand | .planning/ROADMAP.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: roadmap bookkeeping for an archived phase |
| <a id="W36"></a>W36 | Plan 199-11 progress reconciled by hand | .planning/ROADMAP.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: roadmap bookkeeping for an archived phase |
| <a id="W37"></a>W37 | critic-scores destination parent created after a git mv | test/fixtures/operator_surface/critic-scores/.gitkeep | 35243789 (C4) | waived | Obsolete with DEBT-02: the critic-scores directory was deleted in C4 |
| <a id="W38"></a>W38 | Fixture corpus validator adapted to mechanical floors and scorecards | test/threadline/operator_surface/operator_surface_fixture_contract_test.exs | 35243789 (C4); 1258c014 (C3b) | waived | Obsolete with DEBT-02: the mechanical floor and scorecard corpus were removed in C3b and C4 |
| <a id="W39"></a>W39 | Plan 199-08 replaced an unsupported mix test -x flag | .planning/milestones/v1.41-phases/199-decouple/199-08-PLAN.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: the plan command was corrected at execution time; no code defect |
| <a id="W40"></a>W40 | Refute and scorecard outputs restored after a directory git mv | .planning/refute/transcripts/refute.veto-ordering.off-token-accent.json | 35243789 (C4) | waived | Obsolete with DEBT-02: the refute corpus is gone and .planning/refute no longer exists |
| <a id="W41"></a>W41 | Plan 199-08 roadmap progress reconciled by hand | .planning/ROADMAP.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: roadmap bookkeeping for an archived phase |
| <a id="W42"></a>W42 | Full-build Dialyzer red (22-file warning set) | test/threadline/dialyzer_ignore_contract_test.exs | .dialyzer_ignore.exs is `[]`; test/threadline/dialyzer_ignore_contract_test.exs:35-37 | closed | Fixed: every sealed warning is dispositioned fixed and the ignore list is empty |
| <a id="W43"></a>W43 | Plan 199-13 Task 2 verification not run (re-plan gate) | .planning/milestones/v1.41-phases/199-decouple/199-13-PLAN.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md (40/40) | waived | Obsolete process record: the re-planned 199 plans ran and the phase verified 40/40 |
| <a id="W44"></a>W44 | Plan 199-13 halted; roadmap row hand-marked | .planning/ROADMAP.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: roadmap bookkeeping for an archived phase |
| <a id="W45"></a>W45 | Plan 199-15 checklist row hand-marked | .planning/ROADMAP.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: roadmap bookkeeping for an archived phase |
| <a id="W46"></a>W46 | state.advance-plan used the stale pre-replan position | .planning/STATE.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: a GSD bookkeeping reconciliation for a closed phase |
| <a id="W47"></a>W47 | Temporary named Node tests for source-verifier RED evidence | .planning/milestones/v1.41-phases/199-decouple/199-17-SUMMARY.md | bin/verify-dialyzer-slice; test/threadline/dialyzer_slice_contract_test.exs | waived | Obsolete process record: throwaway RED scaffolding; the slice verifier is contract-tested at HEAD |
| <a id="W48"></a>W48 | Roadmap progress reconciled after missing_phase_details | .planning/ROADMAP.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: roadmap bookkeeping for an archived phase |
| <a id="W49"></a>W49 | Plan 199-19 roadmap progress reconciled by hand | .planning/ROADMAP.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: roadmap bookkeeping for an archived phase |
| <a id="W50"></a>W50 | Temporary measurement-branch push trigger added and removed | .github/workflows/ci.yml | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: the trigger was removed after evidence collection |
| <a id="W51"></a>W51 | Tracer workflow-header matcher corrected | test/threadline/ci_topology_contract_test.exs | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: an in-plan correction, already applied |
| <a id="W52"></a>W52 | Plan 199-14 roadmap progress reconciled by hand | .planning/ROADMAP.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: roadmap bookkeeping for an archived phase |
| <a id="W53"></a>W53 | Two pre-existing contract files had formatter drift | test/threadline/main_ci_observer_contract_test.exs | `mix format --check-formatted` clean at HEAD (246-05) | closed | Fixed: formatted in plan 199-21 and covered by the aggregate format gate |
| <a id="W54"></a>W54 | Hidden planning dereferences removed; clean-clone prerequisites supplied | test/threadline/removed_artifact_contract_test.exs | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: an in-plan change, already applied |
| <a id="W55"></a>W55 | Local aggregate Dialyzer env aligned with CI | mix.exs | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: an in-plan change, already applied |
| <a id="W56"></a>W56 | Cross-scroll-state geometry sampling fixed | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts | examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts:139 | closed | Fixed: the single-scroll-state sampling is present at HEAD |
| <a id="W57"></a>W57 | Plan 199-21 final roadmap row reconciled by hand | .planning/ROADMAP.md | .planning/milestones/v1.41-phases/199-decouple/199-VERIFICATION.md | waived | Obsolete process record: roadmap bookkeeping for an archived phase |
| <a id="W61"></a>W61 | verify.format blocked by a mechanical_checker.ex format defect | lib/threadline/operator_surface/mechanical_checker.ex | 1258c014 (C3b) | waived | Obsolete with DEBT-02: mechanical_checker.ex was deleted in C3b |
| <a id="W62"></a>W62 | The 8 pre-existing screenshot-regression failures (gate amendment) | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts | examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts:108,115,136,145 | routed | Routed to SEED-008 (baselines last written in 180-04 and never regenerated) |
| <a id="W63"></a>W63 | 0.10.0 publish blocked by three born-red causes | .planning/milestones/v1.41-phases/202-release-0-10-0/202-05-PLAN.md | 3d148435 (#26); tag v0.10.0 | closed | Fixed: 0.10.0 published, and every release since has shipped |
| <a id="W64"></a>W64 | Adopt landing links added to the guide graph | guides/getting-started-saas.md | .planning/milestones/v1.45-phases/235-stability-contract-and-adopter-guides/235-VERIFICATION.md | waived | Obsolete process record: an in-plan doc change, already applied |

**No polish-later bucket exists.** Every `routed` row names v1.48, v1.49, v1.51 or SEED-008,
and each route also appears in `.planning/research/QUALITY-ROADMAP-2026-10-24.md` or in
`.planning/seeds/SEED-008-operator-ui-carry.md`. Every `waived` row gives its reason. Every
`closed` row cites a file:line at `37dc883d` or a commit on main.

## Boundary Check

- No `waived` row has a credential, injection or other security angle without being D-17-cheap.
  Rows with that angle (T-215-36, 216-IN-03, 215-WR-09, 198-CR-05 / W7) are routed.
- `.planning/WINDOWS.md` is not edited here. Plan 246-07 writes the 60 W rows through
  `gsd-tools windows fixed|waive`, using this table's dispositions (`routed` rows are written
  with `waive` and a route reason, because the ledger has no routed status).
- 245 IN-01..07 and 245 WR-01 stay in 245's own disposition file (D-00c) and are not rows here.
- The 231 stale disposition row is hand-edited in this plan. The gsd-core disposition step is
  never run over 231, 233 or 234 files, because it drops reused ids.
