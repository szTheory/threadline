# Phase 246: Debt closeout and critic retirement - Pattern Map

**Mapped:** 2026-10-25 (HEAD `690523d6`, branch `milestone/v1.47`)
**Files analyzed:** 13 new-shape files/edits (plus the deletion set, grouped by commit below)
**Analogs found:** 13 / 13 (every analog verified git-tracked with `git ls-files`)

This phase is mostly deletions plus contract edits. RESEARCH.md §Anchor verification, §Contract coupling graph and §Per-subsystem edit details already pin every edit site by file:line; this map does not repeat them. It covers only the files that are new or take a new shape, and gives each one a concrete analog to copy.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/246-debt-closeout-and-critic-retirement/246-DEBT-REGISTER.md` | planning ledger | batch (dispositions) | `.planning/milestones/v1.40-phases/197-coverage-growth-adversarial-closeout-design-debt-register/197-DESIGN-DEBT-REGISTER.md` (+ `193-RISK-REGISTER.md` frontmatter) | exact (shape), columns differ |
| `.planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh` (`--close`) | utility / gate script | batch, read-only | `.planning/milestones/v1.43-phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh` | exact |
| `test/threadline/<retired_pointer>_doc_contract_test.exs` (replaces `critic_iteration_runbook_doc_contract_test.exs`) | test (doc contract) | file-I/O, transform | `test/threadline/critic_iteration_runbook_doc_contract_test.exs` | exact (same file slot) |
| `CONTRIBUTING.md` "Retired" pointer (replaces :285-556) | doc | n/a | the headings it replaces (`## Local-only critic …` :285, `## Forward-only gate …` :483) | role-match |
| `CONTRIBUTING.md` "Removed CI proofs" new bullet + intro amendment (:857-868) | doc | n/a | existing bullets `CONTRIBUTING.md:865-868` | exact |
| `test/threadline/ci_topology_contract_test.exs` removed-proofs rewrite (:1261-1455) | test (contract) | transform + mutation controls | same block, `removed_job_checks/2` :1315-1332 | exact |
| `.github/workflows/ci.yml` `# Removed: verify-capture` comment | config | n/a | `ci.yml:53-63`, `:842-845` | exact |
| `test/threadline/ci_topology_contract_test.exs:674-695` resurrection-guard reword | test (contract) | file-I/O | itself | exact |
| `.planning/ARCHIVE-REGISTER.md` new row | planning ledger | append | row `ARCHIVE-REGISTER.md:25` (`gsd/phase-166-…`) | exact |
| `archive/ui-critic-loop` annotated-tag message | git metadata | n/a | `git cat-file -p archive/backup/pre-release-cleanup-2026-05-08` | exact |
| `.planning/seeds/SEED-008-operator-ui-carry.md` (new) + `SEED-005` frontmatter rewrite | planning seed | n/a | `.planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md:1-23,72-89` | exact |
| `test/threadline/deps_health_doc_contract_test.exs` WR-04 / WR-05 / IN-03 | test (contract) | file-I/O + negative control | `ci_topology_contract_test.exs:1632-1665` (ruleset parse + in-memory mutation control); `deps_health_doc_contract_test.exs:60-67` (`canonical_dir_line!/1`) | exact |
| `test/threadline/repo_hygiene_contract_test.exs`, `changelog_contract_test.exs` (223 IN-01) | test (contract) | file-I/O | `critic_iteration_runbook_doc_contract_test.exs:10-19` (`String.contains?` over a file read); `changelog_contract_test.exs:57` `read!/1` helper | role-match |

## Pattern Assignments

### `246-DEBT-REGISTER.md` (planning ledger, batch)

**Analog:** `197-DESIGN-DEBT-REGISTER.md` (89 lines), frontmatter style from `193-RISK-REGISTER.md:1-16`.

