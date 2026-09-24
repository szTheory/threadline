---
phase: 204-structure
reviewed: 2026-09-24T04:49:35Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - lib/mix/tasks/critic.measure.ex
  - lib/threadline/critic_trust/krippendorff_alpha.ex
  - lib/threadline/critic_trust/repository_boundary.ex
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/release_artifact_contract_test.exs
  - test/threadline/source_size_contract_test.exs
findings:
  critical: 0
  warning: 2
  info: 8
  total: 10
status: issues_found
---

# Phase 204: Code Review Report

**Reviewed:** 2026-09-24T04:49:35Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Scope: the 204-16 gap-closure diff `5df40009..HEAD` for the six files listed. It widens the `@banner` regex and adds a planted self-test. It fixes the keyword-clause length measurement (the prior WR-01). It moves critic.measure's repository boundary into `Threadline.CriticTrust.RepositoryBoundary`. This review replaces the phase-wide review from a61effc3. Its prior findings are re-checked below.

**The move is verbatim.** I extracted the old `Repository-only path and decode boundary` section from `5df40009:lib/mix/tasks/critic.measure.ex` and diffed it against `repository_boundary.ex:11-266`. Blank lines were ignored. The only differences are the 12 planned `defp` to `def` promotions, plus `{__MODULE__, :atomic_write_hook}` becoming `{Mix.Tasks.Critic.Measure, :atomic_write_hook}`. These guards are unchanged:
- `realpath` canonicalization
- `Path.safe_relative_to`
- the bidirectional `within?` root-separation check
- the exclusive temp file, fsync and rename sequence, with cleanup in `after`
- the `critic.measure:` / `resolved path:` / `repository-only: true` / `next:` error text

The hook key matches what `critic_trust_test.exs:1067` plants. `canonicalize_root!`, `within?`, `atomic_write_hook` and the `valid_*` helpers stay private. The new file is in the Hex `exclude_patterns` (`^lib/threadline/critic_trust/`), in `@maintainer_only_paths` and in `@hidden_modules`.

**Commands run:**
- `MIX_ENV=test mix compile --warnings-as-errors`: clean.
- `MIX_ENV=dev mix dialyzer`: 0 errors. The sealed empty-output hash still holds.
- `mix credo --strict` on both lib files: no issues.
- `source_size_contract_test`, `public_surface_contract_test`, `critic_trust_test` and `dialyzer_ignore_contract_test`: 95 tests, 0 failures.

**WR-01 fix, probed directly:**
- `end_of_expression` is present for keyword clauses that are last in a module, last in a `quote` block, or split by `;`. The fix measures all of these correctly.
- The subtree fallback is only reached when there is no enclosing newline-terminated block, and there it still returns 1 (IN-07).

**Banner regex, probed directly:** the planted positives and negatives behave as the test says. However, the common ASCII forms `# -- Title --`, `# == Title ==` and `# ═══ Title ═══` still pass the gate silently (WR-03). The trailing-rule branch also flags some prose that the moduledoc says is exempt (IN-06).

I found no BLOCKER.

## Carried forward from prior review (a61effc3)

| Prior ID | Status | Evidence |
|---|---|---|
| WR-01 size gate counts keyword `do:` clauses as 1 line | **RESOLVED** | `source_size_contract_test.exs:318` now uses `last_meta_line(node)`, which reads `end_of_expression` and falls back to a subtree max. Two planted self-tests were added (a 121+ line `~H` heredoc and an exact 8-line clause followed by `def g`), and both pass. A residual edge is tracked as IN-07. |
| WR-02 ci.all dedup guard raises "alias cycle" on a self-referencing `test` alias | **STILL OPEN** | `test/threadline/ci_all_dedup_contract_test.exs:228-229` still raises on `head in seen` and has no case for an alias calling its own task. No commit in `5df40009..HEAD` touches the file. |
| IN-01 storybook prose names the deleted `Threadline.OperatorSurface.UI` / `UI.fn` forms | **STILL OPEN** | `examples/threadline_phoenix/storybook/forms/field.story.exs:11,17` and `overlays/modal.story.exs:18` still say `Threadline.OperatorSurface.UI source`, `UI.field` and `UI.modal`. |
| IN-02 credo register successor hardwired to a completed phase | **STILL OPEN** | `test/threadline/credo_config_contract_test.exs:37` still has `@successor "Phase 204 / STRUCT-07"`, and `:83` still asserts `successor == @successor`. |
| IN-03 test-structure scan only sees bare line-start `use Phoenix.Endpoint/Router` | **STILL OPEN** | `test/threadline/test_structure_contract_test.exs:27-28`: the regexes are unchanged. |
| IN-04 `MechanicalChecker` and `MechanicalChecker.Contrast` call each other | **STILL OPEN** | `lib/threadline/operator_surface/mechanical_checker/contrast.ex:37-39` still calls `MechanicalChecker.contrast_ratio/2` and `MechanicalChecker.relative_luminance/1`. |
| IN-05 duplicate atom-key schema matcher | **STILL OPEN** | `row_history_component.ex:156-160` (`schema_for_atom_key/2`) and `timeline_live/helpers.ex:115-119` (`atom_key_schema/2`) both still exist, with the same bodies. |

