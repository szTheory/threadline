---
phase: 198-green-bringup
reviewed: 2026-09-10T22:29:46Z
depth: standard
files_reviewed: 109
files_reviewed_list:
  - .github/rulesets/main.json
  - .github/workflows/branch-protection.yml
  - .github/workflows/browser-full.yml
  - .github/workflows/ci.yml
  - .github/workflows/flake-detection.yml
  - .github/workflows/release.yml
  - CONTRIBUTING.md
  - bin/classify-flake-run
  - bin/compare-required-contexts
  - bin/observe-main-ci
  - bin/record-ci-attestation
  - bin/upsert-ci-issue
  - bin/verify-branch-protection
  - bin/verify-phase198-evidence
  - bin/verify-playwright-fail-fast
  - config/test.exs
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - examples/threadline_phoenix/e2e/run-e2e.sh
  - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-177-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-tier-a-capture.spec.ts
  - examples/threadline_phoenix/e2e/tests/register.spec.ts
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex
  - examples/threadline_phoenix/test/support/walkthrough_case.ex
  - examples/threadline_phoenix/test/threadline_phoenix/demo/advisory_lock_pinning_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/demo/retention_tail_env_contract_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs
  - lib/threadline/operator_surface/controllers/theme_controller.ex
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/live/evidence_live.ex
  - lib/threadline/operator_surface/live/export_status_live.ex
  - lib/threadline/operator_surface/live/policy_redaction_live.ex
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/row_history_live.ex
  - lib/threadline/operator_surface/live/start_live.ex
  - lib/threadline/operator_surface/live/stress_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/operator_surface/presentation.ex
  - lib/threadline/operator_surface/ui.ex
  - mix.exs
  - test/mix/tasks/threadline.evidence_show_test.exs
  - test/mix/tasks/threadline.incident_test.exs
  - test/mix/tasks/threadline/export_test.exs
  - test/support/storage_schema_case.ex
  - test/test_helper.exs
  - test/threadline/branch_protection_comparison_contract_test.exs
  - test/threadline/capture/trigger_changed_from_test.exs
  - test/threadline/capture/trigger_context_test.exs
  - test/threadline/capture/trigger_redaction_test.exs
  - test/threadline/capture/trigger_test.exs
  - test/threadline/ci_attestation_contract_test.exs
  - test/threadline/ci_coverage_doc_contract_test.exs
  - test/threadline/ci_issue_upsert_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/e2e_preflight_contract_test.exs
  - test/threadline/evidence/proof_test.exs
  - test/threadline/flake_classifier_contract_test.exs
  - test/threadline/governance/evidence_record_test.exs
  - test/threadline/idle_transaction_reaper_contract_test.exs
  - test/threadline/main_ci_observer_contract_test.exs
  - test/threadline/operator_surface/breadcrumb_test.exs
  - test/threadline/operator_surface/component_contract_test.exs
  - test/threadline/operator_surface/copy_contract_test.exs
  - test/threadline/operator_surface/exports_mix_parity_test.exs
  - test/threadline/operator_surface/live/actor_live_test.exs
  - test/threadline/operator_surface/live/export_status_live_test.exs
  - test/threadline/operator_surface/live/row_history_live_test.exs
  - test/threadline/operator_surface/mechanical_checker_test.exs
  - test/threadline/operator_surface/policy_show_mix_test.exs
  - test/threadline/operator_surface/presentation_test.exs
  - test/threadline/operator_surface/row_history_component_test.exs
  - test/threadline/operator_surface/stress_ledger_test.exs
  - test/threadline/operator_surface/stress_router_test.exs
  - test/threadline/operator_surface/transaction_live_test.exs
  - test/threadline/operator_surface/ui_form_policy_contract_test.exs
  - test/threadline/optional_deps_contract_test.exs
  - test/threadline/pgbouncer_topology_test.exs
  - test/threadline/phase06_nyquist_ci_contract_test.exs
  - test/threadline/phase198_automation_policy_test.exs
  - test/threadline/phase198_decision_attestation_test.exs
  - test/threadline/phase198_nyquist_contract_test.exs
  - test/threadline/phase198_zero_human_uat_contract_test.exs
  - test/threadline/playwright_fail_fast_contract_test.exs
  - test/threadline/release_ci_gate_contract_test.exs
  - test/threadline/release_control_plane_contract_test.exs
  - test/threadline/storage_schema_call_site_contract_test.exs
  - test/threadline/storage_schema_prefix_contract_test.exs
  - test/threadline/zero_skips_contract_test.exs
  - test/threadline/phase198_prohibition_resolution_contract_test.exs
  - .planning/audits/198-summary-coverage-manifest.json
  - .planning/audits/198-round14-security-disposition.json
  - .planning/audits/198-round15-security-authorization.txt
  - .planning/audits/198-round15-security-disposition.json
