# Phase 238: Current-main preview and acceptance baseline — Research

**Researched:** 2026-10-08  
**Domain:** Phoenix operator UI preview, deterministic browser evidence, and acceptance coverage  
**Confidence:** HIGH for existing tooling and isolation diagnosis; MEDIUM for the new evidence contract

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Preserve the dirty planning checkout and all unrelated edits. Later execution must establish an isolated current-main context using the supported workflow, carrying the approved planning, PRODUCT.md and Impeccable context. Do not run source implementation from the stale milestone/v1.44 branch, switch/reset this checkout, or silently treat a missing isolation adapter as permission to do so.
- **D-02:** Record the actual source SHA, relevant diff, served-asset identity, safe fixture identity and capture conditions for the baseline. Historical screenshots and source candidates are leads, not reproduced visual defects. Refresh main at execution; the preflight SHA is historical evidence, not a permanent pin.
- **D-03:** Inventory all eleven existing routes, shared primitives, unique controls and material states. Every item needs a ranked rendered finding or explicit evidence-linked coverage disposition; do not silently drop inaccessible states or claim a source-only check proves rendered behavior.
- **D-04:** Include full-shell captures and representative desktop, intermediate and narrow/mobile widths; Light, Dark and System; actual 200% browser zoom; keyboard/touch focus; pending/empty/failed/denied/completed and offline/reconnect conditions where applicable. Use a bounded, risk-based matrix and explicit limitations rather than an unbounded Cartesian product.
- **D-05:** Review with agent judgment plus repeatable checks. Normal verification must not overwrite reference baselines. No paid critic revival, new paid API loop, or routine maintainer UAT; a source/asset mismatch blocks visual classification. Keep proof honest about browser and capability limits.
- **D-06:** Engineers and support/on-call operators have equal UI priority. Use familiar investigation/operations flows, canonical domain nouns, readable hierarchy, exact evidence access and the existing Threadline identity and private Phoenix/HEEx primitives. Impeccable is code-first; purposeful Kowalski motion guidance informs later refinements. Do not rerun initialization or prescribe an unseen redesign during this baseline phase.
- **D-07:** Preserve public 1.x APIs, routes, host authentication/authorization, tenant scope, redaction and Phoenix optionality. Do not expand backend capabilities, create a public component package or migrate frameworks. Preview fixtures must be synthetic/local and must not touch user or production data.
- **D-08:** Link findings to the owning approved phases and preserve existing acceptance conditions across journeys. Source candidates from preflight must be confirmed or explicitly dispositioned. No push, publication, new spend or release grant is implied by this planning request.

### the agent's Discretion

- Select the smallest reusable existing preview/capture tooling and fixture strategy after inspecting current main.
- Choose evidence formats, bounded capture ordering, risk rankings and local verification commands, provided completeness and provenance remain checkable.
- Use existing project checks and regression infrastructure; add only baseline tooling/contracts needed to prevent stale evidence or silent omissions.

### Deferred Ideas (OUT OF SCOPE)

- Visual fixes and token/component/copy refinements before baseline capture and classification.
- New backend capabilities, rebranding, framework changes, paid judging and a new release.
- Unsupported browser/device claims without evidence; composite-key row exploration and unbounded-history backend changes.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UIB-01 | Maintainers can open a reproducible, safely seeded preview of the current-main UI, with source and served-asset identity recorded for captures of all eleven operator routes. | Existing Phoenix example, synthetic `mix demo.seed`, authenticated Playwright route capture, local asset responses, and GSD/Codex worktree handoff support the preview; the current route-capture list and artifact metadata need completion for all eleven routes and source/asset provenance. |
| UIB-02 | Maintainers can trace every route, shared primitive, unique control and material state to a ranked finding or explicit coverage disposition before implementation starts. | Reuse the preflight route and interaction inventory, current private Phoenix/HEEx primitives, Storybook/Playwright browser lane, and a finite evidence-linked inventory with per-item rank or coverage disposition. |
</phase_requirements>

## Summary

Keep Phase 238 as an evidence and preview phase. Start a synthetic, local preview from the freshly resolved `origin/main` commit in an isolated workspace; capture the assembled operator shell and every route; then publish a route/control/state inventory whose entries resolve to ranked rendered findings or explicit evidence-backed dispositions. Do not make visual fixes in this phase. The approved route set is home, timeline, transaction, direct row history, transaction row-history drawer, actor, coverage, evidence, exports, redaction policy, and retention policy.[VERIFIED: 238-CONTEXT.md, Specific Inputs]

The repository already has Phoenix LiveView, seeded help-desk data, a Playwright browser runner, story and route capture specs, and project checks. Current `origin/main` was refreshed read-only at `9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2` on 2026-10-08. The existing route capture file has only five distinct route paths plus a duplicate degraded Timeline entry, so it does not satisfy UIB-01 as written.[VERIFIED: git ls-remote origin refs/heads/main; examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts:82-99]

