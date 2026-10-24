---
phase: 234
fixed_at: 2026-10-05T16:07:35Z
review_path: .planning/phases/234-typespec-and-doc-completion-gate/234-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 234: Code Review Fix Report

**Fixed at:** 2026-10-05T16:07:35Z  
**Source review:** `.planning/phases/234-typespec-and-doc-completion-gate/234-REVIEW.md`  
**Iteration:** 1

**Summary:**
- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### WR-01: Actor map type does not require its documented `type` key

**Files modified:** `lib/threadline/semantics/actor_ref.ex`  
**Commit:** `f0b0cef7` (corrective commit; initial attempt `bffb6de0`)  
**Applied fix:** The initial correction used the valid `required(String.t())` form after Elixir 1.17 rejected literal string keys in typespecs. Incremental review found that its typedoc still overstated the static guarantee. The final correction describes the compiler-expressible map shape, includes `nil` values permitted by the public `t()` type, and documents the exact runtime `"type"`/`"id"` shape on `to_map/1`. The reviewer confirmed WR-01 resolved in `234-REVIEW.md`.

### WR-02: Hydrated transaction action is typed as any struct

**Files modified:** `lib/threadline/capture/audit_transaction.ex`  
**Commit:** `34726064`  
**Applied fix:** Narrowed the virtual `action` field to `Threadline.Semantics.AuditAction.t() | nil`, matching the hydration result.

### WR-03: Export projection type excludes nullable transaction source

**Files modified:** `lib/threadline/export.ex`  
**Commit:** `bfdf4f58`  
**Applied fix:** Changed `tx_source` to `String.t() | nil`, matching the nullable database column and existing encoder behavior.

## Verification

Verification ran in the main checkout.

- `mix test test/threadline/doc_spec_coverage_contract_test.exs` — passed (5 tests, 0 failures).
- `mix verify.dialyzer` — passed (0 errors, 0 skipped warnings).

---

_Fixed: 2026-10-05T16:07:35Z_  
_Fixer: the agent (gsd-code-fixer)_

## Follow-up resolution

The incremental review's documentation/type correction is in `lib/threadline/semantics/actor_ref.ex`; its contract test and strict Dialyzer verification passed. The refreshed Phase 234 review is clean with zero findings.
_Iteration: 1_
