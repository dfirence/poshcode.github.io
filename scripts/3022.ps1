# ---------------------------------------------------------------------------
### <Author>
### Chad Miller 
### </Author>
### <Description>
### Based on functions in SQLPSX. SqlProxy.psm1 module is used for administering
### SQL Server logins, users, and roles. Designed to be used with PS Remoting.
### All actions audited to a custom Eventlog. 
### See Write-SqlProxyLog for log setup details
### </Description>
# ---------------------------------------------------------------------------
try {add-type -AssemblyName "Microsoft.SqlServer.ConnectionInfo, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -EA Stop}
catch {add-type -AssemblyName "Microsoft.SqlServer.ConnectionInfo"}

try {add-type -AssemblyName "Microsoft.SqlServer.Smo, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -EA Stop; $smoVersion = 10}
catch {add-type -AssemblyName "Microsoft.SqlServer.Smo"; $smoVersion = 9}

try {add-type -AssemblyName "Microsoft.SqlServer.SqlEnum, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -EA Stop; $smoVersion = 10}
catch {add-type -AssemblyName "Microsoft.SqlServer.SqlEnum"; $smoVersion = 9}

try
{
    try {add-type -AssemblyName "Microsoft.SqlServer.SMOExtended, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91" -EA Stop}
    catch {add-type -AssemblyName "Microsoft.SqlServer.SMOExtended" -EA Stop}
}
catch {Write-Warning "SMOExtended not available"}

$EventID = @{
"Add-SqlDatabaseRoleMember"=0
"Add-SqlLogin"=1
"Add-SqlServerRoleMember"=2
"Add-SqlUser"=3
"Remove-SqlDatabaseRoleMember"=4
"Remove-SqlLogin"=5
"Remove-SqlServerRoleMember"=6
"Remove-SqlUser"=7
"Rename-SqlLogin"=8
"Set-SqlLogin"=9
"Set-SqlLoginDefaultDatabase"=10
}

#######################
<#
.SYNOPSIS
Gets a ServerConnection.
.DESCRIPTION
The Get-SqlConnection function  gets a ServerConnection to the specified SQL Server.
.INPUTS
None
    You cannot pipe objects to Get-SqlConnection 
.OUTPUTS
Microsoft.SqlServer.Management.Common.ServerConnection
    Get-SqlConnection returns a Microsoft.SqlServer.Management.Common.ServerConnection object.
.EXAMPLE
Get-SqlConnection "Z002\sql2K8"
This command gets a ServerConnection to SQL Server Z002\SQL2K8.
.EXAMPLE
Get-SqlConnection "Z002\sql2K8" "sa" "Passw0rd"
This command gets a ServerConnection to SQL Server Z002\SQL2K8 using SQL authentication.
.LINK
Get-SqlConnection 
#>
function Get-SqlConnection
{
    param(
    [Parameter(Position=0, Mandatory=$true)] [string]$sqlserver,
    [Parameter(Position=1, Mandatory=$false)] [string]$username, 
    [Parameter(Position=2, Mandatory=$false)] [string]$password
    )

    Write-Verbose "Get-SqlConnection $sqlserver"
    
    try {
        if($Username -and $Password)
        { $con = new-object ("Microsoft.SqlServer.Management.Common.ServerConnection") $sqlserver,$username,$password }
        else
        { $con = new-object ("Microsoft.SqlServer.Management.Common.ServerConnection") $sqlserver }
            
        $con.Connect()
        Write-Output $con
    }
    catch { $message = $_.Exception.GetBaseException().Message
            write-error $message
    }
    
} #Get-ServerConnection

#######################
<#
.SYNOPSIS
Gets an SMO Server object.
.DESCRIPTION
The Get-SqlServer function  gets a SMO Server object for the specified SQL Server.
.INPUTS
None
    You cannot pipe objects to Get-SqlServer 
.OUTPUTS
Microsoft.SqlServer.Management.Smo.Server
    Get-SqlServer returns a Microsoft.SqlServer.Management.Smo.Server object.
.EXAMPLE
Get-SqlServer "Z002\sql2K8"
This command gets an SMO Server object for SQL Server Z002\SQL2K8.
.EXAMPLE
Get-SqlServer "Z002\sql2K8" "sa" "Passw0rd"
This command gets a SMO Server object for SQL Server Z002\SQL2K8 using SQL authentication.
.LINK
Get-SqlServer 
#>
function Get-SqlServer
{
    param(
    [Parameter(Position=0, Mandatory=$true)] [string]$sqlserver,
    [Parameter(Position=1, Mandatory=$false)] [string]$username, 
    [Parameter(Position=2, Mandatory=$false)] [string]$password,
    [Parameter(Position=3, Mandatory=$false)] [string]$StatementTimeout=0
    )
    #When $sqlserver passed in from the SMO Name property, brackets
    #are automatically inserted which then need to be removed
    $sqlserver = $sqlserver -replace "\[|\]"

    Write-Verbose "Get-SqlServer $sqlserver"

    $con = Get-SqlConnection $sqlserver $Username $Password

    $server = new-object ("Microsoft.SqlServer.Management.Smo.Server") $con
    #Some operations might take longer than the default timeout of 600 seconnds (10 minutes). Set new default to unlimited
    $server.ConnectionContext.StatementTimeout = $StatementTimeout
    $server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.StoredProcedure], "IsSystemObject")
    $server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.Table], "IsSystemObject")
    $server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.View], "IsSystemObject")
    $server.SetDefaultInitFields([Microsoft.SqlServer.Management.SMO.UserDefinedFunction], "IsSystemObject")
    #trap { "Check $SqlServer Name"; continue} $server.ConnectionContext.Connect() 
    Write-Output $server
    
} #Get-SqlServer

