---
phase: 197-coverage-growth-adversarial-closeout-design-debt-register
artifact: adversarial-review
created: 2026-08-27
status: passed
requirement: PROOF-03
---

# Phase 197 Adversarial Review

Multi-lens closeout of the forward-only critique loop's standing invariants, in the
v1.37 `180-ADVERSARIAL-REVIEW.md` shape. Every row cites **executed evidence** — a
tamper probe that made `mix verify.critic_trust` FAIL while applied and pass after
revert, a pinned source/doc-contract test, or a phase diff-scope command — never bare
assertion. Phase context: the paid PROOF-02 iteration loop was **parked by
maintainer-ratified shortfall on 2026-08-27** (197-02-SUMMARY); plans 197-03/04 did
not run, 0 NEW accepts were booked, and the one landed edit is coverage×density
842bd737 with a standing VOID gate verdict. This review therefore closes the loop's
*guarantees*, not a set of new accepts.

## Tamper-Probe Transcript (executed 2026-08-27, each probe reverted before the next)

All four probes were run as temporary local edits; each was observed to FAIL
`mix verify.critic_trust` (exit 2, guard message below) while applied, then pass
22/0 after `git checkout -- <file>`. `git status --porcelain` was empty after every
revert and at the end of the sequence.

| # | Probe (edit applied) | Failing guard test | Guard message (excerpt) | After revert |
|---|----------------------|--------------------|--------------------------|--------------|
| 1 | `critic_panel.trust_floors.density` 0.78 → 0.70 in `design-system-ledger.json`, no signoff | `no silent trust-floor drop below the committed baseline without a signoff (GATE-04, 196-D5)` — critic_trust_test.exs:371 | "critic_panel.trust_floors[density] dropped from committed baseline 0.78 to 0.7 with no matching target_change/ratchet_bump signoff whose after=0.7. A silent quality-bar drop is blocked (GATE-04, 196-D5)." | 22/0 green |
| 2 | Removed synthetic-oracle item `syn_144` from `.planning/golden/synthetic-set.json` (144 → 143), no `fixture_removal` signoff | `no silent oracle/fixture removal below the recorded inventory without a signoff (GATE-04, 196-D4)` — critic_trust_test.exs:420 | "synthetic-set item count 143 < recorded oracle_inventory.synthetic_item_count 144 with no fixture_removal signoff — the oracle inventory cannot silently shrink (GATE-04, 196-D4)." | 22/0 green |
| 3 | Deleted the pinned `ratchet.signoffs` entry (retention forward_only_accept, commit c6f9355e) from the ledger | `ratchet.signoffs is append-only — every pinned known-good signoff is still present (GATE-04)` — critic_trust_test.exs:458 | "a previously-committed ratchet.signoffs entry disappeared: %{... \"commit\" => \"c6f9355e\", \"kind\" => \"forward_only_accept\", \"target\" => \"route.retention__dark-1280\" ...}. Sign-offs are append-only and must never be rewritten or dropped (GATE-04)." | 22/0 green |
| 4 | `mechanical_auto_apply.structural_whitelist` [] → ["eyebrow-label-removal"], no `structural_whitelist_add` signoff | `structural auto-apply whitelist is empty unless a structural_whitelist_add signoff exists (GATE-02, 196-D3)` — critic_trust_test.exs:476 | "mechanical_auto_apply.structural_whitelist is non-empty ([\"eyebrow-label-removal\"]) but no structural_whitelist_add signoff exists — no un-spiked structural auto-apply ships this phase (GATE-02, 196-D3)." | 22/0 green |

All four probes tripped their guards — none passed silently.

## Invariant Lens Review

