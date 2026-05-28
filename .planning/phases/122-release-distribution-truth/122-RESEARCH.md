# Phase 122: Release & Distribution Truth — Research

**Researched:** 2026-05-28  
**Phase:** 122-release-distribution-truth  
**Requirements:** DIST-01, DIST-02, DIST-03  
**Context SSOT:** `122-CONTEXT.md` (user decisions D-01–D-16)

---

## 1. Executive summary

Phase 122 closes the **distribution honesty gap** left open at v1.25: in-repo packaging is complete at **0.6.0** (Phase 114), but **hex.pm still serves 0.5.0** and several adopter surfaces still narrate that lag. This phase is **not** another packaging pass — it is a **three-wave release completion** that aligns registry reality with docs without changing publish policy or adding live hex.pm CI.

| Wave | Owner | Delivers |
|------|-------|----------|
| **Wave 1** | Contributor PR on `main` | DIST-03 CHANGELOG four-lane fix + doc contract; adoption/evaluating docs stay **honest Pending**; `mix verify.release` / `mix ci.all` green |
| **Wave 2** | Maintainer gate | DIST-01: tag **`v0.6.0`** → green **`hex-publish.yml`** → `mix hex.info threadline` shows **0.6.0** |
| **Wave 3** | Maintainer post-publish PR | DIST-01 proof (`122-VERIFICATION.md`); DIST-02 backlog **OK** row + evaluating-guide trim; REQUIREMENTS/STATE ticks |

**Planning takeaway:** Treat Phase 122 as **incomplete until Wave 3 merges**, not when Wave 1 PR lands. Phase 123 should prefer **Tier 2 complete** (hex.pm serves 0.6.0) before evaluator work. Reuse Phase 114 machinery (`mix verify.release`, `hex-publish.yml`, CONTRIBUTING runbook) — **no workflow or `mix.exs` version bump** required unless drift appears during execute.

---

## 2. Current state audit

### 2.1 Hex lag (registry vs repo)

| Signal | Value | Source |
|--------|-------|--------|
| `mix.exs` `@version` | **0.6.0** | `mix.exs:4` |
| hex.pm latest release | **0.5.0** (2026-05-08) | `mix hex.info threadline` (2026-05-28) |
| hex.pm install config | `{:threadline, "~> 0.5.0"}` | same |
| Publish trigger | Tag `v[0-9]+.[0-9]+.[0-9]+` → `mix hex.publish --yes` | `.github/workflows/hex-publish.yml` |
| Tag/version gate | `GITHUB_REF_NAME` must match `@version` | workflow step "Confirm tag matches mix.exs @version" |

Phase 114 explicitly deferred publish per **D-114-05c** ("Out of phase scope: creating/pushing `v0.6.0` tag… asserting hex.pm live state"). Phase 122 is the **post-phase gate** that closes that deferral.

**Pre-flight already green in-repo:** `bin/verify-release-shape`, `mix verify.release` composition, `verify-hex-package` and `verify-release-shape` CI jobs on PR/`main`. Tarball builds; registry publish has not happened.

### 2.2 Doc surfaces (distribution narrative)

| Surface | Current state | Gap vs DIST |
|---------|---------------|-------------|
| `guides/adoption-pilot-backlog.md` Distribution preflight row 1 | **Pending** — "latest is **0.5.0**"; unblock tag `v0.6.0` | DIST-02: flip to **OK** only post-publish (Wave 3) |
| `guides/evaluating-threadline.md` § "What Threadline 0.6.0 packages" | Lag caveat: hex "may still list **0.5.0** as latest" | DIST-02: remove caveat Wave 3; point at Hex 0.6.0 + preflight |
| `CHANGELOG.md` `[0.6.0]` → `### Upgrade from 0.5.x` line 38 | Three lanes only: `capture-only`, `phoenix-surface`, `sigra-reference` | **DIST-03:** missing **`phx-gen-auth-reference`** (v1.26 fourth lane) |
| `guides/upgrade-path.md` | Four-lane matrix SSOT — complete | No edit required; CHANGELOG links here |
| `README.md` | Four-lane canonical order already correct | No edit required for 122 |
| `CONTRIBUTING.md` | v0.6.0 tag runbook, `mix verify.release` sequence | Procedure SSOT; optional one-line DIST-01 pointer (D-16 discretion) |

