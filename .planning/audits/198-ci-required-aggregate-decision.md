# `CI required` aggregate — decision brief: two structurally-red lanes

**Phase:** 198-green-bringup, plan 198-20 (Task 1)
**Requirement:** GREEN-07
**Origin:** `198-VERIFICATION.md` round 2, "What Round 3 must do", item 4 — a maintainer
decision this phase cannot resolve by further engineering.
**Purpose:** enumerate every available disposition for the two lanes below, with the
honest consequence of each stated as: what `CI required` would still guarantee, what it
would stop guaranteeing, whether GREEN-07 can close under it (and whether that closure
is genuine or definitional), and a reversibility rating. **No recommendation, ranking,
or default is given anywhere in this document.** The maintainer's answer is recorded
separately, in Task 2, and then in `198-CONTEXT.md` as locked decisions (Task 3).

This document does not re-open the Tier-A `page.*` regeneration prohibition (maintainer-
ratified twice, most recently 2026-08-28) beyond listing it as an already-refused option,
and does not re-open GREEN-07's wording.

---

## Load-bearing facts, common to both lanes

- **`ci-required`'s `needs:` list is the sole extension/contraction point.** `.github/workflows/ci.yml:1-6`
  states this explicitly: a job becomes blocking by being added to `needs:`, "with zero
  branch-protection edits." The inverse holds identically: a job stops blocking by being
  removed from `needs:`, also with zero branch-protection edits.
- **`.github/rulesets/main.json` names exactly one required context: `"CI required"`.**
  The `required_status_checks.parameters.required_status_checks` array in that file
  contains a single entry, `{ "context": "CI required" }`. **A `needs:` change therefore
  requires no ruleset edit of any kind** — the protection contract stays byte-identical
  whether `needs:` lists ten jobs or two. This is the precise mechanism by which a
  narrowing of the gate's guarantee can be invisible at the protection layer: the file a
  reviewer would check for "did branch protection change?" shows no diff either way.
- **`re-actors/alls-green@release/v1` semantics (D-09), the hard constraint on every option below:**
  `ci-required` runs `if: always()` specifically so a `needs:`-failed dependency does not
  get silently scored as skipped-and-therefore-passing. Two distinct states exist and this
  brief keeps them named separately for every option:
  - A `needs:` member that is present but becomes **conditionally skipped** (a job-level
    `if:`) is scored a **failure** by `alls-green` unless it is explicitly named in
    `allowed-skips`. `ci.yml`'s own comment at the `ci-required` job states `allowed-skips`
    is "deliberately absent today."
  - A `needs:` member that is **removed from the list entirely** is simply not asserted —
    `alls-green` never inspects its result at all, because `jobs: ${{ toJSON(needs) }}`
    only contains what `needs:` names.
  - These are one character of YAML apart (an entry present-with-`if:` vs. an entry
    absent) and materially different: the first still requires a maintenance decision
    every time it runs (list it in `allowed-skips` or the gate fails); the second requires
    none, because the gate has no memory of the removed lane at all.
- **D-23's honesty obligation attaches to every option that reduces coverage,** not just
  to the browser-lane split D-23 was originally written for: the `## CI Coverage` table in
  `CONTRIBUTING.md` must state the new reality, and
  `test/threadline/ci_coverage_doc_contract_test.exs` (or an equivalent derive-from-source
  guard) must make that statement non-vacuous rather than trust-based. Any option below
  that removes a lane from `needs:` inherits this obligation as an implementation
  requirement for plan 198-21, not as something this brief performs.
- **This decision does not itself change the ruleset file.** Whichever way the maintainer
  answers, `.github/rulesets/main.json` is expected to stay byte-identical — the change,
  if any, lands entirely in `ci.yml`'s `needs:` list, `CONTRIBUTING.md`'s coverage table,
  and a doc-contract test. This is the precise reason the decision needs a human and a
  written record rather than a quiet YAML edit: nothing downstream will flag it
  automatically.

---

## Lane A — `verify-capture` / **"Tier A capture lane (byte-stable evidence)"**

**Measured facts (no new analysis; from `198-tier-a-byte-stability.md` and
`198-VERIFICATION.md` round 2):**

