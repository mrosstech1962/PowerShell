
# # Begin LogUpdate setup
$LogFile = "C:\Windows\CcmTemp\WlanDriverInstall.log"  #LogUpdate
$DrvrBack = "C:\Windows\CcmTemp\WLAN_Rollback"  #Driver Backup
# Function to be called on for logging

# Check to see if the rollback directory exists.
# If it doesn't exist, the script needs to exit as the Update script never ran.
If(-Not (Test-Path $DrvrBack)){
    Add-Content $LogFile "The script needs to exit as the Update script never ran."
    exit
}

function RegPoker {
    param ($valuename, $value)
        $RegNameSpace = "HKLM:\Software\CompanyNameIntel_WLAN_Update"
        Set-ItemProperty -Path $RegNameSpace -Name $valuename -value $value
}
function LogUpdate{
    Param($Status)
    function Get-TimeStamp {
        return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    }
    $Status = "$(Get-TimeStamp) $Status"
    Add-Content $LogFile $Status
}

# Determine if the wireless NIC is in use. If so, the script will exit.
If ((Get-NetAdapter | Where-Object InterfaceDescription -like '*Dual Band Wireless*').status -eq "Up"){
    LogUpdate "The wireless LAN NIC is in use. Wireless NIC drivers will not be rolled back."
    LogUpdate "The script is exiting."
    $lastexitcode = 100
    LogUpdate $lastexitcode
    exit
    }else {
        # Get-NetAdapter
        LogUpdate "The wireless LAN NIC is not in use. Wireless NIC drivers will be updated."       
    }

function Version{
    #Get preinstall driver version
    $wifi = Get-NetAdapter | Where-Object {$_.InterfaceDescription -like '*Dual Band Wireless*'}
    Return $wifi.DriverVersion
}

Set-Location $DrvrBack
$Rollback = Version
LogUpdate "The pre-rollback version is $Rollback"
LogUpdate "Starting rollback of driver."
$process = Start-Process -FilePath devcon -Wait -ArgumentList "updateni Netwtw06.inf PCI\VEN_8086" -WindowStyle Hidden  # The main installer
LogUpdate "The rollback of the WLAN driver is complete."
$Rollback2 = Version
If(-Not ($Rollback -eq $Rollback2)){
    $RegNameSpace = "HKLM:\Software\CompanyName\Intel_WLAN_Update"
    If((Test-Path $RegNameSpace)){
        RegPoker "Rollback" "True"
        Remove-ItemProperty -Path "HKLM:\Software\CompanyName\Intel_WLAN_Update" -Name "InstallSuccess"
        LogUpdate "The post-rollback version is $Rollback2"
    }else{
        LogUpdate "The current version is the same version that needed to be rolled back."
    }
}
LogUpdate ""