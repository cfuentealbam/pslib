# Listar nombres internos, visibles y tipos de columnas por identidad de lista - Retro

**Estado:** APROBADO

**Desarrollo:** `tools/Get-SpoListColumnNames`
**Version implementada:** 0.3.0
**Fecha:** 2026-06-16
**Dev Agent:** Dev Agent

---

## Resumen

Se implemento `Get-SpoListColumnNames` como script PowerShell bajo `tools/Get-SpoListColumnNames/src/`. La herramienta usa el contexto activo de `Connect-Spo` o autenticacion explicita, valida la lista por GUID o por `Title` y devuelve columnas con `InternalName`, `DisplayName` y `Type`.

En la version 0.2.0 se agrego `ListTitle` como alternativa mutuamente excluyente a `ListGuid`, permitiendo reutilizar directamente el `Title` desplegado por `Get-SpoListNames`.

En la version 0.3.0 se agrego el descarte de campos internos de SharePoint usando `Hidden`, `ReadOnlyField`, `Sealed` y `FromBaseType`, conservando el campo `Title`.

---

## Inventario de Cambios

| Archivo | Accion | Notas |
|---------|--------|-------|
| `tools/Get-SpoListColumnNames/src/Get-SpoListColumnNames.ps1` | modificado | Entrypoint PowerShell con contexto activo, autenticacion explicita, consulta por GUID o Title y descarte de campos internos. |
| `tools/Get-SpoListColumnNames/tests/Get-SpoListColumnNames.Tests.ps1` | modificado | Pruebas con mocks para contexto activo, conexion explicita, errores, salida, exclusividad de parametros y filtro de campos internos. |
| `tools/Get-SpoListColumnNames/plan/00-get-spo-list-column-names-spec.md` | modificado | Actualiza alcance aprobado para admitir Title. |
| `tools/Get-SpoListColumnNames/plan/01-list-column-discovery-spec.md` | modificado | Actualiza epica para admitir Title. |
| `tools/Get-SpoListColumnNames/plan/01-01-list-column-names-and-types-spec.md` | modificado | Actualiza historia para admitir `ListTitle`. |
| `tools/Get-SpoListColumnNames/plan/01-01-list-column-names-and-types-dev-spec.md` | modificado | Actualiza diseno tecnico para resolver una identidad de lista unica y filtrar campos internos. |
| `C:\Users\Carlos Fuentealba\OneDrive - GLOBE SA\Documentos\PowerShell\Modules\Get-SpoListColumnNames` | modificado | Sincroniza el modulo global instalado a version 0.3.0. |

---

## Verificaciones

- `Invoke-Pester -Path tests` desde `tools/Get-SpoListColumnNames`: 15 passed, 0 failed.
- `Invoke-ScriptAnalyzer -Path src -Recurse` desde `tools/Get-SpoListColumnNames`: sin hallazgos.
- `Invoke-ScriptAnalyzer -Path "C:\Users\Carlos Fuentealba\OneDrive - GLOBE SA\Documentos\PowerShell\Modules\Get-SpoListColumnNames" -Recurse`: sin hallazgos.
- `Test-ModuleManifest` del modulo global: version 0.3.0 valida.
- `pwsh -NoLogo -NoProfile -File ./src/Get-SpoListColumnNames.ps1 -?`: ayuda cargada correctamente y muestra parameter sets por `ListGuid` y `ListTitle`.
- `pwsh -NoLogo -NoProfile -Command "& './src/Get-SpoListColumnNames.ps1' -ListGuid '<guid>' -ListTitle 'Incidentes'"`: falla por combinacion invalida de parameter sets.

---

## Limitaciones

- No se ejecuto consulta real contra SharePoint porque requiere sitio, lista y credenciales reales.
- La primera historia no crea modulo bajo `modules/`; el consumo actual es como script en `tools/Get-SpoListColumnNames/src/`.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-15 | Dev Agent | Retro de implementacion inicial de `Get-SpoListColumnNames`. |
| 0.2.0 | 2026-06-16 | Dev Agent | Registra implementacion de consulta por `ListTitle` y verificaciones actualizadas. |
| 0.3.0 | 2026-06-16 | Dev Agent | Registra implementacion del filtro de campos internos y sincronizacion del modulo global. |

## Iteracion 2026-06-18: Modo Quiet/Verbose

**Cambios implementados:**

- `src/Get-SpoListColumnNames.ps1` emite mensajes auxiliares solo con `Write-Verbose`.
- Se agrego cobertura Pester para Quiet por defecto y `-Verbose`.
- Se genero modulo instalable desde el script y se sincronizo en la biblioteca global disponible del usuario.

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.4.0 | 2026-06-18 | Dev Agent | Registra implementacion de modo Quiet/Verbose e instalacion global disponible. |
