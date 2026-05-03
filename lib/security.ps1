function Get-DefenderThreatDetection {
  <#
    .SYNOPSIS
      Retrieves Microsoft Defender threat detections, optionally filtered by date.
    .DESCRIPTION
      Wraps Get-MpThreatDetection.  -Date sets a cutoff -- only detections with an
      InitialDetectionTime on or after that point are returned.  -OutputPath and
      -OutputFormat control whether results are printed to the terminal or written
      to a file (TXT or JSON).
    .PARAMETER Date
      Cutoff date for detections.  Accepts any value that Get-Date can parse
      (string, DateTime, etc.).  Defaults to right now.
    .PARAMETER OutputPath
      File path to write results to.  When omitted, results are printed to the
      terminal.
    .PARAMETER OutputFormat
      Output format: TXT (Formatted-List) or JSON.  Defaults to TXT.
    .PARAMETER IncludeURLs
      Augment each detection with a ThreatDescriptionURL property pointing to the
      official Microsoft threat encyclopedia entry.
    .EXAMPLE
      Get-DefenderThreatDetection
      Prints all threat detections to the terminal.
    .EXAMPLE
      Get-DefenderThreatDetection -Date '2026-04-01' -OutputPath '.\detections.json' -OutputFormat JSON
      Writes detections since April 1st 2026 as JSON.
    .EXAMPLE
      Get-DefenderThreatDetection -IncludeURLs -OutputPath '.\detections.json' -OutputFormat JSON
      Writes detections as JSON, each augmented with a ThreatDescriptionURL.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $false)]
    [object]
    $Date = (Get-Date),

    [Parameter(Mandatory = $false)]
    [string]
    $OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet('TXT', 'JSON')]
    [string]
    $OutputFormat = 'TXT',

    [Parameter(Mandatory = $false)]
    [switch]
    $IncludeURLs
  )

  $cutoffDate = if ($Date -is [datetime]) { $Date } else { Get-Date $Date }
  Write-Log -Message "Filtering Defender threat detections since $($cutoffDate.ToString('yyyy-MM-dd HH:mm:ss'))" -Color Yellow

  $detections = Get-MpThreatDetection | Where-Object { $_.InitialDetectionTime -ge $cutoffDate }

  if ($IncludeURLs -and $detections.Count -gt 0) {
    $detections = $detections | ForEach-Object {
      $_urlName = if ($_.PSObject.Properties.Name -contains 'ThreatName') { $_.ThreatName } else { $_.Name }
      $_ | Add-Member -NotePropertyName 'ThreatDescriptionURL' -NotePropertyValue (Get-DefenderThreatDescriptionURL -ThreatName $_urlName) -PassThru
    }
    Write-Log -Message '  -> ThreatDescriptionURL(s) appended' -Color Gray
  }
  Write-Log -Message "  -> $($detections.Count) detection(s) found" -Color Gray

  if ($PSBoundParameters.ContainsKey('OutputPath') -and -not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $_outPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
    switch ($OutputFormat) {
      'JSON' {
        $detections | ConvertTo-Json -Depth 3 | Out-File -FilePath $_outPath -Encoding utf8
      }
      'TXT' {
        $detections | Format-List * | Out-String -Width 4096 | Out-File -FilePath $_outPath -Encoding utf8
      }
    }
    Write-Log -Message "  -> Written to: $_outPath" -Color Green
  }
  else {
    $detections | Format-List *
  }
}

function Get-DefenderThreat {
  <#
    .SYNOPSIS
      Retrieves the full Microsoft Defender threat catalog.
    .DESCRIPTION
      Wraps Get-MpThreat.  -OutputPath and -OutputFormat control whether results
      are printed to the terminal or written to a file (TXT or JSON).
    .PARAMETER OutputPath
      File path to write results to.  When omitted, results are printed to the
      terminal.
    .PARAMETER OutputFormat
      Output format: TXT (Formatted-List) or JSON.  Defaults to TXT.
    .PARAMETER IncludeURLs
      Augment each threat with a ThreatDescriptionURL property pointing to the
      official Microsoft threat encyclopedia entry.
    .EXAMPLE
      Get-DefenderThreat
      Prints the threat catalog to the terminal.
    .EXAMPLE
      Get-DefenderThreat -OutputPath '.\threats.json' -OutputFormat JSON
      Writes the threat catalog as JSON.
    .EXAMPLE
      Get-DefenderThreat -IncludeURLs -OutputFormat JSON
      Prints the threat catalog as JSON, each augmented with a ThreatDescriptionURL.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $false)]
    [string]
    $OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet('TXT', 'JSON')]
    [string]
    $OutputFormat = 'TXT',

    [Parameter(Mandatory = $false)]
    [switch]
    $IncludeURLs
  )

  Write-Log -Message 'Retrieving Microsoft Defender threat catalog' -Color Yellow

  $threats = Get-MpThreat

  if ($IncludeURLs -and $threats.Count -gt 0) {
    $threats = $threats | ForEach-Object {
      $_urlName = if ($_.PSObject.Properties.Name -contains 'ThreatName') { $_.ThreatName } else { $_.Name }
      $_ | Add-Member -NotePropertyName 'ThreatDescriptionURL' -NotePropertyValue (Get-DefenderThreatDescriptionURL -ThreatName $_urlName) -PassThru
    }
    Write-Log -Message '  -> ThreatDescriptionURL(s) appended' -Color Gray
  }
  Write-Log -Message "  -> $($threats.Count) threat(s) found" -Color Gray

  if ($PSBoundParameters.ContainsKey('OutputPath') -and -not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $_outPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
    switch ($OutputFormat) {
      'JSON' {
        $threats | ConvertTo-Json -Depth 3 | Out-File -FilePath $_outPath -Encoding utf8
      }
      'TXT' {
        $threats | Format-List * | Out-String -Width 4096 | Out-File -FilePath $_outPath -Encoding utf8
      }
    }
    Write-Log -Message "  -> Written to: $_outPath" -Color Green
  }
  else {
    $threats | Format-List *
  }
}

