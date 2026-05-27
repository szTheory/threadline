# Phase 101: Phase 96 Verification Backfill - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 101 is a verification-backfill phase that closes the missing Phase 96
proof chain. The implementation that Phase 96 was supposed to deliver — the
`Threadline.Evidence` public context, subject-focused write helpers, generic
history reads, latest projections, and the Phoenix-optional / no-ambient-state
boundary — already exists on the current tree. What is missing is
`96-VERIFICATION.md` and a Nyquist-final `96-VALIDATION.md`, so `PROOF-01`
remains pending only because the closure chain was not written.

Phase 101 does NOT redesign the evidence persistence or public API, does NOT
add new helpers, does NOT widen the rerun bundle into broader repo-health
territory, and does NOT touch milestone authority surfaces. The structural
parallel is Phase 100, which just closed the same gap for Phase 95.

Two plans:
- **101-01** — re-verify the current tree against the Phase 96 contract and
  make only the smallest literal-truth repair if a mismatch is found.
- **101-02** — write `96-VERIFICATION.md` and finalize `96-VALIDATION.md` with
  the executed commands and Nyquist sign-off.

</domain>

<decisions>
## Implementation Decisions

### Verification artifact structure

- **D-01:** `96-VERIFICATION.md` uses the same frontmatter shape Phase 100 just
  produced for `95-VERIFICATION.md`: `phase`, `verified`, `status`, `score`,
  `overrides_applied`.
- **D-02:** The artifact opens with a `## Current-tree preflight` section that
  states the working tree is the authority, names the missing-artifact gap
  being closed, and explicitly disclaims any milestone authority-surface
  changes (those remain Phase 103 work).
- **D-03:** Truth bands — **4 numbered bands**, each with its own
  `**Requirement:** PROOF-01` line and `**Result:** PASS` block:
  1. **Write contract** — `Threadline.Evidence` public context exists,
     subject-focused write helpers exist for the closed Phase 95 subject set,
     no generic public writer exists.
  2. **Read contract** — history reads are list-shaped, singular `latest_*`
     helpers return one record or `nil`, `list_latest_*` helpers stay
     list-shaped, no option-driven return-shape switching.
  3. **Defaults and provenance** — mechanical-only auto-fill (normalized
     `subject`, normalized string-keyed `subject_ref`, `recorded_at`,
     `schema_version`, narrow provenance envelope), semantic fields
     (`summary_status`, `detail`, `actor_ref`) remain caller-explicit.
  4. **Phoenix-optional and no-ambient-state** — `Threadline.Evidence` does
     not depend on Plug, Phoenix, the process dictionary, ETS, or Logger
     metadata; every public function requires an explicit `repo:` opt.
- **D-04:** The artifact closes with a `## Requirement closure` table
  (one row for `PROOF-01`) and a `## Not closed here` section (Phase 100
  boilerplate only — REQUIREMENTS.md / ROADMAP.md / STATE.md deferred to
  Phase 103).

### Rerun bundle and authority

- **D-05:** The authoritative Phase 96 rerun bundle is the focused band:
  ```
  mix test test/threadline/evidence_test.exs \
           test/threadline/governance/evidence_record_test.exs \
           --max-failures 1
  ```
  This matches Phase 100's narrowing posture and avoids broader repo-health
  noise that is not the Phase 96 contract.
- **D-06:** `96-VALIDATION.md` currently names `mix verify.test` as the
  authority. If 101-01 finds that to still be the case, the smallest literal
  repair is to swap the authoritative band over to the focused command set,
  retaining `mix verify.test` only as a non-authoritative supporting band
  if at all. This is in scope as a literal-truth repair under the same
  posture Phase 100 used.
