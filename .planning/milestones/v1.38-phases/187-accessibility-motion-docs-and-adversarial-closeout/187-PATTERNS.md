# Phase 187: Accessibility, Motion, Docs, and Adversarial Closeout - Pattern Map

**Mapped:** 2026-06-30
**Files analyzed:** 12
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `guides/operator-surface.md` | documentation | transform | `guides/operator-surface.md` plus theme source truth | exact |
| `test/threadline/operator_surface/theme_doc_contract_test.exs` | test | transform/source-read | `test/threadline/operator_surface/theme_doc_contract_test.exs` | exact |
| `test/threadline/operator_surface_doc_contract_test.exs` | test | transform/source-read | `test/threadline/operator_surface_doc_contract_test.exs` | exact |
| `test/threadline/operator_surface/coverage_doc_contract_test.exs` | test | transform/source-read | `test/threadline/operator_surface/coverage_doc_contract_test.exs` | role-match |
| `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` | test | event-driven/request-response | same file | exact |
| `test/threadline/operator_surface/component_contract_test.exs` | test | transform/source-read | same file | exact |
| `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` | test | event-driven/transform | same file | exact |
| `test/threadline/operator_surface/style_contract_test.exs` | test | transform/source-read | same file | exact |
| `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` | test | file-I/O/browser screenshot | same file plus `operator-stress.spec.ts` | exact |
| `.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-VERIFICATION.md` | documentation/evidence | batch/file-I/O | `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-VERIFICATION.md` and `186-VERIFICATION.md` | exact |
| `.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-ADVERSARIAL-REVIEW.md` | documentation/review | batch/transform | `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-ADVERSARIAL-REVIEW.md` | exact |
| `.planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-RESIDUAL-CI.md` | documentation/evidence | batch/transform | `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-RESIDUAL-CI.md` | exact, conditional |

## Pattern Assignments

### `guides/operator-surface.md` (documentation, transform)

**Analog:** `guides/operator-surface.md`

**Current drift target** (lines 61-95):
```markdown
### Theme

The operator surface renders in one of three host-selected lanes via the
optional `theme:` mount option, validated at compile time to one of
`:dark | :light | :system` (default `:dark`):
...
there is no JavaScript, no `localStorage`, and no runtime theme toggle, so
there is no flash of the wrong theme.
...
There is no runtime per-operator toggle in this version; the theme is a
host-owned mount decision rendered server-side.
```

**Docs structure pattern** (lines 127-169):
```markdown
## Security and Authorization (Fail-Closed Default)

Threadline adopts a **fail-closed security posture by default**. The `threadline_operator_surface/2` macro requires a secure mount. Multi-tenancy and authorization stay host-owned.
...
`live_session` and `on_mount` protect the LiveView pages only. They do not
secure the sibling HTTP export controller routes. Export denials stay
HTTP-native through `Threadline.OperatorSurface.ExportAuthPlug`: denial or
error halts with plain-text `403`, not a LiveView redirect.
```

**Coverage docs pattern** (lines 277-322):
```markdown
## Coverage and audit readiness

The operator surface ships selected-schema audit readiness at `/audit/coverage` by wrapping `Threadline.Health.trigger_coverage/1`.
...
Invalid input renders a schema-not-found message, keeps the picker usable, and offers **Use public schema** instead of showing stale rows from another schema.
...
For non-public schemas, run:

    mix threadline.verify_coverage --schema=NAME
```

**CSP docs pattern** (lines 413-420):
```markdown
### CSP guidance

If you enforce a Content-Security-Policy, the embedded assets require:

- `style-src 'unsafe-inline'` (or a per-response nonce) for the inline styles and `@font-face` data-URIs.
- `script-src 'unsafe-inline'` for the copy helper -- **or** set `operator_surface_embed_scripts: false` and drop the `'unsafe-inline'` script allowance entirely.
```

**Source truth for runtime theme picker:**

`lib/threadline/operator_surface/router.ex` (lines 52-56, 126-129):
```elixir
- `:theme` (`:dark | :light | :system`, default `:dark`) -- selects the
  default server-rendered operator-surface theme lane. `:system` follows the
  visitor's OS preference through scoped CSS only. A runtime dark/light/system
  theme picker is available in the shell (cookie + plug, resolved
  server-side); Threadline adds no JavaScript and no local storage.
...
if Code.ensure_loaded?(Phoenix.Controller) do
  scope unquote(path), as: false do
    post("/theme", Threadline.OperatorSurface.Controllers.ThemeController, :update)
  end
end
```

`lib/threadline/operator_surface/components/surface_header.ex` (lines 99-121):
```elixir
<section
  class="tl-shell-nav__group tl-theme-picker"
  aria-labelledby="tl-shell-nav-theme"
  data-testid="operator-nav-group-theme"
>
  <form action={"#{@base_path}/theme"} method="post" class="tl-theme-picker__form">
    <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />
    <fieldset class="tl-theme-picker__options">
      <legend id="tl-shell-nav-theme" class="tl-shell-nav__label">Theme</legend>
      ...
    </fieldset>
    <button type="submit" class="tl-button tl-button--primary">Apply theme</button>
  </form>
</section>
```

