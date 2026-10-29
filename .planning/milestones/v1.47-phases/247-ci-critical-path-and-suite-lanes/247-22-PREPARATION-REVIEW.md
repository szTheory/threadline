# Plan 247-22 Task 1 Preparation Review

**Scope:** `tools/exunit_boundary_probe.py`, `tools/test_exunit_boundary_probe.py`
**Compared:** `ff3c29c9^..856361c4`
**Review mode:** Deep, read-only
**Result:** 7 blockers, 1 warning

The pure synthetic self-test and the saved historical receipt verifier pass, but several central guards do not match the plan's contract. In particular, the preflight CLI cannot be invoked, healthy truncated receipts validate as `INVALID`, and the source hashes in a receipt do not necessarily describe the files copied into the observed container. Do not use Task 2 to authorize observation until the blockers below are repaired and the relevant mutation controls are added.

## Blockers

### CR-01: Standalone preflight command is unreachable

**File:** `tools/exunit_boundary_probe.py:1188-1201`
**Issue:** The required mutually exclusive group includes only `--self-test`, `--run`, and `--verify`, while standalone `--preflight --output ...` is handled later as a valid generation mode. Argparse rejects the plan's exact preflight command before dispatch with exit code 2: `error: one of the arguments --self-test --run --verify is required`. Adding `--run` cannot work around this because `--run` requires an already existing preflight receipt.
**Fix:** Make the command mode group accept `--preflight` as its own mode, or use a single explicit mode argument with mutually exclusive validation after parsing. Add a mocked CLI test that invokes the documented preflight syntax and asserts it reaches `validation_preflight` without Docker.

### CR-02: A healthy truncated receipt is accepted as a valid `INVALID` stop

**File:** `tools/exunit_boundary_probe.py:523-524, 758-766`
**Issue:** Any incomplete schedule adds `fixed_schedule_stopped_early_or_changed`, and the verifier accepts that derived reason as sufficient proof for `INVALID`. This lets a receipt claim a terminal failure without any failed child, malformed event, timeout, control failure, or other raw fault. I built a synthetic valid ten-arm receipt, truncated it to its single healthy async warmup, set its status/reason from `derive_validation_status`, and `check_validation_receipt` returned `[]`.
**Reproduction:** `arms = [healthy_async_warmup]; status, reason = derive_validation_status(arms)` returns `("INVALID", "fixed_schedule_stopped_early_or_changed")`; with otherwise valid receipt bindings, `check_validation_receipt(receipt) == []`.
**Fix:** Require an incomplete schedule to contain a separately validated terminal raw failure (or a recorded overall deadline condition supported by elapsed timing). Reject incomplete schedules with only healthy arms. Add the exact one-arm mutation above to `--self-test`.

### CR-03: Receipt hashes can describe committed runner/formatter bytes that were not observed

**File:** `tools/exunit_boundary_probe.py:367-368, 636-638, 810-812`
**Issue:** `run_child` writes the current worktree versions of `ELIXIR` and `FORMATTER` into the mounted container, but preflight and run receipts hash those paths from committed Git blobs. Only the coordinator's current bytes are compared with its committed blob before the run. A dirty or replaced runner/formatter therefore executes while the receipt claims different, committed bytes. The verifier repeats the Git-blob comparison and cannot detect the mismatch.
**Fix:** Load runner and formatter bytes once from the committed head, verify their hashes, and pass those exact byte strings to every child. Alternatively, fail closed unless current file bytes match the recorded committed hashes before any child launches. Add mocked tests that alter each worktree file and prove no child is started.

### CR-04: Pair-level invalidity does not stop the schedule before later observations

**File:** `tools/exunit_boundary_probe.py:567-604, 835-853`
**Issue:** The run loop checks only per-arm structural validity and control deltas. Pair-sign consistency and per-mode MAD are checked only after the entire schedule, including both controls, has run. An inconsistent second pair or a noisy third pair therefore still launches later pair/control children despite the plan requiring an immediate terminal `INVALID` stop with no new arm.
**Fix:** Recompute the cumulative pair checks after each completed pair and stop before launching the next pair or control as soon as inconsistency/noise is provable. Keep the final verifier's full-schedule recomputation, and add mocked `run_child` tests asserting no subsequent arm runs after the first detectable failure.

### CR-05: The run trusts unverified preflight claims and executes its supplied image ID

**File:** `tools/exunit_boundary_probe.py:723-730, 786-802`
**Issue:** `execute_validation_run` accepts a preflight if its schema, status enum, and historical hash map look valid. It does not verify the preflight's producer, runner/formatter hashes, runtime fields, or that its image was inspected under the expected tag. `check_validation_receipt` checks only the preflight's schema/hash-map/status/image equality. The run then takes `image = preflight["image"]` and launches that ID. A forged preflight with `status: VALID` and an arbitrary image identity can bypass the preflight checks; the final verifier does not establish that the supplied ID/digest came from the expected cached image.
**Fix:** Validate every preflight field against its committed producer/runner/formatter hashes and expected Elixir/OTP/architecture, enforce the expected tag and immutable image ID/digest, and re-inspect the same image ID before launch (and after observation) without pulling. Add a mutation test for a forged `VALID` preflight with wrong source/runtime/image metadata.

