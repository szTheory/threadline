---
phase: 231-facade-topology-and-the-capture-semantics-edge
fixed_at: 2026-10-03T00:00:00Z
review_path: .planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 231: Code Review Fix Report

**Fixed at:** 2026-10-03T00:00:00Z
**Source review:** .planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 2 (WR-01, WR-02 — IN-01 was out of scope per fix_scope=critical_warning)
- Fixed: 2
- Skipped: 0

## Fixed Issues

### WR-01: `guides/audit-indexing.md` still names the hidden `Threadline.Query` module, undetected by the new facade-only guard

**Files modified:** `guides/audit-indexing.md`, `test/threadline/facade_only_references_contract_test.exs`
**Commit:** d1609504
**Applied fix:**
- Renamed the stale heading `## Timeline and Threadline.Query` to `## Timeline and Threadline.timeline/2`, matching how every other reference in the same guide was rewritten in this phase.
- Added a fourth detector, `@bare_module_mention_regex` + `bare_module_mentions/2`, to the contract test, catching a bare `Threadline.Query` / `Threadline.Investigation` mention that is not a dotted call, a backtick `Module.fun/N` reference, a struct-group alias (`alias Threadline.Investigation.{...}`), or an `alias Threadline.Query` statement (already covered by the existing `@bare_alias_regex`).
- Added a new real-scope test (`has zero bare module mentions of the hidden modules`) plus two self-tests: one confirming the regex flags the exact heading fixture while *not* flagging the struct-group alias or dotted/backtick forms, and one confirming it leaves a struct-group alias fixture alone.
- Before trusting the regex, I ran the full before/after check requested: scanned every scope-glob file for bare `Threadline.Query`/`Threadline.Investigation` mentions (found only the heading and the pre-existing, legitimate struct-group alias in `examples/threadline_phoenix/lib/.../audit_transaction_json.ex`); confirmed the new regex does not flag the struct-group alias; then temporarily reverted the heading, reran `mix test test/threadline/facade_only_references_contract_test.exs`, confirmed it fails with exactly `guides/audit-indexing.md:44 Threadline.Query`, then restored the fix and reran to confirm green (14 tests, 0 failures both times apart from the intentional revert).

### WR-02: `Threadline` moduledoc's "supported read API" list omits most of the module's actual public read functions

**Files modified:** `lib/threadline.ex`
**Commit:** 3ff39d65
**Applied fix:** Checked every public function in `lib/threadline.ex` (grep for `^  def `/`defdelegate`) against the moduledoc's enumeration. Found 16 public functions total; the moduledoc's "supported read API" sentence named only 8, omitting `as_of/4`, `actor_history/2`, `timeline_page/2`, `row_history_page/4`, `actor_window_page/3`, `correlation_bundle/3`, `correlation_bundle_page/3`, and `transaction_context/2`. `record_action/2` (a write) and `change_diff/2` (a post-fetch helper, not itself a query) were correctly excluded from "read API" either way. Rewrote the sentence to list all 16 read functions and added "(see the function list below)" per the REVIEW.md fix suggestion, so the enumeration can't silently drift out of sync with the function list ExDoc renders. Grepped `test/` for any doc-contract test pinning this exact sentence or function enumeration — none exists, so no test needed updating in lockstep.

## Verification

Ran inside the isolated worktree (`.claude/worktrees/rf-231-*`, repo-relative; `deps`/`_build` symlinked in from the main checkout for the duration of verification, then unlinked before handoff — numbers are reproducible from the main checkout on the fast-forwarded branch):

- `mix compile --warnings-as-errors` — clean, both before and after each edit.
- `mix test test/threadline/facade_only_references_contract_test.exs test/threadline/public_surface_contract_test.exs` — 55 tests, 0 failures.
- `mix format --check-formatted` (full project) — clean.
- `mix verify.credo` (full project) — 4984 mods/funs, no issues.

No findings were skipped. No logic-bug classification applies to either fix (WR-01 is a doc/test addition verified by a deliberate revert-and-rerun; WR-02 is a doc enumeration cross-checked against the actual function list), so neither needs the "requires human verification" flag.

---

_Fixed: 2026-10-03T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
