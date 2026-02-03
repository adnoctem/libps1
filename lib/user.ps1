function Get-UserInfo {
  param ()

  $user = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $isAdmin = (New-Object System.Security.Principal.WindowsPrincipal($user)).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

  return @{
    UserName        = $user.Name
    IsAdministrator = $isAdmin
    SID             = $user.User.Value
  }
}

function Get-UserSID {
  param (
    [Parameter(Mandatory = $true)]
    [string]$UserName
  )

  try {
    $user = New-Object System.Security.Principal.NTAccount($UserName)
    $sid = $user.Translate([System.Security.Principal.SecurityIdentifier])
    return $sid.Value
  } catch {
    Write-Error "Could not find SID for user '$UserName'. $_"
    return $null
  }
}