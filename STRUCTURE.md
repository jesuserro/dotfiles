# File Tree: dotfiles

**Generated:** 2026-03-18 19:30:37
**Root Path:** `/home/jesus/dotfiles`

```
📁 .
├── 📁 .chezmoiscripts
│   ├── 📄 run_after_00_gen_secrets.sh.tmpl
│   ├── 📄 run_after_10_link_store_etl_mcp.sh.tmpl
│   ├── 📄 run_after_10_setup_ai_runtime.sh.tmpl
│   └── 📄 run_after_11_link_ai_assets.sh.tmpl
├── 📁 .cursor
│   └── 📁 rules
│       └── 📄 aliases-conventions.mdc
├── 📁 .github
│   └── 📁 workflows
│       └── ⚙️ release.yml
├── 📁 .gitnexus
│   ├── 📁 wiki
│   ├── 📄 lbug
│   └── ⚙️ meta.json
├── 📁 ai
│   ├── 📁 adapters
│   │   ├── 📁 codex
│   │   │   └── 📝 README.md
│   │   └── 📁 cursor
│   │       └── 📝 README.md
│   ├── 📁 assets
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
│   │       │   └── 📁 adr-writer
│   │       │       └── 📝 SKILL.md
│   │       ├── 📁 etl
│   │       │   └── 📁 data-contracts
│   │       │       └── 📝 SKILL.md
│   │       ├── 📁 git
│   │       │   └── 📁 pr-conventions
│   │       │       └── 📝 SKILL.md
│   │       ├── 📁 ops
│   │       │   ├── 📁 mcp-governance
│   │       │   │   └── 📝 SKILL.md
│   │       │   └── 📁 system-workflow
│   │       │       └── 📝 SKILL.md
│   │       ├── 📁 postgres
│   │       │   ├── 📁 schema-review
│   │       │   │   └── 📝 SKILL.md
│   │       │   └── 📁 sql-style
│   │       │       └── 📝 SKILL.md
│   │       ├── 📁 python
│   │       │   └── 📁 project-structure
│   │       │       └── 📝 SKILL.md
│   │       ├── 📁 tools
│   │       │   └── 📁 code-intelligence
│   │       │       ├── 📁 gitnexus-cli
│   │       │       │   └── 📝 SKILL.md
│   │       │       ├── 📁 gitnexus-debugging
│   │       │       │   └── 📝 SKILL.md
│   │       │       ├── 📁 gitnexus-exploring
│   │       │       │   └── 📝 SKILL.md
│   │       │       ├── 📁 gitnexus-guide
│   │       │       │   └── 📝 SKILL.md
│   │       │       ├── 📁 gitnexus-impact-analysis
│   │       │       │   └── 📝 SKILL.md
│   │       │       └── 📁 gitnexus-refactoring
│   │       │           └── 📝 SKILL.md
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
│   ├── 📁 wiki
│   ├── 📝 CAMBIAR_TOKEN_GITHUB.md
│   ├── 📝 CHEZMOI.md
│   ├── 📝 GIT_WORKFLOW.md
│   ├── 📝 GUIA_MCP_AI.md
│   ├── 📝 INSTALL.md
│   ├── 📝 MCP_OBSIDIAN_PROPOSAL.md
│   ├── 📝 MCP_QUICKREF.md
│   ├── 📝 MCP_TAXONOMY.md
│   ├── 📝 MIGRATION_MCP_CHEZMOI.md
│   ├── 📝 MIGRATION_MCP_ITER3.md
│   ├── 📝 OPENCODE.md
│   ├── 📝 README.md
│   ├── 📝 SECRETS_EXAMPLES.md
│   ├── 📝 TESTING.md
│   ├── 📝 TOKEN_GITHUB_GH.md
│   ├── 📝 UPS.md
│   └── 📝 VERIFICAR_MCP_STORE_ETL.md
├── 📁 dot_codex
│   └── 📄 config.toml.tmpl
├── 📁 dot_config
│   ├── 📁 mcp
│   │   ├── 📁 servers
│   │   │   └── 📄 .keep
│   │   └── 📄 .keep
│   └── 📁 opencode
│       ├── 📁 commands
│       │   └── 📄 .keep
│       ├── 📁 plugins
│       │   └── 📄 .keep
│       ├── 📁 skills
│       │   ├── 📄 .keep
│       │   └── 📝 README.md
│       ├── 📄 AGENTS.md.tmpl
│       └── 📄 opencode.json.tmpl
├── 📁 dot_cursor
│   └── 📄 mcp.json.tmpl
├── 📁 git_hooks
│   └── 📄 pre-commit
├── 📁 local
├── 📁 powerlevel10k
│   └── 🔧 p10k.zsh
├── 📁 releases
│   ├── 📝 branch_feature_1-migration-to-chezmoi-sops-age.md
│   ├── 📝 branch_feature_2-refactorai-crear-ai-workstation-framework-en-dotfiles-runtime-mcp-skills-adapters.md
│   ├── 📝 branch_feature_3-enhance-ups-alias-with-ai-upgrades.md
│   ├── 📝 branch_feature_4-adding-opencode.md
│   ├── 📝 branch_feature_5-adding-mcps-globales-especializados.md
│   ├── 📝 branch_feature_6-adding-gitnexus-mcp.md
│   ├── 📝 branch_feature_7-adding-new-global-mcps.md
│   ├── 📝 branch_feature_8-adding-tests.md
│   ├── 📝 branch_feature_test-branch-changelog.md
│   ├── 📝 v2025.12.07_1051.md
│   └── 📝 v2025.12.08_1037.md
├── 📁 scripts
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
│   ├── 🔧 install-gitnexus.sh
│   ├── 🔧 show_branches_with_dates.sh
│   ├── 🔧 system_info.sh
│   ├── 📄 test.sh.example
│   ├── 🔧 test_python3_make.sh
│   ├── 🔧 treegen.sh
│   └── 🔧 validate-skills-structure.sh
├── 📁 termux
│   ├── 🔧 install.sh
│   └── 🔧 install_plugins.sh
├── 📁 tests
│   ├── 📁 bats
│   │   ├── 📁 chezmoi
│   │   │   └── 📄 smoke.bats
│   │   ├── 📁 helpers
│   │   │   └── 🔧 common.bash
│   │   └── 📁 mcp
│   │       ├── 📄 filesystem-launcher.bats
│   │       ├── 📄 git-launcher.bats
│   │       └── 📄 validate-governance.bats
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
├── 📄 rcrc
├── ⚙️ secrets.sops.yaml
├── 📄 secrets.sops.yaml.new
├── 📄 symlink_dot_codex_mcp
├── 📄 symlink_dot_secrets_codex.env
├── 📄 tmux.conf
├── 📄 vimrc
├── 📄 vimrc.bundles
├── 📄 wsl2tolan
└── 📄 zshrc
```
