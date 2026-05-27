# Phase 99: Contract Lock, Docs, And Final Verification - Research

**Researched:** 2026-05-26
**Domain:** Documentation contracts, support-language lock, and current-tree verification closeout for the evidence plane [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Verbatim copy from `99-CONTEXT.md`. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]

### Locked Decisions
- **D-01:** Keep `README.md` as the front door and map, not the full evidence
  contract manual.
- **D-02:** Add a compact evidence-plane claim strip to the README: one tight
  summary of what evidence Threadline proves, one explicit host-owned/non-goal
  boundary block, and links to the canonical deeper guides.
- **D-03:** Do not restate support matrices, dependency versions, or detailed
  proof bundles in the README. Those remain canonical in guide-level contract
  docs and verification artifacts.
- **D-04:** README wording should optimize for least surprise: enough detail to
  prevent readers from inferring “Threadline is now a compliance platform,” but
  not so much detail that the README becomes a shadow spec.

- **D-05:** Treat the evidence plane as a separately gated capability under the
  existing `phoenix-surface` lane, not as a capability that automatically
  inherits the broad `/audit` support claim.
- **D-06:** `guides/upgrade-path.md` should keep the named lane model
  (`capture-only`, `phoenix-surface`, `sigra-reference`) and add only the
  minimum extra wording needed to state that `/audit/evidence` is a narrower,
  explicitly authorized capability on the mounted surface.
- **D-07:** Public wording must preserve the shipped Phase 98 semantics:
  evidence access is fail-closed by default, host-owned through
  `evidence_authorize_fn`, and can render an explicit unsupported state even
  when the broader `/audit` lane is mounted and otherwise available.
- **D-08:** Avoid a full lane-by-capability matrix unless future phases add
  enough new gated operator capabilities that the narrower wording stops being
  legible.

- **D-09:** Publish one canonical public non-goals list, most naturally near
  the front-door “what Threadline is / is not” framing, then echo only the
  locally relevant negatives in deeper guides.
- **D-10:** The canonical list must explicitly reject at least:
  legal hold, immutable-storage guarantees beyond the host runtime/storage
  contract, generic compliance packs, vendor-specific reporting suites, and
  Threadline-owned RBAC or tenancy DSLs.
- **D-11:** Guide-local echoes must stay short and contextual. They should not
  become alternate rewritten copies of the full list.
- **D-12:** Negative claims are part of the product contract and should be
  test-locked like other support-language surfaces; they are not incidental
  prose that can drift release to release.

- **D-13:** Phase 99 should close on a balanced claim-shaped rerun bundle, not
  on the minimal targeted suite alone and not on “just run everything” theater.
- **D-14:** The authoritative DOC-03 evidence bar should include:
  current-tree reruns of the phase-owned evidence tests, mounted evidence
  tests, relevant root integration tests, `mix verify.doc_contract`, and
  `mix verify.example`.
- **D-15:** `mix ci.all` is useful repo-health evidence but should not be the
  sole authority for closing the evidence-plane claim, because it is both
  broader than the claim in some ways and narrower than it in others.
- **D-16:** The final verification artifact should record the exact rerun
  bundle and treat that bundle, not summary prose, as the authoritative closeout
  proof.
- **D-17:** Known unrelated failures outside the evidence-plane claim, such as
  the existing CI-topology alias drift called out in state/phase notes, must be
  named explicitly rather than silently inherited into Phase 99 truth.

- **D-18:** Treat Phase 99 as docs/verification closeout, not as an implicit
  release-cut phase.
- **D-19:** Update `CHANGELOG.md` under `## [Unreleased]` with focused,
  evidence-plane additions/changes if changelog visibility is desired on `main`.
  Do not write a release-style narrative that reads like a shipped `0.6.0`
  announcement before a real version/tag exists.
- **D-20:** Release-specific semantics, package metadata, and `verify.release`
  remain separate concerns unless a later phase explicitly turns the milestone
  closeout into a release-cut.

- **D-21:** README, upgrade-path, integration-contracts, operator-surface,
  how-threadline-works, and domain-reference wording must reinforce one another
  instead of each trying to become the canonical source for all evidence-plane
  nuance.
- **D-22:** The strongest cohesive posture is:
  README gives the thesis and narrow boundary,
  `guides/upgrade-path.md` owns lane/support proof wording,
  `guides/integration-contracts.md` owns host-owned seams,
  `guides/operator-surface.md` owns mounted capability and fallback posture,
  `guides/domain-reference.md` owns evidence vocabulary and proof semantics.
- **D-23:** All public claim wording should stay aligned with the repo’s core
  OSS values from the prompt corpus: proof-first support claims, least surprise,
  SQL-native truth, strong DX, and explicit operational boundaries.

