---
name: sql-style
description: Standards for writing clear, maintainable SQL.
---

# SQL Style Guide

Standards for writing clear, maintainable SQL.

## When to Use

- Writing new SQL queries
- Reviewing SQL code
- Creating migrations
- Writing stored procedures
- Building reports

## Formatting

### Capitalization

```sql
-- Keywords: UPPERCASE
-- Identifiers: lowercase or snake_case
SELECT
    u.id,
    u.email,
    o.total_amount
FROM users u
JOIN orders o ON o.user_id = u.id
WHERE u.is_active = true
  AND o.created_at > NOW() - INTERVAL '30 days';
```

### Indentation

- 4 spaces for indentation
- Each major clause on new line
- AND/OR aligned or indented under WHERE
- Commas at start of line for SELECT

### Line Length

- Target: 100 characters max
- Hard limit: 120 characters
- Long expressions: break at operators

## Query Structure

```sql
SELECT
    -- Columns first
    u.id,
    u.email,
    COUNT(o.id) AS order_count,
    COALESCE(SUM(o.total_amount), 0) AS lifetime_value

FROM users u

-- Joins second
LEFT JOIN orders o ON o.user_id = u.id
LEFT JOIN addresses a ON a.user_id = u.id AND a.is_default = true

-- WHERE third
WHERE
    u.is_active = true
    AND u.created_at >= '2024-01-01'

-- GROUP BY fourth
GROUP BY
    u.id,
    u.email

-- HAVING fifth
HAVING COUNT(o.id) > 0

-- ORDER BY last
ORDER BY
    lifetime_value DESC,
    u.email ASC;
```

## Naming Conventions

| Object | Convention | Example |
|--------|------------|---------|
| Table | singular noun | `user`, `order_item` |
| Column | snake_case | `user_id`, `created_at` |
| Alias | Short, meaningful | `u` for user, `o` for order |
| Parameter | `p_` prefix | `p_user_id` |

## Best Practices

### Always Specify Columns

```sql
-- Good
SELECT id, email, name FROM users;

-- Bad (avoids unnecessary data, prevents breakage on schema change)
SELECT * FROM users;
```

### Use Meaningful Aliases

```sql
-- Good
SELECT u.email, o.total_amount FROM users u JOIN orders o ...

-- Avoid single letters except for standard table abbreviations
```

### Prefer ANSI JOIN

```sql
-- Good: explicit join syntax
SELECT ... FROM orders o JOIN users u ON ...

-- Avoid: implicit join syntax
SELECT ... FROM orders o, users u WHERE o.user_id = u.id
```

### Null Handling

```sql
-- COALESCE for defaults
COALESCE(shipped_at, NOW()) AS effective_date

-- IS NULL / IS NOT NULL (not = NULL)
WHERE deleted_at IS NULL

-- NULLIF to avoid division by zero
total_amount / NULLIF(count, 0)
```

### Date/Time

```sql
-- Always use TIMESTAMPTZ for UTC timestamps
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()

-- Avoid NOW() in WHERE for ranges
WHERE created_at >= '2024-01-01'
WHERE created_at >= $1 AND created_at < $2

-- INTERVAL for relative dates
WHERE created_at > NOW() - INTERVAL '7 days'
```

### Pagination

```sql
-- Always paginate large results
SELECT id, name FROM products
ORDER BY id
LIMIT 100 OFFSET 200;

-- For cursor-based pagination
WHERE id > $last_seen_id
ORDER BY id
LIMIT 100;
```

## Anti-Patterns

| Pattern | Problem | Solution |
|---------|---------|----------|
| `SELECT *` | Unnecessary data | Specify columns |
| `LIKE '%value%'` | No index use | Full-text search |
| `OR` chains | Hard to optimize | UNION or IN |
| Nested subqueries | Hard to read | CTEs or temp tables |
| `DISTINCT` to hide dupes | Data issue | Fix the JOIN |
| Functions on columns | Prevents index use | Pre-compute |

## Comments

```sql
-- Single line comments for clarification
-- Calculate lifetime value per user

/* Multi-line for complex logic
   that spans several lines
   and needs detailed explanation */
```

## Related Skills

- `schema-review`: For DDL and schema design
- `data-contracts`: For shared data definitions
