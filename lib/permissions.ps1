function Request-AdministratorPrivilege {
  <#
    .SYNOPSIS
      Request-AdministratorPrivilege - Requests administrator privileges for the current script.
    .DESCRIPTION
      This function checks if the current script is running with administrator privileges. If not, it attempts to restart the script with elevated permissions using the "RunAs" verb. It also ensures that the operating system supports this functionality (Windows Vista or later).
    .EXAMPLE
      PS> Request-AdministratorPrivilege
    .LINK
      https://github.com/adnoctem/libps1/lib/permissions.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [OutputType([void])]
  param ()

  # ref: https://blog.expta.com/2017/03/how-to-self-elevate-powershell-script.html
  if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {

    # ensure build number is at least 6000 (Windows Vista) because earlier versions did not support RunAs
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
      $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
      Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList $CommandLine
      exit
    }
  }
}

function Read-ProcessElevation {
  <#
    .SYNOPSIS
      Read-ProcessElevation - Checks if the current process is running with administrator privileges.
    .DESCRIPTION
      This function checks if the current process has administrator privileges by examining the Windows principal of the current identity. It returns a boolean value indicating whether the process is elevated or not.
    .EXAMPLE
      PS> Read-ProcessElevation
    .LINK
      https://github.com/adnoctem/libps1/lib/permissions.ps1
    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [OutputType([bool])]
  param ()

  # ref: https://stackoverflow.com/questions/29129787/check-if-logged-on-user-is-an-administrator-when-non-elevated
  return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
}