# Phase 245: Supply chain - Pattern Map

**Mapped:** 2026-10-25
**Files analyzed:** 27 (7 new, 20 modified)
**Analogs found:** 24 / 27. Every analog path below is git-tracked; checked with `git ls-files`.

Read this with `245-RESEARCH.md`. Its four corrections override CONTEXT where they conflict:

1. The retirement fingerprint is `retired:hexpm/<pkg>`, with no id.
2. `deps.tree` must run only after a successful `deps.get --check-locked`.
3. Self-test case (e) is a two-dep fixture (plug test-only plus telemetry prod).
4. The tier rule is keyed on directory role: `bench` and `examples/threadline_phoenix` are always non-blocking; every other directory uses its closure.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `bin/deps-audit-tier` (NEW, sourced lib) | utility | transform (SARIF + tree → tiered findings) | `bin/safe-temp-tree` (sourced-lib idiom) + `bin/upsert-ci-issue` (jq parsing) | role-match |
| `bin/verify-deps-audit` (MOD) | utility / gate | batch (per-dir aggregate) | itself (`:322-392` loop) | exact (self) |
| `bin/deps-health-report` (MOD) | utility / classifier | batch + max-rank classify | itself (`:91-114`, `:211-292`) | exact (self) |
| `bin/upsert-ci-issue` (MOD) | utility | request-response (gh CLI) | itself (`:57-61`) | exact (self) |
| `bin/verify-action-pins` (NEW) | utility | request-response (`gh api` + jq) | `bin/ci-sha-gate` | exact |
| `.github/dependabot.yml` (NEW) | config | — | none in repo; RESEARCH §Dependabot config | no analog |
| `.github/workflows/deps-health.yml` (MOD) | config (workflow) | event-driven | itself + `flake-detection.yml` upsert step | exact (self) |
| `.github/workflows/{ci,release,browser-full,flake-detection,branch-protection,community-health,environment-protection,deps-health}.yml` (MOD, pins) | config | — | RESEARCH §Action inventory (79 refs) | mechanical |
| `test/threadline/dependabot_config_contract_test.exs` (NEW) | test (contract) | transform (YAML → errors) | `test/threadline/ci_token_permissions_contract_test.exs` | exact |
| `test/threadline/ci_action_pin_contract_test.exs` (NEW) | test (contract) | transform (YAML + raw scan → errors) | `test/threadline/ci_action_runtime_contract_test.exs` + `ci_token_permissions_contract_test.exs` | exact |
| `test/threadline/verify_action_pins_test.exs` (NEW) | test (script) | request-response via fake gh | `test/threadline/ci_sha_gate_contract_test.exs` | exact |
| `test/fixtures/deps_audit/sarif/*.json` (NEW, optional; inline heredocs are an alternative) | fixture | — | RESEARCH §Real fixture snippet | no analog file |
| `test/threadline/ci_action_runtime_contract_test.exs` (MOD) | test (contract) | transform | itself | exact (self) |
| `test/threadline/ci_workflow_parity_contract_test.exs`, `ci_topology_contract_test.exs`, `browser_journey_evidence_contract_test.exs`, `flake_classifier_contract_test.exs` (MOD, anchors) | test (contract) | transform | RESEARCH §Blast radius | mechanical |
| `test/threadline/deps_audit_gate_test.exs` (MOD) | test (script) | batch via fake MIX_BIN | itself (`:42-137`) | exact (self) |
| `test/threadline/deps_health_report_test.exs` (MOD) | test (script + workflow shape) | batch via fake MIX_BIN | itself (`:29-145`, `:469-529`) | exact (self) |
| `test/threadline/deps_health_doc_contract_test.exs` (MOD) | test (doc contract) | transform | itself | exact (self) |
| `test/threadline/ci_issue_upsert_contract_test.exs` (MOD) | test (script) | request-response via fake gh | itself (`:5-33`) | exact (self) |
| `CONTRIBUTING.md` (MOD) | docs | — | `## Dependency freshness policy` (`:652-700`) | self |
| `test/partition_weights.txt` (MOD) | config | — | its own header (`:1-6`) | self |
| `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md` (MOD, D-01) | docs | — | — | self |

## Pattern Assignments

### `bin/deps-audit-tier` (NEW: sourced library, transform)

