# ===========================================================================
# Control de Cambios
# v0.1.0 | 2026-06-14 | Implementation Agent | Pruebas del módulo reusable Connect-Spo importable por nombre
# ===========================================================================

$moduleRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..\modules\Connect-Spo')
$manifestPath = Join-Path $moduleRoot 'Connect-Spo.psd1'
$originalPSModulePath = $env:PSModulePath

Describe 'Connect-Spo module' {
    BeforeAll {
        Remove-Module Connect-Spo -ErrorAction SilentlyContinue
        $env:PSModulePath = "$((Resolve-Path (Join-Path $PSScriptRoot '..\..\..\modules')).Path)$([IO.Path]::PathSeparator)$originalPSModulePath"
        Import-Module Connect-Spo -Force -ErrorAction Stop
    }

    AfterAll {
        Remove-Module Connect-Spo -ErrorAction SilentlyContinue
        $env:PSModulePath = $originalPSModulePath
    }

    BeforeEach {
        Remove-Item -Path function:Connect-PnPOnline -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Connect-PnPOnline -ErrorAction SilentlyContinue
        $script:capturedConnectParameters = $null

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

            $script:capturedConnectParameters = @{}
            foreach ($parameterName in $PSBoundParameters.Keys) {
                $script:capturedConnectParameters[$parameterName] = $PSBoundParameters[$parameterName]
            }

            [pscustomobject]@{ Connected = $true }
        }
    }

    AfterEach {
        Remove-Item -Path function:Connect-PnPOnline -ErrorAction SilentlyContinue
        Remove-Item -Path function:global:Connect-PnPOnline -ErrorAction SilentlyContinue
        Remove-Item -Path env:ENTRAID_CLIENT_ID -ErrorAction SilentlyContinue
        Remove-Item -Path env:ENTRAID_APP_ID -ErrorAction SilentlyContinue
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
            'ConvertTo-SharePointUnifiedAuthError'
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
    }

    It 'invokes Connect-PnPOnline with DeviceCode parameters' {
        $connection = Connect-Spo -SiteUrl 'https://contoso.sharepoint.com/sites/demo' -TenantId 'tenant.onmicrosoft.com' -ClientId 'client' -AuthMode DeviceCode

        $connection.Connected | Should Be $true
        $script:capturedConnectParameters.Url | Should Be 'https://contoso.sharepoint.com/sites/demo'
        $script:capturedConnectParameters.ClientId | Should Be 'client'
        $script:capturedConnectParameters.DeviceLogin | Should Be $true
        $script:capturedConnectParameters.Tenant | Should Be 'tenant.onmicrosoft.com'
        $script:capturedConnectParameters.ReturnConnection | Should Be $true
    }

    It 'keeps the approved cancellation message' {
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
