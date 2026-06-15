# Epic Spec: Empaquetado como modulo PowerShell

**Estado:** APROBADO

**Herramienta:** `Get-SpoListNames`
**Producto:** `00-spo-list-names-spec.md`
**Epica:** `02-powershell-module-packaging`
**Fecha de Discovery:** 2026-06-12

---

## Objetivo de la Epica

Permitir que la funcionalidad aprobada de `Get-SpoListNames` se consuma como modulo PowerShell no compilado desde `modules/Get-SpoListNames/`, con manifiesto y modulo de script importables mediante `Import-Module`.

---

## Valor para el Usuario

El operador puede cargar `Get-SpoListNames` como comando disponible en su sesion PowerShell, sin ejecutar directamente un archivo `.ps1` y sin requerir un cmdlet binario compilado.

---

## Historias de Usuario

| ID | Titulo | Archivo | Estado |
|----|--------|---------|--------|
| 02-01 | Empaquetar Get-SpoListNames como modulo PowerShell no compilado | `02-01-package-get-spo-list-names-as-module-spec.md` | APROBADO |

---

## Dependencias Funcionales

- La funcionalidad base de listar nombres internos y visibles esta definida en `01-01-list-internal-and-visible-names-spec.md`.
- La configuracion de `pslib` permite modulos PowerShell bajo `modules/` con aprobacion de spec.
- El empaquetado debe seguir convenciones de PowerShell para modulos de script, manifiestos e importacion con `Import-Module`.

---

## Fuera de Alcance de la Epica

- Publicacion en PowerShell Gallery.
- Instaladores MSI u otros instaladores del sistema.
- Modulo binario, compilado o basado en cmdlets .NET.
- Cambios bajo `mcp/`.

---

## Notas de Discovery

- Segun Microsoft Learn `about_Modules`, un modulo puede ser una unidad reutilizable que incluye funciones y los modulos escritos en PowerShell son modulos de script.
- Segun Microsoft Learn `Import-Module`, importar un modulo agrega sus miembros a la sesion actual.
- Segun Microsoft Learn sobre manifiestos de modulo, un manifiesto `.psd1` describe el modulo, se ubica en la raiz del modulo y se recomienda usarlo para versionado y organizacion.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-12 | Spec Design Agent | Epic spec inicial para empaquetado como modulo PowerShell no compilado |
| 0.2.0 | 2026-06-14 | Implementation Agent | Corrige inconsistencia de estado: la historia 02-01 ya estaba aprobada y habilita implementacion del modulo |
