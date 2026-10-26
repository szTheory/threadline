---
phase: 245-supply-chain
reviewed: 2026-10-25T00:00:00Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - .github/dependabot.yml
  - .github/workflows/branch-protection.yml
  - .github/workflows/browser-full.yml
  - .github/workflows/ci.yml
  - .github/workflows/community-health.yml
  - .github/workflows/deps-health.yml
  - .github/workflows/environment-protection.yml
  - .github/workflows/flake-detection.yml
  - .github/workflows/release.yml
  - CONTRIBUTING.md
  - bin/deps-audit-tier
  - bin/deps-health-report
  - bin/upsert-ci-issue
  - bin/verify-action-pins
  - bin/verify-deps-audit
  - test/threadline/browser_journey_evidence_contract_test.exs
  - test/threadline/ci_action_pin_contract_test.exs
  - test/threadline/ci_action_runtime_contract_test.exs
  - test/threadline/ci_issue_upsert_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/dependabot_config_contract_test.exs
  - test/threadline/deps_audit_gate_test.exs
  - test/threadline/deps_health_doc_contract_test.exs
  - test/threadline/deps_health_report_test.exs
  - test/threadline/flake_classifier_contract_test.exs
  - test/threadline/verify_action_pins_test.exs
findings:
  critical: 0
  warning: 3
  info: 7
  total: 10
status: issues_found
---

# Phase 245: Code Review Report

**Reviewed:** 2026-10-25
**Depth:** standard (diff range `91dc99bc..HEAD`; SARIF fixtures under `test/fixtures/deps_audit/` read as context)
**Files Reviewed:** 27
**Status:** issues_found

## Summary

I checked the phase against the locked decisions D-01..D-30. The main focus was fail-closed behaviour in the bash gates, quoting in workflow steps and URL construction, temp-file cleanup, contract tests that could pass without testing anything, and CONTRIBUTING claims that disagree with the code.

Overall the gates are sound:
- Every ambiguous audit shape in `bin/deps-audit-tier` ends in a FAIL or an `unknown`. That covers: no SARIF file, unparseable JSON, a non-zero exit with zero results, exit 0 with results, an unparseable fingerprint, an unknown kind, and a row-count mismatch.
- `deps.tree` failing or returning an empty closure fails closed in both consumers.
- Every temp directory is registered with the single EXIT trap.
- The `github-script` step in `release.yml` now reads `RELEASE_SHA` from `env:`, which removes the old expression interpolation into JS.
- `bin/verify-action-pins` checks repo, SHA and tag before building any API path, and it fails closed on every gh error or malformed answer.
- I ran the `dat_closure` parser against the real `mix deps.tree --only prod --format plain` output of the root project. It produced the expected closure, with nested `|   |--` and `` `-- `` lines handled.

No BLOCKERs. The three WARNINGs are:
- one latent fail-open in the tier rule (renamed Hex deps);
- the live closure test re-implements the bash parser instead of running it;
- the D-29 "class set equals RANK_NAMES" doc contract only checks one direction.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: A renamed Hex dependency (`hex:` option) is mis-tiered as non-blocking (latent fail-open)

**File:** `bin/deps-audit-tier:204` (`dat_closure`) and `bin/deps-audit-tier:212-219` (`dat_tier`)
**Issue:** The closure file holds the names `mix deps.tree` prints. Those are the dependency **app** names, and for Hex deps the suffix is just `(Hex package)`, with no package name. The SARIF fingerprint names the **Hex package** (`advisory:hexpm/<package>:<id>`). For a dep declared as `{:foo, "~> 1.0", hex: :foo_bar}` (lock entry `"foo": {:hex, :foo_bar, ...}`), the advisory arrives as `package=foo_bar`. `grep -Fxq foo_bar closure.txt` then misses, and `dat_tier` prints `non-blocking`. A real advisory in shipped runtime code would leave the required gate green, and the release lane would publish. Nothing in the root `mix.exs` uses `hex:` today, so this is latent, but it breaks the D-16 "blocking iff in the runtime closure" guarantee silently. No test or doc mentions the limitation.
**Fix:** Map app names to Hex package names from the lock before tiering. Alternatively, fail closed when the closure contains an app whose lock entry names a different package. For example, after writing the closure:
```bash
# in dat_closure, after building $out: add the Hex package name for every app
# whose mix.lock entry is {:hex, :<pkg>, ...} with pkg != app
while IFS= read -r app; do
  pkg="$(sed -nE "s/^  \"$app\": \{:hex, :([a-z0-9_]+),.*/\1/p" "$dir/mix.lock")"
  [ -z "$pkg" ] || [ "$pkg" = "$app" ] || printf '%s\n' "$pkg"
