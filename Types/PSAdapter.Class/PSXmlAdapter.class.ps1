class PSXmlAdapterQueryBuilder : Microsoft.PowerShell.Cmdletization.QueryBuilder {
    [Collections.IDictionary] $QueryOption = [Ordered]@{}
    [Collections.Generic.List[PSObject]] $QueryFilterList = [Collections.Generic.List[PSObject]]::new()
    [PSXmlAdapter] $Adapter
    PSXmlAdapterQueryBuilder([PSXmlAdapter]$adapter) {
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
    [bool] MatchesFilters([object]$Instance, [Microsoft.PowerShell.Cmdletization.QueryBuilder]$QueryBuilder) {
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
class PSXmlAdapter : Microsoft.PowerShell.Cmdletization.CmdletAdapter[object] {    
    [Microsoft.PowerShell.Cmdletization.QueryBuilder] GetQueryBuilder() {
        $this.Cmdlet.WriteVerbose("Getting query builder")
        $queryBuilder = [PSXmlAdapterQueryBuilder]::new($this)        
        return $queryBuilder
    }
    [string[]] $myInvocationPrivateDataKeys
    
    BeginProcessing() {
        $myNamePattern = [Regex]::Escape($this.Cmdlet.MyInvocation.InvocationName)
        $this.myInvocationPrivateDataKeys = $this.PrivateData.Keys -match "^$myNamePattern"
        if ($this.myInvocationPrivateDataKeys) {
            $this.Cmdlet.WriteVerbose("Found private data keys: $($this.myInvocationPrivateDataKeys -join ', ')")
        }
        $this.Cmdlet.WriteVerbose("Beginning processing")
    }
    StopProcessing() {
        $this.Cmdlet.WriteVerbose("Stopping processing")
    }

    [Ordered] SelectXmlSplatter() {
        $pathKeys = $this.MyInvocationPrivateDataKeys -match '(?<!x)Path$'
        $xPathKey = @($this.MyInvocationPrivateDataKeys -match 'XPath$')[0]
        $myNamespaceKey = $this.MyInvocationPrivateDataKeys -match 'Namespace$'
        $selectXmlSplat = [ordered]@{}
        
        if ($myNamespaceKey) {
            $myNamespaceInfo = $this.PrivateData[$myNamespaceKey]
            try {
                if ($myNamespaceInfo -match '^\s{0,}@{') {
                    $dataBlock = [ScriptBlock]::Create("data {$myNamespaceInfo}")
                    if ($dataBlock.Ast.EndBlock.Statements.Count -eq 1 -and 
                        $dataBlock.Ast.EndBlock.Statements[0].PipelineElements.Count -eq 1 -and 
                        $dataBlock.Ast.EndBlock.Statements[0].PipelineElements[0].Expression -is [Management.Automation.Language.HashTableAst]) {
                        $selectXmlSplat.Namespace = $dataBlock.Invoke()
                    }
                } elseif ($myNamespaceInfo -match '^\s{0,}\{') {
                    $selectXmlSplat.Namespace = $myNamespaceInfo | ConvertFrom-Json -AsHashtable                    
                }
            } catch {
                Write-Debug "Failed to parse namespace info: $myNamespaceInfo"

            }        
        }
        elseif ($this.ClassName -match '.+?[\p{P}=].+?http') {
            $selectXmlSplat.Namespace = @{}
            foreach ($section in $this.ClassName -split ';') {
                $prefix, $xmlns = $section -split '\p{P}', 2
                $selectXmlSplat.Namespace[$prefix] = $xmlns -replace '[''"]'
            }
        }

        if (-not $pathKeys) {
            $this.Cmdlet.WriteVerbose("No path keys found, defaulting to '*.xml'")
            $pathKeys = "$($this.Cmdlet.MyInvocation.InvocationName)_Path"
            $this.PrivateData[$pathKeys] = '*.xml'
        }
        if (-not $xPathKey -and $pathKeys) {
            $this.Cmdlet.WriteVerbose("No XPath key found, defaulting to '/'")
            $xPathKey = "$($this.Cmdlet.MyInvocation.InvocationName)_XPath"
            $this.PrivateData[$xPathKey] = '/'
        }
        if ($pathKeys -and $xPathKey) {
            $selectXmlSplat.Path = $this.PrivateData[$pathKeys]
            $selectXmlSplat.XPath = $this.PrivateData[$xPathKey]        
            return $selectXmlSplat
        } else {
            return @{}
        }        
    }

    [PSObject] NewXmlElement([string]$ElementName, [Collections.IDictionary]$Dictionary) {
        $invocationName = $this.Cmdlet.MyInvocation.InvocationName
        $escapedInvocationName = '^' + ([Regex]::Escape($invocationName)) + '-'
        if ($script:debugPreference -eq 'Continue') {
            Write-Debug "Making Markup Element: $elementName"
        }
        $children = @(foreach ($parameterName in @($Dictionary.Keys)) {
            $myParameterPrivateData = 
                $this.PrivateData.Keys -match (
                    [Regex]::Escape($parameterName)
                ) -match $escapedInvocationName
            if ($script:debugPreference -eq 'Continue' -and $myParameterPrivateData) {
                Write-Debug "ParameterName: '$parameterName' has private data keys: $($myParameterPrivateData) "                            
            }
            if ($dictionary[$parameterName] -match '^\s{0,}\S+') {
                foreach ($elementNameKey in $myParameterPrivateData -match 'ElementName$') {
                    $elementNameValue = $this.PrivateData[$elementNameKey]
                    if ($elementNameValue -eq '.') {
                        [Security.SecurityElement]::Escape($dictionary[$parameterName])
                        $dictionary.Remove($parameterName)
                        continue
                    }
                    $childElementXml = foreach ($childElement in $dictionary[$parameterName]) {
                        $(
                            if ($childElement -is [switch] -and $childElement) {
                                "<$elementNameValue />"
                            } else {
                                "<$elementNameValue>" + 
                                    [Security.SecurityElement]::Escape($childElement) + 
                                "</$elementNameValue>"
                            }
                        ) -as [xml]
                    }                                
                    
                    if ($childElementXml) {
                        $childElementXml
                        $dictionary.Remove($parameterName)
                    }
                }
            }                        
            if ($dictionary[$parameterName] -is [xml] -or $dictionary[$parameterName] -is [xml[]]) {
                $dictionary[$parameterName]
                $dictionary.Remove($parameterName)
            } elseif (($dictionary[$parameterName] -as [xml[]])) {
                ($dictionary[$parameterName] -as [xml[]])
                $dictionary.Remove($parameterName)
            }            
        })
        $markupText = @(
        "<$ElementName"
            $elementAttributes = @(
                foreach ($keyValuePair in $dictionary.GetEnumerator()) {
                    $key = $keyValuePair.Key
                    $value = $keyValuePair.Value
                    if ($value -is [bool]) {
                        $value = $value.ToString().ToLower()
                    }
                    [Web.HttpUtility]::HtmlAttributeEncode($key) + '="' + [Web.HttpUtility]::HtmlAttributeEncode($Value) + '"'
                }
                $myXmlNamespaces = $this.PrivateData.Keys -match 'Namespace$' -match $escapedInvocationName
                if ($myXmlNamespaces) {
                    $xNamespaces = @($this.ClassName -split ';')
                    for ($xNamespaceIndex =0; $xNamespaceIndex -lt $xNamespaces.Length; $xNamespaceIndex++) {
                        $prefix, $xmlns = $xNamespaces[$xNamespaceIndex] -split '[\p{P}=]+', 2
                        if ($xNamespaceIndex -eq 0) {                            
                            "xmlns=`"$xmlns`""
                        } else {
                            "xmlns:$prefix=`"$xmlns`""
                        }
                    }
                }
            )
            if ($elementAttributes) {
                ' ' + ($elementAttributes -join ' ')
            }
        if ($children) {
            '>'
            Write-Verbose "Adding $($children.Count) children:"
            foreach ($child in $children) {
                if ($child.OuterXml) {
                    $child.OuterXml
                } else {
                    $child
                }
            }
            "</$ElementName>"
        } else {
            '/>'
        }
        ) -join ' '
        if ($markupText -as [xml]) {
            return $markupText -as [xml]
        } else {
            return $markupText
        }
    }

    
        
    ProcessRecord([Microsoft.PowerShell.Cmdletization.QueryBuilder]$QueryBuilder) {
        $selectXmlSplat = $this.SelectXmlSplatter()
        $this.Cmdlet.WriteVerbose("Processing query builder")
        if ($selectXmlSplat) {                        
            :nextNode foreach ($node in Select-Xml @selectXmlSplat *>&1) {                
                if ($node.GetType -and $node.GetType().Name -match '\.(?<StreamType>.+?)Record$') {
                    $this."Write$($matches.StreamType)"($node)
                }
                elseif ($QueryBuilder.MatchesFilters($node.Node, $QueryBuilder)) {
                    $this.Cmdlet.WriteObject($node)
                }                
            }
        }        
    }
    ProcessRecord([Microsoft.PowerShell.Cmdletization.QueryBuilder]$QueryBuilder, 
        [Microsoft.PowerShell.Cmdletization.MethodInvocationInfo] $MethodInvocationInfo, 
        [bool]$PassThru) {
        $this.Cmdlet.WriteVerbose("Processing query and method")
        $selectXmlSplat = $this.SelectXmlSplatter()    
        if ($selectXmlSplat) {
            :nextNode foreach ($node in Select-Xml @selectXmlSplat) {
                if ($node.GetType -and $node.GetType().Name -match '\.(?<StreamType>.+?)Record$') {
                    $this."Write$($matches.StreamType)"($node)
                }
                elseif ($queryBuilder.MatchesFilters($node.Node, $QueryBuilder)) {
                    ProcessRecord($node.Node, $MethodInvocationInfo, $PassThru)
                }
            }
        }        
    }
    ProcessRecord([object]$Instance, [Microsoft.PowerShell.Cmdletization.MethodInvocationInfo] $methodInvocationInfo, [bool]$PassThru) {
        $this.Cmdlet.WriteVerbose("Processing instance and method")
        # If there is no method name, change the object
        if (-not $methodInvocationInfo.MethodName) {
            foreach ($parameter in $methodInvocationInfo.Parameters) {
                
            }
            $this.Cmdlet.WriteObject($Instance)
            return
        }        
    }
    ProcessRecord([Microsoft.PowerShell.Cmdletization.MethodInvocationInfo] $methodInvocationInfo) {
        $elementName = $methodInvocationInfo.MethodName
        $Dictionary = [Ordered]@{}
        foreach ($parameter in $methodInvocationInfo.Parameters.GetEnumerator()) {
            if (-not $parameter.Value) {
                continue
            }
            $Dictionary[$parameter.Name] = $parameter.Value            
            if ($parameter.Value -is [switch]) {
                $Dictionary[$parameter.Name] = $parameter.Value
            }
        }
        $this.Cmdlet.WriteObject($this.NewXmlElement($elementName, $Dictionary))
    }
    EndProcessing() {
        $this.Cmdlet.WriteVerbose("Ending processing")
    }
}
