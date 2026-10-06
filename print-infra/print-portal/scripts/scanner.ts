import snmp from "net-snmp";
import { PrismaClient } from "@prisma/client";
import * as fs from "fs";
import * as path from "path";
import {
  fetchHpPrinterDiagnostics,
  fetchPrinterSerialNumber,
  fetchPrinterMacAddress,
  isHpPrinterModel,
  probePrinterReachable,
} from "../src/lib/printerDiagnostics";
import {
  appendScanEvent,
  beginScan,
  finalizeScan,
  shouldStopScan,
  type ScanPrinterSummary,
} from "../src/lib/scanPollState";
import {
  loadPrinterCatalog,
  refreshPrinterShareExport,
  resolveShareLocation,
  type PrinterCatalog,
} from "../src/lib/printerCatalog";
import { requireWritableCluster, syncClusterSnapshotToPeer } from "../src/lib/clusterSync";
import { resolveHpFirmwareSource } from "../src/lib/hpFirmwareRepository";

const prisma = new PrismaClient();
type SnmpSession = ReturnType<typeof snmp.createSession>;
type ScanMode = "network" | "existing" | "printer";


type SnmpVarbind = {
  value: { toString(): string };
  type?: number;
};

interface ActiveSubnet {
  startIp: string;
  endIp: string;
  description?: string;
  isActive: boolean;
}

interface KnownPrinterTarget {
  ipAddress: string;
}

type ScanTarget = {
  ip: string;
  location: string | null;
  shareName: string | null;
};

const mutatedPrinterIps = new Set<string>();

function getCliValue(flagName: string): string | null {
  const prefix = `${flagName}=`;
  const foundArgument = process.argv.find((argument) => argument.startsWith(prefix));
  return foundArgument ? foundArgument.slice(prefix.length) : null;
}

async function recordScanEvent(
  tone: "neutral" | "info" | "success" | "warning" | "error",
  text: string,
  printer?: ScanPrinterSummary,
  progress?: { completed: number; total: number; remaining: number }
): Promise<void> {
  console.log(text);
  await appendScanEvent({ tone, text, printer, progress });
}

function markPrinterMutation(ip: string): void {
  mutatedPrinterIps.add(ip);
}

// Common OIDs
const OID_SYS_DESCR = "1.3.6.1.2.1.1.1.0";
const OID_SYS_NAME = "1.3.6.1.2.1.1.5.0";
const OID_PAGE_COUNT = "1.3.6.1.2.1.43.10.2.1.4.1.1";
// Printer MIB (RFC 3805)
// prtMarkerSuppliesLevel
const OID_SUPPLIES_LEVEL_BASE = "1.3.6.1.2.1.43.11.1.1.9.1";
const MAX_CONCURRENT_SCANS = 25;

// Helper to convert IP to number for range iteration
function ipToLong(ip: string): number {
  return ip.split('.').reduce((acc, octet) => (acc << 8) + parseInt(octet, 10), 0) >>> 0;
}
function longToIp(long: number): string {
  return [ (long >>> 24) & 255, (long >>> 16) & 255, (long >>> 8) & 255, long & 255 ].join('.');
}

function normalizeSubnetLocation(description?: string): string | null {
  const trimmedDescription = description?.trim();
  return trimmedDescription && trimmedDescription.length > 0 ? trimmedDescription : null;
}

function resolveSubnetLocation(ip: string, subnets: ActiveSubnet[]): string | null {
  const ipValue = ipToLong(ip);

  for (const subnet of subnets) {
    const start = ipToLong(subnet.startIp);
    const end = ipToLong(subnet.endIp);
    if (ipValue >= start && ipValue <= end) {
      return normalizeSubnetLocation(subnet.description);
    }
  }

  return null;
}

function loadActiveSubnets(): ActiveSubnet[] {
  const dataPath = path.resolve(__dirname, "../data/subnets.json");

  if (!fs.existsSync(dataPath)) {
    return [];
  }

  try {
    const allSubnets = JSON.parse(fs.readFileSync(dataPath, "utf8")) as ActiveSubnet[];
    return allSubnets.filter((subnet) => subnet.isActive);
  } catch (error) {
    console.error("Failed to parse subnets.json", error);
    return [];
  }
}

// Helper to wrap snmp.get in a Promise
function getOid(session: SnmpSession, oid: string): Promise<string | null> {
  return new Promise((resolve) => {
    session.get([oid], (error: Error | null, varbinds: SnmpVarbind[]) => {
      if (error) {
        resolve(null);
      } else {
        if (snmp.isVarbindError(varbinds[0])) {
          resolve(null);
        } else {
          resolve(varbinds[0].value.toString());
        }
      }
    });
  });
}

