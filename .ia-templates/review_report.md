# Reporte de Revision Critica: {Nombre del Desarrollo}

**Estado:** BORRADOR

**Desarrollo:** `{ruta_del_desarrollo}`
**Version evaluada:** {version del codigo}
**Fecha:** {YYYY-MM-DD}
**Review Agent:** Critical Review Agent

---

## Resumen Ejecutivo

{Una o dos frases: calidad general observada, decision final APROBADO o REQUIERE_REFACTORING.}

---

## Criterios de Revision

### 1. Correctitud

| Aspecto | Evaluacion | Observacion |
|---------|------------|-------------|
| Logica de negocio | OK / ISSUE | {detalle} |
| Manejo de errores | OK / ISSUE | {detalle} |
| Casos borde | OK / ISSUE | {detalle} |

### 2. Patrones y Diseno

| Aspecto | Evaluacion | Observacion |
|---------|------------|-------------|
| Responsabilidad unica | OK / ISSUE | {detalle} |
| Abstraccion apropiada | OK / ISSUE | {detalle} |
| Evita complejidad innecesaria | OK / ISSUE | {detalle} |
| API publica coherente | OK / ISSUE | {detalle} |

### 3. Calidad del Codigo

| Aspecto | Evaluacion | Observacion |
|---------|------------|-------------|
| Verbos aprobados y nombres claros | OK / ISSUE | {detalle} |
| Parametros y validacion coherentes | OK / ISSUE | {detalle} |
| Sin comentarios redundantes | OK / ISSUE | {detalle} |
| Control de cambios presente | OK / ISSUE | {detalle} |

### 4. Seguridad

| Aspecto | Evaluacion | Observacion |
|---------|------------|-------------|
| Validacion de entradas en boundaries | OK / ISSUE | {detalle} |
| Sin inyeccion de comandos | OK / ISSUE | {detalle} |
| Manejo seguro de datos sensibles | OK / ISSUE | {detalle} |

### 5. Mantenibilidad

| Aspecto | Evaluacion | Observacion |
|---------|------------|-------------|
| Tests adecuados | OK / ISSUE | {detalle} |
| Estructura de modulos clara | OK / ISSUE | {detalle} |
| Sin codigo muerto | OK / ISSUE | {detalle} |

---

## Hallazgos

### Hallazgo 1: {Titulo} (si aplica)

- **Tipo:** Correctitud / Diseno / Calidad / Seguridad / Mantenibilidad
- **Severidad:** Bloqueante / Recomendado / Menor
- **Archivo:** `src/{archivo}.ps1:{linea}`
- **Descripcion:** {que se observo}
- **Recomendacion:** {cambio concreto sugerido}

---

## Propuesta de Refactoring (si aplica)

{Descripcion del refactoring propuesto, incluyendo que cambiaria en el dev spec de la historia para guiar la siguiente iteracion.}

**Cambios en `NN-MM-{historia}-dev-spec.md`:**
- Seccion {X}: {descripcion del cambio}

---

## Decision Final

**Estado:** APROBADO / REQUIERE_REFACTORING

**Justificacion:** {razon de la decision}

**Proximo paso:** {Iniciar Docs Agent / Modificar dev spec de historia y reiniciar desde Planning o Implementacion}

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | {YYYY-MM-DD} | Critical Review Agent | Revision inicial |
