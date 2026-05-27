# v1.23 Walkthrough Findings

**Purpose:** Capture gaps observed during the Phase 109 maintainer dry-run. Phase 109 is **observe-only** — classify at capture time, file a numbered finding, continue the walk. Phase 110 triages findings into fixes or deferrals using the routing table below.

---

## classify in <30 seconds

Answer these four questions **in order**. Stop at the first match.

1. **Blocked or wrong answer?** → **(a) breakage**
2. **Prose missing/wrong/contradicts shipped behavior?** → **(c) doc gap**
3. **Needs new capability** (Evidence subject, RBAC DSL, multi-phase redesign)? → **(d) design gap**
4. **Else works but annoys** → **(b) DX papercut** (fix if ≤1 narrow plan; else defer like d)

Copy `.planning/v1.23/findings/TEMPLATE.md` to a new file, fill frontmatter + body sections, and keep walking.

---

## Routing table

| Class | Label | Phase 110 action |
|-------|-------|------------------|
| **(a)** | Breakage | **Always fix** in Phase 110 — wrong answer, crash, security regression, hard blocker |
| **(b)** | DX papercut | **Fix if ≤1 narrow plan**; otherwise defer to `.planning/v1.24-seeds/` with rationale |
| **(c)** | Doc gap | **Always fix** in `guides/` or example-app README |
| **(d)** | Design gap | **Defer** to `.planning/v1.24-seeds/SEED-NNN.md`; mark finding `deferred_to:` |

Update `status`, `fixed_in`, or `deferred_to` in the finding frontmatter during Phase 110 triage — not during Phase 109 capture.

---

## Boundary examples

Paste-ready classification anchors (from D-108-05e):

| Observation | Class |
|-------------|-------|
| Missing manifest footnote for `demo_last_tuesday` in WALKTHROUGH appendix | **(c) doc gap** |
| Filter label on `/audit` timeline is confusing but filters work | **(b) DX papercut** |
| Wrong closer shown for ticket #4521 — answer does not match manifest hero | **(a) breakage** |
| Request for legal-hold Evidence subject not shipped in v1.22 | **(d) design gap** |
| Audit surface returns 403 immediately after successful signup | **(a) breakage** |
| Impersonation / delegate actor not represented in ActorRef model | **(d) design gap** |

---

## File naming

- **Finding files:** `.planning/v1.23/findings/NNNN-slug.md` — zero-padded sequential ID starting at **`0001`** during Phase 109
- **Template:** `.planning/v1.23/findings/TEMPLATE.md` — copy, do not edit in place
- **Optional assets:** `.planning/v1.23/findings/assets/` for screenshots — never required for classification
- **Frontmatter + sections:** see `TEMPLATE.md` for required keys (`id`, `slug`, `classification`, `walkthrough_step`, `captured`, `status`, `fixed_in`, `deferred_to`) and body headings (**Expected**, **Actual**, **Evidence**)

---

## No in-flight fixes (Phase 109 discipline)

During the Phase 109 walkthrough run, **do not fix anything in-flight** — even obvious typos, broken links, or one-line code fixes. Observed gaps become numbered finding files with classification assigned at capture time. In-flight fixes corrupt the findings set and blur observe-vs-triage separation; Phase 110 applies the routing table above with concrete commits or v1.24 seed deferrals.

This discipline is echoed in `WALKTHROUGH.md` front matter. If you are tempted to "just fix it now," file the finding and keep walking.
