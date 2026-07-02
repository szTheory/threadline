---
phase: 193-quality-closeout-and-next-step-decision
artifact: 193-EVIDENCE-INDEX.md
milestone: v1.39
clause: CLOSE-01 clause 2 (verification evidence + before/after CI data or explicit no-measure rationale)
generated: 2026-07-02
scope: verification-evidence-index + static-ci-diff + honest-no-measure-runtime-rows
source_precedence: phase 189-192 VERIFICATION/BASELINE artifacts + current .github/workflows/ci.yml (read-only diff)
status: complete
---

# Phase 193 · v1.39 Verification + CI Evidence Index

**CLOSE-01 clause 2** — a read-only index of the verification evidence behind
v1.39, plus the CI before/after story told **honestly**: structural deltas where
they are in-repo diffable (D-08), and explicit no-measure rows where the after
config is ship-gated and has never run publicly (D-09). No phase verification is
re-run; no workflow file is modified; no runtime number is fabricated.

## Verdict

v1.39 verification evidence is **present and traceable**. Phases 189-192 each
carry a `*-VERIFICATION.md` proving their requirement block complete, and the CI
change set is structurally diffable in-repo against `192-BASELINE.md`. The only
honestly-absent data is post-ship runtime telemetry (wall-clock, cache-hit rate,
billed minutes), recorded below as explicit no-measure rows — this IS the
"before/after where possible; explicit no-measure reason where not" that CLOSE-01
anticipates, not a shortfall.

## (a) Verification-Evidence Index (phases 189-192, read-only)

Each row points to the phase artifact that proves its requirement block. These are
indexed, not re-executed (D-01).

| Phase | Requirements proven | Primary verification artifact | What it proves |
|-------|---------------------|-------------------------------|----------------|
| 189 | QUAL-01, QUAL-02, QUAL-03 | `189-VERIFICATION.md` + `189-QUALITY-AUDIT.md` | Repo-evidence quality audit: ranked ledger, must-fix vs good-enough split, QUAL-03 residual triage with Owner + reopen-trigger per row. |
| 190 | SCHEMA-01, SCHEMA-02, SCHEMA-03, SCHEMA-04 | `190-VERIFICATION.md` | Custom `audit` storage-schema proven end-to-end via `storage_schema_integration_test.exs`; prefix-removal wiring; generated-migration quoting contracts; host-schema coverage. Introduces residual **WR-01** (fixture uses `CREATE TABLE … LIKE … INCLUDING ALL`; schema-local FK constraints unproven — non-blocking WARNING). |
| 191 | ADOPT-01, ADOPT-02, ADOPT-03 | `191-VERIFICATION.md` + `deferred-items.md` | Single `0.9.0` package truth + drift guards (`version_truth` / `upgrade_path` / `persona_routing` doc-contract tests). Introduces residual **charter-test drift** (`v1_23_charter_doc_contract_test.exs` asserts stale PROJECT.md milestone literal). |
| 192 | CI-01, CI-02, CI-03, CI-04 | `192-VERIFICATION.md` + `192-BASELINE.md` + `192-SHIP-CHECKLIST.md` | 16/16 CI must-haves closed in-repo: baseline recorded, caches added, PgBouncer pinned, concurrency added, min/current matrix. Introduces residuals **ship-gated D-17/D-19** (external, requires matrix to reach public `origin/main`) and **~81 local-env test failures** (maintainer-friction observation, NOT a v1.39 regression). |

Verification tooling is the project's named entrypoints: `mix verify.test`,
`mix verify.doc_contract`, and the `mix ci.all` aggregate (cited verbatim per
CLAUDE.md). Residuals surfaced here are carried and ranked in `193-RISK-REGISTER.md`.

## (b) CI Before/After — Static Structural Diff (in-repo, D-08)

Before column sourced from `192-BASELINE.md`; After column read from the current
`.github/workflows/*.yml` at generation time and corroborated by the numbered
truths in `192-VERIFICATION.md`. This is a pure in-repo diff — no live API,
no runtime measurement.

