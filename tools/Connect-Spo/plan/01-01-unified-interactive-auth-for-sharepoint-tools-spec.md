# Autenticación Interactiva Unificada para Tools SharePoint - Spec de Historia

**Estado:** APROBADO

## Historia de Usuario

Como usuario de una tool PowerShell de SharePoint en `pslib`, quiero autenticarme con mis credenciales MS365 mediante un flujo interactivo unificado, para que las tools puedan acceder a SharePoint sin pedirme contraseña directamente ni guardar secretos en disco.

## Objetivo

Definir el comportamiento observable de una capacidad común de login interactivo que pueda ser adoptada por tools SharePoint, expuesta mediante el comando público principal `Connect-Spo`, con nombre de tool `Connect-Spo` y ubicación objetivo `tools/Connect-Spo`, usando `SiteUrl`, `TenantId` y `ClientId` como datos de contexto principales, con `ClientId` aceptado también desde variable de ambiente explícitamente configurada.

## Usuarios

- Usuario operador que ejecuta una tool SharePoint.
- Administrador o responsable MS365 que provee `TenantId`, `ClientId` y permisos delegados.
- Mantenedor de tools SharePoint que necesita una experiencia funcional uniforme de autenticación.

## Comportamiento Observable Esperado

1. La tool que adopte esta historia expone como API pública principal el comando `Connect-Spo` para iniciar el proceso de autenticación.
2. La carpeta de trabajo objetivo de esta tool es `tools/Connect-Spo`, reemplazando la ubicación histórica `tools/sharepoint-auth-unified/`.
3. `Connect-Spo` acepta `SiteUrl`, `TenantId` y `ClientId` para iniciar el proceso de autenticación.
4. La tool permite iniciar login en modo `Interactive`.
5. La tool puede permitir login en modo `DeviceCode` como alternativa opcional recomendada cuando el usuario lo solicite o cuando el entorno no facilite login interactivo con navegador local; este modo queda pendiente de aprobación como requisito obligatorio.
6. La tool no solicita contraseña mediante prompts propios.
7. El usuario ingresa sus credenciales MS365 solo en la experiencia interactiva de identidad correspondiente.
8. Si la autenticación es exitosa, la tool puede continuar con la operación SharePoint para la cual fue invocada.
9. Si falta `ClientId` como dato directo, la tool puede obtenerlo desde una variable de ambiente configurada explícitamente para ese propósito.
10. Si falta `SiteUrl`, `TenantId` o `ClientId`, la tool informa qué dato falta y no intenta una autenticación ambigua.
11. Si el usuario cancela el login, la tool informa cancelación de autenticación de forma clara.
12. Si la cuenta no tiene permisos suficientes para el sitio u operación, la tool informa una falla de permisos de forma clara.
13. Si la App Registration no está autorizada o no tiene permisos delegados adecuados, la tool informa una falla de configuración/autorización de forma clara.
14. La tool no guarda contraseñas, secretos de cliente ni otros secretos en disco como parte de esta capacidad.
15. La experiencia de autenticación debe poder ser usada de manera común por más de una tool SharePoint, manteniendo nombres de entradas y mensajes consistentes.
16. `Get-SpoListNames` queda identificada como la primera tool SharePoint candidata/adoptante inicial, sin que esta historia modifique su comportamiento por sí misma.

## Explicación Funcional de DeviceCode

`DeviceCode` es un modo de autenticación interactiva alternativo: la tool muestra al usuario un código y una dirección web; el usuario abre esa dirección en un navegador disponible, incluso en otro equipo o dispositivo, ingresa el código y completa el login MS365. Es útil en consolas remotas, sesiones sin navegador local o equipos donde no se puede abrir una ventana interactiva. En este spec queda como alternativa opcional recomendada, no como requisito obligatorio aprobado.

## Criterios de Aceptación