**Frontmatter pattern** (197 lines 1-15). Copy the keys and add disposition counts (D-15):
```yaml
---
phase: 197-coverage-growth-adversarial-closeout-design-debt-register
artifact: 197-DESIGN-DEBT-REGISTER.md
milestone: v1.40
clause: PROOF-04 (ranked residual design-debt register, ...)
generated: 2026-08-27
source_precedence:
  - runtime/source proof (...)
  - release/package truth
  - CI/gates
  - planning/residual history (...)
seed: ...
status: complete
---
```
For 246, use: `phase`, `artifact`, `milestone: v1.47`, `clause: DEBT-01 (...)`, `generated`, `seed: .planning/research/QUALITY-ROADMAP-2026-10-24.md §Carried-debt register + 246-CONTEXT D-00a..e`, `verified_against: <HEAD sha>`, then `counts: {closed: N, waived: N, routed: N, total: N}` and `status: complete`. The close check (check 1) parses these counts, so keep them flat and one key per line, e.g. `closed: 41`, so a `grep '^  closed:'`/python parse is trivial.

**Body pattern** (197 lines 17-44): an H1, a one-paragraph clause statement, an "all N seed items accounted for (none silently dropped)" sentence, then `## Verdict`. Copy that structure.

**Table pattern** (197 lines 55-68): one pipe table, bold ID cell, closed rows carry the closing commit inline (`**CLOSED 294a0baf**`). For 246, replace the columns with the D-15 set:
```
| id | item | source file | evidence (file:line or commit) | disposition | reason or route |
```
- `id`: `215-WR-04`, `223-IN-01`, `216-IN-03`, `218-WR-03`, `ECON-03`, ... and `W1`..`W64` for WINDOWS rows. Give each W row an HTML anchor so `246-DEBT-REGISTER.md#W7` (the waive-reason citation, D-20) resolves: put `<a id="W7"></a>W7` in the id cell.
- `disposition`: exactly `closed`, `waived` or `routed`. No bold, no extra words, because the close check matches the cell literally.
- `reason or route`: routed rows must name `v1.48`/`v1.49`/`v1.50`/`v1.51` or `SEED-008` (close-check regex `v1\.(48|49|50|51)\b|SEED-[0-9]{3}`).

**Closing sections** (197 lines 70-89): copy the "No polish-later bucket exists." paragraph and the `## Boundary Check` list (which files the plan's commits touch; nothing else).

**Hygiene:** no home-path shapes or username anywhere in the file (repo-hygiene guard scans tracked `.planning/`).

---

### `tools/verify-phase.sh --close` (gate script, read-only)

**Analog:** `.planning/milestones/v1.43-phases/222-seed-006-change-aware-lanes-conditional/tools/verify-phase.sh` (275 lines).

**Header + root resolution** (lines 1-19). Copy verbatim, but do NOT copy line 21's literal `P=.planning/phases/222-…`: it broke when the phase was archived. Derive it:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$ROOT"
P="$(cd "$SCRIPT_DIR/.." && pwd)"   # 246 change: survives archival to milestones/
P="${P#"$ROOT"/}"                    # keep it repo-relative for messages
```

**Mode parsing** (lines 26-35):
```bash
MODE="${1:-}"
case "$MODE" in
  "" | "--close")
    ;;
  *)
    echo "verify-phase: unknown argument: $MODE" >&2
    echo "usage: verify-phase.sh (default measurement gate; 222-02 adds --close)" >&2
    exit 64
    ;;
esac
```

**Scratch + helpers** (lines 37-65): copy `OUT`/`HITS` mktemp + `trap 'rm -f "$OUT" "$HITS"' EXIT`, and the `pass`/`fail`/`run`/`run_out_contains` helpers unchanged.

**Seed frontmatter check** (lines 215-228), the model for check 7 (SEED-005/SEED-008):
```bash
if grep -qx "status: closed" "$SEED" \
   && grep -qF "decision: $P/222-DECISION.md" "$SEED" \
   && grep -q "^reopen_when:" "$SEED" \
   && [ "$(grep -c '^trigger_when:' "$SEED")" -eq 0 ]; then
  pass "SEED-006 has status: closed, ..."
else
  { echo "status:"; grep '^status:' "$SEED" || true; ... } >"$OUT"
  fail "SEED-006 has status: closed, ..."
