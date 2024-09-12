#requires -Module PSDevOps
Import-BuildStep -SourcePath (
    Join-Path $PSScriptRoot 'GitHub'
) -BuildSystem GitHubAction

$PSScriptRoot | Split-Path | Push-Location

New-GitHubAction -Name "UsePSAdapter" -Description 'Adapt anything into Cmdlets' -Action PSAdapter -Icon chevron-right -OutputPath .\action.yml

Pop-Location