`lib/threadline/operator_surface/controllers/theme_controller.ex` (lines 4-8):
```elixir
def update(conn, %{"theme" => theme}) when theme in ["light", "dark", "system"] do
  conn
  |> put_session(:tl_theme, theme)
  |> put_resp_cookie("tl_theme", theme, path: "/")
  |> redirect(to: get_req_header(conn, "referer") |> List.first() || "/")
end
```

**Apply:** Replace stale "no runtime theme toggle" language with source-truth wording: runtime server-posted dark/light/system picker, POST `{base_path}/theme`, native radios, `_csrf_token`, session/cookie resolution, no JavaScript, no localStorage. Preserve fail-closed auth/export, Coverage selected-schema, Storybook/stress, CSP, production exclusion, and optional dependency boundaries.

---

### `test/threadline/operator_surface/theme_doc_contract_test.exs` (test, transform/source-read)

**Analog:** `test/threadline/operator_surface/theme_doc_contract_test.exs`

**Imports and path pattern** (lines 1-17):
```elixir
defmodule Threadline.OperatorSurface.ThemeDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @guide_path "guides/operator-surface.md"
```

**Literal-pin pattern** (lines 18-52):
```elixir
test "guide documents the theme: option literal" do
  src = File.read!(@guide_path)

  assert String.contains?(src, "theme:"),
         "expected #{@guide_path} to document the `theme:` mount option literal"
end
...
test "guide carries the D-04 daytime-use recommendation" do
  src = File.read!(@guide_path)

  assert String.contains?(src, "daytime-use recommendation"),
         "expected #{@guide_path} to carry the D-04 precedent phrasing `daytime-use recommendation`"
end
```

**Source-truth regression pattern:** copy the same `File.read!(@guide_path)` plus one literal per assertion. Add `refute String.contains?/2` checks for stale phrases using the style already present in `coverage_doc_contract_test.exs` (lines 188-190) and `surface_header_test.exs` (lines 81-84).

```elixir
refute String.contains?(coverage_section, "dashboard")
refute String.contains?(guide, "Which tables are covered right now?")
```

```elixir
assert html =~ ~r/name="theme" value="system" checked(="checked")?/
refute html =~ ~s|onchange=|
refute html =~ ~s|onclick=|
refute html =~ ~s|localStorage|
```

**Apply:** Keep tests pure source-reading and async. Pin each runtime theme picker literal separately: `runtime`, `/theme`, `_csrf_token`, `Apply theme`, `system`, `light`, `dark`, cookie/session wording, no JavaScript, no `localStorage`. Refute stale "no runtime theme toggle" and "no runtime per-operator toggle".

---

### `test/threadline/operator_surface_doc_contract_test.exs` (test, transform/source-read)

**Analog:** `test/threadline/operator_surface_doc_contract_test.exs`

**Imports and route/auth literal style** (lines 1-30):
```elixir
defmodule Threadline.OperatorSurfaceDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "operator surface guide details fail-closed security and auth options" do
    guide = File.read!("guides/operator-surface.md")

    assert String.contains?(guide, "fail-closed")
    assert String.contains?(guide, ":authorize_fn")
    assert String.contains?(guide, ":adopter_acknowledges_unauthenticated: true")
  end
end
```

**Callback/export boundary pattern** (lines 67-99):
```elixir
test "operator surface guide locks callback shape and export fallback wording" do
  guide = File.read!("guides/operator-surface.md")

  assert String.contains?(
           guide,
           "The `:authorize_fn` callback is invoked directly as a 1-arity function."
         )
  ...
  assert String.contains?(guide, "plain-text `403`")
  assert String.contains?(guide, "evidence_authorize_fn")
  assert String.contains?(guide, "coverage_authorize_fn")
  assert String.contains?(guide, "policy_authorize_fn")
  refute String.contains?(guide, "{:cont, socket}")
end
```

**Storybook/stress boundary pattern** (lines 120-145):
```elixir
test "operator surface guide keeps Storybook out of adopter install guidance" do
  guide = File.read!("guides/operator-surface.md")

  assert String.contains?(
           guide,
           "PhoenixStorybook is maintainer-only component documentation in `examples/threadline_phoenix`"
         )
  assert String.contains?(guide, "`/audit/__stress` remains the authenticated operator-flow stress harness")
  assert String.contains?(guide, "`/dev/storybook` is not a production route and is not part of the mounted `/audit` operator surface")
  refute String.contains?(guide, "{:phoenix_storybook")
  refute String.contains?(guide, "live_storybook")
end
```

**Apply:** If DOC-01 expands beyond theme docs, add pinned literals here for Storybook, stress route, export auth, CSP/asset opt-outs, and production exclusions. Do not make a broad parser; this repo favors direct literal contracts with precise failure messages.

---

### `test/threadline/operator_surface/coverage_doc_contract_test.exs` (test, transform/source-read)

**Analog:** `test/threadline/operator_surface/coverage_doc_contract_test.exs`

