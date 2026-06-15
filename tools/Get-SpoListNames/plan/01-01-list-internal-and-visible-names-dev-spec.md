# Dev Spec: Listar nombres internos y visibles de listas del sitio

**Estado:** EN_REVISION

**Desarrollo:** `tools/Get-SpoListNames`
**Producto:** `00-spo-list-names-spec.md`
**Epica:** `01-site-list-discovery-spec.md`
**Historia:** `01-01-list-internal-and-visible-names-spec.md`
**Basado en story spec version:** 0.3.0
**Fecha:** 2026-06-12

---

## Plan de Investigacion

### Recursos Consultados

| Recurso | URL / Referencia | Relevancia | Hallazgo Principal |
|---------|------------------|------------|--------------------|
| Connect-PnPOnline | https://pnp.github.io/powershell/cmdlets/Connect-PnPOnline.html | Alta | PnP.PowerShell ofrece conexion soportada a SharePoint Online con `-Interactive`, `-DeviceLogin` y `-ValidateConnection`. |
| Get-PnPList | https://pnp.github.io/powershell/cmdlets/Get-PnPList.html | Alta | Devuelve las listas del web actual y permite pedir propiedades extra con `-Includes`. |
| Microsoft Graph: Get lists in a site | https://learn.microsoft.com/en-us/graph/api/list-list?view=graph-rest-1.0 | Media | Graph puede listar listas del sitio, pero su contrato expuesto no resuelve de forma tan directa el `EntityTypeName` requerido por la historia. |
| ListTemplateType enumeration | https://learn.microsoft.com/en-us/previous-versions/office/sharepoint-csom/ee541191(v=office.15) | Media | La documentacion distingue listas y bibliotecas por tipo/base, lo que justifica filtrar bibliotecas en la capa de seleccion. |

### Alternativas Evaluadas

| Alternativa | Pros | Contras | Decision |
|-------------|------|---------|----------|
| `PnP.PowerShell` con `Connect-PnPOnline` + `Get-PnPList` | Enfoque nativo para SPO en PowerShell, enumeracion simple del sitio actual, acceso directo a propiedades de lista y autenticacion moderna soportada. | Requiere tener instalado `PnP.PowerShell` y disponer de `ClientId` o variables de entorno equivalentes para login moderno. | Elegida |
| Microsoft Graph (`Get-MgSiteList` o REST `/sites/{site-id}/lists`) | API oficial amplia, soporta permisos delegados y application. | Requiere resolver `site-id`, manejar autenticacion Graph y no expone de forma tan directa el dato funcional elegido como nombre interno (`EntityTypeName`). | Descartada |
| SharePoint REST directo con `Invoke-RestMethod` | Sin dependencia funcional de PnP si ya existe token valido. | Aumenta mucho la complejidad de autenticacion, manejo de tokens y composicion de requests para una historia acotada. | Descartada |

### Dependencias Seleccionadas

```text
PnP.PowerShell >= 2.0.0   # conexion a SharePoint Online y enumeracion de listas del sitio
```

---

## Arquitectura

### Alcance Tecnico de Esta Historia

Esta historia crea un script PowerShell que se conecta a un sitio de SharePoint Online, obtiene las listas del web actual, excluye bibliotecas y listas ocultas, y devuelve una salida tabular con dos columnas: `InternalName` y `VisibleTitle`. En esta historia, `InternalName` se mapeara desde `EntityTypeName`, segun lo aprobado en el story spec.

Queda fuera de esta historia:

- Soporte para multiples sitios en una sola ejecucion.
- Exportacion a archivos.
- Recuperacion de metadatos adicionales de listas.
- Soporte para otros modos de autenticacion mas alla de `Interactive` y `DeviceLogin`.

### Estructura Objetivo

```text
tools/Get-SpoListNames/
|- plan/                       # artefactos de proceso de la herramienta Get-SpoListNames
|- src/
|  `- Get-SpoListNames.ps1     # entrypoint principal y logica de consulta
`- tests/
   `- Get-SpoListNames.Tests.ps1
```

Los archivos de plan viven en `tools/Get-SpoListNames/plan/` junto con el resto de artefactos de la herramienta.

### Flujo

```text
[SiteUrl + auth params]
    -> [Validar parametros y resolver ClientId]
    -> [Connect-PnPOnline -ValidateConnection]
    -> [Get-PnPList -Includes EntityTypeName, Title, Hidden, BaseType]
    -> [Excluir Hidden y BaseType DocumentLibrary]
    -> [Mapear a InternalName + VisibleTitle]
    -> [Ordenar salida]
    -> [Emitir objetos]
```

### API Publica

```powershell
function Get-SpoListNames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
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

Comportamiento previsto:

- `SiteUrl`: URL absoluta del sitio SharePoint Online a consultar.
- `AuthMode`: define si la conexion usa `Connect-PnPOnline -Interactive` o `-DeviceLogin`.
- `ClientId`: opcional si existe `ENTRAID_APP_ID` o `ENTRAID_CLIENT_ID`; obligatorio si no hay variable de entorno disponible.
- `TenantId`: opcional en `Interactive`; requerido para `DeviceLogin` si no existe `AZURE_TENANT_ID`.
- Salida: secuencia de `PSCustomObject` con propiedades `InternalName` y `VisibleTitle`.

---

## Plan de Implementacion

### TODO de Implementacion

