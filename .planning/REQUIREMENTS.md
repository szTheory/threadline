# Requirements: Threadline v1.41 — Green, Clean, and Honest

**Defined:** 2026-08-27
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Milestone goal:** Get the repository into a genuinely clean, green, publishable state — then ratchet software quality across every technical stakeholder lens wherever the improvement can be made mechanical and gated.

## v1.41 Requirements

### Green Bringup

- [x] **GREEN-01**: Maintainer can see the last red CI run's failing logs preserved in-repo before GitHub purges them at 90 days (run `28214113903`, ~62 days old at milestone open).
- [x] **GREEN-02**: Maintainer can read a measured per-check Credo finding histogram and a per-file concentration table, produced from a full-default config held outside the repo, without `.credo.exs` being modified.
- [x] **GREEN-03**: Maintainer can state, from evidence rather than inference, whether `verify.mechanical` is sensitive to rendered text content and text width or only to tokens, contrast, and element geometry.
- [ ] **GREEN-04** *(still Pending — re-measured 2026-08-29 on CI run `33253587315`, supersedes `33204829086`)*: `mix test` passes with no deterministically-failing tests, each former failure fixed on its merits rather than skipped — including replacing version-pinned milestone literals with shape assertions that cannot rot at the next milestone. **`Run test suite (current)` concluded `failure` on run `33253587315` — not the literal string `success`, so this requirement cannot close. Failing step: `Verify Threadline Phoenix example` (`mix verify.example`), which reported `109 tests, 1 failure` then `** (Mix) verify.example failed (2)`; the job's earlier root-suite step passed (`1423 tests, 0 failures, 1 excluded`). Three-way cause precision: (1) the ORIGINAL cause (missing `ALTER DATABASE ... SET search_path` at `ci.yml:235-240`) remains CLOSED since plan 198-19 — `grep -c "undefined_table"` over the job log returns 0; (2) round 3's cause on run `33204829086` (9 demo-seed content mismatches across `DemoContractTest`, `WalkthroughHappyPathTest`, `WalkthroughEvidenceTest`, the class D-41 named) is also CLOSED — plans 198-23/24/25 fixed it at cause and none of those tests fail on this run; (3) the CURRENT cause is a THIRD, previously-invisible defect: `ThreadlinePhoenix.DemoResetTest` "prod mix demo.reset fails fast without DEMO_ALLOW_RESET=1" (`examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs:56`) fails with `** (ExUnit.TimeoutError) test timed out after 60000ms` at line 69, where a `System.cmd("mix", ["demo.reset"], env: [{"MIX_ENV", "prod"}])` must cold-compile the example app and its deps under `MIX_ENV=prod` before reaching the guard it asserts on, with no `@tag timeout:` budget. This is a CI-only test-harness defect, not a demo-seed defect and not a product defect, and it is the sole blocker between the current state and this requirement. Plan 198-25's local `mix verify.example` measured `109 tests, 0 failures` twice (warm `_build/prod`, 36.6s and 14.7s) against CI's `109 tests, 1 failure` (cold, 96.1s) — both figures are recorded side by side in `198-CI-MEASUREMENT.md`'s Round 4 section, and per D-01 the local figure is a readiness signal only and is NOT admissible evidence for this requirement. This requirement is NOT marked Complete on local output, and NOT marked Complete because the remaining defect was deferred — a decision to defer is not evidence of satisfaction.**
- [x] **GREEN-05**: A page that legitimately gains a form causes the formless-page guard to fail loudly in the same diff, rather than requiring a hand-edited allowlist elsewhere.
- [x] **GREEN-06**: Every CI job has a `timeout-minutes` bound, and a systemically-broken browser suite aborts early instead of accumulating per-test timeouts.
- [ ] **GREEN-07** *(re-measured 2026-08-29 on CI run `33253587315`, supersedes `33204829086`)*: `origin/main` contains every local commit and its latest CI run concludes `success` in ≤ 20 minutes. **Time clause MET — measured 8m11s (`2026-08-29T12:52:18Z` → `2026-08-29T13:00:29Z`), comfortably inside 20m00s and faster than round 3's 13m29s. Success clause NOT MET — `CI required` concluded the literal string `failure`, with 3 of its 12 `needs:` members red: `verify-test` (`Run test suite (current)`), `verify-example-browser` (`Example app browser E2E (Playwright)`), and `verify-capture` (`Tier A capture lane (byte-stable evidence)`). The other 9 members all concluded `success`, with ZERO `skipped` and ZERO `cancelled` — worth stating because `re-actors/alls-green` would score a `skipped` required check as passing, and D-09 rejects that laundering; only the exact string `success` counts here, and every non-`success` conclusion (`neutral`, `skipped`, `cancelled`) is recorded as not-success. Structural blocker: `Tier A capture lane (byte-stable evidence)` is red and D-39 forbids its only remedy — Tier-A `page.*` scorecard regeneration — for this entire milestone (198 scorecard files show drift; the visible, workflow-truncated diff shows deterministic `scroll_cost` values byte-identical to rounds 2 and 3). Two of the five failing Playwright tests are `page.*` ledger-baseline screenshot diffs in the same D-39-forbidden class. Closure was therefore NOT pursued by narrowing `ci-required`'s `needs:` list: `.github/workflows/ci.yml`, `.github/rulesets/main.json`, `CONTRIBUTING.md` and `examples/threadline_phoenix/e2e/playwright.config.ts` are all byte-unchanged this round (D-42), so `CI required`'s guarantee is unchanged, not scoped down — closure here can only ever be genuine, never definitional. Red `needs:` count 3, identical to round 3's 3 (delta 0), against this round's stated target of 1: the target was MISSED, and the pre-push prediction of 2 was FALSIFIED. 4 of the originally-7 red baseline jobs are green (unchanged from round 3). PR #31 (`ci/198-round4`, draft, DO NOT MERGE) `mergeStateStatus`: `BLOCKED`; `origin/main` is 137 commits behind the measured head. This requirement is NOT marked Complete on any basis. See `198-CI-MEASUREMENT.md`'s Round 4 section for the full five-column comparison.**
- [x] **GREEN-08**: Branch protection requires exactly the check names CI emits, verified after the matrix has reported once, so no pull request can be blocked on a check that cannot exist.
- [x] **GREEN-09**: Paid critic scoring cannot be triggered from any workflow while it is parked — the input and the billing code path are absent, not merely defaulted off.
- [x] **GREEN-10**: Exactly one Hex publish path exists, and it is the one gated by CI-green and release-shape verification.
- [x] **GREEN-11**: Flake Detection distinguishes "suite is broken" from "suite is flaky" by name, is time-bounded, and surfaces failures to a deduplicated tracking issue instead of failing silently.
- [x] **GREEN-12**: `git worktree list` shows one entry and no stale local branches remain; any unmerged branch is either landed or preserved under an archive tag with a recorded recommendation, never silently discarded.

