# Get-MySQLDataSet - Query a MySQL server & return the result to a PoSh variable
# Created:  11/29/07	Modified:  11/29/07
# Written by:  Matt Wilson (Kemis / Matt at ClearChoiceIT dot com) with MAJOR help from
# Joel Bennett (Jaykul):  http://powershellcentral.com/scripts/57
# Andrew Dashin:  http://andrewdashin.com/powershell-mysql.aspx
# Robbie Foust (rfoust):  http://posh.jaykul.com/p/588
# And many, many more in the #Powershell freenode IRC channel!
##################################################################################

# Input variables - Adjust to taste
param 	( 	$server = "server"			# Server name/IP address of database host
		,	$username = "user"		# User ID to database (not necessarily Linux login)
		,	$password = "password"	# User ID's password
		,	$database = "dbname"	# Database name you'd like to query
		,	$global:Query = 'SELECT `user_index`,`user_login`,`user_fname`,`user_lname`,`user_passwd` FROM `dbname` WHERE 1'	# What would you like to get?
		)

# We require the full path to the MySQL.Data.dll
# Modify according to your own path to this library
# Need the library?  Get it from:  http://dev.mysql.com/downloads/connector/net/5.0.html
[void][system.reflection.Assembly]::LoadFrom("C:\Program Files\MySQL\MySQL Connector Net 5.0.8.1\Binaries\.NET 2.0\MySQL.Data.dll")

# Connection string derived from the above variables
function global:Set-SqlConnection ( $server = $(Read-Host "SQL Server Name"), $username = $(Read-Host "Username"), $password = $(Read-Host "Password"), $database = $(Read-Host "Default Database") ) {
	$SqlConnection.ConnectionString = "server=$server;user id=$username;password=$password;database=$database;pooling=false"
}

# A function to allow the user to perform a query that returns a table full of data
function global:Get-SqlDataTable( $Query = $(if (-not ($Query -gt $null)) {Read-Host "Query to run"}) ) {
	# Open the DB connection if it's not already
	# Typically, leave the opening & closing up to this function
	if (-not ($SqlConnection.State -like "Open")) { $SqlConnection.Open() }
	# Create the SQL command object & pre-supply the query & connection string properties
	$SqlCmd = New-Object MySql.Data.MySqlClient.MySqlCommand $Query, $SqlConnection
	# I still have no clue what a SQL Data Adapter is, but create it & supply the command object
	$SqlAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter
	$SqlAdapter.SelectCommand = $SqlCmd
	# Create a new dataset object to hold our query results
	$DataSet = New-Object System.Data.DataSet
	# Using the adapter, we fill the DataSet with our results
	# NOTE: out-null to prevent # of rows returned from appearing in the resulting array
	$SqlAdapter.Fill($DataSet) | Out-Null
	# Close the database connection & return the results
	$SqlConnection.Close()
	return $DataSet.Tables[0]
}

# Global variable to store MySQL connection info so it can be used anytime
# This variable is used by the help functions above
Set-Variable SqlConnection (New-Object MySql.Data.MySqlClient.MySqlConnection) -Scope Global -Option AllScope -Description "Personal variable for Sql Query functions"

# Establish & open the database connection
Set-SqlConnection $server $username $password $database

# Run the query to actually get the table & do what you'd like with it in PoSh!
# $global:dbusers = Get-SqlDataTable $Query

