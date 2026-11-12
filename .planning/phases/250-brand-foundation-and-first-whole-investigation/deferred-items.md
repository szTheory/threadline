# Deferred Items

- Existing rendered-output receipt mismatch: `RenderedOutputContractTest` expects 118 elements and digest `baf2ca11fb3c1a3d0a91a9238bad66472bf7453b30f4a8f50b44c864fb80bac0` for `row_history.shell`; the current renderer produces 116 elements and digest `1527bbb72674a8b5e493c2e9242ef257479ccf44412ae3f50698b112cb19bdb6`. The same mismatch reproduces with the Plan 07 row-history source files restored to their pre-task versions. Do not regenerate the receipt as part of Plan 07; parent should assign a focused investigation before phase verification.

## Resolved by parent integration

The failed gate was kept pending, then causally isolated: restoring only the prior header/logo made all seven historical structure receipts pass. Exact current source was restored. The approved Plans02/04 artwork and immediate theme controls explain the net118→116 shell elements. [The existing corpus test](../../../test/threadline/operator_surface/rendered_output_contract_test.exs) now preserves the historical map and changes only its current row_history.shell pin; all other pins and mutation controls remain. The combined affected suite passed243 tests with no failures, alongside compile/format checks. [Plan07 summary](250-07-SUMMARY.md) records the source and proof limits. No unresolved item remains here.
