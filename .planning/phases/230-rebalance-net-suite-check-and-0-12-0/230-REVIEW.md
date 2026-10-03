---
phase: 230-rebalance-net-suite-check-and-0-12-0
reviewed: 2026-10-02T00:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - CHANGELOG.md
  - CONTRIBUTING.md
  - guides/upgrade-path.md
  - lib/threadline/health.ex
  - lib/threadline/health/coverage_schemas.ex
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/live/evidence_live.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/operator_surface/stress_fixtures.ex
  - lib/threadline/operator_surface/ui/page.ex
  - test/partition_weights.txt
  - test/threadline/brandbook_token_parity_test.exs
  - test/threadline/operator_surface/coverage_doc_contract_test.exs
  - test/threadline/operator_surface/policy_show_doc_contract_test.exs
  - test/threadline/operator_surface_doc_contract_test.exs
  - test/threadline/support_playbook_doc_contract_test.exs
findings:
  critical: 0
  warning: 0
  info: 1
  total: 1
status: issues_found
---

# Phase 230: Code Review Report

**Reviewed:** 2026-10-02
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found (info only)

## Summary

This phase (1) deletes two doc-contract test files (`stg_doc_contract_test.exs`,
`operator_surface/theme_doc_contract_test.exs`) whose only assertions were
hand-typed-literal-vs-prose checks, matching the new CONTRIBUTING.md "keep vs.
cut" convention; (2) trims three mixed doc-contract files
(`coverage_doc_contract_test.exs`, `policy_show_doc_contract_test.exs`,
`operator_surface_doc_contract_test.exs`) down to live-source-derived and
security-boundary assertions; (3) scrubs stale planning-ID tokens (`HLTH-02`,
`197-02`, `196-06`, `196-05`, `T-211-14`, `T-175-09`) from `lib/` comments and
one `@doc`; and (4) adds the 0.12.0 CHANGELOG entry and upgrade-path row.

Verification performed:
- Diffed every file against `8f16361e^..HEAD` individually (not just the
  aggregate diff) to confirm scope.
- Confirmed both deleted test files contained only `File.read!` +
  `String.contains?`/`refute` prose-literal checks with no derivation from
  live source, generated output, or `git ls-files` — correctly cut per the
  new CONTRIBUTING.md criteria.
- Confirmed `test/partition_weights.txt` has no dangling entries for either
  deleted file, and no other file in the tree (excluding `.planning/`)
  references either deleted module or path.
- Confirmed the retained auth/fail-closed/export-auth assertions in
  `operator_surface_doc_contract_test.exs` are intact: fail-closed posture,
  `:adopter_acknowledges_unauthenticated: true`, `admin_auth` pipeline,
  `export_authorize_fn`, "LiveView pages only" / HTTP-export-auth-remains-
  authoritative boundary language — none of these were dropped, only the
  surrounding non-derived prose-literal assertions around them.
- Confirmed `coverage_doc_contract_test.exs` retains the SQL-injection
  refutes (`health.ex`, `coverage_live.ex`, the mix task, `verify_coverage`)
  and the `String.to_atom` atom-leak refutes across the same three files —
  none of the security-boundary checks were cut, only guide-prose-literal
  tests.
- Confirmed no now-unused helper/attribute lingers after trimming: the
  `guide_section/2` private helper in `coverage_doc_contract_test.exs` was
  removed along with its only callers; `@domain_reference_path` in
  `policy_show_doc_contract_test.exs` was removed along with its only user.
  `mix format --check-formatted` reports no diff for any of the three edited
  test files.
- Confirmed the `lib/` diff is comment/`@doc`-text-only in every hunk (no
  code, pattern, or logic changed) across `health.ex`, `coverage_schemas.ex`,
  `coverage_live.ex`, `evidence_live.ex`, `transaction_live.ex`,
  `stress_fixtures.ex`, and `ui/page.ex`.
- Spot-checked the 0.12.0 CHANGELOG/upgrade-path additions against the three
  breaking-change descriptions (exclude/mask non-list raise, telemetry
  actor-ref key removal, health-checked-error exception metadata) — content
  is internally consistent between `CHANGELOG.md` and `guides/upgrade-path.md`
  and matches the committed phase-229 work these docs describe.

No bugs, security issues, or lost assertions found. One minor
convention-consistency note below.

## Info

### IN-01: Rationale comment placed outside `@moduledoc` in a file using `@moduledoc false`

**File:** `test/threadline/operator_surface_doc_contract_test.exs:1-6`
**Issue:** The new keep/cut rationale ("KEEP 1: the install pin derives from
Mix.Tasks.Release.Pins... KEEP 2: ...") is written as a plain module comment
above `@moduledoc false`, whereas the sibling files touched in this same phase
(`coverage_doc_contract_test.exs`, `policy_show_doc_contract_test.exs`) put
the equivalent rationale inside a real `@moduledoc "..."` string, matching
CONTRIBUTING.md's stated convention ("every new `*_contract_test.exs`
moduledoc names, in one sentence, which keep criterion above it satisfies").
Since `@moduledoc false` suppresses ExDoc/doc tooling visibility, this file's
rationale is only discoverable by opening the source, unlike the other two.
This is pre-existing style (the file already used `@moduledoc false` before
this phase) and the convention technically only binds *new* files, so this is
not a defect — just an inconsistency worth normalizing next time this file is
touched.
**Fix:** Change `@moduledoc false` to a real moduledoc string carrying the
KEEP rationale, mirroring `coverage_doc_contract_test.exs`'s pattern, e.g.:
```elixir
defmodule Threadline.OperatorSurfaceDocContractTest do
  @moduledoc """
  KEEP 1: the install pin derives from Mix.Tasks.Release.Pins, the designated
  sole writer of every documented install pin. KEEP 2: the remaining
  sentences pin the auth / fail-closed / export-auth security boundary — a
  security exception to the ordinary CUT shape (prose-to-literal checks are
  cut everywhere else in this file).
  """
  use ExUnit.Case, async: true
  ...
```

---

_Reviewed: 2026-10-02_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
