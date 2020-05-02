#the purpose of this script is to create an azure VM using a list of formal parameters.
#The parameters will all be stored in a PS hash table. 
$ErrorActionPreference = 'stop'

function CreateAzureVM ($VMData) {
    if (!($VMData)) {
        Write-Output "no parameters specified for VM"
        exit
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

    # Create a virtual subnet in the Virtual network using the name in the paremeter hash table. 
    # If such a subnet already exists then add the existing subnet to the VM configuration. 
    # Then add the subnet to the virtual network specified above.
    $existingVsubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $VMData.SubnetName -ErrorAction SilentlyContinue
    if($existingVsubnet){
        Write-Output `
        "A virtual subnet network with the name $($VMData.subnetname) in resource group $($VMData.resourcegroupname) already exists within the $($vnet.name) virtual network. Adding this subnet to the VM configuration."
        $Vsubnet = $existingVsubnet
    }else{
        Add-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $VMData.SubnetName -AddressPrefix $VMData.subnetAddressPrefix
        $vnet | Set-AzureRmVirtualNetwork
        $vsubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $SubnetName
        Write-Output "New Subnet has been created with name $($VMData.SubnetName) in resource group $($VMData.resourcegroupname) and $($vnet.name) Virtual Network."
    }

    # create the public IP address for the VM using the hash table parameter.
    # if a public IP address already exists then skip this step and add it to the VM configuration. 
    if(!($VMdata.PrivateNetwork)){
        $existingIP = Get-AzureRmPublicIpAddress -resourcegroupname $VMData.resourcegroupname -Name $VMData.ipname -ErrorAction SilentlyContinue
        if($existingIP){
            Write-Output "A public IP address with name $($VMData.ipname) already exists in the $($VMData.resourcegroupname) resource group. Adding this public IP address to the VM configuration."
            $PublicIP = $existingIP
        }else{
            $PublicIP = New-AzureRmPublicIpAddress -Name $VMData.ipname -resourcegroupname $VMData.resourcegroupname -Location $VMData.location -AllocationMethod $VMData.IPAllocation
            Write-Output "Public IP address resource has been created with name $($VMData.ipname) in $($VMData.resourcegroupname) resource group for the VM."
        }
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
            -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Description $NSGRuleDesc
        Write-Output "NSG rule created in $($VMData.resourcegroupname) resource group that $($VMData.nsgruledesc). It has been added to the $($networkSG.Name) Network Security Group"
    }

    # Check if a network interface resource is present in the resource group. 
    # If no such resource exists, use all the networking details to create the interface that will be assigned to the VM. 
    $existingNIC = Get-AzureRmNetworkInterface -resourcegroupname $VMData.resourcegroupname -Name $VMData.VMNICName -ErrorAction SilentlyContinue
    if ($existingNIC) {
        Write-Output "Network interface already exists in the $($VMData.resourcegroupname) resource group with name $($VMData.VMNICName)"
        $MyNIC = $existingNIC
    }else{
        #create private Network interface
        if($VMdata.PrivateNetwork){
            $MyNIC = New-AzureRmNetworkInterface -Name $VMData.VMNICName -resourcegroupname $VMData.resourcegroupname -Location $VMData.location `
                -SubnetId $Vsubnet.Id -PrivateIpAddress $VMData.PrivateIPAddress -NetworkSecurityGroupId $networkSG.Id
            Write-Output "A new Network Interface has been created with the name $($VMData.vmnicname) in $($VMData.resourcegroupname) resource group."
        }else{
            #create public network interface
            $MyNIC = New-AzureRmNetworkInterface -Name $VMData.VMNICName -resourcegroupname $VMData.resourcegroupname -Location $VMData.location `
                -SubnetId $Vsubnet.Id -PublicIpAddressId $PublicIP.Id -NetworkSecurityGroupId $networkSG.Id
            Write-Output "A new Network Interface has been created with the name $($VMData.vmnicname) in $($VMData.resourcegroupname) resource group."
        }
    }

    # Create the VM if no such VM exists with the name and resource group specified in the parameters above. 
    $existingVM = Get-AzureRmVm -resourcegroupname $VMData.resourcegroupname -Name $VMData.VMName -ErrorAction SilentlyContinue
    if($existingVM){
        Write-Output "A VM with the name $($VMData.vmname) in $($VMData.resourcegroupname) resource group already exists"
    }else{
        $vmConfig = New-AzureRmVMConfig -VMName $VMData.VMName -VMSize $VMData.VMSize
        Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -Credential $VMData.VMAdminAccCreds -ComputerName $VMData.VMName
        Set-AzureRmVMSourceImage -VM $vmConfig -PublisherName $VMData.imagePublisher -Offer $VMData.imageOffer -Skus $VMData.imageSkus -version latest
        Add-AzureRmVMNetworkInterface -VM $vmConfig -NetworkInterface $MyNIC
        New-AzureRmVM -resourcegroupname $VMData.resourcegroupname -Location $VMData.location -VM $vmConfig
        Write-Output "Virtual Machine $($VMData.vmname) has been built using values from hash table data."
    }
}

#create the hash table
# $BasicVMData = @{
#     resourcegroupname = "AzureAutomationDscRG"
#     VMAdminAccCreds = (Get-Credential -Message "Provide credentials for the admin account on the VM")
#     Location = "East US"
#     VnetName = "MyVnet"
#     vnetAddressPrefix =  "10.1.0.0/16"
#     SubnetName = "MyVsubnet"
#     SubnetAddressPrefix = "10.1.1.0/24"
#     NSGName = "MyNetworkSecurityGroup"
#     NSGRDPRuleName = "My NSG RDP Rule"
#     NSGRuleDesc = "allow RDP to the VM through public facing IP"
#     VMSize = "Standard_A1"
#     VMName = "TestWinServer1"
#     PrivateNetwork = $false #if the VM has a public or private IP.
#     IPName = "MyPublicIP"
#     IPAllocation = "static" #accepted values are static or dynamic (dhcp)
#     imagePublisher = "MicrosoftWindowsServer"
#     imageOffer = "windowsserver"
#     imageSkus = "2012-R2-Datacenter"
#     VMNICName = "MyWinServerInt"
# }

$PrivateWinServerData = @{
    #cloud data
    resourcegroupname = "PublicFacingFirewallRG"
    VMAdminAccCreds = (Get-Credential -Message "Provide credentials for the admin account on the VM")
    Location = "East US"
    ##network data
    #network topology data
    VnetName = "PublicFacingFirewallVnet"
    vnetAddressPrefix =  "10.2.0.0/16"
    SubnetName = "BackendSubnet"
    SubnetAddressPrefix = "10.2.1.0/24"
    #network security group data
    NSGName = "MyNetworkSecurityGroup"
    NSGRDPRuleName = "My NSG RDP Rule"
    NSGRuleDesc = "allow RDP to the VM through Backend subnetP"
    #IP addressing data
    ipname = "PrivateWinIP"
    PrivateNetwork = $true
    PrivateIPAddress = "10.2.1.4" #first four addresses are reserved
    IPAllocation = "dynamic"
    #network interface data
    VMNICName = "MyWinServerInterface"
    #image data
    VMSize = "Standard_A1"
    VMName = "TestWinServer1" #same name as above, but different resource groups
    imagePublisher = "MicrosoftWindowsServer"
    imageOffer = "windowsserver"
    imageSkus = "2012-R2-Datacenter"
}

#pass the hash table as an argument in the function after creating new resource group
#New-AzureRmResourceGroup -Name "PublicFacingFirewallRG" -Location "East US"
CreateAzureVM -VMData $PrivateWinServerData
#CreateAzureVM -VMData $BasicVMData