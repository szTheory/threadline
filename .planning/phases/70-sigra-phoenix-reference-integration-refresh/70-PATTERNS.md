# Phase 70: Sigra/Phoenix Reference Integration Refresh - Pattern Map

**Mapped:** 2026-05-07
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/upgrade-path.md` | guide | support-matrix | `guides/upgrade-path.md` plus Phase 68 `68-02-PLAN.md` | exact |
| `guides/integrations/sigra.md` | guide | request-response | `guides/integrations/sigra.md` plus Phase 69 `69-02-PLAN.md` | exact |
| `examples/threadline_phoenix/README.md` | guide | request-response | `examples/threadline_phoenix/README.md` plus Phase 68 `68-01-PLAN.md` | exact |
| `test/threadline/upgrade_path_doc_contract_test.exs` | test | wording-lock | `test/threadline/upgrade_path_doc_contract_test.exs` | exact |
| `test/threadline/integrations/sigra_doc_contract_test.exs` | test | wording-lock | `test/threadline/integrations/sigra_doc_contract_test.exs` | exact |
| `test/threadline/example_phoenix_readme_contract_test.exs` | test | wording-lock | `test/threadline/example_phoenix_readme_contract_test.exs` | exact |
| `README.md` | guide | discovery | `README.md` plus Phase 69 `69-02-PLAN.md` | role-match |

## Pattern Assignments

### `guides/upgrade-path.md` (guide, support-matrix)

**Analog:** `guides/upgrade-path.md`

**Canonical lane/proof structure** ([guides/upgrade-path.md](/Users/jon/projects/threadline/guides/upgrade-path.md:15)):
```md
## How to tell which lane you are on

You are on the `capture-only` lane ...
You are on the `phoenix-surface` lane ...
You are on the `sigra-reference` lane ...
```

**Support vocabulary before versions** ([guides/upgrade-path.md](/Users/jon/projects/threadline/guides/upgrade-path.md:23)):
```md
- `supported` means the lane is documented and backed by current repo proof.
- `reference` means the repo maintains a first-party composition path inside a narrower host story.
- `unclaimed` means the combination may be plausible locally, but this repo does not currently prove it.
```

**Lane-split version honesty pattern** ([guides/upgrade-path.md](/Users/jon/projects/threadline/guides/upgrade-path.md:38)):
```md
Support claims in this table come from current in-repo proof only:

1. declared optional dependency ranges in `mix.exs`
2. current lock resolution in `mix.lock`
3. current CI coverage in `.github/workflows/ci.yml`
4. focused guide, doc-contract, and example-app verification for the named lane
```

**Matrix pattern to preserve, then tighten** ([guides/upgrade-path.md](/Users/jon/projects/threadline/guides/upgrade-path.md:45)):
```md
| Lane | Claim type | Declared support | Current tested resolution | Proof / CI coverage |
| `phoenix-surface` | `supported` | `phoenix ~> 1.7`, ... | Phoenix `1.8.7`, ... | `mix verify.test`, `mix ci.all`, ... |
| `sigra-reference` | `reference` | Example host path uses `{:sigra, "~> 0.2", optional: true}` ... | Example app lock resolves Sigra `0.2.5`, ... | `mix verify.example`, ... |
```

**Caveat wording pattern** ([guides/upgrade-path.md](/Users/jon/projects/threadline/guides/upgrade-path.md:51)):
```md
Threadline does not claim support ... outside these named proofs.
If your lockfile resolves to different versions within the declared ranges ... verify locally unless and until the repo updates its own ... proof.
```

**Planning analogs:** Phase 68 locks this doc as the canonical support guide, with claims derived only from declared deps, lock resolution, and CI ([68-02-PLAN.md](/Users/jon/projects/threadline/.planning/phases/68-lifecycle-ergonomics/68-02-PLAN.md:26)). Phase 69 then reorients the same guide around named lanes first, proof anchors second ([69-02-PLAN.md](/Users/jon/projects/threadline/.planning/phases/69-integration-contracts-and-support-matrix/69-02-PLAN.md:83)).

### `guides/integrations/sigra.md` (guide, request-response)

**Analog:** `guides/integrations/sigra.md`

**Narrow reference-claim opener** ([guides/integrations/sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md:5)):
```md
This guide documents Threadline's current `sigra-reference` lane: a maintained
first-party reference path ...
It is a reference claim, not a blanket support promise ...
```

**Version-pin restraint in install docs** ([guides/integrations/sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md:12)):
```elixir
{:sigra, "~> 0.2", optional: true}
```

**Host-owned / soft-loaded wording** ([guides/integrations/sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md:20)):
```md
This dependency is for hosts; never for the library.
Sigra stays host-owned and soft-loaded.
The root `threadline` library keeps Sigra out of its dependency graph ...
```

**Direct callback pair pattern** ([guides/integrations/sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md:26)):
```elixir
plug Threadline.Plug,
  actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
  context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
