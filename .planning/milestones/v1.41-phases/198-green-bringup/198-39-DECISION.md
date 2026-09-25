# 198-39 Decision: GREEN-07 / roadmap SC3 terminal disposition for milestone v1.41

**Status:** DECIDED — option-a (2026-08-30)
**Blocking task:** 198-39 Task 1 (`checkpoint:decision`, `gate="blocking-human"`)

## The problem

Phase 198's requirement **GREEN-07** and roadmap **success criterion 3** have now failed five
consecutive measured CI rounds for the same two reasons, and neither reason is a defect this
phase can fix:

1. `CI required` concluded `failure` on measured run `33336651956` (round 5, `ci/198-round5`,
   PR #32, `attempt: 1`).
2. Exactly 2 of `CI required`'s 12 `needs:` members were red on that run:
   `verify-capture` (`Tier A capture lane (byte-stable evidence)`) and
   `verify-example-browser` (`Example app browser E2E (Playwright)`, 3 `operator-stress.spec.ts`
   ledger-baseline rows: `page.home.happy`, `page.timeline.empty`,
   `footgun.transaction-page-left-push-desktop`).
3. Both are red **by construction** under standing decision **D-39**, which forbids their only
   mechanical remedy — Tier-A `page.*` baseline regeneration — for the whole of milestone v1.41.

Round 5's verifier (`198-VERIFICATION.md`) routed this explicitly to human verification as a
milestone-level scope decision outside Phase 198's own authority. No option considered below
marks GREEN-07 Complete: no measured run has concluded `success`, and D-01 admits no substitute
for a measured conclusion.

## Options presented, with consequences

| Option | Description | Consequence |
|---|---|---|
| **(a) Accept GREEN-07 as permanently Pending for v1.41.** | Both D-39-forced lanes are named in the record along with each lane's unblock condition. | Phase 198 closes with 11 of 12 requirements Complete and SC3 failed-with-cause; `CI required` keeps asserting exactly what it asserts today; every future merged PR still proves byte-stable Tier A evidence; `origin/main` stays behind until some milestone authorizes regeneration. Nothing weakened, nothing overclaimed. |
| **(b) Defer GREEN-07 to a named later milestone.** | Same immediate posture as (a), but the requirement moves rather than being accepted in place, acquiring a named target milestone and a named owner in `deferred-items.md`, and v1.41's success criteria are restated to exclude it. | The record shows a moved goalpost rather than an accepted miss — more honest if the work is genuinely planned, less honest if it is not. A target milestone name is required; a deferral without one is option (a) wearing a different label and is refused as such. |
| **(c) Authorize a scoped exception to D-39** for a named, bounded set of baselines. | This plan records the authorization and its exact scope; it never performs a regeneration. | Regeneration makes the lane green by changing the evidence rather than fixing the cause, so the `scroll_cost` coupling diagnosed in 198-16 (a document-wide `scrollHeight` read tied to the stress-lab catalog size) is papered over and the next catalog change re-reds the lane. The regeneration itself would be planned separately with its own before-and-after evidence. |

## The maintainer's verbatim selection

> option-a

The maintainer selected option (a) exactly, with no modification, no additional conditions, and
no target milestone named. Option (b) was explicitly not chosen — no target milestone was
supplied, so (b)'s required-named-target gate is unmet by construction, confirming this is a
genuine (a) selection and not (b) wearing a different label.

**GREEN-07 and roadmap SC3 are accepted as permanently Pending for milestone v1.41.**

Both D-39-forced red lanes and their unblock conditions, as named at the checkpoint:

- **`verify-capture`** (Tier A capture lane, byte-stable evidence) — unblocks in a milestone
  where Tier-A `page.*` scorecard regeneration is authorized AND the `scroll_cost` coupling
  diagnosed in 198-16 (a document-wide `scrollHeight` read tied to the stress-lab catalog size)
  is addressed.
- **`verify-example-browser`** (`Example app browser E2E (Playwright)`) — unblocks under the same
  authorization, scoped to the three named `operator-stress.spec.ts` ledger baseline rows:
  `page.home.happy`, `page.timeline.empty`, `footgun.transaction-page-left-push-desktop`.

**Decided by:** maintainer, 2026-08-30 (recorded by the phase-198 orchestrator at the
`gate="blocking-human"` checkpoint for 198-39 Task 1).

## What changes as a result

- `.planning/REQUIREMENTS.md` — GREEN-07's status line and Phase 198 mapping-table row extended
  with the accepted-Pending disposition, citing this decision; GREEN-08's row extended with the
  same citation so its unmet second clause (PR #26 BLOCKED) points at the decision that now owns
  it. GREEN-07's checkbox stays unchecked and its status stays `Pending`; the round-5 measured
  evidence (run `33336651956`) is preserved, not overwritten.
- `.planning/ROADMAP.md` — Phase 198 success criterion 3 annotated with the accepted-Pending
  disposition and this decision's citation. The criterion is not deleted and not restated as met.
- `.planning/phases/198-green-bringup/deferred-items.md` — new `## Round 6 — GREEN-07 milestone
  disposition` entry naming the owner (the v1.41 milestone record itself) and the per-lane
  unblock condition for both `verify-capture` and `verify-example-browser`.
- `.planning/STATE.md` — current-position block and deferred-items table updated to match.

No gate, workflow file, ruleset, `CONTRIBUTING.md`, `playwright.config.ts`, scorecard, or `*.png`
is touched by this decision or its propagation.

---

## Branch and pull-request disposition (Task 3)

This section separates the phase goal's two clauses, which have different owners:

- **GREEN-06** (every local commit exists and is reachable) is **Complete** and unaffected by
  this decision.
- The unmet part of the goal sentence — that `origin/main` has **received** those commits — is
  downstream of `CI required`'s `failure` conclusion, and therefore downstream of the option-a
  disposition recorded above. It is not an independent defect.

### Live-measured figures (2026-08-30T22:50:23Z)

- `git rev-list --count origin/main..HEAD` → **202** commits, measured live at the timestamp
  above. Round 5's `198-VERIFICATION.md` recorded **186** commits at its measurement time
  (2026-08-30, round-5 close). The two figures are reported side by side rather than letting the
  newer replace the older: **186 (round 5, 2026-08-30 close) vs. 202 (2026-08-30T22:50:23Z,
  this plan)** — the growth reflects plans 198-38 and 198-39's own commits landing on `main`
  after round 5's PR #32 was opened, not a correction of the round-5 figure.
- `gh pr view 32 --json number,state,isDraft,mergeStateStatus` (command shown, run live):
  ```
  {"isDraft":true,"mergeStateStatus":"BLOCKED","number":32,"state":"OPEN"}
  ```
- `gh pr view 26 --json number,state,isDraft,mergeStateStatus` (command shown, run live):
  ```
  {"isDraft":false,"mergeStateStatus":"BLOCKED","number":26,"state":"OPEN"}
  ```

### PR #32 (`ci/198-round5`)

A draft measurement vehicle, never a merge request (title carries DO NOT MERGE). Its
`mergeStateStatus: BLOCKED` is a direct consequence of `CI required`'s red aggregate, which is
now dispositioned as accepted-Pending under option (a) — it is not expected to become mergeable
by any act of this plan.

**Disposition: left open** as the round-5 evidence anchor (measured run `33336651956` is cited
against it project-wide) until plan 198-40 opens its own round-6 measurement branch. The two are
not to be confused: 198-40 owns opening the round-6 measurement branch and its own blocking
push checkpoint; this plan performs no push and does not open or close either branch.

### PR #26 (release-please)

Its `mergeStateStatus: BLOCKED` is a consequence of `CI required`'s red aggregate — a
downstream effect, not an independent branch-protection defect. Under option (a), selected
above, **PR #26 stays blocked**, with the cited reason being exactly GREEN-07's accepted-Pending
disposition: `CI required` will keep concluding `failure` while `verify-capture` and
`verify-example-browser` remain red by construction under D-39, and branch protection requires
that single `CI required` context to succeed before any PR — including #26 — can merge.

PR #26 is **not** force-merged and **not** unblocked by relaxing branch protection. It unblocks
only if a future milestone authorizes the Tier-A regeneration D-39 currently forbids and a
subsequent measured run concludes `CI required: success`.

### The `origin/main` gap

**202 commits** (measured 2026-08-30T22:50:23Z), all reachable from local `HEAD` (GREEN-06,
Complete). **Cause:** no push has occurred since round 5's PR #32 was opened, and no push closes
this gap while `CI required`'s aggregate is red under branch protection requiring that single
context. This is not resolved by pushing — it is resolved by whichever future milestone
authorizes the regeneration option (a) accepts as out of scope for v1.41.

### Explicit refusals, in writing

This plan performs **no `git push`**, **no merge**, and **no branch-protection change**.
`git push` is a human-authorized gate in this project; plan 198-40 owns the staged push and its
own blocking checkpoint. Editing `.github/rulesets/main.json` (or any branch-protection setting)
to unblock PR #26 or PR #32 is explicitly refused here, in writing, per D-42 — the guarantee
behind the gate is not narrowed to make a requirement's disposition look better than it is.
</content>
