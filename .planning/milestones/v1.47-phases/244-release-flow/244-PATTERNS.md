# Phase 244: Release flow - Pattern Map

**Mapped:** 2026-10-24
**Files analyzed:** 19 new/modified
**Analogs found:** 19 / 19 (all analogs verified git-tracked: `bin/*`, `test/threadline/*`, `.github/workflows/*`)

No mix commands were run (no deps/_build in this worktree). Line numbers are from this worktree at HEAD 4227e980.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `bin/date-release-changelog` (new) | utility (bash+perl script) | transform (file in -> file out) | `bin/verify-release-shape` (shell skeleton) + `bin/verify-bump-rehearsal:383-399` (the perl CHANGELOG edit it replaces) | role-match |
| `bin/retry-network` (new) | utility (shell wrapper) | request-response (retry loop) | `bin/verify-deps-audit:325-335` (here-string `n`, capture status under `set +e`) | partial |
| `release-please-config.json` | config | n/a | itself (add one top-level key) | exact |
| `.github/workflows/release.yml` (sync job; pin; wrap) | config (workflow) | event-driven | itself, job `sync-release-pr-pins` (lines 120-197) | exact |
| `.github/workflows/ci.yml` (pin step + wrap in 11 deps.get, 12 setup-beam) | config | event-driven | existing `Install dependencies` / `setup-beam` blocks | exact |
| `.github/workflows/browser-full.yml`, `flake-detection.yml`, `deps-health.yml` | config | event-driven | ci.yml setup-beam block | exact |
| `mix.exs` `verify_hex_evaluator` (`steps` string ~l.470) + `MIN_HEX` doc ref l.190 | config (alias) | batch | itself | exact |
| `bin/verify-bump-rehearsal` (l.383-399 stand-in; l.461 fetch; header l.42-46) | utility | batch | itself | exact |
| `bin/verify-deps-audit` (`MIN_HEX` l.61, check l.243-244, fetch l.331) | utility | batch | itself | exact |
| `bin/deps-health-report` (fetch l.243) | utility | batch | `bin/verify-deps-audit` fetch block | exact |
| `test/threadline/date_release_changelog_test.exs` (new) | test | System.cmd fixture, file-I/O | `test/threadline/deps_audit_gate_test.exs` | role-match |
| `test/threadline/retry_network_contract_test.exs` (new) | test (contract + behaviour) | file-scan + System.cmd | `release_control_plane_contract_test.exs` (rules + mutation controls) + `deps_audit_gate_test.exs` (fake binary) | role-match |
| `test/threadline/hex_pin_contract_test.exs` (new) | test (contract) | file-scan | `ci_workflow_parity_contract_test.exs` setup-beam rules (l.3229-3300) | role-match |
| `test/threadline/release_control_plane_contract_test.exs` (extend) | test | file-scan | itself l.138-188, l.279-340 | exact |
| `test/threadline/ci_workflow_parity_contract_test.exs` (must be edited) | test | file-scan | itself | exact |
| `test/threadline/deps_audit_gate_test.exs` (MIN_HEX strings l.116,182,445) | test | System.cmd | itself | exact |
| `CONTRIBUTING.md` (:665,:732,:1063-1066), `CHANGELOG.md` header l.3-10 | doc | n/a | existing prose | exact |

## Pattern Assignments

### `bin/date-release-changelog` (utility, transform)

**Analog A (shell skeleton):** `bin/verify-release-shape`

Header and version extraction (lines 1-22):
```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
VER_LINE=$(grep -E '^\s*@version\s+"' mix.exs | head -1 || true)
VER=$(sed -n 's/.*@version "\([^"]*\)".*/\1/p' <<<"$VER_LINE" | head -1)
```
Heading regex it must satisfy (lines 38-42), so the output is proven valid by running this script in the unit test:
```bash
ESC_VER="${VER//./\\.}"
DATE_RE="[0-9]{4}-[0-9]{2}-[0-9]{2}"
HEADING_RE="^## \\[${ESC_VER}\\]( - ${DATE_RE}|\\([^)]*\\) \\(${DATE_RE}\\))$"
```
Also copies: a non-semver gate (research says validate `^[0-9]+\.[0-9]+\.[0-9]+$` before perl use), and the pre-release skip branch (`[[ "$VER" == *-* ]]`).

