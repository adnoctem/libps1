# --------------------------------------------------------------------
# libps1.psm1 — Module wrapper for the 'libps1' function library
# --------------------------------------------------------------------

$root = Split-Path -Parent $PSCommandPath
$files = Get-ChildItem -Path $root -Filter *.ps1 -File -Recurse -ErrorAction SilentlyContinue

# iterate and load all script files
foreach ($file in $files) {
  if (-not (Test-Path $file)) {
    throw "The PowerShell script file '$file' was not found. Cannot load module."
  }

  . $file
}

$publicFunctions = @(
  'Write-Log'
)

Export-ModuleMember -Function $publicFunctions