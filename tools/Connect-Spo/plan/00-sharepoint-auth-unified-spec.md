# SharePoint Auth Unified - Spec de Producto

**Estado:** APROBADO

## Problema

Las tools PowerShell de SharePoint en `pslib` necesitan un proceso consistente de autenticación interactiva con credenciales MS365. El uso de contraseñas solicitadas por cada tool, configuraciones divergentes o mensajes de error inconsistentes aumenta fricción operativa y riesgo de manejo inadecuado de credenciales.

## Objetivo del Producto

Definir una capacidad funcional unificada, identificada como tool `Connect-Spo`, con artefactos de proceso en `tools/Connect-Spo` y capacidad reusable publicada como módulo PowerShell no compilado en `modules/Connect-Spo`, para que las tools PowerShell de SharePoint autentiquen usuarios MS365 de forma interactiva, sin solicitar ni almacenar contraseñas, usando parámetros comunes de contexto de tenant, aplicación y sitio.

## Usuarios

- Operador o administrador que ejecuta tools PowerShell de SharePoint en `pslib`.
- Responsable de Microsoft 365 o Entra ID que habilita una App Registration para uso delegado.
- Mantenedor de tools de SharePoint en `pslib` que necesita comportamiento de login consistente entre herramientas.

## Alcance Funcional

- Autenticación interactiva unificada para tools PowerShell de SharePoint.
- Uso de credenciales MS365 mediante experiencia delegada aprobada por el tenant.
- Aceptación consistente de `SiteUrl`, `TenantId` y `ClientId` por las tools SharePoint que adopten esta capacidad, admitiendo que `ClientId` pueda provenir de una variable de ambiente explícitamente configurada.
- Soporte funcional para modo `Interactive`.
- Soporte opcional recomendado para modo `DeviceCode` cuando el entorno de ejecución no permita una experiencia interactiva con navegador local; su adopción obligatoria queda pendiente de aprobación explícita.
- Exposición de un comando público principal esperado llamado `Connect-Spo` para iniciar la autenticación SharePoint unificada.
- Registro de un contexto SharePoint activo en la sesión PowerShell actual tras una autenticación exitosa, para que las tools adoptantes puedan reutilizar `SiteUrl`, `TenantId`, `ClientId`, `AuthMode` y la conexión PnP sin repetir parámetros en llamadas posteriores.
- Reutilización de una conexión activa y válida cuando `Connect-Spo` se invoca nuevamente para el mismo `SiteUrl` y `ClientId`, evitando repetir el login.
- Ubicación objetivo del tool aprobada como `tools/Connect-Spo`, alineada con el nombre funcional del tool `Connect-Spo`.
- Publicación de la capacidad reusable como módulo PowerShell no compilado bajo `modules/Connect-Spo`.
- Importación por nombre desde una sesión cuyo `PSModulePath` haga disponible el módulo: `Import-Module Connect-Spo`.
- Exposición de la API pública `Connect-Spo` desde el módulo importado.
- Consumo por tools adoptantes como dependencia de módulo declarada por nombre, sin rutas relativas hacia `tools/Connect-Spo`.
- Mensajes claros para errores de login, permisos insuficientes, configuración faltante o cancelación del usuario, con mínimos funcionales propuestos.
- Mensaje claro y accionable cuando una tool adoptante no pueda encontrar o importar el módulo `Connect-Spo`.
- Ejecución en modo Quiet por defecto: `Connect-Spo` no debe emitir mensajes narrativos, de estado, progreso o diagnóstico salvo que el operador use `-Verbose`.
- Conservación en modo Quiet de las salidas necesarias para interacción con el usuario, como instrucciones/códigos de login, prompts requeridos por el flujo interactivo y errores accionables.
- No solicitar contraseña directamente al usuario.
- No guardar secretos en disco.
- Documentar las condiciones esperadas para App Registration en Entra ID y permisos delegados adecuados según el alcance real de cada tool.

## Fuera de Alcance