The existing capture also hard-codes Playwright `1.61.1`, while the refreshed `origin/main` lockfile pins `@playwright/test` and `playwright` to `1.60.0`. Treat current scorecard version metadata as untrustworthy until corrected to report the actual runner/browser version; this is a source/provenance defect, not evidence of a rendered UI defect.[VERIFIED: origin/main:examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts:32-37; origin/main:examples/threadline_phoenix/e2e/package-lock.json:491-499]

**Primary recommendation:** Use the GSD `worktree create` command with the refreshed main SHA as its explicit `--base`, then verify the Codex `orchestrator-worktree` exec descriptor and launch the isolated preview with `codex exec --cd <worktree>`. Copy only the approved planning/product/design context needed by the run into that workspace; keep source edits and captures there, and never stage the dirty checkout's `.planning/config.json`. Use a unique `MIX_TEST_PARTITION` for the demo database, extend the existing capture suite and add a small contract test for inventory/provenance completeness. This path is concrete and supported by the installed GSD CLI; it does not require changing this checkout's branch or relying on Codex `spawn_agent` to bind a worktree.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Operator pages and auth-protected rendering | Frontend Server (Phoenix LiveView) | Database / Storage | The demo host mounts the existing operator UI and serves it behind its host auth pipeline. |
| Synthetic operator data | Database / Storage | API / Backend | Existing demo seed writes fictional records to the example app's Ecto/PostgreSQL database. |
| Route, state, viewport and interaction capture | Browser / Client | Frontend Server (Phoenix LiveView) | Playwright drives actual HTTP/LiveView routes and records DOM/screenshots; source inspection alone cannot prove rendered behavior. |
| Source/asset/fixture provenance and inventory | Test / evidence artifacts | Browser / Client | A small manifest links browser outputs and inventory dispositions to the exact source, assets, fixture scenario and capture conditions. |
| Isolation handoff | GSD/Codex orchestration | Git worktree | GSD creates a worktree at a supplied base SHA; its Codex descriptor binds `codex exec` to that directory. |

## Standard Stack

### Core

| Library/tool | Version | Purpose | Why standard |
|---------|---------|---------|--------------|
| Phoenix + LiveView | 1.8.13 / 1.2.11 | Existing example host and operator routes | Already runs the actual UI under test; no new UI framework is in scope. `[VERIFIED: origin/main:mix.lock:32-34]` |
| Playwright Test (`@playwright/test`) | 1.60.0 in `origin/main` lockfile | Browser interaction, responsive capture and route evidence | The repository already provides its tests, Chromium projects and local capture commands. `[VERIFIED: origin/main:examples/threadline_phoenix/e2e/package-lock.json:491-493]` |
| ExUnit / Mix | project-pinned Elixir 1.17.3, OTP 27 | Fast inventory and evidence-contract checks | Repository verification uses Mix aliases and existing test modules. `[VERIFIED: .tool-versions:1-2; mix.exs:163-184]` |
| PostgreSQL | local service or project Docker service | Synthetic demo fixture database | Required by the existing Phoenix example; isolate the E2E database with `MIX_TEST_PARTITION`. |
| GSD Core + Codex CLI | GSD Core 1.16.0; Codex CLI 0.161.0 observed locally | Isolated current-main execution | Local inspection resolved the actual Codex exec descriptor and worktree CLI. `[VERIFIED: runtime-identity; codex --version; inspect-dispatch-isolation --json --cwd-target /tmp/threadline-238-probe --prompt probe]` |

Verbatim version evidence read in this session: `"phoenix": {:hex, :phoenix, "1.8.13"` and `"phoenix_live_view": {:hex, :phoenix_live_view, "1.2.11"` from `origin/main:mix.lock`; `"node_modules/@playwright/test": {` / `"version": "1.60.0"` from `origin/main:examples/threadline_phoenix/e2e/package-lock.json`; `.tool-versions` contains `erlang 27.3.4.15` and `elixir 1.17.3-otp-27`. Local runtime probes returned `{"packageName":"@opengsd/gsd-core","version":"1.16.0"}` and `codex-cli 0.161.0`.

The existing route spec separately says `const PLAYWRIGHT_VERSION = "1.61.1";` while the lockfile says `"version": "1.60.0"` for `@playwright/test` and its `playwright` dependency. Fix this metadata at the same time as the new source/asset manifest; pinning a string for byte stability currently makes it stale rather than accurate.[VERIFIED: origin/main:examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts:32-37; origin/main:examples/threadline_phoenix/e2e/package-lock.json:491-499]

### Supporting

