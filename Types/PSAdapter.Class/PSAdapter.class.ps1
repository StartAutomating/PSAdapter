<#
.SYNOPSIS
    This contains the PSAdapter class.
.DESCRIPTION
    This contains the definition of the PSAdapter class and other classes used to build a CmdletAdapter.
#>


<#
.SYNOPSIS
    The Query Builder for the PSAdapter class.
.DESCRIPTION
    The Query Builder for the PSAdapter class.

    Any CmdletAdapter that wants to work with instances needs to implement a QueryBuilder class.
    
    The QueryBuilder class is responsible for building the query that will be used to filter the instances.    
#> 
class PSAdapterQueryBuilder : Microsoft.PowerShell.Cmdletization.QueryBuilder {
    # The query options.
    [Collections.IDictionary] $QueryOption = [Ordered]@{}
    # The query filter list.
    [Collections.Generic.List[PSObject]] $QueryFilterList = [Collections.Generic.List[PSObject]]::new()
    # The adapter.
    [PSAdapter] $Adapter
    # PSAdapterQueryBuilder constructor.
    PSAdapterQueryBuilder(
        # The adapter.
        [PSAdapter]$adapter
    ) {        
        $this.Adapter = $adapter
    }
    AddQueryOption([string] $name, [object] $value) {
        $this.QueryOption[$name] = $value
        $this.Adapter.Cmdlet.WriteVerbose("Added query option '$name' with value '$value'")
    }
    ExcludeByProperty([string] $propertyName, [Collections.IEnumerable]$ExcludePropertyValue, [object] $propertyValue, [Microsoft.PowerShell.Cmdletization.BehaviorOnNoMatch] $behaviorOnNoMatch) {
        $This.QueryFilterList.Add([PSCustomObject]([Ordered]@{
            FilterType = "ExcludeByProperty"
        } + $PSBoundParameters))
        $this.Adapter.Cmdlet.WriteVerbose("Excluded by property '$propertyName' with value '$propertyValue'")
    }
    FilterByAssociation([object]$AssociatedInstance, [string]$AssociationName, [string]$SourceRole, [string]$ResultRole, [Microsoft.PowerShell.Cmdletization.BehaviorOnNoMatch]$behaviorOnNoMatch) {
        $this.Adapter.Cmdlet.WriteVerbose("Filtered by association '$AssociationName' with associated instance '$AssociatedInstance'")
    }
    FilterByProperty([string] $propertyName, [Collections.IEnumerable]$AllowedPropertyValue, [bool] $wildcardsEnabled, [Microsoft.PowerShell.Cmdletization.BehaviorOnNoMatch] $behaviorOnNoMatch) {
        $This.QueryFilterList.Add([PSCustomObject]([Ordered]@{
            FilterType = "FilterByProperty"
        } + $PSBoundParameters))
        $this.Adapter.Cmdlet.WriteVerbose("Filtered property value '$propertyName' with value '$AllowedPropertyValue'")
    }
    FilterByMinPropertyValue([string]$propertyName, [object]$MinValue, [Microsoft.PowerShell.Cmdletization.BehaviorOnNoMatch] $behaviorOnNoMatch) {
        $This.QueryFilterList.Add([PSCustomObject]([Ordered]@{
            FilterType = "FilterByMinPropertyValue"
        } + $PSBoundParameters))
        $this.Adapter.Cmdlet.WriteVerbose("Filtered by MinValue value '$propertyName' with value '$MinValue'")
    }
    FilterByMaxPropertyValue([string]$propertyName, [object]$MaxValue, [Microsoft.PowerShell.Cmdletization.BehaviorOnNoMatch] $behaviorOnNoMatch) {
        $This.QueryFilterList.Add([PSCustomObject]([Ordered]@{
            FilterType = "FilterByMaxPropertyValue"
        } + $PSBoundParameters))
        $this.Adapter.Cmdlet.WriteVerbose("Filtered by MaxValue '$propertyName' with value '$MaxValue'")
    }
    [bool] MatchesFilters([object]$Instance) {
        $QueryBuilder = $this
        :nextQueryFilter foreach ($queryFilterItem in $QueryBuilder.QueryFilterList) {            
            $InstancePropertyValue = $Instance.$($queryFilterItem.PropertyName)
            switch ($queryFilterItem.FilterType) {
                FilterByProperty {
                    if ($queryFilterItem.WildcardsEnabled) {
                        foreach ($wildcard in $queryFilterItem.AllowedPropertyValue) {
                            if ($InstancePropertyValue -like $wildcard) {                                
                                continue nextQueryFilter
                            }
                        }
                        return $false
                    } else {
                        if ($InstancePropertyValue -notin $queryFilterItem.AllowedPropertyValue) {
                            if ($queryFilterItem.BehaviorOnNoMatch -eq 'ReportErrors') {
                                $this.Adapter.Cmdlet.WriteError("Property value $($queryFilterItem.PropertyName) is not in the allowed list")                             
                            }
                            return $false
                        }
                    }
                    
                    
                }
                FilterByMinPropertyValue {
                    if ($InstancePropertyValue -lt $queryFilterItem.MinValue) {
                        if ($queryFilterItem.BehaviorOnNoMatch -eq 'ReportErrors') {
                            $this.Adapter.Cmdlet.WriteError("Property value $($queryFilterItem.PropertyName) is less than the minimum value")                                    
                        }
                        return $false
                    }
                }
                FilterByMaxPropertyValue {
                    if ($InstancePropertyValue -gt $queryFilterItem.MaxValue) {
                        if ($queryFilterItem.BehaviorOnNoMatch -eq 'ReportErrors') {
                            $this.Adapter.Cmdlet.WriteError("Property value $($queryFilterItem.PropertyName) is greater than the maximum value")                                    
                        }
                        return $false
                    }
                }
                ExcludeByProperty {
                    if ($queryFilterItem.WildcardsEnabled) {
                        foreach ($wildcard in $queryFilterItem.ExcludePropertyValue) {
                            if ($InstancePropertyValue -like $wildcard) {                                
                                return $false
                            }
                        }
                    } else {
                        if ($InstancePropertyValue -in $queryFilterItem.ExcludePropertyValue) {
                            if ($queryFilterItem.BehaviorOnNoMatch -eq 'ReportErrors') {
                                $this.Adapter.Cmdlet.WriteError("Property value $($queryFilterItem.PropertyName) is in the exclude list")                                    
                            }
                            return $false
                        }
                    }                    
                }
            }            
        }
        return $true
    }
}


