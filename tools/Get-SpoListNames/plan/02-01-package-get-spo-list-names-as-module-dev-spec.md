# Dev Spec: Empaquetar Get-SpoListNames como modulo PowerShell no compilado

**Estado:** EN_REVISION

**Desarrollo:** `modules/Get-SpoListNames`
**Producto:** `00-spo-list-names-spec.md`
**Epica:** `02-powershell-module-packaging-spec.md`
**Historia:** `02-01-package-get-spo-list-names-as-module-spec.md`
**Basado en story spec version:** 0.2.0
**Fecha:** 2026-06-12

---

## Alcance Tecnico de Esta Historia

Esta historia agrega un modulo PowerShell de script no compilado bajo `modules/Get-SpoListNames/` para exponer el comando publico `Get-SpoListNames` mediante `Import-Module`, preservando el comportamiento funcional ya aprobado e implementado en `tools/Get-SpoListNames/src/Get-SpoListNames.ps1`.

La implementacion no debe modificar el comportamiento del script existente ni convertirlo en dependencia ejecutable del modulo. El modulo debe poder importarse desde ruta local del repositorio y, si el usuario lo decide, instalarse manualmente por copia a una ubicacion incluida en `$env:PSModulePath`.

Queda fuera de esta historia:

- Publicacion en PowerShell Gallery.
- Instalador MSI u otro instalador del sistema.
- Modulo binario, compilado o cmdlet .NET propio.
- Cambios bajo `mcp/`.
- Instalacion automatica, modificacion persistente de `$env:PSModulePath` o cambios al perfil del usuario.
- Cambios funcionales al descubrimiento de listas fuera de `01-01-list-internal-and-visible-names-spec.md`.

---

## Investigacion y Decisiones

### Recursos / Patrones Relevantes

| Recurso / Patron | Referencia | Hallazgo usado en el diseno |
|------------------|------------|-----------------------------|
| Modulos de script PowerShell | Microsoft Learn `about_Modules` | Un modulo de script se implementa en `.psm1` y puede exportar funciones a la sesion. |
| Importacion de modulos | Microsoft Learn `Import-Module` | `Import-Module` carga miembros exportados desde ruta o nombre de modulo. |
| Manifiestos de modulo | Microsoft Learn `New-ModuleManifest` / `about_Module_Manifests` | Un `.psd1` en la raiz del modulo describe version, `RootModule`, funciones exportadas y requisitos. |
| Funcion existente | `tools/Get-SpoListNames/src/Get-SpoListNames.ps1` | El script contiene una funcion `Get-SpoListNames`, pero tambien invoca `Get-SpoListNames @PSBoundParameters` al final; dot-sourcearlo desde el modulo ejecutaria el entrypoint y no es seguro. |

### Alternativas Evaluadas

| Alternativa | Pros | Contras | Decision |
|-------------|------|---------|----------|
| Dot-source directo de `tools/Get-SpoListNames/src/Get-SpoListNames.ps1` desde `.psm1` | Reutilizacion textual total del archivo existente. | Ejecuta el entrypoint del script al importar por la llamada final `Get-SpoListNames @PSBoundParameters`; podria fallar importacion, pedir parametros o cambiar comportamiento del script. | Descartada. |
| Refactorizar el script para extraer la funcion compartida a un archivo comun | Evita duplicacion y centraliza mantenimiento. | Requiere editar el script existente y revalidar la historia 01-01; no es inevitable para esta historia y aumenta riesgo. | Descartada para esta historia. |
| Implementar la funcion publica en `Get-SpoListNames.psm1` copiando/adaptando la logica aprobada del script | No rompe el script existente; mantiene modulo autocontenido; satisface importacion y ayuda. | Duplica la logica funcional y exige mantener equivalencia mediante tests/verificaciones. | Elegida. |

### Dependencias Seleccionadas

```text
PowerShell 7.4+                 # runtime aprobado para pslib y modulos de script
PnP.PowerShell >= 2.0.0         # dependencia funcional ya usada para Connect-PnPOnline y Get-PnPList
Pester                          # verificacion automatizada si esta disponible en el entorno
PSScriptAnalyzer                # analisis estatico si esta disponible en el entorno
```

Justificacion:

- No se agrega una dependencia nueva para empaquetado; manifiesto y `.psm1` usan capacidades nativas de PowerShell.
- `PnP.PowerShell` se conserva como dependencia funcional de ejecucion del comando, pero el manifiesto no debe declararlo en `RequiredModules` para no impedir `Import-Module`, `Get-Command` ni `Get-Help` en entornos donde solo se quiere verificar el paquete. La funcion mantiene la validacion runtime existente y falla con mensaje claro si falta `Connect-PnPOnline`.
- Pester y PSScriptAnalyzer son herramientas de verificacion, no dependencias runtime del modulo.

