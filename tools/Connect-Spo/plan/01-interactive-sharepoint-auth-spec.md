# Autenticación Interactiva Unificada - Spec de Épica

**Estado:** APROBADO

## Objetivo de la Épica

Definir el comportamiento funcional común del tool `Connect-Spo`, con artefactos de proceso en `tools/Connect-Spo` y capacidad reusable como módulo PowerShell no compilado en `modules/Connect-Spo`, que permita a las tools PowerShell de SharePoint iniciar sesión con credenciales MS365 mediante autenticación interactiva, usando datos de contexto consistentes y sin solicitar ni almacenar contraseñas.

## Problema que Resuelve

Cada tool SharePoint puede terminar pidiendo datos de login, parámetros o manejo de errores de forma distinta. Esta épica busca que la experiencia observable de autenticación sea uniforme, predecible y segura para el usuario.

## Usuarios Beneficiados

- Operadores que ejecutan tools SharePoint y necesitan una experiencia de login única.
- Administradores MS365 que controlan App Registrations y permisos delegados.
- Mantenedores de tools SharePoint que requieren una regla funcional común para incorporar autenticación.

## Alcance Funcional de la Épica

- Definir los datos mínimos que toda tool SharePoint debe aceptar para autenticarse: `SiteUrl`, `TenantId` y `ClientId`, admitiendo `ClientId` desde variable de ambiente explícitamente configurada.
- Definir modos de login aceptados: `Interactive` y `DeviceCode` como alternativa opcional recomendada, pendiente de aprobación como requisito obligatorio.
- Definir `Connect-Spo` como comando público principal esperado para iniciar la conexión/autenticación SharePoint unificada.
- Definir `Connect-Spo` como nombre del tool y `tools/Connect-Spo` como carpeta de trabajo objetivo aprobada.
- Definir `modules/Connect-Spo` como ubicación aprobada del módulo PowerShell no compilado reusable, manteniendo los artefactos de proceso en `tools/Connect-Spo/plan/`.
- Definir que el módulo debe ser importable por nombre mediante `Import-Module Connect-Spo` cuando esté disponible en `PSModulePath`.
- Definir que el módulo expone como API pública el comando `Connect-Spo`.
- Definir que una autenticación exitosa registra un contexto SharePoint activo de sesión reutilizable por tools adoptantes.
- Definir que `Connect-Spo` reutiliza una conexión activa válida cuando se invoca para el mismo sitio y app.
- Definir que las tools adoptantes deben consumir la capacidad como dependencia de módulo por nombre, sin rutas relativas a `tools/Connect-Spo`.
- Definir que ninguna tool SharePoint que adopte la capacidad pida contraseña directamente.
- Definir respuestas observables ante éxito, cancelación, permisos insuficientes, configuración incompleta y fallas de autenticación, incluyendo mensajes mínimos funcionales.
- Definir la expectativa de que la capacidad pueda ser reutilizada de forma común por múltiples tools SharePoint.
- Definir restricciones funcionales sobre no persistir secretos.

## Fuera de Alcance de la Épica

- Diseño técnico de reutilización interna, funciones, clases o dependencias técnicas.
- Implementación de autenticación en una tool específica distinta de las historias aprobadas.
- Implementación directa de cambios en `Get-SpoListNames`; su adopción funcional debe quedar en specs propios de esa tool.
- Automatización de alta o configuración de App Registration.
- Definición exhaustiva de permisos para todos los casos de uso futuros.

## Historias Incluidas

| ID | Historia | Descripción |
|----|----------|-------------|
| 01-01 | Autenticación interactiva unificada para tools SharePoint | Como usuario de una tool SharePoint, quiero autenticarme con credenciales MS365 de forma interactiva y consistente, sin entregar contraseñas a la tool. |
| 01-02 | Publicar Connect-Spo como módulo PowerShell reutilizable | Como mantenedor de tools SharePoint, quiero importar `Connect-Spo` como módulo disponible por nombre, para reutilizar la autenticación sin depender de rutas relativas entre tools. |
| 01-03 | Registrar contexto SharePoint activo de sesión | Como operador, quiero ejecutar `Connect-Spo` una vez y reutilizar esa conexión en tools posteriores sin repetir parámetros. |

## Dependencias Funcionales

- Existencia de una App Registration en Entra ID con `ClientId` disponible para el usuario, la invocación de la tool o una variable de ambiente autorizada.
- Consentimiento y permisos delegados adecuados para la operación real de la tool que use la autenticación.
- Disponibilidad de una cuenta MS365 con acceso al `SiteUrl` solicitado.
- `Get-SpoListNames` será la primera tool adoptante inicial cuando existan specs aprobados para su adopción, sin que esta épica implemente dicha tool.
- Convención PowerShell Verb-Noun: `Connect-Spo` usa el verbo aprobado `Connect`; el sustantivo abreviado `Spo` queda aprobado como nombre funcional observable por decisión explícita del usuario.
- Convención de repositorio para carpeta de tool: el trabajo debe ubicarse en `tools/Connect-Spo`, reemplazando la carpeta histórica `tools/sharepoint-auth-unified/`.
- Convención de repositorio para módulos PowerShell no compilados: el módulo reusable aprobado debe ubicarse en `modules/Connect-Spo`.
- Una sesión PowerShell con `Connect-Spo` autenticado exitosamente puede exponer contexto activo solo dentro de esa sesión/runspace, sin persistencia en disco.

## Mensajes Mínimos Funcionales Propuestos

- Cancelación: `Autenticación cancelada por el usuario. No se continuará con la operación de SharePoint.`
- Permisos insuficientes: `Autenticación completada, pero la cuenta o la aplicación no tiene permisos suficientes para el sitio u operación solicitada.`
- Configuración inválida o incompleta: `No se puede iniciar autenticación: falta o es inválido uno de los datos requeridos: SiteUrl, TenantId o ClientId.`

## Criterios de Éxito de la Épica

- Existe al menos una historia aprobable que describe el comportamiento común de login para tools SharePoint.
- Existe una historia aprobable que describe la publicación y consumo funcional de `Connect-Spo` como módulo PowerShell reusable.
- La historia cubre ausencia de prompts de contraseña, parámetros comunes, modos de autenticación, errores claros y no persistencia de secretos.
- La épica no prescribe implementación ni arquitectura.

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-13 | Discovery Agent | Creación inicial del spec de épica de autenticación interactiva unificada. |
| 0.2.0 | 2026-06-13 | Discovery Agent | Incorpora respuestas de Discovery sobre ClientId vía ambiente, Get-SpoListNames, DeviceCode y mensajes mínimos. |
| 0.3.0 | 2026-06-13 | Discovery Agent | Cambia estado a APROBADO por aprobación explícita del usuario. |
| 0.4.0 | 2026-06-13 | Spec Design Agent | Incorpora `Connect-Spo` como comando público principal esperado por solicitud explícita del usuario. |
| 0.5.0 | 2026-06-13 | Spec Design Agent | Incorpora `tools/Connect-Spo` como ubicación objetivo del tool aprobado `Connect-Spo`. |
| 0.6.0 | 2026-06-14 | Spec Design Agent | Agrega historia para publicar `Connect-Spo` como módulo reusable en `modules/Connect-Spo` importable por nombre. |
| 0.7.0 | 2026-06-15 | Spec Design Agent | Agrega historia para registrar contexto SharePoint activo de sesión reutilizable por tools adoptantes. |
| 0.8.0 | 2026-06-18 | Spec Design Agent | Extiende la historia de contexto activo para evitar login repetido cuando la conexión existente sigue válida para el mismo sitio y app. |
