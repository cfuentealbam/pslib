# ===========================================================================
# Control de Cambios
# v0.1.0 | 2026-06-16 | Dev Agent | Implementacion inicial de Export-SpoListToExcel
# v0.2.0 | 2026-06-18 | Dev Agent | Agrega mensajes auxiliares solo mediante Verbose
# v0.3.0 | 2026-06-19 | Dev Agent | Normaliza errores recuperables de lista vacia al leer items
# ===========================================================================

<#
.SYNOPSIS
Exporta items de una lista SharePoint Online a un archivo Excel .xlsx.

.DESCRIPTION
Autentica contra SharePoint Online mediante el modulo Connect-Spo, o reutiliza
el contexto SharePoint activo de la sesion cuando no se entrega SiteUrl.
Consulta una lista por GUID o por Title, exporta solo campos desplegables y
genera un archivo .xlsx con formatos de fecha, numero y texto multilinea.

.PARAMETER SiteUrl
URL absoluta HTTPS del sitio SharePoint Online. Si se omite, se usa el SiteUrl
del contexto activo creado por Connect-Spo.

.PARAMETER ListGuid
GUID de la lista objetivo dentro del sitio.

.PARAMETER ListTitle
Title de la lista objetivo dentro del sitio, tal como lo despliega
Get-SpoListNames.

.PARAMETER OutputPath
Ruta del archivo .xlsx a generar.

.PARAMETER Force
Permite sobrescribir un archivo existente.

.PARAMETER AuthMode
Modo de autenticacion a solicitar a Connect-Spo. DeviceLogin se adapta a
DeviceCode al invocar Connect-Spo.

.PARAMETER ClientId
ClientId del app registration de Entra ID. Si se omite, se intenta resolver
desde ENTRAID_APP_ID, ENTRAID_CLIENT_ID o AZURE_CLIENT_ID.

.PARAMETER TenantId
Tenant de Entra ID requerido por Connect-Spo. Si se omite, se intenta resolver
desde AZURE_TENANT_ID.

.PARAMETER PageSize
Tamano de pagina usado al consultar items con Get-PnPListItem.

.PARAMETER WorksheetName
Nombre de la hoja Excel de salida.

.OUTPUTS
PSCustomObject. Objeto con OutputPath, ItemCount, FieldCount y WorksheetName.

.EXAMPLE
Export-SpoListToExcel -ListTitle "Incidentes" -OutputPath ".\incidentes.xlsx"

.EXAMPLE
Export-SpoListToExcel -SiteUrl "https://contoso.sharepoint.com/sites/demo" -ListGuid "00000000-0000-0000-0000-000000000000" -TenantId "contoso.onmicrosoft.com" -ClientId "00000000-0000-0000-0000-000000000000" -OutputPath ".\incidentes.xlsx" -Force
#>

[CmdletBinding(DefaultParameterSetName = 'ByTitle')]
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

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [ValidateSet('Interactive', 'DeviceLogin')]
    [string]$AuthMode = 'Interactive',

    [Parameter()]
    [string]$ClientId,

    [Parameter()]
    [string]$TenantId,

    [Parameter()]
    [ValidateRange(1, 5000)]
    [int]$PageSize = 2000,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$WorksheetName = 'Items'
)

function Import-ExportSpoListToExcelAuthenticationModule {
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

function Import-ExportSpoListToExcelExcelModule {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName = 'ImportExcel'
    )

    try {
        Import-Module -Name $ModuleName -ErrorAction Stop
        $command = Get-Command -Name 'Export-Excel' -ErrorAction Stop
        if ($command.Name -ne 'Export-Excel') {
            throw 'Export-Excel command was not resolved.'
        }
    }
    catch {
        throw 'No se puede cargar la dependencia ImportExcel. Instale el modulo ImportExcel en PSModulePath y vuelva a ejecutar la operacion.'
    }
}

