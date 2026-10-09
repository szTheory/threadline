import type { BrowserContext, BrowserType, Page, ServiceWorker } from "@playwright/test";
import { mkdtempSync, rmSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";

const extensionPath = resolve(
  dirname(fileURLToPath(import.meta.url)),
  "operator-zoom-extension",
);

export type TabZoomObservation = {
  tabId: number;
  url: string;
  zoomFactor: number;
};

export async function withIsolatedZoomContext<T>(
  browserType: BrowserType,
  run: (context: BrowserContext, page: Page) => Promise<T>,
): Promise<T> {
  const userDataDir = mkdtempSync(join(tmpdir(), "threadline-zoom-proof-"));
  let context: BrowserContext | undefined;

  try {
    context = await browserType.launchPersistentContext(userDataDir, {
      channel: "chromium",
      headless: false,
      args: [
        `--disable-extensions-except=${extensionPath}`,
        `--load-extension=${extensionPath}`,
      ],
    });
    const page = context.pages()[0] ?? (await context.newPage());
    return await run(context, page);
  } finally {
    await context?.close();
    rmSync(userDataDir, { recursive: true, force: true });
  }
}

export async function setAndReadTabZoom(
  context: BrowserContext,
  page: Page,
): Promise<TabZoomObservation> {
  let worker = context
    .serviceWorkers()
    .find((candidate) => candidate.url().startsWith("chrome-extension://"));

  if (!worker) {
    worker = await context.waitForEvent("serviceworker", { timeout: 15_000 });
  }

  const result = await sendZoomRequest(worker, page);
  if ("error" in result) throw new Error(result.error);

  const pageUrl = page.url();
  if (result.url !== pageUrl) {
    throw new Error(`Zoom worker measured ${result.url}, expected the checked tab ${pageUrl}`);
  }
  if (result.zoomFactor !== 2) {
    throw new Error(`Chrome tabs.getZoom returned ${result.zoomFactor}, expected 2`);
  }

  return result;
}

async function sendZoomRequest(
  worker: ServiceWorker,
  page: Page,
): Promise<TabZoomObservation | { error: string }> {
  const targetUrl = page.url();
  return worker.evaluate(async (url) => {
    const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
    const tab = tabs.find((candidate) => candidate.url === url);
    if (!tab?.id) throw new Error(`Could not identify the test-owned tab at ${url}`);
    if (!tab.url.startsWith("http://127.0.0.1:")) {
      throw new Error("Zoom proof may target only its own loopback test tab");
    }

    await chrome.tabs.setZoom(tab.id, 2);
    const zoomFactor = await chrome.tabs.getZoom(tab.id);
    return { tabId: tab.id, url: tab.url, zoomFactor };
  }, targetUrl);
}
