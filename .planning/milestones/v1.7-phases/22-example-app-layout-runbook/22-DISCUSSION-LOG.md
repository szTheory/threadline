# Phase 22: Example app layout & runbook - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`22-CONTEXT.md`**.

**Date:** 2026-04-23  
**Phase:** 22 — Example app layout & runbook  
**Areas discussed:** All six gray areas (user selected `all`), with parallel subagent research + principal synthesis.

---

## 1. Example path & app name

| Option | Description | Selected |
|--------|-------------|----------|
| `examples/threadline_phoenix/` | Matches REF-01, Phoenix signal, distinct `:threadline` OTP | ✓ |
| `examples/threadline_host/` | Aligns with internal “host” vocabulary | |
| `examples/threadline_example/` | Neutral; weak Phoenix signal | |
| `examples/threadline_demo/` | “Demo” undercuts reference tone | |
| `examples/audit_demo/` | Detaches from Hex name `threadline` | |

**User's choice:** Delegated to research + maintainer synthesis — **locked: `threadline_phoenix`**.  
**Notes:** Subagent compared Hex idioms (path deps, distinct `app:`), Rails dummy/npm examples footguns (rename cost, drift). **D-01–D-03** in CONTEXT.

---

## 2. Phoenix baseline (full vs minimal)

| Option | Description | Selected |
|--------|-------------|----------|
| Default full `phx.new` (browser, LiveView, assets) | Maximum familiarity | |
| Lean `phx.new` (API-oriented flags, Ecto retained) | Standard layout, low noise, fast CI | ✓ |
| Hand-rolled minimal Mix app | Smallest tree, worst copy-paste | |

**User's choice:** Research + synthesis — **locked: documented lean `phx.new`**.  
**Notes:** Compared Oban/Ash/Req patterns; Phoenix upstream precedent for testing `installer/` as second tree. **D-04–D-06** in CONTEXT.

---

## 3. First audited domain table

| Option | Description | Selected |
|--------|-------------|----------|
| `posts` | Familiar CRUD, low PII, README-aligned | ✓ |
| `users` | High PII / secrets footgun for phase 22 | |
| `widgets` / generic | Abstract unless copy is excellent | |
| Settings / JSON-heavy | Harder first lesson for diffs | |

**User's choice:** Research + synthesis — **locked: `posts`**.  
**Notes:** Emphasize neutral seeds; defer `users` until HTTP path needs auth. **D-07–D-09** in CONTEXT.

---

## 4. Contributor bootstrap & Postgres

| Option | Description | Selected |
|--------|-------------|----------|
| `mix setup` + documented `DB_*` + optional Compose appendix | Cross-platform, Elixir-native | ✓ |
| Makefile as primary | Windows tax | |
| `bin/setup` as primary | Shell portability unless maintained dual | |

**User's choice:** Research + synthesis — **Mix setup + CONTRIBUTING/docker appendix**.  
**Notes:** Rails/Django pattern = framework commands + explicit DB location; footgun list included port mismatch. **D-10–D-13** in CONTEXT.

---

## 5. CI / verification

| Option | Description | Selected |
|--------|-------------|----------|
| Umbrella at root | Rejected — non-goal | |
| Path-dep `examples/` + root `mix verify.example` | Matches integrator reality | ✓ |
| Docs-only / no CI | Example rots — rejected | |

**User's choice:** Research + synthesis — **`verify.example`**, **`ci.all` inclusion**, second DB name, contract tests, main never skips. **D-14–D-17** in CONTEXT.

---

## 6. `config :threadline, :trigger_capture`

| Option | Description | Selected |
|--------|-------------|----------|
| Default-only (omit or empty tables) | Single learning path, no config drift | ✓ |
| Live exclude/mask in example | Splits attention; MIX_ENV footgun | |

**User's choice:** Research + synthesis — **default-only for Phase 22**.  
**Notes:** Link to root README + guides for redaction. **D-18–D-19** in CONTEXT.

---

## Claude's Discretion

- Phoenix flag exact spelling per installed version.  
- Micro-optimizations to CI placement after first green timing.  
- Optional future “Advanced” README subsection for redaction (link-only).

## Deferred Ideas

See **`<deferred>`** in **`22-CONTEXT.md`** (in-example redaction demo, umbrella, full LiveView stack, optional rename to `threadline_host`).