function Resolve-ExportSpoListToExcelClientId {
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

function Resolve-ExportSpoListToExcelTenantId {
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

function ConvertTo-ExportSpoListToExcelConnectSpoAuthMode {
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

function Invoke-ExportSpoListToExcelAuthentication {
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

    Import-ExportSpoListToExcelAuthenticationModule
    $connectSpoAuthMode = ConvertTo-ExportSpoListToExcelConnectSpoAuthMode -AuthMode $AuthMode

    try {
        return Connect-Spo -SiteUrl $SiteUrl -TenantId $TenantId -ClientId $ClientId -AuthMode $connectSpoAuthMode -ErrorAction Stop
    }
    catch {
        throw "No se pudo autenticar mediante Connect-Spo para el sitio '$SiteUrl'. $($_.Exception.Message)"
    }
}

function Get-ExportSpoListToExcelActiveContext {
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

function Resolve-ExportSpoListToExcelExecutionContext {
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
        $resolvedClientId = Resolve-ExportSpoListToExcelClientId -ClientId $ClientId
        $resolvedTenantId = Resolve-ExportSpoListToExcelTenantId -TenantId $TenantId
        $connection = Invoke-ExportSpoListToExcelAuthentication -SiteUrl $SiteUrl -TenantId $resolvedTenantId -ClientId $resolvedClientId -AuthMode $AuthMode

        return [pscustomobject]@{
            Connection = $connection
            SiteUrl    = $SiteUrl
        }
    }

    $activeContext = Get-ExportSpoListToExcelActiveContext
    if ($null -eq $activeContext) {
        throw 'No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.'
    }

    return [pscustomobject]@{
        Connection = $activeContext.Connection
        SiteUrl    = $activeContext.SiteUrl
    }
}

function Resolve-ExportSpoListToExcelListIdentity {
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

function Resolve-ExportSpoListToExcelOutputPath {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter()]
        [switch]$Force
    )

    $extension = [System.IO.Path]::GetExtension($OutputPath)
    if ($extension -ne '.xlsx') {
        throw 'OutputPath debe terminar en .xlsx.'
    }

    $fullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
    $directory = [System.IO.Path]::GetDirectoryName($fullPath)
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path -LiteralPath $directory -PathType Container)) {
        throw "El directorio de salida '$directory' no existe."
    }

    if ((Test-Path -LiteralPath $fullPath -PathType Leaf) -and -not $Force) {
        throw "El archivo de salida '$fullPath' ya existe. Use -Force para sobrescribirlo."
    }

    return $fullPath
}

function Test-ExportSpoListToExcelDisplayField {
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

function Resolve-ExportSpoListToExcelFieldType {
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

function Test-ExportSpoListToExcelEmptyListItemReadError {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $message = $ErrorRecord.Exception.Message
    if ([string]::IsNullOrWhiteSpace($message)) {
        return $false
    }

    $normalizedMessage = $message.Normalize([Text.NormalizationForm]::FormD).ToLowerInvariant()
    $normalizedMessage = -join ($normalizedMessage.ToCharArray() | Where-Object { [Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [Globalization.UnicodeCategory]::NonSpacingMark })
    $emptyListPatterns = @(
        'lista vacia',
        'no contiene items',
        'no contiene elementos',
        'no tiene items',
        'no tiene filas',
        'sin items',
        'sin filas',
        'no items',
        'no rows',
        'does not contain items',
        'does not contain rows',
        'empty list',
        'empty result',
        '0 items',
        '0 rows'
    )

    foreach ($pattern in $emptyListPatterns) {
        if ($normalizedMessage.Contains($pattern)) {
            return $true
        }
    }

    return $false
}

function Get-ExportSpoListToExcelFieldDefinition {
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
        $fields = Get-PnPField -Connection $Connection -List $ListIdentity -Includes 'InternalName', 'Title', 'TypeAsString', 'TypeDisplayName', 'FieldTypeKind', 'Hidden', 'ReadOnlyField', 'Sealed', 'FromBaseType' -ErrorAction Stop
        return @($fields |
            Where-Object { Test-ExportSpoListToExcelDisplayField -Field $_ } |
            Sort-Object -Property Title, InternalName)
    }
    catch {
        throw "No se pudieron obtener los campos exportables de la lista '$ListIdentity' en el sitio '$SiteUrl'. $($_.Exception.Message)"
    }
}

function Get-ExportSpoListToExcelListItem {
    [OutputType([object[]])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Connection,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ListIdentity,

        [Parameter(Mandatory)]
        [object[]]$Fields,

        [Parameter(Mandatory)]
        [ValidateRange(1, 5000)]
        [int]$PageSize,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteUrl
    )

    try {
        $fieldInternalNames = @($Fields | ForEach-Object { $_.InternalName })
        return @(Get-PnPListItem -Connection $Connection -List $ListIdentity -Fields $fieldInternalNames -PageSize $PageSize -ErrorAction Stop)
    }
    catch {
        if (Test-ExportSpoListToExcelEmptyListItemReadError -ErrorRecord $_) {
            Write-Verbose "La lectura de items reporto una lista vacia; se continuara exportando solo encabezados."
            return @()
        }

        throw "No se pudieron obtener los items de la lista '$ListIdentity' en el sitio '$SiteUrl'. $($_.Exception.Message)"
    }
}

function Test-ExportSpoListToExcelDateField {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Field
    )

    $fieldType = Resolve-ExportSpoListToExcelFieldType -Field $Field
    return $fieldType -in @('DateTime', 'DateOnly')
}

function Test-ExportSpoListToExcelNumberField {
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Field
    )

    $fieldType = Resolve-ExportSpoListToExcelFieldType -Field $Field
    return $fieldType -in @('Number', 'Currency', 'Integer', 'Counter')
}

