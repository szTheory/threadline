---
phase: 220-newest-toolchain-lane
reviewed: 2026-09-28T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - .github/workflows/ci.yml
  - CONTRIBUTING.md
  - README.md
  - lib/mix/tasks/threadline.incident.ex
  - lib/threadline/critic_trust/ledger_splice.ex
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/live/evidence_live.ex
  - lib/threadline/operator_surface/live/export_status_live/components.ex
  - mix.exs
  - test/support/migration_harness.ex
  - test/threadline/ci_workflow_parity_contract_test.exs
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 220: Code Review Report

**Reviewed:** 2026-09-28
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Scope: `git diff 1934d82d HEAD` over the 11 listed files.

**The dead-code removals do not change behaviour.** I traced each one:

- `timeline_search_path/2` catch-all (`export_status_live/components.ex`). The only call site (line 102) sits inside `:if={Presentation.query_pairs(job.query_params) != []}`. `query_pairs(nil)` returns `[]`, so a nil value never reaches the call. A non-map value would already raise in `query_pairs/1` (line 91) and in `export_summary/1`. `query_params` is an Ecto `:map` field on a `jsonb NOT NULL` column, so a JSON array or scalar fails to load before rendering. The `when is_map` clause covers every reachable input.
- `maybe_put(params, _key, nil)` (`evidence_live.ex`). The only caller is the second `carry_to_exports_path/3` clause. The clause before it matches `%{subject: nil}`, and every `request` assigned in this module is a map with a `:subject` key, so `request.subject` is never nil there.
- `@has_ever_acted and` (`actor_live.ex:233`). It sits in the `else` branch of `if not @has_ever_acted`, so it is always true there. A non-boolean value would already raise in `not/1`.
- `binary_part(text, open, byte_size(text) - open)` (`ledger_splice.ex:85`). For `0 <= open <= byte_size(text)` it returns the same bytes as `<<_::binary-size(open), rest::binary>>`. `open` is always `rest_start + ob_rel` from two successful `:binary.match/2` calls, so it is always in bounds. Only the out-of-range failure changes (ArgumentError instead of MatchError), and that path cannot be reached.
- The two `require Logger` removals. `Logger.configure/1`, `Logger.level/0` and `Logger.compare_levels/2` are functions, not macros, and neither module uses a Logger macro.

**The `lane: latest` row and `latest_row_errors/2` hold up.** Each shape regex gates its newer-than check, a missing or unparseable current value fails closed, and every mutation control asserts the specific error fragment it expects.

**The new D-15 and D-16 contracts have real bypasses.** Each one lets a change the contract claims to forbid pass green:

- A `latest` lane that votes but runs nothing.
- A pre-release PostgreSQL image written with a registry prefix, or as an expression with a suffix.
- A ci.yml job whose id contains an underscore, which escapes `needs:` coverage.

I confirmed each regex behaviour by running the exact contract regexes (see WR-02).

One doc change also makes an existing contradiction worse: the CONTRIBUTING branch-protection list gained a third required context, although the live ruleset allows exactly one (`CI required`).

## Warnings

