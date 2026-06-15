# Connect-Spo

Autenticacion interactiva unificada para SharePoint Online en `pslib`, publicada como modulo PowerShell no compilado.

Ubicacion vigente del modulo: `modules/Connect-Spo`

---

## Instalacion

Para cargar el modulo desde este repositorio, agrega temporalmente el directorio padre `modules/` a `PSModulePath`:

```powershell
$repoModules = Resolve-Path .\modules
$oldPSModulePath = $env:PSModulePath
$env:PSModulePath = "$repoModules$([IO.Path]::PathSeparator)$oldPSModulePath"

Import-Module Connect-Spo -Force
Get-Command Connect-Spo -Module Connect-Spo
```

Tambien puedes cargarlo por manifiesto:

```powershell
Import-Module .\modules\Connect-Spo\Connect-Spo.psd1 -Force
```

El wrapper historico de incubadora sigue disponible en `tools/Connect-Spo/src/Connect-Spo.ps1`, pero solo carga el modulo canonico y no contiene una segunda implementacion.

**Requisitos:**

- PowerShell 5.1 o superior.
- `PnP.PowerShell` disponible en la sesion.
- Una App Registration en Entra ID con `ClientId` valido.
- Permisos delegados adecuados para el sitio u operacion.

**Variables de entorno aceptadas para `ClientId`:**

- `ENTRAID_CLIENT_ID`
- `ENTRAID_APP_ID`

---

## Uso Rapido

```powershell
$repoModules = Resolve-Path .\modules
$env:PSModulePath = "$repoModules$([IO.Path]::PathSeparator)$env:PSModulePath"
Import-Module Connect-Spo -Force

$connection = Connect-Spo `
  -SiteUrl 'https://contoso.sharepoint.com/sites/demo' `
  -TenantId 'contoso.onmicrosoft.com' `
  -ClientId '00000000-0000-0000-0000-000000000000' `
  -AuthMode Interactive
```

Si no pasas `-ClientId`, el comando intenta resolverlo desde `ENTRAID_CLIENT_ID` y luego `ENTRAID_APP_ID`.

---

## Referencia de API

### `Connect-Spo`

Unica funcion publica exportada por el modulo. Inicia autenticacion interactiva unificada y devuelve la conexion PnP reutilizable.

| Parametro | Tipo | Descripcion | Requerido | Default |
|-----------|------|-------------|-----------|---------|
| `SiteUrl` | `string` | URL HTTPS del sitio SharePoint objetivo. | Si | - |
| `TenantId` | `string` | Tenant Microsoft 365 / Entra ID. | Si | - |
| `ClientId` | `string` | App Registration. Si falta, se busca en variables de entorno aceptadas. | No | - |
| `AuthMode` | `string` | `Interactive` o `DeviceCode`. | No | `Interactive` |

**Retorna:** objeto de conexion devuelto por `PnP.PowerShell`.

**Ejemplos:**

```powershell
# Interactive
$connection = Connect-Spo `
  -SiteUrl 'https://contoso.sharepoint.com/sites/demo' `
  -TenantId 'contoso.onmicrosoft.com' `
  -ClientId '00000000-0000-0000-0000-000000000000' `
  -AuthMode Interactive

# DeviceCode
$connection = Connect-Spo `
  -SiteUrl 'https://contoso.sharepoint.com/sites/demo' `
  -TenantId 'contoso.onmicrosoft.com' `
  -ClientId '00000000-0000-0000-0000-000000000000' `
  -AuthMode DeviceCode
```

---

## Manejo de Errores

```powershell
try {
    Connect-Spo `
      -SiteUrl 'https://contoso.sharepoint.com/sites/demo' `
      -TenantId 'contoso.onmicrosoft.com' `
      -ClientId '00000000-0000-0000-0000-000000000000'
}
catch {
    $_.Exception.Message
}
```

Mensajes comunes:

- `Autenticación cancelada por el usuario. No se continuará con la operación de SharePoint.`
- `Autenticación completada, pero la cuenta o la aplicación no tiene permisos suficientes para el sitio u operación solicitada.`
- `No se puede iniciar autenticación: falta o es inválido uno de los datos requeridos: SiteUrl, TenantId o ClientId.`
- `No se encontró PnP.PowerShell. Instálalo con: Install-Module PnP.PowerShell -Scope CurrentUser`

---

## Limitaciones

- Requiere `PnP.PowerShell`; el modulo no lo instala automaticamente.
- No crea App Registrations ni administra consentimientos.
- No usa contraseña, secreto de cliente, certificado, access token manual ni `-PersistLogin`.
- Exporta solo `Connect-Spo`; los helpers internos no forman parte de la API publica.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 1.3.0 | 2026-06-13 | Docs Agent | Actualiza la documentacion de usuario para reflejar la ruta vigente `tools/Connect-Spo` y `src/Connect-Spo.ps1`. |
| 1.4.0 | 2026-06-14 | Docs Agent | Actualiza la documentacion para reflejar el modulo `Connect-Spo` y su unica API publica exportada. |
