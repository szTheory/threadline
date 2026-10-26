---
phase: 246-debt-closeout-and-critic-retirement
reviewed: 2026-10-26T01:29:22Z
depth: standard
files_reviewed: 51
files_reviewed_list:
  - .github/workflows/browser-full.yml
  - .github/workflows/ci.yml
  - CONTRIBUTING.md
  - DESIGN-SYSTEM.md
  - bin/browser-full-projects
  - bin/verify-repo-hygiene
  - examples/threadline_phoenix/e2e/.gitignore
  - examples/threadline_phoenix/e2e/package.json
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - examples/threadline_phoenix/e2e/support/operator-journey-inventory.json
  - examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts
  - examples/threadline_phoenix/e2e/support/operator-surface-paths.ts
  - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts
  - guides/configuration-and-commands.md
  - lib/threadline/operator_surface/live/stress_live.ex
  - lib/threadline/operator_surface/live/stress_live/sections.ex
  - lib/threadline/operator_surface/stress_fixtures.ex
  - mix.exs
  - test/fixtures/dialyzer/README.md
  - test/fixtures/operator_surface/README.md
  - test/fixtures/operator_surface/design-system-ledger.json
  - test/fixtures/operator_surface/route-inventory.json
  - test/fixtures/operator_surface/source-surface-checklist.json
  - test/partition_weights.txt
  - test/support/operator_surface_fixtures.ex
  - test/threadline/browser_full_projects_contract_test.exs
  - test/threadline/browser_journey_evidence_contract_test.exs
  - test/threadline/changelog_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/deps_audit_gate_test.exs
  - test/threadline/deps_health_doc_contract_test.exs
  - test/threadline/deps_health_report_test.exs
  - test/threadline/dialyzer_ignore_contract_test.exs
  - test/threadline/dialyzer_slice_contract_test.exs
  - test/threadline/hex_pin_contract_test.exs
  - test/threadline/layer_boundary_contract_test.exs
  - test/threadline/operator_surface/component_contract_test.exs
  - test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
  - test/threadline/operator_surface/rendered_output_contract_test.exs
  - test/threadline/operator_surface/stress_fixtures_test.exs
  - test/threadline/operator_surface/stress_ledger_test.exs
  - test/threadline/operator_surface/stress_router_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/release_artifact_contract_test.exs
  - test/threadline/repo_hygiene_contract_test.exs
  - test/threadline/retry_network_contract_test.exs
  - test/threadline/source_size_contract_test.exs
  - test/threadline/ui_critic_retirement_doc_contract_test.exs
findings:
  critical: 0
  warning: 5
  info: 5
  total: 10
status: issues_found
---

# Phase 246: Code Review Report

**Reviewed:** 2026-10-26T01:29:22Z
**Depth:** standard
**Files Reviewed:** 51
**Status:** issues_found

## Summary

I reviewed the changed behaviour in every listed file against `0364446a`. The deletion is clean
in mechanical terms:

- A repo-wide `git grep` (excluding `.planning/` and the changelogs) finds no live reference to
  any deleted item: the `verify.capture`, `verify.mechanical`, `verify.critic_trust` and
  `verify.ui_critique` aliases, the `critic.*` tasks, the `critic:`/`capture:tier-a`/
  `capture:storybook`/`capture:graded`/`capture:refute` npm scripts, the `tier-a-capture`,
  `storybook-capture`, `graded-capture` and `refute-capture` projects, `mechanical_checker`,
  `critic_trust`, or `StressFixtures.graded_stories`.
- `ci-required` `needs:` matches the 12 remaining job keys and the header roster, and the
  ruleset still names only `CI required`.
- The pin counts (setup-beam: ci.yml 10, 16 in total; `mix deps.get`: 13 in total) match the
  workflows.
- `test/partition_weights.txt` matches the tracked test files exactly.
- The 22 changed contract test files pass locally (557 tests, 0 failures, `live_dialyzer`
  excluded).
