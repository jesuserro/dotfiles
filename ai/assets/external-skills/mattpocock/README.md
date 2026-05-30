# Matt Pocock Skills

This directory documents the opt-in external Matt Pocock Skills layer for this
dotfiles repository.

It does not vendor skills. The local canonical skills remain under
`ai/assets/skills/`; Matt Pocock Skills are an external fallback catalog for
agents, installed globally under `~/.agents/skills/` when explicitly requested.

## Commands

Install the full external catalog:

```bash
make install-mattpocock-skills
```

Refresh the same catalog later:

```bash
make update-ai-skills
```

Both targets call:

```bash
npx skills add mattpocock/skills -y -g
```

Do not pass `--skill handoff` or `skill=handoff` in full-catalog mode. Those
selectors install or filter a single skill; v1 intentionally installs the
complete `mattpocock/skills` source.

`make update` does not install or update Matt Pocock Skills.

The installer removes accidental Matt Pocock symlinks from `ai/assets/skills/`
after running the external CLI, because `ai/assets/skills/` is reserved for
canonical local dotfiles skills.

## Precedence

- `ai/assets/skills/` — local canonical catalog (highest priority)
- `~/.agents/skills/` — Matt Pocock full catalog (external fallback for agents)

When a local dotfiles skill overlaps with a Matt skill, the local skill wins.

## References

- Policy: [POLICY.md](POLICY.md)
- Source selection: [selected-skills.md](selected-skills.md)
- Source repository: <https://github.com/mattpocock/skills>
