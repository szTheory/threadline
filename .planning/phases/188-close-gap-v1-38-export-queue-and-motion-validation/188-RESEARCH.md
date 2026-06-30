# Phase 188: Close gap: v1.38 export queue and motion validation - Research

**Researched:** 2026-06-30
**Domain:** Threadline operator exports, queued export replay, CSS motion governance, Phoenix LiveView/ExUnit/Playwright validation
**Confidence:** HIGH for codebase findings, MEDIUM for external documentation findings

## User Constraints

No Phase 188 `CONTEXT.md` exists, so the controlling inputs are the v1.38 requirements, roadmap, state history, Phase 187 artifacts, and the v1.38 milestone audit. [VERIFIED: user prompt] [VERIFIED: codebase grep]

### Locked Inputs

- Phase 188 exists to close v1.38 export queue and motion validation gaps after Phases 181-187 completed. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]
- The milestone audit identifies partial v1.38 gaps in `TIME-01`, `GOV-02`, `A11Y-02`, and `MOTION-01`. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]
- `TIME-01` is partial because Timeline direct export and carry links were verified, but a background queued current-view export path can fail or broaden after persisted date filters stay strings. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]
- `GOV-02` is partial because direct downloads and gates were verified, but queued export worker parsing is broken for date-bounded filters; the audit also found noncanonical `requirements:` frontmatter in `186-04` and `186-05` summaries. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]
- `A11Y-02` is partial because keyboard/focus proof exists, but the keyboard-reachable queued export action may not complete for normal date-bounded Timeline filters. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]
- `MOTION-01` is partial because `.tl-copy` uses `transition: var(--tl-transition-fast)`, which implies `transition-property: all`, while the current source guard only rejects literal `transition: all`. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] [CITED: MDN transition docs]
- Phase 187 explicitly kept existing routes, data-testids, auth gates, export authorization gates, and capture/query semantics unchanged. [VERIFIED: .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-CONTEXT.md]
- Phase 187 explicitly scoped out broad redesign and new motion patterns; Phase 188 should preserve that constraint. [VERIFIED: .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-CONTEXT.md] [VERIFIED: .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-UI-SPEC.md]

### Project Constraints (from CLAUDE.md)

