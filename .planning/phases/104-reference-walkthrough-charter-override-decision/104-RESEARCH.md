# Phase 104: Reference-Walkthrough Charter & Override Decision — Research

**Researched:** 2026-05-27
**Domain:** `.planning/` documentation edits (PROJECT.md + MILESTONE-ARC.md)
**Confidence:** HIGH — all findings from direct file reads; zero external lookups needed

---

## Executive Summary

CONTEXT.md is complete and structurally correct. All five decisions (D-01 through D-05) are well-formed and match the voice, density, and structure patterns found in the target files.

**Critical finding — line-number drift:** CONTEXT.md's line number citations are accurate for PROJECT.md. For MILESTONE-ARC.md, the line numbers cited in D-04 items 1–3 (Lines 3, 4, 5) and item 4 (Line 9) are **exact**. Line-specific citations for the option-record row 6 and arc-order v1.22 row are **not given as absolute line numbers** in D-04 — instead D-04 describes them positionally ("Option-record row 6 (Policy / compliance depth)" and "Arc-order v1.22 row"). Actual line numbers are: option-record row 6 is **line 22**, arc-order v1.22 row is **line 34**. The v1.23 arc-order row will be **appended after line 34** (the current last data row of that table). The file is 41 lines total.

**No UI, code, or test concern exists.** This is a pure `.planning/` docs phase. Zero test tasks, zero code tasks.

**No project-local skills directory exists** (`.claude/skills/` absent). No skill constraints apply.

`nyquist_validation` is not explicitly set to `false` in `.planning/config.json` — the Validation Architecture section is required, but for a docs-only phase it is entirely read-based / grep-based / human-cold-read. No automated test commands apply.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Re-engagement trigger definition — three concrete shapes (live-integration issue, maintainer-confirmed pilot host, procurement/security-review/evaluation conversation) + drive-by carve-out + soft-signal routing to `.planning/v1.24-seeds/`.
- **D-02:** Single dense PROJECT.md Key Decisions row with verbatim text supplied; status cell uses `— Active (recorded Phase 104, v1.23, 2026-05-27)`.
- **D-03:** New `**v1.23 non-goals:**` subsection in PROJECT.md `## Current Milestone` block, placed immediately after `**Key context:**` block (after line 29, before line 31), with verbatim bullet content supplied.
- **D-04:** Targeted-fix sweep of MILESTONE-ARC.md — 7 specific edits described with exact target text for header lines 3–5, strategic-thesis paragraph line 9, option-record row 6 status field and Why cell, arc-order v1.22 status field, and new v1.23 arc-order row.
- **D-05:** Record a one-line precedent rule in `104-SUMMARY.md` explaining why the MILESTONE-ARC.md sweep is not a D-02 violation.

### Claude's Discretion

- Whether to use Plan A (one plan, one commit) or Plan B (multiple atomic plans within one commit batch) is the planner's call. User specified "Lock all five as recommended" — implying single-commit framing for the doc-edit atom.
- Exact past-tense rewording of MILESTONE-ARC.md option-record row 6 "Why" cell is left to planner — must convey "v1.22 shipped" without restating v1.22 facts already captured in PROJECT.md.

### Deferred Ideas (OUT OF SCOPE)

- Refine "sustained real-adopter signal" further at v1.24 charter time.
- Promote durable v1.23 non-goals to top-level `## Out of Scope` at v1.23 archive time.
- Add a "MILESTONE-ARC.md status-field freshness check" to the `/gsd-complete-milestone` checklist.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CHARTER-01 | PROJECT.md Key Decisions table gains a row for "v1.23 deliberately overrides v1.22's real-adopter-first closeout guidance" with rationale, override trigger, and re-engagement trigger | D-02 provides verbatim row text; line numbers verified (insert after line 350, which is the last table row before the blank line at 351) |
| CHARTER-02 | `MILESTONE-ARC.md` gains a v1.23 row in the arc-order table with theme, why-now framing, what-this-unlocks, and explicit non-goals; strategic thesis paragraph updated to note the override | D-04 items 4 and 7 cover this; line 9 paragraph and arc-order append point verified |
| CHARTER-03 | v1.23 non-goals locked in PROJECT.md: no new evidence subjects, no Threadline-owned RBAC/tenancy DSLs, no `lib/` auth code, no domain-model code in `lib/`, no rebrand to "demo product", no Sigra extension absent contract gap | D-03 provides verbatim bullet content; insertion point verified (between lines 29 and 31 in the Current Milestone block) |

