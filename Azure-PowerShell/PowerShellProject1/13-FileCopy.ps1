#
# FileCopy.ps1
#
Login-AzureRmAccount

$ResourceGroup = 'MrossTech-Rg'
$location = 'WestUS'
$storAcnt = "imagesmrosstech"
$SkuName = "Standard_LRS"
$blobCont = 'rosstest'
$fileShare = "entfiles"
$fileDir = "stuff"

New-AzureRMStorageAccount -Location $location ` -ResourceGroupName $ResourceGroup -Type $SkuName -Name $storAcnt

Get-AzureRmStorageAccount -ResourceGroup $ResourceGroup -StorageAccountName $storAcnt

$storKey = (Get-AzureRmStorageAccountKey -Name $storAcnt -ResourceGroupName $ResourceGroup ).value[0]

# The piped command works, but in order to run the New-AzureStorageContainer or Get, you must have context
Get-AzureRmStorageAccount -ResourceGroup $ResourceGroup -StorageAccountName $storAcnt

# Setting Context
$ctx = New-AzureStorageContext -StorageAccountName $storAcnt -StorageAccountKey $storKey

New-AzureStorageContainer -Name $blobCont -Context $ctx -Permission Off

# Get info on the container
Get-AzureStorageContainer -Name $blobCont -Context $ctx

Set-AzureStorageBlobContent -Container $blobCont -Context $ctx -File "C:\Azure\azure-ops-guide.pdf" -Blob "azure-ops-guide.pdf"

#Now we will create a share and upload content.

New-AzureStorageShare -Name $fileShare -Context $ctx

New-AzureStorageDirectory -ShareName $fileShare -Context $ctx -Path stuff

Set-AzureStorageFileContent -ShareName $fileShare -Context $ctx -Source "C:\Azure\azure-ops-guide.pdf" -Path $fileDir

# net use H: \\imagesmrosstech.file.core.windows.net\entfiles  /u:AZURE\imagesmrosstech PUQ2rsKboe6Hl2IOtALnhoMXZT1jd7S0adptXalXe5djoG1R4JDGqWbMSTQI8HLKnBJJfOinViOpCs3/dK05uw==

# Upload from local file system
AzCopy /Source: "C:\LabSource\HyperV3\VMstore\GoldImage\Virtual Hard Disks\AzureGoldImg.vhd" /Dest: https://imagesmross.blob.core.windows.net/images /DestKey:ZqstNGEBYJl45G47mlQpJ7fuP2Ej0U+mB0eBnvgcPb4q/Sa47H1qiQXdiOZyc9pBMdhUg9JEeoAUjqtLdQFC+A== /S

AzCopy /Source:"C:\Azure" /Dest:https://imagesmross.blob.core.windows.net/images  /DestKey:ZqstNGEBYJl45G47mlQpJ7fuP2Ej0U+mB0eBnvgcPb4q/Sa47H1qiQXdiOZyc9pBMdhUg9JEeoAUjqtLdQFC+A== /Pattern:"AzureGoldImg.vhd" /S


AzCopy /Source:https://imagesmross.blob.core.windows.net/rosstest /SourceKey:ZqstNGEBYJl45G47mlQpJ7fuP2Ej0U+mB0eBnvgcPb4q/Sa47H1qiQXdiOZyc9pBMdhUg9JEeoAUjqtLdQFC+A== /Dest:https://remotemrosstech.blob.core.windows.net/images /DestKey:Mj9Jm09YeBxb6IwgG6B3IOunaJuL7M1G/mM3jl27OLmQz4v0PTCrIlWMjL3hsyZd13rhRUbsv8J/MNEBc1NK5g== /Pattern:"azure-ops-guide.pdf" /S