**Sourced-lib analog:** `bin/verify-clean-checkout:4-7` sources `bin/safe-temp-tree`:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(git -C "$SCRIPT_DIR/.." rev-parse --show-toplevel)"
# shellcheck source=bin/safe-temp-tree
source "$SCRIPT_DIR/safe-temp-tree"
```
Both consumers already define `SCRIPT_DIR`, `ROOT` and `MIX_BIN` (verify-deps-audit `:58-60`, deps-health-report `:68-70`). Put the `source "$SCRIPT_DIR/deps-audit-tier"` line right after those lines. The library must not set `set -e` or a trap of its own: deps-health-report runs under `set -uo pipefail`, while verify-deps-audit uses `set -euo pipefail`.

**jq parsing analog:** `bin/upsert-ci-issue:47`. Errors are captured with `|| die`:
```bash
matches=$(printf '%s' "$issues" | jq -c --arg marker "$marker" '[.[] | select(...)]') || die "issue list returned malformed JSON"
```
Use the same `|| <fail>` form on the RESEARCH §Parsing recipe jq (the `capture(...)?` call with an `UNPARSEABLE` row).

**Status capture idiom (copy everywhere a mix call may fail):** `bin/verify-deps-audit:375-378`:
```bash
set +e
audit_output="$(cd "$resolved" && "$MIX_BIN" hex.audit 2>&1)"
audit_status=$?
set -e
```
A sourced function must restore the caller's errexit mode. deps-health-report runs with `set +e` as its baseline (`:294-300` explains why). Prefer local `set +e` with no `set -e` afterwards, and have each caller re-enable errexit itself; or save the mode with `case $- in *e*)`.

**Temp dir idiom:** `bin/verify-deps-audit:104-105`:
```bash
mkdir -p "$ROOT/tmp"
self_test_dir="$(mktemp -d "$ROOT/tmp/deps-audit-self-test.XXXXXX")"
```
Use a fresh `mktemp -d "$ROOT/tmp/deps-audit-sarif.XXXXXX"` for each audit call, and never pre-create `audit.sarif` (RESEARCH Pitfall 2). Register the path with the caller's single cleanup function (Pitfall 10).

**Bash 3.2 constraint:** no `declare -A`. Copy the list-loop idiom from `bin/verify-deps-audit:217-225`:
```bash
SEEN_DIRS=()
for d in "${DIRS[@]}"; do
  for prior in ${SEEN_DIRS[@]+"${SEEN_DIRS[@]}"}; do
```
For closure membership, use `grep -Fxq "$pkg" "$closure_file"`.

---

### `bin/verify-deps-audit` (MOD: gate, batch)

**Analog:** itself. These are the regions to change; full line map in RESEARCH §Script structure.

**Header to extend** (`:27-49`). Add self-test case (e) to the `--self-test` prose at `:32-46`, and document the tier rule.

**Self-test case pattern to copy for (e)** (`:179-201`, case d: a string-substituted mix.exs):
```bash
drift_dir="$self_test_dir/drift"
mkdir -p "$drift_dir"
cp "$fixture_dir/mix.exs" "$drift_dir/mix.exs"
cp "$fixture_dir/mix.lock" "$drift_dir/mix.lock"
...
orig_mix_exs="$(cat "$drift_dir/mix.exs")"
drifted_mix_exs="${orig_mix_exs//== 1.19.1/~> 1.19.2}"
printf '%s\n' "$drifted_mix_exs" >"$drift_dir/mix.exs"

set +e
drift_output="$(HEX_IGNORE_ADVISORIES= HEX_IGNORE_RETIREMENTS= "$0" "$drift_dir" 2>&1)"
drift_status=$?
set -e

[ "$drift_status" -ne 0 ] &&
  grep -q -- '--check-locked' <<<"$drift_output" && ... ||
  die "lock drift was not refused (WR-02 regression): $drift_output"
