# Phase 215: Supply Chain Gate - Pattern Map

**Mapped:** 2026-09-26
**Files analyzed:** 8 (new/modified)
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|---------------|
| `mix.exs` (aliases + `verify_deps_audit/1` + `assert_hex_version!/0`) | config / build-tooling | request-response (shell subprocess, exit code) | `mix.exs:217-224` (`verify_bench/1`) + `mix.exs:246-255` (`verify_example/1`) | exact |
| `mix.exs` (`ci.all` entry for `verify.deps_audit`) | config | batch | `mix.exs:190-213` (`ci.all` list) | exact |
| `.github/workflows/ci.yml` (`verify-deps-audit` job + `ci-required` needs: entry) | CI workflow / route | request-response (per-PR gate) | `.github/workflows/ci.yml:278-380` (`verify-test`/`verify-hex-evaluator` job shape) + `:923-954` (`ci-required` needs: list) | exact |
| `.github/workflows/deps-health.yml` (new) | CI workflow | event-driven (cron) + pub-sub (issue upsert) | `.github/workflows/flake-detection.yml` | exact |
| `test/threadline/deps_audit_contract_test.exs` (new) | test (contract) | transform (source-parsing, offline) | `test/threadline/ci_topology_contract_test.exs` (roster/needs: derive pattern, lines ~330-365, 558-596) | exact |
| `test/fixtures/deps_audit/vulnerable_lock/` (new fixture project) | test fixture | file-I/O + event-driven (subprocess) | `test/test_helper.exs` exclusion-tag pattern (`pgbouncer_topology: true`) | role-match |
| `test/threadline/ignore_advisories_contract_test.exs` (new) | test (contract) | transform (static mix.exs `:hex` config parse) | `test/threadline/ci_topology_contract_test.exs` (source-parsing style) | role-match |
| `test/threadline/deps_health_doc_contract_test.exs` (new) | test (doc-contract) | transform (doc ↔ workflow cross-check) | `test/threadline/ci_coverage_doc_contract_test.exs` | exact |
| `CONTRIBUTING.md` (new "Dependency freshness policy" section + `ci-required` needs: roster row) | docs | transform | `CONTRIBUTING.md:458-484` (existing "### `ci-required` needs: roster" section) | exact |
| `CHANGELOG.md` (Unreleased — highlights entry) | docs | transform | `CHANGELOG.md:1-30` (Unreleased section convention) | exact |

## Pattern Assignments

### `mix.exs` — `verify.deps_audit` alias + `verify_deps_audit/1` (config, request-response)

**Analog:** `mix.exs:217-224` (`verify_bench/1`) and `mix.exs:246-255` (`verify_example/1`)

**Aliases registration pattern** (`mix.exs:126-169`, inside `defp aliases do [...]`):
```elixir
"verify.bench": &verify_bench/1,
```
Add `"verify.deps_audit": &verify_deps_audit/1,` in the same list, next to `verify_bench`/`verify_hex_evaluator`.

**Env keyword list at top of `defp project do` block** (`mix.exs:13-28`) assigns each `verify.*` alias its Mix env (`:dev` vs `:test`). `verify.bench` is not listed there (it shells out and sets its own env per-command), so `verify.deps_audit` likely does not need an entry either — confirm during planning whether `hex.audit` needs `:dev` or `:test`.

**Core cross-directory shell pattern** (`mix.exs:217-224`, `verify_bench/1`):
```elixir
defp verify_bench(_args) do
  cmd =
    "bash -lc 'set -euo pipefail && cd bench && mix deps.get && MIX_ENV=test mix run scripts/seed_audit_changes.exs && ...'"

  case Mix.shell().cmd(cmd) do
    0 -> :ok
    status -> Mix.raise("verify.bench failed (#{status})")
  end
end
```

