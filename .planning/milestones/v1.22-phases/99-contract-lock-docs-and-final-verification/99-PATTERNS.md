# Phase 99: Contract Lock, Docs, And Final Verification - Pattern Map

**Mapped:** 2026-05-26
**Files analyzed:** 16
**Analogs found:** 16 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `README.md` | component | transform | `README.md` | exact |
| `guides/how-threadline-works.md` | component | transform | `guides/how-threadline-works.md` | exact |
| `guides/upgrade-path.md` | component | transform | `guides/upgrade-path.md` | exact |
| `guides/integration-contracts.md` | component | transform | `guides/integration-contracts.md` | exact |
| `guides/operator-surface.md` | component | transform | `guides/operator-surface.md` | exact |
| `guides/domain-reference.md` | component | transform | `guides/domain-reference.md` | exact |
| `examples/threadline_phoenix/README.md` | component | transform | `examples/threadline_phoenix/README.md` | exact |
| `CHANGELOG.md` | config | transform | `CHANGELOG.md` | exact |
| `mix.exs` | config | batch | `mix.exs` | exact |
| `test/threadline/readme_doc_contract_test.exs` | test | file-I/O | `test/threadline/readme_doc_contract_test.exs` | exact |
| `test/threadline/how_threadline_works_doc_contract_test.exs` | test | file-I/O | `test/threadline/how_threadline_works_doc_contract_test.exs` | exact |
| `test/threadline/upgrade_path_doc_contract_test.exs` | test | file-I/O | `test/threadline/upgrade_path_doc_contract_test.exs` | exact |
| `test/threadline/integration_contracts_doc_contract_test.exs` | test | file-I/O | `test/threadline/integration_contracts_doc_contract_test.exs` | exact |
| `test/threadline/operator_surface_doc_contract_test.exs` | test | file-I/O | `test/threadline/operator_surface_doc_contract_test.exs` | exact |
| `test/threadline/example_phoenix_readme_contract_test.exs` | test | file-I/O | `test/threadline/example_phoenix_readme_contract_test.exs` | exact |
| `test/threadline/evidence_test.exs` | test | file-I/O | `test/threadline/evidence_test.exs` | exact |
| `test/threadline/evidence/proof_test.exs` | test | file-I/O | `test/threadline/evidence/proof_test.exs` | exact |
| `test/mix/tasks/threadline.evidence_show_test.exs` | test | file-I/O | `test/mix/tasks/threadline.evidence_show_test.exs` | exact |
| `test/threadline/operator_surface/live/evidence_live_test.exs` | test | file-I/O | `test/threadline/operator_surface/live/evidence_live_test.exs` | exact |
| `test/threadline/operator_surface/auth_test.exs` | test | file-I/O | `test/threadline/operator_surface/auth_test.exs` | exact |
| `.planning/phases/99-contract-lock-docs-and-final-verification/99-VALIDATION.md` | test | batch | `.planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md` | exact |
| `.planning/phases/99-contract-lock-docs-and-final-verification/99-VERIFICATION.md` | test | batch | `.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md` | exact |

## Pattern Assignments

### `README.md` (component, transform)

**Analog:** `README.md`

**Front-door map pattern** (`README.md:14-22`):
```md
## Start here

- **Understanding the system:** read [guides/how-threadline-works.md](guides/how-threadline-works.md) ...
- **Understanding the integration seams:** read [guides/integration-contracts.md](guides/integration-contracts.md).
- **Checking the named support lanes:** read [guides/upgrade-path.md](guides/upgrade-path.md) ...
```

**Short capability-strip pattern** (`README.md:103-143`):
```md
## Operator Surface

Threadline provides an optional, drop-in LiveView UI ...
...
For the full first-hour mounted walkthrough, read
[guides/getting-started-saas.md](guides/getting-started-saas.md).
...
For the current support claims, stay with
[guides/upgrade-path.md](guides/upgrade-path.md) rather than inferring broader
compatibility from the README.
```

