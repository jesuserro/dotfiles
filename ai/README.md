# AI Workstation Framework

Hub neutral de infraestructura IA para dotfiles: runtime ejecutable, assets de conocimiento y adapters por agente.

## Arquitectura

```
ai/
  runtime/     # Código ejecutable (MCP servers, runtimes)
  assets/      # Conocimiento consumido por agentes (skills, prompts, rules)
  adapters/    # Wiring específico de cada agente (cursor, codex, opencode)
```

## Principios

| Concepto   | Descripción                                              |
| ---------- | -------------------------------------------------------- |
| **runtime** | Código ejecutable usado por agentes (MCP servers)        |
| **assets**  | Conocimiento consumido por agentes (skills, prompts, rules) |
| **adapters** | Configuración específica de cada IDE/agente             |
| **hub XDG** | `~/.config/ai` como punto central (estándar XDG)         |

## Estructura en el sistema

Tras `chezmoi apply` (script `run_after_11_link_ai_assets`):

```
~/.config/ai/
  runtime/     # venv y dependencias Python para MCP
  skills/      # symlink → dotfiles/ai/assets/skills
  prompts/     # symlink → dotfiles/ai/assets/prompts
  rules/       # symlink → dotfiles/ai/assets/rules

# Cada skill en ai/assets/skills/* se symlinkea en:
~/.cursor/skills-cursor/<skill>  → ~/.config/ai/skills/<skill>
~/.codex/skills/<skill>          → ~/.config/ai/skills/<skill>
~/.config/opencode/skills/<skill> → ~/.config/ai/skills/<skill>
```

> **Nota:** `.claude/skills/` es una convención de nombre compartida por Claude Code y OpenCode. No implica que el repo soporte a Claude — es solo el nombre del directorio que ambos herramientas usan para skills. Los skills de este repo viven en `ai/assets/skills/` y se symlinkean a las rutas que cada plataforma espera.

## Adapters

El directorio `ai/adapters/` documenta el wiring específico de cada agente. Contiene adapters simples para Codex y Cursor. OpenCode tiene documentación completa en `docs/OPENCODE.md` y no requiere adapter adicional aquí.

## Añadir skills

1. Clonar o copiar el skill en `ai/assets/skills/<nombre-skill>/`
2. El skill debe contener `SKILL.md` (formato Cursor/Codex) o equivalente
3. Si clonas un repo externo: `git clone <url> ai/assets/skills/<nombre>` y luego `rm -rf ai/assets/skills/<nombre>/.git` para trackear los archivos
4. Tras `chezmoi apply`, el script `run_after_11_link_ai_assets` publica los skills a cada agente

### Skills instalados

- **excalidraw-diagram**: [coleam00/excalidraw-diagram-skill](https://github.com/coleam00/excalidraw-diagram-skill) — genera diagramas Excalidraw desde descripciones. Requiere Playwright para validación visual (ver README del skill).

## Separación transversal vs proyecto

| Tipo                     | Ubicación           |
| ------------------------ | ------------------- |
| Herramientas universales | dotfiles/ai/...     |
| Prompts de proyecto X    | repo del proyecto   |

El hub `ai/` contiene solo assets reutilizables entre proyectos.

## Añadir un nuevo MCP servidor

Ver [docs/GUIA_MCP_AI.md](../docs/GUIA_MCP_AI.md) — sección "Añadir un nuevo MCP servidor Python".
