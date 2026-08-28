---
phase: 198-green-bringup
verified: 2026-08-28T19:00:00Z
status: gaps_found
supersedes: "Prior 198-VERIFICATION.md (round 1, verified 2026-08-28T15:30:00Z, including its now-retracted GREEN-07 amendment). Round-1 findings are reconciled, not discarded — see 'Reconciliation with Round 1' below. This report is authoritative."
ci_measured:
  round_1: "PR #29, run 33183920952, FAILURE (6/13 checks red)"
  round_2: "PR #29, run 33197493051, FAILURE (11/14 checks red 3, aggregate red) — 13m29s wall clock"
score: 3/6 roadmap success criteria verified (8/12 requirements Complete, 4 Pending) — DOWN from round 1's reported 4/6 (11/12) because round 1's GREEN-04 completion claim did not survive a real CI run
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found (round 1, both before and after its retracted amendment)
  previous_score: "4/6 roadmap success criteria (11/12 requirements) — as claimed in round 1; this figure rested on local-only evidence for GREEN-04 and did not hold once measured against CI run 33197493051"
  gaps_closed:
    - "GREEN-11 (Flake Detection classifier reachable, WR-01 embedded-dash hardening) — closed in round 1, unchanged and re-confirmed this round via 198-CI-MEASUREMENT.md's local re-run; not touched by round-2 plans"
    - "GREEN-08 (branch protection exact-match) — closed in round 1, no drift, re-confirmed"
    - "GREEN-09/GREEN-10 (release-safety guards) — closed in round 1, unchanged"
    - "PgBouncer transaction topology job — genuinely fixed this round (198-14), CONFIRMED green on measured CI run 33197493051 (round 1 had NOT fixed this; round 1's GREEN-04 completion claim was actually wrong on this exact job)"
    - "Run test suite (min) — genuinely fixed this round (198-14/198-15), CONFIRMED green on measured CI run 33197493051"
    - "Two of 198-17's five diagnosed Playwright failures (operator-coverage-readiness.spec.ts, operator-accessibility.spec.ts) — confirmed fixed and held on the measured CI run; the 5 red tests on that run are a disjoint, already-known set (part of the 28-failure discovery)"
  gaps_remaining:
    - "GREEN-04 — still not met. A CI-measured Run test suite (current) failure was found (search_path ALTER missing at ci.yml:235-240), previously masked by the two now-fixed causes. This is a genuinely new discovery this round, not a round-1 miss that went unfixed — round 1's own CI run (33183920952) never reached this failure because verify.test failed first on that run."
    - "GREEN-07 — still not met. CI required concluded failure on the round-2 measured run (3 of 12 dependencies red: Run test suite (current), Tier A capture lane, Example app browser E2E)."
    - "SC3/SC4 (origin/main carries every commit, CI green, PR #26/29 mergeable) — still not met, same root cause as GREEN-07."
    - "Tier A capture lane — still red. 198-16 diagnosed the cause (document-wide scrollHeight read couples scroll_cost to stress-lab catalog size) and halted by design: every remedy requires Tier-A page.* regeneration, which 198-CONTEXT.md forbids this milestone. The maintainer was asked this session and chose to KEEP the prohibition. This is an ACCEPTED, ratified halt — not scored as an unfixed engineering gap, but the phase goal remains unmet because of it."
    - "Example app browser E2E — still red. 198-17 fixed its diagnosed 5 failures (confirmed held on the measured run) but surfaced 28 further pre-existing masked failures, deliberately deferred by maintainer decision this session (deferred-items.md, WINDOWS.md #8)."
  regressions: []
