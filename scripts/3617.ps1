##################################################################################
#
#  Script name: Set-LocalAccount.ps1
#  Author:      niklas.goude@zipper.se
#  Homepage:    www.powershell.nu
#  http://www.powershell.nu/wp-content/uploads/2009/07/set-localaccount.ps1
# start script - .\set-localaccount.ps1 -DS user.csv -Add
##################################################################################

#param([string]$DS, [switch]$Add, [switch]$Remove, [switch]$ResetPassword)
param([string]$DS, [string]$UserName, [string]$Password, [string]$fio, [switch]$Add, [switch]$Remove, [switch]$disable, [switch]$ResetPassword)
#param([string]$DS, [string]$dataSource,[string]$UserName, [string]$Password, [string]$fio, [switch]$Add, [switch]$Remove, [switch]$ResetPassword, [switch]$help)

function AddRemove-LocalAccount ([string]$DS, [switch]$Add, [switch]$Remove, [switch]$disable, [switch]$ResetPassword) {
#function AddRemove-LocalAccount ([string]$DS, [string]$dataSource, [string]$UserName, [string]$Password, [string]$fio, [switch]$Add, [switch]$Remove, [switch]$ResetPassword) {

	[string]$ComputerName = "$Env:COMPUTERNAME"



	if($Add) {        
        # new
        $ADSI = [adsi]"WinNT://$Env:COMPUTERNAME"
        $dataSource = Import-Csv $DS -Delimiter ";"        
        #$dataSource = Import-Csv user.csv -Delimiter ";"        
        foreach ($dataRecord in $dataSource) {
        $UserName = $dataRecord.name
        $Password = $dataRecord.password        
        $fio = $dataRecord.fio                
        $User = $ADSI.Create("user",$UserName)
        $User.Put("Description", $Password)
        $User.Put("FullName", $fio)
		$User.SetPassword($Password)
        $User.SetInfo()                
                
        }
	}
    
    
	if($Remove) {
		$ADSI = [adsi]"WinNT://$Env:COMPUTERNAME"
        #[string]$ConnectionString = "WinNT://$ComputerName"
		$ADSI = [adsi]$ConnectionString
        $ADSI.Delete("user",$UserName)
        #$User.SetInfo()
	}
    if($disable) {
    # Disable the account
            [string]$ConnectionString = "WinNT://" + $ComputerName + "/" + $UserName + ",user"           
            $account=[ADSI]$ConnectionString
            $account.psbase.invokeset("AccountDisabled", "True")
            $account.setinfo()
    
    }
	if($ResetPassword) {	
        
        [string]$ConnectionString = "WinNT://" + $ComputerName + "/" + $UserName + ",user"
		$Account = [adsi]$ConnectionString
        $User.Put("Description", $Password)
        $User.SetInfo() 
		$Account.psbase.invoke("SetPassword", $Password)
	}
}


if($DS -AND !$ResetPassword) { AddRemove-LocalAccount -DS $DS -Add}
if($UserName -AND $Password -AND $ResetPassword) { AddRemove-LocalAccount -UserName $UserName -Password $Password -ResetPassword }
if($Username -AND $disable) {AddRemove-LocalAccount -UserName $UserName -disable }
if($UserName -AND $Remove) { AddRemove-LocalAccount -UserName $UserName -Remove }
