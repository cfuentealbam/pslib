# Listar nombres internos, visibles y tipos de columnas por identidad de lista - Test

**Estado:** APROBADO

**Desarrollo:** `tools/Get-SpoListColumnNames`
**Historia:** `01-01-list-column-names-and-types-spec.md`
**Dev Spec:** `01-01-list-column-names-and-types-dev-spec.md`
**Retro:** `01-01-list-column-names-and-types-retro.md`
**Fecha:** 2026-06-16
**Testing Agent:** Testing Agent

---

## Alcance de Testing

Se verifico que `Get-SpoListColumnNames` mantenga el contrato existente por `ListGuid`, soporte consulta por `ListTitle`, y descarte campos internos de SharePoint usando el filtro aprobado, con contexto activo o autenticacion explicita mediante `Connect-Spo`.

---

## Resultados

| Verificacion | Resultado | Notas |
|--------------|-----------|-------|
| `Invoke-Pester -Path tests` | APROBADO | 15 passed, 0 failed. |
| `Invoke-ScriptAnalyzer -Path src -Recurse` | APROBADO | Sin hallazgos. |
| `Invoke-ScriptAnalyzer` sobre modulo global | APROBADO | Sin hallazgos. |
| `Test-ModuleManifest` sobre modulo global | APROBADO | Version 0.3.0 valida. |
| Ayuda del script | APROBADO | Muestra parameter sets separados para `ListGuid` y `ListTitle`. |
| Exclusividad de parametros | APROBADO | `ListGuid` y `ListTitle` juntos fallan por parameter set invalido. |

---

## Cobertura Relevante

- Contexto activo con `ListGuid` sin llamar `Connect-Spo`.
- Contexto activo con `ListTitle` sin llamar `Connect-Spo`.
- Conexion explicita con `ListGuid`.
- Conexion explicita con `ListTitle`.
- Error claro cuando falta contexto activo.
- Error claro cuando la lista no existe por GUID o por Title.
- Descarte de campos con `Hidden`, `ReadOnlyField`, `Sealed` o `FromBaseType` verdadero.
- Conservacion de `Title` aunque `FromBaseType` sea verdadero.
- Mapeo `DeviceLogin` a `DeviceCode`.
- Resolucion de `ClientId` y `TenantId` desde variables de entorno.
- Shape de salida con `InternalName`, `DisplayName` y `Type`.
- Verificacion de que no se llama `Connect-PnPOnline` directamente.

---

## Limitaciones

- No se ejecuto smoke test real contra SharePoint Online porque requiere sitio, lista y credenciales reales.
- La ejecucion `Invoke-Pester -Path tests -Output Detailed` no fue compatible con la version local de Pester porque `-Output` es ambiguo; se uso `Invoke-Pester -Path tests`.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-16 | Testing Agent | Registra testing aprobado para soporte de `ListTitle`. |
| 0.2.0 | 2026-06-16 | Testing Agent | Registra testing aprobado para descarte de campos internos y modulo global 0.3.0. |

## Iteracion 2026-06-18: Modo Quiet/Verbose

**Estado:** APROBADO

| Verificacion | Resultado |
|--------------|-----------|
| `Invoke-Pester -Path tests` en `tools/Get-SpoListColumnNames` | 16 passed, 0 failed |
| `Invoke-ScriptAnalyzer` sobre `src/Get-SpoListColumnNames.ps1` | Sin hallazgos |
| Import global disponible `Import-Module Get-SpoListColumnNames -Force` | APROBADO |
| ScriptAnalyzer sobre modulo instalado | Sin hallazgos |

**Criterios validados:** Quiet conserva la salida funcional de columnas sin registros verbose; `-Verbose` muestra mensajes auxiliares de consulta.

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.3.0 | 2026-06-18 | Testing Agent | Aprueba verificacion de modo Quiet/Verbose e importacion del modulo instalado. |