- **D-24:** Research across all five gray areas converged on one coherent
  recommendation set: medium-plus README claim strip, separately gated evidence
  capability wording, one canonical non-goals list plus short echoes, balanced
  claim-shaped rerun bundle, and focused `Unreleased` changelog updates only.
- **D-25:** No unresolved high-impact breakpoint remains. Planning should
  proceed directly from this recommendation set unless current-tree code or doc
  evidence exposes a contradiction.

### Claude's Discretion
- Exact README section title and placement for the evidence-plane claim strip,
  as long as it stays compact and clearly subordinate to the canonical guides.
- Exact guide wording for the evidence capability note, as long as it preserves
  fail-closed host-owned authorization and avoids broad `/audit` inheritance.
- Exact test file mix for the balanced rerun bundle, as long as the selected
  bundle demonstrably covers README/guides/example/mounted/API/CLI evidence
  claims on the current tree.
- Exact `CHANGELOG.md` bullet wording under `Unreleased`, as long as it remains
  honest about branch state and avoids implying a tagged release.

### Deferred Ideas (OUT OF SCOPE)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | Public docs, support matrix guidance, and examples state exactly what evidence Threadline can prove and what remains host-owned. [VERIFIED: .planning/REQUIREMENTS.md] | README-as-map ownership, guide ownership map, separately gated `/audit/evidence` wording, and example/doc-contract extension points below. [VERIFIED: README.md] [VERIFIED: guides/upgrade-path.md] [VERIFIED: guides/integration-contracts.md] [VERIFIED: examples/threadline_phoenix/README.md] |
| DOC-02 | Public docs explicitly reject stronger claims that this milestone does not deliver, including legal hold, immutable-storage guarantees, generic compliance packs, and vendor-specific reporting suites. [VERIFIED: .planning/REQUIREMENTS.md] | Canonical non-goals placement in README / `how-threadline-works`, short local echoes in deeper guides, and contract-test lock recommendations below. [VERIFIED: guides/how-threadline-works.md] [VERIFIED: test/threadline/how_threadline_works_doc_contract_test.exs] |
| DOC-03 | Contract and integration tests lock the evidence-plane claim end to end on the current tree. [VERIFIED: .planning/REQUIREMENTS.md] | Existing doc-contract harness, evidence API/CLI/mounted test anchors, and balanced rerun-bundle recommendation below. [VERIFIED: mix.exs] [VERIFIED: test/threadline/evidence_test.exs] [VERIFIED: test/mix/tasks/threadline.evidence_show_test.exs] [VERIFIED: test/threadline/operator_surface/live/evidence_live_test.exs] |
</phase_requirements>

## Summary

Phase 99 should be planned as a contract-lock pass over an already-built claim surface, not as a feature phase. The repo already contains the core evidence API, proof vocabulary, CLI viewer, mounted `/audit/evidence` path, and mature doc-contract patterns; the planning problem is deciding which document owns which claim and then extending the existing test harness so those ownership lines cannot drift. [VERIFIED: test/threadline/evidence_test.exs] [VERIFIED: test/threadline/evidence/proof_test.exs] [VERIFIED: test/mix/tasks/threadline.evidence_show_test.exs] [VERIFIED: test/threadline/operator_surface/live/evidence_live_test.exs] [VERIFIED: test/threadline/readme_doc_contract_test.exs]

The repo’s strongest established pattern is “README as map, deeper guides as canonical detail, verification artifact as authority.” That pattern is already enforced for support-lane and operator-surface work through doc-contract tests, named `mix verify.*` entrypoints, and milestone audit files that treat rerun bundles as the closeout truth. Phase 99 should reuse that exact shape for the evidence-plane claim rather than inventing a new docs process. [VERIFIED: README.md] [VERIFIED: guides/upgrade-path.md] [VERIFIED: mix.exs] [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md] [VERIFIED: prompts/threadline-elixir-oss-dna.md]

**Primary recommendation:** Use the existing doc-contract + targeted evidence-test harness to lock a narrow README claim strip, a separately gated `/audit/evidence` support note, one canonical non-goals list, and a named current-tree rerun bundle recorded in the final verification artifact. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Front-door evidence claim strip and non-goals framing | Documentation / package front door | Test harness | `README.md` is the adopter map, while tests lock the literals. [VERIFIED: README.md] [VERIFIED: test/threadline/readme_doc_contract_test.exs] |
| Support-lane wording for mounted evidence access | Documentation / support matrix | Mounted surface semantics | `guides/upgrade-path.md` already owns lane truth, and Phase 99 only needs to add narrower evidence gating language. [VERIFIED: guides/upgrade-path.md] [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] |
| Host-owned authorization and unsupported-state wording | API / backend contract docs | Mounted surface tests | `guides/integration-contracts.md` and `guides/operator-surface.md` already define host-owned auth seams and unsupported-state behavior. [VERIFIED: guides/integration-contracts.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: test/threadline/operator_surface/live/evidence_live_test.exs] |
| Evidence vocabulary and proof semantics | Domain reference | API/CLI tests | `guides/domain-reference.md` already owns `proven` / `inferred_posture` / `unsupported`, and tests verify those semantics directly. [VERIFIED: guides/domain-reference.md] [VERIFIED: test/threadline/evidence/proof_test.exs] |
| Final closeout truth | Verification artifact | Milestone audit | The repo already treats rerun bundles and milestone audits as authoritative closeout evidence, not summary prose. [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md] |

