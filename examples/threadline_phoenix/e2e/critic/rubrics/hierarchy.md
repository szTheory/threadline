<!-- lens: hierarchy | version: 1.0.0 | sha8: 00000000 -->

# Hierarchy Rubric

> Critic-only lens — no mechanical layer backstops hierarchy judgment. Highest-stakes gate.
> Default verdict: FAIL. Hunt for failure of each pass condition before arriving at a pass.

## Dimensions

### 1. Entry-point clarity

**Pass condition:** Shown cold, you can name exactly one element the eye lands on first, AND it is the element this persona's JTBD needs first. A page with no single dominant visual anchor FAILS. A page whose dominant anchor is chrome rather than task-primary content FAILS.

**Adversarial test:** Try to name a second element that competes for first attention at the same visual weight. If you can, the pass condition is not met — two candidates means no dominant entry point. Then ask whether the dominant element serves the persona's primary task or an administrative concern (navigation, status metadata, breadcrumbs). A mismatch between what is most visually prominent and what the persona needs first is a FAIL.

**Evidence requirement:** Cite the region or CSS selector that you identify as the dominant element. If a competing element is found, cite that locator as well. A finding asserted without a located region or DOM node is discarded.

---

### 2. Scan-path and reading order

**Pass condition:** Starting from the dominant entry point, your eye can follow a clear path through the next two to three elements in task-priority order. Each step serves the persona's JTBD in descending priority. A page where the second step lands on chrome (nav rail, breadcrumb trail, filter bar) before reaching the first task-relevant content FAILS.

**Adversarial test:** Trace the scan path from the dominant entry point. Name the second and third visual stops. If either stop is a meta-element — a filter, a secondary navigation link, a page label — that appears before the primary task content, FAIL. If the reading order jumps between unrelated visual weight levels non-sequentially, FAIL.

**Evidence requirement:** Name the first, second, and third visual stop in your scan path. Cite one region or selector per stop. A scan path stated without locators is discarded.

---

### 3. Emphasis discipline

**Pass condition:** Emphasis is applied to at most one element class at the primary level and does not cascade. If two unrelated elements both use a primary emphasis technique — bold weight, accent color, or large type size — simultaneously, neither can dominate and the hierarchy collapses. FAIL if you can point to two unrelated elements that both employ the same primary-emphasis signal.

**Adversarial test:** Identify the element using the strongest emphasis on the page (largest, boldest, most colorful). Then look for any other element at a similar emphasis level that is not semantically subordinate to it. If found, FAIL. Check whether a single element receives bold weight, accent fill, AND large type simultaneously — that element is over-emphasized to the point that it consumes the entire emphasis budget, leaving no contrast for the remaining hierarchy.

**Evidence requirement:** Cite the selector or region of the primary emphatic element AND the competing element (if found). Without both locators the finding is discarded.

---

## Reference bar

Linear (primary): Each row in Linear's issue list carries one accent signal — the status badge color — while the issue title, metadata, and identifier render at restrained weights. First glance lands on the issue title because it is the only element at primary weight; the scan path then follows to status, then to owner and cycle. No element fights for first position because the emphasis budget is reserved for exactly one signal class per row. Match that principle: one dominant, everything else in supporting role.

Grafana (cautionary): A Grafana alert overview can present multiple panel titles at equal primary weight, each with its own colored badge and its own count. Cold-glance entry-point is indeterminate — every panel competes. This is the anti-model for entry-point clarity and emphasis discipline.

---

## Anchors

**Pass pole:** `page.timeline.happy__dark-1280`
The timeline happy-path view at desktop resolves to a single dominant signal: the audit entry row action name at primary weight. Actor and timestamp follow at visually lower weight. The filter bar and pagination chrome sit at the periphery of the scan path and do not compete with the first visual stop.

**Fail pole:** `page.coverage.permission__dark-1280`
The coverage permission-denied view presents competing signals: a permission-denied callout block and the absent coverage table structure share visual territory. Neither the denial reason nor the recommended next action achieves unambiguous visual dominance at cold glance. Multiple elements of similar weight compete for first attention.