---

## Estructura Objetivo

```text
pslib/
|- modules/
|  `- Get-SpoListNames/
|     |- Get-SpoListNames.psd1      # manifiesto del modulo
|     `- Get-SpoListNames.psm1      # modulo de script no compilado
`- tools/
   `- Get-SpoListNames/
      |- plan/
      |  `- 02-01-package-get-spo-list-names-as-module-dev-spec.md
      |- src/
      |  `- Get-SpoListNames.ps1    # script existente; no modificar en esta historia salvo bloqueo inevitable
      `- tests/
         |- Get-SpoListNames.Tests.ps1
         `- Get-SpoListNames.Module.Tests.ps1
```

Notas:

- Los artefactos de proceso permanecen en `tools/Get-SpoListNames/plan/`.
- El modulo vive en `modules/Get-SpoListNames/` como aprueban producto, epica e historia.
- El archivo de tests de modulo se ubica bajo `tools/Get-SpoListNames/tests/` para mantener las pruebas del producto junto a la herramienta incubada.

---

## Diseno del Manifiesto `.psd1`

Archivo objetivo: `modules/Get-SpoListNames/Get-SpoListNames.psd1`.

Campos requeridos o esperados:

```powershell
@{
    RootModule        = 'Get-SpoListNames.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '<GUID estable generado durante implementacion>'
    Author            = 'pslib'
    CompanyName       = 'Aucar Ltda'
    Copyright         = '(c) 2026 Aucar Ltda. All rights reserved.'
    Description       = 'Modulo PowerShell no compilado para listar nombres internos y visibles de listas no documentales en SharePoint Online.'
    PowerShellVersion = '7.4'
    FunctionsToExport = @('Get-SpoListNames')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('SharePoint', 'PnP.PowerShell', 'Lists')
            ProjectUri = ''
        }
    }
}
```

Boundaries:

- `RootModule` debe apuntar al `.psm1` local.
- `FunctionsToExport` debe limitarse a `Get-SpoListNames`.
- No declarar `NestedModules`, `RequiredAssemblies`, `ScriptsToProcess` ni artefactos compilados.
- No declarar `RequiredModules = @('PnP.PowerShell')` en esta historia, para permitir importacion y consulta de ayuda sin dependencia instalada.

---

## Diseno del Modulo `.psm1`

Archivo objetivo: `modules/Get-SpoListNames/Get-SpoListNames.psm1`.

### API Publica

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

Contrato:

- Entrada `SiteUrl`: URL absoluta HTTPS del sitio SharePoint Online.
- Entrada `AuthMode`: `Interactive` o `DeviceLogin`, con default `Interactive`.
- Entrada `ClientId`: opcional si se resuelve desde `ENTRAID_APP_ID`, `ENTRAID_CLIENT_ID` o `AZURE_CLIENT_ID`.
- Entrada `TenantId`: requerido solo para `DeviceLogin` si no existe `AZURE_TENANT_ID`.
- Salida: objetos con propiedades `InternalName` y `VisibleTitle`, equivalentes al script aprobado.
- Errores: mensajes claros para modulo PnP faltante, `ClientId` faltante, `TenantId` faltante en DeviceLogin, fallo de conexion y fallo de consulta.

### Helpers Internos

No se requieren helpers publicos. Si durante implementacion se separa logica interna por legibilidad, las funciones deben permanecer privadas y no exportarse. Firmas permitidas:

```powershell
function Resolve-SpoListNamesClientId {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ClientId
    )
}

function Resolve-SpoListNamesTenantId {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$TenantId
    )
}
```

Estas funciones, si se implementan, deben devolver `string` o lanzar un error claro. No deben exportarse en `Export-ModuleMember` ni en el manifiesto.

### Exportacion

El `.psm1` debe finalizar con:

```powershell
Export-ModuleMember -Function 'Get-SpoListNames'
```

### Ayuda

La funcion publica en el `.psm1` debe incluir ayuda basada en comentarios compatible con `Get-Help Get-SpoListNames`, al menos con:

- `.SYNOPSIS`
- `.DESCRIPTION`
- `.PARAMETER SiteUrl`
- `.PARAMETER AuthMode`
- `.PARAMETER ClientId`
- `.PARAMETER TenantId`
- `.OUTPUTS`
- `.EXAMPLE`

---

## Reutilizacion Segura de la Logica Existente

