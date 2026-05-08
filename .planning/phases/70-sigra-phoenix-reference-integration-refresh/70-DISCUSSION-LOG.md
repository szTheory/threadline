# Phase 70: Sigra/Phoenix Reference Integration Refresh - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-07
**Phase:** 70-sigra-phoenix-reference-integration-refresh
**Areas discussed:** Version posture and proof pins, Reference-path auth story, Surface-first vs capture-first narrative, Scope of the Sigra reference lane

---

## Version posture and proof pins

| Option | Description | Selected |
|--------|-------------|----------|
| Lane-split wording | Declared semver ranges in library docs, exact tested root/example resolutions as proof pins by lane | ✓ |
| Exact-stack-first wording everywhere | One fully pinned Phoenix/Sigra stack as the only published story | |
| Range-only wording | Declared semver ranges with no explicit proof pins | |

**User's choice:** Lane-split wording
**Notes:** Best fit for Mix/Elixir library norms and for Phase 69's honesty bar. Root `phoenix-surface` and narrower `sigra-reference` lanes should keep different proof anchors without ambiguity.

---

## Reference-path auth story

| Option | Description | Selected |
|--------|-------------|----------|
| Host-owned admin boundary + dual-surface auth contract | Sigra stays request-capture-only; `/audit` remains behind host browser/admin auth plus Threadline auth hooks | ✓ |
| Sigra-first one auth story | Present Sigra as the unified capture + operator auth story | |
| Fully split transport story | Separate top-level capture, LiveView, and export auth narratives | |

**User's choice:** Host-owned admin boundary + dual-surface auth contract
**Notes:** Most idiomatic for Phoenix/LiveView and best aligned with the current example app and locked host-owns-auth boundary.

---

## Surface-first vs capture-first narrative

| Option | Description | Selected |
|--------|-------------|----------|
| Surface-first canonical narrative | One mounted happy path, with explicit API/Mix fallback notes | ✓ |
| Capture-first canonical narrative | Core-library-first story, with surface secondary | |
| Dual-track top-level narrative | Surface-first and capture-first presented as equal primary flows | |

**User's choice:** Surface-first canonical narrative
**Notes:** Preserve Phase 68's “one obvious path” decision while explicitly naming capture-only parity instead of splitting the docs into two equal top-level tracks.

---

## Scope of the Sigra reference lane

| Option | Description | Selected |
|--------|-------------|----------|
| One maintained narrow path | One guide, one example app, one proved callback pair for Phoenix hosts already using Sigra | ✓ |
| Narrow path plus adjacent variants | Canonical path plus documented unclaimed variants/caveats | |
| Broad variants matrix | Multiple auth/layout/version branches inside the Sigra/Phoenix story | |

**User's choice:** One maintained narrow path
**Notes:** Best match for v1.19 breadth honesty and current repo proof. Variants remain unclaimed unless later phases add proof.

---

## the agent's Discretion

- Exact wording and placement of proof-pin language across `guides/upgrade-path.md`, `guides/integrations/sigra.md`, `README.md`, and `examples/threadline_phoenix/README.md`
- Exact doc-contract test updates required to lock refreshed wording

## Deferred Ideas

- Additional first-party Sigra/Phoenix variants without repo proof
- A broader multi-layout compatibility matrix for the Sigra lane
- Larger Sigra adapter scope beyond the current Plug callback pair