## Project Constraints (from CLAUDE.md)

- Preserve the three-layer model: capture, semantics, and exploration/operations must not be conflated in docs or planning. [VERIFIED: CLAUDE.md]
- Use the repo’s domain language consistently: `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation`. [VERIFIED: CLAUDE.md]
- Prefer named verification entrypoints such as `mix verify.*` and `mix ci.*` in docs and plans instead of ad-hoc shell commands. [VERIFIED: CLAUDE.md]
- Keep default `mix test` honest; do not hide heavy suites without updating `test/test_helper.exs` and docs together. [VERIFIED: CLAUDE.md]
- Keep GitHub Actions job `id:` values stable. [VERIFIED: CLAUDE.md] [VERIFIED: .github/workflows/ci.yml]
- Keep doc contract tests aligned across README, guides, and example app README. [VERIFIED: CLAUDE.md]
- Do not let recommendations contradict the project’s non-goals: Threadline is not a SIEM, not event sourcing, not a pgAudit replacement, and not a data warehouse product. [VERIFIED: CLAUDE.md]

## Standard Stack

### Core
| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir + Mix | Elixir `~> 1.15` declared, CI runs Elixir `1.17.3` / OTP `27`, local machine has Elixir `1.19.5` / Mix `1.19.5`. [VERIFIED: mix.exs] [VERIFIED: .github/workflows/ci.yml] [VERIFIED: local tool probe 2026-05-26] | Runs doc-contract tests, targeted evidence tests, and named verification aliases. [VERIFIED: mix.exs] | This repo’s verification model is Mix-first; Phase 99 should extend aliases/tests, not add another runner. [VERIFIED: mix.exs] |
| ExUnit doc-contract tests | Bundled with the project’s Elixir toolchain. [VERIFIED: mix.exs] | Locks README, guide, and example literals. [VERIFIED: test/threadline/readme_doc_contract_test.exs] [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] | The harness already exists and is the lightest credible mechanism for DOC-01 and DOC-02. [VERIFIED: mix.exs] |
| Named verification aliases | `verify.doc_contract`, `verify.example`, `verify.test`, `ci.all`. [VERIFIED: mix.exs] | Provide canonical, reusable proof entrypoints for docs and integration checks. [VERIFIED: mix.exs] | The OSS DNA explicitly treats named verification entrypoints as product surface. [VERIFIED: prompts/threadline-elixir-oss-dna.md] |

### Supporting
| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix example host proof | Example host lock resolves Phoenix `1.8.5`, LiveView `1.1.28`, Phoenix HTML `4.3.0`, PubSub `2.2.0`, Sigra `0.2.5`. [VERIFIED: guides/upgrade-path.md] [VERIFIED: examples/threadline_phoenix/README.md] | Proves example-host wording and mounted-operator integration posture. [VERIFIED: examples/threadline_phoenix/README.md] | Use when a public claim depends on the reference-host story or `mix verify.example`. [VERIFIED: mix.exs] |
| Root mounted-surface proof | Root lane wording cites Phoenix `1.8.7`, LiveView `1.1.30`, Phoenix HTML `4.3.0`, PubSub `2.2.0`. [VERIFIED: guides/upgrade-path.md] | Proves the broader `phoenix-surface` lane and mounted doc wording. [VERIFIED: guides/upgrade-path.md] | Use when the wording concerns root-library support claims rather than the narrower Sigra example. [VERIFIED: guides/upgrade-path.md] |
| GitHub Actions CI topology | Workflow `ci.yml` with stable jobs such as `verify-test`, `verify-docs`, and `verify-compile-no-optional`. [VERIFIED: .github/workflows/ci.yml] | Cross-checks that doc and test entrypoints match CI language. [VERIFIED: .github/workflows/ci.yml] | Use when wording mentions proof sources or when planner needs to avoid stale CI references. [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extending existing doc-contract tests | Manual doc review only | Manual review cannot give DOC-03 closeout evidence and drifts too easily. [VERIFIED: mix.exs] [VERIFIED: prompts/threadline-elixir-oss-dna.md] |
| Named targeted rerun bundle | `mix ci.all` as the sole closeout gate | `mix ci.all` is broader than the claim and still not sufficient to prove the exact evidence-plane wording. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] |
| README-as-map with guide ownership | Full contract duplicated into README | The repo already treats README as a map, and duplicating matrices/proof bundles would create shadow-spec drift. [VERIFIED: README.md] [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] |

