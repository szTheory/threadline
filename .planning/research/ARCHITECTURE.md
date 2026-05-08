# Architecture Research: v1.19 Integration Breadth

**Project:** Threadline
**Milestone:** v1.19
**Researched:** 2026-05-07
**Scope:** Integrate broader host/framework patterns into the existing library without forcing a `threadline_web` split
**Confidence:** HIGH

## Executive Summary

v1.19 should stay **additive to the current package shape**. The stable core remains:

- capture and query APIs in `Threadline.*`
- host entrypoints in `Threadline.Plug`, `Threadline.Job`, and `Threadline.Integrations.*`
- optional Phoenix/LiveView operator code under `Threadline.OperatorSurface.*`

The milestone should therefore widen adoption through **new adapters and extension contracts**, not by moving core logic or introducing a second package immediately. The in-tree operator surface is already isolated behind optional deps and `Code.ensure_loaded?/1`; that is the right seam to keep while proving whether a future `threadline_web` extraction is justified.

## Recommended Architecture

### Existing extension points to preserve

| Extension point | Current role | v1.19 implication |
|---|---|---|
| `Threadline.Plug` | HTTP request audit-context extraction | Keep as the primary host HTTP seam. New auth/framework integrations should terminate here via `:actor_fn` and `:context_overrides_fn`, not by teaching core modules about host frameworks. |
| `Threadline.Job` | Background-job actor/context extraction | Mirror any new host adapter story with job-safe equivalents where needed; do not let HTTP-only assumptions leak into job capture. |
| `Threadline.Integrations.*` | Soft-dependency host adapters | Expand this namespace for reusable auth/framework adapters. This is the correct place for breadth work. |
| `Threadline.OperatorSurface.Router` | Optional Phoenix mount macro and auth boundary | Keep operator mounting host-owned. Add adapters around it, not alternate auth ownership inside the surface. |
| Mix tasks (`mix threadline.*`) | Non-web parity for capture-only adopters | Any new operator-facing integration pattern should preserve CLI or docs parity so non-Phoenix adopters do not lose capability. |

### New components to add

| Component | Why it should exist |
|---|---|
| `Threadline.Integrations.<Adapter>` modules | Reusable host adapters belong beside `Threadline.Integrations.Sigra`, with runtime soft-dependency guards and zero core knowledge of the host framework. |
| Shared adapter-behavior docs/contracts | v1.19 needs one documented adapter contract: actor extraction, additive context overrides, error/nil semantics, and optional dep behavior. |
| Extraction-readiness checks for the operator surface | The milestone should formalize when `threadline_web` becomes worth the cost instead of splitting preemptively. |

### Modified components

| Component | Required change |
|---|---|
| `mix.exs` | Keep optional web deps and docs/module-group boundaries clean as more adapters land. If multiple adapters exist, `groups_for_modules` should keep `Integration` (core seams) separate from `Integrations` (host adapters). |
| `README.md` and guides | Add a host-integration matrix and clear routing between Plug-only, job-only, adapter-backed, and optional operator-surface paths. |
| Example app(s) | Extend the existing example coverage to prove the adapter pattern end to end. Prefer extending the canonical example over multiplying examples unless a second host stack is materially different. |
| Contract tests | Add or extend doc-contract and packaging contract tests so new adapters and guides cannot drift from the public story. |

## Packaging Boundaries

### Keep in `threadline`

- `Threadline.Plug`, `Threadline.Job`, `Threadline.Integrations.*`
- operator-surface query composition, auth mount contracts, and LiveView modules
- docs, examples, and tests that prove optional dependency behavior

Reason: these pieces are still part of one adoption story. They share one version line, one release cadence, and one compatibility promise.

### Do not move yet

- `Threadline.OperatorSurface.*` into `threadline_web`
- auth-specific persistence or saved-view models
- framework-specific domain logic inside capture, semantics, retention, export, or query layers

