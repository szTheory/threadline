# Phase 191: Release/Version and Docs Trust Repair - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-02
**Phase:** 191-release-version-and-docs-trust-repair
**Areas discussed:** Version-truth policy, Upgrade guide shape, Persona routing, Drift-guard enforcement

---

## Discussion mode

User selected **all four** gray areas and requested full subagent-backed research per area (architecture/SWE/DevOps/SRE lenses, ecosystem prior art, DX, API-consumer/JTBD, UI/UX where applicable), asking for a single coherent one-shot recommendation set so no further deliberation is needed. Four parallel `gsd-advisor-researcher` agents were dispatched, one per area, each briefed with the verified in-repo drift facts and the `prompts/` corpus. Their recommendations were reconciled into the locked decisions in CONTEXT.md. This log records the options each researcher weighed.

---

## Version-truth policy

**Install-snippet pin:**

| Option | Description | Selected |
|--------|-------------|----------|
| Leave `~> 0.6` | Semver-valid (resolves to 0.9.0), zero edits, but advertises a stale/misleading floor and rots silently | |
| `~> 0.9` (two-segment) | `>= 0.9.0, < 1.0.0`; floats across future 0.x minors that may break; not cleanly auto-injectable | |
| `~> 0.9.0` (three-segment) | `>= 0.9.0, < 0.10.0`; scopes to current tested minor; matches Carbonite/Req pre-1.0 idiom; contains full semver → auto-injectable | ✓ |

**Prose version handling:**

| Option | Description | Selected |
|--------|-------------|----------|
| Rewrite every 0.6.0 → 0.9.0 | Falsifies history ("0.6.0 packaged Evidence" becomes wrong) | |
| Leave all prose as-is | Keeps the false "0.6.0 is the SSOT" claim | |
| Split by role: fix version-truth to SSOT, keep historical prose pinned + fix tense | Corrects the one flatly-wrong claim; preserves accurate history | ✓ |

**Choice:** Three-segment `~> 0.9.0` everywhere; version-truth vs historical-narrative taxonomy (D-191-01..04).
**Notes:** `evaluating-threadline.md:11` currently claims 0.6.0 *is* `@version` — provably false and the worst trust bug. Carbonite (direct analog) re-pins `~> 0.X.0` each release.

---

## Upgrade guide shape

| Option | Description | Selected |
|--------|-------------|----------|
| Per-minor sections only | Matches how adopters bump; fragments cross-minor themes; fails ADOPT-02's theme half | |
| Theme-grouped narrative only | Mirrors ADOPT-02 themes; loses the per-bump "must I act?" answer; fails the minor half | |
| Hybrid (theme table + per-minor spine + bounded per-bump bullets) | Satisfies both ADOPT-02 axes; independently testable; extends the locked section | ✓ |

**Choice:** Hybrid, extending the existing `## Upgrade by Threadline minor` section (D-191-09..12).
**Notes:** Mandatory "nothing required" reassurance per bump (0.6→0.9 was surface/DX/proof work, no host-DB migrations). Storage-schema gets the only real migration block, phrased per Phase 190 D-190-14. CHANGELOG = complete/chronological; upgrade-path = curated/effect-oriented, linking `[x.y.0]` anchors. Anchors: Oban per-version upgrade guides, Carbonite freeze-at-generation, Phoenix curated notes.

---

## Persona routing

| Option | Description | Selected |
|--------|-------------|----------|
| README-only | Leaves HexDocs sidebar a flat 14-item wall; poor for HexDocs-first visitors | |
| ExDoc-only | GitHub README still dumps everything; sidebar groups alone don't say "why start here" | |
| Duplicate prose in both | Creates the "giant new guide" ADOPT-03 forbids; two copies that drift | |
| Both, divided by medium (Option C) | README owns persona prose (table); ExDoc owns sidebar lanes; one source via `docs.main` | ✓ |