- [x] `1.` Crear o migrar la estructura objetivo `tools/Get-SpoListNames/src/` y `tools/Get-SpoListNames/tests/` sin cambiar el alcance funcional aprobado.
- [x] `2.` Ubicar `tools/Get-SpoListNames/src/Get-SpoListNames.ps1` como entrypoint con parametros `SiteUrl`, `AuthMode`, `ClientId` y `TenantId`.
- [x] `3.` Asegurar que cualquier referencia operativa, ruta de ejecucion, smoke test o documentacion tecnica use `Get-SpoListNames` como nombre de herramienta/directorio cuando aplique.
- [x] `4.` Validar disponibilidad de `PnP.PowerShell` antes de conectar.
- [x] `5.` Resolver `ClientId` desde parametro o desde `ENTRAID_APP_ID` / `ENTRAID_CLIENT_ID`.
- [x] `6.` Conectar al sitio con `Connect-PnPOnline -ValidateConnection` usando el modo de autenticacion elegido.
- [x] `7.` Obtener listas con `Get-PnPList -Includes EntityTypeName, Title, Hidden, BaseType`.
- [x] `8.` Filtrar resultados para excluir:
  - [x] `8.1` listas ocultas (`Hidden`)
  - [x] `8.2` bibliotecas (`BaseType -eq 'DocumentLibrary'`)
- [x] `9.` Proyectar la salida a objetos con propiedades:
  - [x] `9.1` `InternalName` = `EntityTypeName`
  - [x] `9.2` `VisibleTitle` = `Title`
- [x] `10.` Ordenar la salida por `VisibleTitle` para mejorar legibilidad operativa.
- [x] `11.` Implementar manejo de errores claros para:
  - [x] `11.1` modulo faltante
  - [x] `11.2` `ClientId` no resuelto
  - [x] `11.3` fallo de conexion o sitio invalido
  - [x] `11.4` fallo al consultar listas
- [x] `12.` Escribir tests en `tools/Get-SpoListNames/tests/Get-SpoListNames.Tests.ps1`.
  - [x] `12.1` caso nominal con una lista visible no documental
  - [x] `12.2` exclusion de bibliotecas
  - [x] `12.3` exclusion de listas ocultas
  - [x] `12.4` error claro cuando falta `ClientId`
  - [x] `12.5` error claro cuando falla la conexion

### Orden de Implementacion

1. Preparar la estructura `tools/Get-SpoListNames` y asegurar que rutas/referencias tecnicas usen el nombre vigente.
2. Implementar el entrypoint y la resolucion de autenticacion.
3. Implementar consulta, filtrado y proyeccion de salida.
4. Cerrar con manejo de errores y tests con mocks de PnP.

---

## Estandares de Codigo

- Comando `Verb-Noun`: `Get-SpoListNames`.
- `CmdletBinding()` y validacion de parametros en el entrypoint.
- Ayuda basada en comentarios en el script principal.
- Sin comentarios redundantes; comentar solo decisiones no evidentes, como el mapeo de `EntityTypeName` a `InternalName`.
- Control de cambios al inicio del script y de cualquier archivo PowerShell adicional.

---

## Criterios de Aceptacion para Testing

- [x] Todos los criterios de `01-01-list-internal-and-visible-names-spec.md` verificados con tests o chequeo manual documentado.
- [x] Desde `tools/Get-SpoListNames`, `Invoke-Pester -Path tests -Output Detailed` pasa sin fallas.
- [x] Desde `tools/Get-SpoListNames`, `Invoke-ScriptAnalyzer -Path src -Recurse` no reporta errores bloqueantes.
- [x] Smoke test manual documentado con una invocacion equivalente a `pwsh -File ./src/Get-SpoListNames.ps1 -SiteUrl $env:SPO_SITE_URL -AuthMode Interactive -ClientId $env:ENTRAID_APP_ID`.

---

## Notas de Implementacion

- La historia requiere `EntityTypeName` como nombre interno, aunque ese no sea el nombre visible ni la URL de la lista.
- Se usara `-ValidateConnection` al conectar para que el error de sitio invalido o inaccesible ocurra en el boundary de conexion y no mas tarde.
- La implementacion debe preferir un solo archivo de script salvo que aparezca una necesidad real de separar helpers por legibilidad o testabilidad.
- Los tests deben mockear `Connect-PnPOnline` y `Get-PnPList`; no deben depender de un tenant real para el flujo automatizado.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-12 | Planning Agent | Dev spec inicial de historia con plan de investigacion |
| 0.2.0 | 2026-06-12 | Dev Agent | Usuario aprueba el dev spec, se implementa la historia y se marcan los TODOs completados |
| 0.3.0 | 2026-06-12 | Planning Agent | Reabre el dev spec en BORRADOR para reflejar `tools/Get-SpoListNames` como estructura objetivo; mantiene alcance funcional sin cambios |
| 0.4.0 | 2026-06-12 | Dev Agent | Registra aprobacion explicita del usuario y consolida la migracion estructural a `tools/Get-SpoListNames` |
| 0.5.0 | 2026-06-12 | Dev Agent | Deja el dev spec en EN_REVISION para handoff a Testing tras la migracion estructural |
| 0.6.0 | 2026-06-12 | Dev Agent | Sincroniza TODOs y criterios de testing con el estado real de implementacion y verificacion |
| 0.7.0 | 2026-06-12 | Dev Agent | Sincroniza el contrato publico con `TenantId` ya implementado y expone la ayuda a nivel de script |