</phase_requirements>

---

## Line-Number / Current-Text Verification

### D-02: PROJECT.md Key Decisions row insertion

**CONTEXT.md claim:** "Row sits immediately below the v1.22 closeout rows in `## Key Decisions`" and "below line 350."

**Verified state:**
- `## Key Decisions` header is at **line 322** — EXACT MATCH.
- The last row of the Key Decisions table is at **line 350** (the D-02 archive/closeout-gate separation row).
- Line 351 is a blank line.
- Line 352 begins `## Evolution`.
- The new v1.23 row must be **inserted between lines 350 and 351** (i.e., appended as the new last row of the table).

No drift. Line numbers in CONTEXT.md are correct.

### D-03: PROJECT.md `**v1.23 non-goals:**` insertion

**CONTEXT.md claim:** "Placed immediately after the `**Key context:**` block, before `**Current State:**`" and "around line 30 after `**Key context:**`."

**Verified state:**
- `**Key context:**` is at **line 24**.
- The Key context block spans lines 24–29 (4 bullet items ending at line 29, then a blank line at line 30).
- `**Current State:**` is at **line 31**.
- The new `**v1.23 non-goals:**` block must be **inserted between lines 30 and 31** (after the blank line that closes the Key context block, before the Current State line).

CONTEXT.md says "around line 30" — this is correct: the insertion goes at line 30/31 boundary. No drift.

### D-04: MILESTONE-ARC.md header lines 3–5

**CONTEXT.md claim:**
- Line 3: `**Updated:** 2026-05-25` → `**Updated:** 2026-05-27`
- Line 4: `**Active milestone:** v1.22 — Policy / Evidence Plane` → `**Active milestone:** v1.23 — Realistic-Demo Walkthrough`
- Line 5: `**Next ranked candidate:** TBD after v1.22 closeout` → `**Next ranked candidate:** TBD after v1.23 closeout`

**Verified current text (lines 1–5):**
```
# Milestone Arc: Threadline

**Updated:** 2026-05-25
**Active milestone:** v1.22 — Policy / Evidence Plane
**Next ranked candidate:** TBD after v1.22 closeout
```

All three lines match exactly. No drift.

### D-04: MILESTONE-ARC.md line 9 strategic thesis

**CONTEXT.md claim:** "Line 9 (Strategic thesis paragraph)" — append a sentence.

**Verified current text (line 9):**
```
With v1.21 shipped, the support-safe `/audit` lane is now a fixed baseline instead of an adoption question. The next high-leverage move is stronger policy/evidence truth for enterprise scrutiny without widening Threadline into a Threadline-owned auth, tenancy, or compliance platform.
```
(Lines 7–9 are: `## Strategic thesis`, blank line, then the paragraph on line 9.)

Line 9 is correct. No drift. The suggested append sentence from D-04 is:
> *"v1.23 deliberately overrides v1.22's 'real-adopter-first' closeout rule because no real adopter has surfaced yet and the alternative is shipping nothing; the override re-engages on the first sustained real-adopter signal (see PROJECT.md Key Decisions)."*

### D-04: MILESTONE-ARC.md option-record row 6 (Policy / compliance depth)

**CONTEXT.md claim:** Change `**Active (v1.22)**` → `**Shipped (v1.22)**`; tighten "Why" cell to past-tense framing.

**Verified current text (line 22):**
```
| 6 | Policy / compliance depth | **Active (v1.22)** | After the support-safe adopter lane is proven, strengthen durable evidence records and audit-of-audit posture without broadening into a Threadline-owned platform expansion. |
```

Actual line number: **22** (not cited as a specific line number in D-04, described positionally as "Option-record row 6"). This is confirmed correct.

