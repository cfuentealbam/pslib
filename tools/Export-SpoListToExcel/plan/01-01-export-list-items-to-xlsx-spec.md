# Story Spec: Exportar ítems de lista SharePoint a `.xlsx`

**Estado:** APROBADO

**Herramienta:** `Export-SpoListToExcel`
**Producto:** `00-export-spo-list-to-excel-spec.md`
**Épica:** `01-excel-list-export-spec.md`
**Historia:** `01-01-export-list-items-to-xlsx`
**Fecha de Discovery:** 2026-06-16

---

## Historia de Usuario

Como administrador u operador de SharePoint, quiero exportar el contenido de una lista a un archivo Excel `.xlsx`, usando solo campos desplegables, para entregar datos confiables sin que los textos multilínea rompan el formato tabular.

---

## Descripción Funcional

La herramienta recibe la identidad de una lista SharePoint Online por GUID o por `Title`, obtiene sus campos desplegables con la misma regla funcional usada por `Get-SpoListColumnNames`, consulta los ítems de la lista y genera un archivo `.xlsx`.

El archivo Excel debe mantener cada valor en su celda correspondiente. Los campos de texto multilínea pueden contener saltos de línea, pero esos saltos no deben crear filas adicionales ni desplazar columnas. Los campos de fecha deben mostrarse como dd-MM-yyyy. Los campos numéricos deben mostrarse con separador decimal y sin separador de miles.

Si la lista existe y no contiene ítems, la herramienta debe crear igualmente el archivo `.xlsx`. En ese caso, la hoja debe contener solo la fila de encabezados correspondiente a los campos desplegables exportables y no debe incluir filas de datos. Si el intento de leer ítems devuelve un error recuperable que indique que la lista no tiene filas o ítems, ese error debe interpretarse como colección vacía y no debe impedir la creación del archivo.

---

## Entradas y Salidas

### Entradas

| Entrada | Tipo funcional | Descripción | Requerido |
|---------|----------------|-------------|-----------|
| `ListGuid` | GUID | Identificador único de la lista objetivo dentro del sitio/web. | Si no se entrega `ListTitle` |
| `ListTitle` | Texto | Title de la lista objetivo, tal como lo despliega `Get-SpoListNames`. | Si no se entrega `ListGuid` |
| `OutputPath` | Ruta de archivo | Ruta del archivo `.xlsx` a generar. | Sí |
| `Force` | Confirmación | Permite sobrescribir un archivo existente. | No |
| Contexto SharePoint activo | Estado de sesión | Contexto registrado por `Connect-Spo` con conexión PnP y `SiteUrl`. | Si no se entrega `SiteUrl` |
| `SiteUrl` | URL SharePoint | Sitio objetivo entregado explícitamente por el operador. | No, si existe contexto activo |
| `TenantId` | Identificador de tenant | Tenant usado para autenticar explícitamente si no se reutiliza contexto. | No, si existe contexto activo |
| `ClientId` | Identificador de aplicación | App Registration usada explícitamente si no se reutiliza contexto. | No, si existe contexto activo |
| `AuthMode` | Modo de autenticación | `Interactive` o `DeviceLogin` para autenticación explícita. | No |

### Salidas

| Salida | Tipo funcional | Descripción |
|--------|----------------|-------------|
| Archivo `.xlsx` | Archivo Excel | Contenido de la lista con una fila por ítem y una columna por campo desplegable. |
| Resultado PowerShell | Objeto o mensaje | Información de la ruta exportada y cantidad de ítems exportados. |
| Mensajes auxiliares | Texto verbose | Mensajes de estado, progreso o diagnóstico solo cuando el operador usa `-Verbose`. |

---

## Comportamiento Observable

