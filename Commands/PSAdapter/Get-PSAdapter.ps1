function Get-PSAdapter {
    <#
    .SYNOPSIS
        Gets PSAdapter types and modules.
    .DESCRIPTION
        Gets PSAdapter CmdletAdapter types and the modules that use them.

        CmdletAdapters can be used to create custom cmdlets that adapt to different data sources.        
    .EXAMPLE
        Get-PSAdapter
    .EXAMPLE
        Get-PSAdapter -PSAdapterType Type
    .EXAMPLE
        Get-PSAdapter -PSAdapterType Module
    .EXAMPLE
        Get-PSAdapter -PSAdapterType File
    #>
    [CmdletBinding(PositionalBinding=$false)]
    param(    
    # The type of PSAdapter to get.  Can be file, module, or type.
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateSet("File","Module","Type")]
    [string[]]
    $PSAdapterType = @('File','Module','Type')
    )

    begin {
        $psAdapterTypes =
            if ($PSAdapterType -contains 'Type') {
                @(foreach ($loadedAssembly in [AppDomain]::CurrentDomain.GetAssemblies()) {
                    try {
                        :nextType foreach ($loadedType in $loadedAssembly.GetTypes()) {
                            if (-not $loadedType.IsPublic) { continue }
                            if ($loadedType.IsInterface -or $loadedType.IsAbstract) { continue }
                            $processRecordExists = $loadedType.GetMember("ProcessRecord")
                            if ($processRecordExists -and $processRecordExists -join ';' -match 'Cmdletization') {
                                $loadedType
                            }
                        }
                    } catch {
                        
                    }
                })
            } 
            
        $psAdaptedModules = 
            if ($PSAdapterType -contains 'Module') {
                @(foreach ($loadedModule in Get-Module) {
                    if ($loadedModule.ModuleType -eq 'CIM') {
                        $loadedModule
                    } elseif ($loadedModule.NestedModules.ModuleType -match 'CIM') {
                        foreach ($nestedModule in $loadedModule.NestedModules) {
                            if ($nestedModule.ModuleType -eq 'CIM') {
                                $nestedModule
                            }
                        }
                    }
                })
            }                
            
            
        $psAdaptersLocal = 
            if ($PSAdapterType -contains 'File') {
                (Get-Item $pwd).EnumerateFiles("*.*", 'AllDirectories') -match '\.cdxml$'
            }
            
    }

    process {
        foreach ($adapterTypeOrModule in @(            
            $psAdapterTypes
            $psAdaptedModules
            $psAdaptersLocal
        )) {
            if ($null -eq $adapterTypeOrModule) { continue }
            if ($adapterTypeOrModule.pstypenames -notcontains 'PSAdapter') {
                $adapterTypeOrModule.pstypenames.insert(0, 'PSAdapter')
            }
            $adapterTypeOrModule
        }
    }
}