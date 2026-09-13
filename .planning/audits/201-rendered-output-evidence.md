# Phase 201 Rendered Output Evidence

Captured at `2026-09-13T19:53:58Z` UTC from repository HEAD
`2babd4deab6a7bcbe04ae3b47af8df462661fd8a`. The plan entered execution at
`73328bccb6bd74fe087f1b10a92ebc6adc8acd4c`; Task 1 then added only the
rendered-output contract.

## Accepted landed owners

These owner paths are the accepted final baseline. This plan did not revert,
replay, squash, or rewrite their landed work.

| Owner path | Attributed commit | Object at attributed commit | Object at `18fe87f5` | Object at plan entry | Result |
| --- | --- | --- | --- | --- | --- |
| `lib/threadline/operator_surface/style.ex` | `5752e357` | `88602db34bbdf29b4d920793250d6ba62d1ad37b` | `88602db34bbdf29b4d920793250d6ba62d1ad37b` | `88602db34bbdf29b4d920793250d6ba62d1ad37b` | byte-identical |
| `lib/threadline/operator_surface/live/stress_live.ex` | `1a5fbef2` | `0f8a46a79540b39b9db805c68c850bf685b599eb` | `0f8a46a79540b39b9db805c68c850bf685b599eb` | `0f8a46a79540b39b9db805c68c850bf685b599eb` | byte-identical |
| `lib/threadline/operator_surface/stress_fixtures.ex` | `1a5fbef2` | `2744ac53c2701c1f9a62e7e18642bc2de6810a36` | `2744ac53c2701c1f9a62e7e18642bc2de6810a36` | `2744ac53c2701c1f9a62e7e18642bc2de6810a36` | byte-identical |

The exact history checks were:

```text
git diff --exit-code 5752e357 18fe87f5 -- lib/threadline/operator_surface/style.ex
git diff --exit-code 1a5fbef2 18fe87f5 -- lib/threadline/operator_surface/live/stress_live.ex lib/threadline/operator_surface/stress_fixtures.ex
git diff --exit-code 18fe87f5 HEAD -- lib/threadline/operator_surface/style.ex lib/threadline/operator_surface/live/stress_live.ex lib/threadline/operator_surface/stress_fixtures.ex
```

All three commands exited zero.

## Pre-edit structural receipts

The receipt canonicalizer removes text, comments, serialization whitespace, and
only `data-earned-flow`, `data-persona`, and `data-jtbd`. It preserves ordered
element hierarchy and all other meaningful attributes.

| Stable node ID | Elements before | Normalized SHA-256 before |
| --- | ---: | --- |
| `start.record_lookup` | 20 | `f2434dc7348b02c0d74ea212cc6f8fd074b724d9b31f64ca5ce98235a10c3b87` |
| `start.correlation_lookup` | 12 | `a8ec0f2609ec9ec3493564f90e772008ab6e9284a2230635920cc2a1682cdb1b` |
| `exports.timeline_context` | 45 | `568e22a7119d9e5753bddabf42e4d92f9212f7241d4821aae9c52f8e9d84448a` |
| `exports.evidence_context` | 42 | `7a62c0f043c5c02b160d2fd45d3facc40f06ef2e94bb3834c2de62020b29c764` |
| `evidence.carry_to_exports` | 1 | `16250bb948aa1f2dcb3d36d78418c9b151fcf49fa5cb438c710588f2f8859810` |
| `row_history.shell` | 114 | `4994a628aaeb94eeb33ba105015bdfa05a36994316787f40a6d7f27dc838ebbf` |
| `timeline.carry_to_exports` | 4 | `eb676f68c6ff8f1073d2974ca829b9997a4695ad5734cc8ac2027dd676833c2a` |

There are exactly seven rows and every element count is positive.

## Immutable reference corpus

The reference inventory is derived only from Git-tracked paths beneath
`test/fixtures/operator_surface`. Paths are normalized to `/`, sorted by relative
path, and reject empty or duplicate entries. `README.md` and
`manifest.sha256` are metadata and are excluded from the canonical digest rows.

| Evidence | Value |
| --- | --- |
| Tracked paths under corpus root | 429 |
| Canonical reference paths | 427 |
| Manifest entries | 427 |
| Empty canonical paths | 0 |
| Duplicate canonical paths | 0 |
| Manifest-file SHA-256 | `4e64b1f03fb742edd2b6b74d410fc8b59a533f5c4f2d614bdbfaf71241827f3e` |
| Sorted per-path digest-row aggregate SHA-256 | `4e64b1f03fb742edd2b6b74d410fc8b59a533f5c4f2d614bdbfaf71241827f3e` |
| Git tree at plan entry and Task 1 HEAD | `6aaff478a20f2a7e35ae8189f36dbc978dc71064` |

Final comparison must first require exact one-to-one sorted path equality and
only then compare each path's byte digest. Additions, removals, duplicate paths,
and renames are distinct failures; a rename is not accepted as equal content.

The derivation checks were:

```text
git ls-files -z -- test/fixtures/operator_surface
shasum -a 256 test/fixtures/operator_surface/manifest.sha256
git rev-parse 73328bccb6bd74fe087f1b10a92ebc6adc8acd4c:test/fixtures/operator_surface
git rev-parse 2babd4de:test/fixtures/operator_surface
```

## Exception registry

Entry count: **0**.

Zero entries is the expected successful state. If a later comparison genuinely
requires a nonzero contingency, each row must contain exactly: stable node ID,
numeric before, numeric after, numeric delta, rationale, and expiry. The registry
is capped at three entries. Display-text substrings are forbidden as identity or
matching keys.

## Residual provenance inventory

This is work remaining for Plan 04, not an allowlist and not a clean result.
There are exactly 21 attributes on seven rendered nodes:

| Node | Source | Remaining attributes |
| --- | --- | ---: |
| `start.record_lookup` | `start_live.ex:225-227` | 3 |
| `start.correlation_lookup` | `start_live.ex:265-267` | 3 |
| `exports.timeline_context` | `export_status_live.ex:192-194` | 3 |
| `exports.evidence_context` | `export_status_live.ex:252-254` | 3 |
| `evidence.carry_to_exports` | `evidence_live.ex:363-365` | 3 |
| `row_history.shell` | `row_history_live.ex:54-56` | 3 |
| `timeline.carry_to_exports` | `timeline_live.ex:791-793` | 3 |

## Baseline verification and denied-command attestation

The fixture contract ran 5 tests with 0 failures. `mix verify.mechanical` ran 28
tests with 0 failures. No capture command, screenshot or snapshot update,
fixture-corpus rewrite, local critic, or paid critic command ran while producing
this baseline.

```text
ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix test test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 MIX_ENV=test mix verify.mechanical
```
