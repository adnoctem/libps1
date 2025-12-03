#Requires -Version 5.0

function Test-PathExists {
  # ref: https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/using-scriptanalyzer?view=ps-modules#suppressing-rules
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", '', Justification = "Exists is not a plural noun but rather a verb.", Target='Test-PathExists')]

  <#
    .SYNOPSIS
      Check whether a file exists at the specified path.
    .DESCRIPTION
      Uses the .NET file API to determine if the given path points to an existing
      file. Returns $true when the file exists, otherwise $false.
    .EXAMPLE
      PS> Test-Path -Path 'C:\Temp\sample.txt'
    .LINK
      https://github.com/adnoctem/libps1/lib/path.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  param (
    [string]$Path
  )

  if ([System.IO.File]::Exists($Path)) {
    return $true
  } else {
    return $false
  }
}

function Get-BasePath {
  <#
    .SYNOPSIS
      Return the base directory used by libps1.
    .DESCRIPTION
      Determines a dedicated root folder for libps1 so that files created by the
      module stay isolated from other programs. Optionally appends a subfolder
      name to build a fully qualified path for module data.
    .EXAMPLE
      PS> Get-BasePath -Directory 'logs'
    .LINK
      https://github.com/adnoctem/libps1/lib/path.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  param (
    [string]$Directory = 'libps1'
  )

  # [string]$drive = ''
  [string]$_user = [System.Environment]::UserName
  [string]$_home = ''


  if ($PSVersionTable.OS -match "Windows") {
    $_home = $env:LOCALAPPDATA ?? (Join-Path -Path $env:HOMEDRIVE "Users\$_user\AppData\Local")
  } else {
    $_home = ($env:HOME).EndsWith($_user) ? (Join-Path -Path $env:HOME ".cache") : (Join-Path -Path $env:HOME "$_user/.cache")
  }

  return Join-Path -Path $_home (".{0}" -f $Directory)
}

function Get-LogPath {
  <#
    .SYNOPSIS
      Return the log directory for libps1.
    .DESCRIPTION
      Builds a path under the libps1 base folder for log files. A custom
      directory name can be supplied, otherwise 'logs' is used.
    .EXAMPLE
      PS> Get-LogPath
    .EXAMPLE
      PS> Get-LogPath -Directory 'archive'
    .LINK
      https://github.com/adnoctem/libps1/lib/path.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  param (
    [string]$Directory = 'logs'
  )

  return Join-Path -Path (Get-BasePath) $Directory
}

function Get-DataPath {
  <#
    .SYNOPSIS
      Return the data directory for libps1.
    .DESCRIPTION
      Builds a path under the libps1 base folder for persistent data files. A
      custom directory name can be supplied, otherwise 'data' is used.
    .EXAMPLE
      PS> Get-DataPath
    .EXAMPLE
      PS> Get-DataPath -Directory 'downloads'
    .LINK
      https://github.com/adnoctem/libps1/lib/path.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  param (
    [string]$Directory = 'data'
  )

  return Join-Path -Path (Get-BasePath) $Directory
}

function Get-TemporaryPath {
  <#
    .SYNOPSIS
      Return the temporary directory for libps1.
    .DESCRIPTION
      Builds a path under the libps1 base folder for temporary files. A custom
      directory name can be supplied, otherwise 'tmp' is used.
    .EXAMPLE
      PS> Get-TemporaryPath
    .EXAMPLE
      PS> Get-TemporaryPath -Directory 'scratch'
    .LINK
      https://github.com/adnoctem/libps1/lib/path.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  param (
    [string]$Directory = 'tmp'
  )

  return Join-Path -Path (Get-BasePath) $Directory
}

function Get-NewPath {
  <#
    .SYNOPSIS
      Build a new path under the libps1 base folder that must not exist.
    .DESCRIPTION
      Combines the libps1 base folder with a required subdirectory name and
      verifies the resulting path does not already exist, throwing if it does.
    .EXAMPLE
      PS> Get-NewPath -Directory 'exports'
    .LINK
      https://github.com/adnoctem/libps1/lib/path.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  param (
    [Parameter(Mandatory=$true)]
    [string]$Directory
  )

  $path = Join-Path -Path (Get-BasePath) $Directory
  $exists = Test-PathExists $path

  if ($exists) {
    throw "Cannot use path: $path. Path exists!"
  } else {
    return $path
  }
}
