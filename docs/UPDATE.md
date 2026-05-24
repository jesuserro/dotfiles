# Actualización diaria: `make update`

`make update` es la interfaz pública de mantenimiento diario de dotfiles. Sustituye al comando histórico `ups`, que ya no existe.

## Comandos públicos

| Comando | Uso |
|---|---|
| `make update` | Rutina diaria completa: abre Windows PowerShell en otra pestaña y ejecuta WSL, con resumen consolidado |
| `make update-windows` | Ejecuta WinGet y `wsl --update` desde PowerShell/Windows |
| `make update-wsl` | Ejecuta APT, Node/tooling IA, OpenCode, shell, uv, MCPs e imágenes Docker |
| `make update-projects` | Actualiza proyectos personales como `~/proyectos/jesuserro` y RenderCV |
| `make update-check` | Diagnóstico no mutante de requisitos de actualización y MCPs |
| `make excalidraw-start` | Arranca el canvas Docker de Excalidraw bajo demanda |
| `make excalidraw-stop` | Detiene el canvas si está activo |
| `make excalidraw-status` | Muestra estado de Docker/canvas y URL |
| `make excalidraw-update` | Descarga imágenes Docker de Excalidraw sin arrancar el canvas |

## Modelo operativo

| Capa | Comando | Responsabilidad |
|---|---|---|
| Bootstrap | `make install*`, `make deps-*` | Preparar una máquina |
| Materialización | `chezmoi apply` | Publicar plantillas, symlinks y secretos en HOME |
| Mantenimiento | `make update` | Actualizar sistema, runtime y herramientas |
| Proyectos | `make update-projects` | Mantener repos personales fuera del flujo diario |

`make update` no sustituye `chezmoi apply` y no regenera secretos.

## Windows + WSL

Desde Ubuntu/WSL, `make update` crea un directorio de ejecución en una ruta visible por Windows y WSL. La pestaña WSL ejecuta el mantenimiento Linux; una nueva pestaña PowerShell ejecuta WinGet y `wsl --update`.

PowerShell escribe logs y un resultado TSV parseable. Al final, WSL espera ese resultado e imprime un resumen consolidado. Un fallo de WinGet, por ejemplo código `1603`, queda reflejado como incidencia aunque la pestaña se haya abierto correctamente.

`wsl --shutdown` no se ejecuta automáticamente. Si `wsl --update` indica que conviene reiniciar WSL, el resumen lo muestra como acción posterior para ejecutar manualmente desde PowerShell cuando la sesión WSL haya terminado.

## Node y GitNexus

La política del repo exige Node `>=22`. `make install-node-stack` instala NodeSource `24.x`, una fuente externa de paquetes APT firmada y configurada con `signed-by`. Esto evita depender de `nvm`/`fnm` en shells no interactivos y mantiene `node`, `npm` y `npx` disponibles para Make, MCPs y GitNexus.

`make update-wsl` valida la versión de Node antes de actualizar GitNexus. Si el runtime no cumple el engine, el resumen muestra una incidencia visible.

## Excalidraw MCP

Excalidraw ya no usa checkout local ni `dist/index.js`. La modalidad canónica es Docker upstream:

- Canvas: `ghcr.io/yctimlin/mcp_excalidraw-canvas:latest`
- MCP stdio: `ghcr.io/yctimlin/mcp_excalidraw:latest`

El canvas se arranca solo bajo demanda con `make excalidraw-start` y se abre en `http://127.0.0.1:3210`. Docker publica el puerto estable `3210:3000`: `3210` queda reservado en el host para Excalidraw, mientras el contenedor mantiene su puerto interno `3000`. El puerto host `3000` queda libre para Store ETL/Dagster.

Los clientes MCP Docker publican el servidor avanzado con el nombre lógico `excalidraw_canvas` y conectan con el canvas mediante `EXPRESS_SERVER_URL=http://host.docker.internal:3210`. El nombre genérico `excalidraw` queda reservado para cualquier superficie simple que pueda exponer un cliente; no debe usarse para edición agentiva avanzada. `make update` puede descargar imágenes con `make excalidraw-update`, pero nunca deja el canvas arrancado.

Si Docker Desktop está apagado durante `make update`, ese bloque opcional aparece como `SKIP` y no cuenta como incidencia por sí solo. Cuando Docker vuelva a estar disponible, puedes refrescar Excalidraw aparte con `make excalidraw-update`.

El acceso a ficheros del MCP queda deliberadamente acotado: los clientes lanzan el contenedor efímero con `EXCALIDRAW_EXPORT_DIR=/workspace/excalidraw` y un bind mount estrecho de `/mnt/c/Users/jesus/Documents/vault_trabajo/excalidraw` a `/workspace/excalidraw`. Esto mantiene la protección de path traversal y evita montar todo `vault_trabajo`.

Los diagramas maestros viven como `.excalidraw` en los vaults de Obsidian. Las notas nativas de Obsidian usan `.excalidraw.md`, pero para agentes hay que importar el sidecar `.excalidraw`, no el wrapper `.md`. SVG es la salida recomendada para Markdown/PDF técnico; PNG queda para compatibilidad.

Regla de rutas para agentes: no pases rutas WSL `/mnt/c/...` a `import_scene`, `export_scene` ni `export_to_image`. Usa rutas internas del contenedor MCP, por ejemplo:

```text
/workspace/excalidraw/mcp-test/drawing-input.excalidraw
/workspace/excalidraw/mcp-test/drawing-canvas-modified.excalidraw
/workspace/excalidraw/mcp-test/drawing-canvas-modified.svg
```

## Logs y troubleshooting

Cada ejecución crea logs bajo un directorio `dotfiles/update-runs/<timestamp>-<pid>/logs`. El resumen final indica esa ruta.

Comandos útiles:

```bash
make update-check
make excalidraw-status
make ai-mcp-governance
make ai-cursor-check
```

Si las plantillas MCP cambian, ejecuta:

```bash
make ai-mcp-governance
make ai-mcp-generate APPLY=1
chezmoi --source="$HOME/dotfiles" diff ~/.cursor/mcp.json ~/.codex/config.toml ~/.config/opencode/opencode.json
chezmoi --source="$HOME/dotfiles" apply ~/.cursor/mcp.json ~/.codex/config.toml ~/.config/opencode/opencode.json
```

La secuencia anterior publica solo las superficies MCP globales gestionadas por Chezmoi. Para materializar otros cambios de dotfiles no relacionados con MCPs, revisa el diff de Chezmoi antes de aplicar un `chezmoi apply` general.

Un checkout histórico en `~/mcp-servers/excalidraw-mcp` queda obsoleto. No se borra automáticamente; puedes retirarlo manualmente cuando hayas validado la migración Docker.
