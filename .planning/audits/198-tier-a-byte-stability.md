# 198-16: Tier A byte-stability diagnosis — `scroll_cost` drift

**Written before any fix.** Per plan 198-16 (GREEN-04, Gap 3), this diagnoses why
CI run 33183920952's `Tier A capture lane (byte-stable evidence)` fails its
`Assert byte-stable regeneration` step, specifically that
`.planning/scorecards/page.coverage.error__light-1280.json` regenerates with a
`scroll_cost` far from the committed value. No fix is applied in this document;
Task 2 (checkpoint:decision) and Task 3 (implement-or-halt) follow this.

## 1. Reproduction (verbatim)

Reproduced against local Postgres on port 5432 (same port CI uses), root deps
already fetched in this worktree by 198-14, example-app deps + e2e node_modules
fetched fresh for this plan.

```
$ pg_isready -h localhost -p 5432
localhost:5432 - accepting connections

$ DB_HOST=localhost DB_PORT=5432 mix verify.capture
...
> test
> playwright test --project=tier-a-capture --project=tier-a-capture-light operator-tier-a-capture.spec.ts

Running 2 tests using 1 worker

  ✓  1 [tier-a-capture] › tests/operator-tier-a-capture.spec.ts:384:3 › operator Tier A deterministic capture › emits the Tier A evidence bundle for this theme project (1.1m)
  ✓  2 [tier-a-capture-light] › tests/operator-tier-a-capture.spec.ts:384:3 › operator Tier A deterministic capture › emits the Tier A evidence bundle for this theme project (1.2m)

  2 passed (2.3m)

$ git status --porcelain .planning/scorecards/ | wc -l
198

$ git diff -- .planning/scorecards/page.coverage.error__light-1280.json
diff --git a/.planning/scorecards/page.coverage.error__light-1280.json b/.planning/scorecards/page.coverage.error__light-1280.json
index 41239495..28fcf5e7 100644
--- a/.planning/scorecards/page.coverage.error__light-1280.json
+++ b/.planning/scorecards/page.coverage.error__light-1280.json
@@ -110,7 +110,7 @@
     "type_size_count": 4,
     "interactive_control_count": 0,
     "card_nesting_depth": 0,
-    "scroll_cost": 18.803,
+    "scroll_cost": 40.37,
     "font_sizes": [
       "13px",
       "14px",
```

**Does the drift reproduce locally? YES.** No CI-only factor is required. Note the
committed value read by this reproduction (`18.803`) is not the `19.038` figure
in the plan's problem statement — that is expected: `.planning/scorecards/` has
not been regenerated since Phase 194/195, but other 198 gap-closure plans
(198-14, 198-15) did not touch it, and the plan's own stated value traces to an
older CI run (33183920952) against a since-advanced tree. This does not change
the diagnosis; the direction and rough magnitude (near-doubling) match exactly.

## 2. Run-to-run determinism (rules out capture-level flakiness)

Ran `mix verify.capture` a second time from a clean scorecard checkout:

```
$ git checkout -- .planning/scorecards/
$ DB_HOST=localhost DB_PORT=5432 mix verify.capture
...
  ✓  1 [tier-a-capture] › ... (1.1m)
  ✓  2 [tier-a-capture-light] › ... (1.1m)
  2 passed (2.2m)

$ git diff -- .planning/scorecards/page.coverage.error__light-1280.json | grep scroll_cost
-    "scroll_cost": 18.803,
+    "scroll_cost": 40.37,

$ git status --porcelain .planning/scorecards/ | wc -l
198
```

Run 1 and run 2 produced the **identical** `scroll_cost` (`40.37`) for the
target cell, and the identical total count of drifted files (`198` both times).
This rules out run-to-run nondeterminism (a flaky capture): the drift is a
deterministic function of the current tree, not machine noise.

`git status --porcelain .planning/scorecards/` was reverted to clean
(`git checkout -- .planning/scorecards/`) after each run — no regenerated
evidence was left staged.

## 3. Fields that changed (target cell)

For `page.coverage.error__light-1280.json` specifically, **only `scroll_cost`
changed** — `git diff --stat` shows `1 file changed, 1 insertion(+), 1
deletion(-)` and the full diff (§1) shows no other field moved: `tokens`,
`color_pairs`, `element_styles`, `applied_colors`, `mode_b.type_size_count`,
`mode_b.interactive_control_count`, `mode_b.card_nesting_depth`,
`mode_b.font_sizes`, and `a11y_summary` are all byte-identical to the committed
evidence. This holds across all six `page.coverage.error__*` cells (both themes
× all three breakpoints):

