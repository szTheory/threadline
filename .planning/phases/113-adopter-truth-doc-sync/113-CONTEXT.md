# Phase 113: Adopter Truth & Doc Sync - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Repair reference and documentation drift so 0.5.x evaluators see an honest sigra-reference lane: admin-reachable `/audit/evidence`, adoption-pilot version literals aligned with `mix.exs` / README, single-canonical evidence CLI naming locked in doc-contract tests, and WALK-03-02 operator fiction consistent with seeded time anchors.

Requirements: TRUTH-01, TRUTH-02, TRUTH-03, TRUTH-04, TRUTH-05.

Scope guard: `examples/threadline_phoenix/`, `guides/`, doc-contract tests. No new Evidence subjects. No `lib/` unless explicitly reopened (TRUTH-03 does **not** require an alias).

Out of scope: ExampleCloud STG matrix rewrite, `mix verify.evidence` alias, support-scoped evidence UI, full `.planning/milestones/v1.22-phases/**` archive sweep.

</domain>

<decisions>
## Implementation Decisions

### Evidence mount authorization (TRUTH-01) — D-113-01

- **D-113-01a:** Add **`my_evidence_authorize_fn/1`** beside existing export/auth callbacks — **admin-only** (`%{is_admin: true} → :ok`; all others deny).
- **D-113-01b:** Wire **`evidence_authorize_fn:`** on `threadline_operator_surface/2` mount in `router.ex`. Do **not** change `my_authorize_fn/1`, `my_export_authorize_fn/1`, or `scope_query_fn/3` (Phase 106 lock).
- **D-113-01c:** Do **not** reuse `my_export_authorize_fn` as evidence gate (avoids coupling export policy to evidence forever).
- **D-113-01d:** Do **not** grant support `{:ok, scope}` on evidence — library does not scope evidence queries today; enabling support would imply tenancy isolation that does not exist (cross-org governance records leak).
- **D-113-01e:** Document explicitly in example README + `guides/getting-started-saas.md` mount snippet: support reaches scoped `/audit` timeline; **`/audit/evidence` denied** → Unsupported View + CLI fallback `mix threadline.evidence.show`.
- **D-113-01f:** Optional but recommended: example integration test — admin live session sees evidence UI; support sees Unsupported View (mirror `evidence_live_test.exs` patterns in lib tests).

**Rationale synthesis:** Evidence plane = audit-of-audit governance (retention runs, redaction drift, trigger coverage) — same audience tier as `/audit/coverage` and `/audit/policy`, not L1 support triage. Matches CloudTrail/GitHub/Stripe pattern: investigation ≠ compliance console.

### Evidence CLI naming (TRUTH-03) — D-113-02

- **D-113-02a:** **Canonical runnable command only:** `mix threadline.evidence.show` (`lib/mix/tasks/threadline.evidence.show.ex`). **No** `mix verify.evidence` alias in root or example `mix.exs`.
- **D-113-02b:** **`verify.*` namespace stays CI gates only** (`verify.doc_contract`, `verify.example`, `verify.threadline`, etc.) — not operator viewers. Evidence task is explicitly a **viewer** (exits 0 on `unsupported` claims); aliasing as `verify.evidence` implies gate semantics (wrong surprise).
- **D-113-02c:** **WALKTHROUGH §5 footnote** — tighten to past tense: earlier milestones named `mix verify.evidence`; **that alias was never shipped**; use `mix threadline.evidence.show` in body and Appendix B.
- **D-113-02d:** Add **`test/threadline/evidence_cli_doc_contract_test.exs`**; wire into `mix verify.doc_contract` alias list in root `mix.exs`.
- **D-113-02e:** Contract assertions:
  - `guides/domain-reference.md`, `guides/operator-surface.md` — assert canonical; refute `mix verify.evidence`
  - `examples/threadline_phoenix/WALKTHROUGH.md` — assert canonical in command blocks; allow **at most one** footnote mention of `verify.evidence` (or refute entirely after archive cleanup)
  - `mix.exs` — refute `"verify.evidence":` alias
  - `README.md` — keep **refute** on both CLI strings (compact strip unchanged)
- **D-113-02f:** Living planning index: replace dual `verify.evidence` / `threadline.evidence.show` phrasing in `.planning/PROJECT.md` and `.planning/MILESTONES.md` with canonical only + one global footnote that the planned verify name was never shipped.

### Adoption-pilot version sync (TRUTH-02) — D-113-03

