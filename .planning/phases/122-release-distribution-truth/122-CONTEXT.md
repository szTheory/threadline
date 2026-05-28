# Phase 122: Release & Distribution Truth - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the gap between in-repo **0.6.0** and hex.pm reality: evaluators can `mix deps.get` **threadline 0.6.0** from Hex; maintainer/adopter surfaces no longer imply **0.5.0** is latest. Covers DIST-01 (publish + verification record), DIST-02 (adoption-pilot distribution preflight), DIST-03 (CHANGELOG four-lane honesty). Does **not** change tag-triggered publish policy, add live hex.pm CI on every PR, or scope Phase 123/124 doc work.

</domain>

<decisions>
## Implementation Decisions

### Post-publish verification (DIST-01)

- **D-01:** **Maintainer-attested registry proof in two places** — not automated hex.pm polling in default CI.
  - **Adopter-facing:** `guides/adoption-pilot-backlog.md` Distribution preflight Hex row updated after publish.
  - **Maintainer-facing:** `.planning/phases/122-release-distribution-truth/122-VERIFICATION.md` with tag `v0.6.0`, successful `hex-publish.yml` run URL, and redacted `mix hex.info threadline` excerpt showing **0.6.0** in releases (minimum: line containing `0.6.0`).
- **D-02:** **CONTRIBUTING.md** remains procedure SSOT (`mix verify.release` → tag → watch workflow → `mix hex.info`); do not treat CONTRIBUTING alone as DIST-01 “recorded.”
- **D-03:** **Reject** doc-contract that requires Hex row `| OK |` whenever `mix.exs` `@version` is 0.6.0 — that inverts honest three-layer model (local verify → CI → human/registry) from OSS DNA and Phase 114.
- **D-04:** **Reject** default CI job querying hex.pm API on every `push`/`pull_request` — network flake, registry lag, and false reds unrelated to code changes. Optional future: `workflow_dispatch` smoke only.

### Adoption-pilot Published row (DIST-02)

- **D-05:** After hex.pm lists **0.6.0** as latest, flip first Distribution preflight row **Pending → OK** with **date-stamped, reproducible evidence** (STG-style “OK = pointer,” not vibes):
  - ISO date (`Verified YYYY-MM-DD:`)
  - Statement that hex.pm latest is **0.6.0**
  - Link to **successful** GitHub Actions `hex-publish.yml` run for tag **`v0.6.0`**
  - Pointer to CONTRIBUTING hex-publish section for `mix hex.info threadline` (do **not** paste full `mix hex.info` output — avoids churn)
- **D-06:** **Pre-publish:** row stays **Pending** with honest “hex still 0.5.0 / unblock: push tag” narrative — never merge **OK** before registry shows 0.6.0.
- **D-07:** Extend `adoption_pilot_doc_contract_test.exs` **structurally only:** when Hex row status is **OK**, refute stale lag prose (`latest is **0.5.0**`, “Unblock: push tag”); always assert `@version` string and `~> 0.6`. Do **not** auto-assert `| OK |` from `mix.exs`.
- **D-08:** Same publish beat updates `guides/evaluating-threadline.md`: remove “may still list **0.5.0**” caveat; point evaluators at Hex **0.6.0** + adoption-pilot preflight. Extend `evaluating_threadline_doc_contract_test.exs` to refute stale 0.5.0-as-latest caveat once published.

### CHANGELOG four-lane fix (DIST-03)

- **D-09:** **Minimal Keep a Changelog fix (Option A):** In `[0.6.0]` → `### Upgrade from 0.5.x`, replace the lane-matrix bullet to enumerate all **four named lane IDs** in canonical order: `` `capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, `sigra-reference` `` — link remains `guides/upgrade-path.md` for claim types, matrix table, and proof anchors (SSOT).
- **D-10:** **Do not** add `### Adopter lanes` subsection, duplicate upgrade-path table, or put `phx-gen-auth-reference` under `### Added` for 0.6.0 (mis-timelines v1.26 lane work). **Do not** rewrite historical `[0.5.0]` three-lane bullets.
- **D-11:** Add doc-contract on `CHANGELOG.md` `[0.6.0]` section locking the four-lane parenthetical (prevents line-38 regression).

### Tag timing vs phase work

- **D-12:** **Two-wave, one phase (B + C):** Planning/execute do **not** require tag before start. Phase is **not** complete at “PR merged.”
  - **Wave 1 (repo / GSD execute):** DIST-03 CHANGELOG + doc contract; distribution docs **honest Pending** until publish; `mix verify.release` / `mix ci.all` green on release commit.
  - **Wave 2 (maintainer gate):** After green `main` — `mix verify.release` on tagged commit → annotated **`v0.6.0`** → push tag → green **`hex-publish.yml`** → `mix hex.info threadline` confirms **0.6.0**.
  - **Wave 3 (post-publish sync):** DIST-02 backlog **OK** row + evaluating-guide trim + **122-VERIFICATION.md** + REQUIREMENTS/STATE ticks.
- **D-13:** Maintainer **may** push tag in parallel with Wave 1 merge for latency, but **Tier 2 done** requires Waves 2+3 — not “docs PR merged.”
- **D-14:** **Phase 123** should treat **Tier 2 complete** as dependency (“prefer 122 first” = hex.pm actually serves 0.6.0), not merely 122 PR merged.

### Ecosystem alignment (locked rationale)

