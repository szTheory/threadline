# Phase 70: Sigra/Phoenix Reference Integration Refresh - Research

**Researched:** 2026-05-07 [VERIFIED: repo context]
**Domain:** Phoenix/Sigra reference-lane documentation, example-app proof, and optional-dependency contract refresh [VERIFIED: .planning/ROADMAP.md]
**Confidence:** HIGH [VERIFIED: repo grep]

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Version posture and proof pins

- **D-105: Use lane-split version wording.** Library/package/install docs should keep declared semver ranges for the reusable `phoenix-surface` lane, while the narrower `sigra-reference` lane names exact tested resolutions from the example app lockfile as proof pins.
- **D-106: Keep exact proof pins out of generic install snippets.** Root library wording should not imply that exact Phoenix or Sigra patch versions are required for every adopter. Exact versions belong in the support matrix and the example-app reference contract.
- **D-107: Distinguish root-lane proof from example-lane proof explicitly.**
  - `phoenix-surface` proof comes from root `mix.exs`, root `mix.lock`, root CI, and root doc-contract coverage.
  - `sigra-reference` proof comes from `examples/threadline_phoenix/`, its lockfile, its README, and `mix verify.example`.
- **D-108: Avoid range-only compatibility language for the Sigra lane.** `{:sigra, "~> 0.2", optional: true}` is a host install shape, not a promise that all Sigra `0.2.x` hosts are covered.

### Reference-path auth story

- **D-109: Keep Sigra as the request-capture adapter only.** The canonical Sigra story remains: a Phoenix host already using Sigra wires `Threadline.Integrations.Sigra` into `Threadline.Plug` for request capture.
- **D-110: Keep the operator surface behind host-owned browser/admin auth.** `/audit` remains a host-mounted operator surface protected first by host pipeline/session policy, then by Threadline's final authorization hooks.
- **D-111: Document the dual-transport auth contract as intentional.**
  - request capture auth is host-owned and adapted through `actor_fn` + `context_overrides_fn`
  - LiveView operator auth is host-owned and checked through `authorize_fn`
  - export HTTP auth shares the same policy by default via the synthetic mirror fallback, with `export_authorize_fn` documented as the explicit advanced override
- **D-112: Do not romanticize Sigra into end-to-end auth.** Phase 70 wording must not imply that Sigra secures the operator surface or that Threadline owns roles, tenancy, or admin policy.

### Narrative shape

- **D-113: Keep one canonical surface-first reference narrative.** The main reference-path story should walk the adopter through Sigra-backed request capture, one audited request, mounting `/audit`, and verifying the same incident through the operator surface.
- **D-114: Name capture-only parity at each relevant step.** Surface-first does not mean UI-only. Every recommended surface-first operator flow should name the equivalent Mix-task or API/CLI fallback for capture-only adopters.
- **D-115: Preserve the “one obvious path” rule from Phase 68.** Do not present surface-first and capture-first as equal top-level onboarding choices.
- **D-116: Keep the example app as proof, not as the primary narrative owner.** User-facing guidance should stay canonical in guides; `examples/threadline_phoenix/README.md` remains the runnable contract that proves the path.

### Scope of the Sigra reference lane

- **D-117: Keep one maintained narrow Sigra lane.** `sigra-reference` means one first-party reference path for Phoenix hosts already using Sigra, one guide, one example app, and one proved callback pair.
- **D-118: Do not add a variants matrix in Phase 70.** Alternative router/auth/layout combinations may be plausible, but they remain `unclaimed` unless the repo adds proof for them later.
- **D-119: Keep the adapter concrete and small.** `Threadline.Integrations.Sigra` remains a soft-loaded reference adapter around the current Plug callback pair; Phase 70 should not turn it into a mini-framework or broader host-integration program.
- **D-120: Favor credibility over breadth theater.** If wording could be read as “generic Sigra compatibility,” tighten it until it clearly means “current first-party reference path only.”

### Downstream decision policy

- **D-121: Bias toward cohesive researched defaults over repeated user arbitration.** For this phase, downstream agents should treat the recommendations above as locked unless they uncover a direct contradiction in repo proof.
- **D-122: Interactive escalation should stay reserved for high-impact exceptions.** Only reopen decisions if the planner/researcher finds a conflict touching semver support claims, security model, breaking public API, or a real scope cut.

### Claude's Discretion

- Exact section and table wording used in `guides/upgrade-path.md`, `guides/integrations/sigra.md`, and `examples/threadline_phoenix/README.md`, as long as the lane boundaries above stay explicit.
- Exact placement of fallback-path reminders in guides and example docs, as long as surface-first remains the canonical flow.
- Exact doc-contract test file changes needed to lock proof-pin wording, lane language, and auth-boundary literals.

### Deferred Ideas (OUT OF SCOPE)

