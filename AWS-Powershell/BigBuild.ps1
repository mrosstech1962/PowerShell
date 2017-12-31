Import-Module awspowershell
Initialize-AWSDefaults -ProfileName YourAWSProfile -Region us-east-1

function Tagger{
    param ($TagValue, $ResId, $TagClass)
	$Tag1 = New-Object amazon.EC2.Model.Tag
	$Tag1.Key = 'Name'
	$Tag1.Value = $TagValue
	
	$Tag2 = New-Object amazon.EC2.Model.Tag
	$Tag2.Key = 'Class'
	$Tag2.Value = $TagClass
	
	New-EC2Tag -ResourceID $ResId -Tag @($Tag1, $Tag2)
}

# This function ties cidrblocks to ports within security groups
function Porter{
    param ($Port, $CidrB, $SecGroup)
    $ip = New-Object Amazon.EC2.Model.IpPermission
    $ip.IpProtocol = "tcp"
    $ip.FromPort = $Port
    $ip.ToPort = $Port
    $ip.IpRanges.Add($CidrB)
    Grant-EC2SecurityGroupIngress -GroupId $SecGroup -IpPermissions $ip
}

# Create the new VPC and tag it
$vpcid = New-EC2Vpc -CidrBlock 10.0.0.0/16 -Force
$vpcid = $vpcid.VpcID
Tagger 'RossCo-VPC' $vpcid "VPC"

# Get the new route table ID and tag it
$vpcrt = Get-EC2RouteTable | Where-Object {$_.VpcId -eq $vpcid}
$vpcrt = $vpcrt.RouteTableId
Start-Sleep -Seconds 2
Tagger 'RossCo-MainRT' $vpcrt 'RouteTable'

#Create and tag a public route table
$PublicRT = New-EC2RouteTable -VpcID $vpcid -Force
$PublicRT = $PublicRT.RouteTableId
Start-Sleep -Seconds 2
Tagger 'RossCo-PublicRT' $PublicRT 'RouteTable'

#Tag the new network ACL
$VpcACL = Get-EC2NetworkAcl | Where-Object {$_.VpcId -eq $vpcid}
$VpcACL = $VpcACL.NetworkAclId
Start-Sleep -Seconds 2
Tagger 'RossCo-NetACL' $VpcACL 'ACL'

#Tag the new security group
$VpcSG = Get-EC2SecurityGroup | Where-Object {$_.VpcId -eq $vpcid}
$VpcSG = $VpcSG.GroupId
Start-Sleep -Seconds 2
Tagger 'RossCo-SG' $VpcSG 'SecurityGroup'

#Create and tag the Internet Gateway
$VpcIgw = New-EC2InternetGateway
$VpcIgw = $VpcIgw.InternetGatewayId
Start-Sleep -Seconds 2
Tagger 'RossCo-IGW' $VpcIgw 'InternetGateway'

#Attach the Internet Gateway to the VPC
Add-EC2InternetGateway -VpcId $vpcid -InternetGatewayId $VpcIgw

# Add the IGW route to the Public Route Table
New-EC2Route -RouteTableId $PublicRT -DestinationCidrBlock 0.0.0.0/0 -GatewayId $VpcIgw

# ----------------------------------------------------
# Create a subnet in each availability zone where the first zone is
# identified as public and the remaining subnets are identified as private
# ----------------------------------------------------

$AvZones = Get-EC2AvailabilityZone
$OctetId = 0
$CidrBlocks = @()
$PrivSubIDs = @()
foreach ($ZN in $AvZones){
	# Iterate through all AZ's in the region
    $ZoneName = $ZN.ZoneName
    $PubPriv = "Priv"
    $OctetId ++
    If ($OctetId -eq 1){$PubPriv = "Pub"} # Labeling the public subnet
        $SubName = $PubPriv + "-Sub" + "-10.0." + $OctetId # Labeling the public subnet
        $Cidr = "10.0." + $OctetId + ".0/24"
    
    If ($OctetId -gt 1){$CidrBlocks += $Cidr} # Stores private subnets Cidr's for main route table
    Else {$PubCidr = $Cidr} # Stores the public Cidr
    
    $NewSub = New-EC2Subnet -VpcId $vpcid `
                            -CidrBlock $cidr `
                            -AvailabilityZone $ZoneName
    $NewSub = $NewSub.SubnetId # Grabbing the new object Id for tagging
    Start-Sleep -Seconds 2
    Tagger $SubName $NewSub 'Subnet'
    
    If ($OctetId -eq 1){$PubSubID = $NewSub} # Identifies the public subnet ID
    Else {$PrivSubIDs += $NewSub}
	}

# Create and onfigure ports on the NAT security group so that Internet traffic gets to the private subnets
$NatSG = New-EC2SecurityGroup -GroupName NatSG -VpcId $vpcid -Description "Permits internet traffic to the private subnets from the NAT."
Start-Sleep -Seconds 2
Tagger 'RossCo-NAT-SG' $NatSG 'SecurityGroup'
Porter "80" $CidrBlocks[0] $NatSG
Porter "443" $CidrBlocks[0] $NatSG
Porter "80" $CidrBlocks[1] $NatSG
Porter "443" $CidrBlocks[1] $NatSG

# Create and onfigure ports on the PubPriv security group so that Internet and remote traffic gets to all servers
$PubPrivSG = New-EC2SecurityGroup -GroupName PubPrivSG -VpcId $vpcid -Description "Permits SSH and internet traffic for Pub/Priv instances."
Start-Sleep -Seconds 2
Tagger 'RossCo-PubPriv-SG' $PubPrivSG 'SecurityGroup'
Porter "80" "0.0.0.0/0" $PubPrivSG
Porter "443" "0.0.0.0/0" $PubPrivSG
Porter "22" "0.0.0.0/0" $PubPrivSG
Porter "3389" "0.0.0.0/0" $PubPrivSG

