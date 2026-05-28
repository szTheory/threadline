# Phase 123: First-Hour Config — Research

**Researched:** 2026-05-28  
**Phase:** 123-first-hour-config  
**Requirements:** CFG-01, CFG-02, CFG-03  
**Context SSOT:** `123-CONTEXT.md` (user decisions D-01–D-21)

---

## 1. Executive summary

Phase 123 closes the **first-hour `ecto_repos` footgun**: Mix tasks and operator-surface fallbacks read `Application.get_env(:threadline, :ecto_repos)`, but `guides/getting-started-saas.md` never teaches that key. `mix threadline.install` (§3) uses **host** `config :my_app, ecto_repos` and succeeds — adopters conclude they are fully wired.

| Wave | Plan | Delivers |
|------|------|----------|
| **Wave 1** | `123-01-PLAN` | CFG-01 getting-started `### Configure Threadline` + CFG-02 doc-contract in `getting_started_saas_doc_contract_test.exs` |
| **Wave 1** (parallel) | `123-02-PLAN` | CFG-03 production-checklist prerequisite section + dedicated checklist doc-contract |

**Planning takeaway:** Docs-only phase — no library code changes. Dual-contract pattern (getting-started = snippet + brief why; checklist = checkbox + cross-link). Execute after Hex **0.6.0** live (Phase 122 complete).

---

## 2. Current state audit

### 2.1 Config gap

| Signal | Host `:ecto_repos` | `:threadline, :ecto_repos` |
|--------|-------------------|---------------------------|
| `mix threadline.install` | Uses `Mix.Project` app env | Not required |
| `mix threadline.health.coverage` (and 9+ tasks) | Not used | **Required** via `resolve_repo!/0` |
| Operator surface mount fallback | Optional `repo:` assign | Falls back to `Application.get_env(:threadline, :ecto_repos) \|> hd()` |
| Example app `config.exs` | Line 11 | Line 14 — both set |
| Getting-started §2–§6 | Implied via Phoenix/Ecto | **Absent** |
| Production checklist | §1 mentions `verify_coverage` | **No prerequisite for `:threadline` key** |

Error string (consistent across tasks): `Threadline: set :ecto_repos in config — no Ecto repository is configured to run ...`

### 2.2 Getting-started structure (insertion point)

Current flow after §2 `mix deps.get`:

- §3 Install audit schema (`mix threadline.install`) — **succeeds without `:threadline` config**
- §7 first `resolve_repo!` consumer (`mix threadline.health.coverage`)
- §8 lists mix fallbacks that all need `:threadline, :ecto_repos`

**Locked insertion:** `### Configure Threadline` between end of §2 (after `mix deps.get` fence) and `## 3. Install the audit schema`.

### 2.3 Doc-contract landscape

| Test file | In `mix verify.doc_contract`? | Phase 123 role |
|-----------|------------------------------|----------------|
| `getting_started_saas_doc_contract_test.exs` | Yes | CFG-02 — extend with literal + `:binary.match` ordering |
| `stg_doc_contract_test.exs` | **No** | Do **not** fold CFG-03 here (D-16) |
| New `production_checklist_doc_contract_test.exs` | Add to alias | CFG-03 — checklist literal + backlink |

Existing pattern: `getting-started-sigra-reference-fence` ordering uses `:binary.match` — reuse for CFG-02.

### 2.4 Production checklist structure

Intro paragraphs (lines 1–5) → **`## Host repo wiring (prerequisite)`** (new, unnumbered) → `## 1. Capture and triggers` (unchanged ID).

Checklist content per D-12/D-13: checkbox confirming literal, mix-task + operator-fallback scope, link to getting-started anchor; multi-DB note (first repo only).

---

## 3. Implementation approach

### CFG-01 — Getting-started prose

**Snippet (locked):**

```elixir
config :threadline, ecto_repos: [MyApp.Repo]
```

**Prose (3 bullets per D-06):**

1. Threadline Mix tasks and operator-surface fallbacks resolve from `config :threadline, :ecto_repos`, not host `:ecto_repos` alone.
2. `mix threadline.install` still uses host `:ecto_repos` for migration path — different surfaces.
3. Pointer to `guides/production-checklist.md` for full mix-task inventory.

**Footnote (D-08):** List audit-holding repo **first**; Threadline uses **first element only** (`List.first` / `hd`) — unlike Ecto mix iterating all repos.

**Reject:** Multi-repo example block; full §7–§9 task list in §2.

### CFG-02 — Doc contract

Add dedicated test `"getting-started documents threadline ecto_repos before resolve_repo consumers"`:

- Literal: `config :threadline, ecto_repos: [MyApp.Repo]`
- `:binary.match` — literal before `## 7. Check trigger coverage`
- `:binary.match` — literal before `getting-started-sigra-reference-fence`
- **Preferred:** literal before `## 3. Install the audit schema`
- Rationale fragment: contains `Mix tasks` and `ecto_repos`

### CFG-03 — Production checklist + contract

**Checklist section** (after intro, before §1):

```markdown
## Host repo wiring (prerequisite)

- [ ] `config :threadline, ecto_repos: [MyApp.Repo]` is set in `config/config.exs` (see [getting-started §2 Configure Threadline](getting-started-saas.md#configure-threadline)). Required for `mix threadline.*` tasks that call `resolve_repo!/0` and for operator-surface Mix fallbacks when LiveView is not mounted.
- [ ] Multi-database hosts: list only the repo that holds audit tables first; pass `repo:` on mount and programmatic APIs when using a non-default repo.
```

**Contract test** in new file — assert literal or stable anchor, backlink to `getting-started-saas.md` with `#configure-threadline` or equivalent.

**Optional:** One sentence in §5 Export pointing to Host repo wiring (D-14) — no second checkbox.

---

## 4. Ecosystem alignment (research only)

| Product | Pattern | Threadline alignment |
|---------|---------|---------------------|
| Oban | `repo:` in install chapter | Configure library before tasks (D-17) |
| ExAudit | `ecto_repos` app config | Same key name |
| Ecto | Single-repo happy path in getting started | Footnote for multi-repo in ops doc only |

---

## 5. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Config only in Sigra optional fence | CFG-02 ordering vs sigra fence marker |
| Duplicate prose in checklist | D-11: checkbox + link only |
| Renumbering checklist §1–§7 | Unnumbered prerequisite band (D-10) |
| `stg_doc_contract` conflation | Separate `production_checklist_doc_contract_test.exs` (D-16) |

---

## 6. Verification commands (cite in PLAN.md)

```bash
# Per-plan / wave closeout
mix test test/threadline/getting_started_saas_doc_contract_test.exs
mix test test/threadline/production_checklist_doc_contract_test.exs
mix verify.doc_contract
mix ci.all
```

---

## 7. Validation Architecture (Nyquist)

| Requirement | Automated layer | Human layer |
|-------------|-----------------|-------------|
| **CFG-01** | Doc contract literal + ordering; manual read of inserted subsection | Spot-check rendered ExDoc anchor |
| **CFG-02** | `getting_started_saas_doc_contract_test.exs` assertions | — |
| **CFG-03** | `production_checklist_doc_contract_test.exs` + link target exists | — |

**Nyquist:** Fully machine-verifiable — no registry or maintainer attestation gate. Wave 0 not required (ExUnit infrastructure exists).

**Sampling:** After each plan commit, run targeted test file; wave closeout runs `mix verify.doc_contract`.

---

## RESEARCH COMPLETE
