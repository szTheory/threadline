# Phase 56: Docs, Contracts, and Arc Alignment - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `README.md` | docs | request-response | `README.md` | exact |
| `guides/domain-reference.md` | docs | request-response | `guides/domain-reference.md` | exact |
| `guides/getting-started-saas.md` | docs | request-response | `guides/getting-started-saas.md` | exact |
| `guides/incident-playbook.md` | docs | request-response | `guides/incident-playbook.md` | exact |
| `guides/production-checklist.md` | docs | request-response | `guides/production-checklist.md` | exact |
| `examples/threadline_phoenix/README.md` | docs | request-response | `examples/threadline_phoenix/README.md` | exact |
| `test/threadline/readme_doc_contract_test.exs` | test | request-response | `test/threadline/readme_doc_contract_test.exs` | exact |
| `test/threadline/exploration_routing_doc_contract_test.exs` | test | request-response | `test/threadline/exploration_routing_doc_contract_test.exs` | exact |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | test | request-response | `test/threadline/getting_started_saas_doc_contract_test.exs` | exact |
| `test/threadline/incident_playbook_doc_contract_test.exs` | test | request-response | `test/threadline/incident_playbook_doc_contract_test.exs` | exact |
| `test/threadline/example_phoenix_readme_contract_test.exs` | test | request-response | `test/threadline/example_phoenix_readme_contract_test.exs` | exact |
| `.planning/PROJECT.md` | config | transform | `.planning/PROJECT.md` | exact |
| `.planning/STATE.md` | config | transform | `.planning/STATE.md` | exact |

## Pattern Assignments

### `README.md` (docs, request-response)

**Analog:** [README.md](/Users/jon/projects/threadline/README.md:14)

**Compact top-level doc shape** (lines 14-19):
```markdown
## Start here

- **Evaluating:** open the [HexDocs](https://hexdocs.pm/threadline) for the full API.
- **Adopting in Phoenix SaaS:** read [guides/getting-started-saas.md](guides/getting-started-saas.md).
- **Using Sigra:** read [guides/integrations/sigra.md](guides/integrations/sigra.md).
- **Contributing:** follow [`CONTRIBUTING.md`](CONTRIBUTING.md) and run `mix ci.all`.
```

**Investigation hierarchy wording pattern** (lines 79-91):
```markdown
5. Query the audit trail:

```elixir
Threadline.history(MyApp.Post, post.id, repo: MyApp.Repo)
Threadline.timeline([table: "posts"], repo: MyApp.Repo)
Threadline.timeline_page([table: "posts"], repo: MyApp.Repo, page_size: 200)
```

Use `Threadline.timeline/2` for smaller eager slices. When an investigation window is
large enough that you want stable incremental traversal, switch to `Threadline.timeline_page/2`
and continue with the returned `next_cursor` instead of offset pagination.
```

**Copy pattern:** keep the root README concise and routing-oriented. Add the new hierarchy here as a short map, then push details into guides instead of turning README into a second domain reference.

---

### `guides/domain-reference.md` (docs, request-response)

**Analog:** [domain-reference.md](/Users/jon/projects/threadline/guides/domain-reference.md:177)

**Canonical routing-table pattern** (lines 177-190):
```markdown
## Exploration API routing (v1.10+)

This block answers **“which public API first?”** for common exploration tasks.

| Intent | Primary API | Notes / pointer |
|--------|---------------|-----------------|
| Incident / time window across rows | `Threadline.timeline/2` or `Threadline.timeline_page/2` | Use eager `timeline/2` for smaller bounded windows. Switch to `timeline_page/2` for large investigations where stable traversal across pages matters. |
| Everything in one DB transaction | `Threadline.Query.audit_changes_for_transaction/2`, `Threadline.audit_changes_for_transaction/2` | **`opts[:repo]`** is required. Ordering matches timeline. |
| Field-level diff for one `%AuditChange{}` | `Threadline.change_diff/2`, `Threadline.ChangeDiff` | ... |
```

