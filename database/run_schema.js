#!/usr/bin/env node
/**
 * Convenience script to apply database/schema.sql on a local Postgres instance.
 *
 * Usage:
 *   PGUSER=postgres PGPASSWORD=secret node database/run_schema.js
 *
 * The script respects the standard PG* environment variables, with sensible local defaults.
 */

const fs = require('fs/promises');
const path = require('path');
const { Client } = require('pg');

async function main() {
  const schemaPath = path.join(__dirname, 'schema.sql');
  const sql = await fs.readFile(schemaPath, 'utf8');

  const client = new Client({
    host: process.env.PGHOST || 'localhost',
    port: Number(process.env.PGPORT) || 5432,
    user: process.env.PGUSER || 'postgres',
    password: process.env.PGPASSWORD || undefined,
    database: process.env.PGDATABASE || 'volleyleague',
    ssl: process.env.PGSSLMODE === 'require',
  });

  await client.connect();

  try {
    await client.query(sql);
    console.log(`Schema applied successfully from ${schemaPath}`);
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error('Failed to apply schema:', error);
  process.exitCode = 1;
});
