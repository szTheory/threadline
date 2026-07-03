# Phase 191: Release/Version and Docs Trust Repair - Pattern Map

**Mapped:** 2026-07-02
**Files analyzed:** 11 (2 new test files created, 9 files modified)
**Analogs found:** 11 / 11 (every file has a strong in-repo analog — this is a truth-and-wayfinding phase over existing surfaces)

This phase writes **no application code**. It creates two ExUnit doc-contract test modules and edits docs/config. Every "pattern" here is a doc-contract-test idiom or an edit-shape of an existing markdown/JSON/mix surface. There is no controller/service/component work.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/threadline/version_truth_doc_contract_test.exs` (NEW) | test (doc-contract) | file-I/O / transform (glob + regex assert) | `test/threadline/adoption_pilot_doc_contract_test.exs` | exact |
| `test/threadline/persona_routing_doc_contract_test.exs` (NEW) | test (doc-contract) | file-I/O + config introspection | `test/threadline/exploration_routing_doc_contract_test.exs` + `release_artifact_contract_test.exs` (config keys) + `ia_lock_doc_contract_test.exs` (label loop) | role-match (composite) |
| `mix.exs` — `groups_for_extras` | config (ExDoc) | transform (keyword list) | current `groups_for_extras` block (self, mix.exs:279-284) | exact (in-place replace) |
| `mix.exs` — `verify.doc_contract` alias | config (mix alias) | batch (space-joined test path string) | current alias (self, mix.exs:81-83) | exact (append 2 paths) |
| `README.md` — `## Start here` + `## Documentation` | doc (markdown) | transform (prose reshape) | current `## Start here` (self, README.md:21-30) | exact (in-place reshape) |
| `guides/upgrade-path.md` — `## Upgrade by Threadline minor` | doc (markdown) | transform (additive tables/bullets) | current `## Upgrade by Threadline minor` (self, upgrade-path.md:68-83) | exact (extend-in-place) |
| `release-please-config.json` — `extra-files` | config (JSON) | transform (array append) | current `extra-files` (self, config:17-19) | exact (append 1 entry) |
| `guides/evaluating-threadline.md` — SSOT claim + marker | doc (markdown) | transform | `guides/adoption-pilot-backlog.md:7` marked SSOT line | exact (mirror marker idiom) |
| `guides/getting-started-saas.md` — pin + `:140` reframe | doc (markdown) | transform | fence-pin edit (rows 1-3 in RESEARCH ledger) | exact |
| `guides/operator-surface.md` / `adoption-evidence-playbook.md` / `adoption-pilot-backlog.md` — pins | doc (markdown) | transform | same pin-flip shape | exact |
| `CONTRIBUTING.md` — backport sentence | doc (markdown) | transform (additive prose) | existing prose (no test guards text yet) | role-match |

## Pattern Assignments

### `test/threadline/version_truth_doc_contract_test.exs` (NEW — test, glob+regex transform)

**Analog:** `test/threadline/adoption_pilot_doc_contract_test.exs` (read in full). Copy its module shape, `@version` derivation, and marker/extra-files wiring guard; generalize the single-guide/prefix approach to a glob + regex.

**Module + version-derivation pattern** (analog lines 1-7) — copy verbatim, this is the anti-hardcode SSOT idiom (D-191-06):
```elixir
defmodule Threadline.VersionTruthDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @release_please_config "release-please-config.json"
  @version Threadline.MixProject.project()[:version]   # derive, NEVER hardcode
end
```

