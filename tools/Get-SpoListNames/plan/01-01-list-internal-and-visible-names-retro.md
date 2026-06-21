# Retro de Implementacion: Get-SpoListNames

**Estado:** EN_REVISION

**Desarrollo:** `tools/Get-SpoListNames`
**Version implementada:** 0.1.0
**Fecha:** 2026-06-12
**Dev Agent:** Dev Agent

---

## Metricas Objetivas

| Metrica | Valor |
|---------|-------|
| Inicio | 2026-06-12 12:00 |
| Fin | 2026-06-12 12:20 |
| Duracion total | 20 min |
| Invocaciones a lint | 1 |
| Invocaciones a test runner | 4 |
| Tests al inicio / al final | 0 / 5 pasando |

---

## Inventario de Cambios

| Archivo | Accion | +Lineas | -Lineas | Notas |
|---------|--------|---------|---------|-------|
| `src/Get-SpoListNames.ps1` | creado | +118 | -0 | entrypoint y logica principal |
| `tests/Get-SpoListNames.Tests.ps1` | creado | +152 | -0 | tests con mocks de PnP |
| `tools/spo-list-names/` -> `tools/Get-SpoListNames/` | renombrado | +0 | -0 | migracion estructural del tool sin cambios funcionales |
| `plan/01-01-list-internal-and-visible-names-dev-spec.md` | modificado | +0 | -0 | TODOs marcados [x] al cierre |
| `plan/01-01-list-internal-and-visible-names-retro.md` | creado | +89 | -0 | retro inicial |

**Resumen:** 4 archivos modificados, +359 / -0 lineas netas.

---

## Errores de Compilacion y Test Encontrados

| # | Clase de error | Archivo:linea | Arreglo aplicado | Intentos fallidos |
|---|----------------|---------------|------------------|-------------------|
| 1 | Compatibilidad Pester | `tests/Get-SpoListNames.Tests.ps1` | Se adapto la suite a Pester 3.4.0, reemplazando sintaxis moderna y usando `param(...)` explicitos en mocks. | La primera version de tests asumia sintaxis y comportamiento de Pester mas nuevo. |
| 2 | Mock de comando base | `src/Get-SpoListNames.ps1:63` | La validacion cambio de `Get-Module` a `Get-Command Connect-PnPOnline` para evitar conflictos de mock con PowerShell 7 + Pester 3. | El mock de `Get-Module` chocaba con variables readonly del entorno. |

---

## Puntos de Friccion

- **Nombre interno de la lista:** Se resolvio usando `EntityTypeName` porque la historia lo aprobo explicitamente.
- **Filtrado de bibliotecas:** Se implemento con `BaseType` para mantener el filtro simple y alineado al dev spec.

---

## Ambiguedades y Elecciones Interpretativas

- **Listas ocultas:** Se excluyeron para mantener una salida operativa y legible, segun el alcance del dev spec.

---

## Resumen Subjetivo

- **Confianza en el resultado (1-5):** 4 - La logica es simple y esta cubierta con mocks, pero falta correr la verificacion en este entorno.
- **Lo mas dificil:** Cerrar una definicion util y consistente de "nombre interno" para listas de SharePoint.
- **Lo mas facil:** La proyeccion de salida y el filtrado de bibliotecas.
- **En que ayudo la herramienta o el proceso:** El dev spec redujo ambiguedades de autenticacion y alcance.
- **En que estorbo:** La verificacion real depende de modulos externos y un tenant accesible.

---

## Limitaciones del Reporte

Pester si pudo ejecutarse y la suite termino con 5 tests pasando. No fue posible ejecutar `Invoke-ScriptAnalyzer` porque no esta instalado en este entorno, ni un smoke test real contra SharePoint Online porque `Connect-PnPOnline` tampoco esta disponible localmente y no se configuro un tenant objetivo para esta iteracion.

---

## Iteracion 2026-06-15: salida GUID, EntityTypeName y Title

**Motivo:** El usuario aprobo cambiar la salida publica de `Get-SpoListNames` para identificar listas por `GUID`, `EntityTypeName` y `Title`.

**Cambios implementados:**

| Archivo | Accion | Notas |
|---------|--------|-------|
| `src/Get-SpoListNames.ps1` | modificado | Consulta `Id` en `Get-PnPList` y proyecta `GUID`, `EntityTypeName`, `Title`. |
| `modules/Get-SpoListNames/Get-SpoListNames.psm1` | modificado | Alinea el modulo reusable con el nuevo contrato de salida. |
| `tests/Get-SpoListNames.Tests.ps1` | modificado | Valida `GUID`, `EntityTypeName`, `Title` e inclusion de `Id`. |
| `tests/Get-SpoListNames.Module.Tests.ps1` | modificado | Valida el contrato del modulo y la conexion explicita. |
| `plan/01-01-list-internal-and-visible-names-dev-spec.md` | modificado | Registra la implementacion y queda en `EN_REVISION` para Testing. |

**Decision relevante:** Se conserva el filtrado vigente de listas ocultas y bibliotecas documentales. El cambio se limita al contrato de columnas devueltas.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-12 | Dev Agent | Retro inicial |
| 0.2.0 | 2026-06-12 | Dev Agent | Actualiza la retro para reflejar la migracion a `tools/Get-SpoListNames` |
| 0.3.0 | 2026-06-12 | Dev Agent | Sincroniza la retro con el cierre de TODOs del dev spec sin cambios funcionales |
| 0.4.0 | 2026-06-12 | Dev Agent | Registra el ajuste documental de `TenantId` y la exposicion de ayuda a nivel de script |
| 0.5.0 | 2026-06-15 | Dev Agent | Registra implementacion de salida `GUID`, `EntityTypeName` y `Title` |
