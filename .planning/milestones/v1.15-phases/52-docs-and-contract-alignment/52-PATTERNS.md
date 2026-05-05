# Phase 52: Docs and Contract Alignment - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/getting-started-saas.md` | docs | request-response | `guides/getting-started-saas.md` | exact |
| `guides/integrations/sigra.md` | docs | request-response | `guides/integrations/sigra.md` | exact |
| `guides/domain-reference.md` | docs | request-response | `guides/domain-reference.md` | exact |
| `guides/incident-playbook.md` | docs | request-response | `guides/incident-playbook.md` | exact |
| `guides/adoption-pilot-backlog.md` | docs | request-response | `guides/adoption-pilot-backlog.md` | exact |
| `examples/threadline_phoenix/README.md` | docs | request-response | `examples/threadline_phoenix/README.md` | exact |
| `test/threadline/integrations/sigra_doc_contract_test.exs` | test | request-response | `test/threadline/integrations/sigra_doc_contract_test.exs` | exact |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | test | request-response | `test/threadline/getting_started_saas_doc_contract_test.exs` | exact |
| `test/threadline/exploration_routing_doc_contract_test.exs` | test | request-response | `test/threadline/exploration_routing_doc_contract_test.exs` | exact |
| `test/threadline/incident_playbook_doc_contract_test.exs` | test | request-response | `test/threadline/incident_playbook_doc_contract_test.exs` | exact |
| `test/threadline/stg_doc_contract_test.exs` | test | request-response | `test/threadline/stg_doc_contract_test.exs` | exact |
| `test/threadline/example_phoenix_readme_contract_test.exs` | test | request-response | `test/threadline/example_phoenix_readme_contract_test.exs` | exact |

## Pattern Assignments

### `guides/getting-started-saas.md` (docs, request-response)

**Analog:** [getting-started-saas.md](/Users/jon/projects/threadline/guides/getting-started-saas.md:49)

**Canonical router-wiring block** (lines 49-75):
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
for additive `request_id` and `correlation_id` metadata only, and those values
fill missing fields only.
````

**Incident baseline wording** (lines 175-178):
```markdown
The reference app also requires an authenticated actor before it serves
`GET /api/audit_transactions/:id/changes`. That keeps the example honest about
incident drill-down: auth is included, while tenancy rules still belong to the
host app.
```

**Copy pattern:** keep the guide recommendation-first, with one copy-paste router snippet plus one narrow boundary paragraph. Do not expand into tenancy design or extra adapter options here.

---

### `guides/integrations/sigra.md` (docs, request-response)

**Analog:** [sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md:17)

**Direct callback contract** (lines 17-41):
````markdown
## Plug callback wire-up

Wire `Threadline.Plug` directly with both callbacks in the router pipeline
after your host has established request auth and any proxy-aware IP rewriting:

```elixir
pipeline :api do
  plug :accepts, ["json"]
  plug Threadline.Plug,
    actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
    context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
end
```

`actor_fn` decides who acted. `context_overrides_fn` can add only additive
request metadata when the baseline conn extraction has no value.
````

**Behavior bullets to preserve** (lines 45-50):
```markdown
4. Anonymous / Sigra-absent returns `nil`.
5. `x-correlation-id` header always wins.
6. `x-request-id` and any existing actor identity also stay authoritative.
```

**Copy pattern:** this file is the authoritative vocabulary source for the direct Sigra seam. Other docs should borrow its callback names and additive-only language instead of inventing alternate seams.

---

### `guides/domain-reference.md` (docs, request-response)

**Analog:** [domain-reference.md](/Users/jon/projects/threadline/guides/domain-reference.md:211)

**Contract-marker block** (lines 211-223):
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

**Routing-table style** (lines 183-190):
```markdown
| Intent | Primary API | Notes / pointer |
|--------|---------------|-----------------|
| Incident / time window across rows | `Threadline.Query.timeline/2` | ... |
| Correlation-scoped slice | `Threadline.Query.timeline/2`, `Threadline.Export`, `mix threadline.export` | ... |
| Everything in one DB transaction | `Threadline.Query.audit_changes_for_transaction/2`, `Threadline.audit_changes_for_transaction/2` | ... |
```

**Copy pattern:** keep doc-contract markers and public API tables stable. Align narrative wording around the incident JSON example without disturbing unrelated routing/reference sections.

---

### `guides/incident-playbook.md` (docs, request-response)

