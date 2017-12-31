#
# AddVM.ps1
#
# Requires: Infrastructure
#

Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName (Get-AzureRmSubscription).Name
$cred = Get-Credential

[string]$NamePreFix = 3  # Change
$vmName = $NamePreFix + '-MrossTech-Vm'
$NicName = $NamePreFix + '-MrossTech-Nic'
$OsDiskName = $NamePreFix + '-MrossTech-OsDisk'
$PipName = $NamePreFix + '-MrossTech-Pip'
$ResourceGroup = 'MrossTech-Rg'
$location = 'WestUS'
$SubnetName = 'MrossTech-Subnet'
$VnetName = 'MrossTech-Vnet'
$AvailSetName = 'MrossTech-AvSet'
$StorageAccountName = 'mrosstechstorageaccount'
$containerName = 'mrosstech-osdisks'

$vnet = Get-AzureRmVirtualNetwork -Name $VnetName -ResourceGroupName $ResourceGroup
$StorageAccount = Get-AzureRMStorageAccount -ResourceGroupName $ResourceGroup -Name $StorageAccountName

$pip = New-AzureRmPublicIpAddress `
		-ResourceGroupName $resourcegroup `
		-Location $location `
		-AllocationMethod Static `
		-Name $PipName
	
$nic = New-AzureRmNetworkInterface `
		-ResourceGroupName $resourcegroup `
		-Location $location `
		-Name $NicName `
		-SubnetId $vnet.Subnets[0].Id `
		-PublicIpAddressId $pip.Id

Set-AzureRmVirtualNetwork -VirtualNetwork $vnet
	
$AvailSet = Get-AzureRmAvailabilitySet `
		-ResourceGroupName $ResourceGroup `
		-Name $AvailSetName `
		# -Location $location

$vm = New-AzureRmVMConfig `
		-VMName $vmName `
		-VMSize Standard_A1 `
		-AvailabilitySetId $AvailSet.Id
		
$vm = Set-AzureRmVMOperatingSystem `
		-VM $vm `
		-Windows `
		-ComputerName $vmName `
		-Credential $cred `
		-ProvisionVMAgent `
		-EnableAutoUpdate

# $image = Get-AzureRmImage -ImageName 'azureGoldImage'
# $vm = Set-AzureRmVMSourceImage -VM $vm -Id $image.Id

$vm = Set-AzureRmVMSourceImage `
		-VM $vm `
 		-PublisherName MicrosoftWindowsServer `
 		-Offer WindowsServer `
 		-Skus 2016-Datacenter `
 		-Version latest

# $osDiskUri = '{0}vhds/{1}-{2}.vhd' -f `
$vhdpath = '{0}' + $containerName + '/{1}-{2}.vhd'
$osDiskUri = $vhdpath -f `
			$StorageAccount.PrimaryEndpoints.Blob.ToString(),`
			$vmName.ToLower(), `
			$osDiskName

$vm = Set-AzureRmVMOSDisk `
		-VM $vm `
		-Name $OsDiskName `
		-DiskSizeInGB 128 `
		-VhdUri $OsDiskUri `
		-CreateOption FromImage `
		-Caching ReadWrite
		
$vm = Add-AzureRmVMNetworkInterface `
		-VM $vm `
		-Id $nic.Id

New-AzureRmVM -ResourceGroupName $resourcegroup -Location WestUS -VM $vm

# $vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize Standard_D1 | `
#     Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
#     Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
#     -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id | `
# 	Set-AzureRmVMOSDisk -Name mrossOsDisk -1 -DiskSizeInGB 128 -VhdUri $OsDiskUri `
# 	-CreateOption FromImage -Caching ReadWrite
# 
# 	New-AzureRmVM -ResourceGroupName $resourcegroup -Location WestUS -VM $vmconfig