#Requires -Version 5.1

<#
.SYNOPSIS
  Runs Pester tests for the winkit module.

.DESCRIPTION
  Invokes Pester against test files in the repository tests directory. By
  default all test files are executed. The script exits with the number of
  failed tests as its exit code, making it suitable for CI usage.

.PARAMETER Path
  Path to test files or directory. Defaults to the repository tests directory.

.EXAMPLE
  PS> ./test.ps1
  Runs all tests in the tests directory.

.EXAMPLE
  PS> ./test.ps1 -Path ./tests/user.ps1
  Runs only the user.ps1 test file.

.LINK
  https://github.com/adnoctem/winkit

.NOTES
  Author: Maximilian Gindorfer <info@mvprowess.com>
  License: MIT
#>

[CmdletBinding()]
param (
  [string[]]$Path = @(Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'tests')
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name Pester)) {
  Write-Error 'Pester is not installed. Install it with: Install-Module Pester -Force'
  exit 1
}

Import-Module Pester -MinimumVersion 5.0.0 -ErrorAction Stop

$config = [PesterConfiguration]::Default
$config.Run.Path = $Path
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'

$result = Invoke-Pester -Configuration $config

exit $result.FailedCount
