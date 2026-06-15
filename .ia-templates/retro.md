# Retro de Implementacion: {Nombre del Desarrollo}

**Desarrollo:** `{ruta_del_desarrollo}`
**Version implementada:** {version}
**Fecha:** {YYYY-MM-DD}
**Dev Agent:** Dev Agent

---

## Metricas Objetivas

| Metrica | Valor |
|---------|-------|
| Inicio | {YYYY-MM-DD HH:MM} |
| Fin | {YYYY-MM-DD HH:MM} |
| Duracion total | {X min} |
| Invocaciones a lint | {N} |
| Invocaciones a test runner | {N} |
| Tests al inicio / al final | {N} / {N} |

---

## Inventario de Cambios

| Archivo | Accion | +Lineas | -Lineas | Notas |
|---------|--------|---------|---------|-------|
| `src/{Nombre}.ps1` | creado / modificado | +{N} | -{N} | entrypoint principal |
| `src/{Verb-Noun}.ps1` | creado / modificado | +{N} | -{N} | comando reusable, si aplica |
| `src/{Helper}.ps1` | creado / modificado | +{N} | -{N} | helper interno, si aplica |
| `tests/{Nombre}.Tests.ps1` | creado / modificado | +{N} | -{N} | |
| `NN-MM-{historia}-dev-spec.md` | modificado | +{N} | -{N} | TODOs marcados [x] |

**Resumen:** {N} archivos modificados, +{N} / -{N} lineas netas.

---

## Errores de Compilacion y Test Encontrados

| # | Clase de error | Archivo:linea | Arreglo aplicado | Intentos fallidos |
|---|----------------|---------------|------------------|-------------------|
| 1 | {tipo} | `{archivo}:{linea}` | {descripcion del fix} | {si hubo intentos previos que no funcionaron} |

*(Si no hubo errores, escribir "Ninguno".)*

---

## Puntos de Friccion

Respuestas a las preguntas especificas que el dev spec de la historia o el brief pidio responder:

- **{Pregunta o decision tecnica 1}:** {respuesta o hallazgo}
- **{Pregunta o decision tecnica 2}:** {respuesta o hallazgo}

*(Si no hubo friccion, escribir "Ninguno".)*

---

## Ambiguedades y Elecciones Interpretativas

Decisiones que el agente tomo sin guia explicita del brief:

- **{Ambiguedad 1}:** {lo que no estaba claro} -> {decision tomada y razon}
- **{Ambiguedad 2}:** {lo que no estaba claro} -> {decision tomada y razon}

*(Si todo fue explicito, escribir "Ninguna".)*

---

## Resumen Subjetivo

- **Confianza en el resultado (1-5):** {N} - {razon breve}
- **Lo mas dificil:** {descripcion}
- **Lo mas facil:** {descripcion}
- **En que ayudo la herramienta o el proceso:** {descripcion}
- **En que estorbo:** {descripcion}

---

## Limitaciones del Reporte

{Que no pudo medirse o verificarse objetivamente.}

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | {YYYY-MM-DD} | Dev Agent | Retro inicial |
