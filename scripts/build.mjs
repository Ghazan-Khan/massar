#!/usr/bin/env node
// Cross-platform entry point for `npm run build`.
//
// The site generator itself is Windows PowerShell (scripts/build.ps1). The
// generated site is committed in dist/, so the build works in two modes:
//
//   * Windows: run scripts/build.ps1 to regenerate dist/.
//   * Linux/macOS (e.g. Hostinger's build container): validate the committed
//     dist/ artifact. PowerShell is not available there, and rewriting the
//     generated HTML is not necessary because dist/ is part of the repository.
//
// Set MASSAR_FORCE_STATIC=1 to use the static artifact even on Windows (useful
// for testing the deployment path without running the generator).

import { spawnSync } from 'node:child_process';
import { existsSync, statSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const distDir = join(root, 'dist');
const distIndex = join(distDir, 'index.html');

function fail(message) {
  console.error('Build failed: ' + message);
  process.exit(1);
}

function validateStaticArtifact() {
  if (!existsSync(distDir) || !statSync(distDir).isDirectory()) {
    fail('dist/ is missing. Run "npm run build" on Windows and commit dist/ before deploying.');
  }
  if (!existsSync(distIndex) || statSync(distIndex).size === 0) {
    fail('dist/index.html is missing or empty. Run "npm run build" on Windows and commit dist/.');
  }
  console.log('Using the committed static site in dist/.');
  console.log('Hostinger build setting: Output directory = dist');
}

const usePowerShell = process.platform === 'win32' && process.env.MASSAR_FORCE_STATIC !== '1';

if (!usePowerShell) {
  validateStaticArtifact();
  process.exit(0);
}

const result = spawnSync(
  'powershell',
  ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', join(root, 'scripts', 'build.ps1')],
  { cwd: root, stdio: 'inherit' }
);

if (result.error) {
  fail('could not start PowerShell: ' + result.error.message);
}
if (result.status !== 0) {
  fail('scripts/build.ps1 exited with code ' + result.status + '.');
}
