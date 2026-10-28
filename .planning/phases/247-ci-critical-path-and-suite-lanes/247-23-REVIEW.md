---
phase: 247-23-local-canary-recheck-prerequisites
reviewed: 2026-10-27T17:07:25Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs
  - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py
  - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/test_exunit_boundary_probe.py
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 247-23: Code Review Report

**Reviewed:** 2026-10-27T17:07:25Z  
**Depth:** standard  
**Files Reviewed:** 3  
**Status:** clean

## Summary

Re-reviewed the corrections in `9fae282d` against the four findings from the original review of `c16f1e28..391380c5`. All four are fixed in the current code. The fixes bind the executing coordinator bytes to the committed producer before reservation and at later validation, require an exact candidate-bound grant, stop after the first invalid arm, and support a verified write-once report for invalid preflight evidence. The correction added behavioral mock controls for each path. No new source-code finding surfaced.

The exact pinned Elixir/OTP compile and real Docker ownership remain empirically untested. Historical CR-05 and WR-04 therefore remain open on that evidence dimension; this re-review does not claim they are empirically closed.

## Resolved Findings

### CR-01: Running coordinator source binding — FIXED

**Fixed in:** `9fae282d`  
**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py:1753-1782`

The binding now loads the committed coordinator and rejects when the executing `Path(__file__)` bytes differ, before reservation/Docker work. Validation repeats this check for preflight, run, and verification paths. The new mock mutates the coordinator on disk and verifies refusal before reservation or image inspection.

### CR-02: First semantic failure must stop the series — FIXED

**Fixed in:** `9fae282d`  
**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py:1916-1938, 2154-2170`

Each child now passes through runtime, event, formatter, control, and ownership checks immediately. Any failure writes a terminal early-stop reason bound to the last arm and prevents another child launch. The zero-exit invalid-first-arm mock asserts one launch and an `INVALID` receipt.

### CR-03: Incidental decision text must not authorize a run — FIXED

**Fixed in:** `9fae282d`  
**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py:1740-1750, 1801-1809, 2111-2120`

Authorization now requires exact document equality, including an affirmative decision, the current full `HEAD`, the fixed schedule, and all caps. It is rechecked before execution. Tests reject negation, duplicate/incidental marker text, extra text, a mismatched candidate, and a missing candidate before reservation or Docker calls.

### WR-01: Invalid preflight report path — FIXED

**Fixed in:** `9fae282d`  
**File:** `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py:1001-1009, 1707-1737, 2033-2061`

The renderer now accepts either the final recheck receipt or the canonical invalid preflight. Invalid preflight projection explicitly records zero attempted arms, retains raw failure details, and is verified against the same projection. Valid preflight cannot be rendered as a terminal report. Tests verify render, report verification, and write-once refusal.

## Verification

- `python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/test_exunit_boundary_probe.py` — 25 tests passed.
- `python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py --self-test` — synthetic round-trip passed.
- Historical `247-LOCAL-CANARY.json` and `247-LOCAL-CANARY-VALIDATION.json` plus its report verify successfully as terminal `INVALID` under their original producer contract.
- No Docker, Elixir, Mix, native compiler, CI, installation, network access, or timing observation was used.

## Plan 24/25 Invocation Contract

The current CLI requires this exact decision file content, with no extra lines or metadata:

```text
Decision: authorize-one-recheck-series
Source-Head: <full current git HEAD>
Schedule: warmup=async,sync;pair=async/sync,sync/async,async/sync;control=pre_exunit,setup_all
Limits: child=15s,total=150s;warmups=2;controls=2;series=1
```

The candidate binding field is `Source-Head`; a separate `source_sha` field is not required. Because the parser compares the complete file to this canonical text, Plan 24's current instruction to also include a UTC date and the source of the maintainer's answer would make the decision fail validation. Plan 24/25 should align their file writer and precondition with this exact contract, or the parser must be deliberately extended before authorization.

Use these modes and canonical output paths:

```sh
python3 .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py \
  --recheck-preflight --output .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK-PREFLIGHT.json

python3 .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py \
  --recheck-run --preflight .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK-PREFLIGHT.json \
  --output .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK.json

python3 .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py \
  --render-report .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK.json \
  --output .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK.md

python3 .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py \
  --verify .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK.json \
  --report .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK.md
```

If preflight is `INVALID`, do not run `--recheck-run`; render and verify the preflight directly with `--render-report <...RECHECK-PREFLIGHT.json> --output <...RECHECK.md>` and `--verify <...RECHECK-PREFLIGHT.json> --report <...RECHECK.md>`. The implementation's preflight performs cached image inspection and one full-runner compile smoke; the Plan 25 text's “at most two runtime/version probes” is a ceiling and does not require two separate version children.

---

_Reviewed: 2026-10-27T17:07:25Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
