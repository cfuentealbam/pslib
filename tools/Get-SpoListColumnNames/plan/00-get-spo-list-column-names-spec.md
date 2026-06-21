# Get-SpoListColumnNames - Product Spec

**Estado:** APROBADO

**Herramienta:** `Get-SpoListColumnNames`
**Fecha de Discovery:** 2026-06-15

---

## Producto

`Get-SpoListColumnNames` es una herramienta PowerShell para inspeccionar una lista de SharePoint Online e informar las columnas disponibles, mostrando por cada columna su nombre interno, nombre visible y tipo.

---

## Problema

Cuando se construyen automatizaciones o integraciones sobre listas de SharePoint, el nombre visible de una columna no siempre coincide con el nombre interno requerido para consultas, actualizaciones o mapeos tecnicos. La inspeccion manual desde la interfaz de SharePoint es lenta y propensa a errores, especialmente cuando hay columnas renombradas o generadas por plantillas.

El operador necesita una forma rapida y verificable de obtener los nombres internos, nombres visibles y tipos de columnas de una lista especifica.

---

## Usuarios

- Administrador u operador de SharePoint Online.
- Responsable de soporte o automatizacion que necesita mapear columnas correctamente.
- Integrador que requiere referencias internas de columnas antes de crear scripts o cargas de datos.

---

## Alcance

- Trabajar sobre un solo sitio SharePoint Online por ejecucion.
- Identificar la lista objetivo mediante su GUID o mediante el `Title` desplegado por `Get-SpoListNames`.
- Obtener las columnas/campos desplegables de la lista objetivo, descartando campos internos de SharePoint.
- Mostrar por cada columna al menos:
  - nombre interno;
  - nombre visible o externo;
  - tipo de columna/campo.
- Usar el contexto SharePoint activo de sesion registrado por `Connect-Spo` cuando el operador no entregue parametros de conexion.
- Permitir `SiteUrl`, `TenantId`, `ClientId` y `AuthMode` explicitos para mantener el mismo contrato de autenticacion de las tools SharePoint existentes.
- Devolver un resultado tabular o coleccion de objetos PowerShell apta para filtrar, exportar o inspeccionar.
- Descartar campos internos usando las propiedades `Hidden`, `ReadOnlyField`, `Sealed` y `FromBaseType`, conservando `Title` aunque venga de tipo base.
- Funcionar en modo Quiet por defecto, sin mensajes auxiliares de estado, progreso o diagnostico salvo que el operador indique `-Verbose`.
- Mantener en modo Quiet la salida funcional aprobada del comando, es decir la coleccion de columnas devuelta al pipeline, ademas de errores o prompts necesarios para completar la operacion.

---

## Fuera de Alcance

- Crear, modificar o eliminar columnas.
- Consultar valores de items de la lista.
- Modificar permisos, vistas, formularios o configuracion avanzada.
- Operar sobre multiples listas en una sola ejecucion.
- Exportar automaticamente a CSV, JSON, Excel u otros formatos.
- Crear un modulo bajo `modules/` en la primera historia.
- Cambios bajo `mcp/`.

---

## Restricciones

- La herramienta debe ser PowerShell y vivir bajo `tools/Get-SpoListColumnNames`.
- Los artefactos de proceso viven en `tools/Get-SpoListColumnNames/plan/`.
- La lista objetivo se identifica por GUID o por el `Title` desplegado por `Get-SpoListNames`.
- La herramienta debe usar `Connect-Spo` como dependencia de autenticacion, por nombre de modulo, sin rutas relativas a `tools/Connect-Spo`.
- Si usa contexto activo, este debe provenir de `$global:PSLibSpoConnectionContext` creado por `Connect-Spo`.
- Si no existe contexto activo ni parametros suficientes para conectar, debe informar un error claro.
- Los mensajes auxiliares que hasta ahora se mostraban al operador deben emitirse solo con `-Verbose`; los resultados funcionales, errores y prompts necesarios no se consideran mensajes auxiliares.

---

## Epicas

| ID | Epica | Objetivo | Spec |
|----|-------|----------|------|
| 01 | Descubrimiento de columnas de lista | Permitir consultar columnas de una lista SharePoint por GUID y exponer nombres interno/visible y tipo. | `01-list-column-discovery-spec.md` |

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-15 | Discovery Agent | Product spec inicial para `Get-SpoListColumnNames`. |
| 0.2.0 | 2026-06-16 | Spec Design Agent | Aprueba identificar listas por GUID o por el Title mostrado por `Get-SpoListNames`. |
| 0.3.0 | 2026-06-16 | Spec Design Agent | Aprueba mostrar solo campos desplegables, descartando campos internos de SharePoint y preservando `Title`. |
| 0.4.0 | 2026-06-18 | Spec Design Agent | Aprueba modo Quiet por defecto y `-Verbose` para mensajes auxiliares del comando. |
