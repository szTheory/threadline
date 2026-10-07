# Phase 237 Release and Candidate Verification

## Exact source range and breaking-footer audit

- Base tag: `v1.44` at `4ae4557ddde83d70eb1781db984cb287dfa18b1b` (exclusive).
- Inclusive committed source tip: `6227ad959d30b62f08b957ecc50b146ce4fdf62c`.
- Ancestry check: `git merge-base --is-ancestor v1.44 HEAD` passed.
- Exact audit command: `git log 4ae4557ddde83d70eb1781db984cb287dfa18b1b..6227ad959d30b62f08b957ecc50b146ce4fdf62c --grep='BREAKING CHANGE' --format='%H %B'`.
- Result: 11 matching commits and 12 adopter consequences; all consequences are represented in the dated human-owned 1.0.0 breaking section and linked from the upgrade guide.

| Matching commit | Footer consequence | Human changelog / guide ID |
| --- | --- | --- |
| `f068eea0cea0ef6de31591aa76cac3a79826d240` | PostgreSQL 15 is the supported minimum; PostgreSQL 14 users must upgrade the database. | `pg-floor` |
| `0ea306bfeff851e05b83b3ca6299537eb4c090e9` | Unsupported job-context extras and malformed IDs are rejected. | `job-context` |
| `8be660127585f4086fed55e62a229c076124d103` | Six `StorageSchema` SQL helpers leave the documented API. | `hidden-apis` |
| `ec29da4a1c991569f3099b81246fab7adae5e223` | Direct `Threadline.Export` functions reject unknown option keys. | `strict-options` |
| `bc4045843dc62c9a02d513910c8eae2dee63999b` | Two `Evidence.Proof` helpers leave the documented API. | `hidden-apis` |
| `fc72f6b5fa3553cc46db3095c960a748c07bac66` | Investigation reads reject unknown filter and option keys. | `strict-options` |
| `1ab338e86fbda91f8dce1ddd73b28f092645c90a` | Timeline and actor-history reads reject unknown filter and option keys. | `strict-options` |
| `5432f72e7540ea6d38d8adb267ec7016e291bdd2` | A non-nil scope without a three-arity scope callback fails closed. | `fail-closed-scope` |
| `04302cadf2eb4532605a547c75b657cf2af4f056` | `transaction_context/2` returns a tagged tuple; the transaction lookup family rejects `:surface`, `:params`, and `:preload`. | `linked-lookup-shape`, `transaction-lookup-options` |
| `a68981b047192c7d9ab860b31ad658102203ab04` | Transaction lookup functions reject options outside the shared allowlist. | `transaction-lookup-options` |
| `ae5595b424400096082035eef9adc2f8bd270cd9` | `transaction_context/2` returns `{:ok, linked}` or `{:error, :not_found}`. | `linked-lookup-shape` |

The other 1.0 breaking entries also have guide IDs, but no matching footer in this exact range: `association-hydration`, `bounded-row-history`, `hidden-helpers`, `timeline-page`, and `actor-history-page`. They remain in the dated release section as separately documented compatibility changes. The 1.0 section contains 12 breaking-change IDs and eight deprecation IDs. The three `config-shape`, `health-error`, and `telemetry-actor` entries remain prerequisites in the 0.12 section, outside the 1.0 breaking inventory.

`CHANGELOG.md` retains a fresh unbracketed `## Unreleased — highlights` staging heading above `## [1.0.0] - 2026-10-07`. The dated section is human-owned; Release Please continues to target only `CHANGELOG-GENERATED.md`.

## Isolated candidate

- Fetched canonical `main` SHA: `0d6f36f1a7f6d014d415518a4fa2d235b66a9cf8`.
- Candidate checkout: isolated task-local checkout (candidate branch `candidate/threadline-1.0.0-final5`).
- Candidate commit: `d7d5ec7666f5042c943cf66e1a76a65fd9bfd66a`, parent `0d6f36f1a7f6d014d415518a4fa2d235b66a9cf8`.
- Candidate subject/footer: `feat!: land Threadline 1.0 API contract` / one `Release-As: 1.0.0` footer.
- Candidate is one commit above its base and its worktree is clean. A fresh read-only fetch confirmed canonical `main` remains `0d6f36f1a7f6d014d415518a4fa2d235b66a9cf8`, the candidate parent.
- `origin` points to the local source checkout; `github-canonical` is `https://github.com/szTheory/threadline.git`. No push or PR was performed.
- The source range changes 349 paths and the candidate changes 346. Their sorted inventories match exactly after excluding the three local evidence artifacts `237-03-SUMMARY.md`, `237-REVIEW.md`, and `237-VERIFICATION.md` from the source range (0 missing, 0 extra). The candidate reconciliation intentionally keeps `main`'s shipped 0.12.0 manifest/generated changelog artifacts until release automation runs. Pin content differs from the source-side 1.0.0 tree in `README.md`, `guides/getting-started-saas.md`, `guides/operator-surface.md`, and `mix.exs` because those carry the package install version.

## Candidate-bound local gates

At candidate SHA `d7d5ec7666f5042c943cf66e1a76a65fd9bfd66a`, in the order required by the plan:

1. `THREADLINE_BUMP_REHEARSAL_MODE=candidate mix verify.bump_rehearsal` — passed. It simulated only `0.12.0 -> 1.0.0`, kept the existing human changelog heading, generated `threadline-1.0.0.tar`, and produced checksum `cc95ce707f18f6f6bd9c1124baf2dd52349e67806e7ec8935d332f290f6c00a0`. Tree identity matched across 34 checksummed files; no scratch branch or linked worktree survived. The rehearsal does not invoke live Release Please.
2. `mix ci.all` — passed on the same committed candidate SHA with task-local Hex, npm, and Playwright cache paths. Format, Credo, dependency audit, repository hygiene, and cycle checks passed. CI reported 32 properties, 3,058 root tests with 0 failures and 3 exclusions; 132 example tests with 0 failures; Dialyzer 0 errors; 17 live Dialyzer-slice tests with 0 failures (16 excluded); and the final browser lane 318 passed / 26 skipped. The database service for this local run was PostgreSQL 16 on port 55432.

The sandboxed browser attempt could not start Chromium because macOS denied its Mach port bootstrap; the complete `mix ci.all` run under host process permissions passed. Chromium and all task caches remained in temporary storage. These environment adjustments did not alter the candidate tree.

## CI support-lane pins observed

| Lane | Elixir | OTP | PostgreSQL |
| --- | --- | --- | --- |
| Minimum | `1.15.8` | `26.2.5.21` | `15` |
| Current | `.tool-versions`: `1.17.3` | `.tool-versions`: `27.3.4.15` | `16` |
| Latest | `1.20.4` | `29.1.1` | `18.6` |

The minimum PostgreSQL 15 floor and the expected latest pins remain unchanged.

## Release boundary

This artifact is a local candidate and local verification record only. It grants no push, PR, merge, tag, Release Please, or production-Hex action. The candidate remains isolated for a separately authorized landing plan.
