# Phase 220: Newest-Toolchain Lane - Research

**Researched:** 2026-09-28
**Domain:** GitHub Actions CI matrix, Elixir/OTP/PostgreSQL version pinning, `erlef/setup-beam`
**Confidence:** HIGH

## Summary

This phase is almost entirely specified by `220-CONTEXT.md` (D-01..D-18), which is itself the
product of a prior research-then-recommend pass the maintainer accepted in full. This research
pass's job was to (1) independently re-verify the version pins and their sources against live
registries, (2) verify or refute the one open research flag (PG 18's AFTER-trigger role-execution
change), and (3) confirm the exact file/line targets D-08 and D-13/D-14/D-15/D-16/D-17 name,
against the actual tree, so the planner is not trusting a decision doc's citations blind.

All three came back clean. The three pins (`elixir: "1.20.4"`, `otp: "29.1.1"`, `pg: "18.6"`) are
confirmed live against `builds.hex.pm` and Docker Hub as of 2026-09-28 — no newer patch has shipped
since CONTEXT.md was written earlier today. The PG 18 AFTER-trigger role-execution change is real
(confirmed in the PG 18 release notes) but does not touch Threadline: the capture trigger SQL in
`lib/threadline/capture/trigger_sql.ex` contains no `CURRENT_USER`/`SESSION_USER`/role-dependent
logic, and no schema in the repo (outside `deps/`) uses `GENERATED ALWAYS AS` virtual/generated
columns, so the PG 18 default-virtual-generated-column change is also inert here. Every specific
line number CONTEXT.md cites in `ci.yml`, `ci_workflow_parity_contract_test.exs`, `CONTRIBUTING.md`,
`README.md` and `mix.exs` was independently re-read this session and matches (a few are off by a
line or two from renumbering since CONTEXT.md was written, noted below).

**Primary recommendation:** Follow `220-CONTEXT.md` D-01 through D-18 as written — it is
plan-ready. This RESEARCH.md exists to confirm the decisions have not gone stale in the hours since
they were locked, to hand the planner exact current line numbers, and to close the one explicit
open research flag (D-13 "specifics" section, PG 18 role-execution).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Toolchain matrix row (`lane: latest`) | CI / Workflow config | — | Pure GitHub Actions YAML; no application code |
| Pin freshness verification | CI / Workflow config | Process (MILESTONE-GUIDE checklist) | Executed at plan/execute time against external registries, not automated in-repo (D-18) |
| Warning-surface remediation (D-08) | Application (`lib/`) | — | Dead-code/pattern fixes in `lib/mix/tasks`, `lib/threadline/critic_trust`, `lib/threadline/operator_surface/live` |
| Contract enforcement (roster, pins shape, no-continue-on-error, no-beta-pg) | Test suite (`test/threadline/ci_workflow_parity_contract_test.exs`) | — | Existing contract-test pattern; this phase extends it, does not create a new mechanism |
| Findings record (if red) | Docs (`220-FINDINGS.md`, `PROJECT.md`) | — | Not code; a decision record |

## Package Legitimacy Audit

Not applicable. This phase adds no new Hex/npm/cargo dependencies — it adds a CI matrix row and
fixes existing source warnings. No `mix.lock` change is in scope (explicitly out of scope per D-11).

## Standard Stack

No new libraries. This phase's only "stack" additions are pinned toolchain versions consumed by
the existing `erlef/setup-beam@v1` action already used elsewhere in `ci.yml`.

### Verified Pins (re-checked 2026-09-28, same day as CONTEXT.md)

