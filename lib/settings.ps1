Get-DefaultApp {
  param (
    [Parameter(Mandatory = $true)]
    [string]$FileExtension
  )

  try {
    $assoc = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\$FileExtension\UserChoice" -ErrorAction Stop
  } catch {
    Write-Error "Could not retrieve default application for '$FileExtension'. $_"
  }

  $command = (Get-ItemProperty "HKCR:\$($assoc.ProgId)\shell\open\command" -ErrorAction Stop).'(default)'
  return $command
}