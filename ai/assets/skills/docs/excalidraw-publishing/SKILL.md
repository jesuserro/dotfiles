---
name: dotfiles-excalidraw-publishing
description: Publish Excalidraw diagrams from editable .excalidraw masters to SVG/PNG and Markdown/PDF deliverables without leaking internal editable sources.
---

# Dotfiles Excalidraw Publishing

Use `.excalidraw` as the editable master format and export derivatives for documents.

For agent-driven import/export, use the advanced Docker MCP named `excalidraw_canvas`. Do not use a generic `excalidraw` surface for publishing workflows unless the user explicitly requests it.

## When to Use

Use this skill when preparing Excalidraw diagrams for Markdown notes, technical PDFs, or external delivery.

## Outputs

- `.excalidraw.md` — native Obsidian note wrapper, not the MCP import target
- `.excalidraw` — editable source of truth
- `.svg` — preferred output for Markdown and technical PDF
- `.png` — compatibility output when a consumer cannot render SVG well

For dotfiles-managed MCP editing, import/export with container-internal paths under `/workspace/excalidraw/...`. Do not pass host WSL paths under `/mnt/c/...` to MCP file tools.

## Naming

Keep source and export names paired:

```text
architecture-flow.excalidraw
architecture-flow.svg
architecture-flow.png
```

## Markdown

Embed SVG when possible:

```markdown
![Architecture flow](diagrams/architecture-flow.svg)
```

Use PNG only for platforms with weak SVG support.

## Delivery Policy

Do not include editable `.excalidraw` sources when the requested deliverable is only a PDF, SVG, or PNG. Share masters only when the recipient is expected to edit the diagram.

If you need an agent-safe workflow: import the `.excalidraw` sidecar, export first to a new `.excalidraw` file, and keep all MCP writes inside `/workspace/excalidraw`. SVG export or screenshots require the canvas frontend to be open at `http://127.0.0.1:3210`.