The "Why" cell current text: *"After the support-safe adopter lane is proven, strengthen durable evidence records and audit-of-audit posture without broadening into a Threadline-owned platform expansion."* — this is present-tense framing that needs to flip to past-tense per D-04.

### D-04: MILESTONE-ARC.md arc-order v1.22 row status field

**CONTEXT.md claim:** `**active**` → `**shipped**`.

**Verified current text (line 34):**
```
| v1.22 | **active** | Policy / Evidence Plane | After the support-safe lane is proven, strengthen durable policy snapshots and audit-of-audit evidence so Threadline stands up better to enterprise scrutiny without broadening into a compliance platform. | More credible export/retention/policy proof, better procurement posture, cleaner later sink-hook work if needed. | Legal-hold platform work, immutable storage guarantees, generic compliance packs, vendor-specific reporting suites, or Threadline-owned RBAC/tenancy semantics. |
```

Actual line number: **34**. Status field `**active**` is confirmed. No drift.

### D-04: New v1.23 arc-order row placement

The arc-order v1.22 row is the **last data row** of the arc-order table (line 34). Line 35 is blank, line 36 is `## Activation rules`. The new v1.23 row must be **appended after line 34** (inserted between lines 34 and 35). The verbatim row text from D-04 item 7 is ready to use directly.

**MILESTONE-ARC.md total line count: 41 lines.**

---

## Precedent Quotes

### v1.17 / v1.18 / v1.19 / v1.21 / v1.22 Key Decisions rows (verbatim)

These are the rows the new D-02 row must match in density and voice.

**v1.17 row (line 339):**
```
| v1.17 operator surface ships in-tree with optional Phoenix/LiveView deps, not as a separate `threadline_web` package | Splitting at v0.3.0 with one maintainer is premature: doubles the release/version-matrix burden when the surface is still small. LiveDashboard / Oban Web / Ash Admin all split *after* the core had hundreds of adopters; Sentry-Elixir keeps Phoenix integrations optional in-tree without a companion. Keeps capture-only adopters Plug-only via `optional: true` deps gated by `Code.ensure_loaded?(Phoenix.LiveView)`. | ✓ Shipped (Phases 57–63, v1.17) |
```

**v1.18 row (line 342) — direct precedent for re-engagement clause inline in Rationale:**
```
| v1.18 ships exports UI as "download current view" only (sync `iodata` for small windows, chunked stream for large), not queued/Oban-backed | Adding Oban as a hard dep walks back the v1.17 optional-deps win, and storage adapters / file expiry / status pages are platform creep that contradicts "lib not platform." Sidekiq Pro hit memory pain on in-process CSV before adding streaming; Backpex / Linear / GitHub-style sync downloads are the right ceiling at our stage. Queued-with-link-when-ready is what large products (CloudTrail, Sentry, GitHub audit-log) ship after sync hits a wall — Threadline hasn't hit that wall, so the design would be speculative. Revisit in v1.20 once real adopters report row-cap pain on real incidents. | ✓ Shipped in v1.18 |
```

**v1.19 row (line 344) — `— Active (opened 2026-05-07)` status-cell shape:**
```
| v1.19 focuses on integration breadth and extraction readiness, not deeper operator product scope | The next leverage point is reducing host-specific glue and tightening proven compatibility claims. Saved views, retention admin capture machinery, queued exports, and mutable policy UI all add product surface or infrastructure without making adoption easier across hosts. `threadline_web` should remain a measured future decision unless real adopter pressure proves otherwise. | — Active (opened 2026-05-07) |
```

**v1.21 row (line 345):**
```
| v1.21 will productize the mount contract, not the auth model | The strongest remaining adoption gap was a truthful scoped support lane on `/audit`. The current tree now proves one host-owned path end to end, and Phase 94 closed the authority and audit surfaces around that proof without inventing RBAC or tenancy DSLs. | ✓ Ready for closeout (2026-05-25) |
```

