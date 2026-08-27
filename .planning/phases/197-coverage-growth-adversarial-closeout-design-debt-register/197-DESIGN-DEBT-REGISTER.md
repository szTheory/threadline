---
phase: 197-coverage-growth-adversarial-closeout-design-debt-register
artifact: 197-DESIGN-DEBT-REGISTER.md
milestone: v1.40
clause: PROOF-04 (ranked residual design-debt register, each row with owner + concrete reopen-trigger, no vague polish-later bucket)
generated: 2026-08-27
ranking_lens: adoption / operations / maintainer-risk (D-12) — NOT severity×likelihood
source_precedence:
  - runtime/source proof (executed probes, fresh mix test run 2026-08-27, phase SUMMARYs)
  - release/package truth
  - CI/gates
  - planning/residual history (196-06-SUMMARY "Deferred to Phase 197" + 197-RESEARCH seed table)
seed: .planning/phases/196-forward-only-net-positive-gate-first-proven-iteration/196-06-SUMMARY.md ("Deferred to Phase 197") + 197-RESEARCH.md 9-item verified debt table
status: complete
---

# Phase 197 · v1.40 Ranked Design-Debt Register

**PROOF-04** — the residual design-debt register in the v1.39 `193-RISK-REGISTER.md`
shape: ranked rows on the project-native **adoption / operations / maintainer-risk**
lens (D-12), a one-line severity note allowed as secondary color only, and an explicit
**Owner** + concrete **reopen-trigger** on every open row — structurally forbidding a
bare polish-later bucket.

All **9 seed items** from 197-RESEARCH are accounted for (none silently dropped), plus
**three phase-execution rows**: the maintainer-ratified PROOF-02 shortfall (the parked
paid loop itself), the `copy_contract` stale-pin regression discovered by 197-05's
fresh full-suite run, and the Phase-185 doc-contract copy lock that blocked a planned
197-02 removal. Seed #4 (evidence IA) did **NOT** land — plans 197-03/04 did not run —
so it stays an open row.

## Verdict

The loop's guard machinery is closed and adversarially proven (197-ADVERSARIAL-REVIEW:
four tamper probes tripped, six invariants green). The dominant residual is not a code
defect but the **parked PROOF-02 iteration loop itself** (rank 1) — resume fuel is
fully staged and resuming is one maintainer command. The only active full-suite
regression is the rank-2 stale copy-contract pin left behind by the landed 842bd737
edit (a commit-gate coverage gap, not a floor breach — all deterministic loop gates are
green). The historical ~81 search_path local failures did **not** reproduce in this
plan's fresh `mix test` (measured `(undefined_table)` count: **0** — the confirmed
`ALTER DATABASE … SET search_path` fix is in effect), so that row closes in-environment
with a CI reopen-trigger. Every open row has an Owner and a concrete reopen-trigger;
nothing is parked in a vague bucket.

## Ranked Register (adoption / ops / maintainer lens, D-12)

Ranks are strict 1..12: open rows 1–9 ordered by adoption/ops/maintainer leverage
(highest first), closed/consumed rows 10–12 at the bottom in seed order (tie-break
stated per row where leverage is comparable). Fresh evidence basis: full `mix test`
run 2026-08-27 in this worktree — 1381 tests, 4 real failures (3 inherited baseline
modules + the rank-2 copy-contract pin; a 5th failure was a worktree env artifact,
example-app deps unfetched, 17/0 after `deps.get`).

