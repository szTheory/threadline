# Phase 197: Coverage Growth, Adversarial Closeout & Design-Debt Register - Research

**Researched:** 2026-08-26
**Domain:** In-repo forward-only critic loop (Phase 194–196 machinery), adversarial closeout artifacts, planning-artifact registers. No external technology research required — every dependency already exists in-tree.
**Confidence:** HIGH (all findings read from repo source/artifacts this session)

## Summary

Phase 197 is ~90% *operating and documenting existing machinery*, not building new machinery. PROOF-02 runs the already-proven forward-only loop (CONTRIBUTING.md "Forward-only gate — run one iteration", built and exercised for real in Phase 196) on 2–3 of the lowest-scoring operator pages, each ending in a maintainer-ratified `ratchet.signoffs` entry + append-only pin. PROOF-03 reproduces the v1.37 adversarial-closeout shape (`180-ADVERSARIAL-REVIEW.md`: a multi-lens review table + findings + follow-through, backed by green deterministic guards and adversarial probes against the guard tests). PROOF-04 writes a design-debt register in the v1.39 risk-register shape (`193-RISK-REGISTER.md`: ranked rows, each with Owner + concrete reopen-trigger, adoption/ops/maintainer ranking lens, no vague "polish later" bucket) — the seed items are already enumerated in `196-06-SUMMARY.md` "Deferred to Phase 197".

The hard part of planning this phase is not technical novelty; it is **sequencing around the maintainer-gated, paid, local-only LLM steps** (196-D9: executor has no `ANTHROPIC_API_KEY`; the LLM never runs in CI) and **honoring the loop-hygiene gotchas Phase 196 discovered the hard way** (verdict-cache staleness, before-pole overwrite, Tier-A recapture drift). Every PROOF-02 iteration must be structured as: capture → cache-busted before-score → human-authored edit → re-capture → cache-bust → `critic:gate` → `verify.mechanical` floor → maintainer ratification checkpoint → signoff + pin commit. An honest REJECT is a valid loop outcome, but PROOF-02 requires *landed* improvement, so plans need the 196-style pivot fallback (weakest page rejected → next candidate).

**Primary recommendation:** Plan 3 lanes — (1) PROOF-02 as 2–3 maintainer-checkpointed gate iterations using the existing runbook verbatim, with page/lens selection ratified from a fresh cache-busted route.* score run; (2) PROOF-03 as a `197-ADVERSARIAL-REVIEW.md` mirroring the 180 D-12 lens-table shape, evidenced by green `verify.critic_trust`/`verify.mechanical`/`verify.doc_contract` plus tamper-probe demonstrations; (3) PROOF-04 as `197-DESIGN-DEBT-REGISTER.md` in the 193 shape seeded from the 196-06 debt list. Register GATE-02 "true auto-write" as debt with a reopen-trigger rather than building it (open question OQ-1).

## User Constraints (no CONTEXT.md)

No `197-CONTEXT.md` exists. However, **Phase 196's locked decisions [196-D1..D9] remain binding on the loop this phase operates** — they are recorded GATE-04 sign-offs, not suggestions. The planner MUST treat these as locked:

- **[196-D1]** The gate is RELATIVE (ranking Δ vs IQR noise), never absolute-score; blast-radius-aware re-eval for shared tokens/primitives. `[VERIFIED: .planning/phases/196-forward-only-net-positive-gate-first-proven-iteration/196-CONTEXT.md:45-51]`
- **[196-D2]** Blocking panel = `brand_fidelity`, `density`, `typography`, `rhythm`. `hierarchy` + `color_contrast` are advisory only, never block, findings verified vs ground truth before action (they hallucinate specifics). Panel changes require a new recorded sign-off. `[VERIFIED: 196-CONTEXT.md:53-59]`
- **[196-D3]** `verify.mechanical` is the non-negotiable deterministic floor; mechanical fixes are **surface-a-diff** (human applies); structural whitelist starts empty; "True auto-write to source is deferred to **Phase 197**'s first escalation." `[VERIFIED: 196-CONTEXT.md:61-74]` — see OQ-1.
- **[196-D4]** Synthetic oracle is held-out true-north, never optimized against; divergence halts the loop. `[VERIFIED: 196-CONTEXT.md:76-81]`
- **[196-D5]** `verify.critic_trust` is the append-only guard-the-guards. `[VERIFIED: 196-CONTEXT.md:83-87]`
- **[196-D6]** Pixel-diff stays advisory; baseline refresh only after semantic guards pass. `[VERIFIED: 196-CONTEXT.md:89-92]`
- **[196-D8]** Real-UI source = `route.*` cells only (never `page.*` stress-lab chrome, never `story.*` fixtures). `[VERIFIED: 196-CONTEXT.md:103-108]`
- **[196-D9]** LLM critic stays local-only, out of CI, bounded (N=3→7, ~$0.015/call), blast-radius scoped. `[VERIFIED: 196-CONTEXT.md:110-114]`
- **Standing invariants:** "no root runtime dependency; no public component API; dev/test-only; LLM stays out of CI; capture / query / auth semantics untouched; brand-token parity green" `[VERIFIED: 196-CONTEXT.md:153-154]` — these are literally what PROOF-03's closeout must confirm.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-02 | Real, ratified improvement on the 2–3 lowest-scoring operator pages — each targeted lens advanced toward its `target_score`, no regressions | Runbook + gate CLI verified working (196 PROOF-01 accept exists); candidate pages ranked below from live route.* scores; iteration hygiene pitfalls catalogued |
| PROOF-03 | v1.37-style multi-lens adversarial closeout — loop cannot regress the deterministic floor; all invariants hold | 180-ADVERSARIAL-REVIEW.md shape documented; guard inventory (critic_trust 22 tests, mechanical 18 tests, doc-contract) mapped; tamper-probe strategy outlined |
| PROOF-04 | Residual design-debt register with owner + reopen-trigger in v1.39 risk-register shape | 193-RISK-REGISTER.md shape documented; seed debt items enumerated from 196-06-SUMMARY + STATE.md with file-level root causes verified |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PROOF-02 UI edits | LiveView templates (`lib/threadline/operator_surface/live/*.ex`) | LiveView tests | The loop edits real `/audit` page renderings; capture/query/auth untouched (invariant) |
| Route capture + scoring | e2e harness (`examples/threadline_phoenix/e2e/`) | — | Playwright route-capture project + `critic/run.ts`/`gate.ts`; local-only, gitignored outputs |
| Gate verdict + ratification | Maintainer-local CLI (`npm run critic:gate`) | Ledger (`.planning/design-system-ledger.json`) | Paid LLM re-eval is maintainer-local (196-D9); verdict lands as append-only `ratchet.signoffs` |
| Deterministic floor | `mix verify.mechanical` (ExUnit, CI) | Committed `page.*.happy` scorecards | MODE-A/B checks over committed twins; the only hard block in CI |
| Guard-the-guards | `mix verify.critic_trust` (ExUnit, CI) | `critic_trust_test.exs` `@known_signoffs` pins | Append-only ledger enforcement; each new signoff must be pinned here |
| PROOF-03 closeout artifact | `.planning/phases/197-*/` markdown | Guard test runs as evidence | Review artifact, not code — mirrors 180-ADVERSARIAL-REVIEW.md |
| PROOF-04 debt register | `.planning/phases/197-*/` markdown | — | Planning artifact in 193-RISK-REGISTER shape; no product code |

## Standard Stack

No new libraries. No package installation. **Package Legitimacy Audit: N/A — zero external packages are added this phase.** Everything is already in-tree:

| Tool | Location | Purpose | Status |
|------|----------|---------|--------|
| `npm run capture:pages` | `e2e/package.json:12` → `operator-page-capture.spec.ts` (route-capture project) | Capture live `route.*` cells (gitignored) | `[VERIFIED: examples/threadline_phoenix/e2e/package.json:12]` `"capture:pages": "playwright test --project=route-capture operator-page-capture.spec.ts"` |
| `npm run critic:score -- --page route.<x>` | `e2e/package.json:13` → `critic/run.ts score` | Before-pole snapshot (4 blocking + 2 advisory lenses) | `[VERIFIED: package.json:13]` `"critic:score": "tsx critic/run.ts score"` |
| `npm run critic:gate -- --page route.<x> --lens <lens>` | `e2e/package.json:14` → `critic/gate.ts` | 7-step accept/reject pipeline (blast radius → mechanical floor → rank re-eval → divergence halt → advisory report → verdict) | `[VERIFIED: package.json:14]` `"critic:gate": "tsx critic/run.ts gate"`; flags `--page`, `--lens`, `--dry-run`, `--force`, `--n` `[VERIFIED: e2e/critic/gate.ts:113-132]` |
| `npm run capture:refute` | `e2e/package.json:10` | Recover clipped refute-pole PNGs if clobbered | `[VERIFIED: package.json:10]` |
| `npm run critic:report:html` | `e2e/package.json:18` | Human-reviewable critique viewer | `[VERIFIED: package.json:18]` |
| `mix verify.mechanical` | `mechanical_checker_test.exs` | Deterministic hard floor (18 tests as of 196 close) | `[VERIFIED: 196-VERIFICATION.md / STATE.md "critic_trust 22/0, mechanical 18/0"]` |
| `mix verify.critic_trust` | `critic_trust_test.exs` | GATE-04 append-only guard (22 tests) | same |
| `mix ci.all` | `mix.exs` | Full deterministic gate; excludes `verify.ui_critique` | `[VERIFIED: CONTRIBUTING.md:318-320]` |

**Environment note:** `route.*` capture needs the seeded dev server (`e2e/run-e2e.sh`) `[CITED: CONTRIBUTING.md:342]`.

## Current Score Landscape (PROOF-02 target selection input)

Local (uncommitted, gitignored-by-design) `route.*` critic scores, median across score files per lens directory `[VERIFIED: computed from .planning/critic-scores/route.*__dark-1280/<lens>/*.json this session — these are LOCAL artifacts; treat as stale until a fresh cache-busted re-score]`:

| route cell | brand_fidelity | density | typography | rhythm | (advisory: hierarchy / color_contrast) |
|---|---|---|---|---|---|
| route.retention | 80.5 | **49.5** (pre-196-accept; +7 landed) | 67 | 69.0 | 63 / 24 |
| route.actor | 82.0 | **54.5** | 78.0 | 68.5 | 66 / 67 |
| route.evidence | 81.5 | **60** | **66** | 68.5 | 22 / 29 |
| route.timeline | 80.5 | 64 | **66** | **63** | 22 / 30 |
| route.coverage | 82.5 | 69 | 79 | 67.5 | 69 / — |

**Reading (blocking lenses only — advisory numbers must never drive selection, 196-D2):** the weakest (page, lens) cells are `actor×density`, `evidence×density`/`evidence×typography`, `timeline×rhythm`/`timeline×typography`, and `retention×density` (already advanced +7 in 196). Ledger `target_score` for all page entries is **90** with legacy current 62 `[VERIFIED: design-system-ledger.json entries, e.g. "page.actor.happy" current_score 62, target_score 90]` — but per 196-D1 "advanced toward target_score" is proven by a gate-ACCEPT (Δ > IQR noise, no regressions), never by hitting an absolute number.

**Critical caveat from 196:** the evidence-page density candidate was honestly REJECTED three times — "Evidence page structural density (six one-row sections paying full section scaffolding) — needs an IA pass, not chrome removal" `[VERIFIED: 196-06-SUMMARY.md:89]`. If evidence is selected, the edit must be an IA restructure, or pick a different page/lens.

**Route lane is fixed at 5 routes.** Only `route.timeline`, `route.coverage`, `route.retention`, `route.actor`, `route.evidence` have committed `page.<x>.happy` mechanical-floor twins and rows in `ROUTE_PAGE_TWIN` + the CONTRIBUTING twin table (pinned by `forward_only_gate_doc_contract_test.exs`) `[VERIFIED: CONTRIBUTING.md:327-335; 196-04-SUMMARY provides]`. Targeting any other page (home, exports, transaction…) requires expanding the capture spec, `ROUTE_PAGE_TWIN`, the CONTRIBUTING table, and the doc-contract test in lockstep — plan that as explicit tasks if chosen.

