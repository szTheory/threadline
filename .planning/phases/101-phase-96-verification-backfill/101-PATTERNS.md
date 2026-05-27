# Phase 101: Phase 96 Verification Backfill - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 4 (2 artifacts + 2 plans)
**Analogs found:** 4 / 4

## Scope Statement

Phase 101 is a documentation-only verification-backfill. No source code or tests
are created or modified. The files to be created/modified are planning
artifacts that live inside another phase's directory:

**Created:**
- `.planning/phases/96-evidence-persistence-and-public-api/96-VERIFICATION.md`

**Modified:**
- `.planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md`

The plan pair `101-01-PLAN.md` and `101-02-PLAN.md` are the planner's own
output and inherit shape directly from the Phase 100 plan pair.

Data flow direction (per pattern-mapping prompt):

```
lib/threadline/evidence.ex
lib/threadline/evidence/subject.ex
lib/threadline/governance/evidence_record.ex
test/threadline/evidence_test.exs
test/threadline/governance/evidence_record_test.exs
.planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md
                              |
                              v
   mix test ...               + rg structural greps      + rg closed-set grep
                              |
                              v
.planning/phases/96-evidence-persistence-and-public-api/96-VERIFICATION.md  (NEW)
.planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md   (FINAL)
```

Verbatim excerpt sources (already extracted in 101-RESEARCH.md, cited here by
line range to avoid duplication):

| Need | Location in 101-RESEARCH.md |
|------|------------------------------|
| Frontmatter for `96-VERIFICATION.md` | lines 116-128 |
| Header pattern | lines 130-139 |
| `## Current-tree preflight` template | lines 141-151 |
| Band shape skeleton | lines 153-176 |
| Band-title candidates | lines 178-185 |
| `## Requirement closure` table shape | lines 187-197 |
| `## Not closed here` template | lines 199-208 |
| `## Commands Actually Used` template | lines 210-223 |
| Band 1 example (fillable) | lines 578-605 |
| Band 4 example (fillable) | lines 607-638 |
| Per-task verification map rows | lines 460-471 |
| Phase 100 plan-pair frontmatter keys | lines 407-454 |
| Smallest-literal-truth repair candidates | lines 511-526 |
| Current `96-VALIDATION.md` drift map | lines 373-403 |

## File Classification

| File | Role | Data Flow | Closest Analog | Match Quality |
|------|------|-----------|----------------|----------------|
| `.planning/phases/96-evidence-persistence-and-public-api/96-VERIFICATION.md` (NEW) | verification artifact (current-tree truth surface) | transform (read code + run commands -> record verdicts) | `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VERIFICATION.md` | exact-shape (same backfill posture; band count grows 3 -> 4 per CONTEXT D-03) |
| `.planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md` (MODIFY) | validation artifact (Nyquist closure contract) | transform (read VERIFICATION.md -> finalize Nyquist evidence) | `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VALIDATION.md` | exact-shape (same finalize-from-planned-to-validated transition Phase 100 just executed) |
| `.planning/phases/101-phase-96-verification-backfill/101-01-PLAN.md` (the planner writes this) | wave-1 execute plan | request-response (rerun + grep -> artifact) | `.planning/phases/100-phase-95-verification-backfill/100-01-PLAN.md` | exact-shape (same plan structure; PROOF-01 has one requirement instead of three) |
| `.planning/phases/101-phase-96-verification-backfill/101-02-PLAN.md` (the planner writes this) | wave-2 execute plan | request-response (read 96-VERIFICATION.md -> finalize 96-VALIDATION.md) | `.planning/phases/100-phase-95-verification-backfill/100-02-PLAN.md` | exact-shape (same single-task finalize-Nyquist plan) |

**Supplementary analogs** (consult, do not clone wholesale):
- `.planning/phases/99-contract-lock-docs-and-final-verification/99-VERIFICATION.md` — supplementary shape for per-band PASS/FAIL block conventions and authority statement (mentioned in 101-RESEARCH.md `Don't Hand-Roll` table at line 573).
- `.planning/phases/89-contract-lock-final-verification/89-VALIDATION.md` — supplementary shape for the modern 10-column Per-Task Verification Map. The current `96-VALIDATION.md` uses a 9-column variant (no `File Exists`) — promote to 10 columns per 101-RESEARCH.md assumption A3 (line 658).

## Pattern Assignments

### `96-VERIFICATION.md` (NEW)

**Primary analog:** `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VERIFICATION.md` (95 lines total)
**Supplementary analog:** `.planning/phases/99-contract-lock-docs-and-final-verification/99-VERIFICATION.md` (PASS/FAIL conventions)

