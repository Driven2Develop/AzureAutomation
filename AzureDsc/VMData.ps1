#the purpose of this script is to store all the necessary data to create 2 windows VMs and 2 Linux VMs. 
#the VMs will be as basic and cheap as possible. Mostly for Test purposes. 
#the data will be stored in hash tables and dot sourced for use when created. 

#The following variables remain the same for all the VMs
$ErrorActionPreference = 'stop'
$RGname = "AzAutoVMs"
$Location = "East US"
$VnetName = "AzAutoVMVnet"
$VnetAddressPrefix = "10.2.0.0/16" 
$SubnetName = "AzAutoVMSubnet"
$subnetAddressPrefix = "10.2.1.0/24"
$NSGName = "AzAutoNetworkSecurityGroup"
$NSGRuleName = "RDPThrough3389"
$IPAllocation = "static"
$OutputPath = "C:\source\azureautomation\AzureDscPractice\ConfigurationBuild"
$configdataPath = "C:\source\azureautomation\AzureDscPractice\ConfigurationData\ConfigData.psd1"

$WinServer01 = @{
    VMResourceGroup = $RGname
    VMLocation = $Location
    VMVnetName = $VnetName
    VMVnetAddressPrefix = $VnetAddressPrefix
    VMSubnetName = $SubnetName
    VMSubnetAddressPrefix = $subnetAddressPrefix
    VMNSGName = $NSGName
    VMNSGRuleName = $NSGRuleName
    VMIPAllocation = $IPAllocation
    ipname = "WinServerIP01"
    IPAddress = "10.2.1.4" #first four addresses are reserved
    VMNIName = "WinServerNI01"
    VMSize = "Standard_A1"
    VMName = "WinServer01"
    imagePublisher = "MicrosoftWindowsServer"
    imageOffer = "windowsserver"
    imageSkus = "2012-R2-Datacenter"
    OperatingSystem = "Windows"
    ConfigName = "Config"
    ConfigOutputPath = $OutputPath
}
$WinServer02 = @{
    VMResourceGroup = $RGname
    VMLocation = $Location
    VMVnetName = $VnetName
    VMVnetAddressPrefix = $VnetAddressPrefix
    VMubnetName = $SubnetName
    VMSubnetAddressPrefix = $subnetAddressPrefix
    VMNSGName = $NSGName
    VMNSGRuleName = $NSGRuleName
    VMIPAllocation = $IPAllocation
    ipname = "WinServerIP02"
    IPAddress = "10.2.1.5" #first four addresses are reserved
    VMNIName = "WinServerNI02"
    VMSize = "Standard_A1"
    VMName = "WinServer02"
    imagePublisher = "MicrosoftWindowsServer"
    imageOffer = "windowsserver"
    imageSkus = "2012-R2-Datacenter"
    OperatingSystem = "Windows"
    ConfigName = "Config"
    ConfigOutputPath = $OutputPath

}
$LinuxServer01 = @{
    VMResourceGroup = $RGname
    VMLocation = $Location
    VMVnetName = $VnetName
    VMVnetAddressPrefix = $VnetAddressPrefix
    VMubnetName = $SubnetName
    VMSubnetAddressPrefix = $subnetAddressPrefix
    VMNSGName = $NSGName
    VMNSGRuleName = $NSGRuleName
    VMIPAllocation = $IPAllocation
    ipname = "LinuxServerIP01"
    IPAddress = "10.2.1.6" #first four addresses are reserved
    VMNIName = "LinuxServerNI01"
    VMSize = "Standard_A1"
    VMName = "LinuxServer01"
    imagePublisher = "Canonical"
    imageOffer = "UbuntuServer"
    imageSkus = "18.10-DAILY"
    OperatingSystem = "Linux"
    ConfigName = "Config"
    ConfigOutputPath = $OutputPath
}
$LinuxServer02 = @{
    VMResourceGroup = $RGname
    VMLocation = $Location
    VMVnetName = $VnetName
    VMVnetAddressPrefix = $VnetAddressPrefix
    VMubnetName = $SubnetName
    VMSubnetAddressPrefix = $subnetAddressPrefix
    VMNSGName = $NSGName
    VMNSGRuleName = $NSGRuleName
    VMIPAllocation = $IPAllocation
    ipname = "LinuxServerIP02"
    IPAddress = "10.2.1.7" #first four addresses are reserved
    VMNIName = "LinuxServerNI02"
    VMSize = "Standard_A1"
    VMName = "LinuxServer02"
    imagePublisher = "Canonical"
    imageOffer = "UbuntuServer"
    imageSkus = "18.10-DAILY"
    OperatingSystem = "Linux"
    ConfigName = "Config"
    ConfigOutputPath = $OutputPath
}

$AllVMData = @($WinServer01,$WinServer02,$LinuxServer01,$LinuxServer02)