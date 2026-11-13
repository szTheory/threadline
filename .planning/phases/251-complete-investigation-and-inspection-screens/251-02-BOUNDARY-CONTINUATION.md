# Plan02 bounded continuation

The first standalone tracer caught a linked intent defect: clearing a valid historical time dropped explicit `from=` when another supported predicate (`table=users`) survived. The new live assertion failed on that exact destination; it was not a pixel/test-locator mismatch. Both retained-context and component serialization used a private UI helper that preserved blank from only for an otherwise empty query.

Include existing `timeline_live/helpers.ex` in this same bounded tracer, preserving an explicit blank from alongside supported predicates. Keep FilterParams.parse/1 and its unknown-key dropping/canonical serialization compatibility unchanged; no query key, route, host scope or public API changes. The existing failing live assertion and mounted retained-filter check verify the fix. Independent phase review includes this additional owner. This is a necessary routine correction inside approved D-01/D-04 intent, not a new architecture or user approval gate.

The interrupted executor exit1 and no-summary state are preserved. Parent continues the same manifest-owned isolated checkout and will retain sequential plan boundaries, scoped proof and independent review; no fresh historical intake is needed for continuation.
