# Autenticación Interactiva Unificada para Tools SharePoint - Review

**Estado:** APROBADO

## Historia Objetivo

- Producto: `tools/Connect-Spo/plan/00-sharepoint-auth-unified-spec.md` (`APROBADO`).
- Épica: `tools/Connect-Spo/plan/01-interactive-sharepoint-auth-spec.md` (`APROBADO`).
- Historia: `tools/Connect-Spo/plan/01-01-unified-interactive-auth-for-sharepoint-tools-spec.md` (`APROBADO`).
- Dev spec revisado: `tools/Connect-Spo/plan/01-01-unified-interactive-auth-for-sharepoint-tools-dev-spec.md` (`EN_REVISION`).
- Retro revisada: `tools/Connect-Spo/plan/01-01-unified-interactive-auth-for-sharepoint-tools-retro.md` (`EN_REVISION`).
- Test report revisado: `tools/Connect-Spo/plan/01-01-unified-interactive-auth-for-sharepoint-tools-test.md` (`APROBADO`).
- Documentación revisada: `tools/Connect-Spo/docs/README.md`.
- Código revisado: `tools/Connect-Spo/src/Connect-Spo.ps1` y `tools/Connect-Spo/tests/Connect-Spo.Tests.ps1`.

## Alcance de la Revisión

Se revisó el cambio aprobado de ubicación a `tools/Connect-Spo` con foco en:

- Ubicación vigente del tool en `tools/Connect-Spo`.
- Script principal `src/Connect-Spo.ps1`.
- Tests `tests/Connect-Spo.Tests.ps1`.
- Referencias de rutas consistentes.
- Ausencia de carpeta vigente `tools/sharepoint-auth-unified`.
- Ausencia de regresiones en `Connect-Spo`, resolución de `ClientId`, modos de autenticación, errores y seguridad.

## Verificaciones Ejecutadas

Desde `tools/Connect-Spo`:

```powershell
Invoke-Pester -Path tests
Invoke-ScriptAnalyzer -Path src -Recurse
pwsh -NoProfile -Command ". ./src/Connect-Spo.ps1; if (Get-Command -Name 'Connect-Spo' -ErrorAction SilentlyContinue) { 'Connect-Spo:Present' } else { 'Connect-Spo:Missing' }; if (Get-Command -Name 'Connect-SharePointUnifiedAuth' -ErrorAction SilentlyContinue) { 'Connect-SharePointUnifiedAuth:Present' } else { 'Connect-SharePointUnifiedAuth:Missing' }; Get-Command Connect-Spo, Resolve-SharePointUnifiedClientId, Test-SharePointUnifiedAuthDependency | Select-Object -ExpandProperty Name"
```

Resultado:

- Pester: `14 passed, 0 failed`.
- ScriptAnalyzer: sin hallazgos reportados.
- Smoke test: `Connect-Spo:Present`, `Connect-SharePointUnifiedAuth:Missing` y resolución correcta de `Connect-Spo`, `Resolve-SharePointUnifiedClientId`, `Test-SharePointUnifiedAuthDependency`.

Desde la raíz del repositorio:

```powershell
Test-Path -LiteralPath "tools/sharepoint-auth-unified"
Test-Path -LiteralPath "tools/Connect-Spo/src/Connect-Spo.ps1"
Test-Path -LiteralPath "tools/Connect-Spo/tests/Connect-Spo.Tests.ps1"
```

Resultado:

- `tools/sharepoint-auth-unified`: no existe.
- `tools/Connect-Spo/src/Connect-Spo.ps1`: existe.
- `tools/Connect-Spo/tests/Connect-Spo.Tests.ps1`: existe.

## Evaluación Crítica

### Correctitud del cambio de ubicación

- La carpeta vigente del tool es `tools/Connect-Spo` y contiene `plan/`, `src/`, `tests/` y `docs/`.
- La carpeta histórica `tools/sharepoint-auth-unified` no existe como ubicación vigente.
- El script principal está en `tools/Connect-Spo/src/Connect-Spo.ps1`.
- Los tests están en `tools/Connect-Spo/tests/Connect-Spo.Tests.ps1` y dot-sourcean `..\src\Connect-Spo.ps1`.
- La documentación de usuario usa rutas `tools\Connect-Spo\src\Connect-Spo.ps1`.

### Ausencia de regresiones funcionales

