# ===========================================================================
# Control de Cambios
# v0.2.0 | 2026-06-14 | Implementation Agent | Pruebas para el wrapper mínimo que carga el módulo canónico Connect-Spo
# ===========================================================================

$scriptPath = Join-Path $PSScriptRoot '..\src\Connect-Spo.ps1'

Describe 'Connect-Spo wrapper' {
    BeforeEach {
        Remove-Item -Path function:Connect-PnPOnline -ErrorAction SilentlyContinue
        $script:connectPnPOnlineInvoked = $false

        function Connect-PnPOnline {
            [CmdletBinding()]
            param()

            $script:connectPnPOnlineInvoked = $true
            [pscustomobject]@{ Connected = $true }
        }
    }

    AfterEach {
        Remove-Item -Path function:Connect-PnPOnline -ErrorAction SilentlyContinue
    }

    It 'loads the module wrapper without invoking authentication' {
        . $scriptPath

        $script:connectPnPOnlineInvoked | Should Be $false
    }

    It 'exposes Connect-Spo after loading the wrapper' {
        . $scriptPath

        $command = Get-Command -Name 'Connect-Spo' -ErrorAction SilentlyContinue
        $command.Name | Should Be 'Connect-Spo'
    }

    It 'does not invoke Connect-PnPOnline while loading the wrapper' {
        . $scriptPath

        $script:connectPnPOnlineInvoked | Should Be $false
    }
}
