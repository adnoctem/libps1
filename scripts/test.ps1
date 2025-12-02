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
$module = Join-Path -Path $root 'lib/libps1.psd1'

Import-Module $module -Force
# -------------------------------------------------------

Write-Log -Message "This is a test!" -Color Cyan -Timestamps