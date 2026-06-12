---
phase: 159-brand-audit-and-research
verified: 2026-06-11T21:30:00-04:00
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
---

# Phase 159: brand-audit-and-research Verification Report

**Phase Goal:** A design brief grounded in a pressure-test audit of the existing `brandbook/` plus external devtools/OSS identity research — so round-1 candidates are generated from knowledge, not vibes.
**Requirements:** AUD-01, AUD-02, RES-01, RES-02, RES-03, RES-04
**Verified:** 2026-06-11 (re-run against actual artifacts; SUMMARY claims not trusted)
**Status:** passed
**Re-verification:** No — initial verification

## Artifacts Present

| Artifact | Status |
|---|---|
| `159-AUDIT.md` (55,814 bytes) | EXISTS, SUBSTANTIVE |
| `159-RESEARCH.md` (47,427 bytes) | EXISTS, SUBSTANTIVE |
| `159-DESIGN-BRIEF.md` (25,163 bytes) | EXISTS, SUBSTANTIVE |
| `159-01-SUMMARY.md`, `159-02-SUMMARY.md`, `159-03-SUMMARY.md` | EXISTS (3/3) |

## Criterion 1 — AUD-01: 14-section audit with verdicts, 15-cell scorecard, named antipatterns, real grep evidence — VERIFIED

**Sections:** `grep -c -E "^## [0-9]+\." 159-AUDIT.md` → **14** (sections 1–14, lines 123–254).

**Verdicts:** `grep -c '\*\*Verdict:\*\*' 159-AUDIT.md` → **14**, one per section, all from the allowed set: KEEP ×4 (§2, §7, §10, §11), TIGHTEN ×4 (§1, §9, §12, §14), REWORK ×5 (§3, §4, §5, §8, §13), ADD ×1 (§6). REMOVE unused — allowed-set compliant.

**Scorecard:** `grep -o -E "[0-9]+ / 10" 159-AUDIT.md | wc -l` → **15** cells exactly (lines 141–155: Distinctiveness 4/10 … Craft 4/10; total baseline 79/150).

**Icon-left-of-text finding:** Finding E2 (line 60: "The icon-left-of-text antipattern, named plainly") dissects `brandbook/logo-primary.svg` as "three unrelated elements in a row" (line 62) and feeds GAP-01 (line 173).

**Baked-subtitle finding:** Finding E3 (line 70: "The baked-in subtitle antipattern") cites `logo-primary.svg:18`, `logo-primary-light.svg:18`, `logo-monochrome.svg:14` and computes ~4.4px subtitle at the book's own 160px minimum; feeds GAP-02 (line 174).

**`<text>` portability evidence is real:** AUDIT lines 44–47 and Appendix A (lines 272+) reproduce `grep -n '<text' brandbook/*.svg` output. Independently re-run against the working tree — **byte-identical match** for `logo-primary.svg:17-18`, `logo-primary-light.svg:17-18`, `logo-monochrome.svg:13-14`. Per-file `<text>` counts claimed in AUDIT line 54 (primary 2, light 2, monochrome 2, social-card 4, components 13, docs-page 13, palette 12, typography 7, terminal 6, landing-hero 5, readme-header 5, favicon 0, logo-mark 0) re-verified file-by-file: **all 13 counts match actual brandbook files**.

## Criterion 2 — AUD-02: 8-surface stress matrix with PASS/DEGRADED/FAIL — VERIFIED

Matrix at AUDIT lines 104–119 ("Stress-Test Matrix (AUD-02)") contains exactly the 8 required surface rows, each with an asset tested, behavior, file:line evidence, rating, and severity:

| Surface | Rating |
|---|---|
| GitHub README render | FAIL (Critical) |
| Hex.pm logo slot | DEGRADED (Major) |
| HexDocs logo slot | DEGRADED (Major) |
| 16px favicon | FAIL (Critical) |
| Dark mode | PASS (Minor) |
| Light mode | DEGRADED (Major) |
| Monochrome | FAIL (Major) |
| Social card | DEGRADED (Major) |

Summary line present: "1 PASS, 4 DEGRADED, 3 FAIL across 8 surfaces."

## Criterion 3 — RES-01/02/03 — VERIFIED

**RES-01 (≥8 cited case studies incl. ≥1 failure):** `grep -c '^### Case study:' 159-RESEARCH.md` → **11** (Vite, Bun, Deno, Tailwind, Supabase, Prisma, Astro, Zig, Phoenix, Elixir, Mozilla). Per-block check confirms **every case study carries ≥1 `Source:` URL citation** (61 `Source:` lines file-wide). Failure case: "Mozilla moz://a — FAILURE / GIMMICK-RISK CASE" (line 196) with named failure mode GIMMICK-DEPENDENCE, an explicit avoid-rule, and 3 citations (johnsonbanks.co.uk, blog.mozilla.org, underconsideration.com).

**RES-02 (≥6 named techniques):** `grep -c '^### Technique:' 159-RESEARCH.md` → **6**: Negative space, Pattern-through-letterforms, Continuous-line mark, Ligature wordmark, Stroke continuation, Counter replacement. Each has a definition, canon example, and small-size risk — names verbatim-usable.

