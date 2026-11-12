# Phase 250: Brand foundation and first whole investigation - Pattern Map

**Mapped:** 2026-11-12  
**Files analyzed:** 22 candidate implementation, documentation, and test files  
**Tracked analogs found:** 22 / 22 (two behavior slices have only partial analogs)

## File Classification

| New/Modified File or Owner | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/operator_surface/style/01_tokens.css` | config | transform | Same scoped token sheet | exact |
| `lib/threadline/operator_surface/components/logo.ex` | component | transform | Existing compile-time inline logo component | role-match; artwork is retired |
| `lib/threadline/operator_surface/components/surface_header.ex` | component | request-response | Same mounted shell and theme form | exact |
| `lib/threadline/operator_surface/fonts.ex` | utility | file-I/O, transform | Existing compile-time font embedder | exact |
| `examples/threadline_phoenix/priv/static/images/threadline-admin-favicon.svg` | asset | file-I/O | Existing Admin icon path | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/components/layouts/app.html.heex` | component | request-response | Existing conditional document head | exact; preserve its route split |
| `mix.exs` | config | transform, file-I/O | Existing ExDoc hooks and Hex allowlist | exact extension point |
| `README.md` | documentation | transform | Existing theme-paired image and package introduction | exact |
| `guides/operator-surface.md` | documentation | transform | Existing Admin/mount guide | exact |
| `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts` | test | request-response | Mounted Timeline → transaction → row-history journey | partial; current selector takes the first table match |
| `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | test | event-driven, request-response | Deferred clipboard and route-state browser tests | role-match; current copy proof starts from Timeline and clicks |
| `examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts` | utility | file-I/O, transform | Existing source-bound shell/content capture helper | partial; no same-materialization pair protocol |
| `test/threadline/brandbook_token_parity_test.exs` | test | transform, file-I/O | Existing filesystem-backed token parity test | role-match; its current oracle is the superseded `brandbook/` |
| `test/threadline/operator_surface/style_byte_lock_test.exs` | test | transform | Existing stylesheet/font byte lock | exact |
| `test/fixtures/style/operator_surface.css` | test fixture | file-I/O | Existing rendered CSS golden | exact |
| `test/fixtures/style/README.md` | documentation | transform | Existing golden update procedure | exact |
| `test/threadline/operator_surface/surface_header_test.exs` | test | request-response | Existing header/theme rendering assertions | exact |
| `test/threadline/operator_surface/presentation_test.exs` | test | transform | Existing value/time/omitted-state assertions | exact |
| `test/threadline/readme_doc_contract_test.exs` | test | transform | Existing README contract tests | role-match |
| `test/threadline/code_walkthrough_doc_contract_test.exs` | test | transform | Existing ExDoc hook/favicon contract | role-match; currently expects old favicon |
| `test/threadline/release_artifact_contract_test.exs` | test | file-I/O, transform | Existing unpacked-Hex contracts | exact; binary-byte comparison needs an extension |
| `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` | test | request-response, file-I/O | Existing mounted Admin/favicon route test | exact |

## Pattern Assignments

### `lib/threadline/operator_surface/style/01_tokens.css` and `test/threadline/brandbook_token_parity_test.exs`

**Analog:** `lib/threadline/operator_surface/style/01_tokens.css`; `test/threadline/brandbook_token_parity_test.exs`

`01_tokens.css` already owns functional variables inside `.threadline-ui`. It has a dark base, a light selector, and a System branch under `prefers-color-scheme`; keep that structure and existing variable names. The approved `brand/brand.json` is the parity authority. Preserve all eight stable contrast IDs in both explicit theme lanes and keep artwork, link/focus, control edge, and operation colors as separate roles.

**Scoped theme pattern** (`01_tokens.css`, lines 2-4, 176-185, 187-200, 236-250):

```css
.threadline-ui {
  --tl-color-bg: var(--tl-color-threadline-black);
  color-scheme: dark;
}

.threadline-ui[data-tl-theme="light"] {
  color-scheme: light;
  --tl-color-bg: #F7F9FC;
  --tl-color-text: #0F1728;
}

@media (prefers-color-scheme: light) {
  .threadline-ui[data-tl-theme="system"] {
    color-scheme: light;
    --tl-color-bg: #F7F9FC;
    --tl-color-text: #0F1728;
  }
}
```

**Test style, not old source authority** (`brandbook_token_parity_test.exs`, lines 3-20, 22-36):

```elixir
use ExUnit.Case, async: true
alias Threadline.Test.StyleSource