| Lens | Review | Result |
|------|--------|--------|
| Loop cannot regress the deterministic floor | Demonstrated adversarially, not asserted: probes 1–4 above each forced `mix verify.critic_trust` to exit non-zero (floor drop, oracle shrink, pin deletion, un-spiked whitelist add) and pass 22/0 after revert. `mix verify.mechanical` 18/0 green at close. The standing VOID verdict on route.coverage/density correctly produced **no** ledger change, no signoff, no pin (197-02-SUMMARY) — a non-ACCEPT cannot move the ratchet. | Pass |
| No root runtime dependency | `git diff 13ed0328..HEAD --name-only` (phase start → HEAD) contains no `mix.exs`; `git diff 13ed0328..HEAD -- mix.exs` is empty. Phase touched only e2e TypeScript (`examples/threadline_phoenix/e2e/critic/*`, `critic-before-pole.sh`), one LiveView presentation file + its tests, `ui-critic.yml`, and `.planning/` artifacts. The Anthropic SDK remains an example-app e2e devDependency (197-RESEARCH zero-new-package finding). | Pass |
| No public component API | Same diff-scope command: the only lib change is `lib/threadline/operator_surface/live/coverage_live.ex` (private operator-surface presentation — eyebrow/meta-line removal, 842bd737) with its LiveView tests flipped assert-to-refute. No module, function, or component was exported to the public API surface; standing source/doc-contract suites (`mix verify.doc_contract`, 130 tests) pin the private operator-surface boundary. | Pass |
| Dev/test-only surfaces | The critique harness lives entirely in `examples/threadline_phoenix/e2e/` (devDependency scope) plus dev/test-only operator-surface routes; `verify.ui_critique` is maintainer-local (key-gated skip on contributor machines, mix.exs:245-251). New this phase: `critic-before-pole.sh` (local script) and `ui-critic.yml` (CI workflow — tooling lane, not a runtime surface). No production host contract changed. | Pass |
| LLM out of CI (196-D9 as amended 2026-08-27: the LLM cannot run on ordinary CI events — push/PR runs are always capture-only) | `forward_only_gate_doc_contract_test.exs` 6/6 green (pins ci.all ordering, the critic's exclusion from CI, and critic non-leakage into guides/). `mix.exs` evidence: the `ci.all` alias includes `verify.critic_trust` (before `verify.mechanical`, mix.exs:132/135) and **excludes** `verify.ui_critique` ("NOT in ci.all", mix.exs:246). `ui-critic.yml` trigger logic: `SCORE_REQUESTED` is set only when `github.event_name == 'workflow_dispatch' && inputs.score` (line 103) and the scoring step runs only under `if: github.event_name == 'workflow_dispatch' && inputs.score && env.ANTHROPIC_API_KEY != ''` (line 116) — push-triggered runs are structurally capture-only, with an explicit capture-only notice otherwise. | Pass — with the amended-invariant framing (manual dispatch + score=true + secret present is the only paid path) |
| Capture / query / auth semantics untouched | `git diff 13ed0328..HEAD --name-only`: no file under the capture layer (triggers, audit transactions/changes), the semantics layer (actions/actor/context), or auth. The full change set is operator-surface presentation (`coverage_live.ex` + tests), e2e critic tooling, one CI workflow, and `.planning/` documents. | Pass |

## Findings

**No blocking Phase-197-owned issue against the six invariants remains.** All four
tamper probes tripped their guards; none required a Finding for an untripped probe.

Honest proof boundaries and non-blocking findings:

1. **`mix verify.doc_contract` exits non-zero on one inherited failure** —
   `V123CharterDocContractTest` (PROJECT.md advanced past the pinned v1.38 milestone
   literal; 193-RISK-REGISTER row R-C, tracked since 195-10). The loop-relevant
   doc-contract evidence (`forward_only_gate_doc_contract_test.exs`) is 6/6 green in
   isolation. Exactly as 180 carried its inherited Phase-179 failures, this baseline
   is inherited, pre-existing, and registered (debt register rank 8), not a Phase-197
   regression.
2. **New discovery: `copy_contract_test.exs:249` is red** — it still expects the
   "Selected schema readiness" eyebrow that the landed 842bd737 coverage edit
   removed. The 197-02 commit gates (coverage_live_test, verify.mechanical,
   verify.critic_trust) were green but did not include the copy-contract suite. Non-
   blocking to the six invariant lenses (the deterministic floor and trust guards are
   green), but it is a commit-gate coverage gap and an active full-suite red —
   registered as debt rank 2 with owner + trigger.
3. **Tier-A recapture drift boundary** — the mechanical floor gates COMMITTED
   `page.*` scorecard cells, not live recaptures; Tier-A recapture is not
   reproducible in this environment (196-06). The floor's guarantee is exactly as
   wide as the committed cells.
4. **PROOF-02 shortfall scope** — this review closes the loop's guard guarantees
   over the phase's actual diff. It does not claim iteration accepts that never
   happened: 0 NEW accepts this phase; the coverage×density gate verdict stands at
   VOID (REJECT-equivalent, no ledger change).

## Follow-Through

- Keep the four GATE-04/GATE-02 tamper probes (probe → observe FAIL → revert) as the
  standing adversarial-evidence pattern for every future loop closeout.
- Keep push-triggered `ui-critic.yml` runs capture-only forever; paid scoring only
  via manual `workflow_dispatch` with `score=true` and the secret present (196-D9 as
  amended).
- Flip the stale `copy_contract_test.exs:249` "Selected schema readiness"
  expectation (debt rank 2) before any further coverage-page copy edit, and add the
  copy-contract suite to the loop's commit-time gate list for copy-affecting edits.
- Keep the 3-module doc-contract baseline (V123Charter / FormlessPages /
  Phase06Nyquist) in the residual bucket until a doc-contract phase owns it; reopen
  if any NEW module joins the failure set.
- Keep `route.*`-only gating (196-D8) and Δ-vs-IQR-noise verdicts; never gate on
  absolute panel scores or `page.*`/`story.*` cells.
