# Domain Pitfalls

**Domain:** Scoped support/operator lane
**Researched:** 2026-05-24

## Critical Pitfalls

Mistakes that would force a rewrite or invalidate the milestone claim.

### Pitfall 1: Overreaching into a Threadline-owned auth model
**What goes wrong:** The milestone starts with mount recipes and ends with built-in roles, support permissions, tenant semantics, or policy config.
**Why it happens:** Support-lane UX naturally invites "just one more" authorization abstraction.
**Consequences:** Threadline stops being host-agnostic, the API surface expands sharply, and adopters still need custom exceptions anyway.
**Prevention:** Keep the contract frozen at `authorize_fn`, optional `export_authorize_fn`, opaque `scope`, and `scope_query_fn`.
**Detection:** New docs or code start naming canonical roles, org shapes, or permissions beyond examples.

### Pitfall 2: Claiming a support-safe lane while some workflows bypass scope
**What goes wrong:** Docs say support can safely use `/audit`, but one subview loads data outside the scoped query path.
**Why it happens:** Major screens get scoped while secondary workflows are treated as detail work.
**Consequences:** Cross-tenant leakage risk and loss of trust in the support-lane claim.
**Prevention:** Audit every screen/subview. Today the known gap is row-history/as-of, which currently calls `Threadline.history/3` and `Threadline.as_of/4` directly.
**Detection:** A surface inventory cannot explain how each route or subview receives the host scope.

### Pitfall 3: Confusing denial semantics across LiveView and HTTP
**What goes wrong:** Support operators see hidden buttons in one place, redirects in another, and raw `403` elsewhere with no clear rationale.
**Why it happens:** LiveView mount denial and HTTP export denial are different mechanisms by design.
**Consequences:** Poor DX, support confusion, and accidental misconfiguration by adopters.
**Prevention:** Document one explicit matrix:
pipeline denial,
mount denial,
out-of-scope entity,
export denial,
unsupported workflow.
**Detection:** Example app, guides, and tests describe different outcomes for the same posture.

## Moderate Pitfalls

### Pitfall 1: Making the example app too specific
**What goes wrong:** The support-lane story becomes "how to do this with Sigra exactly like the example" instead of "how to compose this in a Phoenix host."
**Prevention:** Keep the example as proof, but teach the lane in root guides using generic Phoenix patterns first.

### Pitfall 2: Duplicating policy between `authorize_fn` and `scope_query_fn`
**What goes wrong:** Hosts encode the same support rules twice, once in allow/deny logic and once in each screen's query transform.
**Prevention:** Keep `authorize_fn` about entry permission and scope payload, and keep `scope_query_fn` about row narrowing only.

### Pitfall 3: Same-tree and separate-tree recipes are both documented but not differentiated
**What goes wrong:** Adopters cannot tell when to keep one `/audit` tree versus when to mount `/audit/support`.
**Prevention:** Give each recipe a clear recommendation and tradeoff line.

## Minor Pitfalls

### Pitfall 1: Surprising redirect target on LiveView denial
**What goes wrong:** A denied mount redirects to `/`, which may be reasonable in the example app but odd in some hosts.
**Prevention:** Either document that behavior very clearly or add one narrow mount-level redirect override.

### Pitfall 2: Surface-context drift in `scope_query_fn`
**What goes wrong:** Hosts depend on `surface` atoms that are not fully documented or stable in prose.
**Prevention:** Document the current `surface` values and keep additions explicit in changelog/docs.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Lane claim audit | Treating "supported support lane" as broader than current proof | Write the supported screen list first and keep docs/tests aligned to it |
| Mount recipes | Accidental second auth vocabulary | Prefer one shared `%{assigns: assigns}` authorizer in all first-party recipes |
| Denial UX | Leaking existence through inconsistent states | Standardize not-found versus `403` versus hidden affordance semantics |
| Example app polish | Overfitting to Sigra or one org model | Keep the policy example simple and obviously host-owned |
| Small API affordances | Adding too many knobs | Add only the switches required to keep the support claim honest |

## Sources

- Local repo:
  - `guides/operator-surface.md`
  - `guides/integration-contracts.md`
  - `lib/threadline/operator_surface/auth.ex`
  - `lib/threadline/operator_surface/export_auth_plug.ex`
  - `lib/threadline/operator_surface/live/row_history_component.ex`
  - `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`
  - `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs`
- Official docs:
  - Phoenix LiveView security model: https://hexdocs.pm/phoenix_live_view/security-model.html
  - Plug.Conn: https://hexdocs.pm/plug/Plug.Conn.html