- Implementación técnica, arquitectura interna, funciones internas, dependencias técnicas o estrategia detallada de empaquetado.
- Creación automática de App Registrations en Entra ID.
- Administración de consentimiento de administrador o asignación automática de permisos en Microsoft 365.
- Autenticación no interactiva basada en secretos de cliente, certificados, credenciales almacenadas o cuentas de servicio.
- Gestión de permisos granulares por tool más allá de declarar que deben corresponder al alcance funcional real.
- Modificaciones bajo `mcp/`.
- Publicación en PowerShell Gallery o instalación persistente automática en perfiles de usuario.
- Cambios funcionales en tools SharePoint existentes que no estén cubiertos por historias aprobadas posteriores.

## Entradas Funcionales

- `SiteUrl`: URL del sitio SharePoint objetivo.
- `TenantId`: identificador del tenant MS365/Entra ID.
- `ClientId`: identificador de la App Registration autorizada, entregado por la invocación de la tool o por una variable de ambiente configurada explícitamente para ese propósito.
- Modo de autenticación solicitado: `Interactive` o, opcionalmente, `DeviceCode`.
- Credenciales MS365 ingresadas únicamente en la experiencia interactiva provista por la plataforma de identidad.

## Modos de Autenticación

- `Interactive`: el usuario completa el login MS365 en una experiencia interactiva, normalmente con navegador o ventana de autenticación disponible en el equipo donde ejecuta la tool.
- `DeviceCode`: modo alternativo en el que la tool muestra un código e instrucciones para completar el login en otro navegador o dispositivo; se recomienda mantenerlo como opción para consolas remotas o entornos sin navegador local, pero aún no queda aprobado como requisito obligatorio.

## Salidas Funcionales Observables

- Sesión o contexto de autenticación disponible para que una tool SharePoint continúe su operación autorizada.
- Contexto SharePoint activo disponible en la sesión PowerShell actual tras ejecutar `Connect-Spo` exitosamente.
- Comando público principal observable `Connect-Spo` disponible para iniciar el flujo de conexión/autenticación SharePoint.
- Módulo PowerShell no compilado `Connect-Spo` disponible bajo `modules/Connect-Spo` e importable por nombre cuando esté expuesto en `PSModulePath`.
- Confirmación clara de autenticación exitosa, cuando la tool decida mostrarla.
- Error claro y accionable cuando el login no pueda completarse.
- Mensajes mínimos propuestos:
  - Cancelación: `Autenticación cancelada por el usuario. No se continuará con la operación de SharePoint.`
  - Permisos insuficientes: `Autenticación completada, pero la cuenta o la aplicación no tiene permisos suficientes para el sitio u operación solicitada.`
  - Configuración inválida o incompleta: `No se puede iniciar autenticación: falta o es inválido uno de los datos requeridos: SiteUrl, TenantId o ClientId.`
  - Módulo no disponible: `No se puede cargar la dependencia Connect-Spo. Instale o exponga el módulo Connect-Spo en PSModulePath y vuelva a ejecutar la operación.`
- En modo Quiet, ausencia de mensajes auxiliares de estado o progreso que no sean necesarios para completar la interacción de autenticación.
- Con `-Verbose`, emisión de los mensajes informativos, diagnósticos o de progreso que existían antes de aprobar el modo Quiet.
- Ausencia de prompts de contraseña propios de la tool.
- Ausencia de secretos persistidos por la tool.

## Restricciones y Reglas

