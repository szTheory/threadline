# Phase 124: Adopter Doc Finish — Pattern Mapping

**Mapped:** 2026-05-28  
**Phase:** 124-adopter-doc-finish  
**Requirements:** DOC-01, DOC-02, DOC-03, DOC-04, DOC-05  
**Context SSOT:** `124-CONTEXT.md` · **Research SSOT:** `124-RESEARCH.md`

---

## 1. File inventory (create / modify)

| File | Wave | Action | Requirement |
|------|------|--------|-------------|
| `guides/getting-started-saas.md` | 124-01 | **Modify** | DOC-01 §6 IEx-first; DOC-02 §5 verify-only; DOC-03 §9 one-liner |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | 124-01 | **Modify** | DOC-01 contract evolution; DOC-02 dedicated test |
| `guides/operator-surface.md` | 124-02 | **Modify** | DOC-03 `:schemas` mount + reification; DOC-04 `/audit/evidence` viewer sentence |
| `test/threadline/operator_surface_doc_contract_test.exs` | 124-02 | **Modify** | DOC-03 mount + subsection + failure UX locks |
| `guides/domain-reference.md` | 124-03 | **Modify** | DOC-04 evidence write boundary SSOT |
| `guides/how-threadline-works.md` | 124-03 | **Modify** | DOC-04 mental model fix (lines 31–33) |
| `guides/integration-contracts.md` | 124-03 | **Modify** | DOC-04 evidence paragraph; DOC-05 lane section + inline touch-ups |
| `test/threadline/how_threadline_works_doc_contract_test.exs` | 124-03 | **Modify** | DOC-04 refute + host-write mirror |
| `test/threadline/integration_contracts_doc_contract_test.exs` | 124-03 | **Modify** | DOC-05 four-lane vocabulary test |

**No new test files required** — extend four existing contract modules (D-24, research §2.6).

**Explicit no-touch (out of scope):**

| File | Reason |
|------|--------|
| `lib/threadline/**` | Docs-only phase; code is behavior anchors only |
| `examples/threadline_phoenix/**` (except README read) | Sigra HTTP SSOT unchanged; example `:schemas` deferred |
| `guides/upgrade-path.md` | Matrix SSOT — link only, no matrix duplicate in integration-contracts |
| `guides/evidence-plane.md` | Phantom hub — refuted by `semver_adopter_doc_contract_test.exs` (D-18) |
| `test/threadline/example_phoenix_readme_contract_test.exs` | **Retain** sigra HTTP literals; do not weaken when removing from getting-started monolith |
| `test/threadline/upgrade_path_doc_contract_test.exs` | Matrix rows stay here only |
| `test/threadline/phx_gen_auth_doc_contract_test.exs` | Plug recipe SSOT — no ADOPT-AUTH duplication (D-09) |
| `test/threadline/evaluating_threadline_doc_contract_test.exs` | Evaluator neutrality — no duplication (D-09) |
| `mix.exs` `verify.doc_contract` alias | No new files → no alias change |

---

## 2. Per-file role classification

### Wave 124-01 — first-hour path + ADOPT-AUTH contract (DOC-01, DOC-02)

| File | Role | Data flow |
|------|------|-----------|
| `guides/getting-started-saas.md` | **Linear first-hour SSOT** | IEx audited write → neutral §5/§6 → §8 `demo-corr` handoff; HTTP depth deferred to example README |
| `getting_started_saas_doc_contract_test.exs` | **Regression gate** | Monolith walkthrough + per-REQ tests; dual-contract: refute open sigra HTTP; lock IEx + ADOPT-AUTH ordering |

### Wave 124-02 — operator mount completeness (DOC-03)

| File | Role | Data flow |
|------|------|-----------|
| `guides/operator-surface.md` | **Mount + screen SSOT** | `:schemas` on `threadline_operator_surface/2`; reification subsection; row-history prerequisites |
| `operator_surface_doc_contract_test.exs` | **Mount literal gate** | Extends existing route/auth/mount locks — no new file |

