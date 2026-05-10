$script:knownLocalAdapters = @('VMware', 'Npcap', 'VirtualBox', 'Hyper-V', 'Loopback', 'WSL')

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

  $ip = Get-CimInstance -Class Win32_NetworkAdapterConfiguration |
  Where-Object {
    $_.IPEnabled -and
    $null -ne $_.DefaultIPGateway -and
    ($script:knownLocalAdapters -notcontains $_.Description)
  } |
  Select-Object -ExpandProperty IPAddress -First 1 |
  Where-Object { $_ -notmatch ':' } |
  Select-Object -First 1

  if ($null -eq $ip) {
    Write-Log -Message "No active network adapter with an IPv4 default gateway was found." -Color Red
    return $null
  }

  return $ip
}

function Get-IPv6Address {
  <#
    .SYNOPSIS
      Retrieves the IPv6 address of the active network adapter that has a default gateway configured.
    .DESCRIPTION
      This function checks all network adapters for an active connection with an IPv6 default gateway. It returns the IPv6 address of the first adapter that meets these criteria. If no such adapter is found, it logs an error and returns $null.
    .OUTPUTS
      [string] The IPv6 address of the active network adapter, or $null if none is found.
    .EXAMPLE
      PS> Get-IPv6Address
  #>

  $ip = Get-CimInstance -Class Win32_NetworkAdapterConfiguration |
  Where-Object {
    $_.IPEnabled -and
    $null -ne $_.DefaultIPGateway -and
    ($script:knownLocalAdapters -notcontains $_.Description)
  } |
  Select-Object -ExpandProperty IPAddress -First 1 |
  Where-Object { $_ -match ':' } |
  Select-Object -First 1

  if ($null -eq $ip) {
    Write-Log -Message "No active network adapter with an IPv6 default gateway was found." -Color Red
    return $null
  }

  return $ip
}

function Get-IPv4SubnetMask {
  <#
    .SYNOPSIS
      Retrieves the IPv4 subnet mask of the active network adapter that has a default gateway configured.
    .DESCRIPTION
      This function checks all network adapters for an active connection with an IPv4 default gateway. It returns the IPv4 subnet mask of the first adapter that meets these criteria. If no such adapter is found, it logs an error and returns $null.
    .OUTPUTS
      [string] The IPv4 subnet mask of the active network adapter, or $null if none is found.
    .EXAMPLE
      PS> Get-IPv4SubnetMask
  #>

  $subnet = Get-CimInstance -Class Win32_NetworkAdapterConfiguration |
  Where-Object {
    $_.IPEnabled -and
    $null -ne $_.DefaultIPGateway -and
    ($script:knownLocalAdapters -notcontains $_.Description)
  } |
  Select-Object -ExpandProperty IPSubnet -First 1 |
  Where-Object { $_ -notmatch ':' } |
  Select-Object -First 1

  if ($null -eq $subnet) {
    Write-Log -Message "No active network adapter with an IPv4 default gateway was found." -Color Red
    return $null
  }

  return $subnet
}

function Get-IPv4DefaultGateway {
  <#
    .SYNOPSIS
      Retrieves the IPv4 default gateway of the active network adapter that has a default gateway configured.
    .DESCRIPTION
      This function checks all network adapters for an active connection with an IPv4 default gateway. It returns the IPv4 default gateway of the first adapter that meets these criteria. If no such adapter is found, it logs an error and returns $null.
    .OUTPUTS
      [string] The IPv4 default gateway of the active network adapter, or $null if none is found.
    .EXAMPLE
      PS> Get-IPv4DefaultGateway
  #>

  $gateway = Get-CimInstance -Class Win32_NetworkAdapterConfiguration |
  Where-Object {
    $_.IPEnabled -and
    $null -ne $_.DefaultIPGateway -and
    ($script:knownLocalAdapters -notcontains $_.Description)
  } |
  Select-Object -ExpandProperty DefaultIPGateway -First 1 |
  Where-Object { $_ -notmatch ':' } |
  Select-Object -First 1

  if ($null -eq $gateway) {
    Write-Log -Message "No active network adapter with an IPv4 default gateway was found." -Color Red
    return $null
  }

  return $gateway
}