**Incident-example contract marker pattern** (lines 211-223):
```markdown
### Reference example: incident JSON (v1.11+)

Contract marker for automated doc checks: **COMP-EXAMPLE-INCIDENT-JSON**

1. **`POST /api/posts`** returns **`audit_transaction_id`**
2. **`GET /api/audit_transactions/:id/changes`** loads every **`AuditChange`**

CI covers the round-trip in **`ThreadlinePhoenixWeb.PostsIncidentJsonPathTest`**.
The reference app requires an authenticated actor before it serves the
drill-down endpoint. Production hosts still own tenancy scoping and any richer
authorization policy beyond that baseline.
```

**Copy pattern:** keep this file as the canonical “which API first?” table plus the stable contract marker block. Phase 56 should change the routing rows and example story, not the surrounding reference structure.

---

### `guides/getting-started-saas.md` (docs, request-response)

**Analog:** [getting-started-saas.md](/Users/jon/projects/threadline/guides/getting-started-saas.md:49)

**Snippet-driven walkthrough pattern** (lines 49-75):
````markdown
## 5. Wire `Threadline.Plug` with actor and additive request metadata

The Phoenix example keeps request capture small and explicit by wiring both
Sigra callbacks directly into `Threadline.Plug`:

```elixir
    plug(Threadline.Plug,
      actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
      context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
    )
```

`actor_fn` remains the only actor-authority path. `context_overrides_fn` is
for additive `request_id` and `correlation_id` metadata only.
````

**First-hour investigation loop pattern** (lines 156-187):
```markdown
Open IEx in the app and use the same first request to inspect row history, transaction drill-down, and point-in-time reconstruction:

timeline = Threadline.timeline(filters)
first_page = Threadline.timeline_page(filters, page_size: 100)
...
Threadline.as_of(MyApp.Post, post_id, as_of_at, repo: MyApp.Repo)

The reference app also requires an authenticated actor before it serves
`GET /api/audit_transactions/:id/changes`. That keeps the example honest about
incident drill-down: auth is included, while tenancy rules still belong to the
host app.
```

**Copy pattern:** keep the guide copy-pasteable and source-backed. When Phase 56 swaps the default transaction drill-down story, preserve the step headings, extracted snippet posture, and short host-boundary paragraph.

---

### `guides/incident-playbook.md` (docs, request-response)

**Analog:** [incident-playbook.md](/Users/jon/projects/threadline/guides/incident-playbook.md:5)

**Top-of-file policy-boundary pattern** (lines 5-8):
```markdown
The Phoenix reference app now includes a baseline auth gate for
`GET /api/audit_transactions/:id/changes`: incident drill-down requires an
authenticated actor. Treat that as the minimum host shape, then layer your own
tenancy and policy rules on top.
```

**Rigid scenario structure** (lines 198-234):
```markdown
## Scenario: single-transaction drilldown

### Diagnosis (API)
### Diagnosis (raw SQL)
### Expected output
### Recovery
```

**Copy pattern:** keep the normalized auth disclaimer at the top and preserve the exact scenario scaffold that the contract test enforces. Only swap the API example from raw composition to the bundled contract.

---

### `guides/production-checklist.md` (docs, request-response)

**Analog:** [production-checklist.md](/Users/jon/projects/threadline/guides/production-checklist.md:61)

**Downstream pointer-table pattern** (lines 61-79):
```markdown
## Support incident queries

Pre-launch: confirm operators can answer the five canonical support questions
(see [`domain-reference.md`](domain-reference.md#support-incident-queries) for full SQL and API notes).
For a **skimmable “which public API first?”** map before diving into playbooks,
see [`domain-reference.md` — Exploration API routing](domain-reference.md#exploration-api-routing-v110).

| Question (1-line) | API / Mix | SQL |
|-------------------|-----------|-----|
| 1. Row history — PK in a time window | `Threadline.history/3`, `Threadline.Query.timeline/2` | ... |
| 2. Actor window — one actor across tables | `Threadline.actor_history/2`, `timeline/2` + `:actor_ref` | ... |
```

**Copy pattern:** this file should stay a pointer hub, not a second routing spec. Keep it aligned to the domain-reference anchors and API names only.

---

