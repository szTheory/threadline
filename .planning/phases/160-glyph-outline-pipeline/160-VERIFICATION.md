---
phase: 160-glyph-outline-pipeline
verified: 2026-06-12T04:05:00Z
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
re_verification: false
---

# Phase 160: Glyph Outline Pipeline Verification Report

**Phase Goal:** A reproducible text-to-outline pipeline so every logo SVG is pure paths with real font-shaping kerning — portable everywhere, no font dependency.
**Verified:** 2026-06-12T04:05:00Z
**Status:** passed
**Re-verification:** No — initial verification

All gates were re-run from scratch by the verifier (fresh ephemeral fontkit install, regeneration, byte-comparison, XML/content gates, native-resolution visual inspection of the overlay PNG). SUMMARY.md claims were not trusted as evidence.

## Goal Achievement

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1   | Committed Node script converts geist-500/600 woff2 into per-glyph SVG paths for "Threadline" with shaped GPOS kerning | ✓ VERIFIED | Fresh `mktemp` install of `fontkit@2.0.4`; both invocations exited 0 into a temp dir. Script uses `font.layout()` + `createRequire` (13 `fontkit\|layout(` matches). Non-uniform kerned offsets (e.g. 500: T adv=568 but h at x=542 — kerning applied, not plain advance accumulation) |
| 2   | Rerunning with same inputs produces byte-identical outputs | ✓ VERIFIED | `cmp` clean for all 4 files: `cmp OK: glyph-kit-geist-500.svg`, `.json`, `glyph-kit-geist-600.svg`, `.json` (regenerated 2026-06-12 from a fresh ephemeral fontkit@2.0.4 install) |
| 3   | SVGs: one `<path>` per glyph, zero `<text>`, 2-decimal y-flipped coords | ✓ VERIFIED | Path counts 10/10 == JSON glyph counts 10/10 (both weights); `grep -c '<text'` = 0 for both; no 3+-decimal coords in any of the 4 files; baseline at y=ascent=1005, viewBox height 1300 = ascent−descent |
| 4   | Overlay evidence matches live-Geist render at 2x with intact e/a/d counters | ✓ VERIFIED | `overlay-evidence-2x.png` is PNG 2800x2200 RGB. Native-resolution crop inspection: uniform magenta+cyan blend, only sub-pixel antialiasing fringe, no glyph-shaped displacement; e/a/d counters render as holes on dark AND white backgrounds |
| 5   | Kit JSON exposes per-glyph metadata + l/T stem widths for Phase 161 | ✓ VERIFIED | Both JSONs carry `unitsPerEm: 1000`, `weight` (500/600), per-glyph `x_offset_kerned`, `advance_width`, `bbox`, `d`; `stem_widths` l=106/T=108 (500), l=128/T=130 (600), all positive, with documented measurement method string |
| 6   | Pipeline regenerable after archive via brandbook/tools/ copy | ✓ VERIFIED | `cmp brandbook/tools/text-to-paths.mjs <phase copy>` byte-identical; README pins `fontkit@2.0.4` (line 17) with the canonical ephemeral-install invocation |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `tools/text-to-paths.mjs` (phase dir) | fontkit pipeline, min 80 lines | ✓ VERIFIED | 209 lines, substantive (layout(), createRequire, canonical formatter); executed successfully |
| `glyph-kit-geist-500.svg` | per-glyph path kit | ✓ VERIFIED | 3675 bytes (≤30720), xmllint clean, 10 paths |
| `glyph-kit-geist-500.json` | metadata + `stem_widths` | ✓ VERIFIED | parses; `stem_widths` present, positive |
| `glyph-kit-geist-600.svg` | per-glyph path kit | ✓ VERIFIED | 3667 bytes (≤30720), xmllint clean, 10 paths |
| `glyph-kit-geist-600.json` | metadata + `stem_widths` | ✓ VERIFIED | parses; `stem_widths` present, positive |
| `overlay-specimen.html` | `@font-face` live-font specimen | ✓ VERIFIED | 3 `@font-face` blocks; zero `https?://` src/href (file://-only) |
| `overlay-evidence-2x.png` | 2x screenshot evidence | ✓ VERIFIED | PNG image data, 2800 x 2200, 8-bit RGB; visually inspected at native resolution |
| `brandbook/tools/text-to-paths.mjs` | byte-identical regeneration copy | ✓ VERIFIED | `cmp` exit 0 against phase copy |
| `brandbook/tools/README.md` | contains `fontkit@2.0.4` | ✓ VERIFIED | pinned install command on line 17 |
| `tools/capture-overlay.mjs` | committed Playwright capture script | ✓ VERIFIED | exists, resolves Playwright via createRequire against the e2e install |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `tools/text-to-paths.mjs` | `priv/fonts/geist-*.woff2` | `--font` arg + fontkit | ✓ WIRED | 13 `fontkit\|layout(` matches; executed end-to-end against both woff2 files |
| `overlay-specimen.html` | `priv/fonts/geist-500.woff2` | `@font-face` relative url | ✓ WIRED | 1 match for `priv/fonts/geist-500.woff2` |
| `brandbook/tools/text-to-paths.mjs` | phase `tools/text-to-paths.mjs` | byte-identical copy | ✓ WIRED | `cmp` exit 0 |

### Behavioral Spot-Checks / Probe Execution

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| GLYPH-01 regeneration + determinism | `FONTKIT_DIR=$(mktemp -d) && npm install --prefix "$FONTKIT_DIR" ... fontkit@2.0.4 && NODE_PATH=... node tools/text-to-paths.mjs --font priv/fonts/geist-{500,600}.woff2 --out $R/... && cmp` x4 | all `cmp OK`, EXIT=0 | ✓ PASS |
| GLYPH-03 XML validity | `xmllint --noout` both SVGs | exit 0 both | ✓ PASS |
| GLYPH-03 no text elements | `grep -c '<text'` both SVGs | 0 / 0 | ✓ PASS |
| GLYPH-03 counters | python check: e/a/d `d` strings M-command count | e=2, a=2, d=2 (both weights), assertion passed | ✓ PASS |
| Rounding gate | `grep -E '[0-9]+\.[0-9]{3}'` all 4 kit files | no matches | ✓ PASS |
| Size budget | `stat -f%z` | 3675 / 3667 bytes ≤ 30720 | ✓ PASS |
| Phase 161 handoff fields | python assertion: `x_offset_kerned`, `unitsPerEm`, positive `stem_widths.l/.T` | all present and positive (both weights) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| GLYPH-01 | 160-01 | Rerunnable committed script → per-glyph SVG paths with real shaped kerning, one `<path>`/glyph, 2-decimal | ✓ SATISFIED | Truths 1-3; fresh-install regeneration byte-identical |
| GLYPH-02 | 160-01 | Overlay evidence vs live-font render at 2x | ✓ SATISFIED | Truth 4; PNG inspected at native resolution, no displacement |
| GLYPH-03 | 160-01 | Zero `<text>`; e/a/d counters render correctly | ✓ SATISFIED | Truths 3-4; ≥2 M-commands per e/a/d glyph, counters visible as holes on dark and white |

No orphaned requirements: REQUIREMENTS.md maps exactly GLYPH-01/02/03 to Phase 160, all claimed by plan 160-01.

### Scope / Hygiene

- `git status --porcelain -- brandbook/` — empty (nothing uncommitted under brandbook/).
- Phase commits `7815e80`, `ea25e34`, `ac837c7` touch only the phase dir and `brandbook/tools/` (verified via `git show --name-only`). The only brandbook/ commit from this phase is `ac837c7`, limited to `brandbook/tools/`.
- `git ls-files` shows no node_modules and no package.json/package-lock.json outside the pre-existing `examples/threadline_phoenix/e2e/` install (added in `db94c49`, prior to this phase; the plan explicitly reuses it).
- No `*.woff2` under `brandbook/tools/`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| — | — | none (TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER scan clean across phase tools, specimen, and brandbook copies) | — | — |

### Human Verification Required

None blocking. The PLAN's deferred human-check ("open overlay-specimen.html over file:// and confirm visual match") was satisfied by verifier inspection of the committed 2x evidence PNG at native resolution per the verification contract for this phase; opening the specimen live remains available as an optional spot-check but is not required for goal achievement.

### Gaps Summary

No gaps. The phase goal is achieved in the codebase: a committed, deterministic, dependency-ephemeral text-to-outline pipeline regenerates byte-identical pure-path glyph kits for both Geist weights with real shaped kerning, fidelity is proven against a live-font render, and the Phase 161 handoff metadata (kerned x-offsets, units-per-em, positive l/T stem widths) is present in both JSONs.

---

_Verified: 2026-06-12T04:05:00Z_
_Verifier: Claude (gsd-verifier)_
