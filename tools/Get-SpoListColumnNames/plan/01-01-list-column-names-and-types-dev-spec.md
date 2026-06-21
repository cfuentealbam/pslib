# Listar nombres internos, visibles y tipos de columnas por GUID de lista - Dev Spec

**Estado:** EN_REVISION

**Desarrollo:** `tools/Get-SpoListColumnNames`
**Producto:** `00-get-spo-list-column-names-spec.md`
**Epica:** `01-list-column-discovery-spec.md`
**Historia:** `01-01-list-column-names-and-types-spec.md`
**Basado en story spec version:** 0.4.0
**Fecha:** 2026-06-15

---

## Verificacion de Estado

La historia objetivo `tools/Get-SpoListColumnNames/plan/01-01-list-column-names-and-types-spec.md` declara `**Estado:** APROBADO`. El producto `00-get-spo-list-column-names-spec.md` y la epica `01-list-column-discovery-spec.md` tambien declaran `APROBADO`.

Este dev spec queda en `BORRADOR` hasta aprobacion explicita del usuario. No se debe implementar codigo antes de esa aprobacion.

---

## Investigacion

### Recursos Consultados

| Recurso | URL / Referencia | Relevancia | Hallazgo Principal |
|---------|------------------|------------|--------------------|
| `Get-PnPField` | https://pnp.github.io/powershell/cmdlets/Get-PnPField.html | Alta | Devuelve campos de una lista o sitio; acepta `-List`, `-Connection` e `-Includes`. |
| `Get-PnPList` | https://pnp.github.io/powershell/cmdlets/Get-PnPList.html | Alta | Devuelve listas; `-Identity` acepta ID/GUID, nombre o URL; acepta `-Connection`. |
| `Connect-Spo` local | `modules/Connect-Spo/Connect-Spo.psm1` | Alta | Registra `$global:PSLibSpoConnectionContext` y retorna conexion PnP. |

---

## Alcance Tecnico

Crear un script PowerShell bajo `tools/Get-SpoListColumnNames/src/Get-SpoListColumnNames.ps1` que:

1. Recibe `ListGuid` o `ListTitle` como parametros obligatorios alternativos y mutuamente excluyentes.
2. Usa contexto activo de `Connect-Spo` si `SiteUrl` no se entrega.
3. Si `SiteUrl` se entrega, autentica explicitamente mediante `Connect-Spo`.
4. Resuelve una identidad de lista unica como texto desde `ListGuid` o `ListTitle`.
5. Valida que la lista exista mediante `Get-PnPList -Identity <listIdentity> -Connection`.
6. Obtiene columnas mediante `Get-PnPField -List <listIdentity> -Connection`, incluyendo propiedades de filtrado `Hidden`, `ReadOnlyField`, `Sealed` y `FromBaseType`.
7. Filtra campos internos con la regla aprobada y conserva `Title`.
8. Devuelve objetos con `InternalName`, `DisplayName` y `Type`.

Fuera de alcance:

- Crear modulo bajo `modules/`.
- Modificar columnas.
- Leer items.
- Parametrizar la inclusion de campos internos.
- Exportar a archivos.
- Cambios bajo `mcp/`.

---

## Dependencias Seleccionadas

| Dependencia | Tipo | Uso | Justificacion |
|-------------|------|-----|---------------|
| `Connect-Spo` | Runtime | Autenticacion explicita y contexto activo. | Contrato aprobado para tools SharePoint del repo. |
| `PnP.PowerShell` | Runtime transitiva | `Get-PnPList` y `Get-PnPField`. | API oficial PnP para listas y campos. |
| `Pester` | Test | Pruebas con mocks. | Herramienta usada en el repo. |
| `PSScriptAnalyzer` | Verificacion | Analisis estatico. | Herramienta usada en el repo. |

---

## Estructura Objetivo

```text
tools/Get-SpoListColumnNames/
|- plan/
|  |- 00-get-spo-list-column-names-spec.md
|  |- 01-list-column-discovery-spec.md
|  |- 01-01-list-column-names-and-types-spec.md
|  `- 01-01-list-column-names-and-types-dev-spec.md
|- src/
|  `- Get-SpoListColumnNames.ps1
`- tests/
   `- Get-SpoListColumnNames.Tests.ps1
```

---

## API Publica

Archivo objetivo: `tools/Get-SpoListColumnNames/src/Get-SpoListColumnNames.ps1`.

