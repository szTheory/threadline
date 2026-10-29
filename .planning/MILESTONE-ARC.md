# Milestone Arc: Threadline

**Updated:** 2026-10-29 (v1.47 closed; rolling quality roadmap adopted 2026-10-24 after the 1.1.0 release)
**Active milestone:** none. Next: v1.48 Safe by default (re-derive the baseline first).
**Posture:** rolling background quality. The maintainer's attention is elsewhere, so operator-UI feedback is parked until they bring it. Meanwhile, work through evidence-backed foundation milestones. Each milestone is short and ends in a release, and the ranking is re-derived at each close. The maintainer will dogfood Threadline in their own projects, so the standing goal is "no bitrot": main green, PRs triaged, specs honest, deps lean, performance measured, intent remembered.

For the lasting intent, persona lenses, selection loop, quality/CI/release bar, and horizons, see `.planning/MILESTONE-GUIDE.txt`. This file is the concise live ranking. Where the guide and current evidence disagree, go by current state and evidence.

## Rolling quality roadmap (2026-10-24)

Evidence, file references, the rejected list, and the verified carried-debt register: `.planning/research/QUALITY-ROADMAP-2026-10-24.md`.

| Rank | Version | Theme | Release | Status |
|------|---------|-------|---------|--------|
| 1 | v1.47 | Release on autopilot: CHANGELOG auto-dating, stale release-PR refresh, Dependabot security-only + SHA pins, tiered deps-audit, fetch retries, browser-lane timing then per-project split, contract tests on one lane, debt-register closeout, critic retired to a tag | none (no shipped change; REL-01 tail deferred to the next natural release) | shipped 2026-10-29 |
| 2 | v1.48 | Safe by default: operator surface fail-closed (bug fix), txid-reuse detection then trigger fix, CSV/header hardening, search_path pin + single SQL quoting, PgBouncer lock check, honest bypass/least-privilege/sandbox guides, floor to Elixir 1.17 / OTP 27 | 1.2.0 | next |
| 3 | v1.49 | Honest specs: dependency-free mutation replay, time-boxed contract-test keep/merge/delete, one-shot coverage probe, dependency-floor lane, twin probes | patch | queued |
| 4 | v1.50 | Measured performance: in-server capture bench vs untriggered control with weekly ratchet, retention orphan-drain fix, adopter index generator, `timeline/2` `:limit`, honest performance guide | minor | queued |
| 5 | v1.51 | Lean dependency tree: vendor CSV writer, Plug optional (required tree 11 to 7), drop unused optional deps, de-duplicate encoders/helpers, runtime-cycle gate, tooling out of `lib/` | minor | queued |

Maintainer decisions, 2026-10-24 (in-session, after a research fan-out):
- D-1: the operator surface fails open, but its docs promise fail-closed. Fix it as a bug in 1.2.0: a mount without `authorize_fn` or the explicit unauthenticated acknowledgement becomes a compile error with a fix-it message.
- D-2: txid reuse after a logical restore. Detect it first with a health finding and docs, then fix the trigger key with a regenerate-triggers upgrade note.
- D-3: raise the supported floor to Elixir 1.17 / OTP 27 in a minor release.
- D-4: retire the parked UI-critic loop to a git tag.
- Operating grants: a standing merge grant for agent quality PRs (all required CI green and automated review clean; public API, defaults, scope, and spend still escalate); release when releasable (the maintainer approves `production-hex`); standard agent spend.
- Maintainer action outstanding: move `HEX_API_KEY` to a `production-hex` environment secret.

## Current position after v1.47 (2026-10-29)

v1.47 closed with 5 phases (including gap phase 247.1), 66 plans, and 13/14 requirements. The audit is `tech_debt`, closed as `override_closeout`. It shipped no Hex release: no merge changed the package, and the CI-only `fix(ci):` #100 opened release PR #101, which was closed unmerged once the `exclude-paths` guard landed. REL-01 is deferred-with-trigger: the first natural release PR, likely v1.48's 1.2.0, must reach green CI with no CHANGELOG-dating PR, with its own Unreleased prose (W-3). Carried items to weigh at the v1.48 baseline: Dependabot #92 (needs a `ci(deps):` PR), deps-health #61, CI-02 drift (main wall 486 s, no regression guard), T-247-46/47 accepted-risk entries, and W-1/W-2 (root-file and `deps:` lock-only release-type gaps). Took 6 calendar days (2026-10-24 to 2026-10-29); phase 247 was the long pole at 37 plans.

