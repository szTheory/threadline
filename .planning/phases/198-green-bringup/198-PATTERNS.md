# Phase 198: Green Bringup - Pattern Map

**Mapped:** 2026-08-27
**Files analyzed:** ~14 new/modified artifacts (workflows, mix.exs, test contracts, bin/ script, planning artifacts)
**Analogs found:** 12 / 14 strong matches; 2 have no direct in-repo analog (branch-protection script, archive register)

This is a CI/repo-hygiene phase — "files" are workflows, shell scripts, mix aliases, and contract tests, not application code. Pattern excerpts below are sized to be copy-paste starting points for executors.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `bin/verify-branch-protection` (new, D-12) | utility/script | request-response (gh API read + diff) | `bin/verify-release-shape` | exact (explicit sibling) |
| `.github/workflows/ci.yml` — new `ci-required` job (D-08/D-09) | config (CI job) | event-driven (aggregates job results) | existing jobs in same file (`verify-release-shape` as simplest single-step job) | role-match |
| `.github/workflows/ci.yml` — `timeout-minutes:` additions (D-16) | config | N/A | `.github/workflows/flake-detection.yml` (has full job shape to pattern-match step ordering) | role-match |
| `test/threadline/ci_topology_contract_test.exs` — D-25 additions | test (contract) | transform (read file, assert string/regex) | itself (existing tests in same file) | exact |
| `test/threadline/v1_23_charter_doc_contract_test.exs` — D-06 deletion | test | N/A | `test/threadline/version_truth_doc_contract_test.exs` (successor idiom, not a direct successor file) | role-match |
| `test/threadline/operator_surface/formless_pages_test.exs` → new `ui_form_policy` guard (D-07) | test + `lib/` module attribute | transform (exhaustive scan + derive) | `test/threadline/version_truth_doc_contract_test.exs` (derive-from-SSOT + non-empty-glob idiom) | exact (idiom transplant) |
| `test/test_helper.exs` — D-03 stale-schema tripwire | config/bootstrap | request-response (DB query) | itself (existing `storage_up`/`Migrator.run` block) + `test/support/storage_schema_case.ex` | exact |
| `mix.exs` — `test.reset`/`test.setup` aliases (D-04) | config (alias) | CRUD (drop/recreate DB) | `mix.exs` existing alias block (`verify.flake`, `verify.mechanical` as simple list-form aliases) | exact |
| `mix.exs` — D-05 zero-skips assertion test | test | transform (grep `test/**/*_test.exs`) | `test/threadline/ci_topology_contract_test.exs` (mix.exs-string-scan pattern) | exact |
| `CONTRIBUTING.md` CI Coverage table + doc-contract test (D-23) | doc + test | transform (derive table from workflow `--project` flags) | `mix.exs:88-90` `verify.doc_contract` idiom + `version_truth_doc_contract_test.exs` | exact (idiom transplant) |
| `.planning/ARCHIVE-REGISTER.md` (D-31) | config/artifact (register) | CRUD (append rows) | none found in-repo under that exact name — see "No Analog Found" | none |
| `198-TRIAGE.md`, `.planning/audits/*` (D-05, D-28, D-36-38) | artifact | batch/transform | no committed sibling triage doc found; format is Claude's discretion per CONTEXT.md | none |
| `.github/rulesets/main.json` (D-13) | config | CRUD (gh api POST) | none — new artifact type for this repo | none |
| `examples/threadline_phoenix/e2e/playwright.config.ts` — delete `chromium` project (D-15) | config | N/A | itself (existing `projects:` array) | exact |

## Pattern Assignments

### `bin/verify-branch-protection` (utility script)

**Analog:** `bin/verify-release-shape` (52 lines, read in full)

