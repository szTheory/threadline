# Phase 102: Phase 98 Verification Backfill - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 102 is a verification-backfill phase that closes the missing Phase 98
proof chain. The implementation Phase 98 was supposed to deliver — the mounted
`/audit/evidence` LiveView, shared-presenter parity with `Threadline.Evidence.Proof`,
and the host-owned `evidence_authorize_fn` gate — already exists on the current
tree. What is missing is `98-VERIFICATION.md` and a Nyquist-final
`98-VALIDATION.md`, so `SURF-01`, `SURF-02`, and `SURF-03` remain pending only
because the closure chain was not written.

Phase 102 does NOT redesign the mounted evidence surface, does NOT add new
UI affordances, does NOT introduce new tests beyond what Phase 98 already
shipped, and does NOT touch milestone authority surfaces. The structural
parallel is Phases 100 and 101, which just closed the same gap for Phases 95
and 96.

Two plans:
- **102-01** — re-verify the current tree against the Phase 98 contract and
  make only the smallest literal-truth repair if a mismatch is found.
- **102-02** — write `98-VERIFICATION.md` and finalize `98-VALIDATION.md` with
  the executed commands, Nyquist sign-off, and an explicit retroactive-backfill
  note (per Phase 101 D-16 "merge-theater" guard).

</domain>

<decisions>
## Implementation Decisions

### Verification artifact structure

- **D-01:** `98-VERIFICATION.md` uses the same frontmatter shape Phases 100 and
  101 produced for `95-VERIFICATION.md` and `96-VERIFICATION.md`: `phase`,
  `verified`, `status`, `score`, `overrides_applied`.
- **D-02:** The artifact opens with a `## Current-tree preflight` section that
  states the working tree is the authority, names the missing-artifact gap
  being closed, and explicitly disclaims any milestone authority-surface
  changes (those remain Phase 103 work).
- **D-03:** Band structure — **3 numbered bands, 1:1 with SURF-01 / SURF-02 /
  SURF-03**, each with its own `**Requirement:**` line and `**Result:** PASS`
  block. This mirrors Phase 100's "N requirements → N bands" pattern (Phase 96
  used 4 bands only because it had a single `PROOF-01` row covering four
  contract surfaces — not a template to copy when requirements are already
  plural).
  1. **Band 1 — SURF-01: Read-only `/audit/evidence` mount inside the existing
     operator family.** The route lives as a sibling in `/audit`, no new UI
     family is introduced, the LiveView defines no mutation handlers.
  2. **Band 2 — SURF-02: Mounted parity through the shared
     `Threadline.Evidence.Proof` presenter and locked Phase 98 copy literals.**
     The mounted UI presents the same evidence facts and verdict vocabulary
     (`proven`, `inferred_posture`, `unsupported`) as the library API and
     Mix-task paths.
  3. **Band 3 — SURF-03: Host-owned authorization gate via
     `evidence_authorize_fn`, with no Threadline-owned RBAC, tenant DSL, or
     persona semantics.** The default callback fails closed.
- **D-04:** The artifact closes with a `## Requirement closure` table (one row
  each for `SURF-01`, `SURF-02`, `SURF-03`) and a `## Not closed here` section
  (REQUIREMENTS.md / ROADMAP.md / STATE.md deferred to Phase 103; visual
  hierarchy and design-token parity from `98-UI-SPEC.md` remain Manual-Only
  per `98-VALIDATION.md`).

### Proof method per band — mixed (structural primary for negatives,
behavioral primary for positives)

Each band picks the strongest available proof method for its specific claim
shape. Negative/absence claims use structural grep with positive-control
pairing so a typo'd path fails loudly. Positive/behavior claims use the
existing Phase 98 test suite as authority. This adapts Phase 101's D-08–D-10
mixed posture to a LiveView surface that already has 34 passing tests.