**Interactive-Hex-reauth avoidance pattern** (`mix.exs:246-255`, `verify_example/1`) — relevant because `verify_deps_audit` also runs `mix deps.get` in nested dirs without a cached Hex token:
```elixir
defp verify_example(_args) do
  cmd =
    "bash -lc 'set -euo pipefail && cd examples/threadline_phoenix && printf \"n\\n\" | mix deps.get && mix compile --warnings-as-errors && ...'"

  case Mix.shell().cmd(cmd, env: [{"MIX_ENV", "test"}]) do
    0 -> :ok
    status -> Mix.raise("verify.example failed (#{status})")
  end
end
```
Note the `printf "n\n" | mix deps.get` idiom to decline interactive re-auth — reuse this for `verify_deps_audit`'s per-directory `mix deps.get` calls (root, `bench`, `examples/threadline_phoenix`), since all three run in CI where no Hex session exists.

**Error handling pattern**: every `verify_*` private function in this file follows the same shape — `case Mix.shell().cmd(cmd) do 0 -> :ok; status -> Mix.raise("verify.X failed (#{status})") end`. Follow this exactly; do not introduce a different error-reporting style (e.g. no `{:error, _}` tuples, no `System.halt`).

**`ci.all` list pattern** (`mix.exs:190-213`): each entry is either a bare alias name (`"verify.format"`) or a `"cmd env VAR=val mix verify.X"` string for cases needing a specific env. RESEARCH.md's Open Question (Sampling Rate section) flags that `verify.deps_audit` likely SHOULD be added here (unlike `verify.bench`/`verify.release`, which are release-lane-only and deliberately excluded — see the comment at `mix.exs:139-141` explaining `verify.bump_rehearsal`'s exclusion, and the identical precedent applies to `verify.bench`). Confirm against `ci_topology_contract_test.exs`'s existing "`ci.all` does NOT include `verify.bench`/`verify.release`" assertions before deciding placement — a new test may need to assert the opposite (inclusion) for `verify.deps_audit`.

---

### `.github/workflows/ci.yml` — `verify-deps-audit` job + `ci-required` needs: entry (route, request-response)

**Analog:** `verify-test` job shape (`ci.yml:53-104` header comment, job body `278-361`) and the `ci-required` needs: list (`ci.yml:923-940`)

**Job id contract comment** (`ci.yml:1-2`) — MUST be updated when adding the new job id, this is a load-bearing single-source-of-truth line asserted by `ci_topology_contract_test.exs`:
```
# Job id contract — stable YAML `jobs:` keys are relied on by docs and `act`:
# verify-format, verify-credo, verify-dialyzer, verify-compile-no-optional, verify-test, verify-pgbouncer-topology, verify-hex-evaluator, verify-example-browser, verify-mechanical, verify-capture, verify-docs, verify-hex-package, verify-release-shape, verify-bump-rehearsal, ci-required
```
Add `verify-deps-audit` to this comma list in the same commit as the job.

**Basic job shape** (`ci.yml:278-330`, `verify-test`):
```yaml
verify-test:
  name: Run test suite
  runs-on: ${{ matrix.runner }}
  timeout-minutes: 20
  env:
    DB_HOST: localhost
    MIX_ENV: test
  steps:
    - uses: actions/checkout@v5
    - uses: erlef/setup-beam@v1
      with:
        elixir-version: "1.17.3"
        otp-version: "27"
    - name: Cache deps
      uses: actions/cache@v4
      with:
        path: deps
        key: ${{ runner.os }}-mix-deps-${{ hashFiles('mix.lock') }}
        restore-keys: ${{ runner.os }}-mix-deps-
    - name: Install dependencies
      run: mix deps.get
    - name: Compile (warnings as errors)
      run: mix compile --warnings-as-errors
    - name: Run tests
      run: mix verify.test
```
`verify-deps-audit` needs NO postgres `services:` block (unlike `verify-test`/`flake-detection`) since `mix hex.audit` and `deps.unlock --check-unused` do not touch the DB — model it closer to `verify-compile-no-optional` (`ci.yml:253-278`, a lightweight no-DB job) than to `verify-test`.

**`ci-required` needs: list** (`ci.yml:923-940`):
```yaml
ci-required:
  name: CI required
  if: always()
  needs:
    - verify-format
    - verify-credo
    - verify-dialyzer
    - verify-compile-no-optional
    - verify-test
    - verify-hex-evaluator
    - verify-example-browser
    - verify-mechanical
    - verify-capture
    - verify-pgbouncer-topology
    - verify-docs
    - verify-hex-package
    - verify-release-shape
    - verify-bump-rehearsal
```
Add `- verify-deps-audit` to this list **in the same commit** as adding both the job and the CONTRIBUTING.md roster row — `ci_topology_contract_test.exs` fails in both drift directions (job present but undocumented, or documented but not required) if these three edits land separately.

