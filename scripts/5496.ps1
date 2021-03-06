##########################################################################
## CDOT-Check - V1 OCT '14 (For CDOT 8.2.X)                             ##
## ==================================================================== ##
## CAVEAT UTILITOR! This program comes with no warranty and no support! ##
################################################################################
## CONTENTS - This script can be broken down into the following sections:     ##
## 1) (Generic) PowerShell Functions                                          ##
## 2) (Generic) Data ONTAP PowerShell Toolkit Functions                       ##
## 3) CLUSTER CONNECT        Set of Functions                                 ##
## 4) HEALTH CHECK           Set of Functions (ADD ADDITIONAL CHECKS HERE!)   ##
## 5) GET/SAVE CONFIGURATION Set of Functions                                 ##
## 6) DISPLAY-ALL            Set of Functions (Used by GET-CONFIGURATION)     ##
## 7) LOAD CLUSTERCFG        Set of Functions                                 ##
## 8) COMPARE-DATA           Set of Functions                                 ##
## 0) MAIN MENU                                                               ##
################################################################################

$title = "CDOT-Check - V1 OCT '14 (For CDOT 8.2.X)"
$TKmajor = 3; $TKminor = 1 # Recommended minimum DOT PSTK major.minor version
[String]$P               = $null                        # Used to put text into some Wr-* Functions
$aggrUsedThreshold       = 90                           # % used threshold for health check (default)
$clusterCfg              = New-Object 'object[,]' 2,3   # Define an array of 2 x 3 for 2 cluster configuration with filename, node count, data SVM count! (might make this global!)
$global:CfgContent       = New-Object 'object[]' 2      # Use to store the Get-Content of the clustercfg files
$global:saveConfig       = $null                        # Re-initialized in Get-Configuration as an array
$whoAmI                  = $env:username                # The user running this script
$workingPath             = $env:USERPROFILE             # The users profile (used to save credentials) Note: Originally used (pwd).path
$defaultClusterCfgFolder = $workingPath + "\CLUSTERCFG" # Default folder for CLUSTERCFG files
$global:CompareA = @{}; $global:CompareB = @{}          # Define hashtables for A&B compare options (CLUSTER=,CLUSTERFILE=,NODE=,NODEFILE=,SVM=,SVMFILE=)

# NEW CLUSTER/NODE/SVM CONFIGURATION CHECKS CAN BE ADDED HERE!
# These are the Get-Nc*'s we use to get configuration information from CLUSTERs/NODEs/SVMs
# Note 1: "$global:currentnccontroller.Vserver =" does not work with nodes - for this reason GetNcNODEs is a bit different
# Note 2: These variables are all used in "FN:GET-CONFIGURATION" and "FN:COMPARE-DATA" (supplied via parameter)

$GetNcCLUSTER    = ("Get-NcCluster","Get-NcSnmp","Get-NcOption","Get-NcTimezone","Get-NcNetDns","Get-NcNetDnsHost","Get-NcConfigBackupURL","Get-NcConfigBackupCount","Get-NcLicense",
                    "Get-NcEmsConfig","Get-NcEmsDestination","Get-NcJobCronSchedule","Get-NcJobIntervalSchedule","Get-NcKerberosRealm",
					"Get-NcNetOption","Get-NcNetRoutingGroupRoute","Get-NcNetInterface",
					"Get-NcSnapmirrorPolicy","Get-NcSecurityCertificate","Get-NcSecuritySSL","Get-NcSnapshotPolicy")
$GetNcCLUSTERLR  = ("Get-NcUser","Get-NcRoleConfig","Get-NcRole")
$GetNcNODE       = ("Get-NcNode -Name","Get-NcSystemImage -Node","Get-NcServiceProcessor -Node","Get-NcOption -Vserver","Get-NcAutoSupportConfig -Node","Get-NcClusterHA","Get-NcVol -Vserver",
                    "Get-NcNetRoutingGroupRoute","Get-NcNetInterface -Vserver",
					"Get-NcNetPort -Node","Get-NcNetPortIfgrp -Node","Get-NcNetPortVlan -Node",
					"Get-NcAggrNodeInfo -Name","Get-NcSecurityCertificate -Vserver","Get-NcSecuritySSL -Vserver")
$GetNcAGGR       = ("Get-NcAggr","Get-NcAggrOption")
$GetNcSVM        = ("Get-NcVserver","Get-NcOption","Get-NcNetDns","Get-NcNetDnsHost","Get-NcFileServiceAudit","Get-NcFlexcachePolicy",
                    "Get-NcFpolicyStatus","Get-NcFpolicyPolicy","Get-NcFpolicyEvent",
					"Get-NcKerberosConfig","Get-NcLdapConfig","Get-NcLdapClient",
					"Get-NcNetRoutingGroupRoute","Get-NcNetInterface",
					"Get-NcSnapmirrorPolicy","Get-NcSecurityCertificate","Get-NcSecuritySSL","Get-NcSisPolicy","Get-NcSnapshotPolicy")
$GetNcSVMLR      = ("Get-NcUser","Get-NcRoleConfig","Get-NcRole")
$GetNcSVMCIFS    = ("Get-NcCifsServer","Get-NcCifsPreferredDomainController","Get-NcGpo","Get-NcCifsOption","Get-NcCifsSecurity","Get-NcCifsHomeDirectorySearchPath",
	                "Get-NcCifsLocalUser","Get-NcCifsLocalGroup","Get-NcCifsLocalGroupMember","Get-NcCifsShareAcl","Get-NcCifsShare")
$GetNcSVMNFS     = ("Get-NcNfsService","Get-NcNis",
                    "Get-NcNameMapping","Get-NcNameMappingUnixGroup","Get-NcNameMappingUnixUser",
					"Get-NcExportPolicy","Get-NcExportRule","Get-NcNfsExport")
$GetNcSVMVOLUMES = ("Get-NcQtree","Get-NcQuota","Get-NcQuotaStatus",
					"Get-NcSis","Get-NcSnapshotAutodelete","Get-NcSnapshotReserve",
					"Get-NcVol","Get-NcVolAutosize","Get-NcVolLanguage","Get-NcVolOption")

$clusterConfigurations = $GetNcCLUSTER + $GetNcCLUSTERLR
$nodeConfigurations    = $GetNcNODE + $GetNcAGGR
$SVMConfigurations     = $GetNcSVM + $GetNcSVMLR + $GetNcSVMCIFS + $GetNcSVMNFS

################################################################################
## 1) (Generic) PowerShell Functions                                          ##
################################################################################

Function Pad-R{ Param([string]$string, [int]$int=30)               # Takes in a -string $string, and -int $int (with default Pad Right value)
	$string.PadRight($int," ").SubString(0,$int) }                 # Pads it right to $padR with " " and cuts it down to size if it was too big to start with	
Function Pad-L{ Param([string]$in, [int]$padL=3, [string]$pad=" ") # Input a string $in, $padL (with default Pad Left number), what to $pad with
	$in.PadLeft($padL,$pad) }                                      # Pads $in left with $padL and $pad

Function Columnize-W{ # ---------------------------------------------------------- # Function Columnize-W (White)
	$i = 0                                                                         # Initialize counter $i = 0
	while($i -lt $args.count){                                                     # While $i is less than the count of arguments
        Write-Host ((Pad-R $args[$i] $args[$i+1]) + " ") -F White -NoNewline       # Write to screen $args[i] adjusted to size $args[i], " ", and in white, with no new line after
        $i += 2                                                                    # Accumulate count by 2 (since have sets of 2 arguments)
    }                                                                              # END of while $i < count of arguments
	Write-Host                                                                     # Starts a new line for the next row
} # ------------------------------------------------------------------------------ # END of Columnize-W (White)

Function Columnize-C{ # ---------------------------------------------------------- # Function Columnize-C (Colour)
	$i = 0                                                                         # Initialize counter $i = 0
	while($i -lt $args.count){                                                     # While $i is less than the count of arguments
        Write-Host ((Pad-R $args[$i] $args[$i+1]) + " ") -F $args[$i+2] -NoNewline # Write to screen $args[i] adjusted to size $args[i], " ", and in color $args[$i+2], with no new line after
        $i += 3                                                                    # Accumulate count by 3 (since have sets of 3 arguments)
    }                                                                              # END of while $i < count of arguments
	Write-Host                                                                     # Starts a new line for the next row
} # ------------------------------------------------------------------------------ # END of Columnize-C (Colour)

