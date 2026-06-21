# Product Spec: Get-SpoListNames

**Estado:** APROBADO

**Herramienta:** `Get-SpoListNames`
**Archivo:** `00-spo-list-names-spec.md`
**Fecha de Discovery:** 2026-06-12
**Solicitante:** Usuario

---

## Descripcion del Producto

Herramienta PowerShell `Get-SpoListNames` para inspeccionar un sitio de SharePoint y listar, para cada lista no documental, su nombre interno y su titulo visible. El producto puede ofrecerse como script incubado en `tools/Get-SpoListNames/src/` y como modulo PowerShell no compilado bajo `modules/Get-SpoListNames/` para uso como comando importable.

---

## Problema que Resuelve

Cuando se trabaja con automatizaciones, integraciones o soporte operativo sobre SharePoint, el nombre visible de una lista no siempre coincide con el nombre interno necesario para referenciarla correctamente. Hoy esa relacion suele requerir inspeccion manual y es propensa a errores.

---

## Usuarios y Contexto

- **Usuario principal:** Administradores de SharePoint, operadores TI y desarrolladores de automatizaciones.
- **Contexto de uso:** Revision de un sitio existente para identificar listas y sus nombres correctos antes de integrarlas o administrarlas.
- **Resultado esperado:** Obtener un listado claro de listas del sitio con nombre interno y titulo visible, sin incluir bibliotecas de documentos.

---

## Alcance Global

- Recibir un sitio de SharePoint como objetivo de consulta.
- Enumerar las listas no documentales accesibles para el operador en ese sitio.
- Mostrar por cada lista al menos su nombre interno y su titulo visible.
- Empaquetar la funcionalidad aprobada como modulo PowerShell no compilado con manifiesto y modulo de script, sin cambiar el comportamiento funcional de descubrimiento de listas.
- Consumir la autenticacion SharePoint unificada mediante dependencia de modulo `Connect-Spo` disponible por nombre, sin rutas relativas a `tools/Connect-Spo`.
- Usar el contexto SharePoint activo de sesion registrado por `Connect-Spo` cuando el operador ejecute la herramienta sin parametros de conexion.
- Informar de forma clara y accionable si la dependencia `Connect-Spo` no esta disponible para importacion.
- Informar de forma clara si no existe contexto SharePoint activo y tampoco se entregan parametros suficientes para conectar.
- Funcionar en modo Quiet por defecto, sin mensajes auxiliares de estado, progreso o diagnostico salvo que el operador indique `-Verbose`.
- Mantener en modo Quiet la salida funcional aprobada del comando, es decir la coleccion de listas devuelta al pipeline, ademas de errores o prompts necesarios para completar la operacion.

---

## Fuera de Alcance Global

- Crear, modificar o eliminar listas.
- Inspeccionar columnas, vistas, permisos, contenido o configuracion avanzada de cada lista.
- Incluir bibliotecas de documentos en el resultado.
- Publicar el modulo en PowerShell Gallery.
- Crear instaladores MSI u otros instaladores del sistema.
- Crear un modulo binario, compilado o basado en cmdlets .NET.
- Cambios bajo `mcp/`.

---

## Epicas

| ID | Epica | Descripcion | Archivo |
|----|-------|-------------|---------|
| 01 | Descubrimiento de listas del sitio | Permite identificar las listas no documentales de un sitio y exponer sus nombres relevantes para uso operativo. | `01-site-list-discovery-spec.md` |
| 02 | Empaquetado como modulo PowerShell | Permite importar `Get-SpoListNames` como modulo PowerShell no compilado y exponer el comando para uso global en una sesion. | `02-powershell-module-packaging-spec.md` |

---

## Restricciones Generales

- **PowerShell:** 7.4+
- **Sistema operativo:** Windows
- **Dependencias externas:** No definidas en Discovery; se aprueban por historia en Planning.
- **Otras restricciones:** El script debe limitarse a capacidades de lectura del sitio objetivo.
- **Empaquetado:** Los modulos PowerShell del producto deben vivir bajo `modules/Get-SpoListNames/` y no deben requerir compilacion .NET.
- **Autenticacion compartida:** `Get-SpoListNames` debe consumir `Connect-Spo` como dependencia de modulo por nombre cuando requiera autenticacion SharePoint unificada; no debe depender de rutas relativas hacia `tools/Connect-Spo`.
- **Contexto activo:** Si existe un contexto SharePoint activo de sesion registrado por `Connect-Spo`, `Get-SpoListNames` puede usarlo como fuente por defecto para `SiteUrl` y conexion cuando se omitan parametros.
- **Modo Quiet/Verbose:** Los mensajes auxiliares que hasta ahora se mostraban al operador deben emitirse solo con `-Verbose`; los resultados funcionales, errores y prompts necesarios no se consideran mensajes auxiliares.

---

## Notas de Discovery

- Se interpreta "nombre publicado" como el titulo visible mostrado al usuario en SharePoint.
- El usuario confirmo que el alcance excluye bibliotecas de documentos.
- Los archivos de plan viven en `tools/Get-SpoListNames/plan/`; el nombre logico vigente de la herramienta es `Get-SpoListNames`.
- El usuario aprobo explicitamente cambiar la configuracion de `pslib` para permitir modulos PowerShell bajo `modules/`.
- La definicion de modulo se alinea con Microsoft Learn: los modulos de script se escriben en PowerShell, se importan con `Import-Module`, y los manifiestos `.psd1` describen el modulo y pueden apuntar a un `RootModule` `.psm1`.
- La refactorizacion funcional para consumir `Connect-Spo` como modulo se define en una nueva historia de la epica de descubrimiento de listas.
- La ejecucion sin parametros basada en contexto activo se define en una historia propia de la epica de descubrimiento de listas.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-12 | Discovery Agent | Product spec inicial |
| 0.2.0 | 2026-06-12 | Spec Design Agent | Cambia el nombre logico de herramienta de `spo-list-names` a `Get-SpoListNames`; mantiene nombres de archivos/ruta de plan historicos y alcance funcional sin cambios |
| 0.3.0 | 2026-06-12 | Dev Agent | Actualiza la referencia de ruta tras la migracion estructural a `tools/Get-SpoListNames` |
| 0.4.0 | 2026-06-12 | Spec Design Agent | Agrega alcance de empaquetado como modulo PowerShell no compilado bajo `modules/Get-SpoListNames/` y marca el producto EN_REVISION |
| 0.5.0 | 2026-06-14 | Spec Design Agent | Incorpora consumo de autenticacion mediante dependencia de modulo `Connect-Spo` por nombre, sin rutas relativas a `tools/Connect-Spo`. |
| 0.6.0 | 2026-06-14 | Spec Design Agent | Cambia estado a APROBADO por aprobacion explicita del usuario de la historia 01-02 para pasar a Planning. |
| 0.7.0 | 2026-06-15 | Spec Design Agent | Aprueba uso de contexto SharePoint activo de sesion para ejecutar `Get-SpoListNames` sin parametros de conexion. |
| 0.8.0 | 2026-06-18 | Spec Design Agent | Aprueba modo Quiet por defecto y `-Verbose` para mensajes auxiliares del comando. |