- Preserve Threadline's three layers: Capture, Semantics, and Exploration/operations. Phase 188 belongs in Exploration/operations, not capture semantics. [VERIFIED: CLAUDE.md]
- Use canonical Threadline terms such as `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, and `Correlation`. [VERIFIED: CLAUDE.md]
- Prefer project verification aliases such as `mix verify.format`, `mix verify.credo`, `mix verify.test`, and `mix ci.all`. [VERIFIED: CLAUDE.md]
- Keep Phoenix/LiveView operator UI private to the example app surface; there is no public Phoenix component API contract to preserve for Phase 188. [VERIFIED: CLAUDE.md]
- Do not introduce Tailwind, shadcn, or a public component styling dependency for this operator surface. [VERIFIED: CLAUDE.md]

### Deferred Or Out-Of-Scope Inputs

- The broad screenshot residual from Phase 187 is already classified as non-blocking and should not become the primary Phase 188 implementation unless the planner intentionally expands scope. [VERIFIED: .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-VERIFICATION.md]
- The broad `mix ci.all` example-app residual from Phase 187 is already classified as unrelated pre-existing work and should not drive this closure phase. [VERIFIED: .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-VERIFICATION.md]
- The v1.38 audit also recommends Nyquist validation catch-up for earlier phases, but Phase 188's title and gap description are specifically export queue and motion validation. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] [VERIFIED: .planning/ROADMAP.md]

## Summary

Phase 188 should be planned as a narrow gap-closure phase with two implementation lanes: queued export replay and motion contract hardening. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] The export gap is in `Threadline.Export.Orchestrator.prepare_filters/2`: it turns persisted `ExportJob.query_params` string keys into atoms with `String.to_atom/1` and does not parse date strings into `DateTime` structs before calling `Threadline.Export.stream_export_rows/2`. [VERIFIED: codebase grep] `Threadline.Query` only applies `from` and `to` filters when the values are `%DateTime{}` structs, so string dates are not enforced by the query layer. [VERIFIED: codebase grep]

The correct planning target is to reuse the existing `Threadline.OperatorSurface.Exports.FilterParams.parse/1` URL-param parser in the worker path, or expose a small shared helper around it, instead of inventing another parser. [VERIFIED: codebase grep] That parser already allowlists accepted keys, parses datetime-local values through `DateTime.from_iso8601/1`, collapses `actor_kind`/`actor_id` into `ActorRef`, and avoids unsafe atom creation. [VERIFIED: codebase grep] Persisted `ExportJob.query_params` should remain the canonical URL-shaped string map because `ExportStatusLive` uses it to render context pairs and rebuild "Reopen source search" links. [VERIFIED: codebase grep]

The motion gap is source-contract coverage, not a need for new animation behavior. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] CSS `transition` shorthand defaults the property list to `all` when no transition property is supplied, and `.tl-copy` currently uses a token-only shorthand that triggers that default. [CITED: MDN transition docs] [VERIFIED: codebase grep] The planner should update `.tl-copy` to declare explicit transition properties and strengthen `style_contract_test.exs` so future token-only shorthand cannot bypass the guard. [VERIFIED: codebase grep] A Phase 188 UI-SPEC is needed because the work touches operator UI CSS/motion behavior and the plan-phase UI gate detects frontend work without a Phase 188 UI-SPEC. [VERIFIED: user prompt] [VERIFIED: codebase grep]

**Primary recommendation:** Plan a small close-gap with red tests first: add queued export replay tests for persisted date-bounded params, replace worker atomization with the existing filter parser, replace `.tl-copy` implicit-all transition with explicit properties, strengthen the motion source contract, repair the `GOV-02` summary metadata if included in scope, then rerun targeted ExUnit and Playwright/source validation. [VERIFIED: codebase grep] [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Persisted queued export filter replay | API / Backend | Database / Storage | `ExportJob.query_params` is stored in governance data and replayed by `Threadline.Export.Orchestrator`; the worker must validate and parse before calling `Threadline.Export` and `Threadline.Query`. [VERIFIED: codebase grep] |
| Timeline "current view" carry and queue affordance | Frontend Server (LiveView) | API / Backend | `TimelineLive` and `ExportStatusLive` render and enqueue the operator action, but the durable correctness belongs to the worker path because jobs can outlive the page. [VERIFIED: codebase grep] |
| Export authorization and feature gates | Frontend Server (LiveView/Controller) | API / Backend | Existing operator export gates are implemented in operator LiveView/controller code and should remain unchanged for Phase 188. [VERIFIED: codebase grep] [VERIFIED: .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-CONTEXT.md] |
| Motion/reduced-motion source contract | Browser / CSS | Test / Validation | The defect is CSS transition semantics plus a source-level test gap; the implementation should change CSS and source/browser validation, not application data flow. [VERIFIED: codebase grep] [CITED: MDN transition docs] |
| v1.38 traceability metadata | Planning docs | Test / Validation | The audit found noncanonical summary frontmatter for `GOV-02`; this is documentation metadata, not runtime behavior. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] |

## Phase Requirements

These requirement IDs are derived from the v1.38 audit because Phase 188 has no dedicated requirement list yet. [VERIFIED: user prompt] [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]

| ID | Description | Research Support |
|----|-------------|------------------|
| `TIME-01` | Timeline export/carry flows must preserve date-bounded current-view context through queued background export. | Fix worker replay of persisted `from`/`to` string params into `%DateTime{}` filters and test inside/outside date rows. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] [VERIFIED: codebase grep] |
| `GOV-02` | Export governance must keep direct and queued exports behind the same safe filter contract and traceability metadata. | Keep existing feature/auth gates, parse job params through the same allowlisted parser, and repair `requirements-completed` metadata where the audit flagged `186-04`/`186-05`. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] [VERIFIED: codebase grep] |
| `A11Y-02` | Keyboard-reachable queued export action must complete for normal date-bounded Timeline filters. | Preserve the existing LiveView action and prove the queue worker can complete the job shape created by the keyboard-accessible button. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] [VERIFIED: codebase grep] |
| `MOTION-01` | Motion governance must prevent unbounded transition properties and preserve reduced-motion validation. | Replace `.tl-copy` token-only transition shorthand and add source or browser proof that computed transition properties are explicit rather than `all`. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] [VERIFIED: codebase grep] [CITED: MDN transition docs] |
| `CLOSE-01` | v1.38 closeout must classify and close residual gaps before archive. | Rerun the milestone audit after the fixes and document any remaining unrelated residuals separately. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] [VERIFIED: .planning/STATE.md] |

## UI-SPEC Need

Phase 188 should get a small UI-SPEC before implementation because the plan will touch operator CSS and possibly operator LiveView validation evidence. [VERIFIED: user prompt] [VERIFIED: codebase grep]

The UI-SPEC should explicitly cover these points: no visual redesign, no new routes, no new data-testids unless tests need a narrow stable hook, no new motion token family, no new animation library, `.tl-copy` keeps the same visual affordance while declaring explicit transition properties, and any browser proof uses existing operator motion validation patterns. [VERIFIED: .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-UI-SPEC.md] [VERIFIED: codebase grep]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir | 1.19.5 | Runtime and test execution for Threadline. | Local project runtime verified by `elixir --version`. [VERIFIED: local command] |
| Mix | 1.19.5 | Build, aliases, and ExUnit runner. | Project aliases include `verify.format`, `verify.credo`, `verify.test`, and `ci.all`. [VERIFIED: local command] |
| Phoenix | 1.8.7 | Operator example app framework. | Installed project dependency verified by `mix deps`. [VERIFIED: local command] |
| Phoenix LiveView | 1.1.30 | Timeline and export status operator UI. | Installed project dependency verified by `mix deps`; relevant files are LiveView modules. [VERIFIED: local command] [VERIFIED: codebase grep] |
| Ecto | 3.13.5 | Query building and persistence. | Installed project dependency verified by `mix deps`; `ExportJob` and `Threadline.Query` use Ecto. [VERIFIED: local command] [VERIFIED: codebase grep] |
| Postgrex | 0.22.0 | PostgreSQL adapter. | Installed project dependency verified by `mix deps`; local PostgreSQL is accepting connections. [VERIFIED: local command] |
| Jason | 1.4.4 | JSON handling for evidence context and map persistence paths. | Installed project dependency verified by `mix deps`; evidence context parser uses `Jason.decode/1`. [VERIFIED: local command] [VERIFIED: codebase grep] |
| NimbleCSV | 1.3.0 | CSV export support. | Installed project dependency verified by `mix deps`; export code owns CSV streaming and formatting. [VERIFIED: local command] [VERIFIED: codebase grep] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| ExUnit | bundled with Elixir 1.19.5 | Unit and integration regression tests. | Use for worker replay, filter parser, LiveView enqueue, export controller, and source contract tests. [VERIFIED: local command] [VERIFIED: codebase grep] |
| Credo | 1.7.18 | Static analysis through project aliases. | Use through `mix verify.credo` when the implementation touches Elixir code. [VERIFIED: local command] |
| `@playwright/test` | installed 1.60.0; latest registry version observed 1.61.1 | Existing browser validation for operator motion and earned flows. | Use only if the Phase 188 UI-SPEC requires computed style proof for `.tl-copy`; do not upgrade in this phase. [VERIFIED: local command] [VERIFIED: npm registry + package-legitimacy] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reusing `FilterParams.parse/1` in the worker | A new `Orchestrator`-local parser | A second parser would duplicate datetime, actor, and allowlist logic and risks diverging from direct exports. [VERIFIED: codebase grep] |
| Keeping persisted `ExportJob.query_params` as canonical string maps | Persist typed `%DateTime{}` values in job params | Typed persistence could break existing "Reopen source search" link rebuilding and stored jobs; parsing at replay handles both new and existing jobs. [VERIFIED: codebase grep] |
| Source contract hardening | Only a browser computed-style check | Source tests are faster and catch the exact `transition` declaration before browser setup; a browser check is still useful if UI-SPEC requires runtime proof. [VERIFIED: codebase grep] |
| Adding a CSS parser package | Existing style source helpers and targeted regex/declaration scanning | No new package is needed for a narrow known declaration pattern; adding a parser would expand dependency risk. [VERIFIED: codebase grep] |

**Installation:**

```bash
# No new package installation is recommended for Phase 188.
```

**Version verification performed:**

```bash
elixir --version
mix --version
mix deps | rg 'phoenix|phoenix_live_view|ecto|ecto_sql|postgrex|jason|nimble_csv|credo'
npm ls @playwright/test --prefix examples/threadline_phoenix/e2e --depth=0
npm view @playwright/test version time.modified repository.url scripts.postinstall --json
node "$HOME/.codex/gsd-core/bin/gsd-tools.cjs" query package-legitimacy check --ecosystem npm @playwright/test
```

All standard stack versions above were verified locally during research. [VERIFIED: local command]

## Package Legitimacy Audit

Phase 188 should not install new external packages. [VERIFIED: codebase grep]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| None (new packages) | - | - | - | - | - | No new installation recommended. [VERIFIED: codebase grep] |
| `@playwright/test` (existing dependency only) | npm | Latest registry metadata modified 2026-06-30 | 40,791,905 weekly downloads reported by legitimacy seam | `github.com/microsoft/playwright` | `SUS` from legitimacy seam because the latest publish was too new | Keep the installed 1.60.0 project version; if a plan installs or upgrades this package, add a human checkpoint first. [VERIFIED: npm registry + package-legitimacy] |

**Packages removed due to `SLOP` verdict:** none. [VERIFIED: package-legitimacy seam]
**Packages flagged as suspicious `SUS`:** `@playwright/test` only if the plan installs or upgrades it; existing project usage does not require installation. [VERIFIED: package-legitimacy seam] [VERIFIED: local command]

## Architecture Patterns

### System Architecture Diagram

```text
Timeline filter form / URL params
  -> FilterParams.filters_raw_from_params/1
  -> FilterParams.parse/1 for current page validation
  -> ExportStatusLive.canonical_query_params/1
  -> ExportJob.query_params persisted as canonical string map
  -> ExportQueue adapter enqueues job id
  -> Export.Orchestrator.run/2 loads ExportJob
  -> prepare_filters/2 must parse persisted params through allowlisted parser
  -> Threadline.Export.stream_export_rows/2
  -> Threadline.Query.timeline_query/1 applies %DateTime{} from/to filters
  -> Storage adapter writes completed CSV path
  -> ExportStatusLive shows completion/download/reopen source search
