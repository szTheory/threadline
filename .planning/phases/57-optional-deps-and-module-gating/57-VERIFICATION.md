---
phase: 57-optional-deps-and-module-gating
verified: 2026-05-06T15:30:00Z
status: human_needed
must_haves_score: 5/5
verified: 5
overrides_applied: 0
human_verification:
  - test: "Confirm GitHub Actions run for the phase commits shows verify-compile-no-optional job green"
    expected: "On the GitHub Actions UI for any of the phase 57 commits (4281556, b8e7044, 409d135, 5d0aebf, 719d7ac, ba91e16) the new verify-compile-no-optional job runs and exits green alongside verify-format, verify-credo, verify-test, verify-pgbouncer-topology, verify-docs, verify-hex-package, and verify-release-shape"
    why_human: "Per VALIDATION.md Manual-Only Verifications — local mix verify.compile_no_optional proves the alias works, but asserting CI behaviour from a local checkout would require shelling out to act or duplicating job YAML in tests. This is documented as not auto-verifiable. Cite the run URL in the verify-phase artifact."
  - test: "Hexdocs preview shows Threadline.OperatorSurface in module index when LV present, absent when LV absent (DISCRETIONARY)"
    expected: "mix docs (LV present) renders Threadline.OperatorSurface in doc/index.html with the 'since 0.4.0' badge; a no-optional-deps docs build (or fixture) shows it absent."
    why_human: "Documentation rendering is not introspectable from ExUnit without two doc builds in two dep configurations. The automated verify.compile_no_optional already proves the BEAM vanishes; this is a secondary visual check (per VALIDATION.md, marked discretionary)."
---

# Phase 57: Optional Deps & Module Gating Verification Report

**Phase Goal:** Make Phoenix/LiveView opt-in at install time so capture-only adopters never compile UI code.
**Verified:** 2026-05-06T15:30:00Z
**Status:** human_needed (5/5 must-haves verified locally; 1 manual-only CI check + 1 discretionary docs check pending)
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #   | Truth                                                                                                                                                                                                                       | Status     | Evidence                                                                                                                                                                                                                                                                                                                                                                                |
| --- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | mix.exs declares phoenix, phoenix_live_view, phoenix_html, phoenix_pubsub as `optional: true` so capture-only adopters install threadline with zero Phoenix/LV code compiled                                                | ✓ VERIFIED | `grep -cE 'optional: true' mix.exs` → `4`. All four exact lines present at mix.exs:57-60: `{:phoenix, "~> 1.7", optional: true}`, `{:phoenix_live_view, "~> 1.0", optional: true}`, `{:phoenix_html, "~> 4.0", optional: true}`, `{:phoenix_pubsub, "~> 2.1", optional: true}`. `:plug` remains hard at line 55. `application/0` extra_applications still `[:logger]` only. |
| 2   | lib/threadline/operator_surface.ex defines Threadline.OperatorSurface gated at file scope on Code.ensure_loaded?(Phoenix.LiveView), so `mix compile --warnings-as-errors` succeeds with and without LV present              | ✓ VERIFIED | File exists (22 lines). Line 1: `if Code.ensure_loaded?(Phoenix.LiveView) do` (file scope, NOT inside module body). Line 2: `  defmodule Threadline.OperatorSurface do` (indented under if). Body contains `@moduledoc` heredoc with `*Available since 0.4.0.*` line + separate `@moduledoc since: "0.4.0"` ExDoc badge + forward-ref to `Threadline.OperatorSurface.Router`. Zero `def`, `@behaviour`, `defstruct`, `alias`, `import` lines (grep count = 0). Both legs compile clean: cold `mix compile --warnings-as-errors` exits 0 (BEAM produced); cold `mix verify.compile_no_optional` exits 0 (BEAM absent). |
| 3   | Capture path runtime observably unchanged when LV absent — `mix compile --no-optional-deps --warnings-as-errors` emits zero warnings, Threadline.OperatorSurface is not loaded, no new modules loaded                       | ✓ VERIFIED | After `rm -rf _build/dev && mix verify.compile_no_optional`: exit 0, zero warnings in stdout/stderr (only `Compiling N files` and `Generated APP app` lines). `_build/dev/lib/threadline/ebin/Elixir.Threadline.OperatorSurface.beam` is **absent** (file-scope if short-circuits). The four optional Phoenix-family deps (`phoenix`, `phoenix_html`, `phoenix_live_view`, `phoenix_pubsub`) are **absent** from `_build/dev/lib/`. `application/0` is unchanged so no boot-time `extra_applications` change can fire warnings. |
| 4   | `mix verify.compile_no_optional` alias exists, runs `compile --no-optional-deps --warnings-as-errors`, and is folded into ci.all between `compile --warnings-as-errors` and `verify.test`                                   | ✓ VERIFIED | mix.exs:77 `"verify.compile_no_optional": ["compile --no-optional-deps --warnings-as-errors"]`. mix.exs:78-87 `ci.all` step list contains `verify.compile_no_optional` at index 3 (after `compile --warnings-as-errors` at index 2, before `verify.test` at index 4). `mix help verify.compile_no_optional` exits 0 and prints the underlying command. |
| 5   | A dedicated GitHub Actions job with stable immutable id `verify-compile-no-optional` runs `mix verify.compile_no_optional` on push and pull_request                                                                          | ✓ VERIFIED | .github/workflows/ci.yml:50-65 defines the job. Stable id `verify-compile-no-optional` (hyphenated, matching twin convention). Calls the named alias `mix verify.compile_no_optional` (NOT raw command, satisfying OSS DNA named-entrypoints rule). Top-of-file job-id contract comment (line 2) lists the new id between `verify-credo` and `verify-test`. `runs-on: ubuntu-24.04`, `actions/checkout@v4`, `erlef/setup-beam@v1` with `elixir-version: "1.17.3"` and `otp-version: "27.0"` — all match twins. No `services:` block (compile-only). Inherits the `on: push branches: [main]` + `pull_request: branches: [main]` triggers from the workflow root. CONTRIBUTING.md table row added between `verify-credo` and `verify-test`. |