**Multi-source path setup** (lines 17-27):
```elixir
@router_path "lib/threadline/operator_surface/router.ex"
@health_path "lib/threadline/health.ex"
@policy_path "lib/threadline/health/policy.ex"
@coverage_lv_path "lib/threadline/operator_surface/live/coverage_live.ex"
@coverage_schemas_path "lib/threadline/health/coverage_schemas.ex"
@on_mount_path "lib/threadline/operator_surface/coverage/on_mount.ex"
@surface_header_path "lib/threadline/operator_surface/components/surface_header.ex"
@mix_task_path "lib/mix/tasks/threadline.health.coverage.ex"
@verify_task_path "lib/mix/tasks/threadline.verify_coverage.ex"
@row_history_path "lib/threadline/operator_surface/live/row_history_component.ex"
```

**Docs-section pinning pattern** (lines 149-190):
```elixir
describe "Phase 185 selected-schema readiness contracts (COV-01/COV-02/COV-03)" do
  test "operator guide documents selected-schema readiness, schema recovery, refresh, and row actions" do
    guide = File.read!("guides/operator-surface.md")
    coverage_section = guide_section(guide, "## Coverage and audit readiness")

    for heading <- [
          "## Coverage and audit readiness",
          "### Selected schema readiness",
          "### Schema selection",
          "### Refresh and stale data",
          "### Row actions and remediation",
          "### Multi-schema adopters"
        ] do
      assert String.contains?(guide, heading), "missing operator guide heading #{heading}"
    end

    assert String.contains?(guide, "Selected schema readiness")
    assert String.contains?(guide, "Use public schema")
    assert String.contains?(guide, "last known results")
    assert String.contains?(guide, "table_schema=NAME&table=TABLE")
    assert String.contains?(guide, "mix threadline.verify_coverage --schema=NAME")
    refute String.contains?(coverage_section, "dashboard")
  end
end
```

**Section helper** (lines 391-397):
```elixir
defp guide_section(markdown, heading) do
  markdown
  |> String.split(heading, parts: 2)
  |> List.last()
  |> String.split("\n## ", parts: 2)
  |> List.first()
end
```

**Apply:** Use this file if DOC-01 requires stronger selected-schema doc pins. Keep doc assertions section-scoped when rejecting stale wording so unrelated uses elsewhere do not false-fail.

---

### `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` (test, event-driven/request-response)

**Analog:** same file

**Imports, login, and focus helpers** (lines 1-158):
```typescript
import { expect, Locator, Page, test } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";
const adminEmail = "admin@example.com";
const rowTable = "ticket_replies";

async function login(page: Page) {
  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  const form = page.locator("#login_form");
  await form.getByLabel("Email").fill(adminEmail);
  await form.getByLabel("Password").fill(password);
  await form.getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL("/", { timeout: 30_000 });
}

async function expectNonObscuredFocused(locator: Locator, page: Page) {
  await expectFocused(locator);
  const visibleFocus = await locator.evaluate((element) => {
    const rect = element.getBoundingClientRect();
    const x = rect.left + Math.min(rect.width / 2, Math.max(1, rect.width - 1));
    const y = rect.top + Math.min(rect.height / 2, Math.max(1, rect.height - 1));
    const hit = document.elementFromPoint(x, y);
    return rect.width > 0 && rect.height > 0 && !!hit && (hit === element || element.contains(hit));
  });
  expect(visibleFocus).toBe(true);
  await expectNoHorizontalOverflow(page);
}
```

**Route discovery helpers** (lines 183-229):
```typescript
async function openTimelineAdvancedFilters(page: Page) {
  const disclosure = page.locator(".tl-filter-disclosure");
  if ((await disclosure.count()) > 0) {
    const open = await disclosure.evaluate((element) =>
      element.hasAttribute("open"),
    );
    if (!open) {
      await disclosure.locator("summary").click();
    }
    return;
  }
  ...
}

async function discoverTransactionAndRowHistory(page: Page) {
  await page.goto(`/audit/timeline?table=${encodeURIComponent(rowTable)}`);
  await expect(page.locator("#filter-table")).toHaveValue(rowTable);
  ...
  return { transactionHref: transactionHref!, rowHistoryHref: rowHistoryHref! };
}
```

**Keyboard/focus primary-flow pattern** (lines 252-431):
```typescript
test("exposes keyboard focus, skip link, nav state, and Home form names", async ({
  page,
}) => {
  await page.goto("/audit");

  await page.keyboard.press("Tab");
  await expectFocused(page.locator(".tl-skip-link"));
  await expect(page.locator(".tl-skip-link")).toHaveText(
    "Skip to main content",
  );

  await page.keyboard.press("Enter");
  await expect(page.locator("#tl-main")).toBeFocused();
  ...
});

test("keeps Timeline filters, Actor segments, and Retention danger action named and stateful", async ({
  page,
}) => {
  await page.goto("/audit/timeline");
  ...
  await page.keyboard.press("Escape");
  await expect(pruneModal).toBeHidden();
  await expectNonObscuredFocused(prune, page);
});
```

