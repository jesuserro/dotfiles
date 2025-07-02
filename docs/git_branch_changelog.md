# Git Branch Changelog

## Descripción

El comando `git branch-changelog` genera changelogs específicos para la rama actual, comparando los commits con una rama base (por defecto `dev`).

## Uso

```bash
git branch-changelog [opciones]
```

## Opciones

- `--base <rama>`, `-b <rama>`: Especifica la rama base para comparar (por defecto: `dev`)
- `--help`, `-h`: Muestra la ayuda

## Ejemplos

### Generar changelog de la rama actual vs dev
```bash
git branch-changelog
```

### Generar changelog de la rama actual vs main
```bash
git branch-changelog --base main
```

### Generar changelog de la rama actual vs otra rama
```bash
git branch-changelog -b feature/login
```

## Funcionalidades

### 📊 Categorización Automática
El script categoriza automáticamente los commits según el formato de Conventional Commits:

- **Added**: Commits con prefijo `feat:` o `feature:`
- **Fixed**: Commits con prefijo `fix:`
- **Documentation**: Commits con prefijo `docs:`
- **Refactored**: Commits con prefijo `refactor:`
- **Tests**: Commits con prefijo `test:`
- **Style**: Commits con prefijo `style:`
- **Technical**: Commits con prefijo `chore:`
- **Other**: Otros commits

### 📁 Estructura de Archivos
Los changelogs se guardan en el directorio `releases/` con el formato:
```
releases/branch_[nombre_rama].md
```

### 📋 Información Incluida
Cada changelog incluye:

- **Fecha de generación**
- **Rama base** utilizada para la comparación
- **Último commit** de la rama
- **Commits categorizados** por tipo
- **Detalles técnicos** (rama, commits totales, etc.)

## Casos de Uso

### 1. Desarrollo de Features
```bash
# En una rama feature
git checkout feature/nueva-funcionalidad
git branch-changelog
# Genera: releases/branch_feature_nueva_funcionalidad.md
```

### 2. Revisión de Cambios
```bash
# Antes de hacer merge
git branch-changelog --base main
# Revisa qué cambios se van a integrar
```

### 3. Documentación de Ramas
```bash
# Para cualquier rama
git branch-changelog
# Documenta automáticamente todos los cambios
```

## Integración con el Workflow

Este comando complementa el workflow existente:

1. **Durante desarrollo**: `git branch-changelog` para documentar cambios
2. **Antes de merge**: `git branch-changelog --base main` para revisar
3. **En releases**: `git changelog` para generar changelog oficial

## Ventajas

- ✅ **Independiente**: No depende del flujo de `git feat`
- ✅ **Flexible**: Permite comparar con cualquier rama base
- ✅ **Automático**: Categoriza commits automáticamente
- ✅ **Documentado**: Genera archivos markdown bien estructurados
- ✅ **Reutilizable**: Se puede ejecutar en cualquier momento

## Diferencias con `git changelog`

| Aspecto | `git changelog` | `git branch-changelog` |
|---------|----------------|------------------------|
| **Propósito** | Changelogs oficiales de releases | Changelogs de ramas de desarrollo |
| **Dependencia** | Requiere tags | Solo requiere estar en una rama |
| **Frecuencia** | Para releases | En cualquier momento |
| **Archivos** | `releases/v1.2.3.md` | `releases/branch_feature_name.md` |
| **Contenido** | Cambios entre tags | Cambios de la rama actual | 