# Create the NAT instance
$NewNatId = New-EC2Instance -ImageId 'ami-184dc970' `
                            -InstanceType 't2.micro' `
                            -SubnetId  $PubSubID `
                            -MinCount 1 `
                            -MaxCount 1 
                            -KeyName 'EC2KeyPair' `
                            -AssociatePublicIP $false `
                            -SecurityGroupId $NatSG
$NewNatId = $NewNatId.runninginstance[0].instanceID
Start-Sleep -Seconds 2
Tagger 'RossCo-NAT' $NewNatId 'NAT'
Write-Host "Linux NAT      : " $NewNatId

# Create the Bastion instance
$NewWebId = New-EC2Instance -ImageId 'ami-08111162' `
                            -InstanceType 't2.micro' `
                            -SubnetId  $PubSubID `
                            -MinCount 1 -MaxCount 1 `
                            -KeyName 'EC2KeyPair' `
                            -InstanceProfile_Name 'S3-Admin-Access' `
                            -AssociatePublicIP $true `
                            -EncodeUserData `
                            -UserDataFile 'ec2_boot.txt' `
                            -SecurityGroupId $PubPrivSG
$NewWebId = $NewWebId.runninginstance[0].instanceID
Tagger 'RossCo-Lin-Bastion' $NewWebId 'Bastion'
Start-Sleep -Seconds 2
Write-Host "Linux Bastion  : " $NewWebId

# Create a private instance
$NewWebId = New-EC2Instance -ImageId 'ami-08111162' `
                            -InstanceType 't2.micro' `
                            -SubnetId  $PrivSubIDs[0] `
                            -MinCount 1 `
                            -MaxCount 1 `
                            -KeyName 'EC2KeyPair' `
                            -InstanceProfile_Name 'S3-Admin-Access' `
                            -AssociatePublicIP $false `
                            -EncodeUserData `
                            -UserDataFile 'ec2_boot.txt' `
                            -SecurityGroupId $PubPrivSG
$NewWebId = $NewWebId.runninginstance[0].instanceID
Tagger 'RossCo-Lin-Priv-1' $NewWebId 'PrivateWeb'
Start-Sleep -Seconds 2
Write-Host "Linux Private 1: " $NewWebId

# Create a private instance
$NewWebId = New-EC2Instance -ImageId 'ami-08111162' `
                            -InstanceType 't2.micro' `
                            -SubnetId  $PrivSubIDs[1] `
                            -MinCount 1 `
                            -MaxCount 1 `
                            -KeyName 'EC2KeyPair' `
                            -InstanceProfile_Name 'S3-Admin-Access' `
                            -AssociatePublicIP $false `
                            -EncodeUserData `
                            -UserDataFile 'ec2_boot.txt' `
                            -SecurityGroupId $PubPrivSG
$NewWebId = $NewWebId.runninginstance[0].instanceID
Start-Sleep -Seconds 2
Tagger 'RossCo-Lin-Priv-2' $NewWebId 'PrivateWeb'
Write-Host "Linux Private 2: " $NewWebId

# Create a public Windows Bastion instance
$NewWebId = New-EC2Instance -ImageId 'ami-3d787d57' `
                            -InstanceType 't2.micro' `
                            -SubnetId  $PubSubID `
                            -MinCount 1 `
                            -MaxCount 1 `
                            -KeyName 'EC2KeyPair' `
                            -InstanceProfile_Name 'S3' `
                            -Admin-Access `
                            -AssociatePublicIP $true `
                            -SecurityGroupId $PubPrivSG
$NewWebId = $NewWebId.runninginstance[0].instanceID
Start-Sleep -Seconds 2
Tagger 'RossCo-Win-Bastion' $NewWebId 'Bastion'
Write-Host "Windows Bastion: " $NewWebId

# Create a private Windows instance
$NewWebId = New-EC2Instance -ImageId 'ami-3d787d57' `
                            -InstanceType 't2.micro' `
                            -SubnetId  $PrivSubIDs[2] `
                            -MinCount 1 `
                            -MaxCount 1 `
                            -KeyName 'EC2KeyPair' `
                            -InstanceProfile_Name 'S3-Admin-Access' `
                            -AssociatePublicIP $false `
                            -SecurityGroupId $PubPrivSG
$NewWebId = $NewWebId.runninginstance[0].instanceID
Start-Sleep -Seconds 2
Tagger 'RossCo-Win-WebTest' $NewWebId 'PrivateWeb'
Write-Host "Windows WebTest: " $NewWebId

Write-Host
Write-Host "Wait 60 seconds for the NAT instance to be ready."
Write-Host
Start-Sleep -Seconds 65

# Associate the Public Subnet with the Public Route Table
Register-EC2RouteTable -RouteTableId $PublicRT -SubnetId $PubSubID

#Allocate an Elastic IP Address. This will be associated to the NAT
$ElasIP = New-EC2Address -Force
$ElasIP = $ElasIP.AllocationId

# Associate the Elastic IP to the NAT
Register-EC2Address -InstanceId $NewNatId -AllocationId $ElasIP

# Disable Source/Dest Check on the NAT
Edit-EC2InstanceAttribute -InstanceId $NewNatId -SourceDestCheck $false

# Create a route in the Main route table to allow the NAT to get inbound traffic from the Internet
New-EC2Route -RouteTableId $vpcrt -DestinationCidrBlock '0.0.0.0/0' -InstanceId $NewNatId