function Get-IPv4DNSServer {
  <#
    .SYNOPSIS
      Retrieves the IPv4 DNS servers of the active network adapter that has a default gateway configured.
    .DESCRIPTION
      This function checks all network adapters for an active connection with an IPv4 default gateway. It returns the IPv4 DNS servers of the first adapter that meets these criteria. If no such adapter is found, it logs an error and returns $null.
    .OUTPUTS
      [string[]] The IPv4 DNS servers of the active network adapter, or $null if none is found.
    .EXAMPLE
      PS> Get-IPv4DNSServers
  #>

  $dnsServers = Get-CimInstance -Class Win32_NetworkAdapterConfiguration |
  Where-Object {
    $_.IPEnabled -and
    $null -ne $_.DefaultIPGateway -and
    ($script:knownLocalAdapters -notcontains $_.Description)
  } |
  Select-Object -ExpandProperty DNSServerSearchOrder -First 1 |
  Where-Object { $_ -notmatch ':' }

  if ($null -eq $dnsServers) {
    Write-Log -Message "No active network adapter with an IPv4 default gateway was found." -Color Red
    return $null
  }

  return $dnsServers
}

function Get-MACAddress {
  <#
    .SYNOPSIS
      Retrieves the MAC address of the active network adapter that has a default gateway configured.
    .DESCRIPTION
      This function checks all network adapters for an active connection with a default gateway. It returns the MAC address of the first adapter that meets these criteria. If no such adapter is found, it logs an error and returns $null.
    .OUTPUTS
      [string] The MAC address of the active network adapter, or $null if none is found.
    .EXAMPLE
      PS> Get-MACAddress
  #>

  $mac = Get-CimInstance -Class Win32_NetworkAdapterConfiguration |
  Where-Object {
    $_.IPEnabled -and
    $null -ne $_.DefaultIPGateway -and
    ($script:knownLocalAdapters -notcontains $_.Description)
  } | Select-Object -ExpandProperty MACAddress -First 1

  if ($null -eq $mac) {
    Write-Log -Message "No active network adapter with a default gateway was found." -Color Red
    return $null
  }

  return $mac
}

function Get-IPv4Network {
  <#
    .SYNOPSIS
      Retrieves the IPv4 network address of the active network adapter that has a default gateway configured.
    .DESCRIPTION
      This function checks all network adapters for an active connection with an IPv4 default gateway. It calculates and returns the IPv4 network address of the first adapter that meets these criteria. If no such adapter is found, it logs an error and returns $null.
    .OUTPUTS
      [string] The IPv4 network address of the active network adapter, or $null if none is found.
    .EXAMPLE
      PS> Get-IPv4Network
  #>

  $ip = Get-IPv4Address
  $subnet = Get-IPv4SubnetMask

  if ($null -eq $ip -or $null -eq $subnet) {
    Write-Log -Message "Cannot calculate network address without valid IP and subnet mask." -Color Red
    return $null
  }

  $ipBytes = [System.Net.IPAddress]::Parse($ip).GetAddressBytes()
  $subnetBytes = [System.Net.IPAddress]::Parse($subnet).GetAddressBytes()

  $networkBytes = @()
  for ($i = 0; $i -lt 4; $i++) {
    $networkBytes += ($ipBytes[$i] -band $subnetBytes[$i])
  }

  return [System.Net.IPAddress]::new($networkBytes).ToString()
}

