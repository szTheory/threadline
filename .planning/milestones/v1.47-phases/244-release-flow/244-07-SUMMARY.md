---
phase: 244-release-flow
plan: 07
subsystem: release
tags: [release, verification, hex, evidence, rehearsal]
status: complete

requires:
  - "244-01..244-06: sync-job rename, rehearsal parity, retry wrapper, Hex 2.6.0 pin in every job"
provides:
  - "244-REL02-EVIDENCE.md: REL-02 observed-run procedure, pass conditions, Status pending, PAT-expiry maintainer item"
  - "Bump rehearsal from a plain clone: green, dated by the production bin/date-release-changelog"
  - "REL-04 reproduction re-run under isolated Hex 2.6.0 and 2.5.1 homes, which FALSIFIES the Hex-drift cause (see below)"
affects: [244-VERIFICATION, 245, v1.47 close audit]

actuals:
  tokens: 4500
  tasks: 2
  commits: 1
plan_head_before: d1b7ad6df3da9a89f650597195da0fbf96c14567
plan_head_after: 175abba62ee8920810ca25e2031d698d3b5e4338

tech-stack:
  added: []
  patterns:
    - "observed-run evidence file with a Status line that a later verifier rewrites"

key-files:
  created:
    - .planning/phases/244-release-flow/244-REL02-EVIDENCE.md
  modified: []

decisions:
  - "REL-04 reproduction diverged from research: on a clean deps/ both Hex 2.5.1 and 2.6.0 reject the [] manager lock. Reported as a finding. The Hex pin is not changed (plan rule)."
  - "REL-02 stays pending, bound to the first natural release cycle after landing; no throwaway release."

metrics:
  duration: "about 16 min"
  completed: 2026-10-25
---

# Phase 244 Plan 07: Release-flow closing evidence Summary

The bump rehearsal is green end to end from a plain clone, and the REL-02 observed-run procedure is on disk with `Status: pending`. Two results did not go to plan:

- **The gate is red, for an environmental reason.** `CI=true mix ci.all` fails twice at `verify.example` with `too_many_connections`. Another project's dev servers on the shared local Postgres hold 70 idle connections. ExUnit is 3250 tests, 0 failures both times.
- **The REL-04 cause in research did not reproduce.** Hex 2.5.1 rejects the `[]` lock just like 2.6.0 does when `deps/` is fresh. So the cause is not Hex version drift.

## Task 1 (tracer): gate, rehearsal, REL-04 reproduction

### Local Hex

`mix hex.info` in the execution checkout reports `Hex: 2.6.0` (Elixir 1.17.3, OTP 27.3.4.15). The maintainer ran `mix local.hex 2.6.0 --force` themselves this session. That covers handoff item (b) below. The executor did not touch the global install.

### Gate: `CI=true mix ci.all`

I ran it twice, the second time as the one re-run the rules allow for `too_many_connections`. Both runs ended the same way:

| Step | Result |
|------|--------|
| verify.format | passed |
| verify.credo | `5769 mods/funs, found no issues.` |
| verify.deps_audit | `verify-deps-audit: 3 lockfile(s) audit clean (Hex 2.6.0)` |
| verify.repo_hygiene | `4901 tracked text file(s) clean; 8 allowlist entries used, 0 inert` |
| compile --warnings-as-errors, xref_cycles, compile_no_optional, bench_compile | passed |
| verify.test (ExUnit) | `32 properties, 3250 tests, 0 failures, 3 excluded` (both runs) |
| verify.threadline | passed |
| verify.example | **FAILED, both runs**: `FATAL 53300 (too_many_connections) sorry, too many clients already`, then `ThreadlinePhoenix tests: could not ensure PostgreSQL database "threadline_phoenix_test" exists.` and `** (Mix) verify.example failed (1)` |
| verify.dialyzer, verify.dialyzer_slice, verify.example_browser | not reached by ci.all (the alias halts at verify.example) |

**Cause of the verify.example failure (environmental, not this phase).** `max_connections` is 100, and `pg_stat_activity` showed 76 in use. 70 of those are idle connections to seven `upg_default_*_dev` databases. Seven long-lived `beam.smp` processes from a different project (OTP 28 / Elixir 1.19, started 2026-10-24) hold them. No `threadline*` database held any connections. The example app's pool cannot fit in the roughly 24 free slots. I did not stop those processes or shrink any pool. They are not this repo's, and that would be working around the gate.

**Steps run on their own after ci.all halted** (these need no database):

- `MIX_ENV=dev mix verify.dialyzer`: the first try failed with `Could not read PLT file ... no_such_file`, a PLT cache miss. After `mix dialyzer --plt`, it reported `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`, `done (passed successfully)`.
- `MIX_ENV=test mix verify.dialyzer_slice`: `17 tests, 0 failures, 16 excluded`.

**Playwright:** not run. `verify.example_browser` is the last ci.all step and needs the example app's database, so it hits the same connection limit. The expected CI-mode result (318 passed / 0 failed / 26 skipped) is **unobserved** for this plan.