| Tool | Purpose | When to use |
|------|---------|-------------|
| `mix verify.example_browser` | Boot seeded example and run Playwright through the project's wrapper | Real route/state/focus proof; use targeted projects/specs during baseline work. |
| `mix verify.capture` | Explicit deterministic Tier-A capture regeneration | Only if the approved review needs the existing shared primitive evidence; it regenerates Tier-A data and is not a route-completeness substitute. |
| `mix verify.mechanical` | Existing mechanical scorecard checks | Fast artifact-quality companion, not a rendered visual verdict. |
| `.planning/UI-MILESTONE-PREFLIGHT.md` | Completed milestone scope, source candidates, route/state checklist and sibling lessons | Reuse it as the baseline checklist; confirm each candidate in fresh current-main renders. |

No new external package is needed. Therefore no Package Legitimacy Audit is required for this phase. Do not add image-critic packages or hosted review services.

### Alternatives Considered

| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| Current-main worktree created through GSD's supported CLI and Codex descriptor | Run implementation in the existing checkout | That checkout is dirty and on `milestone/v1.44`; it cannot represent current main and must remain intact. |
| Actual browser zoom through the interactive Chromium UI | `page.setViewportSize` or `deviceScaleFactor: 2` | Those emulate viewport/device properties, not browser zoom; they do not establish the D-04 zoom condition. |
| Local synthetic demo fixture | User or production data | The latter violates D-07 and is unnecessary because the example seed already supplies fictional records. |

## Project Constraints (from AGENTS.md)

- Keep capture, semantics and exploration responsibilities separate. Use canonical terms such as `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef` and `Correlation` in inventory labels and findings.
- Preserve the trigger-backed capture boundary, public 1.x contracts, host auth/authorization, tenant scope, redaction and Phoenix optionality; do not add backend capabilities or a public component package.
- Use named `mix verify.*` / `mix ci.*` commands when a project entrypoint exists. Keep default tests honest, preserve GitHub Actions job IDs, run expensive path-filtered jobs on `main`, and keep docs aligned with their contract tests.
- GSD policy is zero human verification by default; automated rendered proof plus agent review is the intended route. Do not hand maintainers routine UAT.
- Do not change scope or dependencies without the existing approved context. Preserve every unrelated dirty file and do not silently edit/stage the dirty planning configuration.

## Architecture Patterns

### Preview handoff: current main, explicit adapter

The installed CLI reports the supported invocation when given a target directory. Exact observed result:

```json
{"runtime":"codex","isolation":"orchestrator-worktree","exec":{"command":"codex","args":["exec","--cd","/tmp/threadline-238-probe","probe"],"cwd":"/tmp/threadline-238-probe"},"harnessFlag":null}
```

`inspect-dispatch-isolation` without `--cwd-target` returns `exec: null` by design. Check with a real intended worktree path. The current project setting has `"use_worktrees": false`, which opts GSD phase execution out of automatic worktree isolation; it does not invalidate the explicit `worktree create` CLI. Do not flip the dirty shared config in place. Use the supported create command with the fresh source SHA as `--base`, preserve the manifest so GSD owns cleanup, and launch via the resolved `codex exec --cd` adapter. If the descriptor does not resolve or the process cannot bind to the path, fail closed and report a prerequisite—not a prose-only promise of isolation. `[VERIFIED: .planning/config.json:54; node <gsd-install>/gsd-core/bin/gsd-tools.cjs query inspect-dispatch-isolation --json --cwd-target /tmp/threadline-238-probe --prompt probe; node <gsd-install>/gsd-core/bin/gsd-tools.cjs worktree create]`

Concrete supported CLI syntax observed from the installed tool is `worktree create --manifest <path> --agent-id <id> --path <worktree> --branch <branch> --base <sha> --root <dir> [--files "<space-separated paths>"] [--deletions "<space-separated paths>"]`. At execution, resolve main and retain its SHA, then use that verb with unique manifest/agent/path/branch values and the refreshed SHA; inspect the resulting HEAD and status before launching Codex. Do not use `gsd-workspace --new --strategy worktree` for this handoff: that helper starts from current HEAD, which is the stale milestone branch here. `[VERIFIED: local gsd-tools.cjs worktree create usage; local gsd-workspace/SKILL.md]`

Carry only the run's approved context into the isolated preview: `.planning/PROJECT.md`, current `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `.planning/config.json`, Phase 238 context/research/plan, `PRODUCT.md`, and the applicable `.impeccable` configs. Preserve their exact bytes and record which were copied. Keep the worktree source at the refreshed main SHA; do not copy the source edits from the stale checkout or stage local planning/config artifacts. Inspect the resulting `git status` before capture and record source diff state. The future execution plan must name this context-transfer step and its verification.

### Safe fixture and startup sequence

