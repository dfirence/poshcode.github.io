Function Reset-Alerts
{ 
<#  
.Synopsis  
    Resets alerts for the specified site.
.Description  
    By default this resets scheduled alerts for the specified site.
	This can also reset all alerts for the site and/or for a specific user.
	
	This is inspired by: http://gallery.technet.microsoft.com/scriptcenter/877d2abd-fce9-4545-b223-7637936dd888         
.Parameter Url  
    The url of the site to fix.  Required Parameter. 
.Parameter User 
    Optional UserName to reset.
.Parameter All 
    Reset all alerts.
.Example 
    Reset all scheduled alerts for the specific site.  This operation can not be undone! 
     
    PS >  Reset-Alerts -url "http://teams/sites/newteam"
.Example          
    Reset all scheduled alerts for the specified user for this specific site.  This operation can not be undone! 
         
    PS >  Reset-Alerts -url "http://teams/sites/newteam" -user "username"
.Example 
    Reset all alerts for the specific site.  This operation can not be undone! 
     
    PS >  Reset-Alerts -url "http://teams/sites/newteam" -All
.Example 
    Reset all alerts for the specified user for this specific site.  This operation can not be undone! 
     
    PS >  Reset-Alerts -url "http://teams/sites/newteam" -user "username" -All
	
.Notes  
        NAME:      Reset-Alerts 
        AUTHOR:    Alan Oakland 
        LASTEDIT:  3/29/2013
#>  
 
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')] 
Param( 
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)][ValidateNotNullOrEmpty()][String] $Url, 
    [Parameter(Mandatory=$false, ValueFromPipeline=$False)][string] $user = $null,
	[Switch]$All = $false
    )
	#Try catch for entire script
	try
	{ 
		$site = Get-SPWeb -Identity $URL
		#Try Catch for reading alerts
		try
		{ 
			if ($All -eq $true)
			{
				$siteAlerts = $site.Alerts
			}
			else
			{
				$siteAlerts = $site.Alerts | Where-Object {$_.AlertFrequency -ne "Immediate"}
			}
			if (($user -ne $null) -and ($user -ne ""))
			{
				$siteAlerts = $siteAlerts | Where-Object {$_.User -like "NSIGHT\$($user)"}
			}
			Write-Host "There are $($site.Alerts.Count.ToString()) alerts for $($site.Title) Site ($($site.URL))"
			
			foreach ($alert in $siteAlerts)
			{
				if ($alert.user -ne $null)
				{
					Write-Host "Processing user $($alert.user)";
					#Try catch for restarting alert
					try
					{ 
						if($pscmdlet.ShouldProcess($_.ID, "restarting alert: $($alert.Title) for $($alert.user.DisplayName) on site {$URL}"))
						{
							$alert.Status = [Microsoft.SharePoint.SPAlertStatus]::Off 
							$alert.Update(); 
			
							$alert.Status = [Microsoft.SharePoint.SPAlertStatus]::On
							$alert.Update();
							Write-Host "Restarted alert: $($alert.Title) for $($alert.user.DisplayName) on site {$URL}"
						} 
					}
					catch
					{ 
						Write-Error "Failure restarting alert: $($alert.Title) for $($alert.user.DisplayName) on site {$URL}" 
					}
				}
			}
		}
		catch
		{ 
              Write-Error "Failure reading alerts from SPWeb {$_.URL}" 
              throw 
        } 
		$site.Dispose()
	}
	catch
	{ 
        Write-Error $_        
        throw 
    } 
}

#Only add the snap in if it is not already loaded.
if(-not (Get-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue))
{
   #Add the SharePoint Snap in, but stop script if this fails
   Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction Stop 
   Write-Output "Initialized SharePoint Snap In"
}

# Example to reset all scheduled alerts on a site
# Reset-Alerts -url "http://sharepoint/sites/myteam"

# Example to reset all scheduled alerts on all sites in a site collection
# This has not been tested
<#
$sites = Get-SPWeb -Site $Url -limit All
foreach ($site in $sites)
{
	Reset-Alerts -url "http://sharepoint"
}
#>
