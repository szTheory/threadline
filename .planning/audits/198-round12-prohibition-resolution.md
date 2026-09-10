# Phase 198 Round 12 prohibition resolution

This append-only ledger types the two Plan-53 and three Plan-55 prohibitions without rewriting
the completed round-11 record. The immutable inputs are pinned as follows:

| Input | SHA-256 |
|---|---|
| `.planning/audits/198-round11-ref-disposition.json` | `6b39204b95dcf1dbd42c6885bd4d0d0f6c861ef4d7286b18822edf6c721c6591` |
| `.planning/audits/198-round11-ref-disposition.md` | `70589513acd68de861d74f928ec302a6b455ad0e5c548b3383fa723c50b0ef19` |

## Typed prohibitions

| ID | Source | Tier | Status | Mechanical evidence |
|---|---|---|---|---|
| `P-198-53-01` | Plan 53 | test | pass | `round 11 authority rejects silence, preserve, abort, stale digests, missing subjects, and outsiders`; production fixture-boundary rejection |
| `P-198-53-02` | Plan 53 | test | pass | distinct same-name side/SHA subjects plus collapsed-side rejection |
| `P-198-55-01` | Plan 55 | judgment | **pending** | none — exact historical command operands are not recoverable from final state or narration |
| `P-198-55-02` | Plan 55 | test | pass | delete-before-preserve and incomplete divergent preservation rejection |
| `P-198-55-03` | Plan 55 | test | pass | final-state fixture rejects GREEN-07 promotion |

All mechanical evidence is from the passing command
`mix test test/threadline/phase198_ref_disposition_contract_test.exs`. The JSON ledger retains
the byte-for-byte source statements, exact test names, results, and round-11 threat mappings.

## Historical evidence limitation

Round 11 records final refs, abstract operation receipts, and summary narration. Those facts do
not establish which command operands were typed. This round-12 record therefore supplies no
retrospective command arrays, refspecs, force state, per-operation timestamps, exit statuses, or
before/after identities. The completed round-11 files remain unchanged.

Plan 59 may resolve `P-198-55-01` only through a separate blocking-human record containing the
maintainer's verbatim response, record time, signer, and either `attested` or `cannot-attest`.
A cannot-attest response leaves the prohibition open. Neither outcome accepts risk.

## T-198-55-03 disposition

`T-198-55-03` is **open**, **not accepted**, and classified
`irrecoverable_below_threshold`: its medium severity is below the configured high blocking
threshold, so it is excluded from the canonical blocking `threats_open` count without being
closed. Its missing historical receipt fields are argv, per-operation timestamps, exit status,
and before/after identities. Only a truthful attestation supplying every missing field can close
that finding; resolving the broader command-method prohibition alone cannot.
