# Phase 85: Support-Lane Surface Audit & Claim Narrowing - Cohesive Recommendation

*Synthesized autonomously based on ecosystem research, user preferences, and the Threadline product thesis.*

## Executive Summary

Phase 85 must lock the claims and support matrix for the new "Support-Lane" before implementation begins. The most critical gray area is how to handle the `RowHistoryComponent` (`Threadline.history/3` and `Threadline.as_of/4`), which currently lacks scope enforcement. 

Based on the research from our `prompts/` directory (including lessons from JaVers, django-simple-history, and PaperTrail) and the core goal of building the "batteries-included audit platform for Phoenix", **disabling row history for support operators is a UX anti-pattern**. We must push `scope_query_fn` down into the core data APIs to make the entire UI safely accessible to support personas.

---

## 1. Row History / As-Of Posture

**The Dilemma:** `TimelineLive`, `ActorLive`, and `TransactionLive` already enforce `scope_query_fn`. `RowHistoryComponent` (which powers the "As-Of" and diff views) does not. We can either explicitly disable this component for support-scoped users, or we can wire `scope_query_fn` into `Threadline.history/3` and `Threadline.as_of/4`.

**Recommendation: Scope the history queries (Do not disable the UI).**
- **Extend the Core APIs:** Update `Threadline.history/3` and `Threadline.as_of/4` to accept the `scope_query_fn` callback as an option, applying the same query-narrowing used in `TimelineLive`.
- **Ecosystem Lessons:** `django-simple-history` and `JaVers` prove that developers and operators derive massive value from diffs, snapshots, and `as_of` queries. The JTBD of a support operator is literally "When a customer says 'something changed', I want to find the exact action and affected records quickly." Disabling the diff/history view for support agents severely cripples their ability to do their job. 
- **Idiomatic Elixir/Ecto:** Ecto relies on composable query functions. Passing a `scope_query_fn` (an anonymous function that transforms an `Ecto.Query.t()`) down to the `Threadline` context module is perfectly idiomatic. It ensures that the authorization logic remains host-owned while Threadline handles the query mechanics safely.
- **Security / Footgun Prevention:** Pushing the scope enforcement into the lowest-level APIs (`Threadline.history/3`) ensures that if adopters build custom UIs or export scripts calling these functions, they get secure-by-default behavior. 

---

## 2. Export / Scope Guard Packaging

**The Dilemma:** How strict should the "support lane" claim be regarding bulk data exports?

**Recommendation: Enforce `exports: false` by default for support-scoped operators, requiring explicit opt-in via `export_authorize_fn`.**
- **Why:** Bulk export of audit logs is a massive data exfiltration risk. The principle of least surprise dictates that a "support-read-only" scope should not implicitly grant the ability to download the entire tenant's audit trail to a CSV.
- **The Contract:** The docs and integration recipes should explicitly state that Threadline provides the `scope_query_fn` seam for safe in-browser exploration, but exports remain an admin-tier privilege unless explicitly wired by the host app.

---

## 3. The Final Matrix Lock (Plan 85-01 & 85-02)

To close out Phase 85, the plans should reflect:
1. **Surface Audit Lock:** The milestone explicitly claims support-lane safety for Timeline, Actor, Transaction, **and Row History** views. No views are disabled; all are scoped.
2. **Matrix Wording Lock:** The documentation contract will explicitly separate the "UI Scope" (`scope_query_fn`) from the "Export Scope" (`export_authorize_fn`), teaching adopters that support agents get UI exploration, but exports remain locked down by default.

## Next Steps

If you agree with this cohesive approach, we can immediately write `85-01-PLAN.md` and `85-02-PLAN.md` reflecting these decisions and conclude the discuss phase.