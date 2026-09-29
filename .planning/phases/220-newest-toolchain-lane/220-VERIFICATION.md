---
phase: 220-newest-toolchain-lane
verified: 2026-09-29T01:30:00Z
status: passed
score: 12/12 must-haves verified
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/phases/220-newest-toolchain-lane/220-01-PLAN.md"
  - ".planning/phases/220-newest-toolchain-lane/220-01-SUMMARY.md"
  - ".planning/phases/220-newest-toolchain-lane/220-02-PLAN.md"
  - ".planning/phases/220-newest-toolchain-lane/220-02-SUMMARY.md"
  - ".planning/phases/220-newest-toolchain-lane/220-03-PLAN.md"
  - ".planning/phases/220-newest-toolchain-lane/220-03-SUMMARY.md"
  - ".planning/phases/220-newest-toolchain-lane/220-04-PLAN.md"
  - ".planning/phases/220-newest-toolchain-lane/220-04-SUMMARY.md"
  - "CONTRIBUTING.md"
  - "README.md"
  - "lib/mix/tasks/threadline.incident.ex"
  - "lib/threadline/critic_trust/ledger_splice.ex"
  - "lib/threadline/operator_surface/live/actor_live.ex"
  - "lib/threadline/operator_surface/live/evidence_live.ex"
  - "lib/threadline/operator_surface/live/export_status_live/components.ex"
  - "mix.exs"
  - "test/support/migration_harness.ex"
  - "test/threadline/ci_workflow_parity_contract_test.exs"
covered_digest: "v2:sha256:382f6f4fe5a6cf86560b8633594ed14bef0cde096850f9a8f2f50ce40724ae16"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 9/12
  round: 3
  gaps_closed:
    - "SC3: all 25 reproduced bypass spellings (13 from round 1, 12 from round 2) are rejected by the d7d44fd1 contract, which reads ci.yml structure and image values from YamlElixir-parsed YAML"
    - "D-15: trailing-comment job header, quoted job id, quoted `\"if\":`, `if :`, and a step, job or workflow `shell` override are all rejected (needs-coverage, lane-skip, lane-shell)"
    - "D-16: a prefixed image in `container:`, a flow-mapped service, a quoted `\"image\":`, a folded scalar, a `docker run`, and compose `${VAR:-default}` are all rejected (pg-tag)"
  gaps_remaining: []
  regressions: []
advisory:
  - finding: "ci-required gate wiring is not pinned. Deleting `if: always()` from `ci-required`, narrowing the alls-green `jobs:` input to `'{}'`, or adding a quoted `\"allowed-skips\": verify-test` together with a job-level `if:` on verify-test each leaves every one of the 297 CI-contract tests green. A skipped required check counts as passing, so each edit would make every lane non-blocking."
    category: other
    reason: "Reproduced deterministically: a scratch probe, plus a scratch-tree run of all 19 CI-contract test files against each mutated ci.yml. This is OUTSIDE SC3 and D-15 as written. Those cover continue-on-error, allowed-failures and needs coverage, and phase 220 was barred from touching ci-required (D-04/D-07). This gap existed before phase 220, in the topology and release-control-plane contracts. Resolve it by pinning `if: always()`, `jobs: ${{ toJSON(needs) }}` and no allowed-skips (any spelling) from parsed YAML. A natural home is Phase 221, whose SC3 already pins `CI required`."
    evidence_status: "reproduced (probe and scratch-tree contract run)"
  - finding: "d7d44fd1 is on milestone/v1.43 only. No remote branch contains it, and origin/main still carries the round-2 contract, which the round-2 bypasses defeat."
    category: other
    reason: "Not a code gap. The next landing push must carry d7d44fd1, which needs the maintainer's push grant."
    evidence_status: "git branch -r --contains d7d44fd1 is empty; git diff origin/main HEAD shows the 461/127 change to the contract test"
---

# Phase 220: Newest-Toolchain Lane Verification Report

**Phase Goal:** The suite is proven (or honestly not yet proven) on the newest stable Elixir, OTP and PostgreSQL before any adopter hits them.
**Verified:** 2026-09-29
**Status:** passed
**Re-verification:** Yes, round 3, after d7d44fd1 (the contract now reads ci.yml structure from parsed YAML)

