# Export-SpoListToExcel - Product Spec

**Estado:** APROBADO

**Herramienta:** `Export-SpoListToExcel`
**Fecha de Discovery:** 2026-06-16

---

## Producto

`Export-SpoListToExcel` es una herramienta PowerShell para exportar el contenido de una lista SharePoint Online a un archivo Excel moderno `.xlsx`, usando solo los campos desplegables de la lista.

---

## Problema

Cuando una lista SharePoint contiene campos de texto multilínea, exportar a CSV puede producir archivos frágiles para usuarios o procesos que no manejan correctamente comillas y saltos de línea. El operador necesita una exportación tabular a Excel real donde cada valor quede en su celda, incluyendo textos multilínea, fechas y números con formato legible.

---

## Usuarios

- Administrador u operador de SharePoint Online.
- Responsable de soporte o automatización que necesita entregar datos de listas a usuarios finales.
- Integrador que requiere una copia inspeccionable de datos de una lista con columnas operativas.

---

## Alcance

- Trabajar sobre una sola lista SharePoint Online por ejecución.
- Identificar la lista objetivo por GUID o por el `Title` mostrado por `Get-SpoListNames`.
- Exportar solo a formato `.xlsx`.
- Exportar únicamente campos desplegables usando la misma lógica funcional aprobada para `Get-SpoListColumnNames`:

```powershell
Where-Object {
    -not $_.Hidden -and
    -not $_.ReadOnlyField -and
    -not $_.Sealed -and
    (-not $_.FromBaseType -or $_.InternalName -eq 'Title')
}
```

- Mantener textos multilínea dentro de la celda correspondiente del archivo Excel.
- Si la lista no tiene ítems, crear igualmente el archivo `.xlsx` con una hoja que contenga solo los encabezados de las columnas exportables, incluso cuando la lectura de ítems reporte esa condición como error recuperable de lista vacía.
- Mostrar campos de fecha con formato `dd-MM-yyyy`.
- Mostrar campos numéricos con separador decimal y sin separador de miles.
- Usar el contexto SharePoint activo de sesión registrado por `Connect-Spo` cuando el operador no entregue parámetros de conexión.
- Permitir `SiteUrl`, `TenantId`, `ClientId` y `AuthMode` explícitos para mantener el contrato de autenticación de las tools SharePoint existentes.
- Sobrescribir el archivo de salida solo cuando el operador lo solicite explícitamente.
- Funcionar en modo Quiet por defecto, sin mensajes auxiliares de estado, progreso o diagnóstico salvo que el operador indique `-Verbose`.
- Mantener en modo Quiet la salida funcional aprobada del comando, es decir la creación del archivo `.xlsx` y el resultado PowerShell de exportación, además de errores o prompts necesarios para completar la operación.

---

## Fuera de Alcance

- Exportar a CSV, JSON, XML, `.xls` u otros formatos.
- Exportar múltiples listas en una sola ejecución.
- Crear, modificar o eliminar ítems, listas o columnas.
- Exportar archivos adjuntos de ítems.
- Aplicar filtros por CAML, OData o vistas de SharePoint.
- Transformaciones de negocio sobre los datos.
- Crear un módulo bajo `modules/` en la primera historia.
- Cambios bajo `mcp/`.

---

## Restricciones

- La herramienta debe ser PowerShell y vivir bajo `tools/Export-SpoListToExcel`.
- Los artefactos de proceso viven en `tools/Export-SpoListToExcel/plan/`.
- La salida debe ser un archivo `.xlsx`.
- La lista objetivo se identifica por GUID o por el `Title` mostrado por `Get-SpoListNames`.
- La herramienta debe usar `Connect-Spo` como dependencia de autenticación, por nombre de módulo, sin rutas relativas a `tools/Connect-Spo`.
- Si usa contexto activo, este debe provenir de `$global:PSLibSpoConnectionContext` creado por `Connect-Spo`.
- Si no existe contexto activo ni parámetros suficientes para conectar, debe informar un error claro.
- Los mensajes auxiliares que hasta ahora se mostraban al operador deben emitirse solo con `-Verbose`; el archivo generado, el resultado funcional, errores y prompts necesarios no se consideran mensajes auxiliares.

---

## Épicas

| ID | Épica | Objetivo | Spec |
|----|-------|----------|------|
| 01 | Exportación Excel de lista SharePoint | Exportar ítems de una lista SharePoint a `.xlsx` usando campos desplegables y formatos seguros para Excel. | `01-excel-list-export-spec.md` |

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-16 | Discovery Agent | Product spec inicial para `Export-SpoListToExcel`. |
| 0.2.0 | 2026-06-16 | Discovery Agent | Cambia estado a APROBADO por aprobacion explicita del usuario para pasar a Planning. |
| 0.3.0 | 2026-06-18 | Spec Design Agent | Aprueba modo Quiet por defecto y -Verbose para mensajes auxiliares del comando. |
| 0.4.0 | 2026-06-19 | Spec Design Agent | Agrega comportamiento requerido para listas sin ítems: generar `.xlsx` solo con encabezados. |
| 0.5.0 | 2026-06-19 | Spec Design Agent | Explicita que errores recuperables de lectura por lista vacía se tratan como cero ítems. |




