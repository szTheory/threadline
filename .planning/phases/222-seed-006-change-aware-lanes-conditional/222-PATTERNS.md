# Phase 222: SEED-006 Change-Aware Lanes (conditional) - Pattern Map

**Mapped:** 2026-09-29
**Files analyzed:** 11 (new tool copies, 1 new script, 1 decision doc, 5 closure-artifact edits)
**Analogs found:** 11 / 11

This is a planning-artifact / measurement-tooling phase (CLOSE branch expected). No
application or CI code is created; every file is either a phase-local Python/bash tool
(copy-and-extend of an existing generation), a decision-record doc, or a scoped edit to an
existing planning doc. All analog paths below were verified tracked with
`git ls-files -- <path>` before being cited.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `tools/inert-share.py` (+ `inert-allowlist.txt`) | utility (measurement/classifier) | batch/transform (JSON in, report out) | `.planning/phases/214-baseline-measurement/tools/inert-share.py` | exact (byte-copy per D-01) |
| `tools/check-citations.py` | utility (doc lint / citation gate) | batch/transform | `.planning/phases/214-baseline-measurement/tools/check-citations.py` (218's copy shows the retarget diff) | exact (copy, retarget phase-number regex) |
| `tools/collect-ci-runs.sh` | utility (data collection) | file-I/O (network→JSON) | `.planning/phases/219-deps-only-build-cache/tools/collect-ci-runs.sh` | exact (copy, same as 218→219) |
| `tools/summarize-ci.py` | utility (arithmetic library, imported) | transform | `.planning/phases/219-deps-only-build-cache/tools/summarize-ci.py` | exact (copy, unchanged arithmetic) |
| `tools/remeasure-222.py` | utility (new, imports copied summarizer) | transform + CLI subcommands | `.planning/phases/219-deps-only-build-cache/tools/remeasure-219.py` | role-match (same composition pattern, new subcommand: `minute-gate`) |
| `tools/verify-phase.sh` (phase gate) | utility (test runner / gate script) | batch (sequential command orchestration) | `.planning/phases/214-baseline-measurement/tools/verify-phase.sh` | role-match (214's checks are BASE-01/02-specific; write a new script in the same shape, not a literal copy — RESEARCH §4 explicit) |
| `222-DECISION.md` | config/doc (decision record) | request-response (N/A — static doc) | `.planning/phases/220-newest-toolchain-lane/220-SPIKE.md` §Outcome/Cost, plus the *shape* named in 220-04-PLAN.md:123 for `220-FINDINGS.md` (not itself committed — no such file exists in this repo; verified via `find`) | role-match (verdict + cost table + citations shape; no exact `*-FINDINGS.md` precedent is tracked, so 220-SPIKE.md's Outcome/Cost sections plus 214-BASELINE.md's citation style are the real analogs) |
| `.planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md` (frontmatter edit) | config (seed lifecycle metadata) | CRUD (update) | `.planning/seeds/SEED-003-ecosystem-integrations.md` | exact (the only `retired_*`-shaped precedent; D-07 asks for a parallel `closed_*` shape) |
| `.planning/REQUIREMENTS.md` SCOPE-01 line | config/doc (requirement checklist) | CRUD (update) | same file, in place (quoted below) | exact (in-file edit, no external analog needed) |
| `.planning/PROJECT.md` Key Decisions row | config/doc (decision ledger) | CRUD (append row) | `.planning/phases/220-newest-toolchain-lane/220-04-PLAN.md:124` (the row-append instruction) and `.planning/PROJECT.md:42` (the bullet to convert to past tense) | exact (220's row-append precedent, "not yet" shape; 222 mirrors with "closed" shape) |
| `.planning/phases/220-newest-toolchain-lane/220-CONTEXT.md` D-07 (one-line pointer) | doc | CRUD (append, do not rewrite) | same file, in place | exact |

## Pattern Assignments

### `tools/inert-share.py` + `tools/inert-allowlist.txt` (utility, batch/transform)

**Analog:** `.planning/phases/214-baseline-measurement/tools/inert-share.py` (175 lines, read in full this session)

**Path-resolution pattern (lines 34-42)** — copy this unchanged; it self-locates relative to
`__file__`, so a byte-copy into the 222 `tools/` dir automatically resolves `raw/prs/` and the
allowlist to the 222 phase dir with zero edits to this block itself:
```python
TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
PHASE_DIR = os.path.dirname(TOOLS_DIR)
PRS_DIR = os.path.join(PHASE_DIR, "raw", "prs")
ALLOWLIST = os.path.join(TOOLS_DIR, "inert-allowlist.txt")
PROOF_SEP = " # proof: "
WINDOWS = {
    "all": (None, None),
    "30d": ("2026-08-27T00:00:00Z", "2026-09-26T23:59:59Z"),
}
```
**The only edits the copy needs (per D-01 and RESEARCH §1):**
1. Add two more fixed-constant entries to `WINDOWS`: `since-214` and `30d-now`, collected once
   and frozen (never a runtime `--window` argument with live bounds).
2. Update the docstring's example-invocation path strings (lines 4-14) from `214-baseline-measurement`
   to `222-seed-006-change-aware-lanes-conditional`.
3. Nothing else — `is_inert_pr`, `load_allowlist`, `load_prs`, `in_window`, `summarize`,
   `self_test`, `main` are pure functions with no phase-214-specific literals.

**Fail-closed core pattern (lines 65-70)** — copy verbatim, this is the classifier itself:
```python
def is_inert_path(path, globs):
    return any(fnmatch.fnmatchcase(path, g) for g in globs)

def is_inert_pr(files, globs):
    return bool(files) and all(is_inert_path(f, globs) for f in files)
```

**Error handling / fail-closed data validation (lines 49-62, 73-87)** — the allowlist loader
raises `DataError` on any proofless entry; `load_prs` raises on file-count drift against
`changedFiles`. Both preserved automatically by copying `load_allowlist`/`load_prs` unchanged.

**Self-test pattern (lines 117-154)** — copy unchanged; needs no window data, so it is the
cheapest first proof the copy is faithful:
```python
def self_test():
    globs = [".planning/STATE.md", ".planning/seeds/*"]
    cases = [
        ("allowlisted + unknown file is non-inert",
         is_inert_pr([".planning/STATE.md", "lib/threadline.ex"], globs), False),
        ("only allowlisted files is inert",
         is_inert_pr([".planning/STATE.md", ".planning/seeds/SEED-006.md"], globs), True),
        ("empty file list is non-inert", is_inert_pr([], globs), False),
        ("unmatched sibling of an entry is non-inert",
         is_inert_pr([".planning/STATE.md.bak"], globs), False),
    ]
```

**`inert-allowlist.txt`:** copy verbatim (D-01: "the allowlist is not widened"). Each line is
`<fnmatch glob> # proof: <command>` — any new inert-looking path needs its own proof command,
following the same format as the existing entries.

---

### `tools/check-citations.py` (utility, doc citation gate)

**Analog:** `.planning/phases/214-baseline-measurement/tools/check-citations.py`, diffed against
218's copy for the retarget precedent (both `[VERIFIED]` in RESEARCH.md §4).

**Core rule (lines 1-37, quoted in RESEARCH.md §4):** every non-heading, non-blank line outside
a fenced code block that still contains a digit after stripping ISO dates, `p50`/`p95`,
requirement IDs, phase numbers, hex SHAs and version strings must carry either `run <8+ digit
id>` or a backticked command starting with `gh|mix|MIX_ENV=|git|python3|bash|jq|psql|elixir`.

**Retarget pattern (the only edit needed), from 218's precedent:**
```
# 214's original (line 31):
re.compile(r"\b214(?:-0\d)?\b")
# 218's copy widened it to admit itself:
re.compile(r"\b21[4-8](?:-0\d)?\b")
```
**222's copy must widen this further** to admit 222 itself (and every phase between, per the
219 precedent of admitting the full run: 214 through the current phase), e.g.
`re.compile(r"\b21[4-9]|220|221|222(?:-0\d)?\b")` or an equivalent single pattern — otherwise
every line mentioning "Phase 222" or "222-DECISION.md" alongside another digit false-positives
as an uncited figure (RESEARCH.md Pitfall 2).

---

### `tools/collect-ci-runs.sh` and `tools/summarize-ci.py` (utility, data collection + library)

**Analog:** `.planning/phases/219-deps-only-build-cache/tools/collect-ci-runs.sh` and
`summarize-ci.py` — themselves copies of 218's originals, per 219-REMEASURE.md's own description
(quoted in RESEARCH.md §Code Examples): "the phase 218 collector, summarizer and citation
checker, copied into this phase's `tools/` directory ... The copies differ from the 218
originals only in their self-path strings and in the checker's phase-number exemption." Follow
the identical procedure for 222: copy verbatim, retarget only self-path strings.

---

### `tools/remeasure-222.py` (new, imports copied summarizer)

**Analog:** `.planning/phases/219-deps-only-build-cache/tools/remeasure-219.py` (638 lines, read
in full this session) — this is the pattern to *follow*, not copy verbatim, since 219's phase-
specific cache-hit-labeling logic (D-18/D-25) does not apply to 222's minute-gate arithmetic.

**Import-the-copied-summarizer pattern (lines 58-69, 146-148)** — copy this composition shape
exactly; it is the load-bearing idiom that keeps arithmetic in one place:
```python
import importlib.util
...
TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
PHASE_DIR = os.path.dirname(TOOLS_DIR)
...
_spec = importlib.util.spec_from_file_location("summarize_ci", os.path.join(TOOLS_DIR, "summarize-ci.py"))
S = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(S)
```
Then call `S.job_seconds(j)`, `S.billed_minutes(x)`, `S.sort_samples(...)`, `S.pick(s, 50)` etc.
— never reimplement percentile/billed-minute math (RESEARCH.md "Don't Hand-Roll").

**Subcommand dispatch pattern (lines 620-633)** — copy the `argparse` subparser table shape;
222 needs one new subcommand (e.g. `minute-gate --window 30d-now`) alongside whatever else the
plan decides to expose:
```python
def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if argv == ["--self-test"]:
        return self_test()
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="sub", required=True)
    table = {"samples": sub_samples, ...}
    for name in table:
        sp = sub.add_parser(name)
        sp.add_argument("--set", default="all219", choices=SETS)
    args = p.parse_args(argv)
    return table[args.sub](args)
```

**Billed-minutes arithmetic (lines 364-383, `minutes`/`sub_runner_minutes`)** — reuse this
ceil-per-job-then-sum shape for the D-02 part-2 gate's 19-billed-minute-per-skip and window-total
computations:
```python
def minutes(runs):
    u, b = [], []
    for r in runs:
        secs = [S.job_seconds(j) for j in r["jobs"] if S.ran(j)]
        u.append((sum(secs), r["run_id"]))
        b.append((sum(S.billed_minutes(x) for x in secs), r["run_id"]))
    return S.sort_samples(u), S.sort_samples(b)
```

**Self-test pattern (lines 535-617)** — build small synthetic fixture jobs/runs (see `_st`,
`_job`, `_run` helpers, lines 472-532) and assert exact labels/values with a `check(case, got,
want)` accumulator, printing `FAIL <case>: got ..., want ...` and returning 1 on any failure.
`remeasure-222.py`'s self-test should assert the fixed 19-billed-min-per-skip constant and the
ceiling arithmetic independent of live `gh` data (RESEARCH.md §3, final recommendation).

---

### `tools/verify-phase.sh` (phase gate script)

**Analog:** `.planning/phases/214-baseline-measurement/tools/verify-phase.sh` (98 lines, read in
full this session) — write a **new** script in this shape (214's own checks are BASE-01/BASE-02-
specific and don't all apply), reusing the following idioms verbatim:

**Structure and error reporting (lines 1-27):**
```bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
cd "$ROOT"
OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; sed 's/^/  | /' "$OUT"; exit 1; }
run() {
  local label="$1"; shift
  if "$@" >"$OUT" 2>&1; then pass "$label"; else fail "$label"; fi
}
```

**Read-only `gh` guard (lines 71-78)** — copy this exact regex to prove the 222 tools never
call a write-capable `gh` command:
```bash
GH_WRITE='gh (workflow run|run rerun|run cancel|pr create|pr comment|pr merge|issue)|--method|-X (POST|PUT|PATCH|DELETE)'
if grep -nE "$GH_WRITE" $(ls "$T"/*.sh "$T"/*.py | grep -v '/verify-phase\.sh$') >"$OUT" 2>&1; then
  fail "no write-capable gh usage in tools/*.sh and tools/*.py"
else
  pass "no write-capable gh usage in tools/*.sh and tools/*.py"
fi
```

**Machine-path guard (lines 80-96)** — copy this exact regex and fail-closed grep-exit-status
handling for the phase dir's own doc/raw/fixtures, as a useful local pre-check before the
repo-wide `bin/verify-repo-hygiene` runs in `mix ci.all`:
```bash
MACHINE_PATH='/Users/[A-Za-z0-9_]|/home/[a-z]|~/[A-Za-z0-9_.]'
HITS="$(mktemp)"
set +e
grep -rnE "$MACHINE_PATH" "$DOC" "$P/raw" "$T/fixtures" >"$HITS" 2>"$OUT"
GREP_STATUS=$?
set -e
[ "$GREP_STATUS" -le 1 ] || fail "machine-path grep could not read its inputs (exit $GREP_STATUS)"
```

**222's gate should run, in order (RESEARCH.md §4):** `inert-share.py --self-test`, the
214-subset and `30d` reproduction checks, `check-citations.py --self-test`, `check-citations.py
222-DECISION.md`, `remeasure-222.py --self-test` and the minute-gate command, the machine-path
grep, and the `GH_WRITE` grep.

---

### `222-DECISION.md` (decision record)

**Analog:** No tracked `*-FINDINGS.md` file exists in this repo (`find .planning/phases
-iname "*FINDINGS*.md"` returns nothing) — the "220-FINDINGS style" cited in CONTEXT.md D-04 and
the pattern-mapping prompt refers to a file 220-04-PLAN.md *specifies* but that plan's GREEN
branch (which is what actually landed) never created it. Use `220-SPIKE.md`'s `## Outcome` and
`## Cost` sections (read in full this session, 147 lines) plus `214-BASELINE.md`'s citation
convention as the real, tracked analogs:

**Verdict-line pattern** (`220-SPIKE.md:112-116`):
```markdown
## Outcome

GREEN

The newest toolchain passed on its exact pins in run 36484105399: Elixir 1.20.4 / OTP 29.1.1 /
PostgreSQL 18.6 on ubuntu-24.04, with `version-type: strict`. ...
```
222's `222-DECISION.md` should open with an equally terse verdict line (`CLOSE` or `BUILD`,
per D-04), immediately followed by the one-paragraph reason, before any supporting detail.

**Cost/citation table pattern** (`220-SPIKE.md:96-110`) — every number paired with its exact
run ID or command, inline, never a bare percentage:
```markdown
| Job | Duration | Billed min (measured) |
|-----|----------|-----------------------|
| Run test suite (latest), job 109136659729 | 378 s | **7** |
...
- **Estimate:** about +6 billed runner-minutes per run for the latest lane, taking a warm p50 of
  about 49 to about 55 [inference] (D-07, from 219-REMEASURE §2).
```
Note the `[inference]` tag convention for extrapolated (non-directly-measured) figures — reuse
this exact tag for the D-02 part-2 gate's p50-proxy figures if that shortcut is used (RESEARCH.md
Pitfall 3 flags this precision-labeling requirement explicitly).

**214-BASELINE.md §6 citation convention** (cited, not re-read this session — already fully
quoted and verified in RESEARCH.md §2): every collection command is quoted verbatim inline with
its output file, e.g. `gh pr list --repo szTheory/threadline --state merged --base main --limit
500 --json number,title,mergedAt,headRefName,changedFiles`, saved as `raw/prs/index.json` — 222's
decision doc must cite its own fresh-collection commands the same way.

---

### `.planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md` (frontmatter + body edit)

**Analog:** `.planning/seeds/SEED-003-ecosystem-integrations.md` (full file read this session,
59 lines) — the only `retired_*`-shaped precedent in the repo.

**Frontmatter shape to mirror (lines 1-8), with `closed_*` field names per D-07:**
```yaml
---
id: SEED-003
status: retired
planted: 2026-05-08
retired_on: 2026-05-24
retired_during: v1.20 closeout preparation
retired_reason: Kept as strategic direction in milestone arc and product narrative, but not
  maintained as an open implementation seed.
scope: Large
---
```
222's edit becomes (parallel field names, plus a `decision:` field SEED-003 lacks, per D-07):
`status: closed`, `closed_on: <date>`, `closed_during: v1.43 Phase 222`, `closed_reason: <one
line>`, `decision: .planning/phases/222-seed-006-change-aware-lanes-conditional/222-DECISION.md`.

**Current SEED-006 frontmatter being edited (read in full this session, lines 1-12):**
```yaml
---
id: SEED-006
status: dormant
planted: 2026-09-13
planted_during: v1.41 Phase 201 planning, after Phase 200 closeout
trigger_when: when relevant
scope: unknown
audit_acknowledged:
  milestone: v1.41
  at: 2026-09-25
  status: dormant
---
```
**Pitfall (RESEARCH.md Pitfall 4):** do NOT rewrite the nested `audit_acknowledged.status:
dormant` to `closed` — D-07 says "keep `audit_acknowledged`" verbatim; it is a historical record
of what was true at the v1.41 audit, not a field that should track the new top-level status. Add
a one-line note in the seed's own `## Outcome` section explaining the apparent mismatch is
expected, mirroring how 220-SPIKE.md's "Correction to..." paragraph (line 147) explains a
similarly apparent inconsistency inline rather than silently editing the earlier text.

**Body precedent:** SEED-003 keeps its original body and appends a `## Note` section (lines
52-58) explaining the retirement rather than deleting content. D-07 asks for an `## Outcome`
section in the same append-only spirit for SEED-006.

---

### `.planning/REQUIREMENTS.md` SCOPE-01 line (in-place edit)

**Current text (verified this session, lines 112-120):**
```markdown
### Change-aware lanes (conditional)

- [ ] **SCOPE-01**: SEED-006 is decided from measured data. If BASE-01's inert-PR share,
  re-checked after ECON-07 and CACHE-01, is material, build:
  - a `verify-change-scope` job with a table-tested, fail-closed `bin/classify-ci-lanes`
    classifier (anything unknown runs the full matrix);
  - a dynamic `allowed-skips` only for skip-eligible jobs (never `verify-test` or the rehearsal);
  - an empty skip list on push and on dispatch;
  - a `ci-required` step that re-justifies each skip.

  Otherwise record "measured, not worth it" and close the seed.
```
**Edit per D-08:** change `- [ ]` to `- [x]` and append `Outcome: closed, measured, not worth it
(222-DECISION.md: k of n inert)` — a scoped, minimal edit, not a rewrite of the bullet's
conditional prose (the "otherwise" branch is what makes the checked box honest).

---

### `.planning/PROJECT.md` Key Decisions row (append)

**Analog:** `.planning/phases/220-newest-toolchain-lane/220-04-PLAN.md:124` (the exact row-append
instruction for 220's "not yet" outcome) and `.planning/PROJECT.md:42` (the bullet to convert):

**220's row-append pattern, quoted verbatim:**
```
PROJECT.md Key Decisions: add one row via a scoped Edit at the end of the table: `| Newest-toolchain lane (Elixir 1.20.x / OTP 29.x / PG 18): not yet (Phase 220) | <one-clause failure summary>; see phases/220-newest-toolchain-lane/220-FINDINGS.md | ⚠ Not yet: SEED-007 re-triggers; floor and current unchanged |`.
```
**222's equivalent row (RESEARCH.md §8's own recommendation, quoted):**
```
| Change-aware lanes (SEED-006): closed (Phase 222) | <one-clause "measured, not worth it" summary>; see phases/222-seed-006-change-aware-lanes-conditional/222-DECISION.md | ✓ Closed: k of n inert, reopen_when <clause> |
```
Use a scoped `Edit` appending one row — never rewrite the whole table.

**Bullet to convert to past tense** (`.planning/PROJECT.md:42`, quoted verbatim):
```
- SEED-006: change-aware lanes behind a tested fail-closed classifier (last phase, only after the cheap wins are measured)
```

---

### `.planning/phases/220-newest-toolchain-lane/220-CONTEXT.md` D-07 (one-line pointer)

**Current text (verified this session, lines 56-61):**
```markdown
### Spend (HIGH-IMPACT, maintainer-decided)
- **D-07: Latest runs and votes on every `ci.yml` run: PRs, pushes to main, and dispatch.** —
  **Reversibility:** reversible — it is one matrix row; Phase 222 trims it.
  - Expected cost is about +6 billed runner-minutes per run (warm p50 about 49 → about 55), about
    +40 s more on a cold miss. This exceeds 219's saving. Wall clock is unchanged, because the
    critical path is still Browser E2E at about 550 s.
  - Record the cost honestly in the phase record. Do **not** add a conditional `if:` now; it
    would also need `allowed-skips`.
  - Phase 222 (SEED-006 change-aware lanes) is where it gets trimmed.
```
**Edit per D-06:** append exactly one line to this block: "Superseded by 222 D-05: kept
every-run; see 222-DECISION.md." Do NOT rewrite any of the existing D-07 prose above — the
whole point is to leave 220's original decision text intact and append the supersession note.

## Shared Patterns

### Copy-and-retarget (the phase's dominant convention)
**Source:** established by 218 (copying 214's tools), repeated by 219 (copying 218's), now a
third generation for 222. Quoted description (219-REMEASURE.md, `[VERIFIED]` in RESEARCH.md):
```
Tools: the phase 218 collector, summarizer and citation checker, copied into this phase's tools/
directory so that phase 219 runs never land in the 214 or 218 evidence. The copies differ from
the 218 originals only in their self-path strings and in the checker's phase-number exemption,
which now accepts phases 214 through 219.
```
**Apply to:** `inert-share.py`, `check-citations.py`, `collect-ci-runs.sh`, `summarize-ci.py`.
Never edit the source phase's originals; never widen the `inert-allowlist.txt` beyond what a new
proof command justifies.

### Citation discipline
**Source:** `check-citations.py`'s rule (§ above) plus the `[inference]` tag convention from
220-SPIKE.md:107. **Apply to:** every figure in `222-DECISION.md` — pair each number with a
`run <id>` or a backticked reproducible command; tag extrapolated (not directly measured)
figures `[inference]`.

### Append-only edits to existing planning docs
**Source:** SEED-003's `## Note` append (never deletes original body), 220-SPIKE.md's inline
"Correction to..." paragraph (never silently rewrites earlier text), D-06's explicit "Do not
rewrite 220's decision text" instruction. **Apply to:** SEED-006 body, 220-CONTEXT.md D-07,
PROJECT.md Key Decisions table, REQUIREMENTS.md SCOPE-01 line — every closure edit is an
append or a minimal in-place flip (`[ ]`→`[x]`), never a rewrite of surrounding prose.

### Read-only `gh` and no-machine-path gates
**Source:** `verify-phase.sh`'s `GH_WRITE` and `MACHINE_PATH` regexes (quoted above). **Apply
to:** every new tool script under 222's `tools/` dir, and the phase's own gate script.

## No Analog Found

None — every file in this phase's scope has a concrete, tracked analog (see table above). The
one caveat is `222-DECISION.md`, whose named analog (`220-FINDINGS.md`) does not exist as a
tracked file; the substitute analogs (220-SPIKE.md's Outcome/Cost sections, 214-BASELINE.md's
citation style) are both tracked and sufficient.

## Metadata

**Analog search scope:** `.planning/phases/214-baseline-measurement/`,
`.planning/phases/218-ci-economy-remove-waste/` (referenced via RESEARCH.md's verified diff, not
re-read directly), `.planning/phases/219-deps-only-build-cache/`,
`.planning/phases/220-newest-toolchain-lane/`, `.planning/seeds/`, `.planning/REQUIREMENTS.md`,
`.planning/PROJECT.md`.
**Files scanned/read directly this session:** `inert-share.py` (214), `verify-phase.sh` (214),
`remeasure-219.py` (219), `220-SPIKE.md`, `220-04-PLAN.md` (excerpt), `SEED-003-*.md`,
`SEED-006-*.md`, `220-CONTEXT.md` (excerpt). All other cited excerpts (REQUIREMENTS.md,
PROJECT.md:42, check-citations.py's regex, collect-ci-runs.sh/summarize-ci.py provenance) are
reused from RESEARCH.md's own `[VERIFIED]` quotes to avoid re-reading ranges already loaded into
this session's context by the upstream researcher.
**Pattern extraction date:** 2026-09-29
