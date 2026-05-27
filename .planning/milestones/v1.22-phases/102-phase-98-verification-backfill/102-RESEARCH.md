# Phase 102: Phase 98 Verification Backfill - Research

**Researched:** 2026-05-27
**Domain:** Current-tree proof, verification-backfill artifact authoring, and Nyquist closure synchronization for the Phase 98 mounted `/audit/evidence` surface
**Confidence:** HIGH for the current-tree fingerprint (every CONTEXT.md citation re-verified live by `rg`/`sed`/`mix test` at research time on commit `1db8e8e`) and for the artifact-skeleton extraction (read all four canonical templates 95/96/100/101 in full). MEDIUM only for the carry-forward `mix verify.test` alias-drift status — commit `b636c17` claims to have fixed it but Phase 102 deliberately does not re-run that command (per D-10).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Verification artifact structure

- **D-01:** `98-VERIFICATION.md` uses the same frontmatter shape Phases 100 and 101 produced: `phase`, `verified`, `status`, `score`, `overrides_applied`.
- **D-02:** Artifact opens with `## Current-tree preflight` section that states the working tree is the authority, names the missing-artifact gap being closed, and explicitly disclaims any milestone authority-surface changes (those remain Phase 103 work).
- **D-03:** Band structure — **3 numbered bands, 1:1 with SURF-01 / SURF-02 / SURF-03**, each with its own `**Requirement:**` line and `**Result:** PASS` block. (Phase 96 used 4 bands only because it had a single `PROOF-01` row covering four contract surfaces — not a template to copy when requirements are already plural.)
  1. **Band 1 — SURF-01:** Read-only `/audit/evidence` mount inside the existing operator family. Route lives as a sibling in `/audit`, no new UI family, LiveView defines no mutation handlers.
  2. **Band 2 — SURF-02:** Mounted parity through shared `Threadline.Evidence.Proof` presenter and locked Phase 98 copy literals.
  3. **Band 3 — SURF-03:** Host-owned authorization gate via `evidence_authorize_fn`, with no Threadline-owned RBAC, tenant DSL, or persona semantics. The default callback fails closed.
- **D-04:** Artifact closes with `## Requirement closure` table (one row each for SURF-01/02/03) and `## Not closed here` section.

#### Proof method per band — mixed (structural primary for negatives, behavioral primary for positives)

- **D-05:** Band 1 (SURF-01) proof bundle: structural mount-shape grep (`live("/evidence"` in router.ex), structural read-only grep (no `handle_event` in evidence_live.ex), arity citation (only `mount/3`, `handle_params/3`, `render/1`), behavioral support via focused-bundle.
- **D-06:** Band 2 (SURF-02) proof bundle: structural shared-presenter grep (`alias Threadline.Evidence.Proof` + `Proof.present_record`), structural copy-literal greps per D-12, behavioral verdict vocabulary assertions in rendered HTML.
- **D-07:** Band 3 (SURF-03) proof bundle: structural negative grep (no `Threadline.RBAC|Threadline.Permissions|Threadline.Policy.RBAC`) **paired with positive-control grep** (`evidence_authorize_fn` in auth.ex around line 254), arity citation (callback shape), behavioral fail-closed denial path via the focused bundle.

#### Rerun bundle and authority

- **D-08:** Authoritative Phase 98 rerun bundle is the focused two-file band: `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1`. **Current-tree result confirmed live: PASS — 34 tests, 0 failures.**
- **D-09:** Two-file coupling is intentional: `auth_test.exs` owns SURF-03 unit-scope fan-out; `evidence_live_test.exs` owns SURF-01 mount + SURF-02 parity at LiveView scope.
- **D-10:** `mix verify.test` is intentionally NOT the authority bundle. Disclaim Phase 99 alias-drift to commit `b636c17`. If 102-01 finds the drift was fixed post-`b636c17`, update the disclaimer to cite the newer fix but keep the disclaimer shape.

#### UI-SPEC handling — locked literals only

- **D-11:** `98-UI-SPEC.md` is a Band 2 authority **scoped strictly to mechanically-verifiable copy literals**. Visual hierarchy, spacing tokens, typography sizing, color palette, scanability remain Manual-Only per `98-VALIDATION.md` and are explicitly named in the artifact's "Not closed here" section.
- **D-12:** Locked copy-literal inventory for Band 2 (5 rows) — each verified by `rg -nF` AND a behavioral test assertion. See table in §3 below.

#### Requirement closure layout

- **D-13:** `## Requirement closure` table renders SURF-01/02/03 as **three separate rows**, one prose sentence each, with closing band citation in Evidence column.

#### Finalization honesty (per Phase 101 D-16)

- **D-14:** Flipping `98-VALIDATION.md` to `nyquist_compliant: true` + `wave_0_complete: true` is **retroactive backfill, not original Wave 0 execution**. Finalized validation artifact MUST include a one-line note in the validation strategy section making this explicit. Without this note the frontmatter flip reads as merge-theater.
- **D-15:** New `## Commands Actually Used` section lands immediately after the Per-Task Verification Map and before the Wave 0 Requirements section, mirroring `95-VALIDATION.md:54` and `96-VALIDATION.md:54`. Single numbered entry (the focused bundle); Phase 102's structural greps live in `98-VERIFICATION.md`, not the validation command ledger.

#### Repair posture

- **D-16:** 102-01 makes only the smallest literal-truth repair. Allowed: swap Quick/Full run command in `98-VALIDATION.md`, fix a stale `evidence_live.ex` line reference, correct typos. Not allowed: adding new tests, renaming public functions, expanding SURF wording, restructuring UI-SPEC.
- **D-17:** If a UI-SPEC literal (D-12) does not appear at the cited source line, the smallest repair is to **update the source code to render the UI-SPEC's locked literal — NOT to update the UI-SPEC**. UI-SPEC is the design contract; code is the realization.
- **D-18:** If `98-VALIDATION.md` "Full suite command" still names `mix verify.test` at planning time (it does — confirmed in §4 below), 102-01's smallest repair replaces that line with the focused band per D-08.

#### Milestone authority boundary

- **D-19:** Phase 102 MUST NOT modify `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, or `.planning/STATE.md`. SURF-01/02/03 rows remain `Pending` in those files; Phase 103 owns reconciliation.
- **D-20:** `## Not closed here` mirrors Phase 100/101 boilerplate: three bullets (REQUIREMENTS.md/ROADMAP.md/STATE.md), one bullet for visual/spacing/color of `98-UI-SPEC.md`, plus closing line: "Phase 102 closes the missing Phase 98 verification and validation chain only; milestone authority-surface reconciliation remains Phase 103 work."

### Claude's Discretion

- Exact prose wording inside each band's bullet list, as long as PASS/FAIL block and cited test/grep command are explicit.
- Exact ordering of the three bands, as long as it reads SURF-01 → SURF-02 → SURF-03.
- Whether to render D-12 literal table verbatim inside Band 2 or inline each row as a separate Result bullet, as long as every literal is paired with both a structural and behavioral citation.
- Exact `## Commands Actually Used` numbering if 102-01's repair adds additional executed commands.

### Deferred Ideas (OUT OF SCOPE)