### `examples/threadline_phoenix/README.md` (docs, request-response)

**Analog:** [README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:87)

**Direct host-wiring narrative** (lines 87-104):
```markdown
## Audited HTTP path (`POST /api/posts`)

The example wires **`Threadline.Plug`** with both **`actor_fn`** and
**`context_overrides_fn`** on the `:api` pipeline ...

In the shipped example, both callbacks are wired directly into `Threadline.Plug`:
**`Threadline.Integrations.Sigra.actor_ref_from_conn/1`** decides actor identity and
**`Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1`** fills additive
request metadata only when `x-correlation-id` is absent.
```

**Bundled incident story** (lines 106-113):
```markdown
## Incident JSON drill-down (`audit_transaction_id` → bundled incident)

Successful **`POST /api/posts`** responses include **`audit_transaction_id`** ...
Call **`GET /api/audit_transactions/:id/changes`** ... to fetch the curated
incident bundle rendered from **`Threadline.incident_bundle/2`** ...

CI: **`ThreadlinePhoenixWeb.PostsIncidentJsonPathTest`**. **Security:**
the reference app now requires an authenticated actor before it serves the
drill-down endpoint. Hosts still need their own tenancy and policy checks
before exposing transaction drill-down in production.
```

**Copy pattern:** this is the strongest proof surface for the packaged story. Other docs should converge on this wording, not rephrase the endpoint semantics independently.

---

### `test/threadline/readme_doc_contract_test.exs` (test, request-response)

**Analog:** [readme_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/readme_doc_contract_test.exs:15)

**Focused literal-lock pattern** (lines 15-47):
```elixir
test "README declares the public API surface" do
  readme = File.read!("README.md")
  assert String.contains?(readme, "Threadline.Plug")
  assert String.contains?(readme, "Threadline.record_action/2")
  assert String.contains?(readme, "Threadline.timeline/2")
  assert String.contains?(readme, "Threadline.timeline_page/2")
  assert String.contains?(readme, "Threadline.export_json/2")
end

test "README links the public docs hubs for adopters and operators" do
  readme = File.read!("README.md")
  assert String.contains?(readme, "guides/getting-started-saas.md")
  assert String.contains?(readme, "guides/incident-playbook.md")
end
```

**Fixture-backed API-truth pattern** (lines 96-107):
```elixir
assert {:ok, _} = Threadline.ReadmeQuickstartFixtures.record_action_call(Repo)
assert %Threadline.Query.TimelinePage{} =
         Threadline.ReadmeQuickstartFixtures.timeline_page_call(Repo)
```

**Copy pattern:** keep assertions narrow and literal. Use fixture-backed checks for README API shapes instead of whole-file comparisons.

---

### `test/threadline/exploration_routing_doc_contract_test.exs` (test, request-response)

**Analog:** [exploration_routing_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/exploration_routing_doc_contract_test.exs:11)

**Section-anchor and order pattern** (lines 11-24):
```elixir
assert String.contains?(doc, "## Exploration API routing (v1.10+)")
assert String.contains?(doc, "XPLO-03-API-ROUTING")
assert String.contains?(doc, "audit_changes_for_transaction")
assert String.contains?(doc, "Threadline.timeline_page/2")

{idx_routing, _} = :binary.match(doc, "## Exploration API routing (v1.10+)")
{idx_support, _} = :binary.match(doc, "## Support incident queries")
assert idx_routing < idx_support
```

**Cross-doc pointer pattern** (lines 50-54):
```elixir
doc = read_rel!(["guides", "production-checklist.md"])

assert String.contains?(doc, "domain-reference.md#exploration-api-routing-v110")
assert String.contains?(doc, "domain-reference.md#support-incident-queries")
```

**Copy pattern:** use this file for cross-doc invariants. Phase 56 should extend it with the new default transaction-drill-down API names and preserve anchor/order checks.

---

### `test/threadline/getting_started_saas_doc_contract_test.exs` (test, request-response)

**Analog:** [getting_started_saas_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/getting_started_saas_doc_contract_test.exs:14)

