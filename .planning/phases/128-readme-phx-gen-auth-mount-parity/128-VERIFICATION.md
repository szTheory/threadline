---
status: passed
phase: 128-readme-phx-gen-auth-mount-parity
verified: 2026-05-28
score: 5/5
---

# Phase 128 Verification Report

**Phase goal:** README Quick Start + phx-gen-auth mount parity for first-hour adopters (README-01, README-02, TRIG-01, AUTH-MOUNT-01, AUTH-MOUNT-02).

## Requirement Traceability

All five phase requirement IDs appear in plan frontmatter and `REQUIREMENTS.md` traceability table (Phase 128, Complete).

| ID | Plan | REQUIREMENTS.md | Status |
|----|------|-----------------|--------|
| README-01 | 128-01 | ✓ Phase 128 | ✓ |
| README-02 | 128-01 | ✓ Phase 128 | ✓ |
| TRIG-01 | 128-01 | ✓ Phase 128 | ✓ |
| AUTH-MOUNT-01 | 128-02 | ✓ Phase 128 | ✓ |
| AUTH-MOUNT-02 | 128-02 | ✓ Phase 128 | ✓ |

**Unmapped requirement IDs:** 0

## Requirements Verified

| ID | Requirement | Status | Evidence |
|----|-------------|--------|----------|
| README-01 | Quick Start documents `config :threadline, ecto_repos: [MyApp.Repo]` before install with getting-started §2 cross-link | ✓ | `README.md` L62–70 (step 2); `getting-started-saas.md#configure-threadline` link; ecto_repos at L67 before `mix threadline.install` at L75 |
| README-02 | Doc-contract test locks ecto_repos literal and ordering in Quick Start slice | ✓ | `readme_doc_contract_test.exs` L225–237; `section_slice/3` L272–284; `literal_idx < install_idx` assertion |
| TRIG-01 | Quick Start trigger step uses posts-only command with SSOT cross-links; no divergent multi-table fiction | ✓ | `README.md` L79–86 (`--tables posts`, getting-started §4 + production-checklist §1); contract test L239–248 refutes `users,posts,comments` |
| AUTH-MOUNT-01 | phx-gen-auth guide mount uses scope-first `authorize_fn` callback ref consistent with integration proof | ✓ | `guides/integrations/phx-gen-auth.md` L63–84 (`MyApp.Audit`, `&MyApp.Audit.authorize_operator/1`, `is_admin: true`); `PhxGenAuthReference.Audit` mirrors guide L25–40; no `role: "admin"` in guide |
| AUTH-MOUNT-02 | Doc-contract test locks mount literals and refutes legacy inline role pattern | ✓ | `phx_gen_auth_doc_contract_test.exs` L44–72 (surface slice asserts + refutes legacy `current_user.role` pattern) |

## Plan 01 Must-Haves (README Quick Start)

| Truth / artifact | Status | Evidence |
|------------------|--------|----------|
| Step 2 documents `ecto_repos` before `mix threadline.install` | ✓ | `README.md` L62–77 |
| Trigger step uses `--tables posts` only with getting-started §4 + production-checklist §1 cross-links | ✓ | `README.md` L79–86 |
| Doc-contract tests scoped to Quick Start slice; lock ordering and refute multi-table fiction | ✓ | `@quick_start_start` / `@quick_start_end`; tests L225–248 |
| Artifact: `README.md` (6-step Quick Start) | ✓ | Steps 1–6 L52–98 |
| Artifact: `test/threadline/readme_doc_contract_test.exs` | ✓ | 20 tests in file; 2 new phase-128 locks |

## Plan 02 Must-Haves (phx-gen-auth mount)

| Truth / artifact | Status | Evidence |
|------------------|--------|----------|
| Mount uses `authorize_fn: &MyApp.Audit.authorize_operator/1` with scope-first lookup and `is_admin: true` gate | ✓ | Guide L63–84; Reference semantics item 3 L92 |
| Integration tests: admin allow via scope, non-admin 403, legacy `current_user` fallback | ✓ | `phx_gen_auth_integration_test.exs` L90–124 |
| Doc-contract locks surface-section literals; refutes legacy inline role match | ✓ | `phx_gen_auth_doc_contract_test.exs` L52–71 |
| Artifact: `guides/integrations/phx-gen-auth.md` | ✓ | MyApp.Audit + callback-ref mount |
| Artifact: `test/threadline/integrations/phx_gen_auth_integration_test.exs` | ✓ | `PhxGenAuthReference.Audit`; no `guide_authorize/1` |
| Artifact: `test/support/phx_gen_auth_fixtures.ex` | ✓ | `admin_scope_user/0`, `member_scope_user/0` L35–36 |
| Artifact: `test/threadline/integrations/phx_gen_auth_doc_contract_test.exs` | ✓ | 3 tests, surface slice locks |

## Automated Checks

```text
mix test test/threadline/readme_doc_contract_test.exs \
         test/threadline/integrations/phx_gen_auth_integration_test.exs \
         test/threadline/integrations/phx_gen_auth_doc_contract_test.exs
→ 33 tests, 0 failures
```

Acceptance greps (plan verification blocks):

- `config :threadline, ecto_repos: [MyApp.Repo]` in README — match
- `getting-started-saas.md#configure-threadline` in README — match
- `mix threadline.gen.triggers --tables posts` in README — match
- `users,posts,comments` absent from Quick Start slice — confirmed
- `defmodule MyApp.Audit`, `authorize_fn: &MyApp.Audit.authorize_operator/1`, `is_admin: true` in phx-gen-auth guide — match
- `role: "admin"` absent from phx-gen-auth guide — confirmed
- `defp guide_authorize` absent from integration test — confirmed

## Human Verification

None required. Optional: copy-paste Quick Start steps 2–4 into a fresh Phoenix app and confirm `mix threadline.install` resolves repo; mount `authorize_fn` in a phx-gen-auth host with `is_admin` user field. Automated doc-contract and integration tests cover the same contracts.

## Gaps

None — all five requirements satisfied with current-tree evidence.