**Score:** 5/5 truths verified.

---

### Required Artifacts

| Artifact                              | Expected                                                                       | Status     | Details                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| ------------------------------------- | ------------------------------------------------------------------------------ | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `mix.exs`                             | Four optional Phoenix/LV deps + verify.compile_no_optional alias + ci.all extension | ✓ VERIFIED | All four `optional: true` lines (mix.exs:57-60); alias at mix.exs:77; ci.all step list correctly ordered at mix.exs:78-87; format-clean.                                                                                                                                                                                                                                                                                                       |
| `lib/threadline/operator_surface.ex`  | Gated namespace module Threadline.OperatorSurface (documentation-only)         | ✓ VERIFIED | 22 lines (≥18 expected). File-scope `if Code.ensure_loaded?(Phoenix.LiveView) do` wrapper at line 1. `defmodule Threadline.OperatorSurface do` indented under the if. `@moduledoc` heredoc with required content. `@moduledoc since: "0.4.0"` badge. Zero functions/behaviours/aliases inside body. Both compile legs work. Format-clean. Subdirectory `lib/threadline/operator_surface/` correctly NOT pre-created (per D-06).                                                                                                                                          |
| `.github/workflows/ci.yml`            | verify-compile-no-optional CI job                                              | ✓ VERIFIED | Top-of-file comment updated (line 2). Job at lines 50-65 with stable id, name "Compile without optional deps", correct elixir/OTP versions, calls the alias, no Postgres `services:` block. Job key appears exactly once. Job ordering preserved: verify-credo → verify-compile-no-optional → verify-test.                                                                                                                                              |
| `CONTRIBUTING.md`                     | Job key table row for verify-compile-no-optional                               | ✓ VERIFIED | Row at line 58: `\| `verify-compile-no-optional` \| `mix verify.compile_no_optional` (compile without optional deps; gates against missing Phoenix/LiveView) \|`. Placed between `verify-credo` (line 57) and `verify-test` (line 59) to match GH Actions ordering.                                                                                                                                                                              |

