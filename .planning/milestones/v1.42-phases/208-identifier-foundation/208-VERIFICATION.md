---
phase: 208-identifier-foundation
verified: 2026-09-25T18:10:00Z
status: passed
score: 4/4 roadmap success criteria verified (plus 41/41 plan must-have truths, 3/3 prohibitions)
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/phases/208-identifier-foundation/208-01-PLAN.md
  - .planning/phases/208-identifier-foundation/208-01-SUMMARY.md
  - .planning/phases/208-identifier-foundation/208-02-PLAN.md
  - .planning/phases/208-identifier-foundation/208-02-SUMMARY.md
  - .planning/phases/208-identifier-foundation/208-03-PLAN.md
  - .planning/phases/208-identifier-foundation/208-03-SUMMARY.md
  - .planning/phases/208-identifier-foundation/208-04-PLAN.md
  - .planning/phases/208-identifier-foundation/208-04-SUMMARY.md
  - .planning/phases/208-identifier-foundation/208-05-PLAN.md
  - .planning/phases/208-identifier-foundation/208-05-SUMMARY.md
  - CHANGELOG.md
  - lib/mix/tasks/threadline.gen.triggers.ex
  - lib/mix/tasks/threadline.install.ex
  - lib/threadline/capture/naming.ex
  - lib/threadline/capture/trigger_sql.ex
  - lib/threadline/continuity.ex
  - lib/threadline/mix/migrations_path.ex
  - lib/threadline/mix/trigger_migration.ex
  - lib/threadline/policy/redaction_presenter.ex
  - lib/threadline/storage_schema.ex
  - mix.exs
  - release-please-config.json
covered_digest: "v1:sha256:867d2037f0c40243c2239c240e86ccbcfab027c69fe8c0a4206ac03700e6ddd8"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 208: Identifier Foundation Verification Report

**Phase goal:** Every identifier Threadline derives is valid, deterministic, unique per table and within PostgreSQL's 63-byte limit, and generator tasks agree on where migrations live.
**Verified:** 2026-09-25
**Status:** passed
**Re-verification:** No. This is the first verification. No earlier VERIFICATION.md exists.

## Phase gate

I ran `mix ci.all` myself at HEAD `be4026c8`, after all the review-fix commits. It exited 0.

| Step | Result |
|------|--------|
| verify.format, verify.credo, `compile --warnings-as-errors`, xref cycles, compile without optional deps | clean (credo: 3574 mods/funs, no issues) |
| verify.test | 7 properties, 1924 tests, 0 failures, 1 excluded |
| verify.threadline / verify.example | 117 tests, 0 failures |
| verify.dialyzer (dev) | Total errors: 0. No PLT rebuild was needed. |
| verify.example_browser (desktop and mobile chromium) | 318 passed, 0 failed, 26 skipped. Plan 05 also had 0 failures, so there is no regression. |

I also re-ran the phase's own test files with a new seed (`--seed 4242`): naming, naming properties, storage_schema, `test/threadline/mix/`, gen_triggers, install, changelog_contract and trigger_rerun. Result: 7 properties, 156 tests, 0 failures, in 0.5 s. The properties have a bounded runtime.

## Goal Achievement

