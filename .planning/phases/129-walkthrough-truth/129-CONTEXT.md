# Phase 129: WALKTHROUGH Truth - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix maintainer walkthrough doc lies in `examples/threadline_phoenix/WALKTHROUGH.md` so evaluators on a clean clone do not hit cwd mistakes or misleading row-history URLs. Doc-contract tests lock the fixes. No library API changes, no router changes, no new product surface, no synthetic walkthrough v2.

</domain>

<decisions>
## Implementation Decisions

### verify.threadline cwd strategy (WALK-01)

- **D-129-01:** Replace optional verify lines with **`mix threadline.verify_coverage`** run from the existing **`examples/threadline_phoenix/`** cwd — **not** `mix verify.threadline` from repo root. Root `verify.threadline` maps to the same underlying task but resolves **`Threadline.Test.Repo`** and **`threadline_ci_coverage_canary`** (root `config/test.exs`); the walkthrough just migrated help-desk tables on **`ThreadlinePhoenix.Repo`** with example-app `:verify_coverage` expected_tables. A root `cd ../.. && mix verify.threadline` would exit 0 against the **wrong database** — worse than the current "task not found" failure.
- **D-129-02:** §0 prerequisites gain one clarifying sentence: **walk steps** stay in `examples/threadline_phoenix/`; **contributor CI gates** (`mix verify.*`, `mix ci.all`) run from **repository root** with cross-link to [`CONTRIBUTING.md`](../../CONTRIBUTING.md). Same namespace discipline as Phase 113 (`verify.*` = CI gates; `threadline.*` = host/operator tasks) and the existing `verify.evidence` → `threadline.evidence.show` WALKTHROUGH precedent.
- **D-129-03:** §1 WALK-01-02 and §5 WALK-04-03 optional verify blocks use fenced `mix threadline.verify_coverage` with one sentence noting it uses this app's `config :threadline, :verify_coverage` and `ThreadlinePhoenix.Repo`. One optional footnote may mention root `mix verify.threadline` only as the **full maintainer CI ladder** pointer — not as a walk step command.
- **D-129-04:** **Reject** example-app wrapper alias `"verify.threadline"` — dual semantics (root CI gate vs host check) violates Phase 113 and principle of least surprise. **Reject** removing verify lines entirely — loses cheap trigger-coverage signal immediately after migrate (correct-by-default regression).

### Row-history URL presentation (WALK-02)

- **D-129-05:** Adopt **hybrid pattern** mirroring `guides/operator-surface.md` §179–196 — shorthand `/audit/rows/:table/:pk` describes the **operator question**; shipped route is **`/audit/transactions/:id/history/:table/:record_id`** (transaction-scoped slide-over via **History** link on change rows). No standalone `/audit/rows/` route is mounted (`lib/threadline/operator_surface/router.ex`).
- **D-129-06:** **Do steps** (WALK-03-01 step 6, WALK-03-04 step 5, WALK-04-02 step 5) become **navigation-first**: "On the transaction drill-down, click **History** on the change row" with canonical URL as reference (`/audit/transactions/:id/history/ticket_replies/:record_id`). **Do not** present pasteable `/audit/rows/…` URLs in Do prose — runbook URLs in backticks must work or steps must say click, not paste (Grafana/Sentry contextual drill-down pattern).
- **D-129-07:** **Operator surface tables** (6 rows across §2–§5) keep shorthand in the route column but relabel explicitly: `Row history … *(shorthand /audit/rows/…)*` with **Drill-down** column showing canonical path via **History** link. Matches operator-surface parity table vocabulary without a repo-wide shorthand purge.
- **D-129-08:** New **§0 subsection "Row history URLs"** — one-time SSOT callout: shorthand vs canonical, "Do **not** paste `/audit/rows/…`", cross-link to [`guides/operator-surface.md`](../../guides/operator-surface.md) § Row History / As-of Sub-view. **Reject** §0 footnote-only (Option D) — fails WALK-02 and dry-run maintainers skip §0. **Reject** replace-all-canonical everywhere (Option B) — breaks operator-surface.md parity table convention and over-churns reference sections intentionally using conceptual paths.

### Doc-contract strictness (WALK-03)

