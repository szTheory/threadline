---
phase: 145-brand-audit-milestone-baseline
status: complete
requirements: [BRAND-AUDIT-01]
date: 2026-06-05
---

# Phase 145 Brand Audit & Milestone Baseline

## Sources Read

- `prompts/Threadline Brand Book.txt`
- `prompts/threadline-elixir-oss-dna.md`
- `README.md`
- `priv/fonts/README.md`
- `lib/threadline/operator_surface/style.ex`
- Reverted spike commit `1ccd6fd Add Threadline brandbook artifacts`
- Revert commit `7f9e121 Revert "Add Threadline brandbook artifacts"`

## Executive Judgment

The original Threadline brand book has a strong strategic center and should not be redesigned for novelty. The concept "Threadline makes system history followable" is distinct, technically relevant, and credible for Phoenix/Ecto/Postgres audit infrastructure.

The original book was not implementation-ready. It had strong direction for positioning, voice, palette, type, and visual metaphor, but it did not fully define semantic tokens, state coverage, source artifact rules, logo source assets, visual examples, or concrete verification gates.

The reverted `1ccd6fd` spike was directionally useful but not a proper GSD milestone. It skipped requirements, phase planning, explicit source audit, phase verification, milestone traceability, and closeout. It can be reused only as prototype input, not as accepted milestone evidence.

## KEEP

- Brand idea: "Threadline makes system history followable."
- Tagline: "Follow what happened."
- Stack-specific positioning around Phoenix, Ecto, and PostgreSQL.
- Voice: calm senior engineer, precise, useful, low-BS.
- Visual metaphor: continuous line connecting changes into explainable history.
- Palette foundation: dark infrastructure neutrals with Thread Blue and Signal Cyan as functional signals.
- Typography choice: Geist plus IBM Plex Mono, already documented with SIL OFL font provenance in `priv/fonts/`.

## TIGHTEN

- Translate palette into raw and semantic tokens, including light docs/marketing roles.
- Make hover, active, focus, disabled, selected, success, warning, error, info, subtle, and muted states explicit.
- Separate runtime operator-surface tokens from static brandbook/collateral tokens.
- Convert logo direction into source SVG assets with usage rules, minimum sizes, monochrome behavior, and small-size checks.
- Turn voice principles into examples for README, docs, errors, empty states, release notes, and social launch copy.
- Add repo hygiene rules to avoid duplicate fonts, generated PNG batches, and vendor-locked assets.

## REWORK

- Any language implying Threadline is a complete compliance product, legal hold system, immutable archive guarantee, or SIEM.
- Any abstract node/line artwork that does not encode the audit domain.
- Any gradient usage that becomes decorative ambience instead of signal/path linework.
- Any logo idea that depends on custom proprietary fonts, complex paths, or small-size illegibility.

## ADD

- `brandbook/` as the only committed brand artifact folder.
- Static `index.html` that opens directly from disk.
- `brand-book.md` and `pressure-test.md` as durable source docs.
- `tokens.json` and `tokens.css`.
- Editable SVG logo and visual example assets.
- Verification script or recorded verification commands for JSON, SVG, browser, contrast, image loading, and file inventory.
- Phase verification reports and milestone audit.

## REMOVE / EXCLUDE

- README rollout, HexDocs theme rollout, operator UI changes, and marketing site implementation from this milestone.
- Mascot exploration.
- Shield, lock, chain, fingerprint, police tape, and courtroom imagery.
- Large raster moodboards.
- Duplicate font binaries.

## Scorecard

| Dimension | Score | Rationale | Risk | Required Fix |
|---|---:|---|---|---|
| Distinctiveness | 8 | The connected audit-history metaphor is strong. | Generic line/node execution. | Keep domain nouns and evidence-path linework. |
| Developer credibility | 9 | Voice and claims are grounded in real Threadline behavior. | Compliance overreach. | Tie claims to capture, context, timelines, exports, health, and evidence. |
| Elixir ecosystem fit | 9 | Understated, technical, and stack-specific. | Random SaaS polish. | Prioritize README/HexDocs/docs usefulness over spectacle. |
| Visual coherence | 7 | Palette/type/metaphor align. | Original lacked executable examples. | Add SVG specimens and token constraints. |
| Logo readiness | 6 | Direction is good but no source system existed pre-spike. | Mark may be too generic or not small-size durable. | Add simple SVG system and manual favicon review. |
| Token readiness | 6 | Operator UI has tokens; brandbook did not. | Static collateral could drift from product UI. | Reuse names/values where appropriate and document lanes. |
| UI usefulness | 6 | Component ideas exist but are not fully buildable. | Future sites improvise inconsistently. | Add primitive examples, states, and code/terminal rules. |
| Accessibility | 6 | Intent exists but little proof. | Light accent contrast and small SVG legibility. | Run representative contrast and browser checks. |
| Repo readiness | 5 | No source folder before spike; spike was text/SVG only but unplanned. | Binary sprawl later. | Commit only source assets and document export rules. |
| Maintainability | 7 | Strong concept can endure. | Token/source drift. | Keep artifacts small and verification repeatable. |

## Baseline Decision

Proceed with brand-system-only scope. Reintroduce a hardened `brandbook/` tree after Phase 146/147/148 work, not before. The final output may reuse proven pieces from `1ccd6fd`, but the milestone must add requirements traceability, QA evidence, and closeout records.