### CR-06: Collection and child timing claims are not verified against the cap

**File:** `tools/exunit_boundary_probe.py:672-773, 805-818, 853-859`
**Issue:** The receipt records UTC collection bounds, `elapsed_ms`, and per-arm `duration_ms`, but `check_validation_receipt` does not validate timestamp format/order, compare elapsed time with 150 seconds, or enforce the 15-second per-child limit. A modified receipt with reversed/malformed collection timestamps and arbitrarily large elapsed/arm durations can still pass if its report projection is updated. The cap is a condition of the scope decision, so the verifier currently cannot establish that an accepted receipt stayed within it.
**Fix:** Record monotonic collection start/end and validate elapsed against both those values and the 150-second bound; require each arm's duration to be within 15 seconds (allowing only explicitly documented cleanup accounting). Reject missing, malformed, reversed, or over-budget values. Add timestamp-substitution and over-budget duration mutations.

### CR-07: A failed/interrupted run leaves no write-once reservation, allowing a second series

**File:** `tools/exunit_boundary_probe.py:782-795, 832-859`
**Issue:** The output is checked for nonexistence before observation, but the first write occurs only after the schedule completes. If the process is interrupted or an exception escapes during a child/cleanup, the receipt remains absent. A second `--run` with the same approved decision and preflight passes the same nonexistence check and can launch a replacement series, although the plan authorizes exactly one and forbids replacement samples.
**Fix:** Atomically create a write-once series reservation/`IN_PROGRESS` receipt before launching any child and transition it to a terminal state in a `finally` path. Treat any existing reservation, including interrupted/incomplete, as consumed authorization and refuse a rerun. Add a mocked child-exception test proving a second invocation cannot launch.

## Warning

### WR-01: Timeout cleanup can escape without a terminal receipt

**File:** `tools/exunit_boundary_probe.py:413-429, 843-859`
**Issue:** After timeout, the fallback `proc.communicate()` has no timeout, and `docker rm -f` may raise `TimeoutExpired`. Either path can escape `run_child`; the CLI reports failure but `execute_validation_run` never writes its terminal receipt. The owned container may also remain. This compounds the rerun problem in CR-07 and can exceed the stated overall cap during cleanup.
**Fix:** Bound every cleanup wait, capture cleanup failures on the arm, continue to a terminal `INVALID` receipt, and make the overall deadline include termination/removal time. Test with mocked `communicate` and `docker rm` timeouts.

## Verification performed

- `python3 -B .../exunit_boundary_probe.py --self-test` — passed (`synthetic round-trip PASS`).
- `python3 -B .../exunit_boundary_probe.py --verify .../247-LOCAL-CANARY.json --report .../247-LOCAL-CANARY.md` — passed (`INVALID; 1 attempted arms`).
- `python3 -B -m unittest discover .../tools -p 'test_exunit_boundary_probe.py' -v` — passed (one parser-order test).
- `python3 -B .../exunit_boundary_probe.py --preflight --output /private/tmp/should-not-exist.json` — reproduced the argparse exit 2; no preflight or Docker command ran.
- A fully bound synthetic receipt truncated to one healthy warmup was accepted by `check_validation_receipt` with no errors, as described in CR-02.
- Worktree status showed only the pre-existing `.planning/STATE.md` edit; no source or historical receipt was modified.

## Remediation dispositions

**Disposition:** All findings addressed in remediation commit(s); verified with pure and mocked checks only. No Docker preflight or observed ExUnit child was run.

| Finding | Disposition and evidence |
| --- | --- |
| CR-01 | Fixed CLI mode validation to dispatch standalone `--preflight --output` and `--run --preflight FILE --output`; mocked CLI dispatch tests pass in `python3 -B -m unittest -v test_exunit_boundary_probe`. |
| CR-02 | Healthy incomplete schedules are rejected; terminal early-stop reasons must be supported by raw child/pair/control evidence, or a measured overall deadline. One-arm healthy truncation negative control passes. |
| CR-03 | The run loads runner and formatter bytes from the committed producer snapshot, checks the worktree files are clean at preflight, and writes those exact bytes to each child mount. Dirty-runner and dirty-formatter controls prove no child starts. |
| CR-04 | Cumulative pair sign/MAD checks run immediately after each complete pair and halt before subsequent arms. Mocked pair inconsistency test confirms six arms only, with no later pair or controls. |
| CR-05 | Preflight validation checks producer/source/runner/formatter hashes, runtime versions/architecture, expected image tag and immutable ID/digest; the run re-inspects before and after. Forged source/runtime/tag/ID/digest mutations are rejected. All checks used mocks; image metadata was not inspected live. |
| CR-06 | UTC and monotonic collection clocks, elapsed agreement, overall deadline and child/cleanup duration caps are validated. Timestamp substitution and over-cap mutations are rejected. |
| CR-07 | A distinct write-once `.reservation.json` sidecar is atomically created before any child launch; terminal receipt is emitted in `finally`; a mocked child exception leaves both artifacts and prevents retry. The sidecar is retained as terminal authorization-consumption evidence. |
| WR-01 | Timeout, TERM/KILL waits, and owned-container removal are bounded; cleanup failures are captured on the arm and do not bypass terminal receipt generation. Mocked timeout controls verify bounded waits. |

