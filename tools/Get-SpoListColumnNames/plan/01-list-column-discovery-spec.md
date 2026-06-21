# Epic Spec: Descubrimiento de columnas de lista

**Estado:** APROBADO

**Herramienta:** `Get-SpoListColumnNames`
**Producto:** `00-get-spo-list-column-names-spec.md`
**Epica:** `01-list-column-discovery`
**Fecha de Discovery:** 2026-06-15

---

## Objetivo de la Epica

Permitir que el operador consulte una lista SharePoint Online por GUID o por el `Title` mostrado por `Get-SpoListNames` y obtenga un inventario utilizable de sus columnas desplegables, identificadas por nombre interno, nombre visible y tipo.

---

## Valor Operativo

- Reduce errores al usar columnas en scripts o integraciones.
- Permite distinguir columnas renombradas de sus nombres internos reales.
- Facilita revisar rapidamente la estructura de una lista antes de automatizar operaciones sobre ella.

---

## Historias Incluidas

| ID | Historia | Spec | Estado |
|----|----------|------|--------|
| 01-01 | Listar nombres internos, visibles y tipos de columnas por GUID de lista | `01-01-list-column-names-and-types-spec.md` | APROBADO |

---

## Dependencias Funcionales

- El operador debe tener acceso de lectura al sitio SharePoint objetivo.
- La lista objetivo debe existir dentro del sitio conectado o indicado y poder resolverse por GUID o por `Title`.
- Las columnas devueltas deben descartar campos internos de SharePoint con el filtro aprobado sobre `Hidden`, `ReadOnlyField`, `Sealed` y `FromBaseType`, conservando `Title`.
- La herramienta debe consumir autenticacion mediante `Connect-Spo`.
- Si no se entrega `SiteUrl`, debe existir contexto SharePoint activo de sesion creado por `Connect-Spo`.

---

## Fuera de Alcance de la Epica

- Modificar columnas.
- Leer datos de items.
- Consolidar multiples listas.
- Crear empaquetado como modulo PowerShell.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-15 | Discovery Agent | Epic spec inicial para descubrimiento de columnas de lista. |
| 0.2.0 | 2026-06-16 | Spec Design Agent | Aprueba consultar columnas usando el Title de lista mostrado por `Get-SpoListNames`. |
| 0.3.0 | 2026-06-16 | Spec Design Agent | Aprueba descartar campos internos de SharePoint y conservar `Title`. |
