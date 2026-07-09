<!-- lens: typography | version: 1.0.0 | sha8: 00000000 -->

# Typography Rubric

> Default verdict: FAIL. Hunt for role ambiguity and scale that does not express semantic hierarchy.
> The mechanical layer checks type-size count, minimum sizes, and font-token conformance. Judge ROLE differentiation and semantic scale, not size values.

## Dimensions

### 1. Role differentiation

**Pass condition:** Each text role on the page — heading, label, value, metadata, action copy — is visually distinct from adjacent roles without relying on size alone. If the only cue distinguishing a label from its value is positional proximity, FAIL. If a heading and body paragraph differ in only one property (size only, weight only), leaving them indistinguishable when rendered at the same size in imagination, FAIL.

**Adversarial test:** Identify a label-value pair. Mentally set both at the same size. Can you still tell which is the label and which is the value? If distinction collapses to position, FAIL. Then identify a heading and a body paragraph. Do they differ in at least two independent visual properties (e.g., size AND weight, or weight AND typeface family)? If they differ only in size, FAIL. Apply the Threadline type-role map: IBM Plex Mono is the signal for machine-readable identifiers (timestamps, IDs, table names, request IDs, diffs); Geist is prose; a label using Geist Regular at the same size as the body it labels is indistinguishable by role.

**Evidence requirement:** Cite the selector or region of the label-value pair or heading-body pair where role differentiation is insufficient. State which visual properties are used to differentiate and which are absent. Without a located pair and named properties, the finding is discarded.

---

### 2. Scale expresses hierarchy

**Pass condition:** The typographic scale is monotone with the semantic hierarchy — primary content (what the persona cares about first) renders at greater visual weight than secondary content, which renders at greater weight than metadata. If metadata type and primary content type approach equivalent rendered visual weight, FAIL.

**Adversarial test:** Identify the metadata elements on the page (timestamps, IDs, type labels, badges) and the primary content elements (action description, entity name, the primary data object). Compare their rendered visual weight. If a timestamp and an action title render at similar size AND weight, FAIL. If a badge label and a section heading render at equivalent visual prominence, FAIL. The scale must be readable as a strict rank order from primary through secondary to metadata.

**Evidence requirement:** Cite the selectors or regions of the metadata element and the primary content element. Describe their rendered visual properties using the mechanical evidence (font-size values if available) or observable weight and family differences. Without named elements and stated properties, the finding is discarded.

---

## Reference bar

Vercel (secondary): Vercel's deployment list uses a clear three-tier typographic scale: deployment name at primary weight (Geist SemiBold equivalent), branch and commit reference in a lighter mono treatment (signaling machine-readable identity), timestamp in a muted small label. Each tier is differentiated by at least two properties. The mono treatment for the commit hash signals role independently of size — it tells you "this is a machine identifier" without needing a label.

Stripe (secondary): Stripe's dashboard tables treat data values as primary and column labels as metadata. The label never outweighs the value it describes; it identifies without competing. Numeric values use tabular figures and a monospace or monospace-aligned treatment for scanning alignment.

---

## Anchors

**Pass pole:** `refute.typography.scale-collapse.polished__dark-1280`
The polished typography twin differentiates roles: heading, body, and label are distinguishable by size and weight, and the scale expresses a legible rank order.

**Fail pole:** `refute.typography.scale-collapse.flawed__dark-1280`
The flawed twin collapses the type scale: heading and body approximate the same size and weight, so size no longer signals importance and the roles blur together.