**Choice:** Option C (D-191-13..17). Four personas: Evaluator / Adopter / Operator / Maintainer.
**Notes:** These are distinct from the operator-surface P1–P5 UI personas in `ia_lock_doc_contract_test.exs` — do not touch that test. Delete README's flat `## Documentation` dump; restructure `groups_for_extras` into Evaluate/Adopt/Operate/Maintain lanes. Anchors: Oban/Ash HexDocs grouping, Diátaxis (route by reader intent, don't write a new guide).

---

## Drift-guard enforcement

**Assertion basis:**

| Option | Description | Selected |
|--------|-------------|----------|
| Dynamic (derive from `@version`) | Test never needs editing; survives every bump; already proven in adoption-pilot test | ✓ |
| Hardcoded "0.9.0" strings | Reintroduces the same drift class it's meant to prevent | |

**Coverage model:**

| Option | Description | Selected |
|--------|-------------|----------|
| Central scanner (glob README + guides) | New docs auto-covered; one owner of version truth; can't be partially applied | ✓ |
| Extend each per-doc test individually | This *is what caused the drift* (pattern lived in 1 of ~30 tests) | |

**Choice:** Central `version_truth_doc_contract_test.exs`, dynamic derivation, three families, marker convention for live-claim prose (D-191-05..08).
**Notes:** Resolved the cross-stream tension — three-segment `~> 0.9.0` is auto-injectable, so prefer release-please block annotations *outside* code fences (kills born-red release PRs, a known project pain) with the central test as safety net. Generalize the marker/extra-files wiring guard to all docs. Anchors: read-`Mix.Project.config()[:version]`-in-tests (idiomatic Elixir), release-please `customizing.md`.

---

## Claude's Discretion

- Exact regex/parsing in the new doc-contract tests.
- Per-file isolation of `{:threadline, ...}` pins into their own fenced blocks for clean block-annotation injection; test-enforcement fallback where a pin can't be cleanly marked.
- Precise wording of the upgrade-guide theme table and per-bump reassurance bullets.
- Test module/helper organization.

## Deferred Ideas

- CI/CD measurement and efficiency → Phase 192 (CI-01..04).
- Guide-body content rewrites beyond version/tense/routing repair.
- A standalone "start here"/"where to go next" guide → forbidden by ADOPT-03 (refute-tested).
- Full Diátaxis reorganization of guide content → only ExDoc lane grouping now.
- Post-1.0 two-segment pin convention → revisit at 1.0.

---

## Validation Round (Update pass, 2026-07-02)

User re-ran `/gsd-discuss-phase 191`, chose **Update it**, and asked to adversarially pressure-test the three most opinionated decisions with subagent research (reaffirm-or-overturn). First confirmed no new drift surface exists (package metadata, README badges, example app, bench are all already SSOT-derived / path-dep — clean). Then three researchers ran:

| Decision under test | Verdict | Change folded in |
|---|---|---|
| Pin granularity (D-191-02) | **REAFFIRM** `~> 0.9.0` | + D-191-02a backport policy (patch-backport on current minor; minor-crossing deliberate). Carbonite now `~> 0.16.1`; CHANGELOG audit shows 0 host-breaking 0.6→0.9. |
| Injection / born-red (D-191-05) | **OVERTURN (source-level)** | release-please `generic.ts` has no sticky `major.minor.0` scope → injecting a pin born-reds every *patch* release. Split: prose claims injected; **pins test-enforced only** with `.0` derivation. Dropped fenced-block isolation (unneeded — co-located deps are two-segment). |
| Persona routing (D-191-13..17) | **OVERTURN (targeted)** | persona nouns → intent **verbs** (Evaluate/Adopt/Operate/Contribute); **replace** flat index with collapsed `<details>` (not delete); `upgrade-path`→Adopt, `adoption-evidence-playbook`→Operate; Contribute then-hop = `adoption-pilot-backlog`; label (not rewrite) the SaaS-titled Adopt guide; + D-191-18 brand-voice row microcopy. |

Note: the two overturn researchers initially died on an API `ConnectionRefused` and were retried successfully. All three verdicts are reflected in `191-CONTEXT.md`.
