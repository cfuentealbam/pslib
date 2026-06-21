# Autenticación Interactiva Unificada para Tools SharePoint - Dev Spec

**Estado:** EN_REVISION

## Historia Objetivo

- Producto: `tools/Connect-Spo/plan/00-sharepoint-auth-unified-spec.md` (`APROBADO`).
- Épica: `tools/Connect-Spo/plan/01-interactive-sharepoint-auth-spec.md` (`APROBADO`).
- Historia: `tools/Connect-Spo/plan/01-01-unified-interactive-auth-for-sharepoint-tools-spec.md` (`APROBADO`).
- Alcance técnico de este dev spec: implementar una capacidad común reutilizable de autenticación interactiva SharePoint para futuras tools, sin modificar todavía `Get-SpoListNames` ni otra tool adoptante.
- Refinamiento funcional aprobado por Spec Design: la API pública principal observable debe llamarse `Connect-Spo`; este dev spec queda actualizado para planificar únicamente ese rename sobre la implementación existente.
- Refinamiento funcional aprobado por Spec Design: el nombre del tool aprobado es `Connect-Spo` y la ubicación objetivo es `tools/Connect-Spo`; este dev spec queda actualizado para planificar únicamente el traslado/rename de carpeta y referencias asociadas.

## Resumen Técnico

Se implementará/mantendrá un script reutilizable bajo `tools/Connect-Spo/src/Connect-Spo.ps1` que exponga funciones PowerShell públicas para:

1. Validar `SiteUrl`, `TenantId`, `ClientId` y `AuthMode`.
2. Resolver `ClientId` desde parámetro directo o desde una variable de ambiente explícita.
3. Iniciar conexión SharePoint con PnP.PowerShell usando flujo `Interactive` como modo principal.
4. Permitir `DeviceCode` como modo opcional implementado, mapeado al parámetro oficial `-DeviceLogin` de PnP.PowerShell, sin hacerlo obligatorio para tools adoptantes.
5. Devolver una conexión PnP reutilizable mediante `-ReturnConnection`, sin persistir tokens ni secretos.
6. Normalizar errores mínimos: configuración incompleta, cancelación, permisos/autorización y error general de autenticación.

No se creará módulo PowerShell bajo `modules/` porque producto e historia dejan fuera de alcance el empaquetado en módulos. La reutilización inicial será mediante dot-sourcing del script por futuras historias adoptantes.

## Investigación y Decisiones

### Fuente oficial PnP.PowerShell

- `Connect-PnPOnline -Interactive -Url <String> [-ClientId <String>] [-ReturnConnection]` permite login interactivo MFA y, desde los cambios modernos de PnP.PowerShell, espera un `ClientId` propio o variable de ambiente oficial.
- `Connect-PnPOnline -DeviceLogin -Url <String> -Tenant <String> [-ClientId <String>] [-ReturnConnection]` implementa device code flow en PnP.PowerShell.
- La documentación oficial menciona `ENTRAID_APP_ID` y `ENTRAID_CLIENT_ID` como variables aceptables para suplir `ClientId` en escenarios interactivos.
- `-PersistLogin` persiste token/cache local; no se usará para cumplir la restricción de no persistir secretos/tokens por esta capacidad.

### Dependencia seleccionada

| Dependencia | Tipo | Uso | Justificación |
|-------------|------|-----|---------------|
| `PnP.PowerShell` | Runtime | `Connect-PnPOnline` y tipo de conexión devuelto | Es la librería oficial y ya usada en contexto SharePoint del repo; cubre `Interactive`, `DeviceLogin`, `ClientId`, `Tenant` y `ReturnConnection` sin manejar contraseñas propias. |
| `Pester` | Test | Pruebas unitarias/mocking | Estándar de verificación del repo para scripts PowerShell. No es dependencia runtime. |
| `PSScriptAnalyzer` | Verificación | Análisis estático | Estándar de calidad del repo. No es dependencia runtime. |

