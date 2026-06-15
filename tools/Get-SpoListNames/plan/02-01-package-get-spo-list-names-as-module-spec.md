# Story Spec: Empaquetar Get-SpoListNames como modulo PowerShell no compilado

**Estado:** APROBADO

**Herramienta:** `Get-SpoListNames`
**Producto:** `00-spo-list-names-spec.md`
**Epica:** `02-powershell-module-packaging-spec.md`
**Historia:** `02-01-package-get-spo-list-names-as-module`
**Fecha de Discovery:** 2026-06-12

---

## Historia de Usuario

Como administrador u operador de SharePoint, quiero importar `Get-SpoListNames` como modulo PowerShell no compilado, para usar el comando `Get-SpoListNames` desde una sesion PowerShell sin invocar directamente el script `.ps1`.

---

## Descripcion Funcional

El producto debe exponer la funcionalidad aprobada de `Get-SpoListNames` como modulo PowerShell de script bajo `modules/Get-SpoListNames/`. El modulo debe contar con un manifiesto `.psd1` y un archivo de modulo `.psm1`, poder importarse con `Import-Module`, exponer el comando `Get-SpoListNames` en la sesion y presentar ayuda accesible para el comando. El empaquetado no debe convertir la herramienta en un cmdlet .NET compilado ni agregar comportamiento funcional nuevo de SharePoint fuera de la historia base.

---

## Entradas y Salidas

### Entradas

| Entrada | Tipo funcional | Descripcion | Requerido |
|---------|----------------|-------------|-----------|
| Ruta o nombre de modulo | Identificador de modulo PowerShell | Referencia usada por el operador para cargar `modules/Get-SpoListNames` mediante `Import-Module`. | Si |
| Parametros funcionales de Get-SpoListNames | Entradas existentes del comando | Entradas ya aprobadas para consultar el sitio de SharePoint objetivo. | Si, segun historia base |

### Salidas

| Salida | Tipo funcional | Descripcion |
|--------|----------------|-------------|
| Modulo importado | Estado de sesion PowerShell | El comando `Get-SpoListNames` queda disponible en la sesion tras `Import-Module`. |
| Ayuda del comando | Ayuda PowerShell | `Get-Help Get-SpoListNames` muestra ayuda util para el operador. |
| Resultado funcional | Coleccion tabular o equivalente | El comando mantiene el resultado aprobado para listar nombres internos y visibles de listas no documentales. |

---

## Comportamiento Observable

- Existe una estructura de modulo bajo `modules/Get-SpoListNames/`.
- La estructura incluye un manifiesto `Get-SpoListNames.psd1` en la raiz del modulo.
- La estructura incluye un modulo de script `Get-SpoListNames.psm1` en la raiz del modulo o referenciado por el manifiesto.
- El modulo puede importarse con `Import-Module` desde una ruta local del repositorio.
- Tras importar el modulo, `Get-Command Get-SpoListNames` encuentra el comando expuesto por el modulo.
- `Get-Help Get-SpoListNames` muestra ayuda del comando.
- La implementacion expuesta por el modulo es PowerShell no compilado; no depende de un cmdlet .NET propio ni de ensamblados compilados del producto.

---

## Criterios de Aceptacion

- [ ] Dado el repositorio con la historia implementada, existe `modules/Get-SpoListNames/` con archivos de modulo PowerShell no compilado.
- [ ] El manifiesto `modules/Get-SpoListNames/Get-SpoListNames.psd1` describe el modulo y permite cargar el modulo de script correspondiente.
- [ ] `Import-Module` puede cargar el modulo desde la ruta local del repositorio sin requerir instalacion global.
- [ ] Despues de importar el modulo, el comando `Get-SpoListNames` esta disponible en la sesion PowerShell.
- [ ] La ayuda del comando esta expuesta y puede consultarse con `Get-Help Get-SpoListNames`.
- [ ] El comando importado conserva el comportamiento funcional aprobado para listar listas no documentales con nombre interno y titulo visible.
- [ ] No se agrega un cmdlet .NET compilado, modulo binario propio ni artefacto de compilacion para exponer `Get-SpoListNames`.

---

## Fuera de Alcance de la Historia

- Publicacion en PowerShell Gallery.
- Instalador MSI u otro instalador del sistema.
- Modulo binario/compilado o cmdlet .NET propio.
- Cambios bajo `mcp/`.
- Cambios funcionales al descubrimiento de listas fuera de lo aprobado en `01-01-list-internal-and-visible-names-spec.md`.
- Instalacion automatica en `$Env:PSModulePath` o modificacion persistente del perfil del usuario.

---

## Notas de Discovery

- Microsoft Learn `about_Modules` distingue modulos de script escritos en PowerShell de modulos nativos compilados en C#/.NET.
- Microsoft Learn `Import-Module` indica que el comando agrega miembros del modulo a la sesion actual y admite importar por nombre o ruta.
- Microsoft Learn recomienda manifiestos `.psd1` para organizar modulos y mantener informacion de versionado; el manifiesto se nombra como el modulo y vive en la raiz del directorio del modulo.
- El detalle tecnico exacto de exportacion de funciones, versionado del manifiesto, pruebas y reutilizacion del codigo existente queda para Planning.

---

## Control de Cambios

| Version | Fecha | Agente | Descripcion |
|---------|-------|--------|-------------|
| 0.1.0 | 2026-06-12 | Spec Design Agent | Story spec inicial para empaquetar `Get-SpoListNames` como modulo PowerShell no compilado |
| 0.2.0 | 2026-06-12 | Planning Agent | Registra aprobacion explicita del usuario para avanzar con empaquetado, desarrollo e instalacion; habilita Planning de la historia 02-01 |