class PSAdapterBase : Microsoft.PowerShell.Cmdletization.CmdletAdapter[PSObject]
{
    [Microsoft.PowerShell.Cmdletization.QueryBuilder] GetQueryBuilder() {
        $this.Cmdlet.WriteVerbose("Getting query builder")
        $queryBuilder = [PSAdapterQueryBuilder]::new($this)        
        return $queryBuilder
    }
    [object] $ResolvedClass = $null
    [Collections.Generic.List[Threading.Tasks.Task]] $Tasks = [Collections.Generic.List[Threading.Tasks.Task]]::new()
    static [Ordered] $ResolvedClasses = [Ordered]@{}
    ResolveClass() {
        if ($This::ResolvedClasses[$this.ClassName]) {
            $this.ResolvedClass = $This::ResolvedClasses[$this.ClassName]
            return
        }
        if ($this.ClassName -as [type]) {
            $this.ResolvedClass = $this.ClassName -as [type]
        }
        elseif ( $(
            $typeExists = [type]::GetType($this.ClassName, $false, $true)
            $typeExists
        )) {
            $this.ResolvedClass = $typeExists
        }
        elseif ($(
            $foundCommand = $this.Cmdlet.SessionState.InvokeCommand.GetCommand($this.ClassName, 'Cmdlet,Function,Alias')
            $foundCommand
        )) {
            $this.ResolvedClass = $foundCommand
        } elseif ($(
            $foundVariable = $this.Cmdlet.SessionState.PSVariable.Get($this.ClassName)
            $foundVariable
        )) {
            $this.ResolvedClass = $foundVariable.Value
        }
        if ($this.ResolvedClass) {
            $This::ResolvedClasses[$this.ClassName] = $this.ResolvedClass
        }
        $this.Cmdlet.WriteVerbose("Class resolved to $($this.ResolvedClass)")
    }

