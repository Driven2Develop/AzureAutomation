#the purpose of this script is to create one Win 2012R2 Server in azure. 
#They will be created in the resource group: AzureAutomationDscRG.
$ErrorActionPreference = 'stop'
Import-Module AzureRM
Login-AzAccount -Credential (Get-Credential "iabdella@edc.ca" -Message "Provide credentials for azure login")

$resourceGroupname = "AzureAutomationDscRG"
$cred = Get-Credential iymenabdella -Message "Provide a password for the VM"
$location = "East US" 
$SubnetName = "MyVsubnet"
$VnetName = "MyVnet"
$subnetAddressPrefix = "10.1.1.0/24"
$vnetAddressPrefix = "10.1.0.0/16"
$NSGName = "MyNetworkSecurityGroup"
$VMSize = "Standard_A1"
$VMName = "TestWinServer1"
$PubIPName = "MyPublicIP"
$NSGRDPRuleName = "My NSG RDP Rule"
$imagePublisher = "MicrosoftWindowsServer"
$imageOffer = "windowsserver"
$imageSkus = "2012-R2-Datacenter"
$VMNICName = "MyWinServerInt"
$NSGRuleDesc = "allow RDP to the VM through public facing IP"

##networking details
#create a Virtual Network using the name in the parameter list above, if such a vnet already exists then skip this step.
$existingVnet = Get-AzureRmVirtualNetwork -Name $VnetName -ResourceGroupName $resourceGroupname -ErrorAction SilentlyContinue
if($existingVnet){
    Write-Output "A virtual network with the name $vnetname in resource group $resourcegroupname already exists."
    $vnet = $existingVnet
}else{
    $vnet = New-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $resourceGroupname`
        -Location $location -AddressPrefix $vnetAddressPrefix
    Write-Output "Creating new Virtual Network with name $vnetName in the $resourcegroupname resource group."
}

# Create a virtual subnet in the Virtual network using the name in the parameter list above.
# If such a subnet already exists then skip this step.
# Then add the subnet to the virtual network specified above.
$existingVsubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $SubnetName -ErrorAction SilentlyContinue
if($existingVsubnet){
    Write-Output `
    "A virtual subnet network with the name $subnetname in resource group $resourcegroupname already exists within the $($vnet.name) virtual network."
    $Vsubnet = $existingVsubnet
}else{
    Add-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $SubnetName -AddressPrefix $subnetAddressPrefix
    $vnet | Set-AzureRmVirtualNetwork
    $vsubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $SubnetName
    Write-Output "New Subnet has been created in $($vnet.name) Virtual Network."
}

#create the public IP, if one does not exist with the parameters above in the Resource group
$existingIP = Get-AzureRmPublicIpAddress -ResourceGroupName $resourcegroupname -Name $PubIPName -ErrorAction SilentlyContinue
if($existingIP){
    Write-Output "A public IP address already exists in the $resourcegroupname resource group."
    $PublicIP = $existingIP
}else{
    $PublicIP = New-AzureRmPublicIpAddress -Name $PubIPName -ResourceGroupName $resourcegroupname -Location $location -AllocationMethod Static
    Write-Output "Public IP address resource has been created in $resourcegroupname resource group for the VM."
}

#create a new network security group, if one does not already exist with the parameters above. 
#Then create the NSG rule to allow RDP to the VM and add it to the newly created NSG
$existingNSG = Get-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $resourcegroupname -ErrorAction SilentlyContinue
if($existingNSG){
    Write-Output "A network security group already exists matching the above parameters in $resourcegroupname resource group."
    $networkSG = $existingNSG
}else{
    $networkSG = New-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $resourceGroupname -Location $location
    Write-Output "NSG created in $resourcegroupname resource group."

    Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $networkSG -Name $NSGRDPRuleName -Access Allow `
    -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet `
    -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Description $NSGRuleDesc
    Write-Output "NSG rule created in $resourcegroupname resource group that $nsgruledesc. It has been added to the $($networkSG.Name) NSG"
}

# Check if a network interface resource is present in the resource group. 
# If no such resource exists, use all the networking details to create the interface that will be assigned to the VM. 
$existingNIC = Get-AzureRmNetworkInterface -ResourceGroupName $resourcegroupname -Name $VMNICName -ErrorAction SilentlyContinue
if ($existingNIC) {
    Write-Output "NIC already exists in the $resourcegroupname resource group with name $VMNICName"
    $MyNIC = $existingNIC
}else{
    $MyNIC = New-AzureRmNetworkInterface -Name $VMNICName -ResourceGroupName $resourceGroupname -Location $location `
        -SubnetId $Vsubnet.Id -PublicIpAddressId $PublicIP.Id -NetworkSecurityGroupId $networkSG.Id
    #-PublicIpAddress $PublicIP -Subnet $vsubnet -NetworkSecurityGroup $networkSG
    Write-Output "A new Network Interface has been created with the name $vmnicname in $resourcegroupname resource group."
}

# Create the VM if no such VM exists with the name and resource group specified in the parameters above. 
$existingVM = Get-AzureRmVm -ResourceGroupName $resourceGroupname -Name $VMName -ErrorAction SilentlyContinue
if($existingVM){
    Write-Output "A VM with the name $vmname in $resourcegroupname resource group already exists"
}else{
    $vmConfig = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
    Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -Credential $cred -ComputerName $VMName
    Set-AzureRmVMSourceImage -VM $vmConfig -PublisherName $imagePublisher -Offer $imageOffer -Skus $imageSkus -version latest
    Add-AzureRmVMNetworkInterface -VM $vmConfig -NetworkInterface $MyNIC
    Write-Output "VM $vmname has been configured with windows image, NIC, and windows OS."
    New-AzureRmVM -ResourceGroupName $resourceGroupname -Location $location -VM $vmConfig
}