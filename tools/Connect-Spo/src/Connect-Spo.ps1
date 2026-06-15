# ===========================================================================
# Control de Cambios
# v0.4.0 | 2026-06-14 | Implementation Agent | Convierte el script principal en wrapper mínimo del módulo canónico Connect-Spo
# ===========================================================================

Set-StrictMode -Version Latest

$moduleManifestPath = Join-Path $PSScriptRoot '..\..\..\modules\Connect-Spo\Connect-Spo.psd1'
Import-Module $moduleManifestPath -Force -ErrorAction Stop
