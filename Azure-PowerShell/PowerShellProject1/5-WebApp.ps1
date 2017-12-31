#
# _5_WebApp.ps1
#
# Requires: Infrastructure and AppSvcPlan
#

Login-AzureRmAccount
Select-AzureRmSubscription -SubscriptionName (Get-AzureRmSubscription).Name

$WebAppName = 'mrosstechwebappa'  #Unique
# $AppSvcName = 'MrossTech-AppSvc'  #Unique
$AppSvcName = 'MrossTech-AppSvcTm'
$location = 'WestUS'

# Unique for Traffic Manager
# $WebAppName = 'mrosstechwebappb'
# $AppSvcName = 'MrossTech-AppSvcTm'
# $location = 'WestUS2'

$ResourceGroup = 'MrossTech-Rg'

New-AzureRmWebApp `
   -ResourceGroupName $ResourceGroup `
   -Name $WebAppName `
   -Location $location `
   -AppServicePlan $AppSvcName

Get-AzureRmAppServicePlan
