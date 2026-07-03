# Requirements: Threadline v1.40 — Automated Operator-UI Critique & Forward-Only Iteration Harness

**Defined:** 2026-07-02
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Milestone goal:** Make evaluating and improving the `/audit` operator UI fast and monotonic — an adversarial multi-lens critic panel over deterministic capture, feeding the existing design-system ledger ratchet so award-winning, on-brand (Linear-grade) improvements land and regressions are blocked, with far less human review time.

> **Framing:** ~80% integration on shipped substrate (ledger + `stress_ledger_test.exs` ratchet, `/audit/__stress`, Playwright dark/light lanes, a11y evidence, `style.ex` tokens, brand pressure-test, locked personas P1–P5). New work = the scorecard cube, one critic runner, and the net-positive gate. Full rationale: `.planning/research/SUMMARY.md`.

## v1 Requirements

### Ledger & Scorecard Cube (LEDGER)

- [ ] **LEDGER-01**: The design-system ledger records a `page × persona × lens` scorecard cube per entry (replacing the single opaque score), with each lens score tracked independently.
- [ ] **LEDGER-02**: `stress_ledger_test.exs` enforces per-lens monotonicity — no lens score drops below its committed floor without an explicit ratchet reset + rationale.
- [ ] **LEDGER-03**: Every score increase carries an `evidence_ref` to a committed scorecard artifact; a bump lacking evidence fails the ratchet test.
- [ ] **LEDGER-04**: The `DESIGN-SYSTEM.md` projection regenerates with per-lens columns and stays freshness-tested per row.
- [ ] **LEDGER-05**: The ledger and its guards run inside `mix ci.all` deterministically — no LLM call, no network.

### Deterministic Evidence & Capture (MECH)

- [ ] **MECH-01**: Deterministic checkers compute per-page mechanical metrics — token-grid conformance, spacing-on-scale, type-size count, and radius/shadow/motion token conformance — from source/computed styles.
- [ ] **MECH-02**: Deterministic checkers compute WCAG contrast (dark + light), interactive-control count, card-nesting depth, scroll-cost (page height ÷ viewport per breakpoint), and distinct-accent-hue count.
- [ ] **MECH-03**: Mechanical checks act as ratchet-floor gates — a violation blocks a proposed change independently of any LLM judgment.
- [ ] **MECH-04**: The Playwright capture lane emits a complete evidence bundle per cell (screenshot + rendered DOM + ARIA/a11y tree + resolved `--tl-*` tokens + meta) driven from `/audit/__stress`.
- [ ] **MECH-05**: Capture is tiered and documented — Tier A deterministic (all cells, CI) / Tier B LLM sample (curated subset, local) / Tier C pixel allowlist (CI) — with an explicit page × state × breakpoint × theme matrix.

### Critic Validation & Rubrics (CRITIC)

- [ ] **CRITIC-01**: A golden set of hand-labeled Threadline states (known-good primitives + known-bad footgun fixtures) exists with the maintainer's good/bad/rank verdicts.
- [ ] **CRITIC-02**: The critic passes refute-tests before it may drive the ratchet — scores footgun fixtures low, polished primitives high, prefers the known-better of a curated A/B pair, and detects an injected regression (e.g. doubled padding, added nested card).
- [ ] **CRITIC-03**: Critic↔human agreement is measured on the golden set and meets a documented threshold (target 75–90%); below threshold blocks automated ratcheting.
- [ ] **CRITIC-04**: Versioned, anchored rubrics exist per lens (one per persona/JTBD + graphic-design + brand), each dimension phrased as an adversarial pass/fail with a written pass condition and a reference-bar anchor (Linear primary; Vercel/Stripe/Grafana secondary by surface).
- [ ] **CRITIC-05**: Self-assessment is banned — every score cites a screenshot region/DOM selector or a mechanical output line; a finding that cannot be located is discarded.

### Critic Runner & Adversarial Panel (RUNNER)

- [ ] **RUNNER-01**: A Node critic runner in `examples/threadline_phoenix/e2e/critic/` calls Claude vision with JSON-schema structured output, a prompt-cached rubric+anchor prefix, and one dimension per call.
- [ ] **RUNNER-02**: The runner performs N-sample self-consistency (median + variance), flags high-variance cells as unstable (not ratcheted), and stamps model id + rubric version on every scorecard.
- [ ] **RUNNER-03**: The panel runs one critic per persona (P1–P5) + a graphic-design critic + a brand-veto critic; a `--tl-*` token / parity violation vetoes a change before aesthetic scoring.
- [ ] **RUNNER-04**: `mix verify.ui_critique` wraps the runner as a named entrypoint, requires `ANTHROPIC_API_KEY`, no-ops without it, is excluded from `mix ci.all`, and is documented as local-only under a doc-contract lock.
- [ ] **RUNNER-05**: The Anthropic SDK is a `devDependency` of `e2e/package.json` only; `verify.compile_no_optional` still proves root `threadline` stays Phoenix-optional with no new runtime dependency.

