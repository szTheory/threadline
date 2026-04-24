# Project retrospective

*Living document updated after each milestone.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-04-23  
**Phases:** 4 | **Plans:** 10

### What was built

- PostgreSQL trigger-backed capture with grouped transactions and PgBouncer-safe context propagation.
- First-class audit semantics and request/job context without ETS or process dictionary stores.
- Operator-facing query helpers, trigger coverage health checks, and telemetry instrumentation.
- README-first onboarding, domain reference guide, and Hex-ready packaging.

### What worked

- Strict phase ordering (capture → semantics → query → docs) kept each slice independently verifiable.
- A single research gate (`01-01`) de-risked the highest-uncertainty decision early.

### What was inefficient

- Requirements checkboxes lagged the roadmap briefly; closing the milestone required reconciling traceability with shipped code.

### Patterns established

- `mix verify.*` / `mix ci.*` as the default quality entrypoints.
- Trigger naming prefix (`threadline_audit_%`) as the contract between SQL generation and health checks.

### Key lessons

1. Treat REQUIREMENTS.md traceability as part of “done” for each phase, not only at milestone close.
2. Keep capture logic out of `SET LOCAL` in the trigger path; document PgBouncer constraints in user-facing docs early.

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: single focused execution wave through Phase 4.
- Notable: Phase directories archived under `milestones/v1.0-phases/` to cap `.planning/` growth.

---

## Milestone: v1.1 — GitHub, CI, and Hex

**Shipped:** 2026-04-23  
**Phases:** 4 | **Plans:** 7

### What was built

- Canonical GitHub hosting with `origin`, aligned package URLs, and `main` pushed for CI and releases.
- GitHub Actions contract plus release-hygiene jobs; maintainer-recorded green runs on `main`.
- Public **`threadline` 0.1.0** on Hex with `v0.1.0` tag and changelog alignment.
- Phase 8 audit closure: live CI-02 proof, traceability, and verification docs reconciled.

### What worked

- Treating **CI-02** as “green on GitHub for `origin/main`,” not only local `mix ci.all`, avoided false “done” states.
- Adding Phase 8 explicitly absorbed audit gap-closure without destabilizing Phases 5–7 scope.

### What was inefficient

- `STATE.md` and `PROJECT.md` lagged briefly behind Hex publish; milestone close required one more documentation pass.

### Patterns established

- Phase `*-VERIFICATION.md` holds **run id + SHA** literals for Nyquist and human audit replay.
- Tag-triggered Hex publish workflow separate from PR CI keeps secrets off untrusted builds.

### Key lessons

1. Close the loop on **remote vs local** (`origin/main` SHAs) before calling distribution requirements “done.”
2. Keep **REQUIREMENTS.md** traceability updates in the same change set as verification refreshes.

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: focused waves through CI, Hex, then push/verify.
- Notable: Phase directories archived to `milestones/v1.1-phases/` at close.

---

## Milestone: v1.2 — Before-values & developer tooling

**Shipped:** 2026-04-23  
**Phases:** 3 | **Plans:** 6

### What was built

- Optional **UPDATE** before-values (`changed_from`) with per-table opt-in at trigger generation and stable query loading via `history/3`.
- **`mix threadline.verify_coverage`** plus policy module, tests, and CI-visible failure path for missing triggers.
- **Doc contract tests** mirroring README quickstart, extended `ci.all` / Actions / Nyquist literals for new verify steps.
- **`Threadline.Continuity`**, **`mix threadline.continuity`**, brownfield integration test, and **`guides/brownfield-continuity.md`** for honest cutover semantics.

### What worked

- Splitting **coverage enforcement** (TOOL-01) from **doc drift** (TOOL-03) kept CI failure modes legible.
- Reusing **`Threadline.Health.trigger_coverage/1`** as the single source of truth for verify output avoided contradictory tooling.

### What was inefficient

- `gsd-sdk query milestone.complete` did not archive phase directories in this environment (`version required for phases archive`); phase trees stayed under `.planning/phases/` until optional `/gsd-cleanup`.

### Patterns established

- **Doc fixtures** as compile-checked mirrors of public README examples.
- **Continuity** as an explicit operator surface (`explain_cutover`, `assert_capture_ready!`) separate from silent data fabrication.

### Key lessons

