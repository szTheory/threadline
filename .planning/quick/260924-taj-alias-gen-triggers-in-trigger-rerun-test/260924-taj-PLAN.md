---
phase: quick-260924-taj
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - test/threadline/capture/trigger_rerun_test.exs
autonomous: true
requirements: [GATE-01, GATE-02]

estimate:
  tokens: 15000
  raw_tokens: 15000
  tasks: 1
  confidence: low

must_haves:
  truths:
    - "`MIX_ENV=test mix credo --strict` exits 0 (no Credo.Check.Design.AliasUsage findings in trigger_rerun_test.exs)"
    - "`mix verify.credo` exits 0"
    - "`mix format --check-formatted` exits 0"
    - "`mix test test/threadline/capture/trigger_rerun_test.exs` reports 0 failures"
  artifacts:
    - path: test/threadline/capture/trigger_rerun_test.exs
      provides: "alias Mix.Tasks.Threadline.Gen.Triggers; both call sites use Triggers.run/1"
  key_links:
    - from: test/threadline/capture/trigger_rerun_test.exs
      to: lib/mix/tasks/threadline.gen.triggers.ex
      via: "alias Mix.Tasks.Threadline.Gen.Triggers -> Triggers.run(args)"
---

<objective>
Clear the two `Credo.Check.Design.AliasUsage` findings in `test/threadline/capture/trigger_rerun_test.exs` (lines ~219 inside `assert_raise`, ~279 inside `defp generate!`) that make `mix credo --strict` exit 2 and break the CI-required `verify-credo` job.

Purpose: restore the green credo gate (GATE-01/GATE-02).
Output: one edited test file, one commit.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
</execution_context>

<context>
@/Users/jon/projects/threadline/CLAUDE.md
@/Users/jon/projects/threadline/test/threadline/capture/trigger_rerun_test.exs

Precedent: `test/mix/tasks/threadline/gen_triggers_test.exs:6` and `test/mix/tasks/threadline/install_test.exs:6` already use `alias Mix.Tasks.Threadline.Gen.Triggers`. No other `Triggers` name exists in the target file, so the short alias does not collide.

Env prefix for every mix command (bare `mix` dies without it):
`bash -c 'cd /Users/jon/projects/threadline && DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix <cmd>'`
</context>

<tasks>

<task type="tracer">
  <name>Task 1: Alias Gen.Triggers and route both call sites through it</name>
  <files>test/threadline/capture/trigger_rerun_test.exs</files>
  <action>
1. Run the credo command first (env prefix, `mix credo --strict`) and confirm the live finding list. Scope is this one file: if findings exist in OTHER files, do not fix them — report them in the SUMMARY. If this file has additional AliasUsage findings beyond the two known ones, fix them the same way.
2. After the existing line `alias Threadline.StorageSchema` (line 12), add the line `alias Mix.Tasks.Threadline.Gen.Triggers`. Keep the alias block grouped; if credo's AliasOrder check complains, place it so aliases are alphabetical (Mix... sorts before Threadline..., i.e. put it above `alias Threadline.Capture.{...}`).
3. Replace `Mix.Tasks.Threadline.Gen.Triggers.run(` with `Triggers.run(` at both call sites (~219 and ~279). Change nothing else in behavior.
4. Run `mix format` (env prefix) on the file so any reflow from the shorter call is formatted.
5. Commit ONLY the test file: `git add test/threadline/capture/trigger_rerun_test.exs` then commit with subject exactly `test: alias Gen.Triggers in trigger rerun test` (no planning IDs, phase numbers, or quick id in the subject/body), ending the message with the Co-Authored-By attribution line. Never `git add .planning/` or `git add .`.
  </action>
  <verify>
    <automated>bash -c 'cd /Users/jon/projects/threadline && DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix credo --strict && DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix verify.credo && DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix format --check-formatted && DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix test test/threadline/capture/trigger_rerun_test.exs'</automated>
    <automated>bash -c 'cd /Users/jon/projects/threadline && test "$(grep -c "Mix.Tasks.Threadline.Gen.Triggers.run" test/threadline/capture/trigger_rerun_test.exs)" -eq 0 && test "$(grep -c "Triggers.run(" test/threadline/capture/trigger_rerun_test.exs)" -eq 2 && git log -1 --format=%s | grep -qx "test: alias Gen.Triggers in trigger rerun test" && git show --name-only --format= HEAD | grep -qx test/threadline/capture/trigger_rerun_test.exs && test "$(git show --name-only --format= HEAD | wc -l | tr -d " ")" -eq 1'</automated>
  </verify>
  <done>credo --strict and verify.credo exit 0; format check passes; the rerun test file passes with 0 failures; HEAD commit touches only the test file with the exact subject above.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| none | Test-only refactor; no runtime code, input, or dependency change |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-q260924-01 | Information disclosure | git commit scope | low | mitigate | Stage only the test file by path; never `git add .planning/` (machine-local critic files) |
</threat_model>

<verification>
Both automated verify commands in Task 1 exit 0.
</verification>

<success_criteria>
`mix credo --strict` exits 0 on HEAD, unblocking the `verify-credo` CI job; test behavior unchanged.
</success_criteria>

<output>
Create `/Users/jon/projects/threadline/.planning/quick/260924-taj-alias-gen-triggers-in-trigger-rerun-test/260924-taj-SUMMARY.md` when done (do not commit it with the test-file commit).
</output>