- **D-129-09:** Extend **`examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs`** (Option A) — keep existing RUN-01 literal-presence test unchanged; add new `describe` blocks for WALK-01/02 truth. **Reject** new dedicated file (unnecessary split). **Reject** minimal locks-only (Option C) — leaves `/audit/rows/` Do-step regressions undetected.
- **D-129-10:** Two-tier contract model (Phase 128 D-128-15): **footgun locks** (canonical literals + ordering) + **semantic locks** (refutes for known-bad patterns). Add helpers: `section_slice/3`, `step_do_slice/3` (copy pattern from root `readme_doc_contract_test.exs`).
- **D-129-11 — WALK-01 locks:** Assert `mix threadline.verify_coverage` in verify contexts (§1 and §5). **Refute** bare `mix verify.threadline` anywhere in WALKTHROUGH (unless zero occurrences after edit — refute still guards regression). Assert §0/§1 still documents `examples/threadline_phoenix/` as walk cwd.
- **D-129-12 — WALK-02 locks:** Assert global canonical route literal `/audit/transactions/:id/history/:table/:record_id`. In WALK-03-01 and WALK-03-04 **Do** slices: assert canonical history path; **refute** `/audit/rows/ticket_replies/` in Do prose. In WALK-04-02 step 5 corroboration: refute bare `/audit/rows/`. Optional cheap router cross-check: `lib/threadline/operator_surface/router.ex` contains `live("/transactions/:id/history/:table/:record_id"`.
- **D-129-13 — CI gate:** Run via existing **`mix verify.example`** (already executes full example-app `mix test`). **Do not** add walkthrough contract to root `verify.doc_contract` alias list — WALKTHROUGH is maintainer-only example-app doc; root doc contracts stay for hub/lane guides.

### Phase scope boundary

