---
name: dotfiles-bootstrap-install
description: Guía operativa para el bootstrap inicial de dotfiles en Ubuntu/WSL con make install*. Úsala en una máquina nueva (PC corporativo Windows 11 + WSL2 Ubuntu), antes de confiar en ups o en deps-* para mantenimiento.
---

# Dotfiles bootstrap install (`make install*`)

## Purpose

Orquestar un **bootstrap inicial seguro**: diagnóstico, paquetes APT declarativos, orientación sobre herramientas externas, plan de chezmoi y verificación de versiones. La lógica vive en `scripts/install-*.sh`; el Makefile solo delega.

**`make install` ≠ `chezmoi apply`.** El Makefile no materializa HOME por defecto; hace falta **`DOTFILES_APPLY=1`**. Operación diaria tras bootstrap: skill **`dotfiles-operations`**.

## When to Use

- Primera configuración de una estación con este repo en **WSL2 Ubuntu** o Ubuntu nativo.
- Cuando un agente necesita el flujo canónico “instalar sin sorpresas” en entorno corporativo.
- **No** sustituye a `ups` (actualización periódica), **`chezmoi apply`** en máquina ya configurada, ni convierte `deps-*` en instalador silencioso de todo.
- **No** recomendar **`rcup`** / RCM (legacy, no operativo).

## Commands

| Command | Role |
|---------|------|
| `make install-check` | Solo diagnóstico (no muta). Entorno, herramientas base, más salida de `deps-check --include-optional`. |
| `make install-apt` | Instala paquetes APT desde el inventario YAML (mismo backend que `make deps-install`). |
| `make install-external` | Solo recomendaciones (incluye `deps-actions`); detecta Docker/wt/winget y la zsh stack de forma prudente. |
| `make install-zsh-stack` | Clona Oh My Zsh, Powerlevel10k y plugins custom solo si faltan; idempotente; no toca `~/.zshrc`. |
| `make install-uv` | Instala **uv** (preferido para Python) con el instalador oficial de Astral. Idempotente (no reinstala si existe), respeta `DRY_RUN=1`, no toca `~/.zshrc`/`~/.bashrc`. **Opt-in**: fuera de `make install`. |
| `make install-chezmoi` | Opt-in: binario en `~/.local/bin` (sin sudo). |
| `make install-sops` | Opt-in: binario SOPS en `~/.local/bin`. |
| `make install-dotfiles` | Plan chezmoi; **no aplica** por defecto. |
| `make install-verify` | `PASS` / `WARN` / `FAIL`; `chezmoi`/`sops` ausentes = `WARN` (opt-in), no `FAIL`. |
| `make install` | Orden: check → apt → external → dotfiles → verify. `install-zsh-stack`, `install-chezmoi`, `install-sops`, `install-uv` quedan **fuera** del orquestador (opt-in explícito). |

Variables de entorno / Make (pasar como `make target VAR=value`):

| Variable | Efecto |
|----------|--------|
| `DRY_RUN=1` | APT: `--dry-run`; chezmoi: solo imprime comandos; external: refuerza mensaje de no mutación. |
| `STRICT=1` | En `install-check`: convierte `MISSING` declarativos de `deps-check` en `FAIL` (modo normal solo `WARN`). En `install-verify`: exit ≠ 0 si hay `FAIL` reales (sigue sin promocionar `WARN`). |
| `SKIP_EXTERNAL=1` | Omite el bloque `install-external`. |
| `SKIP_DOCKER=1` | En external: omite la sección Docker y filtra bloques docker en la salida de `deps-actions`. |
| `DOTFILES_APPLY=1` | **Requerido** para que `install-dotfiles` ejecute `chezmoi apply` / `init --apply`. Sin esto, solo plan + `WARN` de aplicación pendiente. |

También: `DEPS_INSTALL_ARGS` se reenvía al instalador APT (igual que `deps-install`).

## install vs ups vs deps-*

- **`make install*`**: bootstrap de máquina nueva; idempotente donde aplica; chezmoi **no** destructivo sin `DOTFILES_APPLY=1`.
- **`ups`**: mantenimiento recurrente (APT, npm, MCP, etc.) definido en el alias; **no** modificar desde esta skill.
- **`make deps-check` / `deps-install` / `deps-actions`**: capa declarativa YAML (`system/packages/*.yaml`); `install-apt` y `install-check` la reutilizan.

## Safety

