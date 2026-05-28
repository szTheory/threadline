# Phase 122: Release & Distribution Truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves alternatives considered.

**Date:** 2026-05-28
**Phase:** 122-Release & Distribution Truth
**Areas discussed:** Post-publish verification, Adoption-pilot row, CHANGELOG four-lane, Tag timing
**Mode:** discuss (all areas, research-backed recommendations)

---

## Research synthesis (cross-cutting)

| Source | Lesson applied |
|--------|----------------|
| Ecto, Phoenix, Oban, Nimble* | CI proves source; Hex publish is release event + human `mix hex.info` |
| Sentry, Django Allauth changelogs | Upgrade guide link in version block; matrix stays in docs |
| npm / crates.io | Publish workflow ≠ registry assert on every commit |
| `prompts/threadline-elixir-oss-dna.md` | Doc contracts + version SSOT; no “docs A, Hex B” |
| Phase 114 | Three-layer verify: local → CI → maintainer/registry |
| Threadline assessment thread | Distribution truth is wedge #1 for v1.27 |

**Coherent package:** Three-wave phase in one milestone — honest Pending in repo PR → maintainer tag → post-publish OK row + evaluating guide + 122-VERIFICATION.md. No live hex CI on PRs. CHANGELOG minimal four-lane bullet + contract.

---

## 1. Post-publish verification (DIST-01)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Maintainer note in adoption-pilot | ✓ (part of hybrid) |
| B | Milestone closeout `.planning/` only | ✓ (122-VERIFICATION.md) |
| C | Doc-contract locks `OK` from mix.exs | |
| D | CI queries hex.pm every run | |
| E | CONTRIBUTING only | |

**User's choice:** **Hybrid A + B** (recommended default — user asked for all areas, no further questions)

**Notes:** Rejects C/D/E. DIST-01 satisfied by dated registry proof in backlog + verification file. CONTRIBUTING stays procedure SSOT.

---

## 2. Adoption-pilot Published row (DIST-02)

| Option | Description | Selected |
|--------|-------------|----------|
| A | OK + short date note | ✓ (baseline) |
| B | OK + GH Actions run URL | ✓ (with A) |
| C | OK + pasted mix hex.info | |
| D | Pending until external pilot | |
| E | Doc-contract auto-OK from mix.exs | |
| F | New two-tier doc section | ✓ (use existing Distribution vs in-repo tables) |

**User's choice:** **A + B** with structural doc-contract anti-stale when OK; **not E**

**Notes:** Sync evaluating-threadline.md same beat. Keep Pending until hex propagates.

---

## 3. CHANGELOG four-lane fix (DIST-03)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Minimal fix to upgrade bullet | ✓ |
| B | New ### Adopter lanes subsection | |
| C | phx-gen-auth in ### Added | |
| D | Full matrix table in CHANGELOG | |
| E | Link-only, no enumeration | |

**User's choice:** **A** + doc-contract lock on four lane IDs in `[0.6.0]`

**Notes:** Canonical order matches README/upgrade-path. Do not rewrite 0.5.0 history.

---

## 4. Tag timing vs phase work

| Option | Description | Selected |
|--------|-------------|----------|
| A | Tag prerequisite before execute | |
| B | Tag as final maintainer task | ✓ (Wave 2) |
| C | Parallel PR + tag when CI green | ✓ (timing) |
| D | Split 122a/122b phases | |
| E | Tag before discuss/plan | |

**User's choice:** **B + C** two-tier done in one phase (Waves 1–3)

**Notes:** Phase 123 gates on Tier 2 (hex live), not PR merge alone.

---

## Claude's Discretion

- Exact Evidence cell wording; Wave 3 commit shape; CHANGELOG test file placement; optional CONTRIBUTING one-liner.

## Deferred Ideas

- Live hex.pm CI on default branch
- Release Please automation (future)
- Full mix hex.info paste in backlog
