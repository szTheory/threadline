# Phase 198 — Red-Baseline Triage

**Produced by:** Plan 198-04
**Date:** 2026-08-27
**Binding taxonomy:** D-05 (`test | category | disposition | evidence`)

---

## Headline: the "stale database" diagnosis was wrong

Plan 198-04 was written on an inherited hypothesis — that CI's **83 failures** were a
maintainer-machine artifact of a test database predating
`priv/repo/migrations/20260607000000_threadline_storage_schema_default.exs`, and that a
freshly recreated database would leave **exactly one** deterministic failure.

**That hypothesis is false, and this plan disproved it with direct evidence.**

| Measurement | Failures | Notes |
|---|---|---|
| Maintainer's existing local database (before any change) | **4** | the state the hypothesis was formed on |
| **Freshly dropped and recreated database** (`mix test.reset`) | **82** | the honest local baseline |
| CI `verify-test`, both `min` and `current` lanes (run `33113172280`) | **83** | 82 + `stress_router_test.exs`, which CI also fails |

Recreating the database made the suite **worse**, not better — 4 → 82. The reconciliation
is exact: **79 + 1 + 1 + 1 = 82** locally, **+1 = 83** in CI. Nothing is unaccounted for.

### Proven root cause of the 79

The library's audit schemas deliberately carry **no** `@schema_prefix` — this is enforced by
`test/threadline/storage_schema_prefix_contract_test.exs:20-25`, which asserts
`module.__schema__(:prefix) == nil`. Callers are required to pass `prefix:` explicitly. But 79
tests reach the audit tables through **unprefixed** repo calls (`Repo.all(AuditChange)`,
`Repo.delete_all(AuditTransaction)`), which can only resolve if `threadline` is on the
connection's `search_path`.

Evidence, gathered directly against PostgreSQL:

```
$ psql -d threadline_test -c 'select count(*) from audit_changes;'
ERROR:  relation "audit_changes" does not exist

$ psql -d threadline_test -c 'set search_path to public,threadline; select count(*) from audit_changes;'
 0
```

The maintainer's database was green because it carried a **database-level**
`search_path` setting that included `threadline`. Two facts pin this down:

1. `pg_db_role_setting` has **no role-level** entry for the `postgres` role
   (`setdatabase = 0` returns nothing), so nothing that survives a `DROP DATABASE`
   was supplying the path.
2. `threadline_phoenix_test` — the *example app's* database — still carries
   `search_path="$user", public, threadline` (set by `ci.yml`, legitimately and by design
   for the host application). `threadline_test` carried an analogous setting until this
   plan dropped the database, and the drop removed it along with the database.

**So the red baseline is not environmental drift and not a stale schema. It is 79 real
test-side defects that were masked, on exactly one machine, by the very `search_path`
reliance that D-02 forbids the library from depending on.** CI never had that mask, which
is why CI has been red at 83 all along.

### Why these are not filed as "environmental"

D-05 binds *environmental* to "fix the **setup path**, never the test." The only setup-path
change that would turn these 79 green is putting `threadline` on the test connection's
`search_path` — precisely what **D-02 prohibits**, and precisely the mask that hid these
defects for so long. Filing them as environmental and applying the "obvious" setup fix would
be the single largest act of laundering available in this phase: it would produce a green
suite while re-establishing the dependency the library sells itself on not having.

They are therefore filed as **real bug (test-side)**, disposition **deferred**, with the
remediation shape named. This is an honest departure from D-05's four-way taxonomy, which has
no slot for "real defect located in test code rather than `lib/`, requiring a remediation
larger than the plan that found it." Recording that gap is better than forcing the rows into
a category whose evidence rule they cannot satisfy.

---

## Triage table

Rows ordered by test file path so the artifact diffs deterministically.
`n` is the number of failing tests contributed by that file on a freshly recreated database.

