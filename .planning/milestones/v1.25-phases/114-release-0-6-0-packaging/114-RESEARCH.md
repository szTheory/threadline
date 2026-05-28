# Phase 114: Release 0.6.0 Packaging — Research

**Researched:** 2026-05-27  
**Phase:** 114-release-0-6-0-packaging  
**Requirements:** REL-01, REL-02, REL-03, REL-04

---

## 1. Current release surface state

| Surface | Current | Target |
|---------|---------|--------|
| `mix.exs` `@version` | `0.5.0` | `0.6.0` |
| `CHANGELOG.md` top | `[Unreleased]` with evidence-plane doc contract bullets | Dated `## [0.6.0] - YYYY-MM-DD` with capability-grouped release notes |
| `README.md` install | `~> 0.5` | `~> 0.6` |
| `guides/adoption-pilot-backlog.md` | `0.5.0` / `~> 0.5` | `0.6.0` / `~> 0.6` |
| `guides/getting-started-saas.md` | `~> 0.5` | `~> 0.6` |
| `guides/operator-surface.md` | `~> 0.5` | `~> 0.6` |
| `CONTRIBUTING.md` | `v0.3.0` runbook literals | `v0.6.0` |
| ExDoc `groups_for_modules` | No Audit, Evidence, Query, Investigation, ChangeDiff; Mix Tasks missing Evidence.Show, Health.Coverage, Policy.Show | Per D-114-03 in CONTEXT |

`bin/verify-release-shape` already enforces `@version` ↔ dated `## [VERSION] - YYYY-MM-DD` in CHANGELOG. Pre-release versions skip the check.

`mix verify.release` (unchanged composition): clean tree → `bin/verify-release-shape` → release + ci_topology contract tests → `MIX_ENV=dev mix docs` → `mix hex.build`. Not in `ci.all`.

---

## 2. CHANGELOG content sources (REL-01)

Fold `[Unreleased]` **Changed** bullets into **Public documentation and evidence-plane contract** under `### Changed` — do not duplicate as `Added`.

**Added** capability groups (bold leads, Phase 48 D-04 pattern):

1. **Evidence plane** — `Threadline.Evidence`, `Evidence.Proof`, `Evidence.Subject`, schema, `mix threadline.evidence.show`
2. **Audited write path** — `Threadline.Audit.transaction/3`
3. **Operator and evidence surfaces** — `/audit/evidence`, `evidence_authorize_fn`, viewer parity
4. **Reference composition (sigra-reference)** — pointer to example/walkthrough (no wall of detail)

**Deprecated:** manual GUC + `record_action/2` legacy; prefer `Audit.transaction/3`.

**Breaking:** explicit none for 0.5.x capture-only / phoenix-surface adopters not opting into new surfaces.

**Upgrade from 0.5.x:** ~12–15 bullets (deps `~> 0.6`, evidence migrations, `evidence_authorize_fn` seam, CLI names, verify entrypoints).

Opener (locked shape D-114-01c): adopter-ready release packaging since 0.5.0 — no `v1.22` in headline.

House style references: `## [0.5.0]`, `## [0.4.0]`, `## [0.3.0]` openers in `CHANGELOG.md`.

---

## 3. ExDoc module inventory (REL-02)

Modules exist on disk and need grouping:

| Group | Modules to add |
|-------|----------------|
| Core API | `Threadline.Audit`, `Threadline.Query`, `Threadline.Investigation`, `Threadline.ChangeDiff` |
| Evidence (new) | `Threadline.Evidence`, `Threadline.Evidence.Proof`, `Threadline.Evidence.Subject` |
| Mix Tasks | `Mix.Tasks.Threadline.Evidence.Show`, `Mix.Tasks.Threadline.Health.Coverage`, `Mix.Tasks.Threadline.Policy.Show` |

Sidebar order: Core API → Evidence → Integration → Integrations → Operator Surface → Schemas → Mix Tasks.

Extend `test/threadline/release_artifact_contract_test.exs` — do not rewrite entire contract; add assertions for new groups and README `~> 0.6`.

---

## 4. Doc-contract SSOT pattern (REL-04)

Phase 113 established `@version` derive in `adoption_pilot_doc_contract_test.exs`:

```elixir
@version Threadline.MixProject.project()[:version]
```

After bump, update hardcoded `~> 0.5` → `~> 0.6` in:

- `adoption_pilot_doc_contract_test.exs` (assert + refute stale)
- `getting_started_saas_doc_contract_test.exs`
- `operator_surface_doc_contract_test.exs`
- `release_artifact_contract_test.exs` (README literal)

`mix verify.doc_contract` must stay green; it does **not** include `release_artifact_contract_test.exs` (release-only gate).

---

## 5. Publish boundary (REL-03)

In scope: `mix verify.release` green on clean tree; CONTRIBUTING maintainer runbook `v0.3.0` → `v0.6.0`.

Out of scope: tag push, `mix hex.publish`, hex.pm live assertion in phase verification.

Post-phase maintainer gate (document in plan 03 verification task, not automated REL-03):

```bash
git status --porcelain   # empty
mix verify.release
mix ci.all               # if needed on main
git tag -a v0.6.0 -m "Release v0.6.0"
git push origin v0.6.0
mix hex.info threadline
```

---

## 6. Validation Architecture (Nyquist Dimension 8)

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config** | `test/test_helper.exs` |
| **Release gate** | `mix verify.release` (dev env, clean tree) |
| **Doc contract gate** | `mix verify.doc_contract` |
| **Full CI** | `mix ci.all` (excludes `verify.release`) |
| **Estimated quick runtime** | Targeted contract tests ~5–15s; `verify.release` ~30–90s |

### Per-wave sampling

| Wave | Plan | Delivers | Automated command | Requirement |
|------|------|----------|-------------------|-------------|
| 1 | 01 | Version + CHANGELOG + ExDoc groups | `mix test test/threadline/release_artifact_contract_test.exs` | REL-01, REL-02 |
| 2 | 02 | Install snippets + doc contracts | `mix verify.doc_contract` | REL-04 |
| 3 | 03 | CONTRIBUTING + release pre-flight | `mix verify.release` (clean tree required) | REL-03 |

**Sampling rule:** Run wave command after each plan; run `mix ci.all` before phase closeout if workspace allows.

### Manual-only

| Behavior | Why manual |
|----------|------------|
| Hex publish + tag push | Human gate per Phase 48 D-09 |
| `mix verify.release` on dirty workspace | Use isolated worktree or commit first |

---

## 7. Plan split recommendation

| Plan | Wave | Requirements | Rationale |
|------|------|--------------|-----------|
| 01 | 1 | REL-01, REL-02 | `mix.exs` + CHANGELOG + ExDoc + release artifact group contract — single artifact file |
| 02 | 2 | REL-04 | Disjoint guide/README edits + doc-contract tests; depends on `@version` |
| 03 | 3 | REL-03 | CONTRIBUTING + final `verify.release`; depends on 01–02 literals |

Plans 01→02→03 sequential (shared `mix.exs` / version SSOT).

---

## RESEARCH COMPLETE