**Installation:**
```bash
# No new packages are recommended for Phase 99.
# Use the repo's existing Mix + ExUnit + Markdown doc-contract stack.
mix deps.get
```

**Version verification:** No new package selection is recommended in this phase; use the versions already proven in `mix.exs`, `guides/upgrade-path.md`, the example README, and CI workflow when writing contract wording. [VERIFIED: mix.exs] [VERIFIED: guides/upgrade-path.md] [VERIFIED: .github/workflows/ci.yml]

## Architecture Patterns

### System Architecture Diagram

```text
README claim strip / canonical non-goals
        |
        v
Guide owners
- upgrade-path: support/lane wording
- integration-contracts: host-owned seams
- operator-surface: mounted capability + unsupported state
- domain-reference: proof vocabulary
- how-threadline-works: product boundary
        |
        v
Doc-contract tests + evidence API/CLI/mounted tests
        |
        v
Named Mix verification entrypoints
- mix verify.doc_contract
- mix verify.example
- targeted MIX_ENV=test mix test ...
        |
        v
Phase 99 verification artifact
        |
        v
Milestone audit / closeout authority
```

This is the repo’s existing proof flow, and Phase 99 should extend it rather than bypass it. [VERIFIED: mix.exs] [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md]

### Recommended Project Structure
```text
README.md                                  # front-door claim strip and canonical links
guides/
├── how-threadline-works.md                # what Threadline is / is not
├── upgrade-path.md                        # support lanes and mounted evidence gating
├── integration-contracts.md               # host-owned seams and auth boundary
├── operator-surface.md                    # mounted capability and fallback posture
└── domain-reference.md                    # evidence proof vocabulary and semantics
test/threadline/
├── readme_doc_contract_test.exs           # README lock points
├── upgrade_path_doc_contract_test.exs     # support-matrix lock points
├── integration_contracts_doc_contract_test.exs
├── how_threadline_works_doc_contract_test.exs
└── operator_surface_doc_contract_test.exs
test/mix/tasks/threadline.evidence_show_test.exs
test/threadline/evidence/proof_test.exs
test/threadline/operator_surface/live/evidence_live_test.exs
.planning/phases/99-contract-lock-docs-and-final-verification/
└── 99-VERIFICATION.md                     # exact rerun bundle + outcomes
```

### Pattern 1: README As Map, Not Shadow Spec
**What:** Keep README short, claim-shaped, and outward-linking; put detailed evidence semantics and support wording in the canonical guides. [VERIFIED: README.md] [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]
**When to use:** Any time Phase 99 introduces new wording about what the evidence plane proves. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]
**Example:**
```elixir
# Source: test/threadline/readme_doc_contract_test.exs
readme = File.read!("README.md")
assert String.contains?(readme, "guides/upgrade-path.md")
assert String.contains?(readme, "guides/integration-contracts.md")
```

### Pattern 2: Canonical Owner Per Claim Family
**What:** Route each claim family to one guide owner and make other docs link or echo briefly instead of rewriting. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]
**When to use:** When adding evidence-plane wording to `upgrade-path`, `integration-contracts`, `operator-surface`, `how-threadline-works`, and `domain-reference`. [VERIFIED: guides/upgrade-path.md] [VERIFIED: guides/integration-contracts.md] [VERIFIED: guides/operator-surface.md] [VERIFIED: guides/domain-reference.md] [VERIFIED: guides/how-threadline-works.md]
**Example:**
```elixir
# Source: test/threadline/upgrade_path_doc_contract_test.exs
guide = File.read!("guides/upgrade-path.md")
assert String.contains?(guide, "Anything outside these named lanes is `unclaimed`, even if it may work.")
```

### Pattern 3: Rerun Bundle As Authority
**What:** Use a named bundle of doc-contract, example, and evidence tests as the closeout authority, and record that bundle in the verification artifact. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md]
**When to use:** Final closeout for DOC-03 and milestone evidence. [VERIFIED: .planning/REQUIREMENTS.md]
**Example:**
```bash
# Source: .planning/milestones/v1.21-MILESTONE-AUDIT.md
mix verify.doc_contract
mix verify.example
MIX_ENV=test mix test ...
```

