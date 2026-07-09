<!-- lens: brand_fidelity | version: 1.0.0 | sha8: 00000000 -->

# Brand Fidelity Rubric

> Post-veto lens. Scored only after the brand-veto mechanical check passes (token-parity, dark/light parity). If the veto fires, this lens is not scored — the cell receives `vetoed: true`.
> Default verdict: FAIL. Hunt for generic SaaS aesthetic and copy that drifts from the Threadline voice register.

## Dimensions

### 1. Designed, not recolored

**Pass condition:** The page reads as a purpose-built operator surface for the audit domain, not a generic admin template filled with Threadline color tokens. A designed page shows structural choices specific to audit work: timelines, diff views, coverage indicators, evidence chains, or operational data tables that could not meaningfully belong to a generic product. If the layout would survive unchanged with a full palette swap into any SaaS color scheme, the surface is not designed — it is recolored. FAIL.

**Adversarial test:** Imagine replacing all Threadline brand tokens (Thread Blue, Signal Cyan, Ember, Fog, Graphite) with a flat gray palette. Does the layout still read as purposeful and audit-domain-specific? If the layout collapses into a generic admin dashboard, FAIL. Additionally, look for these recolored-template anti-patterns: cards wrapping page sections rather than repeated data items (cards for sections, not repeated items — a brand layout rule); gradient hero sections or decorative background fills; marketing-inflected callouts that appear inside operational views; or chrome that exists to establish brand presence rather than to serve a task.

**Evidence requirement:** Cite the selector or region of the element that reads as a generic template or recolored surface. Name the specific anti-pattern. Without a located element and a named anti-pattern, the finding is discarded.

---

### 2. Register and voice fit

**Pass condition:** All visible copy on the page matches the Threadline voice register: precise, operational, calm, technically literate, and uninflected. No copy uses marketing language ("powerful", "seamless", "next-generation"), vague affirmations ("you're all set", "great job", "everything looks good"), compliance-bureaucratic phrasing ("your data is secure", "industry-standard protection"), or generic-SaaS onboarding copy. Error states, empty states, and permission-denied states are informational and actionable — not apologetic, not promotional.

**Adversarial test:** Read every visible text element on the page. Find the first copy that does not match the Threadline voice: promotional language, apologetic empty-state messaging, generic-SaaS placeholder text, or copy that manages feelings rather than communicating operational facts. If found, FAIL. The test is the Threadline pressure-test doctrine: every piece of copy must either state an operational fact or provide an actionable instruction. Copy that does neither is off-register.

**Evidence requirement:** Cite the selector or region containing the off-register copy. Quote the exact text. Without a located element and a quoted text extract, the finding is discarded.

---

## Reference bar

Linear (primary): Linear's UI copy is terse and operational at every state. "In Progress", "Blocked", "Done" — not "Your work is moving forward." Empty states in Linear say what happened and what to do next, never what success feels like. Error states cite what failed, not what Linear is sorry about. The voice is identical across success, error, and empty states: precise, uninflected, and domain-specific.

Vercel (secondary): Vercel's deployment detail pages use domain-consistent language throughout: "Build Output", "Runtime Logs", "Deployment", "Edge Functions". An error state says what failed and where to find the log. No copy reframes operational states in marketing terms; no state apologizes for the state of the system.

---

## Anchors

**Pass pole:** `refute.brand-fidelity.mis-jobbed-accent.polished__dark-1280`
The polished twin keeps the brand's token discipline: accent and surface tokens are used per their documented roles, reading as purpose-built audit UI rather than a generic recolor.

**Fail pole:** `refute.brand-fidelity.mis-jobbed-accent.flawed__dark-1280`
The flawed twin mis-jobs the accent token, applying the brand signal color to a role it does not own, so the surface reads as a recolored/generic template rather than the intended brand register.