- **D-113-03a:** **Medium refresh** of `guides/adoption-pilot-backlog.md` — not full ExampleCloud matrix rewrite.
- **D-113-03b:** Update **Distribution preflight** table only: `threadline` **0.5.0** on Hex (status = actual publish truth), `{:threadline, "~> 0.5"}`, `@version` from `mix.exs`, doc-contract pointer to new adoption test.
- **D-113-03c:** Add **one orientation sentence** in intro or Evidence pass header: distribution preflight reflects tree **0.5.x** (`mix.exs` SSOT); lane/version story in `guides/upgrade-path.md`.
- **D-113-03d:** Do **not** refresh ExampleCloud job row (N/A vs `PostTouchWorker`), test-count prose, or Evidence pass date in this phase — separate honesty ticket if needed.
- **D-113-03e:** Add **`test/threadline/adoption_pilot_doc_contract_test.exs`** — derive expected version from `MixProject.project()[:version]`; assert `~> 0.5`; refute `0.2.0` / `~> 0.2`; optionally assert `guides/upgrade-path.md` cross-link.

### WALK-03-02 prose + contracts (TRUTH-04) — D-113-04

- **D-113-04a:** Replace WALK-03-02 **operator question** (line ~451) with frozen-fiction wording:

  > **Operator question:** Agent **`agent2@acme.example.com`** is leaving — what did they touch from **`demo_last_tuesday`** through **`demo_epoch`**?

- **D-113-04b:** Align **expected outcome** and step 4 with seed truth: **ticket status changes on `tickets` only** — remove “ticket/reply” overclaim (seed has no `ticket_replies` in leaving-agent window).
- **D-113-04c:** Extend **`walkthrough_doc_contract_test.exs`** literals: `demo_last_tuesday`, `demo_epoch`, `33123cc4-da21-5674-b030-e168cee90521`. Do **not** lock full operator-question prose or `"last 24 hours"`.
- **D-113-04d:** Strengthen **`demo_contract_test.exs`** `"SEED-03 leaving agent window"`: `assert count == 12` (matches `@leaving_agent_tx_count`); add `audit_changes` join asserting `table_name == "tickets"` ≥ 1. Prefer `Manifest.last_tuesday()` / `Manifest.epoch()` for bounds when touching file.
- **D-113-04e:** No LiveView filter UI tests — fiction consistency only.

### Planning / archive doc scope (TRUTH-03 adjunct) — D-113-05

- **D-113-05a:** **Runnable three-source surface** is test-locked: guides, example WALKTHROUGH/README, doc-contract tests.
- **D-113-05b:** Edit **living** `.planning/PROJECT.md` + `.planning/MILESTONES.md` bullets to canonical CLI (D-113-02f).
- **D-113-05c:** Add **errata block** (2 lines) atop affected sections in `.planning/milestones/v1.23-REQUIREMENTS.md` and `v1.23-ROADMAP.md` WALK-04 success criteria — do not silently rewrite closed checkboxes.
- **D-113-05d:** **Immutable:** `.planning/milestones/v1.22-phases/**`, Phase 108/107 discussion artifacts, `RETROSPECTIVE.md` body.
- **D-113-05e:** Narrow TRUTH-03 acceptance text when complete: targets are runnable docs + PROJECT index + v1.23 errata — not “v1.22 archives” (v1.22 frozen files already use canonical task name).

### Coherent architecture principles (cross-cutting)

- **Host-owned capability gates:** Separate `*_authorize_fn` per privileged surface (export, coverage, policy, evidence) — django-auditlog per-model permissions / Grafana fixed roles pattern; Threadline does not ship RBAC DSL.
- **Honest reference app:** Admin completes WALK-04 on `/audit/evidence`; support uses scoped timeline + CLI — principle of least surprise aligned with export denial.
- **Doc contracts over folklore:** Version and CLI literals enforced in tests; planning prose links to runnable docs (OSS DNA §2).
- **Frozen demo fiction:** Named manifest anchors + absolute ISO instants — never wall-clock-relative “last 24h” when seeds use `demo_epoch` / `demo_last_tuesday` (Stripe test-clock pattern).

### Claude's Discretion

- Exact doc wording for support denial in example README vs getting-started mount comment.
- Whether to refute `verify.evidence` entirely in WALKTHROUGH after PROJECT cleanup (vs keeping one footnote).
- Hex row “Done” vs “Pending” in adoption-pilot table (human truth on publish state).
- Optional admin/support evidence LiveView test file placement and naming.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Vision & domain model
- `prompts/audit-lib-domain-model-reference.md` — Evidence entity; exploration layer; host-owned auth
- `prompts/THREADLINE-GSD-IDEA.md` — Correct-by-default; honest reference; non-goals
- `prompts/threadline-elixir-oss-dna.md` — `mix verify.*` CI entrypoints; doc contracts; version SSOT
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — django-auditlog middleware/set_actor; opaque storage footguns; operator tooling