```

This data flow is the audited broken path for date-bounded queued exports. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] [VERIFIED: codebase grep]

### Recommended Project Structure

```text
lib/threadline/
  export/orchestrator.ex                         # Worker replay fix for persisted query_params
  operator_surface/exports/filter_params.ex      # Existing canonical URL-param parser to reuse
  operator_surface/live/export_status_live.ex    # Carry-context queue UI and persisted query shape
  operator_surface/live/timeline_live.ex         # Current-view queue action source
  operator_surface/style.ex                      # .tl-copy transition fix
  query.ex                                       # Date filters apply only for %DateTime{} values

test/threadline/
  export/orchestrator_test.exs                   # Add queued replay regression tests
  operator_surface/live/export_status_live_test.exs
                                                 # Preserve carry-context queue behavior
  operator_surface/exports/filter_params_test.exs
                                                 # Parser contract, if helper changes
  operator_surface/style_contract_test.exs       # Add implicit transition-all guard
  operator_surface/controllers/export_controller_test.exs
                                                 # Direct export parity guard; likely no change

examples/threadline_phoenix/e2e/tests/
  operator-motion.spec.ts                        # Optional computed-style proof for .tl-copy
```

These files were confirmed as the relevant implementation and validation targets. [VERIFIED: codebase grep]

### Pattern 1: Parse Persisted Export Params At Worker Replay

**What:** `Export.Orchestrator.prepare_filters/2` should accept persisted URL-shaped maps, parse them through the existing allowlisted filter parser, then add `:repo`. [VERIFIED: codebase grep]

**When to use:** Every queued export job that stores operator Timeline params in `ExportJob.query_params`. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: lib/threadline/operator_surface/exports/filter_params.ex and lib/threadline/export/orchestrator.ex
alias Threadline.OperatorSurface.Exports.FilterParams

defp prepare_filters(query_params, repo) do
  case FilterParams.parse(query_params || %{}) do
    {:ok, filters} ->
      Keyword.put_new(filters, :repo, repo)

    {:error, message} ->
      raise ArgumentError, message
  end
end
```

The planner should decide whether to raise and let the existing rescue path mark the job failed, or return `{:error, message}` and mark failure explicitly; either choice should fail closed rather than silently exporting a broader dataset. [VERIFIED: codebase grep] [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]

### Pattern 2: Keep Persisted Job Params URL-Shaped

**What:** Keep `ExportJob.query_params` as the canonical string map produced by `FilterParams.canonical_query/1` and `URI.decode_query/1`; parse only at execution time. [VERIFIED: codebase grep]

