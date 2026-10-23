# Phase 239 transaction composition and exact evidence research

## Recommendation

Use a semantic transaction summary followed by stacked, individually labeled change records. Pair field names with before/after values on wide screens; reflow each field into explicit “Before” and “After” rows on narrow screens and at actual 200% zoom. Keep semantic metadata in the existing definition-list/detail-header pattern, not a generic table. Preserve the existing stream of changes and `UI.Display`/`Presentation` contracts where they are truthful; make exact values independently visible/selectable when a compact token is abbreviated.

Suggested transaction summary order:

1. **Transaction**: full ID access, captured/committed time, count of changes and tables.
2. **Actor**: transaction `actor_ref`, explicitly separate from the linked action's `actor_ref` if that semantic record exists. If absent, say “Actor not recorded”; never substitute the action actor.
3. **Action**: show the optional linked `AuditAction` name and its own actor as action metadata, only when present.
4. **Execution context**: show recorded `source`/transaction metadata and action `request_id`, `job_id`, and correlation ID when populated. Label absent fields “Not recorded”; do not synthesize request/job/context from transaction identity.
5. **Changes**: one record per captured `AuditChange`, with operation, table, primary key, captured timestamp and field evidence. The transaction may have zero changes; retain the existing explicit “No row-level changes captured” state.

This uses fields and associations already returned by the existing incident bundle. It requires no fetch/API/query/routes or schema expansion. The bundle shape already contains the transaction, linked action and changes (`lib/threadline/investigation.ex:174-209`).

## Cardinality and attribution facts

- `AuditTransaction.action_id` is a nullable singular FK. One transaction links to zero or one action. The action association is virtual and hydrated by investigation reads, not owned by the capture schema. `AuditAction` may be linked to one or more transactions, as its own module documentation states. Sources: `lib/threadline/capture/audit_transaction.ex:20-44, 78-93`; `lib/threadline/semantics/audit_action.ex:3-8, 22-34`.
- Transaction `actor_ref` is independently nullable and set from the transaction-local `threadline.actor_ref` GUC. Action `actor_ref` is also independently stored. The current transaction page displays the transaction's actor, action name, and action correlation ID; it does not merge the two actors (`lib/threadline/operator_surface/live/transaction_live.ex:177-205, 326-344`).
- The action may be absent even when the transaction and row changes exist. The linked action is optional and semantic; it is not another change row and must not be presented as one transaction per action. Threadline's domain model also explicitly distinguishes action/change, transaction/request, and user/actor (`prompts/audit-lib-domain-model-reference.md:91-93, 104-112, 135-145`).
- Existing context fields include `AuditTransaction.source`/`meta`, and `AuditAction.request_id`, `job_id`, `correlation_id`, `reason`, and `comment` (`lib/threadline/capture/audit_transaction.ex:12-24, 78-99`; `lib/threadline/semantics/audit_action.ex:40-76`). Their presence in schemas does not mean every captured record populates them.

## Exact-value access gap and recommended control

The current abbreviated presentation does not provide a dependable full-value reading path for JS-enabled users. `UI.Display.ref/1` renders a shortened code token and sets the full string in `title` and `data-tl-copy`; the separate “Copy” button only exists when `Script.enabled?()` (`lib/threadline/operator_surface/ui/display.ex:154-181`). A tooltip/title and a `datetime` attribute are not visible selectable evidence, and a copy action that depends on JavaScript belongs to Phase 240's fresh-entry/rebinding work. Likewise, `Presentation.value_token/1` puts long string values and exact datetime strings in `title`, while `transaction_live.ex` renders a relative human time with its exact timestamp in `title` and `datetime` (`lib/threadline/operator_surface/presentation.ex:98-115, 400-464`; `lib/threadline/operator_surface/live/transaction_live.ex:201-205, 224-231, 254-276`).

Phase 239 should provide complete visible/selectable access independent of the Copy helper—for example, a native `<details><summary>Show full transaction ID/value/timestamp</summary><code>…</code></details>` disclosure beside an abbreviated token, or a persistently visible exact timestamp alongside the friendly time. Ensure the disclosure is keyboard-focusable/operable, touch reachable, and still works when the delegated Copy script is unavailable. Preserve full-value copy as a convenience; Phase 240 separately proves copy lifecycle and failure feedback. At 200% zoom and narrow widths, reflow this content and avoid clipping. Do not use hover-only title text or treat text stored in an HTML attribute as reader-accessible proof.