**Walkthrough checklist pattern** (lines 14-47):
```elixir
headings = [
  "## 1. Prerequisites",
  "## 2. Add Threadline to your app",
  "## 3. Install the audit schema",
  "## 4. Generate triggers for posts",
  "## 5. Wire `Threadline.Plug` with actor and additive request metadata",
  "## 6. Exercise the first audited write",
  "## 7. Check trigger coverage",
  "## 8. Investigate the captured timeline"
]

assert String.contains?(doc, router_block())
assert String.contains?(doc, blog_block())
assert String.contains?(doc, "`actor_fn` remains the only actor-authority path")
assert String.contains?(doc, "`Threadline.timeline_page/2` is the same investigation path")
assert String.contains?(doc, "requires an authenticated actor before it serves")
```

**Copy pattern:** keep the guide contract anchored on headings, extracted live snippets, and a small set of stable wording lines. This is the best analog for testing the Phase 56 quickstart rewrite.

---

### `test/threadline/incident_playbook_doc_contract_test.exs` (test, request-response)

**Analog:** [incident_playbook_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/incident_playbook_doc_contract_test.exs:11)

**Boundary + scenario assertions** (lines 28-49):
```elixir
assert content =~ "GET /api/audit_transactions/:id/changes"
assert content =~ "incident drill-down requires an"
assert content =~ "authenticated actor"
assert content =~ "Treat that as the minimum host shape, then layer your own"
assert content =~ "tenancy and policy rules on top"

assert content =~ "Threadline.history("
assert content =~ "Threadline.actor_history("
assert content =~ "Threadline.audit_changes_for_transaction("
assert content =~ "Threadline.as_of("
```

**Stable structure pattern** (lines 64-88):
```elixir
assert section_content =~ "### Diagnosis (API)"
assert section_content =~ "### Diagnosis (raw SQL)"
assert section_content =~ "### Expected output"
assert section_content =~ "### Recovery"
```

**Copy pattern:** keep the playbook test structural and literal-focused. Replace API names deliberately, but do not snapshot whole scenarios or paragraphs.

---

### `test/threadline/example_phoenix_readme_contract_test.exs` (test, request-response)

**Analog:** [example_phoenix_readme_contract_test.exs](/Users/jon/projects/threadline/test/threadline/example_phoenix_readme_contract_test.exs:12)

**Cross-surface literal reuse** (lines 12-33):
```elixir
assert String.contains?(doc, "Threadline.Integrations.Sigra.actor_ref_from_conn/1")
assert String.contains?(doc, "Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1")
assert String.contains?(doc, "wired directly into `Threadline.Plug`")

assert String.contains?(doc, "requires an authenticated actor before it serves the")
assert String.contains?(doc, "drill-down endpoint")
assert String.contains?(doc, "Hosts still need their own tenancy and policy checks")
```

**Copy pattern:** reuse exact callback and host-boundary literals here and in other doc-contract files. This file is the best canonical source for shared wording once the example README is updated.

---

### `.planning/PROJECT.md` (config, transform)

**Analog:** [PROJECT.md](/Users/jon/projects/threadline/.planning/PROJECT.md:21)

**Pointer-style milestone summary** (lines 21-33):
```markdown
## Current Milestone: v1.16 — Investigation Table Stakes

**Goal:** Make Threadline answer the first serious audit investigation questions ...

**Strategic arc:** `.planning/MILESTONE-ARC.md` now records the standing
recommendation order for future milestones so `/gsd-new-milestone` can start
from a durable gameplan instead of a blank prompt.
```

**Copy pattern:** keep only the local milestone consequence here and point outward for future ordering. Do not duplicate the candidate milestone table or ranked rationale from `.planning/MILESTONE-ARC.md`.

---

### `.planning/STATE.md` (config, transform)

**Analog:** [STATE.md](/Users/jon/projects/threadline/.planning/STATE.md:20)

**Status-plus-pointer pattern** (lines 20-28):
```markdown
**Current Focus**: v1.16 — Investigation Table Stakes. Phase 55 is shipped;
Phase 56 is the next execution target for docs and contract alignment.
See `.planning/MILESTONE-ARC.md` for the standing strategic order after this milestone.

Phase: 56 — Docs, Contracts, and Arc Alignment (next)
Plan: Not started
Status: Phase 55 shipped; Phase 56 is the next execution target in v1.16.
```

