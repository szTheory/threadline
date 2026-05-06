# Phase 57: optional-deps-and-module-gating — Discussion Log

**Discussed:** 2026-05-06
**Mode:** discuss-phase (default), with parallel research subagents per area
**Audience:** human reference for retrospectives and audits — NOT consumed by
downstream agents (researcher, planner, executor read `57-CONTEXT.md`).

---

## Context entering discussion

- v1.17 ("Operator Surface Foundation") opened 2026-05-06; Phase 57 is the
  first execution target.
- Roadmap line for Phase 57: "Make Phoenix/LiveView opt-in at install time so
  capture-only adopters never compile UI code." Maps to SURF-02, SURF-03.
- Already locked at milestone planning (carried forward, NOT re-asked):
  - In-tree (not separate `threadline_web` package, deferred to v1.19+)
  - Optional deps approach via `Code.ensure_loaded?` family
  - Sentry-Elixir is the explicit idiomatic anchor
  - Four optional deps to declare: `phoenix`, `phoenix_live_view`,
    `phoenix_html`, `phoenix_pubsub`
- No SPEC.md, `.continue-here.md`, prior CONTEXT.md, or DISCUSS-CHECKPOINT.json
  for Phase 57.
- Phase directory `.planning/phases/57-optional-deps-and-module-gating/`
  created during this discussion.

---

## Pre-discussion research pass

