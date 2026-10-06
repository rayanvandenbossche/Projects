# Printer management portal

This repo contains the code to the printer management portal. In this app you can manage all the printers on the network without any effort. 

For more info please visit the [wiki](https://git.pefki.xyz/pefki/print-infra/wiki).

## Important functions
- Fetching printer status
- Searching for new printers in defined ip ranges
- Automatically adding an HP printer to MSCC
- Usage statistics of all printers
- Scheduling
- Location based on share name
- Finding the most recent firmware version (HP only)
- Advanced searching (share name, serial number, manufacturer, model, IP, hostname, location) 


Quick start (developer)
-----------------------
Prerequisites:
- Node.js (18+ recommended)
- npm
Start dev server:

```bash
cd print-portal
npm install
# Ensure Prisma client is in sync with the schema
npx prisma db push

# Optional: type-check the project
npx tsc --noEmit

# Start development server
npm run dev
```

Production build
----------------
```bash
cd print-portal
npm install
npx prisma generate
npx prisma db push
npm run build
npm start
```
For more reliable deployment check the [wiki](https://git.pefki.xyz/pefki/print-infra/wiki/Deployment).

Prisma / database
-----------------
- Schema: `prisma/schema.prisma` is the canonical data model.
- After schema edits run:

```bash
npx prisma generate
npx prisma db push
```


Update portal (deploy new build)
-------------------------------
If you need to update the running portal from source (for example after pulling new code), run these steps on the server or deployment host:

```bash
cd print-portal
npm run update
```


