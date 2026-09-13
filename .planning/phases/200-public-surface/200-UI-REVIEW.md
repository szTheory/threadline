# Phase 200 — UI Review

**Audited:** 2026-09-12
**Baseline:** Abstract 6-pillar standards (no UI-SPEC.md)
**Screenshots:** Generated `doc/readme.html` inspected at desktop, tablet, and 375×812 mobile. Mobile evidence: page scroll width 375 px; Start-here table width and scroll width 335 px; stacked full-width cells; 16 px text with 27 px line height; loaded logo with 300 px natural width. Dark mobile evidence: background `rgb(3, 8, 18)`, text `rgb(216, 224, 233)` at 15.05:1 contrast, links `rgb(177, 165, 238)` at 9.06:1 contrast, and the dark logo rendered.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | The landing is concise, task-led, defines the evidence outcome plainly, and routes exhaustive contracts to their canonical references. |
| 2. Visuals | 4/4 | The branded landing, responsive intent grid, hierarchy, and native ExDoc navigation render correctly across audited widths. |
| 3. Color | 4/4 | Light and dark presentation are coherent, with verified high contrast and the correct theme-aware logo. |
| 4. Typography | 4/4 | Readable mobile sizing, wrapping, hierarchy, and intentional contract identifiers are all handled without overflow. |
| 5. Spacing | 4/4 | Mobile gutters, stacked rows, desktop content measure, and overflow behavior form a consistent responsive rhythm. |
| 6. Experience Design | 3/4 | Core documentation flows and states are strong; one explicitly accepted hosted non-maintainer rendering observation remains unproven. |

**Overall: 23/24**

---

## Top 3 Priority Fixes

1. **Close the accepted hosted GitHub outsider-render residual when practical** — local contracts and hosted API/public-content checks cannot show exactly what a logged-in non-maintainer sees — record one separate-account observation of issue forms, PR template, and private-report routing without changing the already accepted release disposition.
2. **Add a rendered responsive screenshot regression** — source contracts protect the injected CSS but not final browser geometry — retain the verified 375 px table/page measurements in an automated browser check when a stable hosted or generated-doc test lane is available.
3. **Add a rendered dark-theme regression** — current contrast and dark-logo evidence is strong but point-in-time — automate the verified body, link, logo, and diagram theme assertions when browser infrastructure is available.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

- The plain-language bridge at `README.md:36-37` now explains the practical operator question before introducing governance, posture, and verdict concepts. The prior Evidence-plane recommendation is resolved.
- Positive evidence: `README.md:13-19` opens with a concise benefit, domain context, primary API, and canonical next step. The four intent rows at `README.md:25-30` use active, differentiated verbs and descriptive destinations.
- Positive evidence: the Operator Surface copy is now bounded to capability, fail-closed ownership, theme behavior, one mount example, and canonical guide routes (`README.md:77-115`). Compatibility and lane details sit under Notes rather than blocking the opening.
- Exact API names and support-lane identifiers are intentional discoverability contracts, with exhaustive mappings routed to Domain reference and Upgrade Path rather than expanded inline.
- No generic Submit/Click Here/OK/Cancel/Save CTA pattern was found in the public documentation corpus.

### Pillar 2: Visuals (4/4)

- The generated `doc/readme.html` contains the theme-aware `<picture>`; runtime evidence confirms the logo loads at 300 px natural width and switches to the dark asset.
- The Start-here table becomes four full-width grid rows below 640 px, visually repeating “Start here” and “Then read” for each lane (`mix.exs:539-595`). At 375 px it measures 335 px wide with equal scroll width, proving no horizontal clipping.
- Desktop and tablet preserve a clear wordmark/H1/H2 hierarchy, visible search, grouped sidebar navigation, a restrained content rail, and contained code surfaces. No visual defect remained in the audited states.

### Pillar 3: Color (4/4)

- Dark mobile rendering was directly verified: `rgb(216, 224, 233)` body text on `rgb(3, 8, 18)` produces 15.05:1 contrast, and `rgb(177, 165, 238)` links produce 9.06:1. Both comfortably exceed WCAG AA thresholds.
- The light surface uses neutral backgrounds with purple action/link emphasis and the Threadline blue wordmark as its brand anchor. Accent is reserved for actionable or identifying elements rather than decorative saturation.
- Native ExDoc theme variables remain intact; Mermaid follows body theme state (`mix.exs:524-526`, `mix.exs:615-627`), and the correct dark logo was observed. No color defect remained in the audited states.

### Pillar 4: Typography (4/4)

- Exact module and support-lane identifiers are intentional, limited to contract/discoverability contexts, and paired with canonical reference links; they are not a typography defect.
- Positive evidence: direct 375×812 inspection confirms 16 px body/table text with 27 px line height and no page overflow. Headings, prose, inline code, and code blocks remain clearly differentiated.
- Positive evidence: balanced heading wrapping and improved paragraph/list wrapping are injected at `mix.exs:529-537`, preventing awkward narrow-layout breaks without shrinking text.

### Pillar 5: Spacing (4/4)

- The native 20 px mobile gutters produce a measured 335 px content/table width inside the 375 px viewport. Responsive rows use 1 rem separation, 0.75 rem internal gaps, full-width cells, and clear dividers (`mix.exs:556-576`).
- The visually hidden table header remains available to assistive technology while per-cell pseudo-headings restore context (`mix.exs:546-595`). Desktop/tablet content measure and section spacing remain consistent.
- Code and Mermaid surfaces constrain their width and scroll internally where needed (`mix.exs:511-522`). No spacing or overflow defect remained in the audited states.

### Pillar 6: Experience Design (3/4)

- **WARNING — accepted residual:** GitHub's login gate prevented observation of the exact issue-form, PR-template, and private-advisory UI through a separate logged-in non-maintainer identity. Default-branch files, hosted API/public-content behavior, 100% community health, enabled private vulnerability reporting, and signed-out routing passed; the maintainer explicitly accepted the remaining observation gap. This review preserves that limitation and does not claim the outsider session occurred.
- Positive evidence: mobile intent navigation works without zooming or panning. The visible Quick destinations links at `README.md:128-131` expose Evaluate, Adopt, Operate, and Contribute before the exhaustive “All guides” disclosure, resolving the prior terminal-navigation finding.
- Positive evidence: native ExDoc provides search, responsive sidebar navigation, focus-visible styling, and reduced-motion handling. Mermaid uses SRI and strict mode, re-renders on theme changes, scrolls wide output, and exposes source if CDN/rendering fails (`mix.exs:605-688`).
- Positive evidence: responsive behavior is contract-guarded in `test/threadline/code_walkthrough_doc_contract_test.exs:149-157`. The reported focused suite has 87 passing tests; docs warnings-as-errors and formatting pass. Registry safety is inapplicable because `components.json` is absent.

---

## Files Audited

- `README.md`
- `mix.exs`
- `test/threadline/code_walkthrough_doc_contract_test.exs`
- `doc/readme.html`
- `.planning/phases/200-public-surface/200-VALIDATION.md`
- `.planning/phases/200-public-surface/200-SECURITY.md`
- `.planning/phases/200-public-surface/200-14-SUMMARY.md`
- `.planning/phases/200-public-surface/200-UI-REVIEW.md` (prior review, superseded in place)