#######################
<#
.SYNOPSIS
Gets an SMO Database object.
.DESCRIPTION
The Get-SqlDatabase function  gets an SMO Database object for the specified SQL Database or collection of Database objects.
.INPUTS
None
    You cannot pipe objects to Get-SqlDatabase 
.OUTPUTS
Microsoft.SqlServer.Management.Smo.Database
    Get-SqlDatabase returns a Microsoft.SqlServer.Management.Smo.Database object.
.EXAMPLE
Get-SqlDatabase "Z002\sql2K8"
This command gets a collection of SMO Database objects for SQL Server Z002\SQL2K8.
.EXAMPLE
Get-SqlDatabase $(Get-SqlServer "Z002\sql2K8" "sa" "Passw0rd") "pubs"
This command gets a SMO Database object for SQL database pubs on the SQL Server Z002\SQL2K8 using SQL authentication.
.LINK
Get-SqlDatabase 
#>
function Get-SqlDatabase
{ 
    param(
    [Parameter(Position=0, Mandatory=$true)] $sqlserver,
    [Parameter(Position=1, Mandatory=$false)] [string]$dbname,
    [Parameter(Position=2, Mandatory=$false)] [switch]$force
    )

    switch ($sqlserver.GetType().Name)
    {
        'String' { $server = Get-SqlServer $sqlserver }
        'Server' { $server = $sqlserver }
        default { throw 'Get-SqlDatabase:Param `$sqlserver must be a String or Server object.' }
    }

    Write-Verbose "Get-SqlDatabase $($server.Name) $dbname"

    if ($dbname)
    { if ($server.Databases.Contains("$dbname") -and $server.Databases[$dbname].IsAccessible)
        {$server.Databases[$dbname]} 
      else
        {throw "Database $dname does not exist or is not accessible."}
    }
    elseif ($force)
    { $server.Databases | where {$_.IsAccessible -eq $true} }
    #Skip systems databases
    else
    { $server.Databases | where {$_.IsSystemObject -eq $false -and $_.IsAccessible -eq $true} }

} # Get-SqlDatabase

#######################
<#
.SYNOPSIS
Executes a query and returns an array of System.Data.DataRow.
.DESCRIPTION
The Get-SqlData function executes a query and returns an array of System.Data.DataRow.
.INPUTS
None
    You cannot pipe objects to Get-SqlData 
.OUTPUTS
System.Data.DataRow
    Get-SqlData returns an array of System.Data.DataRow.
.EXAMPLE
Get-SqlData "Z002\sql2K8" "pubs" "select * from authors"
This command executes the specified SQL query using Windows authentication.
.EXAMPLE
$server = Get-SqlServer "Z002\sql2K8" "sa" "Passw0rd"
Get-SqlData $server "pubs" "select * from authors"
This command executes the specified SQL query using SQL authentication.
.LINK
Get-SqlData 
#>
function Get-SqlData
{
    param(
    [Parameter(Position=0, Mandatory=$false)] $sqlserver,
    [Parameter(Position=1, Mandatory=$true)] $dbname,
    [Parameter(Position=2, Mandatory=$true)] [string]$qry
    )

    switch ($dbname.GetType().Name)
    {
        'String' { $database = Get-SqlDatabase $sqlserver $dbname }
        'Database' { $database = $dbname }
        default { throw "Get-SqlData:Param '`$dbname' must be a String or Database object." }
    }

    #Write-Verbose "Get-SqlData $($database.Parent.Name) $($database.Name) $qry"
    Write-Verbose "Get-SqlData $($database.Parent.Name) $($database.Name)"

    $ds = $database.ExecuteWithResults("$qry")
    $ds.Tables | foreach { $_.Rows}    

}# Get-SqlData

#######################
<#
.SYNOPSIS
 Executes a query that does not return a result set.
.DESCRIPTION
The Set-SqlData function executes a query that does not return a result set.
.INPUTS
None
    You cannot pipe objects to Set-SqlData 
.OUTPUTS
None
    Set-SqlData does not produce any output.
.EXAMPLE
Set-SqlData "Z002\sql2K8" "pubs" "Update authors set au_lname = 'Brown' WHERE au_lname = 'White'"
This command executes the specified SQL query using Windows authentication.
.EXAMPLE
$server = Set-SqlServer "Z002\sql2K8" "sa" "Passw0rd"
Set-SqlData $server "pubs" "Update authors set au_lname = 'Brown' WHERE au_lname = 'White'"
This command executes the specified SQL query using SQL authentication.
.LINK
Set-SqlData 
#>
function Set-SqlData
{
    param(
    [Parameter(Position=0, Mandatory=$false)] $sqlserver,
    [Parameter(Position=1, Mandatory=$true)] [string]$dbname,
    [Parameter(Position=2, Mandatory=$true)] [string]$qry
    )

    switch ($dbname.GetType().Name)
    {
        'String' { $database = Get-SqlDatabase $sqlserver $dbname }
        'Database' { $database = $dbname }
        default { throw "Set-SqlData:Param '`$dbname' must be a String or Database object." }
    } 
    
    #Write-Verbose "Set-SqlData $($database.Parent.Name) $($database.Name) $qry"
    Write-Verbose "Set-SqlData $($database.Parent.Name) $($database.Name)"
    
    $database.ExecuteNonQuery("$qry")

}# Set-SqlData

