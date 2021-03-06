# ==============================================================================================
# 
# Microsoft PowerShell Source File -- Created with SAPIEN Technologies PrimalScript 4.1
# 
# NAME: Check-LotusHealth.ps1
# 
# AUTHOR: Jeremy D. Pavleck , Pavleck.NET
# DATE  : 5/19/2008
# 
# COMMENT: This script queries the ports of a Lotus notes environment, verifying that the various 
#	services are up and running, such as LDAP, SameTime, SMTP, Notes, SSL, etc. Script has been 
#	cleansed of customer data, but placeholder values were left in place to show how to use it.
#	Odds are this will need customization in your environment.
# 
# ==============================================================================================

# Construct constants
Set-Variable -name SMTPPort -value 25 -option constant
Set-Variable -name WWWPort -value 80 -option constant
Set-Variable -name LDAPPort -value 389 -option constant
Set-Variable -name Port410 -value 410 -option constant
Set-Variable -name SSLPort -value 443 -option constant
Set-Variable -name NOTESPort -value 1352 -option constant 

# Create hashtables to hold failed checks, sametime specific fails, and successes
$afails = @{}
$astfails = @{}
$agood = @{}

# Instantiate array to hold server information
$aservers = @{}
# Now, to populate it
# We will monitor one or more of the following ports - SMTP (25), WWW (80), LDAP (389)
# Port 410, SSL (443), Notes (1352) or several SameTime ports. 
$aservers["SERVER01"] = @{Notes=$True;}
$aservers["SERVER02"] = @{SMTP=$True; WWW=$True; Notes=$True;}
$aservers["SERVER03"] = @{SMTP=$True; WWW=$True; Notes=$True;}
$aservers["SERVER04"] = @{WWW=$True; Notes=$True;}
$aservers["SERVER05"] = @{WWW=$True; Notes=$True;}
$aservers["SERVER06"] = @{Notes=$True;}
$aservers["SERVER07"] = @{Notes=$True;}
$aservers["SERVER08"] = @{Notes=$True;}
$aservers["SERVER09"] = @{Notes=$True;}
$aservers["SERVER10"] = @{Notes=$True;}
$aservers["SERVER11"] = @{Notes=$True;}
$aservers["SERVER12"] = @{Notes=$True;}
$aservers["SERVER13"] = @{Notes=$True;}
$aservers["SERVER14"] = @{Notes=$True;}
$aservers["SERVER15"] = @{Notes=$True;}
$aservers["SERVER16"] = @{Notes=$True;}
$aservers["SERVER17"] = @{Notes=$True;}
$aservers["SERVER18"] = @{Notes=$True;}
$aservers["SERVER19"] = @{Notes=$True;}
$aservers["SERVER20"] = @{SMTP=$True; Notes=$True;}
$aservers["SERVER21"] = @{SMTP=$True; Notes=$True;}
$aservers["SERVER22"] = @{SMTP=$True; Notes=$True;}
$aservers["SERVER23"] = @{SMTP=$True; Notes=$True;}
$aservers["SERVER24"] = @{WWW=$True; SSL=$True; Notes=$True;}
$aservers["SERVER25"] = @{Notes=$True;}
$aservers["SERVER26"] = @{WWW=$True; Notes=$True; SameTime=$True;}
# And so on and so forth

# Array of SameTime ports - if SameTime is on a server, then all of these ports will be there.
# So we'll just make a seperate array holding them to make it easier
$astime = 1516, 1533, 8081, 8082, 1503, 554

# function Ping-Port is used to connect to the server on the designated port. 
# Returns $True if it connect, $False if not. 
function Ping-Port([string]$server, [int]$port)
{
$tcpClient = New-Object System.Net.Sockets.TcpClient
trap { # Generic trap object, we don't care what the error is, the check still fails.
	$False
	continue;
}
$tcpClient.Connect($server,$port)
if ($tcpClient.Connected) {$True}           
}

# Create Ping object
# This function only checks for a server response	
function Ping-Server([string]$server) 
{
$ping = New-Object System.Net.NetworkInformation.Ping
  trap { # Generic trap object, we don't care what the error is, the check still fails.
   $False
    continue;
  }
If ($ping.send($server).status -eq "Success") {$True}
$ping = $null
}