**Rendered APG widgets and ARIA snapshots** (lines 471-587, 589-722):
```typescript
test("opens stress rendered widgets with names, keyboard state, and focus entry", async ({
  page,
}) => {
  await page.goto("/audit/__stress?story=group.modal-destructive.current");
  ...
  await expect(dropdownTrigger).toHaveAttribute("aria-haspopup", "menu");
  await page.keyboard.press("Enter");
  await expect(dropdownMenu).toHaveAttribute("role", "menu");
  ...
  await expect(modal).toHaveAttribute("aria-modal", "true");
  await expect(page.getByRole("button", { name: "Confirm stress modal" })).toBeFocused();
});

test("captures accessibility-tree evidence for screen-reader-ready structure", async ({
  page,
}, testInfo) => {
  const homeSnapshot = await expectAriaSnapshotContains(
    page.locator("#tl-main"),
    [
      '- main:',
      'heading "Follow what happened."',
      'status "System health"',
      'link "Open the timeline"',
    ],
    { depth: 6 },
  );
  await testInfo.attach("home-main-aria-snapshot", {
    body: homeSnapshot,
    contentType: "text/plain",
  });
});
```

**Apply:** Extend this file only for missing A11Y-01/A11Y-02 proof. Prefer role/name locators, keyboard operations, visible non-obscured focus, focus restoration after Escape/close, accessible names, no horizontal overflow, and attached accessibility-tree snapshots. Do not add axe or claim screen-reader certification.

---

### `test/threadline/operator_surface/component_contract_test.exs` (test, transform/source-read)

**Analog:** same file

**Imports and source paths** (lines 14-23):
```elixir
use ExUnit.Case, async: true

import Phoenix.Component
import Phoenix.LiveViewTest

alias Threadline.OperatorSurface.UI

@style_path "lib/threadline/operator_surface/style.ex"
@ui_source_path "lib/threadline/operator_surface/ui.ex"
```

**APG/native source contract pattern** (lines 358-399):
```elixir
describe "A11Y-02 APG semantics map" do
  test "custom APG widgets declare the state, popup, and relationship hooks they implement" do
    src = File.read!(@ui_source_path)

    assert src =~ ~s(role="dialog")
    assert src =~ ~s(aria-modal="true")
    assert src =~ ~S(aria-labelledby={"#{@id}-title"})
    assert src =~ ~S(aria-describedby={"#{@id}-description"})
    assert src =~ ~s(aria-haspopup="menu")
    assert src =~ ~s(aria-haspopup="dialog")
    assert src =~ ~s(aria-haspopup="listbox")
    assert src =~ ~s(role="region")
  end

  test "native/non-applicable categories stay documented instead of gaining misleading ARIA roles" do
    src = File.read!(@ui_source_path)
    assert src =~ ~s(<select id={@id} name={@name})
    assert src =~ "NO ARIA role=\"table\"/\"row\"/\"cell\""
    refute src =~ ~s(role="grid")
  end
end
```

**Overlay dismiss contract** (lines 506-528):
```elixir
for {component, scrim_class} <- [
      {"modal", "tl-modal-scrim"},
      {"drawer", "tl-drawer-scrim"}
    ] do
  assert Regex.match?(~r/def #{component}\(assigns\).*?phx-key="escape"/s, src),
         "#{component} must bind an Escape-key dismiss (phx-key=\"escape\")"

  scrim_tag =
    case Regex.run(~r/<div[^>]*class="#{scrim_class}"[^>]*\/?>/s, src) do
      [tag] -> tag
      _ -> flunk("#{component}: missing #{scrim_class} element")
    end

  assert String.contains?(scrim_tag, "phx-click")
end
```

**Non-color and disabled affordance patterns** (lines 540-595):
```elixir
active_block =
  case Regex.run(
         ~r/\.threadline-ui \.tl-shell-nav__item\[aria-current="page"\]\s*\{[^}]*\}/s,
         src
       ) do
    [block] -> block
    _ -> flunk("missing nav active-state selector keyed on aria-current=\"page\"")
  end

assert String.contains?(active_block, "box-shadow:") or
         String.contains?(active_block, "border-color:"),
       "#8: active nav must carry a non-color cue (border/box-shadow), not background color alone (footgun #8)"
```

**Apply:** If adding source APG proof, keep it as direct source or rendered-to-string assertions. Do not role-inflate native controls. Failure messages must name the exact invariant.

---

### `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` (test, event-driven/transform)

**Analog:** same file

**Imports, computed-style helpers, and assertions** (lines 1-155):
```typescript
import { expect, Locator, Page, test } from "@playwright/test";

type StyleSnapshot = {
  animationName: string;
  animationDuration: string;
  animationDelay: string;
  boxShadow: string;
  cursor: string;
  opacity: string;
  pointerEvents: string;
  transform: string;
  transformOrigin: string;
  transitionDelay: string;
  transitionDuration: string;
  transitionProperty: string;
  transitionTimingFunction: string;
};

async function computedStyle(locator: Locator, pseudoElement?: string): Promise<StyleSnapshot> {
  await expect(locator).toBeVisible();
  return readComputedStyle(locator, pseudoElement);
}

function expectDurationList(value: string, duration: string) {
  const durations = value.split(",").map((part) => part.trim());
  expect(durations.every((part) => part === duration), `expected ${value} to collapse to ${duration}`).toBe(true);
}

function expectIdentityOrNone(transform: string) {
  expect(["none", "matrix(1, 0, 0, 1, 0, 0)"]).toContain(transform);
}
```

