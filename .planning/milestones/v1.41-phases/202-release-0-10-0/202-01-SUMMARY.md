---
phase: 202-release-0-10-0
plan: 01
subsystem: infra
tags: [hex, release, postgres, storage-schema, ecto, mix-task, ci]

requires:
  - phase: 200-public-surface
    provides: the clean public surface 0.10.0 publishes
  - phase: 201-operator-surface
    provides: the operator-surface routes the 0.10.x upgrade row must document
provides:
  - "`Threadline.StorageSchema` defaults to the host's `public` schema; a dedicated schema is an explicit opt-in"
  - "`bin/with-rehearsal-registry` — a throwaway signed local Hex registry built from this tree's own `mix hex.build` tarball"
  - "`THREADLINE_HEX_EVALUATOR_MODE` (rehearsal | published) and `THREADLINE_PUBLISHED_VERSION` as the hex evaluator's resolution switch"
  - "`HexEvaluator.LegacyPublicSchemaTest` — an end-to-end proof that a 0.9.x-shaped install reads green"
  - "a version-literal-free, lock-free `priv/ci/hex_evaluator` fixture"
affects: [202-02 pin rewriting, 202-03 changelog and upgrade guide, 202-04 release.yml smoke-published wiring, 202-05 post-publish verification]

actuals:
  tokens: 9197
  tasks: 3
  commits: 5
  plan_head_before: 9e51da200a4beba35faad3c60e94e9683eecebd8

tech-stack:
  added: []
  patterns:
    - "Rehearsal registry: package the tree under test with `mix hex.build`, serve it from a per-run signed local registry, and resolve the fixture against it — so a pre-publish gate measures the tree instead of the last published release"
    - "Mode-switched dependency resolution in a CI fixture, with `System.fetch_env!/1` on the published path so the mode cannot silently degrade to rehearsal"
    - "Artifact-measuring assertions: `information_schema` for where objects actually live, rather than re-reading the config that was supposed to put them there"

key-files:
  created:
    - bin/with-rehearsal-registry
    - priv/ci/hex_evaluator/test/hex_evaluator/legacy_public_schema_test.exs
  modified:
    - lib/threadline/storage_schema.ex
    - lib/mix/tasks/threadline.install.ex
    - guides/getting-started-saas.md
    - priv/ci/hex_evaluator/mix.exs
    - mix.exs
    - .gitignore
    - test/threadline/storage_schema_test.exs
    - test/threadline/getting_started_saas_doc_contract_test.exs
    - test/threadline/readme_doc_contract_test.exs

key-decisions:
  - "Storage-schema default flipped to `public`, making 0.10.0 non-breaking for the entire pre-0.10 adopter population; a dedicated schema is now explicit opt-in"
  - "The hex evaluator resolves `:threadline` from a per-run local rehearsal registry by default, and from hexpm only in the `published` mode set by the release workflow"
  - "`priv/ci/hex_evaluator/mix.lock` is untracked and gitignored: the fixture's job is resolvability, not reproducibility"
  - "The guide's worked storage-schema example changed from `\"audit\"` to `\"threadline\"`, and the two doc contract tests that pinned the old literal moved with it and gained assertions covering the new steering"
  - "The banned-planning-vocabulary rule was honoured by rewriting two `mix.exs` comments rather than relaxing the archive contract"

patterns-established:
  - "Per-invocation signing material: the registry key pair is generated into `mktemp -d`, never enters the working tree, and is destroyed by a trap on every exit path"
  - "Cache and lock hygiene as a correctness requirement, not tidiness: a rehearsal tarball keeps the same version across tree changes, so the dep is unlocked and the throwaway repo's Hex cache purged on every run"

requirements-completed: [RELEASE-03]

