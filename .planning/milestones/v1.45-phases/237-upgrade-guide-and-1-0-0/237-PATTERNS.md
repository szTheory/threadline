# Phase 237: Upgrade Guide and 1.0.0 - Pattern Map

**Mapped:** 2026-10-07  
**Files analyzed:** 9 new/modified files  
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/upgrading-to-1.0.md` | documentation | request-response (adopter procedure) | `guides/upgrading-to-0.11.md` | exact |
| `CHANGELOG.md` | documentation/configuration | transform (human-owned release notes to adopter actions) | `CHANGELOG.md` Unreleased sections | exact |
| `test/threadline/upgrading_to_1_0_doc_contract_test.exs` | test | file I/O / transform | `test/threadline/upgrading_to_0_11_doc_contract_test.exs` | exact |
| `test/threadline/changelog_contract_test.exs` | test | file I/O / transform | same file | exact |
| `test/threadline/guide_graph_contract_test.exs` | test | file I/O / transform | same file | exact |
| `test/partition_weights.txt` | config | batch inventory | same file | exact |
| `mix.exs` | config | build/configuration | same file's `docs: [extras: ...]` list | exact |
| `release-please-config.json` | config | transform | same file's current versioning configuration | exact |
| `bin/verify-bump-rehearsal` | utility | file I/O / batch | same script's disposable-clone rehearsal | exact |

`release-please-config.json` changes per REL-01; its closest analog is the existing JSON configuration itself.

## Pattern Assignments

### `guides/upgrading-to-1.0.md` (documentation, request-response)

**Analog:** `guides/upgrading-to-0.11.md`

**Opening and step pattern** (lines 1-20, 23-39):
```markdown
# Upgrading to 0.11.0

This guide is the full 0.10.x -> 0.11.0 procedure. `guides/upgrade-path.md`
gives the summary and points here for the steps.

## Who this guide is for

Use this guide if your host application is on any Threadline `0.10.x`
release and you are moving to `0.11.0`.
...
## Step 1: Bump the dependency
...
## Step 2: Regenerate triggers
```

Use its direct audience statement, numbered action headings, executable commands, and links to canonical detail. Phase 237 changes the procedure shape: add the version-gated 0.11 preflight, then exactly seven 1.0 steps. The guide must explicitly state that the 1.0 changes need no trigger regeneration; link to the existing trigger procedure only for adopters who skipped that earlier migration.

### `CHANGELOG.md` (documentation, transform)

**Analog:** current Unreleased `### Breaking changes` and `### Deprecations` sections.

**Human-owned break entry** (`CHANGELOG.md`, lines 35-41):
```markdown
- PostgreSQL 15 is the supported minimum. PostgreSQL 14 adopters must upgrade
  their database before upgrading Threadline.

- `Threadline.Job.context_opts/2` now rejects unsupported `extra` keys and
  malformed context IDs with `ArgumentError`; integer `:job_id` and
  `:correlation_id` values are converted to strings. Required action: remove
  unsupported extras and provide string, integer, or `nil` context IDs.
```

**Deprecation entry** (`CHANGELOG.md`, lines 164-170):
```markdown
- `Threadline.Query.audit_transaction/2` is deprecated in favor of
  `Threadline.audit_transaction/2`. It still returns the transaction or
  `nil`, still raises `ArgumentError` on a malformed id, and its `:preload`
  option ... still works.
```

Retain hand-authored actions and place one hidden stable ID beside each scoped breaking/deprecation item, including entries later grouped under one guide step. Do not infer adopter instructions from `CHANGELOG-GENERATED.md`.

### `test/threadline/upgrading_to_1_0_doc_contract_test.exs` (test, file I/O / transform)

**Analog:** `test/threadline/upgrading_to_0_11_doc_contract_test.exs`

**File-based assertions and diagnostics** (lines 17-20, 45-60):
```elixir
@guide_path "guides/upgrading-to-0.11.md"

defp guide, do: File.read!(@guide_path)

test "guide carries all twelve locked headings, with the six steps in ascending order" do
  content = guide()

  for heading <- @headings do
    assert String.contains?(content, heading),
           "expected guides/upgrading-to-0.11.md to contain #{inspect(heading)}"
  end
```

Use a focused ExUnit file contract that reads the human documents directly and reports the missing/extra value. For this test, extract scoped comment IDs, reject duplicates before converting to sets, compare the 0.12.0 preflight and 1.0 scopes independently, and assert the seven step headings/order and required trigger-regeneration statement. Include specific diagnostics for unmatched IDs.

### `test/threadline/changelog_contract_test.exs` (test, file I/O / transform)

**Analog:** same file, existing release-please ownership and config assertions.