Pull these excerpts verbatim:

| Excerpt | Source | Lines | Transform for Phase 96 |
|---------|--------|-------|------------------------|
| Frontmatter block | `95-VERIFICATION.md` | 1-7 | swap `phase`, `verified` timestamp, `score` -> `4/4` |
| Header + Re-verification line | `95-VERIFICATION.md` | 9-14 | swap phase title, retarget goal sentence |
| `## Current-tree preflight` (PASS + 3 bullets) | `95-VERIFICATION.md` | 16-22 | swap "Phase 95" -> "Phase 96"; swap "Phase 100" -> "Phase 101" in closing bullet |
| Numbered band skeleton (heading + `**Requirement:**` + `**Result:**` + 3 bullets + `### Evidence` + fenced bash + Result line) | `95-VERIFICATION.md` | 24-39 (§1), 41-56 (§2), 58-79 (§3 with two evidence blocks) | reuse skeleton 4x with band-title candidates from 101-RESEARCH.md lines 178-185 |
| `## Requirement closure` table (one row per requirement) | `95-VERIFICATION.md` | 81-87 | collapse to **one row** for `PROOF-01` per CONTEXT D-14; use prose from 101-CONTEXT.md `<specifics>` lines 289-294 |
| `## Not closed here` (3 bullets + closing line) | `95-VERIFICATION.md` | 89-94 | retarget closing line to "Phase 101 closes the missing Phase 96 verification..." per CONTEXT D-18 |

**Key shape constraints (do not deviate):**

- The band-1 `**Requirement:**` line in the analog has two trailing spaces before its newline (markdown line break). Mirror this for all four Phase 96 bands; the analog uses it consistently at lines 26, 43, 60.
- Each `### Evidence` block contains exactly one fenced `bash` block per command, followed by a single `Result: PASS (...)` line. Band 3 in the analog (lines 67-79) demonstrates two `### Evidence` blocks under one band — the Phase 96 band 1 and band 4 both have two evidence blocks (the test command + the grep command), so they follow this same convention.
- The closing line of `## Not closed here` is a non-bullet sentence on its own line in the analog (line 94). Match that.
- The artifact has no closing `---` divider; bottom of file is the closing sentence. Match that.