The E2E runner already uses `MIX_ENV=test`, marks its server as E2E, waits for the app and `/audit` mount, and runs `mix demo.reset` plus `mix demo.seed`. The reset truncates demo tables; the test repository derives its database name from `MIX_TEST_PARTITION`. Assign a phase-specific unique partition before boot so the reset is scoped to the isolated database. Never run the seeded reset against the default shared or production database. `[VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh:14-17,234-256,292-306; examples/threadline_phoenix/config/test.exs:10-18; examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex:130-158]`

Capture the fixture identity using a stable seed scenario/version and a digest of the fixture manifest or seeded scenario record. Do not put the demo password, session cookie, or sensitive response data in the evidence manifest. Capture only after the mount readiness guard passes and the authenticated seeded user reaches each expected route.

### Source-bound artifact manifest

Existing route scorecards record Playwright version, device scale, viewport, color scheme, route and artifact paths. They do not record the git source SHA, source diff or served asset bytes. Add a small top-level run manifest beside the baseline evidence, then link each route/control/state inventory row to one or more manifest capture IDs. For each run record: refreshed source SHA, relevant source diff/status digest, fixture scenario ID/digest, exact route/state, account role and scope, theme preference and effective theme, browser/version, viewport, actual zoom condition, input method, motion setting, deterministic clock where relevant, and output hashes.

Record actual browser-served CSS/JS URLs and response-body SHA-256 values from the browser network events, along with status/content-type. Compare the captured asset identity to the exact source/worktree before classifying appearance. If source and served-asset identities disagree, mark the capture invalid and stop visual classification. Keep the ordinary verification path read-only over reference baselines; write new run output to a fresh evidence directory, not committed reference PNG paths.

### Bounded inventory and capture matrix

Inventory scope: the eleven routes; full application shell/navigation/theme control; each shared primitive used by them; route-specific filters/forms/actions; tables, disclosures, menus, dialogs and drawer; and material pending, empty, failed, denied, completed, offline/reconnect, focus, long-value and permission states wherever the route supports them. A control/state can be marked not applicable only with a reason and source/test reference. Every in-scope row gets a risk rank, rendered capture/test link, owner phase (239–243), and disposition such as fix in owning phase, accepted baseline, or capability limitation.

Use the preflight's exact host-relative route inventory (prepend `/audit` for the example mount) as the route-set contract: `/`, `/timeline`, `/transactions/:id`, `/rows/:table/:record_id`, `/transactions/:id/history/:table/:record_id`, `/actors/:kind/:id`, `/coverage`, `/evidence`, `/exports`, `/policy/redaction`, `/policy/retention`. These eleven paths cover home, timeline, transaction detail, direct row history, transaction row-history drawer, actor, coverage, evidence, exports, redaction, and retention.[VERIFIED: .planning/UI-MILESTONE-PREFLIGHT.md:58-75]

Reuse the preflight's already-enumerated building blocks: shared headers/navigation, forms, tables, empty/error states, overlays, references, semantic tokens, dark/light/System themes, reduced motion, and reconnect banner. Preserve its source candidates as *unconfirmed*: clipboard Copy on direct entry to Evidence/Exports/Retention; queue-export behavior during socket loss; label drift; and latent paper/ink token aliases. The first browser probes should exercise fresh direct-entry clipboard success/failure, disconnected pointer and keyboard activation through pending/reconnect without duplicate mutation, and navigation/heading/control/feedback label consistency. Source candidates and historic screenshots are not rendered findings.[VERIFIED: .planning/UI-MILESTONE-PREFLIGHT.md:77-82,154-165]

Use a finite matrix rather than all dimensions multiplied together: capture every route in one stable desktop/light-or-dark hero condition; capture the three representative widths across each route; capture full shell at desktop and narrow widths; apply theme/System and keyboard/touch/reduced-motion/actual-zoom checks to representative shared controls and each materially different layout/state family; expand only where route-specific risk requires it. Capture pending/failed/reconnect with a real delayed/failed/disconnected interaction where possible, not a static mock masquerading as behavior. Record any unavailable state as a limitation and do not infer rendered results from source-only assertions.

Existing route capture clips to `#tl-main`, excluding the shared nav, and currently captures only the `1280` breakpoint; supplement it with full-shell captures and extend the route pass to representative intermediate and narrow widths. Existing project viewport sizes include desktop `1280 × 900`. Actual browser zoom must be driven through the visible Chromium/browser UI and separately recorded; use CUA or another available browser-chrome control to set 200% and verify resulting CSS layout, rather than using Playwright viewport or DPR emulation. Playwright docs describe `page.setViewportSize()` as page resize and `deviceScaleFactor` as DPR emulation, which are different test conditions. `[VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts:22-48; examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts:35-37,292-320; Playwright Page API; Playwright Browser API]`

### Existing output locations and write safety

