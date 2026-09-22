---
phase: 201-rendered-output
verified: 2026-09-22T00:05:50Z
verification_target: 7ef820bce2327454e44846a985911408e8b71247
verification_target_note: "Retargeted from 43c0672e, which was amended (never pushed) to exclude 1066 machine-local critic cache files an over-broad `git add .planning/` had swept in. The covered-input bytes are unchanged, so covered_digest below still holds; 201-VERIFICATION.md is not a member of its own covered set."
previous_verification_target: ae7e75fa1eaa31efa837c957690eb8dfb506d0c7
refresh_pass: true
status: passed
score: 6/6 must-haves verified
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
  - .planning/WINDOWS.md
  - .planning/audits/201-rendered-output-evidence.md
  - .planning/phases/201-rendered-output/201-01-PLAN.md
  - .planning/phases/201-rendered-output/201-01-SUMMARY.md
  - .planning/phases/201-rendered-output/201-02-PLAN.md
  - .planning/phases/201-rendered-output/201-02-SUMMARY.md
  - .planning/phases/201-rendered-output/201-03-PLAN.md
  - .planning/phases/201-rendered-output/201-03-SUMMARY.md
  - .planning/phases/201-rendered-output/201-04-PLAN.md
  - .planning/phases/201-rendered-output/201-04-SUMMARY.md
  - .planning/phases/201-rendered-output/201-05-PLAN.md
  - .planning/phases/201-rendered-output/201-05-SUMMARY.md
  - .planning/phases/201-rendered-output/201-CONTEXT.md
  - .planning/phases/201-rendered-output/201-DISCUSSION-LOG.md
  - .planning/phases/201-rendered-output/201-PATTERNS.md
  - .planning/phases/201-rendered-output/201-RESEARCH.md
  - .planning/phases/201-rendered-output/201-VALIDATION.md
  - lib/threadline/operator_surface/live/evidence_live.ex
  - lib/threadline/operator_surface/live/export_status_live.ex
  - lib/threadline/operator_surface/live/row_history_live.ex
  - lib/threadline/operator_surface/live/start_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - mix.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/critic_iteration_runbook_doc_contract_test.exs
  - test/threadline/operator_surface/live/evidence_live_test.exs
  - test/threadline/operator_surface/live/export_status_live_test.exs
  - test/threadline/operator_surface/live/row_history_live_test.exs
  - test/threadline/operator_surface/live/start_live_test.exs
  - test/threadline/operator_surface/live/timeline_live_test.exs
  - test/threadline/operator_surface/rendered_output_contract_test.exs
covered_digest: "v1:sha256:9ee00d5700029a9805e37a7bb89d4c0b7da32055b9368491730fc52be711bc43"
previous_covered_digest: "v1:sha256:86d45010c30bb7c07c9b3fcdab6b7c8d30f5697b7701d65aa5abac9263a02449"
behavior_unverified: 0
overrides_applied: 0
advisory:
  - finding: "The CSS class token `tl-home__earned-flow` (start_live.ex:222, style.ex:907/4233) still carries `earned-flow` taxonomy vocabulary into rendered DOM and emitted CSS."
    category: other
    reason: "Not a violation of any Phase 201 criterion as written: RENDER-01 covers visible text, RENDER-02 covers provenance attributes, and RENDER-06 explicitly requires class attributes to stay byte-identical, so renaming it here would breach the phase's own no-structure-change contract. Raised for the maintainer to route to Phase 204 (Structure) or explicitly accept."
    evidence_status: "observed by grep; no deterministic failure"
  - finding: "Four e2e spec filenames still encode phase chronology (operator-phase-135/173/175/178-uat.spec.ts)."
    category: other
    reason: "Filenames are not rendered output and were outside the phase's declared rename set (three Elixir tests plus the shell-home spec). Follow-up hygiene, not a RENDER requirement."
    evidence_status: "observed by ls; no deterministic failure"
  - finding: "Closeout bookkeeping is now MOSTLY reconciled but not complete: the phase-level `Phase 201: Rendered Output` checkbox at .planning/ROADMAP.md:71 is still `[ ]`, while all five 201-*-PLAN.md checkboxes and all six RENDER rows are reconciled."
    category: other
    reason: "Prior advisory 3 was closed for REQUIREMENTS (RENDER-03/04/05 now [x] in both the checklist at :61-63 and the traceability table at :176-178) and for the 201-05 plan checkbox (:649). The remaining residual is the phase-level roll-up line, which Phases 198 and 200 carry as `[x] ... (completed DATE)`. Bookkeeping only; no implementation impact."
    evidence_status: "observed in .planning/ROADMAP.md:71 (still unchecked) vs :644-651 (all five plans checked) and .planning/REQUIREMENTS.md:59-64,174-179 (all six Complete)"
  - finding: "`.planning/STATE.md` `progress.completed_phases: 2` UNDER-counts relative to ROADMAP's own checkboxes, which mark Phases 198, 199, and 200 all `[x]`."
    category: other
    reason: "Pre-existing counter drift, not introduced by the closeout — the prior value was 1 against the same three checked phases, so the closeout correctly incremented an already-low baseline. Flagged because it errs toward understatement, not overstatement; nothing in the STATE close-out text overstates Phase 201."
    evidence_status: "observed in .planning/STATE.md frontmatter vs .planning/ROADMAP.md:68-71"
  - finding: "Untracked local e2e capture artifacts still contain the three removed provenance attributes: `examples/threadline_phoenix/e2e/artifacts/routes/route.timeline__dark-1280/dom.html:1913` and `route.timeline.degraded__dark-1280/dom.html:1913` carry `data-earned-flow=\"EF3\" data-jtbd=\"J6\" data-persona=\"P3\"`."
    category: other
    reason: "These are stale pre-removal DOM captures, untracked by git (`git ls-files --error-unmatch` errors on them) and not rendered output — no RENDER criterion governs them. Recorded because the prior pass phrased the grep result as 'zero occurrences in lib/ or the example app', which is exact only for tracked source. Re-capturing would clear them; nothing requires it."
    evidence_status: "observed by grep over lib/ and examples/; files confirmed untracked"
