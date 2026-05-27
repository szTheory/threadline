# Phase 108: Walkthrough Script + Finding-Capture Protocol - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Author `examples/threadline_phoenix/WALKTHROUGH.md` (install → onboarding → daily-use → **four** operator incidents → three evidence exercises) and `.planning/v1.23/findings/TEMPLATE.md` + `README.md` with (a/b/c/d) classification **before** Phase 109 walks anything.

Scope: `examples/threadline_phoenix/` and `.planning/v1.23/findings/` only. `lib/` is read-only. No fix work — script and protocol authoring only.

Requirements: WALK-01, WALK-02, WALK-03 (expanded to four incidents), WALK-04, FINDINGS-01.

</domain>

<decisions>
## Implementation Decisions

### Document architecture (D-108-01)

- **D-108-01a:** **Procedural runbook + reference appendix** — not hub-and-spoke links, not fully duplicated inline SSOT. `WALKTHROUGH.md` body is numbered maintainer execution script; **Appendix A** copies all walk-critical literals from `DEMO-MANIFEST.md` + `DEMO_USERS.md` (credentials, UUIDs, ticket numbers, time anchors, correlation IDs, evidence `run_id`s); **Appendix B** copies minimal install/recovery commands from example README (`mix setup`, `mix demo.seed`, `mix demo.reset`, `mix phx.server`).
- **D-108-01b:** **RUN-01 self-containment** — cold maintainer completes the walk without opening other docs mid-run. Appendix A satisfies this; manifest remains SSOT for edits (edit manifest first, sync appendix). Optional "Further reading (not required for this run)" footer may link guides/README.
- **D-108-01c:** **Four doc roles, one walk path:**

  | Doc | Audience | Role |
  |-----|----------|------|
  | `guides/getting-started-saas.md` | Integrator | Generic first-hour wiring in *their* app |
  | `examples/threadline_phoenix/README.md` | Evaluator / CI | Runnable install + integration contract |
  | `DEMO-MANIFEST.md` + `Demo.Manifest` | Author / tests | Literal SSOT |
  | `WALKTHROUGH.md` | Maintainer (Phase 109) | Derived execution runbook |

- **D-108-01d:** Header block required: audience (maintainer dry-run), not integrator tutorial; recovery command (`mix demo.reset`); pointer that Appendix A replaces opening manifest during the run.

### Operator incidents — four playbooks (D-108-02)

- **D-108-02a:** Expand WALK-03 from three REQUIREMENTS utterances to **four operator incidents** — one atomic playbook per manifest hero. Do **not** fold delete into close scenario (violates D-107-05b; conflates actors, tickets, filters).
- **D-108-02b:** Locked incident pack:

  | # | Step ID prefix | Utterance | Hero | Login | Primary `/audit` path | Expected proof |
  |---|----------------|-----------|------|-------|----------------------|----------------|
  | 1 | `WALK-03-01` | Who closed #4521 in Acme last Tuesday + internal note before close? | #4521, `closer@acme` | `support@acme` or admin | Org-scoped timeline → `correlation_id: walk-acme-4521-close` → transaction → row history | Actor = closer; note field **`[REDACTED]`**, never plaintext |
  | 2 | `WALK-03-02` | Agent leaving — what did they touch in last 24h? | Leaving-agent window | `admin@example.com` | `/audit/actors/user/:id` or cross-org timeline + actor + time window | Cross-org actor history list |
  | 3 | `WALK-03-03` | Prove org Y retention-purged on offboard | `offboarded-co` | `admin@example.com` | `/audit/evidence` + CLI; scoped org Y timeline **empty** | Evidence `walk-retention-offboarded-co`; negative timeline check |
  | 4 | `WALK-03-04` | Who deleted reply on #4518 in Acme last Tuesday? What was in the note? | #4518, `deleter@acme` | `support@acme` or admin | Timeline → `ticket_replies` delete op → actor on delete tx → **prior** row history | Actor = deleter; prior row shows reply; sensitive fields masked |

- **D-108-02c:** All "last Tuesday" prose footnotes **`demo_last_tuesday`** (`2026-05-20T14:30:00Z`) from manifest — never wall-clock-relative filters in expected outputs.
- **D-108-02d:** Operator answers use **only** shipped `/audit` operator surface + documented `mix threadline.*` CLI — no raw SQL, no IEx, no `Repo.all/2`.
- **D-108-02e:** Amend ROADMAP Phase 108 success criteria and Phase 109 RUN-02 wording from "three operator scenarios" to **"four WALK-03 operator incidents"** in Phase 108 doc edits (planning traceability; Phase 109 dry-run validates all four).

