# Story Spec: Listar nombres internos, visibles y tipos de columnas por identidad de lista

**Estado:** APROBADO

**Herramienta:** `Get-SpoListColumnNames`
**Producto:** `00-get-spo-list-column-names-spec.md`
**Epica:** `01-list-column-discovery-spec.md`
**Historia:** `01-01-list-column-names-and-types`
**Fecha de Discovery:** 2026-06-15

---

## Historia de Usuario

Como administrador u operador de SharePoint, quiero consultar una lista por su GUID o por el `Title` desplegado por `Get-SpoListNames` y obtener los nombres internos, nombres visibles y tipos de sus columnas desplegables, para usar las referencias correctas en automatizaciones e integraciones.

---

## Descripcion Funcional

La herramienta recibe el GUID o el `Title` de una lista SharePoint Online y devuelve un inventario de columnas/campos desplegables de esa lista. Cada fila del resultado debe incluir el nombre interno de la columna, el nombre visible o externo y el tipo reportado por SharePoint/PnP.

La herramienta debe usar el mismo contrato de autenticacion ya aprobado para tools SharePoint del repo: puede conectarse explicitamente con `SiteUrl`, `TenantId`, `ClientId` y `AuthMode`, o reutilizar el contexto activo creado por `Connect-Spo` cuando esos parametros se omiten.

`ListGuid` y `ListTitle` son alternativas mutuamente excluyentes. `ListTitle` corresponde al valor `Title` que despliega `Get-SpoListNames`.

Para descartar campos internos de SharePoint, la herramienta debe aplicar este filtro:

```powershell
Where-Object {
    -not $_.Hidden -and
    -not $_.ReadOnlyField -and
    -not $_.Sealed -and
    (-not $_.FromBaseType -or $_.InternalName -eq 'Title')
}
```

---

## Entradas y Salidas

### Entradas

| Entrada | Tipo funcional | Descripcion | Requerido |
|---------|----------------|-------------|-----------|
| `ListGuid` | GUID | Identificador unico de la lista objetivo dentro del sitio/web. | Si no se entrega `ListTitle` |
| `ListTitle` | Texto | Title de la lista objetivo, tal como lo despliega `Get-SpoListNames`. | Si no se entrega `ListGuid` |
| Contexto SharePoint activo | Estado de sesion | Contexto registrado por `Connect-Spo` con conexion PnP y `SiteUrl`. | Si no se entrega `SiteUrl` |
| `SiteUrl` | URL SharePoint | Sitio objetivo entregado explicitamente por el operador. | No, si existe contexto activo |
| `TenantId` | Identificador de tenant | Tenant usado para autenticar explicitamente si no se reutiliza contexto. | No, si existe contexto activo |
| `ClientId` | Identificador de aplicacion | App Registration usada explicitamente si no se reutiliza contexto. | No, si existe contexto activo |
| `AuthMode` | Modo de autenticacion | `Interactive` o `DeviceLogin` para autenticacion explicita. | No |

### Salidas

| Salida | Tipo funcional | Descripcion |
|--------|----------------|-------------|
| `InternalName` | Texto | Nombre interno tecnico de la columna/campo. |
| `DisplayName` | Texto | Nombre visible o externo mostrado al usuario. |
| `Type` | Texto | Tipo de columna/campo reportado por SharePoint/PnP. |

---

## Comportamiento Observable

