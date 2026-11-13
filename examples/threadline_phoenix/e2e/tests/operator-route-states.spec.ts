import { chromium, expect, test, type Locator, type Page, type WebSocketRoute } from "@playwright/test";
import { createHash, randomUUID } from "node:crypto";
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { installControlledClipboard, login, paths, seedPaths, startEvidence } from "../support/operator-browser-evidence.js";
import { capturePhase250GateObservation } from "../support/operator-investigation-pair.js";
import { setAndReadTabZoom, withIsolatedZoomContext } from "../support/operator-tab-zoom.js";

// Passing this suite means observed states have source-bound evidence. Existing
// product failures are recorded for the later refinement phases, not repaired here.
test.use({ trace: "off", screenshot: "off", contextOptions: { reducedMotion: "reduce" } });
test.beforeEach(async ({ page }, info) => {
  if (process.env.THREADLINE_E2E_EVIDENCE === "1" || process.env.THREADLINE_PHASE252_CONTROLLED_CLIPBOARD === "1") await installControlledClipboard(page);
  if (process.env.THREADLINE_PHASE250_BROWSER_GATE === "theme" &&
      info.title === "theme preference, effective cascade and reduced motion are distinct observed facts" &&
      info.project.name === "desktop-chromium") return;
  if (["fonts-loaded", "fonts-disabled"].includes(process.env.THREADLINE_PHASE250_BROWSER_GATE ?? "") &&
      info.title === "Phase250 fonts and brand boundaries" && info.project.name === "desktop-chromium") return;
  if ([
    "Evidence keeps selected subject/reference through latest and proof-history navigation",
    "Timeline delayed query exposes pending then real empty result with a long unbroken filter",
    "Timeline export reaches protected download and returns to its committed search",
    "Timeline keeps populated query identity while an applied replacement is pending",
    "Home correlation lookup keeps destination identity while navigation is pending",
    "real host denial under Acme support is distinct from busy and disabled",
    "saved searches keep canonical sharing, long summaries, and destructive actions reachable",
    "saved search actions stay in bounds at verified 200% browser zoom",
    "actor and correlation pivots re-enter Timeline with only their supported filters",
    "Timeline pagination appends the next page without changing the applied search URL",
    "Clipboard success waits for confirmation on direct entry and after patches",
    "Clipboard failure shows manual recovery without claiming success",
    "Clipboard fallback confirms success and restores focus and selection",
    "Copy feedback fits long URLs and redacted values stay non-copyable",
    "Exports seeded pending, failed, completed, unavailable and invalid context stay distinct",
    "Redaction policy comparison stays safe, keyboard-operable, and responsive",
    "Redaction inspection distinguishes a missing empty-policy trigger from unreadable deployment",
    "Retention confirmation focus and cancel preserve state; Chromium touch navigation works",
  ].includes(info.title)) return;
  if (info.title.startsWith("offline Exports ")) return;
  test.skip(process.env.THREADLINE_E2E_EVIDENCE !== "1" || !["desktop-chromium", "desktop-chromium-light"].includes(info.project.name), "Bounded evidence lanes only");
});

async function expectNoHorizontalOverflow(page: Page) {
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  expect(overflow).toBeLessThanOrEqual(1);
}

function copyStatus(control: Locator) {
  return control.locator("xpath=..").locator("[data-tl-copy-status]");
}

async function phase250FocusByKeyboard(page: Page, target: Locator) {
  await target.scrollIntoViewIfNeeded();
  const limit = await page.locator('a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), summary, [tabindex]:not([tabindex="-1"])').count() + 1;
  for (let index = 0; index < limit; index += 1) {
    if (await target.evaluate((element) => element === document.activeElement)) return;
    await page.keyboard.press("Tab");
  }
  throw new Error("Keyboard traversal did not reach the required control");
}

function phase250Rgb(hex: string) {
  return `rgb(${[1, 3, 5].map((start) => parseInt(hex.slice(start, start + 2), 16)).join(", ")})`;
}

function phase250Contrast(text: string, ground: string) {
  const luminance = (color: string) => {
    const channels = color.match(/[\d.]+/g)!.slice(0, 3).map(Number).map((value) => {
      const s = value / 255;
      return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
    });
    return channels[0]! * 0.2126 + channels[1]! * 0.7152 + channels[2]! * 0.0722;
  };
  const a = luminance(text), b = luminance(ground);
  return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
}

if (["fonts-loaded", "fonts-disabled"].includes(process.env.THREADLINE_PHASE250_BROWSER_GATE ?? "")) {
  test("Phase250 fonts and brand boundaries", async ({ page, context, browser }, info) => {
    test.setTimeout(90_000);
    const disabled = process.env.THREADLINE_PHASE250_FONT_MODE === "disabled";
    expect(disabled).toBe(process.env.THREADLINE_PHASE250_BROWSER_GATE === "fonts-disabled");
    const sourceRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../../../..");
    const brand = JSON.parse(readFileSync(join(sourceRoot, "brand/brand.json"), "utf8"));
    const origin = new URL(process.env.E2E_BASE_URL!).origin;
    const externalRequests: string[] = [];
    const allowLocal = async (route: any) => {
      const url = new URL(route.request().url());
      if (["http:", "https:"].includes(url.protocol) && url.origin !== origin) {
        externalRequests.push(url.origin); await route.abort();
      } else await route.continue();
    };
    await page.route("**/*", allowLocal);
    const fontRequests = [
      '600 28px "Threadline Familjen Grotesk"', '400 16px "Threadline Geist"',
      '400 13px "Threadline IBM Plex Mono"', '500 13px "Threadline IBM Plex Mono"',
    ];
    const timeline = "/audit/timeline?from=2020-01-01T00%3A00&to=2099-01-01T00%3A00&table=ticket_replies&correlation_id=walk-acme-4521-close";
    const mapping: Record<string, [string, string]> = {
      body: ["text", "bg"], descriptor: ["muted", "bg"], caption: ["muted", "surface"],
      "application-copy": ["text", "surface"], hero: ["accent", "bg"], link: ["accent", "surface"],
      focus: ["border-focus", "bg"], artwork: ["stitch-blue", "bg"],
    };
    const loadFaces = async (target: Page) => target.evaluate(async (requests) => {
      await Promise.allSettled(requests.map((font) => document.fonts.load(font)));
      await document.fonts.ready;
      return Array.from(document.fonts).map((face) => ({ family: face.family.replaceAll('"', ""), weight: face.weight, status: face.status }));
    }, fontRequests);
    await login(page);
    for (const width of [1280, 375]) {
      await page.setViewportSize({ width, height: 900 });
      for (const lane of ["dark", "light"] as const) {
        await page.emulateMedia({ colorScheme: "dark", reducedMotion: "reduce" });
        await page.goto(timeline);
        await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
        if (width === 375) await page.locator(".tl-shell-nav__toggle").click();
        await page.getByRole("button", { name: lane === "dark" ? "Dark" : "Light", exact: true }).click();
        await expect(page.locator(".threadline-ui").first()).toHaveAttribute("data-tl-theme", lane);
        await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
        const faces = await loadFaces(page);
        expect(faces).toHaveLength(disabled ? 0 : 4);
        if (!disabled) expect(faces.every((face) => face.status === "loaded")).toBe(true);
        const roles = await page.evaluate(() => {
          const read = (selector: string) => {
            const node = document.querySelector<HTMLElement>(selector);
            if (!node) throw new Error(`Missing rendered type role ${selector}`);
            const s = getComputedStyle(node);
            return { family: s.fontFamily, size: s.fontSize, weight: s.fontWeight, line: s.lineHeight };
          };
          return { body: read(".threadline-ui"), heading: read("#tl-main h1"), id: read(".tl-ref .tl-secondary-ref"), numeric: Array.from(document.querySelectorAll(".threadline-ui *")).map((node) => getComputedStyle(node).fontVariantNumeric).find((value) => value.includes("tabular-nums")) ?? "missing" };
        });
        expect(roles.body.family).toContain("Threadline Geist");
        expect(roles.body).toMatchObject({ size: "16px", weight: "400" });
        expect(roles.heading.family).toContain("Threadline Familjen Grotesk");
        expect(roles.heading).toMatchObject({ size: "28px", weight: "600" });
        expect(roles.id.family).toContain("Threadline IBM Plex Mono");
        expect(roles.id).toMatchObject({ size: "13px", weight: "400", line: "19.5px" });
        expect(roles.numeric).toContain("tabular-nums");
        const contrastRows = await page.evaluate(({ mapping, pairs, lane }) => {
          const root = document.querySelector(".threadline-ui")!;
          const probe = document.createElement("span");
          probe.style.transitionProperty = "none"; probe.style.animationName = "none"; root.append(probe);
          const rows = pairs.map((pair: any) => {
            const [text, ground] = mapping[pair.id]!;
            probe.style.color = `var(--tl-color-${text})`;
            probe.style.backgroundColor = `var(--tl-color-${ground})`;
            const style = getComputedStyle(probe);
            return { id: pair.id, text: style.color, ground: style.backgroundColor, minimum: pair.minimum, expected: pair[lane], mapping: [text, ground] };
          });
          probe.remove(); return rows;
        }, { mapping, pairs: brand.color.contrastPairs, lane });
        expect(contrastRows.map((row: any) => row.id)).toEqual(["body", "descriptor", "caption", "application-copy", "hero", "link", "focus", "artwork"]);
        for (const row of contrastRows) {
          expect(row.text, `${lane}/${row.id} foreground`).toBe(phase250Rgb(row.expected.text));
          expect(row.ground, `${lane}/${row.id} background`).toBe(phase250Rgb(row.expected.ground));
          expect(phase250Contrast(row.text, row.ground)).toBeGreaterThanOrEqual(row.minimum);
        }
        const home = page.getByRole("link", { name: "Threadline Admin home", exact: true });
        await expect(home).toBeVisible();
        const logo = page.locator(`.tl-topbar__brand-logo--${lane}`);
        await expect(logo).toBeVisible();
        const logoBox = await logo.boundingBox(); expect(logoBox!.width).toBeGreaterThanOrEqual(96);
        const homeBox = await home.boundingBox();
        expect(logoBox!.x).toBeGreaterThanOrEqual(homeBox!.x - 1);
        expect(logoBox!.x + logoBox!.width).toBeLessThanOrEqual(homeBox!.x + homeBox!.width + 1);
        const supplied = readFileSync(join(sourceRoot, `brand/assets/logo/threadline-lockup-${lane}.svg`), "utf8");
        const artwork = await logo.evaluate((element, expected) => {
          const source = new DOMParser().parseFromString(expected, "image/svg+xml").documentElement;
          const paths = (node: Element) => Array.from(node.querySelectorAll("path")).map((p) => [p.getAttribute("d"), p.getAttribute("fill"), p.getAttribute("transform")]);
          return { actualPaths: paths(element), actualPaint: Array.from(element.querySelectorAll("path")).map((path) => getComputedStyle(path).fill), suppliedPaths: paths(source), actualViewBox: element.getAttribute("viewBox"), suppliedViewBox: source.getAttribute("viewBox") };
        }, supplied);
        expect(artwork.actualPaths).toEqual(artwork.suppliedPaths);
        expect(artwork.actualPaint).toEqual(artwork.suppliedPaths.map((path) => phase250Rgb(path[1]!)));
        expect(artwork.actualViewBox).toBe(artwork.suppliedViewBox);
        const copy = page.locator("button[data-tl-copy]").first();
        await phase250FocusByKeyboard(page, copy);
        await expect(copy).toBeFocused();
        await expect.poll(() => copy.evaluate((element) => getComputedStyle(element).outlineWidth)).toBe("2px");
        const focus = await copy.evaluate((element) => ({ color: getComputedStyle(element).outlineColor, visible: element.matches(":focus-visible"), style: getComputedStyle(element).outlineStyle }));
        expect(focus).toEqual({ color: phase250Rgb(brand.color.contrastPairs.find((pair: any) => pair.id === "focus")[lane].text), visible: true, style: "solid" });
        await expectNoHorizontalOverflow(page);
        await capturePhase250GateObservation(page, browser, info, disabled ? "fonts-disabled" : "fonts-loaded", { lane, width, faces, roles, contrastRows, focus, logoWidth: logoBox!.width, contrastBoundary: "scoped semantic-token samples; actual heading/body/ID/logo/focus consumers checked separately" });
        if (!disabled) {
          const fallback = await context.newPage();
          try {
            await fallback.setViewportSize({ width, height: 900 });
            await fallback.route("**/*", allowLocal);
            // Preserve the real loopback document response and LiveView connection.
            // A fulfilled response changes Chromium's local-network classification.
            await fallback.addInitScript(() => {
              const install = () => {
                if (!document.head) return false;
                const policy = document.createElement("meta");
                policy.httpEquiv = "Content-Security-Policy";
                policy.content = "font-src 'none'";
                document.head.prepend(policy);
                return true;
              };
              if (!install()) {
                const observer = new MutationObserver(() => { if (install()) observer.disconnect(); });
                observer.observe(document, { childList: true, subtree: true });
              }
            });
            await fallback.goto(timeline);
            await expect(fallback.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
            await expect(fallback.locator(".threadline-ui").first()).toHaveAttribute("data-tl-theme", lane);
            const blocked = await loadFaces(fallback);
            expect(blocked).toHaveLength(4); expect(blocked.every((face) => face.status === "error")).toBe(true);
            await expect(fallback.getByRole("heading", { name: "Investigate audit activity", exact: true })).toBeVisible();
            await expect(fallback.locator(".tl-ref .tl-secondary-ref").first()).toBeVisible();
            await expectNoHorizontalOverflow(fallback);
            await capturePhase250GateObservation(fallback, browser, info, "fonts-loaded", { lane, width, mode: "test-controlled font-src-none", blockedFaces: blocked, readableFallback: "visible heading, original ID and controls remain in bounded layout" });
          } finally { await fallback.close(); }
        }
      }
    }
    const iconHref = await page.locator('link[rel~="icon"]').first().getAttribute("href");
    expect(iconHref).toBeTruthy(); const iconUrl = new URL(iconHref!, page.url()); expect(iconUrl.origin).toBe(origin);
    const icon = await page.request.get(iconUrl.toString()); expect(icon.ok()).toBe(true);
    const iconBytes = await icon.body();
    expect(iconUrl.pathname).toBe("/images/threadline-admin-favicon.svg");
    const iconHash = createHash("sha256").update(iconBytes).digest("hex");
    expect(iconHash).toBe(createHash("sha256").update(readFileSync(join(sourceRoot, "brand/assets/icon/favicon.svg"))).digest("hex"));
    const markProbe = await page.evaluate(async (url) => {
      const image = new Image(); image.src = url; await image.decode();
      const canvas = document.createElement("canvas"); canvas.width = 16; canvas.height = 16;
      const context = canvas.getContext("2d")!; context.drawImage(image, 0, 0, 16, 16);
      const pixels = context.getImageData(0, 0, 16, 16).data;
      let painted = 0; for (let index = 3; index < pixels.length; index += 4) if (pixels[index]! > 0) painted += 1;
      return { width: canvas.width, height: canvas.height, painted };
    }, iconUrl.toString());
    expect(markProbe.width).toBeGreaterThanOrEqual(16); expect(markProbe.height).toBeGreaterThanOrEqual(16); expect(markProbe.painted).toBeGreaterThan(0);
    await info.attach("phase250-favicon", { body: JSON.stringify({ url: iconUrl.pathname, sha256: iconHash, markProbe, boundary: "linked supplied SVG paints at16px; native browser-tab geometry is not captured" }), contentType: "application/json" });
    expect(externalRequests).toEqual([]);
  });
}

test("Redaction policy comparison stays safe, keyboard-operable, and responsive", async ({ page }) => {
  await login(page);
  await page.goto("/audit/policy/redaction");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);

  const main = page.locator("#tl-main");
  await expect(main.getByRole("heading", { name: "Redaction policy" })).toBeVisible();
  const refresh = main.getByRole("button", { name: "Refresh policy inspection", exact: true });
  await expect(refresh).toBeVisible();
  await expect(
    main.getByRole("region", { name: "Redaction policy posture" }).getByText("Host schema", { exact: true }),
  ).toBeVisible();
  await expect(main.getByText("This inspection compares current deployed trigger definitions only.")).toBeVisible();
  await expect(main.getByText(/does not establish whether historical audit rows or downstream exports were redacted/)).toBeVisible();

  const drift = main.getByTestId("policy-section").filter({ has: page.getByRole("heading", { name: /^Drift detected/ }) });
  const matches = main.getByTestId("policy-section").filter({ has: page.getByRole("heading", { name: /^Config matches deployed/ }) });
  await expect(drift.getByText("ticket_replies", { exact: true })).toBeVisible();
  await expect(matches.getByText("posts", { exact: true })).toBeVisible();

  const posts = main.locator("details").filter({ has: page.getByText("posts", { exact: true }) });
  const summary = posts.locator("summary");
  await summary.focus();
  await page.keyboard.press("Enter");
  await expect(posts).toHaveAttribute("open", "");
  await expect(posts.getByRole("table")).toBeVisible();
  await expect(posts.locator('[data-label="Configured"]').first()).toBeVisible();
  await expect(posts.locator('[data-label="Deployed"]').first()).toBeVisible();

  const rendered = await main.evaluate((element) => {
    const values = [element.textContent ?? ""];
    for (const node of [element, ...Array.from(element.querySelectorAll("*"))]) {
      for (const attribute of Array.from(node.attributes)) values.push(attribute.value);
    }
    return values.join("\n");
  });
  for (const canary of [
    "CREATE OR REPLACE FUNCTION",
    "audit_transactions",
    "raw-trigger-sql-canary-241",
    "sample-value-canary-241",
    "redacted-value-canary-241",
  ]) expect(rendered).not.toContain(canary);
  await expect(main.locator("[data-tl-copy]")).toHaveCount(0);

  await refresh.click();
  await expect(refresh).toBeVisible();
  await expect(posts).toBeVisible();
  await expectNoHorizontalOverflow(page);
});

