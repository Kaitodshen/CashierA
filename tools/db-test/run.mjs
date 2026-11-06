// Runs supabase/migrations, supabase/seed.sql and supabase/tests/database/*.test.sql
// on PGlite (PostgreSQL compiled to WebAssembly). No Docker or Supabase CLI needed.
//
//   node run.mjs                 # migrations + seed + all tests
//   node run.mjs --migrate-only  # migrations + seed, no tests
//   node run.mjs --only 020      # tests whose file name contains "020"
//
// Exit code 0 = everything passed.

import { PGlite } from '@electric-sql/pglite';
import { pgcrypto } from '@electric-sql/pglite/contrib/pgcrypto';
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { dirname, join, resolve, basename } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const supabaseDir = resolve(here, '..', '..', 'supabase');
const args = process.argv.slice(2);
const migrateOnly = args.includes('--migrate-only');
const onlyIndex = args.indexOf('--only');
const only = onlyIndex >= 0 ? args[onlyIndex + 1] : null;

const read = (path) => readFileSync(path, 'utf8');
const sqlFiles = (dir, suffix) =>
  existsSync(dir)
    ? readdirSync(dir).filter((f) => f.endsWith(suffix)).sort().map((f) => join(dir, f))
    : [];

function describeError(error) {
  const parts = [error.message];
  if (error.detail) parts.push(`detail: ${error.detail}`);
  if (error.hint) parts.push(`hint: ${error.hint}`);
  if (error.where) parts.push(`where: ${error.where}`);
  if (error.position) parts.push(`position: ${error.position}`);
  return parts.join('\n    ');
}

async function applyFile(db, path, { transaction = true } = {}) {
  const sql = read(path);
  try {
    await db.exec(transaction ? `begin;\n${sql}\ncommit;` : sql);
  } catch (error) {
    await db.exec('rollback').catch(() => {});
    console.error(`\n✗ ${basename(path)}\n    ${describeError(error)}`);
    process.exit(1);
  }
}

const started = Date.now();
const db = await PGlite.create({ extensions: { pgcrypto } });

await applyFile(db, join(here, 'supabase-shim.sql'), { transaction: false });

const migrations = sqlFiles(join(supabaseDir, 'migrations'), '.sql');
for (const file of migrations) {
  await applyFile(db, file);
  console.log(`✓ migration ${basename(file)}`);
}

const seed = join(supabaseDir, 'seed.sql');
if (existsSync(seed)) {
  await applyFile(db, seed);
  console.log('✓ seed.sql');
}

if (migrateOnly) {
  console.log(`\nDone in ${((Date.now() - started) / 1000).toFixed(1)}s`);
  process.exit(0);
}

await applyFile(db, join(here, 'pgtap-shim.sql'), { transaction: false });

let tests = sqlFiles(join(supabaseDir, 'tests', 'database'), '.test.sql');
// 000_* files install shared helpers, so they always run.
if (only) tests = tests.filter((f) => basename(f).startsWith('000') || basename(f).includes(only));

let totalRun = 0;
let totalFailed = 0;
const failedFiles = [];

for (const file of tests) {
  // The real pgTAP extension is created by the tests on Supabase; the shim replaces it here.
  const sql = read(file).replace(/^\s*create extension[^;]*pgtap[^;]*;\s*$/gim, '');
  const name = basename(file);
  let lines = [];
  let crashed = null;
  try {
    const results = await db.exec(sql);
    for (const result of results) {
      for (const row of result.rows ?? []) {
        for (const value of Object.values(row)) {
          if (typeof value === 'string' && /^(ok |not ok |# |1\.\.)/.test(value)) {
            lines.push(...value.split('\n'));
          }
        }
      }
    }
  } catch (error) {
    crashed = describeError(error);
    await db.exec('rollback').catch(() => {});
  }

  const run = lines.filter((l) => /^(ok|not ok) /.test(l)).length;
  const failed = lines.filter((l) => l.startsWith('not ok ')).length;
  const planLine = lines.find((l) => l.startsWith('1..'));
  const planned = planLine ? Number(planLine.slice(3)) : null;
  const planMismatch = planned !== null && planned !== run;
  totalRun += run;

  if (crashed || failed > 0 || planMismatch) {
    totalFailed += failed || 1;
    failedFiles.push(name);
    console.log(`\n✗ ${name}`);
    for (const line of lines) {
      if (line.startsWith('not ok ') || line.startsWith('# ')) console.log(`    ${line}`);
    }
    if (planMismatch) console.log(`    # planned ${planned} tests but ran ${run}`);
    if (crashed) console.log(`    crashed after ${run} assertions:\n    ${crashed}`);
  } else {
    console.log(`✓ ${name} (${run} assertions)`);
  }
}

const seconds = ((Date.now() - started) / 1000).toFixed(1);
if (failedFiles.length) {
  console.log(`\nFAILED: ${failedFiles.length} of ${tests.length} test files (${totalRun} assertions ran) in ${seconds}s`);
  process.exit(1);
}
console.log(`\nAll ${tests.length} test files passed (${totalRun} assertions) in ${seconds}s`);
