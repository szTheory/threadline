# Phase 202: Release 0.10.0 - Pattern Map

**Mapped:** 2026-09-22
**Files analyzed:** 12 (6 new, 6 modified)
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `bin/verify-environment-protection` (new, D-18) | utility (fail-closed live-state verifier script) | request-response (gh API read + assert) | `bin/verify-branch-protection` | exact |
| `lib/mix/tasks/release.pins.ex` (new, D-04) | utility (Mix task, doc-rewrite) | transform (regex find/replace over doc files) | derivation logic in `test/threadline/version_truth_doc_contract_test.exs` (Family A) + task shape from `lib/mix/tasks/threadline.install.ex` | role-match (test provides the derivation to copy; install.ex provides the Mix.Task/`use Mix.Task`/`Mix.shell().info` idiom) |
| `.github/workflows/release.yml` — new `smoke-published` job (D-09) | CI job (integration smoke) | request-response (installs published pkg, runs test suite against real Postgres) | `verify-hex-evaluator` job in `.github/workflows/ci.yml` | exact (same Postgres service block, same `priv/ci/hex_evaluator` target, different dep-resolution mode) |
| `.github/workflows/release.yml` — `distribution-sync` reorder (D-10) | CI job wiring (`needs:` edit) | event-driven (job-graph dependency) | existing `distribution-sync` job itself (`needs: [release-ref, publish-hex]` → add `smoke-published`) | exact (self-modification, no external analog needed) |
| `priv/ci/hex_evaluator/mix.exs` — dep mode-switch (D-07) | config (Mix project deps) | transform (env-driven dep selection) | itself, current single-dep shape; pattern for switch logic borrowed from `mix.exs`'s own `verify_hex_evaluator/1`/`verify_release/1` env-driven `Mix.shell().cmd` shelling | role-match |
| `priv/ci/hex_evaluator/mix.lock` — untrack + gitignore (D-08) | config | file-I/O | N/A (deletion/untracking action, not a pattern-copy) | no analog needed |
| `CHANGELOG-GENERATED.md` (new, D-11) | config/doc (release-please changelog target) | event-driven (bot-written) | `CHANGELOG.md`'s current structure (headings, section shape) — becomes the bot-only mirror of what `CHANGELOG.md` used to be | exact (literal fork of existing file's shape) |
| `CHANGELOG.md` — highlights block + reorder (D-11..D-14) | doc (human-owned changelog) | transform (manual edit + structural convention) | itself — existing `## [Unreleased]` orphan block at line 43 (content to fold in), Keep-a-Changelog heading shapes at lines 3, 11, 24 | exact |
| `release-please-config.json` — `changelog-path` split (D-11) | config | transform (JSON edit) | itself; `extra-files` array shape (lines 15-18) is the precedent for "file-scoped ownership" already used for `guides/adoption-pilot-backlog.md` / `guides/evaluating-threadline.md` | exact |
| Legacy `public`-schema E2E test (new, D-03) | test (integration, install-path proof) | CRUD (install → capture → read) | `priv/ci/hex_evaluator` fixture (its `mix.exs`, `mix ecto.migrate`, `mix test` shape) + existing `storage_schema` unit tests exercising `storage_schema: "public"` at the opts level | role-match |
| Contract strengthening: `version_truth_doc_contract_test.exs` (D-06) | test (doc-contract, ExUnit) | transform (regex assertion over doc files) | itself — Family A/B pattern (existing `test "every x-release-please-version marked line carries @version..."`) is the template for the new "no pin line also carries the marker" assertion | exact |
| `release_control_plane_contract_test.exs` / `release_artifact_contract_test.exs` strengthening (D-18, D-20) | test (doc-contract / artifact-contract, ExUnit) | transform (source/archive assertion) | itself — `built_archive()` helper (`release_artifact_contract_test.exs:286-329`) is the exact extension point for D-20's exclusion assertion; `release_control_plane_contract_test.exs`'s `String.split`/`assert publish =~` idiom is the template for a D-18 wiring assertion if one is added there | exact |
| `Threadline.StorageSchema` `@default` flip (D-01) | config/module (single-line default change) | CRUD (schema resolution read path) | itself, `lib/threadline/storage_schema.ex:10` | exact (single-line edit, no external pattern needed) |
| `guides/upgrade-path.md` re-scoping (D-15, D-16) | doc | transform (manual edit, structural) | itself — existing per-minor bullet template at lines 96-113 (`**0.8.x → 0.9.x**: ... Breaking changes: **None**. Required migration: **None**. Config changes: **None**. ...`) | exact |
| `mix threadline.install`, `guides/getting-started-saas.md` steering (D-02) | task / doc | request-response (CLI prompt/doc guidance) | `lib/mix/tasks/threadline.install.ex` (itself) | exact |

