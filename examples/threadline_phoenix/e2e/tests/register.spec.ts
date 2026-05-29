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
    await expect(page.getByText("Signed in as")).toBeVisible();
    await expect(page.getByText(email)).toBeVisible();
  });
});
