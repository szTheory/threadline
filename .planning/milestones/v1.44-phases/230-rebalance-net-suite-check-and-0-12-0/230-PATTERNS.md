# Phase 230: Rebalance, Net-Suite Check and 0.12.0 - Pattern Map

**Mapped:** 2026-10-02
**Files analyzed:** 11 (2 deletions, 3 trims, 1 data file, 1 docs file, 1 human-owned changelog, 2 new evidence/verification docs, 1 release commit/PR)
**Analogs found:** 11 / 11

This phase has **no new product code**. Every target file is an edit, trim,
or deletion of an existing test/doc file, or a new evidence/verification
markdown following an established per-phase shape. "Patterns" here means
"the established shape of this kind of artifact in this repo," not a
component to scaffold.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/threadline/stg_doc_contract_test.exs` (delete whole) | test (doc-contract) | request-response (pure `File.read!`/`String.contains?`) | `test/threadline/v1_23_charter_doc_contract_test.exs` deletion, commit `ba7a7140` | exact (prior whole-file doc-contract deletion) |
| `test/threadline/operator_surface/theme_doc_contract_test.exs` (delete whole) | test (doc-contract) | request-response | same as above | exact |
| `test/threadline/operator_surface_doc_contract_test.exs` (line-item trim) | test (doc-contract) | request-response | itself, pre-trim (261 lines, read in full this session) | exact (self-analog — trim in place) |
| `test/threadline/operator_surface/coverage_doc_contract_test.exs` (line-item trim) | test (doc-contract) | request-response + one live Mix-task JSON round-trip (`Coverage.run(["--json"])` + `Jason.decode!`) | `test/threadline/operator_surface/policy_show_doc_contract_test.exs` (same KEEP shape: live task run via `ExUnit.CaptureIO` + `Jason.decode!`) | exact |
| `test/threadline/operator_surface/policy_show_doc_contract_test.exs` (cut exactly one test) | test (doc-contract) | request-response | itself, pre-trim (209 lines, read in full this session) | exact (self-analog) |
| `test/partition_weights.txt` (remove 2 lines) | config/data | batch (static weight table, `<int> <space> <path>` per line) | itself — no transform, a 2-line deletion at lines 165 and 210 | exact |
| `CONTRIBUTING.md` (new rubric subsection) | config/docs | — | `## Deterministic tests (no flakes)` section (CONTRIBUTING.md:159-261) — prose rule + bullet list + fenced example shape | role-match (same file, sibling section style) |
| `CHANGELOG.md` (`### Breaking changes` entries, confirm Fix lines) | config/docs | — | **Already present and fully matching D-12's three footers** — see Findings below. No new prose needed, only a presence/Fix-line confirmation pass | exact (content pre-exists) |
| `230-EVIDENCE.md` (new) | docs (evidence) | batch (citation table + command transcripts) | `.planning/phases/227-db-backed-property-tests/227-EVIDENCE.md` (SC-5 wall-clock section) + `225-BASELINE.md` (SUITE-01 table shape) | exact |
| `230-VERIFICATION.md` (new) | docs (verification) | batch | `.planning/phases/227-db-backed-property-tests/227-VERIFICATION.md` | exact |
| Squash commit message / PR to `main` | release artifact | event-driven (one-shot land) | `b0668e6d` `feat!: capture every primary-key shape...` (0.11.0, #52) | exact |

## Pattern Assignments

### Whole-file test deletion (`stg_doc_contract_test.exs`, `theme_doc_contract_test.exs`)

**Analog:** commit `ba7a7140` — `test(198-04): triage the red baseline, delete the obsolete charter test, cap skips at zero`

**Deletion mechanics it demonstrates** (commit body, read this session):
```
git rm test/threadline/v1_23_charter_doc_contract_test.exs (D-06, obsolete),
with the recorded admission that coverage was dropped and no successor guard
exists. Also dropped from the verify.doc_contract alias, and
ci_topology_contract_test.exs flipped assert -> refute for that path.
```

**Apply to this phase as:**
1. `git rm test/threadline/stg_doc_contract_test.exs test/threadline/operator_surface/theme_doc_contract_test.exs`.
2. Confirmed this session: **no alias, no `ci_topology_contract_test.exs` entry, and no other `.ex`/`.exs` references these two filenames** (only `test/partition_weights.txt` lines 165/210 and a `# House style mirrors ... theme_doc_contract_test.exs` *comment* in `test/threadline/brandbook_token_parity_test.exs` — comment-only, no assertion, does not need updating but is worth a human-readable fix-up if the planner wants zero stale references). So this deletion is simpler than the 198-04 precedent — no alias/roster flip needed, only the partition-weight line removal (see below).
3. Remove `test/partition_weights.txt:165` (`1 test/threadline/operator_surface/theme_doc_contract_test.exs`) and `:210` (`0 test/threadline/stg_doc_contract_test.exs`) — confirmed exact line numbers live this session.
4. Re-run `find test \( -name '*doc_contract_test.exs' -o -name '*readme_contract_test.exs' \) | wc -l` — must read 35 (37 − 2), still above `bin/verify-bump-rehearsal`'s 30-file floor (line ~437, `if [[ "${#DC_FILES[@]}" -lt 30 ]]`).

### Line-item trim, self-analog (`operator_surface_doc_contract_test.exs`)

**Analog:** the file itself, pre-trim (full file read this session, 261 lines).

**Structural pattern:** one `describe`-free flat list of `test "..."` blocks, each independently reading `guides/operator-surface.md` or `README.md` via `File.read!/1` then `String.contains?/2`/`refute`. There is exactly **one** derived assertion in the whole file — everything else is prose-to-prose.

**KEEP excerpt** (lines 55-68) — the only Pins-derived assertion, trim its prose siblings but keep this block intact:
```elixir
test "operator surface guide links the canonical upgrade-path guide and stays scoped" do
  guide = File.read!("guides/operator-surface.md")

  assert String.contains?(guide, "[upgrade\npath](upgrade-path.md)")
  assert String.contains?(guide, "[integration contracts](integration-contracts.md)")
  # Derived from `mix release.pins`, the designated sole writer of every
  # documented install pin, rather than hardcoded. A literal here goes red the
  # moment that writer does its job at a version bump — the born-red shape
  # Plan 202-09 removed from release_artifact_contract_test.exs (which carries
  # the full rationale) and the bump rehearsal found four more copies of.
  assert String.contains?(
           guide,
           ~s({:threadline, "~> #{Pins.target_pin_version()}"})
         )

  refute String.contains?(guide, "{:threadline, \"~> 0.5\"}")
  ...
end
```
Per D-02, trim this test down to just the `Pins.target_pin_version()` assertion (and its own prose-literal siblings inside the *same* test body are themselves prose-pinned — re-confirm against B.1 before deciding whether to keep the surrounding `refute`s, which pin *removed* legacy strings and may independently qualify as structural/security-adjacent "don't regress a stripped example" guards; if uncertain, the safe D-01 reading is CUT the bare `assert String.contains?` siblings, KEEP only the derived line and any `refute` that guards against a literal regression of a since-removed real example).

**CUT-shaped excerpt** (lines 7-16, README prose pair — same shape repeats through lines 233-260):
```elixir
test "README routes the operator surface mount macro to its canonical owner" do
  readme = File.read!("README.md")
  assert String.contains?(readme, "threadline_operator_surface")
end

test "README documents fail-closed posture and links guide" do
  readme = File.read!("README.md")
  assert String.contains?(readme, "fail-closed")
  assert String.contains?(readme, "guides/operator-surface.md")
end
```
The second one is a candidate for the **security-boundary exception** named in
D-02 ("keep any assertion that pins an auth/fail-closed/export-auth security
boundary sentence") — it is the only place in this file that pins the literal
word `"fail-closed"` against README prose. Record the keep/cut call with a
one-line reason either way, per D-02's instruction.

### Line-item trim with a live KEEP core (`coverage_doc_contract_test.exs`)

**Analog:** `test/threadline/operator_surface/policy_show_doc_contract_test.exs` (KEEP-shaped JSON round-trip) and RESEARCH.md's own line-range inventory for this file (already independently re-verified this session per `230-RESEARCH.md` lines 112-116 — do not re-derive, just execute).

**KEEP excerpt pattern** (the live Mix-task JSON contract, shared shape across both files):
```elixir
# coverage_doc_contract_test.exs ~323-359 (per RESEARCH.md)
output = capture_io(fn -> Coverage.run(["--json"]) end)
decoded = Jason.decode!(output)
# ... asserts against the live decoded map, not a doc string
```
```elixir
# policy_show_doc_contract_test.exs ~100-130 (same shape)
output = capture_io(fn -> Show.run(["--json"]) end)
decoded = Jason.decode!(output)
```
Both call the real Mix task via `ExUnit.CaptureIO.capture_io/1` then
`Jason.decode!/1` the output — this is the canonical "derived from a real
Mix task run" KEEP pattern (B.1 criterion 1). Keep both, verbatim.

**CUT-shaped excerpt** (`coverage_doc_contract_test.exs` ~164-192, guide-prose pair, same shape as the operator_surface file above):
```elixir
test "operator guide documents selected-schema readiness..." do
  guide = File.read!("guides/operator-surface.md")
  assert String.contains?(guide, "...")
end
```

### Line-item trim, single-test cut (`policy_show_doc_contract_test.exs`)

**Analog:** itself, pre-trim (full file read this session, 209 lines).

**The one CUT test** (lines 76-88, read live this session):
```elixir
test "domain reference documents policy.show --schema as host schema, not storage schema" do
  src = File.read!(@domain_reference_path)

  for literal <- [
        "mix threadline.policy.show --schema=NAME",
        "mix threadline.policy.show --schema=support",
        "`--schema=NAME` selects the audited host schema",
        "does not change Threadline's storage schema"
      ] do
    assert String.contains?(src, literal),
           "expected #{@domain_reference_path} to document #{inspect(literal)}"
  end
end
```
This is the full body to delete — every other `describe` block in this file
reads live source (`@router_path`, `@live_view_path`, `@mix_task_path`,
`@presenter_path`) or calls `Show.run(["--json"])`, and stays untouched.
`@domain_reference_path` (line 20) becomes unused after this deletion —
remove that module attribute too, or `mix compile --warnings-as-errors`
fails on the unused-attribute warning.

### `test/partition_weights.txt` edit

**Analog:** itself. Format confirmed live this session: `<int weight><TAB or space>test/path.exs` per line, 1-indexed by line number matching `grep -n` output.

**Exact edits:**
- Delete line 165: `1	test/threadline/operator_surface/theme_doc_contract_test.exs`
- Delete line 210: `0	test/threadline/stg_doc_contract_test.exs`
- Leave lines 124 (`coverage_doc_contract_test.exs`, weight 7), 146 (`policy_show_doc_contract_test.exs`, weight 2), and 171 (`operator_surface_doc_contract_test.exs`, weight 1) **untouched** — these files are trimmed, not deleted, and CONTRIBUTING.md's own documented contract is that a stale weight only costs partition balance, never correctness (no re-run of `--write-weights` required).

### CONTRIBUTING.md rubric section (D-04)

**Analog:** `## Deterministic tests (no flakes)` (CONTRIBUTING.md:159-261) — this is the established "rule + bullet list + example" shape in this file for a testing-discipline section.

**Shape to copy** (opening framing + "Rules of thumb" bullet-list pattern, lines 159-163 and 199-201 as the template skeleton):
```markdown
## Deterministic tests (no flakes)

Tests must be deterministic — a green run must mean the code is correct, not that
the dice landed well. ...

**Rules of thumb:**

- **Never `Process.sleep` to wait for a condition.** Use ...
```

**Apply to D-04 as:** a new subsection (discretion: planner may nest it under
"Deterministic tests" or make it a sibling `## Writing a doc-contract or
guard test` section — RESEARCH.md recommends a subsection of "Deterministic
tests"). Content is fully locked by D-04's prose: state KEEP criteria 1-3
and the CUT shape, plus the one new convention (every new
`*_contract_test.exs` moduledoc names, in one sentence, which KEEP criterion
it satisfies). Follow `policy_show_doc_contract_test.exs`'s own moduledoc
(lines 2-8, quoted above) as the concrete example of "a moduledoc that names
what it locks" to cite inline if an example is useful.

### CHANGELOG.md — already satisfies D-11/D-12 verbatim

**Finding (not a gap to fill):** `CHANGELOG.md`'s `## Unreleased — highlights`
→ `### Breaking changes` section (read live this session, lines 24-45)
**already contains all three D-12 breaking-change entries**, each with an
explicit "Fix:" sentence, matching D-12's footer list content word-for-word
in substance (operator-surface telemetry actor-ref strip; health-checked
metadata shape change; non-list `exclude:`/`mask:`/`except_columns:` raising
`ArgumentError`). This phase's CHANGELOG action is **verification, not
authorship**:
1. Confirm all three entries are present (they are, as of this session).
2. Confirm each has a concrete "Fix:" line (they do).
3. Run `mix test test/threadline/changelog_contract_test.exs` green.
4. D-13 needs no separate upgrade guide — already satisfied by the inline Fix lines.

No new CHANGELOG prose-writing pattern is needed; this is a confirm-and-cite step.

### Evidence/Verification docs (`230-EVIDENCE.md`, `230-VERIFICATION.md`)

**Analogs:** `.planning/phases/227-db-backed-property-tests/227-EVIDENCE.md` and `227-VERIFICATION.md`; `.planning/phases/225-suite-baseline-and-partitioned-ci/225-BASELINE.md` for the SUITE-01 table shape.

**CI timing citation shape to copy** (227-EVIDENCE.md, read this session):
```text
python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py <run_id> --cache-state

## run <run_id>

| Lane | Job seconds | Proxy (min) | Run tests seconds | Build cache |
|---|---|---|---|---|
| min | ... | ... | ... | hit |
| current | ... | ... | ... | hit |
| latest | ... | ... | ... | hit |
| **total** | | **N** | |
```
Reused for every phase's before/after pair since 225; D-06/D-09 require the
same shape for 230's own fresh run plus the assembled 224-230 table.

**`--compare` two-after-run pitfall, already solved by precedent** (227-EVIDENCE.md):
```text
python3 .../ci-job-timing.py --compare <before> <after> exits 1:
"INSUFFICIENT (need at least 2 after runs)". ... the before/after table below
comes from two single-run invocations instead.
```
Copy this exact fallback framing verbatim — D-06 only needs one fresh run.

**Maintainer-grant citation shape** (227-EVIDENCE.md "### CI" section, read this session):
```text
The maintainer granted, in their own words, `git push origin milestone/v1.44`
(incl. follow-ups), `gh workflow run ci.yml --ref milestone/v1.44`, ...
("yes i grant it i authorize u", 2026-10-01); the push and both dispatches
below were carried out under that grant.
```
Copy this pattern for D-17's grant citation in the release plan's evidence —
name every verb, quote the maintainer's own words, date it.

**VERIFICATION.md frontmatter + structure** (227-VERIFICATION.md, read this session):
```yaml
---
phase: 227-db-backed-property-tests
verified: 2026-10-01T00:00:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---
```
followed by `## Goal Achievement` → `### Observable Truths` table (one row
per ROADMAP SC) → `### Required Artifacts` → `### Key Link Verification` →
`### Behavioral Spot-Checks` → `### Requirements Coverage` → `### Anti-Patterns Found`.
Copy this section order and table shape for `230-VERIFICATION.md`, with rows
keyed to this phase's own SC1-SC4 (rebalance / net-suite / release / close-vs-land
ordering) instead of 227's SC1-SC5.

### Release squash commit (REL-01, D-11/D-12)

**Analog:** `b0668e6d` — `feat!: capture every primary-key shape, read it back exactly, and detect broken capture (#52)` (0.11.0 precedent, the only prior `feat!:` landing in this repo).

**Shape to copy:**
```
feat!: <one-line, adopter-benefit-framed subject, no removal list>

<one-paragraph user-facing summary of what ships>

BREAKING CHANGE: <break 1>
BREAKING CHANGE: <break 2>
BREAKING CHANGE: <break 3>

See CHANGELOG.md for upgrade steps.
```
D-12 gives the exact subject-candidate and all three footer lines verbatim
(`230-CONTEXT.md` D-12, reproduced in `230-RESEARCH.md`'s "Release Mechanics"
section) — copy those footer lines unedited; only the subject wording is
discretionary (tighten within D-12's shape/length).

## Shared Patterns

### "Governed absence" citation discipline
**Source:** `230-RESEARCH.md` lines 117-136 (D-05 cross-check finding)
**Apply to:** `230-EVIDENCE.md` whenever citing a cross-check that returns
zero hits — state the grep command, the zero-hit result, and explicitly that
absence-of-mention is not proof-of-absence, exactly as RESEARCH.md phrases
it. Do not write `"X confirms a mutation control for file Y"` unless a
targeted search actually finds one.

### "Local figures are noisy context, CI is the gate" framing
**Source:** every phase 224-229's evidence doc; verbatim caveat text quoted
in `230-RESEARCH.md`'s Suite-Time Comparator Mechanics section:
```
this machine's own documented load-noise floor is on an order of magnitude
larger than the head-vs-base gap recorded above, so this local whole-suite
figure is read as within the documented noise floor, not as a per-test
regression or improvement in either direction
```
**Apply to:** `230-EVIDENCE.md`'s local-triple-median section (D-08).

### No-new-tooling discipline
**Source:** `230-RESEARCH.md` "Don't Hand-Roll" table.
**Apply to:** every plan in this phase — reuse `ci-job-timing.py`,
`ci_topology_contract_test.exs`'s own roster test, and
`bin/ci-test-partitions`; do not write new scripts for the `ci-required`
diff, the pin re-check, or the ID-leak scan (a one-off `grep -rniE` sweep is
the right shape, not a new contract test, per Pitfall 4 in RESEARCH.md).

## No Analog Found

None. Every artifact in this phase has a direct, same-repo analog — this
phase is pure rebalancing/landing work against an already-mature pattern
set from phases 224-229.

## Metadata

**Analog search scope:** `test/threadline/`, `test/threadline/operator_surface/`,
`.planning/phases/225-*` through `229-*`, `CONTRIBUTING.md`, `CHANGELOG.md`,
`test/partition_weights.txt`, git log for whole-file test deletions and prior
`feat!:` commits.
**Files scanned:** ~15 (5 test files in full or targeted ranges, 2 evidence
docs in full, 1 verification doc, CONTRIBUTING.md 2 sections, CHANGELOG.md
head, partition_weights.txt grep, 2 git-log commits inspected)
**Pattern extraction date:** 2026-10-02
