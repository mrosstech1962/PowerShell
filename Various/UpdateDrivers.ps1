
# Last exit code
# 100 - Wireless NIC in use
# 200 - Driver was updated
# 300 - Driver was not updated
# 400 - Not an HP laptop

# # Begin LogUpdate setup
$LogFile = "C:\Windows\CcmTemp\WlanDriverInstall.log"  #LogUpdate
$DrvrBack = "C:\Windows\CcmTemp\WLAN_Rollback"  #Driver Backup

# Function to be called on for logging
function LogUpdate{
    Param($Status)
    function Get-TimeStamp {
        return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    }
    $Status = "$(Get-TimeStamp) $Status"
    Add-Content $LogFile $Status
}

# Create the Ccmtemp log directory if it does not exist
If (-Not (Test-Path "C:\Windows\CcmTemp")){
    New-Item -Path $Env:SystemRoot -Name "CcmTemp" -ItemType "directory"
    LogUpdate "The logging directory has been created."  
} else {
    LogUpdate "The logging directory exists."
}

# Begin RegPoker setup
$RootKey = "HKLM:\Software"   #RegPoker
$CompanyKey = "HKLM:\Software\CompanyName"   #RegPoker
$AppName = "Intel_WLAN_Update"   #RegPoker
$Global:RegNameSpace = Join-Path $CompanyKey $AppName   #RegPoker
#Create top level key
If (-Not (Test-Path $CompanyKey)){
    New-Item -Path $RootKey -Name CompanyName
}
#Create app level key
If (-Not (Test-Path $RegNameSpace)){
    New-Item -Path $CompanyKey -Name $AppName
}
function RegPoker {
    param ($valuename, $value)
        Set-ItemProperty -Path $RegNameSpace -Name $valuename -value $value
}

# Create the WLAN Rollback directory if it does not exist
If (-Not (Test-Path $DrvrBack)){
    New-Item -Path "C:\Windows\CcmTemp" -Name "WLAN_Rollback" -ItemType "directory"
    LogUpdate "The rollback directory has been created." 
} else {
    LogUpdate "The rollback directory exists."
}

# Determine if the wireless NIC is in use. If so, the script will exit.
If ((Get-NetAdapter | Where-Object InterfaceDescription -like '*Dual Band Wireless*').status -eq "Up"){
    LogUpdate "The wireless LAN NIC is in use. Wireless NIC drivers will not be updated."
    LogUpdate "The script is exiting."
    exit
}else {
    # Get-NetAdapter
    LogUpdate "The wireless LAN NIC is not in use. Wireless NIC drivers will be updated if the OS is at Win10 1809."       
}

# Determine if the OS is version 1809. If so, the script will exit.
$osver = [System.Environment]::OSVersion.Version.Build
If ($osver -le "16299"){
    LogUpdate "The Operating System is Win10 1709 or less. It needs to be at 1809 for the drivers to install."
    LogUpdate "The script is exiting."
    exit
}else {
    LogUpdate "The OS version is Win10 1809. Wireless NIC drivers will be updated."       
}

#Get preinstall driver version
$wifi = Get-NetAdapter | Where-Object {$_.InterfaceDescription -like '*Dual Band Wireless*'}
RegPoker "AdapterName" $wifi.InterfaceDescription
$CurrentVersion = $wifi.DriverVersion
LogUpdate "The preinstall version of the WLAN driver is: $CurrentVersion"
RegPoker "PreInstallVersion" $CurrentVersion

# Backup the drivers
$DriverRepository = "C:\Windows\System32\DriverStore\FileRepository"
$DriverDirs = Get-ChildItem -Path $DriverRepository
ForEach ($dir in $DriverDirs){
    $ChkDir = Join-path $DriverRepository $dir.name
    $DriverFiles = Get-ChildItem -Path $ChkDir
    ForEach ($file in $DriverFiles){
        If ($file.Name -like '*.sys'){
            $FilePath = Join-Path $ChkDir $file.name
            $FileVerCheck = (Get-Item $FilePath).VersionInfo.FileVersion
            If ($FileVerCheck -eq $CurrentVersion){
                Copy-Item -Path $ChkDir\* -Destination $DrvrBack -Force
                LogUpdate "The rollback drivers have been found here: $FilePath"
                LogUpdate "The rollback drivers have been backed up to $DrvrBack"
                RegPoker "RollbackLocation" $DrvrBack
                Copy-Item "devcon.exe" $DrvrBack
                Copy-Item "RollBackDrivers.ps1" $DrvrBack
                Copy-Item "SCCM_Rollback.bat" $DrvrBack
                Copy-Item "CMtrace.exe" $DrvrBack
            }
        }
    }  
}

# Update the WLAN drivers
$HPmodel = (Get-WmiObject -Class:Win32_ComputerSystem).model
If ($HPmodel -like '*HP EliteBook*'){
    LogUpdate "$HPmodel is the discovered HP model"
    RegPoker "HPModel" $HPmodel

    Enable-ComputerRestore -Drive "C:\"
    Checkpoint-Computer -Description "WLAN Driver Update" -RestorePointType DEVICE_DRIVER_INSTALL
    RegPoker "Restore Point" "Created"
    LogUpdate "A restore point has been created called WLAN Driver Update"
    Start-Sleep -s 15

    $process = Start-Process -FilePath devcon -Wait -ArgumentList "updateni Netwtw06.inf PCI\VEN_8086" -WindowStyle Hidden  # The main installer
 
    #Check to see if the driver was updated
    $wifi = Get-NetAdapter | Where-Object {$_.InterfaceDescription -like '*Dual Band Wireless*'}
    $UpdatedVersion = $wifi.DriverVersion
    $ExpectedVersion = "10.70.10.2"

    #Compare the previous version with the installed version
    If (([System.Version]$UpdatedVersion -gt [System.Version]$CurrentVersion)){
        LogUpdate "The WLAN updated version is $UpdatedVersion and is upgraded from $CurrentVersion ."
        RegPoker "UpdatedVersion" $UpdatedVersion
        RegPoker "InstallSuccess" "Success"
        RegPoker "Rollback" "NotAttempted"
    }elseif ([System.Version]$UpdatedVersion -eq [System.Version]$ExpectedVersion) {
        LogUpdate "The expected driver version was already installed."
        RegPoker "InstallSuccess" "Success"
        RegPoker "InstallStatus" "NoChange"
    }else {
        LogUpdate "The WLAN driver failed to update."
        RegPoker "InstallStatus" "Failed to update."
    }
}else {
    LogUpdate "The laptop is not a G3, G4, or a G5."
    RegPoker "InstallStatus" "NoData"
}
LogUpdate ""
$Date = Get-Date
RegPoker "InstallDate" $Date