## Round-3 Summary

d7d44fd1 replaces the line-regex readers with YamlElixir-parsed structure:

- job ids and `needs`;
- `continue-on-error` and `allowed-failures` at any depth;
- step `if`, `run` and `shell`, plus `defaults.run.shell`;
- a walk over every string scalar for PostgreSQL images.

A file that fails to parse is reported as `rule=yaml-parse` instead of passing. This closes the class of bypass, not just the spellings I listed. All 25 previously reproduced bypasses are rejected, and each mutation is still valid YAML, so the named rule is what catches it, not a parse error. My new hunt found no bypass of SC3, D-15 or D-16 as written.

The author's two known limits are acceptable residual risk (reasoning below). I found one real hole of a *neighbouring* kind: the `ci-required` gate wiring itself is not pinned. It is outside the phase's must-haves and existed before this phase, so it is recorded as an evidenced advisory for Phase 221, not a gap.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1: a dispatch spike on exactly pinned Elixir 1.20.x / OTP 29.x / PG 18 under `--warnings-as-errors` | ✓ VERIFIED (regression) | Run 36484105399. The pins `1.20.4` / `29.1.1` / `"18.6"` are unchanged in ci.yml |
| 2 | SC2: `lane: latest` is a voting `verify-test` entry | ✓ VERIFIED (regression) | `ci.yml:338`. PR run 36501481301 was 16/16 success, and main run 36502353440 was success. ci.yml is unchanged since then (`git diff 97ccbf06 HEAD` touches only the contract test) |
| 3 | SC3: a contract test proves no voting lane uses `continue-on-error` and no lane uses a beta PG image | ✓ VERIFIED (gap closed) | 25/25 earlier bypasses are rejected, and the new hunt found no in-scope bypass (tables below). Contract and topology: 63 tests, 0 failures |
| 4 | D-08: six 1.20 warnings removed without behaviour change | ✓ VERIFIED (regression) | `lib/` is unchanged since 4a32cbf6 |
| 5 | D-14: `latest_row_errors/2` checks shape and strict-newer, with controls | ✓ VERIFIED (regression) | contract file green |
| 6 | D-15: no `continue-on-error` or `allowed-failures` on a voting lane, `needs` covers every job, and every-lane steps cannot be skipped or no-opped | ✓ VERIFIED (gap closed) | Probe: the trailing-comment header and the quoted job id give needs-coverage. Quoted `"if"`, `if :` and a merge-key `<<: {if: …}` give lane-skip. Step and job `shell` overrides give lane-shell. A duplicate `run` key gives lane-command |
| 7 | D-16: every PostgreSQL image in every workflow file and docker-compose.yml carries a release tag | ✓ VERIFIED (gap closed) | Probe: prefixed images in `container:`, a flow-mapped service, a quoted `"image":`, a folded scalar, `docker run` or `docker pull` (including a `host:port` registry), `skopeo docker://`, JSON inside a script, and a compose anchor or alias all give pg-tag. `${VAR:-…}`, `${{ env.* }}`, `$PG_TAG` and `fromJSON` give pg-tag or pg-unresolved. `bitnami/postgresql:…-beta1` gives pg-tag |
| 8 | D-17: docs describe latest as **tested on**; the check name is composed from live YAML | ✓ VERIFIED (regression) | README:102. `composed_check_names/1` |
| 9 | D-18: MILESTONE-GUIDE re-pin line | ✓ VERIFIED (regression) | `.planning/MILESTONE-GUIDE.txt:347` |
| 10 | D-04/D-07: ci-required, ruleset and `bin/verify-branch-protection` unchanged | ✓ VERIFIED (regression) | empty diff since fcb22e00 |
| 11 | Landing: PR #60 carries the lane and its PR run is green | ✓ VERIFIED | PR #60 was MERGED as `3c4ac9b1`, run 36501481301. See the advisory: d7d44fd1 itself still needs landing |
| 12 | Docs describe latest as voting through `CI required` | ✓ VERIFIED (closed in round 2) | CONTRIBUTING "Branch protection (maintainers)" |

