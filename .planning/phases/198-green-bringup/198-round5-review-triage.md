# Round-5 Review Triage Ledger

**Phase:** 198-green-bringup, plan 198-36
**Source:** `REVIEW.md` (2026-08-29T13:22:38Z, `diff_range: 35f1b519..455c2328`), 20 findings (5 Critical, 11 Warning, 4 Info)
**Purpose:** close the round-5 books before the measured CI run (plan 198-37) — every finding gets a
disposition verified against the tree as it stands after waves 1-3, not against the plans that promised it.

## Mechanical completeness proof

```
$ grep -oE "(CR|WR|IN)-[0-9]{2}" .planning/phases/198-green-bringup/REVIEW.md | sort -u > /tmp/198-r5-review-ids.txt
$ grep -oE "(CR|WR|IN)-[0-9]{2}" .planning/phases/198-green-bringup/198-round5-review-triage.md | sort -u > /tmp/198-r5-ledger-ids.txt
$ diff /tmp/198-r5-review-ids.txt /tmp/198-r5-ledger-ids.txt
(no output — sets are identical)
```

REVIEW.md's finding-id set: `CR-01 CR-02 CR-03 CR-04 CR-05 IN-01 IN-02 IN-03 IN-04 WR-01 WR-02 WR-03 WR-04
WR-05 WR-06 WR-07 WR-08 WR-09 WR-10 WR-11` — 20 ids, none missing, none invented.

## Disposition counts

| Disposition | Count |
|---|---|
| `fixed` | 18 |
| `deferred` | 1 (IN-01) |
| `no-action-required` | 1 (IN-04) |
| `unaddressed` | 0 |
| **Total** | **20** |

Every `fixed` row's citation below is a command with its own output (a `grep` hit, a test-file line, or
a full-suite pass count) re-run directly against this tree — not a SUMMARY filename. Where a SUMMARY's
claim and the tree's evidence could plausibly diverge, both are named; in every row checked below they
agree, and that agreement is itself the finding — no SUMMARY claim was taken on faith.

## Ledger

| Finding | One-line restatement | Owning plan | Disposition | Verification citation |
|---|---|---|---|---|
| CR-01 | Private `export_job_status_label/1` duplicated the canonical copy contract and diverged on 3/5 branches | 198-34 | fixed | `grep -c "defp export_job_status_label" lib/threadline/operator_surface/live/export_status_live.ex` → `0`. Render site now calls the canonical function: `export_status_live.ex:308` → `<%= Presentation.export_status_label(job) %>`; `presentation.ex:373` defines `def export_status_label(job, opts \\ [])`. Maintainer decision recorded in `198-34-DECISION.md` (Option B, `retain-with-reason` for `export_action_label/2`). |
| CR-02 | Coverage-snapshot assertions matched static `<dt>` labels regardless of count — vacuous pass | 198-32 | fixed | `walkthrough_evidence_test.exs:104-105` → `assert coverage_html =~ ~r/<dt>Covered<\/dt>\s*<dd>[1-9]\d*<\/dd>/` and the `Needs capture` sibling, discriminating on count, not label. |
| CR-03 | `assert record.subject_ref == subject_ref` was tautological against the query's own filter columns; the manifest-literal pin was deleted | 198-32 | fixed | `demo_contract_test.exs:259` → `assert subject_ref == %{"policy" => "walk-demo-redaction-policy"}` restored, ahead of the retained (now honestly-labelled) round-trip assertion. |
| CR-04 | Phase-177 group-story coverage floor dropped from 12 enumerated stories to `length > 0` | 198-33 | fixed | `operator-phase-177-uat.spec.ts:51` → `.toBeGreaterThanOrEqual(GROUP_STORY_FLOOR)` (12), `:57` → 4 pinned identities asserted via `.toContain(...)`. |
| CR-05 | Phase-135 authorization UAT stopped proving authorization — asserted a lane-capability descriptor any role can see | 198-33 | fixed | `operator-phase-135-uat.spec.ts:110` → test renamed `"Coverage is role-discriminating: support gets the unavailable lane, admin gets the table"`; `:127` asserts `coverage-table` has count 0 for support, `:138` asserts `admin.page.getByTestId("coverage-table")` is visible via a fresh browser context. Both halves independently teeth-proofed (198-33-SUMMARY.md, verbatim red-then-green captures for each half). |
| WR-01 | Session-scoped advisory lock leaked on an ExUnit timeout kill, poisoning the pool | 198-30 | fixed | `grep -c "pg_advisory_lock("` on `reset.ex`, `seed.ex`, `walkthrough_case.ex` → `0` each (all three files). `reset.ex:57` defines `with_demo_lock/1`; `:89` uses `pg_try_advisory_lock($1, $2)` in a bounded retry loop, not the unbounded blocking form. |
| WR-02 | The lock guarded only `WalkthroughCase`'s own callers; the cited concurrent-intra-run cause was structurally impossible | 198-30 | fixed | Lock moved into `Demo.Reset.run/1` and `Demo.Seed.run/0` (every entry point) — same `pg_try_advisory_lock` calls as WR-01's citation. `walkthrough_case.ex` no longer contains any `pg_advisory_lock` call (see WR-01 grep, `0`); comment corrected per 198-30-SUMMARY.md. |
| WR-03 | Retention cutoff (60) and org-Y backdate (90) were two independent magic numbers with no enforced ordering | 198-35 | fixed | `retention_tail.ex:31` → `@earliest_other_org_epoch_offset_days 21`; `:61` → `unless @earliest_other_org_epoch_offset_days < @retention_purge_cutoff_days_before_epoch and ...` compile-time guard. Perturbation proofs (four boundary violations, each raising a named `CompileError`) captured verbatim in 198-35-SUMMARY.md "Behavior Assertions". |
| WR-04 | Safety comment's stated margin (`-14 day` filler bound) was factually wrong; true earliest offset is `-21 day` | 198-35 | fixed | `retention_tail.ex:21-22` → comment now cites `personas.ex:99` and `temporal.ex:37` with the correct `-21` day figure, matching the ledger row above's `@earliest_other_org_epoch_offset_days 21`. |
| WR-05 | Purge remained globally time-scoped with no direct cross-org survival assertion; retention env write was never restored | 198-35 | fixed | `retention_tail.ex:343` → `defp assert_other_orgs_survived!(org_y_id)`, called at `:108`. `grep -c "Application.put_env"` on the file → `2` (one write at `:180`, one restore at `:105` inside an `after` block). |
| WR-06 | 177 rewrite put 60 navigations under one 120s budget that previously covered 5, and `test.step` failures hid unproven stories | 198-33 | fixed | `operator-phase-177-uat.spec.ts:169` → `test.setTimeout(budgetMs)` derived from a measured per-story cost; `:205-209` → try/catch collects a `STORY_VERDICT: PASS\|FAIL` line per story into a `failures[]` array, so one failure no longer hides the other 11. Teeth-proofed live (198-33-SUMMARY.md "Task 2 — per-story independence proof"). |
| WR-07 | `resolveGroupStories` never verified returned ids were actually group stories; an unrecognised filter value silently returns the whole catalog | 198-33 | fixed | `operator-phase-177-uat.spec.ts:68` → `expect(id, ...).toMatch(/^group\./)` for every resolved id. Teeth-proofed by temporarily pointing the navigation at a bogus category and capturing the resulting failure (198-33-SUMMARY.md "Task 1 — filter-applied proof"). |
| WR-08 | `operator-nav-shell` `<nav>` landmark claim was asserted only in a comment, not in code | 198-31 | fixed | `operator-phase-175-uat.spec.ts:97-98` → `expect(await shell.evaluate((el) => el.tagName)).toBe("NAV")` and `toHaveAttribute("aria-label", "Audit navigation")`. |
| WR-09 | Actor-page assertion lost its type/prefix check and could trip Playwright strict mode on raw-interpolated ids | 198-31 | fixed | `operator-screenshots.spec.ts` — `.first()` present at two sites (`:105`, `:114`) guarding strict-mode collisions; `JSON.stringify(leavingAgentId)` quoting and the restored `<:metadata key="Kind">`-scoped type assertion recorded in 198-31-SUMMARY.md's Files list and this plan's own read of the diff. |
| WR-10 | `refute timeline_html =~ "View Incident"` was deleted rather than kept alongside the new positive assertion | 198-32 | fixed | `walkthrough_evidence_test.exs:55` → `refute timeline_html =~ "View Incident"`, present alongside the positive `"No captured changes"` assertion. |
| WR-11 | `<details>` expansion in the mobile spec was order-dependent with no state assertion | 198-31 | fixed | `operator-find-mobile.spec.ts:123` → `await expect(row).toHaveAttribute("open", "")` after a conditional click, matching the plan's own fix snippet. |
| IN-01 | Row-history screenshot targets a content-sized element with no height guard (informational, not required) | this plan (198-36) | deferred | `operator-screenshot-regression.spec.ts:77-78` → `test.skip(!!process.env.CI, ...)`, confirming the file (and this finding) does not bear on the measured CI lane. Matching entry appended to `deferred-items.md` under `## Round 5` (Task 2 of this plan). |
| IN-02 | `@demo_seed_lock_key` was an unnamespaced `phash2` value | 198-30 | fixed | `reset.ex:18-19` → `@advisory_lock_classid 84_672_301`, `@advisory_lock_objid 1`, a fixed application-specific classid replacing the unnamespaced hash. |
| IN-03 | `demo_reset_test.exs:56` cold `MIX_ENV=prod` compile timeout — REVIEW.md itself declined to re-raise this as a new finding, describing the correct fix as moving the cold compile out of the per-test budget | 198-30 | fixed | `demo_reset_test.exs:21` → `setup_all do` now runs the cold `MIX_ENV=prod mix compile` once, outside ExUnit's per-test `:timeout`, exactly the remedy IN-03's own text names ("pre-warm `_build/prod`... or replace the shell-out"). Measured cold/warm compile figures (30.3s / 0.73s) and warm guard-only figure (0.748s, inside the 60000ms default) recorded in 198-30-SUMMARY.md. |
| IN-04 | REVIEW.md's own list of verified-correct changes — asks for nothing | this plan (198-36) | no-action-required | REVIEW.md itself states these edits were "traced to product source and are strictly-or-equally strict" and requests no fix. Recorded here rather than omitted, per this plan's own rule that `no-action-required` requires the reason to be stated, not left out. |

