function Get-IPv4Address {
  <#
    .SYNOPSIS
      Retrieves the IPv4 address of the active network adapter that has a default gateway configured.
    .DESCRIPTION
      This function checks all network adapters for an active connection with an IPv4 default gateway. It returns the IPv4 address of the first adapter that meets these criteria. If no such adapter is found, it logs an error and returns $null.
    .OUTPUTS
      [string] The IPv4 address of the active network adapter, or $null if none is found.
    .EXAMPLE
      PS> Get-IPv4Address
  #>

  $cfg = Get-NetIPConfiguration |
  Where-Object {
    $null -ne $_.IPv4DefaultGateway -and
    'Disconnected' -ne $_.NetAdapter.Status
  }

  if ($null -eq $cfg) {
    Write-Log -Message "No active network adapter with an IPv4 default gateway was found." -Color Red
    return $null
  }

  return $cfg.IPv4Address.IPAddress
}

