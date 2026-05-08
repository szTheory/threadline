# Pitfalls Research — v1.19 Integration Breadth

**Domain:** Broadening host/framework integration for an OSS Elixir audit library with an optional in-tree LiveView operator surface.
**Researched:** 2026-05-07
**Confidence:** HIGH

This note is scoped to **new v1.19 risks only**: auth/framework adapters, broader host patterns, and deciding whether `threadline_web` should remain in-tree or split later. It intentionally excludes older capture, retention, and investigation-surface pitfalls unless they become relevant to these integration choices.

## Critical pitfalls

### 1. Auth leakage into core

**What goes wrong:**  
`threadline` core starts encoding host auth assumptions: user structs, session lookups, role checks, or persistent auth concepts such as saved views ownership. The library stops being auth-agnostic and becomes implicitly Phoenix-auth-opinionated.

**Why it happens:**  
Integration work often starts from a real host app, so convenience code gets written in the wrong layer. LiveView mount auth is especially risky because Phoenix expects checks both in the plug pipeline and the LiveView mount path, which tempts library authors to centralize auth in the UI package instead of preserving host-owned boundaries.

**Warning signs:**  
- Core modules outside adapter/web namespaces reference host auth structs, `Plug.Conn`, or role names.
- New public APIs require a current user, session, or authorization schema rather than accepting host callbacks.
- UI feature proposals introduce ownership or sharing concepts that require Threadline to persist auth state.
- `mix compile --no-optional-deps --warnings-as-errors` stops passing cleanly.

**Prevention:**  
- Keep auth at the boundary: `threadline` core accepts callbacks/contracts, adapters translate host auth into those contracts.
- Restrict host-specific code to explicit adapter or operator-surface namespaces.
- Gate every optional integration with compile-without-optional-deps CI.
- Reject any v1.19 feature that needs Threadline-owned auth state; treat it as v1.20+ product expansion, not integration breadth.

**Phase that should own it:**  
Integration contract/spec phase first, then adapter implementation phase.

### 2. Splitting into `threadline_web` at the wrong time

**What goes wrong:**  
The package is split before there is real version pressure or adopter demand, creating packaging churn, duplicated docs, and a more fragile upgrade story. The opposite mistake is also common: leaving the surface in-tree after it is clearly driving a separate compatibility and release cadence.

**Why it happens:**  
Maintainers often split because the architecture "looks cleaner" on paper, not because the support burden justifies it. Conversely, they delay too long because optional deps still technically compile, even while docs, CI, and version support become noisy.

**Warning signs:**  
- Extraction is proposed without evidence from at least a couple of live adopters or repeated support incidents.
- The split rationale is aesthetic ("clean separation") rather than operational.
- In-tree optional web deps begin forcing frequent constraint edits, special-case docs, or matrix failures across Phoenix/LiveView versions.
- The library needs duplicate CHANGELOG, README, or install-path explanations to describe one feature.

**Prevention:**  
- Define extraction criteria before coding: adopter count, support load, CI matrix burden, and release-cadence divergence.
- Until those triggers are met, keep the surface in-tree but maintain clear namespaces and dependency seams so extraction remains cheap.
- Revisit the decision only after real adopter evidence, not during speculative roadmap drafting.

**Phase that should own it:**  
Package-boundary decision phase.

### 3. Version-matrix promises outrun verification

**What goes wrong:**  
Threadline claims broad compatibility across Elixir/OTP, Phoenix, LiveView, and auth adapters, but CI only proves one or two combinations. The result is support debt, regressions on optional deps, and docs that overstate what "supported" means.

**Why it happens:**  
Integration milestones create pressure to advertise breadth. In practice, each new adapter or framework hook multiplies the test matrix, especially when optional dependencies and host-owned router/auth setups are involved.

**Warning signs:**  
- README/guides say "works with Phoenix/LiveView/auth libraries" without naming tested ranges.
- New adapters land with one happy-path example but no lowest/highest supported-version coverage.
- Breakages only appear in downstream apps, not in Threadline CI.
- Compatibility wording uses "supports" where the codebase has only been smoke-tested or inferred.