function normalizeTonerLevel(rawValue: string | null): number | null {
  if (!rawValue || rawValue === "-3") {
    return null;
  }

  const parsedValue = parseInt(rawValue, 10);
  if (Number.isNaN(parsedValue) || parsedValue < 0) {
    return null;
  }

  return parsedValue > 100 ? 100 : parsedValue;
}

function normalizePageCount(rawValue: string | null): number | null {
  if (!rawValue) {
    return null;
  }

  const parsedValue = Number.parseInt(rawValue, 10);
  if (!Number.isFinite(parsedValue) || parsedValue < 0) {
    return null;
  }

  return parsedValue;
}

async function capturePrinterPageCount(session: SnmpSession): Promise<number | null> {
  return normalizePageCount(await getOid(session, OID_PAGE_COUNT));
}

async function persistPrinterPageCount(printerId: string, pageCount: number): Promise<void> {
  const capturedAt = new Date();

  await prisma.printer.update({
    where: { id: printerId },
    data: {
      pageCount,
      pageCountCapturedAt: capturedAt,
    },
  });

  await prisma.printerUsageSample.create({
    data: {
      printerId,
      pageCount,
      capturedAt,
    },
  });
}

async function scanDevice(target: ScanTarget, allowDiscovery: boolean): Promise<ScanPrinterSummary> {
  const { ip, location, shareName } = target;
  const existingPrinter = await prisma.printer.findUnique({ where: { ipAddress: ip } });
  const existingPrinterHostname = (existingPrinter as { hostname?: string | null } | null)?.hostname ?? null;
  const session = snmp.createSession(ip, "public", { timeout: 1000, retries: 0 });

  try {
    const sysDescr = await getOid(session, OID_SYS_DESCR);

    if (sysDescr) {
      const sysName = await getOid(session, OID_SYS_NAME) || "Unknown Printer";
      const sysDescrLower = sysDescr.toLowerCase();

      // Check if it's a printer (Usually mentions printer, HP, Ricoh, or Zebra)
      if (sysDescrLower.includes("printer") || sysDescrLower.includes("ricoh") || isHpPrinterModel(sysDescr) || sysDescrLower.includes("zebra")) {
        if (!existingPrinter && !allowDiscovery) {
          await recordScanEvent("warning", `Skipping discovered printer ${ip} because this refresh only targets printers already in the database.`);
          return {
            ip,
            name: null,
            model: null,
            manufacturer: null,
            status: "Unknown",
          };
        }

        let manufacturer = "Unknown";
        if (sysDescrLower.includes("ricoh")) manufacturer = "Ricoh";
        else if (isHpPrinterModel(sysDescr)) manufacturer = "HP";
        else if (sysDescrLower.includes("zebra")) manufacturer = "Zebra";

        // Try to get basic Black Toner Level (Index 1 is often black, but varies)
        // For real production, we would walk the prtMarkerSupplies description table first
        const blackToner = await getOid(session, `${OID_SUPPLIES_LEVEL_BASE}.1`);
        const cyanToner = await getOid(session, `${OID_SUPPLIES_LEVEL_BASE}.2`);
        const magentaToner = await getOid(session, `${OID_SUPPLIES_LEVEL_BASE}.3`);
        const yellowToner = await getOid(session, `${OID_SUPPLIES_LEVEL_BASE}.4`);

        const tonerPercent = normalizeTonerLevel(blackToner) ?? 85;
        const cyanPercent = normalizeTonerLevel(cyanToner);
        const magentaPercent = normalizeTonerLevel(magentaToner);
        const yellowPercent = normalizeTonerLevel(yellowToner);
        const macAddress = await fetchPrinterMacAddress(ip);
        const hpDiagnostics = isHpPrinterModel(sysDescr) ? await fetchHpPrinterDiagnostics(ip) : null;
        const hpModelName = hpDiagnostics?.model ?? sysDescr.substring(0, 50);
        const serialNumber = hpDiagnostics?.serialNumber ?? await fetchPrinterSerialNumber(ip);
        const hpFirmwareCache = isHpPrinterModel(sysDescr) ? await resolveHpFirmwareSource(prisma, hpModelName) : null;
        const hpFirmwareFields = hpFirmwareCache?.latestFirmwareVersion
          ? {
              latestFirmwareVersion: hpFirmwareCache.latestFirmwareVersion,
              latestFirmwareFetchedAt: hpFirmwareCache.fetchedAt,
            }
          : {};
        const printerName = shareName ?? existingPrinter?.name ?? sysName;
        const printerHostname = sysName === "Unknown Printer" ? existingPrinterHostname : sysName;
        const pageCount = await capturePrinterPageCount(session);

        const upsertedPrinter = await prisma.printer.upsert({
          where: { ipAddress: ip }, // Using IP as unique for the sake of the scan script
          update: {
            name: printerName,
            hostname: printerHostname,
            ...(macAddress ? { macAddress } : {}),
            model: hpModelName,
            manufacturer,
            status: "Online",
            tonerBlack: tonerPercent,
            tonerCyan: cyanPercent,
            tonerMagenta: magentaPercent,
            tonerYellow: yellowPercent,
            ...(pageCount !== null ? { pageCount, pageCountCapturedAt: new Date() } : {}),
            lastSeen: new Date(),
            ...(hpDiagnostics?.firmwareVersion ? { firmwareVersion: hpDiagnostics.firmwareVersion } : {}),
            ...(serialNumber ? { serialNumber } : {}),
            location: location ?? existingPrinter?.location ?? null,
            ...hpFirmwareFields,
          },
          create: {
            ipAddress: ip,
            macAddress: macAddress ?? `00:00:${ip.replace(/\./g, ':')}`,
            name: printerName,
            hostname: printerHostname,
            model: hpModelName,
            manufacturer,
            status: "Online",
            firmwareVersion: hpDiagnostics?.firmwareVersion ?? null,
            serialNumber: serialNumber ?? null,
            location: location ?? null,
            ...hpFirmwareFields,
            tonerBlack: tonerPercent,
            tonerCyan: cyanPercent,
            tonerMagenta: magentaPercent,
            tonerYellow: yellowPercent,
            ...(pageCount !== null ? { pageCount, pageCountCapturedAt: new Date() } : {}),
          }
        });
        if (pageCount !== null) {
          await persistPrinterPageCount(upsertedPrinter.id, pageCount);
        }
        markPrinterMutation(ip);
        return {
          ip,
          name: printerName,
          model: hpModelName,
          manufacturer,
          status: "Online",
        };
      }
    }

    const reachable = await probePrinterReachable(ip);

    if (reachable) {
      if (!existingPrinter && !allowDiscovery) {
        await recordScanEvent("warning", `Skipping reachable device ${ip} because this refresh only targets printers already in the database.`);
        return {
          ip,
          name: null,
          model: null,
          manufacturer: null,
          status: "Unknown",
        };
      }

      const hpDiagnostics = existingPrinter && isHpPrinterModel(existingPrinter.model) ? await fetchHpPrinterDiagnostics(ip) : null;
      const hpModelName = hpDiagnostics?.model ?? existingPrinter?.model ?? null;
      const serialNumber = hpDiagnostics?.serialNumber ?? await fetchPrinterSerialNumber(ip);
      const macAddress = await fetchPrinterMacAddress(ip);
      const hpFirmwareCache = hpModelName && (isHpPrinterModel(hpModelName) || isHpPrinterModel(existingPrinter?.model))
        ? await resolveHpFirmwareSource(prisma, hpModelName)
        : null;
      const hpFirmwareFields = hpFirmwareCache?.latestFirmwareVersion
        ? {
            latestFirmwareVersion: hpFirmwareCache.latestFirmwareVersion,
            latestFirmwareFetchedAt: hpFirmwareCache.fetchedAt,
          }
        : {};
      const updatedPrinterName = shareName ?? existingPrinter?.name ?? null;
      const pageCount = await capturePrinterPageCount(session);
      await prisma.printer.updateMany({
        where: { ipAddress: ip },
        data: {
          ...(updatedPrinterName ? { name: updatedPrinterName } : {}),
          status: "Online",
          lastSeen: new Date(),
          hostname: existingPrinterHostname,
          location: location ?? existingPrinter?.location ?? null,
          ...(macAddress ? { macAddress } : {}),
          ...(hpDiagnostics?.firmwareVersion ? { firmwareVersion: hpDiagnostics.firmwareVersion } : {}),
          ...(serialNumber ? { serialNumber } : {}),
          ...(pageCount !== null ? { pageCount, pageCountCapturedAt: new Date() } : {}),
          ...hpFirmwareFields,
        }
      });
      if (existingPrinter && pageCount !== null) {
        await persistPrinterPageCount(existingPrinter.id, pageCount);
      }
      markPrinterMutation(ip);

      return {
        ip,
        name: existingPrinter?.name ?? shareName ?? null,
        model: existingPrinter?.model ?? null,
        manufacturer: existingPrinter?.manufacturer ?? null,
        status: "Online",
      };
    } else {
      if (!existingPrinter && !allowDiscovery) {
        return {
          ip,
          name: null,
          model: null,
          manufacturer: null,
          status: "Unknown",
        };
      }

      // It didn't respond to SNMP or the HTTP/TCP probe, so mark it offline.
      await prisma.printer.updateMany({
        where: { ipAddress: ip },
        data: {
          ...(shareName ?? existingPrinter?.name ? { name: shareName ?? existingPrinter?.name } : {}),
          status: "Offline",
          hostname: existingPrinterHostname,
        }
      });
      markPrinterMutation(ip);

      return {
        ip,
        name: shareName ?? existingPrinter?.name ?? null,
        model: existingPrinter?.model ?? null,
        manufacturer: existingPrinter?.manufacturer ?? null,
        status: "Offline",
      };
    }
  } catch (error) {
    console.error(`Failed to scan device ${ip}`, error);
    await recordScanEvent("error", `Failed to scan device ${ip}`);
    return {
      ip,
      name: null,
      model: null,
      manufacturer: null,
      status: "Unknown",
    };
  } finally {
    session.close();
  }
}

