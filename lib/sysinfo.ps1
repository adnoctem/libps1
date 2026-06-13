#Requires -Version 5.0

# Shared native methods — compiled once and reused by Get-SystemMemory / Get-SystemUptime
if ($null -eq ('SysInfoNative' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class SysInfoNative {
    [StructLayout(LayoutKind.Sequential)]
    public struct MEMORYSTATUSEX {
        public uint dwLength;
        public uint dwMemoryLoad;
        public ulong ullTotalPhys;
        public ulong ullAvailPhys;
        public ulong ullTotalPageFile;
        public ulong ullAvailPageFile;
        public ulong ullTotalVirtual;
        public ulong ullAvailVirtual;
        public ulong ullAvailExtendedVirtual;
    }

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GlobalMemoryStatusEx(ref MEMORYSTATUSEX lpBuffer);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern ulong GetTickCount64();
}
'@ -ErrorAction Stop
}

function Get-OSBuildNumber {
  <#
    .SYNOPSIS
      Returns the Windows build number as an integer.
    .DESCRIPTION
      Reads CurrentBuild from HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion.
      This is a single cheap registry read — far faster than Get-CimInstance
      or any WMI-based approach.  Returns e.g. 22621 (22H2), 22631 (23H2).
    .EXAMPLE
      PS> Get-OSBuildNumber
      22621
    .LINK
      https://github.com/adnoctem/libps1/lib/sysinfo.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [OutputType([int])]
  [CmdletBinding()]
  param()

  $build = Get-ItemPropertyValue -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'CurrentBuild' -ErrorAction Stop
  return [int]$build
}

function Get-OSDisplayVersion {
  <#
    .SYNOPSIS
      Returns the Windows feature-update display name (e.g. "22H2", "23H2").
    .DESCRIPTION
      Reads DisplayVersion from HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion.
      Falls back to ReleaseId on older builds that lack DisplayVersion.
    .EXAMPLE
      PS> Get-OSDisplayVersion
      23H2
    .LINK
      https://github.com/adnoctem/libps1/lib/sysinfo.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [OutputType([string])]
  [CmdletBinding()]
  param()

  try {
    $display = Get-ItemPropertyValue -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'DisplayVersion' -ErrorAction Stop
    if ($display) { return $display }
  }
  catch { }

  $releaseId = Get-ItemPropertyValue -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ReleaseId' -ErrorAction Stop
  return $releaseId
}

function Get-OSEdition {
  <#
    .SYNOPSIS
      Returns the Windows edition SKU (e.g. "Professional", "Enterprise").
    .DESCRIPTION
      Reads EditionID from HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion.
    .EXAMPLE
      PS> Get-OSEdition
      Professional
    .LINK
      https://github.com/adnoctem/libps1/lib/sysinfo.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [OutputType([string])]
  [CmdletBinding()]
  param()

  return Get-ItemPropertyValue -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'EditionID' -ErrorAction Stop
}

function Get-OSProductName {
  <#
    .SYNOPSIS
      Returns the full Windows product name string.
    .DESCRIPTION
      Reads ProductName from HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion.
      Returns e.g. "Windows 11 Pro" or "Windows 10 Enterprise".
    .EXAMPLE
      PS> Get-OSProductName
      Windows 11 Pro
    .LINK
      https://github.com/adnoctem/libps1/lib/sysinfo.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [OutputType([string])]
  [CmdletBinding()]
  param()

  return Get-ItemPropertyValue -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Name 'ProductName' -ErrorAction Stop
}

function Get-OSVersionInfo {
  <#
    .SYNOPSIS
      Returns a complete snapshot of Windows version metadata from the registry.
    .DESCRIPTION
      Performs a single Get-ItemProperty call against HKLM:\SOFTWARE\Microsoft\
      Windows NT\CurrentVersion and returns all relevant fields in one object.
      Far cheaper than calling the individual Get-OS* functions when you need
      multiple values.
    .EXAMPLE
      PS> Get-OSVersionInfo
    .EXAMPLE
      PS> Get-OSVersionInfo | Format-List
    .LINK
      https://github.com/adnoctem/libps1/lib/sysinfo.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [OutputType([PSCustomObject])]
  [CmdletBinding()]
  param()

  $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
  $props = Get-ItemProperty -LiteralPath $key -ErrorAction Stop

  $installDate = $null
  if ($props.InstallDate) {
    try { $installDate = [DateTime]::FromFileTimeUtc([int64]$props.InstallDate) }
    catch { }
  }

  [PSCustomObject]@{
    ProductName    = $props.ProductName
    EditionID      = $props.EditionID
    DisplayVersion = $props.DisplayVersion
    CurrentBuild   = [int]$props.CurrentBuild
    UBR            = if ($props.UBR) { [int]$props.UBR } else { 0 }
    ReleaseId      = $props.ReleaseId
    BuildBranch    = $props.BuildBranch
    InstallDate    = $installDate
    RegisteredOwner = $props.RegisteredOwner
  }
}

function Get-SystemMemory {
  <#
    .SYNOPSIS
      Returns physical memory statistics — total, available, used, and load
      percentage.
    .DESCRIPTION
      Uses kernel32!GlobalMemoryStatusEx via P/Invoke (no CIM/WMI overhead).
      Returns an object with human-readable GiB values and the raw bytes.
    .EXAMPLE
      PS> Get-SystemMemory
    .EXAMPLE
      PS> Get-SystemMemory | Format-List
    .LINK
      https://github.com/adnoctem/libps1/lib/sysinfo.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [OutputType([PSCustomObject])]
  [CmdletBinding()]
  param()

  $memInfo = New-Object SysInfoNative+MEMORYSTATUSEX
  $memInfo.dwLength = [System.Runtime.InteropServices.Marshal]::SizeOf($memInfo)

  if (-not [SysInfoNative]::GlobalMemoryStatusEx([ref]$memInfo)) {
    Write-Error 'GlobalMemoryStatusEx failed.'
    return $null
  }

  $totalGiB       = [math]::Round($memInfo.ullTotalPhys / 1GB, 2)
  $availableGiB   = [math]::Round($memInfo.ullAvailPhys / 1GB, 2)
  $usedGiB        = [math]::Round(($memInfo.ullTotalPhys - $memInfo.ullAvailPhys) / 1GB, 2)

  [PSCustomObject]@{
    TotalBytes       = $memInfo.ullTotalPhys
    AvailableBytes   = $memInfo.ullAvailPhys
    UsedBytes        = $memInfo.ullTotalPhys - $memInfo.ullAvailPhys
    LoadPercent      = $memInfo.dwMemoryLoad
    TotalGiB         = $totalGiB
    AvailableGiB     = $availableGiB
    UsedGiB          = $usedGiB
  }
}

function Get-SystemDisk {
  <#
    .SYNOPSIS
      Returns disk usage information for all fixed logical drives.
    .DESCRIPTION
      Uses [System.IO.DriveInfo]::GetDrives() — pure .NET, no CIM/WMI overhead.
      Filters to fixed (non-removable) drives that are ready.  Returns total
      size, free space, used space, and the filesystem type.
    .PARAMETER All
      Include removable, network, and CD-ROM drives in addition to fixed drives.
    .EXAMPLE
      PS> Get-SystemDisk
    .EXAMPLE
      PS> Get-SystemDisk -All
    .EXAMPLE
      PS> Get-SystemDisk | Format-Table -AutoSize
    .LINK
      https://github.com/adnoctem/libps1/lib/sysinfo.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [OutputType([PSCustomObject[]])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false)]
    [switch]
    $All = $false
  )

  $drives = [System.IO.DriveInfo]::GetDrives()
  if (-not $All) {
    $drives = $drives | Where-Object { $_.DriveType -eq 'Fixed' }
  }

  foreach ($drive in $drives) {
    if (-not $drive.IsReady) { continue }

    $totalGiB     = [math]::Round($drive.TotalSize / 1GB, 2)
    $freeGiB      = [math]::Round($drive.AvailableFreeSpace / 1GB, 2)
    $usedGiB      = [math]::Round(($drive.TotalSize - $drive.AvailableFreeSpace) / 1GB, 2)
    $percentFree  = [math]::Round($drive.AvailableFreeSpace * 100.0 / $drive.TotalSize, 1)

    [PSCustomObject]@{
      Name          = $drive.Name.TrimEnd('\')
      Label         = $drive.VolumeLabel
      Type          = $drive.DriveType.ToString()
      FileSystem    = $drive.DriveFormat
      TotalGiB      = $totalGiB
      FreeGiB       = $freeGiB
      UsedGiB       = $usedGiB
      PercentFree   = $percentFree
      TotalBytes    = $drive.TotalSize
      FreeBytes     = $drive.AvailableFreeSpace
    }
  }
}

function Get-Hostname {
  <#
    .SYNOPSIS
      Returns the computer hostname.
    .DESCRIPTION
      Uses [System.Net.Dns]::GetHostName() and resolves it to a fully-qualified
      domain name when joined to a domain.  Returns both the short hostname and,
      if different, the FQDN.
    .EXAMPLE
      PS> Get-Hostname
    .LINK
      https://github.com/adnoctem/libps1/lib/sysinfo.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [OutputType([PSCustomObject])]
  [CmdletBinding()]
  param()

  $hostname = [System.Net.Dns]::GetHostName()

  $fqdn = $null
  try {
    $entry = [System.Net.Dns]::GetHostEntry($hostname)
    $fqdn = $entry.HostName
    if ($fqdn -eq $hostname) { $fqdn = $null }
  }
  catch { }

  [PSCustomObject]@{
    Hostname = $hostname
    FQDN     = $fqdn
  }
}

function Get-SystemUptime {
  <#
    .SYNOPSIS
      Returns the system uptime (time since last boot).
    .DESCRIPTION
      Uses kernel32!GetTickCount64 via P/Invoke for a non-wrapping, high-
      precision uptime value — no CIM/WMI overhead.  Returns the raw tick
      count, total milliseconds, and a human-readable breakdown.
    .EXAMPLE
      PS> Get-SystemUptime
    .EXAMPLE
      PS> Get-SystemUptime | Format-List
    .LINK
      https://github.com/adnoctem/libps1/lib/sysinfo.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [OutputType([PSCustomObject])]
  [CmdletBinding()]
  param()

  $ticksMs = [SysInfoNative]::GetTickCount64()
  $span = [TimeSpan]::FromMilliseconds($ticksMs)

  [PSCustomObject]@{
    TotalMilliseconds = $ticksMs
    Days              = $span.Days
    Hours             = $span.Hours
    Minutes           = $span.Minutes
    Seconds           = $span.Seconds
    TotalHours        = [math]::Round($span.TotalHours, 1)
    TotalDays         = [math]::Round($span.TotalDays, 1)
    Display           = ('{0}d {1:D2}h {2:D2}m {3:D2}s' -f $span.Days, $span.Hours, $span.Minutes, $span.Seconds)
  }
}

function Get-SystemInfo {
  <#
    .SYNOPSIS
      Returns a comprehensive system information snapshot (fetch-style).
    .DESCRIPTION
      Assembles OS version, memory, disk, hostname, and uptime into a single
      structured object.  Every data source is chosen to avoid expensive CIM/
      WMI calls — the function uses registry reads, .NET APIs, and lightweight
      P/Invoke where needed.
    .EXAMPLE
      PS> Get-SystemInfo | Format-List
    .EXAMPLE
      PS> Get-SystemInfo
    .LINK
      https://github.com/adnoctem/libps1/lib/sysinfo.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [OutputType([PSCustomObject])]
  [CmdletBinding()]
  param()

  $os    = Get-OSVersionInfo
  $mem   = Get-SystemMemory
  $disks = Get-SystemDisk
  $host  = Get-Hostname
  $up    = Get-SystemUptime

  [PSCustomObject]@{
    OSProductName   = $os.ProductName
    OSEdition       = $os.EditionID
    OSVersion       = $os.DisplayVersion
    OSBuild         = $os.CurrentBuild
    OSUBRev         = $os.UBR
    Hostname        = $host.Hostname
    FQDN            = $host.FQDN
    TotalMemoryGiB  = $mem.TotalGiB
    MemoryLoadPct   = $mem.LoadPercent
    Disks           = ($disks | ForEach-Object { '{0} {1}GiB/{2}GiB ({3}% free)' -f $_.Name, $_.FreeGiB, $_.TotalGiB, $_.PercentFree }) -join ' | '
    Uptime          = $up.Display
    InstallDate     = $os.InstallDate
  }
}