**Honest Pending pattern (Phase 114 → 122):** adoption-pilot Hex row correctly says Pending while registry lags. Wave 1 must **not** merge OK before publish (D-06).

### 2.3 Test contracts (what CI locks today)

| Test file | Locks | 122 extension |
|-----------|-------|---------------|
| `adoption_pilot_doc_contract_test.exs` | `@version`, `~> 0.6`, refute `~> 0.5`; upgrade-path link | **Conditional:** when Hex row `\| OK \|`, refute stale lag prose |
| `evaluating_threadline_doc_contract_test.exs` | `0.6.0` anchor, **requires** `0.5.0` string (upgrade context), verify ladder | **Post-publish:** refute "may still list **0.5.0** as latest" |
| `release_artifact_contract_test.exs` | Package files, ExDoc groups, README `~> 0.6`, CONTRIBUTING `v0.6.0` | No CHANGELOG lane assertions today |
| `upgrade_path_doc_contract_test.exs` | Four named lanes in matrix | SSOT reference; CHANGELOG must not duplicate table |
| `readme_doc_contract_test.exs` | Four-lane README vocabulary | Canonical order for CHANGELOG enumeration |

**Explicit rejections (CONTEXT D-03, D-04, D-07):**

- Do **not** assert `\| OK \|` on Hex row whenever `@version` is 0.6.0.
- Do **not** add default CI job polling hex.pm API.

`mix verify.doc_contract` runs 15 test files; **`release_artifact_contract_test.exs` is not in that alias** — it runs inside `mix verify.release` instead.

### 2.4 Historical context (Phase 114)

Archived under `.planning/milestones/v1.25-phases/114-release-0-6-0-packaging/`:

- **114-VERIFICATION.md:** 4/4 REL requirements passed; "Maintainer tag/publish remains manual follow-up per plan 114-03."
- **Three-layer model:** local `verify.release` → contributor `ci.all` → human/registry publish.
- **114-03-PLAN:** CONTRIBUTING refresh + green `mix verify.release` — already shipped.

Phase 122 inherits that packaging; it adds **registry + adopter-facing truth**, not REL re-work.

---

## 3. Wave 1 / 2 / 3 implementation approach (DIST-01 / 02 / 03)

### DIST-03 — CHANGELOG four-lane honesty (Wave 1 only)

**Problem:** Line 38 of `CHANGELOG.md` under `[0.6.0]` lists three lanes; v1.26 added **`phx-gen-auth-reference`** to upgrade-path/README but CHANGELOG upgrade bullet was not updated.

**Fix (Option A, D-09):** Replace the lane-matrix bullet in `### Upgrade from 0.5.x` with canonical four-ID parenthetical in order:

`` `capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, `sigra-reference` ``

Link text stays `guides/upgrade-path.md` — no matrix duplication, no new `### Adopter lanes`, no `phx-gen-auth` under `### Added` (D-10).

**Verification:** New doc-contract test on `[0.6.0]` section only (D-11). Suggested placement: extend `release_artifact_contract_test.exs` or add `release_distribution_doc_contract_test.exs` and wire into `mix verify.doc_contract` if CHANGELOG is adopter-critical enough for default CI (recommended: **yes**, via doc_contract alias).

**Wave 1 gate:** `mix verify.doc_contract` + `mix ci.all` green on PR.

---

### DIST-01 — Publish + verification record (Wave 2 + Wave 3)

**Wave 2 — Maintainer publish (no code change required):**

1. Clean tree: `git status --porcelain` empty.
2. `mix verify.release` on commit to tag (same tree CI validated).
3. Green **`main`** CI (all branch-protection jobs).
4. Annotated tag and push:

   ```bash
   git tag -a v0.6.0 -m "Release v0.6.0"
   git push origin main        # if needed
   git push origin v0.6.0
   ```

