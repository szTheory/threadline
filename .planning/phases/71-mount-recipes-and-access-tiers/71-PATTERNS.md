# Phase 71: Mount Recipes & Access Tiers - Pattern Map

**Mapped:** 2026-05-08
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/operator-surface.md` | guide | mount/auth | itself plus Phase 70 doc refresh patterns | exact |
| `guides/getting-started-saas.md` | guide | onboarding | itself plus Phase 68 first-hour pattern | exact |
| `guides/integration-contracts.md` | guide | auth-boundary | itself plus Phase 69 contract doc pattern | exact |
| `guides/integrations/sigra.md` | guide | reference-lane | itself plus Phase 70 auth-boundary wording | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | code | router mount/auth | current example mount block | exact |
| `examples/threadline_phoenix/README.md` | guide | runnable-proof | current reference-lane README | exact |
| `test/threadline/operator_surface_doc_contract_test.exs` | test | wording-lock | current guide-literal lock style | exact |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | test | wording-lock | current walkthrough contract style | exact |
| `test/threadline/integration_contracts_doc_contract_test.exs` | test | wording-lock | current contract-guide lock style | exact |
| `test/threadline/example_phoenix_readme_contract_test.exs` | test | wording-lock | current example-proof contract style | exact |
| `test/threadline/operator_surface/auth_test.exs` | test | auth contract | current `authorize_fn` result vocabulary tests | exact |
| `test/threadline/operator_surface/export_auth_plug_test.exs` | test | export auth contract | current mirror-fallback and 403 tests | exact |

## Pattern Assignments

### `guides/operator-surface.md`

**Analog:** current mount/auth guide

Use the existing structure that keeps this guide focused on mount, auth, and screens rather than lifecycle policy. Add the admin recipe first, then a support-read-only variation, then a compact parity table. Preserve the current “fail-closed” and export-fallback wording style.

Key anchors:
- current 1-minute mount block
- current `:authorize_fn` callback explanation
- current export transport split wording

### `guides/getting-started-saas.md`

**Analog:** Phase 68 surface-first walkthrough

Add only high-signal Phase 71 recipe material here. Keep the guide canonical and surface-first; name fallback commands inline at the operator steps they answer. Do not let it become a second compatibility matrix.

### `guides/integration-contracts.md`

**Analog:** Phase 69 breadth-contract guide

Extend the existing “operator-surface composition via `authorize_fn` and `export_authorize_fn`” section rather than inventing a new auth model. This is the right home for the shared assigns-shaped callback contract and the `{:ok, scope}` opacity language.

### `guides/integrations/sigra.md`

**Analog:** Phase 70 narrow reference-lane guide

Keep Sigra request-capture-only, but align any `/audit` examples to the new canonical admin/support recipe wording. The file should point to host-owned browser/admin auth rather than imply Sigra secures the surface.

### `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`

**Analog:** current `operator-surface-mount` block

Replace the split callback pattern with one shared assigns-shaped callback if Phase 71 chooses to update runnable proof code. Keep the scope behind `pipe_through [:browser, :admin_auth]`.

Canonical excerpt:

```elixir
scope "/audit" do
  pipe_through [:browser, :admin_auth]

  threadline_operator_surface "/",
    actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    repo: ThreadlinePhoenix.Repo
end
```

### `examples/threadline_phoenix/README.md`

**Analog:** current runnable-proof README

Preserve the pattern where the README proves one narrow reference lane and points back to `guides/getting-started-saas.md` for the canonical narrative. Add admin/support recipe wording and inline parity notes without promoting the example into the main guide.

### Doc-contract tests

**Analogs:** `test/threadline/operator_surface_doc_contract_test.exs`, `test/threadline/getting_started_saas_doc_contract_test.exs`, `test/threadline/integration_contracts_doc_contract_test.exs`, `test/threadline/example_phoenix_readme_contract_test.exs`

Use the existing `String.contains?/2` / `refute String.contains?/2` style. Lock:
- one shared assigns-shaped `authorize_fn` explanation
- `exports: false` support-default wording
- export-boundary warning (`live_session` does not guard HTTP routes)
- parity table literals and command names
- host-owned scope examples such as `%{access: :support_read_only, organization_id: org_id}`

### Auth tests

**Analogs:** `test/threadline/operator_surface/auth_test.exs`, `test/threadline/operator_surface/export_auth_plug_test.exs`

If Phase 71 changes documented callback shape or scoped behavior, extend these tests rather than inventing a new test style. Existing result-vocabulary and mirror-fallback tests are the right seam to lock shared callback semantics.

## Recommended Plan Split

1. Docs and runnable-proof recipe refresh.
2. Scoped visibility behavior or honesty alignment.
3. Contract-test and auth-test proof lock.

## PATTERN MAPPING COMPLETE
