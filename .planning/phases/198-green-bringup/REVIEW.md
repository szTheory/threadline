---
phase: 198-green-bringup
reviewed: 2026-08-29T13:22:38Z
depth: deep
diff_range: 35f1b519..455c2328
files_reviewed: 15
files_reviewed_list:
  - examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-177-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts
  - examples/threadline_phoenix/e2e/tests/register.spec.ts
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex
  - examples/threadline_phoenix/test/support/walkthrough_case.ex
  - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs
  - lib/threadline/operator_surface/live/export_status_live.ex
  - test/threadline/operator_surface/copy_contract_test.exs
  - test/threadline/operator_surface/live/export_status_live_test.exs
findings:
  critical: 5
  warning: 11
  info: 4
  total: 20
status: issues_found
---

# Phase 198 (green-bringup, gap-closure round 4): Code Review Report

**Reviewed:** 2026-08-29T13:22:38Z
**Depth:** deep (cross-file: specs traced to product source; tests traced to the queries/templates they assert against)
**Files Reviewed:** 15
**Status:** issues_found

## Hard-constraint verdict

| Constraint | Result |
|---|---|
| No `@tag :skip` / `@moduletag :skip` / `test.skip` added | **PASS** — zero matches on added lines |
| No `.png` baseline regenerated | **PASS** — `git diff 35f1b519..HEAD -- '*.png'` is empty |
| No committed scorecard regenerated | **PASS** — `git diff 35f1b519..HEAD -- .planning/scorecards/` is empty |
| `playwright.config.ts`, `ci.yml`, `rulesets/main.json`, `CONTRIBUTING.md` byte-unchanged | **PASS** — all four absent from the diff |
| No `maxDiffPixelRatio` loosened | **PASS** — `0.03` unchanged; only the screenshot *target* changed |
| No assertion removed or weakened | **FAIL** — see CR-03, CR-04, CR-05, WR-08, WR-09, WR-10 |
| No vacuous pass introduced | **FAIL** — see CR-02, CR-03 |

Four of seven pass. The two failures are the load-bearing ones: this round added assertions whose in-code comments claim teeth the product source cannot provide, and replaced one real pin with a tautology.

## Summary

The round is broadly honest work: `retention_tail.ex` fixes a real collateral-deletion bug at cause, several Playwright specs were genuinely re-anchored to product contracts I verified line-by-line against `unsupported.ex`, `ui.ex`, `surface_header.ex`, `coverage_live.ex` and `row_history_component.ex`, and the `register.spec.ts` and phase-175 empty-edge additions are strict improvements.

But three of the changes that were *sold* as anti-vacuity hardening are themselves vacuous or tautological, one authorization UAT quietly stopped testing authorization, the `export_status_live.ex` "de-duplication" did not de-duplicate anything, and the phase-177 rewrite traded 12 enumerated stories for a floor of one while collapsing 60 navigations into a single 120s test budget.

---

## Critical Issues

### CR-01: The `export_status_live.ex` duplicate label function was realigned, not removed — `Presentation.export_action_label/2` is still uncalled dead code and still diverges on 3 of 5 outcomes

**File:** `lib/threadline/operator_surface/live/export_status_live.ex:476-493`, `lib/threadline/operator_surface/presentation.ex:326-346`

**Issue:** The stated fix was to eliminate a private duplicate that had drifted from the spec-tested canonical `Presentation.export_action_label/2`. The diff changes exactly one string literal (`"Expired"` → `"Export expired"`). The private `defp export_job_status_label/1` still exists, is still the only thing rendered at line 308, and `Presentation.export_action_label/2` remains called from nowhere in `lib/` (only from `presentation_test.exs`). Verified:

```
lib/threadline/operator_surface/presentation.ex:327:  def export_action_label(job, opts \\ [])   # zero lib callers
lib/threadline/operator_surface/live/export_status_live.ex:476:  defp export_job_status_label(job)
```

The divergence is not merely latent — it is live on 3 of 5 branches. For the same job the two functions now return:

| readiness | `Presentation.export_action_label/2` | rendered `export_job_status_label/1` |
|---|---|---|
| `:preparing` | `"Preparing download"` | `"Queued"` / `"Processing"` |
| `:needs_attention` | `"Reopen source search"` | `"Failed"` |
| `:unavailable` + expired | `"Export expired"` | `"Export expired"` ✓ |
| `:unavailable` + missing file | `"File unavailable"` | `"File unavailable"` ✓ |

