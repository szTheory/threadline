# Project milestones: Threadline

## v1.35 (Shipped: 2026-06-12)

**Phases completed:** 0 phases, 0 plans, 0 tasks

**Key accomplishments:**

- (none recorded)

---

## --milestone Unified Logo & Brand Book v2 (Shipped: 2026-06-12)

**Phases completed:** 0 phases, 0 plans, 0 tasks

**Key accomplishments:**

- (none recorded)

---

## v1.35 Unified Logo & Brand Book v2 (Shipped: 2026-06-12)

**Delivered:** Replaced the icon-beside-plain-text logo with the tournament-selected C13 "topstitch-geist" identity (a single stitch arc rising from the word's cut d/l ascenders — pure-path SVG, portable in GitHub's font-less sandbox), rebuilt `brandbook/index.html` as a standalone professional brand book with a misuse gallery, imagery section, and dark/light/system preview toggle, rolled the new identity into the operator-surface header, example-app favicon, and README, and decided the light-mode strategy (decision [165-01], v1.36 seeded).

**Phases completed:** 7 phases (159-165, incl. opted-in 163 rollout and UAT-extension 164/165), 14 plans. Requirements: 31/31 satisfied (audit passed; C13 chain verified drift-free 161→162→163).

**Key accomplishments:**

- Pressure-tested the old brand system (79/150 baseline; GitHub README + 16px favicon critical FAILs from the `<text>` font bug) and synthesized an 11-case-study research base into a binding design brief (MR-1..5 motif rules, HC-1..6 numeric hard constraints, four archetype lanes).
- Built a deterministic fontkit text-to-outline pipeline (per-glyph paths, shaped kerning, stem-width metadata) so every logo SVG is pure paths — regenerable via `brandbook/tools/text-to-paths.mjs`.
- Ran a two-round, user-judged logo tournament (8 archetype-quota candidates, six-context galleries, verbatim ADVANCE/KILL/MUTATE feedback in ROUNDS.md); winner declared by explicit user statement: C13 topstitch-geist.
- Graduated the winner into the full 8-asset brandbook family (designed-not-recolored light primary, chipless self-flipping favicon, tagline isolated to the `-subtitle` variant) and rebuilt the brand book; pressure-test rerun scored 128/150 with no dimension below baseline; brandbook stays text/SVG at 236KB.
- Closed both UAT gaps: a visual Imagery section (4 brand-language specimens + banned-imagery strip) and a Dark/Light/System preview toggle dogfooding the approved `data-tl-theme` mechanism.
- Researched and decided the light-mode strategy: decision [165-01] supersedes [136-01] — dark stays the default/brand, `theme: :dark | :light | :system` host config approved, no runtime toggle in v1; implementation seeded as milestone v1.36 (SEED-004) with a 5-phase breakdown.
- Rolled C13 into product surfaces with zero new test failures (operator-surface logo component on the `var(--tl-*)` contract with `style.ex` untouched; example-app favicon; README `<picture>` dark/light header).

**Verification:**

- `node .planning/milestones/v1.35-phases/162-brand-book-v2/tools/brand-gate.mjs brandbook` (0 FAIL / 0 WARN)
- `mix compile --warnings-as-errors`; `mix verify.test` (886 tests, 0 new failures)
- Audit: `.planning/milestones/v1.35-MILESTONE-AUDIT.md` (status: passed; 31/31)

**Stats:** 73 commits (2026-06-11 → 2026-06-12); 149 files changed, +14,061 / -1,250.

**Archives:**

- Roadmap: `.planning/milestones/v1.35-ROADMAP.md`
- Requirements: `.planning/milestones/v1.35-REQUIREMENTS.md`
- Audit: `.planning/milestones/v1.35-MILESTONE-AUDIT.md`
- Phase execution tree: `.planning/milestones/v1.35-phases/`

**What is next:** v1.36 Operator Surface Light Mode is seeded (SEED-004 + `v1.35-phases/165-light-mode-strategy/165-LIGHT-MODE-RECOMMENDATION.md`); deferred: SOCIAL-PNG-01, trademark human review, hidden wordmark compat node removal (after the nav-overhaul lane lands).

## v1.34 Local Docker Admin UI DX (Shipped: 2026-06-07)

**Delivered:** Hardened Threadline's local Docker demo workflow with a one-command seeded `/audit` entrypoint, project-aware lifecycle commands, localhost-bound dynamic ports, cache-friendly Compose/Dockerfile behavior, and an opt-in shared-proxy path for `threadline.localhost`.

**Phases completed:** 5 phases (154-158), 5 plans. Requirements: 9/9 satisfied.

**Key accomplishments:**

- Made `bin/demo-up` the canonical helper-first local demo path, including printed project name, credentials, URLs, and lifecycle commands.
- Added project-aware refresh/status/logs/down/fresh behavior so repeated runs reuse the intended stack and avoid duplicate local resources.
- Hardened Compose/Dockerfile behavior around localhost-bound ports, project-scoped resources, reusable Docker volumes, pinned PgBouncer, `ca-certificates`, and explicit `--build` rebuilds.
- Updated reader-first Docker docs for contributors and example-app users, including cleanup, cache behavior, multi-stack ports, and why `.dev` hostnames are rejected for HTTP local demos.
- Added optional friendly-host proxy mode using the shared local Traefik network, while preserving the fallback `127.0.0.1:<port>` path.

**Verification:**

- `bash -n bin/demo-up`
- `docker compose --profile demo config`
- `bin/demo-up` reached `/users/log_in` and `/audit`, refreshed the same stack, and preserved the browser URL.
- `mix test`
- `mix verify.hex_evaluator`
- `mix verify.example`
- `mix verify.example_browser`
- `git diff --check`

**Archives:**

- Roadmap: `.planning/milestones/v1.34-ROADMAP.md`
- Requirements: `.planning/milestones/v1.34-REQUIREMENTS.md`

**What is next:** `$gsd-new-milestone` - define fresh requirements before opening new work.

---

## v1.33 Brand Review + Direction Selection (Shipped: 2026-06-06)

**Delivered:** Reviewed and approved the v1.32 brandbook direction for README/GitHub readiness, added the light-surface logo role, applied targeted brandbook truth cleanup, and verified the final source artifacts before public rollout.

**Phases completed:** 4 phases (150-153), 3 plans. Requirements: 6/6 satisfied.

**Key accomplishments:**

- Made the existing `brandbook/` HTML, logo assets, visual specimens, token files, and copy guidance visible through a concise review packet.
- Added `brandbook/logo-primary-light.svg` and usage guidance so README/GitHub/light documentation surfaces no longer depend on the dark primary lockup.
- Captured the human direction decision: targeted cleanup selected; alternate logo concepts, public rollout, and runtime UI changes stayed out of scope.
- Rewrote brandbook-facing copy so the artifact set presents current Threadline brand truth instead of refresh/audit backstory.
- Verified JSON, SVG, HTML parser, direct-open browser, desktop/mobile screenshot, historical-frame scan, binary-exclusion, inventory, and file-size evidence.

**Stats:**

- Timeline: 2 days (opened 2026-06-05, shipped 2026-06-06).
- Git range: `v1.32` -> `8e5bd74`; 9 commits, 26 files changed, +1664 / -56 LOC through phase closeout.
- Audit: `passed` - requirements 6/6, phases 4/4.

**Archives:**

- Roadmap: `.planning/milestones/v1.33-ROADMAP.md`
- Requirements: `.planning/milestones/v1.33-REQUIREMENTS.md`
- Audit: `.planning/milestones/v1.33-MILESTONE-AUDIT.md`
- Phase history: `.planning/milestones/v1.33-phases/`

**What is next:** `$gsd-new-milestone` - define fresh requirements before public README, HexDocs, landing page, or social-card rollout work.

---

## v1.32 Brand System Foundation (Shipped: 2026-06-05)

**Phases completed:** 5 phases, 5 plans

**Delivered:** Source-control-ready Threadline brand system under `brandbook/`: strategic pressure test, durable brand book, design tokens, SVG logo system, static HTML brandbook, visual specimens, and final verification evidence.

**Key accomplishments:**

- Reverted the premature one-shot brandbook commit and reopened the work through GSD requirements, roadmap, phase plans, verification, and audit.
- Preserved the strong Threadline core ("Follow what happened", connected audit history, calm technical voice) while tightening implementation readiness.
- Added JSON/CSS tokens for dark/light surfaces, state roles, focus, code, callouts, type, spacing, radius, borders, and modest elevation.
- Added editable SVG logo, mark, monochrome, favicon, social card, and useful visual specimens without raster/font bloat.
- Verified direct-open HTML at desktop and mobile sizes, image-load state, representative WCAG AA contrast pairs, XML/JSON parsing, and file inventory.

**Archives:**

- Roadmap: `.planning/milestones/v1.32-ROADMAP.md`
- Requirements: `.planning/milestones/v1.32-REQUIREMENTS.md`
- Audit: `.planning/milestones/v1.32-MILESTONE-AUDIT.md`
- Phase history: `.planning/milestones/v1.32-phases/`

**What is next:** `$gsd-new-milestone` — define fresh requirements before opening new work.

---

## v1.31 Operator Surface: Insane Polish (Shipped: 2026-06-05)

**Phases completed:** 10 phases, 35 plans, 51 tasks

**Delivered:** Full `/audit` operator-surface polish pass: baseline/final screenshot evidence, seed-state enrichment, design-system hardening, Prove/Find/Home screen polish, earned investigation/export flows, motion governance, responsive coverage, accessibility baseline, and screenshot regression guard.

