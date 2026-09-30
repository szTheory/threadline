# Deferred Items

- `cd bench && mix compile --warnings-as-errors` fails with `module ExUnitProperties is not loaded and could not be found` at `test/support/naming_generators.ex:8`
  status: acknowledged
  **What:** reproduces identically on the base lock (before the 215-01 bench dependency bump) and after it — confirmed by running the same compile command before and after `mix deps.update ecto ecto_sql decimal postgrex plug`. Not caused by the bench refresh; not chased per plan 215-01's scope prohibition.

- WR-01: any `hex.outdated` failure (network, registry, crash) is classified `outdated`, so the lane stays green
  status: open
  **What:** `bin/deps-health-report:157-169` (pre-215-06 line numbers; `.github/workflows/deps-health.yml:98-99`). `mix hex.outdated` exits 1 both when something is genuinely outdated and on a registry fetch failure or other error; the script treats every non-zero exit as `outdated`, and the fail step exempts `outdated`. An outdated check that never actually ran can be reported as merely informational. Cited: `215-REVIEW.md` WR-01.

- WR-03: the weekly lane accepted a directory with no `mix.lock` and could report it `clean`
  status: mitigated
  **What:** `bin/deps-health-report:114` (pre-215-06). The gate required `mix.exs` and `mix.lock` but the report script checked only `mix.exs`; a deleted/moved lockfile let `deps.get` create a fresh lock and `hex.audit`/`hex.outdated` run against it, reporting `clean` for a lockfile absent from the repo. Mitigated by 215-06's WR-02 fix: `deps.get --check-locked` fails when no `mix.lock` is present (the lock would be created), so a missing lockfile now classifies `unknown` via the same code path as a drifted lock — no dedicated seam or test was added for the missing-file case specifically. Cited: `215-REVIEW.md` WR-03.

- WR-04: ruleset check in the doc contract test is vacuous — it looks for the workflow name, not the job's check-run name
  status: open
  **What:** `test/threadline/deps_health_doc_contract_test.exs:231-236`. Required status-check contexts in `.github/rulesets/main.json` are check-run (job) names; the test asserts against `Dependency Health` (the workflow `name:`), which never appears as a required context, so the test would still pass if the weekly job were made required. Cited: `215-REVIEW.md` WR-04.

- WR-05: the lockfile list in the doc contract is a restated literal, not derived, so a fourth canonical directory would not be caught
  status: open
  **What:** `test/threadline/deps_health_doc_contract_test.exs:41`, `:145-153`. `@lockfiles` is hard-coded to three paths rather than parsed from `CANONICAL_DIRS`; a fourth directory added to both scripts would still pass every existing assertion while CONTRIBUTING.md silently omitted it. Cited: `215-REVIEW.md` WR-05.

- WR-06: gate test "no arguments audits exactly the three canonical directories" does not assert "exactly"
  status: open
  **What:** `test/threadline/deps_audit_gate_test.exs:245-281`. The test checks only indices 0-2 of every-third-pwd and never asserts the total call count (10) or the full call sequence; an extra directory or subcommand would still pass. The root check `String.ends_with?(real_root)` is also weak (`/elsewhere/threadline` would match), and the hex.info-only floor-check assertion at line 136 (`String.trim(log) == "#{root}|hex.info"`) can never be true because `hex.info` runs from the repo ROOT, not the tmp root — it silently reduces to a `String.contains?` check, and nothing refutes `deps.unlock` was never called. Cited: `215-REVIEW.md` WR-06.

- WR-07: the ci-deps issue title is frozen at the first classification and the issue is never closed
  status: open
  **What:** `.github/workflows/deps-health.yml:86-90` (via `bin/upsert-ci-issue`). The issue is created with `--title "Dependency health: <classification>"` and only commented on thereafter; a title set from an early `outdated` run keeps signalling "informational" even after a later `advisory` run. A clean run also never closes an open `ci-deps` issue. Cited: `215-REVIEW.md` WR-07.

- WR-08: the weekly lane has no Hex version floor
  status: open
  **What:** `bin/deps-health-report:107-170` (pre-215-06 line numbers). The per-PR gate refuses Hex < 2.5.1 because older clients' `hex.audit` does not report the advisories this repo cares about; the weekly lane runs `hex.audit` with whatever Hex `setup-beam` installed and never checks, so a pinned/cached older Hex on the runner would classify `clean` without having actually checked advisories. Not a one-line change (would need the shared `version_ge` + `hex.info` parse factored out or reused from `bin/verify-deps-audit`) — explicitly out of scope for 215-06 per its plan. Cited: `215-REVIEW.md` WR-08.

- IN-01: a step output is interpolated directly into a `run:` script
  status: open
  **What:** `.github/workflows/deps-health.yml:101`. `${{ steps.report.outputs.classification }}` is expanded directly into shell source rather than passed via `env:` (the upsert step already uses `env: CLASSIFICATION` for the same value). Not attacker-controlled today, but against GitHub's own hardening guidance. Cited: `215-REVIEW.md` IN-01.

- IN-02: `printf | grep -q` under `pipefail` can report a spurious "vacuous red"
  status: open
  **What:** `bin/verify-deps-audit:104-105`, `:133-134` (as of 215-05's commit; not re-checked for line drift after 215-05/215-06 edits). `grep -q` exits on first match; if captured output exceeds the pipe buffer, `printf` receives SIGPIPE and `pipefail` turns the pipeline into status 141, producing a misleading self-test failure message. Output is small today so this has not manifested. Cited: `215-REVIEW.md` IN-02.

- IN-03: tautological or vacuous assertions in the report and doc tests
  status: open
  **What:** `test/threadline/deps_health_report_test.exs:279` (pre-215-06 line number) — `refute after_report == nil` can never fail because the preceding pattern match already raises on absence. `test/threadline/deps_health_doc_contract_test.exs:212-229` — the "deps-health not in ci-required needs" test can never fail either, because `needs:` cannot reference a job in another workflow file. Cited: `215-REVIEW.md` IN-03.

- IN-04: report truncation can leave an unclosed code fence and drops the policy footer
  status: open
  **What:** `bin/deps-health-report:196-201` (pre-215-06 line numbers). `head -c` truncates the assembled body, often mid- ` ``` ` block; the rest of the issue (including the `(truncated)` marker and the CONTRIBUTING.md footer) then renders as code or is lost entirely. Cited: `215-REVIEW.md` IN-04.

- Runtime MIX_EXS / MIX_HOME redirection of the gate
  status: open
  **What:** Observation made during 215-06 planning, not a numbered 215-REVIEW finding. `MIX_EXS` can redirect any per-dir Mix call (in either `bin/verify-deps-audit` or `bin/deps-health-report`) at a different project's `mix.exs` entirely; `MIX_HOME` can point Hex at a different archive/config directory. Workflow files are already contract-scanned for `MIX_HOME` by 215-05's `forbidden_hex_surface/1`, but neither script refuses these variables at runtime the way it refuses `HEX_IGNORE_*` and a global `hex.config` ignore — a workflow-level scan cannot catch a value injected by a runner's own environment rather than committed to a workflow file. Tracked as threat T-215-36.