**Analog B (the perl edit and env injection, never interpolation):** `bin/verify-bump-rehearsal:383-399`
```bash
TODAY="$(date -u +%Y-%m-%d)"
NXT="$NEXT" TODAY="$TODAY" perl -0pi -e \
  's/^(## \[)/"## [$ENV{NXT}] - $ENV{TODAY}\n\n...\n\n" . $1/me' \
  "$CLONE/CHANGELOG.md" ||
  fail "changelog" "Could not insert the rehearsal stand-in heading into CHANGELOG.md."
grep -qE "^## \[$(sed 's/\./\\./g' <<<"$NEXT")\] - " "$CLONE/CHANGELOG.md" || fail ...
```
Copy: `perl -0pi` + `$ENV{...}` injection, then a post-write grep self-check. New script replaces `^## Unreleased — highlights$` (also bare `## Unreleased`) with `## [VER] - DATE` and prepends the reseeded block (literal em dash, `_Nothing yet for the next release._`; see CHANGELOG.md:19-21). Em dash is multibyte: run perl with `-CSD` or `use utf8` consistently, and test it.

**Rehearsal parity edit** (`bin/verify-bump-rehearsal`): replace the stand-in synthesis (l.383-399) with: seed prose under `## Unreleased — highlights` if placeholder-only, then call `"$ROOT/bin/date-release-changelog"` inside `$CLONE` (the script `cd`s to its own repo root via `BASH_SOURCE`, so it needs a `--root DIR`/env override to target `$CLONE`; planner should add that seam). Update header comment l.42-46 ("a human writes it during the release plan").

---

### `bin/retry-network` (utility, retry loop)