## Architecture Patterns

### PROOF-02 iteration pipeline (the only correct shape)

```
seeded dev server up (e2e/run-e2e.sh)
  → npm run capture:pages                          # fresh route.* PNGs + scorecards (local)
  → rm .planning/critic-verdict-cache/<cell>__*.json   # BUST CACHE (keyed cell+rubric+model, NOT screenshot)
  → npm run critic:score -- --page route.<x>       # BEFORE pole (maintainer, paid) — never re-run after the edit
  → [checkpoint:human-verify] maintainer ratifies target (page, lens)
  → human-authored edit to lib/threadline/operator_surface/live/<x>_live.ex (+ LiveView tests)
  → npm run capture:pages                          # AFTER capture
  → rm .planning/critic-verdict-cache/<cell>__*.json   # bust again
  → npm run critic:gate -- --page route.<x> --lens <lens>   # relative verdict (maintainer, paid)
  → mix verify.mechanical                          # deterministic floor on committed page.<x>.happy twin
  → [checkpoint:human-action] maintainer ratifies ACCEPT/REJECT
  → ACCEPT: append ratchet.signoffs (kind: forward_only_accept) + pin in critic_trust_test @known_signoffs
            + commit source diff + ledger + pin  (route.* scorecards + CRITIQUE.md stay uncommitted)
  → REJECT: keep/land edit as ordinary unratified cleanup (tests+floor green) OR revert; pivot to next candidate
```

Source: CONTRIBUTING.md:337-367 (runbook) + the 196-06 execution record. The signoff entry shape to replicate `[VERIFIED: design-system-ledger.json ratchet.signoffs[0]]`:

```json
{ "kind": "forward_only_accept", "target": "route.retention__dark-1280", "lens": "density",
  "delta": 7, "noise_floor": 4.5,
  "before": { "signal_to_chrome": 32, "task_primary_prominence": 67,
              "panel": { "brand_fidelity": 80, "density": 32, "typography": 67, "rhythm": 68 } },
  "verdict": "ACCEPT", "date": "2026-08-26",
  "ratified_by": "maintainer (in-session PROOF-01 ratification, phase 196-06)",
  "commit": "c6f9355e", "notes": "..." }
```

Every new ACCEPT needs a matching append-only pin in `test/threadline/operator_surface/critic_trust_test.exs` `@known_signoffs` (GATE-04) — the 196 precedent is commit f1610d87 `[VERIFIED: 196-06-SUMMARY.md:72-73]`.

### PROOF-03 closeout artifact shape (v1.37 precedent)

`180-ADVERSARIAL-REVIEW.md` structure `[VERIFIED: .planning/milestones/v1.37-phases/180-.../180-ADVERSARIAL-REVIEW.md:1-35]`: YAML frontmatter (`phase / artifact: adversarial-review / created / status: passed / requirement`), a **lens-review table** (| Lens | Review | Result |), a **Findings** section (blocking issues or explicit "none"), and **Follow-Through** bullets. For 197, replace the 180 D-12 lenses with the loop invariants the ROADMAP names: no root runtime dep, no public API, dev/test-only, LLM out of CI, capture/query/auth untouched — plus "loop cannot regress the deterministic floor."

**Evidence per lens should be adversarial, not assertion-only.** The guards already encode tamper resistance; the closeout should *demonstrate* it (locally, reverting after):
- Drop a `trust_floors`/`ratchet.minimum_scores` value without a signoff → `verify.critic_trust` fails (no-silent-target-drop guard) `[VERIFIED: 196-02-SUMMARY provides]`
- Remove an oracle fixture / shrink `synthetic_item_count` → fails (no-fixture-removal guard) `[VERIFIED: 196-02-SUMMARY provides]`
- Delete the pinned signoff → fails (append-only pin) `[VERIFIED: 196-02-SUMMARY provides]`
- Add to `mechanical_auto_apply.structural_whitelist` (currently `[]` `[VERIFIED: design-system-ledger.json mechanical_auto_apply {"structural_whitelist": []}]`) without a `structural_whitelist_add` signoff → fails
- Confirm `ci.all` contains `verify.critic_trust` → `verify.mechanical` and excludes `verify.ui_critique` (LLM out of CI) — pinned by `forward_only_gate_doc_contract_test.exs` which also "asserts the critic never leaks into guides/" `[VERIFIED: 196-04-SUMMARY provides]`
- Runtime-dep / public-API / capture-query-auth invariants: cite existing source/doc contract tests + `git diff` scope of the phase