function ConvertTo-ExportSpoListToExcelScalarText {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return $null
    }

    foreach ($propertyName in @('LookupValue', 'Email', 'Title', 'Label')) {
        if ($Value.PSObject.Properties[$propertyName] -and -not [string]::IsNullOrWhiteSpace([string]$Value.$propertyName)) {
            return [string]$Value.$propertyName
        }
    }

    return [string]$Value
}

function ConvertTo-ExportSpoListToExcelCellValue {
    [OutputType([object], [datetime], [decimal], [bool], [string])]
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory)]
        [object]$Field
    )

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [datetime]) {
        return $Value
    }

    if (Test-ExportSpoListToExcelDateField -Field $Field) {
        $parsedDate = [datetime]::MinValue
        if ([datetime]::TryParse([string]$Value, [ref]$parsedDate)) {
            return $parsedDate
        }
    }

    if ($Value -is [byte] -or $Value -is [int16] -or $Value -is [int32] -or $Value -is [int64] -or $Value -is [single] -or $Value -is [double] -or $Value -is [decimal]) {
        return $Value
    }

    if (Test-ExportSpoListToExcelNumberField -Field $Field) {
        $parsedNumber = [decimal]::Zero
        if ([decimal]::TryParse([string]$Value, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsedNumber)) {
            return $parsedNumber
        }
        if ([decimal]::TryParse([string]$Value, [ref]$parsedNumber)) {
            return $parsedNumber
        }
    }

    if ($Value -is [bool]) {
        return $Value
    }

    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        $parts = @($Value | ForEach-Object { ConvertTo-ExportSpoListToExcelScalarText -Value $_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        return ($parts -join '; ')
    }

    $textValue = ConvertTo-ExportSpoListToExcelScalarText -Value $Value
    if ($null -eq $textValue) {
        return $null
    }

    return ($textValue -replace "`r`n|`r|`n", "`n")
}

function Get-ExportSpoListToExcelHeaderMap {
    [OutputType([object[]])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Fields
    )

    $seenHeaders = @{}
    $headers = foreach ($field in $Fields) {
        $baseHeader = [string]$field.Title
        if ([string]::IsNullOrWhiteSpace($baseHeader)) {
            $baseHeader = [string]$field.InternalName
        }

        if ($seenHeaders.ContainsKey($baseHeader)) {
            $seenHeaders[$baseHeader] += 1
            $header = "$baseHeader ($($field.InternalName))"
        }
        else {
            $seenHeaders[$baseHeader] = 1
            $header = $baseHeader
        }

        [pscustomobject]@{
            Field  = $field
            Header = $header
        }
    }

    return @($headers)
}

function ConvertTo-ExportSpoListToExcelRow {
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Item,

        [Parameter(Mandatory)]
        [object[]]$HeaderMap
    )

    $row = [ordered]@{}
    foreach ($entry in $HeaderMap) {
        $field = $entry.Field
        $value = $null
        if ($Item.PSObject.Properties['FieldValues'] -and $null -ne $Item.FieldValues) {
            $value = $Item.FieldValues[$field.InternalName]
        }
        $row[$entry.Header] = ConvertTo-ExportSpoListToExcelCellValue -Value $value -Field $field
    }

    return [pscustomobject]$row
}

function ConvertTo-ExportSpoListToExcelRowCollection {
    [OutputType([object[]])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Items,

        [Parameter(Mandatory)]
        [object[]]$HeaderMap
    )

    return @($Items | ForEach-Object { ConvertTo-ExportSpoListToExcelRow -Item $_ -HeaderMap $HeaderMap })
}

