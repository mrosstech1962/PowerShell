
$ImportFile = 'cmdbdl.csv'
$Computer = Get-WmiObject -Class Win32_ComputerSystem
$Computer = $Computer.Name

$CMDB = Select-String -Path $ImportFile -Pattern $Computer | Out-String
$CMDB = $CMDB.Trim()
$CMDB = $CMDB.split("{:}")
$ValuesCMDB = $CMDB[2].split("{,}")

$CheckKey = Test-Path HKLM:\Software\Ross\Services
If (!$CheckKey){
	New-Item -Path HKLM:\Software -Name Ross -Force;
	New-Item -Path HKLM:\Software\Ross -Name CMDB -Force
}

New-ItemProperty -Path HKLM:\Software\Ross\CMDB -Name "Computer Name" -PropertyType String -Value $ValuesCMDB[0]
New-ItemProperty -Path HKLM:\Software\Ross\CMDB -Name "Platform" -PropertyType String -Value $ValuesCMDB[1]
New-ItemProperty -Path HKLM:\Software\Ross\CMDB -Name "Operating System" -PropertyType String -Value $ValuesCMDB[2]
New-ItemProperty -Path HKLM:\Software\Ross\CMDB -Name "Owning Group" -PropertyType String -Value $ValuesCMDB[3]
New-ItemProperty -Path HKLM:\Software\Ross\CMDB -Name "Configuration Item" -PropertyType String -Value $ValuesCMDB[4]
New-ItemProperty -Path HKLM:\Software\Ross\CMDB -Name "Maintenance Window" -PropertyType String -Value $ValuesCMDB[5]

# Invoke Hardware Inventory
#$SMSCli = [wmiclass] "\\$Computer\root\ccm:SMS_Client"
#$SMSCli.TriggerSchedule("{00000000-0000-0000-0000-000000000001}")
