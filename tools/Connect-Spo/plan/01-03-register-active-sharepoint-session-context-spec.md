# Registrar Contexto SharePoint Activo de Sesion - Spec de Historia

**Estado:** APROBADO

**Herramienta:** `Connect-Spo`
**Producto:** `00-sharepoint-auth-unified-spec.md`
**Epica:** `01-interactive-sharepoint-auth-spec.md`
**Historia:** `01-03-register-active-sharepoint-session-context`
**Fecha de Discovery:** 2026-06-15

---

## Historia de Usuario

Como operador de tools PowerShell de SharePoint, quiero ejecutar `Connect-Spo` una vez y que la conexion quede como contexto activo de la sesion, para ejecutar tools posteriores sin volver a indicar `SiteUrl`, `TenantId`, `ClientId` ni `AuthMode`.

---

## Descripcion Funcional

Cuando `Connect-Spo` completa una autenticacion exitosa, la capacidad debe dejar disponible en la sesion PowerShell actual un contexto SharePoint activo. Ese contexto debe contener la conexion PnP devuelta por la autenticacion y los datos no secretos de contexto usados por la invocacion: `SiteUrl`, `TenantId`, `ClientId` resuelto y `AuthMode`.

Las tools adoptantes pueden usar ese contexto activo como fuente por defecto cuando el operador no entrega parametros propios. El contexto no debe persistirse en disco ni estar disponible fuera de la sesion/runspace actual.

---

## Entradas y Salidas

### Entradas

| Entrada | Tipo funcional | Descripcion | Requerido |
|---------|----------------|-------------|-----------|
| `SiteUrl` | URL SharePoint | Sitio objetivo autenticado por `Connect-Spo`. | Si |
| `TenantId` | Identificador de tenant | Tenant Microsoft 365 / Entra ID usado para autenticar. | Si |
| `ClientId` | Identificador de aplicacion | App Registration entregada por parametro o variable de ambiente aprobada. | Si |
| `AuthMode` | Modo de autenticacion | `Interactive` o `DeviceCode`. | Si |
| Conexion PnP | Contexto autenticado | Conexion obtenida desde PnP.PowerShell tras autenticacion exitosa. | Si |

### Salidas

| Salida | Tipo funcional | Descripcion |
|--------|----------------|-------------|
| Contexto SharePoint activo | Estado de sesion | Datos de conexion y contexto no secreto disponibles para tools adoptantes en la sesion PowerShell actual. |
| Conexion PnP retornada | Objeto de conexion | Resultado funcional que puede seguir devolviendo `Connect-Spo` al operador o tool invocadora. |

---

## Comportamiento Observable

1. Dado `SiteUrl`, `TenantId`, `ClientId` y `AuthMode` validos, cuando `Connect-Spo` autentica exitosamente, entonces queda registrado un contexto SharePoint activo en la sesion actual.
2. El contexto activo incluye la conexion PnP y los datos no secretos `SiteUrl`, `TenantId`, `ClientId` resuelto y `AuthMode`.
3. Una tool adoptante puede resolver parametros omitidos desde el contexto activo, siempre que su spec propio lo apruebe.
4. Si se ejecuta `Connect-Spo` nuevamente con otro sitio o contexto, el contexto activo de sesion pasa a representar la autenticacion exitosa mas reciente.
5. El contexto activo no guarda contrasenas, secretos de cliente ni tokens persistidos por esta capacidad.
6. El contexto activo no se escribe en disco ni se declara como configuracion persistente del usuario.
7. El contexto activo se limita a la sesion PowerShell/runspace actual.
8. Dado un contexto activo existente para el mismo `SiteUrl` y `ClientId`, cuando `Connect-Spo` valida que la conexion sigue vigente, entonces devuelve esa conexion sin ejecutar un nuevo login.
9. Dado un contexto activo existente para otro sitio, otro `ClientId` o una conexion que ya no responde, cuando `Connect-Spo` se ejecuta, entonces realiza el flujo normal de autenticacion y reemplaza el contexto solo si el login termina exitosamente.

---

## Criterios de Aceptacion

- [ ] Dado que `Connect-Spo` autentica correctamente, cuando termina la ejecucion, entonces existe un contexto SharePoint activo reutilizable en la misma sesion PowerShell.
- [ ] Dado un contexto activo, cuando una tool adoptante aprobada se ejecuta sin parametros de conexion, entonces puede usar el `SiteUrl` y la conexion PnP del contexto.
- [ ] Dado que `Connect-Spo` resuelve `ClientId` desde variable de ambiente, cuando registra el contexto activo, entonces conserva el `ClientId` resuelto y no el valor vacio original.
- [ ] Dado que una autenticacion falla o se cancela, cuando termina `Connect-Spo`, entonces no se registra un nuevo contexto activo exitoso.
- [ ] Dado que se ejecuta `Connect-Spo` exitosamente mas de una vez en la misma sesion, cuando una tool adoptante usa el contexto activo, entonces usa el contexto de la autenticacion exitosa mas reciente.
- [ ] Dado cualquier ejecucion, cuando se inspecciona el comportamiento de persistencia, entonces no existen secretos ni tokens escritos en disco por esta capacidad.
- [ ] Dado un contexto activo valido para el mismo sitio y app, `Connect-Spo` no vuelve a ejecutar login y retorna la conexion existente.
- [ ] Dado un contexto activo invalido, de otro sitio o de otra app, `Connect-Spo` ejecuta el login normal.

---

## Mensaje Minimo Funcional Propuesto

- Contexto ausente para tools adoptantes: `No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.`

---

## Fuera de Alcance

- Persistir perfiles de conexion entre sesiones PowerShell.
- Guardar tokens, contrasenas, certificados, secretos de cliente o refresh tokens en disco.
- Implementar autenticacion no interactiva nueva.
- Definir la adopcion concreta en todas las tools existentes; cada tool adoptante debe tener su historia propia.
- Cambios bajo `mcp/`.

---

## Notas de Discovery

- El diseno fue aprobado explicitamente por el usuario el 2026-06-15.
- La primera tool adoptante esperada es `Get-SpoListNames`, mediante una historia propia en `tools/Get-SpoListNames/plan/`.
- La implementacion tecnica debe volver a Planning antes de modificar codigo porque esta historia cambia alcance funcional.
- El 2026-06-18 el usuario solicito explicitamente que `Connect-Spo` valide y reutilice una conexion activa y valida para el mismo sitio y app.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-15 | Spec Design Agent | Crea historia aprobada para registrar contexto SharePoint activo de sesion tras `Connect-Spo`. |
| 0.2.0 | 2026-06-18 | Spec Design Agent | Aprueba reutilizar conexion activa valida para el mismo sitio y app sin repetir login. |