El script debe poder ejecutarse como entrypoint:

```powershell
Get-SpoListColumnNames -ListGuid 'c8f7f928-3cbd-46bd-8174-4f66985491ec'
Get-SpoListColumnNames -ListTitle 'Incidentes'
```

Firma de parametros de script y funcion interna:

```powershell
function Get-SpoListColumnNames {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding(DefaultParameterSetName = 'ByGuid')]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^https://')]
        [string]$SiteUrl,

        [Parameter(Mandatory, ParameterSetName = 'ByGuid')]
        [ValidateNotNullOrEmpty()]
        [guid]$ListGuid,

        [Parameter(Mandatory, ParameterSetName = 'ByTitle')]
        [ValidateNotNullOrEmpty()]
        [string]$ListTitle,

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

Salida:

```text
InternalName
DisplayName
Type
```

Mapeo:

- `InternalName`: `$field.InternalName`
- `DisplayName`: `$field.Title`
- `Type`: preferir `$field.TypeAsString`; si viene vacio, usar `$field.TypeDisplayName`; si tambien viene vacio, usar string de `$field.FieldTypeKind`.

---

## Helpers Internos

### `Import-GetSpoListColumnNamesAuthenticationModule`

Importa `Connect-Spo` por nombre y valida que exista el comando publico.

Error:

```text
No se puede cargar la dependencia Connect-Spo. Instale o exponga el modulo Connect-Spo en PSModulePath y vuelva a ejecutar la operacion.
```

### `Resolve-GetSpoListColumnNamesClientId`

Resuelve `ClientId` desde parametro o variables:

1. `ENTRAID_APP_ID`
2. `ENTRAID_CLIENT_ID`
3. `AZURE_CLIENT_ID`

Error:

```text
No se pudo resolver ClientId. Proporcionalo con -ClientId o define ENTRAID_APP_ID / ENTRAID_CLIENT_ID / AZURE_CLIENT_ID.
```

### `Resolve-GetSpoListColumnNamesTenantId`

Resuelve `TenantId` desde parametro o `AZURE_TENANT_ID`.

Error:

```text
No se pudo resolver TenantId para Connect-Spo. Proporcionalo con -TenantId o define AZURE_TENANT_ID.
```

### `ConvertTo-GetSpoListColumnNamesConnectSpoAuthMode`

Mapea:

| Entrada publica | Valor para `Connect-Spo` |
|-----------------|--------------------------|
| `Interactive` | `Interactive` |
| `DeviceLogin` | `DeviceCode` |

### `Invoke-GetSpoListColumnNamesAuthentication`

Llama:

```powershell
Connect-Spo -SiteUrl $SiteUrl -TenantId $TenantId -ClientId $ClientId -AuthMode $connectSpoAuthMode -ErrorAction Stop
```

Retorna la conexion PnP.

### `Get-GetSpoListColumnNamesActiveContext`

Lee `$global:PSLibSpoConnectionContext`, valida que tenga `Connection` y `SiteUrl`, y devuelve el contexto si es usable.

### `Resolve-GetSpoListColumnNamesExecutionContext`

Reglas:

1. Si `SiteUrl` existe, usa flujo explicito con `Connect-Spo`.
2. Si `SiteUrl` no existe, usa contexto activo.
3. Si no hay contexto valido, lanza:

```text
No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.
```

Retorna:

```powershell
[pscustomobject]@{
    Connection = $connection
    SiteUrl    = $siteUrl
}
```

### `Resolve-GetSpoListColumnNamesListIdentity`

Recibe `ListGuid` y `ListTitle`.

Reglas:

1. Si se entrega `ListGuid`, retorna `$ListGuid.ToString()`.
2. Si se entrega `ListTitle`, retorna `$ListTitle.Trim()`.
3. PowerShell evita que ambos parametros se entreguen juntos mediante parameter sets.

### `Get-GetSpoListColumnNamesFields`

Recibe `Connection`, `ListIdentity` y `SiteUrl`.

Flujo:

1. Valida existencia de lista:

```powershell
Get-PnPList -Connection $Connection -Identity $ListIdentity -ThrowExceptionIfListNotFound -ErrorAction Stop
```

2. Obtiene campos:

```powershell
Get-PnPField -Connection $Connection -List $ListIdentity -Includes 'InternalName', 'Title', 'TypeAsString', 'TypeDisplayName', 'FieldTypeKind', 'Hidden', 'ReadOnlyField', 'Sealed', 'FromBaseType' -ErrorAction Stop
```

Error:

```text
No se pudieron obtener las columnas de la lista '<listIdentity>' en el sitio '<siteUrl>'. <mensaje original>
```

### `ConvertTo-GetSpoListColumnNamesOutput`

Convierte cada field a:

```powershell
[pscustomobject]@{
    InternalName = $field.InternalName
    DisplayName  = $field.Title
    Type         = <tipo resuelto>
}
```

Orden:

- Ordenar por `DisplayName`, luego `InternalName`.

### `Test-GetSpoListColumnNamesDisplayField`

Recibe cada field de SharePoint y retorna verdadero solo si cumple:

```powershell
-not $Field.Hidden -and
    -not $Field.ReadOnlyField -and
    -not $Field.Sealed -and
    (-not $Field.FromBaseType -or $Field.InternalName -eq 'Title')
