# ===========================================================================
# Control de Cambios
# v0.1.0 | 2026-06-14 | Implementation Agent | Pruebas del modulo reusable Get-SpoListNames
# v0.2.0 | 2026-06-15 | Dev Agent | Valida salida GUID, EntityTypeName y Title
# ===========================================================================

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$modulesRoot = Join-Path $repoRoot 'modules'
$manifestPath = Join-Path $modulesRoot 'Get-SpoListNames\Get-SpoListNames.psd1'
$originalPSModulePath = $env:PSModulePath
$originalSpoConnectionContext = Get-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue

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

    [pscustomobject]@{ Connected = $true; SiteUrl = $SiteUrl }
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
        if ($null -ne $originalSpoConnectionContext) {
            Set-Variable -Name PSLibSpoConnectionContext -Scope Global -Value $originalSpoConnectionContext.Value
        }
        else {
            Remove-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue
        }
        Remove-Item -Path function:global:Get-PnPList -ErrorAction SilentlyContinue
    }

    BeforeEach {
        $global:GetSpoListNamesCapturedConnectSpoParams = $null
        $global:GetSpoListNamesConnectSpoCallCount = 0
        $global:GetSpoListNamesGetPnPListCallCount = 0
        $global:GetSpoListNamesConnectSpoShouldThrow = $false
        $global:GetSpoListNamesMockLists = @()
        $global:GetSpoListNamesCapturedPnPConnection = $null
        $global:GetSpoListNamesCapturedIncludes = $null
        Remove-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue

        function global:Get-PnPList {
            [CmdletBinding()]
            param(
                [Parameter()]
                [object]$Connection,

                [Parameter()]
                [string[]]$Includes
            )

            $global:GetSpoListNamesGetPnPListCallCount += 1
            $global:GetSpoListNamesCapturedPnPConnection = $Connection
            $global:GetSpoListNamesCapturedIncludes = $Includes
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
            'Invoke-GetSpoListNamesAuthentication',
            'Get-GetSpoListNamesActiveContext',
            'Resolve-GetSpoListNamesExecutionContext'
        )

        foreach ($helperName in $helperNames) {
            (Get-Command -Module Get-SpoListNames -Name $helperName -ErrorAction SilentlyContinue) | Should Be $null
        }
    }

    It 'exposes comment-based help for the public command' {
        $help = Get-Help Get-SpoListNames

        $help.Synopsis | Should BeLike '*Lista GUID*'
        @($help.Parameters.Parameter | Where-Object { $_.Name -eq 'SiteUrl' }).Count | Should Be 1
    }

    It 'keeps list filtering and output shape with mocked SharePoint calls' {
        $global:GetSpoListNamesMockLists = @(
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
            }
        )

        $result = @(Get-SpoListNames -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-id' -ClientId 'client-id')

        $result.Count | Should Be 2
        $result[0].GUID | Should Be '33333333-3333-3333-3333-333333333333'
        $result[0].EntityTypeName | Should Be 'AnnouncementsList'
        $result[0].Title | Should Be 'Announcements'
        $result[1].GUID | Should Be '11111111-1111-1111-1111-111111111111'
        $result[1].EntityTypeName | Should Be 'TasksList'
        $result[1].Title | Should Be 'Tasks'
        $global:GetSpoListNamesConnectSpoCallCount | Should Be 1
        $global:GetSpoListNamesGetPnPListCallCount | Should Be 1
        $global:GetSpoListNamesCapturedPnPConnection.Connected | Should Be $true
        $global:GetSpoListNamesCapturedPnPConnection.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/demo'
        $global:GetSpoListNamesCapturedIncludes -contains 'Id' | Should Be $true
        $global:GetSpoListNamesCapturedIncludes -contains 'EntityTypeName' | Should Be $true
        $global:GetSpoListNamesCapturedIncludes -contains 'Title' | Should Be $true
    }

    It 'runs quiet by default and emits auxiliary messages only with Verbose' {
        $global:GetSpoListNamesMockLists = @([pscustomobject]@{ Id = '11111111-1111-1111-1111-111111111111'; EntityTypeName = 'TasksList'; Title = 'Tasks'; Hidden = $false; BaseType = 'GenericList' })

        $quietOutput = @(Get-SpoListNames -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-id' -ClientId 'client-id' 4>&1)
        $quietVerboseRecords = @($quietOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] })

        $quietVerboseRecords.Count | Should Be 0
        @($quietOutput | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] }).Count | Should Be 1

        $verboseOutput = @(Get-SpoListNames -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-id' -ClientId 'client-id' -Verbose 4>&1)
        $verboseRecords = @($verboseOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] })

        ($verboseRecords.Count -gt 0) | Should Be $true
        (($verboseRecords | ForEach-Object { $_.Message }) -join ' ') | Should BeLike '*Consultando listas del sitio*'
    }

    It 'uses the active Connect-Spo context when called without parameters' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true; SiteUrl = 'https://contoso.sharepoint.com/sites/context' }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/context'
            TenantId   = 'tenant-context'
            ClientId   = 'client-context'
            AuthMode   = 'DeviceCode'
        }
        $global:GetSpoListNamesMockLists = @([pscustomobject]@{ Id = '11111111-1111-1111-1111-111111111111'; EntityTypeName = 'TasksList'; Title = 'Tasks'; Hidden = $false; BaseType = 'GenericList' })

        $result = @(Get-SpoListNames)

        $result.Count | Should Be 1
        $result[0].GUID | Should Be '11111111-1111-1111-1111-111111111111'
        $global:GetSpoListNamesConnectSpoCallCount | Should Be 0
        $global:GetSpoListNamesGetPnPListCallCount | Should Be 1
        $global:GetSpoListNamesCapturedPnPConnection.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/context'
    }

    It 'fails clearly without parameters when no active context exists' {
        try {
            Get-SpoListNames
            throw 'Expected command to throw when active context is missing.'
        }
        catch {
            $_.Exception.Message | Should Be 'No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.'
        }

        $global:GetSpoListNamesConnectSpoCallCount | Should Be 0
        $global:GetSpoListNamesGetPnPListCallCount | Should Be 0
    }

    It 'fails clearly without parameters when active context is invalid' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = $null
            SiteUrl    = 'https://contoso.sharepoint.com/sites/context'
            TenantId   = 'tenant-context'
            ClientId   = 'client-context'
            AuthMode   = 'Interactive'
        }

        try {
            Get-SpoListNames
            throw 'Expected command to throw when active context is invalid.'
        }
        catch {
            $_.Exception.Message | Should Be 'No existe una conexion SharePoint activa. Ejecuta Connect-Spo primero o proporciona SiteUrl, TenantId y ClientId.'
        }
    }

    It 'uses explicit parameters instead of an existing active context' {
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true; SiteUrl = 'https://contoso.sharepoint.com/sites/context' }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/context'
            TenantId   = 'tenant-context'
            ClientId   = 'client-context'
            AuthMode   = 'DeviceCode'
        }
        $global:GetSpoListNamesMockLists = @([pscustomobject]@{ Id = '11111111-1111-1111-1111-111111111111'; EntityTypeName = 'TasksList'; Title = 'Tasks'; Hidden = $false; BaseType = 'GenericList' })

        $null = Get-SpoListNames -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-id' -ClientId 'client-id'

        $global:GetSpoListNamesConnectSpoCallCount | Should Be 1
        $global:GetSpoListNamesCapturedConnectSpoParams.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/demo'
        $global:GetSpoListNamesCapturedPnPConnection.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/demo'
    }

    It 'maps DeviceLogin to DeviceCode when authenticating through Connect-Spo' {
        $global:GetSpoListNamesMockLists = @([pscustomobject]@{ Id = '11111111-1111-1111-1111-111111111111'; EntityTypeName = 'TasksList'; Title = 'Tasks'; Hidden = $false; BaseType = 'GenericList' })

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