function Get-IPv6Prefix {
  <#
    .SYNOPSIS
      Retrieves the IPv6 prefix (network) of the active network adapter that has a default gateway configured.
    .DESCRIPTION
      This function checks all network adapters for an active connection with an IPv6 default gateway. It calculates the IPv6 prefix by masking the IPv6 address with its prefix length per RFC 4291. If no such adapter is found, it logs an error and returns $null.
    .OUTPUTS
      [string] The IPv6 prefix of the active network adapter, or $null if none is found.
    .EXAMPLE
      PS> Get-IPv6Prefix
  #>

  $adapter = Get-CimInstance -Class Win32_NetworkAdapterConfiguration |
  Where-Object {
    $_.IPEnabled -and
    $null -ne $_.DefaultIPGateway -and
    ($script:knownLocalAdapters -notcontains $_.Description)
  } |
  Select-Object -First 1

  if ($null -eq $adapter) {
    Write-Log -Message "No active network adapter with a default gateway was found." -Color Red
    return $null
  }

  # IPAddress and IPSubnet are parallel arrays — find the IPv6 entry
  $ipv6Address = $null
  $prefixLength = 0

  for ($i = 0; $i -lt $adapter.IPAddress.Count; $i++) {
    if ($adapter.IPAddress[$i] -match ':') {
      $ipv6Address = $adapter.IPAddress[$i]
      $subnetEntry = $adapter.IPSubnet[$i]

      # IPSubnet may be a prefix length number (e.g., "64") or a full IPv6 mask
      if ($subnetEntry -match '^[0-9]+$') {
        $prefixLength = [int]$subnetEntry
      }
      else {
        # Full mask — count leading 1-bits to derive the prefix length
        $maskBytes = [System.Net.IPAddress]::Parse($subnetEntry).GetAddressBytes()
        foreach ($byte in $maskBytes) {
          if ($byte -eq 0xFF) { $prefixLength += 8; continue }
          for ($bit = 7; $bit -ge 0; $bit--) {
            if (($byte -shr $bit) -band 1) { $prefixLength++ } else { break }
          }
          break
        }
      }
      break
    }
  }

  if ($null -eq $ipv6Address -or $prefixLength -eq 0) {
    Write-Log -Message "No IPv6 address with a valid prefix length was found." -Color Red
    return $null
  }

  # Build the prefix by masking the address with the prefix length
  $ipBytes = [System.Net.IPAddress]::Parse($ipv6Address).GetAddressBytes()
  $prefixBytes = [byte[]]::new(16)
  $bitsRemaining = $prefixLength

  for ($i = 0; $i -lt 16; $i++) {
    if ($bitsRemaining -ge 8) {
      $prefixBytes[$i] = $ipBytes[$i]
      $bitsRemaining -= 8
    }
    elseif ($bitsRemaining -gt 0) {
      $mask = [byte](0xFF -shl (8 - $bitsRemaining))
      $prefixBytes[$i] = $ipBytes[$i] -band $mask
      $bitsRemaining = 0
    }
    else {
      $prefixBytes[$i] = 0
    }
  }

  return [System.Net.IPAddress]::new($prefixBytes).ToString()
}

function Get-IPv4NetworkCIDR {
  <#
    .SYNOPSIS
      Retrieves the IPv4 network address in CIDR notation of the active network adapter that has a default gateway configured.
    .DESCRIPTION
      This function checks all network adapters for an active connection with an IPv4 default gateway. It calculates and returns the IPv4 network address in CIDR notation of the first adapter that meets these criteria. If no such adapter is found, it logs an error and returns $null.
    .OUTPUTS
      [string] The IPv4 network address in CIDR notation of the active network adapter, or $null if none is found.
    .EXAMPLE
      PS> Get-IPv4NetworkCIDR
  #>

  $network = Get-IPv4Network
  $subnet = Get-IPv4SubnetMask

  if ($null -eq $network -or $null -eq $subnet) {
    Write-Log -Message "Cannot calculate CIDR notation without valid network address and subnet mask." -Color Red
    return $null
  }

  $subnetBytes = [System.Net.IPAddress]::Parse($subnet).GetAddressBytes()
  $cidr = 0
  foreach ($byte in $subnetBytes) {
    switch ($byte) {
      255 { $cidr += 8 }
      254 { $cidr += 7 }
      252 { $cidr += 6 }
      248 { $cidr += 5 }
      240 { $cidr += 4 }
      224 { $cidr += 3 }
      192 { $cidr += 2 }
      128 { $cidr += 1 }
    }
  }

  return "$network/$cidr"
}

