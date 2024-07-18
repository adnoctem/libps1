function Write-Log {
  <#
        .SYNOPSIS
            Write log output to stderr or stdout.

        .EXAMPLE
            Write-Log -Content "Your long-running task has completed!"

            This prints the string "Your..." to stdout.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [string]$Message,

    [Parameter]
    [System.ConsoleColor]$Color = 'White',

    [Parameter]
    [switch]$Timestamps = $false
  )

  process {
    $timestamp = (Get-Date).DateTime
    $Content = "{0}" -f $Message

    if ($Timestamps) {
      $Content = "[{0}]: {1}" -f $timestamp, $Message
    }

    Write-Host $Content
  }
}



Export-ModuleMember -Function Write-Log