### Decouple

- [ ] **DECOUPLE-01**: `mix ci.all` passes with `.planning/` renamed away, proving no gate reads the planning directory.
- [ ] **DECOUPLE-02**: All five load-bearing datasets live under `test/fixtures/`, moved with `git mv`, with every reader updated in the same commit and none of them entering the Hex tarball.
- [ ] **DECOUPLE-03**: Dead planning artifacts are removed with `git rm` and no register or doc cites a path that no longer exists.
- [ ] **DECOUPLE-04**: The repository root contains no one-off migration or patch scripts, and the test assertion one of them silently disabled is enabled and passing.
- [ ] **DECOUPLE-05**: A fresh clone plus `mix deps.get` leaves `git status` clean — generated artifacts, crash dumps, build tarballs and e2e artifacts are all ignored.
- [ ] **DECOUPLE-06**: `mix format --check-formatted` covers `bench/`, `scripts/`, and the example app, not only `lib/`, `test/` and `config/`.
- [ ] **DECOUPLE-07**: `mix dialyzer` runs as part of `ci.all` with all optional dependencies in the PLT, and its documented cold-build cost is measured rather than estimated.
- [ ] **DECOUPLE-08**: Dialyzer's ignore file contains only specific, individually-commented entries under a committed ceiling that can only be lowered.

### Public Surface