### Anti-Patterns to Avoid
- **README shadow spec:** Do not duplicate support matrices, dependency versions, or proof bundles into README. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]
- **Capability inheritance shorthand:** Do not imply `/audit/evidence` is supported everywhere `/audit` is mounted; it is separately gated. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] [VERIFIED: test/threadline/operator_surface/live/evidence_live_test.exs]
- **Summary-as-truth closeout:** Do not let `SUMMARY.md` prose stand in for rerun evidence or the final verification artifact. [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md]
- **`mix ci.all` theater:** Do not claim the phase is closed solely because the broad repo suite passed. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Doc drift prevention | Manual review checklist only | Existing ExUnit doc-contract tests | The repo already has a stable pattern for literal lock points across README/guides/example docs. [VERIFIED: test/threadline/readme_doc_contract_test.exs] [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] |
| Final proof narrative | Freeform closeout prose | Named rerun bundle recorded in `99-VERIFICATION.md` | Milestone audits already treat rerun bundles as authority. [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md] |
| New verification command namespace | One-off shell scripts | Existing `mix verify.*` aliases and targeted `mix test` invocations | The repo’s OSS DNA explicitly standardizes named verification entrypoints. [VERIFIED: mix.exs] [VERIFIED: prompts/threadline-elixir-oss-dna.md] |
| New support-matrix format | Full lane-by-capability matrix | Minimal wording extension inside `guides/upgrade-path.md` | The locked decision is to keep the named-lane model and add only the narrow evidence capability note. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] |

**Key insight:** Phase 99 is strongest when it reuses mature proof infrastructure already trusted elsewhere in the repo, because that keeps the write set small and the closeout evidence comparable to prior milestone closure patterns. [VERIFIED: mix.exs] [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md]

## Common Pitfalls

### Pitfall 1: Overclaiming Mounted Evidence Support
**What goes wrong:** Docs imply that mounting `/audit` automatically proves `/audit/evidence` everywhere. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]
**Why it happens:** The repo already has a broad `phoenix-surface` lane, so it is easy to phrase the new capability as inherited rather than separately authorized. [VERIFIED: guides/upgrade-path.md]
**How to avoid:** Add one narrow evidence-capability sentence in `guides/upgrade-path.md` and repeat the host-owned `evidence_authorize_fn` / unsupported-state posture in the canonical guides only. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] [VERIFIED: test/threadline/operator_surface/live/evidence_live_test.exs]
**Warning signs:** Wording like “the `/audit` lane includes evidence” without authorization/fallback qualifiers. [ASSUMED]

### Pitfall 2: Duplicating the Non-Goals List Everywhere
**What goes wrong:** README, `how-threadline-works`, `integration-contracts`, and `domain-reference` all start carrying slightly different negative-claim language. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]
**Why it happens:** Each guide feels like it needs to stand alone, so writers restate the whole boundary list. [ASSUMED]
**How to avoid:** Put the canonical list near the front-door product framing and keep deeper-guide echoes short and local. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]
**Warning signs:** Multiple files enumerate legal hold, immutable guarantees, compliance packs, and RBAC/tenancy DSLs with non-identical wording. [ASSUMED]

### Pitfall 3: Treating `mix ci.all` As The Only Closeout Gate
**What goes wrong:** The phase closes on a broad repo-health run that does not explicitly prove the evidence-plane claim. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]
**Why it happens:** `mix ci.all` is convenient and already exists. [VERIFIED: mix.exs]
**How to avoid:** Record a named rerun bundle for the exact claim surfaces and treat `mix ci.all` as supporting evidence only. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]
**Warning signs:** Verification notes say “CI passed” but do not list evidence API, CLI, mounted evidence, example, and doc-contract commands explicitly. [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md]

### Pitfall 4: Letting Summary Frontmatter Become Truth
**What goes wrong:** A phase summary implies closure even when the authoritative rerun bundle is missing or stale. [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md]
**Why it happens:** Summary files are easier to skim than verification artifacts. [ASSUMED]
**How to avoid:** Make `99-VERIFICATION.md` the explicit source of truth and cite it from milestone closeout surfaces. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md]
**Warning signs:** Requirement closure references summaries without rerun commands or outcomes. [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md]

## Code Examples

Verified patterns from official repo sources:

### README / Guide Contract Assertion
```elixir
# Source: test/threadline/readme_doc_contract_test.exs
readme = File.read!("README.md")
assert String.contains?(readme, "guides/upgrade-path.md")
assert String.contains?(readme, "guides/integration-contracts.md")
```

### Support-Lane Lock Assertion
```elixir
# Source: test/threadline/upgrade_path_doc_contract_test.exs
guide = File.read!("guides/upgrade-path.md")
assert String.contains?(guide, "Anything outside these named lanes is `unclaimed`, even if it may work.")
```