### PROOF-04 register shape (v1.39 precedent)

`193-RISK-REGISTER.md` structure `[VERIFIED: .planning/milestones/v1.39-phases/193-.../193-RISK-REGISTER.md:1-49]`: frontmatter with `clause / ranking_lens / source_precedence / seed / status`; ranked rows in the "Area / Residual / Owner-Scope / Impact / Next Action" format **extended with an explicit Owner and a concrete reopen-trigger on every row**; ranking on the **adoption / operations / maintainer-risk** lens, NOT severity×likelihood ("A one-line severity note per row is allowed as secondary color"); a Verdict section; and the structural rule that "this structurally forbids a bare polish-later bucket."

**Seed debt items (verified root causes):**

| # | Item | Root cause location | Notes |
|---|------|--------------------|-------|
| 1 | Verdict cache not screenshot-keyed (stale-verdict hazard; manual `rm` workaround) | `cacheKey(cellId, dimension, rubricHash, modelId)` — no screenshot hash input `[VERIFIED: e2e/critic/cache.ts:43,68]` | Fix candidate: add screenshot sha to the key; or register with reopen-trigger |
| 2 | `critic:score` after an edit silently overwrites the gate's before pole in `.planning/critic-scores/` | gate.ts reads the snapshot "the maintainer runs BEFORE editing" and errors only when absent `[VERIFIED: e2e/critic/gate.ts:303,394]` | Fix candidate: write-protect/pole-stamp before files |
| 3 | Tier-A recapture drift — systematic `scroll_cost` shifts; ~36k-px fullPage stress shots clobbered clipped refute poles (recovered via `capture:refute`) | `[VERIFIED: 196-06-SUMMARY.md:88 + key-decisions]` "Tier-A recapture is NOT reproducible in this environment" | Floors gate committed cells; drifted scorecards were reverted |
| 4 | Evidence page structural density — "needs an IA pass, not chrome removal" | `[VERIFIED: 196-06-SUMMARY.md:89]` | May instead be consumed as a PROOF-02 target |
| 5 | GATE-02 true auto-write to source (deferred to "Phase 197's first escalation") | `[VERIFIED: 196-CONTEXT.md:74]` | See OQ-1 — recommend register-as-debt |
| 6 | `color_contrast` at ρ0.698 (0.002 under the line) — promotion needs re-validation + GATE-04 signoff | `[VERIFIED: 196-CONTEXT.md:35,184-185]` | Advisory forever until re-validated |
| 7 | `hierarchy` lens near-chance (ρ0.42) | `[VERIFIED: 196-CONTEXT.md:36]` | Persona fan-out already collapsed |
| 8 | Pre-existing 3-module doc-contract baseline (V123Charter / FormlessPages / Phase06Nyquist) red in full suite | `[VERIFIED: 196-06-SUMMARY.md:81-82 + deferred-items.md]` "pre-existing, out of scope, tracked since 195-10" | Candidate row or explicit out-of-scope note |
| 9 | ~81 local `mix test` failures = search_path env issue (maintainer-friction, not regression; confirmed fix `ALTER DATABASE ... SET search_path`) | `[ASSUMED — from project memory local-test-db-storage-schema-failures; verify current count before registering]` | Was 193 register row R-D |

### Anti-Patterns to Avoid

