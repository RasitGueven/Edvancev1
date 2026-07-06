import { expect, test } from '@playwright/test'

// Smoke test: the app boots and the login screen renders.
// `/` redirects to `/login`, which shows email + password fields.
test('app loads and renders the login screen', async ({ page }) => {
  await page.goto('/')
  await expect(page).toHaveURL(/\/login$/)
  await expect(page.locator('input[type="email"]')).toBeVisible()
  await expect(page.locator('input[type="password"]')).toBeVisible()
})