**Use for Phase 99:** add the evidence-plane strip as a short front-door thesis plus links outward; do not turn README into the canonical support/evidence spec.

---

### `guides/how-threadline-works.md` (component, transform)

**Analog:** `guides/how-threadline-works.md`

**Canonical non-goals block pattern** (`guides/how-threadline-works.md:17-34`):
```md
Threadline is:

- a library you embed into your app
...
Threadline is not:

- event sourcing
- a remote SaaS
- an auth framework
- a write-capable admin backend

The evidence plane stays just as narrow. ...
It does not become a Threadline-owned RBAC platform, tenancy DSL, approval workflow, legal-hold
system, or vendor-reporting suite.
```

**Deeper non-goal echo pattern** (`guides/how-threadline-works.md:150-157`):
```md
## The Line of Diminishing Returns

1. **Becoming a SIEM:** ...
2. **Owning Auth/RBAC:** ...
3. **UI-Based Policy Mutation:** ...
```

**Use for Phase 99:** keep the canonical public non-goals list here or adjacent to this framing; deeper guides should echo only the local boundary relevant to that guide.

---

### `guides/upgrade-path.md` (component, transform)

**Analog:** `guides/upgrade-path.md`

**Lane-ownership pattern** (`guides/upgrade-path.md:15-26`):
```md
You are on the `capture-only` lane ...
You are on the `phoenix-surface` lane ...
You are on the `sigra-reference` lane ...

For v1.21's support-lane wording, read those lane claims together with
`guides/operator-surface.md`: current mounted proof covers ...
```

**Narrow-claim pattern** (`guides/upgrade-path.md:28-39`):
```md
Threadline uses three support words intentionally:

- `supported` ...
- `reference` ...
- `unclaimed` ...

- Anything outside these named lanes is `unclaimed`, even if it may work.
```

**Proof-table pattern** (`guides/upgrade-path.md:41-56`):
```md
| Lane | Claim type | Declared support | Current tested resolution | Proof / CI coverage |
| `phoenix-surface` | `supported` | ... | ... | Root `mix.exs`, root `mix.lock`, `mix verify.test`, `mix ci.all`, root doc-contract coverage ... |
```

**Use for Phase 99:** add `/audit/evidence` as a separately authorized narrow capability under `phoenix-surface`; keep the three named lanes and avoid expanding into a giant lane-by-capability matrix.

---

### `guides/integration-contracts.md` (component, transform)

**Analog:** `guides/integration-contracts.md`

**Host-owned seam pattern** (`guides/integration-contracts.md:102-124`):
```md
## Operator-surface composition via `authorize_fn` and `export_authorize_fn`

The host still owns authentication and authorization semantics. Threadline
standardizes where those hooks plug in; it does not define who the user is,
which roles exist, or how tenancy is modeled.

That same boundary applies to the evidence plane. Threadline may persist
evidence about its own governance and support-scope posture, but it does not
introduce a Threadline-owned RBAC system, tenancy DSL, approval workflow,
legal-hold flow, or vendor-reporting suite.
```

**Scoped-query pattern** (`guides/integration-contracts.md:119-124`):
```md
When a host returns `{:ok, scope}` from `authorize_fn`, keep that scope
host-owned and pair it with `scope_query_fn` if you want mounted reads to narrow
by tenant, organization, or another local concept.
```

**Use for Phase 99:** keep all evidence-plane auth/authorization wording anchored to host-owned callbacks, especially `evidence_authorize_fn`.

---

### `guides/operator-surface.md` (component, transform)

**Analog:** `guides/operator-surface.md`

**Mounted-capability wording pattern** (`guides/operator-surface.md:63-73`):
```md
support-read-only variation:

- Reuse the same `/audit` surface ...
- Return `{:ok, %{access: :support_read_only, organization_id: "org_123"}}` ...
- Use `export_authorize_fn` ...
- Keep coverage and policy surfaces behind their own explicit
  `coverage_authorize_fn` / `policy_authorize_fn` callbacks; when denied,
  Threadline renders an unsupported state and points operators to the matching
  Mix-task fallback.
```

