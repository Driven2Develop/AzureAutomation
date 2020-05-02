# The purpose of this script is to test azure DSC.
# The name defaults to the name given to the configuration from the uploaded configuration file.

$ErrorActionPreference = 'stop'
. ..\AzureDscPractice\VMData.ps1 #dot source the VM data

#this configuration creates a local account and adds it to the local admin group. 
#Also this configuration creates a hello OS text file. 
Configuration TestConfig {

    Import-DscResource -ModuleName Psdesiredstateconfiguration

    Node $allnodes.nodename {
        User CreateLocalUser {
            UserName = $node.LocalAdmin
            Description = $node.LocalAdminDesc
            Disabled = $false
            Ensure = "Present"
            PasswordNeverExpires = $true
        }
        Group AddToLocalAdmin {
            GroupName = "Administrators"
            DependsOn = "[User]CreateLocalUser"
            Description = "Local Group for local Admins"
            MembersToInclude = $node.LocalAdmin
        }
        File TestFile {
            DestinationPath = "C:\temp\testfile.txt"
            Ensure = 'present'
            Contents = "Hello $($node.operatingsystem)!"
        }
    }
}

#compile the configuration
testconfig -configurationdata $configdataPath -outputpath $outputPath