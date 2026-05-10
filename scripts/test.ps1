<#
.SYNOPSIS
  TBA..
.DESCRIPTION
  Uses Outlook's COM interface to find items by ReceivedTime and relocate them
  to the specified archive folder. Designed for batch clean-up and retention
  workflows where a fixed date range needs to be archived.
.EXAMPLE
  PS> ./archive-outlook.ps1 -StartDate '2024-01-01' -EndDate '2024-03-31' -ArchiveFolder 'Archive/2024 Q1'
.LINK
  https://github.com/adnoctem/libps1
.NOTES
  Author: Maximilian Gindorfer <info@mvprowess.com>
  License: MIT
#>

# ---- Module import ------------------------------------
$root = Split-Path $PSScriptRoot -Parent
$module = Join-Path -Path $root 'lib/libps1.psm1'

Import-Module $module -Force
# -------------------------------------------------------

# Write-Log -Message "This is a test!" -Color Cyan -Timestamps

# Write-Log "This is some bs" -Color Cyan -Timestamps
# Write-Log "`$root would have been: $root"
# Write-Log "`$module would have been: $module"
# Write-Log "Now we're using $PSScriptRoot\..\lib\libps1.psd1"

# ConvertFrom-HTMLtoWord -FileHTML "C:\Users\Admin\tmp\Pressemitteilung\test.html" -OutputFile "C:\Users\Admin\tmp\Pressemitteilung\test.docx" -Show | Out-Null
# Convert-HTMLToPDF -FilePath '/tmp/test.html' -OutputFilePath '/tmp/test-out.pdf'

# ---------- MAC testing for Send-WOLPacket.ps1 ----------

# $MAC = "6c:4b:90:24:c7:75"
# $normalized = $MAC -replace '[^0-9A-Fa-f]', ''
# Write-Log -Message "Normalized MAC: $normalized" -Color Green
# Write-Log -Message "Normalized MAC length: $( $normalized.Length )" -Color Green

# $MACList = $normalized -split '(..)' | Where-Object { $_ -ne '' }
# Write-Log -Message "MAC List: $MACList" -Color Green

# $MACBytes = $MACList | ForEach-Object { [byte]("0x$_") }
# Write-Log -Message "MAC Bytes: $MACBytes" -Color Green

# $MagicPacket = @([byte]0xFF) * 6 + ($MACBytes * 16) 
# Write-Log -Message "Magic Packet: $($MagicPacket -join ' ')" -Color Green


# $newBytes = $normalized -split '(..)' | Where-Object { $_ -ne '' } | ForEach-Object { [byte]("0x$_") }
# Write-Log -Message "New Normalized MAC List: $newBytes" -Color Green

# ---------- IP testing for Send-WOLPacket.ps1 ----------

# Get-IPv4Address
# Get-IPv4SubnetMask
# Get-IPv4Network
# Get-IPv4NetworkCIDR
# Get-IPv4BroadcastAddress

Get-IPv4Address
Get-IPv6Address
Get-IPv4SubnetMask
Get-IPv4DefaultGateway
Get-IPv4DNSServer
Get-MACAddress
Get-IPv4Network
Get-IPv6Prefix
Get-IPv4NetworkCIDR
Get-IPv6PrefixCIDR
Get-IPv4BroadcastAddress
Get-IPv6MulticastAddress
# Test-IPv4Address
# Test-IPv6Address
# Confirm-IPv4Address
# Confirm-IPv6Address