async function collectScanTargets(mode: ScanMode): Promise<{
  targets: ScanTarget[];
  catalogMessages: Array<{ tone: "info" | "warning" | "success"; text: string }>;
  preMessages: Array<{ tone: "info" | "warning"; text: string }>;
  queueMessage: string;
  emptyMessage: string;
}> {
  const activeSubnets = loadActiveSubnets();
  const catalogMessages: Array<{ tone: "info" | "warning" | "success"; text: string }> = [];
  let printerCatalog: PrinterCatalog | null = null;

  if (mode === "network") {
    catalogMessages.push({ tone: "info", text: "Refreshing printer share catalog from the print servers." });
    try {
      await refreshPrinterShareExport();
      catalogMessages.push({ tone: "success", text: "Printer share catalog refreshed." });
    } catch (error) {
      catalogMessages.push({ tone: "warning", text: "Printer share export failed; using the last exported CSV if available." });
      console.error("Printer share export failed", error);
    }
  }

  printerCatalog = await loadPrinterCatalog();

  if (mode === "printer") {
    const printerIp = getCliValue("--printer-ip");
    const shareName = printerIp ? printerCatalog?.shareNameByIp.get(printerIp) ?? null : null;
    const subnetLocation = printerIp ? resolveSubnetLocation(printerIp, activeSubnets) : null;

    return {
      targets: printerIp ? [{ ip: printerIp, location: shareName && printerCatalog ? resolveShareLocation(shareName, printerCatalog.locationBySiteCode, subnetLocation) : subnetLocation, shareName }] : [],
      catalogMessages,
      preMessages: [{ tone: "info", text: printerIp ? `Refreshing printer ${printerIp}.` : "Printer IP is required for a single-printer refresh." }],
      queueMessage: printerIp ? "Queued 1 printer IP for refresh." : "",
      emptyMessage: printerIp ? "" : "Printer IP is required for a single-printer refresh.",
    };
  }

  if (mode === "existing") {
    const knownPrinters = (await prisma.printer.findMany({
      select: { ipAddress: true },
      orderBy: { ipAddress: "asc" },
    })) as KnownPrinterTarget[];

    const targets = Array.from(new Set(knownPrinters.map((printer) => printer.ipAddress).filter(Boolean))).map((ip) => {
      const shareName = printerCatalog?.shareNameByIp.get(ip) ?? null;
      const subnetLocation = resolveSubnetLocation(ip, activeSubnets);

      return {
        ip,
        location: shareName && printerCatalog ? resolveShareLocation(shareName, printerCatalog.locationBySiteCode, subnetLocation) : subnetLocation,
        shareName,
      };
    });
    return {
      targets,
      catalogMessages,
      preMessages: [{ tone: "info", text: "Refreshing printers already stored in the database." }],
      queueMessage: `Queued ${targets.length} existing printer IPs for refresh.`,
      emptyMessage: "No printers are stored in the database yet.",
    };
  }

  const rangeWarnings: string[] = [];

  const targets: ScanTarget[] = [];

  for (const subnet of activeSubnets) {
    const start = ipToLong(subnet.startIp);
    const end = ipToLong(subnet.endIp);

    if (start <= end && (end - start) <= 65536) {
      for (let i = start; i <= end; i++) {
        const ipStr = longToIp(i);
        if (ipStr.endsWith(".0") || ipStr.endsWith(".255")) {
          continue;
        }

        const shareName = printerCatalog?.shareNameByIp.get(ipStr) ?? null;
        const locationFromShare = shareName && printerCatalog
          ? resolveShareLocation(shareName, printerCatalog.locationBySiteCode, normalizeSubnetLocation(subnet.description))
          : normalizeSubnetLocation(subnet.description);

        targets.push({
          ip: ipStr,
          shareName,
          location: locationFromShare ?? normalizeSubnetLocation(subnet.description),
        });
      }
    } else {
      rangeWarnings.push(`Skipping invalid or excessively large range: ${subnet.startIp} - ${subnet.endIp}`);
    }
  }

  return {
    targets,
    catalogMessages,
    preMessages: [
      ...rangeWarnings.map((warning) => ({ tone: "warning" as const, text: warning })),
      { tone: "info", text: `Starting SNMP sweep across ${activeSubnets.length} defined IP ranges.` },
      ...activeSubnets.map((subnet) => ({
        tone: "info" as const,
        text: `Queuing sweep for ${subnet.startIp} - ${subnet.endIp} (${subnet.description || "No Description"})`,
      })),
    ],
    queueMessage: `Queued ${targets.length} printer IPs for scan.`,
    emptyMessage: "No active IP ranges found in data/subnets.json.",
  };
}

