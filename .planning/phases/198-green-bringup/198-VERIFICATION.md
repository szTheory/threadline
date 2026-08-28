---
phase: 198-green-bringup
verified: 2026-08-28T04:20:00Z
status: gaps_found
score: 2/6 roadmap success criteria fully verified (9/12 requirements)
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "SC2 — `mix test` passes with no deterministically-failing tests, each former failure fixed rather than skipped (GREEN-04)"
    status: partial
    reason: "`mix test` reports 1380 tests / 80 failures, exit 2. The plan honestly declined to manufacture green and filed the 79 unprefixed-audit-table defects plus 1 CONTRIBUTING List 1 parity failure as deferred. The requirement's own text ('`mix test` passes') is therefore not met. The sibling clause of SC2 (GREEN-05, the formless-page guard) IS met."
    artifacts:
      - path: "test/threadline/*"
        issue: "79 tests across 15 files call `Repo.all(AuditChange)` etc. without `prefix:`, relying on a `search_path` D-02 forbids"
      - path: "test/threadline/phase06_nyquist_ci_contract_test.exs"
        issue: "CONTRIBUTING.md List 1 omits `verify-capture` and `verify-mechanical`; TRIAGE records this row as explicitly UNOWNED"
    missing:
      - "Apply the deferred remediation shape (per-call-site `prefix:` or StorageSchemaCase.repo_opts/1) to the 79"
      - "Assign and land the two CONTRIBUTING.md List 1 table rows — currently owned by no plan and no later phase"
  - truth: "SC3 — the latest `main` run concludes `success` (GREEN-07)"
    status: partial
    reason: "Three separable clauses, different outcomes. (a) commits landed: `git rev-list --count origin/main..main` was 0 at push time and is 4 now, all four post-push documentation commits — clause substantively held. (b) wall-clock ≤20min (target ≤12): run 33138291361 took 6m07s — clause MET and comfortably inside target. (c) conclusion `success`: run 33138291361 concluded FAILURE, with 8 of 14 jobs red (`CI required`, `Compile without optional deps`, `Example app browser E2E`, `Mechanical checker`, `PgBouncer transaction topology`, `Run test suite (min)`, `Run test suite (current)`, `Tier A capture lane`) — clause NOT met."
    artifacts:
      - path: "GitHub Actions run 33138291361 (main, a97f527e)"
        issue: "conclusion: failure"
    missing:
      - "Close GREEN-04's 79 to green the two test lanes; then diagnose the 6 remaining red jobs that are not test-suite failures"
  - truth: "SC6 — Flake Detection distinguishes 'suite is broken' from 'suite is flaky' by name and surfaces failures to a deduplicated tracking issue (GREEN-11)"
    status: failed
    reason: "The classifier is present, well-reasoned, and completely unreachable on the only path it exists for. `.github/workflows/flake-detection.yml:87` uses `set -uo pipefail`, which does NOT clear the `-e` GitHub injects — the runner log for the sibling branch-protection job confirms `shell: /usr/bin/bash -e {0}` verbatim. When `mix verify.flake` fails, the line-88 pipeline aborts the step before line 89 writes `exit_code`. `Classify broken vs flaky` (line 101) carries no `if:` and so defaults to `success()` — it is SKIPPED, as is `Open or update the flake tracking issue` (line 145, gated on `steps.classify.outputs.classification`). The step's own comment at lines 82-83 states the opposite intent ('Captures the exit code instead of failing here, so the classification and issue steps below still run'). The time-bounded clause (timeout-minutes: 120) IS met; the by-name classification and deduplicated-issue clauses execute never."
    artifacts:
      - path: ".github/workflows/flake-detection.yml"
        issue: "line 87 `set -uo pipefail` does not disable `-e`; line 101 `Classify broken vs flaky` has no `if: always()`; line 145 issue step transitively skipped"
    missing:
      - "Add `set +e` (or `continue-on-error`) to the repeat step so `exit_code` is always written"
      - "Add `if: always()` to `Classify broken vs flaky`"
      - "Guard the `iterations` integer comparisons against an empty value so an unparseable log lands on `unknown`, not the `flaky` fall-through (CR-02)"
  - truth: "SC4 — PR #26 is mergeable (GREEN-08's downstream consequence clause)"
    status: failed
    reason: "PR #26 is `state: OPEN`, `mergeable: MERGEABLE`, `mergeStateStatus: BLOCKED` — blocked because the single required context `CI required` concluded FAILURE, with `bypass_actors: []` leaving no actor able to walk past it. This is a consequence of SC2/SC3, not of GREEN-08 itself, and the branch-protection audit records the maintainer accepting this cost explicitly before applying the ruleset. The requirement GREEN-08 (`requires exactly the check names CI emits ... so no PR can be blocked on a check that cannot exist`) IS met; the roadmap criterion's mergeability clause is not."
    artifacts:
      - path: "PR #26"
        issue: "mergeStateStatus BLOCKED on a genuinely failing `CI required`"
    missing:
      - "Green `CI required` on the PR head — no branch-protection change is required or appropriate"