| Component | Version | Source | Status |
|-----------|---------|--------|--------|
| Elixir | `1.20.4` | `https://builds.hex.pm/builds/elixir/builds.txt` — entry `v1.20.4-otp-29`, timestamp `2026-08-28T10:07:51Z` | `[VERIFIED: builds.hex.pm/builds/elixir/builds.txt]` — fetched live this session, newest 1.20.x entry, no 1.20.5 present |
| OTP | `29.1.1` | `https://builds.hex.pm/builds/otp/ubuntu-24.04/builds.txt` — entry `OTP-29.1.1`, timestamp `2026-09-22T08:11:48Z`, next-newest `OTP-29.1` at `2026-09-16` | `[VERIFIED: builds.hex.pm/builds/otp/ubuntu-24.04/builds.txt]` — fetched live this session, ubuntu-24.04 prebuilt exists |
| PostgreSQL | `18.6` | PostgreSQL release notes (18.6 released 2026-08-13); Docker Hub `postgres:18.6-trixie` tag pushed ~2026-09-24 | `[CITED: postgresql.org/docs/release/18.6, hub.docker.com/_/postgres]` — image tag confirmed to exist; 18.5 was never released (no such Docker tag), matching D-01's claim |
| Runner | `ubuntu-24.04` | Already the runner for every other `ci.yml` job (`verify-format`, `verify-credo`, `verify-test` min/current rows, `ci-required`, etc.) | `[VERIFIED: .github/workflows/ci.yml]` — read live this session |

**No action needed on pins.** CONTEXT.md's D-01 instruction to re-check at execution time still
applies — a patch could ship between now and when the plan executes — but as of this research pass,
same-day re-verification found no drift.

### Installation

No `mix.exs`/`mix.lock` change. The only "installation" is CI YAML: a third `include` row in the
`verify-test` matrix (D-03) and local toolchain installation for the pre-spike (D-09), via `asdf
install elixir 1.20.4-otp-29` / `asdf install erlang 29.1.1` or equivalent.

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────────────────────┐
                    │  ci.yml : verify-test job                │
                    │  matrix.lane = [min, current, latest]    │
                    └─────────────────┬─────────────────────────┘
                                       │ (include row per lane)
        ┌──────────────────┬──────────┴──────────┬──────────────────┐
        │  lane: min         │  lane: current       │  lane: latest     │
        │  1.15.8/26.2.5.21  │  version-file:        │  1.20.4/29.1.1    │
        │  pg14, explicit     │   .tool-versions      │  pg18.6, explicit │
        │  pins                │  (1.17.3/27.3.4.15)   │  pins              │
        │                     │  pg16                 │                    │
        └────────┬────────────┴──────────┬────────────┴─────────┬──────────┘
                 │                        │                       │
        compile --warnings-as-errors, verify.xref_cycles, verify.test (all 3 lanes)
                 │                        │                       │
                 │           current-only: verify.threadline, example app, verify.example
                 │                        │                       │
                 └────────────────────────┴───────────────────────┘
                                       │
                              ci-required (needs: all jobs incl. verify-test)
                                       │
                         alls-green → single required status check
```

Data flow for the contract-enforcement side (parallel, not sequential):

```
ci.yml (source of truth)
   │
   ├─► ci_workflow_parity_contract_test.exs
   │       ├─ roster tests (3 rows, keys [min,current,latest])
   │       ├─ latest_row_errors/2 (shape/ordering, not literal values)
   │       ├─ no-continue-on-error scan (fail-closed, every job votes)
   │       └─ no-beta-postgres allowlist scan (^\d+(\.\d+)?$ on every postgres:<tag>)
   │
   └─► CONTRIBUTING.md / README.md / mix.exs doc-contract assertions
           (same-commit doc surfaces, D-17)