```

---

## Flujo Tecnico Esperado

1. `Get-SpoListColumnNames` recibe parametros.
2. Resuelve contexto de ejecucion.
3. Resuelve identidad de lista desde `ListGuid` o `ListTitle`.
4. Valida lista por identidad.
5. Obtiene campos de la lista.
6. Excluye campos internos de SharePoint con el filtro aprobado.
7. Proyecta `InternalName`, `DisplayName`, `Type`.
8. Ordena salida.
9. No modifica SharePoint.

---

## Tests Previstos

Crear `tools/Get-SpoListColumnNames/tests/Get-SpoListColumnNames.Tests.ps1`.

Casos minimos:

- Con contexto activo y solo `ListGuid`, consulta lista/campos sin llamar `Connect-Spo`.
- Con contexto activo y solo `ListTitle`, consulta lista/campos sin llamar `Connect-Spo`.
- Sin contexto activo y sin `SiteUrl`, falla con mensaje aprobado y no llama PnP.
- Con contexto activo invalido, falla con mensaje aprobado.
- Con `SiteUrl` explicito, llama `Connect-Spo` y usa la conexion devuelta.
- Mapea `DeviceLogin` a `DeviceCode`.
- Resuelve `ClientId` desde variables aprobadas.
- Resuelve `TenantId` desde `AZURE_TENANT_ID`.
- Valida existencia de lista con `Get-PnPList -Identity <listIdentity>`.
- Obtiene campos con `Get-PnPField -List <listIdentity>`.
- Incluye `Hidden`, `ReadOnlyField`, `Sealed` y `FromBaseType` al obtener campos.
- Descarta campos internos y conserva `Title`.
- Rechaza la combinacion simultanea de `ListGuid` y `ListTitle` mediante parameter sets.
- Devuelve `InternalName`, `DisplayName`, `Type`.
- Prefiere `TypeAsString` para `Type`; usa fallback cuando falta.
- Si la lista no existe o PnP falla, devuelve error claro.
- No llama `Connect-PnPOnline` directamente.

---

## Comandos de Verificacion

Ejecutar desde `tools/Get-SpoListColumnNames`:

```powershell
Invoke-Pester -Path tests
Invoke-ScriptAnalyzer -Path src -Recurse
pwsh -NoProfile -Command ". ./src/Get-SpoListColumnNames.ps1 -? | Out-String | Select-String Get-SpoListColumnNames"
```

No se define smoke test real contra SharePoint porque requiere sitio, lista y credenciales reales.

---

## TODOs Atomicos

- [x] 1. Crear `tools/Get-SpoListColumnNames/src/`.
- [x] 2. Crear `tools/Get-SpoListColumnNames/tests/`.
- [x] 3. Crear `src/Get-SpoListColumnNames.ps1` con Control de Cambios PowerShell.
- [x] 4. Definir parametros de script y ayuda basada en comentarios.
- [x] 5. Definir funcion interna `Get-SpoListColumnNames` con firma aprobada.
- [x] 6. Implementar importacion de `Connect-Spo` por nombre.
- [x] 7. Implementar resolucion de `ClientId`.
- [x] 8. Implementar resolucion de `TenantId`.
- [x] 9. Implementar mapeo `DeviceLogin` -> `DeviceCode`.
- [x] 10. Implementar autenticacion explicita con `Connect-Spo`.
- [x] 11. Implementar lectura de contexto activo.
- [x] 12. Implementar resolucion de contexto de ejecucion.
- [x] 13. Implementar validacion de lista por GUID con `Get-PnPList`.
- [x] 14. Implementar obtencion de campos con `Get-PnPField`.
- [x] 15. Implementar proyeccion `InternalName`, `DisplayName`, `Type`.
- [x] 16. Implementar ordenamiento de salida.
- [x] 17. Crear pruebas unitarias con mocks.
- [x] 18. Ejecutar Pester.
- [x] 19. Ejecutar ScriptAnalyzer.
- [x] 20. Ejecutar smoke test de ayuda.
- [x] 21. Crear retro de implementacion.
- [x] 22. Actualizar firma publica con `ListTitle` como alternativa a `ListGuid`.
- [x] 23. Implementar resolucion de identidad de lista por GUID o Title.
- [x] 24. Ajustar validacion y lectura de campos para usar la identidad resuelta.
- [x] 25. Agregar pruebas para `ListTitle` y exclusividad de parametros.
- [x] 26. Agregar propiedades de filtrado a `Get-PnPField -Includes`.
- [x] 27. Implementar filtro de campos desplegables.
- [x] 28. Agregar pruebas para descartar campos internos y conservar `Title`.

## Iteracion 2026-06-18: Modo Quiet por Defecto

### Alcance Tecnico

El refinamiento funcional aprobado exige que `Get-SpoListColumnNames` opere en modo Quiet por defecto. La implementacion debe:

1. Mantener la salida funcional aprobada: objetos con `InternalName`, `DisplayName` y `Type`.
2. Mantener errores accionables y prompts necesarios.
3. No emitir mensajes auxiliares de estado, progreso o diagnostico por defecto.
4. Emitir mensajes auxiliares solo mediante `Write-Verbose`.
5. Instalarse como modulo PowerShell global compartido para exponer el comando por nombre.

### Mensajes Verbose Planificados

- Resolucion de identidad de lista por GUID o Title.
- Inicio de lectura de campos de la lista.
- Cantidad de columnas desplegables devueltas.

### TODOs Quiet/Verbose

- [x] 29. Agregar linea de Control de Cambios PowerShell para modo Quiet/Verbose.
- [x] 30. Agregar `Write-Verbose` al resolver identidad de lista.
- [x] 31. Agregar `Write-Verbose` antes de obtener campos.
- [x] 32. Agregar `Write-Verbose` con cantidad de columnas devueltas.
- [x] 33. Agregar pruebas para ausencia de registros verbose sin `-Verbose`.
- [x] 34. Agregar pruebas para presencia de registros verbose con `-Verbose`.
- [x] 35. Ejecutar Pester y ScriptAnalyzer.
- [x] 36. Instalar el comando como modulo global compartido tras aprobar pruebas.

---

## Criterios de Aceptacion Tecnicos

- [ ] El script funciona con contexto activo y solo `ListGuid`.
- [ ] El script funciona con contexto activo y solo `ListTitle`.
- [ ] El script funciona con conexion explicita mediante `SiteUrl`.
- [ ] La salida contiene exactamente las propiedades funcionales aprobadas.
- [ ] La salida descarta campos internos de SharePoint segun el filtro aprobado.
- [ ] No hay operaciones de escritura.
- [ ] Tests automatizados cubren contexto activo, conexion explicita, errores y shape de salida.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-15 | Planning Agent | Dev spec inicial en BORRADOR para `Get-SpoListColumnNames`. |
| 0.2.0 | 2026-06-15 | Planning Agent | Cambia estado a APROBADO por aprobacion explicita del usuario. |
| 0.3.0 | 2026-06-15 | Dev Agent | Marca TODOs completados y deja el dev spec en EN_REVISION tras implementacion. |
| 0.4.0 | 2026-06-16 | Planning Agent | Actualiza diseno para soportar `ListTitle` como identidad alternativa aprobada. |
| 0.5.0 | 2026-06-16 | Planning Agent | Actualiza diseno para descartar campos internos de SharePoint y conservar `Title`. |
| 0.6.0 | 2026-06-18 | Planning Agent | Aprueba plan tecnico para modo Quiet por defecto y mensajes auxiliares via `-Verbose`. |
| 0.7.0 | 2026-06-18 | Dev Agent | Implementa modo Quiet/Verbose, completa TODOs y deja el dev spec en EN_REVISION para Testing. |
