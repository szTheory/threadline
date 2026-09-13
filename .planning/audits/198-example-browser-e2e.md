# 198-17: `Example app browser E2E (Playwright)` diagnosis

**Written before any fix.** Per plan 198-17 (GREEN-04, Gap 4), this diagnoses why
CI run 33183920952's `Example app browser E2E (Playwright)` job reports
`5 failed`, `9 passed`, `348 did not run`. No fix is applied in this document;
Task 2 (checkpoint:decision) and Task 3 (implement-or-halt) follow this.

## 1. Uploaded-diagnostics contents read

The job (`98891872894`, run `33183920952`) uploaded `example-browser-e2e-diagnostics`
(artifact id `9691039301`, 9.27MB, not yet expired). Fetched via
`gh api repos/szTheory/threadline/actions/artifacts/9691039301/zip`. Contents:

```
test-results/operator-accessibility-ope-c2b22-controls-keyboard-reachable-desktop-chromium/{error-context.md,trace.zip,test-failed-1.png}
test-results/operator-accessibility-ope-c2b22-controls-keyboard-reachable-desktop-chromium-retry1/{error-context.md,trace.zip,test-failed-1.png}
test-results/operator-coverage-readines-10a0a--actions-and-table-readable-desktop-chromium(-retry1)/{...}
test-results/operator-coverage-readines-9b328--actions-and-table-readable-desktop-chromium(-retry1)/{...}
test-results/operator-coverage-readines-bee7e--actions-and-table-readable-desktop-chromium(-retry1)/{...}
test-results/operator-coverage-readines-bf819--actions-and-table-readable-desktop-chromium(-retry1)/{...}
tmp/threadline_phoenix_e2e.log   (0 bytes)
```

Five distinct failing tests (each with an initial attempt + 1 retry, `retries: 1`
on CI per `playwright.config.ts:131`), all on the `desktop-chromium` project.
**No `mobile-chromium` failures appear in the artifact** — the run's own log
(`gh api .../jobs/98891872894/logs`) confirms why: `maxFailures: 5` was hit
while `desktop-chromium` was still executing, before `mobile-chromium` (the
second, later project in `playwright.config.ts`'s `projects` array) got to run
at all. This is not a second defect; it is a direct, expected consequence of
serialized (`workers: 1`) single-project-at-a-time execution combined with the
failure ceiling (see §2).

`tmp/threadline_phoenix_e2e.log` is 0 bytes — `run-e2e.sh:154` truncates the
log at boot (`: >"$LOG_FILE"`) and the app booted and served requests
successfully for 3 minutes before the Playwright run itself failed on
assertions, not on a boot/preflight failure, so nothing further was ever
written there. This is itself evidence the failure is NOT a boot/environment
problem — the app came up, `/audit/coverage` was reachable and rendering.

## 2. The 348 figure — CONFIRMED as the configured failure-ceiling abort, not a second defect

`examples/threadline_phoenix/e2e/playwright.config.ts:141`:

```ts
maxFailures: process.env.CI ? 5 : 0,
```

The job's own log (`gh api repos/szTheory/threadline/actions/jobs/98891872894/logs`)
shows, verbatim:

```
Running 362 tests using 1 worker
...
  5 failed
  348 did not run
  9 passed (3.0m)
```

`9 + 5 + 348 = 362` — the full scheduled count. `5 failed` is exactly
`maxFailures`'s configured value (`ci.yml`'s `verify-example-browser` step runs
with `CI=true` set by GitHub Actions by default, so `process.env.CI` is truthy
and the ceiling is `5`, not `0`). **The 348 not-run tests are the configured
abort (D-18) working exactly as designed: cite `playwright.config.ts:141`.**
This is settled and not investigated further — per the plan's own framing,
chasing it further would be effort spent on a non-defect.

Why 362 total: `desktop-chromium` and `mobile-chromium` are unscoped projects
(no `testMatch`, `playwright.config.ts:22-24`) and therefore run every
`test(` block in every `.spec.ts` file under `testDir` (`./tests`) except the
projects that ARE scoped away by their own `testMatch` (`tier-a-capture*`,
`storybook-capture`, `graded-capture`, `refute-capture`, `route-capture`,
and the CI-only-conditional `desktop-chromium-light`) — those don't apply
here since they're separate named projects, not filters on `desktop-chromium`/
`mobile-chromium`. 362 is Playwright's own scheduled count for the reduced
2-project PR lane (D-17); not independently re-derived here since it is not
in question — the job log states it directly.