5. Watch [`.github/workflows/hex-publish.yml`](.github/workflows/hex-publish.yml) — job "Publish package and docs".
6. Confirm registry: `mix hex.info threadline` — **Recent releases** must include **0.6.0**; config snippet should reflect `~> 0.6` after propagation.

**Prerequisites already satisfied:** `HEX_API_KEY` secret (workflow fails loudly if missing); tag/version alignment script in workflow.

**Wave 3 — Verification record (hybrid A + B, D-01):**

| Audience | Artifact | Content |
|----------|----------|---------|
| Adopter-facing | `guides/adoption-pilot-backlog.md` Hex row | See DIST-02 |
| Maintainer / GSD | `.planning/phases/122-release-distribution-truth/122-VERIFICATION.md` | Tag `v0.6.0`, successful `hex-publish.yml` run URL, redacted `mix hex.info threadline` excerpt with line containing **0.6.0** |

CONTRIBUTING remains procedure SSOT — not sufficient alone for DIST-01 "recorded" (D-02).

**Optional:** One-line CONTRIBUTING cross-link: "DIST-01 proof = adoption-pilot OK row + `122-VERIFICATION.md`."

---

### DIST-02 — Adoption-pilot + evaluating guide sync (Wave 3)

**Pre-publish (Wave 1 PR — no change or explicit Pending):** Keep current Pending row; optionally refresh date in Evidence cell if stale — still must say hex latest **0.5.0** and unblock tag narrative until Wave 2 completes.

**Post-publish (Wave 3):** Flip first Distribution preflight row **Pending → OK** with STG-style evidence (D-05):

- `Verified YYYY-MM-DD:` (ISO date of maintainer check)
- Statement: hex.pm latest is **0.6.0**
- Link to **successful** GitHub Actions `hex-publish.yml` run for tag **`v0.6.0`**
- Pointer to CONTRIBUTING `#hex-publish-maintainers` for `mix hex.info threadline` — **do not paste full output**

**`guides/evaluating-threadline.md` (same beat):**

- Remove paragraph clause: "As of … may still list **0.5.0** as latest until maintainers push tag **`v0.6.0`**"
- Replace with: Hex serves **0.6.0**; see adoption-pilot Distribution preflight for maintainer attestation link
- Keep **0.5.0** in upgrade/historical context elsewhere in guide (evaluating test currently asserts `0.5.0` presence — that remains valid for semver story)

**Doc contracts (D-07, D-08):**

```elixir
# adoption_pilot_doc_contract_test.exs — pattern sketch
if String.contains?(guide, "| OK |") and hex_row_is_ok?(guide) do
  refute String.contains?(guide, "latest is **0.5.0**")
  refute String.contains?(guide, "Unblock: push tag")
end
# Always (unchanged):
assert String.contains?(guide, @version)
assert String.contains?(guide, "~> 0.6")
```

```elixir
# evaluating_threadline_doc_contract_test.exs — post-publish
if adoption_pilot_hex_ok?() do
  refute String.contains?(guide, "may still list **0.5.0** as latest")
end
```

Helper can grep adoption-pilot first Distribution row for `\| OK \|` — structural coupling is intentional (SSOT chain).

**Planning files (Wave 3 closeout):**

- `.planning/REQUIREMENTS.md` — tick DIST-01, DIST-02, DIST-03
- `.planning/STATE.md` — update Hex distribution line; phase complete markers

---

## 4. File-by-file change map

