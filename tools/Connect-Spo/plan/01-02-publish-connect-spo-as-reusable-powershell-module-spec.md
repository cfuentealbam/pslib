# Publicar Connect-Spo como Módulo PowerShell Reutilizable - Spec de Historia

**Estado:** APROBADO

## Historia de Usuario

Como mantenedor de tools PowerShell de SharePoint en `pslib`, quiero consumir `Connect-Spo` como módulo PowerShell disponible por nombre, para reutilizar la autenticación unificada sin depender de rutas relativas entre carpetas de tools.

## Objetivo

Definir el comportamiento observable para publicar la capacidad reusable `Connect-Spo` como módulo PowerShell no compilado bajo `modules/Connect-Spo`, importable por nombre mediante `Import-Module Connect-Spo` cuando esté disponible en `PSModulePath`, y con API pública `Connect-Spo` para tools adoptantes.

## Comportamiento Observable Esperado

1. Los artefactos de proceso de esta capacidad permanecen en `tools/Connect-Spo/plan/`.
2. La capacidad reusable aprobada vive como módulo PowerShell no compilado en `modules/Connect-Spo`.
3. Cuando `modules/Connect-Spo` está disponible a través de `PSModulePath`, el operador o una tool adoptante puede cargarla con `Import-Module Connect-Spo`.
4. Tras importar el módulo, la API pública `Connect-Spo` queda disponible para iniciar la autenticación SharePoint aprobada.
5. Una tool adoptante declara y consume la dependencia por nombre de módulo `Connect-Spo`.
6. Una tool adoptante no usa rutas relativas hacia `tools/Connect-Spo` para acceder a la autenticación.
7. Si el módulo `Connect-Spo` no está disponible o no puede importarse, la tool adoptante informa un error claro y accionable para exponer o instalar el módulo en `PSModulePath` antes de continuar.

## Criterios de Aceptación

- [ ] Dado el repositorio con la historia implementada, existe un módulo PowerShell no compilado `Connect-Spo` bajo `modules/Connect-Spo`.
- [ ] Dado que `modules/Connect-Spo` está disponible en `PSModulePath`, cuando se ejecuta `Import-Module Connect-Spo`, entonces el módulo se carga por nombre.
- [ ] Dado que el módulo fue importado, cuando se inspeccionan sus comandos públicos, entonces expone `Connect-Spo` como API pública.
- [ ] Dado una tool SharePoint adoptante, cuando requiere autenticación unificada, entonces declara y consume la dependencia por nombre de módulo `Connect-Spo`.
- [ ] Dado una tool SharePoint adoptante, cuando consume autenticación unificada, entonces no referencia rutas relativas hacia `tools/Connect-Spo`.
- [ ] Dado que `Connect-Spo` no está disponible en `PSModulePath`, cuando una tool adoptante intenta usarlo, entonces muestra un mensaje claro y accionable para instalar o exponer el módulo y no continúa con una autenticación ambigua.

## Mensaje Mínimo Funcional Propuesto

- Módulo no disponible: `No se puede cargar la dependencia Connect-Spo. Instale o exponga el módulo Connect-Spo en PSModulePath y vuelva a ejecutar la operación.`

## Fuera de Alcance

- Diseño técnico interno del módulo, manifiesto, exportaciones específicas o estrategia de pruebas.
- Publicación en PowerShell Gallery.
- Instalación persistente automática en el perfil del usuario o modificación automática de `PSModulePath`.
- Cambios funcionales propios de una tool adoptante, incluyendo `Get-SpoListNames`; esos cambios deben quedar en specs de la tool adoptante.
- Cambios bajo `mcp/`.

## Notas de Discovery

- Esta historia incorpora la decisión aprobada por el usuario: `Connect-Spo` será un módulo en `modules/Connect-Spo`, importable por `PSModulePath`, y las tools adoptantes deben depender del módulo por nombre.
- La historia queda en estado `BORRADOR` porque la aprobación recibida cubre la decisión de diseño, pero este documento de historia nuevo requiere aprobación explícita antes de Planning.

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-14 | Spec Design Agent | Crea historia funcional para publicar `Connect-Spo` como módulo PowerShell reutilizable importable por nombre. |
| 0.2.0 | 2026-06-14 | Spec Design Agent | Cambia estado a APROBADO por aprobación explícita del usuario para pasar a Planning. |
