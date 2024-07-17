function Write-Output {
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
    [string]$Content
  )

  process {
    Write-Host $Content
  }
}

# function Write-Log-Green {
#   [CmdletBinding()]
#   param (
#     [Parameter(Mandatory = $true)]
#     [string]$Content
#   )

#   process {
#     Write-Host $Content -ForegroundColor Green
#   }
# }

# function Write-Log-Red {
#   [CmdletBinding()]
#   param (
#     [Parameter(Mandatory = $true)]
#     [string]$Content
#   )

#   process {
#     Write-Host $Content -ForegroundColor Red
#   }
# }

# function Write-Log-Yellow {
#   [CmdletBinding()]
#   param (
#     [Parameter(Mandatory = $true)]
#     [string]$Content
#   )

#   process {
#     Write-Host $Content -ForegroundColor Yellow
#   }
# }

# function Write-Log-Cyan {
#   [CmdletBinding()]
#   param (
#     [Parameter(Mandatory = $true)]
#     [string]$Content
#   )

#   process {
#     Write-Host $Content -ForegroundColor Cyan
#   }
# }

Export-ModuleMember -Function Write-Output