function ExecSQLcmd{
      param(
            [string]$ServerName,
            [string]$DatabaseName,
            [string]$UserN,
            [string]$Password,
            [string]$SQLCommand,
            [Boolean]$IsQuery = $False
            )     
            
      #Output Results to DataSet
      if ($IsQuery -eq $true)
            {     
                  $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
                  $SqlConnection.ConnectionString = "server=$ServerName;database=$DatabaseName;Integrated Security=sspi"
                  $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
                  $SqlCmd.CommandText = $SQLCommand
                  $SqlCmd.Connection = $SqlConnection
                  $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
                  $SqlAdapter.SelectCommand = $SqlCmd
                  $DataSet = New-Object System.Data.DataSet
                  $SqlAdapter.Fill($DataSet) | out-null
                  $SqlConnection.Close()
                  return $DataSet
         	} else  {
                  $conStr = "server=$ServerName;database=$DatabaseName;Integrated Security=sspi"
                  $cn = new-object System.Data.SqlClient.SqlConnection $conStr
                  $cn.Open()
                  $sql = $cn.CreateCommand()
                  $sql.CommandText = $SQLCommand
                  $rdr = $sql.ExecuteReader()         
                  $cn.Close()
            }
            #Close connection 
}


$adapters = Adapters query goes here

foreach ($adapter in $adapters)
{
			$sqlstr= "$sqlstr INSERT INTO MYTABLENAME"
			$sqlstr= "$sqlstr (column1"
			$sqlstr= "$sqlstr ,column2)"
			$sqlstr= "$sqlstr VALUES"
			$sqlstr= "$sqlstr ('value1'"
			$sqlstr= "$sqlstr ,'value2')"
			ExecSQLcmd -ServerName "mysqlserver01" -DatabaseName "test" -SQLCommand $sqlstr
}