```
For (e): substitute the deps list with `[{:plug, "== 1.19.1", only: :test}, {:telemetry, "~> 1.4"}]`, assert exit **0**, and `grep -q 'deps-audit-finding tier=non-blocking .*package=plug id=EEF-CVE-2026-54892'`. Case (a) at `:122-126` switches from grepping `Advisories:` / `plug 1.19.1` to grepping the `tier=blocking … package=plug id=EEF-CVE-2026-54892` machine line. Update the summary line at `:203`.

**Trap conflict to resolve** (`:290-314`). `refuse_global_hex_ignores` sets and clears its own trap:
```bash
neutral_dir="$(mktemp -d "$ROOT/tmp/deps-audit-hex-config.XXXXXX")"
trap 'rm -rf "$neutral_dir"' EXIT
...
rm -rf "$neutral_dir"
trap - EXIT
```
Replace it with one registered-path cleanup, using the `cleanup_sections` model in `bin/deps-health-report:80-85`:
```bash
NEUTRAL_HEX_CONFIG_DIR=""
cleanup_sections() {
  rm -f "$SECTIONS_FILE"
  [ -z "$NEUTRAL_HEX_CONFIG_DIR" ] || rm -rf "$NEUTRAL_HEX_CONFIG_DIR"
}
trap cleanup_sections EXIT
```

**R2-IN-01 hygiene FAIL fix** (`:339-342`). Today the reason is unconditional:
```bash
FAILURES+=("FAIL $d: lock hygiene exited $hygiene_status (an empty build-manager list in mix.lock ...)")
```
Branch on `hygiene_status`, using the exit codes from `bin/verify-lock-hygiene:21-26`: 1 means an empty manager list; 2 means usage, a missing file, a parse error or a malformed entry.

**Ordering** (`:352-363` fetch, then `continue`). Call `deps.tree` only after this check passes (RESEARCH correction 2). Replace the audit block at `:375-383` with the SARIF call through the library. Blocking findings append to `FAILURES`, using the same `FAILURES+=("FAIL $d: …")` form. Non-blocking findings print `::warning::` and the machine line and do not touch `FAILURES`.

**Success line** (`:391`) gains the non-blocking count (D-23 case 11):
```bash
printf 'verify-deps-audit: %d lockfile(s) audit clean (Hex %s)\n' "${#DIRS[@]}" "$hex_version"
```
**Keep byte-identical:** `CANONICAL_DIRS=(. bench examples/threadline_phoenix)` (`:210`), which `deps_health_doc_contract_test.exs:120-128` pins; and `MIN_HEX="2.6.0"` (`:66`).

---

### `bin/deps-health-report` (MOD: classifier, max-rank)

**Analog:** itself. Max-rank idiom at `:91-114`:
```bash
RANK_NAMES=(clean outdated unknown advisory)
overall_rank=0

rank_of() {
  case "$1" in
    clean) echo 0 ;;
    outdated) echo 1 ;;
    unknown) echo 2 ;;
    advisory) echo 3 ;;
    *) echo 0 ;;
  esac
}
```
This becomes `RANK_NAMES=(clean unknown retirement advisory)` with ranks 0-3 (D-25). The fallback `*) echo 0` maps an unrecognised name to clean, which fails open. Change it to rank `unknown`, so an unrecognised name can never classify a run as clean.

**Per-dir section emission** (`:250-253`, `:270-273`):
```bash
{
  printf -- '- fetch exit: %s\n\n' "$deps_get_status"
  printf '```\n%s\n```\n\n' "$(printf '%s' "$deps_get_output" | strip_ansi)"
} >>"$SECTIONS_FILE"
```
D-26: print the fenced `deps.get` output only when `deps_get_status -ne 0`. Delete every `outdated exit:` line (`:222`, `:232`, `:259`) and the `hex.outdated` block (`:279-291`).

**Suppression arm stays unchanged** (`:165-209`). **Body assembly** (`:302-326`): keep `# Dependency health: %s` (`:310`) and the 60000 cap, and add the "Blocking — shipped runtime" / "Non-blocking — dev/test/bench/example" sections (D-27).

**New seam (Pitfall 9).** Copy the `MIX_BIN` default form from `:70`:
```bash
MIX_BIN="${MIX_BIN:-mix}"
```
giving `VERIFY_ACTION_PINS_BIN="${VERIFY_ACTION_PINS_BIN:-$SCRIPT_DIR/verify-action-pins}"`. A non-zero exit bumps `unknown`, and the reason goes at the top of `SECTIONS_FILE`, the same way the suppression reason does at `:204-209`.

**Header rewrite:** `:9-33` (precedence) and `:49` (class list).

---

### `bin/upsert-ci-issue` (MOD: retitle on update)

