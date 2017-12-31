#
# _4_WebApp.ps1
#
# Required: Infrastructure.ps1
#

Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName (Get-AzureRmSubscription).Name

# Required App Service Plan
# $AppSvcName = 'MrossTech-AppSvc'  #Unique
# $location = 'WestUS'

# Unique for Traffic Manager
$AppSvcName = 'MrossTech-AppSvcTm'
$location = 'WestUS2'

$ResourceGroup = 'MrossTech-Rg'

New-AzureRmAppServicePlan `
	-ResourceGroupName $ResourceGroup `
	-Name $AppSvcName `
	-Location $location `
	-Tier "Standard" `
	-NumberofWorkers 2 `
	-WorkerSize "Small"