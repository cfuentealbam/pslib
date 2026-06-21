# Registrar Contexto SharePoint Activo de Sesion - Dev Spec

**Estado:** EN_REVISION

**Desarrollo:** `modules/Connect-Spo` y `tools/Connect-Spo`
**Producto:** `00-sharepoint-auth-unified-spec.md`
**Epica:** `01-interactive-sharepoint-auth-spec.md`
**Historia:** `01-03-register-active-sharepoint-session-context-spec.md`
**Basado en story spec version:** 0.2.0
**Fecha:** 2026-06-15

---

## Verificacion de Estado

La historia objetivo `tools/Connect-Spo/plan/01-03-register-active-sharepoint-session-context-spec.md` declara `**Estado:** APROBADO`. El producto `00-sharepoint-auth-unified-spec.md` y la epica `01-interactive-sharepoint-auth-spec.md` tambien declaran `APROBADO`.

Este dev spec queda en `BORRADOR` hasta aprobacion explicita del usuario. No se debe implementar codigo antes de esa aprobacion.

---

## Alcance Tecnico de Esta Historia

Modificar `Connect-Spo` para registrar un contexto SharePoint activo de sesion despues de una autenticacion exitosa, sin persistir secretos ni tokens en disco.

Incluido:

- Registrar la conexion PnP devuelta por `Connect-PnPOnline -ReturnConnection`.
- Registrar `SiteUrl`, `TenantId`, `ClientId` resuelto y `AuthMode`.
- Reutilizar el contexto activo si corresponde al mismo `SiteUrl` y `ClientId` y la conexion responde correctamente.
- Limitar el contexto a la sesion/runspace actual mediante una variable global de PowerShell con nombre estable.
- Actualizar script wrapper y modulo canonico solo en lo necesario para reflejar el nuevo comportamiento.
- Agregar pruebas unitarias con mocks que validen registro, reemplazo por conexion mas reciente y ausencia de registro ante error.

Fuera de alcance:

- Persistir perfiles o conexiones entre sesiones.
- Exportar nuevos comandos publicos.
- Cambiar modos de autenticacion aprobados.
- Modificar tools adoptantes como `Get-SpoListNames`; eso corresponde a su historia 01-03.
- Cambios bajo `mcp/`.

---

## Dependencias Seleccionadas

| Dependencia | Tipo | Uso | Justificacion |
|-------------|------|-----|---------------|
| `PnP.PowerShell` | Runtime | `Connect-PnPOnline -ReturnConnection` devuelve la conexion PnP a registrar; `Get-PnPWeb -Connection` valida que una conexion activa siga respondiendo. | Ya es dependencia runtime aprobada de `Connect-Spo`; `Get-PnPWeb` permite validar lectura liviana del web actual. |
| Variable global PowerShell | Runtime | Compartir contexto entre modulos importados en la misma sesion. | Permite que tools adoptantes lean el contexto sin nuevo comando publico ni persistencia en disco. |
| `Pester` | Test | Validar comportamiento con mocks. | Herramienta vigente de pruebas del repo. |
| `PSScriptAnalyzer` | Verificacion | Analisis estatico de PowerShell. | Herramienta vigente de calidad del repo. |

---

## Decision Tecnica

El contexto activo se almacenara en la variable global:

```powershell
$global:PSLibSpoConnectionContext
```

Valor esperado:

```powershell
[pscustomobject]@{
    Connection = $connection
    SiteUrl    = $SiteUrl
    TenantId   = $TenantId
    ClientId   = $resolvedClientId
    AuthMode   = $AuthMode
}
```

Razon:

- `Get-SpoListNames` vive en otro modulo y necesita resolver el contexto sin acceder al estado privado de `modules/Connect-Spo`.
- Una variable global de sesion cumple el requisito funcional de quedar disponible en la sesion actual.
- No agrega una API publica nueva ni cambia `FunctionsToExport`.
- No persiste valores en disco ni crea secretos.

Restricciones:

- Solo se asigna la variable despues de una autenticacion exitosa.
- Si `Connect-PnPOnline` falla o el usuario cancela, no se reemplaza el contexto activo existente.
- El objeto no debe incluir contrasenas, secretos, certificados ni tokens expuestos por esta implementacion.

---

## API Publica Afectada

La firma publica de `Connect-Spo` se mantiene:

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

Contrato preservado:

- Sigue devolviendo la conexion PnP obtenida.
- Sigue exportando solo `Connect-Spo`.
- Sigue resolviendo `ClientId` desde parametro o variables aprobadas.
- Sigue usando `Connect-PnPOnline -ReturnConnection`.

Contrato nuevo:

- Al autenticar correctamente, actualiza `$global:PSLibSpoConnectionContext`.

---

## Helpers Internos

### `Set-SharePointUnifiedSessionContext`

