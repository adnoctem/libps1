#Requires -Version 5.0

<#
.SYNOPSIS
  Removes selected bundled and sponsored UPF AppX/MSIX packages.
.DESCRIPTION
  Uses a built-in grouped package pattern table and removes matching installed
  UPF AppX/MSIX packages through libps1 lifecycle helpers. Provisioned package
  removal is opt-in, protected packages are skipped by default, and -DryRun
  previews the concrete removal set.
.PARAMETER Group
  Built-in group names to remove. Defaults to Default.
.PARAMETER Pattern
  Additional package wildcard patterns to include.
.PARAMETER Config
  Optional PSD1 or JSON file with grouped package patterns. Values override or
  add to the built-in groups.
.PARAMETER AllUsers
  Remove installed packages for all users. Requires elevation.
.PARAMETER Provisioned
  Remove provisioned packages from the Windows image for future users.
.PARAMETER IncludeProtected
  Include packages normally protected by libps1 safety checks.
.PARAMETER Force
  Required together with -IncludeProtected to actually remove protected matches.
.PARAMETER DryRun
  Preview matching packages and removals without changing the system.
.PARAMETER ExportConfig
  Export the default package pattern groups as JSON and exit.
.PARAMETER ExportPath
  Output path used with -ExportConfig.
.PARAMETER PassThru
  Return structured lifecycle results.
.EXAMPLE
  PS> ./Remove-AppxBloatware.ps1 -DryRun
.EXAMPLE
  PS> ./Remove-AppxBloatware.ps1 -Group Default,Sponsored -Provisioned -DryRun
.LINK
  https://github.com/adnoctem/libps1
.NOTES
  Author: Maximilian Gindorfer <info@mvprowess.com>
  License: MIT
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param (
  [string[]]$Group = @('Default'),
  [string[]]$Pattern,
  [string]$Config,
  [switch]$AllUsers,
  [switch]$Provisioned,
  [switch]$IncludeProtected,
  [switch]$Force,
  [switch]$DryRun,
  [switch]$ExportConfig,
  [string]$ExportPath,
  [switch]$PassThru
)

# ---- Module import -----------------------------------------------------------
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$module = Join-Path $root 'lib/libps1.psm1'
Import-Module $module -Force
# -----------------------------------------------------------------------------

if ($DryRun) {
  $WhatIfPreference = $true
  Write-Log -Message "DRY RUN - no UPF AppX/MSIX packages will be removed`n" -Color Yellow
}

$_packageGroups = @{
  Default = @(
    'Microsoft.BingWeather*',
    'Microsoft.BingNews',
    'Microsoft.GetHelp',
    'Microsoft.Getstarted',
    'Microsoft.MicrosoftOfficeHub',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.News',
    'Microsoft.People',
    'Microsoft.SkypeApp',
    'Microsoft.WindowsFeedbackHub*',
    'Microsoft.WindowsMaps',
    'Microsoft.WindowsSoundRecorder',
    'Microsoft.ZuneMusic',
    'Microsoft.ZuneVideo'
  )

  Sponsored = @(
    'Clipchamp*',
    'Disney*',
    'Netflix*',
    'Spotify*',
    'Roblox*',
    'Amazon*',
    'Instagram*',
    'Keeper*',
    'CandyCrush*',
    'BubbleWitch3Saga*',
    'AdobeSystemsIncorporated.AdobePhotoshopExpress*',
    'Duolingo-LearnLanguagesforFree*',
    'PandoraMediaInc*',
    'Flipboard.Flipboard*'
  )

  Xbox = @(
    'Microsoft.XboxGamingOverlay',
    'Microsoft.Xbox.TCUI',
    'Microsoft.XboxApp',
    'Microsoft.XboxGameOverlay',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.XboxSpeechToTextOverlay'
  )

  Optional = @(
    'Microsoft.Office.OneNote',
    'Microsoft.Office.Todo.List',
    'Microsoft.RemoteDesktop',
    'Microsoft.Whiteboard',
    'Microsoft.WindowsAlarms',
    'microsoft.windowscommunicationsapps'
  )

  OEM = @(
    'DolbyLaboratories.DolbyAccess*',
    'NVIDIACorp.NVIDIAControlPanel*',
    'Microsoft.DrawboardPDF*',
    'ActiproSoftwareLLC*'
  )
}

