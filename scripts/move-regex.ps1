<#
.SYNOPSIS
  Move files to a specified destination based on a custom regular expression.
.DESCRIPTION
	This PowerShell script takes a source path, a regular expression and a destination path as parameters. The source path
  is searched for files matching the RegEx, which are subsequently moved to the destination path.
.EXAMPLE
  PS> ./move-regex.ps1 C:\Users\Markus\Images ^IMG_([0-9]{4})_([0-9]{2}).(jpg|jpeg|png|gif|svg|webp)$ D:\Storage\Images
.LINK
  https://github.com/fmjstudios/pwshlib
.NOTES
  Author: Maximilian Gindorfer <info@fmj.dev>
  License: MIT
#>

# Parameter help description
param (
  [string] $Source = ""

  # [Parameter(Mandatory = $true)]
  # [regex] $RegEx,

  # [Parameter(Mandatory = $true)]
  # [string] $Destination
)

Import-Module "$PSScriptRoot\..\lib\log.psm1" -Verbose

$rgx = [regex]::Escape($regEx)

try {
  $path = Resolve-Path $Source

  if (-not (Test-Path -Path $path)) {
    Write-Log "Source path $Source was not found on the machine. Exiting" -Timestamps
  }
  else {
    Write-Log "Found source path $Source" -Timestamps
  }
}
catch {
  Write-Log "WTF, had to catch it..."
}