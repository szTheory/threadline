# Phase 201: Rendered Output - Pattern Map

**Mapped:** 2026-09-13
**Files analyzed:** 21 new/modified files
**Analogs found:** 20 / 21

## File Classification

| New/Modified File | Role | Data Flow | Closest Tracked Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/operator_surface/live/start_live.ex` | component | request-response | `lib/threadline/operator_surface/live/start_live.ex` | exact, in-place |
| `lib/threadline/operator_surface/live/export_status_live.ex` | component | request-response | `lib/threadline/operator_surface/live/start_live.ex` | role-match |
| `lib/threadline/operator_surface/live/evidence_live.ex` | component | request-response | `lib/threadline/operator_surface/live/start_live.ex` | role-match |
| `lib/threadline/operator_surface/live/row_history_live.ex` | component | request-response | `lib/threadline/operator_surface/live/start_live.ex` | role-match |
| `lib/threadline/operator_surface/live/timeline_live.ex` | component | request-response | `lib/threadline/operator_surface/live/start_live.ex` | role-match |
| `test/threadline/operator_surface/live/start_live_test.exs` | test | request-response | `test/threadline/operator_surface/live/start_live_test.exs` | exact, in-place |
| `test/threadline/operator_surface/live/export_status_live_test.exs` | test | request-response | `test/threadline/operator_surface/live/start_live_test.exs` | role-match |
| `test/threadline/operator_surface/live/evidence_live_test.exs` | test | request-response | `test/threadline/operator_surface/live/start_live_test.exs` | role-match |
| `test/threadline/operator_surface/live/row_history_live_test.exs` | test | request-response | `test/threadline/operator_surface/live/start_live_test.exs` | role-match |
| `test/threadline/operator_surface/live/timeline_live_test.exs` | test | request-response | `test/threadline/operator_surface/live/start_live_test.exs` | role-match |
| `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | test | request-response | same file | exact, in-place |
| `examples/threadline_phoenix/e2e/tests/operator-home-nav-mobile.spec.ts` | test | request-response | `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | role-match |
| `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts` | test | request-response | `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | role-match |
| `examples/threadline_phoenix/e2e/tests/operator-shell-home.spec.ts` (rename) | test | request-response | `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | role-match |
| `test/threadline/operator_surface/rendered_output_contract_test.exs` | test | batch/transform | `test/threadline/removed_artifact_contract_test.exs` | role + flow match |
| `test/threadline/operator_surface/rendered_structure_support.ex` (optional) | utility | transform | `test/threadline/removed_artifact_contract_test.exs` | partial; keep private unless reused |
| `test/threadline/ci_workflow_parity_contract_test.exs` (rename) | test | file-I/O | `test/threadline/public_surface_contract_test.exs` | role-match |
| `test/threadline/critic_iteration_runbook_doc_contract_test.exs` (rename) | test | file-I/O | `test/threadline/public_surface_contract_test.exs` | role-match |
| `mix.exs` | config | batch | `mix.exs` | exact, in-place |
| `examples/threadline_phoenix/e2e/playwright.config.ts` | config | batch | same file | exact, in-place |
| `.planning/audits/201-rendered-output-evidence.md` | config/evidence | file-I/O | none | no close code analog |

The new durable filenames are the research recommendations. Preserve history with `git mv`; the planner may choose an equally durable name, but must update the same explicit consumers.

## Pattern Assignments

### Five affected LiveViews (component, request-response)

**Files:** `start_live.ex`, `export_status_live.ex`, `evidence_live.ex`, `row_history_live.ex`, and `timeline_live.ex` under `lib/threadline/operator_surface/live/`.

**Analog:** `lib/threadline/operator_surface/live/start_live.ex`

**Module/import pattern** (lines 1-19):

```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.StartLive do
    @moduledoc false
    use Phoenix.LiveView
    import Ecto.Query

    alias Threadline.OperatorSurface.Exports.FilterParams
    alias Threadline.OperatorSurface.UI
  end