**Analog:** itself. Update arm at `:59`:
```bash
1) number=$(printf '%s' "$matches" | jq -r '.[0].number'); printf '%s' "$number" | grep -Eq '^[0-9]+$' || die "matched issue has invalid number"; "$GH_BIN" issue comment "$number" --body-file "$body_file" >/dev/null; printf 'action=update\nissue_number=%s\n' "$number" ;;
```
Insert this after the number validation and before `issue comment`: `cur=$(printf '%s' "$matches" | jq -r '.[0].title')`, then `[ "$cur" = "$title" ] || "$GH_BIN" issue edit "$number" --title "$title" >/dev/null`. The current title is already fetched (`--json number,title`, `:46`). Add a behaviour-table row to the header at `:7-15`. The title travels as argv only (`:17-20` invariant).

---

### `bin/verify-action-pins` (NEW: gh api, request-response)

**Analog:** `bin/ci-sha-gate`.

**Header convention** (`:1-43`): an ID line, a statement that the script is extracted and table-tested through a fake `gh` (GH_BIN), Usage/env, an ordered behavior table, the fail mode, and an Output/exit contract. One difference: ci-sha-gate fails **open** to `run`, but this script must fail **closed**. Any gh error or a mismatch means a non-zero exit.

**Seam and die** (`:44-52`):
```bash
set -uo pipefail

die() {
  printf 'ci-sha-gate: %s\n' "$*" >&2
  exit 2
}

GH_BIN=${GH_BIN:-gh}
```

**gh api + jq with captured failure** (`:89-94`):
```bash
run_count() {
  local out n
  out=$("$GH_BIN" api "repos/$GITHUB_REPOSITORY/actions/workflows/$1/runs?head_sha=$sha&status=$2&per_page=1" 2>/dev/null) || out=""
  n=$(printf '%s' "$out" | jq -r 'if (.total_count|type)=="number" then .total_count else empty end' 2>/dev/null) || n=""
  if is_integer "$n"; then printf '%s' "$n"; fi
}
```
**Deref logic:** RESEARCH §Re-resolved SHAs, "Dereference recipe": `git/ref/tags/T`, then `git/tags/<sha>` when `.object.type == "tag"`; the repo is the first two path segments. Validate every value against `^[0-9a-f]{40}$` / `^v[0-9]+\.[0-9]+\.[0-9]+$` before building a URL. This is the same rule ci-sha-gate applies at its `:41-43`: "validated before any URL is built". Scan the same globs as the pin contract. There are 8 distinct (repo, tag) pairs.

---

### `.github/dependabot.yml` (NEW: config)

**No analog in repo.** Copy the file verbatim from RESEARCH §Dependabot config (`version: 2`, one `github-actions` entry at `/`, monthly, `cooldown.default-days: 7`, one `*` group with `applies-to: version-updates`, `commit-message: {prefix: ci, include: scope}`). Header-comment convention: open with a purpose paragraph and the contract-test path, as `.github/workflows/deps-health.yml:1-12` does.

---

### `.github/workflows/deps-health.yml` (MOD)

**Analog:** itself.
- Triggers (`:15-19`): replace the Monday cron with a daily one, and add `push: branches: [main]` with `paths:` set to the 3 dirs × {mix.exs, mix.lock} (D-27). Keep `workflow_dispatch` and `concurrency` (`:24-26`).
- Job id `deps-health` (`:30`) stays. Rename `name:` (`:31`) and the step name at `:50`.
- Report step (`:50-52`): add `env: GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}` for verify-action-pins, using the same form as `:62-63`.
- `--label-description` (`:94`): drop "hex.outdated findings".
- Fail step `if:` (`:124`): drop `&& … != 'outdated'`. Also move `${{ steps.report.outputs.classification }}` out of `run:` (`:126`) into `env:`. This is the same injection-hygiene move as D-33.
- Rewrite the comments at `:1-12`, `:54-59`, `:97-102` and `:117-122`.

### Workflow pins (all 8 workflow files, MOD)

Mechanical. Use the RESEARCH §Action inventory table for the file:line of each of the 79 refs, and the canonical form from RESEARCH §Code Examples:
```yaml
      - uses: actions/checkout@fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09 # v5.1.0
```
setup-node (ci.yml `:682-686`, the current shape):
```yaml
        uses: actions/setup-node@v5
        with:
          node-version: "22"
          cache: npm
```
`node-version: "22"` becomes `node-version-file: .tool-versions` (also at ci.yml `:889`, `:1052` and browser-full.yml `:103`). Fix the alls-green comment at ci.yml `:1219-1221`: `# v1.2.2 / release/v1` should be `# v1.3.0`, as a trailing comment on the `uses:` line. Optional D-33 at release.yml `:392-395`: `const sha = '${{ needs.release-ref.outputs.release_sha }}';` becomes `env: RELEASE_SHA` with `process.env.RELEASE_SHA`.

