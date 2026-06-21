# ===========================================================================
# Control de Cambios
# v0.1.0 | 2026-06-15 | Dev Agent | Pruebas iniciales de Get-SpoListColumnNames
# v0.2.0 | 2026-06-16 | Dev Agent | Agrega cobertura para consulta por ListTitle
# v0.3.0 | 2026-06-16 | Dev Agent | Cubre descarte de campos internos de SharePoint
# ===========================================================================

Describe 'Get-SpoListColumnNames.ps1' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..\src\Get-SpoListColumnNames.ps1'
        $script:TargetGuid = [guid]'c8f7f928-3cbd-46bd-8174-4f66985491ec'
        $script:TargetTitle = 'Incidentes'
        $originalEntraAppId = $env:ENTRAID_APP_ID
        $originalEntraClientId = $env:ENTRAID_CLIENT_ID
        $originalAzureClientId = $env:AZURE_CLIENT_ID
        $originalAzureTenantId = $env:AZURE_TENANT_ID
        $originalSpoConnectionContext = Get-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue

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
        $script:ImportedModuleName = $null
        $script:CapturedPnPListParams = $null
        $script:CapturedPnPFieldParams = $null
        $script:GetPnPListShouldThrow = $false
        $script:GetPnPFieldShouldThrow = $false
        $script:MockFields = @(
            (New-TestField -InternalName 'Title' -Title 'Titulo' -TypeAsString 'Text' -FieldTypeKind 'Text' -FromBaseType $true),
            (New-TestField -InternalName 'Created' -Title 'Creado' -TypeAsString 'DateTime' -FieldTypeKind 'DateTime' -ReadOnlyField $true -FromBaseType $true),
            (New-TestField -InternalName 'CustomChoice' -Title 'Opcion' -TypeAsString '' -TypeDisplayName 'Choice' -FieldTypeKind 'Choice'),
            (New-TestField -InternalName '_UIVersionString' -Title 'Version' -TypeAsString 'Text' -FieldTypeKind 'Text' -Hidden $true),
            (New-TestField -InternalName 'GUID' -Title 'GUID' -TypeAsString 'Guid' -FieldTypeKind 'Guid' -Sealed $true),
            (New-TestField -InternalName 'Attachments' -Title 'Datos adjuntos' -TypeAsString 'Attachments' -FieldTypeKind 'Attachments' -FromBaseType $true)
        )
        Remove-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Connect-Spo -ErrorAction SilentlyContinue
        Set-ConnectSpoStub

        Mock Import-Module {
            param($Name)
            $script:ImportedModuleName = $Name
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
    }

    It 'lista columnas usando contexto activo sin llamar Connect-Spo' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true; SiteUrl = 'https://contoso.sharepoint.com/sites/demo' }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
            TenantId   = 'tenant-context'
            ClientId   = 'client-context'
            AuthMode   = 'DeviceCode'
        }

        $result = @(. $scriptPath -ListGuid $script:TargetGuid)

        $script:ConnectSpoCallCount | Should Be 0
        $script:GetPnPListCallCount | Should Be 1
        $script:GetPnPFieldCallCount | Should Be 1
        $script:CapturedPnPListParams.Identity | Should Be $script:TargetGuid.ToString()
        $script:CapturedPnPListParams.ThrowExceptionIfListNotFound | Should Be $true
        $script:CapturedPnPFieldParams.List | Should Be $script:TargetGuid.ToString()
        $script:CapturedPnPFieldParams.Includes -contains 'InternalName' | Should Be $true
        $script:CapturedPnPFieldParams.Includes -contains 'Title' | Should Be $true
        $script:CapturedPnPFieldParams.Includes -contains 'Hidden' | Should Be $true
        $script:CapturedPnPFieldParams.Includes -contains 'ReadOnlyField' | Should Be $true
        $script:CapturedPnPFieldParams.Includes -contains 'Sealed' | Should Be $true
        $script:CapturedPnPFieldParams.Includes -contains 'FromBaseType' | Should Be $true

        $result.Count | Should Be 2
        $result[0].InternalName | Should Be 'CustomChoice'
        $result[0].DisplayName | Should Be 'Opcion'
        $result[0].Type | Should Be 'Choice'
        $result[1].InternalName | Should Be 'Title'
        $result[1].DisplayName | Should Be 'Titulo'
        $result[1].Type | Should Be 'Text'
    }

    It 'funciona quiet por defecto y muestra mensajes auxiliares solo con Verbose' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true; SiteUrl = 'https://contoso.sharepoint.com/sites/demo' }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
            TenantId   = 'tenant-context'
            ClientId   = 'client-context'
            AuthMode   = 'DeviceCode'
        }

        $quietOutput = @(. $scriptPath -ListGuid $script:TargetGuid 4>&1)
        $quietVerboseRecords = @($quietOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] })

        $quietVerboseRecords.Count | Should Be 0
        @($quietOutput | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] }).Count | Should Be 2

        $verboseOutput = @(. $scriptPath -ListGuid $script:TargetGuid -Verbose 4>&1)
        $verboseRecords = @($verboseOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] })

        ($verboseRecords.Count -gt 0) | Should Be $true
        (($verboseRecords | ForEach-Object { $_.Message }) -join ' ') | Should BeLike '*Consultando columnas*'
    }

    It 'lista columnas por Title usando contexto activo sin llamar Connect-Spo' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true; SiteUrl = 'https://contoso.sharepoint.com/sites/demo' }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
            TenantId   = 'tenant-context'
            ClientId   = 'client-context'
            AuthMode   = 'DeviceCode'
        }

        $result = @(. $scriptPath -ListTitle $script:TargetTitle)

        $script:ConnectSpoCallCount | Should Be 0
        $script:GetPnPListCallCount | Should Be 1
        $script:GetPnPFieldCallCount | Should Be 1
        $script:CapturedPnPListParams.Identity | Should Be $script:TargetTitle
        $script:CapturedPnPListParams.ThrowExceptionIfListNotFound | Should Be $true
        $script:CapturedPnPFieldParams.List | Should Be $script:TargetTitle
        $result.Count | Should Be 2
    }

    It 'falla sin contexto activo ni SiteUrl antes de llamar PnP' {
        try {
            . $scriptPath -ListGuid $script:TargetGuid
            throw 'Expected script to throw when active context is missing.'
        }
        catch {
            $_.Exception.Message | Should Be 'No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.'
        }

        $script:GetPnPListCallCount | Should Be 0
        $script:GetPnPFieldCallCount | Should Be 0
    }

    It 'falla con contexto activo invalido' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = $null
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }

        try {
            . $scriptPath -ListGuid $script:TargetGuid
            throw 'Expected script to throw when active context is invalid.'
        }
        catch {
            $_.Exception.Message | Should Be 'No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.'
        }
    }

    It 'usa parametros explicitos y autentica mediante Connect-Spo' {
        $result = @(. $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ListGuid $script:TargetGuid -TenantId 'tenant-id' -ClientId 'client-id')

        $result.Count | Should Be 2
        $script:ImportedModuleName | Should Be 'Connect-Spo'
        $script:ConnectSpoCallCount | Should Be 1
        $script:CapturedConnectSpoParams.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/demo'
        $script:CapturedConnectSpoParams.TenantId | Should Be 'tenant-id'
        $script:CapturedConnectSpoParams.ClientId | Should Be 'client-id'
        $script:CapturedConnectSpoParams.AuthMode | Should Be 'Interactive'
        $script:CapturedPnPFieldParams.Connection.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/demo'
    }

    It 'usa parametros explicitos con ListTitle y autentica mediante Connect-Spo' {
        $result = @(. $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ListTitle $script:TargetTitle -TenantId 'tenant-id' -ClientId 'client-id')

        $result.Count | Should Be 2
        $script:ImportedModuleName | Should Be 'Connect-Spo'
        $script:ConnectSpoCallCount | Should Be 1
        $script:CapturedConnectSpoParams.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/demo'
        $script:CapturedPnPListParams.Identity | Should Be $script:TargetTitle
        $script:CapturedPnPFieldParams.List | Should Be $script:TargetTitle
    }

    It 'rechaza ListGuid y ListTitle juntos' {
        try {
            . $scriptPath -ListGuid $script:TargetGuid -ListTitle $script:TargetTitle
            throw 'Expected script to reject conflicting list identity parameters.'
        }
        catch {
            $_.Exception.Message | Should BeLike '*Parameter set cannot be resolved*'
        }

        $script:GetPnPListCallCount | Should Be 0
        $script:GetPnPFieldCallCount | Should Be 0
    }

    It 'mapea DeviceLogin a DeviceCode y resuelve variables de entorno' {
        $env:ENTRAID_APP_ID = 'env-client-id'
        $env:AZURE_TENANT_ID = 'env-tenant-id'

        $null = . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ListGuid $script:TargetGuid -AuthMode DeviceLogin

        $script:CapturedConnectSpoParams.ClientId | Should Be 'env-client-id'
        $script:CapturedConnectSpoParams.TenantId | Should Be 'env-tenant-id'
        $script:CapturedConnectSpoParams.AuthMode | Should Be 'DeviceCode'
    }

    It 'falla claro si no puede cargar Connect-Spo' {
        Remove-Item -Path function:global:Connect-Spo -ErrorAction SilentlyContinue
        Mock Import-Module { throw 'module missing' }

        try {
            . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ListGuid $script:TargetGuid -TenantId 'tenant-id' -ClientId 'client-id'
            throw 'Expected script to throw when Connect-Spo is unavailable.'
        }
        catch {
            $_.Exception.Message | Should Be 'No se puede cargar la dependencia Connect-Spo. Instale o exponga el modulo Connect-Spo en PSModulePath y vuelva a ejecutar la operacion.'
        }
    }

    It 'falla claro cuando la lista no existe' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }
        $script:GetPnPListShouldThrow = $true

        try {
            . $scriptPath -ListGuid $script:TargetGuid
            throw 'Expected script to throw when list is missing.'
        }
        catch {
            $_.Exception.Message | Should BeLike '*No se pudieron obtener las columnas de la lista*'
            $_.Exception.Message | Should BeLike '*list not found*'
        }

        $script:GetPnPFieldCallCount | Should Be 0
    }

    It 'falla claro cuando la lista por Title no existe' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }
        $script:GetPnPListShouldThrow = $true

        try {
            . $scriptPath -ListTitle $script:TargetTitle
            throw 'Expected script to throw when list is missing.'
        }
        catch {
            $_.Exception.Message | Should BeLike "*No se pudieron obtener las columnas de la lista '$($script:TargetTitle)'*"
            $_.Exception.Message | Should BeLike '*list not found*'
        }

        $script:GetPnPFieldCallCount | Should Be 0
    }

    It 'falla claro cuando no puede leer campos' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }
        $script:GetPnPFieldShouldThrow = $true

        try {
            . $scriptPath -ListGuid $script:TargetGuid
            throw 'Expected script to throw when fields cannot be read.'
        }
        catch {
            $_.Exception.Message | Should BeLike '*No se pudieron obtener las columnas de la lista*'
            $_.Exception.Message | Should BeLike '*field read denied*'
        }
    }

    It 'usa FieldTypeKind como fallback final de Type' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }
        $script:MockFields = @(
            (New-TestField -InternalName 'LookupValue' -Title 'Lookup' -FieldTypeKind 'Lookup')
        )

        $result = @(. $scriptPath -ListGuid $script:TargetGuid)

        $result[0].Type | Should Be 'Lookup'
    }

    It 'descarta campos internos de SharePoint y conserva Title aunque venga de base type' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
        }

        $result = @(. $scriptPath -ListGuid $script:TargetGuid)
        $internalNames = @($result | ForEach-Object { $_.InternalName })

        ($internalNames -contains 'Title') | Should Be $true
        ($internalNames -contains 'CustomChoice') | Should Be $true
        ($internalNames -notcontains 'Created') | Should Be $true
        ($internalNames -notcontains '_UIVersionString') | Should Be $true
        ($internalNames -notcontains 'GUID') | Should Be $true
        ($internalNames -notcontains 'Attachments') | Should Be $true
    }

    It 'no llama Connect-PnPOnline directamente' {
        $source = Get-Content -Raw $scriptPath

        $source.Contains('Connect-PnPOnline') | Should Be $false
    }
}