**Analog:** [incident-playbook.md](/Users/jon/projects/threadline/guides/incident-playbook.md:5)

**Top-of-file auth boundary** (lines 5-8):
```markdown
The Phoenix reference app now includes a baseline auth gate for
`GET /api/audit_transactions/:id/changes`: incident drill-down requires an
authenticated actor. Treat that as the minimum host shape, then layer your own
tenancy and policy rules on top.
```

**Scenario section structure** (lines 18-64, representative):
```markdown
## Scenario: who changed this row at time T?
### Diagnosis (API)
### Diagnosis (raw SQL)
### Expected output
### Recovery
```

**Copy pattern:** keep the auth boundary short and normalized up front, then retain the rigid scenario-section structure that the contract test already enforces.

---

### `guides/adoption-pilot-backlog.md` (docs, request-response)

**Analog:** [adoption-pilot-backlog.md](/Users/jon/projects/threadline/guides/adoption-pilot-backlog.md:54)

**Evidence-row contract** (lines 54-58):
```markdown
| `POST /api/posts` | HTTP | OK | ... | CI-class proof only: request wiring, actor bridge, and first audited write are locked by in-repo tests and guide snippets. |
| `GET /api/audit_transactions/:id/changes` | HTTP | OK | `guides/getting-started-saas.md`; `guides/incident-playbook.md`; `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` | CI-class proof only: the reference app now requires an authenticated actor before drill-down. Host teams still own tenancy and richer authorization review. |
```

**Template/disclaimer markers** (lines 21-31, 47-48):
```markdown
STG-HOST-TOPOLOGY-TEMPLATE
STG-AUDITED-PATH-RUBRIC
<!-- ADOPT-EXAMPLE-DISCLAIMER -->
```

**Copy pattern:** when aligning this doc, preserve the CI-class vs host-class distinction and keep the evidence cells tied to exact in-repo guides/tests instead of editorial summaries.

---

### `examples/threadline_phoenix/README.md` (docs, request-response)

**Analog:** [README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:87)

**Runnable example wiring story** (lines 87-104):
```markdown
## Audited HTTP path (`POST /api/posts`)

The example wires **`Threadline.Plug`** with both **`actor_fn`** and
**`context_overrides_fn`** on the `:api` pipeline ...

In the shipped example, both callbacks are wired directly into `Threadline.Plug`:
**`Threadline.Integrations.Sigra.actor_ref_from_conn/1`** decides actor identity and
**`Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1`** fills additive
request metadata only when `x-correlation-id` is absent.
```

**Incident drill-down wording** (lines 106-113):
```markdown
## Incident JSON drill-down (`audit_transaction_id` → changes)

CI: **`ThreadlinePhoenixWeb.PostsIncidentJsonPathTest`**. **Security:**
the reference app now requires an authenticated actor before it serves the
drill-down endpoint. Hosts still need their own tenancy and policy checks
before exposing transaction drill-down in production.
```

**Copy pattern:** this is the highest-risk copy-paste surface. Keep its prose tightly synced with the actual router/controller behavior and with the getting-started guide.

---

### `test/threadline/integrations/sigra_doc_contract_test.exs` (test, request-response)

**Analog:** [sigra_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_doc_contract_test.exs:5)

**Repo-root markdown loader** (lines 5-9):
```elixir
@repo_root File.cwd!()

defp read_rel!(segments) when is_list(segments) do
  @repo_root |> Path.join(Path.join(segments)) |> File.read!()
end
```

**Section-order lock pattern** (lines 11-37):
```elixir
for heading <- [
      "## Install",
      "## Plug callback wire-up",
      "## Behaviors locked by SPEC",
      "## correlation_id formats",
      "## Soft-dep contract"
    ] do
  assert String.contains?(doc, heading)
end

{idx_install, _} = :binary.match(doc, "## Install")
{idx_plug, _} = :binary.match(doc, "## Plug callback wire-up")
...
assert idx_install < idx_plug
```

**Literal-lock pattern** (lines 61-80):
```elixir
assert String.contains?(doc, "Wire `Threadline.Plug` directly with both callbacks")
assert String.contains?(doc, "`actor_fn` decides who acted")
assert String.contains?(doc, "can add only additive")
assert String.contains?(doc, "`request_id` from `x-request-id` first")
assert String.contains?(doc, "`correlation_id` from `x-correlation-id` first")
assert String.contains?(doc, "raises `ArgumentError` immediately")
```

