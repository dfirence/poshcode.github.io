@@This code was copied from the site http://www.ti4fun.com
@@-----------------------------------------------------------


Public Function ConvDataReaderToDataTable(Byval command As System.Data.SqlClient.SqlCommand) As System.Data.DataTable
        Dim datatable As New System.Data.DataTable
        Dim reader As System.Data.SqlClient.SqlDataReader = command.ExecuteReader()

        Try

            datatable.Load(reader)

        Finally
            reader.Close()
            command.Connection = Nothing
        End Try

        Return datatable
    End Function




@@This code was copied from the site http://www.ti4fun.com
@@-----------------------------------------------------------

