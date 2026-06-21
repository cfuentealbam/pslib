# Usar Contexto SharePoint Activo de Connect-Spo - Spec de Historia

**Estado:** APROBADO

**Herramienta:** `Get-SpoListNames`
**Producto:** `00-spo-list-names-spec.md`
**Epica:** `01-site-list-discovery-spec.md`
**Historia:** `01-03-use-active-connect-spo-session-context`
**Fecha de Discovery:** 2026-06-15

---

## Historia de Usuario

Como operador de `Get-SpoListNames`, quiero ejecutar primero `Connect-Spo` y luego llamar `Get-SpoListNames` sin parametros, para listar las listas del sitio ya conectado sin repetir `SiteUrl`, `TenantId`, `ClientId` ni `AuthMode`.

---

## Descripcion Funcional

`Get-SpoListNames` debe poder usar el contexto SharePoint activo de la sesion registrado por `Connect-Spo` cuando el operador no entregue parametros de conexion. En ese caso, la herramienta consulta las listas del `SiteUrl` del contexto activo usando la conexion PnP activa.

La herramienta debe conservar la opcion de recibir parametros explicitos. Si el operador entrega parametros, esos valores siguen siendo una forma valida de determinar el sitio y la autenticacion, segun las historias aprobadas anteriores.

---

## Entradas y Salidas

### Entradas

| Entrada | Tipo funcional | Descripcion | Requerido |
|---------|----------------|-------------|-----------|
| Contexto SharePoint activo | Estado de sesion | Contexto registrado por `Connect-Spo` con conexion PnP y `SiteUrl`. | Si no se entregan parametros |
| `SiteUrl` | URL SharePoint | Sitio objetivo entregado explicitamente por el operador. | No, si existe contexto activo |
| `TenantId` | Identificador de tenant | Tenant usado para autenticar explicitamente si no se reutiliza contexto. | No, si existe contexto activo |
| `ClientId` | Identificador de aplicacion | App Registration usada explicitamente si no se reutiliza contexto. | No, si existe contexto activo |
| `AuthMode` | Modo de autenticacion | Modo usado al conectar explicitamente si no se reutiliza contexto. | No, si existe contexto activo |

### Salidas

| Salida | Tipo funcional | Descripcion |
|--------|----------------|-------------|
| Listado de listas | Coleccion tabular o equivalente | Resultado aprobado de listas no documentales del sitio conectado. |
| Error accionable | Mensaje al operador | Mensaje claro cuando no existe contexto activo ni parametros suficientes para conectar. |

---

## Comportamiento Observable

1. Dado que el operador ejecuto exitosamente `Connect-Spo -SiteUrl "https://globesacl.sharepoint.com/sites/GDS-PM" -TenantId "globesacl.onmicrosoft.com" -ClientId "b7b4891f-c96c-4ce3-aea8-9eb70696a85c" -AuthMode DeviceCode`, cuando ejecuta `Get-SpoListNames` sin parametros en la misma sesion, entonces se listan las listas no documentales de `https://globesacl.sharepoint.com/sites/GDS-PM`.
2. Dado un contexto SharePoint activo, cuando `Get-SpoListNames` se ejecuta sin `SiteUrl`, entonces usa el `SiteUrl` del contexto activo para consultas y mensajes.
3. Dado un contexto SharePoint activo, cuando `Get-SpoListNames` consulta listas, entonces usa la conexion PnP del contexto activo.
4. Dado que no existe contexto SharePoint activo y no se entregan parametros suficientes, cuando se ejecuta `Get-SpoListNames`, entonces falla antes de consultar SharePoint con un mensaje claro.
5. Dado que el operador entrega parametros explicitos, cuando se ejecuta `Get-SpoListNames`, entonces la herramienta conserva el comportamiento aprobado de autenticacion explicita mediante `Connect-Spo`.
6. El resultado funcional de listas no cambia: se mantienen listas no documentales con `GUID`, `EntityTypeName` y `Title`.

---

## Criterios de Aceptacion

- [ ] Dado un contexto activo creado por `Connect-Spo`, cuando el operador ejecuta `Get-SpoListNames` sin parametros, entonces consulta el sitio registrado en ese contexto.
- [ ] Dado el sitio `https://globesacl.sharepoint.com/sites/GDS-PM` conectado por `Connect-Spo`, cuando se ejecuta `Get-SpoListNames` sin parametros, entonces lista las listas de ese sitio.
- [ ] Dado un contexto activo, cuando `Get-SpoListNames` consulta listas sin parametros, entonces no solicita nuevamente `SiteUrl`, `TenantId`, `ClientId` ni `AuthMode`.
- [ ] Dado que no existe contexto activo y no se entregan parametros, cuando se ejecuta `Get-SpoListNames`, entonces informa: `No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.`
- [ ] Dado una invocacion con parametros explicitos completos, cuando se ejecuta `Get-SpoListNames`, entonces conserva el comportamiento aprobado de conectar mediante `Connect-Spo`.
- [ ] Dado cualquier modo de ejecucion, cuando se devuelven listas, entonces se conservan `GUID`, `EntityTypeName` y `Title`, excluyendo bibliotecas de documentos.

---

## Mensaje Minimo Funcional Propuesto

- Contexto ausente: `No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.`

---

## Fuera de Alcance

- Persistir conexiones o perfiles entre sesiones PowerShell.
- Soportar multiples contextos activos simultaneos o seleccion de contexto por nombre.
- Cambiar los campos de salida de `Get-SpoListNames`.
- Incluir bibliotecas de documentos.
- Modificar otras tools adoptantes fuera de `Get-SpoListNames`.
- Cambios bajo `mcp/`.

---

## Notas de Discovery

- El diseno fue aprobado explicitamente por el usuario el 2026-06-15.
- Esta historia depende funcionalmente de `tools/Connect-Spo/plan/01-03-register-active-sharepoint-session-context-spec.md`.
- Al cambiar alcance funcional de `Get-SpoListNames`, el siguiente paso formal es volver a Planning antes de implementar.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-15 | Spec Design Agent | Crea historia aprobada para ejecutar `Get-SpoListNames` sin parametros usando contexto activo de `Connect-Spo`. |