The private copy also uses `to_string/1` instead of `Presentation.normalize_status/1` (no atom-status handling parity) and hardcodes `DateTime.utc_now()` instead of honoring the `:now` opt, so it is untestable at a frozen clock. Two independently-maintained copies of one copy contract is exactly the condition that produced the original `"Expired"` drift; nothing prevents the next one.

**Fix:** Delete the private function and call the canonical one. The template already gates on `Presentation.export_downloadable?(job)`, so the `:ready` branch is unreachable and behavior for the reachable branches is the canonical (better) copy:

```elixir
# export_status_live.ex — delete defp export_job_status_label/1 entirely, and at line 308:
<span class="tl-hint" role="status"><%= Presentation.export_action_label(job) %></span>
```

Then update `copy_contract_test.exs:447-462` (which currently greps for `defp export_job_status_label`) to assert against `Presentation.export_action_label/2` instead, and update `export_status_live_test.exs` expectations to `"Preparing download"` / `"Reopen source search"`.

---

### CR-02: The new "non-vacuous coverage snapshot" assertions are vacuous — `"Covered"` and `"Needs capture"` are static `<dt>` labels rendered unconditionally

**File:** `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs:88-95`

**Issue:** The added code and its comment claim a guarantee the product source cannot provide:

```elixir
# "...so a database that is either all-covered or entirely empty of
#  triggers cannot satisfy this assertion."
assert coverage_html =~ "Covered"
assert coverage_html =~ "Needs capture"
```

`coverage_live.ex:291-297` renders both strings as **static definition-list labels** in the verdict counts block, independent of the counts:

```heex
<div class="tl-coverage-verdict__count">
  <dt>Covered</dt>
  <dd><%= @snapshot.covered_count %></dd>
</div>
<div class="tl-coverage-verdict__count">
  <dt>Needs capture</dt>
  <dd><%= @snapshot.uncovered_count %></dd>
</div>
```

With `covered_count == 0` and `uncovered_count == 0` both assertions still pass. Worse, there is no per-row `"Covered"` chip anywhere: `Presentation.status_label("covered")` returns `"Captured"` (presentation.ex:218), so `"Covered"` can *only* ever come from the static legend. This is a textbook vacuous pass, introduced by a change whose stated purpose was to remove vacuous passes.

**Fix:** Assert the counts, not the labels:

```elixir
assert coverage_html =~ ~r{<dt>Covered</dt>\s*<dd>\s*(?!0\s*<)\d+}s
assert coverage_html =~ ~r{<dt>Needs capture</dt>\s*<dd>\s*(?!0\s*<)\d+}s
# or, better, assert the row-level chips that only exist when the sets are non-empty:
assert coverage_html =~ ~s(<span class="tl-chip tl-chip--danger">Needs capture</span>)
assert coverage_html =~ "Captured"
```

---

### CR-03: `assert record.subject_ref == subject_ref` is tautological — the query already filters on that exact value, and the change deleted the only pin on the manifest's declared literal

**File:** `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs:249-266`

**Issue:** The diff replaced

```elixir
assert record.subject_ref == %{"policy" => "walk-demo-redaction-policy"}
```

with `assert record.subject_ref == subject_ref`, justified by "an inline literal would silently rot". The inline literal *was the teeth*. `Threadline.Evidence.list_subject_ref_history/3` (evidence.ex:82-91) puts `subject` and `subject_ref` into the filter set and hands them to `list_history/2`, i.e. `WHERE subject = ^subject AND subject_ref = ^subject_ref`. Every returned record therefore *necessarily* has `subject_ref == subject_ref` and `subject == "redaction_policy"`. Both assertions in the block are now no-ops; the only surviving load-bearing assertion is `length(records) >= 1`.

Net effect: if `Manifest.evidence_subject_ref(:redaction_policy)` and the seeder both drift to `%{"policy" => "anything-else"}`, this test still passes green. Before the change it failed. That is a strictly weaker test.

**Fix:** Keep both — pin the manifest's declared value *and* assert round-tripping:

```elixir
subject_ref = Manifest.evidence_subject_ref(:redaction_policy)
# Pin the declared value: this is a published demo contract, drift must be deliberate.
assert subject_ref == %{"policy" => "walk-demo-redaction-policy"}
...
assert record.subject_ref == subject_ref
```

---

### CR-04: Phase-177 group-story coverage floor dropped from 12 enumerated stories to `length > 0`

**File:** `examples/threadline_phoenix/e2e/tests/operator-phase-177-uat.spec.ts:14-24, 78-108`

**Issue:** The hard-coded 12-element `groupStories` array was replaced by a runtime lookup whose only cardinality assertion is:

```ts
expect(ids.length, "expected at least one group story in the catalog").toBeGreaterThan(0);
```

`stress_fixtures.ex:72` declares exactly 12 group stories. If a refactor drops 11 of them, or if `stress_live.ex`'s list is ever truncated/paginated, or if the `.tl-stress__story-id` span is renamed such that only a subset is returned, this suite reports green on 1/12 of its prior coverage. The rot-resistance goal is legitimate but is achieved by the *runtime resolution*, not by dropping the floor — the two are separable.

**Fix:** Keep runtime resolution, restore a real floor and pin the identities that the surrounding UAT prose names:

```ts
expect(ids.length, "group story catalog shrank").toBeGreaterThanOrEqual(12);
for (const required of ["group.page-header.current", "group.modal-destructive.current",
                        "group.drawer-form.reference", "group.offline.current"]) {
  expect(ids, `required group story missing: ${required}`).toContain(required);
}
```

---

### CR-05: The Phase-135 authorization UAT no longer proves authorization — it now asserts a capability descriptor that any role (including admin) can see

**File:** `examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts:76-89`

**Issue:** The test is named `"support user is denied admin-only Coverage"`. Its assertions were changed from an access-denial affordance to `Unsupported.descriptor(:coverage_unavailable)`, whose own body text (unsupported.ex:10) reads: *"Coverage is unavailable in this support lane. **This is not a permissions issue.**"* The test's own added comment concedes this: *"not an access-control denial."*

The consequence is a security-coverage regression, not a cosmetic one. The descriptor is a *lane capability* signal, not a *role* signal. If an authorization regression made Coverage readable by support users, or conversely if Coverage became unavailable to *every* role, this test cannot tell the difference — it passes in both worlds. There is no admin-sees-coverage counterpart in this file (only 4 tests, none of them admin/coverage), so nothing in the Phase-135 suite still distinguishes role from lane.

**Fix:** Either rename to match the weaker semantics *and* add the missing role-discriminating half, or keep the name and make it discriminate:

```ts
test("Coverage is role-discriminating: support gets the unavailable lane, admin gets the table", async ({ page }) => {
  await login(page, supportAcmeEmail);
  await page.goto("/audit/coverage");
  await expect(page.getByRole("heading", { name: "Coverage unavailable" })).toBeVisible();
  await expect(page.getByTestId("coverage-table")).toHaveCount(0);

  // The load-bearing half: prove this is the SUPPORT lane, not a globally dead page.
  await logout(page);
  await login(page, adminEmail);
  await page.goto("/audit/coverage");
  await expect(page.getByTestId("coverage-table")).toBeVisible();
});
```

---

## Warnings

### WR-01: The advisory lock is session-scoped and leaks on an ExUnit timeout kill, poisoning a pooled connection for the rest of the run

**File:** `examples/threadline_phoenix/test/support/walkthrough_case.ex:25-34`

**Issue:** `pg_advisory_lock/1` is a **session**-level lock, released only by an explicit `pg_advisory_unlock` or by the backend connection closing. The `try/after` handles exceptions, but ExUnit's per-test timeout terminates the test process by exit signal — `after` does not run for an untrapped exit. The connection is then checked back into the DBConnection pool **still holding the lock**, and every subsequent `seed_demo_fiction!` blocks forever (no `lock_timeout` is set) until it hits its own 60s timeout, cascading the failure.

The trigger for this is not hypothetical: the phase's own documented `demo_reset_test.exs:56` 60s timeout is exactly the kind of event that would leave the lock stranded. The remedy therefore converts an intermittent single-test flake into a whole-suite hang.

