---
name: schema-review
description: Standards for reviewing database schemas and DDL changes.
---

# PostgreSQL Schema Review

Standards for reviewing database schemas and DDL changes.

## When to Use

- Reviewing a migration file
- Designing new tables
- Auditing existing schemas
- Creating indexes or constraints
- Planning database refactoring

## Review Checklist

### Table Design

- [ ] Table name is singular (`user` not `users`)
- [ ] Primary key is `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`
- [ ] No `SERIAL` or `BIGSERIAL` types (use sequences explicitly)
- [ ] Timestamps with timezone: `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`
- [ ] Soft deletes preferred over hard deletes: `deleted_at TIMESTAMPTZ`
- [ ] No Hungarian notation (prefixes like `tbl_`, `str_`)

### Naming Conventions

| Object | Convention | Example |
|--------|------------|---------|
| Table | snake_case, singular | `order_item` |
| Column | snake_case | `order_id`, `total_amount` |
| Index | `idx_<table>_<columns>` | `idx_order_created_at` |
| Foreign key | `fk_<table>_<ref>` | `fk_order_user_id` |
| Unique constraint | `uq_<table>_<columns>` | `uq_user_email` |
| Check constraint | `chk_<table>_<name>` | `chk_positive_amount` |

### Data Types

```sql
-- Preferred types
id              UUID DEFAULT gen_random_uuid()
created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
updated_at      TIMESTAMPTZ
deleted_at      TIMESTAMPTZ  -- soft delete
amount          DECIMAL(12,2)
percentage      DECIMAL(5,2)
boolean flag    BOOLEAN NOT NULL DEFAULT false
status          VARCHAR(32)  -- constrained by FK or CHECK

-- Avoid
VARCHAR without length
TEXT without justification
FLOAT/REAL for monetary values
NUMERIC without precision
```

### Indexes

- [ ] Indexes on foreign keys
- [ ] Composite indexes follow query patterns
- [ ] Index order: equality first, range last
- [ ] Partial indexes for filtered queries
- [ ] Unused indexes removed
- [ ] `INCLUDE` columns for covering indexes

### Constraints

```sql
-- Always use constraints for data integrity
amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0)
status VARCHAR(32) NOT NULL CHECK (status IN ('pending', 'confirmed', 'cancelled'))

-- Naming conventions
ALTER TABLE orders ADD CONSTRAINT chk_orders_positive_amount CHECK (amount >= 0);
```

### Migrations

- [ ] Reversible migrations (downgrade path)
- [ ] No locking operations during peak hours
- [ ] Large table changes use concurrent index creation
- [ ] Data migrations separate from schema migrations
- [ ] Backup verified before destructive changes

### Common Issues

| Issue | Problem | Solution |
|-------|---------|----------|
| Missing FK | Data integrity | Add foreign key constraints |
| No index on FK | Slow joins | Add indexes |
| `SELECT *` | Unnecessary data | Specify columns |
| No pagination | Memory issues | Add LIMIT/OFFSET |
| N+1 queries | Performance | Use JOIN or batch |
| Missing `NOT NULL` | Ambiguous logic | Be explicit |

## Performance Review

### Query Patterns

```sql
-- Use EXPLAIN ANALYZE
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders WHERE user_id = $1;
```

### Index Usage

```sql
-- Check index usage
SELECT indexrelname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
WHERE schemaname = 'public';
```

## Related Skills

- `sql-style`: For writing SQL
- `data-contracts`: For defining data contracts
