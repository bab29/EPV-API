Add-Type -AssemblyName Microsoft.PowerShell.Commands.Utility
$load = $null
$(Get-childitem -path $PSScriptRoot -filter *.psm1).FullName|ForEach-Object {
$load += "Using Module $PSItem`n"
}

. ([scriptblock]::Create($Load))