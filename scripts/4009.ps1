#Script to add a value to the VMX file of a virtual client.
#This is to remove the ability to eject the network card as described in
#http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1012225
#
#Values within <> are relevant to the environment the script is run in.
########################################################################################################
FunctionCheckVMX
{
ForEach ($vmCHECK in $vmLIST)
{
$Error.psbase.clear()$Option = $vmCHECK.extensionData.config.extraconfig | where {$_.Key -eq "devices.hotplug"}
If ($Option.value -match "false")
{
"Value already present in VMX file for " + $vmCHECK 
}
Else
{
EditVMX
}
}
}########################################################################################################FunctionEditVMX{
$Error.psbase.clear()

$vm = Get-View (Get-VM $vmCHECK).ID
$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
$vmConfigSpec.extraconfig += New-Object VMware.Vim.optionvalue
$vmConfigSpec.extraconfig[0].Key="devices.hotplug"
$vmConfigSpec.extraconfig[0].Value="false"
$vm.ReconfigVM($vmConfigSpec)

If ($Error.Count -eq 0){
"Updated VMX File for " + $vmCHECK
}
Else
{
"Error deleting " + $vmCHECK$Error[0].exception
}
}########################################################################################################
#Main Part of the Script
#Add VMware PowerCLI Snapin
add-pssnapinVMware.VimAutomation.Core

#Ignore vCenter certificate error and connect to single vCenter Instance
Set-PowerCLIConfiguration-InvalidCertificateAction "Ignore" -DefaultVIServerMode "single" -Confirm:$false

#Connect to vCenter InstanceConnect-VIServer<vCenter IP> -user "<vCenter Logon>" -pass <password>

#Create list of VM's file and log file paths
$Date= get-date -uformat "%d-%m-%Y"
$LogDir= "<Log Location>"
$Log= $LogDir + "\EditVM-" + $Date + ".log"
$vmLIST= Get-VM | Where-Object {$_.PowerState -eq "PoweredOff"} | Where-Object {$_.Name -like "<Client Name>"}

#Set error action preference to silently continue
$ErrorActionPreference= 'SilentlyContinue'

#Run function and write output to logfile
CheckVMX| Out-File $Log

#Disconnect from vCenter Instance
Disconnect-VIServer-Server * -Force -Confirm:$false

#Script End 

