---
phase: 119-phx-gen-auth-integration-guide-lane
phase_name: phx.gen.auth Integration Guide & Lane
verified_at: "2026-05-27"
status: passed
score: 5/5
requirements:
  - AUTH-GUIDE-01
  - AUTH-GUIDE-02
  - AUTH-GUIDE-03
  - AUTH-LANE-01
  - AUTH-LANE-02
plans_verified:
  - 119-01
  - 119-02
---

# Phase 119 Verification Report

## Goal Achievement

**Status: passed**

Phase 119 goal — ship `guides/integrations/phx-gen-auth.md` as the phx.gen.auth integration cookbook and add **`phx-gen-auth-reference`** lane vocabulary to `guides/upgrade-path.md` (prose only, no matrix row) — is **achieved**. Both plans (119-01, 119-02) executed with no deviations per their SUMMARY files. All five v1.26 requirements scoped to Phase 119 are satisfied in the codebase.

Intentionally out of scope for this phase (deferred Phase 120): compatibility matrix row, root `phx_gen_auth_integration_test.exs`, and doc-contract locks citing the lane in CI.

---

## Plans Reviewed

| Plan | Summary | Requirements | Self-check |
|------|---------|--------------|------------|
| 119-01 | Created `guides/integrations/phx-gen-auth.md` (89 lines) | AUTH-GUIDE-01/02/03 | PASSED |
| 119-02 | Extended `guides/upgrade-path.md` prose-only lane vocabulary | AUTH-LANE-01/02 | PASSED |

---

## Must-Haves vs Codebase

| Truth / Artifact | Expected | Verified |
|------------------|----------|----------|
| phx-gen-auth cookbook exists | `guides/integrations/phx-gen-auth.md` ~70–95 lines | PASS — 89 lines |
| Host-owned `MyApp.AuditActor`, not Sigra adapter | No `Threadline.Integrations.Sigra` | PASS |
| Plug + operator snippets without opening sigra.md | Copy-paste fences in guide | PASS |
| Non-goals (no phx.gen.auth runner, no user tables, host pipelines) | `## Non-goals` section | PASS |
| upgrade-path names `phx-gen-auth-reference` as reference lane | Prose in Who / How to tell / vocabulary | PASS — 5 occurrences |
| No compatibility matrix row in Phase 119 | 3 data rows only | PASS |
| `sigra-reference` matrix row unchanged | `\| \`sigra-reference\` \| \`reference\` \|` | PASS |
| Not Sigra-compatible boundary | Explicit sentence in lane paragraph | PASS |
| ExDoc extras includes guide | `mix.exs` docs extras | PASS — commit `f2c074e` |

---

## Requirement Traceability

| Requirement | Status | Evidence |
|-------------|--------|----------|
| **AUTH-GUIDE-01** | PASS | `guides/integrations/phx-gen-auth.md` documents plug order (`fetch_session` → `fetch_current_scope` → `Threadline.Plug`), `MyApp.AuditActor` with `current_scope` pattern, and router `actor_fn` / `context_overrides_fn` callbacks; no Sigra adapter |
| **AUTH-GUIDE-02** | PASS | `threadline_operator_surface "/audit"` fence with `authorize_fn` admin gate (`role: "admin"`), plus `export_authorize_fn` footgun |
| **AUTH-GUIDE-03** | PASS | `## Non-goals` bullets: does not run `mix phx.gen.auth`, does not own user tables/sessions, does not secure routes without host pipeline plugs |
| **AUTH-LANE-01** | PASS | `guides/upgrade-path.md` adds `phx-gen-auth-reference` as `reference` lane in Who / How to tell / vocabulary / checklist; proof = guide + forthcoming root tests, not second example app |
| **AUTH-LANE-02** | PASS | Matrix still 3 rows (`capture-only`, `phoenix-surface`, `sigra-reference`); sigra row text unchanged; explicit "not Sigra-compatible" in phx-gen-auth lane paragraph |

`.planning/REQUIREMENTS.md` traceability table marks all five requirements **Complete** for Phase 119.

---

## Automated Verification (2026-05-27)