### Named Verification Alias
```elixir
# Source: mix.exs
"verify.doc_contract": [
  "test test/threadline/readme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs"
]
```

### Mounted Evidence Unsupported-State Proof
```elixir
# Source: test/threadline/operator_surface/live/evidence_live_test.exs
{:ok, _view, html} = live(conn, "/audit/evidence")
assert html =~ "Unsupported View"
assert html =~ "mix threadline.evidence.show"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| README carries broad onboarding prose with detailed support truth elsewhere only implicitly | README is a map and guide pointer, with doc-contract tests locking key links and section boundaries. [VERIFIED: README.md] [VERIFIED: test/threadline/readme_doc_contract_test.exs] | Established before v1.21 and reinforced by current tests on 2026-05-26. [VERIFIED: test/threadline/readme_doc_contract_test.exs] | Phase 99 should add only a compact claim strip, not a shadow spec. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] |
| Support-lane truth could drift between examples, guides, and CI prose | `guides/upgrade-path.md` is the canonical lane matrix, backed by doc-contract tests and CI job-name assertions. [VERIFIED: guides/upgrade-path.md] [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs] | Locked by v1.21 closeout evidence dated 2026-05-25. [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md] | Phase 99 should extend the same guide rather than create a new matrix. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] |
| Summary/frontmatter could be mistaken for closure evidence | Rerun bundles recorded in verification artifacts are treated as the authority. [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md] | Explicitly called out in the 2026-05-25 v1.21 milestone audit. [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md] | Phase 99 should close with an exact rerun bundle and outcomes table. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] |

**Deprecated/outdated:**
- Treating `/audit` support truth as a blanket inheritance rule for every mounted capability is outdated for the evidence plane. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]
- Treating `mix ci.all` as sufficient closeout authority for a narrow product claim is outdated for this phase. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Warning signs for overclaiming can be detected by broad wording such as “the `/audit` lane includes evidence” without qualifiers. | Common Pitfalls | Low; planner still has the explicit locked wording rules from context. |
| A2 | Rewriting the same non-goals across multiple files is likely to create drift because each guide optimizes for local clarity. | Common Pitfalls | Low; the canonical-owner recommendation still stands even if the exact failure mode differs. |
| A3 | Summary files are easier to skim than verification artifacts and therefore more likely to be mistaken as authority. | Common Pitfalls | Low; milestone audit evidence already proves the repo guards against this. |

## Open Questions (RESOLVED)

1. **Is all Phase 98 code already on the current tree, or does Phase 99 need a dependency preflight before planning?**
   - What we know: the repo already contains mounted evidence tests, `evidence_authorize_fn` behavior, and evidence-route wording surfaces. [VERIFIED: test/threadline/operator_surface/live/evidence_live_test.exs] [VERIFIED: .planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md]
   - Resolution: treat the current working tree plus on-disk Phase 98 summaries as execution truth and require a short preflight before Phase 99 verification work begins. `99-02-PLAN.md` now records that preflight explicitly and requires any mismatch with `STATE.md` to be named in `99-VERIFICATION.md`. [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-02-PLAN.md]

2. **Should Phase 99 add a new `domain-reference` doc-contract test, or is proof-test coverage sufficient?**
   - What we know: `guides/domain-reference.md` owns the evidence proof vocabulary, but there is no existing dedicated `domain_reference_doc_contract_test.exs` file in the current test tree. [VERIFIED: guides/domain-reference.md] [VERIFIED: rg --files test]
   - Resolution: `guides/domain-reference.md` must be locked as a public text surface, not only as a runtime-semantics source. Phase 99 therefore needs direct guide-text assertions, either in a focused new doc-contract file or in an existing named doc-contract test that reads the guide explicitly, and that coverage must run through `mix verify.doc_contract`. [VERIFIED: guides/domain-reference.md] [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-02-PLAN.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix aliases, ExUnit tests, doc-contract suite | ✓ [VERIFIED: local tool probe 2026-05-26] | `1.19.5` locally; CI uses `1.17.3`. [VERIFIED: local tool probe 2026-05-26] [VERIFIED: .github/workflows/ci.yml] | Use CI versions as the canonical wording reference if local/CI differ. [VERIFIED: .github/workflows/ci.yml] |
| Mix | Named verification entrypoints | ✓ [VERIFIED: local tool probe 2026-05-26] | `1.19.5`. [VERIFIED: local tool probe 2026-05-26] | None |
| PostgreSQL CLI (`pg_isready`, `psql`, `createdb`) | Test bootstrap and example verification | ✓ [VERIFIED: local tool probe 2026-05-26] | `14.17` locally. [VERIFIED: local tool probe 2026-05-26] | Dockerized Postgres via `docker compose` remains available if the local service is down. [VERIFIED: test/test_helper.exs] [VERIFIED: docker --version] |
| Local Postgres service | Default `mix test` and evidence/integration runs | ✓ [VERIFIED: local tool probe 2026-05-26] | `localhost:5432` accepting connections. [VERIFIED: local tool probe 2026-05-26] | Docker Compose per `test/test_helper.exs` hint. [VERIFIED: test/test_helper.exs] |
| Docker | Optional fallback for Postgres-backed runs | ✓ [VERIFIED: local tool probe 2026-05-26] | `29.4.1`. [VERIFIED: local tool probe 2026-05-26] | None needed |
| Git | Commiting research and comparing verification write sets | ✓ [VERIFIED: local tool probe 2026-05-26] | `2.41.0`. [VERIFIED: local tool probe 2026-05-26] | None |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local tool probe 2026-05-26]

**Missing dependencies with fallback:**
- None. [VERIFIED: local tool probe 2026-05-26]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir/Mix. [VERIFIED: test/test_helper.exs] [VERIFIED: mix.exs] |
| Config file | `mix.exs`, `config/test.exs`, `test/test_helper.exs`. [VERIFIED: mix.exs] [VERIFIED: config/test.exs] [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix verify.doc_contract` for doc changes; `MIX_ENV=test mix test test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` for evidence-surface parity. [VERIFIED: mix.exs] [VERIFIED: test/threadline/evidence/proof_test.exs] [VERIFIED: test/mix/tasks/threadline.evidence_show_test.exs] [VERIFIED: test/threadline/operator_surface/live/evidence_live_test.exs] |
| Full suite command | `mix ci.all`. [VERIFIED: mix.exs] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOC-01 | README/guides/example wording states what evidence Threadline proves and what remains host-owned. [VERIFIED: .planning/REQUIREMENTS.md] | doc contract | `mix verify.doc_contract` plus any added `how_threadline_works` / `domain_reference` contract coverage. [VERIFIED: mix.exs] | ✅ existing harness; `domain-reference` textual lock may be a Wave 0 gap. [VERIFIED: rg --files test] |
| DOC-02 | Public docs reject stronger claims such as legal hold, immutable guarantees, compliance packs, and vendor suites. [VERIFIED: .planning/REQUIREMENTS.md] | doc contract | `mix verify.doc_contract` and targeted `mix test test/threadline/how_threadline_works_doc_contract_test.exs`. [VERIFIED: mix.exs] [VERIFIED: test/threadline/how_threadline_works_doc_contract_test.exs] | ✅ for `how-threadline-works`; other guides may need extensions. [VERIFIED: rg --files test] |
| DOC-03 | Current-tree docs and evidence surfaces stay aligned end to end. [VERIFIED: .planning/REQUIREMENTS.md] | doc contract + API + CLI + LiveView + example | `mix verify.doc_contract`, `mix verify.example`, and targeted `MIX_ENV=test mix test test/threadline/evidence_test.exs test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/auth_test.exs --max-failures 1`. [VERIFIED: mix.exs] | ✅ |