**Net:** the must-have "`CI=true mix ci.all` is green" is **not proven locally**. Everything up to and including ExUnit is green, plus Dialyzer and the slice. verify.example and the browser lane are blocked by the shared-Postgres environment. They need a re-run once the other project's servers release their connections. The phase PR's CI is an alternative, since it runs the same lanes on clean runners.

### Bump rehearsal (plain clone)

I cloned the phase tip (d1b7ad6d) with `git clone --no-local` into `<scratch>/rehearsal-clone`, a plain clone rather than a linked worktree. I ran `mix deps.get` and then `mix verify.bump_rehearsal`. Exit 0. The decisive lines:

```
==> rehearsing the next minor: 1.1.0 -> 1.2.0
==> dating CHANGELOG.md with bin/date-release-changelog (the sync job's script)
date-release-changelog: dated [1.2.0] - 2026-10-25
287 tests, 0 failures
9 tests, 0 failures
45 tests, 0 failures
Bump rehearsal OK: a 1.1.0 -> 1.2.0 release commit passes every doc-contract test
(derived by filename), the changelog contract and mix verify.release.
The real working tree is byte-identical.
```

The rehearsal also seeded its disclosed stand-in prose, printing the `(rehearsal-only: ...)` lines, and reported that no scratch branch or linked worktree survived. This proves REL-01's renamed shape end to end: the production rename script runs, then the version-truth, changelog and release-shape contracts pass against its output.

## REL-04 reproduction

**Setup.** I made a minimal Mix project in `<scratch>/rel04-repro/proj`, pinned to the repo's `.tool-versions` (Elixir 1.17.3-otp-27). `mix.exs` deps were `[{:plug_crypto, "2.2.1"}]`. `mix.lock` held exactly the a3301bed entry:

```
"plug_crypto": {:hex, :plug_crypto, "2.2.1", "bd1d0358a2e2f5ffb818217e64c394f9d24ed191d862b7fa1bcce264ace2b8ea", [], [], "hexpm", "4417ccbd8f85e627321cd07d2ab9c4b621f1fd883b9905af241f9b4b780b94b6"},
```

Each Hex version got its own isolated homes: `MIX_HOME=<scratch>/rel04-repro/h260/mix HEX_HOME=<scratch>/rel04-repro/h260/hex mix local.hex 2.6.0 --force`, and the same for `h251` with `2.5.1`. `mix hex.info` confirmed `Hex: 2.6.0` and `Hex: 2.5.1` in those homes. The lock was restored from a pristine copy before every run.

**Command, run under each Hex version:** `MIX_HOME=... HEX_HOME=... mix deps.get --check-locked`.

| Case | Hex 2.6.0 | Hex 2.5.1 |
|------|-----------|-----------|
| clean deps/ (no deps, no _build), CI's state | `** (Mix) Your mix.lock is out of date and must be updated without the --check-locked flag`, exit 1 | `** (Mix) Your mix.lock is out of date and must be updated without the --check-locked flag`, exit 1 |
| deps/ already holds plug_crypto 2.2.1 | `All dependencies are up to date`, exit 0 | `All dependencies are up to date`, exit 0 |
| deps/ holds plug_crypto 2.2.0, lock says 2.2.1 `[]` | `* Updating plug_crypto` then the same `out of date` error, exit 1 | same, exit 1 |

A fresh `mix deps.get` without the flag, under 2.5.1, writes `[:mix]` into the lock. This matches research: neither version produces `[]`.

**Finding: this diverges from research and the plan.** Research E5 and this plan's must-have both expected 2.5.1 to accept the `[]` lock. It does not. On a fresh fetch, both versions reject it. On an already-populated `deps/`, both accept it, because nothing is fetched and the lock is never rewritten. So on this evidence the discriminator is **deps/ cache state, not Hex version**. `--check-locked` fails when a fetch rewrites the manager list from `[]` to `[:mix]`. A local tree whose `deps/` already held 2.2.1 never fetches, so it passes. CI starts from a fresh `deps/`, so it fails. The research's 2.5.1 "accepts" result is consistent with that run having a populated `deps/`. That is an inference; I did not reproduce the research session itself.

Following the plan rule, I stopped there and changed nothing. The Hex 2.6.0 pin and the `MIN_HEX` floor are untouched. The pin still makes CI and local toolchains deterministic, so it does no harm, but it is not what closes the 1.1.0 failure. REL-04's text reads "If Hex version drift is the cause, CI pins the Hex version". This evidence says drift is not the cause. REQUIREMENTS.md already shows REL-04 Complete (set by an earlier plan), and I left it as it was. The orchestrator or verifier should decide whether REL-04 needs re-scoping. One option is a lock-hygiene check that rejects an empty manager list for a Hex package that declares `build_tools`, run from a fresh `deps/` so a populated cache cannot mask it.

I checked tracked locks: `git status --porcelain -- mix.lock bench/mix.lock examples/threadline_phoenix/mix.lock` prints nothing. The reproduction ran entirely in the scratchpad.

## Task 2: REL-02 evidence