### Observable truths (roadmap success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | An oversized or invalid schema/table name gives an error that names the identifier and its byte count, never "storage schema" (unit test on the naming module and on `mix threadline.gen.triggers`) | VERIFIED | `StorageSchema.validate_identifier!/3` has the roles `:storage_schema`, `:host_schema`, `:host_table` and `:derived`, and reports sizes with `byte_size`. Unit tests: `naming_test.exs:225-258` asserts "host table", "host schema" and "70 bytes", and refutes "storage schema". The Mix task test at `gen_triggers_test.exs:404-412` checks the `--tables:` prefix, "host table", the table name and "70 bytes", and refutes "storage schema". I spot-checked this myself: a 64-byte table passed to `Naming.function_name` raises `Threadline host table "xxx…" (from "public.xxx…") is 64 bytes`. The derived overflow path, a per-table function for a 50-byte table, raises `Threadline derived identifier "threadline_capture_changes_ttt…" is 77 bytes`. |
| 2 | StreamData properties in the default `mix test` (async, bounded) prove derived names are at most 63 bytes, match the identifier regex, are deterministic, and are injective under biased generators. A golden test freezes the format, including byte-identical trigger names where the legacy name fits | VERIFIED | `naming_property_test.exs` uses `async: true` and `use ExUnitProperties`, has no exclusion tag, and has 7 properties. It checks: at most 63 bytes plus the identifier regex (trigger, function, legacy function and migration names and modules); determinism; injectivity given distinct hash12 (per D-04); that the trigger name is the legacy name cut to 63 bytes; migration-hash order independence; and the hashed-iff-not-legacy rule. The generators produce `_`-split pairs (`public.<s>_<t>` vs `<s>.<t>`), upcase and swapcase pairs, and 36-byte shared prefixes. The golden test at `naming_test.exs:12-47` freezes every D-05 row. I recomputed the hashes independently (see below) and all match. |
| 3 | `gen.triggers` writes to, and detects reruns in, the repo's configured migrations path, using the same resolution as `install`, and honors `--migrations-path` (tested against a non-default `priv` repo) | VERIFIED | Both tasks call `Threadline.Mix.MigrationsPath.resolve/1`: install at line 69, and gen.triggers `run/1` before the dry-run branch. The one resolved `path` is passed to `MigrationVersion.next`, `TriggerMigration.scan` and `rerun?` (`write_migration!/3`). Tests with `CustomPrivRepo` (`priv: "priv/custom_repo"`) at `gen_triggers_test.exs:306-392` cover: the custom `:priv` directory, rerun detection in that directory (`_2` file plus the rerun message), `--migrations-path` winning over `--repo`, `-r`, a repeated `--repo`, and dry-run validation. `install_test.exs:257-330` covers the same for install. |
| 4 | `release-please-config.json` has `bump-minor-pre-major: true` in a non-releasable `ci:`/`chore:` commit that precedes every releasable commit (contract test plus a recorded `git log` ordering check) | VERIFIED | The config has `"bump-minor-pre-major": true` and `"bump-patch-for-minor-pre-major": false`. The contract test is `changelog_contract_test.exs:200`. The ordering check is below: the config commit `28beadd9 ci(release)` is the 11th commit on main..HEAD, and the first releasable commit, `31dfcc2c fix(208-02)`, is the 16th. |

**Score:** 4/4 roadmap truths verified. None is behavior-unverified.

### Plan must-haves and locked decisions

All five plans' `must_haves.truths` are satisfied at HEAD. Notes on the ones that needed judgment:

- **D-02:** trigger names are never hashed. `Naming.trigger_name/1` is `cut("threadline_audit_" <> suffix, 63)`. `TriggerSQL.create_trigger_sql/2` and `drop_trigger/1` both use it. My spot check: a 50-byte table gives a 63-byte trigger name, quoted, and the default-mode migration generates instead of raising.
- **D-03 / D-04:** `function_name/1` applies all three legacy conditions: `public`, at most 36 bytes, and no `_<12hex>` tail. Otherwise it uses a 23-byte stem, then `_`, then hash12. The injectivity claim is scoped to distinct hash12, and the module comment states 1.8e-7 at 10k tables.
- **D-06 / D-07:** `migration_name/2` hashes over the sorted unique qualified names and trims the trailing `_` from the readable part. `TriggerMigration.resolve_name/2` delegates to it and keeps the ordinal and collision loop. The 44-underscore golden row, `threadline_triggers__4b1eb587a18a`, is present, and I recomputed its hash (`4b1eb587a18a`).
- **D-08:** after the review fix, the default-lookup fallback to `priv/repo/migrations` is kept and now prints a warning (`MigrationsPath.fall_back/2`). An explicit `--repo` that fails to load raises. Neither `Ecto.Migrator.migrations_path` nor `Mix.EctoSQL` is used. This honors the locked D-08. The first WR-03 attempt raised instead, which violated D-08, and it has been superseded (`defc3fc0`).
- **D-09:** both tasks use strict `OptionParser`, `repo: :keep` and alias `r`. Install raises on unknown flags. The moduledoc and CHANGELOG document this and the umbrella note.
- **D-10:** `validate!/1` delegates with `:storage_schema`, and its message text is unchanged. `continuity.ex:89` and `redaction_presenter.ex:36` use `:host_schema`. `Naming.pair/1` re-validates map input (WR-01).
- **D-11:** `rerun?/2` stays name-based. The CR-01 fix treats a 63-byte name as a prefix match, so uncut pre-0.10 names are recognized. That is the conservative direction D-11 accepts.
- **Known interim deviation:** the D-10 clause "derived names never raise" does not yet hold for per-table capture functions. They keep the legacy name and raise a `:derived` ArgumentError when they overflow. This is the handoff documented in `208-05-SUMMARY.md` for NAME-02 in Phase 209. It is not a gap for 208: no derived identifier over 63 bytes is ever emitted, the error names the derived identifier and its byte count, and none of 208's success criteria requires hashed function emission. Phase 209 SC1 explicitly covers distinct per-table capture functions.
- **Backstop truth, "Naming functions are pure and stateless":** VERIFIED. `naming.ex` reads no process, application or ETS state, and uses only `:crypto`, `Base`, `Regex` and binary operations. The async determinism property passes under two seeds (the ci.all run and seed 4242).