**Copy pattern:** use explicit `String.contains?/2` and, where needed, heading-order checks. Avoid snapshots and avoid asserting broad editorial prose outside the public contract.

---

### `test/threadline/getting_started_saas_doc_contract_test.exs` (test, request-response)

**Analog:** [getting_started_saas_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/getting_started_saas_doc_contract_test.exs:14)

**Walkthrough checklist assertion style** (lines 14-45):
```elixir
headings = [
  "## 1. Prerequisites",
  "## 2. Add Threadline to your app",
  ...
  "## 8. Investigate the captured timeline"
]

Enum.each(headings, &assert(String.contains?(doc, &1)))
assert String.contains?(doc, router_block())
assert String.contains?(doc, blog_block())
assert String.contains?(doc, "`actor_fn` remains the only actor-authority path")
assert String.contains?(doc, "additive `request_id` and `correlation_id` metadata only")
assert String.contains?(doc, "requires an authenticated actor before it serves")
```

**Extract-from-source snippet pattern** (lines 71-83):
```elixir
defp router_block do
  GettingStartedFixtures.extract!(
    "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex",
    "router-pipeline-actor-fn"
  )
end
```

**Copy pattern:** for any docs that should mirror shipped code snippets, prefer extracting the snippet from the source-of-truth file instead of hardcoding the block twice in the test.

---

### `test/threadline/exploration_routing_doc_contract_test.exs` (test, request-response)

**Analog:** [exploration_routing_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/exploration_routing_doc_contract_test.exs:11)

**Anchor + ordering pattern** (lines 11-23):
```elixir
assert String.contains?(doc, "## Exploration API routing (v1.10+)")
assert String.contains?(doc, "XPLO-03-API-ROUTING")
...
{idx_routing, _} = :binary.match(doc, "## Exploration API routing (v1.10+)")
{idx_support, _} = :binary.match(doc, "## Support incident queries")
assert idx_routing < idx_support
```

**Incident example marker lock** (lines 25-34):
```elixir
assert String.contains?(doc, "COMP-EXAMPLE-INCIDENT-JSON")
assert String.contains?(doc, "examples/threadline_phoenix")
assert String.contains?(doc, "GET /api/audit_transactions")
assert String.contains?(doc, "audit_transaction_id")
assert String.contains?(doc, "requires an authenticated actor before it serves the")
```

**Copy pattern:** this is the right analog for cross-reference/anchor docs. Keep assertions tied to stable markers and public literals, not whole-section copy.

---

### `test/threadline/incident_playbook_doc_contract_test.exs` (test, request-response)

**Analog:** [incident_playbook_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/incident_playbook_doc_contract_test.exs:6)

**Whole-file setup + boundary lock** (lines 6-34):
```elixir
setup do
  content = File.read!(@playbook_path)
  %{content: content}
end

test "locks the incident drill-down auth baseline and host-owned policy boundary", %{content: content} do
  assert content =~ "GET /api/audit_transactions/:id/changes"
  assert content =~ "incident drill-down requires an"
  assert content =~ "authenticated actor"
  assert content =~ "Treat that as the minimum host shape, then layer your own"
  assert content =~ "tenancy and policy rules on top"
end
```

**Structured-section enforcement** (lines 64-88):
```elixir
assert section_content =~ "### Diagnosis (API)"
assert section_content =~ "### Diagnosis (raw SQL)"
assert section_content =~ "### Expected output"
assert section_content =~ "### Recovery"
```

**Copy pattern:** use this file’s style when locking one guide’s internal structure, especially when the contract is partly wording and partly required section layout.

---

### `test/threadline/stg_doc_contract_test.exs` (test, request-response)

**Analog:** [stg_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/stg_doc_contract_test.exs:22)

**Marker-preservation pattern** (lines 22-33):
```elixir
doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
assert String.contains?(doc, "STG-HOST-TOPOLOGY-TEMPLATE")
assert String.contains?(doc, "STG-AUDITED-PATH-RUBRIC")
assert String.contains?(doc, "<!-- ADOPT-EXAMPLE-DISCLAIMER -->")
```

**Scoped section extraction** (lines 35-44, 62-66):
```elixir
section = walked_example_section()

assert String.contains?(section, "| `GET /api/audit_transactions/:id/changes` | HTTP | OK |")
assert String.contains?(section, "Host teams still own tenancy and richer authorization review.")

defp walked_example_section do
  doc = read_rel!(["guides", "adoption-pilot-backlog.md"])
  [_before, after_heading] = String.split(doc, "### Example: ExampleCloud walkthrough (maintainer-walked)", parts: 2)
  hd(String.split(after_heading, "\n## ", parts: 2))
end
```