1. Brownfield adoption deserves **first-class docs + Mix task** alongside triggers, not an appendix note.
2. Run **`/gsd-audit-milestone`** before close when you want a durable audit artifact (none was produced for v1.2 in `.planning/`).

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: phased execution across 9 → 10 → 11 with tight scope per plan.
- Notable: PostgreSQL-dependent tests relied on CI when local agents lacked Postgres.

---

## Milestone: v1.3 — Production adoption (redaction, retention, export)

**Shipped:** 2026-04-23  
**Phases:** 3 | **Plans:** 6

### What was built

- **Redaction at capture:** `RedactionPolicy`, `TriggerSQL` exclude/mask paths, `config :threadline, :trigger_capture`, generator and integration tests proving JSONB payloads never carry excluded or raw masked values.
- **Retention + purge:** `Threadline.Retention.Policy`, `Threadline.Retention.purge/1`, `mix threadline.retention.purge`, documented windows, batching, dry-run / execute gates, orphan transaction cleanup.
- **Export:** `Threadline.Export` (CSV/JSON/stream/count), shared strict timeline filter validation with `Threadline.Query`, `mix threadline.export`, README and domain guide discovery.

### What worked

- Keeping export on the **same query spine** as `timeline/2` avoided a second filter dialect for operators.
- **Codegen-time** redaction validation caught impossible policies before migrations shipped.

### What was inefficient

- `gsd-sdk query milestone.complete` again failed with `version required for phases archive`; milestone close required **manual** archive files + `MILESTONES.md` / `ROADMAP.md` edits (same as v1.2).

### Patterns established

- **Mix task** symmetry (`threadline.retention.purge`, `threadline.export`) for operator ergonomics next to library APIs.
- **Strict filter keys** shared between query and export for predictable `ArgumentError` surfaces.

### Key lessons

1. Ship **retention semantics** (what “expired” means vs timeline) in docs the same week as the purge API to avoid ops misreads.
2. Run **`/gsd-audit-milestone`** when you want a durable audit artifact (none for v1.3 in `.planning/`).

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: phased execution across 12 → 13 → 14 with PostgreSQL-dependent verification.
- Notable: Phase directories 12–14 remain under `.planning/phases/` until optional `/gsd-cleanup`.

---

## Milestone: v1.5 — Adoption feedback loop

**Shipped:** 2026-04-23  
**Phases:** 2 | **Plans:** — (integrator-led; evidence in `PLAN.md` / `VERIFICATION.md`)

### What was built

- **`guides/adoption-pilot-backlog.md`** as the operator-facing adoption matrix with distribution preflight and prioritized follow-ups.
- Telemetry operator table in **`guides/domain-reference.md`** with links from **`guides/production-checklist.md`**.
- README / ExDoc wiring so pilots find the backlog beside the checklist.
- **ADOP-03** satisfied with maintainer CI–backed backlog rows; **`AP-ENV.1`** explicitly triaged to **`STG-01`** for host pooler realism.
- **`verify-pgbouncer-topology`** CI job plus topology contract tests for pooler paths.

### What worked

- Honest scoping: maintainer CI evidence counts for **ADOP-03** while **STG-01** carries external staging debt explicitly.
- Reusing **`guides/production-checklist.md`** as the backbone for backlog sections kept docs DRY.

### What was inefficient

- `gsd-sdk query milestone.complete` still fails (`version required for phases archive`); milestone close again required **manual** archives + planning edits.

### Patterns established

- Pilot backlog rows use stable IDs (**`AP-*`**) for triage into requirements or issues without losing narrative context.

### Key lessons

1. Separate **library CI topology proof** from **host-owned staging proof** in writing before calling a pilot “external-complete.”
2. Keep **`/gsd-new-milestone`** immediately after close so **`STG-01`** does not float without a living traceability table.

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: Phases 19–20 executed as a short adoption loop on top of **0.2.0** packaging.
- Notable: Phase directories 19–20 remain under `.planning/phases/` until optional `/gsd-cleanup`.

---

## Milestone: v1.6 — Host staging / pooler parity

**Shipped:** 2026-04-24  
**Phases:** 1 | **Plans:** 2

### What was built

- Adoption backlog **STG** topology template and audited-path rubric with stable markers for doc contracts.
- CONTRIBUTING host STG evidence workflow and production-checklist pointer into the rubric.
- `ci_topology_contract_test.exs` and `stg_doc_contract_test.exs` locking anchors for regression safety.

### What worked

