---
phase: 57
slug: optional-deps-and-module-gating
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-06
---

# Phase 57 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in to Elixir) |
| **Config file** | `mix.exs` (test paths), `test/test_helper.exs` |
| **Quick run command** | `mix verify.compile_no_optional` (compile-only check, no tests) |
| **Full suite command** | `mix ci.all` (format + credo + compile_no_optional + test + …) |
| **Estimated runtime** | ~5-10s for `verify.compile_no_optional`; ~60-120s for `mix ci.all` |

---

## Sampling Rate

- **After every task commit:** Run `mix compile --warnings-as-errors` (fast feedback that the file edits compile)
- **After mix.exs deps edit:** Run `mix deps.get` then `mix verify.compile_no_optional` to prove the gating wrapper holds when optional deps are absent
- **After plan wave (single plan, single wave):** Run `mix ci.all` to prove the new alias is in the pipeline and green
- **Before `/gsd-verify-work`:** `mix verify.compile_no_optional` AND `mix ci.all` both green locally; CI run on GH Actions shows the new `verify-compile-no-optional` job passing on the push
- **Max feedback latency:** 10 seconds for the compile-only check; 120 seconds for full suite

---

## Per-Task Verification Map

> Filled by gsd-planner during plan generation. Each row maps a planned task to its automated verification command. The shape below is illustrative; the planner will replace with concrete task IDs once PLAN.md is generated.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 57-01-01 | 01 | 1 | SURF-02 | — | mix.exs declares 4 optional Phoenix/LV deps | compile | `grep -E 'phoenix.*optional: true' mix.exs \| wc -l` returns 4 | ✅ | ⬜ pending |
| 57-01-02 | 01 | 1 | SURF-02 | — | mix verify.compile_no_optional alias exists and runs `mix compile --no-optional-deps --warnings-as-errors` | compile | `mix help verify.compile_no_optional` exits 0; `mix verify.compile_no_optional` exits 0 | ✅ | ⬜ pending |
| 57-01-03 | 01 | 1 | SURF-02 | — | `verify.compile_no_optional` is in `ci.all` between `compile --warnings-as-errors` and `verify.test` | grep | `grep -A 30 '"ci.all":' mix.exs \| grep verify.compile_no_optional` | ✅ | ⬜ pending |
| 57-01-04 | 01 | 1 | SURF-03 | — | `lib/threadline/operator_surface.ex` exists, wraps `defmodule Threadline.OperatorSurface` in file-scope `if Code.ensure_loaded?(Phoenix.LiveView) do … end` | unit | `test -f lib/threadline/operator_surface.ex && grep -q 'if Code.ensure_loaded?(Phoenix.LiveView)' lib/threadline/operator_surface.ex` | ✅ | ⬜ pending |
| 57-01-05 | 01 | 1 | SURF-03 | — | `@moduledoc` includes "Available since 0.4.0" line and forward-references Phase 58's `Threadline.OperatorSurface.Router` | grep | `grep -E 'Available since 0\\.4\\.0' lib/threadline/operator_surface.ex && grep -E 'Threadline\\.OperatorSurface\\.Router' lib/threadline/operator_surface.ex` | ✅ | ⬜ pending |
| 57-01-06 | 01 | 1 | SURF-03 | — | Capture path runtime unchanged when LV absent — `mix compile --no-optional-deps --warnings-as-errors` succeeds and emits no warnings | compile | `mix verify.compile_no_optional 2>&1 \| grep -E 'warning\|Warning' \| wc -l` returns 0 | ✅ | ⬜ pending |
| 57-01-07 | 01 | 1 | SURF-02, SURF-03 | — | `.github/workflows/ci.yml` has a job with stable id `verify-compile-no-optional` running `mix verify.compile_no_optional` on push and pull_request | grep | `grep -E '^  verify-compile-no-optional:' .github/workflows/ci.yml` matches | ✅ | ⬜ pending |

---

## Wave 0 Requirements

- ExUnit is already installed and configured (sibling phases have running suites). No new framework install needed.
- No new test files are required for this phase: per CONTEXT.md D-14, the doc-contract test for "Threadline.OperatorSurface defined when LV present, absent when LV missing" is **deferred to Phase 58** alongside the first behavioural module. Phase 57's verification surface is purely the `mix verify.compile_no_optional` alias + the dedicated GH Actions job, which exercise the gating end-to-end without per-module assertions.
- Wave 0 install for this phase: **none**. The existing test infrastructure is sufficient because Phase 57 ships zero behaviour and only one `@moduledoc`-bearing namespace module.

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| GH Actions job `verify-compile-no-optional` runs on the actual push and is green in the GitHub UI | SURF-02, SURF-03 | The local `mix verify.compile_no_optional` proves the alias works; CI proves the *job* is wired correctly. Asserting CI behaviour from a local test would require shelling out to `act` or duplicating job YAML in tests, both of which are heavier than a one-time PR-time visual check. | After pushing the phase commit, open the GitHub Actions run for that commit, find the `verify-compile-no-optional` job, and confirm it is green. Cite the run URL in the verify-phase artifact. |
| Hexdocs preview shows `Threadline.OperatorSurface` in module index when built with LV present, and absent when built without LV | SURF-03 | This is documentation rendering, not runtime behaviour; ExDoc's output is not introspectable from ExUnit without running the doc build twice in two dep configurations. The automated `verify.compile_no_optional` already proves the **module** vanishes; the docs assertion is a secondary visual check. | Before merging, run `mix docs` locally with the optional Phoenix/LV deps installed and confirm `Threadline.OperatorSurface` appears in `doc/index.html`. Optionally rebuild docs after `mix.exs` is edited to remove the optional deps from the lockfile and confirm absence. *Discretionary — only required if questioning the gating idiom.* |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none required for Phase 57 — see above)
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s (full `mix ci.all`); < 10s (compile-only check)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending — set to approved YYYY-MM-DD after gsd-plan-checker passes.
