﻿<#
.Synopsis
    GitHub Action for PSAdapter
.Description
    GitHub Action for PSAdapter.  This will:

    * Run all *.PSAdapter.ps1 files beneath the workflow directory
    * Run a .PSAdapterScript parameter.

    Any files changed can be outputted by the script, and those changes can be checked back into the repo.
    Make sure to use the "persistCredentials" option with checkout.
#>

param(
# A PowerShell Script that uses PSAdapter.  
# Any files outputted from the script will be added to the repository.
# If those files have a .Message attached to them, they will be committed with that message.
[string]
$PSAdapterScript,

# If set, will not process any files named *.PSAdapter.ps1
[switch]
$SkipPSAdapterPS1,

# A list of modules to be installed from the PowerShell gallery before scripts run.
[string[]]
$InstallModule = @("ugit"),

# A list of installation arguments.
[string[]]
$FFMpegInstallArgument,

# If provided, will commit any remaining changes made to the workspace with this commit message.
[string]
$CommitMessage,

# The user email associated with a git commit.
[string]
$UserEmail,

# The user name associated with a git commit.
[string]
$UserName
)

if (-not $env:GITHUB_WORKSPACE) { throw "No GitHub workspace" }
$anyFilesChanged = $false
$moduleName = 'PSAdapter'
$actorInfo = $null

"::group::Parameters" | Out-Host
[PSCustomObject]$PSBoundParameters | Format-List | Out-Host
"::endgroup::" | Out-Host

function ImportActionModule {
    #region -InstallModule
    if ($InstallModule) {
        "::group::Installing Modules" | Out-Host
        foreach ($moduleToInstall in $InstallModule) {
            $moduleInWorkspace = Get-ChildItem -Path $env:GITHUB_WORKSPACE -Recurse -File |
                Where-Object Name -eq "$($moduleToInstall).psd1" |
                Where-Object { 
                    $(Get-Content $_.FullName -Raw) -match 'ModuleVersion'
                }
            if (-not $moduleInWorkspace) {
                Install-Module $moduleToInstall -Scope CurrentUser -Force
                Import-Module $moduleToInstall -Force -PassThru | Out-Host
            }
        }
        "::endgroup::" | Out-Host
    }
    #endregion -InstallModule

    if ($env:GITHUB_ACTION_PATH) {
        $LocalModulePath = Join-Path $env:GITHUB_ACTION_PATH "$moduleName.psd1"
        if (Test-path $LocalModulePath) {
            Import-Module $LocalModulePath -Force -PassThru | Out-String
        } else {
            throw "Module '$moduleName' not found"
        }
    } elseif (-not (Get-Module $moduleName)) {    
        throw "Module '$ModuleName' not found"
    }

    "::notice title=ModuleLoaded::$ModuleName Loaded from Path - $($LocalModulePath)" | Out-Host
    if ($env:GITHUB_STEP_SUMMARY) {
        "# $($moduleName)" |
            Out-File -Append -FilePath $env:GITHUB_STEP_SUMMARY
    }
}
function InitializeAction {
    #region Custom 
    if ($PSVersionTable.Platform -eq 'Unix') {
        $ffMpegInPath =  $ExecutionContext.SessionState.InvokeCommand.GetCommand('ffmpeg', 'Application')
        if (-not $ffMpegInPath -and $env:GITHUB_WORKFLOW) {
            "::group::Installing FFMpeg" | Out-Host
            sudo apt update | Out-Host
            sudo apt install ffmpeg @FFMpegInstallArgument | Out-Host
            "::endgroup::" | Out-Host
        }
    }
    #endregion Custom

    # Configure git based on the $env:GITHUB_ACTOR
    if (-not $UserName) { $UserName = $env:GITHUB_ACTOR }
    if (-not $actorID)  { $actorID = $env:GITHUB_ACTOR_ID }
    $actorInfo = Invoke-RestMethod -Uri "https://api.github.com/user/$actorID"
    if (-not $UserEmail) { $UserEmail = "$UserName@noreply.github.com" }
    git config --global user.email $UserEmail
    git config --global user.name  $actorInfo.name

    # Pull down any changes
    git pull | Out-Host
}