**Fix:** Use a transaction-scoped lock (auto-released on commit/rollback/disconnect) and bound the wait:

```elixir
Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
  Repo.transaction(fn ->
    Repo.query!("SET LOCAL lock_timeout = '45s'")
    Repo.query!("SELECT pg_advisory_xact_lock($1)", [@demo_seed_lock_key])
    assert :ok = Reset.run()
    assert :ok = Seed.run()
  end, timeout: :infinity)
end)
```

(If `Reset.run/0`/`Seed.run/0` must not run inside one outer transaction, use `pg_try_advisory_lock` in a bounded retry loop instead of an unbounded `pg_advisory_lock`.)

---

### WR-02: The lock guards only `WalkthroughCase`'s own callers, and the cause it cites cannot occur — every seeding module is `async: false`

**File:** `examples/threadline_phoenix/test/support/walkthrough_case.ex:14-23`

**Issue:** Two problems with the diagnosis-to-remedy link:

1. **The lock is not comprehensive.** Three other modules call `Reset.run/0`/`Seed.run/0` inside `unboxed_run` without taking it — `test/threadline_phoenix/demo_reset_test.exs:14-29`, `test/threadline_phoenix/demo_contract_test.exs:17-18,193,213`, `test/mix/tasks/threadline_evidence_show_example_test.exs:11-13`. If cross-module contention is the cause, this fix cannot prevent it; the unguarded seeders are precisely the ones that would collide with a guarded one.
2. **The stated cause is not reachable intra-run.** All five seeding modules are `use ... async: false` (`demo_reset_test.exs:2`, `demo_contract_test.exs:6`, `threadline_evidence_show_example_test.exs:3`, `walkthrough_happy_path_test.exs:9`, `walkthrough_evidence_test.exs:5`). ExUnit never runs two `async: false` modules concurrently, so "two concurrent unboxed seed/reset cycles" cannot happen within one `mix test`. The comment asserts a mechanism the test topology forbids.

Cross-*OS-process* contention (a parallel CI lane, or a developer running `mix demo.seed`) is the only surviving plausible cause — and for that, (1) makes the fix ineffective. As shipped this is unproven mitigation that adds WR-01's failure mode for no demonstrated benefit.

**Fix:** Either (a) move the lock into `Demo.Reset`/`Demo.Seed` themselves so *every* entry point is covered including the mix tasks, or (b) delete it and re-open the timeout diagnosis with evidence (a `pg_locks` / `pg_stat_activity` capture at the moment of the hang), rather than shipping a speculative remedy.

---

### WR-03: The retention cutoff and the org-Y backdate are two independent magic numbers with no enforced ordering

**File:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex:13, 30, 54-57`

**Issue:** The whole correctness of the fix rests on `@retention_purge_cutoff_days_before_epoch (60) < @org_y_backdate_days (90)` and on `60` exceeding every other org's epoch offset. Nothing in code enforces either. If someone lowers `@org_y_backdate_days` to 30, the purge silently deletes nothing, `assert_org_y_audit_empty!/1` fails with a confusing "org Y not empty" rather than "your cutoff no longer covers the backdate". If someone raises it past 60 in the other direction, other orgs get swept.

There is also a latent raise: `Retention.resolve_cutoff/2` (retention.ex:120-128) raises `ArgumentError` when the requested cutoff is **newer** than the policy cutoff. The requested cutoff is frozen at `2026-03-28` (epoch `2026-05-27` minus 60d) while the policy cutoff is `utc_now() - 30d`. On any machine whose clock reads earlier than `2026-04-27` the seed raises. Today (2026-08-29) it is safe and gets safer over time, but a clock-skewed CI runner or a container with a bad RTC will hit it with an opaque error.

**Fix:** Assert the invariant at compile time and make the failure mode legible:

```elixir
@retention_purge_cutoff_days_before_epoch 60
# Invariant: the cutoff must strictly precede org Y's backdate (so org Y is purged)
# and strictly follow every other org's epoch offset (so nothing else is).
@earliest_other_org_epoch_offset_days 21
if @retention_purge_cutoff_days_before_epoch >= @org_y_backdate_days or
     @retention_purge_cutoff_days_before_epoch <= @earliest_other_org_epoch_offset_days do
  raise "demo retention cutoff must sit strictly between " <>
          "#{@earliest_other_org_epoch_offset_days}d and #{@org_y_backdate_days}d before epoch"
