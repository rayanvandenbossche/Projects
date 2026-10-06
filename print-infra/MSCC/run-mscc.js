require("dotenv").config();

const { chromium } = require("playwright");
const { spawnSync } = require("child_process");
const fs = require("fs");

const MSCC_URL = "https://mscc.ext.hp.com/us/en/";
const PS_SCRIPT = process.env.MSCC_PS_SCRIPT || ".\\Get-MsccDeviceAssets.ps1";
const OUT_DIR = process.env.MSCC_OUT_DIR || "./out";

function requireValue(name, value) {
  if (!value || String(value).trim() === "") {
    throw new Error("Missing required value: " + name);
  }
}

async function main() {
  if (!fs.existsSync(PS_SCRIPT)) {
    throw new Error("PowerShell script not found: " + PS_SCRIPT);
  }

  const browser = await chromium.launch({
    headless: false,
    slowMo: 100
  });

  const context = await browser.newContext({
    viewport: { width: 1400, height: 900 }
  });

  const page = await context.newPage();
  
  let bearerToken = null;

  // Intercept the request to get the Bearer token
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
    console.log("Opening MSCC...");
    await page.goto(MSCC_URL, { waitUntil: "domcontentloaded", timeout: 60000 });

    console.log("");
    console.log("============================================================");
    console.log("Please log in manually in the opened browser.");
    console.log("Navigate until the Bearer token is intercepted in the background.");
    console.log("============================================================");
    console.log("");

    // Wait until bearerToken is successfully captured
    await page.waitForFunction(() => {
      return window.bearerTokenFound === true;
    }, null, { timeout: 0, polling: 1000 }).catch(() => {});
    
    // As alternative without injecting window.bearerTokenFound we can just loop
    while(!bearerToken) {
        await page.waitForTimeout(1000);
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
  } finally {
    await browser.close();
  }
}

main();