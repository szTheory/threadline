# Phase 48: threadline-0.3.0-release - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 6 likely Phase 48 targets
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/48-threadline-0.3.0-release/48-01-PLAN.md` | config | transform | `.planning/phases/47-saas-adopter-onramp/47-01-PLAN.md` | exact |
| `test/threadline/release_artifact_contract_test.exs` | test | file-I/O | `test/threadline/getting_started_saas_doc_contract_test.exs` | exact |
| `mix.exs` | config | file-I/O | `mix.exs` alias/package/docs sections | exact |
| `README.md` | config | transform | `README.md` + `test/threadline/readme_doc_contract_test.exs` | role-match |
| `CHANGELOG.md` | config | transform | `CHANGELOG.md` + `bin/verify-release-shape` | role-match |
| `CONTRIBUTING.md` | config | transform | `CONTRIBUTING.md` release/CI sections | exact |

## Pattern Assignments

### `.planning/phases/48-threadline-0.3.0-release/48-01-PLAN.md` (plan/config, transform)

**Primary analog:** `.planning/phases/47-saas-adopter-onramp/47-01-PLAN.md`

**Front matter pattern** (`47-01-PLAN.md:1-55`, `45-01-PLAN.md:1-29`)
- Keep YAML-like metadata first: `phase`, `plan`, `type`, `wave`, `depends_on`, `files_modified`, `autonomous`, `requirements`, `must_haves`.
- Use `must_haves.truths`, `artifacts`, and `key_links` to lock packaging/doc drift, not just tasks.

**Section skeleton** (`47-01-PLAN.md:57,64,69,140,193,212,219,228`)
```md
<objective>
<execution_context>
<context>
<tasks>
<threat_model>
<verification>
<success_criteria>
<output>
```

**Task pattern** (`47-01-PLAN.md:142-191`, `45-01-PLAN.md:53-83`)
- Use 2-3 narrow `<task>` blocks.
- Put locked assertions in `<behavior>` when the file is doc-heavy.
- Put exact commands in `<verify><automated>...</automated></verify>`.
- End each task with a concrete `<done>` sentence tied to release surfaces.

**What to copy**
- From Phase 47: the deeper doc-heavy plan style with `key_links`, explicit behavior bullets, and a full validation loop.
- From Phase 45: the shallower helper/alias task style when adding one Mix helper plus one contract.

**Anti-pattern to avoid**
- Do not make Phase 48 a catch-all repo gate. Phase 48 context D-06..D-09 says `verify.release` is release-scoped, not a second `mix ci.all`.

---

### `test/threadline/release_artifact_contract_test.exs` (test, file-I/O)

**Primary analog:** `test/threadline/getting_started_saas_doc_contract_test.exs:1-59`
**Secondary analogs:** `test/threadline/ci_topology_contract_test.exs:1-46`, `test/threadline/stg_doc_contract_test.exs:1-63`, `test/threadline/performance_doc_contract_test.exs:1-30`

**Shared file-read helper pattern** (`getting_started_saas_doc_contract_test.exs:7-11`, `performance_doc_contract_test.exs:5-8`, `stg_doc_contract_test.exs:5-8`)
```elixir
@repo_root File.cwd!()

defp read_rel!(segments) when is_list(segments) do
  @repo_root |> Path.join(Path.join(segments)) |> File.read!()
