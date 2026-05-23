# Dotfiles Makefile
# Root entry point — delegates to domain-specific Makefiles

include tests/Makefile.tests
include install.mk
include update.mk

.DEFAULT_GOAL := help

DEPS_CHECK_ARGS ?=
DEPS_INSTALL_ARGS ?=
DEPS_ACTION_ARGS ?=