I wrote `.planning/phases/244-release-flow/244-REL02-EVIDENCE.md` (commit 175abba6). It has all eight sections: claim, trigger condition, the five exact read-only `gh` commands, pass conditions, the concurrency note (Pitfall 5), the A1 fallback, Status, and Maintainer-owned items (Q2, the PAT expiry). I ran the first two commands now. `gh pr list --head release-please--branches--main --state open` returned `[]`. The newest release.yml run on main is 40139774747 (push, success, head 23178fb0), and none of the runs listed include the phase 244 workflow. `Status: pending — bound to the first natural release cycle after this phase lands; no throwaway release (maintainer rule)`. The milestone close audit or the next phase's verifier closes it.

One small correction to the plan text: the "expired PAT fails loudly" comment in release.yml sits above the `Bootstrap CI on Release PR` job (the ECON-03 comment), not near l.212. The evidence file cites it by job name.

## Gate re-run on an ephemeral Postgres (orchestrator, 2026-10-25)

The first gate run stopped at `verify.example` on the shared local server (Homebrew PostgreSQL
14.17, below the PG15 support floor, `C` collation, non-UTC timezone, about 21 free slots against
the example app's 36-connection pool). After a three-way research fan-out the orchestrator re-ran
the gate on a throwaway `postgres:16` container, with no repo change:

- `docker run -d --rm --pull never -p 127.0.0.1::5432` with `dev.threadline.kind=gate-db` /
  `owner-pid` labels, readiness via `pg_isready -h 127.0.0.1`, then `DB_HOST=127.0.0.1`,
  `DB_PORT=<docker-assigned>` and `CI=true` exported for the whole run; trap teardown.
- Server proof printed first: `PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on aarch64` |
  `inet_server_port()=5432` (container side) | `Etc/UTC` | `en_US.utf8`; host port 49759.
- `CI=true mix ci.all` exit 0:
  - ExUnit `32 properties, 3250 tests, 0 failures, 3 excluded`; example app `132 tests, 0 failures`
  - credo `5769 mods/funs, found no issues`; format, xref, repo hygiene clean
  - `verify-deps-audit: 3 lockfile(s) audit clean (Hex 2.6.0)`
  - Dialyzer `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`; dialyzer slice 17/0
  - Playwright `418 passed, 64 skipped`, 0 failed
- Teardown removed the container; 0 labelled containers remained.

No collation, timezone or stale-schema failures surfaced on the fresh CI-parity database. The
durable wrapper (`bin/with-test-postgres`) is captured as
`.planning/todos/pending/2026-10-25-local-gate-ephemeral-postgres-wrapper.md`.

## Success criteria status

- **Criterion 1 (REL-01):** proven by contract plus rehearsal. Rehearsal green above. The real release PR's first green CI run is pending the first release after landing.
- **Criterion 2 (REL-02):** contract half proven in 244-01. Observed half pending in 244-REL02-EVIDENCE.md. REQUIREMENTS.md left Pending, as the orchestrator holds it.
- **Criterion 3 (REL-03):** proven by 244-03/244-04 behaviour tests. Nothing new here.
- **Criterion 4 (REL-04):** the pin is proven by hex_pin_contract_test.exs. **The cause as stated (Hex drift) is falsified by this reproduction**; see the finding above. A3 (min/latest lanes green on 2.6.0) is pending the phase PR's CI.

## Deviations from Plan

- **REL-04 reproduction diverged** (Hex 2.5.1 also rejects). I reported it as a finding and did not adjust anything, per the plan's explicit rule.
- **Gate not green locally**, because of a shared-Postgres environment limit. I re-ran once per the rules and recorded the exact failure. I ran Dialyzer and the slice on their own after rebuilding the PLT after a cache miss. Playwright and verify.example were not observed.
- **Commit order:** Task 2's evidence file was committed before this SUMMARY, which is Task 1's only artifact. The SUMMARY commit closes Task 1.

## Deferred Issues

- Re-run `CI=true mix ci.all` once the shared local Postgres has free connections, or rely on the phase PR's CI. That will observe verify.example and the Playwright lane (expected 318/0/26).
- REL-04 re-scope decision (see the finding).

## Maintainer handoff

a. Push or land the phase. This needs a maintainer grant.
b. Upgrade local Hex. **Done by the maintainer** this session (`mix local.hex 2.6.0 --force`; the checkout reports 2.6.0).
c. Confirm the phase PR's CI is green on all lanes. This closes A3, and also covers the verify.example and browser lanes that were blocked locally.
d. Check the `RELEASE_PLEASE_TOKEN` fine-grained PAT expiry date in GitHub settings (secret last updated 2026-05-28) and rotate it before it lapses (Q2). Agents cannot read it.
e. REL-02 live observation. After landing, once a releasable change opens a release PR and a non-releasable merge follows, an agent runs the commands in 244-REL02-EVIDENCE.md. This is not a maintainer action, but it is what keeps REL-02 open.
f. Decide whether REL-04 needs re-scoping, given that the reproduction shows deps/ cache state, not Hex version, decides the `[]` lock outcome.