```

**Auth-boundary / additive-only wording** ([guides/integrations/sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md:40)):
```md
`actor_fn` decides who acted.
`context_overrides_fn` can add only additive request metadata ...
The Sigra callback is therefore supplemental ...
This remains a direct callback pair, not a second adapter layer ...
```

**Reference semantics, not ecosystem promise** ([guides/integrations/sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md:56)):
```md
These behaviors are the supported reference semantics for the current guide and
example app. They are not a statement that every Sigra-backed Phoenix host or
every future Sigra release is automatically covered by Threadline.
```

**Planning analog:** Phase 69 explicitly says to preserve the direct callback contract and soft-dep posture while narrowing the claim around it ([69-02-PLAN.md](/Users/jon/projects/threadline/.planning/phases/69-integration-contracts-and-support-matrix/69-02-PLAN.md:114)).

### `examples/threadline_phoenix/README.md` (guide, request-response)

**Analog:** `examples/threadline_phoenix/README.md`

**Runnable-contract-first opener** ([examples/threadline_phoenix/README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:3)):
```md
Treat the install, run, test, and reconstruction commands in this document as the runnable example contract.
Mix commands in this document are meant to be run from `examples/threadline_phoenix/`.
```

**Reference-lane disclaimer** ([examples/threadline_phoenix/README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:5)):
```md
This app is the current `sigra-reference` lane ...
It proves a narrow composition story ...
It does not claim that arbitrary Sigra versions, arbitrary auth layouts, or non-Phoenix hosts are supported automatically.
```

**Surface-first but proof-oriented flow** ([examples/threadline_phoenix/README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:93)):
```md
## Audited HTTP path (`POST /api/posts`)
...
## Incident JSON drill-down (`audit_transaction_id` → bundled incident)
...
## Operator Surface
```

**Direct callback + proof wording** ([examples/threadline_phoenix/README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:106)):
```md
both callbacks are wired directly into `Threadline.Plug`
...
That is the narrow first-party reference path: soft-loaded, host-owned, and
proven here rather than generalized into a blanket Sigra compatibility promise.
```

**Lane-split proof-pin wording** ([examples/threadline_phoenix/README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:129)):
```md
For support language, treat this as a `sigra-reference` example layered on top
of the root library's broader `phoenix-surface` lane.
The root library declares optional Phoenix dependency ranges in `mix.exs`;
this example app proves the narrower resolved path it actually ships with Sigra `0.2.5`, Phoenix `1.8.5`, ...
```

**Host-owned `/audit` boundary wording** ([examples/threadline_phoenix/README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:135)):
```elixir
scope "/audit" do
  pipe_through [:browser, :admin_auth]

  threadline_operator_surface "/",
    actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    repo: ThreadlinePhoenix.Repo
