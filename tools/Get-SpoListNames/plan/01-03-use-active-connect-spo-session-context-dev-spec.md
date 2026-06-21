# Usar Contexto SharePoint Activo de Connect-Spo - Dev Spec

**Estado:** EN_REVISION

**Desarrollo:** `tools/Get-SpoListNames` y `modules/Get-SpoListNames`
**Producto:** `00-spo-list-names-spec.md`
**Epica:** `01-site-list-discovery-spec.md`
**Historia:** `01-03-use-active-connect-spo-session-context-spec.md`
**Basado en story spec version:** 0.1.0
**Fecha:** 2026-06-15

---

## Verificacion de Estado

La historia objetivo `tools/Get-SpoListNames/plan/01-03-use-active-connect-spo-session-context-spec.md` declara `**Estado:** APROBADO`. El producto `00-spo-list-names-spec.md` y la epica `01-site-list-discovery-spec.md` tambien declaran `APROBADO`.

Precondicion funcional: `tools/Connect-Spo/plan/01-03-register-active-sharepoint-session-context-spec.md` esta `APROBADO` y define el contexto activo que esta historia consume. La implementacion tecnica de `Get-SpoListNames` debe coordinarse con la implementacion de esa historia.

Este dev spec queda en `BORRADOR` hasta aprobacion explicita del usuario. No se debe implementar codigo antes de esa aprobacion.

---

## Alcance Tecnico de Esta Historia

Modificar `Get-SpoListNames` para que pueda ejecutarse sin parametros de conexion cuando exista un contexto SharePoint activo registrado por `Connect-Spo`.

Incluido:

- Hacer que `SiteUrl` deje de ser obligatorio en la funcion publica.
- Resolver contexto activo desde `$global:PSLibSpoConnectionContext`.
- Usar la conexion PnP del contexto activo al consultar listas cuando no se entreguen parametros de conexion.
- Mantener el comportamiento explicito existente cuando el operador entrega `SiteUrl`, `TenantId`, `ClientId` y `AuthMode`.
- Agregar pruebas para ejecucion sin parametros, ausencia de contexto y precedencia de invocacion explicita.

Fuera de alcance:

- Persistir contexto entre sesiones.
- Soportar multiples contextos o seleccion por nombre.
- Cambiar salida funcional de `GUID`, `EntityTypeName` y `Title`.
- Incluir bibliotecas de documentos.
- Modificar otras tools adoptantes.
- Cambios bajo `mcp/`.

---

## Dependencias Seleccionadas

| Dependencia | Tipo | Uso | Justificacion |
|-------------|------|-----|---------------|
| `Connect-Spo` | Runtime | Provee autenticacion explicita y registra contexto activo. | Dependencia aprobada de la tool. |
| `$global:PSLibSpoConnectionContext` | Runtime | Fuente de contexto activo cuando no hay parametros. | Definida por la historia 01-03 de `Connect-Spo`. |
| `PnP.PowerShell` | Runtime transitiva | `Get-PnPList -Connection` consulta listas usando conexion activa. | Ya se usa para la consulta SharePoint. |
| `Pester` | Test | Validar resolucion de contexto y comportamiento con mocks. | Herramienta vigente del repo. |
| `PSScriptAnalyzer` | Verificacion | Analisis estatico. | Herramienta vigente del repo. |

---

## Decision Tecnica

`Get-SpoListNames` usara el contexto activo solo cuando no se entregue `SiteUrl`.

Razon:

- Evita mezclar un `SiteUrl` explicito con una conexion activa de otro sitio.
- Mantiene el comportamiento explicito existente para invocaciones con parametros.
- Permite el caso aprobado: ejecutar `Get-SpoListNames` sin parametros despues de `Connect-Spo`.

Regla de resolucion:

1. Si `SiteUrl` viene informado, usar el flujo explicito actual: resolver `ClientId`, resolver `TenantId`, llamar `Connect-Spo`, consultar con la conexion devuelta.
2. Si `SiteUrl` esta omitido, intentar resolver `$global:PSLibSpoConnectionContext`.
3. Si el contexto existe y tiene `Connection` y `SiteUrl`, consultar listas con esa conexion.
4. Si no existe contexto valido, lanzar: `No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.`