**Default motion pattern** (lines 159-273):
```typescript
test.describe("operator motion contracts with default motion", () => {
  test.use({ reducedMotion: "no-preference" });

  test.beforeEach(async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "no-preference" });
    await login(page);
  });

  test("stress overlays, popovers, details, and toasts compute tokenized compositor motion", async ({
    page,
  }) => {
    await page.goto("/audit/__stress?story=group.modal-destructive.current");
    const toastStyle = await computedStyle(page.locator("#stress-toast"));
    expectTransitionIncludes(toastStyle, {
      duration: "0.18s",
      properties: ["opacity", "transform"],
      easing: "cubic-bezier(0.2, 0, 0, 1)",
    });
  });
});
```

**Reduced-motion pattern** (lines 275-376):
```typescript
test.describe("operator motion contracts with reduced motion", () => {
  test.use({ reducedMotion: "reduce" });

  test.beforeEach(async ({ page }) => {
    await page.emulateMedia({ reducedMotion: "reduce" });
    await login(page);
  });

  test("row-history drawer enters without off-screen reduced-motion transform", async ({
    page,
  }) => {
    const ticketReplyRecordId = await discoverTicketReplyRecordId(page);
    await page.goto(`/audit/rows/${rowTable}/${ticketReplyRecordId}`);

    const drawerStyle = await computedStyle(page.getByTestId("row-history-drawer"));
    expect(drawerStyle.animationName).toBe("none");
    expectIdentityOrNone(drawerStyle.transform);
  });
});
```

**Apply:** Extend only if MOTION-01 lacks browser-computed proof. Use `page.emulateMedia`, `computedStyle`, token durations, opacity/transform properties, and `expectIdentityOrNone` for reduced-motion transforms.

---

### `test/threadline/operator_surface/style_contract_test.exs` (test, transform/source-read)

**Analog:** same file

**Imports and path pattern** (lines 1-6):
```elixir
defmodule Threadline.OperatorSurface.StyleContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @style_path "lib/threadline/operator_surface/style.ex"
  @motion_inventory_path ".planning/milestones/v1.31-phases/141-motion-micro-animation/141-MOTION-INVENTORY.md"
```

**Motion token and keyframe lock** (lines 336-360):
```elixir
for token <- [
      "--tl-motion-fast: 120ms;",
      "--tl-motion-base: 180ms;",
      "--tl-motion-slow: 240ms;",
      "--tl-motion-stagger: 40ms;",
      "--tl-motion-distance-sm: 8px;",
      "--tl-motion-distance-md: 16px;",
      "--tl-ease-standard: cubic-bezier(0.2, 0, 0, 1);",
      "--tl-ease-out: cubic-bezier(0.16, 1, 0.3, 1);",
      "--tl-transition-fast: var(--tl-motion-fast) var(--tl-ease-standard);"
    ] do
  assert String.contains?(src, token), "missing locked motion token #{token}"
end

assert keyframes ==
         Enum.sort(~w(tl-drawer-in tl-rise-in tl-thread-draw tl-fade-in tl-copy-pulse))
```

**Forbidden motion pattern** (lines 418-435, 548-581):
```elixir
refute Regex.match?(~r/transition:\s*all\b/, src)

for marker <- ["animejs", "framer-motion", "gsap", "motion.dev", "lottie"] do
  refute String.contains?(String.downcase(src), marker)
end

for [keyframe] <- Regex.scan(~r/animation:\s*(tl-[a-z0-9-]+)/, src, capture: :all_but_first) do
  assert keyframe in ~w(tl-drawer-in tl-rise-in tl-thread-draw tl-fade-in tl-copy-pulse),
         "unapproved animation keyframe #{keyframe}"
end

refute Regex.match?(~r/transform:\s*scale\(\s*0(?:\.0+)?\s*\)/, src),
       "surface motion must not collapse elements with transform: scale(0)"
```

**Reduced-motion source pattern** (lines 490-523):
```elixir
reduced_motion =
  src
  |> String.split("@media (prefers-reduced-motion: reduce) {")
  |> Enum.at(1)
  |> String.split("</style>")
  |> List.first()

for required <- [
      ".threadline-ui *",
      ".threadline-ui *::before",
      ".threadline-ui *::after",
      "transition-duration: 1ms !important;",
      "animation-duration: 1ms !important;",
      "scroll-behavior: auto !important;",
      "animation: none !important;",
      "transform: none;"
    ] do
  assert String.contains?(reduced_motion, required),
         "reduced-motion block missing #{required}"
end
```

**Focus source pattern** (lines 1214-1240):
```elixir
assert String.contains?(src, "--tl-focus-ring:")

for selector <- [
      ".threadline-ui button:focus-visible",
      ".threadline-ui [role=\"button\"]:focus-visible",
      ".threadline-ui input:focus-visible",
      ".threadline-ui select:focus-visible",
      ".threadline-ui a:focus-visible",
      ".threadline-ui summary:focus-visible"
    ] do
  assert String.contains?(src, selector), "missing focus-visible selector #{selector}"
end

refute Regex.match?(~r/\.threadline-ui\s+\*\s*\{[^}]*outline:\s*none/s, src),
       "blanket focus outline removal is forbidden"
```

