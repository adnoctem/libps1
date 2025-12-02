@{
  Severity            = @('Error', 'Warning')

  IncludeDefaultRules = $true
  Rules               = @{
    'PSAvoidOverwritingBuiltInCmdlets' = @{
      'PowerShellVersion' = @( 'core-7.0.0-windows' )
    }
  }
}