**v1.22 row (line 346):**
```
| v1.22 will ship a narrow evidence plane, not a compliance platform | The next leverage point is durable proof for policy/governance posture. Append-only evidence records, API/CLI parity, and read-only `/audit` evidence views strengthen enterprise credibility without crossing the host-owned auth/tenancy boundary. | ✓ Shipped (Phases 95-103, v1.22, 2026-05-27) |
```

**Observation:** The v1.22 row is notably shorter (no inline re-engagement clause). The v1.18 row is the true structural template for the D-02 row: evidence-citing Rationale with a bolded re-engagement clause as the last sentence. The D-02 row's density is appropriate — it is longer than v1.22 and comparable to v1.18.

**Last two closeout rows (lines 349–350) — also below the insertion point:**
```
| Verification backfill phases (Phases 100/101/102) are the right pattern for closing audit gaps without widening milestone scope | When a milestone audit surfaces gaps in already-shipped phases, inserting narrow verification-only phases (`.planning/`-only, no doc/code/test edits, named rerun bundle as proof) closes the loop without re-litigating the underlying work. Phase 103 then reconciles the authority surfaces and reruns the audit on the reconciled tree. Reusable closeout play. | ✓ Validated (Phases 100-103, v1.22, 2026-05-27) |
| D-02 archive/closeout-gate separation and D-16 `.planning/`-only boundary held cleanly through Phase 103 | The archive step (`/gsd-complete-milestone`) owns MILESTONE-ARC, PROJECT "Last shipped", MILESTONES, RETROSPECTIVE, and `.planning/milestones/v*` archives. The closeout-gate phase is the proof step, not the archive step. Keeping these separated avoids the "audit closed itself" anti-pattern. | ✓ Validated (Phase 103, v1.22, 2026-05-27) |
```

The new v1.23 row appends after line 350 as the next (and last) row.

### v1.6–v1.10 Non-goals (unchanged) pattern (verbatim)

**v1.10 (line 172):**
```
**Non-goals (unchanged):** LiveView operator UI; published **`threadline_web`**; new capture / redaction / retention **semantics**; maintainer-attested third-party STG URLs; **Hex** semver bump unless a **separate** release milestone says so.
```

**v1.9 (line 186):**
```
**Non-goals (unchanged):** LiveView operator UI; `threadline_web`; new capture/redaction semantics; Hex semver bump unless a separate release decision is made.
```

**v1.8 (line 198, inline with Archives):**
```
**Archives:** `.planning/milestones/v1.8-REQUIREMENTS.md`, `.planning/milestones/v1.8-ROADMAP.md`. **Non-goals (unchanged):** LiveView operator UI; `threadline_web` / umbrella; new capture semantics; maintainer-attested third-party STG URLs.
```

**v1.7 (lines 212–212):**
```
**Non-goals (unchanged):** LiveView operator UI; new capture/redaction semantics; Hex semver bump unless a separate release decision is made; published `threadline_web` — example stays under **`examples/`**.
```

**v1.6 (line 224):**
```
**Non-goals (unchanged):** New capture semantics, exploration API expansion, LiveView UI, or claiming external pilot environments the library does not control — see **Out of Scope** below and **Future** in **`.planning/milestones/v1.6-REQUIREMENTS.md`** (archived v1.6 scope).
```

**House-style pattern:** `**Non-goals (unchanged):**` followed by a semicolon-separated inline list (single sentence, no line breaks). This is a prose-inline style, not a bullet list.

**Critical discrepancy — D-03 uses a bullet list, not inline prose.** The shipped-milestone non-goals precedent (v1.6–v1.10) all use a compact inline semicolon list on one line. D-03's verbatim content uses a bullet list format. The CONTEXT.md rationale acknowledges this: D-03 is a *new Current Milestone subsection* (not a "Last milestone shipped" block), and it specifically notes the bullet list "matches surrounding `**Target features:**` / `**Key context:**` bullet style." The `**Non-goals (unchanged):**` label from v1.6–v1.10 is not the correct precedent for the *current milestone block* — those appear only in the *shipped* milestone blocks. The new v1.23 non-goals are a live, in-scope declaration, not a retrospective "unchanged" note. This discrepancy is intentional; the planner should use D-03's verbatim bullet-list format as given.