A single parallel research subagent was dispatched before gray-area
presentation (per the user's standing "research-then-recommend" preference) to
inform the gray-area annotations with concrete prior art.

**Subagent dispatched:** "How do mature Elixir libraries declare Phoenix/LV
as optional and gate the resulting modules?"

**Key findings used to annotate the gray-area presentation:**
- Dominant idiom: top-of-file
  `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule ... end`
- Strongest direct anchor: `getsentry/sentry-elixir` —
  `lib/sentry/live_view_hook.ex` and the `mix.exs` optional dep declaration.
- Footgun: do NOT put `if Code.ensure_loaded?(...) do use Phoenix.LiveView end`
  *inside* `defmodule` — that's [elixir-lang/elixir#8970](https://github.com/elixir-lang/elixir/issues/8970).
- Version-constraint trade-off: `~> 1.0` (drops 0.20.x) vs Sentry's dual-range
  `~> 0.20 or ~> 1.0`.
- Verification: official Elixir guidance is
  `mix compile --no-optional-deps --warnings-as-errors`.

---

## Gray areas presented

The discussion surfaced four gray areas. Each was annotated with a recommended
option and a concrete trade-off line backed by the pre-discussion research.

### Q1: Version constraints for the four optional deps
- **Options presented:**
  - `~> 1.7 / ~> 1.0` (recommended — greenfield, drops the 0.20.x branch)
  - Sentry's dual-range (`~> 0.20 or ~> 1.0`)
  - Tight (`~> 1.7 / ~> 1.1`)
- **User's selection:** `~> 1.7 / ~> 1.0` (the recommendation).
- **Notes:** Locked on first ask. Greenfield posture acknowledged — no
  legacy LV 0.20.x adopters to support.

### Q2: Phase 57 module footprint under `lib/threadline/operator_surface/`
- **Options presented:**
  - One smoke module (recommended)
  - No modules — deps + verification only
  - One smoke module + a doc-contract test
- **User's selection:** "research using subagents..." — explicit request for
  per-option research with idiomatic patterns, prior-art lessons, DX/UX
  emphasis, and a coherent recommendation.

### Q3: Verification approach for SC#3 (capture path unchanged when LV absent)
- **Options presented:**
  - Dedicated CI job + `mix verify.compile_no_optional` alias (recommended)
  - Extend `ci.all` only (no separate CI job)
  - Defer verification to Phase 58
- **User's selection:** same "research using subagents..." request.

### Q4: Plug posture in Phase 57
- **Options presented:**
  - Leave Plug as hard dep (recommended)
  - Flip Plug to optional for symmetry
- **User's selection:** same "research using subagents..." request.

---

## Per-area research dispatch

Three parallel subagents were dispatched (one per outstanding area) with
detailed prompts requesting:
- Idiomatic patterns in Elixir/Plug/Phoenix/Ecto for this kind of library
- Prior-art lessons (including cross-language analogs where relevant)
- Developer ergonomics / UX emphasis
- A single coherent recommendation per area
- Cited real repos / file paths / docs URLs

### Q2 subagent — Module footprint
- **Recommendation:** **Option B** (one smoke module). Defer the doc-contract
  test to Phase 58 where the test helper is reusable.
- **Anchor:** `getsentry/sentry-elixir` PR
  [#722](https://github.com/getsentry/sentry-elixir/pull/722) shipped the gated
  module + optional dep declaration + companion test atomically. Threadline's
  variation: ship gated module + deps in Phase 57; defer test to Phase 58.
- **Reconciliation logic:** `verify.compile_no_optional` needs a target to
  verify; without a gated module the CI step is theatre. One namespace
  module is the smallest concrete artifact that exercises the wrapper.
- **Footgun mitigation:** moduledoc says "since 0.4.0" + forward-references
  Phase 58's mount macro so adopters reading hexdocs aren't surprised.

### Q3 subagent — Verification approach
- **Recommendation:** **Option A** (alias + dedicated CI job).
- **Anchors:**
  - Elixir Library Guidelines (https://hexdocs.pm/elixir/library-guidelines.html) —
    normative `--no-optional-deps` recommendation.
  - `wojtekmach/req` `.github/workflows/ci.yml` — minimum-credible precedent
    (Wojtek Mach, Elixir core team).
  - Sentry-Elixir's CI lacks this job — acknowledged omission, not a
    deliberate engineering choice.
- **Reconciliation logic:** Sentry's gap costs them protection against the
  exact regression Threadline is most exposed to (capture-only adopters
  pulling a release where someone forgot a `Code.ensure_loaded?` wrapper or a
  transitive Phoenix reference leaked into the capture path). Sentry's
  adopters all have Phoenix; Threadline's specifically may not. Replicating
  Sentry's gap inverts the value proposition.
- **Cost analysis:** ~45s/push CI minutes, one YAML stanza, one immutable
  job-id to maintain — already part of the convention this repo enforces.

### Q4 subagent — Plug posture
- **Recommendation:** **Option A** (leave `:plug` as hard dep).
- **Anchors:**
  - `phoenix_ecto`, `ueberauth`, `plug_cowboy`, `bandit` all hard-Plug
    (libraries whose core surface speaks `Plug.Conn`).
  - Sentry-Elixir's optional-Plug works because Sentry's core is exception
    capture — Plug is one of N integrations. Not symmetric to Threadline's
    `Threadline.Plug` which IS core capture.
  - Carbonite (closest peer — Postgres trigger-based audit) has no Plug at
    all because capture is pure Repo. Threadline diverges by design.
- **Reconciliation logic:** "Optional where the surface is optional" is the
  right frame, NOT "symmetric web-dep optionality." Phoenix/LV gate the
  *operator surface* (genuinely opt-in for capture-only adopters); Plug
  gates the *capture surface* (the product itself). Flipping Plug optional
  taxes 4 gating sites (`lib/threadline/plug.ex` 154 lines + `integrations/
  sigra.ex` typespecs + `test/support` + the new mount macro) for a phantom
  Ecto-only cohort that does not exist in Threadline's stated target
  audience (Phoenix/Ecto/Postgres teams per
  `prompts/THREADLINE-GSD-IDEA.md`).
- **Scope guard:** Phase 57's roadmap line scopes optionality to
  Phoenix/LiveView only. Touching Plug would be scope creep.

---

## Synthesized recommendation set presented

The four converged recommendations were presented as a single coherence
table with explicit reinforcement notes:
- Q1 + Q2: tight `~> 1.0` LV + smoke module = simplest wrapper code with
  one clear test target.
- Q2 + Q3: smoke module gives the verify job something concrete to verify.
- Q3 + Q4: dedicated CI job catches operator-surface regressions; leaving
  Plug hard means the gating surface is not multiplied across capture
  wiring.
- Q4 + Q1: hard Plug + tight LV = narrow gating surface (one optional-dep
  family, one gated namespace).

Five landmines were flagged for the planner:
1. Wrap `defmodule` at file scope, not `use` inside it
   (elixir-lang/elixir#8970).
2. No empty `.ex` placeholder stubs.
3. Dialyzer runs only in the all-deps-present CI cell.
4. `@moduledoc` should state "since 0.4.0" + forward-reference Phase 58.
5. Don't touch `package: [files: ...]` in `mix.exs` — `lib` already covers.

**User's final answer:** "Approve all four (Recommended)" — full set locked.

---

## Deferred ideas captured in CONTEXT.md

See the `<deferred>` block of `57-CONTEXT.md` for the canonical list. Highlights:
- Mount macro + `:authorize_fn` contract + telemetry → Phase 58.
- Doc-contract test for the gated namespace → Phase 58 (reusable helper).
- CHANGELOG `0.4.0` entry → Phase 63.
- Splitting `threadline_web` companion package → v1.19+.
- Flipping `:plug` to optional → out of scope; revisit only on adopter ask.

---

## Non-blocking notes for retrospective

- The pre-discussion single-shot research call covered the main idiom + version
  question well; the per-area parallel dispatch on Q2/Q3/Q4 was needed because
  the user explicitly requested it after the first AskUserQuestion (citing the
  standing "shift research-then-recommend left in GSD" preference).
- Total subagents dispatched: 1 (pre-discussion) + 3 (per-area) = 4. Same
  shape as v1.17 milestone planning's three parallel research agents
  (recorded in `.planning/STATE.md`'s 2026-05-06 decisions block).
- The user's preference is already encoded in
  `~/.claude/projects/-Users-jon-projects-threadline/memory/gsd-research-then-recommend.md`;
  no new memory entry needed from this discussion.

---

*Phase: 57-optional-deps-and-module-gating*
*Discussion logged: 2026-05-06*
