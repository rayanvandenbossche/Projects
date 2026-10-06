const { chromium } = require("playwright");
const printerIp = process.argv[2] || "";
const printerPassword = process.argv[3] || "";
const protocol = process.argv[4] || "http";
const headed = process.argv[5] === "true";

function buildUrl(printerIp, protocol) {
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

async function main() {
    const url = buildUrl(printerIp, protocol);

    console.log("Opening: " + url);

    const browser = await chromium.launch({
        headless: !headed
    });

    const context = await browser.newContext({
        ignoreHTTPSErrors: true
    });

    const page = await context.newPage();

    page.setDefaultTimeout(30000);

    try {
        await page.goto(url, {
            waitUntil: "domcontentloaded",
            timeout: 60000
        });

        await page.waitForLoadState("networkidle", {
            timeout: 15000
        }).catch(function () {});

        const passwordBox = page.locator('input[type="password"]#PasswordTextBox');

        const passwordCount = await passwordBox.count();

        if (passwordCount > 0) {
            const isVisible = await passwordBox.first().isVisible().catch(function () {
                return false;
            });

            if (isVisible) {
                if (!printerPassword) {
                    throw new Error("Password field found, but no password was provided.");
                }

                console.log("Password prompt detected.");

                await passwordBox.first().fill(printerPassword);

                await Promise.all([
                    page.waitForLoadState("domcontentloaded", {
                        timeout: 30000
                    }).catch(function () {}),
                    page.locator('input[type="submit"]#signInOk').click()
                ]);

                await page.waitForLoadState("networkidle", {
                    timeout: 15000
                }).catch(function () {});
            }
        }
        else {
            console.log("No password prompt detected.");
        }

        const alreadyEnabledText = "Product E-mail Address";

        if (await page.getByText(alreadyEnabledText).count() > 0) {
            console.log("HP Web Services is already enabled.");
            await browser.close();
            process.exit(0);
        }

        console.log("Looking for Enable HP Web Services button...");

        const enableButton = page.locator(
            'input[type="submit"][name="Register"][value="Enable HP Web Services"], ' +
            'input[type="submit"]#Register[value="Enable HP Web Services"], ' +
            'input.buttonPar[type="submit"][name="Register"][value="Enable HP Web Services"]'
        ).first();

        await enableButton.waitFor({
            state: "visible",
            timeout: 60000
        });

        console.log("Clicking Enable HP Web Services...");

        await Promise.all([
            page.waitForLoadState("domcontentloaded", {
                timeout: 30000
            }).catch(function () {}),
            enableButton.click()
        ]);

        console.log("Success: HP Web Services successfully enabled.");

        await browser.close();
        process.exit(0);
    }
    catch (error) {
        console.error("Failed to enable HP Web Services.");
        console.error(error.message);

        await page.screenshot({
            path: "hp-ews-error.png",
            fullPage: true
        }).catch(function () {});

        await browser.close();
        process.exit(1);
    }
}

main().catch(function (error) {
    console.error(error.message);
    process.exit(1);
});