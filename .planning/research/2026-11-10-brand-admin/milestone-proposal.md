# Proposed v1.48 milestone: Threadline Admin brand and complete journeys

Status: researched proposal for one milestone-scope confirmation; targeted independent adversarial follow-up passed. This is not the
official REQUIREMENTS.md or ROADMAP.md, and no new milestone or phase is initialized.
The maintainer has authorized starting a new UI milestone and applying clear
research recommendations; the remaining decision changes the existing queue.

## Recommended order

Start the requested UI milestone now as **v1.48 Threadline Admin: brand and complete
journeys**. The maintainer has brought new UI direction, so the old provisional
queue is re-ranked rather than treated as an immutable schedule. Keep the broader
Safe by default candidate and remaining specs/performance/dependency-tree work
tracked separately; settle their future planning labels when the arc is updated.
No old safety/correctness requirement is closed by a new UI test.

The direct UI dependency is the already-approved fail-closed mount fix. Deliver
that narrow contract before mounted-route acceptance of the refreshed Admin.
Brand, catalog and scenario scoping work can proceed without first completing
unrelated transaction-ID, SQL, support-floor or other foundation changes.

Current-main advisories and the scheduled broken-suite finding still matter:
**the milestone baseline phase owns #61 and #90 triage and a named fix/disposition
ledger.** The orchestrator assigns any concrete remediation to that phase's owning
executor and retains the findings through verification and release readiness.
Unresolved runtime advisories or an untrustworthy required proof block acceptance
of the affected route/phase and public release. A passing historical run, an
`accepted-risk` label, or approval of this scope does not waive them.

Apply bounded compatible remedies where possible; do not smuggle a full foundation
rewrite into the UI milestone. If a remedy requires a new compatibility policy or
larger foundation capability, stop the affected acceptance/release path, explain
its concrete consequence and seek the consequential decision. Only the maintainer
can accept a specifically explained residual risk; silence, indifference and a
general milestone approval do not count. Keep supported independent work moving.

The initial research inputs preferred the whole foundation milestone first. The
[independent adversarial pass](milestone-adversarial-review.md) identified that as
priority advice rather than a technical dependency. This final synthesis follows
the explicit UI intent with narrow, enforceable safety gates.

## Current baseline and limits

- Live main still matches `d35b9422`, package 1.1.0; v1.47 is closed after Phase
  247.1. Hex agrees on 1.1.0. The last required exact-main CI run passed.
- More recent scheduled runs are not all green: dependency-health issue #61 lists
  Ecto, Phoenix.HTML and example Bandit advisories, and issue #90 classifies the
  repeat-suite failure on main as broken on the first iteration. Those reports
  require diagnosis; the classifier alone does not prove every cause or remedy.
- The sole open PR observed is the grouped GitHub Actions update. It remains
  release-train maintenance, not an automatic UI requirement.
- The current-test job was the longest job in the inspected main run; that single
  sample is useful for triage, not a demonstrated optimization saving. No new CI
  or paid scoring run was dispatched.
- Preserve the retained candidate's 31 dirty product/test/doc edits and original
  checkout's new uncommitted `brand/`. Implementation starts from current main
  through configured GSD isolation, with a deliberate port/replace/defer ledger.

Evidence: [live baseline](milestone-live-baseline.json),
[compatibility and ordering](milestone-compatibility-sequence.md).

## UI milestone outcome

Engineers and support staff can complete the existing investigation and permitted
operations jobs in a coherent, brand-aligned Threadline Admin, while host access,
scope, audit semantics and public 1.x integration contracts remain intact.
The milestone finishes the existing UI; its first investigation slice is an early
proof point, not the final deliverable.

### Proposed phases, named rather than numbered

| Phase | Delivered outcome | Principal proof |
| --- | --- | --- |
| Reconcile the base and establish safety/proof ownership | Current-main isolated candidate; preserved-edit disposition; fail-closed mount contract; #61/#90 root-cause and remediation ownership; trustworthy prerequisites for affected route and release acceptance | Narrow auth/security/domain checks and the repaired affected proof; explicit blocking ledger, no assumed risk waiver |
| Map jobs, scenarios and the brand contract | Every existing route/job/state mapped to its shared renderer and existing proof; coherent ordinary help-desk scenarios separate from stress cases; approved token/asset/compatibility map | Source/route inventory reconciliation, existing fixture/domain contracts and targeted brand-data checks |
| Brand foundation and first whole investigation | Approved spool/logo/fonts/theme roles and user-facing language implemented through the shell and Timeline → transaction → history → copy → return journey | Data-driven brand/package contracts, mounted-route browser journey, exact-value and keyboard/clipboard checks, rendered review |
| Complete investigation and inspection screens | Home, actor/correlation pivots, transaction/history variants, audited-table inspection, Redaction and operational Evidence all use the proven patterns with truthful missing/denied/unavailable states | Existing journey inventory extended only for distinct gaps; targeted component/LiveView/host/browser checks |
| Complete operations and catalog review | Export/status/download and Retention jobs retain scope, accepted-versus-completed states, confirmation/cancel, event-time authorization and reconnect safety; Storybook links useful components/compositions/screens to real journeys | Existing operation/domain contracts and mounted-route journeys; dev/test-only catalog smoke |
| Integration, docs, package and release readiness | Every existing route/job has the new design and an acceptance disposition; current docs and packaged assets agree; real supported themes/responsiveness/accessibility hold across affected flows | Required existing gates and exact-candidate receipt, bounded independent review, package/install/offline/font-license checks and honest release notes |

