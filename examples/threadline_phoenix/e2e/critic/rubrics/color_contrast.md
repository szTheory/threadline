<!-- lens: color_contrast | version: 1.0.0 | sha8: 00000000 -->

# Color Contrast Rubric

> Default verdict: FAIL. Hunt for hue job ambiguity and color-as-decoration rather than color-as-signal.
> WCAG numeric contrast ratios are mechanical layer territory (MODE A). Judge signal semantics: whether each hue communicates exactly one documented role.

## Dimensions

### 1. Color as signal

**Pass condition:** Every accent hue visible on the page maps to exactly one documented signal role, and that role is consistently applied throughout. No accent hue appears in two distinct semantic roles on the same page. Apply the Threadline palette job map: Thread Blue (`--tl-color-thread-blue`) = interface action, active states, primary CTA, selected path; Signal Cyan (`--tl-color-signal-cyan`) = correlation, live trace, connected flow, positive movement; Ember (`--tl-color-ember`) = diff emphasis and attention (not warning, not success); Warning (`--tl-color-warning`) = amber status states; Error (`--tl-color-error`) = red failure states; Success (`--tl-color-success`) = green positive states. If Thread Blue appears on an element that is not interactive or selected, FAIL. If Ember appears as a default warning rather than diff-emphasis, FAIL.

**Adversarial test:** For each distinct accent hue visible on the page, name its signal role as you observe it on this page. Then check that role against the documented palette job map above. A mismatch between observed use and documented role is a FAIL. Also check: does any hue appear twice in two different semantic contexts on the same page (e.g., Thread Blue on a button AND on an informational callout border)? If yes, the signal contract is broken — FAIL.

**Evidence requirement:** Cite the selector or region of the element using the misapplied or ambiguous hue. Name the documented role that hue is assigned to and the role it appears to serve in this instance. Without a located element and a named role conflict, the finding is discarded.

---

### 2. Accent-job discipline

**Pass condition:** Each accent hue appears only where its documented job is semantically present. Thread Blue does not appear on decorative borders, informational block borders, or any surface that is not an active interaction target or selection indicator. Ember does not appear on neutral information displays. If an accent hue is deployed to make a non-semantic element visually prominent — to add "pop" rather than to communicate role — FAIL.

**Adversarial test:** Enumerate every occurrence of each accent hue on the page. For each occurrence, ask: "Does this hue's presence here communicate the documented signal role, or is it decorating the element?" Decoration includes: using Thread Blue as a section border just to create visual interest, using Signal Cyan as a tag color that has no correlation semantics, or using Ember on text that is not a diff or attention marker. Any decorative use is a FAIL.

**Evidence requirement:** Cite the selector or region of the accent hue occurrence that fails job discipline. Name the documented role the hue is assigned and describe the observed use that deviates from that role. Without a located occurrence and a named role mismatch, the finding is discarded.

---

## Reference bar

Vercel (secondary): Vercel's deployment status badges use exactly one hue per state — green for success, red for failure, gray for pending or cancelled. No accent hue appears in more than one semantic state. The primary CTA uses a distinct interactive blue that never appears on status indicators, and status indicators never reuse the CTA color. Each hue has one job; no hue decorates.

Stripe (secondary): Stripe's dashboard distinguishes primary CTA (blue), danger actions (red), and neutral informational states (gray or amber) without ever repurposing a hue across categories. A risk indicator never uses the same color as an action button. Color communicates category, not aesthetic emphasis.

---

## Anchors

**Pass pole:** `refute.brand-fidelity.mis-jobbed-accent.polished__dark-1280`
The polished twin reserves the accent hue for its one documented job, so color reads as meaningful signal rather than decoration. (Stand-in pole: no dedicated `color_contrast` refute twin exists yet — the mis-jobbed-accent twin isolates an accent/color-signal failure.)

**Fail pole:** `refute.brand-fidelity.mis-jobbed-accent.flawed__dark-1280`
The flawed twin mis-jobs the accent — applying the signal color to a role it does not own — so color stops mapping to meaning and the signal hierarchy blurs. (Stand-in pole; see the note on the pass pole.)