**Key accomplishments:**

- Baseline/final evidence was made durable: `v1.31-UI-AUDIT.md`, 24 baseline screenshots, 24 final screenshots, screenshot diff, and Phase 144 errata close `POLISH-AUDIT`.
- Demo seed and `DEMO-MANIFEST.md` now expose the operator surface across empty, sparse, dense, error, scoped, and edge states with named actor literals and doc-contract coverage.
- The dark BEM/token design system is source-first and frozen through `v1.31-DESIGN-SYSTEM.md`, `style.ex`, style contract tests, and shared operation presentation helpers.
- Prove and Find clusters now share canonical value, status, remediation, action, table, card, and mobile primitives across Evidence, Policy, Retention, Exports, Timeline, Transaction, Row-history, Actor, and Coverage.
- Home/nav orientation and earned flows now support record-first lookup, correlation paste/deep-link, first-class row history, and Timeline/Evidence to Exports carry-forward.
- Motion, responsive, accessibility, screenshot diff, and screenshot-regression verification are wired into the browser/source-contract lanes that protect the polished baseline.

**Stats:**

- Timeline: 3 days (opened 2026-06-03, shipped 2026-06-05).
- Requirements: 10/10 complete.
- Audit: `passed` — requirements 10/10, phases 11/11, integration 10/10, flows 10/10.

**Archives:**

- Roadmap: `.planning/milestones/v1.31-ROADMAP.md`
- Requirements: `.planning/milestones/v1.31-REQUIREMENTS.md`
- Audit: `.planning/milestones/v1.31-MILESTONE-AUDIT.md`
- Phase history: `.planning/milestones/v1.31-phases/`

**Tech debt (non-blocking):** Historical validation/frontmatter metadata remains stale in a few older phase files; Phase 144 audit records the debt as non-blocking and closes the milestone requirements.

**What is next:** `$gsd-new-milestone` — define fresh requirements before opening new work.

---

## v1.29 First-Hour Parity (Shipped: 2026-05-29)

**Delivered:** README Quick Start `ecto_repos` parity; scope-first phx-gen-auth mount with integration proof; WALKTHROUGH verify cwd and row-history URL truth; Nyquist 125 finalized; SUMMARY frontmatter SSOT; planning-metadata audit closeout via Phase 130.1.

**Phases completed:** 4 phases (128-130.1), 8 plans, 24 tasks. Requirements: 10/10 satisfied (README-01–02, TRIG-01, AUTH-MOUNT-01–02, WALK-01–03, NYQ-01, PLAN-01).

**Key accomplishments:**

- README Quick Start renumbered to six steps with explicit `ecto_repos` config before install, posts-only triggers, and section_slice doc-contract locks
- Scope-first `authorize_fn` callback ref with `MyApp.Audit.authorize_operator/1`, `is_admin` gate, integration proof, and surface-section doc-contract locks
- WALKTHROUGH.md no longer sends maintainers to root verify or pasteable /audit/rows/ URLs.
- Doc-contract tests prevent WALKTHROUGH verify and row-history regressions.
- Phase 125 Nyquist proof chain archived under v1.27 milestones, charter test locks v1.29, and 125-VALIDATION finalized after fresh Tier 1 green on current tree.
- PLAN-01 SSOT for three-source SUMMARY frontmatter, v1.27 archive with GAP backfill, and NYQ-01 closed after single green `mix ci.all` on current tree.
- Phase 130.1 reconciled ROADMAP/REQUIREMENTS authority, documented Nyquist waivers for doc-only phases 128–129, and closed audit planning-metadata drift.

**Stats:**

- Timeline: ~2 days (2026-05-28 → 2026-05-29; Phase 128 → Phase 130.1 closeout).
- Git range: 50 commits; 66 files changed, +6547 / −108 LOC.
- Audit: `tech_debt` — 10/10 requirements, 4/4 phases verified, no blockers.

**Archives:**

- Roadmap: `.planning/milestones/v1.29-ROADMAP.md`
- Requirements: `.planning/milestones/v1.29-REQUIREMENTS.md`
- Audit: `.planning/milestones/v1.29-MILESTONE-AUDIT.md`

**Tech debt (non-blocking):** Nyquist VALIDATION.md waived for doc-only phases 128–129; see audit archive.

**What is next:** `/gsd-new-milestone` — default **Hold**; v1.28 External Pilot only on sustained real-adopter signal.

---

## v1.27 Distribution & First-Hour Finish (Shipped: 2026-05-28)

**Delivered:** Hex **threadline 0.6.0** published; first-hour `ecto_repos` config documented and contract-locked; adopter docs finished (auth-neutral §6, `:schemas` reification, evidence host-write boundary, four-lane vocabulary); gap-closure phases reconciled authority surfaces, signed Nyquist validation on 122–124, and wired runnable `:schemas` demonstration in the example app.

**Phases completed:** 6 phases (122-127), 15 plans, 44 tasks. Requirements: 11/11 satisfied (DIST-01–03, CFG-01–03, DOC-01–05).

**Key accomplishments:**

- CHANGELOG four-lane upgrade bullet, release distribution doc contract, and conditional anti-stale test scaffolding — all green while Hex row remains Pending
- Published threadline 0.6.0 to hex.pm via Release workflow bootstrap — gate-ci-green, publish-hex, and Hex API verify all succeeded
- Distribution sync PR merged — adoption-pilot Hex row OK, evaluating guide updated, 122-VERIFICATION.md written, doc contracts green
- Getting-started §2 now documents `config :threadline, ecto_repos: [MyApp.Repo]` before install schema, with doc-contract ordering lock
- Production checklist prerequisite band cross-links `config :threadline, ecto_repos` to getting-started with dedicated doc-contract lock
- IEx-first audited write in getting-started §6 with demo-corr handoff, Sigra HTTP collapsed into details, and dedicated DOC-01/DOC-02 doc contract tests
- `:schemas` mount map, row-history reification SSOT, failure UX, and §9 link with DOC-03 doc contract lock
- Evidence host-write SSOT across adopter guides with DOC-04/DOC-05 contract locks and integration-contracts four-lane vocabulary linked to upgrade-path
- Charter doc-contract PROJECT assertion now locks `Latest Milestone Shipped: v1.27` matching shipped PROJECT.md.
- Planning authority surfaces now reflect v1.27 shipped delivery; doc-contract and full CI green.
- `122-VALIDATION.md` finalized with `nyquist_compliant: true` after green D-14 doc-contract bundle; manual DIST rows attested via `122-VERIFICATION.md` without faking automation.
- `123-VALIDATION.md` finalized with `nyquist_compliant: true` after green D-15 doc-contract bundle; CFG-01 ExDoc row closed via Configure Threadline doc-contract proxy.
- `124-VALIDATION.md` and `126-VALIDATION.md` finalized with `nyquist_compliant: true` after green D-16 doc-contract bundle and single session-close `mix ci.all` (740 + 53 tests, 0 failures).
- Example app operator mount now maps help-desk tables for row-history reification; docs match router SSOT.
- Integration test proves ticket_replies row history renders via :schemas; D-14 contract and phase verification close v1.27 gap.

**Stats:**

- Timeline: ~1 day (2026-05-28; Phase 122 → Phase 127 closeout).
- Audit: `passed` — 11/11 requirements, 6/6 phases verified, 26/27 integration checks, 4/4 E2E flows.

**Archives:**

- Roadmap: `.planning/milestones/v1.27-ROADMAP.md`
- Requirements: `.planning/milestones/v1.27-REQUIREMENTS.md`
- Audit: `.planning/milestones/v1.27-MILESTONE-AUDIT.md`

**Tech debt (non-blocking):** 125-VALIDATION.md Nyquist draft; WALKTHROUGH `/audit/rows/` shorthand vs transaction-scoped history route; SUMMARY frontmatter lacks requirements-completed values. See audit archive.

**What is next:** `/gsd-new-milestone` — v1.28 External Pilot on sustained real-adopter signal only.

---

## v1.26 Auth Lane Breadth (Shipped: 2026-05-28)

**Delivered:** phx.gen.auth integration cookbook, `phx-gen-auth-reference` upgrade-path lane with root CI proof, and adopter-doc neutrality so first-hour docs do not read as Sigra-required — without a second reference app or Threadline-owned auth.

**Phases completed:** 3 phases (119-121), 6 plans, 11 tasks. Requirements: 11/11 satisfied (AUTH-GUIDE-01–03, AUTH-LANE-01–02, AUTH-PROOF-01–03, ADOPT-AUTH-01–03).

**Key accomplishments:**

- phx.gen.auth integration cookbook with host-owned MyApp.AuditActor Plug wiring, admin operator mount, and AUTH-GUIDE-03 non-goals
- `phx-gen-auth-reference` lane in upgrade-path with four-lane matrix row and honest proof anchors (guide + root tests)
- Root integration tests prove phx.gen.auth-shaped scope assigns, 1-arity admin authorize_fn, and Threadline.Plug smoke — without Sigra
- Getting-started §5/§6 auth-neutral first; README four-lane Start here; evaluator neutrality; ADOPT-AUTH doc-contract gates

**Stats:**

- Timeline: ~1 day (2026-05-27 → 2026-05-28; feat(119-01) → Phase 121 closeout).
- 26 commits, 41 files changed, +3133 / −98 LOC in milestone commit range.

**Archives:**

