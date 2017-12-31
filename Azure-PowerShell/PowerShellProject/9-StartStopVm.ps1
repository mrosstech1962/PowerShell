#
# _9_StartStopVm.ps1
#
# Requires: Infrastructure
#

Login-AzureRmAccount
$ResourceGroup = 'MrossTech-Rg'
$location = 'WestUS'
Start-AzureRmVM -ResourceGroupName $ResourceGroup -Name "1-MrossTech-Vm"
Start-AzureRmVM -ResourceGroupName $ResourceGroup -Name "2-MrossTech-Vm"



Login-AzureRmAccount
$ResourceGroup = 'MrossTech-Rg'
$location = 'WestUS'
Stop-AzureRmVM -ResourceGroupName $ResourceGroup -Name "1-MrossTech-Vm" -Force -StayProvisioned
Stop-AzureRmVM -ResourceGroupName $ResourceGroup -Name "2-MrossTech-Vm" -Force -StayProvisioned
