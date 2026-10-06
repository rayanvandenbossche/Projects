# Soudal Print Portal

This is the web portal and central print queue for the Soudal Print Infrastructure. It is built with [Next.js](https://nextjs.org/) (App Router), Prisma, and Tailwind CSS.

## Documentation

The full documentation for this project, including **Azure AD Setup**, **Local Development**, and **Production Deployment**, is located in the root repository Wiki pages (see the `wiki/` folder).

Please refer to the main repository wiki for instructions on how to set up, build, and deploy this portal.

## Quick Start (Dev)

Make sure you have your `.env.local` configured with your Azure AD credentials, then run:

```bash
npm install
npm run dev
```

The local development server will start on `https://localhost:3000` (using experimental HTTPS for Entra ID compatibility).

If you run Prisma CLI commands such as `npx prisma db push`, make sure `DATABASE_URL` is available in a plain `.env` file or exported in the shell first. Prisma does not read `.env.local` by default, so copying the database entry into `.env` is the simplest option.

## Windows Update Workflow

If the portal is running as an NSSM service on Windows Server, you can update it with a single command from the `print-portal` folder:

```bash
npm run update
```

That script will stop `SoudalPrintPortal2`, run `git pull --ff-only`, install dependencies from the lockfile, build the app, and start the service again. If you need a different service name, run `update.ps1` directly and pass `-ServiceName`.

The admin web button triggers the same update flow directly. For it to work unattended, the Windows account running the portal must already have permission to stop and start the NSSM service.
