#TPS CAD iymen Abdella August 15 2018
#the purpose of this script is to automate the process of creating a small test environment of VMs.
#Then compiling the configuration for the VMs
#Then finally registering the VMs to an automation account in azure. 

$ErrorActionPreference = 'stop'
$AzureAutomationAcc = "IymenAbdella"
$AzAutoRG = "AzureAutomationDscRG" #resource group of automation account.
$AzureUsername = "iabdella@edc.ca" #Azure username for subscription. 
Login-AzAccount (Get-Credential $azureUsername -Message "Please provide login credentials for azure subscription") #login to azure

.\CreateTestVMs.ps1 #create all the VMs
. .\VMData.ps1 #dot source the variables
..\AzureDscPractice\Configurations\AzureAutoTest.ps1 #compile the configuration locally. 

#upload the configured .mof files to the automation account
$compiledFiles = Get-ChildItem -Path $OutputPath
foreach ($item in $compiledFiles) {
    $configpath = $item.directory.tostring() + '\' + $item.name.tostring()
    Import-AzureRmAutomationDscNodeConfiguration -ResourceGroupName $AzAutoRG -AutomationAccountName $AzureAutomationAcc -Path $configpath -ConfigurationName "Config" -Force
}
 
# Once created, register the VMs to the automation account.
# If the registration fails then try again after starting up the VM.
foreach ($VM in $allvmdata) {
    $configname = "$($vm.configname).$($vm.vmname)"
    try{
        write-output "registering the VM $($vm.vmname) with automation account $AzureAutomationAcc."
        Register-AzureRmAutomationDscNode -AzureVMResourceGroup $RGname.ToString() -AzureVMLocation $Location.ToString() -AzureVMName $VM.vmname.ToString() -AutomationAccountName $AzureAutomationAcc -ResourceGroupName $AzAutoRG -NodeConfigurationName $configname
    }catch{
        write-output "starting up VM $($vm.vmname)."
        Start-AzureRmVM -Name $vm.vmname.ToString() -ResourceGroupName $RGname.ToString() 
        write-output "registering the VM $($vm.vmname) with automation account $AzureAutomationAcc."
        Register-AzureRmAutomationDscNode -AzureVMResourceGroup $RGname.ToString() -AzureVMLocation $Location.ToString() -AzureVMName $VM.vmname.ToString() -AutomationAccountName $AzureAutomationAcc -ResourceGroupName $AzAutoRG -NodeConfigurationName $configname
    }
}