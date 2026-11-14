# Adversarial review: Threadline Admin milestone proposal

**Verdict: REVISE before the single scope/order checkpoint.** The Admin outcome,
compatibility boundaries, route-versus-story proof split, and bounded verification
approach are coherent. The order recommendation does not fully honor the explicit
direction to start the UI milestone now, and two gate statements need sharper owners
and source identity.

## Material findings

### HIGH — Full Safe-by-default completion delays the authorized UI milestone

`milestone-proposal.md` acknowledges that only the fail-closed mount fix is a direct
UI dependency (lines 17–22), but still asks to finish the entire v1.48 milestone
before starting UI (lines 10–15, 145–155). The product scope likewise recommends
waiting and re-ranking later (`milestone-product-scope.md`, lines 9–11, 57–59).
That makes unrelated txid, SQL/CSV, PgBouncer, and support-floor work a scheduling
gate even though the compatibility report says they are not UI prerequisites.

The live evidence justifies keeping release and verification gates: #61 includes
advisories in the shipped runtime, and #90 reports a first-iteration suite failure.
It does not establish that every Safe-by-default item must finish before UI scoping,
brand foundation, or static Storybook work can begin. A clear, lower-delay sequence
is: make the authorized Admin work the active milestone now; require the approved
fail-closed mount fix before any mounted/live Admin journey; diagnose and fix the
runtime advisories and broken suite before the affected package/release or claiming
green acceptance. Keep the remaining v1.48 work separately ranked and visible.

This does not waive security risk: starting scoped UI work is not risk acceptance.
Do not mark #61 or #90 accepted by default. If diagnosis shows a specific UI task
would exercise an affected vulnerable path, block that task until its remedy lands.
No extra approval is needed for routine phases or retests inside the approved UI
scope. If the maintainer must choose between preserving the entire v1.48-first queue
and making UI the next active milestone, put that order in the one checkpoint; do not
ask again whether to start UI, which is already authorized.

### MEDIUM — The open findings lack one explicit owner and non-waiver gate

The proposal says to triage #61/#90 and “resolve release/phase blockers,” while the
compatibility report suggests a “fix-or-accepted-risk disposition.” The later
sentence correctly says real risk acceptance needs a separate informed decision,
but no-waiver-by-default makes the earlier wording ambiguous. State one owner for
the current-main baseline investigation and the gate for each issue: no release with
unresolved shipped-runtime advisories; no green/complete claim while the required
suite has an unexplained deterministic failure. Preserve the findings until fixed;
the single milestone scope/order decision must not be recorded as acceptance.

### LOW — “Same candidate” conflicts with before/after captures

`milestone-verification-dx.md` line 29 asks for a “before/after pair” under “Same
candidate” while also recording source identity. Those captures necessarily have
different before/after source revisions (and possibly served assets). Say “same
route, state, fixture/clock, theme, browser and viewport conditions”; record the
distinct source revisions and served assets, as `milestone-proposal.md` already
specifies at lines 129–134. This removes an impossible reading without adding proof.

## Coherence check

- The full existing Admin outcome is scoped clearly: the ordinary investigation is
  an early slice, all supported existing jobs/routes receive the redesign or an
  explicit disposition, and no new backend/API/login/white-label capability is
  smuggled in.
- PhoenixStorybook remains a dev/test catalog; mounted host routes and domain tests
  own URL/auth/download/persistence/capture claims. No second registry or new CI job
  is justified by the supplied evidence.
- The package target is provisional and release type is still tied to the shipped
  diff; keep it out of the single UI-scope decision.

## Recommendation for synthesis

Use one checkpoint for the authorized full Admin milestone and its order: start the
UI milestone now, with the mount-authorization and current-main verification gates
above. Keep #61/#90 open until evidence resolves them and preserve the remaining
Safe-by-default work as separate queued scope. Then initialize atomic requirements
and the roadmap once, and carry the approved scope through execution, review and
automated verification without routine re-approval.

## Targeted closure review

**PASS.** The revised proposal makes Threadline Admin the active v1.48 milestone,
keeps the broader Safe-by-default backlog separate, and assigns #61/#90 triage and
remediation tracking to the baseline phase. It explicitly preserves those findings
as acceptance/release blockers without treating scope approval as risk acceptance;
the approved mount guard gates mounted-route acceptance. The revised visual row
now pairs matched capture conditions with distinct before/after source and served
asset identities. All three findings are addressed; no further material fix is
needed within this review's scope.
