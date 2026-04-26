# Phase 39: Reification & Schema Safety - Context

**Gathered:** 2026-04-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Add opt-in struct reification on top of the phase 38 single-row `as_of/4` path. The phase stays single-row, read-only, snapshot-first, and limited to historical reconstruction for one record at a time.

</domain>

<decisions>
## Implementation Decisions

### Struct loading shape
- **D-01:** `Threadline.as_of(..., cast: true)` returns `{:ok, %Schema{}}` on success, keeping the existing outer tuple contract.
- **D-02:** The returned value is a plain schema struct, not a wrapper that also carries the raw map.
- **D-03:** The default non-cast path stays map-only; phase 38's raw snapshot contract is unchanged.

### Loose casting
- **D-04:** Casting is permissive by default: ignore audit-log fields that no longer exist in the current schema.
- **D-05:** Missing current-schema fields keep their normal schema defaults / `nil` behavior; phase 39 does not add strict validation for historical shape drift.
- **D-06:** Use Ecto-native loading for the schema module rather than custom field-by-field mapping.

### Failure behavior
- **D-07:** If a historical snapshot cannot be loaded into the current schema, return an explicit cast error instead of silently falling back to the raw map.
- **D-08:** Delete and genesis-gap behavior from phase 38 remains authoritative; `cast: true` only affects successful snapshot reconstruction.

### API surface
- **D-09:** Keep the public API minimal in phase 39: `cast: true` is the only cast-related switch.
- **D-10:** Do not add `:strict`, `:on_cast_error`, or raw-preservation toggles in this phase.

</decisions>

<specifics>
## Specific Ideas

- Prefer the native Ecto loading path so struct reification behaves like the rest of the ecosystem.
- Keep the historical read path read-only; this is reconstruction, not revert or write-back.

</specifics>

<canonical_refs>
## Canonical References

### Core phase context
- `.planning/ROADMAP.md` — Phase 39 goal, dependencies, and success criteria.
- `.planning/REQUIREMENTS.md` — ASOF-03 and ASOF-04 requirements for struct reification and loose casting.
- `.planning/STATE.md` — current project state and phase sequencing.

### Phase 38 handoff
- `.planning/phases/38-core-as-of-reconstruction/38-01-SUMMARY.md` — locked map-only reconstruction pattern and prior decisions.
- `.planning/phases/38-core-as-of-reconstruction/38-VERIFICATION.md` — verified delete / genesis-gap behavior and query contract.

### Existing implementation
- `lib/threadline.ex` — public `as_of/4` delegator.
- `lib/threadline/query.ex` — snapshot-first `as_of/4` query implementation.
- `lib/threadline/capture/audit_change.ex` — audit snapshot shape and JSON map fields.
- `test/threadline/query_test.exs` — current `as_of/4` regression coverage.

### Research notes
- `.planning/research/SUMMARY.md` — prior reconstruction research and recommended struct-loading direction.
- `.planning/research/FEATURES.md` — reconstruction feature framing and ergonomics goals.
- `.planning/research/PITFALLS.md` — schema-drift and historical-data failure modes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Query.as_of/4`: already isolates snapshot-first lookup and explicit delete/genesis classification.
- `AuditChange.data_after`: already stores the historical row snapshot needed for reification.
- Existing `:repo` option style in `history/3` and `as_of/4`: keep the public API consistent.

### Established Patterns
- Phase 38 keeps historical reads map-only until reification is added.
- Public APIs favor explicit errors for invalid inputs or unrecoverable shape problems.
- The library keeps the success/error tuple contract stable across public read APIs.

### Integration Points
- `Threadline.as_of/4` remains the only public entry point for single-row reconstruction.
- `Threadline.Query.as_of/4` is the implementation seam for struct reification.
- Phase 40 can document the cast path once the phase 39 behavior is stable.

</code_context>

<deferred>
## Deferred Ideas

- `Threadline.as_of_all/4` for collection-wide reconstruction — future requirement, not phase 39.
- Association travel / reconstructing related records at time T — future requirement, not phase 39.
- Any stricter cast mode, raw preservation toggles, or additional load options — defer until real usage proves they are needed.

</deferred>

---

*Phase: 39-reification-schema-safety*
*Context gathered: 2026-04-25*