coverage:
  - id: D1
    description: "`Threadline.StorageSchema` defaults to the host's `public` schema, and a dedicated schema remains an explicit opt-in."
    requirement: "RELEASE-03"
    verification:
      - kind: unit
        ref: "test/threadline/storage_schema_test.exs#resolves to the host's public schema when no storage_schema is configured"
        status: pass
      - kind: unit
        ref: "test/threadline/storage_schema_test.exs#a dedicated schema stays available as an explicit opt-in"
        status: pass
    human_judgment: false
  - id: D2
    description: "A 0.9.x-shaped install (audit tables in `public`, no `storage_schema` key) installs a packaged build of this tree and reads audit rows green end-to-end."
    requirement: "RELEASE-03"
    verification:
      - kind: e2e
        ref: "priv/ci/hex_evaluator/test/hex_evaluator/legacy_public_schema_test.exs#a trigger-written change row reads back with no schema prefix"
        status: pass
      - kind: e2e
        ref: "priv/ci/hex_evaluator/test/hex_evaluator/legacy_public_schema_test.exs#the audit tables are physically in public, and no threadline schema exists"
        status: pass
      - kind: other
        ref: "ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix verify.hex_evaluator"
        status: pass
    human_judgment: false
  - id: D3
    description: "`mix verify.hex_evaluator` resolves `:threadline` from the rehearsal registry built out of THIS tree's tarball, not from hexpm."
    requirement: "RELEASE-03"
    verification:
      - kind: other
        ref: "grep threadline_rehearsal priv/ci/hex_evaluator/mix.lock after mix verify.hex_evaluator"
        status: pass
      - kind: other
        ref: "staleness probe — editing @default in the tree changes the fixture's observed behaviour within one run"
        status: pass
    human_judgment: false
  - id: D4
    description: "`priv/ci/hex_evaluator` carries no threadline version literal in tracked source and no tracked lock."
    requirement: "RELEASE-03"
    verification:
      - kind: other
        ref: "git ls-files priv/ci/hex_evaluator/mix.lock (empty) and git check-ignore (exit 0)"
        status: pass
      - kind: other
        ref: "grep -cE '\"(~>|==) 0\\.' priv/ci/hex_evaluator/mix.exs == 0"
        status: pass
    human_judgment: false
  - id: D5
    description: "`mix threadline.install` run without a configured `storage_schema` recommends the dedicated-schema config key; run with it set, it stays silent."
    verification:
      - kind: manual_procedural
        ref: "scratch app run, both branches — recommendation printed when unset, 0 occurrences when set"
        status: pass
    human_judgment: false
  - id: D6
    description: "`guides/getting-started-saas.md` presents the dedicated schema as the recommended choice for a new install and states the `public` default."
    verification:
      - kind: unit
        ref: "test/threadline/getting_started_saas_doc_contract_test.exs#getting-started documents custom storage schema before install generation"
        status: pass
      - kind: unit
        ref: "test/threadline/readme_doc_contract_test.exs#README leaves configuration and migration timing to its canonical guides"
        status: pass
    human_judgment: false
  - id: D7
    description: "In `published` mode with `THREADLINE_PUBLISHED_VERSION` unset, the fixture hard-fails rather than silently falling back to rehearsal."
    verification:
      - kind: other
        ref: "THREADLINE_HEX_EVALUATOR_MODE=published with the version unset — mix deps.get exits 1 naming THREADLINE_PUBLISHED_VERSION"
        status: pass
    human_judgment: true
    rationale: "This truth is backstop-marked in the plan. The local mode-forced run proves the call site dies loudly, but the claim that it behaves this way *inside the release workflow* is only observable in a real release run. Plan 05 Task 4 converts it to read-the-log human verification."
  - id: D8
    description: "The one-way storage-schema default flip was confirmed before any source edit."
    verification: []
    human_judgment: true
    rationale: "Task 1 was a checkpoint:decision that auto-selected under `mode: yolo` + `workflow.auto_advance: true`. No fresh live human confirmation was obtained during execution — see 'Checkpoint handling' below. A maintainer should confirm the flip explicitly before publish."

duration: 26min
completed: 2026-09-22
status: complete
---

# Phase 202 Plan 01: Non-breaking storage-schema default, proven by a rehearsal-registry install Summary

**`Threadline.StorageSchema` now defaults to the host's `public` schema, and the hex evaluator proves it by installing a `mix hex.build` tarball of this tree from a throwaway signed local Hex registry instead of re-testing the last published release.**

## Performance

