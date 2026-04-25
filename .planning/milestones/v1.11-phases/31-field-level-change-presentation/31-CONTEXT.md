# Phase 31: Field-level change presentation - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **XPLO-01** (`.planning/REQUIREMENTS.md`) and roadmap **Phase 31** success criteria:

- Public API (module + function names in ExDoc) returns a **deterministic** structure for a given `%Threadline.Capture.AuditChange{}` that callers can **`Jason.encode!/1`** without leaking private structs in the payload.
- **INSERT** / **UPDATE** / **DELETE** covered; when **`changed_from`** is absent, behavior is **documented** and **never invents** prior scalar values.
- **Unit tests** lock representative shapes (including masked / redacted JSON where the change row already reflects capture policy).

**Out of scope (unchanged):** New capture semantics or migrations; LiveView operator UI; transaction-scoped listing (**Phase 32**); operator routing doc hub (**Phase 33**); Hex semver bump unless a separate release phase says so.

</domain>

<decisions>
## Implementation Decisions

Discussion used **six parallel research passes** (subagents) on API placement, JSON shape, epistemic semantics for missing before-values, INSERT/DELETE presentation, mask parity, and ordering — then **one maintainer-directed cohesive synthesis** so all choices stay mutually consistent with **`Threadline.Export`**, **`Threadline.Query`**, capture SQL (`changed_fields` ordering), and v1.10 “SQL-native / honest by default” vision.

### D-1 — Canonical module and entrypoints

- **Canonical implementation module:** **`Threadline.ChangeDiff`** (sibling to **`Threadline.Export`** and **`Threadline.Query`** — capability-named, not nested under `Query`).
- **Rationale:** Field-level presentation is a **pure projection** of one `%AuditChange{}`, not query composition. Phase 32 reserves **`Threadline.Query`** (+ **`Threadline`** delegators) for **retrieval / listing**; co-locating diff logic inside `Query` mixes fetch with serialize and surprises Phoenix-style “context fetches, formatter shapes” separation.
- **Optional discoverability:** At most **one or two** thin **`defdelegate`**s on **`Threadline`** (e.g. `Threadline.change_diff/1` → `Threadline.ChangeDiff.from_audit_change/1`) if ExDoc/README want REPL ergonomics — keep **options-heavy** or **format variants** only on **`Threadline.ChangeDiff`** to avoid root-module bloat.
- **Do not:** Hide the only public API behind **`Threadline`** with no named module; do not make diff a submodule of **`Threadline.Query`**.

### D-2 — JSON shape contract (integrator-first + export parity)

- **Primary wire shape:** **String keys throughout**; top-level **`schema_version`** integer (start at **1**); **`field_changes`** as a **lexicographically sorted** array (see D-6) of objects, each with at least **`"name"`** (column string) and documented **`"after"`** / prior epistemics per D-3. Use JSON-serializable values only (same class of values as today’s `data_after` / JSONB from Postgrex).
- **Secondary / compatibility shape:** **`format: :export_compat`** (or a dedicated function **`to_export_change_map/1`**) returns the **same logical triple** as **`Threadline.Export`**’s internal `change_map/1` — **`op`**, **`data_after`**, **`changed_fields`**, **`changed_from`** (and identifiers as in export) — so integrators who already merge export JSON need **zero** new merge rules.
- **Rationale:** Export already proves **string-keyed** maps and pass-through JSONB (**`lib/threadline/export.ex`** `change_map/1`). A derived **`field_changes`** array gives JS/TS and OpenAPI consumers **one loop** without reimplementing join logic, while **export_compat** preserves least surprise next to CSV/export docs.
- **Footguns to avoid in implementation:** Atom keys as the default public shape; relying on **`Map`** iteration order for tests or bytes; using **`Jason`** on structs without normalizing; overloading document **`format_version`** (export document) with per-change **`schema_version`** without documenting both scopes.

### D-3 — When `changed_from` is nil or sparse (epistemic honesty)

- **Never** use bare **`"prior": null`** as the **only** signal for “integrator did not capture before-values” — **`null`** must remain available for **JSON/SQL null** semantics where the row truly stored null.
- **Row-level signal (once per change):** **`before_values: "none"`** when **`changed_from`** is **`nil`** (integrator did not enable before-values). **`before_values: "sparse"`** when **`changed_from`** is a **map** (empty or not) — document **`{}`** vs **`nil`** distinctly in the matrix. Add **`"full"`** only if a future capture shape stores complete row before-images (not Phase 31).
- **Per-field (UPDATE):** When **`before_values: "none"`** — **omit** **`before`/`prior`** keys entirely on each **`field_changes`** entry (only **`after`** / new value). When **`before_values: "sparse"`** and a column in **`changed_fields`** has **no** key in **`changed_from`** — include **`prior_state: "omitted"`** (or similarly named closed enum) on **that field only**; when the key exists, emit **`before`** from JSON truth (including JSON **`null`** if stored) and do not overload **`null`** to mean “not captured.”
- **Do not** invent prior values or imply rollback feasibility when capture did not store them.

### D-4 — INSERT and DELETE semantics