- **D-15:** Follow mature Hex OSS pattern (Ecto, Phoenix, Oban, Nimble*): CI proves **source**; registry publish is a **release event** with human `mix hex.info` proof — same as npm/crates “publish action + maintainer verifies registry,” not per-PR registry asserts.
- **D-16:** Align **threadline-elixir-oss-dna.md** §3: version SSOT in repo; CHANGELOG + adoption surfaces agree with Hex **after** tag; avoid “docs say A, Hex says B.”

### Claude's Discretion

- Exact wording of adoption-pilot Evidence cell (within D-05 constraints).
- Whether Wave 3 is a second commit or bundled after tag on `main` (prefer small post-publish PR if tag lands before doc sync merges).
- Placement of CHANGELOG doc-contract (`adoption_pilot_doc_contract_test.exs` vs new `release_distribution_doc_contract_test.exs`).
- Optional one-line CONTRIBUTING cross-link: “DIST-01 proof = backlog OK row + 122-VERIFICATION.md.”

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` — Phase 122 goal, success criteria, DIST-01–03
- `.planning/REQUIREMENTS.md` — DIST-01, DIST-02, DIST-03 acceptance text
- `.planning/threads/2026-05-28-milestone-next-step-post-v1.26.md` — distribution wedge ranking, done band
- `.planning/STATE.md` — hex lag context, maintainer next steps

### OSS DNA & release patterns
- `prompts/threadline-elixir-oss-dna.md` — §2 doc contracts, §3 releases/Hex, verify entrypoints
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — tag-triggered publish, separate CI vs release workflows
- `CLAUDE.md` — verification entrypoints (`mix verify.*`, `mix ci.all`)

### Publish procedure & automation
- `CONTRIBUTING.md` — Hex publish (maintainers), `mix verify.release`, tag sequence
- `.github/workflows/hex-publish.yml` — tag ↔ `@version` gate, `mix hex.publish --yes`

### Adopter / evaluator surfaces (DIST-02, Wave 3)
- `guides/adoption-pilot-backlog.md` — Distribution preflight table (SSOT for publish status narrative)
- `guides/evaluating-threadline.md` — evaluator packaging anchor; lag caveat removal target
- `guides/upgrade-path.md` — four-lane matrix SSOT (CHANGELOG points here only)
- `CHANGELOG.md` — `[0.6.0]` upgrade section (DIST-03 edit target)

### Doc contracts & prior release phase
- `test/threadline/adoption_pilot_doc_contract_test.exs` — in-repo version + `~> 0.6`; extend anti-stale-when-OK
- `test/threadline/evaluating_threadline_doc_contract_test.exs` — 0.6.0 anchor; extend anti-stale post-publish
- `test/threadline/readme_doc_contract_test.exs` — four-lane README vocabulary
- `test/threadline/upgrade_path_doc_contract_test.exs` — lane matrix locks
- `test/threadline/release_artifact_contract_test.exs` — CONTRIBUTING / package release literals

### Historical context (do not re-litigate)
- `.planning/phases/114-release-packaging/` artifacts — D-114-05c publish out of phase; post-phase gate now closed in 122

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `hex-publish.yml` — tag-triggered publish with `@version` match; no workflow changes needed for 122.
- `mix verify.release` — local pre-tag gate already documented and tested.
- `adoption_pilot_doc_contract_test.exs` — locks `@version` + `~> 0.6`; extend for conditional anti-stale when OK.
- `Threadline.MixProject.project()[:version]` — dynamic version in tests (already used).

### Established Patterns
- **Honest Pending** in adoption-pilot until external registry catches up (current 2026-05-27 row).
- **Doc contracts lock prose shape; humans lock registry truth** (Phase 114, OSS DNA).
- **Four-lane SSOT** in `upgrade-path.md` + README; CHANGELOG names lanes briefly, does not duplicate matrix.

### Integration Points
- Wave 1 touches `CHANGELOG.md` + tests only (safe before publish).
- Wave 3 touches `guides/adoption-pilot-backlog.md`, `guides/evaluating-threadline.md`, `.planning/REQUIREMENTS.md`, `122-VERIFICATION.md`.
- Phase 123 getting-started work should assume Wave 2+3 complete for evaluator `mix deps.get` from Hex.

</code_context>

<specifics>
## Specific Ideas

- **Sentry / Oban / Ecto pattern:** major upgrades get a guide link in CHANGELOG, not a full compatibility table — Threadline already does this; 0.6.0 bullet was stale (three lanes at v1.25 packaging, fourth lane in v1.26).
- **Evaluator DX:** one story — evaluating guide + adoption-pilot preflight + Hex badge — no “in-repo 0.6.0 but Hex 0.5.0” after publish.
- **Maintainer DX:** prescribed closeout beats CONTRIBUTING; `122-VERIFICATION.md` is the GSD audit trail for DIST-01 without polluting default `mix test` with network.

</specifics>

<deferred>
## Deferred Ideas

- **Live hex.pm CI job** on every PR — deferred; optional `workflow_dispatch` only if publish mistakes recur.
- **Release Please automation** — out of scope (REQUIREMENTS: tag-triggered workflow unchanged); noted in prior-art CI research as future enhancement.
- **Paste full `mix hex.info` in backlog** — rejected (noisy, churn); command pointer preferred.

</deferred>

---

*Phase: 122-release-distribution-truth*
*Context gathered: 2026-05-28*