### Step template & expected outputs (D-108-03)

- **D-108-03a:** **Hybrid checklist + literals** — not narrative-only, not ExUnit assertions embedded in prose. Executable assertions stay in `demo_contract_test.exs`; walkthrough links tests in **Verify**, does not duplicate `assert`.
- **D-108-03b:** Fixed skeleton for every non-trivial step:

  ```markdown
  #### Step WALK-XX.Y — <title>
  **Operator question:** …
  **Prerequisites:** account + manifest anchor
  **Do:** numbered imperatives
  **Operator surface:** table (Route | Scope | Filters | Drill-down)
  **Expected outcome:** semantic checklist (3–6 bullets)
  **Evidence:** (WALK-04 only) subject | subject_ref | summary_status | CLI | LiveView
  **Verify:** human checklist + optional contract test cite
  **If different:** file finding — do not fix during Phase 109
  ```

- **D-108-03c:** Assert **semantic outcomes** — ticket #4521, correlation_id, actor email, action name, `[REDACTED]` — **not** trigger-generated audit row UUIDs (D-107-07b).
- **D-108-03d:** Document exact **routes and filter keys/values** from manifest; avoid brittle LiveView label text (capabilities, not `<h3>` copy).
- **D-108-03e:** Stable **step IDs** (`WALK-01-03`, `§4.1.2`, etc.) on every step for FINDINGS-02 origin cites. Section-end **Checkpoint** tables (expected met? findings filed? blockers?) after §1–§5.
- **D-108-03f:** Canonical evidence CLI in doc body: **`mix threadline.evidence.show`**. Footnote that REQUIREMENTS/PROJECT prose says `mix verify.evidence` — add thin alias in example `mix.exs` **only if** planner confirms alias is in scope; otherwise footnote only.

### Evidence exercises — hybrid model (D-108-04)

- **D-108-04a:** **Hybrid:** seeded post-state for org Y retention proof + seeded posture snapshots for trigger coverage; **live viewer parity** for redaction/coverage (`mix threadline.policy.show`, `mix threadline.health.coverage`, `/audit/policy/redaction`, `/audit/coverage`). **No live purge** as proof path (D-107-06a — purge runs only in `demo.seed` tail).
- **D-108-04b:** Three WALK-04 exercises (locked):

  | Exercise | Subject | Proof mode | Manifest ref | Expected verdict |
  |----------|---------|------------|--------------|------------------|
  | 1 Retention purge | `retention_run` | Read seeded evidence + empty org Y timeline | `run_id: walk-retention-offboarded-co` | `proven` |
  | 2 Redaction snapshot | `redaction_policy` | Seeded evidence row + live policy viewer + #4521 capture corroboration | `policy: walk-demo-redaction-policy` (to be added) | `inferred_posture` |
  | 3 Trigger coverage | `trigger_coverage` | Seeded snapshot + optional `mix threadline.health.coverage` parity | `snapshot: walk-demo-trigger-coverage` | `proven` |

- **D-108-04c:** WALK-04 section opens with prerequisite `mix demo.seed` / recovery `mix demo.reset`; footnote that retention purge already executed during seed; prod sidebar may mention `mix threadline.retention.purge --dry-run` as **non-proof** optional prose only.
- **D-108-04d:** Document **subject + subject_ref keys + summary_status + claim_assessment.status** — not full JSON blobs in prose. Optional truncated `--json` excerpt per exercise.
- **D-108-04e:** **Known seed gap (planner must resolve before Phase 109):** `redaction_policy` evidence row is **not** seeded today. Phase 108 planning must either (i) include a narrow examples-only seed addition (`RetentionTail.record_evidence!/2` + manifest literal) as Phase 108 Plan 01 prerequisite, or (ii) file as first Phase 109 (a) finding if walk proceeds without it. WALKTHROUGH must not promise a row that does not exist post-`demo.seed`.

### Findings protocol (D-108-05)

- **D-108-05a:** **Structured minimal + YAML frontmatter lite** — not bare paragraph, not KEP/RFC comprehensive, not GitHub issue-template conditionals.
- **D-108-05b:** File naming: `.planning/v1.23/findings/NNNN-slug.md` (zero-padded, sequential from `0001` during Phase 109). Optional `assets/` subdir for screenshots — never required for classification.
- **D-108-05c:** `TEMPLATE.md` frontmatter (required): `id`, `slug`, `classification` (a|b|c|d), `walkthrough_step`, `captured`, `status` (open|fixed|deferred), `fixed_in`, `deferred_to`. Body sections: **Expected**, **Actual**, **Evidence**, optional **Classification note** (one line). Seed rationale / `trigger_when` deferred to Phase 110 `SEED-NNN.md` authoring — not in hot-path capture template.
- **D-108-05d:** `README.md` **4-question decision tree** (classify in <30s):

  1. Blocked or wrong answer? → **(a) breakage**
  2. Prose missing/wrong/contradicts shipped behavior? → **(c) doc gap**
  3. Needs new capability (Evidence subject, RBAC DSL, multi-phase redesign)? → **(d) design gap**
  4. Else works but annoys → **(b) DX papercut** (fix if ≤1 narrow plan; else defer like d)

