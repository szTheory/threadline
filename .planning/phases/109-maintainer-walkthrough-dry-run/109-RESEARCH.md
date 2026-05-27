# Phase 109: Maintainer Walkthrough Dry-Run — Research

**Researched:** 2026-05-27  
**Phase:** 109 — Maintainer Walkthrough Dry-Run  
**Confidence:** HIGH (execution protocol from locked CONTEXT; runtime outcomes discovered during walk)

## Summary

Phase 109 is **manual UAT**, not library implementation. The executor walks `examples/threadline_phoenix/WALKTHROUGH.md` on an **isolated clean clone** at a pinned SHA, files numbered findings under `.planning/v1.23/findings/` at every "If different" trigger, and imports results to the main repo with **git path-filter proof** that no `lib/`, `guides/`, `examples/`, or `test/` files changed during the walk.

**Phase complete when:** FINDINGS-02 satisfied + scope-guard verification passes — **not** when RUN-01..03 are all green (partial walks with documented gates are valid).

**Pre-registered expectations:** `108-REVIEW.md` WR-001 (WALK-03-02 empty actor window → **(a)**) and WR-002 (WALK-03-03 invalid CLI flags → **(c)**) must be confirmed empirically as findings `0001` and `0002`, not pre-fixed.

## Phase Requirements Mapping

| REQ-ID | ROADMAP success criterion | Plan coverage |
|--------|---------------------------|---------------|
| RUN-01 | Clean-clone install; only WALKTHROUGH.md; phx boots | 109-02 (§0–§3) |
| RUN-02 | Four WALK-03 incidents via `/audit` only | 109-03 (§4) |
| RUN-03 | Three evidence exercises via CLI + LiveView | 109-04 (§5) |
| FINDINGS-02 | Every gap captured with class + step cite at capture | All walk plans + 109-04 checkpoint |

## WALKTHROUGH Structure (execution surface)

| Section | Step IDs (sample) | Gate behavior |
|---------|-------------------|---------------|
| §0 | Prerequisites, Path A/B Postgres | In-scope for RUN-01; Path B needs `DB_PORT=5433` after compose |
| §1 | WALK-01-01..03 | **Hard gate** — failure → STOP, §2–§5 NOT ATTEMPTED |
| §2 | WALK-01-04..07 | Soft gaps → finding + continue |
| §3 | WALK-02-* | Soft gaps; hard stop if `/audit` unusable everywhere |
| §4 | WALK-03-01..04 | **Independent lanes** — one failure does not block siblings |
| §5 | WALK-04-01..03 | Independent if `demo.seed` succeeded; CLI uses `--subject` + `--subject-ref-json` |

**"If different" count:** ~17 triggers across §1–§5 (grep `If different` in WALKTHROUGH.md). MVP finding file **at trigger**, not end-of-walk batch.

## Execution Environment

### Clean clone (D-109-01)

```bash
WALK_BASELINE_SHA=$(git rev-parse HEAD)
CLONE_DIR="${TMPDIR:-/tmp}/threadline-walk-109-$(git rev-parse --short HEAD)"
git clone "$(git rev-parse --show-toplevel)" "$CLONE_DIR"
cd "$CLONE_DIR" && git checkout "$WALK_BASELINE_SHA"
cd examples/threadline_phoenix
```

`git worktree add` at same SHA is acceptable shortcut — document in execution log.

### Postgres Path B (D-109-02)

From repo root in clone:

```bash
docker compose up -d postgres
export DB_HOST=localhost DB_PORT=5433
cd examples/threadline_phoenix
```

Ambiguous §0 without `DB_PORT` on compose → classify **(c) doc gap** if maintainer followed compose but omitted export.

### Forbidden during RUN-01 (D-109-02d)

- `README.md`, `CONTRIBUTING.md`, `guides/*`, `DEMO-MANIFEST.md` mid-run
- IEx / `Repo.*` / raw SQL
- In-flight fixes anywhere outside findings files

## Pre-Registered Review Findings