Function Wr-E{Write-Host}                                                     # Writes a Carriage Return (Enter)
Function Wr-C{If($args[0]){$P=$args[0]};Write-Host $P -F Cyan}                # Writes supplied argument text in Cyan
Function Wr-D{If($args[0]){$P=$args[0]};Write-Host $P -F DarkGray}            # Writes supplied argument text in Dark Gray
Function Wr-G{If($args[0]){$P=$args[0]};Write-Host $P -F Green}               # Writes supplied argument text in Green
Function Wr-M{If($args[0]){$P=$args[0]};Write-Host $P -F Magenta}             # Writes supplied argument text in Magenta
Function Wr-R{If($args[0]){$P=$args[0]};Write-Host $P -F Red}                 # Writes supplied argument text in Red
Function Wr-W{If($args[0]){$P=$args[0]};Write-Host $P -F White}               # Writes supplied argument text in White
Function Wr-Y{If($args[0]){$P=$args[0]};Write-Host $P -F Yellow}              # Writes supplied argument text in Yellow
Function Wn-C{If($args[0]){$P=$args[0]};Write-Host $P -F Cyan -NoNewline}     # Writes supplied argument text in Cyan (no new line after)
Function Wn-D{If($args[0]){$P=$args[0]};Write-Host $P -F DarkGray -NoNewline} # Writes supplied argument text in Dark Gray (no new line after)
Function Wn-G{If($args[0]){$P=$args[0]};Write-Host $P -F Green -NoNewline}    # Writes supplied argument text in Green (no new line after)
Function Wn-R{If($args[0]){$P=$args[0]};Write-Host $P -F Red -NoNewline}      # Writes supplied argument text in Red (no new line after)
Function Wn-W{If($args[0]){$P=$args[0]};Write-Host $P -F White -NoNewline}    # Writes supplied argument text in White (no new line after)
Function Wn-Y{If($args[0]){$P=$args[0]};Write-Host $P -F Yellow -NoNewline}   # Writes supplied argument text in Yellow (no new line after)
Function Rd-W{                                                                # Read from host in White (because default isn't)
    If($args){Write-Host ($args[0]) -F White -NoNewline}                      # If supplied $args then write to the screen $args[0] first with NoNewLine
    return (Read-Host "?")}                                                   # Then prompt!

Function Prompt-Keys{ # --------------------------------------------- # This expects key presses so the args should all be only one character long!
	Param([switch]$anykey)                                            # Allows any key to be pressed / Allows the key to be echoed to screen
	If(!$anykey -and !$args[0]){ return $null }                       # No args when not using the -anykey is not a valid option
	If($args[0]){                                                     # Might have no $args[0] if using the -anykey option
		If($args[0].count -ne 1){ $answers = $args[0] }               # If the 1st argument - $args[0] - is an array, use this for the list of possible answers
		else { $answers  = $args[0..(($args.count)-1)] } }            # Otherwise, take all the other arguments for the list of possible answers
	while($true){                                                     # Infinite loop! Escape via valid keypress or anykey if -anykey set!
		$keyPress = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")   # The Key Press (no ECHO)
		$keyPress = $keyPress.character.ToString().ToUpper()          # Compare in upper case (and return in upper case)
		If($anyKey){return $keypress}                                 # If $anyKey and no $args[0] we can return now
		foreach($answer in $answers){                                 # Loop through the answers
			if($keyPress -eq $answer.ToUpper()){ return $keyPress } } # Check if the answer to the prompt equals a valid answer, and if so then return
		Write-Host " " -NoNewLine; Write-Host "`b" -NoNewLine         # Writes a space then does a backspace (Allows refocusing back to the menu prompt)
	}                                                                 # END of while $true
} # ----------------------------------------------------------------- # END of Prompt-Keys

Function Prompt-Menu{
	$question = $args[0]
	If(($args[1].count) -ne 1){$answers = $args[1]} # If $args[1] is an array use it
	else{$answers  = $args[1..(($args.count)-1)]}   # Else take all arguments except the first
	while($true){
		$readIn = Read-Host "$question"
		$readIn = $readIn.ToUpper() # Function always compares and returns in upper case
		foreach($answer in $answers){
			if($readIn -eq $answer.ToUpper()){return $readIn} }	} }

Function Set-Window{ # ---------------------------------------------------------- # Set-Window
	Param([string]$textcolor,[string]$background,[string]$title,[int]$percentMax) # -textcolor COLOR -background COLOR -title TITLE -percentMax %MAX_of_SCREEN_SIZE
	$window = (get-host).UI.RawUI                                                 # Gets the current Window properties
	If($textcolor)      {$window.ForegroundColor = $textcolor}                    # If $textcolor parameter, sets the textcolor
	If($background -and ($window.BackgroundColor -ne $background)){               # If $background parameters and it's not equal to what it is set to already
        $window.BackgroundColor = $background;cls}                                # ... set the background and do a CLS
	If($title)          {$window.WindowTitle = $title}                            # Set's the Window Title!
	$buffer            = $window.BufferSize                                       # Gets buffersize
	$buffer.Height     = 9999                                                     # ... set maximum buffer hit
	$window.BufferSize = $buffer                                                  # ... apply
	If($perCentMax){                                                              # If $perCentMax parameter
		$maxX = [int](($window.MaxPhysicalWindowSize.Width)*$percentMax/100)      # ... find our new X size
		$maxY = [int](($window.MaxPhysicalWindowSize.Height)*$percentMax/100)     # ... find our new Y size
		$buffer.Width = $maxX                                                     # ... buffer = maxX
		$window.BufferSize = $buffer                                              # ... apply
		$size = $window.WindowSize                                                # ... get WindowSize
		$size.Width = $maxX                                                       # ... set maxX
		$size.Height = $maxY                                                      # ... set maxY
		$window.WindowSize = $size                                                # ... apply
	}                                                                             # END of $perCentMax
} # ----------------------------------------------------------------------------- # END of Set-Window

Function Format-Units{ # -------------------------------------------------------------- #
	Param([int64]$raw,[string]$unit) # Take as parameters the value and a UNIT          #
	$unit = $unit.ToUpper()          # Uppercase the UNIT                               #
	If($unit -eq "GB"){return (([int64]($raw/(1024*1024*1024))).ToString() + " $unit")} # If "GB" Gigabytes
} # More units to be added! ----------------------------------------------------------- #

Function Create-Folder { # ------------------------------------------------------- # INPUT = The folder or path to a folder for a new folder
	If(!$args[0]){ return $null }                                                  # If no/null argument supplied, return NULL
	If(Test-Path $args[0] -ErrorAction SilentlyContinue){ return ($args[0]) }      # If it already exists, it returns back the name of the folder
	Else {[Void](New-item $args[0] -type directory -ErrorAction SilentlyContinue)} # Otherwise try and create it
	If(Test-Path $args[0] -ErrorAction SilentlyContinue){ return ($args[0]) }      # If folder now exists, return back the name of the folder
	Else { return $null }                                                          # Otherwise return NULL
} # ------------------------------------------------------------------------------ # END Create-Folder

################################################################################
## 2) (Generic) Data ONTAP PowerShell Toolkit Functions                       ##
################################################################################

Function Check-PSTK{
	if(!(Get-Module DataONTAP)){Import-Module DataONTAP -ErrorAction SilentlyContinue}
	if(!(Get-Module DataONTAP)){return $null}
	$true}
	
Function Check-PSTKversion{
	Param($major,$minor)
	$ver = Get-NaToolKitVersion
	if($ver.major -lt $major){return $null}elseif($ver.major -gt $major){return $true}
	if($ver.minor -lt $minor){return $null}
	$true}
	
Function Current-Cluster {
	If($global:currentnccontroller.name){ $ClusterName = (Get-NcCluster).ClusterName } else { return $null} # Ensures correct case/returns NULL if no .name
	If($ClusterName){ return $ClusterName } else { Current-ClusterNull; return $null }}                     # Returns CLUSTERNAME if one/else reset connection and return NULL
Function Current-ClusterIP  {$global:currentnccontroller.Address.IPAddressToString}
Function Current-ClusterNull{$global:currentnccontroller = $null}
Function Current-UserName   {$global:currentnccontroller.Credentials.Username}
Function Current-Vserver    {$global:currentnccontroller.Vserver}
Function Current-VserverSet {$global:currentnccontroller.Vserver = $args[0]}
Function Current-VserverNull{$global:currentnccontroller.Vserver = $null}

################################################################################
## 3) CLUSTER CONNECT        Set of Functions                                 ##
################################################################################

Function Cluster-Connect{ # --------------- # Cluster-Connect
	Wr-W ">>>>>>> Connect to Cluster"; Wr-E # Heading
	while ($true) {                         # START: WHILE ($TRUE)
		Wr-W "Enter Netbios/FQDN/IP of Cluster to connect to (or enter to return to MAIN MENU)?";Wr-E
		$cluster = Read-Host; Wr-E          # Read input
		If(!$cluster){return}               # Return to Main Menu if enter is pressed
		$getCreds = Get-Creds; Wr-E         # Get-Creds
		If($getCreds){return}               # If Get-Creds return to main menu (else it will prompt again)
	}                                       # END:   WHILE ($TRUE)
} # --------------------------------------- # Note: $cluster is used in the called functions below!

