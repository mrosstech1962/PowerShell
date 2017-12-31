#
# Script.ps1
#
Login-AzureRmAccount

$ResourceGroup = 'mross-Rg'
$location = 'WestUS'
$SubnetName = 'mross-Subnet'
$VnetName = 'mrossVnet'
$PipName = 'mrossPublicIPAddress-1'
$NicName = 'mrossNic-1'
$NsgRuleName = 'mrossNSGRule'
$NsgName = 'mrossSecurityGroup-1'
$vmName = 'mrossVM-1'
$StorageAccountName = "mrosstechstorageaccount"
$containerName = 'osdisks'
$SkuName = "Standard_LRS"
$OsDiskName = 'mrossOsDisk-1'


New-AzureRmResourceGroup `
	-Name $resourcegroup `
	-Location $location

$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
	     -Name $SubnetName `
	     -AddressPrefix 192.168.1.0/24

$vnet = New-AzureRmVirtualNetwork `
	-Name $VnetName `
	-ResourceGroupName $resourcegroup `
	-Location $location `
	-AddressPrefix 192.168.0.0/16 `
	-Subnet $subnetConfig

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
	
$nsgRule = New-AzureRmNetworkSecurityRuleConfig `
  -Name $NsgRuleName `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 3389 `
  -Access Allow
	
$nsg = New-AzureRmNetworkSecurityGroup `
	-ResourceGroupName $resourcegroup `
	-Location $location `
	-Name $NsgName `
	-SecurityRules $nsgRule
	
Set-AzureRmVirtualNetworkSubnetConfig `
	-Name $SubnetName `
	-VirtualNetwork $vnet `
	-NetworkSecurityGroup $nsg `
	-AddressPrefix 192.168.1.0/24
	
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

# Create a storage account and a container

$StorageAccount = New-AzureRMStorageAccount `
  -Location $location `
  -ResourceGroupName $ResourceGroup `
  -Type $SkuName `
  -Name $StorageAccountName

Set-AzureRmCurrentStorageAccount `
  -StorageAccountName $storageAccountName `
  -ResourceGroupName $resourceGroup

# Create a storage container to store the virtual machine image

$container = New-AzureStorageContainer `
  -Name $containerName `
  -Permission Blob

# Create a Virtual Machine

$cred = Get-Credential
	
$vm = New-AzureRmVMConfig `
		-VMName $vmName `
		-VMSize Standard_D1
		
$vm = Set-AzureRmVMOperatingSystem `
		-VM $vm `
		-Windows `
		-ComputerName $vmName `
		-Credential $cred `
		-ProvisionVMAgent `
		-EnableAutoUpdate
	
$vm = Set-AzureRmVMSourceImage `
		-VM $vm `
		-PublisherName MicrosoftWindowsServer `
		-Offer WindowsServer `
		-Skus 2016-Datacenter `
		-Version latest

		$containerName
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

$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize Standard_D1 | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $nic.Id | `
	Set-AzureRmVMOSDisk -Name mrossOsDisk -1 -DiskSizeInGB 128 -VhdUri $OsDiskUri `
	-CreateOption FromImage -Caching ReadWrite

	New-AzureRmVM -ResourceGroupName $resourcegroup -Location WestUS -VM $vmconfig

