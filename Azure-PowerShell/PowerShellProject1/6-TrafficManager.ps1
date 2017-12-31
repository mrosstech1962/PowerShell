#
# _6_TrafficManager.ps1
#
# Requires: Infrastructure, 2 AppSvcPlans in 2 Regions, and one instance of WebApp per region
#

Login-AzureRmAccount

$ProfileName = 'MrossTech-TmProfile'  #Unique
$EndPntName1 = 'MrossTech-Ep1'  #Unique
$EndPntName2 = 'MrossTech-Ep2'  #Unique
$WebAppName1 = 'mrosstechwebappa'  #Unique
$WebAppName2 = 'mrosstechwebappb'  #Unique

$ResourceGroup = 'MrossTech-Rg'
$location = 'WestUS'

$TmProfile = New-AzureRmTrafficManagerProfile `
	-Name $ProfileName `
	-ResourceGroupName $ResourceGroup `
	-TrafficRoutingMethod Performance `
	-RelativeDnsName mrosstech `
	-Ttl 30 `
	-MonitorProtocol HTTP `
	-MonitorPort 80 `
	-MonitorPath "/"
	
$webapp1 = Get-AzureRMWebApp -Name $WebAppName1
$webapp2 = Get-AzureRMWebApp -Name $WebAppName2

Add-AzureRmTrafficManagerEndpointConfig `
	-EndpointName $EndPntName1 `
	-TrafficManagerProfile $TmProfile `
	-Type AzureEndpoints `
	-TargetResourceId $webapp1.Id `
	-EndpointStatus Enabled

Add-AzureRmTrafficManagerEndpointConfig `
	-EndpointName $EndPntName2 `
	-TrafficManagerProfile $TmProfile `
	-Type AzureEndpoints `
	-TargetResourceId $webapp2.Id `
	-EndpointStatus Enabled

Set-AzureRmTrafficManagerProfile -TrafficManagerProfile $TmProfile
