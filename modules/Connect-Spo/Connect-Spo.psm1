# ===========================================================================
# Control de Cambios
# v0.1.0 | 2026-06-14 | Implementation Agent | Publica la implementación reusable de Connect-Spo como módulo script
# ===========================================================================

Set-StrictMode -Version Latest

function Test-SharePointUnifiedAuthDependency {
    <#
    .SYNOPSIS
    Verifica que PnP.PowerShell esté disponible.

    .DESCRIPTION
    Confirma que el comando Connect-PnPOnline exista antes de intentar una conexión interactiva.
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Command -Name 'Connect-PnPOnline' -ErrorAction SilentlyContinue)) {
        throw 'No se encontró PnP.PowerShell. Instálalo con: Install-Module PnP.PowerShell -Scope CurrentUser'
    }
}

function Resolve-SharePointUnifiedClientId {
    <#
    .SYNOPSIS
    Resuelve el ClientId para autenticación SharePoint.

    .DESCRIPTION
    Devuelve el ClientId directo o lo obtiene desde variables de ambiente aprobadas.
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [string[]]$EnvironmentVariableNames = @('ENTRAID_CLIENT_ID', 'ENTRAID_APP_ID')
    )

    $resolvedClientId = ''
    if ($null -ne $ClientId) {
        $resolvedClientId = $ClientId.Trim()
    }

    if ($resolvedClientId) {
        return $resolvedClientId
    }

    foreach ($environmentVariableName in $EnvironmentVariableNames) {
        $environmentValue = [Environment]::GetEnvironmentVariable($environmentVariableName)
        if ($environmentValue) {
            $resolvedClientId = $environmentValue.Trim()
            if ($resolvedClientId) {
                return $resolvedClientId
            }
        }
    }

    throw 'No se puede iniciar autenticación: falta o es inválido uno de los datos requeridos: SiteUrl, TenantId o ClientId.'
}

function New-SharePointUnifiedConnectParameters {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteUrl,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,

        [Parameter(Mandatory)]
        [ValidateSet('Interactive', 'DeviceCode')]
        [string]$AuthMode
    )

    $connectParameters = @{
        Url              = $SiteUrl
        ClientId         = $ClientId
        ReturnConnection = $true
        ErrorAction      = 'Stop'
    }

    switch ($AuthMode) {
        'Interactive' {
            $connectParameters.Interactive = $true
        }

        'DeviceCode' {
            $connectParameters.DeviceLogin = $true
            $connectParameters.Tenant = $TenantId
        }
    }

    return $connectParameters
}

function ConvertTo-SharePointUnifiedAuthError {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory)]
        [ValidateSet('Interactive', 'DeviceCode')]
        [string]$AuthMode
    )

    $message = $ErrorRecord.Exception.Message
    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = $ErrorRecord.Exception.GetType().FullName
    }

    if ($message -match '(?i)(cancel|canceled|cancelled|a task was canceled|user canceled)') {
        return 'Autenticación cancelada por el usuario. No se continuará con la operación de SharePoint.'
    }

    if ($message -match '(?i)(access denied|unauthorized|forbidden|insufficient privileges|aadsts|does not have access|permission)') {
        return 'Autenticación completada, pero la cuenta o la aplicación no tiene permisos suficientes para el sitio u operación solicitada.'
    }

    if ($message -match '(?i)(SiteUrl|TenantId|ClientId|falta|missing|required|invalid|inválid)') {
        return 'No se puede iniciar autenticación: falta o es inválido uno de los datos requeridos: SiteUrl, TenantId o ClientId.'
    }

    return "No se pudo completar la autenticación de SharePoint mediante modo $AuthMode. $message"
}

function Connect-Spo {
    <#
    .SYNOPSIS
    Inicia autenticación interactiva unificada para SharePoint.

    .DESCRIPTION
    Resuelve el ClientId desde parámetro o variables de ambiente aprobadas y conecta con PnP.PowerShell
    usando autenticación interactiva o DeviceCode, sin solicitar ni persistir secretos.

    .PARAMETER SiteUrl
    URL del sitio SharePoint objetivo.

    .PARAMETER TenantId
    Identificador del tenant Microsoft 365 / Entra ID.

    .PARAMETER ClientId
    Identificador de la App Registration. Si no se proporciona, se intenta resolver desde variables de ambiente.

    .PARAMETER AuthMode
    Modo de autenticación. Valores permitidos: Interactive o DeviceCode.

    .OUTPUTS
    System.Object

    .EXAMPLE
    Import-Module Connect-Spo
    $connection = Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'contoso.onmicrosoft.com' -ClientId '00000000-0000-0000-0000-000000000000' -AuthMode Interactive
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^https://')]
        [string]$SiteUrl,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [ValidateSet('Interactive', 'DeviceCode')]
        [string]$AuthMode = 'Interactive'
    )

    Test-SharePointUnifiedAuthDependency

    $resolvedClientId = Resolve-SharePointUnifiedClientId -ClientId $ClientId
    $connectParameters = New-SharePointUnifiedConnectParameters -SiteUrl $SiteUrl -TenantId $TenantId -ClientId $resolvedClientId -AuthMode $AuthMode

    try {
        return Connect-PnPOnline @connectParameters
    }
    catch {
        $normalizedMessage = ConvertTo-SharePointUnifiedAuthError -ErrorRecord $_ -AuthMode $AuthMode
        throw $normalizedMessage
    }
}

Export-ModuleMember -Function 'Connect-Spo'
