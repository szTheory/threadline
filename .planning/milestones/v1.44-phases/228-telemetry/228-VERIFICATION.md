---
phase: 228-telemetry
verified: 2026-10-02T15:30:00Z
status: passed
score: 7/7 must-haves verified
covered_files:
  - .planning/phases/228-telemetry/228-01-PLAN.md
  - .planning/phases/228-telemetry/228-01-SUMMARY.md
  - .planning/phases/228-telemetry/228-02-PLAN.md
  - .planning/phases/228-telemetry/228-02-SUMMARY.md
  - .planning/phases/228-telemetry/228-03-PLAN.md
  - .planning/phases/228-telemetry/228-03-SUMMARY.md
  - .planning/phases/228-telemetry/228-04-PLAN.md
  - .planning/phases/228-telemetry/228-04-SUMMARY.md
  - .planning/phases/228-telemetry/228-05-PLAN.md
  - .planning/phases/228-telemetry/228-05-SUMMARY.md
  - .planning/phases/228-telemetry/228-06-PLAN.md
  - .planning/phases/228-telemetry/228-06-SUMMARY.md
  - .planning/phases/228-telemetry/228-CONTEXT.md
  - .planning/phases/228-telemetry/228-EVIDENCE.md
  - .planning/phases/228-telemetry/228-REVIEW-FIX.md
  - .planning/phases/228-telemetry/228-REVIEW.md
  - .planning/phases/228-telemetry/evidence/SC5-local.md
  - .planning/phases/228-telemetry/evidence/TELE-03-mutation-telemetry-export-leak.md
  - .planning/phases/228-telemetry/evidence/TELE-03-mutation-unlisted-key.md
  - CHANGELOG.md
  - README.md
  - guides/operator-surface.md
  - guides/telemetry.md
  - lib/threadline/export.ex
  - lib/threadline/export/orchestrator.ex
  - lib/threadline/operator_surface/auth.ex
  - lib/threadline/operator_surface/controllers/export_controller.ex
  - lib/threadline/operator_surface/coverage/on_mount.ex
  - lib/threadline/operator_surface/export_auth_plug.ex
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/router.ex
  - lib/threadline/operator_surface/theme_auth_plug.ex
  - lib/threadline/retention.ex
  - lib/threadline/telemetry.ex
  - mix.exs
  - test/partition_weights.txt
  - test/threadline/capture/redaction_leak_property_test.exs
  - test/threadline/changelog_contract_test.exs
  - test/threadline/export/orchestrator_test.exs
  - test/threadline/export_test.exs
  - test/threadline/flake_classifier_contract_test.exs
  - test/threadline/guide_graph_contract_test.exs
  - test/threadline/operator_surface/auth_test.exs
  - test/threadline/operator_surface/export_auth_plug_test.exs
  - test/threadline/operator_surface/export_controller_telemetry_test.exs
  - test/threadline/operator_surface/exports_doc_contract_test.exs
  - test/threadline/operator_surface/theme_auth_plug_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/release_artifact_contract_test.exs
  - test/threadline/retention_test.exs
  - test/threadline/telemetry_doc_contract_test.exs
  - test/threadline/telemetry_raising_handler_test.exs
  - test/threadline/telemetry_registry_contract_test.exs
  - test/threadline/telemetry_repo_query_recipe_test.exs
  - test/threadline/telemetry_test.exs
covered_digest: "v2:sha256:d918e15bddc04d72670bcd12d358397c3af51c981591d5dd39639d2cd299c263"
overrides_applied: 0
behavior_unverified: 0
---

# Phase 228: Telemetry Verification Report

**Phase Goal:** An operator can observe export and retention runs through documented `[:threadline, ...]` events, and a compliance reviewer can confirm those events never carry audited data (ROADMAP.md Phase 228 SC1-SC5).
**Verified:** 2026-10-02
**Status:** passed
**Re-verification:** No — initial verification

## Note on evidence timing (code-review fixes vs. cited CI run)

228-EVIDENCE.md's CI before/after figures cite run `37018812221` (headSha
`7dae7e49`, confirmed live via `gh run view 37018812221` — conclusion
`success`). That run predates the three post-review-fix commits
(`58892345` WR-01 moduledoc wording, `4340e264` WR-02 static `:theme_path`,
`47da3586` WR-02 packaged-source wording) — `git log 7dae7e49..HEAD` shows
all three commits strictly after the cited CI head. This is disclosed
honestly rather than silently accepted:

- **SC5 wall-clock figures remain a valid basis.** The fix diff is a
  moduledoc prose change, a compile-time macro argument threaded through
  the router, and a plug option substitution — no new DB property, no new
  Mix-task event, no loop/IO cost added. `evidence/SC5-local.md`'s own-cost
  table already shows the telemetry suite's added cost (~3.4s) is an order
  of magnitude under the documented local noise floor, so a three-commit
  doc/plug-option diff cannot plausibly move the wall-clock conclusion.
