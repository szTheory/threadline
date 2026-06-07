# Roadmap: Threadline v1.34 Local Docker Admin UI DX

**Status:** implementation complete; awaiting milestone closeout/archive
**Milestone:** v1.34 Local Docker Admin UI DX
**Opened:** 2026-06-06
**Last shipped:** v1.33 Brand Review + Direction Selection (2026-06-06)

## Milestones

- ✅ **v1.34 Local Docker Admin UI DX** — Phases 154-158 (implementation complete; awaiting archive)
- ✅ **v1.33 Brand Review + Direction Selection** — Phases 150-153 (shipped 2026-06-06). Archive: `.planning/milestones/v1.33-ROADMAP.md`
- ✅ **v1.32 Brand System Foundation** — Phases 145-149 (shipped 2026-06-05). Archive: `.planning/milestones/v1.32-ROADMAP.md`

## Current Milestone Goal

Make the Docker-backed Phoenix operator demo easy to start, refresh, inspect, stop, and run alongside other local Docker projects without port or cache pain.

## Phases

### Phase 154: Docker DX Audit + Contract

**Goal:** Audit the current Docker/demo helper behavior, lock the helper-first routing decision, and define source/doc/test contracts before hardening.

**Requirements:** DX-DEMO-01, DX-DEMO-02, DX-DEMO-03, DX-PORT-01, DX-PORT-02, DX-CLEAN-01, DX-CACHE-01, DX-DOC-01, DX-PROXY-01

**Success criteria:**
1. Current Docker Compose, Dockerfile, helper, and local Docker docs are inventoried against the v1.34 requirements.
2. Helper-first dynamic localhost ports are recorded as canonical for this milestone.
3. Traefik/subdomain routing is recorded as deferred with `.localhost` as the future-safe hostname family.
4. Known port, project-name, cleanup, and cache footguns are converted into implementation checks.

### Phase 155: Demo Helper Hardening

**Goal:** Finalize `bin/demo-up` as the canonical one-command seeded `/audit` demo entrypoint.

**Requirements:** DX-DEMO-01, DX-DEMO-02, DX-DEMO-03, DX-PORT-01, DX-CLEAN-01

**Success criteria:**
1. `bin/demo-up` starts the demo, waits for sign-in and `/audit`, and prints the actual browser URLs.
2. Re-running `bin/demo-up` refreshes the existing same-project stack on the same published port.
3. Busy default ports fall back to available local ranges unless the user explicitly requested a fixed non-default port.
4. `--status`, `--logs`, `--down`, and `--fresh` operate on the same profile-aware Compose project.
5. Startup failures print recent demo logs before exiting non-zero.

### Phase 156: Compose + Dockerfile Cache/Isolation Hardening

**Goal:** Keep the demo isolated, localhost-bound, and cache-friendly across multiple checkouts and adjacent Docker projects.

**Requirements:** DX-PORT-02, DX-CACHE-01

**Success criteria:**
1. Compose resources remain project-scoped; no global `container_name` or shared default resource names are introduced.
2. Host ports bind to localhost by default while container-to-container traffic stays on stable service names and container ports.
3. Demo dependency/build outputs use Docker volumes so container-native artifacts are reused.
4. Dockerfile dependency fetch layers are protected from ordinary source/style edits.
5. PgBouncer remains opt-in and pinned enough for reproducible local topology checks.

### Phase 157: Reader-First Documentation Pass

**Goal:** Make local Docker usage clear from each relevant reader entrypoint without turning every guide into Docker internals.

**Requirements:** DX-DOC-01, DX-PROXY-01

**Success criteria:**
1. Root contributor docs explain the Postgres-only and full-demo paths distinctly.
2. Example README starts with `bin/demo-up`, credentials, printed URLs, refresh, stop, and reset.
3. Walkthrough docs acknowledge printed host/port values while keeping default `localhost:4000` examples readable.
4. Local Docker DX guide explains project names, host ports, cleanup, stale code, and multi-stack usage in short sections.
5. Docs explicitly reject `.dev`/`localhost.dev` for HTTP local demos and defer Traefik to a future optional shared-proxy mode.

### Phase 158: Verification + Closeout

**Goal:** Prove the Docker demo DX works on the current tree and close the milestone with actionable evidence.

**Requirements:** DX-DEMO-01, DX-DEMO-02, DX-DEMO-03, DX-PORT-01, DX-PORT-02, DX-CLEAN-01, DX-CACHE-01, DX-DOC-01, DX-PROXY-01

**Success criteria:**
1. One-stack startup reaches `/users/log_in` and `/audit` at the printed URL.
2. Repeated helper startup refreshes the same stack and preserves the browser URL.
3. Busy-port behavior is verified or covered by focused helper checks.
4. Lifecycle commands are verified without leaving Docker resources behind.
5. Relevant doc-contract or targeted tests pass, with any unrelated pre-existing failure called out.

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|---|---|---:|---|---|
| 154. Docker DX Audit + Contract | v1.34 | 1/1 | Complete | 2026-06-06 |
| 155. Demo Helper Hardening | v1.34 | 1/1 | Complete | 2026-06-06 |
| 156. Compose + Dockerfile Cache/Isolation Hardening | v1.34 | 1/1 | Complete | 2026-06-06 |
| 157. Reader-First Documentation Pass | v1.34 | 1/1 | Complete | 2026-06-06 |
| 158. Verification + Closeout | v1.34 | 1/1 | Complete | 2026-06-06 |
