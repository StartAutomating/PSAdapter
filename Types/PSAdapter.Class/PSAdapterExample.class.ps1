class PSAdapterExampleQueryBuilder : Microsoft.PowerShell.Cmdletization.QueryBuilder {
    [Collections.IDictionary] $QueryOption = [Ordered]@{}
    [Collections.Generic.List[PSObject]] $QueryFilterList = [Collections.Generic.List[PSObject]]::new()
    [PSAdapterExample] $Adapter
    PSAdapterExampleQueryBuilder([PSAdapterExample]$adapter) {
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
}
class PSAdapterExample : Microsoft.PowerShell.Cmdletization.CmdletAdapter[object] {
    [Microsoft.PowerShell.Cmdletization.QueryBuilder] GetQueryBuilder() {
        $this.Cmdlet.WriteVerbose("Getting query builder")
        $queryBuilder = [PSAdapterExampleQueryBuilder]::new($this)        
        return $queryBuilder
    }
    BeginProcessing() {
        $this.Cmdlet.WriteVerbose("Beginning processing")
    }
    StopProcessing() {
        $this.Cmdlet.WriteVerbose("Stopping processing")
    }    
    ProcessRecord([Microsoft.PowerShell.Cmdletization.QueryBuilder]$QueryBuilder) {
        $this.Cmdlet.WriteVerbose("Processing query builder")
        $this.Cmdlet.WriteObject($QueryBuilder)        
    }
    ProcessRecord([Microsoft.PowerShell.Cmdletization.QueryBuilder]$QueryBuilder, 
        [Microsoft.PowerShell.Cmdletization.MethodInvocationInfo] $MethodInvocationInfo, 
        [bool]$PassThru) {
        $this.Cmdlet.WriteVerbose("Processing query and method")        
        $this.Cmdlet.WriteObject([PSCustomObject]([Ordered]@{} + $PSBoundParameters))        
    }
    ProcessRecord([Microsoft.PowerShell.Cmdletization.MethodInvocationInfo] $methodInvocationInfo) {
        $typeData = Get-TypeData -TypeName $this.ClassName
        $myMember = $typeData.Members[$methodInvocationInfo.MethodName]
        $this.Cmdlet.WriteObject($myMember)
    }
    ProcessRecord([object]$Instance, 
        [Microsoft.PowerShell.Cmdletization.MethodInvocationInfo] $MethodInvocationInfo, 
        [bool]$PassThru
    ) {
        $this.Cmdlet.WriteVerbose("Processing instance and method")
        $this.Cmdlet.WriteObject([PSCustomObject]([Ordered]@{} + $PSBoundParameters))
    }
    EndProcessing() {
        $this.Cmdlet.WriteVerbose("Ending processing")
    }
}
