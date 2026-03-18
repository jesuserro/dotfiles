# Dotfiles Makefile
# Root entry point — delegates to domain-specific Makefiles

include tests/Makefile.tests

.DEFAULT_GOAL := help
