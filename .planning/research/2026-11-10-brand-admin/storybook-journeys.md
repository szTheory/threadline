# Storybook and operator journey baseline

Read-only source review for the brand-led Threadline UI work. The active checkout is at `0f9347f2`, behind the locally cached `origin/main` at `d35b9422`. The example Storybook, demo seed, operator journey tests, and their contracts match that cached baseline except for one wording-only capture row in `operator-journey-inventory.json`. This report uses the active checkout for source references and the original checkout's new, uncommitted `brand/BRAND.md` and `brand/brand.json` for the brand contract. No tests or application commands were run.

## Recommendation

Keep the existing Phoenix example, help-desk data, component Storybook, real mounted `/audit` routes, and Playwright journeys as one proof system. Make Storybook better at reviewing branded components and composed states; keep route changes, authorization, tenancy, downloads, and retention actions in the real host router and browser tests. Extend the existing demo manifest and journey inventory instead of creating a second fixture registry or a new demo vertical.

The fictional multi-tenant SaaS help desk is a good leading domain for Threadline: it already demonstrates an agent changing a ticket, a support person investigating it, an async/service actor, a deleted reply, field redaction, org-scoped access, exports, and retention. Healthcare or finance examples would suggest compliance guarantees the project explicitly does not claim. Keep every sample clearly marked as fictional and avoid invented adopter, pilot, or measured-outcome claims.

## What exists today

| Surface | Evidence already in the repo | What it proves |
| --- | --- | --- |
| Component and state catalog | The Storybook has foundations, primitives, forms, states, overlays, data display, groups, and patterns. Its tests name component contracts and ugly-data cases (`examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs:10-108,144-256`). | Component variations, typography/theme examples, empty/loading/error/denied/redacted/pruned/stale states, long IDs, null fields, time-zone boundaries, pagination boundaries, reconnect, and selected composite groups. |
| Responsive Storybook rendering | The bounded smoke visits representative stories at 320, 375, and 768 px and checks the preview theme marker and overflow (`examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts:5-16,27-79`). | Stories render and fit at representative widths. This does not establish that host routes, URLs, authorization, or data transitions work. |
| Operator journeys | The inventory enumerates required desktop/mobile investigation, saved-search, evidence, coverage/redaction, export, retention, reconnect, accessibility, motion, and zoom rows (`examples/threadline_phoenix/e2e/support/operator-journey-inventory.json:5-38`). Browser tests exercise the actual Timeline query/transaction flow, Home lookups, row history, exports, evidence context, authorization, and retention (`e2e/tests/operator-timeline-investigation-flow.spec.ts:660-811`, `operator-earned-flows.spec.ts:83-344`, `operator-route-states.spec.ts:418-963`). | Navigation and return-context behavior, query-string state, keyboard/touch operation, real denial, asynchronous pending/error states, and UI journeys against the example app. |
| Domain and HTTP proof | ConnCase tests and the demo contracts cover the host write path, action/correlation linkage, redaction, delete history, and auth/scoping (`examples/threadline_phoenix/test/threadline_phoenix_web/`, `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs:25-105`). | Database and host integration facts that a screenshot cannot prove. |

The example's Storybook is already kept out of product/runtime scope: `phoenix_storybook` is an example dependency restricted to `:dev` and `:test` (`examples/threadline_phoenix/mix.exs:62-82`) and is locked to 1.2.0 (`mix.lock:41`). Its routes are compile-gated by `:dev_routes`, outside `/audit`, and production config leaves them disabled (`lib/threadline_phoenix_web/router.ex:1-27`, `test/threadline_phoenix_web/storybook_route_test.exs:9-55`). The root Threadline package does not need Storybook.

The locked local PhoenixStorybook source matters for the design: version 1.2.0 supports `:component`, `:live_component`, and `:page` story types; its `:example` type is a child LiveView and cannot implement `handle_params/3` (`deps/phoenix_storybook/lib/phoenix_storybook/stories/story.ex:1-4,93-102`). Do not embed a routed operator LiveView as a story to simulate URL navigation. Keep Storybook stories as static/component state examples. Exercise route, filter, return URL, auth, export, and retention transitions through the example's real mounted host routes and Playwright.

## Coherent coverage model

Use four levels, with one owner for each kind of truth:

1. **Component state:** PhoenixStorybook examples with fixed assigns and explicit fixture provenance. Cover visual variants and individual state rendering. Reuse `ThreadlinePhoenixWeb.Storybook.Fixtures` and its allowlist of `Threadline.OperatorSurface.StressFixtures`; keep their current scoped purpose (`storybook/groups/operator_groups.story.exs:8-23`, `storybook/states/data_state.story.exs:8-21`).
2. **Composition:** the existing groups/patterns stories show repeated assemblies, such as toolbar + filters, data panel + state + pager, denied access, and inert destructive confirmation. Keep destructive examples inert here; the repo already contracts that they have no submit or pushed event (`storybook_stories_test.exs:195-208`).
3. **Host journeys:** browser tests use real seeded identities, routes, URL state, host callbacks, and actual actions. Each journey should name the actor/role, organization, starting fixture, route/query, action, expected destination and URL, persisted result or explicit denial, and recovery/return behavior. Add missing journey cases to `operator-journey-inventory.json`; do not duplicate it with another inventory.
4. **Domain contracts:** ExUnit/ConnCase proves capture, semantics, database results, redaction, tenancy policy, and reset invariants. Keep UI snapshots from standing in for these checks.

Do not build the full Cartesian product of every component state × route × role × theme × viewport. Give each component state a stable fixture ID, then use a small risk-based set of journeys that cross the boundaries most likely to mislead or leak data: support vs admin, same-org vs other-org, direct entry vs in-app navigation, pending vs completed/failed, cancellation vs destructive confirmation, and populated vs empty/deleted/redacted data. The current browser suite already covers many of these. Extend where the new design introduces a control/state or the inventory reveals a distinct unproved failure class.

### JTBD anchors to preserve

- **Developer — “Did my normal Phoenix write get recorded?”** Use the existing first-write and audited ticket-reply walkthrough, checking the exact actor, transaction, changes, and action. The host wiring remains host-owned (`examples/threadline_phoenix/README.md:43-64`; `test/threadline_phoenix/demo_contract_test.exs:41-105`).
- **Support — “Who changed this ticket, what changed, and when?”** Keep ticket #4521 as the semantic close/reply story and #4518 as the deletion story; follow Timeline → transaction → row history and retain useful identity after deletion (`DEMO-MANIFEST.md:27-32,64-79`).
- **Platform/operator — “Can I find the gap or sensitive field without being granted broader access?”** Use scoped support identities against the actual authorization callback; coverage, evidence, export, and policy denials stay distinct from empty, unavailable, and loading states (`DEMO-MANIFEST.md:80-94`; `lib/threadline_phoenix_web/router.ex:111-170`).
- **SRE/operator — “What happens when export or retention is waiting, unavailable, denied, canceled, or complete?”** Reuse the seeded export statuses and retention run, plus real confirmation and cancellation journeys (`DEMO-MANIFEST.md:82-92`; `e2e/tests/operator-route-states.spec.ts:418-472,752-828`).
- **Developer/operator — “Does context survive a job or system write?”** Preserve the named service-account, job, system, and anonymous examples; show the recorded actor/source plainly and avoid implying that every user-initiated action maps to one row change (`DEMO-MANIFEST.md:96-113`; `prompts/audit-lib-domain-model-reference.md:65-95,135-151`).

## Demo and fixture findings

The example already has a useful representative dataset: three organizations; admin, agent, and support personas; about 50 tickets per organization; stable UUIDv5 identifiers; named hero tickets; multi-field diffs; redacted `internal_note_body` / reply bodies; a hard delete; job/service/system actors; scoped support access; and an offboarded organization at a retention end state (`examples/threadline_phoenix/DEMO-MANIFEST.md:7-45,58-106`, `WALKTHROUGH.md:158-175`). `demo.seed` fixes its PRNG seed and uses the manifest; reset truncates demo tables and invokes the seed (`lib/threadline_phoenix/demo/seed.ex:25-46`, `demo/reset.ex:125-139`). This is a stronger representative demonstration than generic decorative records because each hero record has an operator question and a path to inspect it.

Two small consistency defects should be corrected when fixture/docs work is in scope:

- `demo/manifest.ex:9-11` calls `2026-05-20` a Tuesday and describes it as “seven days before” the `2026-05-27` demo epoch; both calendar dates are Wednesday. `DEMO-MANIFEST.md:14-15` repeats the claim. Derive the human label from the frozen UTC anchor and test weekday plus relative date so labels such as “last Tuesday” cannot drift from the data.
- `DEMO-MANIFEST.md:62` says the one-command seed story is `mix demo.reset && mix demo.seed`, while `demo/reset.ex:3-6,125-139` says `mix demo.reset` already truncates and reseeds. Choose one canonical reset instruction; the second seed invocation is redundant and risks changing the intended fixture state.

The fixtures are synthetic demo fiction, not real customer records or adoption outcomes. Preserve that distinction in screenshots and copy. Before making data more “realistic,” make the scenarios internally true: organization scoping must agree with the actor; action labels must agree with row changes; dates, time zones, redaction, deletion, and retention must match what the code actually stores.

## Brand and boundary implications

Use the new brand assets/spec as the visual source of truth, not the older `prompts/Threadline Brand Book.txt` direction. The new `brand/BRAND.md` and `brand/brand.json` define a spool lockup, dark-default plus complete light theme, operation words that remain visible independent of color, exact type/palette roles, and the “calm, exact, honest” voice (`brand/BRAND.md:1-5,25-29,113-151,218-388,433-459`; `brand/brand.json:63-90,92-121,138-229,245-279,280-424`). The older prompt book still contains the pre-spool logo exploration and broader legacy palette (`prompts/Threadline Brand Book.txt:407-448,451-543`), so keep these documents from becoming competing implementation specs.

Apply Threadline branding to Threadline-owned surfaces, but keep the host app's auth, tenancy, route, and identity choices host-owned. The brand says a host can replace the lockup, and also records that the current product has no logo setting yet (`brand/brand.json:68-90,881-887`). That is a potential API/product decision, not a reason to sneak a new public component API into this UI pass. The active router demonstrates separate host callbacks for ordinary operator access, exports, evidence, coverage, policy, and tenant query scoping (`lib/threadline_phoenix_web/router.ex:111-170`).

Project scope matters: cached main says v1.47 retired the UI critic loop and v1.48 is next for “Safe by default,” including a fail-closed operator mount fix; operator UI is parked unless explicitly brought back (cached `origin/main:.planning/MILESTONE-ARC.md:1-26`). Do not restore the retired critic/checker system as a default. Treat the queued auth-mount fix as a security prerequisite if UI journeys touch authorization, and keep it distinct from visual polish.

## AI-assisted iteration and maintenance

- Give an AI implementer a story ID or journey-inventory row, named fixture and exact initial state, new-brand reference, affected component/route files, and a deterministic preview/capture recipe. Do not ask it to infer actor, tenant, status, date, or intended behavior from a screenshot.
- Capture Storybook for component/layout iteration and the actual host route for journey iteration. Attach route/story ID, seeded fixture version, dark/light/system preference, browser and viewport, and (when used) actual zoom to the screenshot/evidence bundle. Keep static captures advisory; route, database, policy and URL contracts remain deterministic code assertions.
- Prefer extending the existing fixture allowlist, demo manifest, state tests, and journey inventory. Avoid mirroring all stress cases into Storybook or writing a second scenario database; narrow examples are easier to review and less likely to drift.
- AI can propose copy/layout fixes and compare rendered captures against the supplied brand rules. Deterministic browser and domain tests decide whether behavior remains correct. Visual opinion remains review input; avoid paid critic/default pipeline creep.

## Dependencies and overlooked risks

This recommendation depends on the new brand assets/spec being the canonical edition and on the existing host-auth contract remaining unchanged. It should cohere with sibling work on the brand-token implementation, operator information architecture, and fail-closed mount baseline. Recommend Threadline Admin as the rendered name while retaining public API identifiers. A new host-brand override API would require a separate scope/compatibility decision; it is deferred from this migration.

Overlooked risks: misleading relative dates; a “reset” recipe that seeds twice; screenshots being mistaken for real customer evidence; a state catalog being mistaken for working flows; a Storybook route accidentally entering production or bypassing host authorization; brand color replacing operation text; action, transaction, and request being visually conflated; redacted data leaking through copy/export; and a new identity setting quietly turning a private component into a public API commitment.
