# Phase 217: Repo Hygiene - Pattern Map

**Mapped:** 2026-09-27
**Files analyzed:** ~9 (1 new guard script, 1 new guard test, ~5 roster/config touch points for the guard, 7 tmp_dir migration targets, 2 doc-verification-only files)
**Analogs found:** 9 / 9 (every file has at least a role-match analog; no "no analog" cases)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `bin/check-repo-hygiene` (name TBD — see Open Question A1 in RESEARCH.md; use `check-repo-hygiene`/`verify.repo_hygiene` to match the `verify-repo-hygiene` CI job id) | utility (CI guard script) | batch (git-grep scan + self-test) | `bin/verify-deps-audit` | exact |
| `mix.exs` (+alias `"verify.repo_hygiene"`, +`ci.all` entry) | config | request-response (mix task dispatch) | `mix.exs:174` (`"verify.deps_audit": &verify_deps_audit/1`) + `mix.exs:237-242` (`defp verify_deps_audit/1`) | exact |
| `.github/workflows/ci.yml` (+`verify-repo-hygiene` job, +`ci-required` needs: entry) | config (CI job) | request-response (CI step invocation) | `.github/workflows/ci.yml:933-960` (`verify-deps-audit` job) + `:973-995` (`ci-required` needs: list) | exact |
| `test/threadline/local_paths_guard_test.exs` (name illustrative) or the guard's `--self-test` mode | test | event-driven (fixture-built negative test) | `bin/verify-deps-audit --self-test` block (lines 92-200) for the runtime-fixture shape; `test/threadline/ci_workflow_parity_contract_test.exs:414-424` for the self-referential-safety string-concat trick | exact (mechanism) + exact (self-referential safety) |
| `CONTRIBUTING.md` (`### \`ci-required\` needs: roster` bullet list) | config (doc) | CRUD (append one bullet) | `CONTRIBUTING.md:460-484` (existing 15-bullet roster block) | exact |
| `test/threadline/ci_topology_contract_test.exs` (no code change — roster is derived, not hand-edited) | test | transform (diff derived-vs-documented roster) | `test/threadline/ci_topology_contract_test.exs:569-624` (`documented_needs_roster/0`, the roster-drift test) | exact — verify only, do not hand-edit the list |
| The 7 leaking test files (`branch_protection_comparison_contract_test.exs`, `getting_started_fixtures_test.exs`, `planning_independence_contract_test.exs`, `ci_attestation_contract_test.exs`, `e2e_preflight_contract_test.exs`, `operator_surface/refute_partition_test.exs`, `operator_surface/exports_mix_parity_test.exs`) | test | file-I/O (temp-dir fixture lifecycle) | `test/threadline/playwright_fail_fast_contract_test.exs` (already migrated, `@tag :tmp_dir`) | exact |
| Tree-walking checks that must never see `tmp/` (guard script itself; any test enumerating repo files) | utility / test | batch (tracked-file enumeration) | `test/threadline/planning_dependency_contract_test.exs:16` (`System.cmd("git", ["ls-files", "-z"], cd: root)`) | exact |
| `.planning/MILESTONE-GUIDE.txt`, `.planning/PROJECT.md` (HYG-04 — verification only) | config (doc) | transform (diff against `ed4cd161`) | commit `ed4cd161` itself | exact — no new pattern needed, confirm byte-parity |

## Pattern Assignments

### `bin/check-repo-hygiene` (utility, batch)

**Analog:** `bin/verify-deps-audit` (365 lines, read in full this session)

**Header-comment pattern** (lines 1-47): every `bin/` guard opens with a comment block naming (a) what it checks, (b) its invocation modes including `--self-test`, (c) exactly what the self-test proves and why each case exists, (d) any environment-variable bypass it explicitly refuses, (e) the seam (`MIX_BIN`-style env var) that lets tests fake the tool it shells out to. Copy this shape: `bin/check-repo-hygiene` should document its scan scope (`git grep -I` over `git ls-files`, tracked-only), its allowlist mechanism, and the "fails on unused allowlist entry" behavior up front.

