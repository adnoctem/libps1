function Request-AdministratorPrivilege {
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