if ($PSBoundParameters.ContainsKey('Config')) {
  if ([string]::IsNullOrWhiteSpace($Config)) {
    Write-Log -Message '-Config requires a PSD1 or JSON file path.' -Color Red
    exit 1
  }

  $_configPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Config)
  if (-not (Test-Path -LiteralPath $_configPath)) {
    Write-Log -Message "Config file not found: $_configPath" -Color Red
    exit 1
  }

  try {
    $_extension = [System.IO.Path]::GetExtension($_configPath)
    if ($_extension -eq '.psd1') {
      $_configGroups = Import-PowerShellDataFile -Path $_configPath
    }
    else {
      $_configGroups = ConvertFrom-Json -InputObject (Get-Content -LiteralPath $_configPath -Raw -ErrorAction Stop) -ErrorAction Stop
    }

    foreach ($_property in $_configGroups.PSObject.Properties) {
      $_packageGroups[$_property.Name] = @($_property.Value)
    }
  }
  catch {
    Write-Log -Message "Failed to import config '$_configPath': $_" -Color Red
    exit 1
  }
}

if ($ExportConfig) {
  if ($DryRun) {
    Write-Log -Message '-DryRun cannot be combined with -ExportConfig.' -Color Red
    exit 1
  }
  if ($PSBoundParameters.ContainsKey('ExportPath') -and -not [string]::IsNullOrWhiteSpace($ExportPath)) {
    $_exportPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ExportPath)
    $_packageGroups | ConvertTo-Json -Depth 4 | Out-File -FilePath $_exportPath -Encoding utf8
    Write-Log -Message "Default AppX bloatware package groups exported to: $_exportPath" -Color Green
  }
  else {
    $_packageGroups | ConvertTo-Json -Depth 4
  }
  exit 0
}

$_patterns = New-Object System.Collections.ArrayList
foreach ($_group in $Group) {
  if (-not $_packageGroups.ContainsKey($_group)) {
    Write-Log -Message "Unknown package group: $_group" -Color Red
    Write-Log -Message "Available groups: $($_packageGroups.Keys -join ', ')" -Color Gray
    exit 1
  }

  foreach ($_entry in @($_packageGroups[$_group])) {
    [void]$_patterns.Add($_entry)
  }
}

foreach ($_entry in @($Pattern)) {
  if (-not [string]::IsNullOrWhiteSpace($_entry)) {
    [void]$_patterns.Add($_entry)
  }
}

$_patterns = @($_patterns | Sort-Object -Unique)
if ($_patterns.Count -eq 0) {
  Write-Log -Message 'No package patterns selected.' -Color Yellow
  exit 0
}

Write-Log -Message "Selected UPF AppX/MSIX bloatware groups: $($Group -join ', ')" -Color Yellow
Write-Log -Message "Pattern count: $($_patterns.Count)" -Color Gray

$_matches = @(Find-UPFAppxPackage -Pattern $_patterns -Installed -AllUsers:$AllUsers -Provisioned:$Provisioned -IncludeProtected:$IncludeProtected)
$_matchedPackages = @($_matches | Where-Object { $_.Matched -and $_.Package })
$_skippedProtected = @($_matches | Where-Object { $_.Protected })
$_unmatched = @($_matches | Where-Object { -not $_.Matched })

Write-Log -Message "Matched packages: $($_matchedPackages.Count) | Protected matches: $($_skippedProtected.Count) | Unmatched patterns: $($_unmatched.Count)" -Color Gray

if ($DryRun -and $_matchedPackages.Count -gt 0) {
  $_matchedPackages |
    Select-Object Pattern, Protected, ProtectedReason, @{
      Name = 'Source'
      Expression = { $_.Package.Source }
    }, @{
      Name = 'PackageName'
      Expression = { $_.Package.PackageName }
    } |
    Format-Table -AutoSize
}

$_results = Uninstall-UPFAppxPackageSet -Pattern $_patterns -AllUsers:$AllUsers -Provisioned:$Provisioned -IncludeProtected:$IncludeProtected -Force:$Force -DryRun:$DryRun -PassThru -WhatIf:$WhatIfPreference

if ($PassThru -or $DryRun) {
  $_results
}
