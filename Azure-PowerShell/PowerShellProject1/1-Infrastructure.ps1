#
# Infrastructure.ps1
# Creates a Vnet, Subnet, NSG, Storage Account/Container, Availability Set
#

Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName (Get-AzureRmSubscription).Name

$ResourceGroup = 'MrossTech-Rg'
$location = 'WestUS'
$SubnetName = 'MrossTech-Subnet'
$VnetName = 'MrossTech-Vnet'
$VnetPrefix = '192.168.0.0/16'
$SubNetPrefix = '192.168.1.0/24'
$NsgRuleNamePre = 'MrossTech-NsgRule'
$NsgName = 'MrossTech-Nsg'
$StorageAccountName = 'mrosstechstorageaccount'
$containerName = 'mrosstech-osdisks'
$SkuName = "Standard_LRS"
$AvailSetName = 'MrossTech-AvSet'

New-AzureRmResourceGroup `
	-Name $resourcegroup `
	-Location $location

$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
	-Name $SubnetName `
	-AddressPrefix $SubNetPrefix

$vnet = New-AzureRmVirtualNetwork `
	-Name $VnetName `
	-ResourceGroupName $resourcegroup `
	-Location $location `
	-AddressPrefix $VnetPrefix `
	-Subnet $subnetConfig

$NsgRuleName = $NsgRuleNamePre + '-Rdp'
$nsgRule1 = New-AzureRmNetworkSecurityRuleConfig `
    -Name $NsgRuleName `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1000 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 3389 `
    -Access Allow

$NsgRuleName = $NsgRuleNamePre + '-Web'
$nsgRule2 = New-AzureRmNetworkSecurityRuleConfig `
    -Name $NsgRuleName `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 1001 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 80 `
    -Access Allow
	
$nsg = New-AzureRmNetworkSecurityGroup `
	-ResourceGroupName $resourcegroup `
	-Location $location `
	-Name $NsgName `
	-SecurityRules $nsgRule1, $nsgRule2
	
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

New-AzureStorageContainer `
    -Name $containerName `
    -Permission Blob

#Create Availability Set

New-AzureRmAvailabilitySet `
	-ResourceGroupName $ResourceGroup `
	-Name $AvailSetName `
	-Location $location