Param(
    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$Path,

    [Parameter(Mandatory=$True)]
    [ValidateNotNullOrEmpty()]
    [string]$ProjectName
)

$ScriptName = $ProjectName

Describe "Powershell validation" {
    $Scripts = Get-ChildItem $Path -Include *.ps1 -Recurse
    ForEach ($Script in $Scripts) {
        Context "$($Script.Name)" {
            It "Script should be valid powershell"  {
                $Script.FullName | Should Exist
                $Contents = Get-Content -Path $Script.FullName -ErrorAction Stop
                $Errors = $Null
                $Null = [System.Management.Automation.PSParser]::Tokenize($Contents, [ref]$Errors)
                $Errors.Count | Should Be 0
            }
        }
    }
}

Add-Type -AssemblyName System.Drawing
Describe 'PSSA Standard Rules' {
	$Scripts = Get-ChildItem $Path -Include *.ps1 -Recurse
	ForEach ($Script in $Scripts) {
		Context "$($Script.Name)" {
			$Analysis = Invoke-ScriptAnalyzer -Path $($Script.FullName) -ExcludeRule 'PSAvoidUsingWriteHost','PSAvoidUsingInvokeExpression','PSReviewUnusedParameter'
			$ScriptAnalyzerRules = Get-ScriptAnalyzerRule | Where-Object {($_.RuleName -ne 'PSAvoidUsingWriteHost') -and ($_.RuleName -ne 'PSAvoidUsingInvokeExpression') -and ($_.RuleName -ne 'PSReviewUnusedParameter')}
			ForEach ($Rule in $ScriptAnalyzerRules) {
				It "Should pass $Rule" {
					If ($Analysis.RuleName -contains $Rule) {
						$Analysis |	Where-Object RuleName -EQ $Rule -OutVariable Failures | Out-Default
						$Failures.Count | Should Be 0
					}
				}
			}
		}
	}
}