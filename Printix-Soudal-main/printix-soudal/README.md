# Printix Scripts – Usage Guide

This repository contains two scripts used with Printix exports:

- printers/Update-PrintixPrinterNames.ps1
- networks/Discover-PrintixGateways.ps1

---

## Prerequisites

1. Export the required CSV files from the Printix Configurator.
2. Place the files in the correct folders:

printers/Printix Printers.csv
networks/printers_ranges.csv

---

# Update Printer Names

Script: printers/Update-PrintixPrinterNames.ps1

## Steps

1. Open Printix Configurator
2. Export the printer list as:

   Printix Printers.csv

3. Place the file in:

   .\printers\

4. Open PowerShell and navigate to the printers folder:

   cd .\printers

5. Run the script:

   .\Update-PrintixPrinterNames.ps1

## Result

- A new updated CSV file is created in the same folder
- A backup of the original file is created
- A log file is generated

Review the updated CSV before importing it back into Printix.

---

# Discover Gateways

**This is a one time step.**
Script: networks/Discover-PrintixGateways.ps1

## Steps

1. Open the print portal at https://printportal.soudal.com/admin/subnets
2. Export or prepare the network ranges file as:

   printers_ranges.csv

3. Place the file in:

   .\networks\

4. Open PowerShell and navigate to the networks folder:

   cd .\networks

5. Run the script:

   .\Discover-PrintixGateways.ps1

## Result

- A new file is generated:

   Printix Networks.csv

Use this file for import into Printix.

---

# Summary Workflow

1. Export CSV files from Printix Configurator
2. Place them in the correct folders
3. Run the corresponding script
4. Review generated CSV files
5. Import the updated files back into Printix