## Current position after v1.46 (2026-10-11)

The six approved phases delivered the existing operator investigation and
operations refinement scope. The milestone audit reports no unsatisfied
requirements or broken flows; 24/26 integration paths are fully wired, with the
remaining two satisfying their requirements under explicit visual-evidence
limits. Carry forward the baseline-existing History drawer/header overlap,
dense-typography contract drift, and Redaction empty-category copy for explicit
future disposition. Do not start another broad UI pass by default. Re-derive the
adopter, operator, security, and release baseline using Guide §6 before choosing
the next milestone. No successor is selected.

## Approved UI milestone (2026-10-08)

The maintainer supplied concrete feedback about readable hierarchy, consistent
components/tokens/domain copy, conventional controls, responsive behavior and
bounded automated visual review. Read-only research covered current Threadline
main and Scrypath's post-completion fixes, plus Accrue/Mailglass's ongoing work.
The proposal is refinement of existing operator jobs, with source-bound rendered
evidence and no new paid critic loop. See the preflight record for provenance,
candidate defects, evidence limitations, the adapted prompt and next commands.

GitHub main was verified at 9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2 (1.0.1
distribution sync). The earlier 1.0.0 baseline below predates that patch and this
UI feedback; retain it as history, not a veto on evaluating the requested work.
Preserve the dirty planning checkout; later implementation starts from current
main with the planning and product context carried over. The maintainer approved
v1.46, the proposed scope and reuse of the completed research. Milestone setup is complete: all 26 requirements
and the six-phase roadmap are approved. At setup, the next command was `$gsd-execute-phase 239`. Phase 238 completed with source-bound evidence; retain the existing implementation worktree and read its handoff. Impeccable init is complete; equal engineer/operator
priority and code-first are settled. v1.45 and Phase 237 remain complete.

## Strategic thesis

The 2026-05-29 claim of "~92–95% done, default hold" measured the **adopter-facing docs and first-hour path**. It never measured whether capture behaves correctly on real table shapes. A re-derived baseline on 2026-09-25 found gaps that matter to any adopter:

- trigger SQL hardcodes the PK column `id` (`trigger_sql.ex:183-409`), so tables keyed any other way silently store `{"id": null}`
- per-table function names collide across Postgres schemas (redaction bypass)
- long table names raise a misleading error
- no property tests
- deferred dependency advisories and no audit gate
- nightly flake runs burn ~4,300 runner-min/month with no signal
- ~100 public functions without `@spec`

These are quality defects, not new scope. Under the guide §5 they justify milestones without adopter signal. New product scope still needs signal.

## Ladder to 1.0.0 (complete; original estimate was 6–9 weeks)

Actual at v1.45 close (2026-10-07, America/New_York): 1.0.0 shipped to Hex.pm; the milestone took five calendar days, with 7 phases, 47 plans, and 116 planned tasks. The milestone audit passed with disclosed review debt and no blockers. This finished the ladder ahead of the prior mid-to-late October estimate.

Re-estimate, 2026-09-30: two rungs remain. v1.42 took about 1 day and v1.43 took 4 days (10 phases). v1.44 and v1.45 carry more product-code work, so we budget about 1–2 weeks each. That puts 1.0.0 around mid-to-late October 2026, and mid-November is now the conservative upper bound.

| Rank | Version | Theme | Release | Status |
|------|---------|-------|---------|--------|
| 1 | v1.42 | Capture Correctness for Real Table Shapes | 0.11.0 | shipped 2026-09-26 |
| 2 | v1.43 | Supply Chain, CI Economy and Repo Hygiene | 0.11.1, 0.11.2 | shipped 2026-09-30 |
| 3 | v1.44 | Behavioral Depth: Properties, Twins, Telemetry | 0.12.0 | shipped 2026-10-02 |
| 4 | v1.45 | 1.0 API Contract | 1.0.0 | shipped; closeout passed 2026-10-07 |

