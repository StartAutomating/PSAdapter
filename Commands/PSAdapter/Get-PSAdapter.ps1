function Get-PSAdapter {
    param(
    
    )

    begin {
        $psAdapterTypes = 
            foreach ($loadedAssembly in [AppDomain]::CurrentDomain.GetAssemblies()) {
                try {
                    foreach ($loadedType in $loadedAssembly.GetTypes()) {
                        if ($loadedType.BaseType.Name -match 'CmdletAdapter') {                            
                            $loadedType
                        }
                    }
                } catch {
                    
                }
            }
        $psAdaptedModules = 
            foreach ($loadedModule in Get-Module) {
                if ($loadedModule.ModuleType -eq 'CIM') {
                    $loadedModule
                } elseif ($loadedModule.NestedModules.ModuleType -match 'CIM') {
                    foreach ($nestedModule in $loadedModule.NestedModules) {
                        if ($nestedModule.ModuleType -eq 'CIM') {
                            $nestedModule
                        }
                    }
                }
            }
            
        $psAdaptersLocal = (Get-Item $pwd).EnumerateFiles("*.*", 'AllDirectories') -match '\.cdxml$'
            
    }

    process {
        foreach ($adapterTypeOrModule in @(            
            $psAdapterTypes
            $psAdaptedModules
            $psAdaptersLocal
        )) {
            if ($adapterTypeOrModule.pstypenames -notcontains 'PSAdapter') {
                $adapterTypeOrModule.pstypenames.insert(0, 'PSAdapter')
            }
            $adapterTypeOrModule
        }
    }
}