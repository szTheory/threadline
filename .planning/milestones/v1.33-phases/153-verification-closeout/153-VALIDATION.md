---
phase: 153
slug: verification-closeout
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-06
---

# Phase 153 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell verification using existing CLI tools |
| **Config file** | none |
| **Quick run command** | `jq empty brandbook/tokens.json && find brandbook -name '*.svg' -print0 | xargs -0 xmllint --noout` |
| **Full suite command** | Refresh the full command table from `153-RESEARCH.md` and record output in `153-VERIFICATION.md` |
| **Estimated runtime** | ~60 seconds plus browser screenshot time |

## Sampling Rate

- **After every task commit:** Run `jq empty brandbook/tokens.json && find brandbook -name '*.svg' -print0 | xargs -0 xmllint --noout`
- **After every plan wave:** Refresh all parse, browser, file-boundary, historical-frame, and size checks from `153-RESEARCH.md`
- **Before `$gsd-verify-work`:** `153-VERIFICATION.md` must contain current-tree evidence for every `BRAND-QA-02` check
- **Max feedback latency:** 120 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 153-01-01 | 01 | 1 | BRAND-QA-02 | T-153-01 | Evidence is current-tree command output, not stale prior-phase text | CLI parse/inventory | `jq empty brandbook/tokens.json && find brandbook -name '*.svg' -print0 | xargs -0 xmllint --noout` | yes | pending |
| 153-01-02 | 01 | 1 | BRAND-QA-02 | T-153-02 | Browser evidence renders from local files without network/build dependencies | browser/manual evidence | `agent-browser open file:///Users/jon/projects/threadline/brandbook/index.html` plus desktop/mobile screenshots | yes | pending |
| 153-01-03 | 01 | 1 | BRAND-QA-02 | T-153-03 | Closeout does not overclaim deferred rollout/legal work | source assertion | `rg -n "README-ROLLOUT-01|HEXDOCS-BRAND-01|LANDING-01|legal|trademark|deferred" .planning/phases/153-verification-closeout/153-VERIFICATION.md` | no | pending |

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- `jq` is available.
- `xmllint` is available.
- `agent-browser` is available.
- `file`, `wc`, and `rg` are available.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Desktop/mobile screenshot inspection | BRAND-QA-02 | Screenshot capture is automated, but visual judgment of missing local assets or broken layout needs inspection | Open the `/tmp/threadline-v133-brandbook-phase153-*.png` screenshot paths recorded in `153-VERIFICATION.md` and confirm the page rendered with local assets present. |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-06

