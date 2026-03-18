# OpenCode Skills Surface

This directory is a **surface**, not a source.

## Role

This directory is symlinked from `~/.config/opencode/skills/` during `chezmoi apply`. It receives skills from the canonical source at `ai/assets/skills/`.

## Do Not Edit Here

**Edit skills in**: `ai/assets/skills/`

This directory is automatically populated. Changes made here will be overwritten on next `chezmoi apply`.

## How It Works

The script `run_after_11_link_ai_assets.sh.tmpl` symlinks each skill from `~/.config/ai/skills/<category>/<skill>/` to `~/.config/opencode/skills/<category>-<skill>/`.

## Canonical Source

See `ai/assets/skills/README.md` for the source of truth.
