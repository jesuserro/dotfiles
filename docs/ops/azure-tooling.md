# Azure tooling en Dotfiles

Esta guía describe la integración mínima de Azure tooling en `dotfiles` para trabajar desde Windows 11 Pro + WSL2 sin mezclar configuración local con despliegues reales.

## Objetivo

`dotfiles` prepara herramientas generales, aliases, checks y setup local. No crea recursos Azure, no guarda credenciales y no contiene nombres reales de recursos para proyectos.

Los despliegues concretos de `energy-offer-comparator` deben vivir en ese repo: build/push/deploy, puerto `8501`, nombres de recursos, ACR, Container Apps, Azure SQL si aplica y Managed Identity si aplica.

## Herramientas esperadas

Críticas para esta fase:

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

- Decidir canal de instalación de Azure CLI para WSL2/corporativo.
- Valorar `scripts/install-azure-cli.sh` opt-in, idempotente y con `DRY_RUN=1`.
- Valorar declarar `azure-cli` en `system/packages/tooling.yaml`.
- Preparar scripts específicos en `energy-offer-comparator`.
- Valorar Managed Identity y `AcrPull` más adelante.
