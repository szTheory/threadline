---
phase: 193-quality-closeout-and-next-step-decision
artifact: 193-RISK-REGISTER.md
milestone: v1.39
clause: CLOSE-01 clause 3 (ranked remaining software-quality risks, each with owner + follow-up, no vague polish-later bucket)
generated: 2026-07-02
scope: verify-and-refresh of the 189-QUALITY-AUDIT ranked ledger + four folded-in post-189 residuals
ranking_lens: adoption / operations / maintainer-risk (D-12) — NOT severity×likelihood
source_precedence:
  - runtime/source proof (phase VERIFICATION artifacts)
  - release/package truth
  - CI/gates
  - planning/residual history (189 ledger seed)
seed: .planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md
status: complete
---

# Phase 193 · v1.39 Ranked Residual-Risk Register

**CLOSE-01 clause 3** — a ranked residual-risk register for milestone v1.39,
hand-synthesized in the `v1.38-MILESTONE-AUDIT.md` "Residual Tech Debt" FORMAT
(Area / Residual / Owner-Scope / Impact / Next Action), extended with an explicit
**Owner** and a concrete **reopen-trigger** on every row. This is a
**verify-and-refresh** of the pre-ranked 189 ledger, not a fresh discovery pass
(D-10/D-11): rows 1-3 are verified CLOSED by phases 190/191/192, rows 6-12 are
preserved unchanged, and four new post-189 residuals (R-A..R-D) are folded in.

Ranking is on the project-native **adoption / operations / maintainer-risk** lens
(D-12), matching the REQUIREMENTS.md Future-Requirements framing and QUAL-02's
must-fix-vs-good-enough split — **not** generic severity×likelihood. A one-line
severity note per row is allowed as secondary color. Every row carries an Owner
and a concrete reopen-trigger; this structurally forbids a bare polish-later
bucket.

> **Boundary (D-01/D-02/D-03):** this register does NOT run `/gsd-audit-milestone`
> and does NOT create `v1.39-MILESTONE-AUDIT.md` — it mirrors that skill's FORMAT
> only. The formal audit snapshot is a post-193 step. No product code, schema, UI,
> workflow, version, or tag is touched.

## Verdict

v1.39's three must-fix quality dimensions (189 ledger rows 1-3) are **CLOSED**,
each leaving exactly one carried residual. No open residual is a v1.39 quality
**regression**: the highest-ranked item (R-A) is an inherently-external release-gate
step, the next (R-B/WR-01) is a test-fidelity confidence gap with runtime isolation
already proven, and the ~81 local test failures (R-D) are **maintainer-friction**
with an identical count before and after Phase 192 and green CI — explicitly not a
regression. Every residual has an owner and a reopen-trigger; nothing is parked in a
vague bucket.

## Part A — 189 Ledger Refresh (verify rows 1-3, preserve 6-12)

### Rows 1-3: v1.39 must-fix dimensions — VERIFIED CLOSED

| 189 row | Quality dimension | v1.39 owner phase | Closed? | Carried residual |
|--------:|-------------------|-------------------|---------|------------------|
| 1 | Configurable `storage_schema` confidence beyond default `threadline` | 190 | **CLOSED** — real dual-schema `audit` proof via `storage_schema_integration_test.exs`; prefix-removal wiring; generated-migration quoting contracts (`190-VERIFICATION.md`) | **R-B / WR-01** |
| 2 | Release/version/docs authority surface | 191 | **CLOSED** — single `0.9.0` package truth + `version_truth`/`upgrade_path`/`persona_routing` doc-contract drift guards (`191-VERIFICATION.md`) | **R-C** (charter-test drift) |
| 3 | CI/CD measurement and gate-trust baseline | 192 | **CLOSED in-repo** — 16/16 must-haves: baseline recorded, caches added, PgBouncer pinned, concurrency added, min/current matrix (`192-VERIFICATION.md`) | **R-A** (ship-gated D-17/D-19) + **R-D** (~81 local-env failures) |

### Rows 4-5: this-phase / already-separated