| Rank | ID | Residual | Layer / Area | Owner | Adoption/Ops/Maintainer classification | Severity note (secondary) | Reopen trigger (concrete) |
|-----:|----|----------|--------------|-------|----------------------------------------|---------------------------|---------------------------|
| 1 | **D-197-A** (shortfall) | **Parked PROOF-02 paid iteration loop** — maintainer-ratified shortfall 2026-08-27 (covers unrun plans 197-03/04): 0 NEW accepts this phase; coverage×density gate verdict stands at VOID (REJECT-equivalent, no ledger change). Resume fuel is staged and committed: fresh 5-route before-pole baseline (screenshot-keyed, overwrite-protected), ratified 5-candidate ordered list (197-02-SUMMARY), zero-touch `critic-before-pole.sh`, and the `ui-critic.yml` manual-dispatch scoring lane. | Exploration/ops — the milestone's improvement lane, parked not broken. | maintainer | **Adoption** — highest-leverage open item: the loop is the milestone's reason to exist; everything below rank 5 only matters once it runs again. | Not a defect — an honest, ratified economics call (~80–90% of paid spend was measurement, small visible delta per dollar). | Maintainer resumes the paid loop: one `npm run critic:gate -- --page route.coverage --lens density` (or next candidate) using the standing baseline + candidate list; first clean non-VOID verdict re-opens normal iteration accounting. |
| 2 | **D-197-B** (197-05 discovery) | **`copy_contract_test.exs:249` red** — still asserts the "Selected schema readiness" eyebrow that landed edit 842bd737 removed. The 197-02 commit gates (coverage_live_test 21/0, verify.mechanical, verify.critic_trust) were green but did not include the copy-contract suite — a commit-gate coverage gap. | Operator-surface copy contracts / loop commit-gate set. | maintainer | **Maintainer** — an active default-suite red violates the honest-tests bar; also ops (it will mask real copy regressions while red). | Low severity — the *test's* expectation is stale, not the shipped copy; deterministic one-line flip in the assert-to-refute pattern. | Already open (red now): close by flipping the expectation to the post-842bd737 copy. Escalates if any further coverage copy edit lands while this test is red, or if the loop's commit-gate list is next revised without adding copy-contract coverage for copy-affecting edits. |
| 3 | **Seed #4** | **Evidence page structural density** — six one-row sections paying full section scaffolding; "needs an IA pass, not chrome removal" (196-06). **NOT landed this phase** (PROOF-02 parked before candidate 3); stays open. Fresh 2026-08-27 baseline: evidence density 58. | Operator-surface IA (evidence page). | maintainer (via the resumed loop) | **Adoption** — visible operator-facing density debt on a ratified candidate; tie-break above rank 4: it is user-visible while rank 4 is tooling-internal. | Moderate polish debt; explicitly requires an IA restructure, not the c6f9355e chrome-removal pattern. | The resumed loop reaches candidate 3 (evidence×density 58) on the standing ratified list — the iteration must be scoped as an IA restructure per 196-06, gated as usual. |
| 4 | **Seed #3** | **Tier-A recapture drift** — systematic `scroll_cost` shifts; ~36k-px fullPage stress shots clobbered clipped refute poles in 196 (recovered via `capture:refute`). Tier-A recapture is NOT reproducible in this environment; the committed `page.*` scorecards ARE the floor. | e2e capture tooling (Tier-A stress lab). | e2e tooling (maintainer-owned harness) | **Ops** — bounds what the mechanical floor can honestly claim (committed cells, not live recaptures); recorded as a proof boundary in 197-ADVERSARIAL-REVIEW. | Medium — silent drift would only bite when someone regenerates Tier-A cells, which the anti-pattern list already forbids. | Any future need to regenerate committed Tier-A `page.*` scorecards (e.g. an intentional stress-lab change), or `verify.mechanical` blocking an edit because a committed cell no longer matches the rendered surface. |
| 5 | **D-197-C** (197-02 discovery) | **Phase-185 doc-contract copy lock collides with density edits** — `coverage_doc_contract_test.exs:135` pins the coverage next-step sentence ("Fix rows marked Needs capture, …"); the third planned 197-02 removal was authored then reverted rather than break the locked contract. The lock is working as designed but now sits directly in the path of the rank-1 loop's top candidate (coverage×density). | Doc-contract locks vs. loop edit scope. | maintainer (doc-contract/copy owner) | **Maintainer/ops** — predictable friction: the very next coverage×density iteration will hit the same wall; register-worthy because unowned it silently shrinks every future coverage edit's scope. | Low severity — the guard did its job; the debt is the unresolved policy question (re-scope the lock vs. keep the copy). | The resumed loop targets coverage×density again and the candidate edit touches the locked next-step sentence — at that point the maintainer either amends the doc-contract pin (with its own commit) or permanently excludes that copy from density scope in the plan. |
| 6 | **Seed #7** | **`hierarchy` lens near-chance (ρ 0.42)** — advisory-only; known to confidently fabricate specifics (a nonexistent hex was invented in prior scoring). Persona fan-out already collapsed. | Critic panel validation. | maintainer (critic tooling) | **Ops** — an untrusted lens that *looks* authoritative misleads selection if ever consulted; ranked above #6's color_contrast because 0.42 is near-chance while 0.698 is a near-miss. | Advisory forever until re-validated; never drives verdicts (anti-pattern list). | A rubric redesign for hierarchy is authored AND a fresh synthetic-oracle re-validation clears Spearman ρ ≥ 0.70 — promotion additionally requires a GATE-04 panel-change signoff. |
| 7 | **Seed #6** | **`color_contrast` at ρ 0.698** — 0.002 under the 0.70 line; advisory pending re-validation. | Critic panel validation. | maintainer (critic tooling) | **Ops** — near-threshold: one clean re-validation likely resolves it either way; lower leverage than rank 6 because mechanical WCAG-contrast checks already cover the floor for this dimension. | Minimal — deterministic contrast checks are the actual gate; the LLM lens is additive color only. | A fresh oracle re-validation run clears ρ ≥ 0.70 AND a GATE-04 panel-change signoff records the promotion (both required; either alone is insufficient). |
| 8 | **Seed #8** | **Inherited 3-module doc-contract baseline** — V123Charter (v1.38 milestone literal vs. advanced PROJECT.md; was 193 R-C) / FormlessPages / Phase06Nyquist red in the full suite. Fresh 2026-08-27 run confirms exactly these 3 modules, no new members. Pre-existing, tracked since 195-10. | Doc-contract greenness (maintainer bucket). | doc-contract phase (future) | **Maintainer** — known-red set is stable and fenced; ranked below active friction rows because it has not moved in 4 phases. | Low — each failure correctly reflects docs that advanced past a stale pinned literal, not product defects. | Any NEW module joins the doc-contract failure set (fresh `mix test` shows a 4th red doc-contract module), or a doc-contract cleanup phase is opened — whichever comes first. |
| 9 | **Seed #5** | **GATE-02 true auto-write to source** — deferred by 196-D3 to "Phase 197's first escalation"; 197 ran no escalation (loop parked), so it stays register-as-debt per OQ-1 (RESOLVED: not built). `mechanical_auto_apply.structural_whitelist` remains `[]`, guarded by the probe-4 signoff gate. | Forward-only gate automation (GATE-02). | maintainer | **Maintainer** — deliberately trigger-deferred; zero current cost while the whitelist is empty and the loop is parked, hence lowest open rank. | None today — building it early would be un-spiked automation, exactly what GATE-02 forbids. | **3 consecutive accepted iterations** in which the gate's surfaced mechanical diff was applied verbatim with zero human modification — then spike auto-write behind a `structural_whitelist_add` signoff. |
| 10 | **Seed #1** | **Verdict cache not screenshot-keyed** (stale-verdict hazard; manual `rm` workaround). **CLOSED in 197-01** (commit 4fd68cea): 5-part cache key adds `screenshot_hash` (sha8 of PNG bytes); old 4-part entries miss naturally. Exercised for real by 197-02's cache-busted fresh-before scoring. | e2e critic cache. | — (closed) | Consumed — measurement integrity fix landed before any paid run, per OQ-3 fix-in-phase resolution. | — | A stale-verdict symptom recurs despite the new key (e.g. identical verdict after a visibly changed screenshot) — reopen against cache.ts keying. |
| 11 | **Seed #2** | **`critic:score` silently overwrote the gate's before pole**. **CLOSED in 197-01** (commit 4fd68cea): `guardBeforePole` refuses plain re-scores over an existing pole (VOID-with-instruction message); `--fresh-before` is the deliberate escape; golden/synthetic/refute runs exempt. Exercised for real in 197-02. | e2e critic gate. | — (closed) | Consumed — before/after evidence can no longer be silently faked. | — | Any gate run whose before pole timestamp postdates the edit commit under gate — would mean the guard was bypassed; reopen against gate.ts. |
| 12 | **Seed #9** | **~81 local `mix test` failures (`(undefined_table)` search_path signature)** — re-verified per RESEARCH Assumption A1 with one fresh full `mix test` (2026-08-27): measured `(undefined_table)` failure count = **0**; the signature did not reproduce because the confirmed `ALTER DATABASE <db> SET search_path TO "$user",public,threadline` fix is applied to the local test DB. **Maintainer friction (historical), explicitly NOT a regression** — the 193 R-D stance, now closed-in-environment. | Maintainer environment / storage-schema territory. | maintainer env | Closed-in-environment — friction resolved by the documented non-destructive fix; kept on the register (not dropped) so the CI trigger stays owned. | Never was a severity item — env provisioning, not shipped-code behavior. | The same `(undefined_table)` signature appears in **CI** (provisioned pipeline), or reappears locally on a rebuilt test DB where the ALTER DATABASE fix must be re-applied. |

**No polish-later bucket exists.** Every open row (ranks 1–9) carries an explicit
Owner and a concrete, observable reopen-trigger (a command result, a count threshold,
a CI signature, or a signoff event); closed rows (10–12) each state the closing
evidence and a concrete reopen condition.

## Boundary Check

- This plan's commits touch only files under
  `.planning/phases/197-coverage-growth-adversarial-closeout-design-debt-register/`
  (this register, 197-ADVERSARIAL-REVIEW.md, deferred-items.md, 197-05-SUMMARY.md)
  plus the standard end-of-plan state files. No product code, schema, UI, workflow,
  `mix.exs`, version, or tag changed.
- The tamper probes of 197-05 Task 1 were ephemeral local edits to
  `design-system-ledger.json` / `golden/synthetic-set.json`, each fully reverted
  (`git status --porcelain` empty after the sequence) — nothing probe-related is
  committed.
- `196-06-SUMMARY.md`, `197-RESEARCH.md`, `197-02-SUMMARY.md`, and the 180/193
  precedent artifacts are read-only inputs — none modified.
- Re-running this register-writing task on the same seed reproduces the same 12 rows
  in the same file (single committed artifact, overwrite-in-place, no duplicates).
