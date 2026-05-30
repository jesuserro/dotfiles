# Daily update orchestration. Make exposes stable entry points; scripts own logic.

DOTFILES_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

.PHONY: update update-windows update-wsl update-projects update-check update-ai-skills
.PHONY: update-apt update-tools update-shell update-mcp update-services
.PHONY: excalidraw-start excalidraw-stop excalidraw-status excalidraw-update

update:
	@bash $(DOTFILES_DIR)/scripts/update/update.sh

update-windows:
	@bash $(DOTFILES_DIR)/scripts/update/update-windows.sh

update-wsl:
	@bash $(DOTFILES_DIR)/scripts/update/update-wsl.sh

update-projects:
	@bash $(DOTFILES_DIR)/scripts/update/update-projects.sh

update-check:
	@bash $(DOTFILES_DIR)/scripts/update/update-check.sh

update-ai-skills:
	@bash $(DOTFILES_DIR)/scripts/install-agent-skills.sh $(if $(filter 1 true yes on,$(DRY_RUN)),--dry-run,)

update-apt update-tools update-shell update-mcp update-services:
	@bash $(DOTFILES_DIR)/scripts/update/update-wsl.sh --section "$(@:update-%=%)"

excalidraw-start:
	@bash $(DOTFILES_DIR)/scripts/update/update-excalidraw.sh start

excalidraw-stop:
	@bash $(DOTFILES_DIR)/scripts/update/update-excalidraw.sh stop

excalidraw-status:
	@bash $(DOTFILES_DIR)/scripts/update/update-excalidraw.sh status

excalidraw-update:
	@bash $(DOTFILES_DIR)/scripts/update/update-excalidraw.sh update