- Dado un `SiteUrl`, `TenantId` y `ClientId` válidos, cuando el usuario inicia modo `Interactive` y completa el login MS365, entonces la tool queda habilitada para continuar su operación SharePoint autorizada.
- Dado que la capacidad común de autenticación está disponible, cuando el usuario inspecciona o invoca la API pública principal, entonces el comando esperado es `Connect-Spo`.
- Dado que el nombre aprobado del tool es `Connect-Spo`, cuando se define su ubicación en el repositorio, entonces la carpeta de trabajo objetivo es `tools/Connect-Spo`.
- Dado un entorno donde se usa `DeviceCode`, cuando el usuario completa el flujo indicado, entonces la tool queda habilitada para continuar su operación SharePoint autorizada, siempre que este modo haya sido aprobado para la tool que lo adopta.
- Dado que falta `ClientId` como parámetro o entrada directa, cuando existe una variable de ambiente explícitamente configurada para `ClientId`, entonces la tool puede usar ese valor como entrada aceptada.
- Dado que falta `ClientId` tanto como entrada directa como en variable de ambiente aceptada, cuando el usuario intenta iniciar autenticación, entonces la tool informa que `ClientId` es requerido o debe estar configurado explícitamente.
- Dado que falta `TenantId`, cuando el usuario intenta iniciar autenticación, entonces la tool informa que `TenantId` es requerido.
- Dado que falta `SiteUrl`, cuando el usuario intenta iniciar autenticación, entonces la tool informa que `SiteUrl` es requerido.
- Dado cualquier modo de autenticación, cuando la tool requiere credenciales, entonces no solicita contraseña directamente al usuario.
- Dado un login cancelado por el usuario, cuando la tool termina, entonces muestra un mensaje de cancelación comprensible y no continúa la operación SharePoint.
- Dado permisos insuficientes en SharePoint o en la App Registration, cuando la autenticación u operación autorizada falla, entonces la tool muestra un mensaje que diferencia falta de permisos de errores generales.
- Dado cualquier ejecución, cuando finaliza la autenticación, entonces no quedan contraseñas ni secretos persistidos en disco por esta capacidad.
- Dado que otra tool SharePoint adopta la capacidad, cuando solicita login, entonces usa las mismas entradas funcionales principales y una experiencia de errores consistente.
- Dado que `Get-SpoListNames` sea tratada como primera adoptante inicial en specs posteriores, cuando se defina su adopción, entonces deberá respetar esta historia sin que este documento modifique directamente esa tool.

## Mensajes Mínimos Funcionales Propuestos

- Cancelación: `Autenticación cancelada por el usuario. No se continuará con la operación de SharePoint.`
- Permisos insuficientes: `Autenticación completada, pero la cuenta o la aplicación no tiene permisos suficientes para el sitio u operación solicitada.`
- Configuración inválida o incompleta: `No se puede iniciar autenticación: falta o es inválido uno de los datos requeridos: SiteUrl, TenantId o ClientId.`

## Restricciones Funcionales

- La App Registration en Entra ID debe existir antes del uso de la tool.
- Los permisos delegados deben ajustarse al alcance real de la tool: por ejemplo, permisos de lectura para tools de lectura y permisos de escritura solo cuando la tool modifique contenido.
- En escenarios modernos de PnP.PowerShell, el `ClientId` debe ser propio o estar configurado explícitamente por el usuario/entorno, incluyendo variable de ambiente aprobada para ese uso.
- `Connect-Spo` es el nombre público principal aprobado para esta historia; usa el verbo PowerShell aprobado `Connect` y el sustantivo abreviado `Spo` por decisión explícita del usuario.
- La carpeta de trabajo objetivo aprobada es `tools/Connect-Spo`.
- La historia no autoriza almacenamiento de secretos ni autenticación no interactiva.

## Fuera de Alcance

- Diseño o implementación técnica de la capacidad común.
- Elección de librerías, comandos, funciones, módulos, estructura interna o dependencias.
- Creación, modificación o empaquetado bajo `modules/`.
- Implementación de cambios en una tool SharePoint concreta como `Get-SpoListNames`; esta historia solo la identifica como primera candidata/adoptante inicial.
- Administración automática de App Registration, permisos o consentimiento en Entra ID.
- Definición de permisos exactos para cada tool futura.

## Supuestos

- El usuario podrá proporcionar `TenantId` y `ClientId` válidos.
- La App Registration tendrá permisos delegados compatibles con la operación SharePoint que se ejecute.
- `Interactive` es el modo principal esperado.
- `ClientId` podrá ser provisto por variable de ambiente explícitamente configurada.
- `DeviceCode` se considera funcionalmente deseable y recomendado como alternativa, pero pendiente de confirmar si será obligatorio en la primera implementación aprobada.

## Preguntas Pendientes

- ¿`DeviceCode` debe quedar como criterio obligatorio de la primera historia o como comportamiento opcional aceptado? Por ahora queda como alternativo opcional recomendado, pendiente de aprobación.
- ¿Qué nombre concreto de variable de ambiente debe usarse para `ClientId`, si se desea estandarizarlo entre tools?

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-13 | Discovery Agent | Creación inicial del spec de historia para autenticación interactiva unificada de tools SharePoint. |
| 0.2.0 | 2026-06-13 | Discovery Agent | Incorpora ClientId vía ambiente, Get-SpoListNames como candidata inicial, explicación de DeviceCode y mensajes mínimos propuestos. |
| 0.3.0 | 2026-06-13 | Discovery Agent | Cambia estado a APROBADO por aprobación explícita del usuario. |
| 0.4.0 | 2026-06-13 | Spec Design Agent | Incorpora `Connect-Spo` como API pública principal por solicitud explícita del usuario. |
| 0.5.0 | 2026-06-13 | Spec Design Agent | Incorpora `tools/Connect-Spo` como ubicación objetivo del tool aprobado `Connect-Spo`. |
