#Requires -Version 5.1

<#
.SYNOPSIS
  Updates DNS zone configurations on AutoDNS (InternetX Domainrobot) via the JSON API.

.DESCRIPTION
  Reads a JSON configuration file describing desired zone states (main IP, resource records,
  DNSSEC, etc.) and applies them to AutoDNS.  Discovers the virtual name server automatically
  for each zone.  Provides safety checks including TTL warnings and confirmation prompts before
  replacing resource records.

.PARAMETER Config
  Path to a JSON configuration file describing the desired zone states.  See -ExportConfig
  for the template format.

.PARAMETER Credential
  A PSCredential object for HTTP Basic authentication against the AutoDNS JSON API.
  Obtain via Get-Credential or pass a credential object.

.PARAMETER Context
  The AutoDNS context number (default: 4 for live system; 1 for demo).

.PARAMETER DryRun
  Preview the changes that would be made without applying them.

.PARAMETER Force
  Skip confirmation prompts for destructive operations (e.g., replacing all resource records).

.PARAMETER ExportConfig
  Export a documented JSON configuration template to the console (or to a file with -ExportPath)
  and exit.

.PARAMETER ExportPath
  When used together with -ExportConfig, writes the template JSON to this file path instead of
  printing to the console.

.PARAMETER PassThru
  Output result objects for each processed zone entry.

.EXAMPLE
  PS> $cred = Get-Credential
  PS> ./Update-AutoDNSZones.ps1 -Config .\zones.json -Credential $cred
  Reads zone configuration from zones.json and applies changes to AutoDNS.

.EXAMPLE
  PS> ./Update-AutoDNSZones.ps1 -Config .\zones.json -Credential $cred -DryRun
  Previews the changes that would be made without applying them.

.EXAMPLE
  PS> ./Update-AutoDNSZones.ps1 -ExportConfig
  Prints the configuration template to the console.

.EXAMPLE
  PS> ./Update-AutoDNSZones.ps1 -ExportConfig -ExportPath .\zones-template.json
  Saves the configuration template to zones-template.json.

.LINK
  https://github.com/adnoctem/libps1
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
  [Parameter(Mandatory = $false, HelpMessage = 'Path to a JSON configuration file describing desired zone states.')]
  [string]$Config,

  [Parameter(Mandatory = $false, HelpMessage = 'PSCredential for HTTP Basic authentication against the AutoDNS API.')]
  [pscredential]$Credential,

  [Parameter(Mandatory = $false, HelpMessage = 'AutoDNS context number (4 = live, 1 = demo).')]
  [int]$Context = 4,

  [Parameter(Mandatory = $false, HelpMessage = 'Preview changes without applying them.')]
  [switch]$DryRun,

  [Parameter(Mandatory = $false, HelpMessage = 'Skip confirmation prompts.')]
  [switch]$Force,

  [Parameter(Mandatory = $false, HelpMessage = 'Export the configuration template to the console (or to a file with -ExportPath).')]
  [switch]$ExportConfig,

  [Parameter(Mandatory = $false, HelpMessage = 'File path for -ExportConfig.')]
  [string]$ExportPath,

  [Parameter(Mandatory = $false)]
  [switch]$PassThru
)

# ---- Module import -----------------------------------------------------------
$scriptRoot = Split-Path $PSScriptRoot -Parent
$module = Join-Path $scriptRoot 'lib/libps1.psm1'
Import-Module $module -Force
# -----------------------------------------------------------------------------

$baseUrl = 'https://api.autodns.com/v1'
$highTtlThreshold = 1800

# Template for -ExportConfig
$configTemplate = @(
  @{
    origin = 'example.com'
    main = @{
      address = '203.0.113.10'
      ttl = 3600
    }
    wwwInclude = $true
    dnssec = $true
    records = @(
      @{
        name = '@'
        type = 'A'
        value = '203.0.113.10'
        ttl = 3600
      }
      @{
        name = 'www'
        type = 'A'
        value = '203.0.113.10'
        ttl = 3600
      }
      @{
        name = 'mail'
        type = 'MX'
        value = 'mail.example.com'
        pref = 10
        ttl = 3600
      }
      @{
        name = '@'
        type = 'TXT'
        value = 'v=spf1 mx ~all'
        ttl = 3600
      }
    )
  }
)

# ---- Helper functions -------------------------------------------------------