```

### Recommended Project Structure

No new directories. Changes land in:
```
.github/workflows/ci.yml                                  # D-03 latest row, D-06 cache comment
test/threadline/ci_workflow_parity_contract_test.exs       # D-13/D-14/D-15/D-16
CONTRIBUTING.md                                             # D-17
README.md                                                    # D-17 (support-statement wording only)
mix.exs                                                       # D-17 (comment only)
lib/mix/tasks/threadline.incident.ex                          # D-08.1
test/support/migration_harness.ex                             # D-08.2
lib/threadline/critic_trust/ledger_splice.ex                  # D-08.3
lib/threadline/operator_surface/live/export_status_live/components.ex  # D-08.4
lib/threadline/operator_surface/live/evidence_live.ex          # D-08.5
lib/threadline/operator_surface/live/actor_live.ex              # D-08.6
.planning/phases/220-newest-toolchain-lane/220-FINDINGS.md      # only if "not yet" (D-12)
.planning/PROJECT.md                                             # one-line Key Decisions row (D-12, if red)
.planning/MILESTONE-GUIDE.txt                                    # D-18 checklist line
```

### Pattern 1: Construction A — base-axis-only check-name composition
**What:** Only keys declared directly on the `lane` matrix axis (not via `include`-only keys)
append to the GitHub-posted check name. `include` rows carrying `elixir`/`otp`/`pg`/`runner` do not
change the name.
**When to use:** Adding a fourth (or nth) lane to `verify-test` without touching branch protection.
**Example (verified live in `ci.yml:314-329`):**
```yaml
# Source: .github/workflows/ci.yml (read live 2026-09-28)
name: Run test suite
strategy:
  fail-fast: false
  matrix:
    lane: [min, current]          # → becomes [min, current, latest] per D-03
    include:
      - lane: min
        elixir: "1.15.8"
        otp: "26.2.5.21"
        pg: "14"
        runner: "ubuntu-24.04"
      - lane: current
        version-file: ".tool-versions"
        pg: "16"
        runner: "ubuntu-24.04"
      # + lane: latest row per D-01/D-03, explicit pins, no version-file
