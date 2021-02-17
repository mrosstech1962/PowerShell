# This script was used to add the primary user of a laptop to the local admins group
# With the primary user confirmed in the local admin group, the Interactive user was removed from the local admins group
# The Interactive user was added to the local admin group via a GPO, which was now turned off.
# This was done to give all Windows 10 laptop users local admin rights
# That security policy was being revoked and this script was deployed by SCCM as part of the process to increase security.

# # Begin LogUpdate setup
$LogFile = "C:\Windows\CcmTemp\InterActiveUser.log"  #LogUpdate

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
$AppName = "InterActiveUser"   #RegPoker
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

$IndexFile = "ComputerUser.csv"
$LoggedOnUser = Get-WmiObject Win32_Process -Filter "Name='explorer.exe'" | ForEach-Object { $_.GetOwner() } | Select-Object -Unique -Expand User
$QualifiedLoggedOnUser = "ADdomain\" + $LoggedOnUser
LogUpdate "Logged On User: $LoggedOnUser"
RegPoker "User" $LoggedOnUser
$LoggedOnCumputer = $env:ComputerName
LogUpdate "Logged On Computer: $LoggedOnCumputer"
RegPoker "Computer" $LoggedOnCumputer

$Index = 0
$csv = Get-Content $IndexFile
ForEach ($row in $csv){
    If(Select-String -Pattern $LoggedOnUser -InputObject $row){
        LogUpdate "The logged on user is in the index."
        $CheckGroup = Get-LocalGroupMember -Group "Administrators" -Member $QualifiedLoggedOnUser -ErrorAction 'SilentlyContinue'
        If (!$CheckGroup){
            LogUpdate "The user needs to be added to the local admins group."
            If(Select-String -Pattern $LoggedOnCumputer -InputObject $row){
                LogUpdate "This computer is in the index."
                LogUpdate "Confirmed: The defined user and computer in the index file applies to this computer."
                Add-LocalGroupMember -Group "Administrators" -Member $QualifiedLoggedOnUser
                $CheckGroup = Get-LocalGroupMember -Group "Administrators" -Member $QualifiedLoggedOnUser -ErrorAction 'SilentlyContinue'
                If ($CheckGroup){
                    LogUpdate "$QualifiedLoggedOnUser has been added to the local admins group."
                    RegPoker "MemberShip" "Added"
                    Remove-LocalGroupMember -Group "Administrators" -Member "NT Authority\Interactive" -ErrorAction 'SilentlyContinue'
                    LogUpdate "Removed NT Authority\Interactive from local administrators group."
                    $Index = 1
                    LogUpdate ""
                    $Date = Get-Date
                    RegPoker "InstallDate" $Date
                    Exit
                }
                Else {Write-Host "$QualifiedLoggedOnUser was not added to the local admins group"
                    RegPoker "MemberShip" "Failed to add the logged on user to the local admins group"
                }
            }
        }Else {$CheckGroup = Get-LocalGroupMember -Group "Administrators" -Member "NT Authority\Interactive" -ErrorAction 'SilentlyContinue'
            If ($CheckGroup){
                Remove-LocalGroupMember -Group "Administrators" -Member "NT Authority\Interactive" -ErrorAction 'SilentlyContinue'
            }
        }
    }
}

If ($Index = 0) {LogUpdate "The computer and user defined in the index file does not apply to this computer."}
LogUpdate ""
$Date = Get-Date
RegPoker "InstallDate" $Date