**Forbidden patterns** (lifted from 101-RESEARCH.md Pitfalls and Don't Hand-Roll):

- Do NOT use the naive grep pattern `'Plug\.|Phoenix|Process\.put|Process\.get|Logger\.metadata|:ets'` — it matches the moduledoc string at `lib/threadline/evidence.ex:5`. Use the tightened pattern from CONTEXT D-09 verbatim.
- Do NOT cite `mix verify.test` in any band's Evidence block. The focused bundle is the authority per CONTEXT D-05/D-06. Disclaim `mix verify.test` in prose, never in the Result line.
- Do NOT use unanchored `def record_` — use `^\s*def record_` to exclude the private `defp record_subject/4` at line 161 of `evidence.ex` per Pitfall 3.

**Band-content sources (where the prose in each band's bullet list comes from):**

| Band | Title (candidate from 101-RESEARCH.md lines 180-184) | Source for bullet prose |
|------|------|------|
| 1 | `## 1. Threadline.Evidence public context and subject-focused write helpers` | 101-RESEARCH.md lines 227-263 (write-contract truth audit), CONTEXT D-11, D-12 |
| 2 | `## 2. Append-only read contract — history, latest, and list_latest semantics` | 101-RESEARCH.md lines 264-294 (read-contract truth audit), CONTEXT D-13 |
| 3 | `## 3. Mechanical-only defaults and explicit provenance contract` | 101-RESEARCH.md lines 295-314 (defaults audit), CONTEXT D-03 band 3 |
| 4 | `## 4. Phoenix-optional install and no-ambient-state boundary` | 101-RESEARCH.md lines 316-355 (Phoenix-optional audit + D-09 tightened pattern), CONTEXT D-08, D-09 |

### `96-VALIDATION.md` (MODIFY)

**Primary analog:** `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VALIDATION.md` (102 lines total)
**Supplementary analog:** `.planning/phases/89-contract-lock-final-verification/89-VALIDATION.md` (10-column Per-Task Verification Map)

Pull these excerpts verbatim:

| Excerpt | Source | Lines | Transform for Phase 96 |
|---------|--------|-------|------------------------|
| Final-state frontmatter (`status: validated`, modern timestamps) | `95-VALIDATION.md` | 1-9 | bump `status` `planned` -> `validated`, bump `updated` to 101-01's executed timestamp; keep `nyquist_compliant: true` and `wave_0_complete: true` unchanged per CONTEXT D-16 |
| Title + closing-state lead paragraph | `95-VALIDATION.md` | 11-15 | swap "Phase 95" -> "Phase 96"; cite `96-VERIFICATION.md` |
| `## Test Infrastructure` (re-pointed at executed bundle) | `95-VALIDATION.md` | 19-28 | swap Config file paths to Phase 96 surfaces; swap Quick/Full run commands to the focused bundle per CONTEXT D-06 |
| `## Sampling Rate` 4 bullets | `95-VALIDATION.md` | 32-37 | retarget to evidence-contract surfaces and PROOF-01 |
| `## Per-Task Verification Map` 10-column table + legend line | `95-VALIDATION.md` | 43-50 | reuse 4 rows (101-01-01, 101-01-02, 101-01-03, 101-02-01) per 101-RESEARCH.md lines 466-471 |
| `## Commands Actually Used` numbered list | `95-VALIDATION.md` | 54-61 | use the verbatim template from 101-RESEARCH.md lines 210-223 with executed test counts filled in |
| `## Wave 0 Requirements` checklist | `95-VALIDATION.md` | 65-70 | swap to Phase 96 surfaces |
| `## Manual-Only Verifications` 2-row table | `95-VALIDATION.md` | 74-79 | retarget rows to PROOF-01 boundary and append-only review |
| `## Phase Boundary Guard` 5-bullet block | `95-VALIDATION.md` | 83-89 | retarget to PROOF-01 only; bullet 5 names Phase 97, Phase 98, and milestone closeout |
| `## Validation Sign-Off` checklist + approval line | `95-VALIDATION.md` | 93-101 | swap rerun-bundle wording to focused bundle; approval line follows the pattern at line 101 |

**Smallest-literal-truth repairs already enumerated in 101-RESEARCH.md** (use as the 101-01 task action checklist):

The repair-candidate table at 101-RESEARCH.md lines 511-526 lists 7 concrete drift sites in the current `96-VALIDATION.md`. The 101-01 plan's task action MUST cover each:

1. Frontmatter `status: planned` -> `validated` (line 4 of `96-VALIDATION.md`).
2. Frontmatter `updated:` bump (line 8).
3. Replace `mix verify.test` with the focused bundle at lines 21, 30, 37, 39, 47-48.
4. Flip Per-Task Verification Map Status column `planned` -> `✅ green` (lines 37-40).
5. Promote the Per-Task Verification Map from 9 columns to 10 columns (add `File Exists`) per 101-RESEARCH.md A3.
6. Add `## Commands Actually Used` section after `## Per-Task Verification Map` (currently absent).
7. Add `## Phase Boundary Guard` section after `## Manual-Only Verifications` (currently absent).
8. Rewrite the closing `**Approval:**` line (line 65) per the executed-finalization pattern from `95-VALIDATION.md` line 101.

**Key shape constraints (do not deviate):**

- `## Per-Task Verification Map` legend line `*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*` (analog line 50) MUST appear immediately under the table.
- `## Commands Actually Used` uses **numbered** (`1.`, `2.`, ...) entries with the command on the first line and `Result: PASS (...)` on the second line indented three spaces (analog lines 56-61). Match that indentation exactly.
- The `## Phase Boundary Guard` section in the analog has exactly 5 bullets; bullets 2-4 name `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` verbatim. Mirror this — these are the milestone-authority surfaces CONTEXT D-17 says Phase 101 must NOT touch.
- The validation artifact has horizontal-rule dividers (`---`) between top-level sections (analog lines 17, 30, 39, 52, 63, 72, 81, 91). Match that.

**Forbidden patterns:**

- Do NOT claim Phase 102 or Phase 103 progress in this artifact. The boundary guard's 5th bullet (analog line 89) names downstream phases as out of scope; Phase 96's equivalent is "Phase 97, Phase 98, and milestone closeout".
- Do NOT include an `## Authoritative-Surface Drift` section (89-VALIDATION.md lines 88-93). That section is Phase 89-specific; the modern Phase 95-style closure for `96-VALIDATION.md` uses `## Phase Boundary Guard` instead.

### `101-01-PLAN.md` (planner writes)

**Primary analog:** `.planning/phases/100-phase-95-verification-backfill/100-01-PLAN.md` (209 lines total)

Pull these excerpts verbatim:

| Excerpt | Source | Lines | Transform for Phase 101 |
|---------|--------|-------|-------------------------|
| Frontmatter block (`phase`, `plan`, `type`, `wave`, `depends_on`, `files_modified`, `autonomous`, `requirements`, `must_haves.{truths,artifacts,key_links}`) | `100-01-PLAN.md` | 1-59 | swap `phase` to `101-phase-96-verification-backfill`; collapse `requirements:` to `[PROOF-01]`; narrow `files_modified:` to just `96-VERIFICATION.md` and `96-VALIDATION.md` plus current-tree files only if literal repair is needed; rewrite the 3 `truths:` bullets to PROOF-01 narrative (CONTEXT D-02, D-04, D-18) |
| `<objective>` block | `100-01-PLAN.md` | 61-69 | swap requirement names; mention "literal-truth repair on `96-VALIDATION.md` authority band" per CONTEXT D-06 |
| `<execution_context>` block | `100-01-PLAN.md` | 71-74 | unchanged |
| `<context>` block with `@` references | `100-01-PLAN.md` | 76-98 | swap to Phase 96 surfaces from CONTEXT `<canonical_refs>` lines 185-223 |
| `<interfaces>` block | `100-01-PLAN.md` | 99-121 | swap Phase 95 interfaces for Phase 96 ones: `schema "threadline_evidence_records"`, `def record_redaction_policy`, `def supported_subjects` |
| `<task type="auto">` with `<name>`, `<files>`, `<read_first>`, `<action>`, `<acceptance_criteria>`, `<verify><automated>`, `<done>` | `100-01-PLAN.md` | 126-147 (task 1), 149-173 (task 2) | match the 2-task split exactly (or split into 3 per 101-RESEARCH.md line 433); each task's `<verify><automated>` must combine `mix test ...` and `rg -n` literal-truth checks per 101-RESEARCH.md lines 431-432 |
| `<threat_model>` (Trust Boundaries + STRIDE) | `100-01-PLAN.md` | 177-193 | swap `T-100-XX` -> `T-101-XX`; add T-101-04 (read-shape discipline) and T-101-05 (no-ambient-state) per 101-RESEARCH.md lines 437-440 |
| `<verification>`, `<success_criteria>`, `<output>` | `100-01-PLAN.md` | 195-209 | swap "Phase 95" -> "Phase 96"; output file becomes `101-01-SUMMARY.md` |

**Acceptance-criteria pattern** (analog lines 138-142, 163-168):

Each `<criterion>` is a single-line, grep-friendly literal-truth claim about the artifact. For Phase 101 reuse the criteria shapes from 101-RESEARCH.md lines 425-429:
- 96-VERIFICATION.md contains `PROOF-01`, `Current-tree preflight`, `Not closed here`, and one of the band titles.
- 96-VERIFICATION.md cites the focused-bundle command explicitly and records its outcome with `Result: PASS` or `Result: FAIL`.
- Closed-set proof citation matches exactly six `def record_` lines.
- If any code/test file changes, changes are limited to literal contract alignment.

**`<read_first>` content size:** the analog lists 5-7 `<file>` elements per task (lines 129-136, 152-161). Stay in that range — do NOT over-stuff the read list. Required reads for 101-01 are the Phase 96 implementation files (`evidence.ex`, `subject.ex`, `evidence_record.ex`), the two test files, `96-CONTEXT.md`, and the structural template (`95-VERIFICATION.md`).

**`<verify><automated>` pattern** (analog lines 144, 170):

One shell command per task. The analog uses `&&` to chain a `mix test ...` invocation with one or more `rg -n` literal-truth assertions against the artifact. Phase 101-01 task 2 must include both grep patterns from CONTEXT D-09 and D-12:

```
mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1 && rg -n '^\s*def record_' lib/threadline/evidence.ex && rg -n 'Current-tree preflight|PROOF-01|Not closed here|Result: PASS' .planning/phases/96-evidence-persistence-and-public-api/96-VERIFICATION.md
```

### `101-02-PLAN.md` (planner writes)

**Primary analog:** `.planning/phases/100-phase-95-verification-backfill/100-02-PLAN.md` (121 lines total)

Pull these excerpts verbatim:

| Excerpt | Source | Lines | Transform for Phase 101 |
|---------|--------|-------|-------------------------|
| Frontmatter (note `wave: 2`, `depends_on: ["100-01"]`, single-file `files_modified`) | `100-02-PLAN.md` | 1-29 | swap `phase`, swap `depends_on` -> `["101-01"]`, `files_modified` is just `96-VALIDATION.md`, collapse `requirements:` to `[PROOF-01]`; one `artifacts:` entry for `96-VALIDATION.md`; one `key_links:` entry from VERIFICATION.md -> VALIDATION.md |
| `<objective>`, `<execution_context>`, `<context>` | `100-02-PLAN.md` | 31-64 | swap Phase 95 -> Phase 96 paths; consult `89-VALIDATION.md` and `99-VALIDATION.md` as supplementary shape references |
| Single `<task type="auto">` block | `100-02-PLAN.md` | 68-87 | mirror exactly — one task is sufficient (101-RESEARCH.md line 452 confirms); the `<action>` already enumerates "preserve existing validation-strategy sections where they are still accurate, but replace draft-only status with executed evidence" — retarget to PROOF-01 |
| `<verify><automated>` literal-grep check | `100-02-PLAN.md` | 84 | extend grep pattern to include `## Commands Actually Used`, `evidence_test\.exs`, `evidence_record_test\.exs` per 101-RESEARCH.md line 454 |
| `<threat_model>` | `100-02-PLAN.md` | 91-105 | swap T-100-04 -> T-101-06 (validation evidence), T-100-05 -> T-101-07 (phase boundary) |
| `<verification>`, `<success_criteria>`, `<output>` | `100-02-PLAN.md` | 107-120 | swap output to `101-02-SUMMARY.md` |

**Single-task discipline:** the analog has exactly one `<task>`. Resist splitting `96-VALIDATION.md` finalization into multiple tasks — it is a single in-place edit per CONTEXT D-16.

## Shared Patterns

### Authority statement convention (applies to `96-VERIFICATION.md` band evidence blocks)

**Source:** 99-VERIFICATION.md lines 122-130 (referenced via 101-RESEARCH.md Don't Hand-Roll table line 573) + 101-RESEARCH.md lines 629-637 (suggested band-4 closing).

The verification artifact's Phoenix-optional band ends with a short
"Authority statement" sub-section listing the three authoritative commands and
one paragraph explaining why `mix verify.test` is intentionally not the
authority. The disclaimer names commit `b636c17` as the most recent Phase 99
fix, per CONTEXT D-07.

### Frontmatter date discipline

**Source:** `95-VERIFICATION.md` line 3, `95-VALIDATION.md` line 8.

Both artifacts use ISO-8601 UTC timestamps (`2026-05-26T14:54:49Z`) for
`verified` (VERIFICATION) and `updated` (VALIDATION). The Phase 101 finalization
must use 101-01's actual execution timestamp, not a planning-time placeholder.

### Closed-set grep idiom

**Source:** 101-RESEARCH.md Pitfall 3 (lines 544-549) + CONTEXT D-12.

When the artifact asserts a closed inventory (e.g., "exactly six `record_*`
helpers"), the grep pattern must anchor the leading `def ` with `^\s*` to
exclude `defp` private dispatchers. Apply this to `96-VERIFICATION.md` band 1
and to `101-01-PLAN.md` task 2's `<verify><automated>`.

### Tightened structural grep idiom

**Source:** CONTEXT D-09 + 101-RESEARCH.md lines 320-340.

Negative-assertion greps against `evidence.ex` MUST use the tightened pattern
that anchors module directives at start-of-line and qualifies runtime calls
with their opening paren or namespace separator. Apply this to
`96-VERIFICATION.md` band 4 and to `101-01-PLAN.md` task 3's
`<verify><automated>` (if split) or task 2's (if 2-task layout).

### Phase-boundary discipline

**Source:** CONTEXT D-17, D-18 + `95-VALIDATION.md` lines 83-89 + `95-VERIFICATION.md` lines 89-94.

Both artifacts close with an explicit list of files NOT touched
(`.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`) and
a closing sentence reserving milestone-authority reconciliation for Phase 103.
This boilerplate is non-negotiable per CONTEXT D-04, D-17, D-18.

## No Analog Found

None. Every file in Phase 101 has a direct exact-shape analog from Phase 100,
Phase 95 (target of Phase 100), Phase 89 (modern Nyquist shape source), or
Phase 99 (per-band PASS/FAIL conventions source). The Phase 100 plan pair is
the single best reference because it executed the same verification-backfill
pattern only one phase ago.

## Metadata

**Reference phases:** 95 (closure-target template), 100 (backfill execution template), 89 (modern Nyquist Per-Task Verification Map shape), 99 (supplementary VERIFICATION conventions).

**Primary proof surfaces** (for the planner's authoring tasks, not for the
artifacts themselves to claim): `lib/threadline/evidence.ex`,
`lib/threadline/evidence/subject.ex`,
`lib/threadline/governance/evidence_record.ex`,
`test/threadline/evidence_test.exs`,
`test/threadline/governance/evidence_record_test.exs`.

**Pattern extraction date:** 2026-05-27.

**Verbatim excerpt locations:** all already extracted in 101-RESEARCH.md lines
112-456 — do not re-extract. This document is a per-file analog map that
references those line ranges.