gaps:
  - truth: "GREEN-04 — `mix test` passes with no deterministically-failing tests, each former failure fixed on its merits"
    status: failed
    reason: "Local `mix test` is 1412/0 (1 excluded), verified twice and independently confirmed by this verifier's read of 198-CI-MEASUREMENT.md — but local evidence is explicitly NOT admissible for this requirement per its own text and per this phase's own D-01 ('green' is defined as fresh-clone-local AND CI, both reachable via `mix ci.all`). The measured CI run (33197493051) shows `Run test suite (current)` still fails: `mix verify.example`'s `ThreadlinePhoenixWeb.WalkthroughHappyPathTest` hits `(undefined_table) relation \"audit_transactions\" does not exist` because `.github/workflows/ci.yml:235-240`'s db-prep step never runs the `ALTER DATABASE ... SET search_path` statement its sibling jobs at `:346-355` and `:500-509` both carry. This is a fourth measured location of the exact defect class GREEN-04 exists to close."
    artifacts:
      - path: ".github/workflows/ci.yml"
        issue: "Lines 235-240 (verify-test job, current lane's db-prep step) omit the ALTER DATABASE ... SET search_path statement present at :346-355 (verify-example-browser) and :500-509 (verify-capture)"
    missing:
      - "Add the missing ALTER DATABASE statement to ci.yml:235-240, matching the two sibling jobs, then re-measure on a real CI run (not local) before marking GREEN-04 Complete"
  - truth: "GREEN-07 — `origin/main` carries every local commit and its latest CI run concludes `success` in ≤ 20 minutes"
    status: failed
    reason: "Time clause met (13m29s, well under 20min). Success clause not met: CI required concluded failure on run 33197493051 because 3 of 12 needs: dependencies were red (Run test suite (current), Tier A capture lane, Example app browser E2E). 4 of the originally-7 baseline-red jobs are now green (Compile without optional deps, Mechanical checker — round 1; PgBouncer transaction topology, Run test suite (min) — round 2)."
    artifacts:
      - path: "GitHub Actions run 33197493051 (PR #29, ci/198-gap-closure)"
        issue: "conclusion: failure; CI required aggregate: failure"
    missing:
      - "Fix the GREEN-04 search_path gap above (closes Run test suite (current))"
      - "A maintainer decision on Tier A capture lane (accept the ratified halt as permanently out of GREEN-07's critical path this milestone, or revisit the page.* regeneration prohibition)"
      - "A maintainer decision on the 28 masked Playwright failures (fix, further defer with an explicit successor plan, or narrow CI required's needs: to exclude these two lanes with an honest accounting of what that means for the aggregate's guarantee)"
  - truth: "SC3/SC4 — origin/main..main empty (SC3) and PR mergeable (SC4)"
    status: failed
    reason: "Direct consequence of GREEN-07 above. main was pushed via ci/198-gap-closure and PR #29 (the direct-push-to-main path is refused by the repository ruleset, per GREEN-08 working as designed). PR #29 remains BLOCKED because CI required is red on run 33197493051."
    artifacts:
      - path: "PR #29"
        issue: "mergeStateStatus BLOCKED (CI required red)"
    missing:
      - "Same as GREEN-07 above"
deferred: []
---

# Phase 198: Green Bringup — Verification Report (Post-Gap-Closure, Round 2)

**Phase Goal:** `origin/main` carries every local commit and its CI concludes green well inside a usable feedback loop; the red-test baseline that nobody re-derived is retired with each former failure fixed on its merits; branch protection requires exactly the checks CI emits; and the measurement sweep that sizes Phases 201 and 203 is on disk before either is planned.

**Verified:** 2026-08-28
**Status:** gaps_found
**Re-verification:** Yes — supersedes round-1 198-VERIFICATION.md (whose GREEN-07 amendment was itself made, then correctly retracted, mid-phase). This report covers gap-closure round 2 (plans 198-14 through 198-18) plus a fresh code-review pass with 2 new Critical findings.

## Goal Achievement — the phase goal is NOT achieved

CI on the real, measured PR run (`33197493051`) concludes `failure`. `origin/main` therefore does not carry a green-CI state of every local commit — the plainest possible reading of the phase's own headline sentence. This is scored honestly below rather than credited for the substantial, real engineering progress this round represents.

### Reconciliation with Round 1

