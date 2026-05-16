# Azure tooling en Dotfiles

Esta guía describe la integración mínima de Azure tooling en `dotfiles` para trabajar desde Windows 11 Pro + WSL2 sin mezclar configuración local con despliegues reales.

## Objetivo

`dotfiles` prepara herramientas generales, aliases, checks y setup local. No crea recursos Azure, no guarda credenciales y no contiene nombres reales de recursos para proyectos.

Los despliegues concretos de `energy-offer-comparator` deben vivir en ese repo: build/push/deploy, puerto `8501`, nombres de recursos, ACR, Container Apps, Azure SQL si aplica y Managed Identity si aplica.

## Herramientas esperadas

Azure CLI es **opt-in** en este repo. No se instala con `make install`, no
bloquea los checks generales y solo debe instalarse cuando el usuario lo pida
explícitamente:

```bash
DRY_RUN=1 make install-azure-cli
make install-azure-cli
```

El instalador usa el repo oficial de Microsoft para Debian/Ubuntu/WSL, pero no
ejecuta login, no selecciona suscripciones, no instala Docker Engine, no instala
extensiones y no toca `~/.azure`.

Antes de configurar APT, el instalador valida que Microsoft publique el canal
para el codename detectado en:

```bash
https://packages.microsoft.com/repos/azure-cli/dists/<codename>/Release
```

Codenames nuevos de Ubuntu, como `resolute`, pueden no estar publicados todavía.
En ese caso el instalador debe parar sin escribir fuentes APT ni romper
`apt-get update`. Opciones seguras:

- esperar soporte oficial;
- usar WSL2 con una distro Ubuntu soportada;
- usar Azure Cloud Shell;
- usar Azure CLI desde Docker.

Solo si aceptas el riesgo de mezclar suites APT, puedes forzar manualmente el
codename del repo:

```bash
AZURE_CLI_APT_CODENAME_OVERRIDE=noble make install-azure-cli
```

Si una prueba anterior dejó una fuente inválida dedicada a Azure CLI, la limpieza
también es opt-in:

```bash
DRY_RUN=1 AZURE_CLI_CLEAN_INVALID_SOURCE=1 make install-azure-cli
AZURE_CLI_CLEAN_INVALID_SOURCE=1 make install-azure-cli
```

La limpieza se limita a fuentes dedicadas de Azure CLI y no borra keyrings
Microsoft por defecto.

Azure CLI está declarado como herramienta externa opcional en el inventario de
dependencias (`system/packages/tooling.yaml`). Esto permite recomendar
`make install-azure-cli` sin convertir `az` en dependencia base de Dotfiles ni
bloquear equipos sin Azure.

Críticas solo para el flujo Azure:

- `az`
- `docker`
- `docker compose`
- `git`
- `make`
- `jq`
- `curl`

Recomendadas:

- `gh`
- `yq`
- `unzip`
- `gpg` o `gnupg`
- `lsb_release`

Comprueba el entorno sin mutar nada:

```bash
bash scripts/check-azure-tools.sh
```

Este check sí puede fallar si falta `az`, porque es un readiness check Azure
explícito. En equipos sin Azure no hace falta ejecutarlo.

## Azure CLI

Iniciar sesión es una acción manual:

```bash
az login
```

Ver la suscripción activa:

```bash
az account show --output table
```

Listar suscripciones:

```bash
az account list --output table
```

Cambiar de suscripción, manualmente:

```bash
az account set --subscription "<subscription-name-or-id>"
```

No guardes subscription IDs reales, tenant IDs reales ni credenciales en `dotfiles`.

## Docker y Docker Compose

En Windows 11 Pro + WSL2 se recomienda Docker Desktop con integración WSL activada, no instalar Docker Engine dentro de WSL2 desde estos dotfiles.

Comprobar Docker:

```bash
docker --version
docker info
```

Comprobar Docker Compose:

```bash
docker compose version
```

## Azure Container Apps

Comprobar extensiones Azure CLI:

```bash
az extension list --output table
```

Comprobar la extensión `containerapp`:

```bash
az extension show --name containerapp --output table
```

Instalar o actualizar manualmente la extensión si falta:

```bash
az extension add --name containerapp --upgrade
```

## Aliases disponibles

Los aliases viven en `zsh/55-aliases-azure.zsh` y se cargan desde el `zshrc` modular del repo:

| Alias | Comando |
| --- | --- |
| `azlogin` | `az login` |
| `azacct` | `az account show --output table` |
| `azsubs` | `az account list --output table` |
| `azsetsub` | `az account set --subscription` |
| `azgroups` | `az group list --output table` |
| `azacr` | `az acr list --output table` |
| `azcapps` | `az containerapp list --output table` |
| `azexts` | `az extension list --output table` |
| `azcaext` | `az extension show --name containerapp --output table` |
| `azlocs` | `az account list-locations --output table` |

No hay aliases para crear o borrar recursos.

Nota sobre `azsetsub`: ejecuta `az account set --subscription`. No crea, borra ni modifica recursos Azure, pero sí cambia la suscripción activa que usarán comandos posteriores de Azure CLI. Úsalo conscientemente y verifica después el contexto con `azacct` o `az account show --output table`.

## Separación de responsabilidades

`dotfiles`:

- herramientas generales;
- aliases;
- checks locales;
- documentación de setup.

`energy-offer-comparator`:

- build/push/deploy concretos;
- nombres de recursos;
- puerto `8501`;
- ACR;
- Container Apps;
- Azure SQL si aplica;
- Managed Identity si aplica.

## Seguridad

Esta fase no guarda:

- secretos;
- tokens;
- passwords;
- connection strings;
- claves de ACR;
- claves de Azure SQL;
- credenciales Microsoft 365;
- subscription IDs reales;
- tenant IDs reales.

`dotfiles` tampoco hace login automático, no selecciona suscripción automáticamente, no crea recursos Azure, no borra recursos Azure y no modifica permisos.

## Microsoft 365 / Entra ID / Exchange Online

Microsoft Graph CLI, Microsoft Graph PowerShell, Exchange Online PowerShell, permisos administrativos de tenant y consentimiento administrativo quedan fuera de esta fase.

Si hacen falta más adelante, deben tratarse como fase separada por su superficie administrativa y de permisos.

## TODO posteriores

- Resuelto: instalador opt-in `scripts/install-azure-cli.sh` con `DRY_RUN=1`.
- Resuelto: target manual `make install-azure-cli` fuera de `make install`.
- Resuelto: `azure-cli` declarado como herramienta externa opcional en
  `system/packages/tooling.yaml`.
- Validar instalación real de Azure CLI en equipo de trabajo.
- Valorar automatización opcional de la extensión `containerapp`.
- Preparar Fase 2 en `energy-offer-comparator`.
