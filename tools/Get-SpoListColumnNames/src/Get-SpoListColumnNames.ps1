# ===========================================================================
# Control de Cambios
# v0.1.0 | 2026-06-15 | Dev Agent | Implementacion inicial de Get-SpoListColumnNames
# v0.2.0 | 2026-06-16 | Dev Agent | Permite consultar columnas por Title de lista
# v0.3.0 | 2026-06-16 | Dev Agent | Descarta campos internos de SharePoint
# v0.4.0 | 2026-06-18 | Dev Agent | Agrega mensajes auxiliares solo mediante Verbose
# ===========================================================================

<#
.SYNOPSIS
Lista nombres internos, visibles y tipos de columnas de una lista SharePoint Online.

.DESCRIPTION
Autentica contra un sitio SharePoint Online mediante el modulo Connect-Spo, o
reutiliza el contexto SharePoint activo de la sesion cuando no se entrega
SiteUrl. Consulta una lista por GUID o por Title, descarta campos internos de
SharePoint y devuelve sus columnas con InternalName, DisplayName y Type.

.PARAMETER SiteUrl
URL absoluta HTTPS del sitio SharePoint Online. Si se omite, se usa el SiteUrl
del contexto activo creado por Connect-Spo.

.PARAMETER ListGuid
GUID de la lista objetivo dentro del sitio.

.PARAMETER ListTitle
Title de la lista objetivo dentro del sitio, tal como lo despliega
Get-SpoListNames.

.PARAMETER AuthMode
Modo de autenticacion a solicitar a Connect-Spo. DeviceLogin se adapta a
DeviceCode al invocar Connect-Spo.

.PARAMETER ClientId
ClientId del app registration de Entra ID. Si se omite, se intenta resolver
desde ENTRAID_APP_ID, ENTRAID_CLIENT_ID o AZURE_CLIENT_ID.

.PARAMETER TenantId
Tenant de Entra ID requerido por Connect-Spo. Si se omite, se intenta resolver
desde AZURE_TENANT_ID.

.OUTPUTS
PSCustomObject. Objetos con propiedades InternalName, DisplayName y Type.

.EXAMPLE
Connect-Spo -SiteUrl "https://contoso.sharepoint.com/sites/demo" -TenantId "contoso.onmicrosoft.com" -ClientId "00000000-0000-0000-0000-000000000000" -AuthMode DeviceCode
.\Get-SpoListColumnNames.ps1 -ListGuid "00000000-0000-0000-0000-000000000000"

.EXAMPLE
Connect-Spo -SiteUrl "https://contoso.sharepoint.com/sites/demo" -TenantId "contoso.onmicrosoft.com" -ClientId "00000000-0000-0000-0000-000000000000" -AuthMode DeviceCode
.\Get-SpoListColumnNames.ps1 -ListTitle "Incidentes"

.EXAMPLE
.\Get-SpoListColumnNames.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/demo" -ListGuid "00000000-0000-0000-0000-000000000000" -TenantId "contoso.onmicrosoft.com" -ClientId "00000000-0000-0000-0000-000000000000"
#>

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
[CmdletBinding(DefaultParameterSetName = 'ByGuid')]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^https://')]
    [string]$SiteUrl,

    [Parameter(Mandatory, ParameterSetName = 'ByGuid')]
    [ValidateNotNullOrEmpty()]
    [guid]$ListGuid,

    [Parameter(Mandatory, ParameterSetName = 'ByTitle')]
    [ValidateNotNullOrEmpty()]
    [string]$ListTitle,

    [Parameter()]
    [ValidateSet('Interactive', 'DeviceLogin')]
    [string]$AuthMode = 'Interactive',

    [Parameter()]
    [string]$ClientId,

    [Parameter()]
    [string]$TenantId
)

