# Phase 101: Phase 96 Verification Backfill - Research

**Researched:** 2026-05-27
**Domain:** Current-tree proof, verification-backfill artifact authoring, and Nyquist closure synchronization for the Phase 96 evidence persistence and public API contract
**Confidence:** HIGH for current-tree facts (read directly from `lib/threadline/evidence.ex`, `lib/threadline/evidence/subject.ex`, `lib/threadline/governance/evidence_record.ex`, `test/threadline/evidence_test.exs`, `test/threadline/governance/evidence_record_test.exs`, and the Phase 100 template artifacts on disk). MEDIUM for the carry-forward `mix verify.test` alias-drift status — commit `b636c17` claims to have fixed it but Phase 101 deliberately does not re-run that command.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Verification artifact structure

- **D-01:** `96-VERIFICATION.md` uses the same frontmatter shape Phase 100 just produced for `95-VERIFICATION.md`: `phase`, `verified`, `status`, `score`, `overrides_applied`.
- **D-02:** The artifact opens with a `## Current-tree preflight` section that states the working tree is the authority, names the missing-artifact gap being closed, and explicitly disclaims any milestone authority-surface changes (those remain Phase 103 work).
- **D-03:** Truth bands — **4 numbered bands**, each with its own `**Requirement:** PROOF-01` line and `**Result:** PASS` block:
  1. **Write contract** — `Threadline.Evidence` public context exists, subject-focused write helpers exist for the closed Phase 95 subject set, no generic public writer exists.
  2. **Read contract** — history reads are list-shaped, singular `latest_*` helpers return one record or `nil`, `list_latest_*` helpers stay list-shaped, no option-driven return-shape switching.
  3. **Defaults and provenance** — mechanical-only auto-fill (normalized `subject`, normalized string-keyed `subject_ref`, `recorded_at`, `schema_version`, narrow provenance envelope), semantic fields (`summary_status`, `detail`, `actor_ref`) remain caller-explicit.
  4. **Phoenix-optional and no-ambient-state** — `Threadline.Evidence` does not depend on Plug, Phoenix, the process dictionary, ETS, or Logger metadata; every public function requires an explicit `repo:` opt.
- **D-04:** The artifact closes with a `## Requirement closure` table (one row for `PROOF-01`) and a `## Not closed here` section (Phase 100 boilerplate only — REQUIREMENTS.md / ROADMAP.md / STATE.md deferred to Phase 103).

#### Rerun bundle and authority

- **D-05:** The authoritative Phase 96 rerun bundle is the focused band:
  ```
  mix test test/threadline/evidence_test.exs \
           test/threadline/governance/evidence_record_test.exs \
           --max-failures 1
  ```
- **D-06:** `96-VALIDATION.md` currently names `mix verify.test` as the authority. If 101-01 finds that to still be the case, the smallest literal repair is to swap the authoritative band over to the focused command set.
- **D-07:** The `mix verify.test` alias-drift recorded in Phase 96's summary is disclaimed in the band-3/4 authority statement. The closing line names Phase 99 as the owner of alias topology and references commit `b636c17`.

#### Proof method for Phoenix-optional / no-ambient-state band

- **D-08:** Structural grep + arity citation, not a new behavioral test.
- **D-09:** Two literal proofs — (1) tightened `rg` pattern `'^\s*(import|alias|require|use)\s+(Plug|Phoenix)\.|Process\.(put|get)\(|Logger\.metadata\(|:ets\.'`, expected empty against `lib/threadline/evidence.ex`. (2) Arity citation showing all public entrypoints require explicit `repo:`. The naive pattern is forbidden — it matches the moduledoc at `lib/threadline/evidence.ex:5`.
- **D-10:** Behavioral test poisoning `Process.put` / `Logger.metadata` is intentionally out of scope. Not listed in "Not closed here" — chosen proof method is the proof, not a deferral.

#### Subject-helper inventory enforcement

- **D-11:** Six exact `record_*` function names asserted by name: `record_redaction_policy`, `record_trigger_coverage`, `record_retention_run`, `record_retention_policy`, `record_export_delivery`, `record_support_scope_posture`.
- **D-12:** Closed-set proof via `rg -n 'def record_' lib/threadline/evidence.ex` — must match exactly the six-function set.
- **D-13:** List-vs-singular shape discipline (Phase 96 D-10/D-11/D-12) lives in the Read-contract band, not the Write-contract band.

#### Requirement closure layout

- **D-14:** `## Requirement closure` table renders `PROOF-01` as a single row with one prose sentence covering create + read + Phoenix-optional.

#### Repair posture

- **D-15:** 101-01 makes only the smallest literal-truth repair if a mismatch is found. Allowed: swap authority band in `96-VALIDATION.md` (per D-06), correct a typo in the closed-subject inventory if drifted, fix a stale code reference. Not allowed: new helpers, renames, expanded inventory, new tests.
- **D-16:** `96-VALIDATION.md` already has `nyquist_compliant: true` and `wave_0_complete: true`. 101-02's finalization is mostly adding `## Commands Actually Used` with the focused-bundle commands actually executed in 101-01, plus reconciling the `Status` column from `planned` to executed verdict.

#### Milestone authority boundary

- **D-17:** Phase 101 MUST NOT modify `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, or `.planning/STATE.md`. The `PROOF-01` row remains `Pending` in those files; Phase 103 flips it.
- **D-18:** `## Not closed here` mirrors Phase 100 boilerplate: three bullets for REQUIREMENTS.md / ROADMAP.md / STATE.md, plus closing line: *"Phase 101 closes the missing Phase 96 verification and validation chain only; milestone authority-surface reconciliation remains Phase 103 work."*

### Claude's Discretion

- Exact prose wording inside each band's bullet list (PASS/FAIL block and cited command must remain explicit).
- Exact ordering of the four bands (Write before Read; Phoenix-optional positioned as holistic boundary).
- Exact `## Commands Actually Used` formatting in `96-VALIDATION.md`.
- Whether to break the structural grep into one or two `rg` invocations.

### Deferred Ideas (OUT OF SCOPE)