---

### Key Link Verification

| From                                                            | To                                                            | Via                                                                  | Status   | Details                                                                                                                                                                  |
| --------------------------------------------------------------- | ------------------------------------------------------------- | -------------------------------------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| mix.exs `verify.compile_no_optional` alias                      | `compile --no-optional-deps --warnings-as-errors`             | alias entry in `defp aliases`                                        | ✓ WIRED  | mix.exs:77 binds the alias to `["compile --no-optional-deps --warnings-as-errors"]`. `mix help verify.compile_no_optional` confirms resolution.                          |
| .github/workflows/ci.yml `verify-compile-no-optional` job       | `mix verify.compile_no_optional`                              | `run:` step in job                                                   | ✓ WIRED  | ci.yml:64-65 has `name: Compile without optional deps (warnings-as-errors)` step with `run: mix verify.compile_no_optional`. Calls the alias, not the raw command.       |
| lib/threadline/operator_surface.ex `defmodule`                  | Phoenix.LiveView optional dep presence                        | file-scope `if Code.ensure_loaded?(Phoenix.LiveView) do` wrapper     | ✓ WIRED  | Line 1 wraps the whole `defmodule` at file scope. Verified by both compile legs: BEAM produced when LV present, BEAM absent when LV absent (no warnings either case). |
| ci.all step list                                                | new step folded between compile-warnings-as-errors and verify.test | mix.exs:78-87                                                  | ✓ WIRED  | Order: `verify.format` → `verify.credo` → `compile --warnings-as-errors` → `verify.compile_no_optional` → `verify.test` → ... matches D-10.                              |

---

### Data-Flow Trace (Level 4)

Not applicable — phase ships zero behaviour, no data sources, no rendering. The `Threadline.OperatorSurface` module is documentation-only (`@moduledoc` only, no functions, no state). The verification artifact is a compile-time gate, not runtime data flow.

---

### Behavioral Spot-Checks

