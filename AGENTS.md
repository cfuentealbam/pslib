# pslib - Instrucciones para OpenCode

## Proposito

Este repositorio es una incubadora exclusivamente de PowerShell.

- El desarrollo nuevo de scripts, CLIs y utilidades ejecutables vive en `tools/{NombreTool}`.
- Antes de crear la carpeta de un tool nuevo, se debe acordar explicitamente con el usuario el mejor nombre del tool.
- La carpeta de trabajo debe llamarse exactamente igual que el tool aprobado, respetando mayusculas/minusculas. Ejemplo: `Connect-Spo` -> `tools/Connect-Spo`.
- El desarrollo nuevo de modulos PowerShell no compilados vive en `modules/{NombreModulo}` cuando el spec aplicable lo apruebe.
- El objetivo del repo es incubar scripts, CLIs, modulos PowerShell y utilidades de automatizacion en PowerShell.
- No planifiques trabajo en `mcp/` bajo la configuracion vigente, salvo aprobacion explicita del usuario.

El flujo formal vigente es:

`Discovery -> Product/Epic/Story Specs -> Dev Spec por Historia -> Implementacion -> Testing -> Revision Critica -> Documentacion`

## Estructura del Proyecto

```text
pslib/
|- AGENTS.md
|- opencode.json
|- .ia-templates/
|- tools/
|  `- {NombreTool}/
|     |- plan/
|     |- src/
|     |  `- {Nombre}.ps1
|     |- tests/
|     `- docs/
`- modules/
   `- {NombreModulo}/
      |- {NombreModulo}.psd1
      `- {NombreModulo}.psm1
```

Los artefactos de proceso viven directamente en `tools/{NombreTool}/plan/`, incluso cuando una historia del producto agregue empaquetado bajo `modules/`.

## Convencion de Archivos de Plan

Todos los artefactos de proceso viven en `tools/{NombreTool}/plan/`, en `kebab-case` y con prefijos numericos estables:

```text
00-{producto}-spec.md
NN-{epica}-spec.md
NN-MM-{historia}-spec.md
NN-MM-{historia}-dev-spec.md
NN-MM-{historia}-retro.md
NN-MM-{historia}-test.md
NN-MM-{historia}-review.md
```

- `00-{producto}-spec.md`: producto, problema, usuarios, alcance, fuera de alcance, restricciones y epicas.
- `NN-{epica}-spec.md`: objetivo de la epica, historias incluidas y dependencias funcionales.
- `NN-MM-{historia}-spec.md`: objetivo, comportamiento observable, criterios de aceptacion y fuera de alcance.
- `NN-MM-{historia}-dev-spec.md`: diseno tecnico e implementacion de una sola historia.
- `NN-MM-{historia}-retro.md`, `NN-MM-{historia}-test.md`, `NN-MM-{historia}-review.md`: implementacion, testing y revision critica de esa historia.
- No reutilices numeros si una epica o historia se cancela; marca el documento como cancelado o deja constancia en Control de Cambios.

## Flujo de Trabajo

| Etapa | Comando OpenCode | Rol | Entrada | Salida |
|---|---|---|---|---|
| Discovery | `/discover` | Discovery Agent | Descripcion en lenguaje natural | `plan/00-{producto}-spec.md`, `plan/NN-{epica}-spec.md`, `plan/NN-MM-{historia}-spec.md` |
| Planning | `/plan` | Planning Agent | `plan/NN-MM-{historia}-spec.md` aprobado | `plan/NN-MM-{historia}-dev-spec.md` |
| Implementacion | `/implement` | Dev Agent | `plan/NN-MM-{historia}-dev-spec.md` aprobado | codigo en `src/` o `modules/` segun spec + `plan/NN-MM-{historia}-retro.md` |
| Testing | `/test` | Testing Agent | codigo + `plan/NN-MM-{historia}-dev-spec.md` + retro | `plan/NN-MM-{historia}-test.md` |
| Revision Critica | `/review` | Critical Review Agent | historia, dev spec, test y codigo | `plan/NN-MM-{historia}-review.md` |
| Documentacion | `/document` | Docs Agent | historias aprobadas + codigo aprobado | `docs/README.md` |

La orquestacion OpenCode vive en `.opencode/agents/`, los entrypoints en `.opencode/commands/` y el skill reusable del flujo en `.opencode/skills/pslib-workflow/SKILL.md`.

## Reglas de Transicion

