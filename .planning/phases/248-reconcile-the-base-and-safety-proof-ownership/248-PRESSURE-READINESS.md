> Historical readiness only. The instrumented diagnostic grant is consumed by a first-suite formatter timeout. Current correction, stopped resources and the unapproved plain acceptance proposal are in [248-OVERLAP-READINESS.md](248-OVERLAP-READINESS.md). No old snapshot grants another run.

# Phase 248: Diagnostic repeat readiness

The latest approved plain repeat failed after three clean suites: five file-operation timeouts in iteration 4. Its grant was consumed. Current corrected ordinary-root checks pass, but the cause and a reliable speedup remain unestablished; Plan 248-04 and ADM-04 remain incomplete. [Current proof](248-FILE-PRESSURE-PROOF.md), [review](248-NEGATIVE-PREMISE-REVIEW.md), [failed repeat](248-INVENTORY-REPEAT-RECEIPT.json).

## Recommended next action and its consequence

Approve exactly one **instrumented diagnostic invocation** of the existing nine-run alias to capture the file-server state while a timeout develops. It retains test selection, assertions, exclusions, repeat count, fresh per-suite seeds, property scale 5, max-cases 36 and the existing classifier. A silent private formatter records only the five affected modules' test timing/state, plus file-server status/function/stack/reductions/queue and scheduler run queue every 250 ms. It does not collect mailbox payloads or alter the repository.

The diagnostic runs in the background with a **55-minute limit plus 60-second termination grace**, using only the verified task-owned PostgreSQL 15.17 service at 100 connections. No parallel database suite, foreground focus, shared-service modification, automatic next repeat, fresh canonical/browser invocation or external action is included. PostgreSQL is currently stopped and will be restarted only within a new grant.

```text
THREADLINE_PROPERTY_SCALE=5 timeout --signal=TERM --kill-after=60s 55m elixir -r <private-observer.exs> -S mix verify.flake --formatter ExUnit.CLIFormatter --formatter Threadline.LocalFileObserver
```

The observer can perturb scheduling and timing. **A green instrumented result is diagnostic evidence only and does not replace the required plain nine-run acceptance gate.** No seed is pinned; each actual seed is recorded. True command/capture exits, normal CLI counts, existing classifier, source freeze and resource limit remain authoritative. Failure or timeout consumes the grant; it does not authorize an automatic retry.

## Preparation evidence

- Current reviewed source: `9b695ca25b41be882902ddfb06716141e5a462db`; 33 source identities and 22 protected identities bound to the private proposal; later commits limited to phase evidence.
- Corrected fixture focused check, formatting, strict Credo and one ordinary root pass; controlled wrapper-removal mutant fails as expected. Full details and hashes: [current receipt](248-NEGATIVE-PREMISE-RECEIPT.json).
- Independent instrumentation review found and corrected unsupported `--require` to installed CLI `-r`. It also confirmed that pinning a seed would change the alias's seed policy; the proposed run remains unseeded. Instrumentation remains diagnostic only.
- Offline one-test Mix fixture: nine normal CLI headers, nine clean summaries, nine distinct observation directories and nine suite start/finish pairs; UTF-8 names retained; true exit 0 in 0.82 seconds. This was collector lifecycle QA, not a Threadline repeat. Earlier missing-tool-version and unsupported-flag fixture attempts are preserved privately; no actual candidate repeat was made.
- Observer digest: `09199b6132e45cd326a23dcc87114cfae367a01ff3a362dbe73ec6d558830edc`.
- Concrete private proposal digest: `876854ff343434c204312f67196662550ba974c3bb652d89e842a1cca20936c4`.
- Authorization is false; no new consumed token or actual Threadline repeat exists. Owned PostgreSQL is stopped after ownership and zero-client checks; shared services untouched.

## Next actor

The user decides whether to grant this one diagnostic invocation. The agent then runs only that bounded diagnostic, investigates its captured result and preserves the ordinary acceptance gate. Formal post-gates and phases 249–253 stay pending. No instruction to acknowledge a stopped state is required.
