#Change these settings as needed
#MS Access 2007 Data Components required
$connString = 'Provider=Microsoft.ACE.OLEDB.12.0;WSS;IMEX=2;RetrieveIds=Yes; DATABASE=http://sharepoint.acme.com/;LIST={96801432-2d03-42b8-82b0-ac96ca9fea8a};'
#See http://chadwickmiller.spaces.live.com/blog/cns!EA42395138308430!275.entry for instructions on obtaining list GUID
$qry = 'Select Title,Notes,CreateDate, Modified, Created from list'
#Create a table in destination database with the with referenced columns and table name.

$sqlserver = 'Z002\SQL2K8'
$dbname = 'SQLPSX'
$tblname = 'splist_fill'

#######################
function Get-SPList
{

    param($connString, $qry='select * from list')

    $spConn = new-object System.Data.OleDb.OleDbConnection($connString)
    $spConn.open()
    $cmd = new-object System.Data.OleDb.OleDbCommand($qry,$spConn) 
    $da = new-object System.Data.OleDb.OleDbDataAdapter($cmd) 
    $dt = new-object System.Data.dataTable 
    [void]$da.fill($dt)
    $dt

} #Get-SPList

#######################
function Write-DataTableToDatabase
{ 
    param($dt,$destServer,$destDb,$destTbl)

    $connectionString = "Data Source=$destServer;Integrated Security=true;Initial Catalog=$destdb;"
    $bulkCopy = new-object ("Data.SqlClient.SqlBulkCopy") $connectionString
    $bulkCopy.DestinationTableName = "$destTbl"
    $bulkCopy.WriteToServer($dt)

}# Write-DataTableToDatabase

#######################

$dt = Get-SPList $connString $qry
Write-DataTableToDatabase $dt $sqlserver $dbname $tblname
