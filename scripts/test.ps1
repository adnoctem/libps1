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

# Import-Module $module -Force -Verbose
Import-Module "$PSScriptRoot\..\lib\libps1.psd1"
# -------------------------------------------------------

# Write-Log -Message "This is a test!" -Color Cyan -Timestamps

Write-Log "This is some bs" -Color Cyan -Timestamps
Write-Log "`$root would have been: $root"
Write-Log "`$module would have been: $module"
Write-Log "Now we're using $PSScriptRoot\..\lib\libps1.psd1"

# ConvertFrom-HTMLtoWord -FileHTML '/tmp/test.html' -OutputFile '/tmp/test-out.docx' -Show | Out-Null
Convert-HTMLToPDF -FilePath '/tmp/test.html' -OutputFilePath '/tmp/test-out.pdf'