### Forward-Only Gate & Iteration (GATE)

- [ ] **GATE-01**: A change is accepted only if it improves the targeted lens AND no other page/persona/lens score regresses below floor AND all mechanical / a11y / screenshot guards pass (full-panel re-eval, blast-radius aware for shared tokens/primitives).
- [ ] **GATE-02**: Mechanical fixes auto-apply (snap-to-token, fix contrast, remove off-grid px); a narrow, spike-defined low-risk-structural whitelist may also auto-apply — both strictly behind GATE-01.
- [ ] **GATE-03**: A held-out "true-north" fixture set is scored for validity only and never optimized against; training-vs-held-out score divergence halts the loop (Goodhart guard).
- [ ] **GATE-04**: Score-bar changes (ratchet bumps, target changes, panel-membership changes) require human sign-off recorded in the append-only ledger; a guard-the-guards test blocks silent target drops or fixture removal.
- [ ] **GATE-05**: Pixel-diff stays advisory (never a quality-bar change); a screenshot baseline refresh requires the new render to have already passed the semantic guards.

### Proof & Closeout (PROOF)

- [ ] **PROOF-01**: The full loop (capture → critique → propose → re-evaluate → guard) is wired end-to-end and documented as a repeatable runbook.
- [ ] **PROOF-02**: Real, ratified improvement is landed on the 2–3 lowest-scoring operator pages — each targeted lens advanced toward `target_score` with no regressions — proving the loop drives real UI change, not just tooling.
- [ ] **PROOF-03**: A v1.37-style multi-lens adversarial closeout confirms the loop cannot regress the deterministic floor and all invariants hold (no root runtime dep, no public API, dev/test-only, LLM out of CI, capture/query/auth untouched).
- [ ] **PROOF-04**: A residual design-debt register lists remaining items with owner + reopen-trigger (the v1.39 risk-register shape).

## Future Requirements (deferred)

### Coverage & Automation depth

- **FUT-01**: Full 11-page operator-surface sweep to `target_score` (deferred — v1.40 proves the loop on the weakest pages first to avoid big-bang churn).
- **FUT-02**: Broader auto-apply of structural changes beyond the spike-proven whitelist (revisit after held-out validity holds across several iterations).
- **FUT-03**: Cross-model (≥2 families) ensemble judging for extra robustness (single-family self-consistency first).
- **FUT-04**: A batch/overnight full-matrix critique run via the Message Batches API (on-demand sample first; scale only if cost/coverage warrants).

## Out of Scope

| Feature | Reason |
|---------|--------|
| LLM calls in `mix ci.all` / any blocking CI gate | Nondeterministic + paid + rate-limited; violates honest-default-tests + stable-CI DNA. Critic is local/on-demand; CI verifies the committed ledger only. |
| Anthropic SDK / HTTP client as a root `threadline` runtime dep | Root package must stay Phoenix-optional with no new runtime deps; SDK lives in `e2e` devDependencies only. |
| Public "design-eval" component API or product-facing critic surface | v1.40 is dev/maintainer tooling; the `/audit/__stress` fail-closed pattern is the boundary. |
| Commercial visual-AI SaaS (Applitools/Percy/Chromatic/Lost Pixel) | Playwright already covers pixel regression; the critic is bespoke/self-hosted and their names are banned in committed ledger copy (`@forbidden_terms`). |
| Fully autonomous aesthetic auto-merge of vision-judged structural change | Judge nondeterminism + self-enhancement/verbosity bias → silent quality drift; humans ratify score-bar changes. |
| Grading the demo app instead of `/audit` | Scope creep; the operator surface is the adopter-mounted product. |
| Capture/query/auth semantics, perf/DB work | Out of scope per PROJECT.md unless a truth/schema inconsistency forces it; v1.40 is UI/UX/brand-craft tooling only. |
| New operator routes, capabilities, or dependencies | v1.37/v1.38 held this line; v1.40 must too. |

## Traceability

Which phases cover which requirements. Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| LEDGER-01..05 | TBD | Pending |
| MECH-01..05 | TBD | Pending |
| CRITIC-01..05 | TBD | Pending |
| RUNNER-01..05 | TBD | Pending |
| GATE-01..05 | TBD | Pending |
| PROOF-01..04 | TBD | Pending |

**Coverage:**
- v1 requirements: 29 total
- Mapped to phases: 0 (roadmap pending)
- Unmapped: 29 ⚠️

---
*Requirements defined: 2026-07-02*
*Last updated: 2026-07-02 after initial definition*