```
This yields "Run test suite (min)", "Run test suite (current)", and after this phase "Run test
suite (latest)" — three independently-required sub-checks under the single `verify-test` job key,
none of which need a branch-protection edit because `ci-required`'s `needs: [..., verify-test, ...]`
(confirmed live at `ci.yml:1071-1087`) already covers the whole matrix.

### Pattern 2: Exactly-one-toolchain-source invariant
**What:** Each matrix row sets either `version-file` or explicit `otp`/`elixir` pins, never both —
`erlef/setup-beam` errors if both are present, and an absent matrix key renders as an empty-string
input (also an error).
**When to use:** Adding any new `verify-test` row.
**Verified:** The existing `verify_test_matrix_errors/2` function in the contract test
(`test/threadline/ci_workflow_parity_contract_test.exs:1300`) already asserts `file? == pins?` is an
error for every row — this generalizes cleanly to three rows; D-14's `latest_row_errors/2` should
follow the same `source_errors` shape already present for `min`/`current`.

### Anti-Patterns to Avoid
- **Digest-pinning the new PostgreSQL image:** D-02 explicitly rejects this — the other rows use
  bare version tags (`"14"`, `"16"`), and the new row should match that style (`"18.6"`) for
  consistency, accepting that Docker can silently rebuild the same tag on Debian base updates.
- **Widening `verify.test` to `--warnings-as-errors` on the new lane:** D-05 explicitly keeps
  test-file warnings non-fatal for parity with `min`/`current`. Do not add a stricter test-compile
  step just for `latest`.
- **Adding a `paths:`-filtered or `if:`-conditional latest lane to save cost:** D-07 explicitly
  rejects this for the phase; conditional lanes are Phase 222's job (SEED-006), and a conditional
  lane here would also need `allowed-skips` wiring in `ci-required` (confirmed at `ci.yml:1097-1101`
  — the comment there documents this exact tripwire for the *next* conditionally-skipped job).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Toolchain install/pin verification in CI | A custom version-check script | `erlef/setup-beam@v1` with `version-type: strict` (already used by every other job) | Strict mode already fails hard on a non-existent build tag; no new tooling needed |
| Detecting stale pins over time | A scheduled drift-checker workflow | D-18's MILESTONE-GUIDE checklist line (process, not automation) | CONTEXT.md's deferred-ideas section explicitly defers `deps-health.yml`-style automation for this to a future phase; building it now is scope creep |
| "Which failures count against the toolchain" logic | A bespoke classifier | D-11's explicit rules (dependency-only warnings don't count; anything needing version-conditional code doesn't count; only 2 spike dispatches + 1 flake re-dispatch) | Already fully specified; this is a judgment call for whoever writes the findings, not code |

**Key insight:** This phase's "don't hand-roll" list is short because it is CI-configuration work,
not new application logic — the risk is *process* drift (re-verifying pins, correctly classifying a
spike failure), not missing libraries.

## Runtime State Inventory

Not applicable — this is not a rename/refactor/migration phase. No stored data, live service
config, OS-registered state, secrets, or build artifacts carry the old/new toolchain name as an
identifier; a CI matrix row is declarative config with no persisted runtime state of its own.

## Common Pitfalls

### Pitfall 1: Believing D-08's "6 known warnings" list is exhaustive
**What goes wrong:** The pre-spike (D-09) compile on 1.20.4/29.1.1 (a newer patch than the
researcher used, 1.20.2/29.0.5) surfaces a 7th warning not in the D-08 list.
**Why it happens:** OTP 29.1 or Elixir 1.20.3/1.20.4 shipped after the original researcher's local
compile; new deprecations or stricter checks can appear between patches.
**How to avoid:** Treat D-09 (the local pre-spike, run on the exact D-01 pins if installable) as the
authoritative warning surface, not the D-08 list. If a 7th warning appears, fix it under the same
"dead code / cleanup, no behaviour change" bar D-08 sets, and note the addition in the findings if
the phase produces one.
**Warning signs:** `mix compile --warnings-as-errors` fails locally in the pre-spike after the D-08
fixes are applied.

### Pitfall 2: Mistaking `min_row_errors`'s literal-value pattern for `latest_row_errors`
**What goes wrong:** Writing `latest_row_errors/2` to assert exact literal pins (`otp: "29.1.1"`,
`elixir: "1.20.4"`), the way `min_row_errors/2` asserts the exact floor build.
**Why it happens:** `min_row_errors` (confirmed live at `ci_workflow_parity_contract_test.exs:1329`)
is the closest template in the file, and it does hard-code literal values, because the floor is a
support promise. Copy-pasting that pattern for `latest` is the natural first instinct.
**How to avoid:** D-14 is explicit: latest's pins are checked for **shape and ordering** (regex
format, "strictly newer than current"), not exact values — because the newest-lane pin moves every
re-pin cycle (D-18) and is not a support promise. Follow `current_row_errors/1`'s looser pattern
(confirmed live at line 1349) more than `min_row_errors`'s literal pattern.

### Pitfall 3: Treating a green pre-spike as sufficient to skip the CI dispatch
**What goes wrong:** The local pre-spike (D-09) passes, so the plan skips the paid `gh workflow run
ci.yml --ref spike/220-latest` dispatch and declares the lane green from local-only evidence.
**Why it happens:** The local run is the expensive, novel part; the CI dispatch can feel like
redundant confirmation.
**How to avoid:** D-10/D-11 require the *CI-run* evidence (run ID cited) as what "green" means —
local Docker/asdf environments can diverge from `ubuntu-24.04` GitHub runners (different glibc,
different `postgres:18.6` image pull, different CPU/timing for flakes). The success criteria
explicitly require "a dispatch spike run, cited by run ID."

### Pitfall 4: Assuming PostgreSQL 18's AFTER-trigger role-execution change affects capture
**What goes wrong:** Spending plan/execution time investigating whether Threadline's capture
triggers need updating for PG 18's "AFTER triggers execute as the role active at queue time, not
commit time" change.
**Why it happens:** The CONTEXT.md "specifics" section flagged this as unverified and asked the
phase researcher to check it — a reasonable caution, since role-context bugs are exactly the kind of
subtle capture-layer issue this project cares about.
**How to avoid:** This research session resolved the flag: `[VERIFIED: lib/threadline/capture/trigger_sql.ex — read live, grep for CURRENT_USER/SESSION_USER/role returned no matches]`. The
generated trigger SQL does not read `current_user`/`session_user` at all — actor attribution flows
through the semantics layer (`AuditContext`/`ActorRef`), not through the PostgreSQL role executing
the trigger. The change is real (`[CITED: postgresql.org/docs/release-18.html]` — "Execute AFTER
triggers as the role that was active when trigger events were queued... Previously such triggers
were run as the role that was active at trigger execution time") but inert for this codebase. No
task is needed to address it; the planner should not add one.

### Pitfall 5: Assuming PG 18's default-virtual generated columns affect `to_jsonb(NEW)` capture
**What goes wrong:** Investigating whether any audited table's generated columns change behavior
under PG 18's new default of `GENERATED ALWAYS AS (...) VIRTUAL` (vs. the pre-18 default `STORED`).
**Why it happens:** Same CONTEXT.md "specifics" flag, same reasonable caution — virtual generated
columns are not stored, so `to_jsonb(NEW)` inside a trigger would not see their value pre-18-style.
**How to avoid:** `[VERIFIED: repo-wide grep for "GENERATED ALWAYS AS" and ":generated" across lib/, priv/, test/, excluding deps/]` — no generated columns exist anywhere in Threadline's own schema,
migrations, or test fixtures (the only hits were inside `deps/ecto_sql` and one unrelated docstring
mention of "generated migration" in `lib/mix/tasks/threadline.install.ex`). This pitfall does not
apply; no task is needed.

## Code Examples

### The `latest_row_errors/2` template to extend (verified live)
```elixir
# Source: test/threadline/ci_workflow_parity_contract_test.exs:1327-1349 (read live 2026-09-28)
defp min_row_errors(nil, _floor), do: ["verify-test has no min row"]

