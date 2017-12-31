#
# _14_CreateOsImage.ps1
#

$rgName = "Test-West"
$urlOfUploadedImageVhd = "https://imagesmross.blob.core.windows.net/images/AzGoldImg.vhd"
Add-AzureRmVhd -ResourceGroupName $rgName -Destination $urlOfUploadedImageVhd -LocalFilePath "C:\AzCopy\AzureGoldImg.vhd"



$rgName = 'MrossTech-Rg'
$location = 'WestUS'
$imageName = 'azureGoldImage'
$urlOfUploadedImageVhd = "https://imagesmross.blob.core.windows.net/images/AzGoldImg.vhd"

$imageConfig = New-AzureRmImageConfig -Location $location
$imageConfig = Set-AzureRmImageOsDisk -Image $imageConfig -OsType Windows -OsState Generalized -BlobUri $urlOfUploadedImageVhd
$image = New-AzureRmImage -ImageName $imageName -ResourceGroupName $rgName -Image $imageConfig