The still-open items keep their original IDs in the sections below and count toward the frontmatter totals. The resolved WR-01 is not counted. New findings are numbered from WR-03 and IN-06 so they don't collide with prior IDs.

## Warnings

### WR-02: The ci.all dedup guard raises "alias cycle" on a legal self-referencing `test` alias (carried, still open)

**File:** `test/threadline/ci_all_dedup_contract_test.exs:218-240`
**Issue:** This is unchanged since the prior review. `expand/3` treats a step whose head names the alias currently being expanded as recursion. Mix treats it as the underlying task. Adding the Phoenix-default `test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]` alias would make the real-tree test fail with `alias cycle: verify.test -> test -> test`, which blames `ci.all` for a problem it does not have.
**Fix:**
```elixir
cond do
  seen != [] and head == hd(seen) -> [{Enum.reverse(seen), step}]   # alias invoking its own task
  head in seen -> raise ArgumentError, "alias cycle: ..."
  ...
end
```
Add a self-test with `test: ["ecto.create --quiet", "test"]`.

### WR-03: The widened banner gate still passes the most common ASCII titled-banner forms silently

**File:** `test/threadline/source_size_contract_test.exs:45` (moduledoc `:16-23`, self-test `:222-245`)
**Issue:** The new regex is
`~r/^\s*#\s*(?:-{3,}|={3,}|─{2,}|\*{3,})|(?:-{3,}|={3,}|─{3,}|\*{3,})\s*$/u`.
The two-character leading run is allowed only for `─`. The ASCII rules need three characters at either end. I ran each of these comments through `Regex.match?(@banner, text)`, and each returned `false`:
- `# -- Private helpers --`
- `# == Section ==`
- `# ═══ Section ═══` (double box, U+2550)
- `# ━━━━━━━━━━` (heavy box, U+2501)
- `#####################` (hash rule)
- `## ─── Section` (the second `#` blocks the leading branch, and there is no trailing rule)

`# -- Private helpers --` is the ASCII twin of the box-drawing banner that 204-VERIFICATION found and this plan was written to close. It is a section banner standing in for a module or function boundary, which is what D-11/STRUCT-04 forbids. The gate still reports zero tolerance and the SUMMARY says it "catches the titled box-rule form". That is true for `─` but not for the ASCII equivalent. This is the same kind of gap as the one being closed: the gate enforces less than its prose implies, and nothing fails when it happens. The tree has none of these forms today. I grepped `lib/` for `#{4,}`, `━`, `═`, `~{3,}`, `_{3,}`, `==` and `-- `.
**Fix:** Allow a two-character run of any rule character when a title follows it, and add a hash rule and the heavy/double box characters. Pin the misses as planted positives:
```elixir
@banner ~r/^\s*#+\s*(?:[-=*─━═]{2,}\s+\S|[-=*─━═#_~]{3,})|\s(?:[-=*─━═_~]{2,})\s*$/u
```
```elixir
# planted positives
# -- Private helpers --
# == Section ==
# ═══ Section ═══
#####################
## ─── Section
```
I checked this regex against every planted case plus the misses above. All eight positives match. These still do not match: `--tl-space-2`, `|------|---|`, `->` prose, plain prose, a bare `##`, `# x == y` and `# a -- b`. It still matches prose that ends in ` --` (see IN-06), so pin that decision with a planted case too.

## Info

### IN-01: Storybook doc prose still names the deleted `Threadline.OperatorSurface.UI` module and `UI.fn` call forms (carried, still open)

**File:** `examples/threadline_phoenix/storybook/forms/field.story.exs:10-19`, `examples/threadline_phoenix/storybook/overlays/modal.story.exs:18-19`
**Issue:** The prose still names `UI.field`, `UI.modal` and the other pre-split names, but the components now live in `UI.Form.*`, `UI.Overlay.*` and `UI.Page.*`.
**Fix:** Change the prose to the family-qualified names.

### IN-02: The credo register can only name a successor that is a completed phase (carried, still open)

**File:** `test/threadline/credo_config_contract_test.exs:37`, `:79-84`, `:403`
**Issue:** `@successor "Phase 204 / STRUCT-07"` is still hardwired, and the real-tree test still asserts equality with it. A future reviewed disable can't name a real successor phase.
**Fix:** Require a non-blank successor that differs from the drained phase label, or keep an allowlist of open successors.

### IN-03: The test-structure scan only sees a bare line-start `use Phoenix.Endpoint` / `use Phoenix.Router` (carried, still open)

