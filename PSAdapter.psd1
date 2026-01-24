@{
    ModuleVersion = '0.1'
    RootModule = 'PSAdapter.psm1'
    TypesToProcess = 'PSAdapter.types.ps1xml'
    FormatsToProcess = 'PSAdapter.format.ps1xml'
    Guid = '2453038a-2885-45f9-bb77-cc6971569172'
    Copyright = '2024 Start-Automating'
    Author = 'James Brundage'
    CompanyName = 'Start-Automating'
    Description = 'Adapt anything to PowerShell'
    PrivateData  = @{
        PSData = @{
            Tags = @('PSAdapter')
            LicenseUri = 'https://github.com/StartAutomating/PSAdapter/blob/main/LICENSE'
            ProjectUri = 'https://github.com/StartAutomating/PSAdapter'
            ReleaseNotes = @'
## PSAdapter 0.1:

* PSAdapter Module Source ( #1, #2, #7, #8 )
* PSAdapter Container:
  * Dockerfile ( #11 )
  * Container.init ( #13 )
  * Container.start ( #14 )
  * Container Publishing ( #5, #12 )
  * Container updates (#73)
* PSAdapter Types and Formatting( #3 )
  * PSAdapter basic formatting ( #19 )
  * `PSAdapter.get_PSAdapterType` ( #24 )
* Commands:
  * `New-PSAdapter` ( #9 )
  * `Get-PSAdapter` ( #10 )
  * `Enable-PSAdapter` ( #33 )
  * `Disable-PSAdapter` ( #34 )
* Example Adapters Types:
  * NullAdapter ( #17 )
  * PSEventAdapter ( #18 )
  * PSDotNetAdapter ( #16 )
  * PSTestStaticAdapter ( #26 )
  * PSMarkupAdapter ( #27 )
  * PSDictionaryAdapter ( #47 )
  * PSJsonAdapter ( #45 )
  * PSXMLAdapter ( #28 )
* Example Adapter Commands:
  * Guid example adapter ( #22 )
  * AppDomain Example adapter ( #20 )
  * HttpListener Example Adapter ( #21 )
  * Environment Example Adapter ( #25 )
  * Math example adapter ( #23 )
  * CDXML Example ( #32 )
  * RunspaceFactory adapter ( #50 )
  * PSAdapter Class ( #42 )
  * Path Example ( #51 )
  * Convert example ( #53 )
* PSAdapter logo ( #31 )
* PSAdapter Action (#6 )
* Exporting PSAdapter classes ( #62 )

* Compiling Adapters on Load ( #1 )

'@
        }
    }
    
}
