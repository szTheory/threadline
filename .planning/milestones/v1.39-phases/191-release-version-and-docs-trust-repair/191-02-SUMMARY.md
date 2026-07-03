---
phase: 191-release-version-and-docs-trust-repair
plan: 02
subsystem: docs-routing
tags: [adopt-03, routing, exdoc, readme, doc-contract, wayfinding]
requires:
  - README.md ## Start here + ## Documentation sections
  - mix.exs ExDoc docs() groups_for_extras
  - test/threadline/release_artifact_contract_test.exs groups-key equality guard
provides:
  - README intent-verb routing table (Evaluate/Adopt/Operate/Contribute)
  - collapsed <details> all-guides index grouped by the four verbs
  - four verb lanes in mix.exs groups_for_extras (sidebar == README labels)
  - test/threadline/persona_routing_doc_contract_test.exs (subset + landing + refute guard)
affects:
  - HexDocs sidebar structure (groups_for_extras)
  - verify.doc_contract alias (new test registered)
  - verify.release groups-key equality (updated in lockstep)
tech-stack:
  added: []
  patterns:
    - "Intent VERB routing (Diataxis reader-intent), not persona nouns"
    - "Option-C medium split: README owns routing prose, ExDoc owns sidebar structure"
    - "Explicit per-lane groups_for_extras regexes (not greedy ^guides/), first-match ordered"
    - "Subset check in new test; exact-equality owned by release_artifact_contract_test"
key-files:
  created:
    - test/threadline/persona_routing_doc_contract_test.exs
  modified:
    - mix.exs
    - README.md
    - test/threadline/release_artifact_contract_test.exs
decisions:
  - "[191-02] Verb lanes (Evaluate/Adopt/Operate/Contribute) label both README ## Start here and the ExDoc sidebar; the two surfaces share the same four labels. The new persona-routing test asserts the subset (four keys present + each README landing); release_artifact_contract_test owns the exact-equality key order [:Overview, :Integrations, :Evaluate, :Adopt, :Operate, :Contribute]."
  - "[191-02] groups_for_extras uses explicit per-file regexes so every one of the 20 extras lands in exactly one lane; Overview + Integrations precede the verb lanes because ExDoc groups by first match (keeps the two integration guides out of a verb lane)."
  - "[191-02] The flat ## Documentation dump is replaced (not deleted) by a collapsed <details> all-guides index grouped by the four verbs; the capture-only/phoenix-surface matrix sentence and the 'Phoenix auth (reference lanes, pick one)' line were relocated into Start here prose, preserving every test-locked literal."
metrics:
  duration: ~14 min
  completed: 2026-07-02
  tasks: 3
  files: 4
status: complete
---

# Phase 191 Plan 02: Persona/Intent Routing Reshape Summary

ADOPT-03 wayfinding over the EXISTING guides: README `## Start here` is now a three-column intent table routing the four intent verbs (Evaluate/Adopt/Operate/Contribute) to their canonical landing + next hop, the flat `## Documentation` list is a collapsed `<details>` all-guides index grouped by the same four verbs, `mix.exs groups_for_extras` exposes matching verb lanes, and a new `persona_routing_doc_contract_test` locks both surfaces (subset keys + README landings + anti-new-guide refute) while `release_artifact_contract_test`'s groups-key equality was updated in lockstep so `verify.release` stays green.

## Tasks Completed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Replace groups_for_extras with four verb lanes + update equality guard | `3fe06fd8` | mix.exs, release_artifact_contract_test.exs |
| 2 | Reshape README Start here into intent table + collapsed all-guides index | `b8547d73` | README.md |
| 3 | Add persona_routing_doc_contract_test + register in verify.doc_contract | `775a82f1` | persona_routing_doc_contract_test.exs, mix.exs, deferred-items.md |

## What Changed