- Behavioral test poisoning `Process.put` / `Logger.metadata` — chosen proof method makes it unnecessary; not deferred, just not added.
- Repairing `mix verify.test` alias-drift — Phase 99 owns; commit `b636c17` is the latest fix.
- Updating `.planning/REQUIREMENTS.md` PROOF-01 row from `Pending` to `Complete` — Phase 103.
- Updating `.planning/ROADMAP.md` Phase 101 plan checkboxes — Phase 103 / milestone closeout.
- Updating `.planning/STATE.md` to reflect Phase 101 closure — Phase 103.
- Root-level `Threadline.*` delegates for `Threadline.Evidence` helpers — already deferred in Phase 96, still deferred.
- Phase 102 (SURF backfill) and Phase 103 (authority-surface reconciliation) — separate phases.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | Public library APIs can create and read evidence records without requiring Phoenix or the mounted operator surface. [VERIFIED: `.planning/REQUIREMENTS.md` line 16, Traceability row line 57] | The current `lib/threadline/evidence.ex` exposes six `record_*` write helpers (lines 22–59), five read helpers (`list_history` line 64, `list_subject_ref_history` lines 81/92, `list_latest_subject_refs` lines 100/120, `list_overview` line 128, `get_latest_subject_ref` line 148), every public entrypoint requires explicit `repo:` (lines 165, 269–282), and the module imports nothing from Plug or Phoenix and references nothing in `Process.put`/`Process.get`/`Logger.metadata`/`:ets` (verified by grep — see Band 4 below). The Phase 96 contract is already on disk; what is missing is a `96-VERIFICATION.md` artifact stating that PROOF-01 closes against the current tree. [VERIFIED: current-tree grep + file reads at research time] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Three-layer architecture:** Phase 96 is the *semantics* layer (application-level evidence semantics on top of Phase 95's capture-like primitive in `lib/threadline/governance/`). The verification artifact must not claim exploration/operations-layer concerns (timelines, retention runs, redaction) belong to Phase 96. [VERIFIED: `CLAUDE.md`]
- **Named verification entrypoints:** CLAUDE.md says prefer `mix verify.*` / `mix ci.*` aliases. CONTEXT.md D-05/D-06 deliberately override this for Phase 101 because `mix verify.test` carries unrelated alias-drift. The artifact must explain *why* the focused bundle is the authority instead of `mix verify.test` (boundary scoping, not an indictment of `mix verify.test`). [VERIFIED: `CLAUDE.md` "CI & Verification Conventions"]
- **Stable CI job IDs:** Not applicable in Phase 101 — no CI workflow edits. [VERIFIED: `CLAUDE.md`]
- **Honest default tests:** Phase 101 must not silently widen or narrow `mix test` defaults; it scopes one focused command set as the Phase 96 authority and disclaims `mix verify.test`. [VERIFIED: `CLAUDE.md`]
- **Domain language:** Use `AuditTransaction`/`AuditChange`/`AuditAction`/`ActorRef` etc. consistently. The Phase 96 evidence contract uses its own term (`EvidenceRecord`) which is correct here; do not confuse it with `AuditAction` semantics. [VERIFIED: `CLAUDE.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Verification artifact authoring | Planning / Documentation | — | The artifact is a planning-truth surface; no code or test logic is added. [VERIFIED: D-15] |
| Current-tree re-verification | Test execution (ExUnit + Ecto + PostgreSQL) | — | The focused rerun bundle runs Elixir tests against a real Repo; Phase 101 is consumer of these tests, not their author. [VERIFIED: `test/threadline/evidence_test.exs`, `test/threadline/governance/evidence_record_test.exs`] |
| No-ambient-state proof | Static analysis (ripgrep) | Source citation | Proof is structural grep + arity citation per D-08/D-09; no runtime behavior is asserted. [VERIFIED: D-08, D-09] |
| Validation Nyquist closure | Planning / Documentation | — | `96-VALIDATION.md` is updated in-place to record executed evidence; no new test scaffolding is added. [VERIFIED: D-16] |
| Milestone authority reconciliation | OUT OF SCOPE — Phase 103 | — | Phase 101 must not edit REQUIREMENTS.md / ROADMAP.md / STATE.md. [VERIFIED: D-17] |

## Summary

The current tree on commit `8bf6a7f` already contains the full Phase 96 contract: `lib/threadline/evidence.ex` exposes six subject-focused `record_*` helpers, five read helpers (one list history, one subject-ref history with two arities, one list-latest-per-subject-ref with two arities, one overview list, one singular latest), and all entrypoints require explicit `repo:`. The append-only schema lives in `lib/threadline/governance/evidence_record.ex`. The closed subject inventory lives in `lib/threadline/evidence/subject.ex` with exactly the six families CONTEXT.md D-11 names. The focused test files (`test/threadline/evidence_test.exs` and `test/threadline/governance/evidence_record_test.exs`) exist and cover all four truth bands.

Phase 101's only missing surfaces are paperwork: `96-VERIFICATION.md` (does not exist) and a finalized `96-VALIDATION.md` (exists as a planning-time artifact with `nyquist_compliant: true` but no `## Commands Actually Used` section and with `mix verify.test` named as the authority band — which CONTEXT.md D-06 says to swap for the focused bundle).

**Primary recommendation:** the planner produces two plans that mirror Phase 100's plan pair shape exactly. Plan 101-01 runs the focused rerun bundle plus the two structural greps, writes `96-VERIFICATION.md` against the Phase 100 frontmatter template with four numbered bands (per D-03), and performs the smallest literal-truth repair on `96-VALIDATION.md`'s authority band (per D-06, D-15). Plan 101-02 updates `96-VALIDATION.md` to swap status from `planned` to executed, adds `## Commands Actually Used`, and explicitly leaves milestone surfaces untouched (per D-16, D-17).

## Phase 100 Structural Template — Verbatim Extractions

The planner can copy these sections directly without further derivation.

### Verbatim frontmatter for `96-VERIFICATION.md` (from `95-VERIFICATION.md`)

```yaml
---
phase: 96-evidence-persistence-and-public-api
verified: 2026-05-27T<HH:MM:SSZ>
status: passed
score: 4/4 requirement bands verified
overrides_applied: 0
---
```

(Phase 95 used `3/3 requirement bands verified`; Phase 96 uses `4/4` per D-03.)

### Verbatim header pattern (from `95-VERIFICATION.md`)

```markdown
# Phase 96: Evidence Persistence And Public API Verification Report

**Phase Goal:** Re-prove the current-tree evidence persistence and public API contract with explicit verification evidence instead of inherited summary claims.
**Verified:** 2026-05-27T<HH:MM:SSZ>
**Status:** passed
**Re-verification:** Yes - gap closure for missing phase verification
```

### Verbatim `## Current-tree preflight` template (from `95-VERIFICATION.md`)

```markdown
## Current-tree preflight

**Result:** PASS

- The Phase 96 implementation files, tests, and summaries are present on disk, but `96-VERIFICATION.md` was missing before this run.
- This verification treats the current working tree as the authority and closes that missing artifact gap directly.
- Milestone authority surfaces remain intentionally unreconciled here; `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` stay Phase 103 work.
```

### Verbatim band shape (from `95-VERIFICATION.md` §1)

Each band must use this exact shape:

```markdown
## N. <Band title>

**Requirement:** `PROOF-01`
**Result:** PASS

- <bullet 1 — cite a specific line or module>
- <bullet 2 — cite a specific line or module>
- <bullet 3 — cite a specific line or module>

### Evidence

\`\`\`bash
<the exact command>
\`\`\`

Result: PASS (`<N tests, 0 failures>` or `<grep result description>`)
```

Note the two-space markdown line breaks after the `**Requirement:**` line in `95-VERIFICATION.md` (lines 26, 43, 60). Preserve them or use a blank line — either is fine, but be consistent.

### Verbatim band-title candidates (from CONTEXT.md `<specifics>`)

1. `## 1. Threadline.Evidence public context and subject-focused write helpers`
2. `## 2. Append-only read contract — history, latest, and list_latest semantics`
3. `## 3. Mechanical-only defaults and explicit provenance contract`
4. `## 4. Phoenix-optional install and no-ambient-state boundary`

The Phase 100 convention is `## N. <descriptive title>` with no requirement ID in the heading (the requirement ID lives in the body via `**Requirement:**`). Match that.

### Verbatim `## Requirement closure` table shape (from `95-VERIFICATION.md` lines 81–87)

```markdown
## Requirement closure

| Requirement | Status | Why it closes on the current tree |
| --- | --- | --- |
| `PROOF-01` | ✓ SATISFIED | <one prose sentence covering create + read + Phoenix-optional per D-14> |
```

The Phase 100 artifact uses three rows because Phase 95 had three requirements (`EVID-01`, `EVID-02`, `EVID-03`). Phase 96 has one requirement (`PROOF-01`) per the REQUIREMENTS.md Traceability table line 57 and CONTEXT.md D-14 — render as a single row.

### Verbatim `## Not closed here` template (from `95-VERIFICATION.md` lines 89–94, retargeted per D-18)

```markdown
## Not closed here

- `.planning/REQUIREMENTS.md` remains intentionally unreconciled in this phase.
- `.planning/ROADMAP.md` remains intentionally unreconciled in this phase.
- `.planning/STATE.md` remains intentionally unreconciled in this phase.
- Phase 101 closes the missing Phase 96 verification and validation chain only; milestone authority-surface reconciliation remains Phase 103 work.
```

### Verbatim `## Commands Actually Used` template for finalized `96-VALIDATION.md` (from `95-VALIDATION.md` lines 54–61)

```markdown
## Commands Actually Used

1. `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1`
   Result: PASS (`<N tests, 0 failures>`)
2. `rg -n '^\s*(import|alias|require|use)\s+(Plug|Phoenix)\.|Process\.(put|get)\(|Logger\.metadata\(|:ets\.' lib/threadline/evidence.ex`
   Result: PASS (no matches — negative assertion)
3. `rg -n 'def record_' lib/threadline/evidence.ex`
   Result: PASS (exactly six matches — `record_redaction_policy`, `record_trigger_coverage`, `record_retention_run`, `record_retention_policy`, `record_export_delivery`, `record_support_scope_posture`)
```

(The planner fills in the executed `N tests, 0 failures` count after 101-01 runs.)

## Current-Tree Truth Audit — Per Band

### Band 1 — Write contract (current-tree facts)

**Module:** `lib/threadline/evidence.ex`

| Helper | Line | Signature |
|--------|------|-----------|
| `record_redaction_policy/2,3` | 22 | `def record_redaction_policy(subject_ref, attrs, opts \\ [])` — delegates to private `record_subject("redaction_policy", subject_ref, attrs, opts)` (line 23) |
| `record_trigger_coverage/2,3` | 29 | `def record_trigger_coverage(subject_ref, attrs, opts \\ [])` |
| `record_retention_run/2,3` | 36 | `def record_retention_run(subject_ref, attrs, opts \\ [])` |
| `record_retention_policy/2,3` | 43 | `def record_retention_policy(subject_ref, attrs, opts \\ [])` |
| `record_export_delivery/2,3` | 50 | `def record_export_delivery(subject_ref, attrs, opts \\ [])` |
| `record_support_scope_posture/2,3` | 57 | `def record_support_scope_posture(subject_ref, attrs, opts \\ [])` |

**Private dispatcher:** `record_subject/4` at line 161 — funnels all six helpers through one normalize + validate + insert path. Not part of the public surface.

**Closed-set proof (run live during research):**
```
$ rg -n 'def record_' lib/threadline/evidence.ex
22:  def record_redaction_policy(subject_ref, attrs, opts \\ []) do
29:  def record_trigger_coverage(subject_ref, attrs, opts \\ []) do
36:  def record_retention_run(subject_ref, attrs, opts \\ []) do
43:  def record_retention_policy(subject_ref, attrs, opts \\ []) do
50:  def record_export_delivery(subject_ref, attrs, opts \\ []) do
57:  def record_support_scope_posture(subject_ref, attrs, opts \\ []) do
```
Six matches — exactly the closed set CONTEXT.md D-11 names. Note: this regex also catches the private `defp record_subject` at line 161 if the pattern is loosened to `record_`. Recommended pattern is `'^\s*def record_'` (one leading `def`, not `defp`) to keep the closed-set assertion strictly public. [VERIFIED: live grep at research time]

**Closed subject inventory:** `lib/threadline/evidence/subject.ex` lines 10–17 defines `@supported_subjects` as exactly the six string subjects matching the helper names: `"redaction_policy"`, `"trigger_coverage"`, `"retention_run"`, `"retention_policy"`, `"export_delivery"`, `"support_scope_posture"`. The public function `supported_subjects/0` is at line 30; `validate/1` is at line 36 (returns `:ok | {:error, {:unsupported_subject, term}}`). [VERIFIED: file read at research time]

**Schema boundary:** `lib/threadline/governance/evidence_record.ex` line 15 declares `schema "threadline_evidence_records"`. The schema has only `inserted_at` (line 24), no `updated_at` — append-only by design. [VERIFIED: file read at research time]

**Test coverage:** `test/threadline/evidence_test.exs` lines 36–100 (`describe "record_* helpers"`) covers Band 1 with four tests:
- line 37 `"exposes the supported write helper family without a broad generic writer"` — asserts all six `function_exported?(Evidence, :record_*, 3)` AND `refute function_exported?(Evidence, :record_evidence, 3)` AND `refute function_exported?(Evidence, :record_subject, 4)` (lines 38–46). This is the inventory closure test.
- line 49 `"requires explicit repo handling at the public boundary"` — asserts `{:error, :missing_repo}` when `opts` omits `:repo` (lines 50–55). This is part of Band 4's explicit-repo arity citation too.
- line 57 `"persists normalized defaults and stable provenance"` — asserts `record.provenance == %{"entrypoint" => "record_retention_run", "writer" => "threadline"}` (lines 79–82). This proves Band 3's narrow provenance envelope.
- line 85 `"rejects missing semantic fields even when defaults are available"` — asserts `summary_status` and `detail` errors when callers omit them (lines 86–99). This proves Band 3's caller-explicit-semantic-meaning claim.

### Band 2 — Read contract (current-tree facts)

**Module:** `lib/threadline/evidence.ex`

| Helper | Line | Signature | Shape |
|--------|------|-----------|-------|
| `list_history/1,2` | 64 | `def list_history(filters, opts \\ []) when is_list(filters) and is_list(opts)` | list (always) |
| `list_subject_ref_history/4` | 81 | `def list_subject_ref_history(subject, subject_ref, filters, opts) when is_list(filters) and is_list(opts)` | list (always) |
| `list_subject_ref_history/3` | 92 | `def list_subject_ref_history(subject, subject_ref, opts) when is_list(opts)` — delegates to arity-4 | list (always) |
| `list_latest_subject_refs/3` | 100 | `def list_latest_subject_refs(subject, filters, opts) when is_list(filters) and is_list(opts)` | list (always) |
| `list_latest_subject_refs/2` | 120 | `def list_latest_subject_refs(subject, opts) when is_list(opts)` — delegates to arity-3 | list (always) |
| `list_overview/1,2` | 128 | `def list_overview(filters, opts \\ []) when is_list(filters) and is_list(opts)` | list (always) |
| `get_latest_subject_ref/3` | 148 | `def get_latest_subject_ref(subject, subject_ref, opts) when is_list(opts)` | singular (returns one record or `nil`) |

**Naming discipline (D-11 from Phase 96 CONTEXT):** all latest-projection helpers use `latest_*`, not `current_*`. The list-shaped variants are named `list_latest_*` and the singular variant is `get_latest_*`. Confirmed in code. [VERIFIED: lines 100, 120, 148]

**Return-shape discipline (D-12 from Phase 96 CONTEXT):** there is no option that switches return shape. `get_latest_subject_ref/3` always returns one record or `nil` (line 158 `repo.one()`); `list_*` variants always return lists (lines 75 `repo.all()`, 113 `repo.all()`, etc.). [VERIFIED: file read at research time]

**Filter allow-lists** (fail-loud validation per D-19 from Phase 96):
- `@allowed_history_filter_keys ~w(repo subject subject_ref from to limit)a` (line 15)
- `@allowed_subject_ref_history_filter_keys ~w(repo from to limit)a` (line 16)
- `@allowed_latest_filter_keys ~w(repo from to limit)a` (line 17)
- Unknown keys raise `ArgumentError` via `validate_filters!/3` at line 237.

**Test coverage:** `test/threadline/evidence_test.exs` lines 102–250 (`describe "history and latest helpers"`) covers Band 2 with five tests:
- line 103 `"lists append-only history with explicit filters and stable list shapes"` — asserts list shapes for `list_history` and `list_subject_ref_history`, including `[]` for empty (lines 126–141).
- line 144 `"rejects unknown history filter keys loudly"` — asserts `ArgumentError ~r/unknown evidence history filter key :nope/` (lines 145–147).
- line 150 `"returns explicit latest projections without hiding older history"` — asserts list shape for `list_latest_subject_refs/2` (lines 180–183), singular shape for `get_latest_subject_ref/3` returning one record (line 185–188), `nil` return when no match (lines 190–191), and history list shape still independent (lines 193–198).
- line 201 `"returns overview latest rows across all six supported subject families"` — asserts `list_overview/2` covers the full six-family inventory (lines 209–220).
- line 223 `"applies overview limit across the combined subject inventory"` — asserts the `:limit` filter on `list_overview` (lines 245–248).

### Band 3 — Defaults and provenance (current-tree facts)

**Module:** `lib/threadline/evidence.ex`

| Default | Where filled | Line |
|---------|-------------|------|
| Normalized `subject` (atom→string, validated against closed inventory) | `validate_subject!/1` called from `record_subject/4` via `Subject.validate/1` | 161–172, 284–303 |
| Normalized string-keyed `subject_ref` (atoms→strings recursively) | `normalize_subject_ref/1` + `normalize_map_values/1` | 202–228 |
| `recorded_at` default | `build_record_attrs/4` via `Map.put_new(:recorded_at, DateTime.utc_now(:microsecond))` | 180 |
| `schema_version` default | `build_record_attrs/4` via `Map.put_new(:schema_version, @schema_version)` (constant `1` at line 14) | 14, 181 |
| Provenance envelope | `provenance/2` builds `%{"writer" => "threadline", "entrypoint" => "record_<subject>"}` and `Map.merge`s any caller-supplied extra | 186–192 |

**Helper-specific entrypoint label:** each helper passes its own subject to `record_subject/4`, which computes `entrypoint = "record_#{subject}"` (line 163) — so the provenance always names which public helper inserted the row. [VERIFIED: lines 22–59, 161–164]

**Semantic fields stay caller-explicit (D-15 from Phase 96 CONTEXT):**
- `summary_status` is required by the changeset (line 30 of `evidence_record.ex`, in `@required_fields`).
- `detail` is required by the changeset (line 33 of `evidence_record.ex`).
- `actor_ref` is optional but not auto-filled (it appears in `cast/3` at line 46 but not in `@required_fields` at line 27–35).

**The library does NOT auto-fill semantic fields** — the test at `test/threadline/evidence_test.exs` line 85 (`"rejects missing semantic fields even when defaults are available"`) is the locking proof.

### Band 4 — Phoenix-optional and no-ambient-state (current-tree facts)

**Two literal proofs per D-09:**

**Proof A — Tightened structural grep (negative assertion, expected EMPTY):**

```
rg -n '^\s*(import|alias|require|use)\s+(Plug|Phoenix)\.|Process\.(put|get)\(|Logger\.metadata\(|:ets\.' lib/threadline/evidence.ex
```

**Live result at research time:** no matches (exit code 1). [VERIFIED: live grep at research time]

The tightened pattern matches:
- Module-reference forms `import Plug.X`, `alias Phoenix.X`, `require Plug.X`, `use Phoenix.X` — with the line anchor `^\s*` requiring the directive to start the line, blocking false positives in moduledoc strings.
- Runtime-call forms `Process.put(`, `Process.get(`, `Logger.metadata(`, `:ets.` — each suffixed with the start of an argument list or qualified call to avoid matching prose.

**Naive pattern that MUST NOT be used (per D-09):**

```
rg -n 'Plug\.|Phoenix|Process\.put|Process\.get|Logger\.metadata|:ets' lib/threadline/evidence.ex
```

**Live result at research time:** matches line 5 — `Evidence helpers stay Phoenix-optional, require explicit `repo:` handling, and` (the moduledoc string). This is a false positive. [VERIFIED: live grep at research time]

The verification artifact MUST cite the tightened pattern, not the naive pattern, and SHOULD explicitly note why (one sentence is enough — see suggested wording below).

**Proof B — Arity citation that every public entrypoint requires `repo:`:**

| Public function | `repo:` enforcement | Line |
|-----------------|--------------------|------|
| `record_*` (×6) | All six funnel through `record_subject/4` (line 161) which calls `validate_repo(Keyword.get(opts, :repo))` (line 165). `validate_repo(nil)` returns `{:error, :missing_repo}` (line 346). The `repo.insert/1` call uses `Keyword.fetch!(opts, :repo)` (line 172) — raises if missing. | 161–173, 346–347 |
| `list_history/1,2` | `evidence_repo!(filters, opts)` (line 66) raises `ArgumentError` if neither `filters` nor `opts` supplies `:repo` (lines 269–282) | 64, 66, 269–282 |
| `list_subject_ref_history/3,4` | Delegates to `list_history/2` via line 89 — inherits the same enforcement | 81, 89 |
| `list_latest_subject_refs/2,3` | `evidence_repo!(filters, opts)` at line 103 | 100, 103 |
| `list_overview/1,2` | `evidence_repo!(filters, opts)` at line 130 | 128, 130 |
| `get_latest_subject_ref/3` | `evidence_repo!([], opts)` at line 149 | 148, 149 |

**No ambient-state lookups anywhere in the module:** `evidence.ex` has zero references to `Process.put`/`Process.get`, `Logger.metadata`, ETS, or `Plug.Conn`. The only imports are `import Ecto.Query` (line 9) and the two aliases `Threadline.Evidence.Subject` (line 11) and `Threadline.Governance.EvidenceRecord` (line 12). [VERIFIED: file read at research time]

**Suggested band-4 wording for the negative-pattern footnote:** *"Pattern is tightened to start-of-line module directives (`import|alias|require|use`) and runtime-call forms (`Process.put(`, `Process.get(`, `Logger.metadata(`, `:ets.`). The naive `'Plug\.|Phoenix|...'` pattern is rejected because it matches the module's own `@moduledoc` line at `lib/threadline/evidence.ex:5`, which is documentation, not a runtime dependency."*

## Current State of `96-VALIDATION.md`

The artifact at `.planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md` exists today with this frontmatter (lines 1–9):

```yaml
---
phase: 96
slug: evidence-persistence-and-public-api
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
updated: 2026-05-25T19:50:00Z
---
```

| Field | Current value | After 101-02 |
|-------|---------------|--------------|
| `phase` | `96` | unchanged |
| `slug` | `evidence-persistence-and-public-api` | unchanged |
| `status` | `planned` | `validated` (mirrors `95-VALIDATION.md` line 4) |
| `nyquist_compliant` | `true` | unchanged (already true per D-16) |
| `wave_0_complete` | `true` | unchanged (already true per D-16) |
| `created` | `2026-05-25` | unchanged |
| `updated` | `2026-05-25T19:50:00Z` | bump to 101-01's execution timestamp |

**Per-Task Verification Map status drift:** the existing table at lines 35–40 lists Status as `planned` for all four rows (`96-V-01` through `96-V-04`). After 101-01 runs, these need to flip to `✅ green` (mirroring `95-VALIDATION.md` line 50 conventions: `⬜ pending · ✅ green · ❌ red · ⚠️ flaky`).

**Authority-band drift (the literal-truth repair candidate per D-06):**

| Section | Current text | Should become |
|---------|--------------|---------------|
| Line 21 `Quick run command` | `mix verify.test` | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` |
| Line 22 `Focused debugging band` | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` | Either promote to a `Full suite command` row or remove (it is now the primary authority) |
| Lines 37, 39 `Automated Command` for `96-V-01` and `96-V-03` | `mix verify.test` | the focused bundle command |
| Lines 47, 48 `Requirement-to-Command Map` | references `mix verify.test` twice | swap to the focused bundle |
| Line 30 `Sampling Rate` second bullet | references `mix verify.test` | swap to the focused bundle |

**Sign-off update required:** the line at the bottom of `96-VALIDATION.md` reads `**Approval:** planned on 2026-05-25 for Phase 96 execution.` It must become something like `**Approval:** finalized on 2026-05-27 after Phase 101-01 produced 96-VERIFICATION.md and the current-tree rerun bundle passed.` (mirroring `95-VALIDATION.md` line 101).

**New sections to add (per D-16):**
- `## Commands Actually Used` — see verbatim template above.
- `## Phase Boundary Guard` — copy verbatim from `95-VALIDATION.md` lines 83–90, retargeted to `PROOF-01`.

**Sections to retain unchanged:**
- `## Wave 0 Requirements` — already lists Phase 96 contract test files; status checkboxes can be confirmed as `[x]`.
- `## Manual-Only Verifications` — already includes the boundary-guard line.

## Phase 100 Plan Pair Shape (verbatim extractions for 101-01 and 101-02)

### 100-01-PLAN.md shape (101-01 mirrors this)

**Frontmatter keys** (from lines 1–59):
- `phase: 101-phase-96-verification-backfill`
- `plan: "01"`
- `type: execute`
- `wave: 1`
- `depends_on: []`
- `files_modified:` (list)
- `autonomous: true`
- `requirements:` — `[PROOF-01]` (Phase 100 had three; Phase 101 has one)
- `must_haves:`
  - `truths:` (3 strings, narrating the closure shape)
  - `artifacts:` (list of `{path, provides, contains}` triples)
  - `key_links:` (list of `{from, to, via, pattern}` quadruples)

**`<read_first>` pattern** (from line 129–136): each `<task>` lists 5–7 files as `<file>` elements — the implementation source files plus the prior phase summaries plus the structural template.

**`<acceptance_criteria>` pattern** (from lines 138–142, 163–168): three to four `<criterion>` items, each one a grep-able literal-truth statement. Examples for 101:
- `.planning/phases/96-evidence-persistence-and-public-api/96-VERIFICATION.md` contains `PROOF-01`, `Current-tree preflight`, `Not closed here`, and one of the band titles.
- `96-VERIFICATION.md` cites the focused-bundle command explicitly and records its outcome with `Result: PASS` or `Result: FAIL`.
- Closed-set proof citation matches exactly six `def record_` lines.
- If any code/test file changes, changes are limited to literal contract alignment.

**`<verify><automated>` pattern** (line 144, 170): one shell command that combines `mix test ...` with `&&` and one or more `rg -n` literal-truth assertions against the artifact.

**`<task>` count:** Phase 100-01 had **two** tasks. Phase 101-01 can match (Task 1 = rerun bundle + structural greps + literal-truth repair on `96-VALIDATION.md`; Task 2 = write `96-VERIFICATION.md`), or split into three if the planner prefers (1 = rerun + greps, 2 = repair `96-VALIDATION.md` authority band, 3 = write `96-VERIFICATION.md`).

**`<threat_model>` shape** (lines 177–193): one `Trust Boundaries` table (3 rows) + one `STRIDE Threat Register` table (3 rows with `T-100-XX` IDs). For Phase 101 use `T-101-XX`:
- `T-101-01 Tampering` — public write-helper closed inventory
- `T-101-02 Repudiation` — provenance default contract
- `T-101-03 Elevation of scope` — closed subject boundary
- `T-101-04 Tampering` — read-shape discipline (added for 4-band coverage)
- `T-101-05 Repudiation` — no-ambient-state proof method

### 100-02-PLAN.md shape (101-02 mirrors this)

**Frontmatter** (from lines 1–29):
- `wave: 2`
- `depends_on: ["101-01"]`
- `files_modified:` only `.planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md`
- `must_haves.truths:` 3 strings about Nyquist closure scope and narrow-authority discipline
- `must_haves.artifacts:` one entry for `96-VALIDATION.md`
- `must_haves.key_links:` one entry linking VERIFICATION.md to VALIDATION.md

**`<task>` count:** one (matches 100-02-PLAN.md line 68).

**`<verify><automated>` pattern** (line 84): one `rg -n` command that asserts presence of `phase: 96`, `nyquist_compliant: true`, `wave_0_complete: true`, `PROOF-01`, `## Commands Actually Used`, `evidence_test\.exs`, and `evidence_record_test\.exs`.

## Per-Task Verification Map (the shape `96-VALIDATION.md` already uses)

Reading `96-VALIDATION.md` lines 35–40 plus `89-VALIDATION.md` lines 43–49 plus `95-VALIDATION.md` lines 43–48, the canonical columns are:

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |

(Phase 96's current artifact omits `File Exists` because nothing was on disk yet; the finalized version SHOULD include it per the modern Nyquist shape that Phase 95 used.)

Suggested rows after 101-01 executes (planner finalizes):

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 101-01-01 | 01 | 1 | PROOF-01 | T-101-01, T-101-02, T-101-03 | The current tree still exposes exactly six subject-focused write helpers with no generic public writer, mechanical-only defaults, and explicit semantic fields. | focused integration + structural grep | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1 && rg -n '^\s*def record_' lib/threadline/evidence.ex` | ✅ | ✅ green |
| 101-01-02 | 01 | 1 | PROOF-01 | T-101-04 | Read helpers preserve list-vs-singular shape discipline and reject unknown filter keys loudly. | focused integration | `mix test test/threadline/evidence_test.exs --max-failures 1` | ✅ | ✅ green |
| 101-01-03 | 01 | 1 | PROOF-01 | T-101-05 | `Threadline.Evidence` does not depend on Plug, Phoenix, the process dictionary, ETS, or Logger metadata. | structural grep (negative assertion) | `rg -n '^\s*(import\|alias\|require\|use)\s+(Plug\|Phoenix)\.\|Process\.(put\|get)\(\|Logger\.metadata\(\|:ets\.' lib/threadline/evidence.ex` (expected empty) | ✅ | ✅ green |
| 101-02-01 | 02 | 2 | PROOF-01 | T-101-06 | `96-VALIDATION.md` records the executed rerun bundle, the structural-grep proof, and the closed-set proof — all referenced from `96-VERIFICATION.md`. | artifact review | `rg -n '^phase: 96\|^nyquist_compliant: true\|^wave_0_complete: true\|PROOF-01\|## Commands Actually Used\|evidence_test\.exs\|evidence_record_test\.exs' .planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md` | ✅ | ✅ green |

## Focused Rerun Bundle Confirmation

Per D-05 the authoritative command is:

```
mix test test/threadline/evidence_test.exs \
         test/threadline/governance/evidence_record_test.exs \
         --max-failures 1
```

**Both test files exist on disk at research time:**
- `test/threadline/evidence_test.exs` — 251 lines, 9 tests across 2 `describe` blocks (`record_* helpers`, `history and latest helpers`).
- `test/threadline/governance/evidence_record_test.exs` — 71 lines, 3 tests at top level (no `describe` block).

**Test inventory (verbatim from `rg -n '^\s*test\s+"|^\s*describe\s+"'`):**

`test/threadline/governance/evidence_record_test.exs`:
- line 12: `test "changeset accepts a valid Threadline-owned evidence payload"` — Band 1/Band 3
- line 30: `test "changeset rejects missing required fields"` — Band 3 (semantic-field enforcement)
- line 51: `test "two inserts for the same logical subject are accepted"` — Band 1 (append-only)

`test/threadline/evidence_test.exs`:
- line 36: `describe "record_* helpers"` opens
- line 37: `test "exposes the supported write helper family without a broad generic writer"` — Band 1
- line 49: `test "requires explicit repo handling at the public boundary"` — Band 4
- line 57: `test "persists normalized defaults and stable provenance"` — Band 3
- line 85: `test "rejects missing semantic fields even when defaults are available"` — Band 3
- line 102: `describe "history and latest helpers"` opens
- line 103: `test "lists append-only history with explicit filters and stable list shapes"` — Band 2
- line 144: `test "rejects unknown history filter keys loudly"` — Band 2
- line 150: `test "returns explicit latest projections without hiding older history"` — Band 2
- line 201: `test "returns overview latest rows across all six supported subject families"` — Band 2 (overview coverage)
- line 223: `test "applies overview limit across the combined subject inventory"` — Band 2 (overview limit)

**Total:** 12 tests across the two files. The expected `Result:` line in `96-VERIFICATION.md` will be `Result: PASS (12 tests, 0 failures)` if all pass and no `Threadline.Evidence` regression has crept in since Phase 96 shipped.

**Pre-existing failures recorded in summaries:** `96-02-SUMMARY.md` line 86 records that `mix verify.test` still failed at Phase 96 closeout time on an unrelated assertion in `test/threadline/ci_topology_contract_test.exs` (alias-drift). The focused bundle does NOT include that test file, so it is unaffected. CONTEXT.md D-07 captures the carry-forward disclaimer; the band-3/4 authority statement names Phase 99 commit `b636c17` as the most recent fix. Phase 101 should run the focused bundle FIRST; only if it fails should the planner consider the disclaimer text.

## Smallest Literal-Truth Repair Candidates (D-15)

Surfaced from a `96-VALIDATION.md` vs. CONTEXT.md diff:

| Drift | Location | Fix | Rationale |
|-------|----------|-----|-----------|
| Authority band names `mix verify.test` | `96-VALIDATION.md` lines 21, 37, 39, 47–48, plus second bullet at line 30 | Swap to the focused bundle `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` | Per D-06 the focused bundle is the Phase 96 authority |
| Status column is `planned` for all four rows | `96-VALIDATION.md` lines 37–40 | Flip to `✅ green` after 101-01 passes | Per D-16, status reflects execution |
| `status: planned` in frontmatter | `96-VALIDATION.md` line 4 | Flip to `validated` | Mirrors `95-VALIDATION.md` line 4 after Phase 100 finalized it |
| `updated:` timestamp | `96-VALIDATION.md` line 8 | Bump to 101-01's execution timestamp | Reflects the actual update event |
| Approval line | `96-VALIDATION.md` line 65 | Replace `planned on 2026-05-25 for Phase 96 execution` with the post-execution finalization line | Mirrors `95-VALIDATION.md` line 101 |
| Missing `## Commands Actually Used` section | `96-VALIDATION.md` (no section) | Add per the verbatim template in this RESEARCH.md | Per D-16, this is the main shape change |
| Missing `## Phase Boundary Guard` section | `96-VALIDATION.md` (no section) | Add per `95-VALIDATION.md` lines 83–90, retargeted to `PROOF-01` | Brings the artifact into modern Nyquist shape |
| **No code/test drift expected** | `lib/threadline/evidence.ex`, `lib/threadline/evidence/subject.ex`, `lib/threadline/governance/evidence_record.ex`, test files | None unless rerun finds an unexpected failure | Current-tree grep + signature audit at research time confirms the Phase 96 contract is intact |

**The literal-truth repair scope for 101-01 is entirely planning-artifact text** — no code or test edits are expected. If the focused rerun bundle fails for an unanticipated reason, the planner should treat that failure as out-of-scope and surface it as a blocking finding rather than expanding 101-01 to repair it (per D-15: `Not allowed: adding new helpers, renaming public functions, expanding the subject inventory, adding new tests.`).

## Common Pitfalls

### Pitfall 1: Using the naive grep pattern that matches the moduledoc

**What goes wrong:** The verification artifact cites the naive pattern `'Plug\.|Phoenix|Process\.put|Process\.get|Logger\.metadata|:ets'` and shows it matching line 5 of `lib/threadline/evidence.ex` — which is the docstring "Phoenix-optional". The artifact then has to argue the match away in prose, weakening the negative assertion.
**Why it happens:** The naive pattern is shorter and looks fine at first glance.
**How to avoid:** Use the tightened pattern from D-09 verbatim. State explicitly in the band-4 prose why the tightened pattern is correct.
**Warning signs:** the artifact body contains a "false positive on line 5" caveat.

### Pitfall 2: Treating `mix verify.test` failure as Phase 101 work

**What goes wrong:** `mix verify.test` fails (carry-forward alias-drift or unrelated). The verification artifact pulls that failure into a band's PASS/FAIL block and the planner spends 101-01 on Phase 99 territory.
**Why it happens:** CLAUDE.md prefers `mix verify.*` aliases; instinct says to honor them.
**How to avoid:** Per D-05/D-06, the focused bundle is the authority. The band authority statement disclaims `mix verify.test` and names Phase 99 commit `b636c17` as the most recent fix.
**Warning signs:** the artifact's `Evidence` block for any band cites `mix verify.test`.

### Pitfall 3: Closed-set grep matches the private dispatcher

**What goes wrong:** D-12 says use `rg -n 'def record_' lib/threadline/evidence.ex` and expect exactly six matches. But there is also a private `defp record_subject/4` at line 161 — if the regex is loosened to `record_` (without the `def ` prefix) or to `def[p]? record_`, the match count becomes 7, breaking the closed-set assertion.
**Why it happens:** A reviewer wonders whether `defp` should count.
**How to avoid:** Use `rg -n '^\s*def record_' lib/threadline/evidence.ex` — leading whitespace + `def` (not `defp`) + `record_`. The current tree gives exactly six matches with that pattern.
**Warning signs:** the closed-set proof in the artifact shows 7 matches.

### Pitfall 4: Counting tests wrong on the rerun

**What goes wrong:** The artifact says `Result: PASS (12 tests, 0 failures)` but the actual output says 11 or 13.
**Why it happens:** ExUnit counts top-level `test` blocks; nested `describe` blocks don't add to the count. The count from `rg -n '^\s*test\s+"'` (12) matches the ExUnit count.
**How to avoid:** Record the literal output the planner observes. The expected count is 12, but the artifact must record what the rerun actually printed, not what research predicted.
**Warning signs:** the artifact's `Result:` count was copied from RESEARCH.md without rerun confirmation.

### Pitfall 5: Adding a behavioral test in 101-01

**What goes wrong:** Someone reads the `## Don't Hand-Roll` section, sees "ambient state poisoning" as a known threat, and writes a test that puts a key in `Process.put` and asserts `Threadline.Evidence` ignores it.
**Why it happens:** Adding a test seems like obviously stronger proof than a grep.
**How to avoid:** Per D-08 and D-10, structural grep + arity citation IS the chosen proof method. Adding a test widens scope and triggers a longer review. The planner's tasks must NOT include a "write new test" action.
**Warning signs:** any plan task whose action contains the verbs "add test", "write test", "create test file", or "extend test".

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Verification frontmatter | Custom YAML | Copy `95-VERIFICATION.md` frontmatter shape verbatim | Phase 100 already locked the convention; deviation invites bikeshedding |
| Validation frontmatter | Custom YAML | Copy `95-VALIDATION.md` frontmatter verbatim and bump dates | Same as above |
| Per-task verification table | Custom columns | Copy the canonical 10-column table from `95-VALIDATION.md` line 43 | Tooling and human reviewers expect those exact columns |
| Negative-assertion grep | Naive `'Plug\.|Phoenix|...'` | Use the tightened pattern from D-09 verbatim | Naive pattern matches the moduledoc and weakens the proof |
| Authority statement | Multi-paragraph prose | Mirror `99-VERIFICATION.md` lines 122–130 — short list + one-line repo-health disclaimer | Phase 99's shape is the supplementary template per CONTEXT.md canonical refs |
| Test counting | Re-derive expected counts | Record exactly what ExUnit prints on the rerun | Research can predict 12; rerun reports literal truth |

**Key insight:** Phase 101 is a paperwork phase. The hand-rolled risk is in artifact prose, not in code or tests.

## Code Examples (verbatim band shapes ready to copy)

### Band 1 example (skeleton — fill in the prose bullets)

```markdown
## 1. Threadline.Evidence public context and subject-focused write helpers

**Requirement:** `PROOF-01`
**Result:** PASS

- `lib/threadline/evidence.ex` exposes exactly six public `record_*` helpers (lines 22, 29, 36, 43, 50, 57) — one per closed Phase 95 subject family.
- The module deliberately exposes no generic public writer; `record_subject/4` is a private dispatcher at line 161 and not callable from outside the module.
- `lib/threadline/evidence/subject.ex` enforces the closed inventory at validation time, and the closed inventory matches the public helper names one-to-one.

### Evidence

\`\`\`bash
mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1
\`\`\`

Result: PASS (`12 tests, 0 failures`)

\`\`\`bash
rg -n '^\s*def record_' lib/threadline/evidence.ex
\`\`\`

Result: PASS — exactly six matches: `record_redaction_policy`, `record_trigger_coverage`, `record_retention_run`, `record_retention_policy`, `record_export_delivery`, `record_support_scope_posture`.
```

### Band 4 example (skeleton — fill in the prose bullets)

```markdown
## 4. Phoenix-optional install and no-ambient-state boundary

**Requirement:** `PROOF-01`
**Result:** PASS

- `Threadline.Evidence` requires explicit `repo:` at every public entrypoint (validated in `record_subject/4` line 165 and `evidence_repo!/2` lines 269–282); there is no fallback path that reads an ambient repo.
- The module imports only `Ecto.Query` (line 9) and aliases only `Threadline.Evidence.Subject` and `Threadline.Governance.EvidenceRecord` (lines 11–12); it imports nothing from Plug or Phoenix.
- A tightened structural grep against `lib/threadline/evidence.ex` returns no matches for Plug/Phoenix module directives or for runtime calls to the process dictionary, `Logger.metadata`, or `:ets`.

> Note: the pattern is tightened to start-of-line module directives (`import|alias|require|use`) and runtime-call forms (`Process.put(`, `Process.get(`, `Logger.metadata(`, `:ets.`). The naive pattern `'Plug\.|Phoenix|...'` is rejected because it matches the module's own `@moduledoc` line at `lib/threadline/evidence.ex:5`, which is documentation, not a runtime dependency.

### Evidence

\`\`\`bash
rg -n '^\s*(import|alias|require|use)\s+(Plug|Phoenix)\.|Process\.(put|get)\(|Logger\.metadata\(|:ets\.' lib/threadline/evidence.ex
\`\`\`

Result: PASS (no matches — negative assertion).

### Authority statement

The authoritative Phase 96 rerun bundle is:

1. `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1`
2. `rg -n '^\s*(import|alias|require|use)\s+(Plug|Phoenix)\.|Process\.(put|get)\(|Logger\.metadata\(|:ets\.' lib/threadline/evidence.ex`
3. `rg -n '^\s*def record_' lib/threadline/evidence.ex`

`mix verify.test` is intentionally not the authority for Phase 96. The Phase 96-02 summary records a pre-existing alias-drift failure in `test/threadline/ci_topology_contract_test.exs` that is outside Phase 96 ownership; Phase 99 owns the named-alias topology, and commit `b636c17` ("fix(99-02): update ci.all topology contract to expanded doc_contract alias") is the most recent fix on that surface. Phase 101 disclaims rather than reopens that scope.
```

## State of the Art (Phase 96 contract on the current tree)

| Old approach | Current approach | When changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 96 closure inferred from summary frontmatter | Phase 96 closure proven against the current tree by a focused rerun bundle plus two structural grep proofs | Phase 101 (this phase) | `PROOF-01` becomes auditable instead of inherited |
| `mix verify.test` as the Phase 96 authority band | Focused rerun bundle as authority; `mix verify.test` recorded as a non-authoritative supporting signal at best | Phase 101 per D-06 | Carry-forward alias-drift no longer blocks Phase 96 closure |
| `96-VALIDATION.md` is planning-time only (`status: planned`) | `96-VALIDATION.md` is executed (`status: validated`) with `## Commands Actually Used` | Phase 101-02 per D-16 | Validation matches verification |

**Deprecated/outdated:**
- The naive grep pattern `'Plug\.|Phoenix|Process\.put|Process\.get|Logger\.metadata|:ets'` against `lib/threadline/evidence.ex` is deprecated for Phase 101 (D-09). Use the tightened pattern.
- `## Per-Task Verification Map` without a `File Exists` column is deprecated; Phase 95-VALIDATION uses 10 columns including `File Exists` — match that.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The focused rerun bundle (12 tests across 2 files) will pass on the current tree without code edits. | Focused Rerun Bundle Confirmation | LOW — the implementation files have not changed since Phase 96 shipped and the test files exist with the right test counts. If a test fails unexpectedly, the planner must escalate per D-15 (literal-truth repair only). |
| A2 | The 4-band split is best read in the order Write / Read / Defaults / Phoenix-optional. | Verbatim band-title candidates | LOW — D-03 fixes the four bands; ordering is `Claude's Discretion` per CONTEXT.md `<decisions>` last paragraph. |
| A3 | The Per-Task Verification Map should use 10 columns (matching `95-VALIDATION.md`), not the 8 columns the current `96-VALIDATION.md` uses. | Current State of `96-VALIDATION.md` | LOW — adopting the 10-column shape brings 96 in line with 95 and 89; either is recoverable. |
| A4 | The closed-set grep pattern should be `^\s*def record_` (anchored, excluding `defp`), not the looser `def record_` from D-12. | Pitfall 3 | LOW — D-12 says "exactly six functions" and the current `defp record_subject/4` exists, so the anchored pattern is the correct interpretation of D-12 in code. If the planner uses unanchored `def record_` against the current tree, it would also return six matches (since the private one is `defp`, not `def`), but anchored is safer. |
| A5 | `mix verify.test` alias-drift was actually fixed by commit `b636c17` — but Phase 101 does not re-run it to confirm. | CLAUDE.md / "Disclaim in band authority statement" | LOW — even if it is still broken, the disclaim posture works (Phase 99 is the owner). MEDIUM if the planner is tempted to test it; per D-05 they should not. |

## Open Questions (RESOLVED)

1. **Should `96-VALIDATION.md` retain its draft `phase: 96` (number-only) or switch to `phase: 96-evidence-persistence-and-public-api` (number-slug)?** Phase 95-VALIDATION uses `phase: 95` (line 2). Phase 95-VERIFICATION uses `phase: 95-evidence-model-lock-and-scope-guard` (line 2). The two artifacts use different conventions. **RESOLVED:** keep `96-VALIDATION.md` at `phase: 96` (no change to that line) to minimize diff; `96-VERIFICATION.md` should use `phase: 96-evidence-persistence-and-public-api`. (101-02 Task 1 action encodes this resolution; planner may override if they want symmetry.)

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | rerun bundle execution | ✓ (assumed from prior phase research; the planner can verify) | 1.19.5 from `96-RESEARCH.md` line 150 | — |
| Mix | `mix test` execution | ✓ | 1.19.5 | — |
| PostgreSQL (local) | `Threadline.DataCase` setup in both test files | ✓ (assumed — Phase 100 ran the rerun bundle on the same machine on 2026-05-26) | 14.17 from `96-RESEARCH.md` line 153 | none for integration tests |
| ripgrep (`rg`) | structural grep + closed-set grep + artifact-content greps | ✓ (used throughout Phase 100 plan verification) | — | none — `grep -E` would also work but the plans cite `rg` verbatim |
| Phoenix | NOT required by Phase 96 contract | — | — | optional dep in `mix.lock`; Phase 101 must NOT pull it in |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5) + Ecto/PostgreSQL via `Threadline.DataCase` + ripgrep (`rg`) for structural and artifact greps |
| Config file | `mix.exs`, `config/test.exs`, `test/test_helper.exs`, `.planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md`, `.planning/phases/96-evidence-persistence-and-public-api/96-VERIFICATION.md` (created by 101-01) |
| Quick run command | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` |
| Full suite command | Same as quick run — the focused bundle IS the authority per D-05 |
| Estimated runtime | ~10–30 seconds warm |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROOF-01 | Six subject-focused public `record_*` helpers exist; no generic public writer exists. | integration + grep | `mix test test/threadline/evidence_test.exs --max-failures 1 && rg -n '^\s*def record_' lib/threadline/evidence.ex` | ✅ (both source and tests on disk) |
| PROOF-01 | Read helpers preserve list-vs-singular discipline; unknown filter keys raise loudly. | integration | `mix test test/threadline/evidence_test.exs --max-failures 1` | ✅ |
| PROOF-01 | Defaults are mechanical-only (subject/subject_ref/recorded_at/schema_version/provenance); semantic fields stay caller-explicit. | integration | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` | ✅ |
| PROOF-01 | `Threadline.Evidence` does not depend on Plug, Phoenix, the process dictionary, ETS, or Logger metadata; every public entrypoint requires explicit `repo:`. | structural grep (negative assertion) + arity citation | `rg -n '^\s*(import\|alias\|require\|use)\s+(Plug\|Phoenix)\.\|Process\.(put\|get)\(\|Logger\.metadata\(\|:ets\.' lib/threadline/evidence.ex` (expected empty) | ✅ |
| PROOF-01 | `96-VERIFICATION.md` exists and contains all required band markers. | artifact grep | `rg -n 'Current-tree preflight\|PROOF-01\|Not closed here\|Result: PASS' .planning/phases/96-evidence-persistence-and-public-api/96-VERIFICATION.md` | ❌ Wave 0 (created in 101-01) |
| PROOF-01 | `96-VALIDATION.md` is final Nyquist artifact synchronized to executed bundle. | artifact grep | `rg -n '^phase: 96\|^nyquist_compliant: true\|^wave_0_complete: true\|PROOF-01\|## Commands Actually Used\|evidence_test\.exs\|evidence_record_test\.exs' .planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md` | ✅ (file exists, but `## Commands Actually Used` section is added in 101-02) |

### Sampling Rate

- **Per task commit:** `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` (every task in 101-01 that touches verification artifact prose; 101-02 is artifact-only and may skip).
- **Per wave merge:** same focused bundle plus the two structural greps.
- **Phase gate:** focused bundle green + both grep assertions pass + artifact grep on `96-VERIFICATION.md` shows all required markers + artifact grep on `96-VALIDATION.md` shows updated frontmatter and `## Commands Actually Used`.

### Wave 0 Gaps

- [ ] `.planning/phases/96-evidence-persistence-and-public-api/96-VERIFICATION.md` — to be created in 101-01.
- [ ] `## Commands Actually Used` section in `96-VALIDATION.md` — to be added in 101-02.
- [ ] `## Phase Boundary Guard` section in `96-VALIDATION.md` — to be added in 101-02.

*(No code/test gaps: the focused-bundle tests, the implementation module, the schema, the subject inventory, and the file-level grep target all exist on the current tree at research time.)*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 101 is a verification-backfill phase — no auth surface is added or modified. [VERIFIED: D-15 disallows code changes beyond literal-truth repair] |
| V3 Session Management | no | No session surface in scope. |
| V4 Access Control | no | The `Threadline.Evidence` API is library-facing and Phoenix-optional; mounted-surface auth lives in Phase 98 (`evidence_authorize_fn`, verified separately by Phase 102). |
| V5 Input Validation | yes (carry-forward) | Already enforced by `Threadline.Evidence`: explicit `repo:` validation (lines 269–282), supported-subject validation via `Subject.validate/1`, filter allow-lists (lines 15–17), required-field changeset enforcement in `EvidenceRecord` (lines 27–35). Phase 101 verifies these stay in place; it does not add new validators. |
| V6 Cryptography | no | No crypto surface. |

### Known Threat Patterns for the Phase 96 contract on the current tree

| Pattern | STRIDE | Standard Mitigation | Verified by Phase 101 |
|---------|--------|---------------------|-----------------------|
| Unsupported subject injection | Tampering | `Subject.validate/1` rejects with `{:error, {:unsupported_subject, term}}` before insert | Band 1 + closed-set grep |
| Forged or hidden provenance | Repudiation | Provenance is helper-owned: `provenance/2` at line 186–192 hard-codes `"writer" => "threadline"` and `"entrypoint" => "record_<subject>"`; caller-supplied extras are merged in but never override the two library-owned keys | Band 3 + the `persists normalized defaults and stable provenance` test |
| Ambient-state lookup leak | Repudiation | `Threadline.Evidence` does not call `Process.put`/`Process.get`/`Logger.metadata`/`:ets` and does not import Plug or Phoenix | Band 4 + tightened grep |
| Unbounded history reads | Denial of service | `:limit` filter validated as positive integer (`validate_limit!/1` line 311–315); `list_overview/2` applies `:limit` after combining subject families | Band 2 + the overview-limit test |
| Closed-set boundary erosion | Tampering | Public writer family is exactly six functions; private dispatcher cannot be called from outside the module | Band 1 + closed-set grep |

## Sources

### Primary (HIGH confidence)

- `/Users/jon/projects/threadline/.planning/phases/101-phase-96-verification-backfill/101-CONTEXT.md` — locked decisions D-01 through D-18 for this phase.
- `/Users/jon/projects/threadline/.planning/phases/101-phase-96-verification-backfill/101-DISCUSSION-LOG.md` — alternative options considered (audit-trail only, not planning input).
- `/Users/jon/projects/threadline/.planning/phases/100-phase-95-verification-backfill/100-RESEARCH.md` — Phase 100 research template (same gap-closure posture).
- `/Users/jon/projects/threadline/.planning/phases/100-phase-95-verification-backfill/100-PATTERNS.md` — file-to-analog mapping for verification backfills.
- `/Users/jon/projects/threadline/.planning/phases/100-phase-95-verification-backfill/100-01-PLAN.md` — exact plan shape for 101-01 (frontmatter keys, `<task>` shape, `<verify><automated>` pattern).
- `/Users/jon/projects/threadline/.planning/phases/100-phase-95-verification-backfill/100-02-PLAN.md` — exact plan shape for 101-02.
- `/Users/jon/projects/threadline/.planning/phases/100-phase-95-verification-backfill/100-VERIFICATION.md` — Phase 100's own verification artifact (sample shape for 101 itself, not 96).
- `/Users/jon/projects/threadline/.planning/phases/100-phase-95-verification-backfill/100-VALIDATION.md` — Phase 100's draft validation (sample shape for 101 itself).
- `/Users/jon/projects/threadline/.planning/phases/100-phase-95-verification-backfill/100-01-SUMMARY.md` and `100-02-SUMMARY.md` — completion record for Phase 100.
- `/Users/jon/projects/threadline/.planning/phases/95-evidence-model-lock-and-scope-guard/95-VERIFICATION.md` — exact-shape template for `96-VERIFICATION.md` (frontmatter, preflight, numbered bands, requirement closure, "Not closed here").
- `/Users/jon/projects/threadline/.planning/phases/95-evidence-model-lock-and-scope-guard/95-VALIDATION.md` — exact-shape template for the finalized `96-VALIDATION.md` (`nyquist_compliant: true`, sampling rate, per-task verification map, `## Commands Actually Used`, sign-off).
- `/Users/jon/projects/threadline/.planning/phases/89-contract-lock-final-verification/89-VALIDATION.md` — supplementary template for the modern Nyquist shape (per-task verification map columns, `## Commands Actually Used` shape).
- `/Users/jon/projects/threadline/.planning/phases/99-contract-lock-docs-and-final-verification/99-VERIFICATION.md` — supplementary template for per-band PASS/FAIL conventions and authority-statement shape.
- `/Users/jon/projects/threadline/.planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md` — locked Phase 96 contract decisions (write/read/defaults/Phoenix-optional).
- `/Users/jon/projects/threadline/.planning/phases/96-evidence-persistence-and-public-api/96-RESEARCH.md` — Phase 96 contract rationale.
- `/Users/jon/projects/threadline/.planning/phases/96-evidence-persistence-and-public-api/96-01-SUMMARY.md` and `96-02-SUMMARY.md` — execution summaries (96-02 records the `mix verify.test` alias-drift carry-forward at line 86).
- `/Users/jon/projects/threadline/.planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md` — current state (planning-time artifact) of the file 101-02 finalizes.
- `/Users/jon/projects/threadline/lib/threadline/evidence.ex` — current Phase 96 implementation; line numbers for every public helper captured above.
- `/Users/jon/projects/threadline/lib/threadline/evidence/subject.ex` — closed inventory enforced by Phase 96 helpers.
- `/Users/jon/projects/threadline/lib/threadline/governance/evidence_record.ex` — schema and required-field enforcement.
- `/Users/jon/projects/threadline/test/threadline/evidence_test.exs` — 9 tests across 2 describe blocks; line-precise test inventory captured above.
- `/Users/jon/projects/threadline/test/threadline/governance/evidence_record_test.exs` — 3 top-level tests; line-precise inventory captured above.
- `/Users/jon/projects/threadline/.planning/REQUIREMENTS.md` — `PROOF-01` definition (line 16) and Traceability row (line 57).
- `/Users/jon/projects/threadline/.planning/ROADMAP.md` — Phase 101 goal at lines 99–108.
- `/Users/jon/projects/threadline/.planning/STATE.md` — current milestone state (Phase 100 complete, Phase 101 next).
- `/Users/jon/projects/threadline/.planning/v1.22-MILESTONE-AUDIT.md` — `PROOF-01` audit finding at line 33, `mix verify.test` alias-drift tech-debt note at line 66.
- `/Users/jon/projects/threadline/CLAUDE.md` — project verify-alias conventions and three-layer architecture.

### Secondary (MEDIUM confidence)

- Live ripgrep runs against the current tree at research time (captured in *Band 4 — Phoenix-optional and no-ambient-state* and *Pitfall 3*) — confirmed D-09 tightened pattern returns empty and confirmed D-12 closed-set proof returns exactly six matches. These reflect commit `8bf6a7f` (HEAD at research time).

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Phase 100 structural template extraction: HIGH — read all four canonical templates (`95-VERIFICATION.md`, `95-VALIDATION.md`, `89-VALIDATION.md`, `99-VERIFICATION.md`) plus the Phase 100 plan pair end-to-end.
- Current-tree truth audit: HIGH — read `lib/threadline/evidence.ex`, `lib/threadline/evidence/subject.ex`, `lib/threadline/governance/evidence_record.ex`, and both test files in full; confirmed D-09 and D-12 grep results live.
- Current state of `96-VALIDATION.md`: HIGH — read the full file; identified seven concrete repair sites for 101-02.
- Focused rerun bundle verification: HIGH — both test files exist, the test inventory matches the band coverage requirements.
- Smallest literal-truth repair candidates: HIGH — surfaced from a direct diff between current `96-VALIDATION.md` and CONTEXT.md D-06/D-16.
- Validation Architecture section: HIGH — derived from CONTEXT.md D-05 and confirmed against current-tree state.
- Carry-forward `mix verify.test` alias-drift status: MEDIUM — relies on commit message `b636c17` claim plus 96-02-SUMMARY line 86. Phase 101 does not re-run `mix verify.test` to confirm.

**Research date:** 2026-05-27
**Valid until:** 2026-06-26 (30 days; current-tree facts are stable as long as no one edits `lib/threadline/evidence.ex` between research and execution)

## RESEARCH COMPLETE