function Get-IPv6PrefixCIDR {
  <#
    .SYNOPSIS
      Retrieves the IPv6 prefix in CIDR notation of the active network adapter that has a default gateway configured.
    .DESCRIPTION
      This function checks all network adapters for an active connection with an IPv6 default gateway. It calculates and returns the IPv6 prefix in CIDR notation (prefix/prefixLength) per RFC 4291. If no such adapter is found, it logs an error and returns $null.
    .OUTPUTS
      [string] The IPv6 prefix in CIDR notation of the active network adapter, or $null if none is found.
    .EXAMPLE
      PS> Get-IPv6PrefixCIDR
  #>

  $adapter = Get-CimInstance -Class Win32_NetworkAdapterConfiguration |
  Where-Object {
    $_.IPEnabled -and
    $null -ne $_.DefaultIPGateway -and
    ($script:knownLocalAdapters -notcontains $_.Description)
  } |
  Select-Object -First 1

  if ($null -eq $adapter) {
    Write-Log -Message "No active network adapter with a default gateway was found." -Color Red
    return $null
  }

  $ipv6Address = $null
  $prefixLength = 0

  for ($i = 0; $i -lt $adapter.IPAddress.Count; $i++) {
    if ($adapter.IPAddress[$i] -match ':') {
      $ipv6Address = $adapter.IPAddress[$i]
      $subnetEntry = $adapter.IPSubnet[$i]

      if ($subnetEntry -match '^[0-9]+$') {
        $prefixLength = [int]$subnetEntry
      }
      else {
        $maskBytes = [System.Net.IPAddress]::Parse($subnetEntry).GetAddressBytes()
        foreach ($byte in $maskBytes) {
          if ($byte -eq 0xFF) { $prefixLength += 8; continue }
          for ($bit = 7; $bit -ge 0; $bit--) {
            if (($byte -shr $bit) -band 1) { $prefixLength++ } else { break }
          }
          break
        }
      }
      break
    }
  }

  if ($null -eq $ipv6Address -or $prefixLength -eq 0) {
    Write-Log -Message "No IPv6 address with a valid prefix length was found." -Color Red
    return $null
  }

  $ipBytes = [System.Net.IPAddress]::Parse($ipv6Address).GetAddressBytes()
  $prefixBytes = [byte[]]::new(16)
  $bitsRemaining = $prefixLength

  for ($i = 0; $i -lt 16; $i++) {
    if ($bitsRemaining -ge 8) {
      $prefixBytes[$i] = $ipBytes[$i]
      $bitsRemaining -= 8
    }
    elseif ($bitsRemaining -gt 0) {
      $mask = [byte](0xFF -shl (8 - $bitsRemaining))
      $prefixBytes[$i] = $ipBytes[$i] -band $mask
      $bitsRemaining = 0
    }
    else {
      $prefixBytes[$i] = 0
    }
  }

  $prefix = [System.Net.IPAddress]::new($prefixBytes).ToString()
  return "$prefix/$prefixLength"
}

function Get-IPv4BroadcastAddress {
  <#
    .SYNOPSIS
      Retrieves the IPv4 broadcast address of the active network adapter that has a default gateway configured.
    .DESCRIPTION
      This function checks all network adapters for an active connection with an IPv4 default gateway. It calculates and returns the IPv4 broadcast address of the first adapter that meets these criteria. If no such adapter is found, it logs an error and returns $null.
    .OUTPUTS
      [string] The IPv4 broadcast address of the active network adapter, or $null if none is found.
    .EXAMPLE
      PS> Get-IPv4BroadcastAddress
  #>

  $ip = Get-IPv4Address
  $subnet = Get-IPv4SubnetMask

  if ($null -eq $ip -or $null -eq $subnet) {
    Write-Log -Message "Cannot calculate broadcast address without valid IP and subnet mask." -Color Red
    return $null
  }

  $ipBytes = [System.Net.IPAddress]::Parse($ip).GetAddressBytes()
  $subnetBytes = [System.Net.IPAddress]::Parse($subnet).GetAddressBytes()

  $broadcastBytes = @()
  for ($i = 0; $i -lt 4; $i++) {
    $invertedByte = -bnot $subnetBytes[$i]
    $maskedByte = $invertedByte -band 0xFF
    $broadcastBytes += $ipBytes[$i] -bor $maskedByte
  }

  return [System.Net.IPAddress]::new($broadcastBytes).ToString()
}