### Prohibitions

| Prohibition | Tier | Disposition | Evidence |
|-------------|------|-------------|----------|
| No releasable commit before the `bump-minor-pre-major` commit | test | VERIFIED (enforcement: the ordering check the roadmap requires, run and recorded below) | The first commit touching `release-please-config.json` is `28beadd9`. The first feat/fix/perf/deps commit is `31dfcc2c`, which comes later. |
| Two distinct tables with distinct hash12 never get the same function name | test | VERIFIED | The property "distinct tables with distinct hash12 get distinct function names" passes, with biased pair generators. |
| A trigger name that fits in 63 bytes is never renamed, hashed or re-cased | test | VERIFIED | The property "the trigger name is the legacy name cut to 63 bytes" passes, and so do the golden rows, including `threadline_audit_Users` and `threadline_audit_users`. |

## REL-01 ordering check (recorded)

`git log --reverse --format=%h main..HEAD -- release-please-config.json | head -1`:

```
28beadd9
```

`git log --reverse --format='%h %s' main..HEAD`. There are 48 commits. The first 17:

```
e2b3a980 docs: add milestone guide and the base-library ladder to 1.0.0
4117492c docs: start milestone v1.42 Capture Correctness for Real Table Shapes
9b8672a9 docs: complete v1.42 project research
f04de828 docs: define milestone v1.42 requirements
f33158a0 docs: create milestone v1.42 roadmap (6 phases)
ad6abfff docs(208): capture phase context
d0192be2 docs(state): record phase 208 context session
9e644eab docs(208): research phase domain
db0f1e10 docs(phase-208): add validation strategy
fd128c67 docs(208): create phase plan
28beadd9 ci(release): propose minor bumps for breaking changes before 1.0
c3f207a5 chore(test): add stream_data for property tests and list :crypto
c26b49f2 docs(208-01): complete release policy flip and test infrastructure plan
d0ed6672 docs(208-01): update state, roadmap and REL-01 after plan 01
7499d9db test(208-02): add failing role-accurate identifier error tests
31dfcc2c fix(208-02): name the host identifier role, value and byte count in errors   <- first releasable
07c8c677 fix(208-02): report host schema errors as host schema in runtime callers
...
be4026c8 docs(208): WR-03 record the warning-based fallback fix (D-08)
```

All 10 commits before `28beadd9` are `docs:` commits, and so is every other commit up to `31dfcc2c`. REL-01 ordering holds.

## D-05 golden hashes (independently recomputed)

`printf '%s' '<input>' | shasum -a 256 | cut -c1-12`:

| Input | Recomputed | In naming_test.exs |
|-------|------------|--------------------|
| public.posts | c6fcf4ae4927 | match |
| billing.invoices | 9bba11019407 | match |
| public.billing_invoices | ee2e817bbf91 | match |
| public.customer_subscription_line_items_archive | 3b9be56c3c45 | match |
| analytics_reporting.customer_lifetime_value_snapshots | 411cf9724315 | match |
| public.ledger_0123456789ab | 6095cae6be06 | match |
| public.Users | 3268e9c3e2ba | match |
| public.users | 14447575adab | match |
| a.b (adjacency row) | 2e7336dc8eba | match |
| public. followed by 44 underscores (migration row) | 4b1eb587a18a | match |

## Required artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `lib/threadline/capture/naming.ex` | VERIFIED | Substantive: hash12, pair, qualified, suffix, trigger, function, legacy function and migration names. Wired into TriggerSQL, TriggerMigration and gen.triggers. |
| `lib/threadline/mix/migrations_path.ex` | VERIFIED | Implements the full precedence, the repeated-`--repo` error and the warning fallback. Used by install and gen.triggers. |
| `lib/threadline/storage_schema.ex` (`validate_identifier!/2,3`) | VERIFIED | Role labels. Called from parse_table_identifier, continuity, redaction_presenter, Naming.pair and TriggerSQL. |
| `lib/mix/tasks/threadline.gen.triggers.ex` | VERIFIED | Strict flags, `MigrationsPath.resolve`, the `--tables` rescue and `rerun?(Naming.trigger_name(pair), …)`. |
| `lib/mix/tasks/threadline.install.ex` | VERIFIED | Strict flags and `MigrationsPath.resolve`. |
| `lib/threadline/mix/trigger_migration.ex` | VERIFIED | `resolve_name` uses `Naming.migration_name`. `rerun?` has the conditional boundary. |
| `lib/threadline/capture/trigger_sql.ex` | VERIFIED | `Naming.trigger_name` in create and drop. `:derived` validation of the per-table function base (interim). |
| `release-please-config.json` and `changelog_contract_test.exs` | VERIFIED | |
| `mix.exs` | VERIFIED | `{:stream_data, "~> 1.4", only: :test}` (locked 1.4.0) and `extra_applications: [:logger, :crypto]`. |
| Tests: naming, naming_property, migrations_path, custom_priv_repo support, gen_triggers, install, storage_schema, trigger_migration | VERIFIED | All pass. |