1. Dado un contexto activo creado por `Connect-Spo`, cuando el operador ejecuta `Get-SpoListColumnNames -ListGuid <guid>`, entonces la herramienta consulta las columnas de esa lista usando el sitio y conexion activos.
2. Dado un contexto activo creado por `Connect-Spo`, cuando el operador ejecuta `Get-SpoListColumnNames -ListTitle <title>`, entonces la herramienta consulta las columnas de la lista con ese Title usando el sitio y conexion activos.
3. Dado `SiteUrl`, `TenantId`, `ClientId` y `ListGuid` o `ListTitle`, cuando el operador ejecuta la herramienta con parametros explicitos, entonces se autentica mediante `Connect-Spo` y consulta la lista indicada.
4. Dado que la lista existe y es accesible, cuando la consulta termina, entonces se devuelven objetos con `InternalName`, `DisplayName` y `Type` solo para campos desplegables.
5. Dado que no existe contexto activo y no se entrega `SiteUrl`, cuando se ejecuta la herramienta, entonces informa: `No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.`
6. Dado que la lista no existe o no es accesible, cuando se ejecuta la herramienta, entonces informa claramente que no pudo obtener las columnas de la lista objetivo.
7. Dado que el operador entrega `ListGuid` y `ListTitle` en la misma ejecucion, PowerShell rechaza la combinacion de parametros.
8. Dado que SharePoint devuelve campos internos, ocultos, de solo lectura, sellados o provenientes del tipo base distinto de `Title`, entonces la herramienta los excluye de la salida.
9. Dado que el operador ejecuta la herramienta sin `-Verbose`, entonces no se emiten mensajes auxiliares de estado, progreso o diagnostico.
10. Dado que el operador ejecuta la herramienta con `-Verbose`, entonces se muestran los mensajes informativos que hasta ahora se mostraban por defecto.

---

## Criterios de Aceptacion

- [ ] Dado un GUID de lista valido y contexto activo, la herramienta lista las columnas de la lista sin pedir parametros de conexion.
- [ ] Dado un Title de lista valido y contexto activo, la herramienta lista las columnas de la lista sin pedir parametros de conexion.
- [ ] Dado un GUID de lista valido y parametros explicitos de conexion, la herramienta autentica mediante `Connect-Spo` y lista las columnas.
- [ ] Dado un Title de lista valido y parametros explicitos de conexion, la herramienta autentica mediante `Connect-Spo` y lista las columnas.
- [ ] Cada columna devuelta incluye `InternalName`, `DisplayName` y `Type`.
- [ ] La salida excluye campos con `Hidden`, `ReadOnlyField` o `Sealed` verdadero.
- [ ] La salida excluye campos con `FromBaseType` verdadero salvo `InternalName = 'Title'`.
- [ ] Si falta contexto activo y no hay parametros suficientes, la herramienta falla antes de consultar SharePoint con el mensaje aprobado.
- [ ] Si la lista no existe, la herramienta informa un error claro y no devuelve datos ambiguos.
- [ ] `ListGuid` y `ListTitle` son mutuamente excluyentes.
- [ ] La herramienta no modifica listas, columnas ni items.
- [ ] En modo Quiet, la herramienta conserva la salida funcional de columnas pero no emite mensajes auxiliares.
- [ ] Con `-Verbose`, la herramienta muestra los mensajes auxiliares de estado, progreso o diagnostico.

---

## Fuera de Alcance de la Historia

- Modificar columnas.
- Leer o modificar items.
- Consultar multiples listas.
- Parametrizar la inclusion de campos internos.
- Exportar automaticamente resultados.
- Crear modulo bajo `modules/`.

---

## Ejemplo Funcional

Despues de conectar:

```powershell
Connect-Spo -SiteUrl "https://globesacl.sharepoint.com/sites/GDS-PM" -TenantId "globesacl.onmicrosoft.com" -ClientId "<client-id>" -AuthMode DeviceCode
Get-SpoListColumnNames -ListGuid "c8f7f928-3cbd-46bd-8174-4f66985491ec"
Get-SpoListColumnNames -ListTitle "Incidentes"
```

Salida conceptual:

```text
InternalName       DisplayName       Type
------------       -----------       ----
Title              Titulo            Text
Created            Creado            DateTime
Modified           Modificado        DateTime
```

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-15 | Discovery Agent | Story spec inicial para listar nombres internos, visibles y tipos de columnas por GUID de lista. |
| 0.2.0 | 2026-06-16 | Spec Design Agent | Aprueba `ListTitle` como alternativa mutuamente excluyente a `ListGuid`, usando el Title mostrado por `Get-SpoListNames`. |
| 0.3.0 | 2026-06-16 | Spec Design Agent | Aprueba filtrar campos internos con `Hidden`, `ReadOnlyField`, `Sealed` y `FromBaseType`, conservando `Title`. |
| 0.4.0 | 2026-06-18 | Spec Design Agent | Aprueba modo Quiet por defecto y `-Verbose` para mensajes auxiliares del comando. |