## Pattern Assignments

### `bin/verify-environment-protection` (utility, request-response)

**Analog:** `bin/verify-branch-protection` (171 lines, full read)

**Shebang + safety header pattern** (lines 1-22):
```bash
#!/usr/bin/env bash
# CI / local: assert `main`'s protection contract (GREEN-08 / D-12).
# ... rationale comment block explaining WHY two halves are needed ...
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
```
Copy this exactly, including the rationale-comment convention (D-18's script needs its own two-half rationale: "(a) the live rule still requires a reviewer" and "(b) [optional] a check has actually run under it").

**Tool-presence guards** (lines 27-38):
```bash
if ! command -v jq >/dev/null 2>&1; then
  echo "bin/verify-branch-protection requires jq (JSON processor) and it is not on PATH." >&2
  echo "Install it (macOS: brew install jq; ubuntu: apt-get install -y jq) and re-run." >&2
  exit 1
fi
if ! command -v gh >/dev/null 2>&1; then
  echo "bin/verify-branch-protection requires the gh CLI and it is not on PATH." >&2
  exit 1
fi
```

**Repo-slug resolution** (lines 40-49):
```bash
REPO="${GITHUB_REPOSITORY:-}"
if [[ -z "$REPO" ]]; then
  REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)
fi
if [[ -z "$REPO" ]]; then
  echo "Could not resolve the repository slug from GITHUB_REPOSITORY or 'gh repo view'." >&2
  exit 1
fi
```

**Fail-closed live-state read with named FAIL blocks** (lines 51-93, adapt endpoint per D-18's research note — `GET /repos/{owner}/{repo}/environments/{environment_name}`, `protection_rules` array, `type: "required_reviewers"`):
```bash
RULES_JSON=$(gh api "repos/${REPO}/rules/branches/${BRANCH}" \
  -H "Accept: application/vnd.github+json" 2>/dev/null || true)
if [[ -z "$RULES_JSON" ]]; then
  echo "Could not read the effective rules for ${REPO}@${BRANCH}." >&2
  exit 1
fi
if ! printf '%s' "$RULES_JSON" | "$(dirname "$0")/compare-required-contexts" "$EXPECTED_CONTEXT"; then
  echo "FAIL (a): required status-check contexts for ${REPO}@${BRANCH} do not match (see above)." >&2
  exit 1
fi
```
D-18 equivalent: `gh api "repos/${REPO}/environments/production-hex"` then `jq` over `.protection_rules[] | select(.type == "required_reviewers")` to assert a non-empty `reviewers` array.

**403-fallback / token-permission escape hatch** (lines 95-156) — copy this exact shape for D-18's "default `GITHUB_TOKEN` cannot read Administration:read-gated environment fields" case flagged in RESEARCH.md's Assumption A1:
```bash
set +e
CLASSIC_RESPONSE=$(gh api --include --silent "repos/${REPO}/branches/${BRANCH}/protection" \
  -H "Accept: application/vnd.github+json" 2>&1)
CLASSIC_EXIT=$?
set -e
if [[ "$CLASSIC_EXIT" -eq 0 ]]; then
  CLASSIC_STATUS="present"
else
  CLASSIC_HTTP_STATUS=$(printf '%s\n' "$CLASSIC_RESPONSE" | awk '/^HTTP\/[0-9.]+ [0-9][0-9][0-9]/ { status=$2 } END { print status }')
  case "$CLASSIC_HTTP_STATUS" in
    404) CLASSIC_STATUS="absent" ;;
    403)
      # ... fallback read, then:
      if [[ -z "$CLASSIC_ENABLED" ]]; then
        if [[ "${ALLOW_UNVERIFIED_CLASSIC_PROTECTION:-0}" == "1" ]]; then
          CLASSIC_STATUS="unverified"
          echo "WARNING: this token cannot inspect ... still passed." >&2
        else
          echo "Could not inspect ..." >&2
          exit 1
        fi
      fi
      ;;
    *) echo "Could not inspect ..." >&2; exit 1 ;;
  esac
fi
```
D-18's script should introduce its OWN escape-hatch env var (e.g. `ALLOW_UNVERIFIED_ENVIRONMENT_PROTECTION=1`), following the identical name-and-behavior convention.

**Terminal summary line** (lines 158-171): three-way branch (`FAIL` / `unverified` WARNING+pass / full pass), each with a single human-readable summary echo — copy this exact "OK for X: ..." / "PARTIAL for X: ..." phrasing convention.

**Placement analog:** `.github/workflows/branch-protection.yml` is the precedent for keeping this OUTSIDE `ci-required` (`workflow_run` trigger after CI completes, own workflow file, not a `needs:` member of the required check).

---

### `lib/mix/tasks/release.pins.ex` (utility Mix task, transform)

**Analog 1 — derivation logic to reuse verbatim:** `test/threadline/version_truth_doc_contract_test.exs:24-45`
```elixir
@version Threadline.MixProject.project()[:version]
@parsed Version.parse!(@version)
@expected_pin_version "#{@parsed.major}.#{@parsed.minor}.0"

defp doc_files do
  ["README.md" | Path.wildcard("guides/**/*.md")]
end
```
Per D-04/RESEARCH.md's Claude's Discretion note: DELIBERATELY duplicate this into the new task rather than sharing a module — the advisor recommendation and the "Code Examples" section of RESEARCH.md both confirm this. Reuse the exact SAME `doc_files/0` glob and the exact SAME `pin_regex` (`~r/\{:threadline,\s*"~>\s*([0-9][0-9.]*)"\}/`, from `version_truth_doc_contract_test.exs:50`) so the task and the test can never drift on which lines count.

**Analog 2 — Mix.Task shape and shell-info idiom:** `lib/mix/tasks/threadline.install.ex:1-20`
```elixir
defmodule Mix.Tasks.Threadline.Install do
  @shortdoc "Generates Threadline audit schema migration"
  @moduledoc """
  ...
  """
  use Mix.Task
  import Mix.Generator

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.config", [])
    ...
    Mix.shell().info("...")
  end
end
```
`mix release.pins` should follow `@shortdoc`/`@moduledoc`/`use Mix.Task`/`@impl Mix.Task def run(_args)` exactly, but WITHOUT a `@shortdoc` that would surface as noise for adopters if this task is namespaced `release.pins` rather than `threadline.release.pins` — confirm naming against D-20's packaging concern (any task under `lib/mix/tasks/` ships in the published tarball per the `files:` wildcard unless excluded; a maintainer-only task like `release.pins` should either be gitignored from the package via a D-20-style contract exclusion, OR live under a clearly maintainer-scoped name, matching the `critic.*` precedent this same phase is excluding).

**Error handling idiom (file write failure):** no existing task in this repo does a destructive regex-rewrite of tracked docs; use `File.write!/2` for fail-loud behavior (matches this repo's convention of `Mix.raise/1` on any non-zero shell status, see `mix.exs:354-358` `ensure_clean_tree!/0` and `run_release_step!/1`).

---

### `.github/workflows/release.yml` — `smoke-published` job (D-09)

**Analog:** `verify-hex-evaluator` job, `.github/workflows/ci.yml:380-419` (full block read)
```yaml
verify-hex-evaluator:
  name: Hex evaluator smoke (threadline from hex.pm)
  runs-on: ubuntu-24.04
  timeout-minutes: 15
  env:
    DB_HOST: localhost
    MIX_ENV: test
  services:
    postgres:
      image: postgres:16
      env:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
        POSTGRES_DB: threadline_test
      ports:
        - 5432:5432
      options: >-
        --health-cmd pg_isready
        --health-interval 10s
        --health-timeout 5s
        --health-retries 5
  steps:
    - uses: actions/checkout@v5
    - uses: erlef/setup-beam@v1
      with:
        elixir-version: "1.17.3"
        otp-version: "27.0"
    - name: Ensure hex_evaluator_test database exists
      env:
        PGPASSWORD: postgres
      run: |
        createdb -h "$DB_HOST" -U postgres hex_evaluator_test 2>/dev/null || true
    - name: Verify Hex-published threadline adopt path
      run: mix verify.hex_evaluator
```
Copy this block into `release.yml` nearly verbatim (RESEARCH.md's Open Question 2 explicitly recommends this over modeling on `publish-hex`), with two required changes:
1. `job id: smoke-published` (stable job id per D-09), `name:` free to differ (e.g. "Smoke test published release").
2. Set the mode-switch env var the D-07 `priv/ci/hex_evaluator/mix.exs` reads (e.g. `THREADLINE_HEX_EVALUATOR_MODE=published`) so the dep resolves `{:threadline, "== <version>", repo: "hexpm"}` instead of the rehearsal registry — per D-07/D-10, this job runs AFTER `publish-hex` (`needs: [release-ref, publish-hex]`), consuming the version from `release-ref`'s existing output (see `release-ref` job, `.github/workflows/release.yml:175-224`, for its output-variable convention).
3. Per RESEARCH.md's "D-08 Mix Lock Semantics" finding: `mix.exs:339-340`'s existing `verify_hex_evaluator/1` alias ALREADY runs `mix deps.get` unconditionally before `mix test` — confirm this job invokes the SAME alias (`mix verify.hex_evaluator`) rather than a hand-rolled `mix test`, so the re-resolve-on-mode-switch is automatic and doesn't need new CI-side logic.

**Job-graph wiring analog (needs: ordering):** `distribution-sync`'s existing `needs: [release-ref, publish-hex]` at `.github/workflows/release.yml:434-439` — extend to `needs: [release-ref, publish-hex, smoke-published]` per D-10.

**`ci-required` exclusion analog:** `.github/workflows/ci.yml:2-4`'s header comment enumerating `ci-required`'s member list — `smoke-published` must NOT be added to that enumeration or the `ci-required` job's `needs:`/`allowed-skips` list (D-09's explicit requirement).

---

### `priv/ci/hex_evaluator/mix.exs` — dep mode-switch (D-07)

**Analog:** itself, current shape (full file, 27 lines read):
```elixir
defp deps do
  [
    {:threadline, "~> 0.9.0"},
    {:ecto_sql, "~> 3.10"},
    {:postgrex, ">= 0.0.0"}
  ]
end
```
Rewrite as an env-driven branch, e.g.:
```elixir
defp deps do
  [threadline_dep() | shared_deps()]
end

defp threadline_dep do
  case System.get_env("THREADLINE_HEX_EVALUATOR_MODE", "rehearsal") do
    "published" ->
      version = System.fetch_env!("THREADLINE_PUBLISHED_VERSION")
      {:threadline, "== #{version}", repo: "hexpm"}

    "rehearsal" ->
      {:threadline, ">= 0.0.0", repo: "threadline_rehearsal"}
  end
end
```
No existing file in this repo does env-driven Mix dep selection — the closest structural precedent for "env var flips behavior" is `mix.exs`'s own `elixirc_paths(Mix.env())` pattern (`mix.exs:81-82`) and the `verify_ui_critique/1` `ANTHROPIC_API_KEY`-presence branch (`mix.exs:308-336`) — both fail loudly/skip cleanly rather than silently defaulting. Follow that same "explicit branch, loud on missing required env" convention for `published` mode (use `System.fetch_env!/1`, not `System.get_env/2` with a silent fallback, for the version — a missing version in published mode must hard-fail, not silently rehearse).

**Local Hex repo setup (D-07's rehearsal mode):** no in-repo analog exists (new mechanism) — RESEARCH.md's "Don't Hand-Roll" section and Open Question 1 are the authoritative reference: `mix hex.registry build` + `mix hex.repo add NAME URL` (HTTP-served, not `file://` — plan an ephemeral HTTP server step per Open Question 1's recommendation) + `mix hex.build` from this tree's own tarball. This is genuinely new wiring; there is no closer existing analog than the `mix hex.build` step already used in `verify_release/1` (`mix.exs:214-224`) and `built_archive/0` (`release_artifact_contract_test.exs:286-329`).

---

### `CHANGELOG-GENERATED.md` + `release-please-config.json` split (D-11)

**Analog:** `release-please-config.json`'s existing `extra-files` split (full file read):
```json
"packages": {
  ".": {
    "changelog-path": "CHANGELOG.md",
    "include-v-in-tag": true,
    "extra-files": [
      {"type": "generic", "path": "guides/adoption-pilot-backlog.md"},
      {"type": "generic", "path": "guides/evaluating-threadline.md"}
    ]
  }
}
```
Change ONLY `changelog-path` to `"CHANGELOG-GENERATED.md"`. Do not add `CHANGELOG.md` anywhere in `extra-files` (it becomes fully human-owned, release-please must never touch it again). The ownership-split PROSE convention to copy for `CHANGELOG-GENERATED.md`'s header (if any prose header is added) is `bin/post-publish-distribution-sync`'s header comment (lines 8-20 of that file):
```bash
# Ownership split (see release-please-config.json `extra-files`):
#   - The SSOT line (...) is bumped by release-please IN THE RELEASE COMMIT via
#     the `generic` updater ... This script must NOT rewrite it ...
#   - This script owns ONLY the Hex attestation row ...
```
Same "which half of this file/pair does which owner touch" documentation convention should appear at the top of `CHANGELOG.md` once split (e.g. an HTML comment: `<!-- This file is human-owned. Bot-generated release notes live in CHANGELOG-GENERATED.md. -->`).

**`mix.exs` `package.files` / `docs.extras` analog:** `CHANGELOG.md` already appears in both `package.files` (`mix.exs:385`) and `docs[:extras]` (asserted at `release_artifact_contract_test.exs:75-81`). `CHANGELOG-GENERATED.md` must NOT be added to either — confirmed by `release_artifact_contract_test.exs:70-81`'s existing assertion shape (`assert "CHANGELOG.md" in files`) as the template for a NEW assertion (`refute "CHANGELOG-GENERATED.md" in files`) if D-11 needs one.

---

### `CHANGELOG.md` — highlights block + reorder (D-12, D-13, D-14)

**Analog:** itself — existing heading shapes (lines 1-11, full structure read):
```markdown
# Changelog

## [0.9.0](https://github.com/szTheory/threadline/compare/v0.8.0...v0.9.0) (2026-06-03)


### Features
...
```
D-12's new standing block goes directly below `# Changelog` (line 1), ABOVE the newest dated `## [x.y.z]` heading, using the exact heading text `## Unreleased — highlights` (no brackets — the `[` would collide with release-please's version-header regex per D-12's explicit warning).

**Orphaned block to fold in and delete** — `CHANGELOG.md:43-54` (verified location: sandwiched between `## [0.7.0]` at line 24 and `## [0.6.0]` at line 56):
```markdown
## [Unreleased]

### Added

- **Architecture documentation** — rewrote How Threadline Works as an end-to-end visual architecture guide and added a source-driven Code Walkthrough, with dark/light Mermaid rendering and the Threadline mark as the HexDocs favicon.

### Changed
...
```
Fold this content into the new `0.10.0` entry (this block documents real 0.10.0-era work per D-12/Pitfall 3), then delete the orphaned `## [Unreleased]` heading entirely.

**Section-order convention (D-13):** no existing dated entry in this file currently leads with a "breaking changes / required action" section — `0.10.0`'s entry is the first to need this ordering. Model the sub-heading vocabulary on `guides/upgrade-path.md`'s existing "Breaking changes: **None**. Required migration: **None**. Config changes: **None**." phrasing (see `guides/upgrade-path.md:96-98` quoted below) so the changelog and the upgrade guide use IDENTICAL wording for the same 0.10.0 facts.

**`bin/verify-release-shape`'s heading-shape contract** (already governs any new dated heading, lines 35-45):
```bash
HEADING_RE="^## \\[${ESC_VER}\\]( - ${DATE_RE}|\\([^)]*\\) \\(${DATE_RE}\\))$"
```
The `0.10.0` heading must match one of the two accepted shapes (`## [0.10.0] - YYYY-MM-DD` or release-please's auto-generated `## [0.10.0](<link>) (YYYY-MM-DD)`), and must NOT be a bare `## [0.10.0]` with no date (line 47-50 explicitly rejects that).

---

### Legacy `public`-schema E2E test (new, D-03)

**Analog:** `priv/ci/hex_evaluator`'s existing structure (its `mix.exs`, migration/test flow) combined with `mix.exs:338-346`'s `verify_hex_evaluator/1` alias shell sequence:
```
cd priv/ci/hex_evaluator && printf "n\n" | mix deps.get && mix compile --warnings-as-errors \
  && mix ecto.create --quiet -r HexEvaluator.Repo && mix ecto.migrate --quiet && mix test
```
D-03's fixture should live inside `priv/ci/hex_evaluator` (per CONTEXT.md's explicit steer: "The hex evaluator fixture is the natural home"), configured WITHOUT setting `storage_schema` (so it exercises the flipped `"public"` default from D-01), asserting the SQL read paths resolve unqualified — i.e. a NEW test module alongside whatever `priv/ci/hex_evaluator/test/` already contains, following that directory's existing ExUnit conventions (not read this session in full; the planner should `Read priv/ci/hex_evaluator/test/**` before writing this test to match its exact setup/teardown idiom).

**Unit-level precedent for `storage_schema: "public"` assertions:** existing `storage_schema` unit tests (not enumerated in this pass — Grep `test/threadline/storage_schema_test.exs` during planning) already exercise `"public"` at the SQL/opts level per CONTEXT.md D-03's own framing ("Today only unit tests exercise `storage_schema: "public"`"); D-03's new test is E2E/integration-level, one layer up.

---

### Contract strengthening — `version_truth_doc_contract_test.exs` Family B/D-06

**Analog:** the existing Family B test in the SAME file (`test/threadline/version_truth_doc_contract_test.exs:74-101`), which is the direct template for the new "inverse" assertion:
```elixir
test "every x-release-please-version marked line carries @version and is wired into release-please" do
  config = File.read!(@release_please_config)
  marked =
    for path <- doc_files(),
        line <- String.split(File.read!(path), "\n"),
        String.contains?(line, "x-release-please-version"),
        do: {path, line}

  assert marked != [], "..."

  for {path, line} <- marked do
    assert String.contains?(line, @version), "..."
    assert String.contains?(config, path), "..."
  end
end
```
D-06's new test should follow the identical `for path <- doc_files(), line <- String.split(...)` shape but INVERT the predicate: find lines matching the pin regex (`~r/\{:threadline,\s*"~>\s*([0-9][0-9.]*)"\}/`, already defined in Family A at line 50) and `refute String.contains?(line, "x-release-please-version")` for each. Add it as a NEW `test` block in the same module, reusing `doc_files/0` and the existing pin regex — do not redefine either.

---

### Contract strengthening — `release_artifact_contract_test.exs` `built_archive()` extension (D-20)

**Analog:** the existing archive-content assertion pattern in the SAME file (`test/threadline/release_artifact_contract_test.exs:137-146`):
```elixir
test "built Hex archive excludes repository evidence" do
  %{entries: entries, readable: readable} = built_archive()

  assert entries != [], "unpacked Hex archive contained no files"
  assert map_size(readable) > 0, "unpacked Hex archive contained no readable UTF-8 files"
  assert "lib/threadline.ex" in entries
  assert "mix.exs" in entries
  refute Enum.any?(entries, &String.starts_with?(&1, "test/fixtures/"))
  refute Enum.any?(entries, &String.starts_with?(&1, ".planning/"))
end
```
D-20's new assertion is a near-literal copy, adding refutations for the maintainer-only paths:
```elixir
refute Enum.any?(entries, &String.starts_with?(&1, "lib/mix/tasks/critic."))
refute Enum.any?(entries, &String.starts_with?(&1, "lib/threadline/critic_trust/"))
# + whatever the re-enumerated operator-surface stress/mechanical glob resolves to
# (RESEARCH.md flags CONTEXT.md's "~5,000 lines" vs. measured "3,379 lines" —
# re-run `wc -l` over lib/threadline/operator_surface/*stress*, *mechanical*
# before hardcoding the exclusion list; do not trust either figure literally)
```
`built_archive/0` (lines 286-329) is the shared fixture — already unpacks the REAL tarball via `mix hex.build --unpack`; no new helper needed, only new assertions using the existing `entries`/`readable` return shape.

**Packaging-mechanism pitfall to note in the new test's failure message:** `mix.exs:384-385`'s `files:` is directory-granular (`lib` wholesale), so the actual fix (per RESEARCH.md Pitfall 2) is EITHER narrowing `files:` OR (preferred, per RESEARCH.md's explicit recommendation) leaving `files:` alone and asserting exclusion via `built_archive()` — do not attempt to make `package.files` itself file-granular; extend the contract instead.

---

### `Threadline.StorageSchema` `@default` flip (D-01)

**Analog:** itself, single-line change at `lib/threadline/storage_schema.ex:10`:
```elixir
@default "threadline"
```
→
```elixir
@default "public"
```
No structural change needed elsewhere in the module — `get/1` (lines 25-29) already reads `@default` through `Application.get_env(:threadline, :storage_schema, @default)`, so the flip is purely the literal. Verify `config/test.exs:50` and `examples/threadline_phoenix/config/config.exs:16` (both already set `storage_schema: "threadline"` explicitly per CONTEXT.md D-01's "Verified clean" note) remain unaffected — no edit needed there.

---

### `guides/upgrade-path.md` re-scoping (D-15, D-16)

**Analog:** itself — the existing per-minor bullet template at lines 96-113 (D-16's new `0.9.x -> 0.10.x` row should follow this EXACT shape):
```markdown
- **0.8.x → 0.9.x**: Operator-surface first-class positioning and an accessibility pass. Breaking changes: **None**. Required migration: **None**. Config changes: **None**. For `capture-only` and `phoenix-surface` adopters: **nothing required**. See `CHANGELOG.md` `[0.9.0]`.
```
D-16's row must diverge from this template's "nothing required" framing to actually enumerate the four adopter actions (S3 dep swap, operator-surface routes, `Storage.put/2` narrowing, `@moduledoc false` modules) — do not copy the "nothing required" language verbatim; only copy the STRUCTURE (bolded bump label, "Breaking changes:", "Required migration:", "Config changes:", per-lane callout, `CHANGELOG.md` cross-reference).

**Line 89's "no storage-schema action" claim to re-scope (D-15):** locate and read the exact line in `guides/upgrade-path.md:89` region (the "Storage-schema migration expectation" section starting near line 108 of the excerpt read this session) before editing — it currently frames the storage-schema note as settled by the 0.6-0.9 era; D-15 requires moving/rephrasing this into the NEW 0.10.0-specific row rather than leaving it implying an earlier era already covered it.

---

### `mix threadline.install`, `guides/getting-started-saas.md` steering (D-02)

**Analog:** `lib/mix/tasks/threadline.install.ex` (itself, full file structure read — lines 1-60+):
```elixir
@impl Mix.Task
def run(_args) do
  Mix.Task.run("app.config", [])
  path = migrations_path()
  ...
  Mix.shell().info("Threadline audit schema migration already exists — skipping.")
  ...
end
```
D-02's steering is additive: an `Mix.shell().info/1` call (same idiom already used throughout this task for status messages) printed when `Application.get_env(:threadline, :storage_schema)` is unset, recommending the dedicated schema for a NEW install — follow the exact `Mix.shell().info("...")` phrasing convention already established in this file rather than introducing `IO.puts` (this task never uses raw `IO.puts`).

## Shared Patterns

### Fail-closed live-GitHub-state verification (outside `ci-required`)
**Source:** `bin/verify-branch-protection` (full script) + `.github/workflows/branch-protection.yml` (placement precedent)
**Apply to:** `bin/verify-environment-protection` (D-18) exclusively this phase.
```bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# tool-presence guards (jq, gh) -> repo-slug resolution -> gh api read with
# named FAIL (a)/(b)/(c) blocks -> 403-fallback with ALLOW_UNVERIFIED_* escape
# hatch -> three-way terminal summary (FAIL / PARTIAL-WARNING / OK)
```

### Doc-contract derivation from `@version` (never hardcode a literal)
**Source:** `test/threadline/version_truth_doc_contract_test.exs:24-35`
**Apply to:** `mix release.pins` (D-04), the D-06 strengthening, and D-16's changelog/upgrade-path row cross-references.
```elixir
@version Threadline.MixProject.project()[:version]
@parsed Version.parse!(@version)
@expected_pin_version "#{@parsed.major}.#{@parsed.minor}.0"
```

### `built_archive()` — the single fixture for all packaging assertions
**Source:** `test/threadline/release_artifact_contract_test.exs:286-329`
**Apply to:** D-20's new exclusion assertions, D-03's legacy-schema test if it needs to assert on packaged content, any future packaging contract.
```elixir
defp built_archive do
  # mix hex.build --unpack --output <tmp>, then walk files, split into
  # entries (all relative paths) and readable (UTF-8-valid content map)
end
```
Never re-implement tarball unpacking — call this helper (or its sibling in a new test file that requires the same shape) instead.

### `verify.release` / `verify.hex_evaluator` alias-driven CI steps (fail loud via `Mix.raise/1`)
**Source:** `mix.exs:214-224` (`verify_release/1`), `mix.exs:338-346` (`verify_hex_evaluator/1`), `mix.exs:360-367` (`run_release_step!/1`)
**Apply to:** any new alias this phase needs to add (e.g. wiring D-04's `mix release.pins` into a maintainer workflow, or extending `verify.release`'s step list).
```elixir
defp run_release_step!(command) do
  cmd = "bash -lc 'set -euo pipefail && #{command}'"
  case Mix.shell().cmd(cmd) do
    0 -> :ok
    status -> Mix.raise("verify.release failed while running #{command} (#{status})")
  end
end
```

### File-scoped ownership split, documented in a header comment
**Source:** `bin/post-publish-distribution-sync:8-20` (header comment) + `release-please-config.json`'s `extra-files` array
**Apply to:** D-11's `CHANGELOG.md`/`CHANGELOG-GENERATED.md` split — document which automation owns which file/block in a comment at the top of the human-owned file, exactly as this script's header documents the SSOT-line-vs-Hex-attestation-row split within a SINGLE file.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `priv/ci/hex_evaluator`'s local Hex rehearsal registry wiring (D-07's `mix hex.registry build` + HTTP-serve step) | CI/config | event-driven (ephemeral registry server) | No existing job in this repo stands up a local Hex registry; RESEARCH.md's "Don't Hand-Roll" and Open Question 1 sections are the authoritative reference instead of an in-repo file — follow Hex's own documented `mix help hex.registry` worked example (spin up `erl -s inets` or `python3 -m http.server`) rather than inventing a pattern |

## Metadata

**Analog search scope:** `bin/`, `lib/mix/tasks/`, `lib/threadline/storage_schema.ex`, `test/threadline/*contract*`, `.github/workflows/{release,ci,branch-protection}.yml`, `priv/ci/hex_evaluator/`, `CHANGELOG.md`, `guides/upgrade-path.md`, `release-please-config.json`, `mix.exs`
**Files scanned:** ~20 (all read in full or via targeted `sed -n`/`grep -n` ranges per file-size)
**Pattern extraction date:** 2026-09-22
**Tracked-source gate:** all 19 analog paths confirmed via `git ls-files` — none are gitignored mirrors; no substitutions needed.