- Additional Sigra/Phoenix router/auth/layout variants documented as first-party paths — defer until repo proof exists for them.
- A second first-party integration or non-Phoenix reference lane — separate future breadth work if justified.
- Expanding `Threadline.Integrations.Sigra` into telemetry hooks, richer host semantics, or a larger adapter abstraction — out of scope for Phase 70.
- Any wording that upgrades `reference` into `supported` without new proof.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INTEG-02 | At least one first-party breadth path ships as a reusable `Threadline.Integrations.*` reference integration that materially reduces host glue while keeping the host framework as a soft dependency. [VERIFIED: .planning/REQUIREMENTS.md] | Keep `Threadline.Integrations.Sigra` as the soft-loaded callback pair, refresh its docs, and protect the no-hard-dep contract with `mix verify.compile_no_optional` plus guide/test anchors. [VERIFIED: lib/threadline/integrations/sigra.ex] |
| COMPAT-03 | Example-app and guide dependency pins, install steps, and compatibility wording are refreshed to the currently supported Phoenix/Sigra lines with explicit caveats where support differs by host stack. [VERIFIED: .planning/REQUIREMENTS.md] | Split semver-range wording from exact proof pins across root docs, `guides/upgrade-path.md`, and the example README using root `mix.exs`/`mix.lock` for `phoenix-surface` and example `mix.exs`/`mix.lock` for `sigra-reference`. [VERIFIED: mix.exs] |
| ADOPT-09 | The canonical reference path is proven end to end in docs and the example app, and every recommended surface-first workflow names the equivalent Mix-task or CLI fallback for capture-only adopters. [VERIFIED: .planning/REQUIREMENTS.md] | Align `guides/getting-started-saas.md`, `guides/integrations/sigra.md`, `guides/operator-surface.md`, and `examples/threadline_phoenix/README.md` around one surface-first story with explicit `mix threadline.incident`, `mix threadline.health.coverage`, and `mix threadline.policy.show` parity reminders. [VERIFIED: guides/operator-surface.md] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Keep the architecture boundaries explicit: capture layer owns trigger-backed persistence, semantics owns action context, and exploration/operations owns timelines, diffs, health, exports, retention, and redaction. [CITED: CLAUDE.md]
- Do not conflate actions with changes, requests with transactions, or actors with users; keep Threadline domain language precise in docs and examples. [CITED: CLAUDE.md]
- Preserve the optional Phoenix/LiveView posture and do not turn framework integrations into hard dependencies. [CITED: CLAUDE.md]
- Prefer canonical verification entrypoints in docs and planning: `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all`. [CITED: CLAUDE.md]
- Keep support/documentation claims aligned through doc-contract tests rather than prose-only promises. [CITED: CLAUDE.md]

## Summary

Phase 70 is a documentation-and-proof refresh over an already-correct code seam, not a new integration build. `Threadline.Integrations.Sigra` already matches the locked design: it is a soft-loaded adapter around the `Threadline.Plug` callback pair, it returns neutral defaults when Sigra is absent, and the root library remains free of a `:sigra` dependency. The planner should therefore center the phase on wording, proof anchors, and example contract alignment rather than code expansion. [VERIFIED: lib/threadline/integrations/sigra.ex] [VERIFIED: test/threadline/integrations/sigra_doc_contract_test.exs] [VERIFIED: mix.exs]

The main repo already has the lane split Phase 70 wants, but a few adoption-facing docs still blur package and proof posture. Root docs still teach `{:threadline, "~> 0.3"}` or `{:threadline, "~> 0.3.0"}` even though the library version is `0.4.0`, while the supported-lane matrix and example README already carry the exact tested proof pins for `sigra-reference`. The highest-value plan is therefore to reconcile root install/package wording, keep exact Phoenix/Sigra pins only in the support matrix and example proof path, and extend doc-contract coverage around any refreshed literals. [VERIFIED: README.md] [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: mix.exs] [VERIFIED: guides/upgrade-path.md] [VERIFIED: examples/threadline_phoenix/README.md]

The planner should also treat auth-boundary wording as first-class scope. The example router, operator-surface guides, and auth tests all prove that Sigra belongs only to request capture, while `/audit` remains protected by host browser/admin auth plus Threadline's fail-closed `authorize_fn` and export mirror behavior. Any Phase 70 doc change that drifts toward "Sigra secures the surface" or skips capture-only parity reminders will contradict the repo's locked contract. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] [VERIFIED: guides/operator-surface.md] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] [VERIFIED: test/threadline/operator_surface/auth_test.exs] [VERIFIED: test/threadline/operator_surface/export_auth_plug_test.exs]

**Primary recommendation:** Ship Phase 70 as three doc slices plus one proof slice: refresh root package wording, tighten Sigra guide/auth-boundary language, realign the example README around the single surface-first narrative with parity reminders, then update focused doc-contract tests and run `mix verify.compile_no_optional`, `mix verify.example`, the focused contract suite, and `mix ci.all`. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]

## User Constraints