La implementacion debe tomar como fuente funcional `tools/Get-SpoListNames/src/Get-SpoListNames.ps1`, especificamente la funcion interna `Get-SpoListNames`, y reproducir su contrato y comportamiento en el `.psm1`.

Reglas:

- No dot-sourcear el `.ps1` desde el modulo, porque el script ejecuta el entrypoint al final y eso haria insegura la importacion.
- No editar el `.ps1` existente en esta historia salvo que una verificacion demuestre que es inevitable; si ocurre, se debe detener e informar antes de ampliar alcance.
- Mantener equivalencia observable con el script para:
  - resolucion de `ClientId` desde parametro o variables `ENTRAID_APP_ID`, `ENTRAID_CLIENT_ID`, `AZURE_CLIENT_ID`;
  - resolucion de `TenantId` para `DeviceLogin` desde parametro o `AZURE_TENANT_ID`;
  - uso de `Connect-PnPOnline` con `ValidateConnection`;
  - consulta con `Get-PnPList -Includes 'EntityTypeName', 'Title', 'Hidden', 'BaseType'`;
  - exclusion de listas ocultas y bibliotecas documentales;
  - proyeccion `InternalName = EntityTypeName`, `VisibleTitle = Title`;
  - ordenamiento por titulo visible.

---

## Instalacion y Carga Operativa

La historia no debe automatizar instalacion persistente. El resultado debe permitir estas formas manuales:

### Carga local desde el repositorio

```powershell
Import-Module "<repo>\modules\Get-SpoListNames\Get-SpoListNames.psd1" -Force
Get-Command Get-SpoListNames
Get-Help Get-SpoListNames
```

### Instalacion para usuario actual por copia

```powershell
$destination = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules\Get-SpoListNames'
Copy-Item -Path "<repo>\modules\Get-SpoListNames" -Destination $destination -Recurse -Force
Import-Module Get-SpoListNames -Force
```

### Instalacion global por copia administrativa

```powershell
$destination = Join-Path $PSHOME 'Modules\Get-SpoListNames'
Copy-Item -Path "<repo>\modules\Get-SpoListNames" -Destination $destination -Recurse -Force
Import-Module Get-SpoListNames -Force
```

Notas:

- La instalacion global puede requerir PowerShell elevado y no debe ejecutarse automaticamente.
- Alternativamente, el usuario puede ubicar `modules/Get-SpoListNames/` en cualquier directorio ya presente en `$env:PSModulePath`.
- No modificar `$env:PSModulePath` de forma persistente ni editar perfiles en esta historia.

---

## TODOs Atomicos de Implementacion

- [x] `1.` Verificar que `tools/Get-SpoListNames/src/Get-SpoListNames.ps1` existe y conservarlo sin cambios funcionales.
- [x] `2.` Crear directorio `modules/Get-SpoListNames/` si no existe.
- [x] `3.` Crear `modules/Get-SpoListNames/Get-SpoListNames.psd1` con `RootModule = 'Get-SpoListNames.psm1'`, `PowerShellVersion = '7.4'` y `FunctionsToExport = @('Get-SpoListNames')`.
- [x] `4.` Generar un GUID estable para el manifiesto y registrarlo en `GUID`.
- [x] `5.` Crear `modules/Get-SpoListNames/Get-SpoListNames.psm1` con Control de Cambios PowerShell al inicio.
- [x] `6.` Implementar en el `.psm1` la funcion publica `Get-SpoListNames` con la firma completa definida en este dev spec.
- [x] `7.` Agregar ayuda basada en comentarios dentro de la funcion publica para que `Get-Help Get-SpoListNames` muestre informacion util.
- [x] `8.` Copiar/adaptar la logica aprobada del script existente al `.psm1` sin dot-sourcear ni ejecutar el `.ps1`.
- [x] `9.` Mantener la validacion runtime de dependencia y mensaje accionable mediante `Connect-Spo`.
- [x] `10.` Mantener la resolucion de `ClientId` desde parametro, `ENTRAID_APP_ID`, `ENTRAID_CLIENT_ID` y `AZURE_CLIENT_ID`.
- [x] `11.` Mantener la resolucion de `TenantId` desde parametro o `AZURE_TENANT_ID`.
- [x] `12.` Mantener conexion, consulta, filtrado, proyeccion y ordenamiento equivalentes al script aprobado.
- [x] `13.` Exportar solamente `Get-SpoListNames` con `Export-ModuleMember` y con `FunctionsToExport` en el manifiesto.
- [x] `14.` Crear o actualizar `tools/Get-SpoListNames/tests/Get-SpoListNames.Module.Tests.ps1` para validar importacion por manifiesto y exportacion del comando.
- [x] `15.` Agregar pruebas de ayuda que verifiquen que `Get-Help Get-SpoListNames` devuelve synopsis o parametros esperados tras importar el modulo.
- [x] `16.` Agregar pruebas funcionales con mocks, si Pester esta disponible, para confirmar que el modulo conserva exclusion de ocultas/bibliotecas y proyeccion `InternalName`/`VisibleTitle`.
- [x] `17.` Ejecutar verificaciones locales definidas en este dev spec y documentar resultados en la retro de implementacion.
- [x] `18.` No instalar el modulo en ubicaciones de usuario o globales hasta que el usuario lo apruebe explicitamente despues del dev spec.