## Key links

| From | To | Status |
|------|----|--------|
| gen.triggers | `MigrationsPath.resolve(opts)` | WIRED |
| install | `MigrationsPath.resolve(opts)` | WIRED |
| gen.triggers | `TriggerMigration.rerun?(Naming.trigger_name(pair), scan.sources)` | WIRED |
| TriggerSQL create/drop trigger | `Naming.trigger_name` | WIRED |
| TriggerMigration.resolve_name | `Naming.migration_name` | WIRED |
| Naming.pair | `StorageSchema.parse_table_identifier` / `validate_identifier!` | WIRED |
| Naming.hash12 | `:crypto.hash(:sha256, _)` | WIRED |
| changelog_contract_test | release-please-config.json | WIRED |
| parse_table_identifier | `validate_identifier!(…, :host_schema/:host_table, value)` | WIRED |
| continuity.ex / redaction_presenter.ex | `validate_identifier!(…, :host_schema)` | WIRED |

## Behavioral spot-checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase gate | `mix ci.all` | EXIT=0 | PASS |
| Phase tests, new seed | `mix test <phase files> --seed 4242` | 7 properties, 156 tests, 0 failures | PASS |
| Overflowing default-mode trigger is cut, not raised | `mix run -e 'TriggerSQL.create_trigger(String.duplicate("t",50))'` | `"threadline_audit_ttt…"` (63 bytes) | PASS |
| Overflowing per-table function names the derived identifier and its size | `TriggerSQL.create_trigger(t50, :per_table)` | `Threadline derived identifier "…" is 77 bytes; …` | PASS |
| An oversized host table names the host table and its size | `Naming.function_name("public." <> 64 x)` | `Threadline host table "…" (from "public.…") is 64 bytes; …` | PASS |

## Probe execution

Not applicable. No probe scripts are declared or implied by the phase plans or success criteria.

## Requirements coverage

| Requirement | Source plan | Status | Evidence |
|-------------|-------------|--------|----------|
| NAME-01 | 208-02, 208-04, 208-05 | SATISFIED | Every derived name is capped at 63 bytes and cut or hashed in Elixir. Host errors name the role, the value and the byte count. A derived overflow on a per-table function raises and names the derived identifier (interim until 209). |
| NAME-05 | 208-04 | SATISFIED | StreamData properties plus the golden literal test. |
| CONF-02 | 208-03, 208-05 | SATISFIED | Shared resolver, `--migrations-path`, and rerun detection in the same directory. |
| REL-01 | 208-01 | SATISFIED | Config flag, contract test, and the ordering check above. |

No requirement is orphaned. REQUIREMENTS.md maps exactly these four IDs to Phase 208, and every one is claimed by at least one plan.

## Anti-patterns found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (phase-modified files) | - | TBD/FIXME/XXX/TODO/HACK | none found | - |
| `test/threadline/capture/trigger_rerun_test.exs` | 218 | The per-table overflow test asserts only `~r/at most 63 bytes/`, not the "derived identifier" label or the byte count | Info | I verified the label and byte count behaviorally (spot-check above). A tighter assertion would protect the message. |
| `lib/threadline/capture/trigger_sql.ex` | 97 | `drop_function_for_table` still emits `CASCADE` | Info | This predates the phase and is explicitly Phase 209's scope (209 SC3). |
| Review IN-01..IN-06 | - | Deferred info findings | Info | Recorded in 208-REVIEW-FIX.md. None affects a 208 success criterion. |

## Human verification required

None. Every check was automated or run by the verifier.

## Gaps summary

No gaps. All four roadmap success criteria hold in the codebase at HEAD `be4026c8`. The full `mix ci.all` gate is green, including Dialyzer and the browser lane (0 failures). The golden hashes match independent recomputation, and the REL-01 ordering is confirmed from git history. The only known interim deviation is that per-table capture functions keep their legacy names and raise `:derived` on overflow. It is documented, stays inside the 63-byte guarantee because nothing oversized is emitted, and is owned by Phase 209 (NAME-02).

---

_Verified: 2026-09-25_
_Verifier: Claude (gsd-verifier)_