**Score:** 12/12 truths verified (0 present, behavior-unverified)

### Earlier bypasses, re-run against d7d44fd1

Method: a scratch probe outside the repo. It AST-extracts every `defp` and module attribute from the current `ci_workflow_parity_contract_test.exs` and runs them with the project's yaml_elixir build. It applies each mutation to the live ci.yml or docker-compose.yml and checks that the mutated text is valid YAML. Baseline: `voting_lane_errors == []` and `postgres_image_errors == []`.

| Round | Mutation | Valid YAML | Result |
|---|---|---|---|
| 1 | `image: docker.io/library/postgres:19beta1` | yes | rejected, pg-tag |
| 1 | `postgres:${{ matrix.pg }}rc1` | yes | rejected, pg-unresolved |
| 1 | bare `image: postgres` | yes | rejected, pg-tag |
| 1 | `postgres@sha256:…` | yes | rejected, pg-tag |
| 1 | `"continue-on-error": true` | yes | rejected, continue-on-error |
| 1 | flow-mapped step with `continue-on-error` | yes | rejected, continue-on-error |
| 1 | `verify_latest:` / `VerifyLatest:` job | yes | rejected, needs-coverage (both) |
| 1 | step `if:` on Run tests / Compile / xref | yes | rejected, lane-skip (all three) |
| 1 | `mix verify.test \|\| true` | yes | rejected, lane-command |
| 1 | job `continue-on-error: ${{ … }}`; `allowed-failures:` | yes | rejected (both) |
| 2 | `  verify-extra: # new lane` | yes | rejected, needs-coverage |
| 2 | `  "verify-extra":` | yes | rejected, needs-coverage |
| 2 | `"if":` / `if :` on Run tests | yes | rejected, lane-skip (both) |
| 2 | `shell: "true {0}"` on Run tests | yes | rejected, lane-shell |
| 2 | `container: docker.io/library/postgres:19beta1` | yes | rejected, pg-tag |
| 2 | flow-mapped `postgres: { image: "ghcr.io/acme/postgres:19beta1", … }` | yes | rejected, pg-tag |
| 2 | `"image": docker.io/library/postgres:19beta1` | yes | rejected, pg-tag |
| 2 | `image: >-` + prefixed image | yes | rejected, pg-tag |
| 2 | `run: docker run --rm docker.io/library/postgres:19beta1 true` | yes | rejected, pg-tag |
| 2 | compose `image: ${PG_IMAGE:-postgres:19beta1}` | yes | rejected, pg-tag |

The test file also carries a mutation control for each round-2 spelling. By grep: the trailing-comment header, `"verify-extra":`, `"if":`, `if :`, `true {0}`, `container: docker.io`, `ghcr.io`, `"image":`, `image: >-`, `docker run --rm docker.io` and `PG_IMAGE:-` are all present, plus "must stay valid YAML" guards.

### Round-3 adversarial hunt

