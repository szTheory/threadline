# Phase 109: Maintainer Walkthrough Dry-Run - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Execute `examples/threadline_phoenix/WALKTHROUGH.md` end-to-end on a clean clone, capture every gap/papercut/surprise as a numbered finding file under `.planning/v1.23/findings/` with (a/b/c/d) classification assigned at capture time, and fix nothing in-flight.

Scope guard: `.planning/v1.23/findings/` only during the walk. No edits to `lib/`, `guides/`, `examples/threadline_phoenix/`, or test code — even obvious typos become findings. Phase 110 triages; Phase 109 observes.

Requirements: RUN-01, RUN-02, RUN-03, FINDINGS-02.

**Phase 109 complete ≠ RUN-01..03 all green.** Completion means FINDINGS-02 satisfied (every observed gap captured with classification + step cite) plus auditable proof of observe-only discipline (success criterion 5). RUN-* acceptance targets are validated on post-110 re-walk.

</domain>

<decisions>
## Implementation Decisions

### Execution environment — clean clone (D-109-01)

- **D-109-01a:** Use a **fresh `git clone` to an isolated directory** (e.g. `$TMPDIR/threadline-walk-109-$(git rev-parse --short HEAD)`) at a pinned **`WALK_BASELINE_SHA`**. This is the primary RUN-01 contract — not walking on the dirty dev tree, not a dedicated branch without isolation.
- **D-109-01b:** Clone the **repository root** (path dep `{:threadline, path: "../.."}` requires whole repo). Run all WALKTHROUGH commands from `examples/threadline_phoenix/` inside the clone.
- **D-109-01c:** **`git worktree add`** at the same SHA is an acceptable maintainer shortcut when bandwidth is tight — same semantics as clone (clean working tree, pinned SHA). Document in execution log as "clean sibling checkout," not a substitute for validating literal clone instructions for external adopters.
- **D-109-01d:** For v1.23 closeout, walk **local HEAD** (current commit under test). Optionally re-walk against remote `main` if ahead-of-origin work needs adopter-truth validation — record which in execution log.
- **D-109-01e:** **Reject** walking on current dev tree (Option C) — existing `_build/`, `deps/`, seeded DB, and uncommitted edits invalidate RUN-01 and invite in-flight fix temptation.

### Execution environment — Postgres bootstrap (D-109-02)

- **D-109-02a:** RUN-01 "only WALKTHROUGH.md" means the **entire file** (§0–§5 + appendices), not §1 body alone. §0 prerequisites are in-scope.
- **D-109-02b:** Two blessed database paths before §1:

  | Path | Steps |
  |------|-------|
  | **A — local Postgres on :5432** | Ensure Postgres running; proceed to §1 |
  | **B — Docker Compose (repo root)** | `docker compose up -d postgres` → `export DB_HOST=localhost DB_PORT=5433` → `cd examples/threadline_phoenix` |

  Path B is required when compose publishes **5433** (repo default). Default `pg_isready` without `DB_PORT` will false-fail on Path B — classify environment misconfiguration from ambiguous §0 as **(c) doc gap**, not **(a) breakage**, if maintainer followed compose but omitted export.
- **D-109-02c:** **Appendix B is Mix-only** (recovery, evidence CLIs). Postgres bootstrap lives in §0 — matches D-108-01a split.
- **D-109-02d:** **Forbidden during RUN-01:** opening `README.md`, `CONTRIBUTING.md`, `guides/*`, `DEMO-MANIFEST.md` mid-run; IEx / `Repo.*` / raw SQL; ad-hoc `brew install postgresql` unless WALKTHROUGH is amended in Phase 110.
- **D-109-02e:** Full containerized app+db walk (Option D) is **deferred** to v1.24 seeds if dry-run surfaces demand — host Elixir + container Postgres matches Phoenix/Ecto OSS idioms and Phase 22 D-10–D-13.

### Known review warnings — WR-001 / WR-002 (D-109-03)