deferred: []
---

# Phase 198: Green Bringup — Verification Report

**Phase Goal:** `origin/main` carries every local commit and its CI concludes green well inside a usable feedback loop; the red-test baseline that nobody re-derived is retired with each former failure fixed on its merits; branch protection requires exactly the checks CI emits; and the measurement sweep that sizes Phases 201 and 203 is on disk before either is planned.
**Verified:** 2026-08-28
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Roadmap Success Criteria

| # | Criterion (reqs) | Status | Evidence |
|---|---|---|---|
| 1 | Preserved red logs + Credo histogram + concentration table + mechanical-sensitivity finding, `.credo.exs` unmodified, no scorecard touched (GREEN-01/02/03) | ✓ VERIFIED | See below |
| 2 | `mix test` passes, no skips; milestone literals → shape assertions; formless guard fails in-diff (GREEN-04/05) | ✗ FAILED (GREEN-05 met, GREEN-04 not) | 1380 tests / **80 failures** |
| 3 | `origin/main..main` empty; latest main run `success` ≤20min; every job `timeout-minutes`-bound; browser suite aborts early (GREEN-06/07) | ✗ FAILED (GREEN-06 met; GREEN-07 2-of-3 clauses) | run 33138291361 = **failure** in 6m07s |
| 4 | Branch protection requires exactly the emitted names, verified after the matrix reported once; PR #26 mergeable (GREEN-08) | ⚠️ PARTIAL | GREEN-08 met and proven fail-closed; PR #26 BLOCKED |
| 5 | Paid critic scoring untriggerable; exactly one gated Hex publish path (GREEN-09/10) | ✓ VERIFIED | Workflows deleted + resurrection guards |
| 6 | Flake Detection classifies broken vs flaky, time-bounded, dedup issue; one worktree, no stale branches, archive tags (GREEN-11/12) | ✗ FAILED (GREEN-12 met, GREEN-11 not) | Classifier skipped on the failure path |

**Score:** 2/6 roadmap success criteria fully verified. 9/12 requirements verified.

---

### Criterion 1 — measurement sweep (GREEN-01/02/03) — ✓ VERIFIED

| Check | Evidence |
|---|---|
| Red logs preserved in-repo | `.planning/audits/198-ci-run-28214113903-logs.md`, **8966 lines**, verbatim `gh run view --log-failed`, with run metadata JSON and per-job conclusions |
| D-36 staleness caveat stated in the artifact's own header | Present, with corroborating internal evidence (`Run test suite` with no matrix suffix, only possible on pre-matrix `ci.yml`) |
| Per-check Credo histogram | `198-credo-histogram.md` §"Per-check histogram (full default, all 377 findings)" plus a `lib/`-restricted variant |
| Per-file concentration table | Same file §"Per-file concentration (all 377 findings, 99 files, descending)" |
| Produced from a config held outside the repo | `--config-file /tmp/198-full-default.credo.exs`; full-default **377** > baseline **0**, proving the flag was honored |
| `.credo.exs` unmodified | `git diff --exit-code .credo.exs` → clean; last commit touching it is `d87f1496`, long predating this phase |
| Mechanical sensitivity stated from evidence | `198-mechanical-sensitivity.md` §Finding: **NOT sensitive to rendered text content or text width**; sections for probe design, executed results, a positive control, and raw probe output |
| No scorecard read-modify-written | `git status --porcelain .planning/scorecards/` empty; no scorecard commits in the phase window |

