# Phase 198: Green Bringup - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-27
**Phase:** 198-green-bringup
**Areas discussed:** Green definition & local env failures, The ≤20-min CI lever, Branch-protection contract shape, Irreversibility guards & triage

**Mode:** User requested parallel subagent research across all four areas, with a single coherent recommendation set spanning software architecture, SWE, DevOps/SRE, and DX lenses, grounded in the `prompts/` research corpus. Four `gsd-advisor-researcher` agents ran concurrently; each read actual repo files and cited `path:line`. UI/UX lens was largely non-applicable (roadmap sets **UI hint: no** for every v1.41 phase); the developer-ergonomics and contributor-experience lenses carried its weight.

---

## Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Green definition & local env failures | Whose green — CI only or fresh local clone; is the search_path issue in scope | ✓ |
| The ≤20-min CI lever | Shard / move to nightly / trim matrix / fail-fast+timeouts / caching | ✓ |
| Branch-protection contract shape | Enumerate matrix lanes vs single aggregate gate; is `min` required | ✓ |
| Irreversibility guards & triage | Critic removal depth, publish-path singleton, credential audit, branch triage | ✓ |

**User's choice:** All four, with deep research first.

---

## Research Findings That Overturned Roadmap Premises

Recorded here because these were *corrections*, not choices. Full detail and evidence in CONTEXT.md `<ground_truth>`.

| Premise | Verdict |
|---|---|
| PR #26 blocked by a phantom check name | **Wrong** — blocked by a genuinely red `Run test suite` |
| `min` lane never ran due to a picker limitation | **Wrong** — the matrix commit was never pushed; `origin/main` runs an older `ci.yml` |
| ~81 local failures are a `search_path` env issue needing `ALTER DATABASE` | **Wrong** — stale local DB predating the storage-schema migration; only **one** deterministic failure exists |
| (new) Pushing `main` may permanently orphan the `Run test suite` required context | **Armed hazard** — static `name:` over a `lane:` matrix |
| (new) Pushing 587 commits fires the parked paid critic lane | **Armed hazard** — `ui-critic.yml` push trigger + path filter |

---

## Green definition & local env failures

| Option | Description | Selected |
|--------|-------------|----------|
| Config-level search_path fix | `parameters: [search_path: …]` in `config/test.exs` | |
| `Repo.default_options(prefix:)` | Set the prefix globally for tests | |
| Document as environmental prerequisite | Runbook-only fix | |
| Stale-DB tripwire + `mix test.reset` | Fail once, loudly, with the cause and fix; make the DB disposable | ✓ |

**User's choice:** Accepted the researched recommendation.
**Notes:** Both config-level options contradict D-190-12/D-190-16 and would be caught by `storage_schema_prefix_contract_test.exs:31`, which actively refutes `@schema_prefix "threadline"`; `default_options(prefix:)` would additionally relocate `schema_migrations`. Doc-only is the folklore anti-pattern the OSS DNA names. The rotting charter test was classified **obsolete → `git rm`** rather than version-bumped (rots again in 4 weeks) or loosened to a regex (asserts nothing). The formless-page allowlist was found **non-exhaustive** — a newly added page is silently unguarded today — so it is replaced with a self-declaring `@ui_form_policy` attribute over an exhaustive derived roster.

---

## The ≤20-min CI lever

| Option | Description | Selected |
|--------|-------------|----------|
| Shard the Playwright job first | Split across N runners | Fallback only |
| Move browser lanes to nightly entirely | Off the PR trigger | |
| Trim the OS/Elixir/OTP matrix on PRs | Full matrix on main only | |
| Fail-fast + timeouts only | No structural change | Partial |
| Cut project fan-out + max-failures + timeouts + cache keys | Delete the redundant `chromium` project; split PR vs full lane | ✓ |

**User's choice:** Accepted the researched recommendation; separately confirmed the PR browser lane **stays voting**.

**Sub-question — does the reduced PR browser lane vote?**

| Option | Description | Selected |
|--------|-------------|----------|
| PR lane blocks; full lane main+nightly | Reduced lane keeps existing id+name, stays inside `CI required` | ✓ |
| Browser non-voting on PRs (allowed-skips) | Fastest feedback; lane silently non-voting forever | |

**Notes:** Sharding was demoted to a fallback because it pays a `mix compile --force` + `demo.reset` + `demo.seed` preamble *per runner*. The root cause was three unscoped Chromium projects each running all 126 tests (~382 serialized invocations at `workers: 1`), plus zero `timeout-minutes` anywhere in the repo. Trimming the `min` lane was rejected as the exact "quiet downgrade" the OSS DNA forbids — it is the floor promise to Elixir 1.15 adopters. Honesty mechanism attached: a CI Coverage table in CONTRIBUTING guarded by a doc contract test, plus deduplicated nightly issue notification.

---

## Branch-protection contract shape

| Option | Description | Selected |
|--------|-------------|----------|
| Enumerate every matrix lane | Precise, legible; rots on every matrix change | |
| Single aggregate gate (`CI required`) | One durable name; zero protection edits across Phases 199/203/204 | ✓ |

