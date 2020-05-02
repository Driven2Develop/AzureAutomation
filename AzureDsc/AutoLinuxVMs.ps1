# the purpose of this script is to automate registering linux VMs to an automation account by installing DSCforLinux extension

$ErrorActionPreference = 'stop'
$AzAutoAccount = "IymenAbdella"
$LinuxRGName = "AzAutoVMs"
$linuxVMName = @('LinuxServer01','LinuxServer02')

Login-AzAccount (Get-Credential -Message "Please provide login credentials for azure subscription") #login to azure

Set-AzureRmVMDscExtension -ResourceGroupName $LinuxRGName -VMName $linuxVMName -