- **Functional correctness evidence was independently re-verified against
  current HEAD** (below), not just inherited from the pre-fix CI run or
  228-REVIEW-FIX.md's own narrative. I re-ran the touched and cited test
  files myself after the fix commits landed:
  `mix test test/threadline/operator_surface/theme_auth_plug_test.exs
  test/threadline/telemetry_registry_contract_test.exs
  test/threadline/telemetry_doc_contract_test.exs
  test/threadline/release_artifact_contract_test.exs` → 32 tests, 0
  failures. `mix test test/threadline/export_test.exs
  test/threadline/export/orchestrator_test.exs
  test/threadline/operator_surface/export_controller_telemetry_test.exs
  test/threadline/retention_test.exs` → 66 tests, 0 failures. `mix test
  test/threadline/capture/redaction_leak_property_test.exs
  test/threadline/telemetry_raising_handler_test.exs
  test/threadline/telemetry_repo_query_recipe_test.exs
  test/threadline/guide_graph_contract_test.exs
  test/threadline/operator_surface/auth_test.exs
  test/threadline/changelog_contract_test.exs` → 1 property, 55 tests, 0
  failures. `mix compile --warnings-as-errors` and `mix format
  --check-formatted` both exit 0 at HEAD.
- 228-EVIDENCE.md and 228-REVIEW-FIX.md are themselves honest about this —
  REVIEW-FIX.md records its own local re-run after the fix commits (`31
  properties, 2703 tests, 0 failures, 3 excluded`) and does not claim a
  fresh CI dispatch. No gap is raised on this basis; the fix pass's own
  local evidence plus my independent re-run at HEAD both corroborate it.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1 — attached handler receives `[:threadline, :export, :completed\|:failed]` with row count, duration, format, after export finishes, both branches tested | ✓ VERIFIED | `lib/threadline/export.ex:100,111,164,180`, `lib/threadline/export/orchestrator.ex` (6 call sites across all failure/success branches), `lib/threadline/operator_surface/controllers/export_controller.ex:271,274,281` all call `Telemetry.emit_export_completed/4` or `emit_export_failed/5`. Re-ran `test/threadline/export_test.exs`, `test/threadline/export/orchestrator_test.exs`, `test/threadline/operator_surface/export_controller_telemetry_test.exs` at HEAD: 0 failures. |