---

# Phase 201: Rendered Output Verification Report

**Phase Goal:** No internal vocabulary — phase numbers, decision IDs, JTBD taxonomy labels, provenance attributes, or CSS provenance comments — reaches a browser, achieved in two tiers separated by mechanical-floor blast radius, with element structure, layout, and visual appearance byte-for-byte unchanged.

**Verified:** 2026-09-22T00:05:50Z (refresh pass)
**Verification target:** committed HEAD `43c0672e7e81cf5ecce94f7ab745ab2fbfb3ad4e` (`ae7e75fa` plus the Phase 201 closeout commit `43c0672e`; the production delta is byte-identical to the prior target)
**Status:** passed
**Re-verification:** Refresh pass — the substantive findings below were established at `ae7e75fa` and are carried forward; see "Refresh Pass" immediately below for what changed, what was re-run, and what was carried.

Every number in this report was re-derived in this session. No SUMMARY claim was accepted on its own. Nothing was modified: no source, fixture, scorecard, capture, screenshot, or baseline changed, and no critic command ran. `git status` over `lib/`, `test/`, `examples/`, and `mix.exs` is clean after all measurements.

## Refresh Pass (2026-09-22T00:05:50Z)

This report was first written against `ae7e75fa` and reported `status: stale` shortly afterwards,
because three of its 33 `covered_files` were edited by the Phase 201 closeout commit `43c0672e`.
The staleness verdict was correct and mechanical, not substantive. This pass re-confirms the
reconciliation and re-seals the digest over current bytes.

