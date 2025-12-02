
<#
.SYNOPSIS
  Install Windows features required for Microsoft Exchange Server.
.DESCRIPTION
  Adds the Windows Server roles and features Exchange depends on, preparing a
  host for an on-premises Exchange installation.
.EXAMPLE
  PS> ./setup-exchange.ps1
.LINK
  https://github.com/adnoctem/libps1
.NOTES
  Author: Maximilian Gindorfer <info@mvprowess.com>
  License: MIT
#>

$packages = @(
  'Server-Media-Foundation',
  'NET-Framework-45-Features',
  'RPC-over-HTTP-proxy',
  'RSAT-Clustering',
  'RSAT-Clustering-CmdInterface',
  'RSAT-Clustering-Mgmt',
  'RSAT-Clustering-PowerShell',
  'RSAT-ADD',
  'WAS-Process-Model',
  'Web-Asp-Net45',
  'Web-Basic-Auth',
  'Web-Client-Auth',
  'Web-Digest-Auth',
  'Web-Dir-Browsing',
  'Web-Dyn-Compression',
  'Web-Http-Errors',
  'Web-Http-Logging',
  'Web-Http-Redirect',
  'Web-Http-Tracing',
  'Web-ISAPI-Ext',
  'Web-ISAPI-Filter',
  'Web-Metabase',
  'Web-Mgmt-Console',
  'Web-Mgmt-Service',
  'Web-Net-Ext45',
  'Web-Request-Monitor',
  'Web-Server',
  'Web-Stat-Compression',
  'Web-Static-Content',
  'Web-Windows-Auth',
  'Web-WMI',
  'Windows-Identity-Foundation'
)

$str = $packages -join ", "

Write-Host "Installing Exchange packages: $str"