function Get-IPv6MulticastAddress {
  <#
    .SYNOPSIS
      Retrieves the IPv6 solicited-node multicast address of the active network adapter.
    .DESCRIPTION
      This function calculates the IPv6 solicited-node multicast address (RFC 4291 §2.7.1) for the active network adapter's IPv6 address. IPv6 has no broadcast; instead, the solicited-node multicast address is used for Neighbor Discovery (the IPv6 replacement for ARP). It is formed by taking the lower 24 bits of the unicast address and prepending the prefix ff02::1:ff00:0/104. If no IPv6 adapter is found, it logs an error and returns $null.
    .OUTPUTS
      [string] The IPv6 solicited-node multicast address, or $null if none is found.
    .EXAMPLE
      PS> Get-IPv6MulticastAddress
  #>

  $ip = Get-IPv6Address

  if ($null -eq $ip) {
    Write-Log -Message "Cannot calculate multicast address without a valid IPv6 address." -Color Red
    return $null
  }

  $ipBytes = [System.Net.IPAddress]::Parse($ip).GetAddressBytes()

  # Solicited-node multicast address per RFC 4291 §2.7.1:
  # Prefix ff02:0:0:0:0:1:ff00:0/104 + lower 24 bits of unicast address
  $multicastBytes = [byte[]]@(
    0xFF, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x01, 0xFF,
    $ipBytes[13],
    $ipBytes[14],
    $ipBytes[15]
  )

  return [System.Net.IPAddress]::new($multicastBytes).ToString()
}

function Test-IPv4Address {
  <#
    .SYNOPSIS
      Tests whether a given string is a valid IPv4 address using pattern matching.
    .DESCRIPTION
      This function uses a regular expression to check if the input string conforms to the standard dotted-decimal format of an IPv4 address. It returns $true if the input is a valid IPv4 address, and $false otherwise.
    .PARAMETER Address
      The string to test as an IPv4 address.
    .OUTPUTS
      [bool] $true if the input is a valid IPv4 address, $false otherwise.
    .EXAMPLE
      PS> Test-IPv4Address -Address '192.168.1.1'
      True
  #>
  param (
    [Parameter(Mandatory = $true)]
    [string]$Address
  )

  $pattern = '^(\d{1,3}\.){3}\d{1,3}$'
  if ($Address -match $pattern) {
    $octets = $Address -split '\.'
    foreach ($octet in $octets) {
      # Reject leading zeros (e.g., "01", "001") unless the octet is exactly "0"
      if ($octet.Length -gt 1 -and $octet[0] -eq '0') {
        return $false
      }
      $value = [int]$octet
      if ($value -lt 0 -or $value -gt 255) {
        return $false
      }
    }
    return $true
  }
  return $false
}

