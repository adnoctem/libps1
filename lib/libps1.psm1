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
  # data.ps1
  'Convert-Quote',
  'Merge-ObjectArrays',

  # host.ps1
  'Show-HostName',

  # log.ps1
  'Show-Color',
  'Write-Log',

  # networking.ps1
  'Get-IPv4Address',
  'Get-IPv6Address',
  'Get-IPv4SubnetMask',
  'Get-IPv4DefaultGateway',
  'Get-IPv4DNSServer',
  'Get-MACAddress',
  'Get-IPv4Network',
  'Get-IPv6Prefix',
  'Get-IPv4NetworkCIDR',
  'Get-IPv6PrefixCIDR',
  'Get-IPv4BroadcastAddress',
  'Get-IPv6MulticastAddress',
  'Test-IPv4Address',
  'Test-IPv6Address',
  'Confirm-IPv4Address',
  'Confirm-IPv6Address',

  # packages.ps1
  'Install-AppxPackage',
  'Uninstall-AppxPackage',
  'Install-WinGetPackage',
  'Uninstall-WinGetPackage',

  # path.ps1
  'Test-PathExists',
  'Get-BasePath',
  'Get-LogPath',
  'Get-DataPath',
  'Get-TemporaryPath',
  'Get-NewPath',

  # permissions.ps1
  'Request-AdministratorPrivilege',
  'Read-ProcessElevation',

  # registry.ps1
  'ConvertTo-RegistryProviderPath',
  'Resolve-RegistryPath',
  'Get-RegistryKey',
  'Set-RegistryKey',
  'Remove-RegistryKey',
  'Get-RegistryValue',
  'Set-RegistryValue',
  'Remove-RegistryValue',
  'Test-RegistryPath',
  'Test-RegistryValue',
  'Get-RegistryValueKind',
  'Mount-DefaultUserHive',
  'Dismount-DefaultUserHive',

  # security.ps1
  'Get-DefenderThreatDetection',
  'Get-DefenderThreat',
  'Get-DefenderThreatDescriptionURL',
  'Find-NewlyWrittenObject',

  # settings.ps1
  'Get-DefaultApp',

  # user.ps1
  'Get-UserInfo',
  'Get-UserSID'
)

Export-ModuleMember -Function $publicFunctions