---

## MILESTONE-ARC.md Current State (All 7 D-04 Edit Targets)

### Edit 1: Line 3
**Current:** `**Updated:** 2026-05-25`
**Target:** `**Updated:** 2026-05-27`

### Edit 2: Line 4
**Current:** `**Active milestone:** v1.22 — Policy / Evidence Plane`
**Target:** `**Active milestone:** v1.23 — Realistic-Demo Walkthrough`

### Edit 3: Line 5
**Current:** `**Next ranked candidate:** TBD after v1.22 closeout`
**Target:** `**Next ranked candidate:** TBD after v1.23 closeout`

### Edit 4: Line 9 (append sentence to strategic thesis paragraph)
**Current full paragraph (line 9):**
```
With v1.21 shipped, the support-safe `/audit` lane is now a fixed baseline instead of an adoption question. The next high-leverage move is stronger policy/evidence truth for enterprise scrutiny without widening Threadline into a Threadline-owned auth, tenancy, or compliance platform.
```
**Append sentence (from D-04):**
```
v1.23 deliberately overrides v1.22's 'real-adopter-first' closeout rule because no real adopter has surfaced yet and the alternative is shipping nothing; the override re-engages on the first sustained real-adopter signal (see PROJECT.md Key Decisions).
```
**Note:** The original sentence uses a trailing period; the append sentence should follow naturally (space + sentence, period at end). Result is a three-sentence paragraph.

### Edit 5: Option-record row 6, line 22 (status field + Why cell)
**Current:**
```
| 6 | Policy / compliance depth | **Active (v1.22)** | After the support-safe adopter lane is proven, strengthen durable evidence records and audit-of-audit posture without broadening into a Threadline-owned platform expansion. |
```
**Target status field:** `**Shipped (v1.22)**`
**Why cell (current, present-tense):** "After the support-safe adopter lane is proven, strengthen durable evidence records and audit-of-audit posture without broadening into a Threadline-owned platform expansion."
**Required transformation:** Flip to past tense. Planner's discretion per Claude's Discretion section. Example: "Shipped durable evidence records and audit-of-audit posture after the support-safe adopter lane proved out — without broadening into a Threadline-owned platform expansion."

### Edit 6: Arc-order v1.22 row, line 34 (status field only)
**Current:**
```
| v1.22 | **active** | Policy / Evidence Plane | ... |
```
**Target:** `**active**` → `**shipped**`
**All other cells unchanged.**

### Edit 7: New v1.23 arc-order row (append after line 34)
**Verbatim from D-04 item 7:**
```
| v1.23 | **active** | Realistic-Demo Walkthrough | Synthetic-first-adopter override of v1.22's real-adopter-first rule — no real adopter exists and the alternative is shipping nothing. | Walkthrough-surfaced design gaps as v1.24 seeds; first concrete fix-vs-defer rule in practice; durable boundary against scope creep tested under synthetic pressure. | No new Evidence subjects, no Threadline-owned RBAC/tenancy DSLs, no `lib/` auth or domain code, no "demo product" rebrand, no Sigra integration extension absent contract gap. Re-engages v1.22 rule on first sustained real-adopter signal. |
```

---

## Cross-Phase Scope-Guard Alignment

### Phase 105–109 `lib/` read-only guards

**ROADMAP.md Phase 105 scope guard (line 67):** "`lib/` is read-only." — EXACT language.
**ROADMAP.md Phase 106 scope guard (line 88):** "`lib/` is read-only." — EXACT language.
**ROADMAP.md Phase 107 scope guard (line 112):** "`lib/` is read-only." — EXACT language.
**ROADMAP.md Phase 108 scope guard (line 133):** "`lib/` is read-only." — EXACT language.
**ROADMAP.md Phase 109 scope guard (line 155):** "No code edits, no doc edits, no README edits, no example-app edits during the run." (Phase 109 is `.planning/v1.23/findings/` only — stronger than `lib/` read-only, equivalent in effect.) — CONSISTENT.
**ROADMAP.md Phase 110 scope guard (line 176):** "`lib/` is touchable only for (a) S-tier breakage findings citing concrete walkthrough evidence." — CONSISTENT with D-03's "no `lib/` auth or domain-model code" non-goal (Phase 110 carve-out is for any category-A breakage, which would need concrete walkthrough evidence; Phase 104's non-goal covers auth/domain-model specifically).

