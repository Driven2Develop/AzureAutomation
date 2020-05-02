@{
    AllNodes = 
    @(
        @{
            NodeName = "*"
            LocalAdmin = "IymenAbdella"
            LocalAdminDesc = "Local Admin for the Servers."
        }
        @{
            NodeName = "WinServer01"
            OperatingSystem = "Windows"
        }
        @{
            NodeName = 'WinServer02'
            OperatingSystem = "Windows"
        }
        @{
            NodeName = "LinuxServer01"
            OperatingSystem = "Linux"
        }
        @{
            NodeName = "LinuxServer02"
            OperatingSystem = "Linux"
        }
    )
}