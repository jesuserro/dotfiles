# File Tree: dotfiles

**Generated:** 2026-05-11 14:30:07
**Root Path:** `/home/jesus/dotfiles`

```
📁 .
├── 📁 .chezmoiscripts
│   ├── 📄 run_after_00_gen_secrets.sh.tmpl
│   ├── 📄 run_after_10_link_store_etl_mcp.sh.tmpl
│   ├── 📄 run_after_10_setup_ai_runtime.sh.tmpl
│   ├── 📄 run_after_11_link_ai_assets.sh.tmpl
│   ├── 📄 run_after_12_materialize_ai_commands.sh.tmpl
│   ├── 📄 run_after_13_link_git_ai_wrapper.sh.tmpl
│   ├── 📄 run_after_14_link_prompt_launchers.sh.tmpl
│   └── 📄 run_before_00_backup_rc_files.sh.tmpl
├── 📁 .cursor
│   └── 📁 rules
│       └── 📄 aliases-conventions.mdc
├── 📁 .github
│   └── 📁 workflows
│       └── ⚙️ release.yml
├── 📁 ai
│   ├── 📁 adapters
│   │   ├── 📁 codex
│   │   │   ├── 📝 README.md
│   │   │   └── 📝 TEMPLATE.md
│   │   ├── 📁 cursor
│   │   │   ├── 📝 README.md
│   │   │   └── 📝 TEMPLATE.md
│   │   ├── 📁 opencode
│   │   │   └── 📝 TEMPLATE.md
│   │   └── 📝 README.md
│   ├── 📁 assets
│   │   ├── 📁 commands
│   │   │   ├── 📁 sos
│   │   │   │   └── 📝 COMMAND.md
│   │   │   ├── 📝 README.md
│   │   │   └── ⚙️ registry.yaml
│   │   ├── 📁 mcps
│   │   │   └── ⚙️ MANIFEST.yaml
│   │   ├── 📁 prompts
│   │   │   └── 📄 .keep
│   │   ├── 📁 rules
│   │   │   └── 📄 .keep
│   │   └── 📁 skills
│   │       ├── 📁 diagrams
│   │       │   ├── 📁 conventions
│   │       │   │   └── 📁 excalidraw-architecture
│   │       │   │       └── 📝 SKILL.md
│   │       │   └── 📁 excalidraw
│   │       │       ├── 📁 references
│   │       │       │   ├── 📝 color-palette.md
│   │       │       │   ├── 📝 element-templates.md
│   │       │       │   ├── 📝 json-schema.md
│   │       │       │   ├── ⚙️ pyproject.toml
│   │       │       │   ├── 🐍 render_excalidraw.py
│   │       │       │   └── 📄 render_template.html
│   │       │       ├── 📄 .gitignore
│   │       │       ├── 📝 README.md
│   │       │       └── 📝 SKILL.md
│   │       ├── 📁 docs
│   │       │   ├── 📁 adr-writer
│   │       │   │   └── 📝 SKILL.md
│   │       │   └── 📁 plans-and-notepads-naming
│   │       │       └── 📝 SKILL.md
│   │       ├── 📁 etl
│   │       │   └── 📁 data-contracts
│   │       │       └── 📝 SKILL.md
│   │       ├── 📁 git
│   │       │   ├── 📁 git-rel-troubleshooting
│   │       │   │   └── 📝 SKILL.md
│   │       │   └── 📁 pr-conventions
│   │       │       └── 📝 SKILL.md
│   │       ├── 📁 gitnexus
│   │       │   ├── 📁 gitnexus-cli
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 gitnexus-debugging
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 gitnexus-exploring
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 gitnexus-guide
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 gitnexus-impact-analysis
│   │       │   │   └── 📝 SKILL.md
│   │       │   └── 📁 gitnexus-refactoring
│   │       │       └── 📝 SKILL.md
│   │       ├── 📁 ops
│   │       │   ├── 📁 agent-workflow
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 ai-prompt-consumer
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 architecture-review
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 dotfiles-install
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 dotfiles-skill-registration
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 grill-plan
│   │       │   │   ├── 📁 templates
│   │       │   │   │   └── 📝 grill-report.md
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 mcp-governance
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 playwright-ui-validation
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 system-dependencies
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 system-updates
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 test-driven-change
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 to-issues
│   │       │   │   ├── 📁 templates
│   │       │   │   │   └── 📝 github-issue-vertical.md
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 to-spec
│   │       │   │   ├── 📁 templates
│   │       │   │   │   ├── 📝 contract-outline.md
│   │       │   │   │   ├── 📝 implementation-spec-outline.md
│   │       │   │   │   └── 📝 prd-outline.md
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 vault-detect-errors
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 vault-development-acceleration
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 vault-issue-bridge
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 vault-project-wiki
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 vault-review-diff
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 vault-suggest-improvements
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 vault-update-documentation
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 vault-write-commit-message
│   │       │   │   └── 📝 SKILL.md
│   │       │   └── 📁 wsl2-local-tools
│   │       │       └── 📝 SKILL.md
│   │       ├── 📁 postgres
│   │       │   ├── 📁 schema-review
│   │       │   │   └── 📝 SKILL.md
│   │       │   └── 📁 sql-style
│   │       │       └── 📝 SKILL.md
│   │       ├── 📁 python
│   │       │   └── 📁 project-structure
│   │       │       └── 📝 SKILL.md
│   │       └── 📝 README.md
│   ├── 📁 runtime
│   │   ├── 📁 mcp
│   │   │   ├── 📁 servers
│   │   │   │   ├── 📁 dagster
│   │   │   │   │   └── 🐍 server.py
│   │   │   │   ├── 📁 loki
│   │   │   │   │   └── 🐍 server.py
│   │   │   │   ├── 📁 minio
│   │   │   │   │   └── 🐍 server.py
│   │   │   │   ├── 📁 prometheus
│   │   │   │   │   └── 🐍 server.py
│   │   │   │   ├── 📁 store_etl_ops
│   │   │   │   │   └── 🐍 server.py
│   │   │   │   └── 📁 tempo
│   │   │   │       └── 🐍 server.py
│   │   │   └── 📄 requirements.txt
│   │   └── 📄 .keep
│   ├── 📝 AGENT_WORKFLOW_FOR_AGENTS.md
│   ├── 📝 README.md
│   └── 📝 SKILLS_ARCHITECTURE.md
├── 📁 codex
│   ├── 📝 README-mcp.md
│   ├── 📝 README.md
│   └── ⚙️ config.toml
├── 📁 docs
│   ├── 📁 adr
│   │   ├── 📝 0001-mcp-governance.md
│   │   ├── 📝 0002-gitnexus-mcp.md
│   │   ├── 📝 0003-skills-architecture.md
│   │   └── 📝 template.md
│   ├── 📁 linkedin
│   │   ├── 📁 diagrams
│   │   │   ├── 📄 ai-workstation-flow.excalidraw
│   │   │   ├── 🖼️ ai-workstation-flow.jpg
│   │   │   ├── 🖼️ ai-workstation-flow.svg
│   │   │   ├── 📄 architecture-overview.excalidraw
│   │   │   ├── 🖼️ architecture-overview.jpg
│   │   │   └── 🖼️ architecture-overview.svg
│   │   └── 📝 PROJECT_DATA.md
│   ├── 📁 ops
│   │   └── 📝 dotfiles-install.md
│   ├── 📁 plans
│   │   └── 📝 PLAN_000009.md
│   ├── 📝 AGENT_WORKFLOW_LOOP.md
│   ├── 📝 AI_PROMPTS_SYSTEM.md
│   ├── 📝 CAMBIAR_TOKEN_GITHUB.md
│   ├── 📝 CHEZMOI.md
│   ├── 📝 COMMANDS_ARCHITECTURE.md
│   ├── 📝 GIT_AI_AUTHOR.md
│   ├── 📝 GIT_AI_CURSOR_SETTINGS.md
│   ├── 📝 GIT_REL_INCIDENT.md
│   ├── 📝 GIT_WORKFLOW.md
│   ├── 📝 GUIA_MCP_AI.md
│   ├── 📝 INSTALL.md
│   ├── 📝 MCP_OBSIDIAN_PROPOSAL.md
│   ├── 📝 MCP_QUICKREF.md
│   ├── 📝 MCP_TAXONOMY.md
│   ├── 📝 MIGRATION_MCP_CHEZMOI.md
│   ├── 📝 MIGRATION_MCP_ITER3.md
│   ├── 📝 OPENCODE.md
│   ├── 📝 PROMPT_LAUNCHERS.md
│   ├── 📝 README.md
│   ├── 📝 SECRETS_EXAMPLES.md
│   ├── 📝 SYSTEM_DEPENDENCIES.md
│   ├── 📝 TESTING.md
│   ├── 📝 TOKEN_GITHUB_GH.md
│   ├── 📝 UPS.md
│   ├── 📝 VAULT_PROJECT_WIKI_FLOW.md
│   └── 📝 VERIFICAR_MCP_STORE_ETL.md
├── 📁 dot_codex
│   └── 📄 config.toml.tmpl
├── 📁 dot_config
│   ├── 📁 mcp
│   │   ├── 📁 servers
│   │   │   └── 📄 .keep
│   │   └── 📄 .keep
│   └── 📁 opencode
│       ├── 📁 plugins
│       │   └── 📄 .keep
│       ├── 📁 skills
│       │   ├── 📄 .keep
│       │   └── 📝 README.md
│       ├── 📄 AGENTS.md.tmpl
│       └── 📄 opencode.json.tmpl
├── 📁 dot_cursor
│   └── 📄 mcp.json.tmpl
├── 📁 dot_local
│   └── 📁 share
│       └── 📁 chezmoi
├── 📁 git_hooks
│   └── 📄 pre-commit
├── 📁 local
├── 📁 powerlevel10k
│   └── 🔧 p10k.zsh
├── 📁 releases
│   ├── 📝 branch_feature_1-migration-to-chezmoi-sops-age.md
│   ├── 📝 branch_feature_10-adding-agent-authory.md
│   ├── 📝 branch_feature_11-adding-prompt-launcher.md
│   ├── 📝 branch_feature_12-adding-make-install.md
│   ├── 📝 branch_feature_2-refactorai-crear-ai-workstation-framework-en-dotfiles-runtime-mcp-skills-adapters.md
│   ├── 📝 branch_feature_3-enhance-ups-alias-with-ai-upgrades.md
│   ├── 📝 branch_feature_4-adding-opencode.md
│   ├── 📝 branch_feature_5-adding-mcps-globales-especializados.md
│   ├── 📝 branch_feature_6-adding-gitnexus-mcp.md
│   ├── 📝 branch_feature_7-adding-new-global-mcps.md
│   ├── 📝 branch_feature_8-adding-tests.md
│   ├── 📝 branch_feature_9-adding-commands-and-skills.md
│   ├── 📝 branch_feature_test-branch-changelog.md
│   ├── 📝 v2025.12.07_1051.md
│   └── 📝 v2025.12.08_1037.md
├── 📁 scripts
│   ├── 📁 lib
│   │   ├── 🔧 git-ai-common.sh
│   │   ├── 🔧 git-ai-cursor-path.sh
│   │   ├── 🔧 install_common.sh
│   │   ├── 🔧 prompt-vault-common.sh
│   │   └── 🐍 system_deps.py
│   ├── 🔧 ai-cursor-check.sh
│   ├── 🔧 check-system-deps.sh
│   ├── 🔧 generate-commands.sh
│   ├── 🐍 generate-mcp-configs.py
│   ├── 🔧 git-set-ai-author.sh
│   ├── 🔧 git-set-ai-disable.sh
│   ├── 🔧 git-set-ai-enable.sh
│   ├── 📝 git_branch_changelog.md
│   ├── 🔧 git_branch_changelog.sh
│   ├── 🔧 git_cc.sh
│   ├── 📝 git_changelog.md
│   ├── 🔧 git_changelog.sh
│   ├── 📝 git_clean_branches.md
│   ├── 🔧 git_clean_branches.sh
│   ├── 📝 git_codexpick.md
│   ├── 🔧 git_codexpick.sh
│   ├── 📝 git_diffstat.md
│   ├── 🔧 git_diffstat.sh
│   ├── 📝 git_feat.md
│   ├── 🔧 git_feat.sh
│   ├── 🔧 git_merge_cleanup.sh
│   ├── 📝 git_pr.md
│   ├── 🔧 git_pr.sh
│   ├── 🔧 git_prettylog.sh
│   ├── 📝 git_rel.md
│   ├── 🔧 git_rel.sh
│   ├── 🔧 git_rel_resolve.sh
│   ├── 📝 git_save.md
│   ├── 🔧 git_save.sh
│   ├── 📝 git_start_feature.md
│   ├── 🔧 git_start_feature.sh
│   ├── 🔧 git_workflow.sh
│   ├── 🔧 install-check.sh
│   ├── 🔧 install-chezmoi.sh
│   ├── 🔧 install-dotfiles.sh
│   ├── 🔧 install-external.sh
│   ├── 🔧 install-git-ai-wrapper.sh
│   ├── 🔧 install-gitnexus.sh
│   ├── 🔧 install-mcp-excalidraw.sh
│   ├── 🔧 install-mcp-github.sh
│   ├── 🔧 install-node-stack.sh
│   ├── 🔧 install-sops.sh
│   ├── 🔧 install-system-packages.sh
│   ├── 🔧 install-uv.sh
│   ├── 🔧 install-verify.sh
│   ├── 🔧 install-zsh-stack.sh
│   ├── 🔧 materialize-commands.sh
│   ├── 🔧 set-default-shell-zsh.sh
│   ├── 🔧 show-system-deps-actions.sh
│   ├── 🔧 show_branches_with_dates.sh
│   ├── 🔧 system_info.sh
│   ├── 📄 test.sh.example
│   ├── 🔧 test_python3_make.sh
│   ├── 🔧 treegen.sh
│   ├── 🔧 validate-commands-structure.sh
│   ├── 🐍 validate-mcp-manifest.py
│   └── 🔧 validate-skills-structure.sh
├── 📁 system
│   └── 📁 packages
│       ├── ⚙️ common.yaml
│       ├── ⚙️ tooling.yaml
│       ├── ⚙️ ubuntu.yaml
│       └── ⚙️ wsl.yaml
├── 📁 termux
│   ├── 🔧 install.sh
│   └── 🔧 install_plugins.sh
├── 📁 tests
│   ├── 📁 bats
│   │   ├── 📁 chezmoi
│   │   │   └── 📄 smoke.bats
│   │   ├── 📁 commands
│   │   │   └── 📄 validate-commands.bats
│   │   ├── 📁 helpers
│   │   │   └── 🔧 common.bash
│   │   ├── 📁 mcp
│   │   │   ├── 📄 chezmoi-mcp-launcher-templates.bats
│   │   │   ├── 📄 filesystem-launcher.bats
│   │   │   ├── 📄 git-launcher.bats
│   │   │   └── 📄 validate-governance.bats
│   │   ├── 📁 prompts
│   │   │   └── 📄 prompt-launchers.bats
│   │   ├── 📁 system
│   │   │   ├── 📄 ai-cursor-check.bats
│   │   │   ├── 📄 dry-run-guard.bats
│   │   │   ├── 📄 install-chezmoi.bats
│   │   │   ├── 📄 install-dotfiles.bats
│   │   │   ├── 📄 install-mcp-excalidraw.bats
│   │   │   ├── 📄 install-mcp-github.bats
│   │   │   ├── 📄 install-node-stack.bats
│   │   │   ├── 📄 install-sops.bats
│   │   │   ├── 📄 install-uv.bats
│   │   │   ├── 📄 mcp-manifest.bats
│   │   │   ├── 📄 mcp-render-drift.bats
│   │   │   └── 📄 system-deps.bats
│   │   ├── 📁 zsh
│   │   │   ├── 📄 rc_symlinks.bats
│   │   │   └── 📄 ups_mcp_glob.bats
│   │   └── 📄 git-ai-author.bats
│   └── 📄 Makefile.tests
├── 📁 tmux
│   ├── 📁 common
│   │   ├── 🔧 footer.sh
│   │   └── 🔧 header.sh
│   ├── 🔧 home.sh
│   ├── 🔧 localidades.sh
│   ├── 🔧 nges.sh
│   ├── 🔧 ofertas.sh
│   └── 🔧 work.sh
├── 📁 vim
│   └── 📁 autoload
│       ├── 📄 pathogen.vim
│       └── 📄 plug.vim
├── 📁 zsh
│   ├── 🔧 00-env.zsh
│   ├── 🔧 10-path.zsh
│   ├── 🔧 20-omz.zsh
│   ├── 🔧 30-python.zsh
│   ├── 🔧 50-aliases-dotfiles.zsh
│   └── 🔧 90-local.zsh
├── ⚙️ .chezmoi.toml
├── 📄 .chezmoiignore
├── 📄 .codex
├── 📄 .gitignore
├── ⚙️ .sops.yaml
├── 📝 AGENTS.md
├── 📝 CHANGELOG.md
├── 🔨 Makefile
├── 📝 README.md
├── 📝 STRUCTURE.md
├── 📄 aliases
├── 📄 bashrc
├── 📄 gitconfig
├── 📄 gitignore
├── 📄 gitmessage
├── 🔨 install.mk
├── 📄 rcrc
├── ⚙️ secrets.sops.yaml
├── 📄 secrets.sops.yaml.new
├── 📄 symlink_dot_aliases.tmpl
├── 📄 symlink_dot_codex_mcp
├── 📄 symlink_dot_p10k.zsh.tmpl
├── 📄 symlink_dot_secrets_codex.env
├── 📄 symlink_dot_zshrc.tmpl
├── 📄 tmux.conf
├── 📄 vimrc
├── 📄 vimrc.bundles
├── 📄 wsl2tolan
└── 📄 zshrc
```