| Metric | Before (`192-BASELINE.md`) | After (current workflows) | Evidence for "after" |
|--------|----------------------------|---------------------------|----------------------|
| `actions/cache` blocks in `ci.yml` | 0 | 9 (8 `path: deps` + 1 Playwright browser cache) | `192-VERIFICATION.md` truths 3-4; `grep -c 'uses: actions/cache' ci.yml` = 9 |
| flake-detection.yml deps cache | 0 | 1 (before its `mix deps.get`) | truth 3; `grep -c 'uses: actions/cache' flake-detection.yml` = 1 |
| `_build` cache (must stay 0) | 0 | 0 (contract-test refuted restoring `_build`) | truth 5 / prohibition; `grep -c 'path: _build' ci.yml` = 0 |
| `mix deps.get` invocations | 8 cold | 8 (retained; now cache-warmed — speed only, not fewer calls) | truth 6; `grep -c 'mix deps.get' ci.yml` = 8 |
| `concurrency:` blocks in `ci.yml` | 0 | 1 (PR-scoped; cancels only superseded PR runs) | truth 8; `ci.yml:22` |
| release.yml publish concurrency | 0 | 1 (`group: release-publish-${{ github.ref }}`, job-level on publish-hex, no `run_id`) | truth 9; `release.yml:283-284` |
| PgBouncer image tag | `edoburu/pgbouncer:latest` | `edoburu/pgbouncer:v1.25.2-p0` (0 `:latest` PgBouncer tags across all 4 workflows) | truth 7; `ci.yml:301` |
| `verify-test` version lanes | single pinned `elixir 1.17.3 / OTP 27` | min/current matrix → GitHub posts `Run test suite (min)` + `Run test suite (current)` | truths 11-12; `ci.yml` matrix `lane: [min, current]` |
| min-lane axis | — | `elixir 1.15 / otp 26 / pg14 / ubuntu-22.04` (proves the declared floor) | truth 12; `ci.yml` matrix `include` (min) |
| current-lane axis | `1.17.3 / otp27 / pg16` | `elixir 1.17.3 / otp 27 / pg16 / ubuntu-24.04` (full payload) | `ci.yml` matrix `include` (current) |
| Elixir floor (`~> 1.15`, must be unchanged) | `~> 1.15` | `~> 1.15` (comment-only note; floor honored by the min CI lane, not by raising the requirement) | truth 13; `mix.exs` unchanged |

**Framing:** the before/after is *structurally* complete and in-repo diffable. The
change set adds caching, concurrency cancellation, an image pin, and a min/current
support-lane matrix without restoring `_build`, hiding warnings, or reducing the
number of proven gates.

## (c) Honest No-Measure Runtime Rows (D-09 — four-field Nyquist-debt shape)

These runtime metrics **cannot** be measured because the after-config (Wave-2
caches + min/current matrix) is ship-gated (D-04) and has **never run on public
`origin/main`**. Recorded per the DNA Nyquist-debt shape used verbatim in
`192-BASELINE.md` — **owner / date / superseding-evidence pointer / reopen
trigger** — never a bare "unavailable" and never a fabricated number.

| Metric | Status | Owner | Date | Superseding-evidence pointer | Reopen trigger |
|--------|--------|-------|------|------------------------------|----------------|
| Wall-clock critical path (after) | Unavailable — after-config never ran publicly | maintainer (szTheory) | 2026-07-02 | GitHub Actions run telemetry (`gh api runs/{id}/jobs` p50/p95) once the `ci.yml` cache + matrix land on `origin/main`; compare against `192-BASELINE.md` p50 244 s / p95 326 s | The deliberate clean ship-gated push that lands the `ci.yml` matrix on public `origin/main` (D-04 / `192-SHIP-CHECKLIST.md`) |
| Cache-hit rate | N/A — no telemetry yet | maintainer (szTheory) | 2026-07-02 | `actions/cache` restore/save step logs after the Wave-2 caches run on GitHub (the honest-unavailable row in `192-BASELINE.md` flips to a measured value here) | Same ship-gated push — the first public run that exercises the `deps` / Playwright cache blocks |
| Billed minutes (CI runner cost) | Unavailable — public repo returns empty `{"billable":{}}` | maintainer (szTheory) | 2026-07-02 | GitHub Actions billing API `actions/workflows/ci.yml/timing` is empty for this public repo; an org-level Actions billing export would be the superseding source | Repo becomes private, or an org-level Actions billing export becomes available |

No fabricated after-timing, cache-hit-rate, or billed-minutes number appears
anywhere in this index. Runtime deferral is the intended CLOSE-01 "no-measure
reason where not possible," not a quality gap.

## /gsd-audit-uat Skip Note (D-10 / OQ-3)

`/gsd-audit-uat` is **skipped** for v1.39. The milestone introduced **no
`*-UAT.md` files**, so a UAT audit would only re-surface the already-deferred
v1.36 UAT rows — near-zero expected value. The skip is recorded here explicitly so
the decision is visible in the closeout evidence. The formal `/gsd-audit-milestone`
run (which produces `v1.39-MILESTONE-AUDIT.md`) is a **post-193** step per D-03 and
is not performed by this phase.

## Boundary Check

- Output is `.planning/phases/193-*` files only; no workflow, product, schema,
  version, or tag change (D-02).
- `.github/workflows/*.yml`, `REQUIREMENTS.md`, `ROADMAP.md`, `PROJECT.md`, and
  `mix.exs` are read-only inputs — none is modified.
- `v1.39-MILESTONE-AUDIT.md` is **not** created by Phase 193 (D-03).

## Artifacts This Phase Produces

- `193-TRACEABILITY.md` — CLOSE-01 clause 1.
- `193-EVIDENCE-INDEX.md` (this file) — CLOSE-01 clause 2.
- `193-RISK-REGISTER.md` — CLOSE-01 clause 3.
- `193-NEXT-STEP.md` — CLOSE-01 clause 4.
- `193-VERIFICATION.md` — closeout verification of all four clauses.
- Per-plan `193-01-SUMMARY.md` / `193-02-SUMMARY.md` / `193-03-SUMMARY.md`.
