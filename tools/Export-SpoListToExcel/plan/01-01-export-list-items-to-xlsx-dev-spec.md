# Exportar items de lista SharePoint a `.xlsx` - Dev Spec

**Estado:** EN_REVISION

**Desarrollo:** `tools/Export-SpoListToExcel`
**Producto:** `00-export-spo-list-to-excel-spec.md`
**Epica:** `01-excel-list-export-spec.md`
**Historia:** `01-01-export-list-items-to-xlsx-spec.md`
**Basado en story spec version:** 0.5.0
**Fecha:** 2026-06-16

---

## Verificacion de Estado

La historia objetivo `tools/Export-SpoListToExcel/plan/01-01-export-list-items-to-xlsx-spec.md` declara `**Estado:** APROBADO`. El producto `00-export-spo-list-to-excel-spec.md` y la epica `01-excel-list-export-spec.md` tambien declaran `APROBADO`.

El usuario aprobo avanzar con Planning e Implementacion para la iteracion de lista vacia el 2026-06-19. El dev spec queda en `EN_REVISION` tras la implementacion y debe derivarse a Testing formal.

---

## Investigacion

### Recursos Consultados

| Recurso | URL / Referencia | Relevancia | Hallazgo Principal |
|---------|------------------|------------|--------------------|
| `Get-PnPListItem` | https://pnp.github.io/powershell/cmdlets/Get-PnPListItem.html | Alta | Recupera items de lista; acepta `-List`, `-Fields`, `-PageSize`, `-Connection` y retorna `FieldValues`. |
| `Get-PnPList` | https://pnp.github.io/powershell/cmdlets/Get-PnPList.html | Alta | `-Identity` acepta ID, nombre o URL de lista y permite validar existencia con `-ThrowExceptionIfListNotFound`. |
| `ImportExcel` | https://github.com/dfinke/ImportExcel | Alta | Permite crear archivos Excel `.xlsx` desde PowerShell sin Excel instalado mediante `Export-Excel`. |
| `Get-SpoListColumnNames` local | `tools/Get-SpoListColumnNames/src/Get-SpoListColumnNames.ps1` | Alta | Define la regla aprobada para campos desplegables y el patron de autenticacion/contexto activo. |
| `Connect-Spo` local | `modules/Connect-Spo/Connect-Spo.psm1` | Alta | Registra `$global:PSLibSpoConnectionContext` y retorna conexion PnP. |

---

## Alcance Tecnico

Crear un script PowerShell bajo `tools/Export-SpoListToExcel/src/Export-SpoListToExcel.ps1` que:

1. Recibe `ListGuid` o `ListTitle` como parametros obligatorios alternativos y mutuamente excluyentes.
2. Recibe `OutputPath` obligatorio y valida extension `.xlsx`.
3. Recibe `Force` opcional para sobrescribir archivo existente.
4. Usa contexto activo de `Connect-Spo` si `SiteUrl` no se entrega.
5. Si `SiteUrl` se entrega, autentica explicitamente mediante `Connect-Spo`.
6. Resuelve una identidad de lista unica como texto desde `ListGuid` o `ListTitle`.
7. Valida que la lista exista mediante `Get-PnPList -Identity <listIdentity> -Connection`.
8. Obtiene campos de lista mediante `Get-PnPField -List <listIdentity> -Includes ...`.
9. Filtra campos desplegables con la misma regla aprobada en `Get-SpoListColumnNames`.
10. Obtiene items mediante `Get-PnPListItem -List <listIdentity> -Fields <internalNames> -PageSize <n> -Connection`; si ese intento falla con un error recuperable atribuible a lista vacía, normaliza el resultado a una colección vacía.
11. Proyecta cada item a un objeto tabular con propiedades en orden de campos desplegables.
12. Normaliza valores de SharePoint a valores aptos para Excel.
13. Si no hay items, conserva el conjunto de encabezados de campos desplegables y exporta una hoja sin filas de datos.
14. Exporta a `.xlsx` mediante `Export-Excel` del modulo `ImportExcel`.
15. Aplica formato de fecha `dd-MM-yyyy`, numeros con decimales sin separador de miles, y wrap text para columnas de texto.
16. Devuelve un objeto con `OutputPath`, `ItemCount`, `FieldCount` y `WorksheetName`.

