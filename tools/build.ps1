#Requires -Version 5.0

<#
.SYNOPSIS
  Builds deployable winkit source archives.

.DESCRIPTION
  Creates a clean bundle containing only the repository's lib and scripts
  directories, preserving their relative layout so the scripts can continue to
  import winkit through their local path assumptions.

  Archives are written to the dist directory, which is created when it does not
  already exist. By default, the script builds both:

    dist/winkit.zip
    dist/winkit.tar.gz

  Existing archives with the same names are overwritten. The temporary staging
  directory is created under dist and removed after the archives are produced.

.PARAMETER OutputDirectory
  Directory where archives are written. Defaults to the repository dist folder.

.PARAMETER Name
  Base archive name without extension. Defaults to winkit.

.PARAMETER Format
  Archive format to build. Use Zip, TarGz, or Both. Defaults to Both.

.EXAMPLE
  PS> ./build.ps1
  Creates dist/winkit.zip and dist/winkit.tar.gz.

.EXAMPLE
  PS> ./build.ps1 -Format Zip
  Creates only dist/winkit.zip.

.EXAMPLE
  PS> ./build.ps1 -OutputDirectory C:\Temp -Name winkit-vm-test
  Creates C:\Temp\winkit-vm-test.zip and C:\Temp\winkit-vm-test.tar.gz.

.LINK
  https://github.com/adnoctem/winkit

.NOTES
  Author: Maximilian Gindorfer <info@mvprowess.com>
  License: MIT
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
  [string]$OutputDirectory = (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'dist'),

  [ValidateNotNullOrEmpty()]
  [string]$Name = 'winkit',

  [ValidateSet('Both', 'Zip', 'TarGz')]
  [string]$Format = 'Both'
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath((Split-Path -Path $PSScriptRoot -Parent))
$outputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDirectory)
$stagingPath = Join-Path -Path $outputPath -ChildPath "_staging-$Name"
$zipPath = Join-Path -Path $outputPath -ChildPath "$Name.zip"
$tarGzPath = Join-Path -Path $outputPath -ChildPath "$Name.tar.gz"

function Copy-BuildDirectory {
  param (
    [Parameter(Mandatory = $true)]
    [string]$Source,

    [Parameter(Mandatory = $true)]
    [string]$Destination
  )

  if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
    throw "Required build source directory not found: $Source"
  }

  Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

function Clear-BuildPath {
  param (
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (Test-Path -LiteralPath $Path) {
    Remove-Item -LiteralPath $Path -Recurse -Force
  }
}

if (-not (Test-Path -LiteralPath $outputPath -PathType Container)) {
  New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

try {
  Clear-BuildPath -Path $stagingPath
  New-Item -Path $stagingPath -ItemType Directory -Force | Out-Null

  Copy-BuildDirectory -Source (Join-Path -Path $repositoryRoot -ChildPath 'lib') -Destination $stagingPath
  Copy-BuildDirectory -Source (Join-Path -Path $repositoryRoot -ChildPath 'scripts') -Destination $stagingPath

  if ($Format -eq 'Both' -or $Format -eq 'Zip') {
    if ($PSCmdlet.ShouldProcess($zipPath, 'Create ZIP archive')) {
      Clear-BuildPath -Path $zipPath
      Compress-Archive -Path (Join-Path -Path $stagingPath -ChildPath 'lib'), (Join-Path -Path $stagingPath -ChildPath 'scripts') -DestinationPath $zipPath -Force
      Write-Output "Built: $zipPath"
    }
  }

  if ($Format -eq 'Both' -or $Format -eq 'TarGz') {
    $tarCommand = Get-Command -Name tar -ErrorAction SilentlyContinue
    if (-not $tarCommand) {
      throw 'tar was not found on PATH. Build the ZIP archive instead or install a tar-compatible tool.'
    }

    if ($PSCmdlet.ShouldProcess($tarGzPath, 'Create tar.gz archive')) {
      Clear-BuildPath -Path $tarGzPath
      Push-Location -LiteralPath $stagingPath
      try {
        & $tarCommand.Source -czf $tarGzPath lib scripts
      }
      finally {
        Pop-Location
      }

      Write-Output "Built: $tarGzPath"
    }
  }
}
finally {
  Clear-BuildPath -Path $stagingPath
}
