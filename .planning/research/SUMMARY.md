# Project Research Summary — v1.40 Automated Operator-UI Critique & Forward-Only Iteration Harness

**Synthesized:** 2026-07-02
**Inputs:** STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md (4 parallel researchers)
**Confidence:** HIGH on the internal substrate and the local-vs-CI boundary; MEDIUM on exact numeric thresholds (ensemble N, noise band, restraint budgets) — deliberately deferred to phase-level spikes.

---

## The one-sentence finding

**This is ~80% integration, not a greenfield build:** Threadline already ships the monotonic ratchet (`.planning/design-system-ledger.json` + `stress_ledger_test.exs`, in `mix ci.all`), the deterministic critique target (`/audit/__stress`), dark/light Playwright screenshot lanes with committed baselines, accessibility-tree evidence, the source-first `style.ex` token system, brand token-parity tests, the locked personas (`v1.31-PERSONAS-IA.md`), and even the anti-flattery doctrine (`brandbook/pressure-test.md`: "self-assessment is banned; every score cites a mechanical output"). v1.40's genuinely new work is (1) a **page × persona × lens scorecard cube**, (2) one **critic runner** (`e2e/critic/`, Claude vision, dev-only dependency), and (3) a **net-positive-across-lenses gate** on top of the existing ratchet.

## Key Findings

1. **Reuse the ratchet; do not rebuild it.** `design-system-ledger.json` already enforces upward-only scores (unless an explicit reset+rationale), locked IDs, and minimum-score floors via pure-Elixir `stress_ledger_test.exs` in CI. Extend it with `lens_scores` / `persona` / `evidence_ref`.

2. **The decisive design call: MECHANICAL vs LLM-VISION-JUDGED split.** Deterministic code computes token-grid conformance, WCAG contrast, control-count, card-nesting depth, scroll-cost, accent-count, type-size count (the ratchet floor). The vision model judges *only* gestalt it is actually good at — visual hierarchy, spacing rhythm, elegance-vs-accidental, restraint, information scent, brand feel. This neutralizes the #1 footgun (VLMs mis-measure pixels/spacing) **and** verbosity bias (which would otherwise push an operator UI toward *more* chrome).

3. **Validate the critic before it drives anything (the linchpin).** A golden set (~30–50 hand-labeled Threadline states), 75–90% human agreement, and refute-tests: it must score the seeded footgun fixtures (already `25/35`) *low* and polished primitives *high*, prefer the known-better of a curated A/B pair, and catch an injected regression. The stress harness fixtures are ready-made known-good/known-bad anchors. An un-validated critic just optimizes toward a broken oracle — this phase gates everything downstream.

4. **Local-vs-CI boundary is the invariant-defining line.** LLM calls stay local/on-demand (`mix verify.ui_critique`, excluded from `ci.all` — the `verify.flake` precedent). CI runs only deterministic guards: ledger monotonicity, pixel allowlist, a11y coverage, `style_contract_test`. "CI verifies the ledger; the LLM feeds the ledger." The nondeterministic critic can never regress the deterministic floor.

5. **Determinism without a temperature knob** (Opus 4.8 removed `temperature`/`top_p`/prefill): JSON-schema structured output + a frozen, prompt-cached, versioned rubric + few-shot anchors + N-sample self-consistency (median + variance-flag) + band-quantized score bumps. The critic is advisory; humans ratify every bump.

6. **Forward-only failure modes are real and Threadline-specific.** Whack-a-mole via shared tokens/primitives (v1.38 "page polish" = 262 commits from shared-surface blast radius) → full-panel re-eval + blast-radius gating. Goodharting → a first-class held-out "true-north" set + multi-critic panel + human spot-audit. Silent ratchet loosening → append-only diffable ledger, guard-the-guards, pixel-diff kept advisory (never a quality-bar change).

7. **Anti-slop + brand veto.** Anchor to named reference systems, not adjectives; a brand critic vetoes any change that drifts `--tl-*` tokens or reads as "recolored not designed" (the Grafana lesson), gated on the existing token-parity test.