**Decision-log summary pattern** (lines 41-53):
```markdown
- 2026-05-05: Record a standing milestone arc in `.planning/MILESTONE-ARC.md` ...
- 2026-05-05: Phase 53 introduced ...
- 2026-05-05: Phase 55 plan 55-02 moved the Phoenix reference incident endpoint onto `Threadline.incident_bundle/2` ...
```

**Copy pattern:** keep `STATE.md` as execution memory and pointer summary. If future candidates are mentioned at all, they should be indirect references back to `.planning/MILESTONE-ARC.md`, not a restated ranking table.

## Shared Patterns

### Canonical Investigation Hierarchy
**Sources:** [README.md](/Users/jon/projects/threadline/README.md:79), [domain-reference.md](/Users/jon/projects/threadline/guides/domain-reference.md:177)
```markdown
Use `Threadline.timeline/2` for smaller eager slices.
Switch to `Threadline.timeline_page/2` for large stable windows.
Use higher-level investigation helpers for common support questions.
Use `Threadline.incident_bundle/2` as the default transaction drill-down story.
```

### Host-Owned Auth / Policy Boundary
**Sources:** [getting-started-saas.md](/Users/jon/projects/threadline/guides/getting-started-saas.md:177), [incident-playbook.md](/Users/jon/projects/threadline/guides/incident-playbook.md:5), [examples/threadline_phoenix/README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:110)
```markdown
requires an authenticated actor before it serves ...
Treat that as the minimum host shape ...
Hosts still need their own tenancy and policy checks ...
```

Apply this wording consistently across all incident-facing docs. The library stays auth-agnostic; the example endpoint is only the minimum host proof.

### Narrow Doc-Contract Assertions
**Sources:** [readme_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/readme_doc_contract_test.exs:15), [exploration_routing_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/exploration_routing_doc_contract_test.exs:11), [getting_started_saas_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/getting_started_saas_doc_contract_test.exs:14)
```elixir
assert String.contains?(doc, "...")
{idx_a, _} = :binary.match(doc, "...")
assert idx_a < idx_b
assert String.contains?(doc, router_block())
```

Use literal locks, heading-order checks, and extracted source snippets. Avoid snapshots and broad paragraph assertions.

### Shipped Incident-Bundle Truth
**Source:** [investigation_test.exs](/Users/jon/projects/threadline/test/threadline/investigation_test.exs:282)
```elixir
assert {:ok, %IncidentBundle{} = result} = Threadline.incident_bundle(txn.id, repo: @repo)
assert result.transaction.id == txn.id
assert result.action.id == action.id
assert first_change.change_diff["schema_version"] == 1
assert {:error, :not_found} = Threadline.incident_bundle(Ecto.UUID.generate(), repo: @repo)
```

Docs should describe `incident_bundle/2` in terms that match this shipped behavior. Contract tests should lock the names and routing, not recreate the behavior suite.

### Planning Arc Pointer Discipline
**Sources:** [PROJECT.md](/Users/jon/projects/threadline/.planning/PROJECT.md:33), [STATE.md](/Users/jon/projects/threadline/.planning/STATE.md:21), [MILESTONE-ARC.md](/Users/jon/projects/threadline/.planning/MILESTONE-ARC.md:16)
```markdown
**Strategic arc:** `.planning/MILESTONE-ARC.md` now records the standing recommendation order ...
See `.planning/MILESTONE-ARC.md` for the standing strategic order after this milestone.
```

Apply to `.planning/PROJECT.md` and `.planning/STATE.md`. `.planning/MILESTONE-ARC.md` owns the candidate-order table and rationale.

## No Analog Found

None. Every likely Phase 56 touchpoint already has a strong in-repo analog.

## Metadata

**Analog search scope:** `README.md`, `guides/`, `examples/threadline_phoenix/`, `test/threadline/`, `.planning/`
**Files scanned:** 20+
**Pattern extraction date:** 2026-05-05