### WR-01: A voting lane can be made vacuous with a step `if:` or `|| true`, and `voting_lane_errors/1` does not notice

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:545-601` (the `voting_lane_errors/1` definition), `.github/workflows/ci.yml:434-441`
**Issue:** D-15 promises that "no voting lane can be made non-blocking". The contract only bans `continue-on-error:` and `allowed-failures:`, and checks `needs:` coverage. Any of these keeps the `latest` lane green while it proves nothing:

- `if: matrix.lane != 'latest'` on `Compile (warnings as errors)`, `Verify no compile-connected xref cycles` or `Run tests`. The step is skipped, the job succeeds, and alls-green counts it as success.
- `run: mix verify.test || true`.

No test pins those three steps as unconditional. `grep matrix.lane test/threadline/*.exs` finds only the current-lane guards on example and cache steps. `ci_topology_contract_test.exs:230` only checks that a step named `Run tests` exists. The ci.yml comment (lines 326-328) claims the latest lane "runs compile --warnings-as-errors, xref cycles and `mix verify.test`", but nothing enforces it.
**Fix:** Extend `voting_lane_errors/1` (or add a sibling rule) so the verify-test steps that prove every lane carry no `if:` and run exactly the expected command. Give it matching mutation controls:

```elixir
@every_lane_steps [
  {"Compile (warnings as errors)", "mix compile --warnings-as-errors"},
  {"Verify no compile-connected xref cycles", "mix verify.xref_cycles"},
  {"Run tests", "mix verify.test"}
]

defp every_lane_step_errors(ci_yaml) do
  steps = ci_yaml |> workflow_job("verify-test") |> strip_comment_lines() |> job_steps()

  for {name, cmd} <- @every_lane_steps,
      error <- (case Enum.filter(steps, &String.starts_with?(&1, "      - name: #{name}\n")) do
        [step] ->
          lines = trimmed_lines(step)
          (if Enum.any?(lines, &String.starts_with?(&1, "if:")), do: ["#{name} rule=lane-skip"], else: []) ++
            (if "run: #{cmd}" in lines, do: [], else: ["#{name} rule=lane-command"])
        _ -> ["#{name} rule=lane-step-missing"]
      end),
      do: "verify-test " <> error
end
```

Add controls for `if: matrix.lane != 'latest'` on `Run tests` and for `mix verify.test || true`.

### WR-02: `postgres_image_errors/1` misses registry-prefixed, untagged, digest-pinned and expression-suffixed images

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:656-657` (`@postgres_image_ref`) and `postgres_image_refs/1`
**Issue:** The negative lookbehind `(?<![\w\/@:.-])` skips `postgres://` connection URLs. It also skips every image reference that has a registry or namespace prefix. The expression branch stops at `}}` and ignores any suffix after it. I ran the regex directly:

| Input | Regex result | Outcome |
|---|---|---|
| `image: docker.io/library/postgres:19beta1` | `[]` | not scanned, passes |
| `image: postgres:${{ matrix.pg }}rc1` | captures only `${{ matrix.pg }}` | resolves to release tags, passes |
| `image: postgres` (implicit `latest`) | `[]` | passes |
| `image: postgres@sha256:...` | `[]` | passes |

So D-16 ("no workflow or compose file runs a pre-release PostgreSQL") can be broken without the contract failing.
**Fix:** Match on `image:` lines rather than on bare `postgres:` tokens. That also removes the need for the URL lookbehind:

```elixir
@image_line ~r/^\s*image:\s*["']?(?:[\w.-]+(?::\d+)?\/)*(?:library\/)?postgres(?<rest>[^\s"']*)["']?\s*$/m
```

Then require `rest` to match exactly `:` followed by a release tag or a bare `${{ matrix.pg }}`. Treat an empty `rest`, an `@sha256:` digest, or any text after `}}` as `rule=pg-tag` / `rule=pg-unresolved`. Add mutation controls for `docker.io/library/postgres:19beta1`, `postgres:${{ matrix.pg }}rc1` and a bare `postgres`.

### WR-03: A ci.yml job whose id contains an underscore escapes `needs:` coverage

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:1542-1552` (`workflow_jobs/1`), used by the `needs-coverage` check in `voting_lane_errors/1`
**Issue:** `workflow_jobs/1` recognises job headers only with `^  ([a-z][a-z0-9-]+):\n`. GitHub allows underscores and uppercase letters in job ids. A new job such as `verify_latest:` is not seen as a job boundary. Its text folds into the previous job's block, it never enters the `jobs` set, and `needs == jobs` still holds while that job is missing from `ci-required`'s `needs:`. A failing lane added that way would not vote. The same blind spot affects the per-job `continue-on-error` scan, which reports the folded job under the wrong id.
**Fix:** Widen the header pattern to GitHub's job-id grammar, `^  ([A-Za-z_][A-Za-z0-9_-]*):\s*$`, in both `workflow_jobs/1` and `workflow_job/2`. Add a mutation control that appends `  verify_extra:\n    runs-on: ubuntu-24.04\n` to ci.yml and expects `rule=needs-coverage`.

### WR-04: CONTRIBUTING branch-protection list now names three verify-test contexts, but the ruleset requires exactly one

**File:** `CONTRIBUTING.md:883-895`
**Issue:** The "Branch protection (maintainers)" section tells maintainers to "require these checks on `main`". This phase added `Run test suite (latest)` to that list. The paragraph right after it says the only required status check is `CI required` per `.github/rulesets/main.json`, and `bin/verify-branch-protection` / `bin/compare-required-contexts` enforce exact equality with that one context. A maintainer who follows the list turns the protection check red. The contradiction existed before this phase, but this phase added to the stale list instead of fixing it. The phase's own intent is that the latest lane votes *through* `ci-required`, not as a separate required context.
**Fix:** Present the list as the jobs that feed `CI required`, not as contexts to require:

```markdown
The only required status check is `CI required` (`.github/rulesets/main.json`); it
aggregates these jobs, among others, through `needs:`:

- Run test suite (min) / (current) / (latest) (`verify-test` lanes)
- ...
```

Keep the `Run test suite (latest)` string so the doc-contract assertion still holds.

## Info

### IN-01: The `continue-on-error` and `allowed-failures` regexes miss quoted keys and flow mappings

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:550-567` (inside `voting_lane_errors/1`)
**Issue:** `~r/^\s*continue-on-error\s*:/m` does not match `"continue-on-error": true` or a flow-mapped step (`- { name: x, continue-on-error: true }`). I checked both and neither matches. Both are valid YAML that GitHub honours. The `allowed-failures` rule has the same gap.
**Fix:** Use `~r/(^|[\s{,])["']?continue-on-error["']?\s*:/m` (and the same pattern for `allowed-failures`), with a quoted-key mutation control.

### IN-02: The D-17 assertion on the job's check name is satisfied only by a YAML comment

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:446`
**Issue:** `assert String.contains?(job, ~s["Run test suite (latest)"])` passes only because of the comment at `ci.yml:318`. The composed check name comes from `name: Run test suite` plus the `lane` axis, and the lane-axis test already covers that. The assertion pins prose, not behaviour: deleting the comment fails it, while breaking the real name would not.
**Fix:** Drop the assertion, or run it on `strip_comment_lines(job)` against the `lane: [min, current, latest]` axis.

### IN-03: The comment above `verify_test_matrix_errors/3` still describes two rows

**File:** `test/threadline/ci_workflow_parity_contract_test.exs:1658-1659`
**Issue:** The comment says only "the min row pins … the current row reads .tool-versions" and never mentions the latest row, whose check this function now calls.
**Fix:** Add "the latest row pins an exact release strictly newer than current (`latest_row_errors/2`)".

---

_Reviewed: 2026-09-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