| File | Wave | Action |
|------|------|--------|
| `CHANGELOG.md` | 1 | Fix line ~38 four-lane bullet in `[0.6.0]` / `### Upgrade from 0.5.x` |
| `test/threadline/release_distribution_doc_contract_test.exs` *(new, recommended)* or `release_artifact_contract_test.exs` | 1 | Assert four lane IDs in `[0.6.0]` upgrade bullet; refute three-lane-only regression |
| `mix.exs` | 1 | Only if new test file → add to `verify.doc_contract` alias list |
| `guides/adoption-pilot-backlog.md` | 3 | Hex row Pending → OK + evidence cell (D-05) |
| `guides/evaluating-threadline.md` | 3 | Remove hex lag caveat; point at 0.6.0 + preflight |
| `test/threadline/adoption_pilot_doc_contract_test.exs` | 1 + 3 | Wave 1: add conditional anti-stale test (passes while Pending). Wave 3: passes with OK row |
| `test/threadline/evaluating_threadline_doc_contract_test.exs` | 1 + 3 | Wave 1: add conditional anti-stale (skipped while Pending). Wave 3: enforce |
| `.planning/phases/122-release-distribution-truth/122-VERIFICATION.md` | 3 | **Create** — DIST-01 maintainer attestation |
| `.planning/REQUIREMENTS.md` | 3 | Check off DIST-01–03 |
| `.planning/STATE.md` | 3 | Hex lag resolved; phase progress |
| `.planning/ROADMAP.md` | 3 | Mark Phase 122 complete |
| `CONTRIBUTING.md` | 3 optional | One-line DIST-01 proof pointer |
| `.github/workflows/hex-publish.yml` | — | **No change** (out of scope) |
| `mix.exs` `@version` | — | **No change** (already 0.6.0) |
| `guides/upgrade-path.md` | — | **No change** (SSOT) |
| `README.md` | — | **No change** unless accidental drift |

**Wave 2 files:** none — git tag + CI only.

---

## 5. Doc contract test extensions needed

### 5.1 New or extended CHANGELOG contract (DIST-03)

**File:** prefer `test/threadline/release_distribution_doc_contract_test.exs` (keeps `release_artifact_contract_test.exs` focused on ExDoc/package shape).

**Assertions:**

1. Extract `[0.6.0]` section (scope between `## [0.6.0]` and next `## [`).
2. `assert` section contains all four backtick-wrapped lane IDs in order (or `assert` each ID present + ordered substring match).
3. `refute` three-lane-only pattern: `` (`capture-only`, `phoenix-surface`, `sigra-reference`) `` without `phx-gen-auth-reference`.
4. `assert` link to `guides/upgrade-path.md` in upgrade section.

**Alias:** add to `mix verify.doc_contract` in `mix.exs` if new file.

### 5.2 Adoption-pilot conditional anti-stale (DIST-02)

**File:** `test/threadline/adoption_pilot_doc_contract_test.exs`

**New test:** `"when Hex distribution row is OK, refutes stale 0.5.0 lag narrative"`

- Parse first Distribution preflight data row (line after header).
- If status cell contains `OK`, refute:
  - `latest is **0.5.0**`
  - `Unblock: push tag` (case-sensitive match to current prose)
- If `Pending`, test passes without those refutes.

**Unchanged tests:** version + `~> 0.6` always.

### 5.3 Evaluating guide conditional anti-stale (DIST-02)

**File:** `test/threadline/evaluating_threadline_doc_contract_test.exs`

**New test:** `"when adoption-pilot Hex row is OK, refutes hex still 0.5.0 caveat"`

- Read adoption-pilot guide; detect OK on Hex row.
- If OK: `refute String.contains?(evaluating_guide, "may still list **0.5.0** as latest")`
- Optionally `assert` contains `0.6.0` hex.pm or preflight pointer post-publish.

**Preserve:** existing test requiring `0.5.0` string (upgrade semver context, not "latest" claim).

### 5.4 What NOT to add

| Rejected pattern | Reason |
|------------------|--------|
| `assert` Hex row `\| OK \|` when `@version == "0.6.0"` | Inverts three-layer model (D-03) |
| CI job calling hex.pm on every PR | Flake, lag, false reds (D-04) |
| Network calls in `mix test` | Same; maintainer attestation is human/registry layer |

---

## 6. Risks and pitfalls

