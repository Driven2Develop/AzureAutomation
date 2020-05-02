#The purpose of these scripts is to automate:
1. The creation of a small test environment of Linux and Windows VMs. 
2. Compile a small configuration file for all the VMs. 
3. Register the VMs to an azure automation account along with the compiled configuration files. 

##Prerequisites
* A working azure subscription with credit. 
* an existing azure automation account.

##Structure of Execution
* The data for the VMs for creation can be found in *VMData.ps1*. These values can be freely modified to create any sort of VM in azure. 
* The VM data is stored in a hash table that will be sent to the main function in *CreateTestVMs.ps1*
    * The data is used to create the VMs all enclosed within the function. 
* A default configuration is already in the *configurations\azureAutoTest.ps1* file that is rather simple. 
    * However any configuration can be implemented here for use. 
    * The configuration is then compiled locally and stored in *ConfigurationBuild* file.
* Once compiled the .mof files are uploaded to an azure automation account specified in the **$AzureAutomationAcc** global variable in *DeployAzureConfig.ps1* script.
* Lastly, and the most important and time consuming step, is to register the newly created VM with the azure automation account and configuration build. 