---

### `.github/workflows/deps-health.yml` (new, event-driven + pub-sub)

**Analog:** `.github/workflows/flake-detection.yml` (near-verbatim reuse of the issue-upsert leg)

**Trigger + permissions shape** (`flake-detection.yml:15-44`):
```yaml
name: Flake Detection
on:
  workflow_dispatch:
  schedule:
    - cron: "0 7 * * *"
permissions:
  contents: read
jobs:
  verify-flake:
    name: Suite repeat-until-failure (broken vs flaky)
    runs-on: ubuntu-24.04
    timeout-minutes: 180
    permissions:
      contents: read
      issues: write
```
Adapt for `deps-health.yml`: same `workflow_dispatch` + weekly `schedule:` cron, `permissions: contents: read` at top-level and `issues: write` scoped to the job, no `services:` block needed (no DB).

**Issue-upsert step, reuse verbatim** (`flake-detection.yml:157-206`):
```yaml
- name: Open or update the flake tracking issue
  if: always() && steps.classify.outputs.classification != 'pass'
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    TITLE_PREFIX: "Flake Detection: test suite"
    LABEL: ci-flake
    ...
  run: |
    set -euo pipefail
    ...
    body_file=$(mktemp)
    trap 'rm -f "$body_file"' EXIT
    cat > "$body_file" <<EOF
    ${headline}
    ...
    EOF
    bin/upsert-ci-issue --marker "$TITLE_PREFIX" \
      --title "$TITLE_PREFIX reported ${CLASSIFICATION}" \
      --body-file "$body_file" --label "$LABEL" \
      --label-description "Flake Detection lane: suite reported broken, flaky, or unknown" \
      --label-color D93F0B
```
For `deps-health.yml`: marker `"Dependency health"`, label `ci-deps` (distinct color, e.g. `FBCA04` per RESEARCH.md), label-description `"Weekly hex.audit + hex.outdated findings"`, `if:` gated on `steps.audit.outputs.has_findings == 'true'` (an equivalent to `classify.outputs.classification != 'pass'`).

**`bin/upsert-ci-issue` signature (reuse as-is, zero modification)** — full source read this session (`bin/upsert-ci-issue:1-31`):
```bash
#!/usr/bin/env bash
set -euo pipefail
# --marker, --title, --body-file, --label (required), --label-description, --label-color
"$GH_BIN" label create "$label" --description "$label_description" --color "$label_color" 2>/dev/null || true
issues=$("$GH_BIN" issue list --state open --label "$label" --search "$marker in:title" --json number,title)
matches=$(printf '%s' "$issues" | jq -c --arg marker "$marker" '[.[] | select((.title | type) == "string" and (.title | startswith($marker)))]')
count=$(printf '%s' "$matches" | jq 'length')
case "$count" in
  0) "$GH_BIN" issue create --title "$title" --label "$label" --body-file "$body_file" ;;
  1) number=...; "$GH_BIN" issue comment "$number" --body-file "$body_file" ;;
  *) die "ambiguous marker matched $count open issues" ;;
esac
```
No changes needed to this binary — call it with a new `--marker`/`--title`/`--label`/`--body-file` only.

**`errexit`-independent classification step idiom** (`flake-detection.yml:83-100`) — apply the same pattern if `deps-health.yml`'s audit step can fail non-fatally and still needs its output classified/reported:
```yaml
run: |
  set +e
  set -uo pipefail
  mix hex.audit 2>&1 | tee audit.log
  exit_code="${PIPESTATUS[0]}"
  echo "exit_code=$exit_code" >> "$GITHUB_OUTPUT"
  exit 0
```

---

### `test/threadline/deps_audit_contract_test.exs` (new, contract, transform)

**Analog:** `test/threadline/ci_topology_contract_test.exs` (roster-derive-from-source pattern)