#######################
<#
.SYNOPSIS
Gets an SMO Login object.
.DESCRIPTION
The Get-SqlLogin function  gets a collection of SMO Login objects for the specified SQL Server.
.INPUTS
None
    You cannot pipe objects to Get-SqlLogin 
.OUTPUTS
Microsoft.SqlServer.Management.Smo.Login
    Get-SqlLogin returns a Microsoft.SqlServer.Management.Smo.Login object.
.EXAMPLE
Get-SqlLogin "Z002\sql2K8"
This command gets a collection of SMO Login objects for SQL Server Z002\SQL2K8.
.LINK
Get-SqlLogin 
#>
function Get-SqlLogin
{
    param(
    [Parameter(Position=0, Mandatory=$true)] $sqlserver
    )

    switch ($sqlserver.GetType().Name)
    {
        'String' { $server = Get-SqlServer $sqlserver }
        'Server' { $server = $sqlserver }
        default { throw 'Get-SqlLogin:Param `$sqlserver must be a String or Server object.' }
    }

    Write-Verbose "Get-SqlLogin $($server.Name)"

    foreach ($login in $server.Logins | where {$_.LoginType.ToString() -ne 'Certificate'})
    {
        #Return Login Object
        $login 

    }

} # Get-SqlLogin

#######################
<#
.SYNOPSIS
Adds a login to a SQL Server.
.DESCRIPTION
The Add-SqlLogin function adds a new login to the specified SQL server.
.INPUTS
None
    You cannot pipe objects to Add-SqlLogin
.OUTPUTS
None
    This function does not generate any output.