- **Duration:** 26 min
- **Started:** 2026-09-22T13:25:56Z
- **Completed:** 2026-09-22T13:51:43Z
- **Tasks:** 3
- **Files modified:** 13 (2 created, 10 modified, 1 untracked-by-design)

## Accomplishments

- **The release-blocking split brain is closed.** `@default` is `"public"`, so a 0.9.x adopter who upgrades keeps reading the tables their already-deployed unqualified triggers write to. The dedicated `threadline` schema is now an explicit opt-in.
- **The hex evaluator measures the tree under test.** `bin/with-rehearsal-registry` packages this tree, signs a per-run local registry over it, serves it on loopback, and tears everything down in a trap. `mix verify.hex_evaluator` is now a usable *pre-publish* gate rather than a re-test of 0.9.0.
- **The flip has a regression guard that fails if the fixture stops being legacy-shaped.** `HexEvaluator.LegacyPublicSchemaTest` asserts against `information_schema` where the audit tables physically are, not against the config that was supposed to put them there.
- **New installs are steered to opt in** by both `mix threadline.install` and the getting-started guide, and the steering is contract-enforced so it cannot drift back out while the default stays flipped.

## Task Commits

1. **Task 2 (RED): storage-schema default assertion** — `af73af76` (test)
2. **Task 2 (GREEN): default flip + rehearsal registry + mode switch + lock untrack** — `037852cb` (feat)
3. **Task 3: legacy-public end-to-end proof + installer/guide steering** — `3f9e3b79` (feat)

**Plan metadata:** `7a1f47c5` (SUMMARY), followed by the final metadata commit at this plan's tip (STATE.md + ROADMAP.md). That tip commit is intentionally left unnamed here: it was amended to carry this very correction, so any hash written into it would be stale the moment it was written.

Task 1 was a `checkpoint:decision` and produced no commit.

`actuals.commits: 5` is measured with `git rev-list --count 9e51da20..HEAD` and includes both
metadata commits. The two carry the same subject line because the SUMMARY was committed first
(as the atomic write-then-commit rule requires) and the STATE/ROADMAP updates followed.

## Files Created/Modified

- `lib/threadline/storage_schema.ex` — `@default` flipped to `"public"`; `@moduledoc` and `get/1`'s `@doc` rewritten to state the public default, name the opt-in key, and record that the choice is frozen at generation time. `validate!/1`, `@identifier`, `@max_identifier_bytes`, `@threadline_tables` untouched.
- `bin/with-rehearsal-registry` (new) — builds, signs, serves, registers, runs, and tears down the `threadline_rehearsal` repo.
- `priv/ci/hex_evaluator/mix.exs` — `deps/0` mode-switches on `THREADLINE_HEX_EVALUATOR_MODE`; no threadline version literal remains.
- `priv/ci/hex_evaluator/mix.lock` — untracked and gitignored.
- `priv/ci/hex_evaluator/test/hex_evaluator/legacy_public_schema_test.exs` (new) — the legacy-`public` end-to-end proof.
- `mix.exs` — `verify_hex_evaluator/1` wraps the pipeline in the rehearsal harness (rehearsal mode) or runs it directly (published mode), and unlocks `:threadline` per run.
- `lib/mix/tasks/threadline.install.ex` — `recommend_dedicated_storage_schema/0` fires when the key is unset.
- `guides/getting-started-saas.md` — configuration step rewritten; the `{:threadline, "~> …"}` pin literal untouched.
- `.gitignore` — the fixture lock entry plus the rationale comment.
- `test/threadline/storage_schema_test.exs` — default-resolution describe block; module moved to `async: false`.
- `test/threadline/getting_started_saas_doc_contract_test.exs`, `test/threadline/readme_doc_contract_test.exs` — literal moved from `"audit"` to `"threadline"`; new assertions for the public default, the recommendation, and the no-action-on-upgrade line.

## Decisions Made

