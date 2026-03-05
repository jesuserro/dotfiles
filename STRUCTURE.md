# File Tree: dotfiles

**Generated:** 2026-03-05 13:33:56
**Root Path:** `/home/jesus/dotfiles`

```
📁 .
├── 📁 .chezmoiscripts
│   ├── 📄 run_after_00_gen_secrets.sh.tmpl
│   ├── 📄 run_after_10_link_store_etl_mcp.sh.tmpl
│   ├── 📄 run_after_10_setup_ai_runtime.sh.tmpl
│   └── 📄 run_after_11_link_ai_assets.sh.tmpl
├── 📁 .github
│   └── 📁 workflows
│       └── ⚙️ release.yml
├── 📁 ai
│   ├── 📁 adapters
│   │   ├── 📁 claude
│   │   │   └── 📝 README.md
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
│   │       └── 📁 excalidraw-diagram
│   │           ├── 📁 references
│   │           │   ├── 📝 color-palette.md
│   │           │   ├── 📝 element-templates.md
│   │           │   ├── 📝 json-schema.md
│   │           │   ├── ⚙️ pyproject.toml
│   │           │   ├── 🐍 render_excalidraw.py
│   │           │   └── 📄 render_template.html
│   │           ├── 📄 .gitignore
│   │           ├── 📝 README.md
│   │           └── 📝 SKILL.md
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
│   └── 📝 README.md
├── 📁 codex
│   ├── 📝 README-mcp.md
│   ├── 📝 README.md
│   └── ⚙️ config.toml
├── 📁 docs
│   ├── 📝 CAMBIAR_TOKEN_GITHUB.md
│   ├── 📝 CHEZMOI.md
│   ├── 📝 GIT_WORKFLOW.md
│   ├── 📝 MIGRATION_MCP_CHEZMOI.md
│   ├── 📝 MIGRATION_MCP_ITER3.md
│   ├── 📝 README.md
│   ├── 📝 SECRETS_EXAMPLES.md
│   ├── 📝 TOKEN_GITHUB_GH.md
│   └── 📝 VERIFICAR_MCP_STORE_ETL.md
├── 📁 dot_codex
│   └── 📄 config.toml.tmpl
├── 📁 dot_config
│   └── 📁 mcp
│       ├── 📁 servers
│       │   └── 📄 .keep
│       └── 📄 .keep
├── 📁 dot_cursor
│   └── 📄 mcp.json.tmpl
├── 📁 git_hooks
│   └── 📄 pre-commit
├── 📁 local
├── 📁 mcp -> ai/runtime/mcp
├── 📁 powerlevel10k
│   └── 🔧 p10k.zsh
├── 📁 private_dot_config
│   └── 📁 store-etl
│       └── 📄 store-etl.mcp.json.tmpl
├── 📁 private_proyectos
│   └── 📁 store-etl
│       └── 📁 dot_cursor
│           └── 📄 mcp.json.tmpl
├── 📁 releases
│   ├── 📝 branch_feature_1-migration-to-chezmoi-sops-age.md
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
│   ├── 🔧 show_branches_with_dates.sh
│   ├── 🔧 system_info.sh
│   ├── 📄 test.sh.example
│   ├── 🔧 test_python3_make.sh
│   └── 🔧 treegen.sh
├── 📁 termux
│   ├── 🔧 install.sh
│   └── 🔧 install_plugins.sh
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
├── 📝 CHANGELOG.md
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
├── 📄 symlink_dot_config_ai_prompts.tmpl
├── 📄 symlink_dot_config_ai_rules.tmpl
├── 📄 symlink_dot_config_ai_skills.tmpl
├── 📄 symlink_dot_secrets_codex.env
├── 📄 tmux.conf
├── 📄 vimrc
├── 📄 vimrc.bundles
├── 📄 wsl2tolan
└── 📄 zshrc
```
