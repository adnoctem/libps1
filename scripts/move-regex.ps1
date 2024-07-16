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

#Requires -Version 3

# Parameter help description
Param (
  [Parameter(Mandatory)]
  [string] $source,

  # [Parameter(Mandatory)]
  [regex] $regEx,

  # [Parameter(Mandatory)]
  [string] $destianation
)

$rgx = [regex]::Escape($regEx)