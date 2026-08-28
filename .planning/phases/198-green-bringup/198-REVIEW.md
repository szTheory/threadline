---
phase: 198-green-bringup
reviewed: 2026-08-27T00:00:00Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - .github/rulesets/main.json
  - .github/workflows/branch-protection.yml
  - .github/workflows/browser-full.yml
  - .github/workflows/ci.yml
  - .github/workflows/flake-detection.yml
  - .github/workflows/release.yml
  - CONTRIBUTING.md
  - bin/verify-branch-protection
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - examples/threadline_phoenix/e2e/run-e2e.sh
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/live/evidence_live.ex
  - lib/threadline/operator_surface/live/export_status_live.ex
  - lib/threadline/operator_surface/live/policy_redaction_live.ex
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/row_history_live.ex
  - lib/threadline/operator_surface/live/start_live.ex
  - lib/threadline/operator_surface/live/stress_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - mix.exs
  - test/test_helper.exs
  - test/threadline/ci_coverage_doc_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/operator_surface/ui_form_policy_contract_test.exs
  - test/threadline/phase06_nyquist_ci_contract_test.exs
  - test/threadline/zero_skips_contract_test.exs
findings:
  critical: 5
  warning: 9
  info: 6
  total: 20
status: issues_found
---

# Phase 198: Code Review Report

**Reviewed:** 2026-08-27
**Depth:** standard
**Files Reviewed:** 29
**Status:** issues_found

## Summary

Phase 198 is a CI-honesty phase, so the review weighted the gates themselves over
the product code. The LiveView changes (`@ui_form_policy` declarations) and the
`mix.exs` alias additions are mechanically sound; the defects cluster in the two
new/rewritten gates.

Two of the four properties the phase claims for `.github/workflows/flake-detection.yml`
do not actually hold: the classifier step never runs on the failure path it exists
for (a `set -e` mistake), and its fall-through classification is `flaky`, not
`unknown`. Three of the properties claimed for `bin/verify-branch-protection` hold
(jq guard, exact sorted equality, empty-list failure, non-emitted-context failure);
the third block — "classic protection must not be stacking" — is vacuous under the
workflow's own token, and the two ruleset properties that actually make the rule set
unbypassable (`enforcement`, `bypass_actors`) are never verified at all.

The five release-publish gates in `.github/workflows/release.yml` are intact — the
hard `needs:`, the `production-hex` environment approval, the CI-green poll, the
idempotency skip, and post-publish verification are all present and none of them can
be bypassed by the code as written. `test/threadline/ci_topology_contract_test.exs`
correctly asserts single-publish-path equality. What is broken there is the
*documentation* of that contract, which still advertises a deleted second publish
path.

**Excluded as known/filed per phase scope:** the 79 unprefixed-audit-table test
failures and the `CONTRIBUTING.md` List 1 job-key parity failure. These were
observed but are not reported as new findings (the List 1 drift appears once below,
as Info, only because it is the same doc section as a live-config contradiction).

## Critical Issues

### CR-01: Flake-detection classifier never runs on the failure path it exists for

**File:** `.github/workflows/flake-detection.yml:84-89`
**Issue:** The step comment states "Captures the exit code instead of failing here,
so the classification and issue steps below still run." It does not. GitHub Actions
runs an unspecified-shell `run:` block as `bash -e {0}`; `set -uo pipefail` adds
`-u` and `pipefail` but **does not clear `-e`**. When `mix verify.flake` fails, the
`mix ... | tee` pipeline returns non-zero, `-e` aborts the step immediately, and
`echo "exit_code=..."` never executes.

Consequences, all on the only path that matters:
- `steps.repeat.outputs.exit_code` is never written.
- `Classify broken vs flaky` has no `if:` (defaults to `success()`), so it is
  **skipped**.
- `Open or update the flake tracking issue` is gated on
  `steps.classify.outputs.classification != 'pass'` and is likewise skipped.