**Apply:** If source motion/focus contracts need extension, place them near existing MOTION-01/focus sections. Keep regex helpers and explicit failure messages. Do not add new tokens/keyframes unless a plan explicitly justifies and inventories them.

---

### `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` (test, file-I/O/browser screenshot)

**Analog:** same file plus `operator-stress.spec.ts`

**Screenshot helper and masks** (lines 41-73):
```typescript
async function expectOperatorScreenshot(
  page: Page,
  name: string,
  options: { fullPage?: boolean; maxDiffPixelRatio?: number } = {},
) {
  await page.waitForLoadState("networkidle");
  await expect(page).toHaveScreenshot(`${name}.png`, {
    fullPage: options.fullPage ?? true,
    maxDiffPixelRatio: options.maxDiffPixelRatio ?? 0.01,
    mask: dynamicMasks(page),
  });
}

function dynamicMasks(page: Page): Locator[] {
  return [
    page.locator("time"),
    page.locator(".tl-table__date"),
    page.locator(".tl-copy.is-copied"),
    ...
  ];
}
```

**Local-only bounded guard** (lines 76-99, 101-140):
```typescript
test.describe("operator screenshot regression guard", () => {
  test.skip(
    !!process.env.CI,
    "visual screenshot baselines are platform-sensitive; run this guard locally before updating PNG snapshots",
  );

  test.beforeEach(async ({ page }, testInfo) => {
    test.skip(testInfo.project.name === "chromium", "fixed guard runs on desktop/mobile projects");
    ...
    await login(page);
  });

  test("global chrome and Home workflow launchers stay stable", async ({ page }) => {
    await page.goto("/audit");
    await expect(page.getByTestId("operator-header")).toBeVisible();
    await expect(page.locator("#tl-record-lookup")).toBeVisible();
    await expectOperatorScreenshot(page, "home");
  });
  ...
});
```

**Ledger-owned stress screenshot pattern** from `operator-stress.spec.ts` (lines 21-27, 265-299, 342-350):
```typescript
function ledger() {
  return JSON.parse(readFileSync(ledgerPath, "utf8"));
}

function ciScreenshotAllowlist() {
  return ledger().screenshot_allowlist.ci;
}

for (const item of ciScreenshotAllowlist()) {
  test(`${item.story_id} ${item.theme} ${item.viewport}px matches its ledger baseline`, async ({
    page,
  }) => {
    await page.goto(
      `/audit/__stress?story=${item.story_id}&theme=${item.theme}&viewport=${item.viewport}`,
    );
    const preview = page.getByTestId("stress-preview");
    await expect(preview).toHaveScreenshot(item.baseline_ref, {
      maxDiffPixelRatio: 0.01,
      mask: dynamicMasks(page),
    });
  });
}

test("ledger CI screenshot allowlist is bounded and baseline-backed", () => {
  const ci = ciScreenshotAllowlist();
  expect(ci).toHaveLength(3);
  for (const item of ci) {
    expect(item.baseline_ref).toBeTruthy();
    expect(existsSync(desktopSnapshotPath(item.baseline_ref))).toBe(true);
  }
});
```

**Apply:** Phase 187 should usually report these guard statuses, not modify them. If a real fix is needed, preserve local-only skip, dynamic masks, existing owned cells, and ledger-backed stress allowlist. Do not add broad route/theme/viewport screenshots.

---

### `187-VERIFICATION.md` (documentation/evidence, batch/file-I/O)

**Analog:** `180-VERIFICATION.md` and `186-VERIFICATION.md`

**Frontmatter and verdict pattern** from `180-VERIFICATION.md` (lines 1-13):
```markdown
---
phase: 180-accessibility-verification-guardrails-adversarial-closeout
verified: 2026-06-20
status: passed-with-inherited-ci-residuals
requirements: [A11Y-01, A11Y-02, MOTION-01, MOTION-02]
---

# Phase 180 Verification

## Verdict

Phase 180 is complete. The targeted accessibility, APG, motion, stress, screenshot, and adversarial guardrails pass. `mix ci.all` still exits non-zero because of inherited Phase 179 documentation/demo-seed failures classified in `180-RESIDUAL-CI.md`.
```

**Tiered proof pattern** from `180-VERIFICATION.md` (lines 14-31):
```markdown
## Tiered Proof

| Tier | Evidence | Proves | Does Not Prove |
|------|----------|--------|----------------|
| Tier A: Source contracts | ExUnit style/component/UI/stress/router/card/retention tests | Tokens, APG/source contracts, no card nesting regression, stress fixture/ledger/router continuity, retention modal server-side test alignment | Browser rendering, screenshots, real AT behavior |
| Tier B: Browser rendered checks | Playwright accessibility, motion, Phase 178 UAT, stress, screenshot regression specs | Rendered role/name/focus behavior, keyboard reachability samples, motion/reduced-motion computed styles, route/socket/drop/overlay stability, screenshot baseline stability | Every possible data row, browser, OS, host app, or assistive technology |
| Tier C: Automated accessibility-tree evidence | Playwright ARIA snapshots attached from `operator-accessibility.spec.ts` | Sampled Home, Timeline, row-history drawer, stress menu/modal/drawer expose expected browser accessibility-tree structure | Real screen-reader announcement timing, verbosity, rotor behavior, or human UAT |

## Verification Commands

| Command | Result |
|---------|--------|
```

