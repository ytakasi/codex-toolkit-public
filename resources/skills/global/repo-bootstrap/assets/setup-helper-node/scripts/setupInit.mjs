#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import { copyFileSync, existsSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const args = new Set(process.argv.slice(2));
const dryRun = args.has("--dry-run");
const skipInstall = args.has("--skip-install");
const skipVerify = args.has("--skip-verify");

main();

function main() {
  console.log("🧰 setup:init");
  ensureEnvFile();

  if (skipInstall) {
    console.log("↷ install skipped.");
  } else {
    runPnpm(["install", "--frozen-lockfile"], "install dependencies");
  }

  if (skipVerify) {
    console.log("↷ build / test skipped.");
  } else {
    runPnpm(["build"], "build");
    runPnpm(["test"], "test");
  }

  console.log("");
  console.log("Next steps:");
  console.log("1. Fill .env");
  console.log("2. Run pnpm setup:doctor");
  console.log("3. Confirm DATABASE_URL before running migrations");
  console.log("4. Follow docs/setup.md for production bootstrap");
}

function ensureEnvFile() {
  const envPath = path.join(repoRoot, ".env");
  const examplePath = path.join(repoRoot, ".env.example");

  if (existsSync(envPath)) {
    console.log("✓ .env exists.");
    return;
  }

  if (!existsSync(examplePath)) {
    fail(".env.example not found.");
  }

  if (dryRun) {
    console.log("· would create .env from .env.example");
    return;
  }

  copyFileSync(examplePath, envPath);
  console.log("✓ created .env from .env.example.");
}

function runPnpm(args, label) {
  console.log(`${dryRun ? "·" : "→"} ${label}: corepack pnpm ${args.join(" ")}`);

  if (dryRun) {
    return;
  }

  const result = spawnPackageManager(args, {
    cwd: repoRoot,
    stdio: "inherit",
  });

  if (result.error) {
    fail(`${label} failed: ${result.error.message}`);
  }

  if (result.status !== 0) {
    fail(`${label} failed.`);
  }
}

function spawnPackageManager(args, options) {
  if (process.platform === "win32") {
    return spawnSync(process.env.ComSpec ?? "cmd.exe", [
      "/d",
      "/s",
      "/c",
      `corepack pnpm ${args.join(" ")}`,
    ], options);
  }

  return spawnSync("corepack", ["pnpm", ...args], options);
}

function fail(message) {
  console.error(`✗ ${message}`);
  process.exit(1);
}
