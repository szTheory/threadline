# Phase 213: Upgrade Guide and 0.11.0 Release - Context

**Gathered:** 2026-09-26
**Status:** Ready for planning

<domain>
## Phase Boundary

The goal is that an adopter on 0.10.x can upgrade to 0.11.0 by following one guide, and that 0.11.0 is published from a clean, green `main`.

Deliverables:
- the upgrade guide, with backfill SQL and every fact the adopter needs;
- the CHANGELOG security note;
- real-PG upgrade and rollback proof against a seeded 0.10.x fixture;
- every local pre-land and pre-release check, run and recorded;
- a clean landing branch prepared for the maintainer, with an exact hand-off command list.

Requirements: REL-02 and REL-03.

**Hard boundary:** these are the maintainer's, on their explicit go, and are never done by an agent:
- push;
- PR creation;
- merge (`gh pr merge` is blocked anyway);
- approving the `production-hex` environment;
- hex publish;
- deleting remote branches.

REL-03's post-merge truths are therefore recorded as **maintainer action, pending** with exact commands, and are never marked verified until the maintainer reports SHAs and run IDs:
- release-please proposes exactly 0.11.0;
- `main` CI is green on the released SHA;
- no open PRs or stray branches remain.

Out of scope:
- a `mix threadline.gen.backfill` task (deferred);
- widening the PK type allowlist;
- operator-UI work.

</domain>

<decisions>
## Implementation Decisions

### Carried forward (locked)
- Phases 210–212 decisions stand. The facts the guide must restate are listed in D-04.
- **Pre-1.0 versioning:** `bump-minor-pre-major: true` is contract-enforced (`test/threadline/changelog_contract_test.exs`). A breaking change proposes a minor bump (0.11.0), never 1.0.0.
- **CHANGELOG split:** `CHANGELOG.md` is human-owned. `CHANGELOG-GENERATED.md` is release-please's only write target.
- **Release runbook (memory, [[release-runbook]]):** run `ci.all` **and** a simulated bump before believing a release is green. A rehearsal step with no mirror in the real release flow is a lie.

### Guide shape
- **D-01:** The full 0.10.x → 0.11.0 procedure lives in a new `guides/upgrading-to-0.11.md`.
  - `guides/upgrade-path.md` gains the required human-authored 0.10.x → 0.11.x per-minor entry, which the version-truth Family C contract needs. It summarises the change and links to the new guide.
  - The new guide is registered wherever guides are listed: mix.exs docs extras, guide graph contract and README if applicable.
  - **Reversibility:** reversible.
- **D-02:** Step order, which is dependency-forced:
  1. Bump deps to `~> 0.11`.
  2. Regenerate triggers with `mix threadline.gen.triggers` for every audited table. Tables that shared a capture function are regenerated **together in one `--tables a,b` run**.
  3. Run `mix ecto.migrate`.
  4. Run `mix threadline.gen.row_history_index`, which builds the index concurrently, then migrate. Include the INVALID-index recovery.
  5. Run `mix threadline.verify_coverage` and `mix threadline.health.coverage` and confirm there are no error findings. Show how to read each finding code's fix.
  6. Optionally, backfill.
- **D-03:** Backfill: it is plain SQL in the guide, SQL-native, with no new Mix task.
  - **Scope:** it backfills `table_pk` only for INSERT and UPDATE rows whose `table_pk` is `{"id": null}` (or `{}`), from `data_after`.
  - **Encoding:** it must use the trigger's **text** encoding, `jsonb_build_object('<col>', data_after ->> '<col>', ...)` in key order. Never use `->`.
  - It must be idempotent: guarded on the unresolved `table_pk` values, so a rerun changes nothing. It must be batchable, with a documented batch pattern that keeps lock and transaction size bounded.
  - It must never touch rows where any key column is absent from `data_after` or is null. Those stay unresolved.
  - **Unrecoverable rows**, stated explicitly with the reason:
    - DELETE rows, because 0.10.x stored no row image for DELETE (`data_after` is NULL);
    - rows whose key columns were masked or excluded by redaction, because the value was never stored.
  - The SQL block is wrapped in stable HTML-comment markers (e.g. `<!-- threadline:backfill-sql:start -->` … `end`), so the SC2 test extracts and executes exactly the published text.
  - The block exposes its parameters (table, schema, key columns) in a clearly marked form that the test substitutes.
  - **Reversibility:** reversible. It is guide text; adopters run it themselves.
