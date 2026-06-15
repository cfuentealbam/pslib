# Consumir Autenticacion Unificada mediante Modulo Connect-Spo - Dev Spec

**Estado:** EN_REVISION

**Desarrollo:** `tools/Get-SpoListNames` y, si existe por la historia 02-01, `modules/Get-SpoListNames`
**Producto:** `00-spo-list-names-spec.md`
**Epica:** `01-site-list-discovery-spec.md`
**Historia:** `01-02-consume-connect-spo-module-for-authentication-spec.md`
**Basado en story spec version:** 0.2.0
**Fecha:** 2026-06-14

---

## Verificacion de Estado

La historia objetivo `tools/Get-SpoListNames/plan/01-02-consume-connect-spo-module-for-authentication-spec.md` declara `**Estado:** APROBADO`. El producto `00-spo-list-names-spec.md` y la epica `01-site-list-discovery-spec.md` tambien declaran `APROBADO`.

Se reviso ademas la historia de empaquetado `02-01-package-get-spo-list-names-as-module-spec.md`, que esta `APROBADO`, y su dev spec `02-01-package-get-spo-list-names-as-module-dev-spec.md`, que esta `EN_REVISION`. Por lo tanto, este dev spec debe ser compatible tanto con el script vigente como con el modulo futuro/aprobado, sin implementar empaquetado nuevo fuera de esta historia.

Precondicion externa: la historia de `Connect-Spo` `tools/Connect-Spo/plan/01-02-publish-connect-spo-as-reusable-powershell-module-spec.md` define que existira un modulo no compilado `modules/Connect-Spo`, importable por nombre como `Connect-Spo` cuando el directorio padre `modules/` este disponible en `PSModulePath`.

---

## Alcance Tecnico de Esta Historia

Modificar la autenticacion usada por `Get-SpoListNames` para consumir `Connect-Spo` como dependencia de modulo por nombre, sin rutas relativas a `tools/Connect-Spo`, antes de consultar listas con `Get-PnPList`.

Incluido:

- Importar/validar `Connect-Spo` por nombre de modulo (`Import-Module Connect-Spo`) y no por ruta relativa.
- Reemplazar la llamada directa actual a `Connect-PnPOnline` por una llamada a la API publica `Connect-Spo`.
- Mantener la consulta y salida aprobadas: listas no documentales visibles con `InternalName` y `VisibleTitle`.
- Si `Get-SpoListNames` esta empaquetado como modulo por la historia 02-01, declarar la dependencia `Connect-Spo` en el manifiesto y mantener validacion runtime accionable.
- Agregar/actualizar tests que prueben importacion por nombre, ausencia de rutas relativas y errores claros.

Fuera de alcance:

- Implementar o modificar `modules/Connect-Spo`.
- Publicar modulos en PowerShell Gallery o instalar automaticamente en `PSModulePath`.
- Cambiar campos de salida, incluir bibliotecas documentales o consultar otros metadatos.
- Crear funcionalidad nueva de autenticacion distinta a la API publica aprobada de `Connect-Spo`.
- Cambios bajo `mcp/`.

---

## Investigacion y Decisiones

### Dependencias Seleccionadas

| Dependencia | Tipo | Uso | Justificacion |
|-------------|------|-----|---------------|
| `Connect-Spo` | Runtime | Autenticacion SharePoint unificada por modulo importable por nombre. | Requerida por la historia 01-02; desacopla `Get-SpoListNames` de rutas internas de otro tool. |
| `PnP.PowerShell` | Runtime transitiva | `Get-PnPList` sigue siendo necesario para enumerar listas; `Connect-Spo` usa PnP para conectar. | Ya es la base funcional de la historia 01-01; esta historia no reemplaza la API de consulta de listas. |
| `Pester` | Test | Verificar importacion, mocks de `Connect-Spo` y comportamiento de errores. | Herramienta estandar de pruebas PowerShell en el repo; no es dependencia runtime. |
| `PSScriptAnalyzer` | Verificacion | Analisis estatico de script/modulo. | Herramienta estandar de calidad; no es dependencia runtime. |

### Decisiones Tecnicas

