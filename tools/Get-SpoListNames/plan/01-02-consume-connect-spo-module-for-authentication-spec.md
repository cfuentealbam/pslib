# Consumir Autenticacion Unificada mediante Modulo Connect-Spo - Spec de Historia

**Estado:** APROBADO

**Herramienta:** `Get-SpoListNames`
**Producto:** `00-spo-list-names-spec.md`
**Epica:** `01-site-list-discovery-spec.md`
**Historia:** `01-02-consume-connect-spo-module-for-authentication`
**Fecha de Discovery:** 2026-06-14

---

## Historia de Usuario

Como operador de `Get-SpoListNames`, quiero que la herramienta use la autenticacion unificada de `Connect-Spo` como modulo PowerShell disponible por nombre, para consultar SharePoint de forma consistente sin acoplar la herramienta a rutas internas de otro tool.

---

## Descripcion Funcional

`Get-SpoListNames` debe obtener su contexto de autenticacion SharePoint consumiendo `Connect-Spo` como dependencia de modulo declarada por nombre. La herramienta no debe resolver autenticacion mediante rutas relativas a `tools/Connect-Spo`. Si el modulo no esta disponible para importacion por nombre, la herramienta debe detenerse con un error claro y accionable antes de intentar consultar listas.

---

## Entradas y Salidas

### Entradas

| Entrada | Tipo funcional | Descripcion | Requerido |
|---------|----------------|-------------|-----------|
| Sitio de SharePoint | Identificador de sitio | Sitio objetivo cuyas listas se quieren inspeccionar. | Si |
| Dependencia `Connect-Spo` | Modulo PowerShell | Modulo disponible por nombre para proveer autenticacion SharePoint unificada. | Si |
| Datos de autenticacion aprobados | Contexto de tenant/aplicacion/sitio | Entradas que `Connect-Spo` requiera segun sus specs funcionales aprobados. | Si, segun `Connect-Spo` |

### Salidas

| Salida | Tipo funcional | Descripcion |
|--------|----------------|-------------|
| Contexto autenticado | Estado de sesion/operacion | Autenticacion provista por `Connect-Spo` antes de consultar las listas. |
| Listado de listas | Coleccion tabular o equivalente | Resultado aprobado de `Get-SpoListNames` con listas no documentales, nombre interno y titulo visible. |
| Error accionable | Mensaje al operador | Mensaje claro si `Connect-Spo` no esta disponible o no puede cargarse. |

---

## Comportamiento Observable

1. La herramienta trata `Connect-Spo` como dependencia funcional de modulo PowerShell por nombre.
2. La herramienta no usa rutas relativas a `tools/Connect-Spo` para cargar o ejecutar la autenticacion.
3. Si `Connect-Spo` esta disponible como modulo importable por nombre, la herramienta lo usa para autenticar antes de consultar listas.
4. Si `Connect-Spo` no esta disponible, la herramienta informa un error claro y accionable y no continua con la consulta de listas.
5. El cambio no altera el alcance de salida de `Get-SpoListNames`: se siguen listando listas no documentales con nombre interno y titulo visible.

---

## Criterios de Aceptacion

- [ ] Dado que el modulo `Connect-Spo` esta disponible por nombre, cuando `Get-SpoListNames` requiere autenticacion, entonces consume `Connect-Spo` como dependencia de modulo.
- [ ] Dado que `Get-SpoListNames` consume autenticacion, cuando se revisa su comportamiento funcional, entonces no depende de rutas relativas hacia `tools/Connect-Spo`.
- [ ] Dado que el modulo `Connect-Spo` no esta disponible por nombre, cuando el operador ejecuta `Get-SpoListNames`, entonces recibe un error claro y accionable para exponer o instalar el modulo antes de continuar.
- [ ] Dado un sitio valido, accesible y autenticacion exitosa mediante `Connect-Spo`, cuando se ejecuta `Get-SpoListNames`, entonces conserva el resultado aprobado de listas no documentales con nombre interno y titulo visible.
- [ ] Dado un fallo de autenticacion informado por `Connect-Spo`, cuando `Get-SpoListNames` no puede obtener contexto autenticado, entonces no consulta listas y propaga o presenta un mensaje comprensible para el operador.

---

## Mensaje Minimo Funcional Propuesto

- Modulo no disponible: `No se puede cargar la dependencia Connect-Spo. Instale o exponga el modulo Connect-Spo en PSModulePath y vuelva a ejecutar la operacion.`

---

## Fuera de Alcance de la Historia

- Cambiar los campos de salida de `Get-SpoListNames`.
- Incluir bibliotecas de documentos.
- Implementar o modificar el modulo `Connect-Spo`.
- Usar rutas relativas hacia `tools/Connect-Spo` como mecanismo de integracion.
- Definir detalles tecnicos de importacion, manifiestos, pruebas o manejo interno de excepciones; eso corresponde a Planning.
- Publicar modulos en PowerShell Gallery o modificar persistentemente `PSModulePath`.

---

## Notas de Discovery

- Esta historia incorpora la decision aprobada por el usuario: `Get-SpoListNames` debe consumir `Connect-Spo` por dependencia de modulo disponible por nombre.
- La historia queda en estado `BORRADOR` porque la aprobacion recibida cubre la decision de diseno, pero este documento de historia nuevo requiere aprobacion explicita antes de Planning.
- Al afectar una historia de `Get-SpoListNames`, el siguiente paso formal despues de su aprobacion es volver a Planning para crear o actualizar el dev-spec correspondiente.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-14 | Spec Design Agent | Crea historia funcional para consumir autenticacion mediante modulo `Connect-Spo` por nombre. |
| 0.2.0 | 2026-06-14 | Spec Design Agent | Cambia estado a APROBADO por aprobacion explicita del usuario para pasar a Planning. |