- No second reference lane, no broadening of support claims, and no hard `:sigra` dependency. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]
- Keep `phoenix-surface` semver ranges in generic docs and keep `sigra-reference` exact proof pins in the support matrix and example proof docs. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]
- Keep the narrative surface-first, but name capture-only parity at each relevant operator step. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]
- Keep Sigra limited to request capture; host auth still owns `/audit` and export access. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Sigra-backed request capture reference path | API / Backend [ASSUMED] | Browser / Client [ASSUMED] | The actual integration seam is `Threadline.Plug` plus `Threadline.Integrations.Sigra`, both driven by Phoenix request processing before any UI mount occurs. [VERIFIED: lib/threadline/integrations/sigra.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] |
| Operator-surface auth boundary wording | Frontend Server (SSR) [ASSUMED] | API / Backend [ASSUMED] | `/audit` is mounted in the Phoenix router and authorized through `authorize_fn` / `export_authorize_fn` contracts that run server-side before LiveView/export delivery. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] |
| Support-lane and version-proof documentation | Frontend Server (SSR) [ASSUMED] | — | The deliverable is doc/package/example wording tied to repo proof, not runtime behavior. [VERIFIED: guides/upgrade-path.md] [VERIFIED: README.md] |
| Example-app proof lane | API / Backend [ASSUMED] | Frontend Server (SSR) [ASSUMED] | The example proves both the request path and mounted `/audit` story through the nested Phoenix app and `mix verify.example`. [VERIFIED: examples/threadline_phoenix/README.md] [VERIFIED: mix.exs] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `threadline` | `0.4.0` [VERIFIED: mix.exs] | Root package/docs version that generic install wording must reflect. [VERIFIED: mix.exs] | This is the published library version and the source of truth for package wording. [VERIFIED: mix.exs] |
| `phoenix` (`phoenix-surface` lane) | declared `~> 1.7`, tested `1.8.7` [VERIFIED: mix.exs] [VERIFIED: mix.lock] | Optional operator-surface host dependency in the root lane. [VERIFIED: mix.exs] | The support matrix and doc-contract tests already treat declared ranges plus root lock resolution as the proof source for `phoenix-surface`. [VERIFIED: guides/upgrade-path.md] [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] |
| `phoenix_live_view` (`phoenix-surface` lane) | declared `~> 1.0`, tested `1.1.30` [VERIFIED: mix.exs] [VERIFIED: mix.lock] | Optional operator-surface runtime in the root lane. [VERIFIED: mix.exs] | The repo already names this as part of the supported optional Phoenix surface line. [VERIFIED: guides/upgrade-path.md] |
| `sigra` (`sigra-reference` lane) | declared `~> 0.2` in example host, tested `0.2.5` [VERIFIED: examples/threadline_phoenix/mix.exs] [VERIFIED: examples/threadline_phoenix/mix.lock] | Host-owned request-auth source adapted into `Threadline.Plug`. [VERIFIED: guides/integrations/sigra.md] | This is the one maintained first-party reference integration and must stay soft-loaded. [VERIFIED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md] [VERIFIED: lib/threadline/integrations/sigra.ex] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phoenix_html` | declared `~> 4.0`, tested `4.3.0` in both lanes [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/mix.lock] | Required optional surface dependency for mounted `/audit`. [VERIFIED: mix.exs] | Cite in `phoenix-surface` install snippets and lane tables, not as a Sigra-specific requirement. [VERIFIED: guides/operator-surface.md] |
| `phoenix_pubsub` | declared `~> 2.1`, tested `2.2.0` in both lanes [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/mix.lock] | Required optional surface dependency for LiveView/operator-surface behavior. [VERIFIED: mix.exs] | Keep in root surface snippets and support tables. [VERIFIED: guides/upgrade-path.md] |
| ExUnit doc-contract suite | repo-local, no extra package [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] | Locks wording, proof pins, and router/example literals against drift. [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs] | Use whenever Phase 70 changes docs or example proof text. [VERIFIED: test/threadline/integrations/sigra_doc_contract_test.exs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `Threadline.Integrations.Sigra` callback pair [VERIFIED: lib/threadline/integrations/sigra.ex] | New adapter abstraction or second reference lane [ASSUMED] | This would violate the locked narrow-scope contract and add proof burden Phase 70 explicitly rejects. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md] |
| Lane-split docs using semver ranges in root docs and exact proof pins in support/example docs [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md] | Exact versions everywhere [ASSUMED] | Exact pins in generic install snippets would misstate support posture and imply patch-level requirements for all adopters. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md] |

**Installation:**
```bash
mix deps.get
cd examples/threadline_phoenix && mix deps.get
```

**Version verification:** Root package and lane declarations come from `mix.exs`; current tested root resolutions come from `mix.lock`; current tested example-lane resolutions come from `examples/threadline_phoenix/mix.lock`. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/mix.exs] [VERIFIED: examples/threadline_phoenix/mix.lock]

## Architecture Patterns

### System Architecture Diagram

```text
Host request auth (Sigra / host-owned session)
  -> Phoenix router :api pipeline
  -> Threadline.Plug
       -> actor_fn = Threadline.Integrations.Sigra.actor_ref_from_conn/1
       -> context_overrides_fn = audit_context_overrides_from_conn/1
  -> audited write + Threadline.record_action/2
  -> example proof endpoint / API investigation
  -> host browser/admin pipeline
  -> threadline_operator_surface "/audit"
       -> authorize_fn (LiveView)
       -> export_authorize_fn or authorize_fn mirror (HTTP exports)
  -> operator investigates same incident
  -> capture-only parity via Mix tasks / query APIs