| Behavior                                                                                                  | Command                                                                                                                                                  | Result                                                                                                                                                                                                                                                                                                                                                                                | Status   |
| --------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| Cold no-optional-deps compile produces zero warnings, exits 0                                              | `rm -rf _build/dev && mix verify.compile_no_optional`                                                                                                    | Exit 0. Output contains only `Compiling N files (.ex/.erl)` and `Generated APP app` lines (no `warning`/`Warning` matches outside `==>` lines).                                                                                                                                                                                                                                       | ✓ PASS   |
| Cold no-optional-deps build does NOT produce the gated module's BEAM                                       | `ls _build/dev/lib/threadline/ebin/ \| grep OperatorSurface`                                                                                             | Empty (no match) — file-scope `if` correctly short-circuits when Phoenix.LiveView is absent.                                                                                                                                                                                                                                                                                          | ✓ PASS   |
| Cold no-optional-deps build excludes the four optional Phoenix-family deps from the load path             | `ls _build/dev/lib/ \| grep -E '^phoenix(_live_view\|_html\|_pubsub)?$'`                                                                                  | Empty — `phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub` all absent from `_build/dev/lib/`. (`phoenix_template`, `websock`, `websock_adapter` remain because they're transitive deps fetched into `deps/` previously; not in the `optional: true` set the plan declares.) | ✓ PASS   |
| LV-present compile produces gated module BEAM                                                              | `rm -rf _build/dev && mix compile --warnings-as-errors && ls _build/dev/lib/threadline/ebin/ \| grep OperatorSurface`                                    | Exit 0; `Elixir.Threadline.OperatorSurface.beam` produced. The four optional Phoenix-family deps are present in `_build/dev/lib/`.                                                                                                                                                                                                                                                    | ✓ PASS   |
| `mix help verify.compile_no_optional` reports the underlying command                                       | `mix help verify.compile_no_optional`                                                                                                                    | Exit 0. Prints `Alias for ["compile --no-optional-deps --warnings-as-errors"]` with `Location: mix.exs`.                                                                                                                                                                                                                                                                              | ✓ PASS   |
| Phase 57 files are format-clean                                                                            | `mix format --check-formatted mix.exs lib/threadline/operator_surface.ex CONTRIBUTING.md`                                                                | Exit 0. (.github/workflows/ci.yml is YAML, not subject to `mix format`.)                                                                                                                                                                                                                                                                                                              | ✓ PASS   |

All behavioural spot-checks pass.

---

### Requirements Coverage

| Requirement | Source Plan | Description                                                                                                                          | Status      | Evidence                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| ----------- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------ | ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| SURF-02     | 57-01-PLAN  | `phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub` declared `optional: true` in `mix.exs`                              | ✓ SATISFIED | mix.exs:57-60 contains all four lines verbatim with research-verified version constraints. `grep -cE 'optional: true' mix.exs` → 4. REQUIREMENTS.md:14 already marked `[x]` Validated 2026-05-06.                                                                                                                                                                                                                                                                                                                       |
| SURF-03     | 57-01-PLAN  | All modules under `lib/threadline/operator_surface/` are gated via Code.ensure_loaded?(Phoenix.LiveView), threadline compiles cleanly with LV absent and zero observable overhead on capture path | ✓ SATISFIED | (Stricter wording: "modules under `lib/threadline/operator_surface/`" — Phase 57 ships exactly one module at `lib/threadline/operator_surface.ex`, the namespace module. The directory `lib/threadline/operator_surface/` is correctly NOT pre-created per D-06. Phase 58+ modules will live under that directory and will inherit the same wrapping idiom.) The single shipped module is correctly gated at file scope; both compile legs pass; capture path is observably unchanged when LV is absent. REQUIREMENTS.md:15 marked `[x]` Validated. |

No orphaned requirements: all phase requirement IDs (SURF-02, SURF-03 from PLAN frontmatter) are accounted for, and REQUIREMENTS.md traceability table maps both to Phase 57 with status Validated.

---

### Anti-Patterns Found

| File                                  | Line | Pattern                                  | Severity | Impact                                                                                                                                                                          |
| ------------------------------------- | ---- | ---------------------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| (none)                                | —    | —                                        | —        | No TODO/FIXME/PLACEHOLDER, no empty handlers, no `return null`/`return []` style stubs, no console-only implementations in any of the four phase-scope files. |

The `Threadline.OperatorSurface` module is intentionally documentation-only (`@moduledoc` heredoc + `@moduledoc since: "0.4.0"`). This is NOT a stub — it is the explicit Phase 57 deliverable per D-05 ("Phase 57 ships exactly one gated module … as a documentation namespace with `@moduledoc` only"). Phase 58 ships the first behavioural module (mount macro `Threadline.OperatorSurface.Router`).

---

### Out-of-Scope Format Drift (NOT a phase 57 gap)

Per the verification context note and 57-01-SUMMARY.md "Issues Encountered", `mix verify.format` on the full repository reports drift in 7 files OUTSIDE phase 57's `files_modified` set:

- `test/support/getting_started_fixtures.ex`
- `test/threadline/integrations/sigra_doc_contract_test.exs`
- `lib/threadline/investigation.ex`
- `test/threadline/investigation_test.exs`
- `test/threadline/getting_started_fixtures_test.exs`
- `test/threadline/stg_doc_contract_test.exs`
- `test/threadline/release_artifact_contract_test.exs`

This drift is **pre-existing tech debt recorded in STATE.md "Blockers"**, not a phase 57 deviation. The executor correctly did NOT silently absorb scope. Phase 57's own four files (`mix.exs`, `lib/threadline/operator_surface.ex`, `.github/workflows/ci.yml`, `CONTRIBUTING.md`) are format-clean: `mix format --check-formatted` on those files exits 0.

**Recommendation (already captured in SUMMARY):** Address in a separate cleanup commit / focused tech-debt phase so the fix-set is bounded and reviewable.

---

### Phase Boundary Discipline

All deferred items per `phase_boundary_reminders` (D-13 / D-14) are correctly absent from the phase 57 diff:

- Mount macro `Threadline.OperatorSurface.Router` — absent (deferred to Phase 58)
- `:authorize_fn` contract / compile-time fail-closed check — absent (Phase 58)
- `[:threadline, :operator_surface, :authorize]` telemetry event — absent (Phase 58)
- LiveView screens — absent (Phases 59-61)
- `mix threadline.incident` Mix task — absent (Phase 62)
- `guides/operator-surface.md`, README operator-surface section, CHANGELOG `0.4.0` entry — absent (Phase 63)
- Doc-contract test for module presence/absence — absent (Phase 58)
- `lib/threadline/operator_surface/` subdirectory — NOT pre-created (Phase 58)
- `:plug` flipped to optional — NOT touched (D-02 holds)
- `mix.exs` `package: [files: ...]` — NOT touched (D-03 holds; existing `lib` entry covers the new file)
- `mix.exs` `application/0` `extra_applications` — NOT touched (RESEARCH.md Pitfall 3 holds)
- `Threadline.OperatorSurface` in `groups_for_modules:` — NOT added (Phase 58)

---

### Human Verification Required

**1. GitHub Actions CI green for verify-compile-no-optional**

- **Test:** Open the GitHub Actions run for any of the phase 57 commits (4281556, b8e7044, 409d135, 5d0aebf, 719d7ac, ba91e16) and confirm the `verify-compile-no-optional` job is green.
- **Expected:** The new job runs alongside the existing seven jobs (verify-format, verify-credo, verify-test, verify-pgbouncer-topology, verify-docs, verify-hex-package, verify-release-shape) and shows green.
- **Why human:** Per VALIDATION.md "Manual-Only Verifications" — local `mix verify.compile_no_optional` proves the alias works; the CI gate proves the *job* is wired. Asserting CI behaviour from a local checkout would require shelling out to `act` or duplicating job YAML in tests, both of which are heavier than a one-time PR-time visual check.
- **Outcome:** Cite the run URL in the verify-phase artifact.

**2. (Discretionary) Hexdocs preview module-presence/absence**

- **Test:** With optional Phoenix/LV deps installed, run `mix docs` and confirm `Threadline.OperatorSurface` appears in `doc/index.html` with the "since 0.4.0" badge. Optionally rebuild docs after temporarily removing the optional deps from the lockfile and confirm absence.
- **Expected:** Module visible when LV present (with "since 0.4.0" badge); module absent when LV absent.
- **Why human:** Documentation rendering is not introspectable from ExUnit without two doc builds in two dep configurations. The automated `verify.compile_no_optional` already proves the BEAM vanishes (verified above); this is a secondary visual check.
- **Outcome:** Discretionary — only required if questioning the gating idiom.

---

### Gaps Summary

**No gaps found.** All five must-have truths are verified by direct codebase inspection and behavioural spot-checks:

1. The four optional Phoenix/LV deps are declared verbatim in mix.exs with correct constraints.
2. The gated namespace module exists with the file-scope `Code.ensure_loaded?(Phoenix.LiveView)` wrapper, has documentation-only body, and compiles in both LV-present and LV-absent legs.
3. Cold no-optional-deps compile exits 0 with zero warnings; the gated BEAM is absent and the four optional Phoenix deps are absent from the load path.
4. The `verify.compile_no_optional` alias exists and is folded into `ci.all` in the correct slot.
5. The `verify-compile-no-optional` GH Actions job exists with stable id, calls the named alias (not the raw command), runs on push and PR, and has no Postgres `services:` block.

The pre-existing repo-wide `mix verify.format` drift is **out of phase 57 scope** (already documented as a blocker in STATE.md, surfaced — not absorbed — by the executor).

The only outstanding items are the two **manual-only** verifications documented above, which are non-blocking for goal achievement and are explicitly classified in `57-VALIDATION.md` as "NOT phase-gating".

---

_Verified: 2026-05-06T15:30:00Z_
_Verifier: Claude (gsd-verifier)_