**When to use:** Export Status queueing of carried Timeline context and any existing stored pending jobs. [VERIFIED: codebase grep]

**Reason:** `ExportStatusLive.timeline_search_path/2` stringifies `query_params` to rebuild the Timeline URL, and existing tests assert canonical string values for carried `from`/`to` filters. [VERIFIED: codebase grep]

### Pattern 3: Test The Worker, Not Just The UI

**What:** Add an `orchestrator_test.exs` regression that inserts an `ExportJob` with string `query_params` such as `%{"from" => "2026-05-01T00:00", "to" => "2026-05-06T23:59"}`, runs the orchestrator, and verifies the completed CSV honors the date window. [VERIFIED: codebase grep]

**When to use:** Before changing `prepare_filters/2`, so the test fails red against the current string-date replay bug. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: test/threadline/export/orchestrator_test.exs pattern plus audit gap
job =
  insert_export_job!(%{
    query_params: %{"from" => "2026-05-01T00:00", "to" => "2026-05-06T23:59"}
  })

assert :ok = Orchestrator.run(job.id, repo: Repo)
completed = Repo.get!(ExportJob, job.id)
assert completed.status == "completed"
assert csv_contains_only_rows_inside_window?(completed.file_path)
```

The helper names in this example are illustrative; the actual test should reuse the repo's existing factories/insert helpers in `orchestrator_test.exs`. [VERIFIED: codebase grep]

### Pattern 4: Make Transition Properties Explicit

**What:** Replace `.tl-copy`'s token-only transition shorthand with explicit properties. [VERIFIED: codebase grep] [CITED: MDN transition docs]

**When to use:** Any element whose transition should be limited to governed visual properties. [VERIFIED: .planning/milestones/v1.31-phases/141-motion-micro-animation/141-MOTION-INVENTORY.md]

**Example:**

```css
/* Source target: lib/threadline/operator_surface/style.ex */
.tl-copy {
  transition:
    color var(--tl-transition-fast),
    background-color var(--tl-transition-fast),
    border-color var(--tl-transition-fast),
    box-shadow var(--tl-transition-fast);
}
```

The Phase 141 motion inventory lists `.tl-copy` transition properties as color, border-color, background-color, and box-shadow, so this explicit property list matches the existing governed intent. [VERIFIED: .planning/milestones/v1.31-phases/141-motion-micro-animation/141-MOTION-INVENTORY.md]

### Pattern 5: Strengthen Source Contract Against Implicit `all`

**What:** Extend `style_contract_test.exs` beyond `transition:\s*all` so it also rejects declarations like `transition: var(--tl-transition-fast)` that omit a property and therefore compute to `all`. [VERIFIED: codebase grep] [CITED: MDN transition docs]

**When to use:** In the existing "rejects ad-hoc motion" test or a new focused test under the Phase 141 motion contract block. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source target: test/threadline/operator_surface/style_contract_test.exs
for declaration <- transition_declarations(src) do
  refute Regex.match?(~r/^\s*transition\s*:\s*var\(--tl-transition-fast\)\s*;/, declaration),
         "transition shorthand without an explicit property computes to all: #{declaration}"
end
```

If the implementation adds a helper that extracts full multi-line declarations, it should keep the helper local to `style_contract_test.exs` unless another test already needs it. [VERIFIED: codebase grep]

### Pattern 6: Optional Browser Proof For Computed Motion

**What:** Add a narrow Playwright assertion for `.tl-copy` only if the UI-SPEC requires runtime proof that computed `transitionProperty` is not `all`. [VERIFIED: user prompt] [CITED: Playwright page docs]

**When to use:** If source-contract proof is considered insufficient for `MOTION-01` closeout evidence. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]

**Example:**

```typescript
// Source target: examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts
const transition = await page.locator('.tl-copy').first().evaluate((node) => {
  const style = window.getComputedStyle(node);
  return {
    property: style.transitionProperty,
    duration: style.transitionDuration
  };
});
expect(transition.property).not.toBe('all');
```

Playwright supports `page.emulateMedia({ reducedMotion: 'reduce' })` and page evaluation for computed style checks. [CITED: Playwright page docs]

### Anti-Patterns to Avoid

- **Fix only the LiveView queue button:** Existing or future persisted jobs still replay through `Export.Orchestrator`, so the worker path must own durable parsing. [VERIFIED: codebase grep]
- **Keep `String.to_atom/1` for persisted params:** Arbitrary persisted or user-influenced keys can mint atoms, while the existing parser uses a fixed key allowlist. [VERIFIED: codebase grep]
- **Allow invalid persisted filters to fall back to broad exports:** A date parse failure should fail the job, not export unbounded rows. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]
- **Change the motion token globally without auditing all consumers:** `--tl-transition-fast` currently represents duration/easing and is used inside property-specific shorthands elsewhere. [VERIFIED: codebase grep]
- **Add a new animation or CSS dependency:** The gap is an existing declaration and test guard, not missing animation capability. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| URL-shaped Timeline param parsing | A second parser in `Export.Orchestrator` | `Threadline.OperatorSurface.Exports.FilterParams.parse/1` or a shared wrapper around it | Existing parser already handles allowlisted keys, datetimes, actor refs, canonical blanks, and atom safety. [VERIFIED: codebase grep] |
| DateTime parsing | Manual string slicing in the worker | Existing `FilterParams.parse_datetime_local/1` behavior and `DateTime.from_iso8601/1` | Elixir `DateTime.from_iso8601/1` parses ISO 8601 datetimes with offsets and returns `{:ok, datetime, offset}` or `{:error, reason}`. [CITED: Elixir DateTime docs] [VERIFIED: codebase grep] |
| Atom conversion | `String.to_atom/1` on job params | Fixed allowlist map from string keys to known atoms | The existing parser avoids fresh atoms from arbitrary input. [VERIFIED: codebase grep] |
| Export streaming | A custom job CSV writer | `Threadline.Export.stream_export_rows/2`, `csv_header/0`, and `format_changes_iodata/2` | The orchestrator already streams rows in chunks and writes through the storage adapter. [VERIFIED: codebase grep] |
| CSS motion governance | New animation library or global CSS parser | Existing `style_contract_test.exs` plus explicit declarations | The failure is a single implicit shorthand and a missing source guard. [VERIFIED: codebase grep] [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] |
| Browser reduced-motion validation | A new browser runner | Existing Playwright operator specs | The project already has `operator-motion.spec.ts` and Playwright installed for example app browser checks. [VERIFIED: codebase grep] [VERIFIED: local command] |

