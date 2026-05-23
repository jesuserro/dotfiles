# File Tree: dotfiles

**Generated:** 2026-05-23 17:36:28
**Root Path:** `/home/jesus/dotfiles`

```
📁 .
├── 📁 .chezmoiscripts
│   ├── 📄 run_after_00_gen_secrets.sh.tmpl
│   ├── 📄 run_after_10_setup_ai_runtime.sh.tmpl
│   ├── 📄 run_after_11_link_ai_assets.sh.tmpl
│   ├── 📄 run_after_12_materialize_ai_commands.sh.tmpl
│   ├── 📄 run_after_13_link_git_ai_wrapper.sh.tmpl
│   ├── 📄 run_after_14_link_prompt_launchers.sh.tmpl
│   └── 📄 run_before_00_backup_rc_files.sh.tmpl
├── 📁 .cursor
│   ├── 📁 plans
│   └── 📁 rules
│       └── 📄 aliases-conventions.mdc
├── 📁 .github
│   └── 📁 workflows
│       ├── ⚙️ release.yml
│       └── ⚙️ test.yml
├── 📁 .gitnexus
│   ├── 📁 parse-cache
│   │   └── ⚙️ index.json
│   ├── 📁 wiki
│   ├── 📄 .gitignore
│   ├── 📄 lbug
│   └── ⚙️ meta.json
├── 📁 .venv-tools
│   ├── 📁 include
│   │   └── 📁 python3.12
│   ├── 📁 lib
│   │   └── 📁 python3.12
│   │       └── 📁 site-packages
│   │           ├── 📁 pip
│   │           │   ├── 📁 _internal
│   │           │   │   ├── 📁 cli
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 autocompletion.py
│   │           │   │   │   ├── 🐍 base_command.py
│   │           │   │   │   ├── 🐍 cmdoptions.py
│   │           │   │   │   ├── 🐍 command_context.py
│   │           │   │   │   ├── 🐍 main.py
│   │           │   │   │   ├── 🐍 main_parser.py
│   │           │   │   │   ├── 🐍 parser.py
│   │           │   │   │   ├── 🐍 progress_bars.py
│   │           │   │   │   ├── 🐍 req_command.py
│   │           │   │   │   ├── 🐍 spinners.py
│   │           │   │   │   └── 🐍 status_codes.py
│   │           │   │   ├── 📁 commands
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 cache.py
│   │           │   │   │   ├── 🐍 check.py
│   │           │   │   │   ├── 🐍 completion.py
│   │           │   │   │   ├── 🐍 configuration.py
│   │           │   │   │   ├── 🐍 debug.py
│   │           │   │   │   ├── 🐍 download.py
│   │           │   │   │   ├── 🐍 freeze.py
│   │           │   │   │   ├── 🐍 hash.py
│   │           │   │   │   ├── 🐍 help.py
│   │           │   │   │   ├── 🐍 index.py
│   │           │   │   │   ├── 🐍 inspect.py
│   │           │   │   │   ├── 🐍 install.py
│   │           │   │   │   ├── 🐍 list.py
│   │           │   │   │   ├── 🐍 lock.py
│   │           │   │   │   ├── 🐍 search.py
│   │           │   │   │   ├── 🐍 show.py
│   │           │   │   │   ├── 🐍 uninstall.py
│   │           │   │   │   └── 🐍 wheel.py
│   │           │   │   ├── 📁 distributions
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 base.py
│   │           │   │   │   ├── 🐍 installed.py
│   │           │   │   │   ├── 🐍 sdist.py
│   │           │   │   │   └── 🐍 wheel.py
│   │           │   │   ├── 📁 index
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 collector.py
│   │           │   │   │   ├── 🐍 package_finder.py
│   │           │   │   │   └── 🐍 sources.py
│   │           │   │   ├── 📁 locations
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 _distutils.py
│   │           │   │   │   ├── 🐍 _sysconfig.py
│   │           │   │   │   └── 🐍 base.py
│   │           │   │   ├── 📁 metadata
│   │           │   │   │   ├── 📁 importlib
│   │           │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   ├── 🐍 _compat.py
│   │           │   │   │   │   ├── 🐍 _dists.py
│   │           │   │   │   │   └── 🐍 _envs.py
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 _json.py
│   │           │   │   │   ├── 🐍 base.py
│   │           │   │   │   └── 🐍 pkg_resources.py
│   │           │   │   ├── 📁 models
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 candidate.py
│   │           │   │   │   ├── 🐍 direct_url.py
│   │           │   │   │   ├── 🐍 format_control.py
│   │           │   │   │   ├── 🐍 index.py
│   │           │   │   │   ├── 🐍 installation_report.py
│   │           │   │   │   ├── 🐍 link.py
│   │           │   │   │   ├── 🐍 release_control.py
│   │           │   │   │   ├── 🐍 scheme.py
│   │           │   │   │   ├── 🐍 search_scope.py
│   │           │   │   │   ├── 🐍 selection_prefs.py
│   │           │   │   │   ├── 🐍 target_python.py
│   │           │   │   │   └── 🐍 wheel.py
│   │           │   │   ├── 📁 network
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 auth.py
│   │           │   │   │   ├── 🐍 cache.py
│   │           │   │   │   ├── 🐍 download.py
│   │           │   │   │   ├── 🐍 lazy_wheel.py
│   │           │   │   │   ├── 🐍 session.py
│   │           │   │   │   ├── 🐍 utils.py
│   │           │   │   │   └── 🐍 xmlrpc.py
│   │           │   │   ├── 📁 operations
│   │           │   │   │   ├── 📁 install
│   │           │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   └── 🐍 wheel.py
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 check.py
│   │           │   │   │   ├── 🐍 freeze.py
│   │           │   │   │   └── 🐍 prepare.py
│   │           │   │   ├── 📁 req
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 constructors.py
│   │           │   │   │   ├── 🐍 pep723.py
│   │           │   │   │   ├── 🐍 req_dependency_group.py
│   │           │   │   │   ├── 🐍 req_file.py
│   │           │   │   │   ├── 🐍 req_install.py
│   │           │   │   │   ├── 🐍 req_set.py
│   │           │   │   │   └── 🐍 req_uninstall.py
│   │           │   │   ├── 📁 resolution
│   │           │   │   │   ├── 📁 legacy
│   │           │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   └── 🐍 resolver.py
│   │           │   │   │   ├── 📁 resolvelib
│   │           │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   ├── 🐍 base.py
│   │           │   │   │   │   ├── 🐍 candidates.py
│   │           │   │   │   │   ├── 🐍 factory.py
│   │           │   │   │   │   ├── 🐍 found_candidates.py
│   │           │   │   │   │   ├── 🐍 provider.py
│   │           │   │   │   │   ├── 🐍 reporter.py
│   │           │   │   │   │   ├── 🐍 requirements.py
│   │           │   │   │   │   └── 🐍 resolver.py
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   └── 🐍 base.py
│   │           │   │   ├── 📁 utils
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 _jaraco_text.py
│   │           │   │   │   ├── 🐍 _log.py
│   │           │   │   │   ├── 🐍 appdirs.py
│   │           │   │   │   ├── 🐍 compat.py
│   │           │   │   │   ├── 🐍 compatibility_tags.py
│   │           │   │   │   ├── 🐍 datetime.py
│   │           │   │   │   ├── 🐍 deprecation.py
│   │           │   │   │   ├── 🐍 direct_url_helpers.py
│   │           │   │   │   ├── 🐍 egg_link.py
│   │           │   │   │   ├── 🐍 entrypoints.py
│   │           │   │   │   ├── 🐍 filesystem.py
│   │           │   │   │   ├── 🐍 filetypes.py
│   │           │   │   │   ├── 🐍 glibc.py
│   │           │   │   │   ├── 🐍 hashes.py
│   │           │   │   │   ├── 🐍 logging.py
│   │           │   │   │   ├── 🐍 misc.py
│   │           │   │   │   ├── 🐍 packaging.py
│   │           │   │   │   ├── 🐍 pylock.py
│   │           │   │   │   ├── 🐍 retry.py
│   │           │   │   │   ├── 🐍 subprocess.py
│   │           │   │   │   ├── 🐍 temp_dir.py
│   │           │   │   │   ├── 🐍 unpacking.py
│   │           │   │   │   ├── 🐍 urls.py
│   │           │   │   │   ├── 🐍 virtualenv.py
│   │           │   │   │   └── 🐍 wheel.py
│   │           │   │   ├── 📁 vcs
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 bazaar.py
│   │           │   │   │   ├── 🐍 git.py
│   │           │   │   │   ├── 🐍 mercurial.py
│   │           │   │   │   ├── 🐍 subversion.py
│   │           │   │   │   └── 🐍 versioncontrol.py
│   │           │   │   ├── 🐍 __init__.py
│   │           │   │   ├── 🐍 build_env.py
│   │           │   │   ├── 🐍 cache.py
│   │           │   │   ├── 🐍 configuration.py
│   │           │   │   ├── 🐍 exceptions.py
│   │           │   │   ├── 🐍 main.py
│   │           │   │   ├── 🐍 pyproject.py
│   │           │   │   ├── 🐍 self_outdated_check.py
│   │           │   │   └── 🐍 wheel_builder.py
│   │           │   ├── 📁 _vendor
│   │           │   │   ├── 📁 cachecontrol
│   │           │   │   │   ├── 📁 caches
│   │           │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   ├── 🐍 file_cache.py
│   │           │   │   │   │   └── 🐍 redis_cache.py
│   │           │   │   │   ├── 📄 LICENSE.txt
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 _cmd.py
│   │           │   │   │   ├── 🐍 adapter.py
│   │           │   │   │   ├── 🐍 cache.py
│   │           │   │   │   ├── 🐍 controller.py
│   │           │   │   │   ├── 🐍 filewrapper.py
│   │           │   │   │   ├── 🐍 heuristics.py
│   │           │   │   │   ├── 📄 py.typed
│   │           │   │   │   ├── 🐍 serialize.py
│   │           │   │   │   └── 🐍 wrapper.py
│   │           │   │   ├── 📁 certifi
│   │           │   │   │   ├── 📄 LICENSE
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 __main__.py
│   │           │   │   │   ├── 📄 cacert.pem
│   │           │   │   │   ├── 🐍 core.py
│   │           │   │   │   └── 📄 py.typed
│   │           │   │   ├── 📁 dependency_groups
│   │           │   │   │   ├── 📄 LICENSE.txt
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 __main__.py
│   │           │   │   │   ├── 🐍 _implementation.py
│   │           │   │   │   ├── 🐍 _lint_dependency_groups.py
│   │           │   │   │   ├── 🐍 _pip_wrapper.py
│   │           │   │   │   ├── 🐍 _toml_compat.py
│   │           │   │   │   └── 📄 py.typed
│   │           │   │   ├── 📁 distlib
│   │           │   │   │   ├── 📄 LICENSE.txt
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 compat.py
│   │           │   │   │   ├── 🐍 resources.py
│   │           │   │   │   ├── 🐍 scripts.py
│   │           │   │   │   ├── 📄 t32.exe
│   │           │   │   │   ├── 📄 t64-arm.exe
│   │           │   │   │   ├── 📄 t64.exe
│   │           │   │   │   ├── 🐍 util.py
│   │           │   │   │   ├── 📄 w32.exe
│   │           │   │   │   ├── 📄 w64-arm.exe
│   │           │   │   │   └── 📄 w64.exe
│   │           │   │   ├── 📁 distro
│   │           │   │   │   ├── 📄 LICENSE
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 __main__.py
│   │           │   │   │   ├── 🐍 distro.py
│   │           │   │   │   └── 📄 py.typed
│   │           │   │   ├── 📁 idna
│   │           │   │   │   ├── 📝 LICENSE.md
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 codec.py
│   │           │   │   │   ├── 🐍 compat.py
│   │           │   │   │   ├── 🐍 core.py
│   │           │   │   │   ├── 🐍 idnadata.py
│   │           │   │   │   ├── 🐍 intranges.py
│   │           │   │   │   ├── 🐍 package_data.py
│   │           │   │   │   ├── 📄 py.typed
│   │           │   │   │   └── 🐍 uts46data.py
│   │           │   │   ├── 📁 msgpack
│   │           │   │   │   ├── 📄 COPYING
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 exceptions.py
│   │           │   │   │   ├── 🐍 ext.py
│   │           │   │   │   └── 🐍 fallback.py
│   │           │   │   ├── 📁 packaging
│   │           │   │   │   ├── 📁 licenses
│   │           │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   └── 🐍 _spdx.py
│   │           │   │   │   ├── 📄 LICENSE
│   │           │   │   │   ├── 📄 LICENSE.APACHE
│   │           │   │   │   ├── 📄 LICENSE.BSD
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 _elffile.py
│   │           │   │   │   ├── 🐍 _manylinux.py
│   │           │   │   │   ├── 🐍 _musllinux.py
│   │           │   │   │   ├── 🐍 _parser.py
│   │           │   │   │   ├── 🐍 _structures.py
│   │           │   │   │   ├── 🐍 _tokenizer.py
│   │           │   │   │   ├── 🐍 markers.py
│   │           │   │   │   ├── 🐍 metadata.py
│   │           │   │   │   ├── 📄 py.typed
│   │           │   │   │   ├── 🐍 pylock.py
│   │           │   │   │   ├── 🐍 requirements.py
│   │           │   │   │   ├── 🐍 specifiers.py
│   │           │   │   │   ├── 🐍 tags.py
│   │           │   │   │   ├── 🐍 utils.py
│   │           │   │   │   └── 🐍 version.py
│   │           │   │   ├── 📁 pkg_resources
│   │           │   │   │   ├── 📄 LICENSE
│   │           │   │   │   └── 🐍 __init__.py
│   │           │   │   ├── 📁 platformdirs
│   │           │   │   │   ├── 📄 LICENSE
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 __main__.py
│   │           │   │   │   ├── 🐍 android.py
│   │           │   │   │   ├── 🐍 api.py
│   │           │   │   │   ├── 🐍 macos.py
│   │           │   │   │   ├── 📄 py.typed
│   │           │   │   │   ├── 🐍 unix.py
│   │           │   │   │   ├── 🐍 version.py
│   │           │   │   │   └── 🐍 windows.py
│   │           │   │   ├── 📁 pygments
│   │           │   │   │   ├── 📁 filters
│   │           │   │   │   │   └── 🐍 __init__.py
│   │           │   │   │   ├── 📁 formatters
│   │           │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   └── 🐍 _mapping.py
│   │           │   │   │   ├── 📁 lexers
│   │           │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   ├── 🐍 _mapping.py
│   │           │   │   │   │   └── 🐍 python.py
│   │           │   │   │   ├── 📁 styles
│   │           │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   └── 🐍 _mapping.py
│   │           │   │   │   ├── 📄 LICENSE
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 __main__.py
│   │           │   │   │   ├── 🐍 console.py
│   │           │   │   │   ├── 🐍 filter.py
│   │           │   │   │   ├── 🐍 formatter.py
│   │           │   │   │   ├── 🐍 lexer.py
│   │           │   │   │   ├── 🐍 modeline.py
│   │           │   │   │   ├── 🐍 plugin.py
│   │           │   │   │   ├── 🐍 regexopt.py
│   │           │   │   │   ├── 🐍 scanner.py
│   │           │   │   │   ├── 🐍 sphinxext.py
│   │           │   │   │   ├── 🐍 style.py
│   │           │   │   │   ├── 🐍 token.py
│   │           │   │   │   ├── 🐍 unistring.py
│   │           │   │   │   └── 🐍 util.py
│   │           │   │   ├── 📁 pyproject_hooks
│   │           │   │   │   ├── 📁 _in_process
│   │           │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   └── 🐍 _in_process.py
│   │           │   │   │   ├── 📄 LICENSE
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 _impl.py
│   │           │   │   │   └── 📄 py.typed
│   │           │   │   ├── 📁 requests
│   │           │   │   │   ├── 📄 LICENSE
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 __version__.py
│   │           │   │   │   ├── 🐍 _internal_utils.py
│   │           │   │   │   ├── 🐍 adapters.py
│   │           │   │   │   ├── 🐍 api.py
│   │           │   │   │   ├── 🐍 auth.py
│   │           │   │   │   ├── 🐍 certs.py
│   │           │   │   │   ├── 🐍 compat.py
│   │           │   │   │   ├── 🐍 cookies.py
│   │           │   │   │   ├── 🐍 exceptions.py
│   │           │   │   │   ├── 🐍 help.py
│   │           │   │   │   ├── 🐍 hooks.py
│   │           │   │   │   ├── 🐍 models.py
│   │           │   │   │   ├── 🐍 packages.py
│   │           │   │   │   ├── 🐍 sessions.py
│   │           │   │   │   ├── 🐍 status_codes.py
│   │           │   │   │   ├── 🐍 structures.py
│   │           │   │   │   └── 🐍 utils.py
│   │           │   │   ├── 📁 resolvelib
│   │           │   │   │   ├── 📁 resolvers
│   │           │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   ├── 🐍 abstract.py
│   │           │   │   │   │   ├── 🐍 criterion.py
│   │           │   │   │   │   ├── 🐍 exceptions.py
│   │           │   │   │   │   └── 🐍 resolution.py
│   │           │   │   │   ├── 📄 LICENSE
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 providers.py
│   │           │   │   │   ├── 📄 py.typed
│   │           │   │   │   ├── 🐍 reporters.py
│   │           │   │   │   └── 🐍 structs.py
│   │           │   │   ├── 📁 rich
│   │           │   │   │   ├── 📄 LICENSE
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 __main__.py
│   │           │   │   │   ├── 🐍 _cell_widths.py
│   │           │   │   │   ├── 🐍 _emoji_codes.py
│   │           │   │   │   ├── 🐍 _emoji_replace.py
│   │           │   │   │   ├── 🐍 _export_format.py
│   │           │   │   │   ├── 🐍 _extension.py
│   │           │   │   │   ├── 🐍 _fileno.py
│   │           │   │   │   ├── 🐍 _inspect.py
│   │           │   │   │   ├── 🐍 _log_render.py
│   │           │   │   │   ├── 🐍 _loop.py
│   │           │   │   │   ├── 🐍 _null_file.py
│   │           │   │   │   ├── 🐍 _palettes.py
│   │           │   │   │   ├── 🐍 _pick.py
│   │           │   │   │   ├── 🐍 _ratio.py
│   │           │   │   │   ├── 🐍 _spinners.py
│   │           │   │   │   ├── 🐍 _stack.py
│   │           │   │   │   ├── 🐍 _timer.py
│   │           │   │   │   ├── 🐍 _win32_console.py
│   │           │   │   │   ├── 🐍 _windows.py
│   │           │   │   │   ├── 🐍 _windows_renderer.py
│   │           │   │   │   ├── 🐍 _wrap.py
│   │           │   │   │   ├── 🐍 abc.py
│   │           │   │   │   ├── 🐍 align.py
│   │           │   │   │   ├── 🐍 ansi.py
│   │           │   │   │   ├── 🐍 bar.py
│   │           │   │   │   ├── 🐍 box.py
│   │           │   │   │   ├── 🐍 cells.py
│   │           │   │   │   ├── 🐍 color.py
│   │           │   │   │   ├── 🐍 color_triplet.py
│   │           │   │   │   ├── 🐍 columns.py
│   │           │   │   │   ├── 🐍 console.py
│   │           │   │   │   ├── 🐍 constrain.py
│   │           │   │   │   ├── 🐍 containers.py
│   │           │   │   │   ├── 🐍 control.py
│   │           │   │   │   ├── 🐍 default_styles.py
│   │           │   │   │   ├── 🐍 diagnose.py
│   │           │   │   │   ├── 🐍 emoji.py
│   │           │   │   │   ├── 🐍 errors.py
│   │           │   │   │   ├── 🐍 file_proxy.py
│   │           │   │   │   ├── 🐍 filesize.py
│   │           │   │   │   ├── 🐍 highlighter.py
│   │           │   │   │   ├── 🐍 json.py
│   │           │   │   │   ├── 🐍 jupyter.py
│   │           │   │   │   ├── 🐍 layout.py
│   │           │   │   │   ├── 🐍 live.py
│   │           │   │   │   ├── 🐍 live_render.py
│   │           │   │   │   ├── 🐍 logging.py
│   │           │   │   │   ├── 🐍 markup.py
│   │           │   │   │   ├── 🐍 measure.py
│   │           │   │   │   ├── 🐍 padding.py
│   │           │   │   │   ├── 🐍 pager.py
│   │           │   │   │   ├── 🐍 palette.py
│   │           │   │   │   ├── 🐍 panel.py
│   │           │   │   │   ├── 🐍 pretty.py
│   │           │   │   │   ├── 🐍 progress.py
│   │           │   │   │   ├── 🐍 progress_bar.py
│   │           │   │   │   ├── 🐍 prompt.py
│   │           │   │   │   ├── 🐍 protocol.py
│   │           │   │   │   ├── 📄 py.typed
│   │           │   │   │   ├── 🐍 region.py
│   │           │   │   │   ├── 🐍 repr.py
│   │           │   │   │   ├── 🐍 rule.py
│   │           │   │   │   ├── 🐍 scope.py
│   │           │   │   │   ├── 🐍 screen.py
│   │           │   │   │   ├── 🐍 segment.py
│   │           │   │   │   ├── 🐍 spinner.py
│   │           │   │   │   ├── 🐍 status.py
│   │           │   │   │   ├── 🐍 style.py
│   │           │   │   │   ├── 🐍 styled.py
│   │           │   │   │   ├── 🐍 syntax.py
│   │           │   │   │   ├── 🐍 table.py
│   │           │   │   │   ├── 🐍 terminal_theme.py
│   │           │   │   │   ├── 🐍 text.py
│   │           │   │   │   ├── 🐍 theme.py
│   │           │   │   │   ├── 🐍 themes.py
│   │           │   │   │   ├── 🐍 traceback.py
│   │           │   │   │   └── 🐍 tree.py
│   │           │   │   ├── 📁 tomli
│   │           │   │   │   ├── 📄 LICENSE
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 _parser.py
│   │           │   │   │   ├── 🐍 _re.py
│   │           │   │   │   ├── 🐍 _types.py
│   │           │   │   │   └── 📄 py.typed
│   │           │   │   ├── 📁 tomli_w
│   │           │   │   │   ├── 📄 LICENSE
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 _writer.py
│   │           │   │   │   └── 📄 py.typed
│   │           │   │   ├── 📁 truststore
│   │           │   │   │   ├── 📄 LICENSE
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 _api.py
│   │           │   │   │   ├── 🐍 _macos.py
│   │           │   │   │   ├── 🐍 _openssl.py
│   │           │   │   │   ├── 🐍 _ssl_constants.py
│   │           │   │   │   ├── 🐍 _windows.py
│   │           │   │   │   └── 📄 py.typed
│   │           │   │   ├── 📁 urllib3
│   │           │   │   │   ├── 📁 contrib
│   │           │   │   │   │   ├── 📁 _securetransport
│   │           │   │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   │   ├── 🐍 bindings.py
│   │           │   │   │   │   │   └── 🐍 low_level.py
│   │           │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   ├── 🐍 _appengine_environ.py
│   │           │   │   │   │   ├── 🐍 appengine.py
│   │           │   │   │   │   ├── 🐍 ntlmpool.py
│   │           │   │   │   │   ├── 🐍 pyopenssl.py
│   │           │   │   │   │   ├── 🐍 securetransport.py
│   │           │   │   │   │   └── 🐍 socks.py
│   │           │   │   │   ├── 📁 packages
│   │           │   │   │   │   ├── 📁 backports
│   │           │   │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   │   ├── 🐍 makefile.py
│   │           │   │   │   │   │   └── 🐍 weakref_finalize.py
│   │           │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   └── 🐍 six.py
│   │           │   │   │   ├── 📁 util
│   │           │   │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   │   ├── 🐍 connection.py
│   │           │   │   │   │   ├── 🐍 proxy.py
│   │           │   │   │   │   ├── 🐍 queue.py
│   │           │   │   │   │   ├── 🐍 request.py
│   │           │   │   │   │   ├── 🐍 response.py
│   │           │   │   │   │   ├── 🐍 retry.py
│   │           │   │   │   │   ├── 🐍 ssl_.py
│   │           │   │   │   │   ├── 🐍 ssl_match_hostname.py
│   │           │   │   │   │   ├── 🐍 ssltransport.py
│   │           │   │   │   │   ├── 🐍 timeout.py
│   │           │   │   │   │   ├── 🐍 url.py
│   │           │   │   │   │   └── 🐍 wait.py
│   │           │   │   │   ├── 📄 LICENSE.txt
│   │           │   │   │   ├── 🐍 __init__.py
│   │           │   │   │   ├── 🐍 _collections.py
│   │           │   │   │   ├── 🐍 _version.py
│   │           │   │   │   ├── 🐍 connection.py
│   │           │   │   │   ├── 🐍 connectionpool.py
│   │           │   │   │   ├── 🐍 exceptions.py
│   │           │   │   │   ├── 🐍 fields.py
│   │           │   │   │   ├── 🐍 filepost.py
│   │           │   │   │   ├── 🐍 poolmanager.py
│   │           │   │   │   ├── 🐍 request.py
│   │           │   │   │   └── 🐍 response.py
│   │           │   │   ├── 📄 README.rst
│   │           │   │   ├── 🐍 __init__.py
│   │           │   │   └── 📄 vendor.txt
│   │           │   ├── 🐍 __init__.py
│   │           │   ├── 🐍 __main__.py
│   │           │   ├── 🐍 __pip-runner__.py
│   │           │   └── 📄 py.typed
│   │           ├── 📁 pip-26.0.1.dist-info
│   │           │   ├── 📁 licenses
│   │           │   │   ├── 📁 src
│   │           │   │   │   └── 📁 pip
│   │           │   │   │       └── 📁 _vendor
│   │           │   │   │           ├── 📁 cachecontrol
│   │           │   │   │           │   └── 📄 LICENSE.txt
│   │           │   │   │           ├── 📁 certifi
│   │           │   │   │           │   └── 📄 LICENSE
│   │           │   │   │           ├── 📁 dependency_groups
│   │           │   │   │           │   └── 📄 LICENSE.txt
│   │           │   │   │           ├── 📁 distlib
│   │           │   │   │           │   └── 📄 LICENSE.txt
│   │           │   │   │           ├── 📁 distro
│   │           │   │   │           │   └── 📄 LICENSE
│   │           │   │   │           ├── 📁 idna
│   │           │   │   │           │   └── 📝 LICENSE.md
│   │           │   │   │           ├── 📁 msgpack
│   │           │   │   │           │   └── 📄 COPYING
│   │           │   │   │           ├── 📁 packaging
│   │           │   │   │           │   ├── 📄 LICENSE
│   │           │   │   │           │   ├── 📄 LICENSE.APACHE
│   │           │   │   │           │   └── 📄 LICENSE.BSD
│   │           │   │   │           ├── 📁 pkg_resources
│   │           │   │   │           │   └── 📄 LICENSE
│   │           │   │   │           ├── 📁 platformdirs
│   │           │   │   │           │   └── 📄 LICENSE
│   │           │   │   │           ├── 📁 pygments
│   │           │   │   │           │   └── 📄 LICENSE
│   │           │   │   │           ├── 📁 pyproject_hooks
│   │           │   │   │           │   └── 📄 LICENSE
│   │           │   │   │           ├── 📁 requests
│   │           │   │   │           │   └── 📄 LICENSE
│   │           │   │   │           ├── 📁 resolvelib
│   │           │   │   │           │   └── 📄 LICENSE
│   │           │   │   │           ├── 📁 rich
│   │           │   │   │           │   └── 📄 LICENSE
│   │           │   │   │           ├── 📁 tomli
│   │           │   │   │           │   └── 📄 LICENSE
│   │           │   │   │           ├── 📁 tomli_w
│   │           │   │   │           │   └── 📄 LICENSE
│   │           │   │   │           ├── 📁 truststore
│   │           │   │   │           │   └── 📄 LICENSE
│   │           │   │   │           └── 📁 urllib3
│   │           │   │   │               └── 📄 LICENSE.txt
│   │           │   │   ├── 📄 AUTHORS.txt
│   │           │   │   └── 📄 LICENSE.txt
│   │           │   ├── 📄 INSTALLER
│   │           │   ├── 📄 METADATA
│   │           │   ├── 📄 RECORD
│   │           │   ├── 📄 REQUESTED
│   │           │   ├── 📄 WHEEL
│   │           │   └── 📄 entry_points.txt
│   │           ├── 📁 ruff
│   │           │   ├── 🐍 __init__.py
│   │           │   ├── 🐍 __main__.py
│   │           │   └── 🐍 _find_ruff.py
│   │           └── 📁 ruff-0.15.7.dist-info
│   │               ├── 📁 licenses
│   │               │   └── 📄 LICENSE
│   │               ├── 📄 INSTALLER
│   │               ├── 📄 METADATA
│   │               ├── 📄 RECORD
│   │               ├── 📄 REQUESTED
│   │               └── 📄 WHEEL
│   ├── 📁 lib64 -> lib
│   └── 📄 pyvenv.cfg
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
│   │   │   ├── 📄 .keep
│   │   │   └── 📝 README.md
│   │   ├── 📁 rules
│   │   │   ├── 📄 .keep
│   │   │   └── 📝 README.md
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
│   │       │   ├── 📁 excalidraw-publishing
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
│   │       │   ├── 📁 dotfiles-operations
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 dotfiles-skill-registration
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 excalidraw-mcp-operations
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
│   │   ├── 📝 azure-tooling.md
│   │   └── 📝 dotfiles-install.md
│   ├── 📁 plans
│   │   ├── 📝 PLAN_000009.md
│   │   └── 📄 PLAN_000009.md:Zone.Identifier
│   ├── 📁 wiki
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
│   ├── 📝 OPERATIONS.md
│   ├── 📝 PROMPT_LAUNCHERS.md
│   ├── 📝 README.md
│   ├── 📝 SECRETS_EXAMPLES.md
│   ├── 📝 SYSTEM_DEPENDENCIES.md
│   ├── 📝 TESTING.md
│   ├── 📝 TOKEN_GITHUB_GH.md
│   ├── 📝 UPDATE.md
│   ├── 📝 VAULT_PROJECT_WIKI_FLOW.md
│   └── 📝 VERIFICAR_MCP_STORE_ETL.md
├── 📁 dot_codex
│   └── 📄 config.toml.tmpl
├── 📁 dot_config
│   ├── 📁 codex
│   │   └── 📁 prompts
│   ├── 📁 cursor
│   │   └── 📁 commands
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
│   ├── 📝 branch_feature_1-adding-tooling-azuredevops.md
│   ├── 📝 branch_feature_1-migration-to-chezmoi-sops-age.md
│   ├── 📝 branch_feature_10-adding-agent-authory.md
│   ├── 📝 branch_feature_11-adding-prompt-launcher.md
│   ├── 📝 branch_feature_12-adding-make-install.md
│   ├── 📝 branch_feature_15-adding-refactors-and-enhancements.md
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
│   ├── 📝 v2025.12.08_1037.md
│   ├── 📝 v2025.12.12_2122.md
│   ├── 📝 v2025.12.12_2135.md
│   ├── 📝 v2025.12.12_2141.md
│   ├── 📝 v2025.12.12_2145.md
│   ├── 📝 v2025.12.12_2148.md
│   ├── 📝 v2025.12.17_1000.md
│   ├── 📝 v2025.12.17_1032.md
│   ├── 📝 v2026.03.02_1759.md
│   ├── 📝 v2026.03.02_2158.md
│   ├── 📝 v2026.03.03_1229.md
│   ├── 📝 v2026.03.03_1309.md
│   ├── 📝 v2026.03.05_1658.md
│   ├── 📝 v2026.03.05_1933.md
│   ├── 📝 v2026.03.06_1117.md
│   ├── 📝 v2026.03.07_1206.md
│   ├── 📝 v2026.03.08_0900.md
│   ├── 📝 v2026.03.10_0916.md
│   ├── 📝 v2026.03.14_1052.md
│   ├── 📝 v2026.03.15_0927.md
│   ├── 📝 v2026.03.17_1559.md
│   ├── 📝 v2026.03.17_2026.md
│   ├── 📝 v2026.03.18_1118.md
│   ├── 📝 v2026.03.18_1247.md
│   ├── 📝 v2026.03.18_1355.md
│   ├── 📝 v2026.03.18_2123.md
│   ├── 📝 v2026.03.23_1044.md
│   ├── 📝 v2026.03.23_1210.md
│   ├── 📝 v2026.03.24_0929.md
│   ├── 📝 v2026.03.26_1234.md
│   ├── 📝 v2026.03.26_1317.md
│   ├── 📝 v2026.03.26_1331.md
│   ├── 📝 v2026.03.27_1057.md
│   ├── 📝 v2026.03.30_1203.md
│   ├── 📝 v2026.04.09_1304.md
│   ├── 📝 v2026.04.09_1401.md
│   ├── 📝 v2026.04.10_1841.md
│   ├── 📝 v2026.04.10_1918.md
│   ├── 📝 v2026.04.10_2003.md
│   ├── 📝 v2026.04.20_1036.md
│   ├── 📝 v2026.04.20_1125.md
│   ├── 📝 v2026.05.03_0834.md
│   ├── 📝 v2026.05.09_2139.md
│   └── 📝 v2026.05.09_2340.md
├── 📁 scripts
│   ├── 📁 lib
│   │   ├── 🔧 git-ai-common.sh
│   │   ├── 🔧 git-ai-cursor-path.sh
│   │   ├── 🔧 install_common.sh
│   │   ├── 🔧 prompt-vault-common.sh
│   │   └── 🐍 system_deps.py
│   ├── 📁 update
│   │   ├── 📁 lib
│   │   │   ├── 🔧 environment.sh
│   │   │   ├── 🔧 logging.sh
│   │   │   └── 🔧 results.sh
│   │   ├── 🔧 update-check.sh
│   │   ├── 🔧 update-excalidraw.sh
│   │   ├── 🔧 update-projects.sh
│   │   ├── 🪟 update-windows.ps1
│   │   ├── 🔧 update-windows.sh
│   │   ├── 🔧 update-wsl.sh
│   │   └── 🔧 update.sh
│   ├── 🔧 agent-validate-changed.sh
│   ├── 🔧 ai-cursor-check.sh
│   ├── 🔧 check-azure-tools.sh
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
│   ├── 🔧 install-agent-tools.sh
│   ├── 🔧 install-azure-cli.sh
│   ├── 🔧 install-check.sh
│   ├── 🔧 install-chezmoi.sh
│   ├── 🔧 install-dotfiles.sh
│   ├── 🔧 install-external.sh
│   ├── 🔧 install-fonts.sh
│   ├── 🔧 install-git-ai-wrapper.sh
│   ├── 🔧 install-gitnexus.sh
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
│   │   │   ├── 📄 ai-assets-warnings.bats
│   │   │   ├── 📄 ai-runtime-uv.bats
│   │   │   ├── 📄 gen-secrets-strict.bats
│   │   │   ├── 📄 smoke.bats
│   │   │   └── 📄 store-etl-hook-removed.bats
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
│   │   ├── 📁 skills
│   │   │   └── 📄 canonical-skills.bats
│   │   ├── 📁 system
│   │   │   ├── 📄 ai-cursor-check.bats
│   │   │   ├── 📄 azure-tools.bats
│   │   │   ├── 📄 dry-run-guard.bats
│   │   │   ├── 📄 excalidraw-docker.bats
│   │   │   ├── 📄 install-azure-cli.bats
│   │   │   ├── 📄 install-chezmoi.bats
│   │   │   ├── 📄 install-dotfiles.bats
│   │   │   ├── 📄 install-fonts.bats
│   │   │   ├── 📄 install-mcp-github.bats
│   │   │   ├── 📄 install-node-stack.bats
│   │   │   ├── 📄 install-sops.bats
│   │   │   ├── 📄 install-uv.bats
│   │   │   ├── 📄 mcp-manifest.bats
│   │   │   ├── 📄 mcp-render-drift.bats
│   │   │   ├── 📄 system-deps.bats
│   │   │   └── 📄 update-workflow.bats
│   │   ├── 📁 zsh
│   │   │   ├── 📄 p10k_cache_keys.bats
│   │   │   └── 📄 rc_symlinks.bats
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
│   ├── 🔧 55-aliases-azure.zsh
│   └── 🔧 90-local.zsh
├── ⚙️ .chezmoi.toml
├── 📄 .chezmoiignore
├── 📄 .codex
├── 📄 .gitignore
├── ⚙️ .gitleaks.toml
├── ⚙️ .sops.yaml
├── 📄 .yamllint
├── 📝 AGENTS.md
├── 📝 CHANGELOG.md
├── 📝 CLAUDE.md
├── 🔨 Makefile
├── 📝 README.md
├── 📝 STRUCTURE.md
├── 📄 aliases
├── 📄 bashrc
├── 📄 gitconfig
├── 📄 gitignore
├── 📄 gitmessage
├── 🔨 install.mk
├── 📄 modelcontextprotocol-server-postgres-0.6.2.tgz
├── ⚙️ secrets.sops.yaml
├── 📄 symlink_dot_aliases.tmpl
├── 📄 symlink_dot_codex_mcp
├── 📄 symlink_dot_p10k.zsh.tmpl
├── 📄 symlink_dot_secrets_codex.env
├── 📄 symlink_dot_zshrc.tmpl
├── 📄 tmux.conf
├── 🔨 update.mk
├── 📄 vimrc
├── 📄 vimrc.bundles
├── 📄 wsl2tolan
└── 📄 zshrc
```