```
$ git diff --stat -- .planning/scorecards/page.coverage.error__dark-1280.json \
    .planning/scorecards/page.coverage.error__dark-375.json \
    .planning/scorecards/page.coverage.error__dark-768.json \
    .planning/scorecards/page.coverage.error__light-1280.json \
    .planning/scorecards/page.coverage.error__light-375.json \
    .planning/scorecards/page.coverage.error__light-768.json
 .planning/scorecards/page.coverage.error__dark-1280.json  | 2 +-
 .planning/scorecards/page.coverage.error__dark-375.json   | 2 +-
 .planning/scorecards/page.coverage.error__dark-768.json   | 2 +-
 .planning/scorecards/page.coverage.error__light-1280.json | 2 +-
 .planning/scorecards/page.coverage.error__light-375.json  | 2 +-
 .planning/scorecards/page.coverage.error__light-768.json  | 2 +-
 6 files changed, 6 insertions(+), 6 deletions(-)

$ git diff -- .planning/scorecards/page.coverage.error__*.json | grep scroll_cost
-    "scroll_cost": 18.803,
+    "scroll_cost": 40.37,
-    "scroll_cost": 19.85,
+    "scroll_cost": 41.417,
-    "scroll_cost": 19.038,
+    "scroll_cost": 36.478,
-    "scroll_cost": 18.803,
+    "scroll_cost": 40.37,
-    "scroll_cost": 19.85,
+    "scroll_cost": 41.417,
-    "scroll_cost": 19.038,
+    "scroll_cost": 36.478,
```

("`19.038`" is the `_768` breakpoint's committed value, and matches the plan's
stated problem-statement number exactly — the plan's stated cell ID
(`__light-1280`) and stated number (`19.038`) trace to two different
breakpoints of the same ledger; the underlying cause is identical for all six.)

**Scope note (out of this cell, recorded honestly, not chased further):**
`git status --porcelain .planning/scorecards/` shows 198 of 366 committed
scorecards drift, not just the 6 `page.coverage.error*` cells. Of those, 156
files change only their `scroll_cost` line (the same mechanism diagnosed
below); 42 files (`refute.brand-fidelity.mis-jobbed-accent.flawed__*` and
`refute.density.chrome-bloat.flawed__*`, both themes × 3 breakpoints × 7 lines
average) show additional content-level diffs (font-size, margin, a new
`button` selector). Those 42 are a **different, unrelated** drift in the
refute-twin fixtures — plausibly legitimate content changes from later Phase
195/196 critic work that were never re-captured. They are out of this plan's
scope (`page.coverage.error__light-1280`, GREEN-04 Gap 3) and are not
diagnosed further here; flagging them so a future recapture effort does not
mistake this diagnosis as covering the whole 198-file drift.

## 4. Candidate causes tested

### Ruled OUT: Playwright/Chromium version mismatch (environmental)

**Hypothesis:** the committed `meta.playwright_version` (`"1.61.1"`) differs
from the locally installed Playwright (`1.60.0`, confirmed via
`npx playwright --version` and `package-lock.json`'s
`node_modules/@playwright/test.version`), so a different bundled Chromium
build could render fonts/layout differently between the original capture and
this reproduction (or between CI and local).

**Test:** read `examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts:31`:

```
// Pinned for cross-machine byte-stability — never `new Date()` / installed version.
const PLAYWRIGHT_VERSION = "1.61.1";
```

`PLAYWRIGHT_VERSION` is a **hardcoded string literal**, not derived from the
installed package (`require("@playwright/test/package.json").version` or
similar). It is written into `meta.playwright_version` verbatim regardless of
which Playwright build actually ran the capture.

**Result: RULED OUT.** The field is intentionally static (the comment says so
explicitly) — it cannot be a signal of a real version-driven rendering
difference between environments, and rendering behavior does not track this
field's value. Separately, `1.61.1` vs. the locked `1.60.0` in
`package-lock.json` is itself a latent inconsistency (the literal is stale
relative to the lockfile) — noted for the record, not remedied here since it
carries no bearing on `scroll_cost` (see below for what does).

### Ruled OUT: example-app search_path / demo-seed content difference

