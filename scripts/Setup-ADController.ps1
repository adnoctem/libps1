<#
.SYNOPSIS
  Set up Windows Server Active Directory Domain Services and promote the current machine to a Domain Controller.
.DESCRIPTION
  Installs AD DS, creates a new forest, and promotes the server to the first
  domain controller for the supplied domain. Intended for lab or fresh domain
  provisioning scenarios.
.EXAMPLE
  PS> ./setup-ad-controller.ps1 -Domain 'contoso.local' -Mode Win2025
.LINK
  https://github.com/adnoctem/libps1
.NOTES
  Author: Maximilian Gindorfer <info@mvprowess.com>
  License: MIT
#>

# Parameter help description
param (
  [Parameter(
    Position = 0,
    Mandatory = $true,
    HelpMessage = "The domain to configure the AD Forest with."
  )]
  [ValidatePattern("^[A-Za-z0-9-]{1,63}\.[A-Za-z]{2,8}$")]
  [string]$Domain,
  
  # ref: https://learn.microsoft.com/en-us/powershell/module/addsdeployment/install-addsforest?view=windowsserver2025-ps#-forestmode
  # ref: https://learn.microsoft.com/en-us/powershell/module/addsdeployment/install-addsforest?view=windowsserver2025-ps#-domainmode
  [Parameter(
    Position = 1,
    Mandatory = $false,
    HelpMessage = "The Forest and Domain mode to create the AD Forest with."
  )]
  [ValidateSet("Win2003", "Win2008", "Win2008R2", "Win2012", "Win2012R2", "WinThreshold", "Win2025")]
  [string]$Mode = "Win2025"
)

$packages = @('AD-Domain-Services')
$dsrm = Read-Host -AsSecureString -Prompt "Enter an Active Directory DSRM password"


$pkg = $packages -join ", "
# foreach ($pkg in $packages) {
#   Write-Host "Installing package: $pkg"
# }
Write-Host "Installing packages: $pkg"
Write-Host "Creating AD Forest for domain $Domain with mode: $Mode"
Write-Host "Creating Administrator user with password $DSRM."