Security boundary: render only the authorized, already-redacted values supplied by the current bundle. Do not add an alternate full/raw read or copy path. Null remains `null`; a missing axis remains the explicit `(omitted)`/`(absent)` marker; redaction stays `[REDACTED]` and must never reveal the raw value. Current helpers explicitly differentiate null, sentinel redaction, missing before/after axes, and use the copy exclusions for null/omitted/absent (`lib/threadline/operator_surface/presentation.ex:400-420, 448-464`; `lib/threadline/operator_surface/live/transaction_live.ex:357-369`). The no-row-change state is distinct from a transaction with a found row change lacking field-level evidence (`transaction_live.ex:124-138, 245-252`).

A transaction not found is ambiguous under current APIs: the lookup returns `{:error, :not_found}` and the UI says it may not exist or may have been pruned (`transaction_live.ex:97-119`; `lib/threadline/investigation.ex:174-209`). Keep that honest: state that the record was not found and the lookup cannot distinguish never-existed/out-of-scope from pruned; do not claim pruning as fact or add a backend lookup. Keep permission/scope behavior server-authoritative. Existing tenant-scope contract test verifies out-of-scope transactions are hidden as not found (`test/threadline/operator_surface/transaction_live_test.exs:651-657`).

## Viable layouts

| Option | Pros | Cons | Complexity | Recommendation |
|---|---|---|---|---|
| Semantic summary + stacked change records; paired before/after on wide screens, labeled stack on narrow | Preserves transaction/action/actor/context distinction; fits native definition-list metadata and row-level evidence; naturally reflows | More vertical reading for long transactions | Existing LiveView + CSS edits; risk: scroll distance/context | Rec for equal support/operator and engineer needs across widths |
| Semantic summary + side-by-side before/after everywhere | Fast visual comparison on desktop | Crowded at narrow widths/zoom; long values can force page-wide overflow | Diff layout changes; risk: clipped text, unclear axis when wrapping | Rec for desktop-centric workflow only if it becomes labeled stacked content below a breakpoint |
| Responsive native data table | Strong column scanning; existing `UI.Data.data_table/1` supports native table semantics and mobile `data-label`s | Transaction changes have variable field evidence and per-value actions; table encourages dense columns and horizontal scanning | Convert stream and diff into table; risk: accessibility/reflow and awkward nested evidence | Rec only if current data needs prove uniform enough for tabular comparison |

## Code observations (not visual claims)

- Transaction header currently uses `UI.Page.detail_header` metadata at `lib/threadline/operator_surface/live/transaction_live.ex:163-207`. It shows transaction ID, transaction actor, optional action name, tables/change counts, action correlation, and a friendly captured time. It omits source/request/job context already available in the loaded structs.
- Change presentation is streamed, one `.tl-change` record at a time; per field it conditionally renders before then arrow then after (`transaction_live.ex:215-285`). This existing composition makes a responsive paired/stacked diff a low-surface decision.
- `UI.Display.ref/1` deliberately binds the full ref to `data-tl-copy`; with script disabled the code value is full (`ui/display.ex:154-181`). With script enabled it is abbreviated. This is a convenience contract, not an accessible full-value display contract.
- `Presentation.human_time/2` uses UTC and includes “UTC”; `exact_time/1` produces ISO 8601 (`presentation.ex:1-34`). The current semantic `<time datetime=...>` is accurate machine metadata but does not make exact text visibly readable or selectable.
- `UI.Data` has distinct loading, no-data, unauthorized, source-down, redacted and pruned states with descriptive copy (`lib/threadline/operator_surface/ui/data.ex:191-249`). Use these existing distinctions; transaction lookup itself cannot identify pruned vs nonexistent.

## Existing source/test references

