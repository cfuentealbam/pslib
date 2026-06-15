# ===========================================================================
# Control de Cambios
# v0.1.0 | 2026-06-14 | Implementation Agent | Pruebas del modulo reusable Get-SpoListNames
# ===========================================================================

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$modulesRoot = Join-Path $repoRoot 'modules'
$manifestPath = Join-Path $modulesRoot 'Get-SpoListNames\Get-SpoListNames.psd1'
$originalPSModulePath = $env:PSModulePath

Describe 'Get-SpoListNames module' {
    BeforeAll {
        $fixtureModulesRoot = Join-Path $TestDrive 'Modules'
        $fixtureConnectSpoRoot = Join-Path $fixtureModulesRoot 'Connect-Spo'
        New-Item -ItemType Directory -Force -Path $fixtureConnectSpoRoot | Out-Null

        $fixtureConnectSpoModule = @'
function Connect-Spo {
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

    $global:GetSpoListNamesConnectSpoCallCount += 1
    $global:GetSpoListNamesCapturedConnectSpoParams = @{
        SiteUrl  = $SiteUrl
        TenantId = $TenantId
        ClientId = $ClientId
        AuthMode = $AuthMode
    }

    if ($global:GetSpoListNamesConnectSpoShouldThrow) {
        throw 'autenticacion rechazada'
    }

    [pscustomobject]@{ Connected = $true }
}

Export-ModuleMember -Function 'Connect-Spo'
'@

        Set-Content -Path (Join-Path $fixtureConnectSpoRoot 'Connect-Spo.psm1') -Value $fixtureConnectSpoModule -Encoding UTF8

        Remove-Module Get-SpoListNames -ErrorAction SilentlyContinue
        Remove-Module Connect-Spo -ErrorAction SilentlyContinue
        $env:PSModulePath = "$fixtureModulesRoot$([IO.Path]::PathSeparator)$modulesRoot$([IO.Path]::PathSeparator)$originalPSModulePath"
        Import-Module $manifestPath -Force -ErrorAction Stop
    }

    AfterAll {
        Remove-Module Get-SpoListNames -ErrorAction SilentlyContinue
        Remove-Module Connect-Spo -ErrorAction SilentlyContinue
        $env:PSModulePath = $originalPSModulePath
        Remove-Item -Path function:global:Get-PnPList -ErrorAction SilentlyContinue
    }

    BeforeEach {
        $global:GetSpoListNamesCapturedConnectSpoParams = $null
        $global:GetSpoListNamesConnectSpoCallCount = 0
        $global:GetSpoListNamesGetPnPListCallCount = 0
        $global:GetSpoListNamesConnectSpoShouldThrow = $false
        $global:GetSpoListNamesMockLists = @()

        function global:Get-PnPList {
            [CmdletBinding()]
            param(
                [Parameter()]
                [string[]]$Includes
            )

            $global:GetSpoListNamesGetPnPListCallCount += 1
            return $global:GetSpoListNamesMockLists
        }
    }

    It 'validates the module manifest' {
        $manifestData = Test-ModuleManifest -Path $manifestPath

        $manifestData.Name | Should Be 'Get-SpoListNames'
        $manifestData.Version.ToString() | Should Be '0.1.0'
        $manifestData.RequiredModules.Name -contains 'Connect-Spo' | Should Be $true
    }

    It 'imports the module from the repository manifest' {
        (Get-Module Get-SpoListNames).Name | Should Be 'Get-SpoListNames'
    }

    It 'exports exactly Get-SpoListNames as public command' {
        $publicCommands = Get-Command -Module Get-SpoListNames | Select-Object -ExpandProperty Name

        @($publicCommands).Count | Should Be 1
        @($publicCommands)[0] | Should Be 'Get-SpoListNames'
    }

    It 'does not export helper commands' {
        $helperNames = @(
            'Import-GetSpoListNamesAuthenticationModule',
            'Resolve-GetSpoListNamesClientId',
            'Resolve-GetSpoListNamesTenantId',
            'ConvertTo-GetSpoListNamesConnectSpoAuthMode',
            'Invoke-GetSpoListNamesAuthentication'
        )

        foreach ($helperName in $helperNames) {
            (Get-Command -Module Get-SpoListNames -Name $helperName -ErrorAction SilentlyContinue) | Should Be $null
        }
    }

    It 'exposes comment-based help for the public command' {
        $help = Get-Help Get-SpoListNames

        $help.Synopsis | Should BeLike '*Lista nombres tecnicos*'
        @($help.Parameters.Parameter | Where-Object { $_.Name -eq 'SiteUrl' }).Count | Should Be 1
    }

    It 'keeps list filtering and output shape with mocked SharePoint calls' {
        $global:GetSpoListNamesMockLists = @(
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
            }
        )

        $result = @(Get-SpoListNames -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-id' -ClientId 'client-id')

        $result.Count | Should Be 2
        $result[0].InternalName | Should Be 'AnnouncementsList'
        $result[0].VisibleTitle | Should Be 'Announcements'
        $result[1].InternalName | Should Be 'TasksList'
        $result[1].VisibleTitle | Should Be 'Tasks'
        $global:GetSpoListNamesConnectSpoCallCount | Should Be 1
        $global:GetSpoListNamesGetPnPListCallCount | Should Be 1
    }

    It 'maps DeviceLogin to DeviceCode when authenticating through Connect-Spo' {
        $global:GetSpoListNamesMockLists = @([pscustomobject]@{ EntityTypeName = 'TasksList'; Title = 'Tasks'; Hidden = $false; BaseType = 'GenericList' })

        $null = Get-SpoListNames -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -AuthMode DeviceLogin -TenantId 'tenant-id' -ClientId 'client-id'

        $global:GetSpoListNamesCapturedConnectSpoParams.AuthMode | Should Be 'DeviceCode'
    }

    It 'does not query lists when Connect-Spo authentication fails' {
        $global:GetSpoListNamesConnectSpoShouldThrow = $true

        try {
            Get-SpoListNames -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-id' -ClientId 'client-id'
            throw 'Expected command to throw when Connect-Spo fails.'
        }
        catch {
            $_.Exception.Message | Should BeLike '*No se pudo autenticar mediante Connect-Spo*'
        }

        $global:GetSpoListNamesGetPnPListCallCount | Should Be 0
    }
}
