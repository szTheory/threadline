# Phase 87: Canonical Mount Recipe & Example-App Proof - Discussion

## Context & Goals

Phase 87 addresses the adoption narrative for Threadline's operator surface. Per `REQUIREMENTS.md` and `ROADMAP.md`:
- **ADOPT-01**: Threadline ships one canonical `/audit` mount recipe showing admin and support personas on the same host-owned route tree.
- **ADOPT-02**: The example Phoenix app proves the canonical support lane with host-owned `scope_query_fn` narrowing and admin-only export posture.
- **ADOPT-03**: Any new surface controls added in this milestone stay minimal and additive; Threadline does not introduce a role DSL, tenancy DSL, or policy engine.

### Current State
Currently, `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`, `examples/threadline_phoenix/README.md`, and `guides/getting-started-saas.md` include a commented-out secondary routing tree demonstrating a "Support-read-only variation" at `/support` using `exports: false`.

While this shows flexibility, it dilutes the adoption message. It forces the user to immediately evaluate "which tree shape do I need?" rather than following a single "golden path" that naturally degrades capabilities based on the host app's existing authentication and scoping functions.

## Architectural Recommendations

Per project memory (`gsd-research-then-recommend.md`), here is the cohesive, one-shot recommendation for the canonical mount recipe.

### 1. Drop the Secondary "Separate Tree" Concept Entirely
**Recommendation:** Remove the commented-out `/support` mount and all references to the "narrower recipe on a separate tree" from the example app router and documentation guides. 

**Rationale & Tradeoffs:**
- **Pros (Developer Ergonomics & Least Surprise):** Adopters get exactly one copy-pasteable block of code. The mental model shifts from "configure multiple UI instances" to "mount once and use standard Elixir functions (`authorize_fn`, `export_authorize_fn`, `scope_query_fn`) to control behavior." This is highly idiomatic to Phoenix (like `phx.gen.auth`), pushing authorization into code rather than configuration.
- **Cons:** Users who genuinely want completely isolated URLs for different roles will have to figure out the multiple-mount approach themselves (though it remains possible). 
- **Ecosystem Precedent:** Tools like Livebook and Oban Web typically advocate for a single dashboard mount secured by the host's existing `plug` pipelines.

### 2. Rely Exclusively on `scope_query_fn` and `export_authorize_fn` for Persona Degradation
**Recommendation:** Ensure the canonical narrative highlights how a single `/audit` tree securely serves both Admins and Support Operators. 

**Rationale:**
- **Proof of Concept:** The example app already uses `scope_operator_query/3` and `my_export_authorize_fn/1`. Admins get the full timeline and export abilities; support operators are constrained by a `WHERE metadata->>'organization_id' = ?` clause and receive HTTP 403s on exports.
- **Why this works:** By emphasizing `export_authorize_fn` for UI degradation, Threadline eliminates the need for the coarse `exports: false` opt at the router level. The UI hides export buttons for support users dynamically, offering a much more polished UX without duplicating router scopes.

### 3. Maintain Absolute Host Ownership of Tenancy and Roles (No DSL)
**Recommendation:** Strictly adhere to ADOPT-03. Do not add `Threadline.Role` or a concept of an `organization_id` to the library itself.

**Rationale:**
- Every SaaS implements tenancy differently (some use Ecto prefixes, some use foreign keys, some use custom contexts). By keeping Threadline's inputs as opaque maps (`scope` and `context` passed to `scope_query_fn`), we avoid prescribing a restrictive authorization DSL, maintaining zero-friction adoption for brownfield projects.

## Execution Plan

If these recommendations are accepted, the execution phases (87-01 and 87-02) will consist of:
1. **Source Code:** Deleting the commented-out `/support` mount in `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`.
2. **Docs Alignment:** Updating `examples/threadline_phoenix/README.md` and `guides/getting-started-saas.md` to remove references to the separate tree variation and reinforcing the single canonical `/audit` tree.
3. **Verification:** Compiling the example app and checking `mix verify.compile_no_optional` to ensure the project stays green, and visually verifying the docs diff.

---
*Ready for user alignment. Use `/gsd-plan-phase 87` to proceed to task breakdown if this strategy is approved.*