Scope per rung: `.planning/MILESTONE-GUIDE.txt` §7 (canonical; don't duplicate it here).

## Re-derived baseline (2026-10-08)

**Earlier recommendation, before the UI feedback: narrow sustainment; no new milestone cleared the evidence bar.** On `origin/main` at `edb5138f350f7719778b01a9a85fba49391df32f`, required CI and the minimum/current/latest, browser, dependency-audit, and repo-protection checks pass. Hex, `mix.exs`, and CHANGELOG agree on 1.0.0. There are no open PRs. Open issue #76 refers to an earlier scheduled red SHA (`0d6f36f1`); #61 reports no retired or security-advisory packages, only routine update candidates. Keep both on release-train monitoring, not in milestone scope.

The v1.45 closeout audit has no blockers or open high/critical threats. Its remaining API error-contract findings are narrow patch candidates; re-triage each against current `main` before acting. The operator reconnect seed shipped in Phase 178, and its old open status is corrected in the seed record. The export-queue reconnect control remains a possible small UI follow-up, but no operator incident or maintainer feedback supports a milestone. Existing Sigra integration is shipped, and no current adopter issue identifies a new integration gap.

GSD cross-phase audit on 2026-10-08 found 61 items in 22 archived UAT/deferred files (59 deferred items and two optional Phase 104 editorial checks), zero current-milestone items, and zero parse gaps after normalizing the legacy Phase 06 UAT file. The Windows ledger has 59 open entries, all from archived Phases 198–202; `workflow.windows_enforce` is false. The Phase 235 documentation-routing deviation was waived after checking it on `origin/main`, and both Phase 221 advisories were verified resolved there. Keep this historic audit debt visible; it does not create a new milestone candidate.

The local `milestone/v1.44` checkout is not a current implementation base: its `mix.exs` still reports 0.11.2, while `origin/main` is at 1.0.0. Preserve it and its unrelated local edits; if code work becomes justified, start from a clean branch or worktree at current `origin/main`.

Reopen milestone selection when a reproduced adopter blocker, material operator incident, new security advisory/high-severity finding, or sustained measurable CI/correctness regression clears the guide's bar. Until then, maintain the 1.0.0 release train and take patch-sized fixes individually. At the 2026-10-08 pre-feedback baseline, Phase 237 was the final v1.45 phase and no successor had been selected; subsequent maintainer feedback authorized v1.46 (Phases 238–243), now complete. For the next cycle, start `$gsd-new-milestone` only after a new evidence-backed trigger; further operator UI and wider integrations are not default scope. The paid critic remains parked.

Signal-gated long horizon:
- GDPR erasure of captured rows
- per-table retention
- partitioned tables and RLS
- multiple repos
- external pilot (v1.28)
- compliance packs

## Activation rules

- At `/gsd-new-milestone`, re-derive the baseline and recommend the next evidence-backed outcome (guide §6). The 1.0.0 ladder is complete; do not infer a next milestone from the old rung order.
- At each close, mark the rung shipped, re-estimate the 1.0.0 date, and refresh this table and guide §7.
- **Do not** open compliance-pack / legal-hold / immutable-archive milestones without procurement pressure.
- **Do not** open Pow/bearer auth lane or second reference app without explicit demand.
- **Do not** make operator-UI design the next milestone by default; first re-derive the baseline and confirm the maintainer feedback that would justify it.

## History (condensed)

| Range | Theme |
|-------|-------|
| v1.0–v1.29 | Capture, semantics, exploration, integrations, distribution, first-hour parity (Hex 0.6.0) |
| v1.30–v1.34 | Adoption evidence automation, brand review, local Docker admin UI DX |
| v1.35–v1.40 | Brand identity, light mode, operator design system, page-by-page UI polish, quality baseline + storage schema (0.9.0), automated UI critic (parked) |
| v1.41 | Green, Clean, and Honest: real gates, 0.10.0–0.10.2 |
| v1.42 | Capture Correctness for Real Table Shapes: PK-agnostic, collision-free capture (0.11.0) |
| v1.43 | Supply Chain, CI Economy and Repo Hygiene: audit gate, toolchain pin, PII guard, measured CI cuts (0.11.1, 0.11.2) |

Full per-milestone record: `.planning/MILESTONES.md`. The superseded "hold" arc (2026-06-07) is in git history.
