#Requires -Version 5.0

<#
.SYNOPSIS
  Repairs a broken or missing WinGet installation in Windows.

.DESCRIPTION
  Reinstalls the NuGet package provider, the Microsoft.WinGet.Client PowerShell
  module, and then runs the official repair command.  Use -DryRun to preview
  each step without making changes.

.PARAMETER DryRun
  Preview the repair steps without executing them.

.EXAMPLE
  PS> ./Repair-WinGet.ps1
  Repairs WinGet by reinstalling dependencies and running Repair-WinGetPackageManager.

.EXAMPLE
  PS> ./Repair-WinGet.ps1 -DryRun
  Shows which repair steps would be taken without making changes.

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
    Mandatory = $false,
    HelpMessage = 'Preview the repair steps without executing them.'
  )]
  [switch]
  $DryRun
)

# Bootstrap: import the libps1 module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\lib\libps1.psd1' -Resolve
Import-Module $modulePath -Force -ErrorAction Stop

# When -DryRun is active, enable WhatIf for downstream calls and log intent.
if ($DryRun) {
  $WhatIfPreference = $true
  Write-Log -Message "DRY RUN — no changes will be applied`n" -Color Yellow
}

$anyFailures = $false

# Step 1 — Install / update the NuGet package provider
if ($DryRun) {
  Write-Log -Message '[DRY RUN] Would install/update NuGet package provider.' -Color Yellow
}
else {
  Write-Log -Message 'Step 1/3: Installing NuGet package provider …' -Color Yellow

  try {
    $null = Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
    Write-Log -Message '  -> Done — NuGet package provider is ready.' -Color Green
  }
  catch {
    Write-Log -Message "  -> FAILED — could not install NuGet: $_" -Color Red
    $anyFailures = $true
  }
}

# Step 2 — Install / update the Microsoft.WinGet.Client module
if ($DryRun) {
  Write-Log -Message '[DRY RUN] Would install/update Microsoft.WinGet.Client module.' -Color Yellow
}
else {
  Write-Log -Message 'Step 2/3: Installing Microsoft.WinGet.Client module …' -Color Yellow

  try {
    $null = Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -ErrorAction Stop
    Write-Log -Message '  -> Done — Microsoft.WinGet.Client module is ready.' -Color Green
  }
  catch {
    Write-Log -Message "  -> FAILED — could not install Microsoft.WinGet.Client: $_" -Color Red
    $anyFailures = $true
  }
}

# Step 3 — Run the official WinGet repair command
if ($DryRun) {
  Write-Log -Message '[DRY RUN] Would run Repair-WinGetPackageManager -Force -Latest.' -Color Yellow
}
else {
  Write-Log -Message 'Step 3/3: Running Repair-WinGetPackageManager …' -Color Yellow

  try {
    $null = Repair-WinGetPackageManager -Force -Latest -ErrorAction Stop
    Write-Log -Message '  -> Done — WinGet repair completed.' -Color Green
  }
  catch {
    Write-Log -Message "  -> FAILED — Repair-WinGetPackageManager threw an error: $_" -Color Red
    $anyFailures = $true
  }
}

# Summary
if ($DryRun) {
  Write-Log -Message "`nDRY RUN COMPLETE — no changes were made" -Color Yellow
}
elseif ($anyFailures) {
  Write-Log -Message "`nWinGet repair completed with errors — review the output above." -Color Yellow
}
else {
  Write-Log -Message "`nWinGet repair completed successfully." -Color Green
}