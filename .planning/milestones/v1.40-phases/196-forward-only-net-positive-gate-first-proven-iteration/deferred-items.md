# Deferred Items — Phase 196

Out-of-scope, pre-existing failures discovered during execution. NOT caused by the
plan that logged them. Per the executor scope boundary, these are recorded, not fixed.

## Discovered during 196-02 (2026-07-28)

- **Status:** acknowledged
- **Acknowledged at:** v1.40 milestone close, 2026-08-27

Running the full `mix test` suite surfaced 11 pre-existing failures. All were verified
present on the pre-196-02 ledger/tree (`HEAD~2`) and live in files this plan never
touched. They are unrelated to the GATE-02/04/05 guards this plan added.

- **`Threadline.OperatorSurface.StressLedgerTest` — 6 failures**
  (fixture-registry stories present / top-level shape / entries sorted+contracted keys /
  score-increase evidence_ref / DESIGN-SYSTEM projection freshness / rollup integrity /
  ratchet-upward). Root cause: the committed `design-system-ledger.json` is missing the
  `refute.brand_fidelity.graded.*` (and sibling graded-twin) stories that
  `StressFixtures.all()` references — a Phase-195 synthetic-oracle fixture-registry gap.
  Confirmed identical 8-failure count on `HEAD~2`'s ledger (before this plan's additive
  edit), so this plan introduced zero new failures.
- **`Threadline.CriticTrust.LedgerSpliceTest` — "returns an error when the block is absent"**
  (1 of the 8 in the stress+critic_trust file group). Pre-existing; unrelated to the
  additive `mechanical_auto_apply` / `semantic_guard_stamp` blocks.
- **`Threadline.OperatorSurface.FormlessPagesTest`** — `policy_redaction_live.ex` contains
  a form control. Unrelated operator-surface source; untouched by this plan.
- **`Threadline.Phase06NyquistCIContractTest`** — `ci.yml` job-key parity vs CONTRIBUTING.
  CI-contract doc drift; untouched by this plan.
- **`Threadline.V123CharterDocContractTest`** — `PROJECT.md` milestone-posture framing.
  Doc-contract drift; untouched by this plan.

The two deterministic gates this plan owns are green: `mix verify.critic_trust`
(22 tests, 0 failures) and `mix verify.mechanical` (18 tests, 0 failures), plus
`mix verify.format` and `mix verify.credo` clean.
