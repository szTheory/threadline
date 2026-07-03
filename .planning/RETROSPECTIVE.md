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

---

## Milestone: v1.22 — Policy / Evidence Plane

**Shipped:** 2026-05-27  
**Phases:** 9 | **Plans:** 18

### What was built

- `Threadline.Evidence` append-only records for six bounded subjects with stable provenance metadata and machine-readable detail payloads — no host business-policy meaning encoded.
- Three-tier proof vocabulary (`Threadline.Evidence.Proof`) distinguishing proven facts, inferred posture, and explicit unsupported claims — shared verdict language across library, Mix-task, and LiveView surfaces.
- Phoenix-optional library API plus Mix-task parity (`mix verify.evidence` family, `mix threadline.evidence.show`) with a stable JSON contract for CI, procurement, and audit handoff.
- Mounted `/audit/evidence` LiveView with overview-first drill-down, URL-driven navigation, host-owned auth gate, and truthful mounted fallbacks — reusing the existing `/audit` family, no new operator UI.
- Public docs and contract tests locked the narrow claim plus explicit non-goals (no legal hold, no immutable-storage guarantee, no generic compliance pack, no Threadline-owned RBAC/tenancy DSL).
- Verification backfill chain (Phases 100/101/102) closed Phase 95/96/98 verification gaps with current-tree proof; Phase 103 reconciled the four authority surfaces and reran the milestone audit on the reconciled tree (`status: passed`, 12/12 requirements).

### What worked

- The narrow milestone thesis (a real evidence plane, not a compliance platform) stayed intact end-to-end. The shipped surface answers procurement-grade "what is provable here" questions without crossing the host-owned auth/tenancy boundary that v1.15-v1.21 invested in.
- The three-tier proof vocabulary forced honest claim language at design time — preventing the "everything is a proven compliance fact" drift that other audit libraries fall into when they bolt on evidence late.
- Phase 99's named rerun bundle (`mix verify.doc_contract` + 5-file evidence-plane seam + `mix verify.example`) became the authority for the closeout verdict instead of static prose, which made the Phase 103 milestone re-audit a mechanical rerun rather than an interpretation exercise.
- Inserting Phase 103 explicitly as a closeout-gate phase (not the archive step) meant the milestone audit could be repaired in place without widening into doc/code/test surfaces — the `.planning/`-only D-16 boundary held cleanly.

### What was inefficient