The entire GREEN-11 / D-35 broken-vs-flaky classifier and its tracking issue are
dead code in production. A nightly `schedule:` failure notifies nobody — which the
workflow header identifies as the exact failure mode it was written to prevent.

**Fix:**
```yaml
      - name: Repeat the suite until failure
        id: repeat
        run: |
          set +e
          set -uo pipefail
          mix verify.flake 2>&1 | tee flake-detection.log
          echo "exit_code=${PIPESTATUS[0]}" >> "$GITHUB_OUTPUT"
          exit 0

      - name: Classify broken vs flaky
        id: classify
        if: always()
        # ...
```
Also add `if: always()` to the classify step so a future change to the capture step
cannot silently re-disable the classifier.

### CR-02: Unparseable classifier output is reported as `flaky`, not `unknown`

**File:** `.github/workflows/flake-detection.yml:107-117`
**Issue:** The design contract (workflow header lines 11-13) is: "output that does
not match the expected shape is reported as UNKNOWN with the raw log attached —
never silently downgraded to 'flaky'". The implementation makes `flaky` the
fall-through `else`, so any state that is not provably `0` or `1` iterations lands
on `flaky`.

Concretely, when `flake-detection.log` does not exist (the `tee` failed, the disk
filled, the step layout changed), `grep -c 'Running ExUnit with seed:' flake-detection.log`
writes nothing to stdout and `|| true` swallows the error, leaving `iterations=""`.
Then:
- `[ "" -eq 0 ]` → bash prints `integer expression expected` and returns 2. Under
  `set -e` an `if`/`elif` *condition* is exempt from abort, so this is silently
  treated as false.
- `[ "" -eq 1 ]` → same, false.
- `else` → `classification=flaky`.

A broken suite with no readable log is filed as an intermittent annoyance — verbatim
the outcome the header forbids. The `unknown` branch is reachable only via the exact
`iterations == "0"` case.

**Fix:**
```bash
          iterations=$(grep -c 'Running ExUnit with seed:' flake-detection.log 2>/dev/null || true)

          if [ "$EXIT_CODE" = "0" ]; then
            classification=pass
          elif ! printf '%s' "$iterations" | grep -Eq '^[0-9]+$'; then
            # No parseable iteration count at all — never guess.
            classification=unknown
            iterations=0
          elif [ "$iterations" -eq 0 ]; then
            classification=unknown
          elif [ "$iterations" -eq 1 ]; then
            classification=broken
          elif [ "$iterations" -gt 1 ]; then
            classification=flaky
          else
            classification=unknown
          fi
```
Note the `flaky` branch must be positively asserted (`-gt 1`), not a fall-through.

### CR-03: Branch-protection block (c) is vacuous — it can never fail in CI

**File:** `bin/verify-branch-protection:106-117`, `.github/workflows/branch-protection.yml:27-44`
**Issue:** Block (c) probes classic branch protection with:
```bash
CLASSIC_STATUS=$(gh api "repos/${REPO}/branches/${BRANCH}/protection" ... >/dev/null 2>&1 && echo "present" || echo "absent")
```
`GET /repos/{o}/{r}/branches/{b}/protection` requires repository *administration*
permission. The workflow declares `permissions: contents: read`, and GitHub sets
every unlisted scope to `none`, so `GITHUB_TOKEN` cannot carry `administration:
read`. The call therefore returns 403 unconditionally, and 403 is mapped to
`"absent"` — the passing branch. The script also maps a genuine 404 (no classic
protection) to `"absent"`, so a permission error and a real pass are
indistinguishable.

Block (c) is a gate that structurally cannot fail. The script's own header
(lines 14-19) argues this block is load-bearing precisely because half (a) reads
only ruleset rules — so this is a gate that reports coverage it does not have.
That is the vacuous-gate pattern this milestone exists to eliminate.

