# Brand-led Threadline Admin and flow catalog

Research date: 2026-11-10. Scope: prepare the requested new UI and domain language
using the signed-off identity, Fablebook's useful principles and the supplied
Accrue handoff. Accrue's UI/brand refresh is itself work in progress: its lessons
are comparison evidence to evaluate, not Threadline authority or a blueprint. No implementation
milestone, version, roadmap reorder, public API change or asset migration is selected
by this research.

## Recommendation

Build Threadline Admin as a task-led investigation tool, with a PhoenixStorybook
catalog that connects foundations and individual components to real screen states
and complete user journeys. Use the existing fictional multi-tenant help-desk
application as the coherent demonstration host. Its business actions, actors,
identifiers, chronology and failure conditions should explain what the operator is
trying to establish, rather than merely populate a table.

The new identity sets the visual direction. Keep the product's audit truth:
an action, a database transaction and a captured record change remain different
things. Missing actor context, capture gaps, redaction, excluded fields, expired
history and unavailable reads must remain distinguishable in plainer language.

## Start with one whole task before broad rebuilding

The Accrue comparison strengthens the order of work: map every existing route,
area and supported job first, then validate one representative whole task before
rebuilding the full catalog or every primitive. Small-to-large is the catalog's
review hierarchy, not a requirement to perfect every isolated component before
seeing an assembled screen. A large inventory and a production-shared renderer
can both be accurate while ordinary screens remain awkward.

Recommend the existing support-investigation journey as the first slice:
find an unexpected ticket change using table/actor/date filters → open the
transaction → compare exact old/new values and actor context → follow record
history → copy the record identifier → return with the search intact. Reuse
supported routes and behaviors; record unsupported cases rather than mocking
capabilities into the product. This is a proposed implementation slice, not a
claim that the new design is already implemented or accepted.

| Situation | What the first slice must establish |
| --- | --- |
| Ordinary support work | One coherent fictional ticket, organization, actor, chronology and useful next action; the main answer precedes diagnostic metadata |
| No matches | Accurate filter state, one explanation and an effective reset/next step |
| Redacted or unavailable detail | Replaced, left out, null, unknown actor and absent history retain their distinct meanings |
| Failed read or denied access | Explain the state and supported recovery without false empty results or broader access |
| Return and copy | Query context survives navigation; full identifiers copy accurately with keyboard access and success/failure feedback |
| Layout and themes | Review ordinary screens and affected shared parts in both themes, narrow/embedded widths, keyboard focus and relevant real zoom |

Use the existing journey inventory and production components to own these checks.
Keep hostile strings, duplicate labels and extreme values as separately named
cases. Maintain stable private fixture keys/relationships while improving visible
business data. Do not turn the default review screen into a stress specimen.

Accrue supplies useful candidate checks, not universal layout prescriptions:
remove equivalent filter choices only when Threadline's scope really makes them
redundant; preserve active URL predicates and derive choices independently of the
current search. In particular, one operation or actor type in the current results
is not a reason to hide Threadline's supported operation/actor query choices.
Prefer existing domain/scope facts over adding expensive discovery queries merely
to decide which controls to show. Combine count/reset only where it improves that
job, preserving pagination, pending/retry feedback and accessible announcements.
Keep shown, matched, capped and total counts semantically distinct. Keep catalog
source/evidence metadata secondary to opening the actual screen and flow.

Preserve the installed Storybook shell and scope Threadline styling to its preview
root. Check real wrapper ancestry, served fonts/weights and composited colors.
A width probe must measure the intended container as well as the child; a focus
probe must identify the actual focused control. These transfer as checks to run,
not claims that Threadline already has Accrue's specific defects.

Complete a bounded batch with matched before/after route, scenario, theme,
viewport and zoom; run its mapped behavior/accessibility checks, inspect the
render and record a recoverable verified checkpoint. Keep remaining findings
visible instead of widening the batch indefinitely. Routine verification remains
automated under Threadline's standing policy. Tests and agent review can establish
observable behavior and bounded design judgments; neither synthetic data nor a
green browser run proves real adopter needs or operator comprehension. Do not
import Accrue's open human-UAT gates as new mandatory Threadline gates.

## Authority and source baseline

- The maintainer approved brand edition 1.0 on 2026-11-10. The files identify its
  edition date as November 3, 2026; those dates describe different facts.
