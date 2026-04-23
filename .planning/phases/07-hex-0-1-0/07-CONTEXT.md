# Phase 7: Hex 0.1.0 - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship **HEX-01–HEX-04** for v1.1: `mix.exs` application version **`0.1.0`** (no `-dev`) on the release commit; **dated** `CHANGELOG.md` **0.1.0** entry; **annotated** git tag **`v0.1.0`** on that commit pushed to **`origin`**; **`mix hex.publish`** so **`threadline` 0.1.0** is installable from Hex. **Out of scope:** CI-driven automated publish, OTP/Elixir pin churn, product features (unchanged from `.planning/REQUIREMENTS.md`).

**Process note:** Maintainer-led publish; verify locally (and rely on existing green `main` CI) before tagging and publishing.

</domain>

<decisions>
## Implementation Decisions

### Changelog (HEX-02) — shape and tone

- **D-01:** Follow **[Keep a Changelog](https://keepachangelog.com/)** layout: keep a top-level **`[Unreleased]`** section for habit and diff ergonomics; **do not** add empty `### Added` / `### Fixed` subsections (empty subsections read as mistakes).
- **D-02:** **`## [0.1.0] - YYYY-MM-DD`** with **ISO 8601** date only (lexically sortable, ecosystem default).
- **D-03:** Under **`### Added`**, use a **short factual bullet list** of what the first published surface actually includes (major modules, install/generator tasks, semantics/capture story at a glance) — not marketing fluff, not empty one-liner only; enough that a consumer scanning GitHub or HexDocs extras can answer “what shipped?”
- **D-04:** **SemVer honesty:** `0.1.0` is **initial public release**; avoid dramatic “breaking” language unless there is a real committed policy change. Reserve **`[Unreleased]`** for post-0.1.0 work.

### Git tag `v0.1.0` (HEX-03)

- **D-05:** Use an **annotated** tag **`v0.1.0`** (leading `v`, matches GitHub/Git and `source_ref` below). **Lightweight** tags are acceptable for Hex technically but **annotated** is default for releases (`git describe`, release semantics, least surprise).
- **D-06:** Tag message: **one line**, e.g. **`Release v0.1.0`**, or the first line of the changelog section — details stay in `CHANGELOG.md` / optional GitHub Release body.
- **D-07:** **Single release commit discipline:** the tag **`v0.1.0`** points to the **first** commit where the tree is release-ready: **`@version "0.1.0"`** (no pre-release segment), changelog **0.1.0** section finalized, and any version strings you care about aligned. **Do not** move or force-update the tag after others may have fetched it; follow-ups ship as **`v0.1.1`** (or patch) if needed.
- **D-08:** **Push explicitly:** `git push origin main` (or default branch) **and** `git push origin v0.1.0` — do not rely on “maybe follow-tags” alone for lightweight vs annotated edge cases.
- **D-09:** **GPG/SSH-signed tags:** optional nice-to-have for GitHub “Verified”; **not** required to close this phase.

### Pre-publish verification (maintainer gate)

- **D-10:** **Gold bar before `mix hex.publish`** (same spirit as `cargo publish --dry-run` / `npm publish --dry-run`), in order:
  1. `MIX_ENV=dev mix deps.get` — `ex_doc` is **dev-only**; docs must be validated in **dev** env (CI today runs tests in `:test` and does not prove `mix docs`).
  2. `mix ci.all` — format, credo, compile `--warnings-as-errors`, tests (parity with `.github/workflows/ci.yml` job intent).
  3. `mix docs` — ExDoc + `extras` (`CHANGELOG.md`, guides, etc.) must build.
  4. `mix hex.build` then **`mix hex.build --unpack`** — confirm `package:files` tarball matches intent (classic footgun: missing `lib` subtree or new path not in `files:`).
  5. **`mix hex.publish --dry-run`** — last Hex-side validation without upload.
- **D-11:** **Then** publish for real; **then** confirm **`mix hex.info threadline`** shows **0.1.0** (HEX-04). Order relative to tag push: **tag must exist on GitHub before or when HexDocs “View Source” links are exercised** for the release ref (see D-13).
- **D-12:** **CI job for this full chain** in this milestone remains **optional** (REQUIREMENTS Out of Scope: automated publish from CI); documenting the one-liner in a plan or CONTRIBUTING note is enough for Phase 7.

### HexDocs / ExDoc `source_ref` and package links

- **D-13:** **Released versions** must not use a **moving `main`** pointer for “View Source” on HexDocs — that violates least surprise (links silently track unrelated commits). **Pre-release** versions (`0.1.0-dev`, any SemVer pre segment) may keep **`main`** so local and branch docs do not 404.
- **D-14:** **Implementation (locked):** `source_ref` is **`"v#{@version}"`** when `@version` parses as a **release** (no pre-release segment); otherwise **`"main"`**. Same helper drives **`package.links["Changelog"]`** as `#{@source_url}/blob/#{ref}/CHANGELOG.md` so hex.pm → GitHub changelog stays consistent with the doc source ref.
- **D-15:** On the **0.1.0** release commit, `@version` is **`0.1.0`** → `source_ref` **`v0.1.0`**; **create and push tag `v0.1.0` on that commit** before or as part of publish so links resolve (avoid tag typo / missing tag 404).
- **D-16:** **Doc-only fixes** for an already-published version: ship a **patch** release and new tag (`v0.1.1`); do not retag `v0.1.0`.

### Cohesion with prior phases

- **D-17:** **No automated `mix hex.publish` from GitHub Actions** in v1.1; maintainer runs D-10 locally (or trusted environment) with Hex credentials.
- **D-18:** **CI on `main` remains the honesty baseline** (Phase 6/8 context) — do not publish from a dirty tree that would not pass `mix ci.all` on the same commit.

### Claude's Discretion

Exact changelog bullet wording, optional GitHub Release markdown polish (duplicate of changelog), and whether `mix hex.publish` is one command or package+docs split if Hex prompts — within D-01–D-18.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **HEX-01** through **HEX-04** (v1.1 Hex release); Out of Scope (automated CI publish, pin churn).
- `.planning/ROADMAP.md` — Phase 7 goal, success criteria, canonical refs.
- `.planning/PROJECT.md` — v1.1 vision, maintainer-led Hex, OSS quality bar.

### Release artifacts

- `mix.exs` — `@version`, `package/0`, `docs/0` (`source_ref` policy per D-13–D-15).
- `CHANGELOG.md` — 0.1.0 section (HEX-02).

### Prior phase context

- `.planning/phases/05-repository-remote/05-CONTEXT.md` — Canonical repo URL, `origin`, homepage/docs expectations.
- `.planning/phases/06-ci-on-github/06-CONTEXT.md` — CI-02 meaning of green, job keys, minimal `ci.yml` edit policy.

### External patterns (social / docs, not code deps)

- [Keep a Changelog](https://keepachangelog.com/) — changelog structure.
- [Semantic Versioning](https://semver.org/) — version semantics for `0.1.0` and pre-release.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`mix.exs`**: `verify.*` / `ci.all` aliases; `package/0` with explicit `files:` list including `guides/`; **`doc_source_ref/0`** now ties ExDoc and Hex **Changelog** link to **tag vs `main`** per release vs pre-release (D-13–D-15).
- **`.github/workflows/ci.yml`**: Three stable jobs on `main` — use as parity reference for `mix ci.all` (D-10).

### Established patterns

- **Dev-only ExDoc** (`only: :dev`) — docs verification **must** use `MIX_ENV=dev` (D-10).

### Integration points

- **Hex.pm** package page reads `package.links` — **Changelog** + **GitHub** surfaced there.
- **HexDocs** — `extras` already include `CHANGELOG.md`; source links follow `source_url` + `source_ref`.

</code_context>

<specifics>
## Specific Ideas

- User requested **all four** gray areas with **parallel subagent research**, then a **single coherent recommendation set** (no further interactive Q&A). Decisions above synthesize that research: Keep a Changelog + ISO dates; annotated `v0.1.0`; gold pre-publish chain including `mix hex.publish --dry-run`; **tag-aligned `source_ref`** matching common Elixir library practice (e.g. Jason/Plug-style `v` + version for releases).

</specifics>

<deferred>
## Deferred Ideas

- **Optional CI job** running `MIX_ENV=dev mix docs` + `mix hex.build` on `main`/`push` — useful hardening; not required to close HEX-01–04 this milestone.
- **Signed tags** — defer until maintainer wants GitHub “Verified” without friction.
- **Automated Hex publish from CI** — explicit backlog / future milestone per REQUIREMENTS Out of Scope.

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches for phase 7.

</deferred>

---

*Phase: 07-hex-0-1-0*
*Context gathered: 2026-04-23*