**Family A — install pins** (test-enforced only, D-191-05/06). Glob README + guides, scan **raw text** (pins live in code fences, prose, AND a table cell), assert each equals the derived three-segment `~> major.minor.0`. Derivation helper (new; RESEARCH §Central Test Design Facts):
```elixir
# derive "~> 0.9.0" from @version "0.9.0"
[major, minor, _patch] = String.split(@version, ".")
expected_pin = "~> #{major}.#{minor}.0"

files = ["README.md" | Path.wildcard("guides/**/*.md")]   # glob, not allowlist
for path <- files, capture <- Regex.scan(~r/\{:threadline,\s*"~>\s*([\d.]+)"\}/, File.read!(path)) do
  [_full, ver] = capture
  assert "~> #{ver}" == expected_pin, "stale threadline pin in #{path}: ~> #{ver} (expected #{expected_pin})"
end
```
Note: exclude `priv/` and `examples/` — the README+guides glob already excludes them (RESEARCH). `~> 0.9.0` does not substring-contain `~> 0.6`/`~> 0.5`/`~> 0.3.0`, so existing sibling `refute`s stay valid.

**Family B + wiring guard** — generalize the analog's marker/extra-files check (analog lines 26-45) from one hardcoded guide to **all** marker-bearing docs:
```elixir
# analog idiom to generalize — find marked line, assert marker + extra-files registration
config = File.read!(@release_please_config)
for path <- files do
  for line <- String.split(File.read!(path), "\n"),
      String.contains?(line, "x-release-please-version") do
    assert String.contains?(line, @version),
           "live version claim in #{path} does not carry @version #{@version}: #{line}"
    assert String.contains?(config, path),
           "#{path} carries a version marker but is not in release-please-config.json extra-files"
  end
end
```
The analog's exact assertion messages (lines 33-44) are the tone/format to mirror — explain *why* the wiring matters and how to restore it.

**Family C — upgrade coverage** (derived from `@version`, delegates structural checks to `upgrade_path_doc_contract_test.exs`):
```elixir
minor = String.to_integer(minor)
prev = minor - 1
guide = File.read!("guides/upgrade-path.md")
# arrow may be U+2192 → or ASCII ->
assert guide =~ ~r/0\.#{prev}\.x\s*(→|->)\s*0\.#{minor}\.x/,
       "upgrade-path.md missing current-minor coverage 0.#{prev}.x → 0.#{minor}.x"
```
This assertion **fails today** (guide stops at `0.5.x → 0.6.x`) — that failure is the acceptance proof the guard works (RESEARCH).

---

### `test/threadline/persona_routing_doc_contract_test.exs` (NEW — test, file-I/O + config introspection)

**Analogs (composite):**
- `test/threadline/exploration_routing_doc_contract_test.exs` — README/guide prose assertion shape (`read_rel!` helper, `String.contains?`, `:binary.match` for ordering/scoping).
- `test/threadline/release_artifact_contract_test.exs:39-46` — how to read ExDoc config keys via `Threadline.MixProject.project()[:docs][:groups_for_extras]` and assert on `Keyword.keys(...)`.
- `test/threadline/ia_lock_doc_contract_test.exs:8-33` — the `for id <- ~w(...)` label-loop assertion pattern with per-item failure messages (mirror for the four verb lanes). **Do not touch ia_lock itself — it locks P1–P5 operator personas.**

**Config-introspection pattern** (from `release_artifact_contract_test.exs:5-7,40-45`):
```elixir
defp docs_config, do: Threadline.MixProject.project()[:docs]

test "groups_for_extras carries the four intent-verb lanes" do
  keys = Keyword.keys(docs_config()[:groups_for_extras])
  for lane <- [:Evaluate, :Adopt, :Operate, :Contribute] do
    assert lane in keys, "groups_for_extras missing verb lane #{inspect(lane)}"
  end
end
```
Note the deliberate contrast: `release_artifact_contract_test.exs:40` asserts **exact equality** on the key list (`== [:Overview, :Integrations, :Reference, :Project]`), while this new test asserts **subset presence** (`in`). Both must be updated to agree — see the mix.exs assignment below (RESEARCH §Collision).