**User's choice:** Accepted the researched recommendation.
**Notes:** Implementation is `re-actors/alls-green` under `if: always()`, **not** the hand-rolled `contains(needs.*.result,'failure')` idiom — a job that `needs:` a failed job is marked *skipped*, and GitHub scores a skipped required check as **passing**. The aggregate has no matrix axis, so the armed `ci.yml:100-106` naming hazard stops mattering for protection. Verification is a committed `bin/verify-branch-protection` script with two halves: contexts match exactly, **and** the name has actually been observed on a real run — the executable form of GREEN-08's "verified after the matrix has reported once." Migration to a committed ruleset, `strict: true` → `false` (rebase churn against 20-min CI), `enforce_admins: false` → active (today protection is theater). Four jobs currently run but are required by nothing.

**Lens disagreement recorded:** the external contributor wants the aggregate (one legible check, no phantom waits); the security-minded maintainer prefers enumeration (each control individually visible) and objects to a release-bot bypass actor; the solo maintainer wants zero protection edits per phase. Resolution: aggregate + committed verification script satisfies contributor and solo maintainer, and pays the security lens back by making `enforce_admins` genuinely active for the first time.

---

## Irreversibility guards & triage

| Option | Description | Selected |
|--------|-------------|----------|
| Strip the critic input, keep a skeleton workflow | Minimal diff | |
| Delete `ui-critic.yml` + archive tag + contract-test guard | Structurally untriggerable, recoverable, honest | ✓ |
| Delete the critic *code* under `e2e/` too | Would break CRITIC-02 recoverability | |

| Option | Description | Selected |
|--------|-------------|----------|
| Keep both publish workflows with a guard condition | | |
| Keep `release.yml`, delete `hex-publish.yml`, assert singleton in `ci_topology_contract_test.exs` | | ✓ |

**Sub-question — `.planning/` disclosure posture:**

| Option | Description | Selected |
|--------|-------------|----------|
| Publish as-is | Scan gates on credentials only; content is not a gate | ✓ |
| One-hour targeted content sweep | Review the 49 dollar-figure files and vendor mentions | |
| Full content review of all 2159 files | Days of work; blocks the milestone spine | |

**Sub-question — archive tag location:**

| Option | Description | Selected |
|--------|-------------|----------|
| Push archive tags to origin | Survives laptop loss | ✓ |
| Keep archive tags local only | Preserves existing convention | |

**Sub-question — phase-166 merge-or-archive timing:**

| Option | Description | Selected |
|--------|-------------|----------|
| In-phase, after the diff artifact, archive-by-default rule | No mid-phase stop | ✓ |
| Stop and ask once the diff exists | Synchronous checkpoint | |

**Notes:** A stripped skeleton workflow *is* the "defaulted off" state GREEN-09 explicitly rejects. The actual billing code is in `e2e/critic/`, never in `lib/` and never in the tarball — so deleting the trigger satisfies "the billing path is absent" while keeping CRITIC-02 cheap to resume. `hex-publish.yml` self-describes as "Legacy fallback" and wins the publish race *by construction*: release-please tags with a PAT, PAT-created tags trigger workflows, so it publishes while `release.yml` is still in its 30-minute CI-green poll. Hex trusted publishing/OIDC is announced but not GA, so `HEX_API_KEY` stays behind a `production-hex` Environment reviewer gate.

A binding **Class A/B/C decision rule for "a secret was found"** was adopted in advance so it is never litigated at push time; Class B (a third party's credential or PII — something that cannot be made inert) is the only class permitted to override the no-history-rewrite constraint, and clicking "allow secret" past push protection is forbidden outright.

The "milestone tags stay local" rationale was found **void** for archive tags: it existed because pushing would publish `.planning/` history, and `.planning/` goes public on `main` in this very phase.

---

## Claude's Discretion

- Exact `timeout-minutes` values within the agreed budget, once p95s are observable
- Whether the shard fallback is needed, judged against measured post-surgery wall clock
- Wording of the stale-DB tripwire and `@ui_form_policy` failure messages
- `198-TRIAGE.md` table formatting (four columns and the zero-exclusions assertion are fixed)
- Plan count (roadmap estimates 5)

## Deferred Ideas

- `.planning/milestone.lock` stale artifact → Phase 199 / DECOUPLE-05
- `@moduledoc false` on the two shipped critic mix tasks → Phase 200 / SURFACE-03
- Example-app `ALTER DATABASE` at `ci.yml:374-375` → register row; blocked by the Tier-A no-recapture constraint
- Two duplicated `~> 0.9.0` doc-contract literals → Phase 202 / RELEASE-02
- Whether "milestone tags stay local" survives → milestone-close decision
- Hex trusted publishing / OIDC migration → when Hex ships it
- `stress_live.ex` page-vs-harness classification → resolve inside the `@ui_form_policy` work
- Snapshot-baseline preflight before deleting the `chromium` project → execution-time check
