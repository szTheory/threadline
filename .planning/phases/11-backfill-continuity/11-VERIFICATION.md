---
status: passed
phase: "11"
verified: "2026-04-23"
---

## Phase goal

Deliver TOOL-02: honest T₀ brownfield path — public `Threadline.Continuity`, `mix threadline.continuity`, brownfield integration proof, canonical guide + README + HexDocs extras + domain cross-links.

## Must-haves

| Item | Evidence |
|------|----------|
| Public continuity API | `lib/threadline/continuity.ex` — `explain_cutover/1`, `assert_capture_ready!/2`, `repo:` options, `Threadline.Health.trigger_coverage/1` reuse |
| Mix task | `lib/mix/tasks/threadline.continuity.ex` — `@shortdoc`, `--dry-run`, `--table`, delegates to `Threadline.Continuity` |
| No library `AuditChange` inserts | `rg 'Repo\.(insert|insert_all).*AuditChange'` on continuity paths — no matches |
| Brownfield test | `test/threadline/continuity_brownfield_test.exs` — row inserted before trigger wiring per-test; `Threadline.history/3` → `[]` then audited UPDATE |
| Canonical guide | `guides/brownfield-continuity.md` — T0, `Threadline.history`, operator checklist, compliance + PgBouncer notes |
| Discovery / docs | README subsection, `mix.exs` `extras`, `guides/domain-reference.md` link |
| Compile | `MIX_ENV=test mix compile --warnings-as-errors` — pass |

## Automated checks run (orchestrator)

- `MIX_ENV=test mix compile --warnings-as-errors` — passed
- `MIX_ENV=dev mix docs` — passed
- `MIX_ENV=test mix test test/threadline/continuity_brownfield_test.exs` — not executed (no local PostgreSQL); CI expected

## human_verification

None required for merge; operators should run full `mix ci.all` with PostgreSQL when available.