---

## API Publica Afectada

La firma publica cambia solo para permitir omitir `SiteUrl`:

```powershell
function Get-SpoListNames {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^https://')]
        [string]$SiteUrl,

        [Parameter()]
        [ValidateSet('Interactive', 'DeviceLogin')]
        [string]$AuthMode = 'Interactive',

        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [string]$TenantId
    )
}
```

Contrato preservado:

- Invocaciones con `SiteUrl` explicito siguen autenticando mediante `Connect-Spo`.
- La salida sigue siendo `GUID`, `EntityTypeName` y `Title`.
- Se siguen excluyendo listas ocultas y bibliotecas de documentos.

Contrato nuevo:

- `Get-SpoListNames` sin parametros usa el contexto activo de sesion si existe.
- Si no existe contexto activo ni `SiteUrl`, falla antes de llamar `Connect-Spo` o `Get-PnPList`.

---

## Helpers Internos

### `Get-GetSpoListNamesActiveContext`

```powershell
function Get-GetSpoListNamesActiveContext {
    [OutputType([object])]
    [CmdletBinding()]
    param()
}
```

Boundary:

- Lee `$global:PSLibSpoConnectionContext` si existe.
- Valida que tenga `Connection` y `SiteUrl`.
- Devuelve el contexto si es usable.
- Devuelve `$null` si no existe o es invalido.
- No crea ni modifica contexto.

### `Resolve-GetSpoListNamesExecutionContext`

```powershell
function Resolve-GetSpoListNamesExecutionContext {
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$SiteUrl,

        [Parameter()]
        [string]$TenantId,

        [Parameter()]
        [string]$ClientId,

        [Parameter(Mandatory)]
        [ValidateSet('Interactive', 'DeviceLogin')]
        [string]$AuthMode
    )
}
```

Boundary:

- Si `SiteUrl` existe, ejecuta el flujo explicito actual y devuelve objeto con `Connection` y `SiteUrl`.
- Si `SiteUrl` no existe, usa `Get-GetSpoListNamesActiveContext`.
- Si no puede resolver contexto, lanza el mensaje minimo aprobado.

### `Invoke-GetSpoListNamesAuthentication`

Mantiene la firma actual para flujo explicito, pero solo se invoca cuando `SiteUrl` viene informado.

---

## Flujo Tecnico Esperado

1. `Get-SpoListNames` recibe parametros.
2. Llama `Resolve-GetSpoListNamesExecutionContext`.
3. Si hay `SiteUrl` explicito:
   - Resuelve `ClientId`.
   - Resuelve `TenantId`.
   - Importa `Connect-Spo`.
   - Llama `Connect-Spo`.
   - Usa la conexion devuelta.
4. Si no hay `SiteUrl`:
   - Lee contexto activo global.
   - Usa `Connection` y `SiteUrl` del contexto.
5. Ejecuta `Get-PnPList -Connection $connection -Includes 'Id', 'EntityTypeName', 'Title', 'Hidden', 'BaseType' -ErrorAction Stop`.
6. Filtra ocultas y bibliotecas documentales.
7. Ordena por `Title`.
8. Proyecta `GUID`, `EntityTypeName`, `Title`.

---

## Tests Previstos

Actualizar:

- `tools/Get-SpoListNames/tests/Get-SpoListNames.Tests.ps1`
- `tools/Get-SpoListNames/tests/Get-SpoListNames.Module.Tests.ps1`

Casos minimos:

- Sin parametros y con `$global:PSLibSpoConnectionContext` valido, consulta listas usando `Connection` del contexto.
- Sin parametros y con contexto valido, usa `SiteUrl` del contexto en mensajes de error de consulta.
- Sin parametros y sin contexto, lanza el mensaje minimo aprobado y no llama `Connect-Spo` ni `Get-PnPList`.
- Sin parametros y con contexto sin `Connection`, lanza el mensaje minimo aprobado.
- Sin parametros y con contexto sin `SiteUrl`, lanza el mensaje minimo aprobado.
- Con `SiteUrl` explicito, conserva flujo actual: llama `Connect-Spo` y usa la conexion devuelta.
- Con `SiteUrl` explicito, no usa una conexion global existente de otro sitio.
- La salida mantiene `GUID`, `EntityTypeName` y `Title`.
- El modulo sigue exportando solo `Get-SpoListNames`.
- El manifiesto sigue declarando `RequiredModules = @('Connect-Spo')`.

---

## Comandos de Verificacion

Desde `tools/Get-SpoListNames`:

```powershell
Invoke-Pester -Path tests -Output Detailed
Invoke-ScriptAnalyzer -Path src -Recurse
```

Desde la raiz del repo:

```powershell
Test-ModuleManifest -Path .\modules\Get-SpoListNames\Get-SpoListNames.psd1
Invoke-ScriptAnalyzer -Path .\modules\Get-SpoListNames -Recurse
```

No se define smoke test con autenticacion real porque requiere tenant, app registration, consentimiento y credenciales interactivas fuera del alcance automatizable.

---

## TODOs Atomicos Verificables

- [x] 1. Revisar y restaurar `$global:PSLibSpoConnectionContext` en pruebas.
- [x] 2. Cambiar `SiteUrl` de obligatorio a opcional en `tools/Get-SpoListNames/src/Get-SpoListNames.ps1`.
- [x] 3. Cambiar `SiteUrl` de obligatorio a opcional en `modules/Get-SpoListNames/Get-SpoListNames.psm1`.
- [x] 4. Agregar helper `Get-GetSpoListNamesActiveContext` en script y modulo.
- [x] 5. Agregar helper `Resolve-GetSpoListNamesExecutionContext` en script y modulo.
- [x] 6. Mantener `Invoke-GetSpoListNamesAuthentication` solo para flujo explicito con `SiteUrl`.
- [x] 7. Cambiar `Get-SpoListNames` para usar el contexto resuelto antes de llamar `Get-PnPList`.
- [x] 8. Agregar mensaje minimo aprobado para ausencia de contexto.
- [x] 9. Actualizar ayuda basada en comentarios con ejemplo `Connect-Spo` seguido de `Get-SpoListNames`.
- [x] 10. Actualizar pruebas de script para ejecucion sin parametros con contexto valido.
- [x] 11. Actualizar pruebas de modulo para ejecucion sin parametros con contexto valido.
- [x] 12. Agregar pruebas de ausencia de contexto y contexto invalido.
- [x] 13. Agregar pruebas de precedencia de `SiteUrl` explicito sobre contexto global.
- [x] 14. Mantener pruebas existentes de autenticacion explicita, filtros y salida.
- [x] 15. Ejecutar Pester y ScriptAnalyzer.
- [x] 16. Crear retro de implementacion `01-03-use-active-connect-spo-session-context-retro.md` durante Implementacion.

---

## Criterios de Aceptacion Tecnicos

- [ ] `Get-SpoListNames` sin parametros funciona con contexto global valido.
- [ ] `Get-SpoListNames` sin parametros falla claramente sin contexto valido.
- [ ] Invocaciones explicitas con `SiteUrl` conservan el flujo `Connect-Spo`.
- [ ] La salida funcional no cambia.
- [ ] Tests automatizados cubren contexto valido, contexto ausente, contexto invalido y precedencia explicita.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-15 | Planning Agent | Crea dev spec en BORRADOR para consumir contexto SharePoint activo desde `Get-SpoListNames`. |
| 0.2.0 | 2026-06-15 | Planning Agent | Cambia estado a APROBADO por aprobacion explicita del usuario. |
| 0.3.0 | 2026-06-15 | Dev Agent | Marca TODOs completados y deja el dev spec en EN_REVISION tras implementacion. |