**Fix:** Distinguish the three outcomes on the HTTP status, and fail on anything
that is not a definitive 404. Requesting the scope is not sufficient on its own —
`GITHUB_TOKEN` cannot be granted `administration`, so this half needs a PAT or must
be honestly demoted to "not verified in CI" (and removed from the header's claims).
```bash
CLASSIC_HTTP=$(gh api -i "repos/${REPO}/branches/${BRANCH}/protection" 2>/dev/null \
  | head -1 | awk '{print $2}' || true)
case "${CLASSIC_HTTP:-000}" in
  404) : ;;                                   # genuinely absent — the only pass
  200) echo "FAIL (c): classic branch protection still exists..." >&2; exit 1 ;;
  *)   echo "FAIL (c): could not determine classic-protection state (HTTP ${CLASSIC_HTTP:-none})." >&2
       echo "This check requires an 'administration: read' token; GITHUB_TOKEN cannot carry it." >&2
       exit 1 ;;
esac
```

### CR-04: API failure is laundered into "zero check runs emitted" in half (b)

**File:** `bin/verify-branch-protection:95-104`, `.github/workflows/branch-protection.yml:27`
**Issue:** Two compounding defects:

1. **Missing scope.** `GET /repos/{o}/{r}/commits/{sha}/check-runs` requires
   `checks: read`. The workflow declares only `contents: read`, so every other scope
   is `none`. Half (b) is expected to 403 on every scheduled run.
2. **Error/absence conflation.** On any API failure the pipeline yields an empty
   `EMITTED_COUNT` (jq over empty stdin exits 0, so the `|| echo "0"` guard does not
   even fire), and `"${EMITTED_COUNT:-0}" -lt 1` then reports:
   *"no check run named 'CI required' has ever been emitted ... Either the aggregate
   job's `name:` drifted from the required context, or no run has completed on this
   head yet."*

   Both stated causes are wrong. The operator is sent to inspect `ci-required`'s
   `name:` when the real cause is a token scope. A permanently-red scheduled job
   whose diagnosis is misleading is a gate that gets muted, not fixed.

**Fix:** Grant the scope and separate transport failure from a real zero.
```yaml
permissions:
  contents: read
  checks: read
```
```bash
CHECK_RUNS_JSON=$(gh api "repos/${REPO}/commits/${HEAD_SHA}/check-runs?per_page=100" \
  -H "Accept: application/vnd.github+json" 2>/dev/null || true)
if [[ -z "$CHECK_RUNS_JSON" ]]; then
  echo "Could not read check runs for ${REPO}@${HEAD_SHA} (token likely lacks 'checks: read')." >&2
  exit 1
fi
EMITTED_COUNT=$(printf '%s' "$CHECK_RUNS_JSON" \
  | jq --arg name "$EXPECTED_CONTEXT" '[.check_runs[]? | select(.name == $name)] | length')
```

### CR-05: The verifier never checks `enforcement` or `bypass_actors` — the ruleset can be silently made non-binding

**File:** `bin/verify-branch-protection:51-104`, `.github/workflows/branch-protection.yml`, `.github/rulesets/main.json:3-5`
**Issue:** `.github/rulesets/main.json` carries the two properties that make the rule
set actually binding — `"enforcement": "active"` and `"bypass_actors": []` — but
nothing verifies them against the live repository:

- The script asserts **only** the required-status-check context list. Adding a bypass
  actor (an app, a team, or the repository-admin role) in the GitHub UI leaves all
  three blocks green while making `CI required` skippable for that actor.
- `.github/rulesets/main.json` is a checked-in snapshot that no code reads. Nothing
  applies it and nothing diffs it against live config, so the file and reality can
  diverge without any signal.
- `GET /repos/{o}/{r}/rules/branches/{b}` returns rules for rule sets in `evaluate`
  mode as well as `active` mode, so flipping enforcement to `evaluate` — which stops
  the ruleset blocking anything — is also invisible to half (a).

The script's own banner claims to assert "`main`'s protection contract". It asserts
one clause of it.

**Fix:** Fetch the rule set itself and assert the invariants, and diff the live rule
set against the committed JSON so the snapshot stops being decorative.
```bash
RULESET=$(gh api "repos/${REPO}/rulesets?includes_parents=false" --jq \
  '.[] | select(.name == "main-protection")' 2>/dev/null || true)
[[ -n "$RULESET" ]] || { echo "FAIL (d): rule set 'main-protection' not found on ${REPO}." >&2; exit 1; }

RULESET_ID=$(printf '%s' "$RULESET" | jq -r '.id')
FULL=$(gh api "repos/${REPO}/rulesets/${RULESET_ID}")

[[ "$(printf '%s' "$FULL" | jq -r '.enforcement')" == "active" ]] || {
  echo "FAIL (d): rule set enforcement is not 'active' — the rules do not block." >&2; exit 1; }

BYPASS=$(printf '%s' "$FULL" | jq -c '.bypass_actors // []')
[[ "$BYPASS" == "[]" ]] || {
  echo "FAIL (d): rule set declares bypass actors ${BYPASS}; the contract requires none." >&2; exit 1; }
```

## Warnings

### WR-01: `gate-ci-green` is not granted `actions: read`

**File:** `.github/workflows/release.yml:34-37, 225-284`
**Issue:** The workflow-level block declares `contents: write`, `pull-requests:
write`, `issues: write`. Declaring any scope sets all unlisted scopes to `none`, and
`gate-ci-green` declares no job-level `permissions:`, so it inherits that set.
`github.rest.actions.listWorkflowRuns` requires `actions: read`. This gate fails
closed (a 403 throws inside `github-script`, the job fails, `publish-hex`'s hard
`needs:` blocks the publish), so it is not a security hole — but it makes the
canonical release path unable to complete for a reason unrelated to release
readiness, which is exactly the pressure that gets gates removed.
**Fix:**
```yaml
  gate-ci-green:
    name: Verify CI is green on release SHA
    permissions:
      contents: read
      actions: read
```

### WR-02: Docs advertise a deleted, ungated second Hex publish path

**File:** `CONTRIBUTING.md:447`, `CONTRIBUTING.md:550`, `.github/workflows/release.yml:5-6`
**Issue:** `.github/workflows/hex-publish.yml` no longer exists (workflow directory
now contains only `branch-protection.yml`, `browser-full.yml`, `ci.yml`,
`flake-detection.yml`, `release.yml`), and
`ci_topology_contract_test.exs:156` asserts exactly one publish path. But
CONTRIBUTING.md still states:

> **Legacy fallback:** pushing tag **`v*.*.*`** still triggers
> [`.github/workflows/hex-publish.yml`](.github/workflows/hex-publish.yml) (no CI
> gate, no doc sync).

and release.yml's own header calls it the "Legacy tag-only path ... (fallback)".
Both links are 404s. The reality is safe (nothing triggers), but the docs tell a
maintainer that an ungated publish path is available and encourage reaching for it
during a release incident — precisely when the five gates matter most.
**Fix:** Delete both CONTRIBUTING.md sentences and release.yml lines 5-6; replace
with an explicit statement that `release.yml` is the only publish path and that a
tag push alone publishes nothing.

### WR-03: CONTRIBUTING misstates which preflight the release workflow runs

**File:** `CONTRIBUTING.md:516`
**Issue:** "Runs **`mix verify.release`**, then **`mix hex.publish --yes`**". The
workflow runs `bin/verify-release-shape` followed by `mix hex.build`
(`release.yml:345-350`); `mix verify.release` (mix.exs:96, `&verify_release/1`) is
never invoked in CI. A maintainer reproducing the gate locally runs a different
check than the one that gates the publish.
**Fix:** State the actual steps: `bin/verify-release-shape` + `mix hex.build`, and
note that `mix verify.release` is the local superset.

### WR-04: `dry_run` skips the release-shape and tarball preflight

**File:** `.github/workflows/release.yml:345-350`
**Issue:** `Run release tarball preflight` carries `if: env.DRY_RUN != 'true'`, so
`bin/verify-release-shape` and `mix hex.build` do not run on a dry run. A dry run
exists to exercise the real path without the irreversible step; skipping two of the
five gates means a dry run can pass while the real run fails on shape or build. It
also means the one safe rehearsal never rehearses the gates.
**Fix:** Remove the `if:` from the preflight step — it is non-destructive and should
run on both paths. Keep the guard only on `Skip if version already on Hex` and
`Verify version on Hex.pm`.

### WR-05: The CI Coverage doc contract is blind to the lane it documents

**File:** `test/threadline/ci_coverage_doc_contract_test.exs:40-45`
**Issue:** The derive source is `~r/--project[= ]([a-z0-9-]+)/` over `ci.yml` and
`browser-full.yml`. `browser-full.yml:104` deliberately runs
`mix verify.example_browser` with **no** `--project` flags ("Unrestricted (no
per-project flags): the whole registered project set"). So the derived set is exactly
`{desktop-chromium, mobile-chromium}` from ci.yml, and the six projects that the full
lane actually runs (`tier-a-capture`, `tier-a-capture-light`, `storybook-capture`,
`graded-capture`, `refute-capture`, `route-capture`) are never asserted against the
table.

The moduledoc claims the guard catches "a project a workflow actually runs is
missing from the table", and browser-full.yml's comment at :100-101 claims "Adding a
flag here without adding the corresponding CONTRIBUTING.md row turns
ci_coverage_doc_contract_test.exs red" — which is true only for *flagged* projects.
Adding a project to `playwright.config.ts` puts it in the full lane immediately and
the table guard says nothing. The "no `--project` flags at all" vacuity assertion at
:63 passes because ci.yml still has two.
**Fix:** Derive the roster from the real source of truth — the `projects` array in
`examples/threadline_phoenix/e2e/playwright.config.ts` — and treat any workflow that
invokes `verify.example_browser` without `--project` as running the whole set:
```elixir
defp registered_projects do
  config = File.read!(@playwright_config)
  ~r/^\s*(?:\{\s*)?name:\s*"([a-z0-9-]+)"/m
  |> Regex.scan(config)
  |> Enum.map(fn [_, name] -> name end)
  |> Enum.uniq()
end
```
then assert a table row for every registered project, plus keep the existing
flag-scan assertion for the reduced PR lane.

### WR-06: The `@ui_form_policy` guard misses the idiomatic LiveView form syntax

**File:** `test/threadline/operator_surface/ui_form_policy_contract_test.exs:44, 86-93`
**Issue:** `@form_control_tokens ["<input", "<select", "<textarea", "<form"]` is a raw
substring scan over the page source. This codebase renders form controls through
function components — `lib/threadline/operator_surface/ui.ex:1451-1654` defines
`UI.field`/control components containing the actual `<input>`/`<select>` markup.
`"<.form"`, `"<.input"`, `"<UI.field"`, and `"<.field"` contain none of the four
tokens (the `.` breaks `"<form"` and `"<input"`).

So a page declared `:formless` can add `<.form phx-submit="...">` with `<UI.field .../>`
children and the guard passes. The declaration comments added to
`actor_live.ex:5-7`, `evidence_live.ex:7-9`, `export_status_live.ex:7-9`,
`row_history_live.ex:6-8`, and `transaction_live.ex:5-7` all promise "a change that
adds a form control fails the guard in the same diff" — which does not hold for the
form syntax the project prefers.
**Fix:**
```elixir
@form_control_tokens [
  "<input", "<select", "<textarea", "<form",
  "<.form", "<.input", "<.select", "<.textarea",
  "UI.field", "UI.field_group", "<.field", "<.simple_form"
]
```

### WR-07: The moduledoc claims reverse-drift coverage the test does not provide

**File:** `test/threadline/operator_surface/ui_form_policy_contract_test.exs:18-21, 95-96`
**Issue:** Defect 3 in the moduledoc is stated as closed: "**Reverse drift went
unnoticed.** A page that keeps a stale exemption after its form is removed, or that
grows a form while still listed as formless, was invisible." Only the second half is
closed. The `[{:has_forms, reason}]` branch is `:ok` — an unconditional pass with no
assertion that the page contains any form markup at all. A page that loses its last
form keeps `{:has_forms, "..."}` forever and nothing notices. The docstring itself
concedes this at :28-30 ("It is an unconditional pass"), contradicting its own
defect-3 claim ten lines earlier.
**Fix:** Either assert the converse (a `:has_forms` page must contain at least one
form token, so removing the last one fails the guard in the same diff), or amend the
moduledoc to state that only forward drift is caught. The assertion is cheap:
```elixir
[{:has_forms, reason}] when is_binary(reason) and reason != "" ->
  source = File.read!(path)

  assert Enum.any?(@form_control_tokens, &String.contains?(source, &1)),
         "#{relative} declares {:has_forms, #{inspect(reason)}} but contains no form " <>
           "control. If the form was removed, change the declaration to :formless in " <>
           "this same diff — a stale exemption is the reverse drift this guard exists to catch."
```

### WR-08: The login preflight bypasses the single failure-diagnosis mechanism

**File:** `examples/threadline_phoenix/e2e/run-e2e.sh:176`
**Issue:** `fail_with_log()` was extracted (comment at :44-46) so there is "ONE way
to fail loudly with the boot log rather than two copies drifting apart". But
line 176:
```bash
curl --max-time 60 -fsS "${BASE_URL}/users/log_in" >/dev/null
```
runs bare under `set -e`. If the login page 500s or the request times out, the script
exits with `curl`'s status and prints nothing — no boot log, no message. Every other
preflight failure path (:166, :172, :182) routes through `fail_with_log`. This is the
one path that does not, and it sits between the two that do.
**Fix:**
```bash
curl --max-time 60 -fsS "${BASE_URL}/users/log_in" >/dev/null ||
  fail_with_log "GET ${BASE_URL}/users/log_in failed after boot; log follows:"
```

### WR-09: The e2e boot-log path is computed in one place and hardcoded in three

**File:** `examples/threadline_phoenix/e2e/run-e2e.sh:10`, `.github/workflows/ci.yml:384`, `.github/workflows/browser-full.yml:114`
**Issue:** The script writes to `${TMPDIR:-/tmp}/threadline_phoenix_e2e.log`, while
both artifact-upload steps hardcode `/tmp/threadline_phoenix_e2e.log`. These agree
only while `TMPDIR` is unset. Both upload steps use `if-no-files-found: warn`, so
when they disagree the boot log is dropped from the diagnostics bundle with a warning
nobody reads — and the boot log is the artifact that explains a D-18 preflight abort,
the exact scenario the uploads were added for.
**Fix:** Pin the location explicitly and export it so the workflows can reference one
value:
```bash
LOG_FILE="${THREADLINE_E2E_LOG:-/tmp/threadline_phoenix_e2e.log}"
```
and set `THREADLINE_E2E_LOG: /tmp/threadline_phoenix_e2e.log` in the job `env:` of
both workflows, referencing `${{ env.THREADLINE_E2E_LOG }}` in the `path:` list.

## Info

### IN-01: Tracking-issue bodies render as code blocks

**File:** `.github/workflows/flake-detection.yml:176-189`, `.github/workflows/browser-full.yml:143-151`
**Issue:** The `body="..."` heredoc-less strings indent every continuation line by 10
spaces. Markdown treats a line indented four or more spaces as a code block, so the
tracking issue renders the classification, the run link, and the guidance as
preformatted text rather than a readable bulleted body with a clickable link.
**Fix:** Left-align the continuation lines, or build the body with `cat <<'EOF'` and
no indentation.

### IN-02: Half (b) accepts a permanently failing check run, and does not paginate

**File:** `bin/verify-branch-protection:95-97`
**Issue:** The count filters on `.name == "CI required"` only; a check run whose
`conclusion` is `failure` or `cancelled` satisfies the assertion. That matches the
stated intent ("the name has ACTUALLY been emitted"), so it is not a defect — but it
is worth stating in the header so nobody later reads a green half (b) as "CI passed
on main". Separately, `per_page=100` is not paginated; a head commit carrying more
than 100 check runs could miss the required one and produce a false FAIL (b).
**Fix:** Document the conclusion-agnostic intent in the header comment; optionally
add `--paginate` to the `gh api` call.

### IN-03: Ruleset is pinned to a literal ref and permits zero-review self-merge

**File:** `.github/rulesets/main.json:8, 26-30`
**Issue:** Two observations, both defensible for a solo-maintainer OSS repo but worth
recording: (1) `"include": ["refs/heads/main"]` is a literal rather than
`"~DEFAULT_BRANCH"`, so renaming the default branch silently unprotects it; (2)
`required_approving_review_count: 0` with `require_last_push_approval: false` means
the `pull_request` rule enforces PR *shape* only — `CI required` is the sole
substantive gate.
**Fix:** Consider `"~DEFAULT_BRANCH"`; leave the review count as-is deliberately and
state the reasoning in the migration audit.

### IN-04: `test.reset` does more than the tripwire hint says

**File:** `test/test_helper.exs:75`, `mix.exs:126-136`
**Issue:** The tripwire message reads "Fix: `mix test.reset` (drops the test database;
the next run recreates and migrates it)". The alias is
`["ecto.drop --quiet -r Threadline.Test.Repo", "test.setup"]` and `test.setup` ends in
`"test"`, so `mix test.reset` drops the DB, fetches example-app deps, and runs the
entire suite in one command. Accurate expectation-setting matters here because the
suite currently takes ~73s per run.
**Fix:** Amend the hint to "(drops the test database, then re-runs the suite, which
recreates and migrates it)".