    [object] GetDynamicParameters() {        
        
        $this.Cmdlet.WriteVerbose("Getting dynamic parameters")
        [Management.Automation.RuntimeDefinedParameterDictionary] $runtimeParameters = 
            [Management.Automation.RuntimeDefinedParameterDictionary]::new()
        $this.ResolveClass()
        if ($this.ResolvedClass) {
            if ($this.ResolvedClass -is [Management.Automation.CommandInfo]) {
                foreach ($parameter in $this.ResolvedClass.Parameters.Values) {
                    if ($this.Cmdlet.Parameters.ContainsKey($parameter.Name)) {
                        continue
                    }
                    [Management.Automation.RuntimeDefinedParameter]::new($parameter.Name, $parameter.ParameterType, $parameter.Attributes)                    
                }
                
            }
        }
        return $null
    }
    
    [object[]] GetInstances() {
        return @(
            $hashCodeList = [Collections.Generic.List[int]]::new()
            foreach ($var in Get-Variable) {
                $varHashCode = 
                    if ($var.Value.GetHashCode) { $var.Value.GetHashCode() }
                    else { continue }                
                if ($hashCodeList.Contains($varHashCode)) { continue }
                if ($this.ResolvedClass -is [type] -and 
                    $var.Value -is $this.ResolvedClass) {
                    $var.Value
                    $hashCodeList.Add($varHashCode)
                }
                elseif ($var.pstypenames -match $(
                    if ($this.ClassName -match '^/' -and $this.ClassName -match '/$') {
                        [Regex]::new($this.ClassName -replace '^/' -replace '/$', 'IgnoreCase,IgnorePatternWhitespace','00:00:01')
                    } else {
                        [Regex]::Escape($this.ClassName)
                    }                    
                )) {
                    $var.Value
                }
            }
        )        
    }
    [psobject] GetMethodSplat([Microsoft.PowerShell.Cmdletization.MethodInvocationInfo] $MethodInvocationInfo) {
        $methodName = $MethodInvocationInfo.MethodName
        $myInvocationNamePattern = "^$([Regex]::Escape($this.Cmdlet.MyInvocation.InvocationName))"
        $myScriptPrivateDataKeys = $this.PrivateData.Keys -match $myInvocationNamePattern -match "[\.\:]{1,2}$([Regex]::Escape($methodName))"
        $methodScriptBlock = if ($myScriptPrivateDataKeys) {
            [ScriptBlock]::Create(($this.PrivateData[$myScriptPrivateDataKeys] -join [Environment]::NewLine))
        } elseif ($MethodName -match '^\s{0,}\{' -and $methodName -match '\}\s{0,}$') {
            $methodName = $methodName -replace '^\s{0,}\{' -replace '\}\s{0,}$'
            [scriptblock]::Create($methodName)
        }
        if (-not $methodScriptBlock) {            
            return $null
        }
            
        $methodScriptParameters = 
            $methodScriptBlock.Ast.FindAll({
                param($ast) 
                $ast -is [Management.Automation.Language.ParameterAst] -or 
                ($ast -is [System.Management.Automation.Language.AttributeAst] -and $ast.TypeName.Name -eq 'Alias')
            }, $false)
        $methodScriptParameterNames = 
            @(foreach ($ast in $methodScriptParameters) {
                if ($ast -is [Management.Automation.Language.ParameterAst]) {
                    $ast.Name.VariablePath.UserPath
                } else {
                    $ast.PostionalArguments.Value
                }
            })
        $methodSplat = [Ordered]@{}
        foreach ($parameter in $MethodInvocationInfo.Parameters) {
            if ($methodScriptParameterNames -contains $parameter.Name -and $null -ne $parameter.Value) {
                $methodSplat[$parameter.Name] = $parameter.Value
            }
        }
        $methodSplat.psobject.properties.add([psnoteproperty]::new('Command', $methodScriptBlock))
        return $methodSplat
    
    }
    BeginProcessing() {
        $this.Cmdlet.WriteVerbose("Beginning processing") 
    }
    StopProcessing() {
        $this.Cmdlet.WriteVerbose("Stopping processing")
    }    
    ProcessRecord([Microsoft.PowerShell.Cmdletization.QueryBuilder]$QueryBuilder) {
        $this.Cmdlet.WriteVerbose("Processing query builder")
        foreach ($instance in $this.GetInstances()) {
            if ($QueryBuilder.MatchesFilters($instance)) {
                $this.Cmdlet.WriteObject($instance)
            }
        }
        
    }
    ProcessRecord([Microsoft.PowerShell.Cmdletization.QueryBuilder]$QueryBuilder, 
        [Microsoft.PowerShell.Cmdletization.MethodInvocationInfo] $MethodInvocationInfo, 
        [bool]$PassThru) {
        $this.Cmdlet.WriteVerbose("Processing query and method")
        foreach ($instance in $this.GetInstances()) {
            if ($QueryBuilder.MatchesFilters($instance)) {
                $this.ProcessRecord($instance, $MethodInvocationInfo, $PassThru)
            }
        }        
    }
    ProcessRecord(        
        [psobject]$Instance, 
        [Microsoft.PowerShell.Cmdletization.MethodInvocationInfo]$MethodInvocationInfo, 
        [bool]$PassThru
    ) {
        $methodSplat = $this.GetMethodSplat($MethodInvocationInfo)
        $instanceMember = $instance.psobject.Members[$MethodInvocationInfo.MethodName]
        $methodOutput = 
            if ($methodSplat) {
                $this.Cmdlet.SessionState.PSVariable.Set('this', $this)
                $this.Cmdlet.SessionState.PSVariable.Set('_', $Instance)
                . $methodSplat.Command @methodSplat
            }
            elseif ($instanceMember) {
                
                if ($instanceMember -isnot [Management.Automation.PSEvent]) {
                    $invokeArgs = @(foreach ($methodParameter in $MethodInvocationInfo.Parameters) {
                        $methodParameter.Value
                    })
                    $instanceMember.Invoke($invokeArgs)
                } else {
                    $registerObjectEvent = $this.Cmdlet.SessionState.InvokeCommand.GetCommand('Register-ObjectEvent','Cmdlet')
                    $registerObjectEventSplat = [Ordered]@{} + $this.Cmdlet.MyInvocation.BoundParameters
                    foreach ($parameterKey in @($registerObjectEventSplat.Keys)) {
                        if (-not $registerObjectEvent.Parameters[$parameterKey]) {
                            $registerObjectEventSplat.Remove($parameterKey)
                        }                    
                    }
                    Register-ObjectEvent @registerObjectEventSplat
                }            
            }
        if ($methodOutput -is [Threading.Tasks.Task]) {
            $this.Tasks.Add($methodOutput)
        }
        if ($PassThru) {
            if ($methodOutput) {
                if ($methodOutput -isnot [Threading.Tasks.Task]) {                
                    $this.Cmdlet.WriteObject($methodOutput)
                }                
            } else {
                $this.Cmdlet.WriteObject($instance)
            }            
        }
    }
    ProcessRecord([Microsoft.PowerShell.Cmdletization.MethodInvocationInfo] $methodInvocationInfo) {
        $this.Cmdlet.WriteVerbose("Processing static method invocation: $($methodInvocationInfo.MethodName)")
        $methodSplat = $this.GetMethodSplat($MethodInvocationInfo)
        if ($methodSplat) {
            $methodCommandOutput = . $methodSplat.Command @methodSplat *>&1
            
            $this.Cmdlet.WriteObject($methodCommandOutput, $true)
            
            return
        }
        if ($this.ResolvedClass -is [type]) {
            $myMember = $this.ResolvedClass::($methodInvocationInfo.MethodName)            
            $myMemberResult = 
                if ($myMember -is [Management.Automation.PSMethod]) {
                    $invokeArgs = @(foreach ($methodParameter in $MethodInvocationInfo.Parameters) {
                        $methodParameter.Value
                    })
                    $myMember.Invoke($invokeArgs)
                } elseif ($null -ne $myMember) {
                    $myMember
                }
            
            $this.Cmdlet.WriteObject($myMemberResult)
        } else {
            $typeData = Get-TypeData -TypeName $this.ClassName
            if (-not $typeData) { return }
        }
    }    
    EndProcessing() {
        $this.Cmdlet.WriteVerbose("Ending processing")
        if ($this.Tasks.Count) {
            foreach ($task in $this.Tasks) {
                $this.Cmdlet.WriteObject($task.Result)
            }
        }        
    }    
}

class PSAdapter : PSAdapterBase, Management.Automation.IDynamicParameters {}
