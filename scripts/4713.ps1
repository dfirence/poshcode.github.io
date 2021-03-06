###########################################################################
#
# NAME: new-WindowsHostCSR.ps1
#
# AUTHOR:  @geekjimmy
#
# COMMENT: 
#
# VERSION HISTORY:
# 
# 1.0 7/15/2013 - Initial release
# 1.1 12/18/2013 - cleaned up for public consumption
#
###########################################################################
<#
.SYNOPSIS
Creates certificate request for Windows host(s).
.DESCRIPTION
Generates an .inf template and uses that template to generate a CSR.  If an input file is specified, it will read the csv and create CSRs for all the entries in it.
The CSV will need $hostname and $domainname fields.  

Note: This script does NOT generate subject alternative names for inclusion in the CSR.

.PARAMETER hostname
hostname = host name of the server for which the CSR is being generated.  This is NOT the FQDN - just the NetBIOS name. 
.PARAMETER domainname
domainname = the domain portion of the host's FQDN.  This will be used in the subject of the cert.
.PARAMETER inputfile
inputfile = full path to csv file with hostnames
.EXAMPLE
.\New-WinHostCertRequest.ps1 -hostname mywinhost -domainname my.domain.tld
.EXAMPLE
.\New-WinHostCertRequest.ps1 -inputfile c:\temp\foo.csv
#>

param (
	[string]$hostname,
	[string]$domainname,
	[string]$inputfile
	)

if ($inputfile) { 
	$inputhosts = New-Object PSObject -Property @{
		hostname = $hostname
		domainname = $domainname
		}
	
		$inputhosts = Import-Csv $inputfile
	}

if ((!($inputfile)) -and ((!($hostname)) -and (!($domainname)))) {
	$hostname = read-host "Input hostname"
	$domainname = Read-Host "Input FQDN of host's domain name"
	}
	elseif (!($inputfile) -and ((!($hostname)) -or (!($domainname)))) {
		if (!($domainname)) {
			$domainname = Read-Host "Input FQDN of host's domain name"
			}
		elseif (!($hostname)) {
			$hostname = Read-Host "Input hostname"}
			}
			
""
""

function generate-Files {
	if (( Test-Path -path "c:\temp\$hn.$dn.certreq.inf") -eq $true) {
			$datetime = Get-Date -format yyyyddMMHHmm
			mv "c:\temp\$hn.$dn.certreq.inf" "c:\temp\$hn.$dn.certreq.$datetime.inf"
			}
		
		write-output ("[Version]  ") | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ('Signature="$Windows NT$ ' ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("[NewRequest]" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ('Subject = "CN=' + $hn + '.' + $dn + ',INSERT-REST-OF-SUBJECT-HERE"' ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("KeySpec = 1         ; Key Exchange" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("KeyUsage = 0xA0     ; Digital Signature, Key Encipherment" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("KeyLength = 2048" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("Exportable = TRUE" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("MachineKeySet = TRUE" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("SMIME = FALSE" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("PrivateKeyArchive = FALSE" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("UserProtected = FALSE" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("UseExistingKeySet = FALSE" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ('ProviderName = "Microsoft RSA Schannel Cryptographic Provider"' ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("ProviderType = 12" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("RequestType = PKCS10" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("[EnhancedKeyUsageExtension]" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("OID=1.3.6.1.5.5.7.3.1 ; this is for Server Authentication" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"
		write-output ("" ) | out-file -append c:\temp\$hn.$dn.certreq.inf -Encoding "ascii"

		if (( Test-Path -path "c:\temp\$hn.$dn.certreq.req") -eq $true) {
			$datetime = Get-Date -format yyyyddMMHHmm
			mv "c:\temp\$hn.$dn.certreq.req" "c:\temp\$hn.$dn.certreq.$datetime.req"
			}
		certreq -new c:\temp\$hn.$dn.certreq.inf c:\temp\$hn.$dn.certreq.req
		
		"REQ file created for $hn.  The file is at c:\temp\$hn.$dn.certreq.req"
		""
}
if (!($inputfile)) {
	$hn = $hostname
	$dn = $domainname
	generate-Files
	}
	Else {
		foreach ($WinHost in $inputhosts) {
			$hn = $WinHost.hostname
			$dn = $WinHost.domainname
			generate-Files
		
			}
	}
	
	
""
""

