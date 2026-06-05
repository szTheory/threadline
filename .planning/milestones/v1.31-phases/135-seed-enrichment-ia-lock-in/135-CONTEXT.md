# Phase 135: Seed Enrichment & IA Lock-In - Context

**Gathered:** 2026-06-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Enrich the `examples/threadline_phoenix` demo seed so every `/audit` operator-surface screen can be driven to its meaningful states (empty / long-paginated / status-variety / permission-edge) with **no code changes**, update `DEMO-MANIFEST.md` as the single source of truth, and **lock** the persona/JTBD/IA decisions so phases 136–143 cite one authoritative source.

**Seed-only.** No demo-app schema changes, no new routes, no business-logic changes — the git diff is seed code + docs + one doc-contract test. Determinism is preserved: UUID v5 namespace `threadline.demo`, frozen `demo_epoch` 2026-05-27, PRNG `:rand.seed(:exsss, {1,2,3})`.

This phase closes audit findings **F-201, F-202, F-203, F-204, F-205** and enables **F-703**. It is a foundation phase: the design-system (136) and per-screen (137–143) phases depend on its honest seed + locked IA.

</domain>

<decisions>
## Implementation Decisions

### 1. Edge-state reachability — one seed, states selected, recipes documented (F-205)
- **D-01:** ONE deterministic `mix demo.seed`. States are **reached** (log in as X, open path Y, apply filter Z), never **re-seeded**. **No `--profile` flags** — flags fork the seed path and rot (the exact F-205 footgun; non-idiomatic vs the single-`seeds.exs` Ecto/Phoenix convention).
- **D-02:** Empty / scoped / permission-edge states are reached via mechanisms already wired in the codebase:
  - **Sparse org** — `offboarded-co` is already engineered as a purged-empty end-state (`RetentionTail.assert_org_y_audit_empty!/1` hard-asserts zero audit footprint). `support@offboarded-co.example.com` → honest empty scoped Timeline.
  - **Scoped login** — `my_authorize_fn/1` + `scope_operator_query/3` (`router.ex`) narrow Timeline/Transaction/Actor/RowHistory to a support user's org; admin-only screens (Coverage/Evidence/Exports/Policy) return `{:error, :unauthorized}` for the same login = the **permission-edge** state for free.
  - **Filter windows** — future-date filter (`?from=2030-…`) yields an empty Timeline against populated data.
- **D-03:** Document a **per-state recipe table** (screen × state × login × filter/path) in `DEMO-MANIFEST.md`, backed by a doc-contract test so recipes can't silently drift from the seed across the 8 later screenshot phases. `mix demo.reset && mix demo.seed` stays the only seed entrypoint.
- **D-04 (deferred — the one genuinely seed-unreachable state):** Coverage **fully-covered / all-empty** depends on trigger registration + schema introspection (`Health.trigger_coverage`), NOT org rows — cannot be produced seed-only. **Defers to render-phase 138** (Coverage owner): register triggers across all demo tables, or render a synthetic fully-covered snapshot. Phase 135 must note this in the recipe table, not attempt it.

### 2. Actor identity — realistic-skewed + deliberate edge coverage (F-202)
- **D-05 (root cause):** "Actor unknown everywhere" is NOT a broken GUC mechanism. The GUC path works (`Support.set_actor_guc!/1` → `set_config('threadline.actor_ref', …)`; trigger reads it into `audit_transactions.actor_ref`; `actor_label/1` displays it). The symptom comes from **`Personas.run`**: it inserts `organizations` / `org_memberships` / `agents` (all trigger-audited) with **no actor GUC** AND **never backdates them** (`Temporal.run` only rewrites tx registered in `ctx.timestamps`). Those null-actor wall-clock-`now` setup rows sort to the **top of the default 24h window**, burying the actor-populated (epoch-backdated) ticket rows. Fix shape: give persona/setup transactions a real actor **and** a backdated timestamp.
- **D-06:** Realistic-skewed roster (humans dominate; one small, named, in-window cluster per non-human kind so each is demonstrable without looking synthetic):
  | Kind | Who | Activity | ~Share |
  |------|-----|----------|:--:|
  | `:user` | existing 5 personas + agent fillers | ticket replies/closes, hero #4521 close, #4518 delete, filler churn | ~70% |
  | `:admin` | `admin@example.com` | org/membership/agent **setup** transactions (the D-05 fix) | ~15% |
  | `:service_account` | `service_account/zendesk-sync` | inbound ticket sync (INSERT + UPDATE upserts) | ~5% |
  | `:job` | `job/oban-retention-purge` | attribute the **existing** retention purge (zero new rows) + a stale-ticket sweep | ~5% |
  | `:system` | `system/trigger-backfill` | one small backfill/correction cluster | ~3% |
  | `:anonymous` | public ticket-submission form | ONE deliberate cluster of unauthenticated ticket INSERTs, backdated in-window → renders as honest muted "unknown", not a bug | ~2% |
