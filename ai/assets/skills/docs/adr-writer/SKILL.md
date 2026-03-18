# ADR Writer

Guide for writing clear, actionable Architecture Decision Records.

## When to Use

- Proposing a significant technical decision
- Documenting a chosen solution over alternatives
- Reviewing existing ADRs for quality
- Onboarding to a codebase with ADR culture

## ADR Structure

```
# ADR: Title
**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded
**Author:** name

---

## Context
What problem or situation motivates this decision?

## Decision
What is the change being proposed?

### Options Considered
1. Option A - brief description
2. Option B - brief description
3. Option N - brief description

## Consequences
### Positive
### Negative
### Neutral

## References
Links to RFCs, issues, documentation
```

## Quality Checklist

- [ ] **Context** explains the "why", not just the "what"
- [ ] **Decision** is specific and actionable
- [ ] **Alternatives** are genuinely considered (not strawmen)
- [ ] **Consequences** cover positive, negative, AND neutral
- [ ] **Status** reflects actual state
- [ ] **References** link to relevant discussions or docs

## Status Meanings

| Status | When to Use |
|--------|-------------|
| `Proposed` | Under discussion, not yet decided |
| `Accepted` | Agreed and being implemented |
| `Deprecated` | Superseded by another approach |
| `Superseded` | Replaced by ADR-NNN |

## Common Mistakes

1. **Vague context**: "We need to improve performance" → "Current API p95 latency is 2.3s, target is <500ms"
2. **No alternatives**: Always consider at least 2 alternatives
3. **Missing neutral consequences**: What stays the same? What needs to be updated?
4. **Future tense**: ADR is about decisions already made, not plans

## Example

See `docs/adr/0001-mcp-governance.md` for a well-structured example.

## Tools

- Template: `docs/adr/template.md`
- Naming: `XXXX-title-slug.md` (4-digit sequence)