findings:
  critical: 5
  warning: 3
  info: 0
  total: 8
status: issues_found
---

# Phase 198: Code Review Report

**Reviewed:** 2026-09-09T15:18:49Z
**Depth:** standard
**Files Reviewed:** 104
**Status:** issues_found

## Summary

The submitted CI and evidence changes contain two failures that make the new required test lane non-portable to the clean GitHub-hosted runner it is intended to gate. A browser preflight also accepts an unrelated cross-origin redirect as proof that the operator route is correctly mounted. Shell syntax checks passed; the targeted Mix tests could not be executed in this workspace because no Mix version is configured for the active tool manager.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Required test suite depends on an uninstalled developer-global GSD executable

**File:** `/Users/jon/projects/threadline/test/threadline/phase198_zero_human_uat_contract_test.exs:58-75`

**Issue:** `classifier_command!/0` requires either a `gsd-tools` executable on `PATH` or `~/.codex/gsd-core/bin/gsd-tools.cjs`. Neither artifact belongs to this repository or is installed by `verify-test` in `.github/workflows/ci.yml`. A clean GitHub-hosted runner therefore raises at line 71 before performing an assertion. Since this file is included by the ordinary `mix verify.test` alias, both required test-matrix jobs can fail based on a maintainer's local Codex installation rather than the submitted code. It also lets local results vary as the global GSD installation changes.

**Fix:** Vendor the exact classifier implementation/version used by the contract into the repository and invoke that committed path, or replace this test with project-owned parsing logic. For example:

```elixir
@classifier Path.expand("../../bin/classify-uat-coverage", __DIR__)

defp classifier_command! do
  assert File.regular?(@classifier), "committed coverage classifier is missing"
  {@classifier, []}
end
```

### CR-02: Archive-tag contract cannot pass under CI's shallow checkout

**File:** `/Users/jon/projects/threadline/test/threadline/phase198_nyquist_contract_test.exs:88-103`

**Issue:** The test resolves every `archive/*` tag with `git rev-parse` and `git cat-file`, but every checkout in the required `verify-test` job uses the default `actions/checkout` depth. That default fetches a single commit and does not provide the repository's annotated tag objects. On a clean runner, the pattern match `{object, 0}` fails as soon as the first archive tag is absent, independently of whether the archive register is correct. Release jobs explicitly use `fetch-depth: 0`, demonstrating that the repository already accounts for this checkout behavior elsewhere, but the CI test matrix does not.

**Fix:** Fetch tag history in the `verify-test` checkout (or in a dedicated archive-contract job) before running this test:

```yaml
- uses: actions/checkout@v5
  with:
    fetch-depth: 0
```

If the full history cost is unwanted, explicitly fetch the registered tag refs and their peeled objects before the assertion.

## Warnings

### WR-01: Operator preflight accepts a cross-origin redirect as a valid auth mount

**File:** `/Users/jon/projects/threadline/examples/threadline_phoenix/e2e/run-e2e.sh:79-92`

**Issue:** The 3xx branch checks only whether the raw `Location` value contains `/users/log_in`. A response such as `Location: https://unrelated.example/users/log_in` therefore passes, even though it proves neither the example application's auth pipeline nor a valid local login route. This weakens the fail-fast check precisely on the routing/misconfiguration path it was added to detect.

**Fix:** Accept only a relative local login target, or parse an absolute target and require its origin to equal `BASE_URL` before checking the path. For the current Phoenix redirect contract, a strict shell check is sufficient:

```bash
case "$location" in
  /users/log_in|/users/log_in\?*) return 0 ;;
  *) return 1 ;;
esac
```

---

_Reviewed: 2026-09-09T15:18:49Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_

## Plan 64 Delta Review

**Reviewed:** 2026-09-10T21:06:56Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

### Delta Summary

The Plan 64 artifact is narrowly scoped and its decoded-value mutation matrix passes (13 tests, 0 failures), but the accepted-risk record is not attributable to an identifiable maintainer. The parser also permits duplicate JSON members that can be interpreted differently by downstream consumers. Two additional test gaps weaken the claimed timestamp provenance and immutable supersession history.

### Critical Issues

### CR-03: Placeholder text is persisted as the maintainer identity

**Classification:** BLOCKER
**File:** `/Users/jon/projects/threadline/.planning/audits/198-round14-security-disposition.json:6-7`

**Issue:** The security disposition records `YOUR_NAME` as both the signer and the signer embedded in the verbatim response. `YOUR_NAME` is template text, not an identifiable maintainer identity. The test then hard-codes that same placeholder at `phase198_prohibition_resolution_contract_test.exs:11,57,403`, so it positively certifies the attribution defect instead of detecting it. This leaves Plan 64's high-severity spoofing threat unmitigated and makes the accepted-risk audit entry non-attributable.

**Fix:** Obtain a new explicit acceptance containing the maintainer's actual chosen identity, preserve that response verbatim, and update `decided_by` and the test constants to that exact identity. Do not infer or silently substitute an identity.

### CR-04: Duplicate JSON members bypass the exact-schema boundary

**Classification:** BLOCKER
**File:** `/Users/jon/projects/threadline/test/threadline/phase198_prohibition_resolution_contract_test.exs:372-386`

**Issue:** `load_disposition!/0` decodes directly into a map before validation. Duplicate object members are therefore collapsed before the exact-key comparison runs. With the repository's Jason version, a document containing a canonical member followed by a conflicting duplicate can decode to the canonical first value and pass this suite; consumers with last-value semantics can observe the conflicting value instead. This permits parser-differential ambiguity for security-sensitive fields such as `decision`, `threat_id`, `accepted_scope`, and nested `green_07` while the contract claims an exact, fail-closed object shape.

**Fix:** Decode with `objects: :ordered_objects`, recursively reject duplicate member names at every object level, and only then convert to maps for canonical-value validation. Add fixtures with conflicting duplicate root and nested members in both orders.

### Warnings

### WR-02: Timestamp validation proves syntax but not decision-time provenance

**Classification:** WARNING
**File:** `/Users/jon/projects/threadline/test/threadline/phase198_prohibition_resolution_contract_test.exs:115-133`

**Issue:** The validator accepts any real seconds-resolution UTC timestamp. It does not prove that `decided_at` was recorded during Plan 64 execution, so a syntactically valid date from years before the decision or far in the future passes despite the plan's explicit execution-time requirement. The current value is plausible, but the contract cannot detect later timestamp substitution.

**Fix:** Bind `decided_at` to trusted execution boundaries—for example, require it to fall between the recorded Plan 64 start/completion instants and not after the artifact commit time—and add past/future valid-RFC3339 mutation cases.

### WR-03: Substring checks do not prove Plan 63 remained immutable

**Classification:** WARNING
**File:** `/Users/jon/projects/threadline/test/threadline/phase198_prohibition_resolution_contract_test.exs:178-184`

**Issue:** The supersession test checks only that three substrings occur somewhere in the Plan 63 summary. A rewritten summary can retain `status: halted`, `coverage: []`, and the quoted response while altering attribution, scope, chronology, or other decision history, and the test will still pass. That is weaker than the claimed immutable-decision-supersession guarantee.

**Fix:** Pin the Plan 63 summary to its known commit/blob identity or SHA-256 and compare the complete bytes. If semantic validation is also desired, parse the frontmatter and assert the relevant fields rather than searching the whole document for unanchored substrings.

---

_Plan 64 delta reviewed: 2026-09-10T21:06:56Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_

## Plan 65 Delta Review

**Reviewed:** 2026-09-10T21:38:12Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** clean delta; prior Phase 198 findings remain preserved above