# Now, here we go
# First we will iterate through all of the servers, then iterate through each server
# If we have a particular port marked as supposed to being available, then we attempt to
# ping it, otherwise we move onto the next item.
# We also attempt to ping the server itself first - if that fails, we automagically
# mark all of the ports as failed. It is completely possible that your particular 
# environment may block pings, if so you'll need to adjust this. 
$aservers.Keys | ForEach-Object {
 If (Ping-Server $_) {
 			Write-Host "$_ responded." -ForeGroundColor Green
 			$agood[$_] += @{HOST=$True;}
 			If ($aservers[$_].notes) { # If Lotus Notes is on this machine
 				If (Ping-Port $_ $NOTESPort) { # Check it
 					Write-Host "$_: Lotus Notes Port ($NOTESPort) Responding" -ForeGroundColor Green
 					$agood[$_] += @{NOTES=$True;}
 					} else {
 					Write-Host "$_: Host is reported to have Notes ($NOTESPort) but it is not responding." -ForeGroundColor Red
 					$afails[$_] += @{NOTES=$True;} 				
 					}
 				}
 			If ($aservers[$_].smtp) { # If SMTP is here
 				If (Ping-Port $_ $SMTPPort) { # Check it
 					Write-Host "$_: SMTP ($SMTPPort) Responding" -Foregroundcolor green	
 					$agood[$_] += @{SMTP=$True;}
 					} else {
 					Write-Host "$_: Host is reported to have SMTP, but it is not responding." -Foregroundcolor red
 					$afails[$_] += @{SMTP=$True;}
 					}
 				}
 			If ($aservers[$_].www) { # If WWW is here
 				If (Ping-Port $_ $WWWPort) { #Check it
 					Write-Host "$_: WWW ($WWWPort) Responding" -foregroundcolor green
 					$agood[$_] += @{WWW=$True;}
 					} else {
 					Write-Host "$_: Host is reported to have WWW, but it is not responding." -foregroundcolor red
 					$afails[$_] += @{WWW=$True;}
 					}
 				}
 			If ($aservers[$_].ldap) { # If LDAP is here
 				If (Ping-Port $_ $LDAPPort) { # check it
 					Write-Host "$_: LDAP ($LDAPPOrt) Responding" -foregroundcolor green
 					$agood[$_] += @{LDAP=$True;}
 					} else {
 					Write-Host "$_: Host is reported to have LDAP, but it is not responding." -foregroundcolor red
 					$afails[$_] += @{LDAP=$True;}
 					}
 				}
 			If ($aservers[$_].port410) { # If port 410 is here
 				If (Ping-Port $_ $port410) { # check it
 					Write-Host "$_: Port 410 ($port410) Responding" -foregroundcolor green
 					$agood[$_] += @{Port410=$True;}
 					} else {
 					Write-Host "$_: Host is reported to have port 410, but it is not responding." -foregroundcolor red
 					$afails[$_] += @{Port410=$True;}
 					}
 				} 		
 			If ($aservers[$_].ssl) { # If SSL is here
 				If (Ping-Port $_ $SSLPort) { # check it
 					Write-Host "$_: SSL ($SSLPort) Responding" -foregroundcolor green
 					$agood[$_] += @{SSL=$True;}
 					} else {
 					Write-Host "$_: Host is reported to have SSL, but it is not responding." -foregroundcolor red
 					$afails[$_] += @{SSL=$True;}
 					}
 				}
 			If ($aservers[$_].sametime) { # If SameTime is here
 			  $st = $_
 			  $astime | ForEach-Object { 
 			  	If (Ping-Port $st $_) {
 			  		Write-Host "$st: SameTime Port $_ Success." -foregroundcolor green
 			  		} else {
 			  		Write-Host "$st: SameTime Port $_ Not Responding." -foregroundcolor red
 			  		$astfails[$st] += @{$_=$True;}
 			  		}
 			  	}
 			  }
 			} else {
 			Write-Host "Host $_ is not responding." -ForeGroundColor Red
 			$afails[$_] += @{HOST=$True;}
 			}
 }
	

If ($afails.count -gt 0) {
	Write-Host "`n`nCompleted - Errors reported - the following ping tests failed:" -ForeGroundColor Magenta
	Write-Host "`nServer `t`tFailed Ports" -Foregroundcolor Magenta
	Write-Host "----------------------------------------" -ForegroundColor Magenta
	$afails.Keys | ForEach-Object {
			Write-host "$($_): `t$($afails[$_].Keys)" -ForeGroundColor Magenta
			}
    } else {
    Write-Host "`n`nCompleted - All ports are responding." -ForegroundColor Green
}

If ($astfails.count -gt 0) {
	Write-Host "Errors reported within the SameTime environment" -Foregroundcolor Magents
	} else {
	Write-Host "SameTime Environment is fully responsive." -ForegroundColor Green 
}