**Job-block isolation + needs: derive pattern** (`ci_topology_contract_test.exs:558-596` region, read this session):
```elixir
defp ci_required_block do
  yaml = read_rel!([".github", "workflows", "ci.yml"])

  case String.split(yaml, "\n  ci-required:\n", parts: 2) do
    [_, tail] -> tail
    _ -> flunk("could not find a \"  ci-required:\" job in .github/workflows/ci.yml — ...")
  end
end

defp ci_required_needs do
  block = ci_required_block()

  case Regex.run(~r/    needs:\n((?:      - .+\n)+)/, block) do
    [_, items] ->
      items
      |> String.split("\n", trim: true)
      |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("- ")))

    nil -> []
  end
end

defp documented_needs_section do
  contributing = File.read!(@contributing)
  assert String.contains?(contributing, @ci_required_roster_heading), "..."

  contributing
  |> String.split(@ci_required_roster_heading, parts: 2)
  |> List.last()
  |> String.split(~r/\n#+ /, parts: 2)
  |> List.first()
end

defp documented_needs_roster do
  documented_needs_section()
  |> then(&Regex.scan(~r/^- `([a-z0-9-]+)`$/m, &1))
  |> Enum.map(fn [_, id] -> id end)
end

test "ci-required's needs: roster matches CONTRIBUTING.md in both drift directions and stays non-vacuous" do
  actual = ci_required_needs()
  documented = documented_needs_roster()

  assert length(actual) >= 10, "..."
  assert (actual -- documented) == [], "..."
  assert (documented -- actual) == [], "..."
end
```
This existing test is generic over the roster contents — it does NOT need modification when `verify-deps-audit` is added to both `ci.yml` and `CONTRIBUTING.md` in the same commit; it will simply pass with the new entry included. `deps_audit_contract_test.exs` should instead assert the *shape* of the new alias/job itself:
- `mix.exs` contains `"verify.deps_audit": &verify_deps_audit/1,` in `aliases()`
- `verify_deps_audit/1` shells into all three lockfile directories (`.`, `bench`, `examples/threadline_phoenix`) — assert via source substring/regex on `mix.exs`, same style as `ci_topology_contract_test.exs`'s `mix_exs =~ ~s(...)` assertions (e.g. line ~370 `{mix_exs =~ ~s("verify.dialyzer": ["dialyzer --no-check"]), "..."}`)
- `verify_deps_audit/1` asserts `Hex.version() >= "2.5.1"` — assert via source substring
- `.github/workflows/ci.yml` has a `verify-deps-audit:` job and it appears in `ci-required`'s `needs:` (reuse `ci_required_needs/0`-equivalent helper, or extend the existing one if colocating)

**Boolean assertion-list style** (`ci_topology_contract_test.exs` `dialyzer_topology_errors/3`, read this session) — the file collects a list of `{boolean, message}` tuples and asserts each, giving one loud, named failure per broken invariant rather than one big assertion:
```elixir
[
  {mix_exs =~ ~s("verify.dialyzer": ["dialyzer --no-check"]),
   "verify.dialyzer must be the stable local no-check command"},
  {ci_all_entries(mix_exs) |> Enum.count(&(&1 == "cmd env MIX_ENV=dev mix verify.dialyzer")) == 1,
   "ci.all must invoke verify.dialyzer exactly once in the CI job's dev environment"},
  ...
]
```
Follow this list-of-tuples idiom for `deps_audit_contract_test.exs`'s many source-shape assertions.

---

### `test/fixtures/deps_audit/vulnerable_lock/` (new fixture project, file-I/O + event-driven)

**Analog:** `test/test_helper.exs` exclusion-tag pattern (`test/test_helper.exs:1-7`)
```elixir
ExUnit.start()

topology_pooler? = System.get_env("THREADLINE_PGBOUNCER_TOPOLOGY") == "1"

# Topology tests need PgBouncer + bootstrap DDL; keep them out of default `mix test`.
exclude = if(topology_pooler?, do: [], else: [pgbouncer_topology: true])
ExUnit.configure(exclude: exclude)
```
Mirror this exact shape for the network-dependent negative-fixture test: add `deps_audit_network? = System.get_env("THREADLINE_DEPS_AUDIT_NETWORK") == "1"` (or reuse RESEARCH.md's suggested `@tag :deps_audit_network` / `--only deps_audit_network` invocation instead of an env-var exclude — either matches this file's existing precedent of tag-based, not directory-based, suite splitting). No code in `test_helper.exs` needs a fixture-specific DB step; the fixture project is a standalone `mix.exs`+`mix.lock` pair invoked via `System.cmd("mix", ["hex.audit"], cd: fixture_dir)`, analogous to how `verify_example/1` shells into `examples/threadline_phoenix` as a nested Mix project.

