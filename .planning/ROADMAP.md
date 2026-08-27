# Roadmap: Threadline

## Milestones

- 🚧 **v1.41 Green, Clean, and Honest** - Phases 198-204 (in progress, opened 2026-08-27)
- [x] **v1.40 Automated Operator-UI Critique & Forward-Only Iteration Harness** - Phases 194-197 (shipped 2026-08-27). Archive: `.planning/milestones/v1.40-ROADMAP.md`
- [x] **v1.39 Quality Baseline, Schema Confidence, and CI Efficiency** - Phases 189-193 (shipped 2026-07-03). Archive: `.planning/milestones/v1.39-ROADMAP.md`
- [x] **v1.38 Operator UI Page-by-Page IA & Design-System Polish** - Phases 181-188 (shipped 2026-06-30). Archive: `.planning/milestones/v1.38-ROADMAP.md`
- [x] **v1.37 Operator Surface Design-System Stress Test & Component System** - Phases 171-180 (shipped 2026-06-20). Archive: `.planning/milestones/v1.37-ROADMAP.md`
- [x] **v1.36 Operator Surface Light Mode** - Phases 166-170 (shipped 2026-06-14). Archive: `.planning/milestones/v1.36-ROADMAP.md`
- [x] **v1.35 Unified Logo & Brand Book v2** - Phases 159-165 (shipped 2026-06-12). Archive: `.planning/milestones/v1.35-ROADMAP.md`
- [x] **v1.34 Local Docker Admin UI DX** - Phases 154-158 (shipped 2026-06-07). Archive: `.planning/milestones/v1.34-ROADMAP.md`

## 🚧 v1.41 Green, Clean, and Honest (In Progress)

**Milestone Goal:** Get the repository into a genuinely clean, green, publishable state — then ratchet software quality across every technical stakeholder lens (architecture, engineering, DX, CI/CD, code quality, docs) wherever the improvement can be made mechanical and gated. Core capture/query/auth semantics stay fixed unless a truth or schema inconsistency forces a change.

**Granularity:** coarse (7 phases, est. 26-33 plans — in line with v1.39's 5/21 and v1.40's 4/21).

**Why this milestone exists.** Three exploration passes found the repo in worse shape than "needs tidying": `.credo.exs` uses `checks: %{enabled: [...]}`, which *replaces* Credo's defaults rather than extending them, so `mix credo --strict` runs **2 checks on 253 files in 0.1s**, always passes, and sits in `ci.all` as a gate that lints almost nothing (root cause verified in `deps/credo/lib/credo/config_file.ex:377-385` — `merge_checks/2` binds `checks_base` and never references it; the correct keys are `extra:`/`disabled:`). `origin/main` has been red since 2026-06-26 and is **-584 commits** behind local. ~370 planning-vocabulary hits reach shipped source — public `@moduledoc`s, `mix.exs` (including the function name `verify_phase177_uat`), rendered page headings, `data-jtbd` DOM attributes, and CSS comments. Nine test files read `.planning/` at runtime, two of them inside `ci.all`. Two Hex publish paths exist and the ungated one wins the race.

### Dependency spine (non-negotiable)

```
198 Green Bringup ──┬─→ 199 Decouple ──→ 200 Public Surface ──→ 201 Rendered Output ──→ 202 Release 0.10.0 ──→ 203 Real Gates ──→ 204 Structure
                    │       (dialyxir lands here, so it typechecks 201/203/204)
                    └─ 198 Plan 01 measurement sizes 203 (Credo histogram) and 201 (mechanical-sensitivity probe)
```