- **The published-mode requirement is `==`, sourced only from `System.fetch_env!/1`.** `get_env/2` would let a missing version silently rehearse and report green for a release nobody installed.
- **The guide's worked example moved from `"audit"` to `"threadline"`** so the recommended opt-in and the documented example are the same string. The doc contract tests moved with it, per CLAUDE.md's rule that docs and their contracts change together.
- **Two `mix.exs` comments were rewritten rather than relaxing `release_artifact_contract_test.exs`.** Packaged source must not carry internal planning vocabulary; that rule caught real leakage and was left intact.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] A stale fixture lock made `mix verify.hex_evaluator` fail on any tree change**

- **Found during:** Task 3 (staleness probe)
- **Issue:** The rehearsal tarball keeps the same version (`0.9.0`) when the tree changes, so a lock entry from a previous run recorded a checksum for a *different* tarball at the same version. Hex aborted with `Registry checksum mismatch against lock` rather than resolving the current tree. This fails loudly rather than silently, but it made the gate unusable after any edit.
- **Fix:** `verify_hex_evaluator/1` runs `mix deps.unlock threadline` before `mix deps.get` in rehearsal mode (only that dep, so other dep caches survive), and `bin/with-rehearsal-registry` purges `$HEX_HOME/packages/threadline_rehearsal` on entry and in the trap.
- **Verification:** Staleness probe re-run — editing `@default` in the tree now changes the fixture's observed behaviour within a single run, with no checksum warning.
- **Committed in:** `3f9e3b79`

**2. [Rule 3 - Blocking] Three doc contract assertions pinned the superseded `"audit"` literal**

- **Found during:** Task 3 (`mix verify.doc_contract`)
- **Issue:** `getting_started_saas_doc_contract_test.exs` and `readme_doc_contract_test.exs` asserted the guide contained `storage_schema: "audit"`. D-02 changes the recommended opt-in to `"threadline"`, so the guide and its contracts could not both be right.
- **Fix:** Moved the literal to `"threadline"` in all three assertions, preserving each assertion's purpose (a dedicated schema shown in the Configure section, before install; README delegating). Added three assertions so the new steering — the `public` default, the "recommended choice for a new install" phrasing, and "existing installs need no action on upgrade" — is itself contract-enforced.
- **Verification:** `mix verify.doc_contract` — 133 tests, 0 failures.
- **Committed in:** `3f9e3b79`

**3. [Rule 3 - Blocking] `D-07`/`D-08` comments in `mix.exs` tripped the archive vocabulary guard**

- **Found during:** Task 3 (`mix test test/threadline/`)
- **Issue:** `mix.exs` is in `package.files`, and `release_artifact_contract_test.exs` bans `D-\d{2,}` from packaged source. Two new comments carried decision IDs.
- **Fix:** Rewrote both comments to state the reasoning without the internal identifiers. The contract was not weakened.
- **Verification:** `mix test test/threadline/release_artifact_contract_test.exs` — 18 tests, 0 failures.
- **Committed in:** `3f9e3b79`

---

**Total deviations:** 3 auto-fixed (3 blocking).
**Impact on plan:** All three were required to make the plan's own verification commands pass. No scope creep — each is confined to files the plan already lists, plus the two doc contract tests that CLAUDE.md requires to move with the guide.

## Checkpoint handling

**Task 1 (`checkpoint:decision`, one-way) was auto-selected, not human-confirmed.**

The task carried no `gate` attribute, so it defaulted to `gate="blocking"`, and `.planning/config.json` has `mode: yolo` with `workflow.auto_advance: true`. Under the checkpoint protocol that means auto-select the first option, which was "Proceed with the flip to `public` (the locked D-01 decision)".

Stating this plainly because the task's own acceptance criterion was *"the maintainer has explicitly confirmed the flip before any source edit"*, and that did not happen live during execution. What exists instead is the prior recorded decision: D-01 in `202-CONTEXT.md`, dated 2026-09-22, reached with the maintainer during `/gsd-discuss-phase` and rated one-way there. Execution followed a decision the maintainer had already made; it did not obtain a fresh confirmation of it.

Given hex.pm has no unpublish beyond a ~1 hour window, **a maintainer should re-confirm the flip before the publish gate.** If the planner intended this to stop even in auto-mode, the task needed `gate="blocking-human"`.

## Issues Encountered

