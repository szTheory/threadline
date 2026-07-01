# Roadmap: Threadline

## Milestones

- [ ] **v1.39 Quality Baseline, Schema Confidence, and CI Efficiency** - Phases 189-193 (active; opened 2026-07-01).
- [x] **v1.38 Operator UI Page-by-Page IA & Design-System Polish** - Phases 181-188 (shipped 2026-06-30). Archive: `.planning/milestones/v1.38-ROADMAP.md`
- [x] **v1.37 Operator Surface Design-System Stress Test & Component System** - Phases 171-180 (shipped 2026-06-20). Archive: `.planning/milestones/v1.37-ROADMAP.md`
- [x] **v1.36 Operator Surface Light Mode** - Phases 166-170 (shipped 2026-06-14). Archive: `.planning/milestones/v1.36-ROADMAP.md`
- [x] **v1.35 Unified Logo & Brand Book v2** - Phases 159-165 (shipped 2026-06-12). Archive: `.planning/milestones/v1.35-ROADMAP.md`
- [x] **v1.34 Local Docker Admin UI DX** - Phases 154-158 (shipped 2026-06-07). Archive: `.planning/milestones/v1.34-ROADMAP.md`

## Current Planning State

Active milestone: **v1.39 Quality Baseline, Schema Confidence, and CI Efficiency**.

**Goal:** Make Threadline's adoption trust boundary current, measured, and durable by ranking software-quality risks, hardening configurable PostgreSQL storage-schema behavior, repairing release/docs drift, and improving CI/CD efficiency without hiding risk.

**Execution posture:** audit first, then fix high-confidence gaps. Do not expand product/UI scope unless the audit proves a current trust issue. CI changes should be measured, boring, and reversible.

## Current Milestone: v1.39 Quality Baseline, Schema Confidence, and CI Efficiency

| Phase | Name | Requirements | Status |
|------:|------|--------------|--------|
| 189 | Quality baseline and authority-surface audit | QUAL-01, QUAL-02, QUAL-03 | Complete (1/1, 2026-07-01) |
| 190 | 1/10 | In Progress|  |
| 191 | Release/version and docs trust repair | ADOPT-01, ADOPT-02, ADOPT-03 | Pending |
| 192 | CI/CD measurement and efficiency hardening | CI-01, CI-02, CI-03, CI-04 | Pending |
| 193 | Quality closeout and next-step decision | CLOSE-01 | Pending |

### Phase 189: Quality Baseline and Authority-Surface Audit

**Goal:** Produce the blunt, repo-evidence quality ranking requested by the prompt and use it to keep v1.39 focused on the weakest adoption, production, support, and maintenance risks.

**Requirements:** QUAL-01, QUAL-02, QUAL-03

**Success criteria:**

- A durable quality-audit artifact ranks dimensions from weakest/highest-risk to strongest/lowest-risk with evidence, confidence, consequence, highest-leverage fix, and priority.
- The audit explicitly marks good-enough, low-priority, and N/A dimensions instead of manufacturing fake concerns.
- Open residuals and seeds that can affect trust are triaged, including SEED-005, screenshot-regression confidence, external pilot boundaries, host staging ownership, and known CI/example-app residuals.
- The audit narrows the remaining v1.39 implementation work instead of broadening into unrelated product or UI expansion.

### Phase 190: Storage Schema Confidence and Host-Schema Truth

**Goal:** Make the `storage_schema` story trustworthy beyond the default `threadline` schema, including custom-schema Ecto behavior, migration SQL, and host-schema assumptions.

**Requirements:** SCHEMA-01, SCHEMA-02, SCHEMA-03, SCHEMA-04

**Plans:** 10 plans

Plans:
**Wave 1**

- [x] 190-01-PLAN.md — Quote storage-schema identifiers and freeze generated migration contracts.
- [ ] 190-02-PLAN.md — Remove owned fixed prefixes and add explicit storage-schema test support.

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 190-03-PLAN.md — Wire core API, query, preload, and export reads to selected storage.
- [ ] 190-05-PLAN.md — Make retention and pruning storage-prefix safe.
- [ ] 190-07-PLAN.md — Prove `support.tickets` trigger, coverage, verify, and continuity behavior.

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 190-04-PLAN.md — Make queued export, cleanup, and download storage-prefix aware.
- [ ] 190-06-PLAN.md — Make operator storage reads and writes prefix-aware.
- [ ] 190-08-PLAN.md — Add selected host-schema redaction CLI, presenter, and UI support.

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 190-09-PLAN.md — Preserve host-schema identity through Timeline, filters, row-history, and docs.

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 190-10-PLAN.md — Prove custom `audit` storage with real dual-schema PostgreSQL sentinels.

