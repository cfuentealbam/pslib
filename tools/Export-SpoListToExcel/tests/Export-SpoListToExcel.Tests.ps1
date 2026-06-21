# ===========================================================================
# Control de Cambios
# v0.1.0 | 2026-06-16 | Dev Agent | Pruebas iniciales de Export-SpoListToExcel
# v0.2.0 | 2026-06-19 | Dev Agent | Cubre lectura vacia de items y error recuperable de lista vacia
# ===========================================================================

Describe 'Export-SpoListToExcel.ps1' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..\src\Export-SpoListToExcel.ps1'
        $script:TargetGuid = [guid]'c8f7f928-3cbd-46bd-8174-4f66985491ec'
        $script:TargetTitle = 'Incidentes'
        $script:OutputPath = Join-Path ([System.IO.Path]::GetTempPath()) 'Export-SpoListToExcel.Tests.xlsx'
        $originalEntraAppId = $env:ENTRAID_APP_ID
        $originalEntraClientId = $env:ENTRAID_CLIENT_ID
        $originalAzureClientId = $env:AZURE_CLIENT_ID
        $originalAzureTenantId = $env:AZURE_TENANT_ID
        $originalSpoConnectionContext = Get-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue

        function New-TestField {
            param(
                [Parameter(Mandatory)]
                [string]$InternalName,

                [Parameter(Mandatory)]
                [string]$Title,

                [Parameter()]
                [string]$TypeAsString,

                [Parameter()]
                [string]$TypeDisplayName,

                [Parameter()]
                [string]$FieldTypeKind,

                [Parameter()]
                [bool]$Hidden = $false,

                [Parameter()]
                [bool]$ReadOnlyField = $false,

                [Parameter()]
                [bool]$Sealed = $false,

                [Parameter()]
                [bool]$FromBaseType = $false
            )

            [pscustomobject]@{
                InternalName    = $InternalName
                Title           = $Title
                TypeAsString    = $TypeAsString
                TypeDisplayName = $TypeDisplayName
                FieldTypeKind   = $FieldTypeKind
                Hidden          = $Hidden
                ReadOnlyField   = $ReadOnlyField
                Sealed          = $Sealed
                FromBaseType    = $FromBaseType
            }
        }

        function New-TestItem {
            param(
                [Parameter(Mandatory)]
                [hashtable]$FieldValues
            )

            [pscustomobject]@{
                FieldValues = $FieldValues
            }
        }

        function New-FakeExcelPackage {
            param(
                [Parameter(Mandatory)]
                [string]$WorksheetName
            )

            $script:CapturedExcelColumns = @{}
            $worksheet = [pscustomobject]@{
                Dimension = [pscustomobject]@{
                    End = [pscustomobject]@{
                        Row = 2
                    }
                }
            }
            $worksheet | Add-Member -MemberType ScriptMethod -Name Column -Value {
                param($Index)
                if (-not $script:CapturedExcelColumns.ContainsKey($Index)) {
                    $script:CapturedExcelColumns[$Index] = [pscustomobject]@{
                        Style = [pscustomobject]@{
                            Numberformat = [pscustomobject]@{
                                Format = $null
                            }
                            WrapText = $false
                        }
                    }
                }

                return $script:CapturedExcelColumns[$Index]
            }
            $worksheet | Add-Member -MemberType ScriptMethod -Name DeleteRow -Value {
                param($Row)
                $script:DeletedExcelRows += @($Row)
            }

            $package = [pscustomobject]@{
                Workbook = [pscustomobject]@{
                    Worksheets = @{
                        $WorksheetName = $worksheet
                    }
                }
            }
            $package | Add-Member -MemberType ScriptMethod -Name Save -Value { $script:ExcelPackageSaved = $true }
            $package | Add-Member -MemberType ScriptMethod -Name Dispose -Value { $script:ExcelPackageDisposed = $true }

            return $package
        }

        function Set-ConnectSpoStub {
            param(
                [Parameter()]
                [switch]$Throw
            )

            function global:Connect-Spo {
                [CmdletBinding()]
                param(
                    [Parameter()]
                    [string]$SiteUrl,

                    [Parameter()]
                    [string]$TenantId,

                    [Parameter()]
                    [string]$ClientId,

                    [Parameter()]
                    [string]$AuthMode
                )

                $script:ConnectSpoCallCount += 1
                $script:CapturedConnectSpoParams = @{
                    SiteUrl  = $SiteUrl
                    TenantId = $TenantId
                    ClientId = $ClientId
                    AuthMode = $AuthMode
                }

                if ($script:ConnectSpoShouldThrow) {
                    throw 'autenticacion rechazada'
                }

                [pscustomobject]@{ Connected = $true; SiteUrl = $SiteUrl }
            }

            $script:ConnectSpoShouldThrow = [bool]$Throw
        }

        function Set-ExportExcelStub {
            function global:Export-Excel {
                [CmdletBinding()]
                param(
                    [Parameter(ValueFromPipeline)]
                    [object]$InputObject,

                    [Parameter()]
                    [string]$Path,

                    [Parameter()]
                    [string]$WorksheetName,

                    [Parameter()]
                    [string]$TableName,

                    [Parameter()]
                    [switch]$AutoSize,

                    [Parameter()]
                    [switch]$FreezeTopRow,

                    [Parameter()]
                    [switch]$BoldTopRow,

                    [Parameter()]
                    [switch]$ClearSheet,

                    [Parameter()]
                    [switch]$PassThru
                )

                begin {
                    $script:ExportExcelInput = @()
                    $script:CapturedExportExcelParams = @{
                        Path         = $Path
                        WorksheetName = $WorksheetName
                        TableName    = $TableName
                        AutoSize     = $AutoSize
                        FreezeTopRow = $FreezeTopRow
                        BoldTopRow   = $BoldTopRow
                        ClearSheet   = $ClearSheet
                        PassThru     = $PassThru
                    }
                }
                process {
                    $script:ExportExcelInput += $InputObject
                }
                end {
                    return New-FakeExcelPackage -WorksheetName $WorksheetName
                }
            }
        }
    }

    BeforeEach {
        $env:ENTRAID_APP_ID = $null
        $env:ENTRAID_CLIENT_ID = $null
        $env:AZURE_CLIENT_ID = $null
        $env:AZURE_TENANT_ID = $null
        $script:CapturedConnectSpoParams = $null
        $script:ConnectSpoCallCount = 0
        $script:GetPnPListCallCount = 0
        $script:GetPnPFieldCallCount = 0
        $script:GetPnPListItemCallCount = 0
        $script:ImportedModules = @()
        $script:CapturedPnPListParams = $null
        $script:CapturedPnPFieldParams = $null
        $script:CapturedPnPListItemParams = $null
        $script:GetPnPListShouldThrow = $false
        $script:GetPnPFieldShouldThrow = $false
        $script:GetPnPListItemShouldThrow = $false
        $script:GetPnPListItemErrorMessage = 'item read denied'
        $script:ImportExcelShouldThrow = $false
        $script:ConnectSpoShouldThrow = $false
        $script:ExportExcelInput = @()
        $script:CapturedExportExcelParams = $null
        $script:CapturedExcelColumns = @{}
        $script:DeletedExcelRows = @()
        $script:ExcelPackageSaved = $false
        $script:ExcelPackageDisposed = $false
        $script:MockFields = @(
            (New-TestField -InternalName 'Title' -Title 'Titulo' -TypeAsString 'Text' -FieldTypeKind 'Text' -FromBaseType $true),
            (New-TestField -InternalName 'EventDate' -Title 'Fecha' -TypeAsString 'DateTime' -FieldTypeKind 'DateTime'),
            (New-TestField -InternalName 'Amount' -Title 'Monto' -TypeAsString 'Number' -FieldTypeKind 'Number'),
            (New-TestField -InternalName 'Notes' -Title 'Notas' -TypeAsString 'Note' -FieldTypeKind 'Note'),
            (New-TestField -InternalName 'Created' -Title 'Creado' -TypeAsString 'DateTime' -FieldTypeKind 'DateTime' -ReadOnlyField $true -FromBaseType $true),
            (New-TestField -InternalName '_UIVersionString' -Title 'Version' -TypeAsString 'Text' -FieldTypeKind 'Text' -Hidden $true),
            (New-TestField -InternalName 'Attachments' -Title 'Datos adjuntos' -TypeAsString 'Attachments' -FieldTypeKind 'Attachments' -FromBaseType $true)
        )
        $script:MockItems = @(
            (New-TestItem -FieldValues @{
                Title     = 'Caso A'
                EventDate = [datetime]'2026-06-16'
                Amount    = 1234.5
                Notes     = "Linea 1`r`nLinea 2"
                Created   = [datetime]'2026-06-15'
            }),
            (New-TestItem -FieldValues @{
                Title     = 'Caso B'
                EventDate = '2026-06-17'
                Amount    = '45.67'
                Notes     = @('uno', 'dos')
            })
        )

        Remove-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Connect-Spo -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Get-PnPList -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Get-PnPField -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Get-PnPListItem -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Export-Excel -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:OutputPath -Force -ErrorAction SilentlyContinue
        Set-ConnectSpoStub
        Set-ExportExcelStub

        Mock Import-Module {
            param($Name)
            $script:ImportedModules += @($Name)
            if ($Name -eq 'ImportExcel' -and $script:ImportExcelShouldThrow) {
                throw 'module missing'
            }
        }

        function global:Get-PnPList {
            [CmdletBinding()]
            param($Connection, $Identity, [switch]$ThrowExceptionIfListNotFound)

            $script:GetPnPListCallCount += 1
            $script:CapturedPnPListParams = @{
                Connection                   = $Connection
                Identity                     = $Identity
                ThrowExceptionIfListNotFound = $ThrowExceptionIfListNotFound
            }

            if ($script:GetPnPListShouldThrow) {
                throw 'list not found'
            }

            [pscustomobject]@{ Id = $Identity }
        }

        function global:Get-PnPField {
            [CmdletBinding()]
            param($Connection, $List, $Includes)

            $script:GetPnPFieldCallCount += 1
            $script:CapturedPnPFieldParams = @{
                Connection = $Connection
                List       = $List
                Includes   = $Includes
            }

            if ($script:GetPnPFieldShouldThrow) {
                throw 'field read denied'
            }

            $script:MockFields
        }

        function global:Get-PnPListItem {
            [CmdletBinding()]
            param($Connection, $List, $Fields, $PageSize)

            $script:GetPnPListItemCallCount += 1
            $script:CapturedPnPListItemParams = @{
                Connection = $Connection
                List       = $List
                Fields     = $Fields
                PageSize   = $PageSize
            }

            if ($script:GetPnPListItemShouldThrow) {
                throw $script:GetPnPListItemErrorMessage
            }

            $script:MockItems
        }
    }

    AfterAll {
        $env:ENTRAID_APP_ID = $originalEntraAppId
        $env:ENTRAID_CLIENT_ID = $originalEntraClientId
        $env:AZURE_CLIENT_ID = $originalAzureClientId
        $env:AZURE_TENANT_ID = $originalAzureTenantId
        if ($null -ne $originalSpoConnectionContext) {
            Set-Variable -Name PSLibSpoConnectionContext -Scope Global -Value $originalSpoConnectionContext.Value
        }
        else {
            Remove-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue
        }
        Remove-Item -Path function:global:Connect-Spo -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Get-PnPList -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Get-PnPField -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Get-PnPListItem -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Export-Excel -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $script:OutputPath -Force -ErrorAction SilentlyContinue
    }

    It 'exporta por ListTitle usando contexto activo sin llamar Connect-Spo' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true; SiteUrl = 'https://contoso.sharepoint.com/sites/demo' }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }

        $result = . $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath

        $script:ConnectSpoCallCount | Should Be 0
        $script:GetPnPListCallCount | Should Be 1
        $script:GetPnPFieldCallCount | Should Be 1
        $script:GetPnPListItemCallCount | Should Be 1
        $script:CapturedPnPListParams.Identity | Should Be $script:TargetTitle
        $script:CapturedPnPFieldParams.List | Should Be $script:TargetTitle
        $script:CapturedPnPListItemParams.List | Should Be $script:TargetTitle
        $script:CapturedPnPListItemParams.Fields.Count | Should Be 4
        ($script:CapturedPnPListItemParams.Fields -contains 'Title') | Should Be $true
        ($script:CapturedPnPListItemParams.Fields -contains 'Created') | Should Be $false
        $script:CapturedExportExcelParams.Path | Should Be $script:OutputPath
        $script:CapturedExportExcelParams.WorksheetName | Should Be 'Items'
        $script:ExcelPackageSaved | Should Be $true
        $script:ExcelPackageDisposed | Should Be $true
        $result.ItemCount | Should Be 2
        $result.FieldCount | Should Be 4
    }

    It 'funciona quiet por defecto y muestra mensajes auxiliares solo con Verbose' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true; SiteUrl = 'https://contoso.sharepoint.com/sites/demo' }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }

        $quietOutput = @(. $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath 4>&1)
        $quietVerboseRecords = @($quietOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] })

        $quietVerboseRecords.Count | Should Be 0
        @($quietOutput | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] }).Count | Should Be 1

        $verboseOutput = @(. $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath -Force -Verbose 4>&1)
        $verboseRecords = @($verboseOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] })

        ($verboseRecords.Count -gt 0) | Should Be $true
        (($verboseRecords | ForEach-Object { $_.Message }) -join ' ') | Should BeLike '*Escribiendo workbook Excel*'
    }

    It 'exporta por ListGuid usando contexto activo' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }

        $null = . $scriptPath -ListGuid $script:TargetGuid -OutputPath $script:OutputPath

        $script:CapturedPnPListParams.Identity | Should Be $script:TargetGuid.ToString()
        $script:CapturedPnPListItemParams.List | Should Be $script:TargetGuid.ToString()
    }

    It 'usa parametros explicitos y autentica mediante Connect-Spo' {
        $result = . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ListTitle $script:TargetTitle -OutputPath $script:OutputPath -TenantId 'tenant-id' -ClientId 'client-id'

        $result.ItemCount | Should Be 2
        ($script:ImportedModules -contains 'Connect-Spo') | Should Be $true
        $script:ConnectSpoCallCount | Should Be 1
        $script:CapturedConnectSpoParams.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/demo'
        $script:CapturedConnectSpoParams.TenantId | Should Be 'tenant-id'
        $script:CapturedConnectSpoParams.ClientId | Should Be 'client-id'
        $script:CapturedConnectSpoParams.AuthMode | Should Be 'Interactive'
    }

    It 'mapea DeviceLogin a DeviceCode y resuelve variables de entorno' {
        $env:ENTRAID_APP_ID = 'env-client-id'
        $env:AZURE_TENANT_ID = 'env-tenant-id'

        $null = . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ListGuid $script:TargetGuid -OutputPath $script:OutputPath -AuthMode DeviceLogin

        $script:CapturedConnectSpoParams.ClientId | Should Be 'env-client-id'
        $script:CapturedConnectSpoParams.TenantId | Should Be 'env-tenant-id'
        $script:CapturedConnectSpoParams.AuthMode | Should Be 'DeviceCode'
    }

    It 'falla sin contexto activo ni SiteUrl antes de llamar PnP' {
        try {
            . $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath
            throw 'Expected script to throw when active context is missing.'
        }
        catch {
            $_.Exception.Message | Should Be 'No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.'
        }

        $script:GetPnPListCallCount | Should Be 0
        $script:GetPnPFieldCallCount | Should Be 0
        $script:GetPnPListItemCallCount | Should Be 0
    }

    It 'falla con contexto activo invalido' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = $null
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }

        try {
            . $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath
            throw 'Expected script to throw when active context is invalid.'
        }
        catch {
            $_.Exception.Message | Should Be 'No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.'
        }
    }

    It 'falla claro si no puede cargar Connect-Spo' {
        Remove-Item -Path function:global:Connect-Spo -ErrorAction SilentlyContinue
        Mock Import-Module {
            param($Name)
            if ($Name -eq 'Connect-Spo') {
                throw 'module missing'
            }
        }

        try {
            . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ListTitle $script:TargetTitle -OutputPath $script:OutputPath -TenantId 'tenant-id' -ClientId 'client-id'
            throw 'Expected script to throw when Connect-Spo is unavailable.'
        }
        catch {
            $_.Exception.Message | Should Be 'No se puede cargar la dependencia Connect-Spo. Instale o exponga el modulo Connect-Spo en PSModulePath y vuelva a ejecutar la operacion.'
        }
    }

    It 'falla claro si no puede cargar ImportExcel' {
        $script:ImportExcelShouldThrow = $true

        try {
            . $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath
            throw 'Expected script to throw when ImportExcel is unavailable.'
        }
        catch {
            $_.Exception.Message | Should Be 'No se puede cargar la dependencia ImportExcel. Instale el modulo ImportExcel en PSModulePath y vuelva a ejecutar la operacion.'
        }

        $script:GetPnPListCallCount | Should Be 0
    }

    It 'rechaza OutputPath sin extension xlsx' {
        try {
            . $scriptPath -ListTitle $script:TargetTitle -OutputPath (Join-Path ([System.IO.Path]::GetTempPath()) 'demo.csv')
            throw 'Expected script to reject non-xlsx output path.'
        }
        catch {
            $_.Exception.Message | Should Be 'OutputPath debe terminar en .xlsx.'
        }
    }

    It 'rechaza archivo existente sin Force y permite con Force' {
        New-Item -ItemType File -Path $script:OutputPath -Force | Out-Null

        try {
            . $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath
            throw 'Expected script to reject existing output path.'
        }
        catch {
            $_.Exception.Message | Should BeLike '*ya existe*Use -Force*'
        }

        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }

        $result = . $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath -Force

        $result.OutputPath | Should Be $script:OutputPath
        $script:GetPnPListCallCount | Should Be 1
    }

    It 'descarta campos internos y conserva Title' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }

        $null = . $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath

        ($script:CapturedPnPFieldParams.Includes -contains 'Hidden') | Should Be $true
        ($script:CapturedPnPFieldParams.Includes -contains 'ReadOnlyField') | Should Be $true
        ($script:CapturedPnPFieldParams.Includes -contains 'Sealed') | Should Be $true
        ($script:CapturedPnPFieldParams.Includes -contains 'FromBaseType') | Should Be $true
        ($script:CapturedPnPListItemParams.Fields -contains 'Title') | Should Be $true
        ($script:CapturedPnPListItemParams.Fields -contains 'Created') | Should Be $false
        ($script:CapturedPnPListItemParams.Fields -contains '_UIVersionString') | Should Be $false
        ($script:CapturedPnPListItemParams.Fields -contains 'Attachments') | Should Be $false
    }

    It 'crea workbook solo con encabezados cuando la lista no tiene items' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }
        $script:MockItems = @()

        $result = . $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath

        $result.ItemCount | Should Be 0
        $result.FieldCount | Should Be 4
        $script:ExportExcelInput.Count | Should Be 1
        $script:ExportExcelInput[0].Titulo | Should Be $null
        $script:ExportExcelInput[0].Fecha | Should Be $null
        $script:DeletedExcelRows | Should Be 2
        $script:ExcelPackageSaved | Should Be $true
    }

    It 'trata error recuperable de lista vacia como cero items' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }
        $script:GetPnPListItemShouldThrow = $true
        $script:GetPnPListItemErrorMessage = 'La lista vacia no contiene items.'

        $result = . $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath

        $result.ItemCount | Should Be 0
        $result.FieldCount | Should Be 4
        $script:ExportExcelInput.Count | Should Be 1
        $script:DeletedExcelRows | Should Be 2
        $script:ExcelPackageSaved | Should Be $true
    }
    It 'proyecta filas con valores tipados y conserva texto multilinea' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }

        $null = . $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath

        $script:ExportExcelInput.Count | Should Be 2
        $script:ExportExcelInput[0].Titulo | Should Be 'Caso A'
        $script:ExportExcelInput[0].Fecha.GetType().FullName | Should Be 'System.DateTime'
        ($script:ExportExcelInput[0].Monto -is [double] -or $script:ExportExcelInput[0].Monto -is [decimal]) | Should Be $true
        $script:ExportExcelInput[0].Notas | Should Be "Linea 1`nLinea 2"
        $script:ExportExcelInput[1].Notas | Should Be 'uno; dos'
    }

    It 'aplica formatos de fecha numero y wrap text' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }

        $null = . $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath

        $script:CapturedExcelColumns[1].Style.Numberformat.Format | Should Be 'dd-mm-yyyy'
        $script:CapturedExcelColumns[2].Style.Numberformat.Format | Should Be '0.################'
        $script:CapturedExcelColumns[3].Style.WrapText | Should Be $true
        $script:CapturedExcelColumns[4].Style.WrapText | Should Be $true
    }

    It 'evita colisiones de encabezados duplicados' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }
        $script:MockFields = @(
            (New-TestField -InternalName 'FirstName' -Title 'Nombre' -TypeAsString 'Text' -FieldTypeKind 'Text'),
            (New-TestField -InternalName 'SecondName' -Title 'Nombre' -TypeAsString 'Text' -FieldTypeKind 'Text')
        )
        $script:MockItems = @(
            (New-TestItem -FieldValues @{
                FirstName  = 'Uno'
                SecondName = 'Dos'
            })
        )

        $null = . $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath

        $properties = @($script:ExportExcelInput[0].PSObject.Properties.Name)
        ($properties -contains 'Nombre') | Should Be $true
        ($properties -contains 'Nombre (SecondName)') | Should Be $true
    }

    It 'falla claro cuando no puede obtener campos o items' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }
        $script:GetPnPFieldShouldThrow = $true

        try {
            . $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath
            throw 'Expected script to throw when fields cannot be read.'
        }
        catch {
            $_.Exception.Message | Should BeLike '*No se pudieron obtener los campos exportables*'
            $_.Exception.Message | Should BeLike '*field read denied*'
        }

        $script:GetPnPFieldShouldThrow = $false
        $script:GetPnPListItemShouldThrow = $true

        try {
            . $scriptPath -ListTitle $script:TargetTitle -OutputPath $script:OutputPath
            throw 'Expected script to throw when items cannot be read.'
        }
        catch {
            $_.Exception.Message | Should BeLike '*No se pudieron obtener los items*'
            $_.Exception.Message | Should BeLike '*item read denied*'
        }
    }

    It 'no llama Connect-PnPOnline directamente' {
        $source = Get-Content -Raw $scriptPath

        $source.Contains('Connect-PnPOnline') | Should Be $false
    }
}