- The new canary or synthetic controls in `browser_full_projects_contract_test.exs`,
  `browser_journey_evidence_contract_test.exs` and `deps_health_doc_contract_test.exs` stop the
  emptied tables from passing vacuously.

The problems are with honesty and enforcement rather than crashes:

- Docs and comments overstate what the one remaining Browser-full project actually covers.
- A restore pointer names a tag that does not exist yet, and nothing checks for it.
- The replacement proofs named for the two removed CI jobs are not pinned by any contract.
- A ledger invariant that has nothing to do with the critic lost its only test.
- The e2e output-root guard got narrower.

No BLOCKER was found.

## Warnings

### WR-01: Browser-full coverage is misdescribed: the lane renders 6 curated routes at 1280 only, not "every inventoried route at three viewports"

**File:** `CONTRIBUTING.md:311`, `.github/workflows/browser-full.yml:6`, `examples/threadline_phoenix/e2e/playwright.config.ts:25-28`
**Issue:** Browser-full runs `route-capture` with no `THREADLINE_E2E_EVIDENCE`. The new contract
at `browser_journey_evidence_contract_test.exs:434` asserts that browser-full.yml must never set
it. In that mode the only test that runs is `renders every curated operator route at 1280`
(`operator-page-capture.spec.ts:425`). It loops over the 6 hard-coded `ROUTES` (5 real routes
plus the degraded twin) at `BREAKPOINTS = [1280]`. The per-inventory-route tests at
1280/768/375 (`operator-page-capture.spec.ts:376-378`) skip unless evidence mode is on, so they
can never run in Browser-full. Three places still describe the lane wrongly:

- CONTRIBUTING says route-capture is "a render smoke over every inventoried route at three
  viewports".
- browser-full.yml says "a render smoke over every inventoried route".
- The playwright.config comment says the project drives the routes "at 1280/768/375 and, in
  evidence mode, writes the route scorecards". That is backwards: the non-evidence path writes
  `route-scorecards/`, and evidence mode is the multi-width path.

This matters because CONTRIBUTING's CI-coverage table is the stated proof of what runs where. A
reader will believe Browser-full gives inventory-wide, multi-viewport coverage that it does not.
**Fix:** Reword all three to match the code, for example: "`route-capture` (a render smoke over
the 5 curated operator routes plus a degraded Timeline twin, at 1280; the inventory-wide
1280/768/375 expansion runs only in evidence mode, which Browser-full never sets)". Fix the
playwright.config comment the same way. An alternative is to make the smoke loop over
`inventory.routes` × `widths`, so the docs become true.

### WR-02: The CONTRIBUTING restore pointer names `archive/ui-critic-loop`, which does not exist, and no check verifies it