**Key insight:** The safest Phase 188 plan is to unify the queued worker with the already-tested direct export parser, then harden the existing source and browser validation lanes; custom parsing or new motion tooling would increase the chance of another parity gap. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Worker And Direct Export Drift

**What goes wrong:** Direct exports keep passing because `ExportController` uses `FilterParams.parse/1`, while queued exports remain broken because the worker uses `String.to_atom/1` without datetime parsing. [VERIFIED: codebase grep]

**Why it happens:** The direct HTTP path and queued job replay path are separate modules. [VERIFIED: codebase grep]

**How to avoid:** Make the worker call the same parser or shared wrapper as the direct path. [VERIFIED: codebase grep]

**Warning signs:** Tests only cover `ExportController` or LiveView enqueue creation, not `Orchestrator.run/2` with persisted string dates. [VERIFIED: codebase grep]

### Pitfall 2: Silent Broad Exports From String Dates

**What goes wrong:** `from` and `to` survive as strings, and `Threadline.Query` only applies date filters for `%DateTime{}` values. [VERIFIED: codebase grep]

**Why it happens:** `validate_timeline_filters!/1` validates allowed keys and correlation id shape, but does not reject string date values. [VERIFIED: codebase grep]

**How to avoid:** Parse dates before query execution and add a regression that fails if outside-window rows appear in the CSV. [VERIFIED: codebase grep]

**Warning signs:** A queued export completes successfully but contains more rows than the visible Timeline date window. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]

### Pitfall 3: Unsafe Atom Creation

**What goes wrong:** `String.to_atom/1` can create atoms from arbitrary keys. [VERIFIED: codebase grep]

**Why it happens:** `prepare_filters/2` currently atomizes every `query_params` key. [VERIFIED: codebase grep]

**How to avoid:** Use the parser's fixed string-key allowlist and never call `String.to_atom/1` on job data. [VERIFIED: codebase grep]

**Warning signs:** Tests accept unknown `query_params` keys until query validation raises, or new atoms are created before validation. [VERIFIED: codebase grep]

### Pitfall 4: Breaking Reopen Source Search

**What goes wrong:** Converting persisted `query_params` to typed values can make `ExportStatusLive.timeline_search_path/2` produce unexpected URLs. [VERIFIED: codebase grep]

**Why it happens:** The UI rebuilds Timeline links by stringifying stored job params. [VERIFIED: codebase grep]

**How to avoid:** Keep persistence URL-shaped and parse at worker replay. [VERIFIED: codebase grep]

**Warning signs:** Existing `export_status_live_test.exs` expectations for `"from" => "2026-05-01T00:00"` and `"to" => "2026-05-06T23:59"` require broad rewriting. [VERIFIED: codebase grep]

### Pitfall 5: Missing Implicit Transition-All

**What goes wrong:** A test rejects literal `transition: all`, but `transition: var(--tl-transition-fast)` still computes to `transition-property: all`. [VERIFIED: codebase grep] [CITED: MDN transition docs]

**Why it happens:** CSS `transition` shorthand defaults `transition-property` to `all` if the property is omitted. [CITED: MDN transition docs]

**How to avoid:** Use explicit properties in `.tl-copy` and add a contract that rejects token-only transition shorthand. [VERIFIED: codebase grep] [CITED: MDN transition docs]

**Warning signs:** Source grep shows a `transition:` declaration whose first token is only `var(--tl-transition-fast)` or a duration/easing token. [VERIFIED: codebase grep]

### Pitfall 6: Overscoping Into Phase 187 Residuals

**What goes wrong:** The plan spends time on pre-existing broad screenshot or CI residuals instead of the audit's export queue and motion contract gaps. [VERIFIED: .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-VERIFICATION.md] [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]

**Why it happens:** Phase 187 verification intentionally classified several residuals as non-blocking. [VERIFIED: .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-VERIFICATION.md]

**How to avoid:** Treat those residuals as context; only rerun them if needed for final v1.38 audit evidence. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]

**Warning signs:** Planned tasks mention screenshot harness repair before `orchestrator_test.exs` and `style_contract_test.exs` gaps. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]

## Code Examples

Verified patterns from existing project code and official documentation follow. [VERIFIED: codebase grep]

### Existing Parser Contract To Reuse

```elixir
# Source: lib/threadline/operator_surface/exports/filter_params.ex
@filter_key_atoms %{
  "from" => :from,
  "to" => :to,
  "table_schema" => :table_schema,
  "table" => :table,
  "actor_kind" => :actor_kind,
  "actor_id" => :actor_id,
  "correlation_id" => :correlation_id
}

def parse(params) when is_map(params) do
  with normalized <- normalize_params(params),
       {:ok, with_datetimes} <- parse_datetimes(normalized),
       {:ok, with_actor_ref} <- collapse_actor_ref(with_datetimes) do
    {:ok, with_actor_ref}
  end
end
```

This is the parser the worker should reuse or wrap. [VERIFIED: codebase grep]

### Existing Broken Worker Prep