- **D-05:** **Band 1 (SURF-01)** proof bundle:
  - Structural (primary, mount-shape): `rg -n 'live\("/evidence"' lib/threadline/operator_surface/router.ex`
    — expect exactly one match, inside the existing `live_session :threadline`
    block (sibling-route mount on the canonical `/audit` family).
  - Structural (primary, read-only): `rg -n '^\s*def handle_event' lib/threadline/operator_surface/live/evidence_live.ex`
    — expect zero matches (no mutation handlers defined).
  - Arity citation: `EvidenceLive` defines only `mount/3`, `handle_params/3`,
    `render/1` — no `handle_event/3`.
  - Behavioral (supporting): `mix test test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1`.
- **D-06:** **Band 2 (SURF-02)** proof bundle:
  - Structural (primary, shared presenter): `rg -n 'alias Threadline\.Evidence\.Proof|Proof\.present_record' lib/threadline/operator_surface/live/evidence_live.ex`
    — expect matches confirming the LiveView aliases the shared presenter
    and calls `Proof.present_record/1` rather than maintaining a local
    reducer or duplicated truth model.
  - Structural (primary, locked literals from `98-UI-SPEC.md`): `rg -nF`
    against `lib/threadline/operator_surface/live/evidence_live.ex` and
    `lib/threadline/operator_surface/unsupported.ex` for each locked Phase 98
    copy literal — see D-12.
  - Behavioral (primary, vocabulary in rendered HTML): `mix test test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1`
    — asserts verdict vocabulary, "View history", empty-state, denied-state
    copy at the cited test lines (see D-12).
- **D-07:** **Band 3 (SURF-03)** proof bundle:
  - Structural (primary, negative — no Threadline RBAC): `rg -n 'Threadline\.RBAC|Threadline\.Permissions|Threadline\.Policy\.RBAC' lib/threadline/operator_surface/`
    — expect zero matches. PAIRED with a positive-control grep to prevent
    silent-pass on path typo.
  - Structural (positive control / anchor): `rg -n 'evidence_authorize_fn' lib/threadline/operator_surface/auth.ex`
    — expect matches around line 254 (`defp assign_evidence_enabled`) including
    the fail-closed default `Keyword.get(opts, :evidence_authorize_fn, fn _ -> false end)`.
  - Arity citation: `evidence_authorize_fn` is a host-supplied function value
    of shape `(%{assigns: map()} -> boolean | :ok | {:ok, scope} | _)` —
    callback shape only, no Threadline-owned module dispatch or behaviour
    implementation.
  - Behavioral (primary, fail-closed denial path): `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1`.

### Rerun bundle and authority

- **D-08:** The authoritative Phase 98 rerun bundle is the focused two-file
  band already named in `98-VALIDATION.md` Quick run command:
  ```
  mix test test/threadline/operator_surface/auth_test.exs \
           test/threadline/operator_surface/live/evidence_live_test.exs \
           --max-failures 1
  ```
  Current-tree result: **PASS — 34 tests, 0 failures.** This matches Phase 101
  D-05's narrowing posture and avoids broader repo-health noise outside the
  Phase 98 contract.
- **D-09:** The two-file coupling is intentional: `auth_test.exs` owns the
  SURF-03 capability-boolean fan-out at unit scope, while `evidence_live_test.exs`
  owns the SURF-01 mount and SURF-02 parity at LiveView scope. The artifact's
  authority statement must call out that this unit-plus-LiveView coupling is
  the contract under verification, not incidental.