test("Redaction inspection distinguishes a missing empty-policy trigger from unreadable deployment", async ({ page }) => {
  const partition = process.env.MIX_TEST_PARTITION ?? "";
  expect(partition, "Only the runner-owned numeric example test database may be mutated").toMatch(/^\d*$/);
  expect(process.env.THREADLINE_E2E).toBe("1");
  const sql = (statement: string) => execFileSync("psql", [
    "-X", "-h", process.env.DB_HOST ?? "localhost", "-p", process.env.DB_PORT ?? "5432",
    "-U", "postgres", "-d", `threadline_phoenix_test${partition}`, "-v", "ON_ERROR_STOP=1", "-q", "-c", statement,
  ], { env: { ...process.env, PGPASSWORD: "postgres" }, stdio: "pipe" });
  await login(page);
  const inspect = async () => {
    await page.goto("/audit/policy/redaction?schema=public");
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    return page.locator("details.tl-policy__row").filter({ has: page.getByText("posts", { exact: true }) });
  };
  const original = await inspect();
  await expect(original.getByText("Deployed matches config", { exact: true })).toBeVisible();
  sql("ALTER TRIGGER threadline_audit_posts ON public.posts RENAME TO phase241_saved_posts");
  try {
    const missing = await inspect();
    await expect(missing.getByText("Drift detected", { exact: true })).toBeVisible();
    await expect(missing).toContainText("No deployed Threadline trigger found for configured table.");
    sql(`CREATE FUNCTION public.threadline_phase241_unreadable() RETURNS trigger LANGUAGE plpgsql AS $$
      BEGIN
        -- raw-trigger-sql-canary-241 sample-value-canary-241 redacted-value-canary-241
        RETURN NEW;
      END;
    $$;
    CREATE TRIGGER threadline_audit_phase241_unreadable AFTER INSERT ON public.posts
      FOR EACH ROW EXECUTE FUNCTION public.threadline_phase241_unreadable();`);
    const unreadable = await inspect();
    await expect(unreadable.getByText("Could not inspect", { exact: true })).toBeVisible();
    await expect(page.getByText("Deployed policy could not be inspected. Retry before treating policy as matched.", { exact: true })).toBeVisible();
    await unreadable.locator("summary").focus();
    await page.keyboard.press("Enter");
    await expect(unreadable).toHaveAttribute("open", "");
    const dom = await page.locator("#tl-main").evaluate((element) => element.outerHTML);
    for (const canary of ["raw-trigger-sql-canary-241", "sample-value-canary-241", "redacted-value-canary-241", "RETURN NEW", "CREATE FUNCTION"]) {
      expect(dom).not.toContain(canary);
    }
    await expect(page.locator("#tl-main [data-tl-copy]")).toHaveCount(0);
  } finally {
    sql("DROP TRIGGER IF EXISTS threadline_audit_phase241_unreadable ON public.posts; DROP FUNCTION IF EXISTS public.threadline_phase241_unreadable(); ALTER TRIGGER phase241_saved_posts ON public.posts RENAME TO threadline_audit_posts;");
  }
});