Fuera de alcance:

- Exportar a CSV, JSON, XML, `.xls` u otros formatos.
- Exportar multiples listas.
- Exportar adjuntos.
- Filtrar items por consulta, vista, CAML u OData.
- Crear modulo bajo `modules/`.
- Instalar dependencias automaticamente.
- Cambios bajo `mcp/`.

---

## Dependencias Seleccionadas

| Dependencia | Tipo | Uso | Justificacion |
|-------------|------|-----|---------------|
| `Connect-Spo` | Runtime | Autenticacion explicita y contexto activo. | Contrato aprobado para tools SharePoint del repo. |
| `PnP.PowerShell` | Runtime transitiva | `Get-PnPList`, `Get-PnPField` y `Get-PnPListItem`. | API PnP usada por las tools SharePoint existentes. |
| `ImportExcel` | Runtime | Crear `.xlsx` y aplicar formato sin requerir Excel instalado. | Resuelve el formato Excel real y evita fragilidad de CSV con texto multilinea. |
| `Pester` | Test | Pruebas con mocks. | Herramienta usada en el repo. |
| `PSScriptAnalyzer` | Verificacion | Analisis estatico. | Herramienta usada en el repo. |

Si `ImportExcel` no esta disponible, la herramienta debe fallar antes de consultar SharePoint con:

```text
No se puede cargar la dependencia ImportExcel. Instale el modulo ImportExcel en PSModulePath y vuelva a ejecutar la operacion.
```

---

## Estructura Objetivo

```text
tools/Export-SpoListToExcel/
|- plan/
|  |- 00-export-spo-list-to-excel-spec.md
|  |- 01-excel-list-export-spec.md
|  |- 01-01-export-list-items-to-xlsx-spec.md
|  `- 01-01-export-list-items-to-xlsx-dev-spec.md
|- src/
|  `- Export-SpoListToExcel.ps1
`- tests/
   `- Export-SpoListToExcel.Tests.ps1
```

---

## API Publica

Archivo objetivo: `tools/Export-SpoListToExcel/src/Export-SpoListToExcel.ps1`.

El script debe poder ejecutarse como entrypoint:

```powershell
Export-SpoListToExcel -ListTitle 'Incidentes' -OutputPath '.\incidentes.xlsx'
Export-SpoListToExcel -ListGuid 'c8f7f928-3cbd-46bd-8174-4f66985491ec' -OutputPath '.\incidentes.xlsx' -Force
```

Firma de parametros de script y funcion interna:

```powershell
function Export-SpoListToExcel {
    [CmdletBinding(DefaultParameterSetName = 'ByTitle')]
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

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [ValidateSet('Interactive', 'DeviceLogin')]
        [string]$AuthMode = 'Interactive',

        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [string]$TenantId,

        [Parameter()]
        [ValidateRange(1, 5000)]
        [int]$PageSize = 2000,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$WorksheetName = 'Items'
    )
}
```

Salida PowerShell:

```powershell
[pscustomobject]@{
    OutputPath    = <ruta absoluta>
    ItemCount     = <cantidad de items exportados>
    FieldCount    = <cantidad de campos exportados>
    WorksheetName = <nombre de hoja>
}
```

---

## Helpers Internos

### `Import-ExportSpoListToExcelAuthenticationModule`

Importa `Connect-Spo` por nombre y valida que exista el comando publico.

Error:

```text
No se puede cargar la dependencia Connect-Spo. Instale o exponga el modulo Connect-Spo en PSModulePath y vuelva a ejecutar la operacion.
```

### `Import-ExportSpoListToExcelExcelModule`

Importa `ImportExcel` por nombre y valida que exista `Export-Excel`.

Error:

```text
No se puede cargar la dependencia ImportExcel. Instale el modulo ImportExcel en PSModulePath y vuelva a ejecutar la operacion.
```

### `Resolve-ExportSpoListToExcelClientId`

Resuelve `ClientId` desde parametro o variables:

1. `ENTRAID_APP_ID`
2. `ENTRAID_CLIENT_ID`
3. `AZURE_CLIENT_ID`

Error:

```text
No se pudo resolver ClientId. Proporcionalo con -ClientId o define ENTRAID_APP_ID / ENTRAID_CLIENT_ID / AZURE_CLIENT_ID.
```

### `Resolve-ExportSpoListToExcelTenantId`

Resuelve `TenantId` desde parametro o `AZURE_TENANT_ID`.

Error:

```text
No se pudo resolver TenantId para Connect-Spo. Proporcionalo con -TenantId o define AZURE_TENANT_ID.
```

### `ConvertTo-ExportSpoListToExcelConnectSpoAuthMode`

Mapea:

| Entrada publica | Valor para `Connect-Spo` |
|-----------------|--------------------------|
| `Interactive` | `Interactive` |
| `DeviceLogin` | `DeviceCode` |

### `Invoke-ExportSpoListToExcelAuthentication`

Llama:

```powershell
Connect-Spo -SiteUrl $SiteUrl -TenantId $TenantId -ClientId $ClientId -AuthMode $connectSpoAuthMode -ErrorAction Stop
```

Retorna la conexion PnP.

### `Get-ExportSpoListToExcelActiveContext`

Lee `$global:PSLibSpoConnectionContext`, valida que tenga `Connection` y `SiteUrl`, y devuelve el contexto si es usable.

### `Resolve-ExportSpoListToExcelExecutionContext`

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

### `Resolve-ExportSpoListToExcelListIdentity`

Recibe `ListGuid` y `ListTitle`.

Reglas:

1. Si se entrega `ListGuid`, retorna `$ListGuid.ToString()`.
2. Si se entrega `ListTitle`, retorna `$ListTitle.Trim()`.
3. PowerShell evita que ambos parametros se entreguen juntos mediante parameter sets.

### `Resolve-ExportSpoListToExcelOutputPath`

Recibe `OutputPath` y `Force`.

Reglas:

1. Resuelve ruta absoluta.
2. Valida extension `.xlsx` con comparacion case-insensitive.
3. Valida que el directorio padre exista.
4. Si el archivo existe y `Force` no esta presente, falla.

Errores:

```text
OutputPath debe terminar en .xlsx.
El directorio de salida '<directorio>' no existe.
El archivo de salida '<ruta>' ya existe. Use -Force para sobrescribirlo.
```

### `Test-ExportSpoListToExcelDisplayField`

Recibe cada field de SharePoint y retorna verdadero solo si cumple:

```powershell
-not $Field.Hidden -and
    -not $Field.ReadOnlyField -and
    -not $Field.Sealed -and
    (-not $Field.FromBaseType -or $Field.InternalName -eq 'Title')
```

### `Get-ExportSpoListToExcelFields`

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

3. Filtra con `Test-ExportSpoListToExcelDisplayField`.
4. Ordena por `Title`, luego `InternalName`.

Error:

```text
No se pudieron obtener los campos exportables de la lista '<listIdentity>' en el sitio '<siteUrl>'. <mensaje original>
```

### `Get-ExportSpoListToExcelItems`

Recibe `Connection`, `ListIdentity`, `Fields`, `PageSize` y `SiteUrl`.

Llama:

```powershell
Get-PnPListItem -Connection $Connection -List $ListIdentity -Fields $fieldInternalNames -PageSize $PageSize -ErrorAction Stop
```

Resultado sin items:

- Si `Get-PnPListItem` retorna una coleccion vacia, devuelve `@()` sin error.
- Si `Get-PnPListItem` lanza un error recuperable identificable como ausencia de filas o items en una lista existente, normaliza el resultado a `@()` y permite continuar la exportacion solo con encabezados.

Error bloqueante:

Permisos insuficientes, lista inexistente, conexion invalida, parametros invalidos y cualquier error no identificado explicitamente como lista vacia deben fallar con:

```text
No se pudieron obtener los items de la lista '<listIdentity>' en el sitio '<siteUrl>'. <mensaje original>
```

### `ConvertTo-ExportSpoListToExcelCellValue`

Recibe `Value` y `Field`.

Reglas:

- `null`: retorna `$null`.
- Fechas (`DateTime`, `DateTimeKind` o valores `[datetime]`): retorna `[datetime]` para que Excel pueda formatear la celda.
- Numeros (`Number`, `Currency`, `Integer`, `Counter` o tipos numericos .NET): retorna valor numerico sin convertir a string.
- Booleanos: retorna booleano.
- Colecciones simples: une valores por `; `.
- Objetos PnP/CSOM con propiedades conocidas como `LookupValue`, `Email`, `Title` o `Label`: retorna valor legible.
- Texto multilinea: conserva saltos de linea como `"`n"` para que Excel los mantenga dentro de la celda.
- Otros objetos: retorna string.

### `ConvertTo-ExportSpoListToExcelRow`

Recibe `Item` y `Fields`.

Lee valores desde `$Item.FieldValues[$field.InternalName]`, convierte cada valor con `ConvertTo-ExportSpoListToExcelCellValue` y crea `[pscustomobject]` con nombres de propiedad iguales al `Title` visible del campo. Si dos campos comparten `Title`, usa `Title (InternalName)` en el segundo y siguientes para evitar colisiones.

### `Export-ExportSpoListToExcelWorkbook`

Recibe `Rows`, `Fields`, `OutputPath`, `WorksheetName` y `Force`.

Flujo:

1. Importa `ImportExcel`.
2. Si no hay items, crea igualmente el workbook y deja la hoja con solo encabezados de campos exportables y cero filas de datos. Esta rama debe conservar `ItemCount = 0` y no debe inventar una fila de datos vacía visible.
3. Usa `Export-Excel -Path $OutputPath -WorksheetName $WorksheetName -TableName 'SpoListItems' -AutoSize -FreezeTopRow -BoldTopRow -ClearSheet -PassThru`.
4. Aplica formatos por columna sobre el paquete retornado:
   - Fechas: `dd-mm-yyyy`.
   - Numeros: formato decimal sin separador de miles. Formato base: `0.################`.
   - Texto multilinea: `WrapText = $true`.
5. Guarda y cierra el paquete.

Nota: El formato de Excel para mes usa `m`; el formato solicitado `dd-MM-yyyy` en PowerShell se traduce a `dd-mm-yyyy` en formato de celda Excel.

### `Get-ExportSpoListToExcelResult`

Retorna:

```powershell
[pscustomobject]@{
    OutputPath    = $OutputPath
    ItemCount     = $Rows.Count
    FieldCount    = $Fields.Count
    WorksheetName = $WorksheetName
}
```

---

## Flujo Tecnico Esperado

1. `Export-SpoListToExcel` recibe parametros.
2. Resuelve y valida `OutputPath`.
3. Valida disponibilidad de `ImportExcel`.
4. Resuelve contexto de ejecucion.
5. Resuelve identidad de lista desde `ListGuid` o `ListTitle`.
6. Valida lista y obtiene campos desplegables.
7. Obtiene items paginados de SharePoint; si la lectura falla por error recuperable de lista vacía, normaliza a cero items.
8. Si no hay items, prepara exportacion solo con encabezados de columnas exportables.
9. Si hay items, proyecta items a filas Excel.
10. Exporta `.xlsx`.
11. Aplica formatos de fecha, numero y texto multilinea.
12. Devuelve resumen de exportacion.
13. No modifica SharePoint.

---

## Tests Previstos

Crear `tools/Export-SpoListToExcel/tests/Export-SpoListToExcel.Tests.ps1`.

Casos minimos:

- Con contexto activo y `ListTitle`, exporta sin llamar `Connect-Spo`.
- Con contexto activo y `ListGuid`, exporta sin llamar `Connect-Spo`.
- Sin contexto activo y sin `SiteUrl`, falla con mensaje aprobado y no llama PnP.
- Con contexto activo invalido, falla con mensaje aprobado.
- Con `SiteUrl` explicito, llama `Connect-Spo` y usa la conexion devuelta.
- Mapea `DeviceLogin` a `DeviceCode`.
- Resuelve `ClientId` desde variables aprobadas.
- Resuelve `TenantId` desde `AZURE_TENANT_ID`.
- Falla claro si no puede cargar `Connect-Spo`.
- Falla claro si no puede cargar `ImportExcel`.
- Rechaza `OutputPath` sin extension `.xlsx`.
- Rechaza archivo existente sin `Force`.
- Permite archivo existente con `Force`.
- Valida existencia de lista con `Get-PnPList -Identity <listIdentity>`.
- Obtiene campos con `Get-PnPField` incluyendo propiedades del filtro.
- Descarta campos internos y conserva `Title`.
- Obtiene items con `Get-PnPListItem -Fields <internalNames> -PageSize <PageSize>`.
- Proyecta filas usando titulos visibles como encabezados.
- Cuando `Get-PnPListItem` retorna cero items, crea workbook con encabezados de columnas exportables, cero filas de datos e `ItemCount = 0`.
- Cuando `Get-PnPListItem` lanza un error recuperable atribuible a lista vacía, normaliza a cero items y crea el mismo workbook solo con encabezados.
- Evita colisiones de encabezados duplicados.
- Convierte fechas a `[datetime]` y permite formato `dd-mm-yyyy`.
- Convierte numeros a tipos numericos y permite formato decimal sin miles.
- Conserva saltos de linea de textos multilinea.
- Une colecciones simples con `; `.
- Devuelve `OutputPath`, `ItemCount`, `FieldCount` y `WorksheetName`.
- No llama `Connect-PnPOnline` directamente.

---

## Comandos de Verificacion

Ejecutar desde `tools/Export-SpoListToExcel`:

```powershell
Invoke-Pester -Path tests
Invoke-ScriptAnalyzer -Path src -Recurse
pwsh -NoLogo -NoProfile -File ./src/Export-SpoListToExcel.ps1 -?
```

Smoke test sin SharePoint:

```powershell
pwsh -NoLogo -NoProfile -Command "try { ./src/Export-SpoListToExcel.ps1 -ListTitle 'Demo' -OutputPath './demo.xlsx' -ErrorAction Stop } catch { `$_.Exception.Message }"
```

No se define smoke test real contra SharePoint porque requiere sitio, lista y credenciales reales.

---

## TODOs Atomicos

- [x] 1. Crear `tools/Export-SpoListToExcel/src/`.
- [x] 2. Crear `tools/Export-SpoListToExcel/tests/`.
- [x] 3. Crear `src/Export-SpoListToExcel.ps1` con Control de Cambios PowerShell.
- [x] 4. Definir parametros de script y ayuda basada en comentarios.
- [x] 5. Definir funcion interna `Export-SpoListToExcel` con firma aprobada.
- [x] 6. Implementar importacion de `Connect-Spo`.
- [x] 7. Implementar importacion de `ImportExcel`.
- [x] 8. Implementar resolucion de `ClientId`.
- [x] 9. Implementar resolucion de `TenantId`.
- [x] 10. Implementar mapeo `DeviceLogin` -> `DeviceCode`.
- [x] 11. Implementar autenticacion explicita con `Connect-Spo`.
- [x] 12. Implementar lectura de contexto activo.
- [x] 13. Implementar resolucion de contexto de ejecucion.
- [x] 14. Implementar resolucion de identidad de lista.
- [x] 15. Implementar validacion de `OutputPath` y `Force`.
- [x] 16. Implementar filtro de campos desplegables.
- [x] 17. Implementar obtencion de campos exportables.
- [x] 18. Implementar obtencion paginada de items.
- [x] 19. Implementar conversion de valores SharePoint a valores Excel.
- [x] 20. Implementar proyeccion de items a filas.
- [x] 21. Implementar manejo de encabezados duplicados.
- [x] 22. Implementar exportacion con `Export-Excel`.
- [x] 23. Implementar formato de fechas, numeros y texto multilinea en workbook.
- [x] 24. Implementar resultado de exportacion.
- [x] 25. Crear pruebas unitarias con mocks.
- [x] 26. Ejecutar Pester.
- [x] 27. Ejecutar ScriptAnalyzer.
- [x] 28. Ejecutar smoke test de ayuda.
- [x] 29. Crear retro de implementacion.

## Iteracion 2026-06-18: Modo Quiet por Defecto

### Alcance Tecnico

El refinamiento funcional aprobado exige que `Export-SpoListToExcel` opere en modo Quiet por defecto. La implementacion debe:

1. Mantener la salida funcional aprobada: archivo `.xlsx` y objeto resultado de exportacion.
2. Mantener errores accionables y prompts necesarios.
3. No emitir mensajes auxiliares de estado, progreso o diagnostico por defecto.
4. Emitir mensajes auxiliares solo mediante `Write-Verbose`.
5. Instalarse como modulo PowerShell global compartido para exponer el comando por nombre.

### Mensajes Verbose Planificados

- Resolucion de ruta de salida e identidad de lista.
- Obtencion de campos exportables.
- Obtencion de items.
- Escritura del workbook `.xlsx`.

### TODOs Quiet/Verbose

- [x] 30. Agregar linea de Control de Cambios PowerShell para modo Quiet/Verbose.
- [x] 31. Agregar `Write-Verbose` al resolver ruta e identidad.
- [x] 32. Agregar `Write-Verbose` al obtener campos e items.
- [x] 33. Agregar `Write-Verbose` antes de exportar workbook.
- [x] 34. Agregar pruebas para ausencia de registros verbose sin `-Verbose`.
- [x] 35. Agregar pruebas para presencia de registros verbose con `-Verbose`.
- [x] 36. Ejecutar Pester y ScriptAnalyzer.
- [x] 37. Instalar el comando como modulo global compartido tras aprobar pruebas.

### Iteracion 2026-06-19: Listas sin Items

- [x] 38. Ajustar `Export-ExportSpoListToExcelWorkbook` para que una lista sin items genere `.xlsx` con solo encabezados de columnas exportables.
- [x] 39. Asegurar que el resultado PowerShell indique `ItemCount = 0` y `FieldCount` igual a la cantidad de columnas exportables.
- [x] 40. Agregar prueba con `Get-PnPListItem` retornando cero items y campos exportables disponibles.
- [x] 40.1. Agregar prueba con `Get-PnPListItem` lanzando error recuperable de lista vacía y confirmar que se genera workbook solo con encabezados.
- [x] 41. Verificar que el workbook no contiene una fila de datos vacía visible.
- [x] 42. Ejecutar Pester y ScriptAnalyzer.

---

## Criterios de Aceptacion Tecnicos

- [x] El script funciona con contexto activo y `ListTitle`.
- [x] El script funciona con contexto activo y `ListGuid`.
- [x] El script funciona con conexion explicita mediante `SiteUrl`.
- [x] El script valida `.xlsx` y no sobrescribe sin `Force`.
- [x] La salida excluye campos internos de SharePoint segun el filtro aprobado.
- [x] La salida conserva `Title`.
- [x] Si la lista no tiene items, se genera un `.xlsx` con solo encabezados de columnas exportables y `ItemCount = 0`.
- [x] Si la lectura de items falla por error recuperable de lista vacía, se aplica el mismo resultado que una colección vacía.
- [x] Los textos multilinea quedan como valores de celda.
- [x] Fechas y numeros quedan como valores tipados para aplicar formato Excel.
- [x] Tests automatizados cubren contexto activo, conexion explicita, errores, conversiones y llamada a `Export-Excel`.
- [x] No hay operaciones de escritura sobre SharePoint.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-16 | Planning Agent | Dev spec inicial en BORRADOR para `Export-SpoListToExcel`. |
| 0.2.0 | 2026-06-16 | Planning Agent | Cambia estado a APROBADO por aprobacion explicita del usuario para avanzar a implementacion. |
| 0.3.0 | 2026-06-16 | Dev Agent | Marca implementacion y pruebas creadas; deja dev spec en EN_REVISION antes de testing. |
| 0.4.0 | 2026-06-16 | Testing Agent | Marca verificaciones completadas: Pester, ScriptAnalyzer y smoke test. |
| 0.5.0 | 2026-06-18 | Planning Agent | Aprueba plan tecnico para modo Quiet por defecto y mensajes auxiliares via `-Verbose`. |
| 0.6.0 | 2026-06-18 | Dev Agent | Implementa modo Quiet/Verbose, completa TODOs y deja el dev spec en EN_REVISION para Testing. |
| 0.7.0 | 2026-06-19 | Planning Agent | Actualiza dev spec para historia 0.4.0: listas sin items deben generar workbook solo con encabezados. |
| 0.8.0 | 2026-06-19 | Planning Agent | Agrega manejo de error recuperable al leer items de una lista vacía. |






