# Phase 237: Upgrade Guide and 1.0.0 - Research

**Researched:** 2026-10-07
**Domain:** Elixir adopter documentation, conventional-commit release automation, local release-artifact rehearsal
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Upgrade path and CHANGELOG coverage

- **D-01 — Keep one 1.0 upgrade guide for both supported starting lines.** A 0.11.x adopter gets a concise conditional preflight for the three 0.12.0 breaking changes (capture-option shape, telemetry actor metadata, and health-error metadata); it states the required action and links to the 0.12.0 CHANGELOG / upgrade-path details. A 0.12.x adopter skips that preflight. Then both readers follow the seven numbered 1.0 steps named in DOCS-03. Preserve the existing one-off 0.11 trigger migration as a prior-upgrade prerequisite if an adopter skipped it; do not imply that any of the 1.0 changes requires trigger regeneration.

- **D-02 — Make the seven step categories cover every actual 1.0 CHANGELOG break and deprecation.** The listed categories are facade/API use, bounded row history, Page, lookup behavior, action association, PostgreSQL floor, and deprecations. Some categories may map to multiple CHANGELOG entries; no current Unreleased breaking-change or deprecation entry may be left unmapped. The conditional 0.11 preflight separately covers the three 0.12.0 breaking entries.

- **D-03 — Use stable, hidden change IDs as the document contract.** Put machine-readable IDs in invisible HTML comments beside relevant human-owned CHANGELOG entries and guide steps. The focused ExUnit contract compares the scoped ID sets for 0.12.0 prerequisites and 1.0 changes, and fails on a missing, extra, duplicate, or unmatched ID. Keep the guide and human-owned CHANGELOG hand-written; do not introduce a manifest or generated migration prose. Give the new contract test an explicit partition weight.

### Release-please 1.0.0 rehearsal and landing

- **D-04 — Extend the existing disposable-clone rehearsal to prove the exact committed 1.0.0 candidate.** The rehearsal must validate that candidate HEAD has a conventional feat! subject, exactly one Release-As: 1.0.0 footer, and release-please-config.json sets bump-minor-pre-major to false. It must use that footer as the simulated target, assert 1.0.0 (and reject 0.13.0), then run the existing bumped-artifact contracts inside the disposable clone. Run it against the committed candidate squash before push or merge. The report must call this a local artifact rehearsal, not a live Release Please invocation; the generated Release PR/run after landing supplies the live-action evidence.

- **D-05 — Preserve the maintainer-only release boundary.** Re-check the latest-lane pins and the PostgreSQL 15 minimum lane as part of landing evidence. Push, merge, and production-hex publication remain separate operations, each requiring an explicit maintainer grant. Hex publication is one-way; do not let a green rehearsal or CI result stand in for those grants.

### the agent's Discretion

- Exact stable-ID spellings, Markdown comment syntax, and ExUnit module/file placement, provided the scoped ID sets are exact and diagnostic failures identify the missing or extra change.
- The precise prose and headings for the seven steps and the conditional 0.11 preflight, provided each required action is explicit and the guide follows the existing upgrade-guide voice.
- The isolated mechanics for producing a committed candidate squash for rehearsal, provided it does not push, merge, publish, or mutate the user's real worktree outside the approved Phase 237 files.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within the Phase 237 scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCS-03 | `guides/upgrading-to-1.0.md` takes a 0.11 or 0.12 adopter to 1.0, with one numbered step per breaking change in this milestone: the facade collapse; history default; `Page` struct; lookup return shapes; association; PostgreSQL floor; deprecations. It follows the `upgrading-to-0.11.md` template and voice and says whether trigger regeneration is required. A doc-contract test cross-checks guide steps against CHANGELOG breaking-change entries. | Existing guide format and source entries inspected below; stable hidden IDs give exact scope equality, while guide graph, ExDoc extras, and partition-weight contracts require wiring. |
| REL-01 | release-please proposes exactly 1.0.0: `bump-minor-pre-major` is off in the landing change; squash carries a `Release-As: 1.0.0` footer; local rehearsal asserts 1.0.0 and rejects 0.13.0 before merge. | Official Release Please documentation confirms footer and config semantics. The current rehearsal derives 0.13.0 from 0.12.0 and needs candidate-footer-bound behavior. |
| REL-02 | The 1.0.0 CHANGELOG lists every milestone breaking change and deprecation, cross-checked against `git log --grep="BREAKING CHANGE"` for the milestone range; generated release notes are not trusted to carry footers. | Human-owned CHANGELOG contains 12 current Unreleased breaking entries and eight deprecation entries; separate cross-check needs to reconcile all milestone commits and record it in VERIFICATION.md. |
| REL-03 | Milestone lands on main as one conventional `feat!:` squash and ships 1.0.0 through Release Please; latest lane pins are re-checked. Push, merge, and production-hex publish each require explicit maintainer grants. | Existing release workflow separates Release Please, pin sync, CI, and protected `production-hex` publish. Release Please does not publish packages; external actions stay outside the local rehearsal. |
</phase_requirements>