test("theme preference, effective cascade and reduced motion are distinct observed facts", async ({ page, browser }, info) => {
  await page.emulateMedia({ colorScheme: "dark", reducedMotion: "reduce" });
  await login(page);
  if (process.env.THREADLINE_PHASE250_BROWSER_GATE === "theme") {
    const title = "theme preference, effective cascade and reduced motion are distinct observed facts";
    const root = page.locator(".threadline-ui");
    const buttons = root.locator('button[name="theme"]');
    const lightLogo = root.locator(".tl-topbar__brand-logo--light");
    const darkLogo = root.locator(".tl-topbar__brand-logo--dark");
    await page.goto("/audit");
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expect(buttons).toHaveCount(3);
    let currentPreference: "system" | "light" | "dark" = "dark";

    const assertTheme = async (preference: "system" | "light" | "dark", system: "light" | "dark") => {
      await expect(root).toHaveAttribute("data-tl-theme", preference);
      await expect(root.locator('button[name="theme"][aria-pressed="true"]')).toHaveCount(1);
      const selected = root.locator('button[name="theme"][aria-pressed="true"]');
      await expect(selected).toHaveAttribute("value", preference);
      const appearance = await root.evaluate((element) => ({
        stored: (element.querySelector<HTMLButtonElement>('button[name="theme"][aria-pressed="true"]')?.value) ?? "unknown",
        mounted: element.getAttribute("data-tl-theme"),
        effective: getComputedStyle(element).colorScheme,
        system: matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark",
        reduced: matchMedia("(prefers-reduced-motion: reduce)").matches,
      }));
      expect(appearance).toEqual({ stored: preference, mounted: preference, effective: preference === "system" ? system : preference, system, reduced: true });
      const effective = preference === "system" ? system : preference;
      await expect(lightLogo).toHaveCSS("display", effective === "light" ? "block" : "none");
      await expect(darkLogo).toHaveCSS("display", effective === "dark" ? "block" : "none");
      await expect(selected.locator(".tl-theme-picker__selected")).toContainText("Selected");
      await expect(selected).toHaveAccessibleName(preference[0]!.toUpperCase() + preference.slice(1));
      return selected;
    };
    await assertTheme(currentPreference, "dark");

    const diagnosticOutput = process.env.THREADLINE_PHASE250_DIAGNOSTIC_OUTPUT;
    const focusDiagnostics: unknown[] = [];
    const focusCascadeDiagnostics: unknown[] = [];
    const fixtureMarkup = readFileSync(join(paths.repositoryRoot, "test/fixtures/style/operator_surface.css"), "utf8");
    const fixturePrefix = "<style>";
    const fixtureSuffix = "</style>";
    const fixtureBody = fixtureMarkup.startsWith(fixturePrefix) && fixtureMarkup.endsWith(fixtureSuffix)
      ? fixtureMarkup.slice(fixturePrefix.length, -fixtureSuffix.length)
      : null;
    const writeFocusDiagnostics = () => {
      if (diagnosticOutput) {
        writeFileSync(
          diagnosticOutput,
          `${JSON.stringify({ title, route: "/audit", focusDiagnostics, focusCascadeDiagnostics }, null, 2)}\n`,
          { mode: 0o600 },
        );
      }
    };

    const captureFocusDiagnostic = async (target: Locator, phase: "initial" | "settled" = "initial") => {
      const observed = await target.evaluate((element) => {
        const active = document.activeElement;
        const computed = getComputedStyle(element);
        const styleBlocks = Array.from(document.querySelectorAll("style"))
          .filter((style) => style.textContent?.includes(".threadline-ui"))
          .map((style, index) => ({
            index,
            id: style.id || null,
            body: style.textContent ?? "",
            markup: style.outerHTML,
          }));
        const matchedRules: {
          sourceOrigin: string;
          stylesheetIndex: number;
          selector: string;
          conditions: string[];
          declarations: Record<string, string>;
        }[] = [];
        for (let stylesheetIndex = 0; stylesheetIndex < document.styleSheets.length; stylesheetIndex += 1) {
          const sheet = document.styleSheets.item(stylesheetIndex)!;
          const owner = sheet.ownerNode instanceof Element ? sheet.ownerNode : null;
          const sourceOrigin = sheet.href ?? (owner
            ? `${owner.tagName.toLowerCase()}${owner.id ? `#${owner.id}` : `@${stylesheetIndex}`}`
            : `constructed-stylesheet@${stylesheetIndex}`);
          let rules: CSSRuleList;
          try {
            rules = sheet.cssRules;
          } catch {
            continue;
          }
          const visit = (nestedRules: CSSRuleList, conditions: string[]) => {
            for (const rule of Array.from(nestedRules)) {
              if ("selectorText" in rule && typeof rule.selectorText === "string" && "style" in rule) {
                const styleRule = rule as CSSStyleRule;
                let matches = false;
                try {
                  matches = element.matches(styleRule.selectorText);
                } catch {
                  matches = false;
                }
                if (matches) {
                  const properties = ["outline", "outline-width", "outline-style", "outline-color", "outline-offset", "box-shadow"];
                  matchedRules.push({
                    sourceOrigin,
                    stylesheetIndex,
                    selector: styleRule.selectorText,
                    conditions,
                    declarations: Object.fromEntries(properties.map((name) => [name, styleRule.style.getPropertyValue(name).trim()])),
                  });
                }
              }
              const groupingRule = rule as CSSRule & { cssRules?: CSSRuleList; conditionText?: string };
              if (groupingRule.cssRules) {
                const condition = typeof groupingRule.conditionText === "string" ? groupingRule.conditionText : null;
                const active = condition && rule.type === CSSRule.MEDIA_RULE
                  ? window.matchMedia(condition).matches
                  : condition && rule.type === CSSRule.SUPPORTS_RULE
                    ? CSS.supports(condition)
                    : true;
                if (active) visit(groupingRule.cssRules, condition ? [...conditions, condition] : conditions);
              }
            }
          };
          visit(rules, []);
        }
        return {
          route: location.pathname,
          target: {
            tag: element.tagName.toLowerCase(),
            className: typeof element.className === "string" ? element.className : null,
            name: element.getAttribute("name"),
            value: element.getAttribute("value"),
            ariaPressed: element.getAttribute("aria-pressed"),
            active: active === element,
            matchesFocusVisible: element.matches(":focus-visible"),
          },
          activeElement: active instanceof HTMLElement
            ? { tag: active.tagName.toLowerCase(), id: active.id || null, className: active.className || null, name: active.getAttribute("name"), value: active.getAttribute("value") }
            : { tag: active?.nodeName ?? null },
          computed: {
            outlineWidth: computed.outlineWidth,
            outlineStyle: computed.outlineStyle,
            outlineColor: computed.outlineColor,
            outlineOffset: computed.outlineOffset,
            boxShadow: computed.boxShadow,
            focusColorToken: computed.getPropertyValue("--tl-color-border-focus").trim(),
            focusRingToken: computed.getPropertyValue("--tl-focus-ring").trim(),
          },
          inlineStyle: {
            attribute: element.getAttribute("style"),
            outline: element.style.getPropertyValue("outline"),
            outlineWidth: element.style.getPropertyValue("outline-width"),
            outlineStyle: element.style.getPropertyValue("outline-style"),
            outlineColor: element.style.getPropertyValue("outline-color"),
            outlineOffset: element.style.getPropertyValue("outline-offset"),
          },
          styleBlocks,
          matchedRules,
        };
      });
      const blocks = observed.styleBlocks.map((block) => ({
        index: block.index,
        id: block.id,
        bodySha256: createHash("sha256").update(block.body).digest("hex"),
        bodyBytes: Buffer.byteLength(block.body),
        matchesCurrentFixtureBody: fixtureBody !== null && block.body === fixtureBody,
        matchesCurrentFixtureMarkup: block.markup === fixtureMarkup,
      }));
      const record = {
        sequence: focusDiagnostics.length + 1,
        phase,
        source: "mounted browser CSSOM and computed styles",
        fixtureSha256: createHash("sha256").update(fixtureMarkup).digest("hex"),
        fixtureBodySha256: fixtureBody === null ? null : createHash("sha256").update(fixtureBody).digest("hex"),
        ...observed,
        styleBlocks: blocks,
      };
      focusDiagnostics.push(record);
      writeFocusDiagnostics();
      return record;
    };

    const captureFocusCascadeDiagnostic = async (target: Locator, sequence: number) => {
      const elementState = await target.evaluate((element) => ({
        styleAttribute: element.getAttribute("style"),
        animations: element.getAnimations().map((animation) => {
          const effect = animation.effect;
          const timing = effect?.getTiming();
          const computedTiming = effect?.getComputedTiming();
          return {
            playState: animation.playState,
            pending: animation.pending,
            currentTime: animation.currentTime,
            startTime: animation.startTime,
            transitionProperty: "transitionProperty" in animation ? animation.transitionProperty : null,
            timing: timing ? {
              delay: timing.delay,
              duration: timing.duration,
              endDelay: timing.endDelay,
              fill: timing.fill,
              iterationStart: timing.iterationStart,
              iterations: timing.iterations,
              direction: timing.direction,
              easing: timing.easing,
            } : null,
            computedTiming: computedTiming ? {
              progress: computedTiming.progress,
              currentIteration: computedTiming.currentIteration,
              endTime: computedTiming.endTime,
            } : null,
            keyframes: effect?.getKeyframes().map((keyframe) => ({
              outline: keyframe.outline,
              outlineWidth: keyframe.outlineWidth,
              outlineStyle: keyframe.outlineStyle,
              outlineColor: keyframe.outlineColor,
              outlineOffset: keyframe.outlineOffset,
            })) ?? [],
          };
        }),
      }));
      const cdp = await page.context().newCDPSession(page);
      try {
        const sheetSources = new Map<string, string>();
        cdp.on("CSS.styleSheetAdded", ({ header }) => sheetSources.set(header.styleSheetId, header.sourceURL));
        await cdp.send("DOM.enable");
        await cdp.send("CSS.enable");
        const { root: documentNode } = await cdp.send("DOM.getDocument");
        const value = await target.getAttribute("value");
        const { nodeId } = await cdp.send("DOM.querySelector", {
          nodeId: documentNode.nodeId,
          selector: `button[name="theme"][value="${value}"]`,
        });
        if (!nodeId) throw new Error("Could not resolve the focused theme button through Chromium DOM");
        const matched = await cdp.send("CSS.getMatchedStylesForNode", { nodeId });
        const computed = await cdp.send("CSS.getComputedStyleForNode", { nodeId });
        const focusProperties = (properties: Array<{ name: string; value: string; important?: boolean }>) =>
          properties
            .filter(({ name }) => /^(outline(?:-|$)|box-shadow$)/.test(name))
            .map(({ name, value: propertyValue, important }) => ({ name, value: propertyValue, important: Boolean(important) }));
        const matchedRules = (matched.matchedCSSRules ?? []).map(({ rule }) => ({
          origin: rule.origin,
          sourceURL: rule.styleSheetId ? sheetSources.get(rule.styleSheetId) ?? null : null,
          selector: rule.selectorList.text,
          declarations: focusProperties(rule.style.cssProperties),
        })).filter(({ declarations }) => declarations.length > 0);
        const pseudoRules = (matched.pseudoElements ?? []).map(({ pseudoType, matches }) => ({
          pseudoType,
          rules: matches.map(({ rule }) => ({
            origin: rule.origin,
            sourceURL: rule.styleSheetId ? sheetSources.get(rule.styleSheetId) ?? null : null,
            selector: rule.selectorList.text,
            declarations: focusProperties(rule.style.cssProperties),
          })).filter(({ declarations }) => declarations.length > 0),
        })).filter(({ rules }) => rules.length > 0);
        const computedOutline = (computed.computedStyle ?? [])
          .filter(({ name }) => /^(outline(?:-|$)|box-shadow$)/.test(name))
          .map(({ name, value: propertyValue }) => ({ name, value: propertyValue }));
        const diagnostic = {
          sequence,
          source: "Chromium CDP DOM/CSS matched styles",
          elementState,
          inlineStyle: matched.inlineStyle ? focusProperties(matched.inlineStyle.cssProperties) : [],
          attributeStyle: matched.attributesStyle ? focusProperties(matched.attributesStyle.cssProperties) : [],
          matchedRules,
          pseudoRules,
          computedOutline,
        };
        focusCascadeDiagnostics.push(diagnostic);
        writeFocusDiagnostics();
        return diagnostic;
      } finally {
        await cdp.detach();
      }
    };

    const focusByKeyboard = async (target: Locator) => {
      for (let attempts = 0; attempts < 40; attempts += 1) {
        if (await target.evaluate((element) => document.activeElement === element)) break;
        await page.keyboard.press("Tab");
      }
      const initial = await captureFocusDiagnostic(target, "initial");
      const expectedFocus = {
        target: { active: true, matchesFocusVisible: true },
        computed: { outlineWidth: "2px", outlineStyle: "solid", outlineOffset: "2px" },
      };
      const isSettled = initial.target.active && initial.target.matchesFocusVisible &&
        initial.computed.outlineWidth === "2px" && initial.computed.outlineStyle === "solid" &&
        initial.computed.outlineOffset === "2px";
      if (isSettled) return;

      await captureFocusCascadeDiagnostic(target, initial.sequence);
      await expect.poll(async () => target.evaluate((element) => {
        const computed = getComputedStyle(element);
        return {
          target: {
            active: document.activeElement === element,
            matchesFocusVisible: element.matches(":focus-visible"),
          },
          computed: {
            outlineWidth: computed.outlineWidth,
            outlineStyle: computed.outlineStyle,
            outlineOffset: computed.outlineOffset,
          },
        };
      }), { timeout: 3000, intervals: [50, 100, 250, 500] }).toMatchObject(expectedFocus);
      const settled = await captureFocusDiagnostic(target, "settled");
      expect(settled).toMatchObject(expectedFocus);
    };

    const activate = async (preference: "system" | "light" | "dark", system: "light" | "dark") => {
      await page.emulateMedia({ colorScheme: system, reducedMotion: "reduce" });
      await assertTheme(currentPreference, system);
      const target = root.locator(`button[name="theme"][value="${preference}"]`);
      await expect(target).toBeEnabled();
      await focusByKeyboard(target);
      await page.keyboard.press("Enter");
      await expect(root).toHaveAttribute("data-tl-theme", preference);
      await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
      await assertTheme(preference, system);
      currentPreference = preference;
      const current = root.locator(`button[name="theme"][value="${preference}"]`);
      await focusByKeyboard(current);
      return current;
    };

    const defaultTheme = await activate("dark", "dark");
    expect(await defaultTheme.getAttribute("aria-label")).toBe("Dark");
    await activate("light", "dark");
    await activate("dark", "light");
    await activate("system", "dark");
    await activate("system", "light");
    await page.reload();
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await assertTheme("system", "light");
    await focusByKeyboard(root.locator('button[name="theme"][value="system"]'));

    await page.setViewportSize({ width: 375, height: 812 });
    const disclosure = page.locator(".tl-shell-nav__disclosure");
    await disclosure.locator("summary").click();
    await expect(disclosure).toHaveAttribute("open", "");
    for (const button of await buttons.all()) await expect(button).toBeVisible();
    await expect(root.locator('button[name="theme"][aria-pressed="true"]')).toBeVisible();
    const narrow = await page.evaluate(() => ({ viewport: document.documentElement.clientWidth, document: document.documentElement.scrollWidth }));
    expect(narrow.document - narrow.viewport).toBeLessThanOrEqual(1);
    const choiceBounds = await root.locator('button[name="theme"][aria-pressed="true"]').evaluate((element) => {
      const rect = element.getBoundingClientRect();
      return { left: rect.left, right: rect.right, width: rect.width, clientWidth: (element as HTMLElement).clientWidth, scrollWidth: (element as HTMLElement).scrollWidth };
    });
    expect(choiceBounds.left).toBeGreaterThanOrEqual(0);
    expect(choiceBounds.right).toBeLessThanOrEqual(376);
    expect(choiceBounds.scrollWidth).toBeLessThanOrEqual(choiceBounds.clientWidth + 1);
    const observation = await capturePhase250GateObservation(page, browser, info, "theme");
    expect(observation.condition).toMatchObject({ preference: "system", mountedTheme: "system", effectiveTheme: "light", systemScheme: "light", reducedMotion: true, browserZoom: "unverified" });
    expect(observation.assets.fontFaceCount).toBe(4);
    expect(observation.assets.fontFaces).toHaveLength(4);
    expect(observation.route).toBe("/audit");
    expect(info.title).toBe(title);
    return;
  }
  const e = await startEvidence(page, browser, info);
  await page.goto("/audit");
  const light = info.project.name === "desktop-chromium-light";
  const reducedDuration = await page.locator(".tl-home__card").first().evaluate((el) => getComputedStyle(el).animationDuration);
  expect(reducedDuration).toBe("0.001s");
  const initial = await e.capture("state.theme.initial", "/audit", "initial-theme", { reducedDuration });
  expect(initial.mountedTheme).toBe(light ? "system" : "dark");
  expect(initial.preference).toBe(light ? "system" : "dark");
  expect(initial.effectiveTheme).toBe(light ? "light" : "dark");
  expect(initial.background).toBe(light ? "rgb(247, 249, 252)" : "rgb(11, 16, 32)");
  expect(initial.reducedMotion).toBe(true);
  expect(initial.resolvedValues["--tl-color-bg"]).toBeTruthy();
  for (const preference of ["light", "dark", "system"]) {
    await page.locator(`button[name="theme"][value="${preference}"]`).focus();
    await page.keyboard.press("Enter");
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expect(page.locator(".threadline-ui")).toHaveAttribute("data-tl-theme", preference);
    const observed = await e.capture(`state.theme.${preference}`, "/audit", `preference-${preference}`);
    expect(observed.preference).toBe(preference);
    expect(observed.effectiveTheme).toBe(preference === "system" ? (observed.osLight ? "light" : "dark") : preference);
  }
  e.finish("state.theme", "/audit", "theme-and-motion");
});

for (const [name, path] of [["Evidence", "/audit/evidence"], ["Exports", "/audit/exports?table=tickets&correlation_id=walk-acme-4521-close"], ["Retention", "/audit/policy/retention"]]) {
  test(`fresh direct-entry Copy on ${name}: completion or binding failure is observed`, async ({ page, context, browser }, info) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    await login(page);
    const e = await startEvidence(page, browser, info);
    // No prior operator navigation in this context may preload delegated handlers.
    await page.goto(path);
    const copy = page.locator("button[data-tl-copy]").first();
    await expect(copy).toBeVisible();
    const value = await copy.getAttribute("data-tl-copy");
    expect(value).toBeTruthy();
    await page.evaluate(() => navigator.clipboard.writeText("threadline-evidence-sentinel"));
    await copy.click();
    const observed = await page.evaluate(async () => ({ clipboardMatches: await navigator.clipboard.readText() !== "threadline-evidence-sentinel", handlerBound: Boolean((window as any).__tlCopyBound), copiedFeedback: Boolean(document.querySelector("button[data-tl-copy].is-copied")) }));
    const clipboard = await page.evaluate(() => navigator.clipboard.readText());
    const exactMatch = clipboard === value;
    await e.capture(`state.copy.${name.toLowerCase()}`, path, exactMatch ? "copy-completed" : "copy-did-not-complete", { ...observed, exactMatch, rank: exactMatch ? "covered" : "high", ownerPhase: 242, deniedClipboardLimitation: !observed.handlerBound ? "No handler attempts clipboard access on fresh entry; denial handling cannot be exercised through this control." : "Browser permission failure is probed separately on the bound Timeline control." });
    e.finish(`state.copy.${name.toLowerCase()}`, path, exactMatch ? "copy-completed" : "copy-did-not-complete");
  });
}

test("bound Timeline Copy observes exact completion and real denied permission separately", async ({ page, context, browser }, info) => {
  await context.grantPermissions(["clipboard-read", "clipboard-write"]);
  await login(page);
  const e = await startEvidence(page, browser, info);
  await page.goto("/audit/timeline?correlation_id=walk-acme-4521-close");
  const copy = page.locator("button[data-tl-copy]").first();
  await expect(copy).toBeVisible();
  const expected = await copy.getAttribute("data-tl-copy");
  await copy.click();
  await expect.poll(() => page.evaluate(() => navigator.clipboard.readText())).toBe(expected);
  await e.capture("state.clipboard.completed", "/audit/timeline", "copy-completed", { exactMatch: true });
  const cdp = await context.newCDPSession(page);
  await context.clearPermissions();
  const { targetInfo } = await cdp.send("Target.getTargetInfo");
  await cdp.send("Browser.setPermission", { permission: { name: "clipboard-write", allowWithoutSanitization: true }, setting: "denied", origin: new URL(page.url()).origin, browserContextId: targetInfo.browserContextId });
  const permission = await page.evaluate(async () => (await navigator.permissions.query({ name: "clipboard-write" as PermissionName })).state);
  await copy.click();
  await e.capture("state.clipboard.denied", "/audit/timeline", permission === "denied" ? "clipboard-permission-denied" : "clipboard-denial-probe-unavailable", { permission, copiedFeedback: await copy.evaluate((el) => el.classList.contains("is-copied")), limitation: permission === "denied" ? "Legacy execCommand fallback may succeed despite Clipboard API denial; this is not proof of failed fallback or truthful failure feedback." : "This Chromium context does not report denied after permission clear and context-specific Browser.setPermission denied. Actual clipboard denial remains unverified; no denial pass claimed." });
  e.finish("state.clipboard", "/audit/timeline", "clipboard-completed-and-denial-probe");
});