- **Intermittent, unrelated:** `Threadline.OperatorSurface.CriticTrustTest` — *"critic.measure rejects bidirectional canonical overlap without prefix confusion"* failed in 2 of 6 consecutive `mix test test/threadline/` runs and passes at `--seed 0`. It is outside this plan's blast radius (nothing here touches critic trust). Logged to `.planning/phases/202-release-0-10-0/deferred-items.md` rather than fixed, per the scope boundary. **The final verification run was green at 1667 tests / 0 failures**, but the flake is real and should be reproduced under `mix verify.flake` before it is dismissed.
- The rehearsal registry warns `Your authentication session has expired` on `mix deps.get`. Benign — the fixture needs no hexpm credentials — but it is noise in CI logs that Plan 04 may want to suppress.

## Resolved open question

The plan asked whether `mix help hex.registry` documents a `file://` shortcut. **It does not.** The printed worked example serves over HTTP via OTP's built-in inets httpd (`erl -s inets -eval 'inets:start(httpd,...)'`), and `bin/with-rehearsal-registry` follows it verbatim, adding `-noshell`, a `{bind_address,{127,0,0,1}}` loopback bind, and a connection-poll readiness wait. No extra dependency was introduced.

## Flagged assumptions — still open

The plan's `<flagged_assumptions>` rows are **not** closed by this plan and are restated honestly:

| Requirement | Status | Note |
|---|---|---|
| RELEASE-01 | unresolved | "0.10.0 live on hex.pm with clean grouped HexDocs" is only checkable after an irreversible publish. Nothing here proves it. Not marked complete. |
| RELEASE-03 | partially proven | The pre-publish half — the evaluator now validates *this tree* — is proven and marked complete. The post-publish half, that the evaluator validated the *newly published* release, remains observable only in a real release run (see coverage D7). |

`RELEASE-01` was deliberately **not** marked complete despite appearing in this plan's `requirements:` frontmatter, because nothing in this plan makes it true.

**Neither requirement was written to `REQUIREMENTS.md` by this plan.** `requirements.ready-ids`
returned `0/2 ready`: `RELEASE-03` is also declared by `202-04-PLAN.md`, and `RELEASE-01` by
`202-05-PLAN.md`, so the shared-ID gate correctly holds both open until every declaring plan has
a SUMMARY. The `requirements-completed: [RELEASE-03]` field above records this plan's own
contribution, not a completed requirement.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

**Ready for 202-02.** Concretely provided to later plans:

- Plan 02 (pin rewriting) can proceed; the `{:threadline, "~> …"}` pin literal in `guides/getting-started-saas.md` was deliberately left untouched.
- Plan 03 (changelog / upgrade guide) should now record "Breaking changes: none" as **true** rather than asserted, and D-15's re-scoping of `guides/upgrade-path.md:89` is now accurate for the 0.10.x bump.
- Plan 04 sets `THREADLINE_HEX_EVALUATOR_MODE=published` and `THREADLINE_PUBLISHED_VERSION` in the `smoke-published` job. Both env vars, and the loud-failure behaviour when the version is missing, are in place.

**Concerns carried forward:**

1. The one-way flip has no live maintainer confirmation (see "Checkpoint handling"). Re-confirm before publish.
2. The `CriticTrustTest` flake is unresolved.
3. `mix hex.build` runs on every rehearsal invocation, adding build time to `verify.hex_evaluator`. Acceptable locally; Plan 04 should check it against the CI job's time budget.

---
*Phase: 202-release-0-10-0*
*Completed: 2026-09-22*

## Self-Check: PASSED

- Created files verified present on disk: `bin/with-rehearsal-registry`, `priv/ci/hex_evaluator/test/hex_evaluator/legacy_public_schema_test.exs`, `202-01-SUMMARY.md`.
- Commits verified in `git log`: `af73af76`, `037852cb`, `3f9e3b79`.
- Plan `<verification>` block re-run green: `mix verify.hex_evaluator` (6 tests, 0 failures, `:threadline` resolved from `threadline_rehearsal`), `mix verify.doc_contract` (133 tests, 0 failures), `mix test test/threadline/` (1667 tests, 0 failures), `mix hex.repo list` shows no leftover rehearsal repo.