| test | category | disposition | evidence |
|---|---|---|---|
| `test/mix/tasks/threadline.evidence_show_test.exs` (n=7) | real bug (test-side) | deferred — see "Deferred: the 79" | Fails `relation "audit_changes" does not exist` on a fresh DB. Unprefixed repo access; schemas assert `__schema__(:prefix) == nil`. Reproduced by `mix test.reset` this plan. |
| `test/mix/tasks/threadline.incident_test.exs` (n=4) | real bug (test-side) | deferred — see "Deferred: the 79" | Same signature and root cause. |
| `test/mix/tasks/threadline/export_test.exs` (n=1) | real bug (test-side) | deferred — see "Deferred: the 79" | Same signature and root cause. |
| `test/threadline/capture/trigger_changed_from_test.exs` (n=4) | real bug (test-side) | deferred — see "Deferred: the 79" | Same signature and root cause. |
| `test/threadline/capture/trigger_context_test.exs` (n=2) | real bug (test-side) | deferred — see "Deferred: the 79" | Same signature and root cause. |
| `test/threadline/capture/trigger_redaction_test.exs` (n=3) | real bug (test-side) | deferred — see "Deferred: the 79" | Same signature and root cause. |
| `test/threadline/capture/trigger_test.exs` (n=5) | real bug (test-side) | deferred — see "Deferred: the 79" | Same signature and root cause; uses `Threadline.DataCase`, which aliases the bare `Threadline.Test.Repo`. |
| `test/threadline/evidence/proof_test.exs` (n=5) | real bug (test-side) | deferred — see "Deferred: the 79" | Same signature and root cause. |
| `test/threadline/governance/evidence_record_test.exs` (n=3) | real bug (test-side) | deferred — see "Deferred: the 79" | Same signature and root cause. |
| `test/threadline/operator_surface/breadcrumb_test.exs` (n=2) | real bug (test-side) | deferred — see "Deferred: the 79" | Same signature and root cause. |
| `test/threadline/operator_surface/copy_contract_test.exs` (n=13) | real bug (test-side) | deferred — see "Deferred: the 79" | Same signature and root cause; fails in `__ex_unit_setup_1/1` at `:147`. |
| `test/threadline/operator_surface/exports_mix_parity_test.exs` (n=3) | real bug (test-side) | deferred — see "Deferred: the 79" | Same signature and root cause. |
| `test/threadline/operator_surface/formless_pages_test.exs` (n=1) | rotting assertion | **rewritten** — `git rm`, superseded by `test/threadline/operator_surface/ui_form_policy_contract_test.exs` | The allowlist at `:47-54` omitted `policy_redaction_live`, which grew a `<form phx-submit="select-schema">` + `<select>` at `policy_redaction_live.ex:256-258`. The successor is exhaustive over `*_live.ex` and self-declaring, so a page cannot be silently unguarded. Teeth demonstrated in the Plan 198-04 SUMMARY: added a form control to a `:formless` page (red, naming the file and tokens), then stripped a declaration (red, naming the missing declaration). |
| `test/threadline/operator_surface/live/row_history_live_test.exs` (n=8) | real bug (test-side) | deferred — see "Deferred: the 79" | Same signature and root cause. |
| `test/threadline/operator_surface/row_history_component_test.exs` (n=5) | real bug (test-side) | deferred — see "Deferred: the 79" | Same signature and root cause. |
| `test/threadline/operator_surface/stress_router_test.exs` (n=1, CI only) | environmental | **fixed** — setup path, via the `mix test.setup` alias | `:294` shells into `examples/threadline_phoenix` and runs `mix run`, which aborts with "Unchecked dependencies for environment test" when the example app's deps were never fetched. `ci.yml`'s `verify-test` job runs `mix deps.get` for the library only, so CI fails this too. Fixed in `mix.exs` by `test.setup` fetching the example app's deps before the suite — the setup path, not the test. Verified: green locally after `mix test.reset`. |
| `test/threadline/operator_surface/transaction_live_test.exs` (n=14) | real bug (test-side) | deferred — see "Deferred: the 79" | Same signature and root cause; fails in `__ex_unit_setup_0/1` at `:155` and `:648`. |
| `test/threadline/phase06_nyquist_ci_contract_test.exs` (n=1) | rotting assertion | **rewritten** — count literal derived from ci.yml, parity assertions kept | `:185` hardcoded `MapSet.size(jobs) == 10`; ci.yml legitimately has 12 `verify-*` jobs, so the literal rotted and the test failed for a reason unrelated to its actual invariant. Replaced with a non-empty assertion (so it cannot pass vacuously) plus the unchanged three-way parity assertions. **Teeth demonstrated live:** the rewritten assertion is *currently red* against real drift — `only-in-jobs=["verify-capture", "verify-mechanical"]`, i.e. CONTRIBUTING.md List 1 genuinely omits two jobs ci.yml runs. See "Deferred: CONTRIBUTING List 1". |
| `test/threadline/v1_23_charter_doc_contract_test.exs` (n=1) | obsolete | **deleted** — `git rm`, no successor guard | **Coverage was dropped, deliberately and with no replacement.** This test asserted that `.planning/PROJECT.md` contains the literal string "milestone **v1.38 Operator UI Page-by-Page IA & Design-System Polish**" and that `.planning/MILESTONE-ARC.md` contains specific table rows. It is a Phase-104 readability proxy over planning documents — the exact surface v1.41 is decoupling the repository from. Per D-06 it was neither version-bumped (which would restart the same rot on the next milestone) nor loosened to a `~r/v1\.\d+/` shape that would pass against any content and therefore assert nothing. No successor guard exists: the library's real version truth is already guarded independently by `test/threadline/version_truth_doc_contract_test.exs`, which derives from `Threadline.MixProject.project()[:version]` rather than from planning prose. Also removed from the `verify.doc_contract` alias in `mix.exs`, and `test/threadline/ci_topology_contract_test.exs:67` was flipped from `assert` to `refute` so the alias cannot silently re-acquire a path to a deleted file. |