### Wave 124-03 — evidence boundary + integration lane vocabulary (DOC-04, DOC-05)

| File | Role | Data flow |
|------|------|-----------|
| `guides/domain-reference.md` | **Evidence write boundary SSOT** | `EVIDENCE-HOST-WRITE-BOUNDARY` → link target for mental model + integration-contracts |
| `guides/how-threadline-works.md` | **Evaluator mental model** | Host-written attestations; link to domain-reference anchor |
| `guides/integration-contracts.md` | **Seam + lane names SSOT** | Compact four-lane list → upgrade-path matrix |
| `how_threadline_works_doc_contract_test.exs` | **Mental model gate** | Refute stale “may persist”; assert host-write framing |
| `integration_contracts_doc_contract_test.exs` | **Seam architecture gate** | New lane-vocabulary test; refute matrix duplicate |

### Cross-cutting SSOT map (D-24)

```
upgrade-path.md          → lane matrix + claim types + proof
integration-contracts.md → seams + four lane IDs (no matrix)
domain-reference.md      → evidence write boundary
operator-surface.md      → mount completeness (:schemas)
getting-started-saas.md  → IEx write, neutral §5/§6
example README           → sigra HTTP session depth
```

---

## 3. Closest analog + code excerpts

### 3.1 `guides/getting-started-saas.md` — §6 IEx-first (DOC-01)

**Role:** Canonical first-hour walkthrough; §6 must not expose Sigra cookie names in open prose.

**Current gap — open cookie staging outside `<details>` (remove per D-02):**

```183:187:guides/getting-started-saas.md
Cookie staging for the reference app lives in
[`examples/threadline_phoenix/README.md`](../examples/threadline_phoenix/README.md)
— sign in at **`/users/log_in`**, copy **`_threadline_phoenix_key`** from
DevTools, and pass **`-b '_threadline_phoenix_key=PASTE_FROM_BROWSER'`**. This
example does not ship API bearer tokens — host-owned auth only.
```

**§5 prose already satisfies DOC-02 (contract-only):**

```73:104:guides/getting-started-saas.md
Your host app establishes identity on the conn first, then wires `Threadline.Plug`
with host-owned callbacks. Threadline does not own auth — it reads the actor and
request metadata your pipeline already attached.
...
Choose an auth lane when you need a full cookbook:

- **phx-gen-auth-reference** → [`guides/integrations/phx-gen-auth.md`](integrations/phx-gen-auth.md)
- **sigra-reference** (optional) → [`guides/integrations/sigra.md`](integrations/sigra.md)
- lane matrix → [`guides/upgrade-path.md`](upgrade-path.md)

Threadline does not require Sigra; do not use `Threadline.Integrations.Sigra`
unless you adopt the optional sigra-reference lane.
```

**§8 handoff literal (§6 IEx must set same `demo-corr`):**

```215:215:guides/getting-started-saas.md
filters = [table: "posts", correlation_id: "demo-corr", repo: MyApp.Repo]
```

**Closest analog — Phase 123 `:binary.match` ordering (CFG-02 B+):**

```101:114:test/threadline/getting_started_saas_doc_contract_test.exs
  test "getting-started documents threadline ecto_repos before resolve_repo consumers" do
    doc = read_rel!(@guide_path)
    literal = "config :threadline, ecto_repos: [MyApp.Repo]"

    assert String.contains?(doc, literal)

    {literal_idx, _} = :binary.match(doc, literal)
    {section_7_idx, _} = :binary.match(doc, "## 7. Check trigger coverage")
    {section_3_idx, _} = :binary.match(doc, "## 3. Install the audit schema")
    {sigra_fence_idx, _} = :binary.match(doc, "getting-started-sigra-reference-fence")

    assert literal_idx < section_7_idx
    assert literal_idx < sigra_fence_idx
    assert literal_idx < section_3_idx
```

