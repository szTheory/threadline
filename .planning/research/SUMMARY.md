# Project Research Summary

**Milestone:** v1.46 — Operator UI Refinement
**Synthesized:** 2026-10-08
**Status:** Existing research reuse explicitly approved; no new generic research fanout.
**Authoritative inputs:** [UI-MILESTONE-PREFLIGHT.md](../UI-MILESTONE-PREFLIGHT.md), [PRODUCT.md](../../PRODUCT.md), current milestone in [PROJECT.md](../PROJECT.md), domain reference and Brand Book.

## Executive summary

Refine the existing operator UI around complete investigation and operations jobs.
The maintainer confirmed equal priority for engineers and support/on-call operators,
code-first implementation and the existing Threadline identity. No new framework,
backend capability, public component library or paid visual-judge loop is needed.

The preflight consolidates three completed parallel investigations: current-main
Threadline source/inventory, Scrypath's post-milestone fixes, and Accrue/Mailglass
methods and unfinished work. It cites source commits and distinguishes completed,
locally modified and merely planned changes. Reuse those findings; research again
only for a concrete gap discovered during the fresh rendered baseline.

## Stack and architecture

Keep Phoenix/LiveView/HEEx, the existing shared UI modules and CSS tokens, Geist and
IBM Plex Mono, existing theme controls and reconnect handling. Preserve the host
mount, authentication, tenant scope, server authorization, redaction and asset
contract. Capture, semantics and exploration stay separate; public 1.x APIs and
Phoenix optionality are constraints, not implementation targets.

Use the configured isolation workflow to establish a current-main source base.
The original milestone/v1.44 checkout is a dirty planning checkout whose package
version is stale; carrying its source forward wholesale would undo shipped work.
Carry PRODUCT.md, Impeccable config and current planning records deliberately.

First prove one coherent investigation composition, then make shared changes
through one owner before parallel page work. Use existing hooks and idiomatic
LiveView lifecycle handling. Responsive/accessibility/state correctness belongs in
each journey, with final integration confirming the shared seams.

## Scope categories

| Category | Required outcome | Distinctive audit constraint |
| --- | --- | --- |
| Baseline | Reproducible current-main preview; all 11 routes and material states inventoried | Source/asset identity and fixture provenance; historic PNGs are not current proof |
| Shared presentation | Readable hierarchy, reusable controls/tokens and coherent copy | Actions, transactions, changes, contexts and actors remain distinct; exact evidence stays reachable |
| Investigation | Start, filter, inspect, pivot, resume/share using existing capabilities | Preserve search/scope/history context; no relabeling old evidence during pending requests |
| Operations | Coverage, evidence, export, redaction and retention jobs are complete | Host-written evidence and configured/deployed policy limits remain explicit; requested is not completed |
| Interaction | Responsive/zoom/theme, keyboard/touch, patch/disconnect, clipboard and purposeful motion | Permission, busy and unavailable states have different causes and affordances |
| Verification | Required behavioral proof, bounded visual review and final review preview | Test discovery and actual CI execution matter; ordinary verification cannot rewrite baselines |

These are refinements of shipped features. Do not re-add completed reconnect,
theme or integration seeds. Composite-key row routing and row-history pagination
are outside this milestone; preserve and explain existing capability limits.

## Pitfalls that affect the roadmap

- Scrypath's post-closeout changes repaired competing pointer/keyboard highlights,
  loading icons destroyed by text replacement, CSS specificity defeating toast
  tokens, and navigation/copy drift. Exercise interactions and compiled styles,
  not just initial screenshots or class-string tests.
- Mailglass demonstrated why real browser zoom, delayed-response scope identity,
  complete values and CI test discovery need proof. A narrow viewport or a green
  job alone cannot establish those properties.
- Accrue demonstrated baseline mutation during ordinary tests and partial journey
  coverage. Make capture explicit, preserve before evidence, and exercise controls
  through the actual destination/outcome.
- Threadline has source candidates around fresh-entry Copy bindings, disconnected
  queue-export controls, self-referential unused token aliases and label drift.
  They are candidates, not reproduced browser defects. Validate before fixing;
  distinguish latent token debt from visible regressions.
- Paid critic iteration did not establish the intended improvement in v1.40.
  Retain useful deterministic checks and use finite agent visual-review batches;
  do not reopen that loop or resurrect retired pixel machinery by default.

## Roadmap implications

Start numbering at 238 after completed Phase 237. Derive phase boundaries from
approved atomic requirements, not an arbitrary quota. A useful order is fresh
baseline and acceptance contract, one complete investigation slice with shared
primitives, remaining investigation and operations jobs, then integrated evidence
and delivery readiness. Avoid a standalone component rewrite before proving a page,
and avoid deferring responsive/error states to a final cleanup phase.

Reuse named checks listed in the preflight and verify their discovery on current
main. For each meaningful slice, inspect representative full-shell/page states,
fix the concrete findings as a batch, then confirm. Unresolved defects need a
reproduction, severity and disposition; bounded review is not a waiver for blockers.
The maintainer may provide taste feedback after the baseline, but does not execute
UAT. Package publication remains a later explicit grant, not implied by scope approval.

## Confidence and remaining evidence

High confidence in product intent, route/source inventory, architecture boundaries
and the cited sibling failure classes. Current visual quality is not yet measured:
no fresh demo was started during preparation. The initial source reference was
origin/main 9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2 (1.0.1 distribution sync).
Refresh main identity before implementation. Chromium is the existing automated
browser engine; do not claim physical-device or other-engine proof from it.

The preflight contains the detailed citations and capture/state/test matrix.
Known old local planning hygiene findings are recorded there; do not present a
changed-file check as a clean repository-wide scan.

## Research provenance across milestones

The previous summary is preserved byte-for-byte in
[v1.45-API-CONTRACT-SUMMARY.md](v1.45-API-CONTRACT-SUMMARY.md).
The adjacent STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md and CONTRACT.md
remain historical v1.45 API-contract research. They are not v1.46 requirements
inputs and must not reopen already completed public-API decisions. Use this
summary and the preflight for current UI planning.