| Candidate | Valid YAML | Result | Assessment |
|---|---|---|---|
| job-level `defaults.run.shell: "true {0}"` | yes | rejected, lane-shell | fine |
| duplicate `run:` key in Run tests | yes (GitHub rejects duplicate keys anyway) | rejected, lane-command | fine |
| merge key `<<: {if: "false"}` on Run tests | yes | rejected, lane-skip | fine |
| `run: >-` folded `mix verify.test` | yes | accepted | correct: same command |
| `working-directory: examples/threadline_phoenix` (step or job default) | yes | accepted | not a bypass: the example app has no `verify.test` task, so the lane goes red |
| `env: BASH_ENV: <file>` on Run tests | yes | accepted | ℹ️ needs another step that writes an `exit 0` file. That is deliberate sabotage, outside a config contract |
| bitnami `postgresql:19.0.0-beta1` | yes | rejected, pg-tag | fine |
| env `IMG: docker.io/…/postgres:19beta1` + `docker run "$IMG"` | yes | rejected, pg-tag | fine |
| env `PG_TAG: 19beta1` + `docker run "postgres:$PG_TAG"` | yes | rejected, pg-unresolved | fine |
| `image: ${{ env.PG_IMAGE }}` | yes | rejected, pg-unresolved | fine |
| `localhost:5000/postgres:19beta1`; `--platform=… docker.io/…`; JSON `{"image":"postgres:19beta1"}` in a script | yes | rejected, pg-tag | fine |
| base-axis `pg: ["19beta1"]`; include `pg: ${{ fromJSON(…) }}` | yes | rejected, pg-tag | fine |
| compose `x-pg: &pg docker.io/…:19beta1` + `image: *pg` | yes | rejected, pg-tag | fine |
| `skopeo copy docker://docker.io/…/postgres:19beta1` | yes | rejected, pg-tag | fine |
| `image: postgres:18@sha256:…` | yes | rejected, pg-tag | fine (overstrict) |
| `PG_NAME: postgres` + `PG_TAG: 19beta1` + `docker run "$PG_NAME:$PG_TAG"` | yes | accepted | ℹ️ an image string computed in shell. No static scanner can decide this in general, and nothing in CI starts PG from a script today |
| `postgis/postgis:18beta1-3.6` | yes | accepted | ℹ️ outside D-16's `postgres:<tag>` scope (an extension image, not used by the repo) |
| other compose files (`docker-compose.proxy.yml`), Dockerfiles | n/a | not scanned | ℹ️ D-16 names workflows + `docker-compose.yml`. The proxy file has no PG image, and the example Dockerfile's FROM is a variable base, not PG |
| **delete `if: always()` from `ci-required`** | yes | **accepted by all 297 CI-contract tests** | 📋 advisory: gate wiring, outside SC3/D-15 as written |
| **alls-green `jobs: '{}'`** | yes | **accepted by all 297** | 📋 advisory, same |
| **quoted `"allowed-skips": verify-test` + job `if: false`** | yes | **accepted by all 297** (the unquoted form is caught by `release_control_plane_contract_test`) | 📋 advisory, same |

To check the gate-wiring rows beyond the probe, I copied the committed tree into a scratch directory (sharing deps, with its own `_build`). There I ran all 19 test files that read the workflows (297 tests) against each mutated ci.yml. The baseline has 2 failures, both caused by the scratch copy having no `.git`: `.tool-versions is tracked` and `planning history`. The three gate mutations add no failure. The working-directory, BASH_ENV and jobs-input runs showed one extra failure each. That failure was my mutation disturbing the D-15 test's own flow-mapped control anchor ("must stay valid YAML"), not a detection. The probe confirms `voting_lane_errors == []` for all three.

### Judgment: the author's known limits

**(a) A bare, unprefixed, untagged `postgres` in a shell `run:` script is not flagged.** I accept this as residual risk, not a gap.

- SC3 is about *beta* images. An untagged pull resolves to Docker Hub's `latest`, which always points at the newest stable GA release, never a beta or rc. So (a) cannot put a pre-release on a lane.
- D-16 as written scans `postgres:<tag>` tokens, and an untagged word in free text is outside that pattern.
- The fixer's reason holds: in free text, `postgres` is overwhelmingly the role, database or service name (`psql -U postgres`, `@postgres:5432`), and flagging it would bury real findings.
- Every structured place an image can live (`image:`, `container:`, compose) *does* reject an untagged image, and so does any prefixed or digest form in free text.
- Optional hardening: a narrow `docker (run|pull|create) … postgres(\s|$)` rule.

**(b) An unquoted float `pg: 18.10` parses as `18.1`.** I accept this as residual risk, not a gap.

