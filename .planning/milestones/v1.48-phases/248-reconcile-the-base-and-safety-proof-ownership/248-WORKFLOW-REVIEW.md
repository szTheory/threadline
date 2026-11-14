# Phase 248-04 Independent Workflow Review — Refresh

**Disposition:** The Flake Detection setup and walkthrough repairs remain sound. At the current revision, the Release Please exclusion and strict-Credo helper refactor both address the previously identified source defects; this narrow static delta review found no new source defect. Repeat acceptance remains blocked because the only actual full repeat failed before these repairs and the no-retry stop remains active. This is not a phase-readiness verdict.

## Reviewed identities

Current executor revision: `2495891863f5a0fbaab8800a787d668daeb67625`.

| File | Current SHA-256 | Delta since prior review |
| --- | --- | --- |
| `.github/workflows/flake-detection.yml` | `fb4bc5ee204547079811737f907a31dd3539377090f631bb398bf2b341868c3b` | Unchanged |
| `test/threadline/browser_journey_evidence_contract_test.exs` | `d013b21c231a8f36b57b32ac51b8bd3f5f04b42fd85689a24210854e1576823d` | Formatting only |
| `test/threadline/code_walkthrough_doc_contract_test.exs` | `771ef1e4ea30d8eb9bf6cb1fb3a477e17d8a157d7668e320a55a458996f12d04` | Replaced stale auth anchor; exact count 14→15 |
| `guides/code-walkthrough.md` | `6dcda3d9119165902f349ac4894cd7f96dcf356acc46db0850444dedbdb13d6d` | Added one meaningful omission marker |
| `lib/threadline/operator_surface/router.ex` | `6dad6c1939e6915b1f147a5bccf4cff60a20dd0b31b6eae7dfe106ca099bb2a9` | Extracted placeholder-capture branch into a private helper |
| `release-please-config.json` | `2a00615af477658b69f6db38ccf374ab8c56e8d53d61dfe01c4d62c0d62a9004` | Added unshipped `brand` tree to package exclusion |

| Additional statically traced file | SHA-256 |
| --- | --- |
| `mix.exs` | `3dd4a7b33bc91c3eb746d4d98930993f9ecbc7dfe4bb494d216f58859e26bf2f` |
| `test/threadline/release_artifact_contract_test.exs` | `a5f5c029800ec11a19786daf7085fb81fc38060efa8ef34bb639fc4a2b94d588` |
| `test/threadline/clean_checkout_contract_test.exs` | `dd17cbf84a81cd5f911d52419e1c66077ad4871262794c08d602323744f457d0` |
| `test/threadline/deps_health_report_test.exs` | `41344a5f08bfac8609b303b9720566cf87f16cc778f52570fbe9e7abca57cab8` |
| `lib/threadline/operator_surface/router.ex` | `9ed3e3b394cb5127ea9e099080902529bb8643bd9f371aba03f2664b35a6f7a0` |

## Findings

### RESOLVED — Release Please now excludes the unshipped `brand/` tree

**Files:** `release-please-config.json:14-19`; `mix.exs:484-493`; `test/threadline/release_artifact_contract_test.exs:276-295`.

**Observed at the previous revision:** The actual repeat log reported `Threadline.ReleaseArtifactContractTest` failing because `exclude-paths` omitted `brand`; tracked `brand/` files are absent from the built Hex archive. At the current revision, `release-please-config.json:18` includes `brand` as an excluded path. The package allowlist in `mix.exs` still omits `brand/`, consistent with the approved authoring/provenance tree remaining outside the package.

**Prior consequence:** The required suite failed at the previous revision, and a commit touching only the unshipped brand source could open a Release Please PR with no package content change. The current exclusion addresses that condition.

**Resolution:** The config now adds `brand` to the root package's `exclude-paths`; it does not add the brand source to the Hex package. This is the narrow fix consistent with the archive contract.

**Evidence limit:** The author reports the affected mount/release test batch passed after this change. This reviewer did not rerun the artifact test or canonical checks.

### BLOCKER — No complete corrected repeat receipt exists

**Files:** `.planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-04-PLAN.md:103-130`; `.github/workflows/flake-detection.yml:78-80`.

**Observed:** Two original invocations are retained. The first exited 1 before ExUnit under `MIX_ENV=dev`. The only actual suite launch ran at source `450320d71373909fa297a3e95822bc8c0ad7fc49`—before the walkthrough, Release Please, and router-helper repairs—and exited 2 after 376 seconds; captured output and the unchanged classifier report `broken` on the first iteration. There are no nine clean run summaries or `pass` token. The workflow correctly sets `MIX_ENV: test`; the first result was a local harness environment mismatch. The earlier full-repeat result remains a failed receipt, not evidence about the later repairs.

**Consequence:** The one-repeat acceptance criterion remains blocked. No further entire repeat is authorized.

**Fix:** Retain both attempts as failures/gaps and keep the repeat blocked. Honor the no-repeat stop. The orchestrator-owned plan now explicitly sets `MIX_ENV=test` for any separately authorized future run; that correction does not renew authority.

**Evidence needed:** A complete source/lock/Node-bound log with nine suite starts and nine clean summaries, true exit 0, elapsed/capture status, and classifier `pass`. No such evidence exists.

### RESOLVED — Strict-Credo excess nesting in `normalize_authorize_fn/2`

**File:** `lib/threadline/operator_surface/router.ex:172-203`.