end
```

**Literal-locking pattern** (`getting_started_saas_doc_contract_test.exs:15-34`, `readme_doc_contract_test.exs:15-37`)
- Read the release surface file once.
- Assert exact strings for install/version snippets, guide paths, and named docs entries.
- Prefer `String.contains?/2` over parsing markdown structure unless order matters.

**Cross-file consistency pattern** (`getting_started_saas_doc_contract_test.exs:37-58`)
```elixir
Enum.each(pointers, fn path ->
  assert String.contains?(doc, path)
  assert File.exists?(Path.join(@repo_root, path))
end)
```

**Scoped extraction/order pattern** (`stg_doc_contract_test.exs:61-63`, `sigra_doc_contract_test.exs:18-29`, `ci_topology_contract_test.exs:26-31`)
- Use `String.split/3` to isolate one section when assertions should not scan the whole file.
- Use `:binary.match/2` or split around `"ci.all": [` only when relative order matters.

**Recommended Phase 48 contract shape**
- One test for `mix.exs` `package[:files]` coverage of release-surface docs.
- One test for `docs().extras` coverage and grouping assumptions.
- One test for README/guide route targets existing on disk.
- One test for `ci.yml` / `CONTRIBUTING.md` still naming `verify-docs`, `verify-hex-package`, and `verify-release-shape`.

**Anti-patterns to avoid**
- Do not shell out to `mix docs` or `mix hex.build` inside the ExUnit contract; those belong in `verify.release`.
- Do not broaden `verify.doc_contract` unless explicitly intended; current convention is most doc contracts run under `mix verify.test`, not the alias (`mix.exs:67`, Phase 47 research/context).

---

### `mix.exs` (config, file-I/O)

**Primary analog:** `mix.exs:7-18`, `61-145`

**Preferred env pattern** (`mix.exs:7-18`)
```elixir
def cli do
  [
    preferred_envs: [
      "ci.all": :test,
      "verify.test": :test,
      "verify.topology": :test,
      "threadline.verify_topology": :test,
      "verify.example": :test
    ]
  ]
end
```

**Alias table pattern** (`mix.exs:61-80`)
```elixir
defp aliases do
  [
    "verify.format": ["format --check-formatted"],
    "verify.credo": ["credo --strict"],
    "verify.test": ["test"],
    "verify.threadline": ["threadline.verify_coverage"],
    "verify.doc_contract": ["test test/threadline/readme_doc_contract_test.exs"],
    "verify.topology": ["threadline.verify_topology"],
    "verify.example": &verify_example/1,
    "verify.bench": &verify_bench/1,
    "ci.all": [...]
  ]
end
```

**Custom helper pattern** (`mix.exs:83-100`)
```elixir
defp verify_example(_args) do
  cmd = "bash -lc 'set -euo pipefail && ...'"

  case Mix.shell().cmd(cmd, env: [{"MIX_ENV", "test"}]) do
    0 -> :ok
    status -> Mix.raise("verify.example failed (#{status})")
  end
end
```

**Package/files pattern** (`mix.exs:111-119`)
```elixir
defp package do
  [
    licenses: ["MIT"],
    links: %{"GitHub" => @source_url, "Changelog" => "#{@source_url}/blob/#{doc_source_ref()}/CHANGELOG.md"},
    files: ~w(lib guides .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md)
  ]
end
```

**ExDoc organization pattern** (`mix.exs:122-145`)
```elixir
defp docs do
  [
    main: "Threadline",
    source_ref: doc_source_ref(),
    source_url: @source_url,
    extras: [...],
    groups_for_extras: [
      Overview: ~r/README/,
      Reference: ~r{^guides/},
      Project: ~r/(CONTRIBUTING|CHANGELOG)/
    ]
  ]
end
```

**Phase 48 guidance**
- Add `verify.release` as another named `verify.*` alias, following `verify.example` / `verify.bench` as the closest custom-helper pattern.
- Keep it out of `ci.all` unless the phase explicitly intends to change CI topology.
- Reuse `doc_source_ref/0` semantics so release tags and source links stay aligned.
- For ExDoc grouping, Phase 48 context D-16 requires a more specific `Integrations: ~r{^guides/integrations/}` match before the broader `Reference` guide bucket.

**Anti-patterns to avoid**
- Do not add `verify.release` to `preferred_envs: :test` if it only runs packaging checks. It likely wants explicit `MIX_ENV=dev mix docs` inside the helper instead.
- Do not replace `bin/verify-release-shape`; compose it from `verify.release`.
- Do not expand `ci.all` with `verify.release` or heavy release-only checks without updating CI contract tests.

---

### `README.md` (config/docs, transform)

**Primary analog:** `README.md:14-25,27-99`
**Contract analog:** `test/threadline/readme_doc_contract_test.exs:15-83`

**Current README routing pattern** (`README.md:14-18`)
```md
## Start here

- **Evaluating:** open the [HexDocs](https://hexdocs.pm/threadline) for the full API.
- **Integrating:** read [Quick Start](#quick-start) and then [guides/domain-reference.md](guides/domain-reference.md).
- **Contributing:** follow [`CONTRIBUTING.md`](CONTRIBUTING.md) and run `mix ci.all`.
```

**Quick Start version/install snippet** (`README.md:29-49`)
- Dependency version is a literal lock in prose and should match the release.
- Commands are short, copy-pasteable, and library-first.

**Doc-contract pattern**
- README changes should be backed by narrow literal assertions in `readme_doc_contract_test.exs`.
- Existing tests already lock API names and guide links; extend that style rather than replacing it with markdown parsing.

**Phase 48 guidance**
- Keep README compact.
- Promote `guides/getting-started-saas.md` and `guides/integrations/sigra.md` as the two top-level “next reads”.
- Keep `guides/performance.md` and `guides/incident-playbook.md` one level deeper, consistent with Phase 48 context D-13..D-15.

**Anti-patterns to avoid**
- Do not turn the README into the full operator handbook.
- Do not leave `{:threadline, "~> 0.2"}` behind when the release story says `0.3.0`.

---

### `CHANGELOG.md` (config/docs, transform)

**Primary analog:** `CHANGELOG.md:1-47`
**Validation analog:** `bin/verify-release-shape:12-45`

**Release heading pattern**
```md
## [0.2.0] - 2026-04-23
```

**Section pattern** (`CHANGELOG.md:5-23`, `25-47`)
- Top-level release heading.
- `### Added`, `### Changed`, and optional upgrade/release-notes subsections.
- Bullets are evidence-backed and path-linked when helpful.

**Release-shape enforcement** (`bin/verify-release-shape:12-45`)
```bash
VER_LINE=$(grep -E '^\s*@version\s+"' mix.exs | head -1 || true)
VER=$(sed -n 's/.*@version "\([^"]*\)".*/\1/p' <<<"$VER_LINE" | head -1)
if ! grep -qE "^## \\[${VER//./\\.}\\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$" CHANGELOG.md; then
  echo "CHANGELOG.md must contain a dated heading: ## [$VER] - YYYY-MM-DD" >&2
  exit 1
fi
```

**Phase 48 guidance**
- Add a `0.3.0` section, not just Unreleased edits.
- Keep upgrade notes in the changelog for `0.x`, matching Phase 48 context.
- Let the new release narrative open with the adopter claim, then break out proof surfaces under SaaS onboarding, Sigra, performance, incident response, and upgrade notes.

**Anti-patterns to avoid**
- No bare `## [0.3.0]` heading without a date; the script explicitly rejects that.
- Do not leave the release story only in `Unreleased` if `@version` moves to `0.3.0`.

---

### `CONTRIBUTING.md` (config/docs, transform)

**Primary analog:** `CONTRIBUTING.md:50-64`, `96-144`
**Workflow analog:** `.github/workflows/ci.yml:168-250`

**CI parity table pattern** (`CONTRIBUTING.md:52-62`)
```md
| `verify-docs` | `MIX_ENV=dev` — `mix docs` (ExDoc + extras) |
| `verify-hex-package` | `mix hex.build` + assert tarball contains `lib/` |
| `verify-release-shape` | `bin/verify-release-shape` — `@version` / dated `CHANGELOG` for release versions |
```

**Maintainer runbook pattern** (`CONTRIBUTING.md:117-144`)
- Release docs use numbered manual steps.
- They separate “green CI on main”, “shape checks”, and “publish/tagging”.
- They name exact commands, not abstractions.

**Phase 48 guidance**
- Document `mix verify.release` as the maintainer pre-flight.
- Keep `wait for green CI on main` as a runbook step, not as alias logic.
- Preserve the existing distinction between local pre-flight, CI gates, and tag-triggered publish.

**Anti-patterns to avoid**
- Do not rewrite release docs as if local `verify.release` replaces CI.
- Do not hide the clean-tree requirement; current checklist already states it plainly (`CONTRIBUTING.md:139`).

## Shared Patterns

### Named Verification Entrypoints
**Source:** `mix.exs:61-80`, `CLAUDE.md` CI conventions
- New verification surfaces should be exposed as `mix verify.*` aliases.
- Contributors and docs cite the alias name verbatim.
- Composition is explicit; no hidden umbrella macro.

### Release Validation Composition
**Source:** `.github/workflows/ci.yml:168-250`, `CONTRIBUTING.md:52-64`, `bin/verify-release-shape:1-45`
- Treat docs build, hex tarball shape, and release metadata as separate checks.
- `verify.release` should compose those checks locally, not reimplement them inconsistently.

### Contract-Test Style
**Source:** `test/threadline/getting_started_saas_doc_contract_test.exs:1-59`, `test/threadline/stg_doc_contract_test.exs:1-63`, `test/threadline/ci_topology_contract_test.exs:1-46`
- Pure `File.read!` contracts.
- Literal string assertions first.
- `File.exists?` for linked-path existence.
- `String.split` / `:binary.match` only for small scoped structure assertions.

### Docs Surface Discipline
**Source:** `mix.exs:111-145`, `README.md:14-18,92-99`
- README is the front door.
- Guides live in `guides/`.
- ExDoc extras are explicit and grouped deliberately.
- Package file list is curated; if a release-surface doc matters, assert it in both `package[:files]` and `docs().extras` where appropriate.

## Warnings

- `verify.doc_contract` is still README-only in `mix.exs:67`. Do not assume adding a new release contract there is required unless the phase explicitly wants a doc-only alias expansion.
- `ci.all` currently excludes release-only and bench-only checks (`mix.exs:71-79`, `test/threadline/ci_topology_contract_test.exs:23-31`). Preserve that boundary unless Phase 48 intentionally changes CI topology.
- `groups_for_extras` currently routes all `guides/` into `Reference` (`mix.exs:141-145`). If Phase 48 introduces an `Integrations` group, order matters: specific regex first, broad guide regex after.
- `bin/verify-release-shape` already handles SemVer prerelease skip logic (`bin/verify-release-shape:24-28`). Do not regress that behavior when composing `verify.release`.
- The CI workflow comment and docs rely on stable job keys (`.github/workflows/ci.yml:1-2`, `CONTRIBUTING.md:52`). Avoid renaming jobs while editing release docs.

## Metadata

**Analog search scope:** `.planning/phases/45-*`, `.planning/phases/47-*`, `test/threadline/`, `mix.exs`, `bin/`, `.github/workflows/`, top-level docs
**Files scanned:** 17
**Pattern extraction date:** 2026-05-05