### Sampling Rate
- **Per task commit:** `mix verify.doc_contract` for doc-only work, or the targeted evidence parity suite when test files move. [VERIFIED: mix.exs]
- **Per wave merge:** `mix verify.example` plus the targeted evidence parity suite. [VERIFIED: mix.exs]
- **Phase gate:** The named Phase 99 rerun bundle recorded in `99-VERIFICATION.md`, with `mix ci.all` optional as supporting repo-health evidence. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]

### Wave 0 Gaps
- [ ] Add or extend doc-contract coverage for the canonical evidence claim strip in `README.md`. Current README tests do not yet mention evidence-plane wording explicitly. [VERIFIED: test/threadline/readme_doc_contract_test.exs]
- [ ] Add or extend `guides/upgrade-path.md` contract coverage for separately gated `/audit/evidence` wording under the `phoenix-surface` lane. [VERIFIED: test/threadline/upgrade_path_doc_contract_test.exs]
- [ ] Decide whether `guides/domain-reference.md` needs a dedicated textual doc-contract test or explicit new assertions in existing proof tests. [VERIFIED: guides/domain-reference.md] [VERIFIED: test/threadline/evidence/proof_test.exs]
- [ ] Add final verification-artifact structure for the exact rerun bundle and unrelated-known-failure note. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md]

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [VERIFIED: guides/integration-contracts.md] | Host-owned; Phase 99 documents the boundary but does not add auth logic. [VERIFIED: guides/integration-contracts.md] |
| V3 Session Management | no [VERIFIED: guides/operator-surface.md] | Existing session/mount behavior remains unchanged; this phase only locks wording and proof. [VERIFIED: guides/operator-surface.md] |
| V4 Access Control | yes [VERIFIED: guides/operator-surface.md] [VERIFIED: test/threadline/operator_surface/live/evidence_live_test.exs] | Keep mounted evidence fail-closed via host-owned authorization callbacks and explicit unsupported-state fallback. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] |
| V5 Input Validation | yes [VERIFIED: test/mix/tasks/threadline.evidence_show_test.exs] | Reuse existing bounded CLI/query parsing and explicit error behavior in evidence viewers/tests. [VERIFIED: test/mix/tasks/threadline.evidence_show_test.exs] |
| V6 Cryptography | no [VERIFIED: .planning/REQUIREMENTS.md] | Phase 99 does not introduce new crypto or integrity primitives; it explicitly avoids stronger immutability guarantees than the host can prove. [VERIFIED: .planning/REQUIREMENTS.md] |

