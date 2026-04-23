# Phase 5: Repository & remote - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `05-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-23
**Phase:** 5-Repository & remote
**Areas discussed:** Canonical URL, origin shape, URL rules, GitHub metadata, branch/CI alignment, GitHub Actions settings

---

## Canonical host and URLs

| Option | Description | Selected |
|--------|-------------|----------|
| `szTheory/threadline` | Keep `mix.exs` / docs URL as canonical | ✓ |
| Different org/path | Planned transfer before Hex | |

**User's choice:** Confirmed GitHub URL `https://github.com/szTheory/threadline` is fine; push and description via `gh` CLI.
**Notes:** Executed `gh repo create` with public repo, description, homepage `hexdocs.pm/threadline`, `--push`.

---

## Git remote (`origin`)

| Option | Description | Selected |
|--------|-------------|----------|
| HTTPS, single `origin` | Align with `gh` https protocol; simple contributor story | ✓ |
| SSH `origin` | Key-based | |
| Fork layout (`upstream` + `origin`) | Fork-based contribution | |

**User's choice:** Defer to agent — **HTTPS + single `origin`** (recommended default).
**Notes:** User: “no pref on origin shape u choose best practices.”

---

## URL equivalence and verification

| Option | Description | Selected |
|--------|-------------|----------|
| Logical equivalence | `.git` / `git@` variants OK vs `https://…/threadline` | ✓ |
| Byte-identical strings only | Force `mix.exs` to match `git remote -v` literally | |

**User's choice:** Agent recommendation — **logical same-repo** checks.

---

## GitHub Actions / settings

| Topic | User input | Resolution |
|-------|------------|------------|
| Required settings | “if there are options… lmk” | Documented in CONTEXT: default public repo needs no extra settings; troubleshooting if Actions disabled |

**Notes:** First push triggered CI run (`gh run list` showed `in_progress` on `main`).

---

## Claude's Discretion

Minor `gh repo edit` / description tweaks; exact verification command wording in plans.

## Deferred Ideas

- Phase 6–7 work explicitly deferred per milestone split.
