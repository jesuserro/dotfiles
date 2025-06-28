# 🗂️ Branch Policy & Git Workflow

Esta documentación describe la nueva política de ramas y workflow de Git implementada en este proyecto.

## 📋 Política de Ramas

| Rama | Propósito | Regla de oro |
|------|-----------|--------------|
| **`main`** | Producción – solo código estable, testeado y listo para deploy | _Nunca se trabaja directamente aquí_ |
| **`dev`**  | Integración continua – donde confluyen todas las _features_ | Debe ser *siempre* integrable<br>(tests verdes) |
| **`feature/*`** | Trabajo diario – una rama por funcionalidad, vida corta | Se elimina tras fusionarse en `dev` |
| **Tags (`vX.Y.Z`)** | Versión inmutable de lo que hay en `main` | Se crean **solo** después de un release |
| **`hotfix/*`** (opcional) | Parche crítico sobre `main` | Una vez aceptado, merge a `main` y `dev` |

## 🔄 Flujo Estándar

1. **Crear feature**: `git start-feature <nombre>`
2. **Trabajar**: Hacer commits en la rama feature
3. **Integrar**: `git feat <nombre>` (integra en `dev`)
4. **Release**: `git rel [<versión>]` (publica `dev` → `main`)

## 🛠️ Scripts Disponibles

### `scripts/git_feat.sh`
Integra una rama feature en `dev` y la archiva.

**Uso:**
```bash
git feat <nombre-feature>
```

**Funcionalidades:**
- ✅ Valida que estés en un repositorio Git
- ✅ Verifica working directory limpio
- ✅ Detecta automáticamente si la rama tiene prefijo `feature/`
- ✅ Verifica conflictos potenciales
- ✅ Hace merge de feature → dev
- ✅ Archiva la rama feature como `archive/feature/nombre`
- ✅ Elimina la rama original del remoto

### `scripts/git_rel.sh`
Publica `dev` en `main` y crea un tag de versión.

**Uso:**
```bash
git rel              # Versión automática vAAAA.MM.DD_HHMM
git rel 2.1.0        # Versión específica v2.1.0
```

**Funcionalidades:**
- ✅ Ejecuta tests automáticamente (detecta Node.js, Python, Maven)
- ✅ Valida que las ramas `dev` y `main` existan
- ✅ Verifica working directory limpio
- ✅ Hace merge de dev → main
- ✅ Crea tag de versión (automática o específica)
- ✅ Push de cambios y tag

### `scripts/git_workflow.sh`
Muestra la guía completa del workflow.

**Uso:**
```bash
git workflow
```

## 🎯 Comandos Git Alias

Los siguientes alias están configurados en `~/.gitconfig`:

```ini
[alias]
  # Integra feature en dev
  feat = "!f() { TOP=$(git rev-parse --show-toplevel); bash \"$TOP/scripts/git_feat.sh\" \"$@\"; }; f"
  
  # Publica release de dev → main
  rel = "!f() { TOP=$(git rev-parse --show-toplevel); bash \"$TOP/scripts/git_rel.sh\" \"$@\"; }; f"
  
  # Muestra la guía de workflow
  workflow = "!bash ~/dotfiles/scripts/git_workflow.sh"
  
  # Scripts personalizados
  save = "!bash ~/dotfiles/scripts/git_save.sh"
  cc = "!bash ~/dotfiles/scripts/git_cc.sh"
  update = "fetch --prune --all && pull"
  
  # Comandos básicos
  gs = status
  ga = add
  gaa = add --all
  gc = commit --no-template -m
  gp = push
  gl = pull
  gco = checkout
  gb = branch
  gdf = diff --color-words --word-diff=color
  gdfc = diff --color-words --word-diff=color -U3
  
  # Comandos avanzados
  glog = log --oneline --graph --decorate
  glg = log --graph --oneline --all --pretty=format:'%C(yellow)%h%Creset - %s %C(green)(%ad) %C(cyan)[%an]%Creset' --date=format:'%Y-%m-%d %H:%M:%S'
  gbinfo = for-each-ref --sort=-committerdate refs/heads/ --format='%(color:yellow)%(refname:short)%(color:reset) - %(color:green)%(committerdate:short)%(color:reset) - %(color:blue)%(authorname)%(color:reset) - %(contents:subject)'
  gclean = !sh -c 'git branch --merged | grep -v "main\\|master\\|dev\\|*" | xargs git branch -d'
```

## 📝 Ejemplos de Uso

### Crear y trabajar en una feature
```bash
# Crear nueva feature
git start-feature adding-dbt

# Trabajar en la feature
git add .
git commit -m "feat(dbt): add new models"
git push origin feature/adding-dbt
```

### Integrar feature en dev
```bash
# Integrar feature (automáticamente la archiva)
git feat adding-dbt
```

### Hacer release a producción
```bash
# Release con versión automática
git rel

# Release con versión específica
git rel 2.1.0
```

## ⚠️ Reglas de Oro

1. **Nunca trabajar directamente en `main`**
2. **`dev` debe ser siempre integrable** (tests verdes)
3. **Una feature = una rama = vida corta**
4. **Tags solo después de release**
5. **Working directory limpio** antes de cualquier operación