function Import-GetSpoListColumnNamesAuthenticationModule {
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

function Resolve-GetSpoListColumnNamesClientId {
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

    throw 'No se pudo resolver ClientId. Proporcionalo con -ClientId o define ENTRAID_APP_ID / ENTRAID_CLIENT_ID / AZURE_CLIENT_ID.'
}

function Resolve-GetSpoListColumnNamesTenantId {
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

    throw 'No se pudo resolver TenantId para Connect-Spo. Proporcionalo con -TenantId o define AZURE_TENANT_ID.'
}

function ConvertTo-GetSpoListColumnNamesConnectSpoAuthMode {
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

function Invoke-GetSpoListColumnNamesAuthentication {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^https://')]
        [string]$SiteUrl,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,

        [Parameter(Mandatory)]
        [ValidateSet('Interactive', 'DeviceLogin')]
        [string]$AuthMode
    )

    Import-GetSpoListColumnNamesAuthenticationModule
    $connectSpoAuthMode = ConvertTo-GetSpoListColumnNamesConnectSpoAuthMode -AuthMode $AuthMode

    try {
        return Connect-Spo -SiteUrl $SiteUrl -TenantId $TenantId -ClientId $ClientId -AuthMode $connectSpoAuthMode -ErrorAction Stop
    }
    catch {
        throw "No se pudo autenticar mediante Connect-Spo para el sitio '$SiteUrl'. $($_.Exception.Message)"
    }
}

function Get-GetSpoListColumnNamesActiveContext {
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

function Resolve-GetSpoListColumnNamesExecutionContext {
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
        $resolvedClientId = Resolve-GetSpoListColumnNamesClientId -ClientId $ClientId
        $resolvedTenantId = Resolve-GetSpoListColumnNamesTenantId -TenantId $TenantId
        $connection = Invoke-GetSpoListColumnNamesAuthentication -SiteUrl $SiteUrl -TenantId $resolvedTenantId -ClientId $resolvedClientId -AuthMode $AuthMode

        return [pscustomobject]@{
            Connection = $connection
            SiteUrl    = $SiteUrl
        }
    }

    $activeContext = Get-GetSpoListColumnNamesActiveContext
    if ($null -eq $activeContext) {
        throw 'No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.'
    }

    return [pscustomobject]@{
        Connection = $activeContext.Connection
        SiteUrl    = $activeContext.SiteUrl
    }
}

function Resolve-GetSpoListColumnNamesFieldType {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Field
    )

    if (-not [string]::IsNullOrWhiteSpace([string]$Field.TypeAsString)) {
        return [string]$Field.TypeAsString
    }

    if (-not [string]::IsNullOrWhiteSpace([string]$Field.TypeDisplayName)) {
        return [string]$Field.TypeDisplayName
    }

    return [string]$Field.FieldTypeKind
}

function ConvertTo-GetSpoListColumnNamesOutput {
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Field
    )

    [pscustomobject]@{
        InternalName = $Field.InternalName
        DisplayName  = $Field.Title
        Type         = Resolve-GetSpoListColumnNamesFieldType -Field $Field
    }
}

function Test-GetSpoListColumnNamesDisplayField {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Field
    )

    return -not $Field.Hidden -and
        -not $Field.ReadOnlyField -and
        -not $Field.Sealed -and
        (-not $Field.FromBaseType -or $Field.InternalName -eq 'Title')
}

function Resolve-GetSpoListColumnNamesListIdentity {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter()]
        [guid]$ListGuid,

        [Parameter()]
        [string]$ListTitle
    )

    if ($null -ne $ListGuid -and $ListGuid -ne [guid]::Empty) {
        return $ListGuid.ToString()
    }

    return $ListTitle.Trim()
}

function Get-GetSpoListColumnNamesFields {
    [OutputType([object[]])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Connection,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ListIdentity,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteUrl
    )

    try {
        $null = Get-PnPList -Connection $Connection -Identity $ListIdentity -ThrowExceptionIfListNotFound -ErrorAction Stop
        return Get-PnPField -Connection $Connection -List $ListIdentity -Includes 'InternalName', 'Title', 'TypeAsString', 'TypeDisplayName', 'FieldTypeKind', 'Hidden', 'ReadOnlyField', 'Sealed', 'FromBaseType' -ErrorAction Stop
    }
    catch {
        throw "No se pudieron obtener las columnas de la lista '$ListIdentity' en el sitio '$SiteUrl'. $($_.Exception.Message)"
    }
}

function Get-SpoListColumnNames {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
    [OutputType([object[]])]
    [CmdletBinding(DefaultParameterSetName = 'ByGuid')]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^https://')]
        [string]$SiteUrl,

        [Parameter(Mandatory, ParameterSetName = 'ByGuid')]
        [ValidateNotNullOrEmpty()]
        [guid]$ListGuid,

        [Parameter(Mandatory, ParameterSetName = 'ByTitle')]
        [ValidateNotNullOrEmpty()]
        [string]$ListTitle,

        [Parameter()]
        [ValidateSet('Interactive', 'DeviceLogin')]
        [string]$AuthMode = 'Interactive',

        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [string]$TenantId
    )

    $spoExecutionContext = Resolve-GetSpoListColumnNamesExecutionContext -SiteUrl $SiteUrl -TenantId $TenantId -ClientId $ClientId -AuthMode $AuthMode
    if ($PSCmdlet.ParameterSetName -eq 'ByGuid') {
        $listIdentity = Resolve-GetSpoListColumnNamesListIdentity -ListGuid $ListGuid
    }
    else {
        $listIdentity = Resolve-GetSpoListColumnNamesListIdentity -ListTitle $ListTitle
    }
    Write-Verbose "Consultando columnas de la lista '$listIdentity' en '$($spoExecutionContext.SiteUrl)'."
    $fields = Get-GetSpoListColumnNamesFields -Connection $spoExecutionContext.Connection -ListIdentity $listIdentity -SiteUrl $spoExecutionContext.SiteUrl

    $displayColumns = @($fields |
        Where-Object { Test-GetSpoListColumnNamesDisplayField -Field $_ } |
        ForEach-Object { ConvertTo-GetSpoListColumnNamesOutput -Field $_ } |
        Sort-Object -Property DisplayName, InternalName)

    Write-Verbose "Columnas desplegables devueltas: $($displayColumns.Count)."
    $displayColumns
}

Get-SpoListColumnNames @PSBoundParameters