- Treating **library CI topology** and **integrator host staging** as explicitly different proof surfaces avoided over-claiming external environments.
- Small two-plan phase kept verification (`mix ci.all`) as the single heavy gate at the end.

### What was inefficient

- Living **REQUIREMENTS.md** checkboxes lagged **PROJECT.md** until milestone close; reconciliation happened in the archived requirements file.
- `gsd-sdk query milestone.complete` still failed; manual archival duplicated prior milestone toil.

### Patterns established

- **OK / Issue / N/A / Not run** plus “no OK without pointer” as normative rubric text next to the pilot matrix.

### Key lessons

1. Update traceability tables when verification passes, not only at `/gsd-complete-milestone`.
2. Prefer explicit “maintainer vs integrator” ownership sentences in the same doc that hosts the checklist.

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: Phase 21 executed as a short docs + contracts slice after v1.5 adoption loop.
- Notable: Phase directory **21** remains under `.planning/phases/` until optional **`/gsd-cleanup`**.

---

## Milestone: v1.7 — Reference integration for SaaS

**Shipped:** 2026-04-24  
**Phases:** 3 | **Plans:** 5

### What was built

- Canonical **`examples/threadline_phoenix/`** app with path dependency, install/triggers for **`posts`**, and **`mix verify.example`** wired into **`mix ci.all`**.
- HTTP API path with **`Threadline.Plug`**, audited **`Blog.create_post/2`**, and ConnCase coverage for **`audit_changes`** + actor linkage.
- Oban **`PostTouchWorker`** with **`Threadline.Job`**, **`record_action/2`**, and README guidance linking production checklist + adoption backlog (STG rubric).

### What worked

- Keeping the integration surface **example-only** avoided premature **`threadline_web`** / umbrella packaging decisions.
- Reusing **`mix verify.example`** as the repo-root gate kept CI honest for the nested Mix project.

### What was inefficient

- Living **`REQUIREMENTS.md`** and **`ROADMAP.md`** checkboxes lagged **`PROJECT.md`** until close; reconciliation duplicated v1.6 close toil.
- `gsd-sdk query milestone.complete` still failed (`version required for phases archive`); manual archival again.

### Patterns established

- **Sandbox `unboxed_run`** as an escape hatch when nested savepoints hide trigger-visible transaction-local GUC in job tests — document in plan summary when used.

### Key lessons

1. Mark REF/traceability rows **Complete** in the same change set as the last plan’s **`VERIFICATION.md`** refresh.
2. Treat **`audit-open`** + a quick diff of **`REQUIREMENTS.md` vs `PROJECT.md`** as a pre-close habit even without a standalone milestone audit file.

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: Phases 22–24 executed as a tight vertical slice over two days.
- Notable: Phase directories **22–24** moved to **`.planning/milestones/v1.7-phases/`** after close.

---

## Milestone: v1.8 — Close the support loop

**Shipped:** 2026-04-24  
**Phases:** 3 | **Plans:** 5

### What was built

- **`:correlation_id`** on **`Threadline.Query.timeline/2`**, **`timeline_query/1`**, **`export_changes_query/1`**, and **`Threadline.Export`** with strict `audit_actions` join when set; validation, CHANGELOG, integration tests (**LOOP-01**).
- **Support incident queries** playbooks in **`guides/domain-reference.md`** and **`guides/production-checklist.md`**; **`LOOP-04-SUPPORT-INCIDENT-QUERIES`** anchor; **`Threadline.SupportPlaybookDocContractTest`** (**LOOP-02**, **LOOP-04**).
- Example **`POST /api/posts`** path with **`record_action`**, linked **`audit_transactions.action_id`**, **`ThreadlinePhoenixWeb.PostsCorrelationPathTest`**, README **`export_json`** / **`jq`** (**LOOP-03**).

### What worked

- Reusing the **v1.7** example app as the **correlation proof surface** kept the support loop milestone vertically thin.
- **Doc contract tests** for operator-facing guide sections continued the v1.6/v1.7 pattern of **repo-owned** evidence.

### What was inefficient

- **`gsd-sdk query milestone.complete`** still failed with **`version required for phases archive`**; manual **`milestones/v1.8-*`** writes matched **v1.7** close.
- **`PROJECT.md` Active** still listed **LOOP-03** until archive; **`REQUIREMENTS.md`** was already fully checked — reconcile **Active** when the last REQ ships.

### Patterns established

- Linking **`record_action`** to **`audit_transactions.action_id`** in the **same** `Repo.transaction` as audited writes so **strict** correlation filters match row capture.

