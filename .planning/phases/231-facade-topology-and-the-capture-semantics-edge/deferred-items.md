# Phase 231 — Deferred Items

## 231-02: pre-existing release_artifact_contract_test.exs vocabulary failures

**Found during:** Task 1 (231-02), running the full verify command
`mix test test/threadline/public_surface_contract_test.exs test/threadline/release_artifact_contract_test.exs`.

**Status:** Out of scope — pre-existing, not caused by 231-02's changes.

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

**Why not fixed here:** 231-02's tasks scope is hiding `Threadline.Query`/`Threadline.Investigation`
docs and rewriting guides (API-04). Rewriting 231-01's `D-08`/`D-10` source comments to durable
prose is unrelated to this plan's files_modified list and risks touching behavior 231-01 already
verified. Per the executor scope boundary, this is logged rather than auto-fixed.

**Recommended fix:** rewrite the two comments in `lib/threadline/query.ex` (lines ~88 and ~709)
to describe the same rationale without the `D-\d{2,}` decision-id token, mirroring how this plan's
own `skip_code_autolink_to`/`skip_undefined_reference_warnings_on` comments in `mix.exs` were
phrased without decision IDs. A good owner is 231-03 (shares `lib/threadline/query.ex` in its
files_modified) or a dedicated follow-up commit before phase 231 verification.
