<!-- lens: density | version: 1.0.0 | sha8: 00000000 -->

# Density Rubric

> Persona-weighted lens. The persona pass-condition clause is in the uncached suffix, not here.
> Default verdict: FAIL. Hunt for chrome and verbosity that the primary task does not require.

## Dimensions

### 1. Signal-to-chrome

**Pass condition:** Every visible element on the page either advances the primary task or enables a secondary task that cannot be deferred to a detail view. If you can name one control, label, informational block, or structural element whose removal costs the primary task nothing — and that removal does not break navigation, trust signals, or auth context — the density FAILS.

**Adversarial test:** Apply the removal test: name a specific element you could remove without breaking the primary task. The adversarial move is to identify explanatory copy that repeats what the data already says, decorative separators that add no grouping information, or self-labeling chrome that describes the section rather than serving it. Navigation rails, auth indicators, and status signals that establish trust or orientation are not removable chrome — target informational blocks, repeated labels, and inline description copy instead.

**Evidence requirement:** Cite the selector or region of the element identified as removable chrome. A signal-to-chrome verdict without a located element is discarded.

---

### 2. Task-primary prominence

**Pass condition:** The primary task element or the most important data object on the page receives the greatest visual weight among interactive and data elements. If a secondary action — export button, filter toggle, bulk-select control, settings link — receives greater visual prominence than the primary task object, FAIL.

**Adversarial test:** Identify the secondary action or control that receives the most visual treatment on the page (largest rendered size, strongest accent color, most prominent position). Ask whether it outranks the primary task object in visual weight. If a filter bar, export control, or settings menu is more visually prominent than the audit row, coverage number, or actor record it supports, FAIL.

**Evidence requirement:** Cite the selector or region of the primary task element AND the secondary action claiming disproportionate visual weight (if found). Without both locators the finding is discarded.

---

## Reference bar

Linear (primary): Each Linear issue row packs primary metadata — title, status badge, assignee avatar — with one accent signal and two or three muted secondary data points. No explanatory copy appears alongside the row explaining what the row is. The UI trusts the operator to know the surface. Match this judgment: the data speaks for itself; self-describing copy is chrome.

Grafana (cautionary): A Grafana dashboard builder can surface panel titles, data-source labels, panel descriptions, value threshold legends, unit labels, and a refresh interval indicator simultaneously — most of which are accessible in a detail view. That density is the anti-model: the operator surface should never surface that many self-describing elements at the task level.

---

## Anchors

**Pass pole:** `refute.density.card-section-wrap.polished__dark-1280`
The polished density twin lets the data speak for itself: primary content is prominent with minimal chrome and no self-describing copy. Every element either is the data or navigates it.

**Fail pole:** `refute.density.card-section-wrap.flawed__dark-1280`
The flawed twin wraps the same content in extra card/section chrome that adds visual weight and nesting without task value, burying the primary content under structural packaging.
