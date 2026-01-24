function Enable-PSAdapter {
    <#
    .SYNOPSIS
        Enables a PSAdapter Module
    .DESCRIPTION
        Enables a module written in .cdxml format.
    .NOTES
        One of the advantages of using .cdxml and .psd1 modules is that they can be cleanly loaded and unloaded from memory.

        This enables you to enable and disable a large number of commands as needed, without loading all of them into memory when a module first loads.
    #>
    param(
    # The name of the adapter to enable.
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('ModuleName','Name')]
    [string[]]
    $AdapterName,

    # If set, will output the enabled module.
    [switch]
    $PassThru
    )

    begin {
        $knownAdapters = @(foreach ($knownAdapter in Get-PSAdapter) {
            if ($knownAdapter.PSAdapterType -eq 'File') {
                $knownAdapter
            }
        }) 
    }

    process {
        if ($AdapterName) {               
            foreach ($name in $AdapterName) {
                foreach ($foundAdapter in $knownAdapters -match "$([Regex]::Escape($Name))\.cdxml$") {
                    Import-Module $foundAdapter.Fullname -Force -PassThru -Global
                }
            }
        }
    }
}