**Unsupported/fallback pattern** (`guides/operator-surface.md:121-125`):
```md
Coverage and policy views are separate admin/global surfaces. Gate them with
`coverage_authorize_fn` and `policy_authorize_fn`; denied sessions get an
explicit `Unsupported View` state plus the CLI fallback ...
```

**Use for Phase 99:** mirror this exact phrasing shape for `/audit/evidence`: mounted capability, fail-closed authorization, explicit unsupported state, and CLI fallback to `mix threadline.evidence.show`.

---

### `guides/domain-reference.md` (component, transform)

**Analog:** `guides/domain-reference.md`

**Verdict-vocabulary pattern** (`guides/domain-reference.md:75-111`):
```md
## Evidence proof contract (Phase 97)

`mix threadline.evidence.show` is the canonical no-Phoenix viewer ...

`claim_assessment` uses one exact verdict vocabulary ...

- `proven` ...
- `inferred_posture` ...
- `unsupported` ...

Operational errors stay outside that verdict vocabulary.
```

**Use for Phase 99:** keep evidence-plane claims tied to this vocabulary; if new public wording says “prove,” it should line up with `proven`, `inferred_posture`, and `unsupported` rather than inventing new claim language.

---

### `examples/threadline_phoenix/README.md` (component, transform)

**Analog:** `examples/threadline_phoenix/README.md`

**Reference-lane disclaimer pattern** (`examples/threadline_phoenix/README.md:5-13`):
```md
This app is the current `sigra-reference` lane ...
It proves a narrow composition story ...
It does not claim that arbitrary Sigra versions, arbitrary auth
layouts, or non-Phoenix hosts are supported automatically.
```

**Mounted-proof wording pattern** (`examples/threadline_phoenix/README.md:136-149`):
```md
For support language, treat this as a `sigra-reference` example layered on top
of the root library's broader `phoenix-surface` lane.
...
admins get the full surface, while support operators get the current scoped
read-only proof ...
```

**Use for Phase 99:** if the example README is touched, preserve “reference lane, not blanket support” wording and keep evidence access narrower than the broad `/audit` mount claim.

---

### `CHANGELOG.md` (config, transform)

**Analog:** `CHANGELOG.md`

**Unreleased bucket pattern** (`CHANGELOG.md:1-5`):
```md
# Changelog

## [Unreleased]
```

**Focused bullet pattern** (`CHANGELOG.md:9-33`):
```md
### Added
- **Upgrade-path guide** ...

### Changed
- **Release metadata** ...
```

**Use for Phase 99:** add concise `Unreleased` bullets only. Do not write a release-style narrative for an untagged phase-closeout branch.

---

### `mix.exs` (config, batch)

**Analog:** `mix.exs`

**Named verification alias pattern** (`mix.exs:74-97`):
```elixir
defp aliases do
  [
    "verify.doc_contract": [
      "test test/threadline/readme_doc_contract_test.exs ..."
    ],
    "verify.example": &verify_example/1,
    "ci.all": [
      "verify.format",
      "verify.credo",
      "compile --warnings-as-errors",
      "verify.compile_no_optional",
      "verify.test",
      "verify.threadline",
      "verify.example",
      "verify.doc_contract"
    ]
  ]
end
```

**Use for Phase 99:** if doc-contract coverage expands, do it by extending the named alias rather than introducing ad-hoc one-off commands in docs or verification artifacts.

---

### `test/threadline/readme_doc_contract_test.exs` (test, file-I/O)

**Analog:** `test/threadline/readme_doc_contract_test.exs`

**Literal-lock pattern** (`test/threadline/readme_doc_contract_test.exs:15-49`):
```elixir
readme = File.read!("README.md")
assert String.contains?(readme, "Threadline.Plug")
...
assert String.contains?(readme, "guides/upgrade-path.md")
```

