
Set-Location "D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin"
Import-Module .\ConfigurationManager

$computer = $env:COMPUTERNAME
$namespace = "ROOT\SMS\site_S01"
$classname1 = "SMS_G_System_CMDB64"
$classname2 = "SMS_Collection"
$Result = ""
[String]$WqlExpr = ""

# Collect all of the Maintenance Windows in a class populated from hardware inventory: SMS_G_System_CMDB64
$MWName = Get-WmiObject -Class $classname1 -ComputerName $computer -Namespace $namespace | 
    Select-Object MaintenanceWindow | Where-Object {$_.MaintenanceWindow -Like 'WOM*'}

# Collect all of the collections previously created by this script from this class: SMS_G_System_CMDB64
$CollName = Get-WmiObject -Class $classname2 -ComputerName $computer -Namespace $namespace |
    Select-object CollectionID, Name | Where-Object {$_.CollectionID -Like 'S01*'}  | Select-Object -ExpandProperty Name

Set-Location S01:
foreach ($Name in $MWName.MaintenanceWindow){
	$Name = $Name.Replace("_", " ")
    $Result = $CollName.Contains($Name)
    If ($Result -eq $false){
    
    # Split the Maintenance Window
    # WOM_2_DOW_1_MW_1300_TO_2000
    $MWarray = $Name.split("{ }")
    $WeekOfMonth = $MWarray[1] -as [int]
    $DayOfWeek = $MWarray[3] -as [int]	
    $StartHour = $MWarray[5] -as [int]
    $StopHour = $MWarray[7] -as [int]

	If ($DayOfWeek -eq "1") {$DayOfWeek = "Sunday"}
	ElseIf ($DayOfWeek -eq "2") {$DayOfWeek = "Monday"}
	ElseIf ($DayOfWeek -eq "3") {$DayOfWeek = "Tuesday"}
	ElseIf ($DayOfWeek -eq "4") {$DayOfWeek = "Wednesday"}
	ElseIf ($DayOfWeek -eq "5") {$DayOfWeek = "Thursday"}
	ElseIf ($DayOfWeek -eq "6") {$DayOfWeek = "Friday"}
	ElseIf ($DayOfWeek -eq "7") {$DayOfWeek = "Saturday"}

	# Creates the missing collection
	$NewCollection = New-CMDeviceCollection -Name $Name -LimitingCollectionName 'All Computers With Active Clients'
	
	# Moves the new collection into the patch folder
	Move-CMObject -FolderPath '.\DeviceCollection\Patch Collections' -InputObject $NewCollection

	# Gets the Collection ID of the new device Collection; Converts the object to a string
	$CollectID = Get-CMDeviceCollection -Name $Name | Select-Object CollectionID | Select -ExpandProperty CollectionID

	# Creates an Include rule for the parent device collection
	Add-CMDeviceCollectionIncludeMembershipRule -CollectionId S0100012 -IncludeCollectionId $CollectID
	
	# Create the WQL Query Expression used in the device collection membership query
	$Name2 = $Name.Replace(" ", "_")
	$WqlExpr = "select SMS_G_System_CMDB64.ComputerName, SMS_G_System_CMDB64.MaintenanceWindow 
		from  SMS_R_System inner join SMS_G_System_CMDB64 
		on SMS_G_System_CMDB64.ResourceId = SMS_R_System.ResourceId 
		where SMS_G_System_CMDB64.MaintenanceWindow = '$Name2'"

	# Adds the Query Rule to the collection so that only the CMDB resources from the associated Maintenance Window are added
	Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Name -QueryExpression "$WqlExpr" -RuleName $Name2

	# Modify the Maintenance Window start string
	$NewDate = Get-Date -format d
	$NewHour = $StartHour -replace "00$", ""
	If ($NewHour -lt 12){$ampm = "AM"}
	Else {$ampm = "PM"}
	$MWstart = $NewDate + " " + $NewHour + ":00" + " " + $ampm
	
	# Create the duration count for the Maintenance Window
	$DurCount = $StopHour - $StartHour
	$DurCount = $DurCount -replace "00$", ""

	# Create the Maintenance Window scheduler
	$MWSchedule = New-CMSchedule -DurationCount $DurCount `
								-DurationInterval Hours `
								-RecurCount 1 `
								-DayOfWeek $DayOfWeek `
								-WeekOrder $WeekOfMonth `
								-Start "$MWstart"
	
	# Create the Maintenence Window
	New-CMMaintenanceWindow -CollectionID $CollectID -Name $Name2 -Schedule $MWschedule

	# Update collection membership
	Invoke-CMDeviceCollectionUpdate -Name $Name
   	}
}

        # ToDo Items
        # 1. Create a new collection - DONE
        # 2. Define the limiting collection - DONE
        	# New-CMDeviceCollection -Name "CollectionName1" -LimitingCollectionName "LimitingCollection" -RefreshSchedule $Schedule1 -RefreshType Periodic
        	# Schedule to update membership
			# $Schedule1 = New-CMSchedule -Start "01/01/2014 9:00 PM" -DayOfWeek Monday -RecurCount 1 
        # 3. Create the query rule for the collection - DONE
        	# Add-CMDeviceCollectionQueryMembershipRule -RuleName �Windows 7? -Collectionname �Windows 7? -QueryExpression 
			# ? �selectSMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client 
			# from sms_r_system where OperatingSystemNameandVersion like �%Workstation 6.1%�
        # 4. Split the collection name into a format that can be used with a maintenance window - DONE
        # 5. Add the Maintenace Window to the new collection - DONE
        	# New-CMMaintenanceWindow
        # 6. Include the new collection in the parent collection - Done
        	# Add-CMDeviceCollectionIncludeMembershipRule
        