**Observable-truth verification pattern** from `186-VERIFICATION.md` (lines 17-54):
```markdown
## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Transaction, row-history, and actor pages align on detail header, metadata, refs, drawers, copy, and state handling. | VERIFIED | `TransactionLive` uses `UI.shell`, `UI.page_header`, `UI.detail_header`, `UI.ref`, state components, and row-history pivots (`lib/threadline/operator_surface/live/transaction_live.ex:86`, `:101`, `:136`, `:170`, `:202`). |
...
**Score:** 30/30 truths verified (0 present, behavior-unverified)
```

**Behavioral spot-check and gaps pattern** from `186-VERIFICATION.md` (lines 98-138):
```markdown
### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Compile and targeted Phase 186 ExUnit/source/controller contracts | `mix compile --warnings-as-errors && mix test ...` with all Phase 186 operator LiveView/controller/gating/copy/style/doc contract tests | 231 tests, 0 failures | PASS |
| Targeted browser closeout across mobile, accessibility, investigation, earned-flow, feature-gate, and responsive lanes | `mix verify.example_browser -- ...` | 147 passed. | PASS |

### Requirements Coverage
...
### Gaps Summary

No gaps remain. All roadmap success criteria, plan must-haves, key artifacts, key links, data-flow checks, requirement IDs, and prohibitions are verified against the codebase.
```

**Apply:** Create `187-VERIFICATION.md` after commands run. Include frontmatter, verdict, tiered proof, exact commands/results, requirement closure for `A11Y-01`, `A11Y-02`, `MOTION-01`, `DOC-01`, `CLOSE-01`, screenshot/Playwright guard status, residual classification, and proof limits. Use residual file only if broad CI is non-green enough to need separate classification.

---

### `187-ADVERSARIAL-REVIEW.md` (documentation/review, batch/transform)

**Analog:** `180-ADVERSARIAL-REVIEW.md`

**Frontmatter and lens-table pattern** (lines 1-23):
```markdown
---
phase: 180-accessibility-verification-guardrails-adversarial-closeout
artifact: adversarial-review
created: 2026-06-20
status: passed
requirement: MOTION-02
---

# Phase 180 Adversarial Review

## D-12 Lens Review

| Lens | Review | Result |
|------|--------|--------|
| Aesthetics vs usability | Motion, focus, screenshots, contrast-adjacent semantics, and copy-state checks now favor operator task clarity over decorative churn. Screenshot baselines were refreshed only after the current rendered states and seeded discovery passed. | Pass |
| Dependency/architecture weight | No accessibility, axe, animation, or screenshot dependency was added. Evidence stays in existing ExUnit and Playwright harnesses. | Pass |
| Inaccessible custom behavior | Dialogs, drawers, dropdowns, tabs, comboboxes, alerts, statuses, focus entry, and focus restoration are covered by role/name/focus and ARIA snapshot checks. | Pass with bounded AT caveat |
```

**Findings/follow-through pattern** (lines 24-34):
```markdown
## Findings

No blocking Phase 180-owned issue remains.

The main proof boundary is accessibility: Playwright's browser accessibility tree is a useful automation target, but it is not equivalent to NVDA, VoiceOver, JAWS, Narrator, TalkBack, or a human assistive-technology workflow.

## Follow-Through

- Keep `operator-accessibility.spec.ts` as the rendered accessibility and accessibility-tree evidence harness.
- Keep `operator-screenshot-regression.spec.ts` local/platform-sensitive; update baselines only when the current rendered surface has already passed semantic guards.
```

**Apply:** Use Phase 187's required four lenses: operator under incident pressure, keyboard/assistive-technology user, OSS maintainer/library boundary, and host-app DX/security boundary. Actively check route stability, auth/export gates, CSP posture, optional dependency hygiene, docs truth, focus traps, obscured focus, color-only state, reduced motion, screenshot churn, and overclaiming accessibility.

---

### `187-RESIDUAL-CI.md` (documentation/evidence, batch/transform, conditional)

**Analog:** `180-RESIDUAL-CI.md`

**Residual classification pattern** (lines 1-22):
```markdown
---
phase: 180-accessibility-verification-guardrails-adversarial-closeout
artifact: residual-ci
created: 2026-06-20
status: inherited-non-blocking
---

# Phase 180 Residual CI Classification

## Command

`mix ci.all`

## Current Result

`mix ci.all` exits non-zero, but Phase 180-owned regressions were fixed before closeout.

| Suite | Result | Classification |
|-------|--------|----------------|
| Root | 1120 tests, 1 failure, 1 excluded | Inherited non-blocking |
| Example | 95 tests, 7 failures | Inherited non-blocking |
```