- **198 first** because nothing else is verifiable while `origin/main` is red, PR #26 is blocked, and a 1h33m CI run makes every subsequent phase's feedback loop unusable.
- **199 before 200/201** because CONTRIBUTING cannot truthfully drop its 19 `.planning/` references until the fixtures have actually moved.
- **199 lands dialyxir** deliberately early, so it typechecks the 201/203/204 refactors rather than arriving after the fall.
- **202 sits in the middle, and this ordering is contested.** 198 delivers the *stated* goal (unblock PR #26); merging and publishing are a separate act, and release-please keeps the PR current for free. Cutting **before** 200/201 would permanently publish `verify_phase177_uat` in the shipped `mix.exs`, `D-06`/`D-12`/`D-20`/`D-30a` in HexDocs, a `@doc` pointing at a directory that is not in the tarball, six maintainer-only modules on the public index, ~90 ungrouped module pages, and no `DESIGN-SYSTEM.md`. **hex.pm has no undo.** Cutting **after** 203/204 would strand a real 180-lib-commit release behind two open-ended refactors. So: publish once the permanent (200) and rendered (201) surfaces are clean, before the invisible internal work. **0.10.0 is the clean release; 0.11.0 is the ratcheted one.**
- **203 before 204** so that Credo's full defaults are the thing that surfaces structural findings — and any finding whose fix requires extracting a module or splitting a function is *filed* to 204, not fixed in 203, or 203 swallows 204.

### Two workloads are deliberately unmeasured at roadmap time

This roadmap quotes no estimate for the **full-default Credo backlog** or the **dialyzer finding count**, because neither has been measured. Inventing a number here would be exactly the dishonesty this milestone exists to remove.

- The Credo backlog is measured in **198 Plan 01**, from a full-default config held *outside* the repo (`--config-file` replaces rather than merges, so `.credo.exs` is never modified), as a per-check histogram plus a per-file concentration table.
- The dialyzer count is measured in **199**, on the first real cold-PLT build with all 9 optional deps in the PLT.

**Pre-committed sizing rule for Phase 203** (so the resize is not a later judgment call):

| Measured findings | Phase 203 shape |
|---|---|
| < 150 | Fix all in one phase |
| 150-600 | Split mechanical (`Readability.*`/`Consistency.*`) from judgment (`Refactor.*`/`Warning.*`/`Design.*`) |
| > 600, or one dominating check | Adopt full defaults with that check documented as a **register row carrying an exact count and a named successor milestone** |

A counted, documented exclusion is honest. A config that runs 2 checks in 0.1s and calls itself a gate is not.

**Phase 201's cost is likewise unknown until 198 Plan 01 answers one question:** is `verify.mechanical` sensitive to rendered *text content and text width*, or only to tokens, contrast, and element geometry? Tier 1 (attributes and CSS comments) is provably geometry-neutral either way; Tier 2 (visible text) is cheap if the answer is "geometry only" and expensive if not. The roadmap does not guess.

### Cross-cutting invariants (hold in every phase's constraints)

- **No operator-UI design, IA, layout, or visual change.** Cleanup *inside* those files is in scope; design decisions are not.
- **No Tier-A `page.*` scorecard regeneration.** Per v1.40 Seed #3 recapture is not reproducible in this environment; the committed scorecards **are** the floor. Regenerating them would manufacture a floor rather than measure one.
- **Paid critic scoring stays PARKED** and is made structurally untriggerable (input and billing code path absent), not merely defaulted off.
- **`.planning/` stays tracked.** The milestone removes its load-bearing role, not its record.
- **No git history rewrite.** Publishing is accepted as-is.
- **No capture/query/auth semantic change, no new product surface,** unless a truth or schema inconsistency forces it.
- **No Elixir/OTP version-floor bump** (would strand 1.15 adopters, decision D-14).
- **Conventions:** `git mv` for every move, `git rm` for every removal, and **one file per commit wherever contract tests are involved**, so a bisect isolates a regression.

### Phases

- [ ] **Phase 198: Green Bringup** - `origin/main` carries all 584 local commits and CI concludes green in ≤ 20 min; the never-re-measured red-test baseline is retired on its merits; branch protection is repaired against the checks CI actually emits; worktrees, branches, and locks are triaged.
- [ ] **Phase 199: Decouple** - Tests and gates are self-contained in the source tree, proven by `mix ci.all` passing with `.planning/` renamed away; `.planning/` stays tracked but load-bearing on nothing; dialyxir lands early enough to typecheck the later refactors.
- [ ] **Phase 200: Public Surface** - Everything a stranger or hex.pm consumer sees is accurate, navigable, and free of internal vocabulary — *before* anything is published. This is the phase that earns the right to release.
- [ ] **Phase 201: Rendered Output** - Zero internal vocabulary reaches a browser, with zero design/IA/visual change, in two tiers separated by mechanical-floor blast radius.
- [ ] **Phase 202: Release 0.10.0** - Merge PR #26 and publish a release whose public surface is already clean, with every version-bearing literal managed by release automation and exactly one publish path.
- [ ] **Phase 203: Real Gates** - Full Credo defaults expressed as `extra:`/`disabled:` deltas, the dialyzer backlog drained, and the layer inversions plus the Capture↔Semantics cycle fixed.
- [ ] **Phase 204: Structure** - Make the largest files legible without changing a byte of output, behind an executable CSS byte-hash lock.

## Phase Details

### Phase 198: Green Bringup

**Goal**: `origin/main` carries every local commit and its CI concludes green well inside a usable feedback loop; the red-test baseline that nobody re-derived is retired with each former failure fixed on its merits; branch protection requires exactly the checks CI emits; and the measurement sweep that sizes Phases 201 and 203 is on disk before either is planned.
**Depends on**: Nothing (first phase of v1.41)
**Requirements**: GREEN-01, GREEN-02, GREEN-03, GREEN-04, GREEN-05, GREEN-06, GREEN-07, GREEN-08, GREEN-09, GREEN-10, GREEN-11, GREEN-12
**Success Criteria** (what must be TRUE):

  1. Maintainer can read the last red run's failing logs from the repository after GitHub purges them, and can read a measured per-check Credo histogram, a per-file concentration table, and an evidence-backed statement of whether `verify.mechanical` is sensitive to text content and width or only to tokens, contrast, and geometry — with `.credo.exs` unmodified and no scorecard touched. (GREEN-01, GREEN-02, GREEN-03)
  2. `mix test` passes with no deterministically-failing tests, each former failure fixed rather than skipped — version-pinned milestone literals replaced by shape assertions that cannot rot at the next milestone, and a page that legitimately gains a form fails the formless-page guard loudly in the same diff instead of needing a hand-edited allowlist elsewhere. (GREEN-04, GREEN-05)
  3. `git log origin/main..main` is empty and the latest `main` run concludes `success` in ≤ 20 minutes (target ≤ 12), with every job carrying a `timeout-minutes` bound and a systemically-broken browser suite aborting early rather than accumulating per-test timeouts. (GREEN-06, GREEN-07)
  4. Branch protection requires exactly the check names CI emits, verified after the matrix has reported once, so PR #26 is mergeable and no future pull request can be blocked on a check that cannot exist. (GREEN-08)
  5. Paid critic scoring cannot be triggered from any workflow — the input and the billing code path are absent, not defaulted off — and exactly one Hex publish path exists, the one gated by CI-green and release-shape verification. (GREEN-09, GREEN-10)
  6. Flake Detection distinguishes "suite is broken" from "suite is flaky" by name, is time-bounded, and surfaces failures to a deduplicated tracking issue; `git worktree list` shows one entry, no stale local branches remain, and any unmerged branch is landed or preserved under an archive tag with a recorded recommendation — never silently discarded. (GREEN-11, GREEN-12)

**Plans**: TBD (est. 5 — measurement sweep · red-baseline retirement · CI cost surgery · staging-PR bringup · triage)

**Notes carried from the approved plan:**
- Plan 01 is read-only and runs first because it sizes Phases 201 and 203. The 2026-06-26 run log is ~62 days old against a 90-day purge — preserving it is a ~4-week window, not a nice-to-have.
- The bringup validates on `ci/v1_41-green-bringup` → PR before `main` is touched, because `ci.yml` triggers on `pull_request: [main]` with `cancel-in-progress`, making iterations cancellable.
- **Hard gate before publishing:** the 54 MB of `.planning/` has never been audited for credentials and is about to become fully public.
- `gsd/phase-166-unfreeze-token-lane-mechanism` (`dd5b48be`) is verified *not* an ancestor of `main` — real unmerged work. It gets a diff, a summary, and a merge-or-archive recommendation **before** anything is removed.
- **Highest-variance risk in the milestone:** the `min` lane (Elixir 1.15 / OTP 26 / pg14 / ubuntu-22.04) has **never executed on origin**. Expect novel failures. If the cause turns out to be runner or Playwright-version drift, the fallback is moving the browser lanes off the PR trigger onto nightly.

**UI hint**: no

### Phase 199: Decouple

**Goal**: The test suite and every CI gate are self-contained in the source tree, so `mix ci.all` passes with `.planning/` renamed away; the dead planning artifacts and one-off root scripts are gone with their citations repaired; a fresh clone plus `mix deps.get` leaves `git status` clean; and dialyzer is a real, measured, ratcheting gate before the refactor-heavy phases begin.
**Depends on**: Phase 198 (a green, fast CI is the only way to trust that a fixture move broke nothing)
**Requirements**: DECOUPLE-01, DECOUPLE-02, DECOUPLE-03, DECOUPLE-04, DECOUPLE-05, DECOUPLE-06, DECOUPLE-07, DECOUPLE-08
**Success Criteria** (what must be TRUE):

  1. `mix ci.all` passes with `.planning/` renamed away — the only real proof that no gate reads the planning directory — and all five load-bearing datasets live under `test/fixtures/`, moved with `git mv`, every reader updated in the same commit, none of them entering the Hex tarball. (DECOUPLE-01, DECOUPLE-02)
  2. Dead planning artifacts are removed with `git rm`, no register or doc cites a path that no longer exists, the repository root holds no one-off migration or patch scripts, and the test assertion one of them silently disabled is enabled and passing. (DECOUPLE-03, DECOUPLE-04)
  3. A fresh clone plus `mix deps.get` leaves `git status` clean — generated artifacts, crash dumps, build tarballs, and the 596 MB of e2e artifacts are all ignored — and `mix format --check-formatted` covers `bench/`, `scripts/`, and the example app, not only `lib/`, `test/`, and `config/`. (DECOUPLE-05, DECOUPLE-06)
  4. `mix dialyzer` runs inside `ci.all` with all optional dependencies in the PLT, its cold-build cost is measured rather than estimated and documented in CONTRIBUTING, and its ignore file holds only specific, individually-commented entries under a committed ceiling that can only be lowered. (DECOUPLE-07, DECOUPLE-08)

**Plans**: TBD (est. 4 — fixture relocation · dead-artifact removal and root-script cleanup · ignore/format hygiene · dialyxir adoption and finding triage)

**Notes carried from the approved plan:**
- `test/fixtures/`, **not** `priv/`: none of it is runtime library data and 3.2 MB must not enter the Hex tarball. Grep every literal (`scorecards`, `design-system-ledger`, `golden-set`, `refute-set`, `critic-scores`) across `lib/`, `test/`, `mix.exs`, `.github/`, and `examples/` before moving, and verify `package.files` still excludes the destination.
- `plt_add_apps` must list **all 9 optional deps explicitly** — they are not in the runtime tree, so every `Phoenix.Component`/`Oban`/`ExAws` call would otherwise become `unknown_function`. Analyse the full build only, never `--no-optional-deps` (`style.ex:1` is `if Code.ensure_loaded?(Phoenix.LiveView)`, so the module set genuinely differs). PLT cache keyed on `otp-${{matrix.otp}}` — PLTs are not portable across OTP versions. Run on the `current` lane only.
- Triage every dialyzer finding: `:unmatched_returns`/`:extra_return` surface real bugs. Fix what is real; only irreducible residue goes in `.dialyzer_ignore.exs`, one commented entry each, **no wildcards**, under a ratchet-down-only ceiling test (same idiom as the MODE-B floors).

**UI hint**: no

### Phase 200: Public Surface

**Goal**: Everything a stranger or a hex.pm consumer sees — module docs, the tarball, the HexDocs index and its grouping, the guide graph, the config and alias vocabulary, the contributor onboarding path, and the `.github/` directory — is accurate, navigable, and free of internal planning vocabulary, so that publishing 0.10.0 in Phase 202 is safe rather than permanent regret.
**Depends on**: Phase 199 (CONTRIBUTING cannot truthfully drop its `.planning/` references until the fixtures have moved)
**Requirements**: SURFACE-01, SURFACE-02, SURFACE-03, SURFACE-04, SURFACE-05, SURFACE-06, SURFACE-07, SURFACE-08, SURFACE-09, SURFACE-10, SURFACE-11
**Success Criteria** (what must be TRUE):

  1. No published `@moduledoc` or `@doc` contains a phase number, decision ID, requirement ID, or milestone literal, and `mix hex.build` plus unpack shows a tarball free of planning vocabulary — including in `mix.exs` comments and identifiers. (SURFACE-01, SURFACE-02)
  2. Maintainer-only design-system and critic tooling is absent from the public HexDocs index, every module page ExDoc generates appears in a named group, and `DESIGN-SYSTEM.md` plus the reference-app README are reachable from HexDocs. (SURFACE-03, SURFACE-04, SURFACE-05)
  3. Every guide has at least one outbound link and one inbound link other than the README, no relative link between docs is broken, every module / mix alias / `:threadline` config key referenced by public docs exists, and every supported config key and alias is documented somewhere public. (SURFACE-06, SURFACE-07)
  4. A contributor who hits `(undefined_table) relation "audit_changes" does not exist` finds the fix by searching that error string in the repository's own docs, and install instructions, operator-surface overview, and local Docker setup each have exactly one canonical home with other mentions pointing to it. (SURFACE-08, SURFACE-09)
  5. `CONTRIBUTING.md` describes a contributor workflow requiring no knowledge of `.planning/`, and the repository provides a pull-request template, issue templates, a security policy, and a code of conduct. (SURFACE-10, SURFACE-11)

**Plans**: TBD (est. 5 — moduledoc/mix.exs vocabulary strip · ExDoc grouping and extras · docs-graph repair and link fixes · config/alias/`search_path` documentation and deduplication · `.github/` templates and CONTRIBUTING rewrite)

**Notes carried from the approved plan:**
- Known offenders: `capture/trigger_sql.ex:7,10`, `export_auth_plug.ex:12`, `coverage/snapshot.ex:8`, `coverage/on_mount.ex:36,38`, `evidence/subject.ex:28`, `router.ex:40`, `threadline.gen.triggers.ex:52`, `ui.ex:402,510,794`; `mix/tasks/critic.synth.ex:19` points at a directory that is not in the tarball; `mix.exs` comments at :34/:97/:102/:107/:194/:223/:235/:359 plus the function name `verify_phase177_uat`.
- Six accidentally-public maintainer-only modules need `@moduledoc false`: `critic_trust/{measure,rank_metrics,ledger_splice,krippendorff_alpha}` and `mix/tasks/critic.{measure,synth}`.
- The docs graph is a star with dead ends — **13 of 19 guides link to nothing**. Broken links at `guides/getting-started-saas.md:345` (wrong `guides/` prefix, also :49 and :380) and `domain-reference.md:88` (`Threadline.Proof` → `Threadline.Evidence.Proof`).
- Three orphan config keys (`:export_status_poll_ms`, `:retention_poll_ms`, `:storage_adapter` — decide whether the last is actually public rather than documenting by default) and five orphan mix aliases.
- Deduplicate Quick Start (4 copies), Operator Surface (3), Docker/DX (3). Fix `CLAUDE.md:71` ("Capture mechanism TBD" — it shipped long ago).

**UI hint**: no

### Phase 201: Rendered Output

**Goal**: No internal vocabulary — phase numbers, decision IDs, JTBD taxonomy labels, provenance attributes, or CSS provenance comments — reaches a browser, achieved in two tiers separated by mechanical-floor blast radius, with element structure, layout, and visual appearance byte-for-byte unchanged.
**Depends on**: Phase 200 (same vocabulary sweep, one surface deeper; and 198 Plan 01's sensitivity probe decides Tier 2's cost)
**Requirements**: RENDER-01, RENDER-02, RENDER-03, RENDER-04, RENDER-05, RENDER-06
**Success Criteria** (what must be TRUE):

  1. No operator page renders a phase number, decision ID, or internal taxonomy label in visible text; no rendered DOM carries a planning-provenance attribute (`grep -rn 'data-jtbd'` empty); and the emitted CSS contains no phase or milestone provenance comment. (RENDER-01, RENDER-02, RENDER-03)
  2. The attribute-only and comment-only removals pass `mix verify.mechanical` against an **unmodified** scorecard set, proving they did not move the mechanical floor. (RENDER-04)
  3. Any text change that does move a measured value is absorbed by narrowing the offending check to be text-length-invariant, or by a registered whitelist entry of at most three named nodes carrying the measured delta and a stated expiry — **never** by regenerating a capture this environment cannot reproduce. (RENDER-05)
  4. No operator page's element structure, layout, or visual appearance changes — node count, tag, classes, and nesting stay byte-identical; only text content and non-visual attributes differ. (RENDER-06)

**Plans**: TBD (est. 3 — Tier 1 attribute/comment/filename removal · Tier 2 text-only renames · whitelist-or-narrow resolution if the probe says text matters)

**Notes carried from the approved plan:**
- **Tier 1 lands alone, first,** because attributes and CSS comments provably cannot move layout: remove `data-jtbd` (`evidence_live.ex:359`, `row_history_live.ex:50`, `timeline_live.ex:750`, `export_status_live.ex:158,201`, `start_live.ex:221,261`) and their 7 test assertions; delete CSS comments (`style.ex:20,166,310,1745`); `git mv` the test filenames (`phase06_nyquist_ci_`, `ia_lock_`, `forward_only_gate_`).
- **Tier 2 is text-only and element-preserving.** `Phase 173 Primitives Matrix` → `Primitives Matrix`; `Phase 176 Data States (DATA-03 taxonomy)` → `Data States`; `stress_fixtures.ex:292,513,582,694`. **Rule: rename, never delete an element.**
- Whether Tier 2 moves a scorecard is answered by 198 Plan 01, not guessed here. If it does: **do not attempt a Tier-A recapture** — v1.40 Seed #3 established that recapture is not reproducible in this environment and the committed `page.*` scorecards *are* the floor. A documented, bounded weakening is honest; a fabricated recapture is not.
- **Highest contract-test blast radius in the milestone:** `style_contract_test.exs` (2130 lines), `copy_contract_test.exs`, `component_contract_test.exs`. Edit source and its contract test in the same commit, one file per commit.

**UI hint**: no — this is a vocabulary-removal pass with an explicit zero-visual-change constraint. Operator-UI design, IA, layout, and visual change are out of scope for the whole milestone, so no phase takes a UI design contract.

### Phase 202: Release 0.10.0

**Goal**: PR #26 is merged and threadline 0.10.0 is published to hex.pm with a public surface that Phases 200 and 201 already made clean, every version-bearing literal managed by release automation so a version bump needs no hand edits, and a changelog a human can read.
**Depends on**: Phase 201 (hex.pm has no undo — publish only once the permanent and rendered surfaces are clean)
**Requirements**: RELEASE-01, RELEASE-02, RELEASE-03, RELEASE-04, RELEASE-05
**Success Criteria** (what must be TRUE):

  1. Threadline 0.10.0 is live on hex.pm with clean, grouped HexDocs. (RELEASE-01)
  2. Every version-bearing line in the repository is managed by release automation, so a version bump requires no hand edits — enforced by `version_truth_doc_contract_test.exs`. (RELEASE-02)
  3. The Hex evaluator smoke test validates the newly published release rather than silently continuing to validate its predecessor. (RELEASE-03)
  4. The 0.10.0 changelog entry opens with human-written highlights above the generated commit list. (RELEASE-04)
  5. Release-shape and post-publish distribution-sync checks pass against the published tarball. (RELEASE-05)

**Plans**: TBD (est. 3 — version-literal wiring before merge · merge and publish · changelog highlights and post-publish sync)

**Notes carried from the approved plan:**
- Verified since `v0.9.0`: 1275 commits — 210 `feat`, 86 `fix`, 1 `perf`, 747 `docs`, 172 `test`, **zero breaking changes**. `0.9.0 → 0.10.0` is correct.
- **Version literals are the real gap.** Only 2 files carry `x-release-please-version` and appear in `release-please-config.json` `extra-files`. `README.md:69`, `getting-started-saas.md:26`, `operator-surface.md:30`, `upgrade-path.md`, `CONTRIBUTING.md:460` and — sharpest — **`priv/ci/hex_evaluator/mix.exs:27`** are unmanaged. That last one pins `{:threadline, "~> 0.9.0"}` *from hex.pm*: after 0.10.0 publishes it would keep validating the previous release forever and silently stop proving the new one. Annotate and wire every version-bearing line **before** merging.
- **CHANGELOG honesty:** release-please emits ~296 bullets. Let it, then hand-write a 5-10 line Highlights block above it (matching the existing hand-written `## [0.8.0]` section) as a follow-up `docs(changelog):` commit on `main`, so it cannot race regeneration.
- Dispatch CI manually on the updated release branch — `bootstrap-release-pr-ci` only fires on `prs_created == 'true'`, and #26 already exists.

**UI hint**: no

### Phase 203: Real Gates

**Goal**: `mix credo --strict` runs Credo's full default check set as a gate with teeth, expressed as deltas so a future Credo release cannot silently drop checks; every finding is fixed or counted; the dialyzer backlog is drained; and the layer inversions and Capture↔Semantics cycle that `Design.AliasUsage` surfaces are actually fixed rather than suppressed.
**Depends on**: Phase 202 (0.10.0 ships clean; the ratcheted release is 0.11.0) and Phase 198 Plan 01 (whose histogram sizes this phase per the pre-committed rule above)
**Requirements**: GATE-01, GATE-02, GATE-03, GATE-04, GATE-05
**Success Criteria** (what must be TRUE):

  1. `mix credo --strict` runs Credo's full default check set, with project adjustments expressed as `extra:`/`disabled:` deltas and never an `enabled:` list, so a future Credo release cannot silently drop checks. (GATE-01)
  2. Every Credo finding is either fixed or recorded as a register row carrying an exact count and a named successor milestone — no check is silently disabled. (GATE-02)
  3. No module in the capture, semantics, query, or export layers references the operator-surface namespace. (GATE-03)
  4. The Capture↔Semantics module cycle is resolved and its compiler suppression removed rather than relocated. (GATE-04)
  5. No comment in `lib/` cites a file location whose referent has moved, and every module has a deliberate `@moduledoc` or `@moduledoc false`. (GATE-05)

**Plans**: TBD (est. 4-6 — **plan count is sized by 198 Plan 01's histogram under the pre-committed rule**, not chosen here)

**Notes carried from the approved plan:**
- Rebuild `.credo.exs` from `deps/credo/.credo.exs` verbatim, then express adjustments as deltas.
- Defensible tuning only: keep `Design.TagTODO` at `exit_status: 0` while `Design.TagFIXME` stays blocking (the honest asymmetry); consider `Design.AliasUsage` `if_called_more_often_than: 2` — but **never disable it**, it is the check that surfaces the layer inversions. `Readability.MaxLineLength` needs no adjustment (`ignore_heredocs`/`ignore_sigils` are already defaults). Do **not** enable the opt-in set (`Readability.Specs` etc.) in the same change — one ratchet click at a time; that is deferred to TYPES-01.
- **Hard rule:** any finding whose fix requires extracting a module or splitting a function is *filed* to Phase 204, not fixed here — otherwise 203 swallows 204.
- The layer inversions are the real work: `query.ex:34` → `OperatorSurface.Scope`, `export/orchestrator.ex:8` → `OperatorSurface.Exports.FilterParams`, `critic.synth.ex:30` → `OperatorSurface.StressFixtures`. Delete — do not relocate — the `@compile {:no_warn_undefined, ...}` at `capture/audit_transaction.ex:57` papering the Capture↔Semantics cycle, and verify preload behaviour before assuming it is cosmetic.
- Stale comments citing moved line ranges: `exports/filter_params.ex:121`, `controllers/export_controller.ex:361`. Three modules are missing `@moduledoc`.

**UI hint**: no

### Phase 204: Structure

**Goal**: The largest files become legible — `style.ex` split behind an executable byte-hash lock, the render monsters extracted, separator comments replaced by real boundaries, shared test case templates adopted — without changing a byte of output, and with the redundant second definition of "which contract tests matter" deleted rather than preserved.
**Depends on**: Phase 203 (full-Credo findings requiring extraction are filed here) and Phase 199 (dialyzer typechecks each refactor)
**Requirements**: STRUCT-01, STRUCT-02, STRUCT-03, STRUCT-04, STRUCT-05, STRUCT-06
**Success Criteria** (what must be TRUE):

  1. The emitted CSS is locked by a committed content hash gated in `ci.all`, proving byte-equality across refactors, and the style module is split into ordered, individually-legible segments with that hash unchanged at every intermediate commit. (STRUCT-01, STRUCT-02)
  2. No file in `lib/` exceeds roughly 800 lines and no function roughly 120 lines, or the exception is named with a stated reason; and separator comments no longer stand in for module or function boundaries in `lib/`. (STRUCT-03, STRUCT-04)
  3. Test files share endpoint and router case templates from `test/support/` instead of hand-rolling their own, except where a per-file difference is deliberate and documented. (STRUCT-05)
  4. `ci.all` contains no step that re-runs assertions another step already ran, and no second, drift-prone definition of which contract tests matter. (STRUCT-06)

**Plans**: TBD (est. 5 — CSS hash freeze · style-source test indirection · mechanical style split · render-monster extraction and banner-comment removal · shared case templates and `verify.doc_contract` deletion)

**Notes carried from the approved plan:**
- **Reframed:** the mechanics pass verified in Credo 1.7.18 source that **no Credo check forces the `style.ex` split** — `LongQuoteBlocks` matches only `:quote` nodes (never `sigil_H`), `css/1` has cyclomatic complexity **1**, Credo has no function-length check, and `MaxLineLength` ignores heredocs and sigils by default. This is a *legibility* goal (a 4,510-line file with one 4,493-line function), not a gate requirement — which lowers its urgency and means it must be done only if it can be done provably safely.
- **The split, in four independently revertible commits:** (1) **freeze the bytes first** — commit a SHA-256 test over `Style.css/1`'s rendered output across the full theme matrix *before touching anything*, pinning or stubbing `Fonts.face_css()` for determinism; this converts "byte-stable frozen" from a milestone convention into an executable gate, strictly stronger than today's source-text assertions. **If the hash cannot be made stable, stop** — that means the frozen invariant was never verifiable, which is itself the finding. (2) Introduce `style_source/0` in `style_contract_test.exs` with `@style_sources` still one element, proving the suite green, isolating the test refactor from the code refactor and avoiding a rewrite of 40+ `File.read!(@style_path)` sites. (3) Split mechanically into ordered `defp` segments returning plain heredocs — everything after `{@fonts_html}<style>` is static, no `:for`, no `:if`, one interpolation point — **splitting at the existing section markers**, because assertions at lines 198-200, 215-217, 265-267, 291-293, 522-524, 1259-1261 slice on them and assume adjacency; use an explicit ordered list, never `Path.wildcard` ordering. (4) Prove the hash and the suite.
- Render monsters: `stress_live.ex:79` (540 lines), `export_status_live.ex:115` (244), `timeline_live.ex:636` (201), and six more ≥135. 33 banner comments stand in for module boundaries. 17 test files hand-roll `Phoenix.Endpoint` and 19 hand-roll `Phoenix.Router` — migrate one file per commit, since a per-file config difference may be load-bearing.
- **`verify.doc_contract`: delete it, do not glob it.** Verified: `mix.exs` sets no `test_paths`, so `mix test` already runs all 44 `*_contract_test.exs`. The alias re-runs 22 of them a third step later in the same `ci.all` chain — 100% redundant — and the 20-file gap (register row D-197-B) went unnoticed for exactly as long as it did *because* the duplication made it look like something was being checked that `mix test` was already checking. Glob-ifying preserves the cause. Remove it from `aliases/0`, `ci.all`, `preferred_cli_env`, the `verify-test` job step, and the docs that cite it.

**UI hint**: no

## Verification

- **Per phase:** `mix ci.all` green on a clean tree, plus that phase's own success criteria.
- **Decoupling (199):** `mix ci.all` green with `.planning/` renamed away — the only real proof.
- **Vocabulary (200/201):** planning-vocabulary grep clean over doc attributes and rendered output; `mix hex.build` plus unpack inspected for `Phase N` and `D-NN`.
- **CSS (204):** committed SHA-256 identical pre- and post-split, gated in `ci.all`.
- **Milestone:** `origin/main` green in ≤ 20 min · 0.10.0 live on hex.pm with clean, grouped HexDocs · `mix credo --strict` running full defaults · `mix dialyzer` clean inside `ci.all` · Flake Detection green and notifying · a `v1.41-MILESTONE-AUDIT.md` (v1.40 never got one).

## Known risks

| Risk | Where | Handling |
|---|---|---|
| The `min` CI lane (Elixir 1.15 / OTP 26 / pg14 / ubuntu-22.04) has **never executed on origin** — highest variance in the milestone | 198 | Expect novel failures; fallback is moving browser lanes off the PR trigger onto nightly if the cause is runner/Playwright-version drift |
| Full-Credo and dialyzer backlogs are genuinely unmeasured | 203, 199 | Measured in 198 Plan 01 and 199; 203 resized by the pre-committed rule above. No invented numbers appear in this roadmap |
| Phase 201 Tier 2 may weaken the mechanical floor for up to three named nodes | 201 | If so it gets a register row with the measured delta and an expiry — it must not disappear. Recapture is forbidden |
| `.planning/` (54 MB) has never been audited for credentials and is about to become fully public | 198 | Hard gate before the push in Plan 04 |
| Contract-test blast radius on `style_contract_test.exs` (2130 lines) and siblings | 201, 204 | One file per commit; source and its contract test in the same commit |
| Publishing before 203/204 means 0.10.0 ships un-ratcheted internals | 202 | Accepted and deliberate: 0.10.0 is the *clean* release, 0.11.0 is the *ratcheted* one. hex.pm has no undo, so surface cleanliness is the gating property, not internal structure |

## Progress

**Execution Order:**
Phases execute in numeric order: 198 → 199 → 200 → 201 → 202 → 203 → 204

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 198. Green Bringup | v1.41 | 0/TBD | Not started | |
| 199. Decouple | v1.41 | 0/TBD | Not started | |
| 200. Public Surface | v1.41 | 0/TBD | Not started | |
| 201. Rendered Output | v1.41 | 0/TBD | Not started | |
| 202. Release 0.10.0 | v1.41 | 0/TBD | Not started | |
| 203. Real Gates | v1.41 | 0/TBD | Not started | |
| 204. Structure | v1.41 | 0/TBD | Not started | |

## Prior Milestones

<details>
<summary>v1.40 Automated Operator-UI Critique & Forward-Only Iteration Harness (Phases 194-197) - SHIPPED 2026-08-27</summary>

- [x] Phase 194: Deterministic Scorecard-Cube Ledger & Mechanical Capture Foundation (3/3 plans) — completed 2026-07-03
- [x] Phase 195: Validated Adversarial Critic Runner & Panel (9/9 plans) — completed 2026-08-26
- [x] Phase 196: Forward-Only Net-Positive Gate & First Proven Iteration (6/6 plans) — completed 2026-08-26
- [x] Phase 197: Coverage Growth, Adversarial Closeout & Design-Debt Register (3/5 plans; 03/04 waived on a ratified PROOF-02 shortfall) — completed 2026-08-27

28/29 requirements satisfied. The paid critic loop is PARKED on ratified spend/value grounds; residual design debt lives in `197-DESIGN-DEBT-REGISTER.md` with owner and reopen-trigger per row. Archive: `.planning/milestones/v1.40-ROADMAP.md`.

</details>

<details>
<summary>v1.39 Quality Baseline, Schema Confidence, and CI Efficiency (Phases 189-193) - SHIPPED 2026-07-03</summary>

Repo-evidence quality-risk ranking followed by high-confidence fixes to the three weakest surfaces: configurable PostgreSQL `storage_schema` behavior proven end-to-end, release/docs version truth reconciled to `0.9.0` behind a drift-guard test, and measured CI/CD efficiency work behind contract guards. 15/15 requirements. Archive: `.planning/milestones/v1.39-ROADMAP.md`.

</details>

<details>
<summary>v1.38 Operator UI Page-by-Page IA & Design-System Polish (Phases 181-188) - SHIPPED 2026-06-30</summary>

Baseline guard repair, PhoenixStorybook example/dev lane, shell/Home orientation, Timeline investigation flow, Coverage readiness, detail/governance/export surface polish, accessibility/motion/docs closeout, and Phase 188 audit-gap closure. Archive: `.planning/milestones/v1.38-ROADMAP.md`.

</details>

<details>
<summary>v1.37 Operator Surface Design-System Stress Test & Component System (Phases 171-180) - SHIPPED 2026-06-20</summary>

Internal component system, `/audit/__stress`, design-system ledger, shell/navigation/theme picker, page stress coverage, microcopy/IA normalization, WCAG/APG/motion guardrails, accessibility-tree evidence, and adversarial closeout. Archive: `.planning/milestones/v1.37-ROADMAP.md`.

</details>

<details>
<summary>v1.36 Operator Surface Light Mode (Phases 166-170) - SHIPPED 2026-06-14</summary>

`theme: :dark | :light | :system` host config and pure-CSS light/system lanes. Archive: `.planning/milestones/v1.36-ROADMAP.md`.

</details>
