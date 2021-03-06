$Script:ScriptName = Split-Path -Path $PSScriptRoot -Leaf
$Script:ScriptFileName = $ScriptName + ".ps1"
$Script:SourceRoot = "$BuildRoot\source"
$Script:OutputRoot = "$BuildRoot\_output"
$Script:TestResultsRoot = "$BuildRoot\_testresults"
$Script:TestsRoot = "$BuildRoot\tests"
$Script:SourceScript = "$SourceRoot\$ScriptFileName"
$Script:DestinationScript = "$OutputRoot\$ScriptFileName"
$Script:ScriptConfig = [xml]$(Get-Content -Path '.\Script.Config.xml')

Task . Clean, Build, Test

# Synopsis: Empty the _output and _testresults folders
Task Clean {
    If (Test-Path -Path $OutputRoot) {
        Get-ChildItem -Path $OutputRoot -Recurse | Remove-Item -Force -Recurse
    } Else {
		New-Item -Path $OutputRoot -ItemType Directory -Force
	}
    If (Test-Path -Path $TestResultsRoot) {
        Get-ChildItem -Path $TestResultsRoot -Recurse | Remove-Item -Force -Recurse
    } Else {
		New-Item -Path $TestResultsRoot -ItemType Directory -Force
	}
}

# Synopsis: Compile and build the project
Task Build {
    Write-Host "Building Powershell Script $ScriptName"

    "# Project:     $ScriptName" | Add-Content -Path $DestinationScript
    "# Author:      $($ScriptConfig.config.info.author)" | Add-Content -Path $DestinationScript
    "# Buildnumber: $($ScriptConfig.config.info.scriptbuild)" | Add-Content -Path $DestinationScript
    "# Description: $($ScriptConfig.config.info.description)" | Add-Content -Path $DestinationScript
    Get-Content -Path $SourceScript | Add-Content -Path $DestinationScript

    $Content = Get-Content -Path "$OutputRoot\PSReadline-Profile.ps1"
    $Content | ForEach-Object {$_.TrimEnd()} | Set-Content -Path "$OutputRoot\PSReadline-Profile.ps1" -Force

    $ZipName = "{0}_{1}.zip" -f $ScriptName, $($ScriptConfig.config.info.scriptbuild)
    Compress-Archive -Path "$OutputRoot\PSReadline-Profile.ps1" -DestinationPath "$OutputRoot\$ZipName"
}

# Synopsis: Test the Project
Task Test {
    $PesterBasic = @{
        OutputFile = "$TestResultsRoot\BasicScriptTestResults.xml"
        OutputFormat = 'NUnitXml'
        Script = @{Path="$TestsRoot\BasicScript.tests.ps1";Parameters=@{Path=$OutputRoot;ProjectName=$ScriptName}}
    }
    $BasicResults = Invoke-Pester @PesterBasic -PassThru
    If ($BasicResults.FailedCount -ne 0) {Throw "One or more Basic Script Tests Failed"}
    Else {Write-Host "All tests have passed...Build can continue."}
}