Round 1's VERIFICATION.md went through three states in sequence, all preserved here for the record rather than discarded:

1. **Initial round-1 verdict (2026-08-28T15:30:00Z):** `gaps_found`, 4/6 success criteria (11/12 requirements), with GREEN-04 marked ✓ VERIFIED on **local-only** evidence (`mix test` 1398/0) and GREEN-07 marked ✗ FAILED because nothing had been pushed to `origin/main`.
2. **Amendment (same day):** the maintainer was told pushing `main` would "publish the full `.planning/` history to public GitHub" and, on that premise, agreed to loosen GREEN-07's wording. **This premise was false** — `.planning/` was already tracked and public on `origin/main`, including this very phase's own plans 01–07 (`git ls-tree` showed 2191 already-public `.planning/` files at retraction time). The amendment was correctly retracted the same day once this was measured.
3. **Post-retraction, measured (round 1's final state):** `main` was pushed as PR #29; CI run `33183920952` concluded `failure` (6/13 red). This is where round 1 actually ended: **GREEN-04's "Complete" mark from step 1 above did not survive the real CI run** — two causes invisible to any local `mix test` run (an ambient `examples/threadline_phoenix` deps-fetch dependency in `stress_router_test.exs`, and a `pgbouncer_topology_test.exs` unprefixed call site hidden behind the excluded `pgbouncer_topology` tag) turned out to be live defects. Round 1's closing document (embedded at the bottom of the superseded VERIFICATION.md as "MEASURED CI RESULT") correctly reopened GREEN-04 and stated the next real engineering work plainly.

**This verifier's score line (3/6, 8/12) is therefore lower than round 1's *reported* 4/6 (11/12) not because round 2 regressed anything, but because round 1's reported score was itself wrong** — it counted GREEN-04 as satisfied on local evidence the phase's own D-01 explicitly disallows, and a real CI run proved that call incorrect within the same day. Round 2 (plans 14–18) then did real, confirmed engineering: it fixed 2 of the 3 causes round 1's own measured run exposed (`PgBouncer transaction topology`, `Run test suite (min)` — both independently confirmed green on run `33197493051`), leaving one newly-discovered third cause (the `ci.yml:235-240` search_path gap) still open. Net honest position: **more of the real defect surface is now fixed and independently confirmed than at any prior point in this phase**, but the requirement-level scoreboard has not yet crossed to "met" for GREEN-04 or GREEN-07.

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Measurement sweep (GREEN-01/02/03) on disk, `.credo.exs` unmodified, no scorecard touched | ✓ VERIFIED (unchanged since round 1) | `.planning/audits/198-ci-run-28214113903-logs.md` present; `git status --porcelain .planning/scorecards/` clean at round-1 verification time; not touched by any round-2 plan (198-14..18's `files_modified` lists confirm no scorecard/`.credo.exs` writes) |
| 2 | `mix test` passes locally with no deterministically-failing tests | ✓ VERIFIED (local only) | 198-CI-MEASUREMENT.md Task 1: 1412 tests, 0 failures (1 excluded), two consecutive runs, byte-identical |
| 3 | `mix test`-equivalent passes on real CI (the requirement's own admissible evidence) | ✗ FAILED | CI run 33197493051: `Run test suite (current)` failure — 9 `WalkthroughHappyPathTest` failures, all `undefined_table` on `audit_transactions`, root-caused to `ci.yml:235-240`'s missing `ALTER DATABASE ... SET search_path` |
| 4 | Formless-page guard fails loudly on a legitimate new form (GREEN-05) | ✓ VERIFIED (unchanged since round 1) | Not touched by round-2 plans; round-1's re-run of `ui_form_policy_contract_test.exs` (13/13) stands, uncontradicted by anything measured this round |
| 5 | Every job carries `timeout-minutes`; browser suite aborts early (GREEN-06) | ✓ VERIFIED (unchanged since round 1) | Not touched by round-2 plans; `git diff 74db148a..HEAD -- .github/workflows/` confirms no structural job changes beyond the round-2 diagnosis/fix commits, none of which removed a `timeout-minutes` bound |
| 6 | `origin/main` carries every local commit and its latest CI run concludes `success` ≤20min (GREEN-06/07) | ✗ FAILED | `git push origin HEAD:ci/198-gap-closure` (direct push to `main` refused by ruleset, as designed); CI run 33197493051, wall clock 13m29s (time clause met), conclusion `failure` (success clause not met) |
| 7 | Branch protection requires exactly the emitted check names; PR mergeable (GREEN-08) | ⚠️ PARTIAL — GREEN-08 itself ✓, mergeability ✗ | `.github/workflows/ci.yml` and `.github/rulesets/` byte-identical across the whole round-2 diff (`git diff 74db148a..HEAD` on those paths empty) — GREEN-08 unchanged and not retested this round, standing on round 1's red→green discrimination pair; `gh pr view 29 --json mergeStateStatus,state` → `BLOCKED`, downstream of GREEN-07 |
| 8 | Paid critic scoring untriggerable; exactly one gated Hex publish path (GREEN-09/10) | ✓ VERIFIED (unchanged since round 1) | Not touched by round-2 plans |
| 9 | Flake Detection classifies broken vs flaky, dedup issue; one worktree, no stale branches (GREEN-11/12) | ✓ VERIFIED (unchanged since round 1) | 198-CI-MEASUREMENT.md Task 1 re-ran the classifier's contract-test coverage as a byproduct of the full-suite run (1412/0 includes it); not touched by round-2 plans |
| 10 | The static call-site sweep (198-14) enumerates EVERY Ecto call site against Threadline-owned schemas, with no escape hatch | ✗ FAILED — see analysis below (verification_focus #3) | 198-REVIEW.md CR-01, CR-02, independently reproduced by the orchestrator via `Regex.scan/2` this session |

**Score:** 3/6 roadmap success criteria fully verified (Criteria 1, 5, unchanged-parts of 6). Criteria 2, 3, 4 (partially) not met. 8/12 requirements Complete (GREEN-01, 02, 03, 05, 06, 08[wiring only], 09, 10, 11, 12 — note GREEN-08's own text is met but its downstream mergeability consequence is not), 4/12 Pending (GREEN-04, GREEN-07, and the two success-criteria consequences these drive).

---

### Requirements Coverage — reconciled against REQUIREMENTS.md on disk

| Req | Description | REQUIREMENTS.md status (as of this verification) | This verifier's independent finding | Agreement? |
|---|---|---|---|---|
| GREEN-01 | Red run logs preserved in-repo | [x] Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-02 | Credo histogram + concentration, `.credo.exs` untouched | [x] Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-03 | Mechanical sensitivity stated from evidence | [x] Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-04 | `mix test` passes, each failure fixed on its merits | [ ] Pending, with an unusually thorough inline note citing run `33197493051` and the exact `ci.yml:235-240` cause | ✗ BLOCKED — confirmed by this verifier via the same run; REQUIREMENTS.md's own text is accurate and non-vacuous | Yes — correctly recorded as Pending, not over-claimed |
| GREEN-05 | Formless guard fails loudly in-diff | [x] Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-06 | Every job `timeout-minutes`-bound; browser aborts early | [x] Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-07 | `origin/main` complete, CI green ≤20min | [ ] Pending, with the same run cited and an accurate 3-of-12-red breakdown | ✗ BLOCKED — confirmed | Yes — correctly recorded |
| GREEN-08 | Branch protection requires exactly the emitted names | [x] Complete | ✓ SATISFIED (the requirement's own literal text — protection contexts match emitted names) — but this is a narrower claim than "PR is mergeable," which REQUIREMENTS.md does not claim for GREEN-08 | Yes — REQUIREMENTS.md does not over-claim mergeability under this ID |
| GREEN-09 | Paid scoring structurally untriggerable | [x] Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-10 | Exactly one gated publish path | [x] Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-11 | Broken vs flaky by name, bounded, dedup issue | [x] Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-12 | One worktree, no stale branches, archive tags | [x] Complete | ✓ SATISFIED, unchanged | Yes |

**No over-claim or under-claim found in REQUIREMENTS.md.** This is a materially different finding from round 1's initial pass (which had briefly marked GREEN-04 Complete on local-only evidence, later self-corrected) — the current state on disk is honest, cites the exact measured run, and states the exact remaining cause. This is worth naming explicitly: **the traceability discipline this phase exists to enforce is now visibly working on itself.**

**Plan → requirement traceability:** every plan's frontmatter `requirements:` field was checked against REQUIREMENTS.md's GREEN-01..12. All 12 IDs are claimed by at least one plan (198-01 → GREEN-01/02/03; 198-02 → none declared, credential audit, not requirement-bearing by design; 198-03 → GREEN-07/08; 198-04 → GREEN-04/05; 198-05 → GREEN-06/07; 198-06 → GREEN-09/10/11/12; 198-07 → GREEN-07/08/12; 198-08 → GREEN-04; 198-09 → GREEN-07; 198-10 → GREEN-07; 198-11 → GREEN-11; 198-12 → GREEN-04; 198-13 → none declared, closing/traceability plan; 198-14 → GREEN-04; 198-15 → GREEN-04; 198-16 → GREEN-04; 198-17 → GREEN-04; 198-18 → GREEN-07). **No orphaned requirement.** Plans 198-13/198-14/198-15/198-16/198-17 initially appeared to have empty `requirements:` in a shallow grep pass (an earlier automated scan in this session mis-parsed the YAML list-block syntax `requirements:\n  - GREEN-04` as empty) — re-checked directly by reading each file's frontmatter in full; all but 198-02 and 198-13 in fact declare a requirement.

---

### Focus Item — Must-Have Assessment: 198-14's static call-site sweep

**198-14's must-have text (verbatim from its PLAN frontmatter):** *"A static contract test enumerates every Ecto call site in `test/**/*.exs` that names a Threadline-owned schema module and fails when any one of them omits `repo_opts` — and it does so by reading source, so a tag-excluded or environment-gated file is scanned exactly like a file that runs by default."*

**Verdict: UNMET, as literally worded.** Two confirmed, reproduced escape hatches (198-REVIEW.md CR-01, CR-02; independently re-reproduced by this verifier and the orchestrator this session via `Regex.scan/2` against the actual compiled regex in `test/threadline/storage_schema_call_site_contract_test.exs`):

1. **CR-01 — the receiver regex's `(?<![\w.])` lookbehind is blind to fully-qualified receivers.** `Threadline.Test.Repo.delete_all(...)` — the shape used at 73 real call sites across 9 files — produces zero regex matches. Confirmed: `Regex.scan(~r/(?<![\w.])(?:Repo|@repo|repo)\.(?:insert!|insert|delete_all)\(/x, "Threadline.Test.Repo.delete_all(AuditChange)")` → `[]`, versus `Regex.scan(same, "Repo.delete_all(AuditChange)")` → one match.
2. **CR-02 — `insert_all` is absent from `@ecto_functions`**, and the function-name alternation requires an immediate literal `(`, so the `insert` entry cannot partial-match `insert_all(` either. Confirmed against the two real `insert_all` call sites in the tree (`timeline_live_test.exs:458`, `export_controller_test.exs:431`) — zero matches at either line.

**Why this is UNMET rather than "met with caveats":** the must-have's own language is absolute — "enumerates *every* Ecto call site," "no permitted-file collection, no opt-out source marker, and no skipped-path constant" (moduledoc, quoted in 198-REVIEW.md). It is not worded as "enumerates every call site of the specific shapes exercised in this round's fixtures." A sweep whose own selling point is exhaustiveness, with two concrete, reproduced blind spots covering 75 real call sites, does not meet its own bar. The distinction that matters and is correctly preserved in the review: **no live offense exists today** (every one of those 75 sites currently carries `repo_opts()` or the older `storage_opts` binding) — so this is not a currently-manifesting regression, but it is a false completeness guarantee, which is precisely the "matches nothing, silently" failure class 198-CONTEXT.md's own D-05 anti-laundering framing was written to prevent. A future contributor writing `Threadline.Test.Repo.delete_all(AuditChange)` or `repo.insert_all(AuditChange, entries)` with no opts gets a green run and a real, silent, undetected regression of the exact defect class `pgbouncer_topology_test.exs` demonstrated reaches production.

**This is treated as part of the GREEN-04 gap, not a separate blocker**, because GREEN-04's own text ("each former failure fixed on its merits") is satisfied for what the sweep does catch, and no live offense exists — but it is flagged here explicitly per the verification focus, and belongs in round 3's scope precisely because the review already scoped, reproduced, and specified concrete fixes (CR-01's regex change, CR-02's roster addition) that were deliberately NOT applied this session to avoid desynchronizing the tree from the CI run REQUIREMENTS.md cites.

---

### Anti-Patterns Found (this round's diff, `74db148a..HEAD`)

| File | Line | Pattern | Severity | Status |
|---|---|---|---|---|
| `test/threadline/storage_schema_call_site_contract_test.exs` | 56-66 | CR-01: `(?<![\w.])` lookbehind blinds the sweep to fully-qualified `Threadline.Test.Repo.*` receivers (73 call sites, 9 files) | 🛑 Blocker (to the must-have's own exhaustiveness claim, not to GREEN-04's live-defect scope) | Diagnosed, fix specified, NOT applied (deliberate, to avoid desyncing from the cited CI run) |
| `test/threadline/storage_schema_call_site_contract_test.exs` | 38-52 | CR-02: `insert_all` absent from `@ecto_functions`; 2 real call sites invisible | 🛑 Blocker (same qualification as CR-01) | Diagnosed, fix specified, NOT applied |
| `test/threadline/storage_schema_call_site_contract_test.exs` | 170-192 | IN-02: `contains_unclosed?/3` uses a literal `"end"` substring match, not syntactic `do`/`end` balance tracking | ℹ️ Info | Not currently reproducible against real code; robustness gap only |
| `.github/workflows/ci.yml` | 235-240 | GREEN-04's third, newly-measured cause: db-prep step omits the `ALTER DATABASE ... SET search_path` its siblings at :346-355/:500-509 carry | 🛑 Blocker | Diagnosed this round via the measured CI run; not yet fixed |

No unreferenced `TBD`/`FIXME`/`XXX` debt markers found in the round-2 diff. No new laundering pattern (`search_path` restoration, default prefix, skip tags) — the round-1 anti-laundering re-scan stands, unchanged by anything in this diff.

---

### Probe / Behavioral Evidence

| Behavior | Command | Result | Status |
|---|---|---|---|
| Local suite green | `mix test` (per 198-CI-MEASUREMENT.md, ×2) | 1412 tests, 0 failures (1 excluded), byte-identical both runs | ✓ PASS (local only — inadmissible alone for GREEN-04 per D-01) |
| CI `Run test suite (current)` | Measured run 33197493051 | 9 failures, `undefined_table` on `audit_transactions` | ✗ FAIL |
| CI `Run test suite (min)` | Measured run 33197493051 | success, 4m26s | ✓ PASS (genuinely new this round) |
| CI `PgBouncer transaction topology` | Measured run 33197493051 | success, 1m57s | ✓ PASS (genuinely new this round) |
| CI `Tier A capture lane` | Measured run 33197493051 | failure — `scroll_cost` drift, exactly as 198-16 diagnosed and predicted | ✗ FAIL (expected-red, ratified halt) |
| CI `Example app browser E2E` | Measured run 33197493051 | failure — 5/305/50, exactly the known 28-failure-set members, exactly as 198-17 predicted | ✗ FAIL (expected-red, deferred) |
| CI `CI required` aggregate | Measured run 33197493051 | failure | ✗ FAIL |
| CR-01 reproduction | `Regex.scan/2` against the live `@call_regex` | `Threadline.Test.Repo.delete_all(...)` → `[]` (no match) | ✗ FAIL — confirms the review finding |
| CR-02 reproduction | `Regex.scan/2` against the live `@call_regex` | `repo.insert_all(...)` at both real call sites → `[]` (no match) | ✗ FAIL — confirms the review finding |

No `scripts/*/tests/probe-*.sh` exist for this project; the `mix verify.*`/`mix ci.*` aliases and the direct CI-run measurement above are the equivalent evidence.

---

### SUMMARY claims not supported by the codebase

1. **198-14-SUMMARY's claim that the sweep catches "any future Threadline-owned schema call site added anywhere under `test/`"** is not supported — two concrete, reproduced counterexamples exist (CR-01, CR-02). This is the review's own finding, not a new one, but it belongs here explicitly per this verification's focus: the SUMMARY's absolute wording does not match the code's actual behavior.
2. **No other SUMMARY claim in plans 14-18 was found to be false.** 198-15's and 198-17's claims about their specific fixes holding on real CI were independently confirmed by the measured run (the two previously-failing Playwright specs no longer appear among the 5 failures; `Run test suite (min)` and `PgBouncer transaction topology` are both genuinely green). 198-16's halt claim is corroborated by the measured run reproducing the exact `scroll_cost` drift direction and magnitude. 198-18's CI-measurement claims match this verifier's own independent read of `198-CI-MEASUREMENT.md` and are not contradicted by anything found this pass.

---

### Human Verification Required

None. Every truth in this phase resolves to a measured, on-disk, machine-checkable state (a CI run's JSON conclusion, a regex reproduction, a file diff) — no visual, UX, or subjective judgment call remains open.

---

## What Round 3 must do (ordered, derived from measured evidence)

1. **Fix `ci.yml:235-240`** — add the `ALTER DATABASE threadline_phoenix_test SET search_path TO "$user", public, threadline;` statement to the `current`-lane db-prep step, matching `:346-355` and `:500-509`. This is the highest-leverage single fix: it is the only remaining cause standing between `Run test suite (current)` and green, and therefore the only remaining cause standing between GREEN-04 and Complete.
2. **Fix the two sweep regex gaps (CR-01, CR-02)** in `test/threadline/storage_schema_call_site_contract_test.exs`, per the review's already-specified fixes: widen the lookbehind to admit `CamelCase.` chains before `Repo` while still rejecting `MyRepo`/`some_repo`; add `insert_all` (and the other listed missing Ecto.Repo callbacks) to `@ecto_functions`. Add the review's specified regression fixtures (`Threadline.Test.Repo.delete_all(AuditChange)` and `repo.insert_all(AuditChange, [...])` with no opts, both asserted `offense: true`) so this class has teeth going forward. No live offense exists today, so this carries no urgency risk, but it should land before round 3 declares GREEN-04 truly complete — the requirement's own bar is "each former failure fixed on its merits," and a sweep that silently can't see 75 real call sites is not that bar met, even though nothing is on fire.
3. **Push and re-measure** — after (1) and ideally (2), push to a fresh `ci/198-*` branch/PR and observe a real CI run. Do not mark GREEN-04 or GREEN-07 Complete on local evidence; this phase's own history (round 1's initial GREEN-04 claim reopened within the same day) is the strongest available argument for that discipline.
4. **Decision-dependent, in this order of urgency:**
   - **Tier A capture lane** — the maintainer already ratified keeping the page.* regeneration prohibition this session. Round 3's job is not to re-litigate this but to decide whether `CI required` should keep `needs:`-ing this lane (permanently red until the prohibition lifts, meaning GREEN-07 can never close while it's in the aggregate) or be restructured — e.g., moved out of the required aggregate with an explicit, documented rationale, consistent with D-08's own "durable job-id contract" framing, rather than left as a silent permanent blocker to the phase's own stated exit condition.
   - **The 28 masked Playwright failures** — same structural question. `deferred-items.md` and `WINDOWS.md #8` correctly log these as needing "a follow-up 198 (or successor-phase) gap-closure plan." Round 3 should either be that plan, or make an equally explicit decision to move `Example app browser E2E` out of `CI required`'s `needs:` with a stated rationale, since as currently constituted this lane's known-28-failure debt has the same practical effect as the Tier A halt: it structurally caps GREEN-07 at "cannot close."
5. **Do not re-litigate GREEN-07's wording.** The round-1 amendment attempt was made on a false premise and correctly retracted; `origin/main` already carries `.planning/` publicly, so there is no policy conflict left to invoke. The remaining path to GREEN-07 is entirely the engineering and decision items above, not a wording change.

---

## Anti-Patterns / WINDOWS.md carried-forward debt (unchanged, not gaps for this phase)

- CR-03 (`branch-protection.yml:27-28` `permissions: contents: read` makes block (c) unfalsifiable in CI) — WARNING, WINDOWS.md #5.
- CR-04 (block (b) launders an API-scope failure into an empty `EMITTED_COUNT`) — WARNING, WINDOWS.md #6.
- CR-05 (`.github/rulesets/main.json` never diffed against live state) — WARNING, WINDOWS.md #7.
- IN-01 (`optional_deps_contract_test.exs`'s `guarded?/1` checks only the first line) — accepted, no change, `verify.compile_no_optional` is the real backstop.
- IN-02 (`contains_unclosed?/3` substring-based `"end"` match) — Info, not currently reproducible against real code.

---

## Gaps Summary

Phase 198 has made substantial, independently-confirmed progress across two gap-closure rounds: of the 7 originally-red baseline jobs, **4 are now genuinely green** (`Compile without optional deps`, `Mechanical checker` — round 1; `PgBouncer transaction topology`, `Run test suite (min)` — round 2), each confirmed against a real, measured CI run rather than local evidence or SUMMARY narration. The measurement sweep (GREEN-01/02/03), release-safety guards (GREEN-09/10), branch-protection contract (GREEN-08's own text), and flake-detection wiring (GREEN-11/12) are all genuinely closed and unchanged by anything in this round.

**The phase goal is not achieved.** `origin/main`'s branch-protected merge path (PR #29, the only route since direct pushes to `main` are ruleset-refused) carries a `CI required` aggregate that concluded `failure` on the last measured run. Three causes remain:

1. **`Run test suite (current)`** — a real, still-open engineering gap (missing `ALTER DATABASE` statement), newly discovered this round because fixing the two round-1 causes let the job progress far enough to reach it. Straightforward to fix; not yet fixed.
2. **`Tier A capture lane`** — an accepted, ratified halt. The cause is fully diagnosed (198-16); every remedy requires a Tier-A evidence regeneration this milestone's own maintainer-confirmed policy forbids. Not an unfixed defect in the ordinary sense — a structural constraint the phase cannot resolve without a policy change outside this phase's authority.
3. **`Example app browser E2E`** — 5 of the diagnosed failures are genuinely fixed and held (confirmed on the measured run); 28 further pre-existing, masked failures were discovered and deliberately deferred, logged with an explicit successor-plan pointer.

Additionally, the static call-site sweep introduced this round (198-14) does not meet its own stated must-have of exhaustive coverage — two reproduced regex blind spots (75 real call sites) exist, though no live offense results from them today. This is recorded as part of the GREEN-04 gap rather than a separate blocker, per the analysis above.

**REQUIREMENTS.md's own record is accurate** — GREEN-04 and GREEN-07 are correctly marked Pending with precise, evidence-backed inline notes citing the exact measured run and cause. This is worth stating plainly: the traceability discipline this milestone exists to enforce is visibly working, including on itself, including through a self-correcting sequence (round 1's brief over-claim, caught and reopened within the same day).

---

_Verified: 2026-08-28_
_Verifier: Claude (gsd-verifier)_
