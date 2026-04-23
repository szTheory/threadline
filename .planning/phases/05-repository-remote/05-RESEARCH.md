# Phase 5 — Repository & remote — Research

**Phase:** 5 — Repository & remote  
**Question:** What do we need to know to plan verification and traceability for REPO-01–REPO-03?

## 1. Requirement semantics

| ID | Intent | Deterministic checks |
|----|--------|----------------------|
| **REPO-01** | `origin` points at canonical public GitHub repo | `git remote -v` shows fetch URL containing `github.com/szTheory/threadline` (HTTPS `.git` or SSH `git@github.com:szTheory/threadline.git` per CONTEXT D-05) |
| **REPO-02** | Package/docs URLs match canonical host | `mix.exs` contains `@source_url "https://github.com/szTheory/threadline"` (no `.git`); `source_url:` in `docs/0` matches `package/0` links map `"GitHub"` |
| **REPO-03** | `main` on `origin`, CI watches `main` | `git branch -vv` shows `main` tracking `origin/main`; `.github/workflows/ci.yml` has `branches: [main]` under `on.push` and `on.pull_request` |

## 2. Tooling and commands

- **`gh repo view szTheory/threadline --json name,url,description,homepageUrl`** — confirms GitHub metadata (description D-06, homepage D-07) without mutating git state.
- **`git remote get-url origin`** — single URL for scripts; normalize comparison by stripping optional `.git` and comparing host + path.
- **Equivalence:** Treat `https://github.com/szTheory/threadline`, `…/threadline.git`, and `git@github.com:szTheory/threadline.git` as one repo (CONTEXT D-05).

## 3. Execution posture (from CONTEXT)

Maintainer already ran `gh repo create szTheory/threadline … --remote=origin --push`. Plans should **still** encode grep/shell acceptance so `/gsd-execute-phase` and auditors can replay proof without assuming local git state.

## 4. Risks and false positives

- **Local-only clone:** Executor’s machine might use SSH while CONTEXT prefers HTTPS — acceptance must allow both forms against the same `szTheory/threadline` path.
- **CI file drift:** If someone changes branch filters, REPO-03 fails — plans should grep literal `[main]` in `ci.yml`.
- **Hex/docs:** `homepageUrl` may point at hexdocs before publish; 404 is acceptable per CONTEXT — do not gate on HTTP 200 to hexdocs.

## 5. Plan shape recommendation

- **One wave, one plan** is sufficient: read-only verification tasks + optional `gh repo view` JSON check.
- **No schema push** — no ORM migrations in this phase.

---

## Validation Architecture

**Nyquist / execution feedback**

- **Automated (local):** `mix ci.all` remains the project quick gate (format, credo, test) — run after any accidental edit to `mix.exs` or workflow YAML; not required to prove REPO URLs but catches typos.
- **Manual / CLI:** `git remote -v`, `git branch -vv`, `gh repo view` — primary evidence for REPO-01 and GitHub metadata.
- **Sampling:** After each task that touches `mix.exs` or `.github/workflows/ci.yml`, run `mix verify.format` (fast) or full `mix ci.all` if those files changed.

## RESEARCH COMPLETE