- GitHub Actions reads the same YAML the same way. An unquoted `18.10` is a number, so the runner renders `postgres:18.1`. The contract checks exactly what GitHub would pull, and `18.1` is a real release.
- A float can never carry `beta`, `rc`, `devel` or `latest`, so (b) cannot hide a pre-release. It is a pin-fidelity trap (the familiar `python-version: 3.10` problem), not a beta hole.
- D-02 already pins pg as quoted strings, and every row is quoted today.
- Optional hardening: require `pg` values to be YAML strings.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.github/workflows/ci.yml` | voting latest row | ✓ VERIFIED | unchanged since round 2 |
| `test/threadline/ci_workflow_parity_contract_test.exs` | fail-closed roster, latest, voting-lane and PG-tag contracts | ✓ VERIFIED | Parsed-YAML readers (`parse_yaml/1`, `parsed_jobs/1`, `yaml_key_anywhere?/2`, `every_lane_step_errors/1`, the `scan_postgres_node/2` walk) are wired into the D-15 and D-16 tests. It adds the `lane-shell` and `yaml-parse` rules. `mix format --check-formatted` passes on the file, and the run emits no warnings |
| `CONTRIBUTING.md`, `README.md`, `.planning/MILESTONE-GUIDE.txt`, `220-SPIKE.md` | as before | ✓ VERIFIED | regression only |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| parity contract test | `.github/workflows/ci.yml` and `docker-compose.yml` | `YamlElixir.read_from_string!` → `voting_lane_errors/1`, `postgres_image_errors/1` | WIRED | Baseline empty on the live tree. Every mutation turns its named rule red |
| `CI required` | `Run test suite (latest)` | `needs: verify-test` + alls-green | WIRED | Run 36501481301 |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Contract + topology green | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs` | 63 tests, 0 failures | ✓ PASS |
| All CI-contract files green on the committed tree | 19 files in a scratch copy | 297 tests; the only failures are the 2 caused by the missing `.git` | ✓ PASS |
| Full suite, compile, hygiene | orchestrator gates log (HEAD 97ccbf06; d7d44fd1 touches only the contract test, which was re-run above) | 2507 tests, 0 failures; COMPILE_OK; hygiene clean | ✓ PASS |
| Earlier bypasses rejected | scratch probe | 25/25 rejected | ✓ PASS |
| No in-scope new bypass | scratch probe + scratch-tree run | 0 in scope; 3 gate-wiring advisories; 4 ℹ️ out of scope | ✓ PASS |

### Probe Execution

None declared. SKIPPED.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| LANE-01 | 220-01..04 | Dispatch spike on Elixir 1.20.x / OTP 29.x / PG 18, exactly pinned, under `--warnings-as-errors` | ✓ SATISFIED | Truth 1 |

### Prohibitions (judgment-tier, non-authoritative LLM verdict)

| Prohibition | Verdict |
|-------------|---------|
| No version-conditional D-08 fix | holds |
| No `mix.lock` / `.tool-versions` / min-pin change | holds |
| No ruleset or ci-required change, no `if:` / `allowed-skips` for latest | holds |
| Latest lane gains no example app, Dialyzer or test `--warnings-as-errors` | holds |
| No voting lane can use continue-on-error; no pre-release PG | holds, and enforcement is now fail-closed for every spelling tried |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (ci-required gate, owned by ci_topology / release_control_plane contracts) | — | `if: always()`, the alls-green `jobs:` input, and quoted `allowed-skips` are not pinned | 📋 Advisory | Existed before this phase. See frontmatter `advisory` |

There are no TBD, FIXME or XXX markers in the contract test or in any other file this phase touched.

### Human Verification Required

None. Every check was automated. The judgment rows (limits a and b, and the scope of the gate-wiring finding) are resolved above.

### Gaps Summary

No gaps remain. d7d44fd1 fixes the root cause the last two rounds kept hitting (reading YAML as lines) by moving every structural rule onto a real parser, and it fails closed on anything that does not parse. SC3, D-15 and D-16 now hold against every spelling I could construct inside their written scope. Limits (a) and (b) cannot introduce a pre-release image, and are documented.

Two follow-ups for the orchestrator:

1. **Landing.** d7d44fd1 is not on any remote, and `origin/main` still has the round-2 contract. The next landing must carry it.
2. **Gate-wiring advisory.** Pin `ci-required`'s `if: always()`, `jobs: ${{ toJSON(needs) }}` and the absence of `allowed-skips` in any spelling, from parsed YAML. The best place is Phase 221, which already has to keep `CI required` byte-exact.

---

_Verified: 2026-09-29_
_Verifier: Claude (gsd-verifier)_
