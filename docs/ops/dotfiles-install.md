# Bootstrap install (`make install*`)

Guía corta para el flujo **install** del repo (máquina nueva, sobre todo **WSL2 Ubuntu**). La lógica está en `scripts/install-*.sh` e [`install.mk`](../../install.mk); el Makefile raíz incluye `install.mk`.

## Comandos

- `make install-check` — diagnóstico (no muta). En modo normal solo falla por prerrequisitos duros (no Debian-like, sin `apt-get`, scripts/inventario rotos). Con `STRICT=1` también falla por requeridos declarativos ausentes.
- `make install-apt` — mismo backend que `make deps-install` (inventario en `system/packages/*.yaml`). Usa `DRY_RUN=1` → `--dry-run`.
- `make install-external` — recomendaciones (`deps-actions`), Docker/wt/winget sin instalación agresiva. `SKIP_EXTERNAL=1`, `SKIP_DOCKER=1`.
- `make install-dotfiles` — plan chezmoi; **no ejecuta apply** salvo `DOTFILES_APPLY=1`. Con `DRY_RUN=1` solo imprime comandos.
- `make install-verify` — versiones; Docker es `WARN`. `STRICT=1` → falla si hay `FAIL`.
- `make install` — encadena los pasos anteriores. `make install DRY_RUN=1` no se rompe por paquetes APT pendientes; `STRICT=1 make install DRY_RUN=1` sí los exige.

## Documentación relacionada

- Instalación general y secretos: [INSTALL.md](../INSTALL.md)
- Inventario APT / externos: [SYSTEM_DEPENDENCIES.md](../SYSTEM_DEPENDENCIES.md)
- Mantenimiento periódico (no es install): [UPS.md](../UPS.md)

## Skill para agentes

- [Dotfiles bootstrap install](../../ai/assets/skills/ops/dotfiles-install/SKILL.md)