- **D-04:** Facts the guide must state, collected from 210–212 and the CHANGELOG:
  - PK types outside the allowlist (e.g. `timestamptz`, `numeric`, float, json, array, bytea) refuse to regenerate, naming the column. Such tables keep their legacy trigger, which captures as before.
  - `{"id": null}` (legacy) and `{}` (0.11 unresolved) both mean "unresolved". Match both.
  - `history/3` and `as_of/4` now raise `ArgumentError` on a wrong, nil or uncastable key. Composite keys take a keyword list or map.
  - `trigger_coverage/1` no longer counts disabled (`'D'`) or replica-only (`'R'`) triggers as covered, so a CI gate can turn red. Give the fixes.
  - The `primary_key:` override goes in `config/config.exs` under `config :threadline, :trigger_capture, tables: %{...}`, and needs a qualifying unique index.
  - A key column in `mask`/`exclude` is refused.
  - A fresh install already has the row-history index.
  - Point to the CHANGELOG security note.
- **D-05:** Security note: a CHANGELOG entry covers installs where two tables shared one per-table capture function. This is the phase 209 issue: cleanup or regeneration for one table could affect the other's capture or trigger.
  - It gives the detection command (`mix threadline.health.coverage`, code `shared_capture_function`) and the fix: regenerate all affected tables together.
  - The planner confirms the exact impact wording against `.planning/phases/209-*/209-CONTEXT.md` and the 209 SUMMARYs. It must be accurate, neither overstated nor understated.
  - It is placed in the human CHANGELOG's Unreleased section, under a Security heading, following the repo's CHANGELOG conventions.
  - **Reversibility:** costly once published. It is public release notes.
- **D-06:** Doc contracts:
  - Extend the existing `*_doc_contract_test.exs` pattern.
  - A new contract for `upgrading-to-0.11.md` pins these literal commands: `mix threadline.gen.triggers --tables`, the together-regeneration rule, `mix threadline.gen.row_history_index`, `mix threadline.verify_coverage`, and the backfill markers.
  - `upgrade_path_doc_contract_test.exs` pins the new per-minor entry and link.
  - The CHANGELOG contract pins the security note heading.

### Upgrade and rollback proof (SC2)
- **D-07:** Build the fixture from the frozen `Threadline.Test.LegacyTriggerSQL` 0.10.2 SQL plus `Threadline.Test.MigrationHarness` (the established real-PG pattern). Extend `LegacyTriggerSQL` where a shape needs it.
  - No `git show` at test time.
  - The hex evaluator is not the primary proof.
- **D-08:** One root-suite real-PG test module seeds a 0.10.x install with these shapes:
  - an `id`-keyed table;
  - a non-`id`-keyed table with INSERT, UPDATE and DELETE rows captured as `{"id":null}`;
  - a composite-key table;
  - two tables sharing one per-table capture function, reproducing the 0.10.x shape;
  - a `timestamptz`-PK table, which must keep its legacy trigger after upgrade.

  It then runs the documented steps: regenerate through the real generator, migrate, row-history index, health with no error findings except the documented `timestamptz` case, and the backfill SQL **extracted from the guide markers**. It asserts:
  - the backfilled INSERT and UPDATE rows now equal what a regenerated trigger writes, and `history/3` finds them;
  - DELETE rows are untouched;
  - a rerun of the backfill is a no-op.