## 3. Five-row failure attribution table

All five verbatim assertion messages, read directly from the artifact's
`error-context.md` files (not reconstructed from spec source):

| # | Spec:line | Viewport | Verbatim assertion message | Cause |
|---|---|---|---|---|
| 1 | `operator-accessibility.spec.ts:406` | desktop (no viewport override; default project viewport) | `Error: expect(locator).toContainText(expected) failed` — `Locator: getByRole('region', { name: 'Selected schema readiness' })` — `- selected schema` / `+ Not ready\n+ Not ready for public: 8 tables need capture.\n+ Covered 6 / Needs capture 8 / Expected gaps 1 / Fix rows marked...` | **SHARED** — see below |
| 2 | `operator-coverage-readiness.spec.ts:135` (via `:119`) | phone-320 | identical `toContainText("selected schema")` failure, identical received-string shape (`Not ready for public: 8 tables need capture.` / `Covered 6` / `Needs capture 8` / `Expected gaps 1`) | **SHARED** — same cause |
| 3 | `operator-coverage-readiness.spec.ts:135` (via `:119`) | phone-375 | identical | **SHARED** — same cause |
| 4 | `operator-coverage-readiness.spec.ts:135` (via `:119`) | tablet | identical | **SHARED** — same cause |
| 5 | `operator-coverage-readiness.spec.ts:135` (via `:119`) | desktop-1024 | identical | **SHARED** — same cause |

**All five failures share exactly one cause.** They are not five bugs; they
are one assertion string (`"selected schema"`) that no longer appears
anywhere in the rendered `Selected schema readiness` region, hit once per
viewport iteration of `operator-coverage-readiness.spec.ts`'s parameterized
`for (const viewport of viewports)` loop (4 of its 5 viewports run before the
ceiling; the 5th, `desktop-1440`, is part of the 348-not-run set — confirmed
in §5 by locally running all 5 viewports unbounded) plus once in
`operator-accessibility.spec.ts`'s single non-parameterized test that visits
the same page. The accessibility spec fails **the same way**, for **the same
reason** — not a distinct per-viewport layout/overflow cause. There is no
layout, overflow, or responsive-collapse component to this failure: the
`Expected substring`/`Received string` diff shows the literal text
`"selected schema"` is simply absent from the region's rendered content at
every viewport, including desktop.

## 4. The cause: an intentional 197-02 product change the Playwright specs were never updated for

Read `lib/threadline/operator_surface/live/coverage_live.ex:277-306`
(`coverage_verdict/1`), which renders the `Selected schema readiness` region.
Its own comment states the cause directly:

```elixir
<%!-- Density (197-02, signal-to-chrome): no "Selected schema readiness" eyebrow
and no "selected schema: … · Checked …" meta line here. The section is already
marked by its aria-label and status chip, the verdict heading names the schema
and readiness, and the page-header meta above owns schema + last-checked —
restating any of them inside the verdict is chrome. --%>
```

`git log --oneline -- lib/threadline/operator_surface/live/coverage_live.ex`
confirms the commit: `842bd737` — `feat(197-02): raise coverage page
signal-to-chrome — drop verdict eyebrow self-label + duplicated schema/checked
meta line` (2026-08-27, one day before the CI run under diagnosis). Its
message states explicitly: *"its 'selected schema: … · Checked …' meta line
restated the schema + last-checked that the page-header meta directly above
already owns... Both removed — data speaks once."* `git show 842bd737 --stat`
shows it touched `coverage_live.ex` (12 lines) and
`coverage_live_test.exs` (+32, the Elixir ExUnit test updated in the same
commit, "Tests flipped in the c6f9355e assert-to-refute pattern" per the
commit message) — but **did not touch either Playwright spec file**.

`git blame` on the two failing lines confirms both assertions predate 197-02
by roughly two months and were never revisited:

```
$ git blame -L 135,135 examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts
62f3f5a69 (szTheory 2026-06-29) await expect(verdict).toContainText("selected schema");

$ git blame -L 406,406 examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
c32277ca8 (szTheory 2026-06-30)   await expect(readiness).toContainText("selected schema");
```

**Result: this is the identified cause for all five failures.** 197-02
correctly, deliberately removed a self-labeling meta line from the product
(an intentional density/de-chroming change, not a regression) but the
Playwright browser specs assert on the retired literal text and were never
updated in the same change — a classic rotting assertion (D-05 taxonomy),
not a bug in `lib/` and not an environmental defect.