8. **Biggest value risk (SCOPE-1):** an elaborate eval machine that never improves the real UI. Every phase is gated on "≥N fixtures advanced toward target on the real surface," not "harness built."

## Locked decisions (this milestone)

- **Scope:** Build + validate the harness, then prove the loop by driving real improvement on the 2–3 lowest-scoring pages. No full 11-page sweep (avoids the churn the milestone exists to escape).
- **Automation:** Auto-apply deterministic mechanical fixes **and** a *narrow, spike-proven* low-risk-structural whitelist — behind the full-panel net-positive gate, with a first-class held-out true-north set and human sign-off on score-bar bumps.
- **Reference bar:** **Linear = primary model** (dark-native, single-accent, restraint, lead-answer-first hierarchy, calm-but-dense — spans all five personas' JTBD and matches Threadline's brand values). Secondary surface-specific anchors: **Vercel** (dark grid discipline — shell/Home), **Stripe dashboard** (dense tables + export/artifact polish — Prove cluster/P3), **Grafana-done-right** (cautionary "dense data-viz that stays legible" — Timeline/Coverage/diff only).

## Implications for the Roadmap

Dependency-ordered, ~6 phases (continues numbering from v1.39 → starts Phase 194):

- **A — Ledger → scorecard-cube foundation** (Elixir, deterministic, lands in `ci.all`). Depends on nothing; unblocks everything that writes scores.
- **B — Deterministic evidence extractors + tiered capture matrix** (Node/Playwright; token-grid/contrast/control-count/nesting/scroll metrics + evidence bundles: screenshot + DOM + a11y tree + tokens + meta). No LLM yet.
- **C — Critic validation & golden set + versioned anchored rubrics** (the linchpin; must precede the automated ratchet).
- **D — Critic runner + adversarial panel** (`e2e/critic/`, Claude vision, structured output, self-consistency; per-persona + graphic-design + brand-veto; `mix verify.ui_critique`, local-only).
- **E — Evidence/scorecard artifacts + net-positive gate wiring + ONE proven real iteration** on the weakest page (improve target, show no regressions, human-ratified bump).
- **F — Coverage growth on the 2–3 weakest pages + v1.37-style 8-lens adversarial closeout + residual design-debt register** (owner + reopen-trigger per item).

## Invariants preserved

No root (`mix.exs`) runtime dependency (Anthropic SDK is an `examples/threadline_phoenix/e2e` devDependency only); no public component API; dev/test-only fail-closed harness (the `/audit/__stress` pattern); LLM out of `ci.all`; capture/query/auth semantics untouched; PhoenixStorybook stays example/dev-only; no external SaaS visual-diff tool names in committed ledger copy (the ledger's `@forbidden_terms` guard).

## Open questions (phase-level, not blockers)

- Exact ensemble N and ratchet noise-band width — measure empirically against the golden anchor set (Phase C/D spike), not desk research.
- The precise "low-risk structural" auto-apply whitelist — a spike against real `style.ex`/`ui.ex` usage before anything auto-applies (Phase E).
- Full-page vs section-cropped screenshots for the graphic-design critic (image-token/signal tradeoff) — settle on the Phase E seed page.
- Confirm the exact Claude vision model id / image input format / pricing against the `claude-api` skill at Phase D implementation time (do not hardcode from memory).

## Sources

Internal (HIGH): `.planning/design-system-ledger.json`, `test/threadline/operator_surface/stress_ledger_test.exs`, `DESIGN-SYSTEM.md`, `lib/threadline/operator_surface/{style.ex,ui.ex,stress_fixtures.ex,stress_router.ex,live/stress_live.ex}`, `.planning/milestones/v1.31-PERSONAS-IA.md`, `brandbook/{pressure-test.md,brand-book.md,tokens.json}`, `examples/threadline_phoenix/e2e/`, `CLAUDE.md`.

External (MEDIUM–HIGH): see per-report Sources in STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md — LLM-as-visual-judge reliability (UICrit UIST 2024; WebVR; eugeneyan; Appen), bias/Goodhart/homogenization literature (2024–2026), Claude API surface (bundled `claude-api` reference), and design-craft references (Linear/Vercel/Stripe/Grafana).
