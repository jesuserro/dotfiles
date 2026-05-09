# Bootstrap install orchestration (scripts/install-*.sh).
# Included from the root Makefile — keep logic in Bash, not here.

DOTFILES_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

export DRY_RUN
export STRICT
export SKIP_EXTERNAL
export SKIP_DOCKER
export DOTFILES_APPLY

# Optional passthrough to the declarative APT installer (same as deps-install).
DEPS_INSTALL_ARGS ?=

.PHONY: install-check install-apt install-external install-dotfiles install-verify install install-zsh-stack install-uv ai-cursor-check ai-mcp-validate

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

# Non-mutating readiness: Cursor MCPs, skills, AI commands (no chezmoi apply).
ai-cursor-check:
	@bash $(DOTFILES_DIR)/scripts/ai-cursor-check.sh

# Non-mutating: validate canonical MCP manifest (ai/assets/mcps/MANIFEST.yaml).
ai-mcp-validate:
	@python3 $(DOTFILES_DIR)/scripts/validate-mcp-manifest.py

install: install-check install-apt install-external install-dotfiles install-verify