**Script skeleton** (lines 49-58):
```bash
set -euo pipefail

die() {
  printf 'verify-deps-audit: %s\n' "$*" >&2
  exit 2
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
```
Reuse verbatim (rename the `die` prefix to `check-repo-hygiene`). `ROOT` gives the guard a stable place to `cd` before running `git grep`/`git ls-files`, so it works regardless of the caller's cwd — required since `mix verify.repo_hygiene` and the CI step both invoke it from different working directories.

**`--self-test` runtime-fixture pattern** (lines 92-200, esp. 124-152 and the closing message at 198):
```bash
if [ "${1:-}" = "--self-test" ]; then
  mkdir -p "$ROOT/tmp"
  self_test_dir="$(mktemp -d "$ROOT/tmp/deps-audit-self-test.XXXXXX")"
  cleanup_self_test() {
    rm -rf "$self_test_dir"
  }
  trap cleanup_self_test EXIT
  ...
  set +e
  vuln_output="$(HEX_IGNORE_ADVISORIES= HEX_IGNORE_RETIREMENTS= "$0" "$project_dir" 2>&1)"
  vuln_status=$?
  set -e

  [ "$vuln_status" -ne 0 ] ||
    die "gate stayed green on a known-vulnerable lock"
  ...
  printf 'verify-deps-audit self-test: ok (...)\n'
  exit 0
fi
```
For `check-repo-hygiene --self-test`, build the positive-case fixture the same way — a throwaway dir under `$ROOT/tmp/`, cleaned via `trap ... EXIT` — but the fixture content must be a **runtime-built** string, never a literal-looking home path (see Pattern below, "Self-referential safety"). Assert both directions: the guard goes red on the fixture (has-a-hit case) and green once the fixture line is removed/allowlisted (no false-positive case). Reuse the `die`/aggregate-and-report shape rather than failing on the first mismatch, matching `FAILURES=()` accumulation at lines 315-357 of the analog if the real (non-self-test) scan also needs to report every hit across the tree in one run, not just the first.