- The original Phase 95/96/98 work shipped without explicit `VERIFICATION.md` artifacts on disk, so the v1.22 milestone audit surfaced gaps that required three backfill phases (100/101/102) to close. The feature work was done correctly; the proof-chain bookkeeping was the gap. Same shape as v1.21's Phase 90-94 backfill chain — this is a repeating cost we now have a pattern for.
- `gsd-sdk query state.begin-phase` corrupted `STATE.md` with `null` values at Phase 103 start (positional args weren't parsed); orchestrator restored from HEAD before dispatch. CLAUDE.md already warns about this command's sensitivity — but the warning came too late to prevent the corruption.
- `gsd-sdk query milestone.complete` auto-extracted "deviation log" entries from SUMMARY.md files into the MILESTONES.md "Key accomplishments" block (e.g. `1. [Rule 3 - Blocking issue] STATE.md yaml status flipped from executing to completed`). Required a manual rewrite to focus the entry on actual themes rather than mid-execution bookkeeping.

### Patterns established

- **Closeout-gate phase shape:** A `.planning/`-only phase whose two plans are (1) reconcile the four authority surfaces and any stale validation bookkeeping, and (2) rerun the named proof bundle and rewrite the milestone audit. Pre-locks D-02 (archive belongs to `/gsd-complete-milestone`) and D-16 (no doc/code/test edits). Re-usable for any future milestone whose audit surfaces gaps after feature work is done.
- **Verification backfill phase shape:** A narrow phase per gapped earlier phase, scoped to writing `VERIFICATION.md` from current-tree evidence and finalizing `VALIDATION.md` to `nyquist_compliant: true`. No new feature work, no scope widening.
- **Named rerun bundle as closeout authority:** The Phase 99 bundle (3 commands, ~122 tests) is the milestone audit's primary evidence — not prose, not summary frontmatter. Future milestones should designate a named bundle early so closeout becomes a rerun rather than a re-litigation.
- **Three-tier proof verdict:** `proven` / `inferred` / `unsupported` keeps the claim language honest. Worth carrying forward as a default vocabulary anywhere Threadline emits truth statements.

### Key lessons

1. **Bake proof-chain completeness into phase verification, not into milestone close.** v1.21 and v1.22 both needed verification backfill phases to repair earlier-phase audit gaps. The gsd-verifier step should produce `VERIFICATION.md` files atomically as part of phase close, not as a separate later artifact. Carry this into v1.23 phase plans.
2. **Closeout-gate phases need explicit D-02 / D-16 framing in their CONTEXT.md.** Without it, the executor is tempted to widen scope to "fix the new gap inline." Phase 103's research locked these as explicit decisions and the boundary held; replicate that framing in future closeout-gate phases.
3. **Trust the named bundle, not the audit prose.** The v1.22 audit went from `gaps_found` to `passed` only because the rerun bundle stayed green on the reconciled tree. Future milestone audits should anchor on rerun authority rather than authored verdicts.
4. **CLAUDE.md tooling-sensitivity warnings should move upstream into the SDK itself.** The `state.begin-phase` corruption is a known sensitivity; document-level warnings are not enough — the tool itself should validate args.

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: two concentrated waves over two days — first for evidence-plane feature work (Phases 95-99), then for verification backfill + closeout (Phases 100-103).
- Notable: Phases 100/101/102/103 collectively touched only `.planning/` (zero changes under `lib/`, `test/`, `mix.exs`, `mix.lock`, `guides/`, `examples/`, `priv/`); the closeout boundary held cleanly across four phases.

---

## Milestone: v1.21 — Scoped Support / Operator Proof

**Shipped:** 2026-05-25  
**Phases:** 10 | **Plans:** 21

### What was built

- A truthful first-party support-safe `/audit` lane with one exact current-tree claim: timeline, actor, transaction, support-scoped row history / as-of, and export denial posture through host-owned seams.
- Explicit gating for coverage/global policy surfaces so support-scoped operators do not learn admin-only state through UI badges, routing, or background telemetry loops.
- One canonical `/audit` mount recipe and runnable example-host proof for admin and support personas on the same route tree.
- Backfilled verification, validation, and authority-surface evidence for Phases 85-94 so all 12 v1.21 requirements close on rerun-backed current-tree proof.

### What worked

- The narrow milestone thesis held: productizing the mount contract without inventing a Threadline-owned auth model kept the work scoped and verifiable.
- Re-running the final proof bundle in Phase 94 before closeout prevented stale summary frontmatter from becoming release truth.

### What was inefficient

- Milestone closeout needed manual cleanup after `gsd-sdk query milestone.complete`; the generated `MILESTONES.md` entry and `STATE.md` updates did not match the repo’s established closeout format.
- Verification backfill phases were necessary because earlier milestone execution left canonical proof artifacts incomplete even when the feature work was effectively shipped.

### Patterns established

- Treat rerun-backed `VERIFICATION.md` and `VALIDATION.md` artifacts as the only authority for requirement closure when summary frontmatter and active planning docs drift.
- Keep host-owned seams explicit: `scope_query_fn` proves the safe read lane, while `export_authorize_fn` remains a separate privileged capability.

### Key lessons

1. A narrow current-tree claim is more durable than a broad roadmap promise when the real risk is authority-surface drift.
2. Milestone audits should force proof-chain completeness earlier, before follow-up verification-backfill phases become necessary.

### Cost observations

- Model mix: not instrumented in-repo for this milestone.
- Sessions: two concentrated waves, first for support-lane closure and then for proof-chain/authority reconciliation.
- Notable: the milestone touched 126 files in about one day, but much of the second wave was evidence repair rather than net-new feature surface.

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
| v1.24 | 3 | Audited write-path helper + reference adoption + 0.5.x adopter/doc truth |

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
| v1.24 | + `audit_transaction_test.exs`, `audit_doc_contract_test.exs`, `evidence_cli_doc_contract_test.exs`, `adoption_pilot_doc_contract_test.exs` | Helper integration tests + doc contracts lock write path and 0.5.x evaluator truth |

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
11. v1.24 — Split **library helper**, **reference adoption**, and **doc truth** into separate phases; closeout doc-contract gates catch evaluator-facing drift that code-only refactors miss.

---

## Milestone: v1.23 — Realistic-Demo Walkthrough

**Shipped:** 2026-05-27  
**Phases:** 7 (104–110) | **Plans:** 24

### What was built

- Help-desk domain, Sigra auth lane, `mix demo.seed` / `demo.reset`, maintainer `WALKTHROUGH.md`, observe-only dry-run, triage of findings 0001–0003.

### Graduated learnings (for future milestones)

1. **Synthetic override when no adopter exists** — Record override + re-engagement trigger in Key Decisions so the next arc reread does not re-litigate v1.22 closeout language.
2. **Observe-only → triage split** — Phase 109 captures; Phase 110 fixes. Prevents in-flight scope creep during the walk.
3. **Isolated clone verification ladder** — L0→L2 re-walk after fixes; do not claim RUN pass on a tree that predates triage commits.
4. **Inventory-phase scope guard** — Phase 110 example/guides fixes with **zero** `lib/threadline/**` commits unless (a) breakage with walkthrough evidence.
5. **108-REVIEW before 109** — Catch walk/doc mismatches before the dry-run hard-gates.

### Surprises

- Walkthrough filed **zero** (d) design gaps — v1.24-seeds handoff empty at closeout.
- Landing-page `BadMapError` (finding 0001) was the only hard gate; RUN-02/03 were not attempted until fixed.

### Cost observations

- Not instrumented in-repo for this milestone.

---

## Milestone: v1.24 — Audited Write Path & Adopter Truth

**Shipped:** 2026-05-27  
**Phases:** 3 (111–113) | **Plans:** 11

### What was built

- `Threadline.Audit.transaction/3` — single-call audited write path with actor GUC, optional semantic action, and `action_id` linkage.
- Reference app and getting-started guide migrated all primary write paths to the helper; audit/correlation tests unchanged.
- Adopter truth repairs: `evidence_authorize_fn` on sigra-reference mount, adoption-pilot **0.5.0** SSOT, canonical evidence CLI doc contracts, WALK-03-02 prose aligned to seed anchors.

### What worked

- Three-phase vertical slice (library → example adoption → doc truth) matched the assessment boundary without scope creep into compliance or another walkthrough.
- Doc-contract tests as the closeout gate (`verify.doc_contract`, `verify.example`) caught CLI naming and version-table drift before ship.
- Phase 112 `transaction_meta` fix on capture-only paths unblocked help-desk org scoping without weakening audit assertions.

### What was inefficient

- `milestone.complete` CLI extracted placeholder "complete" one-liners for MILESTONES.md — manual rewrite required at closeout.
- No v1.24 milestone audit file; closeout proceeded on roadmap analyze + requirements traceability alone.

### Patterns established

- `Threadline.Audit.transaction/3` is the recommended write path in guides; manual GUC + `record_action` recipe is legacy escape hatch only.
- Evidence CLI canonical name locked via dedicated doc-contract test refuting never-shipped `mix verify.evidence`.

### Key lessons

1. Integration ergonomics (helper API) was the highest-leverage remaining gap once capture+semantics+operator stack shipped — assessment thread was right to prioritize it over DEFER trio without adopter signal.
2. Adopter truth is a separate phase from library adoption — mount options (`evidence_authorize_fn`) and version literals drift independently of write-path refactors.

### Cost observations

- Timeline: single day (2026-05-27).
- Not instrumented in-repo for model mix.

---

## Milestone: v1.25 — Adopter-Ready Release & First-Hour Truth

**Shipped:** 2026-05-28  
**Phases:** 5 (114–118) | **Plans:** 11 | **Tasks:** 33

### What was built

- **threadline 0.6.0** Hex packaging with CHANGELOG, ExDoc Evidence group, `mix verify.release`, and `~> 0.6` install-snippet SSOT.
- Narrative alignment on `Audit.transaction/3` across how-threadline-works, README, and getting-started with doc-contract discovery locks.
- Example first-hour runbook: `:api` session plugs, Track A/B paths, Mix task ownership tables, cookie curl for `POST /api/posts`.
- Evidence-plane doc authority: split-guide map, semver adopter prose, incident JSON blessed path; `mix verify.doc_contract` green.
- Evaluator one-pager and adoption-pilot verify ladder refresh without maintainer STG attestation claims.

### What worked

- Five-phase vertical slice (release → narrative → example → doc authority → pilot prep) matched the post-v1.24 assessment without compliance creep.
- Doc-contract tests as the universal closeout gate caught version literals, phantom hub references, and stale verify counts.
- Milestone audit (`passed`, 16/16 requirements) before closeout gave confidence to ship despite partial Nyquist on 115/117/118.

### What was inefficient

- `summary-extract` one-liner CLI returned frontmatter instead of prose — MILESTONES accomplishments were assembled from SUMMARY provides blocks.
- Phase directories remain in `.planning/phases/` (not moved to `milestones/v1.25-phases/`); use `/gsd-cleanup` later if context cost matters.

### Patterns established

- **0.6.0** is the adopter semver SSOT; internal milestone labels stay in maintainer/planning paths only.
- `guides/evaluating-threadline.md` is the canonical external evaluator entry (what 0.6.0 proves, host-owned boundaries, verify ladder).

### Key lessons

1. Release truth and first-hour friction were the right closeout target once the helper shipped in v1.24 — evaluators were blocked on Hex/doc drift, not missing library features.
2. Optional Phase 118 still paid off: adoption-pilot without hardcoded test counts prevents the next milestone from inheriting stale verify prose.

### Cost observations

- Timeline: ~1 day (2026-05-27 → 2026-05-28); 68 commits in milestone range.
- Not instrumented in-repo for model mix.

---

## Milestone: v1.26 — Auth Lane Breadth

**Shipped:** 2026-05-28  
**Phases:** 3 (119–121) | **Plans:** 6 | **Tasks:** 11

### What was built

- `guides/integrations/phx-gen-auth.md` cookbook with host-owned `MyApp.AuditActor`, Plug order, admin `authorize_fn`, and explicit non-goals.
- **`phx-gen-auth-reference`** lane in upgrade-path with four-lane matrix row and doc-contract proof anchors.
- Root `phx_gen_auth_integration_test.exs` proving actor extraction, admin gate, and Plug smoke without Sigra.
- Getting-started auth neutrality, README four-lane discovery, evaluator cross-links, and ADOPT-AUTH doc-contract gates.

### What worked

- Three-phase vertical slice (guide → root proof → doc neutrality) closed the diminishing-returns assessment wedge without a second reference app.
- Milestone audit (`passed`, 11/11 requirements) before closeout; prior AUTH-GUIDE-01 blocker resolved by aligning guide unwrap with test contract.
- Host-owned adapter pattern (`MyApp.AuditActor`) kept Threadline free of phx.gen.auth coupling in `lib/`.

### What was inefficient

- `summary-extract` CLI still returns frontmatter — accomplishments assembled from SUMMARY provides blocks at closeout.
- Phase directories remain in `.planning/phases/`; optional `/gsd-cleanup` to archive under `milestones/v1.26-phases/`.

### Patterns established

- **Four-lane** adopter self-identification: `capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, `sigra-reference` — Sigra is optional peer, not default.
- Root integration tests as proof for reference lanes that do not warrant a second example app.

### Key lessons

1. Guide + root proof beats a second reference app for majority Phoenix auth — assessment thread was right to cap scope at cookbook + CI.
2. Doc neutrality is a separate phase from guide/proof — discovery order (README, getting-started, evaluator) drifts independently of integration snippets.

### Cost observations

- Timeline: ~1 day (2026-05-27 → 2026-05-28); 26 commits, +3133 / −98 LOC in milestone range.
- Not instrumented in-repo for model mix.

---

## Assessment: 2026-05-28 (post-v1.26 milestone next-step)

**Thread:** `.planning/threads/2026-05-28-milestone-next-step-post-v1.26.md`

### Judgment

- **Done-%:** ~90–93% for stated narrow audit-platform scope (band: near-done / diminishing returns soon).
- **Single pick:** v1.27 Distribution & First-Hour Finish — Hex 0.6.0, `ecto_repos` getting-started doc, first-hour doc finish.
- **Not next:** external pilot (no signal), compliance DEFER trio, second reference app, evidence auto-population.

### Key findings (repo-grounded)

1. Hex.pm **0.5.0** vs in-repo **0.6.0** — adopter-facing distribution blocker.
2. `config :threadline, ecto_repos` required by mix tasks; missing from getting-started.
3. Evidence plane is host-write only — set expectations, do not auto-wire from ops without signal.
4. v1.26 audit carry-forward: §6 sigra cookie prose, ADOPT-AUTH contract literals (non-blocking).

### Graduation candidates (reusable closeout / GSD patterns)

- Three-phase vertical slice: guide → root proof → doc neutrality (v1.26 validated)
- Doc-contract tests as milestone closeout gate
- `mix verify.*` as claim authority over prose
- Assessment thread at each `/gsd-new-milestone`
- Distribution truth check (in-repo semver vs hex.pm) in milestone assessment
- Guide + root proof > second reference app for reference lanes

---

## Milestone: v1.27 — Distribution & First-Hour Finish

**Shipped:** 2026-05-28  
**Phases:** 6 (122–127) | **Plans:** 15 | **Tasks:** 44

### What was built

- **threadline 0.6.0** published to hex.pm; adoption-pilot and evaluator surfaces honest about distribution truth.
- First-hour `ecto_repos` config in getting-started §2 and production-checklist with doc-contract locks.
- Adopter doc finish: IEx-first §6, ADOPT-AUTH literals, `:schemas` reification docs, evidence host-write boundary, four-lane integration-contracts vocabulary.
- Gap-closure phases: authority-surface reconciliation (charter test, STATE, MILESTONE-ARC), Nyquist sign-off on 122–124, runnable `:schemas` demonstration in example app (D-14).

### What worked

- Assessment thread correctly identified the three adopter-facing blockers (Hex drift, `ecto_repos`, doc finish) as a single milestone wedge.
- Gap-closure insert pattern (Phases 125–127 after audit) closed planning metadata drift without reopening satisfied requirements.
- Doc-contract tests as the closeout gate — `mix verify.doc_contract` and session-close `mix ci.all` (740 + 53 tests) as authoritative proof.

### What was inefficient

- Milestone grew from 3 delivery phases to 6 after audit — predictable for Threadline closeout but worth budgeting in future milestone scoping.
- `summary-extract` CLI still returns frontmatter; accomplishments assembled from SUMMARY provides blocks at closeout.

### Patterns established

- **Distribution truth check** at milestone assessment: in-repo semver vs hex.pm must match before claiming adopter-ready.
- **Guide + example demo** for operator-surface features (`:schemas`) when docs-only proof is insufficient — D-14 deferred from 124 to 127 rather than faking runnable evidence.

### Key lessons

1. First-hour friction (missing `ecto_repos`, stale Hex version) blocks evaluators harder than missing advanced features — finish distribution + config before pilot outreach.
2. Nyquist validation sign-off as a dedicated gap-closure phase (126) is cheaper than re-litigating delivery phases — reuse for future audits.

### Cost observations

- Timeline: ~1 day (2026-05-28); 6 phases, 15 plans, 44 tasks.
- Not instrumented in-repo for model mix.

---

## Assessment: 2026-05-28 (post-v1.27 path-to-done)

**Thread:** `.planning/threads/2026-05-28-milestone-next-step-post-v1.27.md`

### Judgment

- **Done-%:** ~92% for stated narrow audit-platform scope (band: 90–95% near-done / diminishing returns soon).
- **Single pick:** **Hold** (default) or optional **v1.29 First-Hour Parity & Verify Hygiene** — not v1.28 (no adopter signal).
- **Path to done:** optional v1.29 → hold → v1.28 on signal → ~95%+ then stop major milestones.

### Key findings (repo-grounded)

1. Hex **0.6.0** aligned with in-repo semver — v1.27 closed distribution blocker.
2. Getting-started spine complete; README Quick Start still omits `ecto_repos` — v1.29 candidate.
3. phx-gen-auth mount snippet omits canonical `scope` shape — v1.29 candidate.
4. WALKTHROUGH command cwd and row-history URL shorthand — v1.29 candidate; v1.27 audit low-severity gap.
5. Core lib surfaces shipped; `mix ci.all` + `mix verify.example` are credible evaluator ladder.

### Graduation candidates (added post-v1.27)

- Gap-closure phases (125–127 pattern) for audit hygiene without scope creep
- `mix ci.all` + `mix verify.example` as evaluator ladder SSOT
- Path-to-done roadmap recorded in MILESTONE-ARC at each assessment
- Hold as valid default when done band ≥90% and no adopter signal

---

## Milestone: v1.29 — First-Hour Parity

**Shipped:** 2026-05-29  
**Phases:** 4 (128–130.1) | **Plans:** 8 | **Tasks:** 24

### What was built

- README Quick Start renumbered with `ecto_repos` before install, posts-only triggers, and doc-contract locks.
- phx-gen-auth scope-first `authorize_fn` mount with integration proof and surface-section doc-contract locks.
- WALKTHROUGH verify cwd and row-history URL truth with two-tier doc-contract tests.
- Nyquist 125 finalized under v1.27 milestone archive; SUMMARY `requirements-completed` SSOT; v1.27 GAP backfill.
- Phase 130.1 closed planning-metadata audit drift (ROADMAP/REQUIREMENTS authority, Nyquist waivers for doc-only phases).

### What worked

- Thin hygiene milestone scoped correctly — doc parity and verify debt without pilot pretense or product expansion.
- Decimal phase 130.1 pattern closed audit remainder without reopening delivery phases.
- Doc-contract tests as closeout gate — session-close `mix ci.all` (744 + 61 tests) as authoritative proof.

### What was inefficient

- Milestone grew from 3 planned phases to 4 after audit (130.1) — predictable Threadline closeout pattern.
- Charter doc-contract literals require update at every milestone closeout (D-130.1-08).

### Patterns established

- **Nyquist waiver documentation** for doc-only phases when VERIFICATION passes but VALIDATION.md is intentionally absent.
- **Three-source SUMMARY frontmatter** (`requirements-completed` hyphenated SSOT) for audit traceability.

### Key lessons

1. README Quick Start is a distinct surface from getting-started §2 — both need `ecto_repos` parity for evaluators who never open the guide.
2. WALKTHROUGH truth (cwd + URL presentation) is maintainer-facing but blocks credible dry-runs — treat as first-hour scope.

### Cost observations

- Timeline: ~2 days (2026-05-28 → 2026-05-29); 50 commits; 66 files changed.
- Not instrumented in-repo for model mix.

---

## Milestone: v1.30 — Adoption Evidence Automation

**Shipped:** 2026-05-29  
**Phases:** 3 | **Plans:** -

### What was built
- Automated WALKTHROUGH §1–§4 ConnCase happy paths in `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_happy_path_test.exs`.
- Configured Hex package evaluator pipeline in `priv/ci/hex_evaluator` to prove `mix verify.hex_evaluator` installs from hex.pm without path override.
- Documented pre-pilot hardening posture and defined v1.28 signal gates.

### What worked
- Shifting manual WALKTHROUGH validation into automated `ConnCase` tests ensures the demo path won't silently regress during hold.
- Running Hex installation tests in an isolated Mix project (`priv/ci/hex_evaluator`) is the only honest way to test evaluator adoption from hex.pm.

### What was inefficient
- Testing Hex-published installs is inherently disconnected from local dev; requires local `deps.get` mocking or live publishes.

### Patterns established
- **Pre-pilot hardening:** Close shift-left gaps using automation rather than rushing an external pilot without signal.

### Key lessons
1. Maintainer-driven walkthroughs rot quickly without automated guards; `ConnCase` on seeded fiction provides 80% of the value of E2E for 10% of the cost.

### Cost observations
- Quick focused automation iteration.

---

## Milestone: v1.31 — Operator Surface: Insane Polish

**Shipped:** 2026-06-05
**Phases:** 11 | **Plans:** 35

### What was built
- Objective `/audit` surface baseline and final screenshot evidence, with Phase 144 errata tying historical Phase 134 evidence to closeout.
- Seed-state enrichment and DEMO-MANIFEST recipes so every operator screen demonstrates useful empty, sparse, dense, error, scoped, and edge states.
- Source-first dark BEM/token design-system catalog and freeze, with shared primitives across Prove, Find, Home, navigation, operation badges, tables, cards, drawers, and affordances.
- Earned investigation/export flows: record-first lookup, correlation paste/deep-link, first-class row history, and Timeline/Evidence context handoff into Exports.
- Motion, responsive, accessibility, screenshot diff, and screenshot-regression verification for the polished operator baseline.

### What worked
- Closing POLISH-AUDIT and POLISH-DS through Phase 144 preserved provenance instead of fabricating missing Phase 134/136 execution records.
- Source contracts around `style.ex`, the design-system catalog, and browser screenshot checks made subjective UI polish auditable.
- Moving phase history into `.planning/milestones/v1.31-phases/` keeps the active planning surface small for the next milestone.

### What was inefficient
- Early summary extraction was noisy (`One-liner:` / invalid fragments), so milestone closeout still required editorial cleanup in `MILESTONES.md`.
- Historical validation/frontmatter drift in older v1.31 phases created audit noise even though later verification satisfied the requirements.

### Patterns established
- Use a narrow close-gap phase when audit blockers are evidence/provenance issues, and explicitly name the original roadmap owner plus the closing evidence.
- Treat UI polish as a governed surface: baseline screenshots, token/class catalog, browser matrix, reduced-motion checks, and regression guard all belong in the milestone definition of done.

### Key lessons
1. A polish milestone can be non-signal-gated when it raises the floor of an already-shipped operator surface without widening backend/product scope.
2. Historical gaps should be closed with truthful errata and current-tree proof, not invented phase artifacts.

### Cost observations
- Timeline: 3 days (2026-06-03 → 2026-06-05); 35 plans; 51 tasks.
- Not instrumented in-repo for model mix.

---

## Milestone: v1.33 — Brand Review + Direction Selection

**Shipped:** 2026-06-06
**Phases:** 4 | **Plans:** 3

### What was built

- Review packet and artifact inventory for the existing v1.32 `brandbook/` HTML, logo assets, visual specimens, tokens, and copy guidance.
- Light-surface primary logo variant plus usage guidance for README/GitHub/light documentation contexts.
- Human direction decision: targeted cleanup selected; alternate concepts, public rollout, and runtime UI changes rejected for this milestone.
- Brandbook-facing copy cleanup so source artifacts present current Threadline brand truth without refresh/audit backstory.
- Final verification evidence for JSON/SVG/HTML parsing, direct-open browser rendering, desktop/mobile screenshots, historical scan, binary exclusion, inventory, and file-size discipline.

### What worked

- Treating README/GitHub as the deciding surface kept the brand review grounded in the first OSS trust surface.
- Separating direction approval from public rollout avoided mixing brand-source readiness with README/HexDocs/landing-page implementation.
- The audit passed cleanly after Phase 153 because Phase 150-153 evidence matched the narrow requirements.

### What was inefficient

- `summary-extract` returned no usable one-liners for the milestone summaries, so `MILESTONES.md` needed manual editorial cleanup.
- Phase 152 has summary and verification evidence but no separate plan file, which is acceptable for this closeout but makes plan-count reporting less tidy.

### Patterns established

- Brand artifacts should read as current source guidance; process history belongs in `.planning/`.
- Light and dark logo roles need explicit source assets and usage guidance before README/GitHub rollout.

### Key lessons

1. A brand review milestone should approve direction before touching public surfaces.
2. Public rollout candidates need fresh requirements even when the source brandbook is approved.

### Cost observations

- Timeline: 2 days (2026-06-05 -> 2026-06-06); 4 phases; 3 plans.
- Not instrumented in-repo for model mix.

---

## Milestone: v1.36 — Operator Surface Light Mode

**Shipped:** 2026-06-14
**Phases:** 5 (166-170) | **Plans:** 9

### What was built

First-class light mode for the operator surface without disturbing the dark default: `theme: :dark | :light | :system` host config rendered server-side as a `data-tl-theme` attribute over a pure-CSS 45-token light lane (zero JS, zero FOUC, CSP-proof). Component retune of the ~9 dark-effect families and data-viz surfaces, a light/system WCAG-AA contrast mirror with an alpha-aware compositing parser, a `__light__` screenshot lane, `theme:` docs under doc-contract, and full brand-token parity with a bidirectional drift test.

### What worked

- **Source-first contract amendment.** Amending `style.ex` and `style_contract_test.exs` in the same wave (the seven light refutes → theme-aware assertions) kept the contract honest and the dark baseline byte-stable — no window where the test and the source disagreed.
- **Designed-not-recolored discipline.** Treating the light status-tint system as one keystone decision in Phase 166, then retuning against it, avoided the "Grafana lesson" of dark-tuned content washing out on white.
- **Server-rendered theming.** Choosing `data-tl-theme` over localStorage/JS meant first paint was correct on the dead render and the whole feature survives CSP — the right call for a mounted library.

### What was inefficient

- **Entangled uncommitted source (Finding F1).** The light `style.ex` changes lived uncommitted in a broader operator-surface working tree across most of the milestone, so COMP-01/02 shipped as "verified-live, source-pending" and the parity gate was only green against the working tree — not a clean checkout. It took a dedicated commit at close to resolve, and a doc-contract test (`exports_doc_contract_test.exs`) had drifted from the uncommitted markup unnoticed.
- **Doc-contract drift discovered late.** Two sibling doc-contract tests diverged (one updated, one missed) because the markup evolved in an uncommitted tree the tests couldn't see until the source was committed.

### Patterns established

- **Commit source in the same wave it's verified.** "Verified live but uncommitted" is a debt that hides test drift and makes gates lie about a clean checkout. Don't let a milestone's keystone source sit uncommitted across phases.
- **Theme-aware contract mirroring.** A single style contract that reads the source directly can assert per-mode (dark + light/system) invariants — including alpha-composited contrast — without a browser.

### Key lessons

- A passing gate that depends on an uncommitted working tree is not a passing gate. Make "green on a clean checkout" the bar.
- When markup evolves, grep for *all* sibling doc-contract tests, not just the obvious one — brittle string/regex contracts drift silently.

### Cost observations

- Timeline: 3 days (2026-06-12 → 2026-06-14); 5 phases; 9 plans; 86 commits.
- Closed with 6 acknowledged-deferred items (2 human-UAT, 1 human verification, 3 operator-surface todos).
- Not instrumented in-repo for model mix.

---

## Milestone: v1.37 — Operator Surface Design-System Stress Test & Component System

**Shipped:** 2026-06-20
**Phases:** 10 (171-180) | **Plans:** 47

### What was built

- Dev/test-only stress-lab harness, fixture matrix, scored ledger, `DESIGN-SYSTEM.md` projection, and screenshot ratchet guards.
- Private operator-surface component system across primitives, overlays, forms, data display, layout, and meta-components.
- Shell/navigation, runtime theme picker, page headers, breadcrumbs, pager, data-state taxonomy, full-value copy affordances, coverage flattening, and destructive action confirmation.
- All-page stress evidence, microcopy/IA normalization, WCAG/APG/motion guardrails, bounded accessibility-tree evidence, residual CI classification, and adversarial closeout.

### What worked

- The fractal order held: harness and foundations first, then primitives/forms, groups, pages, copy, and final accessibility/motion guardrails.
- Keeping components private preserved the v1.31 freeze while still reducing page-level duplication and making regression tests sharper.
- Phase 180's proof tiers were honest: source contracts, rendered browser checks, and accessibility-tree snapshots each state what they prove and do not prove.

### What was inefficient

- The generated milestone-accomplishment extraction was too noisy and needed manual editorial cleanup.
- `roadmap.analyze` miscounted phase 180 because of stale roadmap shape, which required manual state correction before closeout.
- `REQUIREMENTS.md` traceability for DATA-01/02/03 lagged behind verified Phase 176 evidence until milestone close.

### Patterns established

- Use `/audit/__stress` plus a scored ledger as the regression anchor for future operator-surface work.
- Treat visual polish milestones like backend milestones: every claim needs source, rendered, and archive-ready evidence.
- Bounded accessibility evidence is acceptable when it names the gap explicitly; do not let browser automation imply real assistive-technology UAT.

### Key lessons

1. Keep roadmap plan lists synchronized before running milestone tooling; stale `TBD` markers can poison readiness metrics even when disk artifacts are complete.
2. Requirements traceability should be updated in the same wave as verification, not reconciled at close.
3. Generated archive summaries need an editorial pass before they become durable project history.

### Cost observations

- Timeline: 2026-06-14 -> 2026-06-20; 10 phases; 47 plans.
- Closed with 3 acknowledged post-close todo artifacts and one intentional destructive-flow deferral.
- Model mix is not instrumented in-repo.

---

## Milestone: v1.38 — Operator UI Page-by-Page IA & Design-System Polish

**Shipped:** 2026-06-30
**Phases:** 8 (181-188) | **Plans:** 34

### What was built

- Current rendered `/audit` baseline, stale guard repair, source contracts, and bounded screenshot inventory for page-by-page polish.
- Example-app-only PhoenixStorybook maintainer lane for private operator components and ugly-state review.
- Task-led shell/Home/Timeline/Coverage workflows with clearer navigation, page hierarchy, URL state, row actions, copy, and responsive proof.
- Detail/governance/export/retention pages aligned to the same operator IA patterns, with risk-aware destructive and disabled states.
- Accessibility, motion, docs, adversarial closeout, queued export replay, `.tl-copy` motion governance, and GOV-02 traceability closure.

### What worked

- Starting with baseline and stale-guard repair prevented polish work from inheriting dead selectors or outdated visual evidence.
- Shell/Home/Timeline became the reference pattern before lower-traffic pages were retuned, which kept later work more mechanical.
- Keeping PhoenixStorybook example/dev-only preserved the root package boundary while still improving maintainer design review.

### What was inefficient

- Generated milestone accomplishments were noisy and needed manual cleanup before becoming archive history.
- Several broad-suite, screenshot, and environment residuals had to be reclassified carefully so closeout did not imply broader green status than the evidence supported.
- GOV-02 traceability metadata lagged behind implementation evidence until the Phase 188 close-gap pass.

### Patterns established

- Use the mounted UI's job-to-be-done order as the page cleanup sequence: orientation first, investigation second, readiness third, detail/governance after patterns settle.
- Prefer source contracts for narrow motion governance fixes when browser proof would add little signal.
- Keep residual classifications explicit in milestone audits instead of converting unrelated non-green evidence into blocker-free language.

### Key lessons

1. Closeout phases should verify traceability frontmatter as carefully as runtime behavior; planning metadata can block archive readiness.
2. Storybook can be useful without changing the public package contract when it is scoped to a maintained example app.
3. Screenshot and browser proof need named boundaries; archived milestones should state exactly which visual claims are and are not made.

### Cost observations

- Timeline: 2026-06-26 -> 2026-06-30; 8 phases; 34 plans; 51 tasks.
- Git range: `v1.37` -> `715e0da3` before archive; 262 commits; 296 files changed.
- Model mix is not instrumented in-repo.

---

## Milestone: v1.39 — Quality Baseline, Schema Confidence, and CI Efficiency

**Shipped:** 2026-07-03
**Phases:** 5 (189-193) | **Plans:** 21 | **Tasks:** 42 | **Requirements:** 15/15

### What was built

- A repo-evidence software-quality audit that ranked the weakest adoption/ops/maintainer dimensions and deliberately narrowed the milestone to schema confidence, docs/version truth, and CI efficiency rather than new product scope.
- End-to-end proof that a custom non-default `storage_schema` (`audit`) threads correctly through capture, query, evidence, governance, retention, queued export, and every operator LiveView — with prefix-free Ecto schemas source-locked against the fixed default, quoted generated migration identifiers, and a real dual-schema PostgreSQL integration test.
- Version/docs truth reconciled to `0.9.0` behind a central drift-guard doc-contract test, a 0.6.x→0.9.x upgrade path, and verb-lane README/ExDoc routing.
- A measured CI/CD efficiency pass (baseline first, then deps/Playwright/npm caches, min/current compatibility matrix, PR + publish concurrency, pinned PgBouncer) behind contract + dep-floor guards.
- A closeout that gave every carried residual an owner and a concrete reopen-trigger, plus a v1.40/hold recommendation.

### What worked

- **Audit-first, then fix.** Phase 189 ranked risk from repo evidence before any code changed, so the four implementation phases spent effort only on proven-weak surfaces and the invariants (no product scope, no version bump) held cleanly through close.
- **Measure-before-optimize on CI.** Recording a read-only baseline first (Phase 192) kept the efficiency changes boring and reversible and avoided speculative matrix/sharding cleverness.
- **Residuals with reopen-triggers, not a polish bucket.** The 193 risk register ranked each carried item (WR-01 fixture, health.ex filter, R-C charter test, R-D local test-DB env) with an owner and a concrete condition to reopen — measured tech debt instead of accumulated-and-unreviewed.

### What was inefficient

- Several 191/192/193 plan SUMMARY one-liners were empty or carried a code-review artifact (`[Rule 3 - Blocking] …`), so the CLI-generated MILESTONES.md accomplishments needed manual editorial repair at close — the recurring "generated archive text needs review" lesson again.
- Nyquist validation is partial: 191 and 193 shipped docs-only with no VALIDATION.md, flagged (not blocked) and left as optional retroactive `/gsd-validate-phase`.

### Patterns established

- A quality milestone can be a legitimate ship: rank risk, fix the top few high-confidence gaps, and close with a ranked residual register — no feature surface required.
- Storage-schema threading is now proven by a dual-schema integration test with default-`threadline` sentinels; future schema work should extend that fixture (and harden it past `LIKE ... INCLUDING ALL` per WR-01) rather than re-proving from scratch.

### Key lessons

- Ship-gated externals (D-17 min-lane run, D-19 branch-protection reconfig) are real tech debt even when accepted; tracking them in a checklist with an explicit trigger (the clean push landing the new matrix on public `main`) keeps them from silently lapsing.
- Local `mix test` `(undefined_table)` failures are an environment/search_path artifact, not a regression — CI is green; reopen only on a CI failure with the same signature.

### Cost observations

- Timeline: 2026-06-30 -> 2026-07-02; 5 phases; 21 plans; 42 tasks.
- Git range: `v1.38` -> `57a6aacb` before archive; 154 commits; 359 files changed, +19,596 / -717.
- Model mix is not instrumented in-repo.

---

## Cross-Milestone Trends

- v1.39 shows a non-feature "consolidation" milestone (quality audit → schema/docs/CI hardening → ranked residual register) can ship as a first-class milestone when surface area has outgrown its trust evidence.
- Measure-before-optimize generalizes beyond UI: the CI baseline-first discipline mirrors the baseline-first UI lesson from v1.38.
- Generated archive text (SUMMARY one-liners → MILESTONES accomplishments) has now needed editorial cleanup at v1.37, v1.38, and v1.39 closes — treat CLI-generated milestone prose as a draft, always review before it becomes durable history.
- v1.38 confirms the v1.37 lesson that generated archive text needs editorial review before it becomes durable project history.
- Baseline-first UI milestones reduce drift: rendered evidence, source contracts, and stale-test repair should precede visual or IA changes.
- Example-app dev tooling is the right place for maintainer-only UI review aids when the root library has an optional-dependency promise.
- v1.37 reinforces the v1.36 lesson: archive-ready evidence must be clean against the current working tree, not only locally remembered phase context.
- Planning tools can misread stale roadmap metadata; closeout should include a manual sanity pass over phase counts, requirement traceability, and state frontmatter before tagging.
- **Commit keystone source in the wave it's verified.** v1.36's Finding F1 (entangled uncommitted `style.ex`) echoes the recurring "verified-live but source-pending" hazard — it hides doc-contract drift and makes quality gates green only against a dirty tree. Treat a clean-checkout green as the bar.
- Brand and UI milestones now need the same evidence discipline as backend milestones: source artifacts, direct-render checks, explicit deferred rollout boundaries, and archive-ready verification.
- Public-surface rollout should start from fresh requirements even when source guidance is approved; approval is not implementation scope.
