# AGENTS.md

This file provides guidance to Codex and other coding agents when working in this repository.

## What is Threadline

Threadline is an open-source audit trail library for Elixir teams using Phoenix, Ecto, and PostgreSQL. It combines trigger-backed row-change capture, rich action semantics (actor/intent/context), and operator-grade exploration. The Hex package name is `threadline`.

## Architecture — Three Layers

The codebase is organized around three separate layers. Do not conflate their responsibilities:

- **Capture layer** — canonical persistence of row mutations via PostgreSQL triggers. Owns audit transactions, change records, trigger registration, and integrity. Does not own action naming, UI grouping, or retention policy.
- **Semantics layer** — application-level action events binding actor, intent, correlation IDs, request/job provenance, and reason. Actions are not changes; transactions are not requests; users are not always the actor.
- **Exploration/operations layer** — timelines, diffs, filters, as-of queries, exports, health checks, retention, redaction, coverage, and telemetry. This layer matures after capture + semantics prove out.

See `prompts/audit-lib-domain-model-reference.md` for the full domain model, entity definitions, and bounded contexts.

## Domain Language

Use these terms consistently in code, docs, and APIs:

- **AuditTransaction** — groups row changes from one DB transaction (not the same as a request or action)
- **AuditChange** — one row mutation in one audited table
- **AuditAction** — a semantic application-level event (e.g. `member.role_changed`)
- **AuditContext** — execution context (request, job, correlation, route, IP, auth)
- **ActorRef** — stable reference to who did it (user, admin, service account, job, system, anonymous)
- **Correlation** — ties related records across request/job/integration boundaries

## Build & Development Commands

```bash
# Dependencies
mix deps.get

# Compile
mix compile --warnings-as-errors

# Tests
mix test                    # full suite
mix test test/path_test.exs # single file
mix test test/path_test.exs:42  # single test by line

# Formatting & linting
mix format
mix format --check-formatted
mix credo --strict          # if adopted

# Verification entrypoints (canonical — cite these in CI and docs)
mix verify.format
mix verify.credo
mix verify.test
mix ci.all                  # runs all verification steps
```

## CI & Verification Conventions

Launch automated apps and tests in the background by default so the maintainer can
keep using the shared computer. Use managed sessions that retain logs and the real
exit status. Use foreground only when a specific check requires it; explain the
need before activation and bound that interval. Diagnose background
failures within existing limits. A timeout alone does not justify taking focus.

These come from the project's OSS DNA (`prompts/threadline-elixir-oss-dna.md`):

- **Named entrypoints**: prefer `mix verify.*` / `mix ci.*` aliases over ad-hoc commands. Contributors and CI cite these verbatim.
- **Honest default tests**: never silently exclude heavy suites from `mix test` without updating `test/test_helper.exs` and docs together.
- **Stable CI job IDs**: keep job `id:` fields immutable in GitHub Actions workflows. Evolve `name:` freely.
- **Path filters + main**: expensive jobs still run on `main` even when PRs are path-filtered.
- **Doc contract tests**: README, guides, and example app README stay aligned via test assertions.

## Key Design Constraints

- Correct by default — harder to miss capture than to enable it.
- SQL-native — operators query audit data with plain SQL, no opaque blobs.
- Composable — idiomatic Plug, Phoenix, Ecto, Oban, and LiveView integration.
- Capture uses generated PostgreSQL triggers installed through host-owned Ecto
  migrations; preserve that trigger-backed boundary unless a future public API
  decision explicitly changes it.
- Not a SIEM, not event sourcing, not a pgAudit replacement, not a data warehouse product.

## GSD / local planning

Tracked planning artifacts use repository-relative links. Machine-local file links
belong in chat, not in committed documents.

**Zero human verification by default.** Automate UAT and verification (tests, CI
gates where they keep paying off, and agent review for judgment calls such as prose
clarity). Hand the maintainer only secrets, spend, push/publish, and scope decisions.
Full rule: `.planning/PROJECT.md` → Constraints → "Zero human verification by default".

**Research, then recommend — never a blind option menu.** Any GSD step that would
offer architectural, API, UX, scope or dependency options (discuss-phase included)
first fans out parallel researchers, one per decision cluster. Each covers pros/cons,
idiomatic Elixir/Plug/Ecto/Phoenix practice, prior art and footguns from peer libraries
(cross-language where instructive), DX and least surprise, and the expert lenses
(architecture, SRE, security, semver). Each reads `prompts/` and names the sibling
decisions it must cohere with. Also enumerate angles the roadmap did not name, up to
the point of diminishing returns. Return ONE coherent recommendation set with a single
confirm. Ask the maintainer only about major architect-level decisions where research
found no clear winner. Research depth does not follow the advisor calibration tier.

