# Bootstrap install (`make install*`)

Guía corta para el flujo **install** del repo (máquina nueva, sobre todo **WSL2 Ubuntu**). La lógica está en `scripts/install-*.sh` e [`install.mk`](../../install.mk); el Makefile raíz incluye `install.mk`.

## Idempotencia

Todos los targets están diseñados para ejecutarse más de una vez:

- `install-check` y `install-verify` son **no mutantes**.
- `install-apt` delega en `apt-get install` (idempotente por naturaleza para paquetes ya instalados).
- `install-external` es **solo guía** (no instala host-side ni Docker Desktop).
- `install-dotfiles` no ejecuta `chezmoi apply` salvo `DOTFILES_APPLY=1`.
- `install-zsh-stack` clona Oh My Zsh, Powerlevel10k y plugins **solo si faltan**; nunca toca `~/.zshrc` ni `~/.p10k.zsh`.
- `make install` puede repetirse: cada paso decide si actuar.

## Comandos

- `make install-check` — diagnóstico (no muta). Modo normal: solo prerrequisitos duros (no Debian-like, sin `apt-get`, scripts/inventario rotos) hacen fallar; los `MISSING/WARN` instalables quedan como `PASS_WITH_WARNINGS`. Con `STRICT=1` los requeridos declarativos también `FAIL`.
- `make install-apt` — mismo backend que `make deps-install` (inventario en [`system/packages/*.yaml`](../../system/packages/)). Usa `DRY_RUN=1` → `--dry-run`.
- `make install-external` — recomendaciones (`make deps-actions`), Docker / `wt.exe` / `winget.exe` y detección del zsh stack. Sin instalación agresiva. Flags: `SKIP_EXTERNAL=1`, `SKIP_DOCKER=1`.
- `make install-zsh-stack` — Oh My Zsh + Powerlevel10k + plugins custom (idempotente; respeta `DRY_RUN=1`). No edita `~/.zshrc`.
- `make install-uv` — instala **uv** (preferido para Python) con el instalador oficial de Astral. Idempotente: si `uv` existe, no reinstala. `DRY_RUN=1` no descarga ni instala. Pasa `UV_NO_MODIFY_PATH=1` al instalador para no editar `~/.zshrc`/`~/.bashrc`. **Fuera** del orquestador `make install` (opt-in).
- `make install-dotfiles` — plan chezmoi; **no ejecuta apply** salvo `DOTFILES_APPLY=1`. Con `DRY_RUN=1` solo imprime comandos.
- `make install-verify` — versiones; Docker es `WARN`. `STRICT=1` → falla si hay `FAIL`.
- `make install` — encadena los pasos anteriores. `make install DRY_RUN=1` no se rompe por paquetes APT pendientes; `STRICT=1 make install DRY_RUN=1` sí los exige.

## Política de seguridad

- **Docker Desktop:** solo detección y `WARN`; nunca instalación silenciosa.
- **SOPS / Age:** verificación si el inventario lo declara, pero no se generan claves ni se tocan secretos.
- **Windows host (`wt.exe`, `winget.exe`, `powershell.exe`):** solo detección desde WSL; no se asume admin ni se ejecuta `winget install`.
- **chezmoi:** sin `DOTFILES_APPLY=1` no se aplica nada destructivo.
- **Oh My Zsh / Powerlevel10k:** clones bajo `$HOME/.oh-my-zsh` y `$ZSH_CUSTOM/themes/powerlevel10k` solo si faltan; los RC files (`~/.zshrc`, `~/.p10k.zsh`, `~/.aliases`) los gestiona Chezmoi vía `make install-dotfiles DOTFILES_APPLY=1`. RCM/rcup queda fuera del flujo activo.
- **uv:** `make install-uv` descarga el script oficial de Astral a un fichero temporal antes de ejecutarlo (sin `curl|sh` opaco), pasa `UV_NO_MODIFY_PATH=1` para que el instalador no edite rc files, y nunca reinstala si `uv` ya está en `PATH`. No entra en `make install`.

## Documentación relacionada

- Instalación general y secretos: [INSTALL.md](../INSTALL.md)
- Inventario APT / externos: [SYSTEM_DEPENDENCIES.md](../SYSTEM_DEPENDENCIES.md)
- Mantenimiento periódico (no es install): [UPS.md](../UPS.md)
- Chezmoi + SOPS + Age: [CHEZMOI.md](../CHEZMOI.md)

## Skill para agentes

- [Dotfiles bootstrap install](../../ai/assets/skills/ops/dotfiles-install/SKILL.md)