- Cause fully diagnosed (198-16): `scroll_cost`'s numerator is a document-wide
  `document.documentElement.scrollHeight` read on `/audit/__stress`, not the
  product-content-scoped read every sibling field uses. 98.5% of the measured document
  height is the harness's own unvirtualized story-catalog sidebar (currently 981 registered
  stories), not the captured cell's content. As the sidebar grows, the metric drifts —
  independent of any actual product change.
- Reproduced twice locally, byte-identical both times — run-to-run flakiness and a CI-only
  environmental cause are both ruled out with direct evidence.
- Confirmed still red on the measured CI run `33197493051` (round 2), "exactly as 198-16
  diagnosed and predicted."
- **Every available remedy requires Tier A `page.*` scorecard regeneration** (198-16 §6):
  either regenerate the currently-drifted values as-is (blast radius: 198 scorecards, not
  durable — will drift again as the catalog grows), or rescope `scroll_cost` to
  `preview.offsetHeight`/`window.innerHeight` and regenerate the full 366-cell set plus
  re-seed `mechanical_floors["scroll_cost"]` (durable, larger blast radius).
- The Tier-A `page.*` regeneration prohibition was **re-ratified by the maintainer this
  session** (2026-08-28), after 198-16 explicitly asked. This is a milestone-level policy
  decision, not a Phase 198 engineering one, and this brief does not re-open it.

**Dispositions:**

### A1 — Keep `verify-capture` in `ci-required`'s `needs:`

- **What `CI required` would still guarantee:** every pull request that merges has
  byte-stable Tier A evidence proven fresh on that PR — the gate's Tier-A guarantee is
  unchanged from what it has always meant.
- **What it would stop guaranteeing:** nothing — this option changes no guarantee.
- **GREEN-07 consequence:** GREEN-07 stays open, indefinitely, for as long as the
  regeneration prohibition stands — not because of an unfixed defect in the ordinary
  sense, but because the phase has no authority to lift a milestone-level policy. Closure
  under this option is not available; it is simply deferred to whenever the prohibition
  lifts.
- **Reversibility:** **reversible.** Nothing is removed or weakened; switching to A2 or A3
  later costs only a subsequent `needs:` edit (plus the honesty-mechanism work A2 would
  require).

### A2 — Remove `verify-capture` from `needs:`; job continues to run and report

- **What `CI required` would still guarantee:** every other lane's guarantee is unchanged;
  the `verify-capture` job itself keeps running on every PR and its pass/fail status
  remains visible in the PR checks list — the signal is not deleted, only made
  non-blocking.
- **What it would stop guaranteeing:** a green pull request no longer proves Tier-A
  byte-stable evidence. A PR can merge while `verify-capture` is red. Nothing catches this
  at the branch-protection layer — `.github/rulesets/main.json` stays byte-identical
  either way, so this reduction is legible only in `CONTRIBUTING.md`'s `## CI Coverage`
  table and whatever contract test asserts that table's accuracy (D-23's honesty
  mechanism, per the common facts above).
  Mechanism used: **removal from `needs:`, not a conditional skip** — the job runs
  unconditionally, so `allowed-skips` never enters into it; the lane is simply not
  asserted by the aggregate.
- **GREEN-07 consequence:** GREEN-07 **can close** under this option, but the closure is
  **definitional, not genuine** — `CI required` reaches `success` because it was told to
  stop checking this lane, not because the lane turned green. The underlying `scroll_cost`
  drift is unchanged; only the gate's scope shrank.
- **Reversibility:** **one-way.** Re-adding the lane later does not restore what was true
  in the interim: every PR merged while it was non-blocking merged without the Tier-A
  proof the gate used to require, and that history cannot be retroactively re-verified.
  The published guarantee for that window is permanently weaker than the guarantee before
  or after.

### A3 — Lift the Tier-A `page.*` regeneration prohibition (already refused twice)

- **What `CI required` would still guarantee:** if this were done, followed by an actual
  regeneration and fix, the gate would keep its full Tier-A guarantee, on the lane's
  actual engineering merits rather than by scope reduction.
- **What it would stop guaranteeing:** nothing, if the regeneration is done correctly —
  but this option is listed **only so the option set is complete**, not as a live
  candidate. It has been **explicitly refused by the maintainer twice, most recently this
  session (2026-08-28)**. Selecting it re-opens a settled milestone policy that this brief
  is instructed not to re-litigate.
- **GREEN-07 consequence:** would allow genuine closure, in principle — moot, given the
  policy is settled against it.