---

### `test/threadline/ignore_advisories_contract_test.exs` (new, contract, transform)

**Analog:** `test/threadline/ci_topology_contract_test.exs` (static source-parsing style, same as above)

No `ignore_advisories` usage exists yet in `mix.exs` to copy from — this test parses the `:hex` project config key (currently absent) and must assert on a repo-invented comment/annotation convention (reason + reachability + review-by date) since Hex's own `ignore_advisories` list carries no structured metadata (confirmed via RESEARCH.md `mix help hex.audit`). Structure the test the same way as `deps_audit_contract_test.exs` above: read `mix.exs` as a string, regex/substring-match the `:hex` config block and its preceding comment lines, assert a list of `{boolean, message}` tuples.

---

### `test/threadline/deps_health_doc_contract_test.exs` (new, doc-contract, transform)

**Analog:** `test/threadline/ci_coverage_doc_contract_test.exs` (full file read this session, 92 lines — copy this shape closely, it is the closest existing doc-contract precedent)

**Full pattern to copy:**
```elixir
defmodule Threadline.CiCoverageDocContractTest do
  @moduledoc """
  [explain what drifted and why this test exists, cite the phase/decision]
  """
  use ExUnit.Case, async: true

  @repo_root File.cwd!()
  @workflow_paths [
    Path.join([@repo_root, ".github", "workflows", "deps-health.yml"])
  ]
  @contributing Path.join(@repo_root, "CONTRIBUTING.md")
  @coverage_heading "## Dependency freshness policy"  # or similar new heading

  defp things_in_workflow do
    # regex-scan the workflow for the concrete facts the doc must state
    # (e.g. cron schedule, label `ci-deps`, lockfiles covered)
  end

  defp doc_section do
    contributing = File.read!(@contributing)
    assert String.contains?(contributing, @coverage_heading), "..."

    contributing
    |> String.split(@coverage_heading, parts: 2)
    |> List.last()
    |> String.split(~r/\n## /, parts: 2)
    |> List.first()
  end

  test "the workflow scan finds the expected markers at all" do
    # non-vacuous guard — same "derive source broken" failure mode as ci_coverage_doc_contract_test.exs:63-71
  end

  test "every fact the workflow carries appears in the CONTRIBUTING.md section" do
    # same row/substring-match style as ci_coverage_doc_contract_test.exs:73-90
  end
end
```
Two deliberately distinct failure modes to preserve: (1) doc row/fact missing for something the workflow actually does (drift), and (2) the source-scan itself finding nothing (broken derive, would otherwise pass vacuously) — both are asserted as separate tests in the analog, at lines 63-71 and 73-90.

---

### `CONTRIBUTING.md` — new "Dependency freshness policy" section + `ci-required` needs: roster row (docs, transform)

