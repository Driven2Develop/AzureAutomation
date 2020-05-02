#Iymen Abdella TPS CAD August 13 2018
#the prupsoe of this script is to create a small test environment of VMs in the same resource group, vnet, and subnet. 
#tbh these serves are not built in the most secure fashion so precautions should be taken when integrating in any high security environment. 
#Since azure does not except generic types all variables from VMData.ps1 need to be explicitely used as strings. 
#By default linux machines do not have a ssh key associated to them, instead it uses password authentication. 

$ErrorActionPreference = 'stop'
#dot source the variables
 . .\VMData.ps1
 #get credentials of all virtual machines being built
 $VMAdminAccCreds = (Get-Credential -Message "Provide credentials for the admin account on the VM")

function CreateAzureVM ($VMData) {

    #null check of the hash of VM data
    if (!($VMData)) {
        Write-Output "no parameters specified for VM"
        exit
    }

    #check if the resource group exists, if it does not then create a new one. 
    try{
        $resourceGroup = Get-AzureRmResourceGroup -Name $VMData.VMResourceGroup.ToString() -Location $VMData.VMLocation.ToString()
        Write-Output "Found existing Azure resource group with name $($VMData.VMResourceGroup) in location $($VMData.VMLocation)."
    }catch{
        $resourceGroup = New-AzureRmResourceGroup -Name $VMData.VMResourceGroup.ToString() -Location $VMData.VMLocation.ToString()
        write-output "New resource group created with name $($VMData.VMResourceGroup) in location $($VMData.VMLocation)."
    }

    ##networking details
    # create a Virtual Network, if such a vnet already exists then add the existing Vnet to the VM Configuration.
    $existingVnet = Get-AzureRmVirtualNetwork -Name $VMData.VMVnetName.toString() -resourcegroupname $resourcegroup.resourcegroupname -ErrorAction SilentlyContinue
    if($existingVnet){
        Write-Output "A virtual network with the name $($VMData.VMVnetName) in resource group $($resourcegroup.ResourceGroupName) already exists. Adding the existing Vnet to the VM configuration."
        $vnet = $existingVnet
    }else{
        $vnet = New-AzureRmVirtualNetwork -Name $VMData.VMVnetName.toString() -resourcegroupname $resourcegroup.resourcegroupname `
            -Location $VMData.VMLocation.ToString() -AddressPrefix $VMData.VMVnetAddressPrefix.ToString()
        Write-Output "Creating new Virtual Network with name $($vnet.name) in the $($resourcegroup.resourcegroupname) resource group."
    }

    # Create a virtual subnet if such a subnet already exists then add the existing subnet to the VM configuration. 
    # Add the subnet to the virtual network specified above.
    $existingVsubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $VMData.VMSubnetName -ErrorAction SilentlyContinue
    if($existingVsubnet){
        Write-Output `
        "A virtual subnet network with the name $($VMData.VMSubnetName) in resource group $($VMData.VMResourceGroup) already exists within the $($vnet.name) virtual network. Adding this subnet to the VM configuration."
        $Vsubnet = $existingVsubnet
    }else{
        Add-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $VMData.VMSubnetName.ToString() -AddressPrefix $VMData.VMsubnetAddressPrefix.ToString()
        $vnet | Set-AzureRmVirtualNetwork
        $vsubnet = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $VMData.VMSubnetName.ToString()
        Write-Output "New Subnet has been created with name $($vsubnet.name) in resource group $($vsubnet.resourcegroupname) and $($vnet.name) Virtual Network."
    }

    # create the public IP address for the VM if a public IP address already exists then add it to the VM configuration. 
    $existingIP = Get-AzureRmPublicIpAddress -resourcegroupname $resourcegroup.resourcegroupname -Name $VMData.ipname.toString() -ErrorAction SilentlyContinue
    if($existingIP){
        Write-Output "A public IP address with name $($VMData.ipname) already exists in the $($resourcegroup.ResourceGroupName) resource group. Adding this public IP address to the VM configuration."
        $PublicIP = $existingIP
    }else{
        $PublicIP = New-AzureRmPublicIpAddress -Name $VMData.ipname.toString() -resourcegroupname $resourcegroup.resourcegroupname `
            -Location $VMData.VMLocation.ToString() -AllocationMethod $VMData.VMIPAllocation.ToString()
        Write-Output "Public IP address resource has been created with name $($PublicIP.name) in $($PublicIP.resourcegroupname) resource group for the VM."
    }

    # create a new network security group if a network security group already exists then create the NSG rule to allow RDP on 3389 and SSH on 22.
    # Add the rules to the newly created NSG.
    $existingNSG = Get-AzureRmNetworkSecurityGroup -Name $VMData.VMNSGName.ToString() -resourcegroupname $resourcegroup.resourcegroupname -ErrorAction SilentlyContinue
    if($existingNSG){
        Write-Output "A network security group with name $($VMData.VMNSGName) already exists in $($resourcegroup.ResourceGroupName) resource group. Adding this network security group to the VM configuration."
        $networkSG = $existingNSG

        #ensure RDP and SSh are allowed 
        Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $networkSG -Name $VMData.VMNSGRuleName.ToString() -Access Allow `
            -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix * `
            -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -ErrorAction SilentlyContinue | Set-AzureRmNetworkSecurityGroup -ErrorAction SilentlyContinue
        Write-Output "NSG rule created in $($networkSG.name) network security group to allow any/any RDP through Port 3389."

        Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $networkSG -Name "SSHThrough22" -Access Allow `
            -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * `
            -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -ErrorAction SilentlyContinue | Set-AzureRmNetworkSecurityGroup -ErrorAction SilentlyContinue
        Write-Output "NSG rule created in $($networkSG.name) network security group to allow any/any SSH through Port 22."
    }else{
        $networkSG = New-AzureRmNetworkSecurityGroup -Name $VMData.VMNSGName.ToString() -resourcegroupname $resourcegroup.resourcegroupname `
            -Location $VMData.VMLocation.ToString()
        Write-Output "A Network Security Group has been created in $($networkSG.resourcegroupname) resource group."

        #allow RDP through port 3389 and ssh through port 22
        Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $networkSG -Name $VMData.VMNSGRuleName.ToString() -Access Allow `
            -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet `
            -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -ErrorAction SilentlyContinue | Set-AzureRmNetworkSecurityGroup -ErrorAction SilentlyContinue
        Write-Output "NSG rule created in $($networkSG.name) resource group. It has been added to the $($networkSG.Name) Network Security Group to allow any/any RDP through port 3389."
        Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $networkSG -Name "SSHThrough22" -Access Allow `
            -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * `
            -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -ErrorAction SilentlyContinue | Set-AzureRmNetworkSecurityRuleConfig -ErrorAction SilentlyContinue
        Write-Output "NSG rule created in $($networkSG.name) resource group. It has been added to the $($networkSG.Name) Network Security Group to allow any/any SSH through Port 22."
    }

    # Create a network interface resource if no such resource exists, use all the networking details to create the interface that will be assigned to the VM. 
    $existingNIC = Get-AzureRmNetworkInterface -resourcegroupname $resourcegroup.resourcegroupname -Name $VMData.VMNIName.ToString() -ErrorAction SilentlyContinue
    if ($existingNIC) {
        Write-Output "Network interface already exists in the $($resourcegroup.ResourceGroupName) resource group with name $($VMData.VMNIName). Adding this Network Interface to the VM Configuration."
        $MyNIC = $existingNIC
    }else{
        $MyNIC = New-AzureRmNetworkInterface -Name $VMData.VMNIName.ToString() -resourcegroupname $resourcegroup.resourcegroupname `
         -Location $VMData.VMLocation.ToString() -SubnetId $Vsubnet.Id -PublicIpAddressId $PublicIP.Id -NetworkSecurityGroupId $networkSG.Id
        Write-Output "A new Network Interface has been created with the name $($MYNIC.Name) in $($MYNIC.resourcegroupname) source group."
    }

    # Use all the data to create the VM.
    $existingVM = Get-AzureRmVm -resourcegroupname $resourcegroup.resourcegroupname -Name $VMData.VMName.ToString() -ErrorAction SilentlyContinue
    if($existingVM){
        Write-Output "A VM with the name $($VMData.vmname) in $($resourcegroup.ResourceGroupName) resource group already exists."
    }else{
        $vmConfig = New-AzureRmVMConfig -VMName $VMData.VMName.ToString() -VMSize $VMData.VMSize.ToString()
        if ($VMData.operatingsystem -eq 'linux') {
            Set-AzureRmVMOperatingSystem -VM $vmConfig -Linux -Credential $VMAdminAccCreds -ComputerName $VMData.VMName.ToString()
        }elseif ($VMData.operatingsystem -eq 'Windows') {
            Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -Credential $VMAdminAccCreds -ComputerName $VMData.VMName.ToString()
        }
        Set-AzureRmVMSourceImage -VM $vmConfig -PublisherName $VMData.imagePublisher.ToString() -Offer $VMData.imageOffer.ToString() -Skus $VMData.imageSkus.ToString() -version latest
        Add-AzureRmVMNetworkInterface -VM $vmConfig -NetworkInterface $MyNIC
        New-AzureRmVM -resourcegroupname $resourcegroup.resourcegroupname -Location $VMData.VMLocation.ToString() -VM $vmConfig
        Write-Output "Virtual Machine $($VMData.vmname) has been built using values from hash table data."
    }
}

#create the VMs from all the hash table data. 
foreach ($vm in $allvmdata){
    CreateAzureVM -VMData $vm
}