- **Reversibility:** not applicable here — this option is not a live choice in this brief;
  it is recorded for completeness only.

---

## Lane B — `verify-example-browser` / **"Example app browser E2E (Playwright)"**

**Measured facts (no new analysis; from `198-example-browser-e2e.md`,
`deferred-items.md` Plan 198-17 entry, and `198-VERIFICATION.md` round 2):**

- 198-17 diagnosed and fixed the 5 failures observed on CI run `33183920952` (two
  Playwright specs asserting a `"selected schema"` literal that commit `842bd737` /
  197-02 intentionally removed from the product a day before that CI run) — with a
  red-then-green teeth proof for each. Confirmed **held** on the later measured run
  `33197493051`: "Two of 198-17's five diagnosed Playwright failures... confirmed fixed
  and held on the measured CI run."
- Fixing those 5 did not turn the lane green. Running the plan's own full local verify
  command (`mix verify.example_browser --project=desktop-chromium
  --project=mobile-chromium`, unbounded locally — the PR-lane project set) surfaced **28
  additional, pre-existing failures across 14 unrelated test files**
  (`operator-find-mobile.spec.ts`, `operator-phase-135/173/175/177-uat.spec.ts`,
  `operator-screenshot-regression.spec.ts`, `operator-screenshots.spec.ts`,
  `register.spec.ts`), none touching either file 198-17 modified.
- These 28 were never visible in CI because `playwright.config.ts:141`'s
  `maxFailures: process.env.CI ? 5 : 0` always aborted the run at the first 5 failures —
  which, before 198-17, were always the two now-fixed specs. Fixing the diagnosed cause
  revealed the next layer of pre-existing red underneath it, rather than turning the lane
  green.
- Logged as `deferred-items.md` Plan 198-17 entry and `WINDOWS.md` #8, explicitly
  deliberately deferred by maintainer decision this session, needing "a follow-up 198 (or
  successor-phase) gap-closure plan to diagnose and fix in the same disciplined,
  no-weakening manner" 198-17 used.
- Confirmed still red on the measured CI run `33197493051` — "5/305/50, exactly the known
  28-failure-set members, exactly as 198-17 predicted."

**Dispositions:**

### B1 — Fix the 28 masked failures in a dedicated successor round

- **What `CI required` would still guarantee:** the lane's full guarantee is preserved and
  strengthened — a green PR proves the example app's interactive Chromium flows pass, with
  no reduction in what is asserted, in the same red-then-green, no-weakening manner 198-17
  demonstrated.
- **What it would stop guaranteeing:** nothing — this option changes no guarantee, it only
  delays when the guarantee is restored to green.
- **GREEN-07 consequence:** GREEN-07 stays open until the successor plan lands and is
  confirmed on a real measured CI run — closure under this option, once reached, is
  genuine (the lane is actually green, not scoped out).
- **Reversibility:** **reversible** in the sense that nothing is given up in the meantime;
  the cost is calendar time and a dedicated diagnosis round (28 unrelated failures exceed
  a single executor's context budget per 198-17's own next-phase-readiness note), not a
  weakened guarantee.

### B2 — Keep `verify-example-browser` in `needs:`; accept GREEN-07 stays open

- **What `CI required` would still guarantee:** identical to B1's guarantee today — the
  gate keeps demanding the full lane pass, and a red lane keeps blocking merges, so no
  latent regression can slip in silently through this lane while the 28 failures remain
  undiagnosed.
- **What it would stop guaranteeing:** nothing — this is the same as A1's structural
  position, applied to Lane B: no guarantee changes, only the closure timeline is
  undetermined (it depends on when a diagnosis round, if any, is scheduled).
- **GREEN-07 consequence:** GREEN-07 stays open indefinitely — the debt stays visible as a
  red required gate rather than being scoped out or fixed. Distinct from B1 only in that
  B2 makes no commitment to when or whether a fix round happens; B1 is B2's disposition
  plus a scheduling commitment.
- **Reversibility:** **reversible** — identical reasoning to A1: nothing removed or
  weakened.

### B3 — Remove `verify-example-browser` from `needs:`; job continues to run and report

- **What `CI required` would still guarantee:** every other lane's guarantee is unchanged;
  the job keeps running on every PR and its status stays visible — the browser signal is
  not deleted, only made non-blocking.