**README prose-assertion pattern** (from `exploration_routing_doc_contract_test.exs:7-9,11-27`):
```elixir
@readme File.read!("README.md")   # or read via a read_rel!/1 helper like the analog

test "README ## Start here routes each verb lane to its canonical landing" do
  # scope to the ## Start here … ## Evidence plane slice like readme_doc_contract_test does
  for {label, landing} <- [
        {"Evaluate", "guides/evaluating-threadline.md"},
        {"Adopt", "guides/getting-started-saas.md"},
        {"Operate", "guides/operator-surface.md"},
        {"Contribute", "CONTRIBUTING.md"}
      ] do
    assert String.contains?(@readme, label)
    assert String.contains?(@readme, landing)
  end
end
```

**`refute` a new-guide pattern** (D-191-17 — the anti-scope-creep guard; mirror the `refute String.contains?` style from analog siblings):
```elixir
test "no standalone start-here / where-to-go-next guide was introduced" do
  refute File.exists?("guides/where-to-go-next.md")
  refute File.exists?("guides/start-here.md")
end
```

**Wiring:** register this test file path in the `verify.doc_contract` alias (see mix.exs alias assignment below, D-191-08).

---

### `mix.exs` — `groups_for_extras` (config, ExDoc)

**Analog / edit target:** the block at `mix.exs:279-284` (read this session). Replace the greedy flat `Reference`/`Project` buckets with four explicit per-lane file-list regexes plus retained `Overview`/`Integrations` (D-191-16). Current shape to replace:
```elixir
groups_for_extras: [
  Overview: ~r/README/,
  Integrations: ~r{^guides/integrations/},
  Reference: ~r{^guides/},                    # greedy flat bucket — replace
  Project: ~r/(CONTRIBUTING|CHANGELOG)/       # replace with Contribute
]
```
Replace with explicit per-lane lists (every one of the 20 extras in `mix.exs:257-278` in exactly one lane; RESEARCH §ExDoc Routing Grounding gives the full lane assignment). Keep `Integrations` regex **before** any general guide match (order matters for ExDoc first-match grouping — the analog's original ordering put `Integrations` ahead of the flat `Reference` bucket for this reason).

**Co-edit (mandatory, same commit):** `release_artifact_contract_test.exs:40-45` asserts `Keyword.keys(...) == [:Overview, :Integrations, :Reference, :Project]` (exact equality). Update to the new key order, e.g. `[:Overview, :Integrations, :Evaluate, :Adopt, :Operate, :Contribute]`, and keep it consistent with the subset check in the new `persona_routing_doc_contract_test.exs`. `groups_for_modules` (`mix.exs:285+`) is unaffected.

### `mix.exs` — `verify.doc_contract` alias (config, mix alias)

**Edit target:** `mix.exs:81-83` (read this session) — one long space-joined string of ~18 relative test paths. Append the two new files (D-191-08):
```
... test/threadline/version_truth_doc_contract_test.exs test/threadline/persona_routing_doc_contract_test.exs
```
No structural change — just extend the string so both new tests run under `mix ci.all`.

---

### `README.md` — `## Start here` + `## Documentation` (doc, prose reshape — HIGHEST execution risk)

**Analog / edit target:** current `## Start here` at `README.md:21-30` (read this session). Reshape into a 3-column `I want to… / Start here / Then read` intent table (D-191-15), and replace the flat `## Documentation` dump (README.md:187-204) with a collapsed `<details><summary>All guides</summary>` index grouped by the four verbs.

**Preservation-literal constraint (load-bearing):** `readme_doc_contract_test.exs` greps the whole README for ~18 literals that must survive the reshape (RESEARCH §README Reshape Preservation Literals). Notably the current `## Start here` bullets at README.md:27-28 carry two literals that do **not** map to the four verb rows and must be relocated into the `<details>` index or adjacent prose:
- the lane-matrix sentence: `` canonical `capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, and `sigra-reference` matrix `` (README.md:27)
- `Phoenix auth (reference lanes, pick one)` (README.md:28)

Also `release_artifact_contract_test.exs:86-89` asserts the README contains the pin and specific guide links — update its pin literal (see pin edits) and keep the guide links present. The intent table header must be `I want to… / Start here / Then read` — never `| Lane | Claim type |` (that literal is `refute`d README-wide by `readme_doc_contract_test.exs`).

---

### `guides/upgrade-path.md` — extend `## Upgrade by Threadline minor` (doc, additive)

**Analog / edit target:** the `## Upgrade by Threadline minor` section at `upgrade-path.md:68-83` (read this session). The section skeleton (compatibility matrix, per-minor list, "what breaks") already exists — only the 0.6→0.9 era content is missing. Extend **within** the existing section; do not add or rename a top-level heading.

**Existing per-minor bullet shape to mirror** (upgrade-path.md:81-82) — the new `0.6→0.7`, `0.7→0.8`, `0.8→0.9` bullets follow this exact "arrow + effect + `CHANGELOG.md` `[x.y.0]` anchor" form:
```
- **0.5.x → 0.6.x**: Evidence plane (...), recommended audited write path (`Threadline.Audit.transaction/3`); see `CHANGELOG.md` `[0.6.0]` for ...
```

**Locked structural constraints** (`upgrade_path_doc_contract_test.exs:5-30`, read this session): all nine `## ` section headings must survive verbatim; the compatibility-matrix header row string (`| Lane | Claim type | ... |`) and the `You are on the ... lane` sentences are locked. Keep the existing `0.5.x → 0.6.x` bullet (the scoped test at test lines 165-180 requires it). Tense fix at `upgrade-path.md:5` ("packages" → "landed in 0.6.0"). Add the D-191-02a/12a backport-policy sentence near the compatibility-matrix / lane framing. Avoid refuted tokens `forthcoming`, `coming soon`, `Phoenix 1.7+`, and product-milestone `v1.3x` labels.

---

### `release-please-config.json` — `extra-files` (config, JSON array append)

**Analog / edit target:** `release-please-config.json:17-19` (read this session):
```json
"extra-files": [
  {"type": "generic", "path": "guides/adoption-pilot-backlog.md"}
]
```
Append **only** the prose-claim file `guides/evaluating-threadline.md` (D-191-07). **Do NOT add any pin-bearing file** — the generic updater has no sticky `.0` scope and would born-red every patch release (D-191-05). Mirror the exact `{"type": "generic", "path": ...}` object shape.

---

### `guides/evaluating-threadline.md` — SSOT claim + marker (doc)

**Analog:** `guides/adoption-pilot-backlog.md:7` — the one existing correct marked SSOT line (`... reflects the **0.9.0** tree ... <!-- x-release-please-version -->`). Mirror its inline-marker idiom on `evaluating-threadline.md:11` (change the false `0.6.0` SSOT claim to `0.9.0` and append the `<!-- x-release-please-version -->` marker on the same line). **Leave `evaluating-threadline.md:13` verbatim** — it is protected history (`evaluating_threadline_doc_contract_test.exs:35` requires the `0.6.0 packages Evidence` line to survive). No global find-replace of `0.6.0` in this file.

### Pin-flip edits — `getting-started-saas.md:26`, `operator-surface.md:30`, `adoption-evidence-playbook.md:15`, `adoption-pilot-backlog.md:14`, `evaluating-threadline.md:38`, `README.md:63`, `priv/ci/hex_evaluator/mix.exs:27`

**Edit shape:** replace `{:threadline, "~> 0.6"}` → `{:threadline, "~> 0.9.0"}` (and the prose variants `` depends on `{:threadline, "~> 0.6"}` ``). Uniform one-token change; see the Co-Commit Guard table in Shared Patterns below for the guards each must move with. `priv/ci/hex_evaluator/mix.exs:27` additionally requires a `mix.lock` regeneration.

### `CONTRIBUTING.md` — backport sentence (doc, additive)

No existing analog line (grep for `backport`/`patch release`/`current minor` → zero hits). Add the same D-191-02a sentence mirrored into `upgrade-path.md`. Optionally add a small assertion in a doc-contract test for durability (Claude's discretion).

## Shared Patterns

### Version-SSOT derivation in tests
**Source:** `test/threadline/adoption_pilot_doc_contract_test.exs:7`
**Apply to:** both new test files
```elixir
@version Threadline.MixProject.project()[:version]
```
Never hardcode a version literal in a test — a test that hardcodes the version is the same drift footgun it guards (D-191-06). `release_artifact_contract_test.exs:5` shows the same idiom via a `project_config/0` helper for the `[:docs]` sub-config.

### Marker + extra-files wiring guard
**Source:** `test/threadline/adoption_pilot_doc_contract_test.exs:26-45`
**Apply to:** `version_truth_doc_contract_test.exs` (generalized to all marked docs)
The pattern: find the marked line, assert it carries `x-release-please-version`, then assert `release-please-config.json` lists the file under `extra-files`. Copy the analog's explanatory assertion messages (they tell a future maintainer *why* and *how to restore*).

### Doc prose assertion via read + `String.contains?` / `:binary.match`
**Source:** `test/threadline/exploration_routing_doc_contract_test.exs:7-9,24-27`
**Apply to:** `persona_routing_doc_contract_test.exs`, Family C of `version_truth`
`read_rel!/1` helper + `String.contains?` for presence; `:binary.match` for ordering/scoping when a literal must appear within a section slice (as `readme_doc_contract_test.exs` scopes `## Start here … ## Evidence plane`).

### Label-loop assertion with per-item message
**Source:** `test/threadline/ia_lock_doc_contract_test.exs:11-14`
**Apply to:** the four verb-lane checks in `persona_routing_doc_contract_test.exs`
```elixir
for id <- ~w(...) do
  assert String.contains?(doc, id), "expected ... to contain #{inspect(id)}"
end
```

### Co-Commit Guard Inventory (atomic pin-flip commit — the load-bearing correction to D-191-04)
**Apply to:** the pin-flip + `groups_for_extras` change. All must move in the same commit or CI/release reddens (RESEARCH §Co-Commit Guard Inventory):

| Guard file | Line(s) | Change | Runs under |
|------------|---------|--------|------------|
| `adoption_pilot_doc_contract_test.exs` | 9, 13, 14 | assert `~> 0.9.0`; add refute `~> 0.6`; update test-name string | `ci.all` |
| `getting_started_saas_doc_contract_test.exs` | 33, 34 | assert `~> 0.9.0`; keep refutes | `ci.all` |
| `operator_surface_doc_contract_test.exs` | 58-60 | assert `~> 0.9.0`; refutes stay valid | `ci.all` |
| `release_artifact_contract_test.exs` | 86 | assert README `~> 0.9.0` | `verify.release` only |
| `release_artifact_contract_test.exs` | 40-44 | update `groups_for_extras` key equality to verb lanes | `verify.release` only |
| `priv/ci/hex_evaluator/mix.exs` + `mix.lock` | 27 | `~> 0.9.0` + regenerate lock | `verify.hex_evaluator` |

**Timing nuance:** guards under `verify.release` do NOT run in per-PR `ci.all` — a green PR can still break the release. Update all in one commit regardless.

## No Analog Found

None. Every file in scope has a concrete in-repo analog or is an in-place edit of an existing surface. The `CONTRIBUTING.md` backport sentence is genuinely new prose but follows the same additive-prose shape as its `upgrade-path.md` twin; no code-pattern analog is needed.

## Metadata

**Analog search scope:** `test/threadline/*doc_contract*.exs`, `test/threadline/release_artifact_contract_test.exs`, `mix.exs` (aliases + ExDoc `docs` block), `README.md`, `guides/upgrade-path.md`, `release-please-config.json`.
**Files scanned:** 8 read directly this session (adoption_pilot test, exploration_routing test, ia_lock test, release_artifact test, upgrade_path test, mix.exs sections, README section, upgrade-path.md head, release-please-config.json). RESEARCH.md and CONTEXT.md supplied the verified line-level ledger for the remaining doc edits.
**Pattern extraction date:** 2026-07-02