| Risk | Severity | Mitigation |
|------|----------|------------|
| Merging Wave 3 **OK** row before registry propagates | High | D-06: maintainer runs `mix hex.info` before Wave 3 PR; never auto-OK from tests |
| Wave 1 PR merged → team assumes 122 "done" | High | D-12/D-14: plan and ROADMAP success criteria require Waves 2+3; Phase 123 depends on Tier 2 |
| Tag pushed from dirty tree or wrong commit | Medium | `mix verify.release` clean-tree guard; tag only green `main` HEAD |
| `@version` / tag mismatch | Medium | `hex-publish.yml` fails publish; CONTRIBUTING documents sequence |
| `HEX_API_KEY` missing/rotated | Medium | Workflow emits `::error::`; manual `mix hex.publish` fallback in CONTRIBUTING |
| Registry propagation delay | Low | Wait and re-run `mix hex.info` before Wave 3 |
| CHANGELOG four-lane fix mis-timelines v1.26 | Low | D-10: only upgrade bullet; no `### Added` for phx-gen-auth |
| Evaluating test breaks on Wave 1 | Medium | Conditional tests must **pass** while Pending (only refute when OK) |
| Accidentally rewriting `[0.5.0]` three-lane history | Low | D-10 explicit; scope doc-contract to `[0.6.0]` section only |
| Parallel tag + Wave 1 merge race | Low | D-13: allowed for latency; Wave 3 still required for docs sync |
| Doc-contract coupling to table markdown shape | Low | Match existing adoption-pilot table parsing style; document fragile line |

---

## 7. Validation Architecture (Nyquist)

Nyquist principle for this phase: **each requirement has at least one automated check where honest**, plus **human/registry attestation where automation would lie**.

### DIST-01 — Publish + verification record

| Layer | Validation | Owner | When |
|-------|------------|-------|------|
| Source | `mix verify.release` (clean tree, release-shape, artifact contracts, docs, hex.build) | Automated | Wave 1 PR + Wave 2 pre-tag |
| CI | `verify-release-shape`, `verify-hex-package`, full `ci.all` on `main` | Automated | Pre-tag |
| Registry | `hex-publish.yml` green on tag `v0.6.0` | Automated (event-triggered) | Wave 2 |
| Human | `mix hex.info threadline` shows 0.6.0 | Maintainer | Wave 2 closeout |
| Record | `122-VERIFICATION.md` + adoption-pilot OK row | Maintainer-authored | Wave 3 |

**Nyquist gap (accepted):** No CI assertion that hex.pm latest == `@version`. **Superseding evidence:** maintainer attestation files. **Reopen trigger:** publish mistake recurs → optional `workflow_dispatch` hex smoke (deferred).

### DIST-02 — Adoption-pilot + evaluating surfaces

| Layer | Validation | Owner | When |
|-------|------------|-------|------|
| Pre-publish honesty | Existing tests: `@version`, `~> 0.6`; Pending row prose | Automated | Wave 1 (must stay green) |
| Post-publish shape | Conditional refute stale lag in adoption + evaluating contracts | Automated | Wave 3 (activates when OK) |
| Content truth | Maintainer verifies hex.pm before OK row | Human | Wave 3 |
| Chain | Evaluating test reads adoption-pilot SSOT | Automated | Wave 3 |

**Nyquist gap (accepted):** Tests do not fetch hex.pm. **Superseding evidence:** OK row + GH Actions URL + `122-VERIFICATION.md`.

### DIST-03 — CHANGELOG four-lane mention

| Layer | Validation | Owner | When |
|-------|------------|-------|------|
| Content | CHANGELOG bullet lists four canonical lane IDs | Maintainer edit | Wave 1 |
| Regression lock | Doc-contract on `[0.6.0]` section | Automated (`mix verify.doc_contract`) | Wave 1 |
| SSOT depth | `upgrade_path_doc_contract_test.exs` (unchanged) | Automated | Existing CI |

**Nyquist:** Fully machine-verifiable in Wave 1 — no human gate required for DIST-03 alone.

