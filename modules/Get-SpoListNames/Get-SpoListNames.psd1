@{
    RootModule = 'Get-SpoListNames.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'c55bbf58-b012-4b3d-8e6b-5c2cf70fc5d7'
    Author = 'pslib'
    CompanyName = 'Aucar Ltda'
    Copyright = '(c) 2026 Aucar Ltda. All rights reserved.'
    Description = 'Modulo PowerShell no compilado para listar nombres internos y visibles de listas no documentales en SharePoint Online.'
    PowerShellVersion = '7.4'
    RequiredModules = @('Connect-Spo')
    FunctionsToExport = @('Get-SpoListNames')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('SharePoint', 'PnP.PowerShell', 'Lists')
            ExternalModuleDependencies = @('Connect-Spo', 'PnP.PowerShell')
        }
    }
}