### Key lessons

1. Treat **`PROJECT.md` Active`** as part of the last phase’s “done” checklist alongside **`REQUIREMENTS.md`** checkboxes.
2. Run **`audit-open`** at milestone close even without a standalone **`MILESTONE-AUDIT.md`**.

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: Phases 25–27 executed as a focused support-loop slice.
- Notable: Phase directories **25–27** archived under **`.planning/milestones/v1.8-phases/`** after tag push.

---

## Milestone: v1.9 — Production confidence at volume

**Shipped:** 2026-04-24  
**Phases:** 3 | **Plans:** 6

### What was built

- Per-event **telemetry** operator narrative and **`## Trigger coverage (operational)`** for **`Threadline.Health`** / **`mix threadline.verify_coverage`**, with checklist + README cross-links (**OPS-01**, **OPS-02**).
- **`guides/audit-indexing.md`** indexing cookbook (access patterns vs **`Threadline.Query`**, **`Threadline.Export`**, retention), ExDoc extra, and **`Threadline.AuditIndexingDocContractTest`** (**IDX-01**, **IDX-02**).
- **`guides/production-checklist.md`** volume / purge cadence guidance tied to **`Threadline.Retention`**; **`## Operating at scale (v1.9+)`** hub in **`guides/domain-reference.md`**; **README** Maintainer-band discovery (**SCALE-01**, **SCALE-02**).

### What worked

- **Docs-first** milestone reused existing APIs; doc contract tests matched the **v1.8** support-playbook pattern.
- Phase work already lived under **`.planning/milestones/v1.9-phases/`**, so close did not require moving trees.

### What was inefficient

- **`gsd-sdk query milestone.complete`** still failed with **`version required for phases archive`**; **`milestones/v1.9-*`** files were written manually again.

### Patterns established

- **Stable HTML `id=` anchors** where heading slugs are ambiguous, so fragment links from checklists and README stay reliable.

### Key lessons

1. Keep **`audit-open`** in the pre-close path even when the milestone is documentation-only.
2. When **`milestone.complete` CLI** cannot archive, copy the **v1.8** close checklist (ROADMAP links, **MILESTONES.md** order, **`git rm` REQUIREMENTS.md**) so the living tree does not keep a stale requirements file.

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: Phases **28–30** executed as a single ops-at-volume slice.
- Notable: Execution history remains under **`.planning/milestones/v1.9-phases/`** (no extra move step at close).

---

## Milestone: v1.10 — Support-grade exploration primitives

**Shipped:** 2026-04-24  
**Phases:** 6 | **Plans (with SUMMARY):** 4

### What was built

- **`Threadline.ChangeDiff`** + **`Threadline.change_diff/2`** with **`test/threadline/change_diff_test.exs`** — deterministic JSON field maps for INSERT/UPDATE/DELETE (**XPLO-01**).
- **`Threadline.Query.audit_changes_for_transaction/2`** + delegator, stable ordering, integration coverage including **FLOW-TEST-01** round-trip to **`change_diff/2`** (**XPLO-02**).
- **`guides/domain-reference.md`** **Exploration API routing (v1.10+)** section, production-checklist cross-link, **`Threadline.ExplorationRoutingDocContractTest`** (**XPLO-03**).
- Audit closure phases **34–36**: **`timeline/2` @doc** parity (**INT-DOC-01**), **`34-VERIFICATION.md`**, **`PROJECT.md`** alignment (**PLANNING-PROJECT-01**), Nyquist/SUMMARY matrix hygiene.

### What worked

- **`/gsd-audit-milestone`** with explicit **closure_evidence** gave a single pre-close truth source before archiving.
- Reusing **doc contract tests** for new guide anchors matched the **v1.8** / **v1.9** operator-docs pattern.

### What was inefficient

- **`gsd-sdk query milestone.complete`** still failed with **`version required for phases archive`**; **`milestones/v1.10-*`** files were written manually again.

### Patterns established

- **Primary wire map** for exploration JSON stays stable even when raw DB rows carry lowercase **`op`** values from triggers.

### Key lessons

1. Keep **hygiene phases** (written verification + planning matrix) in the same milestone when they unblock **audit status: passed**.
2. When **`milestone.complete` CLI** fails, still run **`git rm .planning/REQUIREMENTS.md`** at close so **`/gsd-new-milestone`** starts from a clean requirements slot.

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: Phases **31–36** executed as exploration + audit-unblock slice.
- Notable: Phase directories **31–36** remain under **`.planning/phases/`** (optional **`/gsd-cleanup`** move to **`milestones/v1.10-phases/`** later).