```powershell
function Set-SharePointUnifiedSessionContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object]$Connection,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^https://')]
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

Boundary:

- Crea un `[pscustomobject]` con las propiedades `Connection`, `SiteUrl`, `TenantId`, `ClientId`, `AuthMode`.
- Asigna el objeto a `$global:PSLibSpoConnectionContext`.
- Devuelve el contexto creado para facilitar pruebas internas.
- No se exporta.

### `Get-SharePointUnifiedActiveContext`

Lee `$global:PSLibSpoConnectionContext` y devuelve el contexto actual si existe.

### `ConvertTo-SharePointUnifiedNormalizedSiteUrl`

Normaliza URL de sitio con `Trim()`, remocion de `/` final y comparacion en minusculas.

### `Test-SharePointUnifiedReusableSessionContext`

Recibe `SiteUrl` y `ClientId` resuelto.

Reglas:

1. Retorna falso si no existe contexto global o faltan `Connection`, `SiteUrl` o `ClientId`.
2. Retorna falso si `SiteUrl` normalizado o `ClientId` no coinciden.
3. Ejecuta `Get-PnPWeb -Connection $context.Connection -Includes 'Url' -ErrorAction Stop`.
4. Retorna verdadero solo si la llamada responde y, cuando el web trae `Url`, coincide con el sitio solicitado.

---

## Flujo Tecnico Esperado

1. `Connect-Spo` valida dependencias.
2. Resuelve `ClientId`.
3. Si el contexto activo es reutilizable para el mismo sitio y app, devuelve la conexion existente sin llamar `Connect-PnPOnline`.
4. Construye parametros para `Connect-PnPOnline`.
5. Ejecuta `Connect-PnPOnline @connectParameters`.
6. Si la conexion se obtiene correctamente, llama `Set-SharePointUnifiedSessionContext`.
7. Devuelve la conexion PnP como antes.
8. Si ocurre error, normaliza el mensaje y no actualiza el contexto global.

---

## Tests Previstos

Actualizar `tools/Connect-Spo/tests/Connect-Spo.Module.Tests.ps1` y, si corresponde, `tools/Connect-Spo/tests/Connect-Spo.Tests.ps1`.

Casos minimos:

- `Connect-Spo` exitoso registra `$global:PSLibSpoConnectionContext`.
- El contexto contiene `Connection`, `SiteUrl`, `TenantId`, `ClientId` resuelto y `AuthMode`.
- Si `ClientId` viene con espacios, el contexto guarda el valor recortado.
- Si `ClientId` se resuelve desde variable de ambiente aprobada, el contexto guarda el valor resuelto.
- Dos autenticaciones exitosas reemplazan el contexto con la mas reciente.
- Si `Connect-PnPOnline` falla, no se reemplaza un contexto existente.
- Si existe contexto activo valido para el mismo sitio y app, no llama `Connect-PnPOnline`.
- Si la validacion de contexto activo falla, llama `Connect-PnPOnline` y reemplaza contexto tras exito.
- Si el sitio o app difieren, no intenta reutilizar el contexto activo.
- El modulo sigue exportando solamente `Connect-Spo`.
- No se escriben archivos ni variables de entorno persistentes como parte del registro de contexto.

---

## Comandos de Verificacion

Desde `tools/Connect-Spo`:

```powershell
Invoke-Pester -Path tests -Output Detailed
Invoke-ScriptAnalyzer -Path src -Recurse
```

Desde la raiz del repo:

```powershell
Test-ModuleManifest -Path .\modules\Connect-Spo\Connect-Spo.psd1
Invoke-ScriptAnalyzer -Path .\modules\Connect-Spo -Recurse
```

---

## TODOs Atomicos Verificables

- [x] 1. Revisar estado inicial de `$global:PSLibSpoConnectionContext` en pruebas y restaurarlo al finalizar cada test.
- [x] 2. Agregar helper interno `Set-SharePointUnifiedSessionContext` en `modules/Connect-Spo/Connect-Spo.psm1`.
- [x] 3. Modificar `Connect-Spo` para guardar la conexion devuelta por `Connect-PnPOnline` en una variable local.
- [x] 4. Llamar `Set-SharePointUnifiedSessionContext` solo despues de obtener conexion exitosa.
- [x] 5. Mantener el retorno publico de `Connect-Spo` como la conexion PnP.
- [x] 6. Confirmar que `Export-ModuleMember` sigue exportando solo `Connect-Spo`.
- [x] 7. Actualizar ayuda basada en comentarios para mencionar el contexto activo de sesion.
- [x] 8. Actualizar pruebas de modulo para validar contexto registrado en exito.
- [x] 9. Agregar pruebas de `ClientId` resuelto desde parametro y ambiente.
- [x] 10. Agregar prueba de reemplazo por autenticacion exitosa mas reciente.
- [x] 11. Agregar prueba de no reemplazo ante error de autenticacion.
- [x] 12. Ejecutar Pester y ScriptAnalyzer.
- [x] 13. Crear retro de implementacion `01-03-register-active-sharepoint-session-context-retro.md` durante Implementacion.
- [x] 14. Agregar helper para leer contexto activo.
- [x] 15. Agregar normalizacion de `SiteUrl`.
- [x] 16. Agregar validacion de conexion activa con `Get-PnPWeb -Connection`.
- [x] 17. Evitar `Connect-PnPOnline` cuando el contexto activo es valido para el mismo sitio y app.
- [x] 18. Agregar pruebas para reuso, contexto invalido, sitio distinto y app distinta.

---

## Criterios de Aceptacion Tecnicos

- [ ] `Connect-Spo` exitoso actualiza `$global:PSLibSpoConnectionContext`.
- [ ] El contexto incluye conexion PnP y datos no secretos requeridos.
- [ ] Fallos de autenticacion no registran un nuevo contexto exitoso.
- [ ] La API publica exportada no cambia.
- [ ] Tests automatizados cubren registro, reemplazo y fallo.
- [ ] Tests automatizados cubren reuso de conexion activa valida y fallback a login cuando no corresponde reutilizar.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-15 | Planning Agent | Crea dev spec en BORRADOR para registrar contexto SharePoint activo de sesion en `Connect-Spo`. |
| 0.2.0 | 2026-06-15 | Planning Agent | Cambia estado a APROBADO por aprobacion explicita del usuario. |
| 0.3.0 | 2026-06-15 | Dev Agent | Marca TODOs completados y deja el dev spec en EN_REVISION tras implementacion. |
| 0.4.0 | 2026-06-18 | Planning Agent | Actualiza diseno para reutilizar conexion activa valida para el mismo sitio y app. |
| 0.5.0 | 2026-06-18 | Dev Agent | Marca implementacion de reuso de conexion activa y pruebas asociadas. |