### 119-01 — `guides/integrations/phx-gen-auth.md`

| Check | Command | Result |
|-------|---------|--------|
| File exists | `test -f guides/integrations/phx-gen-auth.md` | PASS |
| HTML marker | `grep -F 'PHX-GEN-AUTH-03-INTEGRATION-GUIDE'` | PASS |
| Lane name | `grep -F 'phx-gen-auth-reference'` | PASS |
| Reference claim phrase | `grep -F 'reference claim, not a blanket support promise'` | PASS |
| Host AuditActor | `grep -F 'MyApp.AuditActor'` | PASS |
| Scope fetch | `grep -F 'fetch_current_scope'` | PASS |
| actor_fn literal | `grep -F 'actor_fn: &MyApp.AuditActor.actor_ref_from_conn/1'` | PASS |
| current_scope | `grep -F 'current_scope'` | PASS |
| No Sigra adapter | `grep -F 'Threadline.Integrations.Sigra'` (expect exit 1) | PASS |
| Operator surface | `grep -F 'threadline_operator_surface'` | PASS |
| authorize_fn | `grep -F 'authorize_fn'` | PASS |
| export_authorize_fn | `grep -F 'export_authorize_fn'` | PASS |
| Non-goals heading | `grep -F '## Non-goals'` | PASS |
| does not run | `grep -F 'does not run'` | PASS |
| mix phx.gen.auth | `grep -F 'mix phx.gen.auth'` | PASS |
| No premature test cite | `grep -F 'phx_gen_auth_integration_test'` (expect exit 1) | PASS |
| Line count | `wc -l` → **89** (range 70–95) | PASS |
| Section order | Prerequisites → Plug → Surface → Reference semantics → Non-goals | PASS |

### 119-02 — `guides/upgrade-path.md`

| Check | Command | Result |
|-------|---------|--------|
| Lane name present | `grep -F 'phx-gen-auth-reference'` | PASS (5 occurrences) |
| Guide cross-link | `grep -F 'guides/integrations/phx-gen-auth.md'` | PASS (4 occurrences) |
| Not Sigra-compatible | `grep -F 'not Sigra-compatible'` | PASS |
| No matrix row | `grep -F '| \`phx-gen-auth-reference\` |'` (expect exit 1) | PASS |
| sigra row unchanged | `grep -F '| \`sigra-reference\` | \`reference\` |'` | PASS |
| sigra link preserved | `grep -F 'guides/integrations/sigra.md'` | PASS |
| No test cite | `grep -F 'phx_gen_auth_integration_test'` (expect exit 1) | PASS |
| Matrix data rows | `grep -E '\| \`(capture-only\|phoenix-surface\|sigra-reference)\` \|'` | PASS — **3 rows** |

### ExDoc registration (f2c074e fix)

| Check | Command | Result |
|-------|---------|--------|
| mix.exs extras | `grep -F 'guides/integrations/phx-gen-auth.md' mix.exs` | PASS |
| Commit | `git show f2c074e --stat` | PASS — `fix(119): register phx-gen-auth guide in ExDoc extras allowlist` |

### Formatting

| Check | Command | Result |
|-------|---------|--------|
| Markdown formatted | `mix format --check-formatted guides/integrations/phx-gen-auth.md guides/upgrade-path.md` | PASS (exit 0) |

---

## Gaps Found

**None** within Phase 119 scope.

Expected follow-ons (not gaps for this phase):

- Phase 120: matrix row, `phx_gen_auth_integration_test.exs`, doc-contract locks (AUTH-PROOF-01/02/03)
- Phase 121: getting-started neutrality and discovery links (ADOPT-AUTH-01/02/03)

---

## Score

| Dimension | Score |
|-----------|-------|
| Requirements (5/5) | 5/5 |
| Plan must-haves | 5/5 |
| Automated acceptance criteria | 5/5 |
| **Overall** | **5/5 — passed** |

---

*Verified against plans 119-01-PLAN.md, 119-02-PLAN.md, summaries 119-01-SUMMARY.md, 119-02-SUMMARY.md, and `.planning/REQUIREMENTS.md`.*
