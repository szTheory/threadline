import { test, expect } from "@playwright/test";

const password = process.env.DEMO_SEED_PASSWORD ?? "password123456";

test.describe("register UX", () => {
  test("register lands on home signed in", async ({ page }) => {
    const email = `e2e-${Date.now()}@example.com`;

    await page.goto("/users/register", { waitUntil: "domcontentloaded" });
    await page.locator("#registration_form").getByLabel("Email").fill(email);
    await page.locator("#registration_form").getByLabel("Password").fill(password);
    await page.getByRole("button", { name: /create an account/i }).click();

    await expect(page).toHaveURL("/");
    // Scoped to the home hero's own signed-in badge (`.rd-signed-in`): the
    // shared topbar nav also renders a "Signed in as" identity badge
    // (`.rd-nav__identity`, added for the v1.38 UI polish) on every
    // authenticated page, so an unscoped `getByText("Signed in as")` now
    // resolves two elements on this page and violates Playwright's strict
    // mode. Scoping to the hero's own container keeps the assertion a shape
    // check (the hero surface is reachable and exposes its signed-in
    // affordance) rather than a global text search that a future nav change
    // can collide with again.
    const heroSignedIn = page.locator(".rd-signed-in");
    await expect(heroSignedIn).toBeVisible();
    await expect(heroSignedIn.getByText("Signed in as")).toBeVisible();
    await expect(heroSignedIn.getByText(email)).toBeVisible();
  });
});
