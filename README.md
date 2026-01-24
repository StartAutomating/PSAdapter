<div align='center'>
<img src='Assets/PSAdapter.svg' alt='PSAdapter' />
<a href='https://www.powershellgallery.com/packages/PSAdapter/'>
<img src='https://img.shields.io/powershellgallery/dt/PSAdapter' />
</a>
<br/>
<a href='https://github.com/sponsors/StartAutomating'>❤️</a>
<a href='https://github.com/StartAutomating/PSAdapter/stargazers'>⭐</a>
</div>

# PSAdapter

Adapt anything into PowerShell Commands.

PSAdapter is a module that helps you build and manage PowerShell Command Adapters.

## A bit of background

PowerShell is full of amazing capabilities that are underknown and underused.

This modules is here to help demonstrate one of these areas:  [CmdletAdapters](https://learn.microsoft.com/en-us/dotnet/api/microsoft.powershell.cmdletization.cmdletadapter-1?view=powershellsdk-7.4.0&wt.mc_id=MVP_321542).

CmdletAdapters have existed since PowerShell Version 3, and are the part of PowerShell
that makes `.cdxml` files work.

Many people do not realize that CmdletAdapters are extensible, and thus, an adapter could be made for almost anything.

This module exists to help make CmdletAdapters, and provides some example .cdxml files that use these adapters.

## Using PSAdapter

### Installing

You can install PSAdapter from the PowerShell gallery:

~~~PowerShell
Install-Module -Name PSAdapter -Scope CurrentUser
~~~

## Adapter Types Included

PSAdapter ships several implementations of adapters:

* PSDotNetAdapter adapts any .NET class into Cmdlets
* PSEventAdapter creates Cmdlets that broadcast events
* PSMarkupAdapter creates Cmdlets that make markup
* PSXMLAdapter creates Cmdlets that make XML
* PSJSONAdapter creates Cmdlets that output JSON
* PSDictionaryAdapter creates Cmdlets the output dictionaries

## Using Adapters

Adapters allow you to create commands in XML.  Once you've imported the module, each adapter type will be available to use.

You are free to modify them as as needed for your environment.

To load a module that uses an adapter we can use Import-Module on the .cdxml file

~~~PowerShell
Get-Module PSAdapter | Split-Path | Push-Location
Import-Module ./Examples/Guid.cdmxl -PassThru
Pop-Location
~~~


Alternatively, if the adapter is a PSAdpater example, we can use: Enable-PSAdapter.
~~~PowerShell

Enable-PSAdapter -Name Guid
~~~


Adapted cmdlets are written in CDXML.   For example, Guid.cdxml is defined as:


~~~xml
<?xml version="1.0" encoding="utf-8"?>
<PowerShellMetadata xmlns="http://schemas.microsoft.com/cmdlets-over-objects/2009/11">
    <Class ClassName="System.Guid" CmdletAdapter="PSAdapter.PSDotNetAdapter">
        <Version>1.0</Version>
        <DefaultNoun>Guid</DefaultNoun>
        <InstanceCmdlets>
            <GetCmdletParameters />
        </InstanceCmdlets>
        <StaticCmdlets>
            <Cmdlet>
                <CmdletMetadata Verb="New" />
                <Method MethodName="NewGuid">                
                    <ReturnValue>
                        <Type PSType="System.Guid" />
                    </ReturnValue>
                </Method>
            </Cmdlet>
            <Cmdlet>
                <CmdletMetadata Verb="ConvertTo" />
                <Method MethodName="Parse">
                    <Parameters>
                        <Parameter ParameterName="String">
                            <Type PSType="System.String" />
                            <CmdletParameterMetadata ValueFromPipeline="true" ValueFromPipelineByPropertyName="true" Position="0">
                                <AllowNull />
                            </CmdletParameterMetadata>
                        </Parameter>
                    </Parameters>
                    <ReturnValue>
                        <Type PSType="System.Guid" />
                    </ReturnValue>
                </Method>
            </Cmdlet>
        </StaticCmdlets>
    </Class>    
</PowerShellMetadata>
~~~

By allowing us to define cmdlets in data, we can rapdily define and import massive numbers of commands, thus "adapting" whole ecosystems at once.