### Requirements & milestone
- `.planning/REQUIREMENTS.md` — TRUTH-01 through TRUTH-05
- `.planning/ROADMAP.md` — Phase 113 scope guard and success criteria
- `.planning/threads/2026-05-27-milestone-next-step-v1.24.md` — Pre-registered doc drift (WR-110-001, CLI naming)
- `.planning/phases/110-triage-narrow-fixes/110-REVIEW.md` — WR-110-001 operator question gap

### Prior phase decisions (locked)
- `.planning/phases/108-walkthrough-script-finding-capture-protocol/108-CONTEXT.md` — D-108-03f canonical CLI + footnote pattern
- `.planning/phases/106-sigra-auth-lane-in-reference-app/106-CONTEXT.md` — D-106-02h no authorize_fn changes
- `.planning/phases/112-reference-app-adopts-helper/112-CONTEXT.md` — Helper adoption (context for 0.5.x honesty, not STG matrix)

### Implementation targets
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — mount + new `my_evidence_authorize_fn/1`
- `examples/threadline_phoenix/WALKTHROUGH.md` — WALK-03-02 operator question; §5 footnote
- `guides/adoption-pilot-backlog.md` — distribution preflight table
- `guides/operator-surface.md` — evidence gate + CLI fallback
- `guides/integration-contracts.md` — `evidence_authorize_fn` contract
- `lib/threadline/operator_surface/auth.ex` — default `fn _ -> false`; boolean enable semantics
- `lib/mix/tasks/threadline.evidence.show.ex` — canonical viewer; “not a gate” moduledoc
- `test/threadline/readme_doc_contract_test.exs` — README compact strip
- `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` — leaving-agent window
- `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs` — RUN-01 literals

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `my_export_authorize_fn/1` — template for admin-only capability gate (parallel to evidence)
- `Threadline.OperatorSurface.EvidenceLiveTest` — lib test mount with `evidence_authorize_fn` example
- `mix threadline.evidence.show` — shipped viewer with flag-style CLI (`--subject`, `--subject-ref-json`)
- `walkthrough_doc_contract_test.exs` — literal-lock pattern for WALKTHROUGH
- `release_artifact_contract_test.exs` / `getting_started_saas_doc_contract_test.exs` — `~> 0.5` version lock pattern

### Established Patterns
- Capability-specific `*_authorize_fn` defaults false; host opts in per surface
- `verify.*` = repo CI aliases; `threadline.*` = domain/operator tasks
- Frozen demo anchors in `Demo.Seed.Anchors` + `Manifest` module
- Doc-contract tests derive version from `MixProject.project()[:version]`

### Integration Points
- `mix verify.doc_contract` — add evidence CLI + adoption pilot tests to alias list
- `mix verify.example` — walkthrough + demo_contract tests after WALK-03-02 edits
- Example README + getting-started mount snippet — sync `evidence_authorize_fn` for doc markers

</code_context>

<specifics>
## Specific Ideas

### Canonical `my_evidence_authorize_fn/1`

```elixir
def my_evidence_authorize_fn(%{assigns: assigns}) do
  case assigns[:current_user] do
    %{is_admin: true} -> :ok
    _ -> {:error, :unauthorized}
  end
end
```

### Expected session matrix (reference app)

| Session | `/audit` | `/audit/evidence` | CLI fallback |
|---------|----------|---------------------|--------------|
| Admin | Cross-org | Enabled | `mix threadline.evidence.show` |
| Support | Org-scoped | Unsupported View | Same CLI (no LiveView) |
| Agent | Denied at pipeline | N/A | N/A |

### WALK-03-02 operator question (final)

```markdown
**Operator question:** Agent **`agent2@acme.example.com`** is leaving — what did they touch from **`demo_last_tuesday`** through **`demo_epoch`**?
```

</specifics>

<deferred>
## Deferred Ideas

- **`mix verify.evidence` alias** — only if external procurement mandates the verify namespace; footnote + contracts sufficient for v1.24
- **Support-scoped evidence UI** — requires `scope_query_fn` seam for evidence queries; new capability phase
- **ExampleCloud STG matrix refresh** — job row N/A vs `PostTouchWorker`; `Audit.transaction/3` in fiction table
- **Deep leaving-agent contract** — org-scoping SQL assertion; reply-table seed extension
- **Full `.planning/milestones/` archive sweep** — violates milestone hygiene; v1.22-phases already canonical

### Reviewed Todos (not folded)

No pending todos matched phase 113 via `gsd-sdk query todo.match-phase`.

</deferred>

---

*Phase: 113-adopter-truth-doc-sync*
*Context gathered: 2026-05-27*