**Config assertion** (lines 273-287):
```elixir
parsed = @release_please_config |> read!() |> Jason.decode!()

assert parsed["bump-minor-pre-major"] == true,
       "#{@release_please_config} sets `bump-minor-pre-major` to " <>
         "#{inspect(parsed["bump-minor-pre-major"])}, not true. ..."

assert parsed["bump-patch-for-minor-pre-major"] == false,
```

Update the current pre-1.0 expectation to the explicit 1.0 landing decision (`bump-minor-pre-major: false`), preserving the existing parsed-JSON assertion and useful failure detail. Changelog ownership remains that `changelog-path` targets the generated file.

### `test/threadline/guide_graph_contract_test.exs` (test, file I/O / transform)

**Analog:** same file.

**Guide registration** (lines 12-24):
```elixir
adopt: [
  "guides/getting-started-saas.md",
  ...
  "guides/upgrading-to-0.11.md",
  "guides/integrations/sigra.md"
]
```

Register `guides/upgrading-to-1.0.md` in the adopt lane so the existing graph's set, existence, and link checks cover it.

### `test/partition_weights.txt` (config, batch inventory)

**Analog:** same inventory.

**Weighted test row** (line 106):
```text
71 test/threadline/guide_graph_contract_test.exs
```

Add the new contract path with an explicit measured/assigned partition weight, maintaining the inventory's ascending path order and numeric-weight format.

### `mix.exs` (config, build/configuration)

**Analog:** existing `docs` extras (lines 577-590):
```elixir
extras: [
  "README.md",
  ...
  "guides/upgrading-to-0.11.md",
  "guides/brownfield-continuity.md",
```

Add the 1.0 guide to ExDoc extras next to the upgrade guide. Keep its path consistent with the guide graph and any release artifact configuration that collects local guides.

### `release-please-config.json` (config, transform)

**Analog:** same file's current versioning configuration.

`test/threadline/changelog_contract_test.exs:273-288` shows the parsed key and current assertion for `bump-minor-pre-major`. Preserve the project's explicit configuration style and set the value to `false` for the 1.0 landing; the rehearsal should read and validate this committed config rather than use a separate target manifest.

### `bin/verify-bump-rehearsal` (utility, file I/O / batch)

**Analog:** same script.

**Inputs and blast-radius identity** (lines 136-169):
```bash
CONFIG="release-please-config.json"
MANIFEST=".release-please-manifest.json"
for required in mix.exs CHANGELOG.md "$CONFIG" "$MANIFEST"; do
  [[ -f "$required" ]] || fail "missing input: $required" \
    "The rehearsal cannot simulate a release commit without $required."
done
```

**Candidate clone and artifact gate** (lines 223-231, 424-454):
```bash
SOURCE_SHA="$(git rev-parse HEAD)"
git clone --quiet --no-local "$ROOT" "$CLONE"
git -C "$CLONE" checkout --quiet --detach "$SOURCE_SHA"
...
run_gate "doc-contract tests (derived by filename) at $NEXT" derived_doc_contract_tests &&
  run_gate "changelog contract at $NEXT" mix test test/threadline/changelog_contract_test.exs &&
  run_gate "mix verify.release at $NEXT" mix verify.release || true
```

Extend this flow to validate candidate `HEAD`'s conventional breaking subject and exactly one `Release-As: 1.0.0` footer, require config false, and use that validated footer as the clone target. Keep the detached disposable clone, in-clone artifact contracts, and post-run identity check. The existing helper derives the next minor at lines 172-181, so replace that target logic and its user-facing “next minor” descriptions; the evidence is a local artifact rehearsal, not a live Release Please run.

## Shared Patterns

### Human-owned adopter prose

**Sources:** `guides/upgrading-to-0.11.md`; `CHANGELOG.md`; `test/threadline/changelog_contract_test.exs`  
Keep procedural details concise, answer the adopter's required action, and link to canonical deeper guidance. The human `CHANGELOG.md` remains the authority for action semantics while the generated changelog remains release-automation output.

### Source-aligned document contracts

**Sources:** `test/threadline/upgrading_to_0_11_doc_contract_test.exs`; `test/threadline/guide_graph_contract_test.exs`  
Use async ExUnit tests, read files with `File.read!`, assert specific structure, and make failure messages name the expected source fact. Add the new contract to the partition inventory.

### Release rehearsal boundary

**Source:** `bin/verify-bump-rehearsal`  
Validate committed candidate metadata before simulated edits, clone the exact candidate SHA with `--no-local`, run release contracts only in the clone, then prove source-tree identity is unchanged. Push, merge, and Hex publication remain outside this local operation.

## No Analog Found

None. `release-please-config.json` is classified as a new/modified configuration file; its current configuration and parsed contract provide a direct analog.

## Metadata

**Analog search scope:** tracked guide, changelog, Mix configuration, release helper, ExUnit contract, and partition-inventory files.  
**Files scanned:** 9 primary analog paths.  
**Pattern extraction date:** 2026-10-07
