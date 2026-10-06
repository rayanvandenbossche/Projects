import { runDueScheduledJobs } from "../src/lib/scheduledJobs";
import { advanceTonerWorkflows } from "../src/lib/msccRegistrationWorkflow";

const DEFAULT_INTERVAL_MS = 30000;
const POLL_INTERVAL_MS = Number.parseInt(process.env.SCHEDULED_JOB_POLL_INTERVAL_MS ?? String(DEFAULT_INTERVAL_MS), 10);

let isTickRunning = false;

async function tick(): Promise<void> {
  if (isTickRunning) {
    return;
  }

  isTickRunning = true;

  try {
    const processedCount = await runDueScheduledJobs();
    if (processedCount > 0) {
      console.log(`[scheduled-jobs] processed ${processedCount} job(s).`);
    } else {
      console.log("[scheduled-jobs] no due jobs found.");
    }
    
    // Also advance MSCC Registration (Toner) Workflows continuously
    await advanceTonerWorkflows().catch(err => {
      console.error("[scheduled-jobs] failed to advance MSCC Registration workflows:", err);
    });

  } catch (error) {
    console.error("[scheduled-jobs] failed to process due jobs:", error);
  } finally {
    isTickRunning = false;
  }
}

async function main(): Promise<void> {
  console.log("[scheduled-jobs] starting scheduler...");
  await tick();
  console.log("[scheduled-jobs] initial tick completed.");

  const intervalId = setInterval(() => {
    console.log("[scheduled-jobs] interval tick starting...");
    void tick();
  }, Number.isFinite(POLL_INTERVAL_MS) && POLL_INTERVAL_MS > 0 ? POLL_INTERVAL_MS : DEFAULT_INTERVAL_MS);

  const shutdown = () => {
    clearInterval(intervalId);
    process.exit(0);
  };

  process.once("SIGINT", shutdown);
  process.once("SIGTERM", shutdown);
}

void main().catch((error) => {
  console.error("[scheduled-jobs] scheduler stopped unexpectedly:", error);
  process.exit(1);
});