**Closest analog — Phase 123 dedicated REQ test (`production_checklist_doc_contract_test.exs`):**

```10:22:test/threadline/production_checklist_doc_contract_test.exs
  test "production checklist cross-links threadline ecto_repos to getting-started" do
    doc = read_rel!(["guides", "production-checklist.md"])
    literal = "config :threadline, ecto_repos: [MyApp.Repo]"

    assert String.contains?(doc, "## Host repo wiring (prerequisite)")
    assert String.contains?(doc, literal)
    assert String.contains?(doc, "getting-started-saas.md#configure-threadline")
    ...
    {host_idx, _} = :binary.match(doc, "## Host repo wiring (prerequisite)")
    {section_1_idx, _} = :binary.match(doc, "## 1. Capture and triggers")
    assert host_idx < section_1_idx
  end
```

**Closest analog — Phase 123 sigra fence scoping:**

```120:141:test/threadline/getting_started_saas_doc_contract_test.exs
  test "getting-started optional sigra-reference fence is scoped" do
    doc = read_rel!(@guide_path)

    assert String.contains?(doc, "getting-started-sigra-reference-fence")

    marker = "getting-started-sigra-reference-fence"
    [_before, after_marker] = String.split(doc, marker, parts: 2)
    subsection = after_marker

    assert String.contains?(subsection, router_block())
    refute String.contains?(subsection, "MyApp.Audit.actor_ref_from_conn")

    {generic_idx, _} =
      :binary.match(doc, "actor_fn: &MyApp.Audit.actor_ref_from_conn/1")

    {marker_idx, _} = :binary.match(doc, marker)

    {sigra_idx, _} =
      :binary.match(doc, "Threadline.Integrations.Sigra.actor_ref_from_conn/1")

    assert generic_idx < marker_idx
    assert marker_idx < sigra_idx
  end
```

**Pattern to replicate (DOC-01 prose):** Insert `### Run your first audited write in IEx` after `### Recommended path`; rename `### Authenticate before...` → `### HTTP requests and host auth`; move all cookie/curl prose into existing `<details>`; optional `getting-started-sigra-http-staging-fence` inside `<details>`.

**Pattern to replicate (DOC-01 contract):** Remove monolith asserts at lines 67–69; add IEx subsection + `demo-corr` in §6 before §8; `refute` open `_threadline_phoenix_key` in full doc (or scoped before §6 `<details>` if fence added).

---

### 3.2 `test/threadline/getting_started_saas_doc_contract_test.exs` — DOC-01 + DOC-02

**Role:** Doc contract for getting-started; one verify artifact per REQ (Phase 123 D-16/D-20).

**Monolith conflict to fix (DOC-01 / D-04):**

```67:69:test/threadline/getting_started_saas_doc_contract_test.exs
    assert String.contains?(doc, "Authenticate before")
    assert String.contains?(doc, "_threadline_phoenix_key")
    assert String.contains?(doc, "does not ship API bearer")
```

**Dual-contract SSOT — sigra HTTP stays in example README test:**

```121:129:test/threadline/example_phoenix_readme_contract_test.exs
  test "example README documents API auth staging for POST /api/posts" do
    doc = read_rel!(@readme_path)

    assert String.contains?(doc, "Authenticate before")
    assert String.contains?(doc, "fetch_current_scope")
    assert String.contains?(doc, "missing actor")
    assert String.contains?(doc, "DEMO_USERS.md")
    assert String.contains?(doc, "_threadline_phoenix_key")
    assert String.contains?(doc, "does not ship API bearer")
```

**Pattern to replicate — new dedicated DOC-02 test (D-06–D-08):**

