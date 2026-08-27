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
| 01-T1 | 01 | 1 | GREEN-01 | T-198-01-01 | Preserved logs pass the pre-push credential sweep | artifact check | `test -f .planning/audits/198-ci-run-28214113903-logs.md` | ❌ W0 | ⬜ pending |
| 01-T2 | 01 | 1 | GREEN-02 | T-198-01-02 | Measurement never mutates the gate config | script + diff | `git diff --exit-code .credo.exs && test -f .planning/audits/198-credo-histogram.md` | ❌ W0 | ⬜ pending |
| 01-T3 | 01 | 1 | GREEN-03 | T-198-01-03 | Probe cannot manufacture the Phase 201 floor | probe + finding | `test -z "$(git status --porcelain .planning/scorecards/)" && grep -q '^## Finding' .planning/audits/198-mechanical-sensitivity.md` | ❌ W0 | ⬜ pending |
| 02-T1 | 02 | 1 | GREEN-07 (push gate) | T-198-02-01, T-198-02-02 | Full-history scan, redacted reports | scanner sweep | `test -f .planning/audits/198-gitleaks-history.json && test -f .planning/audits/198-trufflehog-verified.json` | ❌ W0 | ⬜ pending |
| 02-T2 | 02 | 1 | GREEN-07 (push gate) | T-198-02-05 | Every finding classed in writing | register check | `grep -qE '^## VERDICT: (PROCEED\|ABORT)' .planning/audits/198-credential-audit.md` | ❌ W0 | ⬜ pending |
| 02-T3 | 02 | 1 | GREEN-07 (push gate) | T-198-02-03 | Push protection live before first push | CLI + artifact | `grep -q '"secret_scanning_push_protection"' .planning/audits/198-credential-audit.md` | ❌ W0 | ⬜ pending |
| 03-T1 | 03 | 2 | GREEN-08 | T-198-03-01, T-198-03-05 | Skipped-on-dependency-failure cannot score as pass | YAML contract + live API | `grep -q 'name: CI required' .github/workflows/ci.yml` and check-runs API returns ≥1 `CI required` | ⚠️ additive | ⬜ pending |
| 03-T2 | 03 | 2 | GREEN-08 | T-198-03-05 | Required-check identity matches emitted name | observation artifact | `grep -q '^## Verdict' .planning/audits/198-matrix-name-observation.md` | ❌ W0 | ⬜ pending |
| 03-T3 | 03 | 2 | GREEN-07 | — | Floor lane not downgraded | live run + grep | `grep -c 'continue-on-error' .github/workflows/ci.yml` == 0 | ⚠️ additive | ⬜ pending |
| 04-T1 | 04 | 3 | GREEN-04 | T-198-04-03, T-198-04-05 | Stale DB fails once, loudly | full suite (fresh DB) | `mix test.reset` | ❌ W0 | ⬜ pending |
| 04-T2 | 04 | 3 | GREEN-04 | T-198-04-01, T-198-04-02 | Zero laundering; guard not self-invalidating | unit | `mix test test/threadline/zero_skips_contract_test.exs` | ❌ W0 | ⬜ pending |
| 04-T3 | 04 | 3 | GREEN-05 | T-198-04-04 | New page cannot be silently unguarded | unit | `mix test test/threadline/operator_surface/ui_form_policy_contract_test.exs` | ❌ W0 | ⬜ pending |
| 05-T1 | 05 | 3 | GREEN-06 | T-198-05-05 | Broken suite aborts, traces retained | config + list | `grep -c 'name: "chromium"' examples/threadline_phoenix/e2e/playwright.config.ts` == 0 | ⚠️ additive | ⬜ pending |
| 05-T2 | 05 | 3 | GREEN-06 | T-198-05-03 | Moved coverage is stated and asserted | doc contract | `mix test test/threadline/ci_coverage_doc_contract_test.exs` | ❌ W0 | ⬜ pending |
| 05-T3 | 05 | 3 | GREEN-06 | T-198-05-02 | No job can hang unbounded | static YAML contract | job count == `timeout-minutes` count in ci.yml, release.yml, browser-full.yml | ⚠️ additive | ⬜ pending |
| 05-T4 | 05 | 3 | GREEN-07 | T-198-05-01 | Lanes cannot share a cache entry | static YAML contract | `grep -c 'runner.os' .github/workflows/ci.yml` == 0 | ⚠️ additive | ⬜ pending |
| 06-T1 | 06 | 4 | GREEN-12 | T-198-06-04 | Nothing deleted before its tag resolves | git + register check | `git worktree list \| wc -l` == 1; every `archive/*` tag resolves; `test -f .planning/ARCHIVE-REGISTER.md` | ❌ W0 | ⬜ pending |
| 06-T2 | 06 | 4 | GREEN-10 | T-198-06-01, T-198-06-03 | One-way publish decision recorded | artifact check | `grep -q '^## Publish-path and secret-store decisions' .planning/phases/198-green-bringup/198-TRIAGE.md` | ❌ W0 | ⬜ pending |
| 06-T3 | 06 | 4 | GREEN-09, GREEN-10 | T-198-06-01, T-198-06-02, T-198-06-06 | Paid path unreachable; one gated publish path | contract test | `mix test test/threadline/ci_topology_contract_test.exs` | ⚠️ additive | ⬜ pending |
| 06-T4 | 06 | 4 | GREEN-11 | T-198-06-05 | Broken never mislabelled as flaky | live workflow + YAML | every job in flake-detection.yml bounded; classification branch present — dispatch verification see Manual-Only | ⚠️ additive | ⬜ pending |
| 07-T1 | 07 | 5 | GREEN-07, GREEN-12 | T-198-07-04 | Irreversible step gated on steps 1–4 | artifact check | `grep -q '^## D-34 step 5 authorization' .planning/audits/198-branch-protection-migration.md` | ❌ W0 | ⬜ pending |
| 07-T2 | 07 | 5 | GREEN-08 | T-198-07-01, T-198-07-02, T-198-07-03, T-198-07-05 | Contexts diff AND proof-of-emission | committed script | `bash bin/verify-branch-protection` | ❌ W0 | ⬜ pending |
| 07-T3 | 07 | 5 | GREEN-07, GREEN-12 | T-198-07-04, T-198-07-06 | Green inside budget; tags durable off-laptop | git + `gh run view` | `git log origin/main..main` empty; run elapsed ≤ 20 min; `git ls-remote --tags origin 'refs/tags/archive/*'` non-empty | ❌ W0 (post-merge) | ⬜ pending |

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

- [ ] `bin/verify-branch-protection` — new committed script (D-12), assigned to task **07-T2**
- [ ] `.github/workflows/branch-protection.yml` — deliberately its own workflow, NOT a conditionally-skipped job inside the aggregate's `needs:` list

**Constraint carried from CONTEXT.md `<code_context>`:** Phase 199 / DECOUPLE-01 requires `mix ci.all` to pass with `.planning/` renamed away — **no gate may read any artifact under `.planning/`.** Evidence artifacts are outputs, never test inputs.

**Verified against the plan set (2026-08-27):** every `<automated>` command across Plans 01–07 targets `git`, `gh`, `mix`, `yq`/`jq`, `bash`, or a path under `.github/`, `bin/`, `test/`, `lib/`, `examples/` — the only `.planning/` paths appearing in a verify command are `test -f` / `grep` **artifact-existence** assertions inside plan-local task verification, none of which is wired into `mix ci.all` or any CI job. No gate reads `.planning/`.

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
