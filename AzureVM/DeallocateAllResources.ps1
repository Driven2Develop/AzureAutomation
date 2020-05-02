#the purpose of this script is to deallocate all the resources in all the resource groups of an account. 
#it is recommended to execute this script at the end of the day to not incur additional charges for VMs
#Lastly this script is idempotent and generates an output of all the operations that take place.

$ErrorActionPreference = 'stop'
Import-Module AzureRM.profile

#Prompt user to login to the portal, user can use the pop-up window to login securely
$cred = Get-Credential -Message "Please provide login credentials for your Azure account"
Login-AzureRmAccount -Credential $cred -Environment AzureCloud
write-output "Login Successful, will proceed to deallocate VM Resources"

#get all the resource groups in the account
$resourceGroups = Get-AzureRmResourceGroup

#Get any VMs that are in the resource group and stop them
foreach ($RGs in $resourceGroups) {
    Write-Output "Deallocating VMs in the resource group: $($RGs.resourcegroupname)"
    Get-AzureRmVm -ResourceGroupName $RGs.resourcegroupname | stop-azurermvm -Force 
}