---

## Verificaciones de Implementacion y Testing

Ejecutar desde la raiz del repositorio salvo indicacion contraria.

### Verificaciones del modulo

```powershell
Test-ModuleManifest -Path .\modules\Get-SpoListNames\Get-SpoListNames.psd1
Import-Module .\modules\Get-SpoListNames\Get-SpoListNames.psd1 -Force
Get-Command Get-SpoListNames
Get-Help Get-SpoListNames
```

### Analisis estatico

```powershell
Invoke-ScriptAnalyzer -Path .\modules\Get-SpoListNames -Recurse
```

Si corresponde, mantener tambien el analisis del script existente:

```powershell
Invoke-ScriptAnalyzer -Path .\tools\Get-SpoListNames\src -Recurse
```

### Pester

Desde `tools/Get-SpoListNames`:

```powershell
Invoke-Pester -Path tests -Output Detailed
```

Las pruebas automatizadas no deben requerir conexion real a SharePoint. Deben mockear comandos PnP cuando validen comportamiento funcional.

### Smoke test funcional opcional

Solo si el entorno tiene `PnP.PowerShell`, credenciales y variables necesarias:

```powershell
Import-Module .\modules\Get-SpoListNames\Get-SpoListNames.psd1 -Force
Get-SpoListNames -SiteUrl $env:SPO_SITE_URL -AuthMode Interactive -ClientId $env:ENTRAID_APP_ID
```

Si no existe sitio o credenciales disponibles, documentar la limitacion ambiental en la retro y considerar suficiente la importacion, ayuda, comandos exportados y tests con mocks.

---

## Criterios de Aceptacion Tecnicos

- [ ] Existe `modules/Get-SpoListNames/Get-SpoListNames.psd1` y `Test-ModuleManifest` pasa.
- [ ] Existe `modules/Get-SpoListNames/Get-SpoListNames.psm1` y es PowerShell no compilado.
- [ ] `Import-Module .\modules\Get-SpoListNames\Get-SpoListNames.psd1 -Force` carga el modulo desde el repositorio.
- [ ] `Get-Command Get-SpoListNames` muestra el comando exportado desde el modulo.
- [ ] `Get-Help Get-SpoListNames` muestra ayuda basada en comentarios del comando.
- [ ] El manifiesto exporta solo `Get-SpoListNames` y no referencia ensamblados, binarios ni instaladores.
- [ ] El script `tools/Get-SpoListNames/src/Get-SpoListNames.ps1` sigue funcionando como script independiente y no se rompe por el empaquetado.
- [ ] Tests o mocks confirman equivalencia funcional basica con la historia 01-01.
- [ ] No hay cambios bajo `mcp/`.
- [ ] No se publica en PSGallery ni se crea instalador MSI.

---

## Riesgos y Mitigaciones

| Riesgo | Mitigacion |
|--------|------------|
| Divergencia entre script y modulo por duplicacion de logica. | Tests con mocks sobre el modulo y comparacion manual de contrato con el script existente durante implementacion. |
| `Import-Module` falla si se fuerza dependencia PnP en manifiesto. | No declarar `PnP.PowerShell` en `RequiredModules`; validar en runtime dentro de la funcion. |
| Ayuda no aparece con `Get-Help` por ubicacion incorrecta del bloque de ayuda. | Colocar ayuda basada en comentarios inmediatamente antes o dentro de la funcion publica segun reglas de PowerShell y verificar con `Get-Help`. |
| Instalacion global requiere permisos elevados. | No automatizar; documentar comandos de copia y advertir requisito administrativo. |

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-12 | Planning Agent | Dev spec inicial para empaquetar `Get-SpoListNames` como modulo PowerShell no compilado |
| 0.2.0 | 2026-06-14 | Implementation Agent | Marca implementacion y verificaciones completadas para el modulo `Get-SpoListNames`. |