- **Docker Desktop:** no se instala desde estos scripts; solo detección y `WARN`.
- **SOPS/Age:** `make install-sops` + `age` vía APT si aplica; la **clave privada Age** (`~/.config/sops/age/keys.txt`) debe **restaurarse/importarse manualmente** — los agentes no generan claves ni ejecutan `sops -d` a stdout.
- **Windows host:** se detectan `wt.exe`, `winget.exe`, `powershell.exe` desde WSL; **no** se asume admin ni se ejecuta `winget install` por defecto.
- **Zsh stack:** `install-zsh-stack` clona bajo `$HOME/.oh-my-zsh` y `$ZSH_CUSTOM/themes/powerlevel10k` solo si faltan; nunca edita `~/.zshrc`, `~/.p10k.zsh` ni `~/.aliases`. Esos symlinks los crea Chezmoi en `make install-dotfiles DOTFILES_APPLY=1` (RCM/rcup queda fuera del flujo activo).
- **uv:** `install-uv` descarga el script oficial de Astral a un temporal y lo ejecuta con `UV_NO_MODIFY_PATH=1`; no edita `~/.zshrc` ni `~/.bashrc`; no reinstala si `uv` ya está en `PATH`. Pertenece a la política transversal **uv first / pip fallback**: para escenarios Python nuevos prefiere `uv venv`, `uv pip install`, `uv tool install`, `uvx`. **No tocar** `pip`/`pipx`/`python3 -m venv` legados ni el venv runtime AI (`~/.config/ai/runtime/.venv`) salvo tarea explícita.

## Idempotency

- `install-check` y `install-verify` no mutan el sistema.
- `install-apt` delega en `apt-get`, idempotente por paquete.
- `install-external` no instala nada (solo guía).
- `install-dotfiles` no aplica chezmoi sin `DOTFILES_APPLY=1`.
- `install-zsh-stack` clona solo si la ruta destino no existe.
- `make install` puede repetirse sin efectos destructivos.

## Recommended Flow (Windows 11 Pro + WSL2 Ubuntu)

1. `make install-check`
2. `make install-apt` (o primero `DRY_RUN=1`) — o `make install SKIP_EXTERNAL=1`
3. `make install-chezmoi` · `make install-sops` (opt-in)
4. `make install-zsh-stack` (OMZ + p10k runtime; **no** crea symlinks RC)
5. Restaurar `~/.config/sops/age/keys.txt` · `sops secrets.sops.yaml` (valores bajo `mcp:`)
6. `make install-dotfiles DOTFILES_APPLY=1` (symlinks `~/.zshrc`, `~/.aliases`, `~/.p10k.zsh`, MCPs, `mcp-secrets.env`)
7. `make install-verify` · `make ai-cursor-check` · `make ai-mcp-governance` (no mutan)
8. `source ~/.zshrc`

Si RC en HOME tienen contenido custom: `ZSH_RC_APPLY=1 make install-dotfiles DOTFILES_APPLY=1`.

Opt-in aparte: `make install-uv`.

## Interpreting PASS / WARN / FAIL

- **PASS / OK:** herramienta presente o comprobación exitosa.
- **WARN:** pendiente o opcional (Docker, interop Windows, secretos no configurados, aplicación chezmoi pendiente, paquetes APT que `install-apt` puede instalar).
- **MISSING:** comando ausente entre las herramientas deseadas; en modo normal **no** rompe `install-check`.
- **FAIL:** prerrequisito duro (no es Debian-like, falta `apt-get`, scripts internos no encontrados, error real de `check-system-deps.sh`) **o** dependencia declarativa requerida ausente con `STRICT=1`.

`install-check` resume tres bloques: `Local probes`, `Declarative deps` (con estado `PASS` / `WARN` / `FAIL`) y `Hard prerequisites`. El veredicto final es `PASS`, `PASS_WITH_WARNINGS` o `FAIL`. En modo normal solo `FAIL` provoca exit ≠ 0; `STRICT=1` añade los faltantes declarativos al criterio de fallo.

## References

- [dotfiles-operations](../dotfiles-operations/SKILL.md) — operación diaria (apply, secretos, ups vs Chezmoi)
- [docs/OPERATIONS.md](../../../../docs/OPERATIONS.md)
- [docs/ops/dotfiles-install.md](../../../../docs/ops/dotfiles-install.md)
- [docs/INSTALL.md](../../../../docs/INSTALL.md)
- [docs/CHEZMOI.md](../../../../docs/CHEZMOI.md)
- [docs/SYSTEM_DEPENDENCIES.md](../../../../docs/SYSTEM_DEPENDENCIES.md)
