# Rolling quality roadmap — research baseline (2026-10-24)

**Baseline:** `main` at 07610840 (1.1.0 published, distribution sync #88 merged, no open PRs).
**Method:** six parallel read-only researchers, one per cluster: test value, performance/scale, architecture/dependencies, security/supply chain, CI/release toil, adopter correctness/carried debt. Static reads, `gh`, and `mix xref` / `credo` / `hex.audit` in a clean worktree. Facts marked **F** were observed; **I** is inference that the owning phase must verify first.
**Adoption signal (F):** 3,490 Hex downloads (126 in the last week). The only dependent is maintainer-owned. Every issue was filed by a bot. Every adopter-correctness item below is predicted, not reported. The maintainer will dogfood Threadline in their own projects.

## Healthy (F) — no action
- Compile is warning-free on Elixir 1.20.4/OTP 29 (`latest` lane). `credo --strict` 0, dialyzer ignore list empty, `hex.audit` clean.
- 0 compile-connected cycles. Public `@spec`/`@doc` complete except the `OperatorSurface.Router` macro.
- 39 property tests cover every guide §8 invariant family.
- Workflows use top-level `contents: read`, have no `pull_request_target`, and do not persist publish credentials. Secret scanning, push protection, and private vulnerability reporting are on.
- No `raw` on audit values. Export downloads check ownership. The theme redirect stays same-origin.

## Candidates by milestone

### v1.47 Release on autopilot (toil first; makes every later release cheaper)
- **F:** releases take 4 PRs (#85→#86→#87→#88; 1.0.1 followed the same pattern) and about 9 maintainer touches. release-please logged "PR #86 remained the same" after the docs-only #87. `bootstrap-release-pr-ci` fires only on `prs_created`, so the release PR kept a stale red check.
  - Fix: `sync-release-pr-pins` (release.yml:120-197) renames `## Unreleased` to `## [X.Y.Z] - date`. Backstop: `gh pr update-branch --rebase` when the release PR is behind and `prs_created` is false. Keep the human-written CHANGELOG prose; the generated 1.1.0 note was "operator UI refinement (v1.46)", which is useless to adopters.
- **F:** there is no `.github/dependabot.yml`. 78 `uses:` are tag-pinned; only `alls-green` is pinned by SHA. setup-node floats on `"22"`. Add Dependabot security-only updates for mix (all three directories) and github-actions, then SHA-pin with a contract test.
- **F:** the deps-audit gate blocks on example/bench-only advisories. The Hex tarball ships no mix.lock. Shipped runtime deps should block; dev/example deps should file an issue (deps-health lane), with a test pinning that behaviour.
- **F:** nothing retries network fetches. Wrap `deps.get` and the hex-evaluator resolve in retries (never tests).
- **F:** issue #61 never closes, because "outdated" is a permanent state. Report advisories and retirements only, and auto-close when clean. Fix `bin/deps-health-report:23` (any non-zero exit is counted as outdated).
- **F:** the browser E2E job is the critical path at 653–831 s. It runs 482 tests on `workers: 1` and nobody can see which spec dominates. First publish per-spec timing (JSON report / `reportSlowTests`), then split per Playwright project, using blob merge for the journey receipt. Target: CI median ≤ 9 min.
- **F:** contract tests are 48% of measured test weight and re-run on min/latest. Tag `:repo_contract`, run on the current lane only, keep local `mix test` whole, and refresh partition weights (skew today: 127–200 s against a predicted 74 s).
- Close the fixed carried items and bulk-waive obsolete WINDOWS rows (register below). Retire the parked critic loop to a tag (decision D-4).
- Maintainer settings action: move `HEX_API_KEY` from a repo secret to a `production-hex` environment secret, and restrict deployments to main and `v*` tags.

### v1.48 Safe by default (correctness + security) → 1.2.0
- **F — operator surface fails open.** `router.ex:148-157` accepts any `pipe_through`, and the default `authorize_fn` is `fn _ -> true end` (`export_auth_plug.ex:14`, `theme_auth_plug.ex:32`). The guide's "fail-closed" claim and the ack-option behaviour (`operator-surface.md:159-166`) are not implemented. Decision D-1: fix as a bug.
- **F/I — txid reuse after logical restore.** `txid bigint UNIQUE` plus `ON CONFLICT (txid) DO NOTHING` (`capture/migration.ex:29`, `trigger_sql.ex:325-338`). After a pg_dump/restore into a new cluster, new changes silently attach to old transaction rows. Prior art: Carbonite #45. Decision D-2: health detection first, then a trigger fix plus a regenerate note. The duplicate `audit_transactions_txid_idx` folds into the trigger fix.
- **F — CSV formula injection:** the `x-correlation-id` header is persisted unbounded (`plug.ex:92`) and exported raw (`export.ex:285`, `export/csv.ex`). Cap and validate header-derived ids; add an opt-in `spreadsheet_safe:` option.
- **I — search_path:** generated functions have no `SET search_path` and call unqualified polymorphic built-ins (`trigger_sql.ex:257/312/421/483`). Pin it and measure the overhead. Reject `$`/backslash in redaction names (`trigger_sql.ex:628,655`). Collapse the 3 copies of `sql_string_literal` into one helper.
- **I — PgBouncer:** session advisory locks in `retention/pruner.ex:277,283` and `export/cleanup_task.ex:149,155`. Write a topology test to reproduce, then move to xact-scoped locks.
- Honest guides: what capture does not see (TRUNCATE, `session_replication_role`, DISABLE TRIGGER); least-privilege role layout; testing under the Ecto SQL sandbox (I: one txid per test means the first actor wins; Carbonite #150/#120).
- Raise the floor to Elixir 1.17 / OTP 27 (decision D-3).
- Small items: `NotFoundError.message/1` bare-map match; the grouped-alias gap in the boundary-test scanner; raw SQL and session-level `set_config` in `incident_replay.exs`; `mix threadline.verify_topology` is shipped in the package but is repo-only.
- Routed by Phase 246 (DEBT-01; rows in 246-DEBT-REGISTER.md):
  - CR-05 (`W7`, `198-CR-05`): `bin/verify-branch-protection` never diffs `bypass_actors` against `.github/rulesets/main.json:5`.
  - T-215-36: `bin/verify-deps-audit` and `bin/deps-health-report` should refuse `MIX_EXS` / `MIX_HOME` at runtime, the way they refuse `HEX_IGNORE_*`.
  - 216 IN-03: the CONTRIBUTING runbook passes the GitHub token on argv (`:1205`) and uses a GNU-only sed escape (`:1207`).
  - ECON-03: confirm one CI run per release PR on the first natural release (the same trigger as the 244 REL-02 observation).
  - The three small items above map to rows `233-IN-01`, `234-WR-02`, and `231-IN-01` plus `INCIDENT-REPLAY-SESSION`.

### v1.49 Honest specs (test quality)
- Mutation testing with no new dependency: a replayable script mutates the critical modules (trigger SQL generation, redaction, retention cutoff, cursors, row keys). A survivor marks a weak spec; a test that is never the first to fail is a tautology candidate.
- Contract-test pass: 111 files, 1,052 tests, 42% of test LOC. Time-boxed keep/merge/delete, largest files first; every kept guard names its failure class and has a negative control. Rename planning-ID test names (308) only when a file is touched for another reason.
- One-shot `mix test --cover` probe, then add tests for uncovered error paths. No coverage gate.
- Dependency-floor lane: the declared floors are never compiled (ecto_sql 3.10, LV 1.0, oban 2.15, plug 1.15). Either test them or raise them.
- Twin probes: PG18 virtual and stored generated columns, bytea, the SQL sandbox.
- Move slow tooling smokes out of the three-lane suite (stress_router 47 s, fail_fast 32 s, prod_compile 26 s and others), but keep the prod-leak check.
- Routed by Phase 246 (DEBT-01; rows in 246-DEBT-REGISTER.md):
  - 216 WR-01: a contract tying the CONTRIBUTING pin literals to `.tool-versions`.
  - 216 WR-02: make the Release Please runbook contract exact (no `@v5` matching `@v50`, check the rehearsal line, check every action ref).
  - clean_checkout tmp-dir collision: move `clean_checkout_contract_test.exs:339` to `@tag :tmp_dir`.
  - 215 IN-04: `bin/deps-health-report:443` truncation can leave a code fence unclosed and drop the policy footer.

### v1.50 Measured performance
- **F:** benches are stale (2026-05, M2). The redaction bench updates one row (noise: baseline is slower than redacted). `performance.md` advertises a trigger `WHEN` knob that does not exist (`primary_key_sql.ex:522`). No bench compares against an untriggered table.
  - Fix: an in-server capture bench with an untriggered control (1/10k/100k rows, WAL bytes, audit bytes/row), weekly ratchet at 1.5×, and rewrite `performance.md`.
- **F:** the retention orphan drain runs a full anti-join after every 500-row batch (`retention.ex:306-312,373-398`). Delete RETURNING and check only those ids.
- **F:** the actor GIN index and the `occurred_at`, `action_id`, and `correlation_id` indexes exist only in the repo's test migration, not in adopter templates. Add a `CONCURRENTLY` index generator plus EXPLAIN-shape tests against the templates.
- **F:** `timeline/2` is unbounded (`query.ex:621-637`). Add `:limit` (the default cap waits for 2.0). Per-row trigger micro-optimisations (RETURNING id, a txid GUC cache, no-op UPDATE skip) only after the baseline exists. Add a Health storage/retention-lag check.

### v1.51 Lean dependency tree
- Vendor the CSV dumper and drop `nimble_csv` (only `dump_to_iodata/1` is used). Make Plug optional (`Code.ensure_loaded?`). Together these take the required tree from 11 to 7 packages.
- Drop unused optional deps (`phoenix_pubsub`, `sweet_xml`) and widen `req` to `~> 0.7 or ~> 1.0`. Remove `heroicons` from the example and `benchee_html`/`benchee_markdown` from bench.
- Collapse the export row encoder copied between `export.ex:463-533` and `query/export_reads.ex:204-274`; share the repo-start helper used by 8 Mix tasks.
- Runtime cycles are 8, not the guide's 5: untangle the `Query` helper cycles, then gate with `--fail-above`. Widen the layer-boundary test.
- Move maintainer tooling (about 5.1k lines) out of `lib/`; drop `CONTRIBUTING.md` from the Hex `files:`.
- Routed by Phase 246 (DEBT-01; rows in 246-DEBT-REGISTER.md):
  - 215 WR-10: dedupe `read_global_hex_ignore` (`bin/deps-health-report:170`, `bin/verify-deps-audit:335`).
  - 215 WR-09: the dedupe lets `bin/verify-deps-audit --self-test` prove the deps-health-report suppression path too. It has a security angle, so it is routed rather than waived.

## Rejected / not this (adversarial pass)
- Mutation-testing or coverage dependencies, and a coverage-% gate.
- `workers > 1` or `fullyParallel` in one browser job.
- Change-aware CI lanes (SEED-006: 0 of 28 PRs inert), a merge queue, auto-rerun bots, and test retries.
- Release-please-generated user-facing notes; auto-merging the release PR; skipping the `production-hex` approval.
- Statement-level triggers, native partitioning, UUIDv7, and changed-fields-only capture.
- SECURITY DEFINER capture in 1.x; hash chains; Sobelow; a standalone Scorecard badge.
- Splitting operator LiveViews or `lib/threadline.ex`, and renaming `ActorRef`.
- Deprecating the S3 adapter (no signal; revisit at 2.0).

## Carried-debt register (verified against 07610840)
| Item | Status | Disposition |
|---|---|---|
| 231 WR-01, 234 WR-01, 233 WR-01 | Fixed (PR #81; `audit.ex:216`, `job.ex:80`, `transaction_lookup.ex:69`) | Close |
| gen.triggers `down` orphan (v1.42) | Fixed (`gen.triggers.ex:601-617`) | Close |
| gen.backfill, `:invalid_config` | Rejected in v1.44 | Close |
| Partition weights missing property files; bench compile; 216 CR-01; 217 R2-* | Fixed | Close |
| SEED-005 reconnect banner | Shipped (`ui/page.ex:295`); seed record stale | Close the seed |
| 233 IN-01, 234 WR-02, 231 IN-01 + incident_replay session config | Still real | v1.48 small items |
| 216 action pinning / setup-node float; 215 WR-01 | Still real | v1.47 |
| 215 WR-04..08, IN-01..03; 223 5 WR + 1 IN | Open, low adopter value | v1.47: fix the cheap ones, waive the rest with a reason |
| clean_checkout tmp-dir collision | Latent | v1.49: move to `@tag :tmp_dir` |
| `verify.temp_leaks` not continuous; v1.42 guide IN-01/02 | By design / obsolete | Waive |
| WINDOWS ledger (60 open, phases 198–202) | Mostly obsolete | Bulk-waive; re-check CR-05 |
| v1.46 UI items (DR-243-01, typography, Redaction copy) | Still real | Parked with UI |

**Disposition (246):** Phase 246 re-verified every row above and expanded it to one row per finding in `.planning/phases/246-debt-closeout-and-critic-retirement/246-DEBT-REGISTER.md`. That file is the canonical record (131 rows: 64 closed, 44 waived, 23 routed). Routed items appear in the v1.48, v1.49 and v1.51 lists above. The UI items, including the 8 screenshot baselines, are carried by `.planning/seeds/SEED-008-operator-ui-carry.md`. The table above keeps its original 07610840 text. Where it disagrees with the register (for example "223 5 WR + 1 IN", which D-00a corrected), the register wins.
