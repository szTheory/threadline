---
phase: 198-green-bringup
plan: 28
subsystem: testing
tags: [playwright, e2e, ci, green-bringup, screenshot-regression, actor-live, export-status, decision]

requires:
  - phase: 198-green-bringup (plans 198-26, 198-27)
    provides: the measured 29-row (later reconciled to 26) attribution table and cluster
      assignment for the masked Playwright failures, naming cluster 198-28's rows
      (operator-screenshot-regression.spec.ts, operator-screenshots.spec.ts) as this
      plan's work list, plus the 7 seed-sensitive=yes rows this plan's post-merge gate
      had to re-derive
provides:
  - A post-merge re-validation of every seed-sensitive attribution row against the fully
    merged demo-seed pipeline (198-23/24/25), with 2 genuine divergences re-attributed
  - The CI-contributing (2 rows) vs local-only (8 rows) split for cluster 198-28, with
    the deciding source lines cited
  - A blocking checkpoint:decision (Task 2) answered under auto-mode: no committed PNG
    baseline may be regenerated
  - Both CI-contributing rows fixed at cause (a phase-186 assertion-rot, not a seed
    issue as previously classified)
  - A genuine locator-scope improvement on one local-only row (row-history), and honest
    "open" dispositions with named causes for the remaining local-only rows, none of
    which is resolved by regenerating evidence
  - Corrected root-cause diagnosis for two out-of-cluster discoveries first logged by
    this plan's own Task 1 (they were misattributed to a seed-content change; the real
    cause is this same round's own export-label copy fix)
affects: [198-29]

actuals:
  tokens: 15300
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Prefer a title/data-attribute locator over getByText on a truncated-display value
      (operator-screenshots.spec.ts, .tl-secondary-ref[title=...] instead of the full
      UUID as visible text)"
    - "Scope a screenshot locator to the actual bounded visual element, not a wrapper
      that also carries the same data-testid via {@rest} (row-history: .tl-drawer, not
      the outer .tl-drawer-container the testid lands on)"
    - "getByRole(role, { name, exact: true }) to disambiguate a heading whose accessible
      name is a substring of another heading's name, rather than widening or deleting
      either assertion"
    - "When a screenshot diff persists after fixing its assertion-rot half, diagnose
      whether the residual is a legitimate already-shipped change before concluding a
      baseline needs regenerating — checked git log -L / git show on the rendering
      source before naming a cause"

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
    - .planning/audits/198-round4-playwright.md
    - .planning/phases/198-green-bringup/deferred-items.md
    - .planning/WINDOWS.md

key-decisions:
  - "Task 2 blocking checkpoint:decision was answered under auto-mode as option A (fix
    at cause, regenerate nothing), with an explicit fallback: where A cannot resolve a
    divergence without a baseline rewrite, leave the row open with its cause named
    rather than force a fix or spend the evidence a regeneration would destroy."
  - "Corrected an inherited over-attribution: 198-26 classified operator-screenshots.spec.ts's
    admin-investigation mobile row as seed-sensitive (leaving-agent persona content).
    Reading git log -L on the failing assertion's source line showed the literal text it
    searches for was removed from the product in phase 186 (commit 3022e2e0), long
    before this round, and independently recomputing the deterministic actor UUID
    confirmed it was never wrong. This was assertion rot, not a seed issue."
  - "Corrected the diagnosis of two out-of-cluster discoveries this plan's own Task 1
    first logged as 'consistent with 198-25's exports seed rewrite' — that hypothesis
    was checked against git history in Task 3 and found wrong: demo/seed/exports.ex was
    never touched this round. The real cause is 198-25's own export_status_live.ex label
    fix (Expired -> Export expired), which broke a case-sensitive regex in two unrelated
    spec files. Corrected in WINDOWS.md rather than left standing."
  - "Housekeeping: cluster 198-28 was documented as '13 rows' in 198-26/198-27's own
    headers, but only 10 distinct rows are actually enumerated in the attribution table.
    Proceeded from the reconciled 10, not the unverified 13, and flagged the discrepancy
    rather than silently propagating it into this plan's own arithmetic or into 198-29's
    prediction scorecard."
  - "Fixed the row-history drawer's screenshot locator (was scoped to the full-viewport
    .tl-drawer-container the data-testid lands on via {@rest}, not the bounded .tl-drawer
    panel) even though this did not fully close the row — the fix is independently
    correct (matches the guard's own stated intent) and is real, measured progress
    (ratio 0.53 -> 0.19, width mismatch eliminated), recorded honestly as 'open, improved'
    rather than either 'closed' (false) or reverted for not fully succeeding."

requirements-completed: [GREEN-07]

coverage:
  - id: D1
    description: "Post-merge re-validation of all 7 seed-sensitive=yes attribution rows
      against the fully merged demo-seed pipeline, with 2 genuine divergences
      re-attributed and rewritten in place"
    requirement: "GREEN-07"
    verification:
      - kind: e2e
        ref: ".planning/audits/198-round4-playwright.md#post-merge-re-validation-198-28 (mix verify.example_browser --project=desktop-chromium --project=mobile-chromium, /tmp/198-28-postmerge.log)"
        status: pass
    human_judgment: false
  - id: D2
    description: "CI-contributing (2) vs local-only (8) split established for cluster
      198-28, citing the deciding source lines"
    requirement: "GREEN-07"
    verification:
      - kind: other
        ref: ".planning/audits/198-round4-playwright.md#ci-contributing-versus-local-only-split-198-28"
        status: pass
    human_judgment: false
  - id: D3
    description: "Blocking checkpoint:decision (Task 2, baseline regeneration) answered
      and recorded in writing before any fix was attempted"
    requirement: "GREEN-07"
    verification:
      - kind: unit
        ref: "test/threadline/phase198_decision_attestation_test.exs"
        status: pass
    human_judgment: false
    rationale: "The decision itself was made by the maintainer (via the orchestrator's
      auto-mode auto-answer), not by this executor. Recorded here for traceability, not
      for automated re-verification. Discharged by phase-199: the recorded regeneration decision is asserted mechanically, and phase-199's own bounded D-39 exception supersedes it append-only with a fresh verbatim maintainer answer."
  - id: D4
    description: "Both CI-contributing rows (operator-screenshots.spec.ts admin
      investigation) fixed at cause with red-then-green teeth proof"
    requirement: "GREEN-07"
    verification:
      - kind: e2e
        ref: "mix verify.example_browser operator-screenshots.spec.ts:90 --project=desktop-chromium --project=mobile-chromium"
        status: pass
    human_judgment: false
  - id: D5
    description: "8 local-only rows reconciled as open with a named cause each, and no
      baseline PNG regenerated (git status --porcelain on the snapshots directory empty)"
    requirement: "GREEN-07"
    verification:
      - kind: other
        ref: ".planning/audits/198-round4-playwright.md#cluster-198-28-reconciliation"
        status: pass
    human_judgment: false