test("Clipboard success waits for confirmation on direct entry and after patches", async ({ page }) => {
  await page.addInitScript(() => {
    const probe = {
      calls: [] as Array<{ value: string; userActivation: boolean }>,
      fallbackCalls: 0,
      pending: [] as Array<() => void>,
      resolveNext() {
        this.pending.shift()?.();
      },
    };
    (window as any).__threadlineCopyProbe = probe;
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: {
        writeText(value: string) {
          probe.calls.push({ value, userActivation: (navigator as any).userActivation?.isActive === true });
          return new Promise<void>((resolve) => probe.pending.push(resolve));
        },
      },
    });
    document.execCommand = () => { probe.fallbackCalls += 1; return false; };
  });

  await login(page);
  await page.goto("/audit/timeline?correlation_id=walk-acme-4521-close");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);

  const copy = page.locator("button[data-tl-copy]").first();
  await expect(copy).toBeVisible();
  const expected = await copy.getAttribute("data-tl-copy");
  expect(expected).toBeTruthy();
  await phase250FocusByKeyboard(page, copy);
  await page.keyboard.press("Enter");

  const status = copyStatus(copy);
  await expect(status).toHaveText("Copying…");
  expect(await copy.evaluate((element) => element.classList.contains("is-copied"))).toBe(false);
  expect(await page.evaluate(() => (window as any).__threadlineCopyProbe.calls)).toEqual([
    { value: expected, userActivation: true },
  ]);

  await page.evaluate(() => (window as any).__threadlineCopyProbe.resolveNext());
  await expect(status).toHaveText("Copied.");
  await expect(copy).toHaveClass(/is-copied/);
  await expect(copy).toBeFocused();
  expect(await page.evaluate(() => (window as any).__threadlineCopyProbe.fallbackCalls)).toBe(0);

  await page.locator("#filter-table").fill("ticket_replies");
  await page.locator("#timeline-filters").getByRole("button", { name: "Apply", exact: true }).click();
  await expect(page).toHaveURL(/table=ticket_replies/);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);

  const patchedCopy = page.locator("button[data-tl-copy]").first();
  const patchedExpected = await patchedCopy.getAttribute("data-tl-copy");
  await phase250FocusByKeyboard(page, patchedCopy);
  await page.keyboard.press("Enter");
  const patchedStatus = copyStatus(patchedCopy);
  await expect(patchedStatus).toHaveText("Copying…");
  expect(await page.evaluate(() => (window as any).__threadlineCopyProbe.calls)).toHaveLength(2);
  await page.evaluate(() => (window as any).__threadlineCopyProbe.resolveNext());
  await expect(patchedStatus).toHaveText("Copied.");
  await expect(patchedCopy).toBeFocused();
  await expect(page.locator("textarea[data-tl-copy-fallback]")).toHaveCount(0);
  expect(await page.evaluate(() => (window as any).__threadlineCopyProbe.calls[1])).toEqual({
    value: patchedExpected,
    userActivation: true,
  });
});

test("Clipboard failure shows manual recovery without claiming success", async ({ page }) => {
  await page.addInitScript(() => {
    const probe = { fallbackCalls: 0 };
    (window as any).__threadlineCopyProbe = probe;
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { writeText: () => Promise.reject(new DOMException("denied", "NotAllowedError")) },
    });
    document.execCommand = () => {
      probe.fallbackCalls += 1;
      return false;
    };
  });

  await login(page);
  await page.goto("/audit/timeline?correlation_id=walk-acme-4521-close");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  const copy = page.locator("button[data-tl-copy]").first();
  await expect(copy).toBeVisible();
  const expected = await copy.getAttribute("data-tl-copy");
  await phase250FocusByKeyboard(page, copy);
  await page.keyboard.press("Enter");

  const status = copyStatus(copy);
  await expect(status).toHaveText("Copy failed. Select the value and copy it manually.");
  await expect(status).toHaveAttribute("role", "status");
  await expect(status).toHaveAttribute("aria-live", "polite");
  await expect(copy).not.toHaveClass(/is-copied/);
  await expect(copy).toBeFocused();
  expect(await page.evaluate(() => (window as any).__threadlineCopyProbe.fallbackCalls)).toBe(1);
  await expect(page.locator("textarea[data-tl-copy-fallback]")).toHaveCount(0);
  await expect(status).not.toContainText(expected ?? "");
});

test("Clipboard fallback confirms success and restores focus and selection", async ({ page }) => {
  await page.addInitScript(() => {
    const probe = { fallbackCalls: 0, values: [] as string[] };
    (window as any).__threadlineCopyProbe = probe;
    Object.defineProperty(navigator, "clipboard", { configurable: true, value: undefined });
    document.execCommand = () => {
      probe.fallbackCalls += 1;
      probe.values.push((document.activeElement as HTMLTextAreaElement).value);
      return true;
    };
  });

  await login(page);
  await page.goto("/audit/timeline?correlation_id=walk-acme-4521-close");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  const source = page.locator(".tl-ref .tl-secondary-ref").first();
  await expect(source).toBeVisible();
  const selected = await source.evaluate((element) => {
    const range = document.createRange();
    range.selectNodeContents(element);
    const selection = window.getSelection()!;
    selection.removeAllRanges();
    selection.addRange(range);
    return range.toString();
  });
  expect(selected).not.toBe("");
  await page.evaluate(() => new Promise<void>((resolve) => requestAnimationFrame(() => requestAnimationFrame(() => resolve()))));
  await expect.poll(() => page.evaluate(() => window.getSelection()?.toString())).toBe(selected);

  const copy = source.locator("xpath=..").locator("button[data-tl-copy]").first();
  await phase250FocusByKeyboard(page, copy);
  await source.evaluate((element) => {
    const range = document.createRange(); range.selectNodeContents(element);
    const selection = window.getSelection()!; selection.removeAllRanges(); selection.addRange(range);
  });
  await page.keyboard.press("Enter");
  await expect(copyStatus(copy)).toHaveText("Copied.");
  await expect(copy).toBeFocused();
  expect(await page.evaluate(() => (window as any).__threadlineCopyProbe.values)).toEqual([await copy.getAttribute("data-tl-copy")]);
  await expect.poll(() => page.evaluate(() => window.getSelection()?.toString())).toBe(selected);
  expect(await page.evaluate(() => (window as any).__threadlineCopyProbe.fallbackCalls)).toBe(1);
  await expect(page.locator("textarea[data-tl-copy-fallback]")).toHaveCount(0);
});

test("Copy feedback fits long URLs and redacted values stay non-copyable", async ({ page }) => {
  await page.addInitScript(() => {
    (window as any).__threadlineLongCopyValues = [];
    document.execCommand = () => false;
    Object.defineProperty(navigator, "clipboard", {
      configurable: true,
      value: { writeText: (value: string) => { (window as any).__threadlineLongCopyValues.push(value); return Promise.resolve(); } },
    });
  });

  await login(page);
  for (const width of [1280, 375]) {
    await page.setViewportSize({ width, height: 900 });
  const correlation = `copy-long-${"x".repeat(180)}`;
  const appliedUrl = `/audit/timeline?table=ticket_replies&correlation_id=${encodeURIComponent(correlation)}`;
  await page.goto(appliedUrl);
  await page.getByRole("button", { name: "Filters", exact: true }).click();
  const drawer = page.getByRole("dialog", { name: "Filters and handoff" });
  const copySearch = drawer.getByRole("button", { name: "Copy search URL", exact: true });
  await expect(copySearch).toHaveAttribute("data-tl-copy", appliedUrl);
  await expect(copyStatus(copySearch)).toHaveCount(1);
  await phase250FocusByKeyboard(page, copySearch);
  await page.keyboard.press("Enter");
  const status = copyStatus(copySearch);
  await expect(status).toHaveText("Copied.");
  await expectNoHorizontalOverflow(page);

  const geometry = await page.evaluate(() => {
    const button = document.querySelector('button[aria-label="Copy search URL"]')!;
    const status = button.parentElement!.querySelector<HTMLElement>("[data-tl-copy-status]")!;
    const buttonRect = button.getBoundingClientRect();
    const statusRect = status.getBoundingClientRect();
    return {
      overlaps: buttonRect.left < statusRect.right && buttonRect.right > statusRect.left && buttonRect.top < statusRect.bottom && buttonRect.bottom > statusRect.top,
      statusInsideViewport: statusRect.left >= 0 && statusRect.right <= document.documentElement.clientWidth + 1,
      statusText: status.textContent,
    };
  });
  expect(geometry.overlaps).toBe(false);
  expect(geometry.statusInsideViewport).toBe(true);
  expect(geometry.statusText).toBe("Copied.");

  await page.goto("/audit/timeline?correlation_id=walk-acme-4521-close");
  await page.getByTestId("timeline-row").first().getByTestId("transaction-link").click();
  const reference = page.locator(".tl-ref").filter({ has: page.locator("button[data-tl-copy]") }).first();
  const referenceCopy = reference.locator("button[data-tl-copy]").first();
  await expect(referenceCopy).toBeVisible();
  await phase250FocusByKeyboard(page, referenceCopy);
  await page.keyboard.press("Enter");
  await expect(copyStatus(referenceCopy)).toHaveText("Copied.");
  await expectNoHorizontalOverflow(page);
  const referenceGeometry = await reference.evaluate((element) => {
    const value = element.querySelector(".tl-secondary-ref")!;
    const button = element.querySelector("button[data-tl-copy]")!;
    const status = element.querySelector<HTMLElement>("[data-tl-copy-status]")!;
    const rect = (node: Element) => node.getBoundingClientRect();
    const valueRect = rect(value);
    const buttonRect = rect(button);
    const statusRect = rect(status);
    const overlaps = (a: DOMRect, b: DOMRect) => a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top;
    return {
      overlapsValue: overlaps(valueRect, statusRect),
      overlapsButton: overlaps(buttonRect, statusRect),
      statusInsideViewport: statusRect.left >= 0 && statusRect.right <= document.documentElement.clientWidth + 1,
    };
  });
  expect(referenceGeometry).toEqual({ overlapsValue: false, overlapsButton: false, statusInsideViewport: true });

  await page.goto("/audit/timeline?table=ticket_replies");
  const redactedUpdate = page
    .getByTestId("timeline-row")
    .filter({ hasText: "UPDATE" })
    .filter({ hasText: "ticket_replies" })
    .first();
  await redactedUpdate.getByTestId("transaction-link").click();
  const redacted = page.locator(".tl-value--redacted").first();
  await expect(redacted).toBeVisible();
  const cell = redacted.locator("xpath=ancestor::div[contains(@class, 'tl-diff__cell')]");
  await expect(cell.locator("[data-tl-copy]")).toHaveCount(0);
  await expect(page.locator('button[data-tl-copy="[REDACTED]"]')).toHaveCount(0);
  await expect(page.locator("#tl-main")).not.toContainText("Internal: route to tier-2");
  await expect(page.locator("#tl-main")).not.toContainText("Confirmed tier-2 resolved. Closing.");
  await expect(
    page.locator("[data-tl-copy-status]").filter({ hasText: "Internal: route to tier-2" }),
  ).toHaveCount(0);
  // Supported long string ActorRef with no recorded actions; no row or action is invented.
  const expectedLongId = "svc-long-" + "x".repeat(180);
  await page.goto(`/audit/actors/service_account/${encodeURIComponent(expectedLongId)}`);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  const values = await page.locator("button[data-tl-copy]").evaluateAll((nodes) => nodes.map((node) => node.getAttribute("data-tl-copy")));
  const longIndex = values.indexOf(expectedLongId); expect(longIndex).toBeGreaterThanOrEqual(0);
  const longCopy = page.locator("button[data-tl-copy]").nth(longIndex);
  await phase250FocusByKeyboard(page, longCopy); await page.keyboard.press("Enter");
  await expect(copyStatus(longCopy)).toHaveText("Copied."); await expect(longCopy).toBeFocused();
  expect(await page.evaluate(() => (window as any).__threadlineLongCopyValues.at(-1))).toBe(expectedLongId);
  await expectNoHorizontalOverflow(page);

  }
});

test("Exports seeded pending, failed, completed, unavailable and invalid context stay distinct", async ({ page, browser }, info) => {
  await login(page);
  // Required CI exercises the seeded read-only states without writing evidence artifacts.
  // The bounded evidence lane still captures the same states when explicitly enabled.
  const evidence = process.env.THREADLINE_E2E_EVIDENCE === "1"
    ? await startEvidence(page, browser, info)
    : undefined;
  await page.goto("/audit/exports");
  const jobs = page.getByTestId("export-jobs");
  for (const heading of ["Ready to hand off", "Preparing", "Needs attention", "Unavailable"]) await expect(jobs.getByRole("heading", { name: heading, exact: true })).toBeVisible();
  await expect(jobs.getByText("Export failed.").first()).toBeVisible();
  await expect(jobs.getByRole("link", { name: "Download export" }).first()).toBeVisible();
  if (evidence) await evidence.capture("state.exports.seeded", "/audit/exports", "seeded-pending-failed-completed-unavailable", { stateSource: "Demo.Seed.Exports synthetic jobs; not a newly completed mutation" });
  await page.goto("/audit/exports?subject_type=invalid&subject_ref_json=%7B");
  await expect(page.locator("#tl-main [role=alert]").first()).toBeVisible();
  if (evidence) {
    await evidence.capture("state.exports.invalid", "/audit/exports?subject_type=invalid&subject_ref_json=%7B", "invalid-context-alert");
    evidence.finish("state.exports", "/audit/exports", "seeded-status-and-invalid-context");
  }
});