```elixir
test "getting-started §5 locks auth-neutral ADOPT-AUTH literals (DOC-02)" do
  doc = read_rel!(@guide_path)

  {s5, _} = :binary.match(doc, "## 5.")
  {s6, _} = :binary.match(doc, "## 6.")
  scope = {s5, s6 - s5}
  section = :binary.part(doc, scope)

  for literal <- [
        "Threadline does not own auth",
        "Choose an auth lane when you need a full cookbook:",
        "phx-gen-auth-reference",
        "sigra-reference",
        "Threadline does not require Sigra; do not use `Threadline.Integrations.Sigra`",
        "unless you adopt the optional sigra-reference lane."
      ] do
    assert :binary.match(section, literal) != :nomatch
  end

  {neutrality, _} = :binary.match(doc, "Threadline does not require Sigra")
  assert neutrality < s6

  {phx, _} = :binary.match(doc, "phx-gen-auth-reference")
  {sigra, _} = :binary.match(doc, "sigra-reference")
  assert phx < sigra

  {fence, _} = :binary.match(doc, "getting-started-sigra-reference-fence")
  {sigra_cb, _} = :binary.match(doc, "Threadline.Integrations.Sigra.actor_ref_from_conn/1")
  assert neutrality < fence
  assert fence < sigra_cb
end
```

**Pattern to replicate — DOC-01 IEx test (suggested shape):**

```elixir
test "getting-started §6 locks IEx-first audited write and demo-corr handoff (DOC-01)" do
  doc = read_rel!(@guide_path)

  assert String.contains?(doc, "### Run your first audited write in IEx")
  assert String.contains?(doc, "### HTTP requests and host auth")
  refute String.contains?(doc, "### Authenticate before the audited API call")

  {s6, _} = :binary.match(doc, "## 6.")
  {s8, _} = :binary.match(doc, "## 8.")
  section = :binary.part(doc, s6, s8 - s6)

  assert :binary.match(section, "demo-corr") != :nomatch
  assert :binary.match(section, "audit_transaction_id") != :nomatch
  refute :binary.match(section, "_threadline_phoenix_key") != :nomatch
end
```

---

### 3.3 `guides/operator-surface.md` + contract — `:schemas` (DOC-03)

**Role:** Mount completeness SSOT; row-history reification before operators hit error panel.

**Current gap — mount without `:schemas`:**

```46:50:guides/operator-surface.md
    threadline_operator_surface "/",
      actor_fn: &MyApp.Audit.current_actor/1,
      authorize_fn: &MyApp.Audit.authorize_operator/1,
      repo: MyApp.Repo
```

**Code truth — option on mount `on_mount`:**

```12:20:lib/threadline/operator_surface/auth.ex
      repo = Keyword.get(opts, :repo)
      schemas = Keyword.get(opts, :schemas, %{})

      socket =
        socket
        |> maybe_assign_session_user(session)
        |> maybe_assign_session_actor(session)
        |> Phoenix.Component.assign(:threadline_repo, repo)
        |> Phoenix.Component.assign(:threadline_schemas, schemas)
```

**Failure UX exact copy (D-12):**

```36:41:lib/threadline/operator_surface/live/row_history_component.ex
        {:ok,
         assign(
           socket,
           :error,
           "Table '#{assigns.table}' is not mapped to an Ecto schema. Configure :schemas in the auth plug."
         )}
```

**Actual drill-down route (document shorthand vs slide-over):**

```106:106:lib/threadline/operator_surface/router.ex
            live("/transactions/:id/history/:table/:record_id", TransactionLive, :history)
```

**Closest analog — mount literal locks in contract:**

```32:41:test/threadline/operator_surface_doc_contract_test.exs
  test "operator surface guide locks the canonical admin and support recipes" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(guide, "pipe_through [:browser, :admin_auth]")
    assert String.contains?(guide, "support-read-only variation")
    assert String.contains?(guide, "export_authorize_fn")
    assert String.contains?(guide, "organization_id")
    refute String.contains?(guide, "support_roles =")
    refute String.contains?(guide, "permissions_dsl")
  end
```

**Pattern to replicate (prose):** Add to both admin and support mount blocks:

```elixir
schemas: %{"posts" => MyApp.Post, "users" => MyApp.Accounts.User}
```

New `#### Row history reification (:schemas)` under `### Row History / As-of Sub-view` (~line 172).

**Pattern to replicate (contract — extend same file):**

```elixir
test "operator surface guide documents :schemas for row history reification (DOC-03)" do
  guide = File.read!("guides/operator-surface.md")

  assert String.contains?(guide, "schemas:")
  assert String.contains?(guide, "#### Row history reification (:schemas)")
  assert String.contains?(guide, "Configure :schemas in the auth plug")
  assert String.contains?(guide, "table_name")
end
```

**getting-started §9 one-liner (D-13):** Single sentence + link to operator-surface reification anchor — no map duplicate in §9 mount block (~lines 256–274).

---

### 3.4 `guides/domain-reference.md` — evidence write boundary (DOC-04)

**Role:** Canonical host-write SSOT before proof contract.

**Current gap — jumps Export → Evidence proof contract:**

```75:80:guides/domain-reference.md
## Evidence proof contract (Phase 97)

`mix threadline.evidence.show` is the canonical no-Phoenix viewer for
Threadline-owned evidence records. It is a viewer, not a compliance gate, and
```

**Code truth — six host `record_*` entrypoints:**

```22:58:lib/threadline/evidence.ex
  def record_redaction_policy(subject_ref, attrs, opts \\ []) do
    record_subject("redaction_policy", subject_ref, attrs, opts)
  end
  ...
  def record_support_scope_posture(subject_ref, attrs, opts \\ []) do
    record_subject("support_scope_posture", subject_ref, attrs, opts)
  end
```

**Closest analog — Phase 122 scoped section extraction:**

```117:129:test/threadline/upgrade_path_doc_contract_test.exs
  test "upgrade-path guide locks 0.5.x to 0.6.x minor upgrade bullet" do
    guide = File.read!("guides/upgrade-path.md")

    {idx_minor, _} = :binary.match(guide, "## Upgrade by Threadline minor")
    {idx_phoenix, _} = :binary.match(guide, "## What breaks when Phoenix")
    scope = {idx_minor, idx_phoenix - idx_minor}
    ...
```

**Pattern to replicate (prose):** Insert before `## Evidence proof contract`:

```markdown
## Evidence write boundary (host-written)

<!-- EVIDENCE-HOST-WRITE-BOUNDARY -->

Host apps write attestations via `Threadline.Evidence` `record_*` ...
`Threadline.Retention`, `Threadline.Health`, and export paths do not auto-populate evidence rows.
...
```

**Pattern to replicate (contract — in `how_threadline_works_doc_contract_test.exs` or dedicated test in same module):**

```elixir
test "domain-reference locks evidence host-write boundary before proof contract (DOC-04)" do
  guide = File.read!("guides/domain-reference.md")

  assert String.contains?(guide, "EVIDENCE-HOST-WRITE-BOUNDARY")
  assert String.contains?(guide, "## Evidence write boundary (host-written)")

  {start, _} = :binary.match(guide, "EVIDENCE-HOST-WRITE-BOUNDARY")
  {proof, _} = :binary.match(guide, "## Evidence proof contract")
  section = :binary.part(guide, start, proof - start)

  assert :binary.match(section, "does not auto-populate") != :nomatch
  assert :binary.match(section, "record_redaction_policy") != :nomatch
  assert :binary.match(section, "threadline_retention_runs") != :nomatch
end
```

---

### 3.5 `guides/how-threadline-works.md` + contract — mental model (DOC-04)

**Role:** Architecture map; evidence paragraph must match host-write API.

**Stale copy to replace:**

```31:33:guides/how-threadline-works.md
The evidence plane stays just as narrow. Threadline may persist evidence about
its own governance surfaces such as redaction posture, trigger coverage,
retention runs, export delivery, and support-scope posture.
```

