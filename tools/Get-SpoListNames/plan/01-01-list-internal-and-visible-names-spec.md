# Story Spec: Listar nombres internos y visibles de listas del sitio

**Estado:** APROBADO

**Herramienta:** `Get-SpoListNames`
**Producto:** `00-spo-list-names-spec.md`
**Epica:** `01-site-list-discovery-spec.md`
**Historia:** `01-01-list-internal-and-visible-names`
**Fecha de Discovery:** 2026-06-12

---

## Historia de Usuario

Como administrador u operador de SharePoint, quiero listar las listas no documentales de un sitio con su GUID, `EntityTypeName` y titulo, para poder identificarlas inequívocamente en soporte y automatizaciones.

---

## Descripcion Funcional

El script recibe un sitio de SharePoint como objetivo y devuelve un listado de las listas no documentales accesibles para el operador. Cada elemento del resultado debe permitir distinguir con claridad el GUID interno de la lista, su `EntityTypeName` y el titulo que el usuario ve en SharePoint.

---

## Entradas y Salidas

### Entradas

| Entrada | Tipo funcional | Descripcion | Requerido |
|---------|----------------|-------------|-----------|
| Sitio de SharePoint | Identificador de sitio | Sitio objetivo cuyas listas se quieren inspeccionar. | Si |

### Salidas

| Salida | Tipo funcional | Descripcion |
|--------|----------------|-------------|
| Listado de listas | Coleccion tabular o equivalente | Resultado con una fila o registro por cada lista no documental accesible. |
| GUID | Identificador unico | Valor `Id`/GUID de la lista para referencia inequivoca dentro del sitio/web. |
| EntityTypeName | Texto | Valor `EntityTypeName` de la lista para referencia tecnica. |
| Title | Texto | Nombre visible mostrado al usuario en SharePoint. |
| Mensajes auxiliares | Texto verbose | Mensajes de estado, progreso o diagnostico solo cuando el operador usa `-Verbose`. |

---

## Criterios de Aceptacion

- [ ] Dado un sitio valido y accesible, el script lista las listas no documentales del sitio objetivo.
- [ ] Cada lista devuelta incluye de forma distinguible su `GUID`, `EntityTypeName` y `Title`.
- [ ] Las bibliotecas de documentos no aparecen en el resultado.
- [ ] Si el sitio no puede ser consultado, el script informa el problema de forma clara para el operador.
- [ ] Dado que el operador ejecuta el comando sin `-Verbose`, no se emiten mensajes auxiliares de estado, progreso o diagnostico.
- [ ] Dado que el operador ejecuta el comando con `-Verbose`, se muestran los mensajes informativos que hasta ahora se mostraban por defecto.
- [ ] La salida funcional de listas se conserva en modo Quiet porque es el resultado principal del comando.

---

## Fuera de Alcance de la Historia

- Incluir bibliotecas de documentos.
- Mostrar columnas, plantillas, permisos u otros metadatos adicionales de la lista fuera de `GUID`, `EntityTypeName` y `Title`.
- Soportar consolidacion de multiples sitios en un mismo resultado.

---

## Notas de Discovery

- Se asume una sola consulta por ejecucion a un sitio objetivo.
- La definicion tecnica exacta de como se autentica el operador queda para Planning.
- Para esta historia, el identificador inequivoco de la lista se define como `GUID`, y la referencia tecnica adicional se expone como `EntityTypeName`.
- Los archivos de plan viven en `tools/Get-SpoListNames/plan/`; el nombre logico vigente de la herramienta es `Get-SpoListNames`.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-12 | Discovery Agent | Story spec inicial |
| 0.2.0 | 2026-06-12 | Spec Design Agent | Define `EntityTypeName` como nombre interno de la lista y marca el story spec como aprobado |
| 0.3.0 | 2026-06-12 | Spec Design Agent | Cambia el nombre logico de herramienta de `spo-list-names` a `Get-SpoListNames`; mantiene estado APROBADO, nombres de archivos/ruta de plan historicos y alcance funcional sin cambios |
| 0.4.0 | 2026-06-12 | Dev Agent | Actualiza la referencia de ruta tras la migracion estructural a `tools/Get-SpoListNames` |
| 0.5.0 | 2026-06-15 | Spec Design Agent | Cambia salida aprobada a `GUID`, `EntityTypeName` y `Title` por aprobacion explicita del usuario |
| 0.6.0 | 2026-06-18 | Spec Design Agent | Aprueba modo Quiet por defecto y `-Verbose` para mensajes auxiliares del listado. |