**Observed at the previous revision:** Strict Credo reported excess nesting in this private helper. The current revision extracts the prior inner `capture_placeholder_arity/1` case and its identical body into `normalize_authorize_capture/2` (`router.ex:183-209`). The call, guards, placeholder substitution, generated callback, and fallback result are unchanged by the diff; this is a control-flow extraction with no new behavior change identified.

**Resolution:** The nested branch is now the private helper `normalize_authorize_capture/2`. The author reports 17 router tests passed after correcting helper placement, and strict Credo, format, and warnings-as-errors compile passed. This reviewer ran none of those checks.

**Evidence limit:** I reviewed the source diff and hash only. The reported checks are author evidence; no complete post-fix canonical integration result is available in this refresh.

## Resolved since prior review

The walkthrough anchor now checks `adopter_acknowledges_unauthenticated: true`, which is present in both the current router docs and guide. The count remains bounded at 12–18 and is exact at 15. The added `# ...` before the Plug `call/2` excerpt truthfully marks omitted surrounding module context, including the preceding `init/1`; it preserves the existing excerpt-truncation contract rather than padding a complete snippet arbitrarily. The author’s recorded focused run reports 16 tests with 0 failures, and the formatting check passes. I ran neither command.

For the current router/config delta, the authorization-capture branch was moved intact into a private helper and the root Release Please config now excludes `brand`. The author reports 105 affected mount/release tests and 17 router tests passed, plus strict Credo, format, and warnings-as-errors compile checks. These are reported results, not checks this reviewer ran. I found no new source defect in those two-file changes.

The new workflow contract still parses `jobs.verify-flake` and checks the gate, pinned action, `.tool-versions`, E2E lock/cache path, working directory, `npm ci`, and setup order. The two real Playwright `--list` assertions remain intact. Existing contracts retain the nine-run budget, property scale 5, 55-minute timeout, TERM/60-second grace, true exit capture, classifier, and failure reporting.

## Inherited lock proof identity

The lock hashes still match `248-ADVISORY-PROOF.md`; the recorded candidate-base hashes also match:

| Lockfile | Candidate-base SHA-256 | Current SHA-256 |
| --- | --- | --- |
| `mix.lock` | `314eed89ed27ff919afdd2436c2805a16b99811eef88b7678e3ba7b02acef3ee` | `00e6393a22730830470a8253a3cbbd49ca4adc8fd8768573516f58e592502e00` |
| `bench/mix.lock` | `73ae2b2474cee204454fe11eb23ea4b11b61e95c0abd09a289b094115d5e6927` | `70392fba94a8798e746db0c7b8b2861b267c6922758fd5dc27240e4dcec3427a` |
| `examples/threadline_phoenix/mix.lock` | `66a8373dab6c4adb546a57d4b4cfd99c4d08b4c31d360e0b10060e0a7e7bbd38` | `d3f34675157bd1d18e38d026aa0d89279dd2e46a4e55a5c82e0827f1ed5b3bff` |

The diff contains only the six intended lock tuples: Ecto 3.14.3 in all three locks, Phoenix.HTML 4.4.0 in root/example, and Bandit 1.14.1 in the example. Dependency declarations are unchanged. I confirmed hashes and diff shape only; I did not rerun Mix resolution or the audit. The inherited proof separates package Elixir metadata compatibility from a minimum-toolchain execution.

## Environment and unclassified repeat failures

The repeat log also records these failures; available evidence does not support a source-code diagnosis:

- `Threadline.CleanCheckoutContractTest` at `test/threadline/clean_checkout_contract_test.exs:140`: the child `git worktree add` was denied while creating a worktree in the shared Git metadata area.
- `Threadline.PlaywrightFailFastContractTest` at `test/threadline/playwright_fail_fast_contract_test.exs:8`: npm returned `EPERM` while opening its cache and reported root-owned cache files.
- `Threadline.DepsHealthReportTest` at `test/threadline/deps_health_report_test.exs:737`: a 60-second timeout occurred in the subprocess launched by `run_report/2`; its cause is not established.

Keep these historical environment/unclassified results distinct from the Release Please failure, which is resolved in the current config. The original suite attempt had an npm-cache `EPERM`; a later bounded targeted invocation using a task-local npm cache completed `npm exec` successfully, then timed out at ExUnit's 60-second boundary. Static inspection shows that latter test invokes `bin/verify-playwright-fail-fast`, not the E2E app runner; the exact stage after npm remains unproven. Do not change product assertions, increase timeouts, or infer causes without new evidence.

## Verification limits

- This reviewer ran no tests, apps, databases, or canonical commands. The first `mix ci.all` attempt stopped at formatting; the author then formatted the setup test and recorded a passing format check. At the previous revision, the canonical rerun identified strict-Credo nesting; the author now reports Credo, format, warnings-as-errors compile, and focused test batches pass after the router/config fixes. A complete post-fix canonical integration result is not available here.
- The earlier no-Mix-dependencies bootstrap failure must remain separate from the one missing-Playwright reproduction, which must retain both expected discovery failures.
- The completed local repeat remains failed and cannot be retried under the active stop. No minimum-toolchain execution, scheduled clean dependency-health receipt, hosted post-fix CI, live issue closure for #61/#90, or REL-01/publication result is claimed.
- The earlier mount review's callback findings are reused; this delta review checked the extracted helper and the exact source diff but did not repeat broad callback analysis.