**No conflicts.** D-03's "no `lib/` auth or domain-model code" language is a narrower constraint within the same `lib/` read-only regime; Phase 110's carve-out for S-tier breakage is orthogonal (any breakage with walkthrough evidence, not new auth/domain code).

### Sub-phase 106b existence and carve-out alignment

**ROADMAP.md Phase 106 scope guard (line 88–89):**
> "Sub-phase **106b** is the documented escape valve if real signup/login surfaces a contract gap in `Threadline.Integrations.Sigra` — but is NOT added to the roadmap proactively; opened only if/when needed."

**ROADMAP.md Boundary contract summary (line 21–22):**
> "Sub-phase **106b** is the documented escape valve if real signup/login surfaces a contract gap in `Threadline.Integrations.Sigra` — but **not** added to the roadmap proactively; opened only if/when needed."

**D-03 non-goals bullet 3:** "Sigra integration is not extended unless real signup/login surfaces a contract gap (handled via sub-phase 106b escape valve)."

**Alignment: CONFIRMED.** Sub-phase 106b is defined identically in both ROADMAP.md locations and D-03. The escape valve language is consistent across all three sources. No drift.

### Terminology alignment with CLAUDE.md

D-03 references "`lib/` auth or domain-model code" — CLAUDE.md domain language maps this to the Capture layer (`lib/`) and Semantics layer (`lib/`), both in scope of the boundary. "Threadline-owned RBAC/tenancy DSLs" is consistent with CLAUDE.md's explicit prohibition on conflating host-owned auth with library-owned auth. Terminology is clean.

---

## Validation Architecture

`nyquist_validation` is not explicitly `false` in `.planning/config.json`. However, Phase 104 is a docs-only phase with no code, no tests, and no automated test suite that can validate prose accuracy. The validation dimensions are entirely read-based and grep-based.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None (docs-only phase) |
| Config file | N/A |
| Quick run command | `grep -c "v1.23 deliberately overrides" .planning/PROJECT.md` (expect: `1`) |
| Full suite command | See Phase Requirements → Test Map below |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| CHARTER-01 | New Key Decisions row present in PROJECT.md | grep-based | `grep -c "v1.23 deliberately overrides v1.22" .planning/PROJECT.md` → expect `1` | Human confirms density/voice match |
| CHARTER-01 | Re-engagement clause bolded in row | grep-based | `grep -c "\*\*Re-engages the v1.22 rule" .planning/PROJECT.md` → expect `1` | |
| CHARTER-01 | Status cell correct | grep-based | `grep -c "Active (recorded Phase 104, v1.23, 2026-05-27)" .planning/PROJECT.md` → expect `1` | |
| CHARTER-02 | MILESTONE-ARC.md header updated | grep-based | `grep "Active milestone:" .planning/MILESTONE-ARC.md` → expect `v1.23 — Realistic-Demo Walkthrough` | |
| CHARTER-02 | v1.23 arc-order row present | grep-based | `grep -c "Realistic-Demo Walkthrough" .planning/MILESTONE-ARC.md` → expect `1` | |
| CHARTER-02 | v1.22 status flipped in arc-order table | grep-based | `grep "v1.22" .planning/MILESTONE-ARC.md \| grep -c "shipped"` → expect `1` in arc-order row | |
| CHARTER-02 | Strategic thesis updated | grep-based | `grep -c "real-adopter has surfaced yet" .planning/MILESTONE-ARC.md` → expect `1` | |
| CHARTER-03 | v1.23 non-goals subsection present in Current Milestone block | grep-based | `grep -c "v1.23 non-goals:" .planning/PROJECT.md` → expect `1` | |
| CHARTER-03 | Non-goals appear before Current State line | manual read | Open PROJECT.md, confirm `**v1.23 non-goals:**` block sits between line ~29 and the `**Current State:**` line | Human cold-read check |