```

The core planning point is that Sigra enters only on the request-capture branch, while `/audit` auth is a separate host-owned mount/export boundary. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex]

### Recommended Project Structure
```text
README.md                                      # root package wording and discovery map
guides/
├── getting-started-saas.md                    # canonical surface-first onboarding story
├── upgrade-path.md                            # support lanes, proof matrix, caveats
├── operator-surface.md                        # mount/auth/screens + parity task refs
└── integrations/sigra.md                      # narrow Sigra request-capture guide
examples/threadline_phoenix/
├── README.md                                  # runnable sigra-reference proof contract
├── mix.exs                                    # example declared dependency shape
└── lib/threadline_phoenix_web/router.ex       # canonical request-path + /audit wiring
test/threadline/
├── upgrade_path_doc_contract_test.exs         # lane/proof literal locks
├── integrations/sigra_doc_contract_test.exs  # Sigra guide literal locks
└── example_phoenix_readme_contract_test.exs   # example proof/lane/router locks
```

### Component Responsibilities

| Component | Responsibility | Exact Proof Anchor |
|-----------|----------------|--------------------|
| Root `mix.exs` | Declares the optional `phoenix-surface` dependency ranges and verification aliases. [VERIFIED: mix.exs] | [mix.exs](/Users/jon/projects/threadline/mix.exs:49) |
| Root `mix.lock` | Freezes the currently tested root `phoenix-surface` resolutions named in the support matrix. [VERIFIED: mix.lock] | [mix.lock](/Users/jon/projects/threadline/mix.lock:23) |
| `guides/upgrade-path.md` | Owns the lane matrix and the supported/reference/unclaimed vocabulary. [VERIFIED: guides/upgrade-path.md] | [upgrade-path.md](/Users/jon/projects/threadline/guides/upgrade-path.md:15) |
| `guides/integrations/sigra.md` | Owns the narrow Sigra request-path contract and soft-dep wording. [VERIFIED: guides/integrations/sigra.md] | [sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md:12) |
| `guides/getting-started-saas.md` | Owns the canonical surface-first narrative and parity branch wording. [VERIFIED: guides/getting-started-saas.md] | [getting-started-saas.md](/Users/jon/projects/threadline/guides/getting-started-saas.md:194) |
| Example `mix.exs` and `mix.lock` | Define and prove the narrower `sigra-reference` lane resolutions. [VERIFIED: examples/threadline_phoenix/mix.exs] [VERIFIED: examples/threadline_phoenix/mix.lock] | [examples/threadline_phoenix/mix.exs](/Users/jon/projects/threadline/examples/threadline_phoenix/mix.exs:40) |
| Example router | Proves the direct Sigra callback pair and host-owned `/audit` boundary. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] | [router.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:53) |
| Doc-contract tests | Prevent wording/proof drift after the refresh. [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] [VERIFIED: test/threadline/integrations/sigra_doc_contract_test.exs] [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs] | [upgrade_path_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/upgrade_path_doc_contract_test.exs:18) |

### Pattern 1: Lane-Split Version Contract
**What:** Keep root docs on declared semver ranges and keep exact tested proof pins only in `guides/upgrade-path.md` and the example README. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]
**When to use:** Any doc or package wording that mentions Phoenix/Sigra compatibility or install requirements. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]
**Example:**
```elixir
# Source: /Users/jon/projects/threadline/mix.exs:57
{:phoenix, "~> 1.7", optional: true}
{:phoenix_live_view, "~> 1.0", optional: true}
{:phoenix_html, "~> 4.0", optional: true}
{:phoenix_pubsub, "~> 2.1", optional: true}
```

### Pattern 2: Direct Sigra Callback Pair, Not an Abstraction Layer
**What:** Present `Threadline.Integrations.Sigra` as the reusable direct callback pair around `Threadline.Plug`, not as a new adapter system. [VERIFIED: lib/threadline/integrations/sigra.ex] [VERIFIED: guides/integrations/sigra.md]
**When to use:** Sigra guide text, example-router snippets, and any reference-lane narrative. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]
**Example:**
```elixir
# Source: /Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:57
plug(Threadline.Plug,
  actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
  context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
)
```

### Pattern 3: Surface-First Narrative With Explicit Capture-Only Parity
**What:** Keep `/audit` as the primary adoption story, but attach the relevant Mix-task/query fallback at each operator step. [CITED: .planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md] [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]
**When to use:** `guides/getting-started-saas.md`, the example README, and any root discovery links. [VERIFIED: guides/getting-started-saas.md] [VERIFIED: examples/threadline_phoenix/README.md]
**Example:**
```bash
# Source: /Users/jon/projects/threadline/guides/operator-surface.md:104
mix threadline.incident <transaction_id>
```

### Likely Plan Slices

| Slice | Files | Why This Slice Exists |
|------|-------|------------------------|
| 1. Root package wording refresh | `README.md`, `guides/getting-started-saas.md`, `guides/operator-surface.md` [VERIFIED: repo grep] | Root docs currently still teach `threadline ~> 0.3` / `0.3.0`, which is stale against `@version "0.4.0"`. [VERIFIED: README.md] [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: mix.exs] |
| 2. Lane/proof matrix and Sigra guide tightening | `guides/upgrade-path.md`, `guides/integrations/sigra.md` [VERIFIED: repo grep] | These files already carry the lane vocabulary and proof pins, so they are the right seam for caveat tightening without widening scope. [VERIFIED: guides/upgrade-path.md] [VERIFIED: guides/integrations/sigra.md] |
| 3. Example README narrative refresh | `examples/threadline_phoenix/README.md`, `examples/threadline_phoenix/mix.exs`, `examples/threadline_phoenix/mix.lock`, router snippet extracts [VERIFIED: repo grep] | The example is the runnable proof contract for `sigra-reference` and already names the exact tested resolutions. [VERIFIED: examples/threadline_phoenix/README.md] |
| 4. Proof lock and verification refresh | `test/threadline/upgrade_path_doc_contract_test.exs`, `test/threadline/integrations/sigra_doc_contract_test.exs`, `test/threadline/example_phoenix_readme_contract_test.exs` [VERIFIED: repo grep] | Phase 70 is doc-heavy, so the real gate is contract-test coverage plus `mix verify.example` and `mix verify.compile_no_optional`. [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] [VERIFIED: mix.exs] |

### Anti-Patterns to Avoid
- **Generic Sigra compatibility language:** Do not let `{:sigra, "~> 0.2", optional: true}` read like support for all `0.2.x` host setups. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]
- **Exact pins in generic install snippets:** Do not move example proof pins into root install blocks. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]
- **Teaching Sigra as `/audit` auth:** Do not present Sigra as the surface-security boundary; the host browser/admin pipeline and `authorize_fn` own that contract. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] [VERIFIED: guides/operator-surface.md]
- **Doc-only refresh without proof locks:** Any changed wording should be mirrored in the focused contract tests, or the phase will regress silently. [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] [VERIFIED: test/threadline/integrations/sigra_doc_contract_test.exs] [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sigra integration breadth | A new behavior/protocol or second integration framework [ASSUMED] | The existing `Threadline.Integrations.Sigra` callback pair and guide/example pattern. [VERIFIED: lib/threadline/integrations/sigra.ex] [VERIFIED: guides/integrations/sigra.md] | The current module already proves the soft-dep reference seam and Phase 70 explicitly keeps it concrete and small. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md] |
| Support matrix | A package-by-package compatibility spreadsheet [ASSUMED] | The existing three-lane `capture-only` / `phoenix-surface` / `sigra-reference` matrix in `guides/upgrade-path.md`. [VERIFIED: guides/upgrade-path.md] | The lane model is already locked and supported by tests; widening it adds proof debt immediately. [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] |
| Auth story | Threadline-owned auth/roles wording or a Sigra-secures-everything narrative [ASSUMED] | Host-owned pipeline/session auth plus `authorize_fn` / `export_authorize_fn` wording. [VERIFIED: lib/threadline/operator_surface/router.ex] [VERIFIED: guides/operator-surface.md] | The router macro and tests already fail closed around host-owned auth hooks; changing that story would contradict shipped behavior. [VERIFIED: test/threadline/operator_surface/auth_test.exs] [VERIFIED: test/threadline/operator_surface/export_auth_plug_test.exs] |

**Key insight:** Phase 70 should spend complexity budget on honesty and proof, not new abstractions. The repo already has the reusable seam; the missing work is keeping docs, example pins, and tests synchronized around that seam. [VERIFIED: lib/threadline/integrations/sigra.ex] [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]

## Common Pitfalls

### Pitfall 1: Leaving stale root package snippets in place
**What goes wrong:** Root docs continue to teach `{:threadline, "~> 0.3"}` or `{:threadline, "~> 0.3.0"}` after the library is already `0.4.0`. [VERIFIED: README.md] [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: mix.exs]
**Why it happens:** Package-version wording lives outside the support-matrix docs and was not refreshed when the lane model shipped in Phase 69. [VERIFIED: repo grep]
**How to avoid:** Make one explicit Phase 70 slice for root package wording and tie it back to `mix.exs @version`. [VERIFIED: mix.exs]
**Warning signs:** `rg -n 'threadline, \"~> 0\\.3' README.md guides` still returns matches after the phase. [VERIFIED: repo grep]

### Pitfall 2: Treating example declarations as proof pins
**What goes wrong:** A planner may try to "fix" Phase 70 by pinning exact Phoenix/Sigra versions in generic install instructions or by tightening example declarations instead of documentation boundaries. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]
**Why it happens:** The example app uses broad declarations like `{:phoenix_live_view, "~> 1.0"}` and `{:sigra, "~> 0.2"}` while the README/support docs already name exact tested resolutions from the lockfile. [VERIFIED: examples/threadline_phoenix/mix.exs] [VERIFIED: examples/threadline_phoenix/README.md]
**How to avoid:** Preserve semver declarations in `mix.exs` and update proof-pin wording in `guides/upgrade-path.md` and the example README only. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]
**Warning signs:** New docs say "install Phoenix 1.8.5" or "install Sigra 0.2.5" in root snippets instead of lane tables/example proof sections. [ASSUMED]

### Pitfall 3: Blurring request auth with surface auth
**What goes wrong:** Docs imply that using Sigra on the request path also secures `/audit` or export endpoints. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]
**Why it happens:** The example app shows both the Sigra-backed `:api` pipeline and the mounted `/audit` scope in the same router. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]
**How to avoid:** Repeat the split explicitly: Sigra feeds `Threadline.Plug`; host browser/admin auth plus `authorize_fn` / export mirror guard `/audit`. [VERIFIED: guides/integration-contracts.md] [VERIFIED: guides/operator-surface.md]
**Warning signs:** Updated prose drops `pipeline :admin_auth`, `authorize_fn`, or the "host-owned" wording around the operator surface. [VERIFIED: examples/threadline_phoenix/README.md]

### Pitfall 4: Forgetting capture-only parity while keeping surface-first UX
**What goes wrong:** The docs keep `/audit` as the main story but stop naming the relevant non-surface fallback. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]
**Why it happens:** The parity reminders live across multiple guides rather than one checklist. [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/operator-surface.md]
**How to avoid:** Add parity reminders to the exact steps they correspond to: incident drill-down -> `mix threadline.incident`; coverage -> `mix threadline.health.coverage`; policy drift -> `mix threadline.policy.show`. [VERIFIED: guides/operator-surface.md]
**Warning signs:** A refreshed guide mentions `/audit` and the surface routes but not the equivalent Mix task for the same operator question. [VERIFIED: guides/operator-surface.md]

## Code Examples

Verified patterns from current repo sources:

### Sigra callback pair stays small and soft-loaded
```elixir
// Source: /Users/jon/projects/threadline/lib/threadline/integrations/sigra.ex
def actor_ref_from_conn(conn) do
  if sigra_available?() do
    conn
    |> current_scope()
    |> actor_ref_from_scope()
  else
    nil
  end
