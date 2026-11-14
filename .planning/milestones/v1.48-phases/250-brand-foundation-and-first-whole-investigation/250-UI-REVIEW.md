# Phase 250 — UI Review

**Audited:** 2026-11-12
**Baseline:** Approved Phase 250 UI-SPEC.md and signed-off Threadline brand
**Scope:** The bounded Timeline → transaction → ticket-prior snapshot/reply history → filtered Timeline return, plus the generated README/ExDoc first viewport.
**Screenshots:** Existing final matched screenshots inspected; no new captures. After capsule digest `80bdaa57b2e16669a995f0ea0e02ec40458b2113968682757adc22da313fd5ac`.
**Interaction captures:** No new interaction capture. Existing Plan08 keyboard/copy and final responsive gate evidence is referenced; native clipboard contents/permissions remain unverified.
**Source identity:** runtime revision `395f0b5afcfd0bd84f39a9dbe62dc9f01045c41c`, test revision `25fd5f854b26e39e7f2e652e97ec6bb05e6c8c62`; current root `74e9bb83faaaa5c416067286a43b2946025d92fd` adds test/inventory metadata only, with no pixel/runtime-source change.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Main journey copy and values match; the unavailable-transaction button still says only `Retry`. |
| 2. Visuals | 4/4 | Final captures confirm the drawer title and Timeline hierarchy corrections in both themes. |
| 3. Color | 4/4 | Both lanes follow the approved palette and operation colors; eight semantic contrast IDs pass current source-bound checks. |
| 4. Typography | 4/4 | Local brand faces load at the contracted 28/16/13px roles and remain readable at 1280/375px. |
| 5. Spacing | 4/4 | Drawer clears the fixed bar; mobile controls fit without horizontal overflow or clipping. |
| 6. Experience Design | 3/4 | The ordinary journey and keyboard copy path are complete; the rendered error/empty layouts were not part of the matched screenshot set. |

**Overall: 22/24**

---

## Top 3 Priority Fixes

1. **WARNING — Make the transaction retry action specific.** Change `Retry` to `Retry transaction` in `transaction_live.ex:176-178`; the adjacent sentence gives context, but the button label is generic.
2. **WARNING — Keep a rendered-state evidence set for empty/error layouts.** The source and Plan08 checks cover those states, but this visual pass did not inspect their layout. Capture them when those UI states next change; no current flow blocker is evidenced.
3. No additional priority visual fix remains: the former drawer-title and filter-emphasis findings are resolved by the final after captures.

---

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING:** The transaction-unavailable paragraph names the failed transaction, but its action remains the generic `Retry` (`lib/threadline/operator_surface/live/transaction_live.ex:174-178`). Use `Retry transaction` so the control remains clear when scanned alone. The surrounding sentence mitigates the ambiguity.
- Positive evidence: the ordinary journey shows the exact `ticket_replied_and_closed` action, actual `user/...` actor, UTC event time, `status` open/closed across the prior/current views, raw `closed_at` value, exact reply, and `[REDACTED]` internal note. Timeline empty copy and clipboard failure recovery copy match the contract in source; those states were not rendered in this pair.
- The transaction-origin history recovery copy is now explicitly declared in the current UI-SPEC.md, so the previous mismatch is resolved.

### Pillar 2: Visuals (4/4)

- Final `ticket-prior` and `reply-history` captures in dark/light show the drawer title below the fixed bar (observed geometry title top 80px, bar bottom 45px), with its copy control and focus ring visible.
- Final `timeline-restored` captures remove the heavy filter-panel and metric-tile treatments while retaining all controls and active predicates. The result card reads as the primary contained content; the earlier hierarchy warning is resolved.
- The generated docs light/dark screenshots show the supplied Threadline identity and approved plain-language opening without an assurance claim. No new visual defect was found in the requested checkpoints.

### Pillar 3: Color (4/4)

- Both theme lanes use the approved ground, surface, text, link, focus, and logo roles. Insert/update operation labels remain words as well as color chips; redaction remains explicitly labeled.
- Current source-bound gates report all eight approved contrast IDs measured in both effective lanes. Screenshot review is limited to the captured routes and does not establish a pixel-wide contrast audit of the full Admin.

### Pillar 4: Typography (4/4)

- Current loaded-font evidence reports all four local WOFF2 faces loaded. The contract roles are visible in the final captures: Familjen Grotesk 28px/600 headings, Geist 16px/400 body text, and IBM Plex Mono 13px/400 identifiers.
- At 1280px and 375px the recorded values, filters, and actions remain readable; long IDs are visually shortened while the full-ID controls remain available. Browser zoom was not verified.

### Pillar 5: Spacing (4/4)

- The corrected drawer starts below the app bar and keeps its header, close action, ID/copy controls, and snapshot content in view. Its body can extend vertically without hiding the relevant fields.
- At 375px the search fields and active-filter values stack and wrap within the viewport; the result actions may require a short vertical scroll, but no horizontal overflow or clipped control appears. This is expected responsive flow, not a task blocker.

### Pillar 6: Experience Design (3/4)

- The matched after journey reaches the actual transaction, prior ticket snapshot, reply history, in-drawer copy control, and returned Timeline with the original date/table/correlation predicates restored. Keyboard focus is visible on the copy control; current Plan08 evidence covers deferred copy success/failure and fallback behavior.
- **WARNING (visual evidence limit):** Empty, unavailable, and loading/error layouts are represented in the source and Plan08 checks but are not among the inspected matched screenshots. Their runtime state handling is not called broken; their visual hierarchy was not independently observed here. Native clipboard behavior and permission handling remain outside the evidence boundary.
- This read-only journey has no destructive action, so no destructive confirmation is expected.

---

## Registry Safety

N/A. The approved UI-SPEC lists custom Phoenix components and no shadcn or third-party registry. No registry/dependency was introduced; no registry audit was run.

---

## Files and Evidence Audited

- `.planning/phases/250-brand-foundation-and-first-whole-investigation/250-UI-SPEC.md`
- `.planning/phases/250-brand-foundation-and-first-whole-investigation/250-08-PLAN.md` and `250-08-SUMMARY.md`
- `brand/BRAND.md`, `brand/brand.json`, `brand/assets/README.md`
- `lib/threadline/operator_surface/components/surface_header.ex`
- `lib/threadline/operator_surface/live/timeline_live.ex`
- `lib/threadline/operator_surface/live/transaction_live.ex`
- `lib/threadline/operator_surface/live/row_history_component.ex`
- `lib/threadline/operator_surface/script.ex`
- Final after captures: `captures/after/2026-11-12T22-54-49.492Z-c5a0a9cf-45aa-4b24-b1eb-7b9287d70d8d/` — transaction, ticket-prior, reply-history, and timeline-restored dark/light shell and content images.
- Fresh mobile screenshots: `gates/fonts-loaded/fonts-loaded-380c0780-5da2-480d-8cf9-40c1f4469b27-{shell,content}.png` and `fonts-loaded-8aae6958-1b0c-4d3e-aa56-d6dcd392caf8-{shell,content}.png`.
- Generated docs screenshots: `review/docs-light.png`, `review/docs-dark.png`.

The audit reuses current Plan08 source-bound evidence; it did not launch a browser, tests, or database. Browser zoom, native clipboard contents/permissions, native browser-tab favicon geometry, and human comprehension are unverified. Five unclassified requirement taxonomy signals and three descriptorless prohibitions remain flagged-unverified; this UI review does not resolve them or create a human acceptance gate.
