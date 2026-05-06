---
phase: 57-optional-deps-and-module-gating
plan: 01
subsystem: infra
tags:
  - elixir
  - mix
  - phoenix
  - phoenix_live_view
  - optional-deps
  - github-actions
  - operator-surface
  - hex-package

# Dependency graph
requires:
  - phase: 56-docs-contracts-and-arc-alignment
    provides: v1.16 close — investigation contracts + canonical docs alignment that the operator surface will render
provides:
  - Four `optional: true` Phoenix/LiveView family deps (`phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub`) declared in `mix.exs`
  - `Threadline.OperatorSurface` namespace module gated at file scope on `Code.ensure_loaded?(Phoenix.LiveView)` (documentation-only — no functions, no `@behaviour`, no `defstruct`)
  - `mix verify.compile_no_optional` named alias running `compile --no-optional-deps --warnings-as-errors`, folded into `ci.all` between `compile --warnings-as-errors` and `verify.test`
  - Stable-id GitHub Actions job `verify-compile-no-optional` running on push and pull_request
  - CONTRIBUTING.md row in the stable-job-keys table for the new gate
affects:
  - Phase 58 (mount macro must compile under the file-scope wrap idiom this phase ships and is the first to add a `def`/`defmacro` body inside the gated module space)
  - Phase 59-61 (every operator-surface LiveView module compiles under the same file-scope `Code.ensure_loaded?(Phoenix.LiveView)` wrapper)
  - Phase 62 (`mix threadline.incident` is no-LiveView — does not need the wrapper but coexists with it)
  - Phase 63 (CHANGELOG entry must document the four new optional deps shipped here)

# Tech tracking
tech-stack:
  added:
    - "phoenix ~> 1.7 (optional)"
    - "phoenix_live_view ~> 1.0 (optional)"
    - "phoenix_html ~> 4.0 (optional)"
    - "phoenix_pubsub ~> 2.1 (optional)"
  patterns:
    - "File-scope `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule ... end end` — Sentry-elixir `lib/sentry/live_view_hook.ex` idiom adapted to Threadline namespace"
    - "ExDoc `@moduledoc since: \"X.Y.Z\"` attribute (separate from heredoc) for since-badge rendering — first use in this codebase"
    - "Italicized `*Available since X.Y.Z.*` line inside `@moduledoc` heredoc, bare-version style (no `v` prefix) to match Threadline CHANGELOG style"
    - "Named `mix verify.compile_no_optional` alias paired with stable-id `verify-compile-no-optional` GH Actions job (alias underscore ↔ job-id hyphen split, mirroring existing `verify.format`/`verify-format` and `verify.credo`/`verify-credo`)"

key-files:
  created:
    - "lib/threadline/operator_surface.ex"
    - ".planning/phases/57-optional-deps-and-module-gating/57-01-SUMMARY.md"
  modified:
    - "mix.exs"
    - "mix.lock"
    - ".github/workflows/ci.yml"
    - "CONTRIBUTING.md"

key-decisions:
  - "Adopted the file-scope `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule ... end end` wrapper at file scope (not inside the module body) to avoid the elixir-lang/elixir#8970 footgun where `use Phoenix.LiveView` macros expand at compile time before any inner `if` evaluates"
  - "Pinned each optional dep to a single major-version line (`~> 1.7`, `~> 1.0`, `~> 4.0`, `~> 2.1`) rather than Sentry's dual-range `~> 0.20 or ~> 1.0` shape — Threadline is greenfield so the planner explicitly drops 0.20.x for module-gating simplicity (D-01)"
  - "Kept `:plug` HARD (not optional) per D-02 — it is pervasively typed across `Threadline.Plug` (154 lines) and `Threadline.Integrations.Sigra` and an optional Plug would create four new gating sites for a phantom Ecto-only adopter cohort"
  - "GH Actions job calls the named alias `mix verify.compile_no_optional` (not the raw `mix compile --no-optional-deps --warnings-as-errors`) per the OSS DNA \"named entrypoints\" rule, mirroring how verify-format runs `mix verify.format` and verify-credo runs `mix verify.credo`"
  - "Did NOT touch `mix.exs` `application/0` `extra_applications: [:logger]` (RESEARCH.md Pitfall 3) — adding `:phoenix_live_view` to either list would force the BEAM to start it at boot regardless of `optional: true` and produce capture-only-adopter boot warnings"
  - "Did NOT add `Threadline.OperatorSurface` to `groups_for_modules:` in `mix.exs` `docs/0` per CONTEXT.md \"Things to NOT Do\" — wait until Phase 58 so a single hexdocs group entry covers the surface family"
  - "Did NOT pre-create `lib/threadline/operator_surface/` (the directory) — Phase 58 lands the first file under it, and an empty placeholder file would compile vacuously and pollute hexdocs"
  - "INCLUDED the CONTRIBUTING.md row in this phase (planner discretion per CONTEXT.md \"Agent's discretion\") — single-line addition co-located with the change set's atomic commits, avoids 5-phase doc staleness until Phase 63"

