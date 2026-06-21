# ===========================================================================
# Control de Cambios
# v0.1.0 | 2026-06-12 | Dev Agent | Implementacion inicial
# v0.1.2 | 2026-06-12 | Dev Agent | Migracion estructural a tools/Get-SpoListNames
# v0.2.0 | 2026-06-14 | Implementation Agent | Pruebas de consumo del modulo Connect-Spo por nombre
# v0.3.0 | 2026-06-15 | Dev Agent | Valida salida GUID, EntityTypeName y Title
# ===========================================================================

Describe 'Get-SpoListNames.ps1' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..\src\Get-SpoListNames.ps1'
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
                    SiteUrl   = $SiteUrl
                    TenantId  = $TenantId
                    ClientId  = $ClientId
                    AuthMode  = $AuthMode
                }

                if ($script:ConnectSpoShouldThrow) {
                    throw 'autenticacion rechazada'
                }

                [pscustomobject]@{ Connected = $true; SiteUrl = $SiteUrl }
            }

            $script:ConnectSpoShouldThrow = [bool]$Throw
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
        $script:ImportedModuleName = $null
        $script:CapturedPnPConnection = $null
        Remove-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Connect-Spo -ErrorAction SilentlyContinue
        Set-ConnectSpoStub

        Mock Import-Module {
            param($Name)
            $script:ImportedModuleName = $Name
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
    }

    It 'lista solo listas visibles no documentales y ordenadas por titulo despues de autenticar con Connect-Spo' {
        Mock Get-PnPList {
            param($Connection, $Includes, $ErrorAction)

            $script:GetPnPListCallCount += 1
            $script:CapturedPnPConnection = $Connection
            $script:CapturedIncludes = $Includes

            @(
                [pscustomobject]@{
                    Id             = '11111111-1111-1111-1111-111111111111'
                    EntityTypeName = 'TasksList'
                    Title          = 'Tasks'
                    Hidden         = $false
                    BaseType       = 'GenericList'
                },
                [pscustomobject]@{
                    Id             = '22222222-2222-2222-2222-222222222222'
                    EntityTypeName = 'Documents'
                    Title          = 'Documents'
                    Hidden         = $false
                    BaseType       = 'DocumentLibrary'
                },
                [pscustomobject]@{
                    Id             = '33333333-3333-3333-3333-333333333333'
                    EntityTypeName = 'AnnouncementsList'
                    Title          = 'Announcements'
                    Hidden         = $false
                    BaseType       = 'GenericList'
                },
                [pscustomobject]@{
                    Id             = '44444444-4444-4444-4444-444444444444'
                    EntityTypeName = 'HiddenList'
                    Title          = 'Hidden'
                    Hidden         = $true
                    BaseType       = 'GenericList'
                }
            )
        }

        $result = @(. $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ClientId 'client-id' -TenantId 'tenant-id')

        $result.Count | Should Be 2
        $result[0].GUID | Should Be '33333333-3333-3333-3333-333333333333'
        $result[0].EntityTypeName | Should Be 'AnnouncementsList'
        $result[0].Title | Should Be 'Announcements'
        $result[1].GUID | Should Be '11111111-1111-1111-1111-111111111111'
        $result[1].EntityTypeName | Should Be 'TasksList'
        $result[1].Title | Should Be 'Tasks'

        $script:ImportedModuleName | Should Be 'Connect-Spo'
        $script:ConnectSpoCallCount | Should Be 1
        $script:CapturedConnectSpoParams.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/demo'
        $script:CapturedConnectSpoParams.ClientId | Should Be 'client-id'
        $script:CapturedConnectSpoParams.TenantId | Should Be 'tenant-id'
        $script:CapturedConnectSpoParams.AuthMode | Should Be 'Interactive'
        $script:GetPnPListCallCount | Should Be 1
        $script:CapturedPnPConnection.Connected | Should Be $true
        $script:CapturedPnPConnection.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/demo'

        $script:CapturedIncludes -contains 'Id' | Should Be $true
        $script:CapturedIncludes -contains 'EntityTypeName' | Should Be $true
        $script:CapturedIncludes -contains 'Title' | Should Be $true
        $script:CapturedIncludes -contains 'Hidden' | Should Be $true
        $script:CapturedIncludes -contains 'BaseType' | Should Be $true
    }

    It 'funciona quiet por defecto y muestra mensajes auxiliares solo con Verbose' {
        Mock Get-PnPList {
            @([pscustomobject]@{ Id = '11111111-1111-1111-1111-111111111111'; EntityTypeName = 'TasksList'; Title = 'Tasks'; Hidden = $false; BaseType = 'GenericList' })
        }

        $quietOutput = @(. $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ClientId 'client-id' -TenantId 'tenant-id' 4>&1)
        $quietVerboseRecords = @($quietOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] })

        $quietVerboseRecords.Count | Should Be 0
        @($quietOutput | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] }).Count | Should Be 1

        $verboseOutput = @(. $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ClientId 'client-id' -TenantId 'tenant-id' -Verbose 4>&1)
        $verboseRecords = @($verboseOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] })

        ($verboseRecords.Count -gt 0) | Should Be $true
        (($verboseRecords | ForEach-Object { $_.Message }) -join ' ') | Should BeLike '*Consultando listas del sitio*'
    }

    It 'usa el contexto activo de Connect-Spo cuando se ejecuta sin parametros' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true; SiteUrl = 'https://contoso.sharepoint.com/sites/context' }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/context'
            TenantId   = 'tenant-context'
            ClientId   = 'client-context'
            AuthMode   = 'DeviceCode'
        }

        Mock Get-PnPList {
            param($Connection, $Includes, $ErrorAction)

            $script:GetPnPListCallCount += 1
            $script:CapturedPnPConnection = $Connection

            @(
                [pscustomobject]@{
                    Id             = '11111111-1111-1111-1111-111111111111'
                    EntityTypeName = 'TasksList'
                    Title          = 'Tasks'
                    Hidden         = $false
                    BaseType       = 'GenericList'
                }
            )
        }

        $result = @(. $scriptPath)

        $result.Count | Should Be 1
        $result[0].GUID | Should Be '11111111-1111-1111-1111-111111111111'
        $script:ConnectSpoCallCount | Should Be 0
        $script:GetPnPListCallCount | Should Be 1
        $script:CapturedPnPConnection.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/context'
    }

    It 'usa el SiteUrl del contexto activo en errores de consulta sin parametros' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/context'
            TenantId   = 'tenant-context'
            ClientId   = 'client-context'
            AuthMode   = 'Interactive'
        }

        Mock Get-PnPList {
            throw 'consulta rechazada'
        }

        try {
            . $scriptPath
            throw 'Expected script to throw when Get-PnPList fails.'
        }
        catch {
            $_.Exception.Message | Should BeLike "*https://contoso.sharepoint.com/sites/context*"
        }
    }

    It 'falla sin parametros cuando no existe contexto activo y no consulta listas' {
        Mock Get-PnPList {
            $script:GetPnPListCallCount += 1
            @()
        }

        try {
            . $scriptPath
            throw 'Expected script to throw when active context is missing.'
        }
        catch {
            $_.Exception.Message | Should Be 'No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.'
        }

        $script:ConnectSpoCallCount | Should Be 0
        $script:GetPnPListCallCount | Should Be 0
    }

    It 'falla sin parametros cuando el contexto activo no tiene conexion usable' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            SiteUrl  = 'https://contoso.sharepoint.com/sites/context'
            TenantId = 'tenant-context'
            ClientId = 'client-context'
            AuthMode = 'Interactive'
        }

        try {
            . $scriptPath
            throw 'Expected script to throw when active context is invalid.'
        }
        catch {
            $_.Exception.Message | Should Be 'No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.'
        }
    }

    It 'usa parametros explicitos por sobre un contexto activo existente' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true; SiteUrl = 'https://contoso.sharepoint.com/sites/context' }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/context'
            TenantId   = 'tenant-context'
            ClientId   = 'client-context'
            AuthMode   = 'DeviceCode'
        }

        Mock Get-PnPList {
            param($Connection, $Includes, $ErrorAction)

            $script:GetPnPListCallCount += 1
            $script:CapturedPnPConnection = $Connection

            @([pscustomobject]@{ Id = '11111111-1111-1111-1111-111111111111'; EntityTypeName = 'TasksList'; Title = 'Tasks'; Hidden = $false; BaseType = 'GenericList' })
        }

        $null = . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ClientId 'client-id' -TenantId 'tenant-id'

        $script:ConnectSpoCallCount | Should Be 1
        $script:CapturedConnectSpoParams.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/demo'
        $script:CapturedPnPConnection.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/demo'
    }

    It 'mapea DeviceLogin a DeviceCode al invocar Connect-Spo' {
        Mock Get-PnPList {
            $script:GetPnPListCallCount += 1
            @(
                [pscustomobject]@{
                    Id             = '11111111-1111-1111-1111-111111111111'
                    EntityTypeName = 'TasksList'
                    Title          = 'Tasks'
                    Hidden         = $false
                    BaseType       = 'GenericList'
                }
            )
        }

        $null = . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -AuthMode DeviceLogin -ClientId 'client-id' -TenantId 'tenant-id'

        $script:CapturedConnectSpoParams.AuthMode | Should Be 'DeviceCode'
        $script:GetPnPListCallCount | Should Be 1
    }

    It 'resuelve ClientId desde variables de entorno si no se entrega por parametro' {
        $env:ENTRAID_APP_ID = 'env-client-id'
        Mock Get-PnPList {
            @([pscustomobject]@{ Id = '11111111-1111-1111-1111-111111111111'; EntityTypeName = 'TasksList'; Title = 'Tasks'; Hidden = $false; BaseType = 'GenericList' })
        }

        $null = . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-id'

        $script:CapturedConnectSpoParams.ClientId | Should Be 'env-client-id'
    }

    It 'resuelve ClientId desde AZURE_CLIENT_ID cuando no hay variables ENTRAID' {
        $env:AZURE_CLIENT_ID = 'azure-client-id'
        Mock Get-PnPList {
            @([pscustomobject]@{ Id = '11111111-1111-1111-1111-111111111111'; EntityTypeName = 'TasksList'; Title = 'Tasks'; Hidden = $false; BaseType = 'GenericList' })
        }

        $null = . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-id'

        $script:CapturedConnectSpoParams.ClientId | Should Be 'azure-client-id'
    }

    It 'resuelve TenantId desde AZURE_TENANT_ID cuando no se entrega por parametro' {
        $env:AZURE_TENANT_ID = 'env-tenant-id'
        Mock Get-PnPList {
            @([pscustomobject]@{ Id = '11111111-1111-1111-1111-111111111111'; EntityTypeName = 'TasksList'; Title = 'Tasks'; Hidden = $false; BaseType = 'GenericList' })
        }

        $null = . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ClientId 'client-id'

        $script:CapturedConnectSpoParams.TenantId | Should Be 'env-tenant-id'
    }

    It 'falla con error claro cuando no hay TenantId disponible' {
        try {
            . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ClientId 'client-id'
            throw 'Expected script to throw when TenantId is missing.'
        }
        catch {
            $_.Exception.Message | Should BeLike '*No se pudo resolver TenantId para Connect-Spo*'
        }
    }

    It 'falla con error claro cuando no hay ClientId disponible' {
        try {
            . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-id'
            throw 'Expected script to throw when ClientId is missing.'
        }
        catch {
            $_.Exception.Message | Should BeLike '*No se pudo resolver ClientId*'
        }
    }

    It 'falla con error claro si Connect-Spo no esta disponible y no consulta listas' {
        Remove-Item -Path function:global:Connect-Spo -ErrorAction SilentlyContinue
        Mock Import-Module { throw 'modulo no encontrado' }
        Mock Get-PnPList {
            $script:GetPnPListCallCount += 1
            @()
        }

        try {
            . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ClientId 'client-id' -TenantId 'tenant-id'
            throw 'Expected script to throw when Connect-Spo is unavailable.'
        }
        catch {
            $_.Exception.Message | Should Be 'No se puede cargar la dependencia Connect-Spo. Instale o exponga el modulo Connect-Spo en PSModulePath y vuelva a ejecutar la operacion.'
        }

        $script:GetPnPListCallCount | Should Be 0
    }

    It 'no consulta listas si Connect-Spo falla autenticando' {
        Set-ConnectSpoStub -Throw
        Mock Get-PnPList {
            $script:GetPnPListCallCount += 1
            @()
        }

        try {
            . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ClientId 'client-id' -TenantId 'tenant-id'
            throw 'Expected script to throw when Connect-Spo fails.'
        }
        catch {
            $_.Exception.Message | Should BeLike '*No se pudo autenticar mediante Connect-Spo*'
        }

        $script:GetPnPListCallCount | Should Be 0
    }

    It 'no llama Connect-PnPOnline directamente ni referencia rutas de tools/Connect-Spo' {
        $source = Get-Content -Raw $scriptPath

        $source.Contains('Connect-PnPOnline') | Should Be $false
        $source.Contains('tools/Connect-Spo') | Should Be $false
        $source.Contains('tools\Connect-Spo') | Should Be $false
    }
}