## 5. Local reproduction (verbatim) — YES, deterministic

Reproduced against local Postgres on port 5432 (matches CI), after fetching
root deps, example-app deps, e2e `node_modules`, and the Playwright Chromium
browser fresh in this worktree (none were present — same Rule 3 setup 198-16
needed), then running the CI-matching local DB prep
(`ALTER DATABASE threadline_phoenix_test SET search_path ...`, `threadline_phoenix_test`
already existed in this shared local Postgres).

```
$ DB_HOST=localhost DB_PORT=5432 mix verify.example_browser operator-coverage-readiness.spec.ts --project=desktop-chromium
Running 7 tests using 1 worker
...
  5 failed
    [desktop-chromium] › operator-coverage-readiness.spec.ts:119:5 › Coverage readiness viewport: phone-320 › keeps the selected-schema verdict, picker, row actions, and table readable
    [desktop-chromium] › operator-coverage-readiness.spec.ts:119:5 › Coverage readiness viewport: phone-375 › keeps the selected-schema verdict, picker, row actions, and table readable
    [desktop-chromium] › operator-coverage-readiness.spec.ts:119:5 › Coverage readiness viewport: tablet › keeps the selected-schema verdict, picker, row actions, and table readable
    [desktop-chromium] › operator-coverage-readiness.spec.ts:119:5 › Coverage readiness viewport: desktop-1024 › keeps the selected-schema verdict, picker, row actions, and table readable
    [desktop-chromium] › operator-coverage-readiness.spec.ts:119:5 › Coverage readiness viewport: desktop-1440 › keeps the selected-schema verdict, picker, row actions, and table readable
  2 passed (1.3m)
```

Because the local run has no `maxFailures` ceiling (`process.env.CI` is unset
locally, so `maxFailures: 0` — unbounded), **all 5 of this spec's viewports
fail identically**, including `desktop-1440` — which never got to run in CI
before the ceiling aborted the job. This directly confirms §2: `desktop-1440`
is part of the "348 did not run" set purely because of the abort, not because
it has a different or additional cause — it fails with the exact same
`toContainText("selected schema")` message as the other four viewports.

Every failure's `Expected substring`/`Received string` diff is byte-for-byte
identical to the corresponding CI failure in the uploaded artifact (§3),
including the exact rendered counts (`Covered 6`, `Needs capture 8`,
`Expected gaps 1`). **Reproduces locally: YES**, deterministically, with the
identical error on every run.

## 6. Measured coverage state vs. what the specs require — ruling out the deferred demo-seed drift

The leading pre-diagnosis hypothesis (per the plan's own framing) was that the
example app's database/seed preparation does not produce what the coverage
page needs — potentially colliding with the deferred `examples/threadline_phoenix`
demo-seed drift (`deferred-items.md`, `ThreadlinePhoenix.DemoContractTest`).
**This is directly ruled out by the failure output itself:**

- The schema picker DOES offer `public` — never asserted-and-failed in any of
  the 5 failures; `expect(optionValues).toContain("public")` is never reached
  because the test fails one assertion earlier, but the coverage table
  content further down the received-string dump shows real,
  non-empty, differentiated data.
- The `Selected schema readiness` region's **actual rendered content** (the
  `+`-side of every diff) shows a complete, correctly-computed verdict:
  `Not ready for public: 8 tables need capture.` / `Covered: 6` /
  `Needs capture: 8` / `Expected gaps: 1`. These are real, non-zero,
  differentiated counts — not an empty/broken/error state, not a
  `Postgrex.Error` or `Ecto.NoResultsError` (the deferred drift's actual
  failure signature per `deferred-items.md`), and not a missing-schema
  condition. The page renders correctly; only one specific, now-retired
  string is absent from it.
- The `firstUncovered.getByText("Add capture")` and `firstCoveredLink`
  assertions later in `operator-coverage-readiness.spec.ts:145-146` — which
  DO depend on both covered and uncovered rows existing in the table — are
  never reached (the spec fails earlier, at line 135), so this diagnosis
  cannot directly confirm those pass, but the verdict region's own counts
  (`Covered: 6`, `Needs capture: 8`) prove both row classes exist in the
  rendered data, which is what those later assertions require.

**Result: RULED OUT.** The example app's database/schema preparation produces
exactly what the coverage page and the specs need. This gap does **not**
collide with the deferred demo-seed drift, and closing it requires no
scope expansion into that deferred item.

