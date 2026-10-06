const { execSync, spawnSync } = require("child_process");
const fs = require("fs");
const path = require("path");

try {
  require.resolve("dotenv");
  require.resolve("playwright");
} catch (e) {
  console.log("Missing dependencies detected. Installing...");
  execSync("npm install", { cwd: __dirname, stdio: "inherit" });
  execSync("npx playwright install chromium", { cwd: __dirname, stdio: "inherit" });
}

require("dotenv").config();
const { chromium } = require("playwright");

try {
  const executablePath = chromium.executablePath();
  if (!fs.existsSync(executablePath)) {
    console.log("Playwright chromium binary missing (checked " + executablePath + "). Installing...");
    execSync("npx playwright install chromium", { cwd: __dirname, stdio: "inherit" });
  }
} catch (e) {
  console.log("Error checking for browser path, attempting install...");
  execSync("npx playwright install chromium", { cwd: __dirname, stdio: "inherit" });
}

function parseCliArgs() {
  const args = process.argv.slice(2);
  const parsed = {};
  for (let i = 0; i < args.length; i++) {
    if (args[i].startsWith("--")) {
      const parts = args[i].substring(2).split("=");
      const key = parts[0];
      const val = parts.length > 1 ? parts.slice(1).join("=") : true;
      parsed[key] = val;
    }
  }
  return parsed;
}

const cliArgs = parseCliArgs();
const MSCC_EMAIL = (cliArgs.email && cliArgs.email !== true) ? cliArgs.email : (process.env.MSCC_EMAIL || process.env.DCC_EMAIL);
const MSCC_PASSWORD = (cliArgs.password && cliArgs.password !== true) ? cliArgs.password : (process.env.MSCC_PASSWORD || process.env.DCC_PASSWORD);
const PS_SCRIPT = process.env.MSCC_PS_SCRIPT || ".\\Get-MsccDeviceAssets.ps1";
const OUT_DIR = process.env.MSCC_OUT_DIR || "C:\\Temp\\MSCC";

function requireValue(name, value) {
  if (!value || String(value).trim() === "") {
    throw new Error("Missing required .env value: " + name);
  }
}

async function main() {
  requireValue("MSCC_EMAIL (or --email=...)", MSCC_EMAIL);
  requireValue("MSCC_PASSWORD (or --password=...)", MSCC_PASSWORD);

  if (!fs.existsSync(PS_SCRIPT)) {
    throw new Error("PowerShell script not found: " + PS_SCRIPT);
  }

  const isHeadless = false;
  
  const browser = await chromium.launch({
    headless: isHeadless,
    args: [
      "--disable-blink-features=AutomationControlled",
      "--disable-dev-shm-usage",
      "--disable-gpu",
      "--no-first-run",
      "--no-default-browser-check",
      "--disable-extensions"
    ]
  });
  
  const context = await browser.newContext();
  const page = await context.newPage();
  
  // Set viewport to avoid headless detection
  await page.setViewportSize({
    width: 1920,
    height: 1080
  });

  let bearerToken = null;

  page.on("request", (request) => {
    const url = request.url();
    if (url.startsWith("https://print.services.api.hp.com/")) {
      const headers = request.headers();
      if (headers["authorization"] && headers["authorization"].startsWith("Bearer ")) {
        bearerToken = headers["authorization"].substring(7);
      }
    }
  });

  try {
    console.log("Navigating to MSCC...");
    await page.goto("https://mscc.ext.hp.com/us/en/", { waitUntil: "domcontentloaded", timeout: 150000 });

    console.log("Clicking initial HP Customer login button...");
    const customerLoginBtn = page.locator('#btnHPCustomer');
    await customerLoginBtn.waitFor({ state: "visible", timeout: 15000 }).catch(() => {});
    if (await customerLoginBtn.isVisible()) {
      await customerLoginBtn.click();
    }

    // Wait for the login button / form
    // Since MSCC usually has a redirect loop via HP ID, we'll implement a robust wait for the username field
    console.log("Waiting for HP ID Login form...");
    const emailInput = page.locator('input[type="email"], input[name="username"], input[id="username"]').first();
    await emailInput.waitFor({ state: "visible", timeout: 60000 });
    
    console.log("Filling email...");
    await emailInput.fill(MSCC_EMAIL.toString().trim());
    const nextBtn = page.locator('button[type="submit"], input[type="submit"], button:has-text("Next")').first();
    await nextBtn.click();

    console.log("Waiting for password field...");
    const passwordInput = page.locator('input[type="password"], input[name="password"]').first();
    await passwordInput.waitFor({ state: "visible", timeout: 150000 });
    
    console.log("Filling password...");
    // Give HP ID a moment to settle animation
    await page.waitForTimeout(2000); 
    await passwordInput.fill(String(MSCC_PASSWORD));

    const submitBtn = page.locator('button[type="submit"], input[type="submit"], button:has-text("Sign in")').first();
    await submitBtn.click();

    console.log("Logging in... waiting for MSCC portal redirection...");

    // Wait until bearerToken is successfully captured
    let attempts = 0;
    while(!bearerToken && attempts < 15000) {
        await page.waitForTimeout(1000);
        attempts++;
    }

    if (!bearerToken) {
       throw new Error("Failed to capture Authorization Bearer token within 150 seconds of login.");
    }

    console.log("Bearer token intercepted successfully.");
    console.log("Starting PowerShell report downloader...");

    const psArgs = [
      "-ExecutionPolicy", "Bypass",
      "-File", PS_SCRIPT,
      "-BearerToken", bearerToken,
      "-OutDir", OUT_DIR
    ];

    const result = spawnSync("powershell", psArgs, {
      stdio: "inherit",
      windowsHide: true,
      env: process.env
    });

    if (result.error) {
      throw result.error;
    }

    console.log("Done.");
  } catch (err) {
    console.error("Error:", err);
    await page.screenshot({ path: "mscc-error.png" }).catch(()=>{});
  } finally {
    await browser.close();
  }
}

main();