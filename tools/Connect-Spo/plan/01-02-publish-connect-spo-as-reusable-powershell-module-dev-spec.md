# Publicar Connect-Spo como Módulo PowerShell Reutilizable - Dev Spec

**Estado:** EN_REVISION

## Historia Objetivo

- Producto: `tools/Connect-Spo/plan/00-sharepoint-auth-unified-spec.md` (`APROBADO`).
- Épica: `tools/Connect-Spo/plan/01-interactive-sharepoint-auth-spec.md` (`APROBADO`).
- Historia: `tools/Connect-Spo/plan/01-02-publish-connect-spo-as-reusable-powershell-module-spec.md` (`APROBADO`).
- Alcance técnico de este dev spec: publicar la capacidad reusable existente como módulo PowerShell no compilado en `modules/Connect-Spo`, importable por nombre con `Import-Module Connect-Spo` cuando el padre `modules/` esté disponible en `PSModulePath`.

## Verificación de Estado

La historia objetivo declara `**Estado:** APROBADO` en la línea 3 del story spec, por lo que Planning puede generar este dev spec. Producto y épica también están en `APROBADO`.

## Resumen Técnico

Se migrará la implementación funcional vigente desde `tools/Connect-Spo/src/Connect-Spo.ps1` hacia un módulo script PowerShell como fuente reusable canónica:

```text
modules/Connect-Spo/
|- Connect-Spo.psd1
`- Connect-Spo.psm1
```

El módulo debe:

1. Cargar por nombre con `Import-Module Connect-Spo` cuando `modules/` esté en `PSModulePath`.
2. Exportar explícitamente solo la API pública aprobada `Connect-Spo`.
3. Mantener helpers internos encapsulados dentro del módulo, sin exportarlos como comandos públicos.
4. Reutilizar el comportamiento aprobado de autenticación sin duplicar innecesariamente lógica entre `tools/Connect-Spo/src/Connect-Spo.ps1` y `modules/Connect-Spo/Connect-Spo.psm1`.
5. Mantener artefactos de proceso y tests bajo `tools/Connect-Spo/`.

## Investigación y Decisiones

### Patrones oficiales PowerShell usados

- Un módulo script PowerShell es un archivo `.psm1`; el directorio y el archivo de módulo suelen usar el mismo nombre para que el motor pueda cargarlo por nombre desde rutas en `PSModulePath`.
- `PSModulePath` contiene carpetas donde PowerShell busca módulos `.psd1` o `.psm1`; para este repo, la ruta que debe agregarse temporalmente es el directorio padre `modules/`, no `modules/Connect-Spo`.
- Un manifiesto `.psd1` puede declarar `RootModule = 'Connect-Spo.psm1'` y restringir comandos públicos con `FunctionsToExport`.
- PowerShell recomienda exportar funciones explícitamente para rendimiento, descubribilidad y control de superficie pública.

### Dependencias seleccionadas

| Dependencia | Tipo | Uso | Justificación |
|-------------|------|-----|---------------|
| `PnP.PowerShell` | Runtime | Provee `Connect-PnPOnline` llamado por `Connect-Spo` | Dependencia existente de la capacidad aprobada; cubre autenticación `Interactive`/`DeviceCode`, `ClientId` y `ReturnConnection` sin manejar contraseñas propias. |
| `Pester` | Test | Tests de módulo, manifiesto, exportaciones y comportamiento por mocks | Estándar de verificación del repo para PowerShell. No es dependencia runtime. |
| `PSScriptAnalyzer` | Verificación | Análisis estático de `modules/Connect-Spo` y scripts de compatibilidad si quedan | Estándar de calidad del repo. No es dependencia runtime. |

No se agregan dependencias nuevas como `Microsoft.Graph`, MSAL directo, SecretManagement, empaquetadores externos ni publicación en PowerShell Gallery porque exceden la historia aprobada.

## Estructura Objetivo de Archivos

```text
pslib/
|- modules/
|  `- Connect-Spo/
|     |- Connect-Spo.psd1
|     `- Connect-Spo.psm1
`- tools/
   `- Connect-Spo/
      |- plan/
      |  |- 00-sharepoint-auth-unified-spec.md
      |  |- 01-interactive-sharepoint-auth-spec.md
      |  |- 01-02-publish-connect-spo-as-reusable-powershell-module-spec.md
      |  `- 01-02-publish-connect-spo-as-reusable-powershell-module-dev-spec.md
      |- src/
      |  `- Connect-Spo.ps1
      `- tests/
         |- Connect-Spo.Tests.ps1
         `- Connect-Spo.Module.Tests.ps1
