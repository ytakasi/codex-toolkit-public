#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const envPath = path.join(repoRoot, ".env");
const env = { ...readEnvFile(envPath), ...process.env };
const checks = [];

const requiredEnv = ["DATABASE_URL"];
const pairedEnv = [["DISCORD_BOT_TOKEN", "DISCORD_ALERT_CHANNEL_ID"]];
const manualSurfaces = [
  "GitHub Actions secrets / variables",
  "ランタイム用 provider secrets",
  "database migrations and ランタイム用 DB grants",
  "worker / job deploy",
  "provider command / webhook / endpoint registration",
];

main();

function main() {
  checkRuntime();
  checkLocalFiles();
  checkEnv();

  console.log("🩺 setup:doctor");
  console.log("");
  for (const check of checks) {
    console.log(`${symbolFor(check.status)} ${check.label}: ${check.detail}`);
  }
  console.log("");
  printSummary();
  console.log("");
  printManualSurfaces();
}

function checkRuntime() {
  const [major] = process.versions.node.split(".").map(Number);
  addCheck(
    major >= 22 && major < 25 ? "ok" : "error",
    "Node.js",
    `${process.versions.node} ${major >= 22 && major < 25 ? "(supported)" : "(22 <= version < 25 required)"}`,
  );

  const pnpmVersion = readPackageManagerVersion();
  addCheck(pnpmVersion ? "ok" : "error", "pnpm", pnpmVersion ?? "not found");

  addCheck(
    existsSync(path.join(repoRoot, "node_modules")) ? "ok" : "warn",
    "node_modules",
    existsSync(path.join(repoRoot, "node_modules"))
      ? "exists"
      : "missing; run pnpm setup:init or pnpm install",
  );
}

function checkLocalFiles() {
  addCheck(
    existsSync(envPath) ? "ok" : "warn",
    ".env",
    existsSync(envPath) ? "exists" : "missing; run pnpm setup:init",
  );
}

function checkEnv() {
  for (const name of requiredEnv) {
    addCheck(hasValue(name) ? "ok" : "error", name, hasValue(name) ? "set" : "required");
  }

  for (const pair of pairedEnv) {
    const present = pair.filter(hasValue);
    addCheck(
      present.length === 0 || present.length === pair.length ? (present.length ? "ok" : "warn") : "error",
      pair.join(" + "),
      present.length === pair.length
        ? "all set"
        : present.length === 0
          ? "not set; okay if this feature is unused"
          : `partial pair: ${present.join(", ")}`,
    );
  }
}

function printSummary() {
  const errorCount = checks.filter((check) => check.status === "error").length;
  const warnCount = checks.filter((check) => check.status === "warn").length;

  if (errorCount > 0) {
    console.log(`Summary: setup incomplete. errors=${errorCount}, warnings=${warnCount}`);
  } else if (warnCount > 0) {
    console.log(`Summary: setup likely usable, but warnings=${warnCount}`);
  } else {
    console.log("Summary: setup looks clean.");
  }
}

function printManualSurfaces() {
  console.log("Manual external surfaces:");
  for (const surface of manualSurfaces) {
    console.log(`- ${surface}`);
  }
}

function hasValue(name) {
  return typeof env[name] === "string" && env[name].trim().length > 0;
}

function readEnvFile(filePath) {
  if (!existsSync(filePath)) {
    return {};
  }

  const entries = {};
  for (const rawLine of readFileSync(filePath, "utf8").split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }

    const separatorIndex = line.indexOf("=");
    if (separatorIndex <= 0) {
      continue;
    }

    const key = line.slice(0, separatorIndex).trim();
    let value = line.slice(separatorIndex + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    entries[key] = value;
  }

  return entries;
}

function readPackageManagerVersion() {
  const result =
    process.platform === "win32"
      ? spawnSync(process.env.ComSpec ?? "cmd.exe", ["/d", "/s", "/c", "corepack pnpm --version"], {
          cwd: repoRoot,
          encoding: "utf8",
        })
      : spawnSync("corepack", ["pnpm", "--version"], {
          cwd: repoRoot,
          encoding: "utf8",
        });

  if (result.error || result.status !== 0) {
    return null;
  }

  return result.stdout.trim();
}

function addCheck(status, label, detail) {
  checks.push({ status, label, detail });
}

function symbolFor(status) {
  if (status === "ok") return "✓";
  if (status === "warn") return "!";
  return "✗";
}
