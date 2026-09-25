# Phase 205 — Deferred Items

Out-of-scope discoveries logged during execution. Not fixed in 205.

## From 205-01

### D-205-01: CleanCheckoutContractTest temp-dir collision with a crashed earlier run

- **Test:** `test/threadline/clean_checkout_contract_test.exs:276` ("forced verifier failure cleans only its clone child and preserves caller state")
- **Symptom:** the first full-suite run on HEAD 486a1392 failed once with
  `(File.Error) could not make directory ".../T/threadline-clean-verifier-test-13": file already exists`.
- **Cause:** `unique_temp_path/1` names directories with `System.unique_integer([:positive, :monotonic])`,
  which restarts in every VM. Directories `threadline-clean-verifier-test-1` and `-13` were left in
  `$TMPDIR` at 08:34 by an earlier run that did not tear down (before 205-01 started). A new run that
  draws the same integer collides.
- **Evidence it is not a 205 regression:** the file re-ran alone at 9 tests, 0 failures; the full suite
  re-ran at 1787 tests, 0 failures, 1 excluded. 205-01 touches neither the test nor `bin/verify-clean-checkout`.
- **Suggested fix (future plan):** add randomness (`:crypto.strong_rand_bytes/1` or the OS pid) to the
  prefix, or use `File.mkdir_p!` after an existence check that picks a fresh name. The stale
  `$TMPDIR/threadline-clean-verifier-test-{1,13}` directories were left in place (outside the repo).
  status: acknowledged