### Recommended verification commands (cite in PLAN.md)

```bash
# Wave 1 PR
mix test test/threadline/release_distribution_doc_contract_test.exs   # after added
mix test test/threadline/adoption_pilot_doc_contract_test.exs
mix test test/threadline/evaluating_threadline_doc_contract_test.exs
mix verify.doc_contract
mix verify.release    # maintainer dry-run before merge if release-critical
mix ci.all            # full contributor gate

# Wave 2 (maintainer)
git status --porcelain   # empty
mix verify.release
git tag -a v0.6.0 -m "Release v0.6.0"
git push origin v0.6.0
# → watch hex-publish.yml
mix hex.info threadline

# Wave 3 PR
mix verify.doc_contract
# Manual: grep adoption-pilot OK row + 122-VERIFICATION.md present
```

---

## 8. Recommended plan split

**Three plans matching three waves** — mirrors Phase 114's 01/02/03 split and CONTEXT D-12.

| Plan | Wave | Type | Requirements | Deliverables |
|------|------|------|--------------|--------------|
| **122-01-PLAN.md** | 1 | `execute` (autonomous) | DIST-03 (+ test scaffolding for DIST-02 conditionals) | CHANGELOG fix; new/extended doc contracts; conditional tests that pass while Pending; `mix ci.all` green |
| **122-02-PLAN.md** | 2 | `maintainer-gate` (manual checklist) | DIST-01 (publish) | Tag `v0.6.0`; green `hex-publish.yml`; `mix hex.info` confirmation; no repo commit required |
| **122-03-PLAN.md** | 3 | `execute` (autonomous + maintainer content) | DIST-01 (record), DIST-02 | adoption-pilot OK row; evaluating guide trim; `122-VERIFICATION.md`; REQUIREMENTS/STATE/ROADMAP ticks; conditional tests now enforce anti-stale |

### Dependency graph

```
122-01 (Wave 1 PR) ──merge──► main green ──► 122-02 (tag/publish)
                                                    │
                                                    ▼
                                              122-03 (post-publish PR)
```

**Parallelism:** Maintainer may run **122-02** in parallel with **122-01** merge (D-13) if `main` already contains 0.6.0 packaging — but **122-03** still depends on successful publish.

### Plan sizing guidance

- **122-01:** Small — ~2 source files + 1–3 test files + optional `mix.exs` alias line. Single commit acceptable.
- **122-02:** Checklist-only PLAN (~15 lines of steps); SUMMARY captures GH run URL + hex.info excerpt for 122-03 author.
- **122-03:** Small — 2 guides + 1 planning verification file + requirement ticks. Prefer **separate PR** from Wave 1 if tag lands before doc sync merges (D-13 discretion).

### Phase completion criteria (for PLAN frontmatter)

Phase 122 is **complete** when all are true:

1. hex.pm latest **0.6.0** (DIST-01)
2. `122-VERIFICATION.md` exists with tag, workflow URL, hex.info excerpt (DIST-01)
3. adoption-pilot Hex row **OK** with dated evidence (DIST-02)
4. evaluating guide has no stale lag caveat (DIST-02)
5. CHANGELOG `[0.6.0]` four-lane bullet + doc contract green (DIST-03)
6. `.planning/REQUIREMENTS.md` DIST-01–03 checked

**Not sufficient:** Wave 1 PR merged alone.

---

## Canonical references (planner checklist)

- `122-CONTEXT.md` — locked decisions D-01–D-16
- `.planning/milestones/v1.25-phases/114-release-0-6-0-packaging/114-CONTEXT.md` — D-114-05 publish boundary
- `prompts/threadline-elixir-oss-dna.md` — §2 doc contracts, §3 releases/Hex
- `CONTRIBUTING.md` — Hex publish (maintainers)
- `.github/workflows/hex-publish.yml` — tag-triggered publish (unchanged)
- `guides/upgrade-path.md` — four-lane matrix SSOT

---

*Research complete for `/gsd-plan-phase 122`.*