- **D-108-05e:** Routing table + six paste-ready boundary examples in README (missing manifest footnote → c; filter label confusing → b; wrong closer #4521 → a; legal-hold subject → d; audit 403 after signup → a; impersonation not in ActorRef → d).
- **D-108-05f:** Phase 109 discipline echoed once in WALKTHROUGH front-matter: observe only; classify at capture; **no in-flight fixes** — even obvious typos become findings.

### Voice & audience (D-108-06)

- **D-108-06a:** **Primary reader:** maintainer executing Phase 109 dry-run on clean clone. **Secondary:** future adopter exploring reference app after Phase 110 fixes — not the authoring target. **Not the reader:** generic Phoenix integrator (`getting-started-saas.md`).
- **D-108-06b:** **Operator runbook voice** — imperative, evidence-oriented, calm senior engineer (brand book §6). Incident-playbook structure (`guides/incident-playbook.md` precedent): scenario question as H3, not tutorial pedagogy ("Understanding capture").
- **D-108-06c:** Per-step **Do / Expected / If different** trio. **STOP** only on hard blockers (install fail, scenario unanswerable); soft gaps continue walk with finding filed.
- **D-108-06d:** Reference app **proof script** language — never "demo product" rebrand (Phase 104 charter). WALK-01 includes **fresh register path** (any new email) **and** seeded persona logins (D-107-02d) — both documented.

### WALKTHROUGH.md section outline (D-108-07)

- **§0 Before you start** — prerequisites, Phase 109 discipline, findings link, manifest pointer
- **§1 Clean clone install** (WALK-01 bootstrap)
- **§2 Onboarding** (WALK-01 — register, confirm, seeded login, first ticket reply)
- **§3 Daily use** (WALK-02 — agent reply+close, admin recent activity, support triage)
- **§4 Operator incidents** (WALK-03 — four incidents D-108-02b)
- **§5 Evidence plane exercises** (WALK-04 — three exercises D-108-04b)
- **Appendix A — Demo reference** (synced literals)
- **Appendix B — Command cheat sheet**
- **Further reading** (optional, not required for run)

### Claude's Discretion

- Exact § numbering style (`§4.1` vs `WALK-03-01`) — pick one scheme and apply consistently.
- Whether to add `mix verify.evidence` alias vs footnote-only.
- Exact leaving-agent persona email/display name (must match manifest once published).
- Checkpoint table column formatting.
- Optional `walkthrough_doc_contract_test.exs` in Phase 108 vs Phase 110 — recommended: assert appendix literals (`4521`, `4518`, `walk-retention-offboarded-co`, `2026-05-20T14:30:00Z`, `mix demo.reset`) if planner has bandwidth.

### Folded Todos

(none — `todo.match-phase` returned empty)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contracts

- `.planning/ROADMAP.md` § Phase 108–110 — goals, success criteria, scope guards, fix-vs-defer chain
- `.planning/REQUIREMENTS.md` — WALK-01 through WALK-04, FINDINGS-01/02, FIX-01/03, Out of Scope
- `.planning/phases/104-reference-walkthrough-charter-override-decision/104-CONTEXT.md` — synthetic adopter, v1.23 non-goals, `.planning/v1.24-seeds/` routing vocabulary
- `.planning/phases/107-realistic-seed-data-demo-mix-tasks/107-CONTEXT.md` — manifest SSOT, four hero stories, redaction/delete semantics, org Y post-purge end state

### Example app (authoring surface)

- `examples/threadline_phoenix/DEMO-MANIFEST.md` — literal SSOT; Appendix A copies from here
- `examples/threadline_phoenix/DEMO_USERS.md` — credentials + walkthrough step mapping
- `examples/threadline_phoenix/README.md` — install commands, operator surface mount, `/audit` recipe
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex` — programmatic literals
- `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` — executable ground truth for heroes

### Guides & operator paths

- `guides/getting-started-saas.md` — integrator path (explicitly NOT the walkthrough reader)
- `guides/operator-surface.md` — route literals, auth seams, export/coverage/policy paths
- `guides/domain-reference.md` — actor window, row history, delete/redaction semantics, support questions Q1–Q5
- `guides/how-threadline-works.md` — evidence plane overview (no `guides/evidence-plane.md` on disk)
- `guides/incident-playbook.md` — Expected output subsection precedent for incident steps

### Vision, ecosystem lessons, OSS DNA

- `prompts/threadline-elixir-oss-dna.md` — honest verification, named `mix verify.*` entrypoints, doc contract tests
- `prompts/audit-lib-domain-model-reference.md` — capture vs semantics; AuditAction vs AuditChange
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — django-auditlog masking, Logidze soft-delete footguns, SIEM manifest pattern, hybrid row+action model
- `prompts/THREADLINE-GSD-IDEA.md` — project vision and constraints

### Findings destination (Phase 108 creates)

- `.planning/v1.23/findings/TEMPLATE.md` — to be authored
- `.planning/v1.23/findings/README.md` — to be authored

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `DEMO-MANIFEST.md` + `ThreadlinePhoenix.Demo.Manifest` — all walkthrough literals already locked (Phase 107)
- `DEMO_USERS.md` — persona → step mapping including deleter for WALK-03-04
- `mix demo.seed` / `mix demo.reset` — daily walk loop; WALKTHROUGH §0 + Appendix B cite these
- `demo_contract_test.exs` — semantic fingerprint tests; WALKTHROUGH **Verify** sections reference, do not duplicate
- `guides/incident-playbook.md` — step shape precedent (Question → Diagnosis → Expected output)
- Seeded evidence rows for `retention_run`, `retention_policy`, `trigger_coverage` — **not** `redaction_policy` (gap D-108-04e)

### Established Patterns

- Doc stack: README = map; guides = integrator; example README = contract; manifest = SSOT; walkthrough = derived runbook
- Operator incidents: one utterance = one playbook = one manifest hero (SIEM search-pack pattern)
- Evidence plane: viewer tasks exit 0; document `claim_assessment.status` honestly (`proven` vs `inferred_posture`)
- Findings: observe-then-fix separation (Phase 109 scope guard); same v1.24-seeds routing as Phase 104 soft signals
- Redaction: `[REDACTED]` in expected outputs; never quote `WALKTHROUGH-INTERNAL-SECRET-4521`

### Integration Points

- Phase 108 outputs feed Phase 109 dry-run (RUN-01..03) and Phase 110 triage (FIX-01..03, DEFER-01)
- Example README "canonical first-hour walkthrough" pointer should be updated in Phase 108/110 to cite `WALKTHROUGH.md` for reference-app path (doc gap if left stale)
- ROADMAP Phase 108/109 "three scenarios" → "four incidents" traceability edit in Phase 108

</code_context>

<specifics>
## Specific Ideas

- **Incident pack model:** `DEMO-MANIFEST.md` is the SIEM ingest manifest; WALK-03 is the sample search pack — one detection per question, fixed literals.
- **Stripe test clock:** frozen `demo_epoch` + manifest offsets; human "last Tuesday" always footnoted.
- **Kubernetes troubleshooting:** symptom → steps → expected state; "do not change cluster state during audit" → "do not fix during Phase 109 walk."
- **PaperTrail tutorials:** self-contained runnable exercises with inline expected outcomes — WALKTHROUGH body mirrors this; literals come from appendix not scattered links.
- **Runbook-as-code:** manifest is SSOT; walkthrough appendix is derived view — edit manifest first, sync appendix (same pattern as doc contract tests lock README ↔ guides).
- **Confluence anti-pattern avoided:** no "see README § Installation" mid-procedure — RUN-01 forbids it.

</specifics>

<deferred>
## Deferred Ideas

- **Split public WALKTHROUGH vs maintainer-only runbook** — single file for Phase 108/109; revisit post-110 if adopter polish needs separate artifact
- **Livebook notebook runner** derived from same appendix literals — v1.24+ if repeat walks justify tooling
- **`mix verify.evidence` alias** — only if footnote proves insufficient during Phase 109; not mandatory in 108
- **Screenshot-based proof in findings** — optional `assets/` only; text routes + literals are primary evidence
- **Per-org retention purge in `lib/`** — design gap (d) if pressured; org Y story stays host narrative in evidence `detail`
- **Adopter-tutorial voice rewrite** — after Phase 110 fixes, add "Last verified" date; do not dual-voice in Phase 108

### Reviewed Todos (not folded)

(none)

</deferred>

---

*Phase: 108-walkthrough-script-finding-capture-protocol*
*Context gathered: 2026-05-27*