end

def audit_context_overrides_from_conn(conn) do
  if header_correlation_id?(conn) do
    %{}
  else
    build_audit_overrides(conn)
  end
end
```

### Example router proves the split between request capture and `/audit` auth
```elixir
// Source: /Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
pipeline :api do
  plug(:accepts, ["json"])

  plug(Threadline.Plug,
    actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
    context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
  )
end

scope "/audit" do
  pipe_through [:browser, :admin_auth]

  threadline_operator_surface "/",
    actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    repo: ThreadlinePhoenix.Repo
end
```

### Export auth parity is intentionally mirrored, not separate by default
```elixir
// Source: /Users/jon/projects/threadline/lib/threadline/operator_surface/export_auth_plug.ex
authorizer =
  case export_authorize_fn do
    fun when is_function(fun, 1) ->
      fn -> fun.(conn) end

    nil ->
      fn ->
        mirror = %{assigns: conn.assigns}
        authorize_fn.(mirror)
      end
  end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Broad or stale package snippets in root docs [VERIFIED: README.md] [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/operator-surface.md] | Lane-split support story with generic ranges in root docs and exact proof pins in lane/example docs. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md] | Phase 69 established the lane model on 2026-05-07. [VERIFIED: .planning/STATE.md] | Phase 70 should finish the migration by removing leftover `0.3` package wording. [VERIFIED: repo grep] |