function Export-ExportSpoListToExcelWorkbook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Rows,

        [Parameter(Mandatory)]
        [object[]]$HeaderMap,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$WorksheetName,

        [Parameter()]
        [switch]$Force
    )

    Import-ExportSpoListToExcelExcelModule

    if ((Test-Path -LiteralPath $OutputPath -PathType Leaf) -and $Force) {
        Remove-Item -LiteralPath $OutputPath -Force
    }

    $exportRows = $Rows
    $deletePlaceholderRow = $false
    if ($Rows.Count -eq 0) {
        $emptyRow = [ordered]@{}
        foreach ($entry in $HeaderMap) {
            $emptyRow[$entry.Header] = $null
        }
        $exportRows = @([pscustomobject]$emptyRow)
        $deletePlaceholderRow = $true
    }

    $package = $exportRows |
        Export-Excel -Path $OutputPath -WorksheetName $WorksheetName -TableName 'SpoListItems' -AutoSize -FreezeTopRow -BoldTopRow -ClearSheet -PassThru

    try {
        $worksheet = $package.Workbook.Worksheets[$WorksheetName]
        if ($deletePlaceholderRow -and $worksheet -and $worksheet.Dimension.End.Row -ge 2) {
            $worksheet.DeleteRow(2)
        }

        for ($index = 0; $index -lt $HeaderMap.Count; $index += 1) {
            $field = $HeaderMap[$index].Field
            $column = $worksheet.Column($index + 1)
            if (Test-ExportSpoListToExcelDateField -Field $field) {
                $column.Style.Numberformat.Format = 'dd-mm-yyyy'
            }
            elseif (Test-ExportSpoListToExcelNumberField -Field $field) {
                $column.Style.Numberformat.Format = '0.################'
            }
            else {
                $column.Style.WrapText = $true
            }
        }

        $package.Save()
    }
    finally {
        if ($package -and $package.PSObject.Methods['Dispose']) {
            $package.Dispose()
        }
    }
}

function Get-ExportSpoListToExcelResult {
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter(Mandatory)]
        [int]$ItemCount,

        [Parameter(Mandatory)]
        [int]$FieldCount,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$WorksheetName
    )

    [pscustomobject]@{
        OutputPath    = $OutputPath
        ItemCount     = $ItemCount
        FieldCount    = $FieldCount
        WorksheetName = $WorksheetName
    }
}

function Export-SpoListToExcel {
    [CmdletBinding(DefaultParameterSetName = 'ByTitle')]
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

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [ValidateSet('Interactive', 'DeviceLogin')]
        [string]$AuthMode = 'Interactive',

        [Parameter()]
        [string]$ClientId,

        [Parameter()]
        [string]$TenantId,

        [Parameter()]
        [ValidateRange(1, 5000)]
        [int]$PageSize = 2000,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$WorksheetName = 'Items'
    )

    $resolvedOutputPath = Resolve-ExportSpoListToExcelOutputPath -OutputPath $OutputPath -Force:$Force
    Write-Verbose "Ruta de salida Excel resuelta: '$resolvedOutputPath'."
    Import-ExportSpoListToExcelExcelModule
    $spoExecutionContext = Resolve-ExportSpoListToExcelExecutionContext -SiteUrl $SiteUrl -TenantId $TenantId -ClientId $ClientId -AuthMode $AuthMode

    if ($PSCmdlet.ParameterSetName -eq 'ByGuid') {
        $listIdentity = Resolve-ExportSpoListToExcelListIdentity -ListGuid $ListGuid
    }
    else {
        $listIdentity = Resolve-ExportSpoListToExcelListIdentity -ListTitle $ListTitle
    }
    Write-Verbose "Exportando lista '$listIdentity' desde '$($spoExecutionContext.SiteUrl)'."

    $fields = Get-ExportSpoListToExcelFieldDefinition -Connection $spoExecutionContext.Connection -ListIdentity $listIdentity -SiteUrl $spoExecutionContext.SiteUrl
    Write-Verbose "Campos exportables obtenidos: $($fields.Count)."
    $items = @(Get-ExportSpoListToExcelListItem -Connection $spoExecutionContext.Connection -ListIdentity $listIdentity -Fields $fields -PageSize $PageSize -SiteUrl $spoExecutionContext.SiteUrl)
    Write-Verbose "Items obtenidos: $($items.Count)."
    $headerMap = Get-ExportSpoListToExcelHeaderMap -Fields $fields
    $rows = @(ConvertTo-ExportSpoListToExcelRowCollection -Items $items -HeaderMap $headerMap)

    Write-Verbose "Escribiendo workbook Excel '$resolvedOutputPath'."
    Export-ExportSpoListToExcelWorkbook -Rows $rows -HeaderMap $headerMap -OutputPath $resolvedOutputPath -WorksheetName $WorksheetName -Force:$Force

    Get-ExportSpoListToExcelResult -OutputPath $resolvedOutputPath -ItemCount $items.Count -FieldCount $fields.Count -WorksheetName $WorksheetName
}

Export-SpoListToExcel @PSBoundParameters