- Roadmap: `.planning/milestones/v1.26-ROADMAP.md`
- Requirements: `.planning/milestones/v1.26-REQUIREMENTS.md`
- Audit: `.planning/milestones/v1.26-MILESTONE-AUDIT.md`

**Tech debt (non-blocking):** ADOPT-AUTH-01 soft literal gaps in getting_started contract; §6 cookie staging prose still sigra-example-specific below collapsed curl; Hex publish via tag `v0.6.0`. See audit archive.

**What is next:** `/gsd-new-milestone` — adopter-driven maintenance; external pilot on sustained signal only.

---

## v1.25 Adopter-Ready Release & First-Hour Truth (Shipped: 2026-05-28)

**Delivered:** Truthful Hex **threadline 0.6.0** packaging; narrative and example surfaces aligned on `Audit.transaction/3` as the blessed write path; evidence-plane doc authority with semver adopter prose; evaluator one-pager and refreshed adoption-pilot verify ladder — without compliance expansion or maintainer STG attestation claims.

**Phases completed:** 5 phases (114-118), 11 plans, 33 tasks. Requirements: 16/16 satisfied (REL-01–04, NARR-01–03, EXAMPLE-01–04, DOC-01–03, PILOT-01–02).

**Key accomplishments:**

- 0.6.0 semver, adopter-ready CHANGELOG narrative, and ExDoc module IA with Evidence plane group
- REL-04 install-snippet SSOT: all four adopter copy-paste surfaces and doc-contract tests lock `~> 0.6`
- REL-03 publish-ready boundary: CONTRIBUTING v0.6.0 literals, verify.release and ci.all green
- Retargeted `guides/how-threadline-works.md` to center `Threadline.Audit.transaction/3` as the recommended audited write path and locked blessed-path literals plus write-side ordering in doc-contract tests.
- Aligned README and getting-started discovery cross-links with the retargeted how-threadline-works guide, added a three-doc NARR-02 contract lock, and closed verify.doc_contract gate drift for audit_doc_contract_test.exs.
- Browser Sigra session reaches POST /api/posts via fetch_session/fetch_current_scope on :api, with cookie curl documented and locked in dual-contract tests.
- Example README restructured with Choose your path, shared Base install, Track A/B forks, and Mix task ownership tables — doc contracts lock skip-generators and neutral vs walkthrough fiction literals.
- Maintainer and adopter prose now use split evidence guides and Hex semver — phantom hub removed, 0.5→0.6 upgrade documented, incident JSON step 1 cites Audit.transaction/3
- Minimal-plus DOC-03 contracts lock Evolution semver chronology, 0.5→0.6 upgrade bullet, adopter semver refutes, and incident JSON blessed path — with exploration_routing wired into mix verify.doc_contract (71 tests green)
- Adoption-pilot backlog now cites the canonical eight-step `mix ci.all` ladder and doc contracts refute hardcoded test counts.
- Evaluator one-pager links 0.6.0 packaging, host-owned boundaries, verify ladder, and STG template pointers; README and ExDoc expose it without maintainer STG attestation phrasing.

**Stats:**

- Timeline: ~1 day (2026-05-27 → 2026-05-28; feat(114-01) → Phase 118 closeout).
- 68 commits, 78 files changed, +6176 / −230 LOC in milestone commit range.

**Archives:**

- Roadmap: `.planning/milestones/v1.25-ROADMAP.md`
- Requirements: `.planning/milestones/v1.25-REQUIREMENTS.md`
- Audit: `.planning/milestones/v1.25-MILESTONE-AUDIT.md`

**Tech debt (non-blocking):** Nyquist partial on phases 115/117/118; optional manual Track A evaluator smoke. See audit archive.

**What is next:** v1.26 Auth Lane Breadth (shipped 2026-05-28) — see `.planning/ROADMAP.md` for deferred carry-forward.

---

## v1.24 Audited Write Path & Adopter Truth (Shipped: 2026-05-27)

**Delivered:** First-class `Threadline.Audit.transaction/3` helper wrapping actor GUC + domain writes + optional `record_action/2` + `action_id` linkage; reference app and getting-started guide adopt it on all primary write paths; 0.5.x adopter/doc truth repaired (`evidence_authorize_fn`, adoption-pilot version table, canonical evidence CLI, WR-110-001 prose).

**Phases completed:** 3 phases (111-113), 11 plans. Requirements: 12/12 satisfied (AUDIT-TXN-01–04, ADOPT-HELPER-01–03, TRUTH-01–05).

**Known deferred items at close:** 1 (see STATE.md Deferred Items — Phase 109 verification gap from v1.23 acknowledged as by-design)

**Key accomplishments:**

- Shipped `Threadline.Audit.transaction/3` with transaction-local GUC, optional semantic action recording, `action_id` linkage via `txid_current()`, and map-merge return envelope — doc-contract marker for guide extraction.
- PostgreSQL integration tests prove capture, strict `:correlation_id` timeline linkage, missing-actor policy, rollback propagation, and `transaction_meta` on linkage paths.
- Documented helper as the recommended write path in `guides/getting-started-saas.md` and `guides/integration-contracts.md`; `audit_doc_contract_test.exs` locks literals.
- Reference app migrated `Blog.create_post/2`, `HelpDesk.ticket_replied_and_closed/6`, capture-only deletes, and Oban `touch_post_for_job/2` to the helper — audit/correlation tests green without weakened assertions.
- Capture-only `transaction_meta` persistence on helper paths with fail-closed `update_all` semantics for help-desk org scoping.
- Wired `evidence_authorize_fn` on sigra-reference operator mount (admin-only); admin vs support `/audit/evidence` integration tests; docs state support denial and CLI fallback.
- Adoption-pilot backlog aligned to **threadline 0.5.0** / `~> 0.5` with doc-contract SSOT from `Threadline.MixProject`.
- WALK-03-02 prose aligned to frozen `demo_last_tuesday` / `demo_epoch` anchors (WR-110-001); strengthened demo contract tests for leaving-agent ticket volume.
- Evidence CLI naming locked repo-wide: canonical `mix threadline.evidence.show`; `evidence_cli_doc_contract_test.exs` refutes never-shipped `mix verify.evidence` alias.
- Closeout gates green: `mix verify.doc_contract` and `mix verify.example`.

**Stats:**

- Timeline: same day (2026-05-27; feat(111-01) → feat(112-04)).
- ~45 files changed, +4101 / −305 LOC in milestone commit range.

**Archives:**

- Roadmap: `.planning/milestones/v1.24-ROADMAP.md`
- Requirements: `.planning/milestones/v1.24-REQUIREMENTS.md`

**What is next:** `/gsd-new-milestone` — define v1.25+ themes (re-engage v1.22 DEFER trio only on sustained adopter/procurement pressure).

---

## v1.23 Realistic-Demo Walkthrough (Shipped: 2026-05-27)

**Phases completed:** 7 phases, 24 plans, 59 tasks

**Known deferred items at close:** 1 (see STATE.md Deferred Items — Phase 109 verification gap acknowledged as by-design)

**Key accomplishments:**