## Round-5 actionable causes

Per `198-CI-MEASUREMENT.md`'s round-4 "Gaps Summary" and `198-round4-playwright.md`, round 4's measured
CI run left four concrete actionable causes for round 5. All four are recorded here, including whether
each actually closed — not only the ones that moved.

| Cause | Closing evidence | Closed? |
|---|---|---|
| `demo_reset_test.exs:56` cold-compile `ExUnit.TimeoutError` (60000ms), sole GREEN-04 blocker on run `33253587315` | 198-30 Task 1: cold compile moved into `setup_all`, measured cold=30.3s/warm=0.73s/warm-guard-only=0.748s (inside the 60000ms default, no `@tag timeout:` needed). Local `mix verify.example` = 109/0 twice. **This is a local readiness signal only per D-01 — the measured-CI re-run is plan 198-37's concern, not proven closed here.** | Locally, yes. On CI, unmeasured by this plan. |
| Export-status locator row 1 — `operator-accessibility.spec.ts:565:3`, stale `/Expired/` regex broken by 198-25's canonical copy fix | 198-31 Task 1: re-anchored to `/Export expired\|File unavailable/`. Local pass confirmed both projects (198-31-SUMMARY.md). | Yes, locally. |
| Export-status locator row 2 — `operator-prove-mobile.spec.ts:38:3`, same cause | 198-31 Task 1: same re-anchor. Local pass confirmed both projects. | Yes, locally. |
| `operator-responsive-mobile-first.spec.ts:577:5` — un-inventoried CI-only failure, round-4's own record explicitly states "cause not established" | 198-31 Task 2 diagnosed the cause at the product level (the shared `expectOperatorChrome` mobile-nav-toggle click firing the row-history drawer's own `phx-click-away`, `row_history_component.ex`), confirmed by direct standalone reproduction outside the test harness, and fixed test-side with a scoped `exerciseMobileNav` opt-out. **This closed — it was not an honest halt.** The plan's own read_first note anticipated a possible halt outcome; the diagnosis in `.planning/audits/198-round5-playwright.md` shows plan 198-31 fixed it at cause instead, with a named mechanism and a passing local re-run on both projects (198-31-SUMMARY.md coverage D2). | Yes, locally, at cause — no halt occurred. |

