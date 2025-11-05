#!/usr/bin/env python3
"""
Convenience script to apply database/schema.sql on a local Postgres instance.

Usage:
  PGUSER=postgres PGPASSWORD=secret python database/run_schema.py

The script respects the standard PG* environment variables, with sensible local defaults.
"""

import os
import sys
from pathlib import Path
import asyncpg
import asyncio


async def main():
    # Get the directory of this script
    script_dir = Path(__file__).parent
    schema_path = script_dir / "schema.sql"
    
    # Read the schema file
    with open(schema_path, "r", encoding="utf-8") as f:
        sql = f.read()
    
    # Connection parameters from environment variables
    connection_params = {
        "host": os.environ.get("PGHOST", "localhost"),
        "port": int(os.environ.get("PGPORT", 5432)),
        "user": os.environ.get("PGUSER", "postgres"),
        "password": os.environ.get("PGPASSWORD"),
        "database": os.environ.get("PGDATABASE", "antonidebicki"),
    }
    # Enable SSL only for encryption if requested
    if os.environ.get("PGSSLMODE") == "require":
        connection_params["ssl"] = True
    
    print(f"Connecting to database: {connection_params['database']} at {connection_params['host']}:{connection_params['port']}")
    
    # Connect to the database
    conn = await asyncpg.connect(**connection_params)
    
    try:
        # Execute the schema
        await conn.execute(sql)
        print(f"✓ Schema applied successfully from {schema_path}")
    except Exception as e:
        print(f"✗ Failed to apply schema: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        await conn.close()


if __name__ == "__main__":
    asyncio.run(main())