- **D-09:** Rollback: the same module, or a sibling, first creates a **foreign host trigger** that is not Threadline's, on an audited table and on an unaudited one. It then runs the full upgrade set up, then `Ecto.Migrator` down to zero (`all: true`), and asserts against the live catalog:
  - no `threadline_capture_changes%` function remains that no trigger references (no orphans);
  - every foreign trigger survives.

  Existing tests prove only the generated SQL text, so this catalog proof is the new part.
- **D-10:** The tests live in the root suite and run under `mix test`, `mix verify.test` and `mix ci.all`. No new entrypoint. Tests clean up their tables, functions, triggers and roles.

### Release (REL-03, SC3)
- **D-11:** Local pre-land proof, all run and recorded with exit codes in verification:
  - `mix ci.all`
  - `mix verify.release`
  - `mix verify.bump_rehearsal`, which is release-lane only and **not** part of `ci.all`
  - `mix release.pins --check`, or its equivalent
  - `MIX_ENV=dev mix docs --warnings-as-errors`
  - `mix hex.build`
  - the CHANGELOG, version-truth and upgrade-path contracts
  - `mix verify.topology` and `mix verify.hex_evaluator`, because a release SHA must be green in CI jobs that `ci.all` omits
  - the unscoped browser lane, with the 8 known failures only
- **D-12:** CHANGELOG heading: follow repo precedent, where each human `## [x.y.z] - date` heading was written before release. Retitle `## Unreleased — highlights` to `## [0.11.0] - <landing date>` on the landing branch.
  - If the contract tests require Unreleased to remain until release-please runs, follow the tests instead. The planner verifies which with `changelog_contract_test.exs` and the 0.10.2 history (`git log -p origin/main -- CHANGELOG.md`).
  - The date is set at landing time.