function InvokeActionModule {
    $myScriptStart = [DateTime]::Now
    $myScript = $ExecutionContext.SessionState.PSVariable.Get("${ModuleName}Script").Value
    if ($myScript) {
        Invoke-Expression -Command $myScript |
            . ProcessOutput |
            Out-Host
    }
    $myScriptTook = [Datetime]::Now - $myScriptStart
    $MyScriptFilesStart = [DateTime]::Now

    $myScriptList  = @()
    $shouldSkip = $ExecutionContext.SessionState.PSVariable.Get("Skip${ModuleName}PS1").Value
    if (-not $shouldSkip) {
        Get-ChildItem -Recurse -Path $env:GITHUB_WORKSPACE |
            Where-Object Name -Match "\.$($moduleName)\.ps1$" |            
            ForEach-Object -Begin {
                if ($env:GITHUB_STEP_SUMMARY) {
                    "## $ModuleName Scripts" |
                        Out-File -Append -FilePath $env:GITHUB_STEP_SUMMARY
                } 
            } -Process {
                $myScriptList += $_.FullName.Replace($env:GITHUB_WORKSPACE, '').TrimStart('/')
                $myScriptCount++
                $scriptFile = $_
                if ($env:GITHUB_STEP_SUMMARY) {
                    "### $($scriptFile.Fullname)" |
                        Out-File -Append -FilePath $env:GITHUB_STEP_SUMMARY
                }            
                $scriptFileOutputs = . $scriptFile.FullName
                if ($env:GITHUB_STEP_SUMMARY) {
                    "$(@($scriptFileOutputs).Length) Outputs" |                    
                        Out-File -Append -FilePath $env:GITHUB_STEP_SUMMARY
                    "$(@($scriptFileOutputs).Length) Outputs" | Out-Host
                }
                $scriptFileOutputs |
                    . ProcessOutput  | 
                    Out-Host
            }
    }
    
    $MyScriptFilesTook = [Datetime]::Now - $MyScriptFilesStart
    $SummaryOfMyScripts = "$myScriptCount $moduleName scripts took $($MyScriptFilesTook.TotalSeconds) seconds" 
    $SummaryOfMyScripts | 
        Out-Host
    if ($env:GITHUB_STEP_SUMMARY) {
        $SummaryOfMyScripts | 
            Out-File -Append -FilePath $env:GITHUB_STEP_SUMMARY
    }
}

function PushActionOutput {
    if ($CommitMessage -or $anyFilesChanged) {
        if ($CommitMessage) {
            Get-ChildItem $env:GITHUB_WORKSPACE -Recurse |
                ForEach-Object {
                    $gitStatusOutput = git status $_.Fullname -s
                    if ($gitStatusOutput) {
                        git add $_.Fullname
                    }
                }
    
            git commit -m $ExecutionContext.SessionState.InvokeCommand.ExpandString($CommitMessage)
        }
    
        $checkDetached = git symbolic-ref -q HEAD
        if (-not $LASTEXITCODE) {
            "::notice::Pushing Changes" | Out-Host
            git push
            "Git Push Output: $($gitPushed  | Out-String)"
        } else {
            "::notice::Not pushing changes (on detached head)" | Out-Host
            $LASTEXITCODE = 0
            exit 0
        }
    }
}

filter ProcessOutput {
    $out = $_
    $outItem = Get-Item -Path $out -ErrorAction Ignore
    if (-not $outItem -and $out -is [string]) {
        $out | Out-Host
        if ($env:GITHUB_STEP_SUMMARY) {
            "> $out" | Out-File -Append -FilePath $env:GITHUB_STEP_SUMMARY
        }
        return
    }
    $fullName, $shouldCommit = 
        if ($out -is [IO.FileInfo]) {
            $out.FullName, (git status $out.Fullname -s)
        } elseif ($outItem) {
            $outItem.FullName, (git status $outItem.Fullname -s)
        }
    if ($shouldCommit) {
        git add $fullName
        if ($out.Message) {
            git commit -m "$($out.Message)" | Out-Host
        } elseif ($out.CommitMessage) {
            git commit -m "$($out.CommitMessage)" | Out-Host
        }  elseif ($gitHubEvent.head_commit.message) {
            git commit -m "$($gitHubEvent.head_commit.message)" | Out-Host
        }
        $anyFilesChanged = $true
    }    
    $out
}


. ImportActionModule
. InitializeAction
. InvokeActionModule
. PushActionOutput
