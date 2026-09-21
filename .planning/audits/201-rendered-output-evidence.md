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

---

## Plan 05 final evidence (sealed 2026-09-21)

All results below were measured on this machine at phase HEAD with the Plan 05
contract in the working tree. No capture, snapshot update, fixture rewrite,
scorecard regeneration, baseline regeneration, or critic command (local or paid)
was run to produce any of it.

### Deterministic gates

| Gate | Command | Result |
| --- | --- | --- |
| Rendered-output contract | `mix test test/threadline/operator_surface/rendered_output_contract_test.exs` | 9 tests, 0 failures |
| Fixture contract + mechanical checker | `mix test .../operator_surface_fixture_contract_test.exs .../mechanical_checker_test.exs` | 33 tests, 0 failures |
| Mechanical floor | `mix verify.mechanical` | 28 tests, 0 failures |
| Root suite (in aggregate) | `mix ci.all` | 1660 tests, 0 failures, 1 excluded |
| Example suite (in aggregate) | `mix ci.all` | 116 tests, 0 failures |
| Dialyzer | `mix verify.dialyzer` | Total errors: 0, Skipped: 0, Unnecessary Skips: 0 |
| **Aggregate** | `mix ci.all` | **exit 0** |

`ci.all` first failed at the Dialyzer lane with
`Could not read PLT file .dialyzer/dialyxir_erlang-27.3_elixir-1.17.3_deps-dev.plt: no_such_file`.
This is a local build-cache miss, not a product defect: `verify.dialyzer` runs
`dialyzer --no-check`, which will not build a missing PLT, and the PLTs present
on disk were built under OTP `27.3.4.15` while the pinned
`ASDF_ERLANG_VERSION=27.3` resolves to the separately installed OTP `27.3`.
PLT files are gitignored (`/.dialyzer/*.plt`), so rebuilding them changed nothing
tracked. After one `mix dialyzer --plt`, the lane and the full aggregate pass.

### Accepted landed-blob attribution (D-08/D-09)

All three commands exit 0 — the accepted copy/CSS blobs were proven, never replayed:

```text
git diff --exit-code 5752e357 18fe87f5 -- lib/threadline/operator_surface/style.ex
git diff --exit-code 1a5fbef2 18fe87f5 -- lib/threadline/operator_surface/live/stress_live.ex lib/threadline/operator_surface/stress_fixtures.ex
git diff --exit-code 18fe87f5 HEAD -- lib/threadline/operator_surface/style.ex lib/threadline/operator_surface/live/stress_live.ex lib/threadline/operator_surface/stress_fixtures.ex
```

### Phase 201 production delta

The complete production delta of Phase 201 over `fecfe684..HEAD` is 21 deletions
across five LiveView modules, and every deleted line is a `data-earned-flow`,
`data-persona`, or `data-jtbd` attribute. Filtering those three attribute names
out of the diff leaves zero changed lines:

```text
lib/threadline/operator_surface/live/evidence_live.ex      | 3 ---
lib/threadline/operator_surface/live/export_status_live.ex | 6 ------
lib/threadline/operator_surface/live/row_history_live.ex   | 3 ---
lib/threadline/operator_surface/live/start_live.ex         | 6 ------
lib/threadline/operator_surface/live/timeline_live.ex      | 3 ---
5 files changed, 21 deletions(-)
```

### Browser lane — exact non-regression result

`mix verify.example_browser --project=desktop-chromium --project=mobile-chromium`
over the six operator specs: **82 passed, 8 failed**. Every behavior,
accessibility, responsive, and overflow case passes. All eight failures are
screenshot comparisons:

| Case | desktop-chromium | mobile-chromium |
| --- | --- | --- |
| `:108` dense Timeline keeps row-first evidence stable | FAIL | FAIL |
| `:115` row-history drawer keeps as-of evidence stable | FAIL | FAIL |
| `:136` Exports readiness hierarchy stays stable | FAIL | FAIL |
| `:145` Retention safety hierarchy stays stable | FAIL | FAIL |
| Home screenshot | PASS | PASS |

**These eight are proven pre-existing, not a Phase 201 regression.** The five
LiveView modules were reverted to their pre-phase state (`fecfe684`) and the
screenshot spec re-run against that pre-201 rendering: the result was the same
8 failed / 2 passed, with the identical four cases on the identical two
projects. The working tree was then restored to phase HEAD and the Plan 05
contract file verified byte-identical to its pre-experiment copy. A rendered
attribute deletion cannot change raster output, and this measurement confirms it
empirically rather than by argument.

The failures are already recorded as open pre-existing deviations in
`.planning/WINDOWS.md` (entries 8, 14, 15). The baselines were last written in
phase 180-04 (`799c7d6e`), long before Phases 198, 200, and 201.

### Immutable baseline hashes

`git diff --exit-code` over the snapshot directory is clean — nothing was
regenerated. SHA-256 of all ten baselines at seal time:

```text
3547f9902dc7316af45d06c72a2355fa200b4b9e592c20e33199a27560fc1bdf  exports-desktop-chromium.png
dee47fff376c37096ed73609d2517aa49dacd823e3cbe363548dbdc8a342b68c  exports-mobile-chromium.png
32c1aea1db6beec4de69f4f92505a584825b5e1873062f99e7e08ea261a560bb  home-desktop-chromium.png
7310f88f6a716664b0d06fb7ca83dc23b1e92e7e6f3c7ad2679e5d9877682ec1  home-mobile-chromium.png
d6884f18f6e559ba67dc2e8523bc943405207dfa1f8807470baef92fcf7a6ea5  retention-desktop-chromium.png
01d7d443c23cbbd1c50213e46c9b11d9863f9e9ee577876ccdf7d8d70e7c94f4  retention-mobile-chromium.png
4a75965ea8a8ede1d181a7f1c4d7aca8145031c0cdeb963445065f2519689edb  row-history-desktop-chromium.png
ad46e77057a772436c8ed63e797f58312db779872b637a70a8ba0e5bbd465540  row-history-mobile-chromium.png
ceda8fb7dd99cd75bdfa6865cf0e5eacc21bb20728751e8d95351a858d8e0f92  timeline-dense-desktop-chromium.png
54d9dfff1311adafb2cf050d1b8bbe2ef539a82eeda85c4f907c1bcbbbb889b8  timeline-dense-mobile-chromium.png
```

### Exception registry

Entry count: **0**. Unchanged from the Plan 01 seal. No measured structural or
corpus deviation required a contingency entry.

### Phase 202 clean-handoff preconditions

1. `mix ci.all` exits 0 at phase HEAD (root 1660/0, example 116/0, Dialyzer 0).
2. Zero planning-provenance attributes reach rendered output; the guard is
   positive-controlled and fails closed on empty or incomplete inventories.
3. The seven canonical nodes have equal pre/post canonical structural hashes.
4. The reference corpus is one-to-one identical: same normalized tracked path
   set, same byte hashes, 427 manifest entries.
5. Zero exception-registry entries.
6. The browser lane's only failures are the eight pre-existing screenshot
   comparisons above, proven unchanged by this phase and pinned as an exact
   non-regression set in the amended Plan 05 gate. Phase 202 inherits them as
   named, measured, already-registered debt — not as an unknown.