**Normalized-snippet pattern** (`test/threadline/readme_doc_contract_test.exs:51-69`, `146-166`):
```elixir
assert contains_normalized?(readme, readme_mount_block())

defp contains_normalized?(doc, snippet) do
  String.contains?(normalize(doc), normalize(snippet))
end
```

**Use for Phase 99:** extend by checking for the evidence-plane strip, outward links, and non-goal boundary literals without overfitting formatting whitespace.

---

### `test/threadline/how_threadline_works_doc_contract_test.exs` (test, file-I/O)

**Analog:** `test/threadline/how_threadline_works_doc_contract_test.exs`

**Grouped-heading-and-literal pattern** (`test/threadline/how_threadline_works_doc_contract_test.exs:7-67`):
```elixir
headings = [
  "# How Threadline works",
  "## The short version",
  ...
]

Enum.each(headings, &assert(String.contains?(doc, &1)))
Enum.each([...], &assert(String.contains?(doc, &1)))
```

**Use for Phase 99:** lock the canonical non-goals list here if it becomes the main public “what Threadline is not” home.

---

### `test/threadline/upgrade_path_doc_contract_test.exs` (test, file-I/O)

**Analog:** `test/threadline/upgrade_path_doc_contract_test.exs`

**Section-architecture pattern** (`test/threadline/upgrade_path_doc_contract_test.exs:5-17`):
```elixir
assert String.contains?(guide, "## Who this guide is for")
assert String.contains?(guide, "## How to tell which lane you are on")
assert String.contains?(guide, "## Supported compatibility matrix")
```

**Narrow-claim assertion pattern** (`test/threadline/upgrade_path_doc_contract_test.exs:36-68`):
```elixir
assert String.contains?(guide, "Anything outside these named lanes is `unclaimed`, even if it may work.")
assert String.contains?(guide, "Support claims in this table come from current in-repo proof only:")
refute String.contains?(guide, "Phoenix 1.7+")
```

**Use for Phase 99:** add assertions that `/audit/evidence` stays separately authorized under `phoenix-surface` and does not inherit the broad mounted `/audit` claim.

---

### `test/threadline/integration_contracts_doc_contract_test.exs` (test, file-I/O)

**Analog:** `test/threadline/integration_contracts_doc_contract_test.exs`

**Boundary-literal pattern** (`test/threadline/integration_contracts_doc_contract_test.exs:20-42`):
```elixir
assert String.contains?(guide, "evidence about its own governance and support-scope posture")
assert String.contains?(guide, "Threadline-owned RBAC system")
assert String.contains?(guide, "tenancy DSL")
assert String.contains?(guide, "legal-hold flow")
```

**Callback-contract pattern** (`test/threadline/integration_contracts_doc_contract_test.exs:88-124`):
```elixir
assert String.contains?(guide, "authorize_fn: &MyApp.Audit.authorize_operator/1")
assert String.contains?(guide, "pair it with `scope_query_fn`")
assert String.contains?(guide, "`export_authorize_fn` is optional and should stay an advanced override.")
```

**Use for Phase 99:** extend only if the evidence-plane host-owned boundary needs a new locked literal around `evidence_authorize_fn` or unsupported-state semantics.

---

### `test/threadline/operator_surface_doc_contract_test.exs` (test, file-I/O)

**Analog:** `test/threadline/operator_surface_doc_contract_test.exs`

**Mounted-surface contract pattern** (`test/threadline/operator_surface_doc_contract_test.exs:16-30`, `98-114`):
```elixir
assert String.contains?(guide, "/audit/transactions/:id")
...
assert String.contains?(guide, "fail-closed")
...
assert String.contains?(guide, "## Mounted workflow parity")
assert String.contains?(guide, "mix threadline.health.coverage")
assert String.contains?(guide, "mix threadline.policy.show")
```