### mix.exs groups_for_extras (Task 1)
Replaced the greedy `Reference: ~r{^guides/}` + `Project: ~r/(CONTRIBUTING|CHANGELOG)/` buckets with four explicit per-lane regexes, retaining `Overview` (README) first and `Integrations` (`~r{^guides/integrations/}`) before the verb lanes. Lane assignment (per 191-RESEARCH):
- **Evaluate** — evaluating-threadline, how-threadline-works, domain-reference
- **Adopt** — getting-started-saas, production-checklist, brownfield-continuity, integration-contracts, local-docker-dx, upgrade-path
- **Operate** — operator-surface, incident-playbook, performance, audit-indexing, adoption-evidence-playbook
- **Contribute** — CONTRIBUTING, adoption-pilot-backlog, CHANGELOG

All 20 extras (README + 15 guides + 2 integrations + CONTRIBUTING + CHANGELOG) land in exactly one lane; `mix docs` builds with no ungrouped-extra warning. `groups_for_modules` untouched.

### README (Task 2)
- `## Start here` is now a `| I want to... | Start here | Then read |` table with one row per verb, each pointing at its canonical landing + next hop; brand-voice microcopy names concrete surfaces (in-repo proof vs staging; install + first captured write + operator surface; the `/audit` console; repo setup + `mix ci.all` + contribution gate). The Adopt row says "Wire it into a Phoenix app" (no guide-body rename).
- The capture-only/phoenix-surface/phx-gen-auth-reference/sigra-reference matrix sentence and the "Phoenix auth (reference lanes, pick one)" line were **relocated** into adjacent Start here prose (not deleted).
- The flat `## Documentation` list became a collapsed `<details><summary>All guides</summary>` index grouped by the four verbs (+ an Integrations group), preserving every previously-listed guide link and adding operator-surface/audit-indexing/adoption-evidence-playbook/CHANGELOG for a complete index.

### New test (Task 3)
`Threadline.PersonaRoutingDocContractTest` (`async: true`), three checks:
- **(a)** `groups_for_extras` contains the four verb lane keys (subset/`in`, not exact equality).
- **(b)** README `## Start here` slice contains each verb label + its canonical landing (Evaluate/evaluating-threadline.md, Adopt/getting-started-saas.md, Operate/operator-surface.md, Contribute/CONTRIBUTING.md).
- **(c)** `refute File.exists?` for `guides/where-to-go-next.md` and `guides/start-here.md`.

Registered by appending to the space-joined `verify.doc_contract` alias in mix.exs (plan 03 separately appends version_truth — a sequential edit, no conflict). Did NOT touch the P1–P5 operator-UI personas or `ia_lock_doc_contract_test.exs`.

## Verification

- `mix test test/threadline/release_artifact_contract_test.exs` — 7/0.
- `MIX_ENV=dev mix docs` — builds, no ungrouped-extra warning.
- `mix test .../readme_doc_contract_test.exs .../exploration_routing_doc_contract_test.exs` — 26/0.
- `mix test .../persona_routing_doc_contract_test.exs` — 3/0.
- Combined routing + preservation + ia_lock guards (persona_routing + readme + release_artifact + exploration_routing + ia_lock) — 42/0.
- `mix verify.doc_contract` — 114 tests, 1 **pre-existing** failure (see Deferred).

## Deviations from Plan

None — plan executed exactly as written. No auto-fixes were required; all target tests passed on first run.

## Deferred Issues

- **Pre-existing `v1_23_charter_doc_contract_test.exs:18` failure** (milestone drift: charter asserts v1.38, active milestone is v1.39). Confirmed failing on clean `b8547d73` BEFORE the Task 3 change, so it is not caused by this routing reshape. It is version/milestone-charter truth, owned by the ADOPT-01 version-truth work (plan 191-03) or a charter refresh — out of scope for the ADOPT-03 routing plan. Logged to `deferred-items.md`. It was already the single residual failure in the `verify.doc_contract` suite prior to this plan (110/111 at 191-01; 113/114 now, the delta being the +3 passing persona-routing tests).

## Known Stubs

None. No hardcoded empty/placeholder values introduced; all links resolve to existing guides.

## Self-Check: PASSED

- Created file `test/threadline/persona_routing_doc_contract_test.exs` — FOUND.
- Modified `mix.exs`, `README.md`, `test/threadline/release_artifact_contract_test.exs` — all present.
- Commits `3fe06fd8`, `b8547d73`, `775a82f1` — all present in `git log`.