defp min_row_errors(row, floor) do
  # ... asserts literal elixir/otp pins match `floor`, runner is ubuntu-24.04,
  # pg is "14", no version-file key present ...
end

defp current_row_errors(nil), do: ["verify-test has no current row"]

defp current_row_errors(row) do
  # ... asserts version-file key present, no otp/elixir pins, pg is "16" ...
end
```
D-14's `latest_row_errors/2` should sit alongside these, fed `.tool-versions` text (to compare
against for "strictly newer than current") the same way `min_row_errors/2` is fed the `mix.exs`
floor via `elixir_floor(mix_exs)`.

### The count/roster assertion to extend from 2 to 3 rows
```elixir
# Source: test/threadline/ci_workflow_parity_contract_test.exs:1300-1324 (read live 2026-09-28)
defp verify_test_matrix_errors(yaml, mix_exs) do
  rows = verify_test_rows(workflow_job(yaml, "verify-test"))
  by_lane = Map.new(rows, &{&1["lane"], &1})

  count_errors =
    if length(rows) == 2 and Map.keys(by_lane) |> Enum.sort() == ["current", "min"],
      do: [],
      else: [
        "verify-test must have exactly two include rows (min, current), found " <>
          inspect(Enum.map(rows, & &1["lane"]))
      ]
  # ... becomes length(rows) == 3, keys ["current", "latest", "min"] per D-13
end
```

### The no-`:latest`-tag ban this phase must not collide with
```elixir
# Source: test/threadline/ci_workflow_parity_contract_test.exs:204-211 (read live 2026-09-28)
describe "workflow image pinning" do
  test "no workflow file pins a service image to the mutable :latest tag" do
    for path <- workflow_files() do
      refute String.contains?(File.read!(path), ":latest"),
             "#{Path.relative_to(path, @repo_root)} must not pin any image to the " <>
               "rolling :latest tag"
    end
  end
end
```
This is a plain substring check across the whole file, so the matrix key `lane: latest` (a bare
word with no colon before it in that form) does not collide — D-03 explicitly notes the
`lane: latest` spacing must be preserved because this test's substring match is looking for the
literal text `:latest` (colon-latest, as in an image tag `postgres:latest`), which `lane: latest`
does not contain. Confirmed live: the string `lane: latest` (with the space) would not match
`":latest"` as a substring, `lane:latest` (no space) would. Preserve the space.

### `ci-required`'s extension-point comment (why no branch-protection edit is needed)
```yaml
# Source: .github/workflows/ci.yml:1071-1101 (read live 2026-09-28)
ci-required:
  name: CI required
  if: always()
  needs:
    - verify-format
    - verify-credo
    - verify-dialyzer
    - verify-compile-no-optional
    - verify-test          # ← the whole matrix, including the new latest row, already here
    - verify-hex-evaluator
    - verify-example-browser
    - verify-capture
    - verify-pgbouncer-topology
    - verify-release-shape
    - verify-bump-rehearsal
    - verify-deps-audit
    - verify-repo-hygiene
  # Extension point: the first `needs:` job that becomes conditionally
  # skipped (a job-level `if:`) must be listed here via `allowed-skips`,
  # or this gate will correctly fail on its skip. Deliberately absent
  # today — all thirteen jobs above run unconditionally...