- **Scoring `page.*` or `story.*` cells for the gate** — 196-D8: `route.*` only. `page.*` = stress-lab dev chrome (invalid), `story.*` = isolated fixtures.
- **Acting on advisory-lens findings unverified** — hierarchy/color_contrast confidently invent specifics (a nonexistent hex was fabricated in prior scoring). Verify vs ground truth first; never let them drive selection or verdicts.
- **Absolute-score gating** — the panel ranks well but its absolute scale is compressed; only Δ-vs-IQR-noise verdicts are valid.
- **Recapturing Tier-A `page.*` scorecards** — known systematic drift; the committed scorecards are the floor. Don't regenerate them as part of PROOF-02.
- **Committing `route.*` scorecards or `.planning/CRITIQUE.md`** — uncommitted by design; only the reviewed ledger signoff + pin + source diff are committed.
- **Bumping ledger floors/targets in the same breath as the edit** — any floor/target/panel change needs its own recorded signoff or `verify.critic_trust` fails.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Accept/reject decision | New gate logic | `npm run critic:gate` (gate.ts 7-step pipeline) | Already implements blast radius, N-escalation, IQR noise, divergence halt, advisory badging |
| Floor enforcement | New checks | `mix verify.mechanical` + committed `page.<x>.happy` twins | 18 deterministic tests; MODE-A/B |
| Ratification record | New format | `ratchet.signoffs` entry (shape above) + `@known_signoffs` pin | GATE-04 machinery enforces it |
| Closeout format | New template | 180-ADVERSARIAL-REVIEW.md shape | "v1.37-style" is the literal requirement |
| Register format | New template | 193-RISK-REGISTER.md shape | "v1.39 risk-register shape" is the literal requirement |
| Loop documentation | New runbook | CONTRIBUTING.md "Forward-only gate — run one iteration" (doc-contract-pinned) | Update only if the loop itself changes; test must move in lockstep |

## Common Pitfalls

### Pitfall 1: Stale verdict cache silently fakes before/after
**What goes wrong:** cache key = cell+rubric+model, not screenshot; a re-score after re-capture returns the old verdict.
**How to avoid:** `rm .planning/critic-verdict-cache/<cell>__*.json` before EVERY re-score after a re-capture. Make it an explicit task action, both poles.
**Warning signs:** identical scores across an edit; instant (non-billed) "scoring".

### Pitfall 2: Before-pole overwrite
**What goes wrong:** running `critic:score` after the edit overwrites the before snapshot; the gate then compares after-vs-after.
**How to avoid:** the only post-edit command is `critic:gate` (it re-scores internally). Sequence this in plan actions verbatim.

### Pitfall 3: Executor can't run the paid steps
**What goes wrong:** `ANTHROPIC_API_KEY` is unset in the execution environment (verified this session); `capture`/`score`/`gate` are maintainer-local. Plans that assume the executor scores pages will stall.
**How to avoid:** structure every score/gate step as `checkpoint:human-action` with the exact commands to paste (the 196-05/196-06 precedent — maintainer authorized running the paid loop in-session). Deterministic steps (`verify.mechanical`, `verify.critic_trust`, LiveView tests, edits) remain executor-run.

### Pitfall 4: REJECT stalls PROOF-02
**What goes wrong:** the gate genuinely discriminates (3 evidence variants rejected in 196). Two or three ACCEPTs are not guaranteed on the first candidates.
**How to avoid:** rank ≥4 candidate (page, lens) cells up front; plan the pivot as a first-class path; each accepted page = independent success unit so partial completion is legible.

### Pitfall 5: rhythm instability on real routes
**What goes wrong:** rhythm (ρ0.76, lowest trusted) + non-deterministic `scroll_cost` jitter; unstable verdicts are VOID per 196-D1 practice (v3 evidence variant went VOID).
**How to avoid:** prefer density/typography targets where available; use `--n 7` escalation on unstable cells; treat VOID as REJECT-equivalent for planning.

### Pitfall 6: Doc-contract lockstep
**What goes wrong:** touching the runbook, twin table, or route lane without updating `forward_only_gate_doc_contract_test.exs` (and vice-versa) breaks `verify.doc_contract` in `ci.all`.
**How to avoid:** any CONTRIBUTING/route-lane change task must name the test file in the same task.

