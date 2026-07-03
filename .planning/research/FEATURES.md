# v1.40 Feature Landscape — Adversarial Multi-Lens UI/UX Evaluation & Forward-Only Iteration Harness

**Domain:** Automated, adversarial, LLM-plus-mechanical critique system for the `/audit` operator surface, driving a monotonic (forward-only) quality ratchet toward award-winning, on-brand craft.
**Researched:** 2026-07-02
**Downstream consumer:** v1.40 requirements definition — categorize into requirement groups with complexity + dependency notes.

---

## 0. Where This Starts (do not rebuild what exists)

Threadline already ships most of the *substrate* an evaluation harness needs. v1.40 is not a greenfield build — it is **wiring adversarial critics and a graphic-design lens onto existing rails**. Confirmed in-repo:

| Existing asset | What it already gives us | File |
|---|---|---|
| **Scored ledger + ratchet rule** | `.planning/design-system-ledger.json` — per-entry `current_score` / `ratchet_score` / `target_score` (90), "scores may only stay level or increase," enforced by a test. **This IS the monotonic quality ratchet.** | `.planning/design-system-ledger.json`, `test/threadline/operator_surface/stress_ledger_test.exs`, `DESIGN-SYSTEM.md` |
| **Stress lab** | `/audit/__stress?story=...` renders every component/page × state (happy/empty/error/loading/permission/boundary/advanced) from static ugly-data fixtures — deterministic, network-free critique targets. | `lib/threadline/operator_surface/stress_fixtures.ex`, `stress_router.ex`, `stress_live.ex` |
| **Token grid** | 4px-base spacing scale (`--tl-space-1..12` = 4/8/12/16/20/24/32/40/48), typographic scale (xs/sm/body/label/ui/heading/title/display), radius scale, motion tokens — all in `style.ex`. Mechanically greppable. | `lib/threadline/operator_surface/style.ex` (4501 lines) |
| **Brand pressure-test rubric** | 15 dimensions × 1–10 (150), **"self-assessment banned: every score cites a mechanical output"** — the exact philosophy to extend to UI critique. | `brandbook/pressure-test.md` |
| **Personas + JTBD + flows, LOCKED** | P1–P5, J1–J11, EF1–EF5, Flows A–D — already the persona set the adversarial critics need. | `.planning/milestones/v1.31-PERSONAS-IA.md` |
| **E2E lenses** | Playwright specs for accessibility, motion, responsive/mobile-first, stress, screenshot-regression + snapshots. | `examples/threadline_phoenix/e2e/tests/` |

**Strategic consequence:** the ledger's flat `62/72` current scores are a *single* opaque number per entry. v1.40's core move is to **decompose that one number into a per-page × per-persona × per-lens scorecard** and let adversarial critics (not self-assessment) populate it — while keeping the existing ratchet enforcement. Everything below is framed against that reality.

---

## 1. Personas & JTBD — One Adversarial Critic Per Persona

The personas are already locked (`v1.31-PERSONAS-IA.md`). Each becomes an **adversarial critic hat** that reviews every page *in that persona's arrival context* and scores task-completion friction. The critic's job is to fail the page for *its* persona, not to be charitable.

