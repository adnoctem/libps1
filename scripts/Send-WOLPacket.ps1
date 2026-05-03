#Requires -Version 5.0

<#
.SYNOPSIS
  Sends a Wake-on-LAN magic packet to wake a target machine on the local subnet.

.DESCRIPTION
  Builds a WoL magic packet (6 bytes of 0xFF followed by the target MAC address
  repeated 16 times) and broadcasts it via UDP on both ports 7 and 9 — the two
  most common ports NICs listen on.  Use -DryRun to preview without sending.

.PARAMETER Mac
  The target machine's MAC address.  Accepted formats:
    '1A:2B:3C:4D:5E:6F'  (colon-separated)
    '1A-2B-3C-4D-5E-6F'  (dash-separated)
    '1A2B3C4D5E6F'        (no separator)
  Casing is ignored.

.PARAMETER DryRun
  Preview the operation without sending any packets.

.EXAMPLE
  PS> ./Send-WOLPacket.ps1 -Mac '1A:2B:3C:4D:5E:6F'
  Sends magic packets on UDP ports 7 and 9 to wake the target machine.

.EXAMPLE
  PS> ./Send-WOLPacket.ps1 -Mac '1a-2b-3c-4d-5e-6f' -DryRun
  Previews the packets that would be sent without broadcasting anything.

.LINK
  https://github.com/adnoctem/libps1

.NOTES
  Author: Maximilian Gindorfer <info@mvprowess.com>
  License: MIT
#>

[CmdletBinding(SupportsShouldProcess = $true)]
# Parameters
param (
  [Parameter(
    Position = 0,
    Mandatory = $true,
    HelpMessage = "Target MAC address — accepted formats: '1A:2B:3C:4D:5E:6F', '1A-2B-3C-4D-5E-6F', or '1A2B3C4D5E6F'."
  )]
  [ValidatePattern('^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$|^[0-9A-Fa-f]{12}$')]
  [string]
  $Mac,

  [Parameter(
    Position = 1,
    Mandatory = $false,
    HelpMessage = 'Preview the operation without sending any packets.'
  )]
  [switch]
  $DryRun
)

# Bootstrap: import the libps1 module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\lib\libps1.psd1' -Resolve
Import-Module $modulePath -Force -ErrorAction Stop

# When -DryRun is active, enable WhatIf for downstream lib calls and log intent.
if ($DryRun) {
  $WhatIfPreference = $true
  Write-Log -Message "DRY RUN — no packets will be sent`n" -Color Yellow
}

# Build the magic packet: strip non-hex chars, then parse 2 chars per byte
Write-Log -Message "Building magic packet for MAC $Mac …" -Color Yellow

$normalized = $Mac -replace '[^0-9A-Fa-f]', ''
if ($normalized.Length -ne 12) {
  Write-Log -Message "Invalid MAC address after normalisation — expected 12 hex digits, got $($normalized.Length)." -Color Red
  exit 1
}

$macBytes = for ($i = 0; $i -lt 12; $i += 2) {
  [byte]"0x$($normalized.Substring($i, 2))"
}
[byte[]]$packet = (, 0xFF * 6) + ($macBytes * 16)

Write-Log -Message '  -> Magic packet assembled.' -Color Gray

# Broadcast on both commonly-used WoL ports
$ports = @(7, 9)
$anyFailures = $false

if ($DryRun) {
  Write-Log -Message "[DRY RUN] Would broadcast magic packet on UDP ports: $($ports -join ', ')" -Color Yellow
}
else {
  foreach ($port in $ports) {
    Write-Log -Message "Broadcasting magic packet on UDP port $port …" -Color Yellow

    try {
      $client = New-Object System.Net.Sockets.UdpClient
      $client.Connect([System.Net.IPAddress]::Broadcast, $port)
      $null = $client.Send($packet, $packet.Length)
      $client.Close()

      Write-Log -Message "  -> Done — packet sent on port $port." -Color Green
    }
    catch {
      Write-Log -Message "  -> FAILED on port $($port): $_" -Color Red
      $anyFailures = $true
    }
  }
}

# Summary
if ($DryRun) {
  Write-Log -Message "`nDRY RUN COMPLETE — no packets were sent" -Color Yellow
}
elseif ($anyFailures) {
  Write-Log -Message "`nMagic packet sent with errors on some ports — review the output above." -Color Yellow
}
else {
  Write-Log -Message "`nMagic packet sent on all ports — target should wake shortly." -Color Green
}
