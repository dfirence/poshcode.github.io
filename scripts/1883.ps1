###########################################
# Get-DLRestriction
#
# Uses QAD cmdlets to retrieve distribution list restriction attributes 
# and then provides a list of users which can send email messages to the group.
#
# Usage: Get-DLRestriction "Worldwide Everyone"
#
# Dmitry Sotnikov, http://dmitrysotnikov.wordpress.com
############################################

function Get-DLRestriction {
	param([System.String]	$DLName	)

  "Checking restrictions for $DLName"

  $DL = Get-QADGroup $DLName `
      -IncludedProperties AuthOrig, UnauthOrig, dLMemRejectPerms,`
                      dLMemSubmitPerms, msExchRequireAuthToSendTo

  # we'll set this to true if we see a restriction
  $restricted = $false

  # if the group with such a name is found
  if ( $DL -ne $null ) { 
    
    if ( $DL.AuthOrig -ne $null ) { 
      $restricted = $true
      "`n The following users can send messages to this list:"
      $DL.AuthOrig | Get-QADUser
    }
    
    if ( $DL.UnauthOrig -ne $null ) { 
      $restricted = $true
      "`n Anyone BUT the following users can send messages to this list:"
      $DL.UnauthOrig | Get-QADUser
    }
    
    if ( $DL.dLMemSubmitPerms -ne $null ) { 
      $restricted = $true
      "n` Members of this group can send messages to this list: $($DL.dLMemSubmitPerms | Get-QADGroup).Name) :"
      Get-QADGroupMember $DL.dLMemSubmitPerms
    }
    
    if ( $DL.dLMemRejectPerms -ne $null ) { 
      $restricted = $true
      "`n Anyone BUT members of this group can send messages to this list: $($DL.dLMemRejectPerms | Get-QADGroup).Name) :"
      Get-QADGroupMember $DL.dLMemRejectPerms
    }
    
    if ( $DL.msExchRequireAuthToSendTo ) { 
      $restricted = $true
      "`n Only authenticated users can send messages to this list.`nExternal senders get blocked."
    }
    
    if ( -not $restricted ) {
      "`n This list is not restricted. Anyone can email it."
    }
  } else {
    "`n DL $DLName not found."
  }
}

