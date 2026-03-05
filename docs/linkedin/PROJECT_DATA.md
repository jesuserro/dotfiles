# LinkedIn Project Data — dotfiles

Use this data to showcase the dotfiles project on your LinkedIn profile (March 2026 and beyond).

---

## Project Name

**AI-Powered Dotfiles: Developer Environment as Code**

---

## Description

A production-ready dotfiles repository that turns your development environment into version-controlled, reproducible infrastructure. Built around an **AI Workstation** layer integrating MCP (Model Context Protocol), agent skills, and encrypted secrets—enabling AI assistants (Cursor, Codex, Claude) to multiply developer productivity through structured tool access.

**Highlights:**
- **MCP Integration**: Custom MCP servers (GitHub, Docker, Dagster, MinIO, Prometheus, Loki, Tempo) give AI agents direct access to real tools
- **Agent Skills**: Reusable skills for diagram generation, rules creation, and IDE configuration—shared across Cursor, Codex, and Claude
- **Infrastructure as Code**: Chezmoi + SOPS + Age for declarative, encrypted secret management
- **Hub-Neutral AI Framework**: Single source of truth for runtime, assets, and adapters—works with any AI-powered IDE

**Why it matters for 2026+**: AI-augmented development is the new normal. This project demonstrates hands-on experience with MCP, agent tooling, and infrastructure patterns that scale productivity—skills highly sought after in modern engineering roles.

---

## Skills

- **AI / LLM Tooling**: Model Context Protocol (MCP), AI agents, Cursor, Claude
- **Infrastructure as Code**: Chezmoi, declarative configuration
- **Security**: SOPS, Age encryption, secrets management
- **DevOps**: Shell scripting (Zsh), TMUX, Neovim
- **Version Control**: Git, dotfiles management
- **Python**: MCP server development
- **Developer Productivity**: Automation, reproducible environments

---

## Media Assets

Diagrams are stored in `docs/linkedin/diagrams/`:

| File | Description |
|------|-------------|
| `architecture-overview.excalidraw` / `.jpg` | High-level architecture: dotfiles repo → AI Workstation → HOME |
| `ai-workstation-flow.excalidraw` / `.jpg` | MCP + AI agent flow: Developer → Agent → MCP Servers → Tools |

**For LinkedIn:** Use the `.jpg` files as project media (LinkedIn does not support SVG).

**To regenerate JPGs:**
```bash
cd ~/dotfiles/ai/assets/skills/excalidraw-diagram/references
uv run python render_excalidraw.py ../../../../docs/linkedin/diagrams/architecture-overview.excalidraw -f jpg -o ../../../../docs/linkedin/diagrams/architecture-overview.jpg
uv run python render_excalidraw.py ../../../../docs/linkedin/diagrams/ai-workstation-flow.excalidraw -f jpg -o ../../../../docs/linkedin/diagrams/ai-workstation-flow.jpg
```