**Owned-fix and inherited-residual pattern** (lines 23-53):
```markdown
## Phase 180-Owned Failures Fixed During Closeout

`mix ci.all` initially exposed six root failures ...

## Inherited Residuals

These match the Phase 179 residual failure families and are outside A11Y-01, A11Y-02, MOTION-01, and MOTION-02.

| File/Test | Current Shape | Phase 179 Baseline |
|-----------|---------------|--------------------|
...
## Classification

No current `mix ci.all` failure is owned by Phase 180 after the retention test repair.
```

**Apply:** Create this only if `187-VERIFICATION.md` would become too dense or if `mix ci.all` has broad non-green output needing traceable owner/impact/in-scope classification. Otherwise keep residuals in `187-VERIFICATION.md`.

## Shared Patterns

### Source-Reading ExUnit Contracts

**Source:** `theme_doc_contract_test.exs`, `operator_surface_doc_contract_test.exs`, `coverage_doc_contract_test.exs`, `component_contract_test.exs`, `style_contract_test.exs`

**Apply to:** All doc/source contract tests.

```elixir
src = File.read!(@path)
assert String.contains?(src, "locked literal"),
       "expected #{@path} to contain the locked literal"
refute Regex.match?(~r/forbidden-pattern/, src),
       "specific invariant failure message"
```

Use direct `String.contains?/2` for pinned copy and simple source truth. Use regex only when order, selector blocks, or HTML fragments require it. Keep failure messages specific enough to identify the broken contract.

### Runtime Theme Picker Truth

**Source:** `router.ex` lines 52-56 and 126-129; `surface_header.ex` lines 99-121; `theme_controller.ex` lines 4-8; `surface_header_csp_test.exs` lines 45-52; `surface_header_test.exs` lines 66-85.

**Apply to:** `guides/operator-surface.md`, theme doc contract tests, broad operator-surface doc contract tests.

Key facts to pin:

- Runtime dark/light/system picker exists.
- Form posts to `{base_path}/theme` with method `post`.
- Native radios use `name="theme"` values `system`, `light`, `dark`.
- Form includes `_csrf_token`.
- Controller allowlists `light`, `dark`, `system`.
- State is session/cookie/server resolved.
- No JavaScript handler and no `localStorage`.

### Browser Accessibility Proof

**Source:** `operator-accessibility.spec.ts` lines 1-230, 252-431, 471-722.

**Apply to:** A11Y-01/A11Y-02 rendered proof.

Use the existing helpers:

- `login(page)`
- `expectFocused(locator)`
- `expectNonObscuredFocused(locator, page)`
- `expectNoHorizontalOverflow(page)`
- `expectAriaSnapshotContains(locator, snippets, options)`
- `openOperatorNav(page)`
- `openTimelineAdvancedFilters(page)`
- `discoverTransactionAndRowHistory(page)`

Keep proof role/name/keyboard based. Use screenshots only as existing bounded visual guards.

### Motion Proof

**Source:** `style_contract_test.exs` lines 336-581 and `operator-motion.spec.ts` lines 1-376.

**Apply to:** MOTION-01 source/browser proof.

Use two tiers:

- ExUnit source guard: tokens, approved keyframes, no `transition: all`, no motion libraries, reduced-motion blanket, no layout-affecting transitions.
- Playwright computed guard: default motion uses token durations/properties/easing; reduced motion collapses durations/transforms while keeping UI visible.

### Screenshot Boundary

**Source:** `operator-screenshot-regression.spec.ts` lines 41-142 and `operator-stress.spec.ts` lines 21-27, 265-350.

**Apply to:** CLOSE-01 screenshot/visual QA status.

Report existing guard status for Home, dense Timeline, row-history drawer, Exports, Retention, and ledger-owned stress cells. Do not add baselines outside `.planning/design-system-ledger.json`.

### Closeout Evidence

**Source:** `180-VERIFICATION.md`, `180-ADVERSARIAL-REVIEW.md`, `180-RESIDUAL-CI.md`, `186-VERIFICATION.md`

**Apply to:** `187-VERIFICATION.md`, `187-ADVERSARIAL-REVIEW.md`, optional `187-RESIDUAL-CI.md`.

Required evidence shape:

- Frontmatter with phase, date, status, requirement IDs.
- Verdict.
- Tiered proof with "Proves" and "Does Not Prove".
- Exact command ledger and results.
- Requirement closure table.
- Screenshot/Playwright status.
- Residual owner/impact/scope classification.
- Proof limits, especially no real screen-reader certification unless real AT UAT was performed and recorded.

## No Analog Found

No files lack a close analog. The only conditional artifact is `187-RESIDUAL-CI.md`; use `180-RESIDUAL-CI.md` if broad CI residuals need standalone owner/impact classification.

## Metadata

**Analog search scope:** `guides/`, `test/threadline/operator_surface/`, `test/threadline/`, `examples/threadline_phoenix/e2e/tests/`, `lib/threadline/operator_surface/`, `.planning/phases/`, `.planning/milestones/`
**Files scanned:** 576 repo files, plus 116 planning verification/review/residual artifacts
**Pattern extraction date:** 2026-06-30
**Read-only note:** Source, test, doc, STATE, ROADMAP, and config files were not modified. Only this PATTERNS artifact was written.