end
```

**Follow-up auth explanation** ([examples/threadline_phoenix/README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:150)):
```md
`pipeline :admin_auth` requires an authenticated administrative user ...
your app owns browser auth first, then Threadline runs inside that boundary.
```

**Planning analogs:** Phase 68 locks the “one obvious path” doc hierarchy: canonical guide owns narrative, README stays short, example README stays runnable-contract-first ([68-01-PLAN.md](/Users/jon/projects/threadline/.planning/phases/68-lifecycle-ergonomics/68-01-PLAN.md:27)). Phase 70 should reuse that shape rather than promoting the example README into the primary guide.

### `test/threadline/upgrade_path_doc_contract_test.exs` (test, wording-lock)

**Analog:** `test/threadline/upgrade_path_doc_contract_test.exs`

**Section-heading lock pattern** ([test/threadline/upgrade_path_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/upgrade_path_doc_contract_test.exs:5)):
```elixir
assert String.contains?(guide, "## How to tell which lane you are on")
assert String.contains?(guide, "## Supported compatibility matrix")
assert String.contains?(guide, "## Release checklist for adopters")
```

**Exact matrix-header and lane literal pattern** ([test/threadline/upgrade_path_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/upgrade_path_doc_contract_test.exs:18)):
```elixir
assert String.contains?(guide, "| Lane | Claim type | Declared support | Current tested resolution | Proof / CI coverage |")
assert String.contains?(guide, "You are on the `phoenix-surface` lane")
assert String.contains?(guide, "You are on the `sigra-reference` lane")
```

**Anti-overclaim / proof-anchor test style** ([test/threadline/upgrade_path_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/upgrade_path_doc_contract_test.exs:33)):
```elixir
assert String.contains?(guide, "Support claims in this table come from current in-repo proof only:")
assert String.contains?(guide, "declared optional dependency ranges in `mix.exs`")
refute String.contains?(guide, "Phoenix 1.7+")
```

**Version-pin assertions pattern** ([test/threadline/upgrade_path_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/upgrade_path_doc_contract_test.exs:61)):
```elixir
assert String.contains?(guide, "Phoenix `1.8.7`")
assert String.contains?(guide, "Sigra `0.2.5`")
assert String.contains?(guide, "mix verify.example")
```

### `test/threadline/integrations/sigra_doc_contract_test.exs` (test, wording-lock)

**Analog:** `test/threadline/integrations/sigra_doc_contract_test.exs`

**Marker + section-order pattern** ([test/threadline/integrations/sigra_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_doc_contract_test.exs:11)):
```elixir
assert String.contains?(doc, "<!-- SIGRA-03-INTEGRATION-GUIDE -->")
{idx_install, _} = :binary.match(doc, "## Install")
...
assert idx_install < idx_plug
```

**Literal lock pattern for install/callback wording** ([test/threadline/integrations/sigra_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_doc_contract_test.exs:41)):
```elixir
assert String.contains?(doc, "{:sigra, \"~> 0.2\", optional: true}")
assert String.contains?(doc, "for hosts; never for the library")
assert String.contains?(doc, "proven through the current example app, docs, and focused repo verification")
```

**Auth-boundary and non-framework-ownership lock** ([test/threadline/integrations/sigra_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_doc_contract_test.exs:69)):
```elixir
assert String.contains?(doc, "Wire `Threadline.Plug` directly with both callbacks")
assert String.contains?(doc, "direct callback pair, not a second adapter layer")
assert String.contains?(doc, "not a statement that every Sigra-backed Phoenix host or")
```

### `test/threadline/example_phoenix_readme_contract_test.exs` (test, wording-lock)

**Analog:** `test/threadline/example_phoenix_readme_contract_test.exs`

**Reference-lane and direct callback lock** ([test/threadline/example_phoenix_readme_contract_test.exs](/Users/jon/projects/threadline/test/threadline/example_phoenix_readme_contract_test.exs:14)):
```elixir
assert String.contains?(doc, "This app is the current `sigra-reference` lane")
assert String.contains?(doc, "It does not claim that arbitrary Sigra versions")
assert String.contains?(doc, "wired directly into `Threadline.Plug`")
```

**Negative-contract pattern** ([test/threadline/example_phoenix_readme_contract_test.exs](/Users/jon/projects/threadline/test/threadline/example_phoenix_readme_contract_test.exs:31)):
```elixir
refute String.contains?(doc, "delegates to")
refute String.contains?(doc, "ThreadlinePhoenix.AuditActor")
```

**Snippet-extraction / runnable-proof pattern** ([test/threadline/example_phoenix_readme_contract_test.exs](/Users/jon/projects/threadline/test/threadline/example_phoenix_readme_contract_test.exs:48)):
```elixir
assert contains_normalized?(doc, router_mount_block())
...
GettingStartedFixtures.extract!(
  "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex",
  "operator-surface-mount"
)
```

**Version-pin and hierarchy lock** ([test/threadline/example_phoenix_readme_contract_test.exs](/Users/jon/projects/threadline/test/threadline/example_phoenix_readme_contract_test.exs:51)):
```elixir
assert String.contains?(doc, "treat this as a `sigra-reference` example layered on top")
assert String.contains?(doc, "root library's broader `phoenix-surface` lane")
assert String.contains?(doc, "Sigra `0.2.5`, Phoenix `1.8.5`")
assert String.contains?(doc, "without becoming the primary onboarding narrative")
```

### `README.md` (guide, discovery)

**Analog:** `README.md`

**Short discovery-pointer pattern** ([README.md](/Users/jon/projects/threadline/README.md:14)):
```md
- **Checking the named support lanes:** read [guides/upgrade-path.md](guides/upgrade-path.md) ...
- **Using Sigra:** read [guides/integrations/sigra.md](guides/integrations/sigra.md).
```

**Planning analog:** keep root README as the map, not the support-matrix owner or reference-path owner ([68-01-PLAN.md](/Users/jon/projects/threadline/.planning/phases/68-lifecycle-ergonomics/68-01-PLAN.md:29), [69-02-PLAN.md](/Users/jon/projects/threadline/.planning/phases/69-integration-contracts-and-support-matrix/69-02-PLAN.md:101)).

## Shared Patterns

### Canonical Doc Hierarchy
**Sources:** [68-01-PLAN.md](/Users/jon/projects/threadline/.planning/phases/68-lifecycle-ergonomics/68-01-PLAN.md:29), [README.md](/Users/jon/projects/threadline/README.md:95)

Apply to all Phase 70 docs:
```md
- canonical guide owns the narrative
- README stays a discovery map
- example README stays runnable proof, not the primary narrative
```

### Lane-Split Proof Honesty
**Sources:** [guides/upgrade-path.md](/Users/jon/projects/threadline/guides/upgrade-path.md:31), [examples/threadline_phoenix/README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:129)

Apply to `guides/upgrade-path.md`, `guides/integrations/sigra.md`, `examples/threadline_phoenix/README.md`:
```md
- root/library lane keeps declared semver ranges
- example/reference lane names exact tested resolutions
- exact pins do not migrate into generic install snippets
```

### Host-Owned Auth Boundary
**Sources:** [guides/integrations/sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md:40), [examples/threadline_phoenix/README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:150)

Apply to Sigra guide and example README:
```md
Sigra owns request-capture-side auth state.
The host owns browser/admin auth for `/audit`.
Threadline runs inside that boundary with final authorization hooks.
```

### Capture-Only Parity Reminder
**Sources:** [guides/upgrade-path.md](/Users/jon/projects/threadline/guides/upgrade-path.md:55), [68-01-PLAN.md](/Users/jon/projects/threadline/.planning/phases/68-lifecycle-ergonomics/68-01-PLAN.md:33)

Apply anywhere Phase 70 tells the surface-first story:
```md
surface-first stays canonical, but each major operator step should still name the equivalent capture-only Mix/API fallback rather than creating a second equal onboarding path
```

### Doc-Contract Style
**Sources:** [test/threadline/upgrade_path_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/upgrade_path_doc_contract_test.exs:5), [test/threadline/integrations/sigra_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_doc_contract_test.exs:11), [test/threadline/example_phoenix_readme_contract_test.exs](/Users/jon/projects/threadline/test/threadline/example_phoenix_readme_contract_test.exs:31)

Apply to all Phase 70 test edits:
```elixir
assert String.contains?(...)
refute String.contains?(...)
:binary.match(...) for section order
fixture/snippet extraction for shared runnable blocks
```

## No Analog Found

None. Phase 70 is a direct refinement of patterns already established by Phase 68 onboarding docs, Phase 68 support-matrix docs, and Phase 69 support-lane/reference wording.

## Metadata

**Analog search scope:** `guides/`, `examples/threadline_phoenix/`, `test/threadline/`, `.planning/phases/68-*`, `.planning/phases/69-*`, `README.md`  
**Files scanned:** 12 required files + 2 project instruction files + 1 prior pattern map  
**Pattern extraction date:** 2026-05-07