| 2 | SC2 — attached handler receives `[:threadline, :retention, :purge, :start\|:stop\|:exception]` span and one `batch_purged` per batch with rows deleted; exception path forced by a test | ✓ VERIFIED | `lib/threadline/retention.ex:72` wraps the run in `Threadline.Telemetry.purge_span/2`; registry (moduledoc table) lists `batch_purged` with `deleted_changes, deleted_transactions, duration`. Re-ran `test/threadline/retention_test.exs` at HEAD: 0 failures, including the exception-path test against a missing storage schema on the real DB (D-11). |
| 3 | SC3 — allowlist test pins every event's keys and reds on an unlisted key; PROP-04 handler never observes plaintext; raising handler doesn't break export/purge | ✓ VERIFIED | `test/threadline/telemetry_registry_contract_test.exs` drives all 14 registry events and asserts key-set + value-type equality; static scan confirmed independently (`grep -rn ":telemetry\.\(execute\|span\)(" lib/` outside `telemetry.ex` → no matches). Two multi-seed mutation controls filed in `evidence/TELE-03-mutation-*.md`, kill rate 5/5 each, reviewed diff/output directly — both are real, non-fabricated patches against real code lines. `test/threadline/telemetry_raising_handler_test.exs` and the redaction property re-run at HEAD: 0 failures. |
| 4 | SC4 — moduledoc table and `guides/telemetry.md` list every event; guide includes the `[:my_app, :repo, :query]` recipe; a test derives the doc list from `__events__/0` | ✓ VERIFIED | `lib/threadline/telemetry.ex` moduledoc table (14 rows) read directly; `guides/telemetry.md` (271 lines, sections: Events, Attaching handlers, Metrics, Handlers-must-not-raise, Cardinality, Keep row data out, Observing Threadline's queries, Next steps) read directly. `test/threadline/telemetry_doc_contract_test.exs` and `test/threadline/telemetry_repo_query_recipe_test.exs` re-run at HEAD: part of the 0-failures group above. |
| 5 | SC5 — no `[:threadline, :query, ...]` or Mix-task event added; VERIFICATION.md reports suite wall clock before/after | ✓ VERIFIED | Full registry name list (14 names, none containing `:query`) independently re-derived by reading the moduledoc table; `grep -rn ":telemetry" lib/mix/` → no matches (confirmed live, exit 1). Wall clock: see 228-EVIDENCE.md / `evidence/SC5-local.md` (local: base median 213.7s → head median 219.0s, within documented local-noise floor; CI: proxy-min total unchanged at 14 across before/after runs — see "Note on evidence timing" above for why this basis still holds post-fix). |
| 6 | Operator-surface identity fields (`actor_ref`, `session_actor_ref`, `scope_actor_ref`) removed from `:authorize`/`:export_authorize`/`:actor_ref_mismatch` metadata (D-17, TELE-03) | ✓ VERIFIED | `lib/threadline/operator_surface/auth.ex:152` `emit_actor_mismatch/2` discards both args (`_session_actor_ref`, `_scope_actor_ref`) before calling the telemetry helper; moduledoc table shows `:actor_ref_mismatch` metadata as `—` (empty) and `:authorize` metadata as `path, scope_keys` only. |
| 7 | WR-02 fix: `:authorize` event's `path` metadata is bound to the static mount route, not the live dynamic request path | ✓ VERIFIED | `lib/threadline/operator_surface/router.ex:103-112` threads the macro's own compile-time path into `:theme_path`; `theme_auth_plug.ex:75-80` forwards that option instead of `conn.request_path`; `telemetry.ex` helper signature takes a path string, not a `%Plug.Conn{}`. New test in `theme_auth_plug_test.exs` ("path metadata is the plug's fixed `:theme_path` option, never the live request path") drives a dynamic `/accounts/:account_id/audit/theme` request and asserts the un-substituted template is emitted. Re-ran at HEAD: passes. |

**Score:** 7/7 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/threadline/telemetry.ex` | Registry, `__events__/0`, all 14 helpers, moduledoc table | ✓ VERIFIED | Read directly; moduledoc table has 14 rows matching the EVIDENCE.md registry dump; `emit_export_completed/4-5`, `emit_export_failed/5`, `purge_span/2`, `emit_health_checked_error/1`, `emit_operator_surface_authorize/3` all present |
| `lib/threadline/export.ex`, `export/orchestrator.ex` | Export emission at eager + async entry points | ✓ VERIFIED | Call sites confirmed via grep, outside any `Repo.transaction` |
| `lib/threadline/operator_surface/controllers/export_controller.ex` | Chunked-download emission | ✓ VERIFIED | 3 call sites after `reduce_while` |
| `lib/threadline/retention.ex` | Purge span wraps dry-run/real-run branch | ✓ VERIFIED | `purge_span(span_dry_run?, fn -> ... end)` at line 72 |
| `guides/telemetry.md` | ExDoc extra, 8 sections per D-16 order | ✓ VERIFIED | File exists, 271 lines, section headers match D-16 exactly |
| `test/threadline/telemetry_registry_contract_test.exs` | Allowlist + static-scan test | ✓ VERIFIED | Re-run, passing |
| `evidence/TELE-03-mutation-*.md` | Two filed mutation-control diffs, kill rate 5/5 | ✓ VERIFIED | Both files read; real diffs against `lib/threadline/export.ex` and the registry; summaries match the diffs shown |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `lib/threadline/export.ex` / `orchestrator.ex` / `export_controller.ex` | `lib/threadline/telemetry.ex` | `Threadline.Telemetry.emit_export_completed/failed` calls | WIRED | Confirmed via grep at every call site |
| `lib/threadline/retention.ex` | `lib/threadline/telemetry.ex` | `Threadline.Telemetry.purge_span/2` | WIRED | Confirmed at line 72 |
| `lib/threadline/operator_surface/router.ex` → `theme_auth_plug.ex` → `telemetry.ex` | path metadata | `:theme_path` opt threaded at compile time | WIRED | Confirmed in router.ex, theme_auth_plug.ex, and the new dynamic-segment test |
| `guides/telemetry.md` / moduledoc table | `Threadline.Telemetry.__events__/0` | doc-parity test | WIRED | `test/threadline/telemetry_doc_contract_test.exs` re-run, passing |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|-----------------|--------------|--------|----------|
| TELE-01 | 228-02, 228-06 | Export `:completed`/`:failed` with row count, duration, format | ✓ SATISFIED | Truth 1 |
| TELE-02 | 228-03, 228-06 | Retention purge span + `batch_purged` | ✓ SATISFIED | Truth 2 |
| TELE-03 | 228-01, 228-02, 228-03, 228-04, 228-06 | No event carries row values, actor identifiers, correlation ids, free-text reasons | ✓ SATISFIED | Truths 3, 6, 7 |
| TELE-04 | 228-05, 228-06 | Documented in moduledoc + guide, repo-query recipe | ✓ SATISFIED | Truth 4 |

No orphaned requirements: REQUIREMENTS.md maps exactly TELE-01..04 to Phase 228, and all four appear in at least one plan's `requirements:` frontmatter.

### Anti-Patterns Found

Scanned all `lib/` files touched by this phase (`telemetry.ex`, `export.ex`, `export/orchestrator.ex`, `retention.ex`, `operator_surface/auth.ex`, `theme_auth_plug.ex`, `export_auth_plug.ex`, `router.ex`, `controllers/export_controller.ex`, `coverage/on_mount.ex`, `live/coverage_live.ex`) for `TODO|HACK|PLACEHOLDER|TBD|FIXME|XXX|not yet implemented|coming soon`.

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `export_controller.ex` | 80 | `"Export download is not available"` | none | User-facing 404 message string, not a stub marker |

No debt markers found. No blockers.

### Code Review Findings — Disposition

`228-REVIEW.md` found 2 warnings (WR-01, WR-02) and 1 info (IN-01, out of scope for the fix pass). `228-REVIEW-FIX.md` claims both warnings fixed in commits `58892345`, `4340e264`, `47da3586`. Independently confirmed at HEAD:

- WR-01: `lib/threadline/telemetry.ex` moduledoc opening sentence now names the `[:threadline, :retention, :purge, :exception]` `reason`/`stacktrace` exemption inline (read directly, lines 5-13).
- WR-02: `router.ex`/`theme_auth_plug.ex`/`telemetry.ex` now thread a static compile-time `:theme_path` instead of `conn.request_path`; a red-then-green dynamic-segment test exists and passes at HEAD.
- The fix pass's own follow-up (`47da3586`) correctly caught and fixed a `release_artifact_contract_test.exs` regression from packaged-source finding-id references; re-confirmed clean at HEAD via `grep -n "WR-02" lib/ test/` → no matches in shipped files.
- IN-01 remains open (explicitly out of scope, not a TELE-03 violation — `ExportAuthPlug`/`Auth.on_mount/4` already pass `nil`, which is the safe default, not a leak).

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Export telemetry round-trip | `mix test test/threadline/export_test.exs test/threadline/export/orchestrator_test.exs test/threadline/operator_surface/export_controller_telemetry_test.exs test/threadline/retention_test.exs` | 66 tests, 0 failures | ✓ PASS |
| Registry allowlist + static scan + redaction observer + raising handler + guide parity | `mix test test/threadline/capture/redaction_leak_property_test.exs test/threadline/telemetry_raising_handler_test.exs test/threadline/telemetry_repo_query_recipe_test.exs test/threadline/guide_graph_contract_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/changelog_contract_test.exs` | 1 property, 55 tests, 0 failures | ✓ PASS |
| WR fixes (post-review-fix regression check) | `mix test test/threadline/operator_surface/theme_auth_plug_test.exs test/threadline/telemetry_registry_contract_test.exs test/threadline/telemetry_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs` | 32 tests, 0 failures | ✓ PASS |
| No stray `:telemetry.execute`/`:telemetry.span` outside `telemetry.ex` | `grep -rn ":telemetry\.\(execute\|span\)(" lib/ --include="*.ex" \| grep -v "lib/threadline/telemetry.ex"` | no matches | ✓ PASS |
| No Mix-task telemetry reference | `grep -rn ":telemetry" lib/mix/` | no matches (exit 1) | ✓ PASS |
| Compile / format clean at HEAD | `mix compile --warnings-as-errors`, `mix format --check-formatted` | both exit 0 | ✓ PASS |
| CI run cited in evidence is real | `gh run view 37018812221 --json conclusion,headSha,status` (read-only) | `conclusion: success, headSha: 7dae7e49, status: completed` | ✓ PASS |

A full-suite `mix test` re-run was attempted for extra corroboration but stalled under this machine's shared-Postgres contention with an unrelated concurrent `mix test` process; it was killed cleanly (no stray processes or uncommitted artifacts left — confirmed via `ps aux` and `git status --porcelain`). This does not weaken the verdict: every SC-relevant test file was independently re-run above with 0 failures, matching 228-REVIEW-FIX.md's own independent full-suite claim (`31 properties, 2703 tests, 0 failures, 3 excluded`).

### Human Verification Required

None. All must-haves verified programmatically; no visual, real-time, or external-service behavior in this phase's scope.

### Gaps Summary

None. All 7 observable truths verified, all 4 requirements satisfied, both code-review warnings confirmed fixed at HEAD, CI-run/fix-commit timing discrepancy disclosed and shown not to invalidate the cited evidence.

---

_Verified: 2026-10-02_
_Verifier: Claude (gsd-verifier)_