1. `Connect-Spo` se carga exclusivamente por nombre con `Import-Module -Name 'Connect-Spo' -ErrorAction Stop`.
2. No se permite construir rutas hacia `tools/Connect-Spo`, `modules/Connect-Spo` ni dot-sourcear archivos de esa tool desde `Get-SpoListNames`.
3. La funcion publica `Get-SpoListNames` conserva su firma actual para no cambiar el contrato operativo de listado; internamente traduce `AuthMode = 'DeviceLogin'` al modo `DeviceCode` esperado por `Connect-Spo`.
4. `Connect-Spo` debe retornar o establecer la conexion PnP necesaria antes de ejecutar `Get-PnPList`. `Get-SpoListNames` no debe llamar `Connect-PnPOnline` directamente.
5. Si la dependencia no se puede importar, se debe lanzar el mensaje minimo aprobado: `No se puede cargar la dependencia Connect-Spo. Instale o exponga el modulo Connect-Spo en PSModulePath y vuelva a ejecutar la operacion.`
6. Si existe el modulo `modules/Get-SpoListNames`, su manifiesto debe declarar `Connect-Spo` como dependencia de modulo. La validacion runtime se mantiene para ejecuciones como script y para errores de carga no cubiertos por el manifiesto.

---

## Estructura Objetivo

```text
pslib/
|- modules/
|  |- Connect-Spo/                       # precondicion externa de otra historia
|  `- Get-SpoListNames/                  # si existe/queda implementado por historia 02-01
|     |- Get-SpoListNames.psd1           # actualizar RequiredModules si existe
|     `- Get-SpoListNames.psm1           # usar Connect-Spo por nombre si existe
`- tools/
   `- Get-SpoListNames/
      |- plan/
      |  `- 01-02-consume-connect-spo-module-for-authentication-dev-spec.md
      |- src/
      |  `- Get-SpoListNames.ps1         # actualizar autenticacion vigente
      `- tests/
         |- Get-SpoListNames.Tests.ps1
         `- Get-SpoListNames.ConnectSpo.Tests.ps1
```

Notas:

- Este dev spec no crea por si mismo el modulo `modules/Get-SpoListNames`; solo define los cambios que deben aplicarse si ese modulo ya existe o se implementa por la historia 02-01.
- Los artefactos de proceso permanecen en `tools/Get-SpoListNames/plan/`.

---

## API Publica Afectada

La firma publica de `Get-SpoListNames` debe conservarse:

```powershell
function Get-SpoListNames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
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

- Entrada `SiteUrl`: URL HTTPS del sitio SharePoint.
- Entrada `AuthMode`: `Interactive` o `DeviceLogin` por compatibilidad con la historia 01-01.
- Entrada `ClientId`: opcional; puede resolverse desde variables de entorno para pasarlo a `Connect-Spo`.
- Entrada `TenantId`: necesario para satisfacer la API publica aprobada de `Connect-Spo`; puede resolverse desde `AZURE_TENANT_ID`.
- Salida: objetos con propiedades `InternalName` y `VisibleTitle`.

La ayuda basada en comentarios debe actualizarse para indicar que la autenticacion se delega al modulo `Connect-Spo` y que dicho modulo debe estar disponible por nombre en `PSModulePath`.

---

## Helpers Internos y Boundaries

Los helpers son internos; no deben exportarse desde `modules/Get-SpoListNames` ni exponerse como comandos publicos.

### `Import-GetSpoListNamesAuthenticationModule`

```powershell
function Import-GetSpoListNamesAuthenticationModule {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName = 'Connect-Spo'
    )
}
```

Boundary:

- Ejecuta `Import-Module -Name $ModuleName -ErrorAction Stop`.
- No acepta rutas ni calcula ubicaciones relativas.
- Verifica que `Get-Command -Name 'Connect-Spo' -Module 'Connect-Spo'` o equivalente resuelva la funcion publica.
- Si falla importacion o comando publico, lanza el mensaje minimo funcional aprobado.

### `Resolve-GetSpoListNamesClientId`

```powershell
function Resolve-GetSpoListNamesClientId {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [string[]]$EnvironmentVariableNames = @('ENTRAID_APP_ID', 'ENTRAID_CLIENT_ID', 'AZURE_CLIENT_ID')
    )
}
```

Boundary:

- Mantiene la precedencia vigente de la herramienta para no romper compatibilidad.
- Devuelve `string` o `$null`; el error final de obligatoriedad se centraliza antes de llamar a `Connect-Spo`.

### `Resolve-GetSpoListNamesTenantId`

```powershell
function Resolve-GetSpoListNamesTenantId {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$TenantId,

        [Parameter()]
        [string[]]$EnvironmentVariableNames = @('AZURE_TENANT_ID')
    )
}
```

Boundary:

- Devuelve el parametro si viene informado; si no, intenta `AZURE_TENANT_ID`.
- Si no resuelve valor y se requiere llamar a `Connect-Spo`, lanza error claro: `No se pudo resolver TenantId para Connect-Spo. Proporcionalo con -TenantId o define AZURE_TENANT_ID.`

### `ConvertTo-GetSpoListNamesConnectSpoAuthMode`

```powershell
function ConvertTo-GetSpoListNamesConnectSpoAuthMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Interactive', 'DeviceLogin')]
        [string]$AuthMode
    )
}
```

Boundary:

- Retorna `Interactive` cuando recibe `Interactive`.
- Retorna `DeviceCode` cuando recibe `DeviceLogin`, para adaptar el contrato vigente de `Get-SpoListNames` a la API publica planificada de `Connect-Spo`.

### `Invoke-GetSpoListNamesAuthentication`

```powershell
function Invoke-GetSpoListNamesAuthentication {
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

        [Parameter(Mandatory)]
        [ValidateSet('Interactive', 'DeviceLogin')]
        [string]$AuthMode
    )
}
```

Boundary:

- Llama primero a `Import-GetSpoListNamesAuthenticationModule`.
- Convierte `AuthMode` a la nomenclatura de `Connect-Spo`.
- Invoca `Connect-Spo -SiteUrl $SiteUrl -TenantId $TenantId -ClientId $ClientId -AuthMode <Interactive|DeviceCode> -ErrorAction Stop`.
- Si `Connect-Spo` falla, no consulta listas y lanza un mensaje comprensible que incluya que fallo la autenticacion mediante `Connect-Spo`.

---

## Cambios en Manifiesto si `Get-SpoListNames` es Modulo

Si existe o se implementa `modules/Get-SpoListNames/Get-SpoListNames.psd1`, debe ajustarse dentro del alcance de esta historia para declarar la dependencia:

```powershell
RequiredModules = @('Connect-Spo')
```

El manifiesto debe conservar:

- `RootModule = 'Get-SpoListNames.psm1'`.
- `FunctionsToExport = @('Get-SpoListNames')`.
- Sin `NestedModules`, `RequiredAssemblies`, binarios ni instaladores.

Si la historia 02-01 aun no esta implementada al momento de esta implementacion, el TODO asociado al manifiesto queda como cambio pendiente condicionado y debe documentarse en la retro. No se debe crear todo el empaquetado de `Get-SpoListNames` desde esta historia.

---

## Flujo Tecnico Esperado

1. `Get-SpoListNames` recibe parametros.
2. Resuelve `ClientId` segun compatibilidad vigente.
3. Resuelve `TenantId` desde parametro o `AZURE_TENANT_ID` para poder llamar a `Connect-Spo`.
4. Importa `Connect-Spo` por nombre.
5. Llama a `Connect-Spo` con `SiteUrl`, `TenantId`, `ClientId` y `AuthMode` adaptado.
6. Solo si la autenticacion fue exitosa, ejecuta `Get-PnPList -Includes 'EntityTypeName', 'Title', 'Hidden', 'BaseType' -ErrorAction Stop`.
7. Mantiene filtrado de listas ocultas y bibliotecas documentales.
8. Mantiene proyeccion `InternalName = EntityTypeName` y `VisibleTitle = Title`, ordenada por `Title`.

---

## Tests Previstos

Actualizar pruebas existentes y agregar `tools/Get-SpoListNames/tests/Get-SpoListNames.ConnectSpo.Tests.ps1`.

Casos minimos:

- Con stub/mocking de modulo `Connect-Spo`, `Get-SpoListNames` importa `Connect-Spo` por nombre antes de consultar listas.
- `Get-SpoListNames` llama `Connect-Spo` y no llama `Connect-PnPOnline` directamente.
- `AuthMode Interactive` se pasa a `Connect-Spo` como `Interactive`.
- `AuthMode DeviceLogin` se pasa a `Connect-Spo` como `DeviceCode`.
- Si `Connect-Spo` no esta disponible por nombre, se lanza el mensaje minimo aprobado y no se llama `Get-PnPList`.
- Si `Connect-Spo` falla, no se llama `Get-PnPList` y el error indica fallo de autenticacion mediante `Connect-Spo`.
- La salida de listas conserva filtrado, ordenamiento y propiedades `InternalName`/`VisibleTitle`.
- Busqueda estatica o test de contenido confirma que no existen referencias a `tools/Connect-Spo` ni dot-sourcing hacia `Connect-Spo` en archivos modificados.
- Si existe `modules/Get-SpoListNames/Get-SpoListNames.psd1`, `Test-ModuleManifest` pasa y `RequiredModules` contiene `Connect-Spo`.

Los tests no deben requerir conexion real a SharePoint ni instalacion persistente de modulos. Para pruebas por nombre, usar `PSModulePath` temporal que incluya un directorio controlado de fixtures o el directorio `modules/` del repo cuando corresponda, restaurandolo al finalizar.

---

## Comandos de Verificacion

Desde `tools/Get-SpoListNames`:

```powershell
Invoke-Pester -Path tests -Output Detailed
Invoke-ScriptAnalyzer -Path src -Recurse
```

Si existe `modules/Get-SpoListNames` por la historia 02-01, ejecutar ademas desde la raiz del repo:

```powershell
Test-ModuleManifest -Path .\modules\Get-SpoListNames\Get-SpoListNames.psd1
Invoke-ScriptAnalyzer -Path .\modules\Get-SpoListNames -Recurse
```

Smoke test de dependencia por nombre con `PSModulePath` controlado, sin autenticacion real:

```powershell
pwsh -NoProfile -Command "$repoModules = (Resolve-Path '.\modules').Path; $old = $env:PSModulePath; try { $env:PSModulePath = $repoModules + [IO.Path]::PathSeparator + $old; Import-Module Connect-Spo -Force; Get-Command Connect-Spo -Module Connect-Spo | Select-Object -ExpandProperty Name } finally { $env:PSModulePath = $old; Remove-Module Connect-Spo -ErrorAction SilentlyContinue }"
```

No se define smoke test con autenticacion real porque requiere tenant, app registration, consentimiento y credenciales interactivas fuera del alcance automatizable de esta historia.

---

## TODOs Atomicos Verificables

- [x] 1. Verificar que la implementacion de `Connect-Spo` como modulo por nombre esta disponible o documentar como precondicion bloqueante si aun no fue implementada.
- [x] 2. Identificar si existe `modules/Get-SpoListNames/`; si no existe, limitar cambios al script y tests sin crear el empaquetado completo.
- [x] 3. Actualizar `tools/Get-SpoListNames/src/Get-SpoListNames.ps1` para remover la validacion directa de `Connect-PnPOnline` como mecanismo de autenticacion.
- [x] 4. Agregar helper interno `Import-GetSpoListNamesAuthenticationModule` con la firma definida y carga por nombre `Connect-Spo`.
- [x] 5. Agregar helper interno `Resolve-GetSpoListNamesClientId` preservando precedencia vigente de variables de entorno.
- [x] 6. Agregar helper interno `Resolve-GetSpoListNamesTenantId` para parametro o `AZURE_TENANT_ID`.
- [x] 7. Agregar helper interno `ConvertTo-GetSpoListNamesConnectSpoAuthMode` para mapear `DeviceLogin` a `DeviceCode`.
- [x] 8. Agregar helper interno `Invoke-GetSpoListNamesAuthentication` que invoque `Connect-Spo` y detenga la consulta si falla.
- [x] 9. Reemplazar la llamada directa a `Connect-PnPOnline` por `Invoke-GetSpoListNamesAuthentication`.
- [x] 10. Mantener intacta la consulta `Get-PnPList`, filtrado de ocultas/documentales, ordenamiento y proyeccion aprobada.
- [x] 11. Actualizar ayuda de `Get-SpoListNames` para mencionar dependencia `Connect-Spo` por nombre y `PSModulePath`.
- [x] 12. Eliminar cualquier referencia introducida o existente a rutas relativas hacia `tools/Connect-Spo`.
- [x] 13. Si existe `modules/Get-SpoListNames/Get-SpoListNames.psm1`, aplicar los mismos cambios de autenticacion en la funcion exportada del modulo.
- [x] 14. Si existe `modules/Get-SpoListNames/Get-SpoListNames.psd1`, agregar `RequiredModules = @('Connect-Spo')` y conservar exportacion publica solo de `Get-SpoListNames`.
- [x] 15. Crear o actualizar tests para validar que se importa `Connect-Spo` por nombre.
- [x] 16. Crear o actualizar tests para validar que `Connect-PnPOnline` no se llama directamente desde `Get-SpoListNames`.
- [x] 17. Crear test de error claro cuando `Connect-Spo` no esta disponible y confirmar que no se ejecuta `Get-PnPList`.
- [x] 18. Crear test de fallo de autenticacion propagado/comprensible cuando `Connect-Spo` lanza error y confirmar que no se ejecuta `Get-PnPList`.
- [x] 19. Crear tests de mapeo de `AuthMode`: `Interactive` -> `Interactive`, `DeviceLogin` -> `DeviceCode`.
- [x] 20. Mantener o actualizar tests funcionales existentes de filtrado y salida de listas con mocks.
- [x] 21. Agregar verificacion estatica/test que falle si aparece `tools/Connect-Spo` en archivos de implementacion de `Get-SpoListNames`.
- [x] 22. Ejecutar `Invoke-Pester -Path tests -Output Detailed` desde `tools/Get-SpoListNames` y documentar resultado en la retro de implementacion.
- [x] 23. Ejecutar `Invoke-ScriptAnalyzer -Path src -Recurse` desde `tools/Get-SpoListNames` y documentar resultado.
- [x] 24. Si existe `modules/Get-SpoListNames`, ejecutar `Test-ModuleManifest` e `Invoke-ScriptAnalyzer` sobre el modulo y documentar resultado.
- [x] 25. Crear retro de implementacion `tools/Get-SpoListNames/plan/01-02-consume-connect-spo-module-for-authentication-retro.md` solo durante Implementacion.

---

## Criterios de Aceptacion Tecnicos

- [ ] `Get-SpoListNames` consume autenticacion mediante `Connect-Spo` importado por nombre.
- [ ] No hay referencias a rutas relativas hacia `tools/Connect-Spo` en la implementacion de `Get-SpoListNames`.
- [ ] Si `Connect-Spo` no esta disponible, el error es claro, accionable y menciona `PSModulePath`.
- [ ] Si `Connect-Spo` falla autenticando, `Get-SpoListNames` no consulta listas.
- [ ] `Get-SpoListNames` no llama `Connect-PnPOnline` directamente para autenticar.
- [ ] La salida funcional de listas no documentales con `InternalName` y `VisibleTitle` se conserva.
- [ ] Si `Get-SpoListNames` esta empaquetado como modulo, su manifiesto declara `RequiredModules = @('Connect-Spo')` y exporta solo `Get-SpoListNames`.
- [ ] Tests automatizados cubren dependencia disponible, dependencia faltante, fallo de autenticacion y salida de listas con mocks.

---

## Riesgos y Mitigaciones

| Riesgo | Mitigacion |
|--------|------------|
| `Connect-Spo` aun no implementado como modulo al iniciar esta historia. | Tratarlo como precondicion bloqueante o usar fixtures de test; no implementar `Connect-Spo` desde esta historia. |
| Diferencia de nomenclatura `DeviceLogin` vs `DeviceCode`. | Mantener firma publica de `Get-SpoListNames` y mapear internamente hacia la API de `Connect-Spo`. |
| El manifiesto con `RequiredModules` puede fallar antes de ejecutar validacion runtime. | Mantener validacion runtime para script y documentar/testear el comportamiento de manifiesto cuando exista modulo. |
| Reintroduccion accidental de rutas relativas a otra tool. | Test/grep sobre archivos modificados buscando `tools/Connect-Spo` y dot-sourcing de archivos externos. |
| Fallas ambientales de temporales en OneDrive. | Si Pester o analizadores fallan por cache/bloqueos, usar ubicacion temporal preaprobada fuera de OneDrive y documentarlo en retro/test. |

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-14 | Planning Agent | Crea dev spec tecnico en BORRADOR para consumir `Connect-Spo` como modulo por nombre desde `Get-SpoListNames`. |
| 0.2.0 | 2026-06-14 | Planning Agent | Marca dev spec como APROBADO por aprobación explícita del usuario. |
| 0.3.0 | 2026-06-14 | Implementation Agent | Marca TODOs completados tras implementar consumo de `Connect-Spo` en script y modulo. |
| 0.4.0 | 2026-06-14 | Implementation Agent | Deja el dev spec en EN_REVISION tras implementacion, con test y review aprobados. |
