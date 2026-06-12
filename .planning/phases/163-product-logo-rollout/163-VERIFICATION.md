---
phase: 163-product-logo-rollout
verified: 2026-06-12T21:45:32Z
status: passed
score: 7/7 must-haves verified
overrides_applied: 0
re_verification: false
backfilled: true # Record written at milestone audit time from rerun gates + commit inspection
---

# Phase 163: product-logo-rollout Verification Report

**Phase Goal:** User opted in at the end-of-milestone checkpoint; the C13 identity rolls into product surfaces (operator-surface logo component, example-app admin favicon, root README header).
**Requirements:** ROLL-01, ROLL-02, ROLL-03 (optional, decision-gated — user opted IN)
**Verified:** 2026-06-12 (commits inspected and gates rerun by verifier; SUMMARY claims cross-checked, not trusted)
**Status:** passed
**Re-verification:** No — backfilled initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Explicit opt-in decision at the checkpoint | ✓ VERIFIED | ROADMAP.md phase table: `Complete (2026-06-12) — user opted in ("Roll out now")`; STATE.md: "user opted IN at the rollout checkpoint ('Roll out now')" |
| 2 | Commits touch only sanctioned files | ✓ VERIFIED | `git show --stat` per commit: `898b63f` → logo.ex only; `2e8be6d` → threadline-admin-favicon.svg only; `5fd61fc` → README.md only; `c19fded` → phase-dir evidence only (163-01-PLAN.md, topbar-mark-evidence.html/.png); `19486ae` → planning docs only (REQUIREMENTS/ROADMAP/STATE/163-01-SUMMARY). No other-lane file in any task commit |
| 3 | ROLL-01: logo.ex renders the winning mark on the `var(--tl-*)` contract | ✓ VERIFIED | All 11 `<path d="...">` geometries in `lib/threadline/operator_surface/components/logo.ex` are verbatim-identical to `brandbook/logo-primary.svg` (10/10 unique path strings match, including the `data-role="mark"` stitch arc); viewBox identical (`-80 60 5194 1140`); 13 `var(--tl-*)` usages (glyphs `--tl-color-text`, arc `--tl-color-accent`); no `role="img"`, `aria-hidden` preserved |
| 4 | `style.ex` untouched (freeze exception covers logo.ex only) | ✓ VERIFIED | `style.ex` does not appear in any of the five 163 commits' stats |
| 5 | ROLL-02: example-app admin favicon = brandbook favicon | ✓ VERIFIED | Verifier rerun: `cmp examples/threadline_phoenix/priv/static/images/threadline-admin-favicon.svg brandbook/favicon.svg` → byte-identical; zero `<rect>`/`<text>`; internal `prefers-color-scheme` flip intact |
| 6 | ROLL-03: README header uses the brand assets with GitHub-safe dark/light handling | ✓ VERIFIED | `README.md` lines 1–4: `<picture>` with `<source media="(prefers-color-scheme: dark)" srcset="brandbook/logo-primary.svg">` and light fallback `<img src="brandbook/logo-primary-light.svg" width="420">`; both referenced assets tracked; prior content/badges preserved |
| 7 | Compile/test gates green | ✓ VERIFIED (compile rerun) | Verifier rerun 2026-06-12: `mix compile --warnings-as-errors` → exit 0 against the current tree. Test comparison per 163-01-SUMMARY (documented evidence, not rerun — working tree carries unrelated in-flight nav-overhaul edits): baseline 886 tests / 3 failures; post ROLL-01 and post ROLL-03 both 886 tests / same 3 failures — **0 new**. The 3 pre-existing failures belong to other lanes: `V123CharterDocContractTest` (PROJECT.md posture) and `ExportsDocContractTest` ×2 (TimelineLive download anchors/labels). Focused surface_header + style_contract run: 28 tests, 0 failures |

**Score:** 7/7 truths verified

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| brandbook/logo-primary.svg | logo.ex | verbatim path copy | ✓ WIRED | 10/10 unique `d=` strings + arc identical; same viewBox |
| brandbook/favicon.svg | example-app favicon | byte copy | ✓ WIRED | `cmp` byte-identical |
| brandbook assets | README.md | `<picture>` prefers-color-scheme | ✓ WIRED | dark → logo-primary.svg, light → logo-primary-light.svg |

### Documented Deviation (deliberate, not a gap)

**Hidden `<text display="none">` compat node** — `logo.ex` line 102 carries a single non-rendering `<text class="tl-topbar__brand-wordmark" display="none">Threadline</text>`. Reason (163-01-SUMMARY, Rule-3 auto-fix): the in-flight nav-overhaul lane's uncommitted `surface_header_test.exs` asserts `>Threadline</text>` and the wordmark class against this component, and that file belongs to another lane. The visible wordmark is pure paths; the node never renders. Documented in the module comment with an explicit removal trigger: **drop it when the nav-overhaul lane lands and updates its contract to the path-based assertions.** Carried in the v1.35 milestone audit deferred ledger.

### Evidence

| Artifact | Status |
|----------|--------|
| `topbar-mark-evidence.png` / `.html` | EXISTS — standalone dark-token render at both brand-logo contract sizes (132×32, 148×36) + favicon at 16/32/64 under dark scheme |
| Commits `898b63f`, `2e8be6d`, `5fd61fc`, `c19fded`, `19486ae` | ALL EXIST on main, scopes verified |

### Gaps Summary

None. All three ROLL requirements verified; the single deviation is deliberate, documented, and tracked for removal.

---

_Verified: 2026-06-12T21:45:32Z_
_Verifier: Claude (gsd-verifier, milestone-audit backfill)_