### Remediation verification

- `python3 -B -m unittest -v test_exunit_boundary_probe` — passed, 11 tests.
- `python3 -B exunit_boundary_probe.py --self-test` — passed (`synthetic round-trip PASS`).
- `elixir .../tools/exunit_boundary_case.exs --trace-self-test` — passed; starts no ExUnit.
- Saved receipt and report: `--verify .../247-LOCAL-CANARY.json --report .../247-LOCAL-CANARY.md` — passed (`INVALID; 1 attempted arms`).
- Original receipt, preflight, and frozen replay SHA-256 assertions — passed unchanged.

## Independent Re-review: remediation commit `6b54154d`

**Scope:** The same two tool files, compared against CR-01–CR-07 and WR-01 above.
**Safety:** Pure/mocked Python only; no Docker command, preflight, or observed child was run.
**Conclusion:** CR-01, CR-03, CR-04, CR-06, CR-07, and WR-01 are closed by the remediation. The healthy-truncation case in CR-02 is also rejected. Two concrete verifier gaps remain before the receipt contract is complete.

### CR-08: Arbitrary `run_failure` metadata bypasses raw-failure verification — BLOCKER

**File:** `tools/exunit_boundary_probe.py:964-976, 996-1002`
**Issue:** When `run_failure` is present, the verifier checks only that its arbitrary `type` matches the result string and that `message` is non-empty and bounded. This skips normal status derivation and the no-raw-failure rejection. A forged zero-arm receipt with `run_failure = {"type": "FakeFailure", "message": "forged text; no child/runtime/inspection failure"}` and result `INVALID/run_failure:FakeFailure` passes `check_validation_receipt` with no errors.
**Reproduction:** Starting from a passing mocked receipt, set `arms=[]`, `attempted_count=0`, `result={"status":"INVALID","reason":"run_failure:FakeFailure"}`, and the matching `run_failure` object above. `check_validation_receipt(receipt, receipt_path)` returns `[]`.
**Fix:** Restrict `run_failure.type` to explicit producer failure cases and require each case's matching captured evidence (for example, inspection mismatch fields or a recorded exception from a child launch). Reject unknown types and a zero-arm failure with no corresponding evidence. Add this exact forged-run-failure mutation to the self-test.

### CR-09: Verifier accepts a preflight from a different producer commit — BLOCKER

**File:** `tools/exunit_boundary_probe.py:707-747, 862-923`
**Issue:** `validate_preflight` verifies the preflight's producer and source internally, but `check_validation_receipt` never requires that preflight source/producer commit equal the validation receipt's source/producer commit. The run command enforces that equality before launching; the verifier does not, so a valid preflight from a different committed producer can be attached to an otherwise valid receipt and still pass.
**Reproduction:** I generated a complete mocked VALID receipt at `6b54154d`, changed its preflight to the valid `856361c4` producer/commit and matching committed runner/formatter hashes, then updated the receipt's preflight hash and reservation binding. `validate_preflight` returned `[]` and `check_validation_receipt` returned `[]` while receipt and preflight source heads differed.
**Fix:** In `check_validation_receipt`, require the preflight's `source.head` and `producer.commit` to equal the validation receipt's `source.head` and `producer.commit`, and require the preflight producer hash to equal the receipt producer hash. Add a cross-commit preflight mutation control.

### Re-review verification

- `python3 -B -m unittest -v test_exunit_boundary_probe` — passed, all 11 mocked tests.
- The truncated healthy schedule negative control is covered and passes; no source or historical evidence was changed.
- The two reproductions above use temporary mocked receipts only and demonstrate the remaining gaps.

## Final verifier remediation

The two re-review reproductions now have dedicated regression tests. A preflight's source, producer and runner/formatter hashes must equal the validation receipt's bindings. Generic software exceptions retain the terminal receipt and consumed reservation, but fail receipt verification with `run_failure_has_no_verifiable_raw_failure`; arbitrary exception text cannot certify a measurement. Image-identity failures require actual differing inspection records. An internal exception therefore remains an unverified terminal diagnostic and cannot reopen the observation grant.

Verification: both regressions failed before the implementation change (RED commit `181e66c8`); all 13 mocked tests and the synthetic receipt/report round trip pass after it. Historical receipt/report verification and trace-only self-test remain required at the checkpoint. No Docker command or observed ExUnit child ran.
