# Reporte de Testing: {Titulo de Historia}

**Estado:** BORRADOR

**Desarrollo:** `{ruta_del_desarrollo}`
**Version evaluada:** {version del codigo}
**Fecha:** {YYYY-MM-DD}
**Testing Agent:** Testing Agent

---

## Resumen Ejecutivo

{Una o dos frases: resultado general, estado final APROBADO o FALLA.}

---

## Entorno de Testing

- PowerShell: {version}
- Sistema operativo: {OS}
- Dependencias instaladas: {lista o "ver script y entorno"}

---

## Resultados por Criterio de Aceptacion

| Criterio | Resultado | Test asociado | Observacion |
|----------|-----------|---------------|-------------|
| {criterio 1} | PASS / FAIL | `{Nombre}.Tests.ps1` | {si aplica} |
| {criterio 2} | PASS / FAIL | `{Nombre}.Tests.ps1` | {si aplica} |

---

## Resultados de Tests

### Ejecucion

```powershell
Invoke-Pester -Path tests -Output Detailed
{output de Pester}
```

### Analisis Estatico

```powershell
Invoke-ScriptAnalyzer -Path src -Recurse
{output del analizador}
```

---

## Casos de Borde Verificados

| Caso | Comportamiento esperado | Resultado |
|------|-------------------------|-----------|
| {caso borde 1} | {que deberia pasar} | PASS / FAIL |
| {caso borde 2} | {que deberia pasar} | PASS / FAIL |

---

## Problemas Encontrados

### Problema 1 (si aplica)

- **Descripcion:** {que fallo}
- **Severidad:** Alta / Media / Baja
- **Reproducible:** Si / No
- **Recomendacion:** {correccion sugerida}

---

## Verificacion de Smoke Test

```powershell
{comando_smoke_test}
{output del smoke test}
```

---

## Decision Final

**Estado:** APROBADO / FALLA

**Justificacion:** {razon de la decision}

**Proximo paso:** {Iniciar Review Agent / Devolver a Dev Agent con issues arriba}

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | {YYYY-MM-DD} | Testing Agent | Reporte inicial |
