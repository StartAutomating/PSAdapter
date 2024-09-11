/*
.SYNOPSIS
    This is a template implementation for a MarkupAdapter.
.DESCRIPTION
    This is a template implementation for a MarkupAdapter.  It is a CmdletAdapter that creates Markup.

    This can be useful for creating XML, HTML, or other markup languages.
*/
namespace PSAdapter
{    
    using System;
    using System.Web;
    using System.Management.Automation;
    using System.Management.Automation.Runspaces;
    using System.Collections;
    using System.Collections.Generic;
    using System.Collections.Specialized;    
    using System.Collections.ObjectModel;
    using Microsoft.PowerShell.Cmdletization;
    

    public class PSMarkupAdapter : CmdletAdapter<Object>
    {
        public ScriptBlock ToMarkup { get; set; }
        Dictionary<string, List<object>> attributesAndElements = new Dictionary<string, List<object>>(StringComparer.OrdinalIgnoreCase);

        public override void BeginProcessing()
        {
            
        }
        public override void ProcessRecord(MethodInvocationInfo methodInvocationInfo)
        {
            if (this.ToMarkup == null)
            {
                this.ToMarkup = ScriptBlock.Create(@"
                    param($elementName, $dictionary, $privateData, $this)
                    $invocationName = $this.Cmdlet.MyInvocation.InvocationName
                    $escapedInvocationName = '^' + ([Regex]::Escape($invocationName)) + '-'
                    if ($debugPreference -eq 'Continue') {
                        Write-Debug ""Making Markup Element: $elementName""
                    }
                    $children = @(foreach ($parameterName in @($Dictionary.Keys)) {
                        $myParameterPrivateData = 
                            $this.PrivateData.Keys -match (
                                [Regex]::Escape($parameterName)
                            ) -match $escapedInvocationName
                        if ($debugPreference -eq 'Continue' -and $myParameterPrivateData) {
                            Write-Debug ""ParameterName: '$parameterName' has private data keys: $($myParameterPrivateData) ""                            
                        }
                        if ($dictionary[$parameterName] -match '^\s{0,}\S+') {
                            foreach ($elementNameKey in $myParameterPrivateData -match 'ElementName$') {
                                $elementNameValue = $this.PrivateData[$elementNameKey]
                                $childElementXml = (
                                    ""<$elementNameValue>"" + 
                                        [Security.SecurityElement]::Escape($dictionary[$parameterName]) + 
                                    ""</$elementNameValue>""
                                ) -as [xml]
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
                    ""<$ElementName""
                        $elementAttributes = @(foreach ($keyValuePair in $dictionary.GetEnumerator()) {
                            $key = $keyValuePair.Key
                            $value = $keyValuePair.Value
                            if ($value -is [bool]) {
                                $value = $value.ToString().ToLower()
                            }
                            [Web.HttpUtility]::HtmlAttributeEncode($key) + '=""' + [Web.HttpUtility]::HtmlAttributeEncode($Value) + '""'
                        })
                        if ($elementAttributes) {
                            ' ' + ($elementAttributes -join ' ')
                        }
                    if ($children) {
                        '>'
                        Write-Verbose ""Adding $($children.Count) children:""
                        foreach ($child in $children) {
                            if ($child.OuterXml) {
                                $child.OuterXml
                            } else {
                                $child
                            }
                        }
                        ""</$ElementName>""
                    } else {
                        '/>'
                    }
                    ) -join ' '
                    if ($markupText -as [xml]) {
                        $markupText -as [xml]
                    } else {
                        $markupText
                    }
                ");
            }
            OrderedDictionary methodInfo = new OrderedDictionary(StringComparer.OrdinalIgnoreCase);            
            foreach (var paramInfo in methodInvocationInfo.Parameters)
            {
                if (paramInfo.Value != null) {

                    if (paramInfo.Value is SwitchParameter) {
                        SwitchParameter switchParam = (SwitchParameter)paramInfo.Value;
                        methodInfo.Add(paramInfo.Name, switchParam.IsPresent);
                    } else {
                        methodInfo.Add(paramInfo.Name, paramInfo.Value);
                    }                    
                }                
            }
            
            Pipeline pipeline = Runspace.DefaultRunspace.CreateNestedPipeline(ToMarkup.ToString(), false);
            pipeline.Commands[0].Parameters.Add("ElementName", methodInvocationInfo.MethodName);
            pipeline.Commands[0].Parameters.Add("Dictionary", methodInfo);            
            pipeline.Commands[0].Parameters.Add("PrivateData", this.PrivateData);
            pipeline.Commands[0].Parameters.Add("This", this);
            Collection<PSObject> results = pipeline.Invoke();
            pipeline.Dispose();                
            this.Cmdlet.WriteObject(results, true);
        }
    }
}
