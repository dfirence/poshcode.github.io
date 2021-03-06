$views = (get-vm | get-view)
$views += (get-template | get-view)

$VMDatastores = get-datastore

$views | foreach {

    $vm = $PSItem

     foreach ($VMDSUsage in $vm.storage.PerDatastoreUsage) {
        $dsReport = [ordered]@{}
        $VMDatastore = $VMDatastores | where { $_.ID -match "datastore-$($VMDSUsage.datastore.value)"}
        $dsReport.VMName = $vm.name
        $dsReport.Datastore = $VMDatastore.Name
        $dsReport.UsedGB = [math]::round(($VMDSUsage.committed / 1GB),2)
        $dsReport.ProvisionedGB = [math]::round((($VMDSUsage.committed + $VMDSUsage.Uncommitted) / 1GB),2)
        $dsReport.DatastoreUsagePct = [math]::round((($dsReport.UsedGB / $VMDatastore.CapacityGB) * 100),2)
        new-object PSObject -property $dsReport
    }


}
