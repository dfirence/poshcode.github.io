#############################################################################################
#
# NAME: Add-SQLAccountToSQLRole.ps1
# AUTHOR: Rob Sewell http://sqldbawithabeard.com
# DATE:11/09/2013
#
# COMMENTS: Load function to create a SQL user and add them to a server role
#
# USAGE: Add-SQLAccountToSQLRole FADE2BLACK Test Password01 dbcreator
#        Add-SQLAccountToSQLRole FADE2BLACK Test Password01 public

Function Add-SQLAccountToSQLRole ([String]$Server, [String] $User, [String]$Password, [String]$Role)
{

$Svr = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $server

# Check if Role entered Correctly
    if($svr.Roles.name -notcontains $Role)
        {
        Write-Host " $Role is not a valid Role on $Server"
        }

    else
        {
#Check if User already exists
    		if($svr.Logins.Contains($User))
			    {
                $SqlUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login $Server, $User
                $LoginName = $SQLUser.Name
                $svrole = $svr.Roles | where {$_.Name -eq $Role}
                $svrole.AddMember("$LoginName")
                }

            else
                {
                $SqlUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login $Server, $User
                $SqlUser.LoginType = 'SqlLogin'
                $SqlUser.PasswordExpirationEnabled = $false
                $SqlUser.Create($Password)
                $LoginName = $SQLUser.Name
                $svrole = $svr.Roles | where {$_.Name -eq $Role}
                $svrole.AddMember("$LoginName")
                }
        }

}


