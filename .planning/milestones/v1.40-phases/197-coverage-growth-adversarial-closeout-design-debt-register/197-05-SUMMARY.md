---
phase: 197-coverage-growth-adversarial-closeout-design-debt-register
plan: 05
subsystem: planning-closeout
tags: [proof-03, proof-04, adversarial-review, design-debt-register, tamper-probes]
requires:
  - 197-01 (closed debt seeds #1/#2 — cited as closed rows)
  - 197-02 (shortfall ratification + fresh baseline — replaces waived 197-04 dependency)
provides:
  - 197-ADVERSARIAL-REVIEW.md (PROOF-03, status passed, 6 invariant lenses, 4 executed tamper probes)
  - 197-DESIGN-DEBT-REGISTER.md (PROOF-04, status complete, 12 ranked rows, all 9 seeds accounted)
affects:
  - phase-197 verifier (PROOF-02 gap is explicit; PROOF-03/04 closed)
  - any future resume of the paid loop (register rank 1 owns it)
tech-stack:
  added: []
  patterns:
    - probe → observe FAIL → revert tamper-evidence pattern (GATE-04/GATE-02)
    - 180-shape adversarial review + 193-shape ranked register reused verbatim
key-files:
  created:
    - .planning/phases/197-coverage-growth-adversarial-closeout-design-debt-register/197-ADVERSARIAL-REVIEW.md
    - .planning/phases/197-coverage-growth-adversarial-closeout-design-debt-register/197-DESIGN-DEBT-REGISTER.md
    - .planning/phases/197-coverage-growth-adversarial-closeout-design-debt-register/deferred-items.md
  modified: []
decisions:
  - "Phase-185 coverage doc-contract copy lock judged register-worthy → registered as rank 5 (D-197-C) with owner + concrete trigger (next coverage×density iteration touching the locked sentence forces the amend-vs-exclude call)"
  - "Debt seed #9 re-measured fresh: (undefined_table) count = 0 (ALTER DATABASE search_path fix in effect) → closed-in-environment with a CI reopen-trigger, not an open ~81-failure row"
  - "copy_contract_test.exs:249 red (stale 'Selected schema readiness' pin vs landed 842bd737) discovered by the fresh full run — NOT auto-fixed (caused by 197-02, out of this plan's scope boundary); logged to deferred-items + registered rank 2"
  - "verify.doc_contract non-zero exit accepted as a bounded caveat (inherited V123Charter drift, 193 R-C); loop-relevant forward_only_gate_doc_contract_test is 6/6 green in isolation — mirrors 180's inherited-failure stance"
  - "GATE-02 auto-write trigger N pinned at 3 consecutive verbatim-applied accepts (register rank 9, per OQ-1)"
metrics:
  duration: ~50 min (fresh full mix test dominated)
  completed: 2026-08-27
status: complete
actuals:
  tokens: 14000
  tasks: 3
  commits: 2
---

# Phase 197 Plan 05: Adversarial Closeout + Design-Debt Register Summary

Four GATE-04/GATE-02 tamper probes executed and reverted (each observed to FAIL
`mix verify.critic_trust` while applied), backing a passed 6-lens adversarial review
(PROOF-03) and a 12-row ranked design-debt register (PROOF-04) that honestly reflects
the ratified PROOF-02 shortfall — 0 NEW accepts, loop parked with resume fuel staged.

## Task Commits

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Four tamper probes (probe → FAIL → revert) + CI-posture evidence | (no committed files — ephemeral, tree clean after sequence) | — |
| 2 | 197-ADVERSARIAL-REVIEW.md (PROOF-03) | 09dcaf95 | 197-ADVERSARIAL-REVIEW.md, deferred-items.md |
| 3 | 197-DESIGN-DEBT-REGISTER.md (PROOF-04) | 1e4b8c0c | 197-DESIGN-DEBT-REGISTER.md |

## Probe Transcript (excerpt)

Each probe: temporary local edit → `mix verify.critic_trust` exit 2 with the guard's
message → `git checkout -- <file>` → 22/0 green → `git status --porcelain` empty.

1. **Floor drop** — `critic_panel.trust_floors.density` 0.78→0.70, no signoff →
   FAIL: "critic_panel.trust_floors[density] dropped from committed baseline 0.78 to
   0.7 with no matching target_change/ratchet_bump signoff … (GATE-04, 196-D5)."
2. **Oracle fixture removal** — removed `syn_144` from `golden/synthetic-set.json`
   (144→143) → FAIL: "synthetic-set item count 143 < recorded
   oracle_inventory.synthetic_item_count 144 with no fixture_removal signoff …
   (GATE-04, 196-D4)."
3. **Pinned-signoff deletion** — deleted the c6f9355e retention forward_only_accept
   from `ratchet.signoffs` → FAIL: "a previously-committed ratchet.signoffs entry
   disappeared … Sign-offs are append-only … (GATE-04)."
4. **Whitelist add** — `structural_whitelist` []→["eyebrow-label-removal"], no
   signoff → FAIL: "structural_whitelist is non-empty … but no
   structural_whitelist_add signoff exists … (GATE-02, 196-D3)."

All four guards tripped — no untripped probe, so no blocking Finding. CI posture:
`forward_only_gate_doc_contract_test` 6/6; `ci.all` includes verify.critic_trust +
verify.mechanical, excludes verify.ui_critique; `ui-critic.yml` scoring runs only on
`workflow_dispatch && inputs.score && secret present` (push = capture-only).

## Deviations from Plan

**1. [Frontmatter dependency waived] 197-04 never ran** — the maintainer ratified a
PROOF-02 shortfall on 2026-08-27 (197-02-SUMMARY) parking plans 03/04. Both artifacts
were written against the shortfall reality: seed #4 (evidence IA) stays OPEN (register
rank 3), and the parked loop itself is register rank 1 (Owner maintainer;
reopen-trigger = maintainer resumes with the staged fuel). The review's lens rows cite
the actual phase diff (13ed0328..HEAD), and its Findings state the 0-accept scope.