The `baseline_count = 0` finding independently re-derives the known-vacuous credo gate (`enabled:` replaces defaults, 2 checks not 108, `TagTODO` at `exit_status: 0`). This is a genuinely measured artifact, not a narrative.

---

### Criterion 2 — the red baseline (GREEN-04 ✗ / GREEN-05 ✓)

**GREEN-05 — ✓ VERIFIED.** `test/threadline/operator_surface/ui_form_policy_contract_test.exs` passes (ran: 3 tests, 0 failures with the zero-skips guard). All **11/11** `*_live.ex` pages carry a persisted `@ui_form_policy`; the roster is derived from `Path.wildcard`, not an allowlist, with an explicit non-empty assertion so a broken glob cannot pass vacuously. The superseded `formless_pages_test.exs` is deleted. `policy_redaction_live.ex` — which the old allowlist still called formless after it gained a host-schema picker — now declares `{:has_forms, "host-schema picker for the redaction diff view"}`. A page that gains a raw form control while declaring `:formless` fails in the same diff, which is GREEN-05 verbatim.

**GREEN-04 — ✗ FAILED.** `mix test` → **1380 tests, 80 failures**, exit 2. The phase's own `198-TRIAGE.md` §"Post-plan measurement (the honest number)" records `1376 tests, 80 failures` and states plainly that no failure was skipped, excluded, tagged out, or asserted away. The anti-laundering cap (`zero_skips_contract_test.exs`) is real and passing. The version-pinned-literal sub-clause IS satisfied — `v1_23_charter_doc_contract_test.exs` was deleted and the nyquist contract test is now red for the real reason (CONTRIBUTING List 1 drift) rather than a rotted count literal. But the requirement's headline ("`mix test` passes") is not met, and `.planning/REQUIREMENTS.md` correctly leaves GREEN-04 unchecked.

**This is a gap, not a dishonesty finding.** The plan disproved its own inherited premise with measurement (recreating the DB went 4 → 82 failures, falsifying the "stale database" hypothesis) and refused to file 79 real test-side defects as environmental. That is the right call. The goal still is not achieved.

---

### Criterion 3 — landed and fast (GREEN-06 ✓ / GREEN-07 ✗ partial)

**GREEN-06 — ✓ VERIFIED.** Parsed every `jobs:` block across all 5 workflows: **24/24 jobs carry a job-level `timeout-minutes`**, zero missing.

| Workflow | Jobs | All bounded |
|---|---|---|
| `branch-protection.yml` | 1 | ✓ |
| `browser-full.yml` | 1 | ✓ |
| `ci.yml` | 13 | ✓ |
| `flake-detection.yml` | 1 | ✓ |
| `release.yml` | 7 | ✓ |

Early abort on systemic breakage: `examples/threadline_phoenix/e2e/playwright.config.ts:141` sets `maxFailures: process.env.CI ? 5 : 0`, deliberately chosen over `-x` so `trace: retain-on-failure` still yields diagnosable artifacts; the browser step's `timeout-minutes: 14` is strictly less than the job's `18` so the step dies first and the failure-artifact upload still runs. Both are correct and non-obvious.

**GREEN-07 — ✗ FAILED, but only on one of three clauses:**

| Clause | Outcome |
|---|---|
| `git log origin/main..main` empty | **Substantively held.** 0 at push; 4 now, all post-push docs commits (`a347a07c`, `7d3dd1f6`, `d268f4b0`, `81878c83`) |
| ≤ 20 min (target ≤ 12) | **✓ MET.** Run 33138291361: 03:13:58Z → 03:20:05Z = **6m07s**, against the preserved 1h33m red baseline. A real, large win. |
| Concludes `success` | **✗ NOT MET.** conclusion `failure`; 8 red jobs, 6 green |

---

### Criterion 4 — branch protection (GREEN-08) — ⚠️ PARTIAL

**GREEN-08 itself is met, and it is proven non-vacuous by live evidence** — the strongest kind available:

| Run | Head | Result |
|---|---|---|
| `33138291397` @ 03:14 | `a97f527e` | **FAILED CLOSED**: `FAIL (a): szTheory/threadline@main has ZERO required status-check contexts. / An unprotected branch must not read as passing.` |
| `33140020321` @ 03:49 | `a97f527e` | **PASSED**: `required contexts are exactly [CI required], that name has been emitted 1 time(s) on head a97f527e..., and no classic protection is stacking.` |

