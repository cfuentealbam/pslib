# ===========================================================================
# Control de Cambios
# v0.1.0 | 2026-06-14 | Implementation Agent | Pruebas del módulo reusable Connect-Spo importable por nombre
# ===========================================================================

$moduleRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..\modules\Connect-Spo')
$manifestPath = Join-Path $moduleRoot 'Connect-Spo.psd1'
$originalPSModulePath = $env:PSModulePath
$originalSpoConnectionContext = Get-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue

Describe 'Connect-Spo module' {
    BeforeAll {
        Remove-Module Connect-Spo -ErrorAction SilentlyContinue
        $env:PSModulePath = "$((Resolve-Path (Join-Path $PSScriptRoot '..\..\..\modules')).Path)$([IO.Path]::PathSeparator)$originalPSModulePath"
        Import-Module Connect-Spo -Force -ErrorAction Stop
    }

    AfterAll {
        Remove-Module Connect-Spo -ErrorAction SilentlyContinue
        $env:PSModulePath = $originalPSModulePath
        if ($null -ne $originalSpoConnectionContext) {
            Set-Variable -Name PSLibSpoConnectionContext -Scope Global -Value $originalSpoConnectionContext.Value
        }
        else {
            Remove-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue
        }
    }

    BeforeEach {
        Remove-Item -Path function:Connect-PnPOnline -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Connect-PnPOnline -ErrorAction SilentlyContinue
        Remove-Item -Path function:Get-PnPWeb -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Get-PnPWeb -ErrorAction SilentlyContinue
        $script:capturedConnectParameters = $null
        $script:capturedGetPnPWebParameters = $null
        $script:connectPnPOnlineCallCount = 0
        $script:getPnPWebCallCount = 0
        $script:getPnPWebShouldThrow = $false
        Remove-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue

        function global:Connect-PnPOnline {
            [CmdletBinding()]
            param(
                [Parameter()]
                [string]$Url,

                [Parameter()]
                [string]$ClientId,

                [Parameter()]
                [switch]$Interactive,

                [Parameter()]
                [switch]$DeviceLogin,

                [Parameter()]
                [string]$Tenant,

                [Parameter()]
                [switch]$ReturnConnection
            )

            $script:connectPnPOnlineCallCount += 1
            $script:capturedConnectParameters = @{}
            foreach ($parameterName in $PSBoundParameters.Keys) {
                $script:capturedConnectParameters[$parameterName] = $PSBoundParameters[$parameterName]
            }

            [pscustomobject]@{ Connected = $true }
        }

        function global:Get-PnPWeb {
            [CmdletBinding()]
            param(
                [Parameter()]
                [object]$Connection,

                [Parameter()]
                [string[]]$Includes
            )

            $script:getPnPWebCallCount += 1
            $script:capturedGetPnPWebParameters = @{
                Connection = $Connection
                Includes   = $Includes
            }

            if ($script:getPnPWebShouldThrow) {
                throw 'connection expired'
            }

            [pscustomobject]@{ Url = 'https://contoso.sharepoint.com/sites/demo' }
        }
    }

    AfterEach {
        Remove-Item -Path function:Connect-PnPOnline -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Connect-PnPOnline -ErrorAction SilentlyContinue
        Remove-Item -Path function:Get-PnPWeb -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Get-PnPWeb -ErrorAction SilentlyContinue
        Remove-Item -Path env:ENTRAID_CLIENT_ID -ErrorAction SilentlyContinue
        Remove-Item -Path env:ENTRAID_APP_ID -ErrorAction SilentlyContinue
        Remove-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue
    }

    It 'validates the module manifest' {
        $manifestData = Test-ModuleManifest -Path $manifestPath

        $manifestData.Name | Should Be 'Connect-Spo'
        $manifestData.Version.ToString() | Should Be '0.1.0'
    }

    It 'imports the module by name from PSModulePath' {
        (Get-Module Connect-Spo).Name | Should Be 'Connect-Spo'
    }

    It 'exports exactly Connect-Spo as public command' {
        $publicCommands = Get-Command -Module Connect-Spo | Select-Object -ExpandProperty Name

        @($publicCommands).Count | Should Be 1
        @($publicCommands)[0] | Should Be 'Connect-Spo'
    }

    It 'does not export helper commands' {
        $helperNames = @(
            'Resolve-SharePointUnifiedClientId',
            'Test-SharePointUnifiedAuthDependency',
            'New-SharePointUnifiedConnectParameters',
            'ConvertTo-SharePointUnifiedAuthError',
            'Set-SharePointUnifiedSessionContext',
            'ConvertTo-SharePointUnifiedNormalizedSiteUrl',
            'Get-SharePointUnifiedActiveContext',
            'Test-SharePointUnifiedReusableSessionContext'
        )

        foreach ($helperName in $helperNames) {
            (Get-Command -Module Connect-Spo -Name $helperName -ErrorAction SilentlyContinue) | Should Be $null
        }
    }

    It 'keeps ClientId precedence and validates input through the public command' {
        $env:ENTRAID_CLIENT_ID = 'env-client'

        $connection = Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant' -ClientId '  direct-client  ' -AuthMode Interactive

        $connection.Connected | Should Be $true
        $script:capturedConnectParameters.Url | Should Be 'https://contoso.sharepoint.com/sites/demo'
        $script:capturedConnectParameters.ClientId | Should Be 'direct-client'
        $script:capturedConnectParameters.Interactive | Should Be $true
        $script:capturedConnectParameters.ReturnConnection | Should Be $true
        $script:capturedConnectParameters.ContainsKey('PersistLogin') | Should Be $false
        $script:capturedConnectParameters.ContainsKey('Credentials') | Should Be $false
        $script:capturedConnectParameters.ContainsKey('ClientSecret') | Should Be $false
        $script:capturedConnectParameters.ContainsKey('CertificatePath') | Should Be $false
        $script:capturedConnectParameters.ContainsKey('AccessToken') | Should Be $false
        $script:capturedConnectParameters.ContainsKey('EnvironmentVariable') | Should Be $false
        $global:PSLibSpoConnectionContext.Connection | Should Be $connection
        $global:PSLibSpoConnectionContext.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/demo'
        $global:PSLibSpoConnectionContext.TenantId | Should Be 'tenant'
        $global:PSLibSpoConnectionContext.ClientId | Should Be 'direct-client'
        $global:PSLibSpoConnectionContext.AuthMode | Should Be 'Interactive'
    }

    It 'invokes Connect-PnPOnline with DeviceCode parameters' {
        $connection = Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant.onmicrosoft.com' -ClientId 'client' -AuthMode DeviceCode

        $connection.Connected | Should Be $true
        $script:capturedConnectParameters.Url | Should Be 'https://contoso.sharepoint.com/sites/demo'
        $script:capturedConnectParameters.ClientId | Should Be 'client'
        $script:capturedConnectParameters.DeviceLogin | Should Be $true
        $script:capturedConnectParameters.Tenant | Should Be 'tenant.onmicrosoft.com'
        $script:capturedConnectParameters.ReturnConnection | Should Be $true
        $global:PSLibSpoConnectionContext.Connection | Should Be $connection
        $global:PSLibSpoConnectionContext.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/demo'
        $global:PSLibSpoConnectionContext.TenantId | Should Be 'tenant.onmicrosoft.com'
        $global:PSLibSpoConnectionContext.ClientId | Should Be 'client'
        $global:PSLibSpoConnectionContext.AuthMode | Should Be 'DeviceCode'
    }

    It 'stores the resolved ClientId from an approved environment variable in the active context' {
        $env:ENTRAID_CLIENT_ID = '  env-client  '

        $connection = Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant' -AuthMode Interactive

        $global:PSLibSpoConnectionContext.Connection | Should Be $connection
        $global:PSLibSpoConnectionContext.ClientId | Should Be 'env-client'
    }

    It 'runs quiet by default and emits auxiliary messages only with Verbose' {
        $quietOutput = @(Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant' -ClientId 'client' 4>&1)
        $quietVerboseRecords = @($quietOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] })

        $quietVerboseRecords.Count | Should Be 0
        @($quietOutput | Where-Object { $_ -isnot [System.Management.Automation.VerboseRecord] }).Count | Should Be 1

        Remove-Variable -Name PSLibSpoConnectionContext -Scope Global -ErrorAction SilentlyContinue
        $verboseOutput = @(Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/verbose' -TenantId 'tenant' -ClientId 'client' -Verbose 4>&1)
        $verboseRecords = @($verboseOutput | Where-Object { $_ -is [System.Management.Automation.VerboseRecord] })

        ($verboseRecords.Count -gt 0) | Should Be $true
        (($verboseRecords | ForEach-Object { $_.Message }) -join ' ') | Should BeLike '*Iniciando autenticacion SharePoint*'
    }

    It 'reuses an active valid connection for the same site and ClientId without login' {
        $existingConnection = [pscustomobject]@{ Connected = $true; Name = 'existing' }
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = $existingConnection
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo/'
            TenantId   = 'tenant-existing'
            ClientId   = 'CLIENT'
            AuthMode   = 'Interactive'
        }

        $connection = Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-new' -ClientId 'client' -AuthMode DeviceCode

        $connection | Should Be $existingConnection
        $script:getPnPWebCallCount | Should Be 1
        $script:capturedGetPnPWebParameters.Connection | Should Be $existingConnection
        $script:connectPnPOnlineCallCount | Should Be 0
        $global:PSLibSpoConnectionContext.Connection | Should Be $existingConnection
        $global:PSLibSpoConnectionContext.TenantId | Should Be 'tenant-existing'
    }

    It 'performs login when the active connection validation fails' {
        $existingConnection = [pscustomobject]@{ Connected = $true; Name = 'expired' }
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = $existingConnection
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
            TenantId   = 'tenant-existing'
            ClientId   = 'client'
            AuthMode   = 'Interactive'
        }
        $script:getPnPWebShouldThrow = $true

        $connection = Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-new' -ClientId 'client'

        $script:getPnPWebCallCount | Should Be 1
        $script:connectPnPOnlineCallCount | Should Be 1
        $connection | Should Not Be $existingConnection
        $global:PSLibSpoConnectionContext.Connection | Should Be $connection
        $global:PSLibSpoConnectionContext.TenantId | Should Be 'tenant-new'
    }

    It 'performs login when active context site or ClientId differ' {
        $existingConnection = [pscustomobject]@{ Connected = $true; Name = 'existing' }
        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = $existingConnection
            SiteUrl    = 'https://contoso.sharepoint.com/sites/other'
            TenantId   = 'tenant-existing'
            ClientId   = 'client'
            AuthMode   = 'Interactive'
        }

        $connection = Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-new' -ClientId 'client'

        $script:getPnPWebCallCount | Should Be 0
        $script:connectPnPOnlineCallCount | Should Be 1
        $global:PSLibSpoConnectionContext.Connection | Should Be $connection

        $global:PSLibSpoConnectionContext = [pscustomobject]@{
            Connection = $existingConnection
            SiteUrl    = 'https://contoso.sharepoint.com/sites/demo'
            TenantId   = 'tenant-existing'
            ClientId   = 'other-client'
            AuthMode   = 'Interactive'
        }
        $script:connectPnPOnlineCallCount = 0
        $script:getPnPWebCallCount = 0

        $connection = Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant-new' -ClientId 'client'

        $script:getPnPWebCallCount | Should Be 0
        $script:connectPnPOnlineCallCount | Should Be 1
        $global:PSLibSpoConnectionContext.Connection | Should Be $connection
    }

    It 'replaces the active context with the latest successful connection' {
        $firstConnection = Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/first' -TenantId 'tenant-one' -ClientId 'client-one'
        $secondConnection = Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/second' -TenantId 'tenant-two' -ClientId 'client-two' -AuthMode DeviceCode

        $firstConnection.Connected | Should Be $true
        $global:PSLibSpoConnectionContext.Connection | Should Be $secondConnection
        $global:PSLibSpoConnectionContext.SiteUrl | Should Be 'https://contoso.sharepoint.com/sites/second'
        $global:PSLibSpoConnectionContext.TenantId | Should Be 'tenant-two'
        $global:PSLibSpoConnectionContext.ClientId | Should Be 'client-two'
        $global:PSLibSpoConnectionContext.AuthMode | Should Be 'DeviceCode'
    }

    It 'does not replace an existing active context when authentication fails' {
        $existingContext = [pscustomobject]@{
            Connection = [pscustomobject]@{ Connected = $true; Name = 'existing' }
            SiteUrl    = 'https://contoso.sharepoint.com/sites/existing'
            TenantId   = 'tenant-existing'
            ClientId   = 'client-existing'
            AuthMode   = 'Interactive'
        }
        $global:PSLibSpoConnectionContext = $existingContext

        Remove-Item -Path function:Connect-PnPOnline -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Connect-PnPOnline -ErrorAction SilentlyContinue
        Remove-Item -Path function:Get-PnPWeb -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Get-PnPWeb -ErrorAction SilentlyContinue

        function global:Connect-PnPOnline {
            [CmdletBinding()]
            param(
                [Parameter()]
                [string]$Url,

                [Parameter()]
                [string]$ClientId,

                [Parameter()]
                [switch]$Interactive,

                [Parameter()]
                [switch]$DeviceLogin,

                [Parameter()]
                [string]$Tenant,

                [Parameter()]
                [switch]$ReturnConnection
            )

            throw 'authentication failed'
        }

        function global:Get-PnPWeb {
            [CmdletBinding()]
            param($Connection, $Includes)

            [pscustomobject]@{ Url = 'https://contoso.sharepoint.com/sites/new' }
        }

        try {
            Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/new' -TenantId 'tenant-new' -ClientId 'client-new'
            throw 'Expected exception was not thrown.'
        }
        catch {
            $_.Exception.Message | Should BeLike '*No se pudo completar la autenticación*'
        }

        $global:PSLibSpoConnectionContext | Should Be $existingContext
    }

    It 'keeps the approved cancellation message' {
        Remove-Item -Path function:Connect-PnPOnline -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Connect-PnPOnline -ErrorAction SilentlyContinue
        Remove-Item -Path function:Get-PnPWeb -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Get-PnPWeb -ErrorAction SilentlyContinue

        function global:Connect-PnPOnline {
            [CmdletBinding()]
            param(
                [Parameter()]
                [string]$Url,

                [Parameter()]
                [string]$ClientId,

                [Parameter()]
                [switch]$Interactive,

                [Parameter()]
                [switch]$DeviceLogin,

                [Parameter()]
                [string]$Tenant,

                [Parameter()]
                [switch]$ReturnConnection
            )

            throw [System.OperationCanceledException]::new('A task was canceled by the user')
        }

        try {
            Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant' -ClientId 'client'
            throw 'Expected exception was not thrown.'
        }
        catch {
            $_.Exception.Message | Should Be 'Autenticación cancelada por el usuario. No se continuará con la operación de SharePoint.'
        }
    }

    It 'keeps the approved insufficient permissions message' {
        Remove-Item -Path function:Connect-PnPOnline -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Connect-PnPOnline -ErrorAction SilentlyContinue

        function global:Connect-PnPOnline {
            [CmdletBinding()]
            param(
                [Parameter()]
                [string]$Url,

                [Parameter()]
                [string]$ClientId,

                [Parameter()]
                [switch]$Interactive,

                [Parameter()]
                [switch]$DeviceLogin,

                [Parameter()]
                [string]$Tenant,

                [Parameter()]
                [switch]$ReturnConnection
            )

            throw [System.UnauthorizedAccessException]::new('Access denied. Insufficient privileges.')
        }

        try {
            Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant' -ClientId 'client'
            throw 'Expected exception was not thrown.'
        }
        catch {
            $_.Exception.Message | Should Be 'Autenticación completada, pero la cuenta o la aplicación no tiene permisos suficientes para el sitio u operación solicitada.'
        }
    }

    It 'fails fast when PnP.PowerShell is unavailable' {
        Remove-Item -Path function:Connect-PnPOnline -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Connect-PnPOnline -ErrorAction SilentlyContinue
        $currentPSModulePath = $env:PSModulePath
        Remove-Module PnP.PowerShell -ErrorAction SilentlyContinue

        try {
            $env:PSModulePath = ''
            Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant' -ClientId 'client'
            throw 'Expected exception was not thrown.'
        }
        catch {
            $_.Exception.Message | Should Be 'No se encontró PnP.PowerShell. Instálalo con: Install-Module PnP.PowerShell -Scope CurrentUser'
        }
        finally {
            $env:PSModulePath = $currentPSModulePath
        }
    }
}
