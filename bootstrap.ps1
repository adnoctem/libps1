<#
  Initial bootstrapping script used to download PowerShell module dependencies
  defined in the project manifest and set up the project for local use.
#>

param(
  [switch]$Force
)

$manifestPath = Join-Path -Path $PSScriptRoot 'lib/libps1.psd1'
$manifest = Test-ModuleManifest -Path $manifestPath

Write-Output "Using manifest: $manifest"

foreach ($mod in $manifest.RequiredModules) {
  # RequiredModules entries can be strings or hashtables
  if ($mod -is [string]) {
    $name = $mod
    $version = $null
  } else {
    $name = $mod.Name
    $version = $mod.ModuleVersion
  }

  Write-Output "Ensuring module '$name' is installed.." -ForegroundColor [System.ConsoleColor]::('Cyan')

  $installed = Get-Module -ListAvailable -Name $name |
    Sort-Object Version -Descending |
      Select-Object -First 1

  if ($installed -and (!$version -or $installed.Version -ge [version]$version)) {
    Write-Output "    -> OK (found $($installed.Version))"
    continue
  }

  $params = @{
    Name         = $name
    Scope        = 'CurrentUser'
    Force        = $true
    AllowClobber = $true
  }

  if ($version) { $params['RequiredVersion'] = $version }
  if (-not $Force) {
    Write-Output "    -> Installing module: $name at version: $version (use -Force to skip prompts)"
  }

  Install-Module @params
}

Write-Output "Successfully processed all RequiredModules!" -ForegroundColor [System.ConsoleColor]::('Cyan')
