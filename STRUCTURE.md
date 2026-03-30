# File Tree: dotfiles

**Generated:** 2026-03-30 08:53:23
**Root Path:** `/home/jesus/dotfiles`

```
📁 .
├── 📁 .chezmoiscripts
│   ├── 📄 run_after_00_gen_secrets.sh.tmpl
│   ├── 📄 run_after_10_link_store_etl_mcp.sh.tmpl
│   ├── 📄 run_after_10_setup_ai_runtime.sh.tmpl
│   ├── 📄 run_after_11_link_ai_assets.sh.tmpl
│   └── 📄 run_after_12_materialize_ai_commands.sh.tmpl
├── 📁 .cursor
│   ├── 📁 plans
│   └── 📁 rules
│       └── 📄 aliases-conventions.mdc
├── 📁 .github
│   └── 📁 workflows
│       └── ⚙️ release.yml
├── 📁 .gitnexus
│   ├── 📁 wiki
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
│   │       │   ├── 📁 mcp-governance
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 playwright-ui-validation
│   │       │   │   └── 📝 SKILL.md
│   │       │   ├── 📁 system-updates
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
│   ├── 📁 plans
│   │   ├── 📝 PLAN_000009.md
│   │   └── 📄 PLAN_000009.md:Zone.Identifier
│   ├── 📁 wiki
│   ├── 📝 CAMBIAR_TOKEN_GITHUB.md
│   ├── 📝 CHEZMOI.md
│   ├── 📝 COMMANDS_ARCHITECTURE.md
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
│   ├── 📝 branch_feature_9-adding-commands-and-skills.md
│   ├── 📝 branch_feature_test-branch-changelog.md
│   ├── 📝 v2025.12.07_1051.md
│   └── 📝 v2025.12.08_1037.md
├── 📁 scripts
│   ├── 🔧 generate-commands.sh
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
│   ├── 🔧 materialize-commands.sh
│   ├── 🔧 show_branches_with_dates.sh
│   ├── 🔧 system_info.sh
│   ├── 📄 test.sh.example
│   ├── 🔧 test_python3_make.sh
│   ├── 🔧 treegen.sh
│   ├── 🔧 validate-commands-structure.sh
│   └── 🔧 validate-skills-structure.sh
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