### Pitfall 7: GSD state tooling
**What goes wrong:** `gsd-sdk query state.begin-phase` with flag-style args can corrupt `.planning/STATE.md`; `state.advance-plan`/`update-progress` miscompute the bespoke progress block.
**How to avoid:** positional args (`phase`, `slug`, `plan_count`) per CLAUDE.md; hand-correct progress after state.* calls (project memory).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node | e2e harness | ✓ | v24.19.0 | — |
| Playwright | capture lane | ✓ | 1.60.0 | — |
| Elixir/OTP | mix gates | ✓ | 1.19.5 / OTP 28 | — |
| PostgreSQL | tests/dev server | ✓ | accepting (:5432) | — |
| `ANTHROPIC_API_KEY` | score/gate steps | ✗ (unset in executor env) | — | **checkpoint:human-action — maintainer runs paid steps locally (by design, 196-D9)** |
| Seeded dev server | route capture | run on demand | `e2e/run-e2e.sh` | — |

**Missing with no fallback:** none — the API key absence is by design, not a blocker, provided plans checkpoint the paid steps.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (via named mix aliases) + Playwright (e2e) |
| Config | `mix.exs` `preferred_envs: ["ci.all": :test]` |
| Quick run | `mix verify.critic_trust && mix verify.mechanical` |
| Full suite | `mix ci.all` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROOF-02 | Edited page renders correctly, no regressions | unit/LiveView | `mix test test/threadline/operator_surface/live/<page>_live_test.exs` | ✅ (per-page tests exist; extend per edit) |
| PROOF-02 | Signoff pinned append-only | unit | `mix verify.critic_trust` | ✅ (add pin per accept) |
| PROOF-02 | Deterministic floor holds | unit | `mix verify.mechanical` | ✅ |
| PROOF-02 | Gate verdict ACCEPT | manual-only (paid LLM, maintainer-local by 196-D9) | `npm run critic:gate -- --page route.<x> --lens <lens>` | ✅ |
| PROOF-03 | Guards reject tampering | unit (probe then revert) | `mix verify.critic_trust` (expected FAIL under probe, PASS after revert) | ✅ |
| PROOF-03 | Runbook/CI posture pinned | unit | `mix verify.doc_contract` (forward_only_gate_doc_contract_test) | ✅ |
| PROOF-04 | Register exists in shape | manual review (optionally a small doc-contract test) | — | ❌ new artifact |