- **What it would stop guaranteeing:** a green pull request no longer proves the example
  app's interactive Chromium flows pass. This directly **contradicts D-17's explicit
  commitment** that the PR-lane browser job "stays inside `CI required` and votes" — D-17
  is on record as designing the split specifically so the reduced PR lane would remain
  required. Selecting B3 would require restating D-17, which this brief flags as a
  consequence rather than performing.
  Mechanism used: **removal from `needs:`, not a conditional skip** — same mechanism as
  A2, same consequence: nothing to register in `allowed-skips`, the lane is simply
  unasserted.
- **GREEN-07 consequence:** GREEN-07 **can close** under this option, but — identically to
  A2 — the closure is **definitional, not genuine**: the 28 failures remain unfixed, only
  unasserted by the gate.
- **Reversibility:** **one-way.** Same reasoning as A2: PRs merged while the lane is
  non-blocking merged without the browser-flow proof the gate used to require, and that
  window cannot be retroactively re-verified once the lane is re-added.

---

## Appendix: newly measured third structurally-red lane (orchestrator input, 2026-08-28)

*(This is an appendix, not a third lane section — the "exactly two lane sections"
acceptance criterion for this brief's main body still holds. This section is
clearly-labelled and separated to keep that boundary unambiguous.)*

**Measured facts, reported to this executor as orchestrator input and recorded here
without independent re-verification by this plan (this plan's Task 1 does not run CI or
`mix verify.example` itself; that would be out of scope for a documents-only task):**

- Plan 198-19 landed the `ALTER DATABASE threadline_phoenix_test SET search_path TO ...`
  fix in `verify-test`'s `current` lane. It works: `mix verify.example` now produces
  **zero** `undefined_table` occurrences, measured on the merged main tree at commit
  `0c8304ae`. GREEN-04's *named* cause (the `ci.yml:235-240` search_path gap) is genuinely
  closed.