Function Get-Creds{
	$filePath = $workingPath + "\" + $cluster + "-" + $whoAmI + ".cred"
	Wn-W "Checking for credentials at ";Wr-C $filepath
	$check = Test-Path $filePath
	If (!$check){
		Wr-Y "No saved credentials for $cluster detected!"; Wr-E
		$PromptForCreds = Prompt-ForCreds
		If($PromptForCreds){return $true} else {return $null}
	} else {
		$readFile = Get-Content $filePath
		$rdUsername = $readFile[0] # Variable used in UseSavedCreds
		$rdPassword = $readFile[1] # Variable used in UseSavedCreds		
		Wr-G "Saved credentials for $cluster detected with user $rdUsername!"; Wr-E
		Wn-G "<<<<< Re-use credentials <Y/N>: "
		$key = Prompt-Keys "Y" "N"; Wr-Y $key; Wr-E
		If($key -eq "Y"){
			$UseSavedCreds  = Use-SavedCreds
			If($UseSavedCreds) {return $true} else {return $null}}
		If($key -eq "N"){
			$PromptForCreds = Prompt-ForCreds
			If($PromptForCreds){return $true} else {return $null}}
	}
}

Function Prompt-ForCreds{
	Wr-W "Enter username to connect to $cluster (or enter to return)?"; Wr-E
	$username = Read-Host; Wr-E
	If(!$username){return $null}
	Wr-W "Enter the password (or enter to return)?"; Wr-E
	$securePassword = Read-Host -AsSecureString; Wr-E
	If($securePassword.length -eq 0){return $null}
	$password       = $securePassword | ConvertFrom-SecureString
	$credential     = New-Object System.Management.Automation.PsCredential($username,$securePassword)
	$connect        = Connect-NcController $cluster -Credential $credential -ErrorAction SilentlyContinue
	If($connect){
		Wn-G "Connected!"; Wn-W " Saved credentials to "; Wr-C $filePath
		[Void](New-Item $filePath -Type file -Force)
		$username,$password | Set-Content $filePath
		return $true
	} else {
		Wr-R "Failed to connect!"
		return $null
	}
}

Function Use-SavedCreds{
	$securePassword = $rdPassword | ConvertTo-SecureString
	$credential = New-Object System.Management.Automation.PsCredential($rdUsername,$securePassword)
	$connect = Connect-NcController $cluster -Credential $credential -ErrorAction SilentlyContinue
	If($connect){Wr-G "Connected!";return $true} else {Wr-R "Failed to connect!";return $false}}

################################################################################
## 4) HEALTH CHECK           Set of Functions (ADD MORE HEALTH CHECKS HERE)   ##
################################################################################

Function Check-Health{
	
	$nodes                = Get-NcNode # Used with node checks ($node is available to functions)
	$SVMquery             = Get-NcVserver -Template
	$SVMquery.VserverType = "data"
	$dataSVMs             = Get-NcVserver -Query $SVMquery # Data SVMs
	$cifsServers          = 0 # Count later
	$nfsServers           = 0 # Count later
	
	Wr-W ">>>>> Get-NcDiagnosisSubsystem Checks"; Wr-E
	Display-HC (get-ncdiagnosissubsystem cifs_ndo) $cCluster "health" "ok"
	Display-HC (get-ncdiagnosissubsystem sas_connect) $cCluster "health" "ok"
	Display-HC (get-ncdiagnosissubsystem switch_health) $cCluster "health" "ok"; Wr-E
	
	Wr-W ">>>>> Get-NcNode Checks"; Wr-E	
	$nodes | foreach {Check-Nodes $_ 24} # Uptime > 24 hours
	
	Wr-W ">>>>> Get-NcAutoSupportConfig Checks"; Wr-E
	$nodes | foreach {Check-ASUP ($_.node)}; Wr-E

	Wr-W ">>>>> Get-NcAutoSupportHistory Checks"; Wr-E
	$nodes | foreach {Check-AsupSent ($_.node)}; Wr-E
	
	Wr-W ">>>>> Get-NcNetPort Checks"; Wr-E
	$nodes | foreach {Check-Ports ($_.node)}
	
	Wr-W ">>>>> Get-NcAggr Checks"; Wr-E
	$nodes | foreach {Check-Aggrs $_}

	Wr-W ">>>>> Get-NcEmsMessage Checks"; Wr-E
	$nodes | foreach {Check-EventLog ($_.node) 24} # Check events in last 24 hours! 
		
	Wr-W ">>>>> Get-NcVserver Checks"; Wr-E
	$dataSVMs | foreach {Check-DataSVMs $_}; Wr-E

	Wr-W ">>>>> Get-NcCifs Checks"; Wr-E
	$dataSVMs | foreach {If(($_.AllowedProtocols).Contains("cifs")){$cifsServers++;Check-CIFS ($_.Vserver)}}
	If($countCifsServers -eq 0){Wr-C "No CIFS enabled SVMs!"}; Wr-E
		
	Wr-W ">>>>> Get-NcNfsService Checks"; Wr-E
	$dataSVMs | foreach {If(($_.AllowedProtocols).Contains("nfs")){$nfsServers++;Check-NFS ($_.Vserver)}}
	If($nfsServers -eq 0){Wr-C "No NFS enabled SVMs!"}; Wr-E
	
}

Function Display-HC { # Display-HC is used to display Health Checks with different conditions! #

	Param(
		$thingToDot,$toDisplay,$member,$greenResult,$memberOverride,$resultOverride,
		[switch]$lt,[switch]$gt,[switch]$ni,[switch]$ct,[switch]$pass,[switch]$failY)
	
	$result = $thingToDot.$member
	If($resultOverride){$outResult = " = " + $resultOverride} else {$outResult = " = " + $result}
	If($memberOverride){$outString = (Pad-R ($toDisplay + "." + $memberOverride) 40) + $outResult}
	else               {$outString = (Pad-R ($toDisplay + "." + $member)         40) + $outResult}

	$P = $outString                                                        # The complete output ($P feeds into Wr-* functions)
	If($lt) {If($result -lt $greenResult)      {Wr-G} else {Wr-R}; return} # Green is result Less Than greenResult
	If($gt) {If($result -gt $greenResult)      {Wr-G} else {Wr-R}; return} # Green is result Greater Than greenResult
	If($ni) {If(!$result)                      {Wr-G} else {Wr-R}; return} # Green is the null result
	If($ct) {If($result.contains($greenResult)){Wr-G} else {Wr-R}; return} # Green if it contains the greenResult
	If($pass)                                  {Wr-G             ; return} # No checking, returns in green
	If($failY)                                 {Wr-Y             ; return} # No checking, returns in yellow
	If(!$greenResult)                          {Wr-C             ; return} # If no $greenresult parameter out with WrC
	If($result -eq $greenResult)               {Wr-G} else {Wr-R}          # Standard check

}

Function Check-Nodes {
	Param($node,[int]$hoursUp = 24)
	$nodeName = $node.Node
	$secondsUptime = $hoursUp*60*60
	Display-HC $node $nodeName "IsNodeHealthy" "true"
	Display-HC $node $nodeName "NodeUptime" $secondsUptime -gt
	Display-HC $node $nodeName "EnvFailedFanCount" "0"
	Display-HC $node $nodeName "EnvFailedPowerSupplyCount" "0"
	Display-HC $node $nodeName "EnvOverTemperature" -ni
	Display-HC $node $nodeName "NvramBatteryStatus" "battery_ok"
	Display-HC $node $nodeName "IsEpsilonNode"
	Display-HC $node $nodeName "IsNodeClusterEligible" "true"
	Wr-E}

function Check-ASUP {
	Param([string]$nodeName)
	$attributes                  = Get-NcAutoSupportConfig -Template
	$attributes.IsEnabled        = ""
	$attributes.IsSupportEnabled = ""
	$getAsupConf                 = Get-NcAutoSupportConfig -Node $nodeName -Attributes $attributes
	Display-HC $getAsupConf $nodeName "IsEnabled" "true"
	Display-HC $getAsupConf $nodeName "IsSupportEnabled" "true"}

function Check-AsupSent {

	Param([string]$nodeName)
	$outString            = (Pad-R ($nodeName + ".ASUP Sent Successfully") 40) + " ="      # Define display out string
	
	$attributes           = Get-NcAutoSupportConfig -Template                               # Get-NcAutoSupportConfig: Template
	$attributes.Transport = ""                                                              # Get-NcAutoSupportConfig: Transport = "" (Attribute)
	$getAsupConf          = Get-NcAutoSupportConfig -Node $nodeName -Attributes $attributes # Get-NcAutoSupportConfig <<<
	$transport            = $getAsupConf.transport                                          # Get ASUP Transport

	If ($transport -eq "https"){ $transport = "http"}                                       # Get-NcAutoSupportHistory 'Destination' is smtp/http/noteto only!
	$attributes           = Get-NcAutoSupportHistory -Template                              # Get-NcAutoSupportHistory: Template for Attributes
	$attributes.Status    = ""	                                                            # Get-NcAutoSupportHistory: Status = "" (Attribute)
	$query                = Get-NcAutoSupportHistory -Template                              # Get-NcAutoSupportHistory: Template for Queries
	$query.Destination    = $transport                                                      # Get-NcAutoSupportHistory: Destination = $transport (Query)
	$query.NodeName       = $nodeName                                                       # Get-NcAutoSupportHistory: Node = $nodeName (Query)
	$getAsupHistory       = Get-NcAutoSupportHistory -Attributes $attributes -Query $query  # Get-NcAutoSupportHistory <<<
	$asupHistoryCount     = $getAsupHistory.count                                           # Count the rows of ASUP History
	if ($asupHistoryCount -eq 0){ Wr-R "$outString No ASUP History!"; return}               # If no ASUP History, report this, and return!
	
	$i = 0
	while ($i -lt $asupHistoryCount) {   ## Cycle through ASUP History ##
		if ($getAsupHistory[$i].status -eq "transmission_failed"){Wr-R "$outString Failed!";          return}
		if ($getAsupHistory[$i].status -eq "sent-successful"){    Wr-R "$outString Sent Successful!"; return}
		$i++}
	
	Wr-R "$outString Failed!"
	
}	
	