fi
```

**Machine-path grep, fail closed on exit 2** (lines 170-186). Copy the `MACHINE_PATH` regex from line 171 of the 222 script itself (do not retype it in prose), extend the alternation at runtime with `$(id -un)` for the username (never a literal), and keep the `set +e` / `GREP_STATUS` / `[ "$GREP_STATUS" -le 1 ] || fail …` shape exactly.

**Count checks** (lines 239-246, `grep -cF … || true` then compare). Use this for the WINDOWS `open_count: 0` frontmatter line and for the register's per-disposition counts vs frontmatter.

**New checks without a 222 analog** (write them in `python3 -I`, either inline in the script or as a sibling `tools/register-check.py` called through `run`): parse the WINDOWS ```` ```json ```` block (status == "open" count is 0), parse the register table (disposition set, blank-reason rows, routed-row regex, W-id set == the 60 D-20 ids, literal non-W id list), the refined D-09 grep ⊆ literal allowlist, and the partition-weights row-existence line from RESEARCH §Validation. End with `echo "verify-phase: all checks passed"` (line 275).

**No default mode needed beyond the generic checks:** 246 has no measurement gate, so the default mode can run the hygiene + register-shape checks and `--close` adds WINDOWS/seed/grep checks; or both modes run everything. Keep the `exit 64` usage error.

---

### Retired-pointer doc contract (test, replaces `critic_iteration_runbook_doc_contract_test.exs`)

**Analog:** `test/threadline/critic_iteration_runbook_doc_contract_test.exs` (81 lines). Replacing it in place keeps the doc-contract file count at 37 (floor 30, `bin/verify-bump-rehearsal:556-557`); the filename must still end `doc_contract_test.exs`.

**Module + file read pattern** (lines 1-10):
```elixir
defmodule Threadline.CriticIterationRunbookDocContractTest do
  @moduledoc """
  Pins the CONTRIBUTING.md "..." maintainer runbook so ...
  """
  use ExUnit.Case, async: true

  @contributing File.read!("CONTRIBUTING.md")
```

**Assertion pattern** (lines 12-19, 51-57): `assert String.contains?(@contributing, "<heading>")` plus `refute String.contains?(…)` for stale text with a failure message.

**Leak-guard pattern** (lines 68-80), keep and adapt (no critic runbook reaches `guides/`):
```elixir
for guide <- Path.wildcard("guides/**/*.md") do
  body = File.read!(guide)
  refute String.contains?(body, "critic:gate"), "#{guide} leaks ..."
end
```

**New assertions:** the pointer heading exists; it names `` `archive/ui-critic-loop` ``; the retired headings (`## Local-only critic (verify.ui_critique)`, `## Forward-only gate — run one iteration`) are gone; no `npm run critic:`/`mix verify.mechanical` command survives in CONTRIBUTING. Add the new file path to the D-09 exemption list in the close check (it necessarily contains the word "critic").

---

### CONTRIBUTING "Retired" pointer (doc)

