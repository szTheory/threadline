# Roadmap: v1.33 Brand Review + Direction Selection

**Status:** complete - v1.33 verified and archive-ready
**Opened:** 2026-06-05

## Goal

Make the already-created v1.32 `brandbook/` artifacts visible, reviewable, and decision-complete before any public README/GitHub/HexDocs/marketing rollout starts.

## Non-goals

- Full brand-system redo.
- Runtime operator surface UI changes.
- Public README, HexDocs, or marketing-site rollout.
- Binary-heavy export batches.
- Legal/trademark clearance beyond flagging the need for human review.

## Deciding Surface

README/GitHub is the primary readiness test. The brand can still support future landing pages and HexDocs, but this milestone judges whether the direction earns OSS adopter trust in the repository first.

## Phases

| Phase | Name | Requirements | Status |
|---|---|---|---|
| 150 | Review Packet + Visibility | REVIEW-PACKET-01, README-FIT-01, LOGO-LIGHT-01 | Complete |
| 151 | Critical Review + Options | REVIEW-DECISION-01 | Complete |
| 152 | Targeted Revisions | REVISION-01 | Complete |
| 153 | Verification + Closeout | BRAND-QA-02 | Complete |

**Execution order:**
- [x] **Phase 150: Review Packet + Visibility** - Make the v1.32 brandbook artifacts visible for review and fix any immediate README/GitHub legibility blocker.
- [x] **Phase 151: Critical Review + Options** - Select the brand direction path before rollout work starts.
- [x] **Phase 152: Targeted Revisions** - Apply selected, scoped brandbook-facing revisions without expanding into public rollout or runtime UI work.
- [x] **Phase 153: Verification + Closeout** - Verify final brand artifacts and close v1.33.

## Phase Details

### Phase 150: Review Packet + Visibility
**Goal**: Make the existing v1.32 `brandbook/` artifacts inspectable for human review and fix any concrete README/GitHub visibility issue found before direction selection.
**Depends on**: Nothing (first phase)
**Requirements**: REVIEW-PACKET-01, README-FIT-01, LOGO-LIGHT-01
**Success Criteria** (what must be TRUE):
  1. The brandbook HTML, logo assets, visual specimens, token files, and copy guidance are inventoried for review.
  2. README/GitHub/light documentation logo fit is evaluated against the actual artifact set.
  3. A light-surface primary logo exists if the dark primary lockup is not suitable on white backgrounds.
**Plans**: 1 plan

### Phase 151: Critical Review + Options
**Goal**: Capture the human brand direction decision before any public README, HexDocs, marketing, or runtime UI rollout work starts.
**Depends on**: Phase 150
**Requirements**: REVIEW-DECISION-01
**Success Criteria** (what must be TRUE):
  1. The user sees concrete direction options based on the reviewed brand artifacts.
  2. The selected path is recorded clearly enough to constrain later work.
  3. Unselected paths remain explicitly out of scope for this milestone unless separately planned.
**Plans**: 1 plan

### Phase 152: Targeted Revisions
**Goal**: Apply the selected targeted cleanup to brandbook-facing source artifacts so they present the current Threadline brand truth without process-history framing.
**Depends on**: Phase 151
**Requirements**: REVISION-01
**Success Criteria** (what must be TRUE):
  1. Brandbook-facing copy describes the current brand system as source guidance rather than refresh or audit backstory.
  2. The current logo system, tokens, examples, HTML layout, and artifact boundary remain intact unless a selected material issue requires a scoped change.
  3. Public README, HexDocs, marketing, runtime UI, and alternate concept exploration remain out of scope.
**Plans**: 1 plan

### Phase 153: Verification + Closeout
**Goal**: Run the final brand artifact verification pass after targeted revisions and close v1.33 only if the artifact set remains parseable, renderable, bounded, and ready for later rollout decisions.
**Depends on**: Phase 152
**Requirements**: BRAND-QA-02
**Success Criteria** (what must be TRUE):
  1. JSON and SVG brand artifacts parse successfully after the final change set.
  2. `brandbook/index.html` renders directly from disk on desktop and mobile viewports without missing local assets.
  3. Final screenshots or equivalent evidence cover desktop/mobile brandbook rendering after the targeted revisions.
  4. File-type and file-size boundaries remain text/SVG/HTML/CSS/JSON-first, with no unintended binary-heavy export batch.
  5. The milestone closeout record states what is approved now and what remains deferred to future public rollout phases.
**Plans**: 1 plan

## Current Checkpoint

Phase 150 found one concrete README/GitHub issue: the dark-surface primary logo was too pale on white backgrounds. The milestone added `brandbook/logo-primary-light.svg` and updated usage guidance so light surfaces no longer depend on the dark lockup.

Phase 151 selected targeted revisions after human review. Phase 152 applied a stand-alone truth cleanup so `brandbook/` presents the current Threadline brand system rather than refresh or audit backstory.

Phase 153 completed the milestone-level verification and closeout lane. v1.33 approves the reviewed brandbook direction, the light-surface primary logo role, and the Phase 152 targeted copy cleanup.

Deferred rollout remains explicit: root README rollout, HexDocs brand treatment, landing page, social-card PNG export, and legal/trademark review.

## Latest Shipped Milestone

<details>
<summary>✅ v1.32 Brand System Foundation (Phases 145-149) - SHIPPED 2026-06-05</summary>

- [x] Phase 145: Brand Audit & Milestone Baseline
- [x] Phase 146: Brand System Spec
- [x] Phase 147: Token & Asset Source System
- [x] Phase 148: Static HTML Brandbook
- [x] Phase 149: Verification, Review, and Closeout

Full archive: `.planning/milestones/v1.32-ROADMAP.md`

</details>