### Delta Summary

Plan 65 resolves all four Plan 64 delta findings without rewriting the rejected v1 record or earlier decision history. The independently rerun focused suite reports 19 tests and zero failures. No new blocker or warning was found in the Plan 65 delta.

### Resolution Assessment

#### CR-03: RESOLVED — attribution no longer uses placeholder text

The new authorization is exactly one UTF-8 line naming `szTheory`, and the v2 disposition derives the same signer and verbatim response from authorization commit `5f77f321bc90c0add078ea083c06d5add575ae25`. That commit resolves the authorization path to blob `4173c528fd26c46b7217650fafa6e851334f367c` and SHA-256 `183c98eb9b0529867ac6231e870aacaea93397f4488dd28cfe93aa32a97686d6`. The rejected `YOUR_NAME` record remains append-only history and is explicitly pinned as `plan64-invalid-disposition` rather than reused as authority.

#### CR-04: RESOLVED — duplicate members fail before map conversion

`decode_unique_ordered_json/1` asks Jason for `Jason.OrderedObject` values, recursively visits ordered objects and lists, rejects repeated decoded member names, and calls `ordered_to_plain/1` only after the complete tree passes. Fixtures exercise malicious-first and malicious-last duplicates for root security fields, `green_07`, `authorization_source`, `decision_time_bounds`, and every object in `supersedes`; each must return the duplicate-specific error.

#### WR-02: RESOLVED — decision time is commit-derived and bounded

`decided_at` and `authorization_committed_at` equal the normalized committer time of the pinned authorization commit. The test resolves both timestamps from Git, proves plan-origin → authorization → first disposition commit ancestry, and enforces origin time < authorization time <= disposition commit time.

#### WR-03: RESOLVED — superseded history is pinned by complete immutable bytes

The v2 record pins the complete Plan 63 plan and decline plus the relevant Plan 64 plan, rejected disposition, summary, and rejecting security audit by exact path, commit, blob, and SHA-256. Validation reads `commit:path` blob bytes and checks every pin and ordered row, so the old substring checks are no longer the trust basis for supersession history.

### Additional Boundary Checks

- Exact authorization bytes, Unicode punctuation, signer, rationale, scope, exclusions, and GREEN-07 state are fixed by whole-object equality after duplicate-safe decoding.
- T-198-55-03 and T-198-62-SC remain excluded; the record claims neither reconstructed evidence nor mitigation.
- Plan 65's implementation commits do not modify SECURITY, VERIFICATION, Plans 63/64, their summaries, or the rejected Round-14 disposition.
- The v2 schema cannot carry local closed, mitigated, attested, evidenced, status, or verdict fields. Canonical security remains the next verdict-writing step, before phase verification.

### New Findings

None.

---

_Plan 65 delta reviewed: 2026-09-10T21:38:12Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_

## Plan 66 Delta Review

**Reviewed:** 2026-09-10T22:22:04Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

### Delta Summary

Plan 66 preserves the 01-61 audited namespace, the sole Plan-62 terminal role,
and the exact bytes of summaries 63-65. Its ordinary, final-mode, and combined
security-disposition suites pass (14, 14, and 34 tests respectively). However,
the only unhashed member of the new policy, `198-66-SUMMARY.md`, is validated by
a lossy regex parser that accepts contradictory duplicate YAML fields. The
claimed fail-closed repair-summary boundary is therefore not established.

### Critical Issues

### CR-05: Duplicate Plan-66 frontmatter fields bypass the semantic boundary

**Classification:** BLOCKER
**File:** `/Users/jon/projects/threadline/test/threadline/phase198_zero_human_uat_contract_test.exs:527-536`

**Issue:** Plan 66 cannot be content-hashed before its execution summary is
created, so `validate_summary_semantics!/4` is the authorization boundary for
that file. The function accepts `phase` and `plan` when *any* matching line is
present, selects only the first `status` match, and delegates coverage parsing
to `coverage_entries/1`, which splits on the first `coverage` member and then
collapses repeated coverage IDs with `Map.new/1` at lines 745-770. A summary
containing both `phase: 198-green-bringup` and `phase: 199`, both `plan: 66` and
`plan: 65`, or `status: complete` followed by `status: halted` passes these
identity/status checks. Repeated coverage members or IDs can likewise hide a
conflicting value. A downstream YAML consumer may select the other value or
reject the document, recreating the parser-differential ambiguity Plan 66 was
supposed to eliminate. The current mutation matrix changes one canonical field
at a time and therefore positively misses this both-values-present case. This
leaves the high-severity T-198-66-04 lifecycle boundary unmitigated.