**Shell dialect / header** (lines 1-10):
```bash
#!/usr/bin/env bash
# CI / local: assert mix.exs @version and CHANGELOG match release hygiene (HEX-01 / HEX-02 style).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f mix.exs ]] || [[ ! -f CHANGELOG.md ]]; then
  echo "mix.exs and CHANGELOG.md required" >&2
  exit 1
fi
```
Copy the `set -euo pipefail`, `cd` to repo root via `$(dirname "${BASH_SOURCE[0]}")/..`, and early-exit-with-`>&2`-message-then-`exit 1` style verbatim. No JSON parsing in the analog (pure grep/sed) — `bin/verify-branch-protection` is the first script in this repo needing `jq` for nested JSON (`gh api` output), so guard for it explicitly (matching the analog's defensive precondition-checking style):
```bash
command -v jq >/dev/null 2>&1 || { echo "jq required" >&2; exit 1; }
```

**Exit-code / error-message style** (lines 12-22, 30-33):
```bash
VER_LINE=$(grep -E '^\s*@version\s+"' mix.exs | head -1 || true)
if [[ -z "$VER_LINE" ]]; then
  echo "No @version line found in mix.exs" >&2
  exit 1
fi
...
if ! grep -qF "@version \"$VER\"" mix.exs; then
  echo "Expected exactly one canonical @version \"$VER\" line (grep mismatch)." >&2
  exit 1
fi
```
Pattern: compute-then-assert, one `if` block per invariant, message states what was expected AND what triggered the failure — not just "check failed."

**Success output** (final line, no wrapping): `echo "Release shape OK for version $VER"` → `bin/verify-branch-protection`'s analogous final line should read something like `echo "Branch protection OK: exactly [\"CI required\"] required, confirmed emitted on main HEAD."` (this exact string is already drafted in `198-RESEARCH.md` Pattern 4 and can be copied directly — it implements both required halves: live-contexts diff via `gh api repos/:owner/:repo/rules/branches/main --jq '...'` and emission-proof via `gh api repos/:owner/:repo/commits/main/check-runs --jq '...'`).

**Invocation from CI** — mirror how `verify-release-shape` is wired at `ci.yml:566-573`:
```yaml
  verify-release-shape:
    name: Release metadata (version / changelog)
    ...
    steps:
      - name: Verify CHANGELOG and @version alignment
        run: bin/verify-release-shape
```
`bin/verify-branch-protection` gets its own job with the same one-step shape, `runs-on: ubuntu-24.04`, needs `gh` (already available in Actions runners) and `GH_TOKEN`/`GITHUB_TOKEN` env for API auth (see `release.yml`'s `GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}` pattern for env wiring, not re-excerpted here since D-12 only asked for the sibling shape).

---

### `test/threadline/ci_topology_contract_test.exs` — D-25 resurrection guards

**Analog:** itself — file already read in full (127 lines). Existing assertion style to copy verbatim for the two new tests:

**File-read helper already present** (lines 5-9):
```elixir
@repo_root File.cwd!()

defp read_rel!(segments) when is_list(segments) do
  @repo_root |> Path.join(Path.join(segments)) |> File.read!()
end
```

**String-containment assertion idiom** (lines 11-21, the existing PgBouncer test):
```elixir
test "ci.yml defines PgBouncer topology job with transaction pool and mix verify.topology" do
  yaml = read_rel!([".github", "workflows", "ci.yml"])

  assert String.contains?(yaml, "verify-pgbouncer-topology:")
  ...
end
```

**Pattern for D-25's two new assertions** (zero ANTHROPIC_API_KEY refs; exactly one `mix hex.publish`), following the same file-glob-and-assert style already used elsewhere in this file (`Regex.match?` for job-id checks at lines 91-97) — glob all five workflow files rather than hardcoding one, since the guard must survive future workflow additions:
```elixir
test "no workflow references ANTHROPIC_API_KEY (GREEN-09 resurrection guard)" do
  for path <- Path.wildcard(Path.join(@repo_root, ".github/workflows/*.yml")) do
    refute String.contains?(File.read!(path), "ANTHROPIC_API_KEY"),
           "#{path} references ANTHROPIC_API_KEY — the paid critic lane must stay " <>
             "structurally unreachable from CI (GREEN-09)."
  end
end

test "exactly one workflow runs mix hex.publish (GREEN-10 single publish path)" do
  publishers =
    for path <- Path.wildcard(Path.join(@repo_root, ".github/workflows/*.yml")),
        String.contains?(File.read!(path), "mix hex.publish"),
        do: path

  assert publishers == [Path.join(@repo_root, ".github/workflows/release.yml")],
         "expected exactly one workflow (release.yml) to run mix hex.publish, found: #{inspect(publishers)}"
end
```
Note: `Path.wildcard` here is the same "prove the glob isn't vacuous" spirit as `version_truth_doc_contract_test.exs:59` — assert `publishers` is non-empty/exact rather than merely `refute`-ing, so an accidentally-empty glob can't launder a false pass.

---

### D-06: `test/threadline/v1_23_charter_doc_contract_test.exs` → `git rm`, derive-from-SSOT idiom for any replacement

**Analog:** `test/threadline/version_truth_doc_contract_test.exs` (119 lines, read in full) — this is the proven idiom every future version-shape assertion should copy. Do NOT write a new file for D-06 itself (CONTEXT.md is explicit: `git rm`, no successor guard, honest admission of dropped coverage in `198-TRIAGE.md`). This excerpt is for any OTHER D-07/D-23-adjacent shape assertion that needs the same idiom.

**Derive-from-SSOT header** (lines 24-35):
```elixir
@version Threadline.MixProject.project()[:version]
@parsed Version.parse!(@version)

@expected_pin_version "#{@parsed.major}.#{@parsed.minor}.0"
```

**Non-empty-glob assertion — copy this exact shape to prevent vacuous passes** (lines 43-61):
```elixir
defp doc_files do
  ["README.md" | Path.wildcard("guides/**/*.md")]
end

test "..." do
  ...
  all_pins =
    for path <- doc_files(),
        [_full, captured] <- Regex.scan(pin_regex, File.read!(path)),
        do: {path, captured}

  assert all_pins != [],
         "no {:threadline, \"~> x.y.z\"} pin found across README + guides — the glob or " <>
           "regex is broken, which would let install-pin drift pass unguarded."

  for {path, captured} <- all_pins do
    assert captured == @expected_pin_version, "..."
  end
end
```
This two-step shape — (1) assert the collection produced by the glob/regex is non-empty, (2) assert every member matches the derived value — is the idiom to transplant into D-07's `@ui_form_policy` scan and D-23's CI-coverage doc contract.

---

### D-07: formless-page guard → `@ui_form_policy` self-declaring attribute + exhaustive scan

**Analog to replace:** `test/threadline/operator_surface/formless_pages_test.exs` (80 lines, read in full) — the exact non-exhaustive allowlist being superseded:
```elixir
@live_dir Path.join([File.cwd!(), "lib", "threadline", "operator_surface", "live"])

@formless_pages ~w(
  actor_live
  evidence_live
  export_status_live
  policy_redaction_live
  row_history_live
  transaction_live
)

@form_control_tokens ["<input", "<select", "<textarea", "<form"]

describe "display-only operator-surface pages stay formless" do
  for page <- @formless_pages do
    @tag page: page
    test "#{page}.ex contains no <input>/<select>/<textarea>/<form>" do
      page = unquote(page)
      path = Path.join(@live_dir, page <> ".ex")
      source = File.read!(path)

      offenders = Enum.filter(@form_control_tokens, &String.contains?(source, &1))

      assert offenders == [], "..."
    end
  end
end
```

**Verified full roster of `lib/threadline/operator_surface/live/*.ex`** (12 files, `ls` this session):
```
actor_live.ex
coverage_live.ex               <- excluded from old list (Phase 185, has native form)
evidence_live.ex
export_status_live.ex
policy_redaction_live.ex
retention_history_live.ex      <- excluded from old list (Phase 176, has prune-confirm form)
row_history_component.ex       <- NOT a page (component, not `*_live.ex` LiveView) — scan should exclude by naming convention or by lacking `use Phoenix.LiveView`
row_history_live.ex
start_live.ex
stress_live.ex                 <- NOT in old @formless_pages list at all (non-exhaustive gap D-07 exists to close); currently `@moduledoc false`, no attribute; is a dev/stress harness, not a shipped page — should self-declare `{:has_forms, "stress harness"}` OR be excluded from the live/ scan naturally if it's judged not a real operator page (per CONTEXT.md deferred note, resolve during D-07 implementation)
timeline_live.ex
transaction_live.ex
```
The old allowlist covers only 6 of these 9-10 real LiveView pages; `stress_live.ex` was silently unguarded — this is the concrete instance of the gap D-07 closes.

**Idiom to transplant for the self-declaring attribute** (`Module.register_attribute(persist: true)` — no existing in-repo analog for this exact mechanism; nearest precedent is the module-attribute-as-locked-constant pattern already used in `mechanical_checker.ex` lines 26-57, e.g. `@wcag_text_contrast_ratio 4.5` — those are compile-time constants, not `persist: true` attributes, so this is a genuinely new mechanism for the repo). Sketch:
```elixir
# In each lib/threadline/operator_surface/live/*_live.ex:
defmodule Threadline.OperatorSurface.Live.ActorLive do
  Module.register_attribute(__MODULE__, :ui_form_policy, persist: true)
  @ui_form_policy :formless
  ...
end
```
```elixir
# In the new test, replacing formless_pages_test.exs:
@live_dir Path.join([File.cwd!(), "lib", "threadline", "operator_surface", "live"])

defp live_page_files do
  Path.wildcard(Path.join(@live_dir, "*_live.ex"))
end

test "every operator_surface live page self-declares @ui_form_policy" do
  files = live_page_files()

  assert files != [],
         "no *_live.ex files found under operator_surface/live — the glob is broken."

  for path <- files do
    mod = module_for(path)
    Code.ensure_loaded!(mod)
    policy = mod.__info__(:attributes)[:ui_form_policy]

    assert policy != nil,
           "#{path} has no @ui_form_policy declaration — every LiveView page must " <>
             "self-declare :formless or {:has_forms, reason} (D-07)."

    case policy do
      [:formless] ->
        source = File.read!(path)
        offenders = Enum.filter(["<input", "<select", "<textarea", "<form"], &String.contains?(source, &1))
        assert offenders == [], "#{path} declares :formless but contains: #{inspect(offenders)}"

      [{:has_forms, _reason}] ->
        :ok
    end
  end
end
```
Copy the non-empty-glob assertion (`assert files != []`) from `version_truth_doc_contract_test.exs:59` verbatim in spirit. `row_history_component.ex` is naturally excluded by the `*_live.ex` glob (it's `row_history_component.ex`, not `*_live.ex`) — same "exclusion by construction, not by list" property D-07 wants.

---

### D-03: stale-schema tripwire in `test/test_helper.exs`

**Analog:** `test/test_helper.exs` itself (39 lines, read in full — note actual line numbers differ slightly from CONTEXT.md's citation of `:13`/`:39`; current file has the `storage_up` case block at lines 12-33 and `Ecto.Migrator.run/3` at line 38, not line 13/39 — re-verify exact line before inserting):
```elixir
unless topology_pooler? do
  case Ecto.Adapters.Postgres.storage_up(config) do
    :ok -> :ok
    {:error, :already_up} -> :ok
    {:error, reason} ->
      db = config[:database]
      host = config[:hostname] || "localhost"
      raise """
      Threadline tests: could not ensure PostgreSQL database #{inspect(db)} exists.
      ...
      """
  end
end

{:ok, _} = repo.start_link()

unless topology_pooler? do
  Ecto.Migrator.run(repo, :up, all: true)
end
```
The tripwire (D-03) inserts AFTER the final `Ecto.Migrator.run/3` call (currently line 38-39), inside the same `unless topology_pooler? do ... end` guard, following the exact "raise a multi-line heredoc naming the cause and the fix" style already established above:
```elixir
unless topology_pooler? do
  Ecto.Migrator.run(repo, :up, all: true)

  stale_public_audit_tables =
    Ecto.Adapters.SQL.query!(repo, """
    select table_name from information_schema.tables
    where table_schema = 'public' and table_name in
      ('audit_transactions', 'audit_changes', 'audit_actions')
    """, []).rows

  if stale_public_audit_tables != [] do
    raise """
    Threadline tests: this test database predates the storage-schema migration
    (priv/repo/migrations/20260607000000_threadline_storage_schema_default.exs).

    Found audit tables still in `public`: #{inspect(stale_public_audit_tables)}

    Fix: `mix test.reset` (drops and recreates the test database).
    """
  end
end
```
Guard against the `test/support/storage_schema_case.ex` `prepare_dual_storage!/1` false-positive: that helper creates a legitimate `"audit"` schema (line 50, `prepare_storage_schema!("audit", repo)`) — the tripwire query above is scoped to `table_schema = 'public'` specifically, which does NOT collide with the `audit` schema `prepare_dual_storage!/1` creates, so no additional guard is needed beyond the schema-name specificity already in the query. Scope this query to `Threadline.Test.Repo` only (never add to `lib/`), matching D-03's explicit constraint.

---

### D-04: `mix test.reset` / `test.setup` aliases

**Analog:** `mix.exs` existing alias block (lines 82-135, read in full). Simple list-form aliases already established as the idiom:
```elixir
"verify.format": ["format --check-formatted"],
"verify.credo": ["credo --strict"],
"verify.test": ["test"],
...
"verify.flake": ["test --repeat-until-failure 50"],
```
D-04's aliases follow the same list-form shape (no function-capture needed, unlike `verify.release`/`verify.example` which use `&verify_x/1`):
```elixir
"test.reset": ["ecto.drop --quiet -r Threadline.Test.Repo", "test"],
"test.setup": ["test"],
```
Per D-04, `test.reset` needs only the drop step since `test_helper.exs:12-33` already calls `storage_up/1` (recreate-on-run is already handled implicitly by the existing `storage_up` case-match on `{:error, :already_up}`).

**Comment style to match** (see the `verify.mechanical`/`verify.flake` inline comments at lines 97-101, 117-120) — every non-obvious alias gets a preceding comment explaining WHY:
```elixir
# Restore the safe recreate-by-default (Django-style) instead of Threadline's
# effective --keepdb-with-no-staleness-check. See D-04 / test/test_helper.exs tripwire.
"test.reset": ["ecto.drop --quiet -r Threadline.Test.Repo", "test"],
```

---

### D-05: zero-skips (`tag+exclude`) mechanical assertion

**Analog:** `test/threadline/ci_topology_contract_test.exs` lines 23-32 (the `ci.all` alias grep-and-slice idiom) shows the closest existing style for "grep source for a forbidden pattern and assert absence" — reuse for scanning `test/**/*_test.exs` for `@tag :skip` / `@moduletag :skip`:
```elixir
test "no test file carries @tag :skip or @moduletag :skip (D-05 anti-laundering cap)" do
  offenders =
    for path <- Path.wildcard("test/**/*_test.exs"),
        content = File.read!(path),
        String.contains?(content, "@tag :skip") or String.contains?(content, "@moduletag :skip"),
        do: path

  assert offenders == [], "these test files carry a skip tag, violating the zero-exclusions cap: #{inspect(offenders)}"
end

test "the only ExUnit exclude tag is pgbouncer_topology (D-05 anti-laundering cap)" do
  assert ExUnit.configuration()[:exclude] == [pgbouncer_topology: true]
end
```
Home this in `ci_topology_contract_test.exs` alongside the D-25 additions, or a new `test/threadline/zero_skips_contract_test.exs` — Claude's discretion per CONTEXT.md.

---

### D-23: CI Coverage doc contract

**Analog:** `mix.exs:88-90` `verify.doc_contract` alias idiom (list of `test test/threadline/*_contract_test.exs` file paths) — D-23(c) explicitly must NOT be wired as a new `verify.*` alias (Phase 204 deletes that alias), it must be a plain `*_contract_test.exs` picked up automatically by bare `mix test`. Use `version_truth_doc_contract_test.exs`'s derive-from-SSOT + non-empty-glob shape (excerpted above) to assert the `CONTRIBUTING.md` CI Coverage table's project list equals the actual `--project` flags in `ci.yml`/the new full-lane workflow:
```elixir
test "CONTRIBUTING.md CI Coverage table matches the actual --project flags in ci.yml" do
  ci_yaml = File.read!(".github/workflows/ci.yml")
  contributing = File.read!("CONTRIBUTING.md")

  projects_in_ci = Regex.scan(~r/--project[= ]([a-z-]+)/, ci_yaml) |> Enum.map(&List.last/1) |> Enum.uniq()

  assert projects_in_ci != [], "no --project flags found in ci.yml — the derive source is broken"

  for project <- projects_in_ci do
    assert String.contains?(contributing, project),
           "CONTRIBUTING.md CI Coverage table is missing project `#{project}` which ci.yml actually runs"
  end
end
```

---

### D-15 step 1: delete redundant `chromium` Playwright project — VERIFIED SAFE, both open questions resolved

**Open question 1 (redundant across all three vs scoped) — ANSWERED by reading both spec files directly:**

`operator-screenshot-regression.spec.ts:83`:
```typescript
test.skip(testInfo.project.name === "chromium", "fixed guard runs on desktop/mobile projects");
```
This spec explicitly SKIPS itself on the bare `chromium` project already — it only asserts on `desktop-chromium` (`:85`) and `mobile-chromium` (`:89`).

`operator-stress.spec.ts:268-269, 308`:
```typescript
testInfo.project.name !== "desktop-chromium",
"stress screenshot ratchet runs only on desktop-chromium",
```
This spec restricts itself to `desktop-chromium` ONLY — never runs its ratchet assertions on bare `chromium` at all.

**Correction to `198-RESEARCH.md`'s "13 chromium baseline files" finding:** the research's `find -iname "*-chromium.png"` glob matches `*-desktop-chromium.png` and `*-mobile-chromium.png` too (both end in the substring `-chromium.png`). Re-running the search and inspecting the 13 filenames directly (this session) shows **all 13 are `-desktop-chromium.png` or `-mobile-chromium.png` suffixed** — **zero** baselines exist for the bare `chromium` project name. `desktopSnapshotPath()` in `operator-stress.spec.ts:36-37` confirms this by construction: `baselineRef.replace(/\.png$/, "-desktop-chromium.png")` — the helper that generates snapshot paths never even constructs a bare `-chromium.png` name.

**Conclusion for the planner:** D-15 step 1 (delete the `chromium` project at `playwright.config.ts:16`) is **safe with zero orphaned baselines and zero coverage loss** — both specs already actively avoid the bare `chromium` project. No pre-condition work needed beyond the deletion itself; CONTEXT.md's deferred "snapshot-baseline check" item is resolved, not merely flagged.

---

### D-38: `verify.mechanical` sensitivity probe — `MechanicalChecker.run/1` signature ANSWERED

`lib/threadline/operator_surface/mechanical_checker.ex:92-102` (read directly this session):
```elixir
@scorecards_dir ".planning/scorecards"
@ledger_path ".planning/design-system-ledger.json"

@doc """
Options:
  * `:scorecard_dir` — directory of `*.json` scorecards (default `.planning/scorecards`).
  * `:mechanical_floors` — MODE-B ratchet floors map (default: loaded from the ledger).
"""
def run(opts \\ []) do
  dir = Keyword.get(opts, :scorecard_dir, @scorecards_dir)
  floors = Keyword.get(opts, :mechanical_floors) || load_floors()

  violations = dir |> list_scorecards() |> Enum.flat_map(&check_scorecard(&1, floors))

  if violations == [], do: {:ok, []}, else: {:error, violations}
end
```
**Confirmed: the function is path-parameterized, NOT hard-coded.** `:scorecard_dir` accepts an arbitrary path. A scorecard-free GREEN-03 probe IS possible without touching any committed scorecard — write synthetic variant scorecards to a scratch dir (e.g. `/tmp/mechanical-probe/`) and call `MechanicalChecker.run(scorecard_dir: "/tmp/mechanical-probe")` directly (e.g. from `iex -S mix` or a one-off script), never via the `mix verify.mechanical` alias (which is hard-wired to run `mechanical_checker_test.exs`, itself presumably calling `run/1` with default opts over the committed dir — do not modify that test). This closes RESEARCH.md's Assumption A6 / Open Question 3 definitively — no temp-copy-and-restore wrapper is needed.

---

## Shared Patterns

### Bash script defensive style (all new `bin/*` scripts)
**Source:** `bin/verify-release-shape` (full file, 52 lines)
**Apply to:** `bin/verify-branch-protection`
```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# precondition checks: echo "<msg>" >&2; exit 1
# ... work ...
echo "<success message, one line, no trailing weirdness>"
```

### Contract-test file-glob-and-assert idiom (all new/modified `*_contract_test.exs`)
**Source:** `test/threadline/version_truth_doc_contract_test.exs` (Family A, lines 43-70) and `test/threadline/ci_topology_contract_test.exs` (lines 5-9, 91-97)
**Apply to:** D-06/D-07/D-23/D-25/D-05 test additions
```elixir
defp target_files, do: Path.wildcard("some/glob/**/*.ext")

test "..." do
  matches = for path <- target_files(), ..., do: {path, captured}
  assert matches != [], "the glob/regex found nothing — this guard would pass vacuously"
  for {path, captured} <- matches, do: assert captured == expected, "..."
end
```

### Mix alias list-form vs function-capture idiom
**Source:** `mix.exs` lines 82-120
**Apply to:** D-04 (`test.reset`/`test.setup`), D-05 zero-skips wiring (if added as an alias rather than a bare test)
- Simple shell/mix-task sequencing → list form: `"name": ["task1 args", "task2 args"]`
- Anything needing Elixir control flow (env var checks, conditional messages, non-zero exit propagation) → `&function/1` capture, e.g. `"verify.release": &verify_release/1`

### Job id / name stability convention (all `.github/workflows/*.yml` edits)
**Source:** CLAUDE.md's own stated convention, verified against `ci.yml`'s existing 12 job ids (verbatim roster below) and `flake-detection.yml:18` (`# Job id is stable (relied on by docs/CI conventions); evolve name: freely.`)
**Apply to:** every workflow edit this phase makes — never rename an existing job `id:`, only `name:`.

---

## Full `ci.yml` Job-ID Roster (verbatim, for the `ci-required` aggregate's `needs:` list)

Read directly from `.github/workflows/ci.yml` this session (`grep -n "^  [a-zA-Z-]*:$" | head -100` plus each job's `name:` line):

| Job id | `name:` |
|---|---|
| `verify-format` | Check formatting |
| `verify-credo` | Run Credo (strict) |
| `verify-compile-no-optional` | Compile without optional deps |
| `verify-test` | Run test suite *(matrix: `lane: [min, current]` — single `needs:` entry covers both legs)* |
| `verify-hex-evaluator` | Hex evaluator smoke (threadline from hex.pm) |
| `verify-example-browser` | Example app browser E2E (Playwright) |
| `verify-mechanical` | Mechanical checker (committed scorecards) |
| `verify-capture` | Tier A capture lane (byte-stable evidence) |
| `verify-pgbouncer-topology` | PgBouncer transaction topology |
| `verify-docs` | Build ExDoc (dev) |
| `verify-hex-package` | Hex package tarball |
| `verify-release-shape` | Release metadata (version / changelog) |

**All 12** currently run unconditionally (no job-level `if:` conditions found), so `alls-green`'s `allowed-skips` input is not needed for the initial `ci-required` wiring (matches RESEARCH.md Pitfall 3's conclusion). The **6 live-required** contexts today (per CONTEXT.md ground_truth) are `Check formatting`, `Run Credo (strict)`, `Run test suite`, `Build ExDoc (dev)`, `Hex package tarball`, `Release metadata (version / changelog)` — i.e. 4 of the current 12 jobs (`verify-compile-no-optional`, `verify-hex-evaluator`, `verify-pgbouncer-topology`, `verify-example-browser`) run today but are required by nothing, confirming CONTEXT.md's ground_truth table. D-17 adds a 13th id, `verify-example-browser-full`, which is explicitly NOT added to `ci-required`'s `needs:` (it runs on `push: main` + nightly only).

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `.planning/ARCHIVE-REGISTER.md` (D-31) | config/artifact (register) | CRUD (append rows) | No file with this exact name exists. CONTEXT.md names a "193 R-D / 197 design-debt register pattern" but no file matching that description was found under `.planning/phases/193-*` or `.planning/phases/197-*` in this repo's current directory listing (those phase-number directories were not found by `ls`/`find`) — treat CONTEXT.md's citation as referring to conventions used inside those phases' SUMMARY docs, not a copyable register file. The planner should design the register table shape directly from D-31's own decision text (columns: `ref \| SHA \| date \| reason \| recommendation \| restore command`) rather than hunting further for a nonexistent analog. |
| `198-TRIAGE.md`, `.planning/audits/*` | artifact | batch/transform | New artifact types for this phase; CONTEXT.md explicitly leaves formatting to Claude's discretion (D-05 states only the required 4 columns + zero-exclusions assertion). No committed sibling triage doc was found to pattern-match against. |
| `.github/rulesets/main.json` (D-13) | config | CRUD (gh api POST) | First repository-ruleset artifact in this repo; RESEARCH.md Pattern 3 already supplies a complete verified-shape JSON template — use that directly, no in-repo analog exists or is needed. |

## Metadata

**Analog search scope:** `bin/`, `.github/workflows/`, `mix.exs`, `test/threadline/`, `test/support/`, `test/test_helper.exs`, `lib/threadline/operator_surface/live/`, `lib/threadline/operator_surface/mechanical_checker.ex`, `examples/threadline_phoenix/e2e/tests/*.spec.ts`, `.planning/` (register/triage search)
**Files scanned/read directly this session:** `bin/verify-release-shape` (full), `test/threadline/ci_topology_contract_test.exs` (full), `test/threadline/version_truth_doc_contract_test.exs` (full), `test/threadline/operator_surface/formless_pages_test.exs` (full), `test/test_helper.exs` (full), `test/support/storage_schema_case.ex` (partial, targeted grep), `mix.exs` lines 1-137 (targeted), `lib/threadline/operator_surface/live/` (directory listing), `lib/threadline/operator_surface/live/stress_live.ex` (partial), `lib/threadline/operator_surface/mechanical_checker.ex` lines 1-130, `.github/workflows/ci.yml` (job roster via grep, full job-id/name table), `.github/workflows/flake-detection.yml` (full), `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts` (partial + targeted grep), `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` (targeted grep), snapshot directory listing (`find -iname "*-chromium.png"`)
**Pattern extraction date:** 2026-08-27

---

## Answers to the two open questions this agent was asked to resolve

1. **Do `operator-stress.spec.ts` / `operator-screenshot-regression.spec.ts` run only under `chromium`, or redundantly across all three?** — **Neither.** Both specs actively exclude themselves from the bare `chromium` project already (`test.skip(... === "chromium", ...)` in the regression spec; `!== "desktop-chromium"` skip guard in the stress spec). They run only on `desktop-chromium`/`mobile-chromium`. The "13 `*-chromium.png` baseline files" found by `198-RESEARCH.md` are a false alarm caused by a glob substring match (`*-chromium.png` also matches `*-desktop-chromium.png`/`*-mobile-chromium.png`) — direct inspection of the 13 filenames shows **zero** are bare-`chromium`-named. **Deleting the `chromium` Playwright project (D-15 step 1) is safe with no coverage loss and no orphaned baselines.**

2. **What is `MechanicalChecker.run/1`'s exact signature?** — `def run(opts \\ [])`, reading `Keyword.get(opts, :scorecard_dir, ".planning/scorecards")` and `Keyword.get(opts, :mechanical_floors)`. **It is path-parameterized, not hard-coded.** A scorecard-free GREEN-03 sensitivity probe is possible: write synthetic variant scorecard JSON to any scratch directory and call `MechanicalChecker.run(scorecard_dir: "/tmp/scratch-path")` directly — no temp-copy-and-restore wrapper over the real `.planning/scorecards/` directory is needed.