Function Check-Ports{
	Param([string]$nodeName)
	$ncNetPort = Get-NcNetPort -Node $nodeName
	$ncNetPort | foreach {
		$port     = $_.Port
		$adminUp  = $_.IsAdministrativeUp
		$link     = $_.LinkStatus
		$nodePort = "$nodeName" + ":" + "$port"
		$P = "$nodePort.LinkStatus = $link (and IsAdminUp = $adminUp)";If($adminUp -and ($link -eq "up")){Wr-G}else{Wr-R}
		Display-HC $_ $port "OperationalDuplex" "full"
		Display-HC $_ $port "AdministrativeDuplex" "full"
		Display-HC $_ $port "OperationalFlowcontrol" "none"
		Display-HC $_ $port "AdministrativeFlowcontrol" "none"
		Display-HC $_ $port "OperationalSpeed"
		Display-HC $_ $port "AdministrativeSpeed" "auto"
		Display-HC $_ $port "IsOperationalAutoNegotiate" "True"
		Display-HC $_ $port "IsAdministrativeAutoNegotiate" "True"
		Display-HC $_ $port "Mtu"
		Wr-E}}

Function Check-Aggrs{

	Param($node)
	
	$volCount             = 0
	$nodename             = $node.Node
	$maxAggrSize          = $node.MaximumAggregateSize
	$maxAggrSizeDisplay   = Format-Units $maxAggrSize GB
	$maxAggrSizeThreshold = $maxAggrSize*0.95
	
	$NcAggrQuery       = Get-NcAggr -Template
	$NcAggrQuery.Nodes = $nodename
	$aggrs             = Get-NcAggr  -Query $NcAggrQuery

	$aggrs | foreach {
			
		$root     = $false
		$aggrname = $_.name

		Display-HC $_ $aggrname "state" "online"
		Display-HC $_ $aggrname "RaidType" "normal" -ct
		Display-HC ($_.AggrOwnershipAttributes) $aggrname "HomeName" ($_.AggrOwnershipAttributes.OwnerName)

		If($_.AggrRaidAttributes.HasLocalRoot){Display-HC ($_.AggrRaidAttributes) $aggrname "HasLocalRoot";$root = $true}
		$modulo = ($_.Disks) % ($_.RaidSize)
		If(!$root -and ($modulo -eq 0)){			
				Display-HC $_ $aggrname "Disks" -Pass
				Display-HC $_ $aggrname "RaidSize" -Pass
		} elseif (!$root -and ($modulo -ne 0)) {
				Display-HC $_ $aggrname "Disks" -FailY
				Display-HC $_ $aggrname "RaidSize" -FailY
		}

		Display-HC $_ $aggrname "used" $aggrUsedThreshold "UsedPercent" -lt
		Display-HC $_ $aggrname "TotalSize" $maxAggrSizeThreshold "TotalSize (max = $maxAggrSizeDisplay)" -r (Format-Units $_.TotalSize GB) -lt
		Display-HC ($_.AggrSnapshotAttributes) $aggrname "SizeUsed" "0" "SnapshotSpaceUsed"
		Display-HC ($_.AggrSnapshotAttributes) $aggrname "SnapshotReservePercent" "0"
		Display-HC ($_.AggrPerformanceAttributes) $aggrname "FreeSpaceRealloc"

		Wr-E
		$volCount += $_.volumes
		
	} # END $aggrs
	
	$maxVols  = $_.MaximumNumberOfVolumes
	$maxVolTH = $maxVols*0.95
	$P = "$nodename has $volCount volumes from a maximum of $maxVols!";If ($volCount -lt $maxVolTH){Wr-G} else {Wr-R}
	Wr-E

} 

Function Check-EventLog{

	Param([string]$nodeName,[int]$hours = 24)
	$attributes       = Get-NcEmsMessage -Template
	$attributes.Event = ""
	$attributes.Node  = ""
	$attributes.Time  = ""
	$severityList     = "EMERGENCY","R","ALERT","R","CRITICAL","R","ERROR","Y","WARNING","Y"
	$sevListCount     = $severityList.count
	
	$i = 0 
	$uniqueMessages = New-Object 'object[]' 5 # 5 severities
	while ($i -lt $sevListCount) {
		$severity = $severityList[$i]
		$colour   = $severityList[$i+1]
		$ems      = Get-NcEmsMessage -Severity $severity -StartTime (Get-Date).AddHours(-$hours) -Attributes $attributes -Node $nodeName
		$emsCount = $ems.count
		$P = "$nodeName has $emsCount events for type $severity in the last $hours hours!"; If($emsCount -eq 0){Wr-G} elseif($colour -eq "R"){Wr-R} else{Wr-Y}
		$uniqueMessages[$i/2] = Check-EventLogUniqueMessages
		$i+=2
	} 
	Wr-E
	
	$i = 0
	while ($i -lt $sevListCount) {
		$uniqueMessageTable  = $uniqueMessages[$i/2]
		$uniqueMessageCount  = $uniqueMessageTable.count
		If ($uniqueMessageCount -ne 0){
			$colour              = $severityList[$i+1]
			Wr-W ("$nodeName occurrences of unique " + $severityList[$i] + " events in the last $hours hours >")
			Columnize-W "Count" 5 "Last Occurrence" 20 "Event" 80
			$y = 0
			while ($y -lt $uniqueMessageCount) {
				Columnize-C $uniqueMessageTable[3,$y] 5 $colour $uniqueMessageTable[0,$y] 20 $colour $uniqueMessageTable[2,$y] 80 $colour
				$y++
				If(!$uniqueMessageTable[0,$y]){$y = $uniqueMessageCount}
			}
			Wr-E
		}
		$i+=2
	}
}

Function Check-EventLogUniqueMessages {
	$outputArray = New-Object 'object[,]' 4,$emsCount
	$arrayYsize = 0 
	foreach ($message in $ems){
		$match = Check-EventLogMessageMatch
		if (!$match){
			$outputArray[0,$arrayYsize]=$message.TimeDT
			$outputArray[1,$arrayYsize]=$message.Node
			$outputArray[2,$arrayYsize]=$message.Event
			$outputArray[3,$arrayYsize]=1
			$arrayYsize++	
		}
	} # END of foreach ($message in $messages)
	, $outputArray
}

Function Check-EventLogMessageMatch{
	$j=0
	while ($j -lt $arrayYsize){ # NOTE SURE why the -1
		if ($message.Event -eq $outputArray[2,$j]){
			$outputArray[3,$j]++ # Accumulate the counter
			return $true         # Have found a match - stop checking!
		}
		$j++
	}
	return $false
} 

Function Check-DataSVMs {
	Param($dataSVM)
	Display-HC $dataSVM ($dataSVM.Vserver) "State" "running"}

Function Check-CIFS {
	Param([string]$currentVserver)
	Current-VserverSet $currentVserver
	$getCifsServer = Get-NcCifsServer
	If (!$getCifsServer){Wr-R "$currentVserver has CIFS allowed but no CIFS server created!"; Current-VserverNull; return}
	$cifsServer    = $getCifsServer.CifsServer
	Display-HC $getCifsServer $cifsServer "AdministrativeStatus" "up"
	Current-VserverNull}

Function Check-NFS{
	Param([string]$currentVserver)
	Current-VserverSet $currentVserver
	$getNfsService = Get-NcNfsService
	If (!$getNfsService){Wr-R "$currentVserver has NFS allowed but no NFS server created!"; Current-VserverNull; return}
	Display-HC $getNfsService $currentVserver "GeneralAccess" "True"
	Current-VserverNull}

################################################################################
## 5) GET/SAVE CONFIGURATION Set of Functions                                 ##
###################################################################################
# For saving configurations, the txt file has headers and footers like the below: #
# #START#WHAT-TYPE-OF-CONFIGURATION(CLUSTER/NODE/SVM)#ENTITY-NAME#GET-?           #
# #FINIR#WHAT-TYPE-OF-CONFIGURATION(CLUSTER/NODE/SVM)#ENTITY-NAME#GET-?           #
###################################################################################