function Invoke-AutoDNSRequest {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $false)]
    [string]$Method = 'GET',
    [Parameter(Mandatory = $false)]
    [object]$Body
  )

  $pair = "$($Credential.UserName):$($Credential.GetNetworkCredential().Password)"
  $encodedCreds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))

  $params = @{
    Uri = "$baseUrl$Path"
    Method = $Method
    Headers = @{
      Authorization = "Basic $encodedCreds"
      'X-Domainrobot-Context' = $Context
      'User-Agent' = 'libps1/1.0'
    }
    ContentType = 'application/json'
  }

  if ($Body) {
    $params['Body'] = ($Body | ConvertTo-Json -Depth 10)
  }

  try {
    $response = Invoke-RestMethod @params
  }
  catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $statusText = $_.Exception.Response.StatusDescription
    throw "AutoDNS API error ($statusCode $statusText) for $Method $Path`: $_"
  }

  if ($response.status.type -ne 'SUCCESS' -and $response.status.type -ne 'N') {
    throw "AutoDNS API returned status '$($response.status.type)': $($response.status.text)"
  }

  return $response
}

function Get-AutoDNSZone {
  [CmdletBinding()]
  param([string]$Origin)

  $response = Invoke-AutoDNSRequest -Path "/zone/$Origin"
  if (-not $response.data -or $response.data.Count -eq 0) {
    throw "Zone '$Origin' not found on AutoDNS."
  }
  return $response.data[0]
}

function Compare-ZoneState {
  [CmdletBinding()]
  param(
    [object]$Current,
    [object]$Desired
  )

  $changes = @()

  # Check main IP
  $currentMain = if ($Current.main) { $Current.main.address } else { $null }
  $desiredMain = if ($Desired.main) { $Desired.main.address } else { $null }
  if ($desiredMain -and $currentMain -ne $desiredMain) {
    $changes += @{
      Field = 'main'
      Current = $currentMain
      Desired = $desiredMain
    }
  }

  # Check wwwInclude
  $currentWww = if ($Current.PSObject.Properties.Name -contains 'wwwInclude') { [bool]$Current.wwwInclude } else { $null }
  $desiredWww = if ($Desired.PSObject.Properties.Name -contains 'wwwInclude') { $Desired.wwwInclude } else { $null }
  if ($null -ne $desiredWww -and $currentWww -ne $desiredWww) {
    $changes += @{
      Field = 'wwwInclude'
      Current = $currentWww
      Desired = $desiredWww
    }
  }

  # Check dnssec
  $currentDnssec = if ($Current.PSObject.Properties.Name -contains 'dnssec') { [bool]$Current.dnssec } else { $null }
  $desiredDnssec = if ($Desired.PSObject.Properties.Name -contains 'dnssec') { $Desired.dnssec } else { $null }
  if ($null -ne $desiredDnssec -and $currentDnssec -ne $desiredDnssec) {
    $changes += @{
      Field = 'dnssec'
      Current = $currentDnssec
      Desired = $desiredDnssec
    }
  }

  # Check records
  $currentRecords = if ($Current.resourceRecords) { $Current.resourceRecords } else { @() }
  $desiredRecords = if ($Desired.resourceRecords) { $Desired.resourceRecords } else { @() }
  if ($desiredRecords.Count -gt 0) {
    $recordsMatch = Compare-RecordArrays -Current $currentRecords -Desired $desiredRecords
    if (-not $recordsMatch) {
      $changes += @{
        Field = 'records'
        Current = "($($currentRecords.Count) existing record(s))"
        Desired = "($($desiredRecords.Count) desired record(s))"
        ReplaceAll = $true
      }
    }
  }

  return $changes
}

function Compare-RecordArrays {
  [CmdletBinding()]
  param(
    [object[]]$Current,
    [object[]]$Desired
  )

  if ($Current.Count -ne $Desired.Count) { return $false }

  foreach ($desired in $Desired) {
    $match = $false
    foreach ($current in $Current) {
      $nameMatch = $current.name -eq $desired.name
      $typeMatch = $current.type -eq $desired.type
      $valueMatch = $current.value -eq $desired.value
      $ttlMatch = (-not $desired.PSObject.Properties.Name.Contains('ttl')) -or ($null -eq $desired.ttl) -or ($current.ttl -eq $desired.ttl)
      $prefMatch = (-not $desired.PSObject.Properties.Name.Contains('pref')) -or ($null -eq $desired.pref) -or ($current.pref -eq $desired.pref)
      if ($nameMatch -and $typeMatch -and $valueMatch -and $ttlMatch -and $prefMatch) {
        $match = $true
        break
      }
    }
    if (-not $match) { return $false }
  }
  return $true
}