**File:** `CONTRIBUTING.md:285-289`, `test/threadline/ui_critic_retirement_doc_contract_test.exs:17-31`
**Issue:** `git cat-file -t archive/ui-critic-loop` returns "Not a valid object name" both locally
and on origin. 246-LANDING.md treats creating and pushing the tag as a manual step after the
squash lands. Until then, the only documented way to recover about 114k removed lines is a dead
instruction. The doc contract checks only that the string appears in CONTRIBUTING, so it stays
green even if the maintainer never creates or pushes the tag. The two `# Removed:` comments in
ci.yml and the CONTRIBUTING removed-proof bullets also lean on the same tag ("restorable from the
tag the 'Retired' section above names").
**Fix:** Add a post-landing guard that fails while the tag is missing. One option is a test in
`ui_critic_retirement_doc_contract_test.exs`, tagged so it runs only on `main` and in
release-gating lanes:
```elixir
@tag :requires_tags
test "the named restore tag resolves to an annotated tag" do
  assert {"tag\n", 0} = System.cmd("git", ["cat-file", "-t", "refs/tags/#{@restore_tag}"])
end
```
The alternative is to make tag creation a blocking item in the landing checklist, with
`git ls-remote origin refs/tags/archive/ui-critic-loop` as its pass criterion, before the
removal PR merges. For example, tag the current `main` HEAD before the squash rather than after.

### WR-03: The claims about what "still catches" the two removed jobs are not pinned; the dominance checks were deleted with nothing to replace them

**File:** `test/threadline/ci_topology_contract_test.exs:1262-1381`, `CONTRIBUTING.md:593-594`, `.github/workflows/ci.yml:842-858`
**Issue:** Before this phase, `removed_proof_errors/3` failed when the proof cited as dominating a
removal stopped running. It checked that `mechanical_checker_test.exs` carried no
default-excluded tag and that the byte-stable step existed, with mutation controls for both. The
rewrite drops those checks. The new bullets for `verify-mechanical` and `verify-capture` say the
failure class "is still caught by" `style_contract_test.exs` in `verify-test` and
`operator-accessibility.spec.ts` in `verify-example-browser`. Nothing checks either claim:

- `style_contract_test.exs` could gain `@moduletag :pgbouncer_topology` (default-excluded).
- `operator-accessibility.spec.ts` could be deleted or renamed.

In both cases `ci_topology_contract_test.exs` stays green. CONTRIBUTING's own rule ("A CI proof
is removed only when another job catches the same failure class…") is pinned only by
`@dominators` for verify-docs and verify-hex-package, not for the two removals in this phase.
**Fix:** Restore a dominance check for the new removals, modelled on the deleted
`excluded_tags_in_checker` check:
```elixir
@style_contract "test/threadline/operator_surface/style_contract_test.exs"
@a11y_spec "examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts"
# in removed_proof_errors/2:
{File.regular?(@a11y_spec), "#{@a11y_spec} is gone; verify-capture/verify-mechanical bullets cite it"},
{excluded_tags(read_rel!([@style_contract])) == [], "#{@style_contract} is tag-excluded from verify-test"}
```
Add mutation controls: tag the style contract out, and point the spec path at a missing file.

### WR-04: The ledger still declares `ratchet_rule` and `ratchet.resets`, but the only test that enforced them was deleted

**File:** `test/threadline/operator_surface/stress_ledger_test.exs:73-121`, `test/fixtures/operator_surface/design-system-ledger.json:2479-2481`
**Issue:** The test "scores can only ratchet upward unless an explicit reset is recorded" was
removed together with the critic-cube tests. It did not depend on the critic. It checked the
scalar `current_score`, `target_score` and `ratchet_score` on every entry:

- each is an integer;
- `target_score >= current_score`;
- `current_score >= ratchet_score`, unless the id is in `ratchet.resets` and has a
  `reset_rationale`.

All three fields still exist on all 130 entries. The ledger still states
`"ratchet_rule": "Scores may only stay level or increase unless an explicit reset with rationale is recorded…"`,
and `@top_level_keys` still requires `ratchet_rule`. The only check left is
`minimum_scores` (120 ids), so a hand edit can now lower the score of any of the other 10
entries, or set `target_score < current_score` or a non-integer score, and the suite stays
green. DESIGN-SYSTEM.md's "Ratchet Rule" section was also deleted, so the rule now lives only in
the JSON and nothing enforces it.
**Fix:** Bring back the scalar part of the deleted test. Drop the `kind != "refute"` filter,
since refute entries are gone:
```elixir
test "scores can only ratchet upward unless an explicit reset is recorded" do
  ledger = ledger()
  reset_ids = Map.keys(ledger["ratchet"]["resets"])
  for e <- ledger["entries"] do
    assert is_integer(e["current_score"]) and is_integer(e["target_score"]) and is_integer(e["ratchet_score"])
    assert e["target_score"] >= e["current_score"]
    assert e["current_score"] >= e["ratchet_score"] or
             (e["id"] in reset_ids and is_binary(e["reset_rationale"]) and e["reset_rationale"] != "")
  end
end
```
If the ratchet is meant to be retired too, delete `ratchet_rule`, `resets` and `ratchet_score`
from the ledger and from `@top_level_keys`/`@entry_keys`, so no rule is left unenforced.

### WR-05: The output-root separation guard shrank from four immutable roots to the ledger file alone

**File:** `examples/threadline_phoenix/e2e/support/operator-surface-paths.ts:80-81`
**Issue:** `resolveOperatorSurfacePaths` used to reject an `outputRoot` override that overlapped
`scorecards/`, `golden/` or `refute/` under the fixture root. It now passes only `[ledgerPath]`.
As a result, any `outputRoot` nested under `test/fixtures/operator_surface/` that is not the
ledger file passes. One example is `test/fixtures/operator_surface/generated`.
`route-scorecards/` would then be written beneath the fixture root. The fixture README says
"Generated output is never written beneath this fixture root", and the sibling writer at
`operator-evidence-manifest.ts:364` already guards with the whole `fixtureRoot`. The two guards
for the same invariant now disagree.
**Fix:** Guard the whole fixture root, matching the manifest writer:
```ts
const immutableRoots = [fixtureRoot];
```
Add a case to `operator-surface-paths.test.ts` showing that an `outputRoot` of
`<fixtureRoot>/generated` throws `/overlap/`.

## Info

### IN-01: Stale "Tier A" wording in stress fixtures, including a summary the stress lab displays

**File:** `lib/threadline/operator_surface/stress_fixtures.ex:105-108`, `lib/threadline/operator_surface/stress_fixtures.ex:737`
**Issue:** The moduledoc comment says "this Tier A cartesian proves the full structural matrix",
and `page_data/2`'s fallback summary is "Synthetic per-page path fixture for #{id} (Tier A
structural cell)." Tier A capture was retired in this phase. The summary string reaches the
`/audit/__stress` page.
**Fix:** Reword both. For example: "structural cell (rendered by the stress lab; the Tier A
capture is retired)", or drop the tier label.