### Sampling Rate

- **Per task commit:** All grep commands above (< 30 seconds total)
- **Per wave merge:** Same grep suite + maintainer cold-read of both edited sections
- **Phase gate:** Human maintainer reads the two edited file sections and confirms the ROADMAP.md success criteria 1–4 are satisfied

### Wave 0 Gaps

None — no test files, config, or framework to create. This is a docs-only phase; validation is inspection-based.

### The <2-minute cold-read criterion

ROADMAP.md Success Criterion 4 states: "A maintainer reopening the planning surface can identify in <2 minutes that v1.23 is the synthetic-first-adopter milestone, why the v1.22 rule was set aside, and what would re-engage it."

This is **human-validated only** — no automated command can assert it. The planner should include a task that explicitly calls for a maintainer cold-read of the edited PROJECT.md Current Milestone block and Key Decisions row after the commit, with the 3-question test:
1. Can I identify v1.23 as the synthetic-first-adopter milestone? (answer in Current Milestone → Goal)
2. Can I identify why v1.22's rule was set aside? (answer in Key Decisions row Rationale cell)
3. Can I identify what would re-engage it? (answer in bolded `**Re-engages…**` clause in Key Decisions row)

---

## Landmines

### Landmine 1: Non-goals insertion point is BETWEEN the Key context block and Current State (not after Current State)

**Risk:** Inserting the `**v1.23 non-goals:**` block *after* `**Current State:**` instead of before it. The correct insertion is between the blank line at line 30 and the `**Current State:**` at line 31. CONTEXT.md says "before `**Current State:**`" — this is unambiguous, but a mechanical edit could get it wrong.

**Guard:** After edit, confirm `**v1.23 non-goals:**` precedes `**Current State:**` in PROJECT.md.

### Landmine 2: Key Decisions row ends the table — no pipe after the last cell

**Risk:** The new row must close with ` |` and be followed by a blank line (not another `|` header or a `---` separator). The table has no footer row. Verify the new row inserts cleanly between line 350 (last data row) and line 351 (blank line before `## Evolution`).

### Landmine 3: Option-record row 6 "Why" cell past-tense rewording

**Risk:** The "Why" cell contains a forward-looking rationale ("After the support-safe adopter lane is proven, strengthen…"). A naive past-tense flip could produce awkward phrasing. The planner must rewrite this cell substantively, not just change verb tense. The suggested approach: replace "After the support-safe adopter lane is proven" with "After the support-safe adopter lane proved out" or equivalent; replace "strengthen" with "strengthened."

**Guard:** Read the rewritten cell aloud — it should read as a done-thing, not a goal.

### Landmine 4: MILESTONE-ARC.md strategic thesis sentence uses smart quotes in D-04

**D-04 item 4 uses a straight apostrophe in** `v1.22's 'real-adopter-first' closeout rule`. The file currently uses standard Markdown (plain text). Ensure no Unicode curly quotes sneak in if copy-pasting. The file uses plain ASCII throughout.

### Landmine 5: v1.23 arc-order row backtick usage

**D-04 item 7 row contains backtick-wrapped code spans:** `` `lib/` ``. Markdown tables allow inline code spans; this is valid. The planner should confirm the row renders correctly in a Markdown preview (the backticks will display as inline code). No action needed, just awareness.

### Landmine 6: MILESTONE-ARC.md option-record table has no "Non-goals" column

The arc-order table has 6 columns (Version, Status, Theme, Why now, Unlocks, Non-goals). The option-record table (rows ranked 1–6) has only 4 columns (Rank, Option, Recommendation, Why). The new v1.23 row goes in the **arc-order table**, not the option-record table. These are two separate tables in MILESTONE-ARC.md. D-04 is clear about this, but a confused edit to the wrong table would be disruptive.

**Guard:** Verify the edit targets the table under `## Arc order` (starting at line 26), not the table under `## Option record` (starting at line 15).

### Landmine 7: Stale date on PROJECT.md footnote

