#the purpose of this script is to automate the provisioning and deployment of a public facing firewall. 
#the firewall will have public (internet facing, front end) network interface and a backend internally facing network interface.

# 1. create the VM for FW
# 2. create two network interfaces and assign to the FW
# 3. create the routing tables for the frontend and backend subnets
$ErrorActionPreference = 'stop'
function CreateAzureFW ($VMData) {
    if (!($VMData)) {
        Write-Output "no parameters specified for VM"
        exit
    }

    #create a new resource group for the firewall
    $existingRG = get-AzureRmResourceGroup -Name $VMData.resourcegroupname -Location $VMData.location
    if($existingRG){
        Write-Output "A resource group already exists with name $($VMdata.resourcegroupname). Addiing this resource group to the VM configuration."
    }else{
        New-AzureRmResourceGroup -Name $VMData.resourcegroupname -Location $VMData.location
    }

    ##networking details
    # create a Virtual Network using the VnetName in the hash table paremeter.
    # if such a vnet already exists then skip this step, and add the VM to the existing Vnet.
    $existingVnet = Get-AzureRmVirtualNetwork -Name $VMdata.VnetName -resourcegroupname $VMData.resourcegroupname -ErrorAction SilentlyContinue
    if($existingVnet){
        Write-Output "A virtual network with the name $($VMData.vnetname) in resource group $($VMData.$VMData.resourcegroupname) already exists. Adding the existing Vnet to the VM configuration."
        $vnet = $existingVnet
    }else{
        $vnet = New-AzureRmVirtualNetwork -Name $VMData.vnetname -resourcegroupname $VMData.resourcegroupname`
            -Location $VMData.location -AddressPrefix $VMData.vnetAddressPrefix
        Write-Output "Creating new Virtual Network with name $($VMData.vnetName) in the $($VMData.resourcegroupname) resource group."
    }

    #Create public (frontend) facing subnet in virtual network.
    #if such a subnet already exists then add it to the FW configuration.
    $existingPublicVsubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $VMData.PublicfacingSubnetName -ErrorAction SilentlyContinue
    if($existingPublicVsubnet){
        $publicVsubnet = $existingPublicVsubnet
        Write-Output "A virtual subnet with the name $($VMData.PublicfacingSubnetName) in resource group $($VMData.resourcegroupname) already exists within the $($vnet.name) virtual network. Adding this subnet to the VM configuration."
    }else{
        Add-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $VMData.PublicfacingSubnetName -AddressPrefix $VMData.PublicSubnetAddressPrefix
        $vnet | Set-AzureRmVirtualNetwork
        $publicVsubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $VMData.PublicfacingSubnetName
        Write-Output "New Subnet has been created with name $($VMData.PublicfacingSubnetName) in resource group $($VMData.resourcegroupname) and $($vnet.name) Virtual Network."
    }

    #Create private (backend) facing subnet in virtual network.
    #if such a subnet already exists then add it to the FW configuration.
    $existingPrivateVsubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $VMData.PrivatefacingSubnetName -ErrorAction SilentlyContinue
    if($existingPrivateVsubnet){
        $privateVsubnet = $existingprivateVsubnet
        Write-Output "A virtual private subnet with the name $($VMData.PrivatefacingSubnetName) in resource group $($VMData.resourcegroupname) already exists within the $($vnet.name) virtual network. Adding this subnet to the VM configuration."
    }else{
        Add-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $VMData.PrivatefacingSubnetName -AddressPrefix $VMData.PrivateSubnetAddressPrefix
        $vnet | Set-AzureRmVirtualNetwork
        $privateVsubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $VMData.PrivatefacingSubnetName
        Write-Output "New Subnet has been created with name $($VMData.PrivatefacingSubnetName) in resource group $($VMData.resourcegroupname) and $($vnet.name) Virtual Network."
    }

    #create a new network security group using the hash table parameter
    #if a network security group already exists with the parameters above, Then create the NSG rule to allow RDP to the VM and add it to the newly created NSG.
    $existingNSG = Get-AzureRmNetworkSecurityGroup -Name $VMData.NSGName -resourcegroupname $VMData.resourcegroupname -ErrorAction SilentlyContinue
    if($existingNSG){
        Write-Output "A network security group with name $($VMData.nsgname) already exists in $($VMData.resourcegroupname) resource group. Adding this network security group to the VM configuration."
        $networkSG = $existingNSG
    }else{
        $networkSG = New-AzureRmNetworkSecurityGroup -Name $VMData.NSGName -resourcegroupname $VMData.resourcegroupname -Location $VMData.location
        Write-Output "A Network Security Group has been created in $($VMData.resourcegroupname) resource group."

        Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $networkSG -Name $VMData.NSGRDPRuleName -Access Allow `
            -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet `
            -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Description $Vmdata.NSGRuleDesc
        Write-Output "NSG rule created in $($VMData.resourcegroupname) resource group that $($VMData.nsgruledesc). It has been added to the $($networkSG.Name) Network Security Group"
    }

    #create a public IP address for the front end of the VM. 
    #If a public IP address already exists then add it to the VM configuration
    $existingPublicIP = Get-AzureRmPublicIpAddress -resourcegroupname $VMData.resourcegroupname -Name $VMData.Publicipname -ErrorAction SilentlyContinue
    if($existingPublicIP){
        $PublicIP = $existingPublicIP
        Write-Output "A Public IP with name $($VMdata.publicIPname) already exists in $($VMData.resourcegroupname) resource group. Adding this IP to the VM configuration." 
    }else{
        $PublicIP = New-AzureRmPublicIpAddress -Name $vmdata.publicIPname -ResourceGroupName $vmdata.resourcegroupname -Location $VMData.location -AllocationMethod $VMData.PublicIPAllocation
        Write-Output "Public IP address resource has been created with name $($VMData.publicipname) in $($VMData.resourcegroupname) resource group for the VM."
    }

    #assign a private IP address to the private (backend) subnet for the VM
    # $existingPrivateIP = Get-AzureRmPublicIpAddress -resourcegroupname $VMData.resourcegroupname -Name $VMData.Privateipname -ErrorAction SilentlyContinue
    # if($existingPrivateIP){
    #     $PrivateIP = $existingPrivateIP
    #     Write-Output "A Private IP with name $($VMdata.privateIPname) already exists in $($VMData.resourcegroupname) resource group. Adding this IP to the VM configuration." 
    # }else{
    #     $PublicIP = New-AzureRmPublicIpAddress -Name $vmdata.privateIPname -ResourceGroupName $vmdata.resourcegroupname -Location $VMData.location -AllocationMethod $VMData.PrivateIPAllocation
    #     Write-Output "Public IP address resource has been created with name $($VMData.privateipname) in $($VMData.resourcegroupname) resource group for the VM."
    # }

    # Check if a public network interface is present in the resource group. 
    # If not then create the interface using the networking details and assign to public front end of VM.
    $existingPublicNI = Get-AzureRmNetworkInterface -resourcegroupname $VMData.resourcegroupname -Name $VMData.PublicNIName -ErrorAction SilentlyContinue
    if ($existingPublicNI) {
        Write-Output "Network interface already exists in the $($VMData.resourcegroupname) resource group with name $($VMData.PublicNIName). Adding to VM configuration."
        $PublicNI = $existingPublicNI
    }else{
        #create public Network interface
        $PublicNI = New-AzureRmNetworkInterface -Name $VMData.PublicNIName -resourcegroupname $VMData.resourcegroupname -Location $VMData.location `
            -SubnetId $publicVsubnet.Id -PublicIpAddressId $PublicIP.Id -NetworkSecurityGroupId $networkSG.Id -EnableIPForwarding
        Write-Output "A new Public Network Interface has been created with the name $($VMData.PublicNIName) in $($VMData.resourcegroupname) resource group."
    }

    # Check if a private network interface is present in the resource group. 
    # If not then create the interface using the networking details and assign to private backend of VM.
    $existingPrivateNI = Get-AzureRmNetworkInterface -resourcegroupname $VMData.resourcegroupname -Name $VMData.PrivateNIName -ErrorAction SilentlyContinue
    if ($existingPrivateNI) {
        Write-Output "Network interface already exists in the $($VMData.resourcegroupname) resource group with name $($VMData.PrivateNIName). Adding to VM configuration."
        $PrivateNI = $existingPrivateNI
    }else{
        #create public Network interface
        $PrivateNI = New-AzureRmNetworkInterface -Name $VMData.PrivateNIName -resourcegroupname $VMData.resourcegroupname -Location $VMData.location `
            -SubnetId $privateVsubnet.Id -PrivateIpAddress $VMData.PrivateIPAddress -NetworkSecurityGroupId $networkSG.Id -EnableIPForwarding
        Write-Output "A new Public Network Interface has been created with the name $($VMData.PrivateNIName) in $($VMData.resourcegroupname) resource group."
    }

    #check if a storage account exists in resource group.
    #if one already exists then use it for the VM configuration.
    $existingStorageAcc = Get-AzureRmStorageAccount -ResourceGroupName $VMData.resourcegroupname -Name $VMData.StorageAccountName -ErrorAction SilentlyContinue
    if($existingStorageAcc){
        $storageAcc = $existingStorageAcc
        Write-Output "A storage account already exists with name $($vmdata.storageaccountname) in resource group $($vmdata.resourcegroupname). Adding it to the VM configuration. "
    }else{
        $storageAcc = New-AzureRmStorageAccount -ResourceGroupName $VMData.resourcegroupname -Name $VMData.storageaccountname -Location $VMData.location -SkuName $VMData.StorageSkuName
        Write-Output "A new storage account has been created with name $($vmdata.storageaccountname) and SKU name $($VMData.StorageSkuName)."
    }

    # Create the VM if no such VM exists with the name and resource group specified in the parameters above. 
    $existingVM = Get-AzureRmVm -resourcegroupname $VMData.resourcegroupname -Name $VMData.VMName -ErrorAction SilentlyContinue
    if($existingVM){
        Write-Output "A VM with the name $($VMData.vmname) in $($VMData.resourcegroupname) resource group already exists"
    }else{
        $vmconfig = New-AzureRmVMConfig -VMName $VMData.VMName -VMSize $VMData.VMSize
        #before adding components of the VM, set the plan for the VM.... because Microsoft
        Set-AzureRmVMPlan -VM $vmConfig -Name $VMData.imageSkus -Publisher $VMData.imagePublisher -Product $VMData.imageOffer
        #set the OS and image properties of the VM
        Set-AzureRmVMOperatingSystem -VM $vmConfig -Linux -Credential $VMData.VMAdminAccCreds -ComputerName $VMData.VMName
        Set-AzureRmVMSourceImage -VM $vmConfig -PublisherName $VMData.imagePublisher -Offer $VMData.imageOffer -Skus $VMData.imageSkus -version latest
        Set-AzureRmVMOSDisk -VM $vmConfig -Name $VMData.OSDiskName -Linux -StorageAccountType $VMData.StorageSkuName -Caching ReadWrite -CreateOption fromimage
        #add the network interfaces
        Add-AzureRmVMNetworkInterface -VM $vmConfig -NetworkInterfaceId $PublicNI.Id -Primary
        Add-AzureRmVMNetworkInterface -VM $vmConfig -NetworkInterfaceId $PrivateNI.Id
        #add the purchase requirements
        Get-AzureRmMarketplaceTerms -Publisher $VMData.imagePublisher -Product $VMData.imageOffer  -Name $VMData.imageSkus  | Set-AzureRmMarketplaceTerms -Accept
        New-AzureRmVM -resourcegroupname $VMData.resourcegroupname -Location $VMData.location -VM $vmConfig
        Write-Output "Virtual Machine $($VMData.vmname) has been built using values from hash table data."
    }
}

Login-AzAccount -Credential (Get-Credential 'iabdella@edc.ca' -Message "enter azure credentials")

#default OS is linux
$FirewallData = @{
    #cloud data
    resourcegroupname = "FirewallRG"
    VMAdminAccCreds = (Get-Credential iymenabdella -Message "Provide credentials for the admin account on the VM")
    Location = "East US"
    ##network data
    #network topology data
    VnetName = "AzureFirewallSubnet" 
    vnetAddressPrefix =  "10.2.0.0/16"
    PublicfacingSubnetName = "FrontEndSubnet"
    PublicSubnetAddressPrefix = "10.2.2.0/24"
    PrivateFacingSubnetName = "BackEndSubnet"
    PrivateSubnetAddressPrefix = "10.2.1.0/24"
    #network security group data
    NSGName = "MyNetworkSecurityGroup"
    NSGRDPRuleName = "My NSG RDP Rule"
    NSGRuleDesc = "allow RDP to the VM through Backend subnet" #same rule as other RG, but good enough. Allows any-2-any on same vnet
    #image data
    VMSize = "Standard_A4"
    VMName = "WindowsFirewall"
    imagePublisher = "Fortinet"
    imageOffer = "fortinet_fortigate-vm_v5"
    imageSkus = "fortinet_fg-vm_payg"
    #Public IP addressing data
    Publicipname = "PublicFWIP"
    PublicIPAllocation = "Dynamic"
    #Private IP addressing Data
    PrivateIPName = "PrivateFWIP"
    PrivateIPAllocation = "Dynamic"
    PrivateIPAddress = "10.2.1.5"
    #network interface data
    PublicNIName = "FrontEndNetworkInterface" #default primary network interface is public
    PrivateNIName = "BackEndNetworkInterface" 
    #storage account data
    StorageAccountName = "fortigatestorageaccount" #lower case letters and numbers only
    StorageSkuName = "Standard_LRS"
    StorageAccountType = "StandardLRS"
    OSDiskName = "WinFirewallOSDisk"
}

CreateAzureFW -VMData $FirewallData