**Row count:** 19 files / **82** failing tests on a freshly recreated database (**83** in CI,
which additionally fails `stress_router_test.exs`).

---

## Post-plan measurement (the honest number)

Measured after all three of Plan 198-04's commits, on a freshly recreated database
(`mix test.reset`):

```
1376 tests, 80 failures (1 excluded)
```

Reconciliation against the 82-failure fresh-database baseline:

| Change | Δ failures | Δ tests |
|---|---|---|
| `v1_23_charter_doc_contract_test.exs` deleted | −1 | −2 |
| `formless_pages_test.exs` deleted (superseded) | −1 | −6 |
| `zero_skips_contract_test.exs` added | 0 | +2 |
| `ui_form_policy_contract_test.exs` added | 0 | +1 |
| **Total** | **82 → 80** | **1381 → 1376** |

The remaining **80** are the 79 deferred test-side defects plus the one
`phase06_nyquist_ci_contract_test.exs` parity failure, which is now red for the real
reason (CONTRIBUTING List 1 drift) rather than for a rotted count literal. **No failure
was skipped, excluded, tagged out, or asserted away to reach this number.** Two runs of
the suite produced the same 80 and the same failing modules.

One instability worth recording rather than hiding: an intermediate run reported
`175 failures, 8 invalid`. It did not reproduce — the two runs either side both reported
exactly 80 with an identical module breakdown. The likely cause is contention on the
shared `threadline_test` database from a concurrently executing sibling plan, since this
suite deliberately does not use the Ecto SQL Sandbox (triggers fire below sandbox
awareness). Flagged as a real risk to CI determinism, not silently averaged away.

---

## Deferred: the 79

**Remediation shape (not applied by this plan).** Every one of the 79 needs the audit tables
addressed through the configured storage schema rather than through `search_path`. The
candidate fixes, in increasing order of blast radius:

1. Pass `prefix:` at each call site (`Repo.all(AuditChange, prefix: "threadline")`). Most
   explicit, most edits, no hidden behaviour.
2. Route the affected tests through the existing `Threadline.StorageSchemaCase.repo_opts/1`
   helper, which already returns the right prefix options and is already proven by
   `Threadline.StorageSchemaCaseContractTest`.
3. Change `Threadline.DataCase` to alias a thin prefixed repo wrapper instead of the bare
   `Threadline.Test.Repo`. Fewest edits, but it silently changes what `Repo` means inside
   every `DataCase` test, and it does **not** help the raw `Repo.query!` SQL those same tests
   use — so it cannot be the whole answer.

**What must NOT be done:** setting `search_path` in `config/test.exs`, or
`Repo.default_options(prefix:)`. D-02 forbids both, `storage_schema_prefix_contract_test.exs`
would catch the latter, and either would merely restore the mask that hid these defects.

**Sizing.** 79 tests across 15 files, touching test-side data access in the capture,
governance, evidence, mix-task, and operator-surface areas. This is a plan of its own, not a
task; Plan 198-04's declared scope was three tasks over `test_helper.exs`, `mix.exs`, the
triage artifact, the zero-skips guard, and the `@ui_form_policy` contract.

## Deferred: CONTRIBUTING List 1

`CONTRIBUTING.md`'s "| Job key | Purpose |" table omits `verify-capture` and
`verify-mechanical`, both of which `ci.yml` actually runs. The fix is two table rows.

**Not applied here because `CONTRIBUTING.md` is owned by the concurrently executing Plan
198-05**, and editing it from this worktree would conflict at merge. Note that 198-05 adds a
*different* table (`## CI Coverage`, one row per Playwright project) and does **not** address
List 1 — so this row is currently unowned and needs an explicit assignment.

---

## Anti-laundering cap

`test/threadline/zero_skips_contract_test.exs` asserts mechanically, on every run, that:

- no file under `test/` carries a test-level or suite-level skip tag; and
- the ExUnit exclude list carries nothing beyond `:pgbouncer_topology`, a genuine
  environment gate.