---

### `test/threadline/dependabot_config_contract_test.exs` (NEW: contract)

**Analog:** `test/threadline/ci_token_permissions_contract_test.exs`.

**Module shape** (`:1-46`): `@moduledoc` sections "Representation" and "Not covered here"; `use ExUnit.Case, async: true`; `@repo_root File.cwd!()`.

**YAML parse helper** (`:122-128`). Copy it verbatim:
```elixir
defp parse_yaml(text) do
  {:ok, YamlElixir.read_from_string!(text, merge_anchors: true)}
rescue
  error -> {:error, Exception.message(error)}
catch
  kind, reason -> {:error, inspect({kind, reason})}
end
```
**Pure checker with a `rule=` id in every error** (`:211-223`, `:376`):
```elixir
defp token_errors(texts) do
  parsed = for {path, text} <- Enum.sort(texts), do: {path, text, parse_yaml(text)}
  parse_errors =
    for {path, _text, {:error, message}} <- parsed do
      "#{path} rule=yaml-parse: the workflow does not parse, ..."
    end
  ...
defp rule_fired?(errors, rule), do: Enum.any?(errors, &String.contains?(&1, "rule=#{rule}"))
```
**Mutation table** (`:378-385` `mutate!`, `:396-450` `for` comprehension). Copy this shape for the four D-05 controls (mix entry, prefix `fix`, `target-branch`, limit 0) plus a benign positive control:
```elixir
defp mutate!(texts, path, from, to) do
  original = Map.fetch!(texts, path)
  assert String.contains?(original, from),
         "control anchor not found in #{path}: #{inspect(from)}"
  Map.put(texts, path, String.replace(original, from, to, global: false))
end
...
for {label, path, from, to, rule} <- [ {...}, ... ] do
  test "#{label} fires rule=#{rule}", %{texts: texts} do
    mutated = mutate!(texts, unquote(path), unquote(from), unquote(to))
    refute mutated == texts, "the control did not change the input"
    errors = token_errors(mutated)
    assert rule_fired?(errors, unquote(rule)),
           "expected rule=#{unquote(rule)} to fire, got #{inspect(errors)}"
  end
end
```
**Releasable set derived from `release-please-config.json`.** Its `changelog-sections` are feat, fix, perf and deps, plus chore with `"hidden": true`. Parse it with `Jason.decode!` and filter `s["hidden"] != true` (RESEARCH §Dependabot config).

**Label disjointness.** Copy `other_workflow_labels/0` from `deps_health_doc_contract_test.exs:81-89`, which uses the regex `~r/LABEL:\s*(\S+)/` over the workflow glob.

---

### `test/threadline/ci_action_pin_contract_test.exs` (NEW: contract)

**Primary analog:** `test/threadline/ci_action_runtime_contract_test.exs`.

**Non-vacuous glob (PIN-SCAN)** (`:36-48`). Extend it to `.github/actions/**/action.{yml,yaml}`:
```elixir
defp workflow_paths do
  paths =
    @repo_root
    |> Path.join(".github/workflows/*.{yml,yaml}")
    |> Path.wildcard()
    |> Enum.map(&Path.relative_to(&1, @repo_root))
    |> Enum.sort()

  assert paths != [],
         "no workflow files found under .github/workflows — refusing to pass vacuously"
  paths
end
```
**Raw scan side of PIN-PARITY** (`:54-70`):
```elixir
defp strip_comment_lines(block) do
  block |> String.split("\n") |> Enum.reject(&String.match?(&1, ~r/^\s*#/)) |> Enum.join("\n")
end

defp uses_refs(yaml) do
  ~r/^\s*(?:-\s+)?uses:\s*["']?([^\s"'#]+)/m
  |> Regex.scan(strip_comment_lines(yaml), capture: :all_but_first)
  ...
```
**Parsed side of PIN-PARITY:** `parse_yaml/1`, `yaml_get/2` and `parsed_jobs/1` from `ci_token_permissions_contract_test.exs:122-156`. They walk `jobs.*.uses`, `jobs.*.steps[*].uses` and composite `runs.steps[*].uses`. Compare the multisets with `Enum.frequencies/1`.