- **D-109-03a:** **Do not pre-fix** WR-001 or WR-002 before the walk. No narrow 108.x doc pass — that erodes the load-bearing 108→109→110 observe/fix separation.
- **D-109-03b:** **Pre-register** expected confirmations from `108-REVIEW.md` in `109-EXECUTION-LOG.md` before walking. This is planning metadata, not a substitute for filing findings.
- **D-109-03c:** Execute **WALK-03-02 and WALK-03-03 verbatim** — including WALK-03-03 optional CLI step 5 with the documented (broken) flag syntax. Do not "try the correct window" or skip steps.
- **D-109-03d:** File **0001** (WR-001: WALK-03-02 empty actor window → **(a) breakage**) and **0002** (WR-002: WALK-03-03 invalid CLI → **(c) doc gap**) with empirical Evidence at capture time. Add `Classification note: Pre-registered 108-REVIEW WR-00N; confirmed YYYY-MM-DD.`
- **D-109-03e:** **Continue walking** after 0001/0002 — remaining steps may surface IN-001 and surprises. RUN-02 partial failure on first pass is a **valid Phase 109 outcome**.

### Blocker vs partial walk (D-109-04)

- **D-109-04a:** **§1 is a hard gate.** If `mix compile`, `ecto.migrate`, `demo.seed` (after one `mix demo.reset`), or `phx.server` fails → file **(a)** finding, **STOP session**. Mark §2–§5 **NOT ATTEMPTED** in checkpoint with `blocked_by: WALK-01-XX`.
- **D-109-04b:** **§2–§3:** soft gaps → file finding + continue. Hard gate if `/audit` is unusable for all personas (403/500 everywhere) → STOP before §4.
- **D-109-04c:** **§4 incidents are independent lanes.** One blocked/unanswerable incident does not stop siblings. WR-001 on WALK-03-02 must not prevent attempting WALK-03-01, 03-03, 03-04.
- **D-109-04d:** Distinguish two "unanswerable" types:
  - **Infrastructure unanswerable** — cannot run documented procedure (no server, no seed, `/audit` down) → gate STOP
  - **Outcome unanswerable** — procedure runs but expected state missing/wrong → **(a/b/c/d)** finding, continue independent steps
