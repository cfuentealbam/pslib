# ===========================================================================
# Control de Cambios
# v0.1.0 | 2026-06-12 | Dev Agent | Implementacion inicial
# v0.1.2 | 2026-06-12 | Dev Agent | Migracion estructural a tools/Get-SpoListNames
# v0.2.0 | 2026-06-14 | Implementation Agent | Consume autenticacion mediante modulo Connect-Spo importado por nombre
# ===========================================================================

<#
.SYNOPSIS
Lista nombres tecnicos y visibles de listas en un sitio SharePoint Online.

.DESCRIPTION
Autentica contra un sitio SharePoint Online mediante el modulo Connect-Spo
importado por nombre y devuelve listas no documentales visibles. El campo
InternalName se mapea desde EntityTypeName segun lo aprobado en el spec de la
historia.

.PARAMETER SiteUrl
URL absoluta del sitio SharePoint Online a consultar.

.PARAMETER AuthMode
Modo de autenticacion a solicitar a Connect-Spo.

.PARAMETER ClientId
ClientId del app registration de Entra ID. Si se omite, el script intenta
resolverlo desde ENTRAID_APP_ID, ENTRAID_CLIENT_ID o AZURE_CLIENT_ID.

.PARAMETER TenantId
Tenant de Entra ID requerido por Connect-Spo. Si se omite, el script intenta
resolverlo desde AZURE_TENANT_ID.

.OUTPUTS
PSCustomObject. Objetos con propiedades InternalName y VisibleTitle.

.EXAMPLE
.\Get-SpoListNames.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -AuthMode DeviceLogin -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "contoso.onmicrosoft.com"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^https://')]
    [string]$SiteUrl,

    [Parameter()]
    [ValidateSet('Interactive', 'DeviceLogin')]
    [string]$AuthMode = 'Interactive',

    [Parameter()]
    [string]$ClientId

    ,

    [Parameter()]
    [string]$TenantId
)

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
        Connect-Spo -SiteUrl $SiteUrl -TenantId $TenantId -ClientId $ClientId -AuthMode $connectSpoAuthMode -ErrorAction Stop | Out-Null
    }
    catch {
        throw "No se pudo autenticar mediante Connect-Spo para el sitio '$SiteUrl'. $($_.Exception.Message)"
    }
}

function Get-SpoListNames {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
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

    <#
    .SYNOPSIS
    Lista nombres tecnicos y visibles de listas en un sitio SharePoint Online.

    .DESCRIPTION
    Autentica contra un sitio SharePoint Online mediante el modulo Connect-Spo
    importado por nombre y devuelve listas no documentales visibles. El campo
    InternalName se mapea desde EntityTypeName segun lo aprobado en el spec de
    la historia.

    .PARAMETER SiteUrl
    URL absoluta del sitio SharePoint Online a consultar.

    .PARAMETER AuthMode
    Modo de autenticacion a solicitar a Connect-Spo.

    .PARAMETER ClientId
    ClientId del app registration de Entra ID. Si se omite, el script intenta
    resolverlo desde ENTRAID_APP_ID, ENTRAID_CLIENT_ID o AZURE_CLIENT_ID.

    .PARAMETER TenantId
    Tenant de Entra ID requerido por Connect-Spo. Si se omite, el script
    intenta resolverlo desde AZURE_TENANT_ID.

    .OUTPUTS
    PSCustomObject. Objetos con propiedades InternalName y VisibleTitle.

    .EXAMPLE
    .\Get-SpoListNames.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -ClientId "00000000-0000-0000-0000-000000000000" -TenantId "contoso.onmicrosoft.com"
    #>

    $resolvedClientId = Resolve-GetSpoListNamesClientId -ClientId $ClientId
    $resolvedTenantId = Resolve-GetSpoListNamesTenantId -TenantId $TenantId

    Invoke-GetSpoListNamesAuthentication -SiteUrl $SiteUrl -TenantId $resolvedTenantId -ClientId $resolvedClientId -AuthMode $AuthMode

    try {
        $lists = Get-PnPList -Includes 'EntityTypeName', 'Title', 'Hidden', 'BaseType' -ErrorAction Stop
    }
    catch {
        throw "No se pudieron consultar las listas del sitio '$SiteUrl'. $($_.Exception.Message)"
    }

    $lists |
        Where-Object {
            -not $_.Hidden -and "$($_.BaseType)" -ne 'DocumentLibrary'
        } |
        Sort-Object -Property Title |
        Select-Object @{
            Name       = 'InternalName'
            Expression = { $_.EntityTypeName }
        }, @{
            Name       = 'VisibleTitle'
            Expression = { $_.Title }
        }
}

Get-SpoListNames @PSBoundParameters
