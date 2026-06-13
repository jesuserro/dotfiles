# Codex — documentation only

This folder is **not** the productive Codex configuration source.

Chezmoi materializes the real `~/.codex/config.toml` from
[`dot_codex/private_config.toml.tmpl`](../dot_codex/private_config.toml.tmpl).
See [docs/CHEZMOI.md](../docs/CHEZMOI.md) and [ai/adapters/codex/README.md](../ai/adapters/codex/README.md).

**Do not copy config examples from `codex/`** — edit the Chezmoi template instead.

MCP secrets: `~/.config/mcp-secrets.env` (SOPS); wrappers source at runtime.
See [docs/TOKEN_GITHUB_GH.md](../docs/TOKEN_GITHUB_GH.md).
