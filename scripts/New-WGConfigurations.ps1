#Requires -Version 5.1

<#
.SYNOPSIS
  Generates WireGuard configuration files for local users based on a template and data exported from pfSense. 

.DESCRIPTION
  This script reads a template configuration file (wg.conf.tpl) and a pfSense export (pfsense.conf) to create individual WireGuard configuration files for each user. It matches users based on their folder names and the peer information in the pfSense export, replacing placeholders in the template with actual values such as private keys, public keys, pre-shared keys, and allowed IPs.

.PARAMETER ServerPublicKey
  The public key of the WireGuard server, which will be inserted into each generated configuration file.

.EXAMPLE
  PS> ./New-WGConfigurations.ps1 -ServerPublicKey "SERVER_PUBLIC_KEY_HERE"
  This command generates WireGuard configuration files for all users based on the provided server public key and the data from pfSense.

.EXAMPLE
  PS> ./New-WGConfigurations.ps1 -ServerPublicKey "SERVER_PUBLIC_KEY_HERE" -RootDirectory "C:\WGConfigs" -TemplatePath "custom_template.conf"
  This command generates WireGuard configuration files using a custom template and saves them in the specified root directory.

.LINK
  https://github.com/adnoctem/libps1

.NOTES
  Author: Maximilian Gindorfer <info@mvprowess.com>
  License: MIT
#>

# Parameters
param (
  [Parameter(
    Position = 0,
    Mandatory = $true,
    HelpMessage = "The public key of the WireGuard server."
  )]
  [string]$ServerPublicKey,

  [Parameter(
    Position = 1,
    Mandatory = $true,
    HelpMessage = "The path to the template configuration file (default: wg.conf.tpl)."
  )]
  [string]$RootDirectory = $PSScriptRoot,

  [Parameter(
    Position = 2,
    Mandatory = $false,
    HelpMessage = "The path to the template configuration file (default: wg.conf.tpl)."
  )]
  [string]$TemplatePath = "wg.conf.tpl",

  [Parameter(
    Position = 3,
    Mandatory = $false,
    HelpMessage = "The path to the pfSense export file (default: pfsense.conf)."
  )]
  [string]$PfSensePath = "pfsense.conf",

  [Parameter(
    Position = 4,
    Mandatory = $false,
    HelpMessage = "The DNS servers to be used in the configuration."
  )]
  [string[]]$ConfigurationInterfaceDNSServers = @("192.168.1.3", "192.168.99.254", "192.168.1.254"),

  [Parameter(
    Position = 5,
    Mandatory = $false,
    HelpMessage = "The peer allowed IP addresses."
  )]
  [string[]]$ConfigurationPeerAllowedIPs = @("192.168.99.0/24"),

  [Parameter(
    Position = 6,
    Mandatory = $false,
    HelpMessage = "The peer endpoint (e.g., hq.delta4x4.net:57173)."
  )]
  [string]$ConfigurationPeerEndpoint = "hq.delta4x4.net:57173",

  [Parameter(
    Position = 7,
    Mandatory = $false,
    HelpMessage = "The persistent keepalive interval in seconds (default: 25)."
  )]
  [int]$ConfigurationPersistentKeepalive = 25
)

# ---- Module import ------------------------------------
$root = Split-Path $PSScriptRoot -Parent
$module = Join-Path -Path $root 'lib/libps1.psm1'

Import-Module $module -Force
# -------------------------------------------------------

$template = @"
[Interface]
PrivateKey = <privatekey>
Address = <allowed_ips>
DNS = <dns_servers>

[Peer]
PublicKey = <pfsense_publickey>
PresharedKey = <pre-shared-key>
AllowedIPs = <peer_allowed_ips>
Endpoint = <peer_endpoint>
PersistentKeepalive = <persistent_keepalive>
"@

$templateContent = ""
$pfSenseExportContent = ""

# Paths and Template markers
$templatePath = Join-Path $RootDirectory $TemplatePath
$pfSensePath = Join-Path $RootDirectory $PfSensePath

# check for required file and load content, otherwise throw an error for missing pfSense export
if (-not (Test-Path $pfSensePath)) {
  Throw "Required file '$PfSensePath' is missing from the root directory. Please download the tunnel export from pfSense and place it in the script's directory."
}
else {
  $pfSenseExportContent = Get-Content -Path $pfSensePath -Raw
}

# check for template file, if not found use the built-in template string
if (-not (Test-Path -Path $templatePath -PathType Leaf)) {
  Write-Log "Could not find '$TemplatePath' in working directory. Using built-in template." -Color Red
  $templateContent = $template
}
else {
  $templateContent = Get-Content -Path $templatePath -Raw
}

# 1. Parse pfSense data (PSK and Client IP) into a Hashtable
$peerLookup = @{}
# Regex matches the Peer name in the comment and captures the block until the next peer or end of file
$regex = "(?ms)# Peer:\s*(.*?)\s*\[Peer\](.*?)(?=# Peer:|\z)"
$rgx_matches = [regex]::Matches($pfSenseExportContent, $regex)

foreach ($m in $rgx_matches) {
  $name = $m.Groups[1].Value.Trim()
  $content = $m.Groups[2].Value

  # Extract the PSK string
  $psk = if ($content -match "PresharedKey\s*=\s*(.*)") { $Matches[1].Trim() }
  # Extract the IP/CIDR (e.g., 192.168.99.12/32)
  $ip = if ($content -match "AllowedIPs\s*=\s*(.*)") { $Matches[1].Trim() }
  $peerLookup[$name] = @{ PSK = $psk; IP = $ip }
}

# 2. Iterate through local user folders to build the configs
$userFolders = Get-ChildItem -Directory $RootDirectory

foreach ($folder in $userFolders) {
  $userName = $folder.Name
  $privateKeyPath = Join-Path $folder.FullName "privatekey"
  $outputPath = Join-Path $folder.FullName "wg.conf"

  # Ensure we have the local private key AND a match in the pfSense export
  if ((Test-Path $privateKeyPath) -and $peerLookup.ContainsKey($userName)) {

    $privKey = (Get-Content -Path $privateKeyPath).Trim()
    $externalData = $peerLookup[$userName]

    # 3. Swap markers with the sourced data
    $finalConfig = $templateContent `
      -replace "<privatekey>", $privKey `
      -replace "<pfsense_publickey>", $ServerPublicKey `
      -replace "<pre-shared-key>", $externalData.PSK `
      -replace "<allowed_ips>", $externalData.IP `
      -replace "<peer_endpoint>", $ConfigurationPeerEndpoint `
      -replace "<persistent_keepalive>", $ConfigurationPersistentKeepalive `
      -replace "<dns_servers>", ($ConfigurationInterfaceDNSServers -join ", ") `
      -replace "<peer_allowed_ips>", ($ConfigurationPeerAllowedIPs -join ", ")

    $finalConfig | Out-File -FilePath $outputPath -Encoding UTF8
    Write-Log "Generated: $userName -> $($externalData.IP)" -Color Green
  }
  else {
    Write-Log "Skipping ${userName}: Missing privatekey file or name not found in pfsense.conf" -Color Yellow
  }
}