**Local and docker refs** (`:72-73`). These are already tagged `:needs_decision`; PIN-LOCAL / PIN-DOCKER give them concrete rules:
```elixir
defp classify_ref("./" <> _ = value), do: {:needs_decision, value}
defp classify_ref("docker://" <> _ = value), do: {:needs_decision, value}
```
**Mutation-control style:** `ci_action_runtime_contract_test.exs:223-283`. Synthetic YAML is built by concatenation (`"actions/cache@" <> "v4"`) so the literal never appears in source for the pin grep to trip on. Copy this concatenation trick for the tag-only `actions/checkout@v5` negative control. There is a benign positive control at `:271-283`. Use the `rule=` / `rule_fired?` reporting from the token contract so each control asserts **its own** rule id.

**NODE-PIN / NODE-FILE:** read `.tool-versions` (today: `nodejs 22.14.0`, `erlang 27.3.4.15`, `elixir 1.17.3-otp-27`). Also assert that no other line is a single token (RESEARCH Pitfall 7).

---

### `test/threadline/verify_action_pins_test.exs` (NEW: script test)

**Analog:** `test/threadline/ci_sha_gate_contract_test.exs:12-60`.
```elixir
use ExUnit.Case, async: true
@moduletag :tmp_dir
@script Path.expand("../../bin/ci-sha-gate", __DIR__)

defp fake_gh!(tmp_dir) do
  gh = Path.join(tmp_dir, "gh")
  File.write!(gh, """
  #!/usr/bin/env bash
  printf '%s\\n' "$*" >> "$CALL_LOG"
  case "${FAKE_GH_MODE:-}" in
    fail) echo "HTTP 403: Resource not accessible by integration" >&2; exit 1 ;;
    garbage) echo "not-json"; exit 0 ;;
  esac
  [ "$1" = "api" ] || exit 9
  case "$2" in
    */workflows/#{@own}/runs\\?*status=success*) printf '%s' "$OWN_SUCCESS_JSON" ;;
    ...
    *) exit 9 ;;
  esac
  """)
  File.chmod!(gh, 0o755)
  gh
end
```
Rows to cover: lightweight tag match, annotated-tag deref match (`.object.type == "tag"`, then a second call), mismatch (exit non-zero), gh failure (fail **closed**), and garbage JSON (fail closed). Point the script at a synthetic workflows dir through an env or argv seam, so the test never reads live refs unless it means to.

---

### `test/threadline/ci_action_runtime_contract_test.exs` (MOD: D-12 re-key)

**Analog:** itself.
- `@node24_or_non_js` (`:13-24`): re-key from `{action, ref}` to `{action, major}`. The alls-green key is `{"re-actors/alls-green", "v1"}`. Update the `@remedy` text (`:26-28`) and the comment block (`:7-12`).
- `uses_refs/1` (`:65-70`): add a capture for the comment major, using `~r/uses:\s*([^\s@"']+)@[0-9a-f]{40}\s+#\s*(v\d+)\.\d+\.\d+/` (RESEARCH §Code Examples).
- `release_please_runbook_errors/2` (`:124-133`): `~r/googleapis\/release-please-action@v(\d+)\b/` must read the major from the `# vX.Y.Z` comment. Rewrite the mutation at `:172-183` so it mutates the comment major.
- Mutation controls (`:223-283`) currently use tag refs. Rewrite the positive control (`:271-283`) in pinned form.

### Live-workflow anchor fixes (MOD; same atomic commit as the pins, D-13)

Follow RESEARCH §Blast radius line by line. The key shapes are:
- `ci_workflow_parity_contract_test.exs:713,722,730`: `~r/^        uses: re-actors\/alls-green@[0-9a-f]{40}\n/m` becomes `@[0-9a-f]{40}[^\n]*\n`.
- `ci_topology_contract_test.exs:246`: the `$` anchor also needs to tolerate the trailing comment.
- Exact-string checks against `@v5`, `@v7` and `@v1` (parity `:2336`, `:4106`, `:4204`, `:4296-4299`, `:2802`, `:2841`, `:5258-5266`; topology `:814`, `:824`; browser_journey `:80`, `:103`; flake_classifier `:538`): match on the action path plus `@` (the pin-safe idiom already used by `step_uses/1` at parity `:4571-4576` and `setup_node_step?/1` at `:4677`).
- After pinning, run `git grep -nE '@v[0-9]+' -- test/` as the completeness check.

---

### `test/threadline/deps_audit_gate_test.exs` (MOD: D-23 cases 1-12)

