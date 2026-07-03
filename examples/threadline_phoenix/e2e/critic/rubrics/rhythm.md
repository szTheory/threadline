<!-- lens: rhythm | version: 1.0.0 | sha8: 00000000 -->

# Rhythm Rubric

> Default verdict: FAIL. Hunt for proximity grouping failures and cadence inconsistency.
> The mechanical layer checks pixel spacing values. Judge whether grouping communicates structure — not whether values are on a token grid.

## Dimensions

### 1. Grouping by proximity

**Pass condition:** Visually related elements are spatially closer to each other than to unrelated elements. A label must be closer to its own datum than to any other datum. Section groups must have larger inter-group gaps than intra-group gaps. If any label-value pair is ambiguous — where the label could plausibly belong to either the element above or below it — the grouping FAILS.

**Adversarial test:** Pick a label-value pair. Without reading the text, ask: purely from spatial arrangement, which datum does this label belong to? If the answer is not unambiguous, FAIL. Then pick any two adjacent but semantically distinct groups and ask: is the gap between these groups visually larger than the gap within either group? If not, FAIL. The mechanical layer confirms token values; you are judging whether those values communicate membership.

**Evidence requirement:** Cite the selector or region of the label-value pair or section boundary where proximity grouping is ambiguous. Without a locator, the finding is discarded.

---

### 2. Vertical-cadence coherence

**Pass condition:** Vertical spacing follows a legible cadence — the same or proportionally stepped rhythms between analogous sections. If you can trace the page top-to-bottom and name a section or element that breaks the cadence without a semantic justification (a double gap that does not correspond to a change in content type, or a collapsed gap between unrelated sections), FAIL.

**Adversarial test:** Trace vertical spacing from top to bottom of the visible content area. Identify the first anomalous gap — where spacing jumps larger or collapses smaller without a clear reason grounded in the content type or section boundary. If found, name the element and the anomaly (too large, too small, inconsistent with adjacent sections). A spacing anomaly that is semantically justified — an error callout that uses a larger margin to signal severity, a section divider that clearly separates a new zone — is not a FAIL.

**Evidence requirement:** Cite the region or selector of the element that breaks vertical cadence. State the before and after context (which elements precede and follow the anomaly). Without a located anomaly and context, the finding is discarded.

---

## Reference bar

Linear (primary): Linear's issue detail view maintains consistent vertical rhythm between the issue body, the comment thread, and the sidebar metadata panel. The gap between the issue body block and the first comment is the same as the gap between sequential comments — a legible vertical period. Section breaks use a thin horizontal divider rather than a doubled gap, making the grouping boundary explicit without disrupting the cadence.

Grafana (cautionary): A Grafana dashboard with multiple panel rows can have irregular panel heights and inconsistent vertical padding depending on content length. Each panel is padded individually rather than contributing to a shared grid period. This produces a visually chaotic cadence where each row looks like a separate decision. That is the anti-model for vertical-cadence coherence.

---

## Anchors

**Pass pole:** `page.home.happy__dark-1280`
The home shell view maintains consistent vertical rhythm across summary cards and navigation zones. The gap between card groups is visually larger than the gap between a card's title and its value. Section boundaries are legible; the cadence does not break.

**Fail pole:** `page.retention.error__dark-1280`
The retention error state introduces an error callout block with a materially larger vertical margin than the surrounding content sections. The cadence break — a double gap before and after the error block — is not proportional to the semantic weight of the error and disrupts the expected vertical period without a structural justification.
