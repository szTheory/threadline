# Phase 63 Architectural Research & Recommendations

**Phase:** 63 - Docs, Contracts & Changelog
**Context:** This research fulfills the deep, cohesive, one-shot recommendation mandate for Phase 63. It addresses how to properly document and lock the contracts for the new v1.17 operator surface, preventing silent regression and ensuring an excellent developer experience (DX).

## 1. Doc-Contract Tests (DOC-01)

### Goal
Lock the `Threadline.OperatorSurface.Router` macro signature, the default route literals (`/audit/transactions/:id`, `/audit/actors/:kind/:id`, `/audit/rows/:table/:pk`), and the README's auth section verbatim so that any future drift fails CI.

### Architectural Recommendation

**Approach:** Build a dedicated `doc_contract_test.exs` using Elixir's native `ExUnit`. Read the `README.md` at test time and assert the presence of exact strings or regex patterns that represent the critical integration points. Parse the AST or use `__info__(:functions)`/`__info__(:macros)` to assert the macro signature.

#### Pros/Cons/Tradeoffs
*   **Pro:** Absolutely guarantees that the README copy-paste instructions actually work with the current codebase. Eliminates "works on my machine but docs are stale" syndrome.
*   **Pro:** Low dependency; relies entirely on built-in Elixir compiler and ExUnit features.
*   **Con:** Tests can be brittle if the copywriter simply wants to fix a typo in the README but it breaks a regex.
*   **Tradeoff Mitigation:** The assertions should check *only* the functional code blocks inside the README (e.g., the `threadline_operator_surface` macro call snippet), not the prose around it.

### Idiomatic Elixir / Ecosystem Lessons
*   **Ecto & Phoenix:** Both framework giants make heavy use of `@moduledoc` doctests (`ExUnit.DocTest`), but for top-level READMEs, reading the file and asserting snippet inclusion is the gold standard for "doc-contract" testing.
*   **Ergonomics:** When a doc-contract test fails, the failure message should explicitly tell the developer *why* they are blocked: "You changed the routing macro, please update the README to match."

## 2. Operator Surface Guide (DOC-02) & README Updates (DOC-03)

### Goal
Create `guides/operator-surface.md` covering mount, `:actor_fn` / `:authorize_fn`, screens, and the Mix task. Update the top-level README and checklist to point to it.

### Architectural Recommendation

**Approach:** Treat the guide as the definitive operator manual. The top-level README should only show the "1-minute mount" example and then link directly to the guide for policy and auth details.

#### Pros/Cons/Tradeoffs
*   **Pro:** Keeps the README scannable and focused on the value proposition.
*   **Pro:** Centralizes complex "How to answer support questions" workflows in one guide that an operator (who might not be a dev) can bookmark.
*   **Ecosystem Lesson (Oban Web / LiveDashboard):** Oban separates its worker docs from its Web UI docs. LiveDashboard has a dedicated guide for metrics/custom pages. Trying to cram UI instructions into the core capture library's README always fails.

## 3. Changelog & Dependency Posture (DOC-04)

### Goal
Document the v1.17 changes, specifically the `optional: true` Phoenix/LiveView deps and the new mount macro, for the next published Hex version.

### Architectural Recommendation

**Approach:** Use the standard Keep a Changelog format. Explicitly group the Operator Surface changes under a major `### Added` heading, emphasizing that capture-only adopters face zero bloat.

#### Pros/Cons/Tradeoffs
*   **Pro:** Reassures existing users that `phoenix` and `live_view` have not become hard dependencies.
*   **Principle of Least Surprise:** Adopters fear updates that suddenly pull in 30 web dependencies to a backend service. The changelog must address this anxiety in the first sentence.

## Synthesis

The strategy for Phase 63 is defensive documentation. By treating docs as a tested contract, we protect the adopter's onboarding experience. The combination of a strict ExUnit doc-contract suite and a dedicated Operator Surface guide ensures that the complex auth boundaries shipped in v1.17 are both discoverable and structurally sound over time.