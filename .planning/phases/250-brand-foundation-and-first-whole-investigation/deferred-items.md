# Deferred Items

- Existing rendered-output receipt mismatch: `RenderedOutputContractTest` expects 118 elements and digest `baf2ca11fb3c1a3d0a91a9238bad66472bf7453b30f4a8f50b44c864fb80bac0` for `row_history.shell`; the current renderer produces 116 elements and digest `1527bbb72674a8b5e493c2e9242ef257479ccf44412ae3f50698b112cb19bdb6`. The same mismatch reproduces with the Plan 07 row-history source files restored to their pre-task versions. Do not regenerate the receipt as part of Plan 07; parent should assign a focused investigation before phase verification.
