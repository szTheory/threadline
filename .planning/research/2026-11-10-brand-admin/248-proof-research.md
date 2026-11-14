# Phase 248: Advisory and Suite Proof Research

**Researched:** 2026-11-10  
**Scope:** ADM-03 and ADM-04 only. Read-only evidence gathering; no source, lockfile, workflow, test, issue, or CI state changed.

## Phase requirements

> **ADM-03**: Maintainers have current root/example advisory diagnoses and compatible remediation for issue #61; unresolved reachable runtime risks block affected acceptance and release, with no implicit risk waiver. [VERIFIED: `.planning/REQUIREMENTS.md:14`]
>
> **ADM-04**: Maintainers can reproduce and diagnose issue #90 against the current candidate, repair the attributable failure, and obtain trustworthy affected verification without weakened checks or speculative retries. [VERIFIED: `.planning/REQUIREMENTS.md:15`]

## Current observations versus historical evidence

- Live GitHub issue #61 is open. Its latest observed report is dated 2026-11-10 and marks root `ecto` / `phoenix_html` advisories blocking in the package runtime closure; `bench` and `examples/threadline_phoenix` findings are non-blocking to the package release. The report lists example Bandit 1.13.1 and Ecto/Phoenix.HTML 3.14.2/4.3.0. [VERIFIED: [issue #61](https://github.com/szTheory/threadline/issues/61), latest comment read 2026-11-10]
- Live issue #90 is open. Its issue body is stale and points to an older run; its latest comment points to the 2026-11-09 run on `d35b9422fb2a83897902c2276cb94ecf5129a5e3`. The current checkout's inspected lockfiles, test, and workflows are unchanged from that source commit, so the finding still applies to the candidate. [VERIFIED: [issue #90](https://github.com/szTheory/threadline/issues/90), [run 42577559585](https://github.com/szTheory/threadline/actions/runs/42577559585); read-only diff against the run SHA]
- The prior required-main CI run `40856193944` passed, but it predates the current scheduled findings and does not clear either open issue. The baseline artifact itself says “Historical exact-main required CI passed; subsequent scheduled audit and first-iteration suite failures remain open.” [VERIFIED: `.planning/research/2026-11-10-brand-admin/milestone-live-baseline.json:2-7,139-141`]

## #61: current lock exposure and compatible minima

| Workspace | Observed locked versions | Report tier | Narrow compatible target |
|---|---|---|---|
| Root | `"ecto": {:hex, :ecto, "3.14.2"` and `"phoenix_html": {:hex, :phoenix_html, "4.3.0"` [VERIFIED: `mix.lock:9,33`] | Blocking for both advisories per the latest report | Ecto **3.14.3**; Phoenix.HTML **4.4.0** |
| `bench` | `"ecto": {:hex, :ecto, "3.14.2"` [VERIFIED: `bench/mix.lock:13`] | Non-blocking | Ecto **3.14.3** |
| `examples/threadline_phoenix` | `"bandit": {:hex, :bandit, "1.13.1"`; `"ecto": {:hex, :ecto, "3.14.2"`; `"phoenix_html": {:hex, :phoenix_html, "4.3.0"` [VERIFIED: `examples/threadline_phoenix/mix.lock:4,13,38`] | Non-blocking to the library package; relevant to the example-host runtime | Bandit **1.14.1**; Ecto **3.14.3**; Phoenix.HTML **4.4.0** |

The proposed patch releases fit the checked-in constraints; do not raise the project's declared dependency or Elixir/OTP floor. The literal declarations are `{:ecto_sql, "~> 3.10"}` and `{:phoenix_html, "~> 4.0", optional: true}` in root `mix.exs`, and `{:phoenix_html, "~> 4.0"}`, `{:ecto_sql, "~> 3.13"}`, and `{:bandit, "~> 1.5"}` in the example `mix.exs`. [VERIFIED: `mix.exs:88-96`; `examples/threadline_phoenix/mix.exs:65-75`]

The resolved root `ecto_sql` lock entry records `{:ecto, "~> 3.14.0"}`; Ecto 3.14.3 stays inside that already-resolved minor line. [VERIFIED: `mix.lock:10`, verbatim dependency constraint `{:ecto, "~> 3.14.0"`]

### Advisory evidence