- **D-07:** Generalize `Support.set_actor_guc!/1` and `Support.audit_context/2` to accept a kind (currently hardcoded `:user`); mechanism already supports all kinds via `ActorRef.new/2`.
- **D-08 (constraint):** Use `:service_account` for the integration actor. **Do NOT introduce `:integration`** — `ActorRef` validates only the 6 kinds; adding it is a library change, out of scope.

### 3. Op/table diversity — in-window variety pack, not a global ratio (F-203, F-201)
- **D-09 (load-bearing constraint A):** Only **`ticket_replies`** runs the custom trigger with `store_changed_from: true` + `mask: ["internal_note_body","body"]`. It is the **only** table that can show a rich multi-field **before→after** diff AND a `[REDACTED]` field. `tickets` / `org_memberships` / `agents` / `organizations` use the default trigger that writes `changed_from = NULL` → their UPDATEs are honestly **after-only**. **Do not fake `before` values** — `ChangeDiff` deliberately omits them and the docs call this honest.
- **D-10 (load-bearing constraint B):** The default Timeline window is **24h off wall-clock `now`** (`timeline_live.ex`), but most seed is anchored to the frozen `demo_epoch` (past) → variety is invisible above the fold. In-window variety MUST use the proven `DateTime.utc_now() |> DateTime.add(-N, :hour)` pattern from `seed_active_agent_window` (`anchors.ex`), with fixed deterministic offsets.
- **D-11:** Two-layer op-mix (do NOT chase a global 50/35/15 — it's invisible in the default window):
  - **In-window "variety pack"** (~**5 INSERT / 4 UPDATE / 2 DELETE**), wall-clock-anchored, so all three op-colors + op-filters show above the fold.
  - **Corpus / filler** shift from ~95% INSERT to ~**55/35/10** (extend `filler.ex`'s existing insert+update with a DELETE branch) for honest wide-date-range ("dense") counts.
- **D-12 (mutation stories, help-desk-plausible, in-window):**
  1. **Reply edited** — INSERT a `ticket_replies` row, then `Repo.update!` its `body` + `internal_note_body` → the canonical rich `before→after` + `[REDACTED]` diff (the J2 "what changed?" demo).
  2. **Ticket reopened / re-triaged** — `tickets` UPDATE `status: closed→open` + cleared `closed_at`; separate `assignee_id` reassignment.
  3. **Membership role change** — `org_memberships` UPDATE `role: agent→support`.
  4. **Reply hard-delete** — re-anchor one existing DELETE in-window.
  5. **Ticket delete** — `Repo.delete!` a duplicate/spam ticket (`tickets` DELETE color).
  6. **Membership delete** — offboarding removes an `org_memberships` row (third-table DELETE).
- **D-13:** **Guarantee** ≥1 UPDATE + ≥1 DELETE land in the default 24h window AND are reachable via op filters; back this with a thin seed/test assertion (`default-window query returns ≥1 of each op`). Coordinate non-human actors (D-06) onto these mutations so op-color + actor-kind diversity land together (feeds F-703 actor rows).
- **D-14 (redaction cohesion):** Keep `internal_note_body` masked on the reply-edit so Row-history `[REDACTED]` and the redaction-drift screen stay consistent. Use the **existing** redaction config (`dev.exs` policy vs deployed trigger drift) — do NOT introduce a second config.

### 4. IA lock-in — lock the existing artifact + cheap doc-contract test (criterion #4)
- **D-15:** The canonical IA artifact **already exists** — `.planning/milestones/v1.31-PERSONAS-IA.md` (P1–P5, J1–J11, earned flows, Find/Verify/Prove triad). **Lock it in place** with a status header; do **NOT** append/copy the IA into `v1.31-UI-AUDIT.md` (that would fork it into two files and create the very drift the milestone forbids — overturns the original working assumption).
- **D-16:** Stabilize the ID scheme: personas `P1–P5`, jobs `J1–J11`, earned flows `EF1–EF5`, each EF bound to its audit finding so the trace **finding → JTBD → persona → flow** is navigable by ID. Earned-flow trace:
  - EF1 record-first cordoned path → J4/P2 → F-1001 (Phase 140)
  - EF2 first-class row-history entry → J2/P1 → F-1003 (138/140)
  - EF3 close the export loop → J6/P3 → F-602, F-1002 (140)
  - EF4 correlation-id paste/deep-link on Home → J1/P1 → F-1001 (140)
  - EF5 Prove-group separator before Exports (+ optional Verify→Trust card label) → P3 IA → F-105, F-304 (139)
- **D-17:** Add a one-line pointer in `v1.31-UI-AUDIT.md` (near the Status line): IDs `P1–P5 / J1–J11 / EF1–EF5` are locked in `v1.31-PERSONAS-IA.md`; cite IDs from there. This satisfies ROADMAP criterion #4 via reference, not duplication.
- **D-18:** Add a **C-lite doc-contract test** (~15 assertions): PERSONAS-IA.md contains `P1..P5`, `J1..J11`, `EF1..EF5`, the `Find/Verify/Prove` triad string, and the audit doc's pointer line exists. Makes the lock survive `/clear`.
- **D-19 (reconcile):** The ROADMAP/brief says "J1–J10" — the real count is **J1–J11** (J11 = P5 first-mount). Fix any Phase 135 success-criterion wording to J1–J11.

### Claude's Discretion
- Exact in-window hour offsets, exact filler ratio within ~50–60/30–40/10–15, exact seed-module decomposition (extend `Anchors`/`Filler` vs a new thin `VarietyPack` module) — all left to planning/execution, provided determinism + the D-13 in-window guarantee hold.
- Exact actor-id literal strings (suggested: `service_account/zendesk-sync`, `job/oban-retention-purge`, `system/trigger-backfill`) — finalize as named `Manifest` literals.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase foundation (read first)
- `.planning/milestones/v1.31-UI-AUDIT.md` — Phase 134 baseline; **F-201–F-205** (seed worklist) + **F-703** (enabled); the per-screen state matrix this phase makes reachable.
- `.planning/milestones/v1.31-PERSONAS-IA.md` — the IA artifact this phase **locks**; personas P1–P5, JTBD J1–J11, earned flows, Find/Verify/Prove triad.
- `examples/threadline_phoenix/DEMO-MANIFEST.md` — current SSOT (temporal anchors, orgs, personas, correlations); this phase extends it with the per-state recipe table + named actor literals.

### Seed implementation
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex` — pipeline entrypoint (`Personas → Exports → Anchors → Filler → Temporal → RetentionTail → RetentionRuns`).
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex` — `set_actor_guc!/1` (GUC mechanism), `audit_context/2`, `put_timestamp`; generalize to accept actor kind (D-07).
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex` — the D-05 root-cause site (null-actor, un-backdated setup rows).
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex` — `seed_active_agent_window` (the wall-clock in-window pattern to reuse, D-10); existing delete/update.
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/filler.ex` — the ~95% INSERT bulk; extend with DELETE branch + op-mix shift (D-11).
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/{retention_tail,retention_runs,exports,temporal}.ex` — retention purge (attribute to `:job`), export status spread, timestamp backfill.
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/tables.ex` + help-desk schemas (tickets, ticket_replies, org_memberships, organizations, agents).
- `examples/threadline_phoenix/config/dev.exs` — `:demo_epoch`, `:demo_seed_password`, and the **redaction policy/trigger drift** config (D-14); `ticket_replies` custom trigger config.

### Capture → display path (understand, don't change)
- `lib/threadline/semantics/` — `ActorRef` (6 kinds, validation — D-08), `AuditContext`.
- `lib/threadline/operator_surface/router.ex` — `my_authorize_fn/1`, `scope_operator_query/3` (the scoped/permission-edge mechanism, D-02).
- `lib/threadline/operator_surface/live/timeline_live.ex` — default 24h window (D-10), `actor_label/1` (D-05); `transaction_live.ex`, `row_history_component.ex` (op/diff render — F-201/F-103 render fixes defer to 138).
- `Threadline.Governance.SavedView` (queried in `timeline_live.ex`) — real persisted table keyed by `actor_ref`; **F-204 saved-views are seed-feasible** (the Home resume *render* defers to 139).

### Domain & ecosystem (grounding)
- `prompts/audit-lib-domain-model-reference.md` — ActorRef/Correlation/AuditContext/AuditChange semantics, op/field_changes model.
- `prompts/threadline-elixir-oss-dna.md` — doc-contract-test discipline (D-03, D-18 follow this).
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md`; `prompts/prior-art/from-sigra/Phoenix Auth Library — Jobs to Be Done, Personas & User Flows.md` (persona/JTBD exemplar format).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **GUC actor mechanism** (`Support.set_actor_guc!/1`): works today — the actor fix is orchestration (set it on persona/setup tx + new clusters), not new plumbing.
- **`seed_active_agent_window`** (`anchors.ex`): proven `DateTime.utc_now()`-relative anchoring — the template for the in-window variety pack (D-10/D-11).
- **`offboarded-co` org**: already engineered (with `assert_org_y_audit_empty!`) as the purged-empty / scoped-empty state — the backbone of the empty-state recipes (D-02).
- **`scope_operator_query/3` + `my_authorize_fn/1`** (`router.ex`): scoped views and permission-edge states come from logging in as `support@<org>` — no new code.
- **`SavedView`** persisted table: F-204 saved views are seedable now (data this phase; Home render = Phase 139).
- **`ticket_replies` custom trigger** (`store_changed_from` + `mask`): the only rich-diff + `[REDACTED]` source (D-09).

### Established Patterns
- Deterministic seed: PRNG `{1,2,3}`, UUID v5 ns `threadline.demo`, frozen `demo_epoch` — every new mutation must preserve this.
- Mutations flow through `Repo.transaction` + `set_actor_guc!` + `put_timestamp` + `Temporal.run` backfill — the maintainer's least-surprise idiom; new variety-pack rows use the same path.
- Doc-contract tests lock literals against drift (e.g. `operator_surface_doc_contract_test.exs`) — D-03 (recipe table) and D-18 (IA IDs) extend this culture.

### Integration Points
- New named actor literals → `ThreadlinePhoenix.Demo.Manifest` + `DEMO-MANIFEST.md`.
- Per-state recipe table → `DEMO-MANIFEST.md`, asserted by a new doc-contract test.
- IA lock header + pointer → `v1.31-PERSONAS-IA.md` and `v1.31-UI-AUDIT.md`; asserted by a new doc-contract test.

</code_context>

<specifics>
## Specific Ideas

- The deliberate-unknown actor is modeled as a **public ticket-submission form** — the one help-desk path where "who" is honestly unknowable (mirrors CloudTrail's anonymous/unauthenticated entries). One small, contextual, in-window cluster — not the default.
- Redaction story stays single-config: the reply-edit's masked `internal_note_body` must agree with the existing policy/trigger drift used by the Redaction screen.
- One-command maintainer story is sacred: `mix demo.reset && mix demo.seed`; reaching any state is always "log in as X, open path Y" — never "re-seed with flag Z."
</specifics>

<deferred>
## Deferred Ideas

- **F-201 render** (show inserted column values for INSERT instead of empty diff) — `transaction_live.ex` render path → **Phase 138**. Phase 135 only guarantees the `field_changes` data exists.
- **F-703 render** (op-color dots + table + change-count per Actor row) → **Phase 138**. Phase 135 seeds the actor/op variety it depends on.
- **F-103 render** (op-chip modifier in `row_history_component.ex`) → **Phase 136/138**.
- **F-204 Home resume row render** → **Phase 139**. Phase 135 seeds the `SavedView` data.
- **Coverage fully-covered / all-empty state** (trigger-registration dependent, D-04) → **Phase 138**.
- **Empty-as-diagnostic for Evidence/Exports/Retention** where global rows exist — represented via the scoped-unauthorized path in 135; a true populated-but-zero render is a per-screen-phase concern (137) if still wanted.

</deferred>

---

*Phase: 135-seed-enrichment-ia-lock-in*
*Context gathered: 2026-06-03*
