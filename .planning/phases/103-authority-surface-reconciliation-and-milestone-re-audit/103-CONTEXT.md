# Phase 103: Authority-Surface Reconciliation And Milestone Re-Audit - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Reconcile v1.22's active authority surfaces with the repaired evidence-plane
status from Phases 100/101/102, then re-run milestone closeout readiness on
the current tree. This is a truth-repair and closeout-gate phase, not a new
feature phase. It moves planning surfaces and the milestone audit; it does
not change `lib/`, `test/`, or any public contract.

It does not widen the evidence-plane claim, invent new requirements, flip
v1.22 to "shipped" framing (that belongs to `/gsd-complete-milestone v1.22`
after this phase passes), or expand into release-ops theater.

Two plans:
- **103-01** — reconcile `.planning/ROADMAP.md`,
  `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, and the v1.22
  remaining-work / next-step sections of `.planning/PROJECT.md` so every
  active authority surface tells the same story as the repaired Phase
  100/101/102 verification chain.
- **103-02** — rerun the named v1.22 evidence bundle on the reconciled
  tree, then rerun `gsd-audit-milestone` in-place against
  `.planning/v1.22-MILESTONE-AUDIT.md` and confirm the verdict flips to
  closeout-ready. Write `103-VERIFICATION.md` + `103-VALIDATION.md` to
  Phase-94 shape.

The structural parallel for this phase is **Phase 94** for v1.21 closeout
(`.planning/phases/94-authority-surface-reconciliation-and-closeout/`).
Phase 103 follows Phase 94's split-authority hierarchy, bounded-truth-bundle
closeout bar, and `/gsd-complete-milestone`-as-archive-gate sequencing
one-for-one.

</domain>

<decisions>
## Implementation Decisions

### Authority-surface scope (103-01)

- **D-01:** Phase 103-01 reconciles exactly four authority surfaces in one
  pass: `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`,
  `.planning/STATE.md`, and the v1.22 remaining-work / next-step sections
  of `.planning/PROJECT.md`. This matches Phase 94's exact pattern (which
  bundled PROJECT current-state with the authority trio) and honors Phase 94
  D-16 ("STATE.md and the current-state sections of PROJECT.md should move
  in the same pass as the audit rerun when the 'what is left / what is
  next' story changes").
- **D-02:** Phase 103-01 MUST NOT touch:
  - `.planning/MILESTONE-ARC.md` (the `v1.22 | active` row stays "active"
    until the milestone genuinely ships at `/gsd-complete-milestone v1.22`)
  - `.planning/PROJECT.md` `Last shipped: v1.21` framing line and the
    "Current milestone: v1.22 ... opened 2026-05-25" framing
  - `.planning/MILESTONES.md`
  - `.planning/RETROSPECTIVE.md`
  - `.planning/milestones/v1.22-*` archive copies (these don't exist yet;
    `/gsd-complete-milestone v1.22` creates them)

  Phase 94 git precedent: commit `140a5c2 chore: archive v1.21 milestone
  files` flipped the "Last shipped" pointer and created the v1.21 archive
  copies only **after** Phase 94 closed. Phase 103 holds the same boundary
  for v1.22.

### Specific edits in 103-01

- **D-03:** `.planning/REQUIREMENTS.md`:
  - Flip the SURF-01, SURF-02, SURF-03 bullet checkboxes from `[ ]` to `[x]`
    (lines 21-23 in the current file).
  - Update the Traceability table rows for SURF-01, SURF-02, SURF-03 from
    `Pending` to `Complete` (lines 60-62). PROOF-01 row is already
    `Complete` in the table; reconfirm and leave as-is.
  - Update the `Last updated:` footer line to today's date with a short
    "after Phase 103 reconciled the SURF closure chain" note.
- **D-04:** `.planning/ROADMAP.md`: flip Phase 103 plan checkboxes
  `103-01` and `103-02` to `[x]` (lines 128-129) once the work is done.
  No other ROADMAP edits — Phase 100/101/102 are already `[x][x]`.
- **D-05:** `.planning/STATE.md`:
  - Update the yaml header `completed_phases: 7 → 9`, `completed_plans:
    14 → 16` (assuming 103 ships its own two plans), `percent: 78 → 100`
    once 103-02 closes. (103-01 may write an interim value; 103-02 flips
    the final.)
  - Update `last_activity` to today + Phase 103 closure summary.
  - Update `## Current Position` from "Phase 102 complete" to "Phase 103
    complete; v1.22 closeout-ready" (after 103-02 PASS).
  - Update `## Performance Metrics` from "8 of 12 satisfied" to "12 of 12
    satisfied" and remove the "PROOF-01, SURF-01, SURF-02, and SURF-03
    remain pending" clause.
  - Update `## Performance Metrics` `Milestone Readiness:` from "OPEN.
    v1.22 now depends on Phases 101-103..." to "CLOSEOUT-READY. v1.22
    cleared its final audit on `[date]` against the reconciled tree."
  - Append three `### Decisions` entries (one each for Phases 100, 101,
    102) plus one closing entry for Phase 103 itself — same multi-entry
    pattern Phase 94 used (Phase 94 added per-phase 90/91/92/93/94
    entries).
  - Update `## Session Continuity` `Next Step:` to "Run
    `/gsd-complete-milestone v1.22`".
  - Update `## Operator Next Steps` to "Run `/gsd-complete-milestone
    v1.22` to archive the v1.22 milestone".
- **D-06:** `.planning/PROJECT.md` (narrow narrative pass only):
  - Update any sentence under `## Current State` that still implies v1.22
    work is in flight (e.g., "Current planning focus: Ship durable
    policy/evidence records...") to reflect that v1.22 is closeout-ready,
    pending `/gsd-complete-milestone v1.22`.
  - Do **NOT** rewrite the "Last shipped: v1.21" line; do **NOT** add a
    "Last shipped: v1.22" entry; do **NOT** touch the
    "Latest Milestone Shipped" section. Those are
    `/gsd-complete-milestone`'s job.
  - Smallest possible diff that removes the contradiction between
    PROJECT's "remaining v1.22 work" narrative and STATE's repaired
    12/12 satisfied count.

### Audit artifact handling (103-02)

- **D-07:** Phase 103-02 **rewrites `.planning/v1.22-MILESTONE-AUDIT.md`
  in place** with the rerun verdict. One canonical milestone audit file
  per milestone — matches every prior milestone (v1.1–v1.21 each have
  exactly one audit file) and Phase 94's explicit "Rewrote the stale v1.21
  milestone audit" pattern. The historical `gaps_found` snapshot from
  2026-05-26 is preserved at git SHA precision and recoverable via
  `git show HEAD~:.planning/v1.22-MILESTONE-AUDIT.md`.
- **D-08:** The rewritten audit should preserve the same yaml frontmatter
  shape (`milestone`, `audited`, `status`, `scores`, `gaps`, `tech_debt`,
  `nyquist`) and body sections, with these expected deltas:
  - `status: gaps_found → status: closeout_ready` (or whatever the
    workflow's PASS verdict is named — confirm at runtime against the
    `gsd-audit-milestone` tool's actual output)
  - `scores.requirements: 5/12 → 12/12`
  - `scores.phases: 2/5 → 5/5` (or 9/9 if the tool now counts the
    backfill phases too; verify against tool behavior)
  - `gaps.requirements: [...] → []` (all seven previously-partial rows
    close)
  - `tech_debt.milestone-surfaces` row removed (Phase 103-01 closes it)
  - `tech_debt` rows for 97-VALIDATION nyquist follow-up and
    98-VALIDATION nyquist follow-up: removed only if Phases 100/101/102
    actually flipped those VALIDATION files to `nyquist_compliant: true`
    on disk — verify at runtime; if still draft, keep the rows
  - `nyquist.compliant_phases` / `partial_phases`: re-derived from the
    actual on-disk VALIDATION frontmatter
  - "Verified locally on `[date]`" stanza updated with the 103-02 rerun
    counts and date
- **D-09:** The rewritten audit's "Recommendation" section should change
  from the "Do not archive v1.22 yet" + 4-step list to a closeout-ready
  recommendation: "v1.22 is ready for `/gsd-complete-milestone v1.22`."

### Closeout-readiness rerun bar (103-02)

- **D-10:** The authoritative v1.22 closeout-readiness bundle is the
  three-command set the existing audit body already names at
  `.planning/v1.22-MILESTONE-AUDIT.md:142-145`:
  ```
  mix verify.doc_contract
  mix test test/threadline/evidence_test.exs \
           test/threadline/evidence/proof_test.exs \
           test/mix/tasks/threadline.evidence_show_test.exs \
           test/threadline/operator_surface/live/evidence_live_test.exs \
           test/threadline/operator_surface/auth_test.exs \
           --max-failures 1
  mix verify.example
  ```
  Expected baseline counts from the 2026-05-26 audit: `46 / 55 / 21
  tests, 0 failures`. If 103-02's rerun produces different counts, the
  artifact records the actual counts; only a regression (failures > 0 or
  visibly-broken seam) is a closeout blocker.
- **D-11:** After the three-command bundle passes on the reconciled
  tree, rerun `gsd-audit-milestone` (or `$gsd-audit-milestone`) and
  capture the new verdict per D-07 / D-08.
- **D-12:** `mix ci.all` is NOT the closeout authority. Phase 99 D-15
  explicitly disclaimed it because dirty-tree `verify.format`/credo
  noise muddies the milestone-truth signal. If a contributor wants to
  run it separately, that's fine; it doesn't gate Phase 103-02 closure.
- **D-13:** The bundle stays as the named-command set inside the audit
  body and `103-02-PLAN.md`. Do NOT promote it to a new `mix
  verify.closeout` alias — the integration-test list rotates per
  milestone (v1.21's bundle is `support-lane/timeline/export`, v1.22's
  is `evidence/proof/evidence_show/evidence_live/auth`), so a stable
  alias would either go stale or have to be rewritten per milestone,
  which defeats the bounded-truth-bundle discipline. The two reusable
  pieces (`mix verify.doc_contract`, `mix verify.example`) are already
  aliases — that's the right level of generalization.

### Phase 103's own artifacts

- **D-14:** Phase 103 produces its own `103-VERIFICATION.md` and
  `103-VALIDATION.md` to Phase-94 shape (Phase 94 produced both files;
  precedent is consistent with reconciliation/closeout phases owning
  their own proof chain). The 103-VERIFICATION.md must report:
  - **closeout_readiness:** green | yellow | red verdict line in the
    frontmatter, matching `94-VERIFICATION.md` frontmatter shape
  - per-evidence-band PASS/FAIL with the named bundle commands and
    actual observed counts
  - the diff summary of the four authority surfaces 103-01 touched
  - the diff summary of the v1.22-MILESTONE-AUDIT.md rewrite
  - explicit statement that MILESTONE-ARC, PROJECT "Last shipped",
    MILESTONES.md, and v1.22 archive copies were intentionally NOT
    touched (per D-02), and naming `/gsd-complete-milestone v1.22` as
    the next gate that owns them
- **D-15:** If 103-02's audit rerun does NOT come back closeout-ready
  (i.e., the rerun surfaces a NEW gap that Phases 100/101/102 didn't
  close), Phase 103 stops in place and records the finding in
  `103-VERIFICATION.md` with `closeout_readiness: red` or `yellow`.
  Phase 103 must NOT widen scope to fix the newly-found gap inline —
  that's a Phase 104 (or sub-plan) decision the maintainer makes
  separately. This guards against the exact failure mode the maintainer's
  culture flags: "reconciliation phases that quietly expand into repair
  phases lose the bounded-scope discipline that makes them trustable".

### Boundary against the broader codebase

- **D-16:** Phase 103 MUST NOT modify `lib/`, `test/`, `mix.exs`,
  `mix.lock`, `guides/`, `examples/`, `priv/`, or anything else outside
  `.planning/`. This is a planning-surface reconciliation phase, not a
  doc/code/test phase. The Phase 102 T-102-08 boundary guard (which
  fenced 102 to `.planning/phases/` only) is the structural ancestor;
  103's boundary is `.planning/` only (slightly wider because authority
  surfaces live at the `.planning/` root, not just under
  `.planning/phases/`).

### Claude's Discretion

- Exact order in which 103-01 edits the four authority surfaces, as
  long as the final state is internally consistent and the commit
  history is readable.
- Exact wording of the per-phase `### Decisions` entries appended to
  STATE.md (one each for Phases 100/101/102/103), as long as each entry
  is dated, names the closed requirements, and matches the existing
  Phase 90-94 entry shape.
- Exact wording of the closeout-ready Recommendation in the rewritten
  `v1.22-MILESTONE-AUDIT.md`, as long as it names
  `/gsd-complete-milestone v1.22` as the next gate and does not declare
  v1.22 "shipped" (that's the archive step's claim, not the audit's).
- Whether to write 103-01 and 103-02 as a single combined commit per
  plan (Phase 94 used per-plan commits) or split each plan further. The
  default is one commit per plan summary, per Phase 94 precedent.
- Whether `103-VERIFICATION.md` cites each of the three closeout-bundle
  commands as a separate evidence band or as one combined band, as long
  as the actual observed counts and exit codes are recorded verbatim.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase and milestone authority (the surfaces being reconciled)

- `.planning/ROADMAP.md` — active v1.22 contract; Phase 103 plan
  checkboxes flip here (D-04)
- `.planning/REQUIREMENTS.md` — SURF-01/02/03 bullet + Traceability table
  flips here (D-03)
- `.planning/STATE.md` — yaml header, current position, performance
  metrics, decisions log, session continuity, operator next steps all
  flip here (D-05)
- `.planning/PROJECT.md` — narrow remaining-work narrative pass only
  (D-06); "Last shipped: v1.21" framing stays untouched (D-02)
- `.planning/v1.22-MILESTONE-AUDIT.md` — rewritten in place by 103-02
  (D-07, D-08, D-09)
- `.planning/MILESTONE-ARC.md` — explicitly NOT touched in Phase 103
  (D-02)
- `.planning/MILESTONES.md`, `.planning/RETROSPECTIVE.md` — explicitly
  NOT touched in Phase 103 (D-02)

### Direct precedent — Phase 94 v1.21 closeout

- `.planning/phases/94-authority-surface-reconciliation-and-closeout/94-CONTEXT.md` —
  split-authority hierarchy (D-01..D-07), bounded truth-bundle closeout bar
  (D-13..D-18), reconciliation boundary (D-19..D-22). This is the
  one-for-one structural template for Phase 103.
- `.planning/phases/94-authority-surface-reconciliation-and-closeout/94-01-SUMMARY.md` —
  Phase 94 reconciliation pass evidence (the v1.21 mirror of 103-01)
- `.planning/phases/94-authority-surface-reconciliation-and-closeout/94-02-SUMMARY.md` —
  Phase 94 audit-rewrite-in-place pattern + bounded rerun bundle (the
  v1.21 mirror of 103-02)
- `.planning/phases/94-authority-surface-reconciliation-and-closeout/94-VERIFICATION.md` —
  Phase 94 closeout-readiness verdict shape with `closeout_readiness:
  green` frontmatter; the format `103-VERIFICATION.md` should follow
  (D-14)
- `.planning/phases/94-authority-surface-reconciliation-and-closeout/94-VALIDATION.md` —
  Phase 94 validation shape for closeout reconciliation phases

### Phase 99 closeout-bar rule (cross-applies to all v1.22 closeout work)

- `.planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md` —
  D-13 ("balanced claim-shaped rerun bundle, not minimal targeted suite
  alone and not 'just run everything' theater"), D-14 (named bundle
  shape), D-15 (`mix ci.all` disclaimer). These cross-apply to 103-02's
  closeout bar (D-10..D-13 above).
- `.planning/phases/99-contract-lock-docs-and-final-verification/99-VERIFICATION.md` —
  v1.22 DOC-01/02/03 closure evidence; the rerun bundle in 103-02
  re-validates the same evidence on the reconciled tree.

### Repaired evidence chain (what Phase 103 is closing on)

- `.planning/phases/100-phase-95-verification-backfill/100-VERIFICATION.md` —
  EVID-01/02/03 closure
- `.planning/phases/101-phase-96-verification-backfill/101-VERIFICATION.md` —
  PROOF-01 closure
- `.planning/phases/102-phase-98-verification-backfill/102-VERIFICATION.md` —
  SURF-01/02/03 closure (PASS 9/9, the most-recent backfill closure)
- `.planning/phases/100-phase-95-verification-backfill/100-VALIDATION.md`,
  `.planning/phases/101-phase-96-verification-backfill/101-VALIDATION.md`,
  `.planning/phases/102-phase-98-verification-backfill/102-VALIDATION.md` —
  Nyquist closure for the three backfill phases; informs whether
  103-02 can drop the corresponding `tech_debt` rows from the audit
  (D-08)
- `.planning/phases/95-evidence-model-lock-and-scope-guard/95-VERIFICATION.md`,
  `.planning/phases/96-evidence-persistence-and-public-api/96-VERIFICATION.md`,
  `.planning/phases/98-mounted-evidence-views-on-audit/98-VERIFICATION.md` —
  the backfilled artifacts the audit rerun will re-discover (Phases
  100/101/102 wrote these to the phase-95/96/98 directories, not to
  100/101/102 directories)

### Tests that lock the closeout-bundle commands (D-10)

- `test/threadline/evidence_test.exs` — library API write/read
- `test/threadline/evidence/proof_test.exs` — verdict vocabulary
- `test/mix/tasks/threadline.evidence_show_test.exs` — Mix-task parity
- `test/threadline/operator_surface/live/evidence_live_test.exs` —
  mounted evidence view + SURF-01/02 behavior
- `test/threadline/operator_surface/auth_test.exs` — SURF-03
  evidence_authorize_fn fail-closed gate
- `mix verify.doc_contract` — locked public-doc literals (DOC-01/02/03)
- `mix verify.example` — example-app `sigra-reference` integration

### Workflow tooling Phase 103 invokes

- `gsd-audit-milestone` (or `$gsd-audit-milestone`) — the audit tool
  103-02 reruns; output rewrites `v1.22-MILESTONE-AUDIT.md` in place
  (D-07)
- `/gsd-complete-milestone v1.22` — the NEXT phase / step after Phase 103
  passes; owns the MILESTONE-ARC flip, the PROJECT "Last shipped" flip,
  the v1.22 archive copy creation, and the `.planning/milestones/v1.22-*`
  archive entries (D-02)

### Workflow posture (carried forward from Phase 94)

- `.planning/config.json` — locked recommendation-first discuss posture
  (Phase 94 D-23..D-25); no further config mutation needed in Phase 103.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **Phase 94 closure pattern.** Every artifact Phase 103 needs to produce
  (CONTEXT, RESEARCH, two PLANs, two SUMMARYs, VERIFICATION, VALIDATION)
  has a one-for-one structural ancestor in
  `.planning/phases/94-authority-surface-reconciliation-and-closeout/`.
  Reuse the Phase 94 shapes verbatim; only the milestone-specific
  details (v1.22 vs v1.21, requirement IDs, command bundle) change.
- **The three closeout-bundle commands already exist and are already
  green** on the current tree (per the 2026-05-26 audit body lines
  142-145). 103-02's rerun is a re-validation, not a fresh
  authoring/wiring task.

### Established Patterns

- **Split-authority hierarchy (Phase 94 D-01..D-07).** ROADMAP =
  active contract, MILESTONE-AUDIT = closeout gate, STATE =
  execution snapshot, PROJECT = narrative/current-state framing
  (must not contradict, must not become a second ledger).
- **Reconciliation phases move proof and active planning surfaces
  together** (Phase 80, 89, 94 precedent). "If narrative or roadmap
  optimism outruns current-tree proof, the project pays for it later
  in repair phases" — Phase 103 holds this line for v1.22.
- **In-place rewrite of MILESTONE-AUDIT.md** is the consistent
  pattern (v1.1–v1.21 are all single files; Phase 94 explicitly
  rewrote v1.21-MILESTONE-AUDIT in place).
- **Per-phase append-only `### Decisions` entries in STATE.md** is the
  consistent pattern for reconciliation phases (Phase 94 added one
  entry each for Phases 90/91/92/93/94; Phase 103 should do the same
  for 100/101/102/103).

### Integration Points

- **`gsd-audit-milestone` tool output → `v1.22-MILESTONE-AUDIT.md`.**
  103-02 invokes the tool; the tool's output is the rewrite source
  for the audit file (D-08 fields are the tool's frontmatter +
  body schema, not human-authored prose).
- **`mix verify.doc_contract` and `mix verify.example`** are existing
  aliases in `mix.exs`. The middle test invocation (5-file bundle)
  is a verbatim command, not an alias. No new aliases are added (D-13).

</code_context>

<specifics>
## Specific Ideas

- The strongest cohesive recommendation is:
  **Phase 103 is the v1.22 mirror of Phase 94. Reuse Phase 94's split-authority
  hierarchy, bounded-truth-bundle closeout bar, and `/gsd-complete-milestone`-
  as-archive-gate sequencing one-for-one. The only intentional deviation is
  scope: Phase 103 reconciles four planning surfaces (not five) because v1.22
  has no equivalent of the `guides/how-threadline-works.md` stale-narrative
  patch Phase 94 D-19 included (the evidence-plane framing in that guide is
  already correct on the current tree).**

- The strongest maintainer lesson Phase 103 honors:
  the reconciliation phase that quietly expands scope to fix a newly-found
  gap loses the bounded-scope discipline that makes it trustable. D-15
  encodes the "stop in place and record" posture so 103 stays narrow even
  if the audit rerun surfaces something unexpected.

- The strongest DX posture for this phase:
  a maintainer reading `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`,
  `.planning/STATE.md`, `.planning/PROJECT.md`, and
  `.planning/v1.22-MILESTONE-AUDIT.md` after Phase 103 closes should get
  exactly one consistent answer: v1.22 evidence-plane work is done and
  proven on the current tree; `/gsd-complete-milestone v1.22` is the next
  gate.

</specifics>

<deferred>
## Deferred Ideas

- **`/gsd-complete-milestone v1.22` (next gate, not this phase).** Owns the
  MILESTONE-ARC v1.22 row flip from "active" to "shipped", the PROJECT.md
  "Last shipped" pointer flip from v1.21 to v1.22, creation of
  `.planning/milestones/v1.22-REQUIREMENTS.md` /
  `v1.22-ROADMAP.md` / `v1.22-MILESTONE-AUDIT.md` archive copies, and
  whatever RETROSPECTIVE.md / MILESTONES.md updates the archival workflow
  produces.
- **Potential Phase 104 (only if 103-02 audit rerun surfaces a new gap).**
  Per D-15, Phase 103 stops in place rather than absorbing newly-found
  gaps. If the rerun surfaces something Phases 100/101/102 missed,
  open a dedicated Phase 104 with its own scope.
- **`mix verify.closeout` alias.** Considered and rejected (D-13). The
  closeout-bundle middle command is milestone-specific (v1.21's
  support-lane tests vs v1.22's evidence-plane tests vs whatever the
  next milestone's seam tests are), so an alias would either go stale or
  need to be rewritten every milestone, defeating the bounded-truth-bundle
  discipline. The two genuinely reusable pieces (`mix verify.doc_contract`,
  `mix verify.example`) are already aliases — that is the right
  generalization level.

</deferred>

---

*Phase: 103-authority-surface-reconciliation-and-milestone-re-audit*
*Context gathered: 2026-05-27*