Replace `CONTRIBUTING.md:285-556` (headings at :285, :311, :483 and their subsections) with one short H2 section, ending just before `## CI Coverage` (:557). Suggested shape (wording is Claude's discretion, D-08):
```markdown
## Retired: UI critic loop

The LLM UI critic, its mechanical floor and Tier-A capture were retired in v1.47 (Phase 246, DEBT-02).
Restore from the annotated tag `archive/ui-critic-loop`; `git cat-file -p archive/ui-critic-loop` prints the restore recipe.
```
The heading level must be `##` so the existing `removed_proof_bullets/1`-style section splitters elsewhere are unaffected.

---

### CONTRIBUTING "Removed CI proofs" bullet (doc) + `ci.yml` `# Removed:` comment (config)

**Analog bullets:** `CONTRIBUTING.md:865-868`. The shape the contract enforces (`ci_topology_contract_test.exs:1285-1289`, `:1367-1373`): a line starting `` - `<job-id>` ``, containing `still caught by`, naming the triggers.
```markdown
- `verify-docs`: failure class "the ExDoc build fails" is still caught by `verify-bump-rehearsal`, whose `mix verify.release` gate runs ..., on pull_request, push to `main` and workflow_dispatch. ...
```
New bullet for 246 (D-02): `` - `verify-capture`: failure class "…" is still caught by `style_contract_test.exs` (contrast and token checks) and `operator-accessibility.spec.ts` in `verify-example-browser` (accessibility), on pull_request, push to `main` and workflow_dispatch. Byte-stable stress-lab regeneration is retired, not replaced: a recorded coverage cut (DEBT-02, UI parked until 1.0.0). `` Delete the `:865` capture-lane-step bullet and restate the `:866` `verify-mechanical` bullet (its `mechanical_checker_test.exs` target is deleted). Amend the intro `:859-863` to admit a deliberate, recorded coverage cut.

**Analog comment:** `ci.yml:53-56`:
```yaml
  # Removed: verify-docs (plain `mix docs`). Failure class "the ExDoc build fails"
  # is still caught by verify-bump-rehearsal, whose `mix verify.release` gate runs
  # `MIX_ENV=dev mix docs --warnings-as-errors`, on push to main, pull_request and
  # workflow_dispatch. A change that skips verify-bump-rehearsal skips this proof too.
```
Put `# Removed: verify-capture (...)` where the job was (replacing `ci.yml:842-851`, which also holds the `verify-mechanical` comment that must be restated).

---

### `ci_topology_contract_test.exs` removed-proofs rewrite (test, mutation controls)

**Analog:** the same block, `:1261-1455`. Keep the generic machinery and drop the capture-specific half.

**Keep unchanged:** `@removed_proofs_heading` (:1266), `removed_proof_bullets/1` (:1271-1283), `justified_removal?/2` (:1285-1289), `header_roster/1` (:1305-1310), `removed_job_checks/2` (:1315-1332), `removed_job_bullet/2` (:1367-1373).

**Change:** `@removed_job_ids` (:1269) → `["verify-mechanical", "verify-docs", "verify-hex-package", "verify-capture"]`; then `removed_job_checks/2` automatically requires the id absent from job keys, header roster and `ci-required` needs, a `# Removed: verify-capture` comment and a CONTRIBUTING bullet.

**Delete:** `@byte_stable_step` (:1267), `@mechanical_checker_test` (:1268), the `checker_test` parameter, the `capture`/byte-stable/`excluded_tags_in_checker` tuples in `removed_proof_errors` (:1335-1354, :1358-1360), the `yaml_controls` loop (:1382-1409), the `capture` bullet control and the `excluded_checker` control (:1443-1454). `default_excluded_tag_names/0` (:1293-1303) may become unused; delete it only if nothing else calls it (`--warnings-as-errors`).

**Mutation-control pattern to keep** (:1411-1441). Each control mutates an in-memory copy, asserts the copy differs, then asserts the contract fails:
```elixir
for {label, bullet} <- [
      {"verify-docs", removed_job_bullet(contributing, "`verify-docs`")},
      ...
    ] do
  assert is_binary(bullet), "the #{label} bullet must exist to mutate"
  contributing_without_bullet = String.replace(contributing, bullet <> "\n", "")
  refute contributing_without_bullet == contributing
  refute removed_proof_errors(yaml, contributing_without_bullet) == [],
         "dropping the #{label} bullet must make the removed-proof contract fail"
end
```
Add `{"verify-capture", removed_job_bullet(contributing, "`verify-capture`")}` to that list.

**Resurrection guard reword** (:674-695): keep the test body (the `"ANTHROPIC" <> "_API_KEY"` needle, the non-empty-glob guard). Reword the name and messages from "paid critic lane" to the retired loop, e.g. `test "no workflow references a paid LLM API key (GREEN-09 resurrection guard; retired UI loop, tag archive/ui-critic-loop)"`. This is a listed D-09 exemption.

---

### `ARCHIVE-REGISTER.md` row + `archive/ui-critic-loop` tag message

**Row analog:** `ARCHIVE-REGISTER.md:25` (the `gsd/phase-166-…` row: real work preserved, not an ancestor-only provenance tag). Columns (`:23`): `| ref | SHA | date | reason | recommendation | restore command |`. 246 row: ref `` `archive/ui-critic-loop` `` (a tag pinning a main commit, not a branch: say so in reason), SHA = parent of the removal squash on main, reason cites DEBT-02 / D-4, recommendation **Archive (retired, restorable)**, restore command `` `git revert <removal-squash-sha>` `` with the fallback in the tag. Then update the `**Rows: 11.**` count (:46) to 12. The `<!-- archive-subject: … -->` comment lines (:28 etc.) belong to the 198 round-11 tooling; do not add one unless that tooling is re-run.

**Tag message analog:** `git cat-file -p archive/backup/pre-release-cleanup-2026-05-08`:
```
archive: backup/pre-release-cleanup-2026-05-08 (GREEN-12)

Archived branch: backup/pre-release-cleanup-2026-05-08
SHA (tip): 50374eb7...
base (merge-base with main): 50374eb7...
ancestry verification: `git merge-base --is-ancestor <branch> main` exited 0
  => ...
archive date: 2026-08-27
requirement: GREEN-12 (Phase 198, Plan 198-06, Task 1; decisions D-31/D-33/D-34)

diffstat (git diff --stat main...50374eb7):
  (empty - ...)

recommendation: ARCHIVE as provenance, not preservation.

rationale: ...

restore command:
  git branch backup/pre-release-cleanup-2026-05-08 50374eb7...
  (inspect without restoring: git show archive/...)

register: see .planning/ARCHIVE-REGISTER.md
```
246 adaptation: subject `archive: ui-critic-loop (DEBT-02 / D-4)`; `Archived state: main before <removal-squash-sha>`; `SHA:` the parent; ancestry line = `git merge-base --is-ancestor archive/ui-critic-loop origin/main` exited 0; `diffstat (git diff --stat <parent> <removal-squash-sha>)`; `restore command:` primary `git revert <removal-squash-sha>`, fallback `git checkout archive/ui-critic-loop -- <full path list>` plus the hand-restored `mix.exs` aliases. Write the message to a scratchpad file and pass it with `git tag -a archive/ui-critic-loop -F <file> <sha>`; grep it for home-path shapes and `$(id -un)` before tagging. Landing-time step only (D-12); push with the explicit refspec (D-13).

---

### `SEED-008` (new) and `SEED-005` (frontmatter rewrite)

**Analog:** `SEED-006-ci-feedback-loop-cost-and-latency.md` frontmatter (lines 1-23):
```yaml
---
id: SEED-006
status: closed
planted: 2026-09-13
planted_during: v1.41 Phase 201 planning, after Phase 200 closeout
scope: unknown
closed_on: 2026-09-29
closed_during: v1.43 Phase 222
closed_reason: >-
  Measured, not worth it — ...
decision: .planning/phases/222-.../222-DECISION.md
reopen_when: >-
  strict inert share >= 5 of the last 20 merged PRs, ...
---
```
and its `## Outcome` body section (lines 72-89).

**SEED-005** (current frontmatter is freeform: `status: closed (shipped Phase 178; ui/page.ex mounts the banner)`, plus `target_phase: 178`, and a stale `**Status:** Open implementation follow-up` body line at :12). Rewrite to `status: closed`, add `closed_on`, `closed_during: v1.47 Phase 246`, `closed_reason: >-` with the D-21 file:line citations; keep `planted`/`planted_during`/`scope`; replace the body `**Status:**` line and add a short `## Outcome` section in the SEED-006 shape. Close check 7 greps `^status: closed$` (exact line, `grep -qx`), so the value must be bare.

**SEED-008** (open seed). Use SEED-006's open-seed key set: `id: SEED-008`, `status: open` (or `dormant`, matching how SEED-001..003 read; check one before writing), `planted: 2026-10-25`, `planted_during: v1.47 Phase 246`, `scope`, `related: SEED-005`, and `reopen_when: >-` (D-22: maintainer brings UI feedback, or the 1.0.0 UI work opens). Body sections follow SEED-006/SEED-007: `## Why`, `## Scope` listing DR-243-01, typography, Redaction copy (`policy_redaction_live.ex:450-454`), the 8 screenshot-regression baselines (`operator-screenshot-regression.spec.ts:108/:115/:136/:145` × desktop/mobile; WINDOWS 14-17, 62), and the degraded-twin untangling (CONTEXT Deferred).

---

### 215 WR-04 negative control (test)

**Analog:** `ci_topology_contract_test.exs:1632-1665`: ruleset decode, rule lookup, then an in-memory mutation control.
```elixir
ruleset =
  [".github", "rulesets", "main.json"]
  |> read_rel!()
  |> Jason.decode!()

required_status_checks_rule =
  Enum.find(ruleset["rules"], fn rule -> rule["type"] == "required_status_checks" end)

refute is_nil(required_status_checks_rule), "... has no required_status_checks rule at all"

contexts = required_status_checks_rule["parameters"]["required_status_checks"]
...
# In-memory mutation control: stripping the pin must fail the same equality.
stripped = Enum.map(contexts, &Map.delete(&1, "integration_id"))
refute stripped == contexts, "the stripped-id control did not change the input"
refute pinned_required_checks?(stripped), "..."
```
**YAML read analog:** `dependabot_config_contract_test.exs:88` / `ci_token_permissions_contract_test.exs:123`: `YamlElixir.read_from_string!(text, merge_anchors: true)`.

**Apply to** `deps_health_doc_contract_test.exs:381-386` (replace the vacuous `refute ruleset =~ "Dependency Health"`):
1. `job_name = YamlElixir.read_from_string!(deps_health_yaml())["jobs"]["deps-health"]["name"]`; assert it is a non-empty binary (non-vacuity; the file's moduledoc :18-25 already names the "derive source finds NOTHING" failure mode).
2. A pure `defp required_context_hits(ruleset_map, name)` returning contexts equal to `name`; assert `== []` on the live ruleset (`@ruleset` is already defined at :41).
3. Negative control: append `%{"context" => job_name, "integration_id" => 15_368}` to a copy of the contexts list, assert the copy differs, and assert `required_context_hits(...) != []`.

**WR-05** uses the existing `canonical_dir_line!/1` (`deps_health_doc_contract_test.exs:60-67`) against `@verify_deps_audit` (:38) to derive `@lockfiles` (:45); since it reads a file, make it a function (not a module attribute) or call it at compile time knowingly.

**IN-03** deletes the test at `:362-379` ("the deps-health job id appears in no ci-required needs: list"); WR-04's real guard replaces it.

---

### 223 IN-01 wording assertions (tests)

**Pattern:** `String.contains?` over a whole-file read with a failure message (`critic_iteration_runbook_doc_contract_test.exs:12-19`). `repo_hygiene_contract_test.exs` already uses `String.contains?` over files (:124-145, :234); `changelog_contract_test.exs` has a `read!/1` helper at :57 (`@root |> Path.join(relative) |> File.read!()`) to read `CONTRIBUTING.md`. Normalise whitespace first for the D-18 sentence that spans `CONTRIBUTING.md:144-145`: `String.replace(text, ~r/\s+/, " ")`.

## Shared Patterns

### In-memory mutation (negative) controls
**Source:** `ci_topology_contract_test.exs:1404-1441`, `:1657-1665`
**Apply to:** WR-04, the removed-proofs rewrite, every rebuilt browser-full / dialyzer-slice / rendered-output control (RESEARCH §CI contract edits, §Dialyzer re-point, §Fixture prune).
Always three steps: mutate a copy, `refute mutated == original, "... control did not change the input"`, then assert the checker now fails. A control that compares against the live tree it is about to delete must be rebuilt on a synthetic mutation of copied inputs.

### Fail-closed derivation
**Source:** `deps_health_doc_contract_test.exs:18-25` moduledoc, `:60-67` (`flunk` when the literal is absent); `ci_topology_contract_test.exs:684-686` (empty glob refuted).
**Apply to:** every new contract: a derive step that finds nothing must flunk, never pass vacuously.

### Live-tree contracts move with their files
**Source:** RESEARCH §Contract coupling graph.
**Apply to:** C1-C4. Each deletion commit carries its reference edits; `exclude_patterns` leave with their files (D-06).

### Planning-prose hygiene
**Source:** 222 `verify-phase.sh:170-186`; `bin/verify-repo-hygiene`.
**Apply to:** the register, both seeds, the ARCHIVE row, the tag message, SUMMARY/VERIFICATION prose. Placeholders only; build the username pattern at runtime.

### WINDOWS writes
**Source:** RESEARCH §WINDOWS mechanics (`broken-windows.cjs`).
**Apply to:** the single WINDOWS plan: `gsd-tools.cjs windows fixed <id>` (the installed gsd-core CLI) (no reason) or `windows waive <id> "<reason starting with a word>"`, one call at a time, routed rows written as `waive` with `routed to v1.48 per 246-DEBT-REGISTER.md#W7`. Never hand-edit; commit WINDOWS.md alone; run last.

## Deletions grouped by commit (no pattern needed)

Order C1 → C2 → C3 → C4 (RESEARCH §Recommended commit plan, which supersedes D-10's order); all `chore:`, contiguous, no non-critic hunks.

**C1: critic-trust tooling + Dialyzer slice**
- `lib/threadline/critic_trust/*`, `lib/mix/tasks/critic.measure.ex`, `lib/mix/tasks/critic.synth.ex`
- `test/threadline/critic_trust/*`, `test/threadline/operator_surface/critic_trust_test.exs`
- `test/fixtures/dialyzer/critic-tooling.json`
- edits: `mix.exs` (`verify.critic_trust`, `verify.ui_critique` aliases + `verify_ui_critique/1`, two exclude lines), guides rows, public_surface / release_artifact / layer_boundary contracts, dialyzer slice + ignore contracts and README, CONTRIBUTING :890, partition rows

**C2: TypeScript critic**
- `examples/threadline_phoenix/e2e/critic/**`, `e2e/critic-before-pole.sh`, `e2e/tsconfig.json`
- `test/threadline/critic_pair_labeling_contract_test.exs`, `critic_shell_safety_contract_test.exs`
- `critic_iteration_runbook_doc_contract_test.exs` → replaced by the retired-pointer doc contract (above)
- edits: `package.json` + regenerated `package-lock.json` (9 packages leave), critic-only fields in `operator-surface-paths{,.test}.ts`, CONTRIBUTING :285-556 → Retired pointer, partition rows

**C3: Tier-A capture, mechanical floor, `verify-capture`**
- `lib/threadline/operator_surface/mechanical_checker.ex`, `mechanical_checker/*`
- `test/threadline/operator_surface/mechanical_checker_test.exs`, `refute_partition_test.exs`
- `e2e/tests/operator-{tier-a,refute,graded,storybook}-capture.spec.ts`
- edits: `playwright.config.ts:25-94`, ci.yml job + roster + needs + `# Removed:` comment, `mix.exs` remaining aliases/preferred_envs/`verify_capture/1`/excludes, all CI contracts, browser-full contract (one-project shape), CONTRIBUTING CI sections + removed-proofs bullet, DESIGN-SYSTEM Capture Matrix, paths fields, `e2e/.gitignore:5-7`, checklist probes, comment-only sites, partition rows

**C4: stress stories + fixture corpus**
- `lib/threadline/operator_surface/live/stress_live/refute.ex`
- `test/fixtures/operator_surface/{scorecards,golden,refute,critic-scores}/`
- edits: `sections.ex`, `stress_live.ex`, `stress_fixtures.ex`, ledger prune, `manifest.sha256` (1 line), fixtures README, fixture/stress_ledger/rendered_output/source_size contracts, `operator_surface_fixtures.ex`, DESIGN-SYSTEM Ratchet Rule + Scorecard Cube

**After C4, outside the squash range:** D-16 fixes (+216 IN-01), the register + close-check script, seeds, QUALITY-ROADMAP appends, live planning wording, hand-fixed disposition rows, then WINDOWS (alone, last), then the D-24 gate.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| close-check register/WINDOWS parsers (inside `verify-phase.sh` or a sibling `tools/*.py`) | utility | transform | 222 has no markdown-table or WINDOWS-JSON parser; use RESEARCH §D-15 checks 1-8 and the `python3 -I` JSON round-trip noted in RESEARCH §Standard Stack |

## Metadata

**Analog search scope:** `.planning/milestones/v1.39-phases/193-*`, `v1.40-phases/197-*`, `v1.43-phases/222-*/tools/`, `.planning/seeds/`, `.planning/ARCHIVE-REGISTER.md`, `test/threadline/*doc_contract_test.exs`, `test/threadline/ci_topology_contract_test.exs`, `deps_health_doc_contract_test.exs`, `.github/workflows/ci.yml`, `CONTRIBUTING.md`, archive tags
**Files scanned:** 14
**Pattern extraction date:** 2026-10-25