end
```

---

### WR-04: The safety comment's stated margin is factually wrong

**File:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex:27-29`

**Issue:** The comment justifying `60` states the cutoff sits above *"the earliest other-org epoch-anchored timestamp (filler's `-14 day` bound, comfortably preserved)"*. That is not the earliest. Two seeders anchor further back:

- `lib/threadline_phoenix/demo/seed/personas.ex:99` — `setup_ts = DateTime.add(Manifest.epoch(), -21, :day)`
- `lib/threadline_phoenix/demo/seed/temporal.ex:37` — `setup_ts = DateTime.add(Manifest.epoch(), -21, :day)`

The true margin is 39 days, not 46. The conclusion still holds, but this is the *only* documentation of why `60` is safe, and it is wrong — a future reader tightening the cutoff toward the claimed `-14d` bound would delete the persona/temporal setup rows.

**Fix:** Correct the comment to `-21 day` and cite `personas.ex:99` / `temporal.ex:37` by path, then wire the number into the compile-time guard from WR-03 so the comment can no longer rot independently.

---

### WR-05: The purge is still globally scoped by time, not by org, and nothing tests cross-org survival

**File:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex:37-51, 87-93`

**Issue:** Two residual hazards behind the fix:

1. **No org scoping.** `Retention.purge/1` remains a global `DELETE ... WHERE captured_at < cutoff` (retention.ex:205-209). Cross-org preservation is a *coincidence* of the epoch offsets, not a constraint. `assert_org_y_audit_empty!/1` proves the purge still bites, but there is no complementary assertion that any other org survived — the regression this round fixed would, at the seed level, still pass silently. (The newly added `total_count >= 1` guards in `demo_contract_test.exs` are a good indirect backstop; they are not a substitute for a direct one.)
2. **The wall-clock landmine remains armed.** `enable_retention!/0` permanently writes `keep_days: 30` into `Application.env(:threadline, :retention)` and never restores it. Any subsequent `Retention.purge/1` call without an explicit `:cutoff` — an Oban job, a mix task, a follow-on seed step, a host app — reproduces the exact bug this round fixed, because the policy default is `utc_now() - 30d` and the entire demo fiction is anchored ~94 days in the past.

**Fix:** Add a direct survival assertion in `run/1` right after the purge, and restore the retention env afterwards:

```elixir
defp assert_other_orgs_survived!(org_y_id) do
  surviving =
    from(ac in AuditChange,
      join: at in assoc(ac, :transaction),
      where: fragment("? -> 'organization_id' <> to_jsonb(?::text)", at.meta, ^org_y_id),
      select: count(ac.id)
    )
    |> Repo.one!()

  if surviving == 0 do
    raise "demo retention purge deleted every non-org-Y audit change (cutoff too new)"
  end
end
```

---

### WR-06: The 177 rewrite puts 60 navigations under a single 120s test budget that previously covered 5

**File:** `examples/threadline_phoenix/e2e/tests/operator-phase-177-uat.spec.ts:78-108`

**Issue:** Twelve independent `test(...)` blocks were collapsed into one. Each formerly got its own `timeout: 120_000` (playwright.config.ts:128) for 5 `page.goto` + overflow evaluations. The single replacement now performs 1 catalog navigation + 12 stories × 5 viewports = **61 navigations** plus 60 `setViewportSize` reflows and 120 `expect` calls, all inside one 120s budget — roughly a 12× reduction in per-work-unit time. At `workers: 1` (config:142) and ~1-2s per LiveView navigation this lands at 60-120s with no headroom; the config's own comment at line 133 flags per-invocation timeout budgeting as a known concern.

Two secondary costs: `test.step` failures abort the enclosing test, so a failure on story 1 leaves stories 2-12 **unproven but not reported as failures**; and `retries: 1` on CI now re-runs all 60 navigations to retry one.

**Fix:** Keep runtime resolution but restore per-story tests via a synchronous catalog source, or at minimum raise the budget and make the remaining stories still run:

```ts
test.describe.configure({ timeout: 600_000 });
// ...and collect failures instead of aborting:
const failures: string[] = [];
for (const story of stories) {
  try { await checkStory(page, story); } catch (e) { failures.push(`${story}: ${e}`); }
}
expect(failures, failures.join("\n")).toEqual([]);
```

---

### WR-07: `resolveGroupStories` does not verify the returned ids are actually group stories

**File:** `examples/threadline_phoenix/e2e/tests/operator-phase-177-uat.spec.ts:17-24`

**Issue:** `stress_live.ex:56` resolves the filter as `allow(params["category"], @category_allowlist)`; an unrecognised value yields `nil`, and `filter_by(:category, nil)` applies **no filter at all**. So if `"group"` is ever renamed in `StressFixtures.categories/0`, or the query-param key changes, the helper silently returns the *entire* catalog and the test claims group-story coverage it did not measure. Nothing asserts the returned ids share the `group.` prefix.

**Fix:**

```ts
const ids = (await page.locator('[data-testid="stress-story-list"] .tl-stress__story-id')
  .allTextContents()).map((id) => id.trim());