- **INSERT:** Default presentation is **row snapshot** — expose **`data_after`** (or a clearly named **`row_after`**) as authoritative; **`field_changes`** **empty** or omitted by default. Optional **`expand_insert_fields: true`** (or separate arity) may synthesize **`kind: "set"`** entries **only** from keys present in **`data_after`** for integrators who want uniform “field chips” — document that this is **derived**, not stored per-field capture.
- **DELETE:** Default is **row removal** — **`op`**, **`table_pk`**, transaction metadata as needed; **`data_after`** is **`nil`** as today; **no** synthetic per-field “removes” **until** capture persists a real **pre-image** (out of scope for Phase 31). Do not pretend column-level DELETE events existed in the DB.
- **Rationale:** Triggers record **one row mutation**; **`changed_fields`** / **`changed_from`** are **UPDATE-shaped** facts in this product. Uniform delta UIs are a **presentation opt-in**, not the default truth.

### D-5 — Mask / redaction / `except_columns` parity

- **Authority:** The diff helper is a **pure function** of the same persisted fields **`Threadline.Export`** uses: **`op`**, **`table_pk`**, **`data_after`**, **`changed_fields`**, **`changed_from`**, timestamps/ids as needed for the chosen format — **no** live table fetch, **no** default re-application of Elixir **`RedactionPolicy`** on raw values.
- **UPDATE key set:** Iterate **exactly** the capture-provided **`changed_fields`** list (not **`Map.keys(data_after)` ∪ `Map.keys(changed_from)`**), so **`except_columns`** (keys in **`data_after`** but absent from **`changed_fields`/`changed_from`**) stays honest.
- **Masking:** If **`data_after`** / **`changed_from`** contain the stable **`:mask`** placeholder (or configured placeholder), the diff shows **the same placeholders** — no inference of cleartext. Document low-information diffs for masked columns as **expected**.
- **Optional later:** Any **synthetic** “what-if” diff from raw app rows + policy belongs in a **separately named** module with scary moduledoc — **not** the XPLO-01 default path.

### D-6 — Deterministic ordering

- **Rule:** Emit **`field_changes`** in **lexicographic order of `"name"`** (UTF-8 binary term order). This matches **capture SQL** intent (`array_agg(... ORDER BY n.key)` for **`changed_fields`**).
- **Maps:** If any auxiliary map keyed by field name appears in the public shape, **sort keys** at construction (never rely on **`Map`** / encoder iteration order for stable bytes or tests).

### D-7 — Cross-cutting DX and docs

- **ExDoc:** **`@moduledoc`** sections are mandatory: authority model (pass-through vs synthetic), **INSERT/UPDATE/DELETE** matrix, **`before_values`** / **`prior_state`**, **`except_columns`**, mask placeholders, **`schema_version`** evolution (additive only), relationship to **`Threadline.Export`**.
- **Tests:** Prefer fixtures aligned with **trigger output** / export JSON, not hand-crafted `%AuditChange{}` with imaginary secrets.

### Claude's Discretion

- Exact atom names for enums (`before_values`, `prior_state` strings) if a shorter closed vocabulary reads better in OpenAPI.
- Whether **`Threadline`** gets **zero, one, or two** delegators once Phase 32 lands — keep **root surface** minimal.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **XPLO-01** acceptance criteria.
- `.planning/ROADMAP.md` — Phase **31–33** goals, success criteria, requirements map.

### Domain and capture truth

- `guides/domain-reference.md` — audit model, operator vocabulary, cross-links for support paths.
- `lib/threadline/capture/audit_change.ex` — schema fields and meanings of **`op`**, **`data_after`**, **`changed_fields`**, **`changed_from`**.
- `lib/threadline/capture/trigger_sql.ex` — **`changed_from`**, mask vs exclude vs **`except_columns`** semantics.

### Existing serialization patterns

- `lib/threadline/export.ex` — **`change_map/1`** string-key shape, **`Jason.encode!`** usage for **`data_after`** / **`changed_fields`** / **`changed_from`** (parity reference for **`:export_compat`**).

### Public API neighbors

- `lib/threadline/query.ex` — **`history`**, **`timeline`**, export query composition (Phase 32 will extend here — do not overload with diff).
- `lib/threadline.ex` — existing delegator patterns for **`history`**, **`timeline`**, etc.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`Threadline.Export`** `change_map/1` / CSV row builders — **export_compat** shape and string-key conventions.
- **`Threadline.Capture.AuditChange`** — single source of field types for inputs.

### Established Patterns

- **Top-level capability modules** (`Query`, `Export`, `Retention`, …) rather than dumping logic into **`Threadline`** only.
- **Honest capture docs** — optional **`changed_from`**, no silent prior invention.

### Integration Points

- **`Threadline`** optional **`defdelegate`** for discoverability.
- Future **Phase 33** domain-reference “when to use” table will reference this helper alongside **`history`**, **`timeline`**, export — keep naming stable and documented.

</code_context>

<specifics>
## Specific Ideas

- User preference (2026-04-24): **Discuss all gray areas in one shot** with **parallel subagent research**, then **cohesive recommendations** so planning can proceed without re-negotiating API ergonomics — reserved **interactive** GSD menus for **high-impact** tags only (**semver**, **security_model**, **breaking_public_api**, **scope_cut**).

</specifics>

<deferred>
## Deferred Ideas

- **Synthetic / policy-reapplied diff** from raw app state (non-persisted audit) — separate module + docs if ever needed; not XPLO-01.
- **Per-field DELETE removes** — only if capture gains durable **pre-image** on DELETE rows.

### Reviewed Todos (not folded)

- None from `todo.match-phase` for phase 31.

</deferred>

---

*Phase: 31-field-level-change-presentation*  
*Context gathered: 2026-04-24*