Function Get-Configuration {

	$nodes             = (Get-NcNode).Node                     # NODE: Get list of Node Names
	$query             = Get-NcVserver -Template               # SVM: Template for Get-NcVserver
	$query.VserverType = "data"                                # SVM: Query for "data" Vservers
	$dataSVMs          = (Get-NcVserver -Query $query).Vserver # SVM: Get list of Data SVMs Names
	
	# Initialize the content for the clustercfg file
	$saveConfig   = @()               # The configuration is saved into this array
	$saveConfig  += "$cCluster"       # First row  [0] of $saveConfig = Cluster Name	
	[string]$listOfNodes = "";$nodes | foreach {$listOfNodes += $_ + ","}
	$saveConfig  += $listOfNodes      # Second row [1] of $saveConfig = List of Nodes (separated by ,)
	$saveConfig  += ($nodes.count)    # Third row  [2] of $saveConfig = nodes count
	[string]$listOfSVMs  = "";$dataSVMs | foreach {$listOfSVMs += $_ + ","}
	$saveConfig  += $listOfSVMs       # Fourth row [3] of $saveConfig = List of SVMs (separated by ,)
	$saveConfig  += ($dataSVMs.count) # Fifth row  [4] of $saveConfig = Data SVMs count
	
	## >> CLUSTER Configurations << ##
	
	foreach ($getNc in $clusterConfigurations){
			Get-CFGwDisplayAll CLUSTER $cCluster $getNc } 
	
	## >> NODE Configurations << ##
	
	foreach ($getNc in $GetNcNODE){
		foreach ($node in $nodes){
			Get-CFGwDisplayAll NODE $node $getNc } }

	## >> AGGREGATE Configurations (still NODE entity type) << ##
	
	$attributes = Get-NcAggr -template
	$query      = Get-NcAggr -template
	Initialize-NcObjectProperty -object $query -name AggrOwnershipAttributes	
	foreach ($getNc in $GetNcAGGR){
		foreach ($node in $nodes){
			Wn-W ">>>>> NODE:          "; Wr-C $node
			Wn-W ">>>>> Configuration: "; Wr-C $getNc; Wr-E
			$saveConfig += "#START#NODE#$node#$getNc"
			$query.AggrOwnershipAttributes.OwnerName = $node
			$aggrs = (Get-NcAggr -Attributes $attributes -Query $query).Name | sort
			$lastAggr = $aggrs[$aggrs.count-1]
			foreach ($aggr in $aggrs){
				$aggrHeader = "AGGREGATE".PadRight(30," ") + " = " + $aggr
				Display-CI $aggrHeader
				$cmdToDisplayAll = $getNc + " -Name " + $aggr
				$output = Display-All $cmdToDisplayAll -All
				$output | foreach {Display-CI $_}
				If($aggr -ne $lastAggr) { Display-CI " " }
			}			
			$saveConfig += "#FINIR#NODE#$node#$getNc"
			Wr-E
		}
	}
	
	## >> SVM Configurations << ##
	
	foreach ($getNc in $SVMConfigurations){
		foreach ($dataSVM in $dataSVMs){
			Get-CFGwDisplayAll SVM $dataSVM $getNc } }
			
	## >> VOLUMES Configurations (still SVM entity type) << ##
	
	$attributes = Get-NcVol -template
	foreach ($getNc in $GetNcSVMVOLUMES){
		foreach ($dataSVM in $dataSVMs){
			Current-VserverSet $dataSVM
			Wn-W ">>>>> SVM:           "; Wr-C $dataSVM
			Wn-W ">>>>> Configuration: "; Wr-C $getNc; Wr-E
			$saveConfig += "#START#SVM#$dataSVM#$getNc"
			$volumes = (Get-NcVol -Attributes $attributes).Name | sort
			$lastVol = $volumes[$volumes.count-1]
			If (($getNc -eq "Get-NcVolOption") -or ($getNc -eq "Get-NcVolLanguage") -or ($getNc -eq "Get-NcVolAutoSize"))
				{ $switchParam = " -Name " } else { $switchParam = " -Volume " }
			foreach ($volume in $volumes) {
				$volHeader = "VOLUME".PadRight(30," ") + " = " + $volume
				Display-CI $volHeader
				$cmdToDisplayAll = $getNc + $switchParam + $volume
				$output = Display-All $cmdToDisplayAll -All
				$output | foreach {Display-CI $_}
				If($volume -ne $lastVol) { Display-CI " " }
			}
			$saveConfig += "#FINIR#SVM#$dataSVM#$getNc"
			Wr-E		
		}
	}; Current-VserverNull

}

Function Display-CI { Param($member); $saveConfig += $member; Wr-C $member }

Function Get-CFGwDisplayAll { # NOTE: Only used with CLUSTER/NODE/SVM above (and not AGGRS in NODEs, and VOLS in SVMs)!
	Param($EntityType,$SVMname,$GetNcCommand)	
	If ($EntityType -ne "NODE") {                                               # IF "!NODE"
		        Current-VserverSet $SVMname                                     # . Current-VserverSet (does not work with anything "NODE")
		        $cmdToDisplayAll = $GetNcCommand                                # . STANDARD $cmdToDisplayAll
	} elseif (  $GetNcCommand -eq "Get-NcClusterHA" ){                          # OVERRIDE for "Get-NcClusterHA"
				$cmdToDisplayAll = "(Get-NcClusterHa -Node $SVMName).SfOptions" # . CUSTOM SHOW just .SfOptions
	} else	 {  $cmdToDisplayAll = $GetNcCommand + " " + $SVMName}              # If "NODE" add NODENAME to $GetNcCommand
	$output = Display-All $cmdToDisplayAll -All
	$EntityDisplay = ($EntityType + ":").PadRight(14)
	Wn-W ">>>>> $EntityDisplay ";Wr-C $SVMname
	Wn-W ">>>>> Configuration: ";Wr-C $cmdToDisplayAll; Wr-E
	$saveConfig += "#START#$EntityType#$SVMname#$GetNcCommand"
	$output | foreach {Display-CI $_}
	$saveConfig += "#FINIR#$EntityType#$SVMname#$GetNcCommand"
	Current-VserverNull; Wr-E } 

Function Save-Configuration{
	Wr-W ">>>>>>> Save Configuration";Wr-E
	$dateString = Get-Date -uformat "%Y%m%d"
	Wn-W "Current folder for clustercfg files = "; Wr-C $clusterCfgFolder
	Wn-W "Default filename                    = "; Wr-C "$cCluster.$dateString.clustercfg"; Wr-E
	Wn-G "<<<<< Use default filename <Y/N>: "
	$key = Prompt-Keys "Y" "N"; Wr-Y $key; Wr-E	
	If ($key -eq "Y"){$saveFile = "$clusterCfgFolder\$cCluster.$dateString.clustercfg"}
	If ($key -eq "N"){
		$filename = Read-Host "Enter filename (.clustercfg is added)?";Wr-E
		If(!$filename){return}
		$saveFile = "$clusterCfgFolder\$filename.clustercfg"
	}
	[Void](New-Item $saveFile -Type file -Force)
	Get-Configuration
	$saveConfig | Out-File $saveFile
}

################################################################################
## 6) DISPLAY-ALL            Set of Functions (Used by GET-CONFIGURATION)     ##
################################################################################
	
Function Display-All {
	Param($getCmd,[int]$padR = 30,[switch]$all = $null)
	If(!$getCmd)   { return }
	If($getCmd.gettype().name -eq "String"){$parsedCmd = Invoke-Expression $getCmd}
	else {$parsedCmd = $getCmd}
	If(!$parsedCmd){ return }
	$parsedCmdCount = $parsedCmd.count
	If( ($parsedCmd.Name.count -ge 1) -and                          # Override for Name - Value pairs
	    ($parsedCmd.Name.count -eq $parsedCmd.Value.count) )        # As an example, this is required for: 
		                           { Display-AllNameValuePairs    } # Get-NcOption
	elseif ($parsedCmdCount -eq 1) { Display-AllMembers $parsedCmd} # If $parsedCmdCount = 1, it is not an array
	else {                                                          # ... otherwise it is an array
		$count = 0                                                  # To count where in the array
		$parsedCmd | foreach {                                      # Cycle through the array $parsedCmd
			Display-AllMembers $_                                   # Invoke Display-AllMembers
			$count++                                                # Accumulate count of where in the array
			If ($count -ne $parsedCmdCount){" "} } } }              # Adds a space between array items (but not after the last)

Function Display-AllNameValuePairs{
	$parsedCmd | foreach { ($_.Name).PadRight($padR," ").SubString(0,$padR) + " = " + ($_.Value) } }

Function Display-AllMembers{
	Param($element,[int]$padL=1)
	($element|gm) | foreach{Member-Data $element $_} }
	