.EXAMPLE
Add-SqlLogin "Z002\sql2k8" "TestPSUnit" "SQLPSXTesting" 'SqlLogin' 
This command adds the TestPSUnit login to the Z002\sql2k8 server.
.EXAMPLE
$server = Get-SqlServer "Z002\sql2k8"
Add-SqlLogin $server "TestPSUnit" "SQLPSXTesting" 'SqlLogin'
This command adds the TestPSUnit login to the Z002\sql2k8 server.
.LINK
Add-SqlLogin 
#>
function Add-SqlLogin
{
    param(
    [Parameter(Position=0, Mandatory=$true)] $sqlserver,
    [Parameter(Position=1, Mandatory=$true)] [string]$name,
    [Parameter(Position=2, Mandatory=$false)] [System.Security.SecureString]$password,
    [Parameter(Position=3, Mandatory=$false)] [Microsoft.SqlServer.Management.Smo.LoginType]$logintype='WindowsUser',
    [Parameter(Position=4, Mandatory=$false)] [string]$DefaultDatabase='master',
    [Parameter(Position=5, Mandatory=$false)] [switch]$PasswordExpirationEnabled,
    [Parameter(Position=6, Mandatory=$false)] [switch]$PasswordPolicyEnforced,
    [Parameter(Position=7, Mandatory=$true)] [string]$ChangeOrder,
    [Parameter(Position=8, Mandatory=$false)] [string]$Description
    )

    $ErrorActionPreference = "Stop"

    $PSUserName = $PSSenderInfo.UserInfo.Identity.Name

    switch ($sqlserver.GetType().Name)
    {
        'String' { $server = Get-SqlServer $sqlserver }
        'Server' { $server = $sqlserver }
        default { throw 'Add-SqlLogin:Param `$sqlserver must be a String or Server object.' }
    }

    Write-Verbose "Add-SqlLogin $($server.Name) $name"

    $login = new-object ('Microsoft.SqlServer.Management.Smo.Login') $server, $name
    $login.DefaultDatabase = $defaultDatabase

    if ($logintype -eq 'SqlLogin')
    {
        $login.LoginType = $logintype
        if ($server.Information.Version.Major -ne '8')
		{
		    $login.PasswordExpirationEnabled = $($PasswordExpirationEnabled.IsPresent)
        	    $login.PasswordPolicyEnforced = $($PasswordPolicyEnforced.IsPresent)
		}
        try { 
            $login.Create($password)
            $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"})
            write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage
        }
        catch {
                $message = $_.Exception.GetBaseException().Message
                $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"}) + "`n$message"
                write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage -EntryType 'Error'
                Write-Error $message
        }
    }
    elseif ($logintype -eq 'WindowsUser' -or $logintype -eq 'WindowsGroup')
    { 
        $login.LoginType = $logintype
        try {
            $login.Create()
            $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"})
            write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage
        }
        catch {
                $message = $_.Exception.GetBaseException().Message
                $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | % {"`n$($_.Key)=$($_.Value)"}) + "`n$message"
                write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage -EntryType 'Error'
                Write-Error $message
        }

    }

} #Add-SqlLogin

#######################
<#
.SYNOPSIS
Removes a login from a SQL Server.
.DESCRIPTION
The Remove-SqlLogin function removes a login from the specified SQL server.
.INPUTS
None
    You cannot pipe objects to Remove-SqlLogin
.OUTPUTS
None
    This function does not generate any output.
.EXAMPLE
Remove-SqlLogin "Z002\sql2k8" "TestPSUnit"
This command removes the TestPSUnit login from the Z002\sql2k8 server.
.EXAMPLE
$server = Get-SqlServer "Z002\sql2k8"
Remove-SqlLogin $server "TestPSUnit"
This command removes the TestPSUnit login from the Z002\sql2k8 server.
.LINK
Remove-SqlLogin 
#>
function Remove-SqlLogin
{

    param(
    [Parameter(Position=0, Mandatory=$true)] $sqlserver,
    [Parameter(Position=1, Mandatory=$true)] [string]$name,
    [Parameter(Position=2, Mandatory=$true)] [string]$ChangeOrder,
    [Parameter(Position=3, Mandatory=$false)] [string]$Description
    )

    $ErrorActionPreference = "Stop"

    $PSUserName = $PSSenderInfo.UserInfo.Identity.Name

    switch ($sqlserver.GetType().Name)
    {
        'String' { $server = Get-SqlServer $sqlserver }
        'Server' { $server = $sqlserver }
        default { throw 'Remove-SqlLogin:Param `$sqlserver must be a String or Server object.' }
    }

    Write-Verbose "Remove-SqlLogin $($server.Name) $name"

    $login = Get-SqlLogin $server | where {$_.name -eq $name}
    try {
        if ($login) {
            $login.Drop()
            $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"})
            write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage
        }
        else
        { throw "Login $name does not exist on server $($server.Name)." }
    }
    catch {
        $message = $_.Exception.GetBaseException().Message
        $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"}) + "`n$message"
        write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage -EntryType 'Error'
        Write-Error $message
    }

} #Remove-SqlLogin

#######################
<#
.SYNOPSIS
Removes a login from a SQL Server.
.DESCRIPTION
The Set-SqlLogin function changes a SQL Login Password.
.INPUTS
None
    You cannot pipe objects to Set-SqlLogin
.OUTPUTS
None
    This function does not generate any output.
.EXAMPLE
$pwd_secure_string = read-host "Enter a Password:" -assecurestring
Set-SqlLogin "Z002\sql2k8" "TestPSUnit" $pwd_secure_string
This command sets the password for TestPSUnit login.
.LINK
Set-SqlLogin 
#>
function Set-SqlLogin
{

    param(
    [Parameter(Position=0, Mandatory=$true)] $sqlserver,
    [Parameter(Position=1, Mandatory=$true)] [string]$name,
    [Parameter(Position=2, Mandatory=$true)] [System.Security.SecureString]$password,
    [Parameter(Position=3, Mandatory=$true)] [string]$ChangeOrder,
    [Parameter(Position=4, Mandatory=$false)] [string]$Description
    )

    $ErrorActionPreference = "Stop"

    $PSUserName = $PSSenderInfo.UserInfo.Identity.Name

    switch ($sqlserver.GetType().Name)
    {
        'String' { $server = Get-SqlServer $sqlserver }
        'Server' { $server = $sqlserver }
        default { throw 'Set-SqlLogin:Param `$sqlserver must be a String or Server object.' }
    }

    Write-Verbose "Set-SqlLogin $($server.Name) $name"

    $login = Get-SqlLogin $server | where {$_.name -eq $name}
    try {
        if ($login) {
            $login.ChangePassword($password,$true,$false)
            $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"})
            write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage
        }
        else
        { throw "Login $name does not exist on server $($server.Name)." }
    }
    catch {
        $message = $_.Exception.GetBaseException().Message
        $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"}) + "`n$message"
        write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage -EntryType 'Error'
        Write-Error $message
    }

} #Set-SqlLogin

#######################
<#
.SYNOPSIS
Removes a login from a SQL Server.
.DESCRIPTION
The Set-SqlLoginDefaultDatabase function changes a SQL Login default database.
.INPUTS
None
    You cannot pipe objects to Set-SqlLoginDefaultDatabase
.OUTPUTS
None
    This function does not generate any output.
.EXAMPLE
Set-SqlLoginDefaultDatabase "Z002\sql2k8" "TestPSUnit" 'master'
This command sets the default database for TestPSUnit login.
.LINK
Set-SqlLoginDefaultDatabase 
#>
function Set-SqlLoginDefaultDatabase
{

    param(
    [Parameter(Position=0, Mandatory=$true)] $sqlserver,
    [Parameter(Position=1, Mandatory=$true)] [string]$name,
    [Parameter(Position=2, Mandatory=$true)] [string]$DefaultDatabase,
    [Parameter(Position=3, Mandatory=$true)] [string]$ChangeOrder,
    [Parameter(Position=4, Mandatory=$false)] [string]$Description
    )

    $ErrorActionPreference = "Stop"

    $PSUserName = $PSSenderInfo.UserInfo.Identity.Name

    switch ($sqlserver.GetType().Name)
    {
        'String' { $server = Get-SqlServer $sqlserver }
        'Server' { $server = $sqlserver }
        default { throw 'Set-SqlLoginDefaultDatabase:Param `$sqlserver must be a String or Server object.' }
    }

    Write-Verbose "Set-SqlLoginDefaultDatabase $($server.Name) $name"

    $login = Get-SqlLogin $server | where {$_.name -eq $name}
    try {
        if ($login) {
            $login.DefaultDatabase = $DefaultDatabase
            $login.Alter()
            $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"})
            write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage
        }
        else
        { throw "Login $name does not exist on server $($server.Name)." }
    }
    catch {
        $message = $_.Exception.GetBaseException().Message
        $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"}) + "`n$message"
        write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage -EntryType 'Error'
        Write-Error $message
    }

} #Set-SqlLoginDefaultDatabase

#######################
<#
.SYNOPSIS
Removes a login from a SQL Server.
.DESCRIPTION
The Rename-SqlLogin function renames a SQL Login.
.INPUTS
None
    You cannot pipe objects to Rename-SqlLogin
.OUTPUTS
None
    This function does not generate any output.
.EXAMPLE
Rename-SqlLogin "Z002\sql2k8" "TestPSUnit" "CheckPSUnit"
This command renames the login TestPSUnit.
.LINK
Rename-SqlLogin 
#>
function Rename-SqlLogin
{

    param(
    [Parameter(Position=0, Mandatory=$true)] $sqlserver,
    [Parameter(Position=1, Mandatory=$true)] [string]$name,
    [Parameter(Position=2, Mandatory=$true)] [string]$newname,
    [Parameter(Position=3, Mandatory=$true)] [string]$ChangeOrder,
    [Parameter(Position=4, Mandatory=$false)] [string]$Description
    )

    $ErrorActionPreference = "Stop"

    $PSUserName = $PSSenderInfo.UserInfo.Identity.Name

    switch ($sqlserver.GetType().Name)
    {
        'String' { $server = Get-SqlServer $sqlserver }
        'Server' { $server = $sqlserver }
        default { throw 'Rename-SqlLogin:Param `$sqlserver must be a String or Server object.' }
    }

    Write-Verbose "Rename-SqlLogin $($server.Name) $name $newname"

    $login = Get-SqlLogin $server | where {$_.name -eq $name}
    try {
        if ($login) {
            $login.Rename("$newName")
            $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"})
            write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage
        }
        else
        { throw "Login $name does not exist on server $($server.Name)." }
    }
    catch {
        $message = $_.Exception.GetBaseException().Message
        $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"}) + "`n$message"
        write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage -EntryType 'Error'
        Write-Error $message
    }

} #Rename-SqlLogin

#######################
<#
.SYNOPSIS
Adds a new user to a database.
.DESCRIPTION
The Add-SqlUser function adds a new user to the specified database.
.INPUTS
None
    You cannot pipe objects to Add-SqlUser
.OUTPUTS
None
    This function does not generate any output.
.EXAMPLE
Add-SqlUser "Z002\sql2k8" "pubs" "TestPSUnit"
This command adds the TestPSUnit login to the pubs database.
.EXAMPLE
$database = Get-SqlDatabase "Z002\sql2k8" "pubs"
Add-SqlUser -dbname $database "TestPSUnit"
This command adds the TestPSUnit login to the pubs database.
.LINK
Add-SqlUser 
#>
function Add-SqlUser
{
    param(
    [Parameter(Position=0, Mandatory=$false)] $sqlserver,
    [Parameter(Position=1, Mandatory=$true)] $dbname,
    [Parameter(Position=2, Mandatory=$true)] [string]$name,
    [Parameter(Position=3, Mandatory=$false)] [string]$login=$name,
    [Parameter(Position=4, Mandatory=$false)] [string]$defaultSchema='dbo',
    [Parameter(Position=5, Mandatory=$true)] [string]$ChangeOrder,
    [Parameter(Position=6, Mandatory=$false)] [string]$Description
    )

    $ErrorActionPreference = "Stop"

    $PSUserName = $PSSenderInfo.UserInfo.Identity.Name

    switch ($dbname.GetType().Name)
    {
        'String' { $database = Get-SqlDatabase $sqlserver $dbname }
        'Database' { $database = $dbname }
        default { throw "Add-SqlUser:Param '`$dbname' must be a String or Database object." }
    }

    Write-Verbose "Add-SqlUser $($database.Name) $name"

    $user = new-object ('Microsoft.SqlServer.Management.Smo.User') $database, $name
    $user.Login = $login
	if ($db.parent.Information.Version.Major -ne '8')
	{ $user.DefaultSchema = $defaultschema }
    try {
        $user.Create()
        $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"})
        write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage
    }
    catch {
        $message = $_.Exception.GetBaseException().Message
        $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"}) + "`n$message"
        write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage -EntryType 'Error'
        Write-Error $message
    }

} #Add-SqlUser

#######################
<#
.SYNOPSIS
Removes a user from a database.
.DESCRIPTION
The Remove-SqlUser function removes a user from the specified database.
.INPUTS
None
    You cannot pipe objects to Remove-SqlUser
.OUTPUTS
None
    This function does not generate any output.
.EXAMPLE
Remove-SqlUser "Z002\sql2k8" "pubs" "TestPSUnit"
This command Removes the TestPSUnit user from the pubs database.
.EXAMPLE
$database = Get-SqlDatabase "Z002\sql2k8" "pubs"
Remove-SqlUser -dbname $database "TestPSUnit"
This command Removes the TestPSUnit user from the pubs database.
.LINK
Remove-SqlUser 
#>
function Remove-SqlUser
{
    param(
    [Parameter(Position=0, Mandatory=$false)] $sqlserver,
    [Parameter(Position=1, Mandatory=$true)] $dbname,
    [Parameter(Position=2, Mandatory=$true)] [string]$name,
    [Parameter(Position=3, Mandatory=$true)] [string]$ChangeOrder,
    [Parameter(Position=4, Mandatory=$false)] [string]$Description
    )

    $ErrorActionPreference = "Stop"

    $PSUserName = $PSSenderInfo.UserInfo.Identity.Name

    switch ($dbname.GetType().Name)
    {
        'String' { $database = Get-SqlDatabase $sqlserver $dbname }
        'Database' { $database = $dbname }
        default { throw "Remove-SqlUser:Param '`$dbname' must be a String or Database object." }
    }

    Write-Verbose "Remove-SqlUser $($database.Name) $name"

    $user = $database.Users[$name]
    try {
        if ($user) {
            $user.Drop()
            $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"})
            write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage
        }
        else
        { throw "User $name does not exist in database $($database.Name)." }
    }
    catch {
        $message = $_.Exception.GetBaseException().Message
        $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"}) + "`n$message"
        write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage -EntryType 'Error'
        Write-Error $message
    }

} #Remove-SqlUser

#######################
<#
.SYNOPSIS
Gets an SMO ServerRole object.
.DESCRIPTION
The Get-SqlServerRole function  gets a collection of SMO ServerRole objects for the specified SQL Server.
.INPUTS
None
    You cannot pipe objects to Get-SqlServerRole 
.OUTPUTS
Microsoft.SqlServer.Management.Smo.ServerRole
    Get-SqlServerRole returns a Microsoft.SqlServer.Management.Smo.ServerRole object.
.EXAMPLE
Get-SqlServerRole "Z002\sql2K8"
This command gets a collection of SMO ServerRole objects for SQL Server Z002\SQL2K8.
.LINK
Get-SqlServerRole 
#>
function Get-SqlServerRole
{
    param(
    [Parameter(Position=0, Mandatory=$true)] $sqlserver
    )

    switch ($sqlserver.GetType().Name)
    {
        'String' { $server = Get-SqlServer $sqlserver }
        'Server' { $server = $sqlserver }
        default { throw 'Get-SqlServerRole:Param `$sqlserver must be a String or Server object.' }
    }

    Write-Verbose "Get-SqlServerRole $($server.Name)"
 
    foreach ($svrole in $server.Roles)
    {
        #Return ServerRole Object
        $svrole 
    }

} #Get-SqlServerRole

#######################
<#
.SYNOPSIS
Adds a login to a server role.
.DESCRIPTION
The Add-SqlServerRoleMember function adds a login to the specified server role.
.INPUTS
None
    You cannot pipe objects to Add-SqlServerRoleMember
.OUTPUTS
None
    This function does not generate any output.
.EXAMPLE
Add-SqlServerRoleMember "Z002\sql2k8" "TestPSUnit" "bulkadmin"
This command adds the TestPSUnit login to the bulkadmin server role.
.EXAMPLE
$server = Get-SqlServer "Z002\sql2k8"
Add-SqlServerRoleMember $server "TestPSUnit" "bulkadmin"
This command adds the TestPSUnit login to the bulkadmin server role.
.LINK
Add-SqlServerRoleMember 
#>
function Add-SqlServerRoleMember
{
    param(
    [Parameter(Position=0, Mandatory=$true)] $sqlserver,
    [Parameter(Position=1, Mandatory=$true)] [string]$loginame,
    [Parameter(Position=2, Mandatory=$true)] [string]$rolename,
    [Parameter(Position=3, Mandatory=$true)] [string]$ChangeOrder,
    [Parameter(Position=4, Mandatory=$false)] [string]$Description
    )

    $ErrorActionPreference = "Stop"

    $PSUserName = $PSSenderInfo.UserInfo.Identity.Name

    switch ($sqlserver.GetType().Name)
    {
        'String' { $server = Get-SqlServer $sqlserver }
        'Server' { $server = $sqlserver }
        default { throw 'Add-SqlServerRoleMember:Param `$sqlserver must be a String or Server object.' }
    }

    Write-Verbose "Add-SqlServerRoleMember $($server.Name) $name"

    if($server.Logins | where {$_.name -eq $loginame})
    {
        $svrole = Get-SqlServerRole $server | where {$_.name -eq $rolename}

        try {
            if ($svrole) {
                $svrole.AddMember($loginame)
                $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"})
                write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage
            }
            else
            { throw "ServerRole $rolename does not exist on server $($server.Name)." }
        }
        catch {
            $message = $_.Exception.GetBaseException().Message
            $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"}) + "`n$message"
            write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage -EntryType 'Error'
            Write-Error $message
            }
    }
    else
    { throw "Login $loginame does not exist on server $($server.Name)." }

} #Add-SqlServerRoleMember

#######################
<#
.SYNOPSIS
Removes a login from a server role.
.DESCRIPTION
The Remove-SqlServerRoleMember function removes a login from the specified server role.
.INPUTS
None
    You cannot pipe objects to Remove-SqlServerRoleMember
.OUTPUTS
None
    This function does not generate any output.
.EXAMPLE
Remove-SqlServerRoleMember "Z002\sql2k8" "TestPSUnit" "bulkadmin"
This command Removes the TestPSUnit login from the bulkadmin server role.
.EXAMPLE
$server = Get-SqlServer "Z002\sql2k8"
Remove-SqlServerRoleMember $server "TestPSUnit" "bulkadmin"
This command Removes the TestPSUnit login from the bulkadmin server role.
.LINK
Remove-SqlServerRoleMember 
#>
function Remove-SqlServerRoleMember
{
    param(
    [Parameter(Position=0, Mandatory=$true)] $sqlserver,
    [Parameter(Position=1, Mandatory=$true)] [string]$loginame,
    [Parameter(Position=2, Mandatory=$true)] [string]$rolename,
    [Parameter(Position=3, Mandatory=$true)] [string]$ChangeOrder,
    [Parameter(Position=4, Mandatory=$false)] [string]$Description
    )

    $ErrorActionPreference = "Stop"

    $PSUserName = $PSSenderInfo.UserInfo.Identity.Name

    switch ($sqlserver.GetType().Name)
    {
        'String' { $server = Get-SqlServer $sqlserver }
        'Server' { $server = $sqlserver }
        default { throw 'Remove-SqlServerRoleMember:Param `$sqlserver must be a String or Server object.' }
    }

    Write-Verbose "Remove-SqlServerRoleMember $($server.Name) $name"

    if($server.Logins | where {$_.name -eq $loginame})
    {
        $svrole = Get-SqlServerRole $server | where {$_.name -eq $rolename}

        try {
            if ($svrole) {
                $svrole.DropMember($loginame)
                $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"})
                write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage
            }
            else
            { throw "ServerRole $rolename does not exist on server $($server.Name)." }
        }
    catch {
        $message = $_.Exception.GetBaseException().Message
        $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"}) + "`n$message"
        write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage -EntryType 'Error'
        Write-Error $message
        }
    }
    else
    { throw "Login $loginame does not exist on server $($server.Name)." }

} #Remove-SqlServerRoleMember

#######################
<#
.SYNOPSIS
Returns a SMO DatabaseRole object with additional properties.
.DESCRIPTION
The Get-SqlDatabaseRole function  gets a collection of SMO DatabaseRole objects for the specified SQL Database. 
.INPUTS
Microsoft.SqlServer.Management.Smo.Database
    You can pipe database objects to Get-SqlDatabaseRole 
.OUTPUTS
Microsoft.SqlServer.Management.Smo.DatabaseRole
    Get-SqlDatabaseRole returns a Microsoft.SqlServer.Management.Smo.DatabaseRole object.
.EXAMPLE
Get-SqlDatabaseRole $(Get-SqlDatabase "Z002\sql2K8" pubs)
This command gets a collection of SMO DatabaseRole objects for SQL Server Z002\SQL2K8, pubs database.
.EXAMPLE
Get-SqlDatabase "Z002\sql2K8" | Get-SqlDatabaseRole
This command gets a collection SMO DatabaseRole objects for all SQL databases on the SQL Server Z002\SQL2K8.
.LINK
Get-SqlDatabaseRole 
#>
function Get-SqlDatabaseRole
{
   param(
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)] [Microsoft.SqlServer.Management.Smo.Database]$database
    )

    process
    {
        foreach ($role in $database.Roles)
        {
            #Return DatabaseRole Object
            $role 
        }
    }
    
} #Get-SqlDatabaseRole

#######################
<#
.SYNOPSIS
Adds a user or role to a database role.
.DESCRIPTION
The Add-SqlDatabaseRoleMember function adds a user or role to the specified database role.
.INPUTS
None
    You cannot pipe objects to Add-SqlDatabaseRoleMember
.OUTPUTS
None
    This function does not generate any output.
.EXAMPLE
Add-SqlDatabaseRoleMember "Z002\sql2k8" "pubs" "TestPSUnit" "TestPSUnitDBRole" 
This command adds the TestUnit user to the TestPSUnitDBRole database role.
.EXAMPLE
$database = Get-SqlDatabase "Z002\sql2k8" "pubs"
Add-SqlDatabaseRoleMember -dbname $database -name "TestPSUnit" -rolename "TestPSUnitDBRole" 
This command adds the TestUnit user to the TestPSUnitDBRole database role.
.LINK
Add-SqlDatabaseRoleMember 
#>
function Add-SqlDatabaseRoleMember
{
    param(
    [Parameter(Position=0, Mandatory=$false)] $sqlserver,
    [Parameter(Position=1, Mandatory=$true)] $dbname,
    [Parameter(Position=2, Mandatory=$true)] [string]$name,
    [Parameter(Position=3, Mandatory=$true)] [string]$rolename,
    [Parameter(Position=4, Mandatory=$true)] [string]$ChangeOrder,
    [Parameter(Position=5, Mandatory=$false)] [string]$Description
    )

    $ErrorActionPreference = "Stop"

    $PSUserName = $PSSenderInfo.UserInfo.Identity.Name

    switch ($dbname.GetType().Name)
    {
        'String' { $database = Get-SqlDatabase $sqlserver $dbname }
        'Database' { $database = $dbname }
        default { throw "Add-SqlDatabaseRoleMember:Param '`$dbname' must be a String or Database object." }
    }

    Write-Verbose "Add-SqlDatabaseRoleMember $($database.Name) $name $rolename"

    if(($database.Users | where {$_.name -eq $name}) -or ($database.Roles | where {$_.name -eq $name}))
    {
        $role = Get-SqlDatabaseRole $database | where {$_.name -eq $rolename}

        try {
            if ($role) {
                $role.AddMember($name)
                $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"})
                write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage
            }
            else
            { throw "DatabaseRole $rolename does not exist in database $($database.Name)." }
        }
        catch {
            $message = $_.Exception.GetBaseException().Message
            $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"}) + "`n$message"
            write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage -EntryType 'Error'
            Write-Error $message
        }
    }
    else
    { throw "Role or User $name does not exist in database $($database.Name)." }

} #Add-SqlDatabaseRoleMember

#######################
<#
.SYNOPSIS
Removes a user or role from a database role.
.DESCRIPTION
The Remove-SqlDatabaseRoleMember function removes a user or role from the specified database role.
.INPUTS
None
    You cannot pipe objects to Remove-SqlDatabaseRoleMember
.OUTPUTS
None
    This function does not generate any output.
.EXAMPLE
Remove-SqlDatabaseRoleMember "Z002\sql2k8" "pubs" "TestPSUnit" "TestPSUnitDBRole" 
This command removes the TestUnit user to the TestPSUnitDBRole database role.
.EXAMPLE
$database = Get-SqlDatabase "Z002\sql2k8" "pubs"
Remove-SqlDatabaseRoleMember -dbname $database -name "TestPSUnit" -rolename "TestPSUnitDBRole" 
This command removes the TestUnit user to the TestPSUnitDBRole database role.
.LINK
Remove-SqlDatabaseRoleMember 
#>
function Remove-SqlDatabaseRoleMember
{
    param(
    [Parameter(Position=0, Mandatory=$false)] $sqlserver,
    [Parameter(Position=1, Mandatory=$true)] $dbname,
    [Parameter(Position=2, Mandatory=$true)] [string]$name,
    [Parameter(Position=3, Mandatory=$true)] [string]$rolename,
    [Parameter(Position=4, Mandatory=$true)] [string]$ChangeOrder,
    [Parameter(Position=5, Mandatory=$false)] [string]$Description
    )

    $ErrorActionPreference = "Stop"

    $PSUserName = $PSSenderInfo.UserInfo.Identity.Name

    switch ($dbname.GetType().Name)
    {
        'String' { $database = Get-SqlDatabase $sqlserver $dbname }
        'Database' { $database = $dbname }
        default { throw "Remove-SqlDatabaseRoleMember:Param '`$dbname' must be a String or Database object." }
    }

    Write-Verbose "Remove-SqlDatabaseRoleMember $($database.Name) $name $rolename"

    if(($database.Users | where {$_.name -eq $name}) -or ($database.Roles | where {$_.name -eq $name}))
    {
        $role = Get-SqlDatabaseRole $database | where {$_.name -eq $rolename}

        try {
            if ($role) {
                $role.DropMember($name)
                $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"})
                write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage
            }
            else
            { throw "DatabaseRole $rolename does not exist in database $($database.Name)." }
        }
        catch {
            $message = $_.Exception.GetBaseException().Message
            $logmessage =  "PSUserName=$PSUserName" + $($psBoundParameters.GetEnumerator() | %{"`n$($_.Key)=$($_.Value)"}) + "`n$message"
            write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $logmessage -EntryType 'Error'
            Write-Error $message
        }
    }
    else
    { throw "Role or User $name does not exist in database $($database.Name)." }

} #Remove-SqlDatabaseRoleMember

#######################
<#
.SYNOPSIS
Writes an entry to SqlProxy Log File.
.DESCRIPTION
The Write-SqlProxyLog function writes an entry to the SqlProxy Log File.
.INPUTS
None
    You cannot pipe objects to Write-SqlProxyLog
.OUTPUTS
None
    This function does not generate any output.
.EXAMPLE
$message =  "PSUserName=$PSUserName`n" + $($psBoundParameters.GetEnumerator() | %{"$($_.Key)=$($_.Value)"})
write-sqlproxylog -eventID $eventID."$($myinvocation.mycommand.name)" -message $message
This command writes a message to the SQLProxy Log
.NOTES
This must be run as administrator to create the new EventLog and EventLog Source!!!
New-EventLog -LogName SqlProxy -Source SqlProxy
.LINK
Write-SqlProxyLog 
#>
function Write-SqlProxyLog
{
    param(
    [Parameter(Position=0, Mandatory=$true)] $EventID,
    [Parameter(Position=1, Mandatory=$true)] $Message,
    [Parameter(Position=2, Mandatory=$false)] $EntryType='SuccessAudit'
    )

    write-eventlog -logname SqlProxy -source SqlProxy -eventID $eventID -message $message -EntryType $EntryType
    
} #Write-SqlProxyLog