**Use for Phase 99:** if `/audit/evidence` wording is added to `guides/operator-surface.md`, lock the mounted route, unsupported-state wording, and CLI fallback here.

---

### `test/threadline/example_phoenix_readme_contract_test.exs` (test, file-I/O)

**Analog:** `test/threadline/example_phoenix_readme_contract_test.exs`

**Reference-app proof pattern** (`test/threadline/example_phoenix_readme_contract_test.exs:14-30`, `50-76`):
```elixir
assert String.contains?(doc, "This app is the current `sigra-reference` lane")
...
assert String.contains?(doc, "secured `/audit` path")
assert String.contains?(doc, "root library's broader `phoenix-surface` lane")
...
assert String.contains?(doc, "HTTP-native `403`")
```

**Use for Phase 99:** if example README wording changes, lock any evidence-plane reference here instead of silently depending on root README tests.

---

### `test/threadline/evidence_test.exs` (test, file-I/O)

**Analog:** `test/threadline/evidence_test.exs`

**API truth-surface pattern** (`test/threadline/evidence_test.exs`):
```elixir
describe "list_overview/2" do
  test "returns stable evidence facts for owned subjects" do
    ...
  end
end
```

**Use for Phase 99:** keep API assertions anchored to shipped owned-fact behavior and parity with the public evidence claim, without widening subject scope.

---

### `test/threadline/evidence/proof_test.exs` (test, file-I/O)

**Analog:** `test/threadline/evidence/proof_test.exs`

**Verdict-vocabulary lock pattern** (`test/threadline/evidence/proof_test.exs`):
```elixir
assert claim["verdict"] == "proven"
assert claim["verdict"] == "inferred_posture"
assert claim["verdict"] == "unsupported"
```

**Use for Phase 99:** if `guides/domain-reference.md` changes, add direct guide-text assertions here or in a companion doc-contract test so public wording and runtime semantics stay aligned.

---

### `test/mix/tasks/threadline.evidence_show_test.exs` (test, file-I/O)

**Analog:** `test/mix/tasks/threadline.evidence_show_test.exs`

**Viewer-parity pattern** (`test/mix/tasks/threadline.evidence_show_test.exs`):
```elixir
assert output =~ "threadline.evidence.show"
assert output =~ "unsupported"
```

**Use for Phase 99:** preserve the viewer-not-gate framing and valid output for unsupported claims.

---

### `test/threadline/operator_surface/live/evidence_live_test.exs` (test, file-I/O)

**Analog:** `test/threadline/operator_surface/live/evidence_live_test.exs`

**Mounted-fallback pattern** (`test/threadline/operator_surface/live/evidence_live_test.exs`):
```elixir
assert html =~ "Unsupported View"
assert html =~ "mix threadline.evidence.show"
```

**Use for Phase 99:** lock mounted evidence wording to the same fail-closed fallback semantics described in the public guides.

---

### `test/threadline/operator_surface/auth_test.exs` (test, file-I/O)

**Analog:** `test/threadline/operator_surface/auth_test.exs`

**Fail-closed auth-seam pattern** (`test/threadline/operator_surface/auth_test.exs`):
```elixir
assert assigns.threadline_evidence_enabled == false
assert assigns.threadline_evidence_enabled == true
```

**Use for Phase 99:** keep explicit `evidence_authorize_fn` deny/allow semantics visible in proof.

---

### `.planning/phases/99-contract-lock-docs-and-final-verification/99-VALIDATION.md` (test, batch)

**Analog:** `.planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md`

**Nyquist contract pattern** (`98-VALIDATION.md`):
```md
## Per-Task Verification Map
...
**Approval:** pending
```

**Use for Phase 99:** update the validation record with the actual rerun bundle, set `nyquist_compliant: true` only after the commands run, and keep it synchronized with `99-VERIFICATION.md`.

---

### `.planning/phases/99-contract-lock-docs-and-final-verification/99-VERIFICATION.md` (test, batch)

**Analog:** `.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md`