```

`tools/Connect-Spo/src/Connect-Spo.ps1` no debe contener una segunda copia divergente de la lógica. Tras la migración, el boundary técnico será:

- `modules/Connect-Spo/Connect-Spo.psm1`: fuente canónica de la implementación reusable.
- `modules/Connect-Spo/Connect-Spo.psd1`: manifiesto de carga y exportación pública.
- `tools/Connect-Spo/src/Connect-Spo.ps1`: entrypoint/compatibilidad de incubadora para cargar la implementación canónica sin ejecutar autenticación automáticamente, o archivo mínimo equivalente si se decide conservarlo para smoke tests históricos.
- `tools/Connect-Spo/tests/`: tests del módulo y, si el script permanece, tests que aseguren que no diverge del módulo.

## Contrato del Módulo

### Manifiesto `modules/Connect-Spo/Connect-Spo.psd1`

El manifiesto debe declarar, como mínimo:

| Campo | Valor requerido |
|-------|-----------------|
| `RootModule` | `'Connect-Spo.psm1'` |
| `ModuleVersion` | `'0.1.0'` |
| `GUID` | `'d25d6e6b-1e5c-4d18-a2fa-c30ab114e900'` |
| `Author` | `'pslib'` |
| `CompanyName` | `'Aucar Ltda'` |
| `Description` | `'Autenticación SharePoint Online unificada para tools PowerShell de pslib.'` |
| `PowerShellVersion` | `'5.1'` o superior si la implementación vigente exige PowerShell 7; si no hay dependencia exclusiva de PS7, mantener `'5.1'` para compatibilidad. |
| `FunctionsToExport` | `@('Connect-Spo')` |
| `CmdletsToExport` | `@()` |
| `VariablesToExport` | `@()` |
| `AliasesToExport` | `@()` |
| `PrivateData.PSData.ExternalModuleDependencies` | `@('PnP.PowerShell')` como metadata informativa |

No debe usar comodines en exportaciones públicas.

### Script module `modules/Connect-Spo/Connect-Spo.psm1`

Debe contener `Set-StrictMode -Version Latest`, Control de Cambios PowerShell y la implementación reusable. Al final debe restringir la superficie pública con exportación explícita de `Connect-Spo`.

## API Pública y Firmas

### `Connect-Spo`

Única función pública exportada por el módulo.

```powershell
function Connect-Spo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^https://')]
        [string]$SiteUrl,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [ValidateSet('Interactive', 'DeviceCode')]
        [string]$AuthMode = 'Interactive'
    )
}
```

Comportamiento heredado obligatorio:

- Valida `SiteUrl`, `TenantId`, `ClientId` resuelto y `AuthMode`.
- Verifica la disponibilidad de `Connect-PnPOnline` antes de conectar.
- Resuelve `ClientId` desde parámetro directo, `ENTRAID_CLIENT_ID` o `ENTRAID_APP_ID`.
- Usa `Connect-PnPOnline` con `-ReturnConnection` y `-ErrorAction Stop`.
- Soporta `Interactive` y `DeviceCode` según el comportamiento vigente.
- No usa `Read-Host`, `Get-Credential`, `-Credentials`, `-ClientSecret`, `-CertificatePath`, `-AccessToken`, `-EnvironmentVariable` ni `-PersistLogin`.
- Mantiene los mensajes funcionales aprobados para configuración inválida, cancelación, permisos insuficientes y fallback.
- Incluye ayuda basada en comentarios actualizada para consumo por módulo, con ejemplo basado en `Import-Module Connect-Spo`.

## Helpers Internos y Boundaries

Los helpers existentes deben migrarse al `.psm1` como funciones internas no exportadas. Sus firmas permanecen completas para preservar comportamiento y testabilidad mediante pruebas dentro del módulo cuando sea necesario.

### `Test-SharePointUnifiedAuthDependency`

```powershell
function Test-SharePointUnifiedAuthDependency {
    [CmdletBinding()]
    param()
}
```

Boundary: verifica `Get-Command -Name 'Connect-PnPOnline' -ErrorAction SilentlyContinue`; si falta, lanza `No se encontró PnP.PowerShell. Instálalo con: Install-Module PnP.PowerShell -Scope CurrentUser`.

### `Resolve-SharePointUnifiedClientId`

```powershell
function Resolve-SharePointUnifiedClientId {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [string[]]$EnvironmentVariableNames = @('ENTRAID_CLIENT_ID', 'ENTRAID_APP_ID')
    )
}
```

Boundary: helper interno; no exportar desde el módulo. Mantiene precedencia `ClientId` -> `ENTRAID_CLIENT_ID` -> `ENTRAID_APP_ID` y el mensaje aprobado si no resuelve valor.

### `New-SharePointUnifiedConnectParameters`

```powershell
function New-SharePointUnifiedConnectParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteUrl,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,

        [Parameter(Mandatory)]
        [ValidateSet('Interactive', 'DeviceCode')]
        [string]$AuthMode
    )
}
```

Boundary: retorna hashtable para splatting. Siempre incluye `Url`, `ClientId`, `ReturnConnection`, `ErrorAction`; agrega `Interactive` para modo `Interactive`; agrega `DeviceLogin` y `Tenant` para modo `DeviceCode`.

### `ConvertTo-SharePointUnifiedAuthError`

```powershell
function ConvertTo-SharePointUnifiedAuthError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory)]
        [ValidateSet('Interactive', 'DeviceCode')]
        [string]$AuthMode
    )
}
```

Boundary: retorna string normalizado según patrones vigentes; no depende de tipos internos de PnP.PowerShell.

## Boundary de Reutilización y Migración

Incluido:

- Crear `modules/Connect-Spo/Connect-Spo.psd1`.
- Crear `modules/Connect-Spo/Connect-Spo.psm1`.
- Migrar la implementación aprobada desde `tools/Connect-Spo/src/Connect-Spo.ps1` al `.psm1`.
- Ajustar `tools/Connect-Spo/src/Connect-Spo.ps1` para evitar duplicación de lógica; si se conserva, debe cargar o delegar en el módulo canónico y no ejecutar autenticación al ser cargado.
- Actualizar tests existentes para importar el módulo o validar el wrapper sin depender de dot-sourcing como mecanismo principal.
- Agregar tests específicos de manifiesto, importación por nombre, exportación pública y ausencia de exportación de helpers.

Excluido:

- No modificar `tools/Get-SpoListNames` ni otra tool adoptante en esta historia.
- No publicar en PowerShell Gallery.
- No instalar módulos en ubicaciones persistentes del usuario ni modificar `PSModulePath` permanentemente.
- No agregar alias, wrappers públicos alternativos ni reexportar helpers.
- No cambiar nombres de parámetros, modos de autenticación, mensajes funcionales, flujo PnP ni dependencias runtime.
- No crear App Registrations, consentimientos ni permisos en Entra ID.

## Tests Previstos

### `tools/Connect-Spo/tests/Connect-Spo.Module.Tests.ps1`

Casos mínimos:

- `Test-ModuleManifest` sobre `modules/Connect-Spo/Connect-Spo.psd1` es válido.
- Con `PSModulePath` controlado para incluir el directorio repo `modules/`, `Import-Module Connect-Spo -Force` carga el módulo por nombre.
- `Get-Module Connect-Spo` retorna un módulo con `RootModule` `Connect-Spo.psm1` y `Version` `0.1.0`.
- `Get-Command Connect-Spo -Module Connect-Spo` resuelve exactamente una función pública.
- Los comandos públicos del módulo son exactamente `Connect-Spo`.
- `Resolve-SharePointUnifiedClientId`, `Test-SharePointUnifiedAuthDependency`, `New-SharePointUnifiedConnectParameters` y `ConvertTo-SharePointUnifiedAuthError` no aparecen como comandos exportados del módulo.
- `Connect-Spo` conserva validaciones de `SiteUrl`, `TenantId` y `AuthMode`.
- Con mock/stub de `Connect-PnPOnline`, `Connect-Spo -AuthMode Interactive` invoca los parámetros aprobados y retorna conexión mockeada.
- Con mock/stub de `Connect-PnPOnline`, `Connect-Spo -AuthMode DeviceCode` invoca `DeviceLogin`, `Tenant`, `ClientId`, `Url` y `ReturnConnection`.
- `Connect-Spo` no pasa parámetros prohibidos: `PersistLogin`, `Credentials`, `ClientSecret`, `CertificatePath`, `AccessToken`, `EnvironmentVariable`.
- Si falta `Connect-PnPOnline`, el error sigue siendo accionable para instalar `PnP.PowerShell`.

### `tools/Connect-Spo/tests/Connect-Spo.Tests.ps1`

Actualizar o conservar solo si `tools/Connect-Spo/src/Connect-Spo.ps1` permanece como wrapper. Casos mínimos:

- Cargar el script no inicia autenticación.
- El script no define una implementación divergente de `Connect-Spo` cuando el módulo está disponible.
- El script deja disponible `Connect-Spo` mediante importación/delegación al módulo canónico.

## Comandos de Verificación

Ejecutar desde `tools/Connect-Spo` salvo que se indique otra ruta:

```powershell
Invoke-Pester -Path tests -Output Detailed
Invoke-ScriptAnalyzer -Path ..\..\modules\Connect-Spo -Recurse
Invoke-ScriptAnalyzer -Path src -Recurse
Test-ModuleManifest -Path ..\..\modules\Connect-Spo\Connect-Spo.psd1
```

Smoke test de importación por nombre con `PSModulePath` controlado desde `tools/Connect-Spo`:

```powershell
pwsh -NoProfile -Command "$repoModules = (Resolve-Path '..\..\modules').Path; $old = $env:PSModulePath; try { $env:PSModulePath = $repoModules + [IO.Path]::PathSeparator + $old; Import-Module Connect-Spo -Force; $commands = Get-Command -Module Connect-Spo | Select-Object -ExpandProperty Name; if (@($commands).Count -ne 1 -or $commands[0] -ne 'Connect-Spo') { throw 'Exportación pública inesperada.' }; 'OK' } finally { $env:PSModulePath = $old; Remove-Module Connect-Spo -ErrorAction SilentlyContinue }"
```

Smoke test directo del manifiesto desde la raíz del repo, útil para CI local:

```powershell
pwsh -NoProfile -Command "$repoRoot = (Resolve-Path '.').Path; $old = $env:PSModulePath; try { $env:PSModulePath = (Join-Path $repoRoot 'modules') + [IO.Path]::PathSeparator + $old; Import-Module Connect-Spo -Force; Get-Command Connect-Spo -Module Connect-Spo | Select-Object -ExpandProperty Name } finally { $env:PSModulePath = $old; Remove-Module Connect-Spo -ErrorAction SilentlyContinue }"
```

No se define smoke test con autenticación real porque requiere tenant, App Registration, consentimiento y credenciales interactivas fuera del alcance automatizable de esta historia.

## TODOs Atómicos Verificables

- [x] 1. Crear carpeta `modules/Connect-Spo/` si no existe.
- [x] 2. Crear `modules/Connect-Spo/Connect-Spo.psm1` con Control de Cambios PowerShell fechado `2026-06-14`.
- [x] 3. Migrar a `Connect-Spo.psm1` la función pública `Connect-Spo` desde `tools/Connect-Spo/src/Connect-Spo.ps1` sin cambiar firma ni comportamiento.
- [x] 4. Migrar a `Connect-Spo.psm1` los helpers `Test-SharePointUnifiedAuthDependency`, `Resolve-SharePointUnifiedClientId`, `New-SharePointUnifiedConnectParameters` y `ConvertTo-SharePointUnifiedAuthError` como internos no exportados.
- [x] 5. Agregar `Export-ModuleMember -Function 'Connect-Spo'` al módulo script y confirmar que no exporta helpers ni alias.
- [x] 6. Crear `modules/Connect-Spo/Connect-Spo.psd1` con `RootModule = 'Connect-Spo.psm1'`, `ModuleVersion = '0.1.0'`, GUID aprobado en este dev spec y `FunctionsToExport = @('Connect-Spo')`.
- [x] 7. Declarar `CmdletsToExport = @()`, `VariablesToExport = @()` y `AliasesToExport = @()` en el manifiesto.
- [x] 8. Agregar metadata informativa `PrivateData.PSData.ExternalModuleDependencies = @('PnP.PowerShell')`.
- [x] 9. Ajustar ayuda basada en comentarios de `Connect-Spo` para mostrar uso vía `Import-Module Connect-Spo`.
- [x] 10. Refactorizar `tools/Connect-Spo/src/Connect-Spo.ps1` para no duplicar la implementación canónica del módulo y no ejecutar autenticación al cargarse.
- [x] 11. Actualizar tests existentes que dot-sourceaban `src/Connect-Spo.ps1` para que validen el módulo o el wrapper según el nuevo boundary.
- [x] 12. Crear `tools/Connect-Spo/tests/Connect-Spo.Module.Tests.ps1` con importación por nombre usando `PSModulePath` temporal que incluya `modules/`.
- [x] 13. Agregar test de `Test-ModuleManifest` para `modules/Connect-Spo/Connect-Spo.psd1`.
- [x] 14. Agregar test que verifique que los comandos públicos del módulo son exactamente `Connect-Spo`.
- [x] 15. Agregar test que verifique que los helpers internos no están exportados por el módulo.
- [x] 16. Agregar tests de comportamiento de `Connect-Spo` con mocks/stubs de `Connect-PnPOnline` para `Interactive` y `DeviceCode`.
- [x] 17. Agregar test que confirme ausencia de parámetros prohibidos en la llamada a `Connect-PnPOnline`.
- [x] 18. Agregar test de error accionable cuando falta `Connect-PnPOnline`.
- [x] 19. Ejecutar `Invoke-Pester -Path tests -Output Detailed` desde `tools/Connect-Spo` y corregir fallas dentro del alcance.
- [x] 20. Ejecutar `Invoke-ScriptAnalyzer -Path ..\..\modules\Connect-Spo -Recurse` y corregir hallazgos dentro del alcance.
- [x] 21. Ejecutar `Invoke-ScriptAnalyzer -Path src -Recurse` si `src/Connect-Spo.ps1` permanece y corregir hallazgos dentro del alcance.
- [x] 22. Ejecutar `Test-ModuleManifest -Path ..\..\modules\Connect-Spo\Connect-Spo.psd1` y corregir fallas.
- [x] 23. Ejecutar smoke test con `PSModulePath` controlado e `Import-Module Connect-Spo` por nombre.
- [x] 24. Verificar que no quedan rutas relativas desde ninguna tool adoptante hacia `tools/Connect-Spo` introducidas por esta historia.
- [x] 25. Crear retro de implementación `tools/Connect-Spo/plan/01-02-publish-connect-spo-as-reusable-powershell-module-retro.md` solo durante Implementación.

## Riesgos y Mitigaciones

- Duplicación entre script y módulo: mitigar haciendo que el `.psm1` sea la fuente canónica y que `src/Connect-Spo.ps1` sea wrapper mínimo o se mantenga solo para compatibilidad de incubadora.
- Exportación accidental de helpers: mitigar con `Export-ModuleMember -Function 'Connect-Spo'`, `FunctionsToExport = @('Connect-Spo')` y test de comandos públicos exactos.
- `Import-Module Connect-Spo` no encuentra el módulo: mitigar documentando y testeando que debe agregarse el padre `modules/` a `PSModulePath`, no la carpeta del módulo directamente.
- Fallas ambientales por temporales en OneDrive: si Pester o analizadores fallan por bloqueo/caché de OneDrive, usar ubicación temporal preaprobada fuera de OneDrive y documentar la limitación en retro/test.
- Cambios funcionales involuntarios durante migración: mitigar portando tests existentes y agregando tests de parámetros prohibidos y mensajes aprobados.

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-14 | Planning Agent | Crea dev spec técnico en BORRADOR para publicar `Connect-Spo` como módulo PowerShell reusable importable por nombre. |
| 0.2.0 | 2026-06-14 | Planning Agent | Marca dev spec como APROBADO por aprobación explícita del usuario. |
| 0.3.0 | 2026-06-14 | Implementation Agent | Marca verificaciones finales completadas tras corregir wrapper, tests y encoding. |