defp style_source, do: StyleSource.read!()
```

The current test explicitly compares the shipped tokens with `brandbook/tokens.css` and `brandbook/tokens.json` (lines 24-34). Replace those old references with `brand/brand.json`; do not preserve the retired brandbook as a second authority. The JSON lists the stable contrast-pair IDs at `brand/brand.json:280-424`.

### `components/logo.ex`, `components/surface_header.ex`, and theme contract owners

**Analogs:** `lib/threadline/operator_surface/components/logo.ex:22-40`; `lib/threadline/operator_surface/components/surface_header.ex:18-24,94-117`; `lib/threadline/operator_surface/controllers/theme_controller.ex:9-27`

`Logo.compact/1` is the existing compile-time HEEx SVG component. Reuse its component boundary and CSS-variable integration, but do not copy its current C13 paths: comments at lines 5-20 describe the retired brandbook logo and Thread Blue thread. Inline the approved paired lockups without editing their geometry or colors. The existing token CSS declares the 132px/148px shell sizes, which exceed the 96px minimum.

```elixir
attr(:rest, :global)

def compact(assigns) do
  ~H"""
  <svg class="tl-topbar__brand-logo" viewBox="-80 60 5194 1140"
       aria-hidden="true" focusable="false" {@rest}>
  ```

The header already owns the home link, navigation, and theme controls. Change the accessible home name to `Threadline Admin home` at its existing link (`surface_header.ex:21-24`). Preserve the grouped fieldset/legend and native POST form while replacing the radio-plus-confirm-submit pattern with the three immediate submit buttons:

```heex
<form action={"#{@base_path}/theme"} method="post" class="tl-theme-picker__form">
  <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
  <fieldset class="tl-theme-picker__options">
    <legend id="tl-shell-nav-theme" class="tl-shell-nav__label">Theme</legend>
    ...
  </fieldset>
</form>
```

The controller remains the server-authoritative owner: `theme_controller.ex:9-14` allowlists `light`, `dark`, `system`, stores the value in session and cookie, then redirects; `:20-27` resolves a same-origin or relative return path under the mounted surface. Extend the existing header test rather than changing these contracts. The current test asserts the CSRF form, theme radios, and `Apply theme` at `surface_header_test.exs:66-85`; update the assertions to the new immediate-button and `aria-pressed` contract.

### `lib/threadline/operator_surface/fonts.ex`, the CSS golden, and byte-lock tests

**Analogs:** `lib/threadline/operator_surface/fonts.ex:30-65`; `test/threadline/operator_surface/style_byte_lock_test.exs:54-96`; `test/fixtures/style/README.md:1-27`

The embedder marks source files as external resources, reads and base64-encodes them at compile time, and keeps `operator_surface_embed_fonts: false` as an empty-face opt-out:

```elixir
for {_family, _weight, file} <- @faces do
  @external_resource Path.join(@fonts_dir, file)
end

@face_css (for {family, weight, file} <- @faces do
  data = @fonts_dir |> Path.join(file) |> File.read!() |> Base.encode64()
  # emit one @font-face rule
end) |> Enum.join("\n")

def face_css do
  if Application.get_env(:threadline, :operator_surface_embed_fonts, true),
    do: @face_css,
    else: ""
end
```

Keep that compile-time/opt-out boundary while changing the source set to the four approved WOFF2 subsets and using private family aliases. Keep all three OFL files available in the package; no remote font fallback. The source path today is `priv/fonts` and family names are generic (`Geist`, `IBM Plex Mono`), so neither is the approved new source/alias. A font or token edit changes the rendered CSS: update `test/fixtures/style/operator_surface.css` and both hash pins in `style_byte_lock_test.exs` through the documented procedure, and keep the fixture and pins together. Do not bypass this lock or treat it as a parity source.

### `Presentation` / `UI.Display` semantic owners

**Shared analogs:** `lib/threadline/operator_surface/presentation.ex:6-31,395-465`; `lib/threadline/operator_surface/ui/display.ex:155-207,227-239`; `test/threadline/operator_surface/presentation_test.exs:304-365`

Keep `Presentation` and `UI.Display` as shared meaning owners. `value_token/1` preserves `nil` as `null`, `[REDACTED]` as redacted, and timestamps with exact ISO titles; `change_value_token/2` keeps `(omitted)` and `(absent)` distinct from a present `nil`. `UI.Display.ref/1` binds the complete value to `data-tl-copy`, keeps the visible `Copy` label, and gives the button its caller-owned accessible name. Retain `Copy row id`; truncate only the visible rendering, never the copied value. Reuse the existing separate tests for these negative controls; do not insert exceptional missing/excluded/unavailable values into the ordinary #4521 story.

### Example journey and clipboard tests

**Analogs:** `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts:41-76,125-175,228-274`; `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts:208-300`; seeded story at `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex:63-90` and `examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex:62-73`

The earned-flow file already waits for LiveView connection, follows route links, and proves query restoration. Its helper at lines 41-75 currently selects the **first** row matching only `ticket_replies`; the journey at 228-260 also starts from that first table match. Narrow selection by `walk-acme-4521-close` and applicable committed date predicates, assert `ticket_replied_and_closed`, then derive generated transaction/change/record IDs from the selected row’s real links. Do not assume a UUID or rely on first-row order. Existing restoration at lines 125-175 checks table/from/to and visible table; extend it to correlation and all committed visible filter values.

The ordinary fixture already resolves closer ID dynamically from `Manifest`, sets the correlation and event time, and seeds the reply body and trigger-masked internal note (`anchors.ex:63-90`). Bind assertions to that actual selected row, one action, two changes in one transaction, the rendered `user/<Manifest closer UUID>`, exact values, and UTC event time. The canary remains a negative control that must not appear in the rendered output.

The clipboard tests provide a deferred promise double and truthful failure/focus proof:

```typescript
writeText(value: string) {
  probe.calls.push({ value, userActivation: ... });
  return new Promise<void>((resolve) => probe.pending.push(resolve));
}
...
await expect(status).toHaveText("Copying…");
expect(probe.calls).toEqual([{ value: expected, userActivation: true }]);
probe.resolveNext();
await expect(status).toHaveText("Copied.");
```

This is `operator-route-states.spec.ts:208-247`; its rejection control at `:269-300` checks the manual-recovery copy, `role=status`, focus, no success class, and no fallback textarea leak. Extend the reached history-row control to keyboard activation and full actual ID, and keep connected-state waits after route navigation/patch. This proves the API argument and feedback only; the existing native-clipboard cases do not prove browser permissions or native clipboard contents.

### `operator-browser-evidence.ts` paired-capture extension

**Closest analog:** `examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts:89-165`

The existing helper waits for font readiness and LiveView connection, hashes inline served CSS, captures `.threadline-ui` shell plus `#tl-main` content, records browser/theme/viewport conditions, and marks zoom `unverified` (`:107-155`). Extend this with a narrow phase-owned pair sidecar for the selected row fingerprint and actually served SVG/font identities. Embedded fonts are in CSS data URIs; source bytes alone do not establish served bytes, so decode the served WOFF2 payloads for the record.

There is no exact tracked analog for the same-materialization before/after protocol. The general evidence helper binds a run to fresh evidence identity/fixture inputs (`:48-90`) and is not a paired baseline runner. Capture the baseline before rendered production edits; retain the same seeded database, partition and port between halves, restart only the HTTP server, and record actual transaction/change/record IDs, persisted UTC times, and a read-only target-row fingerprint. Do not reset/reseed between halves or use a seed-source hash as a data snapshot. `playwright.config.ts:1-3` accepts `E2E_BASE_URL`; preflight it as the HTTP application listener, distinct from the PostgreSQL listener on port `60025`. `run-e2e.sh:427-433` creates/migrates/resets demo data, so it is not the pair runner. Keep the existing evidence gates and mark zoom unverified unless actually measured.

### README, ExDoc, favicon, and package seams

**Analogs:** `README.md:1-19`; `guides/operator-surface.md:1-25`; `mix.exs:484-509,512-529,659-750,754-843`; `examples/threadline_phoenix/lib/threadline_phoenix_web/components/layouts/app.html.heex:1-15`; package contracts below.

The README’s existing `<picture>` is already the dark/light selection pattern. Keep it theme-paired but point to the approved lockups and honor the minimum rendered width. Keep the guide change limited to its introduction: Threadline is an audit trail library; the visible UI is Threadline Admin. Preserve public module/config/route/query/schema/telemetry names and existing anchors.

`mix.exs:512-529` owns ExDoc favicon, assets, head/body hooks, and extras; `:659-750` is the HTML head hook; `:754-843` is the body hook with an existing `body.dark` check and body-class `MutationObserver`. Use these tracked hook seams for paired docs artwork and sizing. There is no tracked project source for ExDoc’s internal 48px logo cap or theme bundle; do not cite or pattern-match an ignored `deps/ex_doc` checkout. Use installed-version research as a constraint and generated-doc output as the proof.

The package configuration at `mix.exs:484-509` uses an explicit file allowlist and exclusions. Replace the old `brandbook` entries with only the approved three SVGs, four WOFF2 files, and three licenses. Do not include the entire `brand/` tree. `release_artifact_contract_test.exs:282-330,646-681` builds and unpacks the actual Hex archive; extend its source/archive checks for this exact set. Its current `readable` map filters text bytes, so WOFF2 byte parity needs raw-byte access or a targeted archive read, not a filename-only assertion. Its existing `:362-376` pattern verifies source ownership against actual archive contents.

The layout already selects `/images/threadline-admin-favicon.svg` only for Admin routes and preserves `/favicon.ico` for demo home/login (`app.html.heex:5-15`). Replace only the SVG bytes at the Admin static path. Extend `operator_surface_test.exs:22-27` from status/MIME checks to exact served-source parity; preserve the conditional path split.

## Shared Patterns

### Theme, authorization, and safe return

**Source:** `lib/threadline/operator_surface/components/surface_header.ex:99-117`; `lib/threadline/operator_surface/controllers/theme_controller.ex:9-27`; `lib/threadline/operator_surface/router.ex:91-110`

Apply the current native POST + CSRF + allowlisted server value + session/cookie + validated local return path pattern. Keep the fieldset legend and keyboard focus. Do not introduce client-only persistence, a new endpoint, or a login/white-label setting.

### Truthful state and copy

**Source:** `Presentation`, `UI.Display`, and their existing focused test owners listed above.

Keep loading/error/empty distinctions grounded in their existing typed state boundaries. UI-SPEC loading criteria are acceptance obligations, not evidence that an asynchronous state or new LiveView event currently exists. Inspect the current implementation before assigning new state behavior.

### Scoped styles and assets

**Source:** `lib/threadline/operator_surface/style/01_tokens.css`; `lib/threadline/operator_surface/fonts.ex`; `lib/threadline/operator_surface/components/logo.ex`; `mix.exs` package/docs config.

Use `.threadline-ui` variables for runtime values, compile-time/local approved artwork and fonts for Threadline Admin, and the three exact package SVGs. Keep host-scoped CSS and offline behavior.

## No Exact Analog Found

| Slice | Nearest tracked source | Why it is only partial |
|---|---|---|
| Same-database matched baseline/after capture | `examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts` | Existing evidence captures one source-bound run and has fresh-fixture identity rules; it does not pair two rendered source versions over the same materialized rows. Use a narrow pair helper and preserve all existing gates. |
| ExDoc logo source switching and ≥96px render | `mix.exs` HTML head/body hooks | The tracked hooks are valid extension points, but no project source currently switches a docs logo by `body.dark`. ExDoc implementation files are dependency checkout paths, not tracked analogs; verify generated docs against the installed ExDoc version. |

## Source Gotchas

- Two paths named in `250-RESEARCH.md` are not tracked in this checkout: `lib/threadline/operator_surface/logo.ex` and `lib/threadline/operator_surface/theme_controller.ex`. Use tracked origins `lib/threadline/operator_surface/components/logo.ex` and `lib/threadline/operator_surface/controllers/theme_controller.ex`.
- The old token test and current logo implementation still refer to `brandbook/`; those are migration inputs, not authority. The approved files `brand/brand.json`, `brand/assets/README.md`, and the supplied asset paths are tracked.
- The current earned-flow and evidence helpers can select a first row based on a table-only predicate. The #4521 story must bind through correlation and exact selected row identity.
- ExDoc dependency internals under `deps/` are install/runtime mirrors. They must not appear as analog paths in plans; cite tracked hooks and verify generated output.

## Metadata

**Analog search scope:** `lib/threadline/operator_surface/`, `test/threadline/operator_surface/`, `test/threadline/`, `test/fixtures/style/`, `examples/threadline_phoenix/e2e/`, example layout/static/test owners, README, guide, `mix.exs`, and approved `brand/` assets.  
**Analog-source tracking:** all named code analogs were verified with `git ls-files`; no ignored runtime mirror is used.  
**Pattern extraction date:** 2026-11-12
