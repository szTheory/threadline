# Operator UI refinement — preparation

Preparation date: 2026-10-08. Current update (2026-10-09): Phase 238 is complete; fresh baseline and handoff supersede the historical observations below. Next: `$gsd-execute-phase 239`.

Original preparation status: research reused for approved v1.46 Operator UI Refinement; 26 requirements and the six-phase roadmap approved.

The maintainer requested preparation using the Scrypath/Accrue/Mailglass UI
kickoff, including lessons from fixes after Scrypath's completed milestone.
They requested Impeccable initialization before fleshing out the GSD milestone.
Init completed later on 2026-10-08; see the confirmed choices in the handoff below. No new version, requirements, phase directories, roadmap, or product
UI changes are authorized by this preparation record alone.

## Recommendation and confirmed intent

Prepare **Operator UI refinement: readable evidence and predictable actions**.
Make the existing operator surface a coherent place to answer who changed what,
when, and why; understand the limits of that evidence; and complete existing
operations safely across desktop and narrow screens.

The maintainer explicitly wants familiar conventions, consistent shared
components and tokens, readable type and spacing, coherent domain language,
useful visible controls, appropriate layouts, responsive behavior, and complete
happy/error/boundary states. They want agents to do the visual and behavioral
verification, with little babysitting, bounded iteration, and no new paid visual
critic loop. A later personal review is welcome feedback, not the default test
executor. This is new maintainer feedback supporting evaluation under the
milestone guide; the earlier sustainment recommendation is historical context.

Recommended interpretation: refine the established Threadline identity and
existing capabilities. Avoid a rebrand, framework migration, cross-project UI
package, or expansion of backend scope. These are recommendations for the later
scope confirmation, not silently ratified requirements.

## Preparation snapshot and evidence limits (2026-10-08; historical)