**Stated plainly:** all four causes moved locally. None of round 5's actionable causes is recorded here
as closed on measured CI — that measurement is plan 198-37's job, and this ledger does not anticipate it.

## Structurally uncloseable inside milestone v1.41

Two items remain red by construction, not by defect, and nothing in round 5 (including this plan)
attempted to close them:

1. **Tier A capture lane (`verify-capture`).** `.github/workflows/ci.yml:550-558`'s byte-stable
   regeneration check fails because 198 committed scorecard files show drift (`scroll_cost` field,
   deterministic across rounds 2-4). The only available remedy is Tier-A `page.*` scorecard
   regeneration. `REQUIREMENTS.md`'s "Out of Scope" table states: *"Regenerating Tier-A `page.*`
   scorecards | Not reproducible in this environment (v1.40 Seed #3). The committed scorecards are the
   floor; regenerating them would manufacture a floor rather than measure one."* Cited also in
   `198-CI-MEASUREMENT.md` (round-4 GREEN-07 entry) and `.planning/audits/198-tier-a-byte-stability.md`
   as owned by D-39.
2. **`operator-stress.spec.ts` `page.*` ledger-baseline screenshot diffs — `page.home.happy` and
   `page.timeline.empty`, dark 1024px.** `operator-stress.spec.ts:15` and `:104-153` define these two
   stories. `198-31-SUMMARY.md`'s "Next Phase Readiness" explicitly names both as "the lane's remaining
   structural red" after its own three fixes landed, and no round-5 plan's `files_modified` list
   includes `operator-stress.spec.ts`'s baseline PNGs (`git diff` over `'*.png'` confirmed empty by
   every round-5 plan's own verification section).

Both items' only remedy is `page.*` baseline regeneration, which the maintainer declined to authorize
by narrowing `ci-required`'s `needs:` list (D-39, D-42) — `.github/`, `CONTRIBUTING.md`,
`.planning/scorecards/` and `playwright.config.ts` are byte-unchanged across every round-5 plan. They
are red **by construction**, not by defect, and this plan attempts no closure of either.

## Product findings surfaced by round 5

Per this plan's `must_haves`, a product finding a round-5 plan uncovered must be recorded here verbatim,
not absorbed into a fix narrative.

**Phase-135 Coverage admin half — 198-33's own teeth proof.** Before 198-33 landed the admin half of the
role-discriminating Coverage test, the *prior* round-4 test had no admin-side assertion at all (CR-05's
own finding). 198-33's teeth-proof section captured what happens when each half is independently
removed, confirming both halves are load-bearing on the *shipped* product (not a residual defect —
these are the plan's own before/after captures, reproduced verbatim below since they are the closest
this round came to a product-level authorization finding):

```
Admin half removed (deny admin too — "Coverage dead for every role"):
Error: expect(locator).toBeVisible() failed
Locator: getByTestId('coverage-table')
Expected: visible
Timeout: 15000ms
Error: element(s) not found
    at .../operator-phase-135-uat.spec.ts:138:62
    admin.page.getByTestId("coverage-table")

Support half removed (authorize everyone — simulated authorization regression):
Error: expect(locator).toBeVisible() failed
Locator: getByRole('heading', { name: 'Coverage unavailable' })
Expected: visible
Timeout: 15000ms
Error: element(s) not found
    at .../operator-phase-135-uat.spec.ts:123:79
```

Both are simulated regressions (deliberate, reverted patches to `router.ex`) used to prove the test's
own teeth, not observed failures against the shipped product — `router.ex` is confirmed byte-identical
after 198-33 (`git diff --stat` empty). No unresolved product defect is recorded here; this section
exists to state that fact explicitly rather than let a reader infer a live regression from the presence
of failing-test output in a SUMMARY.

No other round-5 plan (198-30, 198-31, 198-32, 198-34, 198-35) recorded a product-level finding outside
its own targeted fix — each SUMMARY's "Issues Encountered" section was read in full for this ledger and
contains only environment/tooling notes (stale local DB state, background `DBConnection.OwnershipError`
noise, local server instability under load), none of which are product findings.

---
*Phase: 198-green-bringup*
*Plan: 36*