| 189 row | Quality dimension | Status |
|--------:|-------------------|--------|
| 4 | Closeout traceability and residual ownership | **This phase (193)** — realized by `193-TRACEABILITY.md`, `193-EVIDENCE-INDEX.md`, and this register. Not a residual; it is the closeout itself. |
| 5 | Known CI/example-app residuals | **192-owned and already separated** in `192-VERIFICATION.md` (current red required gates distinguished from historical/broad-suite residuals). Manifests here only as R-D's maintainer-friction framing. |

### Rows 6-12: future / external / good-enough / N/A — PRESERVED UNCHANGED

Not re-litigated (D-05/D-07 — no promotion without fresh evidence). Owner + reopen-trigger carried verbatim from the 189 ledger / QUAL-03 residual table.

| 189 row | Quality dimension | 189 priority / route | Owner | Reopen trigger (from 189) |
|--------:|-------------------|----------------------|-------|---------------------------|
| 6 | Screenshot-regression confidence | Prove before claim / Future seed | future (→ **UI-REG-01**) | A future UI-regression lane fixes local bootstrap, chooses supported platforms, and records passing command evidence for the exact runner claimed. |
| 7 | Host staging ownership | External-owned | external | A named host contributes redacted staging evidence, or in-repo docs imply maintainer-operated host STG proof. |
| 8 | External pilot boundaries | External-owned | external (→ **EXT-PILOT-01**) | Named adopter/integrator evidence, or an explicit future external-pilot milestone. |
| 9 | Hex and dependency maintenance notes | Maintenance note | none | `mix hex.info threadline`, `mix hex.audit`, or release preflight shows a current package/install/advisory blocker. |
| 10 | SEED-005 / reconnect operator behavior | Good enough | none (→ **RECONNECT-01**) | Real socket-drop spec fails, mutating controls stay actionable while disconnected, or field reports show the banner is trust-impacting. |
| 11 | Optional Phoenix / private operator-surface boundary | Good enough | none | (Stable — governed by existing source/doc tests; no route from 189.) |
| 12 | Compliance / public component API / WAL-CDC / runtime destructive redaction | N/A | none | A future milestone is explicitly opened from real adopter or procurement pressure. |

## Part B — Ranked Residual Register (adoption / ops / maintainer lens, D-12)

The active carried residuals, folded in and ranked. Every row has an **Owner** and
a concrete **reopen-trigger**. Ranking is by adoption/ops/maintainer leverage
(highest first); the severity note is secondary color only.

**Critical ranking constraint (honesty in both directions):** R-D (~81 local test
failures) is **maintainer-friction ONLY** — it is **NOT** a v1.39 quality
regression (identical count at the pre-192 commit and at HEAD; CI provisions the DB
correctly and is green). It is therefore ranked **below** the ship-gated (R-A) and
storage-schema-fidelity (R-B/WR-01) residuals. Over-claiming R-D as a regression
would be as dishonest as hiding it.