**Analog:** itself. Fake mix at `:42-93`. Extend its `case` with `deps.tree` and `hex.audit --format sarif --output P` arms, keeping the env-driven toggles:
```bash
base=$(basename "$(pwd)")
key="$base:$cmd"
case ",${FAKE_FAIL:-}," in
  *",$key,"*) exit 1 ;;
esac
exit 0
```
New env knobs follow the existing naming (`FAKE_FAIL`, `FAKE_LOCK_DRIFT`): for example `FAKE_SARIF_<dir>` pointing at a fixture path, which the fake copies to the `--output` argument, and `FAKE_TREE_<dir>`. The fake must **not** write the SARIF file when it is told to simulate a registry failure (Pitfall 2).

**Runner** (`:116-137`): `run(args, env, root)` with the `base_env` merge. Keep it. The clean-run call-order assertion (`:139-170`) must gain `deps.tree --only prod --format plain` and `hex.audit --format sarif --output …` in the new order.

**Dir-role note.** These tests pass explicit temp dirs (`project_dir(root, "one")`), so per RESEARCH correction 4 they use the closure rule. Cases 5 and 6 (bench and example are always non-blocking) need dirs whose path relative to `$ROOT` is literally `bench` or `examples/threadline_phoenix`; alternatively, expose a seam so the role is decided on the relative name. Decide this in the plan.

---

### `test/threadline/deps_health_report_test.exs` (MOD: D-29 rewrite)

**Analog:** itself. The fake mix (`:29-117`) is keyed on the `$REL` path and `should_match` lists. Keep the `hex.outdated)` arm (`:88-96`), but make it exit 1 by default, so the "never invoked" regression is asserted on `FAKE_MIX_LOG`. Add `deps.tree` and SARIF arms. `run_report/2` (`:131-145`) must add `{"VERIFY_ACTION_PINS_BIN", <fake exiting 0>}` to its base env (Pitfall 9).

**Workflow-shape test idiom** (`:500-508`). Rewrite it to "exempts only 'clean'":
```elixir
[_, after_fail] = String.split(yaml, "Fail the job", parts: 2)
step_body = after_fail |> String.split(~r/\n\s{6}- name:/, parts: 2) |> hd()
assert step_body =~ ~r/!=\s*'clean'/
assert step_body =~ ~r/!=\s*'outdated'/
```
Delete the stale tests (`:171-179` outdated arm; `:181-192` "even if outdated also fails"; the moduledoc at `:8-12`).

---

### `test/threadline/deps_health_doc_contract_test.exs` (MOD)

**Analog:** itself.
- `:157-166`: replace the `"This repository does not use Dependabot version-update pull requests."` assertion with the new D-06 sentence facts, and drop `hex.outdated` (`:162`).
- `:168-171` `refute File.exists?(… "dependabot.yml")`: invert it to assert the file exists, with `dependabot.yaml` absent.
- Add the class-set equality: parse `RANK_NAMES=(...)` the same way `canonical_dir_line!/1` (`:58-65`) parses `CANONICAL_DIRS`, and compare it to the classes CONTRIBUTING names.
- The close-step regex at `:219` stays valid. Update its message text, which mentions "outdated".
- `crons/0` (`:47-51`) already derives the cron, so the daily cron automatically requires CONTRIBUTING to name it.

### `test/threadline/ci_issue_upsert_contract_test.exs` (MOD)

**Analog:** itself. The fake gh is at `:18-28`. Add an arm `if [ "$1 $2" = "issue edit" ]; then exit 0; fi` before `exit 9`. Add rows that follow the existing test at `:73-83`: same title gives no `issue edit` in `calls(f)`; a different title gives `issue edit 41 --title …` **before** `issue comment 41`, using the `:binary.match` ordering idiom at `:122-124`:
```elixir
{comment_at, _} = :binary.match(log, "issue comment 41")
{close_at, _} = :binary.match(log, "issue close 41")
assert comment_at < close_at, "the citing comment must be posted before the close"
```

### `CONTRIBUTING.md` (MOD)

**Analog:** the `## Dependency freshness policy` section (`:652-700`). Rewrite these paragraphs:
- `:654-661`: release train and the Dependabot sentence (D-06), plus the D-07 merge policy.
- `:663-675`: the required gate, with the tier rule and the explicit statement that root dev-dep advisories no longer block (D-16).
- `:677-695`: the weekly lane. Use the daily cron and push trigger, the classes {clean, unknown, retirement, advisory}, and remove "an `outdated` result alone stays green".