patterns-established:
  - "Compile-time module gating: file-scope `if Code.ensure_loaded?(SomeOptionalDep) do defmodule ... end end` wrapper — to be replicated in every Phase 58-61 module under the `Threadline.OperatorSurface` namespace"
  - "ExDoc since-badge: `@moduledoc since: \"X.Y.Z\"` attribute placed AFTER the closing `\"\"\"` of the docstring heredoc, with bare-version string"
  - "Optional-dep verification gate: `mix verify.<name>` alias paired with stable-id `verify-<name>` GH Actions job (alias dot↔dash split convention)"

requirements-completed:
  - SURF-02
  - SURF-03

# Metrics
duration: 35min
completed: 2026-05-06
---

# Phase 57 Plan 01: Optional Deps & Module Gating Summary

**Phoenix/LiveView family declared optional in `mix.exs`, `Threadline.OperatorSurface` namespace gated at file scope on `Code.ensure_loaded?(Phoenix.LiveView)`, and a dedicated `verify-compile-no-optional` CI gate enforces the capture-only-adopter contract from day one.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-05-06T08:55:00Z (approx — agent spawn)
- **Completed:** 2026-05-06T09:30:50Z
- **Tasks:** 5
- **Files modified:** 4 (plus `mix.lock` from `mix deps.get`, plus this SUMMARY)

## Accomplishments

- Capture-only adopters now install `:threadline` with zero Phoenix or LiveView code compiled (four `optional: true` deps).
- The file-scope `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule Threadline.OperatorSurface do ... end end` idiom is in place and proven by both compile legs (LV present and LV absent).
- A regression in optional-dep gating now fails fast in two places: (1) `mix ci.all` locally (via the new step between `compile --warnings-as-errors` and `verify.test`) and (2) the `verify-compile-no-optional` GitHub Actions job on every push and PR.
- The `@moduledoc since: "0.4.0"` ExDoc badge attribute is introduced for the first time in the codebase, establishing the convention for v0.4.0+ module additions.

## Task Commits

Each task committed atomically:

1. **Task 1: Add four optional Phoenix/LV deps to mix.exs** — `4281556` (chore)
2. **Task 2: Add verify.compile_no_optional alias and fold into ci.all** — `b8e7044` (chore)
3. **Task 3: Create lib/threadline/operator_surface.ex (gated namespace module)** — `409d135` (feat)
4. **Task 4: Add verify-compile-no-optional GitHub Actions job** — `5d0aebf` (ci)
5. **Task 5: Add verify-compile-no-optional row to CONTRIBUTING.md and run ci.all** — `719d7ac` (docs)

**Plan metadata commit:** to follow (this SUMMARY + STATE.md + ROADMAP.md + REQUIREMENTS.md)

## Files Created/Modified

### Created

- **`lib/threadline/operator_surface.ex`** (22 lines) — Gated namespace module wrapping `defmodule Threadline.OperatorSurface` at file scope on `Code.ensure_loaded?(Phoenix.LiveView)`. Documentation-only body: `@moduledoc` heredoc with the italicized "Available since 0.4.0" line, separate `@moduledoc since: "0.4.0"` ExDoc badge attribute, and forward-reference to the Phase 58 mount macro `Threadline.OperatorSurface.Router`.

### Modified