function Get-DefenderThreatDescriptionURL {
  <#
    .SYNOPSIS
      Builds the public Microsoft Defender threat description URL for a given
      threat family name.
    .DESCRIPTION
      Takes a threat name (e.g. 'Trojan:Win32/Emotet'), URL-encodes it, and
      returns the full HTTP/S link to the official WDSI (Windows Defender
      Security Intelligence) threat encyclopedia entry.
    .PARAMETER ThreatName
      The human-readable threat family name, exactly as reported by
      Get-MpThreat (Name property) or Get-MpThreatDetection (ThreatName).
    .EXAMPLE
      Get-DefenderThreatDescriptionURL -ThreatName 'Trojan:Win32/Emotet'
      https://www.microsoft.com/en-us/wdsi/threats/threat/Trojan%3AWin32%2FEmotet
  #>
  [CmdletBinding()]
  [OutputType([string])]
  param (
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]
    $ThreatName
  )

  $encoded = [System.Web.HttpUtility]::UrlEncode($ThreatName)
  return "https://www.microsoft.com/en-us/wdsi/threats/threat/$encoded"
}

function Find-NewlyWrittenObject {
  <#
    .SYNOPSIS
      Finds files written near a point in time (e.g. around a Defender detection).
    .DESCRIPTION
      Recursively scans C:\ (or a custom path) for files whose LastWriteTime falls
      within a configurable window around the supplied -Date.  Designed to help
      identify artifacts dropped by malware at the time of a Defender alert.
      Results can be printed to the terminal or exported as TXT / JSON.
    .PARAMETER Date
      Anchor date/time.  Accepts any value that Get-Date can parse (string,
      DateTime, etc.).  Defaults to right now.
    .PARAMETER Before
      Number of hours before the anchor date to include.  Defaults to 2.
    .PARAMETER After
      Number of hours after the anchor date to include.  Defaults to 1.
    .PARAMETER Path
      Root path to search.  Defaults to the system drive (C:\).
    .PARAMETER OutputPath
      File path to write results to.  When omitted, results are printed to the
      terminal.
    .PARAMETER OutputFormat
      Output format: TXT (Formatted custom table) or JSON.  Defaults to TXT.
    .EXAMPLE
      Find-NewlyWrittenObject -Date '2026-04-30 10:15'
      Searches for files written between 08:15 and 11:15 on 2026-04-30.
    .EXAMPLE
      Find-NewlyWrittenObject -Date '2026-04-30' -Before 4 -After 2 -OutputPath '.\artifacts.json' -OutputFormat JSON
      Wider window, exported as JSON.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $false)]
    [object]
    $Date = (Get-Date),

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 168)]
    [int]
    $Before = 2,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 168)]
    [int]
    $After = 1,

    [Parameter(Mandatory = $false)]
    [string]
    $Path = "$env:SystemDrive\",

    [Parameter(Mandatory = $false)]
    [string]
    $OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet('TXT', 'JSON')]
    [string]
    $OutputFormat = 'TXT'
  )

  $anchorDate = if ($Date -is [datetime]) { $Date } else { Get-Date $Date }
  $windowStart = $anchorDate.AddHours(-$Before)
  $windowEnd = $anchorDate.AddHours($After)

  Write-Log -Message "Searching for files written between $($windowStart.ToString('yyyy-MM-dd HH:mm:ss')) and $($windowEnd.ToString('yyyy-MM-dd HH:mm:ss'))" -Color Yellow
  Write-Log -Message "  Root path: $Path" -Color Gray

  $items = Get-ChildItem -LiteralPath $Path -Recurse -ErrorAction SilentlyContinue |
  Where-Object { -not $_.PSIsContainer -and $_.LastWriteTime -gt $windowStart -and $_.LastWriteTime -lt $windowEnd } |
  Sort-Object LastWriteTime |
  Select-Object LastWriteTime,
  LastWriteTimeUtc,
  LastAccessTime,
  LastAccessTimeUtc,
  CreationTime,
  CreationTimeUtc,
  Mode,
  IsReadOnly,
  Length,
  Extension,
  FullName

  Write-Log -Message "  -> $($items.Count) file(s) found" -Color Gray

  if ($items.Count -eq 0) { return }

  if ($PSBoundParameters.ContainsKey('OutputPath') -and -not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $_outPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
    switch ($OutputFormat) {
      'JSON' {
        $items | ConvertTo-Json -Depth 2 | Out-File -FilePath $_outPath -Encoding utf8
      }
      'TXT' {
        $items | Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $_outPath -Encoding utf8
      }
    }
    Write-Log -Message "  -> Written to: $_outPath" -Color Green
  }
  else {
    $items | Format-Table -AutoSize
  }
}