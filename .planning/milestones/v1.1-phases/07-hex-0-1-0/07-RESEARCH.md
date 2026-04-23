# Phase 7 — Technical research: Hex 0.1.0

**Phase:** 7 — Hex 0.1.0  
**Question:** What do we need to know to plan a correct first Hex release for `threadline` **0.1.0**?

---

## Current repo snapshot (planning-time)

- `mix.exs` sets `@version "0.1.0-dev"`. `doc_source_ref/0` returns `"main"` for pre-releases and `"v#{@version}"` when `Version.parse` shows empty `pre` (release).
- `package/0` lists explicit `files:`; `links` include GitHub and Changelog URL built from `doc_source_ref()`.
- `CHANGELOG.md` has `[Unreleased]`, stub `## [0.1.0]` with placeholder bullets — must become a dated release section per CONTEXT D-01–D-04.

---

## Hex / Mix publishing (authoritative behaviors)

1. **`mix hex.build`** — Produces the tarball that would upload; catches missing `files:` entries and bad metadata before network I/O.
2. **`mix hex.build --unpack`** — Inspects tarball contents; recommended in CONTEXT D-10 to verify `lib/`, guides, and metadata files are packaged.
3. **`mix hex.publish --dry-run`** — Hex client validation without upload; last gate before real publish.
4. **Real publish** — Requires Hex account and local auth (`mix hex.user whoami`); may prompt for package vs docs; maintainer-only per D-17.
5. **Version discipline** — Release commit must be the first tree where `@version` is exactly `0.1.0` (no `-dev`); tag `v0.1.0` must point to that commit (D-07). Retagging published versions is forbidden (D-16).

---

## Pre-publish “gold bar” (from CONTEXT, ordered)

Aligns with common Elixir OSS practice (Jason, Plug, etc.): dev-only ExDoc means **`MIX_ENV=dev mix deps.get`** before `mix docs`.

| Step | Command | Why |
|------|---------|-----|
| 1 | `MIX_ENV=dev mix deps.get` | Pull `ex_doc` and dev-only deps for docs. |
| 2 | `MIX_ENV=test mix ci.all` | Parity with CI: format, credo, compile `--warnings-as-errors`, tests. |
| 3 | `MIX_ENV=dev mix docs` | ExDoc + extras must build. |
| 4 | `mix hex.build` then `mix hex.build --unpack` | Tarball sanity. |
| 5 | `mix hex.publish --dry-run` | Hex-side checks without upload. |

After publish: **`mix hex.info threadline`** must list **0.1.0** (HEX-04).

---

## Footguns

| Risk | Mitigation |
|------|------------|
| Publishing with wrong `files:` (missing `lib/` subtree) | `hex.build --unpack` + list contents. |
| Docs fail only in `:dev` | Never validate docs only in `:test`. |
| `source_ref` still `main` on release | Release version must parse with empty `pre` so `doc_source_ref()` → `v0.1.0`; tag must exist before consumers rely on “View source” links. |
| Tag not pushed | Explicit `git push origin v0.1.0` (D-08). |

---

## Plan split recommendation

- **Plan 07-01** — Repository edits only: `mix.exs` version bump, `CHANGELOG.md` 0.1.0 section (HEX-01, HEX-02). Fully automatable / autonomous.
- **Plan 07-02** — Maintainer operations: annotated tag, pushes, Hex auth, publish, post-verify `hex.info` (HEX-03, HEX-04). `autonomous: false` — credentials and irreversible publish.

---

## Validation Architecture

This phase is **release and distribution**, not feature code. Automated sampling maps to the gold-bar commands and existing CI:

| Dimension | Approach |
|-----------|----------|
| **Unit / integration** | No new application logic; existing `MIX_ENV=test mix ci.all` remains the regression gate after `mix.exs` / changelog edits. |
| **Docs** | `MIX_ENV=dev mix docs` after version bump proves ExDoc + extras. |
| **Package** | `mix hex.build` + `--unpack` proves tarball. |
| **Manual** | `git tag`, `git push`, `mix hex.publish`, `mix hex.info` — human-in-the-loop with recorded outputs in SUMMARY. |

**Sampling:** After every task in 07-01 that touches `mix.exs` or changelog, run `MIX_ENV=test mix ci.all` (or minimal subset if SUMMARY documents rationale). After full 07-01 wave, run dev docs + hex build chain once. Plan 07-02 tasks record command output in SUMMARY instead of automating Hex upload.

---

## RESEARCH COMPLETE

Findings are sufficient to author `07-VALIDATION.md`, `07-PATTERNS.md`, and split `07-01-PLAN.md` / `07-02-PLAN.md` with concrete acceptance greps.