**Zero skip tags and zero added exclusions were introduced by this plan.** Both halves of the
guard were demonstrated red-then-green before commit (see the Plan 198-04 SUMMARY). The
guard's needles are assembled by runtime string concatenation rather than written as
literals, because the guard file is itself matched by the glob it scans — a literal would
make it report itself, and the natural "fix" would be to exempt it from its own scan.

---

## Publish-path and secret-store decisions

**Recorded by:** Plan 198-06, Task 2 (`checkpoint:decision`, `gate="blocking-human"`)
**Presented:** 2026-08-27 · **Answered by the maintainer:** 2026-08-27
**Binding decisions:** D-26 (single publish path), D-27 (Environment gate), D-34 step 3

Both answers were given explicitly. Neither was inferred from silence, and neither was
auto-selected — this checkpoint carried `gate="blocking-human"`, which is excluded from
auto-mode resolution precisely because its consequences are irreversible in effect.

### Decision 1 — legacy publish workflow: **DELETE** (2026-08-27)

`.github/workflows/hex-publish.yml` is deleted, leaving `.github/workflows/release.yml` as
the single publish path. D-26 as locked; confirmed, not assumed.

**What was presented, and one correction to the planning-time framing.** The legacy workflow
fires on `push: tags: v[0-9]+.[0-9]+.[0-9]+` and runs exactly two checks — a tag-name regex
and a tag-vs-`mix.exs` `@version` match (`hex-publish.yml:32-50`) — then `mix hex.publish --yes`
(`:61`). No CI gate at all. The gated path sits behind `gate-ci-green`, whose poll is 60 × 30s
= **30 minutes by construction** (`release.yml:225-234`).

The plan asserted flatly that the legacy path "wins the race by construction". Read against the
files, that is true **conditionally**, and the condition is worth recording rather than
flattening: `release.yml:6` states that tag pushes made with `GITHUB_TOKEN` do not fan out to
other workflows, and release-please runs with `secrets.RELEASE_PLEASE_TOKEN || secrets.GITHUB_TOKEN`
(`:97`, `:132`). So the race is live **precisely when the fine-grained PAT is configured** — the
tag it creates does fan out, fires the ungated path, and publishes in about a minute while the
gated path is still polling. With only `GITHUB_TOKEN` in use the legacy path is dormant today.

That does not weaken the case for deletion; it sharpens it. A publish path whose safety depends
on which token happens to be configured, with nothing asserting that configuration, is a hazard
that is one secret away from live. Deleting it removes the dependency instead of documenting it.

**What is lost:** the tag-triggered fallback. Recovery becomes `release.yml`'s `workflow_dispatch`
(`:13-27`), which takes a tag and an expected version and additionally offers `dry_run` and
`skip_distribution_sync` — a superset of what the deleted path could do.

**What is kept, and must never be weakened:** all five pre-publish gates on the surviving path —
the CI-green poll, the hard `needs: [release-ref, gate-ci-green]`, `bin/verify-release-shape` +
`mix hex.build`, the already-published idempotency skip, and post-publish verification. The
`production-hex` Environment reviewer gate added by Task 3 is added **in front of** these five,
never in place of any of them.

**Abort branch (restated, and still armed):** if `release.yml` cannot be shown green end to end,
**both** files are kept and the phase stops — Plan 198-07 must not push. A broken single path is
worse than a racy dual path. This branch was not taken; it remains the correct response if the
surviving path is later found unprovable.

### Decision 2 — paid critic API key in the repository secret store: **KEEP** (2026-08-27)

`ANTHROPIC_API_KEY` is **not** revoked from the repository secret store. This is an explicit,
dated maintainer decision with a stated rationale — not a residue of the workflow deletion, and
not an open action item.

**Rationale as given:** the workflow that consumed the secret is being deleted, so nothing in CI
can reach it. The secret becomes inert rather than dangerous.

**Why this is recorded as a decision rather than silently skipped.** Deleting a workflow does not
revoke a secret, and threat row T-198-06-03 files a residual key as an Information Disclosure
risk. The honest treatment is to answer the question, not to let the answer be implied by the
deletion. The residual risk that remains, stated rather than glossed: the secret stays reachable
by any future workflow, and by anyone who can add one. What GREEN-09 requires — and what Task 3
enforces with a test over **all** workflow files, not a named one — is that no workflow references
it. That guard covers a future re-reference, which is the reachable failure mode.

**Status: closed.** No follow-up todo is created for revocation. Revisit only if CRITIC-02 is
reconsidered, or if the key's blast radius changes.