| Critic (persona) | The job it defends | Top friction it hunts for | "Task success fast" = | How it scores |
|---|---|---|---|---|
| **C-P1 Incident Responder** (on-call eng) | "What changed, when, who — then pivot." Arrives *with a handle* (record id / correlation_id / table / window). | Any step between landing and the first pivot; correlation-id paste not accepted on Home; Row-history buried; actor pivot >1 click. | Handle → attributed change → actor/row pivot in **≤3 clicks, zero scroll-to-find**. | Click-count-to-answer, scroll cost, dead-end count, time-to-first-pivot. Penalizes browse-when-you-arrived-with-a-key. |
| **C-P2 Support Agent** (verify a claim) — *most easily overwhelmed* | Plain-language, actor-attributed history for **one record**, then exit to a ticket. | Table-name filter datalist they can't populate (a wall); jargon; no record-first entry; no copy/export exit. | Record id → readable "who changed what when" → copy to ticket, **no filter-building, no schema knowledge**. | Reading-level / jargon count, "can a non-engineer complete unaided?" binary, exit-affordance presence, progressive-disclosure adherence. |
| **C-P3 Compliance / Security Reviewer** | Defensible proof verdict + a downloadable artifact for a third party. | Proof narrative broken across screens; export split (Timeline side-action vs Exports monitor) with no "audit package" flow; verdict vocabulary unexplained. | Question ("is control C enforced?") → verdict (proven/inferred/unsupported) → **one coherent export handoff**. | Provenance completeness, verdict legibility, export-loop closure, artifact defensibility. |
| **C-P4 Audit Operator / SRE** | "Is the audit system itself healthy and complete?" | Health signal noisy when green; coverage gaps / redaction drift / failed retention not scannable; no deep-link to the offending screen. | Scan health row → **only** dwell if something is red → deep-link → resolve → back. | Signal-to-noise of the health row, scannability, drill-to-fix path length, false-alarm rate. |
| **C-P5 Adopter Developer** (first mount) — *secondary* | Confirm data + scoping work on first mount; read empty states as diagnostics. | Empty states that don't say *why* or *what next*; missing CLI/API echo; scope chip ambiguous. | Empty state tells them the exact `mix threadline.*` command / next move. | Empty-state-as-diagnostic coverage, microcopy precision, orientation clarity. |

**Cross-cutting scoring dimensions every persona critic emits** (this is the friction rubric):

1. **Task-completion friction** — clicks, scrolls, form-fields, and page-loads between arrival and job done (lower = better; ties to Fitts/Hick, §3).
2. **Discoverability** — can this persona *find the entry point* without being told? (Weakest known gaps: J4 record-first, J2 row-history-as-entry — already flagged.)
3. **Self-documentation** — does the screen explain what it answers and what to do next, *in the user's voice*? (Evidence's "What can Threadline prove right now?" is the exemplar bar.)
4. **Information scent** — do labels/links predict their destination so the persona commits confidently? (Nav labels, card CTAs, trust-rail cross-links.)

Each scored 0–100, per page, per persona. A page's persona-score is only as high as its *worst-served arriving persona* on that page (see §4 aggregation rule).

---

## 2. Graphic-Design / Visual-Quality Critic — the "Award-Winning" Lens