**2. [Acceptance criterion narrowed honestly] `mix verify.doc_contract` exits
non-zero** — one inherited failure (V123CharterDocContractTest, milestone-literal
drift, 193 R-C / debt rank 8). The plan expected exit 0; instead of hiding it, the
loop-relevant subset (`forward_only_gate_doc_contract_test.exs`, 6/6) was run in
isolation and the lane-level red recorded as a bounded caveat in the review — the
exact stance 180 took with its inherited Phase-179 failures.

**3. [Out-of-scope discovery, not fixed] `copy_contract_test.exs:249` red** — expects
the eyebrow 842bd737 removed. Caused by 197-02, not this plan; per the scope boundary
it was logged to `deferred-items.md` and registered (rank 2) rather than auto-fixed.

**4. [Assumption A1 overturned] seed #9 measured at 0, not ~81** — fresh full
`mix test` (1381 tests): `(undefined_table)` count = 0; the confirmed
`ALTER DATABASE … SET search_path` fix is in effect locally. Row 12 closes
in-environment with a CI reopen-trigger. (A 5th full-suite failure was a worktree env
artifact — example-app deps unfetched; 17/0 after `mix deps.get`, excluded from the
real count.)

**5. [197-02 discovery registered] Phase-185 doc-contract lock** — judged
register-worthy (it will re-bite the loop's #1 candidate): register rank 5 with owner
+ concrete trigger, so no "why not" note is needed.

## Verification

- Probe sequence: 4/4 tripped, 4/4 reverted; `git status --porcelain` empty after.
- `mix compile --warnings-as-errors` clean; `mix verify.critic_trust` 22/0 and
  `mix verify.mechanical` 18/0 re-run green before each commit.
- 197-ADVERSARIAL-REVIEW.md: 6 lens rows, all Pass / Pass-with-bounded-caveat →
  `status: passed`; Findings explicit; Follow-Through 5 imperative bullets.
- 197-DESIGN-DEBT-REGISTER.md: ranks strict 1..12; all 9 seed IDs appear exactly
  once; every open row has Owner + observable reopen-trigger; GATE-02 auto-write
  registered per OQ-1 (N=3).
- Both commits touch only `.planning/phases/197-*` files.

## Known Stubs

None — both artifacts are complete planning documents; no code was written.

## Self-Check: PASSED

All four created files exist on disk; commits 09dcaf95 and 1e4b8c0c present in git
log; review has 6 Pass result cells; register table carries the Reopen-trigger
column with per-row concrete triggers.
