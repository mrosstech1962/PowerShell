#
# _3_CreateAvailabilitySet.ps1
#
# Requires: Infrastructure
#

Login-AzureRmAccount

$ResourceGroup = 'MrossTech-Rg'
$AvailSetName = 'MrossTech-As'
$location = 'WestUS'

New-AzureRmAvailabilitySet `
		-ResourceGroupName $ResourceGroup `
		-Name $AvailSetName `
		-Location $location

$AvailSet = Get-AzureRmAvailabilitySet `
		-ResourceGroupName $ResourceGroup `
		-Name $AvailSetName