test("Timeline export reaches protected download and returns to its committed search", async ({ page }) => {
  await login(page);
  const correlation = "walk-acme-4521-close";
  const sourcePath = `/audit/timeline?table=ticket_replies&correlation_id=${correlation}`;
  await page.goto(sourcePath);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect(page.locator("#timeline-filters")).toBeVisible();

  await page.getByRole("button", { name: "Filters", exact: true }).click();
  await page.getByRole("button", { name: "Export changes", exact: true }).click();
  await expect(page).toHaveURL(/\/audit\/exports(?:\?|$)/);
  await expect(page.getByText("Export queued. You can follow its status here.", { exact: true })).toBeVisible();

  const jobs = page.getByTestId("export-jobs");
  const sourceReturn = jobs.getByRole("link", { name: "Reopen source search", exact: true }).first();
  await expect(sourceReturn).toHaveAttribute("href", `/audit/timeline?table=ticket_replies&correlation_id=${correlation}`);
  const download = jobs.getByRole("link", { name: "Download export", exact: true }).first();
  await expect(download).toBeVisible({ timeout: 60_000 });
  await expect(download).toHaveAttribute("target", "_blank");

  const downloadPath = await download.getAttribute("href");
  expect(downloadPath).toMatch(/^\/audit\/exports\/download\/[0-9a-f-]+$/i);
  const response = await page.request.get(downloadPath!);
  expect(response.status()).toBe(200);
  expect(response.headers()["content-disposition"]).toContain("attachment;");

  await sourceReturn.click();
  await expect.poll(() => new URL(page.url()).pathname).toBe("/audit/timeline");
  const returned = new URL(page.url());
  expect(returned.searchParams.get("table")).toBe("ticket_replies");
  expect(returned.searchParams.get("correlation_id")).toBe(correlation);
  expect([...returned.searchParams.keys()].sort()).toEqual(["correlation_id", "table"]);
});

test("Evidence keeps selected subject/reference through latest and proof-history navigation", async ({ page, browser }) => {
  await login(page);
  await page.goto("/audit/evidence");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);

  const latestCard = page
    .locator(".tl-record-card")
    .filter({ has: page.locator('code[title*="walk-retention-offboarded-co"]') });
  await expect(latestCard).toHaveCount(1);
  const referenceCode = latestCard.locator("code.tl-secondary-ref");
  const selectedReference = await referenceCode.getAttribute("data-tl-copy");
  expect(selectedReference).not.toBeNull();
  expect(JSON.parse(selectedReference!).run_id).toBe("walk-retention-offboarded-co");

  const latestLabels = latestCard.locator(".tl-record-card__title > span");
  await expect(latestLabels.nth(0)).toHaveText("Proven");
  await expect(latestLabels.nth(1)).toHaveText("Completed");
  const history = latestCard.getByRole("link", { name: "View proof history", exact: true });
  const historyHref = await history.getAttribute("href");
  expect(historyHref).not.toBeNull();
  const expectedRoute = new URL(historyHref!, "http://127.0.0.1");
  expect(expectedRoute.pathname).toBe("/audit/evidence");
  expect(expectedRoute.searchParams.get("subject")).toBe("retention_run");
  expect(expectedRoute.searchParams.get("subject_ref_json")).toBe(selectedReference);
  expect(expectedRoute.searchParams.get("mode")).toBe("history");

  await history.click();
  await expect.poll(() => page.url()).toMatch(/\/audit\/evidence\?.*mode=history/);
  await expect(page.getByText("Viewing append-only proof history for one evidence subject reference.")).toBeVisible();
  await expect(page.locator(".tl-evidence__workflow-summary code.tl-secondary-ref")).toHaveAttribute("data-tl-copy", selectedReference!);
  const historyLabels = await page.locator(".tl-record-card__title").allTextContents();
  const normalizedLabels = historyLabels.map((label) => label.replace(/\s+/g, " ").trim());
  expect(normalizedLabels).toEqual(expect.arrayContaining(["Proven Completed", "Proven Running", "Proven Queued"]));
  await expect(page.getByTestId("evidence-claim-boundary")).toContainText("recorded snapshot");
  await expect(page.getByTestId("evidence-claim-boundary")).toContainText("do not establish overall capture completeness");

  const renderedHistory = await page.locator("#tl-main").evaluate((root) => {
    const values = [root.textContent ?? ""];
    for (const element of [root, ...Array.from(root.querySelectorAll("*"))]) {
      for (const attribute of Array.from(element.attributes)) values.push(attribute.value);
    }
    return values.join("\n");
  });
  for (const unapprovedDetail of [
    "org Y offboard",
    "Export artifact written and checksum verified.",
    "Destination unreachable during the demo window; delivery unverifiable.",
  ]) {
    expect(renderedHistory).not.toContain(unapprovedDetail);
  }

  const longReference = { run_id: `missing-evidence-${"x".repeat(140)}` };
  const serializedLongReference = JSON.stringify(longReference);
  await page.goto(`/audit/evidence?subject=retention_run&subject_ref_json=${encodeURIComponent(serializedLongReference)}`);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect(page.getByRole("heading", { name: "No Threadline evidence for this selection", exact: true })).toBeVisible();
  await expect(page.getByRole("status").filter({ hasText: "No evidence was recorded for this subject and reference. This does not establish whether other activity occurred." })).toBeVisible();
  const selectedContext = page.locator(".tl-evidence__workflow-summary code.tl-secondary-ref");
  await expect(selectedContext).toHaveAttribute("title", serializedLongReference);
  await expect(selectedContext).toHaveAttribute("data-tl-copy", serializedLongReference);
  await expect(page.locator(".tl-record-card")).toHaveCount(0);
  await expectNoHorizontalOverflow(page);

  const supportContext = await browser.newContext({
    baseURL: new URL(page.url()).origin,
    viewport: page.viewportSize() ?? { width: 1280, height: 900 },
    reducedMotion: "reduce",
  });
  try {
    const support = await supportContext.newPage();
    await login(support, "support@acme.example.com");
    await support.goto("/audit/evidence");
    await expect(support.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expect(support.getByRole("heading", { name: "Evidence unavailable", exact: true })).toBeVisible();
    await expect(support.locator("#tl-main")).toContainText("Evidence is unavailable in this support lane");
    await expect(support.locator("#tl-main")).toContainText("This is not a permissions issue.");
    await expect(support.locator("#tl-main")).not.toContainText("No Threadline evidence for this selection");
    await expect(support.locator("#tl-main")).not.toContainText("Evidence is unavailable for this selection. Retry the read");
  } finally {
    await supportContext.close();
  }
});

test("Timeline delayed query exposes pending then real empty result with a long unbroken filter", async ({ page, browser }, info) => {
  let hold = false;
  let held: { server: WebSocketRoute; message: string | Buffer } | undefined;
  await page.routeWebSocket(/\/live\/websocket/, (ws) => {
    const server = ws.connectToServer();
    ws.onMessage((message) => {
      if (hold && String(message).includes('"event"')) held = { server, message };
      else server.send(message);
    });
  });
  await login(page);
  const e = process.env.THREADLINE_E2E_EVIDENCE === "1" ? await startEvidence(page, browser, info) : undefined;
  await page.goto("/audit/timeline");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  const longTable = "unmatched_table_" + "t".repeat(210);
  const longCorrelation = "unmatched_correlation_" + "x".repeat(210);
  const tableFilter = page.locator("#filter-table");
  const correlationFilter = page.locator("#filter-correlation-id");
  await tableFilter.fill(longTable);
  await correlationFilter.fill(longCorrelation);
  hold = true;
  await page.locator("#timeline-filters").getByRole("button", { name: "Apply", exact: true }).click();
  await expect.poll(() => Boolean(held)).toBe(true);
  await expect(page.locator("#timeline-filters")).toHaveClass(/phx-submit-loading/);
  await expect(page.locator("#timeline-filters").getByRole("button", { name: "Applying filters…", exact: true })).toBeVisible();
  if (e) await e.capture("state.timeline.pending", "/audit/timeline", "delayed-query-pending", { requestHeld: true, longTableLength: longTable.length, longCorrelationLength: longCorrelation.length, priorDataRetained: await page.getByTestId("timeline-row").count() });
  hold = false;
  held!.server.send(held!.message);
  await expect(page.locator("#timeline-filters")).not.toHaveClass(/phx-submit-loading/);
  await expect(page.getByTestId("timeline-row")).toHaveCount(0);
  await expect(page.getByRole("heading", { name: "No changes match these filters", exact: true })).toBeVisible();
  await expect(page.locator("#tl-main")).toContainText("Try a wider date range or adjust the filters, then apply again.");
  await expect(page.locator(".tl-timeline-fact").filter({ hasText: "Matching changes" })).toContainText("0");
  await expect(page.locator("nav.tl-pager")).toHaveCount(0);
  await expect(tableFilter).toHaveValue(longTable);
  await expect(correlationFilter).toHaveValue(longCorrelation);
  expect(longTable).toHaveLength(226);
  expect(longCorrelation).toHaveLength(232);
  await page.setViewportSize({ width: 1280, height: 900 });
  const controlsFit = async () => page.evaluate(() => {
    const form = document.querySelector<HTMLElement>("#timeline-filters")!;
    const viewportWidth = window.innerWidth;
    const controls = Array.from(form.querySelectorAll<HTMLElement>("input, button, a"));
    return {
      shellFits: document.documentElement.scrollWidth <= viewportWidth,
      controls: controls.map((control) => {
        const rect = control.getBoundingClientRect();
        return { visible: rect.width > 0 && rect.height > 0, inside: rect.left >= 0 && rect.right <= viewportWidth };
      }),
    };
  });
  const desktopControls = await controlsFit();
  expect(desktopControls.shellFits).toBe(true);
  expect(desktopControls.controls.every((control) => control.visible && control.inside)).toBe(true);
  await page.setViewportSize({ width: 375, height: 900 });
  const narrowControls = await controlsFit();
  expect(narrowControls.shellFits).toBe(true);
  expect(narrowControls.controls.every((control) => control.visible && control.inside)).toBe(true);
  await expect(tableFilter).toBeVisible();
  await expect(correlationFilter).toBeVisible();
  await expect(tableFilter).toHaveValue(longTable);
  await expect(correlationFilter).toHaveValue(longCorrelation);
  if (e) {
    await e.capture("state.timeline.empty-long", "/audit/timeline", "empty-long-filter-narrow", { longTableLength: longTable.length, longCorrelationLength: longCorrelation.length, fullValuesRetained: await tableFilter.inputValue() === longTable && await correlationFilter.inputValue() === longCorrelation });
    e.finish("state.timeline", "/audit/timeline", "delayed-empty-long-value");
  }
});

test("Timeline keeps populated query identity while an applied replacement is pending", async ({ page }) => {
  let hold = false;
  let held: { server: WebSocketRoute; message: string | Buffer } | undefined;
  await page.routeWebSocket(/\/live\/websocket/, (ws) => {
    const server = ws.connectToServer();
    ws.onMessage((message) => {
      if (hold && String(message).includes('"event"')) held = { server, message };
      else server.send(message);
    });
  });

  await login(page);
  const queryA = "walk-acme-4521-close";
  await page.goto(`/audit/timeline?from=2020-01-01T00%3A00&to=2099-01-01T00%3A00&table=ticket_replies&correlation_id=${queryA}`);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect(page.getByTestId("timeline-row")).toHaveCount(1);
  await expect(page.getByTestId("timeline-row").first()).toBeVisible();
  const queryARowCount = await page.getByTestId("timeline-row").count();
  expect(queryARowCount).toBe(1);
  await expect(page.locator(".tl-timeline-fact").filter({ hasText: "Matching changes" })).toContainText("1");
  await expect(page.locator(".tl-filter-summary")).toContainText(queryA);
  await expect(page.locator("#filter-table")).toHaveValue("ticket_replies");
  await expect(page.locator("#filter-from")).toHaveValue("2020-01-01T00:00");
  await expect(page.locator("#filter-to")).toHaveValue("2099-01-01T00:00");
  const transactionHref = await page.getByTestId("transaction-link").getAttribute("href");
  expect(transactionHref).toMatch(/^\/audit\/transactions\/[^/?]+$/);
  await page.setViewportSize({ width: 1280, height: 900 });
  const desktopOverflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
  expect(desktopOverflow).toBe(false);

  const queryB = "timeline-query-b-" + "x".repeat(215);
  expect(queryB).toHaveLength(232);
  await page.locator("#filter-correlation-id").fill(queryB);
  hold = true;
  const apply = page.locator("#timeline-filters").getByRole("button", { name: "Apply", exact: true });
  await apply.click();
  await expect.poll(() => Boolean(held)).toBe(true);

  await expect(page.locator("#timeline-filters")).toHaveClass(/phx-submit-loading/);
  await expect(page.locator("#timeline-filters").getByRole("button", { name: "Applying filters…", exact: true })).toBeVisible();
  await expect(page.getByTestId("timeline-row")).toHaveCount(queryARowCount);
  await expect(page.getByTestId("transaction-link")).toHaveAttribute("href", transactionHref!);
  await expect(page.locator(".tl-filter-summary")).toContainText(queryA);
  await expect(page.locator(".tl-filter-summary")).not.toContainText(queryB);
  await expect(page.locator("#timeline-filters").getByRole("button", { name: "Applying filters…", exact: true })).toBeVisible();
  await expect(page.locator(".tl-pager__range")).toContainText("Showing 1 of 1 matching changes");
  await expect(page.locator("#filter-table")).toHaveValue("ticket_replies");
  await expect(page.locator("#filter-from")).toHaveValue("2020-01-01T00:00");
  await expect(page.locator("#filter-to")).toHaveValue("2099-01-01T00:00");
  await expect(page.locator("#filter-correlation-id")).toHaveValue(queryB);
  await expect(page.getByRole("status").filter({ hasText: "Showing 1 of 1 matching changes" })).toBeVisible();
  await page.setViewportSize({ width: 375, height: 900 });
  await expect(page.getByTestId("timeline-row")).toHaveCount(1);
  const pendingOverflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
  expect(pendingOverflow).toBe(false);

  hold = false;
  held!.server.send(held!.message);
  await expect(page.getByTestId("timeline-row")).toHaveCount(0);
  await expect(page.locator(".tl-filter-summary")).toContainText(queryB);
  await expect(page.getByRole("heading", { name: "No changes match these filters", exact: true })).toBeVisible();
  await expect(page.locator("#tl-main")).toContainText("Try a wider date range or adjust the filters, then apply again.");
  await expect(page.locator("#filter-correlation-id")).toHaveValue(queryB);
  await expect(page.locator("#filter-table")).toHaveValue("ticket_replies");
  await expect(page.locator("#filter-from")).toHaveValue("2020-01-01T00:00");
  await expect(page.locator("#filter-to")).toHaveValue("2099-01-01T00:00");
  const committedUrl = new URL(page.url());
  expect(committedUrl.searchParams.get("from")).toBe("2020-01-01T00:00");
  expect(committedUrl.searchParams.get("to")).toBe("2099-01-01T00:00");
  expect(committedUrl.searchParams.get("table")).toBe("ticket_replies");
  expect(committedUrl.searchParams.get("correlation_id")).toBe(queryB);
  await expect(page.locator(".tl-timeline-fact").filter({ hasText: "Matching changes" })).toContainText("0");

  await page.setViewportSize({ width: 375, height: 900 });
  await expect(page.getByTestId("timeline-row")).toHaveCount(0);
  await expect(page.locator("#filter-table")).toBeVisible();
  await expect(page.locator("#filter-correlation-id")).toBeVisible();
  const narrowOverflow = await page.evaluate(() => document.documentElement.scrollWidth > window.innerWidth);
  expect(narrowOverflow).toBe(false);
  const completedApply = page.locator("#timeline-filters").getByRole("button", { name: "Apply", exact: true });
  await expect(completedApply).toBeVisible();
  await expect(completedApply.locator("svg")).toHaveCount(1);
});