### Known Threat Patterns for this phase
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Docs overclaim host-owned authorization or support breadth | Spoofing / Elevation | Keep `evidence_authorize_fn` and unsupported-state wording explicit in canonical guides and lock it with tests. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] [VERIFIED: test/threadline/operator_surface/live/evidence_live_test.exs] |
| Support claims drift from current proof | Repudiation | Tie wording to existing proof anchors and rerun them in the final bundle. [VERIFIED: guides/upgrade-path.md] [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md] |
| Summary prose diverges from actual rerun evidence | Tampering | Treat the verification artifact, not summary prose, as the closeout authority. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] |
| Readers infer immutable-storage or compliance guarantees not actually delivered | Information Disclosure / Misrepresentation | Publish a canonical non-goals list and short local echoes in deeper guides. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)
- `/.planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md` - locked Phase 99 decisions, proof-bar, and doc ownership map.
- `/.planning/REQUIREMENTS.md` - `DOC-01`, `DOC-02`, `DOC-03`.
- `/.planning/STATE.md` - current milestone state and known verification-drift note.
- `/CLAUDE.md` - project constraints and verification conventions.
- `/README.md` - current front-door contract shape.
- `/guides/upgrade-path.md` - support-lane and proof-source wording.
- `/guides/integration-contracts.md` - host-owned auth/seam wording.
- `/guides/operator-surface.md` - fail-closed mounted surface wording.
- `/guides/domain-reference.md` - evidence proof vocabulary.
- `/guides/how-threadline-works.md` - public non-goal and boundary framing.
- `/mix.exs` - named verification entrypoints.
- `/.github/workflows/ci.yml` - stable CI job IDs and verification topology.
- `/test/threadline/readme_doc_contract_test.exs` - README contract harness.
- `/test/threadline/upgrade_path_doc_contract_test.exs` - support-matrix contract harness.
- `/test/threadline/integration_contracts_doc_contract_test.exs` - host-seam contract harness.
- `/test/threadline/how_threadline_works_doc_contract_test.exs` - boundary/non-goals contract harness.
- `/test/threadline/operator_surface_doc_contract_test.exs` - mounted-surface contract harness.
- `/test/threadline/evidence_test.exs` - evidence API truth surface.
- `/test/threadline/evidence/proof_test.exs` - proof verdict semantics.
- `/test/mix/tasks/threadline.evidence_show_test.exs` - CLI viewer parity and unsupported semantics.
- `/test/threadline/operator_surface/live/evidence_live_test.exs` - mounted evidence overview/history/unsupported-state proof.
- `/.planning/milestones/v1.21-MILESTONE-AUDIT.md` - current-tree closeout and rerun-bundle authority pattern.
- `/test/test_helper.exs` and `/config/test.exs` - local Postgres-backed test bootstrap.

### Secondary (MEDIUM confidence)
- `/.planning/research/v1.22-policy-evidence-plane.md` - milestone-level rationale and prior recommendation context.
- `/.planning/MILESTONE-ARC.md` - strategic milestone thesis and non-goals.
- `/examples/threadline_phoenix/README.md` - example-host wording and verification role.
- `/prompts/threadline-elixir-oss-dna.md` - maintainer intent for verification/doc-contract patterns.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phase 99 reuses current repo-native tooling rather than adopting new libraries. [VERIFIED: mix.exs]
- Architecture: HIGH - The doc owner map and rerun-bundle pattern are explicit in Phase 99 context and prior milestone closeout artifacts. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md]
- Pitfalls: MEDIUM - Most pitfalls are directly evidenced by locked decisions and prior milestone lessons, but a few warning-sign heuristics remain assumed. [VERIFIED: .planning/phases/99-contract-lock-docs-and-final-verification/99-CONTEXT.md] [VERIFIED: .planning/milestones/v1.21-MILESTONE-AUDIT.md] [ASSUMED]

**Research date:** 2026-05-26
**Valid until:** 2026-06-25