1. Dado un contexto activo creado por `Connect-Spo`, cuando el operador ejecuta `Export-SpoListToExcel -ListTitle <title> -OutputPath <archivo.xlsx>`, entonces la herramienta exporta los ítems de esa lista usando la conexión activa.
2. Dado `SiteUrl`, `TenantId`, `ClientId` y `ListGuid` o `ListTitle`, cuando el operador ejecuta la herramienta con parámetros explícitos, entonces se autentica mediante `Connect-Spo` y exporta la lista indicada.
3. Dado que la lista existe y tiene ítems, cuando la exportación termina, entonces el archivo `.xlsx` contiene una fila por ítem y columnas correspondientes a campos desplegables.
4. Dado que la lista existe y no tiene ítems, cuando la exportación termina, entonces el archivo `.xlsx` existe y contiene solo los encabezados de las columnas exportables, sin filas de datos.
5. Dado que la lectura de ítems de una lista vacía devuelve un error recuperable identificable como ausencia de filas o ítems, cuando se ejecuta la exportación, entonces la herramienta trata ese error como cero ítems y genera el `.xlsx` solo con encabezados.
6. Dado que una columna contiene texto multilínea, cuando se abre el `.xlsx`, entonces el contenido permanece dentro de la celda de esa columna y no crea filas adicionales.
7. Dado que una columna es fecha, cuando se abre el `.xlsx`, entonces sus valores se muestran con formato `dd-MM-yyyy`.
8. Dado que una columna es numérica, cuando se abre el `.xlsx`, entonces sus valores se muestran con separador decimal y sin separador de miles.
9. Dado que SharePoint devuelve campos internos, ocultos, de solo lectura, sellados o provenientes del tipo base distinto de `Title`, entonces la herramienta los excluye de la exportación.
10. Dado que `OutputPath` no termina en `.xlsx`, cuando se ejecuta la herramienta, entonces falla con un error claro.
11. Dado que `OutputPath` ya existe y el operador no usa `Force`, cuando se ejecuta la herramienta, entonces falla sin sobrescribir el archivo existente.
12. Dado que no existe contexto activo y no se entrega `SiteUrl`, cuando se ejecuta la herramienta, entonces informa: `No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.`
13. Dado que el operador ejecuta la herramienta sin `-Verbose`, entonces no se emiten mensajes auxiliares de estado, progreso o diagnóstico.
14. Dado que el operador ejecuta la herramienta con `-Verbose`, entonces se muestran los mensajes informativos que hasta ahora se mostraban por defecto.

---

## Criterios de Aceptación

- [ ] Dado un `ListTitle` válido y contexto activo, la herramienta exporta la lista a `.xlsx`.
- [ ] Dado un `ListGuid` válido y contexto activo, la herramienta exporta la lista a `.xlsx`.
- [ ] Dado un `ListGuid` o `ListTitle` válido y parámetros explícitos de conexión, la herramienta autentica mediante `Connect-Spo` y exporta la lista.
- [ ] La exportación contiene solo campos desplegables según el filtro aprobado de `Get-SpoListColumnNames`.
- [ ] El campo `Title` se conserva aunque provenga de tipo base.
- [ ] Dada una lista válida sin ítems, la herramienta crea un `.xlsx` con solo los encabezados de las columnas exportables y cero filas de datos.
- [ ] Dado que la lectura de ítems falla con un error recuperable atribuible a lista vacía, la herramienta trata el resultado como cero ítems y crea el `.xlsx` solo con encabezados.
- [ ] Los textos multilínea permanecen dentro de sus celdas en Excel.
- [ ] Las fechas se muestran como `dd-MM-yyyy`.
- [ ] Los números se muestran con separador decimal y sin separador de miles.
- [ ] `OutputPath` solo acepta `.xlsx`.
- [ ] La herramienta no sobrescribe archivos existentes sin `Force`.
- [ ] La herramienta no modifica listas, columnas ni ítems.
- [ ] En modo Quiet, la herramienta conserva el archivo `.xlsx` y el resultado funcional, pero no emite mensajes auxiliares.
- [ ] Con `-Verbose`, la herramienta muestra los mensajes auxiliares de estado, progreso o diagnóstico.

---

## Fuera de Alcance de la Historia

- Exportar a CSV, JSON, XML o `.xls`.
- Exportar múltiples listas.
- Exportar adjuntos.
- Filtrar ítems por consulta, vista, CAML u OData.
- Modificar valores antes de exportar por reglas de negocio.
- Crear módulo bajo `modules/`.

---

## Ejemplo Funcional

Después de conectar:

```powershell
Connect-Spo -SiteUrl "https://contoso.sharepoint.com/sites/demo" -TenantId "contoso.onmicrosoft.com" -ClientId "<client-id>" -AuthMode DeviceCode
Export-SpoListToExcel -ListTitle "Incidentes" -OutputPath ".\incidentes.xlsx"
```

Con conexión explícita:

```powershell
Export-SpoListToExcel -SiteUrl "https://contoso.sharepoint.com/sites/demo" -TenantId "contoso.onmicrosoft.com" -ClientId "<client-id>" -ListGuid "00000000-0000-0000-0000-000000000000" -OutputPath ".\incidentes.xlsx"
```

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-16 | Discovery Agent | Story spec inicial para exportar ítems de lista SharePoint a `.xlsx`. |
| 0.2.0 | 2026-06-16 | Discovery Agent | Cambia estado a APROBADO por aprobacion explicita del usuario para pasar a Planning. |
| 0.3.0 | 2026-06-18 | Spec Design Agent | Aprueba modo Quiet por defecto y -Verbose para mensajes auxiliares de exportacion. |
| 0.4.0 | 2026-06-19 | Spec Design Agent | Agrega criterio para listas sin ítems: generar `.xlsx` solo con encabezados de columnas exportables. |
| 0.5.0 | 2026-06-19 | Spec Design Agent | Aclara que errores recuperables al leer una lista vacía se manejan como cero ítems. |





