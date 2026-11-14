import { expect, test } from "@playwright/test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { Script } from "node:vm";

const docsUrl = process.env.THREADLINE_PHASE250_DOCS_URL;

const registerGeneratedDocsTests = (url: string) => {
  const repositoryRoot = resolve(process.cwd(), "../../..");
  const darkLogo = readFileSync(
    resolve(repositoryRoot, "brand/assets/logo/threadline-lockup-dark.svg"),
  );
  const lightLogo = readFileSync(
    resolve(repositoryRoot, "brand/assets/logo/threadline-lockup-light.svg"),
  );
  const favicon = readFileSync(
    resolve(repositoryRoot, "brand/assets/icon/favicon.svg"),
  );

  // This private listener is required only for the bounded generated-doc proof.
  const generatedHtml = readFileSync(
    resolve(repositoryRoot, "doc/readme.html"),
    "utf8",
  );
  const logoHook = Array.from(
    generatedHtml.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/gi),
    (match) => match[1] ?? "",
  ).find((source) => source.includes("const updateProjectLogo"));
  if (!logoHook) throw new Error("Generated ExDoc logo hook was not found in doc/readme.html.");
  new Script(logoHook, { filename: "doc/readme.html#threadline-logo-hook" });

  test("loads the paired README artwork and switches the measured sidebar logo with body.dark", async ({
    page,
  }) => {
    await page.goto(url, { waitUntil: "domcontentloaded" });

    const sidebarLogo = page.locator(".sidebar .sidebar-projectImage img");
    await expect(sidebarLogo).toBeVisible();

    const readmePicture = page.locator("main picture").filter({
      has: page.locator('img[alt="Threadline"][width="420"]'),
    });
    await expect(readmePicture).toHaveCount(1);
    await expect(readmePicture.locator("source")).toHaveAttribute(
      "srcset",
      "brand/assets/logo/threadline-lockup-dark.svg",
    );
    await expect(readmePicture.locator("source")).toHaveAttribute(
      "media",
      "(prefers-color-scheme: dark)",
    );
    await expect(readmePicture.locator("img")).toHaveAttribute(
      "src",
      "brand/assets/logo/threadline-lockup-light.svg",
    );

    const readmeLogo = readmePicture.locator("img");
    for (const scheme of ["light", "dark"] as const) {
      await page.emulateMedia({ colorScheme: scheme });
      await expect
        .poll(() =>
          readmeLogo.evaluate((image: HTMLImageElement) => image.currentSrc),
        )
        .toMatch(new RegExp(`threadline-lockup-${scheme}\\.svg$`));
      await expect
        .poll(() =>
          readmeLogo.evaluate(
            (image: HTMLImageElement) => image.complete && image.naturalWidth > 0,
          ),
        )
        .toBe(true);
    }

    for (const theme of ["light", "dark", "light"] as const) {
      const logoBytes = theme === "dark" ? darkLogo : lightLogo;
      await page.evaluate((isDark) => {
        document.body.classList.toggle("dark", isDark);
      }, theme === "dark");

      await expect(sidebarLogo).toHaveAttribute(
        "src",
        new RegExp(`brand/assets/logo/threadline-lockup-${theme}\\.svg$`),
      );
      await expect
        .poll(() => sidebarLogo.evaluate((image: HTMLImageElement) => image.complete && image.naturalWidth > 0))
        .toBe(true);

      const geometry = await sidebarLogo.evaluate((image: HTMLImageElement) => {
        const rect = image.getBoundingClientRect();
        return {
          width: rect.width,
          height: rect.height,
          naturalWidth: image.naturalWidth,
          naturalHeight: image.naturalHeight,
        };
      });
      expect(geometry.width).toBeGreaterThanOrEqual(96);
      expect(geometry.height).toBeGreaterThan(0);
      expect(geometry.naturalWidth / geometry.naturalHeight).toBeCloseTo(
        geometry.width / geometry.height,
        1,
      );

      const logoResponse = await page.request.get(new URL(
        `brand/assets/logo/threadline-lockup-${theme}.svg`,
        page.url(),
      ).href);
      expect(logoResponse.ok()).toBe(true);
      expect(await logoResponse.body()).toEqual(logoBytes);
    }

    await expect(readmeLogo).toBeVisible();
    await expect(page.locator("#threadline-mermaid-script")).toBeAttached();
  });

  test("keeps the local favicon independent from application body theme", async ({
    page,
  }) => {
    expect(favicon.toString()).toContain("@media (prefers-color-scheme:dark)");
    await page.goto(url, { waitUntil: "domcontentloaded" });
    const faviconLink = page.locator('link[rel="icon"]');
    await expect(faviconLink).toHaveAttribute("href", "assets/favicon.svg");
    const faviconUrl = new URL(await faviconLink.getAttribute("href")!, page.url());

    for (const scheme of ["light", "dark"] as const) {
      await page.emulateMedia({ colorScheme: scheme });
      expect(
        await page.evaluate(() => matchMedia("(prefers-color-scheme: dark)").matches),
      ).toBe(scheme === "dark");

      await page.evaluate((isDark) => {
        document.body.classList.toggle("dark", isDark);
      }, scheme === "dark");
      const response = await page.request.get(faviconUrl.href);
      expect(response.ok()).toBe(true);
      expect(await response.body()).toEqual(favicon);
      await expect(faviconLink).toHaveAttribute("href", "assets/favicon.svg");
    }

    await expect(page.locator("#threadline-mermaid-script")).toBeAttached();
  });
};

if (docsUrl) registerGeneratedDocsTests(docsUrl);
