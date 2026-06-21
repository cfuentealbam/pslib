# ===========================================================================
# Control de Cambios
# v0.1.0 | 2026-06-14 | Implementation Agent | Publica Get-SpoListNames como modulo PowerShell reusable
# v0.1.1 | 2026-06-15 | Codex | Usa la conexion devuelta por Connect-Spo al consultar listas
# v0.2.0 | 2026-06-15 | Dev Agent | Cambia salida a GUID, EntityTypeName y Title
# v0.3.0 | 2026-06-15 | Dev Agent | Permite usar contexto activo de Connect-Spo sin parametros
# v0.4.0 | 2026-06-18 | Dev Agent | Agrega mensajes auxiliares solo mediante Verbose
# ===========================================================================

Set-StrictMode -Version Latest

function Import-GetSpoListNamesAuthenticationModule {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName = 'Connect-Spo'
    )

    try {
        Import-Module -Name $ModuleName -ErrorAction Stop
        $command = Get-Command -Name 'Connect-Spo' -ErrorAction Stop
        if ($command.Name -ne 'Connect-Spo') {
            throw 'Connect-Spo command was not resolved.'
        }
    }
    catch {
        throw 'No se puede cargar la dependencia Connect-Spo. Instale o exponga el modulo Connect-Spo en PSModulePath y vuelva a ejecutar la operacion.'
    }
}

function Resolve-GetSpoListNamesClientId {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [string[]]$EnvironmentVariableNames = @('ENTRAID_APP_ID', 'ENTRAID_CLIENT_ID', 'AZURE_CLIENT_ID')
    )

    if (-not [string]::IsNullOrWhiteSpace($ClientId)) {
        return $ClientId.Trim()
    }

    foreach ($environmentVariableName in $EnvironmentVariableNames) {
        $environmentValue = [Environment]::GetEnvironmentVariable($environmentVariableName)
        if (-not [string]::IsNullOrWhiteSpace($environmentValue)) {
            return $environmentValue.Trim()
        }
    }

    throw "No se pudo resolver ClientId. Proporcionalo con -ClientId o define ENTRAID_APP_ID / ENTRAID_CLIENT_ID / AZURE_CLIENT_ID."
}

function Resolve-GetSpoListNamesTenantId {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$TenantId,

        [Parameter()]
        [string[]]$EnvironmentVariableNames = @('AZURE_TENANT_ID')
    )

    if (-not [string]::IsNullOrWhiteSpace($TenantId)) {
        return $TenantId.Trim()
    }

    foreach ($environmentVariableName in $EnvironmentVariableNames) {
        $environmentValue = [Environment]::GetEnvironmentVariable($environmentVariableName)
        if (-not [string]::IsNullOrWhiteSpace($environmentValue)) {
            return $environmentValue.Trim()
        }
    }

    throw "No se pudo resolver TenantId para Connect-Spo. Proporcionalo con -TenantId o define AZURE_TENANT_ID."
}

function ConvertTo-GetSpoListNamesConnectSpoAuthMode {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Interactive', 'DeviceLogin')]
        [string]$AuthMode
    )

    if ($AuthMode -eq 'DeviceLogin') {
        return 'DeviceCode'
    }

    return 'Interactive'
}

function Invoke-GetSpoListNamesAuthentication {
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

        [Parameter(Mandatory)]
        [ValidateSet('Interactive', 'DeviceLogin')]
        [string]$AuthMode
    )

    Import-GetSpoListNamesAuthenticationModule
    $connectSpoAuthMode = ConvertTo-GetSpoListNamesConnectSpoAuthMode -AuthMode $AuthMode

    try {
        return Connect-Spo -SiteUrl $SiteUrl -TenantId $TenantId -ClientId $ClientId -AuthMode $connectSpoAuthMode -ErrorAction Stop
    }
    catch {
        throw "No se pudo autenticar mediante Connect-Spo para el sitio '$SiteUrl'. $($_.Exception.Message)"
    }
}

function Get-GetSpoListNamesActiveContext {
    [OutputType([object])]
    [CmdletBinding()]
    param()

    $contextVariable = Get-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue
    if ($null -eq $contextVariable) {
        return $null
    }

    $context = $contextVariable.Value
    if ($null -eq $context) {
        return $null
    }

    if (-not $context.PSObject.Properties['Connection']) {
        return $null
    }

    if (-not $context.PSObject.Properties['SiteUrl']) {
        return $null
    }

    if ($null -eq $context.Connection) {
        return $null
    }

    if ([string]::IsNullOrWhiteSpace([string]$context.SiteUrl)) {
        return $null
    }

    return $context
}