```elixir
# Source: lib/threadline/export/orchestrator.ex
defp prepare_filters(query_params, repo) do
  base =
    Enum.map(query_params || %{}, fn {k, v} ->
      {String.to_atom(k), v}
    end)

  Keyword.put_new(base, :repo, repo)
end
```

This function is the primary backend implementation target. [VERIFIED: codebase grep] [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]

### Query Date Filter Behavior

```elixir
# Source: lib/threadline/query.ex
defp filter_by_from(query, %DateTime{} = from) do
  where(query, [ac], ac.captured_at >= ^from)
end

defp filter_by_to(query, %DateTime{} = to) do
  where(query, [ac], ac.captured_at <= ^to)
end
```

String `from` and `to` values do not match these clauses, which is why worker-side DateTime parsing is required. [VERIFIED: codebase grep]

### Existing Motion Contract Gap

```css
/* Source: lib/threadline/operator_surface/style.ex */
:root {
  --tl-transition-fast: var(--tl-motion-fast) var(--tl-ease-standard);
}

.tl-copy {
  transition: var(--tl-transition-fast);
}
```

The token contains duration/easing, not a property, so this shorthand relies on CSS's default transition property of `all`. [VERIFIED: codebase grep] [CITED: MDN transition docs]

## State of the Art

| Old Approach | Current Approach | When Changed / Confirmed | Impact |
|--------------|------------------|--------------------------|--------|
| Worker converts string keys with `String.to_atom/1` and passes values unchanged. | Worker should use the allowlisted URL-param parser already shared by LiveView/direct export paths. | Confirmed during Phase 188 research on 2026-06-30. [VERIFIED: codebase grep] | Prevents string-date replay bugs and unsafe atom creation. [VERIFIED: codebase grep] |
| Source guard rejects only literal `transition: all`. | Source guard should reject implicit-all shorthand and `.tl-copy` should declare explicit properties. | Confirmed by v1.38 audit and MDN docs. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] [CITED: MDN transition docs] | Closes `MOTION-01` without adding new motion behavior. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] |
| Browser proof samples existing operator motion surfaces. | Add `.tl-copy` computed-style proof only if UI-SPEC requires runtime evidence. | Playwright docs confirm reduced-motion emulation and page evaluation APIs. [CITED: Playwright page docs] | Keeps validation targeted and avoids broad screenshot residuals. [VERIFIED: .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-VERIFICATION.md] |

**Deprecated/outdated for this phase:**

- `String.to_atom/1` on persisted or user-influenced params is outdated for this path because the project already has a safer allowlist parser. [VERIFIED: codebase grep]
- Token-only `transition` shorthand is outdated for governed operator controls because it computes to all properties. [VERIFIED: codebase grep] [CITED: MDN transition docs]
- Adding new motion libraries is out of scope because the project already has source and Playwright validation lanes. [VERIFIED: codebase grep] [VERIFIED: .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| - | No unverified assumptions were used as planning facts. | All sections | - |

All claims in this research are tagged with local verification, official documentation citation, user prompt provenance, or package registry/provenance results. [VERIFIED: codebase grep]

## Open Questions (RESOLVED)

1. **Should invalid persisted queued export params fail the job or be ignored?**
   - What we know: The existing orchestrator marks rescued exceptions as failed jobs, and broad exports are the audit risk. [VERIFIED: codebase grep] [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]
   - What's unclear: Whether the desired user-facing error should be `ArgumentError` text from the parser or a normalized export-specific error message. [VERIFIED: codebase grep]
   - Recommendation: Fail closed with a clear parser-derived message and add an assertion that invalid persisted datetime params mark the job failed. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]
   - RESOLVED: Invalid persisted queued export params fail closed with parser-derived detail per D-188-09 and D-188-10. `188-01-PLAN.md` Task 1 requires the RED invalid persisted datetime regression and existing failed-row treatment proof; `188-01-PLAN.md` Task 2 requires the worker to record parser-derived detail in `ExportJob.error_message` and render it through the existing `Export failed.` row.

2. **Should Phase 188 repair `186-04`/`186-05` summary frontmatter?**
   - What we know: The audit flags noncanonical `requirements:` instead of `requirements-completed:` for `GOV-02`. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]
   - What's unclear: Whether the planner should include this small doc metadata repair in Phase 188 or leave it to a separate validation catch-up phase. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]
   - Recommendation: Include the frontmatter repair if it is confined to those summaries; do not bundle broader Nyquist validation catch-up unless explicitly requested. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]
   - RESOLVED: Phase 188 owns the targeted `186-04`/`186-05` GOV-02 metadata repair per D-188-20. `188-03-PLAN.md` Task 1 repairs only the summary frontmatter from `requirements` to `requirements-completed` while preserving the IDs and body evidence; `188-03-PLAN.md` Task 2 records the repair in closeout evidence.

3. **Is source-contract motion proof enough, or is browser computed-style proof required?**
   - What we know: The audit gap is a source declaration and the existing source guard misses implicit `all`. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] [VERIFIED: codebase grep]
   - What's unclear: Whether final acceptance wants a Playwright computed-style assertion for `.tl-copy`. [VERIFIED: user prompt]
   - Recommendation: Plan source-contract proof as required and make a narrow Playwright `.tl-copy` computed-style assertion optional under the Phase 188 UI-SPEC. [VERIFIED: codebase grep] [CITED: Playwright page docs]
   - RESOLVED: Source-contract proof is required, while browser proof remains optional and narrow per D-188-16, D-188-18, and D-188-19. `188-02-PLAN.md` Task 1 requires `style_contract_test.exs` proof for explicit `.tl-copy` transition properties and implicit-all rejection; `188-02-PLAN.md` Task 2 changes only `.tl-copy` CSS and adds browser computed-style proof only if source proof cannot validate the property list; `188-03-PLAN.md` Task 2 records `mix verify.example_browser` only if browser proof was actually added or changed.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix/ExUnit implementation and tests | yes | 1.19.5 | None needed. [VERIFIED: local command] |