**Closest analog — scoped write-side ordering in contract:**

```72:87:test/threadline/how_threadline_works_doc_contract_test.exs
  test "mental model guide locks recommended audited write path (NARR-03)" do
    doc = File.read!(@guide_path)

    assert String.contains?(doc, "Threadline.Audit.transaction/3")
    ...

    {idx_write, _} = :binary.match(doc, "### Write-side")
    write_len = byte_size(doc) - idx_write
    scope = {idx_write, write_len}

    {idx_tx, _} = :binary.match(doc, "Threadline.Audit.transaction/3", scope: scope)
    {idx_ra, _} = :binary.match(doc, "Threadline.record_action/2", scope: scope)
    assert idx_tx < idx_ra
  end
```

**Pattern to replicate:**

```elixir
test "mental model guide locks host-written evidence framing (DOC-04)" do
  doc = File.read!(@guide_path)

  refute String.contains?(doc, "Threadline may persist evidence")
  assert String.contains?(doc, "domain-reference.md")
  assert String.contains?(doc, "host-written") or String.contains?(doc, "host apps write")
end
```

---

### 3.6 `guides/integration-contracts.md` + contract — lanes + evidence (DOC-04, DOC-05)

**Role:** Seam breadth contract; compact lane enumeration without matrix duplicate.

**Insert point — after intro seam list, before Request path:**

```7:18:guides/integration-contracts.md
- `Threadline.Plug` owns request-path capture context.
...
These are the existing supported seams.

## Request path via `Threadline.Plug`
```

**Stale evidence copy (DOC-04 touch):**

```151:154:guides/integration-contracts.md
That same boundary applies to the evidence plane. Threadline may persist
evidence about its own governance and support-scope posture, but it does not
introduce a Threadline-owned RBAC system, tenancy DSL, approval workflow,
```

**Closest analog — Phase 122 CHANGELOG four-lane minimal enumeration (no matrix):**

```38:38:CHANGELOG.md
- See `guides/upgrade-path.md` for lane matrix (`capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, `sigra-reference`) and surface deprecation policy.
```

**Closest analog — upgrade-path matrix (link target only; do not duplicate):**

```101:107:test/threadline/upgrade_path_doc_contract_test.exs
  test "upgrade-path guide locks the four named lanes and their proof anchors" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(guide, "| `capture-only` | `supported` |")
    assert String.contains?(guide, "| `phoenix-surface` | `supported` |")
    assert String.contains?(guide, "| `phx-gen-auth-reference` | `reference` |")
    assert String.contains?(guide, "| `sigra-reference` | `reference` |")
```

**Existing integration-contracts architecture test (extend file, new test name):**

```5:18:test/threadline/integration_contracts_doc_contract_test.exs
  test "integration-contracts guide keeps the locked section architecture" do
    guide = File.read!("guides/integration-contracts.md")

    assert String.contains?(guide, "## Request path via `Threadline.Plug`")
    ...
  end
```

**Pattern to replicate — DOC-05 new test:**

```elixir
test "integration-contracts guide locks four-lane vocabulary and upgrade-path cross-link" do
  guide = File.read!("guides/integration-contracts.md")

  assert String.contains?(guide, "## Adoption lanes and integration seams")
  assert String.contains?(guide, "guides/upgrade-path.md")

  lanes = ~w(capture-only phoenix-surface phx-gen-auth-reference sigra-reference)
  indices = Enum.map(lanes, fn lane ->
    {idx, _} = :binary.match(guide, lane)
    idx
  end)
  assert indices == Enum.sort(indices)

  refute String.contains?(guide, "| Lane | Claim type |")
