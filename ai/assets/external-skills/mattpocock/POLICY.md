# Matt Pocock Skills Policy

Matt Pocock Skills are an external fallback catalog for agents.

## Resolution Order

1. Prefer local dotfiles skills under `ai/assets/skills/`.
2. Use Matt Pocock Skills only when no local skill covers the task.
3. When a local skill and a Matt skill overlap, the local skill wins.
4. Matt skills must not be vendored into `ai/assets/skills/`.
5. Matt skills are installed or updated only through explicit opt-in targets.
6. `make update` must not install or update Matt skills by default.

## Known Local Overrides

| Local skill | Matt skill | Decision |
|---|---|---|
| `ops/to-issues` | `to-issues` | Local wins. |
| `ops/to-spec` | `to-prd` | Local wins for dotfiles work. |
| `ops/test-driven-change` | `tdd` | Local wins for dotfiles work. |
| `ops/architecture-review` | `improve-codebase-architecture` | Local wins for dotfiles work. |
| `ops/grill-plan` | `grill-with-docs` or `grill-me` | Local wins for dotfiles planning. |

All other Matt skills from the full catalog remain available as external fallback
when no local equivalent exists.
