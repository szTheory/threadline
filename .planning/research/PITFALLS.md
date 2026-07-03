# Domain Pitfalls: Adversarial LLM-Critic UI/UX Iteration Loop (v1.40)

**Domain:** Automated, adversarial-LLM-critic-driven UI/UX evaluation with a forward-only (monotonic) improvement ratchet for the Threadline `/audit` operator surface.
**Researched:** 2026-07-02
**Overall confidence:** HIGH (well-documented failure-mode literature 2024–2026 + Threadline's own shipped stress-lab/ledger/pressure-test precedents to build on)

> **How to read this file.** Each pitfall has a concrete prevention and a suggested *owning phase archetype* (v1.40 phases are not yet defined; names are proposed so the roadmap can adopt them). The single most important meta-lesson: **Threadline already has the right skeleton** — the brand pressure-test's "self-assessment is banned, every score cites a mechanical output" rule (`brandbook/pressure-test.md`) and the stress-lab `design-system-ledger.json` per-fixture `ratchet_score`/`target_score`/`reserved_for_phase` model. v1.40's job is to *generalize and harden* those, not invent a new eval machine from scratch. Do not throw them away.

---

## 1. Critic Reliability Pitfalls + Prevention

An LLM design critic is itself an unreliable instrument. **You must validate the critic before you trust a single score it emits.** Treat the critic like a measurement device that needs calibration certificates.

### CRIT-1 (Critical): Sycophancy / flattery — everything rates "good"
**What goes wrong:** LLM judges systematically prefer answers that are stated assertively or that confirm framing, and rate their own or default-register outputs highly. Applied to design, a naive "rate this page 1–10" prompt drifts toward 7–8 on everything, so the ratchet never has room to climb and real problems never surface.
**Why it happens:** RLHF-trained models are optimized to be agreeable; "does this look good?" is a leading question. Sycophancy is documented as the *hardest* of the three classic judge biases to mitigate.
**Prevention:**
- **Refute-framing over praise-framing.** Threadline already proved this works: the brand pressure-test's distinctiveness check is *"delete the motif and render — if what remains is a complete generic wordmark, the identity fails."* Every rubric dimension must be phrased as an adversarial pass/fail the critic tries to *break*, not a quality it tries to affirm. Ask "list the three worst things on this screen and why an operator would stumble," never "is this good?"
- **Ban bare self-assessment; require mechanical evidence per score.** Port `pressure-test.md`'s rule verbatim: a score is only valid if it cites a measurable artifact (a measured pixel gap, a control count, a token violation, a specific element) or a direct render. "Looks clean, 8/10" is an automatic void.
- **Force a critique quota.** Require N concrete defects per screen even on "good" screens; a critic that returns zero findings is treated as a failed run, not a pass.
**Detection:** Score-distribution monitoring — if the critic's scores cluster >7 with low variance across deliberately-ugly fixtures, it is flattering.
**Owning phase:** Critic Harness & Rubric Design.

### CRIT-2 (Critical): Hallucinated issues
**What goes wrong:** The critic invents defects that aren't in the rendered UI ("the button overlaps the header," "contrast is 2:1") — especially with vision inputs — causing wasted or actively harmful "fixes."
**Why it happens:** VLMs confabulate spatial/layout facts they cannot actually perceive (see CRIT-5).
**Prevention:**
- **Every claimed defect must be locatable and reproducible.** Require the critic to cite a selector, coordinate region, or quoted text string. A defect that can't be pointed at is discarded.
- **Ground with deterministic evidence, don't ask the model to measure.** Contrast ratios, element counts, token usage, DOM depth, scroll height, and touch-target sizes are computed by *code* (extend the existing `style_contract_test.exs` / Playwright accessibility-tree harness from v1.37), then *handed to* the critic. The critic reasons about salience/hierarchy; it never guesses a number a program can compute.
- **Two-pass confirm.** A flagged defect is only actionable if it survives a second, independently-prompted verification pass (or a code check).
**Owning phase:** Critic Harness & Rubric Design; Deterministic-Evidence Extractors.

### CRIT-3 (High): Run-to-run inconsistency
**What goes wrong:** The same screen scores 6 then 8 then 5 on identical input; the ratchet can't tell a real regression from noise.
**Prevention:**
- **Majority vote / ensemble.** Run each evaluation k≥3 times (and ideally across ≥2 model families) and take median + report variance. Only act on findings that recur.
- **Temperature discipline + fixed rubric.** Low temperature for scoring passes; the rubric text is version-pinned and hashed so a score always names the rubric version that produced it (mirror the pressure-test's "a score is only as current as its evidence").
- **Noise floor.** Compute the critic's own test-retest variance on a frozen fixture set; any score change smaller than that floor is *not* a regression and *not* an improvement — it's noise. The ratchet only moves on changes above the floor.
**Owning phase:** Critic Harness & Rubric Design (ensemble + noise-floor).

### CRIT-4 (High): Positional & verbosity bias
**What goes wrong:** In A/B ("is the new version better than the old?") comparisons, the judge favors whichever candidate is shown first/last, and favors the longer/more-decorated option — which pushes the UI toward *more* chrome, the exact opposite of the operator-UI goal (see §5).
**Prevention:**
- **Randomize & swap order; average both orderings.** Standard positional-bias mitigation: evaluate (A,B) and (B,A), keep only verdicts stable under swap.
- **Blind the critic to "which is new."** Never label a candidate "the improved version" — that triggers both sycophancy and positional priming.
- **Explicitly penalize verbosity/chrome in the rubric** so the known verbosity bias is counter-weighted, not amplified (MLLMs are *more* vulnerable to verbosity bias than position bias).
**Owning phase:** Critic Harness & Rubric Design.

### CRIT-5 (Critical): Vision-model limits — misreading spacing, alignment, pixels
**What goes wrong:** VLMs (GPT-4o class) are architecturally weak at precise spatial reasoning: patch-based encoders misread continuous coordinates, horizontal-distance and alignment tasks score lowest, and models fail to localize elements lacking textual identity. A visual critic will *confidently* mis-report spacing, alignment, and density.
**Why it happens:** Vision transformers partition images into patches and interpret patch boundaries as coordinates — systematic, not random, error.
**Prevention:**
- **Do not ask the VLM to be a ruler.** Spacing, alignment, overflow, scroll height, control counts, contrast, and grid consistency are measured from the DOM/computed styles by code (Threadline already has the Playwright + `style.ex` source-contract lanes). The VLM judges *gestalt* questions it's actually good at: "does the visual hierarchy match the task priority? what does the eye land on first? does this read as one system or a patchwork?"
- **Feed the VLM both the screenshot AND the extracted metrics** so its narrative is anchored to ground truth.
- **Multi-viewport rendering is code's job** (375/768/1280 already exist in v1.31); the critic reviews each rendered breakpoint, it does not imagine responsiveness.
**Owning phase:** Deterministic-Evidence Extractors (owns the measured facts); Visual-Critic Harness (owns gestalt judgment only).

### CRIT-6 (Moderate): Model drift over time
**What goes wrong:** The underlying model is updated by the vendor; scores shift; last month's "88" and this month's "88" aren't comparable, silently loosening or tightening the ratchet.
**Prevention:**
- **Pin the model version** in the ledger alongside the rubric version. A score record is `{score, model_id, rubric_hash, timestamp, evidence}`.
- **Golden-anchor re-baseline on model change.** Keep a frozen golden set (see CRIT-7); when the model id changes, re-score the golden set and confirm the critic still ranks the known-good/known-bad anchors correctly before any live scores are trusted.
**Owning phase:** Critic Validation & Golden Set.

### CRIT-7 (Critical): Trusting the critic before validating it (meta-eval gap)
**What goes wrong:** The whole system is built on the assumption the critic's judgment tracks reality — but that assumption is never tested, so the ratchet optimizes toward a broken oracle.
**Why it happens:** Teams skip the boring step of validating the judge against humans. The literature is blunt: validate against a golden dataset to **75–90% agreement with human labels** *before* scaling; if the judge disagrees with experts >20% on clear-cut cases, fix the prompt, not the UI.
**Prevention (this is the linchpin — do it in an early phase, gate everything else on it):**
- **Build a golden set of Threadline screens with human labels.** Reuse the existing stress-lab fixtures: the ledger already encodes known footguns (`footgun.coverage-schema.card_declutter`=25, `footgun.transaction-page.left_push_desktop`=25) and known-good primitives. Hand-label a calibration set (30–50 states) with the maintainer's own good/bad/rank verdicts.
- **Measure critic↔human agreement and inter-rater agreement.** If two humans agree <80% on a dimension, the *rubric* is ambiguous — fix the rubric, not the model (this is exactly the pressure-test's "cite a testable pass condition" discipline).
- **Refute-tests the critic must pass:** it must (a) score the seeded footgun fixtures *low*, (b) score the polished v1.38 primitives *high*, (c) prefer the known-better of a curated A/B pair, (d) detect an injected regression (e.g., double the padding, add a nested card). A critic that fails these does not get to drive the ratchet.
- **Never present LOW-confidence critic output as authoritative** — carry the confidence tier into the ledger.
**Owning phase:** **Critic Validation & Golden Set (must precede the automated ratchet phase).**

---

## 2. Forward-Only / Ratchet Failure Modes + Prevention

The "only move forward" promise is where this class of system most often quietly breaks. Threadline already ships the right primitive — the JSON `design-system-ledger.json` with per-fixture `current_score`/`ratchet_score`/`target_score` — but a ratchet is only as honest as its re-evaluation discipline.

### FWD-1 (Critical): Whack-a-mole — fixing one page regresses another
**What goes wrong:** An autofix improves the Timeline page but changes a shared primitive/token and silently regresses Coverage, Actor, and Export. This is Threadline's *documented* historical churn: v1.38 was a "page-by-page polish" milestone that still took **262 commits / 296 files / ~40k insertions** — shared-surface blast radius is real here.
**Prevention:**
- **Full-panel re-eval after every change — never per-page.** The ratchet advances only if *the whole scored set* is re-evaluated and no fixture's score dropped above the noise floor. A local win that lowers any other fixture is rejected. This is the single most important rule in the milestone.
- **Score the shared substrate as first-class fixtures.** Because `style.ex` tokens and private primitives are shared, changes to them must trigger re-scoring of *every* page that consumes them (the ledger already links fixtures to `source`).
- **Blast-radius gating.** A change touching a shared token/primitive requires a full-panel pass; a change touching one page's markup can run a narrower panel but still re-checks any fixture sharing its primitives.
**Owning phase:** Ratchet Engine & Regression Guard.

### FWD-2 (Critical): Goodharting the rubric — optimizing the score, not real quality
**What goes wrong:** The loop learns to move the number without improving the UI. This is textbook reward hacking / Goodhart: *"when a measure becomes a target it ceases to be a good measure,"* and under optimization pressure the policy drifts into regions where "superficial correlates of quality dominate the score." Concretely: the fixer starts gaming whatever the critic keys on (adding buzzwords the copy-critic likes, padding to hit a whitespace heuristic, adding a hero element the salience-critic rewards).
**Prevention:**
- **Hold out a frozen "true-north" set the fixer never optimizes against.** Split fixtures: a *training* set the loop iterates on, and a *held-out* set scored only for validity monitoring. If training-set scores climb while held-out scores stall or fall, the loop is Goodharting — halt and revise the rubric.
- **Rotate/refresh rubric probes** so the fixer can't memorize the exact triggers.
- **Human spot-audit at milestone gates.** The score is a *proxy*; a human confirms the top-scored screens are genuinely better at a few checkpoints. Full automation of the *oracle* is a non-goal (see §4).
- **Diversify the critic panel** (per-persona/JTBD + visual + brand) so no single taste function can be gamed in isolation; a change must satisfy *all* critics, and their disagreements are signal.
**Owning phase:** Ratchet Engine & Regression Guard (held-out set); Critic Validation (rubric-probe rotation).

### FWD-3 (High): Local optima / oscillation
**What goes wrong:** The loop toggles a design decision back and forth (A improves critic-1, B improves critic-2), burning cost and commits without net progress; or it stalls in a mediocre local optimum it can't escape with small edits.
**Prevention:**
- **Monotonic ledger with a strict advance rule.** A candidate is accepted only if aggregate score strictly increases (above noise) *and no fixture regresses*. Rejected candidates are recorded so the loop doesn't retry the same oscillation (the ledger already carries per-fixture history).
- **Change-budget / iteration cap per fixture per milestone** — after K non-improving attempts, escalate to human decision instead of thrashing.
- **Allow explicit "accept sideways for a documented reason" only via human sign-off,** never automatically.
**Owning phase:** Ratchet Engine & Regression Guard.

### FWD-4 (Critical): The ratchet silently loosening
**What goes wrong:** Baselines get "refreshed" to make red go green; a `target_score` is quietly lowered; a fixture is dropped from the panel. The ratchet still *looks* monotonic but the bar moved. Threadline has already felt adjacent pain: screenshot-regression baselines are "local/platform-sensitive" and flaky, and v1.37/v1.38 carried "screenshot-regression confidence" as a named residual.
**Prevention:**
- **Ledger is append-only and diffable in git;** score/target/panel-membership changes are reviewed changes, not silent edits. Adopt the pressure-test rule: *"a score is only as current as its evidence"* — refreshing a baseline requires the new render to have already passed the semantic guards (exactly the v1.37 adversarial-closeout rule: "update baselines only when the current rendered surface has already passed semantic guards").
- **Guard the guards.** A contract test asserts no `target_score` decreased and no fixture left the panel without a recorded, human-approved reason.
- **Separate "screenshot pixel diff" (flaky, advisory) from "semantic score" (authoritative).** Never let a pixel-diff refresh double as a quality-bar change.
**Owning phase:** Ratchet Engine & Regression Guard; Closeout/Audit.

### FWD-5 (Moderate): Over-fitting to one critic's taste
**What goes wrong:** Converging on the aesthetic the dominant model happens to like, not what operators or the brand need.
**Prevention:** Covered by the multi-critic panel (FWD-2) and the anti-homogenization anchors in §3; the brand-identity critic acts as a *veto* against drift away from Threadline's established dark-primary, designed-not-recolored system.
**Owning phase:** Critic Harness (panel design); Award-Quality Anchoring.

---

## 3. "Award-Winning" Subjectivity Traps

"Award-winning / on-brand / tight design system" is the vaguest part of the goal and the easiest to Goodhart or homogenize. Research is clear that LLMs converge on a *"dominant, often Western-centric default aesthetic"* — identical gradients, glassmorphism, and the "competent, balanced, indistinguishable" register — and that exposure to AI suggestions *reduces* variety and originality.

### AWD-1 (Critical): Generic AI-slop convergence
**Trap:** Left to its own taste, the loop drifts toward the homogenized "AI design aesthetic," which for an operator tool is both off-brand and often *worse* (decorative, low-density).
**Prevention:**
- **Anchor to concrete named reference systems, not adjectives.** The rubric must cite real operator/dev-tool exemplars (e.g., Linear, Vercel dashboard, Stripe dashboard, Datadog/Grafana density) as the calibration bar — "does this hold up beside Linear's information density?" is answerable; "is this award-winning?" is not. This mirrors the pressure-test's per-dimension *testable pass condition* approach.
- **Anti-slop clauses in the rubric:** explicitly ban/penalize the tells (gratuitous gradients, glassmorphism-for-its-own-sake, hero cards on a data tool, decorative iconography, marketing-register microcopy). Threadline's brand book *already bans* several of these — reuse its misuse gallery and banned-vocabulary list as critic inputs.
**Owning phase:** Award-Quality Anchoring & Reference Calibration.

### AWD-2 (Critical): Brand-identity erosion
**Trap:** Optimizing "beauty" quietly recolors/reshapes the UI away from the shipped identity — the exact thing the brand system was built to prevent.
**Prevention:**
- **Brand critic as a veto, gated on the existing mechanical brand suite.** The `brandbook/` pressure-test and `brandbook_token_parity_test.exs` already enforce dark/light token parity and "designed-not-recolored." Any candidate that changes a `--tl-*` token value, drifts from the token contract, or trips the brand gate is rejected *before* aesthetic scoring. Aesthetics may only move *within* the brand envelope.
- **"Designed-not-recolored" is a first-class rule** — Threadline learned the "Grafana lesson" in v1.36 (data-viz surfaces must be *designed* per mode, not mechanically recolored). Encode it: the critic must flag any change that reads as a mechanical transform rather than a considered design.
**Owning phase:** Brand-Guard Integration (wraps existing pressure-test/token-parity gates).

### AWD-3 (Moderate): Homogenizing toward the model's default across pages
**Trap:** Every page converges to the same template, killing the earned per-surface affordances (record-first lookup, correlation paste/deep-link, row history) that v1.31 built.
**Prevention:** Score *task-fit per persona/JTBD*, not just visual uniformity. Uniform *system* (tokens, primitives) is the goal; uniform *layout* is not. The per-persona critics protect surface-specific workflows from being flattened.
**Owning phase:** Persona/JTBD Critic Panel.

---

## 4. Scope & Cost Footguns

This is where the milestone most plausibly fails to deliver *value* even if every component "works."

### SCOPE-1 (Critical): An elaborate eval machine that never drives real improvement
**Trap:** Building the harness, ledger, critics, and dashboards becomes the deliverable; the actual `/audit` UI barely changes. Threadline's own v1.39 audit explicitly warns against this pattern — it *narrowed* scope and refused to "broaden into UI/product scope."
**Prevention:**
- **Ship UI improvements every phase, not just tooling.** Gate each phase on "≥N fixtures advanced toward `target_score` on the real surface," not "harness built." The ledger's `target_score: 90` per fixture is the deliverable, not the ledger itself.
- **Timebox the machinery; the harness is the *thinnest* thing that can drive the ratchet.** Reuse v1.37's stress-lab, ledger, Playwright, and pressure-test infra rather than rebuilding.
**Owning phase:** every phase (acceptance criterion); enforced at Closeout/Audit.

### SCOPE-2 (Critical): LLM cost/nondeterminism making it unusable in CI
**Trap:** Wiring nondeterministic, paid, rate-limited LLM calls into `mix ci.all` — which is Threadline's canonical, must-stay-green, path-filtered CI (per CLAUDE.md CI conventions). This would make CI flaky, slow, and expensive, violating the project's "honest default tests" and stable-CI DNA.
**Prevention:**
- **The LLM critic loop is an offline, dev/maintainer-run tool — NOT a CI gate.** CI keeps only the *deterministic* residue: the committed ledger, source-contract tests, token-parity, accessibility-tree snapshots, and screenshot guards (all of which already exist and are deterministic). The critic *produces* ledger updates offline; CI *verifies* the committed ledger is internally consistent and monotonic.
- **Cache/record critic runs** (research-store pattern) so a given `{screen, rubric_hash, model_id}` isn't re-billed; make runs reproducible from recorded transcripts.
- **Budget guardrails:** ensemble k and panel size are cost knobs; cap them.
**Owning phase:** Harness/CI Boundary Design (early); enforced by CI-contract test.

### SCOPE-3 (High): Over-automation removing necessary human judgment
**Trap:** Fully autonomous "critic → autofix → merge" convinces itself the UI is award-winning while a human would instantly see it's off. The oracle is a proxy; closing the human loop entirely is how Goodharting goes undetected.
**Prevention:** **Keep a human at the milestone gates and at "accept sideways" decisions** (FWD-3) and golden-set drift checks (CRIT-7). The system *proposes and pre-filters*; the human *ratifies* score-bar changes and final acceptance. This matches Threadline's existing "human-judged tournament" and "user-approved live in both modes" precedents (v1.35 logo tournament, v1.36 retune).
**Owning phase:** Ratchet Engine (human-in-the-loop checkpoints).

### SCOPE-4 (High): Scope creep into redesigning everything at once
**Trap:** "Award-winning" invites a big-bang redesign; Threadline's history shows big changes = big churn + new regressions (the stated problem this milestone exists to solve).
**Prevention:**
- **Reserved-for-phase, one-fixture-at-a-time ratcheting** — the ledger *already* does this (`reserved_for_phase`, `owner_phase`, `status: reserved`). Each footgun/fixture is owned by exactly one phase; you do not open a fixture out of turn (the ledger literally notes *"do not fix it in Phase 171"*). Carry this discipline into v1.40.
- **No new routes, capabilities, dependencies, or public API** — v1.37/v1.38 held this line; v1.40 must too.
**Owning phase:** Roadmap/phase decomposition; Ratchet Engine.

### SCOPE-5 (Critical): Turning dev-only tooling into product surface or new runtime deps
**Trap:** The critic harness leaks into the shipped library — a new runtime dependency, a public component API, a product-facing "eval" surface — violating Threadline's hard invariants (Phoenix optional; PhoenixStorybook example/dev-only; no public component API; not a SIEM; capture-only adopters stay Plug-only).
**Prevention:**
- **The eval harness lives exactly where the stress lab lives: internal, dev/test-only, fail-closed in prod.** The `/audit/__stress` route *raises* if used in prod and is omitted from the example prod build — replicate that pattern for anything new. No LLM/critic code ships in `lib/threadline/**` runtime paths; it lives in dev tooling / `.planning` / test support.
- **Anti-feature list to encode:** no LLM SDK as a runtime dep, no public "design-eval" API, no product UI for critics, nothing that makes a capture-only adopter pull Phoenix or an HTTP client.
**Owning phase:** Harness/CI Boundary Design; Closeout/Audit (invariant check).

---

## 5. Operator-UI Verbosity / Clunk Antipatterns (and how a critic reliably detects them)

Operator/admin UIs fail in a *specific* direction — toward too much, not too little. The verbosity bias of LLM critics (§CRIT-4) actively pushes the *wrong* way here, so these must be **explicit, measured, penalized** rubric dimensions, not left to the model's taste.

| Antipattern | What it looks like on `/audit` | How a critic reliably detects it |
|---|---|---|
| **Control overload** | Every filter/action shown at once; no progressive disclosure | *Code-measured*: count interactive controls per view above the fold; flag over a threshold. Critic judges whether the primary task's controls are visually primary. |
| **Card-in-card nesting** | Panels inside panels inside panels (the ledger's `footgun.coverage-schema.card_declutter` is literally this) | *Code-measured*: DOM nesting depth of card/panel containers; flag depth > N. Critic confirms the nesting adds no information scent. |
| **Excessive scroll / low density** | Data tool that scrolls forever; sparse rows; hero whitespace | *Code-measured*: scroll height ÷ viewport at each breakpoint; information-per-screen. Critic compares density to reference systems (Linear/Grafana). |
| **Low information scent** | Operator can't tell what a screen does or where a link goes | Critic (gestalt): "state the page's primary task and next action in one sentence from the render alone" — if it can't, scent is low. Cross-checked vs. the persona/JTBD rubric. |
| **Over-explanatory chrome** | Paragraphs of help text, redundant labels, marketing-register copy on a tool | *Code-measured*: prose word count per view, ratio of chrome-text to data. Critic flags explanatory copy that a competent operator doesn't need. Reuse the brand book's banned-vocabulary/voice rules. |
| **Redundant / decorative affordance** | Icons, badges, gradients that carry no operator meaning | Critic + brand gate: any decorative element must justify an operator purpose or be flagged (anti-slop, §3). |

**The key move:** these are **measured by deterministic extractors and only *interpreted* by the critic** (control counts, nesting depth, scroll ratio, word counts — the same "code computes the number, VLM judges the gestalt" split as CRIT-5). This makes clunk detection reproducible and immune to the critic's own verbosity bias. Density/clunk get their *own* ledger fixtures with `target_score`, so "tighten it" is a first-class, ratcheted goal — not a vibe.
**Owning phase:** Deterministic-Evidence Extractors (the metrics); Operator-Clunk Rubric (interpretation + fixtures).

---

## 6. Lessons From Threadline's Prior UI Milestones

Direct, repo-grounded lessons so v1.40 doesn't repeat prior churn.

### What worked (keep / generalize)
- **The stress-lab + JSON ledger (v1.37).** `design-system-ledger.json` with per-fixture `current_score`/`ratchet_score`/`target_score`/`reserved_for_phase`/`owner_phase`/`screenshot_baseline_refs` is *exactly* the monotonic ledger v1.40 needs. **Generalize it to hold LLM-critic scores per persona/dimension; do not rebuild it.**
- **Reserved-for-phase discipline.** Footguns were catalogued at baseline (`card_declutter`=25, `transaction_page.left_push_desktop`=25) and *explicitly not fixed early* — each owned by one future phase. This prevented big-bang churn and is the antidote to SCOPE-4.
- **The brand pressure-test method (`brandbook/pressure-test.md`).** 15 dimensions, each a *testable pass condition*, **"self-assessment is banned; every score cites a mechanical output or a direct render,"** rerun on any change. This is a *pre-built, proven anti-sycophancy protocol* — port it wholesale as the critic's evidence discipline (CRIT-1/CRIT-2).
- **Adversarial closeout with a fixed lens set (v1.37 Phase 180 "D-12 lens review").** Eight named lenses (Aesthetics-vs-usability, Dependency/architecture weight, Host-integration friction, Inaccessible custom behavior, Generic-template drift, **Screenshot-only quality**, Route/API stability, Residual CI ownership). Reuse this as v1.40's closeout checklist; the "Generic-template drift" and "Screenshot-only quality" lenses are directly on-point.
- **Mechanical brand gate + token parity test.** `brandbook_token_parity_test.exs` catches recolor drift automatically — the brand-guard veto (AWD-2) plugs straight into it.

### What created churn / residuals (avoid)
- **"Polish" milestones balloon.** v1.38 page-by-page polish = **262 commits, 296 files, ~40k insertions**; v1.31 = 35 plans/51 tasks. Shared tokens/primitives make every page-edit high-blast-radius. → **Full-panel re-eval (FWD-1) and blast-radius gating are mandatory, not optional.**
- **Screenshot regression is flaky and confidence-eroding.** Repeatedly a named residual ("standalone screenshot regression," "screenshot-regression confidence," baselines "local/platform-sensitive"). → **Pixel-diff is advisory only; the authoritative bar is the semantic score + deterministic contracts** (FWD-4). Never let a baseline refresh loosen the quality bar.
- **Accessibility tree ≠ real assistive tech.** v1.37 closeout's explicit caveat: Playwright's a11y tree "is not equivalent to NVDA/VoiceOver/JAWS." → Don't let a critic *overclaim* a11y or any human-only property; carry the bounded caveat forward.
- **Inherited residual CI failures get parked.** v1.37/v1.38/v1.39 all carried demo-seed / example-app / local test-DB `search_path` failures classified as non-blocking. → Keep the critic loop **out of `ci.all`** (SCOPE-2) so it never adds to this pile, and classify residuals honestly with owner + reopen-trigger (the v1.39 risk-register pattern).
- **v1.39 deliberately did NO UI scope.** v1.40 is a *deliberate re-opening* of UI iteration after a consolidation milestone — so it must be *tightly* scoped and evidence-first, or it re-introduces exactly the risk v1.39 just retired.

---

## Prevention Summary

| # | Pitfall | Severity | Prevention (one-liner) | Owning phase (archetype) |
|---|---|---|---|---|
| CRIT-1 | Sycophancy / everything "good" | Critical | Refute-framing + ban bare self-assessment (port pressure-test rule) + defect quota | Critic Harness & Rubric |
| CRIT-2 | Hallucinated defects | Critical | Every defect locatable + measure with code, not the model | Critic Harness; Evidence Extractors |
| CRIT-3 | Run-to-run inconsistency | High | Ensemble k≥3 (+cross-family), median, noise-floor gate | Critic Harness |
| CRIT-4 | Positional/verbosity bias | High | Swap order, blind "which is new," penalize verbosity | Critic Harness |
| CRIT-5 | Vision limits (spacing/pixels) | Critical | Code measures numbers; VLM judges gestalt only | Evidence Extractors; Visual Critic |
| CRIT-6 | Model drift | Moderate | Pin model+rubric in ledger; re-anchor golden set on change | Critic Validation & Golden Set |
| CRIT-7 | Trusting critic un-validated | Critical | Golden set, 75–90% human agreement, refute-tests before ratchet | **Critic Validation & Golden Set (gates all)** |
| FWD-1 | Whack-a-mole regressions | Critical | Full-panel re-eval + blast-radius gating; no per-page advance | Ratchet Engine & Regression Guard |
| FWD-2 | Goodharting the rubric | Critical | Held-out true-north set, multi-critic panel, human spot-audit | Ratchet Engine; Critic Validation |
| FWD-3 | Oscillation / local optima | High | Strict monotonic advance, record rejects, iteration cap | Ratchet Engine |
| FWD-4 | Ratchet silently loosening | Critical | Append-only diffable ledger; guard-the-guards; pixel-diff ≠ bar | Ratchet Engine; Closeout |
| FWD-5 | Over-fit to one critic's taste | Moderate | Multi-critic panel + brand veto | Critic Harness; Award Anchoring |
| AWD-1 | Generic AI-slop convergence | Critical | Anchor to named reference systems; anti-slop rubric clauses | Award-Quality Anchoring |
| AWD-2 | Brand-identity erosion | Critical | Brand critic veto gated on existing token-parity/pressure-test | Brand-Guard Integration |
| AWD-3 | Homogenized layouts | Moderate | Score task-fit per persona/JTBD, not layout uniformity | Persona/JTBD Critic Panel |
| SCOPE-1 | Eval machine, no real improvement | Critical | Gate each phase on fixtures advanced on the real surface | All phases; Closeout |
| SCOPE-2 | LLM cost/nondeterminism in CI | Critical | Critic loop is offline/dev-only; CI verifies committed ledger only | Harness/CI Boundary |
| SCOPE-3 | Over-automation removes judgment | High | Human ratifies bar-changes + final acceptance | Ratchet Engine |
| SCOPE-4 | Redesign-everything scope creep | High | Reserved-for-phase, one-fixture ratchet; no new routes/deps | Roadmap decomposition; Ratchet |
| SCOPE-5 | Dev tooling leaks into product | Critical | Fail-closed dev/test-only harness (stress-lab pattern); no runtime LLM dep | Harness/CI Boundary; Closeout |
| CLUNK | Verbosity/control-overload/nesting/scroll | High | Deterministic metrics + interpreting critic; own ledger fixtures | Evidence Extractors; Clunk Rubric |

**Suggested phase-ordering implication:** *Critic Validation & Golden Set* must come **before** the automated ratchet — an un-validated critic driving a ratchet just optimizes toward a broken oracle (CRIT-7 + FWD-2). Build/validate the critic, then build the ratchet on top of the *existing* ledger + pressure-test + stress-lab infra, then iterate fixtures one owning-phase at a time.

---

## Sources

LLM-as-judge bias & reliability:
- [Self-Preference Bias in LLM-as-a-Judge (arXiv 2410.21819)](https://arxiv.org/html/2410.21819v2)
- [Position Bias in LLM Judges: Measurement and Mitigation (Brenndoerfer)](https://mbrenndoerfer.com/writing/position-bias-in-llm-judges)
- [LLM-as-a-Judge: Why Frontier Models Fail 50%+ Bias Tests (Adaline)](https://www.adaline.ai/blog/llm-as-a-judge-reliability-bias)
- [What Is LLM-as-a-Judge Calibration? Power & Limits (Deepchecks)](https://deepchecks.com/llm-judge-calibration-automated-issues/)
- [Breaking the Mirror: Activation-Based Mitigation of Self-Preference (arXiv 2509.03647)](https://arxiv.org/pdf/2509.03647)

Reward hacking / Goodhart / self-improvement loops:
- [Specification gaming, Goodhart's law, and the metrics (explainx.ai)](https://explainx.ai/blog/specification-gaming-goodharts-law-ai-metrics)
- [Reward Hacking in the Era of Large Models: Mechanisms, Emergent Misalignment (arXiv 2604.13602)](https://arxiv.org/html/2604.13602v1)
- [Reward Shaping to Mitigate Reward Hacking in RLHF (arXiv 2502.18770)](https://arxiv.org/html/2502.18770v1)
- [Defining and Characterizing Reward Hacking (arXiv 2209.13085)](https://arxiv.org/pdf/2209.13085)

Vision-language model spatial limits:
- [Can Vision-Language Models See Squares? Text-Recognition Mediates Spatial Reasoning (arXiv 2602.15950)](https://arxiv.org/html/2602.15950)
- [SpatiaLab: Can Vision–Language Models Perform Spatial Reasoning in the Wild? (arXiv 2602.03916)](https://arxiv.org/html/2602.03916v1)
- [Inherent limitations of GPT-4 regarding spatial information (arXiv 2312.03042)](https://arxiv.org/html/2312.03042v1)

AI-slop / homogenization / anti-slop:
- [Interrogating Design Homogenization in Web Vibe Coding (arXiv 2603.13036)](https://arxiv.org/html/2603.13036v1)
- [The Homogenization Problem in LLMs: Towards Meaningful Diversity (arXiv 2601.06116)](https://arxiv.org/pdf/2601.06116)
- [The AI design aesthetic: why AI content all looks the same (Kompozy)](https://kompozy.io/guides/the-ai-design-aesthetic)
- [Diverse AI personas can mitigate the homogenization effect (ScienceDirect)](https://www.sciencedirect.com/science/article/pii/S294988212600040X)

Judge validation / golden set / calibration:
- [LLM-as-a-Judge vs Human Evaluation (Galileo)](https://galileo.ai/blog/llm-as-a-judge-vs-human-evaluation)
- [How to optimize your LLM Judge (Galtea)](https://www.galtea.ai/blog/llm-as-a-judge-evaluation)
- [LLM-as-a-Judge: Build Reliable, Scalable Evaluation (Comet)](https://www.comet.com/site/blog/llm-as-a-judge/)

Threadline internal (repo-grounded):
- `brandbook/pressure-test.md` — 15-dimension, self-assessment-banned, mechanical-evidence pressure test (anti-sycophancy protocol to port)
- `.planning/design-system-ledger.json` — per-fixture `current/ratchet/target_score`, `reserved_for_phase`, `owner_phase` (the monotonic ratchet to generalize)
- `.planning/milestones/v1.37-phases/180-.../180-ADVERSARIAL-REVIEW.md` — D-12 8-lens adversarial closeout; screenshot-only-quality and generic-template-drift lenses; a11y-tree ≠ real AT caveat
- `.planning/MILESTONES.md` (v1.31/v1.37/v1.38/v1.39) — churn stats and named residuals (screenshot-regression confidence, demo-seed/CI residuals)
- `CLAUDE.md` — invariants (Phoenix optional, no public component API, dev/test-only harness, not a SIEM, no new runtime deps)