**Claim-shaped section pattern** (`89-VERIFICATION.md:19-126`):
```md
## 1. Public Contract Text
**Result:** PASS
...
### Evidence
```bash
mix verify.doc_contract
```

## 4. Named Verification/CI Proof
**Result:** MIXED, but honest
...
```bash
mix ci.all
```
Result: FAIL on formatting checks ...
```

**Honest-failure recording pattern** (`89-VERIFICATION.md:96-126`):
```md
What passed:
...
What failed:
...
This means the named proof surface is wired correctly, but ...
That failure is real and is recorded here instead of being hidden.
```

**Structured evidence-table alternative** (`97-VERIFICATION.md:22-83`):
```md
### Observable Truths
| # | Truth | Status | Evidence |

### Behavioral Spot-Checks
| Behavior | Command | Result | Status |
```

**Use for Phase 99:** copy the phase-89 “claim-shaped rerun bundle” structure first; borrow the phase-97 evidence tables if the final artifact needs a tighter truth-by-truth checklist.

## Shared Patterns

### README As Map
**Source:** `README.md:14-22`, `README.md:96-101`, `README.md:103-143`

Apply to `README.md` and every guide cross-link update.

```md
Keep the root README as the map ...
For the current support claims, stay with
[guides/upgrade-path.md](guides/upgrade-path.md) rather than inferring broader
compatibility from the README.
```

### Canonical Owner Per Claim Family
**Source:** `guides/upgrade-path.md:3-4`, `guides/operator-surface.md:7-10`, `guides/how-threadline-works.md:3`, `guides/domain-reference.md:3`

Apply to all doc files in this phase.

```md
This guide is the canonical support-matrix and lifecycle reference ...
For compatibility, support boundaries, and deprecation policy, see `guides/upgrade-path.md`.
This guide stays focused on mount, auth, and screens.
```

### Host-Owned Boundary Language
**Source:** `guides/integration-contracts.md:110-117`, `guides/how-threadline-works.md:30-34`

Apply to `README.md`, `guides/how-threadline-works.md`, `guides/integration-contracts.md`, `guides/operator-surface.md`, and `examples/threadline_phoenix/README.md`.

```md
Threadline may persist evidence about its own governance and support-scope posture,
but it does not introduce a Threadline-owned RBAC system, tenancy DSL,
approval workflow, legal-hold flow, or vendor-reporting suite.
```

### Unsupported-State + CLI Fallback
**Source:** `guides/operator-surface.md:70-73`, `121-125`; `test/threadline/operator_surface/live/evidence_live_test.exs:105-116`

Apply to any `/audit/evidence` docs/tests.

```md
when denied, Threadline renders an unsupported state and points operators to the matching
Mix-task fallback.
```

```elixir
assert html =~ "Unsupported View"
assert html =~ "mix threadline.evidence.show"
```

### Named Verification Entrypoints
**Source:** `mix.exs:74-97`

Apply to `99-VERIFICATION.md`, `CHANGELOG.md`, and any guide wording that names proof commands.

```elixir
"verify.doc_contract": [...],
"verify.example": &verify_example/1,
"ci.all": [...]
```

### Doc-Contract Lock Style
**Source:** `test/threadline/readme_doc_contract_test.exs:15-69`; `test/threadline/upgrade_path_doc_contract_test.exs:36-68`

Apply to all doc test edits.

```elixir
guide = File.read!("guides/upgrade-path.md")
assert String.contains?(guide, "...")
refute String.contains?(guide, "...")
```

## No Analog Found

None. Every likely Phase 99 write target already has a strong in-repo analog.

## Metadata

**Analog search scope:** `README.md`, `CHANGELOG.md`, `mix.exs`, `guides/`, `examples/threadline_phoenix/`, `test/threadline/`, `test/mix/tasks/`, `.planning/phases/89-*`, `.planning/phases/97-*`

**Files scanned:** 18

**Pattern extraction date:** 2026-05-26