- However, `mix verify.example` still **exits 1** with **8 failures / 109 tests**:
  14 hits in `test/threadline_phoenix/demo_contract_test.exs`, 5 in
  `test/threadline_phoenix_web/walkthrough_happy_path_test.exs`, 3 in
  `test/threadline_phoenix_web/walkthrough_evidence_test.exs` — all demo-seed content
  mismatches, pre-existing and deferred since Phase 177 (see `deferred-items.md`, Plan
  198-12 entry, which already logs "the recurring 'example precommit demo-seed/walkthrough
  failures' pattern already acknowledged & deferred across Phases 177, 179, 180, and
  182").
- **`.github/workflows/ci.yml:251` runs `mix verify.example` with `if: matrix.lane ==
  'current'` INSIDE the `verify-test` job** — the very job that emits the required check
  `Run test suite (current)`.
- **Consequence, stated plainly:** `Run test suite (current)` will conclude **FAILURE**
  on plan 198-22's measured CI run, so GREEN-04 cannot close on that run, and `CI
  required` cannot conclude `success` regardless of how the maintainer disposes of Lanes A
  and B above. This is a third, independent blocker to the same aggregate outcome.

**Dispositions, in the same four-field format used above:**

### C1 — Fix the 8 demo-seed failures in a dedicated successor round

- **What `CI required` would still guarantee:** the `verify-test` (`current`) job's full
  guarantee is preserved and strengthened — a green PR proves both the root-repo test
  suite and the example app's demo-seed/walkthrough content are consistent, with no
  reduction in scope.
- **What it would stop guaranteeing:** nothing — this option changes no guarantee, only
  delays when green is reached, in the same manner as B1.
- **GREEN-04/GREEN-07 consequence:** GREEN-04 cannot be marked Complete and GREEN-07
  cannot close until this lands and is confirmed on a real measured CI run — genuine
  closure once reached, since nothing is scoped out.
- **Reversibility:** **reversible** — nothing given up in the meantime, cost is a
  dedicated diagnosis/fix round for demo-seed content, a debt that predates this phase by
  four phases (177/179/180/182) per `deferred-items.md`.

### C2 — Keep as-is; accept GREEN-04 stays open (and therefore GREEN-07 stays open)

- **What `CI required` would still guarantee:** identical to today's actual guarantee —
  the gate keeps demanding `mix verify.example` pass inside `verify-test`, and a red
  result keeps blocking merges on the `current` lane, so this specific debt cannot slip in
  silently.
- **What it would stop guaranteeing:** nothing — no guarantee changes, only the closure
  timeline stays undetermined, exactly as B2 above.
- **GREEN-04/GREEN-07 consequence:** both requirements stay open indefinitely, alongside
  whatever Lane A/B answers the maintainer gives — this is a genuinely independent
  blocker, not resolved by any combination of A/B answers.
- **Reversibility:** **reversible** — same reasoning as A1/B2.

### C3 — Move `mix verify.example` out of the `verify-test` job so the check name it feeds is narrowed

- **What `CI required` would still guarantee:** the root-repo `mix test` guarantee behind
  `Run test suite (current)` stays intact and would go green on its own merits (it already
  is: 1412/0 confirmed locally per `198-CI-MEASUREMENT.md`, and `verify-test`'s only
  remaining measured cause — the search_path gap — is now fixed per plan 198-19). Every
  other lane's guarantee is unchanged.
- **What it would stop guaranteeing:** `Run test suite (current)`, as a check name, would
  no longer imply the example app's demo-seed content is consistent — that guarantee would
  either move to a separately-named, separately-required job (preserving it, at the cost
  of a new `needs:` entry and a new named check), or move to a non-required job (losing
  it from the gate, exactly like A2/B3's shrinkage, with the identical invisible-at-the-
  ruleset-layer property: `.github/rulesets/main.json` stays byte-identical because it
  only names the aggregate `CI required`, never the individual job). Which of these two
  sub-shapes is chosen changes whether this option is a genuine restructuring or a scope
  reduction wearing a restructuring's clothes — this brief does not choose between them.
  Mechanism, if the non-required sub-shape is chosen: **removal from `needs:`**, same
  as A2/B3's mechanism — the lane's `mix verify.example` step is simply not part of any
  `needs:`-tracked job's success condition once moved out.
- **GREEN-04/GREEN-07 consequence:** GREEN-04, read narrowly as "`mix test` passes with no
  deterministically-failing tests" (its own literal wording, which does not name the
  example app), could close under the required-elsewhere sub-shape once the new job is
  green, or under the non-required sub-shape immediately — but the latter closure is
  **definitional, not genuine**, in the identical sense as A2/B3: the underlying 8
  failures remain unfixed, only unasserted by the gate that used to check them. GREEN-07
  is unblocked by this specific cause either way `mix verify.example`'s new status is
  wired, but only genuinely so if the new location is itself required and green.
- **Reversibility:** **one-way** if the non-required sub-shape is chosen (identical
  reasoning to A2/B3 — PRs merged while the demo-seed content check is non-blocking merged
  without a proof that later cannot be retroactively supplied); **reversible** if the
  required-elsewhere sub-shape is chosen (moving the check back costs only a subsequent
  workflow edit, no guarantee window is lost).

**No recommendation is made among C1/C2/C3, nor between C3's two sub-shapes.**

---

## Cross-cutting note: independence and ordering (per this plan's must-haves)

The Lane A, Lane B, and Appendix Lane C decisions are **three independent questions** and
may be answered differently — nothing about A's answer constrains B's or C's, or vice
versa. Whatever combination the maintainer chooses, the implementing plan (198-21) must
apply all resulting `needs:` / `CONTRIBUTING.md` / contract-test changes **in a single
diff**, so no intermediate commit ever publishes a `CI required` state that asserts a
guarantee nobody actually chose (e.g., a half-applied removal that drops a lane from
`needs:` before the corresponding `CONTRIBUTING.md` row and contract test exist).

The **empty-edge reading is stated explicitly, as this plan's must-haves require**: an
aggregate whose `needs:` list is reduced toward nothing asserts correspondingly less — the
degenerate case, an aggregate that needs nothing, would assert nothing at all and would
trivially always conclude `success`. No option enumerated above approaches that degenerate
case (each proposes removing at most one lane from a twelve-entry list, not collapsing the
list), but the reading is named here so no future reader mistakes "smaller `needs:`" for
"free" — every one-lane reduction proposed above (A2, B3, C3's non-required sub-shape) is
priced, per-option, above.

---

*No option in this document is marked preferred, recommended, or default. The maintainer's
answers to Lane A, Lane B, and Appendix Lane C are recorded in Task 2 of plan 198-20 and,
once given, as numbered locked decisions in `198-CONTEXT.md` (Task 3).*
