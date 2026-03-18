# Data Contracts

Standards for designing and documenting data contracts in ETL and data engineering contexts.

## When to Use

- Defining input/output schemas for pipelines
- Establishing contracts between data producers and consumers
- Reviewing data pipeline designs
- Onboarding to a data-intensive project
- Creating shared data models

## Contract Components

### 1. Schema Definition

```yaml
contract:
  name: order_created
  version: 1.0.0
  producer: orders-service
  consumers:
    - analytics-pipeline
    - fulfillment-service
  schema:
    fields:
      - name: order_id
        type: string
        format: uuid
        required: true
        description: Unique order identifier
      - name: customer_id
        type: string
        format: uuid
        required: true
      - name: total_amount
        type: decimal
        precision: 12
        scale: 2
        required: true
      - name: created_at
        type: timestamp
        format: iso8601
        required: true
```

### 2. Field Conventions

| Field Property | Standard | Example |
|----------------|----------|---------|
| Timestamps | `_at` suffix, UTC | `created_at`, `updated_at` |
| IDs | `_id` suffix | `user_id`, `order_id` |
| Flags | `is_` prefix | `is_active`, `is_deleted` |
| Amounts | decimal with scale | `total_amount DECIMAL(12,2)` |
| Strings | explicit max length | `VARCHAR(255)` |

### 3. Required vs Optional

- **Required**: Business key, timestamp, critical foreign key
- **Optional**: Descriptive fields, nullable relations
- **Never required**: Derived/calculated fields

## Contract Lifecycle

```
Draft → Review → Accepted → Deprecated → Retired
  │        │        │         │           │
  ▼        ▼        ▼         ▼           ▼
 v0.x    v1.x    v1.x      v2.x        -
```

## Breaking vs Non-Breaking Changes

### Non-Breaking (Backwards Compatible)

- Adding optional fields
- Adding new enum values
- Making required → optional
- Adding documentation

### Breaking (Requires New Version)

- Removing fields
- Renaming fields
- Changing types
- Making optional → required
- Changing constraints

## Documentation Requirements

Every contract must document:

1. **Purpose**: What this data represents
2. **Producer**: Which system generates it
3. **Consumers**: Which systems consume it
4. **SLA**: Expected delivery timing
5. **Schema**: All fields with types and descriptions
6. **Examples**: Sample records

## Quality Checklist

- [ ] Schema is versioned
- [ ] All fields have types and descriptions
- [ ] Business key is identified
- [ ] Nullability is explicit
- [ ] Breaking changes defined
- [ ] Examples provided
- [ ] Owner/maintainer listed

## Anti-Patterns

1. **Untyped fields**: `misc TEXT` without description
2. **Hidden dependencies**: Pipeline depends on undocumented behavior
3. **Version drift**: Producer and consumer on different versions
4. **Silent nulls**: Optional fields not marked as such
5. **No owner**: Nobody responsible for the contract

## Related Skills

- `sql-style`: For writing schema definitions
- `postgres-schema-review`: For database-level validation
