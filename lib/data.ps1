function Convert-Quote {
  <#
  .SYNOPSIS
    Converts single quotes to double quotes or vice versa in a specified file.
  .DESCRIPTION
    This function reads the content of a file and replaces all single quotes with double quotes or all double quotes with single quotes, based on the specified parameter. It is useful for standardizing quote usage in configuration files, scripts, or any text files.
  .PARAMETER Path
    The full path to the file that needs to be processed. The file must exist and be accessible for reading and writing.
  .PARAMETER To
    Specifies the type of quote conversion to perform. Acceptable values are "Single" for converting double quotes to single quotes and "Double" for converting single quotes to double quotes. The default value is "Double".
  .EXAMPLE
    PS> Convert-Quote -Path 'C:\config.txt' -To 'Single'
    This command converts all double quotes in the file 'C:\config.txt' to single quotes.
  .EXAMPLE
    PS> Convert-Quote -Path 'C:\config.txt' -To 'Double'
    This command converts all single quotes in the file 'C:\config.txt' to double quotes.
  .LINK
    https://github.com/adnoctem/libps1/blob/main/lib/data.ps1
  .NOTES
    Author: Maximilian Gindorfer <info@mvprowess.com>
    License: MIT
    #>

  [OutputType([void])]
  param (
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Single", "Double")]
    [string]$To = "Double"
  )

  # NOTE: '-Raw' is required to read the entire file as a single string, allowing for proper replacement of quotes
  $content = Get-Content -Path $Path -Raw

  switch ($To) {
    "Double" { $content = $content -replace "'", '"' }
    "Single" { $content = $content -replace '"', "'" }

    Default {
      throw "Invalid value for -To parameter. Use 'Single' or 'Double'."
    }
  }

  Set-Content -Path $Path -Value $content
}
