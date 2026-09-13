---
phase: 200-public-surface
reviewed: 2026-09-13T08:05:56Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - .planning/phases/200-public-surface/200-SECURITY.md
  - .planning/phases/200-public-surface/200-VALIDATION.md
  - examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts
  - examples/threadline_phoenix/mix.lock
  - lib/threadline/operator_surface/live/row_history_component.ex
  - mix.exs
  - mix.lock
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 200: Code Review Report

**Reviewed:** 2026-09-13T08:05:56Z
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

The exact seven-file delta from post-closeout commit `0833da97` was reviewed for correctness, security, dependency compatibility, test robustness, and report accuracy. The LiveView form-id repair is valid, the example lock is internally coherent, and the screenshot helper's removal of Playwright's discouraged `networkidle` state is supported by page-specific web assertions at every capture call.

The dependency remediation is not compatible with Threadline's published minimum runtime. The root graph now forces an OTP-27-only Hackney release while the project continues to promise and test OTP 26. Consequently the new security and validation reports close the dependency threat without evidence on the affected supported lane.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Hackney 4.7.4 breaks the published OTP 26 support floor

**Files:** `mix.exs:37-41,99`; `mix.lock:15,21`; `.planning/phases/200-public-surface/200-SECURITY.md:46,76-77`; `.planning/phases/200-public-surface/200-VALIDATION.md:140-147`

**Issue:** The commit changes Threadline's direct optional Hackney requirement from `~> 1.18` to `~> 4.0`, and the root lock selects Hackney 4.7.4 through ExAws 2.7.0. Hackney 4.7.4's own packaged README states `Erlang/OTP 27+` under Requirements, while this same `mix.exs` explicitly preserves OTP 26 as the supported minimum and the repository's minimum CI lane is Elixir 1.15/OTP 26. This makes the root dependency graph unsupported on a promised platform and breaks the documented S3 dependency lane for OTP-26 adopters. The local/current-toolchain regression counts and clean advisory scans recorded in `200-SECURITY.md` and `200-VALIDATION.md` do not establish minimum-lane compatibility, so T-200-14 cannot accurately remain closed. Upstream confirmation: [Hackney 4.7.4 requirements](https://hackney.hexdocs.pm/readme.html#requirements).

**Fix:** Either retain OTP 26 by moving the ExAws transport to a fixed dependency line/client that supports OTP 26 (for example, evaluate ExAws's Req backend), then regenerate the root lock and run the real Elixir 1.15/OTP 26 CI lane plus S3 adapter coverage and both audits; or deliberately raise Threadline's OTP floor to 27 as an adopter-visible breaking change and update the support matrix, CI, guides, and release notes. Until one path is proven, reopen T-200-14 and qualify/remove the closeout claims.

---

_Reviewed: 2026-09-13T08:05:56Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
