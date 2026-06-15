@{
    RootModule = 'Connect-Spo.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'd25d6e6b-1e5c-4d18-a2fa-c30ab114e900'
    Author = 'pslib'
    CompanyName = 'Aucar Ltda'
    Description = 'Autenticación SharePoint Online unificada para tools PowerShell de pslib.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Connect-Spo')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            ExternalModuleDependencies = @('PnP.PowerShell')
        }
    }
}