end
```

Do not introduce imports, dependencies, components, or authorization changes for this deletion.

**Core markup pattern** (lines 222-257):

```heex
<section class="tl-home__earned-flow" aria-label="Go straight to an audited record">
  <div class="tl-home__earned-panel">
    <form id="tl-record-lookup" class="tl-home__earned-form" phx-submit="open-row-history">
      <UI.field name="record_lookup[table]" label="Table" />
      <UI.field name="record_lookup[record_id]" label="Record id" />
      <button class="tl-button tl-button--secondary" type="submit">Open row history</button>
    </form>
  </div>
</section>
```

Copy the shape-preservation rule, not a rewritten template: delete only `data-earned-flow`, `data-persona`, and `data-jtbd`. Retain tags, classes, IDs, attributes unrelated to the taxonomy, child order, text, and nesting exactly. Existing semantic selectors (`#tl-record-lookup`, `#tl-correlation-lookup`, export-context test IDs, link names, destinations, and `#tl-main`) become the test hooks.

**Validation/error pattern** (lines 62-115): handlers trim inputs, assign existing inline errors, and `push_navigate/2` only on valid input. This behavior remains untouched.

---

### Five LiveView tests (test, request-response)

**Analog:** `test/threadline/operator_surface/live/start_live_test.exs`

**Imports/setup pattern** (lines 194-204, 236-253):

```elixir
defmodule Threadline.OperatorSurface.Live.StartLiveTest do
  use Threadline.DataCase, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint Threadline.OperatorSurface.StartLiveTest.Endpoint
end
```

Use the existing mounted endpoint and auth/session setup. Do not add a special rendering harness when the current test already mounts the real route.

**Behavior-first form pattern** (lines 474-483):

```elixir
{:ok, view, _html} = live(conn, "/audit")

view
|> form("#tl-record-lookup", %{
  "record_lookup" => %{"table" => "ticket_replies", "record_id" => " reply-123 "}
})
|> render_submit()

assert_redirect(view, "/audit/rows/ticket_replies/reply-123")
```

**Semantic element pattern** (lines 378-389):

```elixir
assert has_element?(view, ~s|a[href="/audit/timeline?table=posts"]|, "Recent deletes")
```

Replace raw taxonomy substring assertions with `has_element?/3`, `element/2`, `form/2`, `render_submit/1`, redirect/destination assertions, and visible action text. Preserve existing assertions that arbitrary actor/row content renders; the new static-copy guard must not censor host data.

---

### Four Playwright specs, including durable shell rename (test, request-response)

**Analog:** `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts`

**Imports and login pattern** (lines 1-15):

```typescript
import { expect, Page, test } from "@playwright/test";

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}
```

**Task-selector and outcome pattern** (lines 84-103):

```typescript
await page.goto("/audit");
const form = page.locator("#tl-record-lookup");
await form.locator('select[name="record_lookup[table]"]').selectOption(rowTable);
await form.locator('input[name="record_lookup[record_id]"]').fill(ticketReplyRecordId);
await form.getByRole("button", { name: "Open row history" }).click();

await expectPath(page, `/audit/rows/${rowTable}/${ticketReplyRecordId}`);
const drawer = page.getByTestId("row-history-drawer");
await expect(drawer).toBeVisible();
await expect(drawer.getByText("Row history:")).toBeVisible();
```

**Accessible handoff + stable task ID pattern** (lines 158-183):

```typescript
const filterDrawer = page.getByRole("dialog", { name: "Filters and handoff" });
const carry = filterDrawer.getByRole("link", { name: "Carry to Exports" });
await carry.click();
await expectPath(page, "/audit/exports");

const context = page.getByTestId("timeline-export-context");
await expect(context.getByText("Timeline export context")).toBeVisible();
```

Delete `expectEarnedFlow*` and EF-named locators/assertions. Prefer, in order: role/name or label, existing form ID, route/outcome, then existing task-oriented `data-testid`. There is no demonstrated uniqueness gap requiring a new DOM hook.