- GitHub main was read live on 2026-10-08 and agrees with cached origin/main:
  **9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2**, distribution sync for 1.0.1 (#84).
- v1.45 / Phase 237 remains completed: 7 phases, 47 plans. No Phase 238 exists.
- This planning checkout is on milestone/v1.44 and its package version is still
  0.11.2. Preserve its local edits. Source execution must start from current main
  through the configured GSD isolation workflow, carrying this planning context
  into that execution checkout. Do not build the milestone on the stale branch
  or discard its planning history in a wholesale branch switch.
- Source inventory used origin/main. The inspected operator source and example
  host assets have no worktree difference from that ref, but that does not make
  the entire old checkout a current implementation base.
- No running helper-managed demo was found with `bin/demo-up --list`. No app was
  started during preparation, and no new browser or test result is claimed.
- The checked-in operator PNGs last changed at **799c7d6e** (2026-06-20).
  Seventy-eight operator/host source files changed in the inspected paths since
  then. Three historic images were viewed for context only. Their colored masks
  are test instrumentation, not product rendering. They cannot establish current
  visual defects or serve as the new before baseline without recapture.
- The existing screenshot-regression spec explicitly skips CI. Capture,
  mechanical, behavioral, local pixel, and required CI checks are distinct proof.

## Existing Threadline surface

Paths below are relative to the host mount (the example uses `/audit`). Source:
`lib/threadline/operator_surface/router.ex` at the baseline above.

| Path | Existing job |
| --- | --- |
| `/` | Choose an investigation, inspect health, resume saved searches, look up a record/correlation |
| `/timeline` | Filter changes, page results, pivot by actor/correlation/transaction, save a view, export |
| `/transactions/:id` | Inspect transaction context and before/after changes |
| `/rows/:table/:record_id` | Inspect row history and as-of state directly |
| `/transactions/:id/history/:table/:record_id` | Inspect row history in a transaction drawer |
| `/actors/:kind/:id` | Inspect actor activity and pivot to transactions |
| `/coverage` | Understand schema-specific capture gaps and migration remediation |
| `/evidence` | Inspect evidence projections and subject-specific proof history |
| `/exports` | Queue an export, follow progress, download a completed result, recover its source search |
| `/policy/redaction` | Compare configured policy with deployed trigger policy |
| `/policy/retention` | Inspect runs/failures/evidence and perform an authorized, confirmed prune |

Theme submission and export/download endpoints also belong to these journeys.
Stress routes and Storybook are verification surfaces, not operator navigation.

Existing building blocks are in `operator_surface/ui/{page,actions,form,overlay,
data,display}.ex`, `presentation.ex`, and the nine `style/*.css` files. There are
already shared headers, navigation, forms, tables, empty/error states, overlays,
references, semantic tokens, dark/light/System themes, reduced-motion handling,
and a central reconnect banner. Reuse and correct these; do not reopen the
shipped reconnect-banner seed or assume a theme picker is missing.

Primary job chains for later acceptance:

1. Support investigator: locate a change → inspect transaction/diff → follow
   actor, correlation, or row history → preserve/share the investigation.
2. Platform operator: identify missing capture → inspect the right schema →
   obtain remediation guidance → distinguish verified readiness from unknown.
3. Security reviewer: inspect evidence/redaction/retention → understand partial,
   pruned, unavailable, denied, and genuinely empty data without false assurance.
4. Authorized maintainer: inspect a failed operation → retain scope and context →
   recover or perform a destructive action with an accurate consequence preview.

## Lessons from sibling projects

Separate-repository paths in this section are relative to the named repository.
Research was read-only. Recorded test results were inspected, not rerun. Dirty
worktree evidence and plans are explicitly distinguished from committed fixes.

### Scrypath: what formal completion missed

v1.42 / Phase 172 was archived October 4 at **5ed440954ba70d2b94d8b480d625530e26a809ac**.
Its audit records 8/8 requirements, 38/38 truths, 104 browser tests and four mounted
tests. Subsequent October 4–5 fixes were outside that completed source receipt.
The inspected local branch was 18 commits ahead of cached origin/main. Its v1.43
was planned, with zero implementation plans completed; later dirty changes and
proposed remedies are not shipped evidence.

| Observed issue and provenance | Lesson for Threadline |
| --- | --- |
| **698013c, Oct 4:** pointer hover and keyboard selection highlighted different command items; `scrypath_ops/assets/js/ops_hooks.js` and `admin_shell_chrome.spec.ts` were corrected. | Test pointer → keyboard → pointer sequences. Selection styling and accessibility state must agree, beyond separate mouse/keyboard happy paths. |
| **b10ba7d, Oct 4; 7abb4c9 follow-up:** LiveView loading text replacement removed a nested refresh icon; hooks and mounted wiring needed follow-up. | Exercise actual pending/success/error and patch cycles. Preserve labels/icons, suppress duplicate submissions, retain server-denied eligibility, and respect reduced motion. Do not copy a hook that snapshots disabled state without handling later patches. |
| **961ecf4, Oct 4:** alert utilities overrode intended toast colors despite semantic tokens. | Inspect computed styles and contrast in the served host, including both themes. Token declarations alone do not prove cascade behavior. Fix owning rules instead of accumulating override layers. |
| **2977c92, Oct 5:** refresh/time controls were consolidated, false success feedback avoided, essential failure reasons exposed, and vague navigation renamed. **6881d76** aligned titles/nav/breadcrumbs. | Define observation time, pending, accepted, and completed separately; use consistent nouns and keep primary diagnostic evidence visible. Preserve URL scope and navigation compatibility when labels change. |
| **Oct 6 dirty worktree:** nested diagnostic panels were flattened; the browser test that demanded their border contrast was replaced by checks for a plain group with at most one divider. Source: `live/posture_live.ex`, `assets/css/app.css`, `admin_surface_depth.spec.ts`. | A passing test can fossilize poor hierarchy. Review whether each panel represents an independent object or merely wraps another panel. Use task-based visual review alongside layout/state assertions. This correction remains local evidence. |
| **Oct 6 dirty worktree:** namespace/timestamp truncation was removed and diagnostic type enlarged. | Use long actual identifiers and values. Verify the full value is reachable and copyable; a visible container does not prove its evidence is readable. |
| **f09da66 / 48acc15, Oct 6:** `.planning/reference/OPERATOR-UI-REFINEMENT.md` records remaining color/theme/clipboard problems; source separates preference and effective theme incorrectly in its pill. Remedies are v1.43 plans. | Distinguish System preference from current appearance, unknown from healthy, and clipboard attempt from confirmed success. Neutral surfaces and local status cues are a recommendation, not evidence those planned fixes already succeeded. |

Useful completed precedent: **1b2287e, Oct 3** measured overlap/reflow at
320/390/1279/1280/1440 widths and modal focus through real LiveView patches.
Sources: `.planning/milestones/v1.42-MILESTONE-AUDIT.md` and
`v1.42-phases/172-consistent-operator-ui-and-verified-recovery/172-07-SUMMARY.md`.

### Accrue and Mailglass: current work, not finished templates

Accrue v1.63 has verification records for Phases 233–235 and Phase 236 fixes through
**adcdbbfa** (Oct 8). Its current untracked verification still describes an earlier
theme gap addressed by subsequent commits. Later phases remain unfinished.
Mailglass HEAD was **72801f9b** (Oct 8): Phase 169 records 100/100 truths; the modified
Phase 168 verification records 94/95 with a spacing-contract blocker. Neither is
evidence that its entire current milestone has passed.

| Evidence | Transfer and limit |
| --- | --- |
| Both have PRODUCT.md and a local code-first setting. Accrue **594f7a33** (Oct 7) records phase-local design authority; Mailglass uses `mailglass_admin/docs/design-system.md` and source tokens. | Give product facts, brand direction, source token values, and per-surface acceptance clear ownership. Do not duplicate token catalogs across planning files. Their code-first choice does not set Threadline's preference automatically. |
| Accrue **2c6da192 / 89410264 / 42e2be0b** (Jul 18) corrected contrast/focus/dark-token issues; scoped `--ax-*` assets retain some documented overrides. | Borrow semantic roles and cascade discipline, not another framework, palette, or token namespace. Existing corrections do not establish a pristine design system. |
| Mailglass **5bdc1098** (Oct 7) separates a replay command result from delivery evidence; Phase 168 removed a fabricated stale timestamp. | Preserve audit truth: action ≠ transaction ≠ change, ActorRef ≠ user, unknown ≠ empty, redacted ≠ missing, and accepted operation ≠ completed operation. |
| Mailglass **f574f838 / 5fa6a380 / b5b2de00 / f2223fa0** (Oct 8) fixed pending scope feedback and proved complete values at real 200% browser zoom, including 320 CSS px layout. | Test browser zoom separately from viewport emulation. Keep old identity and old data paired while new scope loads; do not relabel old evidence prematurely. Hold a real request/patch to inspect pending feedback. |
| Accrue **519ef895** (Oct 8), quick `261008-cjc`, separated normal verification from destructive baseline capture; **748751c7** repaired an incompletely exercised journey. Its summary still records another suite regenerating tracked PNGs. | Make ordinary tests read-only over baselines; explicit capture writes to a fresh destination. Verify full control sequences and actual served asset identity. Keep a review demo separate from fixture resets. |
| Mailglass **5c42d563** (Sep 17), Phase 166 summary: 325 of 510 Admin tests had been omitted by a nine-file CI allowlist. | Prove tests are discovered and required checks actually execute them. A local pass, artifact inventory, advisory browser job, and protected CI result are different evidence. |
| Accrue v1.56's model-based UI ratchet did not converge on information architecture and was parked; current sibling guidance favors finite review batches. | Threadline's paid critic is retired (tag `archive/ui-critic-loop`). A more elaborate scoring pipeline is not the default solution to hierarchy problems. |
| Mailglass Phase 168 currently blocks a broad readability contract over 2px utilities after functional reflow passed (dirty verification). | Agree on a semantic spacing scale and legitimate optical exceptions. Avoid imposing literal arithmetic on every border, focus ring, or icon offset. This is a planning caution, not authority to waive its approved contract. |

Sibling paths worth revisiting at scope time: Accrue
`.planning/notes/2026-10-07-accrue-ui-refinement-scope.md`,
`.planning/phases/233-shared-direction-portal-contract/DESIGN.md`, and quick
`261008-cjc` summary; Mailglass `168-BASELINE.md`, `168-09-SUMMARY.md`, and
`168-VERIFICATION.md` under Phase 168, plus
`mailglass_admin/e2e/phase168-plan03-acceptance.spec.js`.

## Threadline candidates requiring fresh proof

These are source findings at the pinned main SHA, not claims of browser reproduction.

| Candidate | Source | First useful proof |
| --- | --- | --- |
| Copy controls may lack their binding on direct entry to Evidence, Exports and Retention. | `ui/page.ex:270` defaults shell script off; `ui/display.ex:178` emits Copy based on app config; those pages do not enable the shell script. | Fresh isolated browser context for each direct URL; clipboard success and failure. Prior navigation must not preload the missing handler and mask the gap. |
| Queue-export controls omit the shared mutation marker used for disconnected treatment. | `live/timeline_live/filters.ex:343`, `live/export_status_live.ex:263`; existing socket-drop coverage concentrates on Retention. | Real socket loss, keyboard and pointer activation, pending/reconnect state, no duplicate mutation; inspect semantic disabling as well as CSS dimming. |
| Paper/ink aliases self-reference; the style test substitutes expected colors. | `style/01_tokens.css:44`, `89`, `215`, `267`; `test/threadline/operator_surface/style_contract_test.exs:1914`. | Browser/cycle-aware token resolution. No current consuming declaration was found, so classify as latent token/test debt rather than a visible defect. |
| Labels drift between page and link/feedback wording. | `timeline_live.ex:301`: Export Status page vs Exports; Actor timeline vs Actor activity; saved searches/views. | Small canonical copy map used by nav, headings, controls, feedback and workflow assertions. |

Hierarchy, tiny text, nested framing, drawer reachability, filter ergonomics and
truncation remain inspection targets until current rendered evidence establishes
their severity. Do not manufacture a defect list from historic screenshots.

Scope boundary to preserve: composite-key capture is supported, but the current
row-history route intentionally accepts one scalar PK. Row-history also requests
an unbounded history read. Record these capability/performance limits; new routing
or pagination needs explicit later scope, not incidental polish.

## Design and engineering approach

Use Threadline's existing brand book: calm, precise, evidence-oriented; Geist and
IBM Plex Mono; readable compact density; semantic color; accurate domain nouns.
Use Impeccable's **Operate** guidance. A branded tool earns familiarity through
layout, typography and consistent controls; it does not need decorative novelty.

Recommended composition rules:

- Start from the user's task and its primary action/evidence. Common controls are
  visible; less-common options and large payloads use deliberate disclosure.
- Tables suit comparing records; definition lists suit metadata; diff/history
  presentations suit changes over time. Use the representation the job needs.
  Neither every object in a card nor every screen in a table is a useful rule.
- One independent object may warrant a surface. Headings, proximity and dividers
  usually suffice inside it. Use semantic spacing/type/elevation/z-index roles,
  with documented optical exceptions instead of page-specific magic numbers.
- Narrow screens preserve investigation context and full evidence access. Allow
  local scrolling for genuinely two-dimensional material; prevent accidental
  whole-page overflow. Intermediate breakpoints and short viewports matter too.
- Audit timestamps retain exact time/timezone access; raw IDs and field values
  stay lossless. Redaction, absence, pruning and permission limits remain honest.
- Prefer existing Phoenix/HEEx primitives and small existing JS hooks. Fix event
  lifecycle and CSS ownership before adding dependencies. Share primitive edits
  through one owner; parallelize independent page work only after that contract.

Kowalski's installed `emil-design-eng` guidance supplies the motion criteria:
frequent operations stay immediate; motion must explain state, feedback or
spatial change; overlays remain interruptible; reduced motion is respected.
Apply animation review to identified transitions after layout and state behavior
are sound. Do not port React-specific APIs into LiveView. The
[official skill collection](https://github.com/emilkowalski/skills) also provides
targeted animation review and opportunity discovery; none requires animating
every route or importing a new animation library.

Relevant prior art informs behavior, not a copied visual skin:

- [Phoenix LiveDashboard](https://phoenix-live-dashboard.hexdocs.pm/Phoenix.LiveDashboard.html)
  groups operational inspection by concrete resources and expects host-side
  access protection. Keep Threadline's host authentication and mount contract.
- [Oban Web's v2.13 changelog](https://oban-web.hexdocs.pm/changelog.html) documents
  consistent detail layouts, meaningful empty states, scoped confirmations and
  keyboard controls. Its fixes for silent font fallback, reconnect listener
  duplication and enabled controls without permission are additional useful
  regression classes. Borrow those checks, not Oban's jobs/queue domain or its
  particular browser-history policy.
- [WCAG Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html) and
  [Resize Text](https://www.w3.org/WAI/WCAG22/Understanding/resize-text.html)
  justify separate reflow and magnification checks. Narrow viewport emulation
  alone is insufficient evidence of usable text at browser zoom.

## Verification that earns its cost

Inventory every route, shared primitive, unique control and material transition,
then test applicable combinations. Do not multiply all themes × widths × states
into a giant screenshot collection. Every item gets an explicit disposition:
covered, scheduled, justified N/A, or recorded debt. States the backend cannot
produce must not be invented to fill a checklist.

Reuse the existing proof layers:

| Layer | Existing entrypoints or surfaces | What it establishes |
| --- | --- | --- |
| Domain and LiveView behavior | `mix verify.test`, targeted existing tests | State, scope, authorization, redaction, validation and event outcomes |
| Shared primitives and stress | `mix verify.operator_component_contracts`, `mix verify.operator_stress`, Storybook | Reusable states, structural/geometry floors, overlays and motion behavior |
| Connected browser jobs | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium`, `mix verify.example_browser_light` | Actual controls, focus, URL/context, host integration and theme behavior |
| Capture and mechanical floors | Retired in v1.47 Phase 246; restore from tag `archive/ui-critic-loop` | Not an active proof layer |
| Delivery regression | Existing required CI and `mix ci.all` | Required proof on the delivered source; preserve job IDs and current browser partition ownership |

Verify entrypoint discovery on the implementation baseline before claiming scope.
The current automated browser engine is Chromium; do not claim Safari/Firefox or
physical-device validation from it. Whole-shell review must supplement captures
clipped to `#tl-main`. The paid UI-critic loop is retired; restore it from tag
`archive/ui-critic-loop` (v1.47 Phase 246). Retired Tier C pixel machinery stays
retired unless a distinct failure class warrants reconsideration.

Capture contract: record source SHA, relevant uncommitted diff if any, served
asset identity, fixture scenario, route/state, role/scope, theme/preference,
viewport/browser, motion setting and deterministic clock as applicable. Keep
ordinary tests from rewriting before images. Limit masks to unstable values;
do not mask the evidence whose wrapping or semantics the test must inspect.

Critical browser sequences include fresh direct entry, reload/back/forward,
filter/scope changes during delayed responses, repeated LiveView patches,
disconnect/reconnect, pointer/keyboard switching, focus return/escape, long
unbroken values, unavailable clipboard, failed operations and overlapping
toast/drawer/menu states. Check theme preference versus effective appearance;
read-only permission versus temporary busy state; actual clickability and full
value reachability, not just element visibility.

Use a representative route/state matrix for desktop, narrow and intermediate
widths, both themes, System behavior, reduced motion and actual browser zoom.
Expand only for identified risk. Snapshot images need an explicit environment
policy; do not silently promote the old platform-local PNG guard into CI.

For each coherent implementation slice: finish it, batch desktop/mobile/theme
visual inspection, fix the findings in one batch, then confirm once. Stop
subjective polishing; concrete unresolved defects get a reproduction and
disposition. Judge improvement by completed tasks, readability and removed
defects. Synthetic scores, screenshot counts and test counts are not the goal.
No external model API, paid critic, image-generation spend, or new hosted
service is authorized by this brief.

Threadline already learned this in v1.40: Phase 197's intended two-to-three-page
improvement proof was not achieved; Coverage's attempted iteration was VOID.
The archived `197-02-SUMMARY.md` and `197-VERIFICATION.md` record the paid loop's
poor value. Retain useful deterministic guards and avoid rebuilding that loop.

## Recommended order after initialization (not GSD phases)

1. Confirm durable product facts through Impeccable init, using this record and
   existing brand/domain sources. Record the incumbent design only after seeing
   current renders; missing DESIGN.md is not evidence of a greenfield app.
2. Establish a clean current-main implementation base and a reproducible, safely
   seeded preview. Capture the full shell, eleven routes and representative
   interaction states. Produce a ranked defect/acceptance list from that evidence.
3. Establish one representative complete investigation composition, then repair
   shared tokens, controls, copy and lifecycle behavior against it. Avoid a long
   abstract component rewrite before proving a usable page.
4. Apply the shared decisions through investigation and operations journeys,
   including permission/error/boundary cases. Finish responsive behavior and
   targeted motion as part of each journey, not as an end-of-milestone afterthought.
5. Perform a bounded integration/visual sweep on the final delivered source,
   refresh evidence after fixes, confirm CI coverage, then prepare the normal
   release and review preview. List any remaining limitation honestly.

Architecture/semver: Phoenix remains optional; private operator components remain
private; capture/semantics/exploration and public 1.x contracts remain intact.
Security: UI affordances reflect server authorization and redaction, never replace
them. SRE: avoid extra polling, unbounded DOM growth or duplicate reconnect
listeners; measure realistic dense views before optimizing. DX: preserve mounts,
deep links, asset delivery and maintainable CSS ownership. Accessibility/content:
readable hierarchy, complete evidence, keyboard/touch parity and truthful feedback
are evaluated together. These lenses must cohere in later scope and plans.

## Adapted kickoff for the later milestone

Refine Threadline's existing admin/operator UI into a calm, conventional,
coherent tool for investigating audit history and managing the operations already
supported. Work from current main and preserve all unrelated local edits. Read
this preparation record, the domain model, Brand Book, milestone guide and current
Impeccable context before proposing requirements.

Inventory routes, jobs, primitives, unique controls and applicable states. Start
from fresh rendered evidence, then improve hierarchy, legibility, domain copy,
control discoverability, shared tokens and component consistency through complete
jobs. Use appropriate data representations; preserve exact IDs/timestamps and the
distinctions between actions, transactions, changes, context and actors. Preserve
host authorization, redaction, tenant scope, routes and supported capability limits.

Use Impeccable for product/design context and bounded Operate-mode refinement;
use Kowalski's guidance for interaction quality and purposeful motion. Apply the
Scrypath post-completion lessons and Accrue/Mailglass verification lessons above.
Reuse existing automation, inspect actual rendered states, and prove that final
CI executes the relevant checks. No paid visual-judge loop or open-ended polish.
Deliver a reproducible preview and an evidence-backed list of remaining limits,
so the maintainer can give taste feedback after the baseline is complete.

## Next commands and handoff

Impeccable init completed on 2026-10-08. The maintainer explicitly confirmed:

- Equal priority for engineers and support/on-call operators in the operator UI;
  integrating Elixir developers remain the package's primary adopters.
- Code-first as the stored workflow default in `.impeccable/config.json`.

`PRODUCT.md` contains the confirmed product record. The optional live-mode config
points at the example host's actual `layouts/app.html.heex` document and its
closing-body anchor. The CSP detector returned no signals; source inspection
found Phoenix's default base-uri/frame-ancestors policy without a script/connect
restriction. No template/CSP modification or helper
injection was performed. The configuration is statically checked, not a claim of
live-picker compatibility: start and smoke-test it with the fresh current-main
preview. No DESIGN.md was created or visual direction chosen by init.

Milestone setup is complete: **v1.46 Operator UI Refinement**, using this file
and PRODUCT.md. The maintainer approved the scope, research reuse, all 26
requirements and Phases 238–243. The specific next command is `$gsd-execute-phase 239` (updated after Phase 239 plan verification on 2026-10-09).
Do not rerun completed v1.45 phases or Impeccable init.

Impeccable context ran once during preparation: installed v4.5.0, no PRODUCT.md,
DESIGN.md or surface brief detected. Its `hasVisualImplementation: false` is a
detector limitation for this Elixir-rendered UI, contradicted by source and prior
visual evidence. The launcher advertised v4.5.1; no skill update was performed.
The initial deferral is resolved by the confirmed initialization above.

Preparation verification: changed-file whitespace checks, source identity, key
reference paths and unchanged milestone counters passed. No product tests were
run for this documentation-only preparation. The repository-wide
`bin/verify-repo-hygiene` scan found 12 pre-existing machine-local path occurrences
in eight older planning files (Phase 233 validation and quick tasks 261008-fg2,
261008-gce, 261008-h8v and 261008-ic2). It found none in the three preparation files.
Those historical files were not changed; the full repository scan is therefore
not green. Keep this separate from UI requirements and resolve before publishing
planning records that include those paths.
