# Codex user config

This folder is symlinked into ~/.codex by dotfiles bootstrap.

- config.toml: shared, versioned (no secrets)
- MCP secrets: `~/.config/mcp-secrets.env` (SOPS); wrappers source at runtime. See [docs/TOKEN_GITHUB_GH.md](../docs/TOKEN_GITHUB_GH.md).