**Analog:** `CONTRIBUTING.md:458-484`, the existing "### `ci-required` needs: roster" section (read this session)
```markdown
### `ci-required` needs: roster

This is what the single required check `CI required` actually proves: every
pull request merged to `main` proves each of the following jobs succeeded.
`test/threadline/ci_topology_contract_test.exs` derives this list from
`.github/workflows/ci.yml`'s `ci-required` job itself and fails in either
drift direction — ...

- `verify-format`
- `verify-credo`
- ...
- `verify-bump-rehearsal`

No `allowed-skips` or `allowed-failures` entry is documented here today, ...
```
Add `- \`verify-deps-audit\`` to this bullet list (in the same commit as the `ci.yml` job + needs: entry, per the roster-drift test's requirement). Also add a new "## Dependency freshness policy" (or similarly named) section describing: batched-per-release-train updates, no Dependabot version-update PRs (Dependabot **alerts**, a repo setting, is separate and out of scope for this doc), the `mix verify.deps_audit` gate, and the weekly `deps-health.yml` non-required issue. Model the new section's tone/structure on the existing "## CI Coverage" section (`CONTRIBUTING.md`, cited by `ci_coverage_doc_contract_test.exs:38` as `@coverage_heading "## CI Coverage"`) — a short prose intro followed by a table or bullet list, plus a closing note naming which test derives/enforces it.

---

### `CHANGELOG.md` — Unreleased entry (docs, transform)

**Analog:** `CHANGELOG.md:1-30`, the "## Unreleased — highlights" convention (read this session)
```markdown
## Unreleased — highlights

Highlights accumulate here as work lands, and this heading is retitled to the
dated release heading at release time. ...

_Nothing yet for the next release._
```
Replace `_Nothing yet for the next release._` with the SUP-01 fix entry, following the file's own stated convention (top of file: "breaking changes and required action come BEFORE the feature tour"). Commit type per `release-please-config.json` (confirmed this session): `fix(deps): ...` — both `fix` and `deps` are recognized, releasable types. Example shape (not copied verbatim from an existing entry since this is the first `Unreleased` entry of its kind, but matching the voice of the `[0.11.0]` entry immediately below it, e.g. "Capture now resolves every supported primary-key shape..."):
```markdown
### Security

- `mint` bumped to 1.10.1 (response-smuggling advisory) and `lazy_html` to
  0.1.13 (mutation XSS, test-only) — lockfile-only fixes, no `mix.exs` change.
```

## Shared Patterns

### Cross-directory Mix subprocess invocation
**Source:** `mix.exs:217-224` (`verify_bench/1`), `mix.exs:246-255` (`verify_example/1`)
**Apply to:** `verify_deps_audit/1`'s three-lockfile fan-out (root, `bench`, `examples/threadline_phoenix`)
```elixir
cmd = "bash -lc 'set -euo pipefail && cd DIR && mix deps.get && ...'"
case Mix.shell().cmd(cmd) do
  0 -> :ok
  status -> Mix.raise("verify.X failed (#{status})")
end
```

### CI issue upsert (dedup, never duplicate)
**Source:** `bin/upsert-ci-issue`, reused by `.github/workflows/flake-detection.yml`
**Apply to:** `deps-health.yml`'s weekly `ci-deps` issue
```bash
bin/upsert-ci-issue --marker "<marker>" --title "<title>" \
  --body-file "$body_file" --label "<label>" \
  --label-description "<desc>" --label-color <hex>
```

### Same-commit roster/doc-drift contract
**Source:** `test/threadline/ci_topology_contract_test.exs` (`ci-required` needs: ↔ CONTRIBUTING.md), `test/threadline/ci_coverage_doc_contract_test.exs` (Playwright projects ↔ CONTRIBUTING.md CI Coverage table)
**Apply to:** `deps_audit_contract_test.exs` (job/alias wiring), `deps_health_doc_contract_test.exs` (deps-health.yml facts ↔ CONTRIBUTING.md), and the `ci.yml` + `CONTRIBUTING.md` needs: roster edit for `verify-deps-audit` itself
```elixir
missing_from_docs = actual -- documented
assert missing_from_docs == [], "..."
undocumented_extra = documented -- actual
assert undocumented_extra == [], "..."
```

### Test exclusion tag for network/topology-dependent tests
**Source:** `test/test_helper.exs:3-7` (`pgbouncer_topology: true`)
**Apply to:** the negative-fixture network test in `test/fixtures/deps_audit/vulnerable_lock/`
```elixir
exclude = if(some_env_flag?, do: [], else: [some_tag: true])
ExUnit.configure(exclude: exclude)
```

## No Analog Found

None — every file in scope has a strong (exact or role-match) existing analog in this repo.

## Metadata

**Analog search scope:** `mix.exs`, `.github/workflows/*.yml`, `bin/upsert-ci-issue`, `test/threadline/*_contract_test.exs`, `test/test_helper.exs`, `CONTRIBUTING.md`, `CHANGELOG.md` — all read/grepped this session, all confirmed git-tracked via `git ls-files`.
**Files scanned:** 9 (all named directly by RESEARCH.md's "Key analogs" pointer plus `ci_coverage_doc_contract_test.exs`, discovered as the closest doc-contract precedent for SUP-04)
**Pattern extraction date:** 2026-09-26
