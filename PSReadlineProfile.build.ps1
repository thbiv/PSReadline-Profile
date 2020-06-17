$Script:ScriptName = Split-Path -Path $PSScriptRoot -Leaf
$Script:ScriptFileName = $ScriptName + ".ps1"
$Script:SourceRoot = "$BuildRoot\source"
$Script:OutputRoot = "$BuildRoot\_output"
$Script:TestResultsRoot = "$BuildRoot\_testresults"
$Script:TestsRoot = "$BuildRoot\tests"
$Script:FileHashRoot = "$BuildRoot\_filehash"
$Script:SourceScript = "$SourceRoot\$ScriptFileName"
$Script:DestinationScript = "$OutputRoot\$ScriptFileName"

Task . Clean, Build, Test, Hash, Deploy
Task Testing Clean, Build, Test

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
    Get-Content -Path "$SourceScript" | Add-Content -Path $DestinationScript
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

# Synopsis: Produce File Hash for all output files
Task Hash {
    $HashOutput = Get-FileHash -Path $DestinationScript
    $HashExportFile = "ScriptFile_Hash_$ScriptName.xml"
    $HashOutput | Export-Clixml -Path "$FileHashRoot\$HashExportFile"
    Write-Host "Hash Information File: $HashExportFile"
}

# Synopsis: Publish to repository
Task Deploy {
    Invoke-PSDeploy -Force -Verbose
}