**Analog:** `bin/verify-deps-audit:325-335` and identical `bin/deps-health-report:235-247`
```bash
# The `n` answers any interactive Mix prompt. It is fed as a here-string,
# not `printf 'n\n' | mix ...`: under `set -o pipefail` that pipeline's
# status also counts printf, which fails (EPIPE, or SIGPIPE 141) ...
set +e
deps_get_output="$(cd "$resolved" && "$MIX_BIN" deps.get --check-locked <<<'n' 2>&1)"
deps_get_status=$?
set -e
```
Constraints derived from the repo (these bite the research's draft):
- Feed `n` with a here-string/`<<<'n'` per attempt, NOT `printf 'n\n' |` (research D-3 text says printf; `deps_health_report_test.exs:433-451` enforces "no `| \"$MIX_BIN\"`" and the pipefail/EPIPE reason). Same applies to mix.exs `steps` which currently uses `printf "n\n" | mix deps.get`.
- Capture output under `set +e` to grep deterministic markers (`mix.lock is out of date`, `Unchecked dependencies`, `Dependency resolution failed`) while still tee-ing it to the log.
- Test-delay seam: follow the `MIX_BIN` env seam style (`RETRY_NETWORK_BASE_DELAY=0`).

**Call-site test fallout (important):** wrapping `"$MIX_BIN" deps.get --check-locked` in `bin/verify-deps-audit` / `bin/deps-health-report` changes behaviour under the fake mix in `deps_audit_gate_test.exs` and `deps_health_report_test.exs`:
- `FAKE_FAIL=one:deps.get` (gate test l.226-234) emits no deterministic marker, so it would be retried 3 times and the exact `CALL_LOG` lists (e.g. gate test l.131-160 asserting `deps.get --check-locked` exactly per dir) would gain duplicate lines. Tests must set `RETRY_NETWORK_BASE_DELAY=0` and either assert the retried count or the fake must print a marker. Keep the `MIX_BIN` path: the wrapper must run `"$MIX_BIN"`-resolved command, not a hardcoded `mix`.
- `FAKE_MIX_STDIN_LOG` expectation `"n\nn\nn\n"` (health test l.433-441) stays true only if each attempt reads exactly one `n` and clean runs do not retry.

---

### `release-please-config.json` (config)

Current file (top level keys: `$schema`, `release-type`, `bump-minor-pre-major`, `bump-patch-for-minor-pre-major`, `changelog-sections`, `packages`). Add `"always-update": true,` as a top-level sibling of `release-type`. `changelog_contract_test.exs` decodes this JSON and refutes any `CHANGELOG.md` mention; do not add one.

---

### `.github/workflows/release.yml` — `sync-release-pr-pins` (workflow)

**Analog:** the job itself, lines 120-197. Insert after `mix release.pins --check` (l.175-176) and before the commit step:
```yaml
      - name: Confirm the pin writer is now idempotent
        run: mix release.pins --check

      - name: Date the CHANGELOG from the Unreleased block      # NEW
        run: bin/date-release-changelog
```
Edit commit step (l.181-196): `git add -- README.md guides/` -> `git add -- README.md guides/ CHANGELOG.md`; update the "Stage only the files the pin writer owns" comment; message at l.193 (`chore(release): sync documented install pins to @version`) stays `chore(release):`. Keep `PUSH_TOKEN` bound exactly once (l.183) and the `if: ... prs_created == 'true'` (l.130). Note l.189-192's early `exit 0` ("Install pins already match") must not skip when only CHANGELOG changed: the check is `git diff --cached --quiet`, which is after the add, so adding CHANGELOG.md before it is sufficient.

Setup-beam/pin (l.157-161) and `Fetch dependencies` (l.169-170: `run: mix deps.get`):
```yaml
      - uses: erlef/setup-beam@v1
        id: beam
        with:
          version-file: .toolchain-pin/.tool-versions
          version-type: strict
          install-hex: false          # NEW
      - name: Pin Hex (CI and local must agree)   # NEW, directly after setup-beam
        run: bin/retry-network mix local.hex 2.6.0 --force
```
Note: `bin/retry-network` lives in the target-ref checkout, which in this job happens AFTER setup-beam (the root has only `.toolchain-pin/` sparse checkout at that point). The pin step must therefore run after the second `actions/checkout` (or call `.toolchain-pin/bin/...`, which is sparse and does not contain bin/). Planner: in `sync-release-pr-pins` and any job with a ref-checkout after setup-beam, either place the pin after the checkout or use a plain `mix local.hex 2.6.0 --force` there. The research rule "pin step directly after setup-beam" conflicts here; resolve explicitly. The `release.yml:492` publish-hex and smoke jobs have the same ordering question.

**Contract to extend:** `release_control_plane_contract_test.exs:138-188` (see below).

---

### `.github/workflows/ci.yml` and the other workflow files (workflow)

**Analog (existing deps.get step), ci.yml e.g. :156/:203/:305...:**
```yaml
      - name: Install dependencies
        run: mix deps.get
```
Wrap as `run: bin/retry-network mix deps.get`. Setup-beam block with `id: beam`, `version-file: .tool-versions`, `version-type: strict` gets `install-hex: false` plus the pin step. The matrix lane (verify-test) is special, see parity notes.

---

### `mix.exs` `verify_hex_evaluator` (alias)

**Analog:** itself (~l.465-470):
```elixir
steps =
  "printf \"n\\n\" | mix deps.get && mix compile --warnings-as-errors && mix ecto.create ... && mix ecto.migrate --quiet && mix test"
```
Replace only the leading `printf "n\n" | mix deps.get` with `bin/retry-network mix deps.get`; leave `mix test` tail unwrapped. Check for the existing mix.exs test asserting this string (grep `printf` in `test/`) before editing. Raise `MIN_HEX` mention at mix.exs:190.

---

### `test/threadline/date_release_changelog_test.exs` (new)

**Analog:** `test/threadline/deps_audit_gate_test.exs` — tmp-root + `System.cmd` on a script with an env seam.

Skeleton (lines 1-24, 117-129):
```elixir
use ExUnit.Case, async: true
@script Path.expand("../../bin/verify-deps-audit", __DIR__)

defp tmp_root do
  root = Path.join(System.tmp_dir!(), "deps_audit_gate_#{System.unique_integer([:positive])}")
  File.mkdir_p!(root)
  on_exit(fn -> File.rm_rf!(root) end)
  root
end
...
{out, status} = System.cmd(@script, args, env: full_env, stderr_to_stdout: true)
```
Copy `tmp_root`, `System.cmd(..., stderr_to_stdout: true)`, and the `cd:` option (used at l.451). Caveat from l.32: `System.cmd` `:env` drops zero-length values, so use sentinels rather than empty strings. Build a fixture tree (`mix.exs` with `@version "1.2.0"`, `CHANGELOG.md`, `CHANGELOG-GENERATED.md`) in tmp, run the script with `cd:`/root override, then also run `bin/verify-release-shape` in the same tree (copy it in or point at it with `cd:`; it self-locates via `BASH_SOURCE`, so copy it to `tmp/bin/`). Cases from RESEARCH D-5: happy path, empty placeholder fails, idempotent rerun, date from generated heading, bare `## Unreleased`, em-dash reseed, `Unreleased` body containing the placeholder.

---

### `test/threadline/retry_network_contract_test.exs` (new)

**Analog 1 (rules + mutation controls):** `release_control_plane_contract_test.exs`, mutation block l.279-340:
```elixir
describe "mutation controls (D-11)" do
  setup do
    %{live: release_workflow()}
  end

  for {label, from, to, rule} <- [ {"add a mix invocation to distribution-sync", from, to, "allowlisted-job-runs-no-mix"}, ... ] do
    test "#{label} fires rule=#{rule}", %{live: live} do
      from = unquote(from)
      to = unquote(to)
      assert length(String.split(live, from)) == 2, "control anchor not found or not unique"
      mutated = String.replace(live, from, to, global: false)
      refute mutated == live, "the control did not change the input"
      assert rule_fired?(persisted_checkout_errors(mutated), unquote(rule))
    end
  end
end
```
Copy this exact discipline: a pure `*_errors(text)` function over workflow text, run on live (expect `[]`) and on mutated text (expect rule fired); anchor uniqueness assertion; `refute mutated == live`. Also the "contract is not vacuous" pattern (l.186-203).

**Analog 2 (command-position detection):** `release_control_plane_contract_test.exs:652-668` `mix_invocation?`/`line_has_mix_invocation?` + `mix_command_position?` (see l.668+). `bin/retry-network mix deps.get`: prefix before `mix` is `bin/retry-network ` (a word, not a separator), so `mix_command_position?` is false (research collision check; verify by reading `mix_command_position?` at l.668-700 before relying on it).

**Analog 3 (behaviour tests):** `deps_audit_gate_test.exs` fake-binary style (l.40-93): write a fake command into tmp via `File.write!` + chmod, count calls in a `CALL_LOG`, `FAKE_FAIL` counter files for "fail N times then succeed". Set `RETRY_NETWORK_BASE_DELAY=0` via env.

---

### `test/threadline/hex_pin_contract_test.exs` (new)

**Analog:** `ci_workflow_parity_contract_test.exs` setup-beam helpers, l.3229-3300 (`setup_beam_errors`, `file_setup_beam_errors`, `trimmed_lines`, `job_steps`, `strip_comment_lines`) and `all_workflows()` (l.127 area, `Map.new(workflow_files(), &{Path.relative_to(&1, @repo_root), File.read!(&1)})`).
```elixir
defp trimmed_lines(text), do: text |> strip_comment_lines() |> String.split("\n") |> Enum.map(&String.trim/1)
...
required = for line <- ["id: beam", version_file, "version-type: strict"], line not in lines do "..." end
```
Pattern: per workflow, split jobs, find each step containing `uses: erlef/setup-beam@`, require `install-hex: false` in its trimmed lines, and exactly one `mix local.hex <V> --force`; all V equal; V equals the `MIN_HEX="..."` literal parsed from `bin/verify-deps-audit` (regex `~r/^MIN_HEX="([^"]+)"/m`). Reuse (copy, tests don't share modules) helper bodies; add mutation controls (drop `install-hex: false`; change one version) in the same style as above. Count expectations: research says 17 setup-beam uses across workflow files; parity test asserts 11 in ci.yml only (l.2822-2826) while research says ci.yml has 12 — reconcile by grep before hard-coding any count.

---

### `test/threadline/release_control_plane_contract_test.exs` (extend)

**Analog:** itself. Add to the sync-job test (l.138-188) assertions in its house style:
```elixir
assert sync =~ "bin/date-release-changelog",
       "sync-release-pr-pins must run bin/date-release-changelog ... (REL-01)"
assert sync =~ ~r/git add -- README\.md guides\/ CHANGELOG\.md/
```
plus an ordering assertion (date step index between `mix release.pins --check` and the commit step; use `:binary.match` positions as in parity tests) and a config test decoding `release-please-config.json` (`Jason`/`YamlElixir` already used by `changelog_contract_test.exs`: `@release_please_config` at its l.28) asserting `"always-update" == true`, the `RELEASE_PLEASE_TOKEN || GITHUB_TOKEN` token expression on the release-please step, and the `prs_created == 'true'` `if:`. Add mutation controls to the existing `for {label, from, to, rule}` table or a sibling table. Beware existing control anchors that must remain unique and unchanged after workflow edits: `"ref: release-please--branches--main\n          persist-credentials: false\n"`, the publish-hex anchor `"...persist-credentials: false\n\n      - name: Install dependencies\n"` (so do NOT insert a step between that checkout and `Install dependencies`, and do not rename that step), and the smoke anchor `"...\n\n      - name: Ensure hex_evaluator_test database exists\n"`. Also `sync =~ "run: mix release.pins\n"` (l.147) must still match exactly.

---

## ci_workflow_parity_contract_test.exs: how it reads ci.yml, and what a wrapped `deps.get` trips

**Reading mode: BOTH.** The live-file readers are `read_rel!([".github","workflows","ci.yml"])` (l.7-9, used l.13, 216, 239, 249, 308, 377, 440, 2326...) and `all_workflows()` over every real workflow file (l.127). Separately, inline YAML fixtures (heredocs) embedded in the test: `run: mix deps.get` at **l.5546, 5587, 5794**, and `uses: erlef/setup-beam@v1` fixtures at l.4895, 5523, 5674. The fixtures feed the pure `*_errors/…` functions for negative/mutation controls, so they are not affected by editing ci.yml, but their expectations must stay consistent with any rule change you make in the helper (e.g. if the `run_step_class` regex is widened, the fixtures still classify).

**Rules a `bin/retry-network mix deps.get` wrapping WILL trip (live ci.yml):**
1. **`run_step_class/1` (l.4487-4493):** `Regex.match?(~r/^\s*run:\s*mix deps\.get\s*$/m, stripped) -> :deps_get`. A wrapped step classifies as `:other`. The D-07 build-cache `@build_cache_sequences` (l.3909-3919: `[:restore_build, :deps_restore, :deps_get, :deps_compile, :rm_own, :save_build, :compile]`, example: `[:restore_build, :deps_get, ...]`) are checked by `order_errors` (l.~4130) as an exact contiguous window, so every cached job (rule=order) turns red. Fix in the same change: widen the regex to `~r/^\s*run:\s*(?:bin\/retry-network\s+)?mix deps\.get\s*$/m`. Add a mutation fixture for the wrapped form.
2. **`rule=order` window also breaks if a pin step lands inside the window** — place the `Pin Hex` step right after setup-beam, which is before `restore_build`, so it is outside the window. (Check: the window starts at the `:restore_build` step.)
3. **Matrix setup-beam exact-input rule (`@matrix_beam_inputs`, l.3267-3300):** `matrix_setup_beam_errors` requires the `with:` inputs to be EXACTLY `version-file`, `otp-version`, `elixir-version`, `version-type`. Adding `install-hex: false` to the verify-test matrix lane (ci.yml ~659-661) fails `inputs` equality. Add `"install-hex: false"` to `@matrix_beam_inputs` (and update its fixtures at ~l.3070 only if they assert exact input lists).
4. **File-form setup-beam rule (l.3229-3262):** requires `id: beam`, `version-file: …`, `version-type: strict` and forbids `otp-version/elixir-version/...`; it does NOT forbid `install-hex`, so adding it is safe for file-form steps.
5. **Ordering rules (`beam_ordering_errors`, l.3606-3622; `toolchain_source_errors`, l.3500-3530):** `exactly one id: beam step` and no `steps.beam.outputs` before it — unaffected as long as the pin step does not reference `steps.beam.outputs` before setup-beam.
6. **Toolchain-count assertion (l.2822-2826):** `setup_beam_steps - 1 == 11` is a count of `uses: erlef/setup-beam@` in ci.yml; unchanged by this phase (no new setup-beam steps). Research says 12 in ci.yml; if that figure is right, this assertion already counts something else — verify with grep and do not change count assertions unless the number of steps changes.
7. **`ci_topology_contract_test.exs:784`:** `position(job, "mix deps.get")` is a substring match, still found when wrapped.
8. **`deps-health.yml`/other workflows via `all_workflows()`:** toolchain/pin rules iterate all workflow files; any job with a setup-beam step where the pin step precedes a `version-file` checkout may trip `toolchain_source_errors` pin-isolation (`pin_isolation_errors`). Release.yml's sparse `.toolchain-pin` job is the sensitive one.

The research's claim "inline fixtures only" is therefore only half right: the live-tree rules (1 and 3) need helper edits. Run the full parity file first after any workflow edit (as RESEARCH advises).

## Shared Patterns

### Contract tests parse workflow text with pure `*_errors/1` functions plus mutation controls
**Source:** `release_control_plane_contract_test.exs:279-340`, `ci_workflow_parity_contract_test.exs` (`build_cache_error/…`, `rule=` tagged messages).
**Apply to:** `retry_network_contract_test.exs`, `hex_pin_contract_test.exs`, release-control-plane extensions. Each rule has a `rule=<id>` tag, an anchor-uniqueness assertion, and a "did not change the input" guard.

### Shell scripts that take a stand-in binary through an env seam
**Source:** `bin/verify-deps-audit:55-61` (`MIX_BIN="${MIX_BIN:-mix}"`, literal non-overridable floor), `deps_audit_gate_test.exs` fake `mix`.
**Apply to:** `bin/retry-network` (delay seam), `bin/date-release-changelog` (root override seam).

### Here-string for the `n` answer, never a printf pipe
**Source:** `bin/verify-deps-audit:325-335`, `bin/deps-health-report:235-247`, guard `deps_health_report_test.exs:433-451`.
**Apply to:** `bin/retry-network` and the rewritten `verify_hex_evaluator` chain.

### Env-injected perl, post-write grep self-check, `fail "<tag>" "<msg>"` style
**Source:** `bin/verify-bump-rehearsal:383-399`.
**Apply to:** `bin/date-release-changelog`.

### Release-branch bot edits must be recomputable from the branch (force-push drops commits)
**Source:** release.yml comment l.108-118. **Apply to:** every step in `sync-release-pr-pins`; the date comes from `CHANGELOG-GENERATED.md` on the same branch.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| (retry loop logic in `bin/retry-network`) | utility | retry/backoff | No existing retry/backoff script in `bin/`; only the here-string/status-capture idiom is reusable. Use RESEARCH D-3 contract. |
| REL-02 observed-run evidence task | n/a | evidence | No existing analog; RESEARCH Open Question Q1 (`gh run list --branch release-please--branches--main`). |

## Gotchas surfaced while mapping (planner should resolve)

1. `bin/retry-network` is not on disk in jobs where the repo is checked out after setup-beam (release.yml sync/publish/smoke use a sparse `.toolchain-pin` first). Pin step placement "directly after setup-beam" must be reconciled with the checkout order there.
2. Research D-3 says retry supplies `printf 'n\n'`; the repo forbids pipes into mix (pipefail/EPIPE). Use `<<<'n'`.
3. `MIN_HEX` bump invalidates the fake `FAKE_HEX_INFO: "Hex:    2.5.1"` base env in `deps_audit_gate_test.exs:~116` (it is the passing default) and the l.182/445 assertions; update together. `ci.all` locally red on Hex 2.5.1 is expected (RESEARCH Pitfall 6).
4. Adding retries around `deps.get --check-locked` in `verify-deps-audit` makes non-marker fake failures retried; adjust the gate/health tests' env (`RETRY_NETWORK_BASE_DELAY=0`) and exact `CALL_LOG` assertions.
5. Tracked-source gate: all analog paths above were checked as tracked repo paths (no `.gsd/capabilities` mirrors involved).

## Metadata

**Analog search scope:** `bin/`, `.github/workflows/`, `test/threadline/`, `mix.exs`, `release-please-config.json`
**Files read:** RESEARCH.md, release.yml (l.100-200), release_control_plane_contract_test.exs (l.1-200, 275-340, 400-420, 650-670), ci_workflow_parity_contract_test.exs (targeted ranges), deps_audit_gate_test.exs (l.1-130), deps_health_report_test.exs (l.425-470), bin/verify-release-shape, bin/verify-bump-rehearsal (header, l.375-405, 455-466), bin/verify-deps-audit (l.55-66, 320-335), changelog_contract_test.exs head
**Pattern extraction date:** 2026-10-24