**File:** `test/threadline/test_structure_contract_test.exs:27-28`
**Issue:** The scan misses `use(Phoenix.Endpoint, ...)` and aliased `use` forms.
**Fix:** Do an AST scan for `{:use, _, [{:__aliases__, _, [:Phoenix, :Endpoint]} | _]}`, or at minimum use `use\(?\s*Phoenix\.(Endpoint|Router)\b`.

### IN-04: `MechanicalChecker` and `MechanicalChecker.Contrast` call each other (carried, still open)

**File:** `lib/threadline/operator_surface/mechanical_checker/contrast.ex:37-39`
**Issue:** The child module calls back into its parent for `contrast_ratio/2` and `relative_luminance/1`.
**Fix:** Move both functions into `Contrast` or `Parsing`, and have the parent delegate to them.

### IN-05: The same atom-key schema matcher exists as two private helpers (carried, still open)

**File:** `lib/threadline/operator_surface/live/row_history_component.ex:156-160`, `lib/threadline/operator_surface/live/timeline_live/helpers.ex:115-119`
**Issue:** `schema_for_atom_key/2` and `atom_key_schema/2` are identical and can drift apart.
**Fix:** Move the table-to-schema lookup into one shared internal helper.

### IN-06: The trailing-rule branch flags prose that the moduledoc says is exempt

**File:** `test/threadline/source_size_contract_test.exs:16-23`, `:45`
**Issue:** The moduledoc says "a markdown table rule ... is not a banner". The planted negative only covers the leading-pipe form `# |------|---|`. GFM also allows the pipe-less form `# --- | ---`, and the leading branch matches it. The trailing branch also counts ordinary prose that ends in a rule run, such as `# see the table below ---` and `# TODO ***`. I confirmed both match. The gate fails loudly and a person can sort it out, so this is Info. Still, the doc promises more than the regex delivers.
**Fix:** Add `# --- | ---` as a planted case and decide which way it should go. Either exclude it (for example, reject comments that contain `|`) or narrow the moduledoc wording to "a pipe-delimited markdown table rule".

### IN-07: The keyword-clause fallback still returns 1 for literal bodies

**File:** `test/threadline/source_size_contract_test.exs:331-351`
**Issue:** `last_meta_line/1` falls back to `Macro.prewalk` over `:line`/`:closing`/`:end`/`:end_of_expression` when there is no `end_of_expression`. Plain heredoc strings and list literals carry no metadata, so a clause reaching the fallback with that kind of body measures as 1 line. I confirmed this: `"def f(a),\n  do: [\n  1,\n  2\n  ]"` and a 5-line `do: """..."""` at EOF with no trailing newline both give `{:prewalk, 1}`. Every clause inside `defmodule ... do` followed by a newline gets `end_of_expression`, including the last clause in a module or a `quote`, so no real `lib/` file is affected today. The SUMMARY calls the fallback "best effort", but the code comment above `last_meta_line/1` does not say it can still return 1.
**Fix:** In the fallback, also consider the enclosing parent's `:end`/`:closing` line, or fail closed (`fail!/1`) when neither `:end` nor `:end_of_expression` is present. That way a silent 1 can't come back.

### IN-08: `RepositoryBoundary` is hardwired to one task, while `critic.synth` keeps a weaker copy of the same boundary

**File:** `lib/threadline/critic_trust/repository_boundary.ex:14,37,51,71,250,261`; see also `lib/mix/tasks/critic.synth.ex:106-190` (outside this review's file scope)
**Issue:** The module is named as a general repository boundary, but the task name is written out in several places:
- the `mix help critic.measure` recovery strings
- the `critic.measure:` error prefix
- the `{Mix.Tasks.Critic.Measure, :atomic_write_hook}` Process key

The 204-16 plan required this to keep behaviour unchanged, and the literal key is correct for the existing test. However, it gives the lower-level module a hidden reverse reference to its caller. Meanwhile `critic.synth.ex` still has its own `project_root!`, `resolve_repository_root!`, `require_directory!`, `atomic_replace!`, `atomic_write_hook` and `task_error!`. Its `resolve_repository_root!/2` has no `realpath` canonicalization, so a symlinked `--fixture-root` inside the repo that points outside it passes the check. critic.measure rejects that case (`critic_trust_test.exs:785`). The two maintainer tools now enforce different path guarantees, and the extraction did not converge them.
**Fix:** Parameterize the boundary by task: pass `%{task: "critic.synth", hook_key: {Mix.Tasks.Critic.Synth, :atomic_write_hook}}` or add a `task_name` argument. Then have `critic.synth` call `RepositoryBoundary.resolve_repository_root!/3` and `atomic_replace!/2` instead of its own copies, so it gets symlink canonicalization too.

---

_Reviewed: 2026-09-24T04:49:35Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