- [ ] **SURFACE-01**: No published `@moduledoc` or `@doc` contains phase numbers, decision IDs, requirement IDs, or milestone literals.
- [ ] **SURFACE-02**: The Hex tarball contains no planning vocabulary, including in `mix.exs` comments and identifiers.
- [ ] **SURFACE-03**: Maintainer-only design-system and critic tooling is absent from the public HexDocs index.
- [ ] **SURFACE-04**: Every module page generated by ExDoc appears in a named group.
- [ ] **SURFACE-05**: `DESIGN-SYSTEM.md` and the reference-app README are reachable from HexDocs.
- [ ] **SURFACE-06**: Every guide has at least one outbound link and one inbound link other than the README, and no relative link between docs is broken.
- [ ] **SURFACE-07**: Every module, mix alias, and `:threadline` config key referenced by public docs exists, and every supported config key and alias is documented somewhere public.
- [ ] **SURFACE-08**: A contributor who hits the `(undefined_table) relation "audit_changes" does not exist` error finds the fix by searching the error string in the repository's own docs.
- [ ] **SURFACE-09**: Install instructions, operator-surface overview, and local Docker setup each have one canonical home, with other mentions pointing to it.
- [ ] **SURFACE-10**: `CONTRIBUTING.md` describes a contributor workflow that requires no knowledge of `.planning/`.
- [ ] **SURFACE-11**: The repository provides a pull-request template, issue templates, a security policy, and a code of conduct.

### Rendered Output

- [ ] **RENDER-01**: No operator page renders a phase number, decision ID, or internal taxonomy label in visible text.
- [ ] **RENDER-02**: No rendered DOM carries planning-provenance attributes.
- [ ] **RENDER-03**: The emitted CSS contains no phase or milestone provenance comments.
- [ ] **RENDER-04**: Attribute-only and comment-only removals are proven not to move the mechanical floor, passing against an unmodified scorecard set.
- [ ] **RENDER-05**: Any text change that does move a measured value is absorbed by narrowing the check or by a registered, counted whitelist entry with a stated expiry — never by regenerating a capture that this environment cannot reproduce.
- [ ] **RENDER-06**: No operator page's element structure, layout, or visual appearance changes — only text content and non-visual attributes.

### Release

- [ ] **RELEASE-01**: Threadline 0.10.0 is published on hex.pm with clean, grouped HexDocs.
- [ ] **RELEASE-02**: Every version-bearing line in the repository is managed by release automation, so a version bump requires no hand edits.
- [ ] **RELEASE-03**: The Hex evaluator smoke test validates the newly published release rather than silently continuing to validate its predecessor.
- [ ] **RELEASE-04**: The 0.10.0 changelog entry opens with human-written highlights above the generated commit list.
- [ ] **RELEASE-05**: Release-shape and post-publish distribution-sync checks pass against the published tarball.

### Real Gates

- [ ] **GATE-01**: `mix credo --strict` runs Credo's full default check set, with project adjustments expressed as deltas so a future Credo release cannot silently drop checks.
- [ ] **GATE-02**: Every Credo finding is either fixed or recorded as a register row carrying an exact count and a named successor milestone — no check is silently disabled.
- [ ] **GATE-03**: No module in the capture, semantics, query, or export layers references the operator-surface namespace.
- [ ] **GATE-04**: The Capture↔Semantics module cycle is resolved and its compiler suppression removed rather than relocated.
- [ ] **GATE-05**: No comment in `lib/` cites a file location whose referent has moved, and every module has a deliberate `@moduledoc` or `@moduledoc false`.

### Structure

- [ ] **STRUCT-01**: The emitted CSS is locked by a committed content hash gated in `ci.all`, proving byte-equality across refactors.
- [ ] **STRUCT-02**: The style module is split into ordered, individually-legible segments with the CSS hash unchanged at every intermediate commit.
- [ ] **STRUCT-03**: No file in `lib/` exceeds roughly 800 lines and no function roughly 120 lines, or the exception is named with a stated reason.
- [ ] **STRUCT-04**: Separator comments no longer stand in for module or function boundaries in `lib/`.
- [ ] **STRUCT-05**: Test files share endpoint and router case templates from `test/support/` instead of hand-rolling their own, except where a per-file difference is deliberate and documented.
- [ ] **STRUCT-06**: `ci.all` contains no step that re-runs assertions another step already ran, and no second, drift-prone definition of which contract tests matter.

