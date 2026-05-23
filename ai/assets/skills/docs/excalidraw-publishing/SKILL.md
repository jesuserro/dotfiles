---
name: dotfiles-excalidraw-publishing
description: Publish Excalidraw diagrams from editable .excalidraw masters to SVG/PNG and Markdown/PDF deliverables without leaking internal editable sources.
---

# Dotfiles Excalidraw Publishing

Use `.excalidraw` as the editable master format and export derivatives for documents.

## When to Use

Use this skill when preparing Excalidraw diagrams for Markdown notes, technical PDFs, or external delivery.

## Outputs

- `.excalidraw` — editable source of truth
- `.svg` — preferred output for Markdown and technical PDF
- `.png` — compatibility output when a consumer cannot render SVG well

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
