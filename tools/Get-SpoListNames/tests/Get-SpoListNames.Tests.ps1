# ===========================================================================
# Control de Cambios
# v0.1.0 | 2026-06-12 | Dev Agent | Implementacion inicial
# v0.1.2 | 2026-06-12 | Dev Agent | Migracion estructural a tools/Get-SpoListNames
# v0.2.0 | 2026-06-14 | Implementation Agent | Pruebas de consumo del modulo Connect-Spo por nombre
# ===========================================================================

Describe 'Get-SpoListNames.ps1' {
    BeforeAll {
        $scriptPath = Join-Path $PSScriptRoot '..\src\Get-SpoListNames.ps1'
        $originalEntraAppId = $env:ENTRAID_APP_ID
        $originalEntraClientId = $env:ENTRAID_CLIENT_ID
        $originalAzureClientId = $env:AZURE_CLIENT_ID
        $originalAzureTenantId = $env:AZURE_TENANT_ID

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

                [pscustomobject]@{ Connected = $true }
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
        Remove-Item -Path function:global:Connect-Spo -ErrorAction SilentlyContinue
    }

    It 'lista solo listas visibles no documentales y ordenadas por titulo despues de autenticar con Connect-Spo' {
        Mock Get-PnPList {
            param($Includes, $ErrorAction)

            $script:GetPnPListCallCount += 1
            $script:CapturedIncludes = $Includes

            @(
                [pscustomobject]@{
                    EntityTypeName = 'TasksList'
                    Title          = 'Tasks'
                    Hidden         = $false
                    BaseType       = 'GenericList'
                },
                [pscustomobject]@{
                    EntityTypeName = 'Documents'
                    Title          = 'Documents'
                    Hidden         = $false
                    BaseType       = 'DocumentLibrary'
                },
                [pscustomobject]@{
                    EntityTypeName = 'AnnouncementsList'
                    Title          = 'Announcements'
                    Hidden         = $false
                    BaseType       = 'GenericList'
                },
                [pscustomobject]@{
                    EntityTypeName = 'HiddenList'
                    Title          = 'Hidden'
                    Hidden         = $true
                    BaseType       = 'GenericList'
                }
            )
        }

        $result = @(. $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -ClientId 'client-id' -TenantId 'tenant-id')

        $result.Count | Should Be 2
        $result[0].InternalName | Should Be 'AnnouncementsList'
        $result[0].VisibleTitle | Should Be 'Announcements'
        $result[1].InternalName | Should Be 'TasksList'
        $result[1].VisibleTitle | Should Be 'Tasks'

        $script:ImportedModuleName | Should Be 'Connect-Spo'
        $script:ConnectSpoCallCount | Should Be 1
        $script:CapturedConnectSpoParams.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/demo'
        $script:CapturedConnectSpoParams.ClientId | Should Be 'client-id'
        $script:CapturedConnectSpoParams.TenantId | Should Be 'tenant-id'
        $script:CapturedConnectSpoParams.AuthMode | Should Be 'Interactive'
        $script:GetPnPListCallCount | Should Be 1

        $script:CapturedIncludes -contains 'EntityTypeName' | Should Be $true
        $script:CapturedIncludes -contains 'Title' | Should Be $true
        $script:CapturedIncludes -contains 'Hidden' | Should Be $true
        $script:CapturedIncludes -contains 'BaseType' | Should Be $true
    }

    It 'mapea DeviceLogin a DeviceCode al invocar Connect-Spo' {
        Mock Get-PnPList {
            $script:GetPnPListCallCount += 1
            @(
                [pscustomobject]@{
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
            @([pscustomobject]@{ EntityTypeName = 'TasksList'; Title = 'Tasks'; Hidden = $false; BaseType = 'GenericList' })
        }

        $null = . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-id'

        $script:CapturedConnectSpoParams.ClientId | Should Be 'env-client-id'
    }

    It 'resuelve ClientId desde AZURE_CLIENT_ID cuando no hay variables ENTRAID' {
        $env:AZURE_CLIENT_ID = 'azure-client-id'
        Mock Get-PnPList {
            @([pscustomobject]@{ EntityTypeName = 'TasksList'; Title = 'Tasks'; Hidden = $false; BaseType = 'GenericList' })
        }

        $null = . $scriptPath -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-id'

        $script:CapturedConnectSpoParams.ClientId | Should Be 'azure-client-id'
    }

    It 'resuelve TenantId desde AZURE_TENANT_ID cuando no se entrega por parametro' {
        $env:AZURE_TENANT_ID = 'env-tenant-id'
        Mock Get-PnPList {
            @([pscustomobject]@{ EntityTypeName = 'TasksList'; Title = 'Tasks'; Hidden = $false; BaseType = 'GenericList' })
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
