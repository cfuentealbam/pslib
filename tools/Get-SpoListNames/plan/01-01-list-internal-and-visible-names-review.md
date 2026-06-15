# Revision Critica: Listar nombres internos y visibles de listas del sitio

**Estado:** APROBADO

**Desarrollo:** `tools/Get-SpoListNames`
**Historia:** `01-01-list-internal-and-visible-names-spec.md`
**Dev Spec:** `01-01-list-internal-and-visible-names-dev-spec.md`
**Test Report:** `01-01-list-internal-and-visible-names-test.md`
**Fecha:** 2026-06-12
**Agente:** Critical Review Agent

---

## Alcance Revisado

- Producto: `00-spo-list-names-spec.md`
- Epica: `01-site-list-discovery-spec.md`
- Historia: `01-01-list-internal-and-visible-names-spec.md`
- Dev spec: `01-01-list-internal-and-visible-names-dev-spec.md`
- Reporte de testing: `01-01-list-internal-and-visible-names-test.md`
- Codigo fuente: `src/Get-SpoListNames.ps1`
- Tests: `tests/Get-SpoListNames.Tests.ps1`

---

## Verificacion Ejecutada en Revision

Desde `tools/Get-SpoListNames`:

```powershell
Invoke-Pester -Path tests
# Passed: 7 Failed: 0

Invoke-ScriptAnalyzer -Path src -Recurse
# Warning: PSUseSingularNouns en src/Get-SpoListNames.ps1:27

# Smoke test equivalente con Connect-PnPOnline/Get-PnPList stubbed
# Resultado: salida ordenada con InternalName/VisibleTitle y exclusion de DocumentLibrary
```

---

## Evaluacion

### Correctitud

La implementacion cumple los criterios funcionales de la historia: recibe un sitio, consulta listas mediante PnP, excluye bibliotecas documentales y listas ocultas, y emite objetos con `InternalName` derivado de `EntityTypeName` y `VisibleTitle` derivado de `Title`. El manejo de errores cubre modulo/comandos faltantes, `ClientId` no resuelto, fallo de conexion y fallo de consulta.

### Diseno

El diseno se mantiene acotado a un script PowerShell con entrypoint claro, sin agregar exportaciones ni dependencias no aprobadas. El uso de `Connect-PnPOnline -ValidateConnection` y `Get-PnPList -Includes` coincide con el dev spec.

### Calidad y Mantenibilidad

Los tests cubren flujo nominal, exclusiones, resolucion de credenciales de aplicacion y errores relevantes. Quedan observaciones no bloqueantes sobre consistencia de documentacion tecnica y ayuda descubierta por `Get-Help`.

### Seguridad

La herramienta es de lectura. No registra secretos ni escribe artefactos externos. `ClientId` y `TenantId` se tratan como parametros/configuracion, no como secretos.

---

## Hallazgos

### Bloqueantes

No se identificaron hallazgos bloqueantes.

### Recomendados

1. **Dev spec no refleja todo el contrato publico implementado**
   - **Archivo:** `tools/Get-SpoListNames/plan/01-01-list-internal-and-visible-names-dev-spec.md`
   - **Linea:** 82
   - **Patron:** La API publica documentada incluye `SiteUrl`, `AuthMode` y `ClientId`, pero el script implementa ademas `TenantId` en `src/Get-SpoListNames.ps1:23` para `DeviceLogin`.
   - **Alternativa concreta:** En una actualizacion documental, agregar `[string]$TenantId` como parametro opcional en la seccion API Publica y documentar que se resuelve desde `AZURE_TENANT_ID` cuando `AuthMode` es `DeviceLogin`.

2. **Ayuda basada en comentarios no queda expuesta por `Get-Help` del script**
   - **Archivo:** `tools/Get-SpoListNames/src/Get-SpoListNames.ps1`
   - **Linea:** 48
   - **Patron:** El bloque de ayuda esta dentro de la funcion despues del bloque `param`, mientras que el entrypoint publico real es el script con parametros en lineas 7-25; `Get-Help ./src/Get-SpoListNames.ps1 -Full` solo muestra sintaxis generada.
   - **Alternativa concreta:** Mover o duplicar la ayuda basada en comentarios al inicio del script antes del `param` de nivel script, manteniendo los parametros `SiteUrl`, `AuthMode`, `ClientId` y `TenantId` documentados.

### Menores

1. **Advertencia conocida de ScriptAnalyzer por nombre plural**
   - **Archivo:** `tools/Get-SpoListNames/src/Get-SpoListNames.ps1`
   - **Linea:** 27
   - **Patron:** `PSUseSingularNouns` advierte que `Get-SpoListNames` usa noun plural.
   - **Alternativa concreta:** Mantener el nombre porque esta aprobado por producto/historia; si se exige salida limpia de ScriptAnalyzer, agregar una supresion local justificada o configuracion de regla para esta herramienta.

---

## Decision Final

**Estado:** APROBADO

**Justificacion:** No hay bloqueantes. La implementacion cumple la historia y el dev spec en el comportamiento observable, las pruebas automatizadas pasan y el smoke test equivalente confirma la salida esperada. Los hallazgos restantes son de consistencia documental/calidad no funcional y no requieren refactoring minimo antes de avanzar.

**Proximo paso:** Avanzar a Documentacion de la herramienta.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-12 | Critical Review Agent | Revision critica formal de la historia y aprobacion sin bloqueantes |
