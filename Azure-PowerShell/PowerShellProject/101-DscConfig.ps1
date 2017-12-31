Configuration MrossTechDsc
{

	Node WebServer 
	{
		WindowsFeature IIS
		{
			Ensure               = "Present"
			Name                 = "Web-Server"
			IncludeAllSubFeature = $true
		}
		Group Developers
		{ 
			Ensure               = "Present"
			GroupName            = "DevGroup"
		}
		Group Accountants
		{ 
			Ensure               = "Present"
			GroupName            = "AcctGroup"
		}
		File DirectoryCreate
		{
			Ensure               = "Present"
			Type                 = "Directory"
			DestinationPath      = "C:\AzureTest"
		}
	}
 }
