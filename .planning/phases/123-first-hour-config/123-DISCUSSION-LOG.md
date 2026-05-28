# Phase 123: First-Hour Config - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 123-First-Hour Config
**Areas discussed:** All five (user requested full research + one-shot recommendations)

---

## Getting-started placement

| Option | Description | Selected |
|--------|-------------|----------|
| End of §2 (after deps.get) | Day-one wiring without new heading | |
| **§2.5 subsection before §3** | Dedicated “Configure Threadline” beat; explains dual-key split | ✓ |
| Just before §7 | Just-in-time at first resolve_repo! task | |

**User's choice:** Auto-selected after subagent research — **§2.5 subsection (Option B)**
**Notes:** Oban/ExAudit/Sentry pattern: configure after deps, before operational commands. Option C fails ROADMAP “discover on day one” because §8 fallbacks and checklist §1 mix tasks run before §7.

---

## Rationale depth

| Option | Description | Selected |
|--------|-------------|----------|
| One line only | “Mix tasks and fallbacks need your Repo” | |
| Full §7–§9 task list in getting-started | Enumerates every resolve_repo! task | |
| **Brief getting-started + checklist depth** | 2 sentences + cross-link; checklist owns inventory | ✓ |

**User's choice:** Auto-selected — **Option C**
**Notes:** Matches Threadline doc layering (getting-started walkthrough vs production-checklist ops). Rejects triple duplication with §8 fallback bullets.

---

## Config literal & multi-repo

| Option | Description | Selected |
|--------|-------------|----------|
| `[MyApp.Repo]` only | Strict placeholder | |
| **Placeholder + first-wins footnote** | One sentence on ordering vs Ecto semantics | ✓ |
| Multi-repo example in getting-started | Advanced block in first-hour doc | |

**User's choice:** Auto-selected — **Option B**
**Notes:** Threadline uses first element only; Ecto mix iterates all repos — footnote prevents silent wrong-repo selection. Multi-repo belongs in checklist advanced note, not getting-started.

---

## Production checklist placement

| Option | Description | Selected |
|--------|-------------|----------|
| §1 Capture and triggers | Near verify_coverage | |
| §5 Export and investigation | Near mix fallbacks | |
| **Standalone prerequisite section** | Before §1; cross-link only | ✓ |

**User's choice:** Auto-selected — **Option C**
**Notes:** Oban pattern: install docs own repo wiring; production guide verifies. Cross-cutting config should not live inside capture-only or export-only taxonomy. Optional §5 backlink, no second checkbox.

---

## Doc-contract strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Literal only | `config :threadline, ecto_repos: [MyApp.Repo]` | |
| Literal + before §7 | Ordering gate | |
| Literal + placement + checklist in same test | Cross-doc coupling | |
| **B+ split** | Literal + before §7 + before sigra fence (+ prefer before §3); CFG-03 separate test | ✓ |

**User's choice:** Auto-selected — **Option B+ with CFG-03 split**
**Notes:** Mirrors existing sigra fence ordering test. Footer checklist link already exists but does not prevent install-path gap. One verify artifact per REQ per OSS DNA.

---

## Claude's Discretion

- Subsection title polish, anchor slug, CFG-03 test file choice (extend stg vs new)

## Deferred Ideas

- Auto-infer ecto_repos from host config
- CLI `-r` flag pattern (Carbonite-style)
- Full multi-repo advanced guide
- Phase 124 doc finish items
