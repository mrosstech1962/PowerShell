#
# _8_VmScaleSet.ps1
#
# Requires: Infrastructure
#

https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-overview

$VmSsName = 'MrossTech-VmSsName' # Unique
$ResourceGroup = 'MrossTech-Rg'
$location = 'WestUS'

$subid = "yoursubscriptionid"

$rule1 = New-AzureRmAutoscaleRule `
			-MetricName "Percentage CPU" `
			-MetricResourceId /subscriptions/$subid/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachineScaleSets/$VmSsName `
			-Operator GreaterThan `
			-MetricStatistic Average `
			-Threshold 60 `
			-TimeGrain 00:01:00 `
			-TimeWindow 00:05:00 `
			-ScaleActionCooldown 00:05:00 `
			-ScaleActionDirection Increase `
			-ScaleActionValue 1

$rule2 = New-AzureRmAutoscaleRule `
			-MetricName "Percentage CPU" `
			-MetricResourceId /subscriptions/$subid/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachineScaleSets/$VmSsName `
			-Operator LessThan `
			-MetricStatistic Average `
			-Threshold 30 `
			-TimeGrain 00:01:00 `
			-TimeWindow 00:05:00 `
			-ScaleActionCooldown 00:05:00 `
			-ScaleActionDirection Decrease `
			-ScaleActionValue 1

$profile1 = New-AzureRmAutoscaleProfile `
			-DefaultCapacity 2 `
			-MaximumCapacity 10 `
			-MinimumCapacity 2 `
			-Rules $rule1,$rule2 `
			-Name "autoprofile1"

Add-AzureRmAutoscaleSetting `
			-Location $location `
			-Name "autosetting1" `
			-ResourceGroup $ResourceGroup `
			-TargetResourceId /subscriptions/$subid/resourceGroups/$ResourceGroup/providers/Microsoft.Compute/virtualMachineScaleSets/$VmSsName `
			-AutoscaleProfiles $profile1


# The following code only updates the scaleout capacity
# $vmss = Get-AzureRmVmss -ResourceGroupName $ResourceGroup -VMScaleSetName $VmSsName 
# $vmss.Sku.Capacity = 10
# Update-AzureRmVmss -ResourceGroupName $ResourceGroup -Name $VmSsName -VirtualMachineScaleSet $vmss