Reason: the current optional-dependency boundary is already doing the job. A split now would create version-matrix work before there is evidence that package independence is needed.

### Extraction-readiness heuristics for future `threadline_web`

Promote extraction only when most of these are true:

| Heuristic | Why it matters |
|---|---|
| 2+ active adapters or host patterns need operator-surface-specific docs/tests | Signals the web surface now has its own compatibility burden. |
| The operator surface begins releasing faster than core capture/query APIs | Indicates separate version cadence pressure. |
| Optional Phoenix deps cause repeated CI, docs, or Hex packaging churn | Shows the current in-tree boundary is becoming expensive. |
| Surface-only bugs/features dominate milestone scope for 2 consecutive milestones | Suggests the web layer has become a product surface of its own. |
| Adopters want the operator surface without the rest of the library release cycle, or vice versa | Strong evidence for package decoupling. |

Do **not** extract based only on code size or aesthetics.

## Adapter Boundary Rules

### Hard rules

- Core audit semantics stay auth-agnostic.
- Adapters may derive `ActorRef` and additive context overrides; they may not redefine capture semantics.
- Optional integrations must use soft-dependency guards and degrade to neutral defaults.
- Operator-surface authorization remains host-supplied via mount pipeline and/or `:authorize_fn`; v1.19 should add reusable patterns around that contract, not replace it.

### Recommended adapter contract

Each adapter should answer four questions consistently:

| Concern | Contract |
|---|---|
| Actor extraction | Return `ActorRef.t() | nil`; never raise on absent host state. |
| Context overrides | Return additive request/job metadata only. Existing explicit request metadata must still win. |
| Optional dependency | Runtime-gated; compile succeeds without the host framework installed. |
| Example wiring | One canonical host example proving Plug path, operator auth path if relevant, and negative-path behavior. |

## Docs and Test Contract Implications

v1.19 needs stronger architectural contracts than new runtime machinery.

| Area | Contract implication |
|---|---|
| Guides | Each adapter/pattern needs one canonical guide, cross-linked from README and operator-surface docs. |
| Example coverage | Example tests should prove the public integration shape, not just internal helpers. |
| Doc contracts | Lock route literals, mount/auth wording, adapter function names, and guide links. |
| Release/package contracts | Keep tests like `release_artifact_contract_test.exs` aligned with any new guides, module groups, and package allowlists. |
| Optional-deps safety | Keep compile-without-optional-deps verification as a release gate for any new breadth work. |

## Sensible Build Order

Order the milestone by dependency risk, not by surface appeal.

1. **Adapter contract and extension-point hardening**
   - Freeze the reusable adapter rules first.
   - This reduces churn before adding concrete adapters or docs.

2. **First new adapter(s) and host wiring examples**
   - Add breadth through `Threadline.Integrations.*`.
   - Prove the pattern in the example app and negative-path tests.

3. **Operator-surface integration patterns**
   - Document and test how adapters compose with `threadline_operator_surface`, `:authorize_fn`, and scoped investigation queries.
   - This should build on the adapter contract, not invent a separate one.

4. **Packaging and extraction-readiness instrumentation**
   - Extend docs/module groups, release/package contracts, and write down the extraction heuristics.
   - Only after the actual integration surface exists can readiness be judged honestly.

5. **Milestone close with extraction decision record**
   - Decide: stay in-tree for now, or open a later `threadline_web` extraction milestone.
   - The expected outcome for v1.19 is likely “stay in-tree, but with explicit promotion criteria.”

## Roadmap Implications

- Treat v1.19 as **modified seams plus small additive modules**, not as a subsystem rewrite.
- New work should cluster around `Threadline.Integrations.*`, docs/examples, and contract tests.
- The highest-risk mistake is letting framework/auth concerns bleed into core capture/query APIs.
- The second highest-risk mistake is extracting `threadline_web` before versioning and maintenance pressure justify it.