| ID | Step | Expected classification | Evidence to capture |
|----|------|-------------------------|---------------------|
| WR-001 | WALK-03-02 | **(a) breakage** | Empty actor history for window `2026-05-26T12:00:00Z`–`2026-05-27T12:00:00Z`; seed uses `demo_last_tuesday` + 1..12 min |
| WR-002 | WALK-03-03 step 5 | **(c) doc gap** | CLI stderr: unexpected positional args on `mix threadline.evidence.show` |

Correct form (from WALK-04-01):

```bash
mix threadline.evidence.show --subject retention_run \
  --subject-ref-json '{"run_id":"walk-retention-offboarded-co"}'
```

## Finding Capture Protocol

- Copy `.planning/v1.23/findings/TEMPLATE.md` → `NNNN-slug.md` starting at **0001**
- Frontmatter: `classification` required at creation (never TBD)
- Maintain `109-WALK-CHECKPOINT.json` at each section boundary
- Checkpoint tables in WALKTHROUGH are **reconciliation only** at section end

## Import & Scope Guard (D-109-06)

After walk in clone:

```bash
rsync -av "$CLONE_DIR/.planning/v1.23/findings/" .planning/v1.23/findings/
rsync -av "$CLONE_DIR/.planning/phases/109-maintainer-walkthrough-dry-run/109-WALK-CHECKPOINT.json" \
  .planning/phases/109-maintainer-walkthrough-dry-run/
```

Record `PHASE_109_START_SHA` before walk; after import commit `IMPORT_SHA`:

```bash
git log "$PHASE_109_START_SHA".."$IMPORT_SHA" \
  --name-only --pretty=format: -- lib/ guides/ examples/ test/ | sort -u
# Expected: empty
```

## Validation Architecture

| Property | Value |
|----------|-------|
| **Primary verification** | Manual maintainer walk + finding files |
| **Automated guard** | `git log` path filter (109-VERIFICATION.md) |
| **CI not sufficient** | `walkthrough_doc_contract_test.exs` locks literals only — procedure↔seed semantics need human UAT (WR-001 slipped through) |
| **Quick sanity** | Optional: `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs` in clone after WALK-01-03 — not a RUN-01 substitute |

### Per-requirement verification

| REQ-ID | Verification type | Command / artifact |
|--------|-------------------|-------------------|
| RUN-01 | Manual + execution log | `109-EXECUTION-LOG.md` §1 checkpoint; `http://localhost:4000` renders |
| RUN-02 | Manual + findings | Four findings or "met" ticks on §4 checkpoint; step cites WALK-03-0N |
| RUN-03 | Manual + findings | §5 checkpoint; CLI/LiveView evidence in finding bodies |
| FINDINGS-02 | Artifact audit | `ls .planning/v1.23/findings/0*.md`; each has `classification` + `walkthrough_step` |

### Manual-only (expected)

| Behavior | Why manual |
|----------|------------|
| `/audit` operator UX | Browser + persona flows |
| Evidence LiveView verdicts | Human reads `summary_status` / `claim_assessment.status` |
| Observe-only discipline | Cannot automate "did not fix in-flight" — git path filter proves post-hoc |

## Plan Structure Recommendation

| Plan | Wave | Delivers |
|------|------|----------|
| 109-01 | 1 | Execution log, clone, §0 bootstrap |
| 109-02 | 2 | RUN-01 §1–§3 |
| 109-03 | 3 | RUN-02 §4 (four incidents) |
| 109-04 | 4 | RUN-03 §5 + FINDINGS-02 reconciliation |
| 109-05 | 5 | rsync import, 109-VERIFICATION.md, 109-SUMMARY.md |

## Risks

| Risk | Mitigation |
|------|------------|
| Walking dirty dev tree | Reject — clone only (D-109-01e) |
| Pre-fixing WR-001/002 | Forbidden — file 0001/0002 instead |
| §1 fail but continuing | Hard STOP per D-109-04a |
| One §4 incident blocks others | Independent lanes per D-109-04c |
| End-of-walk batch findings | Rejected — MVP at each trigger |

## RESEARCH COMPLETE