- Visual hierarchy, spacing tokens (4/8/16/24/32/48px), typography sizing, color palette adherence, scanability — Manual-Only.
- Behavioral test exhaustively poisoning every host capability boolean — existing `auth_test.exs` coverage is sufficient.
- Repairing `mix verify.test` alias-drift — Phase 99 owns.
- Updating REQUIREMENTS.md / ROADMAP.md / STATE.md — Phase 103.
- Adding root-level `Threadline.*` delegates or new evidence helpers — already deferred by Phase 96.
- Phase 103 (authority-surface reconciliation) — follows Phase 102 directly.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SURF-01 | Read-only evidence views live on the existing `/audit` surface rather than a new operator UI family. [VERIFIED: `.planning/REQUIREMENTS.md:22`, Traceability row line 60] | Current `lib/threadline/operator_surface/router.ex:100` mounts `live("/evidence", EvidenceLive, :index)` inside the existing `live_session :threadline` block at line 89, as a sibling alongside `live("/", TimelineLive, :index)` at line 99 and seven other operator routes. `EvidenceLive` defines only `mount/3` (line 12), `handle_params/3` (line 21), and `render/1` (line 49) — no `handle_event/3` is defined (live grep returns exit code 1). [VERIFIED: live `rg`/`sed` at research time on commit `1db8e8e`] |
| SURF-02 | Mounted evidence views show the same evidence facts and boundary language as the library API and Mix-task paths. [VERIFIED: `.planning/REQUIREMENTS.md:23`, Traceability row line 61] | `evidence_live.ex:8` aliases `Threadline.Evidence.Proof` and `evidence_live.ex:253` calls `Proof.present_record(record)` inside `build_row/1` — the same presenter that `lib/threadline/evidence/proof.ex:75` exposes for Mix-task `render_human/1` and `to_json_iodata/2` paths. Verdict vocabulary `proven`/`inferred_posture`/`unsupported` originates from `proof.ex:10` (`@semantic_statuses ~w(proven inferred_posture unsupported)`) and renders dynamically at `evidence_live.ex:117` via `{row.verdict_status}`. All five locked Phase 98 UI-SPEC literals are present in source AND asserted in `evidence_live_test.exs` (full inventory below). [VERIFIED: live grep at research time] |
| SURF-03 | Host-owned authorization remains the gate for mounted evidence views; Threadline does not introduce RBAC or tenant DSL semantics. [VERIFIED: `.planning/REQUIREMENTS.md:24`, Traceability row line 62] | `lib/threadline/operator_surface/auth.ex:254` defines `evidence_authorize_fn = Keyword.get(opts, :evidence_authorize_fn, fn _ -> false end)` — fail-closed default inside `defp assign_evidence_enabled/2` (line 253). The callback shape is `(%{assigns: map()} -> boolean | :ok | {:ok, scope} | _)` — host-supplied function value, not a Threadline-owned module dispatch or behaviour. Negative grep `rg -n 'Threadline\.RBAC|Threadline\.Permissions|Threadline\.Policy\.RBAC' lib/threadline/operator_surface/` returns exit code 1 (zero matches). [VERIFIED: live grep at research time] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Three-layer architecture:** Phase 98 is the *exploration/operations* layer (mounted `/audit/evidence` surface over Phase 96's semantics-layer `Threadline.Evidence`). The verification artifact must not claim capture-layer concerns (trigger registration, change records) belong to Phase 98. [VERIFIED: `CLAUDE.md` "Architecture — Three Layers"]
- **Named verification entrypoints:** CLAUDE.md says prefer `mix verify.*` / `mix ci.*` aliases. CONTEXT.md D-08/D-10 deliberately override this for Phase 102 because `mix verify.test` carries unrelated alias-drift (Phase 99 territory). The artifact must explain *why* the focused bundle is the authority (boundary scoping, not an indictment of `mix verify.test`). [VERIFIED: `CLAUDE.md` "CI & Verification Conventions"]
- **Stable CI job IDs:** Not applicable — no CI workflow edits. [VERIFIED: `CLAUDE.md`]
- **Honest default tests:** Phase 102 must not silently widen/narrow `mix test` defaults; it scopes one focused command set and disclaims `mix verify.test`. [VERIFIED: `CLAUDE.md` "CI & Verification Conventions"]
- **Domain language:** Phase 98 uses operator-surface terms (`/audit/evidence`, `evidence_authorize_fn`); domain language from CLAUDE.md (`AuditTransaction`/`AuditChange`/etc.) lives in the capture/semantics layers, not here. Do not conflate. [VERIFIED: `CLAUDE.md` "Domain Language"]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Verification artifact authoring | Planning / Documentation | — | The artifact is a planning-truth surface; no code or test logic is added. [VERIFIED: D-16] |
| Current-tree re-verification | Test execution (ExUnit + Phoenix.LiveView + Ecto) | — | Focused two-file rerun bundle exercises LiveView mount/HTML assertions plus auth unit fan-out. Phase 102 is consumer of these tests, not their author. [VERIFIED: `test/threadline/operator_surface/live/evidence_live_test.exs`, `test/threadline/operator_surface/auth_test.exs`] |
| Mount-shape and read-only-handler proof | Static analysis (ripgrep) + arity citation | Source citation | Per D-05, structural greps prove the mount lives in the existing `/audit` family and no `handle_event` is defined. No runtime behavior is asserted for these claims. [VERIFIED: D-05] |
| Shared-presenter parity proof | Static analysis (alias + call-site grep) | Behavioral HTML assertion | Per D-06, grep proves `EvidenceLive` aliases `Threadline.Evidence.Proof` and calls `Proof.present_record/1`; LiveView tests prove the resulting verdict vocabulary renders in HTML. [VERIFIED: D-06] |
| Host-owned authorization proof | Static analysis (negative grep + positive control) | Behavioral fail-closed test | Per D-07, paired greps prove absence of Threadline-owned RBAC AND presence of the host-supplied callback. Behavioral test in `evidence_live_test.exs:106-116` proves denied-state HTML rendering. [VERIFIED: D-07] |
| Validation Nyquist closure | Planning / Documentation | — | `98-VALIDATION.md` is updated in-place to record executed evidence; no new test scaffolding is added. [VERIFIED: D-14, D-15] |
| Milestone authority reconciliation | OUT OF SCOPE — Phase 103 | — | Phase 102 must not edit REQUIREMENTS.md / ROADMAP.md / STATE.md. [VERIFIED: D-19] |

## Summary

The current tree on commit `1db8e8e` already contains the full Phase 98 contract: a thin `EvidenceLive` LiveView mounted at `/audit/evidence` (router.ex:100), shared-presenter parity via `Threadline.Evidence.Proof.present_record/1` (evidence_live.ex:253), and a fail-closed `evidence_authorize_fn` host-owned gate (auth.ex:254). All five UI-SPEC copy literals are present at the cited source locations AND asserted by the existing test suite. The focused two-file rerun bundle (`auth_test.exs` + `evidence_live_test.exs`) passes 34/0 live.

Phase 102's only missing surfaces are paperwork: `98-VERIFICATION.md` (does not exist) and a finalized `98-VALIDATION.md` (exists as `status: draft`, `nyquist_compliant: false`, `wave_0_complete: false`, with `mix verify.test` still named as the Full suite command — which D-18 says to swap for the focused bundle).

**Primary recommendation:** the planner produces two plans that mirror Phase 100's plan pair shape exactly. **Plan 102-01** runs the focused rerun bundle plus four structural greps (Band 1 mount, Band 1 no-handler, Band 3 negative-RBAC, Band 3 positive-control auth gate), writes `98-VERIFICATION.md` against the Phase 100 frontmatter template with three numbered bands (per D-03), and performs the smallest literal-truth repair on `98-VALIDATION.md`'s authority band (per D-18). **Plan 102-02** finalizes `98-VALIDATION.md` (frontmatter flip to `nyquist_compliant: true` + `wave_0_complete: true`, status drift `draft → validated`, swap authority commands, add `## Commands Actually Used` with the executed focused bundle per D-15, add `## Phase Boundary Guard` per the 95/96 finalized analogs, and add the retroactive-backfill note per D-14). Both plans intentionally leave milestone authority surfaces untouched (D-19).

## 1. Phase Goal Restatement

Phase 102 closes the missing Phase 98 verification and validation chain by producing two paperwork artifacts: a brand-new `98-VERIFICATION.md` (current-tree proof for SURF-01/02/03 organized as three numbered bands) and a finalized `98-VALIDATION.md` (Nyquist-final Wave 0 + per-task verification map + Commands Actually Used + retroactive-backfill honesty note + focused-bundle authority swap). No code or tests change beyond the smallest literal-truth repair, and no milestone authority surface (REQUIREMENTS.md/ROADMAP.md/STATE.md) is reconciled — those remain Phase 103 work.

## 2. Current-tree fingerprint — citation re-verification

Every CONTEXT.md citation has been verified live at research time on commit `1db8e8e`. All citations are accurate. **No drift detected.**

### 2.1 D-05 (Band 1 / SURF-01) citation table

| CONTEXT.md claim | Cited location | Observed live | Status |
|------------------|----------------|---------------|--------|
| `/audit/evidence` mount lives at `router.ex:100` inside `live_session :threadline` | `lib/threadline/operator_surface/router.ex:100` | `live("/evidence", EvidenceLive, :index)` at line 100; `live_session :threadline` opens at line 89 and `live_session` block closes at line 109; route is one of nine siblings in the `scope unquote(path)` block (line 94) | ✅ MATCH |
| `EvidenceLive` defines only `mount/3`, `handle_params/3`, `render/1` (no `handle_event/3`) | `lib/threadline/operator_surface/live/evidence_live.ex` | `mount/3` at line 12, `handle_params/3` at line 21, `render/1` at line 49; `rg -n '^\s*def handle_event' …/evidence_live.ex` returns exit code 1 (zero matches) | ✅ MATCH |

### 2.2 D-06 + D-12 (Band 2 / SURF-02) citation table

| CONTEXT.md claim | Cited location | Observed live | Status |
|------------------|----------------|---------------|--------|
| Shared-presenter alias | `lib/threadline/operator_surface/live/evidence_live.ex` | `alias Threadline.Evidence.Proof` at line 8; `Proof.present_record(record)` at line 253 (inside `defp build_row/1`) | ✅ MATCH |
| Locked literal: `What can Threadline prove right now?` → UI-SPEC line 87, source `evidence_live.ex:67`, test `evidence_live_test.exs:115,150` | source 67 / test 115,150 | source line 67 = `<h2>What can Threadline prove right now?</h2>`; test line 115 = `refute html =~ "What can Threadline prove right now?"` (denied-state negative assertion); test line 150 = `assert html =~ "What can Threadline prove right now?"` (positive assertion) | ✅ MATCH — note line 115 is a **refute** (negative assertion proving the denied state hides the literal), line 150 is a **positive assertion**; CONTEXT.md correctly cites both because both reference the literal |
| Verdict triple `proven` / `inferred_posture` / `unsupported` → UI-SPEC line 88, source `evidence_live.ex:116-118`, test `evidence_live_test.exs:153-155` | source 116-118 / test 153-155 | source lines 116-118 contain the **dynamic rendering site** (`<span class={…"evidence-verdict--#{row.verdict_status}"}>{row.verdict_status}</span>`) — the verdict literals themselves originate from `lib/threadline/evidence/proof.ex:10` (`@semantic_statuses ~w(proven inferred_posture unsupported)`); test lines 153-155 = three positive assertions (`assert html =~ "proven"`, `"inferred_posture"`, `"unsupported"`) | ⚠️ NUANCE — `evidence_live.ex:116-118` is the **render site**, not the **literal-defining site**. The literal lives in `proof.ex:10`. Band 2 must cite both: the render site (proves the LiveView surfaces the vocabulary) AND the canonical source (proves there's one truth model). See §5.2 below for the dual-grep recommendation. CONTEXT.md citation is not wrong but is incomplete — the planner should add the `proof.ex:10` citation as a Band 2 supporting reference. |
| Locked literal: `View history` → UI-SPEC line 79, source `evidence_live.ex:142`, test `evidence_live_test.exs:152` | source 142 / test 152 | source line 142 = `View history` (inside the history-link `<.link>` body); test line 152 = `assert html =~ "View history"` | ✅ MATCH |
| Locked literal: `No evidence records yet` → UI-SPEC line 81, source `evidence_live.ex:89-95`, test `evidence_live_test.exs:213` | source 89-95 / test 213 | source line 89 = `<h3>No evidence records yet</h3>`; lines 90-95 contain the rest of the empty-state paragraph (with `mix threadline.evidence.show` and `Threadline.Evidence` references); test line 213 = `assert html =~ "No evidence records yet"` | ✅ MATCH |
| Locked literal: `Evidence view unavailable.` → UI-SPEC line 82, source `unsupported.ex` via `evidence_live.ex:154`, test `evidence_live_test.exs:113` | source via line 154 / test 113 | `unsupported.ex:25` defines the descriptor body starting `"Evidence view unavailable. This mounted proof surface is not available…"`; `evidence_live.ex:154` calls `Unsupported.descriptor(:evidence_unavailable)` to render it via `UnsupportedView`; test line 113 = `assert html =~ "Evidence view unavailable."` | ✅ MATCH |

### 2.3 D-07 (Band 3 / SURF-03) citation table

| CONTEXT.md claim | Cited location | Observed live | Status |
|------------------|----------------|---------------|--------|
| `evidence_authorize_fn` fail-closed default at `auth.ex:254` inside `defp assign_evidence_enabled` | `lib/threadline/operator_surface/auth.ex:253-260` | line 253 = `defp assign_evidence_enabled(socket, opts) do`; line 254 = `evidence_authorize_fn = Keyword.get(opts, :evidence_authorize_fn, fn _ -> false end)` — exact match | ✅ MATCH |
| No Threadline-owned RBAC modules under `lib/threadline/operator_surface/` | `rg -n 'Threadline\.RBAC\|Threadline\.Permissions\|Threadline\.Policy\.RBAC' lib/threadline/operator_surface/` | exit code 1 (zero matches) | ✅ MATCH |

### 2.4 D-08 rerun bundle live confirmation

Command: `MIX_ENV=test mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1`

Live result at research time (HEAD `1db8e8e`):
```
Running ExUnit with seed: 198450, max_cases: 36
Excluding tags: [pgbouncer_topology: true]

..................................
Finished in 0.2 seconds (0.1s async, 0.1s sync)
34 tests, 0 failures
```

✅ MATCHES CONTEXT.md D-08 claim of "PASS — 34 tests, 0 failures". Per-file test counts (`rg -c '^\s*test '`): `auth_test.exs` = 29 tests; `evidence_live_test.exs` = 5 tests. 29 + 5 = 34. ExUnit count matches.

### 2.5 `98-VALIDATION.md` current state (the file 102-02 finalizes)

| Field | Current value | Required after 102-02 | Source of "required" |
|-------|---------------|----------------------|----------------------|
| `phase` | `98` | unchanged (matches 95-VALIDATION line 2 convention) | D-15 |
| `slug` | `mounted-evidence-views-on-audit` | unchanged | — |
| `status` | `draft` | `validated` | mirrors `95-VALIDATION.md:4` |
| `nyquist_compliant` | `false` | `true` | D-14 |
| `wave_0_complete` | `false` | `true` | D-14 |
| `created` | `2026-05-26` | unchanged | — |
| `updated:` (missing) | — | add bump to 102-01's execution timestamp | mirrors `95-VALIDATION.md:8` |
| Quick run command (line 22) | `MIX_ENV=test mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` | unchanged (already the focused bundle, just drop the `MIX_ENV=test` prefix for symmetry with 95/96 finalized analogs which do not include it) | D-18, mirrors `95-VALIDATION.md:25` |
| Full suite command (line 23) | `mix verify.test` | **swap to the focused bundle** | **D-18 (the canonical literal-truth repair)** |
| Per-Task Verification Map Status (lines 41-43) | all `⬜ pending` | flip to `✅ green` after 102-01 passes | mirrors `95-VALIDATION.md:45-48` |
| Approval line (line 73) | `pending` | `finalized on 2026-05-27 after Phase 102-01 produced 98-VERIFICATION.md and the current-tree rerun bundle passed.` | mirrors `95-VALIDATION.md:101` |

**Sections missing that 102-02 MUST add:**
- `## Commands Actually Used` (lands after Per-Task Verification Map, before Wave 0 Requirements per D-15) — see §4 verbatim shape.
- `## Phase Boundary Guard` (lands after Manual-Only Verifications, before Validation Sign-Off — mirrors `95-VALIDATION.md:83-90` and `96-VALIDATION.md:83-90`).
- Retroactive-backfill honesty note (per D-14) — one line in the opening block-quote at the top of `98-VALIDATION.md`, replacing or augmenting the existing block-quote at line 12.

**Sections to retain unchanged:**
- `## Sampling Rate` (lines 28-33) — already correct.
- `## Manual-Only Verifications` (lines 56-60) — already names visual hierarchy as Manual-Only, which D-11 reaffirms.
- `## Wave 0 Requirements` (lines 49-52) — already lists Phase 98 contract test files. The two `[ ]` checkboxes can be confirmed as `[x]` after 102-01 since both test files exist on disk.

## 3. Verification Artifact Skeleton

Annotated `98-VERIFICATION.md` outline. The planner can copy the verbatim extractions in §3.1–§3.6 below directly without further derivation.

### 3.1 Verbatim frontmatter for `98-VERIFICATION.md` (from `95-VERIFICATION.md` lines 1-7, `96-VERIFICATION.md` lines 1-7)

```yaml
---
phase: 98-mounted-evidence-views-on-audit
verified: 2026-05-27T<HH:MM:SSZ>
status: passed
score: 3/3 requirement bands verified
overrides_applied: 0
---
```

(Phase 96 used `4/4 requirement bands verified`; Phase 102 uses `3/3` per D-03, matching Phase 95's three-band shape.)

### 3.2 Verbatim header pattern (from `95-VERIFICATION.md` lines 9-14, `96-VERIFICATION.md` lines 9-14)

```markdown
# Phase 98: Mounted Evidence Views On `/audit` Verification Report

**Phase Goal:** Re-prove the current-tree mounted `/audit/evidence` surface with explicit verification evidence instead of inherited summary claims.
**Verified:** 2026-05-27T<HH:MM:SSZ>
**Status:** passed
**Re-verification:** Yes - gap closure for missing phase verification
```

### 3.3 Verbatim `## Current-tree preflight` template (from `95-VERIFICATION.md` lines 16-22, `96-VERIFICATION.md` lines 16-23 retargeted)

```markdown
## Current-tree preflight

**Result:** PASS

- The Phase 98 implementation files, tests, and summaries are present on disk, but `98-VERIFICATION.md` was missing before this run.
- This verification treats the current working tree as the authority and closes that missing artifact gap directly.
- Milestone authority surfaces remain intentionally unreconciled here; `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` stay Phase 103 work.
```

### 3.4 Verbatim band shape (from `95-VERIFICATION.md` §1)

Each band must use this exact shape:

````markdown
## N. <Band title>

**Requirement:** `SURF-NN`
**Result:** PASS

- <bullet 1 — cite a specific line or module>
- <bullet 2 — cite a specific line or module>
- <bullet 3 — cite a specific line or module>

### Evidence

```bash
<the exact command>
```

Result: PASS (`<N tests, 0 failures>` or `<grep result description>`)
````

### 3.5 Verbatim band-title candidates (per CONTEXT.md `<specifics>` block)

1. `## 1. Read-only /audit/evidence mount inside the existing operator family`
2. `## 2. Mounted parity through Threadline.Evidence.Proof and locked copy literals`
3. `## 3. Host-owned evidence_authorize_fn gate with no Threadline RBAC`

(Phase 100/95 convention is `## N. <descriptive title>` with no requirement ID in the heading — the requirement ID lives in the body via `**Requirement:**`. Match that.)

### 3.6 Verbatim `## Requirement closure` table shape (from `95-VERIFICATION.md` lines 81-87)

Per D-13, render SURF-01/02/03 as three separate rows. Suggested prose from CONTEXT.md `<specifics>` block:

```markdown
## Requirement closure

| Requirement | Status | Why it closes on the current tree |
| --- | --- | --- |
| `SURF-01` | ✓ SATISFIED | Threadline mounts the read-only evidence surface as a sibling route inside the existing `/audit` operator family, with no new UI family, no mutation handlers, and URL-driven navigation via `handle_params/3`. |
| `SURF-02` | ✓ SATISFIED | The mounted view presents the same evidence facts and verdict vocabulary (`proven`, `inferred_posture`, `unsupported`) as the library API and Mix-task paths via the shared `Threadline.Evidence.Proof` presenter, with the locked Phase 98 copy literals (per `98-UI-SPEC.md` Copywriting Contract) rendered at the cited source lines and asserted by the existing LiveView test suite. |
| `SURF-03` | ✓ SATISFIED | Host-owned authorization remains the gate via `evidence_authorize_fn`, defaulting fail-closed to `fn _ -> false end`, with no Threadline-owned RBAC, tenant DSL, or persona semantics introduced in `lib/threadline/operator_surface/`. |
```

### 3.7 Verbatim `## Behavioral Spot-Checks` table (mirror Phase 100's at `100-VERIFICATION.md` lines 39-44)

Phase 100's Behavioral Spot-Checks table is rendered in `100-VERIFICATION.md` (the Phase 102-of-102 verifier output, not the Phase 95 artifact itself). Phase 102's `98-VERIFICATION.md` does NOT need this table — the Behavioral Spot-Checks table is a feature of the verifier-output shape, not the phase-VERIFICATION-artifact shape. **Do not include `## Behavioral Spot-Checks` in `98-VERIFICATION.md`.** The behavioral evidence is captured per-band in the `### Evidence` blocks inside Bands 1/2/3. *(The verifier will produce its own `102-VERIFICATION.md` with that table when `/gsd:verify-work` runs after Phase 102 ships — that artifact is downstream of Phase 102, not authored by it.)*

### 3.8 Verbatim `## Not closed here` template (from `95-VERIFICATION.md` lines 89-94, retargeted per D-20)

```markdown
## Not closed here

- `.planning/REQUIREMENTS.md` remains intentionally unreconciled in this phase.
- `.planning/ROADMAP.md` remains intentionally unreconciled in this phase.
- `.planning/STATE.md` remains intentionally unreconciled in this phase.
- The visual hierarchy, spacing tokens (4/8/16/24/32/48px), typography sizing, color palette, and scanability portions of `98-UI-SPEC.md` remain Manual-Only per `98-VALIDATION.md` and are not grep-anchored here.
- Phase 102 closes the missing Phase 98 verification and validation chain only; milestone authority-surface reconciliation remains Phase 103 work.
```

## 4. `98-VALIDATION.md` Modernization Plan

Exact line-level change list against the current `.planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md`:

### 4.1 Frontmatter flip targets

| Line | Current | Replace with | Why |
|------|---------|--------------|-----|
| 4 | `status: draft` | `status: validated` | Mirrors `95-VALIDATION.md:4` after Phase 100 finalized it |
| 5 | `nyquist_compliant: false` | `nyquist_compliant: true` | D-14; per Phase 101 D-16 retroactive backfill is honest backfill |
| 6 | `wave_0_complete: false` | `wave_0_complete: true` | D-14; Wave 0 test files exist on disk and pass |
| (insert after line 7) | (none) | `updated: 2026-05-27T<HH:MM:SSZ>` | Mirrors `95-VALIDATION.md:8` — records the update event |

### 4.2 Retroactive-backfill note (per D-14)

The opening block-quote currently at line 12-13 reads:

```markdown
> Per-phase validation contract for feedback sampling during execution.
```

Replace with:

```markdown
> Per-phase validation contract for feedback sampling during execution.
> Phase 98 is now closed against the current-tree rerun bundle recorded in
> `98-VERIFICATION.md`, not against summary prose alone.
>
> **Retroactive backfill note:** Wave 0 evidence was reconstructed retroactively
> from the current tree as part of Phase 102; original Phase 98 execution did
> not produce a Nyquist-compliant artifact. The `nyquist_compliant: true` and
> `wave_0_complete: true` flags reflect post-hoc verification of pre-existing
> implementation, not in-line Wave 0 execution. The focused two-file rerun
> bundle named below is the authority, not `mix verify.test`.
```

This mirrors the prose pattern that Phase 101's `96-VALIDATION.md` finalization would have used (the file was not actually executed with a retroactive note — but D-14 explicitly cites Phase 101 D-16 as the merge-theater guard). The two-paragraph shape (strategy + retroactive note) is what distinguishes a Phase 102 finalization from a clean Wave 0 close.

### 4.3 Authority-band swap (per D-18) — the smallest literal-truth repair

| Line | Current | Replace with | Why |
|------|---------|--------------|-----|
| 22 (Quick run command) | `MIX_ENV=test mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` | `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` | Drop `MIX_ENV=test` prefix for symmetry with `95-VALIDATION.md:25` and `96-VALIDATION.md:21` finalized analogs (which do not include it). This is cosmetic literal-truth alignment, not a behavioral change. |
| 23 (Full suite command) | `mix verify.test` | `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` | **D-18 — the canonical authority swap.** Same as Quick run command because the focused bundle IS the authority per D-08 (no broader band exists for Phase 98). |
| 24 (Estimated runtime) | `~45 seconds` | `~10-30 seconds warm` | Live measurement at research time was 0.2 seconds; the `~10-30 seconds warm` range matches `96-VALIDATION.md:24` and accounts for cold-start variation. |

### 4.4 Per-Task Verification Map status drift (lines 41-43)

Flip all three Status cells from `⬜ pending` to `✅ green` after 102-01 passes. No column changes — the existing 10-column shape (`Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status`) already matches the modern Nyquist convention from `95-VALIDATION.md:43`.

Also drop the `MIX_ENV=test` prefix from the three `Automated Command` cells (lines 41, 42, 43) for the same symmetry reason as §4.3.

### 4.5 `## Commands Actually Used` placement (per D-15)

Lands immediately after the Per-Task Verification Map block (current line 45 `*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*`) and before the Wave 0 Requirements section (current line 49 `## Wave 0 Requirements`). Insert this exact block at the `---` separator (current line 47) — replace it with:

```markdown
---

## Commands Actually Used

1. `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1`
   Result: PASS (`34 tests, 0 failures`)

---
```

Single numbered entry, mirroring `95-VALIDATION.md:54-61` (which has three entries because Phase 95 had three test files). Phase 102's structural greps live in `98-VERIFICATION.md` per D-15, not in the validation command ledger. The `34 tests, 0 failures` count is the live observation from §2.4.

### 4.6 `## Phase Boundary Guard` section (new)

Lands after `## Manual-Only Verifications` (current line 60) and before `## Validation Sign-Off` (current line 64). Insert verbatim from `95-VALIDATION.md:83-90`, retargeted to Phase 98:

```markdown
---

## Phase Boundary Guard

- `98-VALIDATION.md` closes `SURF-01`, `SURF-02`, and `SURF-03` only.
- `.planning/REQUIREMENTS.md` was not reconciled here.
- `.planning/ROADMAP.md` was not reconciled here.
- `.planning/STATE.md` was not reconciled here.
- Visual hierarchy, spacing tokens, typography sizing, color palette, and scanability portions of `98-UI-SPEC.md` remain Manual-Only and are not grep-anchored in `98-VERIFICATION.md`.
- Phase 99 (already shipped contract-lock + final verification), Phase 100 (Phase 95 backfill), Phase 101 (Phase 96 backfill), and Phase 103 (authority-surface reconciliation) work remains outside this validation artifact.
```

### 4.7 `## Wave 0 Requirements` checkbox flip (lines 50-52)

Both `[ ]` checkboxes flip to `[x]` (both test files exist on disk and the focused bundle passes). Phrasing can stay literally as-is, with checkbox marks updated.

### 4.8 Validation Sign-Off checkbox flips (lines 66-71)

| Line | Current | Replace with |
|------|---------|--------------|
| 66 | `- [ ] All tasks have <automated> verify or Wave 0 dependencies` | `- [x] All executed tasks have explicit automated verification coverage.` |
| 67 | `- [ ] Sampling continuity: no 3 consecutive tasks without automated verify` | `- [x] Sampling continuity stayed below the three-task Nyquist gap.` |
| 68 | `- [ ] Wave 0 covers all MISSING references` | `- [x] The validation artifact records the exact rerun bundle used to close SURF-01, SURF-02, and SURF-03.` |
| 69 | `- [ ] No watch-mode flags` | (delete — Phase 102 does not introduce watch-mode flags; the line is vestigial from a draft Wave 0 template) |
| 70 | `- [ ] Feedback latency < 45s` | `- [x] Feedback latency under 30s confirmed by live measurement (0.2s warm).` |
| 71 | `- [ ] nyquist_compliant: true set in frontmatter` | `- [x] nyquist_compliant: true set in frontmatter (per D-14 retroactive-backfill posture).` |

(Optional sixth checkbox from `95-VALIDATION.md:99`: `- [x] Phase-boundary limits are stated explicitly so this artifact does not overclaim authority-surface reconciliation.`)

### 4.9 Approval line (line 73)

| Current | Replace with |
|---------|--------------|
| `**Approval:** pending` | `**Approval:** finalized on 2026-05-27 after Phase 102-01 produced 98-VERIFICATION.md and the current-tree rerun bundle passed.` |

(Mirrors `95-VALIDATION.md:101` and `96-VALIDATION.md:65` shape.)

## 5. Proof Method Inventory — Per-Band Exact Commands

All commands validated against the current tree at research time (HEAD `1db8e8e`). Live result shown for each. The planner embeds these verbatim in plan tasks.

### 5.1 Band 1 (SURF-01) — read-only `/audit/evidence` mount inside `/audit`

**Structural primary (mount-shape):**
```bash
rg -n 'live\("/evidence"' lib/threadline/operator_surface/router.ex
```
Live result: `100:            live("/evidence", EvidenceLive, :index)` — exactly one match, inside the `live_session :threadline` block opened at line 89 and closed at line 109. PASS.

**Structural primary (read-only, no mutation handlers):**
```bash
rg -n '^\s*def handle_event' lib/threadline/operator_surface/live/evidence_live.ex
```
Live result: exit code 1 (zero matches). PASS — negative assertion.

**Arity citation (inline in artifact prose, not a command):**
> `EvidenceLive` defines only `mount/3` (line 12), `handle_params/3` (line 21), and `render/1` (line 49). No `handle_event/3` is defined.

**Behavioral support:**
```bash
mix test test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1
```
Expected: 5 tests, 0 failures (the file contains exactly 5 `test ` blocks per `rg -c '^\s*test '`).

### 5.2 Band 2 (SURF-02) — shared presenter + locked copy literals

**Structural primary (shared presenter wiring):**
```bash
rg -n 'alias Threadline\.Evidence\.Proof|Proof\.present_record' lib/threadline/operator_surface/live/evidence_live.ex
```
Live result: `8:    alias Threadline.Evidence.Proof` + `253:      presented = Proof.present_record(record)`. PASS — exactly two matches, confirming alias + call site.

**Structural primary (verdict vocabulary canonical source — supplements CONTEXT.md D-12 row 2 per §2.2 nuance):**
```bash
rg -n '@semantic_statuses' lib/threadline/evidence/proof.ex
```
Live result: `10:  @semantic_statuses ~w(proven inferred_posture unsupported)`. PASS — proves the verdict triple originates in the shared presenter module, not the LiveView.

**Structural primary (locked copy literals — five `rg -nF` commands, one per D-12 row):**

```bash
# Row 1 — "What can Threadline prove right now?"
rg -nF 'What can Threadline prove right now?' lib/threadline/operator_surface/live/evidence_live.ex test/threadline/operator_surface/live/evidence_live_test.exs
```
Live result: 3 matches — source `evidence_live.ex:67`, test `evidence_live_test.exs:115` (refute, denied-state), test `evidence_live_test.exs:150` (assert, overview). PASS.

```bash
# Row 3 — "View history"
rg -nF 'View history' lib/threadline/operator_surface/live/evidence_live.ex test/threadline/operator_surface/live/evidence_live_test.exs
```
Live result: 2 matches — source `evidence_live.ex:142`, test `evidence_live_test.exs:152`. PASS.

```bash
# Row 4 — "No evidence records yet"
rg -nF 'No evidence records yet' lib/threadline/operator_surface/live/evidence_live.ex test/threadline/operator_surface/live/evidence_live_test.exs
```
Live result: 2 matches — source `evidence_live.ex:89`, test `evidence_live_test.exs:213`. PASS.

```bash
# Row 5 — "Evidence view unavailable."
rg -nF 'Evidence view unavailable.' lib/threadline/operator_surface/unsupported.ex lib/threadline/operator_surface/live/evidence_live.ex test/threadline/operator_surface/live/evidence_live_test.exs
```
Live result: 2 matches — source `unsupported.ex:25` (the descriptor body, rendered via the `:evidence_unavailable` descriptor at `evidence_live.ex:154`), test `evidence_live_test.exs:113`. PASS.

```bash
# Row 2 — verdict triple (positive assertions in test only — source is dynamic via row.verdict_status)
rg -nF -e 'proven' -e 'inferred_posture' -e 'unsupported' test/threadline/operator_surface/live/evidence_live_test.exs
```
Live result includes assertions at test lines 153, 154, 155. The vocabulary itself originates from `proof.ex:10` (covered by the `@semantic_statuses` grep above).

**Behavioral primary (vocabulary in rendered HTML):**
```bash
mix test test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1
```
Expected: 5 tests, 0 failures. Covers verdict vocabulary at lines 153-155, "View history" at 152, empty-state at 213, denied-state at 113.

### 5.3 Band 3 (SURF-03) — host-owned `evidence_authorize_fn` gate, no Threadline RBAC

**Structural primary (negative assertion — no Threadline-owned RBAC modules):**
```bash
rg -n 'Threadline\.RBAC|Threadline\.Permissions|Threadline\.Policy\.RBAC' lib/threadline/operator_surface/
```
Live result: exit code 1 (zero matches). PASS — negative assertion.

**Structural primary (positive-control PAIRED grep per D-07 — prevents silent-pass on path typo):**
```bash
rg -n 'evidence_authorize_fn' lib/threadline/operator_surface/auth.ex
```
Live result: 5 matches at lines 254, 259, 265, 266, 269. The line-254 match is the canonical `Keyword.get(opts, :evidence_authorize_fn, fn _ -> false end)` fail-closed default. PASS.

**Arity citation (inline in artifact prose, not a command):**
> `evidence_authorize_fn` is a host-supplied function value of shape `(%{assigns: map()} -> boolean | :ok | {:ok, scope} | _)`. The callback dispatch happens at `auth.ex:269` (`evidence_authorize_fn.(mirror)`) where `mirror = %{assigns: socket.assigns}` (`auth.ex:267`) — no Threadline-owned module dispatch, no behaviour implementation, no protocol consumer. The fail-closed default `fn _ -> false end` ensures denial when the host omits the opt entirely.

**Behavioral primary (fail-closed denial path):**
```bash
mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1
```
Expected: 34 tests, 0 failures (the focused rerun bundle). Covers the `assign_evidence_enabled` capability fan-out at `auth_test.exs:337-394` (6 tests in `describe "assign_evidence_enabled"`) plus the denied-state HTML rendering at `evidence_live_test.exs:106-116`.

### 5.4 Authority statement (closing section of `98-VERIFICATION.md`, mirrors `96-VERIFICATION.md` lines 112-120)

The authoritative Phase 98 rerun bundle is:

1. `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1`
2. `rg -n 'live\("/evidence"' lib/threadline/operator_surface/router.ex` (Band 1)
3. `rg -n '^\s*def handle_event' lib/threadline/operator_surface/live/evidence_live.ex` (Band 1)
4. `rg -n 'alias Threadline\.Evidence\.Proof|Proof\.present_record' lib/threadline/operator_surface/live/evidence_live.ex` (Band 2)
5. `rg -n 'Threadline\.RBAC|Threadline\.Permissions|Threadline\.Policy\.RBAC' lib/threadline/operator_surface/` (Band 3 negative)
6. `rg -n 'evidence_authorize_fn' lib/threadline/operator_surface/auth.ex` (Band 3 positive control)

`mix verify.test` is intentionally not the authority for Phase 98. The Phase 98-02 summary (`98-02-SUMMARY.md:80-90`) records a pre-existing alias-drift failure in `Threadline.CiTopologyContractTest` that is outside Phase 98 ownership; Phase 99 owns the named-alias topology, and commit `b636c17` ("fix(99-02): update ci.all topology contract to expanded doc_contract alias") is the most recent fix on that surface. Phase 102 disclaims rather than reopens that scope.

## 6. Rerun Bundle Authority — Live Confirmation

Per D-08, the authoritative command is:

```bash
mix test test/threadline/operator_surface/auth_test.exs \
         test/threadline/operator_surface/live/evidence_live_test.exs \
         --max-failures 1
```

**Both test files exist on disk at research time:**
- `test/threadline/operator_surface/auth_test.exs` — 29 tests across multiple `describe` blocks (`on_mount/4 session extraction` ×5, `on_mount/4` ×8, `assign_coverage_enabled` ×5, `assign_policy_enabled` ×5, `assign_evidence_enabled` ×6). The 6 tests in `describe "assign_evidence_enabled"` (lines 337-394) own the SURF-03 capability-boolean fan-out at unit scope.
- `test/threadline/operator_surface/live/evidence_live_test.exs` — 5 tests in one `describe "mount /audit/evidence"` block (lines 105-217). All 5 own SURF-01 mount and SURF-02 parity at LiveView scope. Test 1 (line 106) owns the SURF-03 denied-state HTML rendering.

**Live execution result at research time (HEAD `1db8e8e`):**
```
Running ExUnit with seed: 198450, max_cases: 36
Excluding tags: [pgbouncer_topology: true]

..................................
Finished in 0.2 seconds (0.1s async, 0.1s sync)
34 tests, 0 failures
```

✅ **34/0 PASS confirmed.** Matches CONTEXT.md D-08 exactly. The expected `Result:` line in `98-VERIFICATION.md` will be `Result: PASS (34 tests, 0 failures)`.

**Pre-existing failures recorded in summaries:** `98-02-SUMMARY.md:70-74` records that `mix verify.test` still fails at Phase 98 closeout time on the unrelated `Threadline.CiTopologyContractTest` assertion (alias-drift). The focused bundle does NOT include that test file, so it is unaffected. D-10 captures the carry-forward disclaimer; the band-3 authority statement names Phase 99 commit `b636c17` as the most recent fix.

**No divergence to repair.** The planner can take the 34/0 number as the authority for both the `98-VERIFICATION.md` band-evidence blocks and the `98-VALIDATION.md` `## Commands Actually Used` section without re-running between 102-01 and 102-02 — though running once per plan is the safest discipline (per the §8 sampling rate).

## 7. Validation Architecture

> Included per Step 4 of the workflow (nyquist_validation is not explicitly disabled in `.planning/config.json`, so it is enabled). Section name is literally `## Validation Architecture` for the workflow Step 5.5 grep.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5) + Phoenix.LiveView 1.x + Ecto/PostgreSQL via `Threadline.DataCase` + ripgrep (`rg`) for structural and artifact greps |
| Config file | `mix.exs`, `config/test.exs`, `test/test_helper.exs`, `.planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md`, `.planning/phases/98-mounted-evidence-views-on-audit/98-VERIFICATION.md` (created by 102-01) |
| Quick run command | `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` |
| Full suite command | Same as Quick run — the focused two-file bundle IS the authority per D-08 |
| Estimated runtime | ~10-30 seconds warm (live measurement at research time: 0.2 seconds) |

### Phase Requirements → Test Map (Nyquist dimensions 1-8)

For a verification-backfill phase, each Nyquist dimension is evaluated against the paperwork posture (no code changes beyond literal-truth repair), not against fresh-feature delivery. Below are the eight dimensions named in the standard Nyquist shape (per the verifier-output convention in `100-VALIDATION.md`, `95-VALIDATION.md`, and `96-VALIDATION.md`).

| # | Dimension | Applies | Proof Method | Sampling Rate | Rationale |
|---|-----------|---------|--------------|---------------|-----------|
| 1 | **Per-task automated verification** | yes | Each plan task carries an `<automated>` block that runs the focused bundle plus the relevant structural greps. | Per task commit (~30s warm). | The full Phase 98 contract is covered by 34 existing tests + 6 structural greps; no task ships without at least one of these executing. |
| 2 | **Sampling continuity (no 3-task gap)** | yes | Plans 102-01 and 102-02 each have ≤2 tasks per Phase 100/101 plan shape, all tasks have `<verify><automated>`. | Per-wave check. | Verification-backfill plans are short; Nyquist sampling cannot drift beyond a single wave. |
| 3 | **Wave 0 covers all MISSING references** | yes | Wave 0 requirements list both `98-VERIFICATION.md` (created by 102-01) and the two new validation sections (`## Commands Actually Used`, `## Phase Boundary Guard`, added by 102-02). | Wave 0 dependency tracking in PLAN frontmatter. | All test files and source files already exist on disk; only paperwork artifacts are net-new. |
| 4 | **No watch-mode flags** | yes (negative — no watch flags introduced) | Plans cite `mix test … --max-failures 1`, not `--listen-on-stdin` or `--stale`. | Plan-time grep against PLAN.md files. | Paperwork phase; watch mode is irrelevant. |
| 5 | **Feedback latency under 30s** | yes | Live measurement at research time: 0.2 seconds for the focused bundle. | Per task commit. | Bundle is two test files; warm-cache execution is sub-second. |
| 6 | **Artifact existence proof** | yes | `rg -n` against both `98-VERIFICATION.md` and `98-VALIDATION.md` confirms all required structural markers (frontmatter keys, band headings, `## Commands Actually Used`, `## Phase Boundary Guard`, requirement closure rows). | Per plan completion. | Artifact-presence greps are the canonical Phase 100/101 verify-work shape (see `101-VERIFICATION.md` lines 24-31). |
| 7 | **Phase boundary guard (no milestone-authority writes)** | yes | `git diff` against `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` after both plans must show zero changes from Phase 102 commits. | Per-wave + phase-gate. | D-19 explicitly forbids these writes; mirrors Phase 101 D-17 enforcement at `101-VERIFICATION.md:29-30`. |
| 8 | **Retroactive-backfill honesty** | yes (Phase-102-specific) | `rg -nF 'Retroactive backfill note' .planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md` returns exactly one match after 102-02. | Plan 102-02 verify-work. | D-14 requires this note; without it the frontmatter flip reads as merge-theater. This dimension is what differentiates Phase 102's validation modernization from a clean Wave 0 close. |

### Sampling Rate

- **After every task commit:** `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` (every task in 102-01 that touches verification artifact prose; 102-02 is artifact-only and may skip).
- **After every plan wave:** same focused bundle plus the six structural greps from §5.
- **Phase gate:** focused bundle green + all six grep assertions pass + artifact grep on `98-VERIFICATION.md` shows all required markers + artifact grep on `98-VALIDATION.md` shows updated frontmatter, `## Commands Actually Used`, `## Phase Boundary Guard`, and the retroactive-backfill note + `git diff` against milestone authority surfaces is empty.

### Wave 0 Gaps

- [ ] `.planning/phases/98-mounted-evidence-views-on-audit/98-VERIFICATION.md` — to be created in 102-01 (D-01..D-04, D-09, D-11..D-13, D-20).
- [ ] `## Commands Actually Used` section in `98-VALIDATION.md` — to be added in 102-02 (D-15).
- [ ] `## Phase Boundary Guard` section in `98-VALIDATION.md` — to be added in 102-02.
- [ ] Retroactive-backfill note in `98-VALIDATION.md` opening block-quote — to be added in 102-02 (D-14).

*(No code/test gaps: the focused-bundle tests, the implementation modules, the auth gate, the unsupported descriptor, the shared presenter, and all five UI-SPEC literal targets exist on the current tree at research time and pass live execution.)*

## 8. Risks & Edge Cases

### Risk 1 — UI-SPEC literal drift (D-17 says repair source, not UI-SPEC)

**What goes wrong:** 102-01 finds that the verdict triple at `evidence_live.ex:116-118` is dynamically rendered via `{row.verdict_status}`, not as static literals. A reviewer concludes the UI-SPEC line 88 claim is unverifiable and proposes weakening the UI-SPEC to drop the verdict-triple row.
**Why it happens:** Dynamic interpolation looks like an absence of the literal at first glance.
**How to avoid:** Per D-17, the smallest repair is **never** to update the UI-SPEC. The verdict triple IS verified: the literals are defined at `lib/threadline/evidence/proof.ex:10` (`@semantic_statuses ~w(proven inferred_posture unsupported)`) and the LiveView renders them via `Proof.present_record/1` (a fact already asserted by the test suite at `evidence_live_test.exs:153-155`). The Band 2 prose must cite both the dynamic-render site (`evidence_live.ex:117`) AND the canonical-literal source (`proof.ex:10`).
**Warning signs:** any task action containing the words "update 98-UI-SPEC.md" or "relax the verdict claim".

### Risk 2 — `mix verify.test` alias-drift disclaimer omitted

**What goes wrong:** 102-01 honors CLAUDE.md's "prefer `mix verify.*` aliases" guidance and quietly runs `mix verify.test`. The carry-forward `Threadline.CiTopologyContractTest` failure (per `98-02-SUMMARY.md:70-74`) trips the bundle red. The planner spends 102-01 trying to repair Phase 99 territory.
**Why it happens:** CLAUDE.md's CI conventions section is generally authoritative; instinct says to honor it.
**How to avoid:** Per D-08/D-10, the focused bundle is the authority for Phase 98 specifically. The Band 3 authority statement (§5.4 above) MUST disclaim `mix verify.test` and name Phase 99 commit `b636c17` as the most recent fix.
**Warning signs:** any band's `### Evidence` block cites `mix verify.test`; any task action contains "run mix verify.test as authority".

### Risk 3 — Merge-theater risk if D-14 retroactive note is omitted

**What goes wrong:** 102-02 flips `nyquist_compliant: false → true` and `wave_0_complete: false → true` without adding the retroactive-backfill note in the opening block-quote. The artifact now reads as if Wave 0 was completed in-line with Phase 98 execution, which is false — it was reconstructed post-hoc by Phase 102. This is the literal "merge theater" pattern Phase 101 D-16 warned against.
**Why it happens:** Frontmatter flips are mechanically straightforward; the note feels like prose padding.
**How to avoid:** Per D-14, the note is non-negotiable. §4.2 above gives the exact prose. The verify-work grep MUST include `rg -nF 'Retroactive backfill note' .planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md` and expect exactly one match.
**Warning signs:** the `98-VALIDATION.md` diff after 102-02 changes only the frontmatter three-key block, with no body changes.

### Risk 4 — Milestone-authority-surface boundary leak (D-19, D-20)

**What goes wrong:** A well-meaning task in 102-01 or 102-02 flips the SURF-01/02/03 checkboxes from `[ ]` to `[x]` in `.planning/REQUIREMENTS.md` (line 22-24) or in `.planning/ROADMAP.md` line 118-119. This pre-empts Phase 103's authority-surface reconciliation and creates the same audit-drift Phase 102 is supposed to repair (just for a different milestone).
**Why it happens:** It feels "natural" to mark the requirement complete once the verification artifact closes it; CLAUDE.md and discipline say "honest default tests" which suggests honest default status.
**How to avoid:** Per D-19, Phase 102 MUST NOT touch REQUIREMENTS.md/ROADMAP.md/STATE.md. The verify-work step MUST include `git diff HEAD .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/STATE.md` returning empty. Phase 101's `101-VERIFICATION.md:30` already established this pattern as Truth #7.
**Warning signs:** any task `files_modified:` frontmatter list contains `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, or `.planning/STATE.md`.

### Risk 5 — Test-count miscount on the rerun

**What goes wrong:** `98-VERIFICATION.md` Band records say `Result: PASS (34 tests, 0 failures)` but the actual rerun reports 33 or 35 because a test was added/removed between research and execution.
**Why it happens:** Research can predict but cannot lock the test count; the planner copies the research number without re-running.
**How to avoid:** Record the literal output the planner observes. The expected count is 34 (live confirmed at HEAD `1db8e8e`), but the artifact must record what the planner's rerun actually printed.
**Warning signs:** the `Result:` count in any band was copied from RESEARCH.md without rerun confirmation.

### Risk 6 — Dynamic verdict rendering misread as missing literal (Band 2)

**What goes wrong:** A reviewer running `rg -nF 'proven' lib/threadline/operator_surface/live/evidence_live.ex` returns zero matches and concludes Band 2 fails — but the literal lives in `lib/threadline/evidence/proof.ex:10` and is rendered through `{row.verdict_status}` at `evidence_live.ex:117`.
**Why it happens:** D-12 row 2 cites `evidence_live.ex:116-118` as the source location, which is the **render site**, not the **literal-defining site**.
**How to avoid:** Use the dual grep in §5.2 — one for `@semantic_statuses` in `proof.ex` (canonical literal source), one for the assertions in `evidence_live_test.exs:153-155` (proves the literal renders in HTML). The Band 2 prose must cite both.
**Warning signs:** a Band 2 `### Evidence` block contains only `rg -nF 'proven' lib/threadline/operator_surface/live/evidence_live.ex` (no `proof.ex` companion) and shows zero matches.

## 9. Plan Boundaries — explicit 102-01 vs 102-02 split

The planner MUST split work this way to avoid double-writes:

### 102-01 owns

- Reading the current tree fingerprint (re-confirm §2 citations live).
- Executing the focused rerun bundle (`mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1`) and recording the literal `N tests, 0 failures` output.
- Executing the six structural greps from §5 and recording their literal results.
- Writing `98-VERIFICATION.md` (NEW) per the §3 skeleton — frontmatter, `## Current-tree preflight`, three numbered bands per §3.5, requirement closure per §3.6, `## Not closed here` per §3.8.
- The smallest literal-truth repair on `98-VALIDATION.md`: swap line 23 Full suite command from `mix verify.test` to the focused bundle (per D-18); optionally drop `MIX_ENV=test` prefix from lines 22, 41, 42, 43 for symmetry with 95/96 (per §4.3). NOTHING else in `98-VALIDATION.md` changes in 102-01.

### 102-02 owns (depends on 102-01)

- Finalizing `98-VALIDATION.md`: frontmatter flip per §4.1, retroactive-backfill note per §4.2 (D-14), Per-Task Verification Map status flip per §4.4, add `## Commands Actually Used` per §4.5 (D-15), add `## Phase Boundary Guard` per §4.6, flip Wave 0 checkboxes per §4.7, flip Validation Sign-Off checkboxes per §4.8, update Approval line per §4.9.
- The verify-work step: `rg -n` against both artifacts confirming all structural markers; `git diff` against milestone authority surfaces confirming empty.

### Neither plan owns

- ❌ Any change to `lib/threadline/operator_surface/live/evidence_live.ex`, `lib/threadline/operator_surface/auth.ex`, `lib/threadline/operator_surface/router.ex`, `lib/threadline/operator_surface/unsupported.ex`, or `lib/threadline/evidence/proof.ex` (D-16 forbids new feature work; current tree is the authority).
- ❌ Any change to `test/threadline/operator_surface/auth_test.exs` or `test/threadline/operator_surface/live/evidence_live_test.exs` (D-16 forbids new tests).
- ❌ Any change to `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, or `.planning/STATE.md` (D-19 — Phase 103).
- ❌ Any change to `.planning/phases/98-mounted-evidence-views-on-audit/98-UI-SPEC.md` body (D-17 — code is the realization, UI-SPEC is the contract).
- ❌ Any attempt to repair `mix verify.test` alias-drift (D-10 — Phase 99 owns; commit `b636c17` is the most recent fix).

### Threat IDs the planner should use

Mirroring Phase 100's `T-100-NN` and Phase 101's `T-101-NN` pattern, use `T-102-NN`:

- `T-102-01` Tampering — mount-shape (Band 1 owner: structural mount grep + read-only grep)
- `T-102-02` Tampering — read-only handler closed set (Band 1 owner: arity citation)
- `T-102-03` Spoofing — shared-presenter parity (Band 2 owner: alias + call-site grep)
- `T-102-04` Spoofing — locked UI-SPEC literals (Band 2 owner: five `rg -nF` greps)
- `T-102-05` Elevation of Privilege — fail-closed host gate (Band 3 owner: positive-control grep + arity citation + auth_test.exs fan-out)
- `T-102-06` Elevation of Privilege — no Threadline-owned RBAC (Band 3 owner: negative grep)
- `T-102-07` Repudiation — retroactive-backfill honesty (102-02 owner: D-14 note grep)
- `T-102-08` Tampering — milestone authority-surface boundary (both plans: empty `git diff` against REQUIREMENTS/ROADMAP/STATE)

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The focused rerun bundle (34 tests across 2 files) will pass on the current tree at planning time without code edits. | §6 Rerun Bundle Authority | LOW — verified live at research time on HEAD `1db8e8e` with `34 tests, 0 failures` in 0.2s. If a test fails unexpectedly at planning time, the planner must escalate per D-16 (literal-truth repair only). |
| A2 | The 3-band split (SURF-01, SURF-02, SURF-03) reads cleanly in numeric order. | §3.5 Verbatim band-title candidates | LOW — D-03 fixes the three bands; band ordering is Claude's Discretion per CONTEXT.md `<decisions>` last paragraph. |
| A3 | The Per-Task Verification Map should retain the existing 10-column shape from `98-VALIDATION.md:39-43`. | §4.4 | LOW — the 10 columns already match the modern Nyquist convention from `95-VALIDATION.md:43`. |
| A4 | `mix verify.test` alias-drift was actually fixed by commit `b636c17` — but Phase 102 does not re-run it to confirm. | §5.4 Authority statement | LOW — even if it is still broken, the disclaim posture works (Phase 99 is the owner). MEDIUM if the planner is tempted to test it; per D-08 they should not. |
| A5 | The Band 2 dynamic-render nuance (verdict triple literal lives in `proof.ex:10`, not `evidence_live.ex:116-118`) is correctly captured by the dual-grep approach in §5.2. | §2.2 + §5.2 | LOW — both the `@semantic_statuses` grep and the existing test assertions at `evidence_live_test.exs:153-155` independently prove the vocabulary is in scope and rendered. |
| A6 | The retroactive-backfill note shape proposed in §4.2 reads as honest backfill rather than apologetic prose. | §4.2 | LOW — exact wording is Claude's Discretion per the CONTEXT.md `<decisions>` last paragraph; the §4.2 prose mirrors the spirit of Phase 101 D-16 explicitly. |
| A7 | The Behavioral Spot-Checks table does NOT belong in `98-VERIFICATION.md` (it's a verifier-output feature, not a phase-VERIFICATION-artifact feature). | §3.7 | LOW — comparison of `95-VERIFICATION.md`, `96-VERIFICATION.md`, and `99-VERIFICATION.md` against `100-VERIFICATION.md` and `101-VERIFICATION.md` confirms: phase-VERIFICATION artifacts contain bands + closure + "Not closed here" only; verifier-output artifacts add Observable Truths, Behavioral Spot-Checks, and Requirements Coverage tables. The pattern is consistent across Phases 95-101. |

## Open Questions (RESOLVED)

None — every question raised during research was answered by either CONTEXT.md decisions or live current-tree verification.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir + Mix | rerun bundle execution | ✓ | 1.19.5 (per `96-RESEARCH.md:150`) | — |
| Phoenix.LiveView | `EvidenceLive` + LiveView tests in the focused bundle | ✓ | 1.x (per `mix.lock`) | none |
| PostgreSQL (local) | `Threadline.DataCase` setup in `evidence_live_test.exs:62` and Repo inserts (line 102) | ✓ | (confirmed at research time — focused bundle ran in 0.2s) | none for integration tests |
| ripgrep (`rg`) | structural grep + closed-set grep + artifact-content greps | ✓ | (used throughout this research; required by Phase 100/101 plan verification) | `grep -E` would also work but the plans cite `rg` verbatim |
| `mix verify.test` (or `mix verify.*` aliases) | NOT required by Phase 102 contract | — | n/a | not needed — focused bundle is the authority per D-08 |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (carry-forward, host-owned) | Phase 98 enforces host-supplied `evidence_authorize_fn` callback at `auth.ex:254`; Threadline owns the gate plumbing (`assign_evidence_enabled/2`) but never the auth identity model. Phase 102 verifies the gate seam stays in place; it does not add new auth. |
| V3 Session Management | no | No session surface added or modified in scope. Phase 98 reads session via `maybe_assign_session_user/2` (`auth.ex:159`) and `maybe_assign_session_actor/2` (`auth.ex:96`) which were established before Phase 98 and remain unchanged. |
| V4 Access Control | yes (carry-forward) | `evidence_authorize_fn` is a per-capability access-control gate. Band 3 verifies the fail-closed default (`fn _ -> false end` at line 254) and the negative absence of Threadline-owned RBAC. Phase 102 does not add new access controls. |
| V5 Input Validation | yes (carry-forward) | `EvidenceLive.parse_request/1` (line 163) validates `subject` against `Threadline.Evidence.Subject.validate/1` (line 175), `subject_ref_json` via `Jason.decode` (line 188), and `mode` against a closed inventory (line 196). Phase 102 verifies these stay in place via the focused bundle's HTML assertions; it does not add new validators. |
| V6 Cryptography | no | No crypto surface in scope. |

### Known Threat Patterns for the Phase 98 contract on the current tree

| Pattern | STRIDE | Standard Mitigation | Verified by Phase 102 |
|---------|--------|---------------------|-----------------------|
| Mount-shape drift (new UI family added accidentally) | Tampering | Sibling-route mount inside `live_session :threadline`; Band 1 structural grep counts exactly one `live("/evidence"` match | §5.1 Band 1 structural primary |
| Mutation handler introduced on a read-only surface | Tampering | `EvidenceLive` defines no `handle_event/3`; Band 1 negative grep returns zero matches | §5.1 Band 1 structural primary (negative) |
| Verdict vocabulary drift (LiveView invents new statuses) | Spoofing | Vocabulary originates from `proof.ex:10` `@semantic_statuses ~w(proven inferred_posture unsupported)`; LiveView renders via `Proof.present_record/1` only; Band 2 dual grep + behavioral HTML assertions | §5.2 Band 2 structural + behavioral |
| UI-SPEC literal drift (locked copy changes silently) | Spoofing | Band 2 `rg -nF` against five locked literals per D-12; tests at `evidence_live_test.exs:113,150,152,153-155,213` lock the render output | §5.2 Band 2 five literal greps + behavioral |
| Fail-open auth gate (omitting `evidence_authorize_fn` accidentally grants access) | Elevation of Privilege | `Keyword.get(opts, :evidence_authorize_fn, fn _ -> false end)` at `auth.ex:254` — fail-closed default; Band 3 positive-control grep + the 6 tests in `describe "assign_evidence_enabled"` (`auth_test.exs:337-394`) | §5.3 Band 3 positive control + behavioral |
| Threadline-owned RBAC introduced inside `lib/threadline/operator_surface/` | Elevation of Privilege | Negative grep `rg -n 'Threadline\.RBAC\|Threadline\.Permissions\|Threadline\.Policy\.RBAC' lib/threadline/operator_surface/` returns zero matches; paired with positive control to prevent silent-pass on path typo | §5.3 Band 3 negative + positive-control pair |
| Milestone authority-surface drift (REQUIREMENTS/ROADMAP/STATE flipped pre-Phase-103) | Tampering | `git diff` against the three files after Phase 102 must show zero changes | Dimension 7 in §7 + Risk 4 in §8 |
| Merge-theater frontmatter flip (nyquist_compliant: true without backfill note) | Repudiation | D-14 retroactive-backfill note in `98-VALIDATION.md` opening block-quote; verify-work grep expects exactly one match | §4.2 + Dimension 8 in §7 |

## Sources

### Primary (HIGH confidence)

- `/Users/jon/projects/threadline/.planning/phases/102-phase-98-verification-backfill/102-CONTEXT.md` — locked decisions D-01 through D-20 for this phase.
- `/Users/jon/projects/threadline/.planning/phases/100-phase-95-verification-backfill/100-RESEARCH.md` — closest-template research artifact (same gap-closure posture, three requirements → three bands).
- `/Users/jon/projects/threadline/.planning/phases/100-phase-95-verification-backfill/100-VERIFICATION.md` — verifier-output shape (used to confirm Behavioral Spot-Checks belongs in verifier output, not phase artifact).
- `/Users/jon/projects/threadline/.planning/phases/100-phase-95-verification-backfill/100-VALIDATION.md` — Phase 100's own draft validation shape.
- `/Users/jon/projects/threadline/.planning/phases/100-phase-95-verification-backfill/100-01-PLAN.md` and `100-02-PLAN.md` — exact plan-pair shape for 102-01 and 102-02.
- `/Users/jon/projects/threadline/.planning/phases/101-phase-96-verification-backfill/101-CONTEXT.md` — mixed-posture rationale, retroactive-backfill honesty (D-16), `mix verify.test` disclaimer pattern (D-07).
- `/Users/jon/projects/threadline/.planning/phases/101-phase-96-verification-backfill/101-RESEARCH.md` — alternate-template research artifact (4-band shape; not copied here because Phase 102 has 3 requirements).
- `/Users/jon/projects/threadline/.planning/phases/101-phase-96-verification-backfill/101-VERIFICATION.md` — Phase 101's verifier-output (Phase 102 verifier will produce its own; not the phase-artifact shape).
- `/Users/jon/projects/threadline/.planning/phases/101-phase-96-verification-backfill/101-VALIDATION.md` — Phase 101's own draft validation shape.
- `/Users/jon/projects/threadline/.planning/phases/95-evidence-model-lock-and-scope-guard/95-VERIFICATION.md` — exact-shape template for `98-VERIFICATION.md` (frontmatter, preflight, numbered bands, requirement closure, "Not closed here").
- `/Users/jon/projects/threadline/.planning/phases/95-evidence-model-lock-and-scope-guard/95-VALIDATION.md` — exact-shape template for the modernized `98-VALIDATION.md` (`nyquist_compliant: true`, sampling rate, per-task verification map, `## Commands Actually Used`, `## Phase Boundary Guard`, sign-off).
- `/Users/jon/projects/threadline/.planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md` — second-reference finalized validation (used to cross-confirm the `## Commands Actually Used` placement and `## Phase Boundary Guard` shape).
- `/Users/jon/projects/threadline/.planning/phases/98-mounted-evidence-views-on-audit/98-CONTEXT.md` — locked Phase 98 implementation decisions D-01..D-23 (mount, parity, gating).
- `/Users/jon/projects/threadline/.planning/phases/98-mounted-evidence-views-on-audit/98-UI-SPEC.md` — locked copy contract for SURF-02 (Copywriting Contract at lines 75-90).
- `/Users/jon/projects/threadline/.planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md` — current state (planning-time artifact) of the file 102-02 finalizes.
- `/Users/jon/projects/threadline/.planning/phases/98-mounted-evidence-views-on-audit/98-01-SUMMARY.md` and `98-02-SUMMARY.md` — execution summaries (98-02 records the `mix verify.test` alias-drift carry-forward at lines 70-74).
- `/Users/jon/projects/threadline/.planning/REQUIREMENTS.md` — SURF-01/02/03 definitions (lines 22-24) and Traceability rows (lines 60-62).
- `/Users/jon/projects/threadline/.planning/ROADMAP.md` — Phase 102 goal at lines 110-119; Phase 103 boundary at lines 121-129.
- `/Users/jon/projects/threadline/.planning/STATE.md` — current milestone state ("Phase 102 Not started" at line 27).
- `/Users/jon/projects/threadline/.planning/v1.22-MILESTONE-AUDIT.md` — SURF-01/02/03 audit findings at lines 40-60; tech-debt note for `98-VALIDATION.md` draft state at lines 70-73.
- `/Users/jon/projects/threadline/lib/threadline/operator_surface/router.ex` — `/audit/evidence` mount at line 100 (verified live).
- `/Users/jon/projects/threadline/lib/threadline/operator_surface/live/evidence_live.ex` — full file read; `mount/3` line 12, `handle_params/3` line 21, `render/1` line 49, copy literals at lines 67/89-95/142/154; `alias Threadline.Evidence.Proof` line 8; `Proof.present_record` call site line 253.
- `/Users/jon/projects/threadline/lib/threadline/operator_surface/auth.ex` — full file read; `defp assign_evidence_enabled/2` line 253; fail-closed default `Keyword.get(opts, :evidence_authorize_fn, fn _ -> false end)` at line 254.
- `/Users/jon/projects/threadline/lib/threadline/operator_surface/unsupported.ex` — full file read; `:evidence_unavailable` descriptor body at line 25 contains the locked `Evidence view unavailable.` literal.
- `/Users/jon/projects/threadline/lib/threadline/evidence/proof.ex` — full file read; `@semantic_statuses ~w(proven inferred_posture unsupported)` at line 10; `present_record/1` at line 75 (the shared presenter Band 2 cites).
- `/Users/jon/projects/threadline/test/threadline/operator_surface/live/evidence_live_test.exs` — full file read; 5 tests in `describe "mount /audit/evidence"` at lines 105-217.
- `/Users/jon/projects/threadline/test/threadline/operator_surface/auth_test.exs` — full file read; 29 tests across 5 `describe` blocks, with `describe "assign_evidence_enabled"` at lines 337-394 owning SURF-03 unit-scope fan-out.
- `/Users/jon/projects/threadline/CLAUDE.md` — project verify-alias conventions and three-layer architecture.

### Secondary (MEDIUM confidence)

- Live `rg`/`sed`/`mix test` runs against the current tree at research time (HEAD `1db8e8e`) — confirmed every CONTEXT.md citation matches and the focused rerun bundle passes 34/0 in 0.2s.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Phase 100/101 structural template extraction: HIGH — read all four canonical templates end-to-end.
- Current-tree truth audit: HIGH — read `lib/threadline/operator_surface/router.ex`, `lib/threadline/operator_surface/live/evidence_live.ex`, `lib/threadline/operator_surface/auth.ex`, `lib/threadline/operator_surface/unsupported.ex`, `lib/threadline/evidence/proof.ex`, and both test files in full; confirmed every D-12 source/test line citation live.
- `98-VALIDATION.md` current state: HIGH — read the full file; identified eight concrete repair sites for 102-02.
- Focused rerun bundle verification: HIGH — executed live, confirmed 34/0 in 0.2s.
- Authority-statement disclaim posture: MEDIUM — relies on commit message `b636c17` claim plus `98-02-SUMMARY.md:70-74`. Phase 102 does not re-run `mix verify.test` to confirm (per D-10).
- Validation Architecture section (Nyquist dimensions 1-8): HIGH — derived from CONTEXT.md D-14/D-15 plus the 95/96/100/101 finalized analog shape.

**Research date:** 2026-05-27
**Valid until:** 2026-06-26 (30 days; current-tree facts are stable as long as no one edits `lib/threadline/operator_surface/live/evidence_live.ex`, `lib/threadline/operator_surface/auth.ex`, `lib/threadline/operator_surface/router.ex`, `lib/threadline/operator_surface/unsupported.ex`, `lib/threadline/evidence/proof.ex`, or the two focused test files between research and execution.)

## RESEARCH COMPLETE