async function scanTargets(mode: ScanMode) {
  const { targets, catalogMessages, preMessages, queueMessage, emptyMessage } = await collectScanTargets(mode);

  if (targets.length === 0) {
    await recordScanEvent("error", emptyMessage);
    await finalizeScan("error", emptyMessage);
    return;
  }
  const total = targets.length;
  let completed = 0;
  await beginScan(total);

  for (const message of catalogMessages) {
    await recordScanEvent(message.tone, message.text);
  }

  for (const message of preMessages) {
    await recordScanEvent(message.tone, message.text);
  }

  await recordScanEvent("info", queueMessage, undefined, { completed, total, remaining: total });

  for (let i = 0; i < targets.length; i += MAX_CONCURRENT_SCANS) {
    if (await shouldStopScan()) {
      await recordScanEvent("warning", "Stop requested. Halting scan before the next batch.");
      await finalizeScan("stopped");
      return;
    }
    const batch = targets.slice(i, i + MAX_CONCURRENT_SCANS);
    await Promise.allSettled(batch.map(async (target) => {
      const result = await scanDevice(target, mode === "network");
      completed += 1;

      const remaining = Math.max(total - completed, 0);
      const tone = result.status === "Online" ? "success" : result.status === "Offline" ? "warning" : "error";
      await recordScanEvent(tone, `${result.name || result.model || result.ip} • ${result.status} • ${remaining} remaining`, result, {
        completed,
        total,
        remaining,
      });


    if (mutatedPrinterIps.size > 0) {
      await syncClusterSnapshotToPeer("scanner-batch");
      mutatedPrinterIps.clear();
    }
      return result;
    }));
  }

  if (await shouldStopScan()) {
    await recordScanEvent("warning", "Stop requested. Scan stopped after the current batch.");
    if (mutatedPrinterIps.size > 0) {
      await syncClusterSnapshotToPeer("scanner-complete");
      mutatedPrinterIps.clear();
    }
    await finalizeScan("stopped");
  } else {
    await recordScanEvent("success", mode === "existing" ? "Existing printer refresh completed. Database updated." : "Scan completed. Database updated.", undefined, {
      completed,
      total,
      remaining: 0,
    });
    await finalizeScan("completed");
  }
}

async function main() {
  const modeArgument = getCliValue("--mode") ?? (process.argv.some((argument) => argument === "--existing-only") ? "existing" : null);
  const mode = modeArgument === "existing" || modeArgument === "printer" ? modeArgument : "network";

  try {
    await requireWritableCluster();
    await scanTargets(mode);
  } catch (error) {
    console.error("Scan failed", error);
    await recordScanEvent("error", "Scan failed. See logs for details.");
    await finalizeScan("error", error instanceof Error ? error.message : "Unknown scan failure");
  } finally {
    await prisma.$disconnect();
  }
}

void main();