- `Connect-Spo` permanece como API pública principal y `Connect-SharePointUnifiedAuth` no queda expuesto.
- `Resolve-SharePointUnifiedClientId` mantiene la precedencia `ClientId` directo, `ENTRAID_CLIENT_ID`, `ENTRAID_APP_ID`.
- `Interactive` sigue usando `Interactive = $true` y `ReturnConnection = $true`.
- `DeviceCode` sigue usando `DeviceLogin = $true`, `Tenant = $TenantId` y `ReturnConnection = $true`.
- La normalización de cancelación, permisos/autorización y fallback sigue cubierta por tests.

### Seguridad

- No se detecta uso de `Read-Host`, `Get-Credential`, `-Credentials`, `-ClientSecret`, `-CertificatePath`, `-AccessToken`, `-EnvironmentVariable` ni `-PersistLogin`.
- No se detecta persistencia propia de contraseñas, secretos ni tokens.

### Mantenibilidad

- El traslado mantiene el comportamiento de autenticación sin introducir dependencias ni wrappers nuevos.
- Los nombres físicos del script y tests están alineados con el nombre del tool aprobado.

## Hallazgos

### Bloqueante

Ninguno.

### Recomendado

1. `tools/Connect-Spo/plan/01-01-unified-interactive-auth-for-sharepoint-tools-dev-spec.md:311`  
   - Patrón: referencia de archivo objetivo de tests como `tools/Connect-Spo/tests/SharePointAuthUnified.Tests.ps1`, aunque el cambio vigente exige y ya usa `tests/Connect-Spo.Tests.ps1`.  
   - Alternativa concreta: cambiar esa línea a `Archivo objetivo: tools/Connect-Spo/tests/Connect-Spo.Tests.ps1`.

2. `tools/Connect-Spo/plan/01-01-unified-interactive-auth-for-sharepoint-tools-test.md:29`  
   - Patrón: `Test-Path -LiteralPath 'tools/sharepoint-auth-unified'` se documenta como ejecutado desde `tools/Connect-Spo`; desde ese directorio la ruta relativa no verifica la carpeta histórica real bajo la raíz del repo.  
   - Alternativa concreta: documentar la verificación desde raíz del repositorio o usar una ruta relativa correcta, por ejemplo `Test-Path -LiteralPath '..\sharepoint-auth-unified'` ejecutado desde `tools/Connect-Spo`.

### Menor

1. `tools/Connect-Spo/plan/01-01-unified-interactive-auth-for-sharepoint-tools-retro.md:12`, `:19` y `:31`  
   - Patrón: el documento contiene tres secciones `## Control de Cambios`.  
   - Alternativa concreta: consolidar las entradas en una sola sección final de Control de Cambios, preservando las versiones históricas.

2. `tools/Connect-Spo/plan/01-01-unified-interactive-auth-for-sharepoint-tools-dev-spec.md:251-252` y `:267`  
   - Patrón: TODOs históricos aún mencionan crear/ejecutar sobre `tools/sharepoint-auth-unified`, aunque el mismo dev spec ya tiene TODOs 34-47 para el traslado vigente.  
   - Alternativa concreta: marcar esas líneas como históricas/previas al traslado o moverlas a una subsección explícita de antecedentes para evitar leerlas como instrucciones vigentes.

3. `tools/Connect-Spo/plan/01-01-unified-interactive-auth-for-sharepoint-tools-dev-spec.md:358-361`  
   - Patrón: `Control de Cambios` repite versiones `0.5.0` y `0.6.0`, afectando trazabilidad documental.  
   - Alternativa concreta: renumerar esas entradas de forma monotónica o fusionar las descripciones equivalentes sin cambiar el alcance técnico.

## Decisión

**APROBADO**

No hay bloqueantes. No se actualizó el dev spec porque no se requiere refactoring mínimo para la implementación ni para aprobar la ubicación vigente; los hallazgos son de trazabilidad/documentación de proceso.

## Recomendación de Handoff

Continuar con la adopción/documentación usando `tools/Connect-Spo`, `src/Connect-Spo.ps1` y `tests/Connect-Spo.Tests.ps1` como rutas vigentes. Antes de cierre documental final, corregir las referencias recomendadas en dev spec/test report y consolidar Control de Cambios de la retro.

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-13 | Critical Review Agent | Revisión crítica formal inicial de la historia 01-01 y aprobación sin bloqueantes. |
| 0.2.0 | 2026-06-13 | Critical Review Agent | Revisión crítica formal del rename aprobado a `Connect-Spo`, con aprobación sin bloqueantes y hallazgos menores documentales. |
| 0.3.0 | 2026-06-13 | Critical Review Agent | Revisión crítica formal del traslado a `tools/Connect-Spo`, con aprobación sin bloqueantes y hallazgos documentales. |