function Test-IPv6Address {
  <#
    .SYNOPSIS
      Tests whether a given string is a valid IPv6 address using pattern matching.
    .DESCRIPTION
      This function uses a comprehensive regular expression (RFC 3986) to check if the input string conforms to the standard colon-hexadecimal format of an IPv6 address, including zero-compression (::) and IPv4-mapped forms. It returns $true if the input is a valid IPv6 address, and $false otherwise.
    .PARAMETER Address
      The string to test as an IPv6 address.
    .OUTPUTS
      [bool] $true if the input is a valid IPv6 address, $false otherwise.
    .EXAMPLE
      PS> Test-IPv6Address -Address '2001:0db8:85a3:0000:0000:8a2e:0370:7334'
      True
    .EXAMPLE
      PS> Test-IPv6Address -Address '::1'
      True
    .EXAMPLE
      PS> Test-IPv6Address -Address '2001:db8::ff00:42:8329'
      True
  #>
  param (
    [Parameter(Mandatory = $true)]
    [string]$Address
  )

  # Comprehensive IPv6 regex per RFC 3986 / RFC 4291:
  # Handles full form, :: compression, and IPv4-mapped (::ffff:x.x.x.x)
  $pattern = '^(([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}|' +
  '([0-9A-Fa-f]{1,4}:){1,7}:|' +
  '([0-9A-Fa-f]{1,4}:){1,6}:[0-9A-Fa-f]{1,4}|' +
  '([0-9A-Fa-f]{1,4}:){1,5}(:[0-9A-Fa-f]{1,4}){1,2}|' +
  '([0-9A-Fa-f]{1,4}:){1,4}(:[0-9A-Fa-f]{1,4}){1,3}|' +
  '([0-9A-Fa-f]{1,4}:){1,3}(:[0-9A-Fa-f]{1,4}){1,4}|' +
  '([0-9A-Fa-f]{1,4}:){1,2}(:[0-9A-Fa-f]{1,4}){1,5}|' +
  '[0-9A-Fa-f]{1,4}:((:[0-9A-Fa-f]{1,4}){1,6})|' +
  ':((:[0-9A-Fa-f]{1,4}){1,7}|:)|' +
  '::(ffff(:0{1,4})?:)?((25[0-5]|(2[0-4]|1?\d)?\d)\.){3}(25[0-5]|(2[0-4]|1?\d)?\d)|' +
  '([0-9A-Fa-f]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1?\d)?\d)\.){3}(25[0-5]|(2[0-4]|1?\d)?\d))$'

  return $Address -match $pattern
} 

function Confirm-IPv4Address {
  <#
    .SYNOPSIS
      Validates whether a given string is a valid IPv4 address using mathematical proof.
    .DESCRIPTION
      This function validates an IPv4 address per RFC 791 by decomposing it into four decimal octets and verifying each is arithmetically within the valid range (0-255). Unlike Test-IPv4Address which uses pattern matching, this function relies on arithmetic constraints — integer parsing, range checking, and canonical form verification (no leading zeros) — to mathematically prove the address is a valid 32-bit IPv4 address.
    .PARAMETER Address
      The string to validate as an IPv4 address.
    .OUTPUTS
      [bool] $true if the input is a valid IPv4 address, $false otherwise.
    .EXAMPLE
      PS> Confirm-IPv4Address -Address '192.168.1.1'
      True
    .EXAMPLE
      PS> Confirm-IPv4Address -Address '256.0.0.1'
      False
    .EXAMPLE
      PS> Confirm-IPv4Address -Address '01.02.03.04'
      False
  #>
  param (
    [Parameter(Mandatory = $true)]
    [string]$Address
  )

  if ([string]::IsNullOrEmpty($Address)) {
    return $false
  }

  # Decompose into octets — must yield exactly 4 parts
  $octets = $Address -split '\.'
  if ($octets.Count -ne 4) {
    return $false
  }

  # Mathematically validate each octet
  foreach ($octet in $octets) {
    # Reject empty octets (consecutive or trailing dots)
    if ($octet.Length -eq 0) {
      return $false
    }

    # Reject leading zeros — canonical form per RFC 3986
    # "0" is valid; "01", "001", "00" are not
    if ($octet.Length -gt 1 -and $octet[0] -eq '0') {
      return $false
    }

    # Convert to integer — must be a valid non-negative number
    $value = 0
    if (-not [int]::TryParse($octet, [ref]$value)) {
      return $false
    }

    # Arithmetic range check: 0 ≤ value ≤ 255
    # This proves the octet fits in 8 bits
    if ($value -lt 0 -or $value -gt 255) {
      return $false
    }
  }

  # All octets are mathematically valid — the address is a valid 32-bit IPv4 address
  # Address value = octet0 × 2^24 + octet1 × 2^16 + octet2 × 2^8 + octet3
  return $true
}