expect(ids.length, "expected the group category filter to return the group catalog")
  .toBeGreaterThanOrEqual(12);
for (const id of ids) {
  expect(id, "category=group filter did not apply").toMatch(/^group\./);
}
```

---

### WR-08: The `operator-nav-shell` tag assertion was dropped without replacement

**File:** `examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts:89-96`

**Issue:** `expect(await shell.evaluate((el) => el.tagName)).toBe("DETAILS")` was moved onto the inner `.tl-shell-nav__disclosure`, which is correct per `surface_header.ex:57-58`. But nothing now asserts anything about `operator-nav-shell` itself beyond visibility. The comment claims the shell "is now a `<nav>` landmark" — an accessibility-landmark contract that the test no longer checks. If a refactor turns it back into a `<div>`, the landmark regresses silently.

**Fix:** Add the assertion the comment already implies:

```ts
expect(await shell.evaluate((el) => el.tagName)).toBe("NAV");
await expect(shell).toHaveAttribute("aria-label", "Audit navigation");
```

---

### WR-09: The actor-page assertion lost its type/prefix check and can trip Playwright strict mode

**File:** `examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts:136-143`

**Issue:** Three sub-issues in the replacement of `getByText(\`Actor: user / ${leavingAgentId}\`)`:

1. `.tl-secondary-ref[title="${leavingAgentId}"]` no longer asserts the actor **type** (`user`) is displayed. The original assertion covered id *and* type; the replacement covers only id.
2. No `.first()`. `UI.ref` is used in multiple places on the actor detail surface (it is the same component the exports page uses per-row); if the same actor ref renders twice, `expect(locator)` throws a strict-mode violation rather than passing. The surrounding file uses `.first()` elsewhere for exactly this reason.
3. `leavingAgentId` is interpolated raw into a CSS attribute selector. It is a UUID today, but the value flows from seeded data — a quote or backslash would silently produce an invalid selector rather than a clear failure.

**Fix:**

```ts
const actorRef = page.locator(`.tl-secondary-ref[title=${JSON.stringify(leavingAgentId)}]`).first();
await expect(actorRef).toBeVisible();
// Keep the type assertion the old text check provided:
await expect(page.getByText(/Actor.*\buser\b/i).first()).toBeVisible();
```

---

### WR-10: `refute timeline_html =~ "View Incident"` was deleted rather than kept alongside the new assertion

**File:** `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs:36-49`

**Issue:** The route changed from `~p"/audit"` to `~p"/audit/timeline"` (a good fix — `/audit` redirects to a generic Home with no org-scoped emptiness signal) and the negative assertion was replaced by `assert timeline_html =~ "No captured changes"`. The positive assertion is genuinely stronger and I do not read this as a net weakening. But the negative cost nothing to keep, and it guards a different failure: a page that renders both an empty-state banner *and* stale incident links (e.g. a partially-scoped query) satisfies the new assertion and would have failed the old one.

**Fix:** Keep both.

```elixir
assert timeline_html =~ "No captured changes"
refute timeline_html =~ "View Incident"
```

---

### WR-11: The `<details>` expansion in the mobile spec is order-dependent with no state assertion

**File:** `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts:108-116`

**Issue:** `addCapture.click()` toggles the `<details>` at `coverage_live.ex:197`. It is collapsed by default today, so the click opens it. If the product ever ships the row expanded (`<details open>`) — a plausible density/UX change — the click *closes* it and the next assertion fails with an opaque "element not visible" rather than "test assumption stale". The test also never asserts the resulting open state, so the intermediate step is unverified.

**Fix:** Make the intent explicit and idempotent:

```ts
const row = page.locator("details.tl-row-action--capture").first();
await expect(row.locator("summary")).toContainText("Add capture");
if (!(await row.evaluate((el: HTMLDetailsElement) => el.open))) {
  await row.locator("summary").click();
}
await expect(row).toHaveAttribute("open", "");
await expect(page.getByText("mix threadline.gen.triggers --tables").first()).toBeVisible();
```

---

## Info

### IN-01: The row-history screenshot now targets a content-sized element with no height guard

**File:** `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts:117-131`

The retarget from `.tl-drawer-container` to `.tl-drawer` is correct and well-evidenced — I confirmed `data-testid` lands on the outer container via `{@rest}` (ui.ex:958-962) while `class="tl-row-history-drawer"` lands on the inner `#{id}-content` panel (ui.ex:980-982, row_history_component.ex:74-78). Worth noting: `.tl-drawer` is content-sized vertically, so a future content addition that makes the panel taller than the viewport changes what Playwright captures (element screenshots clip to the scrollable extent) and will diff against the pinned baseline. Consider asserting the panel's bounding-box height is within the viewport before the screenshot, so the failure names the cause.

### IN-02: `@demo_seed_lock_key` is an unnamespaced `phash2` value

**File:** `examples/threadline_phoenix/test/support/walkthrough_case.ex:23`

`:erlang.phash2/1` yields a 27-bit value with no namespace. Postgres advisory locks share one global keyspace per database; any other tool (a migration helper, a background job library, another app on the same DB) using a colliding integer would silently serialize against this. Prefer the two-int form with a stable app-specific classid: `pg_advisory_xact_lock($1, $2)` with `$1` a fixed Threadline classid.

### IN-03: `demo_reset_test.exs:56` cold `MIX_ENV=prod` compile timeout (known, not re-reported)

Not re-raised as a finding per scope. The right fix is to stop paying compilation inside a 60s ExUnit budget rather than to raise the budget: either pre-warm `MIX_ENV=prod` `_build` in a CI step before `mix test` and assert the compile is a no-op, or replace the shell-out with a direct call to the task module under a test env, keeping the shell-out as a separately-tagged, separately-timed integration test with an explicit `@tag timeout: :infinity`. Raising the ExUnit timeout alone would hide the cost rather than remove it.

### IN-04: Verified-correct changes (no action)

For the record, these edits were traced to product source and are strictly-or-equally strict:

- `operator-phase-135-uat.spec.ts` copy matches `unsupported.ex:8,10` exactly (the *semantics* problem is CR-05; the strings are right).
- `operator-phase-173-uat.spec.ts` — `aria-haspopup="menu"` matches `ui.ex:1265`; a pre-click assertion was **added**, making it stricter.
- `operator-phase-175-uat.spec.ts` — `.tl-shell-nav__disclosure` matches `surface_header.ex:58`; the two hide-at-zero / non-empty preconditions and the `.tl-empty` text assertion (`timeline_live.ex:1264`) are net-new teeth.
- `register.spec.ts` — narrowing to `.rd-signed-in` (`page_html.ex:22`) is a *stricter* location constraint, not a looser one, and adds a third assertion.
- `operator-screenshot-regression.spec.ts` / `operator-screenshots.spec.ts` — `{ exact: true }` on the "Exports" heading (`export_status_live.ex:138`) disambiguates against "Exports need attention"/"Exports are processing" and is stricter.
- `demo_contract_test.exs` — the three `total_count >= 1` non-emptiness guards are genuine, correctly-constructed anti-vacuity additions and are the real regression net for the retention fix.
- `copy_contract_test.exs` / `export_status_live_test.exs` — `"Expired"` → `"Export expired"` is stricter (the old needle is a substring-adjacent weaker match).

---

_Reviewed: 2026-08-29T13:22:38Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