**Prevention:**  
- Publish a narrow support matrix and use "proven against" wording unless a combo is actually in CI.
- Keep one canonical example app per host pattern; do not imply that one example proves every auth stack.
- Add CI for at least: no-optional-deps compile, lowest supported web stack, highest supported web stack, and adapter-specific smoke coverage.
- Prefer adapter guides over broad compatibility claims when evidence is thin.

**Phase that should own it:**  
Compatibility matrix and verification phase.

### 4. UI scope creeps under the label of "integration breadth"

**What goes wrong:**  
The milestone drifts from reusable host patterns into product features: saved views, sharing, queued exports, retention admin, mutable policy controls, or richer operator workflows. Those features pull auth, persistence, jobs, and governance into a library milestone that was supposed to stay read-only and host-integrable.

**Why it happens:**  
Once a LiveView surface exists, the easiest visible work is more UI. But broader adoption is usually blocked by install friction, auth adapters, and compatibility uncertainty, not by missing operator bells and whistles.

**Warning signs:**  
- Proposed work requires new tables, background jobs, ownership rules, or mutable settings.
- A feature cannot be justified as reusable host integration leverage.
- CLI/API parity disappears because effort shifts into surface-only behavior.
- Requirements start reading like "operator product roadmap" rather than "host integration breadth."

**Prevention:**  
- Apply a hard filter: does this reduce adoption friction across multiple hosts, or is it just more UI?
- Preserve the read-only ceiling for v1.19.
- Require CLI/API parity for any new operator affordance that survives scoping.
- Push anything needing Threadline-owned state or workflow orchestration into a later milestone.

**Phase that should own it:**  
Requirements/scope phase, with re-check during roadmap review.

### 5. Docs and examples imply guarantees the code does not provide

**What goes wrong:**  
Examples look "official" enough that adopters assume unsupported auth stacks, mount patterns, or version combos are blessed. Docs silently drift from the actual compile/test matrix. The worst case is a copy-paste example that is insecure by default or only works on the maintainer's exact stack.

**Why it happens:**  
Examples are persuasive. In integration work, readers generalize from one host app faster than maintainers expect. Phoenix and LiveView security guidance also makes it easy to under-document the need for both pipeline and mount-time checks.

**Warning signs:**  
- Example router/auth wiring is shown without explicit security and scope assumptions.
- Docs say "drop-in" where the real story is "reference pattern, adapt to your host."
- The example app uses an auth setup not clearly labeled as one option among several.
- Doc updates are not coupled to contract tests or compileable examples.

**Prevention:**  
- Label examples precisely: "reference integration," "proven in CI," and "host-owned auth still required."
- Keep doc-contract coverage for route literals, auth wording, and adapter wiring.
- Ensure every example path compiles and exercises the documented optional-deps posture.
- Document unsupported or unverified combinations explicitly; ambiguity becomes support debt.

**Phase that should own it:**  
Docs/examples hardening phase.

## Phase-specific warnings

| Phase topic | Likely pitfall | Mitigation |
|-------------|---------------|------------|
| Integration contract/spec | Auth leakage into core | Freeze callback/adaptor boundaries before implementation; reject core-owned auth state |
| Package-boundary decision | Premature or delayed `threadline_web` split | Define objective extraction triggers and revisit only with adopter evidence |
| Compatibility/verification | Version-matrix pain | Publish narrow tested ranges and back them with CI, not marketing language |
| Requirements/roadmap | UI over-scope | Enforce "integration leverage" test and keep v1.19 read-only |
| Docs/examples | Misleading guarantees | Couple examples to contract tests and state exact assumptions/verified stacks |

## Sources

- Internal context: `.planning/PROJECT.md`, `.planning/MILESTONE-ARC.md`, `.planning/MILESTONES.md`, prior `.planning/research/SUMMARY.md`
- Phoenix LiveView security model: https://hexdocs.pm/phoenix_live_view/security-model.html
- Mix optional dependency guidance: https://hexdocs.pm/mix/Mix.Tasks.Deps.html
- Hex package file/include behavior: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html