**Hypothesis:** `ci.yml:374-375`'s `ALTER DATABASE threadline_phoenix_test SET
search_path ...` step, called out in `198-CONTEXT.md`'s deferred-items register
as "a real wart," changes what `demo.seed` renders, which could inflate content
height on seeded pages.

**Test:** read `examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts:301`
— `captureCell` navigates to `/audit/__stress?story=${ledgerId}&theme=${theme}&viewport=${breakpoint}`,
the **stress-harness fixture route**, not a live seeded `/audit/*` page. Band 2
stories (including `page.coverage.error`) render from static, DB-free fixture
data via `Threadline.OperatorSurface.StressFixtures.assigns_for/1` (confirmed
by reading `stress_fixtures.ex`), not from `demo.seed`'s data.

**Result: RULED OUT.** `page.coverage.error` is not seeded-DB content at all;
the search_path wart cannot be the cause of this cell's drift. (It remains a
real, separately-tracked issue for whatever `page.*` cells DO depend on seeded
content — out of scope here.)

### Identified: harness sidebar catalog leaks into `scroll_cost`'s numerator

**Hypothesis, formed after the above two were ruled out and the local
reproduction confirmed the drift is deterministic, not environmental:**
`scroll_cost`'s numerator is scoped to the *whole document*, not to the
product-content region every other captured field is scoped to — so
`scroll_cost` is not actually measuring "how tall is the rendered page under
test," it is measuring "how tall is the entire `/audit/__stress` debug
harness," which includes an unrelated, unvirtualized sidebar listing every
registered stress-lab story.

**Evidence — the formula itself**
(`examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts`, the
`rawInputs` function):

```
const main = document.querySelector('[data-testid="stress-preview"]');
// ... color_pairs, element_styles, applied_colors are all queried from `main`
// (the product-surface region, explicitly NOT the /audit/__stress harness
// chrome, per the function's own comment) ...

const scrollCost =
  Math.round(
    (document.documentElement.scrollHeight /
      Math.max(window.innerHeight, 1)) *
      1000,
  ) / 1000;
```

`scrollCost` reads `document.documentElement.scrollHeight` — the entire
document — while every other raw input in the same function is deliberately
scoped to `main` (`[data-testid="stress-preview"]`), the actual page being
tested. This is a real scoping inconsistency in the capture script itself, not
an environmental variable.

**Evidence — direct DOM measurement.** A temporary, uncommitted diagnostic
Playwright script (`tests/tmp-diag-198-16.spec.ts`, deleted after this
measurement; not part of any commit) navigated to the same URL the capture
uses (`/audit/__stress?story=page.coverage.error&theme=light&viewport=1280`)
and printed a structural breakdown:

```
DIAG_RESULT: {
  "documentElement_scrollHeight": 36374,
  "documentElement_clientHeight": 900,
  "window_innerHeight": 900,
  "preview_scrollHeight": 500,
  "preview_offsetHeight": 502,
  "tlMain_scrollHeight": 36288,
  ...
}

DIAG_STRUCTURE:
main#tl-main.tl-page[data-testid=stress-lab] h=36288
  header.tl-page__header h=67
  section.tl-stress__metrics h=176
  div.tl-stress__layout h=35965
    aside.tl-stress__sidebar h=35965
      nav.tl-stress__category-nav[data-testid=stress-category-nav] h=112
      div.tl-stress__filters h=70
      div.tl-stress__story-list[data-testid=stress-story-list] h=35726
        a.tl-stress__story-link h=121
        a.tl-stress__story-link h=141
        a.tl-stress__story-link h=97
        a.tl-stress__story-link h=97
        a.tl-stress__story-link h=97
        ... (283 more siblings omitted)
    section.tl-stress__preview[data-testid=stress-preview] h=502
      div.tl-stress__preview-header h=44
      dl.tl-stress__ledger-table h=318
      div.tl-stress__fixture-preview h=82
```

**98.5% of `document.documentElement.scrollHeight` (35726px of 36288px inside
`#tl-main`, 35726 of the full-page 36374px) is
`div.tl-stress__story-list[data-testid=stress-story-list]`** — the sidebar
listing of every registered stress-lab story (currently 288, confirmed via
`mix run` calling `length(Threadline.OperatorSurface.StressFixtures.all())` →
`288`). `section.tl-stress__preview` — the actual product content being
captured for this cell — is only `502px` tall.

If `scrollCost` were correctly scoped to the product content the same way
every other field in the same function already is (`preview_offsetHeight /
window_innerHeight`), the value would be `502 / 900 = 0.558`, not `18.803` (old)
or `40.37` (new) — neither committed nor regenerated value is close to what a
correctly-scoped metric would report. This is independent corroboration that
the current formula's scope is the defect, not a rendering artifact of this
specific cell's content.

**Why this produces a near-doubling that reproduces identically across runs:**
`Threadline.OperatorSurface.StressFixtures.all()` returns every registered
stress-lab story regardless of which one is being captured — the sidebar
renders the full catalog on every single cell capture. As the catalog grows
(new pages/states registered across phases), every committed cell's
`scroll_cost` grows in lockstep, uncorrelated with that cell's own content.
`git log --oneline -- lib/threadline/operator_surface/stress_fixtures.ex` shows
14 commits touching the fixture registry; `git show
099afbaa:lib/threadline/operator_surface/stress_fixtures.ex | wc -l` (the
commit that last touched `.planning/scorecards/`, Phase 195-03) is `874`
lines vs. `981` lines on the current tree — the registry grew by 107 lines
(multiple stories) after the committed evidence was captured and before this
plan ran, with no intervening recapture. The earlier commit `f0990a2f`
(Phase 194, the original scorecard baseline) shows a smaller committed
`scroll_cost` still (`16.561` → `18.803` at 195-03 → `40.37`/`36.478`/`41.417`
now), consistent with monotonic catalog growth across three baseline
snapshots.

**Result: this is the identified cause.** `scroll_cost` is deterministically
coupled to the total number of registered stress-lab stories via an
unintentionally document-wide (rather than product-content-scoped)
`scrollHeight` read, and the committed evidence predates roughly three phases'
worth of catalog growth that was never recaptured.

## 5. Which value is correct for the current tree?

**Neither `19.038`/`18.803` (committed) nor `36.478`/`40.37` (regenerated) is
"correct" in the sense of describing the product page under test** — both are
measuring the wrong thing (the harness catalog's total height, not the
captured page's content). But per the plan's own framing ("if the page
renders correctly today, which number describes it"): the page renders
correctly today (login → story render → `stress-preview` visible → no test
assertion failure anywhere in this reproduction), and **the regenerated value
(`36.478`/`40.37`/`41.417`) is what `mix verify.capture`, run twice, `deterministically
and reproducibly computes today` from the current tree** — it is not stale,
not flaky, and not CI-specific. The committed value is stale: it was captured
against a smaller story catalog and never refreshed as that catalog grew.

## 6. Proposed remedy and its cost

There are exactly two ways to make `scroll_cost` byte-stable again, and **both
require regenerating committed Tier A `page.*` scorecard evidence**, which
`198-CONTEXT.md`'s deferred-items register states is **"forbidden this
milestone"** (verbatim, re: the related search_path wart: *"Fixing it means
changing seeded page content, which would force Tier-A `page.*` scorecard
regeneration — forbidden this milestone"*):

1. **Regenerate only (leave the formula as-is).** Run `mix verify.capture` and
   commit the result. Fixes byte-stability *until the catalog grows again* —
   this is not a durable fix; the next phase that registers a new stress-lab
   story reopens the exact same failure for all 366 committed cells, not just
   198. Cost: commits new `scroll_cost` values for (at least) 198 scorecards;
   forbidden by the current milestone constraint regardless.

2. **Rescope `scrollCost` to `preview.offsetHeight / window.innerHeight`**
   (matching the scoping every sibling field in `rawInputs` already uses), then
   regenerate. This is the durable fix — the metric would no longer move when
   unrelated stories are added to the catalog. But it changes the *definition*
   of `scroll_cost` for every one of the 366 committed cells (not just the 198
   currently drifted), so it requires the same forbidden regeneration, at
   larger scale, plus a `mechanical_floors["scroll_cost"]` re-seed in
   `.planning/design-system-ledger.json` (currently `18.803`/`19.85`/`19.038`
   for `page.coverage.error`'s three breakpoints) since `MechanicalChecker`
   ratchets against those floors.

**No available remedy avoids Tier A `page.*` evidence regeneration.** This
matches the plan's own explicitly anticipated outcome: *"If the only available
remedy would require regenerating Tier A `page.*` evidence in a way this
milestone forbids, HALT and say so in the SUMMARY rather than regenerating."*

## Summary for Task 2

- Reproduces locally: **YES**, deterministically, across two independent runs.
- Cause: **identified** — `scroll_cost` reads `document.documentElement.scrollHeight`
  (whole document, including the `/audit/__stress` harness's unvirtualized
  ~288-story sidebar) instead of the product-content region every sibling
  field already scopes to. The committed evidence predates catalog growth that
  happened across at least three untracked capture generations
  (`16.561` → `18.803` → `36.478`/`40.37`/`41.417`).
- Remedy: **both available options (regenerate as-is, or fix the scope and
  regenerate) require Tier A `page.*` scorecard regeneration**, which this
  milestone's deferred-items register explicitly forbids.
- Per the plan's own must-haves, this is a legitimate halt condition, not a
  gap in the diagnosis.