**Fix:** Parse a strictly delimited frontmatter document with duplicate-preserving
semantics, reject duplicate top-level keys and duplicate coverage IDs before any
map construction, and then validate exact scalar values. If retaining the
repository's constrained regex parser, first require the opening delimiter at
byte zero, exactly one `phase`, `plan`, `coverage`, and `status` member, and
unique coverage IDs. Add malicious-first and malicious-last fixtures for every
identity/status/coverage field plus repeated coverage IDs, and assert the
duplicate-specific rejection occurs before value validation.

### CR-05 Repair Re-review: REMAINS OPEN

**Reviewed:** 2026-09-10T22:29:46Z
**Repair commit:** `acd34cd4`
**Validation update:** `aa095569`

The repair adds effective malicious-first and malicious-last fixtures for plain
unquoted `phase`, `plan`, `status`, and `coverage` keys. It also checks duplicate
plain `D1` coverage IDs before `Map.new/1`, and both fresh requested suites pass.
Those changes close the originally demonstrated literal duplicate cases, but do
not close the YAML parser-differential defect.

The duplicate detector at
`test/threadline/phase198_zero_human_uat_contract_test.exs:799-809` recognizes
only unquoted keys matching `[A-Za-z_][A-Za-z0-9_-]*`. A valid YAML member such
as `"phase": 199` is therefore invisible to the detector. A document containing
the accepted unquoted `phase: 198-green-bringup` followed by `"phase": 199`
passes the contract's key scan and phase predicate, while a standard YAML parser
resolves the resulting `phase` value to `199`. The reverse order is likewise not
rejected as a duplicate; it merely changes which external consumer value wins.
This is the same both-values-present ambiguity CR-05 identified, expressed with
a valid YAML key spelling instead of an identical byte spelling. The new fixtures
at lines 396-420 exercise only plain-key duplication, so they cannot detect it.

CR-05 remains a **BLOCKER**. Use a duplicate-preserving YAML parser and compare
decoded scalar keys, or reject every YAML key spelling outside the one canonical
unquoted form before performing the duplicate check. Add both-order quoted-key
fixtures for all four protected fields and require the duplicate/noncanonical-key
failure before identity, status, or coverage validation. Consequently,
`198-VALIDATION.md`'s `CR-05 FILLED` conclusion is not supported by the current
contract.

**Fresh repair verification:**

- Final-mode focused summary contract: 16 tests, 0 failures.
- Combined summary plus Plan-65 security-disposition contracts: 36 tests, 0 failures.
- Role constants remain exact: audited-final 01-61, sole terminal 62,
  content-bound post-terminal 63-65, and non-terminal repair summary 66.

### Boundary Checks That Passed

- The Plan-66 implementation commits modify only the declared manifest and
  focused contract; the executor adds the standard summary and metadata files.
- Summaries 01-61, terminal Plan 62, and post-terminal summaries 63-65 were not
  modified by the delta. The three new manifest digests match their tracked
  summary bytes.
- The new JSON decoder rejects duplicate members recursively before conversion
  to maps, including both member orders at the manifest root, policy object,
  each 63-65 record, and the Plan-66 repair record.
- Allowed membership is built from fixed role records rather than wildcard
  discovery, and Plan 67 or later remains rejected in both normal and final
  modes.
- SECURITY and VERIFICATION were not changed by the task commits; GREEN-07 and
  the named risk dispositions remain unchanged.
- Independent commands passed: ordinary focused summary contract (14 tests),
  final-mode focused summary contract (14 tests), and the combined Plan-66 plus
  Plan-65 security-disposition contracts (34 tests), all with zero failures.

---

_Plan 66 delta reviewed: 2026-09-10T22:22:04Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
