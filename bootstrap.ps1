<#
  Initial bootstrapping script used to download PowerShell module dependencies
  defined in the project manifest and set up the project for local use.
#>

param(
  [switch]$Force
)

# ---- Configure module -----------------------------------------

$manifestPath = Join-Path -Path $PSScriptRoot 'lib/libps1.psd1'
$manifest = Test-ModuleManifest -Path $manifestPath

Write-Host "Using manifest: $manifest"

foreach ($mod in $manifest.RequiredModules) {
  # RequiredModules entries can be strings or hashtables
  if ($mod -is [string]) {
    $name = $mod
    $version = $null
  } else {
    $name = $mod.Name
    $version = $mod.ModuleVersion
  }

  Write-Host "Ensuring module '$name' is installed.." -ForegroundColor Yellow

  $installed = Get-Module -ListAvailable -Name $name |
    Sort-Object Version -Descending |
      Select-Object -First 1

  if ($installed -and (!$version -or $installed.Version -ge [version]$version)) {
    Write-Host "    -> OK (found $($installed.Version))"
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
    Write-Host "    -> Installing module: $name at version: $version (use -Force to skip prompts)"
  }

  Install-Module @params
}

# ---------------------------------------------------------------

Write-Host "Successfully processed all RequiredModules!" -ForegroundColor Yellow
