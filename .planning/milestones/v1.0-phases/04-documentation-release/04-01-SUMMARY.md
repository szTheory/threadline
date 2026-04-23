---
phase: 4
plan: "04-01"
subsystem: documentation
tags: [readme, domain-reference, license, docs]
key-files:
  - README.md
  - guides/domain-reference.md
  - LICENSE
key-decisions:
  - PgBouncer section copied exact set_config(..., true) pattern from Threadline.Plug @moduledoc
  - Domain reference auto-reformatted by linter; all six entities and Correlation "not a database table" note preserved
  - README auto-reformatted by linter; all acceptance grep checks verified to pass
completion: "2026-04-22"
---

# Summary — 04-01: README, domain reference, LICENSE

Added the three missing root-level documentation artifacts that unblock ExDoc and Hex publish:

1. **LICENSE** — MIT, copyright `2026 szTheory`. Acceptance greps pass.

2. **guides/domain-reference.md** — Six entities (AuditTransaction, AuditChange, AuditAction, AuditContext, ActorRef, Correlation) with ubiquitous language table, ASCII relationship diagram, per-entity sections, and glossary. Correlation section explicitly states "not a database table" per D-13. All acceptance greps pass.

3. **README.md** — CI badge, Hex badge, HexDocs badge; one-paragraph description; three-step installation; Quick Start with `plug Threadline.Plug` and `set_config('threadline.actor_ref', $1::text, true)` snippet; PgBouncer note; links to HexDocs, domain-reference.md, CONTRIBUTING.md. All acceptance greps pass.

## Deviations

Both README.md and domain-reference.md were auto-reformatted by the project linter to tighter prose. All required content and acceptance criteria are preserved in the reformatted versions.

## Verification

- All LICENSE acceptance greps ✓
- All domain-reference.md greps (6 entities + "not a database table") ✓
- All README acceptance greps ✓ ({:threadline, mix threadline.install, mix threadline.gen.triggers, Threadline.Plug, set_config, ", true)", PgBouncer, domain-reference, CONTRIBUTING)