end
```

**D-21 inline touch-ups:** Plug § → `` `capture-only` ``; Integrations § → `` `sigra-reference` ``; operator-surface § → required for `phoenix-surface` + reference lanes.

---

## 4. Patterns to replicate (cross-cutting)

### 4.1 Doc-only phase structure (Phase 122 / 123)

| Pattern | Phase 122/123 source | Phase 124 application |
|---------|---------------------|----------------------|
| **Scoped `:binary.match`** | `upgrade_path_doc_contract_test` section slice | §5 ADOPT-AUTH scope; evidence boundary slice; lane order indices |
| **One artifact per REQ** | `production_checklist_doc_contract_test` (CFG-03) | Dedicated `"getting-started §5 locks auth-neutral ADOPT-AUTH literals (DOC-02)"` — not monolith |
| **Dual-contract** | getting-started brief + checklist depth | getting-started IEx + example README HTTP SSOT |
| **HTML fence markers** | `getting-started-sigra-reference-fence` | Optional `getting-started-sigra-http-staging-fence` in §6 `<details>` |
| **Collapsed `<details>`** | §5 Sigra optional block | §6 all cookie/curl prose inside `<details>` only |
| **Four-lane compact list + link** | CHANGELOG line 38 (Phase 122 D-09) | integration-contracts lane section; refute `\| Lane \| Claim type \|` |
| **Phantom hub refute** | `semver_adopter_doc_contract_test` | Do not create `guides/evidence-plane.md` (D-18) |

### 4.2 Dual-contract layering (DOC-01 / D-03)

```
getting-started-saas.md     → neutral IEx + lane table (canonical IDs)
example README + contract   → _threadline_phoenix_key, curl, bearer disclaimer
phx-gen-auth guide + contract → Plug / current_scope only (no curl)
upgrade-path + contract     → four-lane matrix
```

### 4.3 Verification commands (cite in PLAN.md)

```bash
# 124-01
mix test test/threadline/getting_started_saas_doc_contract_test.exs
mix test test/threadline/example_phoenix_readme_contract_test.exs

# 124-02
mix test test/threadline/operator_surface_doc_contract_test.exs

# 124-03
mix test test/threadline/how_threadline_works_doc_contract_test.exs
mix test test/threadline/integration_contracts_doc_contract_test.exs

# Wave closeout
mix verify.doc_contract
mix ci.all
```

### 4.4 Explicit rejections (do not replicate)

| Pattern | Why rejected |
|---------|--------------|
| Open sigra cookie prose in getting-started §6 | phx-gen-auth adopters must not see `_threadline_phoenix_key` in open walkthrough (D-26) |
| Monolith ADOPT-AUTH + IEx asserts only | Blurs REQ ownership; Phase 123 one-artifact-per-REQ (D-06) |
| Matrix table in integration-contracts | SSOT is `upgrade-path.md` (D-20, D-22) |
| `guides/evidence-plane.md` hub | Phantom hub; semver contract refutes (D-18) |
| Evidence auto-population from retention/health/export | Out of phase scope; contradicts code (D-16) |
| Example app `:schemas` in same PR | Deferred unless zero-scope (D-14) |
| Four lane-branched §6 subsections | upgrade-path owns lane depth (D-01) |
| Co-equal phx-gen-auth curl in getting-started | No proof app; host-specific cookie fiction (D-01) |

### 4.5 Requirement → artifact map

| ID | Primary doc edits | Contract extension |
|----|-------------------|-------------------|
| **DOC-01** | `getting-started-saas.md` §6 | Monolith cleanup + IEx/`demo-corr` test; refute open sigra literals |
| **DOC-02** | §5 verify-only | New dedicated ADOPT-AUTH test + `:binary.match` ordering |
| **DOC-03** | `operator-surface.md`, §9 one-liner | `operator_surface_doc_contract_test.exs` |
| **DOC-04** | `domain-reference.md`, `how-threadline-works.md`, `integration-contracts.md`, operator evidence sentence | `how_threadline_works` + domain-reference scoped asserts |
| **DOC-05** | `integration-contracts.md` lane section + inline labels | New test in `integration_contracts_doc_contract_test.exs` |

---

## PATTERN MAPPING COMPLETE
