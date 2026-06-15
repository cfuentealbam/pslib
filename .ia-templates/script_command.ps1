# ===========================================================================
# {Nombre}.ps1
# {descripcion breve de una linea del script}
#
# Control de Cambios
# v0.1.0 | {YYYY-MM-DD} | Dev Agent | Implementacion inicial
# ===========================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$InputValue
)

function {Verb-Noun} {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    <#
    .SYNOPSIS
    {Descripcion en una linea.}

    .PARAMETER Value
    {Descripcion del parametro.}

    .OUTPUTS
    {Tipo de salida.}

    .EXAMPLE
    {Verb-Noun} -Value "ejemplo"
    #>

    {implementacion}
}

{Verb-Noun} -Value $InputValue
