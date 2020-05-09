# Azure Automation Script

This is a collection of scripts meant to deploy virtual machines, virtual firewalls, as well as the desired state configuration necessary to tie all the elements together in Azure using Azure remote management. 

## AzureAutomation.zip
* Creates a small test environment of Linux and Windows VMs. 
* Compile a configuration file for all the VMs. 
* Register the VMs to an azure automation account along with the compiled configuration files. 
* Afterwards this small environment can be configured using PowerShell Desired State Configuration.
* Built using PowerShell

[Azure Remote Management](https://docs.microsoft.com/en-us/powershell/azure/azurerm/overview?view=azurermps-6.13.0) is a module for powershell meant to allow for easier control of cloud assets in Azure from the powershell command line.

These scripts are all well documented and commented to allow for easy understanding. Please view the additional README in the AzureDsc folder. 

## Azure Dsc (Desired State Configuration)

This folder stores the scripts for setting up the desired state configuration environment in an Azure cloud environment. Before executing the script, be mindful of the costs associated with the deployed assets.

# The purpose of these scripts is to automate:
1. The creation of a small test environment of Linux and Windows VMs. 
2. Compile a small configuration file for all the VMs. 
3. Register the VMs to an azure automation account along with the compiled configuration files. 

## Prerequisites
* A working azure subscription with credit. 
* an existing azure automation account.

## Structure of Execution
* The data for the VMs for creation can be found in *VMData.ps1*. These values can be freely modified to create any sort of VM in azure. 
* The VM data is stored in a hash table that will be sent to the main function in *CreateTestVMs.ps1*
    * The data is used to create the VMs all enclosed within the function. 
* A default configuration is already in the *configurations\azureAutoTest.ps1* file that is rather simple. 
    * However any configuration can be implemented here for use. 
    * The configuration is then compiled locally and stored in *ConfigurationBuild* file.
* Once compiled the .mof files are uploaded to an azure automation account specified in the **$AzureAutomationAcc** global variable in *DeployAzureConfig.ps1* script.
* Lastly, and the most important and time consuming step, is to register the newly created VM with the azure automation account and configuration build. 


## Azure VM

This folder stores the configuration for the different virtual machines meant to be deployed in the azure environment. There are a variety of VMs to choose from including the public facing Firewall and a more customied virtual machine. 