| Implicit "Sigra example" wording [ASSUMED] | Explicit `sigra-reference` lane wording with supported/reference/unclaimed vocabulary. [VERIFIED: guides/upgrade-path.md] [VERIFIED: guides/integrations/sigra.md] | Phase 69, 2026-05-07. [VERIFIED: .planning/STATE.md] | Phase 70 can tighten caveats without changing the lane model. [VERIFIED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md] |
| Surface docs and example docs carrying parity reminders unevenly [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/operator-surface.md] | One surface-first story with explicit Mix-task/API fallback reminders at each operator step. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md] | Surface-first narrative locked in Phase 68, 2026-05-07. [VERIFIED: .planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md] | Phase 70 should normalize parity reminders across docs rather than invent a second narrative. [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md] |

**Deprecated/outdated:**
- Root install snippets using `threadline ~> 0.3` or `0.3.0` are outdated against `@version "0.4.0"`. [VERIFIED: README.md] [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: mix.exs]
- Any phrasing that lets `sigra-reference` read as generic Sigra support is outdated against the Phase 69 lane contract. [VERIFIED: guides/upgrade-path.md] [CITED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Mapping doc work to "Frontend Server (SSR)" and request capture to "API / Backend" is the most useful tier split for a Phoenix library/documentation phase. | Architectural Responsibility Map | Low — affects planning labels more than implementation. |
| A2 | A new adapter abstraction or a second lane would be the most likely "hand-rolled" alternative a planner might accidentally propose. | Don't Hand-Roll | Low — the locked context already forbids broadening scope. |
| A3 | Example of "old implicit Sigra example wording" predates Phase 69 even though the current repo now uses explicit lane labels. | State of the Art | Low — does not change current implementation guidance. |

## Open Questions (RESOLVED)

1. **Should Phase 70 update only the narrow Phase 69/70 doc set, or also refresh every root install snippet that still says `threadline ~> 0.3`?**
   - What we know: README, `guides/getting-started-saas.md`, and `guides/operator-surface.md` still contain stale `0.3` package snippets while the library version is `0.4.0`. [VERIFIED: README.md] [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: mix.exs]
   - Resolution: Include the stale root snippets in scope. Phase 70 explicitly covers example/docs/package wording, and these files are part of the same surface-first adoption path that the phase is refreshing. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-01-PLAN.md]
   - Planning impact: `70-01-PLAN.md` owns the generic/root doc cleanup so exact proof pins stay delegated to `guides/upgrade-path.md` and the example README instead of remaining spread across stale package snippets. [VERIFIED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-01-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | All verification commands and lockfile-aware doc refresh workflow [VERIFIED: mix.exs] | ✓ [VERIFIED: shell command] | `Mix 1.19.5` [VERIFIED: shell command] | — |
| Elixir/Erlang | Repo compile/test context and package-version reality [VERIFIED: mix.exs] | ✓ [VERIFIED: shell command] | Erlang/OTP `28`, Elixir/Mix toolchain `1.19.5` via `mix --version` [VERIFIED: shell command] | — |
| PostgreSQL CLI (`psql`, `pg_isready`) | Example-app verification and setup commands in docs [VERIFIED: examples/threadline_phoenix/README.md] | ✓ [VERIFIED: shell command] | `14.17` [VERIFIED: shell command] | — |
| Docker | Optional local Postgres via `docker compose up -d postgres` in the example README [VERIFIED: examples/threadline_phoenix/README.md] | ✓ [VERIFIED: shell command] | `29.4.1` [VERIFIED: shell command] | Use an already-running local Postgres instance if Docker is unavailable. [CITED: examples/threadline_phoenix/README.md] |

**Missing dependencies with no fallback:**
- None found. [VERIFIED: shell command]

**Missing dependencies with fallback:**
- None found on this machine. [VERIFIED: shell command]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix aliases and focused doc-contract tests. [VERIFIED: mix.exs] |
| Config file | none — test discovery is driven by Mix/ExUnit conventions and aliases in `mix.exs`. [VERIFIED: mix.exs] |
| Quick run command | `mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-VERIFICATION.md] |
| Full suite command | `mix ci.all` [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INTEG-02 | `Threadline.Integrations.Sigra` stays the soft-loaded first-party reference adapter and docs keep the direct callback-pair contract. [VERIFIED: lib/threadline/integrations/sigra.ex] | doc-contract + compile-no-optional | `mix test test/threadline/integrations/sigra_doc_contract_test.exs --max-failures 1 && mix verify.compile_no_optional` | ✅ [VERIFIED: test/threadline/integrations/sigra_doc_contract_test.exs] |
| COMPAT-03 | Lane matrix and proof pins stay aligned to root/example declared ranges and lockfiles. [VERIFIED: guides/upgrade-path.md] | doc-contract | `mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` | ✅ [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] |
| ADOPT-09 | Surface-first reference path remains end-to-end and names capture-only parity. [VERIFIED: guides/getting-started-saas.md] [VERIFIED: examples/threadline_phoenix/README.md] | example integration + focused doc-contract | `mix verify.example && mix test test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1` | ✅ [VERIFIED: mix.exs] |

### Sampling Rate
- **Per task commit:** Run the focused contract suite for the file family being edited. [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] [VERIFIED: test/threadline/integrations/sigra_doc_contract_test.exs] [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]
- **Per wave merge:** Run `mix verify.compile_no_optional` and `mix verify.example`. [VERIFIED: mix.exs] [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-VERIFICATION.md]
- **Phase gate:** Run the focused Phase 69/70 contract suite plus `mix ci.all`. [VERIFIED: .planning/phases/69-integration-contracts-and-support-matrix/69-VERIFICATION.md] [VERIFIED: mix.exs]

### Wave 0 Gaps

None — the repo already has the focused doc-contract files and the example verification alias needed for this phase. [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] [VERIFIED: test/threadline/integrations/sigra_doc_contract_test.exs] [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs] [VERIFIED: mix.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: guides/operator-surface.md] | Host-owned authenticated pipeline before `/audit`; docs must keep that explicit. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] |
| V3 Session Management | yes [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] | Host browser/session pipeline plus LiveView mount auth. [VERIFIED: lib/threadline/operator_surface/auth.ex] |
| V4 Access Control | yes [VERIFIED: lib/threadline/operator_surface/router.ex] | `authorize_fn`, optional `export_authorize_fn`, and the fail-closed mount contract. [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] |
| V5 Input Validation | yes [VERIFIED: guides/integration-contracts.md] | `Threadline.Plug` additive-only override validation and immediate `ArgumentError` on invalid shapes. [VERIFIED: guides/integration-contracts.md] |
| V6 Cryptography | no [VERIFIED: repo grep] | Phase 70 does not add or change crypto behavior. [VERIFIED: repo grep] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Sigra implied as `/audit` auth | Spoofing | Keep docs explicit that host browser/admin auth plus `authorize_fn` own surface access. [VERIFIED: guides/operator-surface.md] [VERIFIED: examples/threadline_phoenix/README.md] |
| Unsupported-version overclaim | Tampering [ASSUMED] | Keep support statements tied to declared ranges, current lockfiles, and named verification entrypoints only. [VERIFIED: guides/upgrade-path.md] |
| Export auth divergence from LiveView auth | Elevation of privilege | Preserve the documented `export_authorize_fn` override and mirror fallback behavior. [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex] [VERIFIED: test/threadline/operator_surface/export_auth_plug_test.exs] |

## Sources

### Primary (HIGH confidence)
- `mix.exs` / `mix.lock` - root version, optional Phoenix ranges, alias chain, tested root resolutions. [VERIFIED: mix.exs] [VERIFIED: mix.lock]
- `examples/threadline_phoenix/mix.exs` / `examples/threadline_phoenix/mix.lock` - declared example-host stack and tested `sigra-reference` resolutions. [VERIFIED: examples/threadline_phoenix/mix.exs] [VERIFIED: examples/threadline_phoenix/mix.lock]
- `guides/upgrade-path.md` - current lane matrix and proof-anchor wording. [VERIFIED: guides/upgrade-path.md]
- `guides/integrations/sigra.md` - current Sigra reference-lane contract. [VERIFIED: guides/integrations/sigra.md]
- `guides/getting-started-saas.md` / `guides/operator-surface.md` / `README.md` - current adoption narrative, stale package snippets, and parity reminders. [VERIFIED: guides/getting-started-saas.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: README.md]
- `examples/threadline_phoenix/README.md` / router - runnable example proof and auth-boundary shape. [VERIFIED: examples/threadline_phoenix/README.md] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]
- `lib/threadline/integrations/sigra.ex` / operator-surface auth modules - actual soft-dep, auth, and export-mirror behavior. [VERIFIED: lib/threadline/integrations/sigra.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: lib/threadline/operator_surface/export_auth_plug.ex]
- Focused ExUnit contract tests - current public wording/proof locks. [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] [VERIFIED: test/threadline/integrations/sigra_doc_contract_test.exs] [VERIFIED: test/threadline/example_phoenix_readme_contract_test.exs]

### Secondary (MEDIUM confidence)
- `CLAUDE.md` - project-specific language, verification, and layering constraints. [CITED: CLAUDE.md]
- `.planning/phases/68-.../68-CONTEXT.md`, `.planning/phases/69-.../69-CONTEXT.md`, `.planning/phases/70-.../70-CONTEXT.md` - locked planning constraints and phase scope. [CITED: .planning/phases/68-lifecycle-ergonomics/68-CONTEXT.md] [CITED: .planning/phases/69-integration-contracts-and-support-matrix/69-CONTEXT.md] [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]
- Shell environment checks for tool availability and versions. [VERIFIED: shell command]

### Tertiary (LOW confidence)
- None. All substantive implementation guidance in this document is grounded in the current repo or direct tool output. [VERIFIED: repo grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions, ranges, and proof pins are directly visible in current `mix.exs` and lockfiles. [VERIFIED: mix.exs] [VERIFIED: mix.lock] [VERIFIED: examples/threadline_phoenix/mix.lock]
- Architecture: HIGH - the request/surface/auth boundaries are explicit in router code, auth modules, guides, and tests. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex] [VERIFIED: lib/threadline/operator_surface/auth.ex] [VERIFIED: test/threadline/operator_surface/export_auth_plug_test.exs]
- Pitfalls: HIGH - the main risks are already observable as current stale snippets or as locked constraints in the phase context. [VERIFIED: README.md] [VERIFIED: guides/getting-started-saas.md] [CITED: .planning/phases/70-sigra-phoenix-reference-integration-refresh/70-CONTEXT.md]

**Research date:** 2026-05-07 [VERIFIED: repo context]
**Valid until:** 2026-06-06 for repo-grounded planning unless root/example lockfiles or Phase 70 context change first. [ASSUMED]
