# Epic Spec: Descubrimiento de listas del sitio

**Estado:** APROBADO

**Herramienta:** `Get-SpoListNames`
**Producto:** `00-spo-list-names-spec.md`
**Epica:** `01-site-list-discovery`
**Fecha de Discovery:** 2026-06-12

---

## Objetivo de la Epica

Permitir que el operador consulte un sitio de SharePoint y obtenga un listado utilizable de sus listas no documentales, identificadas tanto por su nombre interno como por su titulo visible.

---

## Valor para el Usuario

Reduce errores al referenciar listas en scripts, soporte e integraciones, y evita tener que descubrir manualmente la relacion entre el nombre mostrado en SharePoint y el nombre interno real.

---

## Historias de Usuario

| ID | Titulo | Archivo | Estado |
|----|--------|---------|--------|
| 01-01 | Listar nombres internos y visibles de listas del sitio | `01-01-list-internal-and-visible-names-spec.md` | APROBADO |
| 01-02 | Consumir autenticacion unificada mediante modulo Connect-Spo | `01-02-consume-connect-spo-module-for-authentication-spec.md` | APROBADO |

---

## Dependencias Funcionales

- El operador debe poder identificar el sitio de SharePoint objetivo.
- El sitio objetivo debe ser accesible en modo lectura para el contexto con que se ejecute el script.
- Para autenticacion SharePoint unificada, la tool debe consumir el modulo `Connect-Spo` por nombre y no mediante rutas relativas a `tools/Connect-Spo`.

---

## Fuera de Alcance de la Epica

- Descubrir listas en multiples sitios en una sola ejecucion.
- Exportar resultados a formatos externos como CSV, JSON o Excel.

---

## Notas de Discovery

- La epica se limita a descubrimiento y listado; no cubre administracion de listas.
- La primera iteracion prioriza una salida simple y legible para el operador.
- Los archivos de plan viven en `tools/Get-SpoListNames/plan/`; el nombre logico vigente de la herramienta es `Get-SpoListNames`.
- El empaquetado como modulo se cubre en la epica `02-powershell-module-packaging-spec.md`; esta epica mantiene el alcance funcional de consulta de listas.
- La historia `01-02` cubre la adopcion funcional de `Connect-Spo` como dependencia de modulo para autenticacion, sin cambiar los datos de salida aprobados para listas.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-12 | Discovery Agent | Epic spec inicial |
| 0.2.0 | 2026-06-12 | Spec Design Agent | Cambia el nombre logico de herramienta de `spo-list-names` a `Get-SpoListNames`; mantiene nombres de archivos/ruta de plan historicos y alcance funcional sin cambios |
| 0.3.0 | 2026-06-12 | Dev Agent | Actualiza la referencia de ruta tras la migracion estructural a `tools/Get-SpoListNames` |
| 0.4.0 | 2026-06-12 | Spec Design Agent | Aclara que el empaquetado como modulo se cubre en una epica separada y marca la epica EN_REVISION |
| 0.5.0 | 2026-06-14 | Spec Design Agent | Agrega historia `01-02` para consumir autenticacion mediante modulo `Connect-Spo` por nombre. |
| 0.6.0 | 2026-06-14 | Spec Design Agent | Cambia estado a APROBADO y marca historia 01-02 como APROBADO por aprobacion explicita del usuario para pasar a Planning. |