test("Home correlation lookup keeps destination identity while navigation is pending", async ({ page }) => {
  let hold = false;
  let held: { server: WebSocketRoute; message: string | Buffer } | undefined;
  await page.routeWebSocket(/\/live\/websocket/, (ws) => {
    const server = ws.connectToServer();
    ws.onMessage((message) => {
      if (hold && String(message).includes('"event"')) held = { server, message };
      else server.send(message);
    });
  });

  await login(page);
  await page.goto("/audit");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);

  const form = page.locator("#tl-correlation-lookup");
  const correlation = "walk-acme-4521-close";
  const input = form.getByLabel("Correlation id");
  await input.fill(correlation);
  hold = true;
  await form.getByRole("button", { name: "Open the timeline", exact: true }).click();
  await expect.poll(() => Boolean(held)).toBe(true);

  await expect(form).toHaveClass(/phx-submit-loading/);
  await expect(input).toHaveValue(correlation);
  await expect(form.getByRole("button", { name: "Open the timeline", exact: true })).toBeVisible();
  await expect(page).toHaveURL(/\/audit\/?$/);
  await expect(page.getByRole("alert")).toHaveCount(0);

  hold = false;
  held!.server.send(held!.message);
  await expect(page).toHaveURL(/\/audit\/timeline\?/);
  await expect(page.locator("#filter-correlation-id")).toHaveValue(correlation);
  await expect(page.locator(".tl-filter-summary")).toContainText(correlation);
});

for (const input of ["pointer", "Enter", "Space"] as const) {
  test(`offline Exports blocks ${input} activation until fresh persisted state returns`, async ({ page }) => {
    let blockReconnect = false;
    let socketConnections = 0;
    let socketClosures = 0;
    await page.routeWebSocket(/\/live\/websocket/, (socket) => {
      socketConnections += 1;
      if (blockReconnect) socket.close();
      else socket.connectToServer();
    });
    page.on("websocket", (socket) => socket.on("close", () => { socketClosures += 1; }));

    await login(page);
    const path = "/audit/exports?table=tickets";
    await page.goto(path);
    const root = page.locator("[data-phx-main]");
    const main = page.locator("#tl-main");
    await expect(root).toHaveClass(/phx-connected/);
    const queue = page.getByRole("button", { name: "Queue Timeline export", exact: true });
    const banner = page.locator(".tl-reconnect-banner");
    await expect(queue).toBeVisible();
    const revisionMarker = page.locator("[data-tl-mutation-revision]");
    await expect(revisionMarker).toHaveAttribute("data-tl-mutation-revision", /.+/);
    const revision = await revisionMarker.getAttribute("data-tl-mutation-revision");
    const jobCount = () => page.getByRole("link", { name: "Reopen source search", exact: true }).count();
    const initialCount = await jobCount();

    await main.focus();
    blockReconnect = true;
    await page.evaluate(() => (window as any).liveSocket.disconnect());
    await expect(root).toHaveClass(/phx-(loading|error|client-error)/);
    await expect.poll(() => socketClosures).toBeGreaterThan(0);
    await expect(banner).toBeVisible();
    await expect(banner).toHaveAttribute("role", "status");
    await expect(banner).toContainText("Reconnecting");
    await expect(queue).toBeDisabled();
    await expect(main).toBeVisible();
    if (page.viewportSize()!.width < 700) {
      await expect(page.locator(".tl-shell-nav__toggle")).toBeVisible();
    } else {
      await expect(page.getByRole("link", { name: "Timeline", exact: true })).toBeVisible();
    }

    if (input === "pointer") {
      const bounds = await queue.boundingBox();
      expect(bounds).toBeTruthy();
      await page.mouse.click(bounds!.x + bounds!.width / 2, bounds!.y + bounds!.height / 2).catch(() => undefined);
    } else {
      await queue.focus();
      await expect(queue).not.toBeFocused();
      await page.keyboard.press(input);
    }

    await expect.poll(() => page.evaluate(() => document.activeElement?.id)).toBe("tl-main");
    await expect.poll(jobCount).toBe(initialCount);

    blockReconnect = false;
    const connectionsBeforeRecovery = socketConnections;
    await page.evaluate(() => (window as any).liveSocket.connect());
    await expect(root).toHaveClass(/phx-connected/);
    await expect(banner).toBeHidden();
    await expect.poll(() => socketConnections).toBeGreaterThan(connectionsBeforeRecovery);
    await expect.poll(async () => revisionMarker.getAttribute("data-tl-mutation-revision"))
      .not.toBe(revision);
    await expect(queue).toBeEnabled();
    await expect.poll(jobCount).toBe(initialCount);

    // A later, deliberate activation is the only action that should create a job.
    await queue.click();
    await expect(page).toHaveURL(/\/audit\/exports(?:\?|$)/);
    await expect.poll(jobCount).toBe(initialCount + 1);
  });
}

test("Retention confirmation focus and cancel preserve state; Chromium touch navigation works", async ({ page, browser }, info) => {
  await login(page);
  await page.goto("/audit/policy/retention");
  const preview = page.getByRole("button", { name: "Preview retention", exact: true });
  const open = page.getByRole("button", { name: "Review and confirm", exact: true });
  const prepare = async () => { await preview.click(); await expect(page.getByTestId("retention-preview")).toBeVisible(); };
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  const revisionMarker = page.locator("[data-tl-mutation-revision]");
  await expect(revisionMarker).toHaveAttribute("data-tl-mutation-revision", /.+/);
  const initialRows = await page.locator("#retention-runs tr").count();
  expect(initialRows).toBeGreaterThan(0);
  await prepare();
  await open.focus();
  await page.keyboard.press("Enter");
  const dialog = page.locator("#prune-confirm-focus");
  await expect(dialog).toBeVisible();
  await expect(dialog).toHaveAttribute("role", "dialog");
  await expect(dialog).toHaveAttribute("aria-modal", "true");
  await expect(page.locator("#prune-confirm-title")).toHaveText("Prune retained audit data?");
  await expect(dialog).toHaveAttribute("aria-labelledby", "prune-confirm-title");
  await expect(dialog).toHaveAttribute("aria-describedby", "prune-confirm-description");
  const confirmation = dialog.getByRole("textbox", { name: "Policy name to confirm" });
  await expect(confirmation).toBeFocused();
  await expect(confirmation).toHaveAttribute("required", "");
  await dialog.getByRole("button", { name: "Prune now", exact: true }).click();
  await expect(dialog).toBeVisible();
  await expect(confirmation).toBeFocused();
  await expect(page.locator("#retention-runs tr")).toHaveCount(initialRows);
  for (let tab = 0; tab < 4; tab += 1) {
    await page.keyboard.press("Tab");
    await expect.poll(() => dialog.evaluate((el) => el.contains(document.activeElement))).toBe(true);
  }
  await page.keyboard.press("Escape");
  await expect(dialog).toBeHidden();
  await expect(preview).toBeFocused();
  await expect(page.getByTestId("retention-preview")).toHaveCount(0);
  await expect(page.locator("#retention-runs tr")).toHaveCount(initialRows);
  await expect(page.getByText("Prune request accepted", { exact: false })).toHaveCount(0);

  await prepare();
  await open.click();
  await expect(dialog).toBeVisible();
  await dialog.getByRole("button", { name: "Keep audit data", exact: true }).click();
  await expect(dialog).toBeHidden();
  await expect(preview).toBeFocused();
  await expect(page.getByTestId("retention-preview")).toHaveCount(0);
  await expect(page.locator("#retention-runs tr")).toHaveCount(initialRows);

  const touchContext = await browser.newContext({ baseURL: new URL(page.url()).origin, viewport: { width: 375, height: 900 }, hasTouch: true, reducedMotion: "reduce", colorScheme: info.project.name.endsWith("light") ? "light" : "dark" });
  try {
    const touch = await touchContext.newPage();
    await installControlledClipboard(touch);
    await login(touch);
    await touch.goto("/audit");
    const toggle = touch.locator(".tl-shell-nav__toggle");
    await expect(toggle).toBeVisible();
    await toggle.tap();
    await expect(touch.locator(".tl-shell-nav__panel")).toBeVisible();
  } finally { await touchContext.close(); }
});

