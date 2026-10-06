const { createServer } = require('http');
const { parse } = require('url');
const next = require('next');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const dev = false;
const hostname = '0.0.0.0';
const port = 3000;

// Fix NEXTAUTH_URL if it has literal quotes wrapped around it
if (process.env.NEXTAUTH_URL && process.env.NEXTAUTH_URL.startsWith('"') && process.env.NEXTAUTH_URL.endsWith('"')) {
    process.env.NEXTAUTH_URL = process.env.NEXTAUTH_URL.slice(1, -1);
}
if (process.env.NEXTAUTH_URL && process.env.NEXTAUTH_URL.startsWith("'") && process.env.NEXTAUTH_URL.endsWith("'")) {
    process.env.NEXTAUTH_URL = process.env.NEXTAUTH_URL.slice(1, -1);
}

process.chdir(__dirname);

// Initialize the Next.js app
const app = next({ dev, hostname, port, dir: __dirname });
const handle = app.getRequestHandler();

let firmwareWorkerProcess = null;
let scheduledJobWorkerProcess = null;

function startFirmwareWorker() {
    if (process.env.FIRMWARE_WORKER_ENABLED !== 'true' || firmwareWorkerProcess) {
        return;
    }

    const npmCommand = process.platform === 'win32' ? 'npm.cmd' : 'npm';
    const launchWorker = () => {
        if (firmwareWorkerProcess) {
            return;
        }

        console.log(`[server] starting firmware worker: ${npmCommand} run firmware:watch`);
        try {
            // Clean env to avoid EINVAL on Windows
            const cleanEnv = {};
            for (const key in process.env) {
                if (key && process.env[key] !== undefined) {
                    cleanEnv[key] = process.env[key];
                }
            }

            firmwareWorkerProcess = spawn(npmCommand, ['run', 'firmware:watch'], {
                cwd: __dirname,
                stdio: 'inherit',
                env: cleanEnv,
                shell: true // Switch back to true to see if it helps with shell resolution
            });

            firmwareWorkerProcess.once('exit', (code, signal) => {
                console.log(`[firmware-worker] exited with code ${code} and signal ${signal}`);
                firmwareWorkerProcess = null;
                if (code !== 0 && signal == null) {
                    console.error(`[firmware-worker] restarting in 5 seconds.`);
                    setTimeout(launchWorker, 5000);
                }
            });

            firmwareWorkerProcess.once('error', (error) => {
                firmwareWorkerProcess = null;
                console.error('[firmware-worker] failed to start:', error);
                setTimeout(launchWorker, 5000);
            });
        } catch (err) {
            console.error('[firmware-worker] spawn error:', err);
        }
    };

    launchWorker();
}

function startScheduledJobWorker() {
    if (scheduledJobWorkerProcess) {
        return;
    }

    const npmCommand = process.platform === 'win32' ? 'npm.cmd' : 'npm';
    const launchWorker = () => {
        if (scheduledJobWorkerProcess) {
            return;
        }

        console.log(`[server] starting scheduled job worker: ${npmCommand} run scheduler`);
        try {
            // Clean env to avoid EINVAL on Windows
            const cleanEnv = {};
            for (const key in process.env) {
                if (key && process.env[key] !== undefined) {
                    cleanEnv[key] = process.env[key];
                }
            }

            scheduledJobWorkerProcess = spawn(npmCommand, ['run', 'scheduler'], {
                cwd: __dirname,
                stdio: 'inherit',
                env: cleanEnv,
                shell: true
            });

            scheduledJobWorkerProcess.once('exit', (code, signal) => {
                console.log(`[scheduled-job-worker] exited with code ${code} and signal ${signal}`);
                scheduledJobWorkerProcess = null;
                if (code !== 0 && signal == null) {
                    console.error(`[scheduled-job-worker] restarting in 5 seconds.`);
                    setTimeout(launchWorker, 5000);
                }
            });

            scheduledJobWorkerProcess.once('error', (error) => {
                scheduledJobWorkerProcess = null;
                console.error('[scheduled-job-worker] failed to start:', error);
                setTimeout(launchWorker, 5000);
            });
        } catch (err) {
            console.error('[scheduled-job-worker] spawn error:', err);
        }
    };

    launchWorker();
}

app.prepare()
    .then(() => {
        startFirmwareWorker();
        startScheduledJobWorker();
        createServer((req, res) => {
            try {
                // Force X-Forwarded-Proto to https to avoid protocol mismatch behind the proxy
                req.headers['x-forwarded-proto'] = 'https';
                
                const parsedUrl = parse(req.url, true);
                handle(req, res, parsedUrl);
            } catch (err) {
                console.error('Error occurred handling', req.url, err);
                res.statusCode = 500;
                res.end('internal server error');
            }
        })
        .once('error', (err) => {
            console.error(err);
            process.exit(1);
        })
        .listen(port, () => {
            console.log(`> Ready on http://${hostname}:${port}`);
        });
    })
    .catch((error) => {
        console.error('Failed to prepare Next.js app:', error);
        process.exit(1);
    });