That red→green pair on an identical SHA demonstrates halves (a) and (b) actually discriminate. Live state confirms ruleset `21702804` `main-protection`, `enforcement: active`, `bypass_actors: []`, single required context `CI required` — byte-identical to the aggregate job's `name:`. Classic protection is deleted. Keeping this workflow **out of** `ci-required` is correct reasoning (a skipped required check scores as passing).

**Two real weaknesses in the drift guard, confirmed independently of the review:**

- **Block (c) is vacuous in CI (CR-03).** `.github/workflows/branch-protection.yml:27-28` declares `permissions: contents: read`, which sets every unlisted scope to *none*. Block (c) (`bin/verify-branch-protection:107-108`) calls `/repos/{}/branches/{}/protection`, which needs *administration* scope, and `&& echo "present" || echo "absent"` maps a 403 to `absent` — the passing branch. The green run's OK line asserting "no classic protection is stacking" is therefore unfalsifiable in CI; it passed locally only because the operator's token carries admin. A stale classic rule could silently re-arm and this check would still read green.
- **`enforcement` and `bypass_actors` are never asserted (CR-05).** `.github/rulesets/main.json` is a checked-in snapshot nothing diffs against live state. A bypass actor added via the UI, or enforcement flipped to `evaluate`, passes all three blocks. This matters precisely because the maintainer accepted a hard merge lock predicated on `bypass_actors: []`.

Neither weakness breaks GREEN-08's literal text, so they are WARNINGs, not BLOCKERs. **The criterion's "so PR #26 is mergeable" clause is a BLOCKER** — see gaps.

---

### Criterion 5 — release safety (GREEN-09/10) — ✓ VERIFIED

| Check | Evidence |
|---|---|
| `ui-critic.yml` deleted | absent from `.github/workflows/` |
| `hex-publish.yml` deleted | absent from `.github/workflows/` |
| No paid-scoring input or billing path in any workflow | grep for `critic\|anthropic\|billing\|paid` across all 5 workflows returns only unrelated prose matches (`scorecards`, "GitHub scores a skipped…") |
| Structural, not defaulted-off | Deletion of the workflow, per `ci_topology_contract_test.exs:134` whose failure message says so explicitly |
| Exactly one publish path | `mix hex.publish` appears only in `release.yml:390,392` |
| Guarded against resurrection | `ci_topology_contract_test.exs:156` asserts **list equality** against `[".github/workflows/release.yml"]`, not a count and not a bare refutation — both weaker forms would pass vacuously. Both guards assert the glob is non-empty first. |
| Publish is gated | `publish-hex` has `needs: [release-ref, gate-ci-green]` + an `if:` re-asserting both results are `success`, `environment: production-hex` (required reviewer), tag↔`@version` equality, `bin/verify-release-shape` + `mix hex.build` preflight, an already-on-Hex idempotency skip, and post-publish verification. `gate-ci-green` polls `ci.yml` for a `conclusion === 'success'` run on the exact release SHA and `core.setFailed`s on timeout. |

The five pre-publish gates are intact and un-bypassable. Verified by the orchestrator's independent review and re-read here.

---

### Criterion 6 — flake lane and hygiene (GREEN-11 ✗ / GREEN-12 ✓)

**GREEN-12 — ✓ VERIFIED.**

| Check | Evidence |
|---|---|
| `git worktree list` | 1 entry (`/Users/jon/projects/threadline`) |
| Local branches | `main` only |
| Archive tags exist locally | `archive/backup/pre-release-cleanup-2026-05-08`, `archive/gsd/phase-166-unfreeze-token-lane-mechanism` |
| Pushed to origin as annotated objects | `git ls-remote --tags origin` shows both, each with a `^{}` peel — i.e. genuinely annotated, not lightweight |
| Register with recommendations | `.planning/ARCHIVE-REGISTER.md`, 2 rows, each carrying SHA, ancestry-verification outcome, reason, recommendation, and restore command |
| No milestone tag published | confirmed — the "milestone tags stay local" rule was not violated |

The register also states what it would say had there been no stale branches, so an absent register cannot be confused with a forgotten one. The `phase-166` row correctly records `merge-base --is-ancestor` exit 1 (real unmerged work, pinned before removal) versus the `backup/*` row's exit 0 (already merged, archived as provenance not preservation). This is the requirement's "never silently discarded" clause met precisely.

