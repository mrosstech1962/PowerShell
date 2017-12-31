#
# _12_FileCopy.ps1
#

Convert-VHD –Path "C:\LabSource\HyperV3\VMstore\GoldImage\Virtual Hard Disks\AzureTest.vhdx" `
			–DestinationPath "C:\LabSource\HyperV3\VMstore\GoldImage\Virtual Hard Disks\AzureGold.vhd" `
			-VHDType Fixed



$rgName = "myResourceGroup"
$urlOfUploadedImageVhd = "https://mystorageaccount.blob.core.windows.net/mycontainer/myUploadedVHD.vhd"
Add-AzureRmVhd -ResourceGroupName $rgName -Destination $urlOfUploadedImageVhd `
    -LocalFilePath "C:\Users\Public\Documents\Virtual hard disks\myVHD.vhd"