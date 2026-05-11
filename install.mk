# Bootstrap install orchestration (scripts/install-*.sh).
# Included from the root Makefile — keep logic in Bash, not here.

DOTFILES_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# --- Fail-fast guard: refuse hyphenated DRY-RUN/dry-run variants ---------------
# The supported flag is DRY_RUN=1 (with underscore). Hyphenated variants like
# DRY-RUN=1 silently bypass our dry-run plumbing (Make treats them as a different
# variable), which on a fresh machine would trigger a real sudo + apt-get install
# while the user thinks they are in dry-run. Abort at parse time, before any
# recipe runs, so no sudo / apt-get / external script is invoked by accident.
BAD_DRY_RUN_VARS := $(strip \
  $(if $(filter command line,$(origin DRY-RUN)),DRY-RUN=$(DRY-RUN)) \
  $(if $(filter command line,$(origin dry-run)),dry-run=$(dry-run)) \
  $(if $(filter command line,$(origin Dry-Run)),Dry-Run=$(Dry-Run)) \
  $(if $(filter command line,$(origin DRYRUN)),DRYRUN=$(DRYRUN)))
ifneq ($(BAD_DRY_RUN_VARS),)
$(error Unsupported variable name: $(BAD_DRY_RUN_VARS). Use DRY_RUN=1 with underscore. Aborting before any APT/sudo action.)
endif

export DRY_RUN
export STRICT
export SKIP_EXTERNAL
export SKIP_DOCKER
export DOTFILES_APPLY

# Optional passthrough to the declarative APT installer (same as deps-install).
DEPS_INSTALL_ARGS ?=

.PHONY: install-check install-apt install-external install-dotfiles install-verify install install-zsh-stack install-uv install-sops ai-cursor-check ai-mcp-validate ai-mcp-render ai-mcp-drift ai-mcp-governance ai-mcp-generate

install-check:
	@bash $(DOTFILES_DIR)/scripts/install-check.sh

install-apt:
	@bash $(DOTFILES_DIR)/scripts/install-system-packages.sh \
		$(if $(filter 1 true yes on,$(DRY_RUN)),--dry-run,) \
		$(DEPS_INSTALL_ARGS)

install-external:
	@bash $(DOTFILES_DIR)/scripts/install-external.sh

install-dotfiles:
	@bash $(DOTFILES_DIR)/scripts/install-dotfiles.sh

install-verify:
	@bash $(DOTFILES_DIR)/scripts/install-verify.sh

install-zsh-stack:
	@bash $(DOTFILES_DIR)/scripts/install-zsh-stack.sh

# Optional, opt-in installer for the Astral uv Python tool.
# Intentionally NOT part of `make install`: uv is preferred for new Python
# work but stays external/user-level, so users opt in explicitly.
install-uv:
	@bash $(DOTFILES_DIR)/scripts/install-uv.sh

# Optional, opt-in installer for the SOPS secrets editor (getsops/sops).
# Intentionally NOT part of `make install`: sops is external (not in Ubuntu APT
# repos), and corporate workstations prefer explicit opt-in for tooling that
# touches secrets. Supports DRY_RUN=1.
install-sops:
	@bash $(DOTFILES_DIR)/scripts/install-sops.sh

# Non-mutating readiness: Cursor MCPs, skills, AI commands (no chezmoi apply).
ai-cursor-check:
	@bash $(DOTFILES_DIR)/scripts/ai-cursor-check.sh

# Non-mutating: validate canonical MCP manifest (ai/assets/mcps/MANIFEST.yaml).
ai-mcp-validate:
	@python3 $(DOTFILES_DIR)/scripts/validate-mcp-manifest.py

# Non-mutating: dry-run MCP templates under build/mcps/ (does not touch dot_cursor/dot_codex/dot_config).
ai-mcp-render:
	@python3 $(DOTFILES_DIR)/scripts/generate-mcp-configs.py render

# Non-mutating: render + drift report vs Chezmoi templates (exit 1 on UNEXPECTED_DRIFT).
ai-mcp-drift:
	@python3 $(DOTFILES_DIR)/scripts/generate-mcp-configs.py drift

# Non-mutating: same gates as ai-mcp-validate + ai-mcp-render + ai-mcp-drift (orchestrated by bin/validate-mcp-governance).
ai-mcp-governance:
	@bash $(DOTFILES_DIR)/bin/validate-mcp-governance

# Plan only unless APPLY=1: then validate → render → drift → overwrite dot_cursor/dot_codex/dot_config MCP templates.
ai-mcp-generate:
	@python3 $(DOTFILES_DIR)/scripts/generate-mcp-configs.py generate $(if $(filter 1 true yes on,$(APPLY)),--apply,)

install: install-check install-apt install-external install-dotfiles install-verify