- **D-109-04e:** **§5 evidence exercises** are independent given successful `demo.seed`. If §4 stopped due to total `/audit` failure but evidence CLIs work, attempt §5 CLI paths; otherwise mark §5 NOT ATTEMPTED.
- **D-109-04f:** **Do not** STOP the entire walk when a single §4 incident fails after §1 passes — that wastes independent signal (working #4521/#4518 paths while 03-02 window is wrong).

### Finding capture cadence (D-109-05)

- **D-109-05a:** **MVP finding file at each "If different" moment** — before advancing the step. Minimum at trigger (~2–3 min):
  - Frontmatter: `id`, `slug`, **`classification`**, **`walkthrough_step`**, `captured`, `status: open`
  - **Actual** (one paragraph) + **Evidence** (paste-ready literals: routes, filters, ticket #, CLI stderr)
  - **Expected** may be one line or "see WALK-XX-YY Expected outcome" initially
- **D-109-05b:** **Classification assigned at file creation** per FINDINGS-02 — never TBD, never "classify in Phase 110." Use README 4-question tree. If ambiguous, pick best fit + optional `classification_note`.
- **D-109-05c:** **§1–§5 checkpoint tables are review-only reconciliation gates** — not primary capture. At each checkpoint: tick Expected met? / Findings filed?; polish thin findings; confirm no duplicate step IDs; record blockers.
- **D-109-05d:** Maintain **`109-WALK-CHECKPOINT.json`** at each section boundary (resume state, not canonical output):

  ```json
  {
    "phase": "109",
    "last_completed_step": "WALK-03-02",
    "sections_completed": ["§1", "§2", "§3"],
    "findings_filed": ["0001-agent2-empty-window", "0002-evidence-cli-flags"],
    "blockers": [],
    "checkpoint_tables_verified": ["§1", "§2", "§3"]
  }
  ```

- **D-109-05e:** **Reject** end-of-walk batch filing (Option D) — memory decay on ~17 "If different" triggers loses route/filter/ticket literals needed for Phase 110 triage.

### Audit trail — scope guard proof (D-109-06)

- **D-109-06a:** Use **clean isolated clone + `109-EXECUTION-LOG.md` + git path filters** — mirrors v1.14 Phase 48 isolated verification at pinned SHA when main is dirty.
- **D-109-06b:** **Before walk** (main repo), write execution log with: `WALK_BASELINE_SHA`, clone path, `WALK_STARTED_AT` (UTC), expected WR-001/WR-002 confirmations table, Elixir/OTP versions, `DB_*` env used.
- **D-109-06c:** **During walk** — findings written only in clone's `.planning/v1.23/findings/`. No commits in clone required; files exist on disk.
- **D-109-06d:** **After walk** — `rsync` findings (+ optional `assets/`) and `109-WALK-CHECKPOINT.json` to main repo. Single import commit:

  ```bash
  git add .planning/v1.23/findings/ .planning/phases/109-maintainer-walkthrough-dry-run/
  git commit -m "Phase 109: maintainer walkthrough findings (observe-only dry-run)"
  ```

- **D-109-06e:** **Verify success criterion 5** in `109-VERIFICATION.md`:

  ```bash
  git log "$PHASE_109_START_SHA".."$IMPORT_SHA" \
    --name-only --pretty=format: -- lib/ guides/ examples/ test/ | sort -u
  # Expected: empty

  git show --name-only --pretty=format: "$IMPORT_SHA"
  # Expected: .planning/v1.23/findings/*, .planning/phases/109-*/* only
  ```

- **D-109-06f:** **Reject** pre-commit hooks (Option D) — new enforcement surface, easy to bypass, inconsistent with repo today. **Reject** execution-log-only proof (Option C alone) when main has parallel edits.

### Phase 109 outcome reporting (D-109-07)

- **D-109-07a:** Record in execution log and STATE.md:

  > **Walk status:** RUN-01 ☐/✓ RUN-02 ☐/✓ RUN-03 ☐/✓ | **Findings:** N (a/b/c/d counts) | **Not attempted:** [steps] due to [gate]

- **D-109-07b:** `109-SUMMARY.md` handoff for Phase 110: finding counts by class, top `(a)` blockers, pre-registered vs surprise findings, `WALK_BASELINE_SHA`.

### Claude's Discretion

- Exact temp clone path naming convention
- Whether to add `scripts/verify-phase-109-scope.sh` vs inline verification commands in `109-VERIFICATION.md`
- Optional `0000-walk-meta.md` finding vs execution-log-only metadata
- Screenshot capture under `findings/assets/` — never required for classification
- Second walk against remote `main` if local HEAD is unpushed

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contracts

- `.planning/ROADMAP.md` § Phase 109–110 — goals, success criteria, scope guards, fix-vs-defer chain
- `.planning/REQUIREMENTS.md` — RUN-01, RUN-02, RUN-03, FINDINGS-02; Out of Scope
- `.planning/phases/104-reference-walkthrough-charter-override-decision/104-CONTEXT.md` — synthetic adopter, v1.23 non-goals, observe/fix separation
- `.planning/phases/108-walkthrough-script-finding-capture-protocol/108-CONTEXT.md` — WALKTHROUGH architecture, step template, findings protocol, D-108-06c STOP discipline
- `.planning/phases/108-walkthrough-script-finding-capture-protocol/108-REVIEW.md` — WR-001, WR-002 pre-registered expected findings

### Walkthrough & findings (execution surface)

- `examples/threadline_phoenix/WALKTHROUGH.md` — sole RUN-01 authority (§0–§5 + appendices)
- `.planning/v1.23/findings/TEMPLATE.md` — finding file format
- `.planning/v1.23/findings/README.md` — 4-question classifier + routing table
- `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs` — literal existence contracts (does not prove procedure semantics)
- `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` — seed fiction ground truth

### Vision, OSS DNA, ecosystem lessons

- `prompts/threadline-elixir-oss-dna.md` — named `mix verify.*` entrypoints, doc contract tests, honest default tests, isolated verification precedent
- `prompts/audit-lib-domain-model-reference.md` — capture vs semantics vs exploration layers
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — SIEM manifest pattern, operational affordances, hybrid row+action model
- `prompts/THREADLINE-GSD-IDEA.md` — project vision and constraints

### Prior art & precedents

- `.planning/phases/108-walkthrough-script-finding-capture-protocol/108-VERIFICATION.md` — Phase 108 closeout; RUN-* deferred to Phase 109
- v1.14 Phase 48 isolated clean-tree verification pattern (referenced in PROJECT.md / milestone archives)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `examples/threadline_phoenix/WALKTHROUGH.md` — complete §0–§5 runbook with step IDs, checkpoint tables, "If different" triggers
- `.planning/v1.23/findings/TEMPLATE.md` + `README.md` — ready for 0001+ capture
- Root `docker-compose.yml` — Postgres on port 5433 for Path B bootstrap
- `mix demo.seed` / `mix demo.reset` — deterministic fiction; recovery mid-walk
- `walkthrough_doc_contract_test.exs` — CI literal lock; gap exposed by WR-001 (procedure semantics untested)

### Established Patterns

- **Observe-then-fix separation** — Phase 109 findings only; Phase 110 triage (D-108-05f, ROADMAP scope guard)
- **Doc stack roles** — WALKTHROUGH = maintainer runbook; manifest = SSOT; Appendix A = mid-run literals (D-108-01c)
- **SIEM search-pack model** — WALK-03 = one detection per manifest hero; independent incident lanes
- **Isolated verification at pinned SHA** — v1.14 release-verify when main is dirty; same shape for Phase 109
- **Named verify entrypoints** — `mix verify.*` / `mix ci.all` for CI; RUN-01 is stricter human UAT on WALKTHROUGH only

### Integration Points

- Findings import → Phase 110 FIX-01..03 / DEFER-01 triage by classification
- WR-001 → Phase 110 doc + `demo_contract_test` describe for agent2 window
- WR-002 → Phase 110 doc fix for CLI flag syntax + optional walkthrough contract extension
- `109-VERIFICATION.md` → milestone audit evidence for RUN-* and FINDINGS-02 satisfaction

</code_context>

<specifics>
## Specific Ideas

- **Kubernetes troubleshooting runbook:** "Do not change cluster state during audit" → "Do not fix during Phase 109 walk." Observation and remediation are separate phases.
- **SIEM detection engineering:** Run the hunt query against the corpus even when you suspect mis-tuning; record TP/FN; tune in tuning phase (Phase 110), not during validation observe (Phase 109). WR-001/WR-002 are labeled test cases, not excuses to fix early.
- **Stripe test mode:** Deterministic manifest literals + frozen `demo_epoch` fiction; only documented surfaces (no IEx/SQL).
- **OpenTelemetry demo:** Compose for dependencies, host-run app — not full containerized library walk.
- **ExUnit + manual UAT two-layer model:** Contract tests = CI gate; maintainer walk = UAT; neither replaces the other. WR-001 slipped through because walkthrough contract tests lock substring existence, not procedure↔seed semantics.
- **PaperTrail / Carbonite / django-auditlog:** Install docs assume Postgres exists; Mix/Ecto-centric bootstrap — Threadline matches with §0 + §1 split.

### Coherent execution playbook (one-shot)

1. Record `WALK_BASELINE_SHA` + start UTC in `109-EXECUTION-LOG.md`; pre-register WR-001/WR-002.
2. `git clone` repo to `$TMPDIR/threadline-walk-109-*`; checkout baseline SHA.
3. §0 Path B: `docker compose up -d postgres`; `export DB_HOST=localhost DB_PORT=5433`.
4. Walk §1→§5 verbatim from clone; MVP finding at every "If different"; checkpoint review each section.
5. §1 fail → STOP. §4 incident fail → file + next incident.
6. `rsync` findings to main; single import commit; run path-filter verification; write `109-VERIFICATION.md` + `109-SUMMARY.md`.

</specifics>

<deferred>
## Deferred Ideas

- **Full containerized walk (app + db in compose)** — v1.24 seed if dry-run surfaces integrator demand for devcontainer-style onboarding
- **Pre-109 narrow doc fix for WR-001/WR-002** — rejected; would blur observe/fix separation (file as 0001/0002 instead)
- **Pre-commit hook enforcing findings-only commits during walk** — rejected; surprising new tooling; git path filters sufficient
- **`mix verify.phase_109_scope` alias** — optional Phase 110+ if verification script is reused; not required for Phase 109
- **Split public WALKTHROUGH vs maintainer runbook** — deferred post-110 (Phase 108 D-108 deferred)
- **Second clone against remote `main`** — optional adopter-truth validation if local HEAD unpushed; not blocking Phase 109 closeout

### Reviewed Todos (not folded)

(none — `todo.match-phase` unavailable in current gsd-sdk; no pending todos matched)

</deferred>

---

*Phase: 109-maintainer-walkthrough-dry-run*
*Context gathered: 2026-05-27*