## Future Requirements

Deferred; tracked but not in this roadmap.

### Type Coverage

- **TYPES-01**: `@spec` coverage is measured and gated (Credo's opt-in `Readability.Specs` — currently 76 specs across 17 of 105 files; a multi-month project of its own).

### Operator Surface

- **UI-01**: Evidence page structural density (v1.40 register rank 3) — an information-architecture pass, not chrome removal. Requires operator-UI bandwidth.
- **UI-02**: SEED-005 — mount `reconnect_banner/1` at the shell, mark real mutating controls, and replace the computed-CSS probe with a true socket-drop end-to-end test.

### Critic Tooling

- **CRITIC-01**: Re-validate the `color_contrast` (ρ 0.698) and `hierarchy` (ρ 0.42) lenses against a fresh synthetic oracle, or retire them.
- **CRITIC-02**: Resume the parked paid iteration loop if and only if spend/value is explicitly reconsidered.

### Schema Fidelity

- **SCHEMA-01**: Alternate-schema test fixtures apply the real generated migrations rather than `CREATE TABLE ... LIKE ... INCLUDING ALL`, so schema-local foreign-key constraints are proven (v1.39 R-B / WR-01).

## Out of Scope

| Feature | Reason |
|---------|--------|
| Operator UI design, IA, layout, or visual change | No maintainer bandwidth this milestone. Cleanup inside those files is in scope; design decisions are not. |
| Regenerating Tier-A `page.*` scorecards | Not reproducible in this environment (v1.40 Seed #3). The committed scorecards are the floor; regenerating them would manufacture a floor rather than measure one. |
| Paid critic scoring | Parked on ratified spend/value grounds at v1.40 close. This milestone makes it structurally untriggerable, not merely discouraged. |
| Untracking `.planning/` from git | Deliberately retained as project history. The milestone removes its load-bearing role, not its record. |
| Rewriting git history to purge large blobs | Publishing accepted as-is; a history rewrite on a public repo is a far larger and riskier operation than this milestone's goal requires. |
| Enabling Credo's opt-in check set | One ratchet click at a time — full defaults first. `Readability.Specs` and friends are deferred to TYPES-01. |
| External adopter pilot | Still signal-gated; no adopter signal on record. |
| Compliance packs, legal hold, immutable archive | Deferred until procurement or adopter pressure justifies the support burden. |
| New product surface or capture/query/auth semantic changes | This is a consolidation milestone; behavior stays fixed unless a truth or schema inconsistency forces a change. |
| Elixir/OTP version-floor bumps | Would strand 1.15 adopters (decision D-14). |

## Traceability

Populated during roadmap creation (2026-08-27). Every v1.41 requirement maps to exactly one phase; no orphans, no duplicates. Phase boundaries follow the category names with four deliberate exceptions, verified individually:

- **GREEN-02** (Credo per-check histogram) and **GREEN-03** (mechanical-sensitivity probe) are *measurement* requirements executed in Phase 198 that **size** Phases 203 and 201 respectively. They belong to 198, where the measurement happens — not to the phases they inform.
- **GREEN-09** (paid scoring structurally untriggerable) and **GREEN-10** (exactly one publish path) concern release safety but are workflow changes made in Phase 198, before anything is published. Leaving them to Phase 202 would mean the ungated publish path survives right up to the moment it could fire.
- **DECOUPLE-07** / **DECOUPLE-08** are dialyzer *adoption* (gate wiring, PLT, measured cold-build cost, ratcheting ignore ceiling), landed in Phase 199 so dialyzer typechecks the 201/203/204 refactors. Draining the findings surfaced by the gates is covered by **GATE-02**'s "fix or register with an exact count and a named successor milestone" discipline in Phase 203.

| Requirement | Phase | Status |
|-------------|-------|--------|
| GREEN-01 | Phase 198 | Complete |
| GREEN-02 | Phase 198 | Complete |
| GREEN-03 | Phase 198 | Complete |
| GREEN-04 | Phase 198 | Pending (Run test suite (current) `failure` — third distinct cause: CI-only 60s ExUnit timeout in demo_reset_test.exs:56; search_path and demo-seed causes both closed — see CI run 33253587315) |
| GREEN-05 | Phase 198 | Complete |
| GREEN-06 | Phase 198 | Complete |
| GREEN-07 | Phase 198 | Pending (CI required `failure`, 3/12 needs: red — verify-test, verify-example-browser, verify-capture; ≤20min clause met at 8m11s; Tier A blocked by D-39; needs: not narrowed — see CI run 33253587315) |
| GREEN-08 | Phase 198 | Complete |
| GREEN-09 | Phase 198 | Complete |
| GREEN-10 | Phase 198 | Complete |
| GREEN-11 | Phase 198 | Complete |
| GREEN-12 | Phase 198 | Complete |
| DECOUPLE-01 | Phase 199 | Pending |
| DECOUPLE-02 | Phase 199 | Pending |
| DECOUPLE-03 | Phase 199 | Pending |
| DECOUPLE-04 | Phase 199 | Pending |
| DECOUPLE-05 | Phase 199 | Pending |
| DECOUPLE-06 | Phase 199 | Pending |
| DECOUPLE-07 | Phase 199 | Pending |
| DECOUPLE-08 | Phase 199 | Pending |
| SURFACE-01 | Phase 200 | Pending |
| SURFACE-02 | Phase 200 | Pending |
| SURFACE-03 | Phase 200 | Pending |
| SURFACE-04 | Phase 200 | Pending |
| SURFACE-05 | Phase 200 | Pending |
| SURFACE-06 | Phase 200 | Pending |
| SURFACE-07 | Phase 200 | Pending |
| SURFACE-08 | Phase 200 | Pending |
| SURFACE-09 | Phase 200 | Pending |
| SURFACE-10 | Phase 200 | Pending |
| SURFACE-11 | Phase 200 | Pending |
| RENDER-01 | Phase 201 | Pending |
| RENDER-02 | Phase 201 | Pending |
| RENDER-03 | Phase 201 | Pending |
| RENDER-04 | Phase 201 | Pending |
| RENDER-05 | Phase 201 | Pending |
| RENDER-06 | Phase 201 | Pending |
| RELEASE-01 | Phase 202 | Pending |
| RELEASE-02 | Phase 202 | Pending |
| RELEASE-03 | Phase 202 | Pending |
| RELEASE-04 | Phase 202 | Pending |
| RELEASE-05 | Phase 202 | Pending |
| GATE-01 | Phase 203 | Pending |
| GATE-02 | Phase 203 | Pending |
| GATE-03 | Phase 203 | Pending |
| GATE-04 | Phase 203 | Pending |
| GATE-05 | Phase 203 | Pending |
| STRUCT-01 | Phase 204 | Pending |
| STRUCT-02 | Phase 204 | Pending |
| STRUCT-03 | Phase 204 | Pending |
| STRUCT-04 | Phase 204 | Pending |
| STRUCT-05 | Phase 204 | Pending |
| STRUCT-06 | Phase 204 | Pending |

**Coverage:**

- v1.41 requirements: 53 total (GREEN 12, DECOUPLE 8, SURFACE 11, RENDER 6, RELEASE 5, GATE 5, STRUCT 6)
- Mapped to phases: 53 ✓
- Unmapped: 0

**Per-phase distribution:**

| Phase | Name | Requirements | Count |
|-------|------|--------------|-------|
| 198 | Green Bringup | GREEN-01..GREEN-12 | 12 |
| 199 | Decouple | DECOUPLE-01..DECOUPLE-08 | 8 |
| 200 | Public Surface | SURFACE-01..SURFACE-11 | 11 |
| 201 | Rendered Output | RENDER-01..RENDER-06 | 6 |
| 202 | Release 0.10.0 | RELEASE-01..RELEASE-05 | 5 |
| 203 | Real Gates | GATE-01..GATE-05 | 5 |
| 204 | Structure | STRUCT-01..STRUCT-06 | 6 |
| | **Total** | | **53** |

---
*Requirements defined: 2026-08-27*
*Last updated: 2026-08-27 at roadmap creation (Phases 198-204 mapped, 53/53)*