function Resolve-GetSpoListNamesExecutionContext {
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$SiteUrl,

        [Parameter()]
        [string]$TenantId,

        [Parameter()]
        [string]$ClientId,

        [Parameter(Mandatory)]
        [ValidateSet('Interactive', 'DeviceLogin')]
        [string]$AuthMode
    )

    if (-not [string]::IsNullOrWhiteSpace($SiteUrl)) {
        Write-Verbose "Usando parametros explicitos para consultar listas en '$SiteUrl'."
        $resolvedClientId = Resolve-GetSpoListNamesClientId -ClientId $ClientId
        $resolvedTenantId = Resolve-GetSpoListNamesTenantId -TenantId $TenantId
        $connection = Invoke-GetSpoListNamesAuthentication -SiteUrl $SiteUrl -TenantId $resolvedTenantId -ClientId $resolvedClientId -AuthMode $AuthMode

        return [pscustomobject]@{
            Connection = $connection
            SiteUrl    = $SiteUrl
        }
    }

    $activeContext = Get-GetSpoListNamesActiveContext
    if ($null -eq $activeContext) {
        throw 'No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.'
    }

    Write-Verbose "Usando contexto SharePoint activo para consultar listas en '$($activeContext.SiteUrl)'."
    return [pscustomobject]@{
        Connection = $activeContext.Connection
        SiteUrl    = $activeContext.SiteUrl
    }
}

function Get-SpoListNames {
    <#
    .SYNOPSIS
    Lista GUID, EntityTypeName y Title de listas en un sitio SharePoint Online.

    .DESCRIPTION
    Autentica contra un sitio SharePoint Online mediante el modulo Connect-Spo
    importado por nombre o reutiliza el contexto SharePoint activo de la sesion
    cuando no se entrega SiteUrl. Devuelve listas no documentales visibles con
    GUID, EntityTypeName y Title.

    .PARAMETER SiteUrl
    URL absoluta del sitio SharePoint Online a consultar. Si se omite, se usa
    el SiteUrl del contexto activo creado por Connect-Spo.

    .PARAMETER AuthMode
    Modo de autenticacion a solicitar a Connect-Spo. DeviceLogin se adapta a
    DeviceCode al invocar Connect-Spo.

    .PARAMETER ClientId
    ClientId del app registration de Entra ID. Si se omite, se intenta resolver
    desde ENTRAID_APP_ID, ENTRAID_CLIENT_ID o AZURE_CLIENT_ID.

    .PARAMETER TenantId
    Tenant de Entra ID requerido por Connect-Spo. Si se omite, se intenta
    resolver desde AZURE_TENANT_ID.

    .OUTPUTS
    PSCustomObject. Objetos con propiedades GUID, EntityTypeName y Title.

    .EXAMPLE
    Import-Module Get-SpoListNames
    Get-SpoListNames -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'contoso.onmicrosoft.com' -ClientId '00000000-0000-0000-0000-000000000000'

    .EXAMPLE
    Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'contoso.onmicrosoft.com' -ClientId '00000000-0000-0000-0000-000000000000' -AuthMode DeviceCode
    Get-SpoListNames
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^https://')]
        [string]$SiteUrl,

        [Parameter()]
        [ValidateSet('Interactive', 'DeviceLogin')]
        [string]$AuthMode = 'Interactive',

        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [string]$TenantId
    )

    $spoExecutionContext = Resolve-GetSpoListNamesExecutionContext -SiteUrl $SiteUrl -TenantId $TenantId -ClientId $ClientId -AuthMode $AuthMode

    try {
        Write-Verbose "Consultando listas del sitio '$($spoExecutionContext.SiteUrl)'."
        $lists = Get-PnPList -Connection $spoExecutionContext.Connection -Includes 'Id', 'EntityTypeName', 'Title', 'Hidden', 'BaseType' -ErrorAction Stop
    }
    catch {
        throw "No se pudieron consultar las listas del sitio '$($spoExecutionContext.SiteUrl)'. $($_.Exception.Message)"
    }

    $visibleLists = @($lists |
        Where-Object {
            -not $_.Hidden -and "$($_.BaseType)" -ne 'DocumentLibrary'
        } |
        Sort-Object -Property Title)

    Write-Verbose "Listas no documentales visibles devueltas: $($visibleLists.Count)."

    $visibleLists | Select-Object @{
            Name       = 'GUID'
            Expression = { $_.Id }
        }, @{
            Name       = 'EntityTypeName'
            Expression = { $_.EntityTypeName }
        }, @{
            Name       = 'Title'
            Expression = { $_.Title }
        }
}

Export-ModuleMember -Function 'Get-SpoListNames'