**Copy pattern:** when a single subsection carries the contract, extract just that subsection and assert on its bounded contents instead of scanning the entire file for generic words.

---

### `test/threadline/example_phoenix_readme_contract_test.exs` (test, request-response)

**Analog:** [example_phoenix_readme_contract_test.exs](/Users/jon/projects/threadline/test/threadline/example_phoenix_readme_contract_test.exs:12)

**Small focused literal tests** (lines 12-33):
```elixir
test "example README locks the direct Sigra callback pair" do
  doc = read_rel!(@readme_path)

  assert String.contains?(doc, "Threadline.Integrations.Sigra.actor_ref_from_conn/1")
  assert String.contains?(doc, "Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1")
  assert String.contains?(doc, "wired directly into `Threadline.Plug`")
end

test "example README locks the incident drill-down auth boundary" do
  doc = read_rel!(@readme_path)

  assert String.contains?(doc, "requires an authenticated actor before it serves the")
  assert String.contains?(doc, "drill-down endpoint")
  assert String.contains?(doc, "Hosts still need their own tenancy and policy checks")
end
```

**Copy pattern:** use small topic-specific tests instead of one large umbrella README contract test.

## Shared Patterns

### Direct host-wiring vocabulary
**Sources:** [router.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:4), [sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md:23)

Apply to: `guides/getting-started-saas.md`, `guides/integrations/sigra.md`, `examples/threadline_phoenix/README.md`, and the related contract tests.

```elixir
pipeline :api do
  plug(:accepts, ["json"])

  plug(Threadline.Plug,
    actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
    context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
  )
end
```

Rule to copy: always use the canonical callback names and direct `Threadline.Plug` wiring. Do not reintroduce example-local delegate seams.

### Additive-only override boundary
**Source:** [sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md:31), [getting-started-saas.md](/Users/jon/projects/threadline/guides/getting-started-saas.md:67)

Apply to: all adopter-facing docs and any doc-contract tests that lock the host-wiring story.

```markdown
`actor_fn` decides who acted. `context_overrides_fn` can add only additive
request metadata when the baseline conn extraction has no value.

`actor_fn` remains the only actor-authority path. `context_overrides_fn` is
for additive `request_id` and `correlation_id` metadata only.
```

Rule to copy: the docs should consistently say actor identity comes from `actor_fn`, while `context_overrides_fn` only fills missing request metadata.

### Normalized incident auth boundary
**Sources:** [audit_transaction_controller.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex:12), [incident-playbook.md](/Users/jon/projects/threadline/guides/incident-playbook.md:5), [domain-reference.md](/Users/jon/projects/threadline/guides/domain-reference.md:220), [README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:110)

Apply to: incident-facing docs and every contract test that mentions drill-down.

```elixir
**Reference-app contract:** requests must arrive with an authenticated actor.
Real hosts still own their tenancy and policy rules.
```

```markdown
The reference app requires an authenticated actor before it serves the
drill-down endpoint. Production hosts still own tenancy scoping and any richer
authorization policy beyond that baseline.
```

Rule to copy: state the boundary in normalized Threadline terms first, then the host-owned follow-on policy. Avoid Sigra-private field names as the public contract.

### Doc-contract assertion posture
**Sources:** [sigra_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_doc_contract_test.exs:11), [exploration_routing_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/exploration_routing_doc_contract_test.exs:11), [stg_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/stg_doc_contract_test.exs:35)

Apply to: all `test/threadline/*doc_contract*_test.exs` touched in this phase.

```elixir
assert String.contains?(doc, "COMP-EXAMPLE-INCIDENT-JSON")
{idx_routing, _} = :binary.match(doc, "## Exploration API routing (v1.10+)")
section = walked_example_section()
```

Rule to copy: assert concrete literals, markers, and ordering. When only one subsection matters, extract that subsection first. Keep tests narrow and drift-focused.

## No Analog Found

None. Every planned docs/test surface already has an in-repo analog and an existing contract-test style to extend.

## Metadata

**Analog search scope:** `guides/`, `examples/threadline_phoenix/`, `test/threadline/`, `.planning/milestones/v1.15-phases/51-authenticated-incident-drill-down/`
**Pattern extraction date:** 2026-05-05