- **D-07:** The `mix verify.test` alias-drift recorded in Phase 96's summary
  (pre-existing failure outside Phase 96 ownership, audit line 66) is
  disclaimed in the band-3/4 authority statement. The closing line names
  Phase 99 as the owner of alias topology and references commit `b636c17`
  ("fix(99-02): update ci.all topology contract to expanded doc_contract
  alias") as the most recent fix. Phase 101 does NOT pull alias-topology
  repair into its scope.

### Proof method for Phoenix-optional / no-ambient-state band

- **D-08:** The Phoenix-optional band uses **structural grep + arity citation**
  rather than a new behavioral test. No new test is added in Phase 101.
- **D-09:** Two literal proofs are recorded:
  1. **Structural grep** — a tightened pattern that only matches actual
     module references and function calls (not moduledoc text). Use a
     pattern of the shape:
     ```
     rg -n '^\s*(import|alias|require|use)\s+(Plug|Phoenix)\.|Process\.(put|get)\(|Logger\.metadata\(|:ets\.' lib/threadline/evidence.ex
     ```
     The expected result is empty (negative assertion). The naive pattern
     `'Plug\.|Phoenix|Process\.put|Process\.get|Logger\.metadata|:ets'`
     incorrectly matches the moduledoc string at `lib/threadline/evidence.ex:5`
     and MUST NOT be used as the artifact's grep pattern.
  2. **Arity citation** — `96-VERIFICATION.md` cites that every public
     entrypoint in `Threadline.Evidence` requires explicit `repo:` opt, so
     there is no path for ambient repo lookup. Cite the closed `record_*`
     helper inventory as evidence.
- **D-10:** Adding a behavioral test that poisons `Process.put` / `Logger.metadata`
  and asserts `Threadline.Evidence` ignores them is intentionally out of
  scope for Phase 101 (verification-backfill posture, no widening). This
  exclusion is NOT listed in the artifact's "Not closed here" section
  (D-23) — the chosen proof method is the proof, not a deferral.

### Subject-helper inventory enforcement

- **D-11:** The Write-contract band asserts the exact six `record_*` function
  names by name:
  - `record_redaction_policy`
  - `record_trigger_coverage`
  - `record_retention_run`
  - `record_retention_policy`
  - `record_export_delivery`
  - `record_support_scope_posture`
- **D-12:** The Write-contract band also includes a closed-set proof using
  `rg -n 'def record_' lib/threadline/evidence.ex` and asserts the result
  matches exactly that six-function set. A future PR adding `record_anything`
  would fail this band.
- **D-13:** The list-vs-singular shape discipline (D-10/D-11/D-12 from the
  Phase 96 CONTEXT) lives in the Read-contract band, not the Write-contract
  band — `list_latest_*` stays list-shaped, singular `latest_*` returns one
  record or `nil`, no option-driven shape switching.

### Requirement closure layout

- **D-14:** The `## Requirement closure` table renders `PROOF-01` as a **single
  row** with one prose sentence covering create + read + Phoenix-optional.
  This matches Phase 100's convention and aligns with the single-row entry
  in `.planning/REQUIREMENTS.md` Traceability table.

### Repair posture

- **D-15:** 101-01 makes only the smallest literal-truth repair if a mismatch
  is found. Allowed examples: updating the authority band in `96-VALIDATION.md`
  (per D-06), correcting a typo in the closed-subject inventory if drifted,
  fixing a stale code reference. Not allowed: adding new helpers, renaming
  public functions, expanding the subject inventory, adding new tests.
- **D-16:** If `96-VALIDATION.md` already has `nyquist_compliant: true` and
  `wave_0_complete: true` at planning time (it does, per current frontmatter),
  101-02's finalization is mostly adding the `## Commands Actually Used`
  section with the focused-bundle commands actually executed in 101-01,
  plus reconciling the `Status` column from `planned` to the executed verdict.

### Milestone authority boundary

- **D-17:** Phase 101 MUST NOT modify `.planning/REQUIREMENTS.md`,
  `.planning/ROADMAP.md`, or `.planning/STATE.md`. The `PROOF-01` row in
  REQUIREMENTS.md will remain `Pending` in those files after Phase 101 ships;
  Phase 103 owns the milestone-authority reconciliation that flips it.
- **D-18:** The `## Not closed here` section in `96-VERIFICATION.md` mirrors
  Phase 100's boilerplate: three bullets naming REQUIREMENTS.md / ROADMAP.md /
  STATE.md as intentionally unreconciled, plus a closing line:
  "Phase 101 closes the missing Phase 96 verification and validation chain
  only; milestone authority-surface reconciliation remains Phase 103 work."

### Claude's Discretion

- Exact prose wording inside each band's bullet list, as long as the
  PASS/FAIL block and the cited test/grep command are explicit.
- Exact ordering of the four bands within the artifact, as long as the
  Write-contract band precedes the Read-contract band and Phoenix-optional
  is positioned to read as a holistic boundary claim.
- Exact `## Commands Actually Used` formatting in `96-VALIDATION.md`, as
  long as it lists every command executed in 101-01 verbatim with its
  observed result.
- Whether to break the structural grep into one rg invocation or two (for
  module-reference vs runtime-call patterns), as long as the negative
  assertion is unambiguous.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 101 closure target — Phase 96 boundary

- `.planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md` — locked write/read/defaults/provenance/Phoenix-optional decisions from Phase 96 (D-01 through D-21)
- `.planning/phases/96-evidence-persistence-and-public-api/96-RESEARCH.md` — Phase 96 contract rationale and library-shape decisions
- `.planning/phases/96-evidence-persistence-and-public-api/96-PATTERNS.md` — Phase 96 file-to-pattern map
- `.planning/phases/96-evidence-persistence-and-public-api/96-01-PLAN.md` — write-side helper plan
- `.planning/phases/96-evidence-persistence-and-public-api/96-02-PLAN.md` — read-side helper plan
- `.planning/phases/96-evidence-persistence-and-public-api/96-01-SUMMARY.md` — write-side execution summary
- `.planning/phases/96-evidence-persistence-and-public-api/96-02-SUMMARY.md` — read-side execution summary (records pre-existing `mix verify.test` alias-drift outside Phase 96 ownership)
- `.planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md` — Phase 96 validation contract; 101-02 finalizes this artifact with the `## Commands Actually Used` section and authoritative-band reconciliation (per D-06)

### Phase 100 — direct structural template

- `.planning/phases/100-phase-95-verification-backfill/100-RESEARCH.md` — narrow-rerun-bundle posture, smallest-literal-repair posture, Phase 103 deferral
- `.planning/phases/100-phase-95-verification-backfill/100-PATTERNS.md` — verification/validation artifact analog mapping (use this same mapping pattern for Phase 101)
- `.planning/phases/100-phase-95-verification-backfill/100-01-PLAN.md` — re-verification plan shape
- `.planning/phases/100-phase-95-verification-backfill/100-02-PLAN.md` — artifact-writing plan shape
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VERIFICATION.md` — exact-shape template for `96-VERIFICATION.md` (frontmatter, preflight, numbered bands, requirement closure, "Not closed here")
- `.planning/phases/89-contract-lock-final-verification/89-VALIDATION.md` — exact-shape template for the modernized `96-VALIDATION.md` (`nyquist_compliant: true`, sampling rate, per-task verification map, `## Commands Actually Used`, sign-off)
- `.planning/phases/99-contract-lock-docs-and-final-verification/99-VERIFICATION.md` — supplementary VERIFICATION shape for per-band PASS/FAIL block conventions

### Milestone authority surfaces (READ ONLY — must not write to these in Phase 101)

- `.planning/ROADMAP.md` — Phase 101 goal at line 99, PROOF-01 mapping
- `.planning/REQUIREMENTS.md` — `PROOF-01` definition (line 16) and Traceability row (line 57)
- `.planning/STATE.md` — current milestone state, "Phase 100 complete (2/2) — ready to discuss Phase 101"
- `.planning/v1.22-MILESTONE-AUDIT.md` — `PROOF-01` audit finding at line 33, `mix verify.test` alias-drift tech-debt note at line 66

### Current-tree implementation surfaces (the truth Phase 101 verifies)

- `lib/threadline/evidence.ex` — `Threadline.Evidence` public context with the six `record_*` helpers, history reads, latest helpers
- `lib/threadline/evidence/subject.ex` — closed supported-subject inventory enforced by Phase 96 write helpers
- `lib/threadline/governance/evidence_record.ex` — append-only schema behind the public context
- `lib/threadline/governance/migration.ex` — install-path migration generation
- `priv/repo/migrations/20260525210000_threadline_evidence_records.exs` — checked-in forward migration

### Current-tree test surfaces (the focused rerun bundle)

- `test/threadline/evidence_test.exs` — public-context create/read tests (primary Phase 96 proof surface)
- `test/threadline/governance/evidence_record_test.exs` — schema and append-only test surface

### Project-level reference docs

- `prompts/audit-lib-domain-model-reference.md` — three-layer architecture (capture / semantics / exploration); Phase 96 lives in the semantics layer
- `prompts/threadline-elixir-oss-dna.md` — verify.* / ci.* alias conventions, doc-contract test posture
- `CLAUDE.md` — domain language (AuditTransaction / AuditChange / AuditAction / etc.), build commands, CI conventions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Threadline.Evidence` (`lib/threadline/evidence.ex`) — already exists with the
  six subject-focused `record_*` helpers, generic `list_history`, history-by-
  subject helpers, `latest_*` singular helpers, and `list_latest_*` list
  helpers. Phase 101 verifies this surface; it does not add to it.
- `Threadline.Evidence.Subject` (`lib/threadline/evidence/subject.ex`) — already
  enforces the closed supported-subject inventory. The Write-contract band
  cites this module as the boundary validator.
- `Threadline.Governance.EvidenceRecord` (`lib/threadline/governance/evidence_record.ex`)
  — already provides the append-only schema. The Read-contract band cites
  this as the canonical truth surface for the `latest_*` projection claim.

### Established Patterns

- The Phase 100 artifact pair (`95-VERIFICATION.md` + finalized
  `95-VALIDATION.md`) is the structural template. Mirror its frontmatter,
  preflight section, numbered-band shape, requirement-closure table, and
  "Not closed here" section verbatim for Phase 96 (with the band count
  expanded from 3 to 4 per D-03).
- Phase 100's per-task verification map in `100-VALIDATION.md` and the
  `100-01-PLAN.md` / `100-02-PLAN.md` pair are the structural template for
  101-01 and 101-02.
- Threadline's `verify.*` and `ci.*` aliases are owned by Phase 99 and
  recently corrected in commit `b636c17`. Phase 101 disclaims alias-topology
  concerns in the band authority statement rather than touching them.

### Integration Points

- Phase 101 outputs land at:
  - `.planning/phases/96-evidence-persistence-and-public-api/96-VERIFICATION.md` (NEW)
  - `.planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md` (UPDATE)
- Phase 102 and Phase 103 read these artifacts as inputs:
  - Phase 102 (SURF backfill) — reuses the same verification-backfill structural
    template; Phase 101's output is the second reference example after Phase 100.
  - Phase 103 (authority-surface reconciliation) — consumes the
    `PROOF-01` closure row from `96-VERIFICATION.md` when updating
    `.planning/REQUIREMENTS.md` Traceability and `.planning/STATE.md`.
- The `Threadline.Evidence` contract verified here is also consumed downstream
  by Phase 97 (Mix-task parity) and Phase 98 (mounted `/audit`), both of which
  already have passing verification artifacts in their own phase dirs.

</code_context>

<specifics>
## Specific Ideas

- The four band sections should mirror the band-titling convention from
  Phase 100's `95-VERIFICATION.md` (e.g., `## 1. Dedicated append-only
  evidence primitive`). Candidate titles:
  1. `## 1. Threadline.Evidence public context and subject-focused write helpers`
  2. `## 2. Append-only read contract — history, latest, and list_latest semantics`
  3. `## 3. Mechanical-only defaults and explicit provenance contract`
  4. `## 4. Phoenix-optional install and no-ambient-state boundary`
- The exact phrasing for the PROOF-01 closure-table row should follow the
  Phase 100 prose pattern: "Threadline still exposes a Phoenix-optional
  `Threadline.Evidence` public context with subject-focused create helpers
  for the closed Phase 95 subject set, append-only history reads, and
  list-vs-singular latest projections, with all defaults remaining mechanical
  and no ambient runtime state in the read or write path."
- The "Not closed here" section closing line: "Phase 101 closes the missing
  Phase 96 verification and validation chain only; milestone authority-surface
  reconciliation remains Phase 103 work."

</specifics>

<deferred>
## Deferred Ideas

- Behavioral test that poisons `Process.put` / `Logger.metadata` / `Process.get`
  and asserts `Threadline.Evidence` ignores them — intentionally not added in
  Phase 101 (structural grep + arity citation is the chosen proof method;
  see D-08, D-10).
- Repairing the `mix verify.test` alias-drift — owned by Phase 99; commit
  `b636c17` is the most recent fix. Phase 101 disclaims and moves on.
- Updating `.planning/REQUIREMENTS.md` `PROOF-01` row from `Pending` to
  `Complete` — Phase 103 work.
- Updating `.planning/ROADMAP.md` Phase 101 plan checkboxes to `[x]` — Phase
  103 / milestone closeout work.
- Updating `.planning/STATE.md` to reflect Phase 101 closure — Phase 103 work.
- Adding root-level `Threadline.*` delegates for any `Threadline.Evidence`
  helper — already deferred by Phase 96 (96-CONTEXT D-02), still deferred.
- Phase 102 (SURF backfill) and Phase 103 (authority-surface reconciliation)
  follow Phase 101 directly — not in this phase's scope.

</deferred>

---

*Phase: 101-phase-96-verification-backfill*
*Context gathered: 2026-05-27*