- `lib/threadline/operator_surface/live/transaction_live.ex:97-155` — missing transaction, zero changes, history drawer composition.
- `lib/threadline/operator_surface/live/transaction_live.ex:163-210` — metadata hierarchy/current actor-action-context gap.
- `lib/threadline/operator_surface/live/transaction_live.ex:215-285` — streamed per-change and before/after structure.
- `lib/threadline/operator_surface/live/transaction_live.ex:326-369` — actor labels/paths, optional action and correlation extraction, exact time conversion, copy exclusions.
- `lib/threadline/operator_surface/presentation.ex:1-34, 47-115, 395-464` — human/exact timestamp formats, ID/ref truncation and value state tokens.
- `lib/threadline/operator_surface/ui/display.ex:154-181` — full identifier's current title/copy/JS-disabled rendering.
- `lib/threadline/operator_surface/ui/data.ex:191-249` — state taxonomy and copy.
- `lib/threadline/capture/audit_transaction.ex:1-44, 62-99`; `lib/threadline/semantics/audit_action.ex:1-34, 40-83` — cardinality, independent actor refs, available context fields.
- `lib/threadline/investigation.ex:174-209` — existing transaction/incident bundle reads and result shapes.
- `test/threadline/operator_surface/transaction_live_test.exs:90-174` — not-found, header and zero-change cases.
- `test/threadline/operator_surface/transaction_live_test.exs:327-413` — insert/update rendering, null/redacted timestamps, no field-level evidence.
- `test/threadline/operator_surface/transaction_live_test.exs:415-525` — full ID/correlation copy targets and definition-list contract.
- `test/threadline/operator_surface/transaction_live_test.exs:527-577` — long before/after values and copy targets.
- `test/threadline/operator_surface/transaction_live_test.exs:651-689` — out-of-scope transaction/history content remains hidden.
- `test/threadline/operator_surface/presentation_test.exs:164-244` — ref truncation, full/title equality, timestamp-kind non-truncation.
- `test/threadline/operator_surface/ui_test.exs:940-1017` — explicit redacted/pruned data state copy and distinct state identity.
- `.planning/REQUIREMENTS.md:15-29, 47-65` — UIS-02/03, UII-03, UIA-01/03/04 requirements and acceptance constraints. There is no phase-local Phase 239 REQUIREMENTS.md; the approved requirement definitions are in this global file.
- `.planning/ROADMAP.md:78-92` — Phase 239 goal, requirement mapping and success criteria.
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-HANDOFF.md` — source/worktree custody and Phase 239 ownership.

## Accepted visual evidence, kept separate from code observations

Phase 238 reports an accepted direct `/transactions/:id` seeded capture at 1280, 768, and 375 CSS-pixel widths (`.planning/phases/238-current-main-preview-and-acceptance-baseline/238-BASELINE-FINDINGS.md:240`; capture mapping in `238-EVIDENCE-INDEX.md:112`). It describes a bounded shell review and explicitly does not establish full keyboard/theme/200%-zoom acceptance. I did not inspect new screenshots in this research. Do not present source-only findings above as visual defects. The Phase 238 UI review states actual browser-chrome 200% zoom remains unverified (`238-UI-REVIEW.md`, Evidence and Limitations).

## Primary external sources

- W3C, [WCAG 2.2 Understanding Reflow (1.4.10)](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html): ordinary content should reflow; genuinely two-dimensional material can use its own scroll container while the rest of the page reflows.
- W3C, [WCAG 2.2 Understanding Resize Text (1.4.4)](https://www.w3.org/WAI/WCAG22/Understanding/resize-text.html): enlarged text must retain content and functionality; test magnification separately from a narrow viewport.
- W3C, [WCAG 2.2 Understanding Keyboard (2.1.1)](https://www.w3.org/WAI/WCAG22/Understanding/keyboard): functionality needs keyboard operation. A native disclosure or button/link is a suitable baseline for full-value access; also test touch reachability from the product's own requirements.
- Official prior art cited by the project preflight: [Phoenix LiveDashboard](https://phoenix-live-dashboard.hexdocs.pm/Phoenix.LiveDashboard.html) for host-protected operational inspection; [Oban Web v2.13 changelog](https://oban-web.hexdocs.pm/changelog.html) for operational detail layouts, empty states, and keyboard behavior. Borrow the behavior checks, not their domain/UI skin.

## Cohesion with sibling decisions

- Home/timeline entry and transaction content should use the same canonical noun “Transaction” and task language established in Phase 239's entry/navigation research. Timeline's transaction link should lead to this detail hierarchy without implying one action equals one transaction.
- Shared responsive/theme/focus contracts own the CSS and native-control treatment. Keep change evidence in the page-specific owner, but route full-value reveal through any shared display primitive only if the same pattern is truly used elsewhere; do not force every datum into the same component.
- Use the existing authorized `incident_bundle` result and `threadline_scope`/`scope_query_fn` inputs. Do not add endpoints, widen data access, expose unredacted values, change public routes/API, or alter Phoenix optionality.

## Unresolved decisions

None at architect level. A design contract still needs a measurable rule for when a value is abbreviated and a specific keyboard/touch-reachable full-value presentation. The accepted evidence must include an actual 200% browser-zoom pass separate from responsive viewport emulation.