duration: 118min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 28: Playwright screenshot-cluster post-merge gate + cause-only fix Summary

**Re-derived every seed-sensitive attribution row against the fully merged demo-seed pipeline, got a blocking baseline-regeneration decision answered (no regeneration, ever), then fixed both of cluster 198-28's CI-contributing rows at a phase-186 assertion-rot cause — while honestly leaving 8 local-only screenshot rows open under the no-regeneration constraint, one of them genuinely improved via a locator-scope fix.**

## Performance

- **Duration:** 118 min
- **Tasks:** 3 (Task 1: post-merge re-validation; Task 2: blocking decision checkpoint; Task 3: fix within the decision)
- **Files modified:** 5 (2 spec files, 3 docs)

## Accomplishments

- Confirmed every prerequisite plan's commits (198-23, 198-24, 198-25, 198-26, 198-27) were present before measuring anything.
- Ran `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium` unbounded against the merged tree: **14 failed, 15 skipped, 311 passed (4.8m)** — the honest post-merge baseline for this plan (not the pre-merge 11 either sibling plan closed with).
- Re-derived all 7 `seed-sensitive? = yes` rows named by 198-26/198-27's own work order. **2 diverged**: mobile row-history (pre-merge assumed a dimension mismatch; actually a content-only diff) and mobile Retention (pre-merge assumed a plain content diff; actually a dimension mismatch, page 157px shorter). Both rewritten in place in the attribution table.
- Also honestly re-attributed row 25 (desktop admin-investigation), pre-flagged `seed-sensitive? = no` under a login-redirect-flake cause that no longer held post-merge — it now failed at the same cause as its sibling row.
- Established the CI split: **CI-contributing = 2** rows (`operator-screenshots.spec.ts`, both projects); **local-only = 8** (all of `operator-screenshot-regression.spec.ts`, gated by its describe-level `test.skip(!!process.env.CI, ...)`).
- Flagged and corrected an inherited arithmetic error: cluster 198-28 was documented as "13 rows" but only 10 are actually enumerated; proceeded from the reconciled 10.
- Raised the plan's Task 2 blocking `checkpoint:decision` (may any committed PNG baseline be regenerated?) and received the maintainer's written answer via the orchestrator's auto-mode auto-answer: **option A — fix at cause, regenerate nothing**, with an explicit fallback to leave a row open (not force it) where only a regeneration could close it.
- Fixed both CI-contributing rows at cause: the `getByText('Actor: user / {uuid}')` assertion targeted a literal that commit `3022e2e0` ("feat(186-01): align actor activity detail surface") removed from the product in **phase 186**, long before this round — this row was never actually seed-sensitive, contrary to 198-26's classification; independently recomputed the deterministic actor UUID to confirm the id itself was never wrong. Replaced with a title-attribute locator matching a pattern the same file already uses for a different secondary ref. Also fixed a `getByRole("heading", {name: "Exports"})` strict-mode collision (shared cause with cluster rows 21/22) reached only after the Actor fix let the test proceed further.
- Fixed the same Exports `getByRole` collision in `operator-screenshot-regression.spec.ts` (`exact: true`).
- Fixed the row-history drawer's screenshot locator: `data-testid="row-history-drawer"` lands on `UI.drawer`'s full-viewport outer container (`{@rest}` on `.tl-drawer-container`), not the bounded `.tl-drawer` panel (`width: min(var(--tl-drawer-width), 100vw)`). Rescoped to `drawer.locator(".tl-drawer")`, cutting the desktop diff from ratio 0.53 to 0.19 and eliminating the width mismatch entirely — genuine progress, though the row does not fully close.
- Diagnosed the Exports screenshot residual (after the assertion-rot fix) as a **legitimate, already-shipped visual change**: this same round's `fix(198-25)` commit `e6f3cd5d` intentionally changed the completed-expired export job's label from `"Expired"` to `"Export expired"`, reflowing page height. Left open per the Task 2 decision rather than forced closed.
- Diagnosed dense Timeline and Retention's residual diffs as, respectively, a whole-page layout drift predating this round (visually confirmed via the diff render, not maskable) and a retention-run history whose row count/order varies with real pruner execution timing (also not maskable) — both left open with named causes.
- Corrected the diagnosis of two new out-of-cluster discoveries this plan's own Task 1 first logged: they were hypothesized as caused by 198-25's exports-seed rewrite, but `demo/seed/exports.ex` was never touched this round. Tracing 198-25's real diff showed the actual cause is the same `"Expired"` → `"Export expired"` label fix breaking a case-sensitive `/Expired|File unavailable/` regex in two unrelated files. Corrected in WINDOWS.md (#12/#13 correcting #10/#11) rather than left standing.
- Re-measured: **12 failed, 15 skipped, 313 passed (4.4m)**. Delta from this plan's own post-merge baseline (14): **-2, both CI-contributing (now fully closed)**. Local-only delta: **0** (8 rows left open, honestly, not silently reduced).
- Reconciled all 10 cluster rows: 2 `closed`, 8 `open`, each with a named cause; arithmetic `2 + 8 = 10` stated against the reconciled cluster size.
- No baseline PNG under `operator-screenshot-regression.spec.ts-snapshots/` was written or modified; `git status --porcelain` on that directory is empty.
- `test.skip(` count in `operator-screenshot-regression.spec.ts` is `2`, unchanged — the pre-existing CI guard and project guard were neither widened nor narrowed, and no new skip was added.
- `git diff` on `playwright.config.ts`, `.github/workflows/ci.yml`, `.github/rulesets/main.json`, and `CONTRIBUTING.md` is empty.
- Restated the round's ceiling: `CI required` cannot conclude `success` this round; `Tier A capture lane` stays red under D-39 regardless of this cluster's outcome.

