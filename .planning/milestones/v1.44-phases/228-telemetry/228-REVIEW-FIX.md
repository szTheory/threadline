---
phase: 228-telemetry
fixed_at: 2026-10-02T00:00:00Z
review_path: .planning/phases/228-telemetry/228-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 228: Code Review Fix Report

**Fixed at:** 2026-10-02
**Source review:** .planning/phases/228-telemetry/228-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 2 (fix_scope: critical_warning — WR-01, WR-02; IN-01 out of scope)
- Fixed: 2
- Skipped: 0

## Fixed Issues

### WR-01: `Threadline.Telemetry`'s own moduledoc asserts a guarantee its own event table contradicts

**Files modified:** `lib/threadline/telemetry.ex`
**Commit:** 58892345
**Applied fix:** Reworded the moduledoc's opening sentence to name the one
documented exemption (`[:threadline, :retention, :purge, :exception]`'s
`reason`/`stacktrace` metadata, forwarded for incident diagnosis) and point
to the Telemetry guide's "Keep row data out of your handlers" section,
matching the wording already in `guides/telemetry.md`. No code behavior
changed — documentation only. Verified by the existing
`telemetry_doc_contract_test.exs` doc-parity test (parses only the event
table, unaffected by the prose change) and a full re-read of the moduledoc.

### WR-02: `path` metadata on `[:threadline, :operator_surface, :authorize]` forwards the raw request path with no shape validation

**Files modified:** `lib/threadline/operator_surface/router.ex`,
`lib/threadline/operator_surface/theme_auth_plug.ex`,
`lib/threadline/telemetry.ex`,
`test/threadline/operator_surface/theme_auth_plug_test.exs`,
`test/threadline/telemetry_registry_contract_test.exs` (comment only),
`guides/telemetry.md`, `CHANGELOG.md`
**Commits:** 4340e264, 47da3586
**Applied fix:** Chose the "constrain" option from the review's two
alternatives (bound the value in code, not just document the exposure).
`threadline_operator_surface/2`'s router macro now threads its own
compile-time mount-path argument into `ThemeAuthPlug`'s opts as
`:theme_path` (e.g. `"/audit/theme"`, or for a host that nests the mount
under a dynamic segment, the un-substituted route template
`"/accounts/:account_id/audit/theme"`). `ThemeAuthPlug` forwards that static
string instead of `conn.request_path`.
`Threadline.Telemetry.emit_operator_surface_authorize/3`'s second argument
changed from "a `%Plug.Conn{}` or `nil`" to "a path string or `nil`" — the
function no longer reads `conn.request_path` itself, so there is no code
path left that can forward a live, possibly-identifying route segment. Added
a red-then-green test
(`theme_auth_plug_test.exs`: "path metadata is the plug's fixed :theme_path
option, never the live request path") that drives a request through
a dynamic `/accounts/42/audit/theme` path with `theme_path` set to the
un-substituted template and asserts the emitted `path` metadata is the
template, not `"42"`. Updated the existing four `theme_auth_plug_test.exs`
assertions to pass `theme_path: "/audit/theme"` in their opts (previously
derived implicitly from the real request path, now sourced from the option
the router macro now sets). Documented the bounded guarantee in
`guides/telemetry.md`'s cardinality section and added a `CHANGELOG.md`
"Fixed" entry, since the observable value of `path` changes for adopters who
mount under a dynamic router segment (unchanged for the documented canonical
`/audit` topology). `ExportAuthPlug` and `Auth.on_mount/4` are unaffected —
they already always pass `nil` (IN-01, out of scope for this run).

A full local `mix test` run after commit 4340e264 caught two real,
unanticipated regressions the targeted tests above did not cover:
`Threadline.ReleaseArtifactContractTest` failed because two new lib/
comments and one test description named the review finding id "(WR-02)" —
the repo's packaged-source guard rejects planning vocabulary in anything
that ships in the Hex tarball. Commit 47da3586 rewords those three spots to
stand on their own without the finding id, re-verified by re-running
`test/threadline/release_artifact_contract_test.exs` and
`test/threadline/operator_surface/theme_auth_plug_test.exs` (25/25 passing),
plus `mix compile --warnings-as-errors`, `mix format --check-formatted`, and
`mix verify.credo` again.

**Verification:** `mix compile --warnings-as-errors`, `mix format --check-formatted`,
`mix verify.credo`, and the touched test files
(`test/threadline/operator_surface/theme_auth_plug_test.exs`,
`test/threadline/telemetry_registry_contract_test.exs`,
`test/threadline/telemetry_doc_contract_test.exs`,
`test/threadline/operator_surface/router_test.exs`,
`test/threadline/operator_surface/auth_test.exs`,
`test/threadline/operator_surface/export_controller_telemetry_test.exs`,
`test/threadline/changelog_contract_test.exs`,
`test/threadline/release_artifact_contract_test.exs`) all pass with 0
failures. A full local `mix test` run was executed twice: once after commit
4340e264 (`31 properties, 2703 tests, 2 failures, 3 excluded` — both
failures in `ReleaseArtifactContractTest`, fixed by 47da3586) and once after
47da3586, confirming `31 properties, 2703 tests, 0 failures, 3 excluded`
(ran in the main checkout, per `workflow.use_worktrees: false`). Local run
only; no CI dispatch was requested or performed for this fix pass.

## Skipped Issues

None — both in-scope findings (WR-01, WR-02) were fixed. IN-01 is out of
scope for `fix_scope: critical_warning` and was not attempted.

---

_Fixed: 2026-10-02_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
