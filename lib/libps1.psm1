# --------------------------------------------------------------------
# libps1.psm1 - Module wrapper for the 'libps1' function library
# --------------------------------------------------------------------

$files = Get-ChildItem -Path $PSScriptRoot -Filter *.ps1 -File -ErrorAction SilentlyContinue

foreach ($file in $files) {
  . $file.FullName
}

$publicAliases = @(
  'Get-Network',
  'Get-Prefix',
  'Get-NetworkCIDR',
  'Get-PrefixCIDR'
)

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
  'Get-DefaultNetworkAdapter',
  'Get-IPAddress',
  'Get-SubnetMask',
  'Get-DefaultGateway',
  'Get-DNSServer',
  'Get-MACAddress',
  'Get-NetworkPrefix',
  'Get-NetworkPrefixCIDR',
  'Get-BroadcastAddress',
  'Get-MulticastAddress',
  'Test-IPv4Address',
  'Test-IPv6Address',

  # packages.ps1
  'New-PackageLifecycleResult',
  'Get-InstalledProgramCount',
  'Get-AppxPackageCount',
  'Get-PackageCount',
  'Get-Win32Program',
  'Find-Win32Program',
  'Install-Win32Program',
  'Uninstall-Win32Program',
  'Get-UPFAppxPackage',
  'Find-UPFAppxPackage',
  'Test-UPFAppxPackageRemovalSafety',
  'Install-UPFAppxPackage',
  'Update-UPFAppxPackage',
  'Repair-UPFAppxPackage',
  'Reset-UPFAppxPackage',
  'Uninstall-UPFAppxPackage',
  'Install-UPFAppxPackageSet',
  'Uninstall-UPFAppxPackageSet',
  'Install-Win32ProgramFromWinGet',
  'Update-Win32ProgramFromWinGet',
  'Uninstall-Win32ProgramFromWinGet',

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

  # sysinfo.ps1
  'Get-OSBuildNumber',
  'Get-OSDisplayVersion',
  'Get-OSEdition',
  'Get-OSProductName',
  'Get-OSVersionInfo',
  'Get-SystemMemory',
  'Get-SystemDisk',
  'Get-Hostname',
  'Get-SystemUptime',
  'Get-SystemInfo',

  # user.ps1
  'Get-UserInfo',
  'Get-UserSID'
)

Export-ModuleMember -Function $publicFunctions -Alias $publicAliases