**Aggregated, non-fail-fast scan pattern** (lines 313-357, adapt for `git grep`):
```bash
FAILURES=()
for d in "${DIRS[@]}"; do
  ...
  if [ "$deps_get_status" -ne 0 ]; then
    printf '%s\n' "$deps_get_output"
    FAILURES+=("FAIL $d: ...")
    continue
  fi
  ...
done

if [ ${#FAILURES[@]} -gt 0 ]; then
  printf '%s\n' "${FAILURES[@]}"
  exit 1
fi

printf 'verify-deps-audit: %d lockfile(s) audit clean (Hex %s)\n' "${#DIRS[@]}" "$hex_version"
exit 0
```
For the hygiene guard: replace the per-directory loop with a single `git grep -n -I -E '<pattern-set>' -- .` (tracked-only, so `tmp/` is naturally excluded — no separate exclusion logic needed), collect every `file:line` hit not covered by an allowlist entry into `FAILURES`, mark each allowlist entry "used" when a hit matches it, and at the end also fail if any allowlist entry was never used (the unused-allowlist-entry requirement in HYG-02 — no existing analog script has this exact check; it is new logic modeled after the "assert every entry matched" idea implied by `ci_workflow_parity_contract_test.exs`'s `@beam_independent_cache_paths` map, see Shared Patterns below).

**False-positive guard note (from RESEARCH.md):** match only on a preceding path-boundary character (start-of-line, whitespace, quote, backtick) — not bare `/home/` mid-word — to avoid the `home/timeline/coverage` false positive already observed in this repo's prose.

---

### `mix.exs` alias + wrapper function (config, request-response)

**Analog:** `mix.exs:174` and `:237-242`

**Alias registration** (line 174, in the `aliases/0` list):
```elixir
# Per-PR supply-chain gate (SUP-02): asserts Hex >= 2.5.1, then runs
# `deps.unlock --check-unused` + `hex.audit` over root, bench and the
# example app's lockfiles via bin/verify-deps-audit. CLI args are
# ignored on purpose so the gate cannot be narrowed from the command
# line; see bin/verify-deps-audit for the full contract.
"verify.deps_audit": &verify_deps_audit/1,
```

**Wrapper function** (lines 237-242):
```elixir
defp verify_deps_audit(_args) do
  case Mix.shell().cmd("bin/verify-deps-audit") do
    0 -> :ok
    status -> Mix.raise("verify.deps_audit failed (#{status})")
  end
end
```
Copy this exact two-piece shape for `"verify.repo_hygiene": &verify_repo_hygiene/1` calling `bin/check-repo-hygiene` with no args (ignore CLI args the same way, so the gate can't be narrowed from the command line — same rationale as the deps-audit alias comment).

**`ci.all` insertion point** (lines 196-223): `verify.deps_audit` is placed early in the list ("Fast and network-bound, so it runs early"). The hygiene guard is even faster (no network) — RESEARCH.md's own measurement is "~0.15s across the whole repo" — so it should also run early, e.g. immediately after `verify.deps_audit` or even before it (no ordering dependency exists between the two; place per whichever reads better to the planner, but keep it near the top since it is cheap and catches an obvious, unrelated-to-compilation failure mode first).

---

### `.github/workflows/ci.yml` — `verify-repo-hygiene` job + `ci-required` needs: entry (config, request-response)

**Analog:** `.github/workflows/ci.yml:933-960` (job body) and `:973-995` (`ci-required`)

**Job template** (lines 933-960, verbatim structure to copy):
```yaml
verify-deps-audit:
  name: Dependency audit (all lockfiles)
  runs-on: ubuntu-24.04
  # Measured locally: `mix verify.deps_audit` ~13s + `bin/verify-deps-audit
  # --self-test` ~4s = ~17s combined wall time. 10 minutes is the repo's
  # timeout floor and gives well over 4x headroom on a slower hosted runner
  # without hiding a hang.
  timeout-minutes: 10
  steps:
    - uses: actions/checkout@v5

    - uses: erlef/setup-beam@v1
      id: beam
      with:
        version-file: .tool-versions
        version-type: strict

    # Deliberately NO `deps` cache here. The gate fetches three separate
    # projects' dependencies itself (root, bench, examples/threadline_phoenix)
    # via bin/verify-deps-audit, so a single cached `deps/` directory would add
    # an unverified key shape to the CACHE KEY CONTRACT above while restoring
    # nothing all three fetches actually use.
    - name: Audit root, bench and example lockfiles
      run: mix verify.deps_audit

    - name: Prove the gate goes red (vulnerable lock, old Hex)
      run: bin/verify-deps-audit --self-test
```
For `verify-repo-hygiene`: the guard needs no BEAM setup at all if it's pure `git grep` (unlike deps-audit, which needs `mix`) — RESEARCH.md's Anti-Patterns section explicitly warns against copying a cache/compile step "for consistency" when none is needed. Keep the `erlef/setup-beam` step ONLY if the guard is wrapped via `mix verify.repo_hygiene` (Mix needs a BEAM to run at all); if the guard runs as a raw shell step (`bin/check-repo-hygiene`) with the `mix verify.*` wrapper invoked in a second step, both steps still need BEAM, so keep `setup-beam` either way in this repo's convention (the deps-audit job keeps it even though the "real work" is bash, because `mix verify.deps_audit` itself needs Mix). Explicitly omit any `actions/cache` step (Anti-Pattern warned against in RESEARCH.md).

**`ci-required` needs: list amendment** (lines 973-995 for context; the actual list is the block right after `needs:`):
```yaml
ci-required:
  name: CI required
  if: always()
  needs:
    - verify-format
    - verify-credo
    ...
    - verify-bump-rehearsal
    - verify-deps-audit
```
Add `- verify-repo-hygiene` as the new final entry, in the same commit as the `CONTRIBUTING.md` roster bullet and the (derived, not hand-edited) confirmation that `ci_topology_contract_test.exs` passes.

---

### `test/threadline/<new guard test file>.exs` (test, event-driven fixture)

**Analog A — runtime-fixture / no-committed-literal shape:** `bin/verify-deps-audit`'s `--self-test` block (see above) — the mechanism-level precedent for "build fixtures at runtime, assert red, assert green."

**Analog B — self-referential-safety trick:** `test/threadline/ci_workflow_parity_contract_test.exs:414-420`
```elixir
# Assembled so this file's own text never contains the needles it forbids.
@os_family_context "runner" <> ".os"
@deprecated_runner_image "ubuntu-" <> "22.04"
@legacy_otp_segment "otp" <> "27"
@legacy_otp_value "27" <> ".0"
```
Apply the identical string-concatenation trick for the hygiene guard's own positive-case fixture, e.g.:
```elixir
@fake_home_path "/" <> "Users" <> "/" <> "fakeuser" <> "/x"
```
Never write a literal `"/Users/<user>"` in this test file's source — that would make the guard's own test file a future scrub target and could produce a circular false-positive against itself once the guard runs over the tracked tree.

**Analog C — allowlist-exhaustiveness assertion pattern:** `test/threadline/ci_workflow_parity_contract_test.exs:412-413` and the `"the Playwright exemption is the only BEAM-independent cache path, with a reason"` test (further down the same file):
```elixir
@beam_independent_cache_paths %{
  "~/.cache/ms-playwright" =>
    "Playwright browser binaries are keyed by the e2e npm lockfile and do not depend on the BEAM"
}
```
```elixir
test "the Playwright exemption is the only BEAM-independent cache path, with a reason" do
  assert Map.keys(@beam_independent_cache_paths) == ["~/.cache/ms-playwright"]

  for {_path, reason} <- @beam_independent_cache_paths do
    assert is_binary(reason) and String.length(reason) > 20
  end
  ...
end
```
This is the strongest existing precedent for HYG-02's "allowlist entries must each carry a reason, and the guard fails if an entry never matches anything" requirement: a map of `path => reason`, an assertion that every reason is non-trivial, and (new, not yet precedented anywhere in this repo) a "matched" tracking pass the guard itself must implement — model it after this map shape but add the match-tracking logic fresh, since no existing file already asserts allowlist-entry usage against a live scan.

---

### The 7 leaking test files -> `@tag :tmp_dir` migration (test, file-I/O)

**Analog (already-migrated, in-repo precedent):** `test/threadline/playwright_fail_fast_contract_test.exs` (44 lines, read in full)

**Before-shape being fixed, exemplified by** `test/threadline/getting_started_fixtures_test.exs:64-73` (one of the 7, read in full):
```elixir
defp write_fixture!(contents) do
  path =
    Path.join(
      System.tmp_dir!(),
      "getting_started_fixture_#{System.unique_integer([:positive])}.txt"
    )

  File.write!(path, contents)
  path
end
```
No `on_exit` at all — a failed assertion anywhere in a test using `write_fixture!/1` leaves the file in the real `/tmp` forever. This is the exact defect shape HYG-03 targets in all 7 files (though the other 6 use inline end-of-test `File.rm_rf!` rather than zero cleanup — same risk, cleanup is skipped on any raised assertion above it).

**After-shape, the tag + fixture-injection pattern** (`playwright_fail_fast_contract_test.exs:6-9, 25-26`):
```elixir
@tag :tmp_dir
test "production CI config is exercised by a clean seven-case behavioral smoke", %{
  tmp_dir: tmp_dir
} do
  ...
  clean_e2e = Path.join(tmp_dir, "e2e")
  File.mkdir_p!(clean_e2e)
  ...
end
```
Apply the same two-part change to each of the 7 files: add `@tag :tmp_dir` above the `test` line (or `setup :tmp_dir` if the fixture is built in a shared `setup` block used by several tests in one module — e.g. `operator_surface/exports_mix_parity_test.exs`, which already destructures `%{conn: conn, tmp_dir: tmp_dir}` in three tests, meaning that file's `setup` already emits `tmp_dir`; confirm during planning whether it already has `@tag :tmp_dir`/`setup :tmp_dir` wired at the module or describe level and only the cleanup call is what's missing, versus needing the tag added fresh — grep confirmed the key `tmp_dir:` is referenced in that file's test args at lines 74, 114, 172, but did not confirm the originating `@tag`/`setup` line, so read the file's `setup` block during planning before assuming which of the two cases applies). Remove any now-redundant inline `File.rm_rf!` calls, since ExUnit wipes `tmp_dir` before each test run automatically — the manual cleanup becomes dead code once the tag guarantees pre-test cleanliness (ExUnit does not clean up *after*, but the directory is scoped uniquely per test/module so a leftover from a crashed run is harmless and gets wiped on the next run of that same test).

**Do NOT migrate** (explicit per RESEARCH.md Pitfall 3): any test that shells into its temp dir and runs `git`/`mix` as if outside the repo, or any tree-walker. None of the 7 identified files do this, but re-verify per file during planning before touching each one.

---

### Tree-walking / tracked-file enumeration (utility + test, batch)

**Analog:** `test/threadline/planning_dependency_contract_test.exs:16`
```elixir
{tracked, 0} = System.cmd("git", ["ls-files", "-z"], cd: root)
```
Both the new guard script and any test that must not see `tmp/`-migration artifacts should enumerate files via `git ls-files`/`git grep -I` (tracked-only), exactly like this existing contract test, rather than `File.ls!`/a manual directory walk. `tmp/` is untracked (per `.gitignore:45`), so `git`-based enumeration excludes it automatically with no extra exclusion logic — this is also the reason RESEARCH.md recommends implementing the new guard via `git grep`, not a manual `File.ls!` recursive walk.

---

## Shared Patterns

### The `bin/` guard + `mix verify.*` alias + CI job + roster triple-edit
**Source:** `bin/verify-deps-audit` + `mix.exs:174,237-242` + `.github/workflows/ci.yml:933-960,973-995` + `CONTRIBUTING.md:460-484` + `test/threadline/ci_topology_contract_test.exs:569-624`
**Apply to:** the entire HYG-02 guard build. All five files/edits must land in one commit (the "same-commit roster rule" from RESEARCH.md's standing rules) — `ci.yml` job + `ci-required` needs: + `CONTRIBUTING.md` bullet + (verification only, no hand-edit) `ci_topology_contract_test.exs` passing + `mix.exs` alias/`ci.all` entry.

### Self-referential-safety in guard fixtures
**Source:** `test/threadline/ci_workflow_parity_contract_test.exs:414-420`
**Apply to:** the new guard's own test file and any positive-case fixture the `--self-test` mode builds. Every "looks like a real home path" literal must be assembled via string concatenation at runtime, never written as a plain string literal in committed source.

### `git`-native, tracked-only enumeration (never `File.ls!`)
**Source:** `test/threadline/planning_dependency_contract_test.exs:16`, `test/threadline/removed_artifact_contract_test.exs:181`, `test/threadline/operator_surface/rendered_output_contract_test.exs:474`
**Apply to:** the guard script itself (already required by HYG-01/02's "scans tracked text only" language) and any pre-existing tree-walking test that might need re-confirming it stays `tmp/`-safe after the `@tag :tmp_dir` migration (RESEARCH.md Pitfall 4) — none of the currently-known tree-walkers (`planning_dependency_contract_test.exs`, `removed_artifact_contract_test.exs`, `operator_surface_fixture_contract_test.exs`, `rendered_output_contract_test.exs`) use `File.ls!`; all already use `git ls-files`, so no change is expected there, but re-run each once the 7 migrations land, per the RESEARCH.md warning sign ("a previously-passing test starts failing only after the tmp_dir migration lands").

### `@tag :tmp_dir` + fixture-injection instead of hand-rolled `System.tmp_dir!()`
**Source:** `test/threadline/playwright_fail_fast_contract_test.exs`
**Apply to:** the 7 files named above only. The 33 already-`on_exit`-covered `System.tmp_dir!()` files and any git-isolation/worktree test are explicitly left untouched (RESEARCH.md Pitfalls 3-4).

## No Analog Found

None. Every file/edit in this phase's scope has at least a role-match analog already in the repo (this matches RESEARCH.md's own "Key insight": every piece of this phase has a working precedent).

## Metadata

**Analog search scope:** `bin/`, `mix.exs`, `.github/workflows/ci.yml`, `CONTRIBUTING.md`, `test/threadline/ci_topology_contract_test.exs`, `test/threadline/ci_workflow_parity_contract_test.exs`, `test/threadline/playwright_fail_fast_contract_test.exs`, the 7 HYG-03 target files, `test/threadline/planning_dependency_contract_test.exs`, `test/threadline/planning_independence_contract_test.exs`, `bin/safe-temp-tree`
**Files scanned:** ~15 (all read directly this session; no re-reads of overlapping ranges)
**Pattern extraction date:** 2026-09-27