The Playwright route spec writes screenshots/DOM/a11y under `examples/threadline_phoenix/e2e/artifacts/routes/` and JSON scorecards through the operator-surface path resolver into `test/generated/operator_surface/route-scorecards/`; current repo ignore rules treat these as generated artifacts. The path resolver already enforces output-root separation from immutable fixtures and offers root overrides. Prefer one fresh run output directory (and retain the original run manifest) over overwriting tracked screenshot guard snapshots. `[VERIFIED: examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts:316-375; examples/threadline_phoenix/e2e/support/operator-surface-paths.ts:21-44; git check-ignore]`

### Code example: targeted route proof

The following is a targeted project command pattern; phase execution should set a unique partition, then pass the capture project/spec through the existing named Mix wrapper. The Playwright config declares `name: "desktop-chromium"`, `name: "mobile-chromium"`, and `name: "route-capture"`; the test path is `operator-page-capture.spec.ts`.[VERIFIED: origin/main:examples/threadline_phoenix/e2e/playwright.config.ts:22-24,95-102; origin/main:examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts:378-382]

```sh
MIX_TEST_PARTITION=phase238 mix verify.example_browser --project=route-capture operator-page-capture.spec.ts
```

The wrapper runs the example's `e2e/run-e2e.sh`; it seeds before serving and forwards Playwright arguments. Confirm argument discovery on the isolated main checkout before relying on this targeted invocation. For final browser journey regression, use the preflight's established command `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium`. Use `mix verify.capture` only when intentionally regenerating existing Tier-A outputs; never make it an implicit side effect of ordinary inventory verification. `[VERIFIED: mix.exs:353-418; examples/threadline_phoenix/e2e/run-e2e.sh:234-306; .planning/UI-MILESTONE-PREFLIGHT.md, Verification that earns its cost]`

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|------------|-------------|-----|
| Current-main workspace isolation | `git checkout`, `git reset`, manual copy of repository source, or an invented Codex spawn isolation flag | GSD `worktree create` with an explicit source SHA, plus the resolved Codex `orchestrator-worktree` descriptor | Keeps the original dirty checkout intact and uses the supported path-bound `codex exec` adapter. |
| Browser interaction and responsive rendering | Static HTML parsing or screenshots from source-only templates | Existing Playwright runner against the seeded Phoenix app | Only a live browser can show layout, focus, LiveView transitions and actual served assets. |
| Repeated fictional audit data | Hand-built database rows for every screenshot | Existing deterministic demo seed; isolated E2E database partition | Keeps route evidence coherent and avoids user/production records. |
| Confidence/ranking automation | Paid visual critic or synthetic aggregate score | Human-readable agent review tied to route/state captures, plus existing deterministic checks | Phase decision forbids paid review and asks for evidence-based findings, not generated scores. |
| Browser zoom | DPR/viewport settings renamed “200% zoom” | Browser UI zoom control with observed layout/CSS dimensions | DPR and viewport are emulation knobs, not browser page zoom. |

**Key insight:** A screenshot is trustworthy only if the source SHA, assets actually served, fixture scenario and capture conditions agree. Browser capture establishes rendered evidence; source checks establish inventory and behavior contracts. Neither substitutes for the other.

## Common Pitfalls

### Treating the stale branch as current main

**What goes wrong:** The old v1.44 checkout can be mistaken for the approved v1.46 baseline.  
**Why it happens:** Planning files and source edits coexist in a dirty checkout.  
**How to avoid:** Refresh `origin/main` at execution, record its SHA, create the preview via supported GSD worktree CLI using that SHA, and verify the Codex adapter with a concrete target path. Preserve the original checkout and config.  
**Warning signs:** The preview's `git rev-parse HEAD` differs from the recorded source SHA, source diff contains unrelated local changes, or `inspect-dispatch-isolation` lacks a usable `codex exec --cd` result.

### Assuming the current route capture covers UIB-01

**What goes wrong:** The baseline claims eleven route captures while only the current capture spec's five unique routes ran.  
**Why it happens:** A degraded Timeline twin adds a sixth capture row and can be mistaken for a sixth route.  
**How to avoid:** Make the route manifest enumerate all eleven accepted route entries and test exact set equality with the inventory. Existing exact source values are `"route.timeline"`, `"route.timeline.degraded"`, `"route.coverage"`, `"route.retention"`, `"route.actor"`, and `"route.evidence"`.[VERIFIED: examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts:92-99]  
**Warning signs:** Duplicate path is counted as a new route; a directly-entered drawer/history state is missing.

### Trusting pinned capture metadata without checking the lockfile

