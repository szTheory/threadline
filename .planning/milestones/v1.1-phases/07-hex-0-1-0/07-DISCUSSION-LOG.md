# Phase 7: Hex 0.1.0 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `07-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-23
**Phase:** 7 — Hex 0.1.0
**Areas discussed:** Changelog (HEX-02), Git tag (HEX-03), Pre-publish verification, ExDoc `source_ref` / package links

**Mode:** User selected **all** gray areas and requested **parallel subagent research** plus a **one-shot** coherent recommendation set (delegated to synthesis).

---

## 1. Changelog & 0.1.0 notes (HEX-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal one-liner | “Initial public release” only | |
| Keep a Changelog + dated `## [0.1.0] - YYYY-MM-DD` + factual `### Added` bullets | Matches ecosystem + SemVer scan habits; no empty subsection headings | ✓ |
| Remove `[Unreleased]` | Less clutter for first release | |
| Non-ISO dates | Friendlier prose dates | |

**User's choice:** Delegated — adopt **Keep a Changelog**, **ISO dates**, keep **`[Unreleased]`**, **short factual bullets** under **`### Added`**, omit empty `###` blocks.

**Notes:** Research contrasted npm “two sources of truth” footguns vs single canonical `CHANGELOG.md`; emphasized ExDoc `extras` + hex.pm links for discoverability.

---

## 2. Git tag `v0.1.0` (HEX-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Lightweight tag | Fast; Hex indifferent | |
| Annotated `v0.1.0` | Release object; `git describe`; OSS norm | ✓ |
| Tag on non-release commit | Flexible | |
| Strict: tag = exact commit with `0.1.0` no pre, changelog final | Hygiene + `git checkout v0.1.0` matches Hex intent | ✓ |
| GPG-signed tags | Trust signal | (optional / deferred) |

**User's choice:** Delegated — **annotated** tag **`v0.1.0`**, **one-line** tag message, **immutable** after push; **no retag**; follow-ups = new semver.

**Notes:** Hex does not use git tags for tarball identity; tags are for humans, Git deps, GitHub, and alignment with `source_ref: v#{version}`.

---

## 3. Pre-publish verification

| Option | Description | Selected |
|--------|-------------|----------|
| `mix ci.all` only | Matches test CI env | |
| Gold chain: dev deps + `ci.all` + `mix docs` + `hex.build --unpack` + `hex.publish --dry-run` | Catches docs, `files:`, and Hex validation before upload | ✓ |

**User's choice:** Delegated — **D-10** chain in `07-CONTEXT.md`; highlights `MIX_ENV=dev` for ExDoc.

**Notes:** Compared to `npm publish --dry-run` / `cargo publish --dry-run`; called out `files:` and post-publish doc failure footguns.

---

## 4. ExDoc `source_ref` & package links

| Option | Description | Selected |
|--------|-------------|----------|
| `source_ref: "main"` always | Simple | |
| `source_ref: "v#{@version}"` for releases; `main` for pre-release | Matches Jason/Plug-style ecosystem pattern; stable HexDocs “View Source” | ✓ |
| Raw SHA | Maximum pin | (defer unless special case) |

**User's choice:** Delegated — **conditional `doc_source_ref/0`** in `mix.exs` + **`package.links["Changelog"]`** aligned with same ref (implemented alongside this log).

**Notes:** `main` for moving branch is high surprise for versioned docs; tag must exist when `v0.1.0` links go live.

---

## Claude's Discretion

Minor wording in changelog bullets; exact `gh`/`git` command snippets in plans; GitHub Release body optional duplication of changelog.

## Deferred Ideas

- CI job for docs + `hex.build` automation
- Signed tags
- Automated Hex publish from Actions