- Read `brand/BRAND.md`, `brand/brand.json`, `brand/tokens.json` and
  `brand/assets/README.md` from the original checkout. That uncommitted directory
  is not yet in the retained UI worktree. No assets were copied or overwritten.
  Its [published source](https://github.com/szTheory/threadline-brand/blob/main/BRAND.md)
  was also read through GitHub; the Pages URL was unavailable through the web reader.
- The retained UI candidate is branch `agent-241-01` at `0f9347f2`. Its 31 dirty
  implementation/test/doc files match the preceding pause fingerprint. Preserve
  them and explicitly reconcile them with the eventual implementation base.
- Cached `origin/main` is `d35b9422`; its package is 1.1.0 and v1.47 is closed.
  A live read of [main's state](https://github.com/szTheory/threadline/blob/main/.planning/STATE.md)
  confirms that milestone position; no fetch or branch movement was performed.
  The retained worktree's v1.46 release/planning claims are historical.
- Main's queued Safe by default milestone and its operator authorization finding
  remain separate foundation work. A UI proposal must account for that dependency
  and the existing roadmap before assigning a milestone number or changing order.
- The paid critic and old MechanicalChecker were retired on main. Reuse relevant
  behavioral tests and lessons without restoring that machinery from the old worktree.

Detailed provenance and file fingerprints are in [source-inventory.json](source-inventory.json).

## One connected catalog, from small to large

| Level | Purpose | Useful cases | Proof |
| --- | --- | --- | --- |
| Foundations | Explain the approved visual rules | Both themes, text/control/logo color roles, type, focus and operation words | Brand data mapping and rendered spot checks |
| Primitives and components | Inspect the smallest independent behavior | Controls, exact timestamp, copyable identifier, operation, value/diff, empty/error state | Component/LiveView tests and focused browser checks |
| Assemblies | Check interactions between parts | One-height filter toolbar, timeline row, transaction header, record-history entry, confirmation | Rendered story plus interaction checks |
| Screens | Understand a user's task at a real moment | Timeline, transaction, history, audited tables, policy inspection and operations in named states | Shared production components with scenario projections; genuine mounted routes for route behavior |
| Journeys | Explain entry, decisions, transitions and outcome | Locate a changed ticket → inspect transaction → follow history/actor → share/export | Catalog description and links to executable mounted-host browser journeys |

Use PhoenixStorybook's supported primitives for the catalog. Storybook's example
stories run as child LiveViews and cannot define `handle_params/3`; embedding a
routed production LiveView is not a substitute for testing its URL lifecycle.
The installed dependency source and [official story documentation](https://phoenix-storybook.hexdocs.pm/PhoenixStorybook.Story.html)
establish this constraint. Keep URL restoration, host authorization, scope,
downloads, reconnect and destructive-operation proof on actual host routes.

Fablebook's proposed hierarchy, relationships and AI context can inform a small
local catalog convention. It is not a finished dependency to adopt or a reason to
build a generic workbench inside Threadline.

## Coverage follows jobs and state transitions

Maintain one explicit inventory linking a job to its screen/assembly/component,
scenario, starting conditions, action, expected result and executable proof.
Reference existing journey inventory and fixture identifiers rather than inventing
a parallel registry of the same facts. Use stable identifiers and direct URLs so
an agent can open one case without navigating the full catalog.

For each applicable job, account for:

- The normal result, genuinely empty data and filters with no matches.
- Initial load, pending work, accepted versus completed work, stale reads and retry.
- Permission denial, tenant isolation and unavailable data without a false zero.
- Invalid input, unknown/deleted records, long identifiers and large/nested values.
- Missing actor/action context, direct SQL capture, job/service actors, correlation
  across transactions, and multiple changes saved in one transaction.
- Redacted values versus fields left out, JSON null versus absent values, retention
  boundaries and historical gaps. A simplified diff must preserve those meanings.
- Clipboard denial, direct entry/reload/back, network loss and reconnect without
  replaying a mutation; destructive cancellation, event-time permission and partial
  failure where the existing backend supports them.
- Both themes, keyboard/touch, reduced motion, narrow reflow, actual zoom and forced
  colors where they can change the result.

Every material case needs an explicit covered, planned, not-applicable-with-reason,
or unsupported/debt disposition. Cover distinct failure classes and use selected
cross-cutting combinations; do not multiply every state by every viewport and theme
or describe a screenshot count as exhaustive behavioral coverage.

## A credible demonstration host

Extend the current help-desk story: a customer ticket is reassigned, replied to,
closed, reopened or deleted; an integration/job makes related changes; support
investigates an unexpected result; an authorized team member exports the same
investigation; a platform engineer checks whether intended tables are audited.
Use consistent organizations, roles and chronology across the host, stories,
walkthrough and tests. Keep real application writes and trigger capture in the
connected proof; render-only stories may project those same deterministic cases.

Keep fixture data fictional and representative, with no claim of a real adopter,
pilot or compliance certification. The existing SaaS help-desk domain exercises
multi-tenant access, human and system actors, record history, redaction and
operations without adding a second application or implying regulated-domain support.
Other industry scenarios can be considered when they expose a distinct supported
failure class, rather than becoming mandatory separate demo applications.

Semantic fixture checks matter. `demo/manifest.ex` describes May 20, 2026 as
"last Tuesday", but that date and its May 27 epoch are both Wednesdays (verified
with the Python calendar). Reconcile the intended story, frozen timestamps and
human labels together. Plausible names alone do not make a scenario realistic.
Also reconcile the walkthrough reset recipe: `mix demo.reset` already calls the
seed, while `DEMO-MANIFEST.md` tells readers to seed again after reset.

## Brand and language migration

1. Replace the old authority deliberately. Inventory package files, docs assets,
   README, font serving, runtime logo, design records and tests before migration.
   Inspect `test/threadline/brandbook_token_parity_test.exs` first: its current
   authority and historical prose assertions do not express the new contract.
   Despite the header, the current test bodies do not compare theme color values;
   the replacement needs actual data-driven role/value checks.
2. Map approved brand roles to the existing semantic UI tokens. Stitch Blue belongs
   to the logo; control/link/focus colors use the appropriate theme's Thread Blue.
   Keep structural spacing tokens separate from brand colors. Check the eight
   contrast roles in both themes and then the actual rendered controls and content.
3. Use supplied spool/outlined wordmark assets and proper theme variants. Preserve
   their geometry, clear space, minimum sizes and font licenses; verify packaged
   fonts/assets offline. Light is a full theme and System remains immediate.
4. Adopt plain user-facing vocabulary with a compatibility map. Recommend the
   official UI name Threadline Admin, audit trail library, record/history, audited
   and not audited tables, redacted versus left out, and host app. Preserve existing
   public module/function/route names unless an explicit compatibility decision
   changes them. Distinct persisted operational evidence is not automatically record
   history; context must survive the wording change.
5. Design the actual investigation layouts from jobs using the book's proposed
   Timeline/diff treatment as a starting point. Operation words carry meaning;
   before/after values stay neutral and exact. Time displays need explicit zones.
   Copyable IDs need keyboard semantics, clear focus, success/failure feedback and
   access to the full value without changing it in place.

Recommend leaving Ember removed and keeping authentication owned by the host app.
Document supported integration patterns, not a new login provider. White-label
configuration, organization avatars, logo animation/sound, all-schema auditing
defaults, new routes and unsupported record-key navigation are separate behavior
or capability choices, not incidental brand migration.

The book's broad wording about every change, actor or historical value needs
capability qualification: capture covers installed audited tables; actor/context
may be absent; retention, redaction, capture start and table-shape support limit
what can be reconstructed. A brand illustration is not evidence of shipped UI.

## AI iteration and evidence

Give an agent the job, scenario, state, target URL/story, owning components, approved
brand roles, expected result and current proof. Reproduce one failure, make a
bounded change, verify the relevant behavior and inspect the rendered result.
Group fixes before another capture pass. Record source, assets, fixture/clock,
scope, theme, viewport/browser and capture identity with the result.

Derive summaries from the existing catalog/fixtures where possible; avoid another
hand-maintained prompt bundle or generic schema engine. Keep automated review
bounded and specific. Old screenshots, passing component renders, token arithmetic
and subjective LLM judgments establish different things and cannot replace one
another. Tests should protect recurring failure classes, not fossilize a layout
by asserting every incidental wrapper or prose sentence.

## Research inputs and next step

The maintainer approved the [revised v1.48 proposal](milestone-proposal.md) and
confirmed PhoenixStorybook with Phoenix LiveView/HEEx now, with Fablebook deferred
until ready. Milestone initialization is recorded in `milestone-initialization.json`;
current execution authority is `../../ROADMAP.md`, `../../REQUIREMENTS.md` and
`../../STATE.md`. The original proposal/review remain preserved research evidence,
including their historical pre-approval language. This source folder was deliberately
imported into the new current-main checkout; the retained old UI candidate remains
unported pending Phase 248.

- [Brand and language migration](brand-language.md): coupling, compatibility and
  concrete migration risks.
- [Fablebook principles](fablebook.md): implemented versus proposed ideas and what
  transfers to PhoenixStorybook.
- [Storybook and journey baseline](storybook-journeys.md): existing host, catalog,
  fixtures and behavioral coverage, with gaps and recommended sequencing.
- [Accrue task/data lessons](accrue-tasks-data.md),
  [catalog/rendering lessons](accrue-catalog-rendering.md), and
  [evidence/iteration lessons](accrue-evidence-iteration.md): source-backed
  comparisons from its unfinished refresh. Owner corrections, implemented fixes,
  test evidence and open findings are distinguished in each report.
- [Milestone product scope](milestone-product-scope.md),
  [compatibility/ordering input](milestone-compatibility-sequence.md), and
  [verification/DX plan](milestone-verification-dx.md): focused decision research
  feeding the revised proposal. Initial ordering advice remains visible as an input.
- [Live milestone baseline](milestone-live-baseline.json): historical required-CI
  pass, newer scheduled findings and actual existing-run job timings.
- [Accrue source provenance](accrue-source-inventory.json): the supplied handoff,
  linked notes, inspected revision and document fingerprints. Accrue's session
  continuity changed during the scan; the inspected handoff inputs and source
  revision remained unchanged, and its existing stops were preserved.

The proposed sequence is: reconcile current main and the preserved UI candidate;
map existing jobs/routes/states and establish normal sample data; implement and
verify the representative investigation slice; then extend the proven shared
patterns to the remaining jobs in bounded batches. Keep package/docs/brand
integration and current-main foundation dependencies explicit in that scope.
The revised scope and reordering were approved at the milestone boundary;
Phases 248–253 now own the atomic requirements. The brand authority
is already approved and does not need another approval. No product source/assets
were changed, no services restarted and no application tests or browser claims were
made during this research.
