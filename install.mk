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

.PHONY: install-check install-apt install-external install-dotfiles install-verify install

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

install: install-check install-apt install-external install-dotfiles install-verify