```
Since the new `latest` row runs unconditionally (D-07: every run, no `if:`), it needs no
`allowed-skips` entry — confirming D-04's claim.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| 2-lane matrix (`min`, `current`) | 3-lane matrix (`min`, `current`, `latest`) | This phase | +1 voting sub-check, +~6 billed runner-minutes/run per D-07's estimate |
| No proactive newest-toolchain proof | Additive `latest` lane, proven or explicitly "not yet" | This phase | Matches prior-art survey in CONTEXT.md specifics: Phoenix pins exact newest and votes; Oban/Req float and go red on new releases; Ecto/Broadway lag. Threadline adopts the strict voting-pin pattern. |

**Deprecated/outdated:** Nothing in this phase deprecates prior lanes — `min` and `current` are
explicitly unchanged (D-per PROJECT.md Out of Scope, confirmed at REQUIREMENTS.md "Out of Scope"
table: "Raise the Elixir 1.15 / PG 14 floor" is a v1.45 decision, not this phase's).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The +~6 billed-runner-minute cost estimate (D-07) is accurate for the actual `latest` lane once it runs | Standard Stack / Spend | Low — CONTEXT.md already frames this as "an inference to be confirmed, not asserted" and offers optional 219-tooling reuse to measure it from real spike runs (Claude's Discretion). If materially higher, it's still reversible (Phase 222 trims it) and does not block LANE-01. |
| A2 | No Elixir 1.20 / OTP 29 warning beyond the D-08 list of 6 will surface on the exact 1.20.4/29.1.1 pins (vs. the researcher's 1.20.2/29.0.5 local compile) | Common Pitfalls #1 | Medium — a 7th warning would need a 7th fix before the spike can go green; handled by treating D-09's local pre-spike as authoritative, not by skipping it. |
| A3 | `postgres:18.6` (bare tag, no `-trixie` suffix) resolves to the same image as `postgres:18.6-trixie` and is what D-02 intends | Standard Stack / Verified Pins | Low — Docker Hub's bare-version tags for `postgres` are the default-OS-variant alias; consistent with how `min`/`current` rows already use bare `"14"`/`"16"` tags. Executor should confirm `docker pull postgres:18.6` resolves before the paid CI dispatch, as part of D-09's local pre-spike. |

**If this table is empty:** N/A — see above. All three assumptions are low-to-medium risk and
already have mitigations built into CONTEXT.md's own decision structure (D-09 pre-spike, D-11
flake-retry allowance, Phase 222 cost-trim reversibility).

## Open Questions

None remaining. The one open research flag CONTEXT.md's "specifics" section named — the PG 18
AFTER-trigger role-execution change and its interaction with generated columns — was investigated
and resolved this session (see Common Pitfalls #4 and #5): both are inert for Threadline's capture
layer and require no plan task.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| asdf (or mise) Elixir/OTP install | D-09 local pre-spike | Not probed this session — D-09 states asdf `elixir 1.20.2-otp-29` / `erlang 29.0.5` are already installed locally | 1.20.2-otp-29 / 29.0.5 installed; 1.20.4/29.1.1 not yet confirmed installed | D-09/Claude's Discretion: run pre-spike on the installed 1.20.2/29.0.5 and state which versions ran, if 1.20.4/29.1.1 install is infeasible |
| Docker | D-09 local `postgres:18.6` container | Docker 29.5.2 installed per D-09; PG18 image not yet pulled | 29.5.2 | None needed — pulling `postgres:18.6` is a plan task, not a missing dependency |
| `gh` CLI / GitHub Actions dispatch access | D-10 spike dispatch | Assumed available (used throughout prior phases, e.g. 218/219 landings) | — | Push/dispatch is explicitly gated behind a maintainer grant (D-10), not a tooling availability question |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** Exact 1.20.4/29.1.1 local install — D-09 explicitly allows
running the pre-spike on whatever is installed and recording the actual versions used, with the
paid CI dispatch (which does install the exact D-01 pins via `erlef/setup-beam` strict mode)
remaining the authoritative "green" evidence regardless of what the local pre-spike used.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir's built-in), plus GitHub Actions workflow-YAML contract tests via `Elixir.YamlElixir` parsing |
| Config file | `test/test_helper.exs` (suite config); no separate config for the CI contract tests — they are ordinary ExUnit tests in `test/threadline/` |
| Quick run command | `mix test test/threadline/ci_workflow_parity_contract_test.exs` |
| Full suite command | `mix verify.test` (current lane), `mix test` (default suite, matches min/current/latest lane payload per D-05) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| LANE-01 (roster) | `verify-test` matrix has exactly 3 rows, keys `[min, current, latest]` | contract/unit | `mix test test/threadline/ci_workflow_parity_contract_test.exs --only line:244` (roster regex) and the count-check around line 1300 | Extend existing test at `ci_workflow_parity_contract_test.exs:244` and `:1300-1309` |
| LANE-01 (pin shape) | `latest` row pins are shape/ordering-valid and strictly newer than `current` | contract/unit | New `latest_row_errors/2`, exercised via `verify_test_matrix_errors(yaml, mix_exs) == []` plus its 5 mutation controls | New — D-14 |
| LANE-01 (fail-closed: no continue-on-error) | No voting lane uses `continue-on-error`; `ci-required.needs` == every job | contract/unit | New test asserting `needs` set equality + comment-stripped scan for `continue-on-error`/`allowed-failures` | New — D-15, 5 controls listed |
| LANE-01 (fail-closed: no beta PG) | Every `postgres:<tag>` across all workflow files + `docker-compose.yml` matches `^\d+(\.\d+)?$` | contract/unit | New allowlist scan resolving `${{ matrix.pg }}` through parsed `include` rows | New — D-16, 3 controls listed |
| LANE-01 (green/red outcome) | Suite compiles and passes on the exact pins under `--warnings-as-errors` | integration/CI dispatch | `gh workflow run ci.yml --ref spike/220-latest`, cited run ID | Not a local test — a live dispatch is the evidence source (D-10/D-11) |
| D-08 (warning fixes) | Each of the 6 named files compiles clean under `--warnings-as-errors` on 1.20.x/29.x, and stays green on the 1.15.8/26.2.5.21 min lane | unit/compile | `mix compile --warnings-as-errors` (locally on both toolchains, and via the min-lane job in the same CI run) | Existing compile step, no new test file needed |
| D-17 (doc parity) | CONTRIBUTING/README/mix.exs doc surfaces mention "Run test suite (latest)" / updated cache table / support-statement wording | contract/unit | Existing pattern: `String.contains?(doc, "Run test suite (min)")`-style assertions at `ci_workflow_parity_contract_test.exs:373-378`, extended for "(latest)" | Extend existing test |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/ci_workflow_parity_contract_test.exs` (fast, no DB/network) plus `mix compile --warnings-as-errors` for any `lib/` fix
- **Per wave merge:** `mix verify.test` (full current-lane payload) locally, before the D-10 push
- **Phase gate:** the cited CI dispatch run on `spike/220-latest` must show min, current, AND latest all green in the same run (D-11's definition of "what green means")

### Wave 0 Gaps
None — `test/threadline/ci_workflow_parity_contract_test.exs` already exists with the exact
`min_row_errors`/`current_row_errors`/`verify_test_matrix_errors` scaffolding to extend; no new test
file or shared fixture is needed, only new `describe`/test blocks and helper functions inside the
existing file.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|----------------|---------|-------------------|
| V2 Authentication | No | This phase touches CI config and dead-code cleanup only; no auth surface |
| V3 Session Management | No | N/A |
| V4 Access Control | No | N/A |
| V5 Input Validation | No | N/A (no user input path touched) |
| V6 Cryptography | No | N/A |
| V14 Configuration | Yes | CI-pipeline hardening pattern: fail-closed allowlists over denylists (D-15/D-16), immutable job IDs, single required status check — all already-established repo conventions this phase extends, not introduces |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| A future contributor adds `continue-on-error: true` to a new voting lane to "unblock" a flaky new toolchain, silently making it non-blocking | Tampering (of the CI trust guarantee) | D-15's fail-closed `continue-on-error` scan across every job, including matrix-expression forms — already the pattern for existing lanes, extended here |
| A future contributor points the new lane at a beta/dev PostgreSQL image (e.g. `postgres:19beta1`) to "get ahead" of the next major | Tampering / supply-chain drift | D-16's allowlist regex (`^\d+(\.\d+)?$`) rejects anything not a clean release version, including `beta`, `rc`, `devel`, `nightly`, `latest` |
| Branch-protection scope creep: someone adds the new check name directly to `.github/rulesets/main.json` instead of relying on the `ci-required` aggregator | Tampering (bypassable via the aggregator staying stale) | D-04 explicitly forbids this edit; `bin/verify-branch-protection` already asserts exactly one required context (`CI required`) |

## Sources

### Primary (HIGH confidence)
- `https://builds.hex.pm/builds/elixir/builds.txt` — fetched live 2026-09-28, confirms `v1.20.4-otp-29` is the newest 1.20.x build
- `https://builds.hex.pm/builds/otp/ubuntu-24.04/builds.txt` — fetched live 2026-09-28, confirms `OTP-29.1.1` (2026-09-22) is the newest OTP 29.x ubuntu-24.04 prebuilt
- `.github/workflows/ci.yml` — read live this session, lines 1-500 and 1071-1101
- `test/threadline/ci_workflow_parity_contract_test.exs` — read live this session, lines 195-390 and 1290-1350
- `CONTRIBUTING.md`, `README.md`, `mix.exs` — read live this session at all D-17-cited line ranges
- `lib/threadline/critic_trust/ledger_splice.ex:79-89`, `lib/mix/tasks/threadline.incident.ex:38`, `test/support/migration_harness.ex:16`, `lib/threadline/operator_surface/live/export_status_live/components.ex:165-175`, `lib/threadline/operator_surface/live/evidence_live.ex:430-445`, `lib/threadline/operator_surface/live/actor_live.ex:225-240` — read live this session, confirming all 6 D-08 warning locations
- `lib/threadline/capture/trigger_sql.ex` — grepped live this session for `CURRENT_USER`/`SESSION_USER`/`role`, zero matches, resolving the PG-18-role-change research flag

### Secondary (MEDIUM confidence)
- PostgreSQL 18 release notes (`https://www.postgresql.org/docs/release-18.html` / `release/18.6/`) — confirms the AFTER-trigger role-execution change via web search summary, not a direct fetch of the release-notes page itself this session
- Docker Hub `postgres` tags page — confirms `postgres:18.6-trixie` tag existence via web search summary, not a direct Docker Hub fetch

### Tertiary (LOW confidence)
- None used for load-bearing claims in this document.

## Metadata

**Confidence breakdown:**
- Standard stack / pins: HIGH — re-verified live against builds.hex.pm same-day as CONTEXT.md, zero drift found
- Architecture / contract-test extension points: HIGH — every cited line read live this session, matches CONTEXT.md's claims (a few line numbers shifted by single digits from file growth, noted as approximate in CONTEXT.md itself)
- PG 18 role/generated-column research flag: HIGH — both claims independently verified/refuted against release notes and live repo grep
- Cost estimate (D-07, +~6 billed runner-min): MEDIUM — inherited from CONTEXT.md's own researcher estimate, not independently re-measured this session (flagged as Assumption A1)

**Research date:** 2026-09-28
**Valid until:** Pins should be re-verified at plan/execute time per D-01 (fast-moving — Elixir/OTP/PG patches ship roughly monthly); the architectural/contract-test findings are stable for the life of this phase (no external dependency).