**What goes wrong:** A baseline reports the wrong Playwright version as if it described the renderer that produced the pixels.
**Why it happens:** The capture spec currently declares `const PLAYWRIGHT_VERSION = "1.61.1";`, but `origin/main`'s Playwright lockfile declares `"version": "1.60.0"` for both the test package and its Playwright dependency.
**How to avoid:** Derive metadata from the installed test runner and report the browser executable/version actually used; keep declared package-lock version and runtime browser version as separate fields. Do not classify old scorecards as current-main evidence.
**Warning signs:** The recorded version is a source literal and does not match lockfile or browser launch metadata.[VERIFIED: origin/main:examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts:32-37; origin/main:examples/threadline_phoenix/e2e/package-lock.json:491-499]

### Resetting shared or production data

**What goes wrong:** The demo reset truncates existing rows or someone points the test runner at a non-test database.  
**Why it happens:** The browser runner automatically resets/seeds, and test database partitioning is an environment value.  
**How to avoid:** Set a unique `MIX_TEST_PARTITION`, verify `MIX_ENV=test`, confirm the derived test database before seeding, and use loopback-bound preview port. Keep production disabled. The runner executes `export MIX_ENV=test` and `mix demo.reset`/`mix demo.seed`; reset refuses production unless the explicit `DEMO_ALLOW_RESET=1` override is set, which this phase must never set.[VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh:14-17,244-252; examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex:142-158]  
**Warning signs:** Missing partition, a non-test DB hostname/name, or any production reset override.

### Capturing only the content region or trusting source candidates

**What goes wrong:** Shared navigation/theme shell gaps are missed, or a prior screenshot/source concern is reported as a reproduced visual defect.  
**Why it happens:** Route captures clip `#tl-main`; old screenshots and code findings are tempting substitutes for fresh renders.  
**How to avoid:** Capture shell separately, direct-enter every route and state, and link each finding to the source-bound capture ID.  
**Warning signs:** A finding has no fresh browser artifact or asset digest.

### Calling viewport emulation browser zoom

**What goes wrong:** Text and layout pass narrow viewport checks while actual 200% zoom remains untested.  
**Why it happens:** Playwright's viewport and DPR APIs are easily confused with browser UI zoom.  
**How to avoid:** Use browser chrome zoom at 200%, record it distinctly, and verify reflow/full value access in the actual window. If the automation cannot reach browser chrome, log the limitation without claiming the criterion passed.  
**Warning signs:** Only `page.setViewportSize()` or `deviceScaleFactor` appears in the proof.

### Expanding into a Cartesian capture explosion or rewriting baselines

**What goes wrong:** Capture cost balloons, unstable images overwrite reference evidence, or a baseline pass becomes a visual ratchet.  
**Why it happens:** Theme × width × state × route combinations are multiplied without risk partitioning.  
**How to avoid:** Use route coverage plus representative shell/state-family cross-checks; preserve reference fixtures and write new captures into a fresh generated directory.  
**Warning signs:** A run claims exhaustive rendering of every combination or ordinary verification changes checked-in PNGs.

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix and Erlang/OTP | Compile and run Phoenix/ExUnit | ✓ | Elixir 1.17.3; OTP 27 (local) | None needed |
| Node.js / npm | Playwright E2E runner | ✓ | Node 22.14.0; npm 11.1.0 (local) | None needed |
| Playwright project dependency | Browser capture | ✓ | 1.60.0 from `origin/main` lock; local binary runs 1.60.0 | If install is needed, use a task-scoped writable npm cache; default cache invocation returned EPERM due root-owned cache files. |
| Chromium | Browser capture and real browser UI zoom | ✓ | `/opt/homebrew/bin/chromium`; Playwright runner also provisions its pinned Chromium | Use Playwright's installed Chromium; do not substitute a different browser without recording it. |
| PostgreSQL | Example Ecto database | ✓ | Local `pg_isready`: `/tmp:5432 - accepting connections` | Docker is available if an isolated service is needed. |
| Docker Engine | Optional isolated PostgreSQL service | ✓ | Server 29.5.2, Docker Desktop | Use local PostgreSQL with unique `MIX_TEST_PARTITION`. |
| Codex CLI + GSD Core | Current-main worktree and handoff | ✓ | Codex CLI 0.161.0; GSD Core 1.16.0 | No fallback: halt if concrete-target adapter inspection fails. |
| External/paid visual service | None | Not required | — | Do not add one. |