| Mix | Project aliases and test runner | yes | 1.19.5 | None needed. [VERIFIED: local command] |
| PostgreSQL / `pg_isready` | Ecto integration tests | yes | `psql` 14.17; local server accepting connections | None needed for targeted tests. [VERIFIED: local command] |
| Node.js | Playwright browser tests if used | yes | v22.14.0 | Skip browser proof if source proof is accepted. [VERIFIED: local command] |
| npm | Existing example E2E dependency management | yes | 11.1.0 | No install recommended. [VERIFIED: local command] |
| `@playwright/test` | Optional `.tl-copy` computed-style proof | yes | 1.60.0 installed in `examples/threadline_phoenix/e2e` | Use source contract only if browser proof is out of scope. [VERIFIED: local command] |

**Missing dependencies with no fallback:** none found for the recommended targeted work. [VERIFIED: local command]

**Missing dependencies with fallback:** none found; Playwright is available but optional for this phase if the UI-SPEC limits evidence to source contracts. [VERIFIED: local command] [VERIFIED: user prompt]

## Validation Architecture

`workflow.nyquist_validation` is enabled in `.planning/config.json`, and `security_enforcement` is not explicitly disabled, so this research includes validation and security sections. [VERIFIED: .planning/config.json]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix 1.19.5; optional Playwright Test 1.60.0 for browser proof. [VERIFIED: local command] |
| Config file | Mix project aliases in `mix.exs`; Playwright config under `examples/threadline_phoenix/e2e`. [VERIFIED: local command] [VERIFIED: codebase grep] |
| Quick run command | `mix test test/threadline/export/orchestrator_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/operator_surface/style_contract_test.exs` [VERIFIED: local command] |
| Full suite command | `mix verify.test` for project tests; add `mix verify.example_browser` only if the UI-SPEC requires browser proof. [VERIFIED: CLAUDE.md] [VERIFIED: local command] |

### Baseline Validation Performed During Research

| Command | Result | Purpose |
|---------|--------|---------|
| `mix test test/threadline/export/orchestrator_test.exs test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/operator_surface/style_contract_test.exs` | 88 tests, 0 failures | Confirms current targeted suites are green but missing the Phase 188 regressions. [VERIFIED: local command] |
| `mix test test/threadline/operator_surface/controllers/export_controller_test.exs test/threadline/export_test.exs` | 46 tests, 0 failures | Confirms direct export suites are green and are not the failing gap. [VERIFIED: local command] |

### Phase Requirements To Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| `TIME-01` | Queued export worker honors persisted date-bounded Timeline filters. | Integration/unit | `mix test test/threadline/export/orchestrator_test.exs` | yes; add regression. [VERIFIED: codebase grep] |
| `GOV-02` | Queued export worker uses safe allowlisted filter parsing and does not mint atoms from job params. | Unit/integration | `mix test test/threadline/export/orchestrator_test.exs test/threadline/operator_surface/exports/filter_params_test.exs` | yes; add worker regression. [VERIFIED: codebase grep] |
| `GOV-02` | Summary metadata uses canonical `requirements-completed` for flagged Phase 186 summaries if included. | Doc validation/manual | `rg -n "requirements:" .planning/phases/186* .planning/summaries*` or project doc-contract alias if available | files need planner lookup. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] |
| `A11Y-02` | Keyboard-reachable queued export action creates a job shape that completes after worker replay. | LiveView + worker integration | `mix test test/threadline/operator_surface/live/export_status_live_test.exs test/threadline/export/orchestrator_test.exs` | yes; add or adjust regression. [VERIFIED: codebase grep] |
| `MOTION-01` | `.tl-copy` does not use implicit `transition-property: all`. | Source contract; optional browser computed style | `mix test test/threadline/operator_surface/style_contract_test.exs`; optional `mix verify.example_browser -- operator-motion.spec.ts` if supported by alias args | source test exists; optional browser spec exists. [VERIFIED: codebase grep] |
| `CLOSE-01` | v1.38 audit rerun reports no export queue or motion validation gaps. | Milestone audit/manual | Project GSD audit command used by orchestrator | audit artifact exists. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] |

### Sampling Rate

- **Per task commit:** Run the quick ExUnit command for files touched by that task. [VERIFIED: CLAUDE.md] [VERIFIED: local command]
- **Per wave merge:** Run `mix verify.test`; add `mix verify.example_browser` only if browser proof is part of the UI-SPEC. [VERIFIED: CLAUDE.md] [VERIFIED: codebase grep]
- **Phase gate:** Re-run the v1.38 milestone audit after targeted fixes so Phase 188 can prove the inserted gap-closure phase actually closed the audit findings. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]

### Wave 0 Gaps

- [ ] `test/threadline/export/orchestrator_test.exs` needs a red regression for persisted string `from`/`to` query params that verifies completed CSV rows honor the date window. [VERIFIED: codebase grep] [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]
- [ ] `test/threadline/export/orchestrator_test.exs` should add a fail-closed regression for invalid persisted datetime params if the implementation raises or returns parser errors. [VERIFIED: codebase grep]
- [ ] `test/threadline/operator_surface/live/export_status_live_test.exs` should continue proving carried Timeline context persists canonical string params; update only if the implementation intentionally changes persistence shape. [VERIFIED: codebase grep]
- [ ] `test/threadline/operator_surface/style_contract_test.exs` needs a guard for implicit transition-all shorthand such as `transition: var(--tl-transition-fast)`. [VERIFIED: codebase grep] [CITED: MDN transition docs]
- [ ] `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` may need a narrow `.tl-copy` computed `transitionProperty` check if the Phase 188 UI-SPEC requires runtime browser proof. [VERIFIED: codebase grep] [CITED: Playwright page docs]
- [ ] Planning/doc summary metadata needs a targeted check or repair for the audit's `GOV-02` frontmatter finding if Phase 188 owns that cleanup. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no direct new auth behavior | Preserve existing operator auth/export gates; do not change auth in Phase 188. [VERIFIED: .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-CONTEXT.md] [VERIFIED: codebase grep] |
| V3 Session Management | no direct new session behavior | No session management changes are required. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] |
| V4 Access Control | yes | Preserve export authorization and feature gates already enforced by operator LiveView/controller paths. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Parse persisted `ExportJob.query_params` with an allowlisted parser before query execution. [VERIFIED: codebase grep] |
| V6 Cryptography | no | No cryptographic changes are required. [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] |