---

### `rendered_output_contract_test.exs` and optional structural helper (test/utility, batch-transform)

**Primary analog:** `test/threadline/removed_artifact_contract_test.exs`

**Scanner separation pattern** (lines 1-26):

```elixir
defmodule Threadline.RemovedArtifactContract do
  @moduledoc false

  def scan(file_sets, read_file) when is_map(file_sets) and is_function(read_file, 1) do
    # return concrete violations; do not assert here
  end
end
```

For Phase 201, prefer private helpers inside the contract test. Extract `rendered_structure_support.ex` only if more than one test genuinely reuses canonicalization. Scanner functions should return structured offenders such as `%{file: path, kind: kind, line: line, match: token}` so failures are actionable.

**Positive-control pattern** (lines 119-145):

```elixir
assert Scanner.scan(stale_tree, &Map.fetch!(stale_files, &1)) == [
  %{file: "README.md", kind: :active_citation, line: 2, target: ".planning/HANDOFF.json"}
]

assert Scanner.scan(clean_tree, &Map.fetch!(clean_files, &1)) == []
```

Seed every forbidden class (the three exact attributes, visible chronology/taxonomy, and CSS provenance comments) in synthetic strings and assert it is reported. Then assert the real derived inventory returns exact `[]`.

**Tracked, source-derived inventory pattern** (lines 179-188):

```elixir
root = Path.expand("../..", __DIR__)
{tracked_output, 0} = System.cmd("git", ["ls-files", "-z"], cd: root)
tracked = :binary.split(tracked_output, <<0>>, [:global, :trim_all])

assert Scanner.scan(file_sets, fn relative ->
  relative |> then(&Path.join(root, &1)) |> File.read!()
end) == []
```

Derive the owned LiveView source set, assert it is nonempty, and assert sentinel paths such as `start_live.ex` and `stress_live.ex` are included. Keep runtime tests independent of `.planning/`. Static visible-copy matching must be restricted to render-capable Threadline-owned text; exact attribute tokens can scan owned template source. Render `Threadline.OperatorSurface.Style.css/1` separately.

**Structural canonicalization:** use existing test-only `LazyHTML.from_fragment/1` and `LazyHTML.to_tree(sort_attributes: true, skip_whitespace_nodes: true)`. Recursively discard text/comments and only the three removed attributes; retain tag, sorted classes, ID, and ordered element children. Hash the normalized term with `:crypto.hash(:sha256, :erlang.term_to_binary(term))`. Do not commit full-DOM snapshots.

---

### Corpus integrity and evidence (test/evidence, file-I/O)

**Analog:** `test/threadline/operator_surface/operator_surface_fixture_contract_test.exs`

**Non-vacuous live-corpus pattern** (lines 65-75):

```elixir
manifest = evidence_manifest(@repository_root, @live_corpus_root)
assert manifest != [], "#{Path.join(@repository_root, @live_corpus_root)} must contain tracked evidence"
assert File.read!(Path.join(@repository_root, @live_corpus_root <> "/manifest.sha256")) ==
         encode_manifest(manifest)
assert validate_corpus(@repository_root, @live_corpus_root) == :ok
```

**Tracked-byte pattern** (lines 282-310):

```elixir
{output, 0} = System.cmd("git", ["ls-files", "-z", "--", corpus_root], cd: repo)

output
|> :binary.split(<<0>>, [:global, :trim])
|> Enum.sort()
|> Enum.map(fn tracked_path ->
  %{path: Path.relative_to(tracked_path, corpus_root),
    sha256: sha256(File.read!(Path.join(repo, tracked_path)))}
end)
```

The phase evidence file should record: accepted landed-commit/blob attribution, pre/post normalized hashes and element counts for all seven nodes, fixture manifest/tree hash, commands and results, zero/bounded exceptions, and an explicit statement that no capture, snapshot-update, or paid critic command ran. Never edit `test/fixtures/operator_surface/`.

