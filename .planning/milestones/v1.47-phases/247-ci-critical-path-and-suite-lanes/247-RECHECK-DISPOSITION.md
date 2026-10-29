# Phase 247 Local Recheck Disposition

## Independent review

- **Reviewer:** `/root/execute_247_25/review_24725_receipt` (`gsd-code-reviewer`; dispatched as GPT-6.1 Sol, xhigh).
- **Review source:** independent automated review, read-only; no Docker or network access used.
- **Reviewed report body SHA-256:** `4e75fa26c3276201c6c55cbbc3fdb4d6f8461980977f4dc8d8a526106907b2f8` (exact UTF-8 bytes of `247-LOCAL-CANARY-RECHECK.md` before this disposition).
- **Exact-source limitation:** No exact Elixir 1.15.8 source-text snapshots for `Mix.Compilers.Test`, `ExUnit.Case`, `ExUnit.Server`, or `ExUnit.Runner` were found in this repository or its cached research. The reviewer consulted local `247-NEXT-MEASUREMENT-RESEARCH.md`, `247-NEXT-SYNTHESIS.md`, and the Plan 22 review, which cite those versioned upstream files and summarize async-run → parallel-require → await, case registration, server queues, and runner scheduling. Those are existing research conclusions, not newly inspected primary-source text. This preflight launched no ExUnit arm, so it observed none of those semantics.

### Reviewed input SHA-256

| Input | SHA-256 |
|---|---|
| `247-LOCAL-CANARY-RECHECK-PREFLIGHT.json` | `505ceeb7c9357d2eec1e6f0d3d5e0b39a4e1bb822319cc5ec7b61f49e5a0d2d7` |
| `247-LOCAL-CANARY-RECHECK.md` | `4e75fa26c3276201c6c55cbbc3fdb4d6f8461980977f4dc8d8a526106907b2f8` |
| `247-LOCAL-CANARY-RECHECK.reservation.json` | `c7c0aa1f1a45ce6fd2f557628afeb04b02f03641fdc03a6edaf6b4e14f93ebd5` |
| `247-LOCAL-CANARY-RECHECK-DECISION.md` | `72bbd731eb7457f41fdbd684d7d4ca1bb180a6046d442b4be843003dcef9a725` |
| `247-LOCAL-CANARY-RECHECK-AUTHORIZATION.md` | `cba041a5abd95c88bf49c8f05e00c0e5b79756b600e25baddfab254eadd36476` |
| `247-LOCAL-CANARY-VALIDATION.json` | `2be63b2ac0894f17321f437ffa839b4c36333f0af0d4f9392eee707322214f93` |
| `247-LOCAL-CANARY-VALIDATION.reservation.json` | `290f7325a6797854a38039014cc7db0d96e6241bee33e89eb806e62ec2638a62` |
| `247-LOCAL-CANARY.json` | `7a946173a6e4c9ca407d94d766343596f77980eaf01eb0ad353985e85b171385` |
| `247-LOCAL-CANARY-PREFLIGHT.json` | `728d8c8efa6fd88c6124c0c1745bcd0a26b00c4b61ebbcd25c7135aa607bb553` |
| `247-FROZEN-REPLAY.json` | `5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1` |
| `247-B4-INCOMPLETE.json` | `4a4a9b237afbd3565d59dd15eb6d8083a77fc92f033302e3780d4cb3a488fe7f` |
| `247-VERIFICATION.md` | `51c8ccf2422e23d23fcb51c3178c2178a6332d38b19ac33cc3b2fa1b1ca01d5b` |
| `247-LEARNINGS.md` | `76ba172e459178433c612b3b78251f8ca2e5e3b50e48cbcfa324cef0304128e3` |
| `247-NEXT-MEASUREMENT-RESEARCH.md` | `42c9ce65a4b3a671e31fd0eb61fdc368af0a2bd7471ee3d5b2e786468501e384` |
| `247-NEXT-SYNTHESIS.md` | `020547c19d51211f75a6e3b098545ca933bac522f1c1d7a648305571aeb62307` |

## Findings and disposition

- **Terminal result: `INVALID` preflight; zero ExUnit arms and no series receipt.** The cached pinned ARM64 image reported Elixir 1.15.8 / OTP 26.2.5.21. The complete runner compile-smoke child exited 0 and printed `THREADLINE_COMPILE_SMOKE|ok`, but stderr contained `warning: variable "mode" is unused` at `probe/runner.exs:140`. The producer classifies any compile-smoke stderr as `compile_smoke_stderr_present`, so the strict preflight is INVALID. This is a warning-only strict-stderr failure, not the earlier Plan 22 OTP compiler crash. No source repair, rerun, or replacement was made. The terminal preflight JSON is the raw receipt; the report projection verifies.
- **Container ownership for this run is verified.** Captured CID `59470909f5d3d36400f5e5e87496af2e8d0beeb21d135bf4a48e1c01b3828ef7` inspected as `/threadline-24723-c0183c8315a0`; inspection and CID-only removal both exited 0. `retained_unverified=false`. WR-04 ownership evidence is satisfied for the sole Plan 25 child; this does not retroactively fill Plan 22's historical missing CID/name evidence.
- **Compiler gate:** CR-05 remains open because the strict compile-smoke result is INVALID despite the success marker and zero exit. Do not treat the marker alone as a valid preflight.
- **Timing provenance limit:** the raw preflight has no start/end or elapsed-duration fields for the child/preflight. The launcher enforces its timeout, but the receipt cannot independently establish elapsed-time compliance. Record this limitation; no extra check or launch was performed.
- **Verification limit:** `--verify` passed for the INVALID preflight, but its verifier recomputes compiler/runtime/ownership predicates only for a VALID preflight. The independent reviewer manually compared the INVALID reason to the raw warning and producer classification. The verifier pass by itself is not evidence that the invalidity reason is correct.
- **Historical inputs:** the original canary, original preflight, frozen replay, Plan 22 INVALID receipt, and Plan 22 reservation match their previously recorded hashes. No historical status was altered. Historical AMD64 cause remains **UNPROVEN**.
- CI-01 and CI-04 remain VERIFIED. CI-02 remains **INCOMPLETE**: B4 still has four qualifying successes and two failed exclusions, so `median_wall_s=null`. CI-03 remains **MISS** at fixed B4 min ratios `1.24/1.28/1.27`. Diagnostic run `40504321590` remains off main. Phase 247 remains **2/4**.

## Remaining main-CI route

1. A separately scoped decision must select a concrete CI-03 candidate based on fixed B4 residuals and locally verified fixture/source changes. A local canary result must not trigger automatic model or weight changes.
2. A separate explicit maintainer grant must authorize landing and a new bounded main cohort. That cohort must produce five qualifying successes for the CI-02 median and three consecutive ratios per lane for CI-03.

The exhausted B4 and diagnostic caps do not roll over. This disposition requests or runs no future cohort.