**GREEN-11 — ✗ FAILED.** See gaps. The time-bounded clause is met (`timeout-minutes: 120`, with an honest comment noting a green 51-run pass has never been observed and the bound should be tightened to observed p95). The classification and dedup logic is well-written — it anchors on a measured stable marker rather than an assumed one, and deliberately routes an absent header to `unknown` rather than `flaky`. **All of it is dead code on the failure path.** The failure is purely one of wiring, and the file's own comment asserts the wiring it does not have.

---

### Requirements Coverage

| Req | Description | Status | Evidence |
|---|---|---|---|
| GREEN-01 | Red run logs preserved in-repo | ✓ SATISFIED | `198-ci-run-28214113903-logs.md`, 8966 lines, verbatim |
| GREEN-02 | Credo histogram + concentration from external config | ✓ SATISFIED | 377 vs 0 baseline; `.credo.exs` diff clean |
| GREEN-03 | Mechanical sensitivity stated from evidence | ✓ SATISFIED | Executed probe + positive control; scorecards untouched |
| GREEN-04 | `mix test` passes, each failure fixed on its merits | ✗ BLOCKED | 80 failures; deferred with a documented remediation shape |
| GREEN-05 | Formless guard fails in the same diff | ✓ SATISFIED | 11/11 pages, derived roster, test passes |
| GREEN-06 | Every job `timeout-minutes`-bound; browser aborts early | ✓ SATISFIED | 24/24 jobs; `maxFailures: 5` |
| GREEN-07 | `origin/main` complete and its CI green ≤20min | ✗ BLOCKED | 6m07s ✓ but conclusion `failure` |
| GREEN-08 | Protection requires exactly the emitted names | ✓ SATISFIED | red→green pair on one SHA proves the guard discriminates |
| GREEN-09 | Paid scoring structurally untriggerable | ✓ SATISFIED | Workflow deleted + resurrection guard |
| GREEN-10 | Exactly one gated publish path | ✓ SATISFIED | List-equality guard + 5 intact gates |
| GREEN-11 | Broken vs flaky by name, bounded, dedup issue | ✗ BLOCKED | Classifier skipped on the failure path |
| GREEN-12 | One worktree, no stale branches, archive tags | ✓ SATISFIED | Tags on origin, annotated, register has 2 rows |

**Orphaned requirements:** none. All 12 IDs declared in PLAN frontmatter are accounted for, and REQUIREMENTS.md maps no additional ID to Phase 198.

**Traceability defect — REQUIREMENTS.md is wrong on one row.** Line 21 marks **GREEN-11 `[x]`** and line 141 lists it `Complete`. Given the classifier is unreachable on the failure path, that row must be flipped to `[ ]` / `Pending`. GREEN-04, 05, 06, 07 are already honestly recorded as pending (05 and 06 are in fact met and can be flipped to complete).

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `.github/workflows/flake-detection.yml` | 87, 101 | Comment asserts behavior the code does not implement | 🛑 Blocker | GREEN-11's entire behavioral claim |
| `.github/workflows/branch-protection.yml` | 27-28 | Insufficient `permissions:` makes an assertion unfalsifiable | ⚠️ Warning | Block (c) can never fail in CI |
| `bin/verify-branch-protection` | 107-108 | `|| echo "absent"` maps API failure to the passing branch | ⚠️ Warning | Error laundered into a pass |
| `bin/verify-branch-protection` | 96-98 | Same laundering in half (b): API failure → `EMITTED_COUNT` empty | ℹ️ Info | Fails closed here, so benign today |
| `.github/workflows/release.yml` | 5 | Stale comment cites deleted `hex-publish.yml` as a "legacy fallback path" | ⚠️ Warning | Invites a future maintainer to recreate the ungated second publish path GREEN-10 deleted |
| `test/.../ui_form_policy_contract_test.exs` | 43 | Token list omits `<.form` / `<.input` / `<.simple_form` | ⚠️ Warning | A page adding an idiomatic LiveView form would not trip the guard. Benign **today** — verified all 11 pages use raw HTML tags (0 occurrences of `<.form`/`<.input` repo-wide in `live/`) |
| `test/.../ui_form_policy_contract_test.exs` | 91-92 | `{:has_forms, _}` is an unconditional pass | ⚠️ Warning | Moduledoc claims reverse-drift coverage; a stale exemption after a form is removed is not caught. GREEN-05's own text only covers *gaining* a form, so not a blocker |
| — | — | No test asserts `timeout-minutes` universality | ⚠️ Warning | GREEN-06 holds today with no durable guard; a new job can silently land unbounded |

