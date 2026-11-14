> Historical readiness snapshot. The newly approved plain invocation passed all nine suites; its grant is consumed, not renewed. [Passing receipt](248-PLAIN-REPEAT-RECEIPT.json) and [current summary](248-04-SUMMARY.md) supersede earlier pending/failure status. Formal phase checks continue without a new user action.

# Phase 248: Plain repeat readiness after the diagnostic

The approved diagnostic failed in its first suite with one formatter timeout. Its grant is consumed. The observed file server continued processing queued work; no exclusive cause is established. The synthetic overlap control also traversed 106 files irrelevant to its one-file ownership assertion, including 97 dependency/build results. That fixture is now narrowed to the exact representative, and its existing focused check, formatting, lint and both private negative controls pass their intended expectations. Independent review has no active findings. [Proof and limits](248-OVERLAP-PROOF.md), [diagnostic receipt](248-INSTRUMENTED-DIAGNOSTIC-RECEIPT.json), [review](248-OVERLAP-REVIEW.md).

## Recommended next action

Approve exactly one **plain nine-run acceptance invocation**, in the background, with **property scale 5, max-cases 36, 55 minutes plus 60 seconds termination grace**. Use the existing unmodified `mix verify.flake` alias, fresh seeds, normal formatter and classifier; no private observer is loaded. The proposal does not alter assertions, exclusions, async settings or timeouts. It does not include any automatic subsequent repeat, indirect repeated-root loop, canonical/browser run, hosted dispatch, push, merge, version change or publication.

```text
MIX_ENV=test THREADLINE_PROPERTY_SCALE=5 timeout --signal=TERM --kill-after=60s 55m mix verify.flake
```

The concrete runner retains actual suite/capture exits, the normal classifier, nine header/clean-summary checks, source freeze and the strict time limit. It uses only the verified task-owned PostgreSQL 15.17 instance at 100 connections, with no parallel database suite. The instance is currently stopped and will be restarted only for an approved run, then stopped after terminal/zero-client checks. Shared services remain untouched.

This is the required plain acceptance attempt, not a claim that the fixture change eliminated all shared-suite pressure. It can still fail or reach its cap; either consumes the single grant. No current full-root, nine-run or full CI toolchain-matrix pass exists. Earlier canonical/browser evidence retains its source and retry limitations. Plan 248-04, ADM-04 and formal post-gates remain incomplete.

## Bound candidate and authorization

- Reviewed source: `ce0c2e30d0b7401b3b35df21dcd986ad9ed8cafb`; later candidate commits may change only Phase248 metadata.
- Current 33 reviewed source hashes and 22 protected identities are bound to the proposal; source recheck uses 32 exact prior reads plus the changed file in full.
- Private proposal SHA-256: `1bab4539851e9935e488f1c7dc5d693f3b4748befdf6157be655bf6fe940ec78`.
- Authorization is false; no new consumed token or plain invocation exists.

The user acts next to decide this one new grant. The agent is waiting at the resource boundary and will resume the original phases 248–253 objective after actual acceptance and required post-gates. No acknowledgment is required merely to keep the current stop in place.