- **D-129-14:** **In scope:** `examples/threadline_phoenix/WALKTHROUGH.md` + `walkthrough_doc_contract_test.exs` only.
- **D-129-15:** **Out of scope:** `examples/threadline_phoenix/README.md` (already honest — no `verify.threadline`, no `/audit/rows/` URLs; map role preserved). Root README, getting-started, operator-surface guide (already SSOT — link, don't rewrite). Router/code changes.
- **D-129-16:** Add one **Further reading** bullet in WALKTHROUGH → `guides/operator-surface.md` row-history section (minimal cross-link C — Phase 128 cross-link pattern).

### WALK-01 requirement reinterpretation

- **D-129-17:** REQUIREMENTS.md WALK-01 text ("runs `mix verify.threadline` from repo root") is superseded by semantic truth: walkthrough optional verify must check **this app's** trigger coverage on **this app's repo**. Implementation satisfies WALK-01 intent (cwd honesty) via D-129-01–03. Update REQUIREMENTS checkbox traceability note in phase SUMMARY, not a premature REQUIREMENTS.md edit in this phase unless planner includes it.

### Claude's Discretion

- Exact §0 row-history subsection heading and prose wording
- Whether WALK-04-02 step 5 says "Repeat WALK-03-01 step 6" vs rewrites navigation inline
- Optional router cross-check test in contract (recommended but not blocking)
- Exact operator-table column relabeling phrasing as long as shorthand/canonical distinction is unambiguous

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements and assessment
- `.planning/REQUIREMENTS.md` — WALK-01, WALK-02, WALK-03
- `.planning/ROADMAP.md` — Phase 129 success criteria
- `.planning/threads/2026-05-28-milestone-next-step-post-v1.27.md` — footgun evidence (verify cwd lie, row-history URL gap)
- `.planning/milestones/v1.27-MILESTONE-AUDIT.md` — WALKTHROUGH `/audit/rows/` vs transaction-scoped route finding

### Doc SSOT (mirror, do not diverge)
- `guides/operator-surface.md` §179–196 — Row History shorthand vs canonical path; `:schemas` reification
- `guides/production-checklist.md` §1 — `mix threadline.verify_coverage` host task reference
- `CONTRIBUTING.md` — root `mix verify.*` / `mix ci.all` maintainer ladder
- `guides/evaluating-threadline.md` — evaluator CI entrypoints from repo root

### Shipped route proof
- `lib/threadline/operator_surface/router.ex` — `live("/transactions/:id/history/:table/:record_id", TransactionLive, :history)`
- `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` — canonical path integration proof

### Config truth (verify cwd semantics)
- `mix.exs` (root) — `verify.threadline` alias → `threadline.verify_coverage`
- `config/test.exs` (root) — `threadline_ci_coverage_canary` on `Threadline.Test.Repo`
- `examples/threadline_phoenix/config/dev.exs` — help-desk `expected_tables` on `ThreadlinePhoenix.Repo`

### Doc-contract patterns (extend, do not reinvent)
- `examples/threadline_phoenix/test/threadline_phoenix/walkthrough_doc_contract_test.exs` — extend here
- `test/threadline/readme_doc_contract_test.exs` — `section_slice/3`, ordering/refute patterns (Phase 128)
- `.planning/milestones/v1.24-phases/113-adopter-truth-doc-sync/113-CONTEXT.md` — `verify.*` vs `threadline.*` namespace (D-113-02b)
- `.planning/phases/128-readme-phx-gen-auth-mount-parity/128-CONTEXT.md` — two-tier doc contracts (D-128-15)

### Project DNA and vision
- `prompts/threadline-elixir-oss-dna.md` — verify entrypoints as product surface; doc contracts lock README ↔ guides ↔ example alignment
- `prompts/audit-lib-domain-model-reference.md` — host-owned auth; operator surface as exploration layer
- `CLAUDE.md` — correct-by-default, composable Phoenix integration

### Prior walkthrough precedent
- `examples/threadline_phoenix/WALKTHROUGH.md` §5 footnote — `verify.evidence` → `threadline.evidence.show` fix pattern

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `walkthrough_doc_contract_test.exs` — existing RUN-01 literal locks; extend with WALK-01/02 truth describes
- `readme_doc_contract_test.exs` — `section_slice/3` helper pattern for scoped assertions
- `operator_surface_test.exs` — canonical row-history URL proof to mirror in docs

### Established Patterns
- **Maintainer runbook cwd** — WALKTHROUGH §0 locks `examples/threadline_phoenix/`; example README defers maintainer walk to WALKTHROUGH (Track B)
- **Contributor verify ladder** — root `mix ci.all` with `verify.threadline` on library test harness; not duplicated in example mix.exs
- **Operator-surface shorthand** — guide documents conceptual `/audit/rows/:table/:pk` vs shipped transaction-scoped history route
- **Namespace split** — `verify.*` = CI gates; `threadline.*` = host/operator tasks (Phase 113)

### Integration Points
- WALKTHROUGH §1 WALK-01-02 verify line (~L120) and §5 WALK-04-03 verify line (~L730)
- WALKTHROUGH §4 incident Do steps and operator-surface tables (8 `/audit/rows/` occurrences)
- `mix verify.example` — CI gate that will run extended contract tests

</code_context>

<specifics>
## Specific Ideas

### Ecosystem lessons applied
- **Oban/LiveDashboard monorepo pattern:** library CI aliases on root; example app documents host-local `threadline.*` tasks — not copied `verify.*` aliases.
- **Phase 113 `verify.evidence` precedent:** phantom CI alias in walkthrough → canonical host task name with contract refute.
- **Grafana/Sentry runbook pattern:** procedural steps use working navigation or complete URLs; conceptual shorthand belongs in reference tables only.
- **Phase 128 doc architecture:** README-as-map for integrators; WALKTHROUGH-as-executable for maintainers; SSOT cross-links over duplication.
- **Rails/npm workspaces footgun:** same command name, different config scope by cwd — avoid Option D wrapper alias.

### Coherent package (all four areas)
1. `mix threadline.verify_coverage` from example cwd + §0 root-vs-walk cwd split
2. Hybrid row-history URLs: navigation-first Do steps + labeled shorthand in tables + §0 callout
3. Extended walkthrough doc contract with refutes; gated by `verify.example`
4. WALKTHROUGH.md only + one Further reading cross-link; README untouched

</specifics>

<deferred>
## Deferred Ideas

- PROJECT.md L167 drift (`/audit/rows/:table/:pk` described as mounted route) — note for future doc-truth pass; use operator-surface shorthand wording if corrected
- Repo-wide elimination of `/audit/rows/` shorthand from operator-surface guide parity table — larger SSOT change than Phase 129 needs
- Adding walkthrough contract to root `verify.doc_contract` — unnecessary duplication
- Example-app `verify.threadline` wrapper alias — rejected (dual semantics)
- Synthetic walkthrough v2 — REQUIREMENTS out of scope

### Reviewed from Phase 128
- WALKTHROUGH cwd / row-history URL truth — **now in scope** (this phase)

</deferred>

---

*Phase: 129-walkthrough-truth*
*Context gathered: 2026-05-28*