function Get-HighTtlRecords {
  [CmdletBinding()]
  param([object[]]$Records)

  $high = @()
  foreach ($r in $Records) {
    if ($r.ttl -and $r.ttl -gt $highTtlThreshold) {
      $high += $r
    }
  }
  return $high
}

function Confirm-DestructiveOperation {
  [CmdletBinding()]
  param([string]$Message)

  if ($Force) { return $true }

  $response = Read-Host "$Message`nType 'yes' to confirm"
  return $response -eq 'yes'
}

# ---- Export config -----------------------------------------------------------
if ($ExportConfig) {
  if ($PSBoundParameters.ContainsKey('ExportPath') -and -not [string]::IsNullOrWhiteSpace($ExportPath)) {
    $_exportPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ExportPath)
    $configTemplate | ConvertTo-Json -Depth 10 | Out-File -FilePath $_exportPath -Encoding utf8
    Write-Log -Message "Configuration template exported to: $_exportPath" -Color Green
  }
  else {
    $configTemplate | ConvertTo-Json -Depth 10
  }
  exit 0
}

# ---- Validate config --------------------------------------------------------
if (-not $PSBoundParameters.ContainsKey('Config') -or [string]::IsNullOrWhiteSpace($Config)) {
  Write-Log -Message '-Config is required (or use -ExportConfig to generate a template).' -Color Red
  exit 1
}

$_configPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Config)
if (-not (Test-Path -LiteralPath $_configPath)) {
  Write-Log -Message "Config file not found: '$_configPath'" -Color Red
  exit 1
}

if (-not $Credential) {
  Write-Log -Message '-Credential is required for AutoDNS API authentication.' -Color Red
  exit 1
}

# ---- Parse config -----------------------------------------------------------
try {
  $_jsonContent = Get-Content -LiteralPath $_configPath -Raw -ErrorAction Stop
  $zoneConfigs = ConvertFrom-Json -InputObject $_jsonContent -ErrorAction Stop
  if ($zoneConfigs -isnot [array]) { $zoneConfigs = @($zoneConfigs) }
}
catch {
  Write-Log -Message "Failed to parse config file '$_configPath': $_" -Color Red
  exit 1
}

Write-Log -Message "Loaded $($zoneConfigs.Count) zone configuration(s) from '$_configPath'" -Color Cyan

# ---- DryRun preamble --------------------------------------------------------
if ($DryRun) {
  $WhatIfPreference = $true
  Write-Log -Message "DRY RUN - no changes will be applied`n" -Color Yellow
}

# ---- Process each zone ------------------------------------------------------
$results = @()