- Ecto GHSA-cxjx-vmm2-qr8r says affected versions are `>= 3.4.0 and < 3.14.3` and patched version is `3.14.3`. Its exploit precondition is attacker-controlled/interpolated JSON paths or `splice/1` list lengths reaching queries under the default query cache. [CITED: [Ecto security advisory](https://github.com/elixir-ecto/ecto/security/advisories/GHSA-cxjx-vmm2-qr8r)]
- CVE-2026-117645 says Phoenix.HTML 4.x versions before 4.4.0 are affected and 4.4.0 contains the fix. The affected path is attribute names controlled by untrusted data reaching `attributes_escape/1` or normal HEEx/tag rendering. [CITED: [EEF CNA record for Phoenix.HTML](https://cna.erlef.org/cves/CVE-2026-117645.html); [Hex Phoenix.HTML 4.4.0 release](https://hex.pm/packages/phoenix_html/4.4.0/changelog)]
- The example's Bandit cluster includes CVE-2026-111101 (fixed in 1.14.0) and the stricter CVE-2026-116078, affected before 1.14.1 and patched in **1.14.1**. Use 1.14.1 as the minimum candidate to clear the reported set, then require the existing Hex audit to report no remaining Bandit advisories. [CITED: [Bandit GHSA-jwh3-j29h-qfmw](https://github.com/mtrudel/bandit/security/advisories/GHSA-jwh3-j29h-qfmw); [Bandit GHSA-pxjf-g536-7r93](https://github.com/mtrudel/bandit/security/advisories/GHSA-pxjf-g536-7r93); [Hex Bandit advisory list](https://hex.pm/packages/bandit/advisories)]

### Audit ownership and acceptance

- The required `mix verify.deps_audit` gate covers root, bench, and example locks. Its tier rule makes root runtime-closure findings blocking while bench/example findings are non-blocking to package release. **A zero exit alone is insufficient evidence of a clean three-lock audit:** non-blocking findings leave exit status unchanged. Inspect the findings section and require zero advisories for this phase's resolved report. [VERIFIED: `mix.exs:212-224,294-299`; `bin/verify-deps-audit:28-52,54-57`]
- The scheduled Dependency Health workflow audits all three lockfiles daily and on matching `main` lockfile changes; it closes #61 only for a `clean` classification. Keep #61 open until that clean evidence arrives; do not replace it with a local pass or risk-acceptance label. [VERIFIED: `.github/workflows/deps-health.yml:1-10,16-31,116-128`]
- No advisory suppression is justified: each reported package has an in-range compatible fixed version. Root advisories remain package-release blockers until fixed; example-only exposure is not a library package blocker but must be resolved before acceptance of an affected example-host route. No waiver is implied. [INFERENCE from project gate and the cited advisory records]

## #90: deterministic first-iteration failure and smallest reproduction

Read-only `gh run view 42577559585 --log-failed` confirmed the first suite seed was `876664`. The run had **3,390 tests and 2 failures**, both in `Threadline.BrowserJourneyEvidenceContractTest`:

1. `test every required journey is discovered exactly once by the real voting Playwright projects` at `test/threadline/browser_journey_evidence_contract_test.exs:70-75`.
2. `test Browser-full discovers and cannot skip its route-capture render smoke` at `test/threadline/browser_journey_evidence_contract_test.exs:100-111`.

Both failed the same assertion with `Playwright CLI is missing; install the locked E2E dependencies`. The test source resolves the CLI at `examples/threadline_phoenix/e2e/node_modules/.bin/playwright` and invokes its real `--list` output; it intentionally verifies real discovery. [VERIFIED: [run 42577559585 logs](https://github.com/szTheory/threadline/actions/runs/42577559585); `test/threadline/browser_journey_evidence_contract_test.exs:1-13,70-92,95-112`]

The failure is deterministic setup omission, not a flaky assertion: the affected file is tagged `:repo_contract`; the current required-test lane installs Node and runs `npm ci` in the locked E2E directory before its full current-lane tests. The repeat-suite workflow only runs `mix deps.get`, compile, then the full suite; it does not install the Node E2E dependencies. [VERIFIED: `test/threadline/browser_journey_evidence_contract_test.exs:1-3`; `.github/workflows/ci.yml:681-699`; `.github/workflows/flake-detection.yml:109-136,155-169`]

**Smallest reproduction after the dependency setup is present:** run the one failing ExUnit file once with the recorded seed: `mix test test/threadline/browser_journey_evidence_contract_test.exs --seed 876664`. On the failing runner, first confirm the locked E2E CLI is absent; after repair, run the same command after installing the existing lock with `npm ci` from `examples/threadline_phoenix/e2e`. Do not rerun the old full repeat loop to rediscover this setup defect. [VERIFIED: `mix.exs:186-193` records `"verify.flake": ["test --repeat-until-failure 8"]`; `examples/threadline_phoenix/e2e/package-lock.json` is the workflow's lock input]

The immediate symptom is proven by the log. The workflow comparison supports the root-cause inference: the flake job lacks the exact Node/Playwright setup that the current required-test lane already uses. Confirm the repair by the one-file seeded check, then one post-fix `mix verify.flake` run in the existing workflow; it is the affected acceptance check, not a speculative retry. Retain the current suite scope and repeat count. [INFERENCE from the cited log and workflow source]

## Recommended bounded plan order

1. **Repair the dependency graph only:** use targeted `mix deps.update` operations in root, `bench`, and `examples/threadline_phoenix` to move Ecto to 3.14.3 and Phoenix.HTML to 4.4.0 where locked; move example Bandit to 1.14.1. Keep the existing `mix.exs` constraints and inspect the lock diff for only these required dependency/resolution changes.
2. **Repair the flake runner environment:** add the same pinned Node setup and `npm ci` working directory already present in the current lane to `.github/workflows/flake-detection.yml` before the suite. Keep immutable CI job IDs; do not add a workflow job, skip repo-contract tests, change test tags, lower the suite scope, or change the repeat count.
3. **Verify the small claims first:** run the recorded seeded ExUnit file once after `npm ci`; run the existing dependency audit across the three lockfiles and inspect it for zero advisory findings, including non-blocking rows.
4. **Verify candidate compatibility:** run the canonical existing checks that observe root and example behavior (`mix ci.all`, which already contains `mix verify.deps_audit`, `mix verify.test`, and `mix verify.example`, plus the existing browser gates). Then run the existing `mix verify.flake` lane once after its setup fix. Diagnose any new failure before another run.
5. **Preserve the live issue receipts:** no release or affected acceptance while root runtime advisories remain; do not claim #90 resolved until a post-fix run passes. Let the existing main lockfile-triggered Dependency Health run close #61 only on a clean result. If any minimum fixed version proves incompatible with the existing floor or requires a public/runtime policy change, stop the affected acceptance path for that decision; do not silently widen scope.

## Project Constraints (from AGENTS.md)

- “Named entrypoints”: prefer `mix verify.*` / `mix ci.*` over ad-hoc commands. [VERIFIED: `AGENTS.md`, CI & Verification Conventions]
- “Honest default tests”: never silently exclude heavy suites from `mix test` without updating `test/test_helper.exs` and docs together. [VERIFIED: `AGENTS.md`, CI & Verification Conventions]
- Keep GitHub Actions job `id:` values immutable; preserve path-filtered expensive jobs on `main`. [VERIFIED: `AGENTS.md`, CI & Verification Conventions]
- Automate routine verification; no new CI job is needed for these two repairs. [VERIFIED: `AGENTS.md`, GSD/local planning; `.planning/research/2026-11-10-brand-admin/milestone-proposal.md`, Verification and efficiency contract]
- Keep dependency and scope changes minimal; do not alter runtime/package floors, public APIs/routes, or turn milestone approval into risk acceptance. [VERIFIED: `AGENTS.md`, Brand and Admin direction; `.planning/research/2026-11-10-brand-admin/milestone-proposal.md`, Fixed boundaries]

## Open acceptance blockers

- #61 remains open until the candidate's root and example locks have compatible fixed versions and the existing audit reports clean. Any remaining root advisory blocks package release; a non-blocking-only CLI exit does not prove clean.
- #90 remains open until the two journey-contract tests pass with the locked Playwright CLI installed and the repaired repeat-suite lane produces trustworthy post-fix evidence.
- No test, build, dependency resolution, workflow run, issue mutation, or package change was performed in this research task.

## Sources

- Project: `AGENTS.md`; `.planning/REQUIREMENTS.md:14-15`; `.planning/ROADMAP.md:52-64`; `.planning/conventions/research-verification-and-efficiency.md`.
- Current evidence: [issue #61](https://github.com/szTheory/threadline/issues/61); [issue #90](https://github.com/szTheory/threadline/issues/90); [run 42577559585](https://github.com/szTheory/threadline/actions/runs/42577559585); `.planning/research/2026-11-10-brand-admin/milestone-live-baseline.json`.
- Code/workflow: `mix.lock`; `bench/mix.lock`; `examples/threadline_phoenix/mix.lock`; `mix.exs`; `examples/threadline_phoenix/mix.exs`; `test/threadline/browser_journey_evidence_contract_test.exs`; `.github/workflows/ci.yml`; `.github/workflows/flake-detection.yml`; `.github/workflows/deps-health.yml`; `bin/verify-deps-audit`.
- Primary advisory sources: [Ecto GHSA](https://github.com/elixir-ecto/ecto/security/advisories/GHSA-cxjx-vmm2-qr8r); [Phoenix.HTML EEF CNA record](https://cna.erlef.org/cves/CVE-2026-117645.html); [Bandit GHSA 111101](https://github.com/mtrudel/bandit/security/advisories/GHSA-jwh3-j29h-qfmw); [Bandit GHSA 116078](https://github.com/mtrudel/bandit/security/advisories/GHSA-pxjf-g536-7r93); [Hex Bandit advisories](https://hex.pm/packages/bandit/advisories).
