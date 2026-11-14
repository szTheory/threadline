# Phase 248-04 clipboard failure proof follow-up

## Scope and previous canonical result

This follow-up addresses only the first-attempt flake in `Clipboard failure shows manual recovery without claiming success`. The isolated canonical run on source `ab65c0147ad7bf58e7d3b2394c55514868c2bec5` exited 0 in 1,427 seconds, with the root suite at 3,400 tests / 0 failures, the example suite at 132 / 0, Dialyzer at 0 errors, and the live slice at 17 / 0. Its desktop/mobile browser result was **417 first-attempt passes, one retry-passed clipboard flake, and 56 configured skips**. That is not a clean 418-pass result. No canonical run was repeated after the test edit.

The original first-attempt `error-context.md`, full canonical log, and public receipt were snapshotted privately before later Playwright invocations could replace test output. The private snapshot manifest SHA-256 is `7ff79e0bc66aaf00ef6e95594931709dd2123b261aa1df9ac8324a087dbf7099`. It binds:

- Error context: `15a579cc832e6a755b9a1f47d022ab2d3cb52e88b9118f002abb6e1ab730e7e2`
- Canonical log: `a6bffa528adf26a6a9e29020bc2d6483418b3eb833fdaaafc9be9013eed9d52b`
- Portable canonical receipt: `4b0c7b90db52201ec399b1fb5c850ffa505f7d2abb7eb22e8e405ab8a7160462`

The error context records the button as inactive at the `toBeFocused` assertion after its 15-second wait. The case had trace and screenshot disabled, so there is no chronology proving why focus was lost. The browser log records the first-attempt failure and retry-1 pass. The case is absent from the required journey inventory and is not credited as clean required-journey evidence.

## Test-only change and source binding

In `operator-route-states.spec.ts`, the clipboard-failure test now waits for `[data-phx-main]` to have class `phx-connected` immediately after direct navigation and before locating/clicking the copy control. This matches the adjacent clipboard cases. No existing postcondition, fixture, title/ID, global retry, timeout, tag, trace setting, product code, markup, stylesheet, asset, or inventory changed.

The original spec SHA-256 was `ac1c6341555fb021a1b0176eb7785692adc71bcc33e6304e5341fabb7639b4d1`. The one-line candidate source used for the focused runs had SHA-256 `ac640f7ba157c04976cfa917805e50bc5cd1a4c6843b51065ea749af69e9b5a7` and was committed unchanged as `ac260b47cc642d0a62cdca30e07ea6bfc863e1db`. Test wrappers record base HEAD `ab65c0147ad7bf58e7d3b2394c55514868c2bec5`; no source edits occurred between verification and the code-only commit.

Protected production and policy identities remained unchanged:

| File | SHA-256 |
|---|---|
| `lib/threadline/operator_surface/script.ex` | `168baaa726aa1ab4f846af78bb2f11864e575dc70c1fe17d3aee16c80f47985a` |
| `examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts` | `58d319900b98c9a10c0790c8dae8c690eec7b574d66adaba49330ec170b222ce` |
| `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json` | `ecd6dfcddc461c8b31d86c2faea14e8990a675e9b18c367d0bbce564ffd06efa` |
| `examples/threadline_phoenix/e2e/package-lock.json` | `b6a4ce7846424aa819a7b6e74aad244442cfdb5b7ad10d2d84916bf15babbcdd` |

## Bounded verification

All browser checks used task-owned PostgreSQL 15.17 on loopback with `max_connections=100`, C/C locale, UTF-8, and America/New_York timezone. The service recorded 282 connection samples, a peak of 77 clients, and zero sampling errors. The shared PostgreSQL service was not modified. This is supported-floor database evidence, not the complete minimum/current/latest CI matrix.

| Command | Result | Log SHA-256 |
|---|---|---|
| `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium tests/operator-route-states.spec.ts:269 --retries=0 --repeat-each=3` | Exit 0, 17 seconds; six target invocations passed (three per project), 39 Playwright unit-precheck tests passed | `280769f525550d5ae18f0b17b2bb442a4d3a0600b991d6edbe7784a15c1826de` |
| `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium tests/operator-route-states.spec.ts --retries=0` | Exit 0, 35 seconds; 52 test instances, 41 passed, 11 configured skips total across both projects; no retries; 39 unit-precheck tests passed | `5b425cf6507556e09c0ec444c2752d3cf0c720f08e54f12a07b7dba35769ba0c` |
| `mix test test/threadline/browser_journey_evidence_contract_test.exs --seed 876664` | Exit 0; 9 tests, 0 failures | `ef1ac4b617951915de2c131f953f2c160cada3678a7fcd7b70b80d007801047c` |
| `python3 .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/verify-candidate-baseline.py --check-inventory --self-test` | Exit 0; all 15 checks passed | `110fcd973d26c6caaa829d1010280a0f595ee357a4c18853df9c1e97a0fc7d26` |

The E2E package has no standalone TypeScript formatter/linter script. Its Playwright runner transpiled and executed the changed file; `git diff --check` passed. The runner used the existing E2E lock and prepared npm/browser caches; the E2E lock hash did not change.

## Limits and status

The added wait establishes the clipboard failure behavior after the page reports `phx-connected`. It does not test a copy attempt before that boundary and does not prove the cause of the original focus loss. The six target passes and one affected-spec run are not a full browser suite or a full canonical result.

The nine-run full repeat remains failed (six clean, then formatter timeout on iteration 7) and no further repeat is authorized. Plan 248-04 remains halted and ADM-04 incomplete. No fresh canonical suite, full-root repeat, or broad browser run was performed after this one-line change. The task-owned PostgreSQL service remains running for the parent to stop; this worker did not stop it or alter the shared service.