**Current PROJECT.md last line (line 372–373):**
```
*Last updated: 2026-05-27 — v1.23 Realistic-Demo Walkthrough opened. Current Milestone section added, Active requirements seeded with Phase 104–110 placeholders; Phase 104 will record the v1.22-override Key Decision and update MILESTONE-ARC.md.*
```

The footnote currently says "Phase 104 **will** record..." — after Phase 104 executes, this should read "Phase 104 **recorded**..." However, D-04 does NOT include a footnote update as one of the 7 edits. The CONTEXT.md scope does not mention updating this footnote. The planner should decide whether to include a minor footnote update ("Phase 104 will record" → "Phase 104 recorded") as part of the PROJECT.md edit. This is not required by any decision but would keep the footnote accurate.

**Recommendation:** Include the footnote date/tense update as a minor addition to the PROJECT.md edit task. It adds <5 seconds and prevents the footnote from being actively inaccurate post-commit. Flag this as planner discretion if scope discipline requires strict D-02/D-03-only edits.

---

## No Code or Test Concern Confirmation

This phase is `.planning/`-only. Confirmed:
- No `lib/` files touched
- No `test/` files touched
- No `guides/` files touched
- No `examples/` files touched
- No `mix.exs` changes
- No `config/` changes
- The scope guard is: **`.planning/PROJECT.md` and `.planning/MILESTONE-ARC.md` only**

The planner should produce ZERO code tasks and ZERO test tasks. The `104-SUMMARY.md` written during execution (D-05) is the only additional artifact — it is a phase-artifact file in `.planning/phases/104-*/`, not a planning-surface file.

---

## Assumptions Log

No claims in this research required assumption — all findings are from direct file reads of the target files in the working directory.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

All claims in this research were verified by direct file read. No user confirmation needed.

---

## Open Questions (RESOLVED)

1. **PROJECT.md footnote update (Landmine 7)**
   - What we know: The footnote on line 372–373 says "Phase 104 will record…" which will be stale after the commit.
   - What's unclear: Whether D-04's strict 7-edit scope means this should be left alone, or whether it's obviously in-scope doc hygiene.
   - RESOLVED: Resolved by `104-01-PLAN.md` Edit 1C in Task 1 (flips "Phase 104 will record…" → past tense). Recommendation: Include it in the PROJECT.md edit task as a minor addition; note it as planner discretion if strict D-03-only scope is preferred.

2. **`104-SUMMARY.md` template**
   - What we know: D-05 requires one line recorded in `104-SUMMARY.md` during execution.
   - What's unclear: Whether `104-SUMMARY.md` follows the same SUMMARY.md template as prior phases (with header + body sections) or is minimal.
   - RESOLVED: Resolved by `104-01-PLAN.md` `<output>` block — standard GSD SUMMARY.md template with D-05 precedent rule as the key content item. Recommendation: Follow the standard GSD SUMMARY.md structure; the D-05 rule is the key content item but the file should have the standard format.

---

## Environment Availability

Step 2.6: SKIPPED (no external dependencies — docs-only phase, no tools, services, runtimes, or databases required).

---

## Sources

### Primary (HIGH confidence)

All findings sourced from direct file reads:

- `/Users/jon/projects/threadline/.planning/PROJECT.md` — Key Decisions table (lines 322–350), Current Milestone block (lines 11–46), v1.6–v1.10 shipped blocks (lines 162–224)
- `/Users/jon/projects/threadline/.planning/MILESTONE-ARC.md` — header (lines 1–5), strategic thesis (line 9), option-record table (lines 15–22), arc-order table (lines 26–34)
- `/Users/jon/projects/threadline/.planning/REQUIREMENTS.md` — CHARTER-01/02/03 wording (lines 16–18)
- `/Users/jon/projects/threadline/.planning/ROADMAP.md` — Phase 104–110 scope guards (lines 18–25, 67, 88–89, 112, 133, 155, 176)
- `/Users/jon/projects/threadline/.planning/phases/104-reference-walkthrough-charter-override-decision/104-CONTEXT.md` — All five decisions (D-01 through D-05) and verbatim text

---

## RESEARCH COMPLETE
