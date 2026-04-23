# Phase 5: Repository & remote - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish the **canonical public GitHub repository** for Threadline, configure **`origin`** to that host, keep **`mix.exs` / docs URLs** aligned with REPO-02, and ensure **`main` exists on `origin`** as the integration branch CI monitors (REPO-03). Scope is REPO-01–REPO-03 only — CI job health is Phase 6; Hex publish is Phase 7.

**Execution note:** Repository was created and initial `main` push completed via `gh repo create … --push` on 2026-04-23; downstream plans should still spell verification steps (remote URL check, requirement traceability) even when the happy path is already done.

</domain>

<decisions>
## Implementation Decisions

### Canonical host and URLs

- **D-01:** Canonical GitHub repository is **`szTheory/threadline`** — base URL `https://github.com/szTheory/threadline`. No org transfer or alternate canonical URL for v1.1.
- **D-02:** **`@source_url` in `mix.exs`** (and ExDoc / package links derived from it) stay as **`https://github.com/szTheory/threadline`** without a `.git` suffix — matches Hex and README conventions.

### Git remote (`origin`)

- **D-03:** Use **`origin`** with **HTTPS** (`https://github.com/szTheory/threadline.git`). Rationale: matches `gh` default for this account (“Git operations protocol: https”), avoids SSH-key friction for new contributors, and pairs cleanly with the canonical `https://` package URL in `mix.exs`.
- **D-04:** **Single remote:** only **`origin`** on the canonical repo for the maintainer’s primary clone — no `upstream` fork layout unless the workflow later explicitly forks.

### URL equivalence (verification)

- **D-05:** Treat **`https://github.com/szTheory/threadline`** and **`https://github.com/szTheory/threadline.git`** (and the same paths with `git@github.com:szTheory/threadline.git`) as the **same repository** for REPO-01 / REPO-02 checks — `git remote -v` may show the `.git` suffix while `mix.exs` does not.

### GitHub repository metadata

- **D-06:** Repository **description** (set at create time; update with `gh repo edit` if needed): *Audit platform for Elixir/Phoenix — trigger-backed row capture with actor, intent, and request context.*
- **D-07:** **Homepage** on GitHub: **`https://hexdocs.pm/threadline`** (package docs; may 404 until first publish — acceptable as declared home for the library).

### Branch and CI alignment

- **D-08:** **Default branch** on GitHub is **`main`**. Local **`main` tracks `origin/main`** after push. REPO-03 satisfied when **`.github/workflows/ci.yml` on `main` lists `branches: [main]`** (already true) and **`main` is pushed to `origin`** (done at repo creation).

### GitHub settings (CI / Actions)

- **D-09:** **No custom org-level policy assumed** — for a **public** repo under a personal account, **Actions are enabled by default**; the workflow run should appear after the first push without changing **Settings → Actions → General** unless the account previously disabled Actions.
- **D-10:** If workflows never appear or stay pending: check **Settings → Actions → General** (“Allow all actions and reusable workflows” or org-equivalent), and the **Actions** tab for policy banners. No branch protection or secrets are required for this repo’s current CI (read-only `contents`, `mix deps.get` + verify jobs only).

### Claude's Discretion

Minor edits to GitHub description wording, optional **`gh repo edit`** field tweaks, and exact verification script wording in plans — within D-01–D-08.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **REPO-01**, **REPO-02**, **REPO-03** (v1.1 Repository & hosting).
- `.planning/ROADMAP.md` — Phase 5 goal, success criteria, **Canonical refs** on the Phase 5 section.

### Repository and CI

- `mix.exs` — `@source_url`, `package/0`, `docs/0` URL alignment.
- `README.md` — CI badge and any GitHub links.
- `.github/workflows/ci.yml` — `on.push.branches` / `pull_request.branches` for **main**.

### Prior milestone context (URL / docs continuity)

- `.planning/milestones/v1.0-phases/04-documentation-release/04-CONTEXT.md` — Hex readiness, `source_ref` policy, README vs HexDocs roles (must stay consistent with canonical repo).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`mix.exs`**: `@source_url "https://github.com/szTheory/threadline"` already matches canonical host — no URL rewrite required for REPO-02 unless the canonical host changes.
- **`README.md`**: CI badge targets `szTheory/threadline` Actions workflow — aligned with D-01.

### Established patterns

- **CI contract**: Stable job keys `verify-format`, `verify-credo`, `verify-test` per workflow header comments; **push/PR to `main`** only.

### Integration points

- **`origin`**: Added by `gh repo create … --remote=origin`; **`main` → `origin/main`** tracking set by the same command.

</code_context>

<specifics>
## Specific Ideas

- Maintainer confirmed **`https://github.com/szTheory/threadline`** as the canonical URL; asked to use **`gh` CLI** to create the repo, push **`main`**, and set **description** (and homepage). Executed: `gh repo create szTheory/threadline --public --description "…" --homepage "https://hexdocs.pm/threadline" --source=. --remote=origin --push`.
- **No preference on HTTPS vs SSH** for `origin` — chose **HTTPS + single `origin`** as default best practice for this setup.

</specifics>

<deferred>
## Deferred Ideas

- **Phase 6:** Confirm latest **`main`** run is green on GitHub; README CI discovery (CI-01–CI-03).
- **Phase 7:** Version **`0.1.0`**, changelog, tag **`v0.1.0`**, **`mix hex.publish`** — out of scope here.

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches.

</deferred>

---

*Phase: 05-repository-remote*
*Context gathered: 2026-04-23*