## 🔧 Configuración Requerida

### Scripts
- ✅ Scripts en `scripts/` con permisos `+x`
- ✅ Alias añadidos a `~/.gitconfig`

### Tests
- ✅ Tests automáticos configurados (npm/pytest/mvn)
- ✅ Tests se ejecutan automáticamente en releases

### Equipo
- ✅ Equipo informado de la nueva convención
- ✅ Documentación disponible

## 🚀 Beneficios

- **Flujo predecible**: Siempre sabes qué rama usar para qué
- **Integración continua**: `dev` siempre está actualizado
- **Releases controlados**: Solo `main` va a producción
- **Historial limpio**: Features se archivan automáticamente
- **Tests automáticos**: Validación antes de cada release

## 📚 Comandos Útiles Adicionales

```bash
# Ver guía completa
git workflow

# Ver historial de commits desde dev
git prettylog

# Ver estadísticas de cambios
git diffstat

# Ver tags disponibles
git taglist

# Ver información de ramas
git gbinfo
```

## 🧪 Configuración de Tests

El script `git rel` ejecuta automáticamente los tests antes de hacer release. Soporta múltiples tecnologías:

### 🔧 Detección Automática

El script detecta automáticamente tu stack tecnológico y ejecuta los tests correspondientes:

| Tecnología | Archivo de Detección | Comando de Test |
|------------|---------------------|-----------------|
| **Node.js** | `package.json` | `npm test` |
| **Python** | `pyproject.toml` / `requirements.txt` | `python3 -m pytest` (o `python`) |
| **Java/Maven** | `pom.xml` | `mvn test` |
| **Java/Gradle** | `build.gradle` | `./gradlew test` |
| **Rust** | `Cargo.toml` | `cargo test` |
| **Go** | `go.mod` | `go test ./...` |
| **PHP** | `composer.json` | `composer test` |
| **Ruby** | `Gemfile` | `bundle exec rspec` |
| **Makefile** | `Makefile` con target `test:` o `tests:` | `make test` o `make tests` |

### 🎯 Script Personalizado (Recomendado)

Para máxima flexibilidad, crea `scripts/test.sh`:

```bash
# Copiar el ejemplo
cp scripts/test.sh.example scripts/test.sh

# Personalizar según tu proyecto
nano scripts/test.sh
```

**Ejemplo de `scripts/test.sh`:**
```bash
#!/bin/bash
set -e

echo "🧪 Ejecutando tests personalizados..."

# Tests de linting
npx eslint . --ext .js,.jsx,.ts,.tsx

# Tests de formato
npx prettier --check .

# Tests de seguridad
npm audit --audit-level moderate

# Tests unitarios
npm test

# Tests de build
npm run build

# Tests de Docker
docker build -t test-image .
docker rmi test-image

echo "✅ Todos los tests pasaron"
```

### 📋 Configuración por Tecnología

#### Node.js
```json
// package.json
{
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint .",
    "build": "webpack --mode production"
  }
}
```

#### Python
```toml
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]

[tool.black]
line-length = 88

[tool.isort]
profile = "black"
```

**Nota:** El script intenta usar `python3` primero, luego `python` como fallback.

#### Java/Maven
```xml
<!-- pom.xml -->
<build>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-surefire-plugin</artifactId>
      <version>3.0.0</version>
    </plugin>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-checkstyle-plugin</artifactId>
      <version>3.2.0</version>
    </plugin>
  </plugins>
</build>
```

### 🚨 Comportamiento en Fallo

Si los tests fallan:
- ❌ El release se **cancela automáticamente**
- 🔍 Se muestra información detallada del error
- 💡 Se sugieren comandos para resolver el problema

### ⚙️ Configuración Avanzada

#### Tests Condicionales
```bash
# scripts/test.sh
#!/bin/bash

# Solo ejecutar tests de BD si está disponible
if command -v psql &> /dev/null; then
    echo "🗄️ Ejecutando tests de BD..."
    # tests de BD
fi

# Tests de Docker solo si Dockerfile existe
if [ -f "Dockerfile" ]; then
    echo "🐳 Ejecutando tests de Docker..."
    docker build -t test-image .
fi
```

#### Tests de Integración
```bash
# scripts/test-integration.sh
#!/bin/bash
echo "🔗 Ejecutando tests de integración..."
# Tu lógica de tests de integración
```

#### Tests de Performance
```bash
# scripts/test-performance.sh
#!/bin/bash
echo "⚡ Ejecutando tests de performance..."
# Tu lógica de tests de performance
```

### 📊 Monitoreo de Tests

El script proporciona feedback detallado:
- ✅ Tests que pasaron
- ❌ Tests que fallaron
- ⚠️ Tests que se saltaron
- 📈 Tiempo de ejecución

### 🔄 Integración con CI/CD

Los tests se ejecutan en el mismo orden que en tu pipeline de CI/CD:
1. Linting y formato
2. Tests unitarios
3. Tests de integración
4. Tests de build
5. Tests de seguridad

---

**¡Disfruta de un flujo Git limpio y predecible! 🚀** 