### Known Threat Patterns For This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Atom table exhaustion from persisted/user-influenced keys | Denial of Service | Replace `String.to_atom/1` with fixed allowlist parsing. [VERIFIED: codebase grep] |
| Broad data export from ignored string date filters | Information Disclosure | Parse date params into `%DateTime{}` before calling `Threadline.Query`; fail closed on parse error. [VERIFIED: codebase grep] [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md] |
| Forged queue event bypassing export gate | Elevation of Privilege | Preserve existing LiveView export-enabled checks and tests; do not move authorization into browser-only logic. [VERIFIED: codebase grep] |
| Tampered stored job params | Tampering | Validate persisted params at worker execution, not only when the UI creates the job. [VERIFIED: codebase grep] |
| Motion contract drift through shorthand CSS | Reliability / Governance | Strengthen source tests and optionally browser computed-style proof for `.tl-copy`. [VERIFIED: codebase grep] [CITED: MDN transition docs] |

## Sources

### Primary (HIGH confidence)

- `.planning/v1.38-MILESTONE-AUDIT.md` - exact Phase 188 gap classification, integration gaps, flow gaps, and frontmatter finding. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md` - v1.38 requirement IDs and requirement status context. [VERIFIED: codebase grep]
- `.planning/STATE.md` - current phase state and prior phase completion context. [VERIFIED: codebase grep]
- `.planning/ROADMAP.md` - Phase 188 roadmap entry and dependency on Phase 187. [VERIFIED: codebase grep]
- `.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-CONTEXT.md` - locked dependency constraints. [VERIFIED: codebase grep]
- `.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-RESEARCH.md` - dependency research and validation framing. [VERIFIED: codebase grep]
- `.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-UI-SPEC.md` - dependency UI/motion contract. [VERIFIED: codebase grep]
- `.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-VERIFICATION.md` - dependency verification and residual classifications. [VERIFIED: codebase grep]
- `CLAUDE.md` - project constraints and verification aliases. [VERIFIED: codebase grep]
- `lib/threadline/export/orchestrator.ex` - queued export worker implementation. [VERIFIED: codebase grep]
- `lib/threadline/operator_surface/exports/filter_params.ex` - canonical URL-param parser. [VERIFIED: codebase grep]
- `lib/threadline/operator_surface/live/export_status_live.ex` - carry-context queue UI and persisted param shape. [VERIFIED: codebase grep]
- `lib/threadline/operator_surface/live/timeline_live.ex` - current-view queue action. [VERIFIED: codebase grep]
- `lib/threadline/query.ex` - allowed timeline filters and date filter clauses. [VERIFIED: codebase grep]
- `lib/threadline/operator_surface/style.ex` and `test/threadline/operator_surface/style_contract_test.exs` - motion defect and source contract gap. [VERIFIED: codebase grep]
- `test/threadline/export/orchestrator_test.exs`, `test/threadline/operator_surface/live/export_status_live_test.exs`, `test/threadline/operator_surface/exports/filter_params_test.exs`, `test/threadline/operator_surface/controllers/export_controller_test.exs`, and `test/threadline/export_test.exs` - existing validation coverage and gaps. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- MDN Web Docs, CSS `transition` reference - confirms omitted transition property defaults to `all` and initial `transition-property` is `all`. [CITED: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/transition]
- Elixir HexDocs, `DateTime.from_iso8601/2` reference - confirms ISO 8601 parsing contract and offset requirement. [CITED: https://elixir.hexdocs.pm/DateTime.html#from_iso8601/2]
- Playwright docs, `page.emulateMedia` and `page.evaluate` - confirms reduced-motion emulation and computed-style evaluation support. [CITED: https://playwright.dev/docs/api/class-page]
- npm registry and GSD package-legitimacy seam for `@playwright/test` - confirms existing package status and latest-version risk signal. [VERIFIED: npm registry + package-legitimacy]

### Tertiary (LOW confidence)

- None. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - versions were verified with local runtime, Mix dependencies, npm registry, and package-legitimacy commands. [VERIFIED: local command] [VERIFIED: npm registry + package-legitimacy]
- Architecture: HIGH - relevant modules and tests were inspected directly, and the v1.38 audit pinpoints the same paths. [VERIFIED: codebase grep] [VERIFIED: .planning/v1.38-MILESTONE-AUDIT.md]
- Pitfalls: HIGH for codebase pitfalls and MEDIUM for CSS/Playwright external semantics because those rely on official docs fetched during research. [VERIFIED: codebase grep] [CITED: MDN transition docs] [CITED: Playwright page docs]
- Package recommendations: HIGH for "no new package install"; MEDIUM for optional Playwright evidence because the installed version is verified but the latest registry package was flagged `SUS` due to recency. [VERIFIED: local command] [VERIFIED: package-legitimacy seam]

**Research date:** 2026-06-30
**Valid until:** 2026-07-30 for codebase findings; 2026-07-07 for package/browser-tooling version details.
