#
# _11_TempDeploy.ps1
#

Login-AzureRmAccount

$deployName="TestDeployment" 
$RGName="ReDeploy" 
$locname="West US" 
$templateURI = "https://github.com/Azure/azure-quickstart-templates/blob/master/101-vm-simple-windows/azuredeploy.json"
New-AzureRmResourceGroup –Name $RGName –Location $locName 
New-AzureRmResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateUri $templateURI


https://github.com/Azure/azure-quickstart-templates/tree/master/101-vm-simple-windows

New-AzureRmResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateUri "D:\Deployments\ReDeploy\template.json" -TemplateParameterFile "D:\Deployments\ReDeploy\parameters.json"