Also update runbook step 5 (around `:1147`). Every edit lands together with the doc-contract edits above.

### `test/partition_weights.txt` (MOD)

Header `:1-6`: one `<ms> <path>` per line, sorted by path. Add the new test files in sorted position, either with `bin/ci-test-partitions --write-weights` or by hand with a measured value (Pitfall 8).

## Shared Patterns

### Fake-binary seam (MIX_BIN / GH_BIN / VERIFY_ACTION_PINS_BIN)
**Sources:** `bin/verify-deps-audit:48-49,60`; `bin/upsert-ci-issue:24`; `bin/ci-sha-gate:52`
**Apply to:** `bin/deps-audit-tier` (uses the caller's `MIX_BIN`), `bin/verify-action-pins` (`GH_BIN`), `bin/deps-health-report` (new `VERIFY_ACTION_PINS_BIN`)
```bash
MIX_BIN="${MIX_BIN:-mix}"
GH_BIN=${GH_BIN:-gh}
```
Test side: the fake script logs `"$*"` to `$CALL_LOG` and exits 9 on any unknown subcommand. Sources: `ci_issue_upsert_contract_test.exs:18-28`, `ci_sha_gate_contract_test.exs:22-43`.

### Fail-closed aggregation (never fail-fast)
**Source:** `bin/verify-deps-audit:320-389`
**Apply to:** the tier classification in verify-deps-audit, and every D-19 ambiguous case. Each case gets its own `FAILURES+=("FAIL $d: …")` line. `die` (exit 2) is only for pre-loop refusals.
```bash
if [ ${#FAILURES[@]} -gt 0 ]; then
  printf '%s\n' "${FAILURES[@]}"
  exit 1
fi
```

### Contract test = parse YAML + pure checker + `rule=` ids + mutation table
**Source:** `test/threadline/ci_token_permissions_contract_test.exs:122-128, 211-223, 376-450`
**Apply to:** `dependabot_config_contract_test.exs`, `ci_action_pin_contract_test.exs`, and the re-keyed runtime contract. Rules: every control asserts `refute mutated == texts` (the anchor must exist), and each control fires **its own** rule id.

### Non-vacuous derive source
**Sources:** `ci_action_runtime_contract_test.exs:44-45, 207-211`; `deps_health_doc_contract_test.exs:109-118`
**Apply to:** every new glob and scan (PIN-SCAN, the closure contract, label derivation). An empty input is an explicit assertion failure, never a pass.

### Single-issue lifecycle wiring
**Source:** `.github/workflows/deps-health.yml:60-115`. Upsert runs on `if: always() && … != 'clean'`, close runs on `== 'clean'`, and `TITLE_PREFIX` doubles as the marker.
**Apply to:** the deps-health changes only. The other callers of upsert-ci-issue (`flake-detection.yml:297`, `browser-full.yml:194`) inherit the retitle behaviour with no edits.

### Untrusted text travels as argv or env, never as interpolation
**Sources:** `bin/upsert-ci-issue:17-20`; `deps-health.yml:62-68` (`env:` indirection)
**Apply to:** SARIF message text in reports (no `eval`), the D-33 github-script fix, and the deps-health fail step's inline `${{ }}`.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `.github/dependabot.yml` | config | — | No Dependabot config has ever existed (a test currently refutes it). Use RESEARCH §Dependabot config verbatim. |
| `test/fixtures/deps_audit/sarif/*.json` (or inline heredocs) | fixture | — | No SARIF fixtures exist. Build them from the real Hex 2.6.0 snippet and the five vulnerable-fixture fingerprints in RESEARCH §Hex 2.6.0 SARIF contract. |
| The SARIF/closure tier logic inside `bin/deps-audit-tier` | utility | transform | Nothing in the repo parses SARIF or `deps.tree` yet. The shell idioms have analogs (above); use the logic from the RESEARCH §Parsing recipe and §deps.tree recipe. |

## Metadata

**Analog search scope:** `bin/`, `test/threadline/`, `.github/workflows/`, `CONTRIBUTING.md`, `release-please-config.json`, `.tool-versions`, `test/partition_weights.txt`
**Files scanned:** 22
**Tracked-source gate:** all 13 analog source files verified with `git ls-files` (no mirror paths)
**Pattern extraction date:** 2026-10-25