**Success criteria:**

- `storage_schema: "audit"` or equivalent non-default schema is covered through capture/query/evidence/governance/operator-relevant paths.
- Fixed `@schema_prefix` interactions are removed, overridden safely, or proven harmless with tests that would fail if reads/writes silently hit `threadline`.
- Generated migration SQL safely quotes validated storage-schema identifiers, or docs/tests narrow the supported identifier contract.
- Continuity, policy/redaction inspection, and operator coverage either support non-public host schemas consistently or clearly document/test-lock public-only behavior.

### Phase 191: Release/Version and Docs Trust Repair

**Goal:** Remove public-version drift and sharpen the adoption path so a stranger can trust the README, Hex line, evaluator docs, and upgrade story without maintainer context.

**Requirements:** ADOPT-01, ADOPT-02, ADOPT-03

**Success criteria:**

- README, guides, evaluator docs, adoption backlog, CHANGELOG/package metadata, and install snippets agree on current `0.9.0` truth or explicitly justify older examples.
- Upgrade guidance covers 0.6.x through 0.9.x adopter effects: storage-schema default, operator surface/theming, release lanes, and migration expectations.
- README/ExDoc guide routing gives evaluators, first-hour adopters, operators, and maintainers a short next-step path.
- Doc-contract tests fail on future install/version/upgrade drift.

### Phase 192: CI/CD Measurement and Efficiency Hardening

**Goal:** Baseline the CI/CD pipeline, then make low-risk improvements that improve feedback speed, determinism, and maintainer DX without weakening gates.

**Requirements:** CI-01, CI-02, CI-03, CI-04

**Success criteria:**

- Current CI critical path, duplicated setup/deps work, browser lane cost, cache state, and flaky/rerun signals are recorded from GitHub/local evidence or explicitly marked unavailable.
- Cache/setup changes are precise, reversible, and safe across OS/OTP/Elixir/MIX_ENV boundaries.
- PgBouncer image pinning, release concurrency, branch-protection docs, job names, and local `mix ci.*` expectations align.
- Compatibility policy for Elixir/OTP/Postgres support is explicit, with only justified min/current lanes added to PR/main/scheduled workflows.

### Phase 193: Quality Closeout and Next-Step Decision

**Goal:** Close v1.39 with evidence, traceability, ranked remaining risk, and a concrete recommendation for what should happen next.

**Requirements:** CLOSE-01

**Success criteria:**

- Requirements traceability and verification evidence are current.
- Before/after CI data is captured where possible; if not, the no-measure reason is explicit.
- Remaining software-quality risks are ranked with owner/follow-up and no vague "polish later" bucket.
- The next milestone recommendation is clear: CI/CD depth, external adopter proof, observability, or hold.

## Prior Milestones

<details>
<summary>v1.38 Operator UI Page-by-Page IA & Design-System Polish (Phases 181-188) - SHIPPED 2026-06-30</summary>

Baseline guard repair, PhoenixStorybook example/dev lane, shell/Home orientation, Timeline investigation flow, Coverage readiness, detail/governance/export surface polish, accessibility/motion/docs closeout, and Phase 188 audit-gap closure for queued export replay, `.tl-copy` motion, GOV-02 traceability, and v1.38 evidence. Archive: `.planning/milestones/v1.38-ROADMAP.md`.

</details>

<details>
<summary>v1.37 Operator Surface Design-System Stress Test & Component System (Phases 171-180) - SHIPPED 2026-06-20</summary>

Internal component system, `/audit/__stress`, design-system ledger, shell/navigation/theme picker, page stress coverage, microcopy/IA normalization, WCAG/APG/motion guardrails, accessibility-tree evidence, and adversarial closeout. Archive: `.planning/milestones/v1.37-ROADMAP.md`.

</details>

<details>
<summary>v1.36 Operator Surface Light Mode (Phases 166-170) - SHIPPED 2026-06-14</summary>

`theme: :dark | :light | :system` host config and pure-CSS light/system lanes. Archive: `.planning/milestones/v1.36-ROADMAP.md`.

</details>