- **D-10:** `mix verify.test` is intentionally NOT named as the authority
  bundle. Disclaimer mirrors Phase 101 D-07 verbatim:
  > A pre-existing `mix verify.test` alias-drift failure is outside Phase 98
  > ownership; Phase 99 owns the named-alias topology, and commit `b636c17`
  > ("fix(99-02): update ci.all topology contract to expanded doc_contract
  > alias") is the most recent fix on that surface. Phase 102 disclaims rather
  > than reopens that scope.
  If 102-01 finds the drift has been repaired post-commit `b636c17`, update
  the disclaimer to cite the newer fix but keep the disclaimer shape.

### UI-SPEC handling — locked literals only

- **D-11:** `98-UI-SPEC.md` is a Band 2 authority **scoped strictly to
  mechanically-verifiable copy literals already present in
  `evidence_live.ex` + tests**. Visual hierarchy, spacing tokens
  (4/8/16/24/32/48px), typography sizing, color palette adherence, and
  scanability remain Manual-Only per `98-VALIDATION.md` and are explicitly
  named in the artifact's "Not closed here" section so a future reviewer
  does not try to grep visual claims. Phase 84-VERIFICATION (Band 2 cites
  `84-UI-SPEC.md` alongside lib/test paths) is the internal precedent for
  this shape.
- **D-12:** The locked copy-literal inventory for Band 2 — each literal is
  verified by `rg -nF` against the cited source location AND by a behavioral
  test assertion at the cited test line:

  | UI-SPEC literal | UI-SPEC line | Source location | Test assertion |
  |---|---|---|---|
  | `What can Threadline prove right now?` | 87 | `lib/threadline/operator_surface/live/evidence_live.ex:67` | `test/threadline/operator_surface/live/evidence_live_test.exs:115,150` |
  | Verdict triple `proven` / `inferred_posture` / `unsupported` | 88 | `lib/threadline/operator_surface/live/evidence_live.ex:116-118` | `test/threadline/operator_surface/live/evidence_live_test.exs:153-155` |
  | `View history` primary CTA | 79 | `lib/threadline/operator_surface/live/evidence_live.ex:142` | `test/threadline/operator_surface/live/evidence_live_test.exs:152` |
  | `No evidence records yet` empty-state heading | 81 | `lib/threadline/operator_surface/live/evidence_live.ex:89-95` | `test/threadline/operator_surface/live/evidence_live_test.exs:213` |
  | `Evidence view unavailable.` denied-state heading | 82 | `lib/threadline/operator_surface/unsupported.ex` via `evidence_live.ex:154` | `test/threadline/operator_surface/live/evidence_live_test.exs:113` |

  If 102-01 finds drift between any UI-SPEC literal and the source/test
  location, the smallest literal-truth repair (per D-17) is to update the
  source/test to match the UI-SPEC, NOT to relax the UI-SPEC. The UI-SPEC is
  the design contract; the code is the realization.

### Requirement closure layout

- **D-13:** The `## Requirement closure` table renders SURF-01, SURF-02, and
  SURF-03 as **three separate rows**, one prose sentence each, with the
  closing band citation in the Evidence column. This matches Phase 100's
  three-row layout for `EVID-01/02/03` and aligns with the three separate
  rows in `.planning/REQUIREMENTS.md` Traceability table (Phase 102 column).

### Finalization honesty (per Phase 101 D-16)

- **D-14:** Flipping `98-VALIDATION.md` to `nyquist_compliant: true` +
  `wave_0_complete: true` is **retroactive backfill, not original Wave 0
  execution**. The finalized validation artifact MUST include a one-line note
  in the validation strategy section making this explicit (e.g., "Wave 0
  evidence reconstructed retroactively from the current tree as part of Phase
  102; original Phase 98 execution did not produce a Nyquist-compliant
  artifact"). Without this note the frontmatter flip reads as merge-theater.
- **D-15:** The new `## Commands Actually Used` section lands immediately
  after the Per-Task Verification Map and before the Wave 0 Requirements
  section, mirroring `95-VALIDATION.md:54` and `96-VALIDATION.md:54`. Exact
  shape:
  ```markdown
  ## Commands Actually Used

  1. `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1`
     Result: PASS (`34 tests, 0 failures`)
  ```
  Single numbered entry (Phase 101's three entries reflected its grep +
  closed-set proofs; Phase 102's structural greps live in
  `98-VERIFICATION.md`, not the validation command ledger).

### Repair posture

- **D-16:** 102-01 makes only the smallest literal-truth repair if a mismatch
  is found. Allowed examples: updating the Quick run command line in
  `98-VALIDATION.md` from naming `mix verify.test` as the Full suite command
  to the focused band, fixing a stale `evidence_live.ex` line reference in
  the UI-SPEC literal map (D-12), correcting a typo in the per-task
  verification map. Not allowed: adding new tests, renaming public functions,
  expanding the SURF-XX requirement wording, restructuring the UI-SPEC.
- **D-17:** If a UI-SPEC literal (D-12) does not appear at the cited source
  line, the smallest repair is to update the source code to render the
  UI-SPEC's locked literal — NOT to update the UI-SPEC. The UI-SPEC is the
  design contract.
- **D-18:** If `98-VALIDATION.md` "Full suite command" still names
  `mix verify.test` at planning time (it does — confirmed during context
  gathering), 102-01's smallest repair replaces that line with the focused
  band per D-08.

### Milestone authority boundary

- **D-19:** Phase 102 MUST NOT modify `.planning/REQUIREMENTS.md`,
  `.planning/ROADMAP.md`, or `.planning/STATE.md`. The `SURF-01`, `SURF-02`,
  and `SURF-03` rows in REQUIREMENTS.md will remain `Pending` in those files
  after Phase 102 ships; Phase 103 owns the milestone-authority
  reconciliation that flips them.
- **D-20:** The `## Not closed here` section in `98-VERIFICATION.md` mirrors
  Phases 100 and 101's boilerplate: three bullets naming REQUIREMENTS.md /
  ROADMAP.md / STATE.md as intentionally unreconciled, one bullet naming the
  visual/spacing/color portions of `98-UI-SPEC.md` as Manual-Only, plus a
  closing line:
  > "Phase 102 closes the missing Phase 98 verification and validation chain
  > only; milestone authority-surface reconciliation remains Phase 103 work."

### Claude's Discretion

- Exact prose wording inside each band's bullet list, as long as the
  PASS/FAIL block and the cited test/grep command are explicit.
- Exact ordering of the three bands within the artifact, as long as the
  ordering reads as SURF-01 → SURF-02 → SURF-03 to match the closure table
  and REQUIREMENTS.md Traceability sequence.
- Whether to render the locked-literal table (D-12) verbatim inside Band 2 or
  inline each row as a separate Result bullet, as long as every literal is
  paired with both a structural and behavioral citation.
- Exact `## Commands Actually Used` numbering if 102-01's repair adds
  additional commands actually executed (e.g., re-running after a literal
  repair), as long as each entry lists the command verbatim with observed
  result.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 102 closure target — Phase 98 boundary

- `.planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md` — locked
  Phase 98 implementation decisions: D-01/D-03 (canonical `/audit/evidence`
  mount), D-10/D-11/D-13 (shared-presenter parity), D-14/D-15/D-16/D-17
  (host-owned gate, unsupported-state posture), D-18/D-19 (thin LiveView,
  URL-driven state)
- `.planning/phases/98-mounted-evidence-views-on-audit/98-UI-SPEC.md` —
  **Locked copy contract for SURF-02 verdict vocabulary, primary CTA,
  empty-state, and denied-state literals.** Cited by Band 2 for the five
  mechanically-verifiable copy literals only (per D-11, D-12); visual
  hierarchy, spacing tokens, typography, and color palette remain Manual-Only
  per `98-VALIDATION.md`.
- `.planning/phases/98-mounted-evidence-views-on-audit/98-RESEARCH.md` —
  Phase 98 mounted-surface research and parity rationale
- `.planning/phases/98-mounted-evidence-views-on-audit/98-PATTERNS.md` —
  Phase 98 file-to-pattern map
- `.planning/phases/98-mounted-evidence-views-on-audit/98-01-PLAN.md` —
  mounted navigation plan (SURF-01, SURF-02 origins)
- `.planning/phases/98-mounted-evidence-views-on-audit/98-02-PLAN.md` —
  parity + host-owned auth wiring plan (SURF-02, SURF-03 origins)
- `.planning/phases/98-mounted-evidence-views-on-audit/98-01-SUMMARY.md` —
  mounted-navigation execution summary
- `.planning/phases/98-mounted-evidence-views-on-audit/98-02-SUMMARY.md` —
  parity + auth-wiring execution summary
- `.planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md` —
  Phase 98 validation contract; 102-02 finalizes this artifact with the
  `## Commands Actually Used` section (per D-15), the focused-bundle authority
  swap (per D-18), retroactive-backfill note (per D-14), and frontmatter flip
  to `nyquist_compliant: true` + `wave_0_complete: true`

### Phases 100 and 101 — direct structural templates

- `.planning/phases/100-phase-95-verification-backfill/100-RESEARCH.md` —
  narrow-rerun-bundle posture, smallest-literal-repair posture, Phase 103
  deferral
- `.planning/phases/100-phase-95-verification-backfill/100-PATTERNS.md` —
  verification/validation artifact analog mapping (Phase 102 reuses this
  mapping pattern)
- `.planning/phases/100-phase-95-verification-backfill/100-01-PLAN.md` —
  re-verification plan shape (template for 102-01)
- `.planning/phases/100-phase-95-verification-backfill/100-02-PLAN.md` —
  artifact-writing plan shape (template for 102-02)
- `.planning/phases/100-phase-95-verification-backfill/100-VERIFICATION.md` —
  exact-shape template for `98-VERIFICATION.md` (frontmatter, preflight,
  numbered bands, requirement closure table, "Not closed here" section,
  Behavioral Spot-Checks table)
- `.planning/phases/101-phase-96-verification-backfill/101-CONTEXT.md` —
  mixed-posture proof-method rationale (D-08, D-09, D-10), retroactive-backfill
  honesty (D-16), `mix verify.test` disclaimer pattern (D-07), narrow-rerun
  posture (D-05, D-06)
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VERIFICATION.md` —
  3-band, 1:1-requirement template (the closest structural analog for Phase
  102's 3-band SURF mapping)
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VALIDATION.md` —
  exact-shape template for the modernized `98-VALIDATION.md`
  (`nyquist_compliant: true`, sampling rate, per-task verification map,
  `## Commands Actually Used`, sign-off)
- `.planning/phases/96-evidence-persistence-and-public-api/96-VERIFICATION.md` —
  supplementary structural-grep band shape (for negative assertions)

### Prior UI-SPEC verification precedent

- `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-VERIFICATION.md` —
  Band 2 cites `84-UI-SPEC.md` alongside lib/test paths for locked copy
  literals. **This is the prior internal precedent for Phase 102's D-11
  scoped-literals approach.** Phase 102 mirrors this pattern.

### Milestone authority surfaces (READ ONLY — must not write to these in Phase 102)

- `.planning/ROADMAP.md` — Phase 102 goal at line 110, SURF-01/02/03 mapping
- `.planning/REQUIREMENTS.md` — `SURF-01` / `SURF-02` / `SURF-03` definitions
  and Traceability rows
- `.planning/STATE.md` — current milestone state
- `.planning/v1.22-MILESTONE-AUDIT.md` — `SURF-01` / `SURF-02` / `SURF-03`
  audit findings; tech-debt note on `98-VALIDATION.md` draft state

### Current-tree implementation surfaces (the truth Phase 102 verifies)

- `lib/threadline/operator_surface/router.ex` — `/audit/evidence` sibling-route
  mount at line 100, inside the `live_session :threadline` block
- `lib/threadline/operator_surface/live/evidence_live.ex` — the mounted
  LiveView: `mount/3`, `handle_params/3`, `render/1` only (no `handle_event/3`)
- `lib/threadline/operator_surface/auth.ex` — `assign_evidence_enabled/2` and
  `evidence_authorize_fn` fail-closed default at line 254
- `lib/threadline/operator_surface/unsupported.ex` — denied-state copy source
  for the `Evidence view unavailable.` literal (D-12)
- `lib/threadline/evidence.ex` — `Threadline.Evidence` public context (the
  library-side truth the mounted view presents)
- `lib/threadline/evidence/proof.ex` — `Threadline.Evidence.Proof` shared
  presenter; the SURF-02 parity hinge

### Current-tree test surfaces (the focused rerun bundle)

- `test/threadline/operator_surface/auth_test.exs` — SURF-03 capability-boolean
  fan-out at unit scope
- `test/threadline/operator_surface/live/evidence_live_test.exs` — SURF-01
  mount, SURF-02 parity, SURF-03 denied-path at LiveView scope; 34 tests
  passing on the current tree

### Project-level reference docs

- `prompts/audit-lib-domain-model-reference.md` — three-layer architecture
  (capture / semantics / exploration); Phase 98 lives in the exploration layer
- `prompts/threadline-elixir-oss-dna.md` — verify.* / ci.* alias conventions,
  doc-contract test posture, honest-default tests posture
- `CLAUDE.md` — domain language, build commands, CI conventions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Threadline.OperatorSurface.Live.EvidenceLive`
  (`lib/threadline/operator_surface/live/evidence_live.ex`) — already exists as
  a read-only thin LiveView over `Threadline.Evidence.Proof`. Phase 102
  verifies this surface; it does not add to it. Confirmed `mount/3`,
  `handle_params/3`, `render/1` only — no mutation handlers.
- `Threadline.OperatorSurface.Auth.assign_evidence_enabled/2`
  (`lib/threadline/operator_surface/auth.ex:253`) — host-owned gate with
  fail-closed default (`fn _ -> false end`) at line 254. Band 3 cites this as
  the boundary.
- `Threadline.Evidence.Proof.present_record/1`
  (`lib/threadline/evidence/proof.ex`) — shared presenter used by the
  LiveView, Mix-task, and JSON paths. Band 2 cites the LiveView's `alias` and
  call sites as the parity hinge.
- `Threadline.OperatorSurface.Unsupported`
  (`lib/threadline/operator_surface/unsupported.ex`) — denied-state copy
  source; carries the `Evidence view unavailable.` literal (D-12).
- `test/threadline/operator_surface/live/evidence_live_test.exs` — already
  asserts the locked copy literals at lines 113, 115, 150, 152-155, 213. No
  new test work needed in Phase 102.
- `test/threadline/operator_surface/auth_test.exs` — already exercises the
  evidence capability fan-out at unit scope.

### Established Patterns

- Phase 100's verification artifact (`95-VERIFICATION.md` + finalized
  `95-VALIDATION.md`) is the closest structural template — 3 requirements,
  3 bands, narrow rerun bundle, retroactive Wave 0 finalization. Mirror its
  frontmatter, preflight section, numbered-band shape, requirement-closure
  table, and "Not closed here" section verbatim, with SURF-01/02/03
  substituted for EVID-01/02/03.
- Phase 101's mixed proof-method posture (D-08/D-09/D-10) is the closest
  template for combining structural grep with behavioral tests within a
  single band. Phase 102 extends this from "Phoenix-optional" to a LiveView
  surface, but the rule is the same: structural primary for negative claims,
  behavioral primary for positive claims, pair negative greps with positive
  controls so path typos fail loudly.
- Phase 84-VERIFICATION (Band 2) is the internal precedent for citing a
  UI-SPEC document at band-authority level for locked copy literals while
  scoping out visual/design intent.
- Threadline's `verify.*` and `ci.*` aliases are owned by Phase 99 and
  recently corrected in commit `b636c17`. Phase 102 disclaims alias-topology
  concerns in the band authority statement rather than touching them.

### Integration Points

- Phase 102 outputs land at:
  - `.planning/phases/98-mounted-evidence-views-on-audit/98-VERIFICATION.md` (NEW)
  - `.planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md` (UPDATE: Commands Actually Used + retroactive-backfill note + frontmatter flip + focused-bundle authority swap)
- Phase 103 reads these artifacts as inputs:
  - Consumes the `SURF-01` / `SURF-02` / `SURF-03` closure rows from
    `98-VERIFICATION.md` when updating `.planning/REQUIREMENTS.md` Traceability,
    `.planning/STATE.md`, and `.planning/ROADMAP.md` Phase 102 checkboxes.
- The Phase 98 mounted surface verified here is also consumed downstream by
  Phase 99 (already shipped contract-lock + final verification), which is why
  the SURF closure can land cleanly without touching Phase 99 artifacts.

</code_context>

<specifics>
## Specific Ideas

- The three band sections should mirror the band-titling convention from
  Phase 100's `95-VERIFICATION.md` (e.g., `## 1. Dedicated append-only
  evidence primitive`). Candidate titles:
  1. `## 1. Read-only /audit/evidence mount inside the existing operator family`
  2. `## 2. Mounted parity through Threadline.Evidence.Proof and locked copy literals`
  3. `## 3. Host-owned evidence_authorize_fn gate with no Threadline RBAC`
- The exact phrasing for each SURF closure-table row should follow the
  Phase 100 prose pattern. Suggested prose:
  - **SURF-01:** "Threadline mounts the read-only evidence surface as a
    sibling route inside the existing `/audit` operator family, with no new
    UI family, no mutation handlers, and URL-driven navigation via
    `handle_params/3`."
  - **SURF-02:** "The mounted view presents the same evidence facts and
    verdict vocabulary (`proven`, `inferred_posture`, `unsupported`) as the
    library API and Mix-task paths via the shared
    `Threadline.Evidence.Proof` presenter, with the locked Phase 98 copy
    literals (per `98-UI-SPEC.md` Copywriting Contract) rendered at the
    cited source lines and asserted by the existing LiveView test suite."
  - **SURF-03:** "Host-owned authorization remains the gate via
    `evidence_authorize_fn`, defaulting fail-closed to
    `fn _ -> false end`, with no Threadline-owned RBAC, tenant DSL, or
    persona semantics introduced in `lib/threadline/operator_surface/`."
- The "Not closed here" section closing line: "Phase 102 closes the missing
  Phase 98 verification and validation chain only; milestone authority-surface
  reconciliation remains Phase 103 work, and visual/spacing/color portions of
  `98-UI-SPEC.md` remain Manual-Only."

</specifics>

<deferred>
## Deferred Ideas

- Visual hierarchy, spacing tokens (4/8/16/24/32/48px), typography sizing,
  color palette adherence, and scanability of the focal-block sequence in
  `98-UI-SPEC.md` — Manual-Only per `98-VALIDATION.md`. Phase 102 does NOT
  attempt to grep visual or design-token claims; these are not
  code-anchorable from this surface.
- Adding a behavioral test that exhaustively poisons every host capability
  boolean to verify `assign_evidence_enabled` ignores adjacent capabilities
  — intentionally not added in Phase 102 (verification-backfill posture, no
  widening). The existing `auth_test.exs` coverage is sufficient.
- Repairing the `mix verify.test` alias-drift — owned by Phase 99; commit
  `b636c17` is the most recent fix. Phase 102 disclaims and moves on.
- Updating `.planning/REQUIREMENTS.md` `SURF-01` / `SURF-02` / `SURF-03` rows
  from `Pending` to `Complete` — Phase 103 work.
- Updating `.planning/ROADMAP.md` Phase 102 plan checkboxes to `[x]` —
  Phase 103 / milestone closeout work.
- Updating `.planning/STATE.md` to reflect Phase 102 closure — Phase 103
  work.
- Adding root-level `Threadline.*` delegates or new evidence helpers —
  already deferred by Phase 96 (96-CONTEXT D-02), still deferred.
- Phase 103 (authority-surface reconciliation and milestone re-audit)
  follows Phase 102 directly — not in this phase's scope.

</deferred>

---

*Phase: 102-phase-98-verification-backfill*
*Context gathered: 2026-05-27*