**Availability caveat:** `npx --no-install playwright --version` could not access the default npm cache (`EPERM`, root-owned cache). The repository-local Playwright executable succeeded. If `npm ci` is needed in the isolated main tree, set `npm_config_cache` to a writable temporary path; do not repair user cache ownership with `sudo` as part of this phase.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit/Mix plus Playwright Test 1.60.0 |
| Config file | `examples/threadline_phoenix/e2e/playwright.config.ts` |
| Quick run command | `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/playwright test --list` (test discovery only; no server or writes) |
| Full suite command | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated command | File exists? |
|--------|----------|-----------|-------------------|-------------|
| UIB-01 | Isolated preview starts at refreshed current-main SHA, fixture is synthetic and partitioned, served asset digests match source identity, and every accepted route is captured. | ExUnit contract + browser integration + artifact inspection | `MIX_TEST_PARTITION=phase238 mix verify.example_browser --project=route-capture operator-page-capture.spec.ts` | Route capture exists but only for five distinct paths; extend route manifest/spec and add provenance contract. |
| UIB-02 | Each route, primitive, control and applicable material state has an evidence-linked rank/disposition; no inventory row is silently omitted. | Fast ExUnit/JSON contract + targeted browser interaction + agent review | `mix test test/threadline/operator_surface/operator_surface_fixture_contract_test.exs` (adapt/add a Phase 238 inventory-contract test in this area) plus targeted `mix verify.example_browser` route/state runs | Existing operator-surface contracts exist; Phase 238 inventory artifact and exact completeness contract are Wave 0 work. |
| UIB-02 | Keyboard/touch and state behavior are rendered where applicable, with route state and role preserved. | Existing browser suite + focused E2E | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium` | Existing browser specs cover access, motion, flows and route behavior; inspect discovery on the isolated main checkout before marking covered. |

### Sampling Rate

- **Fast artifact gate (per task):** Run the new focused inventory/provenance ExUnit contract with `mix test test/threadline/operator_surface/phase_238_inventory_contract_test.exs` and static JSON/hash/link checks against the manifest. This is the short completeness gate; it cannot claim a route rendered correctly.
- **Per capture batch:** Run only the targeted route/state Playwright project, writing to a fresh output root.
- **Expensive rendered proof (per capture batch / phase gate):** Run targeted `MIX_TEST_PARTITION=phase238 mix verify.example_browser --project=route-capture operator-page-capture.spec.ts`; on the final preview run `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium`, plus `mix verify.example_browser_light` when validating light/System. Inspect fresh captures and served asset hashes with agent judgment. Domain, shared component, and delivery checks use existing named `mix verify.test`, `mix verify.operator_component_contracts`, `mix verify.operator_stress`, and `mix ci.all` as appropriate. All eleven route entries and inventory items must resolve to evidence/disposition; source/served asset identity must agree. Maintainer UAT is not a gate.

### Wave 0 Gaps

- [ ] Add an inventory artifact schema with required `id`, kind (route/primitive/control/state), risk rank, owner phase, evidence/capture IDs and explicit disposition.
- [ ] Add a fast contract that compares the inventory route set against all eleven approved routes and rejects unlinked/blank dispositions.
- [ ] Extend current browser route capture from five distinct paths to all eleven, including direct-entry transaction/row-history/drawer/policy routes; add a separate full-shell capture.
- [ ] Add run manifest capture of source SHA/diff, fixture identity, browser conditions and served asset response digests; reject source/asset mismatch.
- [ ] Establish fresh, non-overwriting generated evidence output root and prove ordinary checks do not modify reference captures.
- [ ] Add/enable a reproducible 200% browser UI zoom path and record a truthful limitation if browser chrome cannot be controlled in automation.

Keep the two proof classes separate in tasks and outputs: fast schema/completeness checks may establish no omissions or dangling links, while only browser captures can establish rendered route/state behavior; source/ExUnit checks alone do not support a visual finding.

## Security Domain

This phase observes an existing auth-protected operator surface. Preserve host auth and tenant scoping; browser fixture credentials are local synthetic demo values and must not be added to committed run evidence. The demo reset is destructive to its configured demo tables, so isolate it to the unique E2E test partition and never set the production override.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard control |
|---------------|---------|------------------|
| V2 Authentication | Yes | Use the example's existing seeded login flow; no direct auth bypass. |
| V3 Session Management | Yes | Use Playwright's isolated browser context and login per fresh context/direct-entry capture. |
| V4 Access Control | Yes | Preserve the existing host auth/role/scope behavior and exercise denied states where applicable. |
| V5 Input Validation | Yes | Capture actual form/filter validation and error states; no new validators in this phase. |
| V6 Cryptography | No new crypto path | Avoid credentials/tokens in artifacts; no cryptographic implementation change is planned. |

### Known Threat Patterns

| Pattern | STRIDE | Mitigation |
|---------|--------|------------|
| Preview reset points at shared or production DB | Tampering / denial of service | Unique test partition, require `MIX_ENV=test`, inspect target DB, never enable production reset override. |
| Evidence captures auth/session secrets | Information disclosure | Store only synthetic fixture identity and asset metadata; redact password, cookie, authorization headers and sensitive response bodies. |
| UI appears to enforce access but route is directly reachable | Elevation of privilege | Browser direct-entry tests and existing server authorization tests; UI disable/hide is not authorization. |
| Wrong source serves stale cached assets | Tampering / misleading evidence | Hash browser-served JS/CSS and bind all findings to source SHA; mismatch invalidates classification. |

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| A1 | Browser CUA or another interactive Chromium control can set actual page zoom to 200% during the isolated preview run. | Bounded inventory and capture matrix; Wave 0 | Actual-zoom acceptance remains unproved; report a limitation instead of substituting DPR/viewport emulation. |
| A2 | The approved planning/product/design context can be copied byte-for-byte into a GSD-created current-main worktree without invoking a hidden automatic staging step. | Preview handoff | If not, stop and use an explicit read-only prompt/context handoff; never stage the dirty config to make the run proceed. |
| A3 | `operator-page-capture.spec.ts` accepts project and spec CLI arguments through the named Mix wrapper as proposed. | Code example; validation map | If argument parsing differs, use verified full command or adjust wrapper with a regression test. |

## Open Questions

1. **Can current-main browser UI zoom be automated in this runtime?**
   - What we know: Playwright's exposed viewport and device-scale controls are emulation, while this phase explicitly requires real browser zoom.
   - What's unclear: Whether headed Chromium plus current CUA can reliably operate its browser chrome and retain the 200% state for capture.
   - Recommendation: Make this a Wave 0 executable probe; capture the browser/CSS viewport evidence. If it fails, mark the actual-zoom criterion unresolved with the concrete reason rather than calling DPR/viewport “zoom.”
2. **Will the isolated main checkout load the same local Impeccable config/context after copy?**
   - What we know: Current `.impeccable/config.json` and `.impeccable/live/config.json` are user-approved context, and the original checkout must remain untouched.
   - What's unclear: Which config files are tracked/ignored and whether the main revision carries any of them.
   - Recommendation: Record source and destination hashes for the copied files and confirm the active code-first context before capture; do not rerun initialization.

## State of the Art

| Old approach | Current approach | When changed | Impact |
|--------------|------------------|--------------|--------|
| Screenshot-only visual judgment | Route/state inventory linked to rendered artifacts, plus deterministic checks | Existing v1.40+ tooling and approved v1.46 baseline scope | Findings become traceable and limited to evidence actually captured. |
| Viewport/DPR treated as zoom | Browser UI zoom tested as a distinct condition | Required by the current approved UI acceptance contract | Narrow viewport coverage alone does not prove usable text at 200%. |
| Screenshot baseline always serves as proof | Capture is explicit and ordinary verification is read-only | Existing runner/preflight guidance | Prevents destructive or platform-local snapshot churn. |

**Deprecated/outdated:** None recommended for removal in Phase 238. Existing screenshots and source candidates remain leads until reproduced or dispositioned.

## Sources

### Primary (HIGH confidence)

- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-CONTEXT.md` — locked scope, routes, capture conditions, safety, and deferred work.
- `.planning/UI-MILESTONE-PREFLIGHT.md` and `.planning/research/SUMMARY.md` — completed route/state research, source candidates and capture/verification lessons.
- `origin/main` refreshed with `git ls-remote` at `9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2` — route capture, Playwright, fixture and reset source.
- Local `gsd-tools query inspect-dispatch-isolation --json --cwd-target ... --prompt ...` and `worktree create` usage — actual installed Codex/GSD adapter and explicit-base CLI.
- [Playwright Page API](https://playwright.dev/docs/api/class-page) — viewport resizing API.
- [Playwright Browser API](https://playwright.dev/docs/api/class-browser) — device scale factor semantics.
- Local probes: `git status --short`, `pg_isready`, `docker info --format`, local Playwright executable, `mix --version`, `node --version`, `npm --version`, `codex --version`.

### Secondary (MEDIUM confidence)

- [GSD Core configuration and isolation docs](https://github.com/open-gsd/gsd-core/blob/next/docs/CONFIGURATION.md) — `workflow.use_worktrees` opt-out and Codex `orchestrator-worktree` model; local installed CLI behavior was probed separately.
- `.planning/PROJECT.md`, `PRODUCT.md`, `prompts/audit-lib-domain-model-reference.md`, `prompts/threadline-elixir-oss-dna.md`, and `prompts/Threadline Brand Book.txt` — approved product/domain/engineering language and constraints.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — source and lockfiles on refreshed `origin/main`, plus local runtime probes.
- Architecture: HIGH for the Phoenix/Playwright/fixture boundary; MEDIUM for context-copy handoff details that the phase executor must verify.
- Pitfalls: HIGH — code reads of the reset, route capture, output paths and runner; actual zoom control remains an explicit assumption.

**Research date:** 2026-10-08  
**Valid until:** 2026-11-07 for this stable project tooling; refresh `origin/main` and runtime/tool identity at execution.