### IN-05: The nightly flake lane will file every night while the suite is knowingly red

**File:** `.github/workflows/flake-detection.yml:101-205`
**Issue:** With the suite at 80 known failures, the lane will classify `broken` on
every nightly run and append a comment to the same tracking issue indefinitely. The
dedup keeps it to one issue, which is the right design, but the comment stream will
be pure noise until the known failures are fixed. (This only becomes visible once
CR-01 is fixed and the classifier actually runs.)
**Fix:** No code change required; consider disabling the `schedule:` trigger until
the red baseline is retired, or noting the expectation in the tracking issue body.

### IN-06: `CONTRIBUTING.md` "Branch protection (maintainers)" contradicts the live single-context contract

**File:** `CONTRIBUTING.md:489-502`
**Issue:** This section instructs maintainers to require eight named checks on `main`
("Check formatting", "Run Credo (strict)", "Run test suite (min)", ...). The live rule
set (`.github/rulesets/main.json:16`) and `ci.yml:3-7` establish `CI required` as the
**single** required context. Following this section verbatim would re-introduce
exactly the multi-context configuration D-08 removed, and would make
`bin/verify-branch-protection` half (a) fail.

Recorded here rather than as a Warning because the adjacent List 1 job-key parity gap
is the known, filed, unowned `CONTRIBUTING.md` drift that is explicitly out of this
phase's scope. The two live in the same document and should be fixed together.
**Fix:** Replace the eight-item list with the single `CI required` context and a
pointer to `.github/rulesets/main.json` plus `bin/verify-branch-protection`, and add
the two missing job keys (`verify-mechanical`, `verify-capture`) to List 1 in the same
edit.

---

_Reviewed: 2026-08-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