**Research and delivery policy.** Before milestone scoping, phase discussion,
verification, CI or release/CD work, read
`.planning/conventions/research-verification-and-efficiency.md`. It records the
maintainer's relevant-role fan-out to diminishing returns, adversarial synthesis,
small/flat dependency preference, useful automated verification and measured CI/CD
efficiency defaults. Reuse accepted decisions and evidence without reopening them
unless a relevant change or defect justifies it.

**Milestone guide.** Before choosing or closing a milestone, read `.planning/MILESTONE-GUIDE.txt`
(intent, lenses, selection loop, quality/CI/release bar, roadmap ladder to 1.0.0) with
`.planning/MILESTONE-ARC.md`. Operator-UI design work is parked until 1.0.0.

**`state.begin-phase` argument style depends on which tool is on PATH — check first.**
- `@opengsd/gsd-core` v1.14.0 (`gsd-tools.cjs`, current): requires **flags** —
  `--phase 202 --name "Release 0.10.0" --plans 5`. Positional args are rejected
  (`Error: unexpected positional argument`). Verified 2026-09-22; STATE.md diffed
  afterwards, no corruption.
- Older `gsd-sdk` wrapper: requires **positional** args (`phase`, `slug`, `plan_count`);
  flag-style invocations there can corrupt `.planning/STATE.md`.

Separately, and regardless of invocation style: the `state.*` handlers miscompute this
repo's bespoke progress block. Hand-check `.planning/STATE.md` and `ROADMAP.md` after
calling them.

## Brand and Admin direction (2026-11-10)

Before branding, documentation or Admin UI work, read `brand/BRAND.md`,
`brand/brand.json` and `brand/assets/README.md`. The maintainer signed off this
v1.0 identity on 2026-11-10; its edition date is 2026-11-03. It supersedes the
old identity in `brandbook/` and `prompts/Threadline Brand Book.txt`. The approved `brand/` source is now imported into this current-main milestone
checkout; keep it authoritative through the deliberate runtime/package migration. Inspect
`test/threadline/brandbook_token_parity_test.exs` before migrating assets/tokens.
Preserve old references until package, docs, components and tests migrate together.

Design the new Admin around user jobs and complete flows, with catalog coverage
from primitives through components, page states and journeys. Use PhoenixStorybook
in the example/dev/test boundary for now; apply Fablebook principles without
adopting its unfinished library. Use deterministic, realistic adoption scenarios
with meaningful happy, error and boundary states, connected to executable tests.
Keep user-facing vocabulary distinct from compatible public module/API/route names.
The signed-off identity does not by itself authorize new white-label or login APIs.
Map actual jobs/routes/states before broad rebuilding, then validate one ordinary
whole-task slice using shared production components. Keep normal fictional business
data separate from stress cases. Use bounded batches and matched before/after
captures with behavior/accessibility proof; preserve Threadline's automated
verification policy. Detailed transfer findings are in
`.planning/research/2026-11-10-brand-admin/README.md`.
Accrue's brand/UI refresh is work in progress. Treat its lessons as comparison
evidence and hypotheses to evaluate against Threadline, not as authority or a
blueprint. Distinguish owner feedback, implemented safeguards, design proposals
and unresolved findings before transferring a lesson.

PhoenixStorybook and Phoenix LiveView/HEEx are the approved implementation for
this milestone, not React. Revisit migration to Fablebook only when it is ready
and a deliberate adoption decision is made; do not build a speculative adapter.

## Reference Documents

- `prompts/audit-lib-domain-model-reference.md` — full domain model, entities, bounded contexts, API shapes
- `prompts/threadline-elixir-oss-dna.md` — engineering habits and quality bar from sibling projects
- `prompts/THREADLINE-GSD-IDEA.md` — project vision, constraints, and first milestone intent
- `brand/BRAND.md` and `brand/brand.json` — current approved identity and voice
- `prompts/Threadline Brand Book.txt` — historical identity; superseded by `brand/`
- `prompts/prior-art/` — ecosystem research (Elixir/Phoenix/Ecto best practices, auth domain, CI/CD patterns)