| Rank | ID | Residual | Layer / Area | Owner | Adoption/Ops/Maintainer classification | Severity note (secondary) | Reopen trigger (concrete) |
|-----:|----|----------|--------------|-------|----------------------------------------|---------------------------|---------------------------|
| 1 | **R-A** | **Ship-gated D-17/D-19** — the throwaway min-lane resolution run (elixir 1.15 / otp26 / pg14 / ubuntu-22.04) + GitHub branch-protection reconfig from `Run test suite (verify-test)` to `Run test suite (min)` / `(current)`. Tracked, **not executed** (D-04). | Exploration/ops — release-gate correctness (inherently external; needs the `ci.yml` matrix to reach public `origin/main`, a push the local-only convention forbids). | maintainer (szTheory) | **Ops** — highest-leverage open item: until the matrix lands publicly, branch protection still references the old check name. | Low severity, high leverage. Non-blocking today because no release is being cut; deterministic to close once a legitimate public push happens. | The deliberate clean ship-gated push/release that lands the `ci.yml` verify-test matrix on public `origin/main` (`192-SHIP-CHECKLIST.md`); then reconfigure branch protection to the two new check names. |
| 2 | **R-B / WR-01** | **Alternate-schema test fixture fidelity** — the custom-schema proof fixture builds tables with `CREATE TABLE … LIKE "threadline"."table" INCLUDING ALL` rather than applying the generated migrations, so **schema-local FK constraints are unproven** in the alt-schema matrix (`190-VERIFICATION.md:93`, non-blocking WARNING). | **Capture / storage-schema** fixture-fidelity residual (per CLAUDE.md three-layer framing) — NOT a semantics or exploration defect. Runtime isolation is already proven; generated-migration SQL is separately contracted. | future schema-fixture hardening | **Maintainer-confidence** (test fidelity) — the end-to-end custom-schema claim is proven at runtime; only the FK-constraint dimension of the *fixture* is narrower than the tempting claim. | Low severity — `INCLUDING ALL` copies most structure; the gap is specifically FK enforcement inside the alt schema. | A custom-schema FK regression appears, OR a future phase chooses to apply the real generated migrations in the alt-schema fixture (upgrading fidelity). |
| 3 | **R-C** | **`v1_23_charter_doc_contract_test.exs` milestone-literal drift** — the test asserts PROJECT.md still contains the **v1.38** milestone literals, but PROJECT.md correctly advanced to **v1.39** when the milestone opened, so the test fails. Pre-existing, outside Phase 191's declared file scope (`191/deferred-items.md`, `191-VERIFICATION.md`). | Maintainer / doc-contract greenness — a milestone-literal drift, **not** a version-truth defect (ADOPT-01's `0.9.0` reconciliation is separately proven and green). | charter / SSOT-truth owner | **Maintainer** (doc-contract greenness) — one known-red doc-contract test against an otherwise-green `mix verify.doc_contract` suite. | Low severity — the failure correctly reflects that PROJECT.md moved forward; the *test's* expected literal is stale, not the charter. | Refresh the expected milestone literal to the active milestone or bind it to an SSOT; reopen if `mix verify.doc_contract` must be fully green before archive (natural thin-polish candidate). |
| 4 | **R-D** | **~81 local `mix test` failures** — `(undefined_table) relation "audit_changes" / … does not exist` under a local storage_schema/search_path env gap (`192-VERIFICATION.md` out-of-scope observation; MEMORY `local-test-db-storage-schema-failures`). | Maintainer environment / Phase-190 storage-schema territory — a local test-DB provisioning gap, not shipped-code behavior. | maintainer env (Phase-190 territory) | **Maintainer-friction ONLY — explicitly NOT a v1.39 quality regression.** Evidence inline: the failure count is **identical at the pre-192 commit and at HEAD**, and **CI provisions the DB correctly (CI is green)**. Ranked below R-A and R-B by design. | Not a severity item — it is friction, not a defect. Presenting it as a regression would over-claim risk. | A **CI** (not local) test failure with the same `(undefined_table)` signature — i.e. the env issue reaches the provisioned pipeline. Local-only reproduction does not reopen it. |

**No polish-later bucket exists.** Every residual above and every preserved
189 row carries an explicit owner and a concrete reopen-trigger.

## Boundary Check

- Output is `.planning/phases/193-*` only; no product code, schema, UI, workflow, `mix.exs`, version, or git tag changed (D-02).
- `189-QUALITY-AUDIT.md`, phase VERIFICATION artifacts, `REQUIREMENTS.md`, `ROADMAP.md`, `PROJECT.md`, and `config.json` are **read-only inputs** — none modified.
- `/gsd-audit-milestone` is **not** run and `v1.39-MILESTONE-AUDIT.md` is **not** created by this phase (D-03).
- Rows 6-12 of the 189 ledger are preserved unchanged; nothing is promoted without fresh evidence (D-05/D-07).

## Artifacts This Phase Produces

- `193-TRACEABILITY.md` — CLOSE-01 clause 1.
- `193-EVIDENCE-INDEX.md` — CLOSE-01 clause 2.
- `193-RISK-REGISTER.md` (this file) — CLOSE-01 clause 3.
- `193-NEXT-STEP.md` — CLOSE-01 clause 4.
- `193-VERIFICATION.md` — closeout verification of all four clauses.
- Per-plan `193-01-SUMMARY.md` / `193-02-SUMMARY.md` / `193-03-SUMMARY.md`.
