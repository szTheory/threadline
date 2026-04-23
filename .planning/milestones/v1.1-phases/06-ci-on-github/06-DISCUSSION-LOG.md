# Phase 6: CI on GitHub - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `06-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-23
**Phase:** 6 — CI on GitHub
**Areas discussed:** CI-02 green definition; CI-03 README/docs; Scope of `ci.yml` edits; Proving CI-02 in UAT

---

## CI-02 — What counts as “green”

| Option | Description | Selected |
|--------|-------------|----------|
| Main-only SHA truth | Tip of `main` has completed run with all three jobs `success` for that SHA; re-runs OK | ✓ |
| PR run as substitute for main | Treat PR green as satisfying CI-02 | |
| Loose / badge-only | Visual badge without SHA alignment | |

**User's choice:** All areas selected; delegated to research-backed synthesis — **strict main@HEAD SHA alignment** with success after re-run, cancelled/failed excluded until green.
**Notes:** Research drew on GitHub Actions semantics, branch protection footguns (renamed jobs), fork approval, Rust bors-style patterns (deferred), Ruby badge/`main` rename lessons.

---

## CI-03 — README and contributor discovery

| Option | Description | Selected |
|--------|-------------|----------|
| Badge + Actions prose + CONTRIBUTING | README one-liner to Actions hub; CONTRIBUTING already has CI parity | ✓ |
| Badge only | Minimal README | |
| Long README CI section | Duplicate CONTRIBUTING | |

**User's choice:** Research-backed — **badge + short plain text** + existing **CONTRIBUTING** depth; YAML-only links insufficient for UX/a11y.
**Notes:** Hex landing is README-first; ExDoc is not primary for “where CI runs.”

---

## Scope of `.github/workflows/ci.yml` edits

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal edits (C) | App code first; workflow for runner/actions/services/cache glue only; pins fixed unless explicit decision | ✓ |
| Freeze workflow entirely | Only app fixes | |
| Liberal workflow changes | Includes pin bumps without gate | |

**User's choice:** **Minimal edits** aligned with REQUIREMENTS out-of-scope on pin bumps; **erlef/setup-beam** action bump allowed without Elixir/OTP value change when needed for runner compatibility.

---

## Proving CI-02 (verification / UAT)

| Option | Description | Selected |
|--------|-------------|----------|
| `gh` + SHA match + run URL | Reproducible, auditable | ✓ |
| GitHub UI only | Manual, acceptable for logs | (fallback) |
| Badge as proof | Insufficient | ✗ |

**User's choice:** **`gh run list` / `gh run view`** (or equivalent) with **`origin/main` SHA** matched to run **head SHA**; badge not sole proof.

---

## Claude's Discretion

Minor wording for README/CONTRIBUTING links; optional exact `gh` JSON shape in verification doc.

## Deferred Ideas

Merge queue; rulesets-as-code; CI matrix expansion — see `06-CONTEXT.md` `<deferred>`.