### Sampling Rate
- **Per task commit:** `mix verify.critic_trust && mix verify.mechanical` + the touched page's LiveView test file
- **Per wave merge:** `mix compile --warnings-as-errors && mix format --check-formatted && mix verify.doc_contract`
- **Phase gate:** `mix ci.all` green *except* the pre-existing 3-module doc-contract baseline (V123Charter/FormlessPages/Phase06Nyquist — tracked since 195-10; verify count unchanged, don't fix here)

### Wave 0 Gaps
None — existing test infrastructure covers all phase requirements. (Optional: a tiny doc-contract test for the 197 register/closeout artifacts, at planner's discretion.)

## Security Domain

This phase adds no attack surface: no new deps, no public API, no capture/query/auth changes (invariant), dev/test-only surfaces. Relevant ASVS categories are already enforced and must merely stay untouched: V4 access control (operator auth fail-closed — invariant "capture/query/auth untouched"), V5 input validation (no new inputs). The one security-adjacent obligation is PROOF-03 itself: adversarially confirming LLM stays out of CI and no root runtime dependency appears (supply-chain posture). STRIDE lens for the loop: **Tampering** with the ledger/floors is the threat model — mitigated by the GATE-04 append-only guards, which PROOF-03 probes.

## State of the Art (project-local)

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Krippendorff α agreement bar | Spearman ρ ≥ 0.70 ranking bar vs synthetic oracle | Phase 195 | Gate is relative; α phrasing in docs is stale if found |
| 5-persona fan-out on hierarchy/density | 1 collapsed persona ("all" critic) | Phase 195 | ~5x cheaper scoring |
| route.timeline-only lane | 5-route lane with `ROUTE_PAGE_TWIN` complete | 196-04 / 196-06 fix 83db3918 | All five candidate pages gate-able |
| Playwright default `#FF00FF` maskColor | Dark surface-token maskColor on route lane | 196-06 (83db3918) | No mask contamination in scores |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ~81 local test failures (search_path) still present at current count | Debt seeds #9 | Register row overstates/understates; verify with one `mix test` run before writing the row |
| A2 | Local route.* score medians are representative enough to pre-rank candidates | Score landscape | Selection must be re-ratified from a fresh cache-busted score run anyway (mitigated by checkpoint) |
| A3 | Register/closeout artifacts live in `.planning/phases/197-*/` (like 180/193 precedents) | PROOF-03/04 | Cosmetic; planner's discretion |

## Open Questions (RESOLVED)

1. **OQ-1 — Is GATE-02 "true auto-write to source" in 197 scope?** 196-D3 deferred it to "Phase 197's first escalation," but 197's requirements are only PROOF-02/03/04 and the structural whitelist is `[]` with a signoff-gated add. *Recommendation:* do NOT build it; register it as a debt row with a concrete reopen-trigger (e.g. "≥N accepted iterations where the surfaced diff was applied verbatim with zero human modification"). Confirm with maintainer at discuss/checkpoint.
   **RESOLVED:** Register-as-debt. GATE-02 auto-write is NOT built in Phase 197; it lands as a debt-register row with a concrete reopen-trigger, implemented by Plan 197-05.
2. **OQ-2 — Does retention (already advanced in 196) count toward the "2–3 pages"?** 196-D7 says PROOF-01 "pulls one page's worth of PROOF-02 forward." *Recommendation:* plan for 2–3 NEW accepted improvements in 197 (actor, evidence-or-timeline, +1 stretch), counting retention as bonus coverage only — satisfies the requirement under either reading.
   **RESOLVED:** 2–3 NEW accepted improvements in 197; retention counts as bonus coverage only. Implemented by Plans 197-02 through 197-04 (candidate ratification, iterations 1–2, accept-count closure).
3. **OQ-3 — Fix loop-debt items #1/#2 (cache key, before-pole) inside 197, or register only?** They directly threaten PROOF-02 measurement integrity and are small, local, deterministic (cache.ts key + a pole-protection guard). *Recommendation:* fix #1 and #2 as a Wave-1 hardening plan before running iterations (cheap, de-risks every paid run); register #3 (Tier-A drift) and the rest.
   **RESOLVED:** Fix-in-phase. The cache-key and before-pole fixes land in Plan 197-01 (Wave-1 hardening, before any paid iteration); remaining loop-debt items (#3+) are registered only, via Plan 197-05.

## Sources

### Primary (HIGH confidence — read from repo this session)
- `.planning/phases/196-.../196-CONTEXT.md` — locked decisions D1–D9, invariants, risks
- `.planning/phases/196-.../196-06-SUMMARY.md` — PROOF-01 execution record, 197 debt seeds
- `CONTRIBUTING.md:312-383` — forward-only gate runbook + twin table + invariants
- `.planning/milestones/v1.37-phases/180-.../180-ADVERSARIAL-REVIEW.md` — PROOF-03 shape
- `.planning/milestones/v1.39-phases/193-.../193-RISK-REGISTER.md` — PROOF-04 shape
- `.planning/design-system-ledger.json` — signoff shape, critic_panel, mechanical_auto_apply, page targets
- `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md` — phase framing
- `examples/threadline_phoenix/e2e/{package.json, critic/gate.ts, critic/cache.ts}` — CLI truth
- `.planning/critic-scores/route.*` — local score landscape (uncommitted; stale-until-rescored)

### Tertiary (LOW confidence)
- Project memory notes (search_path failure count) — marked `[ASSUMED]`

## Metadata

**Confidence breakdown:**
- Loop mechanics & constraints: HIGH — read from locked CONTEXT + runbook + executed-precedent summaries
- Artifact shapes (PROOF-03/04): HIGH — literal precedent files read
- Candidate page ranking: MEDIUM — computed from local uncommitted scores; must be re-ratified live
- Debt-item root causes: HIGH for #1–#8 (file-level verification), LOW for #9

**Research date:** 2026-08-26
**Valid until:** ~30 days (in-repo machinery; only the local score landscape goes stale — it is regenerated per run anyway)
