# Excalidraw Architecture Conventions

Standards for creating clear, consistent technical diagrams with Excalidraw.

## When to Use

- System architecture overviews
- Data flow diagrams
- Sequence diagrams
- Entity relationship sketches
- Process workflows
- Deployment diagrams

## Visual Conventions

### Color Palette

| Element Type | Color | Hex |
|--------------|-------|-----|
| External systems | Yellow | `#fef3c7` |
| Your system/service | Blue | `#dbeafe` |
| Database/storage | Green | `#dcfce7` |
| Queue/async | Purple | `#ede9fe` |
| User/actor | Gray | `#f3f4f6` |
| Internet/cloud | Light gray | `#f9fafb` |

### Shape Conventions

| Element | Shape | Notes |
|---------|-------|-------|
| Service/component | Rounded rectangle | Blue fill |
| Database | Cylinder | Green fill |
| External API | Rectangle with icon | Yellow fill |
| User | Circle/avatar | Gray fill |
| Queue | Parallelogram | Purple fill |
| Decision | Diamond | - |
| Data flow | Arrow | Labeled |
| Async message | Dashed arrow | - |

### Layout Principles

1. **Top-down flow**: Data usually flows down
2. **Left-to-right**: Sequence of operations
3. **Group related elements**: With subtle background
4. **Consistent spacing**: 40-60px between elements
5. **Limited nesting**: Max 3 levels deep per diagram

## Text Conventions

- **Labels**: Sentence case, concise (`User Service`, not `UserService`)
- **Numbers**: Use for sequence order when needed
- **Abbreviate**: `DB` for Database, `API` for interface
- **No jargon**: Assume new team member reading

## Export Settings

- **Format**: PNG with transparent background for docs
- **PNG for slides**: White background
- **SVG**: For web integration
- **Library**: Export custom elements to `.excalidrawlib`

## Quality Checklist

- [ ] All elements labeled clearly
- [ ] Data flow direction is obvious
- [ ] External systems distinguished from internal
- [ ] Legend included if using custom symbols
- [ ] No diagram exceeds one logical page
- [ ] Colors used consistently

## Related Skills

- `etl-data-contracts`: For data flow specifics
- `gitnexus-exploring`: For understanding system structure