## Summary

Treat this as two connected deliverables: a human-owned upgrade path with mechanical source coverage, and a release-boundary rehearsal that proves the committed candidate can produce a simulated 1.0.0 artifact tree. The Unreleased human changelog is the source for adopter action; `CHANGELOG-GENERATED.md` remains release-please-owned and must not be treated as the authority for upgrade guidance. The selected design is one `guides/upgrading-to-1.0.md` with a conditional 0.11.x preflight for the three 0.12.0 breaks and seven numbered 1.0 step categories.

Use hidden stable IDs beside changelog entries and guide steps, then compare exact unique ID sets separately for the 0.12.0 preflight and 1.0 changes. This proves coverage without publishing internal planning language or introducing a third manifest. Extend `bin/verify-bump-rehearsal` to inspect the committed candidate HEAD, bind its local artifact simulation to exactly one `Release-As: 1.0.0` footer, require a conventional `feat!:` subject and `bump-minor-pre-major: false`, and reject a 0.13.0 result. The helper simulates release artifacts and runs local gates; only the post-landing Release Please run can prove live automation behavior.

**Primary recommendation:** Keep prose and release notes human-owned, prove coverage through source-aligned ID-set equality, and extend the existing clone rehearsal to validate an exact committed 1.0.0 candidate without performing external release actions.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Upgrade instructions and adopter-facing change notes | Documentation / package distribution | Test contracts | These describe application API and support changes; human prose belongs in the Hex-distributed `CHANGELOG.md` and ExDoc guide. |
| Change coverage and guide registration | Test / build | Documentation | ExUnit checks stable IDs and file graph membership; ExDoc extras render the guide. |
| Version selection and generated release PR | Release automation / GitHub | Git history | Release Please analyzes conventional commits and `Release-As`; it creates a release PR/tag and does not publish to Hex. [CITED: https://github.com/googleapis/release-please] |
| Local candidate artifact rehearsal | CI / local tooling | Disposable filesystem clone | Existing named gate simulates bump artifacts in a throwaway clone and invokes release contracts. Extend its target selection and assertions while preserving the no-touch identity check. |
| Hex publication | Protected release workflow | Maintainer approval | The `production-hex` environment protects publication, a distinct one-way action requiring its own grant. |

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix / ExUnit | Project toolchain; current local probe was Elixir 1.17.3 on OTP 27; `.tool-versions` is the committed CI source | Guide contracts, named verification aliases, and clone rehearsal | Existing project conventions use ExUnit file contracts and `mix verify.*`; add no runtime dependency. |
| Release Please Action | Existing workflow pin `googleapis/release-please-action@v5` | Conventional-commit release PR generation and version targeting | Existing release workflow owns this control plane. Official docs describe `Release-As` commit body behavior and `feat!` as a major bump. [CITED: https://github.com/googleapis/release-please] |
| ExDoc | Existing locked development dependency | Expose the new guide as a published documentation extra | Official ExDoc docs define `docs: [extras: ...]` and keyword options for page title/output. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html] |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| Git, `jq`, Perl, `realpath`, Mix | Inputs needed by the existing rehearsal; the script explicitly checks the first five executables before cloning. | The committed candidate rehearsal. |
| `bin/ci-test-partitions` and `test/partition_weights.txt` | Run weighted CI suites and maintain exact test inventory. | Add a new ExUnit test file and measured/explicit weight in the same phase. |
| `mix verify.release`, `mix verify.bump_rehearsal`, `mix ci.all` | Named package, artifact, and all-gates entrypoints. | Release rehearsal remains separate from `ci.all`; use canonical aliases for the final local gate. |

No external package installation is required by this phase; omit Package Legitimacy Audit.

## Architecture Patterns

### System Architecture Diagram

```text
Human-owned CHANGELOG.md ── stable hidden IDs ─┐
                                               ├─ focused ExUnit set-equality contract
ExDoc guide ─────────────── matching hidden IDs┘            │
                                                            ├─ explicit partition weight
mix.exs docs extras + guide graph ──────────────────────────┘

Committed candidate HEAD
   ├─ conventional feat! subject + one Release-As: 1.0.0 footer
   ├─ config: bump-minor-pre-major = false
   └─ disposable clone: simulate version/artifact writes ──> bumped artifact contracts
                                                            └─ report as local artifact rehearsal

After separate maintainer grants: push ─> main Release Please run ─> Release PR/tag
                                         └─ CI min (PG15) + latest pins ─> protected Hex publish
```

The clone rehearsal must not claim that it executes the live Release Please action. Release Please reads conventional commit history and creates Release PRs; its documented `Release-As: x.y.z` footer selects a specific release version. It does not publish packages. [CITED: https://github.com/googleapis/release-please]

### Recommended Project Structure

```text
guides/upgrading-to-1.0.md                         # new adopter guide, ExDoc extra, guide graph node
test/threadline/upgrading_to_1_0_doc_contract_test.exs # exact hidden-ID set contract
test/partition_weights.txt                         # explicit weight for that test file
bin/verify-bump-rehearsal                           # candidate validation and 1.0.0 artifact rehearsal
release-please-config.json                          # set bump-minor-pre-major false
CHANGELOG.md                                        # human-owned 1.0.0 break/deprecation notes and IDs
```

These paths are quoted from repository sources: `"guides/upgrading-to-0.11.md"` appears in `test/threadline/upgrading_to_0_11_doc_contract_test.exs:101-104`; the rehearsal currently declares `CONFIG="release-please-config.json"` and `MANIFEST=".release-please-manifest.json"` in `bin/verify-bump-rehearsal:136-140`; the existing test inventory path appears as `test/partition_weights.txt` in Phase 236 verification, `.planning/phases/236-support-floor-and-partition-weights/236-VERIFICATION.md:66`. **[VERIFIED: cited source files opened this session]**

### Pattern 1: Hidden IDs and exact scoped-set equality

**What:** Put one stable machine-readable ID in an invisible HTML comment adjacent to each covered human-owned breaking/deprecation entry and its corresponding numbered guide step. Parse the two source sections, reject duplicate IDs, then compare exact sets with diagnostics for missing and extra IDs. Scope separately to the 0.12.0-only preflight and 1.0 guide steps. Keep descriptions hand-written.

**When to use:** This phase's changelog and guide are independently authored documents and one guide category can cover multiple specific entries; a single broad prose assertion could let an individual change become unmapped.

**Evidence:** The locked decision states, verbatim, “The focused ExUnit contract compares the scoped ID sets for 0.12.0 prerequisites and 1.0 changes, and fails on a missing, extra, duplicate, or unmatched ID.” [VERIFIED: `.planning/phases/237-upgrade-guide-and-1-0-0/237-CONTEXT.md`, §D-03]

### Pattern 2: Candidate-bound disposable clone

**What:** At the candidate HEAD, verify the intended squash subject and exactly one target footer. Read the configured boolean and require `false`. Use the footer value as the only simulated version target, then update manifest, package version, marked release files, release pins, generated changelog stand-in, and any release artifact inputs already owned by the existing helper. Run its existing bumped-artifact contract gates only inside the clone and compare the real tree identity before/after.

**When to use:** Run after creating and committing the local candidate squash, before push or merge. This keeps the evidence tied to the precise candidate and validates version-sensitive docs/artifacts. Do not report it as a live Release Please run.

**Existing example:** `bin/verify-bump-rehearsal` checks `for tool in git mix jq perl realpath; do` and currently sets `NEXT="${BASH_REMATCH[1]}.$((BASH_REMATCH[2] + 1)).0"` after parsing the current version (`bin/verify-bump-rehearsal:127-132,172-181`). It then clones the source SHA, simulates version/manifest/extra-file/changelog writes, commits inside the clone, runs doc contracts and `mix verify.release`, and checks the real tree identity (`bin/verify-bump-rehearsal:223-231,245-255,376-380,410-460`). **[VERIFIED: `bin/verify-bump-rehearsal` opened this session]**

### Pattern 3: Register adopter guides through both indexes

**What:** Add the page to `mix.exs` ExDoc extras and the exact adopt lane in `test/threadline/guide_graph_contract_test.exs`; keep Markdown links valid and maintain the established answer-first, task-oriented prose.

**Why:** The existing graph contract compares all local guide files against configured extras and lanes. ExDoc officially supports Markdown extras via project docs configuration. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html]

### Changelog coverage map for this candidate

The current Unreleased block has 12 breaking entries and eight deprecation entries. These are the exact semantic targets for stable IDs; grouping below is a recommended mapping aid, not a claim that every heading represents only one change. The fragments are quoted verbatim from `CHANGELOG.md`, satisfying source-value provenance.

| # | 1.0 breaking entry (guide category) | Required adopter action / note |
|---|---|---|
| 1 | PostgreSQL floor: “PostgreSQL 15 is the supported minimum.” (`CHANGELOG.md:35-36`) | PostgreSQL 14 users upgrade the database first. |
| 2 | Job context validation: “now rejects unsupported `extra` keys and malformed context IDs with `ArgumentError`” (`:38-41`) | Remove unsupported keys and use valid IDs. |
| 3 | Hidden implementation API: “no longer part of the documented API” (`:43-52`) | Stop depending on listed internal helpers; callable status is not an API promise. |
| 4 | Option validation: “now raise `ArgumentError` for unknown filter or option keys” (`:54-63`) | Remove unknown keys including `:surface` and `:params`. |
| 5 | Lookup return shape: “returns `{:ok, %Threadline.Investigation.LinkedTransaction{}}` or `{:error, :not_found}` instead of a bare struct” (`:65-88`) | Match the tuple or use the bang sibling if absence is exceptional. |
| 6 | Lookup option and ID behavior: “accept only `:repo`, `:storage_schema`, `:scope` and `:scope_query_fn`” (`:90-102`) | Drop unsupported lookup options and add the `:transaction_header` scope-query clause; retain the detailed behavior. |
| 7 | Association change: “An un-hydrated `AuditTransaction.action` is now `nil`” and bare preload “now raises” (`:104-112`) | Read linked actions through supported exploration lookups or query by `action_id`; DB column/FK remain. |
| 8 | Shared `Page` struct for general pagers: “`Threadline.Query.TimelinePage` is removed” (`:114-120`) | Match `%Threadline.Page{}` and use `cursor` / exact `has_more`. |
| 9 | Shared `Page` struct for actor history: “`Threadline.Query.ActorHistoryPage` is removed” (`:122-127`) | Fold into the Page step while still assigning a distinct change ID. |
| 10 | Bounded row history: “return at most 200 changes by default” (`:129-138`) | Use `limit: :infinity` for complete list, or cursor paging. |
| 11 | Internal helpers hidden: “no longer appear in the generated docs” (`:140-144`) | No action for users of documented APIs; keep separate from deprecated supported delegates. |
| 12 | Fail-closed scoping: “now raises `ArgumentError` on every scoped read” without a valid three-arity scope function (`:146-160`) | Pair non-nil scope with valid callback and a deny-all catch-all. |
| D1 | “`Threadline.Query.audit_transaction/2` is deprecated” (`:164-170`) | Move to `Threadline.audit_transaction/2`; old function remains through 1.x. |
| D2 | `:action` preload on `audit_changes_for_transaction/2` “now emits one deprecation warning per call” (`:172-175`) | Remove action preload usage / adopt documented read path. |
| D3 | “`Threadline.row_history/4`” (`:177-180`) | Use `row_history/3`; legacy shape remains functional in 1.x. |
| D4 | “`Threadline.history/3`” (`:182-187`) | Use `row_history/3`, map `.audit_change` if needed, pass `limit: :infinity` for old completeness. |
| D5 | “`Threadline.row_history_page/2,3,4`” (`:189-193`) | Use cursor options on `row_history/3`. |
| D6 | “`Threadline.actor_window_page/1,2,3`” (`:195-198`) | Use cursor options on `actor_window/3`. |
| D7 | “`Threadline.correlation_bundle_page/1,2,3`” (`:200-203`) | Use cursor options on `correlation_bundle/3`. |
| D8 | “`Threadline.actor_history/2`'s `:after`, `:before` and `:limit` options” (`:205-208`) | Replace with `cursor:` and `page_size:`. |

The three 0.12.0 preflight changes are separately listed in the existing changelog: (1) non-list `exclude:`/`mask:`/`except_columns:` now raises and non-string `mask_placeholder:` now raises (`CHANGELOG.md:234-240`); (2) operator authorization/mismatch telemetry no longer carries `actor_ref`, `session_actor_ref`, or `scope_actor_ref` (`:241-248`); (3) health error metadata is `%{exception: module}` instead of `%{error: message}` (`:249-253`). The 0.11-only preflight should state the necessary handler/config edit and link to `guides/upgrade-path.md` and the 0.12.0 changelog entry. The migration from 0.10 to 0.11 is a separate prior-upgrade prerequisite: the existing guide includes the exact heading `## Step 2: Regenerate triggers` and its trigger-generation procedure (`guides/upgrading-to-0.11.md:32-64`). The new 1.0 guide must explicitly say trigger regeneration is not required for its changes; preserve the old procedure only for adopters who never completed the 0.11 migration. **[VERIFIED: `CHANGELOG.md` and `guides/upgrading-to-0.11.md` opened this session]**

### Release-please behavior confirmed against official sources

- Release Please says `Release-As: x.x.x` in a main-branch commit body opens a release PR for the requested version; both squash and merge commits work with Release PRs, and it recommends squash merges for conventional history. It also maps `feat!:` to a SemVer major. [CITED: https://github.com/googleapis/release-please]
- Its published config schema describes `bump-minor-pre-major` as “Breaking changes only bump semver minor if version < 1.0.0”; its default versioning strategy treats this as false unless true. Set it explicitly to false for the 1.0 landing. [CITED: https://github.com/googleapis/release-please/blob/main/schemas/config.json] [CITED: https://github.com/googleapis/release-please/blob/main/src/versioning-strategies/default.ts]
- Release Please automates release PRs, changelog generation, and GitHub tags/releases but explicitly “does not handle publication to package managers.” The protected workflow's Hex publish is a separate phase boundary, not an implication of a green candidate rehearsal. [CITED: https://github.com/googleapis/release-please]
- ExDoc's Mix docs configuration supports Markdown `:extras`; per-extra keyword settings can choose generated filename and title. Use current project guide graph practices as well as ExDoc's feature. [CITED: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html]

### Anti-Patterns to Avoid

- **Treating generated release notes as the adopter changelog:** `release-please-config.json` points `changelog-path` to `CHANGELOG-GENERATED.md`; all adopter actions belong in human-owned `CHANGELOG.md`.
- **Trusting a next-minor rehearsal:** the current helper derives `0.13.0` from `0.12.0`; that cannot establish the exact target or candidate metadata for 1.0.0.
- **Calling the local simulation “live Release Please”:** artifact simulation verifies rewritten files and local gates; live release-please action evidence occurs after a granted landing push.
- **Hand-maintaining a parallel change manifest:** IDs in source comments and exact set equality directly connect the two human documents; a third file can drift.
- **Claiming all upgrades require trigger regeneration:** 1.0 changes do not require it; only an adopter who skipped the earlier 0.11 trigger upgrade needs that prerequisite.
- **One release approval for all irreversible actions:** push, merge, and protected Hex publication have separate grants.
- **Moving capture concerns into the upgrade prose incorrectly:** preserve the capture/semantics boundary. `AuditTransaction` groups row changes within one DB transaction, while `AuditAction` is a semantic application event; the association change is an exploration hydration concern and does not replace the trigger-backed, host-owned Ecto migration model.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Version selection from conventional commits | A second semver/release calculator | Release Please semantics for the actual live PR; narrowly scoped rehearsal assertion for the locked footer/config/target | Official tool already defines commit and pre-major behavior. |
| Current release install pins | A second hand-maintained pin rewrite | `mix release.pins` and its `--check` mode in the existing rehearsal | That task owns version-derived install pins. |
| Published guide navigation | A custom guide renderer/index | ExDoc extras plus the current guide-graph contract | Both mechanisms already render and test project guides. |
| Broad change coverage | Runtime-generated prose or standalone manifest | Human-written changelog and guide with stable hidden IDs and exact set comparison | Keeps adopter language curated while enforcing exhaustive mapping. |
| Release permission control | Rehearsal-driven implicit publish or a local Hex shortcut | Separate protected release workflow and grants | A local pass cannot prove repository approvals or external publication. |

**Key insight:** Release automation, human release notes, and Hex distribution have separate owners. Keep those boundaries explicit so complete test evidence cannot be mistaken for authorization or for live release evidence.

## Common Pitfalls

### Pitfall 1: A step heading covers a category but omits a concrete change

**What goes wrong:** Seven headings exist but one of the multiple lookup, Page, scope, hidden API, or deprecation changes has no explicit action.

**Why it happens:** Broad categories can create false confidence in prose review.

**How to avoid:** Assign one distinct stable ID per changelog item even where several IDs share a step. Compare exact scoped unique ID sets and report duplicates, missing IDs, and extra IDs.

**Warning signs:** A count-only assertion, IDs parsed from only one document, duplicate IDs silently collapsing into a set, or a test that conflates pre-1.0 changes with the 0.12-only preflight.

### Pitfall 2: Candidate is tested without validating its release controls

**What goes wrong:** The clone tests 1.0.0 artifacts but source HEAD has no intended conventional subject/footer or config still applies pre-major behavior.

**How to avoid:** Validate candidate HEAD itself before clone mutation; require exact footer count/version, conventional breaking subject, and explicit config false. Use the validated footer as the target and assert a failure if 0.13.0 appears.

### Pitfall 3: Mixing manual and generated release note ownership

**What goes wrong:** Release Please overwrites hand-authored adopter details, or the generated notes become the only 1.0 changelog record.

**How to avoid:** Keep `changelog-path` aimed at generated notes. Reconcile 1.0 notes in human-owned changelog against `git log --grep="BREAKING CHANGE"` across the milestone range and record the check in VERIFICATION.md.

### Pitfall 4: Rehearsal or CI is mistaken for landing authorization

**What goes wrong:** The one-way public package action runs because local validation or green CI is treated as a grant.

**How to avoid:** Keep candidate rehearsal entirely disposable and separate push, merge, and `production-hex` publication. Capture independent maintainer grants at each boundary. Verify min lane PG15 and re-check latest lane pins at landing.

### Pitfall 5: New test is missing from weighted CI

**What goes wrong:** Partition-inventory contract fails, or the new contract is never run by partitioned CI.

**How to avoid:** Add its path and measured/explicit time in `test/partition_weights.txt`; Phase 236 confirmed the old inventory contained 265 discovered tests. Run the weight completeness check after adding it.

## Code Examples

No new application code or external package is needed. For the release-specific implementation, follow existing test conventions rather than pasting a prescriptive parser here: `Threadline.UpgradingTo011DocContractTest` reads guide files, asserts ordered headings and source facts, and emits targeted failure messages; `Threadline.ChangelogContractTest` parses the human/generated changelog ownership boundary. The new contract should adapt those patterns to hidden ID extraction and exact set equality.

Official Release Please behavior examples:

```text
feat!: one release-wide breaking change

Release-As: 1.0.0
```

This shape is grounded in the official documented footer key and conventional `feat!` mapping; the locked requirement calls for exactly one footer at candidate squash HEAD. [CITED: https://github.com/googleapis/release-please]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Derive the next minor from `@version` for rehearsal | Validate a committed candidate's explicit Release-As target, then simulate only that exact artifact version | Phase 237 | Establishes 1.0.0 intent and guards against accidental 0.13.0. |
| Reader manually infers guide completeness by scanning release bullets | Stable hidden IDs tied to both human-owned documents with exact scoped set equality | Phase 237 | Exhaustive and actionable coverage while hidden from the published prose. |
| Treat release-bot activity and package publication as one operation | Release Please PR/tag automation followed by separate protected publish chain | Existing workflow and official Release Please contract | Prevents local rehearsal and CI evidence from being confused with a live action or approval. |

**Deprecated/outdated:**

- Current “next minor” framing in `bin/verify-bump-rehearsal` and its `mix.exs` alias comments will become inaccurate for this candidate. Update descriptions/contracts with the behavior; do not remove the named release-only gate from CI or `mix ci.all` scope without an explicit reason.
- Do not use `CHANGELOG-GENERATED.md` as a source of human upgrade actions.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The focused ID contract can operate directly on invisible HTML comments without conflict with current release artifact scans. | Architecture patterns | Planning comment syntax that leaks or is sanitized unexpectedly could weaken coverage or leak maintenance metadata; keep exact syntax covered by a source contract. |
| A2 | The committed candidate squash can be prepared in an isolated clone/worktree without touching unrelated user changes. | Release rehearsal | A flawed staging procedure could include unrelated dirty files or produce a different HEAD than rehearsal input. |
| A3 | The verification entry should be written by the phase verifier after running the real milestone-range changelog scan. | Requirements support | Claiming cross-check completion without scanning the chosen range would leave REL-02 unsupported. |

## Open Questions

1. **What exact commit/range anchors the REL-02 milestone scan?**
   - What we know: roadmap says milestone range; current worktree has unrelated dirty files and multiple phase commits.
   - What's unclear: the verified branch base and committed candidate range are determined when the landing squash is prepared.
   - Recommendation: make the candidate/merge base explicit in the verification evidence and keep the scan restricted to intended milestone commits.

## Project Constraints (from AGENTS.md)

- Preserve three distinct layers: capture owns trigger-backed canonical row mutations; semantics binds actor, intent, correlation, request/job provenance and reason; exploration/operations owns timelines, diffs, queries, exports, health, retention, redaction, coverage and telemetry.
- Use the domain terms `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation` consistently. Transactions are not requests and actions are not changes.
- Preserve generated PostgreSQL triggers installed through host-owned Ecto migrations. Do not move trigger lifecycle into package-managed migrations.
- Preserve idiomatic Plug/Phoenix/Ecto/Oban integration, SQL-native queryability, and the explicit non-goals: not a SIEM, event-sourcing system, pgAudit replacement, or data warehouse.
- Prefer named `mix verify.*` / `mix ci.*` entrypoints; keep default tests honest; keep stable GitHub Actions job IDs; run expensive jobs on main despite PR path filters; keep README/guides/example README aligned through doc contracts.
- Default to automated UAT and verification. Maintainer involvement belongs at secrets, spend, push/publish, and scope boundaries. No push, merge, publication, or production Hex action is part of research or local planning.
- Research then recommend; respect locked CONTEXT.md choices and do not turn the plan into an option menu.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | ExUnit contract and `mix verify.bump_rehearsal` | ✓ | Elixir 1.17.3 / Mix 1.17.3 on OTP 27 in this research shell | CI uses committed `.tool-versions` and matrix lanes. |
| Git | Candidate HEAD checks and disposable clone | ✓ | 2.41.0 | — |
| `jq` | Manifest/config simulation in current rehearsal | ✓ | 1.7.1 | — |
| Perl | Marked line and release-file rewrites | ✓ | 5.34.1 | — |
| `realpath` | Safe clone path resolution | ✓ | `/bin/realpath` (version flag not reported) | — |
| PostgreSQL | Root test / release gates | ✓ | `pg_isready`: localhost 5432 accepts connections | CI min uses PostgreSQL 15; current local service version not probed. |
| GitHub Actions / Release Please | Live release PR and required CI evidence | ✗ local service | Workflow is present in source; live state must be observed after a granted push | Local artifact rehearsal is useful for planning but does not substitute for live evidence. |
| Hex production credentials / reviewer grant | Production publish | ✗ intentionally not probed | — | Separate explicit maintainer grant and protected workflow. |

**Missing dependencies with no fallback:** None for local plan tasks observed. Live Release Please, CI status, and publication are external landing steps, not local blockers.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit, shipped with Elixir; current lock/toolchain is Elixir 1.17.3 in this shell |
| Config file | `mix.exs` aliases and project `config/test.exs` |
| Quick run command | `mix test test/threadline/upgrading_to_1_0_doc_contract_test.exs test/threadline/changelog_contract_test.exs` |
| Full suite command | `mix ci.all` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCS-03 | Guide has conditional 0.11 preflight, seven numbered steps, explicit trigger-regeneration fact, and exact ID coverage with changelog | ExUnit doc contract + ExDoc build + guide graph test | `mix test test/threadline/upgrading_to_1_0_doc_contract_test.exs test/threadline/guide_graph_contract_test.exs` then `MIX_ENV=dev mix docs --warnings-as-errors` | ❌ New contract; graph test exists |
| REL-01 | Candidate subject/footer/config are exact and clone simulation targets 1.0.0 only, rejects 0.13.0, artifact gates pass | Rehearsal script contract + executable release rehearsal | `mix test test/threadline/ci_topology_contract_test.exs` and `mix verify.bump_rehearsal` on committed candidate HEAD | ❌ Extend existing rehearsal |
| REL-02 | 1.0 changelog covers all release footers and deprecations | Source audit recorded in phase VERIFICATION.md; changelog/doc contract protects stable ID coverage | `git log --grep="BREAKING CHANGE"` for explicit milestone range; focused changelog/guide ExUnit contract | ❌ Cross-check evidence new; focused IDs test new |
| REL-03 | Landing evidence has one `feat!:` squash, green CI required/min PG15/latest pins, later live 1.0.0 release evidence | CI/release workflow evidence + protected environment audit | `mix ci.all` locally; GitHub `CI required` and Release workflow inspected after separately granted landing; verify live `hex.pm` package version | ❌ External landing evidence |

### Sampling Rate

- **Per task commit:** focused changed contract and `mix verify.format`.
- **Per wave merge:** `mix ci.all` after contract/test/weight updates.
- **Phase gate:** `mix verify.bump_rehearsal` on committed candidate HEAD, then full `mix ci.all`; verify required CI evidence and landing pin values separately after granted external action.

### Wave 0 Gaps

- [ ] `test/threadline/upgrading_to_1_0_doc_contract_test.exs` — validates separate prerequisite and 1.0 scoped ID sets.
- [ ] `test/partition_weights.txt` — give the new contract an explicit measured/valid weight.
- [ ] Rehearsal implementation changes and contract coverage — candidate subject/footer/config guards, exact-target simulation, exact version assertions and honest summary label.

## Security Domain

This phase changes docs and release controls; it adds no authentication/session or application authorization feature. The relevant security concern is avoiding unintended package publication and preserving separation of capture and semantics.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No application authentication is changed. |
| V3 Session Management | no | No browser or session surface is changed. |
| V4 Access Control | yes, release infrastructure only | Keep push, merge, and protected `production-hex` publication behind separate explicit maintainer grants; verify `CI required` first. |
| V5 Input Validation | no runtime input introduced | The candidate parser should fail closed on malformed/missing/duplicate footer and invalid config values. |
| V6 Cryptography | no | No cryptographic code or key handling changes are planned. |

### Known Threat Patterns for docs/release changes

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Candidate footer parser accepts multiple or malformed target lines | Tampering | Require exact count and exact `1.0.0`, fail closed, test negatives. |
| Local rehearsal produces release-looking but inaccurate report | Repudiation / Tampering | Label artifact rehearsal truthfully; record candidate SHA and artifact checks. |
| Green CI is treated as authority to publish | Elevation of privilege | Separate grants and protected environment reviewer; do not let local scripts publish. |
| Change moves semantics onto trigger capture or claims schema association is restored | Tampering / Information flow | Keep domain boundaries; existing source contracts and explicit architecture review. |

## Sources

### Primary (HIGH confidence)

- Phase inputs read directly this session: `.planning/phases/237-upgrade-guide-and-1-0-0/237-CONTEXT.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`, `AGENTS.md`.
- Repository implementation and convention files read directly this session: `CHANGELOG.md`, `CHANGELOG-GENERATED.md`, `guides/upgrading-to-0.11.md`, `guides/upgrade-path.md`, `guides/stability.md`, `test/threadline/changelog_contract_test.exs`, `test/threadline/upgrading_to_0_11_doc_contract_test.exs`, `test/threadline/guide_graph_contract_test.exs`, `test/threadline/release_distribution_doc_contract_test.exs`, `test/partition_weights.txt`, `bin/verify-bump-rehearsal`, `mix.exs`, `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release.yml`, `.github/workflows/ci.yml`, `CONTRIBUTING.md`, `.planning/phases/236-support-floor-and-partition-weights/236-VERIFICATION.md`.

### Official documentation (CITED)

- [Release Please README](https://github.com/googleapis/release-please) — Conventional Commits, `feat!`, squash recommendation, `Release-As` body footer, and no package-manager publishing.
- [Release Please config schema](https://github.com/googleapis/release-please/blob/main/schemas/config.json) — `bump-minor-pre-major` meaning.
- [Release Please default versioning strategy](https://github.com/googleapis/release-please/blob/main/src/versioning-strategies/default.ts) — default and pre-1.0 breaking behavior.
- [ExDoc `mix docs` configuration](https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html) — Markdown extras and per-page options.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — current repo files and tool versions inspected; no new package required.
- Architecture: HIGH — decision and repository conventions directly inspected; release behavior confirmed by official Release Please documentation.
- Pitfalls: HIGH — existing rehearsal's current next-minor design and new requirement mismatch are directly established from source.

**Research date:** 2026-10-07
**Valid until:** 2026-11-06 for stable internal conventions; revisit Release Please docs if its action major changes.
