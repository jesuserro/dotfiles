# Matt Pocock Skills Source Selection

## v1 installs

The full `mattpocock/skills` catalog through explicit opt-in targets.

Install command (via `make install-mattpocock-skills` or `make update-ai-skills`):

```bash
npx skills add mattpocock/skills -y -g
```

## Why full catalog

- Agents get the complete Matt Pocock workflow set as an external fallback layer.
- Local dotfiles skills still win on known overlaps (see [POLICY.md](POLICY.md)).
- Matt is not vendored into `ai/assets/skills/`.
- Installation remains opt-in; `make update` does not touch Matt.

## Known overlaps (local wins)

| Local skill | Matt skill |
|---|---|
| `ops/to-issues` | `to-issues` |
| `ops/to-spec` | `to-prd` |
| `ops/test-driven-change` | `tdd` |
| `ops/architecture-review` | `improve-codebase-architecture` |
| `ops/grill-plan` | `grill-with-docs`, `grill-me` |

Matt-only skills (for example `handoff`, `diagnose`, `prototype`, `triage`) are
available from the external catalog when no local equivalent exists.