- Locked the deliberate v1.22 -> v1.23 framing override (synthetic-first-adopter walkthrough) and v1.23 non-goals across PROJECT.md and MILESTONE-ARC.md in three atomic commits, with the re-engagement trigger bolded in the new Key Decisions row and a v1.23 arc-order row added under a refreshed header.
- Shipped five-table help-desk domain with binary_id keys, per-org ticket numbers, and internal_note_body column — migratable and compiling in the example app.
- Help-desk writes now capture with masked internal notes, one semantic action per transaction, and full trigger coverage across six audited tables.
- DataCase tests prove multi-table capture, org-scoped meta, masked internal notes, and hard-delete audit rows — example suite and verify.example stay green.
- Sigra controller-mode auth with users migrations, Phoenix HTML bootstrap, registration that auto-provisions help-desk org membership, and a home page linking register/login and /audit.
- Sigra `current_scope` maps to help-desk-aware `current_user` via `OperatorUser`, with `/audit` wired through `:operator_browser` before unchanged authorize callbacks.
- ConnCase `login_via_sigra/2` replaces faked browser assigns, operator surface tests use real Sigra HTTP login with UUID org scoping, and a dev-only help-desk route proves `actor_ref` capture from the browser pipeline.
- Frozen demo manifest with UUID v5 org/user ids, hero tickets 4521/4518, temporal anchors, and dev/test credential docs before any seed writes.
- Reusable hard-delete API, shared demo truncate SQL, and `mix demo.reset` with production guard — walkthrough recovery without `ecto.drop`.
- `mix demo.seed` plants deterministic three-org help-desk fiction with hero audit incidents, PRNG filler volume, and manifest-driven timeline backfill — `mix demo.reset` now reseeds end-to-end.
- Org Y offboard purge is seeded with evidence snapshots; `demo_contract_test.exs` and the example README lock SEED-02..05 for Phase 108.
- Post-`mix demo.seed` now persists a real `redaction_policy` evidence row with manifest subject_ref `walk-demo-redaction-policy`, closing D-108-04e for WALKTHROUGH §5.
- YAML-frontmatter finding template and a/b/c/d classification README with Phase 110 fix-vs-defer routing for Phase 109 observe-only capture
- Maintainer runbook with §0 discipline block, clean-clone install through daily-use operator flows, and WALK-01/02 step IDs ready for Phase 109 dry-run
- Four WALK-03 incident playbooks (#4521 close, leaving-agent window, org Y retention, #4518 delete) with operator-surface-only resolution paths and ROADMAP traceability aligned to four incidents
- WALKTHROUGH §5 evidence exercises, self-contained appendices, README maintainer routing, and doc contract test completing the Phase 108 runbook
- Isolated walk clone at 368c315 with execution log, WR pre-registration, and §0 checkpoint ready for RUN-01
- §1 bootstrap passes through demo.seed but hard-gates at WALK-01-04 — landing page HTTP 500 blocks RUN-01
- NOT ATTEMPTED — §1 hard gate blocked RUN-02 operator incidents (§4)
- NOT ATTEMPTED — §1 hard gate blocked RUN-03 evidence exercises (§5)
- Imported clone findings to main repo; scope-guard path filter empty; VERIFICATION and phase SUMMARY written
- Observe-only dry-run on clean clone at 368c315 — §1 hard-gates at landing 500; one (a) finding imported; scope guard verified
- Nil-safe `@current_scope` on ThreadlinePhoenix landing page closes finding 0001; logged-out GET / returns 200
- Findings 0002 and 0003 filed from 108-REVIEW, WALK-03-02/03 prose aligned with seed fiction, contract tests extended, IN-001 §0 voice cleaned
- L2 re-walk on fresh clone at d2ef6c8 — RUN-01/02/03 pass, WR-001/002 confirmed, phase 110 closeout complete
- Validation re-walk on isolated clone at post-Wave-2 SHA — RUN-01/02/03 pass; findings 0001–0003 fixed; zero `lib/` commits

---

## v1.22 Policy / Evidence Plane (Shipped: 2026-05-27)

**Delivered:** Durable append-only evidence records for Threadline-owned governance facts, exposed consistently through Phoenix-optional library APIs, Mix tasks, and a host-gated `/audit/evidence` LiveView — with explicit non-goals around RBAC, tenancy, legal hold, immutable storage, and generic compliance workflow.

**Phases completed:** 9 phases (95-103), 18 plans, 33 tasks. Requirements: 12/12 satisfied (EVID-01/02/03, PROOF-01/02/03, SURF-01/02/03, DOC-01/02/03).

**Key accomplishments:**

- Append-only evidence schema and `Threadline.Evidence` public context — six bounded subjects with stable provenance metadata and machine-readable detail payloads.
- Three-tier proof vocabulary (`Threadline.Evidence.Proof`) distinguishing proven facts, inferred posture, and unsupported claims — shared verdict language across library, Mix task, and LiveView surfaces.
- Phoenix-optional library API plus Mix-task parity with a stable JSON contract for CI, procurement, and audit handoff (**canonical:** `mix threadline.evidence.show`).

> **Evidence CLI errata:** `mix verify.evidence` was planned for early milestones but never shipped; runnable viewer is `mix threadline.evidence.show` only.

- Mounted `/audit/evidence` LiveView with overview-first drill-down, URL-driven navigation, host-owned auth gate, and truthful mounted fallbacks — no new operator UI family, no Threadline-owned RBAC.
- Public docs lock the narrow evidence-plane contract: README claim strip, explicit non-goals, and separately-authorized `/audit/evidence` wording in the support matrix.
- Phase 99 named rerun bundle (`mix verify.doc_contract` + 5-file evidence-plane seam bundle + `mix verify.example`) locks the public contract on the current tree; reran green at closeout (46+55+21 = 122 tests, 0 failures).
- Verification backfill chain (Phases 100/101/102) closed Phase 95/96/98 verification gaps with current-tree proof and finalized Nyquist validation artifacts.
- Authority surface reconciliation and milestone re-audit (Phase 103) flipped the v1.22 audit to `status: passed` with 12/12 requirements satisfied, `closeout_readiness: green`, and the D-02 archive boundary intact.

**Stats:**

- Timeline: 2 days (opened 2026-05-25, shipped 2026-05-27).
- 18 plans, all with SUMMARY.md on disk; milestone audit **passed** (2026-05-27 against the reconciled tree).
- Boundary preserved: zero changes to lib/, test/, mix.exs, mix.lock, guides/, examples/, priv/ during Phase 103 closeout.

**Archives:**

- Roadmap: `.planning/milestones/v1.22-ROADMAP.md`
- Requirements: `.planning/milestones/v1.22-REQUIREMENTS.md`
- Milestone audit: `.planning/milestones/v1.22-MILESTONE-AUDIT.md`
- Phase execution tree: `.planning/milestones/v1.22-phases/`

**What is next:** `/gsd-new-milestone` — define v1.23+ themes (consider DEFER-01/02/03 backlog: compliance report packs, legal-hold workflows, immutable archive guarantees).

---

Entries are newest first.

## v1.21 — Scoped Support / Operator Proof (shipped 2026-05-25)

**Goal:** Turn the existing host-owned `scope_query_fn` seam into a truthful, first-party support-safe lane on the shipped `/audit` surface without widening Threadline into an auth, tenancy, or compliance platform.

**Phases completed:** **85-94** (10 phases; 21 plans; 32 tasks).

**Key accomplishments:**

- Narrowed the support-lane claim to one truthful current-tree contract and locked the export-denied-by-default posture behind host-owned seams.
- Closed the remaining scoped read-path gap by enforcing support scope through row history and as-of flows on the shipped `/audit` surface.
- Standardized one canonical `/audit` mount recipe and runnable example-host proof for admin and support personas on the same route tree.
- Aligned denial and fallback UX across LiveView, HTTP, docs, and contract tests so unsupported support-lane surfaces fail clearly and consistently.
- Backfilled the missing verification chain for Phases 85-88 and re-ran the final proof bundle to close all 12 v1.21 requirements on the current tree.
- Reconciled `ROADMAP.md`, `PROJECT.md`, `STATE.md`, `REQUIREMENTS.md`, and the milestone audit around the same shipped support-lane contract.

**Stats:** 10 phases, 21 plans, 32 tasks, 12/12 requirements complete at close. Milestone window: **2026-05-24 → 2026-05-25**. Git range: **`a392d24`** → **`32d187b`**. The milestone work touched **126 files** with **13,428 insertions / 398 deletions**.

**Archives:** `.planning/milestones/v1.21-REQUIREMENTS.md`, `.planning/milestones/v1.21-ROADMAP.md`, `.planning/milestones/v1.21-MILESTONE-AUDIT.md`.

**Known gaps at close:** Milestone audit **passed** with 12/12 requirements satisfied. Two plan-level validation files in Phases **90** and **91** still carry stale draft frontmatter, but the canonical Phase 85/86 verification artifacts and the final Phase 94 rerun bundle are green, so this remains documented non-blocking tech debt.

**What is next:** **`/gsd-new-milestone`** — open the next requirement set from `.planning/MILESTONE-ARC.md`, currently led by **v1.22 — Policy / Evidence Plane**.

---

## v1.20 — Scale and Governance Depth (shipped 2026-05-24)

**Goal:** Turn the core audit substrate into an opinionated production workflow with retention oversight, repeatable investigations, and clear governance controls.

**Phases completed:** **75-84** (10 phases; 22 plans complete).

**Key accomplishments:**

- Added governance schemas plus `Threadline.Storage` and `Threadline.ExportQueue` behaviour seams.
- Shipped batched retention pruning with run tracking and a Retention History operator surface.
- Repaired saved-view ownership on the default `actor_fn` mount path.
- Closed built-in export runtime truth, cleanup, and adapter-backed delivery on the current tree.
- Reconciled the authoritative milestone surfaces and closeout evidence after the v1.20 audit exposed real runtime and verification gaps.

**Stats:** 10 phases, 22 plans, 13/13 requirements complete at close. Milestone window: **2026-05-21 → 2026-05-24**.

**Archives:** `.planning/milestones/v1.20-REQUIREMENTS.md`, `.planning/milestones/v1.20-ROADMAP.md`, `.planning/v1.20-MILESTONE-AUDIT.md`.

**What is next:** **`/gsd-new-milestone`** — open the next requirement set from `.planning/MILESTONE-ARC.md`, now activated as **v1.21 — Scoped Support / Operator Proof**.

---

## v1.19 — Integration Breadth (shipped 2026-05-08)

**Goal:** Broaden host/framework adoption through adapter contracts, support-matrix honesty, canonical mount patterns, and a measured `threadline_web` extraction-readiness decision.

**Phases completed:** **69-74** (6 phases; 16 plans with `SUMMARY.md`; per-phase verification evidence; consolidated `v1.19-MILESTONE-AUDIT.md`).

**Key accomplishments:**

- Published `guides/integration-contracts.md` as the canonical breadth-contract guide, locked discovery pointers, and explicitly narrowed the public support matrix to `capture-only`, `phoenix-surface`, and `sigra-reference` (Phase **69**).
- Rewrote the operator-surface and integration docs around one canonical `/audit` topology with a shared `%{assigns: assigns}` `authorize_fn` and explicit LiveView-versus-export auth boundaries (Phase **71**).
- Added the Packaging Boundary Scorecard to `guides/upgrade-path.md`, recording the v1.19 answer as "stay in-tree for now", and locked this wording with drift-aware contract tests (Phase **72**).
- Repaired the authorization contract to enforce scoped-access across timeline, actor, transaction, and export flows, securing the final tree (Phase **73**).
- Closed all Phase 72 Nyquist validation gaps, updated requirement tracking frontmatter, and verified that the shipped tree is internally consistent (Phase **74**).

**Stats:** 6 phases, 16 plans, 10/10 requirements complete at close. Milestone window: **2026-05-07 → 2026-05-08**. First Phase 69 commit landed **`fd7c4ec`**; final milestone commit landed **`8fb3de5`**. The closeout tree touched **103 files** with **9,262 insertions / 188 deletions** across the milestone work.

**Archives:** `.planning/milestones/v1.19-REQUIREMENTS.md`, `.planning/milestones/v1.19-ROADMAP.md`, `.planning/milestones/v1.19-MILESTONE-AUDIT.md`.

**Known gaps at close:** Milestone audit **passed** with 10/10 requirements satisfied.

**What is next:** **`/gsd-new-milestone`** — open the next requirement set from `.planning/MILESTONE-ARC.md`, currently led by **v1.20 — Scale and Governance Depth**.

---

## v1.18 — Adoption and Policy Hardening (shipped 2026-05-07)

**Goal:** Tighten the shipped operator surface so production teams can actually roll it out cleanly: raw timeline browse with full filter parity, current-view exports, read-only coverage/redaction policy viewers, and lifecycle/onboarding hardening.

**Phases completed:** **64-68** (5 phases; 20 plans with `SUMMARY.md`; per-phase verification evidence; consolidated `v1.18-MILESTONE-AUDIT.md`).

**Key accomplishments:**

- Shipped the raw `/audit` timeline browse LiveView with full `Threadline.Query.timeline/2` filter parity, URL-as-state, shared filter vocabulary, and locked route/label/filter-key doc contracts (**BROWSE-01..04**, Phase **64**).
- Shipped export-from-current-view parity for CSV / wrapped JSON / NDJSON with pre-flight match counts, threshold-based chunked streaming, RFC 5987 filenames, and Mix-task byte-parity coverage (**EXPO-03..05**, Phase **65**).
- Shipped the read-only coverage dashboard plus parity `mix threadline.health.coverage`, including `:schema` support, surface-header drift visibility, and contract-locked output/schema literals (**COV-01..03**, Phase **66**).
- Shipped the drift-aware redaction admin plus parity `mix threadline.policy.show`, reconciling configured vs deployed redaction safely and never rendering sample values (**REDN-03..05**, Phase **67**).
- Closed the lifecycle loop with mounted `/audit` onboarding docs, a canonical upgrade-path guide for the optional Phoenix surface, and fresh `mix verify.format` / `mix ci.all` evidence on the final v1.18 tree (**ADOPT-05..07**, Phase **68**).

**Stats:** 5 phases, 20 plans, 16/16 requirements complete at close. Milestone window: **2026-05-06 → 2026-05-07**. First Phase 64-68 commit landed **2026-05-06 20:31:42 -0400**; final shipped Phase 68 commit landed **2026-05-07 17:14:41 -0400**. The closeout tree touched **82 files** with **13,798 insertions / 119 deletions** across the milestone work.

**Archives:** `.planning/milestones/v1.18-REQUIREMENTS.md`, `.planning/milestones/v1.18-ROADMAP.md`, `.planning/milestones/v1.18-MILESTONE-AUDIT.md`.

**Known gaps at close:** Milestone audit **passed** with 16/16 requirements satisfied. Two bookkeeping notes remain non-blocking: the open-artifact audit still surfaces resolved `67-UAT.md` as a stale close-decision item with 0 pending scenarios, and Phases **64-66** do not have Nyquist `VALIDATION.md` files even though their verification evidence exists.

**What is next:** **`/gsd-new-milestone`** — open the next requirement set from `.planning/MILESTONE-ARC.md`, currently led by **v1.19 — Integration Breadth**.

---

## v1.16 — Investigation Table Stakes (shipped 2026-05-06)

**Goal:** Make Threadline answer the first serious audit investigation questions with stable library APIs, a first-class incident bundle surface, and one canonical docs story instead of custom SQL, ad-hoc joins, or per-app controller glue.

**Phases completed:** **53–56** (4 phases; 8 plans with `SUMMARY.md`; per-phase `VERIFICATION.md`; consolidated `v1.16-MILESTONE-AUDIT.md`).

**Key accomplishments:**

- Shipped explicit keyset paging for investigation timelines through `Threadline.timeline_page/2`, kept eager `timeline/2` intact, and aligned export streaming to the same `(captured_at, id)` traversal semantics (**EXPLORE-01**, Phase **53**).
- Shipped public investigation helpers for row history, actor windows, correlation bundles, and transaction context so adopters no longer need low-level query composition for the first common support questions (**EXPLORE-02**, Phase **54**).
- Shipped `Threadline.incident_bundle/2` plus the Phoenix reference endpoint migration so one transaction drill-down now returns linked context, ordered changes, JSON-ready diffs, and proven `401`/`400`/`404`/`200` request-path behavior (**INCIDENT-06/07**, Phase **55**).
- Aligned README, guides, the Phoenix example, doc-contract suites, `PROJECT.md`, `STATE.md`, and `MILESTONE-ARC.md` on one canonical investigation routing hierarchy and forward-planning source of truth (**ADOPT-04**, Phase **56**).

**Stats:** 4 phases, 8 plans, 5/5 requirements complete at close. Milestone window: **2026-05-05 → 2026-05-05**. Git range from **`v1.15`** tag **`ab71394`** through the v1.16 closeout tree touched **29 files** with **1645 insertions / 145 deletions**.

**Archives:** `.planning/milestones/v1.16-REQUIREMENTS.md`, `.planning/milestones/v1.16-ROADMAP.md`, `.planning/v1.16-MILESTONE-AUDIT.md`, `.planning/milestones/v1.16-phases/`.

**Known gaps at close:** Milestone audit **passed** with 0 requirement, integration, or end-to-end flow gaps. Historical note: repo-wide `mix ci.all` was blocked at the v1.16 close by pre-existing formatter drift outside the write set, and that debt was later retired in Phase 68 on 2026-05-07. Phases **53** and **54** still lack Nyquist `VALIDATION.md` bookkeeping.

**What is next:** **`/gsd-new-milestone`** — define the next requirements set and roadmap slice from `.planning/MILESTONE-ARC.md`, currently led by **v1.17 — Operator Surface Foundation**.

---

## v1.15 — Host Integration Completion (shipped 2026-05-05)

**Goal:** Close the remaining Phoenix host-integration seams by shipping native request-context overrides in `Threadline.Plug`, direct Sigra callback wiring, an authenticated incident drill-down reference path, and one contract-tested public docs story across all adopter entry points.

**Phases completed:** **49–52** (4 phases; 8 plans with `SUMMARY.md`; per-phase `VERIFICATION.md`; consolidated `v1.15-MILESTONE-AUDIT.md`).

**Key accomplishments:**

- Shipped native `Threadline.Plug` `:context_overrides_fn` support with additive-only `request_id` / `correlation_id` semantics, deterministic invalid-shape failures, and focused code/doc coverage (**PLUG-01/02**, Phase **49**).
- Shipped the direct `Threadline.Integrations.Sigra` callback pair as the canonical host path, removed the example-only delegate seam, and proved the router-path correlation fallback in tests (**SIGRA-04/05**, Phase **50**).
- Secured the example incident drill-down endpoint behind an authenticated baseline while preserving the established success and malformed-id contracts for authenticated callers (**INCIDENT-03/04**, Phase **51**).
- Aligned the quickstart, Sigra guide, README, domain reference, incident playbook, and adoption backlog on the same host-wiring story, then locked that wording with focused doc-contract suites (**ADOPT-03**, Phase **52**).

**Stats:** 4 phases, 8 plans, 7/7 requirements complete at close. Milestone window: **2026-05-05 → 2026-05-05**. Git range from **`v1.14`** tag **`da446e1`** through the v1.15 closeout tree touched **123 files** with **11502 insertions / 1231 deletions**.

**Archives:** `.planning/milestones/v1.15-REQUIREMENTS.md`, `.planning/milestones/v1.15-ROADMAP.md`, `.planning/milestones/v1.15-MILESTONE-AUDIT.md`, `.planning/milestones/v1.15-phases/`.

**Known gaps at close:** Milestone audit **passed** with 0 requirement, integration, or end-to-end flow gaps. The open-artifact audit still flagged **`SEED-001-sigra-integration-adapter`**, but that seed had already been promoted into v1.14 and was acknowledged as stale bookkeeping rather than live scope.

**What is next:** **`/gsd-new-milestone`** — define the next requirement set and roadmap slice on a fresh planning surface.

---

## v1.14 — Drop-in Production Adopter Slice (shipped 2026-05-05)

**Goal:** Make Threadline materially drop-in for production adopters by closing Sigra actor-mapping, publishing reproducible performance baselines, shipping a copy-pasteable incident playbook plus replay tooling, providing a first-hour SaaS quickstart, and packaging the result as the `0.3.0` release surface.

**Phases completed:** **44–48** (5 phases; 10 plans with `SUMMARY.md`; per-phase `VERIFICATION.md`; consolidated `v1.14-MILESTONE-AUDIT.md`).

**Key accomplishments:**

- Shipped **`Threadline.Integrations.Sigra`**, example-app Sigra wiring, and **`guides/integrations/sigra.md`** with locked doc-contract coverage (**SIGRA-01/02/03**, Phase **44**).
- Shipped the independent **`bench/`** harness, tracked baseline artifacts, **`mix verify.bench`**, and **`guides/performance.md`** with published baseline numbers and cost-knob comparisons (**PERF-01/02/03**, Phase **45**).
- Shipped **`guides/incident-playbook.md`**, the guarded replay script, **`guides/getting-started-saas.md`**, the walked STG example, and their paired contract/smoke tests (**INCIDENT-01/02**, **ADOPT-01/02**, Phases **46–47**).
- Shipped the **`0.3.0`** release surface across **`mix.exs`**, **`CHANGELOG.md`**, **`README.md`**, ExDoc grouping, **`mix verify.release`**, and **`test/threadline/release_artifact_contract_test.exs`** (**REL-01/02/03**, Phase **48**).

**Stats:** 5 phases, 10 plans, 13/13 requirements complete at close. Milestone window: **2026-04-26 → 2026-05-05**. Verified release candidate range from **`v1.13`** tag **`b3409c8`** to clean release commit **`4543690`** touched **79 files** with **8108 insertions / 350 deletions**.

**Archives:** `.planning/milestones/v1.14-REQUIREMENTS.md`, `.planning/milestones/v1.14-ROADMAP.md`, `.planning/milestones/v1.14-MILESTONE-AUDIT.md`, `.planning/milestones/v1.14-phases/`.

**Known gaps at close:** Milestone audit **passed** with 0 requirement, integration, or end-to-end flow gaps. Open-artifact audit still flagged **`SEED-001-sigra-integration-adapter`**, but that seed had already been promoted into Phase 44 and shipped; it was acknowledged as stale bookkeeping rather than a real open item.

**What is next:** **`/gsd-new-milestone`** — define the next requirements set and roadmap slice. Release verification for `0.3.0` was run against isolated clean commit **`4543690`**.

---

## v1.13 — Docs Contract Repair (shipped 2026-04-26)

**Goal:** Repair README contract drift on the root project and the Phoenix example so the published docs match the shipped public API surface, and restore the verification artifacts the milestone audit was missing — without new capture semantics or product surface.

**Phases completed:** **41–43** (3 phases; 3 plans with `SUMMARY.md`; per-phase `VERIFICATION.md` and consolidated `v1.13-MILESTONE-AUDIT.md`).

**Key accomplishments:**

- Repaired the root **`README.md`** intro, feature list, and quickstart so they explicitly reference **`Threadline.Plug`**, **`Threadline.record_action/2`**, **`Threadline.history/3`**, **`Threadline.timeline/2`**, **`Threadline.export_json/2`**, and **`Threadline.as_of/4`**, and tightened **`test/threadline/readme_doc_contract_test.exs`** to lock the literals (**DOC-01**, Phase **41-01**).
- Repaired **`examples/threadline_phoenix/README.md`** and **`examples/README.md`** so the Phoenix example is framed as the runnable contract (install / run / test / reconstruction) and the index points at it canonically; doc-contract test extended to assert example install/runbook + historical reconstruction literals (**DOC-02**, Phase **42-01**).
- Closed the audit evidence gap by writing **`41-VERIFICATION.md`**, **`42-VERIFICATION.md`**, and reconciling **`v1.13-MILESTONE-AUDIT.md`** + **`REQUIREMENTS.md`** traceability so DOC-01–03 are counted as verified (**DOC-03**, Phase **43-01**).

**Stats:** 3 phases, 3 plans, 3/3 summaries; v1.13 requirements **3/3** complete at close (see archived traceability). **`v1.13-MILESTONE-AUDIT.md`** **verified** with 0 gaps; targeted run `mix test test/threadline/readme_doc_contract_test.exs --seed 0` → 11 tests, 0 failures.

**Archives:** `.planning/milestones/v1.13-REQUIREMENTS.md`, `.planning/milestones/v1.13-ROADMAP.md`, `.planning/milestones/v1.13-MILESTONE-AUDIT.md`, `.planning/milestones/v1.13-phases/`.

**Known gaps at close:** None. **`SEED-001-sigra-integration-adapter`** remains dormant (acknowledged at close).

**What is next:** **`/gsd-new-milestone`** — fresh **`.planning/REQUIREMENTS.md`** and next roadmap slice when scope is ready.

---

## v1.12 — Temporal Truth & Safety (shipped 2026-04-25)

**Goal:** Stable foundation for **point-in-time row reconstruction** with map-first reads, opt-in struct reification, deleted-record / genesis-gap explicit errors, and copy-pasteable operator docs — without new capture semantics or LiveView.

**Phases completed:** **38–40** (3 phases; 3 plans with `SUMMARY.md`).

**Key accomplishments:**

- Shipped **`Threadline.as_of/4`** with **map-first** reconstruction, explicit **deleted-record** error, and **genesis-gap** atom-set errors (**ASOF-01 / 02 / 05**, Phase **38**).
- Shipped opt-in **`:cast`** reification that returns an Ecto struct with **loose historical loading** (ignores fields no longer in the current schema) (**ASOF-03 / 04**, Phase **39**).
- Shipped **Time Travel (As-of)** section in **`guides/domain-reference.md`** and the historical reconstruction walkthrough in **`examples/threadline_phoenix/README.md`** (**ASOF-06**, Phase **40**).

**Stats:** 3 phases, 3 plans, 3/3 summaries; v1.12 requirements **6/6** complete at close (see archived traceability). **`v1.12-MILESTONE-AUDIT.md`** **passed** at pre-close.

**Archives:** `.planning/milestones/v1.12-REQUIREMENTS.md`, `.planning/milestones/v1.12-ROADMAP.md`, `.planning/milestones/v1.12-MILESTONE-AUDIT.md`.

**Known gaps at close:** None for in-repo acceptance.

**What is next:** v1.13 docs contract repair (since shipped).

---

## v1.11 — Composable incident surface (shipped 2026-04-24)

**Goal:** Close the integrator **composition** gap — **`POST /api/posts`** returns **`audit_transaction_id`**, **`GET /api/audit_transactions/:id/changes`** returns ordered **`AuditChange`** rows with **`change_diff`** maps — without LiveView, **`threadline_web`**, or new capture semantics.

**Phases completed:** **37** (1 phase; 1 plan with `SUMMARY.md`; execution tree under **`.planning/milestones/v1.11-phases/`**).

**Key accomplishments:**

- Shipped **`POST /api/posts`** and **`GET /api/audit_transactions/:id/changes`** in **`examples/threadline_phoenix`** to prove composition of **`audit_transaction_id`**, **`audit_changes_for_transaction/2`**, and **`change_diff/2`** (**COMP-01**, **COMP-02**, Phase **37-01**).
- Shipped **`guides/domain-reference.md`** anchor **`COMP-EXAMPLE-INCIDENT-JSON`** and verified via **`ExplorationRoutingDocContractTest`** (**COMP-03**, Phase **37-01**).
- Formalized administrative artifacts for **v1.10** phases (**31–36**) and **v1.11** phase (**37**) to ensure complete planning history.

**Stats:** 1 phase (v1.11), 1 plan with summary; v1.11 requirements **3/3** complete at close (see archived traceability).

**Archives:** `.planning/milestones/v1.11-REQUIREMENTS.md`, `.planning/milestones/v1.11-ROADMAP.md`.

**What is next:** **`/gsd-new-milestone`** — fresh **`.planning/REQUIREMENTS.md`** and next roadmap slice when scope is ready.

---

## v1.10 — Support-grade exploration primitives (shipped 2026-04-24)

**Goal:** Support- and integrator-facing **exploration primitives** — **field-level** change presentation from `%AuditChange{}`, **transaction-scoped** change listing, and **operator doc routing** — on top of shipped capture + semantics + timeline/export, **without** LiveView or new capture semantics.

**Distribution:** **`v0.2.0`** / **`threadline` 0.2.0** unchanged unless a separate release milestone is run.

**Phases completed:** **31–36** (31–33 core: **4** plans with `SUMMARY.md`; **34–36** audit + planning hygiene via **`VERIFICATION.md`**).

**Key accomplishments:**

- Shipped **`Threadline.ChangeDiff`**, **`Threadline.change_diff/2`**, and **`test/threadline/change_diff_test.exs`** — deterministic JSON-serializable field maps (**XPLO-01**, Phases **31-01**, **31-02**).
- Shipped **`Threadline.Query.audit_changes_for_transaction/2`** and **`Threadline.audit_changes_for_transaction/2`** with documented stable ordering and DB-backed tests (**XPLO-02**, Phase **32-01**).
- Shipped **`guides/domain-reference.md`** **Exploration API routing (v1.10+)**, production-checklist cross-link, and **`Threadline.ExplorationRoutingDocContractTest`** (**XPLO-03**, Phase **33-01**).
- Closed **INT-DOC-01** / **FLOW-TEST-01** and **`ChangeDiff`** lowercase **`op`** normalization for trigger-shaped rows (**Phase 34**).
- Added **`34-VERIFICATION.md`** and aligned **`.planning/PROJECT.md`** with shipped **XPLO-03** (**Phase 35**); planning matrix + **`32-VALIDATION`** alignment (**Phase 36**).

**Stats:** 6 phases, 4 plans with summaries; v1.10 requirements **3/3** complete at close (see archived traceability). Standalone **`v1.10-MILESTONE-AUDIT.md`** **passed** at pre-close.

**Archives:** `.planning/milestones/v1.10-REQUIREMENTS.md`, `.planning/milestones/v1.10-ROADMAP.md`, `.planning/milestones/v1.10-MILESTONE-AUDIT.md`.

**Known gaps at close:** None for in-repo acceptance. **`gsd-sdk query milestone.complete`** returned **`version required for phases archive`** — archives written manually (same as **v1.9**).

**What is next:** **`/gsd-new-milestone`** — fresh **`.planning/REQUIREMENTS.md`** and next roadmap slice when scope is ready.

---

## v1.9 — Production confidence at volume (shipped 2026-04-24)

**Goal:** Credible **ops-at-volume** narrative for telemetry + **`Threadline.Health`**, a durable **audit indexing** cookbook with doc contracts, and **retention-at-scale** guidance tied to **`Threadline.Retention`** / export / timeline — **docs-first**.

**Distribution:** **`v0.2.0`** / **`threadline` 0.2.0** unchanged unless a separate release decision is made.

**Phases completed:** **28–30** (3 phases; 6 plans with `SUMMARY.md`; execution trees under **`.planning/milestones/v1.9-phases/`**).

**Key accomplishments:**

- Shipped per-event **telemetry** operator narrative + **`## Trigger coverage (operational)`** in **`guides/domain-reference.md`**; checklist cross-links (**Phase 28**, OPS-01, OPS-02).
- Shipped **`guides/audit-indexing.md`**, ExDoc extra, cross-links, **`test/threadline/audit_indexing_doc_contract_test.exs`** (**Phase 29**, IDX-01, IDX-02).
- Shipped **`guides/production-checklist.md`** volume / purge cadence H3; **`guides/domain-reference.md`** **`## Operating at scale (v1.9+)`** hub; **README** Maintainer-band discovery (**Phase 30**, SCALE-01, SCALE-02).

**Stats:** 3 phases, 6 plans, 6/6 summaries; v1.9 requirements **6/6** complete at close (see archived traceability).

**Archives:** `.planning/milestones/v1.9-REQUIREMENTS.md`, `.planning/milestones/v1.9-ROADMAP.md`.

**Known gaps at close:** None for in-repo acceptance. No standalone **`v1.9-MILESTONE-AUDIT.md`**; optional **`/gsd-audit-milestone`** next time. **`gsd-sdk query milestone.complete`** returned **`version required for phases archive`** — archives written manually.

**What is next:** **`/gsd-new-milestone`** — fresh **`.planning/REQUIREMENTS.md`** and next roadmap slice when scope is ready.

---

## v1.8 — Close the support loop (shipped 2026-04-24)

**Goal:** Reduce SaaS support **time-to-answer** with **correlation-aware** timeline + export, **operator playbooks** in guides, an **example app** correlation path, and **doc contract** anchors.

**Distribution:** **`v0.2.0`** / **`threadline` 0.2.0** unchanged unless a separate release decision is made.

**Phases completed:** **25–27** (3 phases; 5 plans with `SUMMARY.md`; execution trees under **`.planning/milestones/v1.8-phases/`**).

**Key accomplishments:**

- Shipped **`:correlation_id`** on **`Threadline.Query`** / **`Threadline.Export`** with strict `AuditAction` join when set, validation + integration tests, CHANGELOG (**Phase 25**, LOOP-01).
- Shipped **Support incident queries** in **`guides/domain-reference.md`** and **`guides/production-checklist.md`**; marker **`LOOP-04-SUPPORT-INCIDENT-QUERIES`**; **`test/threadline/support_playbook_doc_contract_test.exs`** (**Phase 26**, LOOP-02, LOOP-04).
- Shipped example **`POST /api/posts`** with **`record_action`**, linked **`audit_transactions.action_id`**, **`ThreadlinePhoenixWeb.PostsCorrelationPathTest`**, README **`export_json`** / **`jq`** (**Phase 27**, LOOP-03).

**Stats:** 3 phases, 5 plans, 5/5 summaries; v1.8 requirements **4/4** complete at close (see archived traceability).

**Archives:** `.planning/milestones/v1.8-REQUIREMENTS.md`, `.planning/milestones/v1.8-ROADMAP.md`.

**Known gaps at close:** None for in-repo acceptance. No standalone `v1.8-MILESTONE-AUDIT.md`; optional **`/gsd-audit-milestone`** next time. `gsd-sdk query milestone.complete` returned `version required for phases archive` — archives written manually.

**What is next:** **`/gsd-new-milestone`** — fresh **`.planning/REQUIREMENTS.md`** and next roadmap slice when the **next** planning milestone scope is ready.

---

## v1.7 — Reference integration for SaaS (shipped 2026-04-24)

**Goal:** Runnable in-repo Phoenix example (**`examples/threadline_phoenix/`**) with HTTP + Oban audited paths, `record_action/2`, and links to production checklist + STG rubric.

**Distribution:** **`v0.2.0`** / **`threadline` 0.2.0** unchanged unless a separate release decision is made.

**Phases completed:** 22–24 (3 phases; 5 plans with `SUMMARY.md` under `.planning/milestones/v1.7-phases/`).

**Key accomplishments:**

- Shipped **path-dep** Phoenix example with **`mix threadline.install`**, **`mix threadline.gen.triggers`** for **`posts`**, **`mix verify.example`** in **`mix ci.all`**, and contributor README runbook (**Phase 22**).
- Landed **HTTP audited path**: **`Threadline.Plug`** on `:api`, **`Blog.create_post/2`** with transaction-local GUC, ConnCase proof for audit rows (**Phase 23**).
- Landed **Oban** **`PostTouchWorker`**, **`Threadline.Job`** + **`record_action(:post_title_refreshed_from_queue, …)`** with integration test (Sandbox **`unboxed_run`** where needed); README **Semantics in jobs** + links to **`guides/production-checklist.md`** and **`guides/adoption-pilot-backlog.md`** (**Phase 24**).

**Stats:** 3 phases, 5 plans, 5/5 summaries; v1.7 requirements **6/6** complete at close (see archived traceability; living `REQUIREMENTS.md` had lagging REF-04–REF-06 checkboxes — reconciled in archive).

**Archives:** `.planning/milestones/v1.7-REQUIREMENTS.md`, `.planning/milestones/v1.7-ROADMAP.md`.

**Known gaps at close:** None for in-repo acceptance. No standalone `v1.7-MILESTONE-AUDIT.md`; optional **`/gsd-audit-milestone`** next time. `gsd-sdk query milestone.complete` returned `version required for phases archive` — archives written manually.

**What is next:** **`/gsd-new-milestone`** — fresh `.planning/REQUIREMENTS.md` and next roadmap slice when scope is ready.

---

## v1.6 — Host staging / pooler parity (shipped 2026-04-24)

**Goal:** Close the gap between **library CI** and **honest host documentation** using integrator-owned templates and evidence pointers — not maintainer attestation of third-party staging (**STG-01**–**STG-03**).

**Distribution:** **`v0.2.0`** / **`threadline` 0.2.0** unchanged unless a separate release decision is made.

**Phases completed:** 21 (1 phase; 2 plans with `SUMMARY.md` under `.planning/phases/21-host-staging-pooler-parity/`).

**Key accomplishments:**

- Landed **STG-HOST-TOPOLOGY-TEMPLATE** and **STG-AUDITED-PATH-RUBRIC** in **`guides/adoption-pilot-backlog.md`** with doc contracts in **`test/threadline/ci_topology_contract_test.exs`**.
- Added **`CONTRIBUTING.md`** **`## Host STG evidence (integrators)`** (fork + PR workflow, redaction emphasis) and **`guides/production-checklist.md`** cross-link to the rubric.
- Shipped **`test/threadline/stg_doc_contract_test.exs`** tying CONTRIBUTING, checklist, and backlog anchors; **`DB_PORT=5433 MIX_ENV=test mix ci.all`** green at close.

**Stats:** 1 phase, 2 plans, 2/2 summaries; v1.6 requirements **3/3** complete at close (see archived traceability; living file had lagging checkboxes — reconciled in archive).

**Archives:** `.planning/milestones/v1.6-REQUIREMENTS.md`, `.planning/milestones/v1.6-ROADMAP.md`.

**Known gaps at close:** None for in-repo acceptance. No standalone `v1.6-MILESTONE-AUDIT.md`; optional **`/gsd-audit-milestone`** next time. `gsd-sdk query milestone.complete` returned `version required for phases archive` — archives written manually.

**What is next:** **`/gsd-new-milestone`** — fresh `.planning/REQUIREMENTS.md` and next roadmap slice when scope is ready.

---

## v1.5 — Adoption feedback loop (shipped 2026-04-23)

**Goal:** Integrator-led adoption — operator telemetry reference, **`guides/adoption-pilot-backlog.md`**, README/ExDoc wiring; **Phase 20** closed **ADOP-03** (2026-04-23) with maintainer CI–backed backlog evidence + **STG-01** follow-up for host pooler/staging depth.

**Distribution:** **`v0.2.0`** pushed; **`threadline` 0.2.0** on Hex (same day).

**Phases completed:** 19–20 (2 phases; plans evidenced via `PLAN.md` / `VERIFICATION.md` under `.planning/phases/`).

**Key accomplishments:**

- Shipped **`guides/adoption-pilot-backlog.md`** with checklist matrix, distribution preflight, and prioritized follow-ups aligned to **`guides/production-checklist.md`**.
- Documented all **`[:threadline, …]`** telemetry events in **`guides/domain-reference.md`** with cross-links from the production checklist (**TELEM-01** / **TELEM-02**).
- README and ExDoc extras surface the pilot backlog for integrator discovery (**ADOP-01** / **ADOP-02**).
- Closed **ADOP-03** with maintainer CI evidence in the backlog; **`AP-ENV.1`** routed to **`STG-01`** for honest host pooler/staging depth.
- CI: **`verify-pgbouncer-topology`** plus contract tests exercise pooler topology paths on `main`.

**Stats:** 2 phases; 5/5 v1.5 requirements complete at close (traceability table).

**Archives:** `.planning/milestones/v1.5-REQUIREMENTS.md`, `.planning/milestones/v1.5-ROADMAP.md`.

**Note:** No standalone `v1.5-MILESTONE-AUDIT.md` in `.planning/` at close; optional `/gsd-audit-milestone` next time for extra assurance. `gsd-sdk query milestone.complete` returned `version required for phases archive` in this environment — archives were written manually to match prior milestones.

**What is next (historical at v1.5 close):** v1.6 — shipped 2026-04-24; see **v1.6** entry above.

---

## v1.4 — Adoption & release readiness (shipped 2026-04-23)

**Delivered:** README **`~> 0.2`**, quickstart **export** step, documentation index links; **`guides/production-checklist.md`**; **`Threadline.Query.timeline_repo!/2`**, timeline filter validation before repo resolution, clearer `ArgumentError` messages; **`mix.exs` 0.2.0**, **CHANGELOG 0.2.0** narrative for upgraders from 0.1.0; ExDoc **extras** + **`Threadline.Retention`** / **`Policy`** in module groups.

**Phases completed:** 15–18 (adoption slice; no per-phase execution trees — `gsd-sdk query phases.clear` at milestone open).

**Archives:** `.planning/milestones/v1.4-REQUIREMENTS.md`, `.planning/milestones/v1.4-ROADMAP.md`.

**What is next:** Tag **`v0.2.0`** and `mix hex.publish` when ready; **`/gsd-new-milestone`** for **v1.5**.

---

## v1.3 — Production adoption (redaction, retention, export) (shipped 2026-04-23)

**Delivered:** **Capture-time redaction** (`RedactionPolicy`, `TriggerSQL` exclude/mask, `config :threadline, :trigger_capture`, `mix threadline.gen.triggers` integration); **retention + batched purge** (`Threadline.Retention.Policy`, `Threadline.Retention.purge/1`, `mix threadline.retention.purge`); **CSV/JSON export** (`Threadline.Export`, shared timeline filter validation, `mix threadline.export`, README + domain guide).

**Phases completed:** 12–14 (6 plans).

**Key accomplishments:**

- Landed REDN-01/REDN-02: per-table exclude/mask at trigger generation with PostgreSQL integration tests and operator docs (Path B safe).
- Landed RETN-01/RETN-02: documented retention window, batched idempotent purge with orphan transaction cleanup and Mix task ergonomics.
- Landed EXPO-01/EXPO-02: export APIs and Mix task aligned with `Threadline.Query.timeline/2` filters; NimbleCSV-backed CSV and JSON/NDJSON paths with stream support.

**Stats:**

- v1.3-focused window (see `git log` from `2b7f879` / `fb65250` through tip): phases 12–14 feature and docs commits; six plan summaries complete on disk.
- 3 phases, 6 plans, 100% summaries; requirements traceability 6/6 Complete at close.

**Archives:**

- Roadmap: `.planning/milestones/v1.3-ROADMAP.md`
- Requirements: `.planning/milestones/v1.3-REQUIREMENTS.md`

**Note:** No standalone `v1.3-MILESTONE-AUDIT.md` in `.planning/` at close; optional `/gsd-audit-milestone` next time for extra assurance. `gsd-sdk query milestone.complete` returned `version required for phases archive` in this environment — archives were written manually to match prior milestones.

**What is next:** `/gsd-new-milestone` — define the next product slice and a fresh `.planning/REQUIREMENTS.md`.

---

## v1.2 — Before-values & developer tooling (shipped 2026-04-23)

**Delivered:** Optional per-table **`changed_from`** on UPDATE captures with opt-in trigger generation; **`mix threadline.verify_coverage`** and CI wiring; **README doc contract** tests and Nyquist parity for expanded `ci.all`; **`Threadline.Continuity`** + **`mix threadline.continuity`** with brownfield integration coverage and **`guides/brownfield-continuity.md`**.

**Phases completed:** 9–11 (6 plans).

**Key accomplishments:**

- Landed BVAL-01/BVAL-02: migration + `--store-changed-from` triggers, `AuditChange.changed_from`, integration tests, `history/3` documentation.
- Shipped TOOL-01: `Threadline.Verify.CoveragePolicy`, `Mix.Tasks.Threadline.VerifyCoverage`, canary migration for CI failure path, README maintainer guidance.
- Shipped TOOL-03: quickstart fixtures, `readme_doc_contract_test.exs`, `verify.threadline` / `verify.doc_contract` in `ci.all` and GitHub Actions.
- Shipped TOOL-02: `Threadline.Continuity`, continuity Mix task, brownfield test, guide + README + HexDocs extras cross-links.

**Stats:**

- v1.2-focused window (see `git log` from `002bdf7` through tip): feature and docs commits across capture, verify, continuity; six plan summaries complete on disk.
- 3 phases, 6 plans, 100% summaries; requirements traceability 5/5 Complete at close.

**Archives:**

- Roadmap: `.planning/milestones/v1.2-ROADMAP.md`
- Requirements: `.planning/milestones/v1.2-REQUIREMENTS.md`

**Note:** No standalone `v1.2-MILESTONE-AUDIT.md` in `.planning/` at close; optional `/gsd-audit-milestone` next time for extra assurance.

**What is next:** `/gsd-new-milestone` — define the next product slice and a fresh `.planning/REQUIREMENTS.md`.

---

## v1.1 — GitHub, CI, and Hex (shipped 2026-04-23)

**Delivered:** Canonical GitHub `origin` with `@source_url` / docs alignment; GitHub Actions all green on `main` with maintainer-recorded CI-02 proof; **`threadline` 0.1.0** on Hex with dated `CHANGELOG.md` and **`v0.1.0`** on `origin`; Phase 8 closed audit gaps (remote/`main`, live CI, traceability).

**Phases completed:** 5–8 (7 plans).

**Key accomplishments:**

- Locked REPO-01–REPO-03 with CLI-verified evidence and `main` ↔ `origin/main` alignment.
- Landed CI-01–CI-03: stable job keys, release-hygiene jobs, README/CONTRIBUTING CI surfacing, and Nyquist contract tests for the workflow shape.
- Shipped HEX-01–HEX-04: `0.1.0` semver, changelog section, annotated tag pushed, registry-visible package.
- Refreshed Phase 8 verification so `06-VERIFICATION.md`, requirement checklists, and phase summaries agree on live GitHub state.

**Stats:**

- ~58 files touched, ~3.9k insertions in the `v1.0..HEAD` window (distribution + CI + Hex).
- ~2.4k lines of Elixir under `lib/` + `test/` (`wc` on `*.ex` / `*.exs` at close).
- 4 phases, 7 plans, 100% summaries on disk; milestone audit **passed** (2026-04-23).

**Archives:**

- Roadmap: `.planning/milestones/v1.1-ROADMAP.md`
- Requirements: `.planning/milestones/v1.1-REQUIREMENTS.md`
- Milestone audit: `.planning/milestones/v1.1-MILESTONE-AUDIT.md`
- Phase execution tree: `.planning/milestones/v1.1-phases/`

**What is next:** `/gsd-new-milestone` — define v1.2+ product requirements (see v2 backlog in `v1.0-REQUIREMENTS.md` archive).

---

## v1.0 MVP (shipped 2026-04-23)

**Delivered:** Trigger-backed row capture (Path B), application semantics (`ActorRef`, `record_action/2`, Plug/Job context), query and telemetry APIs, and release-grade docs with ExDoc/Hex build gates.

**Phases completed:** 1–4 (10 plans).

**Key accomplishments:**

- Closed the capture substrate via `gate-01-01.md` and shipped `Threadline.Capture` triggers with idempotent installer tasks and CI.
- Landed semantics: `AuditAction`, six-way `ActorRef`, transaction-local GUC bridge, `Threadline.Plug`, and `Threadline.Job`.
- Shipped `Threadline.Query` (`history`, `actor_history`, `timeline`), `Threadline.Health.trigger_coverage/1`, and structured `:telemetry` events.
- Published-quality README, `guides/domain-reference.md`, LICENSE, CHANGELOG stub, ExDoc layout, and `mix hex.build` / `mix ci.all` green.

**Stats:**

- ~95 files touched from initial commit to tip (`git diff --stat` range); ~11k insertions in that window.
- ~2.3k lines of Elixir under `lib/` + `test/` (wc on `*.ex` / `*.exs`).
- 4 phases, 10 plans, 100% roadmap summaries on disk at close.

**Archives:**

- Roadmap: `.planning/milestones/v1.0-ROADMAP.md`
- Requirements: `.planning/milestones/v1.0-REQUIREMENTS.md`
- Phase execution tree: `.planning/milestones/v1.0-phases/`

**What is next:** Cut application tag `v0.1.0`, run `mix hex.publish` when ready, then `/gsd-new-milestone` for v1.1 themes (see v2 requirement backlog in archived requirements).

---

## v1.17 — Operator Surface Foundation

**Status:** Completed
**Date:** 2026-05-06
**Phases:** 57-63
**Requirements:** 18/18

Shipped a host-usable operator surface, providing an in-tree LiveView UI that turns v1.16 investigation contracts into one-click answers while preserving the v1.15 host-owns-auth boundary.