A dedicated critic hat that owns *elegance vs accidental*, *restraint / low-clunk*, and *on-brand craft*. The decisive design decision: **split every dimension into MECHANICAL (deterministic, gate-able, no LLM) vs LLM-VISION-JUDGED (rubric-scored from screenshots).** Mechanical checks are the ratchet floor; the vision critic scores what mechanics cannot see. This mirrors the brand pressure-test's proven "every score cites a mechanical output" doctrine (`pressure-test.md`) and UICrit's split of design quality into *usability + aesthetics* ([UICrit, UIST 2024](https://people.eecs.berkeley.edu/~bjoern/papers/duan-uicrit-uist2024.pdf)).

### 2a. Mechanically checkable (deterministic — build these first, they anchor the ratchet)

| Dimension | Mechanical check | Source of truth |
|---|---|---|
| **Token-grid conformance** | Every spacing/padding/gap value resolves to a `--tl-space-*` step (4/8/12/16/20/24/32/40/48); flag raw px off the scale. | `style.ex` scale; grep/AST of computed styles |
| **Spacing on the scale** | No off-grid margins; consistent rhythm (vertical baseline multiples). | 4px base grid |
| **Typographic scale conformance** | Font sizes ∈ {xs,sm,body,label,ui,heading,title,display}; no ad-hoc sizes; ≤ N type sizes per page. | typo tokens |
| **Radius / shadow / motion token conformance** | Radii ∈ radius scale; shadows ∈ shadow tokens; transitions ∈ motion tokens; reduced-motion honored. | radius/shadow/motion tokens; existing motion e2e |
| **Color/contrast (WCAG)** | Text ≥ 4.5:1 (AA), large ≥ 3:1, non-text/UI ≥ 3:1, focus ring ≥ 3:1 — both dark & light lanes. | Existing a11y guards, alpha-aware compositing parser (v1.36) |
| **Control count / clunk budget** | Count interactive controls per page vs a budget (Hick's law); flag control-count regressions. | DOM count |
| **Scroll cost** | Above-the-fold answer presence at 375/768/1280; measured page height vs viewport. | Existing responsive e2e |
| **Palette restraint** | Single-accent discipline — count of distinct accent hues in use ≤ threshold (the Linear/Raycast "one accent" rule). | computed styles |
| **Alignment (mechanical subset)** | Shared left edges / gutter conformance to `--tl-shell-gutter`; grid-column adherence. | layout tokens |

### 2b. LLM-vision-judged (rubric-scored from stress-lab screenshots)

Scored 1–10 per dimension against a **written pass condition** (pressure-test style), from a full-page screenshot of a `/audit/__stress` story. These are the dimensions mechanics *cannot* see:

| Dimension | What the vision critic judges | Pass-condition shape |
|---|---|---|
| **Spacing rhythm & breathing room** | Does whitespace feel intentional, not cramped or cavernous? Grouping via proximity reads correctly. | "Related elements are visibly closer than unrelated ones; no element is starved or marooned." |
| **Visual hierarchy** | Can you find the lead answer in <1s? Primary vs secondary differentiated by size/weight/color/space. | "The page's lead question is unmistakably dominant; supporting data recedes." (Linear/Stripe "lead question at top" bar.) |
| **Alignment & optical order** | Edges, baselines, optical centering read as deliberate; no accidental jog. | "No element appears misaligned to a human eye at 1280px and 375px." |
| **Density calibration** | Right amount of information — not enterprise-dashboard clutter, not empty. | "Every visible element justifies its pixels; nothing feels crammed above the fold." |
| **Elegance vs accidental** | Does it look *designed* or *assembled*? Restraint, consistency of treatment. | "A designer would recognize this as intentional; no orphaned/default-styled control." |
| **Restraint / low clunk** | Low control count *feels* low; no verbose chrome; calm. | "A first-time operator is not visually overwhelmed; controls feel curated." |
| **Motion quality** | Transitions feel considered, not gratuitous; respects reduced-motion. | "Motion clarifies state change; nothing bounces/distracts." (paired with mechanical motion-token check) |
| **Brand adherence (visual)** | Reads as Threadline: night-infrastructure palette, single-accent, topstitch identity, "quietly confident." | "On-brand at a glance; matches brandbook mood." |

**Method note (from the research):** vision judging is subject to *verbosity/surface-fluency/self-enhancement bias* ([Appen rubric design](https://www.appen.com/llm-as-a-judge-rubric-design)); one dimension per rubric call improves consistency ([Learning to Judge, arXiv 2602.08672](https://arxiv.org/html/2602.08672v1)); **pairwise beats pointwise** and **reference-guided anchoring** raises reproducibility ([eugeneyan LLM-evaluators](https://eugeneyan.com/writing/llm-evaluators/), [References Improve LLM Alignment, arXiv 2602.16802](https://arxiv.org/pdf/2602.16802)). This directly shapes §4 and §5. The web-design dimension taxonomy (Global Aesthetics / Navigation / Section Layout / Interaction-Motion) from human-aligned visual rubrics ([WebVR, arXiv 2603.13391](https://arxiv.org/pdf/2603.13391)) validates the split above.

---

## 3. Classic Heuristic Lenses (fold in as additional critic hats)

These are *cheap, well-established, partly mechanical* — fold them in so the system isn't purely LLM opinion.

| Lens | What it adds | Mechanical vs judged |
|---|---|---|
| **Nielsen's 10 heuristics** | Visibility of system status, match-to-real-world, user control/undo, consistency, error prevention, recognition-over-recall, flexibility, aesthetic-minimalist, error recovery, help. One critic pass per heuristic. | Mostly judged; "consistency" partly mechanical via tokens. |
| **Gestalt** | Proximity/similarity/common-region/continuity — *validates grouping decisions*. Feeds the vision critic's "grouping reads correctly." | Judged (vision). |
| **Fitts's law** | Target size & distance for primary actions; small/close targets penalized. | Mechanical (hit-target px, distance). |
| **Hick's law** | Choice overload — control-count and nav-option budget per page. | Mechanical (count) + judged (feels overwhelming). |
| **Progressive disclosure** | Is complexity revealed on demand, not dumped? (P2's whole case.) | Judged + structural (drawer/subview presence). |
| **Accessibility (WCAG 2.2 AA + WAI-ARIA APG)** | Contrast, focus order, keyboard operability, reduced-motion, semantic tree, target size (2.5.8). | Mostly mechanical — *already* partly built (v1.37 a11y guards, accessibility-tree evidence). |

**Opinion:** WCAG/APG and Fitts/Hick should be **mechanical gates in the ratchet floor** (fail = block), while Nielsen/Gestalt/progressive-disclosure are **judged scores** feeding the scorecard. Don't LLM-judge what a contrast parser already proves.

---

## 4. Scoring & Findings Model

### 4a. The scorecard cube

Replace the ledger's single `current_score` with a **3-axis cube**: `page × persona × lens`.

```
score[page][persona][lens] ∈ 0..100    (with per-lens sub-dimensions 1..10)
lenses = { P1..P5 friction, graphic-design(mech+vision), nielsen, gestalt,
           fitts, hick, progressive-disclosure, a11y }
```

- **Page score** = weighted roll-up, but **gated by the worst arriving-persona score** (a page that fails P2 cannot score "excellent" even if beautiful). This encodes "task success fast for whoever actually lands here."
- **Persona score** across the flow (Flows A–D) = min/weighted of the pages on that persona's path — a flow is only as good as its worst step.
- **Ratchet score** per (page,lens) — the enforced floor, monotonic (§5).

### 4b. Rubric shape (per finding)

Every finding is a structured record (extends the ledger entry shape):

```
{ id, page, story_id/fixture_key, persona(s), lens, dimension,
  severity, score_before, evidence (screenshot ref | mechanical output line),
  pass_condition, proposed_change, status }
```

**Self-assessment banned** (inherit from `pressure-test.md`): every score cites a *screenshot* (vision) or a *mechanical output line* (grep/contrast/count). No naked opinion.

### 4c. Severity

| Severity | Meaning | Gate behavior |
|---|---|---|
| **Blocker** | WCAG fail, dead-end for a persona, off-token regression | Fails CI / blocks merge |
| **Major** | Task-friction regression, hierarchy failure, export-loop break | Must be triaged; blocks ratchet increase claim |
| **Minor** | Sub-optimal spacing rhythm, weak information scent | Design-debt register |
| **Polish** | Elegance/craft ceiling items | Backlog / aspirational |

### 4d. Design-debt register

A persistent, ranked list (like the ledger's `footgun.*` and `future.*` entries already do — `coverage-schema-card-declutter`, `transaction-page-left-push-desktop`, `theme-picker-idiomatic-ui`). Each debt: owner-page, severity, lens, reproduction (`/audit/__stress?story=...`), and a reopen trigger. This is the backlog the ratchet chews through.

---

## 5. Forward-Only Iteration Loop (the monotonic quality ratchet)

The loop, per (page, lens):

```
1. EVALUATE   critics score the current stress-lab render  → score_before
2. PROPOSE    critic emits a concrete, minimal change (one lever)
3. APPLY      change made (human or auto, see below)
4. RE-EVALUATE same critics, same fixtures, same viewports → score_after
5. GATE       accept ONLY IF: score_after ≥ score_before for THIS lens
              AND no other lens regressed below its ratchet floor
              AND all mechanical gates (WCAG/token/contrast) still pass
6. RATCHET    on accept, raise ratchet_score = max(ratchet, score_after)
              on reject, revert; log why in the ledger
```

**This is already half-built:** the ledger ratchet rule ("scores may only stay level or increase unless an explicit reset with rationale is recorded") + `stress_ledger_test.exs` enforcement is exactly step 5–6. v1.40 adds the multi-lens `score_before/after` and the *net-positive-across-lenses* guard so a beautiful change that breaks P2's task flow is **rejected**.

**Regression guard (no new regressions each change)** — three layers, all present or near-present:
- **Screenshot regression** (`operator-screenshot-regression.spec.ts` + snapshots) — pixel drift is visible.
- **Mechanical gates** (contrast, token conformance, control-count budgets, a11y tree).
- **Ratchet test** — numeric floor can't drop.

**Consistency of the judge (critical, from research):** LLM scores are noisy. Mitigate with (a) **reference-guided** scoring — anchor each judged dimension to a committed "reference bar" screenshot (§6) so the judge calibrates against a fixed exemplar ([References Improve LLM Alignment](https://arxiv.org/pdf/2602.16802)); (b) **pairwise before/after** rather than absolute pointwise where possible ([eugeneyan](https://eugeneyan.com/writing/llm-evaluators/)); (c) **position-swap + majority-vote over N runs** to damp non-determinism ([survey, ScienceDirect](https://www.sciencedirect.com/science/article/pii/S2666675825004564)); (d) require a **margin** (accept only if score_after ≥ score_before + ε) so judge noise can't ratchet the floor up on nothing.

**Auto-proposed vs human-in-the-loop (opinion):**
- **Auto:** mechanical fixes (snap value to nearest token step, fix contrast, remove off-grid px) — deterministic, safe to auto-apply behind the ratchet.
- **Critic-proposed, human-applied:** structural/visual changes (hierarchy, IA moves, copy) — the critic *writes the finding + proposed change*; a human (or a separate build agent) applies. Vision-judge accept/reject stays advisory on structural changes; the human holds the merge.
- **Never fully auto-merge** a vision-judged structural change — judge bias + non-determinism make an unattended aesthetic ratchet an anti-feature (§7).

---

## 6. Reference Bars (calibration anchors)

Concrete award-winning operator/admin UIs to (a) anchor the vision critic's rubric and (b) hold as reference screenshots for reference-guided scoring. *Why* each, mapped to Threadline's needs:

| Reference | Why it's the bar | What Threadline borrows |
|---|---|---|
| **Linear** | "Lead question answered in a single header"; restraint, single accent (Linear-purple), calm > dense. The canonical "boring-and-bettering" craft bar. | Lead-answer-first pages; single-accent discipline; P1 speed. ([LogRocket: Linear design](https://blog.logrocket.com/ux-design/linear-design/), [925studios](https://www.925studios.co/blog/saas-dashboard-design-examples-2026)) |
| **Stripe dashboard** | "Did revenue grow this week?" answered at top; everything else supports the lead. Trust through restraint. | P3/P4 "is it healthy/enforced?" answered at a glance; export/artifact polish. |
| **Vercel** | Blueprint-grid rigor, monochrome + one accent, developer-operator audience. | Grid conformance; dark-surface premium feel for P5/P1. ([Setproduct: Vercel Blueprint Grid](https://www.setproduct.com/blog/complete-guide-to-blueprint-grid-design)) |
| **Raycast** | Keyboard-first, extreme restraint, single accent (Raycast-red), dense-but-calm command surface. | Low-clunk / low-control-count; keyboard operability; P1 handle-first speed. |
| **Grafana (done right)** | Operator/observability density that *stays legible* — the cautionary+aspirational bar for data-viz surfaces (coverage/timeline/diff). Note v1.36 already cites "the Grafana lesson." | Data-dense pages that don't become clutter; dark data-viz contrast. |

**Use:** commit one reference screenshot per relevant lens/page-type into the harness; the vision critic scores *relative to* it. Design engines like [styleseed](https://github.com/bitjaru/styleseed) (brand skins for Stripe/Linear/Notion/Raycast/Arc/Vercel) confirm this "named-bar as calibration" pattern is now standard practice.

---

## 7. Capability Matrix — Table Stakes / Differentiators / Anti-Features

### TABLE STAKES (v1.40 is not credible without these)

| Capability | Complexity | Dependencies |
|---|---|---|
| **Per-persona adversarial critic (C-P1..P5)** scoring friction/discoverability/self-doc/scent per page | High | Locked personas (`v1.31-PERSONAS-IA.md`); stress-lab renders |
| **Graphic-design vision critic** — screenshot-fed, one-dimension-per-call, rubric with written pass conditions | High | Stress-lab screenshots; LLM vision; reference bars (§6) |
| **Mechanical checkers** — token-grid, spacing-on-scale, type-scale, contrast/WCAG, control-count, scroll-cost | Med | `style.ex` tokens; existing a11y/responsive e2e |
| **Scorecard cube** (page × persona × lens), self-assessment-banned, evidence-cited findings | Med | Ledger schema extension |
| **Forward-only ratchet gate** — accept only if net-positive & no lens below floor & mechanical gates pass | Med | Existing `stress_ledger_test.exs` + ratchet rule |
| **Regression guard** — screenshot + mechanical + numeric floor | Low–Med | Existing screenshot-regression spec + snapshots |
| **Design-debt register** — ranked, reproducible via `/audit/__stress?story=` | Low | Existing `footgun.*`/`future.*` ledger entries |
| **Nielsen + WCAG/APG + Fitts/Hick lenses** folded in (WCAG/Fitts/Hick mechanical-gated) | Med | Existing a11y guards |
| **Judge-consistency controls** — reference-guided anchoring, pairwise before/after, position-swap + majority vote, accept-margin ε | Med | Reference-bar screenshots |

### DIFFERENTIATORS (what makes this award-winning, not just a linter)

| Capability | Complexity | Dependencies |
|---|---|---|
| **Arrival-context weighting** — page scored against *whoever actually lands there*, gated by worst-served persona | Med | Persona→page mapping (JTBD table) |
| **Flow-level scoring across Flows A–D** — a flow is only as good as its worst step; catches cross-page friction | High | Per-page scores; flow definitions (EF1–EF5) |
| **Reference-bar calibration** (Linear/Stripe/Vercel/Raycast/Grafana) baked into rubric prompts | Med | Committed reference screenshots |
| **Mechanical/vision split everywhere** — deterministic floor + judged ceiling; never LLM-judge what a parser proves | Med | Token + contrast infra |
| **Auto-fix for mechanical findings** (snap-to-token, fix contrast) behind the ratchet; critic-proposed-human-applied for structural | High | Ratchet gate; safe auto-apply harness |
| **Restraint / low-clunk budgets** — control-count, type-size-count, accent-count, scroll-cost as first-class scored dimensions | Low–Med | DOM/computed-style inspection |
| **Proposed-change register** — every finding ships a concrete minimal lever, not just a complaint | Med | Findings schema |
| **Dual-mode (dark+light) critique** — every score in both lanes | Med | v1.36 light lane, alpha-aware parser |

### ANTI-FEATURES (explicitly do NOT build)

| Anti-feature | Why avoid | Do instead |
|---|---|---|
| **Fully autonomous aesthetic auto-merge** (vision-judge applies + merges structural change unattended) | Judge non-determinism + self-enhancement/verbosity bias → silent quality drift, no human taste in the loop | Critic proposes; human/build-agent applies structural changes; auto-apply only deterministic mechanical fixes |
| **Single blended "UX score"** | Combining dimensions in one rubric produces inconsistent scoring ([Appen](https://www.appen.com/llm-as-a-judge-rubric-design)); hides *which* lens failed | One dimension per rubric call; keep the cube disaggregated |
| **Enterprise-dashboard density / verbose chrome** | Contradicts the whole brief (operators want minimal scroll, low control-count) and the Linear/Stripe restraint bar | Restraint budgets as scored anti-clutter dimensions |
| **New public component API / config surface** | v1.31→v1.39 boundary: no public component API, PhoenixStorybook stays dev/example-only, capture-only adopters stay Plug-only | Keep the harness internal to `/audit` + planning tooling |
| **Pointwise absolute scores as the ratchet driver** | Absolute LLM scores drift run-to-run; a floor built on them ratchets on noise | Pairwise before/after + accept-margin ε + majority vote |
| **Grading the demo app** instead of `/audit` | Scope creep; the operator surface is the adopter-mounted product | Critique targets `/audit` stress-lab stories only |
| **Perf/DB/capture semantics in scope** | Out-of-scope per PROJECT.md unless a truth/schema inconsistency forces it | UI/UX/brand-craft only |
| **Motion for its own sake / heavy animation** | Fails restraint + reduced-motion; distracts operators under time pressure | Motion-token conformance + "motion clarifies state change" pass condition |

---

## 8. Confidence & Gaps

- **HIGH** — persona set, JTBD, token scale, ratchet mechanism, stress-lab, brand rubric: all read directly from repo (`v1.31-PERSONAS-IA.md`, `DESIGN-SYSTEM.md`, `design-system-ledger.json`, `style.ex`, `pressure-test.md`).
- **HIGH** — LLM-as-judge method (one-dim-per-rubric, pairwise, reference-guided, bias/consistency controls): corroborated across multiple 2024–2026 sources.
- **MEDIUM** — exact numeric thresholds for restraint budgets (max control count, max type-size count per page) — must be *derived from the current pages* during requirements, not guessed here.
- **MEDIUM** — auto-fix boundary: which mechanical fixes are truly safe to auto-apply needs a spike against real `style.ex` usage.
- **GAP** — no public benchmark exists for "adversarial persona critic scoring" specifically; UICrit/VisJudge-Bench cover general UI/viz aesthetics, not persona-arrival friction. This persona-arrival weighting is Threadline-original and should be validated against a small human slice ([human-alignment practice](https://www.appen.com/llm-as-a-judge-rubric-design)).

---

## Sources

- [UICrit: Enhancing Automated Design Evaluation with a UI Critique Dataset (UIST 2024)](https://people.eecs.berkeley.edu/~bjoern/papers/duan-uicrit-uist2024.pdf) — design quality = usability + aesthetics; alignment/hierarchy/spacing critique taxonomy. HIGH.
- [VisJudge-Bench: Aesthetics and Quality Assessment of Visualizations (arXiv 2510.22373)](https://arxiv.org/pdf/2510.22373) — vision aesthetics scoring for data-viz. MEDIUM.
- [WebVR: Human-Aligned Visual Rubrics (arXiv 2603.13391)](https://arxiv.org/pdf/2603.13391) — web-design dimension taxonomy (Global Aesthetics / Nav / Section Layout / Interaction-Motion). MEDIUM.
- [Appen — LLM-as-a-Judge Rubric Design](https://www.appen.com/llm-as-a-judge-rubric-design) — one dimension per rubric; verbosity/self-enhancement/surface-fluency bias controls. HIGH.
- [Learning to Judge: LLMs Designing and Applying Evaluation Rubrics (arXiv 2602.08672)](https://arxiv.org/html/2602.08672v1) — diagnostic multi-dimensional rubrics. MEDIUM.
- [eugeneyan — Evaluating LLM-Evaluators](https://eugeneyan.com/writing/llm-evaluators/) — pairwise > pointwise; reference-based calibration. HIGH.
- [References Improve LLM Alignment in Non-Verifiable Domains (arXiv 2602.16802)](https://arxiv.org/pdf/2602.16802) — reference anchor → consistent, reproducible scores. MEDIUM.
- [A survey on LLM-as-a-judge (ScienceDirect)](https://www.sciencedirect.com/science/article/pii/S2666675825004564) — position-swap, majority-vote, robustness/consistency challenges. HIGH.
- [LogRocket — Linear design](https://blog.logrocket.com/ux-design/linear-design/) and [925studios — SaaS dashboard examples 2026](https://www.925studios.co/blog/saas-dashboard-design-examples-2026) — lead-question-first, restraint, single accent, calm > dense. HIGH.
- [Setproduct — Vercel Blueprint Grid](https://www.setproduct.com/blog/complete-guide-to-blueprint-grid-design) and [Dashboard design principles](https://www.setproduct.com/blog/effective-dashboard-design-principles) — 8px/grid discipline; restraint. MEDIUM.
- [styleseed (GitHub)](https://github.com/bitjaru/styleseed) — named brand-bar calibration for AI-generated UI (Stripe/Linear/Notion/Raycast/Vercel skins). MEDIUM.
- **Internal (HIGH):** `.planning/milestones/v1.31-PERSONAS-IA.md`, `DESIGN-SYSTEM.md`, `.planning/design-system-ledger.json`, `brandbook/pressure-test.md`, `lib/threadline/operator_surface/style.ex`, `examples/threadline_phoenix/e2e/tests/`.