function Confirm-IPv6Address {
  <#
    .SYNOPSIS
      Validates whether a given string is a valid IPv6 address using mathematical proof.
    .DESCRIPTION
      This function validates an IPv6 address per RFC 4291 by decomposing it into 16-bit hexadecimal groups. It arithmetically verifies: each group contains 1-4 hex digits representing a value in 0x0000-0xFFFF, zero-compression (::) appears at most once and represents one or more consecutive zero groups, and the total number of groups is exactly 8. IPv4-mapped addresses (::ffff:x.x.x.x) are delegated to Confirm-IPv4Address for the embedded IPv4 portion.
    .PARAMETER Address
      The string to validate as an IPv6 address.
    .OUTPUTS
      [bool] $true if the input is a valid IPv6 address, $false otherwise.
    .EXAMPLE
      PS> Confirm-IPv6Address -Address '2001:0db8:85a3:0000:0000:8a2e:0370:7334'
      True
    .EXAMPLE
      PS> Confirm-IPv6Address -Address '::1'
      True
    .EXAMPLE
      PS> Confirm-IPv6Address -Address '2001:db8::ff00:42:8329'
      True
    .EXAMPLE
      PS> Confirm-IPv6Address -Address '::ffff:192.168.1.1'
      True
    .EXAMPLE
      PS> Confirm-IPv6Address -Address '::1::2'
      False
  #>
  param (
    [Parameter(Mandatory = $true)]
    [string]$Address
  )

  if ([string]::IsNullOrEmpty($Address)) {
    return $false
  }

  # Handle IPv4-mapped IPv6 addresses (e.g., ::ffff:192.168.1.1)
  # If the last segment contains a dot, delegate to Confirm-IPv4Address
  $lastColon = $Address.LastIndexOf(':')
  if ($lastColon -ge 0) {
    $lastSegment = $Address.Substring($lastColon + 1)
    if ($lastSegment.Contains('.')) {
      if (-not (Confirm-IPv4Address -Address $lastSegment)) {
        return $false
      }
      # Replace IPv4 part with a placeholder hex group for group-counting
      $Address = $Address.Substring(0, $lastColon + 1) + '0'
    }
  }

  # :: must appear at most once (RFC 4291 Section 2.2)
  $doubleColonCount = 0
  $pos = 0
  while (($pos = $Address.IndexOf('::', $pos)) -ge 0) {
    $doubleColonCount++
    $pos += 2
  }
  if ($doubleColonCount -gt 1) {
    return $false
  }

  $hasCompression = $doubleColonCount -eq 1

  if ($hasCompression) {
    # Split on :: to separate left and right groups
    $parts = $Address -split '::', 2
    $leftGroups = if ($parts[0]) { $parts[0] -split ':' | Where-Object { $_ -ne '' } } else { @() }
    $rightGroups = if ($parts[1]) { $parts[1] -split ':' | Where-Object { $_ -ne '' } } else { @() }
    $explicitGroups = $leftGroups + $rightGroups

    # :: represents 1 to 8 zero groups; explicit groups must be 0-7
    # so total (explicit + at least 1 zero from ::) ≤ 8
    if ($explicitGroups.Count -gt 7) {
      return $false
    }

    $groupsToValidate = $explicitGroups
  }
  else {
    # Full form: exactly 8 colon-separated groups
    $allGroups = $Address -split ':'
    if ($allGroups.Count -ne 8) {
      return $false
    }
    $groupsToValidate = $allGroups
  }

  # Mathematical validation of each 16-bit hex group
  # Define the hex digit set for set-membership testing
  $hexDigits = [char[]]'0123456789abcdefABCDEF'

  foreach ($group in $groupsToValidate) {
    # Each group must contain 1-4 hex digits
    if ($group.Length -lt 1 -or $group.Length -gt 4) {
      return $false
    }

    # Verify every character is a valid hex digit (set membership)
    foreach ($char in $group.ToCharArray()) {
      if ($char -notin $hexDigits) {
        return $false
      }
    }

    # Arithmetic range check: 0x0000 ≤ value ≤ 0xFFFF (16-bit unsigned)
    $value = [Convert]::ToInt32($group, 16)
    if ($value -lt 0 -or $value -gt 0xFFFF) {
      return $false
    }
  }

  # All groups are mathematically valid — the address is a valid 128-bit IPv6 address
  return $true
}