- **D-13:** Landing branch: build it with the `gsd-pr-branch` flow, the precedent for 0.10.0 (#43).
  - Base it on `origin/main`, carry the milestone's code, test and doc changes, and filter out `.planning/`-only commits, so the squash body carries no phase IDs.
  - The agent builds it **locally only** and verifies it: `ci.all` passes on it, and a diff check shows no `.planning/` paths and no phase-ID vocabulary in the commit subjects.
  - The maintainer chooses the branch name at push time. Suggest `land/v1.42`, but warn that a stale local `land/v1.41` exists.
  - **Reversibility:** reversible until pushed.
- **D-14:** Squash title: `feat!: <summary>`. It is honest about the breaking changes, and `bump-minor-pre-major` makes it 0.11.0, not 1.0.0. The planner verifies this against the contract test.
  - Suggested summary: `feat!: capture every primary-key shape, read it back exactly, and detect broken capture`.
  - Final wording is Claude's discretion: conventional, and free of phase and requirement IDs.
- **D-15:** Maintainer hand-off: an exact, ordered command list in the phase SUMMARY and VERIFICATION:
  1. push the branch;
  2. `gh pr create` with title and body;
  3. `gh pr checks`;
  4. squash merge;
  5. inspect the release-please PR, expecting exactly 0.11.0 and phase-ID-free notes;
  6. merge it with `--match-head-commit`;
  7. approve `production-hex` via the `gh api .../pending_deployments` command from the runbook;
  8. confirm publish and smoke;
  9. merge the distribution-sync PR once it is green.

  Plus the stray-branch deletion commands, listed as maintainer actions:
  - local `land/v1.41`;
  - `origin/fix/branch-protection-after-ci`;
  - `origin/phase-200/hosted-checkpoint`;
  - `origin/release-please--branches--main`, but only after 0.11.0 ships, since release-please reuses it;
  - `origin/release/sync-0.10.0-*` and `origin/release/sync-0.10.2-*`.

  The planner re-derives this list at execution time, because branches change.
- **D-16:** The phase is marked complete once every local truth is proven and the hand-off is recorded. REL-03 stays **Pending**, with a "maintainer action" note, until the maintainer reports back.

### Claude's Discretion
- Guide prose and structure within D-02 to D-04, the backfill batch pattern, and the test module split.
- The exact squash title and PR body wording, with no phase or requirement IDs.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` §Phase 213 (SC1–SC3), `.planning/REQUIREMENTS.md` REL-02, REL-03
- `.planning/phases/209-*/209-CONTEXT.md` and SUMMARYs (the shared-function issue, for the security note), `.planning/phases/210-pk-agnostic-capture/210-CONTEXT.md` (D-01, D-04, D-05, D-11, D-14–D-18), `.planning/phases/211-read-side-agreement/211-CONTEXT.md`, `.planning/phases/212-detection-and-adopter-twins/212-CONTEXT.md`
- `CHANGELOG.md` (Unreleased section), `CHANGELOG-GENERATED.md`, `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release.yml`, `CONTRIBUTING.md`
- `guides/upgrade-path.md`, `test/threadline/upgrade_path_doc_contract_test.exs`, `test/threadline/changelog_contract_test.exs`, `test/threadline/version_truth_doc_contract_test.exs`
- `lib/threadline/capture/audit_change.ex` (no `data_before`), `lib/threadline/capture/trigger_sql.ex`, `test/support/legacy_trigger_sql.ex`, `test/support/migration_harness.ex`
- `.planning/phases/202-*/202-05-SUMMARY.md` (bump rehearsal), memory [[release-runbook]], `bin/verify-bump-rehearsal`
- The `gsd-pr-branch` skill (landing branch build)

</canonical_refs>

<code_context>
## Existing Code Insights

- `Threadline.Test.MigrationHarness` compiles generated migrations and runs real `Ecto.Migrator.up/down`. It is used by 11 test files.
- `Threadline.Test.LegacyTriggerSQL` holds the frozen 0.9.0, 0.10.0 and 0.10.2 trigger and install SQL.
- No test in the repo yet extracts and executes a fenced block from a guide. This phase adds the first, anchored on HTML-comment markers.
- Only string-level tests exist for the drop-function SQL. No live-catalog rollback proof exists; D-09 adds it.
- `hex-publish.yml` no longer exists, so there is no race with `release.yml`.
- The hex evaluator pins exactly to the rehearsal registry or published version, so it has no stale-pin problem.
- Two `x-release-please-version` markers exist (`guides/evaluating-threadline.md:11`, `guides/adoption-pilot-backlog.md:7`). release-please manages them.
- `gh pr list --state open` is empty as of 2026-09-26.

</code_context>

<specifics>
## Specific Ideas

- `origin/main` is 199 commits behind `milestone/v1.42`, and every release so far built on top of 0.10.2. Before building the landing branch, check `git rev-list --count HEAD..origin/main`: it must be 0, or merge origin first. Lesson from phase 205.
- Show adopters the backfill's effect on `history/3` with a before/after example.

</specifics>

<deferred>
## Deferred Ideas

- A `mix threadline.gen.backfill` task that emits a batched, encoding-safe backfill migration. Add it if adopters struggle with the SQL.
- A health finding that counts unresolved `table_pk` rows per table.
- A `--strict` health mode, an `:invalid_config` finding and `--all-schemas`, all carried from 212.

</deferred>

---

*Phase: 213-upgrade-guide-and-0-11-0-release*
*Context gathered: 2026-09-26 (advisor mode, minimal_decisive; three parallel gsd-advisor-researcher reports synthesized; recommendations auto-accepted per maintainer instruction "auto follow your recommendations". Orchestrator syntheses: new satellite guide + required upgrade-path entry (D-01, reconciling two researchers); SQL extracted from guide markers (D-03/D-08); gsd-pr-branch landing per the 0.10.0 precedent (D-13). Push/merge/publish remain the maintainer's.)*
