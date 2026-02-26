#!/usr/bin/env node
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';

function requireWithFallback(specifier) {
  const candidates = [];

  if (process.argv[1]) {
    candidates.push(path.resolve(process.argv[1]));
  }
  candidates.push(fileURLToPath(import.meta.url));

  let lastError;
  for (const filePath of candidates) {
    try {
      const req = createRequire(pathToFileURL(filePath));
      return req(specifier);
    } catch (error) {
      lastError = error;
    }
  }

  throw lastError;
}

const pgModule = requireWithFallback('pg');
const zodModule = requireWithFallback('zod');
const mcpServerModule = requireWithFallback('@modelcontextprotocol/sdk/server/mcp.js');
const stdioModule = requireWithFallback('@modelcontextprotocol/sdk/server/stdio.js');

const pg = pgModule.default ?? pgModule;
const { z } = zodModule;
const { McpServer, ResourceTemplate } = mcpServerModule;
const { StdioServerTransport } = stdioModule;

const { Pool } = pg;

const databaseUrl = process.argv[2] || process.env.POSTGRES_DSN || process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error('Missing PostgreSQL DSN. Pass it as argv[2] or set POSTGRES_DSN/DATABASE_URL.');
  process.exit(1);
}

const pool = new Pool({ connectionString: databaseUrl });

const server = new McpServer({
  name: 'local/postgres',
  version: '1.0.0',
});

async function withClient(fn) {
  const client = await pool.connect();
  try {
    return await fn(client);
  } finally {
    client.release();
  }
}

function jsonResource(uri, payload) {
  return {
    contents: [{
      uri,
      mimeType: 'application/json',
      text: JSON.stringify(payload, null, 2),
    }],
  };
}

async function listUserTables() {
  return withClient(async (client) => {
    const { rows } = await client.query(`
      SELECT table_schema, table_name
      FROM information_schema.tables
      WHERE table_type = 'BASE TABLE'
        AND table_schema NOT IN ('pg_catalog', 'information_schema')
      ORDER BY table_schema, table_name
    `);
    return rows;
  });
}

server.registerResource(
  'pg-health',
  'postgres://meta/health',
  {
    title: 'PostgreSQL health',
    description: 'Connectivity check and basic server metadata',
    mimeType: 'application/json',
  },
  async (uri) => {
    const payload = await withClient(async (client) => {
      const { rows } = await client.query(`
        SELECT current_database() AS database,
               current_user AS user_name,
               version() AS version,
               now() AS server_time
      `);
      return rows[0];
    });
    return jsonResource(uri.href, payload);
  }
);

server.registerResource(
  'pg-tables',
  'postgres://meta/tables',
  {
    title: 'PostgreSQL tables',
    description: 'List of non-system base tables across schemas',
    mimeType: 'application/json',
  },
  async (uri) => {
    const tables = await listUserTables();
    return jsonResource(uri.href, { count: tables.length, tables });
  }
);

const schemaTemplate = new ResourceTemplate('postgres://schema/{schema}/{table}', {
  list: async () => {
    const tables = await listUserTables();
    return {
      resources: tables.map((t) => ({
        uri: `postgres://schema/${encodeURIComponent(t.table_schema)}/${encodeURIComponent(t.table_name)}`,
        name: `${t.table_schema}.${t.table_name} schema`,
        mimeType: 'application/json',
      })),
    };
  },
});

server.registerResource(
  'pg-table-schema',
  schemaTemplate,
  {
    title: 'Table schema',
    description: 'Column metadata for a concrete PostgreSQL table',
    mimeType: 'application/json',
  },
  async (uri, vars) => {
    const schema = decodeURIComponent(String(vars.schema ?? ''));
    const table = decodeURIComponent(String(vars.table ?? ''));

    const payload = await withClient(async (client) => {
      const columns = await client.query(`
        SELECT ordinal_position, column_name, data_type, is_nullable, column_default
        FROM information_schema.columns
        WHERE table_schema = $1 AND table_name = $2
        ORDER BY ordinal_position
      `, [schema, table]);

      const counts = await client.query(`
        SELECT COUNT(*)::bigint AS row_count
        FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = $1 AND c.relname = $2
      `, [schema, table]);

      return {
        schema,
        table,
        row_count: counts.rows[0]?.row_count ?? null,
        columns: columns.rows,
      };
    });

    return jsonResource(uri.href, payload);
  }
);

server.registerTool(
  'query',
  {
    description: 'Run a read-only SQL query against PostgreSQL',
    inputSchema: {
      sql: z.string().min(1),
      limit: z.number().int().min(1).max(1000).optional(),
    },
  },
  async ({ sql, limit }) => {
    const normalized = sql.trim();
    const lower = normalized.toLowerCase();
    if (!lower.startsWith('select') && !lower.startsWith('with')) {
      return {
        content: [{ type: 'text', text: 'Only SELECT/CTE read-only queries are allowed.' }],
        isError: true,
      };
    }

    const finalSql = limit ? `SELECT * FROM (${normalized}) AS _q LIMIT ${limit}` : normalized;

    const result = await withClient(async (client) => {
      await client.query('BEGIN TRANSACTION READ ONLY');
      try {
        const q = await client.query(finalSql);
        return { rows: q.rows, rowCount: q.rowCount ?? q.rows.length };
      } finally {
        await client.query('ROLLBACK');
      }
    });

    return {
      content: [{ type: 'text', text: JSON.stringify(result, null, 2) }],
    };
  }
);

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(async (err) => {
  console.error(err);
  try { await pool.end(); } catch {}
  process.exit(1);
});

process.on('SIGINT', async () => {
  try { await server.close(); } catch {}
  try { await pool.end(); } catch {}
  process.exit(0);
});