## 7. Hypotheses tested and ruled out

### Ruled OUT: a second, independent "348 did not run" defect (§2)
**Hypothesis:** the "348 did not run" figure is a separate abort/hang bug on
top of the 5 named failures. **Test:** compared the observed failure count (5)
against `playwright.config.ts:141`'s `maxFailures: process.env.CI ? 5 : 0`,
and confirmed via local unbounded reproduction (§5) that `desktop-1440` — one
of the not-run tests — fails with the identical cause the moment it is
allowed to run. **Result: RULED OUT** — the 348 figure is the configured
ceiling working as designed, not a defect.

### Ruled OUT: environmental/database preparation defect, possible collision with the deferred demo-seed drift (§6)
**Hypothesis:** `ci.yml`'s `verify-example-browser` database/schema
preparation does not produce a schema picker offering `public` or a
covered/uncovered table split, the same class of defect named in
`deferred-items.md`. **Test:** read the actual rendered verdict content in
every failure's received-string diff. **Result: RULED OUT** — the coverage
data is real, correct, and non-empty (`Covered: 6`, `Needs capture: 8`,
`Expected gaps: 1`); the failure is purely a retired literal-string
assertion, not a data/schema problem.

### Ruled OUT: per-viewport layout/responsive-collapse cause for the 4 coverage-readiness failures
**Hypothesis:** since 4 of the 5 failures are the same test at 4 different
viewports, the cause could be viewport-specific (e.g., the verdict text gets
clipped or hidden at small widths). **Test:** compared the failure's assertion
location (`toContainText`, which reads the full `textContent`, not a
`toBeVisible`/bounding-box check) and the fact that the accessibility spec's
non-viewport-varying `desktop-chromium`-default-size test fails identically.
**Result: RULED OUT** — the assertion is a raw text-content check unaffected
by viewport size, and the identical failure mode at the accessibility spec's
default (unparameterized) viewport is direct confirmation of a single
non-viewport-dependent cause.

## 8. Proposed remedy per cause

**One cause, one remedy.** Both failing assertions
(`operator-coverage-readiness.spec.ts:135`, `operator-accessibility.spec.ts:406`)
must stop asserting the retired literal `"selected schema"` string and instead
assert something 197-02 actually kept: the verdict heading still names the
selected schema (`verdict_heading(@snapshot, @schema)` interpolates
`@schema`, e.g. `"Not ready for public: 8 tables need capture."`). Both test
call sites navigate to `/audit/coverage` with no `schema` query param, so
`schema_param` defaults to `"public"` (`coverage_live.ex:49`,
`Map.get(params, "schema", "public")`) — the same literal `"public"` this
suite already asserts elsewhere (`operator-coverage-readiness.spec.ts:142`,
`expect(optionValues).toContain("public")`).

This is an **assertion-side classification** (a rotting assertion, per the
D-05 taxonomy) — no `lib/` change, no `ci.yml`/database-preparation change.
Any rewritten assertion requires a demonstrated red-then-green teeth proof
per the plan's Task 3 hard constraint; see Task 2/3 below for the recorded
decision and the executed proof.

## Summary for Task 2

- Reproduces locally: **YES**, deterministically, byte-identical to CI.
- The 348 figure: **CONFIRMED** as the configured `maxFailures: 5` abort
  (`playwright.config.ts:141`), not a second defect.
- Cause: **identified, single, shared across all 5 failures** — two Playwright
  assertions (`operator-coverage-readiness.spec.ts:135`,
  `operator-accessibility.spec.ts:406`) still assert a literal string
  (`"selected schema"`) that commit `842bd737` (Phase 197-02) intentionally
  and correctly removed from the product, one day before this CI run, without
  updating these two browser specs (only the Elixir unit test was updated in
  that commit).
- Classification: **assertion-side (rotting assertion)**, not environmental.
- Collision with the deferred demo-seed drift: **NONE** — the coverage data
  itself is real, correct, and complete; ruled out directly from the
  failures' own rendered content (§6).

## Decision (Task 2)

