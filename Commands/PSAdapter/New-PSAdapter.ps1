function New-PSAdapter {
    <#
    .SYNOPSIS
        Creates a new PowerShell Adapter
    .DESCRIPTION
        Creates a new PowerShell Adapter.

        Adapters allow you to adapt anything into a PowerShell command.
    #>    
    param(
    # The template name, or a command.
    [Parameter(ValueFromPipelineByPropertyName)]
    [ArgumentCompleter({
        param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter) 
        $typeData = Get-TypeData -TypeName "PSAdapter.Template"
        return $typeData.Members.Keys -match "$([Regex]::Escape($wordToComplete))"
    })]
    [PSObject]
    $Template = "DotNetAdapter",
    
    # Any arguments to pass to the template
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('TemplateArguments','TemplateArgs')]
    [PSObject[]]
    $TemplateArgument = @(),

    # Any parameters to pass to the template
    [Parameter(ValueFromPipelineByPropertyName)]
    [Alias('TemplateParameters')]
    [Collections.IDictionary]
    $TemplateParameter = @{},

    # The namespace for the adapter.
    # If this is not provided, it will use the name of the current repository.
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $Namespace,

    # The output path for the adapter.
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $OutputPath
    )

    process {
                
        $foundTemplateCommands = @(
            if ($template -is [Management.Automation.CommandInfo] -or
                $template -is [ScriptBlock]) {
                $Template
            } else {
                $escapedName = [Regex]::Escape("$Template")

                $typeData = Get-TypeData -TypeName "PSAdapter.Template"
                foreach ($foundKey in $typeData.Members.Keys -match "^$escapedName") {
                    if ($typeData.Members[$foundKey].RefeferencedMemberName) {
                        $foundKey = $typeData.Members[$foundKey].RefeferencedMemberName
                    }
    
                    if ($typeData.Members[$foundKey].Script) {
                        $typeData.Members[$foundKey].Script
                    }
                    elseif ($typeData.Members[$foundKey].GetterScript) {
                        $typeData.Members[$foundKey].GetterScript
                    } elseif ($typeData.Members[$foundKey].Value) {
                        $typeData.Members[$foundKey].Value
                    }
                }
    
                $ExecutionContext.SessionState.InvokeCommand.GetCommands('*Template*','Function,Alias', $true) -match 'Adapter'
            }

            
            
        )

        $templateOutput = 
            foreach ($foundTemplateCommand in $foundTemplateCommands) {
                if ($foundTemplateCommand -is [string]) {
                    $foundTemplateCommand
                    continue
                }
                if ($TemplateParameter) {
                    if ($TemplateArgument) {
                        & $foundTemplateCommand @TemplateArgument @TemplateParameter 
                    } else {
                        & $foundTemplateCommand @TemplateParameter
                    }
                }
                elseif ($TemplateArgument) {
                    & $foundTemplateCommand @TemplateArgument
                }
                else {
                    $foundTemplateCommand
                }
            }
        
        
        $templateString = $templateOutput -join [Environment]::NewLine

        if (-not $Namespace) {
            if ($env:GITHUB_REPOSITORY) {
                $Namespace = $env:GITHUB_REPOSITORY -replace '/', '.'
            } else {
                $Namespace = 'PSAdapter'
            }
        }

        $findCurrentNamespace = [Regex]::new("(?<!using\s+)(?<=namespace\s+)(?<Namespace>\S+)")

        $templateResult = 
            if ($templateString -as [xml]) {
                $templateXml -as [xml]
            } else {                
                $templateString -replace $findCurrentNamespace, $Namespace
            }
        
        if ($OutputPath) {
            if ($templateResult -is [xml]) {
                $templateResult.Save($OutputPath)
            } else {
                $templateResult | Out-File -FilePath $OutputPath
            }
            if ($?) {
                Get-Item -Path $outputPath
            }
        } else {
            $templateResult
        }
    }
}