No se agregan `Microsoft.Graph`, MSAL directo, SecretManagement ni manejo propio de tokens porque PnP.PowerShell cubre el alcance aprobado y agregar esas dependencias ampliaría superficie técnica sin necesidad.

## Estructura de Archivos

```text
tools/Connect-Spo/
|- plan/
|  |- 00-sharepoint-auth-unified-spec.md
|  |- 01-interactive-sharepoint-auth-spec.md
|  |- 01-01-unified-interactive-auth-for-sharepoint-tools-spec.md
|  `- 01-01-unified-interactive-auth-for-sharepoint-tools-dev-spec.md
|- src/
|  `- Connect-Spo.ps1
|- docs/
|  `- README.md
`- tests/
   `- Connect-Spo.Tests.ps1
```

La implementación del refactor mueve los artefactos de proceso a `tools/Connect-Spo/plan/`.

## API Pública y Firmas

Todas las funciones públicas deben incluir `CmdletBinding()`, validación de parámetros y ayuda basada en comentarios.

### Script reutilizable

Archivo objetivo: `tools/Connect-Spo/src/Connect-Spo.ps1`

El script debe poder dot-sourcearse sin ejecutar autenticación automáticamente:

```powershell
. "./src/Connect-Spo.ps1"
$connection = Connect-Spo -SiteUrl $SiteUrl -TenantId $TenantId -ClientId $ClientId -AuthMode Interactive
```

### `Connect-Spo`

Función pública principal. Reemplaza a `Connect-SharePointUnifiedAuth` como nombre público observable aprobado. No debe agregarse funcionalidad nueva durante este rename.

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

Comportamiento:

- Llama a `Test-SharePointUnifiedAuthDependency` antes de conectar.
- Llama a `Resolve-SharePointUnifiedClientId` para resolver `ClientId`.
- Llama a `New-SharePointUnifiedConnectParameters` para construir el splat de `Connect-PnPOnline`.
- Ejecuta `Connect-PnPOnline @connectParams -ReturnConnection -ErrorAction Stop` mediante splatting incluido en el helper.
- Retorna el objeto de conexión PnP producido por `Connect-PnPOnline -ReturnConnection`.
- No usa `-PersistLogin`, `-Credentials`, `-ClientSecret`, `-CertificatePath`, `-AccessToken`, `-EnvironmentVariable` ni prompts propios de contraseña.
- Ante error, traduce con `ConvertTo-SharePointUnifiedAuthError` y lanza mensaje claro.
- No se mantiene alias ni wrapper público `Connect-SharePointUnifiedAuth` salvo aprobación funcional posterior; el alcance aprobado exige que el comando público principal sea `Connect-Spo`.

### `Resolve-SharePointUnifiedClientId`

Función pública auxiliar para adopción y tests.

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

Comportamiento:

- Si `ClientId` no está vacío, retorna su valor recortado.
- Si falta `ClientId`, busca en orden `ENTRAID_CLIENT_ID`, luego `ENTRAID_APP_ID`.
- Si encuentra valor no vacío, retorna ese valor recortado.
- Si no encuentra valor, lanza: `No se puede iniciar autenticación: falta o es inválido uno de los datos requeridos: SiteUrl, TenantId o ClientId.`
- No lee `AZURE_CLIENT_ID` para evitar ambigüedad con flujos `-EnvironmentVariable` no interactivos documentados por PnP.PowerShell.

### `Test-SharePointUnifiedAuthDependency`

Función pública auxiliar de diagnóstico.

```powershell
function Test-SharePointUnifiedAuthDependency {
    [CmdletBinding()]
    param()
}
```

Comportamiento:

- Verifica que exista `Connect-PnPOnline` con `Get-Command -Name 'Connect-PnPOnline' -ErrorAction SilentlyContinue`.
- Si no existe, lanza mensaje accionable: `No se encontró PnP.PowerShell. Instálalo con: Install-Module PnP.PowerShell -Scope CurrentUser`.
- No instala dependencias automáticamente.

## Helpers Internos

Los helpers internos no requieren ayuda pública, pero sí `CmdletBinding()` cuando reciban parámetros.

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

Retorna un `hashtable` para splatting con claves:

- Siempre: `Url`, `ClientId`, `ReturnConnection`, `ErrorAction`.
- `Interactive`: agrega `Interactive = $true` y `Tenant = $TenantId` si PnP lo acepta en la versión instalada; si no, omite `Tenant` para no romper el parameter set oficial. La implementación debe decidirlo por introspección de `Connect-PnPOnline` o mantener `Tenant` solo para `DeviceCode`.
- `DeviceCode`: agrega `DeviceLogin = $true` y `Tenant = $TenantId`.

Nota: aunque `TenantId` es requerido por la historia, PnP.PowerShell no requiere `-Tenant` en el parameter set `Interactive` documentado; el valor se valida como dato funcional común, pero solo se envía cuando el parameter set lo permite.

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

Retorna un string de error normalizado según patrones del mensaje original:

- Cancelación: `Autenticación cancelada por el usuario. No se continuará con la operación de SharePoint.`
- Permisos/configuración/autorización: `Autenticación completada, pero la cuenta o la aplicación no tiene permisos suficientes para el sitio u operación solicitada.`
- Configuración incompleta: `No se puede iniciar autenticación: falta o es inválido uno de los datos requeridos: SiteUrl, TenantId o ClientId.`
- Fallback: `No se pudo completar la autenticación de SharePoint mediante modo <AuthMode>. <mensaje original>`.

Patrones mínimos a reconocer, sin depender de tipos internos no públicos:

- Cancelación: `cancel`, `canceled`, `cancelled`, `A task was canceled`, `user canceled`.
- Permisos/autorización: `Access denied`, `Unauthorized`, `Forbidden`, `insufficient privileges`, `AADSTS`, `does not have access`, `permission`.

## Boundaries de Alcance

Incluido:

- Crear `src/Connect-Spo.ps1`.
- Crear tests unitarios/mocking en `tests/Connect-Spo.Tests.ps1`.
- Trasladar la carpeta de trabajo vigente desde `tools/sharepoint-auth-unified` hacia `tools/Connect-Spo`.
- Alinear el script principal del tool con la convención del repositorio como `tools/Connect-Spo/src/Connect-Spo.ps1`, sin modificar comportamiento funcional.
- Exponer `Connect-Spo` como función pública principal de autenticación SharePoint unificada.
- Implementar `Interactive` y permitir `DeviceCode` como opción disponible.
- Resolver `ClientId` desde parámetro, `ENTRAID_CLIENT_ID` o `ENTRAID_APP_ID`.
- Devolver conexión PnP para que futuras tools operen con `-Connection` o contexto equivalente.

Excluido:

- No modificar `tools/Get-SpoListNames`.
- No crear ni modificar `modules/`.
- No crear App Registrations ni consentimientos.
- No definir permisos exactos por tool adoptante.
- No implementar autenticación con contraseña, secreto de cliente, certificado, managed identity, `-EnvironmentVariable` de PnP, token externo ni almacenamiento persistente.
- No agregar documentación de usuario final fuera de lo mínimo necesario en comentarios de ayuda; documentación formal queda para la etapa de Documentación.
- No agregar alias de compatibilidad, wrappers secundarios ni comandos adicionales durante este rename.
- No cambiar nombres de funciones auxiliares, parámetros, modos de autenticación, mensajes funcionales ni dependencias como parte del traslado de carpeta.

## TODOs Atómicos Verificables

- [x] 1. Crear carpeta `tools/sharepoint-auth-unified/src/` si no existe.
- [x] 2. Crear carpeta `tools/sharepoint-auth-unified/tests/` si no existe.
- [x] 3. Crear `src/Connect-Spo.ps1` con bloque de Control de Cambios PowerShell fechado `2026-06-13`.
- [x] 4. Definir `Connect-Spo` con firma exacta, `CmdletBinding()`, validación y ayuda basada en comentarios.
- [x] 5. Definir `Resolve-SharePointUnifiedClientId` con firma exacta, orden de resolución `ClientId` -> `ENTRAID_CLIENT_ID` -> `ENTRAID_APP_ID` y error funcional aprobado.
- [x] 6. Definir `Test-SharePointUnifiedAuthDependency` con firma exacta y mensaje accionable si falta PnP.PowerShell.
- [x] 7. Definir helper interno `New-SharePointUnifiedConnectParameters` con firma exacta y mapeo `Interactive`/`DeviceCode`.
- [x] 8. Definir helper interno `ConvertTo-SharePointUnifiedAuthError` con firma exacta y clasificación de mensajes mínimos.
- [x] 9. Implementar llamada a `Connect-PnPOnline` exclusivamente con splatting generado, `-ReturnConnection` y `-ErrorAction Stop`.
- [x] 10. Verificar que ninguna ruta de código use `Read-Host`, `Get-Credential`, `-Credentials`, `-ClientSecret`, `-CertificatePath`, `-AccessToken`, `-EnvironmentVariable` ni `-PersistLogin`.
- [x] 11. Crear `tests/Connect-Spo.Tests.ps1` con dot-sourcing del script y mocks de `Connect-PnPOnline`/`Get-Command`.
- [x] 12. Agregar tests para resolución de `ClientId` directo, `ENTRAID_CLIENT_ID`, `ENTRAID_APP_ID` y ausencia total.
- [x] 13. Agregar tests para validación de `SiteUrl`, `TenantId` y `AuthMode`.
- [x] 14. Agregar tests para que `Interactive` invoque `Connect-PnPOnline` con `Interactive`, `ClientId`, `Url`, `ReturnConnection`, sin `PersistLogin`.
- [x] 15. Agregar tests para que `DeviceCode` invoque `Connect-PnPOnline` con `DeviceLogin`, `Tenant`, `ClientId`, `Url`, `ReturnConnection`.
- [x] 16. Agregar tests para normalización de cancelación, permisos/autorización y fallback general.
- [x] 17. Ejecutar Pester desde `tools/sharepoint-auth-unified` y corregir fallas dentro del alcance.
- [x] 18. Ejecutar ScriptAnalyzer sobre `src` y corregir hallazgos dentro del alcance.
- [x] 19. Ejecutar smoke test de carga del script sin autenticación real.
- [x] 20. Crear retro de implementación solo en etapa de Implementación, no durante Planning.

## TODOs Atómicos de Refactor por Rename `Connect-Spo`

Estos TODOs reemplazan únicamente el nombre de la API pública principal según specs funcionales aprobados; no autorizan funcionalidades nuevas.

- [x] 21. Actualizar `src/Connect-Spo.ps1` para renombrar la función pública principal de `Connect-SharePointUnifiedAuth` a `Connect-Spo` manteniendo intactos parámetros, validaciones y comportamiento.
- [x] 22. Actualizar la ayuda basada en comentarios de la función principal para que `.SYNOPSIS`, ejemplos y referencias usen `Connect-Spo`.
- [x] 23. Verificar que `Connect-SharePointUnifiedAuth` no quede expuesto como función pública, alias ni wrapper en el script, salvo que una historia futura lo apruebe explícitamente.
- [x] 24. Mantener sin cambios los helpers `Resolve-SharePointUnifiedClientId`, `Test-SharePointUnifiedAuthDependency`, `New-SharePointUnifiedConnectParameters` y `ConvertTo-SharePointUnifiedAuthError`, salvo ajustes de referencias internas estrictamente necesarios por el rename.
- [x] 25. Actualizar `tests/Connect-Spo.Tests.ps1` para invocar y validar `Connect-Spo` en todos los casos donde antes se usaba `Connect-SharePointUnifiedAuth`.
- [x] 26. Agregar o actualizar test que verifique que `Get-Command Connect-Spo` resuelve la función tras dot-sourcear el script.
- [x] 27. Agregar o actualizar test que verifique que `Connect-SharePointUnifiedAuth` no queda disponible como comando público tras dot-sourcear el script.
- [x] 28. Actualizar los mensajes descriptivos/nombres de contextos de tests para reflejar `Connect-Spo` sin cambiar expectativas funcionales.
- [x] 29. Actualizar documentación de usuario relacionada con esta historia, si ya existe en `tools/Connect-Spo/docs/`, para reemplazar referencias al comando anterior por `Connect-Spo`.
- [x] 30. Actualizar retro/test/review posteriores de esta nueva implementación solo en sus etapas correspondientes; no modificar artefactos históricos ya cerrados salvo que el agente de etapa lo requiera explícitamente.
- [x] 31. Ejecutar Pester desde `tools/sharepoint-auth-unified` y corregir fallas causadas por el rename dentro de este alcance.
- [x] 32. Ejecutar ScriptAnalyzer sobre `src` y corregir hallazgos causados por el rename dentro de este alcance.
- [x] 33. Ejecutar smoke test de carga del script verificando `Connect-Spo` y helpers públicos aprobados.

## TODOs Atómicos de Refactor por Ubicación `tools/Connect-Spo`

Estos TODOs aplican exclusivamente el cambio aprobado de ubicación/nombre del tool. No autorizan funcionalidades nuevas ni cambios de comportamiento de autenticación.

- [x] 34. Verificar que la carpeta origen `tools/sharepoint-auth-unified/` existe antes de moverla.
- [x] 35. Verificar que no exista una carpeta destino conflictiva `tools/Connect-Spo/` o, si existe, detener la implementación y solicitar decisión antes de sobrescribir o fusionar.
- [x] 36. Mover la carpeta completa `tools/sharepoint-auth-unified/` a `tools/Connect-Spo/`, preservando `plan/`, `src/`, `tests/` y `docs/` si existe.
- [x] 37. Renombrar el script principal a `tools/Connect-Spo/src/Connect-Spo.ps1`, manteniendo intacto el contenido funcional salvo referencias de ruta/nombre estrictamente necesarias.
- [x] 38. Actualizar tests en `tools/Connect-Spo/tests/Connect-Spo.Tests.ps1` para dot-sourcear `../src/Connect-Spo.ps1` o la ruta equivalente correcta desde la nueva carpeta.
- [x] 39. Actualizar referencias de rutas en los artefactos Markdown movidos bajo `tools/Connect-Spo/plan/` para que apunten a `tools/Connect-Spo` como ubicación vigente.
- [x] 40. Actualizar referencias de rutas en documentación de usuario bajo `tools/Connect-Spo/docs/`, si existe, reemplazando `tools/sharepoint-auth-unified` y `SharePointAuthUnified.ps1` por `tools/Connect-Spo` y `Connect-Spo.ps1` cuando corresponda.
- [x] 41. Confirmar que no queden referencias vigentes a `tools/sharepoint-auth-unified` en los artefactos del tool movido, salvo menciones históricas explícitas de Control de Cambios o notas de transición.
- [x] 42. Confirmar que la carpeta antigua `tools/sharepoint-auth-unified/` no queda como ubicación vigente después del movimiento.
- [x] 43. Confirmar que no se modificaron parámetros, helpers, mensajes funcionales, dependencias ni comportamiento de `Connect-Spo` durante el traslado.
- [x] 44. Ejecutar Pester desde `tools/Connect-Spo` con `Invoke-Pester -Path tests -Output Detailed`.
- [x] 45. Ejecutar ScriptAnalyzer desde `tools/Connect-Spo` con `Invoke-ScriptAnalyzer -Path src -Recurse`.
- [x] 46. Ejecutar smoke test desde `tools/Connect-Spo` cargando `./src/Connect-Spo.ps1` y verificando `Connect-Spo`, `Resolve-SharePointUnifiedClientId` y `Test-SharePointUnifiedAuthDependency`.
- [x] 47. Registrar retro de implementación de este refactor en el `plan/` ya movido a `tools/Connect-Spo/plan/`, durante la etapa de Implementación.

## Tests Previstos

Archivo objetivo: `tools/Connect-Spo/tests/SharePointAuthUnified.Tests.ps1`

Casos mínimos:

- `Resolve-SharePointUnifiedClientId` retorna el parámetro directo con precedencia sobre ambiente.
- `Resolve-SharePointUnifiedClientId` retorna `ENTRAID_CLIENT_ID` cuando no hay parámetro.
- `Resolve-SharePointUnifiedClientId` retorna `ENTRAID_APP_ID` cuando no hay parámetro ni `ENTRAID_CLIENT_ID`.
- `Resolve-SharePointUnifiedClientId` lanza mensaje aprobado cuando no hay `ClientId`.
- `Connect-Spo` falla antes de conectar si falta `Connect-PnPOnline`.
- `Connect-Spo -AuthMode Interactive` llama a `Connect-PnPOnline` con parámetros esperados y retorna la conexión mockeada.
- `Connect-Spo -AuthMode DeviceCode` llama a `Connect-PnPOnline` con `DeviceLogin` y `Tenant`.
- `Connect-Spo` no pasa parámetros prohibidos (`PersistLogin`, `Credentials`, `ClientSecret`, `CertificatePath`, `AccessToken`, `EnvironmentVariable`).
- `Get-Command Connect-Spo` resuelve la función pública principal tras dot-sourcear el script.
- `Get-Command Connect-SharePointUnifiedAuth` no resuelve ningún comando público definido por esta capacidad tras el rename.
- `ConvertTo-SharePointUnifiedAuthError` normaliza cancelación del usuario.
- `ConvertTo-SharePointUnifiedAuthError` normaliza permisos/autorización.
- `ConvertTo-SharePointUnifiedAuthError` conserva contexto en error general.

## Iteracion 2026-06-18: Modo Quiet por Defecto

### Alcance Tecnico

El refinamiento funcional aprobado exige que `Connect-Spo` opere en modo Quiet por defecto. La implementacion debe:

1. Mantener la salida funcional aprobada: objeto de conexion PnP.
2. Mantener errores accionables y salidas necesarias para la interaccion de autenticacion.
3. No emitir mensajes auxiliares de estado, progreso o diagnostico por salida host/information/output.
4. Emitir mensajes auxiliares solo mediante `Write-Verbose`, visibles cuando el operador use `-Verbose`.
5. Aplicar el mismo comportamiento al modulo reusable `modules/Connect-Spo/Connect-Spo.psm1`.

### Mensajes Verbose Planificados

- Reutilizacion de conexion activa valida.
- Inicio de autenticacion explicita mediante `Connect-PnPOnline`.
- Registro de contexto SharePoint activo tras autenticacion exitosa.

### TODOs Quiet/Verbose

- [x] 48. Agregar linea de Control de Cambios PowerShell para modo Quiet/Verbose.
- [x] 49. Agregar `Write-Verbose` en reutilizacion de conexion activa valida.
- [x] 50. Agregar `Write-Verbose` antes de invocar autenticacion explicita.
- [x] 51. Agregar `Write-Verbose` despues de registrar contexto activo.
- [x] 52. Agregar prueba que confirme que `Connect-Spo` sin `-Verbose` no emite registros verbose.
- [x] 53. Agregar prueba que confirme que `Connect-Spo -Verbose` emite mensajes auxiliares.
- [x] 54. Ejecutar Pester y ScriptAnalyzer.
- [x] 55. Sincronizar el modulo instalado globalmente tras aprobar pruebas.

## Comandos de Verificación

Ejecutar desde `tools/Connect-Spo` después del traslado:

```powershell
Invoke-Pester -Path tests -Output Detailed
Invoke-ScriptAnalyzer -Path src -Recurse
pwsh -NoProfile -Command ". ./src/Connect-Spo.ps1; Get-Command Connect-Spo, Resolve-SharePointUnifiedClientId, Test-SharePointUnifiedAuthDependency | Select-Object -ExpandProperty Name"
```

No se define smoke test que autentique contra SharePoint real porque requiere tenant, App Registration, consentimiento y credenciales interactivas fuera del alcance automatizable de esta historia.

## Riesgos y Mitigaciones

- Diferencias de parameter sets entre versiones de PnP.PowerShell: mitigar enviando `Tenant` solo donde el parameter set documentado lo requiere (`DeviceLogin`) o mediante introspección segura antes de enviarlo en `Interactive`.
- Clasificación de errores basada en texto: mantener patrones mínimos y fallback claro; no depender de excepciones internas no públicas.
- Persistencia involuntaria de tokens: no usar `-PersistLogin`; documentar que cualquier caché propia de la plataforma/PnP fuera de ese switch no es creada por esta capacidad.
- Variable `ClientId` ambigua: aceptar solo `ENTRAID_CLIENT_ID` y `ENTRAID_APP_ID`, alineadas con PnP para login interactivo, y excluir `AZURE_CLIENT_ID` en esta historia.
- Riesgo de compatibilidad por rename: no mantener compatibilidad con `Connect-SharePointUnifiedAuth` en esta historia porque el refinamiento aprobado define `Connect-Spo` como API pública principal; cualquier alias de transición requiere historia o aprobación explícita posterior.
- Riesgo de referencias obsoletas por traslado: mitigar buscando referencias a `tools/sharepoint-auth-unified`, `SharePointAuthUnified.ps1` y rutas antiguas dentro del tool movido antes de cerrar implementación.

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-13 | Planning Agent | Creación inicial del dev spec técnico para autenticación interactiva unificada SharePoint. |
| 0.2.0 | 2026-06-13 | Planning Agent | Cambia estado a APROBADO por aprobación explícita del usuario. |
| 0.3.0 | 2026-06-13 | Implementation Agent | Implementa la historia, marca TODOs completados y deja el dev spec en EN_REVISION para Testing. |
| 0.4.0 | 2026-06-13 | Implementation Agent | Registra verificaciones completadas con Pester, ScriptAnalyzer y smoke test de carga. |
| 0.5.0 | 2026-06-13 | Implementation Agent | Actualiza el plan aprobado para el rename de la API pública principal a Connect-Spo. |
| 0.6.0 | 2026-06-13 | Implementation Agent | Corrige el estado de los TODOs 21-33 tras el rename aprobado, dejando constancia de su cumplimiento. |
| 0.5.0 | 2026-06-13 | Planning Agent | Actualiza dev spec por refinamiento funcional aprobado para renombrar la API pública principal a `Connect-Spo`; deja el documento en BORRADOR para aprobación explícita antes de implementar el refactor. |
| 0.6.0 | 2026-06-13 | Planning Agent | Cambia estado a APROBADO por aprobación explícita del usuario del dev spec actualizado para renombrar la API pública principal a `Connect-Spo`. |
| 0.7.0 | 2026-06-13 | Planning Agent | Actualiza dev spec por refinamiento funcional aprobado para trasladar el tool a `tools/Connect-Spo`; deja el documento en BORRADOR para aprobación explícita antes de implementar el refactor de ubicación. |
| 0.8.0 | 2026-06-13 | Planning Agent | Cambia estado a APROBADO por aprobación explícita del usuario del dev spec actualizado para mover el tool a `tools/Connect-Spo`. |
| 0.9.0 | 2026-06-13 | Implementation Agent | Implementa el traslado de ubicación a `tools/Connect-Spo`, renombra script/tests y deja el dev spec en EN_REVISION para Testing. |
| 1.0.0 | 2026-06-18 | Planning Agent | Aprueba plan tecnico para modo Quiet por defecto y mensajes auxiliares via `-Verbose`. |
| 1.1.0 | 2026-06-18 | Dev Agent | Implementa modo Quiet/Verbose, completa TODOs y deja el dev spec en EN_REVISION para Testing. |