- Una etapa solo inicia si la etapa anterior tiene estado `APROBADO` en su documento de salida.
- El usuario debe aprobar explicitamente el spec de historia `NN-MM-{historia}-spec.md` antes de Planning.
- Discovery define QUE se construira: producto, epicas e historias. No define arquitectura, estructura interna del script, funciones, TODOs tecnicos ni estrategia.
- Planning se ejecuta por historia. No crea un `dev-spec` monolitico ni mezcla historias.
- Si durante Planning, Implementacion, Testing, Revision Critica o Documentacion se detecta una funcionalidad solicitada o necesaria que no esta cubierta por los specs vigentes de producto, epica o historia, se debe detener esa etapa y volver a Discovery antes de continuar.
- `/spec_design` puede usarse como submodo de Discovery para refinar punto a punto una funcionalidad fuera de alcance, ambigua o insuficientemente especificada.
- En este retorno a Discovery, el agente debe proponer un solo punto de diseno a la vez, discutir alternativas y esperar aprobacion explicita antes de modificar el spec de producto, epica o historia correspondiente.
- Si el punto requiere comportamiento estandar, protocolo, CLI historica, API o herramienta externa, el agente debe investigar fuentes primarias u oficiales antes de proponer.
- No se debe modificar `NN-MM-{historia}-dev-spec.md` ni implementar codigo para funcionalidad fuera de spec hasta que el spec aplicable sea actualizado y aprobado explicitamente.
- Si un spec aprobado de producto, epica o historia cambia y afecta una historia, se debe volver a Planning para crear o actualizar su `NN-MM-{historia}-dev-spec.md` antes de Implementacion.
- El usuario debe aprobar explicitamente `NN-MM-{historia}-dev-spec.md` antes de Implementacion.
- Antes de Testing, la implementacion debe crear `plan/NN-MM-{historia}-retro.md`.
- Sin retro de la historia, no se avanza a Testing.
- El Testing Agent puede devolver a Implementacion con estado `FALLA`.
- El Review Agent puede devolver a Planning o Implementacion con estado `REQUIERE_REFACTORING` y cambios en `NN-MM-{historia}-dev-spec.md`.

## Estados de Documentos

Cada documento de control declara su estado en la primera linea despues del titulo:

```text
**Estado:** BORRADOR | EN_REVISION | APROBADO | FALLA | REQUIERE_REFACTORING
```

## Convenciones

### Control de Cambios en Markdown

Cada artefacto Markdown debe incluir al final:

```markdown
## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | YYYY-MM-DD | Nombre Agente | Descripcion del cambio |
```

### Control de Cambios en PowerShell

Cada script principal o archivo PowerShell relevante debe comenzar con:

```powershell
# ===========================================================================
# Control de Cambios
# v0.1.0 | YYYY-MM-DD | Nombre Agente | Descripcion
# ===========================================================================
```

### Codigo PowerShell

- Usa nombres de comandos `Verb-Noun` con verbos aprobados.
- La implementacion de scripts vive en `tools/{NombreTool}/src/`.
- La implementacion de modulos PowerShell no compilados vive en `modules/{NombreModulo}/` e incluye manifiesto `.psd1` y modulo de script `.psm1` cuando el spec aplicable lo apruebe.
- Prefiere scripts `.ps1` con un entrypoint claro para herramientas bajo `tools/`; usa modulos solo cuando el spec lo solicite y apruebe.
- Usa `CmdletBinding()` y validacion de parametros en toda funcion publica.
- Agrega ayuda basada en comentarios en toda API publica.
- No agregues dependencias fuera del `NN-MM-{historia}-dev-spec.md` vigente.
- No implementes fuera del alcance aprobado.
- Comenta solo decisiones no evidentes.

## Comandos de Verificacion

Ejecuta desde `tools/{NombreTool}` cuando corresponda para scripts:

```powershell
Invoke-Pester -Path tests -Output Detailed
Invoke-ScriptAnalyzer -Path src -Recurse
pwsh -File ./src/{Nombre}.ps1
```

Si el script requiere argumentos, reemplaza el ultimo comando por un smoke test equivalente del entrypoint real.

Para modulos PowerShell, ajusta las verificaciones al `NN-MM-{historia}-dev-spec.md` aprobado, incluyendo como minimo analisis sobre `modules/{NombreModulo}` e importacion del manifiesto o modulo cuando corresponda.

### Artefactos temporales en OneDrive / Windows

- Evita que Pester, analizadores u otras herramientas escriban caches o temporales en OneDrive si ya hubo `Access denied`, `PermissionError`, `unable to open database file` o fallas de `rename`.
- Si una verificacion necesita rutas temporales fuera del directorio sincronizado, usa una ubicacion temporal preaprobada y documenta la limitacion ambiental.
- No intentes borrar con `Remove-Item` artefactos bloqueados en OneDrive tras un primer `Access denied`; si hace falta borrarlos, solicita aprobacion para la ruta exacta.

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-12 | OpenCode | Configuracion inicial de OpenCode para `pslib`, basada en `../pylib` y adaptada a desarrollos PowerShell |
| 0.2.0 | 2026-06-12 | OpenCode | Restringe `pslib` a incubacion exclusiva de scripts PowerShell en `tools/` |
| 0.3.0 | 2026-06-12 | Spec Design Agent | Permite modulos PowerShell no compilados bajo `modules/` con aprobacion de spec y mantiene `mcp/` restringido salvo aprobacion explicita |
| 0.4.0 | 2026-06-13 | OpenCode | Agrega regla para acordar con el usuario el nombre exacto del tool antes de crear `tools/{NombreTool}` |