Function Member-Data {
	Param($element,$member)
	If($member.MemberType -eq "Method"){return}
	$name    = $member.Name
	$checks  = "Specified","NcController","Vserver","VserverName","VserverType","PublicCertificate"
	foreach($check in $checks){If($name.Contains($check)){return}}
	$data    = $element.$name
	$padding = $name.length + $padL
	$output  = $name.PadLeft($padding,".").PadRight($padR," ").SubString(0,$padR) + " = " + $data
	If (!$data){If($all){return $output}else{return}}
	$checks  = "bool","string[]","NcController","System.Object"
	foreach($check in $checks){If($member.Definition.Contains($check)){return $output}}
	$checks  = "String","Boolean","TimeSpan","DateTime","Int32","Int64"
	foreach($check in $checks){If($data.gettype().name -eq $check){return $output}}
	If (($data|gm).count -eq 0){return $output}
	$name.PadLeft($padding,".");$padL++
	$output  = Display-AllMembers $data $padL
	return $output}

################################################################################
## 7) LOAD CLUSTERCFG        Set of Functions                                 ##
################################################################################

Function Set-ClusterCFGFolder{
	Wr-W "Enter folder/folderpath for clustercfg files?"; Wr-E
	$readIn     = Read-Host; Wr-E
	$testCreate = Create-Folder $readIn
	If (!$testCreate){Wr-R "Failed to create folder!"; Wr-E; return $clusterCfgFolder} # If fails to create, we return the original $clusterCfgFolder
	else {return $readIn}                                                              # Otherwise we return the new clustercfg folder
}