foreach ($zoneCfg in $zoneConfigs) {
  $origin = $zoneCfg.origin
  if ([string]::IsNullOrWhiteSpace($origin)) {
    Write-Log -Message 'Skipping config entry with empty or missing origin.' -Color Yellow
    continue
  }

  Write-Log -Message "`nProcessing zone: $origin" -Color Cyan

  # 1. Get current zone state
  try {
    $currentZone = Get-AutoDNSZone -Origin $origin
  }
  catch {
    Write-Log -Message "  -> $_" -Color Red
    continue
  }

  $vns = $currentZone.virtualNameServer
  if ([string]::IsNullOrWhiteSpace($vns)) {
    Write-Log -Message "  -> Could not determine virtual name server for '$origin'. Skipping." -Color Yellow
    continue
  }
  Write-Log -Message "  Virtual name server: $vns" -Color Gray

  # 2. Build desired state
  $desiredPayload = @{}

  if ($zoneCfg.PSObject.Properties.Name -contains 'main') {
    $desiredPayload.main = $zoneCfg.main
  }
  if ($zoneCfg.PSObject.Properties.Name -contains 'wwwInclude') {
    $desiredPayload.wwwInclude = [bool]$zoneCfg.wwwInclude
  }
  if ($zoneCfg.PSObject.Properties.Name -contains 'dnssec') {
    $desiredPayload.dnssec = [bool]$zoneCfg.dnssec
  }
  if ($zoneCfg.PSObject.Properties.Name -contains 'records' -and $zoneCfg.records.Count -gt 0) {
    $desiredPayload.resourceRecords = $zoneCfg.records
  }

  # 3. Compare current vs desired
  $changes = Compare-ZoneState -Current $currentZone -Desired $desiredPayload

  if ($changes.Count -eq 0) {
    Write-Log -Message "  -> No changes detected for '$origin'." -Color Green
    continue
  }

  # 4. Display changes
  Write-Log -Message "  -> Changes detected:" -Color Yellow
  foreach ($change in $changes) {
    Write-Log -Message "      * $($change.Field): '$($change.Current)' -> '$($change.Desired)'" -Color Yellow
  }

  # 5. TTL warning
  $currentRecords = if ($currentZone.resourceRecords) { $currentZone.resourceRecords } else { @() }
  $highTtlRecords = Get-HighTtlRecords -Records $currentRecords
  if ($highTtlRecords.Count -gt 0) {
    Write-Log -Message "  -> WARNING: $($highTtlRecords.Count) existing record(s) have TTL > $highTtlThreshold seconds:" -Color Red
    foreach ($r in $highTtlRecords) {
      Write-Log -Message "      $($r.name) $($r.type) TTL=$($r.ttl)" -Color Red
    }
    Write-Log -Message '     Outstanding DNS propagation may cause stale values to persist.' -Color Red
    if (-not $DryRun) {
      $confirmed = Confirm-DestructiveOperation -Message "  Continue updating zone '$origin' despite high TTLs?"
      if (-not $confirmed) {
        Write-Log -Message "  -> Skipped '$origin' (user cancelled)." -Color Yellow
        continue
      }
    }
  }

  # 6. Records replacement warning
  $hasRecordChange = $changes | Where-Object { $_.Field -eq 'records' -and $_.ReplaceAll }
  if ($hasRecordChange) {
    Write-Log -Message '  -> WARNING: This will REPLACE all existing resource records for this zone.' -Color Red
    if (-not $DryRun) {
      $confirmed = Confirm-DestructiveOperation -Message "  Replace all resource records for '$origin'?"
      if (-not $confirmed) {
        Write-Log -Message "  -> Skipped '$origin' (user cancelled)." -Color Yellow
        continue
      }
    }
  }

  # 7. Build full PUT body (merge current with desired overrides)
  $putBody = @{
    origin = $origin
    virtualNameServer = $vns
    main = if ($desiredPayload.Contains('main')) { $desiredPayload.main } else { $currentZone.main }
    wwwInclude = if ($desiredPayload.Contains('wwwInclude')) { $desiredPayload.wwwInclude } else { [bool]$currentZone.wwwInclude }
    dnssec = if ($desiredPayload.Contains('dnssec')) { $desiredPayload.dnssec } else { [bool]$currentZone.dnssec }
    resourceRecords = if ($desiredPayload.Contains('resourceRecords')) { $desiredPayload.resourceRecords } else { $currentZone.resourceRecords }
    nameServers = $currentZone.nameServers
    soa = $currentZone.soa
  }

  # 8. Apply
  if ($DryRun) {
    Write-Log -Message "  -> [DRY RUN] Would update zone '$origin' on $vns" -Color Yellow
    $results += @{
      Origin = $origin
      Status = 'DryRun'
      Changes = $changes
    }
    continue
  }

  try {
    Invoke-AutoDNSRequest -Path "/zone/$origin/$vns" -Method PUT -Body $putBody
    Write-Log -Message "  -> Zone '$origin' updated successfully." -Color Green
    $results += @{
      Origin = $origin
      Status = 'Updated'
      Changes = $changes
    }
  }
  catch {
    Write-Log -Message "  -> Failed to update zone '$origin': $_" -Color Red
    $results += @{
      Origin = $origin
      Status = 'Failed'
      Error = $_
    }
    continue
  }

  # 9. DNSSEC domain-level update if toggled
  if ($desiredPayload.Contains('dnssec') -and $desiredPayload.dnssec -ne [bool]$currentZone.dnssec) {
    Write-Log -Message '  -> Updating DNSSEC configuration at domain level ...' -Color Yellow
    try {
      $dnssecBody = @{ dnssec = $desiredPayload.dnssec }
      Invoke-AutoDNSRequest -Path "/domain/$origin/_dnssec" -Method PUT -Body $dnssecBody | Out-Null
      Write-Log -Message '  -> DNSSEC updated at domain level.' -Color Green
    }
    catch {
      Write-Log -Message "  -> Warning: DNSSEC domain update failed: $_" -Color Yellow
    }
  }
}

Write-Log -Message "`nDone. Processed $($zoneConfigs.Count) zone configuration(s)." -Color Cyan

if ($PassThru -or $DryRun) {
  $results
}