**RES-03 (numeric thresholds, not adjectives):** §2b "16px canvas rules" (lines 369+): stroke weight **>= 1.5px target / >= 1.0px absolute floor** at 16px canvas (Primer/Octicons cited); gap/counter **>= 1.0px**, **>= 1.5px** around modifiers; corner detail **1px radius at 16px**. Monochrome rules (lines 413–440) are binary procedures: single-flat-color flatten test, gradient-dependence named antipattern with check ("if distinctiveness rests on a color transition rather than geometry, fail"), dark/light flip test on #FFFFFF and near-black. All testable, none adjectival.

## Criterion 4 — RES-04: DESIGN-BRIEF round-1 generation contract — VERIFIED

- **Motif rules cite RESEARCH technique names verbatim:** brief §2 lines 33–38 list all 6 technique names exactly as in RESEARCH (`grep` match on all six strings).
- **Hard constraints with downstream IDs:** HC-1 [LOGO-03], HC-2 [LOGO-02], HC-3 [LOGO-01], HC-4 [TOUR-02], HC-5 [LOGO-04], HC-6 [LOGO-05, GLYPH-03]; §5 heading carries [TOUR-01]. All of LOGO-01..05 and TOUR-01 present; all IDs confirmed real in `.planning/REQUIREMENTS.md`. HC-4 restates the RESEARCH numeric thresholds verbatim (1.5px/1.0px strokes, 1.0px gaps, ≤4 strokes, silhouette-first).
- **Degrees of freedom name OFL typefaces:** §4 lists Geist plus 8 named OFL-1.1 candidates (Inter, Space Grotesk, IBM Plex Sans, Manrope, Sora, Hanken Grotesk, Archivo, JetBrains Mono) with the Plex reserved-name caveat.
- **3+3+1+1 archetype lane table:** §5 table — Integrated typemark 3, Unified mark+type lockup 3, Monogram/mark-led 1, Wordmark-only 1 = 8 candidates, plus the distinct-named-motif (technique, hook) pairing rule.
- **Trademark flag:** §6 one-line flag — "trademark/legal clearance … NOT performed in this milestone and is flagged for human review before public rollout — this is the only legal mention in this brief"; mirrored as traceability row AUDIT-TM.
- **Definition of done for round 1:** heading present (line 171) with the full mechanical acceptance statement (8 candidates, lane quota, distinct strategies, all six HCs, six TOUR-02 contexts, user-only selection).

## Criterion 5 — Routing: no orphan GAP/UP items — VERIFIED

ID-set cross-check (independent grep, sorted unique):

- AUDIT defines: GAP-01..GAP-12 (12), UP-01..UP-11 (11).
- BRIEF traceability references: GAP-01..GAP-12 (12), UP-01..UP-11 (11).
- **Set difference: empty in both directions — zero orphans.**

Traceability table (brief lines 106–160): 6 section-level REWORK/ADD rows + 12 GAP rows + 11 UP rows + 1 human-review flag = 30 rows. 27 ROUTED (every routed-to target — LOGO-01..05, TOUR-01/02, BOOK-01..05/07 — is a real v1.35 requirement ID in REQUIREMENTS.md), 3 DESCOPED (GAP-09, UP-08 → SOCIAL-PNG-01, which exists in REQUIREMENTS.md Future Requirements line 67; AUDIT-TM → human review per Out of Scope), each with a recorded reason. **No empty cells** (visual inspection of all 30 rows).

## Criterion 6 — Scope: read-only phase respected — VERIFIED

- `git status --porcelain brandbook/` → **empty** (clean).
- `git log --name-only --grep='159-0' --oneline` → 10 commits (9a2bf5c..e20668b), touching **only** `.planning/` paths (REQUIREMENTS.md, ROADMAP.md, STATE.md, phase-dir PLAN/SUMMARY/AUDIT/RESEARCH/DESIGN-BRIEF files). **Zero commits touch `brandbook/` or `lib/`.** Pre-existing uncommitted `lib/`/`examples/`/`test/` changes belong to other lanes and were not staged by any 159 commit.

## Anti-Patterns Found

None. `grep -E "TBD|FIXME|XXX|PLACEHOLDER|not yet implemented"` across all six phase artifacts → no matches.

## Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|---|---|---|---|
| AUD-01 | 159-01 | SATISFIED | Criterion 1 |
| AUD-02 | 159-01 | SATISFIED | Criterion 2 |
| RES-01 | 159-02 | SATISFIED | Criterion 3 |
| RES-02 | 159-02 | SATISFIED | Criterion 3 |
| RES-03 | 159-02 | SATISFIED | Criterion 3 |
| RES-04 | 159-03 | SATISFIED | Criterion 4 |

## Gaps Summary

No gaps. All five ROADMAP success criteria hold against the actual artifacts; audit evidence claims (grep output, per-file `<text>` counts, quoted SVG lines) were independently re-run and match the working tree byte-for-byte.

---

_Verified: 2026-06-11_
_Verifier: Claude (gsd-verifier)_