---

## Cross-milestone trends

### Process evolution

| Milestone | Phases | Key change |
| --------- | ------ | ---------- |
| v1.0 | 4 | Established GSD phase + plan workflow for Threadline |
| v1.1 | 4 | Shipped OSS distribution: GitHub + Actions + Hex **0.1.0** |
| v1.2 | 3 | Capture fidelity + maintainer verify/doc contracts + brownfield continuity |
| v1.3 | 3 | Production adoption: redaction, retention/purge, CSV/JSON export |
| v1.4 | 4 | **0.2.0** packaging, production checklist, timeline/export DX |
| v1.5 | 2 | Adoption feedback loop: pilot backlog + telemetry reference + honest pooler follow-up |
| v1.6 | 1 | Host STG templates + rubric + CONTRIBUTING + doc contracts (integrator-owned evidence explicit) |
| v1.7 | 3 | In-repo Phoenix reference app: HTTP + Oban paths, `record_action/2`, adoption doc pointers |
| v1.8 | 3 | Correlation-aware timeline/export + support playbooks + example correlation path + doc contracts |
| v1.9 | 3 | Ops-at-volume docs: telemetry + health narrative, audit indexing cookbook + doc contract, retention-at-scale + discovery hub |
| v1.10 | 6 | Exploration primitives (`ChangeDiff`, txn-scoped listing, routing docs) + milestone-audit hygiene phases |

### Cumulative quality

| Milestone | Tests | Notes |
| --------- | ----- | ----- |
| v1.0 | Growing integration + unit suite | `mix ci.all` required green at each close |
| v1.1 | + workflow/Nyquist contract tests | CI jobs extended for docs, Hex tarball, release shape |
| v1.2 | + verify coverage + README doc contracts + brownfield continuity | `verify.threadline` / `verify.doc_contract` on default CI path |
| v1.3 | + redaction + retention + export integration / Mix task tests | PostgreSQL-backed paths for capture JSON and purge |
| v1.4 | unchanged default CI path | Release narrative + operator checklist for **0.2.0** |
| v1.5 | + topology / pooler contract job on CI | Doc-first adoption loop; no new library surface |
| v1.6 | + STG doc contract tests | Doc-only milestone; `mix ci.all` unchanged in spirit, added focused contract files |
| v1.7 | + `verify.example` + example ConnCase / Oban tests | Runnable `examples/threadline_phoenix/` exercised on default CI path |
| v1.8 | + correlation filter integration tests + support playbook doc contract + example correlation ConnCase | Same **timeline/export** vocabulary for support; **`:correlation_id`** strict join path |
| v1.9 | + audit indexing doc contract | Doc-only milestone; default CI path unchanged; operator narrative locked to shipped **`Threadline.Telemetry`** names |
| v1.10 | + composed query→`change_diff` test path | Exploration API surface + audit-unblock phases; **`FLOW-TEST-01`** locks JSON/API integrator path in CI |

### Top lessons (verified across milestones)

1. v1.0 — treat REQUIREMENTS traceability as part of phase “done,” not only at milestone close.
2. v1.1 — verify **GitHub truth** (SHAs, Actions runs) alongside local green builds.
3. v1.2 — ship **operator semantics** for brownfield (continuity module + guide) in the same milestone as the capture feature that motivates them.
4. v1.3 — align **export filters** with **timeline** so ops never learn two query dialects.
5. v1.5 — label **who** must prove pooler realism (library CI vs host staging) before conflating them in a pilot narrative.
6. v1.6 — ship **templates + rubrics** as repo artifacts; treat integrator **OK** rows as downstream work outside maintainer attestation.
7. v1.7 — **`verify.example`** is the cheapest guardrail that nested example apps do not rot on **`main`**.
8. v1.8 — Keep **`PROJECT.md` Active`** aligned with the last shipped REQ the same day as phase verification.
9. v1.9 — When **`milestone.complete` CLI** fails, still run **`git rm .planning/REQUIREMENTS.md`** at close so **`/gsd-new-milestone`** starts from a clean requirements slot.
10. v1.10 — Run **`/gsd-audit-milestone`** before close when the milestone ships **library + doc + CI** evidence together; archive the audit file beside requirements.