---

### Durable test renames and discovery config (test/config, file-I/O/batch)

**Analogs:** `mix.exs` and `examples/threadline_phoenix/e2e/playwright.config.ts` (both in-place tracked consumers).

**Root alias consumer** (`mix.exs`, line 116): `verify.doc_contract` names `test/threadline/forward_only_gate_doc_contract_test.exs` explicitly. Update that exact token in the same commit as its `git mv`; conventional discovery covers the `phase06_nyquist` rename.

**Playwright consumer** (`playwright.config.ts`, lines 103-123):

```typescript
...(lightLane
  ? [{
      name: "desktop-chromium-light",
      testMatch: [
        /operator-(accessibility|motion|screenshots|screenshot-regression|stress)\.spec\.ts/,
        /operator-shell-home-phase183\.spec\.ts/,
      ],
    }]
  : []),
```

Update only the renamed spec regex (for example to `/operator-shell-home\.spec\.ts/`). Do not touch capture projects, snapshots, retry/worker policy, theme behavior, or unrelated historical comments.

## Shared Patterns

### Authorization and optional-dependency boundary

**Source:** `test/threadline/operator_surface/live/start_live_test.exs:42-71,194-204`

All affected LiveViews remain behind the existing router/auth/on-mount setup and `Code.ensure_loaded?(Phoenix.LiveView)` boundary. Selector cleanup must not alter routing, sessions, authorization, or optional dependencies.

### Exact-zero contracts with positive controls

**Sources:** `test/threadline/removed_artifact_contract_test.exs:119-188`; `test/threadline/public_surface_contract_test.exs:96-109,175-181`

Derived inventory must be nonempty and contain sentinels; synthetic offenders must fail with actionable details; the repository inventory must equal `[]`. Do not add an allowlist. If a measured movement unexpectedly occurs, use only the bounded exception schema required by D-13/D-15, with rationale and expiry.

### Behavior-first selectors

**Sources:** `test/threadline/operator_surface/live/start_live_test.exs:378-389,474-483`; `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts:84-103,158-183`

LiveView tests use `form`, `has_element?`, rendered outcomes, and redirects. Browser tests use role/name, labels, stable task IDs, URLs/query parameters, and visible outcomes. Never replace EF/P/J with parallel provenance metadata.

### Error handling

Contract scanners return complete offender collections and assertions print diffs/details. Live behavior keeps its current validation and navigation behavior. Tests should fail normally through ExUnit/Playwright; do not rescue assertion failures or add sleeps/retries.

### Verification boundary

Allowed: targeted `mix test`, `mix verify.mechanical`, existing desktop/mobile Playwright projects, example-app `mix precommit`, and final `mix ci.all`. Forbidden: `mix verify.capture`, capture-only projects/scripts, `--update-snapshots`, baseline/scorecard regeneration, `mix verify.ui_critique`, or any paid critic command.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `.planning/audits/201-rendered-output-evidence.md` | config/evidence | file-I/O | No existing artifact combines landed-blob attribution, seven-surface normalized hashes/counts, corpus hashes, command receipts, and forbidden-path attestation. Follow the required evidence fields above rather than copying a historical audit wholesale. |

## Metadata

**Analog search scope:** tracked files under `lib/threadline/operator_surface/`, `test/threadline/`, `examples/threadline_phoenix/e2e/`, plus root `mix.exs`

**Strong analogs read:** 5 — `start_live.ex`, `start_live_test.exs`, `operator-earned-flows.spec.ts`, `removed_artifact_contract_test.exs`, and `operator_surface_fixture_contract_test.exs`. `public_surface_contract_test.exs`, `mix.exs`, and `playwright.config.ts` supplied cross-cutting/config excerpts.

**Tracked-source gate:** every named code analog was verified nonempty through `git ls-files -- <path>`. No `.gsd` capability mirror or ignored runtime path is cited.

**Pattern extraction date:** 2026-09-13
