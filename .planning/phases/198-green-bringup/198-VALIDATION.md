---
phase: 198
slug: green-bringup
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-27
---

# Phase 198 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `198-RESEARCH.md` § Validation Architecture. Task IDs are filled in by the planner.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `test/test_helper.exs` — `ExUnit.start()`, storage bootstrap, `Ecto.Migrator.run/3` at `:13`, `pgbouncer_topology` tag exclusion at `:39` |
| **Quick run command** | `mix test test/threadline/<specific_test>.exs` |
| **Full suite command** | `mix verify.test` (full gate chain: `mix ci.all`) |
| **Estimated runtime** | `mix test` seconds-to-low-minutes; `mix ci.all` is itself under measurement (Success Criterion #3 target ≤ 20 min, goal ≤ 12) |

---

## Sampling Rate

- **After every task commit:** targeted `mix test test/threadline/<touched_test>.exs` for test/triage tasks; `git diff --exit-code .credo.exs` for every measurement-plan task; `bin/verify-branch-protection` once it exists for protection tasks
- **After every plan wave:** `mix ci.all`
- **Before `/gsd-verify-work`:** full suite must be green on a **fresh** database (`mix test.reset`, per D-04) — a green run against the maintainer's existing DB does not count (D-01)
- **Max feedback latency:** 20 s for targeted runs; `mix ci.all` bounded by the phase's own ≤ 20 min target

---

## Per-Task Verification Map

Task IDs are assigned by the planner; this table carries the requirement→command binding each task must inherit.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | 01 | 1 | GREEN-01 | — | N/A | artifact check | `test -f .planning/audits/198-ci-run-28214113903-logs.md` | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | GREEN-02 | — | N/A | script + diff | `git diff --exit-code .credo.exs && test -f .planning/audits/198-credo-histogram.json` | ❌ W0 | ⬜ pending |
| TBD | 01 | 1 | GREEN-03 | — | N/A | probe + finding | scorecard-free probe; output committed to `.planning/audits/198-mechanical-sensitivity.md` | ❌ W0 | ⬜ pending |
| TBD | — | — | GREEN-04 | — | N/A | full suite + guard | `mix test` exit 0 **and** the D-05 zero-exclusions assertion test | ❌ W0 | ⬜ pending |
| TBD | — | — | GREEN-05 | — | N/A | unit | D-07 `@ui_form_policy` exhaustive-scan test (replaces `formless_pages_test.exs:47-54`) | ❌ W0 | ⬜ pending |
| TBD | — | — | GREEN-06 | — | N/A | static YAML contract | `timeout-minutes:` count vs. job count across all 5 workflows; `--max-failures` present | ❌ W0 | ⬜ pending |
| TBD | — | — | GREEN-07 | — | N/A | git + `gh run view` | `git log origin/main..main` empty; `gh run view <id> --json conclusion,startedAt,updatedAt` ≤ 20 min | ❌ W0 (post-push) | ⬜ pending |
| TBD | — | — | GREEN-08 | — | N/A | committed script | `bin/verify-branch-protection` (D-12: contexts diff **and** proof-of-emission) | ❌ W0 | ⬜ pending |
| TBD | — | — | GREEN-09 | T-198-01 | Paid path structurally unreachable from CI | contract test | D-25 assertions in `test/threadline/ci_topology_contract_test.exs`: zero `ANTHROPIC_API_KEY` refs in `.github/workflows/` | ⚠️ additive | ⬜ pending |
| TBD | — | — | GREEN-10 | T-198-02 | Exactly one gated publish path | contract test | same file: `mix hex.publish` occurrence count across `.github/workflows/*.yml` == 1 | ⚠️ additive | ⬜ pending |
| TBD | — | — | GREEN-11 | — | N/A | live workflow | `workflow_dispatch` dry-run — see Manual-Only below | N/A | ⬜ pending |
| TBD | — | — | GREEN-12 | — | N/A | git + register check | `git worktree list \| wc -l` == 1; no non-`main`/`archive/*` branches; `test -f .planning/ARCHIVE-REGISTER.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] D-07's replacement for `test/**/formless_pages_test.exs` — self-declaring `@ui_form_policy` attribute + exhaustive `lib/threadline/operator_surface/live/*.ex` scan, with the non-empty-glob assertion (`version_truth_doc_contract_test.exs:59` idiom)
- [ ] D-05 zero-exclusions assertion test — greps `test/**/*_test.exs` for `@tag :skip` / `@moduletag :skip` and asserts `ExUnit.configuration()[:exclude] == [pgbouncer_topology: true]`
- [ ] `bin/verify-branch-protection` — new committed script (D-12), sibling to `bin/verify-release-shape`
- [ ] Additive D-25 assertions inside existing `test/threadline/ci_topology_contract_test.exs`
- [ ] D-23(c) CI-Coverage doc-contract test — asserts the `CONTRIBUTING.md` table's project list equals the actual `--project` flags in the workflow. Per CONTEXT.md, make it a plain `*_contract_test.exs` picked up by `mix test`, **not** a new `verify.*` step, so it survives Phase 204's deletion of `verify.doc_contract`
- [ ] D-03 stale-schema tripwire in `test/test_helper.exs` (after `:13`) — scoped to `Threadline.Test.Repo`'s own database, never in `lib/`
- [ ] Tracked evidence artifacts (not test files, but the mechanical evidence GREEN-01/02/03/12 point at): `198-TRIAGE.md`, `.planning/ARCHIVE-REGISTER.md`, `.planning/audits/*`

**Constraint carried from CONTEXT.md `<code_context>`:** Phase 199 / DECOUPLE-01 requires `mix ci.all` to pass with `.planning/` renamed away — **no gate may read any artifact under `.planning/`.** Evidence artifacts are outputs, never test inputs.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Flake Detection classifies "broken" vs. "flaky" by name and dedupes its tracking issue | GREEN-11 | The classification heuristic only exercises on a live scheduled Actions run; no pre-merge assertion can reach it | Trigger via `workflow_dispatch` on the staging branch; confirm a run-1 failure is reported as *broken*, and that a second failure updates the existing issue rather than opening a new one |
| GitHub's emitted check name for a matrix job carrying a static `name:` (`ci.yml:100-106`) | GREEN-08 | Genuinely unresolved by any authoritative source (research confidence: LOW); only observable once the matrix reports on origin | Push the matrix, then read `gh api repos/:owner/:repo/commits/main/check-runs` and record verbatim in `.planning/audits/198-matrix-name-observation.md`. This observation **is** GREEN-08's "verified after the matrix has reported once" (D-11) |
| Credential-audit finding classification (D-29 Class A/B/C) | GREEN-07 gate | Class assignment is a judgment call with an abort branch; the scanners are automated but the disposition is not | Every finding gets a register row; Class A rotated **before** `git push`; any Class B **aborts** the push and escalates. Clicking "allow secret" on push protection is forbidden |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 20 s (targeted) / < 20 min (`mix ci.all`)
- [ ] No gate reads any path under `.planning/` (Phase 199 DECOUPLE-01 forward-constraint)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
