---
phase: 7
slug: hex-0-1-0
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-23
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (via Mix) |
| **Config file** | `mix.exs` aliases, `config/test.exs` |
| **Quick run command** | `MIX_ENV=test mix ci.all` |
| **Full suite command** | Same as quick for this phase — `mix ci.all` is the project contract |
| **Estimated runtime** | ~1–3 minutes (depends on Postgres for tests) |

---

## Sampling rate

- **After every 07-01 task that edits `mix.exs` or `CHANGELOG.md`:** `MIX_ENV=test mix ci.all`
- **After 07-01 plan complete (before tag):** `MIX_ENV=dev mix deps.get` then `MIX_ENV=dev mix docs`, then `mix hex.build` and `mix hex.build --unpack`, then `mix hex.publish --dry-run`
- **Before marking HEX-04 done:** `mix hex.info threadline` shows `0.1.0`
- **Max feedback latency:** Bounded by local `mix ci.all` + docs + hex build (developer machine)

---

## Per-task verification map

| Task ID | Plan | Wave | Requirement | Threat ref | Secure behavior | Test type | Automated command | File exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | HEX-01 | T-07-01-01 | No secret in repo | grep | `grep -F '@version "0.1.0"' mix.exs` | ✅ | ⬜ |
| 07-01-02 | 01 | 1 | HEX-02 | T-07-01-02 | N/A | grep + manual read | `grep -F '## [0.1.0]' CHANGELOG.md` | ✅ | ⬜ |
| 07-01-03 | 01 | 1 | HEX-01, HEX-02 | T-07-01-03 | N/A | Mix | `MIX_ENV=test mix ci.all` | ✅ | ⬜ |
| 07-01-04 | 01 | 1 | HEX-01 | T-07-01-04 | N/A | Mix | `MIX_ENV=dev mix docs` | ✅ | ⬜ |
| 07-01-05 | 01 | 1 | HEX-01 | T-07-01-05 | N/A | Mix | `mix hex.build` | ✅ | ⬜ |
| 07-02-01 | 02 | 2 | HEX-03 | T-07-02-01 | No token in logs | manual | `git tag -n1 v0.1.0` | ⬜ W0 | ⬜ |
| 07-02-02 | 02 | 2 | HEX-03 | T-07-02-02 | SSH/HTTPS auth only | manual | `git ls-remote origin refs/tags/v0.1.0` | ⬜ W0 | ⬜ |
| 07-02-03 | 02 | 2 | HEX-04 | T-07-02-03 | Hex auth local only | manual | `mix hex.info threadline` | ⬜ W0 | ⬜ |

*Wave 0: no new test files — existing suite covers code health.*

---

## Wave 0 requirements

- Existing infrastructure covers all phase requirements — no new `test/` stubs required for Hex release mechanics.

---

## Manual-only verifications

| Behavior | Requirement | Why manual | Test instructions |
|----------|-------------|------------|-------------------|
| Annotated tag on release commit | HEX-03 | Needs gpg/ssh optional signing choices | `git tag -a v0.1.0 -m 'Release v0.1.0'` on the HEX-01/02 commit; verify `git cat-file -t v0.1.0` → `tag` |
| Push tag to origin | HEX-03 | Network + credentials | `git push origin v0.1.0` |
| Publish to Hex | HEX-04 | API key / password | `mix hex.publish` after dry-run; confirm no errors |
| Hex registry shows version | HEX-04 | External registry | `mix hex.info threadline` |

---

## Validation sign-off

- [ ] All tasks have automated verify or manual table above
- [ ] Sampling continuity: 07-01 uses `mix ci.all` between edits
- [ ] No watch-mode flags
- [ ] `nyquist_compliant: true` set in frontmatter after execution wave complete

**Approval:** pending