Each implementation phase uses the requested research-first discussion method,
reuses settled decisions, and completes useful automated verification/review before
its own phase boundary. Routine substeps within approved scope do not become
another approval question.

### Requirements to translate into the official roadmap

1. Preserve and reconcile current-main, retained edits and the approved brand input; establish fail-closed access and named ownership/remediation for current #61/#90 acceptance/release blockers.
2. Map every supported Admin route/job/state to the owning component and proof.
3. Establish internally consistent ordinary fictional help-desk data, stable private
   keys, real chronology and separately named empty/error/boundary/stress cases.
4. Implement the supplied spool identity, correct theme variants, licensed fonts
   and semantic role mappings; keep logo blue separate from control/link blues.
5. Use Threadline Admin and the approved plain vocabulary while retaining exact
   API/config/schema/telemetry/route/query names and the three domain layers.
6. Complete the first support investigation through real mounted routes with exact
   values, actor/context, zoned timestamps, full-ID copy and return-query continuity.
7. Apply the new design to every remaining existing investigation/inspection job,
   preserving distinctions among missing, null, left out, Redacted and unavailable.
8. Preserve export and retention behavior, scope, confirmation/cancel, persisted
   outcomes and no mutation replay after reconnect.
9. Extend the current Storybook and journey inventory without a second fixture or
   coverage registry. Static stories remain distinct from route/auth/database proof.
10. Verify changed controls and assembled tasks in both themes, keyboard/touch,
    narrow/embedded containers, relevant real zoom, focus and reduced motion.
11. Migrate current README/ExDoc/package/brand tests together. Keep only needed
    distributable assets/fonts with licenses, offline fallback and host opt-outs.
12. Close the full scope with current automated evidence and bounded design/copy
    review, preserving limitations and deferred findings without claiming observed
    human comprehension, actual adopter validation or blanket accessibility.

These are scoping statements; the official requirements will split compound
claims into atomic IDs and give each one a single owning phase after approval.

## Fixed boundaries and clear recommendations

- PhoenixStorybook stays in the existing example/dev/test boundary. Borrow useful
  Fablebook principles without adopting its unfinished library. Accrue remains WIP
  comparison evidence, not authority or a blueprint.
- Preserve host-owned sign-in, authorization, tenant policy and mount location.
  The already-approved fail-closed mount guard is an explicit intentional access/default
  correction, with its host-policy decision, regression checks and migration guidance.
  Add no white-label/logo setting, login/SSO provider, public component package,
  new route, all-schema default, composite-record navigation or capture capability.
- Dark remains default; light and System remain complete. Operations are words
  first. Old/new values use neutral exact presentation; no color-only meaning.
- Prefer existing code or a small, licensed local implementation over another
  dependency for narrow needs. No new runtime dependency is currently justified.
- No paid critic, generic catalog engine, exhaustive cross-product screenshot
  matrix, logo animation/sound, avatar project or second demo application.
- Product package releases and planning milestone labels are separate. Do not
  promise 1.2.0, 1.3.0 or a patch merely from this planning label. Determine the
  actual bump from final shipped behavior, compatibility consequences and release
  policy, including the separately approved mount fix. No live publish or merge
  authority is granted by this scope proposal.

## Verification and efficiency contract

Automate useful acceptance evidence at the boundary that observes it; use the
smallest reliable existing check first. One-shot local/throwaway proof is valid.
CI gets recurring guards only when they pay for their cost. The proposed UI work
needs no new CI job: extend the current example tests and required browser journeys.

Pair visual changes with matched route/story, scenario/clock, theme, browser,
viewport, device scale and zoom. Record the distinct before/after source revisions
and served assets for each capture; matching conditions do not mean identical
source revisions. Inspect actual fonts, composited surfaces, preview-container
geometry, focused element and clipboard behavior. A screenshot or digest is not
route/database proof and cannot by itself close an old finding.

During active/completed CI and release/CD work, inspect timings, duplicate setup,
artifact/cache reuse, polling and long tests. Prefer measured removal of waste
before adding caches/concurrency/dependencies; never weaken required checks.
No extra runs are needed merely to satisfy a process checklist.

Standing method: [research, verification and efficiency policy](../../conventions/research-verification-and-efficiency.md).
Detailed verification: [milestone-verification-dx.md](milestone-verification-dx.md).
Full product scope: [milestone-product-scope.md](milestone-product-scope.md).

## One milestone scope confirmation

Confirm **v1.48 Threadline Admin: brand and complete journeys**, with the six named
phases, full-existing-UI scope, narrow safety/proof gates and exclusions above.
That selects the concrete outcome and order once: UI work starts now, the broader
foundation backlog remains separate, and a first slice does not close the whole
milestone. It grants no blanket risk acceptance and no publication authority.

After confirmation, initialize that milestone on a current-main planning base,
create atomic requirements and a mapped roadmap, then discuss and plan its first
phase using the settled research and standing automation policy. Carry approved
phase work through execution, tests and review until its real boundary. Do not
reset the retained historical worktree into an apparent current-main milestone
or blindly copy its source tree.
