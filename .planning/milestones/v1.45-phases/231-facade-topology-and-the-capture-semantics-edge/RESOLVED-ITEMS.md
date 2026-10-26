# Phase 231 — Deferred Items

## 231-02: pre-existing release_artifact_contract_test.exs vocabulary failures

**Found during:** Task 1 (231-02), running the full verify command
`mix test test/threadline/public_surface_contract_test.exs test/threadline/release_artifact_contract_test.exs`.

**Status:** Resolved in 231-02 (Rule 3 — blocking fix). The pre-existing failures blocked this
task's own `<verify>` command (which runs `release_artifact_contract_test.exs` together with
`public_surface_contract_test.exs`), and the fix was a one-line, no-behavior-change rewording of
two comments in a file this task was already touching, so it was fixed rather than merely logged.

**Evidence:** Confirmed via `git stash` (reverting all 231-02 working-tree changes) that the
same 3 failures reproduce identically on top of 231-01's commit (`c382a937`):

- `lib/threadline/query.ex:88` (pre-stash line 115) — `# D-08: hidden, batched replacement
  for the removed capture/semantics Ecto ...` comment, added in 231-01's GREEN commit
  `45592663`, matches `release_artifact_contract_test.exs`'s `decision_id: ~r/\bD-\d{2,}\b/`
  planning-vocabulary scan.
- `lib/threadline/query.ex:709` (pre-stash line 736) — `# D-10: pulls a bare :action
  (audit_transaction/2) out of a :preload ...` comment, added in 231-01's GREEN commit
  `c382a937`, same pattern.

**Failing tests:**
- `test all packaged source uses durable vocabulary`
- `test source_vocab_core_query_policy is an exact nonempty archive source owner`
- `test the entire readable archive is free of planning vocabulary`

**Fix applied:** reworded the two comments in `lib/threadline/query.ex` to drop the `D-\d{2,}`
decision-id prefix while keeping the exact same rationale text, mirroring how this plan's own
`skip_code_autolink_to`/`skip_undefined_reference_warnings_on` comments in `mix.exs` were phrased
without decision IDs (Task 1's GREEN commit). No behavior change; `mix test
test/threadline/public_surface_contract_test.exs test/threadline/release_artifact_contract_test.exs`
now exits 0 (60 tests, 0 failures) and `mix verify.credo` stays clean.