done <"$out" | sort -u -o "$out.extra" && sort -u "$out" "$out.extra" -o "$out"
```
Add a gate test with a fake tree listing `foo` and a SARIF finding for `foo_bar` that must exit 1.

### WR-02: The live-tree closure contract re-implements the parser, so the bash parser that decides blocking is never run against real `deps.tree` output offline

**File:** `test/threadline/deps_audit_gate_test.exs:1240-1281`
**Issue:** D-23 asks for a live-tree contract on the real `--only prod` closure. The test runs `mix deps.tree` itself and parses it with its own Elixir copy of the strip logic (`String.replace(~r/^[|` -]*/, "") |> String.split(" ") |> hd()`). It never calls `dat_closure` in `bin/deps-audit-tier`. The fake `mix` in the same file (`deps.tree` branch, around lines 104-114) only prints flat `|-- name` lines, never the nested `|   |-- ` or `` `-- `` forms. So the only check that the bash `sed -E 's/^[|` -]*//; s/ .*//'` handles real nested output is the network `--self-test`, and its case (a) only needs top-level `plug`.

If the bash regex drifts (an edited glyph class, a changed `tail -n +2`), transitive runtime packages such as `plug_crypto` or `telemetry` would drop out of the closure and their advisories would become non-blocking. All offline tests would stay green. I confirmed by hand that the current parser is correct on today's tree, but nothing pins that.
**Fix:** Have the live test source the library and run the real function. For example, run `bash -c 'ROOT=...; MIX_BIN=mix; source bin/deps-audit-tier; dat_closure . "$1"; cat "$1"'` and assert on that output instead of re-parsing. Also make the fake `deps.tree` print at least one nested `|   `-- child` line, so cases 1-3 cover transitive parsing.

### WR-03: The D-29 doc contract "class set CONTRIBUTING names equals RANK_NAMES" only checks a subset

**File:** `test/threadline/deps_health_doc_contract_test.exs:235-247`
**Issue:** The test is named for (and D-29 requires) set **equality** between the classes CONTRIBUTING names and `RANK_NAMES`. It only checks that each `RANK_NAMES` entry appears backticked in the policy section. A CONTRIBUTING edit that brings back a class the classifier no longer emits (`` `outdated` ``, or a new `` `stale` ``) would pass. The only guard against `outdated` coming back is the narrow `refute ... =~ "alone stays green"` at line 249, which matches one old phrasing. So the honest-docs contract can drift in the direction D-24 was meant to close.
**Fix:** Derive the documented class set from the precedence sentence, which has a fixed shape (`` `advisory` ... > `retirement` ... > `unknown` > `clean` ``), and compare it for equality:
```elixir
[_, chain] = Regex.run(~r/highest wins.*?:\s*(`[a-z]+`.*?`clean`)/s, section)
documented = Regex.scan(~r/`([a-z]+)`/, chain, capture: :all_but_first) |> List.flatten()
assert Enum.sort(documented) == Enum.sort(names)
```
At minimum, add `refute section =~ "`outdated`"` as a mutation-style guard.

## Info

### IN-01: Tab-IFS `read` collapses an empty id field and shifts the message into `id`

**File:** `bin/verify-deps-audit:541`, `bin/deps-health-report:376`
**Issue:** `IFS=$'\t' read -r f_kind f_pkg f_id f_msg`: tab is an IFS-whitespace character, so consecutive tabs collapse into one separator. If a retirement result has no `ruleId` (`$m.id // .ruleId // ""` gives an empty string), the message text lands in `f_id`. It then appears in the machine line `id=<message>` and in the `::error::` text. Classification is unaffected because kind and package are still right. The D-18 machine line contract is not.
**Fix:** Emit a placeholder for an empty id in `dat_findings` (`($m.id // .ruleId // "-")`), or switch the field separator to a non-whitespace byte such as `\x1f`.

### IN-02: CONTRIBUTING says a failing `deps.tree` is blocking "in all three directories"

**File:** `CONTRIBUTING.md` (the "Everything other than a finding stays blocking in all three directories: ... a failing `deps.tree` or an empty closure" sentence)
**Issue:** `deps.tree` runs only for closure-rule directories (`bin/verify-deps-audit:506`). It never runs for `bench` or `examples/threadline_phoenix`, so it cannot fail there. The sentence overstates what the code does.
**Fix:** Move "a failing `deps.tree` or an empty closure" out of the all-three list into a root-only clause.

### IN-03: The `verify-action-pins` repo check accepts `.` and `..` as the repo segment

**File:** `bin/verify-action-pins:92` (`re_repo='^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$'`), and the matching `@pin_form` in `test/threadline/ci_action_pin_contract_test.exs:55`
**Issue:** `actions/..@<sha> # v1.0.0` passes both the offline form contract and this check, and builds `repos/actions/../git/ref/tags/v1.0.0`. The token is read-only and the lookup would most likely 404, which fails closed as UNVERIFIED, so this is not exploitable. It does contradict the header's claim that "no workflow text reaches the request path unchecked".
**Fix:** Reject dot-only segments: `[[ "${repo#*/}" =~ ^\.+$ ]] && NOT-PINNED`, and the same negative lookahead in `@pin_form`.

### IN-04: An annotated tag that points at another tag reports a misleading MISMATCH

**File:** `bin/verify-action-pins:167-178`
**Issue:** The `git/tags/<sha>` lookup reads only `.object.sha` and never checks `.object.type == "commit"`. A tag-of-tag returns another tag-object SHA, which is reported as `MISMATCH ... resolves to <tag sha>`. It fails closed, but the diagnosis is wrong, and an operator could chase a non-existent impostor commit.
**Fix:** Query `--jq '.object.type+" "+.object.sha'` and report UNVERIFIED (nested annotated tag) when the type is not `commit`, or follow it one more level.

### IN-05: The NODE-FILE rule does not cover composite actions

**File:** `test/threadline/ci_action_pin_contract_test.exs:261-278`
**Issue:** `node_file_errors/2` walks only `jobs.*.steps`. A future `.github/actions/**/action.yml` composite (which the scan already includes, and which Phase 247 is expected to add) could use `actions/setup-node` with `node-version: "22"` and still pass D-10.
**Fix:** Also walk `runs.steps` in the same comprehension, as `parsed_uses/1` already does.

### IN-06: The "flags a quoted ref" runtime control no longer tests Node 20 detection for quoted refs

**File:** `test/threadline/ci_action_runtime_contract_test.exs` (test "flags a quoted ref")
**Issue:** `@pinned_major` cannot match a quoted value, so the quoted `actions/cache@<sha>" # v4.2.0` line now fires `:no_major`, not the Node 20 allowlist miss. The assertion `message =~ "actions/cache@"` passes either way. This is acceptable because PIN-FORM bans quoted refs, but the test name now describes a different rule than the one it exercises.
**Fix:** Rename it to "a quoted ref has no readable major" and assert on "has no `@<40-hex SHA> # vX.Y.Z` pin".

### IN-07: Report truncation can split a multibyte character or an open code fence

**File:** `bin/deps-health-report:439-444`
**Issue:** `head -c "$KEEP"` cuts at a byte offset. The body contains em dashes (tier headings) and fenced output blocks, so a truncated issue body can end inside a UTF-8 sequence or inside an unclosed fence. The rest of the issue then renders as code. Classification is unaffected.
**Fix:** Truncate at the last newline before `KEEP`, and append a closing fence when the kept text has an odd number of fence lines.

---

_Reviewed: 2026-10-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