### IN-02: Browser-full's job name still says "(all projects)"

**File:** `.github/workflows/browser-full.yml:46`
**Issue:** `name: Example app browser E2E (all projects)`, inside the workflow `Browser (full
project set)`, now runs exactly one project. That misleads anyone reading the Actions UI or the
failure issue title.
**Fix:** Rename it, for example "Example app browser E2E (projects ci.yml does not run)", and
update any parity pins that need it. Job `id:`s stay stable.

### IN-03: The retired-critic guide leak guard checks only two needles

**File:** `test/threadline/ui_critic_retirement_doc_contract_test.exs:58`
**Issue:** Only `critic:gate` and `verify.ui_critique` are refused in `guides/**/*.md`. A guide
that reintroduced `mix verify.capture`, `mix verify.mechanical`, `mix verify.critic_trust` or
`mix critic.measure` (the commands this phase removed from `guides/configuration-and-commands.md`)
would pass.
**Fix:** Extend the needle list to every retired alias and task:
`~w(critic: verify.ui_critique verify.capture verify.mechanical verify.critic_trust critic.measure critic.synth)`.

### IN-04: The reference-manifest path-set control now tests only one direction

**File:** `test/threadline/operator_surface/rendered_output_contract_test.exs:391-395`
**Issue:** With a one-entry manifest, the control now appends an untracked row (the manifest has
an extra path). It no longer exercises the opposite case: git tracks a file the manifest lacks.
That is the more likely drift when someone adds a new fixture.
**Fix:** Also assert
`{:error, {:path_set_mismatch, _}} = validate_reference_manifest(manifest, tracked ++ [untracked_row])`.

### IN-05: Leftover e2e dev dependency after `typescript` and `typecheck` were removed

**File:** `examples/threadline_phoenix/e2e/package.json:14`
**Issue:** `@types/node` stays a devDependency, but nothing type-checks the e2e TypeScript any
more: there is no `tsc`, no `typecheck` script and no tsconfig. `tsx` strips types without
reading them. The specs and support modules are no longer type-checked anywhere. That was also
true in CI before this phase, but the local affordance is now gone too.
**Fix:** Either drop `@types/node`, or keep `typescript` plus a `typecheck` script (and wire it
into `mix verify.example_browser` or CI) if type safety of the e2e harness is wanted.

---

_Reviewed: 2026-10-26T01:29:22Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