- **`mix.exs`** — Added four `optional: true` Phoenix/LiveView family deps between `:telemetry` and `:credo`; added `verify.compile_no_optional` alias; folded the alias into `ci.all` between `compile --warnings-as-errors` and `verify.test`.
- **`mix.lock`** — Picked up `phoenix`, `phoenix_html`, `phoenix_live_view`, `phoenix_pubsub`, `phoenix_template`, `websock`, `websock_adapter` from `mix deps.get` (Threadline's own dev env always pulls optional deps per the Library Guidelines).
- **`.github/workflows/ci.yml`** — Updated top-of-file job-id contract comment to list `verify-compile-no-optional` between `verify-credo` and `verify-test`; added the new `verify-compile-no-optional` job (single-checkout, single-setup-beam, no Postgres `services:` block) calling `mix verify.compile_no_optional`.
- **`CONTRIBUTING.md`** — Added one row to the "Stable job keys" table for `verify-compile-no-optional`, placed between `verify-credo` and `verify-test` to match the GH Actions file ordering and the top-of-file job-id contract comment.

### Final Dep Declarations (verbatim from `mix.exs`)

```elixir
{:phoenix, "~> 1.7", optional: true},
{:phoenix_live_view, "~> 1.0", optional: true},
{:phoenix_html, "~> 4.0", optional: true},
{:phoenix_pubsub, "~> 2.1", optional: true},
```

## Verification

### Local verification (after Task 4)

- `mix verify.compile_no_optional` exits 0 with **zero warnings** under a cold `_build/dev` build.
- `_build/dev/lib/` after the cold no-optional-deps build contains **none** of `phoenix`, `phoenix_html`, `phoenix_live_view`, `phoenix_pubsub` (verified by `ls _build/dev/lib/` post-build) — the optional deps are correctly excluded from the load path.
- `_build/dev/lib/threadline/ebin/Elixir.Threadline.OperatorSurface.beam` is **absent** in the no-optional-deps build (verified by `ls ... | grep OperatorSurface` exiting non-zero) — the file-scope wrap correctly short-circuits.
- With LV present (`mix compile --warnings-as-errors`), `Elixir.Threadline.OperatorSurface.beam` **is** produced and ExDoc would render it.

### Local verification (after Task 5)

Each `mix ci.all` step was run individually with `MIX_ENV=test DB_PORT=5433` (Threadline's docker-compose Postgres maps to 5433):

| Step                              | Result      | Notes                                                                |
| --------------------------------- | ----------- | -------------------------------------------------------------------- |
| `mix verify.format`               | **BLOCKED** | Pre-existing format drift in 7 files outside this phase's scope (see Deferred Issues) |
| `mix verify.credo`                | exit 0      | 75 source files, no issues                                            |
| `mix compile --warnings-as-errors`| exit 0      | Threadline app compiles cleanly with all optional deps installed      |
| `mix verify.compile_no_optional`  | exit 0      | Zero warnings, gated module BEAM absent                               |
| `mix verify.test`                 | exit 0      | 270 tests, 0 failures                                                 |
| `mix verify.threadline`           | exit 0      | 1/1 expected tables covered                                           |
| `mix verify.example`              | exit 0      | 17 example-app tests, 0 failures                                      |
| `mix verify.doc_contract`         | exit 0      | 12 doc-contract tests, 0 failures                                     |

Aggregate: every step except `verify.format` is green. The `verify.format` block is **not** caused by this phase — see "Deferred Issues" below.

### Files in this phase's scope are format-clean

`mix format --check-formatted mix.exs lib/threadline/operator_surface.ex` exits 0. The four phase-scope files (`mix.exs`, `lib/threadline/operator_surface.ex`, `.github/workflows/ci.yml`, `CONTRIBUTING.md`) introduce zero new format drift.

## Decisions Made

See the `key-decisions` frontmatter block above. Most decisions were locked in `57-CONTEXT.md` (D-01 through D-14) before planning began; this execution applied them verbatim. The single planner-discretion decision was including the CONTRIBUTING.md row in this phase rather than deferring to Phase 63 — the planner's recommendation in `57-RESEARCH.md` Example E was followed (single-line addition co-located with the atomic commit set).

## Deviations from Plan

**None — the plan executed exactly as written.** All five tasks' actions, acceptance criteria, and verbatim final-state code blocks (PATTERNS.md Excerpts 1-6) were applied without modification. No Rule 1, 2, or 3 auto-fixes were required during execution. No Rule 4 architectural decisions surfaced.

## Issues Encountered

### Pre-existing format drift outside this phase's scope (NOT a Phase 57 deviation)

`mix verify.format` (the first step of `mix ci.all`) reports drift in 7 files **outside** the four files this phase's frontmatter `files_modified` lists. The drift is documented in `STATE.md` "Blockers":

> Repo-wide `mix ci.all` still reports pre-existing format drift in untouched files outside the v1.16 closeout set.

The plan's Task 5 action explicitly directed the executor to surface this as a blocker rather than absorbing scope:

> If `mix verify.format` reports drift in files NOT in this phase's `files_modified` list, do NOT silently fix them — they belong to a separate concern.

**Drifted files (all outside Phase 57 scope):**

- `test/support/getting_started_fixtures.ex`
- `test/threadline/integrations/sigra_doc_contract_test.exs`
- `lib/threadline/investigation.ex`
- `test/threadline/investigation_test.exs`
- `test/threadline/getting_started_fixtures_test.exs`
- `test/threadline/stg_doc_contract_test.exs`
- `test/threadline/release_artifact_contract_test.exs`

**Recommendation:** Address in a separate cleanup commit (or a focused tech-debt phase) so the fix-set is bounded and reviewable. Phase 57's atomic commit set is intentionally narrow.

## Deferred Issues

| Item                              | Why Deferred                                                                                                              | Forward Reference                                  |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| Repo-wide `mix verify.format` drift | Outside Phase 57's `files_modified` set; pre-existing tech debt from prior phases (recorded in STATE.md "Blockers" since v1.16) | Tech-debt cleanup commit/phase (TBD)               |
| `mix threadline.incident` Mix task    | Out of Phase 57 scope per `phase_boundary_reminders`                                                                        | Phase 62                                           |
| Mount macro `Threadline.OperatorSurface.Router`     | Out of Phase 57 scope                                                                                                     | Phase 58                                           |
| `:authorize_fn` contract + compile-time fail-closed check + telemetry event | Out of Phase 57 scope                                                                                                     | Phase 58                                           |
| Doc-contract test asserting the gated module is defined when LV present and absent when LV missing | Test helper becomes reusable once Phase 58 ships the first behavioural module — deferred per D-14                          | Phase 58                                           |
| `Threadline.OperatorSurface` row in `mix.exs` `groups_for_modules:` | Wait until Phase 58 lands the first behavioural module so a single hexdocs group entry covers the surface family            | Phase 58                                           |
| `lib/threadline/operator_surface/` subdirectory     | Phase 58 lands the first file under it; pre-creating an empty placeholder would compile vacuously and pollute hexdocs        | Phase 58                                           |
| `guides/operator-surface.md`, README operator-surface section, CHANGELOG `0.4.0` entry | Out of Phase 57 scope                                                                                                     | Phase 63                                           |

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- The four `optional: true` Phoenix/LiveView family deps and the file-scope `Code.ensure_loaded?(Phoenix.LiveView)` wrapper idiom are in place. Phase 58 can paste the same wrapper around its mount macro module without any further build-system changes.
- The `verify-compile-no-optional` CI gate will catch any Phase 58+ module that is added under the `Threadline.OperatorSurface` namespace **without** the file-scope wrapper — the regression-protection contract is now enforced from day one.
- The pre-existing `mix verify.format` drift surfaced during this phase's `ci.all` run remains a known blocker on `main`. It does NOT block Phase 58's planning or execution: Phase 58 should run its acceptance criteria step-by-step (or with `mix do verify.credo + ...`) just like this phase did, and surface format drift in non-scope files the same way.

### Manual-only verifications still pending (per VALIDATION.md)

- After pushing this plan, the maintainer should open the GitHub Actions run for the phase commits, find the new `verify-compile-no-optional` job, and confirm it is green. Cite the run URL in the verify-phase artifact when running `/gsd-verify-work`.
- Hexdocs preview (discretionary): `mix docs` with optional deps installed should show `Threadline.OperatorSurface` in the module index; `mix docs` under a no-optional-deps fixture should show it absent.

---
*Phase: 57-optional-deps-and-module-gating*
*Completed: 2026-05-06*

## Self-Check: PASSED

- `lib/threadline/operator_surface.ex` — FOUND (verified `test -f`)
- `mix.exs` deps changes — FOUND (verified four `optional: true` lines, plus `:plug` unchanged, plus `application/0` unchanged)
- `mix.exs` alias + `ci.all` extension — FOUND (verified `mix help verify.compile_no_optional` shows the underlying command)
- `.github/workflows/ci.yml` job + comment update — FOUND (verified job key, name, runs-on, alias call, no `services:` block)
- `CONTRIBUTING.md` row — FOUND (verified row appears between `verify-credo` and `verify-test`)
- Commit `4281556` — FOUND (`git log` shows `chore(57-01): declare Phoenix/LiveView family deps as optional`)
- Commit `b8e7044` — FOUND (`git log` shows `chore(57-01): add verify.compile_no_optional alias and fold into ci.all`)
- Commit `409d135` — FOUND (`git log` shows `feat(57-01): add Threadline.OperatorSurface gated namespace module`)
- Commit `5d0aebf` — FOUND (`git log` shows `ci(57-01): add verify-compile-no-optional GitHub Actions job`)
- Commit `719d7ac` — FOUND (`git log` shows `docs(57-01): document verify-compile-no-optional in CONTRIBUTING.md`)
