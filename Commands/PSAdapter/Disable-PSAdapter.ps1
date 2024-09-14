function Disable-PSAdapter {
    <#
    .SYNOPSIS
        Disables a PSAdapter Module
    .DESCRIPTION
        Disables a module written in .cdxml format.
    .NOTES
        One of the advantages of using .cdxml and .psd1 modules is that they can be cleanly loaded and unloaded from memory.

        This enables you to enable and disable a large number of commands as needed, without loading all of them into memory when a module first loads.
    #>
    param(
    # The name of the adapter to disable.
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('ModuleName','Name')]
    [string[]]
    $AdapterName
    )

    begin {
        $loadedModules = @(Get-Module)
    }

    process {
        if ($AdapterName) {               
            foreach ($name in $AdapterName) {
                foreach ($loadedModule in $loadedModules) {
                    if ($loadedModule.Path -match "$([Regex]::Escape($Name))\.cdxml$") {
                        Remove-Module -ModuleInfo $loadedModule -Force
                        break
                    }
                }
            }
        }
    }
}