# Epic Spec: Exportación Excel de lista SharePoint

**Estado:** APROBADO

**Herramienta:** `Export-SpoListToExcel`
**Producto:** `00-export-spo-list-to-excel-spec.md`
**Épica:** `01-excel-list-export`
**Fecha de Discovery:** 2026-06-16

---

## Objetivo de la Épica

Permitir que el operador exporte los ítems de una lista SharePoint Online a un archivo `.xlsx`, usando columnas desplegables y formatos compatibles con Excel para texto multilínea, fechas y números. Si la lista no tiene ítems, el archivo debe generarse igualmente con los encabezados de las columnas exportables, aun cuando la lectura de ítems exponga esa condición como error recuperable.

---

## Valor Operativo

- Evita problemas de CSV con saltos de línea en campos de texto multilínea.
- Entrega un archivo directamente utilizable por usuarios de Excel.
- Reutiliza el criterio de campos operativos ya aprobado para `Get-SpoListColumnNames`.
- Reduce ruido de campos internos de SharePoint en las exportaciones.

---

## Historias Incluidas

| ID | Historia | Spec | Estado |
|----|----------|------|--------|
| 01-01 | Exportar ítems de lista SharePoint a `.xlsx` | `01-01-export-list-items-to-xlsx-spec.md` | APROBADO |

---

## Dependencias Funcionales

- El operador debe tener acceso de lectura al sitio y lista SharePoint objetivo.
- La lista objetivo debe existir dentro del sitio conectado o indicado y poder resolverse por GUID o por `Title`.
- La herramienta debe consumir autenticación mediante `Connect-Spo`.
- Si no se entrega `SiteUrl`, debe existir contexto SharePoint activo de sesión creado por `Connect-Spo`.
- El archivo de salida debe poder escribirse en la ruta indicada por el operador.

---

## Fuera de Alcance de la Épica

- Exportar otros formatos distintos de `.xlsx`.
- Modificar datos de SharePoint.
- Exportar múltiples listas en una ejecución.
- Exportar adjuntos.
- Crear empaquetado como módulo PowerShell.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-16 | Discovery Agent | Epic spec inicial para exportación Excel de lista SharePoint. |
| 0.2.0 | 2026-06-16 | Discovery Agent | Cambia estado a APROBADO por aprobacion explicita del usuario para pasar a Planning. |
| 0.3.0 | 2026-06-19 | Spec Design Agent | Explicita que listas vacías generan `.xlsx` con encabezados de columnas exportables. |
| 0.4.0 | 2026-06-19 | Spec Design Agent | Aclara manejo de error recuperable al leer ítems de una lista vacía. |