**Nothing in the implementation moved.** `git diff ae7e75fa..HEAD -- lib/ test/ examples/ mix.exs`
is empty, verified first. `43c0672e` is `1078 A` + `4 M` by `--name-status`: the four modifications
are `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, and
`.planning/audits/201-rendered-output-evidence.md`; the 1078 additions are previously **untracked**
critic scorecards, verdict-cache entries, and `critic-report.html` being committed for the first
time — their on-disk bytes did not change, so no scorecard, capture, screenshot, or baseline moved.
`git status` over `lib/`, `test/`, `examples/`, and `mix.exs` is clean.

**The bookkeeping reconciliation is judged honest.** Each of the three edits was checked for
correctness, not merely for presence:

1. `ROADMAP.md:649` — `201-05-PLAN.md` flipped `[ ]` → `[x]`. Correct: `201-05-SUMMARY.md` exists and
   all five plan checkboxes are now `[x]`. (Residual: the phase-level roll-up at `ROADMAP.md:71` is
   still `[ ]` — advisory 3 below.)
2. `REQUIREMENTS.md` — RENDER-03/04/05 flipped `Pending` → `Complete` in both the checklist
   (`:61-63`) and the traceability table (`:176-178`). **Judged independently this pass, not
   inherited.** RENDER-03: `grep -cE 'Phase [0-9]|D-[0-9]{2}|milestone v[0-9]'` over
   `style.ex` returns `0`, and the guard scans the *emitted* `Style.css/1` output with a
   `/* Phase 202 */` positive control that must fire — re-run green here. RENDER-04:
   `mix verify.mechanical` re-run here is **28 tests, 0 failures**, and
   `git diff --stat fecfe684..HEAD -- test/fixtures/` is empty, so the scorecard set is provably the
   unmodified one. RENDER-05: nothing was regenerated — all ten baseline PNG SHA-256 values
   recomputed here match the sealed values digit-for-digit, the snapshot-directory diff over the
   phase window is empty, and the registry mechanism is non-vacuous (`validate_exception_registry/1`
   is exercised with seeded rejections for unknown node ID, delta mismatch, non-numeric measurement,
   empty rationale, invalid expiry, and a >3-entry cap). All three deserve `Complete`; **nothing was
   reverted.**
3. `audits/201-rendered-output-evidence.md` — "Verification addenda (2026-09-21)" appended. Both
   claims re-checked against source this pass and both hold exactly:
   `operator-screenshot-regression.spec.ts:77` is `test.skip(` with `!!process.env.CI` on the next
   line, and `mix.exs:186` is `cmd env CI=true mix verify.example_browser ...` — so the eight
   screenshot failures genuinely sit outside `mix ci.all`. `start_live.ex:222` is
   `<section class="tl-home__earned-flow" ...>`, styled at `style.ex:907` and `style.ex:4233` — and
   this is correctly judged a non-violation, because RENDER-06 requires class attributes stay
   byte-identical.

**`.planning/STATE.md` does not overstate.** Its Phase 201 close-out text matches this report
(passed, 6/6, the two carried facts), it explicitly records the open verification debt on Phases 199
and 200, and the reworked progress bar disambiguates itself as "28% of phases — 2 of 7 closed"
rather than claiming project-level completion. The one discrepancy runs the *other* way: it is
advisory 4 below, an under-count.

**Digest recomputed, not fabricated.** The refreshed `covered_digest` is
`v1:sha256:9ee00d5700029a9805e37a7bb89d4c0b7da32055b9368491730fc52be711bc43`,
produced by `gsd-tools query verification.fingerprint` over the current bytes of the same 33-file
covered set. As an integrity control, the same verb was run against a `git archive` of those 33
paths at `ae7e75fa` and reproduced the previously sealed
`v1:sha256:86d45010c30bb7c07c9b3fcdab6b7c8d30f5697b7701d65aa5abac9263a02449`
exactly — which proves the invocation is correct and that both the old and the new digest correspond
to real file bytes.

**Checks re-run in this pass** (all green): `mix test test/threadline/operator_surface/rendered_output_contract_test.exs`
(9/0); `mix verify.mechanical` (28/0); SHA-256 of all ten snapshot baselines (10/10 match the seal);
`git diff` over `test/fixtures/` and the snapshot directory (both empty); the three accepted
landed-blob attribution diffs (`--exit-code` 0); `git log --follow` on both renames (`R093` each);
the repo-wide dangling-reference grep for both old filenames and both old module names (zero hits);
`mix.exs:116` wiring; the `style.ex` provenance grep; and the repo-wide provenance-attribute grep.

**Checks carried forward from the `ae7e75fa` pass, not re-run**, because the implementation diff is
empty and re-running them could not produce new information: the full root suite (1660/0), the
example suite (116/0), Dialyzer (0 errors), `mix verify.format`, `mix verify.credo`, the Playwright
browser lane (82 passed / 8 failed), the structural-receipt comparison, and the 427-entry corpus
manifest check.

**Environment note.** An untracked `.tool-versions` containing only `nodejs 22.14.0` has appeared in
the working tree since the prior pass, so a bare `mix` now fails to resolve a version. This pass
pinned `ASDF_ELIXIR_VERSION=1.17.3-otp-27` / `ASDF_ERLANG_VERSION=27.3.4.15` per invocation —
matching both CI (`ci.yml` elixir 1.17.3 / OTP 27) and the existing `_build/test` compile artifact.
No file was modified to achieve this.

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP Success Criteria) | Status | Evidence |
|---|---|---|---|
| 1 | No operator page renders a phase number, decision ID, or internal taxonomy label in visible text; no rendered DOM carries a planning-provenance attribute; the emitted CSS contains no phase or milestone provenance comment. (RENDER-01, RENDER-02, RENDER-03) | ✓ VERIFIED | `grep -rIn 'data-jtbd\|data-persona\|data-earned-flow'` over the whole repo (excluding `.planning/`) returns only negative assertions in tests — zero occurrences in `lib/` or the example app. A broad token grep for `Phase N`, `milestone vN`, `D-NN`, `REQ-NN`, `DATA-NN`, `EFn`, `Pn`, `Jn` over `lib/threadline/operator_surface/` returns nothing outside source comments. `style.ex` contains zero `Phase`/`D-NN` occurrences. The behavioral guard `rendered_output_contract_test.exs` mounts six real routes and scans visible text of seven canonical nodes, all `StressFixtures` strings, and the rendered `Style.css/1` output: 9 tests, 0 failures, re-run in this session. |
| 2 | The attribute-only and comment-only removals pass `mix verify.mechanical` against an **unmodified** scorecard set. (RENDER-04) | ✓ VERIFIED | `mix verify.mechanical` re-run here: 28 tests, 0 failures. `git diff --stat fecfe684..HEAD -- test/fixtures/` is empty — no scorecard, ledger, golden set, or manifest entry changed during the phase. |
| 3 | Any text change that moved a measured value is absorbed by narrowing or by a registered, bounded exception entry — never by regenerating a capture. (RENDER-05) | ✓ VERIFIED | No measured value moved and no capture was regenerated: fixtures are byte-unchanged across the phase, the ten screenshot baselines hash exactly to the ten values sealed in the evidence file, and `git diff --exit-code` over the snapshot directory is clean. The exception registry holds zero entries, and the registry mechanism is non-vacuous — `validate_exception_registry/1` is exercised with seven positive controls (unknown node ID, delta mismatch, non-numeric measurement, empty rationale, invalid expiry, >3 entries) and rejects display-text identity. |
| 4 | No operator page's element structure, layout, or visual appearance changes — node count, tag, classes, and nesting stay byte-identical; only text content and non-visual attributes differ. (RENDER-06) | ✓ VERIFIED | The entire production delta over `fecfe684..HEAD` is 21 deletions in five LiveView modules and zero insertions; every deleted line is a `data-earned-flow`, `data-persona`, or `data-jtbd` attribute (line-level diff enumerated below). Post-edit canonical structural receipts for the seven canonical nodes equal the pre-edit receipts sealed before the edits, and the canonicalizer is proven mutation-sensitive against eight seeded structural mutations (tag change, added nesting, class change, id change, href, role, aria-label, phx-click). The browser lane independently re-run here is 82 passed / 8 failed with every behavior, accessibility, responsive, and overflow case passing. |
| 5 | The two residual root contract tests carry durable, history-preserving identities with no dangling references. (Plan 201-05 Tasks 1-2) | ✓ VERIFIED | `git log --follow --name-status` shows real renames: `R093 forward_only_gate_doc_contract_test.exs → critic_iteration_runbook_doc_contract_test.exs` at `c12f024d`, and `R093 phase06_nyquist_ci_contract_test.exs → ci_workflow_parity_contract_test.exs` at `dee6b824`. Modules are `Threadline.CriticIterationRunbookDocContractTest` and `Threadline.CIWorkflowParityContractTest`. `mix.exs:116` `verify.doc_contract` names the new path. A repo-wide grep for both old filenames and both old module names returns zero hits outside `.planning/`. |
| 6 | Phase 202 inherits a green, deterministic gate set. | ✓ VERIFIED | Re-run here: root suite 1660 tests / 0 failures / 1 excluded; example suite 116 / 0; Dialyzer `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`; `mix verify.format` exit 0; `mix verify.credo` no issues; `mix verify.mechanical` 28/0; rendered-output contract 9/0. All three accepted landed-blob attribution diffs exit 0. |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

### Production Delta (independently re-derived)

`git diff --stat fecfe684..HEAD -- lib/ examples/threadline_phoenix/lib/`:

```text
 lib/threadline/operator_surface/live/evidence_live.ex      | 3 ---
 lib/threadline/operator_surface/live/export_status_live.ex | 6 ------
 lib/threadline/operator_surface/live/row_history_live.ex   | 3 ---
 lib/threadline/operator_surface/live/start_live.ex         | 6 ------
 lib/threadline/operator_surface/live/timeline_live.ex      | 3 ---
 5 files changed, 21 deletions(-)
```

Every one of the 21 changed lines, deduplicated, is one of `data-persona="Pn"`, `data-jtbd="Jn"`, or `data-earned-flow="EFn"`. There are zero insertions. Claim 3 of the phase handoff is confirmed exactly.

`fecfe684` is the correct pre-delta baseline: it is the Plan 201-01 completion commit, and Plan 201-01 touched no LiveView module (it added the contract test, the evidence file, the shell-home spec rename, and a Playwright config edit). The substantial LiveView changes visible between `18fe87f5` and `fecfe684` belong to the Phase 200 closeout merge (#37) and Phase 199 UAT, not to Phase 201.

### Visual Gate Amendment — Honest Disposition or Laundering?

**Verdict: honest disposition.** Four independent lines of evidence support it, three of them re-measured in this session:

1. **Reproduced at HEAD.** `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium` over the six named specs, run here: **82 passed, 8 failed**. The eight failures are exactly the claimed set — `operator-screenshot-regression.spec.ts` cases `:108`, `:115`, `:136`, `:145`, each on desktop-chromium and mobile-chromium. Both Home screenshot cases pass. This matches the sealed evidence case-for-case.
2. **The delta cannot move a raster.** The only production change is the deletion of three `data-*` attributes. A repo-wide grep shows no CSS rule, no JS, and no Playwright locator references any of the three; the only surviving references are negative `refute has_element?` assertions in the LiveView tests. An attribute that no selector matches and no style consumes cannot alter rendered pixels.
3. **The baselines pre-date the phase by twenty phases.** The snapshot directory's last commit is `799c7d6e test(180-04)`, and `git diff --stat fecfe684..HEAD` over that directory is empty. The ten on-disk PNG SHA-256 values I computed match the ten sealed in the evidence file digit-for-digit. Nothing was regenerated.
4. **The failures were already registered as pre-existing debt before Phase 201 existed.** `.planning/WINDOWS.md` entries 8, 14, and 15 (all Phase 198) record these same screenshot-regression cases as open, unresolvable-without-regeneration deviations. Entry 62 adds the Phase 201 revert measurement rather than inventing the disposition.

The revert measurement the executor ran (five LiveView modules reverted to `fecfe684`, identical 8 fail / 2 pass) is therefore corroborated by, and consistent with, four facts I verified independently. It is a measurement pinning a pre-existing reality, not a waiver.

**Two non-obvious facts worth recording for Phase 202**, both confirmed here:

- These eight failures are **outside `mix ci.all`**. `operator-screenshot-regression.spec.ts:77` begins with `test.skip(!!process.env.CI, ...)`, and `ci.all`'s final step invokes the browser lane with `CI=true`. The screenshot guards are platform-local by design and predate this phase; `ci.all` exiting 0 and the local lane failing 8 are not in conflict.
- The plan's original verbatim command invoked `playwright test` directly, which boots no app server; the corrected invocation through `mix verify.example_browser` is required and is what I used.

### Guard Non-Vacuity

`test/threadline/operator_surface/rendered_output_contract_test.exs` (791 lines, 9 tests) fails closed and is positive-controlled. Read line by line:

| Guard | Fail-closed on empty/incomplete | Positive control |
|---|---|---|
| Owned static source inventory | `assert sources != []`, plus four explicit required paths (`start_live.ex`, `stress_live.ex`, `stress_fixtures.ex`, `style.ex`) and a sortedness assertion; derived from `git ls-files`, so a mis-globbed empty result fails | Attribute scan asserted clean only after the inventory is proven populated |
| Planning-vocabulary matcher | — | Seeded control string must produce **every one** of the nine offender kinds; a token-boundary control (`xPhase 201`, `EF3x`, `AP1`) must produce none |
| Planning-attribute matcher | — | Seeded HTML with all three attributes must yield exactly those three kinds with line and match populated; a clean `data-state` control must yield none |
| Seven-node render inventory | `validate_render_inventory(%{})` must return `{:error, {:unexpected_inventory, []}}`; a one-node deletion must be reported with the exact remaining ID set; `map_size == 7` and exact ID list asserted | For each of the three attributes, a seeded node must be rejected with the matching offender kind |
| Visible copy + CSS provenance | Inventory is the same seven real live-mounted renders | `scan_css_provenance("/* Phase 202 */")` must report `:phase`; a host-data control confirms adopter data is deliberately outside the boundary |
| Structural receipts | `Enum.all?(receipts, & &1.elements > 0)` and key-set equality with the sealed pre-edit map | Eight seeded structural mutations must each break canonical equality, while a copy-and-provenance-only variation must not |
| Reference corpus | `{:error, :empty_manifest}` on empty; `length(manifest) == 427` pinned; duplicate, path-set, and byte-hash mismatches each asserted with a distinct error and a seeded offender | Path-set equality is proven to be checked **before** byte hashes |

The render inventory is built from real `live/2` mounts of `/audit`, `/audit/exports` (two shapes), `/audit/evidence`, `/audit/rows/...`, and `/audit/timeline` — this is behavioral evidence, not presence checking. No guard can pass by having scanned nothing.

One honest scope note: the **visible-text** lane covers seven representative rendered nodes plus the full `StressFixtures` corpus, not every operator page. The gap is closed at source level — the repo-wide token grep over `lib/threadline/operator_surface/` is clean — so RENDER-01 holds by the union of the two, but the rendered lane alone is representative rather than exhaustive.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `test/threadline/operator_surface/rendered_output_contract_test.exs` | Fail-closed, positive-controlled rendered-output guard | ✓ VERIFIED | 791 lines, 9 tests, 0 failures; controls enumerated above |
| Five LiveView modules | Provenance-free rendered output | ✓ VERIFIED | 21 attribute lines deleted, no other change |
| Five LiveView test files | Negative assertions pinning removal | ✓ VERIFIED | `refute has_element?("[data-earned-flow]")` etc. present in all five; pass in the 1660-test run |
| `test/threadline/critic_iteration_runbook_doc_contract_test.exs` | History-preserving rename, wired into `verify.doc_contract` | ✓ VERIFIED | `R093` rename; `mix.exs:116` updated |
| `test/threadline/ci_workflow_parity_contract_test.exs` | History-preserving rename, ExUnit convention discovery | ✓ VERIFIED | `R093` rename; no consumer list to update |
| `.planning/audits/201-rendered-output-evidence.md` | Sealed, reproducible evidence | ✓ VERIFIED | Every reproducible figure in it re-derived here and matched |
| `.planning/WINDOWS.md` entry 62 | Registered deviation with measurement | ✓ VERIFIED | Present, dated, references the exact spec and cases; entries 8/14/15 establish the pre-existence |
| Snapshot baselines and `test/fixtures/` | Unmodified | ✓ VERIFIED | Ten hashes match the seal; `git diff` empty before and after my browser run |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `rendered_output_contract_test.exs` | Six real operator routes | `Phoenix.LiveViewTest.live/2` through a real router/endpoint | ✓ WIRED | Renders the actual surface, not fixtures |
| `rendered_output_contract_test.exs` | `Style.css/1` | `render_component/2` | ✓ WIRED | CSS provenance scanned on emitted output, not source |
| `rendered_output_contract_test.exs` | `test/fixtures/operator_surface/manifest.sha256` | Tracked-path derivation plus byte hashing | ✓ WIRED | 427 entries, one-to-one |
| `mix.exs` `verify.doc_contract` | `critic_iteration_runbook_doc_contract_test.exs` | Alias test list | ✓ WIRED | Renamed path present; old path absent everywhere |
| `mix.exs` `ci.all` | `verify.mechanical`, browser lane | Alias chain | ✓ WIRED | Mechanical runs before the browser lane, as documented |
| Live tests | Removed attributes | `refute has_element?/2` | ✓ WIRED | Recurrence is rejected at the five owning modules |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Render inventory | seven node HTML fragments | Live-mounted `/audit/*` routes against the test repo | Yes | ✓ FLOWING |
| CSS provenance scan | `css` | `render_component(&Style.css/1, [])` | Yes | ✓ FLOWING |
| Source inventory | `sources` | `git ls-files` over the operator surface | Yes | ✓ FLOWING |
| Corpus verification | manifest + tracked paths | On-disk `manifest.sha256` and Git index | Yes | ✓ FLOWING |
| Structural receipts | `elements`, normalized SHA-256 | LazyHTML tree of the live renders | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Rendered-output contract | `mix test test/threadline/operator_surface/rendered_output_contract_test.exs` | 9 tests, 0 failures | ✓ PASS |
| Mechanical floor on unmodified scorecards | `mix verify.mechanical` | 28 tests, 0 failures | ✓ PASS |
| Root suite | `mix test` | 1660 tests, 0 failures, 1 excluded | ✓ PASS |
| Example suite | `mix verify.example` | 116 tests, 0 failures | ✓ PASS |
| Dialyzer | `MIX_ENV=dev mix verify.dialyzer` | Total errors: 0, Skipped: 0, Unnecessary Skips: 0 | ✓ PASS |
| Formatting | `mix verify.format` | exit 0 | ✓ PASS |
| Credo | `mix verify.credo` | no issues (2 checks over 281 files — the known-narrow gate, unchanged by this phase) | ✓ PASS |
| Browser lane, six operator specs | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium tests/operator-earned-flows.spec.ts tests/operator-shell-home.spec.ts tests/operator-home-nav-mobile.spec.ts tests/operator-responsive-mobile-first.spec.ts tests/operator-accessibility.spec.ts tests/operator-screenshot-regression.spec.ts` | 82 passed, 8 failed — exactly the registered pre-existing screenshot set | ✓ PASS (against the amended exact non-regression gate) |
| Accepted landed-blob attribution ×3 | `git diff --exit-code` for `5752e357`/`1a5fbef2` → `18fe87f5` → HEAD | all exit 0 | ✓ PASS |
| Baseline immutability | `shasum -a 256` over the ten snapshot PNGs | all ten match the sealed values | ✓ PASS |

`mix ci.all` was not run end-to-end as a single command (its final step re-runs the full browser directory). Every one of its component lanes was run individually here and every one passed, which is strictly more informative than the aggregate exit code.

### Probe Execution

No Phase 201 plan declares a `probe-*.sh`, and no conventional `scripts/**/tests/probe-*.sh` exists in the repository. Not applicable.

### Requirements Coverage

| Requirement | Source plans | Verdict | Evidence |
|---|---|---|---|
| RENDER-01 — no phase number, decision ID, or internal taxonomy label in visible text | 01, 02, 03, 04, 05 | **Complete** | Rendered visible-text scan over seven live-mounted nodes plus all `StressFixtures` strings returns zero offenders under a nine-kind matcher with full positive controls; a repo-wide token grep over `lib/threadline/operator_surface/` is clean at source level. Tier-2 copy (`Primitives Matrix`, `Data States`, named stress cohorts) landed at `1a5fbef2` and is proven byte-identical through HEAD rather than replayed. |
| RENDER-02 — no rendered DOM carries planning-provenance attributes | 02, 03, 04, 05 | **Complete** | 21 attribute lines deleted across five LiveViews; zero occurrences of the three attributes remain anywhere in `lib/` or the example app; five LiveView test files hold `refute has_element?` guards; the render guard seeds each attribute as a positive control and rejects it. |
| RENDER-03 — emitted CSS contains no phase or milestone provenance comments | 01, 05 | **Complete** | `grep -cE "Phase\|D-[0-9]" lib/threadline/operator_surface/style.ex` returns 0; the guard scans the **emitted** `Style.css/1` output and its `/* Phase 202 */` positive control is detected. The removal itself landed at accepted blob `5752e357` and is proven unmodified through HEAD by a zero-exit diff. |
| RENDER-04 — removals proven not to move the mechanical floor, against an unmodified scorecard set | 01, 05 | **Complete** | `mix verify.mechanical` 28/0 re-run here, with `git diff --stat fecfe684..HEAD -- test/fixtures/` empty — the scorecard set is provably the unmodified one. |
| RENDER-05 — any moved measurement absorbed by narrowing or a registered bounded exception, never by regeneration | 01, 05 | **Complete** | Nothing was regenerated: fixtures byte-unchanged, ten baseline hashes identical to the seal, snapshot directory diff clean. Zero exception entries were needed. The registry is not a stub — it enforces stable node IDs, numeric before/after/delta consistency, non-empty rationale, ISO expiry, and a three-entry cap, each proven by a seeded rejection. |
| RENDER-06 — no element structure, layout, or visual appearance change | 01, 02, 03, 04, 05 | **Complete** | Attribute-only, insertion-free 21-line delta; post-edit canonical receipts equal the pre-edit seal for all seven nodes with a mutation-sensitive canonicalizer; 82 browser cases covering behavior, accessibility, responsive, and overflow pass; the eight screenshot failures are measured pre-existing and unchanged by the phase. |

No RENDER requirement is orphaned: the roadmap maps RENDER-01..06 to Phase 201 and the plans claim all six.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | None | — | A `TBD\|FIXME\|XXX\|TODO\|HACK\|PLACEHOLDER` scan across all 19 non-planning files changed in `fecfe684..HEAD` returns zero matches. |

No stub, empty implementation, disabled test, or debt marker was introduced. The guards added by this phase are the opposite of vacuous — they fail closed on empty input and carry seeded offenders.

### Advisory (Non-Blocking Observations)

1. **`tl-home__earned-flow` class token.** `start_live.ex:222` renders `class="tl-home__earned-flow"`, styled at `style.ex:907` and `style.ex:4233`. "Earned flow" is the same internal design taxonomy family as the removed `EFn` attribute values, and it does reach the browser. It is not a violation of any Phase 201 criterion as written — RENDER-01 governs visible text, RENDER-02 governs provenance attributes, and RENDER-06 explicitly requires class attributes to stay byte-identical, so renaming it inside this phase would breach the phase's own contract and disturb the mechanical and screenshot floors. Flagged rather than buried, for the maintainer to route to Phase 204 (Structure) or explicitly accept.
2. **Phase-numbered e2e spec filenames.** `operator-phase-135-uat.spec.ts`, `operator-phase-173-uat.spec.ts`, `operator-phase-175-uat.spec.ts`, and `operator-phase-178-uat.spec.ts` still encode phase chronology. Filenames are not rendered output and were outside the declared rename set; the root Elixir test tree is now clean of phase-numbered filenames.
3. **Closeout bookkeeping is mostly, not fully, reconciled.** The original form of this advisory is now closed: `ROADMAP.md:649` shows `201-05-PLAN.md` checked, and `REQUIREMENTS.md:59-64` plus traceability rows 174-179 mark all six RENDER requirements Complete. The residual is the **phase-level roll-up**: `ROADMAP.md:71` still reads `- [ ] **Phase 201: Rendered Output**`, where Phases 198 and 200 read `- [x] ... (completed DATE)`. Bookkeeping only, with no implementation impact, but it should be flipped before Phase 202 planning reads the roadmap as settled.
4. **Two in-window commits unrelated to rendered output.** `8c1cb0fe` and `597d7686` (idle-in-transaction reaping: `examples/threadline_phoenix/config/test.exs` and a new example contract test) landed inside the Phase 201 window but are test-infrastructure fixes outside the phase's success criteria. They are green in the example suite (116/0) and do not touch rendered output.

5. **`STATE.md` under-counts closed phases.** `progress.completed_phases: 2` against a ROADMAP that marks Phases 198, 199, and 200 all `[x]`. This is pre-existing counter drift — the prior value was `1` against the same three — and the closeout merely incremented the existing baseline. It errs toward understatement; nothing in the Phase 201 close-out text overstates.
6. **Stale untracked e2e capture artifacts still carry the removed attributes.** `examples/threadline_phoenix/e2e/artifacts/routes/route.timeline__dark-1280/dom.html:1913` and its `.degraded` sibling still contain `data-earned-flow="EF3" data-jtbd="J6" data-persona="P3"`. Both files are **untracked** (confirmed with `git ls-files --error-unmatch`) and are pre-removal DOM captures, not rendered output — no RENDER criterion governs them. Recorded only because the truth-1 evidence above phrases the grep as "zero occurrences in `lib/` or the example app", which is exact for tracked source; a re-capture would clear them, and nothing requires one.

### Human Verification Required

None. Every truth was settled by measurement in this session: real live renders, a real browser lane, real suite runs, and real hashes. The three advisories are maintainer scope decisions, not unverified behavior.

### Gaps Summary

No gaps. The phase goal is achieved and independently measured: the complete production delta of Phase 201 is 21 deleted provenance-attribute lines with zero insertions, leaving zero planning-provenance attributes, zero planning vocabulary in visible rendered text or emitted CSS, byte-identical canonical structure at the seven canonical nodes, byte-identical fixtures and screenshot baselines, a zero-entry exception registry, and green format, credo, root suite, example suite, Dialyzer, and mechanical lanes.

The one judgment call in the phase — amending the visual gate to an exact non-regression set rather than demanding a green lane — survives adversarial scrutiny. The eight screenshot failures are outside `ci.all` by a pre-existing `CI` skip, were registered as open deviations in Phase 198, compare against baselines last written in Phase 180-04, reproduce exactly at HEAD in my own run, and cannot be caused by deleting attributes that no selector or stylesheet references. That is a measured disposition, not a laundered regression.

---

_Verified: 2026-09-22T00:05:50Z (refresh pass over `43c0672e`; prior pass `ae7e75fa`)_
_Verifier: the agent (gsd-verifier)_