No unreferenced `TBD`/`FIXME`/`XXX` debt markers were found in phase-modified source.

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Form-policy guard passes | `mix test .../ui_form_policy_contract_test.exs .../zero_skips_contract_test.exs` | 3 tests, 0 failures | ✓ PASS |
| CI topology contract (incl. GREEN-09/10 guards) | `mix test .../ci_topology_contract_test.exs` | 12 tests, 0 failures | ✓ PASS |
| Full suite green | `mix test` | 1380 tests, **80 failures**, exit 2 | ✗ FAIL |
| Compile clean | `mix compile --warnings-as-errors` | exit 0 | ✓ PASS |
| Format clean | `mix format --check-formatted` | exit 0 | ✓ PASS |
| Every job bounded | AST parse of all 5 workflow `jobs:` blocks | 24/24 bounded | ✓ PASS |
| Publish-path uniqueness | `grep -rn "mix hex.publish" .github/` | only `release.yml:390,392` | ✓ PASS |
| Branch-protection guard discriminates | runs `33138291397` (fail) vs `33140020321` (pass), same SHA | red→green | ✓ PASS |
| Latest main CI green | `gh run list --workflow=ci.yml --branch main` | `failure`, 6m07s | ✗ FAIL |
| PR #26 mergeable | `gh pr view 26` | `BLOCKED` on failing `CI required` | ✗ FAIL |
| Archive tags on origin | `git ls-remote --tags origin \| grep archive` | both, annotated (`^{}` peels present) | ✓ PASS |
| Worktree / branch hygiene | `git worktree list`; `git branch` | 1 entry; `main` only | ✓ PASS |

### Probe Execution

No `scripts/*/tests/probe-*.sh` exist in this repository and no PLAN declares one — the project's equivalents are `mix verify.*` aliases, exercised above. Step 7c: not applicable.

---

## Gaps Summary

Phase 198 delivered a large amount of genuine, well-evidenced work, and its documentation is unusually honest — `198-TRIAGE.md` disproves its own plan's premise with measurement rather than executing against it, and reports 80 failures rather than manufacturing green. Nine of twelve requirements are met, several of them with guards that are demonstrably non-vacuous (the branch-protection red→green pair on an identical SHA; the list-equality publish guard; the glob-derived form-policy roster). The wall-clock result is a real win: 1h33m → 6m07s.

Three things stop the phase goal from being achieved, and they compound:

1. **The suite is still red (GREEN-04).** 79 real test-side defects that assume an unprefixed `search_path` remain, correctly diagnosed and correctly refused an "environmental" label, but not fixed. The remediation shape is documented; no later milestone phase claims it, so this is a genuine gap, not a deferral. One further failure — the `CONTRIBUTING.md` List 1 parity row — is recorded in TRIAGE as explicitly **unowned by any plan**.
2. **Therefore `main` CI is red (GREEN-07), therefore PR #26 is blocked.** The phase's headline promise — "`origin/main` carries every local commit and its CI concludes green" — is half-delivered: the commits landed and the loop is fast, but it is not green. With `bypass_actors: []` deliberately active, nothing merges until it is. The maintainer was told this cost before the ruleset was applied and accepted it.
3. **The flake classifier never runs (GREEN-11).** This is the one finding where the artifact and the claim genuinely diverge: the workflow's own comment says the classification and issue steps still run on failure, and they do not. It is a two-line fix (`set +e`, `if: always()`), and until it lands the entire behavioral content of GREEN-11 — classification by name, deduplicated tracking issue — is unreachable.

Two lower-severity items deserve carrying forward because they weaken guards the phase specifically built to prevent drift: block (c) of `bin/verify-branch-protection` cannot fail in CI under `permissions: contents: read`, and neither `enforcement` nor `bypass_actors` is ever asserted against live state despite the merge lock being predicated on the latter.

---

_Verified: 2026-08-28_
_Verifier: Claude (gsd-verifier)_