test("real host denial under Acme support is distinct from busy and disabled", async ({ page, browser }, info) => {
  const unauthenticated = await page.request.get("/audit/timeline?correlation_id=walk-acme-4521-close", { maxRedirects: 0 });
  expect(unauthenticated.status()).toBe(302);
  expect(unauthenticated.headers().location).toContain("/users/log_in");

  await page.goto("/users/log_in", { waitUntil: "domcontentloaded" });
  await page.locator("#login_form").getByLabel("Email").fill("support@acme.example.com");
  await page.locator("#login_form").getByLabel("Password").fill(process.env.DEMO_SEED_PASSWORD ?? "password123456");
  await page.locator("#login_form").getByRole("button", { name: /log in/i }).click();
  await expect(page).toHaveURL(/\/(?:audit\/timeline(?:\?[^#]*)?)?$/);
  const e = process.env.THREADLINE_E2E_EVIDENCE === "1"
    ? await startEvidence(page, browser, info, "seeded-support-acme-read-only")
    : undefined;
  await page.goto("/audit/timeline");
  await expect(page.locator("#timeline-filters")).toBeVisible();
  const denied = await page.request.get("/audit/exports/changes.csv");
  expect(denied.status()).toBe(403);
  await expect(page).toHaveURL(/\/audit\/timeline(?:\?|$)/);
  if (e) {
    await e.capture("state.denied", "/audit/timeline", "real-export-http-denied", { httpStatus: denied.status(), role: "Acme support read-only", scopeDecision: "host callback", timelineAllowed: true, unauthenticatedTimelineStatus: unauthenticated.status(), notPending: true });
    e.finish("state.denied", "/audit/timeline", "real-host-denial");
  }
});

test("saved searches keep canonical sharing, long summaries, and destructive actions reachable", async ({ page }) => {
  await login(page);
  const id = randomUUID();
  const correlation = `saved-search-${id}-` + "x".repeat(170);
  const name = `Escalation review ${"weekly priorities ".repeat(9)}${id}`;
  const appliedUrl = `/audit/timeline?table=ticket_replies&correlation_id=${encodeURIComponent(correlation)}`;

  await page.goto(appliedUrl);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect(page.locator("#filter-correlation-id")).toHaveValue(correlation);

  // Edits that have not been applied remain drafts; sharing still describes the URL query.
  await page.locator("#filter-table").fill("draft_table_should_not_be_shared");
  await page.locator("#filter-correlation-id").fill("draft-correlation-should-not-be-shared");

  const filters = page.getByRole("button", { name: "Filters", exact: true });
  await filters.click();
  const drawer = page.getByRole("dialog", { name: "Filters and handoff" });
  await expect(drawer).toBeVisible();
  await expect(drawer.getByRole("region", { name: "Saved searches" })).toBeVisible();
  await expect(drawer).toContainText("This URL shares the applied filters. Results and access are determined by the receiving host.");

  const copySearch = drawer.getByRole("button", { name: "Copy search URL", exact: true });
  await expect(copySearch).toHaveAttribute("data-tl-copy", appliedUrl);
  await drawer.locator("#save-view-form").getByLabel("Saved search name").fill(name);
  await drawer.getByRole("button", { name: "Save search", exact: true }).click();

  const applySavedSearch = drawer.getByRole("button", { name: `Apply saved search ${name}`, exact: true });
  await expect(applySavedSearch).toBeVisible();
  const savedItem = applySavedSearch.locator("xpath=ancestor::li");
  await expect(savedItem.locator(".tl-saved-search__summary")).toContainText(correlation);
  const deleteSavedSearch = savedItem.getByRole("button", { name: `Delete ${name}`, exact: true });
  await expect(deleteSavedSearch).toBeVisible();

  // Change the committed query, then resume the saved search through Timeline validation.
  await drawer.getByRole("button", { name: "Close", exact: true }).click();
  await expect(drawer).toBeHidden();
  await page.locator("#filter-correlation-id").fill("replacement-correlation");
  await page.locator("#timeline-filters").getByRole("button", { name: "Apply", exact: true }).click();
  await expect(page).toHaveURL(/correlation_id=replacement-correlation/);
  await filters.click();
  await expect(drawer).toBeVisible();
  await drawer.getByRole("button", { name: `Apply saved search ${name}`, exact: true }).click();
  await expect.poll(() => {
    const current = new URL(page.url());
    return `${current.pathname}${current.search}`;
  }).toBe(appliedUrl);
  await expect(page.locator("#filter-correlation-id")).toHaveValue(correlation);

  await page.setViewportSize({ width: 375, height: 900 });
  await expect(drawer).toBeVisible();
  await expectNoHorizontalOverflow(page);
  await expect(drawer.getByRole("button", { name: `Apply saved search ${name}`, exact: true })).toBeVisible();
  await expect(drawer.getByRole("button", { name: `Delete ${name}`, exact: true })).toBeVisible();

  await drawer.getByRole("button", { name: `Delete ${name}`, exact: true }).click();
  const confirmation = page.getByRole("dialog", { name: "Delete saved search" });
  await expect(confirmation).toContainText(`Delete saved search “${name}”? This removes it from your saved searches.`);
  await confirmation.getByRole("button", { name: "Keep saved search", exact: true }).click();
  await expect(confirmation).toBeHidden();

  await drawer.getByRole("button", { name: `Delete ${name}`, exact: true }).click();
  await page.getByRole("dialog", { name: "Delete saved search" }).getByRole("button", { name: "Delete search", exact: true }).click();
  await expect(drawer.getByRole("button", { name: `Apply saved search ${name}`, exact: true })).toHaveCount(0);
});

test("saved search actions stay in bounds at verified 200% browser zoom", async ({}, info) => {
  test.skip(info.project.name !== "desktop-chromium", "The actual tab-zoom proof runs in desktop Chromium");

  await withIsolatedZoomContext(chromium, async (context, page) => {
    const baseURL = String(info.project.use.baseURL ?? "http://127.0.0.1:4002");
    await page.goto(new URL("/users/log_in", baseURL).toString(), { waitUntil: "domcontentloaded" });
    const loginForm = page.locator("#login_form");
    await loginForm.getByLabel("Email").fill("admin@example.com");
    await loginForm.getByLabel("Password").fill(process.env.DEMO_SEED_PASSWORD ?? "password123456");
    await loginForm.getByRole("button", { name: /log in/i }).click();
    await expect(page).toHaveURL(new URL("/", baseURL).toString());

    const correlation = `zoom-saved-search-${randomUUID()}-` + "z".repeat(170);
    const name = `Zoom support search ${"unusual naming ".repeat(9)}${randomUUID()}`;
    await page.goto(new URL(`/audit/timeline?table=ticket_replies&correlation_id=${encodeURIComponent(correlation)}`, baseURL).toString());
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    const zoom = await setAndReadTabZoom(context, page);
    expect(zoom.zoomFactor).toBe(2);

    await page.getByRole("button", { name: "Filters", exact: true }).click();
    const drawer = page.getByRole("dialog", { name: "Filters and handoff" });
    await expect(drawer).toBeVisible();
    await drawer.locator("#save-view-form").getByLabel("Saved search name").fill(name);
    await drawer.getByRole("button", { name: "Save search", exact: true }).click();
    const apply = drawer.getByRole("button", { name: `Apply saved search ${name}`, exact: true });
    const remove = drawer.getByRole("button", { name: `Delete ${name}`, exact: true });
    await expect(apply).toBeVisible();
    await expect(remove).toBeVisible();
    await expectNoHorizontalOverflow(page);

    const controlsInsideViewport = await Promise.all([apply, remove].map((control) => control.evaluate((element) => {
      const rect = element.getBoundingClientRect();
      return rect.left >= 0 && rect.right <= document.documentElement.clientWidth + 1;
    })));
    expect(controlsInsideViewport).toEqual([true, true]);
    await expect(drawer.locator(".tl-saved-search__summary").filter({ hasText: correlation })).toBeVisible();
  });
});

test("actor and correlation pivots re-enter Timeline with only their supported filters", async ({ page }) => {
  await login(page);
  await page.goto("/audit/timeline?correlation_id=walk-acme-4521-close");
  await expect(page.getByTestId("timeline-row").first()).toBeVisible();

  const row = page.getByTestId("timeline-row").first();
  const correlationLink = row.getByTitle("View correlated changes in Timeline");
  const actorLink = row.getByTitle("View actor activity");
  const correlationHref = await correlationLink.getAttribute("href");
  const actorHref = await actorLink.getAttribute("href");
  expect(correlationHref).toMatch(/^\/audit\/timeline\?correlation_id=/);
  expect(actorHref).toMatch(/^\/audit\/actors\/(?:user|admin|service_account|job|system)\//);

  await correlationLink.click();
  await expect.poll(() => new URL(page.url()).searchParams.get("correlation_id")).toBe("walk-acme-4521-close");
  await expect(page.locator("#filter-correlation-id")).toHaveValue("walk-acme-4521-close");
  await expect(page.locator("#tl-main")).not.toContainText("incident/walk-acme-4521-close");

  await page.goto(actorHref!);
  await expect(page.getByRole("heading", { name: "Actor activity", exact: true })).toBeVisible();
  await page.getByRole("link", { name: "Open timeline", exact: true }).first().click();
  await expect(page).toHaveURL(/\/audit\/timeline\?actor_kind=[^&]+&actor_id=/);
  const actorQuery = new URL(page.url()).searchParams;
  expect(actorQuery.get("actor_kind")).toBeTruthy();
  expect(actorQuery.get("actor_id")).toBeTruthy();
  expect([...actorQuery.keys()].sort()).toEqual(["actor_id", "actor_kind"]);
  await expect(page.locator("#filter-correlation-id")).toHaveValue("");
});

test("Timeline pagination appends the next page without changing the applied search URL", async ({ page }) => {
  await login(page);
  const appliedUrl = "/audit/timeline?from=2020-01-01T00%3A00&to=2099-01-01T00%3A00&table=tickets";
  await page.goto(appliedUrl);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);

  const rows = page.getByTestId("timeline-row");
  await expect(rows).toHaveCount(50);
  const pager = page.getByRole("navigation", { name: "Timeline pagination" });
  await expect(pager).toContainText(/Showing 50 of [\d,]+ matching changes/);
  const older = pager.getByRole("button", { name: "Older", exact: true });
  await expect(older).toBeEnabled();

  const before = await rows.first().getAttribute("id");
  await older.click();
  await expect.poll(() => rows.count()).toBeGreaterThan(50);
  const shownCount = await rows.count();
  const range = (await pager.innerText()).match(/Showing ([\d,]+) of ([\d,]+) matching changes/);
  expect(range).not.toBeNull();
  expect(Number(range![1].replaceAll(",", ""))).toBe(shownCount);
  expect(Number(range![2].replaceAll(",", ""))).toBeGreaterThan(shownCount);
  await expect.poll(() => {
    const current = new URL(page.url());
    return `${current.pathname}${current.search}`;
  }).toBe(appliedUrl);
  expect(await rows.first().getAttribute("id")).toBe(before);

  const rowMotion = await rows.first().evaluate((element) => {
    const style = getComputedStyle(element);
    return { animationName: style.animationName, animationDuration: style.animationDuration, animationDelay: style.animationDelay };
  });
  expect(rowMotion.animationName).toBe("none");
  expect(rowMotion.animationDelay.split(",").every((delay) => Number.parseFloat(delay) === 0)).toBe(true);
});


test("Phase251 Timeline and saved-view guards", async ({ page }) => {
  await installControlledClipboard(page);
  await login(page);
  const message = "These Timeline filters are not supported. Update the filters before applying them.";
  await page.goto("/audit/timeline?unsupported_only=private-value");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect(page.getByRole("alert").filter({ hasText: message })).toBeVisible();
  await expect(page.getByTestId("timeline-row")).toHaveCount(0);

  const original = "/audit/timeline?from=2020-01-01T00%3A00&to=2099-01-01T00%3A00&correlation_id=walk-acme-4521-close";
  await page.goto(original);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect(page.getByTestId("timeline-row").first()).toBeVisible();
  await page.locator("#filter-correlation-id").fill("phase251-no-match");
  await page.locator("#timeline-filters").getByRole("button", { name: "Apply", exact: true }).click();
  await expect.poll(() => new URL(page.url()).searchParams.get("correlation_id")).toBe("phase251-no-match");
  await page.reload();
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect(page.locator("#filter-correlation-id")).toHaveValue("phase251-no-match");
  await page.goBack();
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect.poll(() => new URL(page.url()).searchParams.get("correlation_id")).toBe("walk-acme-4521-close");
  await expect(page.getByTestId("timeline-row").first()).toBeVisible();
  await page.goForward();
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect.poll(() => new URL(page.url()).searchParams.get("correlation_id")).toBe("phase251-no-match");
  await page.goto(original);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await page.getByRole("button", { name: "Filters", exact: true }).click();
  let drawer = page.getByRole("dialog", { name: "Filters and handoff" });
  const name = `Phase251 saved selection ${randomUUID()}`;
  await drawer.locator("#save-view-form").getByLabel("Saved search name").fill(name);
  await drawer.getByRole("button", { name: "Save search", exact: true }).click();
  const apply = drawer.getByRole("button", { name: `Apply saved search ${name}`, exact: true });
  await expect(apply).toBeVisible();
  const id = await apply.getAttribute("phx-value-id");
  expect(id).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);

  // Mutate only the fresh UI-owned fixture, never shared business data.
  const partition = process.env.MIX_TEST_PARTITION ?? "";
  expect(partition).toMatch(/^(?:\d+|p251pair)?$/);
  expect(process.env.THREADLINE_E2E).toBe("1");
  if (partition === "p251pair") {
    expect(new URL(page.url()).origin).toBe("http://127.0.0.1:60152");
    expect(process.env.DB_HOST).toBe("127.0.0.1");
    expect(process.env.DB_PORT).toBe("60025");
  }
  const sql = (statement: string) => execFileSync("psql", [
    "-X", "-h", process.env.DB_HOST ?? "localhost", "-p", process.env.DB_PORT ?? "5432",
    "-U", "postgres", "-d", `threadline_phoenix_test${partition}`, "-v", "ON_ERROR_STOP=1", "-At", "-c", statement,
  ], { env: { ...process.env, PGPASSWORD: "postgres" }, encoding: "utf8", stdio: "pipe" });
  try {
    for (const invalid of [{ unsupported_only: "private-value" }, { correlation_id: ["private-value"] }]) {
      const payload = JSON.stringify(invalid).replaceAll("'", "''");
      const updated = sql(`UPDATE threadline.threadline_saved_views SET filters = '${payload}'::jsonb WHERE id = '${id}'::uuid RETURNING id`).trim();
      expect(updated).toContain(id!);
      await page.reload();
      await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
      await page.getByRole("button", { name: "Filters", exact: true }).click();
      drawer = page.getByRole("dialog", { name: "Filters and handoff" });
      await drawer.getByRole("button", { name: `Apply saved search ${name}`, exact: true }).click();
      await expect(drawer.getByRole("alert").filter({ hasText: message })).toBeVisible();
      expect(new URL(page.url()).searchParams.get("correlation_id")).toBe("walk-acme-4521-close");
    }
    sql(`UPDATE threadline.threadline_saved_views SET filters = '{}'::jsonb WHERE id = '${id}'::uuid`);
    await page.reload();
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await page.getByRole("button", { name: "Filters", exact: true }).click();
    drawer = page.getByRole("dialog", { name: "Filters and handoff" });
    await drawer.getByRole("button", { name: `Apply saved search ${name}`, exact: true }).click();
    await expect.poll(() => new URL(page.url()).search).toBe("?from=");
    await page.reload();
    await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expect.poll(() => new URL(page.url()).search).toBe("?from=");
    await expectNoHorizontalOverflow(page);
    await page.getByRole("button", { name: "Filters", exact: true }).click();
    drawer = page.getByRole("dialog", { name: "Filters and handoff" });
    await drawer.getByRole("button", { name: `Delete ${name}`, exact: true }).click();
    const confirmation = page.getByRole("dialog", { name: "Delete saved search", exact: true });
    const keep = confirmation.getByRole("button", { name: "Keep saved search", exact: true });
    await expect(keep).toBeFocused();
    await page.keyboard.press("Tab");
    await expect(confirmation.getByRole("button", { name: "Delete search", exact: true })).toBeFocused();
    expect(await page.evaluate(() => (window as any).__phase251CopyCounter.installed)).toBe(true);
    await page.keyboard.press("Enter");
    await expect(confirmation).toBeHidden();
    await expect(drawer.getByRole("button", { name: `Apply saved search ${name}`, exact: true })).toHaveCount(0);
    expect(await page.evaluate(() => (window as any).__phase251CopyCounter.count)).toBe(0);
  } finally {
    sql(`DELETE FROM threadline.threadline_saved_views WHERE id = '${id}'::uuid`);
  }
});


test("Phase251 Coverage availability boundaries", async ({ page, browser }) => {
  await installControlledClipboard(page);
  await login(page);
  await page.goto("/audit/coverage?schema%5Bpart%5D=private-251-input-canary");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect(page.getByRole("alert")).toContainText("Choose a schema from the list.");
  await expect(page.getByTestId("coverage-status")).toContainText("Coverage not inspected");
  await expect(page.getByTestId("coverage-table")).toHaveCount(0);
  await expect(page.locator("#tl-main")).not.toContainText("private-251-input-canary");
  await page.locator("#coverage-schema").selectOption("public");
  await page.getByRole("button", { name: "Apply schema", exact: true }).click();
  await expect.poll(() => new URL(page.url()).searchParams.get("schema")).toBe("public");
  await expect(page.getByTestId("coverage-status")).toContainText("public:");
  await expect(page.getByTestId("coverage-table")).toBeVisible();
  await page.goto("/audit/coverage?schema=does_not_exist_phase251");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect(page.getByRole("alert")).toContainText("was not found");
  await expect(page.getByTestId("coverage-status")).toContainText("Coverage not inspected");
  await expect(page.getByTestId("coverage-table")).toHaveCount(0);
  await expectNoHorizontalOverflow(page);

  const supportContext = await browser.newContext({ baseURL: new URL(page.url()).origin, viewport: { width: 375, height: 900 } });
  const anonymousContext = await browser.newContext({ baseURL: new URL(page.url()).origin });
  try {
    const support = await supportContext.newPage();
    await installControlledClipboard(support);
    await login(support, "support@acme.example.com");
    await support.goto("/audit/coverage?schema=public");
    await expect(support.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expect(support.getByRole("heading", { name: "Coverage unavailable", exact: true })).toBeVisible();
    await expect(support.locator("#tl-main")).toContainText("This is not a permissions issue.");
    await expect(support.getByTestId("coverage-table")).toHaveCount(0);
    await expect(support.locator("#coverage-schema")).toHaveCount(0);
    const anonymous = await anonymousContext.newPage();
    await anonymous.goto("/audit/coverage?schema=public");
    await expect.poll(() => new URL(anonymous.url()).pathname).toBe("/users/log_in");
  } finally {
    await supportContext.close();
    await anonymousContext.close();
  }
});


test("Phase251 Redaction current-definition meaning", async ({ page }) => {
  let hold = false;
  let held: { server: WebSocketRoute; message: string | Buffer } | undefined;
  await page.routeWebSocket(/\/live\/websocket/, ws => {
    const server = ws.connectToServer();
    ws.onMessage(message => {
      if (hold && String(message).includes('"refresh-policy-inspection"')) held = { server, message };
      else server.send(message);
    });
  });
  await installControlledClipboard(page);
  await login(page);
  await page.setViewportSize({ width: 375, height: 900 });
  await page.goto("/audit/policy/redaction?schema=public");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  const main = page.locator("#tl-main");
  await expect(main.getByText("Inspection completed at", { exact: true })).toBeVisible();
  await expect(main.getByText("Configured: host application policy. Deployed: current database trigger definition.", { exact: true })).toBeVisible();
  const posts = main.locator("details.tl-policy__row").filter({ has: page.getByText("posts", { exact: true }) });
  await posts.locator("summary").focus();
  await page.keyboard.press("Enter");
  await expect(posts).toHaveAttribute("open", "");
  await expect(posts.getByRole("rowheader", { name: "Left out", exact: true })).toBeVisible();
  await expect(posts.getByRole("rowheader", { name: "Redacted", exact: true })).toBeVisible();
  await expect(posts.getByRole("rowheader", { name: "Replacement", exact: true })).toBeVisible();
  await expect(main).toContainText("does not establish whether historical audit rows or downstream exports were redacted");
  const refresh = main.locator('button[phx-click="refresh-policy-inspection"]');
  await expect(refresh).toHaveAttribute("phx-disable-with", "Inspecting policy…");
  const beforeInspection = await main.locator("time").first().getAttribute("datetime");
  hold = true;
  await refresh.focus();
  await page.keyboard.press("Enter");
  await expect.poll(() => Boolean(held)).toBe(true);
  await expect(refresh).toBeDisabled();
  await expect(refresh).toHaveText("Inspecting policy…");
  await expect(main.locator("time").first()).toHaveAttribute("datetime", beforeInspection!);
  hold = false;
  held!.server.send(held!.message);
  await expect(refresh).toBeEnabled();
  await expect.poll(() => main.locator("time").first().getAttribute("datetime")).not.toBe(beforeInspection);
  await expect(main.locator("time").first()).toHaveAttribute("datetime", /Z$/);
  await expectNoHorizontalOverflow(page);
  await page.goto("/audit/policy/redaction?schema=threadline");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect(main.getByRole("heading", { name: "No configured policy to compare", exact: true })).toHaveCount(1);
  await expect(main.getByRole("heading", { name: /^No configured policy to compare \(0\)$/ })).toHaveCount(3);
  await expect(main).not.toContainText("No redaction drift detected.");
  await expect(main).not.toContainText("No introspection failures.");
  await page.goto("/audit/policy/redaction?schema[bad]=value");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect(main.getByText("Choose a schema from the list or use public schema.", { exact: true })).toBeVisible();
  await main.getByRole("link", { name: "Use public schema", exact: true }).focus();
  await page.keyboard.press("Enter");
  await expect(page).toHaveURL(/policy\/redaction\?schema=public$/);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  const rendered = await main.evaluate(node => node.outerHTML);
  for (const canary of ["CREATE OR REPLACE FUNCTION", "raw-trigger-sql-canary-241", "private-unexpected-policy-canary-251", "sample-value-canary-241", "redacted-value-canary-241"]) expect(rendered).not.toContain(canary);
  expect(await page.evaluate(() => (window as any).__phase251CopyCounter.count)).toBe(0);
});


test("Phase251 Evidence recorded provenance", async ({ page, browser }) => {
  await installControlledClipboard(page);
  await login(page);
  await page.setViewportSize({ width: 375, height: 900 });
  await page.goto("/audit/evidence");
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  const main = page.locator("#tl-main");
  await expect(main.getByText("Snapshot recorded at", { exact: true }).first()).toBeVisible();
  await expect(main).toContainText("caller-overridable recorded metadata, not verified or authenticated identity");
  const card = main.locator(".tl-record-card").filter({ has: page.locator('code[title*="walk-retention-offboarded-co"]') });
  await expect(card).toHaveCount(1);
  await expect(card).toContainText("Recorded provenance");
  const selectedReference = await card.locator("code.tl-secondary-ref").getAttribute("data-tl-copy");
  expect(selectedReference).not.toBeNull();
  await card.getByRole("link", { name: "View proof history", exact: true }).focus();
  await page.keyboard.press("Enter");
  await expect(page).toHaveURL(/mode=history/);
  await expect(main.locator(".tl-record-card")).toHaveCount(3);
  await expect(main.locator(".tl-evidence__workflow-summary code.tl-secondary-ref")).toHaveAttribute("title", selectedReference!);
  await expect(main).toContainText("Append-only history");
  await expectNoHorizontalOverflow(page);
  const ref = JSON.stringify({ run_id: "missing-" + "x".repeat(180) });
  const selection = `/audit/evidence?subject=retention_run&subject_ref_json=${encodeURIComponent(ref)}`;
  await page.goto(selection);
  await expect(page.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
  await expect(main.getByRole("heading", { name: "No Threadline evidence for this selection", exact: true })).toBeVisible();
  const selected = main.locator(".tl-evidence__workflow-summary code.tl-secondary-ref");
  await expect(selected).toHaveAttribute("title", ref);
  await selected.locator("..").getByRole("button", { name: "Copy subject ref", exact: true }).focus();
  await page.keyboard.press("Enter");
  await expect.poll(() => page.evaluate(() => (window as any).__phase251CopyCounter.lastValue)).toBe(ref);
  await expectNoHorizontalOverflow(page);
  // The existing live/DB unavailable endpoint owns failed-read and Retry proof;
  // this mounted host deliberately exposes no outage injection route.
  const context = await browser.newContext({ baseURL: new URL(page.url()).origin });
  try {
    const support = await context.newPage();
    await login(support, "support@acme.example.com");
    await support.goto("/audit/evidence");
    await expect(support.locator("[data-phx-main]")).toHaveClass(/phx-connected/);
    await expect(support.locator("#tl-main")).toContainText("Evidence is unavailable in this support lane");
  } finally { await context.close(); }
});


type Phase252MutationState = {
  database: string; requests: number; changes: number; transactions: number;
  active: number; run_rows: { id: string; status: string; deleted_count: number | null; started_at: string | null; completed_at: string | null }[];
  request_rows: { id: string; actor_ref: { type: string; id: string }; inserted_at: string }[];
};

function phase252MutationState(): Phase252MutationState {
  const expectedOrigin = "http://127.0.0.1:60154";
  if (process.env.DB_HOST !== "127.0.0.1" || process.env.DB_PORT !== "60025" || process.env.MIX_TEST_PARTITION !== "p252mutation" || process.env.THREADLINE_PHASE252_MUTATION_APP_URL !== expectedOrigin || new URL(process.env.E2E_BASE_URL ?? "http://invalid").origin !== expectedOrigin) {
    throw new Error("Phase252 destructive proof requires the exact owned p252mutation database and app origin; no fallback");
  }
  const receipt = JSON.parse(readFileSync("/private/tmp/threadline-252-mutation-app.json", "utf8"));
  if (receipt.status !== "ready" || receipt.url !== expectedOrigin || receipt.database !== "threadline_phoenix_testp252mutation" || receipt.port !== 60154) throw new Error("Mutation app custody is not ready");
  const sql = `SELECT jsonb_build_object(
    'database',current_database(),
    'requests',(SELECT count(*) FROM threadline.audit_actions WHERE name='retention.pruned'),
    'changes',(SELECT count(*) FROM threadline.audit_changes),
    'transactions',(SELECT count(*) FROM threadline.audit_transactions),
    'active',(SELECT count(*) FROM threadline.threadline_retention_runs WHERE status IN ('queued','running')),
    'run_rows',(SELECT COALESCE(jsonb_agg(jsonb_build_object('id',id,'status',status,'deleted_count',deleted_count,'started_at',started_at,'completed_at',completed_at) ORDER BY id),'[]'::jsonb) FROM threadline.threadline_retention_runs),
    'request_rows',(SELECT COALESCE(jsonb_agg(jsonb_build_object('id',id,'actor_ref',actor_ref,'inserted_at',inserted_at) ORDER BY id),'[]'::jsonb) FROM threadline.audit_actions WHERE name='retention.pruned'))::text;`;
  const value = JSON.parse(execFileSync(process.env.THREADLINE_PHASE252_PSQL ?? "psql", ["-X", "-h", "127.0.0.1", "-p", "60025", "-d", "threadline_phoenix_testp252mutation", "-v", "ON_ERROR_STOP=1", "-At", "-c", sql], { encoding: "utf8", env: { ...process.env, PGUSER: "postgres", PGPASSWORD: "postgres" } }).trim());
  if (value.database !== "threadline_phoenix_testp252mutation") throw new Error("Wrong observed mutation database");
  return value;
}

test("Phase252 Retention preview requires fresh deliberate confirmation after reconnect", async ({ page }) => {
  test.skip(process.env.THREADLINE_PHASE252_MUTATION_APP_URL !== "http://127.0.0.1:60154", "Explicit owned mutation-fixture lane only");
  const proofDir = resolve(process.env.THREADLINE_PHASE252_PROOF_DIR ?? "/invalid");
  if (!proofDir.startsWith("/private/tmp/private252mutationevidence/") || !existsSync(proofDir) || !statSync(proofDir).isDirectory()) throw new Error("Parent-owned fresh mutation proof directory required");
  const proofFile = join(proofDir, "retention-no-replay.json");
  if (existsSync(proofFile)) throw new Error("Preserve the previous mutation proof invocation");
  const facts: { at: string; stage: string; state: Phase252MutationState }[] = [];
  const mark = (stage: string) => { const state = phase252MutationState(); facts.push({ at: new Date().toISOString(), stage, state }); writeFileSync(proofFile, `${JSON.stringify({ kind: "owned-mutation-fixture", facts }, null, 2)}\n`); return state; };
  const before = mark("fixture-before-login");
  expect(before.active).toBe(0); expect(before.changes).toBeGreaterThan(0); expect(before.transactions).toBeGreaterThan(0); expect(before.run_rows.length).toBeGreaterThan(0);
  let blockReconnect = false;
  let connections = 0;
  await page.routeWebSocket(/\/live\/websocket/, (socket) => { connections += 1; if (blockReconnect) socket.close(); else socket.connectToServer(); });
  await login(page); await page.goto("/audit/policy/retention");
  const liveRoot = page.locator("[data-phx-main]");
  await expect(liveRoot).toHaveClass(/phx-connected/);
  const revision = page.locator("[data-tl-mutation-revision]");
  await expect(revision).toHaveAttribute("data-tl-mutation-revision", /.+/);
  const originalRevision = await revision.getAttribute("data-tl-mutation-revision");
  const prepare = async () => { await page.getByRole("button", { name: "Preview retention", exact: true }).click(); await expect(page.getByTestId("retention-preview")).toBeVisible(); await page.getByRole("button", { name: "Review and confirm", exact: true }).click(); await expect(page.getByRole("dialog")).toBeVisible(); };
  await prepare();
  await page.getByRole("textbox", { name: "Policy name to confirm" }).fill("default");
  blockReconnect = true;
  await page.evaluate(() => (window as any).liveSocket.disconnect());
  await expect(liveRoot).toHaveClass(/phx-(loading|error|client-error)/);
  await expect(page.locator(".tl-reconnect-banner")).toBeVisible();
  const submit = page.getByRole("button", { name: "Prune now", exact: true });
  await expect(submit).toBeDisabled();
  const box = await submit.boundingBox(); expect(box).toBeTruthy();
  await page.mouse.click(box!.x + box!.width / 2, box!.y + box!.height / 2);
  await page.getByRole("textbox", { name: "Policy name to confirm" }).focus();
  await page.keyboard.press("Enter");
  expect(mark("offline-pointer-enter")).toEqual(before);
  blockReconnect = false;
  const previousConnections = connections;
  await page.evaluate(() => (window as any).liveSocket.connect());
  await expect(liveRoot).toHaveClass(/phx-connected/);
  await expect.poll(() => connections).toBeGreaterThan(previousConnections);
  await expect.poll(() => revision.getAttribute("data-tl-mutation-revision")).not.toBe(originalRevision);
  await expect(page.getByRole("dialog")).toHaveCount(0);
  await expect(page.getByTestId("retention-preview")).toHaveCount(0);
  // A bounded observation window checks delayed replay as well as the first reconnect frame.
  const until = Date.now() + 1_000;
  while (Date.now() < until) { expect(phase252MutationState()).toEqual(before); await page.waitForTimeout(100); }
  expect(mark("reconnected-without-replay")).toEqual(before);
  await prepare();
  expect(phase252MutationState()).toEqual(before);
  await page.getByRole("textbox", { name: "Policy name to confirm" }).fill("default");
  expect(phase252MutationState()).toEqual(before);
  await page.getByRole("button", { name: "Prune now", exact: true }).click();
  await expect.poll(() => phase252MutationState().requests).toBe(before.requests + 1);
  await expect.poll(() => phase252MutationState().run_rows.length).toBe(before.run_rows.length + 1);
  const originalIds = new Set(before.run_rows.map((run) => run.id));
  await expect.poll(() => phase252MutationState().run_rows.find((run) => !originalIds.has(run.id))?.status).toBe("completed");
  const after = mark("fresh-deliberate-completed");
  const run = after.run_rows.find((candidate) => !originalIds.has(candidate.id))!;
  expect(run.deleted_count).toBeGreaterThan(0);
  expect((before.changes - after.changes) + (before.transactions - after.transactions)).toBe(run.deleted_count);
  expect(after.changes).toBeLessThan(before.changes);
  expect(after.requests).toBe(before.requests + 1);
  const requestIds = new Set(before.request_rows.map((request) => request.id));
  const request = after.request_rows.find((candidate) => !requestIds.has(candidate.id))!;
  expect(request.actor_ref.type).toBe("user");
  expect(request.actor_ref.id).toBeTruthy();
  const row = page.locator(`#runs-${run.id}`);
  await expect(row.getByText("Completed", { exact: true })).toBeVisible();
  await expect(row.locator("td[data-label='Deleted Rows']")).toHaveText(String(run.deleted_count));
  expect(run.started_at).toBeTruthy(); expect(run.completed_at).toBeTruthy();
});