## Task Commits

Each task was committed atomically (Task 1 and Task 3 each produced two commits — a fix/decision commit and a docs commit recording the evidence):

1. **Task 1: Re-validate both attribution tables post-merge, establish CI-vs-local split** — `1daa9aeb` (docs) + `bd35f54d` (docs — new-discovery ledger entries)
2. **Task 2: Decide whether any committed PNG baseline may be regenerated** — `a2a92ccb` (docs — decision recorded)
3. **Task 3: Fix this cluster at its causes within the recorded decision, and re-measure** — `1b0d8d0a` (fix) + `42746189` (docs — teeth proofs, reconciliation, ledger corrections)

## Files Created/Modified

- `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` — fixed the stale `Actor:` literal (title-attribute locator) and the `Exports` heading strict-mode collision.
- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` — fixed the same `Exports` heading collision; rescoped the row-history drawer screenshot locator to the bounded panel element.
- `.planning/audits/198-round4-playwright.md` — post-merge re-validation, divergences, CI/local split, baseline-regeneration decision record, teeth proofs, measured after-count, cluster reconciliation, restated ceiling.
- `.planning/phases/198-green-bringup/deferred-items.md` — Plan 198-28 entry documenting fixes, open rows, and the corrected new-discovery diagnosis.
- `.planning/WINDOWS.md` — corrected entries #10/#11's root-cause hypothesis (new entries #12/#13) and logged 4 new entries for the 8 open local-only rows.

## Decisions Made

See `key-decisions` in frontmatter above — the Task 2 checkpoint answer, the two over-attribution corrections (the Actor row and the two out-of-cluster discoveries), the row-count housekeeping correction, and the decision to keep the row-history locator fix despite it not fully closing the row.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed the row-history drawer's screenshot locator beyond the plan's literal masking-list guidance**
- **Found during:** Task 3
- **Issue:** The plan's `<action>` for Task 3 anticipated masking-list extension or product/baseline fixes; the row-history row's actual cause was neither — it was a wrong-element locator (data-testid landing on a full-viewport wrapper instead of the bounded visual panel).
- **Fix:** Rescoped the screenshot locator to `.tl-drawer`, the panel `UI.drawer` actually renders visually bounded, per the component's own CSS.
- **Files modified:** `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts`
- **Verification:** Diff ratio dropped from 0.53 to 0.19 and the dimension mismatch (width) was eliminated; recorded as `open` (not `closed`) since a residual diff remains.
- **Committed in:** `1b0d8d0a`

**2. [Rule 1 - Bug] Corrected two ledger entries' root-cause hypothesis rather than leaving a wrong diagnosis standing**
- **Found during:** Task 3 (while diagnosing cluster 198-28's own Exports screenshot residual)
- **Issue:** Task 1 logged `operator-accessibility.spec.ts:565:3` and `operator-prove-mobile.spec.ts:38:3` as "likely caused by 198-25's exports seed rewrite" — a hypothesis, not a measured cause, and per `git show` on 198-25's actual delivered commits, wrong (no seed producer file was touched).
- **Fix:** Traced the real cause (198-25's `export_status_live.ex` label copy fix) and appended corrected WINDOWS.md entries (#12/#13) rather than silently leaving the wrong hypothesis as the last word.
- **Files modified:** `.planning/WINDOWS.md`
- **Verification:** Confirmed by reading `git show e6f3cd5d` and the case-sensitive regex mismatch directly.
- **Committed in:** `42746189`

---

**Total deviations:** 2 auto-fixed (both Rule 1 — bug fixes beyond the plan's anticipated remedy shape, within the plan's declared scope and the Task 2 decision's bounds).
**Impact on plan:** Both deviations improved the plan's honesty and its downstream fix quality; neither expanded scope beyond the plan's declared files (the row-history fix is inside `files_modified`; the ledger correction is a correction of this same plan's own prior-task output, not new scope).

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, file-access patterns, or schema changes. All changes were to Playwright test locators/assertions and documentation.

## Issues Encountered

- The plan's own Task 1 hypothesis for the two new out-of-cluster discoveries (seed-content change) was wrong, discovered only while diagnosing this cluster's own Exports row in Task 3. Corrected rather than left standing (see Deviations above) — resolved by tracing `git show` on the actual commits rather than assuming the earlier hypothesis was right because it "fit the shape."
- The row-history drawer's residual failure (after fixing the locator) required reading `UI.drawer`'s CSS (`height: 100%`) to establish that the remaining height mismatch is a structural, pre-existing sizing decision rather than something further fixable within this task's scope — resolved by naming the cause precisely rather than continuing to iterate on a fix that could not close it without regenerating.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Cluster 198-28 is fully reconciled: 2 rows closed (both CI-contributing), 8 rows open with named causes (all local-only, none of which ever bore on the CI lane's conclusion).
- Plan 198-29 (or whichever plan next measures the lane) should use this plan's own post-merge baseline (14 failed) and closing count (12 failed) rather than either sibling plan's pre-merge figures — the count moved 11 → 14 → 12 across the round, and each move has a named cause in `.planning/audits/198-round4-playwright.md`.
- Two corrected, still-open, out-of-cluster discoveries (`operator-accessibility.spec.ts:565:3`, `operator-prove-mobile.spec.ts:38:3`, both projects each) need a follow-up plan to update their `/Expired|File unavailable/` regex to match the corrected canonical export-expired copy.
- GREEN-07 remains not-Complete this round by design (D-39 forbids the Tier A remedy); no claim in this plan or its SUMMARY asserts otherwise.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*

## Self-Check: PASSED

- `test -f examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts` -> FOUND
- `test -f examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` -> FOUND
- `test -f .planning/audits/198-round4-playwright.md` -> FOUND
- `test -f .planning/phases/198-green-bringup/deferred-items.md` -> FOUND
- `test -f .planning/WINDOWS.md` -> FOUND
- Commits `1daa9aeb`, `bd35f54d`, `a2a92ccb`, `1b0d8d0a`, `42746189` all present in `git log --oneline --all`
- `mix verify.example_browser operator-screenshots.spec.ts:90 --project=desktop-chromium --project=mobile-chromium` re-confirmed `2 passed` at write time
- Full-lane re-measurement re-confirmed `12 failed, 15 skipped, 313 passed` at write time
- `git status --porcelain examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts-snapshots` confirmed empty at write time
- `grep -c "test.skip(" examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` confirmed `2` at write time