This plan runs under auto-mode. Task 2 is a `checkpoint:decision` that asks
two questions rather than offering an enumerated remedy-class list to
auto-select from (unlike 198-16's Task 2). Per this plan's own checkpoint
protocol ("auto-mode NEVER overrides your plan's own must_haves or measured
evidence"), the classification below is made directly from the evidence in
§§1–7, which is unambiguous and internally consistent (every failure shares
one cause, the cause is confirmed by a same-day commit's own explanatory
comment and commit message, and the "collision" hypothesis is directly
contradicted by the failures' own rendered content) — auto-resolving here
does not require picking between competing plausible options, since only one
classification is supported by the evidence:

1. **Where does the fix belong?** **Assertion-side.** The product change
   (197-02) is correct and intentional; the two Playwright specs are stale.
   Per D-05, this is a rotting assertion, and the fix is a derive-from-truth
   rewrite (assert the schema name that is still genuinely rendered) — not a
   loosened selector, not a broadened match, not a conditional guard. The
   rewrite must be demonstrated failing against a deliberately drifted input
   before acceptance (executed in Task 3, teeth proof recorded there).
2. **Does this collide with the deferred demo-seed drift?** **No.** §6 shows
   directly, from the failures' own rendered content, that the coverage
   page's data (schema picker, covered/uncovered counts) is correct and
   complete. Nothing about this gap requires scoping in any part of the
   deferred `ThreadlinePhoenix.DemoContractTest` seed-shape work.

**No scope expansion authorized or required.** Task 3 proceeds directly to
implementing the two assertion rewrites at the identified cause.

## Task 3 outcome: fix verified with teeth proof; a new, unrelated set of pre-existing failures discovered

Both assertions were rewritten exactly as classified in §8/Task 2 (`"selected
schema"` → `"public"`, the schema name the verdict heading still genuinely
renders), with a red-then-green teeth proof executed for each:

- `operator-coverage-readiness.spec.ts:142` (desktop-1024, `--grep desktop-1024`):
  drifted to a nonsense string → **RED** (`1 failed`); restored to `"public"`
  → **GREEN** (`1 passed`).
- `operator-accessibility.spec.ts:411` (`--grep "keyboard reachable"`): drifted
  → **RED** (`1 failed`, 2 passed unrelated); restored → **GREEN** (`3 passed`).

`git diff examples/threadline_phoenix/e2e/tests/` shows only these two lines
changed (plus explanatory comments) — no assertion deleted, no selector
broadened, no retry added, no conditional guard. `git diff .github/` and
`git diff examples/threadline_phoenix/e2e/playwright.config.ts` are both
empty — no job id, check name, aggregate membership, timeout bound, or
protection-file change of any kind.

**Running the plan's own required verify command
(`mix verify.example_browser --project=desktop-chromium --project=mobile-chromium`,
unbounded locally) surfaced a new, unrelated finding.** Neither of the two
now-fixed specs appears anywhere in the failure output. But the full run —
which CI's `maxFailures: 5` ceiling never allowed to complete, since it
always aborted at the first 5 failures, and those 5 were always these two
specs — does not exit 0:

```
28 failed
15 skipped
319 passed (14.2m)
```

The 28 failures span 14 distinct tests × 2 projects
(`operator-find-mobile.spec.ts`, `operator-phase-135-uat.spec.ts`,
`operator-phase-173-uat.spec.ts`, `operator-phase-175-uat.spec.ts`,
`operator-phase-177-uat.spec.ts`, `operator-screenshot-regression.spec.ts`,
`operator-screenshots.spec.ts`, `register.spec.ts`) — none in either file
this plan touched. They are **pre-existing and unrelated**: they were always
present but invisible to every prior CI run of this job, because the
ceiling always hit its cap on the two now-fixed specs first (alphabetically
and by execution order, `operator-accessibility`/`operator-coverage-readiness`
sort before all 8 of the newly-visible spec files) and aborted before
reaching them. Fixing the diagnosed cause did not make the lane green; it
revealed the next layer of pre-existing red that the ceiling had been
masking underneath it.

**This is out of this plan's scope** (`files_modified` names exactly
`ci.yml`, the two specs, and this artifact) and is **not diagnosed or fixed
here** — no cause investigation, no assertion changes, for any of the 28.
Logged to `.planning/phases/198-green-bringup/deferred-items.md` (Plan
198-17 entry) and `.planning/WINDOWS.md` (entry #8) for a follow-up
gap-closure plan. **The must-have backstop truth — "`Example app browser
E2E (Playwright)` concludes success on the next CI run" — is not expected to
hold as a direct result of this plan alone.** GREEN-04 Gap 4, narrowly
defined as "the 5 failures from run 33183920952," is closed; the browser
lane as a whole is not yet green.
