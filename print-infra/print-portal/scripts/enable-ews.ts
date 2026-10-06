import { chromium } from "playwright";

export type EnableEwsResult = 
  | { status: "success" }
  | { status: "already-enabled" }
  | { status: "auth-required" }
  | { status: "error"; error: string };

function buildUrl(printerIp: string, protocol: string) {
    if (!printerIp) {
        throw new Error("Printer IP was not provided.");
    }

    let value = printerIp.trim();

    if (value.startsWith("http://") || value.startsWith("https://")) {
        value = value.replace(/\/$/, "");

        if (value.toLowerCase().endsWith("/hp/webservice")) {
            return value;
        }

        return value + "/hp/webservice";
    }

    return protocol + "://" + value + "/hp/webservice";
}

export async function enableHpEws(
    printerIp: string,
    printerPassword?: string,
    protocol: string = "http",
    headed: boolean = false
): Promise<EnableEwsResult> {
    const url = buildUrl(printerIp, protocol);
    console.log("Opening: " + url);

    const browser = await chromium.launch({ headless: !headed });
    const context = await browser.newContext({ ignoreHTTPSErrors: true });
    const page = await context.newPage();
    page.setDefaultTimeout(30000);

    try {
        const response = await page.goto(url, { waitUntil: "domcontentloaded", timeout: 60000 });
        if (response && (response.status() === 401 || response.status() === 403)) {
             // Basic auth or similar HTTP layer denial
             if (!printerPassword) {
                 await browser.close();
                 return { status: "auth-required" };
             }
        }

        await page.waitForLoadState("networkidle", { timeout: 15000 }).catch(() => {});

        const passwordBox = page.locator('input[type="password"]#PasswordTextBox');
        const passwordCount = await passwordBox.count();

        if (passwordCount > 0) {
            const isVisible = await passwordBox.first().isVisible().catch(() => false);

            if (isVisible) {
                if (!printerPassword) {
                    console.log("Password prompt detected, but no password was provided.");
                    await browser.close();
                    return { status: "auth-required" };
                }

                console.log("Password prompt detected. Filling in password.");
                await passwordBox.first().fill(printerPassword);

                await Promise.all([
                    page.waitForLoadState("domcontentloaded", { timeout: 30000 }).catch(() => {}),
                    page.locator('input[type="submit"]#signInOk').click()
                ]);

                await page.waitForLoadState("networkidle", { timeout: 15000 }).catch(() => {});

                // Ensure we proceed to webservice page or detect auth failure
                const newPasswordCount = await page.locator('input[type="password"]#PasswordTextBox').count();
                if (newPasswordCount > 0 && await page.locator('input[type="password"]#PasswordTextBox').first().isVisible().catch(() => false)) {
                     // Probably incorrect password
                     await browser.close();
                     return { status: "auth-required" };
                }
                
                // the redirect logic - sometimes it goes to index after login
                if (!page.url().toLowerCase().includes("/hp/webservice")) {
                     await page.goto(url, { waitUntil: "domcontentloaded", timeout: 30000 });
                     await page.waitForLoadState("networkidle", { timeout: 15000 }).catch(() => {});
                }
            }
        } else {
            console.log("No password prompt detected.");
        }

        const alreadyEnabledText = "Product E-mail Address";

        if (await page.getByText(alreadyEnabledText).count() > 0) {
            console.log("HP Web Services is already enabled.");
            await browser.close();
            return { status: "already-enabled" };
        }

        console.log("Looking for Enable HP Web Services button...");

        const enableButton = page.locator(
            'input[type="submit"][name="Register"][value="Enable HP Web Services"], ' +
            'input[type="submit"]#Register[value="Enable HP Web Services"], ' +
            'input.buttonPar[type="submit"][name="Register"][value="Enable HP Web Services"]'
        ).first();

        await enableButton.waitFor({ state: "visible", timeout: 15000 });

        console.log("Clicking Enable HP Web Services...");

        await Promise.all([
            page.waitForLoadState("domcontentloaded", { timeout: 30000 }).catch(() => {}),
            enableButton.click()
        ]);

        console.log("Success: HP Web Services successfully enabled.");
        await browser.close();
        return { status: "success" };

    } catch (error) {
        console.error("Failed to enable HP Web Services.", error);
        await browser.close();
        return { status: "error", error: error instanceof Error ? error.message : "Unknown error" };
    }
}