- Las tools que adopten esta capacidad deben aceptar `SiteUrl`, `TenantId` y `ClientId` como datos explícitos o configurados de forma aprobada por el usuario; en particular, `ClientId` puede obtenerse desde una variable de ambiente explícitamente documentada para la tool.
- El nombre público principal de la API funcional es `Connect-Spo`; `Connect` es verbo aprobado de PowerShell para crear un vínculo entre origen y destino, y `Spo` identifica SharePoint Online en forma breve según decisión explícita del usuario.
- El nombre del tool aprobado es `Connect-Spo`; por convención de repositorio, su carpeta de trabajo objetivo debe llamarse exactamente igual y quedar en `tools/Connect-Spo`.
- El código reusable aprobado para esta capacidad debe vivir como módulo PowerShell no compilado en `modules/Connect-Spo`; los artefactos de proceso permanecen en `tools/Connect-Spo/plan/`.
- Las tools adoptantes deben depender de `Connect-Spo` por nombre de módulo y no por rutas relativas a `tools/Connect-Spo`.
- La App Registration debe existir en Entra ID antes del uso operativo.
- Los permisos delegados deben corresponder al alcance real de cada tool; por ejemplo, lectura de sitios para tools de lectura o permisos de escritura solo si la tool modifica contenido.
- Para escenarios modernos de PnP.PowerShell se asume el uso de un `ClientId` propio o configurado de forma explícita por el usuario/entorno.
- No se deben guardar contraseñas, secretos de cliente ni tokens persistentes definidos por esta especificación.
- El contexto SharePoint activo no debe persistirse en disco ni cruzar sesiones/runspaces; su alcance funcional es la sesión PowerShell actual.
- Los mensajes auxiliares de operación deben canalizarse como salida verbose para que solo aparezcan cuando el operador indique `-Verbose`; los errores, prompts e instrucciones necesarias para la autenticación no se consideran mensajes auxiliares.

## Supuestos

- La carpeta histórica `tools/sharepoint-auth-unified/` debe ser reemplazada como ubicación de trabajo por `tools/Connect-Spo`.
- La primera necesidad funcional es habilitar una historia común de autenticación para tools SharePoint, sin implementar todavía migración de cada tool existente.
- `Get-SpoListNames` es la primera tool SharePoint adoptante inicial de esta capacidad; su adopción funcional se define en specs propios de `tools/Get-SpoListNames/plan/`.
- El usuario o administrador del tenant podrá registrar y autorizar una aplicación en Entra ID con permisos delegados adecuados.

## Épicas

| ID | Épica | Descripción |
|----|-------|-------------|
| 01 | Autenticación interactiva unificada | Define el comportamiento común de login MS365 para tools PowerShell de SharePoint. |

## Preguntas Pendientes

- ¿El modo `DeviceCode` debe ser obligatorio para todas las tools que adopten la capacidad o solo permitido cuando se solicite explícitamente? Por ahora queda como alternativo opcional recomendado, pendiente de aprobación.
- ¿Qué nombre concreto de variable de ambiente debe usarse para `ClientId`, si se desea estandarizarlo entre tools?

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-13 | Discovery Agent | Creación inicial del spec de producto para autenticación interactiva unificada SharePoint. |
| 0.2.0 | 2026-06-13 | Discovery Agent | Incorpora ClientId vía variable de ambiente, Get-SpoListNames como adoptante inicial, explicación de DeviceCode y mensajes mínimos funcionales. |
| 0.3.0 | 2026-06-13 | Discovery Agent | Cambia estado a APROBADO por aprobación explícita del usuario. |
| 0.4.0 | 2026-06-13 | Spec Design Agent | Incorpora `Connect-Spo` como nombre público principal esperado por solicitud explícita del usuario. |
| 0.5.0 | 2026-06-13 | Spec Design Agent | Incorpora `tools/Connect-Spo` como ubicación objetivo del tool aprobado `Connect-Spo`. |
| 0.6.0 | 2026-06-14 | Spec Design Agent | Autoriza `modules/Connect-Spo` como módulo PowerShell reusable importable por nombre y dependencia para tools adoptantes. |
| 0.7.0 | 2026-06-15 | Spec Design Agent | Aprueba contexto SharePoint activo de sesión para reutilizar conexión y datos de autenticación en tools posteriores sin repetir parámetros. |
| 0.8.0 | 2026-06-18 | Spec Design Agent | Aprueba reutilizar una conexión activa válida para el mismo sitio y app sin repetir login. |
| 0.9.0 | 2026-06-18 | Spec Design Agent | Aprueba modo Quiet por defecto y salida verbose para mensajes auxiliares de autenticación. |