Function Load-ClusterCfg {

	Param([int]$fileNumber)
	Wr-W ">>>>>>> Load ClusterCfg File"; Wr-E
	Wn-W "Folder/folderpath for clustercfg files = "; Wr-C $clusterCfgFolder
	$items        = Get-ChildItem -Path $clusterCfgFolder
	$searchString = "*.clustercfg"
	
	# Note: -like will only return true and not the list of matches if the array is only 1 in size
	If     ( $items.count -eq 0) { Wr-R "No *.clustercfg files in this folder!"; Wr-E; return $null} 
	elseif (($items.count -eq 1) -and ($items.name -like $searchString)) { $matches = @(); $matches += $items.name } # Makes $matches to be an array with 1 item
	else   { $matches = $items -like $searchString }
	If     (!$matches)           { Wr-R "No *.clustercfg files in this folder!"; Wr-E; return $null}
	
	Wr-E; Wr-W "Clustercfg Files in this Directory:"; Wr-E
	
	$i = 1
	$promptOptions = @()
	$promptOptions += "0"
	Wr-W "  0) Unload clustercfg file and/or Return to Main Menu"
	$matches | foreach{
		$promptOptions += ($i.toString())
		$display = Pad-L ($i.toString())
		Wr-C "$display) $_"
		$i++
	}; Wr-E
	
	$answer = Prompt-Menu "Choose clustercfg file to load (or 0)?" $promptOptions
	Unload-ClusterCfg                  # We unload the clustercfg for this filenumber prior to reloading it below
	If($answer -eq "0"){ Wr-E; return} # If 0 is chosen return (clustercfgfile unloaded)
	
	$chosenFilename = $matches[([Int]$answer) -1] # We allow chosing the same clustercfg file twice! (for checking script functionality)	
	$content        = Get-Content ($clusterCfgFolder + "\" + $chosenFilename) -ErrorAction SilentlyContinue
	If(!$content){ Wr-E; Wr-R "Unable to load file!"; Wr-E; return}

	$clusterCfg[$fileNumber,0] = $chosenFilename
	$clusterCfg[$fileNumber,1] = $content[2] # Count of nodes is on line 3 of the clustercfg file
	$clusterCfg[$fileNumber,2] = $content[4] # Count of SVMs  is on line 5 of the clustercfg file
	$CfgContent[$fileNumber]   = $content
	
	If($fileNumber -eq 0){ $CompareA.CLUSTER = $content[0]; $CompareA.CLUSTERFILE = 0} # Automatically sets Compare A and B for clusters
	If($fileNumber -eq 1){ $CompareB.CLUSTER = $content[0]; $CompareB.CLUSTERFILE = 1} # since only one cluster per config file with name at row 1 (0 for array)
		
	Wr-E
	
}

Function Unload-ClusterCfg {

	$clusterCfg[$fileNumber,0] = $clusterCfg[$fileNumber,1] = $clusterCfg[$fileNumber,2] = $null

	If($CompareA.CLUSTERFILE -eq $fileNumber){$CompareA.CLUSTER = $null} 
	If($CompareB.CLUSTERFILE -eq $fileNumber){$CompareB.CLUSTER = $null}
	
	# Reset $CompareA/B.NODE/SVM if they were taken from the config file number which we've now reloaded
	# . or if there was previously only 1 config file loaded, and CompareA/B NODE/SVM pairs got autoselected!	
	If(($CompareA.NODEFILE -eq $fileNumber) -or ($cfgFiles -eq 1)){$CompareA.NODE = $null} 
	If(($CompareB.NODEFILE -eq $fileNumber) -or ($cfgFiles -eq 1)){$CompareB.NODE = $null}
	If(($CompareA.SVMFILE -eq $fileNumber ) -or ($cfgFiles -eq 1)){$CompareA.SVM = $null}
	If(($CompareB.SVMFILE -eq $fileNumber ) -or ($cfgFiles -eq 1)){$CompareB.SVM = $null}

}


################################################################################
## 8) COMPARE-DATA           Set of Functions                                 ##
################################################################################

Function Select-PairToCompare{

	Param([string]$EntityType)

	# $itemsMenu is an array with X x 3, the 3 are the columns - ENTITY, cluster, clustercfg file number	
	If ($EntityType -eq "NODE"){ $itemsMenu = New-Object 'object[,]' $cfgNodeCount,3 ; $rowInCfgFile = 1} # Menu of NODEs / row (-1) in cfg file with list of NODEs
	If ($EntityType -eq "SVM") { $itemsMenu = New-Object 'object[,]' $cfgSVMCount,3  ; $rowInCfgFile = 3} # Menu of SVMs  / row (-1) in cfg file with list of SVMs

	$x = 0                                                         # The ITEM number in the complete list of ITEMs
	0,1 | foreach { # -------------------------------------------- # There's only 2 config files - 0 & 1
		If($global:CfgContent[$_]){                                # .Checking there is some content!
			$items     = $CfgContent[$_][$rowInCfgFile].split(",") # .. we get clustercfg row with the NODE/SVMS in and split it
			$itemCount = $items.count -1                           # .. count is one less than the split (because of trailing ",")
			$j = 0                                                 # .. The ITEM in the list of ITEMs for that config file
			while ($j -lt $itemCount){                             # .. LOOP items in the clustercfg file
				$itemsMenu[$x,0] = $items[$j]                      # ... item $j (NODE/SVM) from the clustercfg file (COLUMN 2 in table below) ENTITY
				$itemsMenu[$x,1] = $CfgContent[$_][0]              # ... get CLUSTER from line 0 of clustercfg file  (COLUMN 3 in table below) CLUSTER
				$itemsMenu[$x,2] = $_                              # ... clustercfg file number                      (COLUMN 4 in table below) CLUSTERCFGFILE
				$x++ ; $j++ } } } # ------------------------------ # ... accumulate total number of ITEMs / accumulate item in the current clustercfg

	Columnize-W "Menu Option" 20 "$EntityType Name" 20 "Cluster Name"       20 "Config File Number" 20
	Columnize-C "0"           20 Yellow    "<Return to Main Menu>" 25 Cyan
	$r = 0                                # r for rows (must use $r because Columnize uses $i)
	$menuOptions  = @()                   # Define Menu Options Array
	$menuOptions += "0"                   # Add option 0
	while ($r -lt $x){ # ---------------- # START: WHILE: r < x (total number of ITEMs in the loaded config files from above)
		$option       = ($r+1).ToString() # Put option in string form (COLUMN 1 in table below)
		$menuOptions += $option           # Accumulate Menu Options Array
		Columnize-C $option 20 Yellow ($itemsMenu[$r,0]) 20 Green ($itemsMenu[$r,1]) 20 Cyan ($itemsMenu[$r,2].ToString()) 20 Cyan
		$r++                              # Accumulate r (ITEM in ITEMs Menu)
	}; Wr-E # --------------------------- # FINIT: WHILE
	
	$answer0 = Prompt-Menu "Enter 1st item (to be compared with)    ?" $menuOptions; If($answer0 -eq "0"){ Wr-E; return}; $option0 = ([int]$answer0) -1
	$answer1 = Prompt-Menu "Enter 2nd item (to compare with the 1st)?" $menuOptions; If($answer1 -eq "0"){ Wr-E; return}; $option1 = ([int]$answer1) -1; Wr-E
	
	$CompareA.$EntityType            = $itemsMenu[$option0,0]; $CompareB.$EntityType            = $itemsMenu[$option1,0] # Sets comparison A/B object for Entity (NODE/SVM)
	$CompareA.($EntityType + "FILE") = $itemsMenu[$option0,2]; $CompareB.($EntityType + "FILE") = $itemsMenu[$option1,2] # Sets comparison A/B filenumber (0/1) for Entity (NODE/SVM)
	
}

Function Compare-Data{
	
	Param($EntityType,$check) # $EntityType = CLUSTER\NODE\SVM, and $configChecks the list of $GetNc?(s)
	Wn-W ">>>>>>> Compare $EntityType"; Wr-W "s"; Wr-E # Heading
		
	## >> Search through the cluster cfg files << ##
	
	# Initialize arrays (for comparing two objects) with source cfgfile number, row count in CfgContent, size of cfgfile, and output
	$cfgFile = New-Object 'object[]' 2; $rowCount = New-Object 'object[]' 2; $rowsInFile = New-Object 'object[]' 2; $output = New-Object 'object[]' 2
	$cfgFile[0]        = $CompareA.($EntityType + "FILE") # CFG file number 0 comes from svmsMenu and the chosen option1
	$cfgFile[1]        = $CompareB.($EntityType + "FILE") # CFG file number 1 comes from svmsMenu and the chosen option2
	$rowCount[0]       = $rowCount[1] = 5        # Start on 6th row (5 in array) of CfgContent
	$rowsInFile[0]     = ($global:CfgContent[ $cfgFile[0] ]).count # Records size of file
	$rowsInFile[1]     = ($global:CfgContent[ $cfgFile[1] ]).count # Records size of file
	$entityName1       = $CompareA.$EntityType
	$entityName2       = $CompareB.$EntityType
	$searchString      = New-Object 'object[,]' 2,2
	$searchString[0,0] = "#START#$EntityType#" + $entityName1 + "#" + $check
	$searchString[0,1] = "#FINIR#$EntityType#" + $entityName1 + "#" + $check
	$searchString[1,0] = "#START#$EntityType#" + $entityName2 + "#" + $check
	$searchString[1,1] = "#FINIR#$EntityType#" + $entityName2 + "#" + $check

	"0","1" | foreach { # ---- # START: Cycle through the two config files, 0 and 1 (may be the same clustercfg file)
		$checking   = $true    # Initialize $checking TRUE
		$recording  = $null    # Initialize $recording NULL
		$output[$_] = @()      # Initialize $output as a blank array
		while ($checking) {    # START: Checking for $searchString ------------------------------------------------------------ #
			If( $CfgContent[ $cfgFile[$_] ][ $rowCount[$_] ] -eq $searchString[$_,0]){ $recording = $true; $rowCount[$_]++ }    # If it finds the start searchString, start recording from the next row
			If( $CfgContent[ $cfgFile[$_] ][ $rowCount[$_] ] -eq $searchString[$_,1]){ $recording = $null; $checking  = $null } # If finds the end searchString, stop recording and stop checking
			If( $recording ) { $output[$_] += $CfgContent[ $cfgFile[$_] ][ $rowCount[$_] ] }                                    # If recording then add the row to output
			$rowCount[$_]++				                                                                                        # Accumulate row count by 1
			If ($rowCount[$_] -ge $rowsInFile[$_]){ $checking = $null; $rowCount[$_] = 5 } # Don't let rowCount go beyond the file size, and reset counter back to the start
		}                      # FINIR: while ($checking) -------------------------------- #
	} # ---------------------- # FINIR: foreach
	
	## >> Output the comparison << ##
	
	Wn-W ">>>>> $EntityType Configuration Compare: "; Wr-C $check; Wr-E
	$x1 = 30; $x2 = 25; $x3 = 25; $x4 = 30 # Define column widths for output
	Columnize-W "PROPERTY" $x1 "$entityName1" $x2 "$entityName2" $x3 "PROPERTY" $x4
	
	$count0 = $output[0].count; $count1 = $output[1].count               # Get the size of the outputs
	$maxCount = $count0; If ($count1 -gt $count0){ $maxCount = $count1 } # Max Count = $count0, unless $count1 is greater!
	
	$r = 0               # Initialize $r for (R)ow count as 0
	$haveContent = $true # The loop below runs whilst we have content to display
	
	while ($haveContent){
	
		# This section generates for display $property0 and $entity0item ------------- #
		If     ($r -ge $count0)              { $property0 = "";  $entity0item  = ""  } # If $r (row) >= count of rows in $output[0]
		elseif ($output[0][$r].trim() -eq ""){ $property0 = " "; $entity0item  = " " } # Handles config file having blank output (separator) (Generated with Display-All)
		else {                                                                         # ------------------------ #
			$splitString0 = $output[0][$r].split("=")                                                             # Split output row on "="
			$property0    = $splitString0[0]                                                                      # $property0 is the bit before the first/only "="
			If     ($splitString0.count -eq 1){ $entity0item = " "}                                               # Handles if theres no = in the output
			elseif ($splitString0.count -eq 3){ $entity0item = $splitString0[1].trim() + "=" + $splitString0[2] } # Handles if there's a 2nd = in the output, concatentate [1]=[2]
			else                              { $entity0item = $splitString0[1].trim() }  }                       # $entity0item is the bit after the first/only "="

		# This section generates for display $property1 and $entity1item ------------- #
		If     ($r -ge $count1)              { $property1 = "";  $entity1item  = ""  } # If $r (row) >= count of rows in $output[1]
		elseif ($output[1][$r].trim() -eq ""){ $property1 = " "; $entity1item  = " " } # Handles config file having blank output (separator) (Generated with Display-All)
		else {                                                                         # ------------------------ #
			$splitString1 = $output[1][$r].split("=")                                                             # Split output row on "="
			$property1    = $splitString1[0]                                                                      # $property0 is the bit before the first/only "="
			If     ($splitString1.count -eq 1){ $entity1item = " "}                                               # Handles if theres no = in the output
			elseif ($splitString1.count -eq 3){ $entity1item = $splitString1[1].trim() + "=" + $splitString1[2] } # Handles if there's a 2nd = in the output, concatentate [1]=[2]
			else                              { $entity1item = $splitString1[1].trim() }  }                       # $entity0item is the bit after the first/only "="

		# If the properties are the same, we check for attribute matching, and display green (matched), yellow (unmatched)
		# ... otherwise we cannot, so display attributes as yellow (unmatched)
		If (($property0 -eq " ") -and ($property1 -eq " ")) { Columnize-W "PROPERTY" $x1       $entityName1 $x2        $entityName2 $x3        "PROPERTY" $x4       } # No         properties
		elseif ($property0 -eq " ") {                         Columnize-C "PROPERTY" $x1 White $entityName1 $x2 White  $entity1item $x3 Yellow $property1 $x4 Cyan  } # No "left"  property
		elseif ($property1 -eq " ") {                         Columnize-C $property0 $x1 Cyan  $entity0item $x2 Yellow $entityName2 $x3 White  "PROPERTY" $x4 White } # No "right" property
		elseif ($property0 -eq $property1) {                                                                                                                          # Properties match
			If ($entity0item -eq $entity1item) {              Columnize-C $property0 $x1 Cyan  $entity0item $x2 Green  $entity1item $x3 Green  $property1 $x4 Cyan  } # Entities   match
			else {                                            Columnize-C $property0 $x1 Cyan  $entity0item $x2 Yellow $entity1item $x3 Yellow $property1 $x4 Cyan  } # Entities   don't match
		} else {                                              Columnize-C $property0 $x1 Cyan  $entity0item $x2 Yellow $entity1item $x3 Yellow $property1 $x4 Cyan  } # Properties don't match
		
		$r ++ # accumulate the row count
		If (($count0 -le $r) -and ($count1 -le $r)){$haveContent = $null} # If $r (rows) has gone beyond the rows in $output[0] and [1], have content = NULL
		
	}; Wr-E # FINIR: while ($haveContent)

} # FINIR: Function Compare-Data

Function Compare-DataChooseGetNc{

	Param($entity,$list)
	
	Wr-W "Type a COMPLETE command from the following list, or type:"; Wr-E
	Wr-W "    ALL to cycle through the complete list"
	Wr-W "    EXIT to return"; Wr-E
	
	$list        = $list | sort ; $listCount    = $list.count
	$menuChoices = @()          ; $menuChoices += "ALL","EXIT"; $l = 0	
	while ($l -lt $listCount){
		# Note 1: substring(6) gets rid of the "Get-Nc". Note 2: split(" ") is for NODE Get-NC*'s which have a " -SWITCHNAME"
		If( ($l+0) -lt $listCount){ $col0 = ($list[$l].substring(6).split(" "))[0];   $menuChoices += $col0 } else { $col0 = " " }
		If( ($l+1) -lt $listCount){ $col1 = ($list[$l+1].substring(6).split(" "))[0]; $menuChoices += $col1 } else { $col1 = " " }
		If( ($l+2) -lt $listCount){ $col2 = ($list[$l+2].substring(6).split(" "))[0]; $menuChoices += $col2 } else { $col2 = " " }
		Columnize-C $col0 35 Cyan $col1 35 Cyan $col2 35 Cyan
		$l+=3 }; Wr-E
	
	$answer = Prompt-Menu "Type a Get-Nc* command" $menuChoices; Wr-E
	If($answer -eq "EXIT") { return }
	If($answer -eq "ALL"){
		Foreach ($GetNcCompare in $list){
			Compare-Data $entity $GetNcCompare
			Wr-G ">>>> Press ANY key to continue or X to E(X)IT"; Wr-E
			$key = Prompt-Keys -AnyKey; If($key -eq "X"){ return } }
		return }

	$GetNcCompare = "Get-Nc" + $answer
	
	If($entity -eq "NODE"){
		# NODE Get-NC*'s need their " -SWITCHNAME" re-added
		$i = 0
		while ($i -lt $listCount){
			If ($list[$i] -match $GetNcCompare){ $GetNcCompare = $list[$i]; $i = $listCount }
			$i++ } } 

	Compare-Data $entity $GetNcCompare
	
}

################################################################################
## 0) MAIN PROGRAM                                                            ##
################################################################################

If($PSIse){Wr-E; Wr-R "This program cannot run in PowerShell ISE. ISE does not support ReadKey!"; Wr-E; EXIT}     # Check not running in PowerShell ISE
$toolkit = Check-PSTK; If($toolkit){$versionChk = Check-PSTKversion $TKmajor $TKminor} else {$versionChk = $null} # Check for DOT PSTK and Version
[Void](Create-Folder $defaultClusterCfgFolder); $clusterCfgFolder = $defaultClusterCfgFolder                      # Check for default CLUSTERCFG folder

Set-Window White Black $title 80            # Set White text, Black background, Window Title, @ 80% max window size
Wr-E;Wr-M "<<<<<<<<< $title >>>>>>>>>";Wr-E # Display TITLE
If($toolkit -and !$versionChk){Wr-Y "Recommend DataONTAP PowerShell Toolkit version $TKmajor.$TKminor or better - older version detected!"};Wr-E
$lastPressed = $null # We record the last pressed key (since sometimes the output's big and I forget what I last pressed, and don't want to scroll back)

while ($true) { ## >> MENU SYSTEM << ##

	Wr-M "<<<<<<<<< MAIN MENU >>>>>>>>>"; Wr-E
	
	# Checking currently-connected-to-cluster
	$cCluster = Current-Cluster; $cClusterIP = Current-ClusterIP; $cUsername = Current-Username
	If($cCluster) { Current-VserverNull } # Make sure no Vserver is selected!
	
	# Checking loaded clustercfg files & CompareA/B HashTables
	If ($clusterCfg[0,0] -and $clusterCfg[1,0]){$cfgFiles = 2} elseif ($clusterCfg[0,0] -or  $clusterCfg[1,0]){$cfgFiles = 1} else {$cfgFiles = 0}
	$cfgNodeCount = [int]$clusterCfg[0,1] + [int]$clusterCfg[1,1]; If(!$cfgNodeCount){$cfgNodeCount = 0} # Count Nodes
	$cfgSVMCount  = [int]$clusterCfg[0,2] + [int]$clusterCfg[1,2]; If(!$cfgSVMCount) {$cfgSVMCount = 0}  # Count SVMs

	If($cfgNodeCount -eq 2){ # We have a pair of nodes, so to override needing to select two from two
		If ($cfgFiles -eq 2){ # Two files so take one node from each file
			$CompareA.NODE = ( ($CfgContent[0][1]).Split(",") )[0]; $CompareA.NODEFILE = 0
			$CompareB.NODE = ( ($CfgContent[1][1]).Split(",") )[0]; $CompareB.NODEFILE = 1
		} else { # We must have 1 $cfgFile, but which?
			If ($clusterCfg[0,0]){
				$CompareA.NODE = ( ($CfgContent[0][1]).Split(",") )[0]; $CompareA.NODEFILE = 0
				$CompareB.NODE = ( ($CfgContent[0][1]).Split(",") )[1]; $CompareB.NODEFILE = 0 }		
			If ($clusterCfg[1,0]){
				$CompareA.NODE = ( ($CfgContent[1][1]).Split(",") )[0]; $CompareA.NODEFILE = 1
				$CompareB.NODE = ( ($CfgContent[1][1]).Split(",") )[1]; $CompareB.NODEFILE = 1 } } }

	If($cfgSVMCount -eq 2){ # We have a pair of SVMs, so to override needing to select two from two
		If ($cfgFiles -eq 2){ # Two files so take one SVM from each file
			$CompareA.SVM = ( ($CfgContent[0][3]).Split(",") )[0]; $CompareA.SVMFILE = 0
			$CompareB.SVM = ( ($CfgContent[1][3]).Split(",") )[0]; $CompareB.SVMFILE = 1
		} else { # We must have 1 $cfgFile, but which?
			If ($clusterCfg[0,0]){
				$CompareA.SVM = ( ($CfgContent[0][3]).Split(",") )[0]; $CompareA.SVMFILE = 0
				$CompareB.SVM = ( ($CfgContent[0][3]).Split(",") )[1]; $CompareB.SVMFILE = 0 }		
			If ($clusterCfg[1,0]){
				$CompareA.SVM = ( ($CfgContent[1][3]).Split(",") )[0]; $CompareA.SVMFILE = 1
				$CompareB.SVM = ( ($CfgContent[1][3]).Split(",") )[1]; $CompareB.SVMFILE = 1 } } }

	$clusterA = $CompareA.CLUSTER; $clusterB = $CompareB.CLUSTER; If($clusterA  -and $clusterB){$clusterPair  = $true} else {$clusterPair  = $null}   
	$nodeA    = $CompareA.NODE;    $nodeB    = $CompareB.NODE;    If($nodeA     -and $nodeB)   {$nodePair     = $true} else {$nodePair     = $null}
	$svmA     = $CompareA.SVM;     $svmB     = $CompareB.SVM;     If($svmA      -and $svmB)    {$svmPair      = $true} else {$svmPair      = $null}
				
	# Display menu options	
	$PROMPTKEYS = "X","3","A","B" # Always available options
	$P = "    < 1 > Connect to Cluster - PS toolkit not loaded!"; If(!$toolkit){Wr-D}
	$P = "    < 1 > Connect to Cluster - "; If($toolkit -and !$cCluster){Wn-W;Wr-Y "no current connection!";$PROMPTKEYS += "1"}
	$P = "    < 1 > Connect to Cluster -";  If($toolkit -and  $cCluster){Wn-W "$P current = ";Wn-C $cCluster;Wn-W " (IP ";Wn-C $cClusterIP;Wn-W ", user ";Wn-C $cUsername;Wr-W ")";$PROMPTKEYS += "1"}
	$P = "    < 2 > Health Check Cluster";  If($cCluster) {Wr-W;$PROMPTKEYS += "2"} else {Wr-D}; Wr-E
	Wn-W "    < 3 > Change Folder for saved clustercfg files - current = "; Wr-C $clusterCfgFolder
	$P = "    < 4 > Save Current Cluster's Configuration"; If($cCluster)        {Wr-W;$PROMPTKEYS += "4"} else {Wr-D}
	$P = "    < A > Load clustercfg File A -";             If($clusterCfg[0,0]) {Wn-W "$P loaded = "; Wr-C $clusterCfg[0,0]} else {Wr-W "$P nothing loaded!"}
	$P = "    < B > Load clustercfg File B -";             If($clusterCfg[1,0]) {Wn-W "$P loaded = "; Wr-C $clusterCfg[1,0]} else {Wr-W "$P nothing loaded!"}
	$P = "    Loaded  clustercfg files contain: ";    If($cfgFiles -ne 0)    {Wr-E; Wn-W; Wr-C "$cfgFiles CLUSTER(s), $cfgNodeCount NODE(s), and $cfgSVMCount Data SVM(s)"}; Wr-E
	$P = "    < C > Compare CLUSTER  Configurations"; If($clusterPair)       {Wn-W "$P for ";Wn-C $clusterA;Wn-W " and ";Wr-C $clusterB;$PROMPTKEYS += "C"} else {Wr-D}
	$P = "    < M > Select  NODEs to Compare";        If($cfgNodeCount -gt 2){Wr-W; $PROMPTKEYS += "M"}
	$P = "    < N > Compare NODE     Configurations"; If($nodePair)          {Wn-W "$P for ";Wn-C $nodeA;Wn-W " and ";Wr-C $nodeB;$PROMPTKEYS += "N"} else {Wr-D}
	$P = "    < R > Select  SVMs  to Compare";        If($cfgSVMCount -gt 2) {Wr-W; $PROMPTKEYS += "R"}
	$P = "    < S > Compare SVM      Configurations"; If($svmPair)           {Wn-W "$P for ";Wn-C $svmA; Wn-W " and ";Wr-C $svmB; $PROMPTKEYS += "S"} else {Wr-D}; Wr-E
	Wr-W "    < X > Exit"; Wr-E
	$P = "    <<<<< Las
