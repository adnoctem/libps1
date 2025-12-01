<#
.SYNOPSIS
  Move Outlook messages received between two dates into an archive folder.
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

# Parameters
param (
  # Start
  [Parameter(
    Position = 0,
    Mandatory = $true,
    HelpMessage = "The starting date from which to begin email archival."
  )]
  [ValidatePattern("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")]
  [string]$Start,

  # End
  [Parameter(
    Position = 1,
    Mandatory = $true,
    HelpMessage = "The ending date to which we're archiving emails."
  )]
  [ValidatePattern("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")]
  [string]$End
)


$Root = ""; # the root directory we're operating within
$User = ""; # the users name
$Destination = ""; # the final destination path

if ($PSVersionTable.OS -match "Windows") {
  $User = (whoami).Split([IO.Path]::DirectorySeparatorChar).Trim()[1]
  $UserHome = $env:USERPROFILE ?? (Join-Path $env:HOMEDRIVE "Users" $User)
} else {
  $User = (whoami).Trim()
  $UserHome = ($env:HOME).EndsWith($User) ? $env:HOME : (Join-Path $env:HOME $User)
}

$Root = Join-Path $UserHome ".delta4x4"
$Destination = Join-Path $Root "OutlookArchives"

$DateStart = Get-Date -Date $Start
$DateEnd = Get-Date -Date $End

Write-Host $Destination


Add-Type -AssemblyName "Microsoft.Office.Interop.Outlook" -ErrorAction Stop
$_outlook = New-Object -com outlook.application

$ns = $_outlook.GetNamespace("MAPI")
$store = $ns.Stores | Select-Object -First 1

$folders = $store.GetRootFolder().Folders

foreach ($folder in $folders) {
  Write-Host "Copying $(folder.Name)"
}
